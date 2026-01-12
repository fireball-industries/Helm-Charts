# SQLite Embedded Database Pod

![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square)
![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)
![AppVersion: 3.45.0](https://img.shields.io/badge/AppVersion-3.45.0-informational?style=flat-square)

**Ignite Your Factory Efficiency** with lightweight embedded database storage for edge deployments.

## Overview

SQLite is a self-contained, serverless, zero-configuration SQL database engine. This Helm chart deploys SQLite in Kubernetes with Litestream for continuous replication, making it ideal for edge computing, IoT data collection, and factory automation where a full database server would be overkill.

### Key Features

- 📦 **Zero Configuration** - No server setup, just a file-based database
- 🔄 **Litestream Replication** - Continuous backup to S3 or local storage
- 🚀 **Lightweight** - Minimal resource requirements (64MB-512MB RAM)
- 🌐 **Web Interface** - Optional SQLite Web UI for management
- 🏭 **Edge-Optimized** - Perfect for factory floor, PLCs, and IoT devices
- 💾 **Persistent Storage** - Kubernetes PVC-backed data storage
- 🔐 **ACID Compliance** - Full transactional support with WAL mode
- 📊 **Industrial Ready** - Store sensor data, configuration, and logs

### Industrial Use Cases

1. **Local Sensor Data Cache**
   - Buffer sensor readings before cloud upload
   - Local analytics and aggregation
   - Offline-first edge deployments

2. **Configuration Storage**
   - PLC and device configurations
   - User preferences and settings
   - Application state persistence

3. **Audit Logging**
   - Track equipment operations
   - Store alarm and event history
   - Compliance data retention

4. **Small Datasets**
   - Product catalogs
   - Shift schedules
   - Quality control data

## Installation

### Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- PV provisioner support (if persistence is enabled)
- Optional: S3-compatible storage for Litestream backups

### Quick Start

```bash
# Add Fireball Industries Helm repository
helm repo add fireball https://charts.fireballindustries.com
helm repo update

# Install with default configuration
helm install sqlite fireball/sqlite-pod

# Install with custom database name
helm install sqlite fireball/sqlite-pod \
  --set sqlite.databaseName=sensors.db

# Install with S3 replication
helm install sqlite fireball/sqlite-pod \
  --set litestream.enabled=true \
  --set litestream.s3.enabled=true \
  --set litestream.s3.bucket=my-backups \
  --set litestream.s3.accessKeyId=AKIAIOSFODNN7EXAMPLE \
  --set litestream.s3.secretAccessKey=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

### Production Deployment

```bash
helm install sqlite fireball/sqlite-pod \
  --set sqlite.databaseName=production.db \
  --set sqlite.walMode=true \
  --set persistence.size=20Gi \
  --set resources.preset=medium \
  --set litestream.enabled=true \
  --set litestream.s3.enabled=true \
  --set litestream.s3.bucket=factory-backups \
  --set litestream.s3.region=us-east-1 \
  --set litestream.replication.snapshotInterval=1h \
  --set litestream.replication.retention=168h \
  --set web.enabled=true \
  --set web.readOnly=true
```

## Configuration

### Resource Presets

Choose a preset based on your database size and workload:

| Preset | CPU Request | CPU Limit | Memory Request | Memory Limit | Use Case |
|--------|-------------|-----------|----------------|--------------|----------|
| micro  | 50m | 200m | 64Mi | 128Mi | Testing, small logs |
| small  | 100m | 500m | 128Mi | 256Mi | **Recommended** - Edge devices |
| medium | 250m | 1000m | 256Mi | 512Mi | Moderate workloads |
| large  | 500m | 2000m | 512Mi | 1Gi | Heavy processing |
| custom | - | - | - | - | Define your own |

```yaml
resources:
  preset: small  # Change to match your needs
```

### SQLite Configuration

#### Database Settings

```yaml
sqlite:
  databaseName: "industrial.db"
  walMode: true  # Enable Write-Ahead Logging (recommended)
  journalMode: "WAL"  # WAL, DELETE, TRUNCATE, PERSIST, MEMORY, OFF
  synchronous: "NORMAL"  # OFF, NORMAL, FULL, EXTRA
  autoVacuum: "INCREMENTAL"  # NONE, FULL, INCREMENTAL
  cacheSize: -2000  # -2000 = 2MB cache (negative = KB)
  pageSize: 4096  # Page size in bytes
  busyTimeout: 5000  # Timeout in milliseconds
```

**WAL Mode Benefits**:
- Better write concurrency
- Faster commits
- No blocking between readers and writers

#### Journal Modes

- **WAL** (Recommended): Best performance and concurrency
- **DELETE**: Default mode, deletes journal after commit
- **TRUNCATE**: Faster than DELETE, truncates journal
- **PERSIST**: Keeps journal file, zeros it
- **MEMORY**: In-memory journal (risky)
- **OFF**: No journal (dangerous)

#### Synchronous Modes

- **OFF**: No syncing (fastest, least safe)
- **NORMAL**: Syncs at critical moments (good for WAL)
- **FULL**: Syncs every write (safest, slowest)
- **EXTRA**: Extra sync calls (paranoid)

### Litestream Replication

Enable continuous replication and disaster recovery:

```yaml
litestream:
  enabled: true
  replication:
    snapshotInterval: "1h"  # How often to snapshot
    retention: "24h"  # How long to keep snapshots
    validationInterval: "6h"  # Verify backups
```

#### S3 Backup

```yaml
litestream:
  s3:
    enabled: true
    bucket: "sqlite-backups"
    path: "production"
    region: "us-east-1"
    endpoint: ""  # For MinIO: http://minio:9000
    accessKeyId: "your-access-key"
    secretAccessKey: "your-secret-key"
    forcePathStyle: false  # true for MinIO
```

#### Local Backup

```yaml
litestream:
  localBackup:
    enabled: true
    path: "/backup"
    size: "5Gi"
    storageClass: "local-path"
```

### Web Interface

Optional SQLite Web UI for database management:

```yaml
web:
  enabled: true
  readOnly: true  # Prevent modifications via web UI
  service:
    type: ClusterIP
    port: 8080
  ingress:
    enabled: true
    className: "traefik"
    host: "sqlite-web.factory.local"
    tls:
      enabled: false
```

**Features**:
- Browse tables and data
- Execute SQL queries
- Export data as CSV/JSON
- View schema and indexes

### Persistence

```yaml
persistence:
  enabled: true
  size: 5Gi
  storageClass: "local-path"
  accessMode: ReadWriteOnce
  existingClaim: ""  # Use existing PVC
  paths:
    data: /data
    backup: /backup
```

### Init Scripts

Run SQL scripts on first startup:

```yaml
initScripts:
  enabled: true
  scripts:
    01-schema.sql: |
      CREATE TABLE IF NOT EXISTS sensors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        location TEXT,
        value REAL,
        unit TEXT,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX idx_sensors_location ON sensors(location);
      CREATE INDEX idx_sensors_timestamp ON sensors(timestamp);
    
    02-seed.sql: |
      INSERT INTO sensors (name, type, location, value, unit) VALUES
        ('temp-01', 'temperature', 'line-1', 72.5, 'F'),
        ('pressure-01', 'pressure', 'line-1', 45.2, 'PSI'),
        ('speed-01', 'speed', 'line-2', 1200, 'RPM');
```

### Monitoring

```yaml
monitoring:
  healthcheck:
    enabled: true
    livenessProbe:
      exec:
        command:
          - sh
          - -c
          - "test -f /data/industrial.db"
      initialDelaySeconds: 10
      periodSeconds: 30
  serviceMonitor:
    enabled: false
    interval: 30s
    labels:
      release: prometheus
```

## Usage Examples

### Accessing the Database

#### Via kubectl exec

```bash
# Get pod name
POD_NAME=$(kubectl get pods -l app.kubernetes.io/name=sqlite-pod -o jsonpath='{.items[0].metadata.name}')

# Access SQLite CLI
kubectl exec -it $POD_NAME -c sqlite -- sqlite3 /data/industrial.db

# Run a query
kubectl exec -it $POD_NAME -c sqlite -- sqlite3 /data/industrial.db "SELECT * FROM sensors;"

# Execute SQL file
kubectl cp ./schema.sql $POD_NAME:/tmp/schema.sql -c sqlite
kubectl exec -it $POD_NAME -c sqlite -- sqlite3 /data/industrial.db ".read /tmp/schema.sql"
```

#### From Application Pod

```yaml
# Mount the same PVC in your application
volumeMounts:
  - name: sqlite-data
    mountPath: /data

# Access the database
sqlite3 /data/industrial.db "SELECT * FROM sensors WHERE location = 'line-1';"
```

### Example Queries

#### Create Tables

```sql
-- Sensor readings
CREATE TABLE sensor_readings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sensor_id TEXT NOT NULL,
  value REAL NOT NULL,
  unit TEXT,
  quality INTEGER DEFAULT 192,  -- OPC-UA quality
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_readings_sensor ON sensor_readings(sensor_id);
CREATE INDEX idx_readings_timestamp ON sensor_readings(timestamp);

-- Equipment events
CREATE TABLE equipment_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  equipment_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  severity TEXT CHECK(severity IN ('info', 'warning', 'error', 'critical')),
  message TEXT,
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

#### Insert Data

```sql
-- Insert sensor reading
INSERT INTO sensor_readings (sensor_id, value, unit) 
VALUES ('temp-01', 72.5, 'F');

-- Bulk insert
INSERT INTO sensor_readings (sensor_id, value, unit) VALUES
  ('temp-01', 72.5, 'F'),
  ('temp-02', 68.3, 'F'),
  ('pressure-01', 45.2, 'PSI');
```

#### Query Data

```sql
-- Latest readings
SELECT sensor_id, value, unit, timestamp 
FROM sensor_readings 
ORDER BY timestamp DESC 
LIMIT 10;

-- Average by sensor
SELECT sensor_id, 
       AVG(value) as avg_value, 
       MIN(value) as min_value, 
       MAX(value) as max_value,
       COUNT(*) as sample_count
FROM sensor_readings 
WHERE timestamp > datetime('now', '-1 hour')
GROUP BY sensor_id;

-- Events by severity
SELECT severity, COUNT(*) as count 
FROM equipment_events 
WHERE timestamp > datetime('now', '-24 hours')
GROUP BY severity;
```

#### Maintenance

```sql
-- Vacuum database (reclaim space)
VACUUM;

-- Analyze for query optimization
ANALYZE;

-- Check integrity
PRAGMA integrity_check;

-- View database info
PRAGMA database_list;
PRAGMA table_info(sensor_readings);
```

### Backup and Restore

#### Manual Backup

```bash
# Backup database file
kubectl exec $POD_NAME -c sqlite -- \
  sqlite3 /data/industrial.db ".backup '/tmp/backup.db'"

kubectl cp $POD_NAME:/tmp/backup.db ./industrial-backup-$(date +%Y%m%d).db -c sqlite
```

#### Litestream Restore

```bash
# List available snapshots
kubectl exec $POD_NAME -c litestream -- \
  litestream snapshots /data/industrial.db

# Restore from S3
kubectl exec $POD_NAME -c litestream -- \
  litestream restore -o /tmp/restored.db /data/industrial.db

# Restore to specific timestamp
kubectl exec $POD_NAME -c litestream -- \
  litestream restore -timestamp 2026-01-12T10:30:00Z \
  -o /tmp/restored.db /data/industrial.db
```

## Architecture

### Components

- **SQLite**: File-based SQL database engine
- **Litestream**: Continuous replication sidecar (optional)
- **SQLite Web**: Web-based management UI (optional)
- **Persistent Storage**: Kubernetes PVC for database files

### Data Flow

```
Application → SQLite Database File → Persistent Volume
                  ↓
            Litestream (optional)
                  ↓
         S3 Backup or Local Backup
```

## Comparison with Other Databases

| Feature | SQLite | PostgreSQL | InfluxDB |
|---------|--------|------------|----------|
| **Deployment** | File-based | Server | Server |
| **Resources** | 64-512MB | 1-4GB | 2-8GB |
| **Concurrency** | Low-Medium | High | High |
| **Use Case** | Edge, Cache | Production DB | Time-series |
| **Setup** | Zero-config | Complex | Moderate |
| **Replication** | Litestream | Built-in | Built-in |
| **Best For** | Small datasets | Relational data | Sensor metrics |

**When to Use SQLite**:
- Edge deployments with limited resources
- Local caching and buffering
- Configuration and state storage
- Datasets < 1GB
- Single-writer scenarios

**When NOT to Use SQLite**:
- High concurrent writes
- Large datasets (> 100GB)
- Multi-node distributed systems
- Time-series analytics (use InfluxDB)

## Troubleshooting

### Database Locked Errors

SQLite can lock during concurrent writes:

```bash
# Check WAL mode is enabled
kubectl exec $POD_NAME -c sqlite -- \
  sqlite3 /data/industrial.db "PRAGMA journal_mode;"

# Should return: wal

# Increase busy timeout
kubectl exec $POD_NAME -c sqlite -- \
  sqlite3 /data/industrial.db "PRAGMA busy_timeout = 10000;"
```

### Database Corruption

```bash
# Check integrity
kubectl exec $POD_NAME -c sqlite -- \
  sqlite3 /data/industrial.db "PRAGMA integrity_check;"

# If corrupted, restore from Litestream
kubectl exec $POD_NAME -c litestream -- \
  litestream restore -o /data/industrial.db.restored /data/industrial.db
```

### High Disk Usage

```bash
# Check database size
kubectl exec $POD_NAME -c sqlite -- du -h /data/industrial.db

# Vacuum to reclaim space
kubectl exec $POD_NAME -c sqlite -- \
  sqlite3 /data/industrial.db "VACUUM;"

# Enable auto-vacuum
kubectl exec $POD_NAME -c sqlite -- \
  sqlite3 /data/industrial.db "PRAGMA auto_vacuum = INCREMENTAL; VACUUM;"
```

### Slow Queries

```bash
# Analyze database
kubectl exec $POD_NAME -c sqlite -- \
  sqlite3 /data/industrial.db "ANALYZE;"

# View query plan
kubectl exec $POD_NAME -c sqlite -- \
  sqlite3 /data/industrial.db "EXPLAIN QUERY PLAN SELECT * FROM sensors WHERE location = 'line-1';"

# Add indexes
kubectl exec $POD_NAME -c sqlite -- \
  sqlite3 /data/industrial.db "CREATE INDEX idx_location ON sensors(location);"
```

## Upgrading

```bash
# Standard Helm upgrade
helm upgrade sqlite fireball/sqlite-pod

# Upgrade with new values
helm upgrade sqlite fireball/sqlite-pod \
  --set persistence.size=10Gi
```

**Note**: SQLite is backward compatible. Newer versions can always read older database files.

## Uninstallation

```bash
# Uninstall release
helm uninstall sqlite

# Remove PVC (WARNING: deletes all data)
kubectl delete pvc data-sqlite-pod-0
```

## Performance Tips

1. **Enable WAL Mode**: Better concurrency and performance
2. **Use Indexes**: Speed up queries with proper indexes
3. **Increase Cache Size**: More memory = faster queries
4. **Batch Writes**: Use transactions for multiple inserts
5. **Analyze Regularly**: Keep query planner statistics current
6. **Vacuum Periodically**: Reclaim space and reorganize data

## Security

- Database files are stored on persistent volumes
- No network exposure by default (file-based access only)
- Web interface can be set to read-only mode
- Litestream credentials stored in Kubernetes Secrets

## Support

- **SQLite Documentation**: [sqlite.org](https://www.sqlite.org/docs.html)
- **Litestream Docs**: [litestream.io](https://litestream.io/)
- **Fireball Industries**: support@fireballindustries.com
- **Issues**: [GitHub Issues](https://github.com/fireball-industries/helm-charts/issues)

## License

This Helm chart is licensed under Apache 2.0.

SQLite is in the [public domain](https://www.sqlite.org/copyright.html).

---

**Fireball Industries** - Ignite Your Factory Efficiency
