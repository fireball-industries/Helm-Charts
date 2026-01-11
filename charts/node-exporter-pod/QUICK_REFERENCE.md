# Node Exporter Quick Reference

Fast command reference and troubleshooting guide for Prometheus Node Exporter on Kubernetes/K3s.

## Table of Contents
- [Installation](#installation)
- [Common Commands](#common-commands)
- [Troubleshooting](#troubleshooting)
- [PromQL Quick Reference](#promql-quick-reference)
- [Alert Examples](#alert-examples)

---

## Installation

### Quick Deploy (Default DaemonSet)
```powershell
# Clone repository
git clone https://github.com/fireball-industries/node-exporter-pod.git
cd node-exporter-pod

# Deploy with default settings
helm install node-exporter . -n monitoring --create-namespace
```

### Deploy with Custom Values
```powershell
# Using values file
helm install node-exporter . -n monitoring -f examples/edge-daemonset.yaml

# Using inline values
helm install node-exporter . -n monitoring `
  --set resourcePreset=edge-minimal `
  --set collectors.hwmon=true `
  --set collectors.thermal_zone=true
```

### Deployment Modes
```powershell
# DaemonSet (default - runs on all nodes)
helm install node-exporter . -n monitoring

# Deployment (single instance)
helm install node-exporter . -n monitoring --set deploymentMode=deployment

# StatefulSet (persistent identity)
helm install node-exporter . -n monitoring --set deploymentMode=statefulset
```

---

## Common Commands

### Helm Operations
```powershell
# List releases
helm list -n monitoring

# Get values
helm get values node-exporter -n monitoring

# Upgrade
helm upgrade node-exporter . -n monitoring

# Rollback
helm rollback node-exporter -n monitoring

# Uninstall
helm uninstall node-exporter -n monitoring
```

### kubectl Operations
```powershell
# Check pod status
kubectl get pods -n monitoring -l app.kubernetes.io/name=node-exporter

# View logs
kubectl logs -n monitoring -l app.kubernetes.io/name=node-exporter --tail=50

# Get metrics from pod
kubectl port-forward -n monitoring svc/node-exporter 9100:9100
curl http://localhost:9100/metrics

# Describe pod
kubectl describe pod -n monitoring <pod-name>

# Execute command in pod
kubectl exec -it -n monitoring <pod-name> -- /bin/sh
```

### PowerShell Management Script
```powershell
# Deploy
.\scripts\manage-node-exporter.ps1 -Action deploy -Release node-exporter

# Health check
.\scripts\manage-node-exporter.ps1 -Action health-check

# View metrics
.\scripts\manage-node-exporter.ps1 -Action view-metrics

# Check temperature
.\scripts\manage-node-exporter.ps1 -Action temperature

# Check disk space
.\scripts\manage-node-exporter.ps1 -Action disk-space

# View logs
.\scripts\manage-node-exporter.ps1 -Action logs

# Delete
.\scripts\manage-node-exporter.ps1 -Action delete -Release node-exporter
```

### Testing
```powershell
# Run full test suite
.\scripts\test-node-exporter.ps1

# Analyze cluster health
.\scripts\analyze-cluster-health.ps1
```

---

## Troubleshooting

### Pod Not Starting

**Check pod status:**
```powershell
kubectl get pods -n monitoring -l app.kubernetes.io/name=node-exporter
kubectl describe pod -n monitoring <pod-name>
```

**Common issues:**
- **ImagePullBackOff:** Check image name and registry access
- **CrashLoopBackOff:** Check logs with `kubectl logs`
- **Pending:** Check node resources and tolerations

**Fix permission issues:**
```yaml
# Ensure RBAC is enabled
rbac:
  create: true

# Check ServiceAccount
kubectl get sa -n monitoring node-exporter
```

### No Metrics Visible

**Test metrics endpoint:**
```powershell
# Port-forward to pod
kubectl port-forward -n monitoring svc/node-exporter 9100:9100

# Fetch metrics
curl http://localhost:9100/metrics | Select-String "node_cpu"
```

**Check collectors:**
```powershell
# Verify enabled collectors
helm get values node-exporter -n monitoring | Select-String "collectors"
```

### High Memory Usage

**Check resource limits:**
```powershell
kubectl describe pod -n monitoring <pod-name> | Select-String "Limits|Requests"
```

**Reduce memory usage:**
```yaml
# Use minimal preset
resourcePreset: edge-minimal

# Disable heavy collectors
collectors:
  processes: false
  systemd: false
```

### Temperature Sensors Not Working

**Enable collectors:**
```yaml
collectors:
  hwmon: true
  thermal_zone: true
```

**Check host access:**
```yaml
# Ensure host paths are mounted
hostPID: false  # Usually not needed
hostNetwork: false

# Volume mounts should include /sys
volumes:
  - name: sys
    hostPath:
      path: /sys
```

### ServiceMonitor Not Discovered

**Check Prometheus Operator:**
```powershell
kubectl get servicemonitors -n monitoring
kubectl describe servicemonitor -n monitoring node-exporter
```

**Verify labels:**
```yaml
serviceMonitor:
  enabled: true
  labels:
    prometheus: kube-prometheus  # Must match Prometheus selector
```

---

## PromQL Quick Reference

### CPU
```promql
# CPU usage %
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Per-CPU usage
100 - (avg by (instance, cpu) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

### Memory
```promql
# Memory usage %
100 - ((node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100)

# Memory used (GB)
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / 1024 / 1024 / 1024
```

### Disk
```promql
# Disk usage %
100 - ((node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100)

# Disk I/O rate (MB/s)
rate(node_disk_read_bytes_total[5m]) / 1024 / 1024
```

### Network
```promql
# Network RX (MB/s)
rate(node_network_receive_bytes_total{device!~"lo|veth.*"}[5m]) / 1024 / 1024

# Network errors
rate(node_network_receive_errs_total[5m]) + rate(node_network_transmit_errs_total[5m])
```

### Temperature
```promql
# Max temperature
max(node_hwmon_temp_celsius)

# Temperature by chip
avg by (chip) (node_hwmon_temp_celsius)
```

---

## Alert Examples

### CPU Alert
```yaml
- alert: HighCPUUsage
  expr: 100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "High CPU usage on {{ $labels.instance }}"
```

### Memory Alert
```yaml
- alert: HighMemoryUsage
  expr: 100 - ((node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100) > 90
  for: 2m
  labels:
    severity: critical
  annotations:
    summary: "Critical memory usage on {{ $labels.instance }}"
```

### Disk Alert
```yaml
- alert: DiskSpaceLow
  expr: 100 - ((node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100) > 90
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "Disk {{ $labels.mountpoint }} on {{ $labels.instance }} is {{ $value | humanize }}% full"
```

### Temperature Alert
```yaml
- alert: HighTemperature
  expr: node_hwmon_temp_celsius > 70
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "High temperature {{ $value }}°C on {{ $labels.instance }}"
```

---

## Resource Presets

| Preset | CPU Request | CPU Limit | Memory Request | Memory Limit | Use Case |
|--------|------------|-----------|----------------|--------------|----------|
| edge-minimal | 50m | 100m | 30Mi | 50Mi | Raspberry Pi, IoT |
| edge-standard | 100m | 200m | 50Mi | 100Mi | Industrial edge (default) |
| server | 200m | 500m | 100Mi | 200Mi | Servers, VMs |

**Apply preset:**
```powershell
helm install node-exporter . -n monitoring --set resourcePreset=edge-minimal
```

---

## Default Collectors

### Always Enabled (13)
- cpu, cpufreq, diskstats, filesystem, hwmon
- loadavg, meminfo, netdev, netstat, stat
- time, uname, vmstat

### Optional (Enable as needed)
```yaml
collectors:
  systemd: true        # Systemd units
  processes: true      # Process states
  textfile: true       # Custom metrics
  ntp: true           # Time sync
  tcpstat: true       # TCP stats
  thermal_zone: true  # Temperature
```

---

## Port Reference

| Service | Port | Protocol | Description |
|---------|------|----------|-------------|
| Metrics | 9100 | HTTP | Prometheus scrape endpoint |

---

## File Locations

| Path | Description |
|------|-------------|
| /proc | Process and kernel information (mounted from host) |
| /sys | System devices and drivers (mounted from host) |
| /root | Root filesystem (mounted read-only from host) |
| /var/lib/node_exporter/textfile_collector | Textfile collector directory |

---

## Useful Links

- **Chart Repository:** https://github.com/fireball-industries/node-exporter-pod
- **Node Exporter Docs:** https://github.com/prometheus/node_exporter
- **Prometheus Docs:** https://prometheus.io/docs
- **Grafana Dashboards:** https://grafana.com/grafana/dashboards/1860

---

## Emergency Commands

### Force pod restart
```powershell
kubectl delete pod -n monitoring -l app.kubernetes.io/name=node-exporter
```

### View all events
```powershell
kubectl get events -n monitoring --sort-by='.lastTimestamp'
```

### Check resource usage
```powershell
kubectl top pods -n monitoring
```

### Emergency rollback
```powershell
helm rollback node-exporter 0 -n monitoring
```

---

**Made with 💀 by Fireball Industries**  
*Because knowing when your hardware is about to die is slightly important.*
