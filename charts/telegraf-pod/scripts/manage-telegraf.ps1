#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Telegraf Pod Management Script
    Fireball Industries - We Play With Fire So You Don't Have To™

.DESCRIPTION
    Comprehensive management script for Telegraf Pod deployments.
    Because clicking around Rancher gets old fast.
    
    Features:
    - Deploy/Upgrade/Delete Telegraf instances
    - Health checks and diagnostics
    - Configuration validation
    - Metrics collection testing
    - Log aggregation
    - Backup/Restore operations
    - Performance tuning recommendations

.PARAMETER Action
    The action to perform: deploy, upgrade, delete, health-check, validate, test-metrics, logs, backup, restore, tune

.PARAMETER Namespace
    Kubernetes namespace for the Telegraf instance (default: telegraf)

.PARAMETER ReleaseName
    Helm release name (default: telegraf)

.PARAMETER Mode
    Deployment mode: deployment or daemonset (default: deployment)

.PARAMETER Preset
    Resource preset: small, medium, large, custom (default: medium)

.PARAMETER ValuesFile
    Path to custom values.yaml file

.EXAMPLE
    .\manage-telegraf.ps1 -Action deploy -Namespace telegraf-prod -Preset large

.EXAMPLE
    .\manage-telegraf.ps1 -Action health-check -Namespace telegraf-prod

.EXAMPLE
    .\manage-telegraf.ps1 -Action test-metrics -Namespace telegraf-prod

.NOTES
    Author: Patrick Ryan
    Company: Fireball Industries
    Version: 1.0.0
    Warning: May contain excessive sarcasm
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('deploy', 'upgrade', 'delete', 'health-check', 'validate', 'test-metrics', 'logs', 'backup', 'restore', 'tune', 'status')]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$Namespace = "telegraf",
    
    [Parameter(Mandatory=$false)]
    [string]$ReleaseName = "telegraf",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('deployment', 'daemonset')]
    [string]$Mode = "deployment",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('small', 'medium', 'large', 'custom')]
    [string]$Preset = "medium",
    
    [Parameter(Mandatory=$false)]
    [string]$ValuesFile = "",
    
    [Parameter(Mandatory=$false)]
    [string]$BackupPath = "./backups",
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose
)

# Color output functions
function Write-FireballSuccess {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-FireballError {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-FireballWarning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-FireballInfo {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Cyan
}

function Write-FireballBanner {
    Write-Host @"

╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║              TELEGRAF POD MANAGEMENT SCRIPT                   ║
║           Fireball Industries - Professional Chaos            ║
║        We Play With Fire So You Don't Have To™                ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Yellow
}

# Preflight checks
function Test-Prerequisites {
    Write-FireballInfo "Running preflight checks..."
    
    $missing = @()
    
    # Check kubectl
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        $missing += "kubectl"
    }
    
    # Check helm
    if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
        $missing += "helm"
    }
    
    if ($missing.Count -gt 0) {
        Write-FireballError "Missing required tools: $($missing -join ', ')"
        Write-FireballInfo "Please install missing tools and try again."
        exit 1
    }
    
    # Test cluster connectivity
    try {
        kubectl cluster-info --request-timeout=5s | Out-Null
        Write-FireballSuccess "Cluster connectivity verified"
    }
    catch {
        Write-FireballError "Cannot connect to Kubernetes cluster"
        Write-FireballInfo "Check your kubeconfig and cluster status"
        exit 1
    }
}

