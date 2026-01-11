<#
.SYNOPSIS
    Generate TimescaleDB values.yaml configurations for common scenarios
    
.DESCRIPTION
    Generate pre-configured values.yaml files for common industrial IoT/SCADA scenarios.
    Because nobody wants to manually configure 100+ YAML options at 2 AM.
    
    Scenarios:
    - dev-minimal: Development/testing minimal setup
    - sensor-monitoring: High-frequency sensor data collection
    - production-historian: Full production SCADA historian
    - edge-gateway: Resource-constrained edge deployment
    - analytics-warehouse: Long-term analytics and reporting
    - compliance-historian: FDA 21 CFR Part 11 compliant setup
    
.PARAMETER Scenario
    The scenario to generate
    
.PARAMETER OutputFile
    Output file path (default: values-<scenario>.yaml)
    
.PARAMETER Namespace
    Kubernetes namespace (default: databases)
    
.PARAMETER StorageClass
    Storage class name (leave empty for cluster default)
    
.PARAMETER Domain
    Domain name for ingress (optional)
    
.EXAMPLE
    .\generate-timescaledb-config.ps1 -Scenario sensor-monitoring -OutputFile my-values.yaml
    
.EXAMPLE
    .\generate-timescaledb-config.ps1 -Scenario compliance-historian -Domain tsdb.example.com
    
.NOTES
    Author: Patrick Ryan / Fireball Industries
    Version: 1.0.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('dev-minimal', 'sensor-monitoring', 'production-historian', 
                 'edge-gateway', 'analytics-warehouse', 'compliance-historian')]
    [string]$Scenario,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputFile = "",
    
    [Parameter(Mandatory = $false)]
    [string]$Namespace = "databases",
    
    [Parameter(Mandatory = $false)]
    [string]$StorageClass = "",
    
    [Parameter(Mandatory = $false)]
    [string]$Domain = ""
)

# Color output functions
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Write-Success { param([string]$Message) Write-ColorOutput "✅ $Message" "Green" }
function Write-Info { param([string]$Message) Write-ColorOutput "ℹ️  $Message" "Cyan" }
function Write-Header { param([string]$Message) Write-ColorOutput "`n🔥 $Message" "Magenta" }

# Set default output file if not specified
if (-not $OutputFile) {
    $OutputFile = "values-$Scenario.yaml"
}

Write-Header "Generating TimescaleDB Configuration"
Write-Info "Scenario: $Scenario"
Write-Info "Output: $OutputFile"

