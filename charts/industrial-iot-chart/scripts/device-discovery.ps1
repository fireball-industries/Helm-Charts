# ============================================================================
# USB Device Discovery Script
# ============================================================================
# Fireball Industries - Patrick Ryan
# "Finding your USB devices before Home Assistant does"
# ============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("list", "watch", "permissions")]
    [string]$Action = "list",
    
    [Parameter(Mandatory = $false)]
    [string]$NodeName = ""
)

# Color output
function Write-DeviceInfo { param([string]$Message) Write-Host "  $Message" -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "✓ $Message" -ForegroundColor Green }
function Write-Warning { param([string]$Message) Write-Host "⚠ $Message" -ForegroundColor Yellow }

Write-Host @"

╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║  USB Device Discovery                                            ║
║  Fireball Industries - Patrick Ryan                              ║
║  "Your devices can run, but they can't hide"                     ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Yellow

# ============================================================================
# DEVICE LISTING
# ============================================================================

function Get-USBDevices {
    param([string]$Node = "")
    
    Write-Host "`n=== USB Devices ===" -ForegroundColor Cyan
    
    if ($Node) {
        Write-Host "Scanning node: $Node`n" -ForegroundColor Gray
        
        # SSH into node and list USB devices
        $devices = kubectl debug node/$Node -it --image=nicolaka/netshoot -- lsusb 2>$null
        
        if ($devices) {
            foreach ($device in $devices) {
                Write-DeviceInfo $device
            }
        } else {
            Write-Warning "No devices found or cannot access node"
        }
    } else {
        # List all nodes
        Write-Host "Available nodes:" -ForegroundColor Gray
        kubectl get nodes -o custom-columns=NAME:.metadata.name,STATUS:.status.conditions[-1].type --no-headers
        
        Write-Host "`nTip: Run with -NodeName <name> to scan specific node" -ForegroundColor Yellow
    }
    
    Write-Host "`n=== Serial Devices ===" -ForegroundColor Cyan
    
    if ($Node) {
        $serial = kubectl debug node/$Node -it --image=nicolaka/netshoot -- ls -la /dev/tty* 2>$null
        
        if ($serial) {
            foreach ($device in $serial) {
                if ($device -match "ttyUSB|ttyACM") {
                    Write-DeviceInfo $device
                }
            }
        }
    }
}

# ============================================================================
# COMMON DEVICE PATTERNS
# ============================================================================

function Show-CommonDevices {
    Write-Host "`n=== Common Smart Home USB Devices ===" -ForegroundColor Cyan
    
    $commonDevices = @(
        @{Name="Aeotec Z-Stick"; VendorID="0658"; ProductID="0200"; Type="Z-Wave"},
        @{Name="Nortek HUSBZB-1"; VendorID="10c4"; ProductID="8a2a"; Type="Zigbee+Z-Wave"},
        @{Name="ConBee II"; VendorID="1cf1"; ProductID="0030"; Type="Zigbee"},
        @{Name="Sonoff Zigbee Dongle"; VendorID="1a86"; ProductID="7523"; Type="Zigbee"},
        @{Name="SkyConnect"; VendorID="10c4"; ProductID="ea60"; Type="Zigbee"},
        @{Name="Bluetooth Adapter"; VendorID="0a12"; ProductID="0001"; Type="Bluetooth"}
    )
    
    foreach ($device in $commonDevices) {
        Write-DeviceInfo "$($device.Name) [$($device.Type)]"
        Write-Host "    Vendor: $($device.VendorID), Product: $($device.ProductID)" -ForegroundColor Gray
    }
    
    Write-Host "`n=== Device Path Examples ===" -ForegroundColor Cyan
    Write-DeviceInfo "/dev/ttyUSB0  - USB to Serial adapter (Z-Wave, Zigbee)"
    Write-DeviceInfo "/dev/ttyACM0  - USB modem/serial device"
    Write-DeviceInfo "/dev/ttyAMA0  - Raspberry Pi GPIO serial"
    Write-DeviceInfo "/dev/serial/by-id/* - Persistent device names (RECOMMENDED)"
}

# ============================================================================
# WATCH MODE
# ============================================================================

