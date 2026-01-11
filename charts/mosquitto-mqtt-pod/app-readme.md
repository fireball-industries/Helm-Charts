# Mosquitto MQTT Broker - Industrial IoT Messaging

**Production-ready Eclipse Mosquitto MQTT Broker for Kubernetes/K3s with Prometheus monitoring and industrial IoT optimization.**

Because your factory floor deserves better than a sketchy WiFi network.

---

## 🦟 What is Eclipse Mosquitto?

**Eclipse Mosquitto** is an open-source MQTT broker (message queue telemetry transport) that provides lightweight publish/subscribe messaging:

- **MQTT 3.1.1 & 5.0** - Industry-standard IoT messaging protocol
- **WebSockets** - MQTT over WebSockets for web browsers and SPAs
- **TLS/SSL** - Encrypted connections with client certificate support
- **Authentication & ACLs** - Password authentication and topic-based access control
- **Bridges** - Connect to cloud brokers (AWS IoT, Azure IoT Hub, Google Cloud IoT)
- **Persistence** - Store messages and sessions to disk
- **High Performance** - Handle thousands of concurrent clients with minimal resources

**Perfect for:** IoT sensor networks, SCADA/HMI communication, Sparkplug B deployments, edge data collection, cloud integration.

---

## 📊 Resource Presets

Choose a preset that matches your deployment scale:

| Preset | CPU | RAM | Storage | Max Connections | Use Case |
|--------|-----|-----|---------|----------------|----------|
| **edge-broker** | 500m / 1 | 512 MiB / 1 GiB | 5 GiB | 100 | Edge sites, small IoT |
| **standard-broker** | 1 / 2 | 1 GiB / 2 GiB | 20 GiB | 1,000 | Factory MQTT broker |
| **enterprise-broker** | 2 / 4 | 4 GiB / 8 GiB | 100 GiB | 10,000 | Central MQTT hub |
| **ha-cluster** | 2 / 4 per replica | 4 GiB / 8 GiB | 100 GiB (shared) | 10,000 | Mission-critical HA |

**Recommendation:**
- Start with **standard-broker** for most factory deployments
- Use **edge-broker** for resource-constrained edge sites
- Upgrade to **enterprise-broker** for centralized data collection
- Choose **ha-cluster** for zero-downtime operations

---

## 🚀 Quick Start

### Minimal Deployment
Deploy Mosquitto with default settings (no authentication, plain MQTT):

```bash
helm upgrade --install mosquitto fireball-industries/mosquitto-mqtt-pod \
  --namespace iot \
  --create-namespace \
  --set resourcePreset=standard-broker
```

**Access the broker:**
```bash
# Port-forward MQTT port
kubectl port-forward -n iot svc/mosquitto-mqtt 1883:1883

# Test connection with mosquitto_pub
mosquitto_pub -h localhost -p 1883 -t test/topic -m "Hello MQTT!"

# Subscribe to topics
mosquitto_sub -h localhost -p 1883 -t '#' -v
```

---

### Production Deployment with Security
Deploy with authentication, TLS, and persistence:

```bash
helm upgrade --install mosquitto fireball-industries/mosquitto-mqtt-pod \
  --namespace iot \
  --create-namespace \
  --set resourcePreset=standard-broker \
  --set mqtt.authentication.enabled=true \
  --set mqtt.authentication.allowAnonymous=false \
  --set mqtt.tls.enabled=true \
  --set mqtt.persistence.enabled=true \
  --set monitoring.enabled=true
```

---

## 🔌 MQTT Protocol Support

### Plain MQTT (Port 1883)
Standard unencrypted MQTT over TCP:

**Configuration:**
- **Port:** 1883 (IANA standard)
- **Protocol:** MQTT 3.1.1, MQTT 5.0
- **Use case:** Internal cluster communication, development

**Connection string:** `mqtt://mosquitto.iot.svc.cluster.local:1883`

---

