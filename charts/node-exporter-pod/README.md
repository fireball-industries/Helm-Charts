# Fireball Node Exporter

```ascii
███████╗██╗██████╗ ███████╗██████╗  █████╗ ██╗     ██╗     
██╔════╝██║██╔══██╗██╔════╝██╔══██╗██╔══██╗██║     ██║     
█████╗  ██║██████╔╝█████╗  ██████╔╝███████║██║     ██║     
██╔══╝  ██║██╔══██╗██╔══╝  ██╔══██╗██╔══██║██║     ██║     
██║     ██║██║  ██║███████╗██████╔╝██║  ██║███████╗███████╗
╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝
NODE EXPORTER - Because Dead Hardware Costs Money
```

**Production-ready Prometheus Node Exporter Helm chart for Kubernetes/K3s environments.**

Comprehensive node-level hardware monitoring optimized for industrial edge computing where knowing when your hardware is about to die is slightly important. Because uptime matters when downtime costs actual money.

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Helm](https://img.shields.io/badge/Helm-v3-blue)](https://helm.sh)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.19%2B-blue)](https://kubernetes.io)
[![Node Exporter](https://img.shields.io/badge/Node%20Exporter-v1.7.0-green)](https://github.com/prometheus/node_exporter)

---

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Deployment Modes](#deployment-modes)
- [Configuration](#configuration)
- [Resource Presets](#resource-presets)
- [Collectors](#collectors)
- [Examples](#examples)
- [PowerShell Management](#powershell-management)
- [Grafana Dashboards](#grafana-dashboards)
- [Alerts](#alerts)
- [Troubleshooting](#troubleshooting)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)

---

## Features

### Core Capabilities
- ✅ **3 Deployment Modes**: DaemonSet (default), Deployment, StatefulSet
- ✅ **25+ Collectors**: CPU, memory, disk, network, filesystem, temperature, processes, systemd, and more
- ✅ **Resource Presets**: Optimized configurations for edge-minimal (Raspberry Pi), edge-standard (industrial), and server workloads
- ✅ **Textfile Collector**: Import custom metrics from scripts and external tools
- ✅ **Prometheus Operator**: ServiceMonitor for automatic service discovery

### Industrial Edge Optimizations
- 🌡️ **Temperature Monitoring**: hwmon and thermal_zone collectors for overheating detection
- 💾 **Disk Wear Tracking**: Monitor SD card/SSD wear for preventive replacement
- ⚡ **Minimal Resource Mode**: Run on Raspberry Pi with 50m CPU / 30Mi RAM
- 🔒 **Security Hardened**: Non-root execution, read-only filesystem, minimal capabilities

### Security & Compliance
- 🔐 **RBAC**: ClusterRole and ClusterRoleBinding for node access
- 🛡️ **NetworkPolicy**: Restrict traffic to Prometheus scrape endpoints
- 🔒 **PodSecurityPolicy**: Legacy PSP support for older clusters
- 👤 **Non-root Execution**: Runs as UID 65534 (nobody)
- 📁 **Read-only Root**: Immutable container filesystem

### Monitoring Integration
- 📊 **Grafana Dashboards**: 4 pre-built dashboards (full, edge, cluster, hardware)
- 🚨 **Alert Rules**: 30+ PrometheusRule templates for critical thresholds
- 📈 **Recording Rules**: Pre-aggregated metrics for faster queries
- 🔔 **AlertManager Integration**: Example routing configurations

---

## Quick Start

### Prerequisites
- Kubernetes 1.19.0+ or K3s
- Helm 3.0+
- `kubectl` configured

### Install in 30 Seconds

```powershell
# Clone the repository
git clone https://github.com/fireball-industries/node-exporter-pod.git
cd node-exporter-pod

# Deploy with default settings (DaemonSet on all nodes)
helm install node-exporter . --namespace monitoring --create-namespace

# Verify deployment
kubectl get daemonset -n monitoring node-exporter
kubectl get pods -n monitoring -l app.kubernetes.io/name=node-exporter -o wide

# Access metrics from any pod
kubectl port-forward -n monitoring daemonset/node-exporter 9100:9100
curl http://localhost:9100/metrics
```

That's it. Your nodes are now being monitored.

---

## Deployment Modes

### DaemonSet (Default - Recommended)
Runs one pod per node in the cluster. Best for comprehensive cluster-wide monitoring.

```powershell
helm install node-exporter . -n monitoring --set deploymentMode=daemonset
```

**Use when:**
- You want metrics from every node
- Node-level monitoring is required
- Running on physical hardware or VMs

### Deployment
Single-instance deployment. Useful for testing or monitoring the Kubernetes master only.

```powershell
helm install node-exporter . -n monitoring --set deploymentMode=deployment --set replicaCount=1
```

**Use when:**
- Testing the configuration
- Monitoring a single node
- Resource constraints prevent DaemonSet

### StatefulSet
Similar to Deployment but with persistent identity. Rarely needed for Node Exporter.

```powershell
helm install node-exporter . -n monitoring --set deploymentMode=statefulset
```

**Use when:**
- You need stable network identity
- Persistent storage is required (uncommon for Node Exporter)

---

## Configuration

### Basic Configuration

```yaml
# values.yaml
resourcePreset: edge-standard  # edge-minimal, edge-standard, server

collectors:
  cpu: true
  cpufreq: true
  diskstats: true
  filesystem: true
  hwmon: true              # Temperature sensors
  thermal_zone: true       # Thermal monitoring
  loadavg: true
  meminfo: true
  netdev: true
  systemd: true            # Systemd unit monitoring
  processes: true          # Process states
  textfile: true           # Custom metrics

textfileCollector:
  directory: /var/lib/node_exporter/textfile_collector

serviceMonitor:
  enabled: true
  labels:
    prometheus: kube-prometheus
```

### Advanced Configuration

```yaml
# Production edge deployment with security
resourcePreset: edge-standard

collectors:
  hwmon: true
  thermal_zone: true
  textfile: true

securityContext:
  runAsNonRoot: true
  runAsUser: 65534
  readOnlyRootFilesystem: true

networkPolicy:
  enabled: true
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: prometheus

rbac:
  create: true
  pspEnabled: false  # Disable for Kubernetes 1.25+
```

---

## Resource Presets

Choose a preset based on your hardware:

| Preset | CPU Request | CPU Limit | Memory Request | Memory Limit | Use Case |
|--------|------------|-----------|----------------|--------------|----------|
| **edge-minimal** | 50m | 100m | 30Mi | 50Mi | Raspberry Pi, IoT devices, ultra-constrained |
| **edge-standard** | 100m | 200m | 50Mi | 100Mi | Industrial edge, small VMs **(default)** |
| **server** | 200m | 500m | 100Mi | 200Mi | Servers, large VMs, full collector set |

### Apply a Preset

```powershell
# Ultra-lightweight for Raspberry Pi
helm install node-exporter . -n monitoring --set resourcePreset=edge-minimal

# Default industrial edge
helm install node-exporter . -n monitoring --set resourcePreset=edge-standard

# Full server monitoring
helm install node-exporter . -n monitoring --set resourcePreset=server
```

### Custom Resources (Override Preset)

```yaml
resources:
  requests:
    cpu: 150m
    memory: 75Mi
  limits:
    cpu: 300m
    memory: 150Mi
```

---

## Collectors

### Default Enabled Collectors (13)

Always enabled for comprehensive node monitoring:

- **cpu** - CPU time statistics
- **cpufreq** - CPU frequency scaling
- **diskstats** - Disk I/O statistics
- **filesystem** - Filesystem usage (mount points)
- **hwmon** - Hardware monitoring (temperature, fans, voltage)
- **loadavg** - System load average
- **meminfo** - Memory statistics
- **netdev** - Network device statistics
- **netstat** - Network statistics (TCP, UDP)
- **stat** - Various kernel statistics
- **time** - System time
- **uname** - System information (OS, kernel, architecture)
- **vmstat** - Virtual memory statistics

### Optional Collectors

Enable as needed for specific monitoring requirements:

```yaml
collectors:
  # Systemd unit monitoring
  systemd: true
  
  # Process states (running, sleeping, zombie)
  processes: true
  
  # Custom metrics from files
  textfile: true
  
  # NTP time synchronization
  ntp: true
  
  # TCP connection states
  tcpstat: true
  
  # CPU interrupts
  interrupts: true
  
  # Thermal zones (alternative to hwmon)
  thermal_zone: true
  
  # Network device details (ethtool)
  ethtool: true
  
  # WiFi statistics
  wifi: true
  
  # RAPL power monitoring
  rapl: true
  
  # Supervisord process manager
  supervisord: true
```

See [COLLECTORS.md](COLLECTORS.md) for complete collector reference.

---

## Examples

### Industrial Edge Deployment

Monitor Raspberry Pi or industrial PCs with temperature focus:

```powershell
helm install node-exporter . -n monitoring -f examples/edge-daemonset.yaml
```

### Secure Production Deployment

Full security hardening with NetworkPolicy:

```powershell
helm install node-exporter . -n monitoring -f examples/secure-monitoring.yaml
```

### K3s Lightweight

Optimized for K3s clusters on Raspberry Pi:

```powershell
helm install node-exporter . -n monitoring -f examples/k3s-lightweight.yaml
```

### Server Full Monitoring

All collectors enabled for comprehensive server monitoring:

```powershell
helm install node-exporter . -n monitoring -f examples/server-full.yaml
```

### Single Instance Demo

Deployment mode for testing:

```powershell
helm install node-exporter . -n monitoring -f examples/demo-node-exporter.yaml
```

All example configurations are in [examples/](examples/).

---

## PowerShell Management

Use included PowerShell scripts for easy management:

### Main Management Script

```powershell
# Deploy Node Exporter
.\scripts\manage-node-exporter.ps1 -Action deploy -Release node-exporter

# Upgrade existing deployment
.\scripts\manage-node-exporter.ps1 -Action upgrade -Release node-exporter

# Health check
.\scripts\manage-node-exporter.ps1 -Action health-check

# View metrics from all pods
.\scripts\manage-node-exporter.ps1 -Action view-metrics

# Check temperature across all nodes
.\scripts\manage-node-exporter.ps1 -Action temperature

# Check disk space
.\scripts\manage-node-exporter.ps1 -Action disk-space

# View logs
.\scripts\manage-node-exporter.ps1 -Action logs -PodName node-exporter-abc123

# Delete deployment
.\scripts\manage-node-exporter.ps1 -Action delete -Release node-exporter
```

### Test Suite

```powershell
# Run comprehensive test suite
.\scripts\test-node-exporter.ps1
```

Tests:
- Helm release status
- Pod deployment
- Metrics endpoint
- Collector functionality
- Scrape performance
- ServiceMonitor configuration
- RBAC permissions
- Resource usage

### Cluster Health Analysis

```powershell
# Analyze health across all nodes
.\scripts\analyze-cluster-health.ps1
```

Analyzes:
- Memory pressure (>90% critical)
- Disk space (predictive full disk warnings)
- Temperature (>80°C critical)
- Network errors

---

## Grafana Dashboards

Four pre-built dashboards included:

### 1. Node Exporter Full
**File:** `dashboards/node-exporter-full.json`  
Comprehensive overview of all node metrics. CPU, memory, disk, network, temperature.

### 2. Industrial Edge
**File:** `dashboards/industrial-edge.json`  
Edge-focused dashboard with temperature emphasis. Optimized for Raspberry Pi and industrial PCs.

### 3. Cluster Overview
**File:** `dashboards/cluster-overview.json`  
Multi-node aggregation view showing fleet health at a glance.

### 4. Hardware Health
**File:** `dashboards/hardware-health.json`  
Temperature sensors, disk health, network errors, I/O performance.

### Import Dashboards

```powershell
# Via Grafana UI
# 1. Go to Dashboards > Import
# 2. Upload JSON file from dashboards/ directory
# 3. Select Prometheus datasource

# Via ConfigMap (Kubernetes)
kubectl create configmap grafana-dashboard-node-exporter \
  --from-file=dashboards/node-exporter-full.json \
  -n monitoring

# Label for auto-discovery
kubectl label configmap grafana-dashboard-node-exporter \
  grafana_dashboard=1 -n monitoring
```

See [integration/grafana-provisioning.yaml](integration/grafana-provisioning.yaml) for complete setup.

---

## Alerts

### Alert Rule Templates

Four PrometheusRule files with 30+ alerts:

#### Hardware Alerts (`alerts/alerts-hardware.yaml`)
- HighCPUUsage (>80% for 5m)
- CriticalCPUUsage (>95% for 2m)
- HighMemoryUsage (>80% for 5m)
- CriticalMemoryUsage (>90% for 2m)
- HighDiskIOLatency (>100ms)
- NetworkInterfaceErrors
- HighNetworkErrors (>1%)

#### Temperature Alerts (`alerts/alerts-temperature.yaml`)
- HighTemperature (>70°C warning)
- CriticalTemperature (>80°C critical)
- ThermalThrottling (>85°C)
- FanFailure

#### Filesystem Alerts (`alerts/alerts-filesystem.yaml`)
- DiskSpaceWarning (>80%)
- DiskSpaceCritical (>90%)
- DiskWillFillIn4Hours
- DiskWillFillIn24Hours
- DiskAlmostFull (>95%)
- DiskSpaceVeryLow (<5GB absolute)
- InodesWarning (>80%)
- InodesCritical (>90%)
- FilesystemReadOnly

#### System Alerts (`alerts/alerts-system.yaml`)
- ClockSkewDetected (>1s drift)
- ClockSkewCritical (>30s drift)
- HighContextSwitches
- ZombieProcesses
- OOMKillerActive
- SwapUsageHigh (>80%)
- SwapActivityHigh
- NodeNotReady
- NodeRebooted
- HighFileDescriptorUsage (>80%)
- LowEntropyAvailable (<100)

### Deploy Alerts

```powershell
# Deploy all alert rules
kubectl apply -f alerts/ -n monitoring

# Verify PrometheusRule resources
kubectl get prometheusrules -n monitoring
```

---

## Troubleshooting

### Pods Not Starting

```powershell
# Check pod status
kubectl get pods -n monitoring -l app.kubernetes.io/name=node-exporter
kubectl describe pod -n monitoring <pod-name>

# Common issues:
# - ImagePullBackOff: Check image name and registry
# - CrashLoopBackOff: Check logs with kubectl logs
# - Pending: Check node resources and tolerations

# View logs
kubectl logs -n monitoring <pod-name>
```

### No Metrics Visible

```powershell
# Test metrics endpoint
kubectl port-forward -n monitoring svc/node-exporter 9100:9100
curl http://localhost:9100/metrics | Select-String "node_cpu"

# Verify collectors enabled
helm get values node-exporter -n monitoring
```

### Temperature Sensors Not Working

```yaml
# Ensure collectors enabled
collectors:
  hwmon: true
  thermal_zone: true

# Check host path mounts
# /sys must be mounted from host
```

### ServiceMonitor Not Discovered

```powershell
# Check Prometheus Operator
kubectl get servicemonitors -n monitoring

# Verify labels match Prometheus selector
serviceMonitor:
  labels:
    prometheus: kube-prometheus  # Must match your Prometheus
```

See [QUICK_REFERENCE.md](QUICK_REFERENCE.md) for complete troubleshooting guide.

---

## Documentation

- **[COLLECTORS.md](COLLECTORS.md)** - Complete collector reference with metrics and examples
- **[METRICS_REFERENCE.md](METRICS_REFERENCE.md)** - All metrics with PromQL queries
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Fast command reference and troubleshooting
- **[examples/](examples/)** - 5 deployment configuration examples
- **[alerts/](alerts/)** - 4 PrometheusRule templates
- **[dashboards/](dashboards/)** - 4 Grafana dashboards
- **[integration/](integration/)** - Prometheus, AlertManager, Grafana configs
- **[textfile-examples/](textfile-examples/)** - Custom metrics scripts

---

## Textfile Collector Examples

Import custom metrics from scripts:

### Backup Status Monitoring
```bash
# Run backup-status.sh via cron
./textfile-examples/backup-status.sh

# Exports metrics:
# backup_last_success_timestamp
# backup_size_bytes
# backup_health_status
```

### Hardware Health Checks
```bash
# Monitor RAID, SMART, UPS, PSU
./textfile-examples/hardware-health.sh

# Exports metrics:
# hardware_raid_health
# hardware_disk_smart_health
# hardware_ups_health
# hardware_nvme_temperature_celsius
```

### License Expiry Tracking
```bash
# Track software license expiration
./textfile-examples/license-expiry.sh

# Exports metrics:
# license_expiry_days
# license_status
```

See [textfile-examples/](textfile-examples/) for all scripts and [textfile-examples/custom-metrics.prom.example](textfile-examples/custom-metrics.prom.example) for format reference.

---

## Integration Examples

### Prometheus Configuration
```yaml
# See integration/prometheus-config.yaml
scrape_configs:
  - job_name: 'kubernetes-node-exporter'
    kubernetes_sd_configs:
      - role: endpoints
    relabel_configs:
      - source_labels: [__meta_kubernetes_service_name]
        action: keep
        regex: node-exporter
```

### AlertManager Routing
```yaml
# See integration/alertmanager-config.yaml
route:
  routes:
    - match:
        severity: critical
        alertname: ~"Critical.*"
      receiver: 'oncall-pager'
```

### Node Affinity
```yaml
# See integration/node-affinity.yaml
# Deploy only on edge nodes
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: node-role
              operator: In
              values:
                - edge
```

---

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## License

This project is licensed under the **Apache License 2.0** - see the [LICENSE](LICENSE) file for details.

Prometheus Node Exporter itself is also Apache 2.0 licensed.

---

## Credits

**Created by:** Patrick Ryan / Fireball Industries  
**Node Exporter Upstream:** [prometheus/node_exporter](https://github.com/prometheus/node_exporter)  
**Inspired by:** Years of watching hardware fail in industrial environments

---

## Support

- **Issues:** [GitHub Issues](https://github.com/fireball-industries/node-exporter-pod/issues)
- **Discussions:** [GitHub Discussions](https://github.com/fireball-industries/node-exporter-pod/discussions)
- **Documentation:** See [docs/](.) for all documentation files

---

**Made with 💀 by Fireball Industries**  
*Because knowing when your hardware is about to die is slightly important.*

---

## Changelog

### v1.0.0 (2024-01-21)
- Initial release
- 3 deployment modes (DaemonSet, Deployment, StatefulSet)
- 25+ collectors with configurable presets
- 3 resource presets (edge-minimal, edge-standard, server)
- Full RBAC and security hardening
- ServiceMonitor for Prometheus Operator
- 4 Grafana dashboards
- 30+ alert rules
- PowerShell management scripts
- Complete documentation suite
