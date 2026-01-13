# Rancher Charts Detailed Guide

**Complete Reference for Multi-Tenant Helm Chart Deployment**

---

## 🎯 Overview

**ADMIN (Fireball Industries):**
- Configure GitHub repository connection **ONCE** at cluster level
- Rancher automatically watches GitHub and syncs new/updated charts
- Provide curated catalog of 20+ Helm charts to all tenants
- **Compatible with automatic tenant watcher** - new tenants automatically see catalog

**TENANTS (Clients):**
- Browse Apps → Charts in Rancher UI
- See all Fireball Industries charts automatically available
- Install/upgrade charts with one click
- **NO GitHub access required. NO repository import needed.**
- **NO namespace creation needed** - auto-imported tenants work immediately

---

## 🚀 How It Works

**When you (admin) push changes to GitHub:**
1. ✅ Rancher automatically detects new charts (5-15 minutes)
2. ✅ Rancher automatically detects chart updates (5-15 minutes)
3. ✅ Charts appear in tenant catalog immediately
4. ✅ Tenants see "Upgrade Available" for deployed services
5. ✅ Tenants click "Upgrade" when ready

**Tenants never interact with GitHub. Everything is in Rancher UI.**

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│ ADMIN (Fireball Industries)                     │
│                                                  │
│ GitHub Repo ──→ Rancher Catalog (configured once)│
│  charts/           ↓                             │
│   ├─ emberburn    Auto-sync every 15 min        │
│   ├─ codesys                                     │
│   └─ ignition                                    │
└─────────────────────────────────────────────────┘
                      ↓
          ┌──────────────────────┐
          │  Rancher Catalog     │
          │  (Apps → Charts)     │
          └──────────────────────┘
                      ↓
    ┌─────────────────────────────────────┐
    │ TENANTS (Browse & Install)          │
    │                                     │
    │ Tenant A          Tenant B          │
    │ INSTALLS:         INSTALLS:         │
    │ - Grafana         - Ignition        │
    │ - CODESYS         - Node-RED        │
    │ - MQTT            - PostgreSQL      │
    │ (namespace A)     (namespace B)     │
    └─────────────────────────────────────┘
```

**Key Points:**
- ✅ Admin configures GitHub repo connection **ONE TIME**
- ✅ Rancher automatically syncs charts from GitHub
- ✅ All tenants see the same catalog automatically (existing AND auto-imported)
- ✅ Tenants browse and install via Rancher UI only
- ✅ **NO GitHub import by tenants**
- ✅ **Compatible with automatic tenant watcher** - no manual namespace creation needed

---

## 🚀 How Auto-Deployment Works

### Scenario: You Update EmberBurn Chart

**Your Action:**
```bash
cd charts/emberburn/

# Update chart
vim Chart.yaml  # version: 1.0.0 → 1.1.0
vim values.yaml  # tag: "1.2.3" → "1.2.4"

git add charts/emberburn/
git commit -m "EmberBurn v1.1.0 - Add MQTT TLS support"
git push origin main
```

**What Happens (Automatically):**
```
1. GitHub receives push (immediate)
    ↓
2. Fleet polls repository (15 seconds later)
    ↓
3. Fleet detects emberburn chart changed
    ↓
4. Fleet runs helm upgrade for ALL tenant namespaces:
   - helm upgrade emberburn-tenant-a charts/emberburn -n tenant-a
   - helm upgrade emberburn-tenant-b charts/emberburn -n tenant-b
   - helm upgrade emberburn-tenant-c charts/emberburn -n tenant-c
    ↓
5. Pods restart with new version (rolling update)
    ↓
6. All tenants now running v1.1.0 (automatic)
```

**Timeline:** 15-30 seconds from push to deployment complete

**Zero manual intervention. Zero tenant disruption (rolling updates).**

---

## 🔄 Common Workflows

### Scenario 1: You Add a NEW Chart

**Developer Action:**
```bash
cd charts/
helm create my-new-service

# Edit Chart.yaml, values.yaml, templates/
# Add Rancher annotations to Chart.yaml

