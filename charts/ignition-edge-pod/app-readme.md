# Ignition Edge - Industrial IoT SCADA/HMI Gateway

**Production-ready Ignition Edge for Kubernetes/K3s - The industrial automation platform that doesn't crash during production runs.**

Because your operators deserve better than a Windows XP touchscreen running FactoryTalk from 2005.

---

## 🔥 What is Ignition Edge?

**Ignition Edge** is Inductive Automation's lightweight SCADA/HMI/IIoT platform designed for edge deployments:

- **Industrial Protocols**: OPC UA, MQTT Sparkplug B, Modbus, Allen-Bradley, Siemens, BACnet, DNP3
- **Tag Historian**: Time-series database for production metrics and trending
- **Vision & Perspective**: Modern HMI interfaces (no more 1990s-era VGA graphics)
- **Gateway Network**: Connect edge gateways to central SCADA systems
- **Store & Forward**: Never lose data during network outages
- **Scripting**: Python scripting for custom automation logic

**Perfect for:** Factory HMI panels, remote site monitoring, IoT data collection, machine integration, production dashboards.

---

## ⚠️ Demo Mode vs. Licensed Mode

### Demo Mode (Default)
- ✅ **No license required** - Runs immediately
- ✅ **Full functionality** - All features available
- ⚠️ **2-hour sessions** - Gateway auto-restarts every 2 hours
- ❌ **Not for production** - Data loss during restarts

**Demo mode is perfect for:**
- Proof-of-concept deployments
- Development and testing
- Training and demonstrations
- "Can I get approval for the license?" trials

---

### Licensed Mode (Production)
- ✅ **Continuous operation** - No restarts
- ✅ **Production-ready** - 24/7 uptime
- ✅ **Support available** - Inductive Automation support
- 💰 **Requires license** - Purchase from Inductive Automation

**Get a license:** https://inductiveautomation.com/ignition/edge

**Three editions available:**
- **Edge Panel** ($0/year with valid Ignition license) - Vision HMI runtime only
- **Edge Gateway** ($500/year) - OPC UA + MQTT + Historian (no designer access)
- **Edge Compute** ($2,500/year) - Full gateway with designer access

---

## 📊 Resource Presets

Choose a preset that matches your deployment:

| Preset | CPU | RAM | Storage | Use Case | JVM Heap |
|--------|-----|-----|---------|----------|----------|
| **edge-panel** | 1-2 | 2-4 GiB | 10 GiB | HMI touchscreen panels | 1-2 GiB |
| **edge-gateway** | 2-4 | 4-8 GiB | 20 GiB | IoT data collection | 2-4 GiB |
| **edge-compute** | 4-8 | 8-16 GiB | 50 GiB | Standalone SCADA site | 4-8 GiB |
| **standard** | 4-8 | 16-32 GiB | 100 GiB | Production SCADA | 8-16 GiB |
| **enterprise** | 8-16 | 32-64 GiB | 200 GiB | Enterprise MES | 16-32 GiB |

**Recommendation:**
- Start with **edge-gateway** for most deployments
- Use **edge-panel** for HMI-only touchscreens
- Upgrade to **standard** for high-tag-count SCADA systems
- Choose **enterprise** for MES integration with thousands of tags

---

## 🚀 Quick Start

### Minimal Demo Deployment
Deploy Ignition Edge in demo mode (2-hour sessions):

```powershell
helm upgrade --install ignition fireball-industries/ignition-edge-pod \
  --namespace industrial \
  --create-namespace \
  --set global.preset=edge-gateway \
  --set global.demoMode=true
```

**Access the gateway:**
```powershell
kubectl port-forward -n industrial svc/ignition-edge 8088:8088
```

Open browser to **http://localhost:8088**

**Get admin password:**
```powershell
kubectl get secret ignition-edge-secret -n industrial -o jsonpath="{.data.admin-password}" | base64 -d
```

---

### Production Deployment with License
Deploy Ignition Edge with activation key (continuous operation):