# Generate configuration based on scenario
$config = switch ($Scenario) {
    'dev-minimal' {
        @"
# TimescaleDB - Development Minimal Configuration
# For local dev/test environments where you're just trying to get something running
# Don't use this in production unless you enjoy living dangerously

preset: small
mode: standalone

postgresql:
  database: tsdb
  username: tsadmin

timescaledb:
  enabled: true
  compression:
    enabled: false  # Compression off for faster dev iterations
  retention:
    enabled: false  # Keep all data in dev
  hypertables:
    sensorData:
      enabled: true
      compression:
        enabled: false
      retention:
        enabled: false
    machineMetrics:
      enabled: true
      compression:
        enabled: false
      retention:
        enabled: false

persistence:
  enabled: true
  size: 50Gi

walVolume:
  enabled: false  # No separate WAL volume for dev

backup:
  enabled: false  # No backups in dev (YOLO)

monitoring:
  serviceMonitor:
    enabled: false
  grafana:
    enabled: false

sidecars:
  postgresExporter:
    enabled: false
  pgbouncer:
    enabled: false

# Resource requests are low for dev
resources:
  requests:
    cpu: "1"
    memory: "2Gi"
  limits:
    cpu: "2"
    memory: "4Gi"
"@
    }
    
    'sensor-monitoring' {
        @"
# TimescaleDB - Sensor Monitoring Configuration
# Optimized for high-frequency sensor data (1-second intervals)
# Because your temperature sensors don't take breaks

preset: medium
mode: standalone

postgresql:
  database: tsdb
  username: tsadmin

timescaledb:
  enabled: true
  maxBackgroundWorkers: 16
  compression:
    enabled: true
    compressAfter: "1 day"  # Aggressive compression for high-volume data
    algorithm: "auto"
  retention:
    enabled: true
    rawData: "90 days"
  continuousAggregates:
    enabled: true
    autoRefresh: true
  hypertables:
    sensorData:
      enabled: true
      chunkTimeInterval: "1 hour"  # Small chunks for high-frequency data
      compression:
        enabled: true
        compressAfter: "1 day"
        segmentby: "device_id,sensor_type"
        orderby: "time DESC"
      retention:
        enabled: true
        dropAfter: "90 days"
    machineMetrics:
      enabled: true
    energyConsumption:
      enabled: true
    qualityMeasurements:
      enabled: false
    alarmHistory:
      enabled: true
    productionCounts:
      enabled: false

persistence:
  enabled: true
  size: 500Gi

walVolume:
  enabled: true
  size: 50Gi

backup:
  enabled: true
  schedule: "0 2 * * *"
  retention: 7
  destination:
    type: pvc
    pvc:
      size: 100Gi

monitoring:
  serviceMonitor:
    enabled: true
  grafana:
    enabled: true

sidecars:
  postgresExporter:
    enabled: true
  pgbouncer:
    enabled: true
    maxClientConn: 500

# Optimized for high insert rates
postgresql:
  autovacuum:
    enabled: true
    naptime: "30s"
  wal:
    maxWalSize: "8GB"
"@
    }
    
    'production-historian' {
        @"
# TimescaleDB - Production SCADA Historian Configuration
# Full-featured production setup with HA, compression, and monitoring
# This is the "I know what I'm doing" configuration

preset: large
mode: ha
replicaCount: 3
synchronousCommit: "local"

postgresql:
  database: tsdb
  username: tsadmin

timescaledb:
  enabled: true
  maxBackgroundWorkers: 24
  compression:
    enabled: true
    compressAfter: "7 days"
  retention:
    enabled: true
    rawData: "90 days"
    hourlyAggregates: "1 year"
    dailyAggregates: "5 years"
  continuousAggregates:
    enabled: true
    autoRefresh: true
    refreshInterval: "1 hour"
  hypertables:
    sensorData:
      enabled: true
    machineMetrics:
      enabled: true
    energyConsumption:
      enabled: true
    qualityMeasurements:
      enabled: true
    alarmHistory:
      enabled: true
    productionCounts:
      enabled: true

persistence:
  enabled: true
  size: 1Ti

walVolume:
  enabled: true
  size: 100Gi

backup:
  enabled: true
  schedule: "0 2 * * *"
  retention: 30
  destination:
    type: pvc
    pvc:
      size: 500Gi

monitoring:
  serviceMonitor:
    enabled: true
    interval: 30s
  grafana:
    enabled: true

sidecars:
  postgresExporter:
    enabled: true
  pgbouncer:
    enabled: true
    poolMode: "transaction"
    maxClientConn: 1000
    defaultPoolSize: 50

networkPolicy:
  enabled: true

podDisruptionBudget:
  enabled: true
  minAvailable: 2

tls:
  enabled: true
  mode: "prefer"
"@
    }
    
    'edge-gateway' {
        @"
# TimescaleDB - Edge Gateway Configuration
# Optimized for Raspberry Pi / resource-constrained edge devices
# Because not everyone has a datacenter in their basement

preset: edge
mode: standalone

postgresql:
  database: tsdb
  username: tsadmin
  maxConnections: 50

timescaledb:
  enabled: true
  maxBackgroundWorkers: 4
  compression:
    enabled: true
    compressAfter: "1 hour"  # Aggressive compression on edge
  retention:
    enabled: true
    rawData: "7 days"  # Short retention on edge
    hourlyAggregates: "30 days"
  continuousAggregates:
    enabled: true
  hypertables:
    sensorData:
      enabled: true
      chunkTimeInterval: "1 day"  # Larger chunks for limited resources
      compression:
        enabled: true
        compressAfter: "1 hour"
      retention:
        enabled: true
        dropAfter: "7 days"
    machineMetrics:
      enabled: true
      chunkTimeInterval: "1 day"
      compression:
        enabled: true
        compressAfter: "1 hour"
      retention:
        enabled: true
        dropAfter: "7 days"
    energyConsumption:
      enabled: false
    qualityMeasurements:
      enabled: false
    alarmHistory:
      enabled: true
      retention:
        enabled: true
        dropAfter: "30 days"
    productionCounts:
      enabled: false

persistence:
  enabled: true
  size: 20Gi

walVolume:
  enabled: false  # Limited storage on edge

backup:
  enabled: true
  schedule: "0 3 * * 0"  # Weekly backups only
  retention: 2
  destination:
    type: pvc
    pvc:
      size: 10Gi

monitoring:
  serviceMonitor:
    enabled: false
  grafana:
    enabled: false

sidecars:
  postgresExporter:
    enabled: false
  pgbouncer:
    enabled: false

# Resource limits appropriate for Raspberry Pi 4
resources:
  requests:
    cpu: "500m"
    memory: "1Gi"
  limits:
    cpu: "1"
    memory: "1Gi"
"@
    }
    
    'analytics-warehouse' {
        @"
# TimescaleDB - Analytics Warehouse Configuration
# Optimized for complex analytical queries and long-term retention
# Because somebody needs to explain to management what happened last quarter

preset: xlarge
mode: standalone

postgresql:
  database: tsdb
  username: tsadmin
  maxConnections: 300
  performance:
    maxParallelWorkers: 32
    maxParallelWorkersPerGather: 16
    jitEnabled: true

timescaledb:
  enabled: true
  maxBackgroundWorkers: 32
  compression:
    enabled: true
    compressAfter: "30 days"  # Longer before compression for recent queries
  retention:
    enabled: true
    rawData: "2 years"
    hourlyAggregates: "10 years"
    dailyAggregates: "25 years"
    monthlyAggregates: "permanent"
  continuousAggregates:
    enabled: true
    autoRefresh: true
    compressMaterialized: true
  hypertables:
    sensorData:
      enabled: true
      retention:
        dropAfter: "2 years"
    machineMetrics:
      enabled: true
      retention:
        dropAfter: "5 years"
    energyConsumption:
      enabled: true
      retention:
        dropAfter: "10 years"
    qualityMeasurements:
      enabled: true
      retention:
        dropAfter: "10 years"
    alarmHistory:
      enabled: true
      retention:
        dropAfter: "5 years"
    productionCounts:
      enabled: true
      retention:
        dropAfter: "10 years"

persistence:
  enabled: true
  size: 5Ti  # Large storage for long-term data

walVolume:
  enabled: true
  size: 200Gi

backup:
  enabled: true
  schedule: "0 1 * * *"  # Daily backups
  retention: 90
  destination:
    type: pvc
    pvc:
      size: 1Ti

monitoring:
  serviceMonitor:
    enabled: true
  grafana:
    enabled: true

sidecars:
  postgresExporter:
    enabled: true
  pgbouncer:
    enabled: true
    poolMode: "session"  # Session mode for complex queries
    maxClientConn: 500

# SSD storage recommended
# storageClass: fast-ssd
"@
    }
    
    'compliance-historian' {
        @"
# TimescaleDB - Compliance Historian Configuration
# FDA 21 CFR Part 11 / ISO 9001 compliant setup
# Because regulators don't accept "oops" as an explanation

preset: large
mode: ha
replicaCount: 3
synchronousCommit: "remote_write"  # Highest durability

postgresql:
  database: tsdb
  username: tsadmin
  logging:
    logStatement: "all"
    logConnections: true
    logDisconnections: true
    logDuration: true

timescaledb:
  enabled: true
  compression:
    enabled: true
    compressAfter: "30 days"
    allowRecompression: false  # No modifications to compressed data
  retention:
    enabled: true
    rawData: "25 years"  # Long-term regulatory retention
    hourlyAggregates: "permanent"
    dailyAggregates: "permanent"
  hypertables:
    sensorData:
      enabled: true
      retention:
        enabled: true
        dropAfter: "25 years"
    machineMetrics:
      enabled: true
      retention:
        dropAfter: "25 years"
    energyConsumption:
      enabled: true
      retention:
        dropAfter: "25 years"
    qualityMeasurements:
      enabled: true
      retention:
        dropAfter: "25 years"
    alarmHistory:
      enabled: true
      retention:
        dropAfter: "25 years"
    productionCounts:
      enabled: true
      retention:
        dropAfter: "25 years"

compliance:
  fda21CFRPart11:
    enabled: true
    auditLogging: true
    immutableAuditTables: true
    electronicSignatures: true
  iso9001:
    enabled: true
    auditLogging: true
  gdpr:
    enabled: true
    dataRetention: true

persistence:
  enabled: true
  size: 2Ti

walVolume:
  enabled: true
  size: 200Gi

backup:
  enabled: true
  schedule: "0 2 * * *"
  retention: 365  # 1 year of backups
  destination:
    type: pvc
    pvc:
      size: 2Ti
  compression: gzip

tls:
  enabled: true
  mode: "require"

networkPolicy:
  enabled: true

podDisruptionBudget:
  enabled: true
  minAvailable: 2

monitoring:
  serviceMonitor:
    enabled: true
  grafana:
    enabled: true

sidecars:
  postgresExporter:
    enabled: true
  pgbouncer:
    enabled: true
"@
    }
}

