# Home Assistant Pod

Production-ready Home Assistant deployment for industrial IoT and smart home management in Kubernetes.

## Overview

This chart deploys a fully-featured Home Assistant instance with optional PostgreSQL database, persistent storage, monitoring, and advanced networking capabilities. Perfect for industrial IoT deployments, smart building automation, and comprehensive home automation platforms.

## Key Features

- **Production-Ready**: StatefulSet deployment with health checks and configurable resource management
- **Database Options**: SQLite (default), managed PostgreSQL StatefulSet, or external database
- **Persistent Storage**: Separate volumes for config, media, backups, and shared data
- **Device Support**: USB device passthrough for Zigbee/Z-Wave controllers, Bluetooth, and GPIO access
- **Monitoring**: Built-in Prometheus ServiceMonitor support
- **Security**: NetworkPolicies, RBAC, TLS ingress, and security contexts
- **High Availability**: Configurable replicas, PodDisruptionBudgets, and affinity rules
- **Camera Support**: Dedicated storage and configuration for IP camera integration

## Prerequisites

- Kubernetes 1.20+ or K3s
- Helm 3.0+
- PersistentVolume provisioner (for storage)
- LoadBalancer support (MetalLB, cloud provider, or NodePort alternative)

## Quick Start

1. **Basic Installation**:
   ```bash
   helm install home-assistant ./home-assistant-pod
   ```

2. **With PostgreSQL**:
   ```bash
   helm install home-assistant ./home-assistant-pod \
     --set database.type=postgresql \
     --set database.postgresql.enabled=true \
     --set database.postgresql.auth.password=your-secure-password
   ```

3. **With Ingress**:
   ```bash
   helm install home-assistant ./home-assistant-pod \
     --set ingress.enabled=true \
     --set ingress.hosts[0].host=homeassistant.example.com \
     --set ingress.hosts[0].paths[0].path=/ \
     --set ingress.hosts[0].paths[0].pathType=Prefix
   ```

## Common Configuration Options

### Resource Presets
- `minimal`: < 50 devices, SQLite (200m-500m CPU, 256Mi-512Mi RAM)
- `standard`: 50-200 devices, PostgreSQL (500m-1000m CPU, 512Mi-1Gi RAM) - **Default**
- `full`: 200+ devices, cameras (1000m-2000m CPU, 1Gi-2Gi RAM)
- `custom`: Use manual resource configuration

### Database Types
- `sqlite`: Simple file-based database (default)
- `postgresql`: Managed PostgreSQL StatefulSet (recommended for production)
- `external`: Connect to existing database server

### Service Types
- `ClusterIP`: Internal cluster access only
- `NodePort`: Access via node IP and static port
- `LoadBalancer`: External load balancer (requires MetalLB or cloud provider)

## USB Device Integration

For Zigbee, Z-Wave, or other USB devices:

1. Label your node with USB devices:
   ```bash
   kubectl label nodes <node-name> usb-devices=zigbee
   ```

2. Enable USB device support:
   ```yaml
   devices:
     usb:
       enabled: true
       devices:
         - name: zigbee
           hostPath: /dev/ttyUSB0
   homeassistant:
     nodeSelector:
       usb-devices: "zigbee"
   ```

## Monitoring

Enable Prometheus monitoring:

```yaml
monitoring:
  serviceMonitor:
    enabled: true
    namespace: monitoring
    interval: 30s
```

## Support

- **Documentation**: See INSTALL.md, QUICKREF.md, and ARCHITECTURE.md in the chart directory
- **GitHub**: https://github.com/fireballindustries/home-assistant-pod
- **Home Assistant**: https://www.home-assistant.io/

## License

Apache 2.0 - See LICENSE file for details
