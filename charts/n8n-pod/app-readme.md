# n8n Workflow Automation

Automate your industrial workflows with n8n's powerful visual automation platform.

## Quick Deploy

Deploy n8n for workflow automation in your factory with one click. Pre-configured for MQTT, InfluxDB, PostgreSQL, and webhook integrations.

## Key Features

- **Visual Workflow Designer** - Drag-and-drop automation builder
- **400+ Integrations** - Connect to any system or service
- **Industrial Ready** - MQTT, OPC-UA, InfluxDB, PostgreSQL support
- **Webhook Triggers** - External system automation
- **Secure Credentials** - Encrypted storage for API keys and passwords

## Common Use Cases

1. **Sensor Data Processing** - MQTT → Transform → InfluxDB
2. **Alert Workflows** - Monitor thresholds → Send notifications
3. **ETL Pipelines** - Extract from APIs → Transform → Load to database
4. **System Orchestration** - Coordinate multiple factory systems

## Quick Configuration

**Resource Size**: Choose micro (dev), small (light), medium (production), or large (heavy processing)

**Database**: SQLite (default) or PostgreSQL (recommended for production)

**Persistence**: 5Gi storage for workflows and executions

**Access**: ClusterIP, NodePort, LoadBalancer, or Ingress

## Getting Started

After deployment:

1. Access n8n UI via ingress or port-forward
2. Login with configured credentials
3. Create your first workflow
4. Connect to MQTT broker or database
5. Set up automation triggers

## Industrial Integrations

- **MQTT**: mosquitto-mqtt-pod for sensor data
- **InfluxDB**: influxdb-pod for time-series storage
- **PostgreSQL**: postgresql-pod for relational data
- **Node-RED**: Chain with existing automations
- **APIs**: Connect to MES, ERP, SCADA systems

## Documentation

See full README.md for:
- Detailed configuration options
- Workflow examples (MQTT processing, alerting, ETL)
- Database setup instructions
- Queue mode for high throughput
- Troubleshooting guide

---

**Fireball Industries** - Ignite Your Factory Efficiency
