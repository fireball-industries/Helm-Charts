<#
.SYNOPSIS
    CODESYS License Manager
.DESCRIPTION
    Manages CODESYS TargetVisu licenses in Kubernetes
.NOTES
    Author: Patrick Ryan / Fireball Industries
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('install', 'validate', 'info', 'remove')]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$LicenseFile,
    
    [Parameter(Mandatory=$false)]
    [string]$ReleaseName = "codesys-targetvisu",
    
    [Parameter(Mandatory=$false)]
    [string]$Namespace = "industrial"
)

function Install-License {
    if (-not $LicenseFile) {
        Write-Host "❌ Please specify -LicenseFile" -ForegroundColor Red
        return
    }
    
    if (-not (Test-Path $LicenseFile)) {
        Write-Host "❌ License file not found: $LicenseFile" -ForegroundColor Red
        return
    }
    
    Write-Host "📜 Installing CODESYS license..." -ForegroundColor Cyan
    
    # Create secret
    kubectl create secret generic codesys-license `
        --from-file=license.lic=$LicenseFile `
        --namespace=$Namespace `
        --dry-run=client -o yaml | kubectl apply -f -
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ License installed successfully" -ForegroundColor Green
        Write-Host "ℹ️  Restart deployment to apply license:" -ForegroundColor Blue
        Write-Host "  .\manage-targetvisu.ps1 -Action restart" -ForegroundColor Yellow
    } else {
        Write-Host "❌ Failed to install license" -ForegroundColor Red
    }
}

function Get-LicenseInfo {
    Write-Host "📜 License Information" -ForegroundColor Cyan
    
    $podName = kubectl get pods -n $Namespace -l app.kubernetes.io/instance=$ReleaseName -o jsonpath='{.items[0].metadata.name}' 2>$null
    
    if ($podName) {
        Write-Host "Pod: $podName" -ForegroundColor Gray
        kubectl exec -n $Namespace $podName -- ls -lh /var/opt/codesys/license/ 2>$null
    } else {
        Write-Host "❌ No pods found" -ForegroundColor Red
    }
}

switch ($Action) {
    'install' { Install-License }
    'info' { Get-LicenseInfo }
}

