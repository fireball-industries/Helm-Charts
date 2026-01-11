# Fireball Industrial IOT Platform

**Production-ready Industrial IoT platform powered by Home Assistant for Kubernetes/K3s.**

Because manually monitoring factory equipment like it's 1950 is so last century. Also, your factory will eventually optimize itself and make you obsolete. 🏭🤖

---

## � What is the Industrial IOT Platform?

**Industrial IOT** is a production-ready platform built on Home Assistant for industrial automation and edge computing:

- **Universal Integration** - 2,000+ integrations (PLCs, sensors, actuators, cameras, SCADA systems)
- **Industrial Protocols** - OPC-UA, Modbus TCP/RTU, EtherNet/IP, PROFINET, BACnet, MQTT
- **Edge Computing** - Local control, no cloud required, 100% data sovereignty
- **Automation Engine** - Time-based, sensor-triggered, AI-powered automations
- **Data Logging** - InfluxDB integration, time-series data, analytics
- **Monitoring & Control** - Equipment health, production metrics, alarm management

**Perfect for:** Smart manufacturing, building automation, industrial IoT monitoring, edge computing, SCADA systems.

---

## 📦 What This Chart Includes

This isn't your typical hobbyist-grade Home Assistant deployment. This is production-ready:

✅ **Home Assistant Core** - Latest stable release with persistent storage  
✅ **Database Options** - SQLite (simple), PostgreSQL (production), or external DB  
✅ **MQTT Broker** - Mosquitto for IoT device communication  
✅ **Node-RED** - Visual flow-based automation programming  
✅ **ESPHome** - Manage ESP32/ESP8266 custom devices  
✅ **Zigbee2MQTT** - Zigbee device integration (optional)  
✅ **Camera Support** - RTSP streams, recording, retention policies  
✅ **USB Devices** - Z-Wave, Zigbee dongles, serial adapters  
✅ **Industrial IoT** - OPC-UA, Modbus, InfluxDB, SNMP integrations  
✅ **Automated Backups** - CronJob-based snapshot management  
✅ **Prometheus Monitoring** - ServiceMonitor and Grafana dashboards  
✅ **Network Policy** - Secure pod-to-pod communication  

---

## 🚀 Resource Presets

Choose a preset based on your deployment size:

| Preset | CPU | RAM | Storage | Use Case |
|--------|-----|-----|---------|----------|
| **minimal** | 200m / 500m | 256Mi / 512Mi | 10Gi | <50 devices, SQLite, Raspberry Pi |
| **standard** | 500m / 1000m | 512Mi / 1Gi | 30Gi | 50-200 devices, PostgreSQL **(default)** |
| **full** | 1000m / 2000m | 1Gi / 2Gi | 60Gi | >200 devices + cameras, PostgreSQL |

**Recommendation:**
- Use **minimal** for simple smart home on Raspberry Pi (<50 devices)
- Choose **standard** for typical home automation (50-200 devices, recommended)
- Select **full** for complex setups with security cameras and industrial monitoring

---

## 🏁 Quick Start

### Standard Smart Home Deployment
Deploy with PostgreSQL and MQTT:

```bash
helm upgrade --install home-assistant fireball-industries/home-assistant-pod \
  --namespace home-automation \
  --create-namespace \
  --set homeassistant.resourcePreset=standard \
  --set database.type=postgresql \
  --set database.postgresql.enabled=true \
  --set mqtt.enabled=true \
  --set nodered.enabled=true
```

**Access Home Assistant:**
```bash
# Get LoadBalancer IP
kubectl get service -n home-automation home-assistant

# Access at: http://<load-balancer-ip>:8123
```

---

### Minimal Edge Deployment (SQLite)
Lightweight deployment for edge devices:

```bash
helm upgrade --install home-assistant fireball-industries/home-assistant-pod \
  --namespace home-automation \
  --create-namespace \
  --set homeassistant.resourcePreset=minimal \
  --set database.type=sqlite \
  --set mqtt.enabled=true \
  --set nodered.enabled=false \
  --set esphome.enabled=false
```