# Add common configuration
$commonConfig = @"

# Common configuration
global:
  storageClass: "$StorageClass"
"@

if ($Domain) {
    $commonConfig += @"

ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: $Domain
      paths:
        - path: /
          pathType: Prefix
"@
}

# Write configuration to file
$fullConfig = $config + $commonConfig
$fullConfig | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Success "Configuration generated: $OutputFile"
Write-Info "`nDeploy with:"
Write-Info "  helm upgrade --install timescaledb . --namespace $Namespace --create-namespace --values $OutputFile"

# Display scenario-specific tips
Write-Header "Scenario Tips"

switch ($Scenario) {
    'dev-minimal' {
        Write-Info "• Perfect for local development and testing"
        Write-Info "• No backups or monitoring - use for non-critical data only"
        Write-Info "• Consider enabling compression if testing high-volume scenarios"
    }
    'sensor-monitoring' {
        Write-Info "• Optimized for 1-second interval sensor data"
        Write-Info "• Aggressive compression after 1 day saves significant storage"
        Write-Info "• Monitor compression ratio with: .\scripts\manage-timescaledb.ps1 -Action compression-status"
        Write-Info "• Consider increasing retention period based on business needs"
    }
    'production-historian' {
        Write-Info "• HA mode with 3 replicas provides redundancy"
        Write-Info "• All industrial schemas enabled by default"
        Write-Info "• TLS recommended for production - configure certificates"
        Write-Info "• Review backup retention (30 days) based on compliance needs"
    }
    'edge-gateway' {
        Write-Info "• Designed for Raspberry Pi 4 (4GB+ RAM recommended)"
        Write-Info "• Aggressive compression and short retention to save space"
        Write-Info "• Consider forwarding data to central historian for long-term storage"
        Write-Info "• Weekly backups only - adjust if needed"
    }
    'analytics-warehouse' {
        Write-Info "• Large storage allocation for long-term data (5Ti default)"
        Write-Info "• Parallel query execution enabled for complex analytics"
        Write-Info "• Consider using faster storage class for better query performance"
        Write-Info "• Session pooling mode for complex, long-running queries"
    }
    'compliance-historian' {
        Write-Info "• ⚠️  IMPORTANT: This enables compliance features but doesn't guarantee compliance"
        Write-Info "• Review SECURITY.md for complete compliance checklists"
        Write-Info "• Audit logging enabled - review audit tables regularly"
        Write-Info "• 25-year retention configured - adjust based on regulatory requirements"
        Write-Info "• Immutable audit tables prevent tampering"
        Write-Info "• TLS enabled and required - configure valid certificates"
    }
}

Write-Info "`nNext steps:"
Write-Info "1. Review and customize $OutputFile as needed"
Write-Info "2. Deploy: helm upgrade --install timescaledb . --namespace $Namespace --values $OutputFile"
Write-Info "3. Verify: .\scripts\manage-timescaledb.ps1 -Action health-check -Namespace $Namespace"

Write-Success "`nConfiguration generation complete!"
