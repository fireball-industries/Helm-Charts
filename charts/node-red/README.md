# Node-RED Helm Chart 🔴

*Because visual programming is the only programming I trust after 3am* 🎨

Flow-based visual programming for IoT, automation, and integration. Deploy production-ready Node-RED instances on k3s/Kubernetes with persistent storage, authentication, and full Rancher Apps & Marketplace integration.

**Brought to you by Fireball Industries** - Where wiring diagrams ARE code, and we're not apologizing for it.

## Features

- 🎨 **Flow-Based Programming** - Visual programming for event-driven applications
- 🔒 **Built-in Authentication** - Secure your editor with username/password (bcrypt hashed)
- 💾 **Persistent Storage** - Your flows survive pod restarts (unlike your sleep schedule)
- 🚀 **Multi-Tenant Ready** - Isolated namespaces for different customers/projects
- 📊 **Project Support** - Built-in Git integration for version-controlled flows
- 🔧 **Resource Presets** - Small/Medium/Large for easy sizing
- 🌐 **LoadBalancer/NodePort/Ingress** - Multiple exposure options
- 📈 **Health Checks** - Liveness and readiness probes
- 🔐 **Security Hardened** - Non-root, dropped capabilities, read-only root filesystem options
- 🎯 **Rancher Integration** - Full wizard support via questions.yaml

## Quick Start

### Deploy with Helm

```bash
# Add Fireball Industries Helm repository
helm repo add fireball https://fireball-industries.github.io/helm-charts
helm repo update

# Deploy with defaults (LoadBalancer, medium resources, 5Gi storage)
helm install my-nodered fireball/node-red

# Deploy with custom values
helm install my-nodered fireball/node-red \
  --set nodeRed.image.tag=3.1.0 \
  --set persistence.size=10Gi \
  --set nodeRed.resources.preset=large
```

### Deploy from Source

```bash
# Clone the repository
git clone https://github.com/fireball-industries/helm-charts.git
cd helm-charts

# Install the chart
helm install my-nodered ./charts/node-red

# Or use an example values file
helm install my-nodered ./charts/node-red -f charts/node-red/examples/production-values.yaml
```

### Deploy via Rancher

1. Navigate to **Apps & Marketplace** → **Charts**
2. Search for **"Node-RED"**
3. Click **Install**
4. Use the interactive wizard to configure:
   - Namespace and version
   - Authentication credentials
   - Resource allocation (Small/Medium/Large presets)
   - Storage size and class
   - Service type (LoadBalancer/NodePort/ClusterIP)
   - Optional ingress configuration
5. Click **Install** and watch the magic happen

## Configuration

### Common Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `namespace.name` | Kubernetes namespace | `node-red` |
| `nodeRed.image.tag` | Node-RED version | `3.1.0` |
| `nodeRed.auth.enabled` | Enable authentication | `true` |
| `nodeRed.auth.username` | Admin username | `admin` |
| `nodeRed.auth.password` | Admin password (auto-generated if empty) | `""` |
| `persistence.enabled` | Enable persistent storage | `true` |
| `persistence.size` | PVC size | `5Gi` |
| `persistence.storageClass` | Storage class | `""` (default) |
| `service.type` | Service type | `LoadBalancer` |
| `service.port` | Service port | `1880` |
| `ingress.enabled` | Enable ingress | `false` |

### Resource Presets

| Preset | CPU Request | CPU Limit | Memory Request | Memory Limit | Use Case |
|--------|-------------|-----------|----------------|--------------|----------|
| **small** | 100m | 500m | 256Mi | 1Gi | Dev/testing, light flows |
| **medium** | 250m | 1000m | 512Mi | 2Gi | Production, typical workflows |
| **large** | 500m | 2000m | 1Gi | 4Gi | Heavy processing, complex flows |
| **custom** | User-defined | User-defined | User-defined | User-defined | Full control |

### Authentication Configuration

Node-RED supports bcrypt-hashed passwords for security. To generate a password hash:

```bash
# Using Docker
docker run -it nodered/node-red npx node-red admin hash-pw

# Or use the auto-generated password (retrieved after deployment)
kubectl get secret -n node-red node-red-auth -o jsonpath='{.data.password}' | base64 --decode
```

Set the hash in values.yaml:

```yaml
nodeRed:
  auth:
    enabled: true
    username: "admin"
    passwordHash: "$2b$08$zZWtXTja0fB1pzD4sHCMyOCMYz2Z6dNbM6tl8sJogENOMcxWV9DN."
```

