# Fireball Node Exporter - Hardware Monitoring

**Production-ready Prometheus Node Exporter for comprehensive node-level monitoring.**

Optimized for industrial edge computing where knowing your hardware is dying BEFORE it catches fire is surprisingly useful.

---

## 🔥 What is Prometheus Node Exporter?

**Prometheus Node Exporter** exposes hardware and OS-level metrics from Linux/Unix nodes:

- **CPU Metrics** - Usage, frequency scaling, temperature, thermal throttling
- **Memory Metrics** - Total, available, buffers, cache, swap
- **Disk Metrics** - I/O statistics, latency, read/write bytes, SMART health
- **Network Metrics** - Bytes sent/received, errors, drops, interface status
- **Filesystem Metrics** - Disk usage, inodes, mount points
- **Temperature Monitoring** - CPU/GPU sensors via hwmon and thermal zones
- **System Metrics** - Load average, processes, context switches, interrupts

**Perfect for:** Industrial edge computing, Raspberry Pi monitoring, server fleet management, hardware failure prediction.

---

## 📊 Resource Presets

Choose a preset based on your hardware and monitoring needs:

| Preset | CPU | RAM | Collectors | Use Case |
|--------|-----|-----|------------|----------|
| **edge-minimal** | 50m / 100m | 30Mi / 50Mi | 10 basic | Raspberry Pi, constrained IoT |
| **edge-standard** | 100m / 200m | 50Mi / 100Mi | 13 standard | Industrial PCs **(default)** |
| **server** | 200m / 500m | 100Mi / 200Mi | 16 full | Servers, VMs, full monitoring |

**Recommendation:**
- Use **edge-minimal** for ultra-constrained devices (Raspberry Pi Zero, IoT gateways)
- Choose **edge-standard** for most industrial edge deployments (recommended)
- Select **server** for comprehensive server/VM monitoring with all collectors

---

## 🚀 Quick Start

### DaemonSet Deployment (Recommended)
Deploy Node Exporter on every node in the cluster:

```bash
helm upgrade --install node-exporter fireball-industries/node-exporter-pod \
  --namespace monitoring \
  --create-namespace \
  --set resourcePreset=edge-standard \
  --set serviceMonitor.enabled=true
```

**Access metrics:**
```bash
# Port-forward to any pod
kubectl port-forward -n monitoring daemonset/node-exporter 9100:9100

# View metrics
curl http://localhost:9100/metrics
```

---

### Deployment Mode (Testing)
Single instance for testing or monitoring one specific node:

```bash
helm upgrade --install node-exporter fireball-industries/node-exporter-pod \
  --namespace monitoring \
  --create-namespace \
  --set deploymentMode=deployment \
  --set replicaCount=1
```

---

## 🎯 Deployment Modes

### DaemonSet (Default - Recommended)
Runs **one pod per node** in the cluster:

**Benefits:**
- Complete cluster visibility (all nodes monitored)
- Automatic scaling (new nodes get monitoring pods)
- Node-specific metrics (per-node CPU, disk, temperature)

**Use when:**
- ✅ Running production Kubernetes/K3s cluster
- ✅ Want metrics from every node
- ✅ Need hardware failure detection across fleet

**Configuration:**
```yaml
deploymentMode: daemonset
```

---

### Deployment
Single instance or multi-replica deployment:

**Benefits:**
- Lower resource usage (one pod total)
- Good for testing configuration
- Useful for single-node clusters

**Use when:**
- ✅ Testing Node Exporter configuration
- ✅ Single-node Kubernetes setup
- ✅ Want to monitor just the control plane

**Configuration:**
```yaml
deploymentMode: deployment
replicaCount: 1
```

---

### StatefulSet
Persistent identity deployment (rarely needed):

**Use when:**
- ✅ Need stable network identity for pods
- ✅ Persistent storage required (uncommon for Node Exporter)

---

## 📡 Collectors Explained

### Always-Enabled Collectors (13)

These collectors are enabled in all presets for essential monitoring:

**CPU & Processor:**
- **cpu** - CPU time per core (user, system, idle, iowait)
- **cpufreq** - CPU frequency scaling (current/min/max MHz)
- **stat** - Context switches, interrupts, CPU states

**Memory:**
- **meminfo** - Total, available, free, buffers, cached, swap
- **vmstat** - Virtual memory statistics, paging, swapping

**Disk & Filesystem:**
- **diskstats** - Disk I/O operations, read/write bytes, latency
- **filesystem** - Mount point usage, free space, inodes

