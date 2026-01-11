# Prometheus Pod - Quick Reference

**One-page cheat sheet for common operations**

---

## 🚀 Installation

```bash
# Default install
helm install prometheus ./prometheus-pod -n monitoring --create-namespace

# With preset
helm install prometheus ./prometheus-pod -n monitoring --set resourcePreset=large

# HA mode
helm install prometheus ./prometheus-pod -n monitoring \
  --set deploymentMode=ha \
  --set replicaCount=3

# From example
helm install prometheus ./prometheus-pod -n monitoring \
  -f examples/ha-prometheus.yaml
```

---

## 🔧 Management Commands

### Helm Operations

```bash
# Upgrade
helm upgrade prometheus ./prometheus-pod -n monitoring

# Rollback
helm rollback prometheus -n monitoring

# Uninstall
helm uninstall prometheus -n monitoring

# Show values
helm get values prometheus -n monitoring

# Show all resources
helm get manifest prometheus -n monitoring
```

### Kubectl Operations

```bash
# Check pods
kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus-pod

# Describe pod
kubectl describe pod prometheus-0 -n monitoring

# View logs
kubectl logs -n monitoring prometheus-0 -c prometheus -f

# Check PVC
kubectl get pvc -n monitoring

# Check service
kubectl get svc prometheus -n monitoring

# Port forward
kubectl port-forward -n monitoring svc/prometheus 9090:9090
```

---

## 📊 Common Value Overrides

```bash
# Change resource preset
--set resourcePreset=xlarge

# Custom resources
--set resources.requests.memory=4Gi \
--set resources.requests.cpu=2 \
--set resources.limits.memory=8Gi \
--set resources.limits.cpu=4

# Storage size
--set storage.size=100Gi

# Retention
--set retentionTime=30d \
--set retentionSize=50GB

# Enable ingress
--set ingress.enabled=true \
--set ingress.host=prometheus.example.com

# Enable Thanos
--set thanos.enabled=true

# Replicas (HA mode)
--set replicaCount=5

# Storage class
--set storage.storageClass=fast-ssd
```

---

## 🔍 Troubleshooting

### Pod won't start

```bash
# Check pod status
kubectl describe pod prometheus-0 -n monitoring

# Check logs
kubectl logs prometheus-0 -n monitoring -c prometheus

# Check events
kubectl get events -n monitoring --sort-by='.lastTimestamp'

# Validate config
kubectl exec prometheus-0 -n monitoring -- \
  promtool check config /etc/prometheus/prometheus.yml
```

### Storage issues

```bash
# Check PVC status
kubectl get pvc -n monitoring

# Check PV
kubectl get pv

# Describe PVC
kubectl describe pvc prometheus-storage-prometheus-0 -n monitoring

# Check disk usage
kubectl exec prometheus-0 -n monitoring -- df -h /prometheus
```

### Query issues

```bash
# Test query API
kubectl exec prometheus-0 -n monitoring -- \
  wget -qO- 'http://localhost:9090/api/v1/query?query=up'

# Check targets
kubectl exec prometheus-0 -n monitoring -- \
  wget -qO- 'http://localhost:9090/api/v1/targets'

# Check config
kubectl exec prometheus-0 -n monitoring -- \
  wget -qO- 'http://localhost:9090/api/v1/status/config'
```

### Health checks

```bash
# Check readiness
kubectl exec prometheus-0 -n monitoring -- \
  wget -qO- http://localhost:9090/-/ready

# Check health
kubectl exec prometheus-0 -n monitoring -- \
  wget -qO- http://localhost:9090/-/healthy

# Check TSDB stats
kubectl exec prometheus-0 -n monitoring -- \
  wget -qO- http://localhost:9090/api/v1/status/tsdb
```

---

## 🧪 PowerShell Scripts

### manage-prometheus.ps1

```powershell
# Deploy
.\scripts\manage-prometheus.ps1 -Action deploy

# Upgrade
.\scripts\manage-prometheus.ps1 -Action upgrade

# Health check
.\scripts\manage-prometheus.ps1 -Action health-check

# Backup
.\scripts\manage-prometheus.ps1 -Action backup -BackupPath ./backups

# Restore
.\scripts\manage-prometheus.ps1 -Action restore -BackupPath ./backups/backup-20240101

# Query
.\scripts\manage-prometheus.ps1 -Action query -Query "up"

# Status
.\scripts\manage-prometheus.ps1 -Action status

# Tune
.\scripts\manage-prometheus.ps1 -Action tune

# Delete
.\scripts\manage-prometheus.ps1 -Action delete

# Validate
.\scripts\manage-prometheus.ps1 -Action validate
```

