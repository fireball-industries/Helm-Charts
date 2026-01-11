# 🏭 CODESYS TargetVisu for Linux SL - Helm Chart

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Helm](https://img.shields.io/badge/Helm-v3-blue.svg)](https://helm.sh)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.24+-blue.svg)](https://kubernetes.io)

> *"Because staring at green text on black screens while your PLC crashes is a rite of passage. Now in containerized form with 100% more YAML and 200% more 'why is the HMI offline?'"*

## 🏭 CODESYS TargetVisu for Linux SL Helm Chart

Create a **production-ready CODESYS TargetVisu for Linux SL Helm chart** for Kubernetes/K3s environments optimized for industrial HMI/SCADA visualization and edge computing. Include Patrick Ryan's signature dark millennial humor and industrial automation expertise throughout documentation and comments.

## Project Overview

**Chart Name:** `codesys-targetvisu-pod`  
**Version:** 1.0.0  
**App Version:** V3.5.20.0 (or latest TargetVisu for Linux SL)  
**License:** Apache 2.0 (chart itself - CODESYS runtime requires separate license)  
**Maintainer:** Patrick Ryan / Fireball Industries  
**Distribution:** GitHub releases with packaged CODESYS runtime  

**Tagline:** *"Because staring at green text on black screens while your PLC crashes is a rite of passage. Now in containerized form with 100% more YAML and 200% more 'why is the HMI offline?'"*

---

## Core Requirements

### 1. Deployment Architecture

**Primary Deployment:**
- **Deployment** (single instance - TargetVisu is not clusterable)
- **Replica count:** 1 (fixed - license restriction and state)
- **PersistentVolumeClaim** for projects and configuration (5GB default)
- **Service** for web access (HTTP/HTTPS)
- **Ingress** support for SSL termination
- **HostNetwork** option for real-time industrial protocols

**Container Structure:**
- Base image: `debian:bookworm-slim` or `ubuntu:22.04`
- CODESYS TargetVisu for Linux SL runtime (user-provided package)
- Web server (built-in to TargetVisu)
- VNC server (optional for remote desktop access)

### 2. Storage Configuration

**Persistent storage needs:**

```yaml
storage:
  config:
    enabled: true
    size: 5Gi
    mountPath: /var/opt/codesys
    
  projects:
    enabled: true
    size: 10Gi
    mountPath: /projects
    
  logs:
    enabled: true
    size: 2Gi
    mountPath: /var/log/codesys
```

**Storage structure:**
- `/var/opt/codesys` - TargetVisu configuration, license
- `/projects` - HMI projects and visualizations
- `/var/log/codesys` - Runtime logs and diagnostics
- `/opt/codesys` - Application binaries (from image)

### 3. License Management

**Three license modes:**

```yaml
license:
  # Mode 1: License file (ConfigMap or Secret)
  type: file
  licenseFile: |
    # CODESYS license content
    
  # Mode 2: License server
  type: server
  licenseServer: "license.example.com:1947"
  
  # Mode 3: Demo/trial mode
  type: demo
  duration: 30d
```

### 4. Network Access Modes

**Four network options:**

**NodePort** (default for industrial edge):
```yaml
service:
  type: NodePort
  http:
    port: 8080
    nodePort: 30080
  https:
    port: 8443
    nodePort: 30443
  webvisu:
    port: 8081
    nodePort: 30081
```

**Ingress** (for secure remote access):
```yaml
ingress:
  enabled: true
  className: nginx
  host: hmi.factory.example.com
  tls:
    enabled: true
    secretName: codesys-tls
```

**LoadBalancer** (cloud deployments):
```yaml
service:
  type: LoadBalancer
  annotations:
    metallb.universe.tf/address-pool: industrial
```

**HostNetwork** (for industrial protocols requiring specific ports):
```yaml
hostNetwork: true
dnsPolicy: ClusterFirstWithHostNet
```

### 5. Resource Presets

**Three resource profiles:**

| Preset | CPU | Memory | Storage | Use Case |
|--------|-----|--------|---------|----------|
| **edge-minimal** | 500m / 1000m | 512Mi / 1Gi | 5Gi | Small HMIs, <10 screens, Raspberry Pi 4 |
| **edge-standard** | 1000m / 2000m | 1Gi / 2Gi | 10Gi | Medium HMIs, 10-50 screens, industrial PC (default) |
| **industrial** | 2000m / 4000m | 2Gi / 4Gi | 20Gi | Large HMIs, >50 screens, complex visualizations |

### 6. Industrial Protocol Support

**Pre-configured protocol integrations:**

```yaml
protocols:
  opcua:
    enabled: true
    port: 4840
    endpoint: "opc.tcp://0.0.0.0:4840"
    
  modbusTcp:
    enabled: true
    port: 502
    
  ethernetIp:
    enabled: false
    port: 44818
    
  profinet:
    enabled: false
    # Requires hostNetwork
    
  bacnet:
    enabled: false
    port: 47808
    
  canbus:
    enabled: false
    socketcan: true
```

### 7. Security Features

**Industrial-grade security:**

```yaml
security:
  # Web authentication
  authentication:
    enabled: true
    type: basic  # basic, ldap, active-directory
    users:
      - username: admin
        passwordSecret: codesys-admin-password
      - username: operator
        passwordSecret: codesys-operator-password
  
  # SSL/TLS
  tls:
    enabled: true
    certSecret: codesys-tls-cert
  
  # IP whitelisting
  ipWhitelist:
    enabled: true
    allowedIPs:
      - "10.0.0.0/8"
      - "192.168.0.0/16"
  
  # Role-based access
  rbac:
    enabled: true
    roles:
      - name: admin
        permissions: ["view", "edit", "configure"]
      - name: operator
        permissions: ["view", "acknowledge"]
      - name: readonly
        permissions: ["view"]
```

### 8. Integration with CODESYS Ecosystem

**PLC Runtime Integration:**

```yaml
plc:
  # Connect to CODESYS Control runtime
  enabled: true
  runtimeType: "Control for Linux SL"
  
  # Connection methods
  connection:
    type: local  # local, remote
    
    # Remote PLC connection
    remote:
      host: "plc.example.com"
      port: 11740
      protocol: CDS  # CODESYS protocol
    
    # Shared memory (local)
    local:
      shmPath: /dev/shm/codesys
```

**Gateway Integration:**

```yaml
gateway:
  enabled: true
  port: 11740
  maxConnections: 10
  encryption: true
```

### 9. VNC Remote Access (Optional)

```yaml
vnc:
  enabled: false
  port: 5900
  password: "changeme"
  resolution: "1920x1080"
  depth: 24
```

### 10. Monitoring & Diagnostics

```yaml
monitoring:
  # Prometheus metrics
  prometheus:
    enabled: true
    port: 9100
    path: /metrics
  
  # Health checks
  healthcheck:
    enabled: true
    interval: 30s
    timeout: 5s
    
  # Logging
  logging:
    level: info  # debug, info, warn, error
    format: json
    
  # Performance metrics
  metrics:
    cycleTimes: true
    memoryUsage: true
    taskExecution: true
    communicationStats: true
```

---

## File Structure (50+ files)

### Core Helm Files (7)
- `Chart.yaml` - Chart metadata with industrial automation focus
- `values.yaml` - 120+ configuration options
- `LICENSE` - Apache 2.0 license (for chart)
- `.gitignore` - Git exclusions
- `.gitattributes` - Git line endings
- `.helmignore` - Helm package exclusions
- `README.md` - Comprehensive documentation with dark humor

### Kubernetes Templates (12)
- `templates/_helpers.tpl` - Template helper functions
- `templates/deployment.yaml` - CODESYS TargetVisu Deployment
- `templates/service.yaml` - Service (HTTP/HTTPS/WebVisu)
- `templates/ingress.yaml` - Ingress for remote access
- `templates/serviceaccount.yaml` - ServiceAccount
- `templates/rbac.yaml` - RBAC for privileged access
- `templates/configmap.yaml` - Configuration files
- `templates/secret.yaml` - Licenses and passwords
- `templates/pvc.yaml` - PersistentVolumeClaims
- `templates/servicemonitor.yaml` - Prometheus metrics
- `templates/networkpolicy.yaml` - Network isolation
- `templates/NOTES.txt` - Post-install instructions with humor

### Container Build (5)
- `docker/Dockerfile` - Multi-stage build for TargetVisu
- `docker/entrypoint.sh` - Container startup script
- `docker/healthcheck.sh` - Health check script
- `docker/.dockerignore` - Docker exclusions
- `docker/README.md` - Build instructions

### PowerShell Scripts (5)
- `scripts/manage-targetvisu.ps1` - Main management (deploy, upgrade, backup, restart, shell)
- `scripts/test-targetvisu.ps1` - Testing suite (health, web, protocols, PLC connection)
- `scripts/license-manager.ps1` - License installation and validation
- `scripts/project-deploy.ps1` - HMI project deployment
- `scripts/diagnostics.ps1` - Runtime diagnostics and troubleshooting

### Documentation (6)
- `README.md` - Main project documentation
- `INSTALLATION.md` - Step-by-step installation guide
- `PROTOCOLS.md` - Industrial protocol configuration
- `PROJECTS.md` - HMI project deployment guide
- `TROUBLESHOOTING.md` - Common issues and solutions
- `QUICK_REFERENCE.md` - Fast command reference

### Example Configurations (6)
- `examples/minimal-hmi.yaml` - Small HMI, basic features
- `examples/standard-factory.yaml` - Medium factory HMI
- `examples/large-scada.yaml` - Large SCADA system
- `examples/edge-raspberry.yaml` - Raspberry Pi edge deployment
- `examples/secure-remote.yaml` - Remote access with SSL
- `examples/plc-integrated.yaml` - Integrated with CODESYS Control

### Configuration Templates (5)
- `config-templates/CODESYSControl.cfg` - Runtime configuration
- `config-templates/webserver.cfg` - Web server settings
- `config-templates/gateway.cfg` - Gateway configuration
- `config-templates/users.xml` - User management
- `config-templates/visu-config.xml` - Visualization settings

### Alert Rules (3)
- `alerts/alerts-runtime.yaml` - Runtime health, crashes, restarts
- `alerts/alerts-web.yaml` - Web interface availability, response time
- `alerts/alerts-plc.yaml` - PLC connection, communication errors

### Grafana Dashboards (4)
- `dashboards/targetvisu-overview.json` - System metrics, uptime
- `dashboards/web-performance.json` - Web access, response times
- `dashboards/protocol-stats.json` - OPC UA, Modbus communication
- `dashboards/plc-connection.json` - PLC connection health

### Integration Examples (4)
- `integration/prometheus-config.yaml` - Prometheus scrape config
- `integration/opcua-config.yaml` - OPC UA server configuration
- `integration/nginx-ingress.yaml` - Nginx Ingress with SSL
- `integration/plc-runtime-config.yaml` - CODESYS Control integration

### Sample Projects (3)
- `sample-projects/basic-buttons/` - Simple HMI with buttons
- `sample-projects/process-overview/` - Process visualization
- `sample-projects/alarm-viewer/` - Alarm management screen

---

## Key Features to Implement

### CODESYS TargetVisu Features
- ✅ Web-based HMI visualization
- ✅ Multi-client support (concurrent users)
- ✅ Responsive design (desktop, tablet, mobile)
- ✅ SVG and bitmap graphics support
- ✅ Touch-optimized interface
- ✅ Recipe management
- ✅ Alarm/event viewer
- ✅ Trend visualization
- ✅ User management and authentication
- ✅ Data logging

### Container-Specific Features
- ✅ StatefulSet/Deployment with persistent storage
- ✅ License file mounting (Secret)
- ✅ Configuration via ConfigMaps
- ✅ Auto-restart on crashes
- ✅ Health checks and probes
- ✅ Resource limits and requests
- ✅ Security contexts (non-root where possible)
- ✅ Multi-arch support (amd64, arm64, armv7)

### Industrial Features
- ✅ OPC UA client/server integration
- ✅ Modbus TCP support
- ✅ Real-time data updates
- ✅ PLC runtime communication
- ✅ Industrial protocol support
- ✅ High availability considerations
- ✅ Performance monitoring
- ✅ Audit logging

### Monitoring & Observability
- 📊 Prometheus metrics (CPU, memory, connections, errors)
- 📊 Grafana dashboard integration
- 📊 Alert rules for runtime failures
- 📊 Web access monitoring
- 📊 PLC connection health
- 📊 Protocol communication stats

---

## Configuration Examples

### values.yaml Structure

```yaml
# Resource preset
resourcePreset: edge-standard  # edge-minimal, edge-standard, industrial

# CODESYS TargetVisu
targetvisu:
  image:
    repository: ghcr.io/fireball-industries/codesys-targetvisu
    tag: "3.5.20.0"
    pullPolicy: IfNotPresent
  
  # License configuration
  license:
    type: file  # file, server, demo
    licenseSecret: codesys-license
  
  # Storage
  storage:
    config:
      size: 5Gi
    projects:
      size: 10Gi
    logs:
      size: 2Gi
  
  # Configuration
  config:
    webPort: 8080
    httpsPort: 8443
    webVisuPort: 8081
    maxClients: 10
    sessionTimeout: 3600
    
# Network configuration
service:
  type: NodePort
  http:
    port: 8080
    nodePort: 30080
  https:
    port: 8443
    nodePort: 30443

ingress:
  enabled: false
  host: hmi.example.com
  tls:
    enabled: false

# Industrial protocols
protocols:
  opcua:
    enabled: true
    port: 4840
  modbusTcp:
    enabled: true
    port: 502

# PLC integration
plc:
  enabled: false
  connection:
    type: local  # local, remote

# Security
security:
  authentication:
    enabled: true
  tls:
    enabled: false
  ipWhitelist:
    enabled: false

# Monitoring
monitoring:
  prometheus:
    enabled: true
    port: 9100
```

---

## Humor & Personality

Include dark millennial humor throughout:

### README.md quotes:
- *"Your PLC is about to crash, but at least the HMI will look good while it happens."*
- *"CODESYS: Because ladder logic wasn't confusing enough, let's add containers."*
- *"Now you can watch your factory automation fail in real-time from your phone."*
- *"Toggle outputs like a wizard. A very stressed, coffee-fueled industrial wizard."*
- *"Your HMI will be more reliable than your PLC. That's not saying much."*

### NOTES.txt post-install:
```
🏭 CODESYS TARGETVISU DEPLOYED 🏭

Congratulations! Your HMI is now containerized.

Your visualization is running on port {{ .Values.service.http.port }}.
Your PLC is probably still using ladder logic from 1987.
The operators are already complaining the buttons are "too small."

But hey, at least it's in Kubernetes now.
That's basically job security.

Default credentials:
Username: admin
Password: {{ .Values.security.authentication.defaultPassword }}

(Please change this before production. Seriously. Your security team is watching.)
```

### Alert annotations:
```yaml
annotations:
  summary: "TargetVisu is down. Your operators are now staring at blank screens."
  description: "The HMI has gone dark. Time to pretend you're 'investigating' while restarting the pod."
  runbook: "kubectl delete pod -l app=codesys-targetvisu && pray"
```

---

## Docker Image Build

### Multi-stage Dockerfile

```dockerfile
FROM debian:bookworm-slim AS builder

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget ca-certificates libssl3 libcurl4

# Download CODESYS TargetVisu (user must provide package)
# This is a placeholder - actual package from GitHub release
COPY codesys-targetvisu-*.deb /tmp/
RUN dpkg -i /tmp/codesys-targetvisu-*.deb || true
RUN apt-get -f install -y

FROM debian:bookworm-slim

# Runtime dependencies
RUN apt-get update && apt-get install -y \
    libssl3 libcurl4 fonts-liberation \
    && rm -rf /var/lib/apt/lists/*

# Copy CODESYS from builder
COPY --from=builder /opt/codesys /opt/codesys
COPY --from=builder /var/opt/codesys /var/opt/codesys

# Create runtime user
RUN useradd -r -u 1000 -s /bin/false codesys

# Volumes
VOLUME ["/var/opt/codesys", "/projects", "/var/log/codesys"]

# Expose ports
EXPOSE 8080 8443 8081 4840 502

# Health check
COPY docker/healthcheck.sh /usr/local/bin/
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD /usr/local/bin/healthcheck.sh

# Entrypoint
COPY docker/entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/opt/codesys/bin/codesysvisu"]
```

---

## Testing & Validation

### PowerShell Test Script Categories:
1. **Deployment Health** - Pod status, persistent storage mounted
2. **Web Interface** - HTTP 200, HTTPS if enabled, login page
3. **License Validation** - License valid, not expired, feature set
4. **PLC Connection** - Gateway reachable, runtime communication
5. **Protocol Tests** - OPC UA browsable, Modbus readable
6. **Performance** - Response time <500ms, memory usage stable
7. **Security** - Authentication working, SSL certificate valid
8. **Project Deployment** - Sample project loads, displays correctly

---

## Special Considerations

### License Handling
- ⚠️ User must provide CODESYS license (not included in chart)
- Support license file (Secret) or license server
- Demo mode for testing (30-day trial)
- License validation on startup
- Auto-renewal for license server mode

### CODESYS Package Distribution
- User hosts `.deb` package on GitHub releases
- Docker build downloads from GitHub release
- Multi-arch support (amd64, arm64, armv7 if available)
- Version pinning in values.yaml

### Industrial Environment Considerations
- Real-time performance requirements
- Deterministic behavior for HMI updates
- Network latency to PLCs
- Firewall rules for industrial protocols
- Physical device access (USB for license dongles)

### Edge Deployment
- Optimized for Raspberry Pi 4 (arm64)
- Low resource consumption (edge-minimal preset)
- Offline operation support
- Local storage for projects

---

## Deliverables

**Total: 50+ files across 11 categories**

1. ✅ Core Helm files (7)
2. ✅ Kubernetes templates (12)
3. ✅ Container build (5)
4. ✅ PowerShell scripts (5)
5. ✅ Documentation (6)
6. ✅ Example configurations (6)
7. ✅ Configuration templates (5)
8. ✅ Alert rules (3)
9. ✅ Grafana dashboards (4)
10. ✅ Integration examples (4)
11. ✅ Sample projects (3)

**Same quality and structure as Node Exporter and Home Assistant charts.**

---

## Success Criteria

- ✅ Deploys with single `helm install` command
- ✅ Web interface accessible within 60 seconds
- ✅ License validation works (file/server/demo)
- ✅ Persistent storage mounts correctly
- ✅ OPC UA/Modbus protocols functional
- ✅ PLC runtime integration works
- ✅ Sample HMI project displays
- ✅ Prometheus metrics exported
- ✅ Grafana dashboards show data
- ✅ PowerShell scripts provide full lifecycle management
- ✅ Docker image builds for multiple architectures
- ✅ Dark humor makes factory automation slightly less painful
- ✅ Ready for production industrial deployment

---

**Made with 💀 by Fireball Industries**  
*Because your factory automation deserves cloud-native deployments and existential dread in equal measure.*

---

**Ready to build when you are! This will be a comprehensive CODESYS TargetVisu deployment platform for Kubernetes/K3s with all the industrial automation features and "HMI is offline again" humor your factory needs.**
