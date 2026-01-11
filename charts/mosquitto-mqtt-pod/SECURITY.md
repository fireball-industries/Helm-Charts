# 🔒 Mosquitto MQTT Security Guide

Comprehensive security configuration for Eclipse Mosquitto MQTT broker.

---

## 🔐 Authentication

### Password File Authentication

#### Basic Setup

```yaml
mqtt:
  authentication:
    enabled: true
    allowAnonymous: false
    passwordFile:
      enabled: true
      users:
        - username: admin
          password: your-secure-password
        - username: sensor01
          password: sensor-password
```

#### Add Users via CLI

```bash
# Get pod name
POD=$(kubectl get pods -n iot -l app.kubernetes.io/name=mosquitto-mqtt -o jsonpath='{.items[0].metadata.name}')

# Add user with bcrypt hashing
kubectl exec -n iot $POD -c mosquitto -- \
  mosquitto_passwd -b /mosquitto/config/passwd newuser newpassword

# Delete user
kubectl exec -n iot $POD -c mosquitto -- \
  mosquitto_passwd -D /mosquitto/config/passwd olduser

# Restart broker to apply changes
kubectl rollout restart statefulset/mosquitto -n iot
```

#### Using PowerShell Scripts

```powershell
# Add user
.\scripts\manage-mosquitto.ps1 -Action add-user -Username sensor02 -Password secret123

# Remove user
.\scripts\manage-mosquitto.ps1 -Action remove-user -Username sensor02
```

---

## 🛡️ Access Control Lists (ACL)

### ACL Syntax

```
# Format:
# user <username>
# topic [read|write|readwrite|deny] <topic>

# Pattern matching:
# %u = username
# %c = client ID
# + = single level wildcard
# # = multi-level wildcard
```

### Example ACL Configuration

```yaml
mqtt:
  acl:
    enabled: true
    content: |
      # =============================================================
      # Admin User - Full Access
      # =============================================================
      user admin
      topic readwrite #
      
      # =============================================================
      # SCADA System - Read All Sensors, Write Commands
      # =============================================================
      user scada
      topic read sensors/#
      topic read factory/#
      topic write commands/#
      
      # =============================================================
      # Sensors - Publish to Own Topics Only
      # =============================================================
      user sensor01
      topic write sensors/sensor01/#
      topic read commands/sensor01/#
      
      user sensor02
      topic write sensors/sensor02/#
      topic read commands/sensor02/#
      
      # =============================================================
      # Pattern-Based Access (username in topic path)
      # =============================================================
      pattern write sensors/%u/#
      pattern read commands/%u/#
      
      # =============================================================
      # Sparkplug B ACL
      # =============================================================
      # Edge nodes can publish birth/death/data
      user edge_node_01
      topic write spBv1.0/Factory/NBIRTH/edge_node_01
      topic write spBv1.0/Factory/NDEATH/edge_node_01
      topic write spBv1.0/Factory/NDATA/edge_node_01
      topic write spBv1.0/Factory/DBIRTH/edge_node_01/#
      topic write spBv1.0/Factory/DDEATH/edge_node_01/#
      topic write spBv1.0/Factory/DDATA/edge_node_01/#
      topic read spBv1.0/Factory/NCMD/edge_node_01
      topic read spBv1.0/Factory/DCMD/edge_node_01/#
      
      # Primary application can read all, write commands
      user primary_app
      topic read spBv1.0/#
      topic write spBv1.0/+/NCMD/#
      topic write spBv1.0/+/DCMD/#
```

### Pre-Built ACL Templates

See `acl-templates/` directory:
- `acl-sparkplug.conf` - Sparkplug B permissions
- `acl-factory.conf` - Factory floor permissions
- `acl-edge-nodes.conf` - Edge node permissions
- `acl-scada.conf` - SCADA system permissions

---

## 🔐 TLS/SSL Configuration

### Development: Auto-Generated Self-Signed Certificates

```yaml
mqtt:
  tls:
    enabled: true
    autoGenerate: true
    version: tlsv1.3
  ports:
    mqtts:
      enabled: true
      port: 8883
```

**⚠️ WARNING**: Auto-generated certificates are for development only!

### Production: Bring Your Own Certificates

#### 1. Create TLS Secret

```bash
kubectl create secret tls mosquitto-tls \
  --cert=path/to/server.crt \
  --key=path/to/server.key \
  --namespace=iot

# If you have a CA certificate
kubectl create secret generic mosquitto-ca \
  --from-file=ca.crt=path/to/ca.crt \
  --namespace=iot
```

#### 2. Configure Helm Values

```yaml
mqtt:
  tls:
    enabled: true
    existingSecret: mosquitto-tls
    version: tlsv1.3
    requireCertificate: false
    ciphers: "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384"
  ports:
    mqtts:
      enabled: true
      port: 8883
```

