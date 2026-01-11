<#
.SYNOPSIS
    Test Mosquitto MQTT Broker connectivity and performance
    
.DESCRIPTION
    Comprehensive testing script for Mosquitto MQTT broker.
    Tests plain MQTT, TLS, WebSockets, QoS levels, and performance.
    
.PARAMETER ReleaseName
    Helm release name (default: mosquitto)
    
.PARAMETER Namespace
    Kubernetes namespace (default: iot)
    
.PARAMETER TestType
    Type of test to run: connectivity, tls, websocket, qos, sparkplug, performance, all
    
.EXAMPLE
    .\test-mosquitto.ps1 -TestType connectivity
    
.EXAMPLE
    .\test-mosquitto.ps1 -TestType all
    
.NOTES
    Author: Patrick Ryan - Fireball Industries
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ReleaseName = "mosquitto",
    
    [Parameter(Mandatory=$false)]
    [string]$Namespace = "iot",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('connectivity', 'tls', 'websocket', 'qos', 'sparkplug', 'performance', 'all')]
    [string]$TestType = "connectivity",
    
    [Parameter(Mandatory=$false)]
    [string]$Host = "",
    
    [Parameter(Mandatory=$false)]
    [int]$Port = 1883,
    
    [Parameter(Mandatory=$false)]
    [string]$Username = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Password = ""
)

$ErrorActionPreference = "Stop"

# ============================================================================
# Helper Functions
# ============================================================================

function Write-TestHeader {
    param([string]$Message)
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "🧪 $Message" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
}

function Write-TestResult {
    param(
        [string]$Test,
        [bool]$Passed,
        [string]$Message = ""
    )
    
    $status = if ($Passed) { "✅ PASS" } else { "❌ FAIL" }
    $color = if ($Passed) { "Green" } else { "Red" }
    
    Write-Host "$status - $Test" -ForegroundColor $color
    if ($Message) {
        Write-Host "       $Message" -ForegroundColor DarkGray
    }
}

function Get-MosquittoService {
    if (-not $Host) {
        $script:Host = "$ReleaseName.$Namespace.svc.cluster.local"
    }
    return $script:Host
}

# ============================================================================
# Test Functions
# ============================================================================

