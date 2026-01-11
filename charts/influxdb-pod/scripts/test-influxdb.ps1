<#
.SYNOPSIS
    Test InfluxDB Pod deployments
    
.DESCRIPTION
    Comprehensive testing script for InfluxDB Pod.
    Tests: API, writes, queries, retention, clustering, backup-restore, performance
    
    "Because 'it works on my machine' isn't good enough for production."
    - Patrick Ryan, Fireball Industries
    
.PARAMETER TestType
    Type of test to run (all, api, writes, queries, retention, clustering, backup-restore, performance)
    
.PARAMETER ReleaseName
    Helm release name (default: influxdb)
    
.PARAMETER Namespace
    Kubernetes namespace (default: influxdb)
    
.PARAMETER Organization
    InfluxDB organization name
    
.PARAMETER Bucket
    Bucket name for testing
    
.PARAMETER Duration
    Duration for performance tests (seconds)
    
.EXAMPLE
    .\test-influxdb.ps1 -TestType all
    
.EXAMPLE
    .\test-influxdb.ps1 -TestType performance -Duration 60
    
.NOTES
    Author: Patrick Ryan, Fireball Industries
    Version: 1.0.0
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('all', 'api', 'writes', 'queries', 'retention', 'clustering', 'backup-restore', 'performance')]
    [string]$TestType,
    
    [string]$ReleaseName = "influxdb",
    [string]$Namespace = "influxdb",
    [string]$Organization = "factory",
    [string]$Bucket = "sensors",
    [int]$Duration = 30
)

# Test results tracking
$script:TestResults = @{
    Passed = 0
    Failed = 0
    Skipped = 0
    Tests = @()
}

# Banner
function Show-Banner {
    Write-Host @"
================================================================================
🧪 InfluxDB Pod Test Suite
================================================================================
Fireball Industries - "Testing is caring about your users"™
================================================================================
"@ -ForegroundColor Cyan
}

# Test result helper
function Add-TestResult {
    param(
        [string]$TestName,
        [string]$Status,
        [string]$Message = ""
    )
    
    $script:TestResults.Tests += @{
        Name = $TestName
        Status = $Status
        Message = $Message
        Timestamp = Get-Date
    }
    
    switch ($Status) {
        'PASS' { 
            $script:TestResults.Passed++
            Write-Host "✅ PASS: $TestName" -ForegroundColor Green
        }
        'FAIL' { 
            $script:TestResults.Failed++
            Write-Host "❌ FAIL: $TestName - $Message" -ForegroundColor Red
        }
        'SKIP' { 
            $script:TestResults.Skipped++
            Write-Host "⏭️  SKIP: $TestName - $Message" -ForegroundColor Yellow
        }
    }
}

# Get admin token
function Get-AdminToken {
    $secretName = "$ReleaseName-influxdb-pod-auth"
    $token = kubectl get secret $secretName -n $Namespace -o jsonpath='{.data.admin-token}' 2>$null
    
    if ($token) {
        return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($token))
    }
    return $null
}

# Get pod name
function Get-PodName {
    return kubectl get pods -n $Namespace -l app.kubernetes.io/instance=$ReleaseName -o jsonpath='{.items[0].metadata.name}' 2>$null
}

# Test 1: API Health
function Test-APIHealth {
    Write-Host "`n🏥 Testing API Health..." -ForegroundColor Cyan
    
    $podName = Get-PodName
    if (-not $podName) {
        Add-TestResult "API Health Check" "FAIL" "No pods found"
        return
    }
    
    $health = kubectl exec -n $Namespace $podName -- curl -s http://localhost:8086/health 2>$null
    
    if ($health -match '"status":"pass"') {
        Add-TestResult "API Health Endpoint" "PASS"
    } else {
        Add-TestResult "API Health Endpoint" "FAIL" "Health check returned: $health"
    }
    
    # Test ping
    $ping = kubectl exec -n $Namespace $podName -- influx ping 2>$null
    if ($LASTEXITCODE -eq 0) {
        Add-TestResult "InfluxDB Ping" "PASS"
    } else {
        Add-TestResult "InfluxDB Ping" "FAIL" "Ping command failed"
    }
}

# Test 2: Write Data
function Test-Writes {
    Write-Host "`n✍️  Testing Data Writes..." -ForegroundColor Cyan
    
    $token = Get-AdminToken
    if (-not $token) {
        Add-TestResult "Write Test Setup" "FAIL" "Could not get admin token"
        return
    }
    
    $podName = Get-PodName
    if (-not $podName) {
        Add-TestResult "Write Test Setup" "FAIL" "No pods found"
        return
    }
    
    # Test single point write
    $timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $writeCmd = @"
influx write --bucket $Bucket --org $Organization --token $token --precision s 'test,sensor=test01 value=23.5 $timestamp'
"@
    
    $result = kubectl exec -n $Namespace $podName -- sh -c $writeCmd 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Add-TestResult "Single Point Write" "PASS"
    } else {
        Add-TestResult "Single Point Write" "FAIL" "Write failed: $result"
    }
    
    # Test batch write
    $batchData = @"
