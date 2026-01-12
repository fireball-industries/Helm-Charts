# Rancher Auto-Deployment Guide

**Automatic Chart Catalog for Multi-Tenant K3s**

## 🎯 Overview

**ADMIN (Fireball Industries):**
- Configure GitHub repository connection **ONCE** at cluster level
- Rancher automatically watches GitHub and syncs new/updated charts
- Provide curated catalog of 20+ Helm charts to all tenants

**TENANTS (Clients):**
- Browse Apps → Charts in Rancher UI
- See all Fireball Industries charts automatically available
- Install/upgrade charts with one click
- **NO GitHub access required. NO repository import needed.**

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
- ✅ All tenants see the same catalog automatically
- ✅ Tenants browse and install via Rancher UI only
- ✅ **NO GitHub import by tenants**

---

## 📋 Setup: Part 1 - Chart Repository (PRIMARY)

This is the primary deployment method. Tenants browse the chart catalog and install what they need.

### Step 1: Navigate to Rancher Repositories
ADMIN SETUP (One-Time Configuration)

**⚠️ ADMIN ONLY - Tenants do NOT perform this setup**

This is done **ONCE** by Fireball Industries admin. After this, all tenants automatically see the chart catalog.

### Step 1: Navigate to Rancher Repositories (Admin Only)
### Step 2: Click "Create"

### Step 3: Configure Git Repository

| Field | Value |
|-------|-------|
| **Name** | `fireball-industries` |
| **Target** | `Git repository containing Helm chart(s)` |
| **Git Repo URL** | `https://github.com/fireball-industries/Helm-Charts` |
| **Git Branch** | `main` |
| **Git Subfolder** | *(leave empty - auto-detects charts/ folder)* |

### Step 4: Authentication

**If Repository is PUBLIC:**
- Leave authentication fields blank

**If Repository is PRIVATE:**
- **Type:** `HTTP Basic Auth`
- **Username:** Your GitHub username (or `x-access-token`)
- **Password:** GitHub Personal Access Token (PAT)
  - Create at: https://github.com/settings/tokens
  - Required scope: `repo` (full repository access)

### Step 5: Advanced Settings (Optional)

```yaml
# Polling interval (how often Rancher checks for updates)
Poll Interval: 15m  # Default: 6h (recommend 5-15m for active development)

# Skip TLS verification (only if using self-signed certs)
Skip TLS Verification: false
```

### Step 6: Click "Create"

Rancher will:
1. Clone the repository
2. Scan `charts/` directory **for ALL tenants**

**Initial indexing takes 1-2 minutes.**

---

## ✅ TOPTIONAL: Fleet for Forced Deployment

**⚠️ ADMIN ONLY - Use this to FORCE deploy services to tenant namespaces**

The catalog method above lets tenants choose what to install. Fleet is for when YOU want to force-deploy services to all tenants automatically

### Step 1: Browse Catalog
```
Rancher UI → ☰ Menu → Apps → Charts
```

### Step 2: See Fireball Industries Charts
All charts are automa vs Catalog?

**Use Catalog (Recommended):**
- ✅ Tenants browse and choose what to install
- ✅ Tenants control their own upgrades
- ✅ Self-service model
- ✅ **This is your primary deployment method**

**Use Fleet (Optional):**
- Force-deploy monitoring to all tenants (Prometheus, Grafana)
- Deploy baseline infrastructure automatically
- Auto-update services across all tenants
- **Use sparingly - tenants lose control**
### Step 3: Install Charts
```
Click chart → Install
Choose namespace
Configure values (or use defaults)
Click Install
```

### Step 4: Manage Deployments
```
Apps → Installed Apps
See all deployed services
Click "Upgrade" when updates available
```

**That's it. Tenants never see GitHubarketplace

**Initial indexing takes 1-2 minutes.**

---

## 🌊 Setup: Part 2 - Fleet for Auto-Deployment (OPTIONAL)

**Optional:** Use Fleet if you want to auto-deploy baseline services to all tenants, or for internal infrastructure.

