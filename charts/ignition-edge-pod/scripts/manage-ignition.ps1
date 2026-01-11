<#
.SYNOPSIS
    Ignition Edge Management Script for Kubernetes
    
.DESCRIPTION
    Because clicking through kubectl commands is peak inefficiency.
    This script manages your Ignition Edge deployment with style and sarcasm.
    
    Patrick Ryan - Fireball Industries
    "Your operators deserve better than Windows XP"

.PARAMETER Action
    Action to perform: deploy, upgrade, delete, backup, restore, health-check, 
    activate-license, restart-demo, import-project, export-project, 
    install-module, logs, designer-launch

.PARAMETER ReleaseName
    Helm release name (default: ignition-edge)

.PARAMETER Namespace
    Kubernetes namespace (default: industrial)

.PARAMETER ValuesFile
    Path to values.yaml file for deployment

.PARAMETER ActivationKey
    Ignition license activation key

.PARAMETER ProjectFile
    Path to Ignition project file (.proj)

.PARAMETER ModuleFile
    Path to Ignition module file (.modl)

.PARAMETER BackupFile
    Path to backup file (.gwbk)

.EXAMPLE
    .\manage-ignition.ps1 -Action deploy
    
.EXAMPLE
    .\manage-ignition.ps1 -Action health-check -ReleaseName my-ignition

.EXAMPLE
    .\manage-ignition.ps1 -Action activate-license -ActivationKey "YOUR-KEY-HERE"

.EXAMPLE
    .\manage-ignition.ps1 -Action backup -BackupFile "C:\backups\gateway.gwbk"
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('deploy', 'upgrade', 'delete', 'backup', 'restore', 'health-check', 
                 'activate-license', 'restart-demo', 'import-project', 'export-project',
                 'install-module', 'logs', 'designer-launch')]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$ReleaseName = "ignition-edge",
    
    [Parameter(Mandatory=$false)]
    [string]$Namespace = "industrial",
    
    [Parameter(Mandatory=$false)]
    [string]$ValuesFile = "values.yaml",
    
    [Parameter(Mandatory=$false)]
    [string]$ActivationKey,
    
    [Parameter(Mandatory=$false)]
    [string]$ProjectFile,
    
    [Parameter(Mandatory=$false)]
    [string]$ModuleFile,
    
    [Parameter(Mandatory=$false)]
    [string]$BackupFile
)

# ============================================================================
# Color Output Functions
# Because monochrome terminals are so 1980
# ============================================================================

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Blue
}

function Write-Snark {
    param([string]$Message)
    Write-Host "💬 $Message" -ForegroundColor Magenta
}

# ============================================================================
# Prerequisite Checks
# ============================================================================

function Test-Prerequisites {
    Write-Header "Checking Prerequisites"
    
    $allGood = $true
    
    # Check kubectl
    if (Get-Command kubectl -ErrorAction SilentlyContinue) {
        $kubectlVersion = (kubectl version --client --short 2>$null) -replace 'Client Version: v', ''
        Write-Success "kubectl installed: v$kubectlVersion"
    } else {
        Write-Error "kubectl not found. Install it or forever be stuck in GUI hell."
        $allGood = $false
    }
    
    # Check helm
    if (Get-Command helm -ErrorAction SilentlyContinue) {
        $helmVersion = (helm version --short 2>$null) -replace 'v', '' -replace '\+.*', ''
        Write-Success "Helm installed: v$helmVersion"
    } else {
        Write-Error "Helm not found. Seriously, how did you even get this far?"
        $allGood = $false
    }
    
    # Check cluster connectivity
    try {
        $null = kubectl cluster-info 2>&1
        Write-Success "Kubernetes cluster accessible"
    } catch {
        Write-Error "Cannot connect to Kubernetes cluster. Check your kubeconfig."
        $allGood = $false
    }
    
    if (-not $allGood) {
        Write-Snark "Fix the errors above before continuing. I'll wait."
        exit 1
    }
    
    Write-Success "All prerequisites met. Let's rock and roll."
}

# ============================================================================
# Deployment Functions
# ============================================================================

function Deploy-Ignition {
    Write-Header "Deploying Ignition Edge"
    Write-Snark "Because your operators deserve better than Windows XP"
    
    # Create namespace if it doesn't exist
    $nsExists = kubectl get namespace $Namespace 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Info "Creating namespace: $Namespace"
        kubectl create namespace $Namespace
    }
    
    # Deploy with Helm
    Write-Info "Deploying Helm chart..."
    helm install $ReleaseName . `
        --namespace $Namespace `
        --values $ValuesFile `
        --create-namespace `
        --wait `
        --timeout 10m
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Deployment successful!"
        Write-Info "Release: $ReleaseName"
        Write-Info "Namespace: $Namespace"
        
        # Wait for pod to be ready
        Write-Info "Waiting for gateway to be ready..."
        kubectl wait --for=condition=ready pod `
            -l "app.kubernetes.io/name=ignition-edge,app.kubernetes.io/instance=$ReleaseName" `
            -n $Namespace `
            --timeout=300s
        
        Write-Success "Gateway is ready!"
        
        # Show access information
        Show-AccessInfo
        
        # Open web UI
        Open-WebUI
    } else {
        Write-Error "Deployment failed. Check the logs above."
        exit 1
    }
}

