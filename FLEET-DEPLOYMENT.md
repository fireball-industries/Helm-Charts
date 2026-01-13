# Fleet Auto-Deployment

**Force Deploy Baseline Services to All Tenant Namespaces**

⚠️ **Use only when requested by client.** This removes tenant control over deployments.

---

## Overview

Fleet auto-deploys specified charts to all tenant namespaces matching a label selector.

**Use cases:**
- Client requests baseline services for all tenants
- Centralized monitoring/logging
- Security tools

**Requirements:**
- Tenant watcher must label namespaces with `tenant=true`

---

## Setup

### Step 1: Create fleet.yaml

**In repository root:**

```yaml
# fleet.yaml - Auto-deploy to all tenant namespaces

# Shared Infrastructure
- name: monitoring
  namespace: monitoring
  targetNamespace: monitoring
  helm:
    chart: charts/prometheus-pod
    releaseName: prometheus
  targets:
    - clusterSelector: {}

# Per-Tenant Baseline Services
- name: tenant-monitoring
  helm:
    chart: charts/node-exporter-pod
    releaseName: node-exporter
  targets:
    - clusterSelector: {}
      namespaceSelector:
        matchLabels:
          tenant: "true"

- name: tenant-mqtt
  helm:
    chart: charts/mosquitto-mqtt-pod
    releaseName: mqtt-broker
  targets:
    - clusterSelector: {}
      namespaceSelector:
        matchLabels:
          tenant: "true"
```

**Commit and push:**
```bash
git add fleet.yaml
git commit -m "Add Fleet configuration"
git push
```

### Step 2: Add Fleet Git Repository

Navigate to:
```
Rancher UI → ☰ Menu → Continuous Delivery → Git Repos → Create
```

Configure:

| Field | Value |
|-------|-------|
| **Name** | `fireball-helm-charts` |
| **Repository URL** | `https://github.com/fireball-industries/Helm-Charts` |
| **Branch** | `main` |
| **Paths** | *(leave empty)* |
| **Polling Interval** | `15s` |

**Authentication (if private):**
- Type: HTTP Basic Auth
- Username: GitHub username
- Password: GitHub PAT (scope: `repo`)

Click "Create".

### Step 3: Verify

Check deployment status:
```
Continuous Delivery → Git Repos → fireball-helm-charts
Status: ✅ Active
```

Check bundles:
```
Continuous Delivery → Advanced → Bundles
```

Check workloads:
```
☰ Menu → Cluster → Workloads
Filter by tenant namespaces
```

---

## Tenant Watcher Integration

### Update Tenant Watcher

Add label when creating namespaces:

```bash
#!/bin/bash
TENANT_NAME="$1"

kubectl create namespace "${TENANT_NAME}"
kubectl label namespace "${TENANT_NAME}" tenant=true

# Fleet auto-deploys within 15 seconds
```

### Verify Labels

List tenant namespaces:
```bash
kubectl get namespaces -l tenant=true
```

Check specific namespace:
```bash
kubectl get namespace <tenant-name> --show-labels
```

---

## How It Works

1. Tenant watcher creates namespace with `tenant=true` label
2. Fleet detects new namespace (15 seconds)
3. Fleet auto-deploys all charts with matching namespace selector
4. Updates to charts auto-deploy (15 seconds after push)

---

## Admin Tasks

### Add Service to Fleet Baseline

Edit fleet.yaml:
```yaml
- name: tenant-new-service
  helm:
    chart: charts/new-service-pod
    releaseName: new-service
  targets:
    - clusterSelector: {}
      namespaceSelector:
        matchLabels:
          tenant: "true"
```

```bash
git add fleet.yaml
git commit -m "Add new-service to Fleet baseline"
git push
```

Deploys to all tenant namespaces in 15 seconds.

### Force Fleet Update
```
Continuous Delivery → Git Repos → fireball-helm-charts → ⋮ → Force Update
```

### Rollback Fleet Deployment

**Git revert:**
```bash
git revert HEAD
git push
# Auto-rolls back in 15 seconds
```

**UI rollback:**
```
Continuous Delivery → Bundles → [bundle-name] → ⋮ → Rollback
```

---

## Troubleshooting

### Fleet Not Deploying to New Tenant

Check namespace label:
```bash
kubectl get namespace <tenant-name> --show-labels
```

Should show `tenant=true`. If missing:
```bash
kubectl label namespace <tenant-name> tenant=true
```

### Deployment Stuck

Force update:
```
Continuous Delivery → Bundles → [bundle-name] → ⋮ → Force Update
```

---

**Fireball Industries**
