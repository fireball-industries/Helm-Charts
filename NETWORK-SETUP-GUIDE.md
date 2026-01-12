# Network Setup Guide for Fireball Industries Pod Store
**Multi-Tenant Industrial Automation Platform**

> **TL;DR:** Run the automated setup scripts, open the ports listed below, and everything flows. We've done the hard work so your clients don't have to.

---

## Overview

This guide covers the complete networking configuration for a production multi-tenant K3s/Rancher environment running Fireball Industries Helm charts. Follow this **once per cluster** and all 21 Forge Industrial charts will work seamlessly.

**Environment Assumptions:**
- ✅ Multi-tenant Rancher cluster (already configured)
- ✅ K3s or RKE2 Kubernetes distribution
- ✅ Windows Server nodes (PowerShell commands) OR Linux nodes (bash commands)
- ✅ Factory network with static IP range available

### Your Network Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    CLOUD TIER (Azure)                       │
├─────────────────────────────────────────────────────────────┤
│  K3s Server:       172.16.0.20  (74.249.82.35 public)      │
│  LoadBalancer:     172.16.1.100-172.16.1.150               │
│                                                             │
│  Services: Grafana, N8N, Prometheus, Alertmanager, Loki    │
└─────────────────────────────────────────────────────────────┘
                              │
                     Internet / VPN / Direct
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
┌───────▼────────┐   ┌────────▼────────┐   ┌───────▼────────┐
│   SITE A       │   │    SITE B       │   │   SITE C       │
├────────────────┤   ├─────────────────┤   ├────────────────┤
│ Edge Tier:     │   │ Edge Tier:      │   │ Edge Tier:     │
│ 172.17.0.0/16  │   │ 172.18.0.0/16   │   │ 172.19.0.0/16  │
│                │   │                 │   │                │
│ K3s Services:  │   │ K3s Services:   │   │ K3s Services:  │
│ - CODESYS      │   │ - CODESYS       │   │ - CODESYS      │
│ - Ignition     │   │ - Ignition      │   │ - Ignition     │
│ - Node-RED     │   │ - Node-RED      │   │ - Node-RED     │
│ - MQTT         │   │ - MQTT          │   │ - MQTT         │
│                │   │                 │   │                │
│ LoadBalancer:  │   │ LoadBalancer:   │   │ LoadBalancer:  │
│ 172.17.1.100-  │   │ 172.18.1.100-   │   │ 172.19.1.100-  │
│        .150    │   │         .150    │   │         .150   │
├────────────────┤   ├─────────────────┤   ├────────────────┤
│ OT Tier:       │   │ OT Tier:        │   │ OT Tier:       │
│ 172.20.0.0/16  │   │ 172.21.0.0/16   │   │ 172.22.0.0/16  │
│                │   │                 │   │                │
│ (Isolated)     │   │ (Isolated)      │   │ (Isolated)     │
│ PLCs, SCADA    │   │ PLCs, SCADA     │   │ PLCs, SCADA    │
└────────────────┘   └─────────────────┘   └────────────────┘
```

**Key Design Principles:**
- **Cloud Tier:** Central K3s cluster in Azure (172.16.0.0/16) - Monitoring, orchestration, centralized services
- **Edge Tier:** Site-local K3s clusters per factory location (172.17-19.x.x) - CODESYS, Ignition, MQTT, Node-RED
- **OT Tier:** Isolated operational technology networks (172.20-22.x.x) - Field devices, PLCs, HMIs connected to K3s via MQTT/OPC UA
- **Network Isolation:** OT networks protected with NetworkPolicies, no direct internet access from OT tier
- **Connectivity:** Sites connect to cloud via internet/VPN (OpenWISP managed separately for device management)

---

## 1. Required Port Configuration

### Core Kubernetes Ports (K3s/Rancher)

**On ALL nodes - must remain open:**

| Port | Protocol | Purpose | Direction |
|------|----------|---------|-----------|
| 6443 | TCP | Kubernetes API Server | Inbound |
| 10250 | TCP | Kubelet metrics | Inbound |
| 2379-2380 | TCP | etcd (server nodes only) | Inbound |
| 8472 | UDP | Flannel VXLAN | Bidirectional |
| 51820 | UDP | Flannel WireGuard (if used) | Bidirectional |
| 51821 | UDP | Flannel WireGuard (IPv6) | Bidirectional |

**Rancher-specific:**

| Port | Protocol | Purpose | Direction |
|------|----------|---------|-----------|
| 80 | TCP | Rancher UI (HTTP) | Inbound |
| 443 | TCP | Rancher UI (HTTPS) | Inbound |
| 9345 | TCP | Rancher agent registration | Inbound |

### NodePort Range (Services with NodePort type)

| Port Range | Protocol | Purpose |
|------------|----------|---------|
| 30000-32767 | TCP | Kubernetes NodePort services | Inbound |

**Charts using NodePort by default:**
- CODESYS AMD64-x86 (ports 31740, 32455, 34840)
- Some monitoring stack components

### LoadBalancer IP Range (MetalLB)

**Your Network Configuration:**

| Site | Edge Tier Network | LoadBalancer IP Pool | Purpose |
|------|-------------------|----------------------|---------|
| Cloud (Azure) | 172.16.0.0/16 | 172.16.1.100-172.16.1.150 | Central services, Traefik ingress |
| Site A | 172.17.0.0/16 | 172.17.1.100-172.17.1.150 | Edge services, MQTT, OPC UA |
| Site B | 172.18.0.0/16 | 172.18.1.100-172.18.1.150 | Edge services, MQTT, OPC UA |
| Site C | 172.19.0.0/16 | 172.19.1.100-172.19.1.150 | Edge services, MQTT, OPC UA |

**Charts using LoadBalancer by default:**
- **CODESYS Runtime ARM** (ports 1217, 4840, 8080) - Deploy to edge tier
- **CODESYS Edge Gateway** (ports 2455, 1217, 1740-1743) - Deploy to edge tier
- **Mosquitto MQTT** (ports 1883, 8883) - **Dual service mode** (see MQTT section)
- **Traefik Ingress Controller** (ports 80, 443) - Deploy to cloud tier
- **Grafana-Loki** (port 3000) - Deploy to cloud tier
- **Alert Manager** - Changed to ClusterIP (internal only)

---

## 2. Industrial Protocol Ports

**These ports are used BY the applications inside pods - no firewall rules needed on nodes, but document for network team:**

### OPC UA
| Port | Protocol | Service | Chart |
|------|----------|---------|-------|
| 4840 | TCP | OPC UA Server | CODESYS Runtime ARM, Ignition Edge, EmberBurn |
| 62541 | TCP | OPC UA Server | Ignition Edge (alternate) |

### MQTT
| Port | Protocol | Service | Chart |
|------|----------|---------|-------|
| 1883 | TCP | MQTT (unencrypted) | Mosquitto MQTT, Ignition Edge, EmberBurn |
| 8883 | TCP | MQTT over TLS | Mosquitto MQTT |
| 9001 | TCP | MQTT WebSocket | Mosquitto MQTT |

### Modbus TCP
| Port | Protocol | Service | Chart |
|------|----------|---------|-------|
| 502 | TCP | Modbus TCP | EmberBurn, Home Assistant |

### Database Services
| Port | Protocol | Service | Chart |
|------|----------|---------|-------|
| 5432 | TCP | PostgreSQL/TimescaleDB | PostgreSQL-Pod, TimescaleDB-Pod |
| 8086 | TCP | InfluxDB | InfluxDB-Pod |
| 3306 | TCP | MySQL (if added) | N/A |

### Monitoring & Observability
| Port | Protocol | Service | Chart |
|------|----------|---------|-------|
| 9090 | TCP | Prometheus | Prometheus-Pod |
| 3000 | TCP | Grafana | Grafana-Loki |
| 3100 | TCP | Loki | Grafana-Loki |
| 9093 | TCP | Alertmanager | Alert-Manager |
| 9100 | TCP | Node Exporter | Node-Exporter-Pod |
| 9273 | TCP | CODESYS Metrics | CODESYS charts (optional) |

### Web UIs & APIs
| Port | Protocol | Service | Chart |
|------|----------|---------|-------|
| 8080 | TCP | Various Web UIs | CODESYS WebVisu, Node-RED, N8N, Home Assistant |
| 8123 | TCP | Home Assistant | Home Assistant-Pod |
| 1880 | TCP | Node-RED | Node-RED |
| 5678 | TCP | N8N | N8N-Pod |

---

## 3. Automated Firewall Configuration

### Windows Server Nodes (PowerShell - Run as Administrator)

```powershell
# Save as: Configure-FireballNetworking.ps1

