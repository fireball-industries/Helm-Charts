<#
.SYNOPSIS
    Prometheus Pod Management Script
    
.DESCRIPTION
    Comprehensive management tool for Prometheus Pod deployments.
    Handles deployment, upgrades, health checks, backups, and more.
    
    Fireball Industries - We Play With Fire So You Don't Have To™
    
.PARAMETER Action
    Action to perform: deploy, upgrade, delete, health-check, validate, backup, restore, query, status, tune
    
.PARAMETER Namespace
    Kubernetes namespace (default: monitoring)
    
.PARAMETER ReleaseName
    Helm release name (default: prometheus)
    
.PARAMETER ValuesFile
    Path to custom values.yaml file
    
.PARAMETER Preset
    Resource preset: small, medium, large, xlarge, custom (for deploy/upgrade)
    
.PARAMETER BackupPath
    Path for backup files (for backup/restore)
    
.PARAMETER Query
    PromQL query to execute (for query action)
    
.EXAMPLE
    .\manage-prometheus.ps1 -Action deploy
    Deploy Prometheus with default settings
    
.EXAMPLE
    .\manage-prometheus.ps1 -Action deploy -Preset large -Namespace prod-monitoring
    Deploy with large preset in custom namespace
    
.EXAMPLE
    .\manage-prometheus.ps1 -Action upgrade -ValuesFile ./my-values.yaml
    Upgrade with custom values
    
.EXAMPLE
    .\manage-prometheus.ps1 -Action backup -BackupPath ./backups
    Backup Prometheus data
    
.EXAMPLE
    .\manage-prometheus.ps1 -Action query -Query "up"
    Execute PromQL query
    
.NOTES
    Version: 1.0.0
    Author: Fireball Industries
    Requires: kubectl, helm
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('deploy', 'upgrade', 'delete', 'health-check', 'validate', 'backup', 'restore', 'query', 'status', 'tune')]
    [string]$Action,
    
    [string]$Namespace = 'monitoring',
    [string]$ReleaseName = 'prometheus',
    [string]$ValuesFile = '',
    [ValidateSet('small', 'medium', 'large', 'xlarge', 'custom', '')]
    [string]$Preset = 'medium',
    [string]$BackupPath = './prometheus-backup',
    [string]$Query = ''
)

# Colors for output
$script:Colors = @{
    Success = 'Green'
    Warning = 'Yellow'
    Error   = 'Red'
    Info    = 'Cyan'
    Prompt  = 'Magenta'
}

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Type = 'Info'
    )
    
    $color = $script:Colors[$Type]
    Write-Host $Message -ForegroundColor $color
}

function Test-Prerequisites {
    Write-ColorOutput "`n🔍 Checking prerequisites..." -Type Info
    
    # Check kubectl
    try {
        $null = kubectl version --client --short 2>$null
        Write-ColorOutput "✅ kubectl found" -Type Success
    }
    catch {
        Write-ColorOutput "❌ kubectl not found. Please install kubectl." -Type Error
        exit 1
    }
    
    # Check helm
    try {
        $null = helm version --short 2>$null
        Write-ColorOutput "✅ helm found" -Type Success
    }
    catch {
        Write-ColorOutput "❌ helm not found. Please install helm 3.0+." -Type Error
        exit 1
    }
    
    # Check cluster connectivity
    try {
        $null = kubectl cluster-info 2>$null
        Write-ColorOutput "✅ Kubernetes cluster accessible" -Type Success
    }
    catch {
        Write-ColorOutput "❌ Cannot connect to Kubernetes cluster" -Type Error
        exit 1
    }
}

