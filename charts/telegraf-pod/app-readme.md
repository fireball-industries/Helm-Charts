# Telegraf Pod - Metrics Collection

**Fireball Industries** - *"We Play With Fire So You Don't Have To"™*

> Production-ready Telegraf metrics collection for Kubernetes. Because somebody has to collect all those metrics before they disappear into the void.

---

## 🔥 Overview

Comprehensive Helm chart for deploying Telegraf in Kubernetes environments. Pre-configured with sensible defaults that actually work in production, complete with 87% more snark than competing solutions.

**Perfect for:**
- 📊 System metrics collection (CPU, memory, disk, network)
- 🐳 Docker container monitoring
- ☸️ Kubernetes cluster observability
- 📈 Custom application metrics
- 🔌 Multi-protocol metric ingestion (StatsD, HTTP, SNMP)
- 📡 Remote endpoint monitoring
- 🎯 Time-series data forwarding to InfluxDB/Prometheus

---

## ✨ Key Features

### Deployment Flexibility
- **Deployment Mode**: Single centralized collector for APIs/remote endpoints
- **DaemonSet Mode**: Per-node collection for comprehensive host metrics
- **Resource Presets**: small/medium/large for different collection frequencies

### Collection Capabilities
- **200+ Input Plugins**: System, Docker, Kubernetes, HTTP, SNMP, MQTT, and more
- **50+ Output Plugins**: InfluxDB, Prometheus, Kafka, file, and more
- **Pre-configured defaults**: Works out-of-the-box for Kubernetes monitoring

### Security & Reliability
- 🔒 Non-root execution (UID 999)
- 🛡️ Read-only root filesystem
- 🔐 All capabilities dropped
- 🌐 RBAC with minimal permissions
- 💾 Persistent buffering during output failures
- ⚖️ Pod Disruption Budget for HA

### Integration Ready
- **InfluxDB**: v1 and v2 support with auto-retry
- **Prometheus**: Metrics exposition endpoint
- **Kubernetes**: Full service discovery and inventory
- **Docker**: Container stats without breaking things

---

## 🚀 Quick Start

### Minimal Deployment
```bash
helm install telegraf fireball/telegraf-pod \
  --namespace telegraf \
  --create-namespace
```

### Full Kubernetes Monitoring (DaemonSet)
```bash
helm install telegraf fireball/telegraf-pod \
  --set deploymentMode=daemonset \
  --set hostNetwork=true \
  --set hostVolumes.enabled=true \
  --set rbac.clusterRole=true \
  --namespace telegraf \
  --create-namespace
```

### With InfluxDB Output
```bash
helm install telegraf fireball/telegraf-pod \
  --set config.outputs.influxdb_v2.enabled=true \
  --set config.outputs.influxdb_v2.urls[0]=http://influxdb:8086 \
  --set config.outputs.influxdb_v2.token=your-token-here \
  --namespace telegraf \
  --create-namespace
```

### Access Metrics
```bash
# Port-forward to Prometheus endpoint
kubectl port-forward -n telegraf svc/telegraf 8080:8080

# View metrics
http://localhost:8080/metrics
```

---

## 📊 Resource Presets

| Preset | Interval | Memory | CPU | Buffer | Use Case |
|--------|----------|--------|-----|--------|----------|
| **small** | 60s | 64Mi | 50m | 1K | Low-frequency polling |
| **medium** | 10s | 128Mi | 100m | 10K | Standard collection ✅ |
| **large** | 1s | 256Mi | 250m | 100K | High-frequency monitoring |
| **custom** | Custom | Custom | Custom | Custom | You know better |

---

## 🎯 Deployment Modes

### Deployment Mode (Single Instance)
- Single pod collecting from remote endpoints
- Lower resource usage
- Perfect for: API polling, SNMP, HTTP checks, aggregated metrics

### DaemonSet Mode (Per-Node)
- One pod per node in the cluster
- Complete host-level visibility
- Perfect for: Node metrics, Docker stats, system monitoring

---

## 🔍 Pre-Configured Inputs

### System Metrics
✅ **CPU** - Per-core and total usage  
✅ **Memory** - Usage, buffers, cache  
✅ **Disk** - Usage and I/O statistics  
✅ **Network** - Interface traffic and errors  
✅ **Processes** - Count and states  
✅ **System** - Load average, uptime  

### Container Metrics
✅ **Docker** - Container stats (requires Docker socket access)  
✅ **Kubernetes** - Kubelet metrics from each node  
✅ **kube_inventory** - Cluster-level inventory (pods, deployments, services)

