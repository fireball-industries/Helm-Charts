<#
.SYNOPSIS
    Generate InfluxDB Pod configuration files
    
.DESCRIPTION
    Generate customized values.yaml and Telegraf configurations for various scenarios.
    Scenarios: factory, scada, energy, edge, custom
    
    Includes Telegraf configs for OPC UA, Modbus, MQTT, and more.
    
.PARAMETER Scenario
    Deployment scenario (factory, scada, energy, edge, custom)
    
.PARAMETER OutputPath
    Output directory for generated files
    
.PARAMETER Organization
    InfluxDB organization name
    
.PARAMETER DeploymentMode
    Deployment mode: single or ha
    
.PARAMETER ResourcePreset
    Resource preset: edge, small, medium, large, xlarge
    
.PARAMETER SensorCount
    Estimated number of sensors (for sizing)
    
.PARAMETER IncludeTelegraf
    Include Telegraf configuration
    
.PARAMETER TelegrafProtocols
    Comma-separated list of protocols: opcua, modbus, mqtt, snmp, sql
    
.EXAMPLE
    .\generate-config.ps1 -Scenario factory -Organization "acme-factory" -SensorCount 100
    
.EXAMPLE
    .\generate-config.ps1 -Scenario scada -IncludeTelegraf -TelegrafProtocols "opcua,modbus"
    
.EXAMPLE
    .\generate-config.ps1 -Scenario edge -DeploymentMode single -ResourcePreset edge
    
.NOTES
    Author: Patrick Ryan, Fireball Industries
    Version: 1.0.0
    "Configuration generation: Because YAML is tedious"
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('factory', 'scada', 'energy', 'edge', 'custom')]
    [string]$Scenario,
    
    [string]$OutputPath = "./generated-config",
    [string]$Organization = "my-factory",
    [string]$DeploymentMode = "single",
    [string]$ResourcePreset = "medium",
    [int]$SensorCount = 50,
    [switch]$IncludeTelegraf,
    [string]$TelegrafProtocols = "mqtt"
)

# Banner
Write-Host @"
================================================================================
⚙️  InfluxDB Pod Configuration Generator
================================================================================
Fireball Industries - "YAML files shouldn't require a PhD"™
================================================================================
"@ -ForegroundColor Cyan

# Create output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    Write-Host "Created output directory: $OutputPath" -ForegroundColor Green
}

# Determine resource preset based on sensor count if not specified
function Get-ResourcePresetFromSensorCount {
    param([int]$count)
    
    if ($count -lt 5) { return "edge" }
    elseif ($count -lt 10) { return "small" }
    elseif ($count -lt 100) { return "medium" }
    elseif ($count -lt 1000) { return "large" }
    else { return "xlarge" }
}

if ($ResourcePreset -eq "medium" -and $SensorCount -gt 0) {
    $ResourcePreset = Get-ResourcePresetFromSensorCount -count $SensorCount
    Write-Host "Auto-selected resource preset '$ResourcePreset' for $SensorCount sensors" -ForegroundColor Yellow
}

# Generate base values.yaml
function New-BaseValues {
    param(
        [string]$mode,
        [string]$preset,
        [string]$org
    )
    
    return @"
# Generated InfluxDB Pod Configuration
# Scenario: $Scenario
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# Fireball Industries - "Ignite Your Factory Efficiency"™

deploymentMode: $mode
resourcePreset: $preset

influxdb:
  organization: "$org"
  bucket: "sensors"
  retention: "90d"
  logLevel: info

persistence:
  enabled: true
  retainOnDelete: true

industrialBuckets:
  enabled: true

dataRetention:
  enabled: true

monitoring:
  prometheus:
    enabled: true

security:
  runAsNonRoot: true
  podSecurityStandard: restricted
"@
}

# Generate factory scenario
function New-FactoryConfig {
    $config = New-BaseValues -mode $DeploymentMode -preset $ResourcePreset -org $Organization
    
    $config += @"

# Factory-specific configuration
industrialBuckets:
  enabled: true
  buckets:
    - name: "sensors"
      retention: "90d"
      description: "Raw sensor data"
    - name: "production"
      retention: "365d"
      description: "Production metrics (OEE, cycle times)"
    - name: "quality"
      retention: "1095d"  # 3 years
      description: "Quality control measurements"
    - name: "maintenance"
      retention: "730d"
      description: "Maintenance and vibration data"

backup:
  enabled: true
  schedule: "0 2 * * *"
  retention: 14

ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: influxdb.${Organization}.local
      paths:
        - path: /
          pathType: Prefix
"@
    
    return $config
}

