# Node Exporter Collectors Reference

Complete reference for all Prometheus Node Exporter collectors supported by the Fireball Industries Helm chart.

## Table of Contents

- [Default Enabled Collectors](#default-enabled-collectors)
- [Optional Collectors](#optional-collectors)
- [Collector Configuration](#collector-configuration)
- [Performance Impact](#performance-impact)
- [Industrial Use Cases](#industrial-use-cases)

## Default Enabled Collectors

These collectors are enabled by default in the `edge-standard` preset:

### cpu
**Exposes**: CPU time statistics by core and mode

**Metrics**:
- `node_cpu_seconds_total{cpu, mode}` - Total CPU time in seconds

**Modes**: idle, iowait, irq, nice, softirq, steal, system, user

**Use Case**: CPU utilization monitoring, identifying CPU-bound workloads

**PromQL Examples**:
```promql
# CPU usage percentage
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# CPU usage by mode
rate(node_cpu_seconds_total{mode!="idle"}[5m])
```

### cpufreq
**Exposes**: CPU frequency scaling information

**Metrics**:
- `node_cpu_frequency_hertz` - Current CPU frequency
- `node_cpu_frequency_max_hertz` - Maximum CPU frequency
- `node_cpu_frequency_min_hertz` - Minimum CPU frequency

**Use Case**: Power management, thermal throttling detection

**Performance**: Negligible

---

### diskstats
**Exposes**: Disk I/O statistics from `/proc/diskstats`

**Metrics**:
- `node_disk_read_bytes_total{device}` - Total bytes read
- `node_disk_written_bytes_total{device}` - Total bytes written
- `node_disk_reads_completed_total{device}` - Total read operations
- `node_disk_writes_completed_total{device}` - Total write operations
- `node_disk_io_time_seconds_total{device}` - Total I/O time (for latency calculation)

**Use Case**: Disk I/O monitoring, SSD wear tracking, bottleneck identification

**Industrial Edge**: Critical for SSD wear monitoring in 24/7 operations

**PromQL Examples**:
```promql
# Disk I/O latency
rate(node_disk_io_time_seconds_total{device="sda"}[5m])

# Write rate
rate(node_disk_written_bytes_total[5m])
```

**Configuration**:
```yaml
collectors:
  collectorArgs:
    diskstats:
      device-exclude: "^(ram|loop|fd|(h|s|v|xv)d[a-z]|nvme\\d+n\\d+p)\\d+$"
```

---

### filesystem
**Exposes**: Filesystem usage and availability

**Metrics**:
- `node_filesystem_size_bytes{mountpoint, fstype}` - Total filesystem size
- `node_filesystem_avail_bytes{mountpoint, fstype}` - Available space
- `node_filesystem_files{mountpoint, fstype}` - Total inodes
- `node_filesystem_files_free{mountpoint, fstype}` - Free inodes

**Use Case**: Disk space monitoring, capacity planning, inode exhaustion prevention

**PromQL Examples**:
```promql
# Filesystem usage percentage
100 - ((node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100)

# Predict disk full (linear prediction)
predict_linear(node_filesystem_avail_bytes{mountpoint="/"}[1h], 24*3600) < 0
```

**Configuration**:
```yaml
collectors:
  collectorArgs:
    filesystem:
      mount-points-exclude: "^/(dev|proc|sys|var/lib/docker/.+|var/lib/kubelet/.+)($|/)"
      fs-types-exclude: "^(autofs|binfmt_misc|bpf|cgroup2?|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|iso9660|mqueue|nsfs|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|selinuxfs|squashfs|sysfs|tracefs)$"
```

---

### hwmon
**Exposes**: Hardware monitoring sensors (temperature, fans, voltage)

**Metrics**:
- `node_hwmon_temp_celsius{chip, sensor}` - Temperature in Celsius
- `node_hwmon_fan_rpm{chip, sensor}` - Fan speed in RPM
- `node_hwmon_in_volts{chip, sensor}` - Voltage readings

**Use Case**: Temperature monitoring, hardware health, thermal management

**Industrial Edge**: **CRITICAL** for devices in enclosures or harsh environments

**PromQL Examples**:
```promql
# Maximum temperature
max(node_hwmon_temp_celsius)

# Temperature warning
node_hwmon_temp_celsius > 70
```

**Alert**:
```yaml
- alert: HighTemperature
  expr: node_hwmon_temp_celsius > 70
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "High temperature on {{ $labels.instance }}"
    description: "Temperature is {{ $value }}°C (threshold: 70°C)"
```

---

### loadavg
**Exposes**: System load average

**Metrics**:
- `node_load1` - 1-minute load average
- `node_load5` - 5-minute load average
- `node_load15` - 15-minute load average

**Use Case**: System overload detection, capacity planning

**PromQL Examples**:
```promql
# Load average normalized by CPU count
node_load1 / count(node_cpu_seconds_total{mode="idle"})

# High load alert
node_load5 > count(node_cpu_seconds_total{mode="idle"}) * 2
```

---

### meminfo
**Exposes**: Memory statistics from `/proc/meminfo`

**Key Metrics**:
- `node_memory_MemTotal_bytes` - Total memory
- `node_memory_MemAvailable_bytes` - Available memory
- `node_memory_MemFree_bytes` - Free memory
- `node_memory_Buffers_bytes` - Buffer cache
- `node_memory_Cached_bytes` - Page cache
- `node_memory_SwapTotal_bytes` - Total swap
- `node_memory_SwapFree_bytes` - Free swap

**Use Case**: Memory usage monitoring, OOM prediction

**PromQL Examples**:
```promql
# Memory usage percentage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Memory pressure
node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes < 0.1
```

---

### netdev
**Exposes**: Network interface statistics

**Metrics**:
- `node_network_receive_bytes_total{device}` - Bytes received
- `node_network_transmit_bytes_total{device}` - Bytes transmitted
- `node_network_receive_packets_total{device}` - Packets received
- `node_network_transmit_packets_total{device}` - Packets transmitted
- `node_network_receive_errs_total{device}` - Receive errors
- `node_network_transmit_errs_total{device}` - Transmit errors
- `node_network_receive_drop_total{device}` - Dropped received packets
- `node_network_transmit_drop_total{device}` - Dropped transmitted packets

**Use Case**: Network throughput, error monitoring, saturation detection

**Industrial Edge**: Important for detecting cabling issues, switch problems

**PromQL Examples**:
```promql
# Network throughput
rate(node_network_receive_bytes_total{device="eth0"}[5m])

# Error rate
rate(node_network_receive_errs_total[5m]) / rate(node_network_receive_packets_total[5m])
```

**Configuration**:
```yaml
collectors:
  collectorArgs:
    netdev:
      device-exclude: "^(veth.*|docker.*|br-.*|lo)$"
```

---

### netstat
**Exposes**: Network connection statistics

**Metrics**:
- `node_netstat_Tcp_CurrEstab` - Current TCP connections
- `node_netstat_Tcp_InSegs` - TCP segments received
- `node_netstat_Tcp_OutSegs` - TCP segments sent
- `node_netstat_Tcp_RetransSegs` - TCP retransmissions
- `node_netstat_Udp_InDatagrams` - UDP datagrams received
- `node_netstat_Udp_OutDatagrams` - UDP datagrams sent

**Use Case**: Network health, connection tracking, retransmission monitoring

---

### stat
**Exposes**: System statistics from `/proc/stat`

**Metrics**:
- `node_context_switches_total` - Context switches
- `node_intr_total` - Interrupts
- `node_forks_total` - Processes forked
- `node_boot_time_seconds` - Boot time (Unix timestamp)

**Use Case**: System performance, uptime tracking

---

### time
**Exposes**: System time

**Metrics**:
- `node_time_seconds` - Current system time (Unix timestamp)

**Use Case**: Time drift detection, clock synchronization monitoring

---

### uname
**Exposes**: System information

**Metrics**:
- `node_uname_info{machine, nodename, release, sysname, version}` - System information

**Use Case**: Inventory, OS version tracking

---

### vmstat
**Exposes**: Virtual memory statistics

**Metrics**:
- `node_vmstat_pgpgin` - Pages paged in
- `node_vmstat_pgpgout` - Pages paged out
- `node_vmstat_pswpin` - Swap pages in
- `node_vmstat_pswpout` - Swap pages out

**Use Case**: Memory pressure, swap activity monitoring

## Optional Collectors

Enable these collectors as needed for specific use cases:

### systemd
**Enable**: `collectors.optional.systemd: true`

**Exposes**: Systemd unit states

**Metrics**:
- `node_systemd_unit_state{name, state, type}` - Unit state (active, inactive, failed)
- `node_systemd_system_running` - System state

**Use Case**: Service health monitoring, failed unit detection

**Performance Impact**: Medium (queries systemd on each scrape)

**PromQL Examples**:
```promql
# Failed units
node_systemd_unit_state{state="failed"}

# Inactive services that should be active
node_systemd_unit_state{state="inactive",name=~"important-service.*"}
```

---

### processes
**Enable**: `collectors.optional.processes: true`

**Exposes**: Per-process metrics

**Metrics**:
- `node_processes_state{state}` - Process count by state
- `node_processes_threads` - Total thread count

**States**: running, sleeping, stopped, zombie, idle

**Use Case**: Process monitoring, zombie process detection

**Performance Impact**: Low

---

### textfile
**Enable**: `collectors.optional.textfile: true`

**Exposes**: Custom metrics from `.prom` files

**Configuration**:
```yaml
collectors:
  optional:
    textfile: true
  collectorArgs:
    textfile:
      directory: "/var/lib/node_exporter/textfile_collector"
```

**Use Case**: Custom metrics from scripts, batch jobs, external tools

**Example**:
```bash
echo 'backup_last_success_timestamp 1737446400' > \
  /var/lib/node_exporter/textfile_collector/backup.prom
```

See `textfile-examples/` directory for complete examples.

**Performance Impact**: Low (files read on each scrape)

---

### ntp
**Enable**: `collectors.optional.ntp: true`

**Exposes**: NTP time synchronization status

**Metrics**:
- `node_ntp_offset_seconds` - Time offset from NTP server
- `node_ntp_stratum` - NTP stratum

**Use Case**: Time synchronization monitoring, drift detection

**Industrial Edge**: Important when devices lack reliable time sources

**Performance Impact**: Low-Medium (queries NTP server)

---

### tcpstat
**Enable**: `collectors.optional.tcpstat: true`

**Exposes**: TCP connection state counts

**Metrics**:
- `node_tcp_connection_states{state}` - Connection count by state

**States**: established, syn_sent, syn_recv, fin_wait1, fin_wait2, time_wait, close, close_wait, last_ack, listen, closing

**Use Case**: Connection tracking, TIME_WAIT monitoring

**Performance Impact**: Low

---

### interrupts
**Enable**: `collectors.optional.interrupts: true`

**Exposes**: Interrupt statistics

**Metrics**:
- `node_interrupts_total{cpu, type}` - Total interrupts by CPU and type

**Use Case**: Hardware diagnostics, IRQ load balancing

**Performance Impact**: Medium (high metric cardinality)

---

### thermal_zone
**Enable**: `collectors.optional.thermal_zone: true`

**Exposes**: Thermal zone temperatures

**Metrics**:
- `node_thermal_zone_temp{type, zone}` - Temperature in Celsius

**Use Case**: Temperature monitoring (alternative to hwmon)

**Industrial Edge**: **CRITICAL** for embedded devices, edge hardware

**Performance Impact**: Low

**PromQL Examples**:
```promql
# Maximum thermal zone temperature
max(node_thermal_zone_temp)

# Critical temperature
node_thermal_zone_temp > 80
```

---

### ethtool
**Enable**: `collectors.optional.ethtool: true`

**Exposes**: NIC statistics from ethtool

**Requires**: Elevated privileges (CAP_NET_ADMIN)

**Metrics**: NIC-specific statistics

**Use Case**: Advanced network diagnostics, NIC health

**Performance Impact**: Medium

**Security Note**: Requires additional capabilities

---

### rapl
**Enable**: `collectors.optional.rapl: true`

**Exposes**: Intel RAPL power consumption

**Metrics**:
- `node_rapl_package_joules_total` - Energy consumption

**Use Case**: Power monitoring on Intel CPUs

**Performance Impact**: Low

**Hardware**: Intel CPUs with RAPL support

## Collector Configuration

### Filesystem Filtering

Exclude virtual/temporary filesystems:

```yaml
collectors:
  collectorArgs:
    filesystem:
      mount-points-exclude: "^/(dev|proc|sys|var/lib/docker/.+|var/lib/kubelet/.+)($|/)"
      fs-types-exclude: "^(autofs|binfmt_misc|bpf|cgroup2?|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|iso9660|mqueue|nsfs|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|selinuxfs|squashfs|sysfs|tracefs)$"
```

### Network Interface Filtering

Exclude virtual interfaces:

```yaml
collectors:
  collectorArgs:
    netdev:
      device-exclude: "^(veth.*|docker.*|br-.*|lo)$"
    netclass:
      ignored-devices: "^(veth.*|docker.*|br-.*|lo)$"
```

### Disk Device Filtering

Exclude partitions and loop devices:

```yaml
collectors:
  collectorArgs:
    diskstats:
      device-exclude: "^(ram|loop|fd|(h|s|v|xv)d[a-z]|nvme\\d+n\\d+p)\\d+$"
```

## Performance Impact

| Collector | CPU Impact | Memory Impact | Scrape Time | Notes |
|-----------|------------|---------------|-------------|-------|
| cpu | Low | Low | <10ms | Essential |
| diskstats | Low | Low | <20ms | Essential |
| filesystem | Low | Low | <50ms | Depends on mount count |
| hwmon | Low | Low | <10ms | Hardware-dependent |
| meminfo | Low | Low | <5ms | Essential |
| netdev | Low | Low | <20ms | Essential |
| systemd | Medium | Medium | 50-200ms | Query systemd |
| processes | Low | Low | <20ms | Lightweight |
| textfile | Low | Low | <50ms | Depends on file count |
| interrupts | Medium | High | <50ms | High cardinality |
| ethtool | Medium | Medium | 50-100ms | Per-interface queries |

**Recommendation**: Start with defaults, add collectors as needed. Disable unused collectors on resource-constrained devices.

## Industrial Use Cases

### Edge Device Monitoring

```yaml
resourcePreset: edge-standard

collectors:
  optional:
    thermal_zone: true  # Temperature is critical!
    textfile: true      # Custom metrics from PLCs, etc.
    ntp: false          # May not have reliable NTP
```

**Focus**: Temperature, disk wear, network reliability

### Server Monitoring

```yaml
resourcePreset: server

collectors:
  optional:
    systemd: true       # Service health
    processes: true     # Process tracking
    ntp: true          # Time sync
    rapl: true         # Power consumption
```

**Focus**: Service health, resource utilization, power efficiency

### Raspberry Pi / IoT

```yaml
resourcePreset: edge-minimal

collectors:
  enabled:
    - cpu
    - meminfo
    - diskstats
    - filesystem
    - netdev
  optional:
    thermal_zone: true  # Raspberry Pi has thermal zones
```

**Focus**: Minimal overhead, essential metrics only

---

**Remember**: More collectors = more overhead. Enable what you need, disable what you don't.

For complete metric reference, see [METRICS_REFERENCE.md](METRICS_REFERENCE.md).
