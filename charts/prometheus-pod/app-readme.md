# Prometheus Pod - Production-Grade Monitoring

**Fireball Industries** - *"We Play With Fire So You Don't Have To"™*

> Production-ready Prometheus monitoring for Kubernetes. Because your apps won't monitor themselves.

---

## 🔥 Overview

Comprehensive Helm chart for deploying Prometheus in Kubernetes environments. Pre-configured with sensible defaults, Kubernetes service discovery, alerting rules, and security hardening.

**Perfect for:**
- 📊 Kubernetes cluster monitoring
- 🎯 Application metrics collection
- 🔔 Alert rule management
- 📈 Time-series data analysis
- 🔍 Troubleshooting and debugging
- 📉 Capacity planning
- 🌐 Multi-cluster federation
- ☁️ Long-term storage with Thanos

---

## ✨ Key Features

### Core Capabilities
- **Prometheus 2.49.0** (latest stable, alpine-based)
- **Kubernetes-native service discovery** (API, nodes, pods, services, cAdvisor)
- **Pre-configured scrape configs** for complete cluster monitoring
- **Alert rules included** for common failure scenarios
- **RBAC configured** with minimal cluster-wide read-only permissions

### Deployment Flexibility
- **Single Mode**: One replica for dev/test/small clusters (Deployment)
- **HA Mode**: 2+ replicas with query deduplication (StatefulSet + Thanos)
- **Resource Presets**: small/medium/large/xlarge for easy sizing
- **Persistent storage** with time and size-based retention

### Security & Reliability
- 🔒 Non-root user (UID 65534)
- 🛡️ Read-only root filesystem
- 🔐 All capabilities dropped
- 🔒 Pod Security Standards (Restricted level compliance)
- 🌐 Network policies for traffic control
- ⚖️ Pod Disruption Budget for HA deployments

### Integration Ready
- **Thanos**: HA query deduplication + object storage for long-term retention
- **Remote Write**: Forward to Cortex, VictoriaMetrics, etc.
- **Prometheus Operator**: ServiceMonitor for self-monitoring
- **Grafana**: Ready for datasource configuration

---

## 🚀 Quick Start

### Minimal Deployment
```bash
helm install prometheus fireball/prometheus-pod \
  --namespace monitoring \
  --create-namespace
```

### Production HA Deployment
```bash
helm install prometheus fireball/prometheus-pod \
  --set deploymentMode=ha \
  --set replicaCount=3 \
  --set resourcePreset=large \
  --set thanos.enabled=true \
  --namespace monitoring \
  --create-namespace
```

### Access Prometheus UI
```bash
# Port-forward
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# Open browser
http://localhost:9090
```

---

## 📊 Resource Presets

| Preset | Targets | Memory | CPU | Storage | Retention | Use Case |
|--------|---------|--------|-----|---------|-----------|----------|
| **small** | 1-5 | 512Mi | 1 core | 10Gi | 7d | Dev/test |
| **medium** | 5-50 | 2Gi | 2 cores | 20Gi | 15d | Small prod ✅ |
| **large** | 50-500 | 8Gi | 4 cores | 50Gi | 30d | Medium prod |
| **xlarge** | 500+ | 16Gi | 8 cores | 100Gi | 60d | Enterprise |
| **custom** | - | Custom | Custom | Custom | Custom | You know better |

---

## 🎯 Deployment Modes

### Single Mode (Development/Testing)
- Single Deployment with 1 replica
- One PersistentVolumeClaim
- Lower resource requirements
- Perfect for dev/test environments

### HA Mode (Production)
- StatefulSet with 2+ replicas
- Per-replica PVCs
- Anti-affinity to spread across nodes
- Pod Disruption Budget
- Thanos sidecar for query deduplication
- Recommended: 3 replicas + Thanos

---

## 🔍 Pre-Configured Monitoring