# Generate SCADA scenario
function New-SCADAConfig {
    $config = New-BaseValues -mode $DeploymentMode -preset $ResourcePreset -org $Organization
    
    $config += @"

# SCADA-specific configuration
industrialBuckets:
  enabled: true
  buckets:
    - name: "scada"
      retention: "730d"  # 2 years
      description: "SCADA system metrics and alarms"
    - name: "alarms"
      retention: "2555d"  # 7 years
      description: "SCADA alarm history"
    - name: "events"
      retention: "2555d"
      description: "Operator events"
    - name: "plc_data"
      retention: "365d"
      description: "PLC register values"

dataRetention:
  enabled: true
  hot:
    duration: "14d"
  warm:
    duration: "365d"
    interval: "1m"
  cold:
    duration: "2555d"
    interval: "1h"

backup:
  enabled: true
  schedule: "0 3 * * *"
  retention: 90

networkPolicy:
  enabled: true
  ingress:
    - namespaceSelector:
        matchLabels:
          name: scada
    - namespaceSelector:
        matchLabels:
          name: hmi
"@
    
    return $config
}

# Generate energy scenario
function New-EnergyConfig {
    $config = New-BaseValues -mode $DeploymentMode -preset "small" -org $Organization
    
    $config += @"

# Energy monitoring configuration
influxdb:
  bucket: "energy"
  retention: "2555d"  # 7 years for compliance

industrialBuckets:
  enabled: true
  buckets:
    - name: "energy"
      retention: "2555d"
      description: "Main energy meters"
    - name: "power_quality"
      retention: "365d"
      description: "Voltage, current, harmonics"
    - name: "demand"
      retention: "2555d"
      description: "Peak demand tracking"
    - name: "renewable"
      retention: "2555d"
      description: "Solar/wind generation"

dataRetention:
  enabled: true
  hot:
    duration: "30d"
  warm:
    duration: "365d"
    interval: "15m"
  cold:
    duration: "2555d"
    interval: "1h"
"@
    
    return $config
}

# Generate edge scenario
function New-EdgeConfig {
    $config = New-BaseValues -mode "single" -preset "edge" -org "${Organization}-edge"
    
    $config += @"

# Edge gateway configuration
influxdb:
  retention: "7d"  # Short local retention

edge:
  enabled: true
  remoteWrite:
    enabled: true
    url: "https://influxdb-central.${Organization}.com"
    organization: "$Organization"
    bucket: "edge-data"
    batchSize: 5000
    flushInterval: "30s"
    maxRetries: 10
    retryInterval: "30s"
  localBuffer:
    enabled: true
    maxSize: "10Gi"

industrialBuckets:
  enabled: true
  buckets:
    - name: "sensors"
      retention: "7d"
      description: "Edge sensor data"

dataRetention:
  enabled: false

backup:
  enabled: false

ingress:
  enabled: false
"@
    
    return $config
}

# Generate Telegraf configuration
function New-TelegrafConfig {
    param([string[]]$protocols)
    
    $config = @"
# Telegraf Configuration
# Generated for: $Scenario scenario
# Protocols: $($protocols -join ', ')

[agent]
  interval = "10s"
  round_interval = true
  metric_batch_size = 1000
  metric_buffer_limit = 10000
  flush_interval = "10s"

[[outputs.influxdb_v2]]
  urls = ["http://localhost:8086"]
  token = "`$INFLUX_TOKEN"
  organization = "`$INFLUX_ORG"
  bucket = "sensors"

"@
    
    # OPC UA
    if ($protocols -contains "opcua") {
        $config += @"
# OPC UA input for SCADA servers
[[inputs.opcua]]
  name = "scada-server"
  endpoint = "opc.tcp://scada-server:4840"
  security_policy = "None"
  security_mode = "None"
  
  [[inputs.opcua.nodes]]
    name = "Temperature"
    namespace = "2"
    identifier_type = "s"
    identifier = "PLC.Temperature"
  
  [[inputs.opcua.nodes]]
    name = "Pressure"
    namespace = "2"
    identifier_type = "s"
    identifier = "PLC.Pressure"

"@
    }
    
    # Modbus
    if ($protocols -contains "modbus") {
        $config += @"
# Modbus TCP for PLCs
[[inputs.modbus]]
  name = "plc-01"
  slave_id = 1
  timeout = "1s"
  controller = "tcp://192.168.1.10:502"
  
  holding_registers = [
    {name = "temperature", byte_order = "AB", data_type = "FLOAT32", scale=1.0, address = [0,1]},
    {name = "pressure", byte_order = "AB", data_type = "FLOAT32", scale=1.0, address = [2,3]},
    {name = "flow_rate", byte_order = "AB", data_type = "FLOAT32", scale=1.0, address = [4,5]},
  ]

"@
    }
    
    # MQTT
    if ($protocols -contains "mqtt") {
        $config += @"
# MQTT input for sensor data
[[inputs.mqtt_consumer]]
  servers = ["tcp://mqtt-broker:1883"]
  topics = [
    "factory/+/temperature",
    "factory/+/pressure",
    "factory/+/status"
  ]
  data_format = "json"
  json_time_key = "timestamp"
  json_time_format = "unix"

"@
    }
    
    # SNMP
    if ($protocols -contains "snmp") {
        $config += @"
# SNMP for network equipment and UPS
[[inputs.snmp]]
  agents = ["192.168.1.20:161"]
  version = 2
  community = "public"
  
  [[inputs.snmp.field]]
    name = "hostname"
    oid = "RFC1213-MIB::sysName.0"
    is_tag = true

"@
    }
    
    # SQL
    if ($protocols -contains "sql") {
        $config += @"
# SQL Server for legacy SCADA historian
[[inputs.sql]]
  driver = "mssql"
  dsn = "server=scada-db;user id=telegraf;password=`${SCADA_DB_PASSWORD};database=RuntimeData"
  
  [[inputs.sql.query]]
    query = "SELECT TagName, Value, Timestamp FROM AnalogData WHERE Timestamp > DATEADD(minute, -1, GETDATE())"
    measurement = "scada_historian"
    time_column = "Timestamp"
    tag_columns = ["TagName"]
    field_columns = ["Value"]

"@
    }
    
    # Always include system metrics
    $config += @"
# System metrics
[[inputs.cpu]]
  percpu = true
  totalcpu = true

[[inputs.disk]]
  ignore_fs = ["tmpfs", "devtmpfs", "devfs"]

[[inputs.mem]]

[[inputs.net]]
"@
    
    return $config
}

