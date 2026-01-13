# Rancher OCI Chart Deployment - Complete Guide

**Final Working Solution: Individual OCI Repositories**

Successfully deployed all 21 Helm charts to Rancher App Catalog using GitHub Container Registry (GHCR) as OCI storage.

---

## 🎯 Deployment Summary

**What We Accomplished:**
- ✅ 21/21 charts deployed to Rancher App Catalog
- ✅ Charts stored in GHCR (ghcr.io/fireball-industries)
- ✅ Users can browse and install charts via Apps → Charts
- ✅ Manual installation (not auto-deployed to clusters)

**Date Completed:** January 13, 2026

---

## 📋 Prerequisites

### Required Tools
- Helm 3.16.4+ (OCI support required)
- Git
- GitHub account with package permissions
- Rancher 2.6.0+

### Credentials
- GitHub Personal Access Token (PAT) with scopes:
  - `read:packages`
  - `write:packages`
- GitHub username: `ragaglialucas`
- Organization: `fireball-industries`

---

## 🏗️ Architecture

### OCI Registry Structure
```
ghcr.io/fireball-industries/
├── alert-manager:1.0.0
├── codesys-amd64-x86:1.0.0
├── codesys-edge-gateway:1.0.0
├── codesys-runtime-arm:1.0.0
├── emberburn:1.0.0
├── fireball-node-exporter:1.0.0
├── grafana-loki:1.0.0
├── ignition-edge:1.0.0
├── industrial-iot:1.0.0
├── influxdb-pod:1.0.0
├── microvm:1.0.0
├── mosquitto-mqtt:1.0.0
├── n8n-pod:1.0.0
├── node-red:1.0.0
├── postgresql-pod:1.0.0
├── prometheus-pod:1.0.0
├── sorba-sde:1.0.0
├── sqlite-pod:1.0.0
├── telegraf-pod:1.0.0
├── timescaledb:1.0.0
└── traefik-pod:1.0.0
```

### Rancher Integration
Each chart requires a separate OCI repository entry in Rancher Apps → Repositories.

**Why Individual Repositories?**
- Rancher OCI integration expects one chart per repository URL
- GHCR doesn't expose an OCI catalog/index API
- Each `oci://ghcr.io/fireball-industries/{chart-name}` is treated as a standalone repository

---

## 🚀 Deployment Process

### Step 1: Prepare Charts

#### 1.1 Chart Metadata Requirements
All charts MUST have simplified Rancher annotations to avoid indexing failures:

```yaml
# Chart.yaml - REQUIRED annotations format
annotations:
  catalog.cattle.io/certified: "partner"
  catalog.cattle.io/display-name: "Chart Display Name"
  catalog.cattle.io/release-name: "chart-name"
  catalog.cattle.io/namespace: "default-namespace"
  catalog.cattle.io/categories: "Forge Industrial,Category,Subcategory"
  catalog.cattle.io/os: "linux"
  catalog.cattle.io/type: "chart-type"
```

**❌ AVOID These Issues:**
- Duplicate `catalog.cattle.io/categories` annotations
- Excessive metadata (descriptions, vendor info, version requirements)
- Unquoted values
- Extra annotations like `auto-install`, `hidden`, `featured`

**Why?** Rancher's OCI parser has a metadata size limit and chokes on duplicate/complex annotations.

#### 1.2 Package Charts
```bash
cd C:\Users\rukaz\OneDrive\Documents\GitHub\Helm-Charts

# Package individual chart
helm package .\charts\chart-name --destination .\dist

# Verify package
helm show chart dist/chart-name-1.0.0.tgz
```

### Step 2: Push to GitHub Container Registry

#### 2.1 Authenticate with GHCR
```bash
helm registry login ghcr.io -u ragaglialucas -p ghp_YourPATHere
```

#### 2.2 Push Chart
```bash
helm push dist/chart-name-1.0.0.tgz oci://ghcr.io/fireball-industries
```

**Expected Output:**
```
Pushed: ghcr.io/fireball-industries/chart-name:1.0.0
Digest: sha256:abc123...
```

#### 2.3 Verify in GHCR
```bash
helm pull oci://ghcr.io/fireball-industries/chart-name --version 1.0.0
```

