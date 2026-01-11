# TimescaleDB - Industrial IoT Time-Series Historian

**Production-ready TimescaleDB for Kubernetes/K3s, optimized for SCADA and industrial sensor data.**

Because your time-series data deserves better than CSV files, Excel spreadsheets, and "just dump it in a folder" strategies.

---

## 🎯 What is TimescaleDB?

TimescaleDB is a **time-series database built on PostgreSQL**, combining the power of SQL with automatic time-series optimizations:

- **Automatic Partitioning**: Data is automatically partitioned into chunks for efficient queries
- **Compression**: Achieve 90%+ compression on historical data with no performance impact
- **Continuous Aggregates**: Pre-computed rollups (hourly, daily, monthly) for lightning-fast dashboards
- **Retention Policies**: Automatically drop old data to manage storage costs
- **Full SQL Support**: Join time-series data with relational tables, use PostgreSQL extensions

**Perfect for:** SCADA historians, sensor monitoring, production metrics, energy management, quality tracking, alarm logging.

---

## 📊 Resource Presets

Choose a preset that matches your deployment scale:

| Preset | Use Case | CPU | RAM | Storage | Max Connections | Compression |
|--------|----------|-----|-----|---------|----------------|-------------|
| **edge** | Raspberry Pi, IoT Gateway | 500m | 1Gi | 20Gi | 50 | ✅ |
| **small** | Dev/Test, Small Sites | 2 | 4Gi | 100Gi | 100 | ✅ |
| **medium** | Standard Production | 4 | 16Gi | 500Gi | 300 | ✅ |
| **large** | High-Volume SCADA | 8 | 32Gi | 1Ti | 500 | ✅ |
| **xlarge** | Enterprise Historian | 16 | 64Gi | 2Ti | 1000 | ✅ |

All presets include automatic compression and retention policies to maximize storage efficiency.

---

## 🚀 Deployment Modes

### Standalone Mode
Single-instance deployment for development, testing, or non-critical production workloads.

**Features:**
- Single StatefulSet with 1 replica
- Persistent storage for data durability
- Automatic backups to PVC, S3, or NFS
- Prometheus metrics and Grafana dashboards

**Best for:** Development environments, edge gateways, non-HA production systems

---

### High Availability (HA) Mode
Multi-replica deployment with PostgreSQL streaming replication for zero-downtime operations.

**Features:**
- StatefulSet with 3+ replicas (configurable)
- Synchronous or asynchronous replication
- Automatic failover (with Patroni/pg_auto_failover)
- Read replicas for query load distribution
- Pod Disruption Budget to prevent cascading failures

**Best for:** Mission-critical SCADA systems, compliance-regulated environments, enterprise historians

---

## 🏭 Pre-configured Industrial IoT Schemas

TimescaleDB comes with **6 pre-configured hypertables** optimized for industrial IoT:

### 1. **Sensor Data** (`scada_historian.sensor_data`)
- **Use Case:** High-frequency sensor data (1-second intervals)
- **Partitioning:** Device ID (4 partitions)
- **Compression:** After 7 days, 90% storage reduction
- **Retention:** 90 days of raw data, then aggregates only
- **Example:** PLC tags, temperature sensors, pressure transmitters

### 2. **Machine Metrics** (`production_metrics.machine_metrics`)
- **Use Case:** Machine performance metrics (per-minute aggregates)
- **Partitioning:** Machine ID (4 partitions)
- **Compression:** After 7 days
- **Retention:** 90 days raw, 1 year hourly, 5 years daily
- **Example:** OEE calculations, cycle times, throughput

### 3. **Energy Consumption** (`energy_management.energy_consumption`)
- **Use Case:** Power usage and demand monitoring (15-minute intervals)
- **Compression:** After 7 days
- **Retention:** 5 years (all data)
- **Example:** kWh tracking, peak demand, power factor

### 4. **Quality Measurements** (`quality_data.quality_measurements`)
- **Use Case:** SPC charts, Cpk calculations, inspection results
- **Compression:** After 30 days
- **Retention:** 5 years (compliance)
- **Example:** Dimensional measurements, defect tracking, first article

### 5. **Alarm History** (`scada_historian.alarm_history`)
- **Use Case:** Alarm and event logging
- **Compression:** After 30 days
- **Retention:** 2 years (audit trail)
- **Example:** PLC alarms, operator actions, system events

### 6. **Production Counts** (`production_metrics.production_counts`)
- **Use Case:** OEE tracking, scrap, downtime
- **Partitioning:** Production line ID (2 partitions)
- **Compression:** After 7 days
- **Retention:** 5 years
- **Example:** Good/bad counts, downtime codes, shift totals