Fleet provides GitOps continuous deployment:
- Monitors your Git repository
- Auto-deploys specified services to target namespaces
- Auto-upgrades when you push changes
- Useful for baseline services (monitoring, logging)

### When to Use Fleet?

**Use Fleet for:**
- Baseline services all tenants need (Prometheus, Grafana, Loki)
- Internal infrastructure (monitoring, logging, security)
- Services you want to auto-update centrally

**Use Chart Repository for:**
- Optional services tenants choose (CODESYS, Ignition, Home Assistant)
- Services with tenant-specific configuration
- Services tenants manage upgrade schedules for

### Prerequisites:

Fleet is pre-installed with Rancher. If not enabled:
```bash
# Enable Fleet in Rancher
kubectl apply -f https://github.com/rancher/fleet/releases/latest/download/fleet.yaml
```

### Step 1: Create Fleet Configuration

**Create `fleet.yaml` in your repository root:**

```bash
# In your Helm-Charts repository
touch fleet.yaml
```

**fleet.yaml content (Managed Service Model):**

```yaml
# Fleet GitOps Configuration for Fireball Industries Multi-Tenant Platform
# This auto-deploys services to all tenant namespaces

# Default namespace (fallback if not overridden)
defaultNamespace: default

# Target ALL clusters in Rancher
targets:
  - clusterSelector: {}

# Helm configuration for each service
helm:
  # Use charts from this repo
  repo: .
  
  # Global values applied to all charts
  valuesFiles:
    - fleet-values.yaml  # Optional: shared config across tenants

# Define which charts to auto-deploy
bundles:
  # Infrastructure Services (shared across tenants)
  - name: monitoring-stack
    charts:
      - name: prometheus
        path: charts/prometheus-pod
        namespace: monitoring
      - name: grafana
        path: charts/grafana-loki
        namespace: monitoring
      - name: alertmanager
        path: charts/alert-manager
        namespace: monitoring
    targets:
      - clusterSelector:
          matchLabels:
            env: production

  # Per-Tenant Services (deployed to each tenant namespace)
  - name: tenant-services
    charts:
      - name: codesys-runtime
        path: charts/codesys-runtime
      - name: ignition-edge
        path: charts/ignition-edge-pod
      - name: mosquitto-mqtt
        path: charts/mosquitto-mqtt-pod
      - name: node-red
        path: charts/node-red
      - name: emberburn
        path: charts/emberburn
    # Deploy to multiple namespaces (one per tenant)
    targets:
      - name: tenant-a
        namespace: tenant-a
        clusterName: local
      - name: tenant-b
        namespace: tenant-b
        clusterName: local
      - name: tenant-c
        namespace: tenant-c
        clusterName: local
```

**Simpler version (All charts to all namespaces):**

```yaml
# fleet.yaml
defaultNamespace: default

# Deploy to all clusters
targets:
  - clusterSelector: {}

# List each chart individually (Rancher UI will show each as separate app)
helm:
  chart: charts/prometheus-pod
  releaseName: prometheus
  namespace: monitoring
---
helm:
  chart: charts/grafana-loki
  releaseName: grafana
  namespace: monitoring
---
helm:
  chart: charts/codesys-runtime
  releaseName: codesys
  # Namespace determined by target
---
# ... repeat for each chart
```

### Step 2: Optional - Create Per-Tenant Value Overrides

**Create `fleet-values.yaml` for shared config:**

```yaml
# fleet-values.yaml
# Shared values across all tenant deployments

# Global image pull policy
image:
  pullPolicy: IfNotPresent

# MetalLB annotations (per site)
service:
  annotations:
    metallb.universe.tf/address-pool: industrial

# Resource limits (prevent tenant resource exhaustion)
resources:
  limits:
    cpu: "2"
    memory: 4Gi
  requests:
    cpu: "500m"
    memory: 1Gi
```

**Create per-tenant overrides (optional):**

