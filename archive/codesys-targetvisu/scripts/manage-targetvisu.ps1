<#
.SYNOPSIS
    CODESYS TargetVisu Management Script
    
.DESCRIPTION
    Comprehensive management script for CODESYS TargetVisu Helm deployments.
    Provides deployment, upgrade, backup, restart, and shell access functionality.
    
.PARAMETER Action
    Action to perform: deploy, upgrade, restart, delete, backup, restore, shell, logs, status
    
.PARAMETER ReleaseName
    Helm release name (default: codesys-targetvisu)
    
.PARAMETER Namespace
    Kubernetes namespace (default: industrial)
    
.PARAMETER ValuesFile
    Path to values.yaml file
    
.PARAMETER BackupPath
    Path for backup/restore operations
    
.EXAMPLE
    .\manage-targetvisu.ps1 -Action deploy -ValuesFile .\examples\standard-factory.yaml
    
.EXAMPLE
    .\manage-targetvisu.ps1 -Action restart -ReleaseName my-hmi
    
.EXAMPLE
    .\manage-targetvisu.ps1 -Action backup -BackupPath C:\backups\hmi
    
.NOTES
    Author: Patrick Ryan / Fireball Industries
    Because managing factory automation should be as easy as restarting your HMI
    (which you'll do approximately 47 times per shift)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('deploy', 'upgrade', 'restart', 'delete', 'backup', 'restore', 'shell', 'logs', 'status', 'help')]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$ReleaseName = "codesys-targetvisu",
    
    [Parameter(Mandatory=$false)]
    [string]$Namespace = "industrial",
    
    [Parameter(Mandatory=$false)]
    [string]$ValuesFile,
    
    [Parameter(Mandatory=$false)]
    [string]$BackupPath
)

# ========================================
# Configuration
# ========================================

$ChartPath = "."
$DefaultTimeout = "10m"

# ========================================
# Helper Functions
# ========================================

function Write-Banner {
    param([string]$Text)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Blue
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    # Check kubectl
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        Write-Error "kubectl not found. Please install kubectl."
        exit 1
    }
    
    # Check helm
    if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
        Write-Error "helm not found. Please install Helm 3."
        exit 1
    }
    
    # Check cluster connectivity
    try {
        kubectl cluster-info | Out-Null
        Write-Success "Connected to Kubernetes cluster"
    } catch {
        Write-Error "Cannot connect to Kubernetes cluster. Check your kubeconfig."
        exit 1
    }
    
    # Check namespace
    $namespaceExists = kubectl get namespace $Namespace 2>&1 | Select-String -Pattern $Namespace
    if (-not $namespaceExists) {
        Write-Warning "Namespace '$Namespace' does not exist. Creating..."
        kubectl create namespace $Namespace
        Write-Success "Namespace '$Namespace' created"
    }
}

# ========================================
# Action Functions
# ========================================

function Invoke-Deploy {
    Write-Banner "Deploying CODESYS TargetVisu"
    
    Test-Prerequisites
    
    # Check if release already exists
    $releaseExists = helm list -n $Namespace | Select-String -Pattern $ReleaseName
    if ($releaseExists) {
        Write-Warning "Release '$ReleaseName' already exists in namespace '$Namespace'"
        $response = Read-Host "Do you want to upgrade instead? (y/n)"
        if ($response -eq 'y') {
            Invoke-Upgrade
            return
        } else {
            Write-Error "Deployment cancelled"
            return
        }
    }
    
    # Build helm install command
    $helmCmd = @(
        "install"
        $ReleaseName
        $ChartPath
        "--namespace"
        $Namespace
        "--create-namespace"
        "--timeout"
        $DefaultTimeout
    )
    
    if ($ValuesFile) {
        if (Test-Path $ValuesFile) {
            $helmCmd += "--values"
            $helmCmd += $ValuesFile
            Write-Info "Using values file: $ValuesFile"
        } else {
            Write-Error "Values file not found: $ValuesFile"
            return
        }
    }
    
    Write-Info "Deploying CODESYS TargetVisu..."
    Write-Info "Release: $ReleaseName"
    Write-Info "Namespace: $Namespace"
    Write-Host ""
    
    # Execute helm install
    & helm @helmCmd
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Deployment successful!"
        Write-Host ""
        Write-Info "To access your HMI, run:"
        Write-Host "  kubectl get svc -n $Namespace $ReleaseName" -ForegroundColor Yellow
        Write-Host ""
        Write-Info "To view logs, run:"
        Write-Host "  .\manage-targetvisu.ps1 -Action logs -ReleaseName $ReleaseName -Namespace $Namespace" -ForegroundColor Yellow
    } else {
        Write-Error "Deployment failed!"
    }
}