### MQTT over TLS (MQTTS, Port 8883)
Encrypted MQTT with TLS/SSL:

**Configuration:**
- **Port:** 8883 (IANA standard for MQTTS)
- **TLS Versions:** TLS 1.2, TLS 1.3
- **Certificates:** Auto-generated self-signed or custom CA
- **Mutual TLS:** Optional client certificate verification

**Connection string:** `mqtts://mosquitto.iot.svc.cluster.local:8883`

**Use case:** Production deployments, cloud integration, IoT devices over public networks

---

### MQTT over WebSockets (Port 9001)
MQTT for web browsers and JavaScript clients:

**Configuration:**
- **Port:** 9001 (WebSocket)
- **Protocol:** MQTT 3.1.1/5.0 over WebSocket
- **TLS:** Optional (configure via ingress)
- **Use case:** Web dashboards, browser-based HMI

**Connection (JavaScript):**
```javascript
const client = mqtt.connect('ws://mosquitto.iot.svc.cluster.local:9001');
```

**Ingress support:**
Enable ingress to expose WebSocket endpoint externally with TLS termination.

---

## 🔒 Security & Authentication

### Password Authentication
Require username/password for all MQTT connections:

**Enable authentication:**
```yaml
mqtt:
  authentication:
    enabled: true
    allowAnonymous: false
    passwordFile:
      enabled: true
      users:
        - username: admin
          password: changeme
        - username: sensor01
          password: secret123
```

**Add users dynamically:**
Use PowerShell management script:
```powershell
.\scripts\manage-mosquitto.ps1 -Action add-user -Username factory-gateway -Password newsecret
```

**Password hashing:**
Passwords are automatically hashed using Mosquitto's password utility before storage.

---

### Access Control Lists (ACL)
Restrict which topics users can read/write:

**Example ACL configuration:**
```conf
# Admin has full access
user admin
topic readwrite #

# Sensors can only publish to sensors/ topics
user sensor01
topic write sensors/#

# Dashboards can only subscribe
user dashboard
topic read factory/#
```

**Pattern-based ACLs:**
```conf
# Users can only access their own namespace
pattern readwrite %u/#
```

**Pre-configured ACL templates:**
- **acl-factory.conf** - Factory floor with zones (production, quality, maintenance)
- **acl-sparkplug.conf** - Sparkplug B namespace restrictions

---

### TLS/SSL Encryption
Encrypt MQTT connections with TLS:

**Auto-generated certificates (testing):**
```yaml
mqtt:
  tls:
    enabled: true
    autoGenerate: true
```

**Custom certificates (production):**
```yaml
mqtt:
  tls:
    enabled: true
    autoGenerate: false
    existingSecret: "mosquitto-tls-cert"
```

**Mutual TLS (client certificates):**
```yaml
mqtt:
  tls:
    enabled: true
    requireCertificate: true
```

**Benefits:**
- Encrypted data in transit
- Client authentication via certificates
- Compliance with security standards

---

## ⚡ Sparkplug B Support

### What is Sparkplug B?
Industry-standard MQTT specification for industrial IoT:

- **Namespace:** `spBv1.0/<group_id>/<message_type>/<edge_node_id>[/<device_id>]`
- **Message types:** NBIRTH, NDEATH, DBIRTH, DDEATH, NDATA, DDATA, NCMD, DCMD
- **Auto-discovery:** Edge nodes announce themselves and devices
- **State awareness:** Track connection status and data freshness

**Use cases:**
- Ignition Edge + Central SCADA
- Factory floor sensor networks
- Remote site monitoring
- IIoT data collection

---

### Enable Sparkplug B
Pre-configure topics and ACLs for Sparkplug:

```yaml
mqtt:
  sparkplug:
    enabled: true
    namespace: "spBv1.0"
    aclEnabled: true
    groupIds:
      - "Factory"
      - "Warehouse"
```