```yaml
# tenant-a-values.yaml
# Specific overrides for Tenant A

codesys-runtime:
  service:
    annotations:
      metallb.universe.tf/loadBalancerIP: 172.17.1.110

emberburn:
  config:
    mqtt:
      broker: mosquitto-mqtt.tenant-a.svc.cluster.local
```

### Step 3: Add Fleet Git Repository

**Navigate to Fleet:**
```
Rancher UI → ☰ Menu → Continuous Delivery → Git Repos
```

**Click "Create"**

**Configure:**

| Field | Value |
|-------|-------|
| **Name** | `fireball-helm-charts` |
| **Repository URL** | `https://github.com/fireball-industries/Helm-Charts` |
| **Branch** | `main` |
| **Paths** | *(leave empty - uses root fleet.yaml)* |
| **Polling Interval** | `15s` (default) |

**Authentication (if private repo):**
- **Type:** HTTP Basic Auth
- **Username:** GitHub username
- **Password:** GitHub PAT (token with `repo` scope)

**Click "Create"**

### Step 4: Verify Fleet Deployment

**Check Git Repo Status:**
```
Continuous Delivery → Git Repos → fireball-helm-charts
Status: ✅ Active
Resources: [shows deployed apps]
```

**Check Deployed Bundles:**
```
Continuous Delivery → Advanced → Bundles
```

You should see bundles for each chart/tenant combination being deployed.

**Check Deployed Workloads:**
```
☰ Menu → Cluster → Workloads
Filter by namespace: tenant-a, tenant-b, etc.
```

You should see pods running for each service you defined in fleet.yaml.

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

### Add New Tenant

**1. Create namespace:**
```bash
kubectl create namespace tenant-d
```

**2. Update fleet.yaml:**
```yaml
# Add to targets list
targets:
  - name: tenant-d
    namespace: tenant-d
    clusterName: local
```

**3. Commit and push:**
```bash
git add fleet.yaml
git commit -m "Add tenant-d"
git push
```

**4. Fleet auto-deploys (15 seconds):**
- All services deploy to `tenant-d` namespace
- Tenant D gets same service stack as other tenants

---

### Add New Service to All Tenants

**1. Create new chart:**
```bash
cd charts/
helm create timescaledb-pod
# Configure chart...
```

**2. Add to fleet.yaml:**
```yaml
bundles:
  - name: tenant-services
    charts:
      - name: timescaledb
        path: charts/timescaledb-pod
```

**3. Commit and push:**
```bash
git add charts/timescaledb-pod/ fleet.yaml
git commit -m "Add TimescaleDB service"
git push
```

**4. Fleet auto-deploys to all tenants (15 seconds):**
- TimescaleDB deploys to tenant-a, tenant-b, tenant-c
- All tenants get new service automatically

---

### Rollback a Bad Deployment

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

## 🛡️ Safety Features

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
    namespace: tenant-*
    clusterName: local
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

## 📊 Monitoring Fleet Deployments

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

### Slack/Email Notifications:

