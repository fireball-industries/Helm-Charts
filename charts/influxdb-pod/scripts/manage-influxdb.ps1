<#
.SYNOPSIS
    Manage InfluxDB Pod deployments in Kubernetes
    
.DESCRIPTION
    Comprehensive management script for Fireball Industries InfluxDB Pod.
    "Ignite Your Factory Efficiency"™
    
    Actions: deploy, upgrade, delete, health-check, validate, backup, restore,
             query, status, tune, create-bucket, create-token, list-buckets
    
.PARAMETER Action
    Action to perform (deploy, upgrade, delete, health-check, etc.)
    
.PARAMETER ReleaseName
    Helm release name (default: influxdb)
    
.PARAMETER Namespace
    Kubernetes namespace (default: influxdb)
    
.PARAMETER ValuesFile
    Path to values.yaml file
    
.PARAMETER Organization
    InfluxDB organization name
    
.PARAMETER Bucket
    Bucket name (for create-bucket action)
    
.PARAMETER Retention
    Retention period (e.g., 90d, 365d)
    
.PARAMETER TokenDescription
    Description for new token
    
.PARAMETER TokenPermissions
    Token permissions (read, write, all)
    
.EXAMPLE
    .\manage-influxdb.ps1 -Action deploy -Organization "my-factory"
    
.EXAMPLE
    .\manage-influxdb.ps1 -Action health-check -ReleaseName influxdb
    
.EXAMPLE
    .\manage-influxdb.ps1 -Action create-bucket -Bucket "maintenance" -Retention "365d"
    
.NOTES
    Author: Patrick Ryan, Fireball Industries
    Version: 1.0.0
    "Because factory data deserves better than CSV files"
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('deploy', 'upgrade', 'delete', 'health-check', 'validate', 'backup', 
                 'restore', 'query', 'status', 'tune', 'create-bucket', 'create-token', 
                 'list-buckets', 'rotate-tokens')]
    [string]$Action,
    
    [string]$ReleaseName = "influxdb",
    [string]$Namespace = "influxdb",
    [string]$ValuesFile = "",
    [string]$Organization = "factory",
    [string]$Bucket = "",
    [string]$Retention = "90d",
    [string]$TokenDescription = "",
    [string]$TokenPermissions = "all",
    [string]$BackupPath = "",
    [string]$Query = ""
)

# ASCII Art Banner
function Show-Banner {
    Write-Host @"
================================================================================
  _____        __ _       _     _____  ____    ____           _ 
 |_   _|      / _| |     | |   |  __ \|  _ \  |  _ \         | |
   | |  _ __ | |_| |_   _| |__ | |  | | |_) | | |_) |__   ___| |
   | | | '_ \|  _| | | | |_  / | |  | |  _ <  |  __/ _ \ / _ \ |
  _| |_| | | | | | | |_| |/ /  | |__| | |_) | | | | (_) |  __/_|
 |_____|_| |_|_| |_|\__,_/___|  |_____/|____/  |_|  \___/ \___(_)

================================================================================
         Fireball Industries - "Ignite Your Factory Efficiency"™
================================================================================
"@ -ForegroundColor Cyan
}

# Check prerequisites
function Test-Prerequisites {
    Write-Host "`n🔧 Checking prerequisites..." -ForegroundColor Yellow
    
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
        Write-Host "❌ Missing required tools: $($missing -join ', ')" -ForegroundColor Red
        Write-Host "Install them and try again." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ All prerequisites met" -ForegroundColor Green
}

# Get admin token from secret
function Get-AdminToken {
    param([string]$ns = $Namespace, [string]$release = $ReleaseName)
    
    $secretName = "$release-influxdb-pod-auth"
    $token = kubectl get secret $secretName -n $ns -o jsonpath='{.data.admin-token}' 2>$null
    
    if ($token) {
        return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($token))
    }
    return $null
}

# Get InfluxDB service URL
function Get-InfluxDBUrl {
    param([string]$ns = $Namespace, [string]$release = $ReleaseName)
    
    return "http://$release-influxdb-pod.$ns.svc.cluster.local:8086"
}