**Topic structure:**
```
spBv1.0/Factory/NBIRTH/Edge-Gateway-01
spBv1.0/Factory/DDATA/Edge-Gateway-01/Sensor-Temperature-01
spBv1.0/Warehouse/NDATA/Edge-Gateway-02
```

**ACL permissions (auto-configured):**
- Edge nodes: Publish to `spBv1.0/<group_id>/+/<edge_node_id>/#`
- Central SCADA: Subscribe to `spBv1.0/#`
- Applications: Subscribe to specific groups

See [SPARKPLUG.md](SPARKPLUG.md) in chart for detailed configuration.

---

## 🌉 Cloud Bridges

### What are MQTT Bridges?
Forward messages between Mosquitto and cloud MQTT brokers:

**Supported cloud platforms:**
- AWS IoT Core
- Azure IoT Hub
- Google Cloud IoT Core
- IBM Watson IoT
- Any MQTT broker (HiveMQ, EMQX, VerneMQ)

**Use cases:**
- Send factory data to cloud analytics
- Receive commands from cloud applications
- Multi-site data aggregation
- Hybrid cloud/on-premises architectures

---

### Bridge Configuration Examples

#### AWS IoT Core
```yaml
mqtt:
  bridge:
    enabled: true
    connections:
      - name: aws-iot
        address: a1b2c3d4e5f6g7.iot.us-east-1.amazonaws.com:8883
        topics:
          - pattern: "factory/# out 1"
          - pattern: "commands/# in 1"
        tls: true
        clientId: factory-edge-01
        username: ""  # Use certificates for AWS IoT
        password: ""
```

---

#### Azure IoT Hub
```yaml
mqtt:
  bridge:
    enabled: true
    connections:
      - name: azure-iot
        address: my-iot-hub.azure-devices.net:8883
        topics:
          - pattern: "factory/# out 1 devices/factory-edge-01/messages/events/"
        tls: true
        clientId: factory-edge-01
        username: "my-iot-hub.azure-devices.net/factory-edge-01/?api-version=2021-04-12"
        password: "SharedAccessSignature sr=..."
```

---

### Bridge Patterns
**Outbound (out):** Send local topics to cloud
```yaml
topics:
  - pattern: "sensors/# out 1"  # Local sensors/* → Cloud sensors/*
```

**Inbound (in):** Receive cloud topics locally
```yaml
topics:
  - pattern: "commands/# in 1"  # Cloud commands/* → Local commands/*
```

**Bidirectional (both):** Two-way sync
```yaml
topics:
  - pattern: "data/# both 1"
```

**Topic remapping:**
```yaml
topics:
  - pattern: "local/sensors/# out 1 cloud/factory-01/sensors/"
```

---

## 💾 Message Persistence

### Why Persistence Matters
Without persistence, Mosquitto loses all messages and subscriptions on restart. **Critical for:**
- QoS 1/2 message delivery guarantees
- Retained messages
- Session state for clients
- Offline message buffering

---

### Persistence Configuration

**Enable persistence:**
```yaml
mqtt:
  persistence:
    enabled: true
    autosaveInterval: 60  # Save to disk every 60 seconds
    retainedMessages: true
    size: 20Gi
```

**Autosave strategies:**
- **60 seconds (default):** Good balance of performance and safety
- **0 (on exit only):** Best performance, risk data loss on crash
- **10 seconds:** Maximum safety, higher I/O overhead

**What's persisted:**
- QoS 1/2 messages awaiting delivery
- Retained messages (last value cache)
- Subscriptions for persistent sessions
- Client session state

---

### Storage Recommendations

**Edge broker (5 GiB):**
- Short-term buffering (hours)
- Retained messages only
- Minimal offline clients

**Standard broker (20 GiB):**
- Medium-term buffering (days)
- Hundreds of retained messages
- Dozens of offline clients

**Enterprise broker (100 GiB):**
- Long-term buffering (weeks)
- Thousands of retained messages
- Hundreds of offline clients

