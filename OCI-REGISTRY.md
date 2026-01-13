# OCI Registry Setup - Modern Rancher Standard

## GitHub Container Registry - The Only Sensible Choice

Your charts are already on GitHub. Use GitHub Container Registry (GHCR). It's free, fast, and already integrated. Why would you pay for or self-host anything else?

## Quick Start

### 1. Create GitHub Personal Access Token

GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)

**Scopes needed:**
- `write:packages` (push charts)
- `read:packages` (pull charts)
- `delete:packages` (optional - manage chart versions)

Save the token - you'll need it.

### 2. Push All Charts to GHCR

```powershell
.\push-to-oci.ps1 -Registry "ghcr.io/YOUR-USERNAME" -Username "YOUR-USERNAME" -Password "YOUR-PAT"
```

Done. All 20 charts are now on GHCR at `oci://ghcr.io/YOUR-USERNAME/CHART-NAME`.

### 3. Add OCI Repository in Rancher

**Apps → Repositories → Create**

- **Type**: OCI
- **Name**: `fireball-podstore`
- **OCI Registry URL**: `oci://ghcr.io/YOUR-USERNAME`
- **Authentication**: 
  - Username: `YOUR-USERNAME`
  - Password: `YOUR-PAT`

### 4. Install Charts

```bash
# Via Helm CLI
helm install my-prometheus oci://ghcr.io/YOUR-USERNAME/prometheus-pod --version 1.0.0

# Or use Rancher UI → Apps & Marketplace
```

## Why GitHub Container Registry?

✅ **Free** - Unlimited public packages, 500MB free private storage  
✅ **Integrated** - Your code is already on GitHub  
✅ **Fast** - CDN-backed, globally distributed  
✅ **No Rate Limits** - Unlike Docker Hub's 100 pulls/6hrs for free tier  
✅ **Package Insights** - Download stats, vulnerability scanning  
✅ **Simple Auth** - Same PAT you already use for Git  
✅ **OCI Native** - Built for modern container/chart distribution  

**Alternatives (and why not to use them):**
- **Docker Hub**: Rate limits, costs money for private repos, slower
- **Harbor**: Self-hosted = your problem to maintain/backup/secure
- **Cloud registries (ACR/GCR/ECR)**: Costs money, cloud lock-in

Unless you have a specific compliance requirement, use GHCR.

## Rancher Configuration

### Global Repository (Cluster-Wide)

1. Cluster → Apps → Repositories
2. Create → OCI
3. Configure authentication
4. All namespaces can now install from this repo

### Namespace-Scoped Repository

1. Project/Namespace → Apps → Repositories  
2. Create → OCI
3. Only accessible within that namespace

## Install Commands

```bash
# List available versions
helm show chart oci://ghcr.io/YOUR-USERNAME/prometheus-pod

# Install specific version
helm install prom oci://ghcr.io/YOUR-USERNAME/prometheus-pod \
  --version 1.0.0 \
  --namespace monitoring \
  --create-namespace

# Upgrade
helm upgrade prom oci://ghcr.io/YOUR-USERNAME/prometheus-pod --version 1.0.1

# With values
helm install prom oci://ghcr.io/YOUR-USERNAME/prometheus-pod \
  --values custom-values.yaml \
  --version 1.0.0
```

## Update Workflow

```powershell
# 1. Update chart version in Chart.yaml
# 2. Push to OCI
.\push-to-oci.ps1 -Registry "ghcr.io/YOUR-USERNAME" -Username "YOUR-USERNAME" -Password "YOUR-PAT"

# 3. Users upgrade
helm upgrade RELEASE-NAME oci://ghcr.io/YOUR-USERNAME/CHART-NAME --version NEW-VERSION
```

## Migration from HTTP/HTTPS Repos

**Old (Legacy HTTP)**:
```yaml
# index.yaml based
helm repo add fireball https://example.com/charts
helm repo update
helm install app fireball/chart-name
```

**New (OCI Standard)**:
```yaml
# Direct OCI reference
helm install app oci://ghcr.io/username/chart-name --version 1.0.0
```

No `helm repo add` required - charts are pulled directly by reference.