function Deploy-Prometheus {
    Write-ColorOutput "`n🚀 Deploying Prometheus..." -Type Info
    
    # Check if release already exists
    $existing = helm list -n $Namespace -o json | ConvertFrom-Json
    if ($existing | Where-Object { $_.name -eq $ReleaseName }) {
        Write-ColorOutput "⚠️  Release '$ReleaseName' already exists in namespace '$Namespace'" -Type Warning
        $response = Read-Host "Upgrade instead? (y/n)"
        if ($response -eq 'y') {
            Upgrade-Prometheus
            return
        }
        else {
            Write-ColorOutput "Deployment cancelled" -Type Warning
            return
        }
    }
    
    # Build helm install command
    $helmArgs = @(
        'install', $ReleaseName, '.',
        '--namespace', $Namespace,
        '--create-namespace',
        '--set', "resourcePreset=$Preset"
    )
    
    if ($ValuesFile) {
        $helmArgs += @('--values', $ValuesFile)
    }
    
    Write-ColorOutput "📦 Installing chart with preset: $Preset" -Type Info
    helm @helmArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✅ Deployment successful!" -Type Success
        
        Write-ColorOutput "`n⏳ Waiting for pod to be ready..." -Type Info
        kubectl wait --for=condition=ready pod `
            -l app.kubernetes.io/name=prometheus-pod `
            -n $Namespace `
            --timeout=5m
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ Pod is ready!" -Type Success
            Get-PrometheusStatus
        }
    }
    else {
        Write-ColorOutput "❌ Deployment failed" -Type Error
        exit 1
    }
}

function Upgrade-Prometheus {
    Write-ColorOutput "`n⬆️  Upgrading Prometheus..." -Type Info
    
    $helmArgs = @(
        'upgrade', $ReleaseName, '.',
        '--namespace', $Namespace
    )
    
    if ($ValuesFile) {
        $helmArgs += @('--values', $ValuesFile)
    }
    elseif ($Preset) {
        $helmArgs += @('--set', "resourcePreset=$Preset", '--reuse-values')
    }
    else {
        $helmArgs += @('--reuse-values')
    }
    
    helm @helmArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✅ Upgrade successful!" -Type Success
        
        Write-ColorOutput "`n⏳ Waiting for rollout..." -Type Info
        kubectl rollout status deployment/$ReleaseName -n $Namespace 2>$null
        kubectl rollout status statefulset/$ReleaseName -n $Namespace 2>$null
        
        Get-PrometheusStatus
    }
    else {
        Write-ColorOutput "❌ Upgrade failed" -Type Error
        exit 1
    }
}

function Remove-Prometheus {
    Write-ColorOutput "`n🗑️  Deleting Prometheus..." -Type Warning
    
    $response = Read-Host "⚠️  This will delete the release '$ReleaseName' in namespace '$Namespace'. Continue? (yes/no)"
    if ($response -ne 'yes') {
        Write-ColorOutput "Deletion cancelled" -Type Info
        return
    }
    
    $deletePVC = Read-Host "Delete PVCs too? (yes/no)"
    
    helm uninstall $ReleaseName --namespace $Namespace
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✅ Release deleted" -Type Success
        
        if ($deletePVC -eq 'yes') {
            Write-ColorOutput "🗑️  Deleting PVCs..." -Type Warning
            kubectl delete pvc -n $Namespace -l app.kubernetes.io/instance=$ReleaseName
        }
    }
    else {
        Write-ColorOutput "❌ Deletion failed" -Type Error
        exit 1
    }
}

