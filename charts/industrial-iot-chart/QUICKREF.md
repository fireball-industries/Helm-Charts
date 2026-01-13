# 🚀 Quick Reference Guide

**Home Assistant Helm Chart** - Fireball Industries - Patrick Ryan

---

## 📥 Installation

### Default (SQLite)
```bash
helm install home-assistant ./home-assistant-pod -n home-assistant --create-namespace
```

### Production (PostgreSQL)
```bash
helm install home-assistant ./home-assistant-pod \
  -n home-assistant --create-namespace \
  -f values-production.yaml
```

### K3s
```bash
helm install home-assistant ./home-assistant-pod \
  -n home-assistant --create-namespace \
  -f values-k3s.yaml
```

---

## 🔍 Status Check

```bash
# Check all resources
kubectl get all -n home-assistant

# Check pods
kubectl get pods -n home-assistant

# Check PVCs
kubectl get pvc -n home-assistant

# Check services
kubectl get svc -n home-assistant
```

---

## 📊 Logs

```bash
# Home Assistant logs
kubectl logs -n home-assistant home-assistant-0 -c home-assistant -f

# MQTT logs
kubectl logs -n home-assistant home-assistant-0 -c mqtt -f

# All containers
kubectl logs -n home-assistant home-assistant-0 --all-containers -f
```

---

## 🌐 Access

### Port Forward
```bash
# Home Assistant
kubectl port-forward -n home-assistant svc/home-assistant 8123:8123

# Node-RED
kubectl port-forward -n home-assistant svc/home-assistant 1880:1880

# ESPHome
kubectl port-forward -n home-assistant svc/home-assistant 6052:6052

# Zigbee2MQTT
kubectl port-forward -n home-assistant svc/home-assistant 8080:8080
```

### Get External IP (LoadBalancer)
```bash
kubectl get svc home-assistant -n home-assistant
```

### Get NodePort
```bash
kubectl get svc home-assistant -n home-assistant -o jsonpath='{.spec.ports[0].nodePort}'
```

---

## 🔧 Configuration

### Update Values
```bash
# Edit your values
nano my-values.yaml

# Upgrade
helm upgrade home-assistant ./home-assistant-pod \
  -n home-assistant \
  -f my-values.yaml
```

### Restart Pod
```bash
kubectl delete pod home-assistant-0 -n home-assistant
# StatefulSet will recreate it
```

---

## 💾 Backup

### Config Backup
```bash
kubectl exec -n home-assistant home-assistant-0 -- \
  tar czf /backups/config-$(date +%Y%m%d).tar.gz /config

kubectl cp home-assistant/home-assistant-0:/backups/config-20240111.tar.gz \
  ./backup.tar.gz
```

### Database Backup
```bash
kubectl exec -n home-assistant home-assistant-postgresql-0 -- \
  pg_dump -U homeassistant homeassistant | gzip > db-backup.sql.gz
```

---

## 🔄 Upgrade

```bash
# Update chart
git pull

# Upgrade
helm upgrade home-assistant ./home-assistant-pod \
  -n home-assistant \
  -f my-values.yaml

# Check rollout
kubectl rollout status statefulset/home-assistant -n home-assistant
```

---

## 🗑️ Uninstall

```bash
# Remove release
helm uninstall home-assistant -n home-assistant

# Delete PVCs (WARNING: Deletes all data!)
kubectl delete pvc -n home-assistant -l app.kubernetes.io/instance=home-assistant

# Delete namespace
kubectl delete namespace home-assistant
```

---

## 🐛 Troubleshooting

### Pod Not Starting
```bash
kubectl describe pod home-assistant-0 -n home-assistant
kubectl logs home-assistant-0 -n home-assistant
```

### PVC Issues
```bash
kubectl get pvc -n home-assistant
kubectl describe pvc home-assistant-config -n home-assistant
```

### Database Connection
```bash
kubectl exec -n home-assistant home-assistant-postgresql-0 -- \
  psql -U homeassistant -c "SELECT version();"
```

### MQTT Test
```bash
# Publish
kubectl exec -n home-assistant home-assistant-0 -c mqtt -- \
  mosquitto_pub -h localhost -t test -m "hello"

# Subscribe
kubectl exec -n home-assistant home-assistant-0 -c mqtt -- \
  mosquitto_sub -h localhost -t test -v
```

---

## 📖 Documentation

- **Full Documentation**: [README.md](README.md)
- **Installation Guide**: [INSTALL.md](INSTALL.md)
- **Architecture**: [ARCHITECTURE.md](ARCHITECTURE.md)
- **Project Summary**: [PROJECT-SUMMARY.md](PROJECT-SUMMARY.md)

---

## 🔐 Security Checklist

- [ ] Change all default passwords
- [ ] Configure TLS/SSL
- [ ] Enable 2FA in Home Assistant
- [ ] Set up automated backups
- [ ] Configure firewall rules
- [ ] Review network policies

---

## 🎯 Common Tasks

### Enable MQTT in Home Assistant
1. Settings > Devices & Services
2. Add Integration > MQTT
3. Broker: `localhost` or `home-assistant-mqtt`
4. Port: `1883`
5. Credentials from values.yaml

### Add Zigbee Device
1. Access Zigbee2MQTT web UI
2. Enable permit join
3. Pair device
4. Device auto-appears in Home Assistant

### Create Node-RED Flow
1. Access Node-RED web UI
2. Drag nodes from palette
3. Connect to Home Assistant API
4. Deploy flow

---

## 📊 Resource Usage

### Minimal (SQLite)
- CPU: 500m - 2000m
- Memory: 1Gi - 4Gi
- Storage: ~30GB

### Production (PostgreSQL)
- CPU: 1500m - 5000m
- Memory: 3Gi - 10Gi
- Storage: ~60GB

### All Add-ons Enabled
- CPU: 2000m - 8000m
- Memory: 4Gi - 16Gi
- Storage: ~80GB

---

## 🔗 Quick Links

- **Home Assistant**: http://localhost:8123 (after port-forward)
- **Node-RED**: http://localhost:1880
- **ESPHome**: http://localhost:6052
- **Zigbee2MQTT**: http://localhost:8080

---

## 🆘 Support

- **Issues**: https://github.com/fireballindustries/home-assistant-pod/issues
- **Email**: patrick@fireballindustries.com
- **Docs**: https://www.home-assistant.io/docs/

---

**Built with ☕ by Fireball Industries - Patrick Ryan**  
*"Your smart home is now more intelligent than your ex"*
