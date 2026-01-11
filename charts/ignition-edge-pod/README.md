# Ignition Edge - Production Kubernetes Deployment

<div align="center">

**Because your operators deserve better than a Windows XP touchscreen running FactoryTalk from 2005**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.19+-blue.svg)](https://kubernetes.io/)
[![Helm](https://img.shields.io/badge/Helm-v3.0+-blue.svg)](https://helm.sh/)
[![Ignition](https://img.shields.io/badge/Ignition-8.1-orange.svg)](https://inductiveautomation.com/)

</div>

---

## 🔥 What Is This?

A production-ready Helm chart for deploying **Ignition Edge** on Kubernetes/K3s. This isn't your typical "copy-paste from the docs" deployment. This is a battle-tested, industrial-grade SCADA/HMI solution that actually understands how factories work.

### Features That Actually Matter

- ✅ **Demo Mode by Default** - 2-hour runtime sessions (perfect for testing, terrible for production)
- ✅ **5 Resource Presets** - From tiny HMI panels to enterprise MES systems
- ✅ **Industrial Protocols** - OPC UA, MQTT Sparkplug B, Modbus, Allen-Bradley, Siemens
- ✅ **Tag Historian** - TimescaleDB integration (because Excel is NOT a database)
- ✅ **Automated Backups** - Because losing your SCADA config is a career-limiting move
- ✅ **High Availability** - Active/standby redundancy (when uptime actually matters)
- ✅ **Prometheus Metrics** - Real monitoring, not "just check the logs"
- ✅ **PowerShell Management** - Scripts with personality and functionality

---

## 🚀 Quick Start (30 Seconds to Demo)

```powershell
# Clone the repository
git clone https://github.com/fireball-industries/ignition-edge-pod.git
cd ignition-edge-pod

# Deploy with defaults (demo mode)
helm install ignition-edge . --namespace industrial --create-namespace

# Access the gateway
kubectl port-forward -n industrial svc/ignition-edge 8088:8088

# Open browser to http://localhost:8088
# Username: admin
# Password: (get from secret - see below)
```

Get admin password:
```powershell
kubectl get secret ignition-edge-secret -n industrial -o jsonpath='{.data.admin-password}' | base64 -d
```

⚠️ **DEMO MODE ACTIVE** - Gateway restarts every 2 hours. See License Activation section for production use.

---

## 📦 What's Included

This chart includes **50+ files** for complete production deployment:

### Core Helm Chart
- `Chart.yaml` - Chart metadata with Rancher annotations
- `values.yaml` - 100+ configuration options
- `LICENSE` - MIT license (chart only)

### Kubernetes Templates (15+)
- `templates/_helpers.tpl` - Helper functions and presets
- `templates/deployment.yaml` - Main gateway deployment
- `templates/service.yaml` - Service exposure
- `templates/configmap.yaml` - Gateway configuration
- `templates/secret.yaml` - Credentials management
- `templates/backup-cronjob.yaml` - Automated backups
- And more...

### PowerShell Management Scripts (4)
- `scripts/manage-ignition.ps1` - Complete lifecycle management
- `scripts/test-ignition.ps1` - Connectivity testing
- `scripts/generate-ignition-config.ps1` - Configuration generator
- `scripts/provision-ignition.ps1` - Auto-provisioning

### Documentation (6+)
- `README.md` - You are here
- `LICENSING.md` - License activation guide
- `SECURITY.md` - Security configuration
- `PROTOCOLS.md` - Industrial protocol setup
- `TROUBLESHOOTING.md` - Common issues
- `QUICK_REFERENCE.md` - Command cheat sheet

### Example Configurations (6)
- `examples/demo-ignition.yaml` - Quick demo
- `examples/factory-hmi.yaml` - HMI panel
- `examples/edge-gateway-historian.yaml` - Edge with historian
- `examples/production-scada.yaml` - Full SCADA
- `examples/remote-edge.yaml` - Resource-constrained
- `examples/mes-integration.yaml` - MES system

---

## 🎯 Resource Presets

| Preset | CPU | RAM | Storage | Use Case |
|--------|-----|-----|---------|----------|
| **edge-panel** | 1-2 | 2-4 GiB | 10 GiB | HMI touchscreens |
| **edge-gateway** | 2-4 | 4-8 GiB | 20 GiB | IoT data collection |
| **edge-compute** | 4-8 | 8-16 GiB | 50 GiB | Standalone SCADA |
| **standard** | 4-8 | 16-32 GiB | 100 GiB | Production SCADA |
| **enterprise** | 8-16 | 32-64 GiB | 200 GiB | Enterprise MES |

**Deploy with a preset:**
```powershell
helm install ignition-edge . --set global.preset=edge-gateway
```

---

## 🔑 License Activation

### Demo Mode (Default)
- ✅ No license required
- ✅ Full functionality
- ⚠️ 2-hour runtime sessions (auto-restart)
- ❌ Not suitable for production

### Activate Production License

**Option 1: Via PowerShell (Easiest)**
```powershell
.\scripts\manage-ignition.ps1 -Action activate-license -ActivationKey "YOUR-KEY"
```

**Option 2: Via Kubernetes Secret (GitOps)**
```powershell
kubectl create secret generic ignition-license \
  --from-literal=activation-key=YOUR-KEY \
  -n industrial

helm upgrade ignition-edge . \
  --set license.existingSecret=ignition-license \
  --set global.demoMode=false
```

**Option 3: Via Web UI**
1. Open http://localhost:8088
2. Config → Licensing → Activate License
3. Enter activation key
4. Done

**Get a License:** https://inductiveautomation.com/ignition/edge

---

## 🏭 Industrial Protocols

### OPC UA Server
```yaml
opcua:
  server:
    enabled: true
    port: 62541
    securityPolicies:
      - "Basic256Sha256"
```

Connect PLCs: `opc.tcp://your-gateway:62541`

### MQTT Sparkplug B
```yaml
mqtt:
  engine:
    enabled: true    # Subscribe to IIoT devices
  transmission:
    enabled: true    # Publish to central gateway
    storeAndForward:
      enabled: true  # Won't lose data during network outages
```

### PLC Drivers
```yaml
drivers:
  allenBradley:
    enabled: true
    devices:
      - name: "ControlLogix-01"
        ipAddress: "192.168.1.20"
        
  siemens:
    enabled: true
    devices:
      - name: "S7-1500-01"
        ipAddress: "192.168.1.30"
        
  modbusTcp:
    enabled: true
    devices:
      - name: "Modbus-VFD-01"
        ipAddress: "192.168.1.40"
```

---

## 📊 Database Configuration

### PostgreSQL (Production Data)
```yaml
databases:
  postgresql:
    enabled: true
    host: "postgresql"
    database: "ignition"
```

### TimescaleDB (Tag Historian)
```yaml
databases:
  timescaledb:
    enabled: true
    host: "timescaledb"
    database: "historian"

historian:
  enabled: true
  retention:
    period: "90 days"
    compressionAge: "30 days"
```

---

## 💾 Backup & Restore

### Automated Backups
Runs daily at 2 AM by default:
```yaml
backup:
  enabled: true
  schedule: "0 2 * * *"
  retention: 30  # days
```

### Manual Backup
```powershell
.\scripts\manage-ignition.ps1 -Action backup
```

### Restore from Backup
```powershell
.\scripts\manage-ignition.ps1 -Action restore -BackupFile "gateway.gwbk"
```

---

## 📈 Monitoring

### Prometheus Metrics
JMX exporter provides metrics on port 5556:
- JVM heap and GC metrics
- Designer/client connection counts
- Tag counts and update rates
- Database connection pool status

Enable ServiceMonitor:
```yaml
monitoring:
  serviceMonitor:
    enabled: true
```

---

## 🛠️ PowerShell Scripts

### manage-ignition.ps1
Complete lifecycle management:
```powershell
# Deploy
.\scripts\manage-ignition.ps1 -Action deploy

# Health check
.\scripts\manage-ignition.ps1 -Action health-check

# Backup
.\scripts\manage-ignition.ps1 -Action backup

# View logs
.\scripts\manage-ignition.ps1 -Action logs

# Activate license
.\scripts\manage-ignition.ps1 -Action activate-license -ActivationKey "KEY"

# Restart demo mode (extends 2-hour session)
.\scripts\manage-ignition.ps1 -Action restart-demo
```

### test-ignition.ps1
Comprehensive testing:
```powershell
.\scripts\test-ignition.ps1
```

Tests: HTTP, HTTPS, OPC UA, MQTT, databases, security, performance

---

## 🐛 Troubleshooting

### Gateway Won't Start
```powershell
kubectl get pods -n industrial
kubectl describe pod ignition-edge-xxx -n industrial
kubectl logs ignition-edge-xxx -n industrial
```

### Demo Mode Keeps Restarting
That's the point. Activate your license for production.

### OPC UA Connection Issues
```powershell
kubectl port-forward svc/ignition-edge 62541:62541
# Test connection to localhost:62541
```

### Performance Issues
Upgrade to larger preset:
```powershell
helm upgrade ignition-edge . --set global.preset=standard
```

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for more.

---

## 📚 Documentation

- [LICENSING.md](LICENSING.md) - License activation procedures
- [SECURITY.md](SECURITY.md) - Security hardening guide
- [PROTOCOLS.md](PROTOCOLS.md) - Industrial protocol configuration
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues
- [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - Command cheat sheet

---

## 🤝 Contributing

PRs welcome! Especially with sarcastic commit messages.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

## 📜 License

MIT License - See [LICENSE](LICENSE) for details.

**Note:** Ignition software requires separate licensing from Inductive Automation.

---

## 🙏 Credits

Created by **Patrick Ryan** - Fireball Industries

*"Because your operators deserve better than Windows XP"*

Special thanks to:
- Factory floor workers who inspired this
- IT admins who support it
- The Ignition community
- Coffee

---

**Happy SCADAing!** 🏭