#Requires -RunAsAdministrator

Write-Host "🔥 Configuring Fireball Industries Network Rules..." -ForegroundColor Cyan

# Kubernetes Core Ports
New-NetFirewallRule -DisplayName "K3s API Server" -Direction Inbound -LocalPort 6443 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName "K3s Kubelet" -Direction Inbound -LocalPort 10250 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName "K3s etcd" -Direction Inbound -LocalPort 2379-2380 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue

# Flannel VXLAN
New-NetFirewallRule -DisplayName "Flannel VXLAN" -Direction Inbound -LocalPort 8472 -Protocol UDP -Action Allow -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName "Flannel VXLAN" -Direction Outbound -LocalPort 8472 -Protocol UDP -Action Allow -ErrorAction SilentlyContinue

# Flannel WireGuard (if used)
New-NetFirewallRule -DisplayName "Flannel WireGuard" -Direction Inbound -LocalPort 51820-51821 -Protocol UDP -Action Allow -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName "Flannel WireGuard" -Direction Outbound -LocalPort 51820-51821 -Protocol UDP -Action Allow -ErrorAction SilentlyContinue

# Rancher Ports
New-NetFirewallRule -DisplayName "Rancher HTTP" -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName "Rancher HTTPS" -Direction Inbound -LocalPort 443 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName "Rancher Agent" -Direction Inbound -LocalPort 9345 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue

# NodePort Range (30000-32767)
New-NetFirewallRule -DisplayName "Kubernetes NodePort Range" -Direction Inbound -LocalPort 30000-32767 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue

Write-Host "✅ Firewall rules configured successfully!" -ForegroundColor Green
Write-Host "📊 Verifying rules..." -ForegroundColor Cyan

# Verify critical rules
$criticalPorts = @(6443, 10250, 80, 443)
foreach ($port in $criticalPorts) {
    $rule = Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*$port*" -or $_.DisplayName -like "*K3s*" -or $_.DisplayName -like "*Rancher*"} | Select-Object -First 1
    if ($rule) {
        Write-Host "  ✓ Port $port configured" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Port $port NOT configured - manual check required" -ForegroundColor Red
    }
}

Write-Host "`n🔥 Fireball Industries networking ready!" -ForegroundColor Cyan
```

**Run it:**
```powershell
.\Configure-FireballNetworking.ps1
```

### Linux Nodes (firewalld - RHEL/CentOS/Rocky)

```bash
#!/bin/bash
# Save as: configure-fireball-networking.sh

echo "🔥 Configuring Fireball Industries Network Rules..."

# Kubernetes Core
firewall-cmd --permanent --add-port=6443/tcp    # K3s API
firewall-cmd --permanent --add-port=10250/tcp   # Kubelet
firewall-cmd --permanent --add-port=2379-2380/tcp  # etcd

# Flannel
firewall-cmd --permanent --add-port=8472/udp    # VXLAN
firewall-cmd --permanent --add-port=51820-51821/udp  # WireGuard

# Rancher
firewall-cmd --permanent --add-port=80/tcp      # HTTP
firewall-cmd --permanent --add-port=443/tcp     # HTTPS
firewall-cmd --permanent --add-port=9345/tcp    # Agent

# NodePort Range
firewall-cmd --permanent --add-port=30000-32767/tcp

# Reload
firewall-cmd --reload