---

## 📈 Monitoring & Metrics

### Prometheus Exporter
mosquitto-exporter sidecar provides comprehensive metrics:

**Broker Metrics:**
- Total messages published/received
- Messages per second (publish rate)
- Connected clients count
- Subscriptions count
- Retained messages count
- Bytes sent/received

**System Metrics:**
- Uptime
- Memory usage
- Heap allocation
- Load average (1/5/15 minutes)

**Client Metrics:**
- Active connections
- Connected/disconnected events
- Maximum concurrent clients

**Message Metrics (per topic):**
- Publish count
- Bytes published
- Message drops

---

### Prometheus Queries

**Message publish rate:**
```promql
rate(mosquitto_messages_publish_total[5m])
```

**Active client connections:**
```promql
mosquitto_connected_clients
```

**Memory usage:**
```promql
mosquitto_heap_current_bytes / mosquitto_heap_max_bytes * 100
```

**Alert on connection limit:**
```promql
mosquitto_connected_clients / 1000 > 0.9  # 90% of 1000 limit
```

---

### Grafana Dashboards
Import pre-built dashboard for visualization:

**Dashboard ID:** 11542 (Mosquitto Exporter)

**Panels:**
- Client connections over time
- Message publish/receive rates
- Topic-level message breakdown
- Retained message count
- Bytes sent/received
- Uptime and availability

---

## 🏗️ High Availability

### HA Architecture
Zero-downtime MQTT broker with shared storage:

**Configuration:**
- **3 replicas** (minimum recommended)
- **Shared storage** (NFS, EFS, Azure Files - ReadWriteMany)
- **Session affinity** (ClientIP routing)
- **Persistence** enabled for session state

**How it works:**
1. All replicas share the same persistence storage
2. Clients connect to service with session affinity
3. If a replica crashes, Kubernetes reschedules it
4. Client reconnects and resumes session from shared storage

---

### Enable HA Cluster

```yaml
highAvailability:
  enabled: true
  replicas: 3
  sharedStorage:
    enabled: true
    storageClass: "nfs-client"
    size: 100Gi
```

**Requirements:**
- Storage class supporting **ReadWriteMany** access mode
- NFS, EFS, Azure Files, Google Cloud Filestore, or similar
- Session affinity enabled (default)

---

### HA Considerations

**Pros:**
- Zero-downtime deployments
- Automatic failover on pod crashes
- Load distribution across replicas

**Cons:**
- Shared storage can be a single point of failure (use redundant NFS)
- Slightly higher latency for persistence writes
- Session affinity prevents true load balancing

**Best for:**
- Mission-critical SCADA systems
- 24/7 factory operations
- Cloud-hosted deployments with managed storage

---

## 🛠️ PowerShell Management Scripts

Included scripts for Windows environments:

### 1. `manage-mosquitto.ps1`
Complete lifecycle management:

```powershell
# Deploy broker
.\scripts\manage-mosquitto.ps1 -Action deploy -Namespace iot

# Health check
.\scripts\manage-mosquitto.ps1 -Action health-check

# View logs
.\scripts\manage-mosquitto.ps1 -Action logs

# Add user
.\scripts\manage-mosquitto.ps1 -Action add-user -Username sensor02 -Password secret

# Remove user
.\scripts\manage-mosquitto.ps1 -Action remove-user -Username sensor02

# Reload configuration
.\scripts\manage-mosquitto.ps1 -Action reload-config
```

---

### 2. `test-mosquitto.ps1`
Comprehensive connectivity testing:

```powershell
.\scripts\test-mosquitto.ps1 -Namespace iot -TestType all
```

**Tests performed:**
- ✅ MQTT port connectivity (1883)
- ✅ MQTTS port connectivity (8883, if enabled)
- ✅ WebSocket connectivity (9001, if enabled)
- ✅ Publish/Subscribe message flow
- ✅ Authentication (if enabled)
- ✅ TLS handshake (if enabled)
- ✅ Prometheus metrics endpoint
- ✅ Persistence file integrity

