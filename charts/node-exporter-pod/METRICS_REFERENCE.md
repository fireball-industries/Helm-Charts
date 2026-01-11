# Node Exporter Metrics Reference

Complete reference of all metrics exposed by Prometheus Node Exporter v1.7.0.

## Table of Contents

- [CPU Metrics](#cpu-metrics)
- [Memory Metrics](#memory-metrics)
- [Filesystem Metrics](#filesystem-metrics)
- [Disk I/O Metrics](#disk-io-metrics)
- [Network Metrics](#network-metrics)
- [System Load Metrics](#system-load-metrics)
- [Temperature Metrics](#temperature-metrics)
- [Time & System Metrics](#time--system-metrics)
- [Advanced Collectors](#advanced-collectors)

---

## CPU Metrics

### node_cpu_seconds_total
**Type:** Counter  
**Labels:** `cpu`, `mode`  
**Description:** Total seconds CPU has spent in each mode  

**Modes:**
- `idle` - Time CPU spent idle
- `iowait` - Time waiting for I/O operations
- `irq` - Time servicing interrupts
- `nice` - Time in user mode with low priority
- `softirq` - Time servicing software interrupts
- `steal` - Time stolen by hypervisor (VMs only)
- `system` - Time in kernel mode
- `user` - Time in user mode

**PromQL Examples:**
```promql
# CPU usage percentage per CPU
100 - (avg by (instance, cpu) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Overall CPU usage percentage
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# CPU usage by mode
sum by (mode) (irate(node_cpu_seconds_total[5m]))

# I/O wait percentage
avg by (instance) (irate(node_cpu_seconds_total{mode="iowait"}[5m])) * 100
```

### node_cpu_guest_seconds_total
**Type:** Counter  
**Labels:** `cpu`, `mode`  
**Description:** Time spent running virtual CPUs for guest operating systems

---

## Memory Metrics

### node_memory_MemTotal_bytes
**Type:** Gauge  
**Description:** Total usable RAM (physical RAM minus reserved bits and kernel binary code)

### node_memory_MemFree_bytes
**Type:** Gauge  
**Description:** Amount of free memory

### node_memory_MemAvailable_bytes
**Type:** Gauge  
**Description:** Estimate of memory available for starting new applications (without swapping)

### node_memory_Buffers_bytes
**Type:** Gauge  
**Description:** Memory used by kernel buffers

### node_memory_Cached_bytes
**Type:** Gauge  
**Description:** Memory used as page cache

### node_memory_SwapTotal_bytes / node_memory_SwapFree_bytes
**Type:** Gauge  
**Description:** Total and free swap space

**PromQL Examples:**
```promql
# Memory usage percentage
100 - ((node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100)

# Memory used (excluding buffers/cache)
node_memory_MemTotal_bytes - node_memory_MemFree_bytes - node_memory_Buffers_bytes - node_memory_Cached_bytes

# Swap usage percentage
((node_memory_SwapTotal_bytes - node_memory_SwapFree_bytes) / node_memory_SwapTotal_bytes) * 100

# Available memory in GB
node_memory_MemAvailable_bytes / 1024 / 1024 / 1024
```

---

## Filesystem Metrics

### node_filesystem_size_bytes
**Type:** Gauge  
**Labels:** `device`, `fstype`, `mountpoint`  
**Description:** Filesystem size in bytes

### node_filesystem_avail_bytes
**Type:** Gauge  
**Labels:** `device`, `fstype`, `mountpoint`  
**Description:** Filesystem space available to non-root users

### node_filesystem_free_bytes
**Type:** Gauge  
**Labels:** `device`, `fstype`, `mountpoint`  
**Description:** Filesystem free space (including reserved for root)

### node_filesystem_files
**Type:** Gauge  
**Labels:** `device`, `fstype`, `mountpoint`  
**Description:** Total inodes in filesystem

### node_filesystem_files_free
**Type:** Gauge  
**Labels:** `device`, `fstype`, `mountpoint`  
**Description:** Free inodes

**PromQL Examples:**
```promql
# Filesystem usage percentage
100 - ((node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100)

# Inode usage percentage
100 - ((node_filesystem_files_free / node_filesystem_files) * 100)

# Filesystems over 80% full
100 - ((node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100) > 80

# Predict disk full in 4 hours
predict_linear(node_filesystem_avail_bytes{mountpoint="/"}[1h], 4*3600) < 0
```

---

## Disk I/O Metrics

### node_disk_read_bytes_total
**Type:** Counter  
**Labels:** `device`  
**Description:** Total bytes read from disk

### node_disk_written_bytes_total
**Type:** Counter  
**Labels:** `device`  
**Description:** Total bytes written to disk

### node_disk_reads_completed_total
**Type:** Counter  
**Labels:** `device`  
**Description:** Number of completed read operations

### node_disk_writes_completed_total
**Type:** Counter  
**Labels:** `device`  
**Description:** Number of completed write operations

### node_disk_io_time_seconds_total
**Type:** Counter  
**Labels:** `device`  
**Description:** Total time spent doing I/Os

**PromQL Examples:**
```promql
# Read throughput (bytes/sec)
rate(node_disk_read_bytes_total[5m])

# Write throughput (bytes/sec)
rate(node_disk_written_bytes_total[5m])

# Total IOPS
rate(node_disk_reads_completed_total[5m]) + rate(node_disk_writes_completed_total[5m])

# Average I/O wait time (ms)
rate(node_disk_io_time_seconds_total[5m]) * 1000
```

---

## Network Metrics

### node_network_receive_bytes_total
**Type:** Counter  
**Labels:** `device`  
**Description:** Total bytes received on network interface

### node_network_transmit_bytes_total
**Type:** Counter  
**Labels:** `device`  
**Description:** Total bytes transmitted on network interface

### node_network_receive_errs_total
**Type:** Counter  
**Labels:** `device`  
**Description:** Total receive errors

### node_network_transmit_errs_total
**Type:** Counter  
**Labels:** `device`  
**Description:** Total transmit errors

### node_network_receive_drop_total
**Type:** Counter  
**Labels:** `device`  
**Description:** Total packets dropped while receiving

**PromQL Examples:**
```promql
# Network receive rate (bytes/sec)
rate(node_network_receive_bytes_total{device!~"lo|veth.*"}[5m])

# Network transmit rate (bytes/sec)
rate(node_network_transmit_bytes_total{device!~"lo|veth.*"}[5m])

# Network error rate
rate(node_network_receive_errs_total[5m]) + rate(node_network_transmit_errs_total[5m])

# Total network bandwidth (MB/s)
(rate(node_network_receive_bytes_total[5m]) + rate(node_network_transmit_bytes_total[5m])) / 1024 / 1024
```

---

## System Load Metrics

### node_load1 / node_load5 / node_load15
**Type:** Gauge  
**Description:** System load average over 1, 5, and 15 minutes

### node_procs_running
**Type:** Gauge  
**Description:** Number of processes in runnable state

### node_procs_blocked
**Type:** Gauge  
**Description:** Number of processes blocked waiting for I/O

**PromQL Examples:**
```promql
# Load per CPU core
node_load5 / count(node_cpu_seconds_total{mode="idle"}) without (cpu, mode)

# High load alert condition
node_load5 / count(node_cpu_seconds_total{mode="idle"}) without (cpu, mode) > 0.8
```

---

## Temperature Metrics

### node_hwmon_temp_celsius
**Type:** Gauge  
**Labels:** `chip`, `sensor`  
**Description:** Hardware monitoring temperature sensor reading

### node_thermal_zone_temp
**Type:** Gauge  
**Labels:** `zone`, `type`  
**Description:** Thermal zone temperature

**PromQL Examples:**
```promql
# Maximum temperature across all sensors
max(node_hwmon_temp_celsius)

# Temperature alert (>70°C)
node_hwmon_temp_celsius > 70

# Average temperature per chip
avg by (chip) (node_hwmon_temp_celsius)
```

---

## Time & System Metrics

### node_time_seconds
**Type:** Gauge  
**Description:** System time in seconds since epoch

### node_boot_time_seconds
**Type:** Gauge  
**Description:** Unix time when system booted

### node_context_switches_total
**Type:** Counter  
**Description:** Total number of context switches

**PromQL Examples:**
```promql
# System uptime (hours)
(time() - node_boot_time_seconds) / 3600

# Clock skew detection (compare to Prometheus time)
abs(time() - node_time_seconds) > 1

# Context switch rate
rate(node_context_switches_total[5m])
```

---

## Advanced Collectors

### systemd Metrics
- `node_systemd_unit_state` - Unit states (active, inactive, failed)
- `node_systemd_system_running` - Overall systemd state

### NTP Metrics
- `node_ntp_offset_seconds` - Time offset from NTP server
- `node_ntp_stratum` - NTP stratum

### Process Metrics
- `node_processes_state` - Number of processes by state
- `node_processes_threads` - Number of threads

### TCP Metrics
- `node_netstat_Tcp_CurrEstab` - Established TCP connections
- `node_netstat_Tcp_ActiveOpens` - Active TCP opens
- `node_netstat_Tcp_PassiveOpens` - Passive TCP opens

---

## Common Queries & Alerts

### Top 5 filesystems by usage
```promql
topk(5, 100 - ((node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100))
```

### Nodes with high memory pressure
```promql
100 - ((node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100) > 90
```

### Network interfaces with errors
```promql
rate(node_network_receive_errs_total[5m]) + rate(node_network_transmit_errs_total[5m]) > 0
```

### Disk I/O latency
```promql
rate(node_disk_io_time_seconds_total[5m]) > 0.1
```

---

## Metric Naming Conventions

- **Counters:** `_total` suffix (always increasing)
- **Gauges:** No suffix (can go up or down)
- **Bytes:** `_bytes` suffix
- **Seconds:** `_seconds` suffix
- **Celsius:** `_celsius` suffix
- **Percent:** `_percent` suffix (0-100 range)

For complete documentation, see: https://github.com/prometheus/node_exporter
