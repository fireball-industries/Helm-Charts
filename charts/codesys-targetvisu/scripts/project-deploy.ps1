<#
.SYNOPSIS
    Deploy HMI Projects to CODESYS TargetVisu
.NOTES
    Author: Patrick Ryan / Fireball Industries
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,
    
    [Parameter(Mandatory=$false)]
    [string]$ReleaseName = "codesys-targetvisu",
    
    [Parameter(Mandatory=$false)]
    [string]$Namespace = "industrial"
)

if (-not (Test-Path $ProjectPath)) {
    Write-Host "❌ Project not found: $ProjectPath" -ForegroundColor Red
    exit 1
}

$podName = kubectl get pods -n $Namespace -l app.kubernetes.io/instance=$ReleaseName -o jsonpath='{.items[0].metadata.name}' 2>$null

if (-not $podName) {
    Write-Host "❌ No pods found for release '$ReleaseName'" -ForegroundColor Red
    exit 1
}

Write-Host "🚀 Deploying project to CODESYS TargetVisu..." -ForegroundColor Cyan
Write-Host "Pod: $podName" -ForegroundColor Gray
Write-Host "Project: $ProjectPath" -ForegroundColor Gray

# Copy project
kubectl cp $ProjectPath "${Namespace}/${podName}:/projects/" 

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Project deployed successfully" -ForegroundColor Green
    Write-Host "ℹ️  Access your HMI to view the project" -ForegroundColor Blue
} else {
    Write-Host "❌ Deployment failed" -ForegroundColor Red
}