**All hypertables are optional** - enable only what you need via the Rancher wizard.

---

## 🔧 TimescaleDB Features

### Automatic Compression
TimescaleDB automatically compresses chunks older than 7 days (configurable), achieving **90%+ storage reduction** with no query performance impact.

**Compression Stats:**
- Raw sensor data: 1TB → 100GB (90% reduction)
- Machine metrics: 500GB → 50GB (90% reduction)
- Energy data: 200GB → 20GB (90% reduction)

**How it works:**
1. New data is written uncompressed for fast inserts
2. After 7 days, background workers compress chunks
3. Queries transparently decompress data on-the-fly
4. Older aggregates are compressed even further

---

### Continuous Aggregates
Pre-computed rollup tables for lightning-fast dashboards and reports.

**Example: Machine OEE Dashboard**
- Raw data: 1-second intervals (86,400 rows/day/machine)
- Hourly aggregates: 24 rows/day/machine (3,600x fewer rows)
- Daily aggregates: 1 row/day/machine (86,400x fewer rows)

**Performance:**
- Loading a 30-day trend: 0.05 seconds (vs. 45 seconds on raw data)
- Annual OEE report: 0.2 seconds (vs. 15 minutes on raw data)

**Auto-refresh:** Aggregates update every hour (configurable) with only new data processed.

---

### Retention Policies
Automatically drop old data to manage storage costs and compliance requirements.

**Default Retention:**
- Raw sensor data: 90 days
- Hourly aggregates: 1 year
- Daily aggregates: 5 years
- Monthly aggregates: 10 years

**Compliance Example (FDA 21 CFR Part 11):**
- Quality measurements: 5 years raw + 25 years aggregates
- Alarm history: 2 years immutable audit trail
- Production counts: 10 years for ISO 9001 compliance

---

## 💾 Backup & Restore

### Automated Daily Backups
TimescaleDB includes automated pg_dump backups with **TimescaleDB-aware** export:

**Features:**
- Scheduled backups (default: 2 AM daily)
- Configurable retention (default: 7 days)
- Compression (gzip) for reduced storage
- Supports PVC, S3, or NFS destinations
- Includes continuous aggregate definitions

**Backup Sizes (with compression):**
- 1TB database → ~100GB backup (90% compression)
- Backup time: ~30 minutes for 1TB
- Restore time: ~45 minutes for 1TB

**Backup Destinations:**
- **PVC:** Store backups in Kubernetes persistent volumes
- **S3:** AWS S3, MinIO, or S3-compatible storage
- **NFS:** Network file system (NAS, SAN)

---

### Manual Backup
Use the included PowerShell management script:

```powershell
.\scripts\manage-timescaledb.ps1 -Action backup
```

**Backup includes:**
- All databases and schemas
- Hypertable definitions
- Continuous aggregate definitions
- Compression policies
- Retention policies
- User accounts and permissions

---

## 📈 Monitoring & Observability

### Prometheus Metrics
Enable `sidecars.postgresExporter.enabled` for comprehensive metrics:

**TimescaleDB-Specific:**
- Hypertable size and growth rate
- Compression ratios and savings
- Chunk distribution (hot vs. compressed)
- Background job status (compression, retention, aggregates)
- Continuous aggregate lag

**PostgreSQL Standard:**
- Connections and active queries
- Transaction rate and throughput
- Cache hit ratios
- Replication lag (HA mode)
- Disk usage and I/O

---

### Grafana Dashboards
Enable `monitoring.grafana.enabled` for pre-built dashboards:

**Dashboard #455 - PostgreSQL Overview**
- Database connections and activity
- Transaction rates
- Cache performance
- Disk I/O and utilization

**Dashboard #12776 - TimescaleDB Metrics**
- Hypertable size trends
- Compression statistics
- Chunk distribution
- Background worker status
- Query performance

---

## 🔌 Connection Pooling (Optional)

### PgBouncer Sidecar
Enable `sidecars.pgbouncer.enabled` for connection pooling:

**Benefits:**
- Reduce connection overhead (PostgreSQL forks a new process per connection)
- Support 1,000+ client connections with only 25 backend connections
- Faster connection establishment
- Lower memory usage

**Pool Modes:**
- **Session:** Full PostgreSQL features (prepared statements, temp tables)
- **Transaction:** Better pooling, most features work
- **Statement:** Maximum performance, limited features

**Best for:** Web applications, microservices, Node-RED, Telegraf collectors with many instances

---

## 🔒 Security & Compliance

### Security Features
- ✅ Non-root container user (UID 1000)
- ✅ Read-only root filesystem (where applicable)
- ✅ Dropped capabilities (CAP_DROP ALL)
- ✅ Network policies (optional)
- ✅ RBAC for Kubernetes service account
- ✅ TLS support for client connections
- ✅ Auto-generated secure passwords

