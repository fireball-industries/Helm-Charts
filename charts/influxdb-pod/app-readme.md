# InfluxDB Pod - Industrial Time-Series Database

**Fireball Industries** - *"Ignite Your Factory Efficiency"™*

> Industrial-grade InfluxDB time-series database for Kubernetes. Because your factory's sensor data deserves better than an Excel spreadsheet.

---

## 🔥 Overview

Production-ready Helm chart for deploying InfluxDB in industrial Kubernetes environments. Optimized for factory automation, IIoT sensor data, SCADA integration, and manufacturing analytics.

**Perfect for:**
- 🏭 Factory floor sensor data collection
- 📊 SCADA system integration  
- ⚙️ Production line monitoring (OEE, cycle times, downtime)
- ⚡ Energy consumption tracking
- 🔬 Quality control measurements
- 🔧 Predictive maintenance analytics
- 🌐 Edge deployment with unreliable connectivity
- 🏢 Multi-plant data aggregation

---

## ✨ Key Features

### Industrial-Ready
- **Pre-configured Buckets**: sensors, SCADA, production, energy, quality
- **Data Retention**: Automatic downsampling (hot/warm/cold storage tiers)
- **Compliance Support**: 21 CFR Part 11, ISO 9001, IEC 62443

### Deployment Flexibility
- **Single Mode**: Development, testing, edge locations
- **HA Mode**: Production clustering with 3/5/7 replicas
- **Resource Presets**: Edge to enterprise (5 sensors to 1000+ sensors)

### Security & Reliability
- 🔒 Token-based authentication (no passwords)
- 🛡️ Pod Security Standards (restricted profile)
- 🔐 TLS/HTTPS support via Ingress
- 🌐 Network policies for traffic control
- ⚖️ RBAC with minimal permissions
- 🔄 Automated backups to S3/NFS/PVC

### Edge Support
- 📡 Remote write to central InfluxDB
- 💾 Local buffering during network outages
- 🔌 Perfect for unreliable factory floor connectivity

### Integration Ready
- **Telegraf**: OPC UA, Modbus, MQTT, SNMP collectors included
- **Grafana**: Auto-datasource configuration
- **Prometheus**: ServiceMonitor for metrics scraping

---

## 🚀 Quick Start

### Minimal Deployment
```bash
helm install influxdb fireball/influxdb-pod \
  --set influxdb.organization=my-factory \
  --namespace influxdb \
  --create-namespace
```

### Production Factory
```bash
helm install influxdb fireball/influxdb-pod \
  --set deploymentMode=ha \
  --set resourcePreset=large \
  --set highAvailability.replicas=3 \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=influxdb.factory.com \
  --namespace influxdb \
  --create-namespace
```

### Edge Gateway
```bash
helm install influxdb-edge fireball/influxdb-pod \
  --set resourcePreset=edge \
  --set edge.enabled=true \
  --set edge.remoteWrite.enabled=true \
  --set edge.remoteWrite.url=https://influxdb-central.factory.com \
  --namespace influxdb \
  --create-namespace
```

---

## 📊 Resource Presets

| Preset | Sensors | Write Rate | Memory | CPU | Storage | Use Case |
|--------|---------|------------|--------|-----|---------|----------|
| **edge** | <5 | <100 pts/sec | 256Mi | 0.5 | 5Gi | Remote sites |
| **small** | <10 | <500 pts/sec | 512Mi | 1 | 10Gi | Small factory |
| **medium** | <100 | <2K pts/sec | 2Gi | 2 | 50Gi | Medium factory ✅ |
| **large** | <1K | <10K pts/sec | 8Gi | 4 | 200Gi | Large factory |
| **xlarge** | >1K | >10K pts/sec | 16Gi | 8 | 500Gi | Enterprise plant |
| **custom** | - | - | Custom | Custom | Custom | You know better |

---

## 🪣 Industrial Buckets

Pre-configured for manufacturing data:

| Bucket | Retention | Purpose |
|--------|-----------|---------|
| **sensors** | 90 days | Raw sensor data (temp, pressure, flow, vibration) |
| **scada** | 365 days | SCADA metrics and alarms |
| **production** | 730 days | Production line metrics (OEE, cycle times, defects) |
| **energy** | 7 years | Energy consumption (compliance) |
| **quality** | 7 years | Quality measurements (21 CFR Part 11) |
| **_monitoring** | 30 days | InfluxDB system health |

---

## 🔐 Security Features

✅ Token-based authentication  
✅ Pod Security Standards (restricted)  
✅ TLS/HTTPS via Ingress  
✅ Network policies  
✅ RBAC with minimal permissions  
✅ Non-root user execution  
✅ Audit logging  
✅ Compliance support (FDA 21 CFR Part 11, ISO 9001, IEC 62443)