function Invoke-Upgrade {
    Write-Banner "Upgrading CODESYS TargetVisu"
    
    Test-Prerequisites
    
    # Check if release exists
    $releaseExists = helm list -n $Namespace | Select-String -Pattern $ReleaseName
    if (-not $releaseExists) {
        Write-Error "Release '$ReleaseName' not found in namespace '$Namespace'"
        Write-Info "Use -Action deploy to create a new deployment"
        return
    }
    
    # Build helm upgrade command
    $helmCmd = @(
        "upgrade"
        $ReleaseName
        $ChartPath
        "--namespace"
        $Namespace
        "--timeout"
        $DefaultTimeout
    )
    
    if ($ValuesFile) {
        if (Test-Path $ValuesFile) {
            $helmCmd += "--values"
            $helmCmd += $ValuesFile
            Write-Info "Using values file: $ValuesFile"
        } else {
            Write-Error "Values file not found: $ValuesFile"
            return
        }
    }
    
    Write-Info "Upgrading CODESYS TargetVisu..."
    Write-Host ""
    
    # Execute helm upgrade
    & helm @helmCmd
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Upgrade successful!"
        Write-Host ""
        Write-Info "To check rollout status:"
        Write-Host "  kubectl rollout status deployment/$ReleaseName -n $Namespace" -ForegroundColor Yellow
    } else {
        Write-Error "Upgrade failed!"
        Write-Warning "To rollback, run:"
        Write-Host "  helm rollback $ReleaseName -n $Namespace" -ForegroundColor Yellow
    }
}

function Invoke-Restart {
    Write-Banner "Restarting CODESYS TargetVisu"
    
    Test-Prerequisites
    
    Write-Info "Restarting deployment..."
    kubectl rollout restart deployment/$ReleaseName -n $Namespace
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Restart initiated"
        Write-Info "Waiting for rollout to complete..."
        kubectl rollout status deployment/$ReleaseName -n $Namespace --timeout=5m
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Restart completed successfully!"
        } else {
            Write-Error "Restart timed out or failed"
        }
    } else {
        Write-Error "Failed to restart deployment"
    }
}

function Invoke-Delete {
    Write-Banner "Deleting CODESYS TargetVisu"
    
    Write-Warning "This will delete the release '$ReleaseName' from namespace '$Namespace'"
    Write-Warning "Persistent volumes will be retained (manual deletion required)"
    $response = Read-Host "Are you sure? (yes/no)"
    
    if ($response -ne 'yes') {
        Write-Info "Deletion cancelled"
        return
    }
    
    Test-Prerequisites
    
    Write-Info "Uninstalling Helm release..."
    helm uninstall $ReleaseName -n $Namespace
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Release uninstalled"
        
        Write-Warning "Persistent Volume Claims still exist. To delete:"
        Write-Host "  kubectl delete pvc -n $Namespace -l app.kubernetes.io/instance=$ReleaseName" -ForegroundColor Yellow
        
        $deletePvc = Read-Host "Delete PVCs now? (yes/no)"
        if ($deletePvc -eq 'yes') {
            kubectl delete pvc -n $Namespace -l app.kubernetes.io/instance=$ReleaseName
            Write-Success "PVCs deleted"
        }
    } else {
        Write-Error "Failed to uninstall release"
    }
}