function Upgrade-Ignition {
    Write-Header "Upgrading Ignition Edge"
    
    helm upgrade $ReleaseName . `
        --namespace $Namespace `
        --values $ValuesFile `
        --wait `
        --timeout 10m
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Upgrade successful!"
    } else {
        Write-Error "Upgrade failed."
        exit 1
    }
}

function Remove-Ignition {
    Write-Header "Removing Ignition Edge"
    Write-Warning "This will DELETE your deployment. Are you sure? (yes/no)"
    
    $confirmation = Read-Host
    if ($confirmation -ne "yes") {
        Write-Info "Cancelled. Your gateway lives to see another day."
        return
    }
    
    Write-Snark "Deleting deployment. Hope you have backups..."
    
    helm uninstall $ReleaseName --namespace $Namespace
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Deployment removed"
        Write-Warning "PVCs are retained. Delete manually if needed:"
        Write-Host "  kubectl delete pvc -n $Namespace -l app.kubernetes.io/instance=$ReleaseName"
    } else {
        Write-Error "Uninstall failed"
        exit 1
    }
}

# ============================================================================
# Backup and Restore
# ============================================================================

function Backup-Gateway {
    Write-Header "Creating Gateway Backup"
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupFileName = "ignition-backup-$timestamp.gwbk"
    
    if (-not $BackupFile) {
        $BackupFile = Join-Path $PWD $backupFileName
    }
    
    Write-Info "Creating backup: $backupFileName"
    
    # Trigger backup job
    kubectl create job --from=cronjob/$ReleaseName-backup manual-backup-$timestamp `
        -n $Namespace
    
    # Wait for job to complete
    Write-Info "Waiting for backup to complete..."
    kubectl wait --for=condition=complete job/manual-backup-$timestamp `
        -n $Namespace `
        --timeout=300s
    
    if ($LASTEXITCODE -eq 0) {
        # Copy backup file from pod
        $podName = kubectl get pods -n $Namespace `
            -l "app.kubernetes.io/name=ignition-edge,app.kubernetes.io/instance=$ReleaseName" `
            -o jsonpath='{.items[0].metadata.name}'
        
        Write-Info "Downloading backup file..."
        kubectl cp "$Namespace/${podName}:/backups/$backupFileName" $BackupFile
        
        Write-Success "Backup completed: $BackupFile"
        Write-Snark "Your config is safe. Sleep well tonight."
    } else {
        Write-Error "Backup failed"
        exit 1
    }
}

function Restore-Gateway {
    Write-Header "Restoring Gateway from Backup"
    
    if (-not (Test-Path $BackupFile)) {
        Write-Error "Backup file not found: $BackupFile"
        exit 1
    }
    
    Write-Warning "This will OVERWRITE current gateway configuration!"
    Write-Warning "Continue? (yes/no)"
    
    $confirmation = Read-Host
    if ($confirmation -ne "yes") {
        Write-Info "Cancelled"
        return
    }
    
    $podName = kubectl get pods -n $Namespace `
        -l "app.kubernetes.io/name=ignition-edge,app.kubernetes.io/instance=$ReleaseName" `
        -o jsonpath='{.items[0].metadata.name}'
    
    # Upload backup file
    Write-Info "Uploading backup file to pod..."
    kubectl cp $BackupFile "$Namespace/${podName}:/restore/gateway.gwbk"
    
    # Execute restore
    Write-Info "Executing restore..."
    kubectl exec -n $Namespace $podName -- /bin/bash -c `
        "/usr/local/bin/ignition/gwcmd.sh --restore --file /restore/gateway.gwbk"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Restore completed"
        Write-Info "Restarting gateway..."
        kubectl rollout restart deployment/$ReleaseName -n $Namespace
        Write-Success "Gateway restarted"
    } else {
        Write-Error "Restore failed"
        exit 1
    }
}

# ============================================================================
# License Management
# ============================================================================

function Activate-License {
    Write-Header "Activating Ignition License"
    
    if (-not $ActivationKey) {
        Write-Error "Activation key required. Use -ActivationKey parameter"
        exit 1
    }
    
    Write-Info "Creating license secret..."
    
    kubectl create secret generic $ReleaseName-license `
        --from-literal=activation-key=$ActivationKey `
        -n $Namespace `
        --dry-run=client -o yaml | kubectl apply -f -
    
    Write-Info "Upgrading release with license..."
    helm upgrade $ReleaseName . `
        --namespace $Namespace `
        --set license.existingSecret=$ReleaseName-license `
        --set global.demoMode=false `
        --reuse-values `
        --wait
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "License activated successfully!"
        Write-Snark "Welcome to the big leagues. No more 2-hour restarts."
    } else {
        Write-Error "License activation failed"
        exit 1
    }
}