function Watch-USBDevices {
    param([string]$Node)
    
    if (-not $Node) {
        Write-Warning "Node name required for watch mode"
        Write-Host "Usage: .\device-discovery.ps1 -Action watch -NodeName <node>" -ForegroundColor Gray
        return
    }
    
    Write-Host "`nWatching USB devices on node: $Node" -ForegroundColor Cyan
    Write-Host "Press Ctrl+C to stop`n" -ForegroundColor Gray
    
    $previousDevices = ""
    
    while ($true) {
        $currentDevices = kubectl debug node/$Node -it --image=nicolaka/netshoot -- lsusb 2>$null | Sort-Object
        
        if ($currentDevices -ne $previousDevices) {
            Clear-Host
            Write-Host "=== USB Devices ($(Get-Date -Format 'HH:mm:ss')) ===" -ForegroundColor Cyan
            
            foreach ($device in $currentDevices) {
                Write-DeviceInfo $device
            }
            
            $previousDevices = $currentDevices
        }
        
        Start-Sleep -Seconds 2
    }
}

# ============================================================================
# PERMISSIONS CHECK
# ============================================================================

function Test-DevicePermissions {
    param([string]$Node)
    
    if (-not $Node) {
        Write-Warning "Node name required for permissions check"
        return
    }
    
    Write-Host "`n=== Device Permissions Check ===" -ForegroundColor Cyan
    
    # Check udev rules
    Write-Host "`nChecking udev rules..." -ForegroundColor Gray
    $udevRules = kubectl debug node/$Node -it --image=nicolaka/netshoot -- ls -la /etc/udev/rules.d/ 2>$null
    
    if ($udevRules) {
        foreach ($rule in $udevRules) {
            if ($rule -match "\.rules$") {
                Write-DeviceInfo $rule
            }
        }
    }
    
    # Check device group memberships
    Write-Host "`nDevice groups:" -ForegroundColor Gray
    kubectl debug node/$Node -it --image=nicolaka/netshoot -- getent group | Select-String "dialout|uucp|tty" 2>$null | ForEach-Object {
        Write-DeviceInfo $_
    }
    
    Write-Host "`n" -NoNewline
    Write-Success "Recommendation: Add container user to 'dialout' group for serial access"
}

# ============================================================================
# HELM VALUES GENERATOR
# ============================================================================

function Export-DeviceConfig {
    param([string]$Node, [string]$DevicePath)
    
    Write-Host "`n=== Helm Values Configuration ===" -ForegroundColor Cyan
    
    if ($DevicePath) {
        Write-Host "`nAdd this to your values.yaml:`n" -ForegroundColor Gray
        
        $config = @"
devices:
  usb:
    enabled: true
    devices:
      - name: $([System.IO.Path]::GetFileNameWithoutExtension($DevicePath))
        hostPath: $DevicePath
        
# Alternative: Use by-id path (more stable)
# devices:
#   usb:
#     enabled: true
#     devices:
#       - name: zigbee-coordinator
#         hostPath: /dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus-if00-port0
"@
        
        Write-Host $config -ForegroundColor Yellow
        
    } else {
        Write-Host "`nExample configuration:`n" -ForegroundColor Gray
        
        $example = @"
# Z-Wave USB Stick
devices:
  usb:
    enabled: true
    devices:
      - name: zwave
        hostPath: /dev/ttyUSB0

# Zigbee Coordinator
devices:
  usb:
    enabled: true
    devices:
      - name: zigbee
        hostPath: /dev/serial/by-id/usb-Silicon_Labs_Sonoff_Zigbee_3.0_USB_Dongle_Plus_0001-if00-port0
"@
        
        Write-Host $example -ForegroundColor Yellow
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

switch ($Action) {
    "list" {
        Get-USBDevices -Node $NodeName
        Show-CommonDevices
        Export-DeviceConfig -Node $NodeName
    }
    "watch" {
        Watch-USBDevices -Node $NodeName
    }
    "permissions" {
        Test-DevicePermissions -Node $NodeName
    }
}

Write-Host "`n=== Tips ===" -ForegroundColor Cyan
Write-DeviceInfo "1. Use /dev/serial/by-id/* paths for stability across reboots"
Write-DeviceInfo "2. Check device permissions: ls -la /dev/ttyUSB0"
Write-DeviceInfo "3. Add user to dialout group: usermod -aG dialout <user>"
Write-DeviceInfo "4. Test with: kubectl exec -it <pod> -- ls -la /dev/ttyUSB0"
Write-Host ""