**Network:**
- **netdev** - Network interface bytes, packets, errors, drops
- **netstat** - TCP/UDP connection states

**System:**
- **loadavg** - 1/5/15 minute load averages
- **time** - System time and timezone
- **uname** - OS version, kernel, architecture

**Hardware:**
- **hwmon** - Temperature sensors, fan speeds, voltage (from /sys/class/hwmon)

---

### Optional Collectors

Enable based on monitoring requirements:

**Systemd (Recommended for production):**
```yaml
collectors:
  optional:
    systemd: true
```
- Monitor systemd service states (active, failed, dead)
- Track unit restarts and failures
- Useful for tracking kubelet, containerd, k3s services

---

**Processes (Debugging):**
```yaml
collectors:
  optional:
    processes: true
```
- Process states: running, sleeping, stopped, zombie
- Useful for detecting zombie processes or runaway applications

---

**Textfile Collector (Highly Recommended):**
```yaml
collectors:
  optional:
    textfile: true
    textfile:
      directory: "/var/lib/node_exporter/textfile_collector"
```
- Import custom metrics from script-generated `.prom` files
- **Use cases:**
  - Backup status monitoring (`backup_last_success_timestamp`)
  - Hardware RAID health (`raid_health_status`)
  - License expiry tracking (`license_expiry_days`)
  - SMART disk health (`disk_smart_health`)

See [textfile-examples/](textfile-examples/) in chart for scripts.

---

**Thermal Zone (Critical for Edge):**
```yaml
collectors:
  optional:
    thermal_zone: true
```
- Monitor CPU/GPU thermal zones from `/sys/class/thermal`
- Alternative to hwmon for temperature monitoring
- **Critical for edge deployments** - detect overheating before damage

---

**NTP (Time Synchronization):**
```yaml
collectors:
  optional:
    ntp: true
```
- Monitor NTP synchronization status
- Track clock drift and offset
- Important for distributed systems and compliance

---

**TCP Stat (Network Troubleshooting):**
```yaml
collectors:
  optional:
    tcpstat: true
```
- TCP connection states (ESTABLISHED, TIME_WAIT, CLOSE_WAIT)
- Detect connection leaks and socket exhaustion

---

**Ethtool (Advanced Network):**
```yaml
collectors:
  optional:
    ethtool: true  # ⚠️ Requires elevated permissions
```
- NIC statistics and link status
- Duplex mode, speed, auto-negotiation
- **Warning:** Requires CAP_NET_ADMIN capability

---

**WiFi (Wireless Monitoring):**
```yaml
collectors:
  optional:
    wifi: true
```
- WiFi signal strength, bitrate, frequency
- Access point information
- Useful for wireless edge devices

---

**RAPL (Power Monitoring):**
```yaml
collectors:
  optional:
    rapl: true  # Intel CPUs only
```
- Intel Running Average Power Limit monitoring
- Package/core/DRAM power consumption
- Energy usage tracking

---

## 🌡️ Temperature Monitoring

### Why Temperature Matters
Industrial edge devices (Raspberry Pi, NUCs, industrial PCs) run in harsh environments:
- **Dusty factories** - Poor ventilation
- **Outdoor enclosures** - Direct sunlight, extreme temperatures
- **Sealed cabinets** - Heat buildup
- **24/7 operation** - No cooling downtime

**Thermal throttling degrades performance. Hardware failure costs money.**

---

### Enable Temperature Monitoring

**hwmon collector (default):**
```yaml
collectors:
  enabled:
    - hwmon  # Enabled in edge-standard and server presets
```

Exposes metrics:
- `node_hwmon_temp_celsius` - Temperature in Celsius
- `node_hwmon_temp_max` - Maximum temperature threshold
- `node_hwmon_temp_crit` - Critical temperature threshold

**thermal_zone collector (alternative):**
```yaml
collectors:
  optional:
    thermal_zone: true
```

Exposes metrics:
- `node_thermal_zone_temp` - Thermal zone temperature
- `node_cooling_device_cur_state` - Fan/cooling state

---

### Temperature Alert Examples

**Prometheus alert rules:**
```yaml
- alert: HighTemperature
  expr: node_hwmon_temp_celsius > 70
  for: 5m
  annotations:
    summary: "Node {{ $labels.instance }} temperature is {{ $value }}°C"

- alert: CriticalTemperature
  expr: node_hwmon_temp_celsius > 80
  for: 1m
  annotations:
    summary: "⚠️ CRITICAL: {{ $labels.instance }} at {{ $value }}°C"
```

