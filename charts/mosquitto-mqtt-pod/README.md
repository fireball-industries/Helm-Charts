# 🦟 Mosquitto MQTT Broker - Helm Chart

Production-ready Eclipse Mosquitto MQTT Broker for Kubernetes with Prometheus monitoring, Sparkplug B support, and industrial IoT optimization.

**Because your factory floor deserves better than a sketchy WiFi network.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Helm](https://img.shields.io/badge/Helm-v3-blue)](https://helm.sh)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.19+-blue)](https://kubernetes.io)
[![Mosquitto](https://img.shields.io/badge/Mosquitto-2.0.18-green)](https://mosquitto.org)

---

## ✨ Features

- **🔌 Full MQTT Protocol Support**: MQTT 3.1.1, MQTT 5.0, WebSockets, TLS/SSL
- **📊 Prometheus Monitoring**: Built-in mosquitto-exporter sidecar with comprehensive metrics
- **⚡ Sparkplug B Ready**: Pre-configured ACLs and topics for Sparkplug B protocol
- **🔒 Enterprise Security**: Password authentication, ACLs, TLS, client certificates
- **🌉 Cloud Bridges**: Easy configuration for AWS IoT, Azure IoT Hub, Google Cloud IoT
- **🚀 High Availability**: StatefulSet with shared storage and session affinity
- **💾 Persistence**: Message and session persistence with automated backups
- **📦 4 Resource Presets**: edge-broker, standard-broker, enterprise-broker, ha-cluster
- **🛠️ PowerShell Management**: Comprehensive management and testing scripts

---

## 🚀 Quick Start (30 seconds)

```bash
# Install with default settings
helm install mosquitto . --namespace iot --create-namespace

# Test connection
kubectl run -it --rm mqtt-test --image=eclipse-mosquitto:2.0 --restart=Never -- \
  mosquitto_pub -h mosquitto.iot.svc.cluster.local -p 1883 -t test/topic -m "Hello MQTT!"
```

---

## 📋 Installation

### Prerequisites

- Kubernetes 1.19+ or K3s
- Helm 3.0+
- kubectl configured
- (Optional) mosquitto_pub/mosquitto_sub for testing

### Install from Local Chart

```bash
# Install with default values
helm install mosquitto . --namespace iot --create-namespace

# Install with custom values
helm install mosquitto . --namespace iot --values examples/factory-mqtt.yaml
```

### Install Specific Preset

```bash
# Edge broker (small deployments)
helm install mosquitto . --namespace iot --set resourcePreset=edge-broker

# Standard broker (factory deployments)
helm install mosquitto . --namespace iot --set resourcePreset=standard-broker

# Enterprise broker (central hub)
helm install mosquitto . --namespace iot --set resourcePreset=enterprise-broker

# High availability cluster
helm install mosquitto . --namespace iot --set resourcePreset=ha-cluster
```

---

## 🎛️ Resource Presets

### edge-broker (Small Edge Deployments)
- CPU: 500m / 1 core, RAM: 512 MiB / 1 GiB, Storage: 5 GiB
- Max Connections: 100
- Use Case: Edge sites, small deployments

### standard-broker (Standard Deployments)
- CPU: 1 / 2 cores, RAM: 1 GiB / 2 GiB, Storage: 20 GiB
- Max Connections: 1000
- Use Case: Factory MQTT broker, standard IoT

### enterprise-broker (Large Deployments)
- CPU: 2 / 4 cores, RAM: 4 GiB / 8 GiB, Storage: 100 GiB
- Max Connections: 10000
- Use Case: Central MQTT hub, high throughput

### ha-cluster (High Availability)
- CPU: 2 / 4 cores per replica, RAM: 4 GiB / 8 GiB per replica
- Replicas: 3, Storage: 100 GiB (shared)
- Use Case: Mission-critical messaging

---

## 🔌 Connection Examples

### CLI (mosquitto_pub/sub)

```bash
# Subscribe to topics
mosquitto_sub -h mosquitto.iot.svc.cluster.local -p 1883 -t 'factory/#' -v

# Publish message
mosquitto_pub -h mosquitto.iot.svc.cluster.local -p 1883 -t 'factory/sensor01' -m '{"temp":25.5}'

# With authentication
mosquitto_sub -h mosquitto.iot.svc.cluster.local -p 1883 -u admin -P changeme -t '#' -v
```

---

## 🔐 Authentication

Enable password authentication:

```yaml
mqtt:
  authentication:
    enabled: true
    allowAnonymous: false
    passwordFile:
      enabled: true
      users:
        - username: admin
          password: changeme
```

Add users manually:

```powershell
.\scripts\manage-mosquitto.ps1 -Action add-user -Username sensor02 -Password newsecret
```

---

## ⚡ Sparkplug B

Enable Sparkplug B support:

```yaml
mqtt:
  sparkplug:
    enabled: true
    namespace: "spBv1.0"
    aclEnabled: true
    groupIds: ["Factory", "Warehouse"]
```

Topic structure: `spBv1.0/<group_id>/<message_type>/<edge_node_id>[/<device_id>]`

See [SPARKPLUG.md](SPARKPLUG.md) for details.

---

## 📊 Monitoring

Enable Prometheus metrics:

```yaml
monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
```

Access metrics: `http://mosquitto:9234/metrics`

---

## 🛠️ Management Scripts

```powershell
# Deploy broker
.\scripts\manage-mosquitto.ps1 -Action deploy -Namespace iot

# Health check
.\scripts\manage-mosquitto.ps1 -Action health-check

# Test connectivity
.\scripts\test-mosquitto.ps1 -TestType connectivity

# View logs
.\scripts\manage-mosquitto.ps1 -Action logs
```

---

## 📚 Documentation

- **[SECURITY.md](SECURITY.md)** - Authentication, TLS, ACL configuration
- **[SPARKPLUG.md](SPARKPLUG.md)** - Sparkplug B protocol implementation
- **[BRIDGES.md](BRIDGES.md)** - Cloud broker integration guide

---

## 📄 License

MIT License - See [LICENSE](LICENSE) for details.

Eclipse Mosquitto is licensed under EPL-2.0 and EDL-1.0.

---

**Author**: Patrick Ryan - Fireball Industries  
"At least it's more reliable than Modbus over WiFi"
Mosquitto Exporter pod for k3s