```powershell
helm upgrade --install ignition fireball-industries/ignition-edge-pod \
  --namespace industrial \
  --create-namespace \
  --set global.preset=standard \
  --set global.demoMode=false \
  --set license.activationKey="YOUR-ACTIVATION-KEY"
```

---

## 🏭 Ignition Editions Explained

### Edge Panel
**Best for:** Operator HMI touchscreens, read-only dashboards

**Included:**
- ✅ Vision runtime (display HMI projects)
- ✅ Tag browsing
- ❌ No OPC UA server
- ❌ No MQTT
- ❌ No designer access
- ❌ No tag historian

**Typical use case:** Floor-level touchscreen displaying production metrics from central gateway

---

### Edge Gateway
**Best for:** Remote sites, IoT data collection, protocol conversion

**Included:**
- ✅ OPC UA server (publish tags to PLCs/HMIs)
- ✅ MQTT Sparkplug B Engine + Transmission
- ✅ Tag historian (TimescaleDB integration)
- ✅ Gateway network (connect to central SCADA)
- ✅ Store & Forward (offline data buffering)
- ❌ No designer access (projects deployed from central)

**Typical use case:** Remote pump station collecting PLC data, publishing to central SCADA via MQTT

---

### Edge Compute
**Best for:** Standalone SCADA sites, independent facilities

**Included:**
- ✅ Everything in Edge Gateway
- ✅ Designer access (create/modify projects locally)
- ✅ Full gateway functionality
- ✅ Alarming and notification
- ✅ Reporting module

**Typical use case:** Small manufacturing plant with local SCADA development and operations

---

## 🔌 Industrial Protocol Configuration

### OPC UA Server
Enable OPC UA server to expose Ignition tags to PLCs, HMIs, and other OPC clients:

**Configuration:**
- **Port:** 62541 (standard OPC UA port)
- **Security Policies:** None, Basic256Sha256 (selectable)
- **Anonymous Access:** Disabled by default (enable for testing only)
- **Endpoint:** `opc.tcp://your-gateway:62541`

**Use cases:**
- Publish process values to Rockwell FactoryTalk
- Share tags with Siemens WinCC
- Feed data to third-party analytics platforms
- Connect multiple HMI clients

---

### MQTT Sparkplug B
Industry-standard MQTT for IIoT sensor networks:

#### MQTT Engine (Subscribe)
Receive data from IIoT sensors, PLCs with MQTT, field devices:

**Configuration:**
- **Broker:** External MQTT broker (Mosquitto, HiveMQ, AWS IoT Core)
- **Namespace:** Sparkplug B (spBv1.0)
- **Topics:** Auto-discovery of devices and tags
- **Store & Forward:** Buffer data during broker outages

**Topology:**
```
[Field Sensors] → [MQTT Broker] → [Ignition MQTT Engine] → [Tags/Historian]
```

---

#### MQTT Transmission (Publish)
Send Ignition data to central SCADA or cloud platforms:

**Configuration:**
- **Central Broker:** Enterprise MQTT broker or cloud service
- **Store & Forward:** Up to 100,000 messages buffered offline
- **Automatic Reconnect:** Seamless recovery from network outages

**Topology:**
```
[Ignition Edge] → [MQTT Transmission] → [Central MQTT] → [Enterprise SCADA]
```

**Why Store & Forward matters:**
Your remote pump station loses cellular connectivity for 4 hours. With Store & Forward enabled, all 14,400 data points (1-second intervals × 4 hours) are buffered locally and automatically transmitted when connectivity returns. Zero data loss. 🎉

---

### PLC Driver Support
Connect directly to PLCs (via OPC UA or native drivers):

**Allen-Bradley:**
- ControlLogix, CompactLogix, MicroLogix
- Via OPC UA or native driver
- Automatic tag discovery

**Siemens:**
- S7-1200, S7-1500, S7-300/400
- Via OPC UA or S7 driver
- Optimized DB access

**Modbus TCP:**
- Any Modbus TCP device (VFDs, meters, sensors)
- Configurable register mapping
- Multi-device support

