# Fireball CODESYS Edge Gateway - PLC Integration

**Production-ready CODESYS Edge Gateway for Linux on Kubernetes/K3s.**

Extended gateway connecting CODESYS Automation Server to PLCs in local networks. Because managing PLC connections via VPN like it's 1995 is getting old. 🏭

---

## 🌉 What is CODESYS Edge Gateway?

**CODESYS Edge Gateway** is an extended gateway that enables remote access and management of CODESYS PLCs through the CODESYS Automation Server:

- **Remote PLC Access** - Connect to PLCs in local networks from centralized Automation Server
- **Network Bridging** - Bridge between cloud/data center and factory floor networks
- **Secure Communication** - SSL/TLS encrypted connections to Automation Server
- **Automatic Discovery** - UDP broadcast discovery of PLCs on local subnets
- **Multi-Protocol Support** - CODESYS protocol, OPC UA, Modbus
- **Edge Deployment** - Run on industrial PCs, edge gateways, or Kubernetes clusters

**Perfect for:** Factory automation, distributed PLC management, edge computing, remote programming access.

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│ Cloud / Data Center                                         │
│                                                              │
│  ┌──────────────────────────────────┐                       │
│  │ CODESYS Automation Server        │                       │
│  │ https://automation-server:4410   │                       │
│  └────────────┬─────────────────────┘                       │
│               │ SSL/TLS Connection                          │
│               │ (Port 4410)                                 │
└───────────────┼─────────────────────────────────────────────┘
                │
                │ Internet / WAN
                │
┌───────────────┼─────────────────────────────────────────────┐
│ Factory Floor │                                             │
│               │                                             │
│  ┌────────────▼──────────────────┐                         │
│  │ CODESYS Edge Gateway          │                         │
│  │ (Kubernetes Pod)              │                         │
│  │ Port 2455 (Gateway)           │                         │
│  │ Port 1217 (PLC Communication) │                         │
│  └────────────┬──────────────────┘                         │
│               │                                             │
│               │ Local Network (UDP Discovery)              │
│               │                                             │
│  ┌────────────▼──────┐  ┌──────────────┐  ┌─────────────┐ │
│  │ PLC 1              │  │ PLC 2        │  │ PLC 3       │ │
│  │ 192.168.1.10:1217  │  │ 192.168.1.11 │  │ 192.168.1.12│ │
│  └────────────────────┘  └──────────────┘  └─────────────┘ │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## 🚀 Quick Start

### Standard Factory Deployment
Deploy gateway with MetalLB LoadBalancer:

```bash
helm upgrade --install factory-gateway fireball-industries/codesys-edge-gateway \
  --namespace codesys-gateway \
  --create-namespace \
  --set gateway.automationServerUrl="https://automation.example.com:4410" \
  --set gateway.automationServer.username="gateway-user" \
  --set gateway.automationServer.password="your-secure-password" \
  --set gateway.name="Factory-Gateway-1" \
  --set service.type=LoadBalancer
```

**Verify gateway connection:**
```bash
# Check pod status
kubectl get pods -n codesys-gateway

# Check service IP
kubectl get service -n codesys-gateway

# View gateway logs
kubectl logs -n codesys-gateway -l app=codesys-edge-gateway
```

---

### Edge Deployment (K3s)
Lightweight deployment for edge devices:

```bash
helm upgrade --install edge-gateway fireball-industries/codesys-edge-gateway \
  --namespace codesys-gateway \
  --create-namespace \
  --set gateway.automationServerUrl="https://automation.cloud.com:4410" \
  --set gateway.automationServer.username="edge-gateway" \
  --set gateway.automationServer.password="secure-password" \
  --set service.type=NodePort \
  --set persistence.storageClass=local-path \
  --set resources.requests.cpu=100m \
  --set resources.requests.memory=128Mi
```

---

### Host Network Mode (PLC Discovery)
Enable host network for UDP broadcast discovery:

```bash
helm upgrade --install gateway fireball-industries/codesys-edge-gateway \
  --namespace codesys-gateway \
  --create-namespace \
  --set gateway.automationServerUrl="https://automation.example.com:4410" \
  --set gateway.automationServer.username="gateway" \
  --set gateway.automationServer.password="password" \
  --set network.hostNetwork=true \
  --set gateway.enablePlcDiscovery=true \
  --set gateway.discoveryInterval=30
```

**⚠️ Security Note:** Host network bypasses NetworkPolicy. Use only when necessary for UDP broadcast.

---

## 🔌 Automation Server Connection

### SSL/TLS Connection (Recommended)
Secure connection to Automation Server:

**Configuration:**
```yaml
gateway:
  automationServerUrl: "https://automation.example.com:4410"
  enableSsl: true
  automationServer:
    username: "gateway-user"
    password: "secure-password"
```

