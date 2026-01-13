# Alert Manager

**Enterprise-grade Prometheus Alertmanager for managing and routing alerts**

Fireball Industries Podstore brings you a production-ready Alert Manager deployment optimized for Rancher and k3s clusters.

## 🎯 Overview

Alert Manager handles alerts sent by client applications such as Prometheus. It takes care of deduplicating, grouping, and routing them to the correct receiver integrations such as email, PagerDuty, Slack, or other notification systems.

## ✨ Key Features

- **Multi-Channel Notifications**: Send alerts to Slack, Email, PagerDuty, and more
- **Smart Routing**: Route alerts based on labels and severity
- **Alert Grouping**: Batch similar alerts to reduce notification noise
- **Silencing**: Temporarily mute alerts during maintenance windows
- **High Availability**: Deploy multiple replicas for redundancy
- **Persistent Storage**: Store alert state and silences across restarts

## 🚀 Quick Start

Deploy Alert Manager through the Rancher UI:

1. Navigate to **Apps & Marketplace** → **Charts**
2. Search for "Alert Manager"
3. Click **Install**
4. Configure deployment settings through the wizard
5. Click **Install** to deploy

## ⚙️ Configuration Options

### Resource Presets

Choose from pre-configured resource allocations:

- **Small**: 50m-200m CPU, 64Mi-256Mi Memory
- **Medium** (Default): 100m-500m CPU, 128Mi-512Mi Memory
- **Large**: 250m-1000m CPU, 256Mi-1Gi Memory
- **Custom**: Define your own resource limits

### Storage

- Default persistent storage: **2Gi**
- Configurable storage class
- Optional: Use emptyDir for testing (data loss on pod restart)

### Service Types

- **LoadBalancer** (Default): External access via cloud load balancer
- **NodePort**: Access via node IP and static port
- **ClusterIP**: Internal cluster access only

### Notification Receivers

Configure multiple notification channels:

- **Slack**: Webhook URL for team notifications
- **Email**: SMTP configuration for email alerts
- **PagerDuty**: Service key for incident management
- **Custom**: Add your own receiver configurations

## 📊 Integration with Prometheus

Configure Prometheus to send alerts to Alert Manager:

```yaml
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager.alertmanager.svc.cluster.local:9093
```

## 🔒 Security Features

- Non-root execution (UID 65534)
- Read-only root filesystem
- Dropped capabilities
- Security context constraints
- Network policies ready

## 📈 High Availability

For production deployments:

1. Set **Replica Count** to 3 or more
2. Enable **Pod Disruption Budget**
3. Configure appropriate anti-affinity rules
4. Use persistent storage

## 🧪 Testing Alerts

Send a test alert to verify configuration:

```bash
# Port-forward to Alert Manager
kubectl port-forward -n alertmanager svc/alertmanager 9093:9093

# Send test alert
curl -XPOST http://localhost:9093/api/v1/alerts -d '[{
  "labels": {
    "alertname": "TestAlert",
    "severity": "warning"
  },
  "annotations": {
    "summary": "Test alert from Fireball Industries"
  }
}]'
```

## 📚 Documentation

- [Alert Manager Official Docs](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [Configuration Reference](https://prometheus.io/docs/alerting/latest/configuration/)
- [Notification Templates](https://prometheus.io/docs/alerting/latest/notifications/)

## 💼 Production Best Practices

1. **Configure Multiple Receivers**: Don't rely on a single notification channel
2. **Use Inhibition Rules**: Prevent alert storms by suppressing dependent alerts
3. **Set Appropriate Timeouts**: Balance between alert fatigue and timely notifications
4. **Monitor Alert Manager**: Set up alerts for Alert Manager itself
5. **Regular Testing**: Periodically test notification channels
6. **Backup Configuration**: Store alert configurations in version control

## 🆘 Troubleshooting

### Alerts Not Being Received

1. Check Alert Manager logs:
   ```bash
   kubectl logs -n alertmanager -l app.kubernetes.io/name=alert-manager
   ```

2. Verify Prometheus configuration points to Alert Manager

3. Test receiver configurations in Alert Manager UI

### High Memory Usage

- Review alert retention period
- Check for alert storms (too many unique alerts)
- Consider increasing resources or implementing rate limiting

## 🏢 About Fireball Industries

Fireball Industries Podstore delivers enterprise-grade containerized solutions designed by **Patrick Ryan** and team. Our charts provide secure, scalable, and production-ready deployments optimized for k3s and Rancher.

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/fireball-industries/fireball-podstore-charts/issues)
- **Documentation**: [Chart Repository](https://github.com/fireball-industries/fireball-podstore-charts)

---

**Built with ❤️ by Fireball Industries | Patrick Ryan**