**Other protocols:** BACnet/IP, DNP3, EtherNet/IP, Profinet (via modules)

---

## 💾 Database Integration

### PostgreSQL (Production Data)
Store alarm history, audit logs, production records:

**Configuration:**
- **Host:** PostgreSQL service name or IP
- **Database:** `ignition` (default)
- **Connection Pool:** 50 connections (configurable)
- **Auto-reconnect:** Automatic retry on connection loss

**Tables created:**
- Alarm events and acknowledgements
- Audit trail (user logins, project saves)
- Production counts and batch records
- Custom transaction groups

---

### TimescaleDB (Tag Historian)
Time-series database optimized for industrial IoT:

**Configuration:**
- **Host:** TimescaleDB service name or IP
- **Database:** `historian` (default)
- **Retention:** 90 days raw + 5 years aggregates (configurable)
- **Compression:** Automatic after 30 days (90% storage reduction)
- **Partitioning:** 7-day chunks for optimal query performance

**What gets stored:**
- Tag value changes (deadband filtering to reduce storage)
- Sample rate limiting (1-second minimum)
- Historical trending data
- Production metrics and KPIs

**Query performance:**
- Last 1 hour: < 0.1 seconds
- Last 24 hours: < 0.2 seconds
- Last 30 days: < 0.5 seconds

---

## 📈 Tag Historian Deep-Dive

### Storage Strategies

**Deadband Filtering:**
Only store tag values that change by more than X% (reduces storage by 70-90%):
- Temperature sensor: ±0.5°F deadband
- Pressure sensor: ±0.1 PSI deadband
- Boolean tags: On-change only

**Sample Rate Limiting:**
Prevent high-frequency tag updates from overwhelming the database:
- Fast tags (100ms scan): Sample at 1-second intervals for historian
- Medium tags (1s scan): Store all changes
- Slow tags (5s+ scan): Store all changes

---

### Retention Policies

**Default retention (configurable):**
- **Raw data:** 90 days (all tag changes)
- **Hourly aggregates:** 1 year (min/max/avg per hour)
- **Daily aggregates:** 5 years (min/max/avg per day)
- **Monthly aggregates:** 10 years (min/max/avg per month)

**Storage calculation example:**
- 1,000 tags at 1-second scan rate
- 90% reduction via deadband filtering
- 90% reduction via compression after 30 days
- **Result:** 10GB/month raw, 1GB/month after compression

---

### Historical Queries
Query historical data from Vision/Perspective HMIs:

**Easy Chart component:**
- Drag-and-drop historical pens
- Automatic aggregation for date ranges
- Export to CSV/Excel

**SQL queries:**
```sql
-- Last 24 hours of temperature averages (5-minute buckets)
SELECT time_bucket('5 minutes', time) AS bucket,
       AVG(value) AS avg_temp
FROM tag_history
WHERE tag_path = 'Reactor/Temperature'
  AND time > NOW() - INTERVAL '24 hours'
GROUP BY bucket;
```

---

## 💾 Backup & Restore

### Automated Daily Backups
Gateway backups include **everything** needed to restore operations:

**What's backed up:**
- ✅ All projects (Vision, Perspective)
- ✅ Gateway configuration
- ✅ Tag providers and tag configurations
- ✅ Database connections
- ✅ Alarm pipelines and notification profiles
- ✅ User accounts and security settings
- ✅ Installed modules

**Backup destinations:**
- **PVC:** Kubernetes persistent volume (default)
- **NFS:** Network file system (shared storage)
- **S3:** AWS S3, MinIO, or S3-compatible storage

**Backup schedule:**
- Default: 2 AM daily (configurable via cron)
- Retention: 30 days (configurable)
- Compression: gzip (reduces size by 70%+)

---

### Disaster Recovery
Restore gateway from backup in minutes:

**Scenario 1: Pod crashes**
Kubernetes automatically restarts the pod. Gateway data is preserved via persistent volume. **No action needed.**