---

### Compliance Support

#### FDA 21 CFR Part 11
Enable `compliance.fda21CFRPart11.enabled` for:
- Audit trail logging (all data changes)
- Immutable audit tables (append-only, no deletes)
- Electronic signature support
- 25-year data retention (quality, production)
- Data integrity verification (checksums)

**Important:** This chart enables technical controls but doesn't guarantee compliance. Review your organization's validation requirements and SOPs.

---

#### ISO 9001, IATF 16949
- Quality measurement tracking (Cpk, SPC charts)
- Production count history (OEE, scrap, rework)
- Calibration records
- 10-year data retention

---

#### GDPR
- Data anonymization helpers
- Right-to-delete support
- Audit trail for data access
- Encryption at rest (via storage layer)

---

## 🛠️ PowerShell Management Scripts

Included management utilities for Windows environments:

### 1. `manage-timescaledb.ps1`
Comprehensive management operations:

```powershell
# Health check
.\scripts\manage-timescaledb.ps1 -Action health-check

# Compression status and savings
.\scripts\manage-timescaledb.ps1 -Action compression-status

# Manual backup
.\scripts\manage-timescaledb.ps1 -Action backup

# Vacuum database
.\scripts\manage-timescaledb.ps1 -Action vacuum

# View slow queries
.\scripts\manage-timescaledb.ps1 -Action slow-queries
```

---

### 2. `generate-timescaledb-config.ps1`
Generate scenario-based values files:

```powershell
# Edge gateway configuration
.\scripts\generate-timescaledb-config.ps1 -Scenario edge-gateway

# HA production historian
.\scripts\generate-timescaledb-config.ps1 -Scenario production-historian

# Sensor monitoring
.\scripts\generate-timescaledb-config.ps1 -Scenario sensor-monitoring

# Compliance-ready
.\scripts\generate-timescaledb-config.ps1 -Scenario compliance-historian
```

---

### 3. Sample SQL Queries
`scripts/sql/sample-queries.sql` includes 50+ industrial IoT query examples:

- 5-minute sensor averages
- Machine OEE calculations
- Energy demand analysis
- SPC chart (Cpk) calculations
- Alarm frequency reports
- Production shift totals

---

## 📚 Example Configurations

Pre-built configurations in the `examples/` directory:

### 1. **Edge Gateway** (`edge-gateway.yaml`)
Raspberry Pi 4 deployment with minimal resources:
- 500m CPU, 1Gi RAM, 20Gi storage
- 50 max connections
- 30-day retention
- Compression after 3 days
- PVC backups

---

### 2. **HA Production Historian** (`ha-production-historian.yaml`)
Mission-critical SCADA historian:
- 3 replicas with synchronous replication
- 8 CPU, 32Gi RAM, 1Ti storage
- 500 max connections
- 90-day raw + 5-year aggregates
- S3 backups

---

### 3. **Sensor Monitoring** (`sensor-monitoring.yaml`)
High-frequency sensor data collection:
- 4 CPU, 16Gi RAM, 500Gi storage
- 1-second sensor intervals
- Compression after 7 days
- Continuous aggregates (hourly, daily)
- PVC backups

---

## 🔍 When to Use TimescaleDB vs. InfluxDB vs. PostgreSQL

### Use TimescaleDB When:
- ✅ You need **SQL joins** between time-series and relational data
- ✅ You want **PostgreSQL compatibility** (extensions, tools, expertise)
- ✅ You need **long-term compliance** (FDA, ISO 9001, 21 years+)
- ✅ Your team already knows SQL
- ✅ You want **automatic compression** with no query changes

### Use InfluxDB When:
- ✅ Pure time-series data (no joins needed)
- ✅ Ultra-high write throughput (millions of points/second)
- ✅ Short-term retention (days to months)
- ✅ InfluxQL/Flux query language preference

### Use PostgreSQL When:
- ✅ Primarily relational data (customers, orders, inventory)
- ✅ Complex transactions (ACID guarantees)
- ✅ Time-series is a small portion of your data
- ✅ No need for automatic partitioning

**Pro tip:** Use all three! TimescaleDB for SCADA historian, InfluxDB for high-frequency metrics, PostgreSQL for ERP/MES relational data.

---

## 🚀 Quick Start Examples

### Minimal Dev/Test Deployment
```powershell
helm upgrade --install timescaledb fireball-industries/timescaledb-pod \
  --namespace databases \
  --create-namespace \
  --set preset=small \
  --set backup.enabled=false
```

---

