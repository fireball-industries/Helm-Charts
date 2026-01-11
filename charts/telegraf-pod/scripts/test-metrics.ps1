#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Telegraf Metrics Testing and Validation Script
    Fireball Industries

.DESCRIPTION
    Test and validate Telegraf metrics collection across different scenarios.
    Includes output validation, plugin testing, and performance benchmarking.

.EXAMPLE
    .\test-metrics.ps1 -Namespace telegraf-prod

.EXAMPLE
    .\test-metrics.ps1 -Namespace telegraf-prod -Plugin cpu,memory

#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$Namespace = "telegraf",
    
    [Parameter(Mandatory=$false)]
    [string[]]$Plugin = @("cpu", "memory", "disk", "net"),
    
    [Parameter(Mandatory=$false)]
    [int]$Duration = 30,
    
    [Parameter(Mandatory=$false)]
    [switch]$Detailed
)

function Write-TestHeader {
    param([string]$Title)
    Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║ $($Title.PadRight(61)) ║" -ForegroundColor Yellow
    Write-Host "╚═══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Yellow
}

function Test-CPUMetrics {
    Write-TestHeader "Testing CPU Metrics Collection"
    
    $podName = kubectl get pods -n $Namespace -l "app.kubernetes.io/name=telegraf" `
        -o jsonpath='{.items[0].metadata.name}'
    
    Write-Host "Collecting CPU metrics for $Duration seconds...`n"
    
    $output = kubectl exec -n $Namespace $podName -- telegraf --test --config /etc/telegraf/telegraf.conf `
        --input-filter cpu --test-wait $Duration 2>&1
    
    # Parse output
    $cpuMetrics = $output | Select-String -Pattern "cpu," | Measure-Object
    
    Write-Host "✓ Collected $($cpuMetrics.Count) CPU metric samples" -ForegroundColor Green
    
    if ($Detailed) {
        Write-Host "`nSample metrics:"
        $output | Select-String -Pattern "cpu," | Select-Object -First 5
    }
    
    # Validate metric fields
    $requiredFields = @("usage_user", "usage_system", "usage_idle")
    foreach ($field in $requiredFields) {
        $found = $output | Select-String -Pattern $field
        if ($found) {
            Write-Host "  ✓ Field '$field' present" -ForegroundColor Green
        }
        else {
            Write-Host "  ✗ Field '$field' missing" -ForegroundColor Red
        }
    }
}

function Test-MemoryMetrics {
    Write-TestHeader "Testing Memory Metrics Collection"
    
    $podName = kubectl get pods -n $Namespace -l "app.kubernetes.io/name=telegraf" `
        -o jsonpath='{.items[0].metadata.name}'
    
    Write-Host "Collecting memory metrics for $Duration seconds...`n"
    
    $output = kubectl exec -n $Namespace $podName -- telegraf --test --config /etc/telegraf/telegraf.conf `
        --input-filter mem --test-wait $Duration 2>&1
    
    $memMetrics = $output | Select-String -Pattern "mem," | Measure-Object
    
    Write-Host "✓ Collected $($memMetrics.Count) memory metric samples" -ForegroundColor Green
    
    if ($Detailed) {
        Write-Host "`nSample metrics:"
        $output | Select-String -Pattern "mem," | Select-Object -First 5
    }
}

function Test-DiskMetrics {
    Write-TestHeader "Testing Disk Metrics Collection"
    
    $podName = kubectl get pods -n $Namespace -l "app.kubernetes.io/name=telegraf" `
        -o jsonpath='{.items[0].metadata.name}'
    
    Write-Host "Collecting disk metrics for $Duration seconds...`n"
    
    $output = kubectl exec -n $Namespace $podName -- telegraf --test --config /etc/telegraf/telegraf.conf `
        --input-filter disk --test-wait $Duration 2>&1
    
    $diskMetrics = $output | Select-String -Pattern "disk," | Measure-Object
    
    Write-Host "✓ Collected $($diskMetrics.Count) disk metric samples" -ForegroundColor Green
    
    if ($Detailed) {
        Write-Host "`nSample metrics:"
        $output | Select-String -Pattern "disk," | Select-Object -First 5
    }
}

function Test-NetworkMetrics {
    Write-TestHeader "Testing Network Metrics Collection"
    
    $podName = kubectl get pods -n $Namespace -l "app.kubernetes.io/name=telegraf" `
        -o jsonpath='{.items[0].metadata.name}'
    
    Write-Host "Collecting network metrics for $Duration seconds...`n"
    
    $output = kubectl exec -n $Namespace $podName -- telegraf --test --config /etc/telegraf/telegraf.conf `
        --input-filter net --test-wait $Duration 2>&1
    
    $netMetrics = $output | Select-String -Pattern "net," | Measure-Object
    
    Write-Host "✓ Collected $($netMetrics.Count) network metric samples" -ForegroundColor Green
    
    if ($Detailed) {
        Write-Host "`nSample metrics:"
        $output | Select-String -Pattern "net," | Select-Object -First 5
    }
}