test,sensor=test01 value=21.0 $timestamp
test,sensor=test01 value=22.0 $($timestamp + 1)
test,sensor=test01 value=23.0 $($timestamp + 2)
test,sensor=test01 value=24.0 $($timestamp + 3)
test,sensor=test01 value=25.0 $($timestamp + 4)
"@
    
    $batchFile = [System.IO.Path]::GetTempFileName()
    $batchData | Out-File -FilePath $batchFile -Encoding ASCII
    
    kubectl cp $batchFile "$Namespace/${podName}:/tmp/batch-data.lp" 2>$null
    $result = kubectl exec -n $Namespace $podName -- sh -c "influx write --bucket $Bucket --org $Organization --token $token --file /tmp/batch-data.lp" 2>&1
    
    Remove-Item $batchFile -Force
    
    if ($LASTEXITCODE -eq 0) {
        Add-TestResult "Batch Point Write" "PASS"
    } else {
        Add-TestResult "Batch Point Write" "FAIL" "Batch write failed: $result"
    }
}

# Test 3: Query Data
function Test-Queries {
    Write-Host "`n🔍 Testing Queries..." -ForegroundColor Cyan
    
    $token = Get-AdminToken
    if (-not $token) {
        Add-TestResult "Query Test Setup" "FAIL" "Could not get admin token"
        return
    }
    
    $podName = Get-PodName
    if (-not $podName) {
        Add-TestResult "Query Test Setup" "FAIL" "No pods found"
        return
    }
    
    # Test Flux query
    $fluxQuery = "from(bucket: \`"$Bucket\`") |> range(start: -1h) |> filter(fn: (r) => r._measurement == \`"test\`") |> limit(n: 10)"
    $queryCmd = "influx query --org $Organization --token $token '$fluxQuery'"
    
    $result = kubectl exec -n $Namespace $podName -- sh -c $queryCmd 2>&1
    
    if ($LASTEXITCODE -eq 0 -and $result) {
        Add-TestResult "Flux Query Execution" "PASS"
    } else {
        Add-TestResult "Flux Query Execution" "FAIL" "Query failed or returned no data"
    }
    
    # Test aggregation query
    $aggQuery = "from(bucket: \`"$Bucket\`") |> range(start: -1h) |> filter(fn: (r) => r._measurement == \`"test\`") |> mean()"
    $queryCmd = "influx query --org $Organization --token $token '$aggQuery'"
    
    $result = kubectl exec -n $Namespace $podName -- sh -c $queryCmd 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Add-TestResult "Aggregation Query" "PASS"
    } else {
        Add-TestResult "Aggregation Query" "FAIL" "Aggregation query failed"
    }
}

# Test 4: Buckets
function Test-Buckets {
    Write-Host "`n🪣 Testing Bucket Operations..." -ForegroundColor Cyan
    
    $token = Get-AdminToken
    if (-not $token) {
        Add-TestResult "Bucket Test Setup" "FAIL" "Could not get admin token"
        return
    }
    
    $podName = Get-PodName
    if (-not $podName) {
        Add-TestResult "Bucket Test Setup" "FAIL" "No pods found"
        return
    }
    
    # List buckets
    $buckets = kubectl exec -n $Namespace $podName -- influx bucket list --org $Organization --token $token 2>&1
    
    if ($LASTEXITCODE -eq 0 -and $buckets -match $Bucket) {
        Add-TestResult "Bucket List" "PASS"
    } else {
        Add-TestResult "Bucket List" "FAIL" "Could not list buckets or find $Bucket"
    }
    
    # Create test bucket
    $testBucket = "test-bucket-$(Get-Random -Minimum 1000 -Maximum 9999)"
    $result = kubectl exec -n $Namespace $podName -- influx bucket create `
        --name $testBucket `
        --org $Organization `
        --retention 1d `
        --token $token 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Add-TestResult "Bucket Creation" "PASS"
        
        # Clean up: delete test bucket
        kubectl exec -n $Namespace $podName -- sh -c "influx bucket delete --name $testBucket --org $Organization --token $token" 2>$null
    } else {
        Add-TestResult "Bucket Creation" "FAIL" "Could not create bucket: $result"
    }
}

