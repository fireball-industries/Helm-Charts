# Home Assistant Kubernetes Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                          KUBERNETES CLUSTER                                     │
│                                                                                 │
│  ┌───────────────────────────────────────────────────────────────────────────┐ │
│  │                         Namespace: home-assistant                         │ │
│  │                                                                           │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐     │ │
│  │  │                   StatefulSet: home-assistant                   │     │ │
│  │  │                                                                 │     │ │
│  │  │  Pod: home-assistant-0                                          │     │ │
│  │  │  ┌────────────────────────────────────────────────────────┐    │     │ │
│  │  │  │                                                        │    │     │ │
│  │  │  │  Container: home-assistant (PRIMARY)                   │    │     │ │
│  │  │  │  ├─ Image: ghcr.io/home-assistant/home-assistant      │    │     │ │
│  │  │  │  ├─ Port: 8123                                         │    │     │ │
│  │  │  │  ├─ Volume Mounts:                                     │    │     │ │
│  │  │  │  │  ├─ /config   (config PVC)                          │    │     │ │
│  │  │  │  │  ├─ /media    (media PVC)                           │    │     │ │
│  │  │  │  │  ├─ /share    (share PVC)                           │    │     │ │
│  │  │  │  │  └─ /backups  (backups PVC)                         │    │     │ │
│  │  │  │  └─ Probes: Startup, Liveness, Readiness              │    │     │ │
│  │  │  │                                                        │    │     │ │
│  │  │  ├────────────────────────────────────────────────────────┤    │     │ │
│  │  │  │                                                        │    │     │ │
│  │  │  │  Container: mqtt (SIDECAR)                             │    │     │ │
│  │  │  │  ├─ Image: eclipse-mosquitto:2.0                      │    │     │ │
│  │  │  │  ├─ Ports: 1883 (MQTT), 9001 (WebSocket)              │    │     │ │
│  │  │  │  └─ Volume Mounts: /mosquitto/data, /mosquitto/config │    │     │ │
│  │  │  │                                                        │    │     │ │
│  │  │  ├────────────────────────────────────────────────────────┤    │     │ │
│  │  │  │                                                        │    │     │ │
│  │  │  │  Container: nodered (SIDECAR)                          │    │     │ │
│  │  │  │  ├─ Image: nodered/node-red:3.1                       │    │     │ │
│  │  │  │  ├─ Port: 1880                                         │    │     │ │
│  │  │  │  └─ Volume Mounts: /data                              │    │     │ │
│  │  │  │                                                        │    │     │ │
│  │  │  ├────────────────────────────────────────────────────────┤    │     │ │
│  │  │  │                                                        │    │     │ │
│  │  │  │  Container: esphome (SIDECAR)                          │    │     │ │
│  │  │  │  ├─ Image: ghcr.io/esphome/esphome:2024.11           │    │     │ │
│  │  │  │  ├─ Port: 6052                                         │    │     │ │
│  │  │  │  └─ Volume Mounts: /config                            │    │     │ │
│  │  │  │                                                        │    │     │ │
│  │  │  ├────────────────────────────────────────────────────────┤    │     │ │
│  │  │  │                                                        │    │     │ │
│  │  │  │  Container: zigbee2mqtt (SIDECAR - Optional)           │    │     │ │
│  │  │  │  ├─ Image: koenkk/zigbee2mqtt:1.35                    │    │     │ │
│  │  │  │  ├─ Port: 8080                                         │    │     │ │
│  │  │  │  ├─ USB Device: /dev/ttyACM0 (hostPath)               │    │     │ │
│  │  │  │  └─ Volume Mounts: /app/data                          │    │     │ │
│  │  │  │                                                        │    │     │ │
│  │  │  └────────────────────────────────────────────────────────┘    │     │ │
│  │  └─────────────────────────────────────────────────────────────────┘     │ │
│  │                                                                           │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐     │ │
│  │  │         StatefulSet: home-assistant-postgresql (Optional)       │     │ │
│  │  │                                                                 │     │ │
│  │  │  Pod: home-assistant-postgresql-0                               │     │ │
│  │  │  ┌────────────────────────────────────────────────────────┐    │     │ │
│  │  │  │  Container: postgresql                                 │    │     │ │
│  │  │  │  ├─ Image: postgres:16-alpine                          │    │     │ │
│  │  │  │  ├─ Port: 5432                                         │    │     │ │
│  │  │  │  ├─ Database: homeassistant                            │    │     │ │
│  │  │  │  └─ Volume Mounts: /var/lib/postgresql/data           │    │     │ │
│  │  │  └────────────────────────────────────────────────────────┘    │     │ │
│  │  └─────────────────────────────────────────────────────────────────┘     │ │
│  │                                                                           │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐     │ │
│  │  │                     Persistent Volume Claims                    │     │ │
│  │  │                                                                 │     │ │
│  │  │  ├─ home-assistant-config-0    (10GB)  - Home Assistant config │     │ │
│  │  │  ├─ home-assistant-media-0     (20GB)  - Camera recordings     │     │ │
│  │  │  ├─ home-assistant-share-0     (5GB)   - Shared data           │     │ │
│  │  │  ├─ home-assistant-backups-0   (10GB)  - Backups               │     │ │
│  │  │  ├─ home-assistant-mqtt-data-0 (1GB)   - MQTT persistence      │     │ │
│  │  │  └─ postgresql-data-0          (5GB)   - PostgreSQL data       │     │ │
│  │  └─────────────────────────────────────────────────────────────────┘     │ │
│  │                                                                           │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐     │ │
│  │  │                            Services                              │     │ │
│  │  │                                                                 │     │ │
│  │  │  ├─ home-assistant (LoadBalancer/NodePort/ClusterIP)           │     │ │
│  │  │  │  └─ Port 8123 → home-assistant-0:8123                       │     │ │
│  │  │  │                                                              │     │ │
│  │  │  ├─ home-assistant-headless (ClusterIP None)                   │     │ │
│  │  │  │  └─ Stable DNS for StatefulSet                              │     │ │
│  │  │  │                                                              │     │ │
│  │  │  └─ home-assistant-postgresql (ClusterIP)                      │     │ │
│  │  │     └─ Port 5432 → postgresql-0:5432                           │     │ │
│  │  └─────────────────────────────────────────────────────────────────┘     │ │
│  │                                                                           │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐     │ │
│  │  │                     Ingress (Optional)                          │     │ │
│  │  │                                                                 │     │ │
│  │  │  home.example.com → home-assistant:8123                         │     │ │
│  │  │  └─ TLS: homeassistant-tls (cert-manager)                      │     │ │
│  │  └─────────────────────────────────────────────────────────────────┘     │ │
│  │                                                                           │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐     │ │
│  │  │                       Secrets & ConfigMaps                       │     │ │
│  │  │                                                                 │     │ │
│  │  │  Secrets:                                                       │     │ │
│  │  │  ├─ home-assistant-postgresql (PostgreSQL password)            │     │ │
│  │  │  └─ home-assistant-mqtt (MQTT credentials)                     │     │ │
│  │  │                                                                 │     │ │
│  │  │  ConfigMaps:                                                    │     │ │
│  │  │  ├─ home-assistant-mqtt (mosquitto.conf)                       │     │ │
│  │  │  ├─ home-assistant-zigbee2mqtt (configuration.yaml)            │     │ │
│  │  │  └─ home-assistant-postgresql-config (init.sql)                │     │ │
│  │  └─────────────────────────────────────────────────────────────────┘     │ │
│  │                                                                           │ │
│  └───────────────────────────────────────────────────────────────────────────┘ │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                              EXTERNAL ACCESS                                    │
└─────────────────────────────────────────────────────────────────────────────────┘

