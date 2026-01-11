<#
.SYNOPSIS
    CODESYS TargetVisu Diagnostics
.NOTES
    Author: Patrick Ryan / Fireball Industries
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ReleaseName = "codesys-targetvisu",
    
    [Parameter(Mandatory=$false)]
    [string]$Namespace = "industrial"
)

Write-Host "🔍 CODESYS TargetVisu Diagnostics" -ForegroundColor Magenta
Write-Host "=================================" -ForegroundColor Magenta
Write-Host ""

$podName = kubectl get pods -n $Namespace -l app.kubernetes.io/instance=$ReleaseName -o jsonpath='{.items[0].metadata.name}' 2>$null

if (-not $podName) {
    Write-Host "❌ No pods found" -ForegroundColor Red
    exit 1
}

# Pod info
Write-Host "📦 Pod Information:" -ForegroundColor Cyan
kubectl get pod -n $Namespace $podName
Write-Host ""

# Resource usage
Write-Host "📊 Resource Usage:" -ForegroundColor Cyan
kubectl top pod -n $Namespace $podName 2>$null
Write-Host ""

# Recent logs
Write-Host "📜 Recent Logs (last 20 lines):" -ForegroundColor Cyan
kubectl logs -n $Namespace $podName --tail=20
Write-Host ""

# Port forwarding suggestion
Write-Host "💡 To access locally:" -ForegroundColor Yellow
Write-Host "  kubectl port-forward -n $Namespace $podName 8080:8080"
Write-Host ""

Write-Host "Made with 💀 by Fireball Industries" -ForegroundColor Magenta