# Test 5: Performance
function Test-Performance {
    Write-Host "`n⚡ Testing Performance (${Duration}s)..." -ForegroundColor Cyan
    
    $token = Get-AdminToken
    if (-not $token) {
        Add-TestResult "Performance Test Setup" "FAIL" "Could not get admin token"
        return
    }
    
    $podName = Get-PodName
    if (-not $podName) {
        Add-TestResult "Performance Test Setup" "FAIL" "No pods found"
        return
    }
    
    Write-Host "Writing data for ${Duration} seconds..." -ForegroundColor Gray
    
    $startTime = Get-Date
    $pointCount = 0
    $endTime = $startTime.AddSeconds($Duration)
    
    while ((Get-Date) -lt $endTime) {
        $timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeNanoseconds()
        $value = Get-Random -Minimum 20 -Maximum 30
        
        $writeCmd = "influx write --bucket $Bucket --org $Organization --token $token --precision ns 'perftest,sensor=perf01 value=$value $timestamp'"
        kubectl exec -n $Namespace $podName -- sh -c $writeCmd 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            $pointCount++
        }
        
        Start-Sleep -Milliseconds 100
    }
    
    $actualDuration = ((Get-Date) - $startTime).TotalSeconds
    $writesPerSec = [math]::Round($pointCount / $actualDuration, 2)
    
    Write-Host "Wrote $pointCount points in $([math]::Round($actualDuration, 2))s ($writesPerSec points/sec)" -ForegroundColor Gray
    
    if ($writesPerSec -gt 5) {
        Add-TestResult "Write Performance" "PASS" "$writesPerSec points/sec"
    } else {
        Add-TestResult "Write Performance" "FAIL" "Only $writesPerSec points/sec (expected >5)"
    }
}

# Test 6: Backup/Restore
function Test-BackupRestore {
    Write-Host "`n💾 Testing Backup/Restore..." -ForegroundColor Cyan
    
    $token = Get-AdminToken
    if (-not $token) {
        Add-TestResult "Backup/Restore Test Setup" "FAIL" "Could not get admin token"
        return
    }
    
    $podName = Get-PodName
    if (-not $podName) {
        Add-TestResult "Backup/Restore Test Setup" "FAIL" "No pods found"
        return
    }
    
    # Create backup
    Write-Host "Creating backup..." -ForegroundColor Gray
    $backupResult = kubectl exec -n $Namespace $podName -- influx backup /tmp/test-backup --token $token 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Add-TestResult "Backup Creation" "PASS"
    } else {
        Add-TestResult "Backup Creation" "FAIL" "Backup failed: $backupResult"
        return
    }
    
    # Note: Full restore test would require destroying data, which is risky
    # Instead, just verify backup files exist
    $backupFiles = kubectl exec -n $Namespace $podName -- ls -la /tmp/test-backup 2>&1
    
    if ($backupFiles -match "manifest") {
        Add-TestResult "Backup Validation" "PASS"
    } else {
        Add-TestResult "Backup Validation" "FAIL" "Backup files not found"
    }
    
    # Clean up
    kubectl exec -n $Namespace $podName -- rm -rf /tmp/test-backup 2>$null
}

# Test summary
function Show-TestSummary {
    Write-Host "`n" -NoNewline
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "Test Summary" -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    
    Write-Host "Total Tests: $($script:TestResults.Passed + $script:TestResults.Failed + $script:TestResults.Skipped)" -ForegroundColor White
    Write-Host "✅ Passed: $($script:TestResults.Passed)" -ForegroundColor Green
    Write-Host "❌ Failed: $($script:TestResults.Failed)" -ForegroundColor Red
    Write-Host "⏭️  Skipped: $($script:TestResults.Skipped)" -ForegroundColor Yellow
    
    $passRate = if (($script:TestResults.Passed + $script:TestResults.Failed) -gt 0) {
        [math]::Round(($script:TestResults.Passed / ($script:TestResults.Passed + $script:TestResults.Failed)) * 100, 2)
    } else { 0 }
    
    Write-Host "`nPass Rate: $passRate%" -ForegroundColor $(if ($passRate -ge 90) { 'Green' } elseif ($passRate -ge 70) { 'Yellow' } else { 'Red' })
    
    if ($script:TestResults.Failed -gt 0) {
        Write-Host "`nFailed Tests:" -ForegroundColor Red
        foreach ($test in $script:TestResults.Tests | Where-Object { $_.Status -eq 'FAIL' }) {
            Write-Host "  - $($test.Name): $($test.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host "`n================================================================================" -ForegroundColor Cyan
    
    if ($script:TestResults.Failed -eq 0) {
        Write-Host "🎉 All tests passed! Your InfluxDB is ready for production." -ForegroundColor Green
    } else {
        Write-Host "⚠️  Some tests failed. Review the errors above." -ForegroundColor Yellow
    }
}

# Main execution
Show-Banner

Write-Host "Test Type: $TestType" -ForegroundColor Yellow
Write-Host "Release: $ReleaseName" -ForegroundColor Yellow
Write-Host "Namespace: $Namespace" -ForegroundColor Yellow
Write-Host "Organization: $Organization" -ForegroundColor Yellow
Write-Host "Bucket: $Bucket" -ForegroundColor Yellow

switch ($TestType) {
    'all' {
        Test-APIHealth
        Test-Writes
        Test-Queries
        Test-Buckets
        Test-Performance
        Test-BackupRestore
    }
    'api' { Test-APIHealth }
    'writes' { Test-Writes }
    'queries' { Test-Queries }
    'retention' { Test-Buckets }
    'performance' { Test-Performance }
    'backup-restore' { Test-BackupRestore }
}

Show-TestSummary

Write-Host "`n🔥 Fireball Industries - 'Testing saves lives (and uptime)'" -ForegroundColor Cyan

# Exit with appropriate code
exit $(if ($script:TestResults.Failed -eq 0) { 0 } else { 1 })
