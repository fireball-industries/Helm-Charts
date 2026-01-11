<#
.SYNOPSIS
    Test Fireball Node Exporter deployment and validate metrics collection.

.DESCRIPTION
    Comprehensive testing script for Node Exporter deployment validation.
    Tests DaemonSet deployment, metrics endpoints, collector functionality, and performance.

.PARAMETER Namespace
    Kubernetes namespace (default: monitoring)

.PARAMETER ReleaseName
    Helm release name (default: node-exporter)

.EXAMPLE
    .\test-node-exporter.ps1
    .\test-node-exporter.ps1 -Namespace monitoring -ReleaseName node-exporter

.NOTES
    Author: Patrick Ryan - Fireball Industries
    Testing monitoring infrastructure - because trust but verify.
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$Namespace = "monitoring",
    
    [Parameter(Mandatory=$false)]
    [string]$ReleaseName = "node-exporter"
)

# Color output functions
function Write-Success { param([string]$Message) Write-Host "✓ $Message" -ForegroundColor Green }
function Write-Info { param([string]$Message) Write-Host "ℹ $Message" -ForegroundColor Cyan }
function Write-Warning2 { param([string]$Message) Write-Host "⚠ $Message" -ForegroundColor Yellow }
function Write-Error2 { param([string]$Message) Write-Host "✗ $Message" -ForegroundColor Red }
function Write-Test { param([string]$Message) Write-Host "🧪 $Message" -ForegroundColor Magenta }

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

$script:TestResults = @{
    Passed = 0
    Failed = 0
    Warnings = 0
    Tests = @()
}

function Add-TestResult {
    param(
        [string]$TestName,
        [string]$Status,  # Pass, Fail, Warning
        [string]$Message
    )
    
    $script:TestResults.Tests += @{
        Name = $TestName
        Status = $Status
        Message = $Message
    }
    
    switch ($Status) {
        "Pass" { $script:TestResults.Passed++ }
        "Fail" { $script:TestResults.Failed++ }
        "Warning" { $script:TestResults.Warnings++ }
    }
}

# Test 1: Helm release exists
function Test-HelmRelease {
    Write-Header "Test 1: Helm Release Validation"
    
    $release = helm list -n $Namespace -o json | ConvertFrom-Json | Where-Object { $_.name -eq $ReleaseName }
    
    if ($release) {
        Write-Success "Helm release '$ReleaseName' found in namespace '$Namespace'"
        Write-Info "Status: $($release.status)"
        Write-Info "Chart: $($release.chart)"
        Write-Info "App Version: $($release.app_version)"
        Add-TestResult "Helm Release" "Pass" "Release found and deployed"
    } else {
        Write-Error2 "Helm release '$ReleaseName' not found in namespace '$Namespace'"
        Add-TestResult "Helm Release" "Fail" "Release not found"
    }
}