### Meta-Monitoring
✅ **Internal** - Telegraf's own performance metrics

---

## 🎨 Output Plugins

### InfluxDB v2
Send metrics to InfluxDB Cloud or OSS v2:
```yaml
config:
  outputs:
    influxdb_v2:
      enabled: true
      urls: ["http://influxdb:8086"]
      token: "${INFLUX_TOKEN}"
      organization: "fireball"
      bucket: "telegraf"
```

### InfluxDB v1 (Legacy)
For older InfluxDB deployments:
```yaml
config:
  outputs:
    influxdb_v1:
      enabled: true
      urls: ["http://influxdb:8086"]
      database: "telegraf"
      username: "${INFLUX_USER}"
      password: "${INFLUX_PASSWORD}"
```

### Prometheus
Expose metrics for Prometheus scraping:
```yaml
config:
  outputs:
    prometheus_client:
      enabled: true
      listen: ":8080"
      path: "/metrics"
```

### File Output
For debugging or backup:
```yaml
config:
  outputs:
    file:
      enabled: true
      files: ["/var/lib/telegraf/metrics.out"]
```

---

## 🔐 Security Features

✅ Pod Security Standards compliance  
✅ Non-root user (UID 999)  
✅ Read-only root filesystem  
✅ All capabilities dropped  
✅ Seccomp profile: RuntimeDefault  
✅ RBAC with minimal permissions (read-only Kubernetes access)  
✅ Network policies (optional)  
✅ Secret management via environment variables  

---

## 🛠️ Configuration Options

### Collection Settings
- **interval**: How often to collect metrics (1s, 10s, 60s)
- **flush_interval**: How often to send to outputs
- **metric_buffer_limit**: Max metrics before dropping

### RBAC Configuration
- **rbac.create**: Create ServiceAccount and roles
- **rbac.clusterRole**: Cluster-wide or namespace-scoped access

### Host Access
- **hostNetwork**: Use host network stack
- **hostVolumes.enabled**: Mount host paths (Docker socket, /proc, /sys)

### Storage
- **persistence.enabled**: Buffer metrics during output failures
- **persistence.size**: Buffer storage size (default: 1Gi)

---

## 📦 What's Included

- **12 Kubernetes Templates**: Deployment, DaemonSet, ConfigMap, RBAC, Service, PVC, NetworkPolicy
- **6 Example Configurations**: Kubernetes monitoring, Docker, custom apps, HA, minimal
- **3 PowerShell Scripts**: Deployment management, metric testing, config generation
- **Comprehensive Documentation**: Full guide, security best practices, quick reference

---

## 🎨 Example Configurations

Pre-built examples in `examples/` directory:

### Full Kubernetes Monitoring
```bash
helm install telegraf fireball/telegraf-pod \
  -f examples/kubernetes-full-monitoring.yaml
```

### Docker Host Monitoring
```bash
helm install telegraf fireball/telegraf-pod \
  -f examples/docker-monitoring.yaml
```

### Custom Application Metrics
```bash
helm install telegraf fireball/telegraf-pod \
  -f examples/custom-app-monitoring.yaml
```

### High Availability Setup
```bash
helm install telegraf fireball/telegraf-pod \
  -f examples/high-availability.yaml
```

### Minimal Setup
```bash
helm install telegraf fireball/telegraf-pod \
  -f examples/minimal-monitoring.yaml
```

---

## 📋 Requirements

- **Kubernetes**: 1.24+ (tested on k3s, k8s, RKE2)
- **Helm**: 3.0+
- **Resources**: Minimum 64Mi RAM, 50m CPU per pod
- **Optional**: Docker socket access for container metrics
- **Optional**: Cluster-wide RBAC for Kubernetes inventory metrics

---

## 🔧 Post-Installation

After installation completes:

1. **Verify pods are running**:
   ```bash
   kubectl get pods -n telegraf
   ```

2. **Check metrics collection**:
   ```bash
   kubectl logs -n telegraf -l app.kubernetes.io/name=telegraf
   ```

3. **Test Prometheus endpoint**:
   ```bash
   kubectl port-forward -n telegraf svc/telegraf 8080:8080
   curl http://localhost:8080/metrics
   ```

4. **Verify output connectivity**:
   Check logs for successful metric writes to InfluxDB/Prometheus

---

## 📊 Monitoring Telegraf

