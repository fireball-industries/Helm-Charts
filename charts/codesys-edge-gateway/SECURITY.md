# CODESYS Edge Gateway - Security Guide

## Security Best Practices

### Overview

The CODESYS Edge Gateway is a critical component in your industrial automation infrastructure, providing PLC discovery, management, and connectivity services. This guide covers security hardening, compliance, and best practices for production deployments.

## Pod Security Standards

The chart supports multiple Pod Security Standards compliance levels:

### Baseline (Default - Recommended)

```yaml
security:
  podSecurityStandard: "baseline"

securityContext:
  capabilities:
    add:
      - NET_ADMIN  # Required for network configuration
    drop:
      - ALL
  runAsNonRoot: false
  runAsUser: 0
  privileged: false
  readOnlyRootFilesystem: false
```

**Compliance Level:** Kubernetes Pod Security Standard - Baseline

**What's Allowed:**
- ✅ Specific capabilities (NET_ADMIN)
- ✅ Root user (gateway requires network operations)
- ✅ Writable root filesystem

**What's Blocked:**
- ❌ Privileged mode
- ❌ Host namespaces
- ❌ Unnecessary capabilities

**Best For:** Production deployments requiring gateway functionality with reasonable security

### Restricted (High Security - Limited Functionality)

```yaml
security:
  podSecurityStandard: "restricted"

securityContext:
  capabilities:
    drop:
      - ALL
  runAsNonRoot: true
  runAsUser: 1000
  privileged: false
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  seccompProfile:
    type: RuntimeDefault
```

**Compliance Level:** Kubernetes Pod Security Standard - Restricted

**Limitations:**
- ⚠️ May not support all gateway features
- ⚠️ Network discovery may be limited
- ⚠️ Some gateway operations may fail

**Best For:** High-security environments where gateway features are limited to basic connectivity

### Security Context Explanation

#### Why Gateway Needs NET_ADMIN

```yaml
securityContext:
  capabilities:
    add:
      - NET_ADMIN
```

**Purpose:**
- Configure network interfaces for PLC discovery
- Bind to UDP broadcast ports (1740-1743)
- Manage gateway routing tables

**Alternatives:**
If NET_ADMIN is not acceptable in your environment:
1. Use `hostNetwork: true` (not recommended)
2. Limit gateway to TCP-only mode (no UDP discovery)
3. Use external gateway outside Kubernetes

#### Running as Root

```yaml
securityContext:
  runAsUser: 0
```

**Why:** CODESYS Gateway binds to ports < 1024 and configures network interfaces

**Mitigation Options:**

**Option 1: Non-Root with Capabilities (Preferred)**
```yaml
securityContext:
  runAsUser: 1000
  runAsGroup: 1000
  capabilities:
    add:
      - NET_BIND_SERVICE  # Bind to ports < 1024
      - NET_RAW           # Raw socket access
```

**Option 2: Use High Ports**
```yaml
service:
  gatewayPort: 2455    # Changed from default
  plcPort: 11217       # Changed from 1217
```

Then configure port forwarding or use LoadBalancer to expose standard ports.

## Network Security

### Network Policy (Recommended for Production)

```yaml
networkPolicy:
  enabled: true
  ingress:
    # Allow only from CODESYS PLC namespace
    - from:
      - namespaceSelector:
          matchLabels:
            name: codesys-plc
      ports:
      - protocol: TCP
        port: 2455
      - protocol: TCP
        port: 1217
    # Allow from specific IPs (engineering workstations)
    - from:
      - ipBlock:
          cidr: 192.168.1.0/24
          except:
            - 192.168.1.100/32  # Untrusted device
      ports:
      - protocol: TCP
        port: 2455
  egress:
    # Allow DNS
    - to:
      - namespaceSelector: {}
      ports:
      - protocol: UDP
        port: 53
    # Allow outbound to PLCs only
    - to:
      - namespaceSelector:
          matchLabels:
            name: codesys-plc
```

**Best Practices:**
- ✅ Restrict ingress to known sources
- ✅ Limit egress to necessary services
- ✅ Use namespace selectors for micro-segmentation
- ✅ Log denied connections for monitoring

### Service Type Security Considerations

#### LoadBalancer (Production)

```yaml
service:
  type: LoadBalancer
  annotations:
    # MetalLB: Restrict announcement to specific interfaces
    metallb.universe.tf/address-pool: industrial-trusted
    # Restrict source IPs (cloud providers)
    service.beta.kubernetes.io/load-balancer-source-ranges: "192.168.1.0/24,10.0.0.0/8"
```

