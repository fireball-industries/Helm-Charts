#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Telegraf Configuration Generator
    Fireball Industries

.DESCRIPTION
    Generate custom Telegraf configurations for common scenarios.
    Because copy-pasting from Stack Overflow gets old.

.PARAMETER Scenario
    The monitoring scenario: k8s-full, docker-host, custom-app, database, network

.PARAMETER OutputPath
    Path to save the generated configuration

.EXAMPLE
    .\generate-config.ps1 -Scenario k8s-full -OutputPath ./my-values.yaml

#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('k8s-full', 'docker-host', 'custom-app', 'database', 'network', 'iot', 'minimal')]
    [string]$Scenario,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "./values-$Scenario.yaml",
    
    [Parameter(Mandatory=$false)]
    [string]$InfluxDBUrl = "",
    
    [Parameter(Mandatory=$false)]
    [string]$InfluxDBToken = "",
    
    [Parameter(Mandatory=$false)]
    [string]$InfluxDBOrg = "fireball",
    
    [Parameter(Mandatory=$false)]
    [string]$InfluxDBBucket = "telegraf"
)

function Get-K8sFullConfig {
    @"
## Kubernetes Full Monitoring Configuration
## Fireball Industries - Maximum Observability Edition
##
## This configuration collects EVERYTHING from your Kubernetes cluster.
## CPU usage? Check. Memory? Check. Your deepest infrastructure fears? Also check.

deploymentMode: daemonset  # Per-node collection for complete coverage
resourcePreset: large       # Because comprehensive monitoring needs resources

## Enable host-level metrics collection
hostNetwork: true
hostVolumes:
  enabled: true
  paths:
    - name: docker-socket
      hostPath: /var/run/docker.sock
      mountPath: /var/run/docker.sock
      readOnly: true
    - name: sys
      hostPath: /sys
      mountPath: /host/sys
      readOnly: true
    - name: proc
      hostPath: /proc
      mountPath: /host/proc
      readOnly: true

## Full RBAC for cluster-wide metrics
rbac:
  create: true
  clusterRole: true

## Enable persistence for metric buffering
persistence:
  enabled: true
  size: 5Gi

## Output Configuration
config:
  outputs:
    influxdb_v2:
      enabled: $(if ($InfluxDBUrl) { 'true' } else { 'false' })
      urls:
        - "$InfluxDBUrl"
      token: "$InfluxDBToken"
      organization: "$InfluxDBOrg"
      bucket: "$InfluxDBBucket"
    
    prometheus_client:
      enabled: true
      listen: ":8080"
      path: "/metrics"

  ## Input Plugins - All the things!
  inputs:
    internal:
      enabled: true
    cpu:
      enabled: true
      percpu: true
      totalcpu: true
    mem:
      enabled: true
    disk:
      enabled: true
    diskio:
      enabled: true
    kernel:
      enabled: true
    net:
      enabled: true
    processes:
      enabled: true
    swap:
      enabled: true
    system:
      enabled: true
    docker:
      enabled: true
    kubernetes:
      enabled: true
    kube_inventory:
      enabled: true
      resource_include:
        - deployments
        - pods
        - nodes
        - services
        - daemonsets
        - statefulsets
        - persistentvolumes
        - persistentvolumeclaims
        - ingresses
        - jobs
        - cronjobs

## Tolerations to run on all nodes (including masters)
tolerations:
  - operator: Exists
    effect: NoSchedule
  - operator: Exists
    effect: NoExecute

## We Play With Fire So You Don't Have To™
fireball:
  slogan: "We Play With Fire So You Don't Have To™"
  humor: "excessive"
"@
}

function Get-DockerHostConfig {
    @"
## Docker Host Monitoring Configuration
## Fireball Industries - Container Chaos Division

deploymentMode: deployment
resourcePreset: medium
replicaCount: 1

## Mount Docker socket for container metrics
hostVolumes:
  enabled: true
  paths:
    - name: docker-socket
      hostPath: /var/run/docker.sock
      mountPath: /var/run/docker.sock
      readOnly: true

config:
  outputs:
    prometheus_client:
      enabled: true
    file:
      enabled: true
      files:
        - "/var/lib/telegraf/docker-metrics.out"

  inputs:
    internal:
      enabled: true
    cpu:
      enabled: true
    mem:
      enabled: true
    disk:
      enabled: true
    docker:
      enabled: true
      gather_services: false
      perdevice: true
      total: true
    system:
      enabled: true
"@
}

