# Grafana + Loki Pod

**All-in-one observability - Because your logs deserve a good home** 📊

Single-pod deployment combining Grafana dashboards with Loki log aggregation. Perfect for isolated observability instances without the complexity of distributed deployments.

## What You Get

🔍 **Single Pod with:**
- **Grafana 10.2.3** - Modern dashboarding and visualization
- **Loki 2.9.3** - Lightweight log aggregation (like Prometheus, but for logs)
- **Pre-configured integration** - Loki datasource ready out-of-the-box
- **Persistent storage** - Your dashboards and logs survive restarts
- **Resource presets** - Small/Medium/Large configs

## Quick Deploy

Deploy via Rancher UI - browse to **Apps & Marketplace**, find "Grafana + Loki Pod", click install, configure via wizard, profit.

Or via command line:

```bash
helm install my-observability fireball-podstore/grafana-loki \
  --namespace grafana-loki \
  --create-namespace
```

Boom. Observability deployed. ✅

## Features

- **All-in-One**: Grafana + Loki in a single pod (simplified architecture)
- **Production-Ready**: Security contexts, health checks, resource limits
- **Pre-Configured**: Loki datasource automatically added to Grafana
- **Resource Presets**: Small (dev), Medium (prod), Large (high-volume)
- **Rancher-Optimized**: Full wizard UI for easy configuration
- **Persistent Storage**: Keep dashboards and logs across restarts
- **Namespace Isolation**: Deploy multiple instances independently

## Access Grafana

1. Get the service IP: `kubectl get svc -n grafana-loki`
2. Access at `http://<SERVICE_IP>:3000`
3. Login with default credentials (check NOTES.txt for password)
4. Navigate to **Explore** → Loki datasource is pre-configured
5. Start querying your logs with LogQL

## Ports

- **3000**: Grafana web UI (HTTP)
- **3100**: Loki HTTP API (ingestion & queries)
- **9095**: Loki gRPC (internal)

## Resource Presets

**Small** (dev/testing):
- Grafana: 250m CPU, 512Mi RAM, 5Gi storage
- Loki: 250m CPU, 512Mi RAM, 10Gi storage

**Medium** (production):
- Grafana: 500m-1000m CPU, 1-2Gi RAM, 10Gi storage
- Loki: 1000m-2000m CPU, 2-4Gi RAM, 50Gi storage

**Large** (high-volume):
- Grafana: 1000m-2000m CPU, 2-4Gi RAM, 20Gi storage
- Loki: 2000m-4000m CPU, 4-8Gi RAM, 100Gi storage

## Send Logs to Loki

Configure your log shippers (Promtail, Fluent Bit, etc.) to send to:

```
http://grafana-loki-loki.<namespace>.svc.cluster.local:3100
```

Example Promtail config:

```yaml
clients:
  - url: http://grafana-loki-loki.grafana-loki.svc.cluster.local:3100/loki/api/v1/push
```

## Troubleshooting

**Grafana won't start?**
- Check PVC is bound: `kubectl get pvc -n grafana-loki`
- Check pod logs: `kubectl logs -n grafana-loki <pod> -c grafana`

**Loki not receiving logs?**
- Verify service: `kubectl get svc -n grafana-loki`
- Check Loki logs: `kubectl logs -n grafana-loki <pod> -c loki`
- Test endpoint: `curl http://<loki-ip>:3100/ready`

**Can't log into Grafana?**
- Get password: `kubectl get secret -n grafana-loki <release>-grafana-credentials -o jsonpath='{.data.admin-password}' | base64 --decode`

## Why This Exists

Most Loki deployments are distributed and complex. Sometimes you just want logs and dashboards in one place without running a microservices architecture. This pod does exactly that.

**Use cases:**
- Development environments
- Small production workloads
- Isolated tenant observability
- Edge deployments
- "I just want logs, dammit"

## License

Fireball Industries Podstore - Patrick Ryan

---

**Built with 🔥 by Fireball Industries**
*Making observability less painful since 2026*