---

## 📚 Example Configurations

Pre-built configurations in the `examples/` directory:

### 1. **demo-mosquitto.yaml**
Quick demo with minimal resources:
- No authentication (allow anonymous)
- No TLS
- No persistence
- 100 max connections

---

### 2. **factory-mqtt.yaml**
Standard factory MQTT broker:
- Password authentication
- TLS encryption
- Message persistence
- 1,000 max connections
- Prometheus monitoring
- ACL for zones (production, quality, maintenance)

---

### 3. **sparkplug-hub.yaml**
Sparkplug B central hub:
- Sparkplug B pre-configured
- Multiple group IDs (Factory, Warehouse, Remote)
- ACL for edge nodes and SCADA
- TLS with client certificates
- Bridge to AWS IoT Core
- High availability (3 replicas)

---

## 🆘 Troubleshooting

### Clients Can't Connect
```bash
# Check if broker is running
kubectl get pods -n iot

# Check service endpoint
kubectl get svc mosquitto-mqtt -n iot

# Test connection from within cluster
kubectl run -it --rm mqtt-test --image=eclipse-mosquitto:2.0 --restart=Never -- \
  mosquitto_pub -h mosquitto-mqtt.iot.svc.cluster.local -p 1883 -t test -m "test"

# Common issues:
# - Service not exposed (check service type)
# - Authentication enabled but no credentials provided
# - Network policy blocking traffic
# - TLS certificate mismatch
```

---

### Authentication Failures
```bash
# Check if password file is loaded
kubectl logs -n iot mosquitto-mqtt-0 | grep password

# Verify user exists in password file
kubectl exec -it mosquitto-mqtt-0 -n iot -- cat /mosquitto/config/password.txt

# Test with credentials
mosquitto_pub -h mosquitto -p 1883 -u admin -P changeme -t test -m "test"

# Common issues:
# - Password file not created (enable passwordFile.enabled)
# - Incorrect username/password
# - allowAnonymous=true overriding password requirement
```

---

### TLS Connection Issues
```bash
# Test TLS handshake
openssl s_client -connect mosquitto:8883 -servername mosquitto

# Check certificate validity
kubectl get secret mosquitto-tls-cert -n iot -o yaml

# Common issues:
# - Self-signed certificate not trusted by client
# - Certificate CN/SAN doesn't match hostname
# - TLS version mismatch (client using TLS 1.0, server requires 1.2+)
```

---

### High Memory Usage
```bash
# Check memory metrics
kubectl exec -it mosquitto-mqtt-0 -n iot -- \
  wget -qO- localhost:9234/metrics | grep mosquitto_heap

# Review retained message count
mosquitto_sub -h mosquitto -p 1883 -t '$SYS/broker/retained messages/count' -C 1

# Solutions:
# - Reduce autosave interval (less in-memory buffering)
# - Increase memory limits
# - Clean up old retained messages
# - Reduce QoS 1/2 message queue size
```

---

### Persistence Not Working
```bash
# Check if persistence is enabled
kubectl exec -it mosquitto-mqtt-0 -n iot -- cat /mosquitto/config/mosquitto.conf | grep persistence

# Verify PVC is mounted
kubectl describe pod mosquitto-mqtt-0 -n iot | grep -A 5 Volumes

# Check disk space
kubectl exec -it mosquitto-mqtt-0 -n iot -- df -h /mosquitto/data

# Common issues:
# - Persistence disabled in values.yaml
# - PVC not created or not bound
# - Disk full (increase PVC size)
# - Read-only filesystem (check PVC access mode)
```

---

## 🔗 Use Case Examples

### 1. Factory Floor Sensor Network
**Scenario:** 200 temperature/pressure sensors publishing every 5 seconds