---

### Full Production with Cameras
High-performance setup with camera recording:

```bash
helm upgrade --install home-assistant fireball-industries/home-assistant-pod \
  --namespace home-automation \
  --create-namespace \
  --set homeassistant.resourcePreset=full \
  --set database.type=postgresql \
  --set database.postgresql.enabled=true \
  --set cameras.enabled=true \
  --set cameras.storage.size=100Gi \
  --set cameras.retention.days=14 \
  --set monitoring.serviceMonitor.enabled=true
```

---

## 🗄️ Database Options

### SQLite (Default - Minimal Setup)
Built-in file-based database:

**Configuration:**
```yaml
database:
  type: sqlite
```

**Best for:**
- <50 devices
- Simple smart home setups
- Raspberry Pi / edge devices
- Quick testing

**Pros:**
- No setup required
- Lightweight (low resource usage)
- Single file backup

**Cons:**
- Slower queries with many devices
- Limited scalability (>100 devices slow)
- No concurrent access

---

### PostgreSQL (Recommended - Production)
High-performance relational database:

**Configuration:**
```yaml
database:
  type: postgresql
  postgresql:
    enabled: true
    auth:
      password: "your-secure-password"
    persistence:
      size: 5Gi
```

**Best for:**
- 50-500+ devices
- Production environments
- Complex automations
- Long-term history storage

**Pros:**
- Fast queries (even with 1M+ records)
- Excellent scalability
- Reliable and battle-tested
- Advanced indexing

**Cons:**
- More resource usage (~500MB RAM)
- Requires password management

---

### External Database (Enterprise)
Connect to existing database cluster:

**Configuration:**
```yaml
database:
  type: external
  external:
    host: postgres.example.com
    port: 5432
    database: homeassistant
    username: homeassistant
    # Password in Secret: ha-external-db-password
```

**Best for:**
- Enterprise deployments
- Shared database clusters
- High availability requirements
- Compliance (database in specific location)

---

## 🌐 Network Access

### LoadBalancer (Recommended)
Automatic external IP assignment:

**Configuration:**
```yaml
service:
  main:
    type: LoadBalancer
```

**Access:** `http://<load-balancer-ip>:8123`

**Best for:**
- Cloud deployments (AWS, GCP, Azure)
- On-premise with MetalLB
- Production environments

---

### NodePort (Edge Deployments)
Direct access via node IP:

**Configuration:**
```yaml
service:
  main:
    type: NodePort
    nodePort: 30123
```

**Access:** `http://<node-ip>:30123`

**Best for:**
- Edge devices
- Single-node K3s
- Testing environments

---

### Ingress (Domain Name)
SSL termination with hostname:

**Configuration:**
```yaml
service:
  main:
    type: ClusterIP
ingress:
  enabled: true
  className: nginx
  hosts:
    - host: home.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: home-assistant-tls
      hosts:
        - home.example.com
```

**Access:** `https://home.example.com`

**Best for:**
- Multiple services with subdomains
- Centralized SSL certificate management
- Reverse proxy setup

---

### Host Network (mDNS Discovery)
Use host network for device discovery:

**Configuration:**
```yaml
homeassistant:
  hostNetwork: true
```

**⚠️ Security Warning:** Bypasses NetworkPolicy and exposes all ports to host network.

**Enable if you need:**
- mDNS/Bonjour discovery (Chromecasts, Apple TV, Sonos)
- DLNA/UPnP devices (smart TVs, media servers)
- Network scanning for automatic device detection

**Alternative:** Use NodePort or LoadBalancer without host network (more secure).

---

## 📱 Add-on Components

### MQTT Broker (Mosquitto)
Message bus for IoT devices:

**Configuration:**
```yaml
mqtt:
  enabled: true
  deployment: sidecar  # or separate
  config:
    allowAnonymous: false
    username: mqtt
    password: your-mqtt-password
```

