# Helm Charts OCI Registry Deployment Status

**Date:** January 13, 2026  
**Registry:** ghcr.io/fireball-industries  
**Status:** 18/20 charts successfully deployed (90%)

## ✅ Successfully Deployed Charts (18)

1. alert-manager v1.0.0
2. codesys-x86 v1.0.0
3. codesys-edge-gateway v1.0.0
4. codesys-runtime-arm v1.0.0
5. grafana-loki v1.0.0
6. industrial-iot v1.0.0 (home-assistant-pod)
7. influxdb-pod v1.0.0
8. microvm v1.0.0
9. mosquitto-mqtt v1.0.0
10. n8n-pod v1.0.0
11. fireball-node-exporter v1.0.0 (node-exporter-pod)
12. node-red v1.0.0
13. postgresql-pod v1.0.0
14. prometheus-pod v1.0.0
15. sqlite-pod v1.0.0
16. telegraf-pod v1.0.0
17. timescaledb v1.0.0
18. traefik-pod v1.0.0

## ⚠️ Pending Charts (2)

### 1. emberburn v1.0.0
**Status:** Package created but push failed  
**Error:** `403 Forbidden` - GitHub Container Registry permission denied  
**Fix Required:** GitHub organization admin needs to grant write permissions for emberburn package  
**Action:** Contact GitHub org admin to update package permissions

### 2. ignition-edge v1.0.0
**Status:** YAML syntax error  
**Error:** `error converting YAML to JSON: yaml: line 43: did not find expected key`  
**Fix Required:** Fix Chart.yaml syntax error on line 43  
**File:** `charts/ignition-edge-pod/Chart.yaml`  
**Action:** Review and fix YAML formatting

## 🔧 Issues Encountered & Solutions

### Issue 1: Helm "Chart.yaml file is missing" Error
**Charts Affected:** 6 charts (alert-manager, codesys-runtime, grafana-loki, influxdb-pod, mosquitto-mqtt-pod, timescaledb-pod)  
**Root Cause:** PowerShell Get-ChildItem showing duplicate directory entries (display bug), causing Helm's directory loader to fail  
**Solution:** Create fresh chart structure with `helm create`, copy files from original charts, then package successfully

### Issue 2: Chart Name vs Directory Name Mismatch
**Charts Affected:** 7 charts  
**Root Cause:** Chart.yaml `name:` field different from directory name  
**Examples:**
- Directory: `codesys-amd64-x86` → Chart name: `codesys-x86`
- Directory: `home-assistant-pod` → Chart name: `industrial-iot`
- Directory: `ignition-edge-pod` → Chart name: `ignition-edge`

**Solution:** Updated push-to-oci-fixed.ps1 to read actual chart name from Chart.yaml instead of using directory name

### Issue 3: Helm Push Success Misdetected as Failure
**Root Cause:** Helm writes "Pushed:" message to stderr instead of stdout  
**Impact:** PowerShell error handling caught success message as error  
**Solution:** Updated script to check for "Pushed:" or "Digest:" in output regardless of stream

## 📋 Next Steps for Rancher Deployment

### 1. Add OCI Repository to Rancher
```
URL: oci://ghcr.io/fireball-industries
Name: Fireball Industries Podstore
Authentication:
  Username: fireball-industries
  Password: <GitHub Personal Access Token>
  Scopes: read:packages, write:packages
```

### 2. Fix Remaining 2 Charts

**emberburn:**
1. Go to https://github.com/orgs/fireball-industries/packages?repo_name=Helm-Charts
2. Find emberburn package
3. Package settings → Manage Actions access
4. Grant write permission to fireball-industries account

**ignition-edge:**
1. Edit `C:\HelmCharts\charts\ignition-edge-pod\Chart.yaml`
2. Fix YAML syntax error on line 43
3. Re-package and push:
   ```powershell
   helm create temp-ignition
   Copy-Item ignition-edge-pod\* temp-ignition\ -Recurse -Force
   helm package temp-ignition
   helm push ignition-edge-1.0.0.tgz oci://ghcr.io/fireball-industries
   ```

### 3. Verify All Charts in Rancher
Once OCI repository is added to Rancher:
- Navigate to Apps → Charts
- Filter by "Fireball Industries Podstore" repository
- Verify all 20 charts appear in catalog
- Test deploy one chart (recommend prometheus-pod as test)

## 🎯 Success Metrics

- **Deployment Success Rate:** 90% (18/20)
- **Critical Charts Deployed:** ✅ All monitoring, database, and infrastructure charts
- **Blocking Issues:** 2 (both have clear resolution paths)
- **Time to Full Deployment:** <2 hours estimated after fixes

## 📝 Files Created/Modified

- `C:\HelmCharts\push-to-oci-fixed.ps1` - Updated to handle name mismatches and success detection
- `C:\HelmCharts\dist\*.tgz` - 18 packaged charts ready for deployment
- `C:\HelmCharts\charts\temp-*` - Temporary fix directories for problematic charts

## 🔗 Resources

- **GitHub Container Registry:** https://github.com/orgs/fireball-industries/packages
- **Rancher Dashboard:** https://rancher.embernet.ai/
- **OCI Registry Documentation:** https://helm.sh/docs/topics/registries/
