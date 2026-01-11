<#
.SYNOPSIS
    Prometheus Configuration Generator
    
.DESCRIPTION
    Generates prometheus.yml configurations for common monitoring scenarios.
    Outputs valid configuration that can be used standalone or imported.
    
    Fireball Industries - We Play With Fire So You Don't Have To™
    
.PARAMETER Scenario
    Configuration scenario to generate
    
.PARAMETER OutputFile
    Optional output file path (default: stdout)
    
.PARAMETER ExtraExporters
    Comma-separated list of additional exporters to include
    
.EXAMPLE
    .\generate-config.ps1 -Scenario kubernetes
    Generate K8s monitoring config
    
.EXAMPLE
    .\generate-config.ps1 -Scenario app-monitoring -ExtraExporters "mysql,redis" -OutputFile .\my-prometheus.yml
    Generate app monitoring config with MySQL and Redis exporters
    
.EXAMPLE
    .\generate-config.ps1 -Scenario minimal
    Generate minimal config for testing
    
.NOTES
    Version: 1.0.0
    Author: Fireball Industries
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('kubernetes', 'app-monitoring', 'minimal', 'federated', 'custom')]
    [string]$Scenario,
    
    [string]$OutputFile,
    
    [string]$ExtraExporters
)

function Get-GlobalConfig {
    return @"
global:
  scrape_interval: 30s
  scrape_timeout: 10s
  evaluation_interval: 30s
  external_labels:
    cluster: 'my-cluster'
    environment: 'production'

"@
}

function Get-AlertManagerConfig {
    param([bool]$Include = $true)
    
    if (-not $Include) { return "" }
    
    return @"
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - 'alertmanager:9093'

"@
}

function Get-RuleFilesConfig {
    return @"
rule_files:
  - '/etc/prometheus/rules/*.yml'

"@
}

function Get-KubernetesJobs {
    return @"
scrape_configs:
  # ================================================
  # Kubernetes API Server
  # ================================================
  - job_name: 'kubernetes-apiservers'
    kubernetes_sd_configs:
      - role: endpoints
    scheme: https
    tls_config:
      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    relabel_configs:
      - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
        action: keep
        regex: default;kubernetes;https

  # ================================================
  # Kubernetes Nodes
  # ================================================
  - job_name: 'kubernetes-nodes'
    kubernetes_sd_configs:
      - role: node
    scheme: https
    tls_config:
      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
      insecure_skip_verify: true
    bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)
      - target_label: __address__
        replacement: kubernetes.default.svc:443
      - source_labels: [__meta_kubernetes_node_name]
        regex: (.+)
        target_label: __metrics_path__
        replacement: /api/v1/nodes/$1/proxy/metrics

  # ================================================
  # Kubernetes Pods
  # ================================================
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      # Only scrape pods with prometheus.io/scrape=true annotation
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      # Use custom port if specified
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_port, __meta_kubernetes_pod_ip]
        action: replace
        regex: (\\d+);(.+)
        target_label: __address__
        replacement: `$2:`$1
      # Use custom path if specified
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      # Add namespace label
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: kubernetes_namespace
      # Add pod name label
      - source_labels: [__meta_kubernetes_pod_name]
        action: replace
        target_label: kubernetes_pod_name
      # Add container name label
      - source_labels: [__meta_kubernetes_pod_container_name]
        action: replace
        target_label: kubernetes_container_name

  # ================================================
  # Kubernetes Service Endpoints
  # ================================================
  - job_name: 'kubernetes-service-endpoints'
    kubernetes_sd_configs:
      - role: endpoints
    relabel_configs:
      # Only scrape endpoints with prometheus.io/scrape=true annotation
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      # Use custom port if specified
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_port]
        action: replace
        target_label: __meta_kubernetes_pod_container_port_number
        regex: (.+)
      # Use custom path if specified
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      # Add service name
      - source_labels: [__meta_kubernetes_service_name]
        action: replace
        target_label: kubernetes_service_name
      # Add namespace
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: kubernetes_namespace

  # ================================================
  # Kubernetes cAdvisor
  # ================================================
  - job_name: 'kubernetes-cadvisor'
    kubernetes_sd_configs:
      - role: node
    scheme: https
    tls_config:
      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
      insecure_skip_verify: true
    bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)
      - target_label: __address__
        replacement: kubernetes.default.svc:443
      - source_labels: [__meta_kubernetes_node_name]
        regex: (.+)
        target_label: __metrics_path__
        replacement: /api/v1/nodes/$1/proxy/metrics/cadvisor

"@
}

