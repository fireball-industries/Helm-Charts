# Alert Manager Helm Chart

Enterprise-grade Prometheus Alertmanager optimized for Rancher deployment on k3s clusters.

## Introduction

This Helm chart deploys Alert Manager, the component responsible for handling alerts sent by Prometheus. It manages deduplication, grouping, routing, and notification delivery to various receivers.

**Maintained by**: Patrick Ryan - Fireball Industries  
**Chart Version**: 1.0.0  
**App Version**: v0.26.0

## Prerequisites

- Kubernetes 1.25+
- Helm 3.8+
- Rancher 2.6+ (for Rancher catalog integration)
- Persistent Volume provisioner (for persistent storage)

## Installation

### Via Rancher UI

1. Navigate to **Apps & Marketplace** → **Charts**
2. Search for "Alert Manager"
3. Click **Install**
4. Fill in the deployment wizard
5. Click **Install**

### Via Helm CLI

```bash
# Add the Fireball Podstore repository
helm repo add fireball-podstore https://fireball-industries.github.io/fireball-podstore-charts
helm repo update

# Install Alert Manager
helm install my-alertmanager fireball-podstore/alert-manager \
  --namespace alertmanager \
  --create-namespace \
  --set resources.preset=medium

# Install with custom values
helm install my-alertmanager fireball-podstore/alert-manager \
  --namespace alertmanager \
  --create-namespace \
  --values my-values.yaml
```

## Configuration

### Key Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `namespace.name` | Namespace for deployment | `alertmanager` |
| `namespace.create` | Create namespace automatically | `true` |
| `replicaCount` | Number of replicas | `1` |
| `image.tag` | Alert Manager image version | `v0.26.0` |
| `resources.preset` | Resource preset (small/medium/large/custom) | `medium` |
| `persistence.enabled` | Enable persistent storage | `true` |
| `persistence.size` | Storage size | `2Gi` |
| `service.type` | Service type | `LoadBalancer` |
| `service.port` | Service port | `9093` |

### Resource Presets

#### Small
- CPU: 50m request, 200m limit
- Memory: 64Mi request, 256Mi limit
- Use case: Development, testing

#### Medium (Default)
- CPU: 100m request, 500m limit
- Memory: 128Mi request, 512Mi limit
- Use case: Small to medium production

#### Large
- CPU: 250m request, 1000m limit
- Memory: 256Mi request, 1Gi limit
- Use case: Large production environments

### Notification Configuration

#### Slack Integration

```yaml
config:
  global:
    slack_api_url: "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
  receivers:
    - name: "slack-warnings"
      slack_configs:
        - channel: "#alerts"
          title: "Alert Notification"
```

#### Email Integration

```yaml
config:
  global:
    smtp_smarthost: "smtp.gmail.com:587"
    smtp_from: "alerts@yourcompany.com"
    smtp_auth_username: "your-email@gmail.com"
    smtp_auth_password: "your-app-password"
    smtp_require_tls: true
  receivers:
    - name: "email-team"
      email_configs:
        - to: "team@yourcompany.com"
```

#### PagerDuty Integration

```yaml
config:
  receivers:
    - name: "pagerduty-critical"
      pagerduty_configs:
        - service_key: "YOUR_PAGERDUTY_SERVICE_KEY"
```

### Advanced Configuration

#### High Availability Setup

```yaml
replicaCount: 3
podDisruptionBudget:
  enabled: true
  minAvailable: 2
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchLabels:
              app.kubernetes.io/name: alert-manager
          topologyKey: kubernetes.io/hostname
```

#### Custom Alert Routing

```yaml
config:
  route:
    receiver: "default"
    group_by: ['alertname', 'cluster', 'service']
    routes:
      - match:
          severity: critical
        receiver: pagerduty-critical
        continue: true
      - match:
          severity: warning
        receiver: slack-warnings
      - match:
          team: database
        receiver: database-team
```

#### Inhibition Rules

```yaml
config:
  inhibit_rules:
    # Don't send warnings if critical alert is firing
    - source_match:
        severity: critical
      target_match:
        severity: warning
      equal: ['alertname', 'instance']
```