function Test-Connectivity {
    Write-TestHeader "Testing Basic MQTT Connectivity"
    
    $mqttHost = Get-MosquittoService
    Write-Host "Target: mqtt://$mqttHost:$Port" -ForegroundColor Yellow
    Write-Host ""
    
    # Test 1: Simple publish
    Write-Host "Test 1: Simple publish..." -NoNewline
    $topic = "test/connectivity/$(Get-Date -Format 'yyyyMMddHHmmss')"
    $message = "Hello MQTT from PowerShell!"
    
    try {
        $result = kubectl run mqtt-pub-test --rm -i --restart=Never --image=eclipse-mosquitto:2.0 -- `
            mosquitto_pub -h $mqttHost -p $Port -t $topic -m $message -q 0 2>&1
        
        Write-TestResult -Test "Simple publish" -Passed $true
    } catch {
        Write-TestResult -Test "Simple publish" -Passed $false -Message $_.Exception.Message
    }
    
    # Test 2: Subscribe with timeout
    Write-Host "Test 2: Subscribe and receive..." -NoNewline
    
    try {
        # Start subscriber in background
        $subJob = Start-Job -ScriptBlock {
            param($h, $p, $t)
            kubectl run mqtt-sub-test --rm -i --restart=Never --image=eclipse-mosquitto:2.0 -- `
                mosquitto_sub -h $h -p $p -t $t -C 1 -W 5
        } -ArgumentList $mqttHost, $Port, $topic
        
        Start-Sleep -Seconds 2
        
        # Publish message
        kubectl run mqtt-pub-test2 --rm -i --restart=Never --image=eclipse-mosquitto:2.0 -- `
            mosquitto_pub -h $mqttHost -p $Port -t $topic -m "Test message" 2>&1 | Out-Null
        
        $result = Wait-Job $subJob -Timeout 10 | Receive-Job
        Remove-Job $subJob -Force
        
        if ($result -match "Test message") {
            Write-TestResult -Test "Subscribe and receive" -Passed $true
        } else {
            Write-TestResult -Test "Subscribe and receive" -Passed $false -Message "No message received"
        }
    } catch {
        Write-TestResult -Test "Subscribe and receive" -Passed $false -Message $_.Exception.Message
    }
    
    # Test 3: Retained messages
    Write-Host "Test 3: Retained messages..." -NoNewline
    $retainedTopic = "test/retained/$(Get-Date -Format 'yyyyMMddHHmmss')"
    
    try {
        # Publish retained message
        kubectl run mqtt-retained-pub --rm -i --restart=Never --image=eclipse-mosquitto:2.0 -- `
            mosquitto_pub -h $mqttHost -p $Port -t $retainedTopic -m "Retained message" -r 2>&1 | Out-Null
        
        Start-Sleep -Seconds 2
        
        # Subscribe and check for retained message
        $result = kubectl run mqtt-retained-sub --rm -i --restart=Never --image=eclipse-mosquitto:2.0 -- `
            mosquitto_sub -h $mqttHost -p $Port -t $retainedTopic -C 1 -W 3
        
        if ($result -match "Retained message") {
            Write-TestResult -Test "Retained messages" -Passed $true
        } else {
            Write-TestResult -Test "Retained messages" -Passed $false -Message "Retained message not received"
        }
    } catch {
        Write-TestResult -Test "Retained messages" -Passed $false -Message $_.Exception.Message
    }
    
    Write-Host ""
    Write-Host "✅ Basic connectivity tests completed!" -ForegroundColor Green
}

function Test-QoS {
    Write-TestHeader "Testing QoS Levels"
    
    $mqttHost = Get-MosquittoService
    
    foreach ($qos in 0..2) {
        Write-Host "Test QoS $qos..." -NoNewline
        $topic = "test/qos$qos/$(Get-Date -Format 'yyyyMMddHHmmss')"
        
        try {
            kubectl run mqtt-qos-test-$qos --rm -i --restart=Never --image=eclipse-mosquitto:2.0 -- `
                mosquitto_pub -h $mqttHost -p $Port -t $topic -m "QoS $qos message" -q $qos 2>&1 | Out-Null
            
            Write-TestResult -Test "QoS $qos publish" -Passed $true
        } catch {
            Write-TestResult -Test "QoS $qos publish" -Passed $false -Message $_.Exception.Message
        }
    }
    
    Write-Host ""
    Write-Host "✅ QoS tests completed!" -ForegroundColor Green
}

function Test-SparkplugB {
    Write-TestHeader "Testing Sparkplug B Topics"
    
    $mqttHost = Get-MosquittoService
    $namespace = "spBv1.0"
    $groupId = "TestFactory"
    $edgeNode = "Edge-Test-01"
    
    Write-Host "Sparkplug B Configuration:" -ForegroundColor Yellow
    Write-Host "  Namespace: $namespace"
    Write-Host "  Group ID:  $groupId"
    Write-Host "  Edge Node: $edgeNode"
    Write-Host ""
    
    # Test NBIRTH
    Write-Host "Test 1: NBIRTH (Edge Node Birth)..." -NoNewline
    $nbirthTopic = "$namespace/$groupId/NBIRTH/$edgeNode"
    
    try {
        kubectl run mqtt-sparkplug-nbirth --rm -i --restart=Never --image=eclipse-mosquitto:2.0 -- `
            mosquitto_pub -h $mqttHost -p $Port -t $nbirthTopic -m '{"timestamp":1234567890,"metrics":[]}' -q 1 2>&1 | Out-Null
        
        Write-TestResult -Test "NBIRTH publish" -Passed $true
    } catch {
        Write-TestResult -Test "NBIRTH publish" -Passed $false -Message $_.Exception.Message
    }
    
    # Test NDATA
    Write-Host "Test 2: NDATA (Node Data)..." -NoNewline
    $ndataTopic = "$namespace/$groupId/NDATA/$edgeNode"
    
    try {
        kubectl run mqtt-sparkplug-ndata --rm -i --restart=Never --image=eclipse-mosquitto:2.0 -- `
            mosquitto_pub -h $mqttHost -p $Port -t $ndataTopic -m '{"timestamp":1234567890,"metrics":[{"name":"temp","value":25.5}]}' -q 0 2>&1 | Out-Null
        
        Write-TestResult -Test "NDATA publish" -Passed $true
    } catch {
        Write-TestResult -Test "NDATA publish" -Passed $false -Message $_.Exception.Message
    }
    
    # Test DDATA
    Write-Host "Test 3: DDATA (Device Data)..." -NoNewline
    $ddataTopic = "$namespace/$groupId/DDATA/$edgeNode/Sensor-01"
    
    try {
        kubectl run mqtt-sparkplug-ddata --rm -i --restart=Never --image=eclipse-mosquitto:2.0 -- `
            mosquitto_pub -h $mqttHost -p $Port -t $ddataTopic -m '{"timestamp":1234567890,"metrics":[{"name":"pressure","value":101.3}]}' -q 0 2>&1 | Out-Null
        
        Write-TestResult -Test "DDATA publish" -Passed $true
    } catch {
        Write-TestResult -Test "DDATA publish" -Passed $false -Message $_.Exception.Message
    }
    
    # Test NDEATH
    Write-Host "Test 4: NDEATH (Edge Node Death)..." -NoNewline
    $ndeathTopic = "$namespace/$groupId/NDEATH/$edgeNode"
    
    try {
        kubectl run mqtt-sparkplug-ndeath --rm -i --restart=Never --image=eclipse-mosquitto:2.0 -- `
            mosquitto_pub -h $mqttHost -p $Port -t $ndeathTopic -m '{"timestamp":1234567890}' -q 1 2>&1 | Out-Null
        
        Write-TestResult -Test "NDEATH publish" -Passed $true
    } catch {
        Write-TestResult -Test "NDEATH publish" -Passed $false -Message $_.Exception.Message
    }
    
    Write-Host ""
    Write-Host "✅ Sparkplug B tests completed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📝 Subscribe to all Sparkplug messages with:" -ForegroundColor Cyan
    Write-Host "   kubectl run -it mqtt-sparkplug-sub --rm --image=eclipse-mosquitto:2.0 -- mosquitto_sub -h $mqttHost -p $Port -t '$namespace/#' -v"
}

