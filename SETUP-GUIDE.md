# Setup and Deployment Guide
# Fireball Industries Podstore Charts Repository

Complete guide for setting up and deploying the Helm charts repository.

## Table of Contents

1. [Repository Setup](#repository-setup)
2. [Publishing to GitHub](#publishing-to-github)
3. [GitHub Pages Configuration](#github-pages-configuration)
4. [Rancher Integration](#rancher-integration)
5. [Deployment Workflows](#deployment-workflows)
6. [Maintenance](#maintenance)

---

## 1. Repository Setup

### Initial Setup

1. **Initialize Git Repository** (if not already done)
   ```powershell
   cd c:\Users\Admin\Documents\GitHub\Helm-Charts
   git init
   git add .
   git commit -m "Initial commit: Fireball Industries Podstore Charts with Alert Manager"
   ```

2. **Verify Repository Structure**
   ```powershell
   Get-ChildItem -Recurse -Depth 2
   ```

   Expected structure:
   ```
   Helm-Charts/
   ├── charts/
   │   └── alert-manager/
   │       ├── Chart.yaml
   │       ├── values.yaml
   │       ├── questions.yaml
   │       ├── app-readme.md
   │       ├── README.md
   │       ├── .helmignore
   │       ├── examples/
   │       └── templates/
   ├── .github/
   │   ├── workflows/
   │   └── cr.yaml
   ├── README.md
   ├── QUICKSTART.md
   ├── RANCHER-INTEGRATION.md
   ├── CONTRIBUTING.md
   ├── LICENSE
   ├── catalog.yml
   ├── .gitignore
   └── test-chart.ps1
   ```

### Validate Chart

Run the test script:
```powershell
.\test-chart.ps1
```

This will:
- Lint the chart
- Validate templates
- Test different configurations
- Package the chart
- Optionally test deployment

---

## 2. Publishing to GitHub

### Create GitHub Repository

1. **Via GitHub Web Interface:**
   - Go to https://github.com/new
   - Repository name: `fireball-podstore-charts`
   - Description: "Enterprise Helm charts for Rancher deployment - Fireball Industries"
   - Visibility: Public (for Rancher access)
   - Don't initialize with README (already exists)
   - Click **Create repository**

2. **Link Local Repository:**
   ```powershell
   git remote add origin https://github.com/YOUR-USERNAME/fireball-podstore-charts.git
   git branch -M main
   git push -u origin main
   ```

### Configure Repository Settings

1. **Enable GitHub Pages:**
   - Go to repository **Settings** → **Pages**
   - Source: **GitHub Actions**
   - This will host the Helm repository index

2. **Configure Secrets (if needed):**
   - Settings → Secrets and variables → Actions
   - Add secrets for:
     - Docker registry credentials (if private images)
     - Notification webhooks

3. **Branch Protection (Optional):**
   - Settings → Branches
   - Add rule for `main` branch:
     - Require pull request reviews
     - Require status checks

---

## 3. GitHub Pages Configuration

### Automatic Chart Publishing

The included GitHub Action (`.github/workflows/release.yml`) automatically:

1. Detects changes to `charts/` directory
2. Packages modified charts
3. Creates GitHub releases with chart packages
4. Updates `index.yaml` on GitHub Pages
5. Publishes to: `https://YOUR-USERNAME.github.io/fireball-podstore-charts`

### Manual Chart Release

If you need to manually release:

```powershell
# Package the chart
helm package charts/alert-manager

# Create GitHub release manually
# Upload the .tgz file as release asset

# Generate/update index
helm repo index . --url https://YOUR-USERNAME.github.io/fireball-podstore-charts

# Commit and push index.yaml
git add index.yaml
git commit -m "Update chart index"
git push
```

### Verify Publication

After first push:

1. Check **Actions** tab in GitHub
2. Wait for workflow to complete
3. Visit: `https://YOUR-USERNAME.github.io/fireball-podstore-charts/index.yaml`
4. Should see Helm repository index

---

## 4. Rancher Integration

### Add Repository to Rancher

**Method 1: Rancher UI**

1. Login to Rancher
2. Navigate to **Apps & Marketplace** → **Repositories**
3. Click **Create**
4. Configure:
   - Name: `fireball-podstore-charts`
   - Target: Git repository containing Helm chart definitions
   - Git Repo URL: `https://github.com/YOUR-USERNAME/fireball-podstore-charts`
   - Git Branch: `main`
5. Click **Create**

**Method 2: kubectl**

```bash
kubectl apply -f - <<EOF
apiVersion: catalog.cattle.io/v1
kind: ClusterRepo
metadata:
  name: fireball-podstore-charts
spec:
  gitRepo: https://github.com/YOUR-USERNAME/fireball-podstore-charts
  gitBranch: main
EOF
```

### Verify in Rancher

1. Go to **Apps & Marketplace** → **Charts**
2. Filter by repository: `fireball-podstore-charts`
3. Should see **Alert Manager** chart
4. Click to view details from `app-readme.md`

---

## 5. Deployment Workflows

### Development Workflow

1. **Local Development:**
   ```powershell
   # Make changes to chart
   cd charts/alert-manager
   
   # Test locally
   helm lint .
   helm template test . --debug
   
   # Test installation (dry-run)
   helm install test . --dry-run --debug
   ```

2. **Test in Dev Cluster:**
   ```powershell
   helm install test-release ./charts/alert-manager `
     --namespace alertmanager-dev `
     --create-namespace `
     --values ./charts/alert-manager/examples/development-values.yaml
   ```

3. **Commit Changes:**
   ```powershell
   # Update version in Chart.yaml first!
   git add .
   git commit -m "Update Alert Manager chart to v1.1.0"
   git push
   ```

4. **GitHub Actions automatically:**
   - Packages new version
   - Creates GitHub release
   - Updates index.yaml
   - Publishes to GitHub Pages

5. **Rancher Syncs:**
   - Automatically pulls updates (every 5-10 minutes)
   - New version appears in catalog

### Production Deployment via Rancher

1. **Navigate to Charts:**
   - Apps & Marketplace → Charts
   - Find Alert Manager

2. **Configure via Wizard:**
   - Select production namespace
   - Choose "Large" resource preset
   - Configure persistent storage
   - Set LoadBalancer service
   - Add Slack/PagerDuty credentials
   - Enable high availability (3+ replicas)

3. **Deploy:**
   - Click Install
   - Monitor deployment in Rancher UI

4. **Verify:**
   ```bash
   kubectl get all -n alertmanager-prod
   kubectl get pvc -n alertmanager-prod
   ```

### Upgrade Workflow

1. **In Rancher UI:**
   - Apps & Marketplace → Installed Apps
   - Find your installation
   - Click **Upgrade**
   - Modify values as needed
   - Click **Upgrade**

2. **Via Helm CLI:**
   ```bash
   helm upgrade my-alertmanager fireball-podstore/alert-manager \
     --namespace alertmanager \
     --reuse-values \
     --set image.tag=v0.27.0
   ```

---

## 6. Maintenance

### Updating Charts

1. **Make Changes:**
   - Edit chart files
   - Update version in `Chart.yaml`:
     ```yaml
     version: 1.1.0  # Increment
     appVersion: "v0.27.0"  # Update if app version changed
     ```

2. **Test Changes:**
   ```powershell
   .\test-chart.ps1
   ```

3. **Commit and Push:**
   ```powershell
   git add .
   git commit -m "feat: Add new feature X to Alert Manager"
   git tag v1.1.0
   git push --follow-tags
   ```

### Adding New Charts

1. **Create Chart Directory:**
   ```powershell
   mkdir charts\new-chart
   cd charts\new-chart
   ```

2. **Create Chart Files:**
   - Chart.yaml (with Rancher annotations)
   - values.yaml (with descriptions)
   - questions.yaml (for Rancher UI)
   - app-readme.md (for catalog)
   - templates/ directory
   - README.md

3. **Follow Alert Manager as Template**

4. **Test and Publish:**
   ```powershell
   helm lint charts/new-chart
   git add charts/new-chart
   git commit -m "Add new-chart v1.0.0"
   git push
   ```

### Monitoring and Support

**Check Chart Usage:**
- GitHub Insights → Traffic
- Monitor GitHub releases downloads

**Support Issues:**
- GitHub Issues for bug reports
- GitHub Discussions for questions

**Chart Updates:**
- Monitor upstream projects for updates
- Security advisories
- Kubernetes version compatibility

---

## Common Tasks Reference

### Local Testing Commands

```powershell
# Lint chart
helm lint charts/alert-manager

# Template rendering
helm template test charts/alert-manager

# Dry-run install
helm install test charts/alert-manager --dry-run --debug

# Package chart
helm package charts/alert-manager

# Test with custom values
helm install test charts/alert-manager -f custom-values.yaml --dry-run
```

### Git Operations

```powershell
# Check status
git status

# Stage changes
git add .

# Commit with message
git commit -m "Update chart"

# Push to GitHub
git push

# Create and push tag
git tag v1.0.0
git push --tags
```

### Rancher Operations

```bash
# List catalog repos
kubectl get clusterrepos

# Describe repo
kubectl describe clusterrepo fireball-podstore-charts

# Force refresh
kubectl annotate clusterrepo fireball-podstore-charts \
  catalog.cattle.io/force-refresh=$(date +%s)

# List installed apps
kubectl get apps -A
```

---

## Troubleshooting

### Chart Not Appearing in Rancher

1. Check repository sync status:
   ```bash
   kubectl get clusterrepos
   ```

2. Check repository events:
   ```bash
   kubectl describe clusterrepo fireball-podstore-charts
   ```

3. Force refresh:
   ```bash
   kubectl annotate clusterrepo fireball-podstore-charts \
     catalog.cattle.io/force-refresh=$(date +%s)
   ```

### GitHub Action Failing

1. Check Actions tab in GitHub
2. Review workflow logs
3. Verify Chart.yaml syntax
4. Check file permissions

### Helm Installation Fails

1. Check cluster resources:
   ```bash
   kubectl top nodes
   kubectl describe nodes
   ```

2. Verify storage class:
   ```bash
   kubectl get storageclass
   ```

3. Check events:
   ```bash
   kubectl get events -n [namespace] --sort-by='.lastTimestamp'
   ```

---

## Next Steps

1. ✅ Repository setup complete
2. ✅ Alert Manager chart ready
3. ⬜ Push to GitHub
4. ⬜ Verify GitHub Pages
5. ⬜ Add to Rancher
6. ⬜ Test deployment
7. ⬜ Create additional charts
8. ⬜ Document custom use cases

---

**Fireball Industries Podstore**  
Enterprise Container Solutions by Patrick Ryan  
https://github.com/fireball-industries/fireball-podstore-charts

For questions or support, open an issue on GitHub.
