#!/bin/bash
# License Expiry Monitoring Script
# Tracks software license expiration dates
# Alerts before licenses expire

set -euo pipefail

TEXTFILE_DIR="/var/lib/node_exporter/textfile_collector"
PROM_FILE="$TEXTFILE_DIR/license_expiry.prom"
TMP_FILE="$PROM_FILE.$$"

# License database (replace with your actual license management system)
declare -A LICENSES=(
    ["monitoring_tool"]="2026-03-15"
    ["database_license"]="2026-06-30"
    ["backup_software"]="2025-12-31"
    ["antivirus"]="2026-09-01"
    ["ssl_certificate"]="2026-02-28"
)

declare -A LICENSE_TYPES=(
    ["monitoring_tool"]="enterprise"
    ["database_license"]="standard"
    ["backup_software"]="premium"
    ["antivirus"]="business"
    ["ssl_certificate"]="wildcard"
)

# Function to calculate days until expiry
days_until_expiry() {
    local expiry_date=$1
    local expiry_epoch=$(date -d "$expiry_date" +%s)
    local current_epoch=$(date +%s)
    local days=$(( (expiry_epoch - current_epoch) / 86400 ))
    echo $days
}

# Function to get license status
get_license_status() {
    local days=$1
    
    if [ $days -lt 0 ]; then
        echo "expired"
    elif [ $days -lt 30 ]; then
        echo "critical"
    elif [ $days -lt 60 ]; then
        echo "warning"
    else
        echo "valid"
    fi
}

# Generate metrics
{
    echo "# HELP license_expiry_days Days until software license expires (negative=expired)"
    echo "# TYPE license_expiry_days gauge"
    
    for software in "${!LICENSES[@]}"; do
        expiry_date="${LICENSES[$software]}"
        license_type="${LICENSE_TYPES[$software]}"
        days=$(days_until_expiry "$expiry_date")
        status=$(get_license_status $days)
        
        echo "license_expiry_days{software=\"$software\",license_type=\"$license_type\",expiry_date=\"$expiry_date\",status=\"$status\"} $days"
    done
    
    echo ""
    echo "# HELP license_status License status (1=valid, 0=expired)"
    echo "# TYPE license_status gauge"
    
    for software in "${!LICENSES[@]}"; do
        expiry_date="${LICENSES[$software]}"
        license_type="${LICENSE_TYPES[$software]}"
        days=$(days_until_expiry "$expiry_date")
        
        if [ $days -ge 0 ]; then
            echo "license_status{software=\"$software\",license_type=\"$license_type\"} 1"
        else
            echo "license_status{software=\"$software\",license_type=\"$license_type\"} 0"
        fi
    done
    
    echo ""
    echo "# HELP license_check_last_run Unix timestamp of last license check"
    echo "# TYPE license_check_last_run gauge"
    echo "license_check_last_run $(date +%s)"
    
    echo ""
    echo "# HELP license_count_total Total number of licenses tracked"
    echo "# TYPE license_count_total gauge"
    echo "license_count_total ${#LICENSES[@]}"
    
} > "$TMP_FILE"

mv "$TMP_FILE" "$PROM_FILE"

# Prometheus alert examples:
#
# - alert: LicenseExpiringSoon
#   expr: license_expiry_days < 30 and license_expiry_days >= 0
#   for: 24h
#   labels:
#     severity: warning
#   annotations:
#     summary: "License {{ $labels.software }} expires in {{ $value }} days"
#     description: "Renew license before {{ $labels.expiry_date }}"
#
# - alert: LicenseExpired
#   expr: license_expiry_days < 0
#   for: 1h
#   labels:
#     severity: critical
#   annotations:
#     summary: "License {{ $labels.software }} has EXPIRED"
#     description: "License expired {{ $value | humanize }} days ago"
#
# - alert: LicenseCritical
#   expr: license_expiry_days < 7 and license_expiry_days >= 0
#   for: 1h
#   labels:
#     severity: critical
#   annotations:
#     summary: "URGENT: License {{ $labels.software }} expires in {{ $value }} days!"