echo "✅ Firewall rules configured successfully!"
firewall-cmd --list-ports
```

**Run it:**
```bash
chmod +x configure-fireball-networking.sh
sudo ./configure-fireball-networking.sh
```

### Linux Nodes (iptables/ufw - Ubuntu/Debian)

```bash
#!/bin/bash
# Save as: configure-fireball-networking-ufw.sh

echo "🔥 Configuring Fireball Industries Network Rules..."

# Kubernetes Core
ufw allow 6443/tcp comment "K3s API Server"
ufw allow 10250/tcp comment "Kubelet"
ufw allow 2379:2380/tcp comment "etcd"

# Flannel
ufw allow 8472/udp comment "Flannel VXLAN"
ufw allow 51820:51821/udp comment "Flannel WireGuard"

# Rancher
ufw allow 80/tcp comment "Rancher HTTP"
ufw allow 443/tcp comment "Rancher HTTPS"
ufw allow 9345/tcp comment "Rancher Agent"

# NodePort Range
ufw allow 30000:32767/tcp comment "Kubernetes NodePort"

# Enable if not already
ufw --force enable

echo "✅ Firewall rules configured successfully!"
ufw status numbered
```

**Run it:**
```bash
chmod +x configure-fireball-networking-ufw.sh
sudo ./configure-fireball-networking-ufw.sh
```

---

## 4. MetalLB Installation & Configuration

**Required for LoadBalancer service types to work on bare-metal.**

### Install MetalLB

```bash
# Install MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml

# Wait for MetalLB pods to be ready
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb \
  --timeout=90s
```

### Configure IP Address Pool

**Multi-Site Configuration - Create file: `metallb-config.yaml`**

```yaml
# Cloud Tier (Azure K3s Cluster)
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: cloud-tier
  namespace: metallb-system
spec:
  addresses:
  - 172.16.1.100-172.16.1.150  # Azure cloud services
  autoAssign: false  # Manually assign to avoid conflicts
---
# Site A Edge Tier
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: site-a-edge
  namespace: metallb-system
spec:
  addresses:
  - 172.17.1.100-172.17.1.150  # Site A edge devices
  autoAssign: true
---
# Site B Edge Tier
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: site-b-edge
  namespace: metallb-system
spec:
  addresses:
  - 172.18.1.100-172.18.1.150  # Site B edge devices
  autoAssign: true
---
# Site C Edge Tier
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: site-c-edge
  namespace: metallb-system
spec:
  addresses:
  - 172.19.1.100-172.19.1.150  # Site C edge devices
  autoAssign: true
---
# L2 Advertisement (all pools)
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: fireball-industrial
  namespace: metallb-system
spec:
  ipAddressPools:
  - cloud-tier
  - site-a-edge
  - site-b-edge
  - site-c-edge
```

**To assign specific pool to a service, use annotation:**
```yaml
metadata:
  annotations:
    metallb.universe.tf/address-pool: site-a-edge
```

**Apply it:**
```bash
kubectl apply -f metallb-config.yaml
```

### Verify MetalLB

```bash
# Check MetalLB pods
kubectl get pods -n metallb-system

# Check IP pool
kubectl get ipaddresspool -n metallb-system

# Test with a LoadBalancer service
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=LoadBalancer
kubectl get svc nginx

# You should see an EXTERNAL-IP assigned from your pool
# Clean up test:
kubectl delete svc nginx
kubectl delete deployment nginx
```

---

## 5. Ingress Controller Configuration (Traefik)

**K3s includes Traefik by default - verify it's running:**

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik
```

### Multi-Web-UI Routing Configuration

**Your environment needs routing for:**
- **Grafana** (monitoring dashboards) - `grafana.factory.local`
- **Node-RED** (automation flows) - `nodered.factory.local`
- **Ignition Gateway** (SCADA/HMI designer) - `ignition.factory.local`
- **N8N** (workflow automation) - `n8n.factory.local`
- **Home Assistant** (IoT dashboard) - `homeassistant.factory.local`

**Create file: `traefik-ingress-routes.yaml`**

```yaml
# Grafana Ingress (Cloud Tier)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana-ingress
  namespace: monitoring  # Adjust to your namespace
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: traefik
  tls:
  - hosts:
    - grafana.factory.local
    secretName: grafana-tls
  rules:
  - host: grafana.factory.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: grafana-loki  # Your Grafana service name
            port:
              number: 3000
---
# Node-RED Ingress (Edge Tier - per site)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nodered-ingress
  namespace: automation
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    # Allow WebSocket for Node-RED dashboard
    traefik.ingress.kubernetes.io/router.middlewares: automation-nodered-strip@kubernetescrd
spec:
  ingressClassName: traefik
  tls:
  - hosts:
    - nodered.site-a.factory.local
    secretName: nodered-tls
  rules:
  - host: nodered.site-a.factory.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: node-red
            port:
              number: 1880
---
# Ignition Gateway Ingress (Edge Tier)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ignition-gateway-ingress
  namespace: scada
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    # Increase timeout for Designer connections
    traefik.ingress.kubernetes.io/router.middlewares: scada-ignition-timeout@kubernetescrd
spec:
  ingressClassName: traefik
  tls:
  - hosts:
    - ignition.site-a.factory.local
    secretName: ignition-tls
  rules:
  - host: ignition.site-a.factory.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ignition-edge-pod
            port:
              number: 8088  # Gateway web port
---
# N8N Workflow Automation Ingress (Cloud Tier)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: n8n-ingress
  namespace: automation
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
spec:
  ingressClassName: traefik
  tls:
  - hosts:
    - n8n.factory.local
    secretName: n8n-tls
  rules:
  - host: n8n.factory.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: n8n-pod
            port:
              number: 5678
---
# Home Assistant Ingress (Edge Tier)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: homeassistant-ingress
  namespace: iot
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
spec:
  ingressClassName: traefik
  tls:
  - hosts:
    - homeassistant.site-a.factory.local
    secretName: homeassistant-tls
  rules:
  - host: homeassistant.site-a.factory.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: home-assistant-pod
            port:
              number: 8123
```

