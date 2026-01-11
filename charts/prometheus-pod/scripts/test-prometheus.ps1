<#
.SYNOPSIS
    Prometheus Pod Testing Script
    
.DESCRIPTION
    Comprehensive testing for Prometheus Pod deployments.
    Tests scrape targets, alert rules, storage, queries, and HA failover.
    
    Fireball Industries - We Play With Fire So You Don't Have To™
    
.PARAMETER Namespace
    Kubernetes namespace (default: monitoring)
    
.PARAMETER ReleaseName
    Helm release name (default: prometheus)
    
.PARAMETER TestType
    Type of test: all, scraping, alerts, storage, queries, ha-failover
    
.EXAMPLE
    .\test-prometheus.ps1
    Run all tests
    
.EXAMPLE
    .\test-prometheus.ps1 -TestType scraping
    Test only scrape targets
    
.EXAMPLE
    .\test-prometheus.ps1 -TestType ha-failover -Namespace prod-monitoring
    Test HA failover in production namespace
    
.NOTES
    Version: 1.0.0
    Author: Fireball Industries
    Requires: kubectl, curl or wget
#>

param(
    [string]$Namespace = 'monitoring',
    [string]$ReleaseName = 'prometheus',
    [ValidateSet('all', 'scraping', 'alerts', 'storage', 'queries', 'ha-failover')]
    [string]$TestType = 'all'
)

$script:PassedTests = 0
$script:FailedTests = 0
$script:SkippedTests = 0

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Message = ''
    )
    
    if ($Passed) {
        Write-Host "  ✅ $TestName" -ForegroundColor Green
        $script:PassedTests++
    }
    else {
        Write-Host "  ❌ $TestName" -ForegroundColor Red
        if ($Message) {
            Write-Host "     $Message" -ForegroundColor Yellow
        }
        $script:FailedTests++
    }
}

function Write-TestSkipped {
    param([string]$TestName, [string]$Reason)
    
    Write-Host "  ⏭️  $TestName (skipped: $Reason)" -ForegroundColor Yellow
    $script:SkippedTests++
}

function Get-PrometheusPod {
    $pods = kubectl get pods -n $Namespace -l app.kubernetes.io/name=prometheus-pod -o json | ConvertFrom-Json
    return $pods.items
}

function Invoke-PrometheusAPI {
    param(
        [string]$Endpoint,
        [string]$PodName
    )
    
    try {
        $result = kubectl exec -n $Namespace $PodName -- wget -qO- "http://localhost:9090$Endpoint" 2>$null
        return $result | ConvertFrom-Json
    }
    catch {
        return $null
    }
}

function Test-Scraping {
    Write-Host "`n🎯 Testing Scrape Targets" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    
    $pods = Get-PrometheusPod
    
    if ($pods.Count -eq 0) {
        Write-TestResult -TestName "Prometheus pod exists" -Passed $false -Message "No pods found"
        return
    }
    
    $podName = $pods[0].metadata.name
    Write-TestResult -TestName "Prometheus pod exists" -Passed $true
    
    # Get targets
    $targets = Invoke-PrometheusAPI -Endpoint "/api/v1/targets" -PodName $podName
    
    if ($targets.status -eq 'success') {
        Write-TestResult -TestName "Targets API accessible" -Passed $true
        
        $activeTargets = $targets.data.activeTargets
        $totalTargets = $activeTargets.Count
        $healthyTargets = ($activeTargets | Where-Object { $_.health -eq 'up' }).Count
        
        Write-Host "`n  📊 Target Stats:" -ForegroundColor White
        Write-Host "     Total: $totalTargets" -ForegroundColor White
        Write-Host "     Healthy: $healthyTargets" -ForegroundColor Green
        Write-Host "     Unhealthy: $($totalTargets - $healthyTargets)" -ForegroundColor $(if ($totalTargets -eq $healthyTargets) { 'Green' } else { 'Red' })
        
        Write-TestResult -TestName "At least one target is being scraped" -Passed ($totalTargets -gt 0)
        Write-TestResult -TestName "Majority of targets are healthy" -Passed ($healthyTargets -ge ($totalTargets * 0.8))
        
        # Check specific job types
        $jobs = $activeTargets | Group-Object -Property job | Select-Object Name, Count
        
        if ($jobs) {
            Write-Host "`n  🎯 Discovered Jobs:" -ForegroundColor White
            foreach ($job in $jobs) {
                Write-Host "     - $($job.Name): $($job.Count) targets" -ForegroundColor Cyan
            }
        }
        
        # Test scrape of self-monitoring
        $promTargets = $activeTargets | Where-Object { $_.job -eq 'prometheus' }
        Write-TestResult -TestName "Prometheus self-monitoring active" -Passed ($promTargets.Count -gt 0)
        
    }
    else {
        Write-TestResult -TestName "Targets API accessible" -Passed $false -Message $targets.error
    }
}

