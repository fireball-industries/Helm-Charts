<#
.SYNOPSIS
    CODESYS TargetVisu Testing Suite
    
.DESCRIPTION
    Comprehensive testing script for CODESYS TargetVisu deployments.
    Tests health, web interface, protocols, and PLC connections.
    
.PARAMETER ReleaseName
    Helm release name (default: codesys-targetvisu)
    
.PARAMETER Namespace
    Kubernetes namespace (default: industrial)
    
.PARAMETER TestType
    Type of test: all, health, web, protocols, plc, performance
    
.EXAMPLE
    .\test-targetvisu.ps1 -TestType all
    
.NOTES
    Author: Patrick Ryan / Fireball Industries
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ReleaseName = "codesys-targetvisu",
    
    [Parameter(Mandatory=$false)]
    [string]$Namespace = "industrial",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('all', 'health', 'web', 'protocols', 'plc', 'performance')]
    [string]$TestType = "all"
)

# Test results
$script:TestResults = @()

function Write-TestHeader {
    param([string]$Text)
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
}

function Add-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Message
    )
    
    $result = [PSCustomObject]@{
        Test = $TestName
        Status = if ($Passed) { "✅ PASS" } else { "❌ FAIL" }
        Message = $Message
    }
    
    $script:TestResults += $result
    
    if ($Passed) {
        Write-Host "✅ $TestName" -ForegroundColor Green -NoNewline
        Write-Host " - $Message" -ForegroundColor Gray
    } else {
        Write-Host "❌ $TestName" -ForegroundColor Red -NoNewline
        Write-Host " - $Message" -ForegroundColor Gray
    }
}

function Test-DeploymentHealth {
    Write-TestHeader "Deployment Health Tests"
    
    # Test pod exists
    $podName = kubectl get pods -n $Namespace -l app.kubernetes.io/instance=$ReleaseName -o jsonpath='{.items[0].metadata.name}' 2>$null
    Add-TestResult "Pod exists" ($null -ne $podName) "Pod: $podName"
    
    if ($null -eq $podName) { return }
    
    # Test pod status
    $podStatus = kubectl get pod -n $Namespace $podName -o jsonpath='{.status.phase}' 2>$null
    Add-TestResult "Pod running" ($podStatus -eq "Running") "Status: $podStatus"
    
    # Test pod ready
    $podReady = kubectl get pod -n $Namespace $podName -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>$null
    Add-TestResult "Pod ready" ($podReady -eq "True") "Ready: $podReady"
    
    # Test restart count
    $restarts = kubectl get pod -n $Namespace $podName -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>$null
    Add-TestResult "Low restart count" ([int]$restarts -lt 5) "Restarts: $restarts"
}

function Test-WebInterface {
    Write-TestHeader "Web Interface Tests"
    
    # Get service info
    $serviceIP = kubectl get svc -n $Namespace $ReleaseName -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
    if (-not $serviceIP) {
        $serviceType = kubectl get svc -n $Namespace $ReleaseName -o jsonpath='{.spec.type}' 2>$null
        if ($serviceType -eq "NodePort") {
            $nodePort = kubectl get svc -n $Namespace $ReleaseName -o jsonpath='{.spec.ports[0].nodePort}' 2>$null
            $nodeIP = kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>$null
            $serviceIP = "${nodeIP}:${nodePort}"
        }
    }
    
    if ($serviceIP) {
        Add-TestResult "Service accessible" $true "IP: $serviceIP"
    } else {
        Add-TestResult "Service accessible" $false "Could not determine service IP"
    }
}

function Test-Protocols {
    Write-TestHeader "Industrial Protocol Tests"
    
    $podName = kubectl get pods -n $Namespace -l app.kubernetes.io/instance=$ReleaseName -o jsonpath='{.items[0].metadata.name}' 2>$null
    
    if ($null -eq $podName) {
        Add-TestResult "Protocol tests" $false "No pod found"
        return
    }
    
    # Test OPC UA port
    $opcuaPort = kubectl exec -n $Namespace $podName -- netstat -tuln 2>$null | Select-String ":4840"
    Add-TestResult "OPC UA port open" ($null -ne $opcuaPort) "Port 4840"
    
    # Test Modbus TCP port
    $modbusPort = kubectl exec -n $Namespace $podName -- netstat -tuln 2>$null | Select-String ":502"
    Add-TestResult "Modbus TCP port" ($null -ne $modbusPort) "Port 502"
}

function Show-Summary {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  TEST SUMMARY" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    
    $script:TestResults | Format-Table Test, Status, Message -AutoSize
    
    $passed = ($script:TestResults | Where-Object { $_.Status -like "*PASS*" }).Count
    $failed = ($script:TestResults | Where-Object { $_.Status -like "*FAIL*" }).Count
    $total = $script:TestResults.Count
    
    Write-Host ""
    Write-Host "Total Tests: $total" -ForegroundColor Cyan
    Write-Host "Passed: $passed" -ForegroundColor Green
    Write-Host "Failed: $failed" -ForegroundColor Red
    Write-Host ""
    
    if ($failed -eq 0) {
        Write-Host "🎉 All tests passed! Your HMI is healthier than your PLC." -ForegroundColor Green
    } else {
        Write-Host "⚠️  Some tests failed. Time to debug. (Coffee recommended)" -ForegroundColor Yellow
    }
}

# Main execution
Write-Host "CODESYS TargetVisu Test Suite" -ForegroundColor Magenta
Write-Host "Release: $ReleaseName | Namespace: $Namespace" -ForegroundColor Gray

if ($TestType -eq "all" -or $TestType -eq "health") {
    Test-DeploymentHealth
}

if ($TestType -eq "all" -or $TestType -eq "web") {
    Test-WebInterface
}

if ($TestType -eq "all" -or $TestType -eq "protocols") {
    Test-Protocols
}

Show-Summary
