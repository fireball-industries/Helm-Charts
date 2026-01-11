# Prometheus Pod

**Production-Ready Prometheus Monitoring for Kubernetes**

Fireball Industries - *We Play With Fire So You Don't Have To™*

---

## 🚀 Quick Start

Deploy Prometheus in under 2 minutes:

```bash
# Add Helm repo (if using Rancher catalog, skip this)
helm repo add fireball https://charts.fireballindustries.com

# Install with default settings
helm install prometheus ./prometheus-pod -n monitoring --create-namespace

# Or use a preset configuration
helm install prometheus ./prometheus-pod -n monitoring \
  --create-namespace \
  --set resourcePreset=medium \
  --set deploymentMode=ha \
  --set replicaCount=3
```

Access Prometheus:

```bash
# Port forward
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# Open browser
open http://localhost:9090
```

---

## 📦 What Is This?

This is a **POD PRODUCT** - a customer-deployable Helm chart designed for the Rancher Apps & Marketplace catalog. It provides:

- **Complete Prometheus stack** with pre-configured scrape configs for Kubernetes
- **High Availability support** with StatefulSet deployment and Thanos integration
- **Security-hardened** following Pod Security Standards (Restricted level)
- **Resource presets** for easy sizing (small/medium/large/xlarge/custom)
- **Persistent storage** with configurable retention policies
- **Alert rules** pre-configured for common failure scenarios
- **Automation scripts** for deployment, testing, and management

---

## ✨ Features

### Core Capabilities

- ✅ **Prometheus 2.49.0** (latest stable, alpine-based)
- ✅ **Kubernetes-native** service discovery (API, nodes, pods, services, cAdvisor)
- ✅ **HA deployment** with StatefulSet (2+ replicas)
- ✅ **Thanos sidecar** for query deduplication and long-term storage
- ✅ **Persistent storage** with time and size-based retention
- ✅ **Pre-configured alerts** for nodes, pods, storage, and Prometheus health
- ✅ **RBAC** with minimal cluster-wide read-only permissions
- ✅ **Network policies** for ingress/egress control
- ✅ **Ingress support** with TLS
- ✅ **ServiceMonitor** for Prometheus Operator integration

### Security

- 🔒 Non-root user (UID 65534)
- 🔒 Read-only root filesystem
- 🔒 All capabilities dropped
- 🔒 Seccomp profile: RuntimeDefault
- 🔒 Pod Security Standards: **Restricted** compliance
- 🔒 Network policies enabled by default

### Deployment Modes

| Mode | Use Case | Storage | Replicas |
|------|----------|---------|----------|
| **single** | Dev/test, small clusters | Single PVC | 1 |
| **ha** | Production, large clusters | Per-replica PVC | 2+ |

### Resource Presets

| Preset | Memory | CPU | Storage | Retention | Use Case |
|--------|--------|-----|---------|-----------|----------|
| **small** | 512Mi | 1 core | 10Gi | 7d | Dev/test |
| **medium** | 2Gi | 2 cores | 20Gi | 15d | Small prod |
| **large** | 8Gi | 4 cores | 50Gi | 30d | Medium prod |
| **xlarge** | 16Gi | 8 cores | 100Gi | 60d | Large prod |
| **custom** | Your values | - | - | - | Custom sizing |

---

## 📚 Documentation

- **[Complete User Guide](docs/README.md)** - Comprehensive documentation (100+ pages)
  - Installation and configuration
  - Deployment modes and patterns
  - Resource sizing and capacity planning
  - Storage configuration
  - Monitoring and troubleshooting
  - Advanced features (HA, Thanos, federation)

- **[Security Guide](docs/SECURITY.md)** - Security hardening and compliance
  - Threat model and security architecture
  - Container and RBAC security
  - Network policies and secrets management
  - TLS and authentication
  - Compliance considerations (SOC 2, PCI-DSS, HIPAA, GDPR)
  - Incident response

---

## 🎯 Example Configurations