function Test-PrometheusHealth {
    Write-ColorOutput "`n🏥 Checking Prometheus health..." -Type Info
    
    # Check pod status
    Write-ColorOutput "`n📊 Pod Status:" -Type Info
    kubectl get pods -n $Namespace -l app.kubernetes.io/name=prometheus-pod
    
    # Check PVC status
    Write-ColorOutput "`n💾 PVC Status:" -Type Info
    kubectl get pvc -n $Namespace -l app.kubernetes.io/instance=$ReleaseName
    
    # Check service
    Write-ColorOutput "`n🌐 Service Status:" -Type Info
    kubectl get svc -n $Namespace -l app.kubernetes.io/name=prometheus-pod
    
    # Port-forward and check health endpoint
    Write-ColorOutput "`n🔍 Checking health endpoint..." -Type Info
    $podName = kubectl get pods -n $Namespace -l app.kubernetes.io/name=prometheus-pod -o jsonpath='{.items[0].metadata.name}' 2>$null
    
    if ($podName) {
        try {
            $health = kubectl exec -n $Namespace $podName -- wget -qO- http://localhost:9090/-/healthy
            if ($health -eq 'Prometheus is Healthy.') {
                Write-ColorOutput "✅ Prometheus is healthy" -Type Success
            }
            else {
                Write-ColorOutput "⚠️  Unexpected health response: $health" -Type Warning
            }
        }
        catch {
            Write-ColorOutput "❌ Health check failed: $_" -Type Error
        }
        
        # Check readiness
        try {
            $ready = kubectl exec -n $Namespace $podName -- wget -qO- http://localhost:9090/-/ready
            if ($ready -eq 'Prometheus is Ready.') {
                Write-ColorOutput "✅ Prometheus is ready" -Type Success
            }
            else {
                Write-ColorOutput "⚠️  Prometheus not ready: $ready" -Type Warning
            }
        }
        catch {
            Write-ColorOutput "❌ Readiness check failed: $_" -Type Error
        }
    }
    else {
        Write-ColorOutput "❌ No pod found" -Type Error
    }
}

function Test-PrometheusConfiguration {
    Write-ColorOutput "`n✔️  Validating configuration..." -Type Info
    
    # Validate values.yaml
    if (Test-Path 'values.yaml') {
        Write-ColorOutput "Validating values.yaml..." -Type Info
        helm lint . --values values.yaml
    }
    
    # Dry-run installation
    Write-ColorOutput "`nDry-run installation..." -Type Info
    helm install $ReleaseName . --dry-run --debug --namespace $Namespace
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✅ Configuration is valid" -Type Success
    }
    else {
        Write-ColorOutput "❌ Configuration validation failed" -Type Error
        exit 1
    }
}

