# Ignition Edge Quick Reference

## Common kubectl Commands

```powershell
# Get gateway pod status
kubectl get pods -n industrial -l app.kubernetes.io/name=ignition-edge

# View gateway logs
kubectl logs -f deployment/ignition-edge -n industrial

# Get admin password
kubectl get secret ignition-edge-secret -n industrial \
  -o jsonpath='{.data.admin-password}' | base64 -d

# Port forward to gateway
kubectl port-forward -n industrial svc/ignition-edge 8088:8088

# Port forward to OPC UA
kubectl port-forward -n industrial svc/ignition-edge 62541:62541

# Exec into pod
kubectl exec -it deployment/ignition-edge -n industrial -- /bin/bash

# Restart gateway
kubectl rollout restart deployment/ignition-edge -n industrial

# View resource usage
kubectl top pod -n industrial -l app.kubernetes.io/name=ignition-edge
```

## Helm Commands

```powershell
# Install
helm install ignition-edge . -n industrial --create-namespace

# Upgrade
helm upgrade ignition-edge . -n industrial

# Uninstall
helm uninstall ignition-edge -n industrial

# Get values
helm get values ignition-edge -n industrial

# Show status
helm status ignition-edge -n industrial

# History
helm history ignition-edge -n industrial

# Rollback
helm rollback ignition-edge 1 -n industrial
```

## Gateway URLs

```
Web UI:        http://localhost:8088
Designer:      http://localhost:8088/main
Config:        http://localhost:8088/web/config
Status:        http://localhost:8088/StatusPing
OPC UA:        opc.tcp://localhost:62541
MQTT:          mqtt://localhost:1883
Metrics:       http://localhost:5556/metrics
```

## PowerShell Scripts

```powershell
# Deploy
.\scripts\manage-ignition.ps1 -Action deploy

# Health check
.\scripts\manage-ignition.ps1 -Action health-check

# Backup
.\scripts\manage-ignition.ps1 -Action backup

# Restore
.\scripts\manage-ignition.ps1 -Action restore -BackupFile "gateway.gwbk"

# Activate license
.\scripts\manage-ignition.ps1 -Action activate-license -ActivationKey "KEY"

# View logs
.\scripts\manage-ignition.ps1 -Action logs

# Open designer
.\scripts\manage-ignition.ps1 -Action designer-launch

# Run tests
.\scripts\test-ignition.ps1
```

## Common SQL Queries (Tag Historian)

```sql
-- View recent tag history
SELECT tagpath, t_stamp, floatvalue 
FROM sqlt_data_1_TIMESTAMP
ORDER BY t_stamp DESC 
LIMIT 100;

-- Tag data for last hour
SELECT tagpath, t_stamp, floatvalue
FROM sqlt_data_1_TIMESTAMP
WHERE t_stamp > NOW() - INTERVAL '1 hour'
ORDER BY t_stamp DESC;

-- Average value by hour
SELECT 
  date_trunc('hour', t_stamp) as hour,
  tagpath,
  AVG(floatvalue) as avg_value
FROM sqlt_data_1_TIMESTAMP
WHERE t_stamp > NOW() - INTERVAL '24 hours'
GROUP BY hour, tagpath
ORDER BY hour DESC;

-- Storage size by tag
SELECT 
  tagpath,
  COUNT(*) as sample_count,
  pg_size_pretty(pg_total_relation_size('sqlt_data_1_' || id)) as size
FROM sqlt_meta
GROUP BY tagpath, id;
```

## Troubleshooting Commands

```powershell
# Check pod events
kubectl describe pod <pod-name> -n industrial

# Check all resources
kubectl get all -n industrial -l app.kubernetes.io/instance=ignition-edge

# Check PVC status
kubectl get pvc -n industrial

# Check secrets
kubectl get secrets -n industrial

# Check ConfigMaps
kubectl get configmaps -n industrial

# Check NetworkPolicies
kubectl get networkpolicies -n industrial

# Check service endpoints
kubectl get endpoints -n industrial

# View all logs
kubectl logs deployment/ignition-edge -n industrial --all-containers=true
```

## Environment Variables in Pod

```powershell
# View all env vars
kubectl exec deployment/ignition-edge -n industrial -- env

# Check Java version
kubectl exec deployment/ignition-edge -n industrial -- java -version

# Check Ignition version
kubectl exec deployment/ignition-edge -n industrial -- \
  cat /usr/local/bin/ignition/lib/install-info.txt
```

## File Locations in Pod

```
Gateway data:         /usr/local/bin/ignition/data
Configuration:        /usr/local/bin/ignition/data/ignition.conf
Projects:             /usr/local/bin/ignition/data/projects
Logs:                 /var/log/ignition
Backups:              /backups
Modules:              /modules
Scripts:              /scripts
```

## Performance Tuning

```yaml
# Increase heap size
gateway:
  heap:
    initial: "4g"
    max: "8g"

# Increase thread pools
gateway:
  threads:
    http: 300
    database: 100
    tags: 16

# Increase connections
gateway:
  connections:
    maxDesigners: 10
    maxVisionClients: 50
    maxPerspectiveSessions: 200
```

## Network Troubleshooting

```powershell
# Test HTTP connectivity
curl http://localhost:8088/StatusPing

# Test OPC UA port
Test-NetConnection -ComputerName localhost -Port 62541

# Test MQTT port
Test-NetConnection -ComputerName localhost -Port 1883

# DNS lookup
kubectl exec deployment/ignition-edge -n industrial -- nslookup postgresql

# Ping database
kubectl exec deployment/ignition-edge -n industrial -- \
  ping -c 3 postgresql.database.svc.cluster.local
```

## Gateway Backup/Restore (Manual)

```powershell
# Manual backup via gwcmd
kubectl exec deployment/ignition-edge -n industrial -- \
  /usr/local/bin/ignition/gwcmd.sh \
  --backup \
  --file /backups/manual-backup.gwbk

# Copy backup from pod
kubectl cp industrial/ignition-edge-xxx:/backups/manual-backup.gwbk \
  ./local-backup.gwbk

# Copy backup to pod
kubectl cp ./local-backup.gwbk \
  industrial/ignition-edge-xxx:/restore/gateway.gwbk

# Restore via gwcmd
kubectl exec deployment/ignition-edge -n industrial -- \
  /usr/local/bin/ignition/gwcmd.sh \
  --restore \
  --file /restore/gateway.gwbk
```

## Prometheus Queries

```promql
# JVM heap usage
jvm_memory_heap_used_bytes / jvm_memory_heap_max_bytes * 100

# GC time percentage
rate(jvm_gc_collection_time_ms[5m]) / 1000

# Designer connections
ignition_designer_connections

# Vision clients
ignition_vision_clients

# Tag count
ignition_tag_count

# Database connection pool
ignition_db_active_connections
```
