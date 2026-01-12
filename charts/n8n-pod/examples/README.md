# n8n Workflow Examples

This directory contains example workflows and configurations for industrial automation use cases.

## Quick Start Examples

### 1. MQTT to InfluxDB Pipeline

**File**: `mqtt-to-influxdb.json`

Subscribe to MQTT sensor topics, parse JSON data, and write to InfluxDB for time-series storage.

**Use Case**: Real-time sensor data collection from factory floor

```bash
# Deploy with MQTT and InfluxDB integration
helm install n8n ../.. \
  --set integrations.mqtt.enabled=true \
  --set integrations.mqtt.broker=mosquitto-mqtt-pod \
  --set integrations.influxdb.enabled=true \
  --set integrations.influxdb.url=http://influxdb-pod:8086
```

### 2. Temperature Alert Workflow

**File**: `temperature-alert.json`

Monitor temperature sensors via MQTT and send alerts when thresholds are exceeded.

**Use Case**: Equipment overheating detection and notification

### 3. Production Counter

**File**: `production-counter.json`

Count production events from MQTT, aggregate by shift, and store in PostgreSQL.

**Use Case**: Real-time production monitoring and OEE calculation

### 4. API to Database ETL

**File**: `api-to-postgres.json`

Extract data from REST API, transform fields, and load into PostgreSQL database.

**Use Case**: ERP/MES data synchronization

### 5. Multi-System Orchestration

**File**: `multi-system-workflow.json`

Coordinate multiple systems: MQTT → n8n → InfluxDB + PostgreSQL + HTTP API

**Use Case**: Complex factory automation requiring data routing to multiple destinations

## Deployment Examples

### Development Environment

```bash
helm install n8n ../.. -f dev-values.yaml
```

**Features**:
- SQLite database
- 2Gi storage
- No ingress (port-forward)
- Micro resource preset

### Production Environment

```bash
helm install n8n ../.. -f production-values.yaml
```

**Features**:
- PostgreSQL database
- 10Gi storage
- Ingress with TLS
- Medium resource preset
- Prometheus monitoring

### High Availability Setup

```bash
helm install n8n ../.. -f ha-values.yaml
```

**Features**:
- PostgreSQL with replication
- Queue mode with Redis
- Multiple replicas
- Large resource preset

## Workflow Import Instructions

1. Access n8n UI
2. Click "Workflows" in sidebar
3. Click "Import from File"
4. Select example JSON file
5. Configure credentials for MQTT, InfluxDB, PostgreSQL
6. Activate workflow

## Integration Prerequisites

### MQTT Integration

Deploy mosquitto-mqtt-pod first:

```bash
helm install mosquitto fireball/mosquitto-mqtt-pod
```

### InfluxDB Integration

Deploy influxdb-pod first:

```bash
helm install influxdb fireball/influxdb-pod
```

Create bucket for n8n data:

```bash
kubectl exec -it influxdb-pod-0 -- influx bucket create -n n8n-workflows
```

### PostgreSQL Integration

Deploy postgresql-pod first:

```bash
helm install postgresql fireball/postgresql-pod
```

Create database for n8n:

```bash
kubectl exec -it postgresql-pod-0 -- psql -U postgres -c "CREATE DATABASE n8n;"
```

## Customizing Workflows

### Modify MQTT Topics

Edit workflow JSON and change topic subscriptions:

```json
{
  "parameters": {
    "topic": "factory/line1/sensors/#"  // Change to your topic
  }
}
```

### Change Database Connections

Update credentials in n8n UI after import:

- MQTT: broker address, username, password
- InfluxDB: URL, token, org, bucket
- PostgreSQL: host, database, user, password

### Add Custom Logic

n8n supports JavaScript expressions in nodes:

```javascript
// Transform temperature from Celsius to Fahrenheit
{{ ($json.temperature * 9/5) + 32 }}

// Filter by shift
{{ new Date().getHours() >= 6 && new Date().getHours() < 14 ? 'day' : 'night' }}
```

## Testing Workflows

### Trigger Test MQTT Message

```bash
kubectl exec -it mosquitto-mqtt-pod-0 -- \
  mosquitto_pub -t "factory/sensors/temp" \
  -m '{"sensor":"temp01","value":72.5,"unit":"F"}'
```

### Check Workflow Execution

In n8n UI:
1. Go to "Executions" tab
2. View successful/failed runs
3. Inspect input/output data

### View Logs

```bash
kubectl logs -f deployment/n8n-pod
```

## Performance Tuning

### High Throughput Workflows

For processing > 100 executions/minute:

```yaml
queue:
  mode: true
resources:
  preset: large
```

### Long-Running Workflows

Increase timeout for complex processing:

```yaml
execution:
  timeout: 600  # 10 minutes
  maxTimeout: 3600  # 1 hour
```

## Troubleshooting

### Workflow Not Triggering

- Check MQTT broker connectivity
- Verify topic subscriptions match published topics
- Ensure webhook URLs are accessible

### Database Connection Errors

- Verify database credentials in secrets
- Check network policies allow pod communication
- Test connection from n8n pod:

```bash
kubectl exec -it n8n-pod-xxx -- nc -zv postgresql-pod 5432
```

### Memory Issues

- Increase resource limits
- Enable queue mode
- Reduce `saveDataOnSuccess` to "none" for high-volume workflows

## Additional Resources

- [n8n Documentation](https://docs.n8n.io)
- [n8n Workflow Templates](https://n8n.io/workflows)
- [Community Forum](https://community.n8n.io)
- [Fireball Industries Helm Charts](https://github.com/fireball-industries/helm-charts)

## Contributing

Have a useful industrial workflow? Submit a pull request with:

1. Workflow JSON file
2. README section describing use case
3. Required integrations and prerequisites

---

**Fireball Industries** - Ignite Your Factory Efficiency
