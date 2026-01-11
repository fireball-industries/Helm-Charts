# CODESYS TargetVisu - Troubleshooting Guide

Common issues and solutions for CODESYS TargetVisu on Kubernetes.

## 🚨 Pod Issues

### Pod Stuck in Pending

**Symptoms:**
- Pod status shows "Pending" for more than 2 minutes
- HMI not accessible

**Diagnosis:**
```bash
kubectl describe pod -n industrial <POD-NAME>
kubectl get pvc -n industrial
kubectl get events -n industrial
```

**Solutions:**

1. **Storage not available:**
   ```bash
   # Check PVC status
   kubectl get pvc -n industrial
   
   # If PVC is Pending, check storage class
   kubectl get sc
   
   # Create storage class if missing (K3s local-path example)
   kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
   ```

2. **Insufficient resources:**
   ```bash
   # Check node resources
   kubectl top nodes
   kubectl describe nodes
   
   # Reduce resource requests in values.yaml
   resources:
     requests:
       cpu: 500m
       memory: 512Mi
   ```

3. **Node selector mismatch:**
   ```yaml
   # Remove or adjust node selector
   nodeSelector: {}
   ```

### Pod CrashLoopBackOff

**Symptoms:**
- Pod repeatedly restarting
- Status shows "CrashLoopBackOff"

**Diagnosis:**
```bash
# View current logs
kubectl logs -n industrial <POD-NAME>

# View previous logs
kubectl logs -n industrial <POD-NAME> --previous

# Check events
kubectl get events -n industrial --sort-by='.lastTimestamp'
```

**Common Causes:**

1. **Missing license:**
   ```bash
   # Check license secret exists
   kubectl get secret -n industrial codesys-license
   
   # Verify license file in pod
   kubectl exec -n industrial <POD-NAME> -- ls -la /var/opt/codesys/license/
   
   # Recreate license secret
   kubectl delete secret -n industrial codesys-license
   kubectl create secret generic codesys-license --from-file=license.lic=./license.lic -n industrial
   
   # Restart pod
   kubectl delete pod -n industrial <POD-NAME>
   ```

2. **Configuration error:**
   ```bash
   # Check ConfigMap
   kubectl get configmap -n industrial
   
   # View config
   kubectl describe configmap -n industrial <CONFIGMAP-NAME>
   
   # Edit values.yaml and upgrade
   helm upgrade codesys-targetvisu . -n industrial --values values.yaml
   ```

3. **Permission issues:**
   ```yaml
   # Adjust security context in values.yaml
   security:
     podSecurityContext:
       runAsNonRoot: false
       fsGroup: 1000
   ```

### Pod OOMKilled (Out of Memory)

**Symptoms:**
- Pod status shows "OOMKilled"
- Frequent restarts

**Solutions:**
```yaml
# Increase memory limits in values.yaml
resources:
  limits:
    memory: 4Gi  # Increase from 2Gi

# Or use industrial preset
resourcePreset: industrial
```

```bash
# Apply changes
helm upgrade codesys-targetvisu . -n industrial --values values.yaml
```

## 🌐 Network Issues

### Cannot Access HMI Web Interface

**Diagnosis:**
```bash
# Check service
kubectl get svc -n industrial codesys-targetvisu

# Check if pod is running
kubectl get pods -n industrial

# Test from within cluster
kubectl run -it --rm debug --image=busybox --restart=Never -n industrial -- wget -O- http://codesys-targetvisu:8080
```

**Solutions:**

1. **NodePort not accessible:**
   ```bash
   # Get node IP
   kubectl get nodes -o wide
   
   # Get NodePort
   kubectl get svc -n industrial codesys-targetvisu
   
   # Check firewall (if on cloud provider)
   # Allow inbound traffic on NodePort (e.g., 30080)
   ```

2. **Ingress not working:**
   ```bash
   # Check Ingress resource
   kubectl get ingress -n industrial
   kubectl describe ingress -n industrial codesys-targetvisu
   
   # Check Ingress controller
   kubectl get pods -n ingress-nginx
   
   # Test Ingress controller
   kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80
   ```