function Test-Alerts {
    Write-Host "`n🚨 Testing Alert Rules" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    
    $pods = Get-PrometheusPod
    if ($pods.Count -eq 0) {
        Write-TestSkipped -TestName "Alert tests" -Reason "No pods found"
        return
    }
    
    $podName = $pods[0].metadata.name
    
    # Check rules loaded
    $rules = Invoke-PrometheusAPI -Endpoint "/api/v1/rules" -PodName $podName
    
    if ($rules.status -eq 'success') {
        Write-TestResult -TestName "Rules API accessible" -Passed $true
        
        $groups = $rules.data.groups
        $totalRules = ($groups | ForEach-Object { $_.rules.Count } | Measure-Object -Sum).Sum
        
        Write-Host "`n  📋 Rule Stats:" -ForegroundColor White
        Write-Host "     Groups: $($groups.Count)" -ForegroundColor White
        Write-Host "     Total Rules: $totalRules" -ForegroundColor White
        
        Write-TestResult -TestName "Alert rules are loaded" -Passed ($totalRules -gt 0)
        
        # Check for firing alerts
        $alerts = Invoke-PrometheusAPI -Endpoint "/api/v1/alerts" -PodName $podName
        
        if ($alerts.status -eq 'success') {
            $firingAlerts = $alerts.data.alerts | Where-Object { $_.state -eq 'firing' }
            
            Write-Host "     Firing Alerts: $($firingAlerts.Count)" -ForegroundColor $(if ($firingAlerts.Count -eq 0) { 'Green' } else { 'Yellow' })
            
            if ($firingAlerts.Count -gt 0) {
                Write-Host "`n  🔥 Firing Alerts:" -ForegroundColor Yellow
                foreach ($alert in $firingAlerts) {
                    Write-Host "     - $($alert.labels.alertname)" -ForegroundColor Red
                }
            }
            
            Write-TestResult -TestName "Alert evaluation working" -Passed $true
        }
        
    }
    else {
        Write-TestResult -TestName "Rules API accessible" -Passed $false -Message $rules.error
    }
    
    # Test alert manager connectivity
    $am = Invoke-PrometheusAPI -Endpoint "/api/v1/alertmanagers" -PodName $podName
    
    if ($am.status -eq 'success') {
        $activeAMs = $am.data.activeAlertmanagers
        Write-TestResult -TestName "Alertmanager configured" -Passed ($activeAMs.Count -gt 0)
        
        if ($activeAMs.Count -gt 0) {
            $healthyAMs = ($activeAMs | Where-Object { $_.url }).Count
            Write-Host "     Alertmanagers: $healthyAMs/$($activeAMs.Count) healthy" -ForegroundColor $(if ($healthyAMs -eq $activeAMs.Count) { 'Green' } else { 'Yellow' })
        }
    }
}

