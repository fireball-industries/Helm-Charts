# Fireball CODESYS TargetVisu - Industrial HMI/SCADA

**Production-ready CODESYS TargetVisu for Linux SL deployment on Kubernetes/K3s.**

Because staring at green text on black screens while your PLC crashes is a rite of passage. Now in containerized form with 100% more YAML. 🏭

---

## 🎯 What is CODESYS TargetVisu?

**CODESYS TargetVisu** is a professional HMI/SCADA visualization platform for industrial automation:

- **Web-Based HMI** - Access visualizations from any browser (desktop, tablet, mobile)
- **IEC 61131-3 Integration** - Native integration with CODESYS PLC runtime
- **Multi-Protocol Support** - OPC UA, Modbus TCP, EtherNet/IP, PROFINET, BACnet, CAN bus
- **Real-Time Visualization** - Live process data, trends, alarms, recipes
- **Industrial Grade** - Proven in manufacturing, building automation, energy management

**Perfect for:** Factory HMI panels, SCADA systems, building automation, process monitoring, remote control.

---

## 📦 What You Get

This Helm chart deploys a complete HMI/SCADA system:

✅ **CODESYS TargetVisu Runtime** - Web-based visualization engine  
✅ **Web Server** - HTTP/HTTPS with WebSocket for real-time updates  
✅ **Protocol Stack** - OPC UA, Modbus TCP, EtherNet/IP, and more  
✅ **Data Logging** - Process data recording and CSV export  
✅ **Alarm System** - Event management and history  
✅ **Recipe Management** - Production settings and batch control  
✅ **Trend Charts** - Real-time and historical data visualization  
✅ **User Management** - Role-based access control (admin, operator, readonly)  
✅ **CODESYS Gateway** - Online IDE connections for development  
✅ **Prometheus Metrics** - Monitoring and alerting integration  
✅ **Grafana Dashboards** - Pre-built visualization dashboards  

---

## 🚀 Resource Presets

Choose a preset based on your HMI complexity:

| Preset | CPU | RAM | Storage | Use Case |
|--------|-----|-----|---------|----------|
| **edge-minimal** | 500m / 1000m | 512Mi / 1Gi | 8Gi | Raspberry Pi 4, <10 screens, simple HMI |
| **edge-standard** | 1000m / 2000m | 1Gi / 2Gi | 17Gi | Industrial PC, 10-50 screens **(default)** |
| **industrial** | 2000m / 4000m | 2Gi / 4Gi | 35Gi | Large SCADA, >50 screens, high concurrency |

**Recommendation:**
- Use **edge-minimal** for simple HMI on constrained hardware (Raspberry Pi)
- Choose **edge-standard** for typical factory HMI panels (recommended)
- Select **industrial** for complex SCADA systems with many concurrent users

---

## 🏁 Quick Start

### Standard Factory HMI
Deploy with default settings (NodePort access, 10 concurrent clients):

```bash
helm upgrade --install factory-hmi fireball-industries/codesys-targetvisu-pod \
  --namespace hmi \
  --create-namespace \
  --set resourcePreset=edge-standard \
  --set targetvisu.license.type=file \
  --set targetvisu.license.licenseSecret=codesys-license
```

**Access HMI:**
```bash
# Get NodePort
kubectl get service -n hmi factory-hmi-codesys-targetvisu-pod

# Access at: http://<node-ip>:30080
```

---

### With Ingress (SSL Termination)
Deploy with domain name and HTTPS:

```bash
helm upgrade --install factory-hmi fireball-industries/codesys-targetvisu-pod \
  --namespace hmi \
  --create-namespace \
  --set resourcePreset=edge-standard \
  --set service.type=ClusterIP \
  --set ingress.enabled=true \
  --set ingress.host=hmi.factory.local \
  --set ingress.tls.enabled=true
```

**Access HMI:** https://hmi.factory.local

---

### Large SCADA System
High-performance deployment with OPC UA and Modbus:

```bash
helm upgrade --install scada fireball-industries/codesys-targetvisu-pod \
  --namespace hmi \
  --create-namespace \
  --set resourcePreset=industrial \
  --set targetvisu.web.maxClients=25 \
  --set protocols.opcua.enabled=true \
  --set protocols.modbusTcp.enabled=true \
  --set monitoring.serviceMonitor.enabled=true
```

