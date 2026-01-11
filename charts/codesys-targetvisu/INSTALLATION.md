# CODESYS TargetVisu Installation Guide

Complete step-by-step installation guide for deploying CODESYS TargetVisu on Kubernetes/K3s.

## Prerequisites

### Required Software

- **Kubernetes/K3s**: v1.24 or higher
- **Helm**: v3.8 or higher
- **kubectl**: Matching your cluster version
- **Docker/Podman**: For building container images
- **CODESYS TargetVisu Package**: Download from [CODESYS Store](https://store.codesys.com/)
- **Valid License**: Commercial license or trial

### System Requirements

| Deployment Type | CPU | Memory | Storage |
|----------------|-----|--------|---------|
| Edge Minimal (Raspberry Pi) | 500m | 512Mi | 5Gi |
| Edge Standard (Industrial PC) | 1000m | 1Gi | 10Gi |
| Industrial (Large SCADA) | 2000m | 2Gi | 20Gi |

## Quick Start (5 Minutes)

### 1. Build Docker Image

```bash
# Place CODESYS .deb package in docker/ directory
cp codesys-targetvisu-*.deb docker/

# Build image
cd docker
docker build -t codesys-targetvisu:3.5.20.0 .

# Tag for your registry
docker tag codesys-targetvisu:3.5.20.0 ghcr.io/YOUR-ORG/codesys-targetvisu:3.5.20.0

# Push to registry
docker push ghcr.io/YOUR-ORG/codesys-targetvisu:3.5.20.0
```

### 2. Install License

```powershell
# Create license secret
.\scripts\license-manager.ps1 -Action install -LicenseFile C:\path\to\license.lic
```

### 3. Deploy Helm Chart

```powershell
# Using standard factory configuration
.\scripts\manage-targetvisu.ps1 -Action deploy -ValuesFile .\examples\standard-factory.yaml

# Or using Helm directly
helm install codesys-targetvisu . `
  --namespace industrial `
  --create-namespace `
  --values examples\standard-factory.yaml
```

### 4. Access HMI

```powershell
# Get service details
kubectl get svc -n industrial codesys-targetvisu

# Access via NodePort
# http://<NODE-IP>:30080
```

## Detailed Installation

### Step 1: Prepare Kubernetes Cluster

#### K3s Installation (Lightweight Kubernetes)

```bash
# Install K3s on Linux
curl -sfL https://get.k3s.io | sh -

# Verify installation
kubectl get nodes

# Get kubeconfig
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

#### Kubernetes Cluster Setup

Ensure your cluster has:
- Storage provisioner (local-path, NFS, or cloud provider)
- Ingress controller (nginx, traefik)
- LoadBalancer (MetalLB for bare metal)

```bash
# Install nginx ingress controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace

# Install MetalLB (for bare metal)
helm repo add metallb https://metallb.github.io/metallb
helm install metallb metallb/metallb -n metallb-system --create-namespace
```

### Step 2: Build and Push Container Image

#### Download CODESYS Package

1. Visit [CODESYS Store](https://store.codesys.com/)
2. Download "CODESYS TargetVisu for Linux SL" (.deb package)
3. Place in `docker/` directory

#### Build Multi-Architecture Images

```bash
# For amd64 only
docker build -t codesys-targetvisu:3.5.20.0 -f docker/Dockerfile docker/

# For multi-arch (amd64, arm64, armv7)
docker buildx create --name multiarch --use
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -t ghcr.io/YOUR-ORG/codesys-targetvisu:3.5.20.0 \
  --push \
  docker/
```

#### Configure Image Registry

Update `values.yaml`:

```yaml
targetvisu:
  image:
    repository: ghcr.io/YOUR-ORG/codesys-targetvisu
    tag: "3.5.20.0"
    # For private registries
    pullSecrets:
      - name: regcred
```

Create pull secret if using private registry:

```bash
kubectl create secret docker-registry regcred \
  --docker-server=ghcr.io \
  --docker-username=YOUR-USERNAME \
  --docker-password=YOUR-TOKEN \
  --namespace=industrial
```

### Step 3: Configure License

#### Option 1: License File

```powershell
# Install license via PowerShell script
.\scripts\license-manager.ps1 `
  -Action install `
  -LicenseFile C:\licenses\codesys.lic `
  -Namespace industrial

# Or manually create secret
kubectl create secret generic codesys-license `
  --from-file=license.lic=C:\licenses\codesys.lic `
  --namespace=industrial
```

Update `values.yaml`:

```yaml
targetvisu:
  license:
    type: file
    licenseSecret: codesys-license
    licenseKey: license.lic
```

#### Option 2: License Server

```yaml
targetvisu:
  license:
    type: server
    licenseServer:
      host: "license.yourcompany.com"
      port: 1947
```

#### Option 3: Demo Mode

```yaml
targetvisu:
  license:
    type: demo
    demo:
      duration: 30  # days
```

### Step 4: Customize Configuration

Choose a preset or customize:

```yaml
# Quick preset
resourcePreset: edge-standard

# Or customize everything
resources:
  requests:
    cpu: 1000m
    memory: 1Gi
  limits:
    cpu: 2000m
    memory: 2Gi

storage:
  config:
    size: 5Gi
  projects:
    size: 10Gi
  logs:
    size: 2Gi
```

### Step 5: Deploy

#### Using PowerShell Script (Recommended)

```powershell
# Deploy with standard config
.\scripts\manage-targetvisu.ps1 `
  -Action deploy `
  -ReleaseName my-hmi `
  -Namespace industrial `
  -ValuesFile .\examples\standard-factory.yaml
```

#### Using Helm Directly

```bash
helm install codesys-targetvisu . \
  --namespace industrial \
  --create-namespace \
  --values examples/standard-factory.yaml \
  --timeout 10m
```

### Step 6: Verify Deployment

```powershell
# Check deployment status
.\scripts\manage-targetvisu.ps1 -Action status

# Or manually
kubectl get all -n industrial
kubectl get pvc -n industrial
kubectl logs -n industrial deployment/codesys-targetvisu -f
```

### Step 7: Access HMI

#### NodePort Access

```bash
# Get node IP and port
kubectl get svc -n industrial codesys-targetvisu
kubectl get nodes -o wide

# Access HMI
# http://<NODE-IP>:30080
```

#### Ingress Access (Production)

Configure ingress in `values.yaml`:

```yaml
ingress:
  enabled: true
  className: nginx
  host: hmi.yourcompany.com
  tls:
    enabled: true
    secretName: hmi-tls
```

Set up DNS to point to ingress controller.

#### Port Forward (Testing)

```bash
kubectl port-forward -n industrial svc/codesys-targetvisu 8080:8080

# Access at http://localhost:8080
```

## Post-Installation

### Deploy Sample Project

```powershell
.\scripts\project-deploy.ps1 `
  -ProjectPath .\sample-projects\basic-buttons `
  -Namespace industrial
```

### Configure Monitoring

```bash
# Install Prometheus (if not already installed)
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring --create-namespace

# Apply CODESYS dashboards
kubectl apply -f dashboards/ -n monitoring
kubectl apply -f alerts/ -n monitoring
```

### Enable HTTPS

```bash
# Install cert-manager
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true

# Configure in values.yaml
ingress:
  enabled: true
  tls:
    enabled: true
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
```

## Troubleshooting

### Pod Won't Start

```bash
# Check pod status
kubectl describe pod -n industrial -l app.kubernetes.io/instance=codesys-targetvisu

# Check events
kubectl get events -n industrial --sort-by='.lastTimestamp'

# View logs
kubectl logs -n industrial deployment/codesys-targetvisu --previous
```

### License Issues

```bash
# Verify license secret
kubectl get secret -n industrial codesys-license
kubectl get secret -n industrial codesys-license -o yaml

# Check license in pod
kubectl exec -n industrial deployment/codesys-targetvisu -- ls -la /var/opt/codesys/license/
```

### Storage Issues

```bash
# Check PVCs
kubectl get pvc -n industrial

# Describe PVC
kubectl describe pvc -n industrial codesys-targetvisu-config

# Check storage class
kubectl get sc
```

### Network Issues

```bash
# Test from within cluster
kubectl run -it --rm debug --image=busybox --restart=Never -n industrial -- sh
wget -O- http://codesys-targetvisu:8080

# Check service
kubectl get svc -n industrial codesys-targetvisu
kubectl describe svc -n industrial codesys-targetvisu
```

## Upgrading

```powershell
# Upgrade deployment
.\scripts\manage-targetvisu.ps1 `
  -Action upgrade `
  -ValuesFile .\examples\standard-factory.yaml

# Or with Helm
helm upgrade codesys-targetvisu . -n industrial --values examples/standard-factory.yaml
```

## Backup and Restore

```powershell
# Backup
.\scripts\manage-targetvisu.ps1 -Action backup -BackupPath C:\backups\hmi

# Restore
.\scripts\manage-targetvisu.ps1 -Action restore -BackupPath C:\backups\hmi\2026-01-11_10-30-00
```

## Uninstallation

```powershell
# Delete deployment
.\scripts\manage-targetvisu.ps1 -Action delete

# Or with Helm
helm uninstall codesys-targetvisu -n industrial

# Delete PVCs (optional - this deletes all data!)
kubectl delete pvc -n industrial -l app.kubernetes.io/instance=codesys-targetvisu
```

## Next Steps

- [Configure Industrial Protocols](PROTOCOLS.md)
- [Deploy HMI Projects](PROJECTS.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)
- [Quick Reference](QUICK_REFERENCE.md)

---

**Made with 💀 by Fireball Industries**

*"Installation complete. Your HMI is now cloud-native. Your operators still don't trust it."*