### Production SCADA Historian
```powershell
helm upgrade --install tsdb-prod fireball-industries/timescaledb-pod \
  --namespace databases \
  --create-namespace \
  --set preset=large \
  --set mode=ha \
  --set replicaCount=3 \
  --set backup.destination.type=s3 \
  --set backup.destination.s3.bucket=my-backups
```

---

### Edge Gateway (Raspberry Pi)
```powershell
helm upgrade --install tsdb-edge fireball-industries/timescaledb-pod \
  --namespace databases \
  --create-namespace \
  --set preset=edge \
  --set timescaledb.retention.rawData="30 days" \
  --set persistence.size=20Gi
```

---

## 🔧 Accessing TimescaleDB

### From Within Kubernetes
```powershell
# Get the password
$password = kubectl get secret timescaledb-secret -n databases -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }

# Connect via psql
kubectl exec -it deployment/timescaledb -n databases -- psql -U tsadmin -d tsdb
```

---

### From External Applications
```yaml
# Connection string (ClusterIP)
postgresql://tsadmin:password@timescaledb.databases.svc.cluster.local:5432/tsdb

# Connection string (PgBouncer, if enabled)
postgresql://tsadmin:password@timescaledb.databases.svc.cluster.local:6432/tsdb
```

---

### Port Forwarding (Development)
```powershell
kubectl port-forward -n databases service/timescaledb 5432:5432

# Connect from localhost
psql -h localhost -U tsadmin -d tsdb
```

---

## 📊 Performance Expectations

### Write Performance
- **Sensor data (1-second intervals):** 10,000 inserts/second (single node)
- **Batch inserts (COPY):** 100,000+ rows/second
- **HA mode overhead:** ~10% (synchronous replication)

### Query Performance
- **Last 1 hour (raw data):** < 0.1 seconds
- **Last 24 hours (hourly aggregates):** < 0.05 seconds
- **Last 30 days (daily aggregates):** < 0.05 seconds
- **Last 1 year (monthly aggregates):** < 0.1 seconds

### Storage Efficiency
- **Raw sensor data:** ~50 bytes/row (uncompressed)
- **After compression:** ~5 bytes/row (90% reduction)
- **1 billion rows:** ~50GB compressed

---

## 🆘 Troubleshooting

### Out of Disk Space?
```powershell
# Run vacuum to reclaim space
.\scripts\manage-timescaledb.ps1 -Action vacuum

# Check compression status
.\scripts\manage-timescaledb.ps1 -Action compression-status

# Adjust retention policies
kubectl exec -it deployment/timescaledb -n databases -- psql -U tsadmin -d tsdb -c "SELECT drop_chunks('sensor_data', INTERVAL '60 days');"
```

---

### Slow Queries?
```powershell
# View slow query log
.\scripts\manage-timescaledb.ps1 -Action slow-queries

# Check indexes
kubectl exec -it deployment/timescaledb -n databases -- psql -U tsadmin -d tsdb -c "\di+ scada_historian.*"

# Analyze table statistics
kubectl exec -it deployment/timescaledb -n databases -- psql -U tsadmin -d tsdb -c "ANALYZE VERBOSE sensor_data;"
```

---

### Compression Not Working?
```powershell
# Check compression policies
kubectl exec -it deployment/timescaledb -n databases -- psql -U tsadmin -d tsdb -c "SELECT * FROM timescaledb_information.compression_settings;"

# Manually trigger compression
kubectl exec -it deployment/timescaledb -n databases -- psql -U tsadmin -d tsdb -c "CALL compress_chunks_policy('sensor_data');"
```

---

### HA Replication Lag?
```powershell
# Check replication status
kubectl exec -it timescaledb-0 -n databases -- psql -U tsadmin -d tsdb -c "SELECT * FROM pg_stat_replication;"

# Check WAL lag
kubectl logs -n databases timescaledb-1 | grep -i "lag"
```

---

## 📖 Additional Resources

- **TimescaleDB Documentation:** https://docs.timescale.com/
- **PostgreSQL Documentation:** https://www.postgresql.org/docs/
- **Chart Source Code:** https://github.com/fireball-industries/timescaledb-helm
- **Grafana Dashboard #12776:** https://grafana.com/grafana/dashboards/12776
- **Sample Queries:** See `scripts/sql/sample-queries.sql` in chart

---

## 📝 License

MIT License - See chart LICENSE file for details.

---

**Remember:** Your industrial IoT data is now in a proper time-series database with automatic compression, retention policies, and continuous aggregates. You can finally delete that 500MB Excel file that crashes every time someone opens it. You're welcome. 🎉

*Pro tip:* Test in dev first, or live dangerously. We're not judging (but we're definitely backing up our data). 🔥
