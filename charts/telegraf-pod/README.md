# Telegraf Pod for Fireball Industries Podstore

**We Play With Fire So You Don't Have To™**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.24+-blue.svg)](https://kubernetes.io/)
[![Helm](https://img.shields.io/badge/Helm-3.0+-blue.svg)](https://helm.sh/)

A production-ready Telegraf metrics collection pod for Kubernetes, optimized for deployment via Rancher Apps & Marketplace catalog. Built by professionals who've made all the mistakes so you don't have to.

## 🚀 Quick Start

### Deploy from Rancher Catalog

1. Open Rancher UI → Apps & Marketplace
2. Search for "Telegraf Pod"
3. Click Install
4. Configure (or use sensible defaults)
5. Deploy
6. Profit 📊

### Deploy with Helm

```bash
# Add Fireball repo (when published)
helm repo add fireball https://charts.fireball.industries
helm repo update

# Install with defaults
helm install telegraf fireball/telegraf-pod --namespace telegraf --create-namespace

# Or clone and install locally
git clone https://github.com/fireball-industries/telegraf-pod.git
cd telegraf-pod
helm install telegraf . --namespace telegraf --create-namespace
```

### Verify Deployment

```powershell
# Check pods
kubectl get pods -n telegraf

# View logs
kubectl logs -n telegraf -l app.kubernetes.io/name=telegraf

# Test metrics endpoint
kubectl port-forward -n telegraf svc/telegraf 8080:8080
# Browse to http://localhost:8080/metrics
```

## 📊 What Is This?

A comprehensive Telegraf deployment package that includes:

- ✅ **Pre-configured for Kubernetes** - Works out of the box
- ✅ **Production-hardened** - Security, RBAC, health checks, resource limits
- ✅ **Flexible deployment** - Single instance or per-node DaemonSet
- ✅ **Resource presets** - Small/medium/large for different workloads
- ✅ **200+ input plugins** - System, Docker, Kubernetes, custom
- ✅ **Multiple outputs** - InfluxDB, Prometheus, file, and more
- ✅ **Persistent buffering** - Never lose metrics during outages
- ✅ **Comprehensive docs** - 100+ pages because we actually care
- ✅ **Dark humor** - Patrick Ryan's signature snark throughout

## 🎯 Features

### Deployment Modes

**Deployment Mode** - Single centralized collector
- Best for: Remote endpoints, APIs, aggregated metrics
- Resource usage: Low (1 pod)

**DaemonSet Mode** - Per-node collection
- Best for: Node metrics, Docker stats, system monitoring
- Resource usage: Higher (1 pod per node)

### Pre-configured Inputs

- **System**: CPU, memory, disk, network, processes
- **Docker**: Container stats and metrics
- **Kubernetes**: Node metrics, cluster inventory
- **Custom**: Prometheus endpoints, HTTP, StatsD, exec

### Pre-configured Outputs

- **InfluxDB**: v1 and v2 support
- **Prometheus**: Metrics exposition
- **File**: Local debugging/backup
- **50+ others**: Available via configuration

### Security Features

- 🔒 Non-root execution
- 🔒 Read-only root filesystem
- 🔒 Dropped capabilities
- 🔒 RBAC with minimal permissions
- 🔒 Network policies
- 🔒 Secret management
- 🔒 Pod Security Standards compliant

### Production Features

- 🏥 Health checks (liveness/readiness)
- 📊 Resource limits and requests
- 💾 Persistent storage for buffering
- 🔄 Rolling updates
- 🚨 Pod disruption budgets
- 📈 ServiceMonitor for Prometheus Operator
- 🔍 Comprehensive logging

## 📖 Documentation

- **[Complete Guide](docs/README.md)** - 100+ pages of comprehensive documentation
- **[Security Guide](docs/SECURITY.md)** - Best practices and compliance
- **[Examples](examples/)** - Pre-configured scenarios
- **[Scripts](scripts/)** - Automation and management tools

## 🛠️ Configuration

### Resource Presets

Choose based on your collection frequency and scale:

```yaml
# Low-frequency (60s intervals)
resourcePreset: small

# Standard production (10s intervals) - DEFAULT
resourcePreset: medium

# High-frequency (1s intervals)
resourcePreset: large

# Custom
resourcePreset: custom
customResources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 2000m
    memory: 2Gi
```

### Example: Full Kubernetes Monitoring

```yaml
# values.yaml
deploymentMode: daemonset
resourcePreset: large

hostNetwork: true
hostVolumes:
  enabled: true

rbac:
  create: true
  clusterRole: true

config:
  outputs:
    prometheus_client:
      enabled: true
    influxdb_v2:
      enabled: true
      urls: ["http://influxdb:8086"]
      token: "${INFLUX_TOKEN}"

  inputs:
    cpu:
      enabled: true
    mem:
      enabled: true
    docker:
      enabled: true
    kubernetes:
      enabled: true
    kube_inventory:
      enabled: true
```

See [examples/](examples/) for more scenarios.

## 🔐 Security

Security is not optional. This pod includes:

- **Non-root execution** - User 999
- **Minimal capabilities** - All dropped
- **Read-only filesystem** - Immutable
- **RBAC** - Read-only Kubernetes access
- **Network policies** - Restrictive by default
- **Secret management** - Never commit credentials
- **Compliance ready** - PCI, HIPAA, SOC 2

Read the full [Security Guide](docs/SECURITY.md).

## 🤖 Management Scripts

Included PowerShell scripts for common operations:

```powershell
# Deploy/manage instances
.\scripts\manage-telegraf.ps1 -Action deploy -Namespace telegraf-prod -Preset large

# Health check
.\scripts\manage-telegraf.ps1 -Action health-check -Namespace telegraf-prod

# Test metrics collection
.\scripts\test-metrics.ps1 -Namespace telegraf-prod -Plugin cpu,memory

# Generate custom configs
.\scripts\generate-config.ps1 -Scenario k8s-full -OutputPath values-custom.yaml

# Performance tuning recommendations
.\scripts\manage-telegraf.ps1 -Action tune -Namespace telegraf-prod
```

## 🏗️ Architecture

```
Rancher Catalog
      ↓
┌─────────────────────────────────────┐
│   Kubernetes Cluster (k3s)          │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  Telegraf Pod                 │ │
│  │  • Deployment or DaemonSet    │ │
│  │  • ConfigMap (telegraf.conf)  │ │
│  │  • RBAC (ServiceAccount)      │ │
│  │  • PVC (metric buffering)     │ │
│  │  • Service (Prometheus)       │ │
│  └───────────────────────────────┘ │
│           ↓                         │
│  Outputs:                           │
│  • InfluxDB                         │
│  • Prometheus                       │
│  • File                             │
└─────────────────────────────────────┘
```

## 📋 Requirements

- Kubernetes 1.24+ (tested on k3s)
- Helm 3.0+
- 256MB RAM minimum (per pod)
- Rancher (for catalog deployment)

## 📦 What's Included

```
telegraf-pod/
├── Chart.yaml              # Helm chart metadata
├── values.yaml             # Default configuration
├── README.md              # This file
├── templates/             # Kubernetes manifests
│   ├── deployment.yaml
│   ├── daemonset.yaml
│   ├── configmap.yaml
│   ├── serviceaccount.yaml
│   ├── rbac.yaml
│   ├── service.yaml
│   ├── pvc.yaml
│   ├── servicemonitor.yaml
│   ├── networkpolicy.yaml
│   └── NOTES.txt
├── docs/                  # Comprehensive documentation
│   ├── README.md          # 100+ page guide
│   └── SECURITY.md        # Security best practices
├── scripts/               # Management automation
│   ├── manage-telegraf.ps1
│   ├── test-metrics.ps1
│   └── generate-config.ps1
└── examples/              # Pre-configured scenarios
    ├── kubernetes-full-monitoring.yaml
    ├── docker-monitoring.yaml
    ├── custom-app-monitoring.yaml
    ├── high-availability.yaml
    └── minimal-monitoring.yaml
```

## 🎓 Use Cases

### 1. Complete Kubernetes Cluster Monitoring
Deploy as DaemonSet with full RBAC for comprehensive cluster observability.

### 2. Docker Host Metrics
Single instance monitoring Docker containers and host system.

### 3. Application Metrics Collection
Scrape Prometheus endpoints from multiple services.

### 4. Remote Endpoint Monitoring
HTTP, SNMP, or API polling from centralized collector.

### 5. Custom Metrics Pipeline
Ingest StatsD, exec scripts, or custom plugins.

## 🔧 Troubleshooting

### Pod won't start

```powershell
# Check events
kubectl describe pod -n telegraf <pod-name>

# View logs
kubectl logs -n telegraf <pod-name>

# Common issues:
# - Image pull failures (check pullSecrets)
# - OOMKilled (increase resource preset)
# - CrashLoopBackOff (check config syntax)
```

### No metrics collected

```powershell
# Test configuration
kubectl exec -n telegraf deployment/telegraf -- \
  telegraf --test --config /etc/telegraf/telegraf.conf

# Check RBAC (for Kubernetes metrics)
kubectl auth can-i get pods --as=system:serviceaccount:telegraf:telegraf

# Enable hostVolumes (for Docker metrics)
```

### High memory usage

```powershell
# Check current usage
kubectl top pods -n telegraf

# Solutions:
# 1. Use larger preset (small → medium → large)
# 2. Reduce buffer: metric_buffer_limit: 5000
# 3. Increase interval: interval: "30s"
# 4. Enable persistence for overflow
```

See the [full troubleshooting guide](docs/README.md#monitoring--troubleshooting).

## 🤝 Contributing

We accept contributions! Areas we need help:

- Additional example configurations
- Plugin presets for common scenarios
- Grafana dashboards
- Documentation improvements
- Bug fixes
- Terrible puns (high bar, we have standards)

Process:
1. Fork repository
2. Create feature branch
3. Make changes with tests
4. Submit pull request
5. Await code review (with sarcasm)

## 📜 License

MIT License (Make It Terrible)

See [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

**Warranty:** None. Void. Nonexistent.

**Liability:** We are not responsible for:
- Data loss
- Infrastructure fires (literal or metaphorical)
- Metric cardinality explosions
- Your manager's disappointed face
- 3 AM pager alerts
- Existential dread

**Use at your own risk.** That said, we use this in production ourselves, so it's probably fine.

## 📞 Support

**Fireball Industries Support:**
- 📧 Email: support@fireball.industries
- ⏰ Hours: When we feel like it (Mon-Fri 9-5 EST)
- 📜 SLA: Best effort (we'll try real hard)
- 🐛 Issues: https://github.com/fireball-industries/telegraf-pod/issues

**Community:**
- Stack Overflow: Tag `telegraf` + `kubernetes`
- Telegraf Slack: #telegraf channel
- Kubernetes Slack: #rancher

## 🌟 Why Choose This Pod?

**vs. Running Telegraf Manually:**
- ✅ Pre-configured for Kubernetes
- ✅ Production hardening included
- ✅ One-click deployment
- ✅ Comprehensive documentation
- ✅ Actually maintained

**vs. Official Telegraf Helm Chart:**
- ✅ Rancher catalog integration
- ✅ Resource presets
- ✅ Better defaults
- ✅ Security-first design
- ✅ Way more documentation
- ✅ Patrick Ryan's humor

**vs. Writing Your Own:**
- ✅ Save weeks of work
- ✅ Avoid common pitfalls
- ✅ Battle-tested in production
- ✅ Regular updates
- ✅ Support available

## 🔥 About Fireball Industries

**We Play With Fire So You Don't Have To™**

We're a team of infrastructure engineers who've seen things. Terrible things. Things that wake us up at 3 AM. We build tools to prevent you from experiencing the same horrors.

Our products:
- **Telegraf Pod** - This thing
- **Alert Manager Pod** - For when things go wrong
- **Grafana Loki Pod** - For when you need to know why
- More chaos engineering tools coming soon

**Philosophy:**
- Security first
- Documentation matters
- Dark humor required
- No bullshit marketing
- Actually use what we build

## 📊 Stats

- 📄 **100+ pages** of documentation
- 🔧 **6** example configurations
- 🤖 **3** management scripts
- 🔒 **8** security features
- 📦 **3** resource presets
- 🎯 **2** deployment modes
- 🔥 **∞** levels of snark

## 🗺️ Roadmap

- [x] v1.0: Initial release
- [ ] v1.1: Additional input plugin presets
- [ ] v1.2: Grafana dashboard templates
- [ ] v1.3: Prometheus alerting rules
- [ ] v1.4: Auto-tuning recommendations
- [ ] v2.0: eBPF-based collection (maybe)

## 🎉 Acknowledgments

- **InfluxData** - For Telegraf
- **Rancher** - For making Kubernetes manageable
- **Our Production Systems** - For teaching us what breaks
- **Coffee** - For making this possible
- **Stack Overflow** - You know why

## 📚 Additional Resources

- [Telegraf Documentation](https://docs.influxdata.com/telegraf/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/)
- [InfluxDB Docs](https://docs.influxdata.com/influxdb/)
- [Prometheus Docs](https://prometheus.io/docs/)

---

**Fireball Industries** - We Play With Fire So You Don't Have To™

*Professional Chaos Engineering Since 2024*

*Now with 87% more snark than competing solutions*

Made with 🔥 (and excessive amounts of caffeine) by Patrick Ryan and the Fireball Industries team.

---

**Start monitoring in < 5 minutes. Seriously.**

```bash
helm install telegraf . --namespace telegraf --create-namespace
```

That's it. You're done. Go get coffee. ☕
