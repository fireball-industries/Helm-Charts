# SQLite Pod Examples

This directory contains example configurations and SQL scripts for deploying and using SQLite in industrial environments.

## Quick Start Examples

### 1. Basic Development Setup

**File**: `dev-values.yaml`

Minimal SQLite deployment for testing and development.

```bash
helm install sqlite ../.. -f dev-values.yaml
```

**Features**:
- SQLite 3.45.0
- 2Gi storage
- No replication
- Micro resource preset (64MB RAM)

### 2. Production with S3 Replication

**File**: `production-values.yaml`

Production-ready deployment with Litestream backup to S3.

```bash
helm install sqlite ../.. -f production-values.yaml
```

**Features**:
- Litestream replication to S3
- 20Gi storage
- Small resource preset (128MB RAM)
- Hourly snapshots, 7-day retention

### 3. Edge Deployment with Local Backup

**File**: `edge-values.yaml`

Edge computing deployment with local backup to second PVC.

```bash
helm install sqlite ../.. -f edge-values.yaml
```

**Features**:
- Local backup to PVC
- Web interface for monitoring
- Minimal resources for edge devices

## SQL Script Examples

### 1. Sensor Data Schema

**File**: `sensor-schema.sql`

Database schema for industrial sensor data collection.

**Tables**:
- `sensors` - Sensor registry
- `sensor_readings` - Time-series measurements
- `sensor_events` - Alerts and anomalies

**Usage**:
```bash
kubectl cp sensor-schema.sql $POD_NAME:/tmp/schema.sql -c sqlite
kubectl exec $POD_NAME -c sqlite -- sqlite3 /data/industrial.db ".read /tmp/schema.sql"
```

### 2. Equipment Maintenance Schema

**File**: `maintenance-schema.sql`

Track equipment maintenance, schedules, and work orders.

**Tables**:
- `equipment` - Equipment registry
- `maintenance_schedules` - Preventive maintenance
- `work_orders` - Maintenance tasks
- `parts_inventory` - Spare parts tracking

### 3. Production Tracking Schema

**File**: `production-schema.sql`

Monitor production runs, quality, and OEE metrics.

**Tables**:
- `production_runs` - Manufacturing batches
- `quality_checks` - Quality control results
- `downtime_events` - Unplanned stops
- `shift_reports` - Operator handoffs

## Deployment Patterns

### Edge Caching Pattern

Use SQLite as a local cache before cloud upload:

```yaml
# Deploy SQLite for local buffering
helm install sqlite-cache ../.. -f edge-values.yaml

# Application writes to SQLite first
INSERT INTO sensor_readings (sensor_id, value) VALUES ('temp-01', 72.5);

# Background sync job uploads to cloud database
# Litestream provides backup/replication
```

### Configuration Store Pattern

Store application and device configurations:

```yaml
# Deploy SQLite for config storage
helm install config-store ../.. -f dev-values.yaml

# Store PLC configurations
INSERT INTO device_configs (device_id, parameter, value) 
VALUES ('plc-001', 'scan_rate', '100');

# Applications read configuration on startup
SELECT parameter, value FROM device_configs WHERE device_id = 'plc-001';
```

### Audit Log Pattern

Track all system operations:

```yaml
# Deploy SQLite for audit logging
helm install audit-log ../.. -f production-values.yaml

# Log all operations
INSERT INTO audit_log (user_id, action, resource, timestamp) 
VALUES ('operator-1', 'START_MACHINE', 'line-2', CURRENT_TIMESTAMP);

# Litestream replicates to S3 for compliance
```

## Access Patterns

### CLI Access

```bash
# Get pod name
POD_NAME=$(kubectl get pods -l app.kubernetes.io/name=sqlite-pod -o jsonpath='{.items[0].metadata.name}')

# Interactive SQLite shell
kubectl exec -it $POD_NAME -c sqlite -- sqlite3 /data/industrial.db

# Execute single query
kubectl exec $POD_NAME -c sqlite -- \
  sqlite3 /data/industrial.db "SELECT COUNT(*) FROM sensors;"

# Import SQL file
kubectl cp ./schema.sql $POD_NAME:/tmp/schema.sql -c sqlite
kubectl exec $POD_NAME -c sqlite -- \
  sqlite3 /data/industrial.db ".read /tmp/schema.sql"

# Export to CSV
kubectl exec $POD_NAME -c sqlite -- \
  sqlite3 /data/industrial.db ".mode csv" ".output /tmp/export.csv" "SELECT * FROM sensors;"
kubectl cp $POD_NAME:/tmp/export.csv ./sensors.csv -c sqlite
```