# Deploy action
function Invoke-Deploy {
    Write-Host "`n🚀 Deploying InfluxDB Pod..." -ForegroundColor Cyan
    
    # Create namespace if not exists
    $nsExists = kubectl get namespace $Namespace 2>$null
    if (-not $nsExists) {
        Write-Host "Creating namespace: $Namespace" -ForegroundColor Yellow
        kubectl create namespace $Namespace
    }
    
    # Build helm install command
    $helmCmd = "helm install $ReleaseName . --namespace $Namespace --create-namespace"
    
    if ($ValuesFile) {
        $helmCmd += " -f $ValuesFile"
    }
    
    $helmCmd += " --set influxdb.organization=$Organization"
    
    Write-Host "Executing: $helmCmd" -ForegroundColor Gray
    Invoke-Expression $helmCmd
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ Deployment successful!" -ForegroundColor Green
        Write-Host "`nTo get admin token:" -ForegroundColor Yellow
        Write-Host "  kubectl get secret $ReleaseName-influxdb-pod-auth -n $Namespace -o jsonpath='{.data.admin-token}' | base64 --decode" -ForegroundColor Gray
        Write-Host "`nTo access UI:" -ForegroundColor Yellow
        Write-Host "  kubectl port-forward -n $Namespace svc/$ReleaseName-influxdb-pod 8086:8086" -ForegroundColor Gray
        Write-Host "  Then open: http://localhost:8086" -ForegroundColor Gray
    } else {
        Write-Host "❌ Deployment failed" -ForegroundColor Red
        exit 1
    }
}

# Upgrade action
function Invoke-Upgrade {
    Write-Host "`n⬆️  Upgrading InfluxDB Pod..." -ForegroundColor Cyan
    
    $helmCmd = "helm upgrade $ReleaseName . --namespace $Namespace"
    
    if ($ValuesFile) {
        $helmCmd += " -f $ValuesFile"
    }
    
    Write-Host "Executing: $helmCmd" -ForegroundColor Gray
    Invoke-Expression $helmCmd
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ Upgrade successful!" -ForegroundColor Green
    } else {
        Write-Host "❌ Upgrade failed" -ForegroundColor Red
        exit 1
    }
}

# Delete action
function Invoke-Delete {
    Write-Host "`n🗑️  Deleting InfluxDB Pod..." -ForegroundColor Red
    
    $confirm = Read-Host "Are you sure you want to delete $ReleaseName? This cannot be undone! (yes/no)"
    if ($confirm -ne "yes") {
        Write-Host "Aborted" -ForegroundColor Yellow
        return
    }
    
    helm uninstall $ReleaseName --namespace $Namespace
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ Deleted successfully" -ForegroundColor Green
        Write-Host "Note: PVCs may be retained. Delete manually if needed:" -ForegroundColor Yellow
        Write-Host "  kubectl delete pvc -n $Namespace -l app.kubernetes.io/instance=$ReleaseName" -ForegroundColor Gray
    }
}

# Health check action
function Invoke-HealthCheck {
    Write-Host "`n🏥 Performing health check..." -ForegroundColor Cyan
    
    # Check pods
    Write-Host "`nPod Status:" -ForegroundColor Yellow
    kubectl get pods -n $Namespace -l app.kubernetes.io/instance=$ReleaseName
    
    # Check services
    Write-Host "`nService Status:" -ForegroundColor Yellow
    kubectl get svc -n $Namespace -l app.kubernetes.io/instance=$ReleaseName
    
    # Check PVCs
    Write-Host "`nPersistent Volume Claims:" -ForegroundColor Yellow
    kubectl get pvc -n $Namespace -l app.kubernetes.io/instance=$ReleaseName
    
    # Test health endpoint
    Write-Host "`nTesting health endpoint..." -ForegroundColor Yellow
    $podName = kubectl get pods -n $Namespace -l app.kubernetes.io/instance=$ReleaseName -o jsonpath='{.items[0].metadata.name}' 2>$null
    
    if ($podName) {
        $health = kubectl exec -n $Namespace $podName -- curl -s http://localhost:8086/health 2>$null
        if ($health -match '"status":"pass"') {
            Write-Host "✅ InfluxDB is healthy" -ForegroundColor Green
        } else {
            Write-Host "❌ InfluxDB health check failed" -ForegroundColor Red
            Write-Host $health -ForegroundColor Gray
        }
    } else {
        Write-Host "❌ No pods found" -ForegroundColor Red
    }
}

# Status action
function Invoke-Status {
    Write-Host "`n📊 InfluxDB Status..." -ForegroundColor Cyan
    
    # Helm status
    Write-Host "`nHelm Release Status:" -ForegroundColor Yellow
    helm status $ReleaseName -n $Namespace
    
    # Get admin token
    $token = Get-AdminToken
    if ($token) {
        Write-Host "`n🔑 Admin Token (first 20 chars): $($token.Substring(0, 20))..." -ForegroundColor Yellow
    }
    
    # Describe deployment
    Write-Host "`nDeployment Details:" -ForegroundColor Yellow
    $deployType = kubectl get deploy -n $Namespace -l app.kubernetes.io/instance=$ReleaseName -o name 2>$null
    if ($deployType) {
        kubectl describe $deployType -n $Namespace
    } else {
        $statefulSet = kubectl get statefulset -n $Namespace -l app.kubernetes.io/instance=$ReleaseName -o name 2>$null
        if ($statefulSet) {
            kubectl describe $statefulSet -n $Namespace
        }
    }
}

