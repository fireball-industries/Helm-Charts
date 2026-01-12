# Database Charts Review - Industrial IoT Optimization

**Review Date:** January 12, 2026  
**Reviewer:** AI Assistant  
**Charts Reviewed:** InfluxDB, PostgreSQL, TimescaleDB, SQLite

## Executive Summary

All four database charts are well-configured for industrial use with the following status:

✅ **GOOD**: Persistent storage, resource presets, HA modes  
⚠️ **NEEDS ATTENTION**: Service discovery documentation, cross-pod integration examples  
✅ **EXCELLENT**: Security contexts, monitoring integration

---

## 1. InfluxDB Pod

### ✅ Strengths

1. **Industrial-Focused Configuration**
   - Pre-configured buckets for sensors, SCADA, production, energy, quality
   - Retention policies aligned with compliance (2-7 years for quality/energy)
   - Automatic downsampling (hot/warm/cold tiers)

2. **Persistent Storage**
   - Enabled by default (`persistence.enabled: true`)
   - Retention on delete (`retainOnDelete: true`)
   - Supports multiple storage classes

3. **Resource Optimization**
   - 5 presets: edge (256Mi) → xlarge (16Gi)
   - Tuned for sensor count (5 → 1000+ sensors)
   - Storage engine optimization (WAL, TSM compaction)

4. **High Availability**
   - StatefulSet with odd replicas (3, 5, 7)
   - Pod disruption budget
   - Anti-affinity for node distribution

5. **Service Exposure**
   - Service name: `influxdb-pod` (ClusterIP by default)
   - Port: 8086
   - **DNS**: `influxdb-pod.<namespace>.svc.cluster.local:8086`

### ⚠️ Recommendations

1. **Add Example Integration Section**
   ```yaml
   # RECOMMENDED ADDITIONS TO values.yaml
   
   # Example connections (for documentation)
   examples:
     # Telegraf connection
     telegraf: "http://influxdb-pod:8086"
     
     # Grafana data source
     grafana: "http://influxdb-pod:8086"
     
     # n8n workflow
     n8n: "http://influxdb-pod:8086"
     
     # Python client
     python: |
       from influxdb_client import InfluxDBClient
       client = InfluxDBClient(
         url="http://influxdb-pod:8086",
         token="your-token",
         org="factory"
       )
   ```

2. **Add Network Policy Template**
   - Currently no networkPolicy configuration
   - Should allow specific pods (Telegraf, Grafana, n8n)

3. **Enhance NOTES.txt**
   - Add connection examples for other pods
   - Include token retrieval command
   - Show bucket creation examples

---

## 2. PostgreSQL Pod

### ✅ Strengths

1. **Production-Ready**
   - 5 resource presets (edge → xlarge)
   - HA mode with streaming replication
   - Tuned for transactional workloads

2. **PostgreSQL Extensions**
   - TimescaleDB (time-series data)
   - PostGIS (spatial data for factory layouts)
   - pg_stat_statements (query monitoring)
   - pg_cron (scheduled jobs)

3. **Initial Database Setup**
   - Pre-creates 4 databases:
     - `production_data`
     - `quality_metrics`
     - `maintenance_logs`
     - `energy_consumption`
     - `scada_historian`

4. **Default User**
   - Username: `fireball` (good for standardization)
   - Database: `production_data`
   - Auth: `scram-sha-256` (secure)

5. **Service Exposure**
   - Service name: `postgresql-pod`
   - Port: 5432
   - **DNS**: `postgresql-pod.<namespace>.svc.cluster.local:5432`

### ⚠️ Recommendations

1. **Service Discovery Documentation**
   ```yaml
   # RECOMMENDED ADDITIONS TO README.md
   
   ## Connecting from Other Pods
   
   ### n8n Workflow Automation
   ```bash
   helm install n8n fireball/n8n-pod \
     --set database.type=postgres \
     --set database.postgres.external.host=postgresql-pod \
     --set database.postgres.external.user=fireball \
     --set database.postgres.external.database=n8n
   ```
   
   ### Node-RED
   PostgreSQL node configuration:
   - Host: `postgresql-pod`
   - Port: `5432`
   - Database: `production_data`
   - User: `fireball`
   
   ### Python Application
   ```python
   import psycopg2
   conn = psycopg2.connect(
       host="postgresql-pod",
       port=5432,
       database="production_data",
       user="fireball",
       password=os.getenv("POSTGRES_PASSWORD")
   )
   ```
   ```

