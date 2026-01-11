# Telegraf Pod - Security Best Practices
## Fireball Industries Security Guide

Because "It worked on my laptop" isn't a security strategy.

---

## Table of Contents

1. [Security Principles](#security-principles)
2. [Pre-Deployment Security](#pre-deployment-security)
3. [Secret Management](#secret-management)
4. [RBAC Configuration](#rbac-configuration)
5. [Network Security](#network-security)
6. [Pod Security](#pod-security)
7. [Image Security](#image-security)
8. [Compliance Considerations](#compliance-considerations)
9. [Security Monitoring](#security-monitoring)
10. [Incident Response](#incident-response)

---

## Security Principles

This pod implements **Defense in Depth**:

1. **Least Privilege**: Minimal permissions, non-root execution
2. **Fail Secure**: Restrictive defaults, opt-in permissions
3. **Defense in Depth**: Multiple security layers
4. **Separation of Duties**: RBAC boundaries
5. **Audit Everything**: Comprehensive logging

---

## Pre-Deployment Security

### Security Checklist

Before deploying to production:

```powershell
# ✓ Secrets Review
# Verify NO secrets in values.yaml
grep -i "password\|token\|key" values.yaml
# Should find only variable references like ${INFLUX_TOKEN}

# ✓ Image Scan
trivy image telegraf:1.29.0-alpine
# Address any HIGH or CRITICAL vulnerabilities

# ✓ RBAC Validation
kubectl auth can-i get pods --as=system:serviceaccount:telegraf:telegraf
# Should return "yes" only for intended permissions

# ✓ Network Policy Test
kubectl run test --image=nginx -n default
kubectl exec test -- wget -O- http://telegraf.telegraf.svc:8080/metrics
# Should be blocked if NetworkPolicy is restrictive
```

### Namespace Isolation

```bash
# Create dedicated namespace
kubectl create namespace telegraf-prod

# Apply Pod Security Standards
kubectl label namespace telegraf-prod \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted

# Apply resource quotas
kubectl apply -f - <<EOF
apiVersion: v1
kind: ResourceQuota
metadata:
  name: telegraf-quota
  namespace: telegraf-prod
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
    persistentvolumeclaims: "5"
EOF
```

---

## Secret Management

### DO NOT Do This

```yaml
# ❌ NEVER COMMIT SECRETS
config:
  outputs:
    influxdb_v2:
      token: "my-secret-token-12345"  # ❌ WRONG!
```

### DO This Instead

**1. Create Kubernetes Secret:**

```bash
# From literal values
kubectl create secret generic telegraf-secrets \
  --namespace telegraf-prod \
  --from-literal=influx-token='YOUR_TOKEN_HERE' \
  --from-literal=influx-password='YOUR_PASSWORD_HERE' \
  --from-literal=api-key='YOUR_API_KEY_HERE'

# From files (better for certificates)
kubectl create secret generic telegraf-certs \
  --namespace telegraf-prod \
  --from-file=ca.pem=./ca.pem \
  --from-file=cert.pem=./cert.pem \
  --from-file=key.pem=./key.pem
```

**2. Reference in values.yaml:**

```yaml
env:
  - name: INFLUX_TOKEN
    valueFrom:
      secretKeyRef:
        name: telegraf-secrets
        key: influx-token
  - name: INFLUX_PASSWORD
    valueFrom:
      secretKeyRef:
        name: telegraf-secrets
        key: influx-password
  - name: API_KEY
    valueFrom:
      secretKeyRef:
        name: telegraf-secrets
        key: api-key

config:
  outputs:
    influxdb_v2:
      token: "${INFLUX_TOKEN}"  # ✓ Environment variable
      
    influxdb_v1:
      password: "${INFLUX_PASSWORD}"  # ✓ Environment variable
```

**3. Mount certificate files:**

```yaml
extraVolumes:
  - name: certs
    secret:
      secretName: telegraf-certs

extraVolumeMounts:
  - name: certs
    mountPath: /etc/telegraf/certs
    readOnly: true

config:
  outputs:
    influxdb_v2:
      tls_ca: "/etc/telegraf/certs/ca.pem"
      tls_cert: "/etc/telegraf/certs/cert.pem"
      tls_key: "/etc/telegraf/certs/key.pem"
```

### Encrypting Secrets at Rest

**Enable Encryption in Kubernetes:**

```yaml
# /etc/kubernetes/encryption-config.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: <BASE64_ENCODED_SECRET>
      - identity: {}
```

**Using External Secret Management:**

```yaml
# Example: Vault integration
apiVersion: v1
kind: Secret
metadata:
  name: telegraf-secrets
  annotations:
    vault.hashicorp.com/agent-inject: "true"
    vault.hashicorp.com/role: "telegraf"
    vault.hashicorp.com/agent-inject-secret-influx-token: "secret/data/telegraf/influx"
type: Opaque
```

### Secret Rotation

```bash
# Script for rotating secrets
#!/bin/bash

# 1. Generate new token in InfluxDB
NEW_TOKEN=$(influx auth create --org fireball --description "telegraf-$(date +%Y%m%d)")

# 2. Update Kubernetes secret
kubectl create secret generic telegraf-secrets-new \
  --namespace telegraf-prod \
  --from-literal=influx-token="$NEW_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -

# 3. Update deployment to use new secret
kubectl set env deployment/telegraf \
  --namespace telegraf-prod \
  --from=secret/telegraf-secrets-new

# 4. Wait for rollout
kubectl rollout status deployment/telegraf -n telegraf-prod

# 5. Delete old token from InfluxDB
# 6. Delete old secret
kubectl delete secret telegraf-secrets --namespace telegraf-prod
```

---

## RBAC Configuration

### Minimal Permissions (Namespace-Scoped)

Use when you only need metrics from the Telegraf namespace:

```yaml
rbac:
  create: true
  clusterRole: false  # Namespace-scoped only
```

**Permissions granted:**
- `get`, `list`, `watch` pods in namespace
- `get`, `list`, `watch` services in namespace
- No cluster-wide access

### Full Permissions (Cluster-Scoped)

Use when you need cluster-wide Kubernetes metrics:

```yaml
rbac:
  create: true
  clusterRole: true  # Cluster-wide access
```

**Permissions granted:**
- Read-only access to nodes, pods, services, deployments, etc.
- **NO write permissions**
- **NO secret access**
- **NO pod exec/attach permissions**

### Custom RBAC

For specific requirements:

```yaml
# Disable auto-generated RBAC
rbac:
  create: false

serviceAccount:
  create: true
  name: telegraf-custom
```

Create custom RBAC:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: telegraf-custom
rules:
  # Only specific resources
  - apiGroups: [""]
    resources: ["nodes", "pods"]
    verbs: ["get", "list"]
  
  # No watch permission (reduces API load)
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: telegraf-custom
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: telegraf-custom
subjects:
  - kind: ServiceAccount
    name: telegraf-custom
    namespace: telegraf-prod
```

### Auditing RBAC Usage

```bash
# View actual API calls made by Telegraf
kubectl get events --all-namespaces --field-selector involvedObject.name=telegraf

# Check ServiceAccount token usage
kubectl describe serviceaccount telegraf -n telegraf-prod

# Review ClusterRole permissions
kubectl describe clusterrole telegraf
```

---

## Network Security

### Network Policies

**Restrict Ingress (Who Can Connect):**

```yaml
networkPolicy:
  enabled: true
  policyTypes:
    - Ingress
  ingress:
    # Only Prometheus from monitoring namespace
    - from:
        - namespaceSelector:
            matchLabels:
              name: monitoring
        - podSelector:
            matchLabels:
              app: prometheus
      ports:
        - protocol: TCP
          port: 8080
```

**Restrict Egress (Where Telegraf Can Connect):**

```yaml
networkPolicy:
  enabled: true
  policyTypes:
    - Egress
  egress:
    # DNS
    - to:
        - namespaceSelector:
            matchLabels:
              name: kube-system
        - podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - protocol: UDP
          port: 53
    
    # InfluxDB
    - to:
        - namespaceSelector:
            matchLabels:
              name: monitoring
        - podSelector:
            matchLabels:
              app: influxdb
      ports:
        - protocol: TCP
          port: 8086
    
    # Kubernetes API
    - to:
        - namespaceSelector: {}
      ports:
        - protocol: TCP
          port: 443
    
    # External HTTPS (for cloud APIs)
    - to:
        - ipBlock:
            cidr: 0.0.0.0/0
            except:
              - 10.0.0.0/8
              - 172.16.0.0/12
              - 192.168.0.0/16
      ports:
        - protocol: TCP
          port: 443
```

**Test Network Policies:**

```bash
# From allowed namespace (should succeed)
kubectl run test -n monitoring --image=alpine --rm -it -- \
  wget -O- http://telegraf.telegraf-prod.svc:8080/metrics

# From denied namespace (should fail)
kubectl run test -n default --image=alpine --rm -it -- \
  wget -O- http://telegraf.telegraf-prod.svc:8080/metrics
```

### TLS Configuration

**InfluxDB with TLS:**

```yaml
config:
  outputs:
    influxdb_v2:
      urls:
        - "https://influxdb:8086"  # HTTPS
      tls_ca: "/etc/telegraf/certs/ca.pem"
      tls_cert: "/etc/telegraf/certs/cert.pem"
      tls_key: "/etc/telegraf/certs/key.pem"
      insecure_skip_verify: false  # Validate certificate
```

**Prometheus with mTLS:**

```yaml
config:
  outputs:
    prometheus_client:
      # Enable TLS
      tls_cert: "/etc/telegraf/certs/server-cert.pem"
      tls_key: "/etc/telegraf/certs/server-key.pem"
      
      # Require client certificates
      tls_allowed_cacerts: ["/etc/telegraf/certs/client-ca.pem"]
```

---

## Pod Security

### Security Contexts (Already Enabled)

```yaml
securityContext:
  runAsNonRoot: true          # ✓ Not running as root
  runAsUser: 999              # ✓ Specific non-root UID
  fsGroup: 999                # ✓ File permissions
  capabilities:
    drop:
      - ALL                   # ✓ Drop all capabilities
  readOnlyRootFilesystem: true # ✓ Immutable filesystem
  allowPrivilegeEscalation: false # ✓ No privilege escalation

podSecurityContext:
  seccompProfile:
    type: RuntimeDefault      # ✓ Seccomp filtering
```

### Additional Hardening

**AppArmor Profile:**

```yaml
podAnnotations:
  container.apparmor.security.beta.kubernetes.io/telegraf: runtime/default
```

**SELinux Labels:**

```yaml
podSecurityContext:
  seLinuxOptions:
    level: "s0:c123,c456"
    role: "system_r"
    type: "svirt_sandbox_file_t"
```

**Syscall Filtering (Custom Seccomp):**

```yaml
# Create seccomp profile
apiVersion: v1
kind: ConfigMap
metadata:
  name: telegraf-seccomp
data:
  profile.json: |
    {
      "defaultAction": "SCMP_ACT_ERRNO",
      "architectures": ["SCMP_ARCH_X86_64"],
      "syscalls": [
        {"names": ["read", "write", "open", "close", "stat", ...], "action": "SCMP_ACT_ALLOW"}
      ]
    }

# Reference in pod
podSecurityContext:
  seccompProfile:
    type: Localhost
    localhostProfile: telegraf/profile.json
```

---

## Image Security

### Image Scanning

```bash
# Scan with Trivy
trivy image telegraf:1.29.0-alpine

# Scan with Grype
grype telegraf:1.29.0-alpine

# Scan with Snyk
snyk container test telegraf:1.29.0-alpine
```

### Image Signing & Verification

**Using Cosign:**

```bash
# Sign image
cosign sign telegraf:1.29.0-alpine

# Verify signature
cosign verify telegraf:1.29.0-alpine
```

**Enforce signatures with Kyverno:**

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-images
spec:
  validationFailureAction: enforce
  rules:
    - name: verify-telegraf
      match:
        resources:
          kinds:
            - Pod
      verifyImages:
        - image: "telegraf:*"
          key: |-
            -----BEGIN PUBLIC KEY-----
            <YOUR_PUBLIC_KEY>
            -----END PUBLIC KEY-----
```

### Using Private Registry

```yaml
image:
  repository: registry.company.com/telegraf
  tag: "1.29.0-alpine-hardened"
  pullPolicy: Always
  pullSecrets:
    - name: registry-credentials
```

Create pull secret:

```bash
kubectl create secret docker-registry registry-credentials \
  --docker-server=registry.company.com \
  --docker-username=user \
  --docker-password=password \
  --docker-email=user@company.com \
  --namespace=telegraf-prod
```

---

## Compliance Considerations

### PCI DSS

Requirements for credit card processing:

- ✅ **Encrypt data in transit**: Use TLS for all outputs
- ✅ **Restrict network access**: NetworkPolicies
- ✅ **No default credentials**: All secrets in Kubernetes Secrets
- ✅ **Logging & monitoring**: Enabled by default
- ✅ **Regular updates**: Automated image updates

**Additional configuration:**

```yaml
config:
  outputs:
    influxdb_v2:
      urls: ["https://influxdb:8086"]  # HTTPS required
      insecure_skip_verify: false       # Certificate validation required

networkPolicy:
  enabled: true  # Required
  
# Enable audit logging
podAnnotations:
  audit.k8s.io/enabled: "true"
```

### HIPAA

Requirements for healthcare data:

- ✅ **Encryption at rest**: Enable Kubernetes secret encryption
- ✅ **Encryption in transit**: TLS for all communications
- ✅ **Access controls**: RBAC
- ✅ **Audit trails**: Kubernetes audit logs
- ✅ **Data retention**: Configure in InfluxDB

**Additional configuration:**

```yaml
# Do NOT collect PII/PHI in metrics
config:
  processors:
    # Redact sensitive fields
    regex:
      tags:
        - key: "patient_id"
          pattern: ".*"
          replacement: "[REDACTED]"

# Network isolation
networkPolicy:
  enabled: true
  policyTypes: [Ingress, Egress]
```

### SOC 2

Requirements for service organizations:

- ✅ **Security**: Non-root, dropped capabilities, read-only FS
- ✅ **Availability**: Health checks, resource limits
- ✅ **Confidentiality**: Secrets management, TLS
- ✅ **Privacy**: No PII collection
- ✅ **Processing Integrity**: Metric validation

---

## Security Monitoring

### Audit Logging

Enable Kubernetes audit logging for Telegraf actions:

```yaml
# /etc/kubernetes/audit-policy.yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
  # Log all requests from Telegraf ServiceAccount
  - level: RequestResponse
    users:
      - system:serviceaccount:telegraf-prod:telegraf
    
  # Log all access to Telegraf secrets
  - level: Metadata
    resources:
      - group: ""
        resources: ["secrets"]
    namespaces: ["telegraf-prod"]
```

### Monitor for Security Events

```bash
# Watch for privilege escalation attempts
kubectl get events --all-namespaces --field-selector reason=FailedCreate,reason=Forbidden | grep telegraf

# Monitor for secret access
kubectl get events -n telegraf-prod --field-selector involvedObject.kind=Secret

# Check for pod security violations
kubectl get events --all-namespaces | grep "violates PodSecurity"
```

### Anomaly Detection

Monitor for unusual behavior:

```yaml
config:
  inputs:
    # Monitor own resource usage
    internal:
      enabled: true
      collect_memstats: true

# Alert on anomalies
# - Sudden memory increase (possible memory leak)
# - High CPU usage (possible cryptomining)
# - Excessive network traffic (possible data exfiltration)
```

---

## Incident Response

### Security Incident Playbook

**1. Detection:**
```bash
# Check for security alerts
kubectl get events --all-namespaces | grep -i "security\|violation\|forbidden"

# Review pod logs for errors
kubectl logs -n telegraf-prod deployment/telegraf --tail=1000 | grep -i "error\|denied\|forbidden"
```

**2. Containment:**
```bash
# Immediately isolate pod
kubectl patch deployment telegraf -n telegraf-prod \
  -p '{"spec":{"template":{"spec":{"hostNetwork":false}}}}'

# Block all network traffic
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: telegraf-lockdown
  namespace: telegraf-prod
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: telegraf
  policyTypes:
    - Ingress
    - Egress
EOF
```

**3. Investigation:**
```bash
# Capture pod state
kubectl get pod -n telegraf-prod -o yaml > pod-state.yaml
kubectl describe pod -n telegraf-prod > pod-describe.txt
kubectl logs -n telegraf-prod deployment/telegraf --previous > pod-logs.txt

# Check events
kubectl get events -n telegraf-prod --sort-by='.lastTimestamp' > events.txt

# Exec into pod for forensics (if safe)
kubectl exec -it -n telegraf-prod deployment/telegraf -- /bin/sh
```

**4. Eradication:**
```bash
# Delete compromised deployment
kubectl delete deployment telegraf -n telegraf-prod

# Rotate all secrets
kubectl delete secret telegraf-secrets -n telegraf-prod
# Recreate with new credentials
```

**5. Recovery:**
```bash
# Redeploy from known-good state
helm upgrade telegraf . -f values.yaml --namespace telegraf-prod

# Verify clean state
kubectl get pods -n telegraf-prod
kubectl logs -n telegraf-prod deployment/telegraf
```

**6. Post-Incident:**
- Review audit logs
- Update security controls
- Document lessons learned
- Update incident response playbook

---

## Security Checklist

Before going to production:

### Pre-Deployment
- [ ] No secrets in values.yaml or Git
- [ ] All secrets in Kubernetes Secrets
- [ ] Image scanned for vulnerabilities
- [ ] RBAC configured with minimal permissions
- [ ] Network policies defined
- [ ] Pod security contexts enabled
- [ ] Namespace isolation configured
- [ ] Resource quotas set

### Runtime
- [ ] TLS enabled for all outputs
- [ ] Certificate validation enabled
- [ ] Non-root execution verified
- [ ] Health checks passing
- [ ] Audit logging enabled
- [ ] Monitoring alerts configured

### Compliance
- [ ] Encryption at rest enabled
- [ ] Encryption in transit enforced
- [ ] Access controls documented
- [ ] Audit trail retention configured
- [ ] Compliance team review completed

### Operational
- [ ] Secret rotation procedure documented
- [ ] Incident response plan tested
- [ ] Backup/restore tested
- [ ] Update procedure documented
- [ ] Security contacts listed

---

## Summary

Security is not a feature, it's a practice. This pod provides:

✅ **Secure by default** - Non-root, minimal permissions, encrypted  
✅ **Defense in depth** - Multiple security layers  
✅ **Compliance ready** - PCI, HIPAA, SOC 2 configurations  
✅ **Auditable** - Comprehensive logging and monitoring  

**Remember:** Security is an ongoing process, not a one-time configuration.

**Fireball Industries** - We Play With Fire So You Don't Have To™  
*Because "We got hacked" shouldn't be in your vocabulary*

---

**Questions?** security@fireball.industries  
**Incidents?** incident-response@fireball.industries (24/7)
