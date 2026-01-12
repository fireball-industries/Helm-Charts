# n8n Workflow Automation Pod

![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square)
![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)
![AppVersion: 1.25.1](https://img.shields.io/badge/AppVersion-1.25.1-informational?style=flat-square)

**Ignite Your Factory Efficiency** with intelligent workflow automation for industrial systems.

## Overview

n8n (pronounced "nodemation") is a powerful workflow automation platform that connects your industrial systems together. This Helm chart deploys n8n in production-ready configurations optimized for factory automation, IIoT data processing, and multi-system orchestration.

### Key Features

- 🔄 **400+ Integrations** - Connect to MQTT, databases, APIs, webhooks, and cloud services
- 🏭 **Industrial Focus** - Pre-configured for MQTT, InfluxDB, PostgreSQL, and OPC-UA workflows
- 📊 **Visual Workflow Designer** - Drag-and-drop interface for building complex automations
- 🔐 **Secure by Default** - Encryption at rest, basic auth, and secure credential storage
- 📈 **Scalable Architecture** - Queue mode support for high-throughput processing
- 🎯 **Production Ready** - PostgreSQL database, persistent storage, health checks
- 📉 **Observable** - Prometheus metrics and ServiceMonitor integration

### Industrial Use Cases

1. **MQTT Data Processing**
   - Subscribe to sensor topics
   - Filter and transform data
   - Route to InfluxDB, PostgreSQL, or APIs

2. **Alert Workflows**
   - Monitor thresholds in real-time
   - Send notifications (email, SMS, Slack)
   - Trigger corrective actions

3. **ETL Pipelines**
   - Extract data from multiple sources
   - Transform with custom logic
   - Load into data warehouses

4. **System Orchestration**
   - Coordinate multiple factory systems
   - Schedule maintenance tasks
   - Automate reporting workflows

## Installation

### Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- PV provisioner support (if persistence is enabled)
- PostgreSQL database (recommended for production)

### Quick Start

```bash
# Add Fireball Industries Helm repository
helm repo add fireball https://charts.fireballindustries.com
helm repo update

# Install with default configuration (SQLite, 2Gi storage)
helm install n8n fireball/n8n-pod

# Install with PostgreSQL backend
helm install n8n fireball/n8n-pod \
  --set database.type=postgres \
  --set database.postgres.host=postgresql-pod \
  --set database.postgres.password=your-password

# Install with ingress enabled
helm install n8n fireball/n8n-pod \
  --set ingress.enabled=true \
  --set ingress.host=n8n.factory.local \
  --set webhooks.url=https://n8n.factory.local
```

### Production Deployment

```bash
helm install n8n fireball/n8n-pod \
  --set resources.preset=medium \
  --set database.type=postgres \
  --set database.postgres.host=postgresql-pod \
  --set database.postgres.database=n8n \
  --set database.postgres.user=n8n \
  --set database.postgres.password=secure-password \
  --set persistence.size=10Gi \
  --set ingress.enabled=true \
  --set ingress.host=n8n.yourdomain.com \
  --set ingress.tls.enabled=true \
  --set webhooks.enabled=true \
  --set webhooks.url=https://n8n.yourdomain.com \
  --set queue.mode=true \
  --set monitoring.serviceMonitor.enabled=true
```

## Configuration

### Resource Presets

Choose a preset based on your workload:

| Preset | CPU Request | CPU Limit | Memory Request | Memory Limit | Use Case |
|--------|-------------|-----------|----------------|--------------|----------|
| micro  | 100m | 500m | 256Mi | 512Mi | Testing/development |
| small  | 250m | 1000m | 512Mi | 1Gi | Light workflows (< 10/min) |
| medium | 500m | 2000m | 1Gi | 2Gi | **Recommended** - Production |
| large  | 1000m | 4000m | 2Gi | 4Gi | Heavy processing |
| custom | - | - | - | - | Define your own |

```yaml
resources:
  preset: medium  # Change to match your needs
```

### Database Configuration

#### SQLite (Default - Not Recommended for Production)

```yaml
database:
  type: sqlite
```

**Limitations**: Single-threaded, no horizontal scaling, slower performance

#### PostgreSQL (Recommended)

```yaml
database:
  type: postgres
  postgres:
    host: postgresql-pod
    port: 5432
    database: n8n
    user: n8n
    password: your-secure-password
    # Optional SSL
    ssl:
      enabled: true
      ca: ""
      cert: ""
      key: ""
      rejectUnauthorized: true
```

**Benefits**: ACID compliance, better performance, supports queue mode

### Persistence

```yaml
persistence:
  enabled: true
  size: 5Gi
  storageClass: "local-path"  # or your storage class
  accessMode: ReadWriteOnce
  existingClaim: ""  # Use existing PVC
  paths:
    data: /home/node/.n8n
```

### Security

#### Basic Authentication

```yaml
security:
  basicAuth:
    enabled: true
    user: admin
    password: change-me-please
```

#### Encryption Key

Auto-generated encryption key for credentials. Override if needed:

```yaml
security:
  encryptionKey: "your-32-character-key-here"
```

### Webhooks

Enable webhooks for external triggers:

```yaml
webhooks:
  enabled: true
  url: "https://n8n.yourdomain.com"  # Must be accessible from external systems
  testUrl: "https://n8n.yourdomain.com"
```

### Queue Mode (High Throughput)

For processing many workflows concurrently:

```yaml
queue:
  mode: true
  health:
    active: true
    port: 5678
```

**Note**: Requires external Redis for queue coordination (not included in this chart).

### Ingress

```yaml
ingress:
  enabled: true
  className: "traefik"
  host: "n8n.factory.local"
  path: /
  pathType: Prefix
  tls:
    enabled: true
    secretName: n8n-tls
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
```

### Industrial Integrations

#### MQTT

```yaml
integrations:
  mqtt:
    enabled: true
    broker: "mosquitto-mqtt-pod"
    port: 1883
    username: ""
    password: ""
```

#### InfluxDB

```yaml
integrations:
  influxdb:
    enabled: true
    url: "http://influxdb-pod:8086"
    token: "your-influx-token"
    org: "fireball-industries"
    bucket: "sensors"
```

#### PostgreSQL

```yaml
integrations:
  postgresql:
    enabled: true
    url: "postgresql-pod"
    port: 5432
```

### Monitoring

#### Prometheus Metrics

```yaml
monitoring:
  metrics:
    enabled: true
    path: /metrics
  serviceMonitor:
    enabled: true
    interval: 30s
    labels:
      release: prometheus
```

#### Health Checks

```yaml
monitoring:
  healthcheck:
    enabled: true
    livenessProbe:
      httpGet:
        path: /healthz
        port: http
      initialDelaySeconds: 60
      periodSeconds: 30
    readinessProbe:
      httpGet:
        path: /healthz
        port: http
      initialDelaySeconds: 30
      periodSeconds: 10
```

## Industrial Workflow Examples

### Example 1: MQTT to InfluxDB Data Pipeline

```json
{
  "name": "MQTT Sensor Data to InfluxDB",
  "nodes": [
    {
      "name": "MQTT Trigger",
      "type": "n8n-nodes-base.mqtt",
      "parameters": {
        "broker": "mosquitto-mqtt-pod",
        "topic": "factory/sensors/#"
      }
    },
    {
      "name": "Parse JSON",
      "type": "n8n-nodes-base.set"
    },
    {
      "name": "Write to InfluxDB",
      "type": "n8n-nodes-base.influxdb",
      "parameters": {
        "url": "http://influxdb-pod:8086",
        "bucket": "sensors"
      }
    }
  ]
}
```

### Example 2: Temperature Alert Workflow

```json
{
  "name": "High Temperature Alert",
  "nodes": [
    {
      "name": "MQTT Trigger",
      "type": "n8n-nodes-base.mqtt",
      "parameters": {
        "topic": "factory/sensors/temp"
      }
    },
    {
      "name": "Check Threshold",
      "type": "n8n-nodes-base.if",
      "parameters": {
        "conditions": {
          "number": [
            {
              "value1": "={{$json.temperature}}",
              "operation": "larger",
              "value2": 75
            }
          ]
        }
      }
    },
    {
      "name": "Send Alert",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "url": "https://alerts.factory.com/api/notify",
        "method": "POST"
      }
    }
  ]
}
```

See `examples/` directory for more industrial automation workflows.

## Architecture

### Components

- **n8n Application**: Node.js workflow engine
- **Database**: SQLite (default) or PostgreSQL (recommended)
- **Persistent Storage**: 5Gi for workflows, credentials, and executions
- **Service**: ClusterIP on port 5678
- **Ingress**: Optional HTTP/HTTPS access
- **ServiceMonitor**: Prometheus metrics collection

### Data Flow

```
External Systems → Webhooks → n8n → Database
                                  ↓
MQTT Broker ←→ n8n Workflows ←→ InfluxDB
                                  ↓
                              PostgreSQL
```

## Troubleshooting

### n8n Won't Start

Check database connectivity:

```bash
kubectl logs -n <namespace> deployment/n8n-pod
kubectl get secret n8n-pod -o jsonpath='{.data.DB_POSTGRESDB_HOST}' | base64 -d
```

### Webhooks Not Working

Verify webhook URL is accessible from external systems:

```bash
curl https://your-n8n-host/webhook-test/test
```

Ensure ingress is configured correctly:

```bash
kubectl get ingress n8n-pod
kubectl describe ingress n8n-pod
```

### High Memory Usage

Increase resources or enable queue mode:

```yaml
resources:
  preset: large
queue:
  mode: true
```

### Workflows Not Executing

Check execution settings:

```yaml
execution:
  mode: "regular"  # or "queue"
  timeout: 300
  maxTimeout: 3600
  saveDataOnSuccess: "all"
  saveDataOnError: "all"
```

## Upgrading

### From 0.x to 1.x

No breaking changes. Standard Helm upgrade:

```bash
helm upgrade n8n fireball/n8n-pod
```

### Backup Before Upgrade

```bash
# Backup PostgreSQL database
kubectl exec -it postgresql-pod-0 -- pg_dump -U n8n n8n > n8n-backup.sql

# Backup SQLite (if using)
kubectl cp <namespace>/n8n-pod-xxx:/home/node/.n8n/database.sqlite ./database.sqlite
```

## Uninstallation

```bash
# Uninstall release
helm uninstall n8n

# Remove PVC (optional - WARNING: deletes all workflows)
kubectl delete pvc n8n-pod
```

## Support

- **Documentation**: [n8n Docs](https://docs.n8n.io)
- **Community Forum**: [community.n8n.io](https://community.n8n.io)
- **Fireball Industries**: support@fireballindustries.com
- **Issues**: [GitHub Issues](https://github.com/fireball-industries/helm-charts/issues)

## License

This Helm chart is licensed under Apache 2.0.

n8n is licensed under the [Sustainable Use License](https://github.com/n8n-io/n8n/blob/master/LICENSE.md).

---

**Fireball Industries** - Ignite Your Factory Efficiency