### Application Access

From other pods in the cluster:

```yaml
# Mount the same PVC in your application pod
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
    - name: app
      image: myapp:latest
      volumeMounts:
        - name: sqlite-data
          mountPath: /data
  volumes:
    - name: sqlite-data
      persistentVolumeClaim:
        claimName: data-sqlite-pod-0
```

```python
# Python application using sqlite3
import sqlite3

conn = sqlite3.connect('/data/industrial.db')
cursor = conn.cursor()

# Query data
cursor.execute("SELECT * FROM sensors WHERE location = ?", ('line-1',))
results = cursor.fetchall()

# Insert data
cursor.execute(
    "INSERT INTO sensor_readings (sensor_id, value, unit) VALUES (?, ?, ?)",
    ('temp-01', 72.5, 'F')
)
conn.commit()
conn.close()
```

### Web UI Access

If web interface is enabled:

```bash
# Port-forward to local machine
kubectl port-forward svc/sqlite-pod 8080:8080

# Open browser
open http://localhost:8080
```

**Web UI Features**:
- Browse tables and data
- Execute SQL queries
- Export data as CSV/JSON
- View schema and indexes
- Read-only mode available

## Backup and Restore

### Manual Backup

```bash
# Backup database file
kubectl exec $POD_NAME -c sqlite -- \
  sqlite3 /data/industrial.db ".backup '/tmp/backup.db'"

# Copy to local machine
kubectl cp $POD_NAME:/tmp/backup.db ./backup-$(date +%Y%m%d).db -c sqlite

# Compress for storage
gzip ./backup-$(date +%Y%m%d).db
```

### Litestream Backup

With Litestream enabled:

```bash
# Check replication status
kubectl exec $POD_NAME -c litestream -- \
  litestream snapshots /data/industrial.db

# List available backups
kubectl exec $POD_NAME -c litestream -- \
  litestream snapshots /data/industrial.db

# Restore from latest backup
kubectl exec $POD_NAME -c litestream -- \
  litestream restore -o /tmp/restored.db /data/industrial.db

# Restore to specific time
kubectl exec $POD_NAME -c litestream -- \
  litestream restore \
  -timestamp 2026-01-12T10:30:00Z \
  -o /tmp/restored.db \
  /data/industrial.db
```

### Scheduled Backups

Create a CronJob for regular backups:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: sqlite-backup
spec:
  schedule: "0 2 * * *"  # 2 AM daily
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: backup
              image: nouchka/sqlite3:latest
              command:
                - /bin/sh
                - -c
                - |
                  sqlite3 /data/industrial.db ".backup '/backup/backup-$(date +%Y%m%d).db'"
                  find /backup -name "backup-*.db" -mtime +7 -delete
              volumeMounts:
                - name: sqlite-data
                  mountPath: /data
                - name: backup
                  mountPath: /backup
          volumes:
            - name: sqlite-data
              persistentVolumeClaim:
                claimName: data-sqlite-pod-0
            - name: backup
              persistentVolumeClaim:
                claimName: sqlite-backups
          restartPolicy: OnFailure
```

## Performance Tips

### Indexes

Create indexes for frequently queried columns:

```sql
-- Sensor readings by sensor_id
CREATE INDEX idx_readings_sensor ON sensor_readings(sensor_id);

-- Time-based queries
CREATE INDEX idx_readings_timestamp ON sensor_readings(timestamp);

-- Composite index for multi-column queries
CREATE INDEX idx_readings_sensor_time ON sensor_readings(sensor_id, timestamp);

-- Check index usage
EXPLAIN QUERY PLAN SELECT * FROM sensor_readings WHERE sensor_id = 'temp-01';
```

### Batch Inserts

Use transactions for bulk inserts:

```sql
BEGIN TRANSACTION;