git add charts/my-new-service/
git commit -m "Add my-new-service chart"
git push origin main
```

**What Happens Automatically:**
```
1. GitHub receives push (immediate)
2. Rancher polls repository (5-15 minutes later)
3. Rancher detects new chart in charts/my-new-service/
4. Rancher indexes chart metadata
5. Chart appears in Apps & Marketplace (automatic)
6. All tenants can now install it (no admin action needed)
```

**Timeline:** 5-15 minutes from push to chart availability

---

### Scenario 2: You UPDATE an Existing Chart

**Developer Action:**
```bash
# Update chart version in Chart.yaml
# charts/emberburn/Chart.yaml
version: 1.0.0 → 1.1.0

# Make changes to templates, values, etc.

git add charts/emberburn/
git commit -m "EmberBurn v1.1.0 - Add MQTT TLS support"
git push origin main
```

**What Happens:**
```
1. GitHub receives push (immediate)
2. Rancher polls repository (5-15 minutes later)
3. Rancher detects emberburn chart version changed (1.0.0 → 1.1.0)
4. Rancher indexes new version
5. Both versions now available in catalog:
   - emberburn 1.0.0 (old)
   - emberburn 1.1.0 (new - default for new installs)
6. Users with 1.0.0 deployed see "Upgrade Available" badge
```

**Tenants with v1.0.0 deployed see:**
- "Upgrade Available" badge in their Installed Apps
- Click Upgrade → Review → Confirm
- Their pods upgrade to v1.1.0

**Timeline:** 5-15 minutes from push to new version available

---

### Scenario 3: You UPDATE a Container Image

**Developer Action:**
```bash
# Update image tag in values.yaml
# charts/emberburn/values.yaml
tag: "1.2.3" → "1.2.4"

# Also bump chart version
# Chart.yaml
version: 1.0.1 → 1.0.2

git add charts/emberburn/
git commit -m "Update EmberBurn to v1.2.4"
git push
```

**Tenants see:**
- "Upgrade Available" badge
- They choose when to upgrade

---

### Add New Service to All Tenants (Fleet)

**1. Create new chart:**
```bash
cd charts/
helm create timescaledb-pod
# Configure chart...
```

**2. Add to fleet.yaml:**
```yaml
- name: tenant-baseline-timescale
  helm:
    chart: charts/timescaledb-pod
    releaseName: timescaledb
  targets:
    - clusterSelector: {}
      namespaceSelector:
        matchLabels:
          tenant: "true"
