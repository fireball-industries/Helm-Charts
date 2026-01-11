<#
.SYNOPSIS
    Mosquitto MQTT Broker Management Script
    
.DESCRIPTION
    Comprehensive management script for Eclipse Mosquitto MQTT broker on Kubernetes.
    Because clicking around in kubectl gets old fast.
    
.PARAMETER Action
    Action to perform: deploy, upgrade, delete, backup, restore, health-check, 
    add-user, remove-user, test-connection, bridge-setup, logs
    
.PARAMETER ReleaseName
    Helm release name (default: mosquitto)
    
.PARAMETER Namespace
    Kubernetes namespace (default: iot)
    
.PARAMETER ValuesFile
    Path to values.yaml file for deployment
    
.PARAMETER Username
    Username for user management actions
    
.PARAMETER Password
    Password for user management actions
    
.EXAMPLE
    .\manage-mosquitto.ps1 -Action deploy -Namespace iot
    
.EXAMPLE
    .\manage-mosquitto.ps1 -Action add-user -Username sensor01 -Password secret123
    
.NOTES
    Author: Patrick Ryan - Fireball Industries
    "Because your factory floor deserves better than a sketchy WiFi network"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('deploy', 'upgrade', 'delete', 'backup', 'restore', 'health-check', 
                 'add-user', 'remove-user', 'test-connection', 'bridge-setup', 'logs', 'status')]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$ReleaseName = "mosquitto",
    
    [Parameter(Mandatory=$false)]
    [string]$Namespace = "iot",
    
    [Parameter(Mandatory=$false)]
    [string]$ValuesFile = "values.yaml",
    
    [Parameter(Mandatory=$false)]
    [string]$Username,
    
    [Parameter(Mandatory=$false)]
    [string]$Password,
    
    [Parameter(Mandatory=$false)]
    [string]$BackupPath,
    
    [Parameter(Mandatory=$false)]
    [int]$TailLines = 50
)

# ============================================================================
# Configuration
# ============================================================================

$ErrorActionPreference = "Stop"
$ChartPath = Split-Path -Parent $PSScriptRoot

# ============================================================================
# Helper Functions
# ============================================================================

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White",
        [switch]$NoNewline
    )
    
    $params = @{
        Object = $Message
        ForegroundColor = $Color
    }
    
    if ($NoNewline) {
        $params.Add('NoNewline', $true)
    }
    
    Write-Host @params
}

function Write-Header {
    param([string]$Message)
    
    Write-Host ""
    Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Cyan"
    Write-ColorOutput "🦟 $Message" "Cyan"
    Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Cyan"
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "✅ $Message" "Green"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "⚠️  $Message" "Yellow"
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "❌ $Message" "Red"
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "ℹ️  $Message" "Cyan"
}

function Test-Prerequisites {
    Write-Header "Checking Prerequisites"
    
    $allGood = $true
    
    # Check kubectl
    Write-ColorOutput "Checking kubectl... " "White" -NoNewline
    try {
        $null = kubectl version --client --short 2>$null
        Write-Success "Found"
    } catch {
        Write-Error "Not found"
        $allGood = $false
    }
    
    # Check helm
    Write-ColorOutput "Checking helm... " "White" -NoNewline
    try {
        $null = helm version --short 2>$null
        Write-Success "Found"
    } catch {
        Write-Error "Not found"
        $allGood = $false
    }
    
    # Check mosquitto_pub/sub (optional)
    Write-ColorOutput "Checking mosquitto_pub... " "White" -NoNewline
    try {
        $null = mosquitto_pub --help 2>$null
        Write-Success "Found"
    } catch {
        Write-Warning "Not found (optional, needed for testing)"
    }
    
    if (-not $allGood) {
        throw "Prerequisites not met. Please install missing tools."
    }
    
    Write-Success "All required prerequisites met!"
}

function Get-PodName {
    $pods = kubectl get pods -n $Namespace -l "app.kubernetes.io/name=mosquitto-mqtt,app.kubernetes.io/instance=$ReleaseName" -o jsonpath='{.items[0].metadata.name}' 2>$null
    return $pods
}

# ============================================================================
# Action Functions
# ============================================================================