### Custom Settings

Enable advanced Node-RED configuration with custom settings:

```yaml
nodeRed:
  settings:
    enabled: true
    custom:
      functionExternalModules: true  # Allow npm modules in Function nodes
      logging:
        console:
          level: "info"  # fatal, error, warn, info, debug, trace
      editorTheme:
        projects:
          enabled: true  # Enable Git projects
        palette:
          editable: true  # Allow installing nodes from palette
      httpNodeCors:
        origin: "*"
        methods: "GET,PUT,POST,DELETE"
```

### Storage Configuration

```yaml
persistence:
  enabled: true
  storageClass: "local-path"  # or "longhorn", "nfs-client", etc.
  size: "10Gi"
  accessMode: ReadWriteOnce
```

**Storage Class Examples:**
- **k3s default**: `local-path` (single-node, fast)
- **Longhorn**: `longhorn` (replicated, distributed)
- **NFS**: `nfs-client` (shared storage)
- **Cloud**: `standard-ssd` (GKE), `gp2` (EKS), etc.

### Service Types

#### LoadBalancer (Default - k3s)
```yaml
service:
  type: LoadBalancer
  port: 1880
```

Perfect for k3s with built-in ServiceLB. Get an external IP automatically.

#### NodePort (Fixed Port Access)
```yaml
service:
  type: NodePort
  port: 1880
  nodePort: 30180  # 30000-32767
```

Access via `http://<node-ip>:30180`

#### Ingress (Domain-Based Access)
```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/websocket-services: "node-red"
  hosts:
    - host: node-red.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: node-red-tls
      hosts:
        - node-red.example.com
```

Access via `https://node-red.example.com`

## Usage Examples

### Development Deployment

```bash
helm install nodered-dev ./charts/node-red \
  --set namespace.name=nodered-dev \
  --set nodeRed.resources.preset=small \
  --set persistence.size=2Gi \
  --set service.type=NodePort \
  --set nodeRed.auth.password=admin
```

### Production Deployment

```bash
helm install nodered-prod ./charts/node-red \
  --set namespace.name=nodered-prod \
  --set nodeRed.resources.preset=large \
  --set persistence.size=20Gi \
  --set persistence.storageClass=longhorn \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=node-red.example.com \
  --set ingress.tls[0].secretName=node-red-tls \
  --set ingress.tls[0].hosts[0]=node-red.example.com
```

### Multi-Tenant Deployment

```bash
# Customer 1
helm install acme-corp ./charts/node-red \
  --set namespace.name=nodered-acme \
  --set nodeRed.settings.custom.editorTheme.header.title="ACME Corp Node-RED"

# Customer 2
helm install globex ./charts/node-red \
  --set namespace.name=nodered-globex \
  --set nodeRed.settings.custom.editorTheme.header.title="Globex Node-RED"

# Customer 3
helm install initech ./charts/node-red \
  --set namespace.name=nodered-initech \
  --set nodeRed.settings.custom.editorTheme.header.title="Initech Node-RED"
```

### High Availability Setup

```yaml
# values-ha.yaml
pod:
  replicaCount: 1  # Note: Node-RED doesn't support true HA (shared storage issues)

persistence:
  enabled: true
  storageClass: "longhorn"  # Replicated storage
  size: "20Gi"

podDisruptionBudget:
  enabled: true
  minAvailable: 1

affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: app.kubernetes.io/name
                operator: In
                values:
                  - node-red
          topologyKey: kubernetes.io/hostname
```

**Note**: Node-RED doesn't natively support horizontal scaling due to flow state management. For high availability, use:
- Replicated storage (Longhorn/NFS)
- Pod Disruption Budgets
- Regular backups
- Fast pod rescheduling

## Post-Installation

### Access Node-RED

Get the URL:

```bash
# LoadBalancer
kubectl get svc -n node-red node-red
# Use EXTERNAL-IP:1880

# NodePort
kubectl get svc -n node-red node-red
# Use <NODE_IP>:<NODE_PORT>

# Ingress
# Use configured hostname (e.g., https://node-red.example.com)
```

### Get Credentials

```bash
# Username
kubectl get secret -n node-red node-red-auth -o jsonpath='{.data.username}' | base64 --decode
echo

# Password
kubectl get secret -n node-red node-red-auth -o jsonpath='{.data.password}' | base64 --decode
echo
```

### Common Operations