# Test 2: Pod deployment
function Test-PodDeployment {
    Write-Header "Test 2: Pod Deployment Validation"
    
    $pods = kubectl get pods -n $Namespace -l app.kubernetes.io/name=fireball-node-exporter -o json | ConvertFrom-Json
    $totalPods = $pods.items.Count
    $runningPods = ($pods.items | Where-Object { $_.status.phase -eq "Running" }).Count
    $nodes = kubectl get nodes -o json | ConvertFrom-Json
    $totalNodes = $nodes.items.Count
    
    Write-Info "Total nodes in cluster: $totalNodes"
    Write-Info "Total Node Exporter pods: $totalPods"
    Write-Info "Running pods: $runningPods"
    
    # Check if DaemonSet (should have pod on each node)
    $values = helm get values $ReleaseName -n $Namespace -o json | ConvertFrom-Json
    $deploymentMode = if ($values.deploymentMode) { $values.deploymentMode } else { "daemonset" }
    
    if ($deploymentMode -eq "daemonset") {
        if ($runningPods -eq $totalNodes) {
            Write-Success "DaemonSet deployed correctly: $runningPods/$totalNodes nodes covered"
            Add-TestResult "Pod Deployment" "Pass" "All nodes have running pods"
        } elseif ($runningPods -gt 0) {
            Write-Warning2 "DaemonSet partially deployed: $runningPods/$totalNodes nodes covered"
            Write-Warning2 "Some nodes may have taints or node selectors preventing deployment"
            Add-TestResult "Pod Deployment" "Warning" "Not all nodes covered"
        } else {
            Write-Error2 "No pods are running!"
            Add-TestResult "Pod Deployment" "Fail" "No running pods"
        }
    } else {
        if ($runningPods -gt 0) {
            Write-Success "Deployment mode ($deploymentMode): $runningPods pods running"
            Add-TestResult "Pod Deployment" "Pass" "Pods running in $deploymentMode mode"
        } else {
            Write-Error2 "No pods are running in $deploymentMode mode!"
            Add-TestResult "Pod Deployment" "Fail" "No running pods"
        }
    }
    
    # List pods
    Write-Host ""
    Write-Info "Pod distribution:"
    kubectl get pods -n $Namespace -l app.kubernetes.io/name=fireball-node-exporter -o wide
}

# Test 3: Metrics endpoint connectivity
function Test-MetricsEndpoint {
    Write-Header "Test 3: Metrics Endpoint Connectivity"
    
    $pods = kubectl get pods -n $Namespace -l app.kubernetes.io/name=fireball-node-exporter -o json | ConvertFrom-Json
    $testPod = $pods.items[0].metadata.name
    
    if (-not $testPod) {
        Write-Error2 "No pods available for testing"
        Add-TestResult "Metrics Endpoint" "Fail" "No pods available"
        return
    }
    
    Write-Info "Testing metrics endpoint on pod: $testPod"
    
    # Port forward
    $portForwardProcess = Start-Process kubectl -ArgumentList "port-forward -n $Namespace $testPod 9100:9100" -PassThru -NoNewWindow
    Start-Sleep -Seconds 3
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:9100/metrics" -UseBasicParsing -TimeoutSec 10
        
        if ($response.StatusCode -eq 200) {
            Write-Success "Metrics endpoint accessible (HTTP $($response.StatusCode))"
            $metricsCount = ($response.Content -split "`n" | Where-Object { $_ -match '^node_' }).Count
            Write-Info "Metrics returned: ~$metricsCount node metrics"
            Add-TestResult "Metrics Endpoint" "Pass" "Endpoint accessible with $metricsCount metrics"
        } else {
            Write-Error2 "Unexpected HTTP status: $($response.StatusCode)"
            Add-TestResult "Metrics Endpoint" "Fail" "HTTP $($response.StatusCode)"
        }
    } catch {
        Write-Error2 "Cannot connect to metrics endpoint: $_"
        Add-TestResult "Metrics Endpoint" "Fail" "Connection failed"
    } finally {
        Stop-Process -Id $portForwardProcess.Id -Force -ErrorAction SilentlyContinue
    }
}

