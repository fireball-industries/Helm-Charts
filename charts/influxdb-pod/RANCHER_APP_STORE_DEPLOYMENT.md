# Rancher App Store Deployment Guide
## InfluxDB Pod - Multi-Tenant Self-Service Deployment

**Fireball Industries** - *"Ignite Your Factory Efficiency"™*

---

## 📋 Overview

This guide explains how to deploy the InfluxDB Pod Helm chart to your Rancher App Store (Apps & Marketplace), making it available to all clients in your multi-tenant environment. Clients can then self-service deploy InfluxDB instances to their own clusters through the Rancher UI.

---

## 🎯 Multi-Tenant Architecture

Your service provides:
- **Rancher Management**: Centralized cluster management
- **App Store**: Self-service application catalog
- **Fleet**: GitOps-based deployment for troubleshooting
- **Multiple Clients**: Each with their own clusters/namespaces

This InfluxDB Pod chart will appear in the Apps & Marketplace for **all clients**, allowing them to:
1. Browse available industrial applications
2. Select InfluxDB Pod from the catalog
3. Configure deployment through an interactive UI
4. Deploy to their own namespace/cluster
5. Manage their own InfluxDB instances

---

## 📦 Prerequisites

Before deploying to the Rancher App Store, ensure:

- ✅ Rancher Manager 2.7.0 or higher is running
- ✅ You have admin access to Rancher
- ✅ Git repository is accessible by Rancher (for Helm chart source)
- ✅ Clusters have Kubernetes 1.24+ (verified in Chart.yaml)
- ✅ Storage classes are available in target clusters (for PVCs)

---

## 🚀 Deployment Methods

You can deploy this chart to the Rancher App Store using one of these methods:

### Method 1: Git Repository (Recommended)
### Method 2: HTTP/HTTPS Chart Repository
### Method 3: Chart Bundle Upload

---

## 📖 Method 1: Git Repository (Recommended)

This is the **recommended approach** for your multi-tenant environment as it:
- Provides version control
- Enables automatic updates
- Integrates with your existing Fleet deployment
- Allows easy rollback

### Step 1: Push Chart to Git Repository

```powershell
# Navigate to your chart directory
cd C:\Users\Admin\Documents\GitHub\influxdb-pod

# Ensure git repository is initialized and committed
git add .
git commit -m "Prepare InfluxDB Pod for Rancher App Store"
git push origin main
```

### Step 2: Add Repository to Rancher

1. **Login to Rancher** as admin
2. Navigate to **☰ → Apps → Repositories**
3. Click **Create** button
4. Fill in the details:

| Field | Value |
|-------|-------|
| **Name** | `fireball-industries-charts` |
| **Target** | `http(s)` |
| **Index URL** | `https://github.com/fireball-industries/influxdb-pod` |
| **Repository Type** | `Git repository containing Helm chart` |
| **Git Repo URL** | `https://github.com/fireball-industries/influxdb-pod.git` |
| **Git Branch** | `main` (or your default branch) |
| **Chart Folder** | `.` (if chart is in root) or specify subfolder |

5. (Optional) For private repositories:
   - Enable **Authentication**
   - Choose authentication method:
     - **SSH Private Key** (recommended)
     - **Basic Auth** (username/password)
     - **Bearer Token**

6. Click **Create**

### Step 3: Verify Repository

1. Wait for repository to sync (30-60 seconds)
2. Check status shows **Active** with green checkmark
3. Navigate to **☰ → Apps → Charts**
4. Search for "InfluxDB Pod"
5. Verify chart appears with correct version (1.0.0)

---

## 📖 Method 2: HTTP/HTTPS Chart Repository

If you maintain a Helm chart repository:

### Step 1: Package the Chart

```powershell
# Create chart package
helm package C:\Users\Admin\Documents\GitHub\influxdb-pod

# This creates: influxdb-pod-1.0.0.tgz
```

### Step 2: Upload to Chart Repository

```powershell
# Upload to your chart repository
# Example for GitHub Pages:
mv influxdb-pod-1.0.0.tgz /path/to/chart-repo/
cd /path/to/chart-repo/
helm repo index . --url https://yourdomain.com/charts

# Commit and push
git add .
git commit -m "Add InfluxDB Pod 1.0.0"
git push
```

### Step 3: Add Repository to Rancher

1. Navigate to **☰ → Apps → Repositories**
2. Click **Create**
3. Fill in:

| Field | Value |
|-------|-------|
| **Name** | `fireball-industries-charts` |
| **Target** | `http(s)` |
| **Index URL** | `https://yourdomain.com/charts/index.yaml` |

4. Click **Create**

---

## 📖 Method 3: Chart Bundle Upload

For disconnected environments or testing:

### Step 1: Package Chart

```powershell
cd C:\Users\Admin\Documents\GitHub\influxdb-pod
helm package .
```

### Step 2: Upload via Rancher UI

