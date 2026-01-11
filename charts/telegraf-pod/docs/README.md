# Telegraf Pod for Fireball Industries Podstore

**We Play With Fire So You Don't Have To™**

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Deployment Modes](#deployment-modes)
- [Configuration](#configuration)
- [Resource Presets](#resource-presets)
- [Security](#security)
- [Monitoring & Troubleshooting](#monitoring--troubleshooting)
- [Advanced Usage](#advanced-usage)
- [Migration Guide](#migration-guide)
- [Performance Tuning](#performance-tuning)
- [FAQ](#faq)
- [Support](#support)

---

## Overview

The Telegraf Pod is a production-ready metrics collection solution for Kubernetes environments managed through Rancher. Deploy it from the Rancher Apps & Marketplace catalog with a single click, then watch as it dutifully collects metrics from your infrastructure while you do more important things (like scrolling social media).

**What is Telegraf?**

Telegraf is InfluxData's plugin-driven server agent for collecting and sending metrics and events. It's written in Go, which means it's fast, compiled, and doesn't require a JVM (your ops team will thank you).

**What is This Pod?**

This is a pre-configured, production-hardened Telegraf deployment package that:
- Runs on k3s clusters managed through Rancher
- Supports both single-instance and per-node (DaemonSet) deployment modes
- Comes with sensible defaults that actually work
- Includes comprehensive monitoring, security hardening, and automation
- Contains more dark humor than strictly necessary

### Key Benefits

✅ **One-Click Deployment** - Deploy from Rancher catalog in seconds  
✅ **Multi-Tenancy Ready** - Each deployment creates an isolated instance  
✅ **Production Hardened** - Security contexts, RBAC, resource limits, health checks  
✅ **Flexible Collection** - 200+ input plugins, multiple output formats  
✅ **Built-in Buffering** - Persistent storage prevents metric loss during outages  
✅ **Pre-configured for K8s** - Automatic discovery and collection of cluster metrics  
✅ **Resource Efficient** - Presets optimized for different workload sizes  

---

## Features

### Deployment Options

- **Deployment Mode**: Single centralized collector instance
- **DaemonSet Mode**: Per-node collection for comprehensive coverage
- **Flexible Scaling**: Adjust replicas based on load

### Input Plugins (Pre-configured)

**System Metrics**
- CPU, Memory, Disk, Network, Processes
- Kernel statistics, swap usage
- Disk I/O and filesystem metrics

**Container Metrics**
- Docker container statistics
- Container resource usage
- Service discovery

**Kubernetes Metrics**
- Node-level metrics (kubelet)
- Cluster inventory (pods, deployments, services, etc.)
- API server metrics
- Custom resource monitoring

**Custom Metrics**
- Prometheus endpoint scraping
- StatsD receiver
- HTTP/HTTPS endpoint polling
- Custom exec plugin support

### Output Plugins (Pre-configured)

- **InfluxDB v1/v2**: Time-series database storage
- **Prometheus**: Metrics exposure for scraping
- **File**: Local debugging and backup
- **Extensible**: 50+ output plugins available

### Production Features

🔒 **Security**
- Non-root execution
- Read-only root filesystem
- Dropped capabilities
- SELinux/AppArmor profiles
- Network policies
- Secret management

🏥 **Health & Reliability**
- Liveness probes
- Readiness probes
- Resource limits/requests
- Pod disruption budgets
- Automatic restarts

📊 **Observability**
- Prometheus ServiceMonitor
- Grafana dashboard templates
- Self-monitoring metrics
- Comprehensive logging

⚡ **Performance**
- Metric buffering
- Batch processing
- Connection pooling
- Configurable collection intervals

---

## Architecture

### Components

```
┌─────────────────────────────────────────────────────────────┐
│                    Rancher UI / Catalog                     │
└────────────────────────┬────────────────────────────────────┘
                         │ Deploy
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                   Kubernetes Cluster (k3s)                  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Telegraf Namespace                      │  │
│  │                                                      │  │
│  │  ┌────────────────┐         ┌──────────────────┐   │  │
│  │  │  Deployment    │   OR    │   DaemonSet      │   │  │
│  │  │  (Single Pod)  │         │  (Per-Node Pods) │   │  │
│  │  └────────────────┘         └──────────────────┘   │  │
│  │           │                          │              │  │
│  │           ↓                          ↓              │  │
│  │  ┌─────────────────────────────────────────────┐   │  │
│  │  │         Telegraf Configuration              │   │  │
│  │  │  • Agent settings                           │   │  │
│  │  │  • Input plugins (CPU, Mem, K8s, Docker)    │   │  │
│  │  │  • Output plugins (InfluxDB, Prometheus)    │   │  │
│  │  └─────────────────────────────────────────────┘   │  │
│  │                                                      │  │
│  │  ┌──────────────┐    ┌──────────────────────────┐  │  │
│  │  │ ConfigMap    │    │  PersistentVolumeClaim   │  │  │
│  │  │ (Config)     │    │  (Metric Buffer)         │  │  │
│  │  └──────────────┘    └──────────────────────────┘  │  │
│  │                                                      │  │
│  │  ┌──────────────┐    ┌──────────────────────────┐  │  │
│  │  │ ServiceAccount│   │  RBAC (ClusterRole)     │  │  │
│  │  │              │    │  (K8s API Access)        │  │  │
│  │  └──────────────┘    └──────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  Outputs ↓                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────┐  │
│  │  InfluxDB    │  │  Prometheus  │  │  File (Debug)   │  │
│  └──────────────┘  └──────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **Collection**: Telegraf pods collect metrics from configured inputs
2. **Processing**: Metrics are tagged, aggregated, and buffered
3. **Output**: Processed metrics sent to configured outputs
4. **Buffering**: If outputs fail, metrics are buffered to persistent storage
5. **Retry**: Automatic retry with exponential backoff

### Deployment Modes Comparison

| Feature | Deployment Mode | DaemonSet Mode |
|---------|----------------|----------------|
| **Pods** | Single instance | One per node |
| **Use Case** | Centralized collection | Per-node metrics |
| **Resource Usage** | Low | Higher (multiple pods) |
| **Metric Coverage** | Cluster-wide only | Node-level + cluster-wide |
| **HA** | Supports replicas | Inherent redundancy |
| **Host Access** | Limited | Full host access |
| **Best For** | Remote endpoints, APIs | System metrics, Docker |

---

## Quick Start

### Prerequisites

- Rancher-managed Kubernetes cluster (k3s recommended)
- Kubectl access to cluster
- Helm 3.x installed (for manual deployment)
- At least 256MB available memory per pod

### Deploy from Rancher Catalog

1. **Navigate to Apps & Marketplace**
   - Open Rancher UI
   - Select your cluster
   - Click "Apps & Marketplace"

2. **Find Telegraf Pod**
   - Search for "Telegraf" or browse "Monitoring" category
   - Click "Telegraf Pod by Fireball Industries"

3. **Configure Deployment**
   - **Namespace**: Create new or select existing (e.g., `telegraf-prod`)
   - **Deployment Mode**: Choose `deployment` or `daemonset`
   - **Resource Preset**: Select `small`, `medium`, or `large`
   - **Outputs**: Configure InfluxDB, Prometheus, or file outputs

4. **Deploy**
   - Review settings
   - Click "Install"
   - Wait for pod(s) to become ready (usually < 30 seconds)

5. **Verify**
   ```powershell
   kubectl get pods -n telegraf-prod
   kubectl logs -n telegraf-prod deployment/telegraf
   ```

### Manual Helm Deployment

```bash
# Clone repository
git clone https://github.com/fireball-industries/telegraf-pod.git
cd telegraf-pod

# Deploy with default settings
helm install telegraf . --namespace telegraf --create-namespace

# Deploy with custom values
helm install telegraf . \
  --namespace telegraf-prod \
  --create-namespace \
  --set deploymentMode=daemonset \
  --set resourcePreset=large

# Deploy with custom values file
helm install telegraf . \
  --namespace telegraf-prod \
  --create-namespace \
  --values custom-values.yaml
```

### Quick Test

```powershell
# Check pod status
kubectl get pods -n telegraf

# View metrics collection
kubectl logs -n telegraf -l app.kubernetes.io/name=telegraf --tail=50

# Test Prometheus endpoint
kubectl port-forward -n telegraf svc/telegraf 8080:8080
# Open browser: http://localhost:8080/metrics

# Run configuration test
kubectl exec -n telegraf deployment/telegraf -- telegraf --test --config /etc/telegraf/telegraf.conf
```

---

## Deployment Modes

### Deployment Mode (Single Instance)

**Best For:**
- Scraping remote endpoints (APIs, databases, cloud services)
- Centralized log aggregation
- Low-cardinality metric collection
- Cost-sensitive environments

**Configuration:**
```yaml
deploymentMode: deployment
replicaCount: 1  # Can scale up for HA

# Optional: Enable persistence for buffering
persistence:
  enabled: true
  size: 1Gi
```

**Resource Usage:** ~100-500MB RAM, 0.1-0.5 CPU cores

**Example Use Cases:**
- Scraping Prometheus endpoints from multiple services
- Collecting metrics from cloud provider APIs
- Polling HTTP endpoints for application metrics
- Centralized SNMP monitoring

### DaemonSet Mode (Per-Node)

**Best For:**
- Host-level system metrics
- Docker/container metrics
- Node-specific Kubernetes metrics
- Complete infrastructure visibility

**Configuration:**
```yaml
deploymentMode: daemonset

# Enable host access
hostNetwork: true
hostVolumes:
  enabled: true
  paths:
    - name: docker-socket
      hostPath: /var/run/docker.sock
      mountPath: /var/run/docker.sock
      readOnly: true
    - name: proc
      hostPath: /proc
      mountPath: /host/proc
      readOnly: true
    - name: sys
      hostPath: /sys
      mountPath: /host/sys
      readOnly: true

# RBAC for node metrics
rbac:
  create: true
  clusterRole: true

# Run on all nodes (including masters)
tolerations:
  - operator: Exists
```

**Resource Usage:** ~200MB-1GB RAM per node, 0.1-0.5 CPU per node

**Example Use Cases:**
- Complete node monitoring (CPU, memory, disk, network)
- Docker container statistics
- Per-node Kubernetes metrics
- Hardware sensor data (temperature, fan speed)

### Hybrid Deployment

Deploy both modes for complete coverage:

```bash
# Deploy DaemonSet for node metrics
helm install telegraf-nodes . \
  --namespace telegraf \
  --set deploymentMode=daemonset \
  --set resourcePreset=medium

# Deploy Deployment for remote endpoints
helm install telegraf-remote . \
  --namespace telegraf \
  --set deploymentMode=deployment \
  --set resourcePreset=small \
  --values remote-endpoints-config.yaml
```

---

## Configuration

### values.yaml Structure

The configuration is organized into logical sections:

```yaml
# Deployment settings
deploymentMode: deployment|daemonset
resourcePreset: small|medium|large|custom
replicaCount: 1

# Image settings
image:
  repository: telegraf
  tag: "1.29.0-alpine"
  pullPolicy: IfNotPresent

# Security settings
securityContext: {...}
rbac: {...}
serviceAccount: {...}

# Telegraf configuration
config:
  agent: {...}
  outputs: {...}
  inputs: {...}

# Kubernetes settings
persistence: {...}
service: {...}
monitoring: {...}
```

### Key Configuration Options

#### Agent Settings

```yaml
config:
  agent:
    interval: "10s"              # Collection frequency
    flush_interval: "10s"        # Output flush frequency
    metric_batch_size: 1000      # Metrics per batch
    metric_buffer_limit: 10000   # Max buffered metrics
```

**Recommendations:**
- **High-frequency**: 1-5s intervals (use `large` preset)
- **Standard**: 10-30s intervals (use `medium` preset)
- **Low-frequency**: 60s+ intervals (use `small` preset)

#### Output Configuration

**InfluxDB v2:**
```yaml
config:
  outputs:
    influxdb_v2:
      enabled: true
      urls:
        - "http://influxdb:8086"
      token: "${INFLUX_TOKEN}"      # From environment variable
      organization: "fireball"
      bucket: "telegraf"

# Set token via secret
env:
  - name: INFLUX_TOKEN
    valueFrom:
      secretKeyRef:
        name: telegraf-secrets
        key: influx-token
```

**Prometheus Client:**
```yaml
config:
  outputs:
    prometheus_client:
      enabled: true
      listen: ":8080"
      path: "/metrics"
      expiration_interval: "60s"

# Expose service
service:
  enabled: true
  type: ClusterIP
  ports:
    - name: http
      port: 8080
      targetPort: 8080
```

**File Output (Debugging):**
```yaml
config:
  outputs:
    file:
      enabled: true
      files:
        - "/var/lib/telegraf/metrics.out"
      rotation_max_size: "100MB"
      rotation_max_archives: 5
      data_format: "influx"

persistence:
  enabled: true
  size: 5Gi
```

#### Input Configuration

**System Metrics:**
```yaml
config:
  inputs:
    cpu:
      enabled: true
      percpu: true              # Per-CPU metrics
      totalcpu: true
    mem:
      enabled: true
    disk:
      enabled: true
      ignore_fs:                # Ignore virtual filesystems
        - "tmpfs"
        - "devtmpfs"
```

**Docker Metrics:**
```yaml
config:
  inputs:
    docker:
      enabled: true
      endpoint: "unix:///var/run/docker.sock"
      gather_services: false
      perdevice: true
      total: true

# Enable Docker socket mount
hostVolumes:
  enabled: true
  paths:
    - name: docker-socket
      hostPath: /var/run/docker.sock
      mountPath: /var/run/docker.sock
      readOnly: true
```

**Kubernetes Metrics:**
```yaml
config:
  inputs:
    kube_inventory:
      enabled: true
      url: "https://kubernetes.default.svc"
      bearer_token: "/var/run/secrets/kubernetes.io/serviceaccount/token"
      namespace: ""             # Empty = all namespaces
      resource_include:
        - deployments
        - pods
        - nodes
        - services

# Enable RBAC
rbac:
  create: true
  clusterRole: true
```

**Custom Prometheus Scraping:**
```yaml
config:
  inputs:
    prometheus:
      enabled: true
      urls:
        - http://my-app:9090/metrics
        - http://my-api:8080/metrics
        - http://node-exporter:9100/metrics
```

---

## Resource Presets

Pre-configured resource allocations optimized for different workload patterns.

### Small Preset

**Best For:** Low-frequency collection, testing, development

```yaml
resourcePreset: small

# Specifications:
# CPU Request: 50m
# CPU Limit: 200m
# Memory Request: 64Mi
# Memory Limit: 256Mi
# Collection Interval: 60s
# Buffer Limit: 1,000 metrics
```

**Estimated Capacity:**
- ~10,000 metrics/minute
- ~600,000 metrics/hour
- ~14M metrics/day

**Cost:** ~$2-5/month per pod (depending on cloud provider)

### Medium Preset (Default)

**Best For:** Standard production monitoring

```yaml
resourcePreset: medium

# Specifications:
# CPU Request: 100m
# CPU Limit: 500m
# Memory Request: 128Mi
# Memory Limit: 512Mi
# Collection Interval: 10s
# Buffer Limit: 10,000 metrics
```

**Estimated Capacity:**
- ~100,000 metrics/minute
- ~6M metrics/hour
- ~144M metrics/day

**Cost:** ~$5-10/month per pod

### Large Preset

**Best For:** High-frequency collection, large clusters, comprehensive monitoring

```yaml
resourcePreset: large

# Specifications:
# CPU Request: 250m
# CPU Limit: 1000m (1 core)
# Memory Request: 256Mi
# Memory Limit: 1Gi
# Collection Interval: 1s
# Buffer Limit: 100,000 metrics
```

**Estimated Capacity:**
- ~1M metrics/minute
- ~60M metrics/hour
- ~1.4B metrics/day

**Cost:** ~$15-30/month per pod

### Custom Preset

**Best For:** Specialized requirements

```yaml
resourcePreset: custom

customResources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 2000m
    memory: 2Gi

config:
  agent:
    interval: "5s"
    flush_interval: "5s"
    metric_buffer_limit: 50000
```

### Choosing the Right Preset

```
┌─────────────────────────────────────────────────────────────┐
│                    Decision Tree                            │
└─────────────────────────────────────────────────────────────┘

Collection Interval Needed?
│
├─ > 60s ────────────────────────────────→ SMALL
│
├─ 10-30s ───────────────────────────────→ MEDIUM
│
├─ 1-10s ────────────────────────────────→ LARGE
│
└─ < 1s or special requirements ─────────→ CUSTOM

Number of Metrics?
│
├─ < 50 metrics/interval ────────────────→ SMALL
│
├─ 50-500 metrics/interval ──────────────→ MEDIUM
│
├─ 500-5000 metrics/interval ────────────→ LARGE
│
└─ > 5000 metrics/interval ──────────────→ CUSTOM (scale out)
```

### Monitoring Resource Usage

```powershell
# Check current resource usage
kubectl top pods -n telegraf

# View resource requests/limits
kubectl describe pod -n telegraf <pod-name> | Select-String -Pattern "Requests|Limits" -Context 3

# Check for OOMKilled events
kubectl get events -n telegraf --sort-by='.lastTimestamp' | Select-String -Pattern "OOMKilled"
```

**Signs you need a larger preset:**
- Frequent OOMKilled events
- CPU throttling (check container metrics)
- Increasing metric buffer lag
- Dropped metrics warnings in logs

---

## Security

### Security Hardening Features

This pod implements defense-in-depth security practices:

#### 1. Non-Root Execution

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 999
  fsGroup: 999
```

**Why:** Prevents privilege escalation attacks. If the container is compromised, the attacker has limited permissions.

#### 2. Read-Only Root Filesystem

```yaml
securityContext:
  readOnlyRootFilesystem: true
```

Writable directories are explicitly mounted:
```yaml
volumeMounts:
  - name: tmp
    mountPath: /tmp
  - name: var-run
    mountPath: /var/run
  - name: data
    mountPath: /var/lib/telegraf
```

**Why:** Prevents runtime file modification attacks and malware persistence.

#### 3. Dropped Capabilities

```yaml
securityContext:
  capabilities:
    drop:
      - ALL
```

**Why:** Runs with minimal Linux capabilities, reducing attack surface.

#### 4. Privilege Escalation Prevention

```yaml
securityContext:
  allowPrivilegeEscalation: false
```

**Why:** Prevents processes from gaining more privileges than parent.

#### 5. Seccomp Profile

```yaml
podSecurityContext:
  seccompProfile:
    type: RuntimeDefault
```

**Why:** Restricts system calls available to the container.

### RBAC Configuration

#### ClusterRole (Full K8s Metrics)

```yaml
rbac:
  create: true
  clusterRole: true
```

Grants read-only access to:
- Nodes, pods, services, endpoints
- Deployments, daemonsets, statefulsets
- Jobs, cronjobs
- Persistent volumes/claims
- Ingresses

**Permissions:** Read-only (`get`, `list`, `watch`) only. No write access.

#### Role (Namespace-Scoped)

```yaml
rbac:
  create: true
  clusterRole: false
```

Grants read-only access only within the deployment namespace.

**Use When:** You don't need cluster-wide metrics or have strict RBAC policies.

### Secret Management

**NEVER** commit secrets to values.yaml. Use Kubernetes Secrets:

```bash
# Create secret for InfluxDB token
kubectl create secret generic telegraf-secrets \
  --namespace telegraf \
  --from-literal=influx-token='your-secret-token' \
  --from-literal=influx-password='your-password'
```

Reference in values.yaml:
```yaml
env:
  - name: INFLUX_TOKEN
    valueFrom:
      secretKeyRef:
        name: telegraf-secrets
        key: influx-token

config:
  outputs:
    influxdb_v2:
      token: "${INFLUX_TOKEN}"  # Environment variable substitution
```

### Network Policies

Restrict network access:

```yaml
networkPolicy:
  enabled: true
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: monitoring
      ports:
        - protocol: TCP
          port: 8080
  egress:
    - to:
        - namespaceSelector: {}
      ports:
        - protocol: TCP
          port: 8086  # InfluxDB
        - protocol: TCP
          port: 443   # HTTPS
```

### Pod Security Standards

This pod complies with **Restricted** Pod Security Standard (most restrictive).

Enable Pod Security Admission:
```yaml
# Namespace label
kubectl label namespace telegraf \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted
```

### Audit Logging

Monitor Telegraf API access:

```bash
# View Telegraf ServiceAccount API calls
kubectl get events -n telegraf --watch
```

### Security Checklist

Before deploying to production:

- [ ] Secrets stored in Kubernetes Secrets (not values.yaml)
- [ ] RBAC enabled with minimal permissions
- [ ] Network policies configured
- [ ] Security contexts enabled
- [ ] Pod security standards enforced
- [ ] Image from trusted registry
- [ ] Image scanned for vulnerabilities
- [ ] TLS enabled for outputs (InfluxDB, etc.)
- [ ] Regular security updates scheduled
- [ ] Audit logging enabled

### Vulnerability Scanning

Scan the Telegraf image:

```bash
# Using Trivy
trivy image telegraf:1.29.0-alpine

# Using Grype
grype telegraf:1.29.0-alpine
```

---

## Monitoring & Troubleshooting

### Health Checks

The pod includes comprehensive health checks:

**Liveness Probe:**
```yaml
livenessProbe:
  httpGet:
    path: /
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 30
  failureThreshold: 3
```

**What it does:** Kubernetes restarts the pod if it becomes unresponsive.

**Readiness Probe:**
```yaml
readinessProbe:
  httpGet:
    path: /
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 10
  failureThreshold: 3
```

**What it does:** Removes pod from service endpoints if not ready.

### Viewing Logs

```powershell
# Tail logs from all Telegraf pods
kubectl logs -n telegraf -l app.kubernetes.io/name=telegraf --tail=100 -f

# View logs from specific pod
kubectl logs -n telegraf telegraf-xxxxx

# Previous pod instance (if restarted)
kubectl logs -n telegraf telegraf-xxxxx --previous

# Logs from specific time range
kubectl logs -n telegraf telegraf-xxxxx --since=1h

# Save logs to file
kubectl logs -n telegraf telegraf-xxxxx > telegraf-logs.txt
```

### Common Log Messages

**Normal:**
```
[agent] Config: Interval:10s, Quiet:false, Hostname:"telegraf-xxxxx"
[outputs.prometheus_client] Listening on :8080
[inputs.cpu] Loaded CPU plugin
```

**Warnings:**
```
[outputs.influxdb] Failed to write batch: connection refused
  → Check InfluxDB connectivity

[inputs.docker] Error connecting to Docker: permission denied
  → Enable hostVolumes for Docker socket

[inputs.kube_inventory] Forbidden: pods is forbidden
  → Enable RBAC with clusterRole
```

**Errors:**
```
OOMKilled
  → Increase memory limits (use larger preset)

CrashLoopBackOff
  → Check logs for configuration errors
  → Validate telegraf.conf syntax

ImagePullBackOff
  → Check image repository and credentials
```

### Testing Configuration

```powershell
# Test configuration syntax
kubectl exec -n telegraf deployment/telegraf -- \
  telegraf --test --config /etc/telegraf/telegraf.conf

# Test specific input plugin
kubectl exec -n telegraf deployment/telegraf -- \
  telegraf --test --config /etc/telegraf/telegraf.conf --input-filter cpu

# Collect metrics for 10 seconds (no output)
kubectl exec -n telegraf deployment/telegraf -- \
  telegraf --test --config /etc/telegraf/telegraf.conf --test-wait 10
```

### Checking Metrics Output

**Prometheus Endpoint:**
```powershell
# Port-forward to local machine
kubectl port-forward -n telegraf svc/telegraf 8080:8080

# View metrics in browser or curl
curl http://localhost:8080/metrics

# Count metrics
curl -s http://localhost:8080/metrics | grep -v "^#" | wc -l
```

**InfluxDB:**
```powershell
# Check if data is flowing
influx query 'from(bucket:"telegraf") |> range(start: -5m) |> limit(n:10)'
```

### Performance Monitoring

```powershell
# Resource usage
kubectl top pods -n telegraf

# Detailed metrics
kubectl exec -n telegraf deployment/telegraf -- \
  wget -q -O- http://localhost:8080/metrics | grep telegraf_

# Key metrics to watch:
# - telegraf_write_metrics_written: Metrics successfully written
# - telegraf_write_metrics_dropped: Dropped metrics (should be 0)
# - telegraf_internal_gather_time: Collection time per plugin
# - telegraf_mem_heap_inuse: Memory usage
```

### Common Issues & Solutions

#### Issue: No Metrics Collected

**Symptoms:** Empty Prometheus endpoint, no data in InfluxDB

**Diagnosis:**
```powershell
# Check if inputs are enabled
kubectl exec -n telegraf deployment/telegraf -- \
  telegraf --test --config /etc/telegraf/telegraf.conf

# Check plugin errors
kubectl logs -n telegraf deployment/telegraf | grep -i error
```

**Solutions:**
- Verify input plugins are enabled in values.yaml
- Check RBAC permissions for Kubernetes metrics
- Enable hostVolumes for Docker/system metrics

#### Issue: High Memory Usage / OOMKilled

**Symptoms:** Pod restarts, OOMKilled events

**Diagnosis:**
```powershell
# Check events
kubectl get events -n telegraf --sort-by='.lastTimestamp' | grep OOM

# Current memory usage
kubectl top pods -n telegraf
```

**Solutions:**
1. Increase resource preset: `small` → `medium` → `large`
2. Reduce buffer limit:
   ```yaml
   config:
     agent:
       metric_buffer_limit: 5000  # Lower from 10000
   ```
3. Increase collection interval:
   ```yaml
   config:
     agent:
       interval: "30s"  # Up from 10s
   ```
4. Disable unused plugins
5. Use custom preset with higher limits

#### Issue: Metrics Dropping

**Symptoms:** Warning logs about dropped metrics

**Diagnosis:**
```powershell
# Check for drop warnings
kubectl logs -n telegraf deployment/telegraf | grep -i drop

# Check buffer metrics
kubectl exec -n telegraf deployment/telegraf -- \
  wget -q -O- http://localhost:8080/metrics | grep dropped
```

**Solutions:**
1. Increase buffer limit:
   ```yaml
   config:
     agent:
       metric_buffer_limit: 50000
   ```
2. Increase flush frequency:
   ```yaml
   config:
     agent:
       flush_interval: "5s"
   ```
3. Scale output capacity (InfluxDB, etc.)
4. Enable persistence for temporary buffering

#### Issue: Can't Access Kubernetes Metrics

**Symptoms:** Permission denied errors for kube_inventory

**Diagnosis:**
```powershell
kubectl logs -n telegraf deployment/telegraf | grep -i forbidden
```

**Solutions:**
```yaml
rbac:
  create: true
  clusterRole: true  # Enable cluster-wide access
```

#### Issue: Docker Metrics Not Collected

**Symptoms:** No Docker metrics, permission denied

**Solutions:**
```yaml
# Enable Docker socket mount
hostVolumes:
  enabled: true
  paths:
    - name: docker-socket
      hostPath: /var/run/docker.sock
      mountPath: /var/run/docker.sock
      readOnly: true

# Use DaemonSet mode
deploymentMode: daemonset
```

### Using Management Scripts

```powershell
# Comprehensive health check
.\scripts\manage-telegraf.ps1 -Action health-check -Namespace telegraf

# Validate configuration
.\scripts\manage-telegraf.ps1 -Action validate -Namespace telegraf

# Test metrics collection
.\scripts\test-metrics.ps1 -Namespace telegraf -Plugin cpu,memory -Duration 30

# Performance tuning recommendations
.\scripts\manage-telegraf.ps1 -Action tune -Namespace telegraf

# View aggregated logs
.\scripts\manage-telegraf.ps1 -Action logs -Namespace telegraf
```

---

## Advanced Usage

### Custom Plugin Configuration

Add custom input plugins not included in defaults:

```yaml
config:
  inputs:
    # Add HTTP Response Time monitoring
    http_response:
      enabled: true
      urls:
        - "https://example.com"
        - "https://api.example.com/health"
      response_timeout: "5s"
      
    # Add PostgreSQL monitoring
    postgresql:
      enabled: true
      address: "host=postgres user=telegraf password=${DB_PASSWORD} dbname=postgres"
      
    # Add Redis monitoring
    redis:
      enabled: true
      servers:
        - "tcp://redis:6379"
        - "tcp://redis-slave:6379"

# Add database password secret
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: telegraf-secrets
        key: db-password
```

### Processor Plugins

Transform metrics before output:

```yaml
config:
  # Add custom processors via extraConfig
  processors:
    # Rename fields
    rename:
      enabled: true
      namepass: ["cpu"]
      [[processors.rename.replace]]
        field: "usage_idle"
        dest: "idle_percent"
    
    # Add tags
    enum:
      enabled: true
      [[processors.enum.mapping]]
        tag = "environment"
        [processors.enum.mapping.value_mappings]
          prod = "production"
          dev = "development"
```

### Multiple Outputs

Send different metrics to different destinations:

```yaml
config:
  outputs:
    # Critical metrics to InfluxDB
    influxdb_v2:
      enabled: true
      urls: ["http://influxdb:8086"]
      token: "${INFLUX_TOKEN}"
      namepass: ["cpu", "mem", "disk"]  # Only these metrics
      
    # All metrics to Prometheus
    prometheus_client:
      enabled: true
      listen: ":8080"
      
    # Error metrics to separate bucket
    influxdb_v2_errors:
      urls: ["http://influxdb:8086"]
      token: "${INFLUX_TOKEN}"
      bucket: "errors"
      tagpass:
        status: ["error", "critical"]
```

### Scraping Dynamic Endpoints

Use Kubernetes service discovery:

```yaml
config:
  inputs:
    prometheus:
      enabled: true
      # Kubernetes SD for automatic endpoint discovery
      kubernetes_services:
        - role: endpoints
          namespaces:
            names: ["production"]
          selectors:
            - label: "prometheus.io/scrape=true"
```

### High Availability Deployment

Multiple replicas with load balancing:

```yaml
deploymentMode: deployment
replicaCount: 3  # Multiple instances

# Pod anti-affinity (spread across nodes)
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchLabels:
              app.kubernetes.io/name: telegraf
          topologyKey: kubernetes.io/hostname

# Pod disruption budget
podDisruptionBudget:
  enabled: true
  minAvailable: 2  # At least 2 pods always running

# Use shared persistent storage
persistence:
  enabled: true
  storageClass: "nfs-client"  # Shared storage class
  size: 10Gi
```

### Exporting Metrics to Multiple Formats

```yaml
config:
  outputs:
    # Line protocol to file
    file:
      enabled: true
      files: ["/var/lib/telegraf/metrics.out"]
      data_format: "influx"
      
    # JSON to file
    file_json:
      files: ["/var/lib/telegraf/metrics.json"]
      data_format: "json"
      rotation_max_size: "100MB"
      
    # Prometheus remote write
    prometheus_remote_write:
      url: "http://prometheus:9090/api/v1/write"
      
    # HTTP POST to custom endpoint
    http:
      url: "https://metrics.example.com/ingest"
      method: "POST"
      data_format: "json"
```

### Custom Collection Intervals Per Plugin

```yaml
config:
  agent:
    interval: "10s"  # Default
    
  inputs:
    # Fast collection for critical metrics
    cpu:
      enabled: true
      interval: "1s"
      
    mem:
      enabled: true
      interval: "1s"
      
    # Slower collection for expensive metrics
    docker:
      enabled: true
      interval: "60s"
      
    kube_inventory:
      enabled: true
      interval: "30s"
```

---

## Performance Tuning

### Metric Cardinality Management

**Problem:** High cardinality = explosion in unique metric series = high memory/storage

**Solutions:**

1. **Drop unnecessary tags:**
   ```yaml
   processors:
     strings:
       [[processors.strings.trim]]
         field = "container_name"
         cutset = "/k8s_"
       
     # Drop high-cardinality tags
     tagdrop:
       container_id = ["*"]  # Drop container IDs
   ```

2. **Aggregate metrics:**
   ```yaml
   aggregators:
     basicstats:
       period: "30s"
       stats: ["mean", "min", "max"]
       namepass: ["cpu", "mem"]
   ```

3. **Filter unnecessary metrics:**
   ```yaml
   # Only collect what you need
   config:
     inputs:
       cpu:
         totalcpu: true
         percpu: false  # Disable per-CPU metrics
   ```

### Buffer Tuning

**Symptoms of undersized buffer:**
- "metric buffer overflow" warnings
- Dropped metrics during output failures

**Solutions:**

```yaml
config:
  agent:
    # Increase buffer (more memory usage)
    metric_buffer_limit: 50000
    
    # Enable persistence for overflow
    persistence:
      enabled: true
      size: 5Gi
```

**Calculation:**
```
Buffer Size = (metrics per interval) × (number of intervals to buffer)

Example:
- 5000 metrics per 10s interval
- Want to buffer 5 minutes = 30 intervals
- Required: 5000 × 30 = 150,000 metric buffer limit
```

### Output Performance

**InfluxDB Tuning:**
```yaml
config:
  outputs:
    influxdb_v2:
      # Batch writes
      flush_interval: "10s"
      metric_batch_size: 5000
      
      # Connection pooling
      max_parallel_writes: 10
      
      # Timeout
      timeout: "10s"
```

**Prometheus Tuning:**
```yaml
config:
  outputs:
    prometheus_client:
      # Longer expiration for sparse metrics
      expiration_interval: "120s"
      
      # String optimization
      string_as_label: true
      
      # Disable expensive collectors
      collectors_exclude: ["gocollector", "process"]
```

### CPU Optimization

**Multi-core utilization:**
Telegraf is single-threaded per instance. For CPU-bound workloads:

```yaml
# Option 1: Increase CPU limits
customResources:
  limits:
    cpu: 2000m  # 2 cores

# Option 2: Run multiple instances with input sharding
# Deploy multiple pods with different input filters
```

**Input Plugin Optimization:**
```yaml
config:
  inputs:
    # Disable expensive plugins
    diskio:
      enabled: false  # If not needed
      
    # Reduce collection scope
    net:
      interfaces: ["eth0", "eth1"]  # Don't collect all
      
    docker:
      gather_services: false  # Expensive operation
```

### Memory Optimization

```yaml
# 1. Reduce buffer
config:
  agent:
    metric_buffer_limit: 5000  # Lower from default

# 2. Faster flush
config:
  agent:
    flush_interval: "5s"  # Don't hold metrics long

# 3. Smaller batches
config:
  outputs:
    influxdb_v2:
      metric_batch_size: 1000

# 4. Use Alpine image (already default)
image:
  repository: telegraf
  tag: "1.29.0-alpine"  # ~100MB vs ~300MB for full image
```

### Network Optimization

**Reduce egress bandwidth:**

```yaml
# Compression
config:
  outputs:
    influxdb_v2:
      content_encoding: "gzip"
      
# Sampling (for high-volume metrics)
processors:
  sample:
    rate: 0.1  # Keep 10% of metrics
```

### Benchmarking

```powershell
# Test collection performance
kubectl exec -n telegraf deployment/telegraf -- \
  telegraf --test --config /etc/telegraf/telegraf.conf --test-wait 60

# Analyze internal metrics
kubectl exec -n telegraf deployment/telegraf -- \
  wget -q -O- http://localhost:8080/metrics | grep "internal_gather"

# Key metrics:
# - internal_gather_time_ns: Time spent collecting (nanoseconds)
# - internal_gather_errors: Collection errors
```

---

## FAQ

### General Questions

**Q: What's the difference between this and running Telegraf manually?**

A: This pod provides:
- Pre-configured Kubernetes-optimized settings
- Production hardening (security, RBAC, health checks)
- Resource presets for different workloads
- One-click deployment from Rancher
- Comprehensive documentation and support
- Fireball Industries' signature dark humor

**Q: Can I deploy multiple Telegraf instances?**

A: Yes! Each deployment creates an isolated instance in its own namespace. Deploy as many as needed for different collection scenarios.

**Q: Does this work with other Kubernetes distributions (EKS, GKE, AKS)?**

A: Yes, but it's optimized for k3s on Rancher. Some features (like hostVolumes) may require adjustments for cloud providers.

**Q: How much does this cost?**

A: The pod itself is free (MIT license). You pay for:
- Kubernetes resources (compute/storage)
- Data egress (if sending to external systems)
- InfluxDB/Prometheus hosting (if applicable)

Estimated: $2-30/month per pod depending on preset.

### Configuration Questions

**Q: How do I add a new input plugin?**

A: Edit your values file:
```yaml
config:
  inputs:
    # Add your plugin
    my_plugin:
      enabled: true
      setting1: value1
```

Upgrade the release:
```bash
helm upgrade telegraf . -f values.yaml
```

**Q: Can I use a custom telegraf.conf file?**

A: Yes! Create a ConfigMap with your config and reference it:
```yaml
# Disable generated config
config: {}

# Mount custom config
extraVolumes:
  - name: custom-config
    configMap:
      name: my-telegraf-config

extraVolumeMounts:
  - name: custom-config
    mountPath: /etc/telegraf
```

**Q: How do I update to a new Telegraf version?**

A: Update the image tag:
```yaml
image:
  tag: "1.30.0-alpine"  # New version
```

Then upgrade:
```bash
helm upgrade telegraf . --set image.tag=1.30.0-alpine
```

**Q: Can I collect metrics from outside the cluster?**

A: Yes! Use the HTTP, SNMP, or custom exec plugins:
```yaml
config:
  inputs:
    http_response:
      enabled: true
      urls:
        - "https://external-api.example.com"
    
    snmp:
      enabled: true
      agents: ["10.0.1.100"]
```

### Troubleshooting Questions

**Q: Why aren't my metrics showing up?**

**A:** Check in order:
1. Are pods running? `kubectl get pods -n telegraf`
2. Any errors in logs? `kubectl logs -n telegraf deployment/telegraf`
3. Is the plugin enabled? Check values.yaml
4. Test collection: `kubectl exec ... telegraf --test`
5. Check output connectivity (InfluxDB, etc.)

**Q: Why is my pod OOMKilled?**

**A:** Memory limit too low. Solutions:
1. Use a larger preset (`medium` → `large`)
2. Reduce buffer: `metric_buffer_limit: 5000`
3. Increase collection interval: `interval: "30s"`
4. Disable unused plugins

**Q: How do I debug configuration issues?**

**A:**
```powershell
# Test configuration syntax
kubectl exec -n telegraf deployment/telegraf -- \
  telegraf --test --config /etc/telegraf/telegraf.conf

# View generated config
kubectl exec -n telegraf deployment/telegraf -- \
  cat /etc/telegraf/telegraf.conf

# Check ConfigMap
kubectl get configmap -n telegraf telegraf-config -o yaml
```

**Q: Metrics are delayed/lagging?**

**A:** Output bottleneck. Check:
1. InfluxDB/output system capacity
2. Network latency
3. Batch size too large
4. Enable persistence for buffering

### Security Questions

**Q: Is it safe to run in production?**

A: Yes, with proper configuration:
- [ ] Secrets in Kubernetes Secrets (not values.yaml)
- [ ] RBAC enabled
- [ ] Network policies configured
- [ ] Regular security updates
- [ ] TLS enabled for outputs

**Q: What permissions does Telegraf need?**

A: **Read-only** access to:
- Kubernetes API (for cluster metrics)
- Docker socket (for container metrics)
- Host filesystem `/proc`, `/sys` (for system metrics)

No write permissions required.

**Q: How do I secure the Prometheus endpoint?**

A: Use authentication:
```yaml
# In Telegraf config
config:
  outputs:
    prometheus_client:
      basic_username: "monitoring"
      basic_password: "${PROM_PASSWORD}"

# Or use NetworkPolicy to restrict access
networkPolicy:
  enabled: true
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: monitoring
```

**Q: Can I run this in a PCI/HIPAA/SOC2 environment?**

A: Yes, but ensure:
- All data encrypted in transit (TLS)
- Audit logging enabled
- Network segmentation (NetworkPolicies)
- Regular vulnerability scanning
- Access controls (RBAC)
- Compliance team review

### Performance Questions

**Q: How many metrics can one pod handle?**

A: Depends on preset:
- **Small**: ~10K metrics/minute
- **Medium**: ~100K metrics/minute
- **Large**: ~1M metrics/minute
- **Custom**: Scale as needed

**Q: Should I use Deployment or DaemonSet?**

A:
- **Deployment**: Remote endpoints, centralized collection
- **DaemonSet**: Node metrics, Docker stats, per-host monitoring
- **Both**: Hybrid approach for complete coverage

**Q: How do I scale horizontally?**

A: Multiple approaches:
1. **Increase replicas** (Deployment mode):
   ```yaml
   replicaCount: 3
   ```
2. **Shard inputs** across multiple deployments
3. **Use DaemonSet** for per-node automatic scaling

---

## Migration Guide

### From Standalone Telegraf

If you're currently running Telegraf manually, migrate to this pod:

**1. Export current configuration:**
```bash
# Copy your telegraf.conf
cp /etc/telegraf/telegraf.conf ./telegraf-backup.conf
```

**2. Identify enabled plugins:**
```bash
grep "^\[\[inputs\." telegraf-backup.conf
grep "^\[\[outputs\." telegraf-backup.conf
```

**3. Create values.yaml:**
```yaml
# Enable matching plugins
config:
  inputs:
    # Map your plugins
    cpu:
      enabled: true
    # ... etc
      
  outputs:
    # Map your outputs
    influxdb_v2:
      enabled: true
      urls: ["http://your-influxdb:8086"]
      # ...
```

**4. Deploy:**
```bash
helm install telegraf . -f values.yaml
```

**5. Verify metrics:**
```bash
# Compare metric counts
# Old: influx query 'from(bucket:"telegraf") |> range(start: -5m) |> count()'
# New: Same query after pod deployment
```

**6. Decommission old instance:**
```bash
systemctl stop telegraf
systemctl disable telegraf
```

### From Other Helm Charts

**From Official Telegraf Chart:**

This pod is **not** compatible with the official chart. Migration:

```bash
# 1. Backup old values
helm get values telegraf > old-values.yaml

# 2. Export data (InfluxDB example)
influx backup /tmp/backup

# 3. Uninstall old chart
helm uninstall telegraf

# 4. Install Fireball pod
helm install telegraf-fireball . -f new-values.yaml

# 5. Verify data flow resumes
```

**Key Differences:**
- Different value structure (not drop-in compatible)
- Enhanced security defaults
- Resource preset system
- Comprehensive documentation

### From Prometheus Node Exporter

Telegraf can replace Node Exporter:

```yaml
# Enable system metrics collection
deploymentMode: daemonset
resourcePreset: medium

hostVolumes:
  enabled: true

config:
  inputs:
    cpu:
      enabled: true
    mem:
      enabled: true
    disk:
      enabled: true
    net:
      enabled: true
    diskio:
      enabled: true
    kernel:
      enabled: true
  
  outputs:
    prometheus_client:
      enabled: true
      listen: ":9100"  # Node Exporter default port
```

Update Prometheus scrape config:
```yaml
# Old
- job_name: 'node-exporter'
  kubernetes_sd_configs:
    - role: pod
  relabel_configs:
    - source_labels: [__meta_kubernetes_pod_label_app]
      regex: node-exporter
      action: keep

# New
- job_name: 'telegraf'
  kubernetes_sd_configs:
    - role: pod
  relabel_configs:
    - source_labels: [__meta_kubernetes_pod_label_app_kubernetes_io_name]
      regex: telegraf
      action: keep
```

---

## Support

### Documentation

- **This README**: Comprehensive guide
- **Example Configs**: `examples/` directory
- **Scripts**: `scripts/` with automation tools
- **Helm Chart**: `templates/` with inline comments

### Getting Help

**Fireball Industries Support:**
- Email: support@fireball.industries
- Hours: When we feel like it (actually: Mon-Fri 9-5 EST)
- SLA: Best effort (we'll try real hard)

**Community Support:**
- GitHub Issues: Report bugs, request features
- Stack Overflow: Tag `telegraf` + `kubernetes`
- Telegraf Slack: Join #telegraf channel

### Reporting Issues

When reporting issues, include:

```powershell
# Run diagnostic script
.\scripts\manage-telegraf.ps1 -Action health-check -Namespace telegraf > diagnostics.txt

# Include:
# 1. Pod status
kubectl get pods -n telegraf -o yaml

# 2. Logs
kubectl logs -n telegraf deployment/telegraf --tail=200

# 3. Events
kubectl get events -n telegraf --sort-by='.lastTimestamp'

# 4. Configuration
helm get values telegraf -n telegraf

# 5. Kubernetes version
kubectl version
```

### Contributing

We accept contributions! Process:

1. Fork repository
2. Create feature branch
3. Make changes with tests
4. Submit pull request
5. Await sarcastic but constructive code review

**Areas we need help:**
- Additional example configurations
- Plugin presets for common scenarios
- Grafana dashboards
- Documentation improvements
- Bug fixes
- Terrible puns

### Legal Stuff

**License:** MIT (Make It Terrible)

**Warranty:** None. Absolutely none. If this breaks your production system, that's between you and your life choices.

**Liability:** We're not responsible for:
- Data loss
- Infrastructure fires (metaphorical or literal)
- Existential dread induced by metric cardinality explosion
- Your manager's disappointed face
- Pager alerts at 3 AM

**Use at your own risk.** But also, it's pretty solid and we use it ourselves, so... you'll probably be fine.

---

## Appendix

### Resource Estimation Calculator

```
Estimated Resource Usage:

Memory = Base + (Metrics × Plugin Count × Overhead)
       = 64MB + (metrics_per_interval × 20 plugins × 0.001 MB)

CPU = Base + (Collection Frequency Factor)
    = 50m + (1000 / interval_seconds × 10m)

Examples:
- 100 metrics @ 10s: ~128MB RAM, ~150m CPU → Use MEDIUM
- 1000 metrics @ 1s: ~512MB RAM, ~500m CPU → Use LARGE
- 10 metrics @ 60s: ~64MB RAM, ~50m CPU → Use SMALL
```

### Metric Cardinality Examples

```
Low Cardinality (Good):
- cpu,host=server1 usage=50
  Tags: 1 (host)
  Series: ~10 (one per host)

Medium Cardinality (OK):
- http,host=server1,endpoint=/api,method=GET latency=100
  Tags: 3
  Series: ~1000 (hosts × endpoints × methods)

High Cardinality (Dangerous):
- request,host=server1,user_id=12345,session=abc123 count=1
  Tags: 3 (but user_id has millions of values!)
  Series: MILLIONS (explosion!)
  
Solution: Drop user_id or aggregate
```

### Port Reference

| Port | Purpose | Protocol |
|------|---------|----------|
| 8080 | Prometheus metrics | HTTP |
| 8086 | InfluxDB (default) | HTTP |
| 8125 | StatsD (optional) | UDP |
| 10250 | Kubelet API | HTTPS |

### Environment Variables Reference

| Variable | Purpose | Example |
|----------|---------|---------|
| `HOSTNAME` | Pod hostname | Auto-populated |
| `INFLUX_TOKEN` | InfluxDB auth | From secret |
| `INFLUX_PASSWORD` | InfluxDB v1 password | From secret |
| `DB_PASSWORD` | Database password | From secret |

### Glossary

**Agent**: Telegraf process collecting metrics  
**Buffer**: In-memory storage for metrics before output  
**Cardinality**: Number of unique time series  
**DaemonSet**: Kubernetes workload running one pod per node  
**Deployment**: Kubernetes workload running N replicas  
**Flush**: Writing buffered metrics to output  
**Input Plugin**: Collects metrics from a source  
**Output Plugin**: Sends metrics to a destination  
**Preset**: Pre-configured resource allocation  
**Processor Plugin**: Transforms metrics  
**RBAC**: Role-Based Access Control  
**ServiceMonitor**: Prometheus Operator CRD for scrape config  
**Time Series**: Sequence of data points over time  

---

## Changelog

### Version 1.0.0 (2026-01-11)

**Initial Release**

Features:
- Deployment and DaemonSet modes
- Resource presets (small/medium/large/custom)
- Pre-configured input plugins (system, Docker, Kubernetes)
- Pre-configured output plugins (InfluxDB, Prometheus, file)
- Comprehensive RBAC and security hardening
- Health checks and monitoring
- Persistent storage for buffering
- Management and testing scripts
- 100+ pages of documentation
- Patrick Ryan's dark humor throughout

---

**Fireball Industries** - We Play With Fire So You Don't Have To™

*Professional Chaos Engineering Since 2024*

*Now with 87% more snark than competing solutions*

**Warranty:** Void  
**Support:** When we feel like it  
**Quality:** Surprisingly good despite the humor  

---

**End of Documentation**

If you've read this far, you either:
1. Actually needed this information
2. Were incredibly bored
3. Are our QA person checking if we wrote docs
4. Are preparing for an audit

In any case, may your metrics be plentiful, your cardinality reasonable, and your pager quiet.

Happy monitoring! 🔥📊