# Test 4: Collector functionality
function Test-Collectors {
    Write-Header "Test 4: Collector Functionality"
    
    $pods = kubectl get pods -n $Namespace -l app.kubernetes.io/name=fireball-node-exporter -o json | ConvertFrom-Json
    $testPod = $pods.items[0].metadata.name
    
    $portForwardProcess = Start-Process kubectl -ArgumentList "port-forward -n $Namespace $testPod 9100:9100" -PassThru -NoNewWindow
    Start-Sleep -Seconds 3
    
    try {
        $metrics = (Invoke-WebRequest -Uri "http://localhost:9100/metrics" -UseBasicParsing).Content
        
        # Test essential collectors
        $collectors = @{
            "cpu" = "node_cpu_seconds_total"
            "memory" = "node_memory_MemTotal_bytes"
            "disk" = "node_disk_read_bytes_total"
            "network" = "node_network_receive_bytes_total"
            "filesystem" = "node_filesystem_size_bytes"
            "load" = "node_load1"
        }
        
        Write-Info "Testing essential collectors:"
        Write-Host ""
        
        foreach ($collector in $collectors.GetEnumerator()) {
            if ($metrics -match $collector.Value) {
                Write-Success "$($collector.Key): ✓ ($($collector.Value) found)"
            } else {
                Write-Warning2 "$($collector.Key): ✗ ($($collector.Value) not found)"
            }
        }
        
        Add-TestResult "Collectors" "Pass" "Essential collectors functional"
        
    } catch {
        Write-Error2 "Failed to test collectors: $_"
        Add-TestResult "Collectors" "Fail" "Cannot retrieve metrics"
    } finally {
        Stop-Process -Id $portForwardProcess.Id -Force -ErrorAction SilentlyContinue
    }
}

# Test 5: Scrape time validation
function Test-ScrapeTime {
    Write-Header "Test 5: Scrape Time Performance"
    
    $pods = kubectl get pods -n $Namespace -l app.kubernetes.io/name=fireball-node-exporter -o json | ConvertFrom-Json
    $testPod = $pods.items[0].metadata.name
    
    $portForwardProcess = Start-Process kubectl -ArgumentList "port-forward -n $Namespace $testPod 9100:9100" -PassThru -NoNewWindow
    Start-Sleep -Seconds 3
    
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $response = Invoke-WebRequest -Uri "http://localhost:9100/metrics" -UseBasicParsing
        $stopwatch.Stop()
        
        $scrapeTime = $stopwatch.ElapsedMilliseconds
        
        Write-Info "Scrape time: ${scrapeTime}ms"
        
        if ($scrapeTime -lt 500) {
            Write-Success "Excellent scrape performance (<500ms)"
            Add-TestResult "Scrape Time" "Pass" "${scrapeTime}ms - Excellent"
        } elseif ($scrapeTime -lt 1000) {
            Write-Success "Good scrape performance (<1s)"
            Add-TestResult "Scrape Time" "Pass" "${scrapeTime}ms - Good"
        } else {
            Write-Warning2 "Slow scrape time (>1s) - consider reducing collectors"
            Add-TestResult "Scrape Time" "Warning" "${scrapeTime}ms - Slow"
        }
        
    } catch {
        Write-Error2 "Failed to measure scrape time: $_"
        Add-TestResult "Scrape Time" "Fail" "Cannot measure"
    } finally {
        Stop-Process -Id $portForwardProcess.Id -Force -ErrorAction SilentlyContinue
    }
}

# Test 6: Service Monitor (if enabled)
function Test-ServiceMonitor {
    Write-Header "Test 6: ServiceMonitor Validation"
    
    $sm = kubectl get servicemonitor -n $Namespace -l app.kubernetes.io/name=fireball-node-exporter -o json 2>$null | ConvertFrom-Json
    
    if ($sm.items.Count -gt 0) {
        Write-Success "ServiceMonitor found: $($sm.items[0].metadata.name)"
        Write-Info "Scrape interval: $($sm.items[0].spec.endpoints[0].interval)"
        Write-Info "Scrape timeout: $($sm.items[0].spec.endpoints[0].scrapeTimeout)"
        Add-TestResult "ServiceMonitor" "Pass" "ServiceMonitor configured"
    } else {
        Write-Info "ServiceMonitor not enabled (optional)"
        Add-TestResult "ServiceMonitor" "Pass" "Not enabled (optional)"
    }
}