**Scenario 2: Persistent volume corrupted**
1. Deploy new Ignition Edge instance
2. Restore latest backup via PowerShell script
3. Gateway operational in 5-10 minutes

**Scenario 3: Entire cluster lost**
1. Deploy Helm chart to new cluster
2. Restore backup from S3/NFS
3. Update database connection strings
4. Gateway operational in 15-30 minutes

---

### Manual Backup Operations
Use included PowerShell scripts for on-demand backups:

```powershell
# Create manual backup
.\scripts\manage-ignition.ps1 -Action backup

# List available backups
.\scripts\manage-ignition.ps1 -Action list-backups

# Restore specific backup
.\scripts\manage-ignition.ps1 -Action restore -BackupFile "gateway-2026-01-11.gwbk"

# Verify backup integrity
.\scripts\manage-ignition.ps1 -Action verify-backup -BackupFile "gateway-2026-01-11.gwbk"
```

---

## 🔒 Security & Authentication

### Internal Authentication (Default)
Gateway manages user accounts locally:

**Features:**
- Admin and user accounts
- Password policies (complexity, expiration)
- Session timeout configuration
- Role-based access control (RBAC)

---

### LDAP/Active Directory Integration
Integrate with enterprise identity systems:

**Configuration:**
- **LDAP Server:** Active Directory or OpenLDAP
- **Base DN:** `OU=Users,DC=example,DC=com`
- **Bind Account:** Service account for LDAP queries
- **Group Mapping:** AD groups → Ignition roles

**Benefits:**
- Single sign-on (SSO) for operators
- Centralized user management
- Automatic role assignment
- Password policy enforcement via AD

---

### SAML Single Sign-On
Integrate with enterprise SSO providers:

**Supported providers:**
- Okta
- Azure AD
- Ping Identity
- Generic SAML 2.0

**Benefits:**
- No password management
- Multi-factor authentication (MFA)
- Centralized access control

---

### TLS/SSL (HTTPS)
Encrypt gateway web traffic:

**Options:**
1. **Self-signed certificate** (auto-generated, testing only)
2. **Custom certificate** (from enterprise CA)
3. **Let's Encrypt** (via cert-manager ingress annotation)

**Configuration:**
- HTTPS Port: 8043
- HTTP → HTTPS redirect (configurable)
- TLS 1.2+ only (secure ciphers)

---

## 📊 Monitoring & Observability

### Prometheus Metrics
JMX exporter sidecar exposes comprehensive metrics:

**Gateway Metrics:**
- Active designer connections
- Active Vision clients
- Active Perspective sessions
- Tag counts and update rates
- Script execution times
- Alarm counts (active, unacknowledged)

**JVM Metrics:**
- Heap usage and GC statistics
- Thread counts and deadlocks
- CPU usage
- Garbage collection pauses

**Database Metrics:**
- Connection pool utilization
- Query execution times
- Failed connections

---

### Prometheus Alerts (Example)
```yaml
# Alert when demo mode is expiring soon
- alert: IgnitionDemoModeExpiring
  expr: ignition_demo_session_remaining_seconds < 600
  annotations:
    summary: "Demo mode expires in 10 minutes"
    description: "Gateway will restart. Activate license for production."

# Alert when heap usage is high
- alert: IgnitionHighMemoryUsage
  expr: jvm_memory_used_bytes{area="heap"} / jvm_memory_max_bytes{area="heap"} > 0.85
  annotations:
    summary: "JVM heap usage above 85%"
    description: "Consider increasing heap size or upgrading preset."
```

---

### Grafana Dashboards
Import pre-built dashboards for visualization:

**Ignition Overview Dashboard:**
- Gateway status and uptime
- Connection counts (designers, clients, sessions)
- Tag statistics (total, update rate, errors)
- Database connection health
- OPC UA server connections

**JVM Performance Dashboard:**
- Heap usage trends
- Garbage collection frequency
- Thread usage
- CPU utilization

---

## 🏗️ High Availability (Enterprise)

### Active/Standby Redundancy
Zero-downtime gateway operations:

**Architecture:**
- **Master Gateway:** Active, handling all requests
- **Backup Gateway:** Standby, ready for failover
- **Redis:** State synchronization between gateways
- **Automatic Failover:** < 30 seconds

**What's synchronized:**
- Tag values and states
- Alarm states
- Client sessions (Vision/Perspective)
- Database connections
- OPC UA connections

**Failover scenarios:**
1. Master gateway crashes → Backup promotes to master
2. Master pod evicted during node maintenance → Backup takes over
3. Manual failover for testing/upgrades

---

### Active/Active (Advanced)
Both gateways handle client requests:

**Benefits:**
- Load balancing across gateways
- Higher capacity (2× connections, tag counts)
- Even faster failover (clients already connected to both)

**Limitations:**
- Requires enterprise license
- More complex configuration
- Higher resource usage

---

## 🛠️ PowerShell Management Scripts

Included scripts for Windows environments:

### 1. `manage-ignition.ps1`
Complete lifecycle management:

```powershell
# Deploy gateway
.\scripts\manage-ignition.ps1 -Action deploy

# Health check
.\scripts\manage-ignition.ps1 -Action health-check

# View gateway logs
.\scripts\manage-ignition.ps1 -Action logs

# Restart gateway (extends demo mode session)
.\scripts\manage-ignition.ps1 -Action restart

# Activate license
.\scripts\manage-ignition.ps1 -Action activate-license -ActivationKey "YOUR-KEY"

# Backup gateway
.\scripts\manage-ignition.ps1 -Action backup

# Restore gateway
.\scripts\manage-ignition.ps1 -Action restore -BackupFile "gateway.gwbk"

# Upgrade gateway
.\scripts\manage-ignition.ps1 -Action upgrade -Version "8.1.25"
```

---

### 2. `test-ignition.ps1`
Comprehensive connectivity testing:

```powershell
.\scripts\test-ignition.ps1 -Namespace industrial -ReleaseName ignition-edge
```

**Tests performed:**
- ✅ HTTP/HTTPS web interface
- ✅ OPC UA server endpoint
- ✅ MQTT broker connections
- ✅ Database connectivity (PostgreSQL, TimescaleDB)
- ✅ Gateway network (if enabled)
- ✅ Prometheus metrics endpoint

---

## 📚 Example Configurations

Pre-built configurations in the `examples/` directory:

### 1. **demo-ignition.yaml**
Quick demo with minimal resources:
- Demo mode enabled (2-hour sessions)
- No persistence (ephemeral testing)
- No database connections
- No backups

---

### 2. **factory-hmi.yaml**
Operator touchscreen panel:
- Edge Panel edition
- Vision runtime only
- 2 GiB RAM, 10 GiB storage
- Reads tags from central gateway
- No historian or MQTT

---

### 3. **edge-gateway-historian.yaml**
Remote site data collection:
- Edge Gateway edition
- OPC UA + MQTT enabled
- TimescaleDB historian
- Store & Forward for offline buffering
- Daily automated backups to S3

---

### 4. **production-scada.yaml**
Full SCADA system:
- Edge Compute edition
- Designer access enabled
- PostgreSQL + TimescaleDB
- High Availability (active/standby)
- LDAP authentication
- Prometheus monitoring
- TLS/SSL enabled

---

## 🆘 Troubleshooting

### Gateway Won't Start
```powershell
# Check pod status
kubectl get pods -n industrial

# View pod events
kubectl describe pod ignition-edge-xxx -n industrial

# Check logs
kubectl logs -n industrial ignition-edge-xxx

# Common issues:
# - Insufficient memory (increase heap size or upgrade preset)
# - Database connection failure (check credentials and network)
# - License activation failure (verify activation key)
```

---

### Demo Mode Keeps Restarting
**This is normal.** Demo mode has 2-hour sessions and auto-restarts.

**Solutions:**
1. **Get a license** (recommended for production)
2. **Enable auto-restart** (extends demo sessions automatically):
   ```yaml
   license:
     demoModeRestart:
       enabled: true
   ```