Pre-built configurations for common scenarios:

### Full Kubernetes Monitoring
```bash
helm install prometheus ./prometheus-pod -n monitoring \
  -f examples/kubernetes-full-monitoring.yaml
```

### High Availability Production
```bash
helm install prometheus ./prometheus-pod -n monitoring \
  -f examples/ha-prometheus.yaml
```

### Minimal Dev/Test
```bash
helm install prometheus ./prometheus-pod -n monitoring \
  -f examples/minimal-prometheus.yaml
```

### Federated Edge Setup
```bash
helm install prometheus ./prometheus-pod -n monitoring \
  -f examples/federated-prometheus.yaml
```

### Application Monitoring
```bash
helm install prometheus ./prometheus-pod -n monitoring \
  -f examples/app-monitoring.yaml
```

### Long-term Storage with Thanos
```bash
helm install prometheus ./prometheus-pod -n monitoring \
  -f examples/thanos-enabled.yaml
```

See the [examples/](examples/) directory for complete configurations.

---

## 🛠️ PowerShell Automation Scripts

Comprehensive management tools in the [scripts/](scripts/) directory:

### Deployment Management (`manage-prometheus.ps1`)

```powershell
# Deploy with interactive preset selection
.\scripts\manage-prometheus.ps1 -Action deploy

# Deploy with specific preset
.\scripts\manage-prometheus.ps1 -Action deploy -Preset large

# Upgrade existing deployment
.\scripts\manage-prometheus.ps1 -Action upgrade

# Check health
.\scripts\manage-prometheus.ps1 -Action health-check

# Backup TSDB data
.\scripts\manage-prometheus.ps1 -Action backup -BackupPath ./backups

# Query metrics
.\scripts\manage-prometheus.ps1 -Action query -Query "up"

# Get tuning recommendations
.\scripts\manage-prometheus.ps1 -Action tune
```

### Testing (`test-prometheus.ps1`)

```powershell
# Run all tests
.\scripts\test-prometheus.ps1

# Test specific area
.\scripts\test-prometheus.ps1 -TestType scraping
.\scripts\test-prometheus.ps1 -TestType alerts
.\scripts\test-prometheus.ps1 -TestType storage
.\scripts\test-prometheus.ps1 -TestType queries
.\scripts\test-prometheus.ps1 -TestType ha-failover
```

### Configuration Generation (`generate-config.ps1`)

```powershell
# Generate Kubernetes monitoring config
.\scripts\generate-config.ps1 -Scenario kubernetes -OutputFile prom.yml

# Generate app monitoring with exporters
.\scripts\generate-config.ps1 -Scenario app-monitoring \
  -ExtraExporters "mysql,redis,node" \
  -OutputFile app-prom.yml

# Generate minimal config
.\scripts\generate-config.ps1 -Scenario minimal
```

---

## 📖 Quick Reference

### Common Tasks

**Deploy Prometheus:**
```bash
helm install prometheus ./prometheus-pod -n monitoring --create-namespace
```

**Upgrade:**
```bash
helm upgrade prometheus ./prometheus-pod -n monitoring
```

**Scale replicas (HA mode):**
```bash
helm upgrade prometheus ./prometheus-pod -n monitoring --set replicaCount=5
```

**Change resource preset:**
```bash
helm upgrade prometheus ./prometheus-pod -n monitoring --set resourcePreset=large
```

**Enable Thanos sidecar:**
```bash
helm upgrade prometheus ./prometheus-pod -n monitoring \
  --set thanos.enabled=true \
  --set thanos.objectStorageConfig.bucket=my-bucket
```

**Access Prometheus UI:**
```bash
kubectl port-forward -n monitoring svc/prometheus 9090:9090
```

**Check pod status:**
```bash
kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus-pod
```

**View logs:**
```bash
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus-pod -f
```

**Execute PromQL query:**
```bash
kubectl exec -n monitoring prometheus-0 -- \
  wget -qO- 'http://localhost:9090/api/v1/query?query=up'
```

