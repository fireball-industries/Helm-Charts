# Telegraf Pod - Quick Reference Guide

**Fireball Industries - We Play With Fire So You Don't Have To™**

---

## 🚀 5-Minute Quick Start

```bash
# Deploy with defaults (recommended for testing)
helm install telegraf . --namespace telegraf --create-namespace

# Verify deployment
kubectl get pods -n telegraf

# Check metrics
kubectl port-forward -n telegraf svc/telegraf 8080:8080
# Browse to http://localhost:8080/metrics
```

---

## 📊 Common Deployment Scenarios

### Scenario 1: Full Kubernetes Cluster Monitoring

```bash
helm install telegraf . \
  --namespace telegraf \
  --set deploymentMode=daemonset \
  --set resourcePreset=large \
  --set hostNetwork=true \
  --set hostVolumes.enabled=true \
  --set rbac.clusterRole=true
```

**Use when**: You need complete cluster observability (nodes, pods, containers)

### Scenario 2: Docker Host Monitoring

```bash
helm install telegraf . \
  --namespace telegraf \
  --set deploymentMode=deployment \
  --set resourcePreset=medium \
  --set hostVolumes.enabled=true
```

**Use when**: Monitoring Docker containers on a single host

### Scenario 3: Application Metrics Collection

```bash
helm install telegraf . \
  --namespace telegraf \
  --set deploymentMode=deployment \
  --set resourcePreset=small \
  --values examples/custom-app-monitoring.yaml
```

**Use when**: Scraping Prometheus endpoints from your apps

### Scenario 4: High Availability Setup

```bash
helm install telegraf . \
  --namespace telegraf \
  --values examples/high-availability.yaml
```

**Use when**: Production deployments requiring redundancy

---

## 🔧 Essential Commands

### Deployment Management

```bash
# Install
helm install telegraf . -n telegraf --create-namespace

# Upgrade
helm upgrade telegraf . -n telegraf

# Uninstall
helm uninstall telegraf -n telegraf

# Check status
helm status telegraf -n telegraf

# Get values
helm get values telegraf -n telegraf
```

### Pod Operations

```bash
# List pods
kubectl get pods -n telegraf

# View logs
kubectl logs -n telegraf -l app.kubernetes.io/name=telegraf

# Follow logs
kubectl logs -n telegraf -l app.kubernetes.io/name=telegraf -f

# Describe pod
kubectl describe pod -n telegraf <pod-name>

# Exec into pod
kubectl exec -it -n telegraf <pod-name> -- /bin/sh
```

### Configuration Testing

```bash
# Test configuration syntax
kubectl exec -n telegraf deployment/telegraf -- \
  telegraf --test --config /etc/telegraf/telegraf.conf

# Test specific plugin
kubectl exec -n telegraf deployment/telegraf -- \
  telegraf --test --config /etc/telegraf/telegraf.conf --input-filter cpu

# Collect metrics for 10 seconds
kubectl exec -n telegraf deployment/telegraf -- \
  telegraf --test --config /etc/telegraf/telegraf.conf --test-wait 10
```

### Debugging

```bash
# Check events
kubectl get events -n telegraf --sort-by='.lastTimestamp'

# Check resource usage
kubectl top pods -n telegraf

# View ConfigMap
kubectl get configmap -n telegraf -o yaml

# Check RBAC permissions
kubectl auth can-i get pods --as=system:serviceaccount:telegraf:telegraf
```

---

## 🎛️ Configuration Quick Reference

### Resource Presets

```yaml
resourcePreset: small    # 60s intervals, 256MB RAM max
resourcePreset: medium   # 10s intervals, 512MB RAM max (default)
resourcePreset: large    # 1s intervals, 1GB RAM max
resourcePreset: custom   # Define your own
```

### Deployment Modes

```yaml
deploymentMode: deployment  # Single instance (default)
deploymentMode: daemonset   # One per node
```

### Common Settings

```yaml
# Enable InfluxDB output
config:
  outputs:
    influxdb_v2:
      enabled: true
      urls: ["http://influxdb:8086"]
      token: "${INFLUX_TOKEN}"

# Enable Kubernetes metrics
config:
  inputs:
    kube_inventory:
      enabled: true

rbac:
  create: true
  clusterRole: true

# Enable Docker metrics
hostVolumes:
  enabled: true

config:
  inputs:
    docker:
      enabled: true
```

---

## 🔐 Secret Management

```bash
# Create secret for InfluxDB
kubectl create secret generic telegraf-secrets \
  --namespace telegraf \
  --from-literal=influx-token='YOUR_TOKEN_HERE'

# Use in values.yaml
env:
  - name: INFLUX_TOKEN
    valueFrom:
      secretKeyRef:
        name: telegraf-secrets
        key: influx-token

config:
  outputs:
    influxdb_v2:
      token: "${INFLUX_TOKEN}"
```

---

## 🚨 Troubleshooting Quick Fixes

### Pod Keeps Restarting

