# CODESYS Edge Gateway - Helm Chart

A production-ready Helm chart for deploying CODESYS Edge Gateway for Linux on Kubernetes.

**Current Version:** CODESYS Edge Gateway for Linux 4.18.0.0

**GitHub Release:** [EdgeGatewayLinux-4.18.0.0](https://github.com/fireball-industries/Codesys-Edge-Gateway-Release/releases/tag/EdgeGatewayLinux-4.18.0.0)

## Introduction

This chart bootstraps a CODESYS Edge Gateway deployment on a Kubernetes cluster using the Helm package manager. The gateway provides extended connectivity between the CODESYS Automation Server and CODESYS PLCs in local networks.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- PV provisioner support in the underlying infrastructure (for persistent storage)
- Access to CODESYS Automation Server

## Installing the Chart

To install the chart with the release name `my-gateway`:

```bash
helm install my-gateway ./helm-chart \
  --namespace codesys-gateway \
  --create-namespace \
  --set gateway.automationServerUrl="https://automation-server.example.com:4410" \
  --set gateway.automationServer.username="admin" \
  --set gateway.automationServer.password="your-password"
```

## Uninstalling the Chart

To uninstall/delete the `my-gateway` deployment:

```bash
helm uninstall my-gateway -n codesys-gateway
```

## Parameters

### Global Parameters

| Name | Description | Value |
|------|-------------|-------|
| `nameOverride` | String to partially override name | `""` |
| `fullnameOverride` | String to fully override fullname | `""` |
| `namespace` | Namespace to deploy into | `codesys-gateway` |

### Image Parameters

| Name | Description | Value |
|------|-------------|-------|
| `image.repository` | CODESYS Gateway image repository | `ghcr.io/YOUR_ORG/codesys-edge-gateway` |
| `image.tag` | CODESYS Gateway image tag | `4.18.0.0` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `image.architecture` | Target architecture (arm32, arm64, x86, x64) | `arm64` |
| `imagePullSecrets` | Docker registry secret names as array | `[]` |

### Deployment Parameters

| Name | Description | Value |
|------|-------------|-------|
| `replicaCount` | Number of replicas (should be 1 for gateway) | `1` |
| `podAnnotations` | Pod annotations | `{}` |
| `podLabels` | Pod labels | `{}` |
| `podSecurityContext` | Pod security context | `{fsGroup: 1000}` |
| `securityContext.capabilities.add` | Capabilities to add | `[NET_ADMIN]` |

### Service Parameters

| Name | Description | Value |
|------|-------------|-------|
| `service.type` | Kubernetes Service type | `LoadBalancer` |
| `service.gatewayPort` | Gateway communication port | `2455` |
| `service.plcPort` | PLC communication port | `1217` |
| `service.discoveryPorts` | UDP discovery ports | `[1740, 1741, 1742, 1743]` |
| `service.sessionAffinity` | Session affinity | `ClientIP` |
| `service.annotations` | Service annotations | `{}` |

### Persistence Parameters

| Name | Description | Value |
|------|-------------|-------|
| `persistence.enabled` | Enable persistent storage | `true` |
| `persistence.storageClass` | Storage class name | `local-path` |
| `persistence.accessMode` | PVC access mode | `ReadWriteOnce` |
| `persistence.size` | PVC size | `1Gi` |
| `persistence.existingClaim` | Use existing PVC | `""` |
| `persistence.mountPath` | Mount path in container | `/var/opt/codesys-gateway` |

### Gateway Configuration Parameters

| Name | Description | Value |
|------|-------------|-------|
| `gateway.automationServerUrl` | Automation Server URL (required) | `""` |
| `gateway.automationServer.username` | AS username | `""` |
| `gateway.automationServer.password` | AS password | `""` |
| `gateway.automationServer.existingSecret` | Existing secret for credentials | `""` |
| `gateway.networkInterface` | Network interface | `eth0` |
| `gateway.enablePlcDiscovery` | Enable PLC discovery | `true` |
| `gateway.discoveryInterval` | Discovery interval (seconds) | `30` |
| `gateway.name` | Gateway identifier | `CODESYS-Edge-Gateway` |
| `gateway.enableSsl` | Enable SSL for AS connection | `true` |

### Resource Management

| Name | Description | Value |
|------|-------------|-------|
| `resources.requests.memory` | Memory request | `128Mi` |
| `resources.requests.cpu` | CPU request | `100m` |
| `resources.limits.memory` | Memory limit | `512Mi` |
| `resources.limits.cpu` | CPU limit | `500m` |

### Health Probes

| Name | Description | Value |
|------|-------------|-------|
| `livenessProbe.initialDelaySeconds` | Initial delay | `20` |
| `livenessProbe.periodSeconds` | Check period | `10` |
| `readinessProbe.initialDelaySeconds` | Initial delay | `15` |
| `readinessProbe.periodSeconds` | Check period | `10` |
| `startupProbe.failureThreshold` | Failure threshold | `12` |

### Network Configuration

| Name | Description | Value |
|------|-------------|-------|
| `network.hostNetwork` | Use host network | `false` |
| `network.dnsPolicy` | DNS policy | `ClusterFirst` |
| `networkPolicy.enabled` | Enable network policies | `false` |

### Multi-Tenancy

| Name | Description | Value |
|------|-------------|-------|
| `resourceQuota.enabled` | Enable resource quotas | `false` |
| `resourceQuota.hard` | Resource quota limits | `{}` |

### Monitoring

| Name | Description | Value |
|------|-------------|-------|
| `metrics.enabled` | Enable metrics | `false` |
| `metrics.port` | Metrics port | `9090` |
| `metrics.serviceMonitor.enabled` | Enable ServiceMonitor | `false` |

### Logging

| Name | Description | Value |
|------|-------------|-------|
| `logging.level` | Log level | `INFO` |
| `logging.format` | Log format | `json` |

## Configuration Examples

### Basic Deployment

```bash
helm install codesys-gateway ./helm-chart \
  --set gateway.automationServerUrl="https://as.example.com:4410" \
  --set gateway.automationServer.password="secret"
```

### Production Deployment with High Availability Storage

```bash
helm install codesys-gateway ./helm-chart \
  --set gateway.automationServerUrl="https://as.example.com:4410" \
  --set gateway.automationServer.password="secret" \
  --set persistence.storageClass=nfs-client \
  --set persistence.size=5Gi \
  --set resources.limits.memory=1Gi \
  --set resources.limits.cpu=1000m
```

### Multi-Tenant Deployment

```bash
helm install gateway-customer1 ./helm-chart \
  --namespace customer1 \
  --create-namespace \
  --set namespace=customer1 \
  --set networkPolicy.enabled=true \
  --set resourceQuota.enabled=true \
  --set gateway.automationServerUrl="https://as.example.com:4410" \
  --set gateway.automationServer.password="secret1"

helm install gateway-customer2 ./helm-chart \
  --namespace customer2 \
  --create-namespace \
  --set namespace=customer2 \
  --set networkPolicy.enabled=true \
  --set resourceQuota.enabled=true \
  --set gateway.automationServerUrl="https://as.example.com:4410" \
  --set gateway.automationServer.password="secret2"
```

### Using Existing Secret

```bash
# Create secret
kubectl create secret generic my-gateway-secret \
  --from-literal=username=admin \
  --from-literal=password=mypassword \
  -n codesys-gateway

# Install with existing secret
helm install codesys-gateway ./helm-chart \
  --set gateway.automationServerUrl="https://as.example.com:4410" \
  --set gateway.automationServer.existingSecret=my-gateway-secret
```

### Enable Host Network for UDP Discovery

```bash
helm install codesys-gateway ./helm-chart \
  --set gateway.automationServerUrl="https://as.example.com:4410" \
  --set gateway.automationServer.password="secret" \
  --set network.hostNetwork=true
```

## Upgrading

To upgrade the chart:

```bash
helm upgrade codesys-gateway ./helm-chart \
  --reuse-values \
  --set image.tag=4.19.0.0
```

## Values File

You can also create a custom `values.yaml` file:

```yaml
image:
  architecture: arm64

gateway:
  automationServerUrl: "https://automation-server.example.com:4410"
  automationServer:
    username: "admin"
    password: "changeme"
  enablePlcDiscovery: true

persistence:
  enabled: true
  size: 2Gi
  storageClass: nfs-client

resources:
  limits:
    memory: 1Gi
    cpu: 1000m
  requests:
    memory: 256Mi
    cpu: 200m

service:
  type: LoadBalancer
```

Then install:

```bash
helm install codesys-gateway ./helm-chart -f custom-values.yaml
```

## Troubleshooting

See logs:
```bash
kubectl logs -n codesys-gateway -l app.kubernetes.io/name=codesys-edge-gateway -f
```

Check status:
```bash
kubectl get all -n codesys-gateway
```

Describe pod:
```bash
kubectl describe pod -n codesys-gateway <pod-name>
```

## License

Copyright © CODESYS. All rights reserved.