function Backup-PrometheusData {
    Write-ColorOutput "`n💾 Backing up Prometheus data..." -Type Info
    
    $backupDir = Join-Path $BackupPath (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    
    # Get pod name
    $podName = kubectl get pods -n $Namespace -l app.kubernetes.io/name=prometheus-pod -o jsonpath='{.items[0].metadata.name}'
    
    if (-not $podName) {
        Write-ColorOutput "❌ No pod found" -Type Error
        return
    }
    
    Write-ColorOutput "Pod: $podName" -Type Info
    Write-ColorOutput "Backup location: $backupDir" -Type Info
    
    # Create snapshot
    Write-ColorOutput "`nCreating TSDB snapshot..." -Type Info
    kubectl exec -n $Namespace $podName -- wget -qO- --post-data='' http://localhost:9090/api/v1/admin/tsdb/snapshot
    
    # Get snapshot name (last created)
    $snapshotName = kubectl exec -n $Namespace $podName -- sh -c 'ls -t /prometheus/snapshots | head -1'
    
    if ($snapshotName) {
        Write-ColorOutput "Snapshot created: $snapshotName" -Type Success
        
        # Copy snapshot to local
        Write-ColorOutput "`nDownloading snapshot..." -Type Info
        kubectl cp "$Namespace/${podName}:/prometheus/snapshots/$snapshotName" "$backupDir/data" -c prometheus
        
        # Backup ConfigMaps
        Write-ColorOutput "`nBacking up ConfigMaps..." -Type Info
        kubectl get configmap -n $Namespace -l app.kubernetes.io/instance=$ReleaseName -o yaml > "$backupDir/configmaps.yaml"
        
        # Backup Secrets (base64 encoded)
        Write-ColorOutput "`nBacking up Secrets..." -Type Info
        kubectl get secret -n $Namespace -l app.kubernetes.io/instance=$ReleaseName -o yaml > "$backupDir/secrets.yaml"
        
        # Backup Helm values
        Write-ColorOutput "`nBacking up Helm values..." -Type Info
        helm get values $ReleaseName -n $Namespace > "$backupDir/values.yaml"
        
        # Create backup manifest
        @{
            timestamp   = Get-Date -Format 'o'
            release     = $ReleaseName
            namespace   = $Namespace
            snapshot    = $snapshotName
            podName     = $podName
        } | ConvertTo-Json | Out-File "$backupDir/manifest.json"
        
        Write-ColorOutput "`n✅ Backup complete: $backupDir" -Type Success
        
        # Cleanup snapshot on pod
        $cleanup = Read-Host "`nCleanup snapshot from pod? (y/n)"
        if ($cleanup -eq 'y') {
            kubectl exec -n $Namespace $podName -- rm -rf "/prometheus/snapshots/$snapshotName"
            Write-ColorOutput "Snapshot cleaned up" -Type Success
        }
    }
    else {
        Write-ColorOutput "❌ Snapshot creation failed" -Type Error
    }
}

function Restore-PrometheusData {
    Write-ColorOutput "`n♻️  Restoring Prometheus data..." -Type Warning
    
    if (-not (Test-Path $BackupPath)) {
        Write-ColorOutput "❌ Backup path not found: $BackupPath" -Type Error
        return
    }
    
    # List available backups
    $backups = Get-ChildItem -Path $BackupPath -Directory | Sort-Object Name -Descending
    
    if ($backups.Count -eq 0) {
        Write-ColorOutput "❌ No backups found in $BackupPath" -Type Error
        return
    }
    
    Write-ColorOutput "`nAvailable backups:" -Type Info
    for ($i = 0; $i -lt $backups.Count; $i++) {
        Write-Host "  [$i] $($backups[$i].Name)"
    }
    
    $selection = Read-Host "`nSelect backup to restore (number)"
    $backupDir = $backups[$selection].FullName
    
    if (-not (Test-Path "$backupDir/manifest.json")) {
        Write-ColorOutput "❌ Invalid backup (missing manifest)" -Type Error
        return
    }
    
    $manifest = Get-Content "$backupDir/manifest.json" | ConvertFrom-Json
    
    Write-ColorOutput "`n📋 Backup Info:" -Type Info
    Write-ColorOutput "  Timestamp: $($manifest.timestamp)" -Type Info
    Write-ColorOutput "  Release: $($manifest.release)" -Type Info
    Write-ColorOutput "  Namespace: $($manifest.namespace)" -Type Info
    
    $confirm = Read-Host "`n⚠️  This will OVERWRITE current Prometheus data. Continue? (yes/no)"
    if ($confirm -ne 'yes') {
        Write-ColorOutput "Restore cancelled" -Type Info
        return
    }
    
    # Scale down Prometheus
    Write-ColorOutput "`n🛑 Scaling down Prometheus..." -Type Warning
    kubectl scale deployment/$ReleaseName --replicas=0 -n $Namespace 2>$null
    kubectl scale statefulset/$ReleaseName --replicas=0 -n $Namespace 2>$null
    
    Start-Sleep -Seconds 5
    
    # Restore ConfigMaps
    if (Test-Path "$backupDir/configmaps.yaml") {
        Write-ColorOutput "Restoring ConfigMaps..." -Type Info
        kubectl apply -f "$backupDir/configmaps.yaml"
    }
    
    # Restore data (requires manual PVC mount or copy to existing pod)
    Write-ColorOutput "`n⚠️  Data restore requires manual intervention:" -Type Warning
    Write-ColorOutput "  1. Mount PVC to temporary pod" -Type Info
    Write-ColorOutput "  2. Copy data from: $backupDir/data" -Type Info
    Write-ColorOutput "  3. Restart Prometheus" -Type Info
    
    # Scale up
    $scaleUp = Read-Host "`nScale up Prometheus now? (y/n)"
    if ($scaleUp -eq 'y') {
        kubectl scale deployment/$ReleaseName --replicas=1 -n $Namespace 2>$null
        kubectl scale statefulset/$ReleaseName --replicas=2 -n $Namespace 2>$null
        Write-ColorOutput "✅ Prometheus scaled up" -Type Success
    }
}

function Invoke-PrometheusQuery {
    param([string]$QueryString)
    
    if (-not $QueryString) {
        $QueryString = Read-Host "Enter PromQL query"
    }
    
    Write-ColorOutput "`n🔍 Executing query: $QueryString" -Type Info
    
    $podName = kubectl get pods -n $Namespace -l app.kubernetes.io/name=prometheus-pod -o jsonpath='{.items[0].metadata.name}'
    
    if (-not $podName) {
        Write-ColorOutput "❌ No pod found" -Type Error
        return
    }
    
    # URL encode query
    $encodedQuery = [System.Web.HttpUtility]::UrlEncode($QueryString)
    
    # Execute query
    $result = kubectl exec -n $Namespace $podName -- wget -qO- "http://localhost:9090/api/v1/query?query=$encodedQuery"
    
    if ($result) {
        $json = $result | ConvertFrom-Json
        
        if ($json.status -eq 'success') {
            Write-ColorOutput "`n✅ Query successful" -Type Success
            Write-ColorOutput "`nResult:" -Type Info
            $json.data.result | ConvertTo-Json -Depth 5 | Write-Host
        }
        else {
            Write-ColorOutput "❌ Query failed: $($json.error)" -Type Error
        }
    }
}

function Get-PrometheusStatus {
    Write-ColorOutput "`n📊 Prometheus Status" -Type Info
    Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -Type Info
    
    # Release info
    $release = helm list -n $Namespace -o json | ConvertFrom-Json | Where-Object { $_.name -eq $ReleaseName }
    
    if ($release) {
        Write-ColorOutput "`n📦 Release Info:" -Type Info
        Write-ColorOutput "  Name: $($release.name)" -Type Info
        Write-ColorOutput "  Namespace: $($release.namespace)" -Type Info
        Write-ColorOutput "  Status: $($release.status)" -Type Info
        Write-ColorOutput "  Version: $($release.chart)" -Type Info
        Write-ColorOutput "  Updated: $($release.updated)" -Type Info
    }
    
    # Pod status
    Write-ColorOutput "`n🏃 Pods:" -Type Info
    kubectl get pods -n $Namespace -l app.kubernetes.io/instance=$ReleaseName
    
    # PVC status
    Write-ColorOutput "`n💾 Storage:" -Type Info
    kubectl get pvc -n $Namespace -l app.kubernetes.io/instance=$ReleaseName
    
    # Service status
    Write-ColorOutput "`n🌐 Services:" -Type Info
    kubectl get svc -n $Namespace -l app.kubernetes.io/instance=$ReleaseName
    
    # Resource usage
    Write-ColorOutput "`n📈 Resource Usage:" -Type Info
    kubectl top pods -n $Namespace -l app.kubernetes.io/instance=$ReleaseName 2>$null
    
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "  (Metrics server not available)" -Type Warning
    }
    
    # Quick health check
    $podName = kubectl get pods -n $Namespace -l app.kubernetes.io/name=prometheus-pod -o jsonpath='{.items[0].metadata.name}' 2>$null
    
    if ($podName) {
        try {
            $tsdbStats = kubectl exec -n $Namespace $podName -- wget -qO- http://localhost:9090/api/v1/status/tsdb 2>$null | ConvertFrom-Json
            
            if ($tsdbStats.status -eq 'success') {
                Write-ColorOutput "`n📊 TSDB Stats:" -Type Info
                Write-ColorOutput "  Series: $($tsdbStats.data.seriesCountByMetricName | Measure-Object -Sum | Select-Object -ExpandProperty Sum)" -Type Info
                Write-ColorOutput "  Label pairs: $($tsdbStats.data.labelValueCountByLabelName | Measure-Object -Sum | Select-Object -ExpandProperty Sum)" -Type Info
            }
        }
        catch {
            Write-ColorOutput "`n⚠️  Could not retrieve TSDB stats" -Type Warning
        }
    }
    
    Write-ColorOutput "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -Type Info
}