```

**3. Commit and push:**
```bash
git add charts/timescaledb-pod/ fleet.yaml
git commit -m "Add TimescaleDB service"
git push
```

**4. Fleet auto-deploys to all tenants (15 seconds):**
- TimescaleDB deploys to all tenant namespaces with `tenant=true` label
- All tenants get new service automatically

---

## 🏭 Multi-Tenant Behavior

### What Tenants See:

**All tenants see the SAME catalog:**
- ✅ All 20+ Fireball Industries charts visible to everyone
- ✅ No tenant can modify the catalog
- ✅ No tenant needs to import anything

**Example tenant view (Apps → Charts):**
```
Available Charts:
├─ Fireball Industries
│  ├─ CODESYS Runtime (v1.2.3)
│  ├─ Ignition Edge (v2.1.0)
│  ├─ EmberBurn (v1.1.0)
│  ├─ Node-RED (v3.0.2)
│  └─ ... (all 20+ charts)
```

### Deployment Isolation:

**Each tenant deploys to their own namespace:**
- ✅ Tenant A installs EmberBurn v1.0.0 to namespace `tenant-a`
- ✅ Tenant B installs EmberBurn v1.1.0 to namespace `tenant-b`
- ✅ Tenant C doesn't install EmberBurn at all
- ❌ Tenants can't see each other's deployments
- ✅ Tenants can only manage their own namespace

### Upgrade Independence:

**Each tenant upgrades on their own schedule:**
- Tenant A: stays on v1.0.0 (waits for testing)
- Tenant B: upgrades to v1.2.0 immediately
- Tenant C: deploys for first time (gets latest v1.2.0)

**You (admin) can't force upgrades via Catalog. Tenants control their deployments.**
**(Unless using Fleet - see Fleet section)**

---

## ⚠️ IMPORTANT: Catalog vs Fleet Auto-Deployment

### Catalog Method (Default - Recommended):
- ✅ Tenants see new charts in catalog automatically
- ✅ Tenants choose what to install
- ✅ Tenants choose when to upgrade
- ❌ Existing pods do NOT auto-upgrade
- ✅ **Tenant has full control**

### Fleet Method (Optional - Admin Controlled):
- ✅ Auto-deploys services to tenant namespaces
- ✅ Auto-upgrades on chart updates
- ❌ Tenants lose control over deployment timing
- ✅ **Admin has full control**

**For multi-tenant model: Use Catalog for optional services, Fleet for baseline/required services.**

---

## 📊 Monitoring

### What is Automatic:
- ✅ New charts appear in catalog (5-15 min after you push to GitHub)
- ✅ Chart updates appear in catalog (5-15 min after you push)
- ✅ All tenants see the same catalog automatically
- ✅ Tenants see "Upgrade Available" when you release updates
- ✅ (Fleet only) Chart updates auto-upgrade all tenants (15 sec after push)
- ✅ (Fleet only) Container image updates auto-restart pods (15 sec after push)
- ✅ (Fleet only) ConfigMap changes auto-restart pods (15 sec after push)

### What Tenants Control (Catalog):
- ✅ Which charts to install
- ✅ When to upgrade
- ✅ Configuration values
- ✅ Their own namespace

### What is NOT Automatic:
- ❌ (Catalog) Tenants must manually click "Upgrade" 
- ❌ Emergency rollbacks (manual git revert or Fleet UI)

### Verify Admin Setup:

**Check Repository Status:**
```
Apps → Repositories → fireball-industries
```

**Should show:**
- Status: ✅ **Active**
- Chart Count: **21** (or current number of charts)
- Last Synced: *(timestamp within last 15 minutes)*

**View Tenant Catalog (what clients see):**
```
Apps → Charts
```

**Should see all charts grouped by category:**
- **Forge Industrial:** CODESYS Runtime ARM, CODESYS AMD64-X86, CODESYS Edge Gateway, Ignition Edge, EmberBurn
- **Databases:** PostgreSQL, TimescaleDB, InfluxDB
- **Monitoring:** Prometheus, Grafana, Loki, Alertmanager, Node Exporter
- **IoT:** Mosquitto MQTT, Node-RED, Home Assistant, Telegraf

---

## 🚀 Admin Tools

### Force Immediate Catalog Sync

**Don't want to wait 5-15 minutes for polling?**

```
Apps → Repositories → fireball-industries → ⋮ → Refresh
```

Rancher re-scans GitHub immediately (~30 seconds).

---

## 📊 Fleet Monitoring

### Fleet Dashboard:

```
Continuous Delivery → Dashboard
```

**Shows:**
- Git repository sync status
- Bundle deployment status (per namespace)
- Resource health (pods, services, deployments)
- Diff previews before apply
- Deployment history

### Per-Namespace Status:

```
Continuous Delivery → Bundles → tenant-services
```

**Shows:**
- tenant-a: ✅ Ready (5/5 apps deployed)
- tenant-b: ⏳ Deploying (3/5 apps ready)
- tenant-c: ❌ Error (MQTT pod CrashLoopBackOff)

**Click for details:**
- Deployment logs
- Resource YAML
- Events
- Errors

---

## 🛡️ Safety Features (Fleet)

### Diff Preview Before Deploy

Fleet shows diffs before applying:
```
Continuous Delivery → Bundles → tenant-services
Click bundle → View Diff
See exactly what will change before it deploys
```

### Staged Rollouts (Per Tenant)

Deploy to canary tenant first:
```yaml
# fleet.yaml
targets:
  - name: tenant-a-canary
    namespace: tenant-a
    clusterName: local
    # Apply first
    
  - name: all-other-tenants
    namespaceSelector:
      matchLabels:
        tenant: "true"
    # Wait for canary success
    dependsOn:
      - tenant-a-canary
```

### Auto-Pause on Errors

```yaml
# fleet.yaml
helm:
  atomic: true  # Rollback on failure
  timeout: 5m
  wait: true    # Wait for resources to be ready
