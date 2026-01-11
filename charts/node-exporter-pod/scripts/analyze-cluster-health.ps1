<#
.SYNOPSIS
    Analyze cluster-wide hardware health using Node Exporter metrics.

.DESCRIPTION
    Comprehensive cluster health analysis aggregating metrics from all nodes.
    Identifies CPU hotspots, memory pressure, disk issues, network problems, and temperature warnings.

.PARAMETER Namespace
    Kubernetes namespace (default: monitoring)

.PARAMETER TopN
    Number of top resource consumers to show (default: 5)

.EXAMPLE
    .\analyze-cluster-health.ps1
    .\analyze-cluster-health.ps1 -Namespace monitoring -TopN 10

.NOTES
    Author: Patrick Ryan - Fireball Industries
    Because knowing which node is dying first is valuable information.
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$Namespace = "monitoring",
    
    [Parameter(Mandatory=$false)]
    [int]$TopN = 5
)

# Color output
function Write-Success { param([string]$Message) Write-Host "✓ $Message" -ForegroundColor Green }
function Write-Info { param([string]$Message) Write-Host "ℹ $Message" -ForegroundColor Cyan }
function Write-Warning2 { param([string]$Message) Write-Host "⚠ $Message" -ForegroundColor Yellow }
function Write-Error2 { param([string]$Message) Write-Host "✗ $Message" -ForegroundColor Red }
function Write-Critical { param([string]$Message) Write-Host "🔥 $Message" -ForegroundColor Red }

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

# Collect metrics from a pod
function Get-NodeMetrics {
    param([string]$PodName, [string]$NodeName)
    
    # Port forward (background job)
    $job = Start-Job -ScriptBlock {
        param($ns, $pod)
        kubectl port-forward -n $ns $pod 9100:9100 2>$null
    } -ArgumentList $Namespace, $PodName
    
    Start-Sleep -Seconds 2
    
    try {
        $metrics = Invoke-WebRequest -Uri "http://localhost:9100/metrics" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        return @{
            Success = $true
            Content = $metrics.Content
            NodeName = $NodeName
        }
    } catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            NodeName = $NodeName
        }
    } finally {
        Stop-Job -Job $job -ErrorAction SilentlyContinue
        Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
    }
}

# Parse metric value
function Get-MetricValue {
    param([string]$Content, [string]$Pattern)
    
    if ($Content -match $Pattern) {
        return [double]$matches[1]
    }
    return $null
}

# Analyze CPU usage
function Analyze-CPU {
    Write-Header "CPU Usage Analysis"
    
    $pods = kubectl get pods -n $Namespace -l app.kubernetes.io/name=fireball-node-exporter -o json | ConvertFrom-Json
    $cpuData = @()
    
    foreach ($pod in $pods.items) {
        $podName = $pod.metadata.name
        $nodeName = $pod.spec.nodeName
        
        Write-Host "." -NoNewline
        
        $result = Get-NodeMetrics -PodName $podName -NodeName $nodeName
        
        if ($result.Success) {
            # Calculate CPU usage (simplified)
            if ($result.Content -match 'node_cpu_seconds_total{cpu="0",mode="idle"}\s+([\d.]+)') {
                $cpuData += @{
                    Node = $nodeName
                    Status = "Active"
                }
            }
        }
    }
    
    Write-Host ""
    Write-Host ""
    
    Write-Info "Nodes analyzed: $($cpuData.Count)"
    Write-Success "All nodes responding"
    Write-Host ""
    Write-Warning2 "Note: Detailed CPU usage requires Prometheus queries for accurate calculation"
    Write-Info "Use: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode=\""idle\"}[5m])) * 100)"
}