function Test-Storage {
    Write-Host "`n💾 Testing Storage" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    
    # Check PVC status
    $pvcs = kubectl get pvc -n $Namespace -l app.kubernetes.io/instance=$ReleaseName -o json | ConvertFrom-Json
    
    if ($pvcs.items.Count -eq 0) {
        Write-TestResult -TestName "PVC exists" -Passed $false -Message "No PVCs found"
        return
    }
    
    foreach ($pvc in $pvcs.items) {
        $pvcName = $pvc.metadata.name
        $status = $pvc.status.phase
        
        Write-TestResult -TestName "PVC $pvcName is bound" -Passed ($status -eq 'Bound')
        
        # Check capacity
        $capacity = $pvc.status.capacity.storage
        Write-Host "     Capacity: $capacity" -ForegroundColor Cyan
    }
    
    # Check TSDB stats
    $pods = Get-PrometheusPod
    if ($pods.Count -gt 0) {
        $podName = $pods[0].metadata.name
        
        $tsdb = Invoke-PrometheusAPI -Endpoint "/api/v1/status/tsdb" -PodName $podName
        
        if ($tsdb.status -eq 'success') {
            Write-TestResult -TestName "TSDB status accessible" -Passed $true
            
            Write-Host "`n  📊 TSDB Stats:" -ForegroundColor White
            Write-Host "     Head Stats:" -ForegroundColor Cyan
            Write-Host "       Min Time: $($tsdb.data.headStats.minTime)" -ForegroundColor White
            Write-Host "       Max Time: $($tsdb.data.headStats.maxTime)" -ForegroundColor White
            
            # Check storage metrics
            $storageMetric = Invoke-PrometheusAPI -Endpoint "/api/v1/query?query=prometheus_tsdb_storage_blocks_bytes" -PodName $podName
            
            if ($storageMetric.status -eq 'success' -and $storageMetric.data.result.Count -gt 0) {
                $storageBytes = [int64]$storageMetric.data.result[0].value[1]
                $storageGB = [math]::Round($storageBytes / 1GB, 2)
                
                Write-Host "     Storage Used: $storageGB GB" -ForegroundColor Cyan
                
                Write-TestResult -TestName "Storage metrics available" -Passed $true
            }
        }
    }
}

function Test-Queries {
    Write-Host "`n🔍 Testing Queries" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    
    $pods = Get-PrometheusPod
    if ($pods.Count -eq 0) {
        Write-TestSkipped -TestName "Query tests" -Reason "No pods found"
        return
    }
    
    $podName = $pods[0].metadata.name
    
    # Test basic query
    $testQueries = @(
        @{ Name = "Simple metric query"; Query = "up" }
        @{ Name = "Aggregation query"; Query = "sum(up)" }
        @{ Name = "Range query"; Query = "rate(prometheus_http_requests_total[5m])" }
        @{ Name = "Label filtering"; Query = "up{job='prometheus'}" }
    )
    
    foreach ($test in $testQueries) {
        $encodedQuery = [System.Web.HttpUtility]::UrlEncode($test.Query)
        $result = Invoke-PrometheusAPI -Endpoint "/api/v1/query?query=$encodedQuery" -PodName $podName
        
        $passed = $result.status -eq 'success'
        Write-TestResult -TestName $test.Name -Passed $passed -Message $(if (-not $passed) { $result.error })
        
        if ($passed -and $result.data.result.Count -gt 0) {
            Write-Host "     Results: $($result.data.result.Count)" -ForegroundColor Cyan
        }
    }
    
    # Test query performance
    $perfQuery = "up"
    $encodedQuery = [System.Web.HttpUtility]::UrlEncode($perfQuery)
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $result = Invoke-PrometheusAPI -Endpoint "/api/v1/query?query=$encodedQuery" -PodName $podName
    $stopwatch.Stop()
    
    $queryTime = $stopwatch.ElapsedMilliseconds
    
    Write-Host "`n  ⏱️  Query Performance:" -ForegroundColor White
    Write-Host "     Query time: $queryTime ms" -ForegroundColor Cyan
    
    Write-TestResult -TestName "Query latency acceptable (<1000ms)" -Passed ($queryTime -lt 1000)
}

