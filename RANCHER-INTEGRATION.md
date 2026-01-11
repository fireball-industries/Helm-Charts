# Rancher Integration Guide
# Fireball Industries Podstore Charts - Patrick Ryan

## Overview

This guide explains how to integrate the Fireball Industries Podstore Helm Charts repository with Rancher Apps & Marketplace.

## Prerequisites

- Rancher 2.6 or higher
- k3s 1.25+ cluster managed by Rancher
- Admin access to Rancher UI
- Git repository hosting the charts (GitHub recommended)

## Integration Steps

### 1. Prepare Your Git Repository

Ensure your repository is structured correctly:

```
fireball-podstore-charts/
├── charts/
│   └── alert-manager/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── questions.yaml
│       ├── app-readme.md
│       └── templates/
├── README.md
├── catalog.yml
└── .github/workflows/
```

**Important Files for Rancher:**

- `Chart.yaml` - Must include Rancher annotations
- `questions.yaml` - Defines the deployment wizard UI
- `app-readme.md` - Shown in Rancher catalog
- `catalog.yml` - Repository metadata

### 2. Add Repository to Rancher

#### Option A: Via Rancher UI

1. **Login to Rancher**
   - Navigate to your Rancher instance
   - Ensure you're in the correct cluster context

2. **Open Apps & Marketplace**
   - Click on the cluster name
   - Select **Apps & Marketplace** from left menu
   - Click on **Repositories** tab

3. **Add New Repository**
   - Click **Create** button
   - Fill in the form:
     ```
     Name: fireball-podstore-charts
     Target: Git repository containing Helm chart or cluster template definitions
     Git Repo URL: https://github.com/fireball-industries/fireball-podstore-charts
     Git Branch: main
     ```
   - Click **Create**

4. **Wait for Sync**
   - Repository status will show "Active" when ready
   - This may take 1-2 minutes

#### Option B: Via kubectl

Create a CatalogV2 resource:

```yaml
apiVersion: catalog.cattle.io/v1
kind: ClusterRepo
metadata:
  name: fireball-podstore-charts
spec:
  gitRepo: https://github.com/fireball-industries/fireball-podstore-charts
  gitBranch: main
```

Apply it:
```bash
kubectl apply -f catalog-repo.yaml
```

### 3. Verify Repository Integration

1. Go to **Apps & Marketplace** → **Charts**
2. In the filter, select "fireball-podstore-charts" repository
3. You should see "Alert Manager" chart appear
4. Click on it to view details

### 4. Deploy from Rancher Catalog

1. **Find the Chart**
   - Navigate to **Apps & Marketplace** → **Charts**
   - Search for "Alert Manager" or browse categories

2. **Install the Chart**
   - Click on **Alert Manager** chart
   - Review the app-readme.md content
   - Click **Install**

3. **Configure via Wizard**
   
   The deployment wizard (from questions.yaml) will show:
   
   **Namespace Configuration:**
   - Namespace name
   - Create namespace option
   
   **Deployment Configuration:**
   - Replica count
   - Image version
   
   **Resource Configuration:**
   - Preset selection (Small/Medium/Large/Custom)
   - Custom resource limits (if Custom selected)
   
   **Storage Configuration:**
   - Enable/disable persistence
   - Storage size
   - Storage class
   
   **Service Configuration:**
   - Service type (ClusterIP/NodePort/LoadBalancer)
   - Port configuration
   - LoadBalancer IP (if applicable)
   
   **Ingress Configuration:**
   - Enable ingress
   - Hostname
   - TLS settings
   
   **Alert Configuration:**
   - Routing timeouts
   - Slack webhook URL
   - Email SMTP settings
   - PagerDuty integration
   
4. **Deploy**
   - Review configuration
   - Click **Install**
   - Monitor deployment progress

### 5. Rancher-Specific Features

#### Questions.yaml Enhancements

The `questions.yaml` file provides:

- **Grouped Configuration**: Related settings grouped together
- **Conditional Fields**: Show/hide based on other selections
- **Type Validation**: Enum dropdowns, boolean toggles, etc.
- **Help Text**: Descriptions for each field
- **Default Values**: Pre-filled sensible defaults

#### Chart Annotations in Chart.yaml

Key Rancher annotations:

```yaml
annotations:
  catalog.cattle.io/display-name: "Alert Manager"
  catalog.cattle.io/certified: "partner"
  catalog.cattle.io/kube-version: ">=1.25.0"
  catalog.cattle.io/rancher-version: ">=2.6.0"
  catalog.cattle.io/categories: "Monitoring,Alerting"
```

These enable:
- Certification badge in UI
- Version compatibility checks
- Category filtering
- Enhanced display

#### Project/Namespace Integration

Rancher's project-based multi-tenancy:

- Deploy to specific projects
- Inherit project resource quotas
- Apply project network policies
- Project-level RBAC enforcement

### 6. Managing Deployed Apps

#### Via Rancher UI

1. Go to **Apps & Marketplace** → **Installed Apps**
2. Find your Alert Manager installation
3. Available actions:
   - **Edit/Upgrade**: Modify configuration
   - **Rollback**: Revert to previous version
   - **Delete**: Remove installation

#### Upgrading Applications

1. Navigate to **Installed Apps**
2. Click on the app name
3. Click **Upgrade**
4. Modify values in the wizard
5. Click **Upgrade**

#### Viewing App Resources

1. Click on app name in **Installed Apps**
2. View all created resources:
   - Deployments
   - Services
   - ConfigMaps
   - PVCs
   - etc.

### 7. Troubleshooting Rancher Integration

#### Chart Not Appearing in Catalog

**Possible causes:**
- Repository not synced yet (wait 2-3 minutes)
- Git repository URL incorrect
- Branch name wrong
- Chart.yaml missing required fields

**Solution:**
```bash
# Check repository status
kubectl get clusterrepos

# View repository details
kubectl describe clusterrepo fireball-podstore-charts

# Force refresh
kubectl annotate clusterrepo fireball-podstore-charts \
  catalog.cattle.io/force-refresh=$(date +%s)
```

#### Deployment Fails from Rancher

**Common issues:**
- Insufficient resources in cluster
- Storage class not available
- Invalid configuration values

**Check:**
1. View Helm operation logs in Rancher
2. Check pod events:
   ```bash
   kubectl get events -n [namespace] --sort-by='.lastTimestamp'
   ```
3. Check pod status:
   ```bash
   kubectl get pods -n [namespace]
   ```

#### questions.yaml Not Working

Ensure:
- File is named exactly `questions.yaml`
- YAML syntax is valid
- Variable names match values.yaml exactly
- Proper indentation

Test locally:
```bash
# Validate YAML syntax
yamllint questions.yaml
```

### 8. Advanced: Custom Catalog Icons

To add custom icons visible in Rancher:

1. Host icon file (SVG or PNG)
2. Add to Chart.yaml:
   ```yaml
   icon: https://your-domain.com/path/to/icon.svg
   ```

For Fireball Industries branding:
```yaml
icon: https://raw.githubusercontent.com/fireball-industries/branding/main/logo.svg
```

### 9. Multi-Cluster Deployment

Deploy to multiple clusters from Rancher:

1. Navigate to **Apps & Marketplace**
2. Click **Multi-Cluster Apps** (if using Fleet)
3. Select target clusters
4. Configure globally or per-cluster
5. Deploy

### 10. Best Practices

1. **Version Control**: Always version your charts properly
2. **Testing**: Test in dev environment before production
3. **Documentation**: Keep app-readme.md updated
4. **Security**: Review security contexts and RBAC
5. **Resources**: Set appropriate limits and requests
6. **Monitoring**: Enable monitoring and alerting
7. **Backup**: Document backup procedures

### 11. Support and Resources

- **Rancher Documentation**: https://rancher.com/docs/
- **Helm Documentation**: https://helm.sh/docs/
- **Chart Repository**: https://github.com/fireball-industries/fireball-podstore-charts
- **Issues**: https://github.com/fireball-industries/fireball-podstore-charts/issues

---

## Quick Reference Commands

### Check Catalog Status
```bash
kubectl get clusterrepos
kubectl describe clusterrepo fireball-podstore-charts
```

### Force Catalog Refresh
```bash
kubectl annotate clusterrepo fireball-podstore-charts \
  catalog.cattle.io/force-refresh=$(date +%s)
```

### View Installed Apps
```bash
kubectl get apps -A
```

### Debug Helm Releases
```bash
helm list -A
helm history [release-name] -n [namespace]
helm get values [release-name] -n [namespace]
```

---

**Fireball Industries Podstore**  
Crafted by Patrick Ryan  
Enterprise Container Solutions for Modern Infrastructure