1. Navigate to **☰ → Local → Apps → Charts**
2. Click **Import YAML** or **Upload Chart**
3. Select `influxdb-pod-1.0.0.tgz`
4. Follow upload prompts

⚠️ **Note**: This method requires manual uploads for updates and is **not recommended** for multi-tenant production use.

---

## 🎨 Customizing Catalog Display

The chart is configured for optimal Rancher display. Key files control appearance:

### Chart.yaml
Already configured with:
```yaml
annotations:
  catalog.cattle.io/display-name: "InfluxDB Pod - Industrial Time-Series Database"
  catalog.cattle.io/category: "Database,Monitoring,Industrial"
  catalog.cattle.io/certified: partner
  catalog.cattle.io/vendor: "Fireball Industries"
```

### questions.yaml
Provides the **interactive UI form** for client self-service configuration with:
- Grouped configuration sections
- Input validation
- Conditional fields
- Helpful descriptions
- Sensible defaults

### app-readme.md
Displays in the **chart details page** with:
- Feature overview
- Quick start guides
- Resource requirements
- Post-deployment instructions

---

## 👥 Multi-Tenant Client Access

### Making App Available to All Clients

**The app is automatically available to all clusters** managed by your Rancher instance by default. To control access:

#### Option 1: Global Availability (Default)
No additional configuration needed. All clients with cluster access can deploy.

#### Option 2: Restrict to Specific Projects

1. Navigate to **☰ → Cluster → Projects/Namespaces**
2. Select project
3. Go to **Apps**
4. Only charts added to project scope appear

#### Option 3: RBAC Controls

Use Rancher RBAC to control who can deploy apps:

```yaml
# Example: Restrict to certain roles
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: influxdb-deployers
  namespace: cattle-system
subjects:
- kind: Group
  name: factory-admins
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
```

---

## 🔧 Client Self-Service Deployment

Once deployed to the App Store, clients can deploy InfluxDB through the Rancher UI:

### Step-by-Step Client Experience

1. **Login to Rancher** with their credentials
2. **Select their cluster** from the cluster list
3. Navigate to **Apps → Charts**
4. Search or browse for "InfluxDB Pod"
5. Click on the chart card
6. Review the **app-readme.md** description
7. Click **Install** button
8. Fill out the configuration form (questions.yaml):
   - **Namespace**: Select or create namespace
   - **Name**: Installation name (e.g., "factory-influxdb")
   - **Deployment Mode**: single or ha
   - **Resource Preset**: edge, small, medium, large, xlarge
   - **Organization Name**: Their factory/company name
   - **Storage Settings**: Size and class
   - **Network Settings**: Ingress, service type
   - **Advanced Options**: As needed

9. Click **Install** at bottom of form
10. Monitor deployment in **Apps → Installed Apps**
11. Access InfluxDB once pods are running

### Client View

Clients see:
- ✅ Pre-configured industrial buckets (sensors, SCADA, production, etc.)
- ✅ Auto-generated secure tokens
- ✅ Resource sizing based on sensor count
- ✅ Optional HA clustering
- ✅ Backup automation
- ✅ Monitoring integration

---

## 🔍 Monitoring Deployments

### As Service Provider

Monitor all client deployments:

```powershell
# List all InfluxDB deployments across clusters
kubectl get apps -A | Select-String influxdb

# Check specific deployment health
kubectl get pods -n <client-namespace> -l app=influxdb

# View deployment configuration
kubectl get app influxdb -n <client-namespace> -o yaml
```

### Rancher UI

1. Navigate to **☰ → Continuous Delivery → Apps**
2. View all deployed apps across clusters
3. Filter by chart name: "influxdb-pod"
4. Monitor status, versions, and resources

---

## 🚨 Troubleshooting Guide

### Chart Not Appearing in Catalog

**Symptoms**: Clients can't find InfluxDB Pod in Charts

**Solutions**:
```powershell
# Check repository status
kubectl get catalogtemplates -A | Select-String influxdb

# Force repository refresh
# Via Rancher UI: Apps → Repositories → Refresh

# Check repository sync errors
kubectl get settings catalog-refresh-interval -o yaml
```

### Deployment Failures

**Symptoms**: Client reports deployment fails

**Common Issues**:

1. **Storage Class Not Available**
   ```powershell
   # List available storage classes in client cluster
   kubectl get storageclass
   ```
   Solution: Client needs to select valid storage class or leave default

2. **Resource Quotas Exceeded**
   ```powershell
   # Check namespace quotas
   kubectl get resourcequota -n <client-namespace>
   ```
   Solution: Client needs to adjust resource preset or increase quota

3. **Image Pull Errors**
   ```powershell
   # Check pod events
   kubectl describe pod -n <client-namespace> -l app=influxdb
   ```
   Solution: Ensure clusters can pull from `influxdata/influxdb:2.7-alpine`

### Fleet Integration for Support

When clients have issues, you can deploy via Fleet:

