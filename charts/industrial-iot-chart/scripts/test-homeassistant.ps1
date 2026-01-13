# ============================================================================
# Test Suite for Home Assistant Deployment
# ============================================================================
# Fireball Industries - Patrick Ryan
# "Testing in production is for amateurs. We test before production."
# ============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Namespace = "home-assistant",
    
    [Parameter(Mandatory = $false)]
    [string]$ReleaseName = "home-assistant",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("quick", "full", "integration")]
    [string]$TestSuite = "quick"
)

# Color output functions
function Write-Success { param([string]$Message) Write-Host "✓ $Message" -ForegroundColor Green }
function Write-Failure { param([string]$Message) Write-Host "✗ $Message" -ForegroundColor Red }
function Write-TestHeader { param([string]$Message) Write-Host "`n=== $Message ===" -ForegroundColor Cyan }
function Write-Info { param([string]$Message) Write-Host "  $Message" -ForegroundColor Gray }

$script:TestsFailed = 0
$script:TestsPassed = 0

function Test-Assertion {
    param(
        [bool]$Condition,
        [string]$TestName,
        [string]$ErrorMessage = ""
    )
    
    if ($Condition) {
        Write-Success $TestName
        $script:TestsPassed++
        return $true
    } else {
        Write-Failure "$TestName - $ErrorMessage"
        $script:TestsFailed++
        return $false
    }
}

# ============================================================================
# HEALTH CHECKS
# ============================================================================

function Test-PodHealth {
    Write-TestHeader "Pod Health Checks"
    
    # Get pod name
    $podName = kubectl get pods -n $Namespace -l "app.kubernetes.io/name=home-assistant" -o jsonpath="{.items[0].metadata.name}" 2>$null
    
    if (-not $podName) {
        Write-Failure "Home Assistant pod not found"
        return $false
    }
    
    Write-Info "Testing pod: $podName"
    
    # Check pod status
    $podStatus = kubectl get pod $podName -n $Namespace -o jsonpath="{.status.phase}" 2>$null
    Test-Assertion ($podStatus -eq "Running") "Pod is running" "Pod status: $podStatus"
    
    # Check all containers ready
    $containersReady = kubectl get pod $podName -n $Namespace -o jsonpath="{.status.containerStatuses[*].ready}" 2>$null
    $allReady = ($containersReady -split ' ') -notcontains 'false'
    Test-Assertion $allReady "All containers ready" "Container ready status: $containersReady"
    
    # Check restart count (should be low)
    $restartCount = kubectl get pod $podName -n $Namespace -o jsonpath="{.status.containerStatuses[0].restartCount}" 2>$null
    Test-Assertion ($restartCount -lt 5) "Restart count acceptable ($restartCount < 5)" "Too many restarts: $restartCount"
    
    return $allReady
}

function Test-ServiceEndpoints {
    Write-TestHeader "Service Endpoint Checks"
    
    # Check main service
    $serviceExists = kubectl get service "${ReleaseName}-home-assistant" -n $Namespace 2>$null
    Test-Assertion ($null -ne $serviceExists) "Main service exists"
    
    # Check service has endpoints
    $endpoints = kubectl get endpoints "${ReleaseName}-home-assistant" -n $Namespace -o jsonpath="{.subsets[*].addresses[*].ip}" 2>$null
    Test-Assertion ($null -ne $endpoints -and $endpoints -ne "") "Service has endpoints" "No endpoints found"
    
    # Check MQTT service if enabled
    $mqttService = kubectl get service "${ReleaseName}-mqtt" -n $Namespace 2>$null
    if ($mqttService) {
        Write-Info "MQTT service detected, checking endpoints"
        $mqttEndpoints = kubectl get endpoints "${ReleaseName}-mqtt" -n $Namespace -o jsonpath="{.subsets[*].addresses[*].ip}" 2>$null
        Test-Assertion ($null -ne $mqttEndpoints) "MQTT service has endpoints"
    }
    
    return $true
}

# ============================================================================
# HTTP API CHECKS
# ============================================================================

function Test-HomeAssistantAPI {
    Write-TestHeader "Home Assistant API Checks"
    
    # Port forward to HA
    Write-Info "Setting up port forward..."
    $portForwardJob = Start-Job -ScriptBlock {
        param($ns, $release)
        kubectl port-forward -n $ns "svc/${release}-home-assistant" 8123:8123 2>$null
    } -ArgumentList $Namespace, $ReleaseName
    
    Start-Sleep -Seconds 3
    
    try {
        # Test API endpoint
        $apiUrl = "http://localhost:8123/api/"
        $response = Invoke-WebRequest -Uri $apiUrl -TimeoutSec 10 -UseBasicParsing -ErrorAction SilentlyContinue
        
        Test-Assertion ($response.StatusCode -eq 200) "API endpoint responds" "HTTP $($response.StatusCode)"
        
        # Check API returns JSON
        $isJson = $response.Content -match '^\{.*\}$'
        Test-Assertion $isJson "API returns JSON"
        
        # Test health endpoint
        $healthUrl = "http://localhost:8123/api/health"
        $healthResponse = Invoke-WebRequest -Uri $healthUrl -TimeoutSec 10 -UseBasicParsing -ErrorAction SilentlyContinue
        
        if ($healthResponse) {
            Test-Assertion ($healthResponse.StatusCode -eq 200) "Health endpoint OK"
        }
        
    } catch {
        Write-Failure "API test failed: $($_.Exception.Message)"
    } finally {
        Stop-Job $portForwardJob -ErrorAction SilentlyContinue
        Remove-Job $portForwardJob -Force -ErrorAction SilentlyContinue
    }
    
    return $true
}

