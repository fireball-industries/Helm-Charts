# Traefik - Industrial Ingress Controller

Modern reverse proxy and load balancer for routing industrial IoT and factory automation traffic.

## What is This?

Traefik is your factory's traffic cop - it routes HTTP, HTTPS, MQTT, Modbus, and OPC-UA traffic to the right services automatically. No manual nginx configs, no headaches.

## Why Traefik?

- **Automatic Routing** - Discovers services and configures routes automatically
- **SSL Made Easy** - Let's Encrypt integration for free HTTPS
- **Industrial Protocols** - MQTT, Modbus TCP, OPC-UA support
- **Real-time Dashboard** - See what's happening right now
- **Zero Downtime** - Updates without interrupting traffic

## Quick Deploy

```bash
helm install traefik ./traefik-pod
```

Dashboard: `http://<YOUR-IP>:9000/dashboard/`

## Common Setups

### Route Your Other Pods

Once Traefik is installed, create Ingress resources for your services:

```yaml
# Access Node-RED at node-red.factory.local
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
            backend:
              service:
                name: node-red
                port:
                  number: 1880
```

### Edge Deployment

One Traefik per edge node:

```bash
helm install traefik ./traefik-pod \
  --set deployment.kind=DaemonSet \
  --set deployment.resourcePreset=edge
```

### With SSL

Automatic HTTPS with Let's Encrypt:

```bash
helm install traefik ./traefik-pod \
  --set tls.certResolvers.letsencrypt.enabled=true \
  --set tls.certResolvers.letsencrypt.email=admin@factory.com \
  --set ports.web.redirectTo=websecure
```

## Industrial Protocols

**MQTT Load Balancing:**
```bash
helm install traefik ./traefik-pod --set ports.mqtt.enabled=true
```

**Modbus TCP Routing:**
```bash
helm install traefik ./traefik-pod --set ports.modbus.enabled=true
```

**OPC-UA Gateway:**
```bash
helm install traefik ./traefik-pod --set ports.opcua.enabled=true
```

## Access Dashboard

```bash
kubectl port-forward svc/traefik 9000:9000
```

Visit: `http://localhost:9000/dashboard/`

## Resource Presets

- **edge** - 100m CPU, 128Mi RAM (single node)
- **standard** - 200m CPU, 256Mi RAM (default)
- **enterprise** - 500m CPU, 512Mi RAM (HA cluster)

## Support

For issues and questions:
- GitHub: [fireball-industries/helm-charts](https://github.com/fireball-industries/helm-charts)
- Email: patrick@fireballindustries.com

Full docs: [README.md](README.md)
