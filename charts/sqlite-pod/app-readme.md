# SQLite Embedded Database

Lightweight file-based SQL database perfect for edge computing and IoT deployments.

## Quick Deploy

Deploy SQLite with Litestream replication for continuous backup and disaster recovery. Ideal for factory floor data caching, configuration storage, and local analytics.

## Key Features

- **Zero Configuration** - No server setup required
- **Litestream Replication** - Continuous backup to S3 or local storage
- **Lightweight** - Runs on 64MB-512MB RAM
- **Web Interface** - Optional management UI
- **Edge-Optimized** - Perfect for PLCs and IoT devices
- **ACID Compliant** - Full transactional support

## Common Use Cases

1. **Sensor Data Cache** - Buffer readings before cloud upload
2. **Configuration Storage** - Store PLC and device settings
3. **Audit Logging** - Track equipment operations and events
4. **Small Datasets** - Product catalogs, schedules, quality data

## Quick Configuration

**Resource Size**: Choose micro (64MB), small (128MB), medium (256MB), or large (512MB)

**Database Name**: Default is `industrial.db`

**WAL Mode**: Enable for better concurrency (recommended)

**Litestream**: Enable for continuous S3 or local backups

**Web UI**: Optional read-only database browser

## Getting Started

After deployment:

1. Access database via `kubectl exec` and `sqlite3` CLI
2. Import schema with init scripts
3. Query from application pods
4. Monitor backups with Litestream
5. Browse data via web interface (if enabled)

## When to Use

✅ Edge deployments with limited resources  
✅ Local caching and buffering  
✅ Configuration and state storage  
✅ Datasets < 1GB  
✅ Single-writer scenarios

❌ High concurrent writes  
❌ Large datasets (> 100GB)  
❌ Multi-node distributed systems

## Industrial Integrations

- **MQTT**: Store buffered sensor readings
- **Node-RED**: Local flow state persistence
- **n8n**: Workflow execution cache
- **Edge PLCs**: Configuration and audit logs

## Documentation

See full README.md for:
- Detailed configuration options
- SQL query examples
- Backup and restore procedures
- Performance tuning tips
- Troubleshooting guide

---

**Fireball Industries** - Ignite Your Factory Efficiency