function Get-CustomAppConfig {
    @"
## Custom Application Monitoring Configuration
## Fireball Industries - Bespoke Metrics Edition

deploymentMode: deployment
resourcePreset: small
replicaCount: 1

config:
  outputs:
    prometheus_client:
      enabled: true
    influxdb_v2:
      enabled: $(if ($InfluxDBUrl) { 'true' } else { 'false' })

  inputs:
    ## Basic system metrics
    internal:
      enabled: true
    cpu:
      enabled: true
    mem:
      enabled: true
    
    ## Scrape application Prometheus endpoints
    prometheus:
      enabled: true
      urls:
        - http://my-app:9090/metrics
        - http://my-api:8080/metrics

## Add your application-specific environment variables
env:
  - name: APP_ENV
    value: production
  - name: REGION
    value: us-west-2
"@
}

function Get-DatabaseConfig {
    @"
## Database Monitoring Configuration
## Fireball Industries - Query Performance Anxiety Relief

deploymentMode: deployment
resourcePreset: medium

config:
  agent:
    interval: "60s"  # Less frequent for databases
    flush_interval: "60s"

  outputs:
    influxdb_v2:
      enabled: $(if ($InfluxDBUrl) { 'true' } else { 'false' })

  inputs:
    ## Add database-specific plugins
    ## Uncomment and configure as needed:
    
    # postgresql:
    #   enabled: true
    #   address: "host=postgres user=telegraf password=\${DB_PASSWORD} dbname=postgres"
    
    # mysql:
    #   enabled: true
    #   servers: ["telegraf:\${DB_PASSWORD}@tcp(mysql:3306)/"]
    
    # mongodb:
    #   enabled: true
    #   servers: ["mongodb://telegraf:\${DB_PASSWORD}@mongodb:27017"]
    
    # redis:
    #   enabled: true
    #   servers: ["tcp://redis:6379"]

## Mount secrets for database credentials
envFrom:
  - secretRef:
      name: telegraf-db-secrets
"@
}

function Get-MinimalConfig {
    @"
## Minimal Telegraf Configuration
## Fireball Industries - Just The Basics™

deploymentMode: deployment
resourcePreset: small
replicaCount: 1

config:
  agent:
    interval: "60s"
    flush_interval: "60s"

  outputs:
    prometheus_client:
      enabled: true

  inputs:
    internal:
      enabled: true
    cpu:
      enabled: true
    mem:
      enabled: true
    disk:
      enabled: true

fireball:
  humor: "minimal"
  warranty: "extremely void"
"@
}

# Main execution
Write-Host @"

╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║          TELEGRAF CONFIGURATION GENERATOR                     ║
║          Fireball Industries - Automated Excellence           ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Yellow

Write-Host "Generating configuration for scenario: $Scenario`n" -ForegroundColor Cyan

$config = switch ($Scenario) {
    'k8s-full' { Get-K8sFullConfig }
    'docker-host' { Get-DockerHostConfig }
    'custom-app' { Get-CustomAppConfig }
    'database' { Get-DatabaseConfig }
    'minimal' { Get-MinimalConfig }
    default { 
        Write-Host "Unknown scenario: $Scenario" -ForegroundColor Red
        exit 1
    }
}

# Save configuration
$config | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host "✓ Configuration generated successfully!" -ForegroundColor Green
Write-Host "  Output: $OutputPath`n" -ForegroundColor Green

Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review and customize the configuration"
Write-Host "  2. Add secrets for sensitive values (tokens, passwords)"
Write-Host "  3. Deploy using: helm install telegraf . -f $OutputPath`n"

Write-Host "Pro tips:" -ForegroundColor Yellow
Write-Host "  • Use environment variables for secrets (never commit credentials!)"
Write-Host "  • Test configuration before deploying to production"
Write-Host "  • Monitor metric cardinality to avoid explosion`n"

Write-Host "Fireball Industries - We Play With Fire So You Don't Have To™" -ForegroundColor DarkGray