function Get-ApplicationJobs {
    param([string[]]$Exporters)
    
    $config = @"
scrape_configs:
  # ================================================
  # Application Metrics
  # ================================================
  - job_name: 'application'
    static_configs:
      - targets:
          - 'app:8080'
    metrics_path: '/metrics'

"@

    if ($Exporters -contains 'mysql') {
        $config += @"

  # ================================================
  # MySQL Exporter
  # ================================================
  - job_name: 'mysql'
    static_configs:
      - targets:
          - 'mysql-exporter:9104'

"@
    }

    if ($Exporters -contains 'redis') {
        $config += @"

  # ================================================
  # Redis Exporter
  # ================================================
  - job_name: 'redis'
    static_configs:
      - targets:
          - 'redis-exporter:9121'

"@
    }

    if ($Exporters -contains 'postgres') {
        $config += @"

  # ================================================
  # PostgreSQL Exporter
  # ================================================
  - job_name: 'postgres'
    static_configs:
      - targets:
          - 'postgres-exporter:9187'

"@
    }

    if ($Exporters -contains 'rabbitmq') {
        $config += @"

  # ================================================
  # RabbitMQ Exporter
  # ================================================
  - job_name: 'rabbitmq'
    static_configs:
      - targets:
          - 'rabbitmq-exporter:9419'

"@
    }

    if ($Exporters -contains 'nginx') {
        $config += @"

  # ================================================
  # NGINX Exporter
  # ================================================
  - job_name: 'nginx'
    static_configs:
      - targets:
          - 'nginx-exporter:9113'

"@
    }

    if ($Exporters -contains 'node') {
        $config += @"

  # ================================================
  # Node Exporter
  # ================================================
  - job_name: 'node'
    static_configs:
      - targets:
          - 'node-exporter:9100'

"@
    }

    return $config
}

function Get-MinimalJobs {
    return @"
scrape_configs:
  # ================================================
  # Prometheus Self-Monitoring
  # ================================================
  - job_name: 'prometheus'
    static_configs:
      - targets:
          - 'localhost:9090'

  # ================================================
  # Simple Static Targets
  # ================================================
  - job_name: 'example-service'
    static_configs:
      - targets:
          - 'service1:8080'
          - 'service2:8080'
        labels:
          environment: 'dev'

"@
}

function Get-FederatedJobs {
    return @"
scrape_configs:
  # ================================================
  # Prometheus Self-Monitoring
  # ================================================
  - job_name: 'prometheus'
    static_configs:
      - targets:
          - 'localhost:9090'

  # ================================================
  # Federated Scraping from Central Prometheus
  # ================================================
  - job_name: 'federate'
    scrape_interval: 60s
    honor_labels: true
    metrics_path: '/federate'
    params:
      'match[]':
        - '{job=~".+"}'
    static_configs:
      - targets:
          - 'central-prometheus:9090'

"@
}

function Get-RemoteWriteConfig {
    return @"

# ================================================
# Remote Write (for long-term storage)
# ================================================
remote_write:
  - url: 'https://prometheus-central:9090/api/v1/write'
    queue_config:
      capacity: 10000
      max_shards: 10
      min_shards: 1
      max_samples_per_send: 5000
      batch_send_deadline: 5s
    write_relabel_configs:
      - source_labels: [__name__]
        regex: 'up|node_.*|container_.*'
        action: keep

"@
}

function Get-RemoteReadConfig {
    return @"

# ================================================
# Remote Read (query long-term storage)
# ================================================
remote_read:
  - url: 'https://prometheus-central:9090/api/v1/read'
    read_recent: true

"@
}

# Main execution
Write-Host @"

╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║   🔧 Prometheus Configuration Generator                          ║
║   Fireball Industries - We Play With Fire So You Don't Have To™  ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

Write-Host "Generating configuration for scenario: $Scenario`n" -ForegroundColor White

# Parse extra exporters
$exporterList = @()
if ($ExtraExporters) {
    $exporterList = $ExtraExporters -split ',' | ForEach-Object { $_.Trim() }
    Write-Host "Including exporters: $($exporterList -join ', ')`n" -ForegroundColor Cyan
}

# Build configuration based on scenario
$config = ""

# Header comment
$config += @"
# ================================================
# Prometheus Configuration
# Generated by: Fireball Industries Config Generator
# Scenario: $Scenario
# Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# ================================================

"@

# Global config
$config += Get-GlobalConfig