**Benefits:**
- Encrypted communication
- Certificate validation
- Secure credential transmission

---

### Non-SSL Connection (Testing Only)
Unencrypted connection for testing:

**Configuration:**
```yaml
gateway:
  automationServerUrl: "http://automation.example.com:4410"
  enableSsl: false
```

**⚠️ Warning:** Only use for testing in isolated networks. Production deployments must use SSL/TLS.

---

### Existing Secret for Credentials
Use Kubernetes Secret for credential management:

**Create Secret:**
```bash
kubectl create secret generic gateway-credentials \
  --from-literal=username=gateway-user \
  --from-literal=password=your-secure-password \
  -n codesys-gateway
```

**Configuration:**
```yaml
gateway:
  automationServer:
    existingSecret: gateway-credentials
```

---

## 🔍 PLC Discovery

### Automatic Discovery (UDP Broadcast)
Discover PLCs on local subnet:

**Configuration:**
```yaml
gateway:
  enablePlcDiscovery: true
  discoveryInterval: 30  # seconds
  networkInterface: eth0
```

**Requirements:**
- PLCs must respond to UDP broadcast on ports 1740-1743
- Gateway must be on same subnet as PLCs (or use host network)
- Firewall allows UDP broadcast

**Discovery process:**
1. Gateway sends UDP broadcast every 30 seconds
2. PLCs respond with device information
3. Gateway registers PLCs with Automation Server
4. PLCs become visible in CODESYS IDE

---

### Manual PLC Registration
Manually register PLCs in Automation Server:

**Configuration:**
```yaml
gateway:
  enablePlcDiscovery: false
```

**Steps:**
1. Deploy gateway without discovery
2. Access Automation Server web interface
3. Manually add PLC devices with IP addresses
4. Gateway provides network access to PLCs

---

## 🌐 Network Configuration

### LoadBalancer (Recommended - Production)
Dedicated IP for gateway:

**Configuration:**
```yaml
service:
  type: LoadBalancer
  annotations:
    metallb.universe.tf/address-pool: factory-network
```

**Access:**
- Gateway port: `<load-balancer-ip>:2455`
- PLC port: `<load-balancer-ip>:1217`

**Best for:**
- Production environments
- MetalLB on-premise
- Cloud load balancers (AWS NLB, GCP LB)

---

### NodePort (Edge Deployments)
Direct access via node IP:

**Configuration:**
```yaml
service:
  type: NodePort
  gatewayPort: 2455
  plcPort: 1217
```

**Access:**
- Gateway port: `<node-ip>:30455` (auto-assigned)
- PLC port: `<node-ip>:31217` (auto-assigned)

**Best for:**
- Single-node K3s
- Edge gateways
- Testing environments

---

### Host Network (Special Cases)
Use host network stack:

**Configuration:**
```yaml
network:
  hostNetwork: true
  dnsPolicy: ClusterFirstWithHostNet
```

**When to use:**
- UDP broadcast discovery required
- Gateway must be on same IP subnet as PLCs
- Legacy PLC firmware with strict network requirements

**⚠️ Security:**
- Bypasses Kubernetes NetworkPolicy
- Pod gets host IP address
- All ports exposed on host

---

## 📂 Persistent Storage

### Gateway Configuration Storage
Persistent volume for gateway state:

**Configuration:**
```yaml
persistence:
  enabled: true
  size: 1Gi
  storageClass: local-path  # K3s default
  mountPath: /var/opt/codesys-gateway
```

**Stored data:**
- Gateway configuration
- PLC discovery cache
- Connection state
- SSL certificates
- Authentication tokens

**⚠️ Important:** Persistent storage required for gateway to maintain connections across restarts.

---

## 🔐 Security Best Practices

### Network Segmentation
Isolate gateway with NetworkPolicy:

**Configuration:**
```yaml
networkPolicy:
  enabled: true
  ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            name: codesys-plc
      ports:
      - protocol: TCP
        port: 2455
      - protocol: TCP
        port: 1217
```

**Benefits:**
- Restrict access to gateway ports
- Limit egress to Automation Server
- Defense-in-depth security

---

### Credential Management
Use Kubernetes Secrets for passwords:

**Never hardcode passwords in values.yaml!**

**Create Secret:**
```bash
kubectl create secret generic gateway-creds \
  --from-literal=username=gateway \
  --from-literal=password=$(openssl rand -base64 32) \
  -n codesys-gateway
```

**Reference in chart:**
```yaml
gateway:
  automationServer:
    existingSecret: gateway-creds
```

---

### SSL/TLS Certificate Validation
Verify Automation Server certificates:

**Configuration:**
```yaml
gateway:
  enableSsl: true
  # For self-signed certificates in testing:
  # customConfig:
  #   verifyServerCertificate: false
```