```bash
# View logs
kubectl logs -f -n node-red -l app=node-red

# Restart Node-RED
kubectl rollout restart deployment/node-red -n node-red

# Check resource usage
kubectl top pod -n node-red

# Backup flows
kubectl exec -n node-red deployment/node-red -- tar czf /tmp/backup.tar.gz /data
kubectl cp node-red/$(kubectl get pod -n node-red -l app=node-red -o jsonpath='{.items[0].metadata.name}'):/tmp/backup.tar.gz ./node-red-backup-$(date +%F).tar.gz

# Scale down for maintenance
kubectl scale deployment/node-red --replicas=0 -n node-red

# Scale back up
kubectl scale deployment/node-red --replicas=1 -n node-red
```

## Architecture

### Pod Structure

```
┌─────────────────────────────────────────┐
│           Node-RED Pod                  │
├─────────────────────────────────────────┤
│                                         │
│  Container: node-red                    │
│  ├─ Port 1880 (HTTP/WebSocket)          │
│  ├─ User: 1000 (non-root)               │
│  └─ Volume: /data (persistent)          │
│                                         │
│  Mounted Volumes:                       │
│  ├─ PVC: node-red-data → /data          │
│  └─ ConfigMap: settings.js (optional)   │
│                                         │
└─────────────────────────────────────────┘
         │
         ├─ Service (LoadBalancer/NodePort/ClusterIP)
         └─ Ingress (optional)
```

### Data Persistence

Node-RED stores the following in `/data`:
- `flows.json` - Your flow definitions
- `flows_cred.json` - Encrypted credentials
- `.config.json` - Node-RED configuration
- `package.json` - Installed nodes
- `node_modules/` - Custom node packages
- `projects/` - Git-based projects
- `lib/` - Function node libraries

**All data persists across pod restarts** when persistence is enabled.

## Security

### Enabled Security Features

✅ **Authentication** - Bcrypt-hashed passwords  
✅ **Non-root user** - UID 1000, GID 1000  
✅ **Dropped capabilities** - ALL capabilities dropped  
✅ **Namespace isolation** - Separate namespace per deployment  
✅ **Session affinity** - WebSocket support (3-hour timeout)  
✅ **Network policies** - Optional ingress/egress restrictions  
✅ **Resource limits** - Prevent DoS via resource exhaustion  
✅ **Read-only root FS** - Optional (disabled by default for Node-RED compatibility)

### Security Best Practices

1. **Enable Authentication** (enabled by default)
   ```yaml
   nodeRed:
     auth:
       enabled: true
       password: "<strong-password>"
   ```

2. **Use TLS/SSL** (via ingress)
   ```yaml
   ingress:
     enabled: true
     annotations:
       cert-manager.io/cluster-issuer: "letsencrypt-prod"
     tls:
       - secretName: node-red-tls
         hosts:
           - node-red.example.com
   ```

3. **Restrict Function Node Modules** (if untrusted users)
   ```yaml
   nodeRed:
     settings:
       custom:
         functionExternalModules: false  # Disable npm imports
   ```

4. **Enable Network Policies**
   ```yaml
   networkPolicy:
     enabled: true
   ```

5. **Set Resource Limits** (prevent abuse)
   ```yaml
   nodeRed:
     resources:
       preset: medium  # or custom with limits
   ```

## Monitoring

### Prometheus Integration

Enable ServiceMonitor for Prometheus Operator:

```yaml
monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
    interval: "30s"
    labels:
      prometheus: kube-prometheus
```

**Note**: Node-RED doesn't expose metrics by default. Install `node-red-contrib-prometheus-exporter` for metrics support.

### Health Checks

The chart includes liveness and readiness probes:

```yaml
nodeRed:
  livenessProbe:
    enabled: true
    httpGet:
      path: /
      port: 1880
    initialDelaySeconds: 60
    periodSeconds: 30
    timeoutSeconds: 10
    failureThreshold: 3
  
  readinessProbe:
    enabled: true
    httpGet:
      path: /
      port: 1880
    initialDelaySeconds: 30
    periodSeconds: 10
    timeoutSeconds: 5
    failureThreshold: 3
```

### Logs

```bash
# Real-time logs
kubectl logs -f -n node-red -l app=node-red

# Last 100 lines
kubectl logs -n node-red -l app=node-red --tail=100

# Logs from specific container
kubectl logs -n node-red deployment/node-red -c node-red
```

## Troubleshooting

### Pod Not Starting

```bash
# Check pod status
kubectl get pods -n node-red

# Describe pod for events
kubectl describe pod -n node-red -l app=node-red

# Check logs
kubectl logs -n node-red -l app=node-red
```