Self-monitoring enabled by default:

```yaml
config:
  inputs:
    internal:
      enabled: true
      collect_memstats: true
```

Metrics include:
- Collection duration
- Output write latency
- Buffer usage
- Memory stats

Expose via Prometheus:
```yaml
serviceMonitor:
  enabled: true
```

---

## 🔄 Upgrade & Rollback

```bash
# Upgrade
helm upgrade telegraf fireball/telegraf-pod \
  --reuse-values \
  --set resourcePreset=large \
  --namespace telegraf

# Rollback
helm rollback telegraf --namespace telegraf
```

---

## 🗑️ Uninstall

```bash
# Uninstall (PVCs retained by default)
helm uninstall telegraf --namespace telegraf

# Delete PVCs
kubectl delete pvc -n telegraf -l app.kubernetes.io/instance=telegraf
```

---

## 🛡️ Production Checklist

Before going to production:

- ✅ Choose appropriate deployment mode (Deployment vs DaemonSet)
- ✅ Set resource preset based on collection frequency
- ✅ Configure outputs (InfluxDB/Prometheus/both)
- ✅ Store secrets in Kubernetes Secrets, not values.yaml
- ✅ Enable persistence for metric buffering
- ✅ Configure RBAC appropriately (cluster vs namespace scope)
- ✅ Test output connectivity before deploying
- ✅ Enable ServiceMonitor for self-monitoring
- ✅ Review and tune buffer limits
- ✅ Set up alerts for collection failures

---

## 🤝 Integration Examples

### With InfluxDB Pod
```bash
# Install InfluxDB first
helm install influxdb fireball/influxdb-pod -n monitoring

# Install Telegraf with InfluxDB output
helm install telegraf fireball/telegraf-pod \
  --set config.outputs.influxdb_v2.enabled=true \
  --set config.outputs.influxdb_v2.urls[0]=http://influxdb.monitoring:8086 \
  -n telegraf
```

### With Prometheus Pod
```bash
# Install Prometheus first
helm install prometheus fireball/prometheus-pod -n monitoring

# Install Telegraf (Prometheus will auto-discover via ServiceMonitor)
helm install telegraf fireball/telegraf-pod \
  --set serviceMonitor.enabled=true \
  -n telegraf
```

---

## 🔍 Troubleshooting

### Pod won't start
```bash
kubectl describe pod -n telegraf <pod-name>
kubectl logs -n telegraf <pod-name>
```

Common issues:
- Image pull failures (check network/registry)
- OOMKilled (increase resource preset)
- CrashLoopBackOff (check config syntax)

### No metrics collected
```bash
# Test configuration
kubectl exec -n telegraf deployment/telegraf -- \
  telegraf --test --config /etc/telegraf/telegraf.conf

# Check RBAC for Kubernetes metrics
kubectl auth can-i get pods --as=system:serviceaccount:telegraf:telegraf
```

### Output connection failures
Check logs for errors:
```bash
kubectl logs -n telegraf -l app.kubernetes.io/name=telegraf | grep -i error
```

Verify secret values are set correctly in environment variables.

---

## 📚 Documentation

- **[Complete Guide](docs/README.md)** - 100+ page comprehensive guide
- **[Security Guide](docs/SECURITY.md)** - Best practices and compliance
- **[Quick Reference](QUICK_REFERENCE.md)** - One-page cheat sheet
- **[Examples](examples/)** - 6 pre-built configurations

---

## 🔥 About Fireball Industries

**"We Play With Fire So You Don't Have To"™**

We're a team of infrastructure engineers who've seen things. Terrible things. Things that wake us up at 3 AM. We build tools to prevent you from experiencing the same horrors.

- Security-hardened by default
- Production-tested configurations
- Comprehensive documentation
- Automation-first approach
- Dark millennial humor included at no extra charge

Founded by Patrick Ryan - professional chaos engineer and metric hoarder.

- **Website**: https://fireballindustries.com
- **GitHub**: https://github.com/fireball-industries
- **Email**: support@fireball.industries

---

## 📄 License

MIT License (Make It Terrible) - Copyright © 2026 Fireball Industries

---

**Made with 🔥 and excessive amounts of caffeine**

*"Now with 87% more snark than competing solutions"*

---

**Start collecting metrics in < 5 minutes. Seriously.**

```bash
helm install telegraf fireball/telegraf-pod --namespace telegraf --create-namespace
```

That's it. You're done. Go get coffee. ☕
