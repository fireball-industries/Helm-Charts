<#
.SYNOPSIS
    Ignition Edge Connectivity and Performance Test Script
    
.DESCRIPTION
    Comprehensive testing suite for Ignition Edge deployment.
    Because "it works on my machine" is not a deployment strategy.
    
    Patrick Ryan - Fireball Industries

.PARAMETER ReleaseName
    Helm release name (default: ignition-edge)

.PARAMETER Namespace
    Kubernetes namespace (default: industrial)

.PARAMETER SkipPerformance
    Skip performance benchmarks (they take a while)

.EXAMPLE
    .\test-ignition.ps1

.EXAMPLE
    .\test-ignition.ps1 -ReleaseName my-gateway -Namespace production
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ReleaseName = "ignition-edge",
    
    [Parameter(Mandatory=$false)]
    [string]$Namespace = "industrial",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipPerformance
)

# Import color functions
. "$PSScriptRoot\manage-ignition.ps1" -Action health-check -WhatIf 2>$null | Out-Null

# ============================================================================
# Test Results Tracking
# ============================================================================

$script:TestResults = @{
    Passed = 0
    Failed = 0
    Warnings = 0
}

function Test-Component {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [bool]$Critical = $false
    )
    
    Write-Host "Testing: $Name... " -NoNewline
    
    try {
        $result = & $Test
        if ($result) {
            Write-Host "✓ PASS" -ForegroundColor Green
            $script:TestResults.Passed++
            return $true
        } else {
            if ($Critical) {
                Write-Host "✗ FAIL (Critical)" -ForegroundColor Red
                $script:TestResults.Failed++
            } else {
                Write-Host "⚠ WARN" -ForegroundColor Yellow
                $script:TestResults.Warnings++
            }
            return $false
        }
    } catch {
        Write-Host "✗ ERROR: $_" -ForegroundColor Red
        $script:TestResults.Failed++
        return $false
    }
}

# ============================================================================
# Infrastructure Tests
# ============================================================================

Write-Header "Infrastructure Tests"

Test-Component -Name "Kubernetes cluster connectivity" -Critical $true -Test {
    $null = kubectl cluster-info 2>&1
    $LASTEXITCODE -eq 0
}

Test-Component -Name "Namespace exists" -Critical $true -Test {
    $null = kubectl get namespace $Namespace 2>&1
    $LASTEXITCODE -eq 0
}

Test-Component -Name "Helm release deployed" -Critical $true -Test {
    $status = helm status $ReleaseName -n $Namespace 2>&1
    $LASTEXITCODE -eq 0
}

Test-Component -Name "Gateway pod running" -Critical $true -Test {
    $podStatus = kubectl get pods -n $Namespace `
        -l "app.kubernetes.io/name=ignition-edge,app.kubernetes.io/instance=$ReleaseName" `
        -o jsonpath='{.items[0].status.phase}' 2>&1
    
    $podStatus -eq "Running"
}

Test-Component -Name "All containers ready" -Critical $true -Test {
    $ready = kubectl get pods -n $Namespace `
        -l "app.kubernetes.io/name=ignition-edge,app.kubernetes.io/instance=$ReleaseName" `
        -o jsonpath='{.items[0].status.containerStatuses[*].ready}' 2>&1
    
    $ready -notcontains "false"
}

# ============================================================================
# Persistence Tests
# ============================================================================

Write-Header "Persistence Tests"

Test-Component -Name "Gateway data PVC bound" -Test {
    $status = kubectl get pvc -n $Namespace "$ReleaseName-data" `
        -o jsonpath='{.status.phase}' 2>&1
    
    $status -eq "Bound"
}

Test-Component -Name "Backup PVC bound" -Test {
    $status = kubectl get pvc -n $Namespace "$ReleaseName-backup" `
        -o jsonpath='{.status.phase}' 2>&1
    
    $status -eq "Bound"
}

# ============================================================================
# Network Connectivity Tests
# ============================================================================

Write-Header "Network Connectivity Tests"

$portForward = $null