**Production:** Always use valid SSL certificates (Let's Encrypt, enterprise CA).

---

## 📊 Monitoring & Observability

### Prometheus Metrics
Export gateway metrics:

**Configuration:**
```yaml
metrics:
  enabled: true
  port: 9090
  path: /metrics
  serviceMonitor:
    enabled: true
    interval: 30s
```

**Metrics exposed:**
- `codesys_gateway_plc_connections_active` - Active PLC connections
- `codesys_gateway_automation_server_connected` - AS connection status
- `codesys_gateway_discovery_plc_count` - Discovered PLCs
- `codesys_gateway_bytes_sent_total` - Network traffic sent
- `codesys_gateway_bytes_received_total` - Network traffic received

---

### Logging
JSON-formatted logs for parsing:

**Configuration:**
```yaml
logging:
  level: INFO
  format: json
```

**Log levels:**
- **DEBUG** - Detailed connection logs, discovery packets
- **INFO** - Connection events, PLC discovery (default)
- **WARN** - Connection issues, timeouts
- **ERROR** - Critical failures, authentication errors

**View logs:**
```bash
kubectl logs -n codesys-gateway -l app=codesys-edge-gateway -f
```

---

## 🏥 Health Checks

### Liveness Probe
Restart pod if gateway hangs:

**Configuration:**
```yaml
livenessProbe:
  tcpSocket:
    port: gateway
  initialDelaySeconds: 20
  periodSeconds: 10
  failureThreshold: 3
```

**Checks:** TCP connection to gateway port 2455

---

### Readiness Probe
Remove from service if not ready:

**Configuration:**
```yaml
readinessProbe:
  tcpSocket:
    port: gateway
  initialDelaySeconds: 15
  periodSeconds: 10
  failureThreshold: 3
```

**Ensures:** Gateway only receives traffic when connected to Automation Server

---

### Startup Probe
Allow slow gateway startup:

**Configuration:**
```yaml
startupProbe:
  tcpSocket:
    port: gateway
  initialDelaySeconds: 10
  periodSeconds: 5
  failureThreshold: 12
```

**Timeout:** Up to 60 seconds for gateway to start

---

## 🆘 Troubleshooting

### Gateway Not Connecting to Automation Server
```bash
# Check pod status
kubectl get pods -n codesys-gateway

# View logs for connection errors
kubectl logs -n codesys-gateway -l app=codesys-edge-gateway

# Common issues:
# 1. Wrong Automation Server URL - verify URL and port 4410
# 2. Invalid credentials - check username/password Secret
# 3. SSL certificate error - verify enableSsl setting
# 4. Network blocked - check firewall rules for port 4410
```

**Test connectivity:**
```bash
# From gateway pod
kubectl exec -it -n codesys-gateway <pod-name> -- curl -k https://automation.example.com:4410

# Should return connection or certificate error (not timeout)
```

---

### PLCs Not Discovered
```bash
# Check discovery logs
kubectl logs -n codesys-gateway -l app=codesys-edge-gateway | grep -i discovery

# Verify discovery enabled
kubectl get configmap -n codesys-gateway -o yaml | grep enablePlcDiscovery

# Common issues:
# 1. Wrong subnet - gateway not on same network as PLCs
# 2. Host network required - enable network.hostNetwork=true
# 3. Firewall blocking UDP - allow ports 1740-1743
# 4. PLCs not responding to broadcast - check PLC network settings
```

**Manual test:**
```bash
# Test UDP broadcast from gateway pod
kubectl exec -it -n codesys-gateway <pod-name> -- nmap -sU -p 1740-1743 <plc-ip>
```

---

### Service IP Not Assigned (LoadBalancer)
```bash
# Check service status
kubectl get service -n codesys-gateway

# If EXTERNAL-IP is <pending>:
# 1. Verify MetalLB installed (kubectl get pods -n metallb-system)
# 2. Check MetalLB address pool (kubectl get ipaddresspool -n metallb-system)
# 3. Verify annotations (kubectl get service -n codesys-gateway -o yaml)

# For cloud providers:
# - AWS: Check security groups and ELB quotas
# - GCP: Check firewall rules and forwarding rules
# - Azure: Check NSG and load balancer configuration
```

---

### High Memory Usage
```bash
# Check actual memory usage
kubectl top pod -n codesys-gateway

# Gateway memory scales with:
# - Number of PLCs (each PLC ~5-10MB)
# - Connection frequency
# - Discovery interval

# Increase limits if needed:
helm upgrade factory-gateway fireball-industries/codesys-edge-gateway \
  --reuse-values \
  --set resources.limits.memory=1Gi
```

---

### Connection Drops / Timeouts
```bash
# Check session affinity
kubectl get service -n codesys-gateway -o yaml | grep sessionAffinity

# Should be: sessionAffinity: ClientIP

# If not set:
helm upgrade factory-gateway fireball-industries/codesys-edge-gateway \
  --reuse-values \
  --set service.sessionAffinity=ClientIP

# Check network policy
kubectl get networkpolicy -n codesys-gateway

# If too restrictive, temporarily disable:
helm upgrade factory-gateway fireball-industries/codesys-edge-gateway \
  --reuse-values \
  --set networkPolicy.enabled=false
```

---

## 📚 Use Case Examples

### 1. Single Factory Gateway
**Scenario:** Connect 10 PLCs in one factory to cloud Automation Server

**Configuration:**
```yaml
gateway:
  automationServerUrl: "https://automation.cloud.com:4410"
  automationServer:
    username: "factory-1-gateway"
    password: "secure-password"
  name: "Factory-1-Gateway"
  enablePlcDiscovery: true
  networkInterface: eth0
service:
  type: LoadBalancer
persistence:
  enabled: true
  size: 1Gi
```

**Hardware:** Industrial PC or edge gateway (2 cores, 512MB RAM)  
**PLCs:** 10 PLCs on 192.168.1.0/24 subnet  
**Access:** LoadBalancer IP in factory network  

---

### 2. Multi-Site Deployment
**Scenario:** 5 factories, each with dedicated gateway

**Configuration per site:**
```yaml
gateway:
  automationServerUrl: "https://automation.central.com:4410"
  automationServer:
    username: "site-<N>-gateway"
  name: "Site-<N>-Gateway"
  enablePlcDiscovery: true
service:
  type: LoadBalancer
  annotations:
    metallb.universe.tf/address-pool: site-<N>-pool
networkPolicy:
  enabled: true  # Isolate sites
```

**Deployment:**
```bash
# Deploy to each site namespace
for site in site-1 site-2 site-3 site-4 site-5; do
  helm upgrade --install $site-gateway fireball-industries/codesys-edge-gateway \
    --namespace $site \
    --create-namespace \
    --set gateway.name="${site}-Gateway" \
    --set gateway.automationServer.username="${site}-gateway"
done
```

---

### 3. Edge K3s Deployment
**Scenario:** Raspberry Pi 4 running K3s at remote site

**Configuration:**
```yaml
image:
  architecture: arm64
gateway:
  automationServerUrl: "https://automation.hq.com:4410"
service:
  type: NodePort
persistence:
  storageClass: local-path
  size: 500Mi
resources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 200m
    memory: 256Mi
network:
  hostNetwork: true  # For PLC discovery
```

**Hardware:** Raspberry Pi 4 (4GB RAM)  
**Network:** WiFi or Ethernet, DHCP  
**PLCs:** 3-5 PLCs on same subnet  

---

## 📖 Additional Resources

- **CODESYS Gateway Documentation:** https://help.codesys.com/
- **Automation Server Setup:** https://store.codesys.com/
- **Network Configuration:** See `DEPLOYMENT.md` in chart
- **Multi-Tenant Guide:** See `MULTI-TENANT.md` in chart

---

## 📝 License

**Chart License:** Apache 2.0 - Free to use and modify

**CODESYS Gateway License:** Commercial license required from CODESYS

---

## 🎓 Getting Started Checklist

**Before deployment:**
- [ ] CODESYS Automation Server accessible (URL and port 4410)
- [ ] Gateway user credentials created in Automation Server
- [ ] Kubernetes cluster ready (K3s or full Kubernetes)
- [ ] MetalLB or LoadBalancer provider installed (for LoadBalancer service)
- [ ] Network subnet identified (for PLC discovery)
- [ ] Storage class available (local-path for K3s)

**After deployment:**
- [ ] Verify pod running and healthy
- [ ] Check gateway connection to Automation Server
- [ ] Verify service IP assigned (LoadBalancer) or NodePort accessible
- [ ] Test PLC discovery (if enabled)
- [ ] Manually register PLCs in Automation Server (if discovery disabled)
- [ ] Test CODESYS IDE connection through gateway
- [ ] Configure monitoring (Prometheus, logs)
- [ ] Set up NetworkPolicy for production
- [ ] Document gateway IP and port for users
- [ ] Test backup/restore procedures

---

**Remember:** Gateway requires persistent storage to maintain connections across restarts. Always enable persistence.enabled=true. For PLC discovery to work, gateway must be on same subnet as PLCs (use host network or LoadBalancer with factory subnet IP). Use SSL/TLS for Automation Server connection in production. 🔐

*Pro tip:* Start with NodePort service for testing, then switch to LoadBalancer for production. Enable PLC discovery only if you have 5+ PLCs (manual registration is faster for small deployments). Use session affinity (ClientIP) to maintain stable connections. Monitor gateway logs during initial deployment to troubleshoot connectivity issues. 🏭

**Happy automating!** 🤖

---

*Created by Patrick Ryan - Fireball Industries*

*"Because managing PLC connections via VPN like it's 1995 is getting old."*