**Configure Rancher Notifiers:**
```
☰ Menu → Notifiers → Create
TypeADMIN (You) - One-Time Setup:
1. ✅ Configure GitHub repo in Rancher (one time)
2. ✅ Set polling interval (5-15 minutes recommended)
3. ✅ Push charts to GitHub
4. ✅ Rancher automatically syncs catalog

### TENANTS (Clients) - Zero Setup:
1. ✅ Log into Rancher
2. ✅ Browse Apps → Charts
3. ✅ See all Fireball Industries charts automatically
4. ✅ Install what they need with one click
5. ✅ **NO GitHub import. NO repo configuration.**

### What is Automatic:
- ✅ New charts appear in catalog (5-15 min after you push to GitHub)
- ✅ Chart updates appear in catalog (5-15 min after you push)
- ✅ All tenants see the same catalog automatically
- ✅ Tenants see "Upgrade Available" when you release updates

### What Tenants Control:
- ✅ Which charts to install
- ✅ When to upgrade
- ✅ Configuration values
- ✅ Their own namespace

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
---

## 🔄 Workflow Examples

### When You Add a New Chart

**Adminpdates auto-upgrade all tenants (15 sec after push)
- ✅ Container image updates auto-restart pods (15 sec after push)
- ✅ ConfigMap changes auto-restart pods (15 sec after push)
- ✅ Rolling updates (zero downtime)
- ✅ All tenants stay in sync automatically

### What is NOT Automatic:
- ❌ Adding new tenants (must update fleet.yaml manually)
- ❌ Changing per-tenant overrides (manual fleet.yaml edit)
- ❌ Emergency rollbacks (manual git revert or Fleet UI)

### For Your Managed Service Model:
- ✅ Use Fleet (GitOps) for ALL deployments
- ✅ Push to Git → services auto-update everywhere
- ✅ No manual helm commands needed (except emergencies)
- ✅ Tenants never touch Rancher/Helm/kubectl

### Check Repository Status:

```
Apps → Repositories → fireball-industries
```

**Tenant sees:**
- New chart appears in Apps → Charts automatically
- No action needed on tenant side

---

### When You Update an Existing Chart

**Admin
### View Available Charts:

```
Apps → Charts → Search: "fireball"
```

**Should see all charts grouped by category:**
- **Forge Industrial:** CODESYS Runtime ARM, CODESYS AMD64-X86, CODESYS Edge Gateway, Ignition Edge, EmberBurn
- **Databases:** PostgreSQL, TimescaleDB, InfluxDB
- **Monitoring:** Prometheus, Grafana, Loki, Alertmanager, Node Exporter
- **IoT:** Mosquitto MQTT, Node-RED, Home Assistant, Telegraf

- ✅ Tenants never touch Rancher/Helm/kubectl

---

## 🔧 Troubleshooting

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

**Tenants with v1.0.0 deployed see:**
- "Upgrade Available" badge in their Installed Apps
- Click Upgrade → Review → Confirm
- Their pods upgrade to v1.1.0

---

### When You Update a Container Image

**Admindetects emberburn chart version changed (1.0.0 → 1.1.0)
4. Rancher indexes new version
5. Both versions now available in catalog:
   - emberburn 1.0.0 (old)
   - emberburn 1.1.0 (new - default for new installs)
6. Users with 1.0.0 deployed see "Upgrade Available" badge
```

**Timeline:** 5-15 minutes from push to new version available

---

### Scenario 3: You UPDATE a Container Image

**Developer Action:**
```bash
# Update image tag in values.yaml
# charts/emberburn/values.yaml
tag: "1.2.3" → "1.2.4"

**Tenants see:**
- "Upgrade Available" badge
- They choose when to upgrade

---

## ⚠️ IMPORTANT: Catalog vs Auto-Deployment

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

**For multi-tenant model: Use Catalog (let tenants choose).**ia Rancher UI:**
```
Apps → Installed Apps → emberburn-deployment
See: "🔄 Upgrade Available" badge
Click: "Upgrade"
Review changes
Click: "Upgrade"
```

**Via Helm CLI:**
```bash
helm upgrade emberburn ./charts/emberburn \
  --namespace emberburn \
  --reuse-values
```

**V🏭 Multi-Tenant Behavior

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

**You (admin) can't force upgrades. Tenants control their deployments.**

---

## 🚀 Admin Tools

### Force Immediate Catalog Sync

**Don't want to wait 5-15 minutes for polling?**

```
Apps → Repositories → fireball-industries → ⋮ → Refresh
```

Rancher re-scans GitHub immediately (~30 seconds).

**Each tenant upgrades independently:**
- Tenant A stays on v1.0.0 (doesn't upgrade)
- Tenant B upgrades to v1.2.0 (clicks Upgrade button)
- Tenant C deploys for first time (gets latest v1.2.0)

**No automatic upgrades. Each tenant controls their own deployments.**

---

## 📊 Chart Versioning Best Practices

### Semantic Versioning in Chart.yaml:

```yaml
apiVersion: v2
name: emberburn