function Restart-DemoMode {
    Write-Header "Restarting Demo Mode Session"
    Write-Snark "Because you're living on the edge (literally)"
    
    kubectl rollout restart deployment/$ReleaseName -n $Namespace
    
    Write-Success "Gateway restarted - you've got another 2 hours"
    Write-Warning "Seriously though, activate your license for production"
}

# ============================================================================
# Health Check
# ============================================================================

function Test-GatewayHealth {
    Write-Header "Ignition Gateway Health Check"
    
    $podName = kubectl get pods -n $Namespace `
        -l "app.kubernetes.io/name=ignition-edge,app.kubernetes.io/instance=$ReleaseName" `
        -o jsonpath='{.items[0].metadata.name}'
    
    if (-not $podName) {
        Write-Error "No gateway pod found"
        exit 1
    }
    
    # Pod status
    $podStatus = kubectl get pod $podName -n $Namespace -o jsonpath='{.status.phase}'
    if ($podStatus -eq "Running") {
        Write-Success "Pod Status: $podStatus"
    } else {
        Write-Error "Pod Status: $podStatus"
    }
    
    # Check HTTP endpoint
    Write-Info "Testing HTTP connectivity..."
    $portForward = Start-Process kubectl -ArgumentList "port-forward -n $Namespace svc/$ReleaseName 8088:8088" `
        -PassThru -WindowStyle Hidden
    
    Start-Sleep -Seconds 3
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8088/StatusPing" -TimeoutSec 5 -UseBasicParsing
        Write-Success "HTTP Status: $($response.StatusCode)"
    } catch {
        Write-Error "HTTP connectivity failed"
    } finally {
        Stop-Process -Id $portForward.Id -Force
    }
    
    # Resource usage
    Write-Info "Resource Usage:"
    kubectl top pod $podName -n $Namespace
    
    # Recent logs
    Write-Info "Recent Logs (last 10 lines):"
    kubectl logs $podName -n $Namespace --tail=10
    
    Write-Success "Health check complete"
}

# ============================================================================
# Utility Functions
# ============================================================================

function Show-AccessInfo {
    Write-Header "Gateway Access Information"
    
    $svcName = kubectl get svc -n $Namespace `
        -l "app.kubernetes.io/name=ignition-edge,app.kubernetes.io/instance=$ReleaseName" `
        -o jsonpath='{.items[0].metadata.name}'
    
    Write-Info "Service Name: $svcName"
    Write-Info "Namespace: $Namespace"
    Write-Host ""
    Write-Info "To access the gateway, run:"
    Write-Host "  kubectl port-forward -n $Namespace svc/$svcName 8088:8088" -ForegroundColor Yellow
    Write-Host "  Then open: http://localhost:8088" -ForegroundColor Yellow
    Write-Host ""
    
    # Get admin password
    $password = kubectl get secret $ReleaseName-secret -n $Namespace `
        -o jsonpath='{.data.admin-password}' | ForEach-Object { 
            [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_))
        }
    
    Write-Info "Admin Credentials:"
    Write-Host "  Username: admin" -ForegroundColor Yellow
    Write-Host "  Password: $password" -ForegroundColor Yellow
}

function Open-WebUI {
    Write-Info "Opening web UI in browser..."
    
    # Start port-forward in background
    $portForward = Start-Process kubectl `
        -ArgumentList "port-forward -n $Namespace svc/$ReleaseName 8088:8088" `
        -PassThru -WindowStyle Hidden
    
    Start-Sleep -Seconds 3
    
    # Open browser
    Start-Process "http://localhost:8088"
    
    Write-Success "Web UI opened in browser"
    Write-Warning "Port-forward process ID: $($portForward.Id)"
    Write-Info "To stop port-forward: Stop-Process -Id $($portForward.Id)"
}

function Show-Logs {
    Write-Header "Gateway Logs"
    
    $podName = kubectl get pods -n $Namespace `
        -l "app.kubernetes.io/name=ignition-edge,app.kubernetes.io/instance=$ReleaseName" `
        -o jsonpath='{.items[0].metadata.name}'
    
    Write-Info "Following logs (Ctrl+C to exit)..."
    kubectl logs -f $podName -n $Namespace
}

# ============================================================================
# Main Execution
# ============================================================================

Test-Prerequisites

switch ($Action) {
    'deploy' { Deploy-Ignition }
    'upgrade' { Upgrade-Ignition }
    'delete' { Remove-Ignition }
    'backup' { Backup-Gateway }
    'restore' { Restore-Gateway }
    'health-check' { Test-GatewayHealth }
    'activate-license' { Activate-License }
    'restart-demo' { Restart-DemoMode }
    'logs' { Show-Logs }
    'designer-launch' { Open-WebUI }
    default {
        Write-Error "Unknown action: $Action"
        exit 1
    }
}

Write-Host ""
Write-Snark "Mission accomplished. Go build something awesome."
Write-Host ""