**Security Measures:**
- ✅ IP whitelisting via load balancer
- ✅ Separate address pool for industrial services
- ✅ Internal-only IP addresses (no public exposure)

#### NodePort (Development Only)

```yaml
service:
  type: NodePort
  # Note: Exposed on ALL nodes
```

**Security Concerns:**
- ❌ Accessible from any node IP
- ❌ High port numbers may bypass some firewalls
- ⚠️ Not recommended for production

**Mitigation:**
- Use firewall rules on nodes
- Deploy on dedicated worker nodes
- Consider switching to LoadBalancer

#### ClusterIP (Ingress/VPN)

```yaml
service:
  type: ClusterIP
```

**Security Benefits:**
- ✅ Not directly accessible from outside cluster
- ✅ Access via VPN or jump host only
- ✅ Best for defense-in-depth strategy

**Access Methods:**
```bash
# Engineering access via kubectl port-forward
kubectl port-forward -n codesys-gateway svc/codesys-edge-gateway 2455:2455

# Or via VPN to cluster network
```

## Secrets Management

### Password Storage

**Never store passwords in values.yaml:**

```yaml
# ❌ WRONG - Plain text in values
gateway:
  automationServer:
    username: "admin"
    password: "SuperSecret123"

# ✅ CORRECT - Use existing secret
gateway:
  automationServer:
    existingSecret: "gateway-credentials"
```

**Create secret manually:**
```bash
kubectl create secret generic gateway-credentials \
  --from-literal=username=admin \
  --from-literal=password='SuperSecret123' \
  -n codesys-gateway
```

### Sealed Secrets (Recommended)

```bash
# Install Sealed Secrets controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Seal your secret
echo -n SuperSecret123 | kubectl create secret generic gateway-credentials \
  --dry-run=client \
  --from-file=password=/dev/stdin \
  -o yaml | \
kubeseal -o yaml > gateway-credentials-sealed.yaml

# Apply sealed secret (safe to commit to git)
kubectl apply -f gateway-credentials-sealed.yaml
```

**In values.yaml:**
```yaml
gateway:
  automationServer:
    existingSecret: "gateway-credentials"

security:
  secretsEncryption:
    enabled: true
    provider: "sealed-secrets"
```

### External Secrets Operator

```yaml
# Install External Secrets Operator
# Then reference secrets from HashiCorp Vault, AWS Secrets Manager, etc.

security:
  secretsEncryption:
    enabled: true
    provider: "external-secrets"
```

## TLS/SSL Configuration

### Enable TLS for Automation Server Connection

```yaml
gateway:
  enableSsl: true
  automationServerUrl: "https://automation-server.example.com:4410"

security:
  tls:
    enabled: true
    certificateSource: "cert-manager"
    issuerRef:
      name: "ca-issuer"
      kind: "ClusterIssuer"
```

### Using Cert-Manager

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create CA issuer
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ca-issuer
spec:
  ca:
    secretName: ca-key-pair
EOF
```

**In values.yaml:**
```yaml
security:
  tls:
    enabled: true
    certificateSource: "cert-manager"
    issuerRef:
      name: "ca-issuer"
      kind: "ClusterIssuer"
```

### Manual Certificate Management

```yaml
security:
  tls:
    enabled: true
    certificateSource: "existing-secret"
    existingSecret: "gateway-tls-cert"
```

```bash
# Create TLS secret
kubectl create secret tls gateway-tls-cert \
  --cert=path/to/tls.crt \
  --key=path/to/tls.key \
  -n codesys-gateway
```

## Audit and Compliance

### Logging Configuration

```yaml
logging:
  level: INFO  # Options: DEBUG, INFO, WARNING, ERROR
  format: json  # Structured logging for SIEM integration
```

**Log Output:**
```json
{
  "timestamp": "2026-01-12T10:30:45Z",
  "level": "INFO",
  "event": "plc_discovered",
  "plc_address": "192.168.1.50",
  "plc_name": "Production-Line-1"
}
```

**Integration with Logging Systems:**
```bash
# Loki (if using Grafana Loki chart)
# Logs automatically collected via promtail

# View logs in Grafana:
# {namespace="codesys-gateway", app="codesys-edge-gateway"}

# Or view directly:
kubectl logs -n codesys-gateway -l app=codesys-edge-gateway -f
```

### Monitoring and Alerting

```yaml
monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
    namespace: monitoring