### Configuration Values

Key `values.yaml` settings:

```yaml
# Deployment mode
deploymentMode: ha              # single or ha

# Replicas (HA mode only)
replicaCount: 3

# Resource sizing
resourcePreset: medium          # small, medium, large, xlarge, custom

# Storage
storage:
  size: 20Gi
  storageClass: ""              # Use cluster default
  
retentionTime: 15d
retentionSize: 16GB

# Security
rbac:
  create: true
securityContext:
  runAsNonRoot: true
  runAsUser: 65534

# Thanos
thanos:
  enabled: false
  
# Ingress
ingress:
  enabled: false
  host: prometheus.example.com
```

See [values.yaml](values.yaml) for all options.

---

## 🔧 Requirements

- **Kubernetes**: 1.24+ (tested on k3s, k8s, RKE2)
- **Helm**: 3.0+
- **Storage**: PersistentVolume support
- **Resources**: Minimum 512Mi RAM, 1 CPU core, 10Gi storage
- **Permissions**: Cluster-wide read access for service discovery

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Kubernetes Cluster                      │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                     Namespace: monitoring               │ │
│  │                                                          │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │ │
│  │  │ Prometheus-0 │  │ Prometheus-1 │  │ Prometheus-2 │ │ │
│  │  │              │  │              │  │              │ │ │
│  │  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │ │ │
│  │  │ │Prometheus│ │  │ │Prometheus│ │  │ │Prometheus│ │ │ │
│  │  │ │  :9090   │ │  │ │  :9090   │ │  │ │  :9090   │ │ │ │
│  │  │ └──────────┘ │  │ └──────────┘ │  │ └──────────┘ │ │ │
│  │  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │ │ │
│  │  │ │  Thanos  │ │  │ │  Thanos  │ │  │ │  Thanos  │ │ │ │
│  │  │ │ Sidecar  │ │  │ │ Sidecar  │ │  │ │ Sidecar  │ │ │ │
│  │  │ └──────────┘ │  │ └──────────┘ │  │ └──────────┘ │ │ │
│  │  │      ▼       │  │      ▼       │  │      ▼       │ │ │
│  │  │  ┌────────┐  │  │  ┌────────┐  │  │  ┌────────┐  │ │ │
│  │  │  │  PVC   │  │  │  │  PVC   │  │  │  │  PVC   │  │ │ │
│  │  │  └────────┘  │  │  └────────┘  │  │  └────────┘  │ │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘ │ │
│  │                                                          │ │
│  │  ┌─────────────────────────────────────────────────┐   │ │
│  │  │         Service (ClusterIP + Headless)          │   │ │
│  │  └─────────────────────────────────────────────────┘   │ │
│  │                          ▲                              │ │
│  │  ┌───────────────────────┴──────────────────────────┐  │ │
│  │  │                   Ingress (Optional)             │  │ │
│  │  └──────────────────────────────────────────────────┘  │ │
│  └──────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## 🤝 Support

- **Issues**: [GitHub Issues](https://github.com/fireballindustries/prometheus-pod/issues)
- **Documentation**: See [docs/README.md](docs/README.md)
- **Security**: See [docs/SECURITY.md](docs/SECURITY.md)
- **Examples**: See [examples/](examples/)

---

## 📄 License

MIT License - See [LICENSE](LICENSE) file

---

## 🔥 About Fireball Industries

**We Play With Fire So You Don't Have To™**

Fireball Industries specializes in production-ready Kubernetes solutions with personality. Our POD PRODUCTS are designed for the Rancher Apps & Marketplace, providing enterprise-grade monitoring, logging, and observability with minimal friction.

- Security-hardened by default
- Production-tested configurations
- Comprehensive documentation
- Automation-first approach
- Dark millennial humor included at no extra charge

---

**Built with 🔥 by Fireball Industries**

*Patrick Ryan would approve of this sarcasm level.*