function Invoke-Deploy {
    Write-Header "Deploying Mosquitto MQTT Broker"
    
    if (-not (Test-Path $ValuesFile)) {
        Write-Error "Values file not found: $ValuesFile"
        return
    }
    
    Write-Info "Release: $ReleaseName"
    Write-Info "Namespace: $Namespace"
    Write-Info "Values: $ValuesFile"
    Write-Host ""
    
    # Create namespace if it doesn't exist
    $namespaceExists = kubectl get namespace $Namespace 2>$null
    if (-not $namespaceExists) {
        Write-Info "Creating namespace $Namespace..."
        kubectl create namespace $Namespace
    }
    
    Write-Info "Installing Helm chart..."
    helm install $ReleaseName $ChartPath `
        --namespace $Namespace `
        --values $ValuesFile `
        --wait `
        --timeout 5m
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Deployment successful!"
        Write-Host ""
        Write-Info "Run './manage-mosquitto.ps1 -Action status' to check status"
        Write-Info "Run './manage-mosquitto.ps1 -Action test-connection' to test connectivity"
    } else {
        Write-Error "Deployment failed!"
    }
}

function Invoke-Upgrade {
    Write-Header "Upgrading Mosquitto MQTT Broker"
    
    if (-not (Test-Path $ValuesFile)) {
        Write-Error "Values file not found: $ValuesFile"
        return
    }
    
    Write-Info "Release: $ReleaseName"
    Write-Info "Namespace: $Namespace"
    Write-Info "Values: $ValuesFile"
    Write-Host ""
    
    Write-Info "Upgrading Helm chart..."
    helm upgrade $ReleaseName $ChartPath `
        --namespace $Namespace `
        --values $ValuesFile `
        --wait `
        --timeout 5m
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Upgrade successful!"
    } else {
        Write-Error "Upgrade failed!"
    }
}

function Invoke-Delete {
    Write-Header "Deleting Mosquitto MQTT Broker"
    
    Write-Warning "This will delete the release: $ReleaseName in namespace: $Namespace"
    $confirm = Read-Host "Are you sure? (yes/no)"
    
    if ($confirm -ne "yes") {
        Write-Info "Cancelled."
        return
    }
    
    Write-Info "Uninstalling Helm release..."
    helm uninstall $ReleaseName --namespace $Namespace
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Uninstall successful!"
        
        Write-Warning "PVCs are not automatically deleted. To delete them:"
        Write-Host "  kubectl delete pvc -n $Namespace -l app.kubernetes.io/instance=$ReleaseName"
    } else {
        Write-Error "Uninstall failed!"
    }
}

function Invoke-HealthCheck {
    Write-Header "Mosquitto MQTT Broker Health Check"
    
    # Check Helm release
    Write-ColorOutput "Helm Release Status: " "White" -NoNewline
    $releaseStatus = helm status $ReleaseName -n $Namespace --output json 2>$null | ConvertFrom-Json
    if ($releaseStatus) {
        Write-Success $releaseStatus.info.status
    } else {
        Write-Error "Not found"
        return
    }
    
    # Check StatefulSet
    Write-ColorOutput "StatefulSet Status: " "White" -NoNewline
    $sts = kubectl get statefulset $ReleaseName -n $Namespace -o json 2>$null | ConvertFrom-Json
    if ($sts) {
        $ready = "$($sts.status.readyReplicas)/$($sts.status.replicas)"
        if ($sts.status.readyReplicas -eq $sts.status.replicas) {
            Write-Success $ready
        } else {
            Write-Warning $ready
        }
    } else {
        Write-Error "Not found"
    }
    
    # Check Pods
    Write-Host ""
    Write-Info "Pod Status:"
    kubectl get pods -n $Namespace -l "app.kubernetes.io/instance=$ReleaseName"
    
    # Check Service
    Write-Host ""
    Write-Info "Service Status:"
    kubectl get svc -n $Namespace -l "app.kubernetes.io/instance=$ReleaseName"
    
    # Check PVC
    Write-Host ""
    Write-Info "Persistence:"
    kubectl get pvc -n $Namespace -l "app.kubernetes.io/instance=$ReleaseName"
    
    # Test MQTT connectivity
    Write-Host ""
    Write-Info "Testing MQTT connectivity..."
    $podName = Get-PodName
    
    if ($podName) {
        $testResult = kubectl exec -n $Namespace $podName -c mosquitto -- mosquitto_sub -h localhost -p 1883 -t 'test' -C 1 -W 2 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "MQTT broker is responding"
        } else {
            Write-Warning "MQTT broker is not responding (this may be normal if authentication is required)"
        }
    }
}