# Main generation
Write-Host "`n🎯 Generating configuration for scenario: $Scenario" -ForegroundColor Yellow
Write-Host "Organization: $Organization" -ForegroundColor Gray
Write-Host "Deployment Mode: $DeploymentMode" -ForegroundColor Gray
Write-Host "Resource Preset: $ResourcePreset" -ForegroundColor Gray
Write-Host "Sensor Count: $SensorCount" -ForegroundColor Gray

# Generate values.yaml
$valuesContent = switch ($Scenario) {
    'factory' { New-FactoryConfig }
    'scada' { New-SCADAConfig }
    'energy' { New-EnergyConfig }
    'edge' { New-EdgeConfig }
    'custom' { New-BaseValues -mode $DeploymentMode -preset $ResourcePreset -org $Organization }
}

$valuesPath = Join-Path $OutputPath "values-$Scenario.yaml"
$valuesContent | Out-File -FilePath $valuesPath -Encoding UTF8
Write-Host "✅ Generated: $valuesPath" -ForegroundColor Green

# Generate Telegraf config if requested
if ($IncludeTelegraf) {
    $protocols = $TelegrafProtocols -split ','
    $telegrafContent = New-TelegrafConfig -protocols $protocols
    
    $telegrafPath = Join-Path $OutputPath "telegraf-$Scenario.conf"
    $telegrafContent | Out-File -FilePath $telegrafPath -Encoding UTF8
    Write-Host "✅ Generated: $telegrafPath" -ForegroundColor Green
}

# Generate README
$readmePath = Join-Path $OutputPath "README.md"
$readmeContent = @"
# Generated InfluxDB Pod Configuration

**Scenario**: $Scenario
**Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Organization**: $Organization
**Deployment Mode**: $DeploymentMode
**Resource Preset**: $ResourcePreset
**Estimated Sensors**: $SensorCount

## Files

- ``values-$Scenario.yaml`` - Helm values configuration
$(if ($IncludeTelegraf) { "- ``telegraf-$Scenario.conf`` - Telegraf configuration`n" } else { "" })

## Installation

``````bash
# Deploy InfluxDB with this configuration
helm install influxdb ../../ \
  -f values-$Scenario.yaml \
  --namespace influxdb \
  --create-namespace
``````

## Next Steps

1. Review and customize the generated configuration
2. Update organization name, bucket names, retention periods
3. Configure storage class for your environment
4. Set up ingress hostname
5. Deploy using Helm

## Support

Generated by Fireball Industries InfluxDB Pod Configuration Generator
"Ignite Your Factory Efficiency"™

For support: https://github.com/fireball-industries/influxdb-pod
"@

$readmeContent | Out-File -FilePath $readmePath -Encoding UTF8
Write-Host "✅ Generated: $readmePath" -ForegroundColor Green

# Summary
Write-Host "`n📋 Configuration Summary" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "Scenario: $Scenario" -ForegroundColor White
Write-Host "Output Directory: $OutputPath" -ForegroundColor White
Write-Host "Files Generated: $((Get-ChildItem $OutputPath).Count)" -ForegroundColor White
Write-Host "`nTo deploy:" -ForegroundColor Yellow
Write-Host "  helm install influxdb . -f $OutputPath/values-$Scenario.yaml --namespace influxdb" -ForegroundColor Gray
Write-Host "`n🔥 Fireball Industries - 'YAML generation: Because life is too short'" -ForegroundColor Cyan
