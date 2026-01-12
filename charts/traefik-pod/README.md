# Traefik Ingress Controller - Industrial Edition

Production-ready Traefik reverse proxy and ingress controller optimized for industrial IoT, factory automation, and edge computing environments.

## Why Traefik for Industrial?

🏭 **Industrial Protocol Support** - Route MQTT, Modbus, OPC-UA, and HTTP/HTTPS traffic  
🔐 **Automatic SSL** - Let's Encrypt integration for secure communications  
📊 **Real-time Dashboard** - Monitor routing and performance  
🚀 **Zero Downtime** - Hot reload configuration without interrupting traffic  
⚡ **Edge Optimized** - Minimal resource footprint for edge deployments  
🔄 **Auto Discovery** - Automatically discovers and routes to new services  
🛡️ **Security Built-in** - Rate limiting, IP whitelisting, authentication  

## Quick Start

### Basic Installation

```bash
helm install traefik ./traefik-pod
```

Access the dashboard at: `http://<YOUR-IP>:9000/dashboard/`

### Production Installation with Let's Encrypt

```bash
helm install traefik ./traefik-pod \
  --set tls.certResolvers.letsencrypt.enabled=true \
  --set tls.certResolvers.letsencrypt.email=admin@factory.com \
  --set ports.web.redirectTo=websecure \
  --set service.type=LoadBalancer
```

## Common Use Cases

### 1. Route Traffic to Industrial Pods

After installing Traefik, your other pods automatically get routing:

**Node-RED Dashboard:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: node-red
spec:
  rules:
    - host: node-red.factory.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: node-red
                port:
                  number: 1880
```

Access at: `http://node-red.factory.local`

**Grafana Dashboards:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana
spec:
  rules:
    - host: grafana.factory.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: grafana
                port:
                  number: 3000
```

### 2. MQTT Load Balancing

Route MQTT traffic to multiple brokers:

```bash
helm install traefik ./traefik-pod \
  --set ports.mqtt.enabled=true \
  --set ports.mqtts.enabled=true
```

Then create IngressRoute for MQTT:
```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRouteTCP
metadata:
  name: mqtt-route
spec:
  entryPoints:
    - mqtt
  routes:
    - match: HostSNI(`*`)
      services:
        - name: mosquitto-mqtt
          port: 1883
```

### 3. Edge Gateway with Multiple Services

Deploy Traefik as a DaemonSet on edge nodes:

```bash
helm install traefik ./traefik-pod \
  --set deployment.kind=DaemonSet \
  --set deployment.resourcePreset=edge \
  --set nodeSelector.node-role\\.kubernetes\\.io/edge=true
```

This runs one Traefik instance on each edge node, routing:
- MQTT → mosquitto-mqtt
- HTTP APIs → node-red, influxdb
- Modbus TCP → modbus gateway
- OPC-UA → opc-ua server

### 4. Multi-Tenant Factory

Route different departments to different services:

```yaml
# Production Line 1
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: line1-dashboard
spec:
  rules:
    - host: line1.factory.local
      http:
        paths:
          - backend:
              service:
                name: line1-dashboard
                port:
                  number: 80

# Production Line 2
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: line2-dashboard
spec:
  rules:
    - host: line2.factory.local
      http:
        paths:
          - backend:
              service:
                name: line2-dashboard
                port:
                  number: 80
```

### 5. Secure SCADA Access

Add authentication to SCADA web interfaces:

```yaml
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: basic-auth
spec:
  basicAuth:
    secret: auth-secret
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: scada
  annotations:
    traefik.ingress.kubernetes.io/router.middlewares: default-basic-auth@kubernetescrd
spec:
  rules:
    - host: scada.factory.local
      http:
        paths:
          - path: /
            backend:
              service:
                name: scada-hmi
                port:
                  number: 8080
```

## Configuration Presets

| Preset | CPU | Memory | Use Case |
|--------|-----|--------|----------|
| edge | 100m-200m | 128Mi-256Mi | Single edge node, <50 routes |
| standard | 200m-500m | 256Mi-512Mi | Multi-node cluster, <200 routes |
| enterprise | 500m-1000m | 512Mi-1Gi | HA cluster, >200 routes |

## Dashboard Access

The Traefik dashboard shows:
- Active routes and services
- Real-time traffic metrics
- Health checks
- TLS certificate status

Access methods:

**Port Forward:**
```bash
kubectl port-forward svc/traefik 9000:9000
# Visit http://localhost:9000/dashboard/
```

**Via Domain:**
```bash
helm install traefik ./traefik-pod \
  --set traefik.dashboard.enabled=true \
  --set traefik.dashboard.expose=true \
  --set traefik.dashboard.domain=traefik.factory.local