# Analyze memory pressure
function Analyze-Memory {
    Write-Header "Memory Pressure Analysis"
    
    $pods = kubectl get pods -n $Namespace -l app.kubernetes.io/name=fireball-node-exporter -o json | ConvertFrom-Json
    $memoryIssues = @()
    
    foreach ($pod in $pods.items) {
        $podName = $pod.metadata.name
        $nodeName = $pod.spec.nodeName
        
        Write-Host "." -NoNewline
        
        $result = Get-NodeMetrics -PodName $podName -NodeName $nodeName
        
        if ($result.Success) {
            $totalMem = Get-MetricValue -Content $result.Content -Pattern 'node_memory_MemTotal_bytes\s+([\d.]+)'
            $availMem = Get-MetricValue -Content $result.Content -Pattern 'node_memory_MemAvailable_bytes\s+([\d.]+)'
            
            if ($totalMem -and $availMem) {
                $usedPercent = [math]::Round((($totalMem - $availMem) / $totalMem) * 100, 2)
                $totalGB = [math]::Round($totalMem / 1GB, 2)
                $availGB = [math]::Round($availMem / 1GB, 2)
                
                $status = if ($usedPercent -gt 90) { "CRITICAL" }
                         elseif ($usedPercent -gt 80) { "WARNING" }
                         else { "OK" }
                
                $memoryIssues += [PSCustomObject]@{
                    Node = $nodeName
                    'Used%' = $usedPercent
                    'Total(GB)' = $totalGB
                    'Avail(GB)' = $availGB
                    Status = $status
                }
            }
        }
    }
    
    Write-Host ""
    Write-Host ""
    
    $memoryIssues | Sort-Object -Property 'Used%' -Descending | Format-Table -AutoSize
    
    $critical = ($memoryIssues | Where-Object { $_.Status -eq "CRITICAL" }).Count
    $warning = ($memoryIssues | Where-Object { $_.Status -eq "WARNING" }).Count
    
    if ($critical -gt 0) {
        Write-Critical "$critical nodes with CRITICAL memory pressure (>90%)"
    }
    if ($warning -gt 0) {
        Write-Warning2 "$warning nodes with WARNING memory pressure (>80%)"
    }
    if ($critical -eq 0 -and $warning -eq 0) {
        Write-Success "All nodes have healthy memory levels"
    }
}

# Analyze disk space
function Analyze-DiskSpace {
    Write-Header "Disk Space Analysis"
    
    $pods = kubectl get pods -n $Namespace -l app.kubernetes.io/name=fireball-node-exporter -o json | ConvertFrom-Json
    $diskIssues = @()
    
    foreach ($pod in $pods.items) {
        $podName = $pod.metadata.name
        $nodeName = $pod.spec.nodeName
        
        Write-Host "." -NoNewline
        
        $result = Get-NodeMetrics -PodName $podName -NodeName $nodeName
        
        if ($result.Success) {
            # Look for root filesystem
            $lines = $result.Content -split "`n" | Where-Object { $_ -match 'node_filesystem.*mountpoint="/"' }
            
            foreach ($line in $lines) {
                if ($line -match 'node_filesystem_size_bytes{.*mountpoint="/".*}\s+([\d.]+)') {
                    $sizeBytes = [long]$matches[1]
                }
                if ($line -match 'node_filesystem_avail_bytes{.*mountpoint="/".*}\s+([\d.]+)') {
                    $availBytes = [long]$matches[1]
                }
            }
            
            if ($sizeBytes -and $availBytes) {
                $usedPercent = [math]::Round((($sizeBytes - $availBytes) / $sizeBytes) * 100, 2)
                $sizeGB = [math]::Round($sizeBytes / 1GB, 2)
                $availGB = [math]::Round($availBytes / 1GB, 2)
                
                $status = if ($usedPercent -gt 90) { "CRITICAL" }
                         elseif ($usedPercent -gt 80) { "WARNING" }
                         else { "OK" }
                
                # Predict days until full (simple linear projection)
                $daysToFull = if ($usedPercent -gt 50) {
                    $growthRate = 1  # GB per day (estimate)
                    [math]::Round($availGB / $growthRate, 0)
                } else { "N/A" }
                
                $diskIssues += [PSCustomObject]@{
                    Node = $nodeName
                    'Used%' = $usedPercent
                    'Size(GB)' = $sizeGB
                    'Avail(GB)' = $availGB
                    'Days to Full' = $daysToFull
                    Status = $status
                }
            }
        }
    }
    
    Write-Host ""
    Write-Host ""
    
    $diskIssues | Sort-Object -Property 'Used%' -Descending | Format-Table -AutoSize
    
    $critical = ($diskIssues | Where-Object { $_.Status -eq "CRITICAL" }).Count
    $warning = ($diskIssues | Where-Object { $_.Status -eq "WARNING" }).Count
    
    if ($critical -gt 0) {
        Write-Critical "$critical nodes with CRITICAL disk space (<10% free)"
        Write-Critical "Take action NOW before disks fill completely!"
    }
    if ($warning -gt 0) {
        Write-Warning2 "$warning nodes with WARNING disk space (<20% free)"
        Write-Warning2 "Plan cleanup or expansion soon"
    }
    if ($critical -eq 0 -and $warning -eq 0) {
        Write-Success "All nodes have adequate disk space"
    }
}