2. **Add Pre-Configured Schemas**
   ```sql
   -- RECOMMENDED: Add to initScripts
   -- Sensor data table (for apps that don't use TimescaleDB)
   CREATE TABLE IF NOT EXISTS sensor_readings (
       id SERIAL PRIMARY KEY,
       sensor_id VARCHAR(50),
       value REAL,
       quality INTEGER DEFAULT 192,
       timestamp TIMESTAMPTZ DEFAULT NOW()
   );
   CREATE INDEX idx_sensor_timestamp ON sensor_readings(timestamp);
   ```

3. **Enhance Connection Pooling**
   - Add pgBouncer sidecar option (currently missing)
   - Document max_connections limits per preset

---

## 3. TimescaleDB Pod

### ✅ Strengths

1. **Time-Series Optimization**
   - Hypertable auto-creation for:
     - `sensor_data` (1-second intervals)
     - `machine_metrics` (per-minute aggregates)
   - Automatic compression after 7 days
   - Retention policies (90 days → 10 years)

2. **Continuous Aggregates**
   - Auto-refresh enabled
   - Hourly, daily, monthly rollups
   - Materialized hypertable compression

3. **Resource Presets**
   - 5 presets optimized for IoT workloads
   - Edge: 500m CPU, 1Gi RAM (Raspberry Pi)
   - XLarge: 16 CPU, 64Gi RAM (enterprise historian)

4. **PostgreSQL Compatibility**
   - All PostgreSQL features available
   - PostGIS support
   - pg_stat_statements enabled

5. **Service Exposure**
   - Service name: `timescaledb-pod`
   - Port: 5432
   - **DNS**: `timescaledb-pod.<namespace>.svc.cluster.local:5432`

### ⚠️ Recommendations

1. **Add Industrial Schema Templates**
   ```yaml
   # RECOMMENDED ADDITIONS TO examples/
   
   # examples/scada-historian-schema.sql
   -- Create hypertables for SCADA systems
   CREATE TABLE scada_tags (
       time TIMESTAMPTZ NOT NULL,
       tag_id TEXT NOT NULL,
       value DOUBLE PRECISION,
       quality INTEGER DEFAULT 192,
       PRIMARY KEY (tag_id, time)
   );
   
   SELECT create_hypertable('scada_tags', 'time', 
       partitioning_column => 'tag_id',
       number_partitions => 4,
       chunk_time_interval => INTERVAL '1 hour'
   );
   
   -- Compression policy
   ALTER TABLE scada_tags SET (
       timescaledb.compress,
       timescaledb.compress_segmentby = 'tag_id',
       timescaledb.compress_orderby = 'time DESC'
   );
   
   SELECT add_compression_policy('scada_tags', INTERVAL '7 days');
   ```

2. **Document vs InfluxDB Comparison**
   ```markdown
   ## TimescaleDB vs InfluxDB
   
   **Use TimescaleDB when:**
   - Need SQL and complex joins
   - Mixing relational + time-series data
   - Using existing PostgreSQL tools
   - Need ACID guarantees
   
   **Use InfluxDB when:**
   - Pure time-series metrics
   - High write throughput (>100K/sec)
   - Simple queries (no joins)
   - Grafana dashboards
   ```

3. **Add Integration Examples**
   - Telegraf to TimescaleDB (currently missing)
   - MQTT to TimescaleDB pipeline
   - n8n workflow examples

---

## 4. SQLite Pod

### ✅ Strengths

1. **Edge-Optimized**
   - Minimal resources (64MB-512MB)
   - Litestream continuous replication
   - Perfect for factory floor/PLCs

2. **Litestream Integration**
   - S3 backup support
   - Local PVC backup
   - Point-in-time recovery