```

## SSL/TLS Configuration

### Let's Encrypt (Recommended)

Automatically obtain and renew SSL certificates:

```bash
helm install traefik ./traefik-pod \
  --set tls.certResolvers.letsencrypt.enabled=true \
  --set tls.certResolvers.letsencrypt.email=admin@factory.com \
  --set tls.certResolvers.letsencrypt.challengeType=httpChallenge
```

Then add to your Ingress:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-service
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt
spec:
  tls:
    - hosts:
        - myservice.factory.com
      secretName: myservice-tls
  rules:
    - host: myservice.factory.com
      # ... routes
```

### Custom Certificates

```bash
# Create TLS secret
kubectl create secret tls custom-tls \
  --cert=path/to/cert.crt \
  --key=path/to/cert.key

# Install Traefik
helm install traefik ./traefik-pod \
  --set tls.defaultCertificate.enabled=true \
  --set tls.defaultCertificate.secretName=custom-tls
```

## Industrial Protocol Routing

### MQTT Broker

```bash
helm install traefik ./traefik-pod \
  --set ports.mqtt.enabled=true \
  --set ports.mqtts.enabled=true
```

### Modbus TCP

```bash
helm install traefik ./traefik-pod \
  --set ports.modbus.enabled=true
```

Route to PLC:
```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRouteTCP
metadata:
  name: modbus-plc
spec:
  entryPoints:
    - modbus
  routes:
    - match: HostSNI(`*`)
      services:
        - name: plc-gateway
          port: 502
```

### OPC-UA Server

```bash
helm install traefik ./traefik-pod \
  --set ports.opcua.enabled=true
```

## High Availability

Deploy with redundancy:

```bash
helm install traefik ./traefik-pod \
  --set ha.enabled=true \
  --set ha.replicas=3 \
  --set ha.podDisruptionBudget.enabled=true \
  --set deployment.resourcePreset=enterprise
```

Features:
- 3 Traefik instances
- Automatic failover
- Load distribution
- Pod disruption budget

## Monitoring

### Prometheus Integration

```bash
helm install traefik ./traefik-pod \
  --set traefik.metrics.prometheus.enabled=true \
  --set monitoring.serviceMonitor.enabled=true
```

Metrics available:
- `traefik_entrypoint_requests_total` - Request count by entrypoint
- `traefik_service_requests_total` - Request count by service
- `traefik_entrypoint_request_duration_seconds` - Request latency
- `traefik_backend_requests_total` - Backend health

### Grafana Dashboard

Import Traefik official dashboard: https://grafana.com/grafana/dashboards/4475

## Security Features

### Rate Limiting

Prevent abuse:
```bash
helm install traefik ./traefik-pod \
  --set middleware.rateLimit.enabled=true \
  --set middleware.rateLimit.average=100 \
  --set middleware.rateLimit.burst=50
```

### IP Whitelisting

Restrict access to factory network:
```bash
helm install traefik ./traefik-pod \
  --set middleware.ipWhitelist.enabled=true \
  --set middleware.ipWhitelist.sourceRange='{192.168.1.0/24,10.0.0.0/8}'
```

### Security Headers

```bash
helm install traefik ./traefik-pod \
  --set middleware.headers.enabled=true \
  --set middleware.headers.sslRedirect=true
```

## Troubleshooting

### Check Traefik Status

```bash
# View pods
kubectl get pods -l app.kubernetes.io/name=traefik

# View logs
kubectl logs -l app.kubernetes.io/name=traefik -f

# Check service
kubectl get svc traefik
```

### Test Routing

```bash
# Get LoadBalancer IP
export TRAEFIK_IP=$(kubectl get svc traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test HTTP
curl -H "Host: myservice.local" http://$TRAEFIK_IP

# Test HTTPS
curl -k -H "Host: myservice.local" https://$TRAEFIK_IP
```

### Common Issues

**503 Service Unavailable**
- Check backend service is running: `kubectl get svc`
- Verify Ingress targets correct service name and port

**Let's Encrypt not working**
- Ensure ports 80/443 are accessible from internet
- Check email address is valid
- View certificate status in dashboard

**Dashboard not accessible**
- Check `traefik.dashboard.expose=true`
- Verify port 9000 is exposed in service

## Integration Examples

See [examples/](examples/) directory for:
- Node-RED routing
- MQTT load balancing  
- InfluxDB API gateway
- Grafana with auth
- Home Assistant ingress
- Multi-service factory setup

## Configuration Reference

See [values.yaml](values.yaml) for complete configuration options.

## License

Apache 2.0

## Maintainer

Patrick Ryan - [patrick@fireballindustries.com](mailto:patrick@fireballindustries.com)

## Resources

- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Let's Encrypt](https://letsencrypt.org/)