# Test 7: RBAC validation
function Test-RBAC {
    Write-Header "Test 7: RBAC Configuration"
    
    $clusterRole = kubectl get clusterrole -l app.kubernetes.io/name=fireball-node-exporter -o json | ConvertFrom-Json
    $clusterRoleBinding = kubectl get clusterrolebinding -l app.kubernetes.io/name=fireball-node-exporter -o json | ConvertFrom-Json
    
    if ($clusterRole.items.Count -gt 0) {
        Write-Success "ClusterRole found: $($clusterRole.items[0].metadata.name)"
    } else {
        Write-Error2 "ClusterRole not found"
    }
    
    if ($clusterRoleBinding.items.Count -gt 0) {
        Write-Success "ClusterRoleBinding found: $($clusterRoleBinding.items[0].metadata.name)"
        Add-TestResult "RBAC" "Pass" "RBAC configured correctly"
    } else {
        Write-Error2 "ClusterRoleBinding not found"
        Add-TestResult "RBAC" "Fail" "Missing RBAC resources"
    }
}

# Test 8: Resource usage
function Test-ResourceUsage {
    Write-Header "Test 8: Resource Usage Analysis"
    
    $pods = kubectl get pods -n $Namespace -l app.kubernetes.io/name=fireball-node-exporter -o json | ConvertFrom-Json
    
    Write-Info "Analyzing resource requests and limits:"
    Write-Host ""
    
    foreach ($pod in $pods.items | Select-Object -First 3) {
        $podName = $pod.metadata.name
        $container = $pod.spec.containers[0]
        
        Write-Info "Pod: $podName"
        
        if ($container.resources.requests) {
            Write-Host "  CPU Request: $($container.resources.requests.cpu)" -ForegroundColor Gray
            Write-Host "  Memory Request: $($container.resources.requests.memory)" -ForegroundColor Gray
        }
        
        if ($container.resources.limits) {
            Write-Host "  CPU Limit: $($container.resources.limits.cpu)" -ForegroundColor Gray
            Write-Host "  Memory Limit: $($container.resources.limits.memory)" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    Add-TestResult "Resource Usage" "Pass" "Resources configured"
}

# Display final results
function Show-TestSummary {
    Write-Header "Test Summary"
    
    Write-Info "Total Tests Run: $($script:TestResults.Tests.Count)"
    Write-Success "Passed: $($script:TestResults.Passed)"
    
    if ($script:TestResults.Warnings -gt 0) {
        Write-Warning2 "Warnings: $($script:TestResults.Warnings)"
    }
    
    if ($script:TestResults.Failed -gt 0) {
        Write-Error2 "Failed: $($script:TestResults.Failed)"
    }
    
    Write-Host ""
    Write-Host "Detailed Results:" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Cyan
    
    foreach ($test in $script:TestResults.Tests) {
        $icon = switch ($test.Status) {
            "Pass" { "✓"; $color = "Green" }
            "Fail" { "✗"; $color = "Red" }
            "Warning" { "⚠"; $color = "Yellow" }
        }
        
        Write-Host "$icon $($test.Name): " -NoNewline -ForegroundColor $color
        Write-Host "$($test.Message)" -ForegroundColor Gray
    }
    
    Write-Host ""
    
    if ($script:TestResults.Failed -eq 0) {
        Write-Success "All critical tests passed! Your Node Exporter is working."
        Write-Host "Now set up alerts before your hardware decides to die." -ForegroundColor Magenta
    } else {
        Write-Error2 "Some tests failed. Check the details above and fix the issues."
    }
    
    Write-Host ""
}

# Main execution
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                               ║" -ForegroundColor Cyan
Write-Host "║     FIREBALL NODE EXPORTER TEST SUITE                         ║" -ForegroundColor Cyan
Write-Host "║     Comprehensive validation and testing                      ║" -ForegroundColor Cyan
Write-Host "║                                                               ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Info "Testing deployment: $ReleaseName in namespace: $Namespace"
Write-Host ""

# Run all tests
Test-HelmRelease
Test-PodDeployment
Test-MetricsEndpoint
Test-Collectors
Test-ScrapeTime
Test-ServiceMonitor
Test-RBAC
Test-ResourceUsage

# Show summary
Show-TestSummary
