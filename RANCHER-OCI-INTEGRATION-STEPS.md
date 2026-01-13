# Rancher OCI Registry Integration - Step-by-Step Guide

## Current Status
- ✅ 19/20 charts pushed to GitHub Container Registry (ghcr.io/fireball-industries)
- ⚠️ 1/20 charts blocked (emberburn - needs CTO to grant package permissions)
- ❌ Charts not yet in Rancher catalog (need to add OCI repository)

## Prerequisites
- Rancher URL: https://rancher.embernet.ai/
- GitHub PAT: `<YOUR_GITHUB_PAT>` (write:packages scope)
- OCI Registry: `oci://ghcr.io/fireball-industries`

---

## Step-by-Step: Add OCI Repository to Rancher

### Step 1: Login to Rancher
1. Open browser and navigate to: **https://rancher.embernet.ai/**
2. Login with your credentials

### Step 2: Navigate to Repositories
1. In the left sidebar, click **"Apps"**
2. Click **"Repositories"** (or "Chart Repositories")
3. Click **"Create"** button (top-right)

### Step 3: Configure OCI Repository
Fill in the form with these exact values:

| Field | Value |
|-------|-------|
| **Name** | `fireball-podstore` |
| **Type** | Select **"OCI"** from dropdown |
| **Index URL** | `oci://ghcr.io/fireball-industries` |

### Step 4: Add Authentication
1. Check the box for **"Use Authentication"** or **"Enable Authentication"**
2. Fill in credentials:
   - **Username**: `fireball-industries`
   - **Password**: `<YOUR_GITHUB_PAT>`

### Step 5: Save and Verify
1. Click **"Create"** or **"Save"** button at the bottom
2. Wait for Rancher to sync (may take 30-60 seconds)
3. Repository should show status: **"Active"** or **"Ready"**

---

## Step-by-Step: Verify Charts in Catalog

### Step 1: Navigate to Charts
1. In Rancher, go to **Apps → Charts**
2. You should see a filter dropdown or search bar

### Step 2: Filter by Repository
1. Look for repository filter: Select **"fireball-podstore"**
2. OR search for chart names: `prometheus`, `grafana`, `influxdb`, etc.

### Step 3: Expected Results
You should see **19 charts** immediately:
- alert-manager
- codesys-x86
- codesys-edge-gateway
- codesys-runtime-arm
- grafana-loki
- industrial-iot
- ignition-edge
- influxdb-pod
- microvm
- mosquitto-mqtt
- n8n-pod
- fireball-node-exporter
- node-red
- postgresql-pod
- prometheus-pod
- sqlite-pod
- telegraf-pod
- timescaledb
- traefik-pod

**Missing: emberburn** (waiting for CTO to grant GitHub package permissions)

---

## Step-by-Step: Test Deploy a Chart

### Step 1: Select a Test Chart
1. From the Charts catalog, click on **"prometheus-pod"**
2. Click **"Install"** button

### Step 2: Configure Deployment
1. **Namespace**: Select or create `monitoring`
2. **Name**: `prometheus`
3. **Values**: Leave defaults or customize as needed

### Step 3: Deploy
1. Click **"Install"** at the bottom
2. Wait for deployment status: **"Active"**
3. Verify pods are running in the namespace

### Step 4: Verify
1. Go to **Workloads → Pods**
2. Filter by namespace: `monitoring`
3. Should see prometheus pods in **"Running"** state

---

## Troubleshooting

### Repository shows "Unauthorized" or "403"
- **Fix**: Double-check GitHub PAT has `read:packages` scope
- **Fix**: Verify PAT hasn't expired (current expires in 1 year)
- **Fix**: Test manually: `helm pull oci://ghcr.io/fireball-industries/prometheus-pod --version 1.0.0`

### Charts not appearing in catalog
- **Fix**: Wait 60 seconds for Rancher to sync
- **Fix**: Refresh the Rancher UI (F5)
- **Fix**: Check repository status is "Active"
- **Fix**: Verify OCI URL has NO trailing slash: `oci://ghcr.io/fireball-industries`

### emberburn chart missing
- **Expected**: This chart needs CTO to grant permissions
- **Action**: CTO needs to visit https://github.com/fireball-industries/Small-Application/pkgs/container/emberburn
- **Action**: Go to Package Settings → Manage Actions access
- **Action**: Add `Helm-Charts` repository with "Write" access
- **Then**: Run `helm push C:\HelmCharts\dist\emberburn-1.0.0.tgz oci://ghcr.io/fireball-industries`

---

## Next Steps After CTO Fixes emberburn

1. **Push emberburn**:
   ```powershell
   cd C:\HelmCharts
   helm registry login ghcr.io -u fireball-industries -p <YOUR_GITHUB_PAT>
   helm push "dist\emberburn-1.0.0.tgz" oci://ghcr.io/fireball-industries
   ```

2. **Refresh Rancher catalog**: Wait 60 seconds, refresh UI

3. **Verify 20/20 charts**: All charts should now appear

4. **Begin multi-cluster deployment**: Use Rancher Fleet or deploy individually

---

## Quick Reference

**OCI Registry**: `oci://ghcr.io/fireball-industries`  
**Username**: `fireball-industries`  
**Password**: `<YOUR_GITHUB_PAT>`  
**Repository Name in Rancher**: `fireball-podstore`  
**Status**: 19/20 charts ready (95%)