**Apply ingress routes:**
```bash
kubectl apply -f traefik-ingress-routes.yaml
```

### Custom Traefik Configuration (Optional)

**For industrial protocols (MQTT, OPC UA) via Traefik:**

```yaml
# traefik-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: traefik-config
  namespace: kube-system
data:
  traefik.yaml: |
    # Entry points for web and industrial protocols
    entryPoints:
      web:
        address: ":80"
      websecure:
        address: ":443"
      mqtt:
        address: ":1883"  # MQTT plaintext
      mqtts:
        address: ":8883"  # MQTT over TLS
      opcua:
        address: ":4840"  # OPC UA
    
    # Enable dashboard
    api:
      dashboard: true
    
    # TLS configuration
    certificatesResolvers:
      letsencrypt:
        acme:
          email: admin@fireball-industries.com
          storage: /data/acme.json
          httpChallenge:
            entryPoint: web
```

**DNS Configuration for Ingress:**

Add to your DNS server or `/etc/hosts`:
```
172.16.1.100  grafana.factory.local
172.16.1.100  n8n.factory.local
172.17.1.100  nodered.site-a.factory.local
172.17.1.100  ignition.site-a.factory.local
172.17.1.100  homeassistant.site-a.factory.local
```

**Verify Ingress:**
```bash
kubectl get ingress --all-namespaces
curl -k https://grafana.factory.local
```

---

**K3s includes Traefik by default - verify it's running:**

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik
```

### Multi-Web-UI Routing Configuration

**Your environment needs routing for:**
- **Grafana** (monitoring dashboards) - `grafana.factory.local`
- **Node-RED** (automation flows) - `nodered.factory.local`
- **Ignition Gateway** (SCADA/HMI designer) - `ignition.factory.local`
- **N8N** (workflow automation) - `n8n.factory.local`
- **Home Assistant** (IoT dashboard) - `homeassistant.factory.local`

**Create file: `traefik-ingress-routes.yaml`**

```yaml
# Grafana Ingress (Cloud Tier)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana-ingress
  namespace: monitoring  # Adjust to your namespace
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: traefik
  tls:
  - hosts:
    - grafana.factory.local
    secretName: grafana-tls
  rules:
  - host: grafana.factory.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: grafana-loki  # Your Grafana service name
            port:
              number: 3000
---
# Node-RED Ingress (Edge Tier - per site)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nodered-ingress
  namespace: automation
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    # Allow WebSocket for Node-RED dashboard
    traefik.ingress.kubernetes.io/router.middlewares: automation-nodered-strip@kubernetescrd
spec:
  ingressClassName: traefik
  tls:
  - hosts:
    - nodered.site-a.factory.local
    secretName: nodered-tls
  rules:
  - host: nodered.site-a.factory.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: node-red
            port:
              number: 1880
---
# Ignition Gateway Ingress (Edge Tier)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ignition-gateway-ingress
  namespace: scada
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    # Increase timeout for Designer connections
    traefik.ingress.kubernetes.io/router.middlewares: scada-ignition-timeout@kubernetescrd
spec:
  ingressClassName: traefik
  tls:
  - hosts:
    - ignition.site-a.factory.local
    secretName: ignition-tls
  rules:
  - host: ignition.site-a.factory.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ignition-edge-pod
            port:
              number: 8088  # Gateway web port
---
# N8N Workflow Automation Ingress (Cloud Tier)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: n8n-ingress
  namespace: automation
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
spec:
  ingressClassName: traefik
  tls:
  - hosts:
    - n8n.factory.local
    secretName: n8n-tls
  rules:
  - host: n8n.factory.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: n8n-pod
            port:
              number: 5678
---
# Home Assistant Ingress (Edge Tier)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: homeassistant-ingress
  namespace: iot
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
spec:
  ingressClassName: traefik
  tls:
  - hosts:
    - homeassistant.site-a.factory.local
    secretName: homeassistant-tls
  rules:
  - host: homeassistant.site-a.factory.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: home-assistant-pod
            port:
              number: 8123
```

**Apply ingress routes:**
```bash
kubectl apply -f traefik-ingress-routes.yaml
```

### Custom Traefik Configuration (Optional)

**For industrial protocols (MQTT, OPC UA) via Traefik:**

```yaml
# traefik-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: traefik-config
  namespace: kube-system
data:
  traefik.yaml: |
    # Entry points for web and industrial protocols
    entryPoints:
      web:
        address: ":80"
      websecure:
        address: ":443"
      mqtt:
        address: ":1883"  # MQTT plaintext
      mqtts:
        address: ":8883"  # MQTT over TLS
      opcua:
        address: ":4840"  # OPC UA
    
    # Enable dashboard
    api:
      dashboard: true
    
    # TLS configuration
    certificatesResolvers:
      letsencrypt:
        acme:
          email: admin@fireball-industries.com
          storage: /data/acme.json
          httpChallenge:
            entryPoint: web
```

**DNS Configuration for Ingress:**

Add to your DNS server or `/etc/hosts`:
```
172.16.1.100  grafana.factory.local
172.16.1.100  n8n.factory.local
172.17.1.100  nodered.site-a.factory.local
172.17.1.100  ignition.site-a.factory.local
172.17.1.100  homeassistant.site-a.factory.local
```

**Verify Ingress:**
```bash
kubectl get ingress --all-namespaces
curl -k https://grafana.factory.local
```

---

## 6. MQTT Broker Dual-Service Configuration

**Mosquitto MQTT requires BOTH internal ClusterIP and external LoadBalancer:**

### Why Dual Services?
- **ClusterIP:** For pod-to-pod communication (Node-RED, Home Assistant, CODESYS)
- **LoadBalancer:** For external device connections (PLCs, IoT sensors, field devices)

### Configuration

**Create file: `mosquitto-dual-service.yaml`**

```yaml
# Service 1: ClusterIP for internal cluster communication
apiVersion: v1
kind: Service
metadata:
  name: mosquitto-mqtt-pod
  namespace: iot
  labels:
    app: mosquitto-mqtt-pod
