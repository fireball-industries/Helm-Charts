<#
.SYNOPSIS
    Manage Fireball Node Exporter deployment in Kubernetes/K3s clusters.

.DESCRIPTION
    Comprehensive management script for Prometheus Node Exporter with hardware humor.
    Because managing monitoring infrastructure shouldn't be boring.

.PARAMETER Action
    Action to perform: deploy, upgrade, delete, health-check, view-metrics, test-alerts, logs

.PARAMETER Namespace
    Kubernetes namespace (default: monitoring)

.PARAMETER ReleaseName
    Helm release name (default: node-exporter)

.PARAMETER ValuesFile
    Path to custom values.yaml file

.PARAMETER Node
    Specific node name for node-specific operations

.EXAMPLE
    .\manage-node-exporter.ps1 -Action deploy
    .\manage-node-exporter.ps1 -Action health-check
    .\manage-node-exporter.ps1 -Action view-metrics -Node worker-01

.NOTES
    Author: Patrick Ryan - Fireball Industries
    Because knowing your hardware is dying BEFORE it catches fire is useful.
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('deploy', 'upgrade', 'delete', 'health-check', 'view-metrics', 'test-alerts', 'logs', 'temperature', 'disk-space', 'network-stats')]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$Namespace = "monitoring",
    
    [Parameter(Mandatory=$false)]
    [string]$ReleaseName = "node-exporter",
    
    [Parameter(Mandatory=$false)]
    [string]$ValuesFile = "values.yaml",
    
    [Parameter(Mandatory=$false)]
    [string]$Node = ""
)

# Color output functions
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Success { param([string]$Message) Write-ColorOutput "✓ $Message" "Green" }
function Write-Info { param([string]$Message) Write-ColorOutput "ℹ $Message" "Cyan" }
function Write-Warning { param([string]$Message) Write-ColorOutput "⚠ $Message" "Yellow" }
function Write-Error2 { param([string]$Message) Write-ColorOutput "✗ $Message" "Red" }
function Write-Hardware { param([string]$Message) Write-ColorOutput "🔧 $Message" "Magenta" }

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Cyan"
    Write-ColorOutput "  $Title" "Cyan"
    Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Cyan"
    Write-Host ""
}

# Prerequisite checks
function Test-Prerequisites {
    Write-Header "Checking Prerequisites"
    
    $allGood = $true
    
    # Check kubectl
    if (Get-Command kubectl -ErrorAction SilentlyContinue) {
        $kubectlVersion = (kubectl version --client --short 2>$null) -replace 'Client Version: ', ''
        Write-Success "kubectl installed: $kubectlVersion"
    } else {
        Write-Error2 "kubectl not found. Install from: https://kubernetes.io/docs/tasks/tools/"
        $allGood = $false
    }
    
    # Check helm
    if (Get-Command helm -ErrorAction SilentlyContinue) {
        $helmVersion = (helm version --short 2>$null)
        Write-Success "helm installed: $helmVersion"
    } else {
        Write-Error2 "helm not found. Install from: https://helm.sh/docs/intro/install/"
        $allGood = $false
    }
    
    # Check curl
    if (Get-Command curl -ErrorAction SilentlyContinue) {
        Write-Success "curl installed"
    } else {
        Write-Warning "curl not found. Some features will be limited."
    }
    
    # Check cluster connectivity
    try {
        $null = kubectl cluster-info 2>&1
        Write-Success "Kubernetes cluster accessible"
    } catch {
        Write-Error2 "Cannot connect to Kubernetes cluster"
        $allGood = $false
    }
    
    if (-not $allGood) {
        Write-Host ""
        Write-Error2 "Prerequisites not met. Please install required tools."
        exit 1
    }
    
    Write-Host ""
}

