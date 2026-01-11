# Security Guide - InfluxDB Pod

**Fireball Industries** - *"Ignite Your Factory Efficiency"™*

> Industrial security: Because "admin/admin" stopped being funny in 2010.

## Table of Contents

- [Threat Model](#threat-model)
- [Authentication & Authorization](#authentication--authorization)
- [Network Security](#network-security)
- [Encryption](#encryption)
- [Pod Security](#pod-security)
- [Secrets Management](#secrets-management)
- [Compliance](#compliance)
- [Audit Logging](#audit-logging)
- [Incident Response](#incident-response)
- [Security Checklist](#security-checklist)

## 🎯 Threat Model

### Industrial OT/IT Convergence Threats

InfluxDB sits at the OT/IT boundary, collecting data from industrial systems:

**Threats:**
1. **Unauthorized Access**: Attackers accessing production data
2. **Data Tampering**: Modification of historical records (quality/compliance)
3. **Denial of Service**: Database unavailability affecting monitoring
4. **Data Exfiltration**: Theft of proprietary manufacturing data
5. **Supply Chain**: Compromised container images
6. **Insider Threats**: Malicious or negligent employees
7. **Network Sniffing**: Unencrypted data in transit
8. **Ransomware**: Encryption of time-series data

**Risk Level**: HIGH for production factories, CRITICAL for regulated industries (pharma, food, aerospace)

## 🔐 Authentication & Authorization

### Token-Based Authentication

InfluxDB 2.x uses API tokens (NOT username/password):

```bash
# Generate admin token (done automatically by chart)
kubectl get secret influxdb-influxdb-pod-auth \
  -n influxdb \
  -o jsonpath='{.data.admin-token}' | base64 --decode
```

### Token Types

1. **Admin Token** (ALL permissions)
   - Created during initial setup
   - Store in secrets manager (Vault, AWS Secrets Manager)
   - Rotate every 90 days minimum

2. **Read-Only Token** (for dashboards)
   ```bash
   influx auth create \
     --org my-factory \
     --read-bucket sensors \
     --read-bucket production \
     --description "Grafana dashboard" \
     --token <ADMIN_TOKEN>
   ```

3. **Write-Only Token** (for Telegraf agents)
   ```bash
   influx auth create \
     --org my-factory \
     --write-bucket sensors \
     --description "Telegraf on line 1" \
     --token <ADMIN_TOKEN>
   ```

4. **Bucket-Specific Tokens**
   ```bash
   influx auth create \
     --org my-factory \
     --read-bucket quality \
     --write-bucket quality \
     --description "QA system access" \
     --token <ADMIN_TOKEN>
   ```

### Token Rotation

**Best Practice**: Rotate tokens every 90 days

```bash
# Create new token
NEW_TOKEN=$(influx auth create --org my-factory --all-access --json | jq -r .token)

# Update applications to use new token
kubectl create secret generic influxdb-new-token \
  --from-literal=token=$NEW_TOKEN \
  -n influxdb

# Delete old token after verification
influx auth delete --id <OLD_TOKEN_ID>
```

### Disable Password Authentication

InfluxDB Pod disables password auth by default (tokens only):

```yaml
influxdb:
  adminToken: ""  # Auto-generated
  adminPassword: ""  # Not used in production
```

**Why?** Passwords are weak, tokens are:
- Revocable
- Scoped to specific permissions
- Auditable
- Not vulnerable to brute force

## 🌐 Network Security

### Network Policies

Restrict traffic to InfluxDB:

```yaml
networkPolicy:
  enabled: true
  ingress:
    # Allow Grafana
    - namespaceSelector:
        matchLabels:
          name: monitoring
      podSelector:
        matchLabels:
          app: grafana
    # Allow Telegraf agents
    - namespaceSelector:
        matchLabels:
          name: telegraf
  egress:
    # DNS only
    - to:
      - namespaceSelector: {}
      ports:
        - protocol: UDP
          port: 53
```

### OT/IT Network Segmentation

For Purdue Model compliance (IEC 62443):

```
┌─────────────────────────────────┐
│ Level 4: Enterprise (IT)        │  Grafana, Business Intelligence
│   ↓ Firewalled                  │
├─────────────────────────────────┤
│ Level 3.5: DMZ                  │  InfluxDB Pod (YOU ARE HERE)
│   ↓ Firewalled                  │
├─────────────────────────────────┤
│ Level 3: Operations (OT)        │  SCADA, Historians
│   ↓ Firewalled                  │
├─────────────────────────────────┤
│ Level 2: Control                │  PLCs, DCS
│   ↓ Firewalled                  │
├─────────────────────────────────┤
│ Level 1: Devices                │  Sensors, Actuators
└─────────────────────────────────┘
```

**Recommendation**: Deploy InfluxDB in DMZ with strict firewall rules:
- Allow inbound: Only from SCADA/MES systems (specific IPs)
- Allow outbound: Only to Grafana/BI systems
- Deny all other traffic

### Service Mesh (Advanced)

For zero-trust networks, use Istio/Linkerd:

```yaml
# Example: Istio AuthorizationPolicy
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: influxdb-access
  namespace: influxdb
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: influxdb-pod
  action: ALLOW
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/monitoring/sa/grafana"]
    to:
    - operation:
        methods: ["GET"]
        paths: ["/api/v2/query"]
```

## 🔒 Encryption

### TLS/HTTPS (In Transit)

**REQUIRED for production**. Enable via Ingress:

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
  hosts:
    - host: influxdb.factory.acme.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: influxdb-tls
      hosts:
        - influxdb.factory.acme.com
```

### Mutual TLS (mTLS)

For highly secure environments:

```yaml
ingress:
  annotations:
    nginx.ingress.kubernetes.io/auth-tls-secret: "influxdb/client-ca"
    nginx.ingress.kubernetes.io/auth-tls-verify-client: "on"
```

### Encryption at Rest

InfluxDB does not provide built-in encryption at rest. Use:

1. **Encrypted Storage Classes** (cloud providers)
   - AWS EBS: `encrypted: true` in StorageClass
   - GCP PD: Encrypted by default
   - Azure Disk: `encrypted: true`

2. **dm-crypt/LUKS** (bare metal)
   ```bash
   # Create encrypted volume
   cryptsetup luksFormat /dev/sdb
   cryptsetup open /dev/sdb influxdb_encrypted
   mkfs.ext4 /dev/mapper/influxdb_encrypted
   ```

3. **Storage-level encryption** (Ceph, Longhorn)

### Backup Encryption

Encrypt backups before storing:

```bash
# Backup and encrypt
influx backup /tmp/backup
tar czf - /tmp/backup | \
  openssl enc -aes-256-cbc -salt -pbkdf2 \
  -out influxdb-backup-$(date +%Y%m%d).tar.gz.enc

# Upload to S3
aws s3 cp influxdb-backup-*.tar.gz.enc s3://backups/
```

## 🛡️ Pod Security

### Pod Security Standards

InfluxDB Pod runs with **restricted** profile:

```yaml
security:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
  readOnlyRootFilesystem: false  # InfluxDB needs writable /tmp
  capabilities:
    drop:
      - ALL
  podSecurityStandard: restricted
```

### AppArmor (Optional)

```yaml
podAnnotations:
  container.apparmor.security.beta.kubernetes.io/influxdb: runtime/default
```

### Seccomp Profile

Enabled by default with restricted PSS:

```yaml
securityContext:
  seccompProfile:
    type: RuntimeDefault
```

### Resource Limits (DoS Prevention)

Prevent resource exhaustion:

```yaml
resources:
  limits:
    cpu: "4"
    memory: "8Gi"
  requests:
    cpu: "2"
    memory: "8Gi"
```

## 🔑 Secrets Management

### Kubernetes Secrets (Basic)

Default method (secrets stored in etcd):

```bash
# Create token secret
kubectl create secret generic influxdb-token \
  --from-literal=admin-token=<YOUR_TOKEN> \
  -n influxdb
```

**Limitations:**
- Secrets stored base64-encoded (not encrypted)
- Visible to cluster admins
- Not rotated automatically

### HashiCorp Vault (Recommended)

Integration with Vault for token management:

```yaml
# vault-secret.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: influxdb
  annotations:
    vault.hashicorp.com/role: influxdb
---
apiVersion: v1
kind: Pod
metadata:
  annotations:
    vault.hashicorp.com/agent-inject: "true"
    vault.hashicorp.com/agent-inject-secret-token: "secret/data/influxdb/admin-token"
    vault.hashicorp.com/role: "influxdb"
```

### AWS Secrets Manager

For EKS deployments:

```yaml
# Install External Secrets Operator
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets -n kube-system

# Create ExternalSecret
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: influxdb-token
spec:
  secretStoreRef:
    name: aws-secretsmanager
    kind: SecretStore
  target:
    name: influxdb-token
  data:
  - secretKey: admin-token
    remoteRef:
      key: influxdb/admin-token
```

### Sealed Secrets

Encrypt secrets in Git:

```bash
# Install Sealed Secrets
helm install sealed-secrets sealed-secrets/sealed-secrets -n kube-system

# Create sealed secret
kubectl create secret generic influxdb-token \
  --from-literal=admin-token=<YOUR_TOKEN> \
  --dry-run=client -o yaml | \
  kubeseal -o yaml > sealed-secret.yaml

# Commit sealed-secret.yaml to Git (safe!)
```

## 📋 Compliance

### 21 CFR Part 11 (FDA Electronic Records)

For pharmaceutical/medical device manufacturing:

**Requirements:**
- **Audit trails**: Who accessed what, when
- **Data integrity**: Immutable records
- **Access controls**: Role-based permissions
- **Electronic signatures**: Validated user actions
- **Retention**: 7+ years

**Implementation:**
```yaml
# Enable audit logging
influxdb:
  logLevel: info  # Log all API access

# Long retention for quality data
industrialBuckets:
  buckets:
    - name: quality
      retention: "2555d"  # 7 years
      description: "Quality control records (21 CFR Part 11)"

# Backup with validation
backup:
  enabled: true
  retention: 84  # 12 weeks minimum
  destination:
    type: s3
    s3:
      bucket: validated-backups
```

**Audit trail queries:**
```bash
# Query access logs
kubectl logs -n influxdb <pod> | grep "POST /api/v2/write"
```

### ISO 9001 (Quality Management)

**Requirements:**
- Document control
- Record retention (typically 3-7 years)
- Traceability

```yaml
industrialBuckets:
  buckets:
    - name: production
      retention: "1095d"  # 3 years
    - name: quality
      retention: "2555d"  # 7 years
```

### IEC 62443 (Industrial Cybersecurity)

**Requirements:**
- Network segmentation (see Network Security above)
- Access control
- Integrity checking
- Security monitoring

```yaml
# Network policies
networkPolicy:
  enabled: true

# Pod security
security:
  podSecurityStandard: restricted

# Monitoring
monitoring:
  prometheus:
    enabled: true
```

### GDPR (Data Privacy)

**Requirements:**
- Right to deletion
- Data minimization
- Access logs

```bash
# Delete user data (right to erasure)
influx delete \
  --bucket sensors \
  --start 1970-01-01T00:00:00Z \
  --stop $(date -u +"%Y-%m-%dT%H:%M:%SZ") \
  --predicate 'user_id="123456"'
```

## 📝 Audit Logging

### InfluxDB Access Logs

All API requests are logged:

```bash
# View access logs
kubectl logs -n influxdb <pod> | grep "api/v2"

# Example log entry
# {"level":"info","ts":1736611200,"caller":"http/handler.go:123","msg":"HTTP request","method":"POST","path":"/api/v2/write","status":204,"duration":"12ms","user":"telegraf-agent"}
```

### Kubernetes Audit Logs

Enable cluster audit logging to track who accessed InfluxDB:

```yaml
# kube-apiserver audit policy
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: RequestResponse
  resources:
  - group: ""
    resources: ["secrets", "configmaps"]
  namespaces: ["influxdb"]
```

### SIEM Integration

Forward logs to Security Information and Event Management:

```yaml
# Fluentd/Fluent Bit configuration
<filter kubernetes.**influxdb**>
  @type parser
  key_name log
  <parse>
    @type json
  </parse>
</filter>

<match kubernetes.**influxdb**>
  @type forward
  <server>
    host siem.company.com
    port 24224
  </server>
</match>
```

## 🚨 Incident Response

### Unauthorized Access Detected

1. **Immediately revoke token**:
   ```bash
   influx auth delete --id <COMPROMISED_TOKEN_ID>
   ```

2. **Rotate all tokens**:
   ```bash
   # Script in scripts/rotate-tokens.ps1
   ./scripts/manage-influxdb.ps1 -Action rotate-tokens
   ```

3. **Check access logs**:
   ```bash
   kubectl logs -n influxdb <pod> --since=24h | grep "401\|403"
   ```

4. **Assess damage**:
   ```bash
   # Check for deleted buckets
   influx bucket list
   
   # Check for modified data
   influx query 'from(bucket: "sensors") |> range(start: -24h) |> count()'
   ```

### Data Tampering

1. **Restore from backup**:
   ```bash
   influx restore /backup/influxdb-<date>
   ```

2. **Validate data integrity**:
   ```bash
   # Compare checksums
   influx backup /tmp/current
   diff -r /backup/influxdb-<date> /tmp/current
   ```

3. **Investigate**:
   - Review audit logs
   - Check who had write access
   - Analyze query patterns

### Ransomware

1. **Isolate immediately**:
   ```bash
   # Delete ingress
   kubectl delete ingress influxdb -n influxdb
   
   # Apply network policy
   kubectl apply -f networkpolicy-lockdown.yaml
   ```

2. **Do NOT pay ransom** (you have backups, right?)

3. **Restore from backup**:
   ```bash
   # Delete infected deployment
   helm uninstall influxdb -n influxdb
   
   # Restore from clean backup
   helm install influxdb ./influxdb-pod -f values-prod.yaml
   
   # Restore data
   kubectl exec -n influxdb <pod> -- \
     influx restore /backup/influxdb-<clean-date>
   ```

## ✅ Security Checklist

### Pre-Production

- [ ] Admin token stored in secrets manager (Vault, AWS Secrets Manager)
- [ ] TLS/HTTPS enabled via Ingress
- [ ] Network policies configured
- [ ] Pod Security Standard set to `restricted`
- [ ] Resource limits configured
- [ ] Backups enabled and tested
- [ ] Backup encryption enabled
- [ ] Token rotation schedule defined (90 days)
- [ ] Read-only tokens created for dashboards
- [ ] Write-only tokens created for data collectors
- [ ] Audit logging enabled
- [ ] Monitoring and alerting configured
- [ ] Incident response plan documented

### Production Operations

- [ ] Regular token rotation (90 days)
- [ ] Backup validation (monthly)
- [ ] Disaster recovery test (quarterly)
- [ ] Access review (quarterly)
- [ ] Security patch updates (monthly)
- [ ] Vulnerability scanning
- [ ] Penetration testing (annually)

### Compliance (if applicable)

- [ ] 21 CFR Part 11 validation (pharma)
- [ ] ISO 9001 documentation (quality)
- [ ] IEC 62443 assessment (industrial)
- [ ] GDPR data mapping (EU)
- [ ] Audit logs retention policy
- [ ] Data retention compliance

## 🔗 References

- [InfluxDB Security Best Practices](https://docs.influxdata.com/influxdb/v2/security/)
- [Kubernetes Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [OWASP Kubernetes Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Kubernetes_Security_Cheat_Sheet.html)
- [IEC 62443 Industrial Security](https://www.isa.org/standards-and-publications/isa-standards/isa-iec-62443-series-of-standards)
- [21 CFR Part 11 Compliance](https://www.fda.gov/regulatory-information/search-fda-guidance-documents/part-11-electronic-records-electronic-signatures-scope-and-application)

---

**Fireball Industries** - *"Security is not optional in 2026"*

**Made with 🔥 by Patrick Ryan**

*"If your admin password is 'password', we can't be friends."*