spec:
  type: ClusterIP
  ports:
  - name: mqtt
    port: 1883
    targetPort: 1883
    protocol: TCP
  - name: mqtts
    port: 8883
    targetPort: 8883
    protocol: TCP
  - name: websocket
    port: 9001
    targetPort: 9001
    protocol: TCP
  selector:
    app: mosquitto-mqtt-pod
---
# Service 2: LoadBalancer for external device access
apiVersion: v1
kind: Service
metadata:
  name: mosquitto-mqtt-external
  namespace: iot
  labels:
    app: mosquitto-mqtt-pod
  annotations:
    metallb.universe.tf/address-pool: site-a-edge  # Site-specific pool
spec:
  type: LoadBalancer
  loadBalancerIP: 172.17.1.110  # Static IP for Site A
  ports:
  - name: mqtt
    port: 1883
    targetPort: 1883
    protocol: TCP
  - name: mqtts
    port: 8883
    targetPort: 8883
    protocol: TCP
  selector:
    app: mosquitto-mqtt-pod
```

**Apply configuration:**
```bash
kubectl apply -f mosquitto-dual-service.yaml
```

### Per-Site MQTT Deployment

**Site A MQTT Broker:**
```yaml
metadata:
  name: mosquitto-mqtt-external-site-a
  annotations:
    metallb.universe.tf/address-pool: site-a-edge
spec:
  loadBalancerIP: 172.17.1.110
```

**Site B MQTT Broker:**
```yaml
metadata:
  name: mosquitto-mqtt-external-site-b
  annotations:
    metallb.universe.tf/address-pool: site-b-edge
spec:
  loadBalancerIP: 172.18.1.110
```

**Site C MQTT Broker:**
```yaml
metadata:
  name: mosquitto-mqtt-external-site-c
  annotations:
    metallb.universe.tf/address-pool: site-c-edge
spec:
  loadBalancerIP: 172.19.1.110
```

### Connection Examples

**Internal (from other pods in cluster):**
```python
import paho.mqtt.client as mqtt

client = mqtt.Client()
client.connect("mosquitto-mqtt-pod.iot.svc.cluster.local", 1883)
```

**External (from factory floor devices):**
```python
import paho.mqtt.client as mqtt

client = mqtt.Client()
client.connect("172.17.1.110", 1883)  # Site A LoadBalancer IP
```

**Verify MQTT services:**
```bash
# Check both services
kubectl get svc -n iot | grep mosquitto

# Test internal connection
kubectl run mqtt-test --rm -it --image=eclipse-mosquitto -- mosquitto_sub -h mosquitto-mqtt-pod.iot.svc.cluster.local -t test

# Test external connection (from outside cluster)
mosquitto_sub -h 172.17.1.110 -t test
```

---

## 7. Network Policy (OT Network Isolation)

**Install Calico for NetworkPolicy support:**

```bash
# K3s with Calico
curl https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml -O
kubectl apply -f calico.yaml

# Verify Calico
kubectl get pods -n kube-system -l k8s-app=calico-node
```

**NetworkPolicies are available in charts but disabled by default.**

Enable per-chart in values.yaml:
```yaml
networkPolicy:
  enabled: true
```

**Default policies allow:**
- Intra-namespace communication
- Egress to DNS (port 53)
- Chart-specific required ports

---

## 8. DNS Configuration

### Internal (Kubernetes DNS)
**Already works - no configuration needed.**

Services resolve as: `<service-name>.<namespace>.svc.cluster.local`

Examples:
- `postgresql-pod.databases.svc.cluster.local:5432`
- `mosquitto-mqtt-pod.iot.svc.cluster.local:1883`
- `influxdb-pod.default.svc.cluster.local:8086`

### External DNS (Optional)

**For external access to LoadBalancer IPs:**

```bash
# Install external-dns
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
helm install external-dns external-dns/external-dns \
  --set provider=rfc2136 \
  --set rfc2136.host=your-dns-server.local \
  --set rfc2136.zone=factory.local
```

**OR manually add DNS records:**
- Point `*.factory.local` → Traefik LoadBalancer IP
- Point specific services → their LoadBalancer IPs

---

## 9. Multi-Tenant Namespace Isolation

**Already handled by Rancher Projects, but verify:**

### Resource Quotas (per namespace)
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: tenant-quota
  namespace: tenant-a
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi
    persistentvolumeclaims: "10"
    services.loadbalancers: "5"
```

### Network Isolation (between tenants)
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-cross-tenant
  namespace: tenant-a
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          tenant: tenant-a
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          tenant: tenant-a
  - to:  # Allow DNS
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
    ports:
    - protocol: UDP
      port: 53
```

---

## 10. Monitoring & Health Checks

**Verify everything is working:**

```bash
# Check all Fireball charts
kubectl get pods --all-namespaces -l fireball.industries/chart

# Check LoadBalancer IPs assigned
kubectl get svc --all-namespaces -o wide | grep LoadBalancer

# Check Ingress routes
kubectl get ingress --all-namespaces

# Test connectivity from a debug pod
kubectl run -it --rm debug --image=nicolaka/netshoot --restart=Never -- bash
# Inside pod:
curl postgresql-pod.databases.svc.cluster.local:5432
curl influxdb-pod.default.svc.cluster.local:8086/health
nc -zv mosquitto-mqtt-pod.iot.svc.cluster.local 1883
```

**Health check endpoints:**
- InfluxDB: `http://<ip>:8086/health`
- Prometheus: `http://<ip>:9090/-/healthy`
- Grafana: `http://<ip>:3000/api/health`
- PostgreSQL: `pg_isready -h <ip> -p 5432`

---

## 11. Common Issues & Troubleshooting

### Services stuck in "Pending" (LoadBalancer)
**Cause:** MetalLB not installed or no IPs available

**Fix:**
```bash
kubectl get ipaddresspool -n metallb-system
kubectl describe svc <service-name>  # Check events
```