---

## 📋 License Configuration

CODESYS TargetVisu requires a valid runtime license. Three options:

### 1. License File (Recommended for Edge)
Upload license file via Kubernetes Secret:

```bash
# Create license Secret
kubectl create secret generic codesys-license \
  --from-file=license.lic=/path/to/your/license.lic \
  -n hmi

# Deploy with file license
helm upgrade --install factory-hmi fireball-industries/codesys-targetvisu-pod \
  --set targetvisu.license.type=file \
  --set targetvisu.license.licenseSecret=codesys-license
```

**Best for:** Single deployments, offline environments, edge computing

---

### 2. License Server (Recommended for Fleet)
Connect to network CodeMeter license server:

```bash
helm upgrade --install factory-hmi fireball-industries/codesys-targetvisu-pod \
  --set targetvisu.license.type=server \
  --set targetvisu.license.licenseServer.host=license.factory.local \
  --set targetvisu.license.licenseServer.port=1947
```

**Best for:** Multiple deployments, centralized license management, license pooling

**Requires:** CodeMeter license server on network (port 1947)

---

### 3. Demo Mode (Testing Only)
Trial mode with limited features (30 days):

```bash
helm upgrade --install factory-hmi fireball-industries/codesys-targetvisu-pod \
  --set targetvisu.license.type=demo \
  --set targetvisu.license.demo.duration=30
```

**Limitations:**
- 30-day trial period
- Limited concurrent clients (typically 2-3)
- Some features disabled (depends on demo license)
- Not for production use

---

## 🌐 Network Access

### NodePort (Default - Best for Edge)
Direct access via node IP and port:

**Configuration:**
```yaml
service:
  type: NodePort
  http:
    nodePort: 30080  # HTTP
  https:
    nodePort: 30443  # HTTPS
```

**Access:**
- HTTP: `http://<node-ip>:30080`
- HTTPS: `https://<node-ip>:30443`

**Best for:**
- Edge deployments
- Industrial networks without Ingress controllers
- Direct panel access from factory floor

---

### Ingress (Recommended for Cloud/Data Center)
SSL termination with hostname routing:

**Configuration:**
```yaml
service:
  type: ClusterIP
ingress:
  enabled: true
  host: hmi.factory.local
  tls:
    enabled: true
    secretName: codesys-tls
```

**Access:** `https://hmi.factory.local`

**Best for:**
- Cloud deployments
- Multiple HMIs with DNS routing
- Centralized SSL certificate management

---

### LoadBalancer (Cloud Environments)
Automatic external IP assignment:

**Configuration:**
```yaml
service:
  type: LoadBalancer
```

**Best for:**
- Cloud providers (AWS, Azure, GCP)
- On-premise with MetalLB

---

## 🔌 Industrial Protocol Support

### OPC UA Server (Recommended)
Expose process variables via OPC UA:

**Configuration:**
```yaml
protocols:
  opcua:
    enabled: true
    port: 4840
    security:
      mode: SignAndEncrypt  # None, Sign, SignAndEncrypt
```

**Use cases:**
- SCADA data collection
- MES integration
- Historian connectivity
- Third-party HMI clients

**Security modes:**
- **None** - No encryption (testing only)
- **Sign** - Message signing (integrity)
- **SignAndEncrypt** - Signing + encryption (recommended)

---

### Modbus TCP
Industry-standard fieldbus protocol:

**Configuration:**
```yaml
protocols:
  modbusTcp:
    enabled: true
    port: 502
```

**Use cases:**
- PLC communication
- Field device monitoring
- Energy meters, temperature controllers
- RTU gateway integration

---

### EtherNet/IP
Allen-Bradley / Rockwell Automation protocol:

**Configuration:**
```yaml
protocols:
  ethernetIp:
    enabled: true
    port: 44818
```

**Use cases:**
- CompactLogix / ControlLogix PLCs
- PowerFlex drives
- Factory automation networks

---

### PROFINET
Siemens industrial Ethernet protocol:

**Configuration:**
```yaml
protocols:
  profinet:
    enabled: true
hostNetwork: true  # Required for PROFINET
```

