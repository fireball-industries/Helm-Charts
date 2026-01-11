# InfluxDB Pod

**Fireball Industries** - *"Ignite Your Factory Efficiency"™*

> Industrial-grade InfluxDB time-series database for Kubernetes. Because your factory's sensor data deserves better than an Excel spreadsheet.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Helm](https://img.shields.io/badge/Helm-v3.0+-blue.svg)](https://helm.sh)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.24+-326CE5.svg)](https://kubernetes.io)

Production-ready Helm chart for deploying InfluxDB in industrial Kubernetes environments. Optimized for factory automation, IIoT sensor data, SCADA integration, and manufacturing analytics.

## 🔥 Quick Start

```bash
# Install with default settings
helm install influxdb ./influxdb-pod \
  --set influxdb.organization=my-factory \
  --namespace influxdb \
  --create-namespace

# Get admin token
kubectl get secret influxdb-influxdb-pod-auth -n influxdb \
  -o jsonpath='{.data.admin-token}' | base64 --decode

# Port-forward to access UI
kubectl port-forward -n influxdb svc/influxdb-influxdb-pod 8086:8086

# Open browser: http://localhost:8086
```

**That's it!** Production-ready time-series database in under 2 minutes.

## ✨ Features

- **🏭 Industrial-Ready**: Pre-configured buckets for sensors, SCADA, production, energy, quality
- **📊 Resource Presets**: Edge to enterprise (5 sensors to 1000+ sensors)
- **🔒 Security First**: Token-based auth, TLS, Pod Security Standards, network policies
- **⚡ High Availability**: StatefulSet clustering with anti-affinity and PDBs
- **💾 Data Retention**: Automatic downsampling (hot/warm/cold storage tiers)
- **🌐 Edge Support**: Remote write to central InfluxDB with local buffering
- **📡 Telegraf Integration**: OPC UA, Modbus, MQTT, SNMP collectors included
- **🔧 PowerShell Automation**: Complete management, testing, and config generation scripts

## 📦 What's Included

- **Helm Chart**: Production-ready Kubernetes deployment
- **15 Templates**: Deployment, StatefulSet, Services, Ingress, RBAC, NetworkPolicy, Backups
- **6 Examples**: Factory, HA, Edge, SCADA, Energy, Minimal configurations
- **3 PowerShell Scripts**: manage-influxdb.ps1, test-influxdb.ps1, generate-config.ps1
- **Comprehensive Docs**: Full documentation, security guide, quick reference
- **Industrial Defaults**: Optimized for manufacturing environments

## 🚀 Deployment Modes

### Single Mode (Dev, Test, Edge)
```bash
helm install influxdb ./influxdb-pod \
  --set deploymentMode=single \
  --set resourcePreset=small
```

### HA Mode (Production)
```bash
helm install influxdb ./influxdb-pod \
  --set deploymentMode=ha \
  --set resourcePreset=large \
  --set highAvailability.replicas=3
```

### Edge Deployment
```bash
helm install influxdb-edge ./influxdb-pod \
  -f examples/edge-gateway.yaml
```

## 📊 Resource Presets

| Preset | Sensors | Write Rate | Resources | Use Case |
|--------|---------|------------|-----------|----------|
| **edge** | <5 | <100 pts/sec | 256Mi / 0.5 CPU / 5Gi | Remote sites |
| **small** | <10 | <500 pts/sec | 512Mi / 1 CPU / 10Gi | Small factory |
| **medium** | <100 | <2K pts/sec | 2Gi / 2 CPU / 50Gi | Medium factory (default) |
| **large** | <1K | <10K pts/sec | 8Gi / 4 CPU / 200Gi | Large factory |
| **xlarge** | >1K | >10K pts/sec | 16Gi / 8 CPU / 500Gi | Enterprise plant |

## 🪣 Industrial Buckets

Pre-configured for manufacturing data:

- **sensors** (90d) - Raw sensor data (temperature, pressure, flow, vibration)
- **scada** (365d) - SCADA system metrics and alarms
- **production** (730d) - Production line metrics (OEE, cycle times, defects)
- **energy** (2555d/7y) - Energy consumption monitoring
- **quality** (2555d/7y) - Quality control measurements (21 CFR Part 11)
- **_monitoring** (30d) - InfluxDB system health metrics

## 🔐 Security

- ✅ Token-based authentication (no passwords)
- ✅ Pod Security Standards (restricted profile)
- ✅ TLS/HTTPS support via Ingress
- ✅ Network policies
- ✅ RBAC with minimal permissions
- ✅ Runs as non-root user
- ✅ Audit logging
- ✅ Compliance support (21 CFR Part 11, ISO 9001, IEC 62443)