# ============================================================================
# MQTT TESTS
# ============================================================================

function Test-MQTTBroker {
    Write-TestHeader "MQTT Broker Checks"
    
    # Check if MQTT is enabled
    $mqttPod = kubectl get pods -n $Namespace -l "app.kubernetes.io/component=mqtt" -o jsonpath="{.items[0].metadata.name}" 2>$null
    
    if (-not $mqttPod) {
        Write-Info "MQTT not enabled, skipping tests"
        return $true
    }
    
    Write-Info "Testing MQTT broker in pod: $mqttPod"
    
    # Port forward to MQTT
    $portForwardJob = Start-Job -ScriptBlock {
        param($ns, $release)
        kubectl port-forward -n $ns "svc/${release}-mqtt" 1883:1883 2>$null
    } -ArgumentList $Namespace, $ReleaseName
    
    Start-Sleep -Seconds 3
    
    try {
        # Test MQTT connection (requires mosquitto_pub/sub)
        $mosquittoPub = Get-Command mosquitto_pub -ErrorAction SilentlyContinue
        
        if ($mosquittoPub) {
            $testTopic = "test/health/$(Get-Random)"
            $testMessage = "health-check-$(Get-Date -Format 'yyyyMMddHHmmss')"
            
            # Publish test message
            $pubResult = mosquitto_pub -h localhost -p 1883 -t $testTopic -m $testMessage 2>&1
            
            Test-Assertion ($LASTEXITCODE -eq 0) "MQTT publish successful"
        } else {
            Write-Info "mosquitto_pub not found, skipping MQTT pub/sub test"
        }
        
    } catch {
        Write-Failure "MQTT test failed: $($_.Exception.Message)"
    } finally {
        Stop-Job $portForwardJob -ErrorAction SilentlyContinue
        Remove-Job $portForwardJob -Force -ErrorAction SilentlyContinue
    }
    
    return $true
}

# ============================================================================
# DATABASE TESTS
# ============================================================================

function Test-DatabaseConnectivity {
    Write-TestHeader "Database Connectivity Checks"
    
    $podName = kubectl get pods -n $Namespace -l "app.kubernetes.io/name=home-assistant" -o jsonpath="{.items[0].metadata.name}" 2>$null
    
    if (-not $podName) {
        Write-Failure "Cannot find Home Assistant pod"
        return $false
    }
    
    # Check database type from config
    $dbConfig = kubectl exec $podName -n $Namespace -c home-assistant -- cat /config/configuration.yaml 2>$null | Select-String "recorder:" -Context 0,10
    
    if ($dbConfig -match "postgresql") {
        Write-Info "PostgreSQL database detected"
        
        # Test PostgreSQL connectivity
        $pgTest = kubectl exec $podName -n $Namespace -c home-assistant -- sh -c "nc -zv postgres 5432" 2>&1
        Test-Assertion ($LASTEXITCODE -eq 0) "PostgreSQL connectivity OK"
        
    } elseif ($dbConfig -match "sqlite") {
        Write-Info "SQLite database detected"
        
        # Check SQLite file exists
        $dbFile = kubectl exec $podName -n $Namespace -c home-assistant -- ls -lh /config/home-assistant_v2.db 2>$null
        Test-Assertion ($null -ne $dbFile) "SQLite database file exists"
        
    } else {
        Write-Info "Database type not detected, assuming SQLite"
    }
    
    return $true
}

# ============================================================================
# ADD-ON TESTS
# ============================================================================

function Test-Addons {
    Write-TestHeader "Add-on Health Checks"
    
    $podName = kubectl get pods -n $Namespace -l "app.kubernetes.io/name=home-assistant" -o jsonpath="{.items[0].metadata.name}" 2>$null
    
    # Get list of containers
    $containers = kubectl get pod $podName -n $Namespace -o jsonpath="{.spec.containers[*].name}" 2>$null
    
    Write-Info "Containers: $containers"
    
    # Test each add-on container
    foreach ($container in ($containers -split ' ')) {
        if ($container -eq "home-assistant") { continue }
        
        $containerReady = kubectl get pod $podName -n $Namespace -o jsonpath="{.status.containerStatuses[?(@.name=='$container')].ready}" 2>$null
        Test-Assertion ($containerReady -eq "true") "Add-on '$container' is ready"
    }
    
    return $true
}