# Deploy Telegraf
function Deploy-Telegraf {
    Write-FireballInfo "Deploying Telegraf pod to namespace: $Namespace"
    Write-FireballInfo "Mode: $Mode | Preset: $Preset"
    
    # Create namespace if it doesn't exist
    kubectl get namespace $Namespace 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-FireballInfo "Creating namespace: $Namespace"
        kubectl create namespace $Namespace
    }
    
    # Build helm command
    $helmArgs = @(
        "install", $ReleaseName, ".",
        "--namespace", $Namespace,
        "--create-namespace",
        "--set", "deploymentMode=$Mode",
        "--set", "resourcePreset=$Preset"
    )
    
    if ($ValuesFile) {
        $helmArgs += @("--values", $ValuesFile)
    }
    
    if ($DryRun) {
        $helmArgs += "--dry-run"
        Write-FireballWarning "DRY RUN MODE - No actual deployment"
    }
    
    Write-FireballInfo "Executing: helm $($helmArgs -join ' ')"
    
    & helm @helmArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-FireballSuccess "Telegraf deployed successfully!"
        
        if (-not $DryRun) {
            Write-FireballInfo "Waiting for pods to be ready..."
            Start-Sleep -Seconds 5
            
            kubectl wait --for=condition=ready pod `
                -l "app.kubernetes.io/name=telegraf" `
                -n $Namespace `
                --timeout=120s
            
            if ($LASTEXITCODE -eq 0) {
                Write-FireballSuccess "Pods are ready!"
                Get-TelegrafStatus
            }
        }
    }
    else {
        Write-FireballError "Deployment failed!"
        exit 1
    }
}

# Upgrade Telegraf
function Upgrade-Telegraf {
    Write-FireballInfo "Upgrading Telegraf release: $ReleaseName"
    
    $helmArgs = @(
        "upgrade", $ReleaseName, ".",
        "--namespace", $Namespace,
        "--set", "deploymentMode=$Mode",
        "--set", "resourcePreset=$Preset"
    )
    
    if ($ValuesFile) {
        $helmArgs += @("--values", $ValuesFile)
    }
    
    if ($DryRun) {
        $helmArgs += "--dry-run"
    }
    
    & helm @helmArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-FireballSuccess "Upgrade completed successfully!"
    }
    else {
        Write-FireballError "Upgrade failed!"
        exit 1
    }
}

# Delete Telegraf
function Remove-Telegraf {
    Write-FireballWarning "Preparing to delete Telegraf release: $ReleaseName"
    
    if (-not $DryRun) {
        $confirm = Read-Host "Are you sure? Type 'DELETE' to confirm"
        if ($confirm -ne "DELETE") {
            Write-FireballInfo "Deletion cancelled"
            return
        }
    }
    
    helm uninstall $ReleaseName --namespace $Namespace
    
    if ($LASTEXITCODE -eq 0) {
        Write-FireballSuccess "Telegraf release deleted"
        
        # Optionally delete namespace
        $deleteNs = Read-Host "Delete namespace '$Namespace'? (y/N)"
        if ($deleteNs -eq 'y') {
            kubectl delete namespace $Namespace
            Write-FireballSuccess "Namespace deleted"
        }
    }
}

# Health check
function Get-TelegrafHealth {
    Write-FireballInfo "Performing health check for $ReleaseName in $Namespace"
    
    Write-Host "`n=== Pod Status ===" -ForegroundColor Cyan
    kubectl get pods -n $Namespace -l "app.kubernetes.io/name=telegraf"
    
    Write-Host "`n=== Pod Details ===" -ForegroundColor Cyan
    $pods = kubectl get pods -n $Namespace -l "app.kubernetes.io/name=telegraf" -o json | ConvertFrom-Json
    
    foreach ($pod in $pods.items) {
        $podName = $pod.metadata.name
        $status = $pod.status.phase
        
        Write-Host "`nPod: $podName" -ForegroundColor Yellow
        Write-Host "Status: $status"
        
        # Check container status
        foreach ($container in $pod.status.containerStatuses) {
            $ready = $container.ready
            $restarts = $container.restartCount
            
            if ($ready -and $restarts -eq 0) {
                Write-FireballSuccess "Container ready, no restarts"
            }
            elseif ($ready -and $restarts -gt 0) {
                Write-FireballWarning "Container ready but has $restarts restart(s)"
            }
            else {
                Write-FireballError "Container not ready"
            }
        }
        
        # Check recent events
        Write-Host "`nRecent Events:" -ForegroundColor Cyan
        kubectl get events -n $Namespace --field-selector involvedObject.name=$podName `
            --sort-by='.lastTimestamp' | Select-Object -Last 5
    }
    
    # Check service endpoints
    Write-Host "`n=== Service Endpoints ===" -ForegroundColor Cyan
    kubectl get endpoints -n $Namespace -l "app.kubernetes.io/name=telegraf"
    
    # Test metrics endpoint
    Write-Host "`n=== Testing Metrics Endpoint ===" -ForegroundColor Cyan
    $podName = kubectl get pods -n $Namespace -l "app.kubernetes.io/name=telegraf" `
        -o jsonpath='{.items[0].metadata.name}'
    
    if ($podName) {
        try {
            kubectl exec -n $Namespace $podName -- wget -q -O- http://localhost:8080/metrics | Select-Object -First 10
            Write-FireballSuccess "Metrics endpoint responding"
        }
        catch {
            Write-FireballError "Metrics endpoint not accessible"
        }
    }
}

# Validate configuration
function Test-TelegrafConfig {
    Write-FireballInfo "Validating Telegraf configuration..."
    
    $podName = kubectl get pods -n $Namespace -l "app.kubernetes.io/name=telegraf" `
        -o jsonpath='{.items[0].metadata.name}'
    
    if (-not $podName) {
        Write-FireballError "No running Telegraf pods found"
        return
    }
    
    Write-FireballInfo "Testing configuration syntax..."
    kubectl exec -n $Namespace $podName -- telegraf --test --config /etc/telegraf/telegraf.conf
    
    if ($LASTEXITCODE -eq 0) {
        Write-FireballSuccess "Configuration is valid!"
    }
    else {
        Write-FireballError "Configuration validation failed!"
    }
}

# Test metrics collection
function Test-MetricsCollection {
    Write-FireballInfo "Testing metrics collection..."
    
    $podName = kubectl get pods -n $Namespace -l "app.kubernetes.io/name=telegraf" `
        -o jsonpath='{.items[0].metadata.name}'
    
    if (-not $podName) {
        Write-FireballError "No running Telegraf pods found"
        return
    }
    
    Write-FireballInfo "Collecting test metrics (10 seconds)..."
    kubectl exec -n $Namespace $podName -- telegraf --test --config /etc/telegraf/telegraf.conf `
        --test-wait 10
    
    Write-FireballInfo "Checking Prometheus metrics endpoint..."
    kubectl exec -n $Namespace $podName -- wget -q -O- http://localhost:8080/metrics `
        | Select-Object -First 50
}

# Get logs
function Get-TelegrafLogs {
    Write-FireballInfo "Fetching Telegraf logs from $Namespace..."
    
    $pods = kubectl get pods -n $Namespace -l "app.kubernetes.io/name=telegraf" `
        -o jsonpath='{.items[*].metadata.name}'
    
    foreach ($pod in $pods -split ' ') {
        Write-Host "`n=== Logs from $pod ===" -ForegroundColor Cyan
        kubectl logs -n $Namespace $pod --tail=50
    }
}