# Deploy Node Exporter
function Deploy-NodeExporter {
    Write-Header "Deploying Fireball Node Exporter"
    
    Write-Info "Release Name: $ReleaseName"
    Write-Info "Namespace: $Namespace"
    Write-Info "Values File: $ValuesFile"
    Write-Host ""
    
    # Create namespace if it doesn't exist
    $namespaceExists = kubectl get namespace $Namespace 2>$null
    if (-not $namespaceExists) {
        Write-Info "Creating namespace: $Namespace"
        kubectl create namespace $Namespace
    }
    
    # Deploy with Helm
    Write-Info "Installing Node Exporter via Helm..."
    helm upgrade --install $ReleaseName . `
        --namespace $Namespace `
        --values $ValuesFile `
        --create-namespace `
        --wait `
        --timeout 5m
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Node Exporter deployed successfully!"
        Write-Host ""
        Write-Hardware "Your nodes are now being monitored. Try not to let them catch fire."
        Write-Host ""
        
        # Show status
        Start-Sleep -Seconds 3
        Show-HealthCheck
    } else {
        Write-Error2 "Deployment failed. Check the error messages above."
        exit 1
    }
}

# Upgrade Node Exporter
function Upgrade-NodeExporter {
    Write-Header "Upgrading Fireball Node Exporter"
    
    Write-Info "Upgrading release: $ReleaseName"
    Write-Info "Namespace: $Namespace"
    Write-Info "Values File: $ValuesFile"
    Write-Host ""
    
    helm upgrade $ReleaseName . `
        --namespace $Namespace `
        --values $ValuesFile `
        --wait `
        --timeout 5m
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Node Exporter upgraded successfully!"
        Write-Hardware "Your monitoring got better. The hardware is still dying though."
    } else {
        Write-Error2 "Upgrade failed."
        exit 1
    }
}

# Delete Node Exporter
function Remove-NodeExporter {
    Write-Header "Removing Fireball Node Exporter"
    
    Write-Warning "This will delete the Node Exporter deployment!"
    $confirm = Read-Host "Are you sure? (yes/no)"
    
    if ($confirm -ne "yes") {
        Write-Info "Deletion cancelled."
        return
    }
    
    Write-Info "Uninstalling Helm release: $ReleaseName"
    helm uninstall $ReleaseName --namespace $Namespace
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Node Exporter removed."
        Write-Hardware "Hope you have another way to monitor those temps..."
    }
}

# Health check
function Show-HealthCheck {
    Write-Header "Node Exporter Health Check"
    
    # Check DaemonSet/Deployment status
    $deploymentMode = (helm get values $ReleaseName -n $Namespace -o json | ConvertFrom-Json).deploymentMode
    
    if ($deploymentMode -eq "daemonset" -or !$deploymentMode) {
        Write-Info "Checking DaemonSet status..."
        kubectl get daemonset -n $Namespace -l app.kubernetes.io/name=fireball-node-exporter
        
        Write-Host ""
        Write-Info "Pods per node:"
        kubectl get pods -n $Namespace -l app.kubernetes.io/name=fireball-node-exporter -o wide
    } else {
        Write-Info "Checking Deployment status..."
        kubectl get deployment -n $Namespace -l app.kubernetes.io/name=fireball-node-exporter
        
        Write-Host ""
        Write-Info "Pods:"
        kubectl get pods -n $Namespace -l app.kubernetes.io/name=fireball-node-exporter -o wide
    }
    
    Write-Host ""
    
    # Check if all pods are running
    $pods = kubectl get pods -n $Namespace -l app.kubernetes.io/name=fireball-node-exporter -o json | ConvertFrom-Json
    $runningPods = ($pods.items | Where-Object { $_.status.phase -eq "Running" }).Count
    $totalPods = $pods.items.Count
    
    if ($runningPods -eq $totalPods -and $totalPods -gt 0) {
        Write-Success "$runningPods/$totalPods pods running"
        Write-Hardware "All systems operational. Hardware still aging though."
    } elseif ($totalPods -eq 0) {
        Write-Error2 "No pods found. Something went wrong with deployment."
    } else {
        Write-Warning "$runningPods/$totalPods pods running. Some pods are not ready."
    }
    
    Write-Host ""
    
    # Check Service
    Write-Info "Service status:"
    kubectl get service -n $Namespace -l app.kubernetes.io/name=fireball-node-exporter
    
    Write-Host ""
}

# View metrics from nodes
function Show-Metrics {
    Write-Header "Node Metrics Viewer"
    
    if ($Node) {
        Write-Info "Fetching metrics from node: $Node"
        $podName = kubectl get pods -n $Namespace -l app.kubernetes.io/name=fireball-node-exporter --field-selector spec.nodeName=$Node -o jsonpath='{.items[0].metadata.name}' 2>$null
        
        if (-not $podName) {
            Write-Error2 "No pod found on node: $Node"
            return
        }
        
        Write-Info "Pod: $podName"
        Write-Host ""
        
        kubectl port-forward -n $Namespace $podName 9100:9100 > $null 2>&1 &
        $portForwardJob = $!
        Start-Sleep -Seconds 2
        
        Write-Info "Sample metrics from $Node"
        Write-Host ""
        
        # CPU
        Write-ColorOutput "CPU Metrics:" "Yellow"
        curl -s http://localhost:9100/metrics 2>$null | Select-String "node_cpu_seconds_total" | Select-Object -First 5
        
        Write-Host ""
        
        # Memory
        Write-ColorOutput "Memory Metrics:" "Yellow"
        curl -s http://localhost:9100/metrics 2>$null | Select-String "node_memory_" | Select-Object -First 5
        
        Write-Host ""
        
        # Disk
        Write-ColorOutput "Disk Metrics:" "Yellow"
        curl -s http://localhost:9100/metrics 2>$null | Select-String "node_disk_" | Select-Object -First 5
        
        # Kill port-forward
        Stop-Process -Id $portForwardJob -ErrorAction SilentlyContinue
        
    } else {
        Write-Info "Listing all nodes with Node Exporter pods:"
        kubectl get pods -n $Namespace -l app.kubernetes.io/name=fireball-node-exporter -o custom-columns=NODE:.spec.nodeName,POD:.metadata.name,STATUS:.status.phase
        
        Write-Host ""
        Write-Info "Use -Node <nodename> to view metrics from a specific node"
    }
}

# Check temperature across cluster
function Show-Temperature {
    Write-Header "Cluster Temperature Monitoring"
    
    Write-Hardware "Checking if your hardware is cooking itself..."
    Write-Host ""
    
    $pods = kubectl get pods -n $Namespace -l app.kubernetes.io/name=fireball-node-exporter -o json | ConvertFrom-Json
    
    foreach ($pod in $pods.items) {
        $podName = $pod.metadata.name
        $nodeName = $pod.spec.nodeName
        
        Write-Info "Node: $nodeName ($podName)"
        
        # Port forward and check temp
        kubectl port-forward -n $Namespace $podName 9100:9100 > $null 2>&1 &
        $job = $!
        Start-Sleep -Seconds 2
        
        $tempMetrics = curl -s http://localhost:9100/metrics 2>$null | Select-String "node_hwmon_temp_celsius"
        
        if ($tempMetrics) {
            foreach ($metric in $tempMetrics) {
                if ($metric -match 'node_hwmon_temp_celsius.*\s+(\d+\.?\d*)') {
                    $temp = [double]$matches[1]
                    
                    if ($temp -gt 80) {
                        Write-Error2 "  🔥 $metric (CRITICAL - Your hardware is literally cooking!)"
                    } elseif ($temp -gt 70) {
                        Write-Warning "  ⚠️  $metric (HIGH - Check your cooling!)"
                    } else {
                        Write-Success "  ✓ $metric (OK)"
                    }
                }
            }
        } else {
            Write-Info "  No temperature sensors detected"
        }
        
        Stop-Process -Id $job -ErrorAction SilentlyContinue
        Write-Host ""
    }
    
    Write-Hardware "Remember: If you can't hold your hand on it, it's too hot."
}

# Check disk space across cluster
function Show-DiskSpace {
    Write-Header "Cluster Disk Space Check"
    
    Write-Info "Checking disk space across all nodes..."
    Write-Host ""
    
    $pods = kubectl get pods -n $Namespace -l app.kubernetes.io/name=fireball-node-exporter -o json | ConvertFrom-Json
    
    foreach ($pod in $pods.items) {
        $podName = $pod.metadata.name
        $nodeName = $pod.spec.nodeName
        
        Write-Info "Node: $nodeName"
        
        kubectl port-forward -n $Namespace $podName 9100:9100 > $null 2>&1 &
        $job = $!
        Start-Sleep -Seconds 2
        
        $fsMetrics = curl -s http://localhost:9100/metrics 2>$null | Select-String "node_filesystem_avail_bytes{.*mountpoint=\"/\"" | Select-Object -First 1
        $fsSizeMetrics = curl -s http://localhost:9100/metrics 2>$null | Select-String "node_filesystem_size_bytes{.*mountpoint=\"/\"" | Select-Object -First 1
        
        if ($fsMetrics -and $fsSizeMetrics) {
            $fsMetrics -match '\s+(\d+)$' | Out-Null
            $availBytes = [long]$matches[1]
            
            $fsSizeMetrics -match '\s+(\d+)$' | Out-Null
            $totalBytes = [long]$matches[1]
            
            $usedPercent = [math]::Round((($totalBytes - $availBytes) / $totalBytes) * 100, 2)
            $availGB = [math]::Round($availBytes / 1GB, 2)
            
            if ($usedPercent -gt 90) {
                Write-Error2 "  🚨 ${usedPercent}% used (${availGB}GB free) - CRITICAL!"
            } elseif ($usedPercent -gt 80) {
                Write-Warning "  ⚠️  ${usedPercent}% used (${availGB}GB free) - WARNING"
            } else {
                Write-Success "  ✓ ${usedPercent}% used (${availGB}GB free) - OK"
            }
        }
        
        Stop-Process -Id $job -ErrorAction SilentlyContinue
        Write-Host ""
    }
}

# View logs
function Show-Logs {
    Write-Header "Node Exporter Logs"
    
    if ($Node) {
        $podName = kubectl get pods -n $Namespace -l app.kubernetes.io/name=fireball-node-exporter --field-selector spec.nodeName=$Node -o jsonpath='{.items[0].metadata.name}'
        
        if ($podName) {
            Write-Info "Showing logs from $podName on node $Node"
            Write-Host ""
            kubectl logs -n $Namespace $podName --tail=50
        } else {
            Write-Error2 "No pod found on node: $Node"
        }
    } else {
        Write-Info "Showing logs from all Node Exporter pods (last 20 lines each):"
        Write-Host ""
        kubectl logs -n $Namespace -l app.kubernetes.io/name=fireball-node-exporter --tail=20 --prefix=true
    }
}

# Main execution
Write-Host ""
Write-ColorOutput "╔═══════════════════════════════════════════════════════════════╗" "Cyan"
Write-ColorOutput "║                                                               ║" "Cyan"
Write-ColorOutput "║     FIREBALL NODE EXPORTER MANAGEMENT                         ║" "Cyan"
Write-ColorOutput "║     Because hardware monitoring shouldn't be boring           ║" "Cyan"
Write-ColorOutput "║                                                               ║" "Cyan"
Write-ColorOutput "╚═══════════════════════════════════════════════════════════════╝" "Cyan"
Write-Host ""

Test-Prerequisites

switch ($Action) {
    'deploy' { Deploy-NodeExporter }
    'upgrade' { Upgrade-NodeExporter }
    'delete' { Remove-NodeExporter }
    'health-check' { Show-HealthCheck }
    'view-metrics' { Show-Metrics }
    'temperature' { Show-Temperature }
    'disk-space' { Show-DiskSpace }
    'logs' { Show-Logs }
}

Write-Host ""
Write-Hardware "Remember: Monitoring is only useful if you act on the alerts."
Write-Hardware "That 85°C temperature isn't 'fine'. Fix. Your. Cooling."
Write-Host ""
