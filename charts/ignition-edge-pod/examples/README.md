# Ignition Edge Example Configurations

This directory contains 6 ready-to-use example configurations for common deployment scenarios.

## Quick Start

Deploy any example with:
```powershell
helm install ignition-edge . -f examples/<example-file>.yaml
```

---

## Examples Overview

### 1. demo-ignition.yaml
**Perfect for:** Quick testing and evaluation

- Minimal resource usage
- Demo mode (no license required)
- Edge Panel preset
- Single PostgreSQL connection
- Sample project included

**Deploy:**
```powershell
helm install ignition-demo . -f examples/demo-ignition.yaml
```

---

### 2. factory-hmi.yaml
**Perfect for:** Operator interface panels on factory floor

- Edge Panel edition (Vision runtime only)
- Standard preset
- PostgreSQL backend
- OPC UA client to PLCs
- Alarm notifications enabled
- No designer access (runtime only)

**Deploy:**
```powershell
helm install factory-hmi . -f examples/factory-hmi.yaml
```

---

### 3. edge-gateway-historian.yaml
**Perfect for:** Edge data collection with local historian

- Edge Gateway edition
- MQTT Sparkplug B enabled
- TimescaleDB tag historian
- OPC UA server for PLCs
- Store-and-forward to central gateway
- 7-day local historian retention

**Deploy:**
```powershell
helm install edge-gateway . -f examples/edge-gateway-historian.yaml
```

---

### 4. production-scada.yaml
**Perfect for:** Full production SCADA system

- Edge Compute edition
- Full designer access
- High availability (active/standby)
- PostgreSQL + TimescaleDB
- OPC UA + MQTT protocols
- Enterprise preset
- 50+ device connections supported
- Automated backups

**Deploy:**
```powershell
helm install scada-system . -f examples/production-scada.yaml
```

---

### 5. remote-edge.yaml
**Perfect for:** Resource-constrained edge sites

- Edge Gateway preset
- Minimal modules
- Local 7-day historian
- Forward to central every hour
- Low CPU/memory footprint
- Optimized for unreliable network connectivity

**Deploy:**
```powershell
helm install remote-edge . -f examples/remote-edge.yaml
```

---

### 6. mes-integration.yaml
**Perfect for:** Manufacturing Execution System integration

- Edge Compute edition
- MES database connections
- Transaction groups for production data
- Reporting module enabled
- Shift scheduling integration
- Enterprise preset
- Compliance-ready (21 CFR Part 11)

**Deploy:**
```powershell
helm install mes-gateway . -f examples/mes-integration.yaml
```

---

## Customizing Examples

1. Copy an example file:
   ```powershell
   Copy-Item examples/factory-hmi.yaml my-custom-values.yaml
   ```

2. Edit for your environment:
   ```yaml
   gateway:
     name: "My Custom Gateway"
   
   databases:
     postgresql:
       host: "my-postgres.example.com"
       password: "my-password"
   ```

3. Deploy:
   ```powershell
   helm install my-gateway . -f my-custom-values.yaml
   ```

---

## Comparison Matrix

| Feature | Demo | Factory HMI | Edge Gateway | Production SCADA | Remote Edge | MES |
|---------|------|-------------|--------------|------------------|-------------|-----|
| **License** | Demo | Production | Production | Production | Production | Production |
| **Edition** | Panel | Panel | Gateway | Compute | Gateway | Compute |
| **CPU** | 1 | 2 | 2 | 4 | 1 | 8 |
| **RAM** | 2 GiB | 4 GiB | 4 GiB | 16 GiB | 2 GiB | 32 GiB |
| **Designer** | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ |
| **OPC UA Server** | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| **MQTT** | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| **Historian** | ❌ | ❌ | ✅ | ✅ | ✅ (7d) | ✅ (90d) |
| **HA** | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ |
| **Backup** | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Use Case** | Testing | HMI Panel | Edge IoT | Production | Remote Site | Enterprise MES |

---

## Next Steps

After deployment:

1. **Access gateway:**
   ```powershell
   kubectl port-forward svc/your-release-name 8088:8088
   ```

2. **Get admin password:**
   ```powershell
   kubectl get secret your-release-name-secret \
     -o jsonpath='{.data.admin-password}' | base64 -d
   ```

3. **Activate license** (except demo):
   ```powershell
   .\scripts\manage-ignition.ps1 -Action activate-license -ActivationKey "YOUR-KEY"
   ```

4. **Configure devices and tags via web UI**

5. **Import your Ignition projects**

---

## Support

Questions? Check the main [README.md](../README.md) or open an issue.
