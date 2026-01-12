# Rancher Auto-Deployment Guide

**Automatic Chart Detection & Self-Service Deployment for Multi-Tenant K3s**

**Deployment Model:** Self-Service Multi-Tenant Platform
- **Fireball Industries provides** a catalog of 20+ Helm charts
- **Tenants have access** to browse and install charts
- **Tenants choose** which services they want to deploy
- **Self-service model** - tenants manage their own deployments

---

## 🎯 What This Does

**When you push changes to this GitHub repository:**
- ✅ Rancher auto-detects new charts (5-15 minutes)
- ✅ Rancher auto-detects chart updates (5-15 minutes)
- ✅ Tenants see "Upgrade Available" for their deployed services
- ✅ Tenants choose when to upgrade (self-service)

**This provides a self-service catalog where tenants control their deployments.**

---

## 🏗️ Architecture Overview

### Your Self-Service Platform Model:

```
Fireball Industries (Platform Provider)
    ↓
Provides 20+ Chart Catalog
    ↓
┌─────────────────────────────────────┐
│ Tenant A          Tenant B          │
│ CHOOSES:          CHOOSES:          │
│ - Grafana         - Ignition        │
│ - CODESYS         - Node-RED        │
│ - MQTT            - PostgreSQL      │
│ (namespace A)     (namespace B)     │
└─────────────────────────────────────┘
```

**Key Points:**
- ✅ You provide the chart catalog (20+ services available)
- ✅ Tenants have Rancher access to install charts
- ✅ Tenants choose which services they want
- ✅ Tenants manage their own upgrades
- ✅ Each tenant has isolated namespace

### Deployment Flow:

```
You push chart update to GitHub
    ↓
Rancher detects change (5-15 minutes polling)
    ↓
Charts show "Upgrade Available" in tenant UI
    ↓
Tenants click "Upgrade" when ready
    ↓
Tenant services restart with new version (self-service)
```

**Tenants control when and what they upgrade.**

---

## 📋 Setup: Part 1 - Chart Repository (PRIMARY)

This is the primary deployment method. Tenants browse the chart catalog and install what they need.

### Step 1: Navigate to Rancher Repositories

```
Rancher UI → ☰ Menu → Apps → Repositories
```

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
2. Scan `charts/` directory
3. Index all Chart.yaml files
4. Make charts available in Apps & Marketplace

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
Type: Slack
Webhook URL: https://hooks.slack.com/...

Alerts:
- Fleet deployment failed
- Fleet deployment succeeded
- Drift detected (manual changes vs Git)
```

---

## ⚠️ CRITICAL: Running Pods Auto-Upgrade

**Unlike basic Helm charts, Fleet DOES auto-upgrade running pods:**

### What Auto-Upgrades:
- ✅ **Chart version changes** (Chart.yaml version bump)
- ✅ **Image tag changes** (values.yaml image.tag update)
- ✅ **Template changes** (deployment.yaml, service.yaml, etc.)
- ✅ **Values changes** (values.yaml configuration updates)
- ✅ **ConfigMap/Secret changes** (auto-triggers pod restart)

### What Triggers Pod Restart:
- ✅ Helm upgrade (Fleet runs `helm upgrade`)
- ✅ ConfigMap change (annotations force restart)
- ✅ Image pull (imagePullPolicy: Always)

### Rolling Update Behavior:
```yaml
# Fleet ensures zero-downtime upgrades
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0  # Keep old pods running
      maxSurge: 1        # Start new pod first
```

**Old pods stay running until new pods are healthy.**

---

## 🎯 Summary

### What IS Automatic (With Fleet):
- ✅ New charts auto-deploy to all tenants (15 sec after push)
- ✅ Chart updates auto-upgrade all tenants (15 sec after push)
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

**Should show:**
- Status: ✅ **Active**
- Chart Count: **21** (or current number of charts)
- Last Synced: *(timestamp within last 15 minutes)*

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

**What Happens Automatically:**
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

**Timeline:** 5-15 minutes from push to new version available

---

### Scenario 3: You UPDATE a Container Image

**Developer Action:**
```bash
# Update image tag in values.yaml
# charts/emberburn/values.yaml
tag: "1.2.3" → "1.2.4"

# Optionally bump chart version too
# Chart.yaml: version: 1.1.0 → 1.1.1

git add charts/emberburn/
git commit -m "EmberBurn: Update to v1.2.4 (security patches)"
git push origin main
```

**What Happens Automatically:**
```
1. GitHub receives push (immediate)
2. Rancher polls repository (5-15 minutes later)
3. Rancher detects chart change
4. New chart version (1.1.1) appears in catalog
5. Users see "Upgrade Available" badge
```

**Timeline:** 5-15 minutes from push to chart update available

---

## ⚠️ CRITICAL: Running Pods Do NOT Auto-Upgrade

**When you push chart updates, Rancher makes the NEW VERSION available, but:**

### Already-Deployed Pods:
- ❌ **Do NOT automatically upgrade**
- ❌ **Do NOT pull new images automatically**
- ❌ **Keep running old version**
- ✅ **Show "Upgrade Available" badge in Rancher UI**

### Users MUST Manually Upgrade:

**Via Rancher UI:**
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

**Via kubectl (force pod restart with same config):**
```bash
kubectl rollout restart deployment/emberburn -n emberburn
```

---

## 🚀 Force Immediate Chart Detection

**Don't want to wait 5-15 minutes?**

### Manual Refresh:

```
Apps → Repositories → fireball-industries
⋮ Menu → Refresh
```

Rancher re-scans repository immediately (takes ~30 seconds).

---

## 🏭 Multi-Tenant Behavior

### Chart Visibility:

**All charts visible to all projects/namespaces:**
- ✅ Tenant A can see all charts
- ✅ Tenant B can see all charts
- ✅ Tenant C can see all charts

### Deployment Isolation:

**Each tenant deploys independently:**
- ✅ Tenant A deploys EmberBurn v1.0.0 to namespace `tenant-a`
- ✅ Tenant B deploys EmberBurn v1.1.0 to namespace `tenant-b`
- ✅ Tenant C doesn't deploy EmberBurn at all
- ❌ Tenants can't see each other's deployments

### Upgrade Control:

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
version: 1.2.3  # Chart version (increment when chart changes)
appVersion: "4.5.6"  # App version (matches container image version)
```

