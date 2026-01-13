# Fleet OCI Deployment Guide
## Advanced Deployment Patterns for OCI-Based Helm Charts

### Overview
This guide covers advanced Fleet deployment scenarios, multi-cluster strategies, and GitOps workflows for managing your Helm charts from OCI registry.

---

## Understanding Fleet Architecture

### How It Works

```
GitHub Repo (main branch)
   ↓
Fleet Controller (polls every 15s)
   ↓
Detects changes in releases/*.yaml
   ↓
Pulls charts from oci://ghcr.io/fireball-industries
   ↓
Deploys to target clusters
```

**Key Benefits:**
- ✅ Git is source of truth
- ✅ OCI registry holds chart packages
- ✅ No manual `helm install` needed
- ✅ Multi-cluster deployment from single repo
- ✅ Automatic rollback on Git revert

---

## Deployment Patterns

### Pattern 1: Single Namespace Per Category

**Current Setup** - Organized by function:

```
monitoring/     → Prometheus, Grafana, AlertManager, Node Exporter, Telegraf
databases/      → PostgreSQL, InfluxDB, TimescaleDB, SQLite
iot/            → CODESYS, Ignition, Home Assistant, Node-RED, Mosquitto
automation/     → n8n
infrastructure/ → Traefik, MicroVM
```

**When to use**: Clean separation of concerns, easier RBAC management

### Pattern 2: Environment-Based Namespaces

**Modify release YAMLs** for environment separation:

```yaml
# releases/prometheus-pod-prod.yaml
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: prometheus-prod
  namespace: kube-system
spec:
  chart: prometheus-pod
  version: 1.0.0
  repo: oci://ghcr.io/fireball-industries
  targetNamespace: monitoring-prod
  valuesContent: |-
    replicaCount: 3
    resources:
      requests:
        memory: "2Gi"
```

**When to use**: Same cluster, multiple environments

---

## Managing Deployments

### Deploy Additional Chart (e.g., EmberBurn)

1. **Create `releases/emberburn.yaml`**:
```yaml
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: emberburn
  namespace: kube-system
spec:
  chart: emberburn
  version: 1.0.0
  repo: oci://ghcr.io/fireball-industries
  targetNamespace: iot
  valuesContent: |-
    replicaCount: 1
```

2. **Commit and push**:
```bash
git add releases/emberburn.yaml
git commit -m "Add EmberBurn chart"
git push origin main
```

3. **Wait 15 seconds** - Fleet auto-deploys!

### Update Chart Values

**Edit the release YAML**:
```yaml
valuesContent: |-
  replicaCount: 3
  persistence:
    enabled: true
    size: 20Gi
```

**Commit and push** - Fleet auto-updates deployment

### Remove Chart

1. **Delete release YAML**: `rm releases/<chart-name>.yaml`
2. **Commit and push**
3. **Fleet auto-removes deployment**

---

## Monitoring Deployments

### Check Fleet Status

```bash
# List all bundles (one per cluster)
kubectl get bundles -n fleet-default

# Check HelmChart resources
kubectl get helmchart -A

# View specific chart status
kubectl describe helmchart -n kube-system prometheus-pod
```

### Health Checks

```bash
# Check all deployed Helm releases
helm list -A

# Verify specific release
helm status prometheus-pod -n monitoring

# Check pod status
kubectl get pods -A | grep -E 'monitoring|databases|iot|automation|infrastructure'
```

---

## Quick Command Reference

| Task | Command |
|------|---------|
| List all bundles | `kubectl get bundles -n fleet-default` |
| Check GitRepo sync | `kubectl get gitrepo -n fleet-local` |
| View Fleet logs | `kubectl logs -n cattle-fleet-system -l app=fleet-controller` |
| List HelmCharts | `kubectl get helmchart -A` |
| Check Helm releases | `helm list -A` |
| Delete deployment | Remove YAML from Git, commit, push |

---

## Next Steps

✅ **Charts deploying via Fleet**  
🔄 **Auto-updates from Git**  
📊 **Monitor in Rancher Cluster Explorer**  
🚀 **Scale by editing YAML and pushing**

For initial setup, see [FLEET-SETUP.md](FLEET-SETUP.md)

