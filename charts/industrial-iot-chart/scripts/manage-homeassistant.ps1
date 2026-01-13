<#
.SYNOPSIS
    Home Assistant Helm Chart Management Script

.DESCRIPTION
    Comprehensive PowerShell script for managing Home Assistant deployments on Kubernetes.
    Fireball Industries - Patrick Ryan
    
    "Because clicking buttons in a UI is for people with too much time on their hands."

.PARAMETER Action
    Action to perform: deploy, upgrade, uninstall, status, logs, backup, restore, shell, test

.PARAMETER Namespace
    Kubernetes namespace (default: home-assistant)

.PARAMETER Release
    Helm release name (default: home-assistant)

.PARAMETER ValuesFile
    Path to values.yaml file

.EXAMPLE
    .\manage-homeassistant.ps1 -Action deploy
    .\manage-homeassistant.ps1 -Action logs -Follow
    .\manage-homeassistant.ps1 -Action backup

.NOTES
    Author: Patrick Ryan / Fireball Industries
    Version: 1.0.0
    Humor Level: Dark Millennial
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('deploy', 'upgrade', 'uninstall', 'status', 'logs', 'backup', 'restore', 'shell', 'test', 'devices')]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$Namespace = "home-assistant",
    
    [Parameter(Mandatory=$false)]
    [string]$Release = "home-assistant",
    
    [Parameter(Mandatory=$false)]
    [string]$ValuesFile = "values.yaml",
    
    [Parameter(Mandatory=$false)]
    [switch]$Follow,
    
    [Parameter(Mandatory=$false)]
    [string]$BackupPath,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

# ============================================================================
# CONFIGURATION
# ============================================================================
$ChartPath = Split-Path -Parent $PSScriptRoot
$ErrorActionPreference = "Stop"

# ASCII Art Banner (because we're professionals)
$Banner = @"
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║     🏠 HOME ASSISTANT - KUBERNETES MANAGEMENT                        ║
║                                                                      ║
║     Fireball Industries - Patrick Ryan                              ║
║     "Automating your smart home automation. Meta, right?"           ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
"@

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "✅ $Message" "Green"
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "❌ $Message" "Red"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "⚠️  $Message" "Yellow"
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "ℹ️  $Message" "Cyan"
}

function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    $missing = @()
    
    if (-not (Test-Command "kubectl")) {
        $missing += "kubectl"
    }
    
    if (-not (Test-Command "helm")) {
        $missing += "helm"
    }
    
    if ($missing.Count -gt 0) {
        Write-Error "Missing required tools: $($missing -join ', ')"
        Write-Info "Please install missing tools and try again."
        exit 1
    }
    
    Write-Success "Prerequisites check passed"
}

function Get-PodName {
    $podName = kubectl get pods -n $Namespace -l "app.kubernetes.io/name=home-assistant,app.kubernetes.io/instance=$Release" -o jsonpath="{.items[0].metadata.name}" 2>$null
    return $podName
}

# ============================================================================
# ACTION FUNCTIONS
# ============================================================================

function Invoke-Deploy {
    Write-Info "Deploying Home Assistant..."
    
    if (-not (Test-Path $ValuesFile)) {
        Write-Error "Values file not found: $ValuesFile"
        exit 1
    }
    
    # Create namespace if it doesn't exist
    kubectl create namespace $Namespace --dry-run=client -o yaml | kubectl apply -f - | Out-Null
    Write-Success "Namespace '$Namespace' ready"
    
    # Deploy with Helm
    $helmArgs = @(
        "install", $Release, $ChartPath,
        "--namespace", $Namespace,
        "--values", $ValuesFile
    )
    
    if ($DryRun) {
        $helmArgs += "--dry-run"
        Write-Warning "DRY RUN MODE - No changes will be applied"
    }
    
    Write-Info "Executing: helm $($helmArgs -join ' ')"
    & helm @helmArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Home Assistant deployed successfully!"
        Write-Info ""
        Write-Info "Next steps:"
        Write-Info "1. Wait for pod to be ready: kubectl get pods -n $Namespace -w"
        Write-Info "2. Access Home Assistant: kubectl port-forward -n $Namespace svc/$Release 8123:8123"
        Write-Info "3. Open http://localhost:8123 and complete onboarding"
    } else {
        Write-Error "Deployment failed!"
        exit 1
    }
}

