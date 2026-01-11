#!/bin/bash
# Hardware Health Monitoring Script
# Exports custom hardware health metrics
# Integrates with hardware monitoring tools

set -euo pipefail

TEXTFILE_DIR="/var/lib/node_exporter/textfile_collector"
PROM_FILE="$TEXTFILE_DIR/hardware_health.prom"
TMP_FILE="$PROM_FILE.$$"

# Check RAID status (mdadm)
check_raid_status() {
    if command -v mdadm &> /dev/null; then
        local raid_devices=$(ls /dev/md* 2>/dev/null | grep -E 'md[0-9]+$' || true)
        
        for device in $raid_devices; do
            local status=$(mdadm --detail "$device" 2>/dev/null | grep -i "state" | awk -F: '{print $2}' | tr -d ' ' || echo "unknown")
            local health=0
            
            case "$status" in
                "clean"|"active")
                    health=1
                    ;;
                *)
                    health=0
                    ;;
            esac
            
            echo "hardware_raid_health{device=\"$device\",status=\"$status\"} $health"
        done
    fi
}

# Check SMART status (smartctl)
check_smart_status() {
    if command -v smartctl &> /dev/null; then
        local disks=$(lsblk -dn -o NAME,TYPE | awk '$2=="disk" {print "/dev/"$1}')
        
        for disk in $disks; do
            # Skip if not a physical disk
            if ! smartctl -i "$disk" &>/dev/null; then
                continue
            fi
            
            local health=$(smartctl -H "$disk" 2>/dev/null | grep -i "SMART overall-health" | awk -F: '{print $2}' | tr -d ' ' || echo "UNKNOWN")
            local health_value=0
            
            [[ "$health" == "PASSED" ]] && health_value=1
            
            echo "hardware_disk_smart_health{disk=\"$disk\",status=\"$health\"} $health_value"
            
            # Get temperature if available
            local temp=$(smartctl -A "$disk" 2>/dev/null | grep -i "temperature" | head -1 | awk '{print $10}' || echo 0)
            [ -n "$temp" ] && echo "hardware_disk_temperature_celsius{disk=\"$disk\"} $temp"
            
            # Get wear level for SSDs
            local wear=$(smartctl -A "$disk" 2>/dev/null | grep -i "wear.*leveling" | awk '{print $4}' || echo 100)
            [ -n "$wear" ] && echo "hardware_ssd_wear_level_percent{disk=\"$disk\"} $wear"
        done
    fi
}

# Check power supply status (ipmi)
check_power_supply() {
    if command -v ipmitool &> /dev/null; then
        local psu_status=$(ipmitool sensor list 2>/dev/null | grep -i "^PS" || true)
        
        while IFS= read -r line; do
            local name=$(echo "$line" | awk -F'|' '{print $1}' | tr -d ' ')
            local status=$(echo "$line" | awk -F'|' '{print $4}' | tr -d ' ')
            local health=0
            
            [[ "$status" == "ok" || "$status" == "nr" ]] && health=1
            
            echo "hardware_power_supply_health{psu=\"$name\",status=\"$status\"} $health"
        done <<< "$psu_status"
    fi
}

# Check UPS status (apcaccess)
check_ups_status() {
    if command -v apcaccess &> /dev/null; then
        local ups_data=$(apcaccess 2>/dev/null || true)
        
        if [ -n "$ups_data" ]; then
            local status=$(echo "$ups_data" | grep "^STATUS" | awk -F: '{print $2}' | tr -d ' ')
            local load=$(echo "$ups_data" | grep "^LOADPCT" | awk -F: '{print $2}' | tr -d ' %')
            local battery=$(echo "$ups_data" | grep "^BCHARGE" | awk -F: '{print $2}' | tr -d ' %')
            local runtime=$(echo "$ups_data" | grep "^TIMELEFT" | awk -F: '{print $2}' | tr -d ' Minutes')
            
            local health=0
            [[ "$status" == "ONLINE" ]] && health=1
            
            echo "hardware_ups_health{status=\"$status\"} $health"
            [ -n "$load" ] && echo "hardware_ups_load_percent $load"
            [ -n "$battery" ] && echo "hardware_ups_battery_percent $battery"
            [ -n "$runtime" ] && echo "hardware_ups_runtime_minutes $runtime"
        fi
    fi
}

# Check NVMe health
check_nvme_health() {
    if command -v nvme &> /dev/null; then
        local nvme_devices=$(ls /dev/nvme?n? 2>/dev/null || true)
        
        for device in $nvme_devices; do
            local smart_log=$(nvme smart-log "$device" 2>/dev/null || true)
            
            if [ -n "$smart_log" ]; then
                local temp=$(echo "$smart_log" | grep "^temperature" | awk -F: '{print $2}' | tr -d ' C')
                local wear=$(echo "$smart_log" | grep "^percentage_used" | awk -F: '{print $2}' | tr -d ' %')
                
                [ -n "$temp" ] && echo "hardware_nvme_temperature_celsius{device=\"$device\"} $temp"
                [ -n "$wear" ] && echo "hardware_nvme_wear_percent{device=\"$device\"} $wear"
            fi
        done
    fi
}

# Generate metrics
{
    echo "# HELP hardware_raid_health RAID array health (1=healthy, 0=degraded/failed)"
    echo "# TYPE hardware_raid_health gauge"
    check_raid_status
    
    echo ""
    echo "# HELP hardware_disk_smart_health Disk SMART health status (1=PASSED, 0=FAILED)"
    echo "# TYPE hardware_disk_smart_health gauge"
    echo "# HELP hardware_disk_temperature_celsius Disk temperature from SMART"
    echo "# TYPE hardware_disk_temperature_celsius gauge"
    echo "# HELP hardware_ssd_wear_level_percent SSD wear level percentage"
    echo "# TYPE hardware_ssd_wear_level_percent gauge"
    check_smart_status
    
    echo ""
    echo "# HELP hardware_power_supply_health Power supply health status"
    echo "# TYPE hardware_power_supply_health gauge"
    check_power_supply
    
    echo ""
    echo "# HELP hardware_ups_health UPS health status (1=online, 0=offline/problem)"
    echo "# TYPE hardware_ups_health gauge"
    echo "# HELP hardware_ups_load_percent UPS load percentage"
    echo "# TYPE hardware_ups_load_percent gauge"
    echo "# HELP hardware_ups_battery_percent UPS battery charge percentage"
    echo "# TYPE hardware_ups_battery_percent gauge"
    echo "# HELP hardware_ups_runtime_minutes UPS estimated runtime in minutes"
    echo "# TYPE hardware_ups_runtime_minutes gauge"
    check_ups_status
    
    echo ""
    echo "# HELP hardware_nvme_temperature_celsius NVMe drive temperature"
    echo "# TYPE hardware_nvme_temperature_celsius gauge"
    echo "# HELP hardware_nvme_wear_percent NVMe drive wear percentage"
    echo "# TYPE hardware_nvme_wear_percent gauge"
    check_nvme_health
    
    echo ""
    echo "# HELP hardware_health_script_last_run Unix timestamp of last script execution"
    echo "# TYPE hardware_health_script_last_run gauge"
    echo "hardware_health_script_last_run $(date +%s)"
    
} > "$TMP_FILE"

mv "$TMP_FILE" "$PROM_FILE"