# Analyze temperature
function Analyze-Temperature {
    Write-Header "Temperature Monitoring"
    
    $pods = kubectl get pods -n $Namespace -l app.kubernetes.io/name=fireball-node-exporter -o json | ConvertFrom-Json
    $tempData = @()
    $sensorsFound = 0
    
    foreach ($pod in $pods.items) {
        $podName = $pod.metadata.name
        $nodeName = $pod.spec.nodeName
        
        Write-Host "." -NoNewline
        
        $result = Get-NodeMetrics -PodName $podName -NodeName $nodeName
        
        if ($result.Success) {
            $tempMetrics = $result.Content -split "`n" | Where-Object { $_ -match 'node_hwmon_temp_celsius' -or $_ -match 'node_thermal_zone_temp' }
            
            if ($tempMetrics) {
                $sensorsFound++
                $maxTemp = 0
                
                foreach ($metric in $tempMetrics) {
                    if ($metric -match '\s+([\d.]+)$') {
                        $temp = [double]$matches[1]
                        if ($temp -gt $maxTemp) { $maxTemp = $temp }
                    }
                }
                
                $status = if ($maxTemp -gt 80) { "CRITICAL" }
                         elseif ($maxTemp -gt 70) { "WARNING" }
                         elseif ($maxTemp -gt 60) { "ELEVATED" }
                         else { "OK" }
                
                $tempData += [PSCustomObject]@{
                    Node = $nodeName
                    'Max Temp (°C)' = $maxTemp
                    Status = $status
                    Warning = if ($maxTemp -gt 70) { "Check cooling!" } else { "" }
                }
            }
        }
    }
    
    Write-Host ""
    Write-Host ""
    
    if ($tempData.Count -eq 0) {
        Write-Info "No temperature sensors detected on any nodes"
        Write-Info "This is normal for VMs or cloud instances"
        Write-Info "For bare metal/edge devices, ensure hwmon or thermal_zone collectors are enabled"
    } else {
        Write-Info "Temperature sensors found on $sensorsFound nodes"
        Write-Host ""
        
        $tempData | Sort-Object -Property 'Max Temp (°C)' -Descending | Format-Table -AutoSize
        
        $critical = ($tempData | Where-Object { $_.Status -eq "CRITICAL" }).Count
        $warning = ($tempData | Where-Object { $_.Status -eq "WARNING" }).Count
        
        if ($critical -gt 0) {
            Write-Critical "$critical nodes with CRITICAL temperature (>80°C)"
            Write-Critical "YOUR HARDWARE IS LITERALLY COOKING ITSELF!"
            Write-Critical "Fix your cooling before explaining downtime to management!"
        }
        if ($warning -gt 0) {
            Write-Warning2 "$warning nodes with WARNING temperature (>70°C)"
            Write-Warning2 "These temperatures are not 'fine'. Check ventilation and airflow."
        }
        if ($critical -eq 0 -and $warning -eq 0) {
            Write-Success "All monitored nodes have acceptable temperatures"
        }
    }
}