## Persistence

Alert Manager stores alert state and silences in persistent storage. This ensures that:

- Silences survive pod restarts
- Alert state is maintained across deployments
- No alert duplication after restarts

### Using Custom Storage Class

```yaml
persistence:
  enabled: true
  size: 5Gi
  storageClassName: "fast-ssd"
```

### Disabling Persistence (Not Recommended for Production)

```yaml
persistence:
  enabled: false
```

## Security

This chart follows security best practices:

- **Non-root execution**: Runs as UID 65534 (nobody)
- **Read-only root filesystem**: Prevents runtime modifications
- **Dropped capabilities**: Minimal Linux capabilities
- **Security context**: Strict pod and container security policies
- **No privilege escalation**: Container cannot gain additional privileges

### Custom Security Context

```yaml
podSecurityContext:
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
  
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  capabilities:
    drop:
      - ALL
```

## Monitoring

### Health Checks

The chart includes comprehensive health probes:

- **Liveness Probe**: Ensures Alert Manager is running
- **Readiness Probe**: Confirms Alert Manager is ready to receive traffic
- **Startup Probe**: Allows up to 150 seconds for initial startup

### Prometheus Metrics

Alert Manager exposes metrics on port 9093 at `/metrics`:

```yaml
# ServiceMonitor for Prometheus Operator
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: alertmanager
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: alert-manager
  endpoints:
    - port: http
      path: /metrics
```

## Upgrading

### Upgrading the Chart

```bash
# Update repository
helm repo update

# Upgrade release
helm upgrade my-alertmanager fireball-podstore/alert-manager \
  --namespace alertmanager \
  --reuse-values
```

### Upgrading with New Values

```bash
helm upgrade my-alertmanager fireball-podstore/alert-manager \
  --namespace alertmanager \
  --values updated-values.yaml
```

## Uninstallation

```bash
# Uninstall the release
helm uninstall my-alertmanager --namespace alertmanager

# Optional: Delete namespace
kubectl delete namespace alertmanager
```

**Note**: Persistent volumes may need to be manually deleted if using a ReclaimPolicy of Retain.

## Troubleshooting

### Pods Not Starting

Check events:
```bash
kubectl get events -n alertmanager --sort-by='.lastTimestamp'
```

Check pod logs:
```bash
kubectl logs -n alertmanager -l app.kubernetes.io/name=alert-manager
```

### Configuration Errors

Validate configuration:
```bash
# Get current config
kubectl get configmap -n alertmanager alertmanager-config -o yaml

# Validate Alert Manager config locally
amtool check-config /path/to/alertmanager.yml
```

### Notification Not Working

1. Check Alert Manager UI at `http://<service-ip>:9093`
2. Verify receiver configuration
3. Test with manual alert posting
4. Check Alert Manager logs for delivery errors

### Performance Issues

If experiencing high memory usage:

1. Review alert retention: `--data.retention`
2. Check for alert storms
3. Implement proper grouping and inhibition rules
4. Consider increasing resources

## Examples

### Complete Production Configuration

See [examples/production-values.yaml](examples/production-values.yaml) for a complete production setup.

### Multi-Tenant Setup

Deploy multiple instances for different teams:

```bash
# Team A
helm install team-a-alerts fireball-podstore/alert-manager \
  --namespace team-a \
  --create-namespace \
  --set namespace.name=team-a

# Team B
helm install team-b-alerts fireball-podstore/alert-manager \
  --namespace team-b \
  --create-namespace \
  --set namespace.name=team-b
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

Copyright © 2026 Fireball Industries - Patrick Ryan. All rights reserved.

## Support

- **Issues**: [GitHub Issues](https://github.com/fireball-industries/fireball-podstore-charts/issues)
- **Documentation**: [Chart Repository](https://github.com/fireball-industries/fireball-podstore-charts)
- **Email**: patrick@fireball-industries.com

---

**Fireball Industries Podstore** - Enterprise Container Solutions by Patrick Ryan