### Kubernetes Service Discovery
Automatically discovers and monitors:
- ✅ **Kubernetes API servers** - Control plane health
- ✅ **Nodes** - kubelet metrics (CPU, memory, disk, network)
- ✅ **Pods** - Auto-discover with `prometheus.io/scrape: "true"` annotation
- ✅ **Service Endpoints** - Service-level metrics
- ✅ **cAdvisor** - Container metrics (CPU, memory per container)

### Alert Rules
Pre-configured alerts for:
- 🚨 **Node issues**: Node down, high CPU/memory, disk pressure
- 🔴 **Pod issues**: Crash loops, frequent restarts, OOMKilled events
- 💾 **Storage issues**: Disk space running low
- 📊 **Prometheus meta-alerts**: Scrape failures, TSDB issues, high cardinality

---

## 🪣 Data Retention

Configure retention by time and size:

```yaml
retention:
  time: 15d        # Keep 15 days of data
  size: 16GB       # Max TSDB size (~80% of PVC size)
```

**Retention Strategies:**
- **Dev/Test**: 7d retention, 10Gi storage
- **Small Prod**: 15d retention, 20Gi storage
- **Medium Prod**: 30d retention, 50Gi storage
- **Enterprise**: 60d+ retention with Thanos long-term storage

---

## 🔐 Security Features

✅ Pod Security Standards compliance (Restricted)  
✅ Non-root user (UID 65534)  
✅ Read-only root filesystem  
✅ All capabilities dropped  
✅ Seccomp profile: RuntimeDefault  
✅ RBAC with minimal permissions (cluster-wide read-only)  
✅ Network policies (optional)  
✅ TLS via Ingress  

---

## 🛠️ Configuration Options

### Scrape Configuration
- **scrapeInterval**: How often to scrape (default: 1m)
- **scrapeTimeout**: Timeout per scrape (default: 10s)
- **evaluationInterval**: Alert rule evaluation (default: 1m)

### Storage
- **persistence.size**: PVC size (default: 20Gi)
- **persistence.storageClass**: Storage class (default: cluster default)
- **retention.time**: Time-based retention (default: 15d)
- **retention.size**: Size-based retention (default: 16GB)

### Service Types
- **ClusterIP**: Internal only (default)
- **LoadBalancer**: External IP address
- **NodePort**: Static port on nodes (30090)

---

## 📦 What's Included

- **14 Kubernetes Templates**: Deployment, StatefulSet, Services, Ingress, RBAC, ConfigMaps, NetworkPolicy
- **6 Example Configurations**: Minimal, HA, Federated, Kubernetes monitoring, App monitoring, Thanos
- **3 PowerShell Scripts**: Deployment management, testing, config generation
- **Comprehensive Documentation**: 100+ page user guide, security hardening guide, quick reference

---

## 🌐 Thanos Integration

Enable for HA and long-term storage:

```yaml
thanos:
  enabled: true
  objectStorageConfig:
    secretName: thanos-objstore-config
```

**Benefits:**
- Query deduplication across replicas
- Long-term storage to S3/GCS/Azure
- Cheaper than giant PVCs
- Global query view across clusters

---

## 📋 Requirements

- **Kubernetes**: 1.24+ (tested on k3s, k8s, RKE2)
- **Helm**: 3.0+
- **Persistent Storage**: PersistentVolume support (StorageClass with dynamic provisioning)
- **Resources**: Minimum 512Mi RAM, 1 CPU core, 10Gi storage
- **Permissions**: Cluster-wide read access for Kubernetes service discovery

---

## 🎨 Example Configurations

Pre-built examples in `examples/` directory:

### Full Kubernetes Monitoring
```bash
helm install prometheus fireball/prometheus-pod \
  -f examples/kubernetes-full-monitoring.yaml
```

### High Availability Production
```bash
helm install prometheus fireball/prometheus-pod \
  -f examples/ha-prometheus.yaml
```

### Minimal Dev/Test
```bash
helm install prometheus fireball/prometheus-pod \
  -f examples/minimal-prometheus.yaml
```

### Federated Multi-Cluster
```bash
helm install prometheus fireball/prometheus-pod \
  -f examples/federated-prometheus.yaml
```