**Version Increment Rules:**

| Change Type | Chart Version | Example |
|-------------|---------------|---------|
| **Breaking change** (removed values, API changes) | Major: 1.0.0 → 2.0.0 | New values.yaml structure |
| **New feature** (added values, new templates) | Minor: 1.2.0 → 1.3.0 | Add MQTT TLS support |
| **Bug fix** (template fix, doc update) | Patch: 1.2.3 → 1.2.4 | Fix typo in deployment.yaml |
| **Image update only** (no chart changes) | Patch: 1.2.3 → 1.2.4 | Update image tag |

---

## 🔧 Troubleshooting Fleet Deployments

### Problem: Fleet Not Deploying After Push

**Check Git Repo Status:**
```
Continuous Delivery → Git Repos → fireball-helm-charts
Status: Active / ⚠️ Failed
Last Synced: [timestamp]
```

**Common Causes:**

1. **fleet.yaml syntax error**
   ```bash
   # Validate YAML locally
   yamllint fleet.yaml
   ```

2. **Git authentication failed**
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

3. **Wrong directory structure**
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

4. **Git authentication failed (private repos)**
   - Check PAT hasn't expired
   - Verify `repo` scope granted

---

### Problem: Chart Shows Old Version

**Rancher caches chart metadata.**

**Force Cache Refresh:**
```
Apps → Repositories → fireball-industries
⋮ Menu → Refresh
```

**Or delete and re-add repository:**
```
⋮ Menu → Delete
Create new repository (same settings)
```

---

### Problem: Deployed Pod Not Updating

**This is EXPECTED BEHAVIOR.**

Rancher does NOT auto-upgrade running pods. You must:

1. **Check for updates:**
   ```
   Apps → Installed Apps → [your-app]
   Look for "🔄 Upgrade Available" badge
   ```

2. **Manually upgrade:**
   ```
   Click app → Upgrade → Review changes → Upgrade
   ```

**For auto-upgrades, use Rancher Fleet (GitOps) - see next section.**

---

## 🌊 GitOps Auto-Upgrades (Optional)

**Want deployed pods to auto-upgrade when you push changes?**

Use **Rancher Fleet** for continuous deployment.

### How Fleet Works:

```
Push chart update to Git
    ↓
Fleet detects change (polling)
    ↓
Fleet auto-upgrades all deployments matching fleet.yaml rules
    ↓
Pods restart with new version (automatic)
```

### Quick Fleet Setup:

**1. Create fleet.yaml in repo root:**
```yaml
# fleet.yaml
defaultNamespace: default

# Auto-deploy to all clusters
targets:
  - clusterSelector: {}

# Helm configuration
helm:
  chart: charts/emberburn
  releaseName: emberburn
  values:
    # Override values here
    image:
      tag: latest  # or pin to version
```

**2. Add Fleet Repository in Rancher:**
```
Continuous Delivery → Git Repos → Add Repository
Git Repo URL: https://github.com/fireball-industries/Helm-Charts
Branch: main
Path: /  # Root contains fleet.yaml
```

**3. Fleet Auto-Deploys:**
- Polls Git every 15 seconds (configurable)
- Detects chart changes
- Automatically runs `helm upgrade` on all matching clusters
- Pods restart with new version

**⚠️ Use with caution in multi-tenant environments:**
- Fleet auto-upgrades ALL matching deployments
- No per-tenant control
- Good for: internal services, monitoring, infrastructure
- Bad for: tenant-controlled apps, production workloads

---

## 📈 Recommended Workflow

### For Infrastructure/Platform Charts (Prometheus, Grafana, etc.):
1. ✅ Use Rancher Git Repository (chart catalog)
2. ✅ Use Fleet for auto-deployment
3. ✅ Push updates → auto-deploys everywhere

### For Tenant-Controlled Charts (CODESYS, Ignition, EmberBurn):
1. ✅ Use Rancher Git Repository (chart catalog)
2. ❌ Do NOT use Fleet (tenants control upgrades)
3. ✅ Push updates → tenants see "Upgrade Available" → tenants choose when to upgrade

---

## 🎯 Summary

### What IS Automatic:
- ✅ New charts appear in catalog (5-15 min after push)
- ✅ Chart updates appear in catalog (5-15 min after push)
- ✅ All tenants see new/updated charts
- ✅ Rancher indexes metadata automatically

### What is NOT Automatic:
- ❌ Running pods do NOT auto-upgrade
- ❌ Container image updates require manual helm upgrade
- ❌ Users must click "Upgrade" button in Rancher UI

### To Make Pod Upgrades Automatic:
- Use **Rancher Fleet** (GitOps)
- Only recommended for infrastructure, not tenant workloads

---

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