function Test-HAFailover {
    Write-Host "`n🔄 Testing HA Failover" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    
    $pods = Get-PrometheusPod
    
    if ($pods.Count -lt 2) {
        Write-TestSkipped -TestName "HA failover" -Reason "Not in HA mode (need 2+ replicas)"
        return
    }
    
    Write-Host "  Found $($pods.Count) replicas" -ForegroundColor Cyan
    
    # Check all pods are ready
    $readyPods = ($pods | Where-Object { 
        $_.status.conditions | Where-Object { $_.type -eq 'Ready' -and $_.status -eq 'True' }
    }).Count
    
    Write-TestResult -TestName "All replicas are ready" -Passed ($readyPods -eq $pods.Count)
    
    # Check anti-affinity (pods should be on different nodes)
    $nodeDistribution = $pods | Group-Object -Property { $_.spec.nodeName }
    
    Write-Host "`n  📍 Node Distribution:" -ForegroundColor White
    foreach ($group in $nodeDistribution) {
        Write-Host "     - $($group.Name): $($group.Count) pod(s)" -ForegroundColor Cyan
    }
    
    Write-TestResult -TestName "Pods distributed across nodes" -Passed ($nodeDistribution.Count -eq $pods.Count)
    
    # Check PodDisruptionBudget
    $pdb = kubectl get pdb -n $Namespace -l app.kubernetes.io/instance=$ReleaseName -o json 2>$null | ConvertFrom-Json
    
    if ($pdb.items.Count -gt 0) {
        $pdbItem = $pdb.items[0]
        $minAvailable = $pdbItem.spec.minAvailable
        Write-TestResult -TestName "PodDisruptionBudget configured" -Passed $true
        Write-Host "     Min Available: $minAvailable" -ForegroundColor Cyan
    }
    else {
        Write-TestResult -TestName "PodDisruptionBudget configured" -Passed $false -Message "No PDB found"
    }
    
    # Simulate failover (optional, requires confirmation)
    Write-Host "`n  ⚠️  Failover Simulation Available:" -ForegroundColor Yellow
    Write-Host "     To test failover, manually delete one pod:" -ForegroundColor White
    Write-Host "     kubectl delete pod $($pods[0].metadata.name) -n $Namespace" -ForegroundColor Cyan
    
    $testFailover = Read-Host "`n  Simulate failover now? (y/n)"
    
    if ($testFailover -eq 'y') {
        $targetPod = $pods[0].metadata.name
        Write-Host "`n  🔄 Deleting pod: $targetPod" -ForegroundColor Yellow
        
        kubectl delete pod $targetPod -n $Namespace
        
        Write-Host "  ⏳ Waiting for new pod to be ready..." -ForegroundColor Cyan
        Start-Sleep -Seconds 5
        
        kubectl wait --for=condition=ready pod `
            -l app.kubernetes.io/name=prometheus-pod `
            -n $Namespace `
            --timeout=2m
        
        if ($LASTEXITCODE -eq 0) {
            Write-TestResult -TestName "Failover successful" -Passed $true
            
            # Verify query still works
            $newPods = Get-PrometheusPod
            $newPodName = ($newPods | Where-Object { $_.metadata.name -ne $targetPod })[0].metadata.name
            
            $result = Invoke-PrometheusAPI -Endpoint "/api/v1/query?query=up" -PodName $newPodName
            Write-TestResult -TestName "Service available after failover" -Passed ($result.status -eq 'success')
        }
        else {
            Write-TestResult -TestName "Failover successful" -Passed $false -Message "Pod not ready after 2m"
        }
    }
}

# Main execution
Write-Host @"

╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║   🧪 Prometheus Pod Testing Script                               ║
║   Fireball Industries - We Play With Fire So You Don't Have To™  ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Host "`nNamespace: $Namespace" -ForegroundColor White
Write-Host "Release: $ReleaseName" -ForegroundColor White
Write-Host "Test Type: $TestType`n" -ForegroundColor White

# Run tests based on type
switch ($TestType) {
    'all' {
        Test-Scraping
        Test-Alerts
        Test-Storage
        Test-Queries
        Test-HAFailover
    }
    'scraping' { Test-Scraping }
    'alerts' { Test-Alerts }
    'storage' { Test-Storage }
    'queries' { Test-Queries }
    'ha-failover' { Test-HAFailover }
}

# Summary
Write-Host "`n" -NoNewline
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "📊 Test Summary" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

Write-Host "  ✅ Passed: $script:PassedTests" -ForegroundColor Green
Write-Host "  ❌ Failed: $script:FailedTests" -ForegroundColor Red
Write-Host "  ⏭️  Skipped: $script:SkippedTests" -ForegroundColor Yellow
Write-Host "  📋 Total: $($script:PassedTests + $script:FailedTests + $script:SkippedTests)" -ForegroundColor White

$successRate = if (($script:PassedTests + $script:FailedTests) -gt 0) {
    [math]::Round(($script:PassedTests / ($script:PassedTests + $script:FailedTests)) * 100, 1)
} else { 0 }

Write-Host "`n  Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 80) { 'Green' } elseif ($successRate -ge 50) { 'Yellow' } else { 'Red' })

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

# Exit with appropriate code
if ($script:FailedTests -eq 0) {
    Write-Host "✨ All tests passed!`n" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "⚠️  Some tests failed. Check logs above.`n" -ForegroundColor Yellow
    exit 1
}
