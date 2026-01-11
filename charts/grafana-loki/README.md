# Grafana + Loki Helm Chart

## 🎯 Overview

The Grafana + Loki chart deploys an all-in-one observability solution combining Grafana dashboarding with Loki log aggregation in a single Kubernetes pod. This design provides a simplified, production-ready log management stack perfect for isolated deployments.

**Key Benefits:**
- **Simplified Architecture**: Single pod deployment reduces complexity
- **Pre-Integrated**: Loki datasource automatically configured in Grafana
- **Production-Ready**: Security hardened with proper contexts and resource limits
- **Flexible Sizing**: Resource presets for different workload sizes
- **Persistent**: Dashboards and logs survive pod restarts

## ✨ Key Features

- **Grafana 10.2.3**: Modern dashboarding and visualization platform
- **Loki 2.9.3**: Lightweight, horizontally-scalable log aggregation
- **Single Pod Design**: Both containers in one pod for simplified deployment
- **Pre-Configured Integration**: Loki datasource ready to use
- **Resource Presets**: Small/Medium/Large configurations
- **Persistent Storage**: Separate PVCs for Grafana and Loki data
- **Security Hardened**: Non-root containers, read-only filesystems, dropped capabilities
- **Health Checks**: Liveness, readiness, and startup probes
- **Rancher Integration**: Full Rancher Apps & Marketplace support

## 🚀 Quick Start

### Deploy via Rancher UI

1. Navigate to **Apps & Marketplace** → **Charts**
2. Search for "Grafana + Loki"
3. Click **Install**
4. Configure:
   - Resource presets (small/medium/large)
   - Storage sizes
   - Service types
   - Admin credentials
5. Click **Install**

### Deploy via Helm CLI

```bash
helm repo add fireball-podstore https://YOUR-USERNAME.github.io/fireball-podstore-charts
helm repo update

# Basic installation
helm install my-observability fireball-podstore/grafana-loki \
  --namespace grafana-loki \
  --create-namespace

# With custom configuration
helm install my-observability fireball-podstore/grafana-loki \
  --namespace grafana-loki \
  --create-namespace \
  --set grafana.resources.preset=large \
  --set loki.resources.preset=large \
  --set loki.persistence.size=100Gi
```

## ⚙️ Configuration

### Key Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `namespace.name` | Namespace for deployment | `grafana-loki` |
| `grafana.enabled` | Enable Grafana container | `true` |
| `grafana.admin.user` | Grafana admin username | `admin` |
| `grafana.admin.password` | Grafana admin password | Auto-generated |
| `grafana.resources.preset` | Resource preset | `medium` |
| `grafana.persistence.size` | Storage for dashboards | `10Gi` |
| `loki.enabled` | Enable Loki container | `true` |
| `loki.resources.preset` | Resource preset | `medium` |
| `loki.persistence.size` | Storage for logs | `50Gi` |
| `loki.config.limits.retentionPeriod` | Log retention | `744h` (31 days) |
| `service.grafana.type` | Grafana service type | `LoadBalancer` |
| `service.loki.type` | Loki service type | `ClusterIP` |

### Resource Presets

#### Grafana Presets
- **Small**: 250m-500m CPU, 512Mi-1Gi RAM, 5Gi storage
- **Medium**: 500m-1000m CPU, 1-2Gi RAM, 10Gi storage
- **Large**: 1000m-2000m CPU, 2-4Gi RAM, 20Gi storage

#### Loki Presets
- **Small**: 250m-500m CPU, 512Mi-1Gi RAM, 10Gi storage
- **Medium**: 1000m-2000m CPU, 2-4Gi RAM, 50Gi storage
- **Large**: 2000m-4000m CPU, 4-8Gi RAM, 100Gi storage

## 🔧 Usage

### Accessing Grafana

1. **Get Grafana URL**:
   ```bash
   kubectl get svc -n grafana-loki
   ```

2. **Get Admin Password**:
   ```bash
   kubectl get secret <release>-grafana-credentials -n grafana-loki \
     -o jsonpath='{.data.admin-password}' | base64 --decode
   ```

3. **Login**:
   - URL: `http://<SERVICE_IP>:3000`
   - Username: `admin`
   - Password: From step 2

### Sending Logs to Loki

Configure your log shippers to send logs to Loki:

**Loki Endpoint**:
```
http://<release>-loki.<namespace>.svc.cluster.local:3100
```

