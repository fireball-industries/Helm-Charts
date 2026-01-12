# Traefik Industrial Examples

Real-world examples for routing traffic to your industrial pods.

## Quick Start

1. Install Traefik:
```bash
helm install traefik ./traefik-pod
```

2. Apply any example:
```bash
kubectl apply -f examples/node-red-ingress.yaml
```

3. Access your service using the configured hostname

## Examples

### Basic HTTP Routing

#### node-red-ingress.yaml
Route to Node-RED dashboard:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: node-red
  namespace: default
spec:
  ingressClassName: traefik
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

#### grafana-ingress.yaml
Route to Grafana dashboards:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana
  namespace: default
spec:
  ingressClassName: traefik
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

#### influxdb-api-ingress.yaml
Route to InfluxDB API:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: influxdb
  namespace: default
spec:
  ingressClassName: traefik
  rules:
    - host: influxdb.factory.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: influxdb
                port:
                  number: 8086
```

### MQTT TCP Routing

#### mqtt-tcp-route.yaml
Load balance MQTT traffic:
```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRouteTCP
metadata:
  name: mqtt-broker
  namespace: default
spec:
  entryPoints:
    - mqtt
  routes:
    - match: HostSNI(`*`)
      services:
        - name: mosquitto-mqtt
          port: 1883
```

#### mqtt-tls-route.yaml
Secure MQTT with TLS:
```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRouteTCP
metadata:
  name: mqtts-broker
  namespace: default
spec:
  entryPoints:
    - mqtts
  routes:
    - match: HostSNI(`*`)
      services:
        - name: mosquitto-mqtt
          port: 8883
      tls:
        passthrough: true
```

### SSL/HTTPS Examples

#### ssl-redirect.yaml
Force HTTPS for all traffic:
```yaml
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: redirect-https
  namespace: default
spec:
  redirectScheme:
    scheme: https
    permanent: true
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: secure-service
  annotations:
    traefik.ingress.kubernetes.io/router.middlewares: default-redirect-https@kubernetescrd
spec:
  ingressClassName: traefik
  tls:
    - hosts:
        - secure.factory.local
      secretName: secure-tls
  rules:
    - host: secure.factory.local
      http:
        paths:
          - path: /
            backend:
              service:
                name: my-service
                port:
                  number: 80
```

### Multi-Service Factory

#### factory-routes.yaml
Route multiple production lines:
```yaml
# Production Line 1 Dashboard
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: line1
spec:
  ingressClassName: traefik
  rules:
    - host: line1.factory.local
      http:
        paths:
          - path: /
            backend:
              service:
                name: line1-dashboard
                port:
                  number: 80

# Production Line 2 Dashboard
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: line2
spec:
  ingressClassName: traefik
  rules:
    - host: line2.factory.local
      http:
        paths:
          - path: /
            backend:
              service:
                name: line2-dashboard
                port:
                  number: 80

# Quality Control Station
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: qc
spec:
  ingressClassName: traefik
  rules:
    - host: qc.factory.local
      http:
        paths:
          - path: /
            backend:
              service:
                name: qc-system
                port:
                  number: 8080
```

### Authentication & Security

#### basic-auth.yaml
Add basic authentication:
```yaml
# Create auth secret first:
# htpasswd -c auth admin
# kubectl create secret generic auth-secret --from-file=users=auth

apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: basic-auth
  namespace: default
spec:
  basicAuth:
    secret: auth-secret
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: protected-service
  annotations:
    traefik.ingress.kubernetes.io/router.middlewares: default-basic-auth@kubernetescrd
spec:
  ingressClassName: traefik
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

#### ip-whitelist.yaml
Restrict access by IP:
```yaml
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: factory-network-only
  namespace: default
spec:
  ipWhiteList:
    sourceRange:
      - 192.168.1.0/24
      - 10.0.0.0/8
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: internal-service
  annotations:
    traefik.ingress.kubernetes.io/router.middlewares: default-factory-network-only@kubernetescrd
spec:
  ingressClassName: traefik
  rules:
    - host: internal.factory.local
      http:
        paths:
          - path: /
            backend:
              service:
                name: internal-api
                port:
                  number: 3000
```

#### rate-limit.yaml
Prevent API abuse:
```yaml
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: rate-limit
  namespace: default
spec:
  rateLimit:
    average: 100
    burst: 50
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-service
  annotations:
    traefik.ingress.kubernetes.io/router.middlewares: default-rate-limit@kubernetescrd
spec:
  ingressClassName: traefik
  rules:
    - host: api.factory.local
      http:
        paths:
          - path: /
            backend:
              service:
                name: rest-api
                port:
                  number: 8000
```

### Industrial Protocol Examples

#### modbus-tcp.yaml
Route Modbus TCP to PLC:
```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRouteTCP
metadata:
  name: modbus-plc
  namespace: default
spec:
  entryPoints:
    - modbus
  routes:
    - match: HostSNI(`*`)
      services:
        - name: plc-gateway
          port: 502
```

#### opcua-server.yaml
Route OPC-UA traffic:
```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRouteTCP
metadata:
  name: opcua-server
  namespace: default
spec:
  entryPoints:
    - opcua
  routes:
    - match: HostSNI(`*`)
      services:
        - name: opcua-server
          port: 4840
```

### Path-Based Routing

#### api-gateway.yaml
Route different paths to different services:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-gateway
spec:
  ingressClassName: traefik
  rules:
    - host: api.factory.local
      http:
        paths:
          - path: /influx
            pathType: Prefix
            backend:
              service:
                name: influxdb
                port:
                  number: 8086
          - path: /node-red
            pathType: Prefix
            backend:
              service:
                name: node-red
                port:
                  number: 1880
          - path: /grafana
            pathType: Prefix
            backend:
              service:
                name: grafana
                port:
                  number: 3000
```

## Testing Examples

After applying an Ingress, test with curl:

```bash
# Get Traefik LoadBalancer IP
export TRAEFIK_IP=$(kubectl get svc traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test routing
curl -H "Host: node-red.factory.local" http://$TRAEFIK_IP

# Or add to /etc/hosts for real domain access
echo "$TRAEFIK_IP node-red.factory.local" | sudo tee -a /etc/hosts
curl http://node-red.factory.local
```

## DNS Configuration

For production, configure DNS:

1. **Wildcard DNS** (recommended):
   ```
   *.factory.local → <TRAEFIK_LOADBALANCER_IP>
   ```

2. **Individual Records**:
   ```
   node-red.factory.local → <TRAEFIK_IP>
   grafana.factory.local → <TRAEFIK_IP>
   influxdb.factory.local → <TRAEFIK_IP>
   ```

## Complete Stack Example

Deploy full industrial stack with routing:

```bash
# 1. Install Traefik
helm install traefik ./traefik-pod

# 2. Install industrial pods
helm install mosquitto ./mosquitto-mqtt-pod
helm install influxdb ./influxdb-pod
helm install node-red ./node-red

# 3. Apply all ingress routes
kubectl apply -f examples/
```

Access:
- Node-RED: http://node-red.factory.local
- Grafana: http://grafana.factory.local  
- InfluxDB API: http://influxdb.factory.local
- MQTT: mqtt://factory.local:1883