---

## 🛠️ Configuration Options

### Deployment Modes
- **Single**: One replica, for dev/test/edge (Deployment)
- **HA**: 3/5/7 replicas with clustering (StatefulSet)

### Data Management
- **Hot Storage**: Full precision recent data (default: 7 days)
- **Warm Storage**: 1-minute averages (default: 90 days)
- **Cold Storage**: 1-hour averages (default: 730 days)

### Backup Destinations
- **PVC**: Simple cluster storage
- **S3**: AWS or S3-compatible (MinIO)
- **NFS**: Network file system

### Service Types
- **ClusterIP**: Internal only (default)
- **LoadBalancer**: External IP address
- **NodePort**: Static port on nodes (30000-32767)

---

## 📦 What's Included

- **15 Kubernetes Templates**: Deployment, StatefulSet, Services, Ingress, RBAC, NetworkPolicy, Backups
- **6 Example Configurations**: Factory, HA, Edge, SCADA, Energy, Minimal
- **3 PowerShell Scripts**: Management, testing, config generation
- **Comprehensive Documentation**: Full guide, security best practices, quick reference

---

## 📋 Requirements

- **Kubernetes**: 1.24+ (tested on k3s, EKS, GKE, AKS)
- **Helm**: 3.0+
- **Persistent Storage**: StorageClass with dynamic provisioning
- **Optional**: Ingress controller, cert-manager, Prometheus Operator

---

## 🎯 Use Cases

### Factory Monitoring
Collect real-time sensor data from production lines, track OEE metrics, monitor equipment health, and detect anomalies before failures occur.

### SCADA Integration
Centralize SCADA data from multiple systems, maintain long-term compliance records, and enable advanced analytics on historical process data.

### Energy Management
Track energy consumption across facilities, identify optimization opportunities, meet regulatory reporting requirements, and reduce operational costs.

### Quality Control
Store quality measurements for regulatory compliance (21 CFR Part 11), maintain statistical process control data, and perform root cause analysis.

### Edge Computing
Deploy at remote factory locations with local buffering, sync to central database when connectivity available, and ensure zero data loss.

---

## 🔧 Post-Installation

After installation completes:

1. **Get Admin Token**:
   ```bash
   kubectl get secret influxdb-influxdb-pod-auth -n influxdb \
     -o jsonpath='{.data.admin-token}' | base64 --decode
   ```

2. **Access UI** (if using LoadBalancer/NodePort):
   ```bash
   # Get service URL
   kubectl get svc influxdb-influxdb-pod -n influxdb
   
   # Or port-forward
   kubectl port-forward -n influxdb svc/influxdb-influxdb-pod 8086:8086
   ```

3. **Open Browser**: http://localhost:8086 (or external IP)

4. **Login**: Use admin token from step 1

---

## 📊 Monitoring

Enable Prometheus metrics:
```yaml
monitoring:
  prometheus:
    enabled: true
  serviceMonitor:
    enabled: true  # Requires Prometheus Operator
```

Metrics exposed on port 9122:
- Query performance
- Write throughput  
- Storage usage
- Cardinality stats

---

## 🤝 Grafana Integration

Auto-create InfluxDB datasource in Grafana:
```yaml
grafana:
  datasource:
    enabled: true
    namespace: monitoring
```

Or manually add datasource:
- **URL**: `http://influxdb-influxdb-pod.influxdb.svc.cluster.local:8086`
- **Organization**: Your organization name
- **Token**: Admin token from secret
- **Default Bucket**: sensors

---

## 🔄 Upgrade & Rollback

```bash
# Upgrade
helm upgrade influxdb fireball/influxdb-pod \
  --reuse-values \
  --set influxdb.logLevel=debug \
  --namespace influxdb

# Rollback
helm rollback influxdb --namespace influxdb
```

---

## 🗑️ Uninstall

```bash
# Uninstall (PVCs retained by default)
helm uninstall influxdb --namespace influxdb

# Delete PVCs (PERMANENT DATA LOSS)
kubectl delete pvc -n influxdb -l app.kubernetes.io/instance=influxdb
```

---

## 🔥 About Fireball Industries

**"Ignite Your Factory Efficiency"™**

We build industrial-grade cloud-native tools for manufacturing and IIoT. Because factories deserve better than legacy software from the 1990s.

Founded by Patrick Ryan - sarcasm included at no extra charge.

- **Website**: https://fireballindustries.com
- **GitHub**: https://github.com/fireball-industries
- **Email**: support@fireballindustries.com

---

## 📄 License

MIT License - Copyright © 2026 Fireball Industries

---

**Made with 🔥 and dark humor by Patrick Ryan**

*"If your time-series data is in Excel, we need to talk."*
