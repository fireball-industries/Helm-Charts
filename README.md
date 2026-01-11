# Fireball Industries Podstore - Helm Charts Repository

Welcome to the **Fireball Industries Podstore** Helm Charts Repository! This catalog provides enterprise-ready Helm charts optimized for deployment through Rancher Apps & Marketplace.

## Overview

This repository hosts curated Helm charts that integrate seamlessly with Rancher's catalog system, enabling one-click deployment of containerized applications to your k3s/Kubernetes clusters.

## 🎯 Features

- **Rancher-Optimized**: Charts include Rancher-specific annotations and question-driven deployment wizards
- **Production-Ready**: Security hardening, resource presets, and health probes configured by default
- **Project Isolation**: Deploy multiple instances to separate namespaces via Rancher projects
- **UI-Driven Configuration**: Interactive forms in Rancher UI for easy customization
- **k3s Compatible**: Tested on k3s 1.25+ managed by Rancher

## 📦 Available Charts

### Alert Manager
Enterprise-grade Prometheus Alertmanager for managing and routing alerts to various receivers (Slack, email, PagerDuty, etc.).

- **Version**: 1.0.0
- **App Version**: v0.26.0
- **Resource Presets**: Small, Medium, Large
- **Security**: Non-root execution (UID 65534), dropped capabilities
- **Storage**: Persistent volume support for alert state
- **Integration**: Pre-configured receiver templates

[View Chart Details](./charts/alert-manager/)

## 🚀 Quick Start

### Adding to Rancher Catalog

1. **Navigate to Rancher UI** → Apps & Marketplace → Repositories
2. **Add Repository**:
   - Name: `fireball-podstore-charts`
   - Target: `Git repository containing Helm chart or cluster template definitions`
   - Git Repo URL: `https://github.com/fireball-industries/fireball-podstore-charts`
   - Git Branch: `main`
3. **Refresh** the catalog
4. Browse available charts under **Fireball Industries** category

### Deploying via Rancher UI

1. Go to **Apps & Marketplace** → **Charts**
2. Search for **Alert Manager** (or desired chart)
3. Click **Install**
4. Fill in the deployment form:
   - Namespace selection
   - Resource preset (Small/Medium/Large)
   - Storage configuration
   - Receiver endpoints
5. Click **Install** to deploy

### Deploying via Helm CLI

```bash
# Add the repository
helm repo add fireball-podstore https://fireball-industries.github.io/fireball-podstore-charts

# Update repositories
helm repo update

# Install Alert Manager
helm install my-alertmanager fireball-podstore/alert-manager \
  --namespace monitoring \
  --create-namespace \
  --set resources.preset=medium
```

## 📋 Repository Structure

```
fireball-podstore-charts/
├── charts/
│   └── alert-manager/
│       ├── Chart.yaml              # Chart metadata with Rancher annotations
│       ├── values.yaml             # Default configuration values
│       ├── questions.yaml          # Rancher UI deployment wizard
│       ├── app-readme.md           # Rancher catalog description
│       ├── README.md               # Comprehensive chart documentation
│       └── templates/
│           ├── namespace.yaml      # Namespace creation
│           ├── pvc.yaml            # Persistent volume claim
│           ├── configmap.yaml      # Alertmanager configuration
│           ├── deployment.yaml     # Application deployment
│           ├── service.yaml        # Service exposure
│           ├── _helpers.tpl        # Template helpers
│           └── NOTES.txt           # Post-installation notes
├── index.yaml                      # Helm repository index (auto-generated)
└── README.md                       # This file
```

## 🔧 Chart Development Guidelines

### Rancher Integration Requirements

1. **Chart.yaml Annotations**:
   ```yaml
   annotations:
     catalog.cattle.io/display-name: "Descriptive Name"
     catalog.cattle.io/release-name: "chart-name"
     catalog.cattle.io/certified: "partner"
     catalog.cattle.io/kube-version: ">=1.25.0"
   ```

2. **questions.yaml**: Define interactive questions for Rancher UI deployment wizard

3. **app-readme.md**: Provide catalog description shown in Rancher marketplace

4. **Resource Presets**: Offer small/medium/large configurations via dropdown

5. **Security Defaults**:
   - Non-root user execution
   - Read-only root filesystem where possible
   - Dropped capabilities
   - Security context constraints

### Testing Charts

```bash
# Lint the chart
helm lint charts/alert-manager

# Dry-run installation
helm install test-release charts/alert-manager --dry-run --debug

# Template output verification
helm template test-release charts/alert-manager

# Install to test cluster
helm install test-release charts/alert-manager -n test --create-namespace
```

## 🏢 About Fireball Industries

**Fireball Industries Podstore** delivers enterprise-grade containerized solutions for modern cloud-native infrastructure. Our charts are designed by Patrick Ryan and team to provide secure, scalable, and production-ready deployments.

## 📞 Support & Contributions

- **Issues**: Report bugs or request features via GitHub Issues
- **Documentation**: Comprehensive guides in each chart's README
- **Community**: Join our discussions for best practices and tips

## 📄 License

Copyright © 2026 Fireball Industries - Patrick Ryan. All rights reserved.

---

**Built with ❤️ by Fireball Industries | Powering Cloud-Native Excellence**