**⚠️ Requires:** `hostNetwork: true` for real-time requirements

**Use cases:**
- Siemens S7 PLCs
- PROFINET I/O devices
- Process automation

---

### BACnet
Building automation protocol:

**Configuration:**
```yaml
protocols:
  bacnet:
    enabled: true
    port: 47808
```

**Use cases:**
- HVAC control
- Building management systems
- Energy monitoring

---

### CAN Bus
Controller Area Network (automotive, industrial):

**Configuration:**
```yaml
protocols:
  canbus:
    enabled: true
    interface: can0
    bitrate: 500000
```

**⚠️ Requires:** Host CAN interface (`can0`) and kernel modules

**Use cases:**
- Vehicle diagnostics
- Industrial machinery
- CANopen networks

---

## 🏭 PLC Integration

### Local PLC (Same Pod)
Combined HMI + PLC deployment:

**Configuration:**
```yaml
plc:
  enabled: true
  connection:
    type: local
    local:
      shmPath: /dev/shm/codesys
      shmSize: 64Mi
```

**Benefits:**
- Lowest latency (shared memory)
- No network overhead
- Single deployment unit

**Use cases:**
- All-in-one edge device (Raspberry Pi + HMI + PLC)
- Standalone machine control

---

### Remote PLC (Separate Pod/Device)
Connect to external CODESYS runtime:

**Configuration:**
```yaml
plc:
  enabled: true
  connection:
    type: remote
    remote:
      host: plc.factory.local
      port: 11740
      encryption: true
```

**Benefits:**
- Separate HMI and PLC scaling
- Redundant HMI instances
- PLC on dedicated hardware

**Use cases:**
- Central SCADA with multiple PLCs
- Redundant HMI for critical processes

---

### CODESYS Gateway
Enable IDE connections for development:

**Configuration:**
```yaml
gateway:
  enabled: true
  port: 11740
  allowRemote: true
  encryption: true
```

**Features:**
- Online debugging from CODESYS IDE
- Live variable monitoring
- Remote configuration
- Project upload/download

**⚠️ Security:** Restrict access in production (firewall rules, NetworkPolicy)

---

## 🔐 Security Features

### User Authentication
Role-based access control:

**Configuration:**
```yaml
security:
  authentication:
    enabled: true
    type: basic  # basic, ldap, active-directory
    users:
      - username: admin
        passwordSecret: codesys-admin-password
      - username: operator
        passwordSecret: codesys-operator-password
      - username: readonly
        passwordSecret: codesys-readonly-password
```

**Roles:**
- **admin** - Full access (view, edit, configure, manage users)
- **operator** - View + edit + acknowledge alarms
- **readonly** - View only (dashboards, trends)

---

### TLS/SSL Encryption
HTTPS with certificate:

**Configuration:**
```yaml
security:
  tls:
    enabled: true
    certSecret: codesys-tls-cert
    selfSigned: false  # Use real certificate in production
```

**Create certificate Secret:**
```bash
kubectl create secret tls codesys-tls-cert \
  --cert=/path/to/tls.crt \
  --key=/path/to/tls.key \
  -n hmi
```

---

### IP Whitelisting
Restrict access to specific networks:

**Configuration:**
```yaml
security:
  ipWhitelist:
    enabled: true
    allowedIPs:
      - "10.0.0.0/8"        # Private network
      - "192.168.0.0/16"    # Private network
      - "172.16.0.0/12"     # Private network
```

**Best for:** Production environments, defense-in-depth security

---

### LDAP / Active Directory
Enterprise authentication:

**Configuration:**
```yaml
security:
  authentication:
    type: ldap  # or active-directory
    ldap:
      enabled: true
      server: "ldap://ldap.factory.local:389"
      baseDN: "dc=factory,dc=local"
      userFilter: "(uid=%s)"
```

**Benefits:**
- Centralized user management
- Single sign-on (SSO)
- Group-based access control

---

## 📊 Features Explained

### Recipe Management
Store production settings and batch parameters:

**Configuration:**
```yaml
targetvisu:
  recipes:
    enabled: true
    maxRecipes: 100
```

**Use cases:**
- Product changeover (SKU recipes)
- Batch production settings
- Machine parameter sets
- Quality control formulas