3. **Use port-forward as workaround:**
   ```bash
   kubectl port-forward -n industrial svc/codesys-targetvisu 8080:8080
   # Access at http://localhost:8080
   ```

### Slow Web Interface

**Symptoms:**
- Page load times > 5 seconds
- Timeouts

**Solutions:**

1. **Check pod resources:**
   ```bash
   kubectl top pod -n industrial
   
   # If CPU/memory high, increase limits
   ```

2. **Check network latency:**
   ```bash
   # Test from pod
   kubectl exec -n industrial <POD-NAME> -- ping 8.8.8.8
   ```

3. **Enable compression:**
   ```yaml
   targetvisu:
     web:
       compression: true
   ```

4. **Reduce max clients:**
   ```yaml
   targetvisu:
     web:
       maxClients: 5  # Reduce from 10
   ```

## 📜 License Issues

### License Not Found

**Symptoms:**
- HMI shows "No valid license" error
- Pod logs show license error

**Solutions:**
```bash
# 1. Verify license secret exists
kubectl get secret -n industrial codesys-license

# 2. Check secret contents
kubectl get secret -n industrial codesys-license -o yaml

# 3. Verify license file in pod
kubectl exec -n industrial <POD-NAME> -- cat /var/opt/codesys/license/license.lic

# 4. Recreate secret
kubectl delete secret -n industrial codesys-license
kubectl create secret generic codesys-license \
  --from-file=license.lic=./your-license.lic \
  -n industrial

# 5. Restart deployment
kubectl rollout restart deployment/codesys-targetvisu -n industrial
```

### License Server Unreachable

**Symptoms:**
- Cannot connect to license server
- Error: "License server timeout"

**Solutions:**
```bash
# Test connectivity from pod
kubectl exec -n industrial <POD-NAME> -- nc -zv license.example.com 1947

# Check DNS resolution
kubectl exec -n industrial <POD-NAME> -- nslookup license.example.com

# Check network policy
kubectl get networkpolicy -n industrial
```

## 💾 Storage Issues

### PVC Stuck in Pending

**Diagnosis:**
```bash
kubectl describe pvc -n industrial codesys-targetvisu-config
kubectl get sc
```

**Solutions:**

1. **No storage class:**
   ```bash
   # Install local-path provisioner (K3s)
   kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
   ```

2. **Specify storage class:**
   ```yaml
   storage:
     config:
       storageClass: "local-path"  # or your storage class name
   ```

### Disk Full

**Symptoms:**
- Pod crashes
- "No space left on device" errors

**Solutions:**
```bash
# Check PVC usage
kubectl exec -n industrial <POD-NAME> -- df -h

# Increase PVC size (if supported by storage class)
kubectl edit pvc -n industrial codesys-targetvisu-logs

# Or update values.yaml
storage:
  logs:
    size: 5Gi  # Increase from 2Gi

# Clean up old logs
kubectl exec -n industrial <POD-NAME> -- find /var/log/codesys -name "*.log.*" -mtime +7 -delete
```

## 🔌 Protocol Issues

### OPC UA Connection Fails

**Symptoms:**
- OPC UA clients cannot connect
- Port 4840 not accessible

**Solutions:**

1. **Verify OPC UA is enabled:**
   ```yaml
   protocols:
     opcua:
       enabled: true
   ```

2. **Check port is listening:**
   ```bash
   kubectl exec -n industrial <POD-NAME> -- netstat -tuln | grep 4840
   ```

3. **Security policy mismatch:**
   ```yaml
   protocols:
     opcua:
       security:
         mode: None  # Try without security first
   ```

4. **Firewall/Network Policy:**
   ```bash
   # Check if port is exposed in service
   kubectl get svc -n industrial codesys-targetvisu -o yaml
   ```

### Modbus TCP Not Working

**Symptoms:**
- Modbus clients cannot connect
- Port 502 errors

**Solutions:**