3. **Web Interface**
   - Optional SQLite Web UI
   - Read-only mode available
   - Ingress support

4. **Industrial Schemas**
   - `sensor-schema.sql` (sensor readings)
   - `maintenance-schema.sql` (equipment tracking)
   - `production-schema.sql` (OEE, quality)

### ⚠️ Recommendations

1. **Service Exposure**
   - Currently no primary service (only web UI)
   - **ISSUE**: Other pods can't query SQLite directly
   - **SOLUTION**: Add REST API sidecar or document file-based access

2. **Add Shared Access Pattern**
   ```yaml
   # RECOMMENDED: Document multi-pod access
   
   ## Accessing SQLite from Multiple Pods
   
   SQLite is file-based, so multi-pod access requires:
   
   1. **Read-Only Access** (multiple readers):
      Mount the same PVC in ReadOnlyMany mode
   
   2. **Write Access** (single writer):
      Use Litestream replication to separate databases
   
   3. **API Access** (recommended for factories):
      Deploy sqlite-web or custom REST API
   ```

3. **Add Sync Examples**
   ```python
   # RECOMMENDED: Add to examples/
   
   # examples/sqlite-to-postgresql-sync.py
   # Periodically sync SQLite (edge) → PostgreSQL (cloud)
   import sqlite3
   import psycopg2
   
   edge_db = sqlite3.connect('/data/sensors.db')
   cloud_db = psycopg2.connect("host=postgresql-pod port=5432")
   
   # Sync unsynced records
   cursor = edge_db.execute(
       "SELECT * FROM sensor_readings WHERE synced = 0"
   )
   # ... bulk insert to PostgreSQL
   ```

---

## Cross-Pod Integration Matrix

| Source Pod | Target Database | Connection String | Port | Notes |
|------------|----------------|-------------------|------|-------|
| Telegraf | InfluxDB | `http://influxdb-pod:8086` | 8086 | Use token auth |
| Telegraf | TimescaleDB | `postgresql://timescaledb-pod:5432` | 5432 | PostgreSQL output plugin |
| n8n | PostgreSQL | `postgresql-pod:5432` | 5432 | For n8n DB + workflows |
| n8n | InfluxDB | `http://influxdb-pod:8086` | 8086 | InfluxDB nodes |
| n8n | TimescaleDB | `timescaledb-pod:5432` | 5432 | PostgreSQL nodes |
| Grafana | InfluxDB | `http://influxdb-pod:8086` | 8086 | Flux or InfluxQL |
| Grafana | PostgreSQL | `postgresql-pod:5432` | 5432 | PostgreSQL data source |
| Grafana | TimescaleDB | `timescaledb-pod:5432` | 5432 | PostgreSQL + TimescaleDB functions |
| Node-RED | PostgreSQL | `postgresql-pod:5432` | 5432 | PostgreSQL node |
| Node-RED | InfluxDB | `http://influxdb-pod:8086` | 8086 | InfluxDB node |
| MQTT → DB | Any | Service name | Varies | Use Telegraf or n8n |
| SQLite | PostgreSQL | N/A (file-based) | N/A | Manual sync or API |

---

## Required Fixes

### HIGH PRIORITY

1. **✅ COMPLETE**: n8n integration URLs updated to use correct service names
   - Changed: `mosquitto-mqtt.default.svc.cluster.local` → `mosquitto-mqtt-pod`
   - Changed: `influxdb.default.svc.cluster.local` → `influxdb-pod`
   - Changed: `postgresql.default.svc.cluster.local` → `postgresql-pod`

2. **🔧 TODO**: Add NetworkPolicy templates to all database charts
   ```yaml
   # Example for InfluxDB
   networkPolicy:
     enabled: true
     ingress:
       - from:
         - namespaceSelector:
             matchLabels:
               name: default
         - podSelector:
             matchLabels:
               app: telegraf
         - podSelector:
             matchLabels:
               app: grafana
   ```

### MEDIUM PRIORITY

3. **📝 TODO**: Add integration examples to READMEs
   - InfluxDB: Add Telegraf, Grafana, n8n connection examples
   - PostgreSQL: Add n8n, Node-RED connection examples
   - TimescaleDB: Add SCADA historian examples
   - SQLite: Add sync patterns for edge→cloud