Internet
   │
   ├─ HTTPS (443) → Ingress Controller → home-assistant:8123
   │  └─ home.example.com (TLS encrypted)
   │
   ├─ HTTP/TCP → LoadBalancer → home-assistant:8123
   │  └─ External IP (MetalLB, Cloud LB)
   │
   └─ NodePort → Node IP:30123 → home-assistant:8123
      └─ K3s default access method

┌─────────────────────────────────────────────────────────────────────────────────┐
│                              DATA FLOW                                          │
└─────────────────────────────────────────────────────────────────────────────────┘

IoT Devices → MQTT (1883) → Home Assistant (8123)
               ↓
          Zigbee2MQTT (8080)
               ↓
          Home Assistant

Home Assistant ←→ PostgreSQL (5432)
               ↓
          /config PVC (persistent storage)

Node-RED (1880) ←→ Home Assistant API
                ↓
           Automations

ESPHome (6052) → Compile firmware → Flash ESP devices
                                      ↓
                                  MQTT → Home Assistant

┌─────────────────────────────────────────────────────────────────────────────────┐
│                         DEPLOYMENT OPTIONS                                      │
└─────────────────────────────────────────────────────────────────────────────────┘

Option 1: Basic (SQLite)
├─ 1 Pod (Home Assistant + sidecars)
├─ SQLite database in /config PVC
├─ ClusterIP service + port-forward
└─ Good for: Home labs, <100 devices

Option 2: Production (PostgreSQL)
├─ 2 Pods (Home Assistant + PostgreSQL)
├─ PostgreSQL for better performance
├─ LoadBalancer service
├─ Ingress with TLS
└─ Good for: Production, >200 devices

Option 3: K3s Single Node
├─ 1 Pod (all sidecars enabled)
├─ SQLite database
├─ NodePort service
├─ local-path storage
└─ Good for: Raspberry Pi, NUC, edge devices

Option 4: External Database
├─ 1 Pod (Home Assistant + sidecars)
├─ External PostgreSQL/MySQL cluster
├─ Any service type
└─ Good for: Enterprise, existing infrastructure

┌─────────────────────────────────────────────────────────────────────────────────┐
│                    MONITORING & OBSERVABILITY                                   │
└─────────────────────────────────────────────────────────────────────────────────┘

Prometheus Operator
   ↓
ServiceMonitor → Scrape metrics from Home Assistant
   ↓
Prometheus → Store metrics
   ↓
Grafana → Visualize dashboards
   ↓
Alerts (if configured)

Kubernetes Events
   ↓
kubectl get events -n home-assistant
   ↓
Pod status, deployment issues

Logs
   ↓
kubectl logs -n home-assistant home-assistant-0 -c home-assistant
   ↓
Application logs, errors

┌─────────────────────────────────────────────────────────────────────────────────┐
│                       BACKUP & DISASTER RECOVERY                                │
└─────────────────────────────────────────────────────────────────────────────────┘

Automated Backups (Future)
   ↓
CronJob → Backup /config → /backups PVC
   ↓
Retention policy (7-30 days)

Manual Backups
   ↓
kubectl exec → tar config directory
   ↓
kubectl cp → Download to local machine

Database Backups
   ↓
pg_dump (PostgreSQL) → Backup file
   ↓
Store off-cluster (S3, NFS, etc.)

Disaster Recovery
   ↓
1. Restore PVCs
2. Restore database
3. Helm install with same values
4. Verify integrations