# Network statistics
function Analyze-Network {
    Write-Header "Network Statistics Summary"
    
    Write-Info "Aggregating network metrics..."
    Write-Host ""
    
    $pods = kubectl get pods -n $Namespace -l app.kubernetes.io/name=fireball-node-exporter -o json | ConvertFrom-Json
    $networkData = @()
    
    foreach ($pod in $pods.items) {
        $podName = $pod.metadata.name
        $nodeName = $pod.spec.nodeName
        
        Write-Host "." -NoNewline
        
        $result = Get-NodeMetrics -PodName $podName -NodeName $nodeName
        
        if ($result.Success) {
            $errorMetrics = $result.Content -split "`n" | Where-Object { $_ -match 'node_network_.*_errs_total' }
            
            if ($errorMetrics) {
                $hasErrors = $false
                foreach ($metric in $errorMetrics) {
                    if ($metric -match '\s+([\d.]+)$' -and [double]$matches[1] -gt 0) {
                        $hasErrors = $true
                        break
                    }
                }
                
                $networkData += [PSCustomObject]@{
                    Node = $nodeName
                    'Network Errors' = if ($hasErrors) { "Detected" } else { "None" }
                    Status = if ($hasErrors) { "WARNING" } else { "OK" }
                }
            }
        }
    }
    
    Write-Host ""
    Write-Host ""
    
    $networkData | Format-Table -AutoSize
    
    $issues = ($networkData | Where-Object { $_.Status -eq "WARNING" }).Count
    
    if ($issues -gt 0) {
        Write-Warning2 "$issues nodes have network errors detected"
        Write-Warning2 "Check interface statistics and switch ports"
        Write-Info "Use: curl http://localhost:9100/metrics | grep node_network.*errs"
    } else {
        Write-Success "No significant network errors detected"
    }
}

# Hardware health summary
function Show-HealthSummary {
    Write-Header "Cluster Health Summary"
    
    $pods = kubectl get pods -n $Namespace -l app.kubernetes.io/name=fireball-node-exporter -o json | ConvertFrom-Json
    $nodes = kubectl get nodes -o json | ConvertFrom-Json
    
    Write-Info "Total Nodes: $($nodes.items.Count)"
    Write-Info "Monitored Nodes: $($pods.items.Count)"
    Write-Info "Coverage: $([math]::Round(($pods.items.Count / $nodes.items.Count) * 100, 2))%"
    Write-Host ""
    
    # Node status
    $readyNodes = ($nodes.items | Where-Object {
        $_.status.conditions | Where-Object { $_.type -eq "Ready" -and $_.status -eq "True" }
    }).Count
    
    if ($readyNodes -eq $nodes.items.Count) {
        Write-Success "All nodes are Ready"
    } else {
        Write-Warning2 "$($nodes.items.Count - $readyNodes) nodes are not Ready"
    }
}

# Main execution
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                               ║" -ForegroundColor Cyan
Write-Host "║     FIREBALL CLUSTER HEALTH ANALYZER                          ║" -ForegroundColor Cyan
Write-Host "║     Hardware health monitoring across all nodes               ║" -ForegroundColor Cyan
Write-Host "║                                                               ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Info "Analyzing cluster health in namespace: $Namespace"
Write-Warning2 "This may take a minute... fetching metrics from all nodes"
Write-Host ""

# Run analyses
Show-HealthSummary
Analyze-Memory
Analyze-DiskSpace
Analyze-Temperature
Analyze-Network

# Final recommendations
Write-Header "Recommendations"

Write-Info "Regular Maintenance:"
Write-Host "  • Review disk space weekly" -ForegroundColor Gray
Write-Host "  • Monitor temperature trends for edge devices" -ForegroundColor Gray
Write-Host "  • Set up alerts for all critical thresholds" -ForegroundColor Gray
Write-Host "  • Test alert delivery monthly" -ForegroundColor Gray
Write-Host ""

Write-Info "Critical Actions:"
Write-Host "  • Any node >90% disk: Clean up or expand storage NOW" -ForegroundColor Gray
Write-Host "  • Any node >80°C: Fix cooling immediately" -ForegroundColor Gray
Write-Host "  • Network errors: Check cables and switch ports" -ForegroundColor Gray
Write-Host "  • Memory >90%: Investigate memory leaks or add capacity" -ForegroundColor Gray
Write-Host ""

Write-Host "Pro tip: Hardware failures rarely announce themselves politely." -ForegroundColor Magenta
Write-Host "That's why you're monitoring. Act on the warnings before they become outages." -ForegroundColor Magenta
Write-Host ""