4. **📝 TODO**: Document service discovery pattern
   ```markdown
   ## Service Discovery
   
   All pods use Kubernetes DNS for service discovery:
   
   - Same namespace: `<service-name>:<port>`
   - Cross-namespace: `<service-name>.<namespace>.svc.cluster.local:<port>`
   
   Examples:
   - InfluxDB: `http://influxdb-pod:8086`
   - PostgreSQL: `postgresql-pod:5432`
   - TimescaleDB: `timescaledb-pod:5432`
   ```

### LOW PRIORITY

5. **🎨 TODO**: Add architecture diagrams
   - Data flow: MQTT → Telegraf → InfluxDB → Grafana
   - Database selection decision tree
   - Edge vs Cloud deployment patterns

6. **📚 TODO**: Create integration guide
   - File: `INTEGRATION-GUIDE.md` at repository root
   - Cross-reference all database integrations
   - Include real-world examples

---

## Persistent Storage Verification

### ✅ All Charts Have Proper Persistence

| Chart | Storage | Default Size | Retention | Notes |
|-------|---------|--------------|-----------|-------|
| **InfluxDB** | ✅ PVC | 50Gi | Keeps on delete | TSM files, WAL |
| **PostgreSQL** | ✅ PVC | 200Gi | Keeps on delete | PGDATA, WAL |
| **TimescaleDB** | ✅ PVC | 500Gi | Keeps on delete | PGDATA + chunks |
| **SQLite** | ✅ PVC | 5Gi | User choice | DB file + WAL |

**All charts:**
- Use StatefulSet for HA modes
- Support `storageClass` customization
- Default to `ReadWriteOnce` access mode
- Include `retainOnDelete` protection

---

## Security Verification

### ✅ All Charts Are Secure

1. **Pod Security Contexts**
   - ✅ Run as non-root (uid 1000)
   - ✅ FSGroup configured
   - ✅ Capabilities dropped

2. **Authentication**
   - ✅ InfluxDB: Token-based
   - ✅ PostgreSQL: scram-sha-256
   - ✅ TimescaleDB: scram-sha-256
   - ✅ SQLite: File permissions

3. **Secrets Management**
   - ✅ All use Kubernetes Secrets
   - ✅ Passwords auto-generated if not provided
   - ⚠️ Document secret retrieval commands

---

## Monitoring Integration

### ✅ All Charts Support Prometheus

| Chart | Metrics Port | ServiceMonitor | Exporter |
|-------|-------------|----------------|----------|
| **InfluxDB** | 8086 | ✅ Optional | Built-in |
| **PostgreSQL** | 9187 | ✅ Optional | postgres_exporter |
| **TimescaleDB** | 9187 | ✅ Optional | postgres_exporter |
| **SQLite** | N/A | ❌ No | N/A |

**Recommendations:**
- Enable ServiceMonitor in production
- Set appropriate scrape intervals (30s default)
- Document metric names and queries

---

## Final Assessment

### Overall Score: 🟢 EXCELLENT (92/100)

**Breakdown:**
- Persistent Storage: 100/100 ✅
- Resource Optimization: 95/100 ✅
- High Availability: 90/100 ✅
- Security: 95/100 ✅
- Industrial Features: 95/100 ✅
- Cross-Pod Integration: 75/100 ⚠️ (needs documentation)
- Monitoring: 90/100 ✅

### Required Actions

1. ✅ **DONE**: Fixed n8n service names
2. 📝 **TODO**: Add cross-pod integration examples to READMEs (30 min)
3. 📝 **TODO**: Add NetworkPolicy templates (15 min)
4. 📝 **TODO**: Document service discovery pattern (15 min)
5. 📚 **TODO**: Create INTEGRATION-GUIDE.md (1 hour)

---

**Reviewer Notes:**

All four database charts are production-ready and optimized for industrial use. The main gap is documentation around cross-pod integration and service discovery. The technical implementation is solid - just needs better developer guidance.

**Sign-off:** Ready for production deployment with recommended documentation improvements.