**Features:**
- Import/export CSV
- Version control
- Operator selection from HMI
- Automatic loading on startup

---

### Data Logging
Record process variables to disk:

**Configuration:**
```yaml
targetvisu:
  dataLogging:
    enabled: true
    interval: 1000  # milliseconds
    bufferSize: 10000
```

**Formats:**
- CSV (Excel-compatible)
- Binary (high-speed recording)
- Ring buffer (continuous logging)

**Use cases:**
- Production reporting
- Quality traceability
- Compliance documentation
- Trend analysis

---

### Alarm System
Event management with history:

**Configuration:**
```yaml
targetvisu:
  alarms:
    enabled: true
    historySize: 1000
    acknowledgementRequired: true
```

**Features:**
- Real-time alarm display
- Alarm history with timestamps
- Acknowledgement tracking
- Priority levels (critical, high, medium, low)
- Email/SMS notifications (via integration)

---

### Trend Charts
Real-time data visualization:

**Configuration:**
```yaml
targetvisu:
  trends:
    enabled: true
    maxTrends: 50
    sampleRate: 1000  # milliseconds
    historyDuration: 86400  # 24 hours
```

**Features:**
- Multiple variables per chart
- Auto-scaling
- Zoom/pan controls
- Export to CSV
- Historical playback

---

## 📈 Monitoring & Observability

### Prometheus Metrics
Export runtime metrics:

**Configuration:**
```yaml
monitoring:
  prometheus:
    enabled: true
    port: 9100
    interval: 30s
  serviceMonitor:
    enabled: true  # Requires Prometheus Operator
```

**Metrics exposed:**
- `codesys_runtime_cycle_time_ms` - Task execution time
- `codesys_web_clients_active` - Concurrent HMI clients
- `codesys_web_requests_total` - HTTP request counter
- `codesys_alarms_active` - Active alarm count
- `codesys_protocol_connections` - Protocol client connections
- `codesys_memory_usage_bytes` - Runtime memory consumption
- `codesys_task_overruns_total` - Real-time task overruns

---

### Grafana Dashboards
Pre-built visualizations:

**4 Included Dashboards:**

1. **TargetVisu Overview** - Runtime health, clients, performance
2. **Web Performance** - Request rates, latency, session counts
3. **Protocol Stats** - OPC UA/Modbus connections, traffic, errors
4. **PLC Connection** - PLC link status, communication quality

**Import dashboards:**
```bash
kubectl apply -f dashboards/ -n hmi
```

---

### Health Checks
Kubernetes liveness/readiness probes:

**Configuration:**
```yaml
monitoring:
  healthcheck:
    enabled: true
    liveness:
      initialDelaySeconds: 60
      periodSeconds: 30
    readiness:
      initialDelaySeconds: 30
      periodSeconds: 10
```

**Checks:**
- Runtime process active
- Web server responding
- License valid
- PLC connection (if enabled)

---

## 📂 Storage Volumes

### Configuration Volume (5Gi)
Stores CODESYS configuration and license:

**Mountpoint:** `/var/opt/codesys`

**Contents:**
- `CODESYSControl.cfg` - Runtime configuration
- `license.lic` - License file
- `device.xml` - Device description
- User management database
- SSL certificates

**⚠️ Important:** Persistent storage required for license activation

---

### Projects Volume (10Gi)
Stores HMI projects and visualizations:

**Mountpoint:** `/projects`

**Contents:**
- `.project` files - HMI projects
- `.visu` files - Visualization screens
- Recipe files
- Alarm configurations
- Custom scripts

**💡 Tip:** Use version control (Git) for project files

---

### Logs Volume (2Gi)
Stores runtime logs and data:

**Mountpoint:** `/var/log/codesys`

**Contents:**
- `codesys.log` - Runtime events
- `web.log` - HTTP access log
- `data/` - Data logging files
- `alarms/` - Alarm history
- `diagnostics/` - Troubleshooting dumps

---

## 🔧 Advanced Configuration

### VNC Remote Access
Remote desktop for troubleshooting:

**Configuration:**
```yaml
vnc:
  enabled: true
  port: 5900
  resolution: "1920x1080"
  passwordSecret: vnc-password
```

