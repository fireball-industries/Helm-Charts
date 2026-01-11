# ============================================================================
# INSTALLATION GUIDE
# ============================================================================
# Fireball Industries - Patrick Ryan
# Quick reference for deploying Home Assistant with this Helm chart
# ============================================================================

## Prerequisites

1. Kubernetes/K3s cluster (v1.21+)
2. Helm 3.0+
3. kubectl configured
4. Storage provisioner (local-path, Longhorn, NFS, etc.)

## Quick Start

### Option 1: Basic Installation (SQLite)

```bash
# Create namespace
kubectl create namespace home-assistant

# Install with defaults
helm install home-assistant ./home-assistant-pod \
  --namespace home-assistant

# Wait for pod to be ready
kubectl get pods -n home-assistant -w

# Access via port-forward
kubectl port-forward -n home-assistant svc/home-assistant 8123:8123

# Open http://localhost:8123
```

### Option 2: Production Installation (PostgreSQL)

```bash
# Copy and edit production values
cp values-production.yaml my-values.yaml
nano my-values.yaml  # Edit passwords, domain, storage class

# Install with production values
helm install home-assistant ./home-assistant-pod \
  --namespace home-assistant \
  --create-namespace \
  --values my-values.yaml

# Check deployment
kubectl get all -n home-assistant
```

### Option 3: K3s Single Node

```bash
# Use K3s-optimized values
helm install home-assistant ./home-assistant-pod \
  --namespace home-assistant \
  --create-namespace \
  --values values-k3s.yaml

# Access via NodePort
# http://<node-ip>:30123
```

## Post-Installation

### 1. Access Home Assistant

**LoadBalancer:**
```bash
kubectl get svc home-assistant -n home-assistant
# Use EXTERNAL-IP shown
```

**NodePort:**
```bash
kubectl get nodes -o wide
# Use any node IP with port 30123 (or your configured nodePort)
```

**ClusterIP (port-forward):**
```bash
kubectl port-forward -n home-assistant svc/home-assistant 8123:8123
# Open http://localhost:8123
```

### 2. Complete Onboarding

1. Open Home Assistant in browser
2. Create admin account (first user = owner)
3. Set location and timezone
4. Start adding integrations

### 3. Configure MQTT (if enabled)

```bash
# Get MQTT password from values.yaml or secret
kubectl get secret home-assistant-mqtt -n home-assistant -o jsonpath='{.data.password}' | base64 -d

# In Home Assistant UI:
# Settings > Devices & Services > Add Integration > MQTT
# Broker: localhost (if sidecar) or home-assistant-mqtt
# Port: 1883
# Username: mqtt
# Password: (from above)
```

### 4. Access Add-ons

**Node-RED:**
```bash
kubectl port-forward -n home-assistant svc/home-assistant 1880:1880
# Open http://localhost:1880
```

**ESPHome:**
```bash
kubectl port-forward -n home-assistant svc/home-assistant 6052:6052
# Open http://localhost:6052
```

**Zigbee2MQTT:**
```bash
kubectl port-forward -n home-assistant svc/home-assistant 8080:8080
# Open http://localhost:8080
```

## Upgrading

```bash
# Pull latest chart
git pull origin main

# Upgrade release
helm upgrade home-assistant ./home-assistant-pod \
  --namespace home-assistant \
  --values my-values.yaml

# Check status
kubectl rollout status statefulset/home-assistant -n home-assistant
```

## Backup and Restore

### Backup

```bash
# Backup config
kubectl exec -n home-assistant home-assistant-0 -- \
  tar czf /backups/config-$(date +%Y%m%d-%H%M%S).tar.gz /config

# Copy to local
kubectl cp home-assistant/home-assistant-0:/backups/config-20240111-120000.tar.gz \
  ./ha-backup.tar.gz

# Backup database (if PostgreSQL)
kubectl exec -n home-assistant home-assistant-postgresql-0 -- \
  pg_dump -U homeassistant homeassistant | gzip > ha-db-backup.sql.gz
```

### Restore

```bash
# Copy backup to pod
kubectl cp ./ha-backup.tar.gz \
  home-assistant/home-assistant-0:/tmp/backup.tar.gz

# Restore
kubectl exec -n home-assistant home-assistant-0 -- \
  tar xzf /tmp/backup.tar.gz -C /

# Restart pod
kubectl delete pod home-assistant-0 -n home-assistant
```

## Troubleshooting

### Pod not starting

```bash
# Check pod status
kubectl get pods -n home-assistant
kubectl describe pod home-assistant-0 -n home-assistant
kubectl logs -n home-assistant home-assistant-0

# Common issues:
# - PVC not binding: Check storage class and PV availability
# - Image pull error: Check image tag and registry
# - Crash loop: Check logs for configuration errors
```

### PVC issues

```bash
# Check PVC status
kubectl get pvc -n home-assistant
kubectl describe pvc home-assistant-config -n home-assistant

# Check available PVs
kubectl get pv

# If using local-path, ensure provisioner is running
kubectl get pods -n kube-system | grep local-path
```

### Database connection issues

```bash
# Test PostgreSQL connection
kubectl exec -n home-assistant home-assistant-postgresql-0 -- \
  psql -U homeassistant -c "SELECT version();"

# Check PostgreSQL logs
kubectl logs -n home-assistant home-assistant-postgresql-0
```

### MQTT not working

```bash
# Check MQTT logs
kubectl logs -n home-assistant home-assistant-0 -c mqtt

# Test MQTT connection
kubectl exec -n home-assistant home-assistant-0 -c mqtt -- \
  mosquitto_pub -h localhost -t test -m "hello"

kubectl exec -n home-assistant home-assistant-0 -c mqtt -- \
  mosquitto_sub -h localhost -t test -v
```

## Uninstall

```bash
# Delete Helm release
helm uninstall home-assistant -n home-assistant

# Delete PVCs (WARNING: This deletes all data!)
kubectl delete pvc -n home-assistant -l app.kubernetes.io/instance=home-assistant

# Delete namespace
kubectl delete namespace home-assistant
```

## Security Checklist

- [ ] Changed all default passwords
- [ ] Configured TLS/SSL for external access
- [ ] Enabled 2FA in Home Assistant
- [ ] Set up automated backups
- [ ] Network policies configured (if needed)
- [ ] Firewall rules configured
- [ ] Regular updates scheduled
- [ ] Monitoring and alerting configured

## Support

- Documentation: README.md
- Issues: https://github.com/fireballindustries/home-assistant-pod/issues
- Home Assistant Docs: https://www.home-assistant.io/docs/

---

Built with ☕ by Fireball Industries - Patrick Ryan