**Example Promtail Configuration**:
```yaml
clients:
  - url: http://my-observability-loki.grafana-loki.svc.cluster.local:3100/loki/api/v1/push
```

**Example Fluent Bit Configuration**:
```ini
[OUTPUT]
    Name loki
    Match *
    Host my-observability-loki.grafana-loki.svc.cluster.local
    Port 3100
    Labels job=fluentbit
```

### Querying Logs

1. In Grafana, navigate to **Explore**
2. Select **Loki** datasource (pre-configured)
3. Use LogQL to query logs:

```logql
# All logs from a namespace
{namespace="default"}

# Filter by level
{namespace="default"} |= "error"

# Count rate
rate({namespace="default"}[5m])

# JSON parsing
{namespace="default"} | json | level="error"
```

## 🌐 Ports

| Port | Service | Protocol | Description |
|------|---------|----------|-------------|
| 3000 | Grafana | HTTP | Web UI and API |
| 3100 | Loki | HTTP | Log ingestion and queries |
| 9095 | Loki | gRPC | Internal communication |

## 🔒 Security

This chart implements production security best practices:

### Grafana Container
- Runs as UID 472 (non-root)
- Read-only root filesystem
- Dropped all capabilities
- Explicit writable mounts for plugins and logs

### Loki Container
- Runs as UID 10001 (non-root)
- Read-only root filesystem
- Dropped all capabilities
- Minimal permissions

### Pod Security
- `runAsNonRoot: true`
- `fsGroup: 472` (Grafana)
- Seccomp profile: `RuntimeDefault`

### Network Policies

Enable network policies for additional security:

```yaml
networkPolicy:
  enabled: true
```

## 📊 Monitoring

### Prometheus Integration

Enable ServiceMonitor for Prometheus scraping:

```yaml
monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
```

### Metrics Endpoints

- **Grafana**: `http://<pod>:3000/metrics`
- **Loki**: `http://<pod>:3100/metrics`

## 🧪 Troubleshooting

### Check Pod Status

```bash
kubectl get pods -n grafana-loki
kubectl describe pod -n grafana-loki <POD_NAME>
```

### View Logs

```bash
# Grafana logs
kubectl logs -n grafana-loki <POD_NAME> -c grafana -f

# Loki logs
kubectl logs -n grafana-loki <POD_NAME> -c loki -f
```

### Common Issues

**Pod stuck in Pending**:
- Check PVC binding: `kubectl get pvc -n grafana-loki`
- Verify storage class exists
- Check node resources

**Grafana won't start**:
- Check init container logs for permission issues
- Verify PVC is writable
- Check admin credentials secret exists

**Loki not receiving logs**:
- Verify service is accessible: `kubectl get svc -n grafana-loki`
- Check firewall/network policies
- Test Loki endpoint: `curl http://<loki-ip>:3100/ready`

**High memory usage**:
- Review log ingestion rate
- Adjust `loki.config.limits.ingestionRateMb`
- Reduce retention period
- Scale up resources

## 🎓 Best Practices

1. **Storage Planning**: Size Loki storage based on retention needs and log volume
2. **Resource Allocation**: Start with medium preset, monitor, adjust as needed
3. **Retention Policy**: Configure based on compliance and storage constraints
4. **Log Shipping**: Use labels wisely for efficient querying
5. **Backups**: Regularly backup Grafana PVC for dashboard preservation
6. **Updates**: Test chart updates in non-production first
7. **Monitoring**: Enable ServiceMonitor for observing your observability stack

## 📚 Additional Resources

- [Grafana Documentation](https://grafana.com/docs/grafana/latest/)
- [Loki Documentation](https://grafana.com/docs/loki/latest/)
- [LogQL Query Language](https://grafana.com/docs/loki/latest/logql/)
- [Promtail Configuration](https://grafana.com/docs/loki/latest/clients/promtail/)

## 🏢 About

**Fireball Industries Podstore** - Making observability accessible and maintainable.

Crafted by **Patrick Ryan** for engineers who want their logs aggregated without the complexity of distributed systems.

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/fireball-industries/fireball-podstore-charts/issues)
- **Discussions**: [GitHub Discussions](https://github.com/fireball-industries/fireball-podstore-charts/discussions)
- **Documentation**: [Chart Repository](https://github.com/fireball-industries/fireball-podstore-charts)

---

**Built with ❤️ by Fireball Industries | Observability Without the Overhead**