### Step 3: Add to Rancher App Catalog

#### 3.1 Create OCI Repository
1. Navigate to **Apps → Repositories**
2. Click **Create**
3. Configure:
   - **Name:** `chart-name` (lowercase, matches GHCR package name)
   - **Target:** Select **OCI Repository**
   - **OCI Repository Host URL:** `oci://ghcr.io/fireball-industries/chart-name`
   - **Authentication:** Select **HTTP Basic Auth**
     - **Username:** `ragaglialucas`
     - **Password:** `ghp_YourPATHere`
   - **Refresh Interval:** `1 hour` (default)
4. Click **Create**

#### 3.2 Verify Repository Status
- Repository should show **Active** status
- Wait 10-30 seconds for indexing

#### 3.3 Check Chart Availability
1. Navigate to **Apps → Charts**
2. Filter by repository name
3. Chart should appear with **Install** button

**If chart doesn't appear:**
- Repository shows Active but chart not in catalog = metadata issue
- Delete repository, fix Chart.yaml annotations, repackage, re-push, recreate repository

---

## 🔧 Troubleshooting

### Issue: Chart Not Appearing Despite Active Repository

**Symptoms:**
- Repository status: Active
- Chart count: 0 or not displayed
- No errors in repository details

**Root Cause:** Duplicate or excessive Rancher annotations in Chart.yaml

**Solution:**
1. Check Chart.yaml for duplicate `catalog.cattle.io/categories`
2. Remove all non-essential annotations
3. Keep only the 7 required fields (see Step 1.1)
4. Repackage chart
5. Re-push to GHCR (overwrites existing version)
6. **Delete** existing Rancher repository
7. **Recreate** repository (forces fresh metadata pull)

**Example Fix:**
```yaml
# ❌ BROKEN - Duplicate categories
annotations:
  catalog.cattle.io/categories: "Forge Industrial,Monitoring"
  catalog.cattle.io/vendor: "Fireball Industries"
  catalog.cattle.io/categories: "Monitoring,Logging"  # DUPLICATE!
  catalog.cattle.io/description: |
    Long multi-line description...

# ✅ FIXED - Minimal required fields
annotations:
  catalog.cattle.io/certified: "partner"
  catalog.cattle.io/display-name: "Grafana + Loki Pod"
  catalog.cattle.io/release-name: "grafana-loki"
  catalog.cattle.io/namespace: "observability"
  catalog.cattle.io/categories: "Forge Industrial,Monitoring,Observability"
  catalog.cattle.io/os: "linux"
  catalog.cattle.io/type: "cluster-tool"
```

### Issue: 403 Forbidden When Pushing to GHCR

**Symptoms:**
```
Error: unexpected status from POST request to https://ghcr.io/v2/fireball-industries/chart-name/blobs/uploads/: 403 Forbidden
```

**Root Cause:** Insufficient GitHub package permissions

**Solution:**
1. Go to https://github.com/orgs/fireball-industries/packages
2. Find the chart package
3. Settings → Manage Actions access
4. Add user/PAT with **Write** permission
5. Retry push

### Issue: Helm Can't Find Chart.yaml

**Symptoms:**
```
Error: Chart.yaml file is missing
```

**Root Cause:** Directory structure issue or file encoding problem

**Solution:**
```bash
# Method 1: Package from parent directory
cd C:\Users\rukaz\OneDrive\Documents\GitHub\Helm-Charts
helm package .\charts\chart-name --destination .\dist

# Method 2: Recreate chart directory
# Copy working chart structure (e.g., postgresql-pod)
# Replace Chart.yaml, values.yaml, templates/, questions.yaml
# Package the new directory
```

### Issue: Repository Refresh Not Pulling Updated Chart

**Symptoms:**
- Pushed new version to GHCR
- Clicked "Refresh" in Rancher
- Old chart still showing

**Solution:**
Rancher caches OCI metadata aggressively:
1. **Delete** the repository
2. Wait 10 seconds
3. **Recreate** repository with same URL
4. New metadata will be pulled

---

## 📝 Deployment Checklist