**Connect:**
```bash
# Port-forward VNC
kubectl port-forward -n hmi pod/<pod-name> 5900:5900

# Use VNC client: localhost:5900
```

**Use cases:**
- Remote HMI troubleshooting
- Configuration without physical access
- Screen recording for documentation

---

### Custom Resource Limits
Fine-tune resource allocation:

**Configuration:**
```yaml
resourcePreset: custom
resources:
  requests:
    cpu: 1500m
    memory: 1.5Gi
  limits:
    cpu: 3000m
    memory: 3Gi
```

**Guidelines:**
- **CPU**: 1 core minimum, add 500m per 10 concurrent clients
- **Memory**: 1Gi minimum, add 200Mi per 10 complex screens

---

### Network Policy
Restrict pod network access:

**Configuration:**
```yaml
networkPolicy:
  enabled: true
  ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            name: monitoring
      ports:
      - protocol: TCP
        port: 9100  # Prometheus only
```

**Benefits:**
- Defense-in-depth security
- Limit blast radius of compromises
- Compliance requirements (IEC 62443)

---

## 🆘 Troubleshooting

### Pod Not Starting
```bash
# Check pod status
kubectl get pods -n hmi
kubectl describe pod -n hmi <pod-name>

# Common issues:
# 1. PVC not binding - check storage class availability
# 2. Image pull failed - verify image repository and credentials
# 3. License invalid - check license Secret and expiry
```

---

### Cannot Access Web Interface
```bash
# Verify service
kubectl get service -n hmi

# Check NodePort/LoadBalancer IP
kubectl get service -n hmi -o wide

# Test from inside cluster
kubectl run -it --rm debug --image=busybox --restart=Never -n hmi
wget -O- http://factory-hmi:8080

# Common issues:
# 1. NodePort not accessible - check firewall rules
# 2. Ingress not working - verify Ingress controller installed
# 3. Wrong service type - check service.type setting
```

---

### License Errors
```bash
# Check license Secret exists
kubectl get secret -n hmi codesys-license

# View license content
kubectl get secret -n hmi codesys-license -o jsonpath='{.data.license\.lic}' | base64 -d

# Check license server connectivity (if using server mode)
kubectl exec -it -n hmi <pod-name> -- ping license.factory.local
kubectl exec -it -n hmi <pod-name> -- telnet license.factory.local 1947

# Common issues:
# 1. License expired - contact CODESYS support
# 2. License server unreachable - check network/firewall
# 3. Wrong license type - verify license matches TargetVisu for Linux SL
```

---

### PLC Connection Failed
```bash
# Test PLC connectivity
kubectl exec -it -n hmi <pod-name> -- ping <plc-host>
kubectl exec -it -n hmi <pod-name> -- telnet <plc-host> 11740

# Check PLC connection logs
kubectl logs -n hmi <pod-name> | grep -i "plc"

# Common issues:
# 1. Wrong PLC host/port - verify plc.connection.remote settings
# 2. Encryption mismatch - check PLC and HMI encryption settings
# 3. PLC not running - verify PLC runtime status
# 4. Network policy blocking - check NetworkPolicy rules
```

---

### High Memory Usage
```bash
# Check actual memory usage
kubectl top pod -n hmi

# Reduce memory footprint:
# 1. Lower maxClients (targetvisu.web.maxClients)
# 2. Disable unused features (dataLogging, trends)
# 3. Reduce history sizes (alarms.historySize, trends.historyDuration)
# 4. Use edge-minimal preset for simple HMIs
```

---

### Performance Issues
```bash
# Check metrics
kubectl port-forward -n hmi <pod-name> 9100:9100
curl http://localhost:9100/metrics | grep codesys_runtime_cycle_time

# Optimize performance:
# 1. Increase resources (CPU, memory)
# 2. Use industrial preset for complex HMIs
# 3. Reduce runtime.cycleTime (increase to 50-100ms if real-time not needed)
# 4. Enable compression (targetvisu.web.compression: true)
# 5. Check task overruns: codesys_task_overruns_total
```

---

## 📚 Use Case Examples

### 1. Factory HMI Panel (Edge)
**Scenario:** Simple operator panel for production line