function Invoke-Upgrade {
    Write-Info "Upgrading Home Assistant..."
    
    if (-not (Test-Path $ValuesFile)) {
        Write-Error "Values file not found: $ValuesFile"
        exit 1
    }
    
    $helmArgs = @(
        "upgrade", $Release, $ChartPath,
        "--namespace", $Namespace,
        "--values", $ValuesFile
    )
    
    if ($DryRun) {
        $helmArgs += "--dry-run"
        Write-Warning "DRY RUN MODE - No changes will be applied"
    }
    
    Write-Info "Executing: helm $($helmArgs -join ' ')"
    & helm @helmArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Home Assistant upgraded successfully!"
        Write-Info "Checking rollout status..."
        kubectl rollout status statefulset/$Release -n $Namespace
    } else {
        Write-Error "Upgrade failed!"
        exit 1
    }
}

function Invoke-Uninstall {
    Write-Warning "This will uninstall Home Assistant from namespace '$Namespace'"
    Write-Warning "PersistentVolumeClaims will be retained (your data is safe)"
    
    $confirmation = Read-Host "Are you sure? (yes/no)"
    if ($confirmation -ne "yes") {
        Write-Info "Uninstall cancelled"
        return
    }
    
    Write-Info "Uninstalling Home Assistant..."
    helm uninstall $Release --namespace $Namespace
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Home Assistant uninstalled"
        Write-Info ""
        Write-Info "To completely remove all data (WARNING: DESTRUCTIVE):"
        Write-Warning "kubectl delete pvc -n $Namespace -l app.kubernetes.io/instance=$Release"
    }
}

function Invoke-Status {
    Write-Info "Home Assistant Status"
    Write-Info "===================="
    
    # Helm release status
    Write-Info "`nHelm Release:"
    helm status $Release --namespace $Namespace
    
    # Pod status
    Write-Info "`nPods:"
    kubectl get pods -n $Namespace -l "app.kubernetes.io/instance=$Release"
    
    # Service status
    Write-Info "`nServices:"
    kubectl get svc -n $Namespace -l "app.kubernetes.io/instance=$Release"
    
    # PVC status
    Write-Info "`nPersistent Volume Claims:"
    kubectl get pvc -n $Namespace -l "app.kubernetes.io/instance=$Release"
    
    # Resource usage (if metrics-server is available)
    Write-Info "`nResource Usage:"
    kubectl top pods -n $Namespace -l "app.kubernetes.io/instance=$Release" 2>$null
}

function Invoke-Logs {
    $podName = Get-PodName
    
    if (-not $podName) {
        Write-Error "No Home Assistant pod found in namespace '$Namespace'"
        exit 1
    }
    
    Write-Info "Showing logs for pod: $podName"
    
    $kubectlArgs = @("logs", "-n", $Namespace, $podName, "-c", "home-assistant")
    
    if ($Follow) {
        $kubectlArgs += "-f"
        Write-Info "Following logs (Ctrl+C to stop)..."
    }
    
    & kubectl @kubectlArgs
}

function Invoke-Backup {
    $podName = Get-PodName
    
    if (-not $podName) {
        Write-Error "No Home Assistant pod found in namespace '$Namespace'"
        exit 1
    }
    
    if (-not $BackupPath) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $BackupPath = ".\homeassistant-backup-$timestamp.tar.gz"
    }
    
    Write-Info "Creating backup of Home Assistant configuration..."
    Write-Info "Pod: $podName"
    Write-Info "Backup path: $BackupPath"
    
    # Create tar backup inside pod
    kubectl exec -n $Namespace $podName -- tar czf /tmp/ha-backup.tar.gz /config
    
    # Copy backup to local machine
    kubectl cp "${Namespace}/${podName}:/tmp/ha-backup.tar.gz" $BackupPath
    
    # Clean up temp file
    kubectl exec -n $Namespace $podName -- rm /tmp/ha-backup.tar.gz
    
    if (Test-Path $BackupPath) {
        $size = (Get-Item $BackupPath).Length / 1MB
        Write-Success "Backup created successfully!"
        Write-Info "File: $BackupPath"
        Write-Info "Size: $([math]::Round($size, 2)) MB"
    } else {
        Write-Error "Backup failed!"
    }
}

