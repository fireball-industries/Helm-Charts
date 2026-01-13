# Rancher Fleet Setup Guide
## Deploying Helm Charts from OCI Registry via GitOps

### Overview
This guide shows you how to use Rancher Fleet to automatically deploy all 19 Helm charts from GitHub Container Registry (GHCR) using GitOps principles.

**What You'll Get:**
- Auto-deployment of charts from `oci://ghcr.io/fireball-industries`
- Git-based configuration (change Git = change cluster)
- Multi-cluster deployment capability
- Automatic updates when you push to GitHub

---

## Prerequisites

✅ 19/20 charts in GHCR (`ghcr.io/fireball-industries/*`)  
✅ Rancher with Fleet enabled (Resources → Git Repos menu visible)  
✅ GitHub repo: `https://github.com/fireball-industries/Helm-Charts`  
✅ Kubernetes cluster(s) managed by Rancher

---

## Step-by-Step Setup

### Step 1: Prepare GitHub Authentication (if private repo)

If your repo is private, create a secret in Rancher:

1. **Rancher → Storage → Secrets → Create**
2. **Type**: Basic Auth
3. **Name**: `github-helm-charts`
4. **Namespace**: `fleet-default`
5. **Username**: Your GitHub username
6. **Password**: Your GitHub PAT (read access)

### Step 2: Add Git Repository to Fleet

1. **Navigate to Fleet**:
   - Click **Resources** (left sidebar)
   - Click **Git Repos**

2. **Click "Create"** button (top-right)

3. **Fill in Repository Details**:

   | Field | Value |
   |-------|-------|
   | **Name** | `fireball-helm-charts` |
   | **Repository URL** | `https://github.com/fireball-industries/Helm-Charts` |
   | **Branch** | `main` |
   | **Paths** | `releases` |

4. **Authentication** (if private repo):
   - Check "Use Authentication"
   - Select secret: `github-helm-charts`

5. **Advanced Options** (expand):
   - **Helm Secret Name for OCI**: Create secret for GHCR access (see Step 3)

### Step 3: Create OCI Registry Secret

Fleet needs credentials to pull from GHCR:

**Option A: Via Rancher UI**
1. **Storage → Secrets → Create**
2. **Type**: Docker Registry
3. **Name**: `ghcr-auth`
4. **Namespace**: `kube-system`
5. **Registry URL**: `ghcr.io`
6. **Username**: `fireball-industries`
7. **Password**: `<YOUR_GITHUB_PAT>`

**Option B: Via kubectl**
```bash
kubectl create secret docker-registry ghcr-auth \
  --docker-server=ghcr.io \
  --docker-username=fireball-industries \
  --docker-password=<YOUR_GITHUB_PAT> \
  --namespace=kube-system
```

### Step 4: Configure Cluster Targets (Optional)

By default, Fleet deploys to all clusters. To target specific clusters:

1. **Edit `fleet.yaml`** in your repo
2. **Update `targetCustomizations`**:

```yaml
targetCustomizations:
- name: production-only
  clusterSelector:
    matchLabels:
      env: production
```

3. **Label your clusters** in Rancher:
   - Cluster Explorer → Clusters → Edit Config
   - Add label: `env=production`

### Step 5: Save and Watch Deployment

1. **Click "Create"** at the bottom
2. **Monitor deployment**:
   - Resources → Git Repos → `fireball-helm-charts`
   - Check **Status** column (should show "Active")
   - Click repo name → See deployed resources

3. **Verify in cluster**:
   - Cluster Explorer → Workloads → Pods
   - Should see pods in namespaces: `monitoring`, `databases`, `iot`, `automation`, `infrastructure`

---

## Verifying Deployment

### Check Fleet Status
```bash
# List all Fleet resources
kubectl get bundles -n fleet-default

# Check specific chart deployment
kubectl get helmchart -n kube-system prometheus-pod

# View Helm releases
helm list -A
```

### Expected Namespaces Created
- `monitoring` - Prometheus, Grafana, Alert Manager, Node Exporter, Telegraf
- `databases` - PostgreSQL, InfluxDB, TimescaleDB, SQLite
- `iot` - CODESYS, Ignition, Node-RED, Mosquitto, Industrial IoT
- `automation` - n8n
- `infrastructure` - Traefik, MicroVM

---

## Troubleshooting

### Git Repo shows "Error" status

**Check logs**:
```bash
kubectl logs -n cattle-fleet-system -l app=fleet-controller
```

**Common fixes**:
- Verify GitHub URL is correct
- Check authentication secret exists
- Ensure `releases/` folder has YAML files

### Charts not deploying

**Check HelmChart resources**:
```bash
kubectl get helmchart -A
kubectl describe helmchart -n kube-system <chart-name>
```

**Common fixes**:
- Verify OCI secret exists: `kubectl get secret ghcr-auth -n kube-system`
- Test OCI access manually: `helm pull oci://ghcr.io/fireball-industries/prometheus-pod --version 1.0.0`
- Check GitHub PAT has `read:packages` scope

### "Chart not found" errors

**Verify chart exists in GHCR**:
```bash
helm pull oci://ghcr.io/fireball-industries/<chart-name> --version 1.0.0
```

**If missing**: Chart needs to be pushed to GHCR first

### Wrong version deployed

**Update version in release YAML**:
1. Edit `releases/<chart-name>.yaml`
2. Change `version: 1.0.0` to desired version
3. Commit and push to GitHub
4. Fleet auto-updates within 15 seconds

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

## Next Steps

✅ **All 19 charts should now be deploying**  
📊 **Monitor in Rancher**: Cluster Explorer → Workloads  
🔄 **Auto-updates**: Push to GitHub = auto-deploy  
📝 **Customize**: Edit `releases/*.yaml` files for custom values

See [FLEET-DEPLOYMENT.md](FLEET-DEPLOYMENT.md) for advanced deployment patterns and multi-cluster configuration.

---

## Quick Reference

**Fleet GitRepo**: Resources → Git Repos → `fireball-helm-charts`  
**Chart Releases**: `releases/*.yaml` files  
**OCI Registry**: `oci://ghcr.io/fireball-industries`  
**Status Check**: `kubectl get bundles -n fleet-default`  
**Logs**: `kubectl logs -n cattle-fleet-system -l app=fleet-controller`