### Application Monitoring
```bash
helm install prometheus fireball/prometheus-pod \
  -f examples/app-monitoring.yaml
```

### Long-term Storage (Thanos)
```bash
helm install prometheus fireball/prometheus-pod \
  -f examples/thanos-enabled.yaml
```

---

## 🔧 Post-Installation

After installation completes:

1. **Access Prometheus UI**:
   ```bash
   kubectl port-forward -n monitoring svc/prometheus 9090:9090
   ```
   Open: http://localhost:9090

2. **Check targets**:
   Navigate to Status → Targets to see discovered scrape targets

3. **Verify alerts**:
   Navigate to Alerts to see configured alert rules

4. **Query metrics**:
   Try queries like `up`, `node_cpu_seconds_total`, `container_memory_usage_bytes`

5. **Connect Grafana**:
   - URL: `http://prometheus.monitoring.svc.cluster.local:9090`
   - Type: Prometheus
   - Access: Server (default)

---

## 📊 Monitoring Prometheus

Self-monitoring enabled by default:

```yaml
serviceMonitor:
  enabled: true
```

Metrics exposed include:
- Scrape performance
- Query latency
- TSDB size and compaction
- WAL operations
- Rule evaluation time
- Memory usage

---

## 🔄 Upgrade & Rollback

```bash
# Upgrade
helm upgrade prometheus fireball/prometheus-pod \
  --reuse-values \
  --set resourcePreset=large \
  --namespace monitoring

# Rollback
helm rollback prometheus --namespace monitoring
```

---

## 🗑️ Uninstall

```bash
# Uninstall (PVCs retained by default)
helm uninstall prometheus --namespace monitoring

# Delete PVCs (PERMANENT DATA LOSS)
kubectl delete pvc -n monitoring -l app.kubernetes.io/instance=prometheus
```

---

## 🛡️ Production Checklist

Before going to production:

- ✅ Set `deploymentMode: ha` with 3+ replicas
- ✅ Use `resourcePreset: large` or `xlarge`
- ✅ Configure retention based on compliance needs
- ✅ Enable Thanos for long-term storage
- ✅ Set up Alertmanager for alert routing
- ✅ Configure Ingress with TLS + authentication
- ✅ Enable network policies
- ✅ Set `prometheus.externalLabels.cluster` for federation
- ✅ Test backup/restore procedures
- ✅ Configure anti-affinity for replica spread

---

## 🤝 Grafana Integration

Add Prometheus as Grafana datasource:

**Manual Configuration:**
- URL: `http://prometheus.monitoring.svc.cluster.local:9090`
- Type: Prometheus
- Access: Server (default)
- Scrape interval: 1m (or your configured value)

**Recommended Dashboards:**
- 1860: Node Exporter Full
- 315: Kubernetes cluster monitoring
- 7249: Kubernetes cluster (Prometheus)
- 3662: Prometheus 2.0 Overview

---

## 📚 Documentation

- **[Complete User Guide](docs/README.md)** - 100+ page comprehensive guide
- **[Security Guide](docs/SECURITY.md)** - Hardening and compliance
- **[Quick Reference](QUICK_REFERENCE.md)** - One-page cheat sheet
- **[Examples](examples/)** - 6 pre-built configurations

---

## 🔥 About Fireball Industries

**"We Play With Fire So You Don't Have To"™**

We specialize in production-ready Kubernetes solutions with personality. Our POD PRODUCTS are designed for Rancher Apps & Marketplace, providing enterprise-grade monitoring with minimal friction.

- Security-hardened by default
- Production-tested configurations
- Comprehensive documentation
- Automation-first approach
- Dark millennial humor included at no extra charge

Founded by Patrick Ryan - sarcasm level approved.

- **Website**: https://fireballindustries.com
- **GitHub**: https://github.com/fireball-industries
- **Email**: support@fireballindustries.com

---

## 📄 License

MIT License - Copyright © 2026 Fireball Industries

---

**Made with 🔥 and dark humor by Fireball Industries**

*"If your monitoring isn't monitoring itself, are you even monitoring?"*