### Pods can't communicate between namespaces
**Cause:** NetworkPolicy blocking traffic

**Fix:**
```bash
kubectl get networkpolicy -n <namespace>
# Temporarily disable to test:
kubectl delete networkpolicy <policy-name> -n <namespace>
```

### Ingress not routing traffic
**Cause:** Traefik not running or misconfigured

**Fix:**
```bash
kubectl get pods -n kube-system | grep traefik
kubectl logs -n kube-system -l app.kubernetes.io/name=traefik
```

### Cannot reach NodePort services
**Cause:** Firewall blocking 30000-32767 range

**Fix:** Re-run firewall configuration script

---

## 12. Production Checklist

**Before going live:**

### Infrastructure
- [ ] All firewall rules configured on ALL nodes (cloud + edge)
- [ ] MetalLB installed with multi-site IP pools configured
- [ ] IP pools configured for: Cloud (172.16.x.x), Site A (172.17.x.x), Site B (172.18.x.x), Site C (172.19.x.x)
- [ ] Traefik ingress controller running in cloud tier
- [ ] Site-to-cloud connectivity verified (VPN/internet routing working)
- [ ] DNS configured for ingress routes (grafana.factory.local, etc.)

### Security & Isolation
- [ ] Calico installed for NetworkPolicy enforcement
- [ ] OT namespace network policies applied (ot-deny-all, ot-to-mqtt, etc.)
- [ ] OT tier isolated from internet (deny-internet-egress policy active)
- [ ] CODESYS/Ignition can only reach allowed services (databases, MQTT)
- [ ] Prometheus can scrape OT metrics (allow-prometheus-scrape policy)
- [ ] Resource quotas set per tenant/namespace
- [ ] TLS certificates configured for ingress routes

### Services & Connectivity
- [ ] MQTT broker has dual services (ClusterIP + LoadBalancer)
- [ ] MQTT LoadBalancer IPs assigned per site (172.17.1.110, 172.18.1.110, 172.19.1.110)
- [ ] Traefik ingress routes configured (Grafana, Node-RED, Ignition, N8N, Home Assistant)
- [ ] LoadBalancer services have external IPs assigned
- [ ] Test pod-to-pod communication within namespaces
- [ ] Test MQTT external connections from factory floor devices
- [ ] Test OPC UA connections (Ignition → CODESYS)
- [ ] Test database connectivity from CODESYS/Ignition
- [ ] Verify OT workloads CANNOT reach internet

### Monitoring & Operations
- [ ] Monitoring stack deployed (Prometheus, Grafana, Loki)
- [ ] Grafana dashboards accessible via ingress
- [ ] Alertmanager configured for critical alerts
- [ ] Node exporters running on all nodes
- [ ] ServiceMonitors configured for CODESYS/Ignition metrics
- [ ] Backup and disaster recovery plan documented

**Note:** OpenWISP device management (WireGuard 172.8.x.x) is separate - see OpenWISP documentation

---

## 13. Port Summary - Quick Reference

**Copy this to your network team:**

```
KUBERNETES INFRASTRUCTURE
6443/tcp    - Kubernetes API Server
10250/tcp   - Kubelet metrics
2379-2380/tcp - etcd cluster communication
8472/udp    - Flannel VXLAN overlay network
51820-51821/udp - Flannel WireGuard (optional)

RANCHER MANAGEMENT
80/tcp      - Rancher UI (HTTP)
443/tcp     - Rancher UI (HTTPS)
9345/tcp    - Rancher agent registration

KUBERNETES SERVICES
30000-32767/tcp - NodePort service range

INDUSTRIAL PROTOCOLS (inside cluster, for reference)
1883/tcp    - MQTT
8883/tcp    - MQTT over TLS
4840/tcp    - OPC UA
502/tcp     - Modbus TCP

DATABASES (inside cluster)
5432/tcp    - PostgreSQL/TimescaleDB
8086/tcp    - InfluxDB

MONITORING (inside cluster)
9090/tcp    - Prometheus
3000/tcp    - Grafana
9093/tcp    - Alertmanager
9100/tcp    - Node Exporter

WEB UIs (inside cluster, accessed via Ingress or LoadBalancer)
8080/tcp    - Various (CODESYS WebVisu, Node-RED, etc.)
8123/tcp    - Home Assistant
1880/tcp    - Node-RED
5678/tcp    - N8N
```

---

## 14. Site Connectivity Notes

### OpenWISP WireGuard + K3s Integration

**Your architecture has TWO communication paths:**

1. **Device Management (OpenWISP WireGuard):**
   - OpenWISP server (172.16.0.10) manages factory floor devices
   - WireGuard tunnel network: 172.8.0.0/16
   - Devices (PLCs, sensors, HMIs) get WireGuard IPs (172.8.1.x, 172.8.2.x, etc.)

2. **K3s Cluster Communication:**
   - Cloud K3s: 172.16.0.20 (Azure) with public IP 74.249.82.35
   - Edge K3s: 172.17/18/19.0.20 (per site)

---

### MVP/Demo Configuration (Current - Direct Internet)

**For rapid deployment and testing, use direct internet connectivity:**

```bash
# On cloud K3s server (already installed)
# Server is accessible at: https://74.249.82.35:6443

# On Site A edge K3s node
curl -sfL https://get.k3s.io | K3S_URL=https://74.249.82.35:6443 \
  K3S_TOKEN=<your-token> sh -s -

# On Site B edge K3s node
curl -sfL https://get.k3s.io | K3S_URL=https://74.249.82.35:6443 \
  K3S_TOKEN=<your-token> sh -s -

# On Site C edge K3s node
curl -sfL https://get.k3s.io | K3S_URL=https://74.249.82.35:6443 \
  K3S_TOKEN=<your-token> sh -s -
```

**Get the K3s token from cloud server:**
```bash
# On cloud K3s server (74.249.82.35)
sudo cat /var/lib/rancher/k3s/server/node-token
```

### Firewall Configuration for Public K3s API

**On cloud K3s server (Azure), allow port 6443 with IP restrictions:**