1. **Port 502 requires privileges:**
   ```yaml
   security:
     containerSecurityContext:
       capabilities:
         add:
           - NET_BIND_SERVICE
   ```

2. **Use hostNetwork for direct access:**
   ```yaml
   hostNetwork: true
   dnsPolicy: ClusterFirstWithHostNet
   ```

3. **Verify Modbus enabled:**
   ```yaml
   protocols:
     modbusTcp:
       enabled: true
       port: 502
   ```

## 🔐 Authentication Issues

### Cannot Login to HMI

**Symptoms:**
- Login fails with correct credentials
- "Access denied" errors

**Solutions:**

1. **Check user secrets exist:**
   ```bash
   kubectl get secret -n industrial codesys-admin-password
   kubectl get secret -n industrial codesys-admin-password -o yaml
   ```

2. **Reset password:**
   ```bash
   kubectl delete secret -n industrial codesys-admin-password
   kubectl create secret generic codesys-admin-password \
     --from-literal=password='NewPassword123' \
     -n industrial
   
   kubectl rollout restart deployment/codesys-targetvisu -n industrial
   ```

3. **Disable authentication temporarily:**
   ```yaml
   security:
     authentication:
       enabled: false
   ```

## 📊 Performance Issues

### High CPU Usage

**Diagnosis:**
```bash
kubectl top pod -n industrial
kubectl exec -n industrial <POD-NAME> -- top -b -n 1
```

**Solutions:**

1. **Increase CPU limits:**
   ```yaml
   resources:
     limits:
       cpu: 4000m
   ```

2. **Use industrial preset:**
   ```yaml
   resourcePreset: industrial
   ```

3. **Optimize HMI project:**
   - Reduce update frequency
   - Simplify graphics
   - Limit trend history

### High Memory Usage

**Solutions:**
```yaml
# Increase memory
resources:
  limits:
    memory: 4Gi

# Reduce max clients
targetvisu:
  web:
    maxClients: 5

# Reduce trend history
targetvisu:
  trends:
    historyDuration: 3600  # 1 hour instead of 24
```

## 🐛 Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| "License not found" | Missing/invalid license | Reinstall license secret |
| "Cannot bind to port 502" | Insufficient permissions | Add NET_BIND_SERVICE capability |
| "OOMKilled" | Out of memory | Increase memory limits |
| "CrashLoopBackOff" | Application crash | Check logs, verify configuration |
| "ImagePullBackOff" | Cannot pull image | Check image name, add pull secret |
| "Pending" | Resource constraints | Check storage, node resources |
| "Connection refused" | Service not ready | Wait for pod to become ready |

## 🆘 Emergency Procedures

### Complete Reset

```bash
# 1. Delete deployment
helm uninstall codesys-targetvisu -n industrial

# 2. Delete PVCs (WARNING: Deletes all data!)
kubectl delete pvc -n industrial -l app.kubernetes.io/instance=codesys-targetvisu

# 3. Delete secrets
kubectl delete secret -n industrial codesys-license

# 4. Redeploy
helm install codesys-targetvisu . -n industrial --values values.yaml
```

### Backup Before Troubleshooting

```powershell
# Always backup before major changes
.\scripts\manage-targetvisu.ps1 -Action backup -BackupPath C:\backups\before-fix
```

## 📞 Getting Help

1. **Check pod logs:**
   ```bash
   kubectl logs -n industrial <POD-NAME> --tail=100
   ```

2. **Run diagnostics:**
   ```powershell
   .\scripts\diagnostics.ps1
   ```

3. **Run tests:**
   ```powershell
   .\scripts\test-targetvisu.ps1 -TestType all
   ```

4. **Gather information:**
   ```bash
   kubectl get all -n industrial
   kubectl describe pod -n industrial <POD-NAME>
   kubectl get events -n industrial
   ```

5. **GitHub Issues:**
   - https://github.com/fireball-industries/codesys-targetvisu-pod/issues

---

**Made with 💀 by Fireball Industries**

*"When in doubt, restart the pod. If that doesn't work, restart the whole cluster. If that doesn't work, blame the PLC."*