INSERT INTO sensor_readings (sensor_id, value, unit) VALUES
  ('temp-01', 72.5, 'F'),
  ('temp-02', 68.3, 'F'),
  ('pressure-01', 45.2, 'PSI'),
  ('speed-01', 1200, 'RPM');
  -- ... thousands more rows

COMMIT;
```

### Query Optimization

```sql
-- Analyze database for query planner
ANALYZE;

-- View query execution plan
EXPLAIN QUERY PLAN 
SELECT s.name, AVG(r.value) as avg_value
FROM sensors s
JOIN sensor_readings r ON s.id = r.sensor_id
WHERE r.timestamp > datetime('now', '-1 hour')
GROUP BY s.name;

-- Optimize database file
VACUUM;

-- Incremental vacuum (for auto_vacuum = INCREMENTAL)
PRAGMA incremental_vacuum(1000);
```

## Troubleshooting

### Database Locked

```bash
# Check if WAL mode is enabled
kubectl exec $POD_NAME -c sqlite -- \
  sqlite3 /data/industrial.db "PRAGMA journal_mode;"

# Enable WAL if not already
kubectl exec $POD_NAME -c sqlite -- \
  sqlite3 /data/industrial.db "PRAGMA journal_mode=WAL;"

# Increase busy timeout
kubectl exec $POD_NAME -c sqlite -- \
  sqlite3 /data/industrial.db "PRAGMA busy_timeout=10000;"
```

### Check Database Integrity

```bash
# Run integrity check
kubectl exec $POD_NAME -c sqlite -- \
  sqlite3 /data/industrial.db "PRAGMA integrity_check;"

# Quick check (faster)
kubectl exec $POD_NAME -c sqlite -- \
  sqlite3 /data/industrial.db "PRAGMA quick_check;"
```

### View Database Statistics

```bash
# Database size and page count
kubectl exec $POD_NAME -c sqlite -- \
  sqlite3 /data/industrial.db "
    SELECT 
      page_count * page_size as size_bytes,
      page_count,
      page_size
    FROM pragma_page_count(), pragma_page_size();
  "

# Table sizes
kubectl exec $POD_NAME -c sqlite -- \
  sqlite3 /data/industrial.db "
    SELECT 
      name,
      pgsize as table_size_bytes
    FROM dbstat
    WHERE name NOT LIKE 'sqlite_%'
    GROUP BY name
    ORDER BY pgsize DESC;
  "
```

## Integration Examples

### MQTT to SQLite

Buffer MQTT sensor data locally:

```python
import sqlite3
import paho.mqtt.client as mqtt

db = sqlite3.connect('/data/sensors.db')

def on_message(client, userdata, msg):
    value = float(msg.payload)
    sensor_id = msg.topic.split('/')[-1]
    
    db.execute(
        "INSERT INTO sensor_readings (sensor_id, value) VALUES (?, ?)",
        (sensor_id, value)
    )
    db.commit()

client = mqtt.Client()
client.on_message = on_message
client.connect("mosquitto-mqtt-pod", 1883)
client.subscribe("factory/sensors/#")
client.loop_forever()
```

### SQLite to InfluxDB Sync

Batch upload buffered data to InfluxDB:

```python
import sqlite3
from influxdb_client import InfluxDBClient

# Read from SQLite
db = sqlite3.connect('/data/sensors.db')
cursor = db.execute(
    "SELECT sensor_id, value, timestamp FROM sensor_readings WHERE synced = 0"
)

# Write to InfluxDB
influx = InfluxDBClient(url="http://influxdb-pod:8086", token="...")
write_api = influx.write_api()

for row in cursor:
    point = {
        "measurement": "sensors",
        "tags": {"sensor": row[0]},
        "fields": {"value": row[1]},
        "time": row[2]
    }
    write_api.write(bucket="production", record=point)
    
    # Mark as synced
    db.execute("UPDATE sensor_readings SET synced = 1 WHERE id = ?", (row[3],))

db.commit()
```

## Additional Resources

- [SQLite Documentation](https://www.sqlite.org/docs.html)
- [SQLite Performance Tuning](https://www.sqlite.org/optoverview.html)
- [Litestream Documentation](https://litestream.io/)
- [Fireball Industries Helm Charts](https://github.com/fireball-industries/helm-charts)

---

**Fireball Industries** - Ignite Your Factory Efficiency
