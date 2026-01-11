# 🔥 TimescaleDB Helm Chart for Industrial IoT/SCADA

**Production-ready TimescaleDB deployment for Kubernetes/K3s, optimized for industrial time-series data.**

Because your sensor data deserves better than Excel spreadsheets and CSV files on network shares.

[![Helm Version](https://img.shields.io/badge/Helm-v3-blue)](https://helm.sh/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![TimescaleDB](https://img.shields.io/badge/TimescaleDB-2.14.2-orange)](https://www.timescale.com/)

---

## 🚀 Quick Start (30-Second Deployment)

```powershell
# Deploy with medium preset (standard production)
helm upgrade --install timescaledb . --namespace databases --create-namespace

# Get the database password
kubectl get secret timescaledb-secret -n databases -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }

# Connect to the database
kubectl exec -it deployment/timescaledb -n databases -- psql -U tsadmin -d tsdb
```

**That's it!** You now have a production-ready TimescaleDB instance with:
- ✅ Pre-configured hypertables for industrial IoT data
- ✅ Automatic compression (7-day default)
- ✅ Data retention policies (90 days → 10 years depending on data type)
- ✅ Continuous aggregates (hourly, daily, monthly rollups)
- ✅ Automated backups (daily at 2 AM)
- ✅ Prometheus metrics

---

## ✨ Features

- **5 Resource Presets**: edge (Raspberry Pi) → xlarge (enterprise historian)
- **High Availability**: StatefulSet with streaming replication
- **Industrial Schemas**: SCADA historian, production metrics, quality data, energy management
- **Compliance**: FDA 21 CFR Part 11, ISO 9001, GDPR support
- **Monitoring**: Prometheus ServiceMonitor, Grafana dashboards
- **PowerShell Scripts**: Comprehensive management and testing utilities
- **15+ Kubernetes Templates**: Full production-ready deployment

---

## 🎯 Resource Presets

| Preset | Use Case | CPU | RAM | Storage | Max Connections |
|--------|----------|-----|-----|---------|----------------|
| **edge** | Raspberry Pi, IoT Gateway | 500m | 1Gi | 20Gi | 50 |
| **small** | Dev/Test, Small Sites | 2 | 4Gi | 100Gi | 100 |
| **medium** | Standard Production | 4 | 16Gi | 500Gi | 300 |
| **large** | High-Volume SCADA | 8 | 32Gi | 1Ti | 500 |
| **xlarge** | Enterprise Historian | 16 | 64Gi | 2Ti | 1000 |

```powershell
helm upgrade --install timescaledb . --set preset=large
```

---

## 🏭 Industrial IoT Schemas

Pre-configured hypertables:
- **sensor_data**: High-frequency sensor data (1-second intervals)
- **machine_metrics**: Machine performance metrics
- **energy_consumption**: Power usage and demand monitoring
- **quality_measurements**: SPC charts, Cpk calculations
- **alarm_history**: Alarm and event logging
- **production_counts**: OEE tracking, scrap, downtime

**Example query:**
```sql
SELECT time_bucket('5 minutes', time) AS bucket,
       device_id,
       AVG(value) AS avg_value
FROM scada_historian.sensor_data
WHERE time > NOW() - INTERVAL '1 hour'
GROUP BY bucket, device_id;
```

See [scripts/sql/sample-queries.sql](scripts/sql/sample-queries.sql) for 50+ industrial IoT query examples.

---

## 🛠️ PowerShell Management Scripts

```powershell
# Health check
.\scripts\manage-timescaledb.ps1 -Action health-check

# Compression status
.\scripts\manage-timescaledb.ps1 -Action compression-status

# Trigger manual backup
.\scripts\manage-timescaledb.ps1 -Action backup

# Generate scenario-based config
.\scripts\generate-timescaledb-config.ps1 -Scenario sensor-monitoring
```

---

## 📚 Example Configurations

Pre-built configurations in [examples/](examples/):
1. **minimal-timescaledb.yaml**: Dev/test minimal setup
2. **sensor-monitoring.yaml**: High-frequency sensor monitoring
3. **ha-production-historian.yaml**: HA SCADA historian
4. **edge-gateway.yaml**: Raspberry Pi edge deployment
5. **analytics-warehouse.yaml**: Long-term analytics
6. **compliance-historian.yaml**: FDA 21 CFR Part 11 compliant

```powershell
helm upgrade --install timescaledb . --values examples/sensor-monitoring.yaml
```

---

## 🔄 High Availability

```yaml
mode: ha
replicaCount: 3
synchronousCommit: "local"
```

Includes:
- Streaming replication
- Automatic failover (with Patroni/pg_auto_failover)
- Read replicas for query load distribution
- Synchronous replication for critical data

---

## 💾 Backup & Restore

Automated daily backups with TimescaleDB-aware pg_dump:

```yaml
backup:
  enabled: true
  schedule: "0 2 * * *"
  retention: 7
  destination:
    type: pvc  # or s3, nfs
```

Manual backup:
```powershell
.\scripts\manage-timescaledb.ps1 -Action backup
```

---

## 📊 Monitoring

Prometheus metrics via postgres_exporter:
- Hypertable size and growth
- Compression ratios
- Chunk distribution
- Background job status
- Query performance

Grafana dashboards (IDs: 455, 12776) included.

---

## 🔒 Compliance

**FDA 21 CFR Part 11:**
```yaml
compliance:
  fda21CFRPart11:
    enabled: true
    auditLogging: true
    immutableAuditTables: true
```

Features: Audit trail, electronic signatures, data integrity, 25-year retention

**Important**: Enables compliance features but doesn't guarantee compliance. Review [SECURITY.md](SECURITY.md) for complete checklists.

---

## 🚀 Quick Deploy Scenarios

```powershell
# Edge gateway (Raspberry Pi)
.\scripts\generate-timescaledb-config.ps1 -Scenario edge-gateway
helm upgrade --install tsdb-edge . --values values-edge-gateway.yaml

# Production historian with HA
.\scripts\generate-timescaledb-config.ps1 -Scenario production-historian
helm upgrade --install tsdb-prod . --values values-production-historian.yaml --set mode=ha

# Compliance-ready
.\scripts\generate-timescaledb-config.ps1 -Scenario compliance-historian
helm upgrade --install tsdb-fda . --values values-compliance-historian.yaml
```

---

## 🐛 Troubleshooting

**Compression not working?**
```powershell
.\scripts\manage-timescaledb.ps1 -Action compression-status
```

**Out of disk space?**
```powershell
.\scripts\manage-timescaledb.ps1 -Action vacuum
```

**Slow queries?**
See [TIMESCALEDB_GUIDE.md](TIMESCALEDB_GUIDE.md) for optimization tips.

---

## 📜 License

MIT License - see [LICENSE](LICENSE)

---

**Pro tip**: Your SCADA data is now in a proper time-series database. You can finally delete that 500MB Excel file that's been crashing every time someone opens it. You're welcome. 🎉

**Remember**: Test in dev first, or live dangerously. We're not judging (but we're definitely backing up our own data).