### Problem: Tenants Can't See Charts
   - Check PAT hasn't expired
   - Verify `repo` scope granted

3. **Branch mismatch**
   - Verify Fleet is watching correct branch (`main`)

**Force Re-Sync:**
```
Git Repos → fireball-helm-charts → ⋮ → Force Update
```

---

### Problem: Deployment Stuck in "Modified" State

**Cause:** Manual changes made to resources (kubectl edit)

**Check Repository Status:**
```
Apps → Repositories → fireball-industries
Last Synced: [should be recent timestamp]
Status: Active / ⚠️ Failed
```

**Common Causes:**

1. **Polling hasn't happened yet**
   - Solution: Wait 15 minutes or manual refresh

2. **Invalid Chart.yaml syntax**
   ```bash
   # Validate locally before pushing
   helm lint charts/my-chart/
   ```
Admin: Check Repository Status:**
```
Apps → Repositories → fireball-industries
```

**Should show:**
- Status: ✅ Active
- Last Synced: (recent timestamp)

**Common Causes:**

1. **Repository not configured**
   - Admin needs to add GitHub repo (see ADMIN SETUP section)

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
   - Admin:te new repository (same settings)
```

---

##Admin: Force Cache Refresh:**
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

**This is EXPECTED BEHAVIOR.**

Charts in the catalog do NOT auto-upgrade running pods.

**Tenant must:**
1. Go to Apps → Installed Apps
2. Look for "🔄 Upgrade Available" badge
3. Click the app → Upgrade → Review → Confirm

**Tenants control when they upgrade (not automatic)
Fleet detects change (polling)
    ↓
Fleet auto-upgrades all deployments matching fleet.yaml rules
    ↓
Pods restart with new version (automatic)
```

### Quick Fleet Setup:

**1. Create fleet.yaml in repo root:**
``# Problem: Tenant Asking How to Import Charts

**They don't need to!**

**Tell them:**
```
1. Log into Rancher
2. Click Apps → Charts
3. All Fireball Industries charts are already there
4. Click the chart you want → Install
```

**If they still don't see charts:**
- Admin needs to configure the GitHub repo (see ADMIN SETUP)
- Charts will appear automatically for all tenants once configured

## 🔥 Quick Reference Commands

### Check Repository Status:
```bash
# Via Rancher API
kubectl get gitrepos -n fleet-default

# Or check Rancher UI
Apps → Repositories → fireball-industries
```

### Force Immediate Chart Refresh:
```
Apps → Repositories → fireball-industries → ⋮ → Refresh
```

### View All Available Charts:
```bash
helm search repo fireball-industries
```

### Install Chart via CLI:
```bash
helm install my-app fireball-industries/emberburn \
  --namespace my-namespace \
  --create-namespace
```

### Upgrade Deployed App:
```bash
helm upgrade my-app fireball-industries/emberburn \
  --namespace my-namespace \
  --reuse-values
```

---

**Fireball Industries - We Play With Fire So You Don't Have To™** 🔥
🔥 Quick Reference

### Admin Commands

**Check catalog sync status:**
```
Apps → Repositories → fireball-industries
Status: ✅ Active
Last Synced: [timestamp]
```

**Force immediate sync:**
```
Apps → Repositories → fireball-industries → ⋮ → Refresh
```

**Validate chart before pushing:**
```bash
helm lint charts/my-chart/
```

**View charts via CLI:**
```bash
helm search repo fireball-industries
```

---

### Tenant Instructions

**Browse available charts:**
```
Rancher UI → Apps → Charts
```

**Install a chart:**
```
1. Click chart name
2. Click Install
3. Choose namespace
4. Configure values
5. Click Install
```

**Upgrade installed chart:**
```
1. Apps → Installed Apps
2. Find app with "Upgrade Available" badge
3. Click app → Upgrade
4. Review changes
5. Click Upgrade
```

**NO GitHub commands. NO repository imports. Everything in Rancher UI.**