```

**Security-Relevant Metrics:**
- Failed authentication attempts
- Unauthorized connection attempts
- Gateway uptime and availability
- Network errors and anomalies

**Grafana Alert Example:**
```yaml
# Alert on repeated failed authentications
- alert: GatewayAuthFailures
  expr: rate(codesys_gateway_auth_failures[5m]) > 5
  annotations:
    summary: "High authentication failure rate on CODESYS Gateway"
```

## Resource Limits (DoS Prevention)

```yaml
resources:
  limits:
    cpu: 500m      # Prevent CPU exhaustion
    memory: 512Mi  # Prevent memory exhaustion
  requests:
    cpu: 100m
    memory: 128Mi
```

**Why Limits Matter:**
- Prevent gateway from consuming all node resources
- Mitigate resource-based denial of service
- Enable proper scheduling and QoS

## Multi-Tenancy and Isolation

### Resource Quotas

```yaml
resourceQuota:
  enabled: true
  hard:
    requests.cpu: "1"
    requests.memory: 1Gi
    limits.cpu: "2"
    limits.memory: 2Gi
    persistentvolumeclaims: "1"
```

**Prevents:**
- Excessive resource consumption
- PVC sprawl
- Runaway pod creation

### Namespace Isolation

**Deploy in dedicated namespace:**
```bash
kubectl create namespace codesys-gateway

kubectl label namespace codesys-gateway \
  pod-security.kubernetes.io/enforce=baseline \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted
```

### RBAC (Role-Based Access Control)

```yaml
# Example: Read-only access for monitoring
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: gateway-viewer
  namespace: codesys-gateway
rules:
  - apiGroups: [""]
    resources: ["pods", "pods/log"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["services"]
    verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: gateway-viewer-binding
  namespace: codesys-gateway
subjects:
  - kind: User
    name: engineer@fireball.com
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: gateway-viewer
  apiGroup: rbac.authorization.k8s.io
```

## Security Checklist for Production

### Pre-Deployment

- [ ] **Secrets:** All credentials in Kubernetes Secrets (not values.yaml)
- [ ] **TLS:** Enable SSL/TLS for Automation Server connection
- [ ] **Network Policy:** Enabled with ingress/egress restrictions
- [ ] **Service Type:** Using LoadBalancer with IP restrictions (not NodePort)
- [ ] **Pod Security:** Running with baseline or restricted security standard
- [ ] **Resource Limits:** CPU and memory limits configured
- [ ] **Logging:** JSON logging enabled, integrated with SIEM
- [ ] **Monitoring:** ServiceMonitor enabled with alerts configured

### Post-Deployment

- [ ] **Verify Network Policy:** Test that unauthorized access is blocked
- [ ] **Check Logs:** Review logs for errors or security events
- [ ] **Monitor Metrics:** Ensure metrics are collected and dashboards created
- [ ] **Test Failover:** Verify gateway recovers from pod restart
- [ ] **Penetration Test:** Scan for exposed services and vulnerabilities
- [ ] **Access Review:** Confirm only authorized users can access gateway
- [ ] **Backup:** Verify persistent volume backups are configured

### Ongoing Maintenance

- [ ] **Update Images:** Apply security patches monthly
- [ ] **Review Logs:** Weekly review of authentication and error logs
- [ ] **Audit Access:** Quarterly review of RBAC and network policies
- [ ] **Certificate Rotation:** Ensure TLS certificates auto-renew
- [ ] **Compliance Scan:** Run Kubernetes security scanners (kubesec, kube-bench)

## Compliance Frameworks

### IEC 62443 (Industrial Cybersecurity)

**Alignment:**
- Security Level 2 (SL2): Baseline configuration meets requirements
- Security Level 3 (SL3): Enable all security features + TLS + Network Policy
- Security Level 4 (SL4): Requires additional perimeter defenses

### NIST Cybersecurity Framework

**Coverage:**
- **Identify:** Asset inventory via Kubernetes labels
- **Protect:** Network Policy, RBAC, secrets encryption
- **Detect:** Logging, monitoring, alerting
- **Respond:** Incident response via logs and metrics
- **Recover:** Persistent volume backups, pod auto-restart

## Security Contact

For security issues or questions:
- **Email:** security@fireball-industries.com
- **Responsible Disclosure:** security-issues@fireball-industries.com
- **GPG Key:** Available at https://fireball-industries.com/pgp.txt

---

**Document Version:** 1.0  
**Last Updated:** January 2026  
**Author:** Patrick Ryan, Fireball Industries