try {
    # Start port-forward
    $portForward = Start-Process kubectl `
        -ArgumentList "port-forward -n $Namespace svc/$ReleaseName 8088:8088 8043:8043 62541:62541 1883:1883" `
        -PassThru -WindowStyle Hidden
    
    Start-Sleep -Seconds 5
    
    Test-Component -Name "HTTP port (8088) accessible" -Critical $true -Test {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8088/StatusPing" `
                -TimeoutSec 10 -UseBasicParsing
            $response.StatusCode -eq 200
        } catch {
            $false
        }
    }
    
    Test-Component -Name "HTTPS port (8043) accessible" -Test {
        try {
            $response = Invoke-WebRequest -Uri "https://localhost:8043/StatusPing" `
                -TimeoutSec 10 -UseBasicParsing -SkipCertificateCheck
            $response.StatusCode -eq 200
        } catch {
            $false
        }
    }
    
    Test-Component -Name "Gateway login page loads" -Critical $true -Test {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8088" `
                -TimeoutSec 10 -UseBasicParsing
            $response.Content -match "Ignition"
        } catch {
            $false
        }
    }
    
    Test-Component -Name "OPC UA port (62541) listening" -Test {
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $tcpClient.Connect("localhost", 62541)
            $connected = $tcpClient.Connected
            $tcpClient.Close()
            $connected
        } catch {
            $false
        }
    }
    
    Test-Component -Name "MQTT port (1883) listening" -Test {
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $tcpClient.Connect("localhost", 1883)
            $connected = $tcpClient.Connected
            $tcpClient.Close()
            $connected
        } catch {
            $false
        }
    }
    
} finally {
    if ($portForward) {
        Stop-Process -Id $portForward.Id -Force 2>$null
    }
}

# ============================================================================
# Gateway Configuration Tests
# ============================================================================

Write-Header "Gateway Configuration Tests"

$podName = kubectl get pods -n $Namespace `
    -l "app.kubernetes.io/name=ignition-edge,app.kubernetes.io/instance=$ReleaseName" `
    -o jsonpath='{.items[0].metadata.name}' 2>&1

if ($podName) {
    Test-Component -Name "Gateway data directory exists" -Test {
        kubectl exec -n $Namespace $podName -- test -d /usr/local/bin/ignition/data
        $LASTEXITCODE -eq 0
    }
    
    Test-Component -Name "Configuration files present" -Test {
        kubectl exec -n $Namespace $podName -- test -f /usr/local/bin/ignition/data/ignition.conf
        $LASTEXITCODE -eq 0
    }
    
    Test-Component -Name "Gateway initialized" -Test {
        kubectl exec -n $Namespace $podName -- test -f /usr/local/bin/ignition/data/.ignition-initialized
        $LASTEXITCODE -eq 0
    }
}

# ============================================================================
# Security Tests
# ============================================================================

Write-Header "Security Tests"

Test-Component -Name "Admin password secret exists" -Critical $true -Test {
    $null = kubectl get secret "$ReleaseName-secret" -n $Namespace 2>&1
    $LASTEXITCODE -eq 0
}

Test-Component -Name "ServiceAccount exists" -Test {
    $null = kubectl get serviceaccount "$ReleaseName" -n $Namespace 2>&1
    $LASTEXITCODE -eq 0
}

Test-Component -Name "RBAC Role exists" -Test {
    $null = kubectl get role "$ReleaseName" -n $Namespace 2>&1
    $LASTEXITCODE -eq 0
}

Test-Component -Name "RBAC RoleBinding exists" -Test {
    $null = kubectl get rolebinding "$ReleaseName" -n $Namespace 2>&1
    $LASTEXITCODE -eq 0
}

# ============================================================================
# Resource Usage Tests
# ============================================================================

Write-Header "Resource Usage Tests"

if ($podName) {
    $memUsage = kubectl top pod $podName -n $Namespace --no-headers 2>&1 | ForEach-Object {
        ($_ -split '\s+')[2]
    }
    
    $cpuUsage = kubectl top pod $podName -n $Namespace --no-headers 2>&1 | ForEach-Object {
        ($_ -split '\s+')[1]
    }
    
    if ($memUsage) {
        Write-Info "Memory Usage: $memUsage"
        Write-Info "CPU Usage: $cpuUsage"
    }
    
    Test-Component -Name "Pod not restarting excessively" -Test {
        $restarts = kubectl get pod $podName -n $Namespace `
            -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>&1
        
        [int]$restarts -lt 5
    }
}

# ============================================================================
# Monitoring Tests
# ============================================================================

Write-Header "Monitoring Tests"

Test-Component -Name "JMX exporter container present" -Test {
    $containers = kubectl get pod $podName -n $Namespace `
        -o jsonpath='{.spec.containers[*].name}' 2>&1
    
    $containers -match "jmx-exporter"
}

$portForward = $null
try {
    $portForward = Start-Process kubectl `
        -ArgumentList "port-forward -n $Namespace pod/$podName 5556:5556" `
        -PassThru -WindowStyle Hidden
    
    Start-Sleep -Seconds 3
    
    Test-Component -Name "Prometheus metrics endpoint" -Test {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:5556/metrics" `
                -TimeoutSec 5 -UseBasicParsing
            $response.Content -match "jvm_memory"
        } catch {
            $false
        }
    }
} finally {
    if ($portForward) {
        Stop-Process -Id $portForward.Id -Force 2>$null
    }
}