**Typical temperature thresholds:**
- **< 60°C** - Normal operation
- **60-70°C** - Warm (monitor)
- **70-80°C** - Hot (warning, check cooling)
- **80-85°C** - Critical (throttling begins)
- **> 85°C** - Danger (potential hardware damage)

---

## 📈 Prometheus Integration

### ServiceMonitor (Prometheus Operator)
Automatic service discovery for Prometheus:

```yaml
serviceMonitor:
  enabled: true
  interval: 30s
  scrapeTimeout: 10s
  labels:
    prometheus: kube-prometheus
```

**How it works:**
1. ServiceMonitor is created with label `prometheus: kube-prometheus`
2. Prometheus Operator discovers ServiceMonitor
3. Prometheus automatically scrapes all Node Exporter pods
4. No manual Prometheus configuration needed

---

### Manual Prometheus Configuration
If not using Prometheus Operator:

```yaml
scrape_configs:
  - job_name: 'kubernetes-node-exporter'
    kubernetes_sd_configs:
      - role: endpoints
        namespaces:
          names:
            - monitoring
    relabel_configs:
      - source_labels: [__meta_kubernetes_service_name]
        action: keep
        regex: node-exporter
      - source_labels: [__meta_kubernetes_endpoint_node_name]
        target_label: instance
```

---

## 🚨 Alert Rules

### Pre-Configured Alerts (30+)
Four PrometheusRule files with comprehensive alerting:

**Hardware Alerts** (`alerts/alerts-hardware.yaml`):
- HighCPUUsage (>80% for 5m)
- CriticalCPUUsage (>95% for 2m)
- HighMemoryUsage (>80% for 5m)
- CriticalMemoryUsage (>90% for 2m)
- HighDiskIOLatency (>100ms)
- NetworkInterfaceErrors
- HighNetworkErrors (>1%)

**Temperature Alerts** (`alerts/alerts-temperature.yaml`):
- HighTemperature (>70°C warning)
- CriticalTemperature (>80°C critical)
- ThermalThrottling (>85°C)
- FanFailure

**Filesystem Alerts** (`alerts/alerts-filesystem.yaml`):
- DiskSpaceWarning (>80%)
- DiskSpaceCritical (>90%)
- DiskWillFillIn4Hours (predictive)
- DiskWillFillIn24Hours (predictive)
- DiskAlmostFull (>95%)
- InodesWarning (>80%)
- InodesCritical (>90%)
- FilesystemReadOnly

**System Alerts** (`alerts/alerts-system.yaml`):
- ClockSkewDetected (>1s drift)
- ClockSkewCritical (>30s drift)
- HighContextSwitches
- ZombieProcesses
- OOMKillerActive
- SwapUsageHigh (>80%)
- NodeNotReady
- NodeRebooted

---

### Deploy Alert Rules

**Enable in Helm chart:**
```yaml
prometheusRule:
  enabled: true
  hardwareAlerts: true
  temperatureAlerts: true
  filesystemAlerts: true
  systemAlerts: true
```

**Or deploy manually:**
```bash
kubectl apply -f alerts/ -n monitoring
```

---

## 📊 Grafana Dashboards

### 4 Pre-Built Dashboards

**1. Node Exporter Full** (`dashboards/node-exporter-full.json`)
- Comprehensive overview of all node metrics
- CPU, memory, disk, network, temperature
- Multi-node view with drill-down
- Best for: Server monitoring, cluster health

**2. Industrial Edge** (`dashboards/industrial-edge.json`)
- Edge-focused with temperature emphasis
- Raspberry Pi and industrial PC optimized
- Temperature alerts, disk wear tracking
- Best for: Factory edge deployments

**3. Cluster Overview** (`dashboards/cluster-overview.json`)
- Fleet health at a glance
- Aggregated metrics across all nodes
- Top-N views (hottest nodes, highest CPU, lowest disk)
- Best for: Multi-node cluster monitoring

**4. Hardware Health** (`dashboards/hardware-health.json`)
- Temperature sensors, disk health, network errors
- SMART disk monitoring integration
- I/O latency and throughput
- Best for: Hardware failure prediction

---

### Import Dashboards

**Via Grafana UI:**
1. Dashboards → Import
2. Upload JSON file from `dashboards/` directory
3. Select Prometheus datasource
4. Save

**Via Kubernetes ConfigMap:**
```bash
kubectl create configmap grafana-dashboard-node-exporter \
  --from-file=dashboards/node-exporter-full.json \
  -n monitoring

kubectl label configmap grafana-dashboard-node-exporter \
  grafana_dashboard=1 -n monitoring
```

