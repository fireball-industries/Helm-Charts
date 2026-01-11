# InfluxDB Pod - Industrial Time-Series Database

**Fireball Industries** - *"Ignite Your Factory Efficiency"™*

> Because your factory's sensor data deserves better than a CSV file.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Helm Chart](https://img.shields.io/badge/Helm-v3.0+-blue.svg)](https://helm.sh)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.24+-326CE5.svg)](https://kubernetes.io)
[![InfluxDB](https://img.shields.io/badge/InfluxDB-2.7-22ADF6.svg)](https://www.influxdata.com/)

Production-ready Helm chart for deploying InfluxDB time-series databases in industrial Kubernetes environments. Optimized for factory automation, IIoT sensor data, SCADA integration, and manufacturing analytics.

## 🔥 Features

### Industrial-Grade Deployment
- **Deployment Modes**: Single-instance (edge/dev) and HA clustering (production)
- **Resource Presets**: Pre-configured for edge to enterprise (5 sensors to 1000+ sensors)
- **Pre-configured Buckets**: sensors, scada, production, energy, quality, monitoring
- **Data Retention**: Automatic downsampling (hot/warm/cold storage tiers)
- **Edge Support**: Remote write to central InfluxDB with local buffering

### Security First
- Token-based authentication (no passwords in 2026)
- Pod Security Standards (restricted profile)
- TLS/HTTPS support
- Network policies
- RBAC with minimal permissions
- Audit logging for compliance (21 CFR Part 11, ISO 9001)

### High Availability
- StatefulSet clustering with 3/5/7 replicas
- Pod anti-affinity for node distribution
- Pod disruption budgets
- Persistent storage with configurable storage classes
- Automated backups to S3/NFS/PVC

### Monitoring & Observability
- Prometheus metrics endpoint
- ServiceMonitor for Prometheus Operator
- Grafana datasource auto-configuration
- Health checks and probes
- Telegraf sidecar for sensor data collection (OPC UA, Modbus, MQTT)

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Deployment Modes](#deployment-modes)
- [Resource Sizing](#resource-sizing)
- [Industrial Buckets](#industrial-buckets)
- [Data Retention](#data-retention)
- [Security](#security)
- [Backup & Recovery](#backup--recovery)
- [Monitoring](#monitoring)
- [Edge Deployment](#edge-deployment)
- [Telegraf Integration](#telegraf-integration)
- [Troubleshooting](#troubleshooting)
- [Examples](#examples)

## ⚡ Quick Start

Deploy InfluxDB with sensible defaults in under 2 minutes:

```bash
# Add the Helm repository (when published)
helm repo add fireball https://charts.fireballindustries.com
helm repo update

# Install with default settings (medium preset, single mode)
helm install influxdb fireball/influxdb-pod \
  --set influxdb.organization=my-factory

# Or install from local chart
helm install influxdb ./influxdb-pod \
  --set influxdb.organization=my-factory
```

Access InfluxDB:

```bash
# Port-forward to access UI
kubectl port-forward svc/influxdb-influxdb-pod 8086:8086

# Get admin token
kubectl get secret influxdb-influxdb-pod-auth \
  -o jsonpath='{.data.admin-token}' | base64 --decode

# Open browser
open http://localhost:8086
```

Write your first sensor data:

```bash
influx write \
  --bucket sensors \
  --org my-factory \
  --token <YOUR_TOKEN> \
  --precision s \
  "temperature,sensor=TT01,line=assembly value=23.5"
```

**That's it!** You now have a production-grade time-series database running.

## 📦 Prerequisites

### Required
- **Kubernetes**: 1.24+ (tested on k3s, EKS, GKE, AKS)
- **Helm**: 3.0+
- **Persistent Storage**: StorageClass with dynamic provisioning (InfluxDB needs storage)

### Optional
- **Ingress Controller**: nginx, traefik (for external access)
- **Cert-Manager**: For automatic TLS certificates
- **Prometheus Operator**: For ServiceMonitor support
- **Grafana**: For data visualization

### Storage Requirements
InfluxDB **requires** persistent storage. Choose a StorageClass that provides:
- **Fast SSDs** for production (high IOPS for time-series workloads)
- **ReadWriteOnce** access mode
- **Dynamic provisioning** (or pre-create PVs)

Common storage classes:
- **k3s**: `local-path` (default)
- **AWS EKS**: `gp3` (recommended), `gp2`
- **GKE**: `standard-rwo`, `premium-rwo`
- **Azure AKS**: `managed-premium`, `managed`
- **Bare metal**: NFS, Ceph, Longhorn

## 🚀 Installation

### Method 1: Helm Install (Recommended)

```bash
# Default installation (medium preset, single mode)
helm install influxdb ./influxdb-pod \
  --namespace influxdb \
  --create-namespace \
  --set influxdb.organization=my-factory

# Production HA deployment (large factory)
helm install influxdb ./influxdb-pod \
  --namespace influxdb \
  --create-namespace \
  --set deploymentMode=ha \
  --set resourcePreset=large \
  --set influxdb.organization=acme-corp \
  --set persistence.storageClass=gp3

# Edge deployment (remote site with limited resources)
helm install influxdb-edge ./influxdb-pod \
  --namespace edge \
  --create-namespace \
  --set deploymentMode=single \
  --set resourcePreset=edge \
  --set edge.enabled=true \
  --set edge.remoteWrite.enabled=true \
  --set edge.remoteWrite.url=https://influxdb-central.factory.com
```

### Method 2: values.yaml Customization

Create a custom `values-prod.yaml`:

```yaml
deploymentMode: ha
resourcePreset: large

influxdb:
  organization: acme-manufacturing
  bucket: sensors
  retention: 90d

persistence:
  enabled: true
  storageClass: gp3
  size: 200Gi

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: influxdb.factory.acme.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: influxdb-tls
      hosts:
        - influxdb.factory.acme.com

backup:
  enabled: true
  schedule: "0 2 * * *"
  retention: 7
  destination:
    type: s3
    s3:
      bucket: acme-influxdb-backups
      region: us-east-1

monitoring:
  prometheus:
    enabled: true
  serviceMonitor:
    enabled: true
```

Install with custom values:

```bash
helm install influxdb ./influxdb-pod \
  -f values-prod.yaml \
  --namespace influxdb \
  --create-namespace
```

### Method 3: Rancher Apps & Marketplace

1. Navigate to **Apps & Marketplace** in Rancher UI
2. Search for **"InfluxDB Pod"**
3. Click **Install**
4. Configure via web form:
   - Deployment Mode: single or ha
   - Resource Preset: edge, small, medium, large, xlarge
   - Organization name
   - Storage settings
5. Click **Install**

## ⚙️ Configuration

### Key Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `deploymentMode` | Deployment strategy: `single` or `ha` | `single` |
| `resourcePreset` | Resource sizing: `edge`, `small`, `medium`, `large`, `xlarge`, `custom` | `medium` |
| `influxdb.organization` | InfluxDB organization name | `factory` |
| `influxdb.bucket` | Default bucket name | `sensors` |
| `influxdb.retention` | Default retention period | `90d` |
| `influxdb.adminToken` | Admin API token (auto-generated if empty) | `""` |
| `persistence.enabled` | Enable persistent storage (REQUIRED) | `true` |
| `persistence.storageClass` | Kubernetes StorageClass | `""` (cluster default) |
| `persistence.size` | Storage size (overridden by preset unless `custom`) | `50Gi` |
| `industrialBuckets.enabled` | Create pre-configured industrial buckets | `true` |
| `dataRetention.enabled` | Enable automatic downsampling | `true` |
| `backup.enabled` | Enable automated backups | `false` |
| `ingress.enabled` | Enable ingress for external access | `false` |
| `networkPolicy.enabled` | Enable network policies | `false` |

See [values.yaml](values.yaml) for all options (there are many, because industrial is complicated).

## 🏭 Deployment Modes

### Single Mode (Development, Testing, Edge)

Best for:
- Development and testing environments
- Edge locations with limited resources
- Non-critical monitoring systems
- Small factories (<10 sensors)

Features:
- Kubernetes Deployment (1 replica)
- Single PersistentVolumeClaim
- Lower resource requirements
- Faster startup
- Easier troubleshooting

```yaml
deploymentMode: single
resourcePreset: small
```

### HA Mode (Production Factories)

Best for:
- Production manufacturing environments
- Critical monitoring systems
- Large factories (>100 sensors)
- 99.9% uptime requirements

Features:
- Kubernetes StatefulSet (3/5/7 replicas)
- Per-pod PersistentVolumeClaims
- Pod anti-affinity (spread across nodes)
- Pod disruption budgets
- Clustering support (InfluxDB Enterprise features)

```yaml
deploymentMode: ha
resourcePreset: large

highAvailability:
  replicas: 3
  antiAffinity: soft
  podDisruptionBudget:
    enabled: true
    minAvailable: 2
```

**Note**: HA mode requires InfluxDB Enterprise features. For open-source InfluxDB, use single mode with backups and disaster recovery procedures.

## 📊 Resource Sizing

Choose a preset based on your sensor count and data velocity:

### Edge Preset
- **Sensors**: <5 sensors, remote sites
- **Write Rate**: <100 points/sec
- **Resources**: 256Mi RAM, 0.5 CPU, 5Gi storage
- **Use Case**: Single production line, edge gateway

```yaml
resourcePreset: edge
```

### Small Preset
- **Sensors**: <10 sensors
- **Write Rate**: <500 points/sec
- **Resources**: 512Mi RAM, 1 CPU, 10Gi storage
- **Use Case**: Small factory, pilot project

```yaml
resourcePreset: small
```

### Medium Preset (Default)
- **Sensors**: <100 sensors
- **Write Rate**: <2,000 points/sec
- **Resources**: 2Gi RAM, 2 CPU, 50Gi storage
- **Use Case**: Medium factory, multiple lines

```yaml
resourcePreset: medium
```

### Large Preset
- **Sensors**: <1,000 sensors
- **Write Rate**: <10,000 points/sec
- **Resources**: 8Gi RAM, 4 CPU, 200Gi storage
- **Use Case**: Large factory, plant-wide monitoring

```yaml
resourcePreset: large
```

### XLarge Preset
- **Sensors**: >1,000 sensors
- **Write Rate**: >10,000 points/sec
- **Resources**: 16Gi RAM, 8 CPU, 500Gi storage
- **Use Case**: Enterprise manufacturing, multi-plant

```yaml
resourcePreset: xlarge
```

### Custom Preset

Define your own resources:

```yaml
resourcePreset: custom

resources:
  limits:
    cpu: "6"
    memory: "12Gi"
  requests:
    cpu: "3"
    memory: "12Gi"

persistence:
  size: "300Gi"
```

### Sizing Calculator

**Formula**: Storage = Sensors × Points/sec × Retention × Bytes/point

Example: 100 sensors, 1 point/sec/sensor, 90-day retention
- Total points: 100 × 1 × (90×24×3600) = 777,600,000 points
- Storage (compressed): 777M × 3 bytes ≈ 2.3 GB
- Add 50% overhead: ~3.5 GB minimum
- Recommended: **50 GB** (medium preset) for growth

## 🪣 Industrial Buckets

Pre-configured buckets for manufacturing data:

### Default Buckets

| Bucket | Retention | Description |
|--------|-----------|-------------|
| `sensors` | 90d | Raw sensor data (temperature, pressure, flow, vibration) |
| `scada` | 365d | SCADA system metrics and alarms |
| `production` | 730d | Production metrics (OEE, cycle times, defects) |
| `energy` | 2555d (7y) | Energy consumption (compliance retention) |
| `quality` | 2555d (7y) | Quality measurements (21 CFR Part 11) |
| `_monitoring` | 30d | InfluxDB system health metrics |

### Customize Buckets

```yaml
industrialBuckets:
  enabled: true
  buckets:
    - name: "sensors"
      retention: "90d"
      description: "Factory floor sensor data"
    - name: "custom_bucket"
      retention: "365d"
      description: "Custom metrics for special equipment"
```

### Create Buckets Manually

```bash
influx bucket create \
  --name maintenance \
  --org my-factory \
  --retention 365d \
  --description "Predictive maintenance data" \
  --token <YOUR_TOKEN>
```

## ⏱️ Data Retention

Automatic downsampling to manage storage costs:

### Storage Tiers

- **Hot**: Full precision recent data (default: 7 days)
- **Warm**: 1-minute averages (default: 90 days)
- **Cold**: 1-hour averages (default: 2 years)

```yaml
dataRetention:
  enabled: true
  hot:
    duration: "7d"
  warm:
    duration: "90d"
    interval: "1m"
  cold:
    duration: "730d"
    interval: "1h"
```

### How It Works

1. Raw data written to `sensors` bucket
2. After 7 days, 1-minute averages written to `sensors_warm`
3. After 90 days, 1-hour averages written to `sensors_cold`
4. Original data deleted per retention policy

**Benefit**: Store 2 years of data in 10% of the space.

### Custom Downsampling

Create your own Flux tasks:

```flux
option task = {
  name: "downsample-temperature",
  every: 5m,
}

from(bucket: "sensors")
  |> range(start: -5m)
  |> filter(fn: (r) => r._measurement == "temperature")
  |> aggregateWindow(every: 1m, fn: mean)
  |> to(bucket: "sensors_warm", org: "my-factory")
```

## 🔐 Security

### Authentication

InfluxDB uses **token-based authentication**:

```bash
# Get admin token
kubectl get secret influxdb-influxdb-pod-auth \
  -n influxdb \
  -o jsonpath='{.data.admin-token}' | base64 --decode

# Create read-only token for Grafana
influx auth create \
  --org my-factory \
  --read-bucket sensors \
  --description "Grafana read-only" \
  --token <ADMIN_TOKEN>
```

### TLS/HTTPS

Enable TLS for production:

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  hosts:
    - host: influxdb.factory.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: influxdb-tls
      hosts:
        - influxdb.factory.com
```

### Network Policies

Restrict traffic to InfluxDB:

```yaml
networkPolicy:
  enabled: true
  ingress:
    - namespaceSelector:
        matchLabels:
          name: monitoring
    - namespaceSelector:
        matchLabels:
          name: grafana
```

### Pod Security

Runs with Pod Security Standard **restricted**:
- Non-root user (UID 1000)
- Read-only root filesystem (where possible)
- Drops all capabilities
- seccomp profile

### Compliance

For regulated industries:
- **21 CFR Part 11** (FDA): Enable audit logging, 7-year retention
- **ISO 9001**: Quality data retention (2-7 years)
- **IEC 62443**: Industrial security standards
- **GDPR**: Right to deletion (bucket-level)

See [SECURITY.md](SECURITY.md) for detailed security guide.

## 💾 Backup & Recovery

### Automated Backups

Enable scheduled backups:

```yaml
backup:
  enabled: true
  schedule: "0 2 * * *"  # 2 AM daily
  retention: 7  # Keep 7 backups
  destination:
    type: pvc
    pvc:
      size: "100Gi"
```

### Backup to S3

```yaml
backup:
  enabled: true
  destination:
    type: s3
    s3:
      bucket: my-influxdb-backups
      region: us-east-1
      accessKeySecret: aws-credentials
      secretKeySecret: aws-credentials
```

### Manual Backup

```bash
# Backup all data
influx backup /backup/influxdb-$(date +%Y%m%d) \
  --host http://influxdb:8086 \
  --token <YOUR_TOKEN>

# Backup specific bucket
influx backup /backup/sensors-$(date +%Y%m%d) \
  --bucket sensors \
  --host http://influxdb:8086 \
  --token <YOUR_TOKEN>
```

### Restore

```bash
# Restore from backup
influx restore /backup/influxdb-20260111 \
  --host http://influxdb:8086 \
  --token <YOUR_TOKEN>
```

## 📈 Monitoring

### Prometheus Integration

Enable metrics:

```yaml
monitoring:
  prometheus:
    enabled: true
    port: 9122
  serviceMonitor:
    enabled: true
    interval: 30s
```

Key metrics:
- `influxdb_buckets_total` - Number of buckets
- `influxdb_database_write_count` - Write operations
- `influxdb_database_query_count` - Query operations
- `influxdb_storage_disk_bytes` - Disk usage

### Grafana Dashboards

Auto-configure Grafana datasource:

```yaml
grafana:
  datasource:
    enabled: true
    namespace: monitoring
```

Import pre-built dashboards:
- InfluxDB 2.x Metrics (ID: 12619)
- System Stats (ID: 928)

## 🌐 Edge Deployment

Deploy InfluxDB at edge locations with remote write:

```yaml
deploymentMode: single
resourcePreset: edge

edge:
  enabled: true
  remoteWrite:
    enabled: true
    url: https://influxdb-central.factory.com
    organization: acme-corp
    bucket: edge-data
    tokenSecret: edge-token
  localBuffer:
    enabled: true
    maxSize: "5Gi"
```

Features:
- Local data collection during network outages
- Automatic sync when connectivity restored
- Compressed remote write
- Retry with exponential backoff

## 📡 Telegraf Integration

Collect sensor data with Telegraf sidecar:

```yaml
telegraf:
  enabled: true
  config: |
    [agent]
      interval = "10s"
    
    [[outputs.influxdb_v2]]
      urls = ["http://localhost:8086"]
      token = "$INFLUX_TOKEN"
      organization = "$INFLUX_ORG"
      bucket = "sensors"
    
    # MQTT input for sensor data
    [[inputs.mqtt_consumer]]
      servers = ["tcp://mqtt-broker:1883"]
      topics = ["factory/sensors/#"]
      data_format = "json"
    
    # Modbus input for PLCs
    [[inputs.modbus]]
      name = "plc01"
      slave_id = 1
      controller = "tcp://10.0.1.50:502"
      holding_registers = [
        {name = "temperature", byte_order = "AB", data_type = "FLOAT32", scale=1.0, address = [0,1]},
      ]
```

See [examples/scada-integration.yaml](examples/scada-integration.yaml) for complete configuration.

## 🔧 Troubleshooting

### Pod Not Starting

```bash
# Check pod status
kubectl get pods -n influxdb -l app.kubernetes.io/name=influxdb-pod

# View events
kubectl describe pod -n influxdb <pod-name>

# Check logs
kubectl logs -n influxdb <pod-name> --tail=100
```

Common issues:
- **PVC pending**: No StorageClass or PV available
- **Image pull error**: Check image name and credentials
- **CrashLoopBackOff**: Check resource limits, disk space

### Cannot Connect to InfluxDB

```bash
# Test from within cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://influxdb-influxdb-pod:8086/health

# Port-forward for local testing
kubectl port-forward svc/influxdb-influxdb-pod 8086:8086
curl http://localhost:8086/health
```

### High Memory Usage

InfluxDB caches data in memory for performance. If memory usage is high:

```yaml
influxdb:
  storage:
    cacheMaxMemorySize: "512m"  # Reduce cache size
  query:
    concurrency: 5  # Limit concurrent queries
```

### Slow Queries

```bash
# Check query performance
influx task list --org my-factory

# Analyze query
influx query --org my-factory 'from(bucket: "sensors") |> range(start: -1h) |> yield()'
```

Optimizations:
- Add indexes on frequently queried tags
- Use downsampled data for historical queries
- Limit query time range
- Increase query concurrency

### Disk Full

```bash
# Check disk usage
kubectl exec -n influxdb <pod-name> -- df -h

# Check bucket sizes
influx bucket list --org my-factory
```

Solutions:
- Reduce retention periods
- Enable downsampling
- Increase PVC size
- Delete old buckets

## 📚 Examples

See [examples/](examples/) directory:

- [minimal-influxdb.yaml](examples/minimal-influxdb.yaml) - Lightweight dev/test
- [factory-monitoring.yaml](examples/factory-monitoring.yaml) - Complete factory setup
- [ha-influxdb.yaml](examples/ha-influxdb.yaml) - Production HA deployment
- [edge-gateway.yaml](examples/edge-gateway.yaml) - Edge with remote write
- [scada-integration.yaml](examples/scada-integration.yaml) - SCADA monitoring
- [energy-monitoring.yaml](examples/energy-monitoring.yaml) - Energy tracking

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test your changes
4. Submit a pull request

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

Copyright © 2026 Fireball Industries

---

## 🔥 About Fireball Industries

**"Ignite Your Factory Efficiency"™**

We build industrial-grade cloud-native tools for manufacturing and IIoT. Because factories deserve better than legacy software from the 1990s.

Founded by Patrick Ryan (sarcasm included at no extra charge).

- Website: https://fireballindustries.com
- GitHub: https://github.com/fireball-industries
- Support: support@fireballindustries.com

---

**Made with 🔥 and dark humor by Patrick Ryan**

*"If your time-series data is in Excel, we need to talk."*