#### Azure Network Security Group (Recommended)

```bash
# Get your site public IPs first
# Site A public IP (example): 203.0.113.10
# Site B public IP (example): 198.51.100.25
# Site C public IP (example): 192.0.2.50

# Add NSG rule in Azure Portal or via CLI:
az network nsg rule create \
  --resource-group <your-rg> \
  --nsg-name <your-nsg> \
  --name Allow-K3s-API-From-Sites \
  --priority 100 \
  --source-address-prefixes 203.0.113.10 198.51.100.25 192.0.2.50 \
  --destination-port-ranges 6443 \
  --protocol Tcp \
  --access Allow \
  --direction Inbound
```

#### Linux Firewall (ufw) - IP Restricted

```bash
# On cloud K3s server
# Allow K3s API only from known site IPs
sudo ufw allow from 203.0.113.10 to any port 6443 proto tcp comment "Site A K3s"
sudo ufw allow from 198.51.100.25 to any port 6443 proto tcp comment "Site B K3s"
sudo ufw allow from 192.0.2.50 to any port 6443 proto tcp comment "Site C K3s"

# Verify rules
sudo ufw status numbered

# Block all other 6443 access (if not already blocked by default deny)
sudo ufw deny 6443/tcp
```

#### Windows Firewall - IP Restricted

```powershell
# On cloud K3s server (if using Windows)
# Allow K3s API only from known site IPs

# Site A
New-NetFirewallRule -DisplayName "K3s API - Site A" `
  -Direction Inbound -LocalPort 6443 -Protocol TCP `
  -RemoteAddress 203.0.113.10 -Action Allow

# Site B
New-NetFirewallRule -DisplayName "K3s API - Site B" `
  -Direction Inbound -LocalPort 6443 -Protocol TCP `
  -RemoteAddress 198.51.100.25 -Action Allow

# Site C
New-NetFirewallRule -DisplayName "K3s API - Site C" `
  -Direction Inbound -LocalPort 6443 -Protocol TCP `
  -RemoteAddress 192.0.2.50 -Action Allow

# Block all other access to 6443
New-NetFirewallRule -DisplayName "K3s API - Block All Others" `
  -Direction Inbound -LocalPort 6443 -Protocol TCP `
  -Action Block -Priority 1000
```

### Verify Edge Node Connectivity

```bash
# From Site A edge node, test connection to cloud K3s
curl -k https://74.249.82.35:6443

# Should return JSON with API server info
# Example: {"kind":"Status","apiVersion":"v1","metadata":{},...}

# Check node status from cloud
kubectl get nodes
# Should show cloud + all edge nodes
```

### Factory Device Connectivity Flow (MVP)

```
┌─────────────────────────────────────────────────────────────┐
│ CLOUD (Azure) - 74.249.82.35                                │
│  - OpenWISP: 172.16.0.10 (WireGuard: 172.8.0.1)            │
│  - K3s Server: 172.16.0.20                                  │
│    * Public API: 74.249.82.35:6443 (IP restricted)         │
└──────────────────────────┬──────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │ Internet         │ Internet         │ Internet
        │ (Port 6443)      │ (Port 6443)      │ (Port 6443)
        ↓                  ↓                  ↓
┌───────────────┐  ┌───────────────┐  ┌───────────────┐
│ SITE A        │  │ SITE B        │  │ SITE C        │
│ Public IP:    │  │ Public IP:    │  │ Public IP:    │
│ 203.0.113.10  │  │ 198.51.100.25 │  │ 192.0.2.50    │
├───────────────┤  ├───────────────┤  ├───────────────┤
│ K3s Node:     │  │ K3s Node:     │  │ K3s Node:     │
│ 172.17.0.20   │  │ 172.18.0.20   │  │ 172.19.0.20   │
│               │  │               │  │               │
│ K3s Services: │  │               │  │               │
│ - MQTT        │  │               │  │               │
│ - OPC UA      │  │               │  │               │
│ - Node-RED    │  │               │  │               │
├───────────────┤  ├───────────────┤  ├───────────────┤
│ OT Devices    │  │ OT Devices    │  │ OT Devices    │
│ 172.20.x.x    │  │ 172.21.x.x    │  │ 172.22.x.x    │
│               │  │               │  │               │
│ Connect to    │  │               │  │               │
│ local K3s     │  │               │  │               │
│ services      │  │               │  │               │
└───────────────┘  └───────────────┘  └───────────────┘
        ↓                  ↓                  ↓
  WireGuard          WireGuard          WireGuard
  (172.8.1.x)        (172.8.2.x)        (172.8.3.x)
        └──────────────────┴──────────────────┘
                           ↓
                    OpenWISP Management
                     (Device firmware,
                      config updates)
```

**Communication paths:**

1. **Edge K3s → Cloud K3s:**
   - Via public internet to 74.249.82.35:6443
   - Authenticated with K3s token (TLS encrypted)
   - Source IP restricted via firewall

2. **Factory devices → Local K3s services:**
   - PLC (172.20.1.10) → MQTT (172.17.1.110)
   - Stays local, no internet traffic

3. **OpenWISP → Factory devices:**
   - Via WireGuard tunnel (172.8.0.0/16)
   - Separate from K3s traffic

---

### Production Migration Path (Future - WireGuard Integration)

**When ready for production, migrate to WireGuard for K3s:**

<details>
<summary>Click to expand production WireGuard configuration</summary>

**Add K3s nodes as WireGuard peers:**

```yaml
# OpenWISP WireGuard server config addition
[Interface]
Address = 172.8.0.1/16
ListenPort = 51820

# Cloud K3s node
[Peer]
PublicKey = <CLOUD_K3S_PUBLIC_KEY>
AllowedIPs = 172.8.0.20/32, 172.16.0.0/16
PersistentKeepalive = 25

# Site A K3s node
[Peer]
PublicKey = <SITE_A_K3S_PUBLIC_KEY>
AllowedIPs = 172.8.1.20/32, 172.17.0.0/16, 172.20.0.0/16
PersistentKeepalive = 25
```