**Use cases:**
- Zigbee/Z-Wave device communication
- ESP32/ESP8266 custom sensors
- Tasmota devices
- MQTT integrations (cameras, thermostats)

**Sidecar vs Separate:**
- **sidecar** - Same pod, lower latency, shares resources
- **separate** - Dedicated pod, independent scaling, easier troubleshooting

---

### Node-RED (Visual Automation)
Flow-based programming for complex automations:

**Configuration:**
```yaml
nodered:
  enabled: true
  deployment: sidecar
  port: 1880
  security:
    enabled: true
```

**Access:** `http://<service-ip>:1880`

**Use cases:**
- Complex automation logic
- API integration (REST, WebSocket)
- Data transformation
- Custom dashboards

**Features:**
- Visual drag-and-drop programming
- 2,000+ community nodes
- Integration with Home Assistant API
- Real-time debugging

---

### ESPHome (Custom Devices)
Manage ESP32/ESP8266 devices:

**Configuration:**
```yaml
esphome:
  enabled: true
  deployment: sidecar
  port: 6052
```

**Access:** `http://<service-ip>:6052`

**Use cases:**
- DIY temperature sensors
- Custom RGB lighting controllers
- Motion sensors
- Garage door openers

**Features:**
- Web-based configuration
- OTA firmware updates
- Native Home Assistant integration
- YAML-based device config

---

### Zigbee2MQTT (Zigbee Bridge)
Bridge Zigbee devices to MQTT:

**Configuration:**
```yaml
zigbee2mqtt:
  enabled: true
  deployment: sidecar
  usbDevice: /dev/ttyACM0  # Zigbee coordinator
```

**⚠️ Requires:** USB Zigbee coordinator (CC2531, CC2652, ConBee II)

**Use cases:**
- Philips Hue lights (without bridge)
- IKEA Tradfri devices
- Xiaomi Aqara sensors
- Zigbee smart plugs

**Features:**
- Web UI for device pairing
- 2,000+ supported devices
- OTA firmware updates
- Network visualization

---

## 🎥 Camera Support

### RTSP Streams & Recording
Store camera recordings with automatic cleanup:

**Configuration:**
```yaml
cameras:
  enabled: true
  storage:
    size: 50Gi  # Adjust based on camera count
  retention:
    days: 7  # Auto-delete after 7 days
    autoCleanup: true
```

**Storage calculation:**
- 1080p camera @ 24/7 recording: ~2GB/day
- 4K camera @ 24/7 recording: ~8GB/day
- Motion-only recording: ~10-20% of full recording

**Retention examples:**
- 7 days @ 3 cameras (1080p): 42GB
- 14 days @ 5 cameras (1080p): 140GB
- 30 days @ 2 cameras (4K): 480GB

---

### Add Camera Streams
Configure cameras via values.yaml:

**Configuration:**
```yaml
cameras:
  enabled: true
  streams:
    - name: front_door
      url: rtsp://camera1.local:554/stream
      username: admin
      password: changeme
    - name: garage
      url: rtsp://camera2.local:554/stream
    - name: backyard
      url: rtsp://camera3.local:554/stream
```

**Supported protocols:**
- RTSP (most IP cameras)
- HTTP/HTTPS (MJPEG streams)
- RTMP (streaming servers)

---

## 🔌 USB Device Access

### Z-Wave / Zigbee Dongles
Mount USB devices for protocol adapters:

**Configuration:**
```yaml
devices:
  usb:
    enabled: true
    devices:
      - name: zwave
        hostPath: /dev/ttyUSB0
      - name: zigbee
        hostPath: /dev/ttyACM0
```

**Common devices:**
- **Z-Wave:** Aeotec Z-Stick, Zooz ZST10, HomeSeer Z-NET
- **Zigbee:** ConBee II, Sonoff Zigbee 3.0, CC2652
- **Serial:** RS-232/RS-485 adapters

