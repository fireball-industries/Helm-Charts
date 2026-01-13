# OCI Registry Setup - Modern Rancher Standard

## Quick Start

### 1. Push Charts to OCI Registry

```powershell
# GitHub Container Registry (GHCR)
.\push-to-oci.ps1 -Registry "ghcr.io/YOUR-USERNAME" -Username "YOUR-USERNAME" -Password "YOUR-PAT"

# Harbor Registry
.\push-to-oci.ps1 -Registry "harbor.example.com/helm-charts" -Username "admin" -Password "YOUR-PASSWORD"

# Docker Hub
.\push-to-oci.ps1 -Registry "registry-1.docker.io/YOUR-USERNAME" -Username "YOUR-USERNAME" -Password "YOUR-PASSWORD"
```

### 2. Add OCI Repository in Rancher

**Apps → Repositories → Create**

- **Type**: OCI
- **Name**: `fireball-podstore`
- **OCI Registry URL**: `oci://ghcr.io/YOUR-USERNAME`
- **Authentication**: 
  - Username: `YOUR-USERNAME`
  - Password: `YOUR-PAT` (GitHub Personal Access Token)

### 3. Install Charts

```bash
# Via Helm CLI
helm install my-prometheus oci://ghcr.io/YOUR-USERNAME/prometheus-pod --version 1.0.0

# Or use Rancher UI → Apps & Marketplace
```

## Registry Options

### GitHub Container Registry (RECOMMENDED)

**Pros**: Free, integrated with GitHub, good performance
**URL Pattern**: `oci://ghcr.io/YOUR-USERNAME`

Create PAT: GitHub → Settings → Developer settings → Personal access tokens
- Scope: `write:packages`, `read:packages`

### Harbor (Self-Hosted)

**Pros**: Full control, Helm Chart Museum compatibility
**URL Pattern**: `oci://harbor.example.com/PROJECT-NAME`

### Docker Hub

**Pros**: Widely used, familiar
**URL Pattern**: `oci://registry-1.docker.io/YOUR-USERNAME`
**Cons**: Rate limiting on free tier

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
