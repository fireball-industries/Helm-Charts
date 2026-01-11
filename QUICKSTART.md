# Quick Start Guide - Fireball Industries Podstore Charts

**Get your Alert Manager running in 5 minutes!**

## Prerequisites

- Rancher 2.6+ managing your k3s cluster
- kubectl configured and connected to your cluster

## Option 1: Deploy via Rancher UI (Recommended)

### Step 1: Add Repository to Rancher

1. Login to your Rancher UI
2. Navigate to **Apps & Marketplace** → **Repositories**
3. Click **Create**
4. Fill in the details:
   - **Name**: `fireball-podstore-charts`
   - **Target**: Git repository containing Helm chart definitions
   - **Git Repo URL**: `https://github.com/fireball-industries/fireball-podstore-charts`
   - **Git Branch**: `main`
5. Click **Create**
6. Wait for repository to sync (watch the status indicator)

### Step 2: Deploy Alert Manager

1. Go to **Apps & Marketplace** → **Charts**
2. Find **Alert Manager** in the catalog (you can search for it)
3. Click on the chart
4. Click **Install**
5. Configure in the wizard:
   - **Namespace**: `alertmanager` (or your preference)
   - **Resource Preset**: Select `medium` (recommended for production)
   - **Storage Size**: `2Gi` (default is fine)
   - **Service Type**: `LoadBalancer` (or NodePort/ClusterIP)
6. Scroll down to configure notification receivers (optional but recommended):
   - Add Slack webhook URL
   - Configure email SMTP settings
   - Add PagerDuty service key
7. Click **Install**

### Step 3: Access Alert Manager

Once deployed (1-2 minutes):

1. Go to **Service Discovery** → **Services**
2. Find `alert-manager` service
3. Click the external endpoint (if using LoadBalancer)
4. Alert Manager UI will open in your browser

## Option 2: Deploy via Helm CLI

### Step 1: Add Repository

```bash
helm repo add fireball-podstore https://fireball-industries.github.io/fireball-podstore-charts
helm repo update
```

### Step 2: Install Chart

```bash
# Basic installation with defaults
helm install my-alertmanager fireball-podstore/alert-manager \
  --namespace alertmanager \
  --create-namespace

# Or with custom configuration
helm install my-alertmanager fireball-podstore/alert-manager \
  --namespace alertmanager \
  --create-namespace \
  --set resources.preset=large \
  --set persistence.size=5Gi \
  --set service.type=LoadBalancer
```

### Step 3: Check Status

```bash
# Check pods
kubectl get pods -n alertmanager

# Get service details
kubectl get svc -n alertmanager

# View logs
kubectl logs -n alertmanager -l app.kubernetes.io/name=alert-manager -f
```

### Step 4: Access Alert Manager

**For LoadBalancer:**
```bash
export SERVICE_IP=$(kubectl get svc my-alertmanager-alert-manager -n alertmanager -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Alert Manager UI: http://$SERVICE_IP:9093"
```

**For NodePort:**
```bash
export NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
export NODE_PORT=$(kubectl get svc my-alertmanager-alert-manager -n alertmanager -o jsonpath='{.spec.ports[0].nodePort}')
echo "Alert Manager UI: http://$NODE_IP:$NODE_PORT"
```

**For ClusterIP (local access):**
```bash
kubectl port-forward -n alertmanager svc/my-alertmanager-alert-manager 9093:9093
# Access at http://localhost:9093
```

## Next Steps

### Configure Prometheus Integration

Add Alert Manager to your Prometheus configuration:

```yaml
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - my-alertmanager-alert-manager.alertmanager.svc.cluster.local:9093
```

### Set Up Notification Channels

1. **Slack**: Get webhook from Slack → Apps → Incoming Webhooks
2. **Email**: Configure SMTP settings (Gmail, SendGrid, etc.)
3. **PagerDuty**: Get integration key from PagerDuty

Update values and upgrade:
```bash
helm upgrade my-alertmanager fireball-podstore/alert-manager \
  --namespace alertmanager \
  --set config.global.slack_api_url="YOUR_WEBHOOK_URL"
```

### Test Alerts

Send a test alert:
```bash
kubectl port-forward -n alertmanager svc/my-alertmanager-alert-manager 9093:9093

# In another terminal:
curl -XPOST http://localhost:9093/api/v1/alerts -d '[{
  "labels": {
    "alertname": "TestAlert",
    "severity": "warning",
    "instance": "test-instance"
  },
  "annotations": {
    "summary": "This is a test alert from Fireball Industries Podstore",
    "description": "Testing alert routing and notifications"
  }
}]'
```

Check the Alert Manager UI to see your test alert!

## Troubleshooting

### Pods Not Starting

```bash
# Check events
kubectl get events -n alertmanager --sort-by='.lastTimestamp'

# Check pod details
kubectl describe pod -n alertmanager -l app.kubernetes.io/name=alert-manager
```

### Can't Access UI

```bash
# Verify service
kubectl get svc -n alertmanager

# Check if pods are ready
kubectl get pods -n alertmanager

# View logs
kubectl logs -n alertmanager -l app.kubernetes.io/name=alert-manager
```

### Alerts Not Being Received

1. Check Prometheus configuration points to Alert Manager
2. Verify receiver configuration in Alert Manager config
3. Check Alert Manager logs for errors
4. Test with manual alert posting (see above)

## Need Help?

- 📖 [Full Documentation](./charts/alert-manager/README.md)
- 🐛 [Report Issues](https://github.com/fireball-industries/fireball-podstore-charts/issues)
- 💬 [GitHub Discussions](https://github.com/fireball-industries/fireball-podstore-charts/discussions)

---

**Fireball Industries Podstore** - Crafted by Patrick Ryan  
Enterprise Container Solutions for Modern Infrastructure