**Via Helm (Grafana sidecar):**
```yaml
grafanaDashboards:
  enabled: true
  folder: "Node Monitoring"
```

---

## 🔒 Security Hardening

### RBAC (Cluster Access)
Node Exporter requires cluster-level permissions to read node metrics:

**Created resources:**
- ServiceAccount (`node-exporter`)
- ClusterRole (`node-exporter`)
- ClusterRoleBinding (`node-exporter`)

**Permissions:**
- Read-only access to node metrics
- No write permissions
- No secret access

**Configuration:**
```yaml
rbac:
  create: true  # Required for node metrics
  pspEnabled: false  # Deprecated in K8s 1.25+
```

---

### Pod Security Context
Run as non-root with minimal privileges:

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 65534  # UID 'nobody'
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
```

---

### Network Policy
Restrict traffic to Prometheus scrape endpoints only:

```yaml
networkPolicy:
  enabled: true
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: prometheus
      ports:
        - protocol: TCP
          port: 9100
```

**Benefits:**
- Metrics endpoint only accessible to Prometheus
- Prevents unauthorized metric scraping
- Defense-in-depth security

---

## 🛠️ Custom Metrics (Textfile Collector)

### How It Works
1. Scripts generate metrics in Prometheus format (`.prom` files)
2. Save files to textfile collector directory
3. Node Exporter automatically imports metrics
4. Prometheus scrapes custom metrics alongside system metrics

**Textfile directory:** `/var/lib/node_exporter/textfile_collector`

---

### Example: Backup Status Monitoring

**Script: `backup-status.sh`**
```bash
#!/bin/bash
# Generate backup status metrics