### Using cert-manager (Recommended)

#### 1. Install cert-manager

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

#### 2. Create ClusterIssuer

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            class: nginx
```

#### 3. Configure Mosquitto

```yaml
mqtt:
  tls:
    enabled: true
    annotations:
      cert-manager.io/cluster-issuer: "letsencrypt-prod"
ingress:
  enabled: true
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  tls:
    - secretName: mosquitto-tls
      hosts:
        - mqtt.example.com
```

### Client Certificate Authentication

```yaml
mqtt:
  tls:
    enabled: true
    requireCertificate: true
    existingSecret: mosquitto-tls
```

#### Generate Client Certificates

```bash
# Generate client private key
openssl genrsa -out client.key 2048

# Generate client certificate request
openssl req -new -key client.key -out client.csr \
  -subj "/CN=mqtt-client-01/O=Factory/C=US"

# Sign client certificate with CA
openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out client.crt -days 365

# Test connection
mosquitto_pub \
  --cafile ca.crt \
  --cert client.crt \
  --key client.key \
  -h mosquitto.example.com \
  -p 8883 \
  -t test/topic \
  -m "Hello Secure MQTT"
```

---

## 🌐 Network Security

### NetworkPolicy

```yaml
networkPolicy:
  enabled: true
  ingress:
    # Allow MQTT from IoT namespace
    - from:
        - namespaceSelector:
            matchLabels:
              name: iot
      ports:
        - protocol: TCP
          port: 1883
        - protocol: TCP
          port: 8883
    
    # Allow Prometheus scraping from monitoring namespace
    - from:
        - namespaceSelector:
            matchLabels:
              name: monitoring
      ports:
        - protocol: TCP
          port: 9234
  
  egress:
    # Allow DNS
    - to:
        - namespaceSelector: {}
      ports:
        - protocol: UDP
          port: 53
    
    # Allow bridge connections to external brokers
    - to:
        - namespaceSelector: {}
      ports:
        - protocol: TCP
          port: 8883
```

---

## ✅ Security Best Practices

### 1. Always Use Authentication in Production

```yaml
mqtt:
  authentication:
    enabled: true
    allowAnonymous: false
```

### 2. Use Strong Passwords

- Minimum 12 characters
- Mix of uppercase, lowercase, numbers, symbols
- Use password managers
- Rotate passwords regularly

### 3. Implement ACLs

- Principle of least privilege
- Sensors should only write to their own topics
- SCADA should have read-only access to data topics
- Commands should be restricted

### 4. Enable TLS for Production

```yaml
mqtt:
  tls:
    enabled: true
    version: tlsv1.3
  ports:
    mqtt:
      enabled: false  # Disable plain MQTT
    mqtts:
      enabled: true
```

### 5. Use Client Certificates for Critical Systems

```yaml
mqtt:
  tls:
    requireCertificate: true
```

### 6. Network Isolation

- Use NetworkPolicy to restrict access
- Separate namespaces for edge/cloud/SCADA
- Firewall rules for external access

### 7. Audit Logging

```yaml
mqtt:
  logging:
    level: information
    connectionLogs: true
```

### 8. Regular Updates

- Keep Mosquitto updated
- Monitor security advisories
- Test updates in staging first

---

## 🔍 Security Checklist

- [ ] Authentication enabled
- [ ] Anonymous access disabled
- [ ] Strong passwords configured
- [ ] ACL rules implemented
- [ ] TLS/SSL enabled for production
- [ ] Client certificates for critical systems
- [ ] NetworkPolicy configured
- [ ] Audit logging enabled
- [ ] Regular password rotation policy
- [ ] Monitoring and alerting configured
- [ ] Backup and disaster recovery plan
- [ ] Security testing performed

---

## 🚨 Security Incident Response

### Suspected Compromised Credentials

1. Immediately disable the user:
   ```bash
   kubectl exec mosquitto-0 -n iot -- \
     mosquitto_passwd -D /mosquitto/config/passwd compromised_user
   ```

2. Restart broker:
   ```bash
   kubectl rollout restart statefulset/mosquitto -n iot
   ```

3. Review logs for unauthorized access:
   ```bash
   kubectl logs mosquitto-0 -n iot -c mosquitto | grep compromised_user
   ```

4. Audit topic access in ACL logs

5. Generate new credentials for affected user

---

## 📚 Additional Resources

- [Mosquitto Security Documentation](https://mosquitto.org/documentation/authentication-methods/)
- [MQTT Security Fundamentals](https://mqtt.org/mqtt-security-fundamentals/)
- [OWASP IoT Security](https://owasp.org/www-project-internet-of-things/)

---

**Remember**: Security is not a one-time setup, it's an ongoing process!
