# Home Assistant Pod - Rancher App Store Ready

This Helm chart is **ready for Rancher App Store deployment** with full multi-tenant support.

## What's Included

### Core Chart Files
- ✅ **Chart.yaml** - Chart metadata with Rancher annotations
- ✅ **values.yaml** - Default configuration values
- ✅ **values-k3s.yaml** - K3s-specific optimizations
- ✅ **values-production.yaml** - Production defaults
- ✅ **templates/** - Kubernetes resource templates
- ✅ **.helmignore** - Package exclusion rules

### Rancher-Specific Files
- ✅ **questions.yaml** - Interactive UI form for Rancher (400+ lines)
- ✅ **app-readme.md** - App catalog description and quick start
- ✅ **README.md** - Full chart documentation
- ✅ **LICENSE** - Apache 2.0 license

### Additional Resources
- ✅ **INSTALL.md** - Detailed installation guide
- ✅ **QUICKREF.md** - Quick reference
- ✅ **alerts/** - Prometheus alerts
- ✅ **dashboards/** - Grafana dashboard
- ✅ **examples/** - Example configurations
- ✅ **scripts/** - Management scripts

## Rancher Annotations Added

```yaml
catalog.cattle.io/certified: partner
catalog.cattle.io/display-name: "Home Assistant Pod"
catalog.cattle.io/release-name: home-assistant-pod
catalog.cattle.io/type: cluster-tool
catalog.cattle.io/namespace: home-assistant
catalog.cattle.io/scope: namespace
catalog.cattle.io/kube-version: ">=1.20.0-0"
catalog.cattle.io/rancher-version: ">=2.6.0-0"
```

## Deployment Instructions

See [RANCHER-APP-STORE-DEPLOYMENT.md](../RANCHER-APP-STORE-DEPLOYMENT.md) for complete deployment guide including:
- Adding chart to Rancher catalog
- Multi-tenant configuration
- Client self-service workflow
- Common deployment scenarios
- Troubleshooting
- Security best practices

## Quick Start for Rancher

1. **Add Repository** to Rancher:
   ```
   Apps → Repositories → Create
   Name: fireball-industries
   URL: https://charts.fireballindustries.com
   ```

2. **Make Available to All Clients**:
   ```yaml
   spec:
     projectRegistryEnabled: true
   ```

3. **Clients Deploy**:
   - Navigate to Apps → Charts
   - Search "Home Assistant Pod"
   - Click Install
   - Configure via UI form (powered by questions.yaml)
   - Deploy!

## Multi-Tenant Features

### Self-Service Portal
- ✅ Clients browse Apps catalog
- ✅ Deploy to their namespaces
- ✅ Configure through intuitive UI
- ✅ Manage their instances
- ✅ Upgrade when ready

### Namespace Isolation
- ✅ Each client has isolated namespace(s)
- ✅ NetworkPolicy support for segmentation
- ✅ RBAC per namespace
- ✅ Resource quotas (optional)

### Configuration Flexibility
The `questions.yaml` provides organized UI sections:
- Basic Configuration (timezone, version, resources)
- Database Configuration (SQLite, PostgreSQL, external)
- Storage (config, media, backups)
- Networking (service types, ingress, TLS)
- Device Access (USB, Bluetooth, GPIO)
- Cameras (storage, retention)
- Monitoring (Prometheus integration)
- MQTT (broker configuration)
- Advanced (security, RBAC, autoscaling)

## Testing the Chart

Before publishing to your catalog:

```bash
# Validate chart
helm lint home-assistant-pod/

# Test template rendering
helm template test-release home-assistant-pod/

# Dry-run installation
helm install test-release home-assistant-pod/ --dry-run --debug

# Package chart
helm package home-assistant-pod/
```

## Publishing to Rancher Catalog

### Option 1: Helm Repository

```bash
# Package chart
helm package home-assistant-pod/

# Generate/update index
helm repo index . --url https://charts.fireballindustries.com

# Upload to web server
# - home-assistant-pod-1.0.0.tgz
# - index.yaml
```

### Option 2: Git Repository

```bash
# Commit chart to Git repo
git add home-assistant-pod/
git commit -m "Add Home Assistant Pod v1.0.0"
git push

# Rancher will sync automatically if configured as Git-based catalog
```

## Chart Structure

```
home-assistant-pod/
├── Chart.yaml                 # Chart metadata + Rancher annotations
├── values.yaml                # Default values (723 lines)
├── values-k3s.yaml           # K3s-specific
├── values-production.yaml    # Production defaults
├── questions.yaml            # ⭐ Rancher UI form (400+ lines)
├── app-readme.md             # ⭐ Rancher catalog description
├── README.md                 # Full documentation
├── INSTALL.md                # Installation guide
├── QUICKREF.md               # Quick reference
├── LICENSE                   # Apache 2.0
├── .helmignore              # Package exclusions
├── templates/               # Kubernetes resources
│   ├── _helpers.tpl
│   ├── statefulset.yaml
│   ├── postgresql-statefulset.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── pvc.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── rbac.yaml
│   ├── serviceaccount.yaml
│   ├── networkpolicy.yaml
│   ├── servicemonitor.yaml
│   └── NOTES.txt
├── alerts/
│   └── alerts-homeassistant.yaml
├── dashboards/
│   └── homeassistant-overview.json
├── examples/
│   ├── industrial-iot.yaml
│   └── minimal-home.yaml
├── config-templates/
│   ├── configuration.yaml.example
│   ├── automations.yaml.example
│   └── secrets.yaml.example
└── scripts/
    ├── manage-homeassistant.ps1
    ├── test-homeassistant.ps1
    └── device-discovery.ps1
```

## Version Information

- **Chart Version**: 1.0.0
- **App Version**: 2024.12.0 (Home Assistant)
- **Kubernetes**: >=1.20.0
- **Rancher**: >=2.6.0

## Support

- **Repository**: https://github.com/fireballindustries/home-assistant-pod
- **Home Assistant**: https://www.home-assistant.io/
- **Maintainer**: Patrick Ryan (patrick@fireballindustries.com)

## License

Apache 2.0 - See LICENSE file

---

## Ready for Production ✅

This chart is production-ready and fully configured for Rancher App Store deployment with:
- ✅ Multi-tenant support
- ✅ Self-service deployment
- ✅ Intuitive UI configuration
- ✅ Complete documentation
- ✅ Security best practices
- ✅ Monitoring integration
- ✅ High availability options
- ✅ Fleet fallback compatibility

**All files have been preserved with original URLs and configurations unchanged.**