**Common causes:**
- PVC not binding (check storage class availability)
- Resource limits too low (increase preset or use custom)
- Image pull failures (check image tag)

### PVC Not Binding

```bash
# Check PVC status
kubectl get pvc -n node-red

# Describe PVC
kubectl describe pvc -n node-red node-red-data
```

**Common causes:**
- No storage class available
- Insufficient storage capacity
- Access mode incompatibility (use ReadWriteOnce)

### Can't Access Node-RED

```bash
# Check service
kubectl get svc -n node-red

# Check endpoints
kubectl get endpoints -n node-red
```

**LoadBalancer stuck on \<pending\>:**
- k3s: Check ServiceLB is running
- Cloud: Check cloud provider integration

**NodePort not accessible:**
- Check firewall rules
- Verify node IP is correct

### Flows Not Persisting

```bash
# Check PVC is mounted
kubectl describe pod -n node-red -l app=node-red | grep -A5 Mounts

# Check PVC size and usage
kubectl exec -n node-red deployment/node-red -- df -h /data

# Verify ownership
kubectl exec -n node-red deployment/node-red -- ls -la /data
```

### Performance Issues

```bash
# Check resource usage
kubectl top pod -n node-red

# Check resource limits
kubectl describe pod -n node-red -l app=node-red | grep -A10 Limits

# Increase resources if needed
helm upgrade my-nodered ./charts/node-red \
  --set nodeRed.resources.preset=large \
  --reuse-values
```

## Upgrading

### Upgrade Node-RED Version

```bash
# Upgrade to specific version
helm upgrade my-nodered ./charts/node-red \
  --set nodeRed.image.tag=3.1.0 \
  --reuse-values

# Check rollout status
kubectl rollout status deployment/node-red -n node-red
```

### Upgrade Chart Version

```bash
# Update repository
helm repo update fireball

# Upgrade chart
helm upgrade my-nodered fireball/node-red --reuse-values

# Or from source
helm upgrade my-nodered ./charts/node-red --reuse-values
```

### Migration Notes

**Important**: Always backup your flows before upgrading!

```bash
kubectl exec -n node-red deployment/node-red -- tar czf /tmp/backup.tar.gz /data
kubectl cp node-red/$(kubectl get pod -n node-red -l app=node-red -o jsonpath='{.items[0].metadata.name}'):/tmp/backup.tar.gz ./backup-$(date +%F).tar.gz
```

## Uninstalling

```bash
# Uninstall release (keeps PVC)
helm uninstall my-nodered -n node-red

# Delete PVC manually if needed
kubectl delete pvc -n node-red node-red-data

# Delete namespace (deletes everything)
kubectl delete namespace node-red
```

**Warning**: Deleting the PVC will **permanently delete all flows and data**. Make sure you have backups!

## Requirements

- **Kubernetes**: 1.25+
- **Helm**: 3.x
- **Storage**: Persistent storage provider (for persistence)
- **Load Balancer**: k3s ServiceLB, MetalLB, or cloud provider (for LoadBalancer service type)
- **Ingress Controller**: nginx, Traefik, etc. (for ingress)

## Compatibility

| Platform | Status | Notes |
|----------|--------|-------|
| **k3s** | ✅ Fully supported | Default target platform |
| **k8s** | ✅ Fully supported | Standard Kubernetes |
| **Rancher** | ✅ Fully supported | Full wizard integration |
| **RKE2** | ✅ Fully supported | Rancher Kubernetes Engine v2 |
| **GKE/EKS/AKS** | ✅ Fully supported | Cloud Kubernetes |
| **ARM64** | ✅ Fully supported | Official Node-RED multi-arch images |

## Contributing

Found a bug? Have a feature request? Contributions welcome!

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `helm lint` and `helm install --dry-run`
5. Submit a pull request

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for detailed guidelines.

## License

MIT License - See [LICENSE](../../LICENSE) for details.

## Support

- **Documentation**: [Helm Charts Repository](https://github.com/fireball-industries/helm-charts)
- **Node-RED Docs**: [nodered.org/docs](https://nodered.org/docs/)
- **Issues**: [GitHub Issues](https://github.com/fireball-industries/helm-charts/issues)
- **Commercial Support**: support@fireballindustries.com

---

**Fireball Industries** - *We Play With Fire So You Don't Have To™*

*Est. 2024 | Powered by YAML, Caffeine, and Questionable Decisions*

Happy flow building! Remember: wiring diagrams ARE code. 🎨🔥