function Test-PrometheusOutput {
    Write-TestHeader "Testing Prometheus Output"
    
    $podName = kubectl get pods -n $Namespace -l "app.kubernetes.io/name=telegraf" `
        -o jsonpath='{.items[0].metadata.name}'
    
    Write-Host "Fetching metrics from Prometheus endpoint...`n"
    
    $metrics = kubectl exec -n $Namespace $podName -- wget -q -O- http://localhost:8080/metrics
    
    $metricCount = ($metrics -split "`n" | Where-Object { $_ -notmatch "^#" -and $_.Trim() -ne "" }).Count
    
    Write-Host "✓ Prometheus endpoint returned $metricCount metrics" -ForegroundColor Green
    
    # Check for specific metric families
    $families = @("cpu_usage_system", "mem_used", "disk_free", "net_bytes_sent")
    foreach ($family in $families) {
        $found = $metrics | Select-String -Pattern $family
        if ($found) {
            Write-Host "  ✓ Metric family '$family' found" -ForegroundColor Green
        }
        else {
            Write-Host "  ⚠ Metric family '$family' not found" -ForegroundColor Yellow
        }
    }
    
    if ($Detailed) {
        Write-Host "`nSample metrics from Prometheus endpoint:"
        ($metrics -split "`n" | Where-Object { $_ -notmatch "^#" }) | Select-Object -First 10
    }
}

function Test-KubernetesMetrics {
    Write-TestHeader "Testing Kubernetes Metrics Collection"
    
    $podName = kubectl get pods -n $Namespace -l "app.kubernetes.io/name=telegraf" `
        -o jsonpath='{.items[0].metadata.name}'
    
    Write-Host "Collecting Kubernetes metrics...`n"
    
    $output = kubectl exec -n $Namespace $podName -- telegraf --test --config /etc/telegraf/telegraf.conf `
        --input-filter kube_inventory --test-wait 10 2>&1
    
    $k8sMetrics = $output | Select-String -Pattern "kubernetes" | Measure-Object
    
    if ($k8sMetrics.Count -gt 0) {
        Write-Host "✓ Collected $($k8sMetrics.Count) Kubernetes metric samples" -ForegroundColor Green
    }
    else {
        Write-Host "⚠ No Kubernetes metrics collected (check RBAC permissions)" -ForegroundColor Yellow
    }
    
    if ($Detailed) {
        Write-Host "`nSample Kubernetes metrics:"
        $output | Select-String -Pattern "kubernetes" | Select-Object -First 10
    }
}

function Test-MetricCardinality {
    Write-TestHeader "Analyzing Metric Cardinality"
    
    $podName = kubectl get pods -n $Namespace -l "app.kubernetes.io/name=telegraf" `
        -o jsonpath='{.items[0].metadata.name}'
    
    Write-Host "Collecting all metrics for analysis...`n"
    
    $output = kubectl exec -n $Namespace $podName -- telegraf --test --config /etc/telegraf/telegraf.conf `
        --test-wait 10 2>&1
    
    # Count unique metric names
    $metricNames = $output | Select-String -Pattern "^[a-z_]+" | ForEach-Object {
        ($_ -replace ',.*$', '')
    } | Sort-Object -Unique
    
    Write-Host "✓ Total unique metric names: $($metricNames.Count)" -ForegroundColor Green
    
    # Estimate total cardinality
    $totalLines = ($output | Measure-Object -Line).Lines
    Write-Host "✓ Estimated metrics per interval: ~$totalLines" -ForegroundColor Green
    
    # Calculate daily metric volume
    $interval = 10  # seconds
    $metricsPerDay = ($totalLines / $interval) * 86400
    
    Write-Host "`nProjected daily metric volume: ~$([math]::Round($metricsPerDay / 1000000, 2))M metrics" -ForegroundColor Cyan
    
    if ($metricsPerDay -gt 10000000) {
        Write-Host "⚠ Warning: High metric volume detected" -ForegroundColor Yellow
        Write-Host "  Consider adjusting collection interval or disabling unused plugins" -ForegroundColor Yellow
    }
}

# Main execution
Write-Host @"

╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║           TELEGRAF METRICS TESTING & VALIDATION               ║
║           Fireball Industries - Quality Assurance             ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Yellow

Write-Host "Testing Telegraf instance in namespace: $Namespace`n" -ForegroundColor Cyan
Write-Host "Duration: $Duration seconds per test`n" -ForegroundColor Cyan

# Run plugin-specific tests
if ("cpu" -in $Plugin) { Test-CPUMetrics }
if ("memory" -in $Plugin) { Test-MemoryMetrics }
if ("disk" -in $Plugin) { Test-DiskMetrics }
if ("net" -in $Plugin) { Test-NetworkMetrics }

# Always test output and Kubernetes metrics
Test-PrometheusOutput
Test-KubernetesMetrics
Test-MetricCardinality

Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                   TESTING COMPLETE                            ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green