**⚠️ Node Affinity:** Pod must run on node with USB device attached.

---

### Bluetooth (BLE)
Enable Bluetooth for device integration:

**Configuration:**
```yaml
devices:
  bluetooth:
    enabled: true
    hostBluetooth: true
```

**Use cases:**
- Bluetooth Low Energy sensors
- Indoor positioning (iBeacons)
- Presence detection (phone tracking)
- Xiaomi Mi thermometers

---

### GPIO (Raspberry Pi)
Direct GPIO pin access:

**Configuration:**
```yaml
devices:
  gpio:
    enabled: true
    privileged: true
```

**⚠️ Security:** Requires privileged mode for GPIO access.

**Use cases:**
- Relay control (irrigation, garage)
- Button inputs
- LED indicators
- DHT22 temperature sensors

---

## 🏭 Industrial IoT Features

### OPC-UA Client
Connect to PLCs and industrial servers:

**Configuration:**
```yaml
industrial:
  opcua:
    enabled: true
    servers:
      - name: plc1
        url: "opc.tcp://192.168.1.10:4840"
        username: ""
        password: ""
```

**Use cases:**
- PLC data monitoring
- Industrial process visualization
- Production line status
- Equipment health monitoring

---

### Modbus TCP/RTU
Industrial protocol for sensors and controllers:

**Configuration:**
```yaml
industrial:
  modbus:
    enabled: true
    devices:
      - name: energy_meter
        type: tcp
        host: 192.168.1.20
        port: 502
      - name: plc_rtu
        type: serial
        port: /dev/ttyUSB2
        baudrate: 9600
```

**Use cases:**
- Energy meters
- Temperature controllers
- VFD drives
- Flow sensors

---

### InfluxDB Metrics Export
Export time-series data:

**Configuration:**
```yaml
industrial:
  influxdb:
    enabled: true
    url: http://influxdb:8086
    org: home-assistant
    bucket: homeassistant
```

**Use cases:**
- Long-term data retention
- Advanced analytics
- Grafana visualization
- Data science / ML workflows

---

### SNMP Monitoring
Network equipment monitoring:

**Configuration:**
```yaml
industrial:
  snmp:
    enabled: true
    devices:
      - name: network_switch
        host: 192.168.1.1
        community: public
        version: "2c"
```

**Use cases:**
- Network switch monitoring
- UPS status
- Server hardware metrics
- IoT gateway health

---

## 💾 Storage Volumes

### Config Volume (10Gi)
Home Assistant configuration files:

**Mountpoint:** `/config`

**Contents:**
- `configuration.yaml` - Main config
- `automations.yaml` - Automation rules
- `scripts.yaml` - Script definitions
- `secrets.yaml` - Credentials and API keys
- `.storage/` - UI configuration
- `www/` - Custom web resources

---

### Media Volume (20Gi)
Camera recordings and media files:

**Mountpoint:** `/media`

**Contents:**
- Camera recordings
- Snapshots from motion detection
- Image uploads
- Audio files

---

### Backups Volume (10Gi)
Automated backup snapshots:

**Mountpoint:** `/backups`

**Contents:**
- Full system snapshots (config + database)
- Partial backups (config only)
- Automated CronJob backups

---

## 📈 Monitoring & Observability

### Prometheus Metrics
Export metrics for monitoring:

**Configuration:**
```yaml
monitoring:
  serviceMonitor:
    enabled: true
    interval: 30s
```

**Metrics exposed:**
- `homeassistant_entity_available` - Entity availability
- `homeassistant_sensor_state` - Sensor values
- `homeassistant_automation_triggered_total` - Automation triggers
- `homeassistant_event_fired_total` - Event counts

---

### Grafana Dashboards
Pre-built visualization dashboards:

**Configuration:**
```yaml
monitoring:
  grafanaDashboard:
    enabled: true
```

