# 🏠 Home Assistant Helm Chart for Kubernetes/K3s

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Helm Chart Version](https://img.shields.io/badge/helm-v1.0.0-blue)](https://github.com/fireballindustries/home-assistant-pod)
[![Home Assistant Version](https://img.shields.io/badge/home--assistant-2024.12.0-blue)](https://www.home-assistant.io/)

**Production-ready Home Assistant Helm chart for industrial IoT and smart home management on Kubernetes/K3s.**

> "Because manually toggling lights like a caveman is so 2010. Also, your smart home will eventually gain sentience and lock you out." - Patrick Ryan, Fireball Industries

---

## 📋 Table of Contents

- [Features](#-features)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Architecture](#-architecture)
- [Configuration](#-configuration)
- [Database Options](#-database-options)
- [Add-on Components](#-add-on-components)
- [Storage](#-storage)
- [Security](#-security)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 Features

### Core Capabilities
- **Production-Ready**: StatefulSet deployment with persistent storage and proper health checks
- **Database Options**: SQLite (default), PostgreSQL (recommended), or external database support
- **Integrated Add-ons**: MQTT, Node-RED, ESPHome, Zigbee2MQTT as sidecars or separate deployments
- **Flexible Storage**: Configurable PersistentVolumeClaims for config, media, backups, cameras
- **Security-First**: RBAC, NetworkPolicy, secret management, and TLS support
- **Scalable**: Resource limits, probes, and monitoring integration
- **K3s Optimized**: Works perfectly on edge devices and lightweight Kubernetes distributions

### Device Support ✨ NEW
- **USB Devices**: Z-Wave, Zigbee coordinators, serial adapters
- **Bluetooth**: BLE device integration
- **GPIO**: Raspberry Pi GPIO support
- **Cameras**: RTSP streams, recordings, retention policies

### Industrial IoT ✨ NEW
- **OPC-UA**: PLC and industrial server connections
- **Modbus**: TCP and RTU device support
- **InfluxDB**: Time-series data export
- **SNMP**: Network equipment monitoring

### Management Tools ✨ NEW
- **PowerShell Scripts**: Deploy, test, backup, restore, device discovery
- **Testing Suite**: Health checks, API validation, integration tests
- **Monitoring**: Grafana dashboards, Prometheus alerts
- **Examples**: Pre-configured setups for various use cases

**Why this chart?**
- Most Home Assistant charts are hobbyist-grade trash fires 🔥
- This one actually works in production (AND in factories)
- Maintained by someone who knows the pain of debugging YAML at 3 AM
- Includes Patrick Ryan's signature dark millennial humor (free of charge)
- Now with industrial-grade IoT support because why not

---

## 📦 Prerequisites

### Required
- Kubernetes 1.21+ or K3s 1.21+
- Helm 3.0+
- PersistentVolume provisioner support (local-path, NFS, Longhorn, etc.)

### Optional but Recommended
- Ingress controller (nginx, traefik)
- MetalLB or cloud load balancer (for LoadBalancer service type)
- cert-manager (for TLS certificates)
- Prometheus operator (for monitoring)

### Storage Requirements
- **Minimum**: 10GB for Home Assistant config
- **Recommended**: 50GB total (config + media + backups)
- **PostgreSQL**: Additional 5GB if using internal PostgreSQL

---

## 🚀 Quick Start

### 1. Add Helm Repository

```bash
# Add the Fireball Industries Helm repository
helm repo add fireball https://charts.fireballindustries.com
helm repo update
```

**Note**: Repository not published yet? Clone this repo and install locally:

```bash
git clone https://github.com/fireballindustries/home-assistant-pod.git
cd home-assistant-pod
```

### 2. Install with Default Values (SQLite)

```bash
# Install with default values (SQLite, sidecar MQTT)
helm install home-assistant fireball/home-assistant-pod \
  --namespace home-assistant \
  --create-namespace
```

Or from local directory:

```bash
helm install home-assistant ./home-assistant-pod \
  --namespace home-assistant \
  --create-namespace
```

### 3. Access Home Assistant

Wait for the pod to be ready:

```bash
kubectl get pods -n home-assistant -w
```

Port-forward to access locally:

```bash
kubectl port-forward -n home-assistant svc/home-assistant 8123:8123
```

Open http://localhost:8123 and complete the onboarding wizard.

---

## 🏗️ Architecture

### Deployment Model

This chart deploys Home Assistant as a **StatefulSet** with the following components:

```
┌─────────────────────────────────────────────────────────────┐
│                     StatefulSet Pod                         │
│                                                             │
│  ┌──────────────────┐  ┌──────────────────┐               │
│  │ Home Assistant   │  │ MQTT (Mosquitto) │  [Sidecars]   │
│  │    (Primary)     │  │   (Optional)     │               │
│  └──────────────────┘  └──────────────────┘               │
│                                                             │
│  ┌──────────────────┐  ┌──────────────────┐               │
│  │   Node-RED       │  │    ESPHome       │  [Sidecars]   │
│  │   (Optional)     │  │   (Optional)     │               │
│  └──────────────────┘  └──────────────────┘               │
│                                                             │
│  ┌──────────────────┐                                      │
│  │  Zigbee2MQTT     │  [Sidecar - USB required]           │
│  │   (Optional)     │                                      │
│  └──────────────────┘                                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                        ↓
          ┌─────────────────────────────┐
          │  Persistent Volume Claims   │
          │  - config (10GB)            │
          │  - media (20GB)             │
          │  - share (5GB)              │
          │  - backups (10GB)           │
          └─────────────────────────────┘

Optional PostgreSQL StatefulSet (separate)
          ┌─────────────────────────────┐
          │   PostgreSQL Database       │
          │   - Storage (5GB)           │
          └─────────────────────────────┘
```

**Why StatefulSet instead of Deployment?**
- Stable network identity (important for integrations that cache hostnames)
- Ordered deployment and scaling
- Stable persistent storage association
- Home Assistant Core does NOT support HA mode (ironic, right?)

---

## ⚙️ Configuration

### Basic Configuration

Create a `values.yaml` file:

```yaml
# Basic configuration
global:
  timezone: "America/New_York"

homeassistant:
  image:
    tag: "2024.12.0"
  
  resources:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 2000m
      memory: 4Gi

# Service type
service:
  main:
    type: LoadBalancer  # or NodePort, ClusterIP

# Enable PostgreSQL
database:
  type: postgresql
  postgresql:
    enabled: true
    auth:
      password: "CHANGE-ME-NOW"

# Enable add-ons
mqtt:
  enabled: true
  deployment: sidecar

nodered:
  enabled: true
  deployment: sidecar
```

Install with custom values:

```bash
helm install home-assistant ./home-assistant-pod \
  --namespace home-assistant \
  --create-namespace \
  --values values.yaml
```

### All Configuration Options

See [values.yaml](values.yaml) for complete configuration reference.

Key sections:
- `homeassistant.*` - Home Assistant container settings
- `database.*` - Database configuration (SQLite, PostgreSQL, external)
- `persistence.*` - Storage volumes
- `service.*` - Service and networking
- `ingress.*` - Ingress configuration
- `mqtt.*` - MQTT broker settings
- `nodered.*` - Node-RED settings
- `esphome.*` - ESPHome settings
- `zigbee2mqtt.*` - Zigbee2MQTT settings

---

## 🗄️ Database Options

### Option 1: SQLite (Default)

**Pros**: Simple, no external dependencies, single file
**Cons**: Performance degrades with >100 devices, locks on writes

```yaml
database:
  type: sqlite
```

Good for: Home labs, testing, <100 devices

### Option 2: PostgreSQL (Recommended)

**Pros**: Better performance, concurrent access, ACID compliance
**Cons**: Requires additional storage and resources

```yaml
database:
  type: postgresql
  postgresql:
    enabled: true
    auth:
      database: homeassistant
      username: homeassistant
      password: "CHANGE-THIS-PASSWORD"
    persistence:
      size: 5Gi
    resources:
      requests:
        cpu: 100m
        memory: 256Mi
```

Good for: Production, >200 devices, high write volume

### Option 3: External Database

**Pros**: Use existing database infrastructure
**Cons**: You manage backups and availability

```yaml
database:
  type: external
  external:
    dbType: postgresql  # or mysql, mariadb
    host: "postgres.example.com"
    port: 5432
    database: "homeassistant"
    username: "homeassistant"
    passwordSecret: "ha-db-password"
    passwordKey: "password"
```

Create the secret first:

```bash
kubectl create secret generic ha-db-password \
  --from-literal=password='your-password-here' \
  -n home-assistant
```

Good for: Enterprise environments, existing database clusters

---

## 🔌 Add-on Components

### MQTT Broker (Mosquitto)

Message bus for IoT devices. Required for Zigbee2MQTT, Tasmota, ESPHome, etc.

```yaml
mqtt:
  enabled: true
  deployment: sidecar  # or 'separate'
  ports:
    mqtt: 1883
    websocket: 9001
  config:
    allowAnonymous: false
    username: "mqtt"
    password: "CHANGE-ME"
```

**Access MQTT**:
- From Home Assistant: `mqtt://localhost:1883` (if sidecar)
- From other pods: `mqtt://home-assistant-mqtt:1883` (if separate)

### Node-RED

Visual automation and flow-based programming.

```yaml
nodered:
  enabled: true
  deployment: sidecar
  port: 1880
  security:
    enabled: true
    username: "admin"
    # Generate hash: node -e "console.log(require('bcryptjs').hashSync('password', 8));"
    passwordHash: "bcrypt-hash-here"
```

**Access Node-RED**:
```bash
kubectl port-forward -n home-assistant svc/home-assistant 1880:1880
```
Open http://localhost:1880

### ESPHome

Manage ESP32/ESP8266 devices.

```yaml
esphome:
  enabled: true
  deployment: sidecar
  port: 6052
```

**Access ESPHome**:
```bash
kubectl port-forward -n home-assistant svc/home-assistant 6052:6052
```
Open http://localhost:6052

### Zigbee2MQTT

Bridge for Zigbee devices (requires USB Zigbee coordinator).

```yaml
zigbee2mqtt:
  enabled: true
  deployment: sidecar
  port: 8080
  usbDevice: "/dev/ttyACM0"
  
# IMPORTANT: Use nodeSelector to schedule on node with USB device
homeassistant:
  nodeSelector:
    usb-zigbee: "true"
```

Label your node:
```bash
kubectl label nodes <node-name> usb-zigbee=true
```

---

## 💾 Storage

### Storage Structure

```
/config    - Home Assistant configuration (10GB default)
/media     - Camera recordings, snapshots (20GB default)
/share     - Shared data between add-ons (5GB default)
/backups   - Automated backups (10GB default)
```

### Configure Storage Classes

```yaml
persistence:
  config:
    enabled: true
    storageClass: "longhorn"  # or local-path, nfs-client, etc.
    size: 10Gi
  
  media:
    enabled: true
    storageClass: "longhorn"
    size: 50Gi  # Increase for lots of camera footage
```

### Use Existing PVCs

```yaml
persistence:
  config:
    enabled: true
    existingClaim: "my-existing-pvc"
```

### Backup Strategy

**Automated Backups** (coming soon):
```yaml
backups:
  enabled: true
  schedule: "0 2 * * *"  # Daily at 2 AM
  retention: 7
```

**Manual Backup**:
```bash
# Backup config directory
kubectl exec -n home-assistant home-assistant-0 -- \
  tar czf /backups/config-$(date +%Y%m%d).tar.gz /config

# Copy to local machine
kubectl cp home-assistant/home-assistant-0:/backups/config-20240111.tar.gz \
  ./config-backup.tar.gz
```

---
## 🛠️ Management Tools

### PowerShell Scripts ✨ NEW

The chart includes comprehensive PowerShell management scripts in the `scripts/` directory:

#### Main Management Script

`manage-homeassistant.ps1` - All-in-one management tool

```powershell
# Deploy with custom values
.\scripts\manage-homeassistant.ps1 -Action deploy -ValuesFile examples\minimal-home.yaml

# Check deployment status
.\scripts\manage-homeassistant.ps1 -Action status

# View logs (follow mode)
.\scripts\manage-homeassistant.ps1 -Action logs -Follow

# Create backup
.\scripts\manage-homeassistant.ps1 -Action backup

# Restore from backup
.\scripts\manage-homeassistant.ps1 -Action restore -BackupFile backup-20240111.tar.gz

# Open shell in pod
.\scripts\manage-homeassistant.ps1 -Action shell

# Run tests
.\scripts\manage-homeassistant.ps1 -Action test

# Discover USB devices
.\scripts\manage-homeassistant.ps1 -Action devices -NodeName k3s-node-1

# Upgrade chart
.\scripts\manage-homeassistant.ps1 -Action upgrade -ValuesFile values.yaml
```

#### Testing Suite

`test-homeassistant.ps1` - Comprehensive health checks

```powershell
# Quick health check
.\scripts\test-homeassistant.ps1 -TestSuite quick

# Full test suite
.\scripts\test-homeassistant.ps1 -TestSuite full

# Integration tests (API, MQTT, DB, add-ons)
.\scripts\test-homeassistant.ps1 -TestSuite integration
```

Tests include:
- Pod health and readiness
- Service endpoint validation
- HTTP API response checks
- Database connectivity
- MQTT broker functionality
- Add-on health status
- Persistent storage mounting

#### Device Discovery

`device-discovery.ps1` - USB device detection and configuration

```powershell
# List USB devices on specific node
.\scripts\device-discovery.ps1 -Action list -NodeName k3s-node-1

# Watch for device changes
.\scripts\device-discovery.ps1 -Action watch -NodeName k3s-node-1

# Check device permissions
.\scripts\device-discovery.ps1 -Action permissions -NodeName k3s-node-1
```

Automatically generates Helm values configuration for detected devices.

---
## 🔒 Security

### Change Default Passwords

**NEVER use default passwords in production!**

```yaml
database:
  postgresql:
    auth:
      password: "$(openssl rand -base64 32)"

mqtt:
  config:
    password: "$(openssl rand -base64 32)"
```

### Enable TLS/SSL

Use cert-manager for automatic certificate management:

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: homeassistant.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: homeassistant-tls
      hosts:
        - homeassistant.example.com
```

### Network Policies

Restrict network access:

```yaml
networkPolicy:
  enabled: true
  ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            name: trusted-namespace
```

### External Secret Management

Use External Secrets Operator, Sealed Secrets, or Vault instead of plain Kubernetes secrets:

```yaml
database:
  postgresql:
    auth:
      existingSecret: "ha-postgres-secret"  # Managed externally
```

---

## 🐛 Troubleshooting

### Pod Not Starting

Check pod status:
```bash
kubectl get pods -n home-assistant
kubectl describe pod -n home-assistant home-assistant-0
kubectl logs -n home-assistant home-assistant-0
```

Common issues:
- **PVC not binding**: Check StorageClass and available PVs
- **Image pull errors**: Check image tag and registry access
- **USB device access**: Verify nodeSelector and device path

### Database Connection Issues

Check database connectivity:
```bash
# If using PostgreSQL
kubectl exec -n home-assistant home-assistant-0 -- \
  pg_isready -h home-assistant-postgresql -U homeassistant
```

### MQTT Not Working

Check MQTT broker:
```bash
# Test MQTT connection
kubectl exec -n home-assistant home-assistant-0 -c mqtt -- \
  mosquitto_sub -h localhost -t test -v
```

### Persistent Storage Issues

Check PVC status:
```bash
kubectl get pvc -n home-assistant
kubectl describe pvc -n home-assistant
```

### Performance Issues

Check resource usage:
```bash
kubectl top pods -n home-assistant
```

Increase resources in values.yaml if needed.

---

## 🎨 Advanced Scenarios

### High Availability (External DB + Shared Storage)

While Home Assistant Core doesn't support multiple replicas, you can achieve HA at the infrastructure level:

```yaml
database:
  type: external
  external:
    host: "postgres-ha-cluster.database.svc.cluster.local"

persistence:
  config:
    storageClass: "nfs-client"  # Shared filesystem
```

### Multi-Node K3s Cluster

```yaml
homeassistant:
  nodeSelector:
    node-role.kubernetes.io/master: "true"
  
  # USB device access
  extraVolumes:
    - name: usb-zigbee
      hostPath:
        path: /dev/ttyACM0
```

### Ingress with OAuth2 Proxy

Add authentication layer:

```yaml
ingress:
  enabled: true
  annotations:
    nginx.ingress.kubernetes.io/auth-url: "https://oauth2.example.com/oauth2/auth"
    nginx.ingress.kubernetes.io/auth-signin: "https://oauth2.example.com/oauth2/start"
```

---

## 📊 Monitoring

### Prometheus Integration

Enable ServiceMonitor for Prometheus Operator:

```yaml
monitoring:
  serviceMonitor:
    enabled: true
    interval: 30s
```

### Grafana Dashboard

Import Home Assistant Grafana dashboard (ID: 11306) or use the included dashboard:

```yaml
monitoring:
  grafanaDashboard:
    enabled: true
    labels:
      grafana_dashboard: "1"
```

---

## 🛠️ Development

### Local Testing

Test the chart locally:

```bash
# Lint the chart
helm lint ./home-assistant-pod

# Dry-run install
helm install home-assistant ./home-assistant-pod \
  --dry-run --debug

# Template output
helm template home-assistant ./home-assistant-pod \
  --namespace home-assistant > output.yaml
```

### Upgrade Existing Release

```bash
helm upgrade home-assistant ./home-assistant-pod \
  --namespace home-assistant \
  --values values.yaml
```

### Uninstall

```bash
helm uninstall home-assistant -n home-assistant

# Also delete PVCs (if desired)
kubectl delete pvc -n home-assistant -l app.kubernetes.io/instance=home-assistant
```

---

## 📝 Changelog

### Version 1.0.0 (2024-01-11)

**Phase 1: Core Features**
- ✅ StatefulSet deployment with Home Assistant 2024.12.0
- ✅ Database options: SQLite, PostgreSQL, External
- ✅ Add-on support: MQTT, Node-RED, ESPHome, Zigbee2MQTT
- ✅ Configurable persistent storage
- ✅ Service types: LoadBalancer, NodePort, ClusterIP
- ✅ Ingress support with TLS
- ✅ Health probes and resource management

**Phase 2: Extended Features** ✨ NEW
- ✅ Device access (USB, Bluetooth, GPIO)
- ✅ RBAC and NetworkPolicy templates
- ✅ ServiceMonitor for Prometheus
- ✅ PowerShell management scripts (deploy, test, backup, device discovery)
- ✅ Example configurations (minimal, industrial IoT, etc.)
- ✅ Grafana dashboards and Prometheus alerts
- ✅ Industrial IoT integrations (OPC-UA, Modbus, InfluxDB, SNMP)
- ✅ Camera support with retention policies
- ✅ Configuration templates and automation examples
- ✅ Comprehensive testing suite
- ✅ Patrick Ryan's signature dark humor throughout (doubled)

---

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

**Before submitting**:
- Run `helm lint`
- Test on a real cluster
- Update documentation
- Include Patrick Ryan-approved humor (optional but encouraged)

---

## 📄 License

This project is licensed under the **Apache License 2.0** - see the [LICENSE](LICENSE) file for details.

```
Copyright 2024 Fireball Industries - Patrick Ryan

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

---

## 🙏 Acknowledgments

- [Home Assistant Core Team](https://github.com/home-assistant/core) - For the amazing platform
- [Kubernetes Community](https://kubernetes.io/) - For making container orchestration tolerable
- **Patrick Ryan / Fireball Industries** - For questionable life choices and dark humor
- Coffee ☕ - The real MVP

---

## 📬 Support

- **Documentation**: https://github.com/fireballindustries/home-assistant-pod
- **Issues**: https://github.com/fireballindustries/home-assistant-pod/issues
- **Email**: patrick@fireballindustries.com

**Support Policy**: RTFM first, ask questions later. We spent hours writing this documentation while questioning our life choices at 3 AM. The least you can do is read it.

---

## 🎯 Roadmap

**Phase 1 & 2: Complete ✅**
- [x] Core Helm chart with add-ons
- [x] Database options (SQLite, PostgreSQL)
- [x] Device access (USB, Bluetooth, GPIO)
- [x] RBAC and NetworkPolicy
- [x] Grafana dashboards
- [x] Prometheus alerts
- [x] PowerShell management scripts
- [x] Industrial IoT integrations

**Future Enhancements**
- [ ] Automated backup CronJob with S3 support
- [ ] Multi-architecture images (ARM64)
- [ ] ArgoCD GitOps integration
- [ ] High Availability (multi-replica) support
- [ ] Voice assistant integration (Alexa, Google, Siri)
- [ ] Z-Wave JS add-on
- [ ] Additional Grafana dashboards (device health, automation performance)
- [ ] Kustomize overlays
- [ ] Operator pattern implementation
- [ ] Matter protocol support
- [ ] AI-powered automation suggestions (because why not)
- [ ] Skynet integration (just kidding... or are we?)

---

<div align="center">

**Built with ☕ and questionable life choices**

*Fireball Industries - Patrick Ryan*

*"Your smart home is now more intelligent than your ex"*

---

⭐ **Star this repo if it helped you!** ⭐

</div>
