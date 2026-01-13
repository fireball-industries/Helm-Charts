# Rancher OCI Repository Setup Guide

## Quick Start (5 Minutes)

### Step 1: Login to Rancher
Navigate to: https://rancher.embernet.ai/

### Step 2: Add OCI Repository
1. Click **☰** (hamburger menu) → **local** cluster
2. Go to **Apps** → **Repositories**
3. Click **Create** button
4. Fill in the form:
   ```
   Repository Type: OCI
   Name: fireball-podstore
   Index URL: oci://ghcr.io/fireball-industries
   
   Authentication:
   ☑ Use Authentication
   Username: fireball-industries  
   Password: <YOUR_GITHUB_PAT>
   ```
5. Click **Create**

### Step 3: Verify Charts Appear
1. Go to **Apps** → **Charts**
2. In the repository filter, select **fireball-podstore**
3. You should see 18 charts available

### Step 4: Test Deployment
Try deploying a simple chart to verify everything works:
1. Search for **prometheus-pod**
2. Click **Install**
3. Set namespace: `monitoring`
4. Click **Install**
5. Verify pod starts successfully

## Available Charts (18/20)

### Monitoring (6)
- ✅ alert-manager - Prometheus Alertmanager for alert routing
- ✅ grafana-loki - Grafana with Loki log aggregation
- ✅ node-red - Visual programming for IoT workflows
- ✅ prometheus-pod - Prometheus monitoring server
- ✅ telegraf-pod - Metrics collection agent
- ✅ traefik-pod - Modern HTTP reverse proxy

### Industrial Automation (4)
- ✅ codesys-x86 - CODESYS PLC runtime for x86
- ✅ codesys-edge-gateway - Edge gateway for CODESYS
- ✅ codesys-runtime-arm - CODESYS runtime for ARM64
- ⚠️ emberburn - IoT gateway (pending permissions)

### Application (5)
- ✅ industrial-iot - Home Assistant for industrial IoT
- ⚠️ ignition-edge - Ignition SCADA (pending YAML fix)
- ✅ n8n-pod - Workflow automation
- ✅ node-exporter-pod - Prometheus node exporter
- ✅ microvm - Firecracker microVM orchestration

### Database (4)
- ✅ influxdb-pod - InfluxDB time-series database
- ✅ postgresql-pod - PostgreSQL relational database
- ✅ sqlite-pod - SQLite embedded database
- ✅ timescaledb - TimescaleDB for time-series

### Infrastructure (1)
- ✅ mosquitto-mqtt - Eclipse Mosquitto MQTT broker

## Troubleshooting

### "Repository not found" Error
**Cause:** OCI URL incorrect or authentication failed  
**Fix:** Verify URL is `oci://ghcr.io/fireball-industries` (not `https://`)

### "Unauthorized" Error
**Cause:** GitHub PAT missing `read:packages` scope  
**Fix:** Regenerate PAT with correct scopes at https://github.com/settings/tokens

### Charts Don't Appear
**Cause:** Rancher caching issue  
**Fix:**
1. Delete repository in Rancher
2. Wait 30 seconds
3. Re-add repository
4. Force refresh: `kubectl delete po -n cattle-system -l app=rancher`

### Chart Install Fails
**Cause:** Resource conflicts or missing dependencies  
**Fix:**
1. Check namespace doesn't have conflicting resources
2. Review chart's README.md for dependencies
3. Check cluster has sufficient resources

## Advanced Configuration

### Using Custom Values
Each chart supports customization via values.yaml:
1. Click chart → **Install**
2. Scroll to **Values YAML** section
3. Edit values as needed
4. Common options:
   - `replicaCount`: Number of pods
   - `image.tag`: Specific image version
   - `resources`: CPU/memory limits
   - `persistence.enabled`: Enable persistent storage

### Namespace Isolation
Recommended namespace structure:
```
monitoring/     - Prometheus, Grafana, Alert Manager
databases/      - PostgreSQL, InfluxDB, TimescaleDB
iot/           - MQTT, Industrial IoT, CODESYS
automation/    - n8n, Node-RED
infrastructure/ - Traefik, microVM
```

Create namespaces:
```bash
kubectl create namespace monitoring
kubectl create namespace databases
kubectl create namespace iot
kubectl create namespace automation
kubectl create namespace infrastructure
```

### GitOps Integration
For production deployments, use Fleet:
1. Create Git repository with values files
2. Add Fleet GitRepo resource
3. Point to your Helm chart values
4. Fleet will auto-deploy and sync

Example Fleet GitRepo:
```yaml
apiVersion: fleet.cattle.io/v1alpha1
kind: GitRepo
metadata:
  name: fireball-charts
  namespace: fleet-default
spec:
  repo: https://github.com/fireball-industries/helm-values
  branch: main
  paths:
  - charts
  targets:
  - name: local
    clusterSelector:
      matchLabels:
        env: production
```

## Security Considerations

### 1. Image Security
All charts pull from ghcr.io/fireball-industries. Ensure:
- Images are scanned for vulnerabilities
- Use specific tags (not `latest`)
- Enable imagePullSecrets for private images

### 2. RBAC
Charts create ServiceAccounts with minimal permissions. Review and adjust:
```bash
kubectl get sa -n <namespace>
kubectl describe sa <chart-name> -n <namespace>
```

### 3. Network Policies
Implement network segmentation:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

### 4. Secrets Management
Use Kubernetes secrets or external secret managers:
- Sealed Secrets
- External Secrets Operator  
- Vault
- AWS Secrets Manager

## Monitoring Deployment

### Check Chart Status
```bash
# List all releases
helm list -A

# Get release details
helm status <release-name> -n <namespace>

# View release history
helm history <release-name> -n <namespace>
```

### Debug Failed Deployments
```bash
# Check pod status
kubectl get pods -n <namespace>

# View pod logs
kubectl logs <pod-name> -n <namespace>

# Describe pod for events
kubectl describe pod <pod-name> -n <namespace>

# Check PVC status (if persistence enabled)
kubectl get pvc -n <namespace>
```

### Uninstall Chart
```bash
helm uninstall <release-name> -n <namespace>
```

## Multi-Cluster Deployment

For deploying across multiple clusters:

### Option 1: Rancher Multi-Cluster Apps
1. Go to **☰** → **Multi-Cluster Apps**
2. Click **Install from Catalog**
3. Select fireball-podstore repository
4. Choose target clusters
5. Install

### Option 2: Fleet
See GitOps Integration section above

## Updating Charts

When new chart versions are available:
```bash
# Update repository cache
helm repo update

# Check for updates
helm search repo fireball-podstore --versions

# Upgrade release
helm upgrade <release-name> fireball-podstore/<chart-name> -n <namespace>
```

Or use Rancher UI:
1. **Apps** → **Installed Apps**
2. Click release → **Upgrade**
3. Select new version
4. Review changes
5. Click **Upgrade**

## Support

- **GitHub Issues:** https://github.com/fireball-industries/Helm-Charts/issues
- **Documentation:** Check each chart's README.md
- **Rancher Docs:** https://ranchermanager.docs.rancher.com/

## Next Steps

1. ✅ Add OCI repository to Rancher
2. ✅ Deploy test chart (prometheus-pod recommended)
3. ⏭️ Deploy production workloads
4. ⏭️ Configure monitoring and alerting
5. ⏭️ Set up GitOps with Fleet
6. ⏭️ Implement backup strategy