```

If deployment fails, Fleet auto-rolls back to previous version.

---

## 🔧 Troubleshooting

### Problem: Tenants Can't See Charts

**Admin: Check Repository Status:**
```
Apps → Repositories → fireball-industries
```

**Should show:**
- Status: ✅ Active
- Last Synced: (recent timestamp)

**Common Causes:**

1. **Repository not configured**
   - Admin needs to add GitHub repo (see deployment guide)

2. **Polling hasn't happened yet**
   - Wait 15 minutes or click Refresh

3. **Invalid Chart.yaml syntax**
   ```bash
   # Admin: Validate locally before pushing
   helm lint charts/my-chart/
   ```

4. **Wrong directory structure**
   ```
   ✅ Correct:
   charts/
     emberburn/
       Chart.yaml
       values.yaml
       templates/

   ❌ Wrong:
   emberburn/
     Chart.yaml  # Not in charts/ directory
   ```

5. **Git authentication failed (private repos)**
   - Admin: Check GitHub PAT hasn't expired
   - Admin: Verify `repo` scope granted

**Admin: Force Re-Sync:**
```
Apps → Repositories → fireball-industries → ⋮ → Refresh
```

**Admin: Or delete and re-add repository:**
```
⋮ Menu → Delete
Create new repository (same settings)
```

---

### Problem: Charts Appear but Are Empty/Broken

**Admin: Force Cache Refresh:**
```
Apps → Repositories → fireball-industries → ⋮ → Refresh
```

**Admin: Or delete and re-add repository:**
```
⋮ Menu → Delete
Create new repository (same settings)
```

---

### Problem: Tenant Says Update Not Working

**This is EXPECTED BEHAVIOR for Catalog method.**

Charts in the catalog do NOT auto-upgrade running pods.

**Tenant must:**
1. Go to Apps → Installed Apps
2. Look for "🔄 Upgrade Available" badge
3. Click the app → Upgrade → Review → Confirm

**Tenants control when they upgrade (not automatic unless using Fleet).**

---

### Problem: Tenant Asking How to Import Charts

**They don't need to!**

**Tell them:**
```
1. Log into Rancher
2. Click Apps → Charts
3. All Fireball Industries charts are already there
4. Click the chart you want → Install
```

**If they still don't see charts:**
- Admin needs to configure the GitHub repo (see deployment guide)
- Charts will appear automatically for all tenants once configured

---

### Problem: Fleet Deployment Stuck in "Modified" State

**Cause:** Manual changes made to resources (kubectl edit)

**Solution:**
```
Continuous Delivery → Bundles → [bundle-name] → ⋮ → Force Update
```

This resets resources to match Git state.

---

### Problem: Fleet Not Detecting New Tenants

**Verify namespace has label:**
```bash
kubectl get namespace <tenant-namespace> --show-labels
```

**Should show:** `tenant=true`

**If missing, add label:**
```bash
kubectl label namespace <tenant-namespace> tenant=true
```

Fleet will detect within 15 seconds.

---

## 🔄 Rollback Procedures

### Rollback Fleet Deployment

**Option 1: Git Revert (Recommended)**
```bash
# Revert the commit
git revert HEAD
git push

# Fleet auto-rolls back within 15 seconds
```

**Option 2: Manual Fleet Rollback**
```
Continuous Delivery → Bundles → tenant-services
⋮ Menu → Rollback
Select previous version
```

**Option 3: Helm Rollback (Per Namespace)**
```bash
helm rollback emberburn -n tenant-a
helm rollback emberburn -n tenant-b
helm rollback emberburn -n tenant-c
```

---

## 📊 Chart Versioning Best Practices

### Semantic Versioning in Chart.yaml:

```yaml
apiVersion: v2
name: emberburn
version: 1.2.3  # Chart version (increment on every change)
appVersion: "2.1.0"  # Application version

# Version bump guidelines:
# 1.0.0 → 1.0.1  (patch - bug fixes, no breaking changes)
# 1.0.0 → 1.1.0  (minor - new features, backward compatible)
# 1.0.0 → 2.0.0  (major - breaking changes)
```

**Always bump chart version when making ANY changes.**

---

**Fireball Industries - We Play With Fire So You Don't Have To™** 🔥