3. **Manual restart** before expiry:
   ```powershell
   kubectl rollout restart deployment/ignition-edge -n industrial
   ```

---

### OPC UA Connection Refused
```powershell
# Check OPC UA server is enabled
kubectl get pod ignition-edge-xxx -n industrial -o yaml | grep -A 5 "opcua"

# Port-forward OPC UA port
kubectl port-forward -n industrial svc/ignition-edge 62541:62541

# Test connection with OPC UA client to localhost:62541

# Common issues:
# - OPC UA server disabled (enable in values.yaml)
# - Security policy mismatch (check client/server policies)
# - Certificate not trusted (add to client trusted certs)
```

---

### MQTT Connection Failures
```powershell
# Check MQTT broker connectivity from pod
kubectl exec -it ignition-edge-xxx -n industrial -- nc -zv mqtt-broker 1883

# View MQTT module logs
kubectl exec -it ignition-edge-xxx -n industrial -- tail -f /var/lib/ignition/logs/wrapper.log

# Common issues:
# - MQTT broker not accessible (check network/service)
# - Incorrect credentials (verify username/password)
# - TLS certificate mismatch (check broker certificate)
```

---

### Slow Gateway Performance
```powershell
# Check resource usage
kubectl top pod ignition-edge-xxx -n industrial

# View JVM heap usage
kubectl exec -it ignition-edge-xxx -n industrial -- cat /var/lib/ignition/logs/wrapper.log | grep "heap"

# Solutions:
# 1. Upgrade preset (edge-gateway → standard)
# 2. Increase JVM heap size
# 3. Reduce tag scan rates
# 4. Enable tag deadband filtering
# 5. Archive old historical data
```

---

## 🔗 Additional Resources

- **Ignition Documentation:** https://docs.inductiveautomation.com/
- **Edge Licensing:** https://inductiveautomation.com/ignition/edge
- **Inductive University:** https://inductiveuniversity.com/ (Free training)
- **Forum:** https://forum.inductiveautomation.com/
- **Chart Source:** https://github.com/fireball-industries/ignition-edge-pod

---

## 📝 License

Chart: MIT License - See LICENSE file for details.

**Ignition Software:** Separate licensing required from Inductive Automation.
- Demo mode: Free (2-hour sessions)
- Production: $500-$2,500/year depending on edition

---

## 🎓 Getting Started Checklist

**Before deployment:**
- [ ] Decide: Demo mode or licensed? (Demo = testing, Licensed = production)
- [ ] Choose preset: edge-panel / edge-gateway / edge-compute / standard / enterprise
- [ ] Select edition: Panel / Gateway / Compute
- [ ] Identify database servers: PostgreSQL (production data), TimescaleDB (historian)
- [ ] Identify MQTT brokers: Engine (inbound), Transmission (outbound)
- [ ] Plan backup strategy: PVC / NFS / S3

**After deployment:**
- [ ] Access web UI and complete setup wizard
- [ ] Activate license (if production)
- [ ] Configure database connections
- [ ] Configure OPC UA server (if needed)
- [ ] Configure MQTT Engine/Transmission (if needed)
- [ ] Create/import projects (Vision, Perspective)
- [ ] Configure tag providers and scan classes
- [ ] Enable tag historian
- [ ] Test backup and restore
- [ ] Configure monitoring (Prometheus/Grafana)
- [ ] Train operators on web UI

---

**Remember:** Demo mode is perfect for testing and proving value, but you'll need a license for continuous production operations. Don't let your SCADA system restart during critical runs. 🔥

*Pro tip:* Start with `edge-gateway` preset and demo mode. Once you've proven the value to management (they'll see the pretty dashboards and real-time data), request budget approval for the license. Then flip `demoMode: false` and activate your license key. Seamless transition to production. 🎉

**Happy SCADAing!** 🏭

---

*Created by Patrick Ryan - Fireball Industries*

*"Because your operators deserve better than Windows XP"*