function Invoke-Backup {
    Write-Banner "Backing Up CODESYS TargetVisu"
    
    if (-not $BackupPath) {
        $BackupPath = ".\backups\$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')"
    }
    
    New-Item -ItemType Directory -Force -Path $BackupPath | Out-Null
    Write-Info "Backup location: $BackupPath"
    
    Test-Prerequisites
    
    # Get pod name
    $podName = kubectl get pods -n $Namespace -l app.kubernetes.io/instance=$ReleaseName -o jsonpath='{.items[0].metadata.name}'
    
    if (-not $podName) {
        Write-Error "No pods found for release '$ReleaseName'"
        return
    }
    
    Write-Info "Backing up from pod: $podName"
    
    # Backup Helm values
    Write-Info "Backing up Helm values..."
    helm get values $ReleaseName -n $Namespace > "$BackupPath\values.yaml"
    
    # Backup configuration
    Write-Info "Backing up CODESYS configuration..."
    kubectl exec -n $Namespace $podName -- tar czf /tmp/config-backup.tar.gz -C /var/opt/codesys .
    kubectl cp "${Namespace}/${podName}:/tmp/config-backup.tar.gz" "$BackupPath\config-backup.tar.gz"
    kubectl exec -n $Namespace $podName -- rm /tmp/config-backup.tar.gz
    
    # Backup projects
    Write-Info "Backing up projects..."
    kubectl exec -n $Namespace $podName -- tar czf /tmp/projects-backup.tar.gz -C /projects .
    kubectl cp "${Namespace}/${podName}:/tmp/projects-backup.tar.gz" "$BackupPath\projects-backup.tar.gz"
    kubectl exec -n $Namespace $podName -- rm /tmp/projects-backup.tar.gz
    
    # Backup logs
    Write-Info "Backing up logs..."
    kubectl logs -n $Namespace $podName > "$BackupPath\runtime.log"
    
    Write-Success "Backup completed: $BackupPath"
    Write-Info "Backup contents:"
    Get-ChildItem $BackupPath | Format-Table Name, Length, LastWriteTime
}

function Invoke-Restore {
    Write-Banner "Restoring CODESYS TargetVisu"
    
    if (-not $BackupPath) {
        Write-Error "Please specify -BackupPath"
        return
    }
    
    if (-not (Test-Path $BackupPath)) {
        Write-Error "Backup path not found: $BackupPath"
        return
    }
    
    Test-Prerequisites
    
    # Get pod name
    $podName = kubectl get pods -n $Namespace -l app.kubernetes.io/instance=$ReleaseName -o jsonpath='{.items[0].metadata.name}'
    
    if (-not $podName) {
        Write-Error "No pods found for release '$ReleaseName'"
        return
    }
    
    Write-Warning "This will restore configuration and projects from: $BackupPath"
    Write-Warning "Current data will be overwritten!"
    $response = Read-Host "Continue? (yes/no)"
    
    if ($response -ne 'yes') {
        Write-Info "Restore cancelled"
        return
    }
    
    # Restore configuration
    if (Test-Path "$BackupPath\config-backup.tar.gz") {
        Write-Info "Restoring configuration..."
        kubectl cp "$BackupPath\config-backup.tar.gz" "${Namespace}/${podName}:/tmp/config-backup.tar.gz"
        kubectl exec -n $Namespace $podName -- tar xzf /tmp/config-backup.tar.gz -C /var/opt/codesys
        kubectl exec -n $Namespace $podName -- rm /tmp/config-backup.tar.gz
        Write-Success "Configuration restored"
    }
    
    # Restore projects
    if (Test-Path "$BackupPath\projects-backup.tar.gz") {
        Write-Info "Restoring projects..."
        kubectl cp "$BackupPath\projects-backup.tar.gz" "${Namespace}/${podName}:/tmp/projects-backup.tar.gz"
        kubectl exec -n $Namespace $podName -- tar xzf /tmp/projects-backup.tar.gz -C /projects
        kubectl exec -n $Namespace $podName -- rm /tmp/projects-backup.tar.gz
        Write-Success "Projects restored"
    }
    
    Write-Success "Restore completed!"
    Write-Info "Restarting pod to apply changes..."
    Invoke-Restart
}

function Invoke-Shell {
    Write-Banner "Opening Shell to CODESYS TargetVisu"
    
    Test-Prerequisites
    
    # Get pod name
    $podName = kubectl get pods -n $Namespace -l app.kubernetes.io/instance=$ReleaseName -o jsonpath='{.items[0].metadata.name}'
    
    if (-not $podName) {
        Write-Error "No pods found for release '$ReleaseName'"
        return
    }
    
    Write-Info "Connecting to pod: $podName"
    Write-Info "Type 'exit' to close the shell"
    Write-Host ""
    
    kubectl exec -n $Namespace -it $podName -- /bin/bash
}