**Dashboards included:**
- System Overview (CPU, memory, entities)
- Automation Performance (triggers, execution time)
- Device Status (availability, battery levels)
- Energy Monitoring (consumption, cost)

---

## 🔐 Security Best Practices

### Authentication
Always enable Home Assistant authentication:

1. **First login:** Create admin user during setup wizard
2. **Additional users:** Settings → People → Add Person
3. **Multi-factor auth:** Settings → Account → Multi-factor Authentication

---

### Network Security

**Enable NetworkPolicy:**
```yaml
networkPolicy:
  enabled: true
```

**Restrict ingress/egress:**
- Only allow traffic from specific namespaces
- Limit external internet access
- Block pod-to-pod communication

---

### Secrets Management
Never hardcode passwords in values.yaml:

**Create Kubernetes Secrets:**
```bash
# MQTT password
kubectl create secret generic mqtt-password \
  --from-literal=password=your-secure-password \
  -n home-automation

# Database password
kubectl create secret generic ha-db-password \
  --from-literal=postgresql-password=your-db-password \
  -n home-automation
```

---

### SSL/TLS
Always use HTTPS in production:

**Option 1: Ingress with cert-manager**
```yaml
ingress:
  enabled: true
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  tls:
    - secretName: home-assistant-tls
      hosts:
        - home.example.com
```

**Option 2: LoadBalancer with SSL termination**
- Use cloud load balancer SSL (AWS ALB, GCP LB)
- Configure MetalLB with SSL passthrough

---

## 🆘 Troubleshooting

### Pod Not Starting
```bash
# Check pod status
kubectl get pods -n home-automation

# Describe pod for events
kubectl describe pod -n home-automation home-assistant-0

# Common issues:
# 1. PVC not binding - check storage class
# 2. USB device not found - verify device path and node affinity
# 3. Database connection failed - check PostgreSQL pod and password
```

---

### Cannot Access Web Interface
```bash
# Check service
kubectl get service -n home-automation

# Port-forward for testing
kubectl port-forward -n home-automation home-assistant-0 8123:8123

# Access at: http://localhost:8123

# Common issues:
# 1. LoadBalancer pending - check MetalLB/cloud LB configuration
# 2. Ingress not working - verify Ingress controller installed
# 3. Host network conflicts - disable hostNetwork if not needed
```

---

### USB Devices Not Detected
```bash
# Check device path on node
kubectl debug node/<node-name> -it --image=ubuntu
lsusb
ls -la /dev/tty*

# Verify device mounted in pod
kubectl exec -it -n home-automation home-assistant-0 -- ls -la /dev

# Common issues:
# 1. Wrong device path - USB device enumeration changed
# 2. Node affinity missing - pod on wrong node
# 3. Permissions denied - check privileged mode enabled
```

---

### Database Performance Issues
```bash
# Check database size
kubectl exec -it -n home-automation home-assistant-postgresql-0 -- \
  psql -U homeassistant -c "SELECT pg_size_pretty(pg_database_size('homeassistant'));"

# Optimize database
# 1. Reduce recorder history (configuration.yaml)
# 2. Exclude noisy sensors
# 3. Enable purge_keep_days

# Monitor query performance
kubectl logs -n home-automation home-assistant-0 | grep "SELECT"
```

---

### High Memory Usage
```bash
# Check actual memory usage
kubectl top pod -n home-automation

# Reduce memory footprint:
# 1. Switch to SQLite (if <50 devices)
# 2. Disable unused add-ons (Node-RED, ESPHome)
# 3. Reduce recorder history
# 4. Limit camera recording retention
# 5. Use minimal preset
```

---

## 📚 Use Case Examples

### 1. Simple Smart Home (Raspberry Pi)
**Scenario:** Basic home automation on Raspberry Pi 4

**Configuration:**
```yaml
homeassistant:
  resourcePreset: minimal
  hostNetwork: true  # For Chromecast discovery
database:
  type: sqlite
mqtt:
  enabled: true
  deployment: sidecar
nodered:
  enabled: false
service:
  main:
    type: NodePort
```