function Invoke-AddUser {
    Write-Header "Add MQTT User"
    
    if (-not $Username) {
        $Username = Read-Host "Username"
    }
    
    if (-not $Password) {
        $Password = Read-Host "Password" -AsSecureString
        $Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
    }
    
    $podName = Get-PodName
    if (-not $podName) {
        Write-Error "No Mosquitto pods found"
        return
    }
    
    Write-Info "Adding user '$Username' to pod '$podName'..."
    
    kubectl exec -n $Namespace $podName -c mosquitto -- mosquitto_passwd -b /mosquitto/config/passwd $Username $Password
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "User '$Username' added successfully!"
        Write-Warning "You may need to restart the broker for changes to take effect:"
        Write-Host "  kubectl rollout restart statefulset/$ReleaseName -n $Namespace"
    } else {
        Write-Error "Failed to add user"
    }
}

function Invoke-RemoveUser {
    Write-Header "Remove MQTT User"
    
    if (-not $Username) {
        $Username = Read-Host "Username"
    }
    
    $podName = Get-PodName
    if (-not $podName) {
        Write-Error "No Mosquitto pods found"
        return
    }
    
    Write-Info "Removing user '$Username' from pod '$podName'..."
    
    kubectl exec -n $Namespace $podName -c mosquitto -- mosquitto_passwd -D /mosquitto/config/passwd $Username
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "User '$Username' removed successfully!"
    } else {
        Write-Error "Failed to remove user"
    }
}

function Invoke-TestConnection {
    Write-Header "Testing MQTT Connection"
    
    $service = "$ReleaseName.$Namespace.svc.cluster.local"
    $port = 1883
    
    Write-Info "Testing connection to: $service:$port"
    Write-Host ""
    
    Write-Info "Starting subscriber (will wait 10 seconds for message)..."
    
    # Use a test pod for publishing and subscribing
    Write-Info "Publishing test message..."
    kubectl run -it --rm mqtt-test-pub --image=eclipse-mosquitto:2.0 --restart=Never -- `
        mosquitto_pub -h $service -p $port -t 'test/fireball' -m 'Hello from Fireball Industries!' -d
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Successfully published test message!"
        Write-Info "Try subscribing with:"
        Write-Host "  kubectl run -it --rm mqtt-test-sub --image=eclipse-mosquitto:2.0 --restart=Never -- mosquitto_sub -h $service -p $port -t 'test/#' -v"
    } else {
        Write-Error "Failed to publish test message"
    }
}

function Invoke-Logs {
    Write-Header "Mosquitto Logs"
    
    $podName = Get-PodName
    if (-not $podName) {
        Write-Error "No Mosquitto pods found"
        return
    }
    
    Write-Info "Showing logs from pod: $podName"
    Write-Info "Container: mosquitto"
    Write-Host ""
    
    kubectl logs -n $Namespace $podName -c mosquitto --tail=$TailLines --follow
}

function Invoke-Status {
    Write-Header "Mosquitto MQTT Broker Status"
    
    # Helm status
    helm status $ReleaseName -n $Namespace
}

# ============================================================================
# Main Execution
# ============================================================================

Write-Host ""
Write-ColorOutput "🦟 Mosquitto MQTT Broker Management" "Magenta"
Write-ColorOutput "   Fireball Industries - Patrick Ryan" "DarkGray"
Write-ColorOutput '   "At least it''s more reliable than Modbus over WiFi"' "DarkGray"
Write-Host ""

try {
    # Only check prerequisites for actions that need them
    if ($Action -in @('deploy', 'upgrade', 'delete', 'health-check', 'test-connection')) {
        Test-Prerequisites
    }
    
    switch ($Action) {
        'deploy'          { Invoke-Deploy }
        'upgrade'         { Invoke-Upgrade }
        'delete'          { Invoke-Delete }
        'health-check'    { Invoke-HealthCheck }
        'add-user'        { Invoke-AddUser }
        'remove-user'     { Invoke-RemoveUser }
        'test-connection' { Invoke-TestConnection }
        'logs'            { Invoke-Logs }
        'status'          { Invoke-Status }
        default {
            Write-Error "Unknown action: $Action"
        }
    }
    
    Write-Host ""
    Write-Success "Action completed: $Action"
    
} catch {
    Write-Host ""
    Write-Error "Failed: $_"
    Write-Host $_.ScriptStackTrace
    exit 1
}