function Invoke-Logs {
    Write-Banner "Viewing CODESYS TargetVisu Logs"
    
    Test-Prerequisites
    
    # Get pod name
    $podName = kubectl get pods -n $Namespace -l app.kubernetes.io/instance=$ReleaseName -o jsonpath='{.items[0].metadata.name}'
    
    if (-not $podName) {
        Write-Error "No pods found for release '$ReleaseName'"
        return
    }
    
    Write-Info "Viewing logs from pod: $podName"
    Write-Info "Press Ctrl+C to exit"
    Write-Host ""
    
    kubectl logs -n $Namespace -f $podName
}

function Invoke-Status {
    Write-Banner "CODESYS TargetVisu Status"
    
    Test-Prerequisites
    
    # Helm release status
    Write-Host "Helm Release:" -ForegroundColor Cyan
    helm status $ReleaseName -n $Namespace
    Write-Host ""
    
    # Deployment status
    Write-Host "Deployment:" -ForegroundColor Cyan
    kubectl get deployment -n $Namespace -l app.kubernetes.io/instance=$ReleaseName
    Write-Host ""
    
    # Pods
    Write-Host "Pods:" -ForegroundColor Cyan
    kubectl get pods -n $Namespace -l app.kubernetes.io/instance=$ReleaseName
    Write-Host ""
    
    # Services
    Write-Host "Services:" -ForegroundColor Cyan
    kubectl get svc -n $Namespace -l app.kubernetes.io/instance=$ReleaseName
    Write-Host ""
    
    # PVCs
    Write-Host "Persistent Volume Claims:" -ForegroundColor Cyan
    kubectl get pvc -n $Namespace -l app.kubernetes.io/instance=$ReleaseName
    Write-Host ""
    
    # Recent events
    Write-Host "Recent Events:" -ForegroundColor Cyan
    kubectl get events -n $Namespace --sort-by='.lastTimestamp' | Select-Object -Last 10
}

function Show-Help {
    Write-Banner "CODESYS TargetVisu Management Script"
    
    Write-Host "USAGE:" -ForegroundColor Cyan
    Write-Host "  .\manage-targetvisu.ps1 -Action <action> [options]"
    Write-Host ""
    
    Write-Host "ACTIONS:" -ForegroundColor Cyan
    Write-Host "  deploy      Deploy a new CODESYS TargetVisu instance"
    Write-Host "  upgrade     Upgrade an existing deployment"
    Write-Host "  restart     Restart the deployment (rollout restart)"
    Write-Host "  delete      Uninstall the deployment"
    Write-Host "  backup      Backup configuration and projects"
    Write-Host "  restore     Restore from backup"
    Write-Host "  shell       Open a shell to the pod"
    Write-Host "  logs        View runtime logs"
    Write-Host "  status      Show deployment status"
    Write-Host "  help        Show this help message"
    Write-Host ""
    
    Write-Host "OPTIONS:" -ForegroundColor Cyan
    Write-Host "  -ReleaseName    Helm release name (default: codesys-targetvisu)"
    Write-Host "  -Namespace      Kubernetes namespace (default: industrial)"
    Write-Host "  -ValuesFile     Path to values.yaml file"
    Write-Host "  -BackupPath     Path for backup/restore operations"
    Write-Host ""
    
    Write-Host "EXAMPLES:" -ForegroundColor Cyan
    Write-Host "  Deploy with custom values:"
    Write-Host "    .\manage-targetvisu.ps1 -Action deploy -ValuesFile .\examples\standard-factory.yaml"
    Write-Host ""
    Write-Host "  Restart HMI:"
    Write-Host "    .\manage-targetvisu.ps1 -Action restart"
    Write-Host ""
    Write-Host "  Backup configuration:"
    Write-Host "    .\manage-targetvisu.ps1 -Action backup -BackupPath C:\backups\hmi"
    Write-Host ""
    Write-Host "  View logs:"
    Write-Host "    .\manage-targetvisu.ps1 -Action logs"
    Write-Host ""
    
    Write-Host "Made with 💀 by Fireball Industries" -ForegroundColor Magenta
}

# ========================================
# Main Execution
# ========================================

switch ($Action) {
    'deploy'  { Invoke-Deploy }
    'upgrade' { Invoke-Upgrade }
    'restart' { Invoke-Restart }
    'delete'  { Invoke-Delete }
    'backup'  { Invoke-Backup }
    'restore' { Invoke-Restore }
    'shell'   { Invoke-Shell }
    'logs'    { Invoke-Logs }
    'status'  { Invoke-Status }
    'help'    { Show-Help }
}