# Backup configuration
function Backup-TelegrafConfig {
    Write-FireballInfo "Backing up Telegraf configuration..."
    
    if (-not (Test-Path $BackupPath)) {
        New-Item -Path $BackupPath -ItemType Directory | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupFile = Join-Path $BackupPath "telegraf-$Namespace-$timestamp.yaml"
    
    helm get values $ReleaseName -n $Namespace -o yaml | Out-File $backupFile
    
    Write-FireballSuccess "Configuration backed up to: $backupFile"
    
    # Also backup ConfigMap
    $configBackup = Join-Path $BackupPath "telegraf-configmap-$Namespace-$timestamp.yaml"
    kubectl get configmap -n $Namespace -l "app.kubernetes.io/name=telegraf" -o yaml `
        | Out-File $configBackup
    
    Write-FireballSuccess "ConfigMap backed up to: $configBackup"
}

# Get status
function Get-TelegrafStatus {
    Write-Host "`n=== Telegraf Status ===" -ForegroundColor Cyan
    
    helm list -n $Namespace | Where-Object { $_ -match $ReleaseName }
    
    Write-Host "`n=== Resource Usage ===" -ForegroundColor Cyan
    kubectl top pods -n $Namespace -l "app.kubernetes.io/name=telegraf" 2>$null
    
    if ($LASTEXITCODE -ne 0) {
        Write-FireballWarning "Metrics server not available for resource usage"
    }
}

# Performance tuning recommendations
function Get-TuningRecommendations {
    Write-FireballInfo "Analyzing Telegraf deployment for tuning opportunities..."
    
    $pods = kubectl get pods -n $Namespace -l "app.kubernetes.io/name=telegraf" -o json `
        | ConvertFrom-Json
    
    foreach ($pod in $pods.items) {
        $podName = $pod.metadata.name
        Write-Host "`nAnalyzing pod: $podName" -ForegroundColor Yellow
        
        # Check restart count
        $restarts = $pod.status.containerStatuses[0].restartCount
        if ($restarts -gt 3) {
            Write-FireballWarning "High restart count ($restarts) - check logs for OOMKilled or CrashLoopBackOff"
            Write-FireballInfo "Recommendation: Consider increasing resource limits"
        }
        
        # Check resource requests vs limits
        $requests = $pod.spec.containers[0].resources.requests
        $limits = $pod.spec.containers[0].resources.limits
        
        Write-Host "Current Resources:"
        Write-Host "  Requests: CPU=$($requests.cpu), Memory=$($requests.memory)"
        Write-Host "  Limits: CPU=$($limits.cpu), Memory=$($limits.memory)"
        
        # Try to get actual usage
        try {
            $usage = kubectl top pod $podName -n $Namespace --no-headers 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  Actual Usage: $usage"
            }
        }
        catch {}
    }
    
    Write-Host "`n=== General Recommendations ===" -ForegroundColor Cyan
    Write-Host "• For high-frequency metrics (< 10s): Use 'large' preset"
    Write-Host "• For standard monitoring (10-30s): Use 'medium' preset"
    Write-Host "• For low-frequency metrics (> 60s): Use 'small' preset"
    Write-Host "• DaemonSet mode: Best for per-node metrics"
    Write-Host "• Deployment mode: Best for centralized collection"
    Write-Host "• Enable persistent storage for buffering during output failures"
}

# Main execution
Write-FireballBanner

Test-Prerequisites

switch ($Action) {
    'deploy' { Deploy-Telegraf }
    'upgrade' { Upgrade-Telegraf }
    'delete' { Remove-Telegraf }
    'health-check' { Get-TelegrafHealth }
    'validate' { Test-TelegrafConfig }
    'test-metrics' { Test-MetricsCollection }
    'logs' { Get-TelegrafLogs }
    'backup' { Backup-TelegrafConfig }
    'status' { Get-TelegrafStatus }
    'tune' { Get-TuningRecommendations }
}

Write-Host "`n" -NoNewline
Write-FireballSuccess "Operation completed!"
Write-Host "`nFireball Industries - Professional Chaos Engineering since 2024" -ForegroundColor DarkGray
Write-Host "We Play With Fire So You Don't Have To™`n" -ForegroundColor DarkGray