# List buckets action
function Invoke-ListBuckets {
    Write-Host "`n🪣 Listing InfluxDB buckets..." -ForegroundColor Cyan
    
    $token = Get-AdminToken
    if (-not $token) {
        Write-Host "❌ Could not retrieve admin token" -ForegroundColor Red
        return
    }
    
    $podName = kubectl get pods -n $Namespace -l app.kubernetes.io/instance=$ReleaseName -o jsonpath='{.items[0].metadata.name}' 2>$null
    
    if ($podName) {
        kubectl exec -n $Namespace $podName -- influx bucket list --org $Organization --token $token
    } else {
        Write-Host "❌ No pods found" -ForegroundColor Red
    }
}

# Create bucket action
function Invoke-CreateBucket {
    if (-not $Bucket) {
        Write-Host "❌ Bucket name required" -ForegroundColor Red
        return
    }
    
    Write-Host "`n🪣 Creating bucket: $Bucket (retention: $Retention)..." -ForegroundColor Cyan
    
    $token = Get-AdminToken
    if (-not $token) {
        Write-Host "❌ Could not retrieve admin token" -ForegroundColor Red
        return
    }
    
    $podName = kubectl get pods -n $Namespace -l app.kubernetes.io/instance=$ReleaseName -o jsonpath='{.items[0].metadata.name}' 2>$null
    
    if ($podName) {
        kubectl exec -n $Namespace $podName -- influx bucket create `
            --name $Bucket `
            --org $Organization `
            --retention $Retention `
            --token $token
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Bucket created successfully" -ForegroundColor Green
        }
    } else {
        Write-Host "❌ No pods found" -ForegroundColor Red
    }
}

# Create token action
function Invoke-CreateToken {
    Write-Host "`n🔑 Creating API token..." -ForegroundColor Cyan
    
    if (-not $TokenDescription) {
        $TokenDescription = "Token created $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    }
    
    $token = Get-AdminToken
    if (-not $token) {
        Write-Host "❌ Could not retrieve admin token" -ForegroundColor Red
        return
    }
    
    $podName = kubectl get pods -n $Namespace -l app.kubernetes.io/instance=$ReleaseName -o jsonpath='{.items[0].metadata.name}' 2>$null
    
    if ($podName) {
        $permArg = switch ($TokenPermissions) {
            "all" { "--all-access" }
            "read" { "--read-bucket $Bucket" }
            "write" { "--write-bucket $Bucket" }
        }
        
        kubectl exec -n $Namespace $podName -- influx auth create `
            --org $Organization `
            --description $TokenDescription `
            $permArg `
            --token $token
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Token created successfully" -ForegroundColor Green
            Write-Host "⚠️  Save this token securely - it won't be shown again!" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ No pods found" -ForegroundColor Red
    }
}

# Backup action
function Invoke-Backup {
    Write-Host "`n💾 Creating backup..." -ForegroundColor Cyan
    
    if (-not $BackupPath) {
        $BackupPath = "./backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    }
    
    $token = Get-AdminToken
    if (-not $token) {
        Write-Host "❌ Could not retrieve admin token" -ForegroundColor Red
        return
    }
    
    $podName = kubectl get pods -n $Namespace -l app.kubernetes.io/instance=$ReleaseName -o jsonpath='{.items[0].metadata.name}' 2>$null
    
    if ($podName) {
        Write-Host "Backing up to: $BackupPath" -ForegroundColor Gray
        
        kubectl exec -n $Namespace $podName -- influx backup /tmp/backup --token $token
        kubectl cp "$Namespace/${podName}:/tmp/backup" $BackupPath
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Backup completed: $BackupPath" -ForegroundColor Green
        }
    } else {
        Write-Host "❌ No pods found" -ForegroundColor Red
    }
}

# Main execution
Show-Banner
Test-Prerequisites

switch ($Action) {
    'deploy' { Invoke-Deploy }
    'upgrade' { Invoke-Upgrade }
    'delete' { Invoke-Delete }
    'health-check' { Invoke-HealthCheck }
    'status' { Invoke-Status }
    'list-buckets' { Invoke-ListBuckets }
    'create-bucket' { Invoke-CreateBucket }
    'create-token' { Invoke-CreateToken }
    'backup' { Invoke-Backup }
    default {
        Write-Host "❌ Action '$Action' not fully implemented yet" -ForegroundColor Red
        Write-Host "Available actions: deploy, upgrade, delete, health-check, status, list-buckets, create-bucket, create-token, backup" -ForegroundColor Yellow
    }
}

Write-Host "`n🔥 Fireball Industries - Making Industrial IoT Less Painful Since 2026" -ForegroundColor Cyan