# ============================================================================
# Backup Tests
# ============================================================================

Write-Header "Backup Tests"

Test-Component -Name "Backup CronJob exists" -Test {
    $null = kubectl get cronjob "$ReleaseName-backup" -n $Namespace 2>&1
    $LASTEXITCODE -eq 0
}

Test-Component -Name "Backup CronJob schedule valid" -Test {
    $schedule = kubectl get cronjob "$ReleaseName-backup" -n $Namespace `
        -o jsonpath='{.spec.schedule}' 2>&1
    
    $schedule -match '^\S+\s+\S+\s+\S+\s+\S+\s+\S+$'
}

# ============================================================================
# Performance Benchmarks (Optional)
# ============================================================================

if (-not $SkipPerformance) {
    Write-Header "Performance Benchmarks"
    Write-Snark "Grabbing coffee... this might take a minute"
    
    $portForward = $null
    try {
        $portForward = Start-Process kubectl `
            -ArgumentList "port-forward -n $Namespace svc/$ReleaseName 8088:8088" `
            -PassThru -WindowStyle Hidden
        
        Start-Sleep -Seconds 3
        
        # HTTP response time
        Write-Info "Measuring HTTP response time..."
        $responseTimes = @()
        for ($i = 0; $i -lt 10; $i++) {
            $sw = [Diagnostics.Stopwatch]::StartNew()
            try {
                $null = Invoke-WebRequest -Uri "http://localhost:8088/StatusPing" `
                    -TimeoutSec 5 -UseBasicParsing
                $sw.Stop()
                $responseTimes += $sw.ElapsedMilliseconds
            } catch {
                $sw.Stop()
            }
        }
        
        $avgResponseTime = ($responseTimes | Measure-Object -Average).Average
        Write-Info "Average response time: $([math]::Round($avgResponseTime, 2)) ms"
        
        Test-Component -Name "HTTP response time < 500ms" -Test {
            $avgResponseTime -lt 500
        }
        
        Test-Component -Name "HTTP response time < 200ms (excellent)" -Test {
            $avgResponseTime -lt 200
        }
        
    } finally {
        if ($portForward) {
            Stop-Process -Id $portForward.Id -Force 2>$null
        }
    }
}

# ============================================================================
# Test Summary
# ============================================================================

Write-Header "Test Summary"

$totalTests = $script:TestResults.Passed + $script:TestResults.Failed + $script:TestResults.Warnings

Write-Host ""
Write-Host "Total Tests: $totalTests" -ForegroundColor Cyan
Write-Host "Passed:      $($script:TestResults.Passed)" -ForegroundColor Green
Write-Host "Failed:      $($script:TestResults.Failed)" -ForegroundColor Red
Write-Host "Warnings:    $($script:TestResults.Warnings)" -ForegroundColor Yellow
Write-Host ""

$passRate = [math]::Round(($script:TestResults.Passed / $totalTests) * 100, 1)

if ($script:TestResults.Failed -eq 0) {
    Write-Success "All critical tests passed! 🎉"
    Write-Snark "Your gateway is healthier than most production systems I've seen."
} elseif ($script:TestResults.Failed -le 2) {
    Write-Warning "Some tests failed, but gateway is mostly functional"
    Write-Snark "Not perfect, but better than running FactoryTalk on Windows Server 2008."
} else {
    Write-Error "Multiple critical tests failed"
    Write-Snark "Houston, we have a problem. Check the logs above."
    exit 1
}

Write-Host ""
Write-Host "Pass Rate: $passRate%" -ForegroundColor Cyan
Write-Host ""

if ($passRate -ge 90) {
    Write-Snark "Outstanding! Your DevOps game is strong."
} elseif ($passRate -ge 75) {
    Write-Snark "Not bad. Room for improvement, but it'll run."
} else {
    Write-Snark "Yikes. You might want to review the failed tests."
}

Write-Host ""
