# CODESYS TargetVisu - Quick Reference

Fast command reference for common operations.

## 🚀 Deployment

```powershell
# Deploy with defaults
.\scripts\manage-targetvisu.ps1 -Action deploy

# Deploy with custom config
.\scripts\manage-targetvisu.ps1 -Action deploy -ValuesFile .\examples\standard-factory.yaml

# Deploy to specific namespace
.\scripts\manage-targetvisu.ps1 -Action deploy -Namespace production
```

## 🔄 Management

```powershell
# Check status
.\scripts\manage-targetvisu.ps1 -Action status

# Restart HMI (the universal fix)
.\scripts\manage-targetvisu.ps1 -Action restart

# Upgrade
.\scripts\manage-targetvisu.ps1 -Action upgrade -ValuesFile .\values.yaml

# Delete
.\scripts\manage-targetvisu.ps1 -Action delete
```

## 📜 License

```powershell
# Install license
.\scripts\license-manager.ps1 -Action install -LicenseFile C:\license.lic

# View license info
.\scripts\license-manager.ps1 -Action info
```

## 📦 Projects

```powershell
# Deploy HMI project
.\scripts\project-deploy.ps1 -ProjectPath .\my-project

# Deploy sample
.\scripts\project-deploy.ps1 -ProjectPath .\sample-projects\basic-buttons
```

## 💾 Backup & Restore

```powershell
# Backup
.\scripts\manage-targetvisu.ps1 -Action backup -BackupPath C:\backups

# Restore
.\scripts\manage-targetvisu.ps1 -Action restore -BackupPath C:\backups\2026-01-11
```

## 🐛 Troubleshooting

```powershell
# View logs
.\scripts\manage-targetvisu.ps1 -Action logs

# Run diagnostics
.\scripts\diagnostics.ps1

# Get shell access
.\scripts\manage-targetvisu.ps1 -Action shell

# Run tests
.\scripts\test-targetvisu.ps1 -TestType all
```

## 🔍 Kubectl Commands

```bash
# Get pod status
kubectl get pods -n industrial -l app.kubernetes.io/instance=codesys-targetvisu

# View logs
kubectl logs -n industrial deployment/codesys-targetvisu -f

# Describe pod
kubectl describe pod -n industrial <POD-NAME>

# Execute command in pod
kubectl exec -n industrial <POD-NAME> -- <COMMAND>

# Port forward
kubectl port-forward -n industrial svc/codesys-targetvisu 8080:8080

# Get service info
kubectl get svc -n industrial codesys-targetvisu

# Check PVCs
kubectl get pvc -n industrial

# View events
kubectl get events -n industrial --sort-by='.lastTimestamp'

# Delete pod (forces restart)
kubectl delete pod -n industrial <POD-NAME>

# Scale deployment (not recommended for stateful apps)
kubectl scale deployment/codesys-targetvisu -n industrial --replicas=1
```

## 🎯 Helm Commands

```bash
# Install
helm install codesys-targetvisu . -n industrial --create-namespace

# Upgrade
helm upgrade codesys-targetvisu . -n industrial

# Rollback
helm rollback codesys-targetvisu -n industrial

# Uninstall
helm uninstall codesys-targetvisu -n industrial

# List releases
helm list -n industrial

# Get values
helm get values codesys-targetvisu -n industrial

# History
helm history codesys-targetvisu -n industrial

# Test (dry-run)
helm install codesys-targetvisu . -n industrial --dry-run --debug
```

## 🌐 Access URLs

```bash
# NodePort
http://<NODE-IP>:30080          # HTTP
https://<NODE-IP>:30443         # HTTPS
http://<NODE-IP>:30081          # WebVisu

# Ingress
https://hmi.example.com

# Port Forward
kubectl port-forward -n industrial svc/codesys-targetvisu 8080:8080
# Then: http://localhost:8080
```

## 📊 Monitoring

```bash
# Prometheus metrics
kubectl port-forward -n industrial svc/codesys-targetvisu 9100:9100
# Visit: http://localhost:9100/metrics

# Import Grafana dashboards
kubectl apply -f dashboards/ -n monitoring

# Apply alert rules
kubectl apply -f alerts/ -n monitoring
```

## 🔐 Security

```bash
# Create TLS secret
kubectl create secret tls codesys-tls \
  --cert=tls.crt \
  --key=tls.key \
  -n industrial

# Create password secret
kubectl create secret generic codesys-admin-password \
  --from-literal=password='YourSecurePassword' \
  -n industrial

# Create registry credentials
kubectl create secret docker-registry regcred \
  --docker-server=ghcr.io \
  --docker-username=USERNAME \
  --docker-password=TOKEN \
  -n industrial
```

## 🏗️ Resource Presets

```yaml
# Minimal (Raspberry Pi)
resourcePreset: edge-minimal
# 500m CPU, 512Mi RAM, 5Gi storage

# Standard (Industrial PC)
resourcePreset: edge-standard
# 1000m CPU, 1Gi RAM, 10Gi storage

# Large (Enterprise SCADA)
resourcePreset: industrial
# 2000m CPU, 2Gi RAM, 20Gi storage
```

## 🔌 Protocol Ports

| Protocol | Port | Enable In values.yaml |
|----------|------|----------------------|
| HTTP | 8080 | Always on |
| HTTPS | 8443 | `security.tls.enabled: true` |
| WebVisu | 8081 | Always on |
| OPC UA | 4840 | `protocols.opcua.enabled: true` |
| Modbus TCP | 502 | `protocols.modbusTcp.enabled: true` |
| EtherNet/IP | 44818 | `protocols.ethernetIp.enabled: true` |
| BACnet | 47808 | `protocols.bacnet.enabled: true` |
| Gateway | 11740 | `gateway.enabled: true` |
| Metrics | 9100 | `monitoring.prometheus.enabled: true` |

## 🛠️ Common Issues

| Problem | Solution |
|---------|----------|
| Pod stuck in Pending | Check PVC status: `kubectl get pvc -n industrial` |
| Pod CrashLoopBackOff | Check logs: `kubectl logs <POD> --previous` |
| Can't access HMI | Port forward: `kubectl port-forward svc/codesys-targetvisu 8080:8080` |
| License error | Verify secret: `kubectl get secret codesys-license -o yaml` |
| High memory usage | Increase limits in values.yaml or reduce max clients |
| Slow performance | Check node resources: `kubectl top nodes` |

## 📁 File Locations (in Pod)

| Path | Contents |
|------|----------|
| `/opt/codesys` | Application binaries |
| `/var/opt/codesys` | Configuration & license |
| `/projects` | HMI projects |
| `/var/log/codesys` | Runtime logs |
| `/etc/codesys` | Custom config files |

---

**Made with 💀 by Fireball Industries**

*"Quick reference for when your HMI crashes at 3 AM and you can't remember anything."*
