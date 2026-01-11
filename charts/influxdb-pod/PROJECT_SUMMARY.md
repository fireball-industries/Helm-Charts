# InfluxDB Pod - Project Summary

**Fireball Industries** - *"Ignite Your Factory Efficiency"™*

## 📦 Project Overview

Production-ready Helm chart for deploying InfluxDB time-series databases in industrial Kubernetes environments. Optimized for factory automation, IIoT sensor data, SCADA integration, and manufacturing analytics.

**Version**: 1.0.0  
**App Version**: InfluxDB 2.7  
**License**: MIT  
**Author**: Patrick Ryan, Fireball Industries  

## 🎯 Target Audience

- Factory IT/OT teams
- Industrial automation engineers
- Manufacturing data engineers
- SCADA/MES system integrators
- IIoT platform developers

## ✨ Key Features

### Industrial-Grade Deployment
- **Deployment Modes**: Single-instance and HA clustering
- **Resource Presets**: 5 pre-configured sizes (edge to enterprise)
- **Industrial Buckets**: Pre-configured for sensors, SCADA, production, energy, quality
- **Data Retention**: Automatic downsampling with hot/warm/cold tiers
- **Edge Support**: Remote write to central InfluxDB with local buffering

### Security
- Token-based authentication (no passwords)
- Pod Security Standards (restricted profile)
- TLS/HTTPS support
- Network policies
- RBAC with minimal permissions
- Compliance support (21 CFR Part 11, ISO 9001, IEC 62443)

### High Availability
- StatefulSet clustering (3/5/7 replicas)
- Pod anti-affinity for node distribution
- Pod disruption budgets
- Persistent storage with configurable storage classes
- Automated backups to S3/NFS/PVC

### Observability
- Prometheus metrics endpoint
- ServiceMonitor for Prometheus Operator
- Grafana datasource auto-configuration
- Health checks and probes
- Comprehensive logging

## 📂 Project Structure

```
influxdb-pod/
├── Chart.yaml                      # Helm chart metadata
├── values.yaml                     # Default configuration (comprehensive)
├── LICENSE                         # MIT License
├── NOTES.txt                       # Installation banner
├── .gitignore                      # Git exclusions
├── .helmignore                     # Helm package exclusions
├── README.md                       # Project overview
├── QUICK_REFERENCE.md              # One-page cheat sheet
├── PROJECT_SUMMARY.md              # This file
│
├── templates/                      # Kubernetes manifests (15 files)
│   ├── _helpers.tpl                # Template helpers
│   ├── serviceaccount.yaml         # ServiceAccount
│   ├── rbac.yaml                   # RBAC roles/bindings
│   ├── configmap.yaml              # InfluxDB configuration
│   ├── secret.yaml                 # Initial admin token
│   ├── deployment.yaml             # Single-instance deployment
│   ├── statefulset.yaml            # HA clustering deployment
│   ├── pvc.yaml                    # Persistent storage (single mode)
│   ├── service.yaml                # ClusterIP + headless services
│   ├── ingress.yaml                # Ingress for external access
│   ├── networkpolicy.yaml          # Network policies
│   ├── backup-cronjob.yaml         # Automated backup job
│   ├── poddisruptionbudget.yaml    # PDB for HA
│   ├── servicemonitor.yaml         # Prometheus ServiceMonitor
│   └── NOTES.txt                   # Post-install instructions
│
├── docs/                           # Documentation
│   ├── README.md                   # Comprehensive documentation
│   └── SECURITY.md                 # Security guide
│
├── examples/                       # Example configurations (6 files)
│   ├── minimal-influxdb.yaml       # Minimal dev/test setup
│   ├── factory-monitoring.yaml     # Complete factory monitoring
│   ├── ha-influxdb.yaml            # HA production deployment
│   ├── edge-gateway.yaml           # Edge with remote write
│   ├── scada-integration.yaml      # SCADA system monitoring
│   └── energy-monitoring.yaml      # Energy consumption tracking
│
└── scripts/                        # PowerShell automation (3 files)
    ├── manage-influxdb.ps1         # Deployment & management
    ├── test-influxdb.ps1           # Comprehensive testing
    └── generate-config.ps1         # Configuration generator
```

## 📊 File Count Summary

- **Total Files**: 35
- **Templates**: 15 Kubernetes manifests
- **Documentation**: 4 files
- **Examples**: 6 pre-built configurations
- **Scripts**: 3 PowerShell automation scripts
- **Chart Files**: 7 core Helm files

## 🔧 Deployment Modes

### Single Mode
- **Type**: Kubernetes Deployment
- **Replicas**: 1
- **Storage**: Single PVC
- **Use Case**: Dev, test, edge locations

### HA Mode
- **Type**: Kubernetes StatefulSet
- **Replicas**: 3, 5, or 7 (configurable)
- **Storage**: Per-pod PVCs
- **Use Case**: Production factories, critical monitoring

## 📊 Resource Presets

| Preset | RAM | CPU | Storage | Sensors | Write Rate |
|--------|-----|-----|---------|---------|------------|
| edge | 256Mi | 0.5 | 5Gi | <5 | <100 pts/sec |
| small | 512Mi | 1 | 10Gi | <10 | <500 pts/sec |
| medium | 2Gi | 2 | 50Gi | <100 | <2K pts/sec |
| large | 8Gi | 4 | 200Gi | <1K | <10K pts/sec |
| xlarge | 16Gi | 8 | 500Gi | >1K | >10K pts/sec |

## 🪣 Industrial Buckets

Pre-configured data buckets:

