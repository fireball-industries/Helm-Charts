# Quick Reference - TimescaleDB Helm Chart

**Common commands, SQL snippets, and troubleshooting for daily operations.**

---

## 🚀 Quick Deploy

```powershell
# Standard production
helm upgrade --install timescaledb . --namespace databases --create-namespace

# With custom preset
helm upgrade --install timescaledb . --set preset=large

# With custom values
helm upgrade --install timescaledb . --values my-values.yaml
```

---

## 🔑 Get Password

```powershell
kubectl get secret timescaledb-secret -n databases -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
```

---

## 🔌 Connect to Database

```powershell
# Exec into pod
kubectl exec -it deployment/timescaledb -n databases -- psql -U tsadmin -d tsdb

# Port forward (local access)
kubectl port-forward svc/timescaledb -n databases 5432:5432
psql -h localhost -U tsadmin -d tsdb
```

---

## 📊 Common SQL Commands

### View Hypertables
```sql
SELECT * FROM timescaledb_information.hypertables;
```

### View Compression Stats
```sql
SELECT
  hypertable_schema || '.' || hypertable_name AS hypertable,
  pg_size_pretty(before_compression_total_bytes) AS before,
  pg_size_pretty(after_compression_total_bytes) AS after,
  ROUND(100 * (1 - after_compression_total_bytes::NUMERIC / before_compression_total_bytes), 2) AS compression_ratio
FROM timescaledb_information.hypertables h
LEFT JOIN LATERAL hypertable_compression_stats(format('%I.%I', hypertable_schema, hypertable_name)) ON true
WHERE before_compression_total_bytes > 0;
```

### View Chunks
```sql
SELECT
  hypertable_name,
  COUNT(*) AS chunk_count,
  pg_size_pretty(SUM(total_bytes)) AS total_size
FROM timescaledb_information.chunks
GROUP BY hypertable_name;
```

### View Background Jobs
```sql
SELECT
  job_id,
  application_name,
  schedule_interval,
  job_status,
  last_run_status,
  next_start
FROM timescaledb_information.jobs
ORDER BY job_id;
```

### Latest Sensor Values
```sql
SELECT DISTINCT ON (sensor_type)
  sensor_type,
  time,
  value
FROM scada_historian.sensor_data
WHERE device_id = 'PLC-001'
ORDER BY sensor_type, time DESC;
```

### Time-Bucketed Average
```sql
SELECT
  time_bucket('5 minutes', time) AS bucket,
  AVG(value) AS avg_value
FROM scada_historian.sensor_data
WHERE time > NOW() - INTERVAL '1 hour'
  AND device_id = 'PLC-001'
GROUP BY bucket
ORDER BY bucket DESC;
```

---

## 🛠️ PowerShell Management

```powershell
# Health check
.\scripts\manage-timescaledb.ps1 -Action health-check

# Compression status
.\scripts\manage-timescaledb.ps1 -Action compression-status

# Hypertable info
.\scripts\manage-timescaledb.ps1 -Action hypertable-info

# Trigger backup
.\scripts\manage-timescaledb.ps1 -Action backup

# View logs
.\scripts\manage-timescaledb.ps1 -Action logs -Follow

# Vacuum
.\scripts\manage-timescaledb.ps1 -Action vacuum
```

---

## 🐛 Troubleshooting

### Pod Not Starting
```powershell
kubectl describe pod timescaledb-0 -n databases
kubectl logs timescaledb-0 -n databases --tail=100
```

### Check Resources
```powershell
kubectl top pod -n databases
kubectl get pvc -n databases
```

### Database Connection Failed
```sql
-- Check if database is accepting connections
SELECT pg_is_in_recovery();

-- Check active connections
SELECT * FROM pg_stat_activity;
```

### Out of Disk Space
```sql
-- Check database size
SELECT pg_database.datname, pg_size_pretty(pg_database_size(pg_database.datname))
FROM pg_database;

-- Check table sizes
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 20;

-- Run vacuum
VACUUM (VERBOSE, ANALYZE);
```

### Compression Not Working
```sql
-- Check compression policies
SELECT * FROM timescaledb_information.jobs
WHERE proc_name = 'policy_compression';

-- Manually compress chunks
SELECT compress_chunk(i) FROM show_chunks('scada_historian.sensor_data') i;
```

---

## 📈 Monitoring Queries

### Database Health
```sql
SELECT
  pg_database_size(current_database()) / (1024*1024*1024) AS db_size_gb,
  (SELECT COUNT(*) FROM pg_stat_activity) AS active_connections,
  (SELECT COUNT(*) FROM pg_stat_activity WHERE state = 'active') AS active_queries;
```

### Slow Queries
```sql
SELECT
  SUBSTRING(query, 1, 100) AS query,
  calls,
  ROUND(mean_exec_time::NUMERIC, 2) AS avg_ms
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 20;
```

### Replication Lag (HA mode)
```sql
SELECT
  client_addr,
  state,
  pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) AS lag
FROM pg_stat_replication;
```

---

## 🔄 Maintenance

### Vacuum
```sql
VACUUM (VERBOSE, ANALYZE);
```

### Analyze
```sql
ANALYZE VERBOSE;
```

### Refresh Continuous Aggregates
```sql
CALL refresh_continuous_aggregate('sensor_data_hourly', NULL, NULL);
```

### Manually Run Retention
```sql
CALL run_job((SELECT job_id FROM timescaledb_information.jobs WHERE proc_name = 'policy_retention' LIMIT 1));
```

---

## 🔧 Configuration Changes

### Update Resource Preset
```powershell
helm upgrade timescaledb . --set preset=xlarge --reuse-values
```

### Change Backup Schedule
```powershell
helm upgrade timescaledb . --set backup.schedule="0 3 * * *" --reuse-values
```

### Enable Monitoring
```powershell
helm upgrade timescaledb . --set monitoring.serviceMonitor.enabled=true --reuse-values
```

---

## 📦 Backup & Restore

### Manual Backup
```powershell
# Create job from CronJob
kubectl create job timescaledb-backup-$(Get-Date -Format 'yyyyMMddHHmmss') --from=cronjob/timescaledb-backup -n databases
```

### Restore from Backup
```powershell
# Copy backup to pod
kubectl cp backup.sql.gz databases/timescaledb-0:/tmp/

# Restore
kubectl exec -it timescaledb-0 -n databases -- bash -c "gunzip -c /tmp/backup.sql.gz | psql -U tsadmin -d tsdb"
```

---

## 🎯 Resource Presets Quick Reference

| Preset | CPU | RAM | Storage | Use Case |
|--------|-----|-----|---------|----------|
| edge | 500m | 1Gi | 20Gi | Raspberry Pi |
| small | 2 | 4Gi | 100Gi | Dev/Test |
| medium | 4 | 16Gi | 500Gi | Production |
| large | 8 | 32Gi | 1Ti | High-Volume |
| xlarge | 16 | 64Gi | 2Ti | Enterprise |

---

## 🔗 Useful Links

- TimescaleDB Docs: https://docs.timescale.com/
- PostgreSQL Docs: https://www.postgresql.org/docs/
- Helm Docs: https://helm.sh/docs/
- Kubernetes Docs: https://kubernetes.io/docs/

---

**Pro tip**: Bookmark this page. You'll need it when production goes sideways at 3 AM. 🔥