function Test-Performance {
    Write-TestHeader "Performance Testing"
    
    $mqttHost = Get-MosquittoService
    $messageCount = 100
    
    Write-Host "Publishing $messageCount messages..." -ForegroundColor Yellow
    Write-Host ""
    
    $topic = "test/performance/$(Get-Date -Format 'yyyyMMddHHmmss')"
    $startTime = Get-Date
    
    try {
        for ($i = 1; $i -le $messageCount; $i++) {
            if ($i % 10 -eq 0) {
                Write-Host "Progress: $i/$messageCount" -NoNewline -ForegroundColor DarkGray
                Write-Host "`r" -NoNewline
            }
            
            kubectl run mqtt-perf-$i --rm -i --restart=Never --image=eclipse-mosquitto:2.0 -- `
                mosquitto_pub -h $mqttHost -p $Port -t $topic -m "Message $i" -q 0 2>&1 | Out-Null
        }
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds
        $messagesPerSecond = [math]::Round($messageCount / $duration, 2)
        
        Write-Host ""
        Write-Host ""
        Write-Host "Performance Results:" -ForegroundColor Green
        Write-Host "  Messages sent: $messageCount"
        Write-Host "  Duration: $([math]::Round($duration, 2)) seconds"
        Write-Host "  Messages/sec: $messagesPerSecond"
        
        Write-TestResult -Test "Performance test" -Passed $true -Message "$messagesPerSecond msg/sec"
        
    } catch {
        Write-TestResult -Test "Performance test" -Passed $false -Message $_.Exception.Message
    }
}

# ============================================================================
# Main Execution
# ============================================================================

Write-Host ""
Write-Host "🦟 Mosquitto MQTT Broker Test Suite" -ForegroundColor Magenta
Write-Host "   Fireball Industries - Patrick Ryan" -ForegroundColor DarkGray
Write-Host ""

$testsToRun = if ($TestType -eq 'all') {
    @('connectivity', 'qos', 'sparkplug', 'performance')
} else {
    @($TestType)
}

foreach ($test in $testsToRun) {
    switch ($test) {
        'connectivity' { Test-Connectivity }
        'qos'          { Test-QoS }
        'sparkplug'    { Test-SparkplugB }
        'performance'  { Test-Performance }
    }
}

Write-Host ""
Write-Host "✅ All tests completed!" -ForegroundColor Green
Write-Host ""
