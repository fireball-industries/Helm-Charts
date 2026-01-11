# InfluxDB Pod - Quick Reference

**Fireball Industries** - *"Ignite Your Factory Efficiency"™*

## 🚀 Quick Install

```bash
# Basic install
helm install influxdb ./influxdb-pod --set influxdb.organization=my-factory

# Production HA
helm install influxdb ./influxdb-pod -f examples/ha-influxdb.yaml

# Edge deployment
helm install influxdb-edge ./influxdb-pod -f examples/edge-gateway.yaml
```

## 🔑 Get Admin Token

```bash
kubectl get secret influxdb-influxdb-pod-auth -n influxdb \
  -o jsonpath='{.data.admin-token}' | base64 --decode
```

## 🌐 Access UI

```bash
# Port-forward
kubectl port-forward -n influxdb svc/influxdb-influxdb-pod 8086:8086

# Open: http://localhost:8086
```

## 📊 Resource Presets

| Preset | Sensors | RAM | CPU | Storage | Use Case |
|--------|---------|-----|-----|---------|----------|
| edge | <5 | 256Mi | 0.5 | 5Gi | Remote sites |
| small | <10 | 512Mi | 1 | 10Gi | Small factory |
| medium | <100 | 2Gi | 2 | 50Gi | Medium factory (default) |
| large | <1K | 8Gi | 4 | 200Gi | Large factory |
| xlarge | >1K | 16Gi | 8 | 500Gi | Enterprise |

## 🪣 Default Buckets

- **sensors** (90d) - Raw sensor data
- **scada** (365d) - SCADA metrics
- **production** (730d) - Production metrics
- **energy** (2555d) - Energy consumption
- **quality** (2555d) - Quality control
- **_monitoring** (30d) - System health

## 📝 Common Commands

### Write Data
```bash
influx write \
  --bucket sensors \
  --org my-factory \
  --token <TOKEN> \
  --precision s \
  "temperature,sensor=TT01 value=23.5"
```

### Query Data
```bash
influx query --org my-factory --token <TOKEN> \
  'from(bucket: "sensors") |> range(start: -1h)'
```

### Create Bucket
```bash
influx bucket create \
  --name maintenance \
  --org my-factory \
  --retention 365d \
  --token <TOKEN>
```

### Create Read-Only Token
```bash
influx auth create \
  --org my-factory \
  --read-bucket sensors \
  --description "Grafana dashboard" \
  --token <ADMIN_TOKEN>
```

### Backup
```bash
influx backup /backup/influxdb-$(date +%Y%m%d) \
  --host http://influxdb:8086 \
  --token <TOKEN>
```

## 🛠️ PowerShell Scripts

```powershell
# Deploy
.\scripts\manage-influxdb.ps1 -Action deploy -Organization "my-factory"

# Health check
.\scripts\manage-influxdb.ps1 -Action health-check

# Test all
.\scripts\test-influxdb.ps1 -TestType all

# Generate config
.\scripts\generate-config.ps1 -Scenario factory -SensorCount 100
```

## 🔍 Troubleshooting

### Check Pod Status
```bash
kubectl get pods -n influxdb -l app.kubernetes.io/name=influxdb-pod
```

### View Logs
```bash
kubectl logs -n influxdb -l app.kubernetes.io/name=influxdb-pod --tail=100
```

### Test Health
```bash
kubectl exec -n influxdb <pod-name> -- curl http://localhost:8086/health
```

### Check Storage
```bash
kubectl get pvc -n influxdb
kubectl exec -n influxdb <pod-name> -- df -h
```

## ⚙️ Key Configuration

```yaml
# Deployment mode
deploymentMode: single  # or ha

# Resource sizing
resourcePreset: medium  # edge, small, medium, large, xlarge, custom

# Organization
influxdb:
  organization: "my-factory"
  bucket: "sensors"
  retention: "90d"

# HA clustering
highAvailability:
  replicas: 3
  antiAffinity: soft

# Backups
backup:
  enabled: true
  schedule: "0 2 * * *"

# Ingress
ingress:
  enabled: true
  hosts:
    - host: influxdb.factory.local
```

## 🔐 Security Checklist

- [ ] Change default admin token
- [ ] Enable TLS/HTTPS
- [ ] Configure network policies
- [ ] Enable backups
- [ ] Use read-only tokens for dashboards
- [ ] Use write-only tokens for data collectors
- [ ] Rotate tokens every 90 days
- [ ] Enable audit logging

## 📚 Documentation

- **Full Docs**: [docs/README.md](docs/README.md)
- **Security**: [docs/SECURITY.md](docs/SECURITY.md)
- **Examples**: [examples/](examples/)

## 🆘 Support

- **GitHub**: https://github.com/fireball-industries/influxdb-pod
- **Issues**: https://github.com/fireball-industries/influxdb-pod/issues
- **Email**: support@fireballindustries.com

---

**Fireball Industries** - *"One-page cheat sheets save lives"*