See [docs/SECURITY.md](docs/SECURITY.md) for complete security guide.

## 📚 Documentation

- **[Full Documentation](docs/README.md)** - Comprehensive guide
- **[Security Guide](docs/SECURITY.md)** - Industrial security best practices
- **[Quick Reference](QUICK_REFERENCE.md)** - One-page cheat sheet
- **[Examples](examples/)** - 6 pre-built configurations

## 🛠️ PowerShell Scripts

### Manage InfluxDB
```powershell
# Deploy
.\scripts\manage-influxdb.ps1 -Action deploy -Organization "my-factory"

# Health check
.\scripts\manage-influxdb.ps1 -Action health-check

# Create bucket
.\scripts\manage-influxdb.ps1 -Action create-bucket -Bucket "maintenance" -Retention "365d"

# Backup
.\scripts\manage-influxdb.ps1 -Action backup
```

### Test InfluxDB
```powershell
# Run all tests
.\scripts\test-influxdb.ps1 -TestType all

# Performance test
.\scripts\test-influxdb.ps1 -TestType performance -Duration 60
```

### Generate Config
```powershell
# Factory configuration
.\scripts\generate-config.ps1 -Scenario factory -Organization "acme" -SensorCount 100

# SCADA with Telegraf
.\scripts\generate-config.ps1 -Scenario scada -IncludeTelegraf -TelegrafProtocols "opcua,modbus"
```

## 📋 Requirements

- **Kubernetes**: 1.24+ (tested on k3s, EKS, GKE, AKS)
- **Helm**: 3.0+
- **Persistent Storage**: StorageClass with dynamic provisioning
- **Optional**: Ingress controller, cert-manager, Prometheus Operator

## 🎯 Use Cases

- Factory floor sensor data collection
- SCADA system integration
- Production line monitoring (OEE, cycle times, downtime)
- Energy consumption tracking
- Quality control measurements
- Predictive maintenance analytics
- Edge deployment with unreliable connectivity
- Multi-plant data aggregation

## 🔧 Configuration Examples

### Minimal (Local Dev)
```yaml
deploymentMode: single
resourcePreset: edge
persistence:
  size: "5Gi"
```

### Production Factory
```yaml
deploymentMode: ha
resourcePreset: large
highAvailability:
  replicas: 3
backup:
  enabled: true
  schedule: "0 2 * * *"
ingress:
  enabled: true
  tls:
    - secretName: influxdb-tls
```

### Edge Gateway
```yaml
deploymentMode: single
resourcePreset: edge
edge:
  enabled: true
  remoteWrite:
    enabled: true
    url: "https://influxdb-central.factory.com"
```

## 📦 Installation

```bash
# From GitHub
git clone https://github.com/fireball-industries/influxdb-pod.git
cd influxdb-pod
helm install influxdb . --namespace influxdb --create-namespace

# With custom values
helm install influxdb . -f examples/factory-monitoring.yaml

# From Helm repository (when published)
helm repo add fireball https://charts.fireballindustries.com
helm install influxdb fireball/influxdb-pod
```

## 🔄 Upgrade

```bash
# Upgrade with new values
helm upgrade influxdb . -f values.yaml --namespace influxdb

# Rollback if needed
helm rollback influxdb --namespace influxdb
```

## 🗑️ Uninstall

```bash
# Uninstall release (PVCs are retained by default)
helm uninstall influxdb --namespace influxdb

# Delete PVCs if you want to remove data
kubectl delete pvc -n influxdb -l app.kubernetes.io/instance=influxdb
```

## 🤝 Contributing

Contributions welcome! Please submit pull requests or open issues on GitHub.

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

Copyright © 2026 Fireball Industries

---

## 🔥 About Fireball Industries

**"Ignite Your Factory Efficiency"™**

We build industrial-grade cloud-native tools for manufacturing and IIoT. Because factories deserve better than legacy software from the 1990s.

Founded by Patrick Ryan - sarcasm included at no extra charge.

- **Website**: https://fireballindustries.com
- **GitHub**: https://github.com/fireball-industries
- **Email**: support@fireballindustries.com

---

**Made with 🔥 and dark humor by Patrick Ryan**

*"If your time-series data is in Excel, we need to talk."*

---

## ⭐ Show Your Support

If this project saved you time (or sanity), give it a star on GitHub!

For commercial support, training, or custom deployments: support@fireballindustries.com