**Configuration:**
```yaml
resourcePreset: edge-standard
service:
  type: NodePort
  http:
    nodePort: 30080
targetvisu:
  license:
    type: file
  web:
    maxClients: 3
  recipes:
    enabled: true
  alarms:
    enabled: true
protocols:
  modbusTcp:
    enabled: true
```

**Hardware:** Raspberry Pi 4 (4GB) or industrial PC  
**Users:** 1-3 operators on production floor  
**Access:** Direct NodePort via panel touchscreen  

---

### 2. Central SCADA System
**Scenario:** Monitor 20 PLCs across factory

**Configuration:**
```yaml
resourcePreset: industrial
service:
  type: LoadBalancer
targetvisu:
  web:
    maxClients: 25
  dataLogging:
    enabled: true
  trends:
    enabled: true
protocols:
  opcua:
    enabled: true
    security:
      mode: SignAndEncrypt
  modbusTcp:
    enabled: true
monitoring:
  serviceMonitor:
    enabled: true
```

**Hardware:** Server or VM (4 cores, 8GB RAM)  
**Users:** 10-25 concurrent operators/engineers  
**Access:** Ingress with SSL, LDAP authentication  

---

### 3. Building Automation
**Scenario:** HVAC and energy monitoring for commercial building

**Configuration:**
```yaml
resourcePreset: edge-standard
protocols:
  bacnet:
    enabled: true
  modbusTcp:
    enabled: true
  opcua:
    enabled: true
targetvisu:
  dataLogging:
    enabled: true
    interval: 5000  # 5 seconds
  trends:
    enabled: true
    historyDuration: 604800  # 7 days
ingress:
  enabled: true
  host: hvac.building.local
```

**Hardware:** Industrial PC or edge gateway  
**Protocols:** BACnet for HVAC, Modbus for energy meters  
**Features:** Trend logging for energy optimization  

---

## 📖 Additional Resources

- **CODESYS Store:** https://store.codesys.com/ (license purchase)
- **CODESYS Documentation:** https://help.codesys.com/
- **Example Projects:** See `sample-projects/` directory in chart
- **Integration Guide:** See `integration/` directory for PLC/protocol examples

---

## 📝 License Notes

**Chart License:** Apache 2.0 - Free to use and modify

**CODESYS TargetVisu License:** Commercial license required from CODESYS

**License Types:**
- **TargetVisu for Linux SL** - Single license (limited clients)
- **TargetVisu for Linux MC** - Multi-client license (10-100 clients)
- **TargetVisu for Linux Unlimited** - Unlimited concurrent clients

**Purchase:** https://store.codesys.com/ or contact CODESYS distributor

---

## 🎓 Getting Started Checklist

**Before deployment:**
- [ ] Obtain CODESYS TargetVisu for Linux SL license
- [ ] Build container image with licensed CODESYS runtime
- [ ] Create license Secret (or configure license server)
- [ ] Choose resource preset (edge-minimal/edge-standard/industrial)
- [ ] Decide network access method (NodePort/Ingress/LoadBalancer)
- [ ] Plan storage requirements (config + projects + logs)
- [ ] Identify industrial protocols needed (OPC UA, Modbus, etc.)

**After deployment:**
- [ ] Verify pod running and healthy
- [ ] Test web interface access
- [ ] Configure user authentication
- [ ] Upload HMI project files
- [ ] Test PLC connection (if enabled)
- [ ] Verify protocol connectivity (OPC UA, Modbus, etc.)
- [ ] Configure alarms and data logging
- [ ] Set up Prometheus monitoring
- [ ] Import Grafana dashboards
- [ ] Test backup/restore procedures

---

**Remember:** CODESYS TargetVisu requires persistent storage for license activation. Always enable storage volumes. For production SCADA systems, use redundant HMI instances with LoadBalancer for high availability. 🏭

*Pro tip:* Start with `edge-standard` preset and NodePort service. Enable authentication immediately (even in dev environments - build secure habits early). Use demo mode only for testing - production requires valid license. For OPC UA security, always use SignAndEncrypt mode in production. 🔐

**Happy visualizing!** 📊

---

*Created by Patrick Ryan - Fireball Industries*

*"Your PLC is about to crash, but at least the HMI will look good while it happens."*