```bash
# Check for OOMKilled
kubectl describe pod -n telegraf <pod-name> | grep -i oom

# Solution: Increase resource preset
helm upgrade telegraf . -n telegraf --set resourcePreset=large
```

### No Metrics Collected

```bash
# Test inputs
kubectl exec -n telegraf deployment/telegraf -- \
  telegraf --test --config /etc/telegraf/telegraf.conf

# Check RBAC (for K8s metrics)
helm upgrade telegraf . -n telegraf --set rbac.clusterRole=true

# Enable host volumes (for Docker metrics)
helm upgrade telegraf . -n telegraf --set hostVolumes.enabled=true
```

### Can't Access Kubernetes Metrics

```bash
# Enable RBAC
helm upgrade telegraf . -n telegraf \
  --set rbac.create=true \
  --set rbac.clusterRole=true
```

### High Memory Usage

```bash
# Reduce buffer size
helm upgrade telegraf . -n telegraf \
  --set config.agent.metric_buffer_limit=5000

# Increase collection interval
helm upgrade telegraf . -n telegraf \
  --set config.agent.interval=30s
```

---

## 📋 Pre-Deployment Checklist

- [ ] Choose deployment mode (deployment vs daemonset)
- [ ] Select resource preset (small/medium/large)
- [ ] Create secrets for credentials (never commit!)
- [ ] Configure output destinations (InfluxDB, etc.)
- [ ] Enable required input plugins
- [ ] Set up RBAC if collecting K8s metrics
- [ ] Enable hostVolumes if collecting Docker metrics
- [ ] Configure network policies for security
- [ ] Test in non-production first

---

## 🔍 Validation Steps

After deployment:

1. **Check pod status**:
   ```bash
   kubectl get pods -n telegraf
   # Should show Running status
   ```

2. **Verify logs**:
   ```bash
   kubectl logs -n telegraf -l app.kubernetes.io/name=telegraf --tail=20
   # Should show successful metric collection
   ```

3. **Test configuration**:
   ```bash
   kubectl exec -n telegraf deployment/telegraf -- telegraf --test
   # Should return metrics without errors
   ```

4. **Check metrics endpoint**:
   ```bash
   kubectl port-forward -n telegraf svc/telegraf 8080:8080
   curl http://localhost:8080/metrics | head -20
   # Should return Prometheus-formatted metrics
   ```

5. **Verify output connectivity** (if using InfluxDB):
   ```bash
   influx query 'from(bucket:"telegraf") |> range(start: -5m) |> limit(n:10)'
   # Should return recent metrics
   ```

---

## 📚 Documentation Links

- **Full Guide**: [docs/README.md](docs/README.md) - 100+ pages
- **Security**: [docs/SECURITY.md](docs/SECURITY.md) - Best practices
- **Examples**: [examples/](examples/) - 6 pre-configured scenarios
- **Scripts**: [scripts/](scripts/) - Automation tools

---

## 🎯 Resource Preset Decision Tree

```
How often do you need metrics?

Every 60+ seconds → resourcePreset: small
Every 10-30 seconds → resourcePreset: medium (default)
Every 1-10 seconds → resourcePreset: large
Sub-second or >5000 metrics → resourcePreset: custom
```

---

## 🤖 Management Scripts

```powershell
# Health check
.\scripts\manage-telegraf.ps1 -Action health-check -Namespace telegraf

# Test metrics
.\scripts\test-metrics.ps1 -Namespace telegraf

# Generate config
.\scripts\generate-config.ps1 -Scenario k8s-full -OutputPath values.yaml

# Performance tuning
.\scripts\manage-telegraf.ps1 -Action tune -Namespace telegraf
```

---

## ⚡ Performance Tips

1. **Use DaemonSet for system metrics** - More efficient than single collector
2. **Enable persistence** - Buffer metrics during output failures
3. **Adjust collection interval** - Match to your actual needs
4. **Filter unnecessary metrics** - Reduce cardinality
5. **Use resource presets** - Pre-tuned for common scenarios
6. **Monitor buffer usage** - Watch for metric drops

---

## 🔥 Patrick Ryan's Pro Tips

1. **Start small** - Use `resourcePreset: small` first, scale up if needed
2. **Test locally** - Always `--dry-run` before production
3. **Never commit secrets** - Use Kubernetes Secrets, check .gitignore
4. **Monitor the monitor** - Watch Telegraf's own metrics
5. **Read the logs** - Seriously, we put useful stuff in there
6. **RTFM** - We wrote 100+ pages for a reason
7. **When in doubt, restart** - Classic IT solution still works
8. **Backup before upgrade** - Future you will thank present you

---

## 📞 Getting Help

**Quick help**: Check [docs/README.md](docs/README.md) FAQ section

**Still stuck?**
- Email: support@fireball.industries
- Issues: https://github.com/fireball-industries/telegraf-pod/issues

**Before asking:**
1. Check logs: `kubectl logs -n telegraf <pod-name>`
2. Test config: `telegraf --test`
3. Search docs
4. Check examples

---

**Fireball Industries** - We Play With Fire So You Don't Have To™

*Quick Reference v1.0*