BACKUP_DIR="/backups"
LAST_BACKUP=$(stat -c %Y $(ls -t $BACKUP_DIR/*.tar.gz | head -1))
CURRENT_TIME=$(date +%s)

cat <<EOF > /var/lib/node_exporter/textfile_collector/backup.prom
# HELP backup_last_success_timestamp Timestamp of last successful backup
# TYPE backup_last_success_timestamp gauge
backup_last_success_timestamp $LAST_BACKUP

# HELP backup_age_seconds Age of last backup in seconds
# TYPE backup_age_seconds gauge
backup_age_seconds $((CURRENT_TIME - LAST_BACKUP))
EOF
```

**PromQL alert:**
```yaml
- alert: BackupTooOld
  expr: (time() - backup_last_success_timestamp) > 86400
  annotations:
    summary: "Backup is {{ $value | humanizeDuration }} old"
```

---

### Example: Hardware RAID Health

**Script: `raid-health.sh`**
```bash
#!/bin/bash
# Monitor MegaRAID controller

RAID_STATUS=$(megacli -LDInfo -Lall -aALL | grep State | awk '{print $3}')

if [ "$RAID_STATUS" = "Optimal" ]; then
  HEALTH=1
else
  HEALTH=0
fi

cat <<EOF > /var/lib/node_exporter/textfile_collector/raid.prom
# HELP hardware_raid_health RAID array health (1=healthy, 0=degraded)
# TYPE hardware_raid_health gauge
hardware_raid_health $HEALTH
EOF
```

**More examples:** See `textfile-examples/` directory in chart.

---

## 🆘 Troubleshooting

### Pods Not Running
```bash
# Check pod status
kubectl get pods -n monitoring -l app.kubernetes.io/name=node-exporter

# Describe pod for events
kubectl describe pod -n monitoring <pod-name>

# Common issues:
# - ImagePullBackOff: Check image name and registry
# - CrashLoopBackOff: Check logs with kubectl logs
# - Pending: Check node resources and tolerations
```

---

### No Metrics Available
```bash
# Test metrics endpoint
kubectl port-forward -n monitoring daemonset/node-exporter 9100:9100
curl http://localhost:9100/metrics | grep node_cpu

# Verify collectors enabled
helm get values node-exporter -n monitoring

# Check if hostNetwork is enabled (required)
kubectl get pod -n monitoring <pod-name> -o yaml | grep hostNetwork
```

---

### Temperature Sensors Not Reporting
```bash
# Check if hwmon collector is enabled
helm get values node-exporter -n monitoring | grep hwmon

# Verify /sys/class/hwmon is mounted
kubectl exec -it -n monitoring <pod-name> -- ls /sys/class/hwmon

# Test hwmon metrics
kubectl port-forward -n monitoring <pod-name> 9100:9100
curl http://localhost:9100/metrics | grep node_hwmon_temp

# If no sensors found:
# - Hardware may not expose thermal sensors
# - Driver modules not loaded (coretemp, k10temp, etc.)
# - Try thermal_zone collector as alternative
```

---

### ServiceMonitor Not Discovered
```bash
# Check ServiceMonitor exists
kubectl get servicemonitors -n monitoring

# Verify labels match Prometheus selector
kubectl get servicemonitor node-exporter -n monitoring -o yaml

# Check Prometheus serviceMonitorSelector
kubectl get prometheus -o yaml | grep serviceMonitorSelector -A 5

# Common issue: Label mismatch
serviceMonitor:
  labels:
    prometheus: kube-prometheus  # Must match Prometheus selector
```

---

### High Resource Usage
```bash
# Check actual resource usage
kubectl top pod -n monitoring -l app.kubernetes.io/name=node-exporter

# Reduce collectors:
collectors:
  optional:
    systemd: false  # Disable heavy collectors
    processes: false
    interrupts: false

# Use edge-minimal preset:
resourcePreset: edge-minimal
```

---

## 📚 Use Case Examples

### 1. Raspberry Pi Cluster Monitoring
**Scenario:** 5 Raspberry Pi 4 running K3s, monitoring CPU temperature to prevent throttling

**Configuration:**
```yaml
resourcePreset: edge-minimal
collectors:
  optional:
    thermal_zone: true
    textfile: true
prometheusRule:
  enabled: true
  temperatureAlerts: true
```

**Alerts:**
- Temperature >70°C: Warning email
- Temperature >80°C: Critical PagerDuty alert
- Thermal throttling detected: Slack notification

---

### 2. Factory Edge Computing
**Scenario:** Industrial PCs in dusty factory environment, predictive disk failure

**Configuration:**
```yaml
resourcePreset: edge-standard
collectors:
  optional:
    systemd: true
    textfile: true  # For SMART disk health scripts
prometheusRule:
  enabled: true
  hardwareAlerts: true
  filesystemAlerts: true
```

**Custom metrics:**
- SMART disk health via textfile collector
- Backup status monitoring
- Production line status from PLC

---

### 3. Server Fleet Management
**Scenario:** 50 VMs in data center, comprehensive monitoring

**Configuration:**
```yaml
resourcePreset: server
deploymentMode: daemonset
collectors:
  optional:
    systemd: true
    processes: true
    ntp: true
    tcpstat: true
prometheusRule:
  enabled: true
  hardwareAlerts: true
  temperatureAlerts: true
  filesystemAlerts: true
  systemAlerts: true
```

**Dashboards:**
- Cluster Overview (fleet health)
- Hardware Health (temperature, disk, network)
- Node Exporter Full (drill-down per server)

---

## 📖 Additional Resources

- **Prometheus Node Exporter:** https://github.com/prometheus/node_exporter
- **Metrics Reference:** See `METRICS_REFERENCE.md` in chart
- **Collector Details:** See `COLLECTORS.md` in chart
- **Quick Reference:** See `QUICK_REFERENCE.md` in chart

---

## 📝 License

Chart: Apache License 2.0 - See LICENSE file for details.

**Prometheus Node Exporter:** Apache 2.0

---

## 🎓 Getting Started Checklist

**Before deployment:**
- [ ] Choose deployment mode (DaemonSet recommended for clusters)
- [ ] Select resource preset (edge-minimal/edge-standard/server)
- [ ] Identify optional collectors needed (systemd, processes, textfile)
- [ ] Plan temperature monitoring (hwmon and/or thermal_zone)
- [ ] Decide on Prometheus integration method (ServiceMonitor vs manual)

**After deployment:**
- [ ] Verify pods running on all nodes (DaemonSet mode)
- [ ] Test metrics endpoint accessibility
- [ ] Configure Prometheus to scrape Node Exporter
- [ ] Import Grafana dashboards
- [ ] Deploy alert rules (PrometheusRule)
- [ ] Set up textfile collector scripts (if using custom metrics)
- [ ] Configure AlertManager routing for critical alerts
- [ ] Test temperature alerts (if enabled)

---

**Remember:** Node Exporter runs on host network and PID namespace to access system metrics. This is required and normal. If temperature monitoring is critical (edge deployments), enable `thermal_zone` collector. 🌡️

*Pro tip:* Start with `edge-standard` preset and ServiceMonitor enabled. Add optional collectors (systemd, textfile) as needed. Monitor temperature on all edge devices - hardware failure from overheating is expensive. 🔥

**Happy monitoring!** 📊

---

*Created by Patrick Ryan - Fireball Industries*

*"Because knowing when your hardware is about to die is slightly important."*