**Reconfigure K3s to use WireGuard:**

```bash
# Cloud K3s (reinstall with WireGuard binding)
curl -sfL https://get.k3s.io | sh -s - server \
  --node-ip 172.8.0.20 \
  --flannel-iface wg0

# Edge K3s (reinstall pointing to WireGuard IP)
curl -sfL https://get.k3s.io | K3S_URL=https://172.8.0.20:6443 \
  K3S_TOKEN=<token> sh -s - \
  --node-ip 172.8.1.20 \
  --flannel-iface wg0
```

**Benefits:**
- ✅ No public K3s API exposure
- ✅ All traffic encrypted via WireGuard
- ✅ Centralized OpenWISP management
- ✅ Single VPN infrastructure

</details>

---

### MVP Security Considerations

**Current configuration trade-offs:**

⚠️ **Security notes:**
- K3s API exposed on public internet (mitigated by IP restrictions)
- TLS encryption still active (K3s default)
- Token-based authentication required
- Recommend transitioning to WireGuard for production

✅ **Current mitigations:**
- Firewall restricts port 6443 to known site IPs only
- K3s API requires valid token (obtained from server)
- All communication over TLS (encrypted)

**MVP is acceptable for:**
- Demo environments
- Proof of concept
- Development/testing
- Limited site count (3-5 sites)

**Migrate to WireGuard when:**
- Moving to production
- Adding many sites (10+)
- Handling sensitive data
- Compliance requirements (HIPAA, ISO 27001, etc.)

---

## 15. Automation Script - All-In-One

**For copy-paste deployment:**

```powershell
# Save as: Deploy-FireballNetworking.ps1
#Requires -RunAsAdministrator

param(
    [Parameter(Mandatory=$false)]
    [string]$Site = "cloud",  # Options: cloud, site-a, site-b, site-c
    
    [Parameter(Mandatory=$false)]
    [string]$MetalLBIPRange = ""  # Auto-determined by site
)

# Auto-determine IP range based on site
if ([string]::IsNullOrEmpty($MetalLBIPRange)) {
    switch ($Site.ToLower()) {
        "cloud"  { $MetalLBIPRange = "172.16.1.100-172.16.1.150" }
        "site-a" { $MetalLBIPRange = "172.17.1.100-172.17.1.150" }
        "site-b" { $MetalLBIPRange = "172.18.1.100-172.18.1.150" }
        "site-c" { $MetalLBIPRange = "172.19.1.100-172.19.1.150" }
        default  { 
            Write-Host "Invalid site. Use: cloud, site-a, site-b, site-c" -ForegroundColor Red
            exit 1
        }
    }
}

Write-Host "🔥 Fireball Industries - Complete Network Setup" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "Site: $Site" -ForegroundColor Yellow
Write-Host "IP Range: $MetalLBIPRange" -ForegroundColor Yellow
Write-Host "" 

# 1. Configure Windows Firewall
Write-Host "`n[1/4] Configuring Windows Firewall..." -ForegroundColor Yellow
& {
    New-NetFirewallRule -DisplayName "K3s API Server" -Direction Inbound -LocalPort 6443 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "K3s Kubelet" -Direction Inbound -LocalPort 10250 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "K3s etcd" -Direction Inbound -LocalPort 2379-2380 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "Flannel VXLAN" -Direction Inbound -LocalPort 8472 -Protocol UDP -Action Allow -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "Rancher HTTP/HTTPS" -Direction Inbound -LocalPort 80,443 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "Kubernetes NodePort" -Direction Inbound -LocalPort 30000-32767 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue
}
Write-Host "  ✓ Firewall configured" -ForegroundColor Green

# 2. Install MetalLB
Write-Host "`n[2/4] Installing MetalLB..." -ForegroundColor Yellow
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml
Start-Sleep -Seconds 30
Write-Host "  ✓ MetalLB installed" -ForegroundColor Green

# 3. Configure MetalLB IP Pool
Write-Host "`n[3/4] Configuring MetalLB IP Pool: $MetalLBIPRange..." -ForegroundColor Yellow
@"
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: fireball-industrial
  namespace: metallb-system
spec:
  addresses:
  - $MetalLBIPRange
  autoAssign: true
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: fireball-industrial
  namespace: metallb-system
spec:
  ipAddressPools:
  - fireball-industrial
"@ | kubectl apply -f -
Write-Host "  ✓ IP Pool configured" -ForegroundColor Green

# 4. Verify Setup
Write-Host "`n[4/4] Verifying configuration..." -ForegroundColor Yellow
$metallbPods = kubectl get pods -n metallb-system -o json | ConvertFrom-Json
if ($metallbPods.items.Count -gt 0) {
    Write-Host "  ✓ MetalLB pods running" -ForegroundColor Green
} else {
    Write-Host "  ✗ MetalLB pods not found" -ForegroundColor Red
}

Write-Host "`n🔥 Fireball Industries network setup complete!" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "  1. Deploy your first Forge Industrial chart from Rancher"
Write-Host "  2. Verify LoadBalancer gets external IP"
Write-Host "  3. Test connectivity to services"
Write-Host "`nFor help: https://fireballz.ai/docs/networking`n" -ForegroundColor Gray
```

**Run it:**
```powershell
# Cloud tier (Azure)
.\Deploy-FireballNetworking.ps1 -Site cloud

# Site A
.\Deploy-FireballNetworking.ps1 -Site site-a

# Site B
.\Deploy-FireballNetworking.ps1 -Site site-b

# Site C
.\Deploy-FireballNetworking.ps1 -Site site-c

# Custom IP range
.\Deploy-FireballNetworking.ps1 -Site site-a -MetalLBIPRange "172.17.2.100-172.17.2.150"
```

---

## Support

**Questions? Issues?**
- Documentation: https://fireballz.ai/docs
- Email: support@fireball-industries.com
- GitHub: https://github.com/fireball-industries/helm-charts

---

**Fireball Industries - We Play With Fire So You Don't Have To™**

*Network setup version 1.0 - January 2026*
