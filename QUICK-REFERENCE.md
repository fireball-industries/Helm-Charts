# Fireball Industries Podstore Charts
# Quick Reference Card

## 📦 Chart Testing

# Lint chart
helm lint charts/alert-manager

# Validate templates
helm template test charts/alert-manager

# Dry-run install
helm install test charts/alert-manager --dry-run --debug

# Package chart
helm package charts/alert-manager

# Run test script
.\test-chart.ps1

## 🚀 Helm Deployment

# Add repository
helm repo add fireball-podstore https://YOUR-USERNAME.github.io/fireball-podstore-charts
helm repo update

# Install with defaults
helm install my-alertmanager fireball-podstore/alert-manager \
  --namespace alertmanager \
  --create-namespace

# Install with custom values
helm install my-alertmanager fireball-podstore/alert-manager \
  --namespace alertmanager \
  --create-namespace \
  --values custom-values.yaml

# Install with preset
helm install my-alertmanager fireball-podstore/alert-manager \
  --namespace alertmanager \
  --create-namespace \
  --set resources.preset=large

# Upgrade release
helm upgrade my-alertmanager fireball-podstore/alert-manager \
  --namespace alertmanager \
  --reuse-values

# Rollback release
helm rollback my-alertmanager -n alertmanager

# Uninstall
helm uninstall my-alertmanager -n alertmanager

# List releases
helm list -A

# Get values
helm get values my-alertmanager -n alertmanager

# View history
helm history my-alertmanager -n alertmanager

## 🔍 Kubernetes Operations

# Check pods
kubectl get pods -n alertmanager

# Check services
kubectl get svc -n alertmanager

# Check all resources
kubectl get all -n alertmanager

# View logs
kubectl logs -n alertmanager -l app.kubernetes.io/name=alert-manager -f

# Describe pod
kubectl describe pod -n alertmanager POD-NAME

# Get events
kubectl get events -n alertmanager --sort-by='.lastTimestamp'

# Port forward
kubectl port-forward -n alertmanager svc/SERVICE-NAME 9093:9093

# Execute command in pod
kubectl exec -it -n alertmanager POD-NAME -- /bin/sh

## 🐮 Rancher Integration

# List catalog repositories
kubectl get clusterrepos

# Describe repository
kubectl describe clusterrepo fireball-podstore-charts

# Force repository refresh
kubectl annotate clusterrepo fireball-podstore-charts \
  catalog.cattle.io/force-refresh=$(date +%s)

# List installed apps
kubectl get apps -A

# Check Helm operations
kubectl get helmchartconfigs -A

## 📝 Git Operations

# Check status
git status

# Stage all changes
git add .

# Commit
git commit -m "Update Alert Manager chart"

# Push to GitHub
git push

# Create tag
git tag v1.0.0
git push --tags

# View logs
git log --oneline

# Create branch
git checkout -b feature/new-feature

# Merge branch
git checkout main
git merge feature/new-feature

## 🔧 Troubleshooting

# Check node resources
kubectl top nodes

# Check pod resources
kubectl top pods -n alertmanager

# Describe node
kubectl describe node NODE-NAME

# Get storage classes
kubectl get storageclass

# Check PVC
kubectl get pvc -n alertmanager

# Describe PVC
kubectl describe pvc -n alertmanager PVC-NAME

# Check ConfigMap
kubectl get configmap -n alertmanager
kubectl describe configmap -n alertmanager CONFIG-NAME

# View ConfigMap content
kubectl get configmap -n alertmanager CONFIG-NAME -o yaml

# Check secrets
kubectl get secrets -n alertmanager

## 📊 Monitoring

# Watch pods
kubectl get pods -n alertmanager -w

# Watch events
kubectl get events -n alertmanager -w

# View deployment status
kubectl rollout status deployment/DEPLOYMENT-NAME -n alertmanager

# View deployment history
kubectl rollout history deployment/DEPLOYMENT-NAME -n alertmanager

# Restart deployment
kubectl rollout restart deployment/DEPLOYMENT-NAME -n alertmanager

## 🧪 Testing Alerts

# Port forward to Alert Manager
kubectl port-forward -n alertmanager svc/alertmanager 9093:9093

# Send test alert (from another terminal)
curl -XPOST http://localhost:9093/api/v1/alerts -d '[{
  "labels": {
    "alertname": "TestAlert",
    "severity": "warning"
  },
  "annotations": {
    "summary": "Test alert from Fireball Industries"
  }
}]'

# View alerts via API
curl http://localhost:9093/api/v2/alerts

# View silences
curl http://localhost:9093/api/v2/silences

## 💾 Backup & Recovery

# Backup Alert Manager data
kubectl exec -n alertmanager POD-NAME -- tar czf - /alertmanager > backup.tar.gz

# Backup ConfigMap
kubectl get configmap -n alertmanager CONFIG-NAME -o yaml > configmap-backup.yaml

# Backup PVC
kubectl get pvc -n alertmanager PVC-NAME -o yaml > pvc-backup.yaml

# Export Helm values
helm get values my-alertmanager -n alertmanager > values-backup.yaml

## 🔒 Security

# Check pod security context
kubectl get pod POD-NAME -n alertmanager -o jsonpath='{.spec.securityContext}'

# Check container security context
kubectl get pod POD-NAME -n alertmanager -o jsonpath='{.spec.containers[0].securityContext}'

# View service account
kubectl get sa -n alertmanager
kubectl describe sa SERVICE-ACCOUNT-NAME -n alertmanager

## 📈 Scaling

# Scale deployment
kubectl scale deployment DEPLOYMENT-NAME -n alertmanager --replicas=3

# Autoscale (requires HPA)
kubectl autoscale deployment DEPLOYMENT-NAME -n alertmanager --min=2 --max=5 --cpu-percent=80

# Check HPA
kubectl get hpa -n alertmanager

## 🌐 Network

# Get service endpoints
kubectl get endpoints -n alertmanager

# Test service connectivity
kubectl run test-pod --image=busybox:1.28 --rm -it -- \
  wget -qO- http://SERVICE-NAME.alertmanager.svc.cluster.local:9093

# Check network policies
kubectl get networkpolicies -n alertmanager

## 📦 Chart Development

# Create new chart
helm create charts/new-chart

# Update dependencies
helm dependency update charts/alert-manager

# Show chart info
helm show chart charts/alert-manager

# Show values
helm show values charts/alert-manager

# Show readme
helm show readme charts/alert-manager

# Template with debug
helm template test charts/alert-manager --debug

## 🔄 CI/CD

# Check GitHub Actions status
# Visit: https://github.com/YOUR-USERNAME/fireball-podstore-charts/actions

# Manually trigger workflow
# Via GitHub UI or gh CLI:
gh workflow run release.yml

# View workflow runs
gh run list

## ⚙️ Configuration

# Edit values in running release
helm get values my-alertmanager -n alertmanager > current-values.yaml
# Edit current-values.yaml
helm upgrade my-alertmanager fireball-podstore/alert-manager \
  -n alertmanager -f current-values.yaml

# Set single value
helm upgrade my-alertmanager fireball-podstore/alert-manager \
  -n alertmanager --set image.tag=v0.27.0

# Reset to defaults
helm upgrade my-alertmanager fireball-podstore/alert-manager \
  -n alertmanager --reset-values

---
Fireball Industries Podstore - Patrick Ryan
https://github.com/fireball-industries/fireball-podstore-charts
