# Prometheus Pod - Security Guide

> **Fireball Industries - We Play With Fire So You Don't Have To™**

## Table of Contents

1. [Security Overview](#security-overview)
2. [Threat Model](#threat-model)
3. [Security Architecture](#security-architecture)
4. [Container Security](#container-security)
5. [RBAC Configuration](#rbac-configuration)
6. [Network Security](#network-security)
7. [Secret Management](#secret-management)
8. [Authentication & Authorization](#authentication--authorization)
9. [TLS/Encryption](#tlsencryption)
10. [Pod Security Standards](#pod-security-standards)
11. [Supply Chain Security](#supply-chain-security)
12. [Audit Logging](#audit-logging)
13. [Vulnerability Management](#vulnerability-management)
14. [Compliance](#compliance)
15. [Security Checklist](#security-checklist)
16. [Incident Response](#incident-response)

---

## Security Overview

Security isn't optional. This Prometheus pod is designed with security as a first-class concern, not an afterthought.

### Security Principles

1. **Least Privilege**: Minimal permissions required
2. **Defense in Depth**: Multiple layers of security
3. **Fail Secure**: Defaults deny, explicit allow
4. **Zero Trust**: Verify everything, trust nothing
5. **Secure by Default**: No insecure defaults

### Default Security Posture

Out of the box, this pod implements:

✅ **Non-root container** (UID 65534)  
✅ **Read-only root filesystem**  
✅ **Dropped capabilities** (ALL)  
✅ **No privilege escalation**  
✅ **Seccomp profile** (RuntimeDefault)  
✅ **Minimal RBAC** (read-only cluster access)  
✅ **No admin API** (disabled by default)  
✅ **Network policies** (optional, recommended)  
✅ **PodDisruptionBudget** (for HA)  

### Security vs Functionality Trade-offs

| Feature | Security Impact | Default | Notes |
|---------|----------------|---------|-------|
| Admin API | HIGH | Disabled | Enable only if needed |
| Remote Write | MEDIUM | Disabled | Validate endpoints |
| Ingress | MEDIUM | Disabled | Use TLS + auth |
| Network Policy | LOW | Disabled | Enable in production |
| Query Logging | LOW | Disabled | Logs may contain sensitive data |

---

## Threat Model

### Assets to Protect

1. **Metrics Data**: Time-series data, may contain sensitive info
2. **Configuration**: Scrape targets, credentials, endpoints
3. **Secrets**: TLS certs, API keys, passwords
4. **Cluster Access**: RBAC token for service discovery
5. **Availability**: Monitoring must stay up

### Threat Actors

| Actor | Motivation | Capabilities |
|-------|------------|--------------|
| External Attacker | Data theft, disruption | Network access |
| Malicious Pod | Lateral movement | Same namespace |
| Compromised Node | Full control | Node-level access |
| Insider Threat | Data exfiltration | Cluster access |
| Supply Chain | Backdoor, malware | Image tampering |

### Attack Vectors

**1. Container Escape**
- Threat: Attacker breaks out of container
- Mitigation: Non-root, read-only FS, seccomp, AppArmor

**2. RBAC Privilege Escalation**
- Threat: Abuse service account permissions
- Mitigation: Minimal RBAC, no write access

**3. Network Attacks**
- Threat: Unauthorized access to Prometheus API
- Mitigation: Network policies, ingress auth

**4. Data Exfiltration**
- Threat: Steal metrics data via API
- Mitigation: Authentication, encryption, audit logs

**5. Supply Chain Compromise**
- Threat: Malicious container image
- Mitigation: Image signing, scanning, SBOMs

**6. Denial of Service**
- Threat: Overload Prometheus, exhaust resources
- Mitigation: Resource limits, rate limiting

---

## Security Architecture

### Layers of Defense

```
┌─────────────────────────────────────────────────────────────────┐
│ Layer 7: Monitoring & Alerting                                 │
│ - Security metrics                                              │
│ - Intrusion detection alerts                                    │
└─────────────────────────────────────────────────────────────────┘
                              ▲
┌─────────────────────────────────────────────────────────────────┐
│ Layer 6: Application Security                                  │
│ - Admin API disabled                                            │
│ - Query restrictions                                            │
│ - Input validation                                              │
└─────────────────────────────────────────────────────────────────┘
                              ▲
┌─────────────────────────────────────────────────────────────────┐
│ Layer 5: Network Security                                      │
│ - Network policies (ingress/egress)                            │
│ - TLS encryption                                                │
│ - Ingress authentication                                        │
└─────────────────────────────────────────────────────────────────┘
                              ▲
┌─────────────────────────────────────────────────────────────────┐
│ Layer 4: RBAC & Identity                                       │
│ - Service account                                               │
│ - ClusterRole (read-only)                                       │
│ - No cluster-admin                                              │
└─────────────────────────────────────────────────────────────────┘
                              ▲
┌─────────────────────────────────────────────────────────────────┐
│ Layer 3: Pod Security                                          │
│ - SecurityContext (non-root, read-only FS)                     │
│ - Dropped capabilities                                          │
│ - Seccomp, AppArmor, SELinux                                   │
└─────────────────────────────────────────────────────────────────┘
                              ▲
┌─────────────────────────────────────────────────────────────────┐
│ Layer 2: Container Security                                    │
│ - Minimal image (alpine)                                        │
│ - Vulnerability scanning                                        │
│ - Image signing                                                 │
└─────────────────────────────────────────────────────────────────┘
                              ▲
┌─────────────────────────────────────────────────────────────────┐
│ Layer 1: Infrastructure Security                               │
│ - Node hardening                                                │
│ - Encrypted storage                                             │
│ - Network segmentation                                          │
└─────────────────────────────────────────────────────────────────┘
```

---

## Container Security

### Non-Root User

**Why**: Running as root is a privilege escalation risk.

**Implementation**:

```yaml
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 65534  # nobody user
  fsGroup: 65534
```

**Verification**:

```bash
kubectl exec -n monitoring prometheus-0 -- id
# Expected: uid=65534(nobody) gid=65534(nogroup)
```

### Read-Only Root Filesystem

**Why**: Prevents modification of container filesystem.

**Implementation**:

```yaml
securityContext:
  readOnlyRootFilesystem: true
```

**Writable directories** (via tmpfs):

```yaml
volumeMounts:
  - name: tmp
    mountPath: /tmp
  - name: storage
    mountPath: /prometheus  # Data volume
```

**Verification**:

```bash
kubectl exec -n monitoring prometheus-0 -- touch /test
# Expected: touch: /test: Read-only file system
```

### Dropped Capabilities

**Why**: Reduce kernel capabilities available to container.

**Implementation**:

```yaml
securityContext:
  capabilities:
    drop:
      - ALL  # Drop all capabilities
    # add:  # None added (unless NET_BIND_SERVICE needed for ports < 1024)
```

**What this prevents**:
- `CAP_NET_RAW`: No raw sockets (prevents ARP spoofing)
- `CAP_SYS_ADMIN`: No system administration
- `CAP_SYS_PTRACE`: No process tracing
- `CAP_CHOWN`: No file ownership changes
- And 25+ other capabilities

**Verification**:

```bash
kubectl exec -n monitoring prometheus-0 -- grep Cap /proc/1/status
# Should show minimal capabilities
```

### Privilege Escalation Prevention

**Why**: Prevents SUID binaries from granting root access.

**Implementation**:

```yaml
securityContext:
  allowPrivilegeEscalation: false
```

### Seccomp Profile

**Why**: Restricts system calls available to container.

**Implementation**:

```yaml
podSecurityContext:
  seccompProfile:
    type: RuntimeDefault
```

**What this blocks**:
- Dangerous syscalls (keyctl, add_key, etc.)
- Container escape attempts
- Kernel exploits

**Custom profile** (optional):

```yaml
podSecurityContext:
  seccompProfile:
    type: Localhost
    localhostProfile: profiles/prometheus-seccomp.json
```

See [Appendix: Seccomp Profile](#appendix-seccomp-profile) for custom profile.

### AppArmor (optional)

**Why**: Additional MAC (Mandatory Access Control) layer.

**Implementation**:

```yaml
podAnnotations:
  container.apparmor.security.beta.kubernetes.io/prometheus: runtime/default
```

**Custom profile**:

```bash
# Load custom AppArmor profile on nodes
sudo apparmor_parser -r /etc/apparmor.d/prometheus

# Annotate pod
podAnnotations:
  container.apparmor.security.beta.kubernetes.io/prometheus: localhost/prometheus
```

### SELinux (optional)

**For RHEL/CentOS/Fedora**:

```yaml
podSecurityContext:
  seLinuxOptions:
    type: spc_t  # Super Privileged Container (if needed)
    # Or use: type: container_t (default)
```

---

## RBAC Configuration

### Principle of Least Privilege

Prometheus needs cluster-wide read access for service discovery. **NO write access required**.

### Default RBAC

**ClusterRole**:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
rules:
  # Read-only access to nodes
  - apiGroups: [""]
    resources:
      - nodes
      - nodes/metrics
      - nodes/proxy
    verbs: ["get", "list", "watch"]
  
  # Read-only access to services/endpoints
  - apiGroups: [""]
    resources:
      - services
      - endpoints
    verbs: ["get", "list", "watch"]
  
  # Read-only access to pods
  - apiGroups: [""]
    resources:
      - pods
    verbs: ["get", "list", "watch"]
  
  # Read configmaps (for SD configs)
  - apiGroups: [""]
    resources:
      - configmaps
    verbs: ["get"]
  
  # Read ingresses
  - apiGroups: ["networking.k8s.io", "extensions"]
    resources:
      - ingresses
    verbs: ["get", "list", "watch"]
  
  # Non-resource URLs (API server metrics)
  - nonResourceURLs:
      - /metrics
      - /metrics/cadvisor
    verbs: ["get"]
```

**What is NOT granted**:
- ❌ create, update, delete, patch (no writes!)
- ❌ secrets (cannot read secrets)
- ❌ cluster-admin (hell no)
- ❌ namespace-admin (nope)

### ServiceAccount

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: monitoring
# No extra annotations unless using IAM roles (AWS IRSA, GCP Workload Identity)
```

### Restricting to Specific Namespaces

**If you want to limit Prometheus to specific namespaces**:

```yaml
# Replace ClusterRole with Role (per-namespace)
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: prometheus
  namespace: app-namespace-1
rules:
  - apiGroups: [""]
    resources:
      - pods
      - services
      - endpoints
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: prometheus
  namespace: app-namespace-1
subjects:
  - kind: ServiceAccount
    name: prometheus
    namespace: monitoring
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: prometheus
```

Repeat for each namespace you want Prometheus to scrape.

**Trade-off**: More RoleBindings to manage, but better isolation.

### Auditing RBAC Usage

**Check what Prometheus can do**:

```bash
# Can it list pods?
kubectl auth can-i list pods \\
  --as=system:serviceaccount:monitoring:prometheus

# Can it create pods? (should be no)
kubectl auth can-i create pods \\
  --as=system:serviceaccount:monitoring:prometheus

# Can it read secrets? (should be no)
kubectl auth can-i get secrets \\
  --as=system:serviceaccount:monitoring:prometheus
```

**Audit actual API calls**:

```bash
# Enable audit logging in kube-apiserver
# Check audit logs for requests from prometheus service account
kubectl logs -n kube-system kube-apiserver-* | grep prometheus
```

---

## Network Security

### Network Policies

**Why**: Restrict ingress/egress traffic to/from Prometheus.

**Enable**:

```yaml
networkPolicy:
  enabled: true
```

**Default policy**:

```yaml
ingress:
  # Allow from monitoring namespace (Grafana, etc.)
  - from:
    - namespaceSelector:
        matchLabels:
          name: monitoring
    ports:
    - protocol: TCP
      port: 9090

egress:
  # DNS
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: UDP
      port: 53
  
  # Kubernetes API
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 443
  
  # Scrape targets (all pods)
  - to:
    - podSelector: {}
```

**Strict egress** (allow only specific targets):

```yaml
networkPolicy:
  enabled: true
  egress:
    # DNS
    - to:
      - namespaceSelector:
          matchLabels:
            name: kube-system
        podSelector:
          matchLabels:
            k8s-app: kube-dns
      ports:
      - protocol: UDP
        port: 53
    
    # Kubernetes API
    - to:
      - podSelector:
          matchLabels:
            component: kube-apiserver
      ports:
      - protocol: TCP
        port: 6443
    
    # Scrape targets in specific namespaces
    - to:
      - namespaceSelector:
          matchLabels:
            prometheus.io/scrape: "true"
      ports:
      - protocol: TCP
        port: 8080
      - protocol: TCP
        port: 9090
```

**Verification**:

```bash
# Check network policy is applied
kubectl get networkpolicy -n monitoring

# Test connectivity
kubectl exec -n monitoring prometheus-0 -- wget -O- http://grafana.monitoring.svc
# Should work (same namespace)

kubectl exec -n monitoring prometheus-0 -- wget -O- http://evil-service.other-namespace.svc
# Should timeout (blocked)
```

### Service Mesh Integration

**Istio**:

```yaml
podAnnotations:
  sidecar.istio.io/inject: "true"
  traffic.sidecar.istio.io/includeInboundPorts: "9090"
  traffic.sidecar.istio.io/excludeOutboundPorts: "443"  # K8s API
```

**mTLS enforcement**:

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: prometheus
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: prometheus-pod
  mtls:
    mode: STRICT
```

**Linkerd**:

```yaml
podAnnotations:
  linkerd.io/inject: enabled
```

---

## Secret Management

### What Secrets Does Prometheus Need?

1. **Thanos Object Storage**: S3/GCS credentials
2. **Remote Write**: Authentication tokens
3. **TLS Certificates**: For HTTPS endpoints
4. **Basic Auth**: For Ingress authentication
5. **Alertmanager**: API keys, webhook tokens

### Secret Creation

**Thanos object storage**:

```bash
# Create objstore.yml
cat <<EOF > objstore.yml
type: S3
config:
  bucket: prometheus-thanos
  endpoint: s3.amazonaws.com
  access_key: YOUR_ACCESS_KEY
  secret_key: YOUR_SECRET_KEY
  insecure: false
EOF

# Create secret
kubectl create secret generic thanos-objstore-config \\
  --from-file=objstore.yml=objstore.yml \\
  -n monitoring

# Clean up local file
shred -u objstore.yml
```

**TLS certificates**:

```bash
# Generate self-signed cert (or use cert-manager)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \\
  -keyout tls.key \\
  -out tls.crt \\
  -subj "/CN=prometheus.example.com"

# Create secret
kubectl create secret tls prometheus-tls \\
  --cert=tls.crt \\
  --key=tls.key \\
  -n monitoring

# Clean up
shred -u tls.key tls.crt
```

**Basic auth** (for Ingress):

```bash
# Install htpasswd
sudo apt-get install apache2-utils

# Create password file
htpasswd -c auth admin
# Enter password when prompted

# Create secret
kubectl create secret generic prometheus-basic-auth \\
  --from-file=auth=auth \\
  -n monitoring

# Clean up
shred -u auth
```

### Secret Encryption at Rest

**Enable in Kubernetes**:

```yaml
# /etc/kubernetes/encryption-config.yaml (on control plane)
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: <BASE64 ENCODED 32-BYTE KEY>
      - identity: {}
```

**Verify encryption**:

```bash
# Create test secret
kubectl create secret generic test-secret --from-literal=data=test -n monitoring

# Check etcd (on control plane node)
ETCDCTL_API=3 etcdctl get /registry/secrets/monitoring/test-secret | hexdump -C
# Should see encrypted data, not plaintext "test"
```

### External Secret Management

**AWS Secrets Manager** (with External Secrets Operator):

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets
  namespace: monitoring
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: prometheus
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: thanos-objstore-config
  namespace: monitoring
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets
    kind: SecretStore
  target:
    name: thanos-objstore-config
  data:
    - secretKey: objstore.yml
      remoteRef:
        key: prometheus/thanos-objstore
```

**HashiCorp Vault**:

```yaml
podAnnotations:
  vault.hashicorp.com/agent-inject: "true"
  vault.hashicorp.com/role: "prometheus"
  vault.hashicorp.com/agent-inject-secret-objstore.yml: "secret/data/prometheus/thanos"
  vault.hashicorp.com/agent-inject-template-objstore.yml: |
    {{- with secret "secret/data/prometheus/thanos" -}}
    {{ .Data.data.config }}
    {{- end -}}
```

### Secret Rotation

**Automated rotation** (every 90 days):

```bash
# 1. Generate new credentials in cloud provider
# 2. Update secret
kubectl create secret generic thanos-objstore-config \\
  --from-file=objstore.yml=new-objstore.yml \\
  --dry-run=client -o yaml | kubectl apply -f -

# 3. Restart pods (if using secret as file)
kubectl rollout restart statefulset/prometheus -n monitoring

# 4. Verify new credentials work
kubectl logs -n monitoring prometheus-0 | grep thanos

# 5. Revoke old credentials
```

---

## Authentication & Authorization

### Prometheus Web UI Access

**Options**:

1. **No auth** (default, use network policies for access control)
2. **Ingress basic auth** (nginx ingress controller)
3. **OAuth2 proxy** (Google, GitHub, Okta, etc.)
4. **Service mesh mTLS** (Istio, Linkerd)

### Basic Auth via Ingress

**Create auth secret** (see Secret Management section)

**Configure ingress**:

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: prometheus-basic-auth
    nginx.ingress.kubernetes.io/auth-realm: "Prometheus Authentication Required"
  hosts:
    - host: prometheus.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: prometheus-tls
      hosts:
        - prometheus.example.com
```

### OAuth2 Proxy

**Deploy oauth2-proxy**:

```bash
helm install oauth2-proxy oauth2-proxy/oauth2-proxy \\
  --namespace monitoring \\
  --set config.clientID=YOUR_CLIENT_ID \\
  --set config.clientSecret=YOUR_CLIENT_SECRET \\
  --set config.cookieSecret=$(openssl rand -base64 32) \\
  --set extraArgs.provider=google \\
  --set extraArgs.email-domain=example.com \\
  --set extraArgs.upstream=http://prometheus.monitoring.svc:9090
```

**Update ingress**:

```yaml
ingress:
  annotations:
    nginx.ingress.kubernetes.io/auth-url: "https://oauth2-proxy.example.com/oauth2/auth"
    nginx.ingress.kubernetes.io/auth-signin: "https://oauth2-proxy.example.com/oauth2/start?rd=$escaped_request_uri"
```

### Query Access Control

Prometheus doesn't have built-in query ACLs. Use a proxy:

**Prom-label-proxy**:

```bash
# Enforces label-based filtering per user
# Example: User A can only see namespace=team-a metrics

helm install prom-label-proxy \\
  --set upstream=http://prometheus.monitoring.svc:9090 \\
  --set enforceLabel=namespace
```

**Custom proxy**:

```go
// Example: Filter queries by user JWT claims
func PrometheusProxy(w http.ResponseWriter, r *http.Request) {
    user := getUserFromJWT(r)
    query := r.URL.Query().Get("query")
    
    // Inject namespace filter
    filtered := query + fmt.Sprintf("{namespace=\"%s\"}", user.Namespace)
    
    // Proxy to Prometheus
    proxyRequest(w, r, filtered)
}
```

---

## TLS/Encryption

### Ingress TLS

**Using cert-manager**:

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create ClusterIssuer
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            class: nginx
EOF
```

**Configure ingress**:

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: prometheus.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: prometheus-tls-auto
      hosts:
        - prometheus.example.com
```

**Manual certificate**:

```bash
# Generate CSR
openssl req -new -newkey rsa:2048 -nodes \\
  -keyout prometheus.key \\
  -out prometheus.csr \\
  -subj "/CN=prometheus.example.com"

# Get cert from CA
# (Submit CSR to your CA)

# Create secret
kubectl create secret tls prometheus-tls \\
  --cert=prometheus.crt \\
  --key=prometheus.key \\
  -n monitoring
```

### Scrape Target TLS

**Scrape HTTPS endpoints**:

```yaml
scrape_configs:
  - job_name: 'secure-app'
    scheme: https
    tls_config:
      ca_file: /etc/prometheus/certs/ca.crt
      cert_file: /etc/prometheus/certs/client.crt
      key_file: /etc/prometheus/certs/client.key
      insecure_skip_verify: false  # Verify cert
    static_configs:
      - targets:
          - secure-app.example.com:443
```

**Mount certificates**:

```yaml
extraVolumes:
  - name: scrape-certs
    secret:
      secretName: prometheus-scrape-certs

extraVolumeMounts:
  - name: scrape-certs
    mountPath: /etc/prometheus/certs
    readOnly: true
```

### Remote Write TLS

```yaml
remoteWrite:
  enabled: true
  configs:
    - url: https://remote-storage.example.com/api/v1/write
      tls_config:
        ca_file: /etc/prometheus/remote-write-certs/ca.crt
        cert_file: /etc/prometheus/remote-write-certs/client.crt
        key_file: /etc/prometheus/remote-write-certs/client.key
      bearer_token: YOUR_API_TOKEN  # Or use bearer_token_file
```

---

## Pod Security Standards

Kubernetes 1.25+ uses [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/) instead of PodSecurityPolicies.

### Compliance Level

This Prometheus pod is compliant with **Restricted** level (most strict).

**Restricted requirements**:

| Requirement | Implementation |
|-------------|----------------|
| runAsNonRoot: true | ✅ UID 65534 |
| Capabilities dropped | ✅ ALL dropped |
| Privilege escalation | ✅ Disabled |
| Read-only rootFS | ✅ Enabled |
| Seccomp | ✅ RuntimeDefault |
| Volume types | ✅ ConfigMap, Secret, PVC, EmptyDir only |

### Namespace-Level Enforcement

**Enforce Restricted mode**:

```bash
kubectl label namespace monitoring \\
  pod-security.kubernetes.io/enforce=restricted \\
  pod-security.kubernetes.io/audit=restricted \\
  pod-security.kubernetes.io/warn=restricted
```

**Verify compliance**:

```bash
kubectl get namespace monitoring -o yaml | grep pod-security

# Deploy and check for warnings
helm install prometheus fireball/prometheus-pod -n monitoring
# Should succeed without warnings
```

**Baseline or Privileged** (if you need to relax):

```bash
# Baseline (less strict)
kubectl label namespace monitoring \\
  pod-security.kubernetes.io/enforce=baseline \\
  --overwrite

# Privileged (no restrictions, NOT RECOMMENDED)
kubectl label namespace monitoring \\
  pod-security.kubernetes.io/enforce=privileged \\
  --overwrite
```

---

## Supply Chain Security

### Image Provenance

**Official Prometheus images**:
- Source: `docker.io/prom/prometheus`
- Built by: Prometheus Authors
- Signed: No (as of 2026, use Cosign manually)

**Verify image**:

```bash
# Pull image
docker pull prom/prometheus:v2.49.0

# Inspect
docker inspect prom/prometheus:v2.49.0

# Check for known vulnerabilities
trivy image prom/prometheus:v2.49.0
```

### Image Signing (Cosign)

**Sign images**:

```bash
# Generate key pair
cosign generate-key-pair

# Sign
cosign sign --key cosign.key prom/prometheus:v2.49.0
```

**Verify in cluster** (with Sigstore policy controller):

```yaml
apiVersion: policy.sigstore.dev/v1beta1
kind: ClusterImagePolicy
metadata:
  name: prometheus-signature
spec:
  images:
    - glob: "docker.io/prom/prometheus:**"
  authorities:
    - keyless:
        url: https://fulcio.sigstore.dev
```

### Software Bill of Materials (SBOM)

**Generate SBOM**:

```bash
# Using syft
syft prom/prometheus:v2.49.0 -o spdx-json > prometheus-sbom.json

# Upload to artifact repository for compliance
```

### Vulnerability Scanning

**Scan on push** (CI/CD):

```yaml
# .github/workflows/scan.yml
name: Security Scan
on: push
jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: aquasecurity/trivy-action@master
        with:
          image-ref: prom/prometheus:v2.49.0
          format: 'sarif'
          output: 'trivy-results.sarif'
      - uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'
```

**Scan running images**:

```bash
# Scan deployed image
kubectl get pods -n monitoring prometheus-0 -o jsonpath='{.spec.containers[0].image}' | xargs trivy image
```

### Private Registry

**Use internal registry**:

```yaml
image:
  repository: internal-registry.example.com/prometheus
  tag: v2.49.0-verified
  pullSecrets:
    - name: regcred
```

**Create pull secret**:

```bash
kubectl create secret docker-registry regcred \\
  --docker-server=internal-registry.example.com \\
  --docker-username=admin \\
  --docker-password=PASSWORD \\
  --docker-email=admin@example.com \\
  -n monitoring
```

---

## Audit Logging

### Kubernetes Audit Logs

**Track Prometheus API calls to Kubernetes**:

```bash
# On control plane, check audit logs
tail -f /var/log/kubernetes/audit.log | grep prometheus

# Look for:
# - ServiceAccount authentication
# - API requests (list pods, get services, etc.)
# - Authorization decisions
```

### Prometheus Query Logs

**Enable query logging**:

```yaml
prometheus:
  enableQueryLog: true
```

**Queries logged to**:

```bash
kubectl logs -n monitoring prometheus-0 | grep query
```

**Query log format**:

```json
{
  "level": "info",
  "ts": "2026-01-11T10:30:00.000Z",
  "caller": "query_logger.go:87",
  "query": "up{job=\"kubernetes-nodes\"}",
  "timestamp": "2026-01-11T10:30:00.000Z"
}
```

**Security use cases**:
- Detect unauthorized queries
- Identify expensive queries (DoS attempts)
- Audit data access

### Export to SIEM

**Fluent Bit sidecar**:

```yaml
# In Deployment/StatefulSet
containers:
  - name: fluent-bit
    image: fluent/fluent-bit:latest
    volumeMounts:
      - name: varlog
        mountPath: /var/log
      - name: fluent-bit-config
        mountPath: /fluent-bit/etc/
volumes:
  - name: fluent-bit-config
    configMap:
      name: fluent-bit-config
```

**Fluent Bit config**:

```ini
[INPUT]
    Name              tail
    Path              /var/log/prometheus.log
    Parser            json
    Tag               prometheus.query

[OUTPUT]
    Name              es
    Match             prometheus.*
    Host              elasticsearch.logging.svc
    Port              9200
    Index             prometheus-audit
```

---

## Vulnerability Management

### Patching Cadence

**Prometheus releases**:
- Minor releases: Every 6 weeks
- Patch releases: As needed (security fixes)
- LTS: None (always use latest)

**Update strategy**:

```bash
# 1. Check for new release
helm search repo fireball/prometheus-pod

# 2. Review changelog
# https://github.com/prometheus/prometheus/releases

# 3. Test in staging
helm upgrade prometheus-staging fireball/prometheus-pod \\
  --namespace monitoring-staging \\
  --version 1.1.0

# 4. Validate
# Run queries, check targets, test alerts

# 5. Upgrade production
helm upgrade prometheus fireball/prometheus-pod \\
  --namespace monitoring \\
  --version 1.1.0
```

### CVE Monitoring

**Subscribe to**:
- Prometheus mailing list: prometheus-users@googlegroups.com
- GitHub security advisories: https://github.com/prometheus/prometheus/security/advisories
- Kubernetes CVE feed: https://kubernetes.io/docs/reference/issues-security/

**Automated scanning**:

```bash
# Daily Trivy scan
trivy image --severity HIGH,CRITICAL prom/prometheus:v2.49.0

# Fail if vulnerabilities found
trivy image --exit-code 1 --severity CRITICAL prom/prometheus:v2.49.0
```

---

## Compliance

### Common Standards

**SOC 2**:
- ✅ Encryption at rest (PVC encryption)
- ✅ Encryption in transit (TLS)
- ✅ Access controls (RBAC, NetworkPolicy)
- ✅ Audit logging (query logs, K8s audit)

**PCI-DSS**:
- ✅ Network segmentation (NetworkPolicy)
- ✅ Encryption (TLS everywhere)
- ✅ Access controls (RBAC)
- ✅ Monitoring (self-monitoring)

**HIPAA**:
- ✅ Encryption (at rest & in transit)
- ✅ Access logging (audit logs)
- ✅ Access controls (RBAC, auth)
- ⚠️ PHI in metrics? (sanitize labels!)

**GDPR**:
- ⚠️ Personal data in metrics? (use relabeling to drop)
- ✅ Right to erasure (delete blocks containing user data)
- ✅ Encryption (TLS, encrypted storage)

### PII/PHI Sanitization

**Problem**: Metrics may contain sensitive labels.

**Example**:

```promql
# BAD: Contains email address
http_requests_total{user_email="john@example.com"}

# BAD: Contains SSN
user_login_total{ssn="123-45-6789"}
```

**Solution**: Relabeling

```yaml
scrape_configs:
  - job_name: 'app'
    relabel_configs:
      # Drop labels matching patterns
      - source_labels: [__meta_kubernetes_pod_label_user_email]
        regex: '.*@.*'
        action: drop
      
      # Hash sensitive labels
      - source_labels: [user_id]
        target_label: user_id_hash
        action: hashmod
        modulus: 1000000
      
      # Remove original
      - regex: 'user_id'
        action: labeldrop
```

---

## Security Checklist

### Pre-Deployment

- [ ] Review values.yaml security settings
- [ ] Non-root user (UID 65534) enabled
- [ ] Read-only root filesystem enabled
- [ ] All capabilities dropped
- [ ] Seccomp profile set
- [ ] RBAC minimized (no cluster-admin)
- [ ] Network policies defined (if using)
- [ ] Secrets created securely (not in Git)
- [ ] TLS certificates ready (for ingress)
- [ ] PVC encryption enabled (in StorageClass)
- [ ] Admin API disabled (unless required)
- [ ] Pod Security Standards label on namespace

### Post-Deployment

- [ ] Verify pod runs as non-root (`kubectl exec ... -- id`)
- [ ] Check RBAC permissions (`kubectl auth can-i ...`)
- [ ] Test network policies (`kubectl exec ... -- wget ...`)
- [ ] Verify TLS on ingress (`curl https://...`)
- [ ] Check for security warnings (`kubectl get events`)
- [ ] Review audit logs (K8s audit, query logs)
- [ ] Scan image for vulnerabilities (`trivy image ...`)
- [ ] Verify secrets are encrypted (etcd check)
- [ ] Test authentication (try unauthenticated access)
- [ ] Set up security alerts (unauthorized access, etc.)

### Ongoing

- [ ] Weekly vulnerability scans
- [ ] Monthly RBAC reviews
- [ ] Quarterly secret rotation
- [ ] Monitor security metrics
- [ ] Review audit logs regularly
- [ ] Keep Prometheus updated
- [ ] Incident response plan tested

---

## Incident Response

### Security Incident Types

**1. Unauthorized Access**
- Alert: Failed auth attempts
- Response: Revoke credentials, audit access logs, patch vulnerability

**2. Data Exfiltration**
- Alert: Unusual query patterns, high bandwidth
- Response: Block IP, revoke tokens, forensics

**3. Container Escape**
- Alert: Process outside container namespace
- Response: Isolate node, kill pod, investigate

**4. Compromised Credentials**
- Alert: Leaked secret in logs/Git
- Response: Rotate immediately, revoke old, audit usage

### Incident Response Plan

**1. Detection**
```bash
# Monitor for suspicious queries
rate(prometheus_http_requests_total{code=~"4..|5.."}[5m]) > 10

# Unusual data access
rate(prometheus_tsdb_head_samples_appended_total[5m]) > 100000
```

**2. Containment**
```bash
# Isolate pod
kubectl label pod prometheus-0 quarantine=true -n monitoring
kubectl patch networkpolicy prometheus -n monitoring -p '{"spec":{"podSelector":{"matchLabels":{"quarantine":"true"}}}}'

# Or delete immediately
kubectl delete pod prometheus-0 -n monitoring
```

**3. Investigation**
```bash
# Capture pod state
kubectl get pod prometheus-0 -n monitoring -o yaml > incident-pod.yaml
kubectl logs prometheus-0 -n monitoring --previous > incident-logs.txt

# Check events
kubectl get events -n monitoring --sort-by='.lastTimestamp'

# Audit K8s API access
grep prometheus /var/log/kubernetes/audit.log > incident-audit.log
```

**4. Remediation**
```bash
# Rotate credentials
kubectl delete secret thanos-objstore-config -n monitoring
kubectl create secret generic thanos-objstore-config --from-file=objstore.yml

# Patch vulnerability
helm upgrade prometheus fireball/prometheus-pod --version 1.0.1

# Update RBAC
kubectl apply -f rbac-updated.yaml
```

**5. Post-Incident**
- Root cause analysis
- Update runbooks
- Patch vulnerabilities
- Improve detection

---

## Appendix: Seccomp Profile

**Custom seccomp profile** for Prometheus:

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": [
    "SCMP_ARCH_X86_64",
    "SCMP_ARCH_X86",
    "SCMP_ARCH_AARCH64",
    "SCMP_ARCH_ARM"
  ],
  "syscalls": [
    {
      "names": [
        "accept4",
        "access",
        "arch_prctl",
        "bind",
        "brk",
        "close",
        "connect",
        "dup",
        "epoll_create1",
        "epoll_ctl",
        "epoll_pwait",
        "exit",
        "exit_group",
        "fstat",
        "futex",
        "getcwd",
        "getpid",
        "getrlimit",
        "getsockname",
        "getsockopt",
        "listen",
        "mmap",
        "mprotect",
        "munmap",
        "nanosleep",
        "open",
        "openat",
        "read",
        "readlink",
        "rt_sigaction",
        "rt_sigprocmask",
        "rt_sigreturn",
        "sched_getaffinity",
        "sched_yield",
        "set_tid_address",
        "setitimer",
        "setsockopt",
        "socket",
        "stat",
        "tgkill",
        "write",
        "writev"
      ],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
```

Save as `prometheus-seccomp.json` and deploy to nodes.

---

## Appendix: Security Metrics

**Monitor security-related metrics**:

```promql
# Failed authentication attempts (requires auth)
rate(prometheus_http_requests_total{code="401"}[5m])

# Unauthorized access attempts
rate(prometheus_http_requests_total{code="403"}[5m])

# High query rate (possible DoS)
rate(prometheus_http_requests_total{handler="/api/v1/query"}[5m]) > 100

# RBAC denials (check K8s audit logs)
# No built-in metric, use audit log exporter

# Unusual data access patterns
changes(prometheus_tsdb_head_series[1h]) > 10000
```

---

## Conclusion

Security is not a checkbox, it's a process. This Prometheus pod is secure by default, but you must:

1. **Enable network policies** (they're optional)
2. **Use TLS** for ingress
3. **Rotate secrets** regularly
4. **Monitor for anomalies**
5. **Keep updated** with patches
6. **Audit regularly**

Questions? Issues? Security concerns?
- GitHub: https://github.com/fireball-industries/prometheus-pod/security
- Email: security@fireballindustries.com

**Responsible Disclosure**: We take security seriously. If you find a vulnerability, please email security@fireballindustries.com with details. We'll acknowledge within 24 hours and provide a timeline for fixes.

---

**Fireball Industries - We Play With Fire So You Don't Have To™**

*This security guide is maintained by humans who have been paged at 3am due to security incidents. We write these docs so you don't have to experience that pain. You're welcome.*