function Optimize-Prometheus {
    Write-ColorOutput "`n⚙️  Prometheus Tuning Advisor" -Type Info
    Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -Type Info
    
    $podName = kubectl get pods -n $Namespace -l app.kubernetes.io/name=prometheus-pod -o jsonpath='{.items[0].metadata.name}' 2>$null
    
    if (-not $podName) {
        Write-ColorOutput "❌ No pod found" -Type Error
        return
    }
    
    # Get current resource usage
    $usage = kubectl top pod -n $Namespace $podName --no-headers 2>$null
    
    if ($usage) {
        $cpuUsage = ($usage -split '\s+')[1]
        $memUsage = ($usage -split '\s+')[2]
        
        Write-ColorOutput "`n📊 Current Usage:" -Type Info
        Write-ColorOutput "  CPU: $cpuUsage" -Type Info
        Write-ColorOutput "  Memory: $memUsage" -Type Info
    }
    
    # Get TSDB stats
    try {
        $tsdb = kubectl exec -n $Namespace $podName -- wget -qO- http://localhost:9090/api/v1/status/tsdb | ConvertFrom-Json
        
        if ($tsdb.status -eq 'success') {
            $totalSeries = ($tsdb.data.seriesCountByMetricName | Measure-Object -Property Value -Sum).Sum
            
            Write-ColorOutput "`n📈 TSDB Stats:" -Type Info
            Write-ColorOutput "  Total Series: $totalSeries" -Type Info
            
            # Recommendations
            Write-ColorOutput "`n💡 Recommendations:" -Type Info
            
            if ($totalSeries -lt 10000) {
                Write-ColorOutput "  ✅ Series count is low - 'small' preset is sufficient" -Type Success
            }
            elseif ($totalSeries -lt 50000) {
                Write-ColorOutput "  ✅ Series count is moderate - 'medium' preset recommended" -Type Success
            }
            elseif ($totalSeries -lt 500000) {
                Write-ColorOutput "  ⚠️  Series count is high - consider 'large' preset" -Type Warning
            }
            else {
                Write-ColorOutput "  ⚠️  Series count is very high - 'xlarge' or custom tuning needed" -Type Warning
            }
            
            # Memory usage check
            if ($memUsage) {
                $memValue = [int]($memUsage -replace '[^\d]', '')
                if ($memValue -gt 1500) {
                    Write-ColorOutput "  ⚠️  High memory usage - consider increasing limits" -Type Warning
                }
            }
        }
    }
    catch {
        Write-ColorOutput "⚠️  Could not retrieve tuning metrics" -Type Warning
    }
    
    Write-ColorOutput "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -Type Info
}

# Main execution
Write-ColorOutput @"

╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║   🔥 Prometheus Pod Management Script                            ║
║   Fireball Industries - We Play With Fire So You Don't Have To™  ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
"@ -Type Info

Test-Prerequisites

switch ($Action) {
    'deploy' { Deploy-Prometheus }
    'upgrade' { Upgrade-Prometheus }
    'delete' { Remove-Prometheus }
    'health-check' { Test-PrometheusHealth }
    'validate' { Test-PrometheusConfiguration }
    'backup' { Backup-PrometheusData }
    'restore' { Restore-PrometheusData }
    'query' { Invoke-PrometheusQuery -QueryString $Query }
    'status' { Get-PrometheusStatus }
    'tune' { Optimize-Prometheus }
}

Write-ColorOutput "`n✨ Done!`n" -Type Success