# ============================================================================
# STORAGE TESTS
# ============================================================================

function Test-PersistentStorage {
    Write-TestHeader "Persistent Storage Checks"
    
    # Check PVCs
    $pvcs = kubectl get pvc -n $Namespace -l "app.kubernetes.io/name=home-assistant" -o jsonpath="{.items[*].metadata.name}" 2>$null
    
    if ($pvcs) {
        foreach ($pvc in ($pvcs -split ' ')) {
            $pvcStatus = kubectl get pvc $pvc -n $Namespace -o jsonpath="{.status.phase}" 2>$null
            Test-Assertion ($pvcStatus -eq "Bound") "PVC '$pvc' is bound" "Status: $pvcStatus"
        }
    } else {
        Write-Info "No PVCs found (using hostPath?)"
    }
    
    # Check volumes are mounted
    $podName = kubectl get pods -n $Namespace -l "app.kubernetes.io/name=home-assistant" -o jsonpath="{.items[0].metadata.name}" 2>$null
    
    $configMount = kubectl exec $podName -n $Namespace -c home-assistant -- df -h /config 2>$null
    Test-Assertion ($null -ne $configMount) "Config volume mounted"
    
    return $true
}

# ============================================================================
# INTEGRATION TESTS
# ============================================================================

function Test-Integrations {
    Write-TestHeader "Integration Tests (Full Suite)"
    
    $podName = kubectl get pods -n $Namespace -l "app.kubernetes.io/name=home-assistant" -o jsonpath="{.items[0].metadata.name}" 2>$null
    
    # Check integration configuration files
    $integrationsFile = kubectl exec $podName -n $Namespace -c home-assistant -- test -f /config/configuration.yaml 2>$null
    Test-Assertion ($LASTEXITCODE -eq 0) "Configuration file exists"
    
    # Check automations
    $automationsFile = kubectl exec $podName -n $Namespace -c home-assistant -- test -f /config/automations.yaml 2>$null
    Test-Assertion ($LASTEXITCODE -eq 0) "Automations file exists"
    
    # Check scripts
    $scriptsFile = kubectl exec $podName -n $Namespace -c home-assistant -- test -f /config/scripts.yaml 2>$null
    Test-Assertion ($LASTEXITCODE -eq 0) "Scripts file exists"
    
    return $true
}

# ============================================================================
# MAIN TEST RUNNER
# ============================================================================

Write-Host @"

╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║  Home Assistant Test Suite                                       ║
║  Fireball Industries - Patrick Ryan                              ║
║  "Because hope is not a testing strategy"                        ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Yellow

Write-Host "Test Suite: $TestSuite" -ForegroundColor Cyan
Write-Host "Namespace: $Namespace" -ForegroundColor Cyan
Write-Host "Release: $ReleaseName`n" -ForegroundColor Cyan

# Run tests based on suite
switch ($TestSuite) {
    "quick" {
        Test-PodHealth
        Test-ServiceEndpoints
        Test-PersistentStorage
    }
    "full" {
        Test-PodHealth
        Test-ServiceEndpoints
        Test-PersistentStorage
        Test-HomeAssistantAPI
        Test-DatabaseConnectivity
        Test-Addons
    }
    "integration" {
        Test-PodHealth
        Test-ServiceEndpoints
        Test-PersistentStorage
        Test-HomeAssistantAPI
        Test-MQTTBroker
        Test-DatabaseConnectivity
        Test-Addons
        Test-Integrations
    }
}

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host "`n" -NoNewline
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan

$totalTests = $script:TestsPassed + $script:TestsFailed
$successRate = if ($totalTests -gt 0) { [math]::Round(($script:TestsPassed / $totalTests) * 100, 2) } else { 0 }

Write-Host "Total Tests:  " -NoNewline -ForegroundColor Gray
Write-Host $totalTests -ForegroundColor White

Write-Host "Passed:       " -NoNewline -ForegroundColor Gray
Write-Host $script:TestsPassed -ForegroundColor Green

Write-Host "Failed:       " -NoNewline -ForegroundColor Gray
Write-Host $script:TestsFailed -ForegroundColor $(if ($script:TestsFailed -gt 0) { "Red" } else { "Green" })

Write-Host "Success Rate: " -NoNewline -ForegroundColor Gray
Write-Host "$successRate%" -ForegroundColor $(if ($successRate -eq 100) { "Green" } elseif ($successRate -ge 80) { "Yellow" } else { "Red" })

Write-Host "═══════════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# Exit with appropriate code
if ($script:TestsFailed -gt 0) {
    Write-Host "Tests FAILED! 💥" -ForegroundColor Red
    exit 1
} else {
    Write-Host "All tests PASSED! 🎉" -ForegroundColor Green
    exit 0
}