# Scenario-specific configuration
switch ($Scenario) {
    'kubernetes' {
        $config += Get-AlertManagerConfig
        $config += Get-RuleFilesConfig
        $config += Get-KubernetesJobs
    }
    
    'app-monitoring' {
        $config += Get-AlertManagerConfig
        $config += Get-RuleFilesConfig
        $config += Get-ApplicationJobs -Exporters $exporterList
        
        # Add Kubernetes pod scraping for apps running in K8s
        $config += @"

  # ================================================
  # Kubernetes Pods (for app containers)
  # ================================================
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_port, __meta_kubernetes_pod_ip]
        action: replace
        regex: (\\d+);(.+)
        target_label: __address__
        replacement: `$2:`$1
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: kubernetes_namespace
      - source_labels: [__meta_kubernetes_pod_name]
        action: replace
        target_label: kubernetes_pod_name

"@
    }
    
    'minimal' {
        $config += Get-MinimalJobs
    }
    
    'federated' {
        $config += Get-FederatedJobs
        $config += Get-RemoteWriteConfig
    }
    
    'custom' {
        $config += Get-AlertManagerConfig -Include $false
        $config += @"
# Add your custom scrape_configs here
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  
  # Add more jobs as needed...

"@
    }
}

# Add helpful comments at the end
$config += @"

# ================================================
# Configuration Tips
# ================================================
# 1. To enable scraping for a pod, add annotations:
#    prometheus.io/scrape: "true"
#    prometheus.io/port: "8080"
#    prometheus.io/path: "/metrics"
#
# 2. To enable scraping for a service, add service annotations:
#    prometheus.io/scrape: "true"
#    prometheus.io/port: "8080"
#
# 3. Test configuration:
#    promtool check config prometheus.yml
#
# 4. Reload configuration without restart:
#    curl -X POST http://localhost:9090/-/reload
#
# 5. For HA deployments, ensure external_labels are unique
#    per Prometheus instance to enable deduplication
#
# Fireball Industries - We Play With Fire So You Don't Have To™
# ================================================
"@

# Output configuration
if ($OutputFile) {
    $config | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "✅ Configuration written to: $OutputFile`n" -ForegroundColor Green
    
    # Validate if promtool is available
    $promtool = Get-Command promtool -ErrorAction SilentlyContinue
    
    if ($promtool) {
        Write-Host "🔍 Validating configuration...`n" -ForegroundColor Cyan
        
        $validation = promtool check config $OutputFile 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Configuration is valid!`n" -ForegroundColor Green
        }
        else {
            Write-Host "❌ Configuration validation failed:`n" -ForegroundColor Red
            Write-Host $validation -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "ℹ️  promtool not found - skipping validation" -ForegroundColor Yellow
        Write-Host "   Install Prometheus tools to validate configs`n" -ForegroundColor Gray
    }
    
    # Show file info
    $fileInfo = Get-Item $OutputFile
    Write-Host "📄 File Information:" -ForegroundColor White
    Write-Host "   Size: $($fileInfo.Length) bytes" -ForegroundColor Cyan
    Write-Host "   Lines: $(($config -split "`n").Count)" -ForegroundColor Cyan
    Write-Host ""
    
    # Show next steps
    Write-Host "📋 Next Steps:" -ForegroundColor White
    Write-Host "   1. Review the generated configuration" -ForegroundColor Gray
    Write-Host "   2. Customize for your environment" -ForegroundColor Gray
    Write-Host "   3. Deploy to Prometheus:" -ForegroundColor Gray
    Write-Host "      kubectl create configmap prometheus-config --from-file=$OutputFile -n monitoring" -ForegroundColor Cyan
    Write-Host ""
}
else {
    # Output to stdout
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan
    Write-Output $config
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "`nℹ️  Tip: Use -OutputFile to save to a file`n" -ForegroundColor Yellow
}

# Show exporters reference
if ($Scenario -eq 'app-monitoring') {
    Write-Host "📚 Supported Exporters:" -ForegroundColor White
    Write-Host "   - mysql       : MySQL database metrics (port 9104)" -ForegroundColor Gray
    Write-Host "   - redis       : Redis metrics (port 9121)" -ForegroundColor Gray
    Write-Host "   - postgres    : PostgreSQL metrics (port 9187)" -ForegroundColor Gray
    Write-Host "   - rabbitmq    : RabbitMQ metrics (port 9419)" -ForegroundColor Gray
    Write-Host "   - nginx       : NGINX metrics (port 9113)" -ForegroundColor Gray
    Write-Host "   - node        : Node/host metrics (port 9100)" -ForegroundColor Gray
    Write-Host "`n   Example: -ExtraExporters 'mysql,redis,node'`n" -ForegroundColor Cyan
}

Write-Host "✨ Configuration generation complete!`n" -ForegroundColor Green