**Devices:** 20-30 smart lights, thermostats, sensors  
**Hardware:** Raspberry Pi 4 (4GB RAM)  
**Access:** NodePort on local network  

---

### 2. Production Smart Home (Industrial PC)
**Scenario:** Full home automation with cameras and PostgreSQL

**Configuration:**
```yaml
homeassistant:
  resourcePreset: standard
database:
  type: postgresql
  postgresql:
    enabled: true
mqtt:
  enabled: true
nodered:
  enabled: true
cameras:
  enabled: true
  storage:
    size: 100Gi
  retention:
    days: 14
service:
  main:
    type: LoadBalancer
monitoring:
  serviceMonitor:
    enabled: true
```

**Devices:** 100-200 devices + 5 security cameras  
**Hardware:** Industrial PC or VM (4 cores, 8GB RAM)  
**Access:** LoadBalancer with MetalLB  

---

### 3. Industrial IoT Monitoring
**Scenario:** Factory equipment monitoring with Modbus and OPC-UA

**Configuration:**
```yaml
homeassistant:
  resourcePreset: full
database:
  type: postgresql
  postgresql:
    enabled: true
industrial:
  opcua:
    enabled: true
  modbus:
    enabled: true
  influxdb:
    enabled: true
    url: http://influxdb:8086
devices:
  usb:
    enabled: true  # RS-485 adapters
service:
  main:
    type: ClusterIP
ingress:
  enabled: true
  host: factory-hmi.local
```

**Devices:** 50 Modbus sensors + 3 PLCs (OPC-UA)  
**Hardware:** Server or VM (8 cores, 16GB RAM)  
**Access:** Ingress with SSL  

---

## 📖 Additional Resources

- **Home Assistant Docs:** https://www.home-assistant.io/docs/
- **Community Forum:** https://community.home-assistant.io/
- **Integration List:** https://www.home-assistant.io/integrations/
- **HACS (Custom Components):** https://hacs.xyz/
- **Example Configurations:** See `examples/` directory in chart

---

## 📝 License

**Chart License:** Apache 2.0 - Free to use and modify

**Home Assistant:** Apache 2.0 - Open source home automation

---

## 🎓 Getting Started Checklist

**Before deployment:**
- [ ] Choose resource preset (minimal/standard/full)
- [ ] Decide on database type (SQLite/PostgreSQL/external)
- [ ] Plan storage requirements (config + media + backups + cameras)
- [ ] Select network access method (LoadBalancer/NodePort/Ingress)
- [ ] Identify USB devices needed (Z-Wave, Zigbee)
- [ ] Configure timezone correctly
- [ ] Set up Kubernetes Secrets for passwords

**After deployment:**
- [ ] Verify pod running and healthy
- [ ] Access web interface and complete setup wizard
- [ ] Create admin user account
- [ ] Enable multi-factor authentication
- [ ] Configure MQTT broker (if enabled)
- [ ] Add device integrations
- [ ] Set up automations
- [ ] Configure camera streams (if enabled)
- [ ] Test USB devices (if enabled)
- [ ] Set up automated backups
- [ ] Import Grafana dashboards
- [ ] Configure alerts in Prometheus

---

**Remember:** Home Assistant uses persistent storage for critical configuration. Always enable storage volumes and set up automated backups. For production deployments, use PostgreSQL database for better performance. Enable authentication and NetworkPolicy for security. 🏠

*Pro tip:* Start with `standard` preset and PostgreSQL. Enable MQTT and Node-RED from day one. Use host network only if absolutely necessary (Chromecast, mDNS). Configure automated backups BEFORE making major configuration changes. Test USB devices on host node before enabling in chart. 🔧

**Happy automating!** 🤖

---

*Created by Patrick Ryan - Fireball Industries*

*"Your smart home: Now with 99.9% uptime and 100% judgment of your life choices."*