1. **sensors** (90d) - Raw sensor data (temperature, pressure, flow, vibration)
2. **scada** (365d) - SCADA system metrics and alarms
3. **production** (730d) - Production metrics (OEE, cycle times, defects)
4. **energy** (2555d/7y) - Energy consumption (compliance retention)
5. **quality** (2555d/7y) - Quality control (21 CFR Part 11)
6. **_monitoring** (30d) - InfluxDB system health

## 🔐 Security Features

- Token-based authentication (no passwords)
- Pod Security Standards (restricted)
- TLS/HTTPS via Ingress
- Network policies (Kubernetes NetworkPolicy)
- RBAC with minimal permissions
- Non-root user (UID 1000)
- Read-only root filesystem (where possible)
- seccomp profile
- Capability dropping
- Audit logging

## 🛠️ PowerShell Scripts

### manage-influxdb.ps1
**Actions**: deploy, upgrade, delete, health-check, validate, backup, restore, query, status, tune, create-bucket, create-token, list-buckets, rotate-tokens

**Usage**:
```powershell
.\scripts\manage-influxdb.ps1 -Action deploy -Organization "my-factory"
```

### test-influxdb.ps1
**Tests**: all, api, writes, queries, retention, clustering, backup-restore, performance

**Usage**:
```powershell
.\scripts\test-influxdb.ps1 -TestType all
```

### generate-config.ps1
**Scenarios**: factory, scada, energy, edge, custom

**Usage**:
```powershell
.\scripts\generate-config.ps1 -Scenario factory -SensorCount 100 -IncludeTelegraf
```

## 📚 Documentation

### docs/README.md
Comprehensive documentation covering:
- Quick start
- Installation methods
- Configuration options
- Deployment modes
- Resource sizing
- Industrial buckets
- Data retention
- Security
- Backup & recovery
- Monitoring
- Edge deployment
- Telegraf integration
- Troubleshooting
- Examples

### docs/SECURITY.md
Complete security guide covering:
- Threat model for industrial environments
- Authentication & authorization
- Network security (OT/IT convergence)
- Encryption (TLS, at-rest)
- Pod security
- Secrets management (Vault, AWS Secrets Manager)
- Compliance (21 CFR Part 11, ISO 9001, IEC 62443, GDPR)
- Audit logging
- Incident response
- Security checklist

## 🎓 Use Cases

1. **Factory Floor Monitoring**: 50-100 sensors, production line data
2. **SCADA Integration**: OPC UA, Modbus TCP data collection
3. **Energy Monitoring**: Power meters, ISO 50001 compliance
4. **Edge Deployment**: Remote sites with unreliable connectivity
5. **Quality Control**: 21 CFR Part 11 compliant data retention
6. **Predictive Maintenance**: Vibration analysis, runtime hours

## 🚀 Quick Start

```bash
# 1. Clone repository
git clone https://github.com/fireball-industries/influxdb-pod.git
cd influxdb-pod

# 2. Deploy with defaults
helm install influxdb . \
  --set influxdb.organization=my-factory \
  --namespace influxdb \
  --create-namespace

# 3. Get admin token
kubectl get secret influxdb-influxdb-pod-auth -n influxdb \
  -o jsonpath='{.data.admin-token}' | base64 --decode

# 4. Access UI
kubectl port-forward -n influxdb svc/influxdb-influxdb-pod 8086:8086
# Open: http://localhost:8086
```

## 🔄 Upgrade Path

```bash
# Upgrade to new version
helm upgrade influxdb . -f values.yaml --namespace influxdb

# Rollback if needed
helm rollback influxdb --namespace influxdb
```

## 🧪 Testing

Comprehensive test suite included:
- API health checks
- Write performance tests
- Query tests (Flux)
- Bucket operations
- Backup/restore validation
- Performance benchmarking

## 📈 Success Metrics

- ✅ Deploy in <2 minutes with defaults
- ✅ Security-hardened (Pod Security Standards restricted)
- ✅ Comprehensive documentation
- ✅ Production-ready configurations
- ✅ Full PowerShell automation
- ✅ 6 example configurations
- ✅ Industrial-specific features

## 🤝 Contributing

Contributions welcome! Submit pull requests or open issues on GitHub.

## 📄 License

MIT License

Copyright © 2026 Fireball Industries

## 📞 Support

- **GitHub**: https://github.com/fireball-industries/influxdb-pod
- **Issues**: https://github.com/fireball-industries/influxdb-pod/issues
- **Email**: support@fireballindustries.com
- **Website**: https://fireballindustries.com

## 🏆 Credits

**Author**: Patrick Ryan  
**Company**: Fireball Industries  
**Tagline**: *"Ignite Your Factory Efficiency"™*  
**Motto**: *"Because your factory's data deserves better than an Excel spreadsheet."*

---

## 📦 Deliverables Summary

✅ **Helm Chart Structure**: Chart.yaml, values.yaml, .gitignore, .helmignore, LICENSE, NOTES.txt  
✅ **Kubernetes Templates (15)**: Deployment, StatefulSet, Services, Ingress, RBAC, NetworkPolicy, Backup CronJob, PDB, ServiceMonitor  
✅ **Documentation**: Comprehensive README.md, SECURITY.md  
✅ **Examples (6)**: Minimal, Factory, HA, Edge, SCADA, Energy configurations  
✅ **PowerShell Scripts (3)**: Manage, Test, Generate-Config automation  
✅ **Supporting Files**: Project README, Quick Reference, Project Summary  

**Total Lines of Code**: ~7,500+  
**Configuration Options**: 100+ in values.yaml  
**Industrial Features**: Fully implemented  
**Patrick Ryan Sarcasm Level**: Maximum 🔥  

---

**Fireball Industries** - *Making Industrial IoT Less Painful Since 2026*

*"If your time-series data is in Excel, we need to talk."* - Patrick Ryan
