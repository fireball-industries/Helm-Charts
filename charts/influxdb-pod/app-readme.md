# InfluxDB Pod - Industrial Time-Series Database

**Fireball Industries** - *"Ignite Your Factory Efficiency"™*

---

## What This App Does

InfluxDB Pod is a production-ready, industrial-grade time-series database deployment optimized for factory automation, IIoT data collection, and manufacturing environments. 

**Perfect for collecting data from:**
- 🏭 Factory floor sensors and PLCs
- 📊 SCADA systems and HMIs
- ⚡ Energy monitoring equipment
- 🔧 Predictive maintenance sensors
- 📈 Quality control measurements
- 🌡️ Environmental monitoring

---

## Why Choose InfluxDB Pod?

### 🚀 Deploy in Seconds
Pre-configured for industrial use cases with sensible defaults. Choose your deployment size based on sensor count and go.

### 🔒 Production-Ready Security
- Token-based authentication
- Optional TLS/HTTPS
- Network policies
- RBAC integration
- Audit logging

### 📈 Scales With Your Factory
Resource presets from edge gateways (5 sensors) to enterprise plants (1000+ sensors):
- **Edge**: 256Mi RAM, 5Gi storage
- **Small**: 512Mi RAM, 10Gi storage  
- **Medium**: 2Gi RAM, 50Gi storage
- **Large**: 8Gi RAM, 200Gi storage
- **XLarge**: 16Gi RAM, 500Gi storage

### 🏗️ High Availability Mode
Deploy 3+ replicas with StatefulSet clustering for zero-downtime data collection. Because production lines don't stop for database restarts.

### 🔌 Industrial Protocol Ready
Integrates seamlessly with:
- Telegraf (OPC UA, Modbus, MQTT)
- Grafana dashboards
- SCADA systems
- Edge gateways

---

## Quick Start

### 1️⃣ **Basic Deployment (Single Instance)**
For development, testing, or edge locations:
```yaml
Organization: your-factory-name
Deployment Mode: single
Resource Preset: medium
Enable Persistence: true
```

### 2️⃣ **Production Deployment (High Availability)**
For critical production environments:
```yaml
Organization: your-factory-name
Deployment Mode: ha
Replicas: 3
Resource Preset: large
Enable Persistence: true
Enable Backups: true
```

### 3️⃣ **Edge Gateway Deployment**
For remote sites with limited resources:
```yaml
Organization: your-factory-name
Deployment Mode: single
Resource Preset: edge
Enable Persistence: true
```

---

## Pre-Configured Industrial Buckets

When you enable **Industrial Buckets**, the following data repositories are automatically created:

| Bucket | Purpose | Default Retention |
|--------|---------|------------------|
| `sensors` | Raw sensor data from PLCs, temperature, pressure, flow meters | 90 days |
| `scada` | SCADA system data, alarms, events | 90 days |
| `production` | Production metrics, cycle times, throughput, OEE | 90 days |
| `energy` | Power consumption, energy monitoring | 90 days |
| `quality` | Quality control measurements, defect rates | 90 days |
| `downsampled` | Aggregated historical data for long-term trends | 3 years |

---

## Configuration Highlights

### 🎯 **Deployment Mode**
- **Single**: One replica, perfect for dev/test/edge
- **HA**: 3+ replicas with clustering for production

### 💾 **Persistent Storage**
**REQUIRED** for production use. Configure:
- Storage class (leave default or specify)
- Size (controlled by resource preset)
- Access mode (ReadWriteOnce for most use cases)

### 🌐 **Network Access**
- **ClusterIP**: Internal access only (default)
- **NodePort**: Direct access via node IP
- **LoadBalancer**: External load balancer
- **Ingress**: HTTP/HTTPS with custom domain

### 🔐 **Security Options**
- Auto-generated admin tokens and passwords
- Pod Security Policies
- Network Policies for traffic control
- RBAC service accounts
- TLS/HTTPS support

### 📊 **Monitoring Integration**
- Prometheus ServiceMonitor
- Grafana datasource auto-configuration
- Built-in metrics endpoints

---

## After Deployment

### Access InfluxDB UI
1. Get your admin token:
   ```bash
   kubectl get secret influxdb-auth -n <namespace> -o jsonpath='{.data.admin-token}' | base64 -d
   ```

2. Port-forward to access locally:
   ```bash
   kubectl port-forward svc/influxdb 8086:8086 -n <namespace>
   ```

3. Open browser: `http://localhost:8086`

### Connect Telegraf Agents
Configure Telegraf with the service endpoint:
```toml
[[outputs.influxdb_v2]]
  urls = ["http://influxdb:8086"]
  token = "$INFLUX_TOKEN"
  organization = "your-factory-name"
  bucket = "sensors"
```

### Create Grafana Dashboards
Use the InfluxDB datasource with Flux queries to visualize your factory data in real-time.

---

## Resource Requirements

Minimum recommended resources by deployment size:

| Preset | Sensors | CPU | Memory | Storage | Use Case |
|--------|---------|-----|--------|---------|----------|
| Edge | <5 | 0.5 | 256Mi | 5Gi | Remote sites, edge gateways |
| Small | <10 | 1 | 512Mi | 10Gi | Small factories, pilot projects |
| Medium | <100 | 2 | 2Gi | 50Gi | Standard factory floor |
| Large | <1000 | 4 | 8Gi | 200Gi | Large manufacturing plants |
| XLarge | >1000 | 8 | 16Gi | 500Gi | Enterprise multi-site deployments |

---

## Support & Documentation

- **GitHub**: https://github.com/fireball-industries/influxdb-pod
- **Documentation**: See the `docs/` folder in the chart
- **Examples**: Check `examples/` for real-world configurations
- **InfluxDB Docs**: https://docs.influxdata.com/influxdb/v2/

---

## About Fireball Industries

We build industrial automation solutions that actually work. Because factory downtime is expensive, and Excel spreadsheets weren't meant for 10,000 data points per second.

**"Ignite Your Factory Efficiency"™**

---

*Version 1.0.0 | InfluxDB 2.7 | Kubernetes 1.24+*