**Configuration:**
- Preset: standard-broker (1,000 connections)
- Authentication: disabled (internal network)
- TLS: disabled (internal network)
- Persistence: enabled (sensor data buffering)
- Topics: `factory/zone-{1-5}/sensor-{001-200}/temperature`

---

### 2. Ignition Edge + Central SCADA
**Scenario:** 10 edge gateways with Ignition, central Ignition gateway

**Configuration:**
- Preset: enterprise-broker (10,000 connections)
- Sparkplug B: enabled
- Authentication: enabled (edge node credentials)
- TLS: enabled (edge nodes over public internet)
- Bridge: to cloud for backup/analytics

**Topic structure:**
```
spBv1.0/Factory/NBIRTH/Edge-01
spBv1.0/Factory/DDATA/Edge-01/Device-PLC-01
spBv1.0/Warehouse/NDATA/Edge-02
```

---

### 3. Cloud Data Upload
**Scenario:** Factory MQTT broker forwarding to AWS IoT

**Configuration:**
- Preset: standard-broker
- Bridge: AWS IoT Core
- Authentication: client certificates
- TLS: required
- Topics: `factory/# → cloud/factory-01/#`

**Data flow:**
```
[Factory Sensors] → [Mosquitto] → [Bridge] → [AWS IoT Core] → [S3/Analytics]
```

---

### 4. Web Dashboard (MQTT over WebSockets)
**Scenario:** Browser-based production dashboard

**Configuration:**
- WebSockets: enabled on port 9001
- Ingress: enabled with TLS termination
- Authentication: enabled (dashboard credentials)
- Topics: `dashboard/#` (read-only ACL)

**Client code (JavaScript):**
```javascript
const client = mqtt.connect('wss://mqtt.factory.com');
client.subscribe('factory/production/#');
client.on('message', (topic, message) => {
  updateDashboard(topic, message.toString());
});
```

---

## 📖 Additional Resources

- **Eclipse Mosquitto Documentation:** https://mosquitto.org/documentation/
- **MQTT Protocol Specification:** https://mqtt.org/
- **Sparkplug B Specification:** https://sparkplug.eclipse.org/
- **mosquitto-exporter:** https://github.com/sapcc/mosquitto-exporter
- **Chart Source:** https://github.com/fireball-industries/mosquitto-mqtt-helm

---

## 📝 License

Chart: MIT License - See LICENSE file for details.

**Eclipse Mosquitto:** EPL-2.0 and EDL-1.0

---

## 🎓 Getting Started Checklist

**Before deployment:**
- [ ] Choose resource preset (edge/standard/enterprise/ha-cluster)
- [ ] Decide authentication strategy (anonymous/password/certificates)
- [ ] Plan TLS deployment (self-signed for testing, custom certs for production)
- [ ] Identify topic structure (factory zones, sensor types, Sparkplug namespace)
- [ ] Configure ACLs (if multi-tenant or security-sensitive)
- [ ] Plan persistence storage size (based on message volume and retention)

**After deployment:**
- [ ] Test MQTT connectivity (mosquitto_pub/sub)
- [ ] Configure user accounts (if authentication enabled)
- [ ] Upload TLS certificates (if using custom certs)
- [ ] Test TLS connections (if enabled)
- [ ] Configure bridges (if cloud integration needed)
- [ ] Enable monitoring (Prometheus ServiceMonitor)
- [ ] Import Grafana dashboard (ID 11542)
- [ ] Load test with expected message volume
- [ ] Configure backup strategy

---

**Remember:** MQTT is stateful. Enable persistence to avoid losing messages and subscriptions on pod restarts. Your IoT sensors will thank you. 🦟

*Pro tip:* Start with `standard-broker` preset and authentication disabled for initial testing. Once you've verified connectivity and message flow, enable authentication and TLS before going to production. Security is easier to add than to retrofit. 🔒

**Happy messaging!** 📡

---

*Created by Patrick Ryan - Fireball Industries*

*"At least it's more reliable than Modbus over WiFi"*