```powershell
# Create Fleet bundle for troubleshooting
cat > fleet.yaml @"
defaultNamespace: influxdb-support
helm:
  chart: influxdb-pod
  repo: https://github.com/fireball-industries/influxdb-pod
  version: 1.0.0
  values:
    deploymentMode: single
    resourcePreset: medium
"@

# Deploy via Fleet for investigation
kubectl apply -f fleet.yaml
```

---

## 🔄 Updating the Chart

When you release new versions:

### Method 1: Git Repository (Automatic)

1. Update chart version in Chart.yaml:
   ```yaml
   version: 1.1.0
   ```

2. Commit and push:
   ```powershell
   git add Chart.yaml
   git commit -m "Release v1.1.0"
   git tag v1.1.0
   git push --tags
   ```

3. Repository syncs automatically (check interval in Rancher settings)

4. Clients see update notification in **Apps → Installed Apps**

### Method 2: Manual Repository Update

1. Package new version
2. Upload to chart repository
3. Refresh Rancher repository
4. Clients can upgrade via UI

---

## 📊 Usage Analytics

Track chart adoption:

```powershell
# Count deployments per cluster
kubectl get apps -A -o json | ConvertFrom-Json | 
  Select-Object -ExpandProperty items | 
  Where-Object { $_.metadata.name -like "*influxdb*" } | 
  Group-Object -Property {$_.metadata.namespace} | 
  Select-Object Count, Name

# View versions deployed
kubectl get apps -A -o json | ConvertFrom-Json |
  Select-Object -ExpandProperty items |
  Where-Object { $_.metadata.name -like "*influxdb*" } |
  Select-Object @{N='Namespace';E={$_.metadata.namespace}}, 
                @{N='Version';E={$_.spec.chart.version}}
```

---

## 🔐 Security Considerations

### For Multi-Tenant Environment

1. **Network Isolation**
   - Ensure Network Policies are enabled per namespace
   - Clients cannot access each other's InfluxDB instances

2. **RBAC Enforcement**
   - Clients can only deploy to their assigned namespaces
   - Rancher RBAC controls app deployment permissions

3. **Secrets Management**
   - Auto-generated tokens are stored in namespace secrets
   - Clients manage their own credentials
   - No cross-namespace secret access

4. **Resource Quotas**
   - Set per-namespace resource quotas
   - Prevents resource exhaustion from oversized deployments

Example quota:
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: influxdb-quota
  namespace: client-namespace
spec:
  hard:
    requests.cpu: "8"
    requests.memory: "16Gi"
    persistentvolumeclaims: "5"
```

---

## 📚 Additional Resources

### Documentation for Clients

Provide clients with:
- Link to app-readme.md (visible in Rancher chart details)
- [Quick Reference](QUICK_REFERENCE.md) for common operations
- Example configurations in `examples/` folder:
  - [minimal-influxdb.yaml](examples/minimal-influxdb.yaml)
  - [ha-influxdb.yaml](examples/ha-influxdb.yaml)
  - [edge-gateway.yaml](examples/edge-gateway.yaml)

### Support Channels

Direct clients to:
- **GitHub Issues**: https://github.com/fireball-industries/influxdb-pod/issues
- **Documentation**: [docs/README.md](docs/README.md)
- **Your Support Portal**: (customize with your support URL)

---

## ✅ Deployment Checklist

Before going live with the app store:

- [ ] Chart is tested in development cluster
- [ ] Git repository is accessible by Rancher
- [ ] Repository is added to Rancher (Apps → Repositories)
- [ ] Chart appears in catalog (Apps → Charts)
- [ ] Test deployment as client user
- [ ] Verify all form fields work correctly
- [ ] Verify HA mode deploys 3+ replicas
- [ ] Verify persistence works with available storage classes
- [ ] Verify ingress configuration (if using)
- [ ] Verify backup CronJob (if enabled)
- [ ] Test upgrade path from 1.0.0 to newer version
- [ ] Documentation is accessible to clients
- [ ] Support process is defined for client issues
- [ ] Resource quotas are configured per client namespace
- [ ] Network policies are tested (if enabled)
- [ ] Monitoring is configured (Prometheus/Grafana)

---

## 🎉 Success!

Your InfluxDB Pod chart is now available in the Rancher App Store for all clients!

**Clients can now**:
- ✅ Self-service deploy InfluxDB to their clusters
- ✅ Choose deployment size based on their sensor count
- ✅ Configure HA clustering for production workloads
- ✅ Enable automated backups
- ✅ Integrate with Grafana and Telegraf
- ✅ Manage their own time-series data platform

**You provide**:
- ✅ Centralized app catalog management
- ✅ Version-controlled Helm charts
- ✅ Fleet-based troubleshooting option
- ✅ Multi-tenant isolation and security
- ✅ Self-service portal reducing support overhead

---

**Fireball Industries** - *"Ignite Your Factory Efficiency"™*

Because your clients' factory data deserves better than an Excel spreadsheet.

---

*For questions or issues, contact: patrick@fireballindustries.com*