### test-prometheus.ps1

```powershell
# All tests
.\scripts\test-prometheus.ps1

# Specific tests
.\scripts\test-prometheus.ps1 -TestType scraping
.\scripts\test-prometheus.ps1 -TestType alerts
.\scripts\test-prometheus.ps1 -TestType storage
.\scripts\test-prometheus.ps1 -TestType queries
.\scripts\test-prometheus.ps1 -TestType ha-failover

# Custom namespace
.\scripts\test-prometheus.ps1 -Namespace prod-monitoring
```

### generate-config.ps1

```powershell
# Kubernetes config
.\scripts\generate-config.ps1 -Scenario kubernetes -OutputFile prom.yml

# App monitoring
.\scripts\generate-config.ps1 -Scenario app-monitoring \
  -ExtraExporters "mysql,redis" \
  -OutputFile app-prom.yml

# Minimal
.\scripts\generate-config.ps1 -Scenario minimal

# Federated
.\scripts\generate-config.ps1 -Scenario federated -OutputFile fed.yml

# Custom
.\scripts\generate-config.ps1 -Scenario custom -OutputFile custom.yml
```

---

## 📈 PromQL Quick Reference

```promql
# Check if targets are up
up

# Total up targets
sum(up)

# Targets by job
count(up) by (job)

# HTTP request rate (5m)
rate(prometheus_http_requests_total[5m])

# Memory usage
prometheus_engine_query_duration_seconds_sum

# TSDB block size
prometheus_tsdb_storage_blocks_bytes

# Scrape duration
scrape_duration_seconds

# Time series count
prometheus_tsdb_head_series
```

---

## 🎯 Resource Presets

| Preset | Memory | CPU | Storage | Retention |
|--------|--------|-----|---------|-----------|
| small | 512Mi | 1 | 10Gi | 7d |
| medium | 2Gi | 2 | 20Gi | 15d |
| large | 8Gi | 4 | 50Gi | 30d |
| xlarge | 16Gi | 8 | 100Gi | 60d |

**Formula for custom sizing:**

- Memory: `(Series Count × 2KB) + (Scrape Interval Buffer × 100MB)`
- Storage: `(Series Count × 1-2 bytes per sample) × Retention Seconds`

---

## 🔐 Security Checklist

- ✅ Non-root user (UID 65534)
- ✅ Read-only root filesystem
- ✅ Capabilities dropped
- ✅ Seccomp: RuntimeDefault
- ✅ RBAC: Read-only cluster access
- ✅ Network policies enabled
- ✅ Pod Security Standards: Restricted

---

## 📋 Configuration Files

| File | Purpose |
|------|---------|
| `values.yaml` | Default configuration values |
| `Chart.yaml` | Helm chart metadata |
| `templates/` | Kubernetes manifests |
| `docs/README.md` | Full documentation (100+ pages) |
| `docs/SECURITY.md` | Security guide |
| `examples/` | Pre-built configurations |
| `scripts/` | PowerShell automation |

---

## 🔗 Useful URLs

**Once port-forwarded (9090):**

- UI: http://localhost:9090
- Graph: http://localhost:9090/graph
- Targets: http://localhost:9090/targets
- Alerts: http://localhost:9090/alerts
- Config: http://localhost:9090/config
- Status: http://localhost:9090/status
- TSDB: http://localhost:9090/tsdb-status

**API Endpoints:**

- Query: `/api/v1/query?query=up`
- Range: `/api/v1/query_range`
- Targets: `/api/v1/targets`
- Alerts: `/api/v1/alerts`
- Rules: `/api/v1/rules`
- Config: `/api/v1/status/config`
- TSDB: `/api/v1/status/tsdb`

---

## 💡 Tips & Tricks

1. **Always use resource presets first** - easier than custom sizing
2. **Enable HA mode for prod** - use 3+ replicas
3. **Set retention based on disk** - monitor `prometheus_tsdb_storage_blocks_bytes`
4. **Use network policies** - enabled by default, restrict egress if needed
5. **Monitor Prometheus itself** - check `up{job="prometheus"}`
6. **Backup before upgrades** - use `manage-prometheus.ps1 -Action backup`
7. **Test with minimal preset** - validate configs in dev first
8. **Use ServiceMonitor** - if Prometheus Operator is available
9. **Enable Thanos for HA** - deduplication and long-term storage
10. **Check TSDB compaction** - alerts fire if compaction fails

---

**Fireball Industries - We Play With Fire So You Don't Have To™**
