# SECURITY.md - TimescaleDB Helm Chart Security Guide

**Production-ready security configuration and compliance checklists.**

Because InfoSec will ask questions, and "it's probably fine" is not an acceptable answer.

---

## 🔒 Table of Contents

- [Authentication & Authorization](#authentication--authorization)
- [TLS/SSL Configuration](#tlsssl-configuration)
- [Network Security](#network-security)
- [RBAC Configuration](#rbac-configuration)
- [Compliance Checklists](#compliance-checklists)
- [Audit Logging](#audit-logging)
- [Security Hardening](#security-hardening)
- [Secret Management](#secret-management)
- [Vulnerability Management](#vulnerability-management)

---

## 🔐 Authentication & Authorization

### Password Management

**Default Behavior (Recommended):**
```yaml
postgresql:
  password: ""  # Auto-generates secure 32-character password
```

The chart automatically generates a random 32-character password stored in Kubernetes Secret.

**Retrieve password:**
```powershell
kubectl get secret timescaledb-secret -n databases -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
```

**Custom password (not recommended for production):**
```yaml
postgresql:
  password: "YourSecurePasswordHere"
```

### Authentication Methods

**SCRAM-SHA-256 (Default)**
```conf
# pg_hba.conf
host all all 0.0.0.0/0 scram-sha-256
```

Stronger than MD5, resistant to password capture attacks.

**Client certificate authentication:**
```yaml
tls:
  enabled: true
  mode: "verify-full"
```

```conf
# pg_hba.conf
hostssl all all 0.0.0.0/0 cert
```

### User Roles

**Pre-created roles:**
- `tsadmin`: Database superuser (created automatically)
- `readonly`: Read-only access to hypertables (created by init scripts)
- `replicator`: Replication user for HA mode

**Create application-specific user:**
```sql
CREATE ROLE app_user WITH LOGIN PASSWORD 'secure_password';
GRANT CONNECT ON DATABASE tsdb TO app_user;
GRANT USAGE ON SCHEMA scada_historian TO app_user;
GRANT SELECT, INSERT ON ALL TABLES IN SCHEMA scada_historian TO app_user;
```

**Row-Level Security (multi-tenant):**
```sql
ALTER TABLE scada_historian.sensor_data ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON scada_historian.sensor_data
  FOR ALL
  USING (tenant_id = current_setting('app.current_tenant')::TEXT);
```

---

## 🔐 TLS/SSL Configuration

### Enable TLS

```yaml
tls:
  enabled: true
  mode: "require"  # disable, allow, prefer, require, verify-ca, verify-full
  certificateSource: "secret"
  secretName: "timescaledb-tls"
```

**TLS Modes:**
- `disable`: No TLS (dev only)
- `allow`: TLS if client requests
- `prefer`: Try TLS, fall back to plaintext
- `require`: TLS required, no certificate verification
- `verify-ca`: TLS with CA verification
- `verify-full`: Full certificate verification (recommended)

### Create TLS Certificate

**Using cert-manager:**
```yaml
tls:
  enabled: true
  mode: "require"
  certificateSource: "cert-manager"
  certManager:
    issuer: "letsencrypt-prod"
    issuerKind: "ClusterIssuer"
```

**Manual certificate:**
```powershell
# Generate self-signed certificate (dev only)
openssl req -new -x509 -days 365 -nodes -text `
  -out server.crt `
  -keyout server.key `
  -subj "/CN=timescaledb.example.com"

# Create Kubernetes secret
kubectl create secret tls timescaledb-tls `
  --cert=server.crt `
  --key=server.key `
  -n databases
```

**Production certificate (Let's Encrypt):**
```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: timescaledb-tls
spec:
  secretName: timescaledb-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
    - timescaledb.example.com
```

### Client Connection with TLS

```powershell
psql "sslmode=require host=timescaledb.example.com port=5432 user=tsadmin dbname=tsdb"
```

---

## 🛡️ Network Security

### NetworkPolicy

```yaml
networkPolicy:
  enabled: true
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: applications
        - namespaceSelector:
            matchLabels:
              name: monitoring
```

**Default policy**: Deny all, allow specific namespaces.

**Allow specific pods:**
```yaml
networkPolicy:
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: my-app
```

**Allow external access (LoadBalancer/Ingress only):**
```yaml
service:
  type: LoadBalancer
  loadBalancerSourceRanges:
    - 10.0.0.0/8  # Internal network only
```

### Firewall Rules

**Allow PostgreSQL (5432):**
- From application pods/namespaces
- From monitoring namespace (Prometheus)
- From backup jobs

**Block everything else.**

---

## 🔑 RBAC Configuration

### ServiceAccount Permissions

```yaml
rbac:
  create: true
  rules:
    - apiGroups: [""]
      resources: ["configmaps", "secrets"]
      verbs: ["get", "list", "watch"]
```

**Minimum required permissions:**
- Read ConfigMaps (configuration)
- Read Secrets (passwords)
- Get/List/Patch Pods (HA leader election)
- Create Events (monitoring)

**Additional rules for custom automation:**
```yaml
rbac:
  rules:
    - apiGroups: ["batch"]
      resources: ["jobs"]
      verbs: ["create", "delete"]  # For backup automation
```

---

## ✅ Compliance Checklists

### FDA 21 CFR Part 11 Compliance

**Requirements:**
- [ ] Electronic signatures for critical operations
- [ ] Audit trail (immutable)
- [ ] User authentication and authorization
- [ ] Data integrity controls
- [ ] System validation documentation
- [ ] Change control procedures
- [ ] Backup and disaster recovery

**Configuration:**
```yaml
compliance:
  fda21CFRPart11:
    enabled: true
    auditLogging: true
    immutableAuditTables: true
    electronicSignatures: true

tls:
  enabled: true
  mode: "require"

backup:
  enabled: true
  retention: 365  # 1 year minimum

timescaledb:
  retention:
    rawData: "25 years"  # Long-term regulatory retention
```

**Validation Steps:**
1. Document system architecture
2. Perform installation qualification (IQ)
3. Perform operational qualification (OQ)
4. Perform performance qualification (PQ)
5. Create validation summary report
6. Obtain quality approval

**Audit Requirements:**
```sql
-- All data changes logged to audit_log.data_changes
-- Audit table is immutable (no updates/deletes)
-- Includes: timestamp, user, operation, old/new data, reason

SELECT * FROM audit_log.data_changes
WHERE changed_at > NOW() - INTERVAL '30 days'
ORDER BY changed_at DESC;
```

### ISO 9001 Compliance

**Requirements:**
- [ ] Quality data tracking (measurements, inspections)
- [ ] Traceability (lot tracking, genealogy)
- [ ] Audit logging
- [ ] Document control
- [ ] Nonconformance tracking

**Configuration:**
```yaml
compliance:
  iso9001:
    enabled: true
    auditLogging: true

timescaledb:
  hypertables:
    qualityMeasurements:
      enabled: true
      retention:
        dropAfter: "10 years"
```

**Quality Data Queries:**
```sql
-- SPC Control Chart
SELECT measurement_type, value, time,
       AVG(value) OVER (PARTITION BY measurement_type) AS mean,
       STDDEV(value) OVER (PARTITION BY measurement_type) AS stddev
FROM quality_data.quality_measurements
WHERE time > NOW() - INTERVAL '30 days';

-- Cpk Calculation
SELECT measurement_type,
       LEAST((MAX(usl) - AVG(value)) / (3 * STDDEV(value)),
             (AVG(value) - MAX(lsl)) / (3 * STDDEV(value))) AS cpk
FROM quality_data.quality_measurements
GROUP BY measurement_type;
```

### GDPR Compliance

**Requirements:**
- [ ] Right to be forgotten (data deletion)
- [ ] Data retention policies
- [ ] Consent management
- [ ] Data portability
- [ ] Privacy by design

**Configuration:**
```yaml
compliance:
  gdpr:
    enabled: true
    dataRetention: true
    rightToBeForgotten: true
```

**Right to be forgotten implementation:**
```sql
-- Delete user data (implement with caution)
DELETE FROM scada_historian.sensor_data
WHERE tags->>'user_id' = 'user-to-forget';

-- Or anonymize instead of delete
UPDATE scada_historian.sensor_data
SET tags = tags - 'user_id'
WHERE tags->>'user_id' = 'user-to-forget';
```

---

## 📝 Audit Logging

### Enable Comprehensive Logging

```yaml
postgresql:
  logging:
    logStatement: "all"  # none, ddl, mod, all
    logConnections: true
    logDisconnections: true
    logDuration: true
    logMinDurationStatement: "0ms"  # Log all queries
```

**⚠️ Warning**: `logStatement: "all"` generates large log volumes. Use for compliance only.

**Balanced logging (recommended for production):**
```yaml
postgresql:
  logging:
    logStatement: "ddl"  # Log schema changes only
    logMinDurationStatement: "1000ms"  # Log slow queries (>1s)
```

### Audit Table Structure

```sql
CREATE TABLE audit_log.data_changes (
  change_id BIGSERIAL PRIMARY KEY,
  changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  schema_name TEXT NOT NULL,
  table_name TEXT NOT NULL,
  operation TEXT NOT NULL,  -- INSERT, UPDATE, DELETE
  user_name TEXT NOT NULL,
  old_data JSONB,
  new_data JSONB,
  reason TEXT,
  electronic_signature TEXT
);
```

### Query Audit Logs

```sql
-- Recent changes
SELECT * FROM audit_log.data_changes
WHERE changed_at > NOW() - INTERVAL '24 hours'
ORDER BY changed_at DESC;

-- Changes by user
SELECT user_name, COUNT(*), MAX(changed_at)
FROM audit_log.data_changes
GROUP BY user_name
ORDER BY COUNT(*) DESC;

-- Suspicious activity (bulk deletes)
SELECT * FROM audit_log.data_changes
WHERE operation = 'DELETE'
  AND changed_at > NOW() - INTERVAL '1 hour'
  AND (old_data->>'count')::INT > 1000;
```

---

## 🔒 Security Hardening

### PostgreSQL Configuration

```yaml
postgresql:
  # Limit superuser connections
  maxConnections: 300
  
  # Enable SSL/TLS
  tls:
    enabled: true
    mode: "require"
  
  # Restrict pg_hba.conf
  # (default allows from all K8s pods with scram-sha-256)
  
  # Enable statement timeout (prevent long-running queries)
  performance:
    statementTimeout: "30min"
```

### Container Security

```yaml
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000

securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: false
  runAsNonRoot: true
  capabilities:
    drop:
      - ALL
```

### Resource Limits

```yaml
resources:
  limits:
    cpu: "8"
    memory: "16Gi"
  requests:
    cpu: "4"
    memory: "16Gi"
```

**Prevents:**
- Resource exhaustion attacks
- Noisy neighbor problems
- Cluster-wide outages

### PodDisruptionBudget

```yaml
podDisruptionBudget:
  enabled: true
  minAvailable: 1  # or 2 for HA
```

**Ensures:**
- Minimum availability during node maintenance
- Protection against accidental disruptions

---

## 🔐 Secret Management

### Kubernetes Secrets (Default)

```yaml
# Auto-generated password stored in secret
apiVersion: v1
kind: Secret
metadata:
  name: timescaledb-secret
type: Opaque
data:
  password: <base64-encoded>
```

**Pros:** Simple, built-in
**Cons:** Secrets are base64-encoded, not encrypted at rest (unless ETCD encryption enabled)

### External Secret Management

**HashiCorp Vault:**
```yaml
# Use External Secrets Operator
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: timescaledb-password
spec:
  secretStoreRef:
    name: vault-backend
  target:
    name: timescaledb-secret
  data:
    - secretKey: password
      remoteRef:
        key: secret/data/timescaledb
        property: password
```

**AWS Secrets Manager, Azure Key Vault, GCP Secret Manager:**
Similar integration via External Secrets Operator.

### Rotate Passwords

```powershell
# Generate new password
$newPassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})

# Update secret
kubectl create secret generic timescaledb-secret `
  --from-literal=password=$newPassword `
  --dry-run=client -o yaml | kubectl apply -f -

# Update database
kubectl exec -it timescaledb-0 -n databases -- psql -U postgres -c "ALTER USER tsadmin WITH PASSWORD '$newPassword';"

# Restart pods to pick up new secret
kubectl rollout restart statefulset/timescaledb -n databases
```

---

## 🛡️ Vulnerability Management

### Image Scanning

**Scan TimescaleDB image:**
```powershell
# Using Trivy
trivy image timescale/timescaledb-ha:pg15-latest

# Using Grype
grype timescale/timescaledb-ha:pg15-latest
```

**Use specific versions (not `latest`):**
```yaml
image:
  repository: timescale/timescaledb-ha
  tag: "pg15-2.14.2"  # Pin to specific version
```

### Keep Updated

**Subscribe to security announcements:**
- TimescaleDB Security Advisories
- PostgreSQL Security Page
- Kubernetes CVE Database

**Update regularly:**
```powershell
# Update Helm chart values with new image tag
helm upgrade timescaledb . --set image.tag=pg15-2.15.0
```

---

## 📋 Security Checklist

**Before Production Deployment:**
- [ ] Auto-generated passwords enabled
- [ ] TLS/SSL enabled and configured
- [ ] NetworkPolicy created and tested
- [ ] RBAC permissions reviewed and minimized
- [ ] Resource limits configured
- [ ] PodDisruptionBudget enabled
- [ ] Backup and restore tested
- [ ] Monitoring and alerting configured
- [ ] Audit logging enabled (if compliance required)
- [ ] Image vulnerabilities scanned
- [ ] Security review completed
- [ ] Incident response plan documented

**Ongoing Security:**
- [ ] Regular password rotation
- [ ] Image updates (monthly)
- [ ] Audit log reviews (weekly)
- [ ] Backup verification (weekly)
- [ ] Access control reviews (quarterly)
- [ ] Penetration testing (annually)

---

**Remember**: Security is not a one-time checklist. It's an ongoing process. Stay vigilant, keep updated, and don't trust Karen from accounting with the database password. 🔒