function Invoke-Restore {
    if (-not $BackupPath -or -not (Test-Path $BackupPath)) {
        Write-Error "Backup file not found: $BackupPath"
        Write-Info "Usage: .\manage-homeassistant.ps1 -Action restore -BackupPath <path-to-backup.tar.gz>"
        exit 1
    }
    
    $podName = Get-PodName
    
    if (-not $podName) {
        Write-Error "No Home Assistant pod found in namespace '$Namespace'"
        exit 1
    }
    
    Write-Warning "This will restore Home Assistant configuration from backup"
    Write-Warning "Current configuration will be overwritten!"
    
    $confirmation = Read-Host "Are you sure? (yes/no)"
    if ($confirmation -ne "yes") {
        Write-Info "Restore cancelled"
        return
    }
    
    Write-Info "Restoring from backup: $BackupPath"
    
    # Copy backup to pod
    kubectl cp $BackupPath "${Namespace}/${podName}:/tmp/ha-backup.tar.gz"
    
    # Extract backup
    kubectl exec -n $Namespace $podName -- tar xzf /tmp/ha-backup.tar.gz -C /
    
    # Clean up
    kubectl exec -n $Namespace $podName -- rm /tmp/ha-backup.tar.gz
    
    Write-Success "Restore completed!"
    Write-Info "Restarting Home Assistant pod..."
    kubectl delete pod $podName -n $Namespace
    
    Write-Info "Waiting for pod to restart..."
    kubectl wait --for=condition=ready pod -l "app.kubernetes.io/instance=$Release" -n $Namespace --timeout=300s
    
    Write-Success "Home Assistant restarted successfully!"
}

function Invoke-Shell {
    $podName = Get-PodName
    
    if (-not $podName) {
        Write-Error "No Home Assistant pod found in namespace '$Namespace'"
        exit 1
    }
    
    Write-Info "Opening shell in pod: $podName"
    Write-Info "Type 'exit' to close the shell"
    
    kubectl exec -it -n $Namespace $podName -c home-assistant -- /bin/bash
}

function Invoke-Test {
    Write-Info "Running Home Assistant health checks..."
    
    # Run test script
    $testScript = Join-Path (Split-Path $PSScriptRoot) "scripts\test-homeassistant.ps1"
    
    if (Test-Path $testScript) {
        & $testScript -Namespace $Namespace -Release $Release
    } else {
        Write-Warning "Test script not found: $testScript"
        Write-Info "Performing basic health check..."
        
        $podName = Get-PodName
        if ($podName) {
            Write-Success "Pod is running: $podName"
            
            # Check pod status
            $podStatus = kubectl get pod $podName -n $Namespace -o jsonpath='{.status.phase}'
            Write-Info "Pod status: $podStatus"
            
            # Check if Home Assistant is responsive
            Write-Info "Testing HTTP endpoint..."
            kubectl exec -n $Namespace $podName -- curl -s -o /dev/null -w "%{http_code}" http://localhost:8123/ | Out-Null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Home Assistant is responding to HTTP requests"
            } else {
                Write-Warning "Home Assistant may not be fully started yet"
            }
        } else {
            Write-Error "No pod found"
        }
    }
}

function Invoke-Devices {
    Write-Info "Detecting USB devices on cluster nodes..."
    
    # Run device discovery script
    $deviceScript = Join-Path (Split-Path $PSScriptRoot) "scripts\device-discovery.ps1"
    
    if (Test-Path $deviceScript) {
        & $deviceScript
    } else {
        Write-Warning "Device discovery script not found: $deviceScript"
        Write-Info "Manually check USB devices on nodes:"
        Write-Info "kubectl get nodes -o wide"
        Write-Info "Then SSH to node and run: ls -la /dev/tty*"
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

Write-Host $Banner -ForegroundColor Cyan
Write-Host ""

Test-Prerequisites

switch ($Action) {
    "deploy"     { Invoke-Deploy }
    "upgrade"    { Invoke-Upgrade }
    "uninstall"  { Invoke-Uninstall }
    "status"     { Invoke-Status }
    "logs"       { Invoke-Logs }
    "backup"     { Invoke-Backup }
    "restore"    { Invoke-Restore }
    "shell"      { Invoke-Shell }
    "test"       { Invoke-Test }
    "devices"    { Invoke-Devices }
}

Write-Host ""
Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "DarkGray"
Write-ColorOutput "Built with ☕ by Fireball Industries - Patrick Ryan" "DarkGray"
Write-Host ""