### Per-Chart Deployment
- [ ] Chart.yaml has simplified annotations (7 required fields only)
- [ ] Chart packaged: `helm package .\charts\chart-name --destination .\dist`
- [ ] Authenticated with GHCR: `helm registry login ghcr.io`
- [ ] Pushed to GHCR: `helm push dist/chart-name-1.0.0.tgz oci://ghcr.io/fireball-industries`
- [ ] Verified in GHCR: `helm pull oci://ghcr.io/fireball-industries/chart-name --version 1.0.0`
- [ ] Created OCI repository in Rancher
- [ ] Repository shows Active status
- [ ] Chart appears in Apps → Charts
- [ ] Install button works

### All Charts Complete
- [ ] 21/21 charts in GHCR
- [ ] 21/21 OCI repositories created in Rancher
- [ ] 21/21 charts browsable in Apps → Charts
- [ ] Documentation updated

---

## 📊 Deployment Results

### All 21 Charts Deployed
1. alert-manager
2. codesys-amd64-x86
3. codesys-edge-gateway
4. codesys-runtime-arm
5. emberburn
6. fireball-node-exporter
7. grafana-loki
8. ignition-edge
9. industrial-iot
10. influxdb-pod
11. microvm
12. mosquitto-mqtt
13. n8n-pod
14. node-red
15. postgresql-pod
16. prometheus-pod
17. sorba-sde
18. sqlite-pod
19. telegraf-pod
20. timescaledb
21. traefik-pod

### Lessons Learned
1. **Rancher OCI Limitations:** Doesn't support multi-chart OCI repositories
2. **Metadata Matters:** Excessive/duplicate annotations break indexing
3. **Manual is OK:** Individual repositories work fine at this scale (21 charts)
4. **GHCR Works Well:** Reliable, free, integrates with GitHub permissions
5. **Delete/Recreate:** Fastest way to force metadata refresh in Rancher

---

## 🔄 Updating Charts

### Adding New Chart Version
```bash
# 1. Update Chart.yaml version
# version: 1.0.1

# 2. Package
helm package .\charts\chart-name --destination .\dist

# 3. Push
helm push dist/chart-name-1.0.1.tgz oci://ghcr.io/fireball-industries

# 4. Rancher auto-detects new version (may take up to 1 hour)
# Or manually refresh repository in Rancher UI
```

### Adding Completely New Chart
```bash
# 1. Create chart with simplified annotations
# 2. Package and push to GHCR
# 3. Create new OCI repository in Rancher
# 4. Verify in Apps → Charts
```

---

## 🎓 Key Takeaways

### What Worked
- ✅ Individual OCI repositories per chart
- ✅ Simplified Rancher annotations (7 required fields)
- ✅ GHCR as OCI storage
- ✅ HTTP Basic Auth for authentication
- ✅ Delete/recreate repositories to force metadata refresh

### What Didn't Work
- ❌ Single Rancher OCI repository for all charts
- ❌ Git Repository mode (required index.yaml)
- ❌ HTTP Index mode (manual maintenance)
- ❌ Fleet GitOps auto-deployment (CTO wanted manual catalog)
- ❌ Complex Chart.yaml annotations (broke indexing)

### Performance Notes
- Chart indexing: 10-30 seconds per repository
- Repository refresh: Up to 1 hour automatic, instant manual
- GHCR push: ~2-5 seconds per chart
- Rancher catalog UI: Responsive with 21 charts

---

## 📚 Reference Documentation

- [Rancher Apps & Marketplace](https://ranchermanager.docs.rancher.com/pages-for-subheaders/helm-charts-in-rancher)
- [Helm OCI Support](https://helm.sh/docs/topics/registries/)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Helm Chart Annotations](https://helm.sh/docs/topics/charts/#the-chartyaml-file)

---

## 👤 Deployment Credits

**Deployment Date:** January 13, 2026  
**Deployed By:** Lucas Ragaglia (ragaglialucas)  
**Organization:** Fireball Industries  
**Total Charts:** 21  
**Success Rate:** 100%  
**Deployment Method:** Individual OCI Repositories via GHCR

---

*For questions or issues, contact the platform team or refer to individual chart README.md files.*
