# Prometheus Pod - Comprehensive Documentation

> **Fireball Industries - We Play With Fire So You Don't Have To™**

## Table of Contents

1. [Introduction](#introduction)
2. [Features](#features)
3. [Architecture](#architecture)
4. [Quick Start](#quick-start)
5. [Installation](#installation)
6. [Configuration](#configuration)
7. [Deployment Modes](#deployment-modes)
8. [Resource Sizing](#resource-sizing)
9. [Storage Planning](#storage-planning)
10. [Service Discovery](#service-discovery)
11. [Alert Rules](#alert-rules)
12. [PromQL Queries](#promql-queries)
13. [Integration Guides](#integration-guides)
14. [High Availability Setup](#high-availability-setup)
15. [Thanos Integration](#thanos-integration)
16. [Performance Tuning](#performance-tuning)
17. [Backup and Restore](#backup-and-restore)
18. [Troubleshooting](#troubleshooting)
19. [Migration Guide](#migration-guide)
20. [Security Best Practices](#security-best-practices)
21. [Compliance Considerations](#compliance-considerations)
22. [FAQ](#faq)
23. [Appendices](#appendices)

---

## Introduction

Welcome to the Prometheus Pod documentation. If you're reading this, you've either:

1. Made a wise decision to deploy monitoring properly
2. Been forced to deploy monitoring by your CTO
3. Broken production and need to fix it at 3am (sorry)

This is a **POD PRODUCT** - a self-contained, deployable Prometheus instance that customers install from the Fireball Industries Podstore via Rancher Apps & Marketplace. Each deployment creates an isolated Prometheus instance in the customer's chosen namespace.

### What This Is

- ✅ A complete, production-ready Prometheus deployment
- ✅ Helm chart with sensible defaults that actually work
- ✅ Pre-configured for Kubernetes monitoring
- ✅ Security-hardened out of the box
- ✅ Thoroughly documented (yes, really)
- ✅ Includes HA mode with Thanos support
- ✅ Resource presets that won't bankrupt you

### What This Is NOT

- ❌ A hosted monitoring service (you deploy it)
- ❌ A multi-tenant SaaS platform
- ❌ A replacement for actually understanding your systems
- ❌ Magic (though it might feel like it)

### Why Another Prometheus Chart?

Great question. The ecosystem has:
- `prometheus-operator` (complex, operator overhead)
- `kube-prometheus-stack` (kitchen sink included)
- Various community charts (varying quality)

We built this because we needed:
- **Simple deployment** - Click, configure, done
- **Sensible defaults** - Works out of the box, not after 3 hours of tuning
- **Security first** - Non-root, minimal permissions, network policies
- **Actual documentation** - Not just API specs
- **Production ready** - Battle-tested in real deployments

If you want a simple, secure, well-documented Prometheus deployment that won't page you at 3am, you're in the right place.

---

## Features

### Core Features

- **Multiple Deployment Modes**: Single instance (Deployment) or HA (StatefulSet)
- **Persistent Storage**: Required by default (because data loss is bad)
- **Resource Presets**: Small, Medium, Large, XLarge, Custom sizing
- **Auto-Discovery**: Kubernetes pods, services, nodes, endpoints
- **Pre-configured Alerts**: Common failure scenarios covered
- **RBAC**: Minimal permissions for service discovery
- **Security Hardening**: Non-root, read-only FS, dropped capabilities
- **Health Probes**: Liveness, readiness, startup probes
- **Self-Monitoring**: ServiceMonitor for meta-monitoring

### Advanced Features

- **High Availability**: StatefulSet with 2+ replicas
- **Thanos Sidecar**: For HA deduplication and long-term storage
- **Remote Write/Read**: Federation and external storage
- **Network Policies**: Ingress/egress traffic control
- **PodDisruptionBudget**: Prevent all replicas evicting simultaneously
- **Anti-Affinity Rules**: Spread replicas across nodes
- **Custom Alert Rules**: Add your own via ConfigMap
- **Ingress Support**: HTTPS access with TLS
- **Query Logging**: Debug slow queries

### Kubernetes Integration

- **Service Discovery**: Automatic for pods, services, nodes
- **Annotation-Based Scraping**: `prometheus.io/scrape: "true"`
- **Multiple Namespaces**: Can scrape across namespace boundaries
- **StatefulSet Support**: For HA with per-replica storage
- **ConfigMap Reloading**: Updates without pod restart
- **Secret Management**: For Thanos object storage, TLS certs

---

## Architecture

### Single Instance Mode

```
┌─────────────────────────────────────────────────────────┐
│                     Kubernetes Cluster                  │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │          Monitoring Namespace                   │   │
│  │                                                 │   │
│  │  ┌─────────────────────────────────────────┐   │   │
│  │  │         Prometheus Deployment           │   │
│  │  │                                         │   │
│  │  │  ┌─────────────────────────────────┐   │   │
│  │  │  │      Prometheus Container       │   │   │
│  │  │  │                                 │   │   │
│  │  │  │  - Scrapes K8s API              │   │   │
│  │  │  │  - Scrapes discovered targets   │   │   │
│  │  │  │  - Evaluates alert rules        │   │   │
│  │  │  │  - Stores TSDB data             │   │   │
│  │  │  │  - Serves Web UI & API          │   │   │
│  │  │  └─────────────────────────────────┘   │   │
│  │  │                 │                      │   │
│  │  │                 │ PVC Mount            │   │
│  │  │                 ▼                      │   │
│  │  │  ┌─────────────────────────────────┐   │   │
│  │  │  │  PersistentVolumeClaim (20Gi)   │   │   │
│  │  │  │  - TSDB blocks                  │   │   │
│  │  │  │  - WAL segments                 │   │   │
│  │  │  └─────────────────────────────────┘   │   │
│  │  └─────────────────────────────────────────┘   │
│  │                                                 │
│  │  ┌─────────────────────────────────────────┐   │
│  │  │           Service (ClusterIP)           │   │
│  │  │         Port 9090 → Pod:9090            │   │
│  │  └─────────────────────────────────────────┘   │
│  │                                                 │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Pros**:
- Simple to deploy and manage
- Lower resource usage
- Easier to reason about
- Perfect for dev/test/small clusters

**Cons**:
- Single point of failure
- Downtime during pod restarts
- Can't scale horizontally

### High Availability Mode

```
┌───────────────────────────────────────────────────────────────────────────┐
│                         Kubernetes Cluster                                │
│                                                                           │
│  ┌───────────────────────────────────────────────────────────────────┐   │
│  │                    Monitoring Namespace                           │   │
│  │                                                                   │   │
│  │  ┌─────────────────────┐       ┌─────────────────────┐           │   │
│  │  │   Prometheus-0      │       │   Prometheus-1      │           │   │
│  │  │  (StatefulSet)      │       │  (StatefulSet)      │           │   │
│  │  │                     │       │                     │           │   │
│  │  │  ┌──────────────┐   │       │  ┌──────────────┐   │           │   │
│  │  │  │ Prometheus   │   │       │  │ Prometheus   │   │           │   │
│  │  │  │ Container    │   │       │  │ Container    │   │           │   │
│  │  │  └──────────────┘   │       │  └──────────────┘   │           │   │
│  │  │  ┌──────────────┐   │       │  ┌──────────────┐   │           │   │
│  │  │  │ Thanos       │   │       │  │ Thanos       │   │           │   │
│  │  │  │ Sidecar      │   │       │  │ Sidecar      │   │           │   │
│  │  │  └──────────────┘   │       │  └──────────────┘   │           │   │
│  │  │         │           │       │         │           │           │   │
│  │  │         ▼           │       │         ▼           │           │   │
│  │  │  ┌──────────────┐   │       │  ┌──────────────┐   │           │   │
│  │  │  │ PVC (20Gi)   │   │       │  │ PVC (20Gi)   │   │           │   │
│  │  │  └──────────────┘   │       │  └──────────────┘   │           │   │
│  │  └─────────────────────┘       └─────────────────────┘           │   │
│  │            │                              │                      │   │
│  │            └──────────────┬───────────────┘                      │   │
│  │                           │                                      │   │
│  │                           ▼                                      │   │
│  │            ┌──────────────────────────────┐                      │   │
│  │            │   Service (ClusterIP)        │                      │   │
│  │            │   Load balanced across pods  │                      │   │
│  │            └──────────────────────────────┘                      │   │
│  │                           │                                      │   │
│  │                           │                                      │   │
│  │                           ▼                                      │   │
│  │            ┌──────────────────────────────┐                      │   │
│  │            │    Thanos Querier            │                      │   │
│  │            │    (Deduplicates queries)    │                      │   │
│  │            └──────────────────────────────┘                      │   │
│  │                           │                                      │   │
│  │                           ▼                                      │   │
│  │            ┌──────────────────────────────┐                      │   │
│  │            │   Object Storage (S3/GCS)    │                      │   │
│  │            │   (Long-term retention)      │                      │   │
│  │            └──────────────────────────────┘                      │   │
│  │                                                                   │   │
│  └───────────────────────────────────────────────────────────────────┘   │
│                                                                           │
└───────────────────────────────────────────────────────────────────────────┘
```

**Pros**:
- No single point of failure
- Continues working if one replica dies
- Can survive node failures
- Scalable query capacity

**Cons**:
- More complex to manage
- Higher resource usage (2x+ pods)
- Duplicate data without Thanos
- More expensive

**When to Use HA**:
- Production environments
- SLA requirements > 99%
- Can't afford monitoring downtime
- Multi-node clusters
- Compliance requirements

---

## Quick Start

### 5-Minute Deployment

The fastest path from zero to metrics:

```bash
# 1. Add Fireball Industries Helm repo (if not using Rancher)
helm repo add fireball https://charts.fireballindustries.com
helm repo update

# 2. Install with defaults
helm install prometheus fireball/prometheus-pod \\
  --namespace monitoring \\
  --create-namespace

# 3. Wait for pod to be ready
kubectl wait --for=condition=ready pod \\
  -l app.kubernetes.io/name=prometheus-pod \\
  -n monitoring \\
  --timeout=5m

# 4. Port-forward to access UI
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# 5. Open http://localhost:9090 in your browser
```

**What you get**:
- ✅ Prometheus running in `monitoring` namespace
- ✅ 15 days retention, 20Gi storage
- ✅ Auto-discovery of K8s pods, services, nodes
- ✅ Pre-configured alert rules
- ✅ Web UI on port 9090
- ✅ 2Gi RAM, 2 CPU limits

### Via Rancher UI

Even easier if you're using Rancher:

1. **Navigate**: Apps & Marketplace → Charts
2. **Search**: "Prometheus Pod"
3. **Click**: Install
4. **Configure**: 
   - Select target namespace (or create new)
   - Choose resource preset (Medium is default)
   - Adjust retention if needed
   - Enable HA if desired
5. **Deploy**: Click Install
6. **Done**: Check Apps → Installed Apps for status

---

## Installation

### Prerequisites

**Kubernetes Cluster**:
- Version: 1.24+
- Distribution: Any (k3s optimized, but works everywhere)
- Nodes: 1+ (3+ recommended for HA)

**Storage**:
- StorageClass with dynamic provisioning
- Or pre-provisioned PersistentVolumes
- Default StorageClass configured (or specify one)

**Network**:
- Pod network connectivity
- Egress to scrape targets
- Ingress to pods (for scraping)

**RBAC**:
- Cluster-admin permissions for installation
- Or ability to create ClusterRole/ClusterRoleBinding

**Helm**:
- Version: 3.0+
- Configured with cluster access

### Installation Methods

#### Method 1: Helm CLI

```bash
# Basic installation
helm install prometheus fireball/prometheus-pod \\
  --namespace monitoring \\
  --create-namespace

# With custom values
helm install prometheus fireball/prometheus-pod \\
  --namespace monitoring \\
  --create-namespace \\
  --values my-values.yaml

# With inline overrides
helm install prometheus fireball/prometheus-pod \\
  --namespace monitoring \\
  --create-namespace \\
  --set resourcePreset=large \\
  --set deploymentMode=ha \\
  --set replicaCount=3
```

#### Method 2: Rancher Catalog

1. Log into Rancher UI
2. Select target cluster
3. Navigate to Apps & Marketplace
4. Click "Charts"
5. Find "Prometheus Pod"
6. Click "Install"
7. Fill out the form:
   - **Name**: prometheus (or custom)
   - **Namespace**: monitoring (or custom)
   - **Deployment Mode**: single or ha
   - **Resource Preset**: small/medium/large/xlarge
   - **Retention**: Adjust time/size
   - **Thanos**: Enable if HA + long-term storage
8. Click "Install"
9. Wait for deployment (check Apps → Installed Apps)

#### Method 3: GitOps (ArgoCD/Flux)

**ArgoCD Application**:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: prometheus
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://charts.fireballindustries.com
    chart: prometheus-pod
    targetRevision: 1.0.0
    helm:
      values: |
        deploymentMode: ha
        replicaCount: 2
        resourcePreset: medium
        thanos:
          enabled: true
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

**Flux HelmRelease**:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: prometheus
  namespace: monitoring
spec:
  interval: 5m
  chart:
    spec:
      chart: prometheus-pod
      version: 1.0.0
      sourceRef:
        kind: HelmRepository
        name: fireball
        namespace: flux-system
  values:
    deploymentMode: ha
    replicaCount: 2
    resourcePreset: medium
    thanos:
      enabled: true
```

### Verification

After installation, verify everything is working:

```bash
# Check pod status
kubectl get pods -n monitoring

# Expected output:
# NAME            READY   STATUS    RESTARTS   AGE
# prometheus-0    1/1     Running   0          2m

# Check PVC
kubectl get pvc -n monitoring

# Expected output:
# NAME                        STATUS   VOLUME                 CAPACITY   ACCESS MODES
# prometheus-0-storage        Bound    pvc-abc123...          20Gi       RWO

# Check service
kubectl get svc -n monitoring

# Expected output:
# NAME           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
# prometheus     ClusterIP   10.43.100.50    <none>        9090/TCP   2m

# Check logs
kubectl logs -n monitoring prometheus-0

# Should see:
# level=info ts=... caller=main.go:xxx msg="Server is ready to receive web requests."

# Port-forward and test
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# Open http://localhost:9090
# Run query: up
# Should see targets
```

**Sanity Checks**:

1. **Targets**: Go to Status → Targets in UI
   - Should see kubernetes-apiservers, kubernetes-nodes, etc.
   - All should be UP (or most of them)

2. **TSDB Status**: Go to Status → TSDB Status
   - Should see metrics being ingested
   - Check "Number of Series"

3. **Graph**: Go to Graph tab
   - Run: `up{job="kubernetes-nodes"}`
   - Should see your nodes

4. **Alerts**: Go to Alerts
   - Should see pre-configured rules
   - Most should be inactive (green)

---

## Configuration

### values.yaml Structure

The `values.yaml` file is organized into logical sections:

```yaml
# Image configuration
image: {...}

# Deployment mode (single vs HA)
deploymentMode: single

# Resource presets (easy sizing)
resourcePreset: medium
presets: {...}

# Custom resources (if preset=custom)
resources: {...}

# Storage & retention
persistence: {...}
retention: {...}

# Prometheus behavior
prometheus: {...}

# Scrape configurations
scrapeConfigs: {...}

# Alerting rules
alerting: {...}

# Remote write/read
remoteWrite: {...}
remoteRead: {...}

# Thanos sidecar
thanos: {...}

# Service exposure
service: {...}
ingress: {...}

# RBAC & security
rbac: {...}
serviceAccount: {...}
securityContext: {...}

# High availability
highAvailability: {...}

# Network policies
networkPolicy: {...}
```

### Common Configuration Patterns

#### Small Dev Environment

```yaml
resourcePreset: small
retention:
  time: 7d
  size: 8GB
persistence:
  size: 10Gi
scrapeConfigs:
  kubernetesPods:
    enabled: true
  kubernetesServiceEndpoints:
    enabled: false
  kubernetesCadvisor:
    enabled: false
alerting:
  enabled: false
```

**Use case**: Local development, testing, CI/CD

#### Production Single Instance

```yaml
resourcePreset: large
retention:
  time: 30d
  size: 40GB
persistence:
  size: 50Gi
  storageClass: fast-ssd
prometheus:
  enableQueryLog: true
  walCompression: true
alerting:
  enabled: true
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager.monitoring.svc:9093
ingress:
  enabled: true
  className: nginx
  hosts:
    - host: prometheus.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: prometheus-tls
      hosts:
        - prometheus.example.com
```

**Use case**: Production with acceptable downtime SLA

#### HA Production with Thanos

```yaml
deploymentMode: ha
replicaCount: 3
resourcePreset: large

highAvailability:
  antiAffinity: hard
  podDisruptionBudget:
    enabled: true
    minAvailable: 2

thanos:
  enabled: true
  objectStorageConfig:
    secretName: thanos-objstore-config
    secretKey: objstore.yml

retention:
  time: 15d  # Local retention (Thanos has long-term)
  size: 12GB

persistence:
  size: 20Gi
  storageClass: fast-ssd

alerting:
  enabled: true
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager-0.alertmanager.monitoring.svc:9093
            - alertmanager-1.alertmanager.monitoring.svc:9093

remoteWrite:
  enabled: true
  configs:
    - url: http://thanos-receive.monitoring.svc:10908/api/v1/receive
      queue_config:
        capacity: 10000
        max_shards: 50
```

**Use case**: Enterprise production, strict SLA, long-term storage

### Resource Preset Details

#### Small Preset

```yaml
resourcePreset: small
# Results in:
resources:
  limits:
    cpu: 1000m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 256Mi
storage: 10Gi
retentionTime: 7d
retentionSize: 8GB
```

**Sizing**:
- Targets: 1-5
- Samples/sec: ~500
- Series: ~10,000
- Queries/sec: Light usage

**Cost**: ~$5-15/month (depending on cloud)

#### Medium Preset (Default)

```yaml
resourcePreset: medium
# Results in:
resources:
  limits:
    cpu: 2000m
    memory: 2Gi
  requests:
    cpu: 500m
    memory: 1Gi
storage: 20Gi
retentionTime: 15d
retentionSize: 16GB
```

**Sizing**:
- Targets: 5-50
- Samples/sec: ~2,000
- Series: ~50,000
- Queries/sec: Moderate

**Cost**: ~$20-50/month

#### Large Preset

```yaml
resourcePreset: large
# Results in:
resources:
  limits:
    cpu: 4000m
    memory: 8Gi
  requests:
    cpu: 1000m
    memory: 4Gi
storage: 50Gi
retentionTime: 30d
retentionSize: 40GB
```

**Sizing**:
- Targets: 50-500
- Samples/sec: ~10,000
- Series: ~500,000
- Queries/sec: Heavy

**Cost**: ~$100-200/month

#### XLarge Preset

```yaml
resourcePreset: xlarge
# Results in:
resources:
  limits:
    cpu: 8000m
    memory: 16Gi
  requests:
    cpu: 2000m
    memory: 8Gi
storage: 100Gi
retentionTime: 60d
retentionSize: 80GB
```

**Sizing**:
- Targets: 500-5,000
- Samples/sec: ~50,000
- Series: ~5,000,000
- Queries/sec: Very heavy

**Cost**: ~$500-1000/month

---

## Deployment Modes

### Single Instance Mode

**How it works**:
- Uses Kubernetes `Deployment`
- Single pod (replica=1)
- One PVC for storage
- Service routes to single pod

**Configuration**:

```yaml
deploymentMode: single
# replicaCount is ignored in single mode
```

**Scaling**:
- Vertical only (increase resources)
- Cannot add replicas in single mode
- To scale horizontally, switch to HA mode

**Pros**:
- Simple to deploy and manage
- Lower resource consumption
- Easier troubleshooting
- Predictable behavior
- Lower cost

**Cons**:
- Single point of failure
- Downtime during:
  - Pod restarts
  - Node failures
  - Upgrades
  - Storage issues
- No horizontal scaling

**When to use**:
- Development environments
- Testing/staging
- Small clusters (< 10 nodes)
- Non-critical monitoring
- Cost-sensitive deployments
- SLA allows downtime

### High Availability Mode

**How it works**:
- Uses Kubernetes `StatefulSet`
- Multiple pods (replica=2+)
- Per-pod PVC (storage-0, storage-1, etc.)
- Service load-balances across pods
- Each replica scrapes independently

**Configuration**:

```yaml
deploymentMode: ha
replicaCount: 2  # Or 3, 5, etc. (odd numbers recommended)

highAvailability:
  antiAffinity: soft  # Or hard
  podDisruptionBudget:
    enabled: true
    minAvailable: 1
```

**Scaling**:

```bash
# Scale up
helm upgrade prometheus fireball/prometheus-pod \\
  --reuse-values \\
  --set replicaCount=3

# Scale down
helm upgrade prometheus fireball/prometheus-pod \\
  --reuse-values \\
  --set replicaCount=2
```

**Pros**:
- No single point of failure
- Survives pod/node failures
- Zero-downtime upgrades
- Horizontal scaling
- Higher query capacity
- Better SLA

**Cons**:
- More complex
- Higher resource usage (2x-3x)
- Duplicate data (each replica scrapes)
- Inconsistent queries (time skew between replicas)
- Higher cost
- Requires Thanos for query deduplication

**When to use**:
- Production environments
- Critical monitoring
- SLA > 99.9%
- Multi-node clusters
- Cannot afford downtime
- Have budget for redundancy

### HA with Thanos

The proper way to do HA:

**Configuration**:

```yaml
deploymentMode: ha
replicaCount: 2

thanos:
  enabled: true
  objectStorageConfig:
    secretName: thanos-objstore-config
    secretKey: objstore.yml
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 100m
      memory: 128Mi

highAvailability:
  antiAffinity: hard  # Force spreading
  podDisruptionBudget:
    enabled: true
    minAvailable: 1
```

**Thanos Object Storage Secret**:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: thanos-objstore-config
  namespace: monitoring
type: Opaque
stringData:
  objstore.yml: |
    type: S3
    config:
      bucket: prometheus-thanos
      endpoint: s3.amazonaws.com
      access_key: YOUR_ACCESS_KEY
      secret_key: YOUR_SECRET_KEY
```

**What Thanos adds**:
- ✅ Query deduplication (handles duplicate scrapes)
- ✅ Long-term storage (uploads blocks to S3/GCS)
- ✅ Downsampling (reduce old data resolution)
- ✅ Global query view (query across all replicas)
- ✅ Unlimited retention (object storage is cheap)

**Architecture with Thanos**:

```
Prometheus-0 ──┐
               ├─→ Thanos Querier ──→ Query API
Prometheus-1 ──┘        │
                        │
                        ▼
                   Object Storage (S3/GCS)
                   (Long-term blocks)
```

**Deployment**:

```bash
# 1. Create object storage secret
kubectl create secret generic thanos-objstore-config \\
  --from-file=objstore.yml=./objstore.yml \\
  -n monitoring

# 2. Install with Thanos enabled
helm install prometheus fireball/prometheus-pod \\
  --namespace monitoring \\
  --create-namespace \\
  --set deploymentMode=ha \\
  --set replicaCount=2 \\
  --set thanos.enabled=true

# 3. Deploy Thanos Querier (separate chart or custom)
# See: https://thanos.io/tip/components/query.md/
```

**Trade-offs**:
- ➕ Solves HA duplicate data problem
- ➕ Adds unlimited retention
- ➕ Reduces local storage costs
- ➖ Adds complexity (another component)
- ➖ Object storage costs
- ➖ Slightly higher query latency

---

## Resource Sizing

This is where most people screw up. Let's fix that.

### The Math (Simplified)

**Memory usage formula**:

```
RAM = (active_series * 2KB) + (samples_per_sec * 60 * scrape_interval * 8 bytes) + overhead

Where:
- active_series = number of unique metric combinations
- samples_per_sec = ingestion rate
- scrape_interval = how often you scrape (60s default)
- overhead = ~500MB for Prometheus itself
```

**Example calculation**:

```
Scenario: 50 targets, 100 series per target, 1m scrape interval

active_series = 50 * 100 = 5,000
samples_per_sec = 5,000 / 60 = 83.3
memory_for_series = 5,000 * 2KB = 10MB
memory_for_samples = 83.3 * 60 * 60 * 8 = 2.4MB
overhead = 500MB

Total RAM = 10MB + 2.4MB + 500MB ≈ 512MB

Recommendation: 1-2GB (2x-4x headroom for queries, spikes)
```

### Sizing by Target Count

| Targets | Series | Samples/s | RAM Needed | Storage (15d) | Preset |
|---------|--------|-----------|------------|---------------|--------|
| 1-5 | 500 | 8 | 512Mi | 5Gi | small |
| 5-20 | 2,000 | 33 | 1Gi | 10Gi | small |
| 20-50 | 5,000 | 83 | 2Gi | 20Gi | medium |
| 50-100 | 10,000 | 166 | 4Gi | 30Gi | medium/large |
| 100-500 | 50,000 | 833 | 8Gi | 50Gi | large |
| 500-1,000 | 100,000 | 1,666 | 16Gi | 100Gi | xlarge |
| 1,000+ | 1M+ | 16,666+ | 32Gi+ | 200Gi+ | custom |

**Note**: These are estimates. Actual usage varies based on:
- Number of labels per metric
- Scrape interval
- Retention period
- Query load
- Churn rate (how often series appear/disappear)

### Sizing by Cluster Size

| Cluster | Nodes | Pods | RAM | Storage | Preset |
|---------|-------|------|-----|---------|--------|
| Tiny | 1-3 | < 50 | 512Mi | 10Gi | small |
| Small | 3-10 | 50-200 | 2Gi | 20Gi | medium |
| Medium | 10-50 | 200-1,000 | 8Gi | 50Gi | large |
| Large | 50-200 | 1,000-5,000 | 16Gi | 100Gi | xlarge |
| Huge | 200+ | 5,000+ | 32Gi+ | 200Gi+ | custom |

### Storage Calculation

**Formula**:

```
Storage = samples_per_sec * retention_seconds * bytes_per_sample * compression_ratio

Where:
- samples_per_sec = ingestion rate
- retention_seconds = retention in seconds (15d = 1,296,000s)
- bytes_per_sample = ~1.3 bytes (TSDB is efficient)
- compression_ratio = ~3-4x (depends on data)
```

**Example**:

```
50 targets, 100 series each, 15d retention

samples_per_sec = (50 * 100) / 60 = 83.3
retention_seconds = 15 * 24 * 60 * 60 = 1,296,000
bytes_per_sample = 1.3
compression = 4

Storage = 83.3 * 1,296,000 * 1.3 / 4
        = ~35,000,000 bytes
        = ~35MB

But TSDB has overhead (blocks, WAL), so add 50%:
Storage = 35MB * 1.5 = ~50MB

For safety, use 20Gi preset (400x headroom for growth)
```

**Rule of thumb**:
- 1,000 samples/sec × 15d retention ≈ 20GB
- 10,000 samples/sec × 15d retention ≈ 200GB
- Double retention time → double storage
- Double sample rate → double storage

### Monitoring Prometheus Resources

**Useful queries**:

```promql
# Memory usage
process_resident_memory_bytes

# Memory usage as % of limit
(process_resident_memory_bytes / on() kube_pod_container_resource_limits{resource="memory", container="prometheus"}) * 100

# Disk usage
prometheus_tsdb_storage_blocks_bytes

# Disk usage as % of retention limit
(prometheus_tsdb_storage_blocks_bytes / prometheus_tsdb_retention_limit_bytes) * 100

# Ingestion rate (samples per second)
rate(prometheus_tsdb_head_samples_appended_total[5m])

# Active series count
prometheus_tsdb_head_series

# Chunks in memory
prometheus_tsdb_head_chunks

# WAL size
prometheus_tsdb_wal_storage_size_bytes
```

**Set up alerts**:

```yaml
# Already included in pre-configured alerts
- alert: PrometheusHighMemoryUsage
  expr: (process_resident_memory_bytes / on() kube_pod_container_resource_limits{resource="memory"}) > 0.85
  for: 15m

- alert: PrometheusDiskSpaceLow
  expr: (prometheus_tsdb_storage_blocks_bytes / prometheus_tsdb_retention_limit_bytes) > 0.85
  for: 10m
```

### Right-Sizing Process

1. **Start with preset** based on cluster size
2. **Deploy and monitor** for 24-48 hours
3. **Check actual usage**:
   ```bash
   kubectl top pod -n monitoring
   ```
4. **Adjust if needed**:
   - Memory > 80% used → upgrade preset
   - Memory < 30% used → downgrade preset
   - Disk > 80% used → increase retention.size or decrease retention.time
5. **Tune scrape intervals** if ingestion too high
6. **Add relabeling** to drop unnecessary metrics

**Example tuning**:

```bash
# Check current usage
kubectl top pod -n monitoring prometheus-0

# Output: NAME            CPU    MEMORY
#         prometheus-0    250m   1500Mi

# Currently using medium preset (2Gi limit)
# Usage is 75% (1500Mi / 2000Mi)
# This is fine, no change needed

# If usage was > 85%, upgrade:
helm upgrade prometheus fireball/prometheus-pod \\
  --reuse-values \\
  --set resourcePreset=large
```

---

## Storage Planning

Storage is critical. Screw this up and you'll lose data or run out of disk at 3am.

### Retention Types

Prometheus has two retention mechanisms:

**Time-based** (`--storage.tsdb.retention.time`):
- Keeps data for X days/hours
- Example: `15d` = 15 days
- Older blocks are deleted
- Default: 15d

**Size-based** (`--storage.tsdb.retention.size`):
- Keeps data until TSDB reaches X GB
- Example: `16GB`
- Oldest blocks deleted when limit reached
- Default: disabled (time-based only)

**Both can be set** - Prometheus uses whichever is hit first.

### Retention Configuration

```yaml
retention:
  time: 15d    # Keep 15 days of data
  size: 16GB   # Or until 16GB used (whichever comes first)
```

**Choosing retention.time**:

| Use Case | Retention | Reasoning |
|----------|-----------|-----------|
| Dev/Test | 1d-7d | Fast iteration, don't need history |
| Production (non-critical) | 7d-15d | Enough for most troubleshooting |
| Production (critical) | 15d-30d | Cover weekends, incident investigation |
| Compliance | 30d-90d+ | Regulatory requirements |
| Long-term | Use Thanos | Cheaper than local storage |

**Choosing retention.size**:

```
retention.size should be ~80% of PVC size

Why 80%?
- TSDB needs overhead for:
  - WAL (Write-Ahead Log)
  - Compaction temp space
  - Block metadata
  - Filesystem overhead

Example:
  PVC = 20Gi
  retention.size = 16GB (80%)
```

**Common mistakes**:

❌ **retention.size = PVC size**
- TSDB will fill disk 100%
- No space for WAL/compaction
- Pod crashes with "no space left on device"

❌ **retention.time too long for PVC size**
- Retention time will never be reached
- retention.size kicks in first
- Confusing behavior

❌ **retention.size in wrong units**
- Prometheus uses: B, KB, MB, GB, TB, PB, EB
- Not: Bi, KiB, GiB (those don't work)

✅ **Correct configuration**:

```yaml
persistence:
  size: 20Gi

retention:
  time: 15d
  size: 16GB  # 80% of 20Gi
```

### Storage Growth Estimation

**Formula**:

```
Daily growth = (samples_per_sec * 86400 * bytes_per_sample) / compression_ratio

Where:
- samples_per_sec = your ingestion rate
- 86400 = seconds in a day
- bytes_per_sample = ~1.3 bytes
- compression_ratio = ~4x
```

**Example**:

```
100 samples/sec

Daily = 100 * 86400 * 1.3 / 4
      = 2,808,000 bytes
      = ~2.7MB/day

For 15d retention:
Total = 2.7MB * 15 = ~40MB

But add 2x for safety:
Recommended PVC = 80MB → use 1Gi minimum
```

**Real-world multipliers**:

Small clusters (1-10 nodes):
- 100-1,000 samples/sec
- ~10MB-100MB/day
- 15d retention = ~1-2GB
- **PVC: 10Gi** (room for growth)

Medium clusters (10-50 nodes):
- 1,000-10,000 samples/sec
- ~100MB-1GB/day
- 15d retention = ~2-15GB
- **PVC: 20-50Gi**

Large clusters (50+ nodes):
- 10,000-100,000 samples/sec
- ~1-10GB/day
- 15d retention = ~15-150GB
- **PVC: 100-200Gi**

### PVC Resizing

**Most storage classes support online resizing**:

```bash
# Edit values.yaml
persistence:
  size: 50Gi  # Was 20Gi

# Upgrade release
helm upgrade prometheus fireball/prometheus-pod \\
  --namespace monitoring \\
  --values values.yaml

# Check PVC (should auto-expand)
kubectl get pvc -n monitoring

# If not automatic, delete and recreate pod
kubectl delete pod -n monitoring prometheus-0
# StatefulSet will recreate with new size
```

**Check if StorageClass supports resizing**:

```bash
kubectl get sc

# Look for: ALLOWVOLUMEEXPANSION = true
```

**For non-resizable storage**:

Option 1: Backup and restore
```bash
# 1. Backup (see Backup section)
# 2. Delete old PVC
kubectl delete pvc prometheus-0-storage -n monitoring
# 3. Update values.yaml with new size
# 4. Redeploy
helm upgrade prometheus fireball/prometheus-pod --values values.yaml
# 5. Restore data
```

Option 2: Remote write to new instance
```bash
# 1. Deploy new Prometheus with larger storage
# 2. Configure old Prometheus remote_write to new
# 3. Wait for data sync
# 4. Switch over
# 5. Delete old instance
```

### Storage Performance

**IOPS requirements**:

| Workload | IOPS | Storage Type |
|----------|------|--------------|
| Dev/Test | 100-500 | Standard HDD |
| Production (light) | 500-1,000 | SSD |
| Production (medium) | 1,000-3,000 | Fast SSD |
| Production (heavy) | 3,000+ | NVMe |

**Latency impact**:

- High latency → slow queries
- High latency → slow compaction
- High latency → WAL bottleneck
- High latency → OOM (memory compensates)

**Storage class examples**:

```yaml
# k3s (local-path)
persistence:
  storageClass: local-path
  # Fast, but node-local (not portable)

# AWS EBS gp3
persistence:
  storageClass: gp3
  # Good balance of cost/performance

# AWS EBS io2
persistence:
  storageClass: io2
  # High IOPS, expensive

# GCP pd-ssd
persistence:
  storageClass: pd-ssd
  # Balanced SSD

# Azure managed-premium
persistence:
  storageClass: managed-premium
  # Premium SSD
```

### Monitoring Storage

**Queries**:

```promql
# Current storage size
prometheus_tsdb_storage_blocks_bytes

# Storage as % of retention limit
(prometheus_tsdb_storage_blocks_bytes / prometheus_tsdb_retention_limit_bytes) * 100

# Blocks on disk
prometheus_tsdb_blocks_loaded

# Oldest block timestamp
prometheus_tsdb_lowest_timestamp

# Head chunk size (in-memory, not yet persisted)
prometheus_tsdb_head_chunks_storage_size_bytes

# WAL size
prometheus_tsdb_wal_storage_size_bytes

# Compactions
rate(prometheus_tsdb_compactions_total[5m])

# Compaction duration
rate(prometheus_tsdb_compaction_duration_seconds_sum[5m])
```

**Grafana dashboard**:

Import dashboard ID: 12229 (Prometheus Stats)

Or use included queries in custom dashboard.

---

*[Documentation continues with remaining sections... Due to length constraints, I'll create the file in parts]*

---

