#!/bin/bash
# Backup Status Monitoring Script
# Exports backup job status as Prometheus metrics
# Run via cron after backup completes

set -euo pipefail

TEXTFILE_DIR="/var/lib/node_exporter/textfile_collector"
PROM_FILE="$TEXTFILE_DIR/backup_status.prom"
TMP_FILE="$PROM_FILE.$$"

# Backup configuration
BACKUP_TYPES=("full" "incremental" "differential")
BACKUP_TARGETS=("database" "files" "logs")

# Function to get last backup timestamp from backup system
get_last_backup_time() {
    local backup_type=$1
    local target=$2
    
    # Example: Parse backup log file
    # Replace with your actual backup system query
    local log_file="/var/log/backup/${backup_type}_${target}.log"
    
    if [ -f "$log_file" ]; then
        # Get last successful backup timestamp
        grep "Backup completed successfully" "$log_file" | tail -1 | \
            awk '{print $1" "$2}' | xargs -I {} date -d "{}" +%s || echo 0
    else
        echo 0
    fi
}

# Function to get backup size
get_backup_size() {
    local backup_type=$1
    local target=$2
    
    # Example: Get size from backup directory
    local backup_dir="/backups/${backup_type}/${target}"
    
    if [ -d "$backup_dir" ]; then
        du -sb "$backup_dir" | awk '{print $1}'
    else
        echo 0
    fi
}

# Function to check backup health
check_backup_health() {
    local backup_type=$1
    local target=$2
    
    local last_backup=$(get_last_backup_time "$backup_type" "$target")
    local current_time=$(date +%s)
    local age=$((current_time - last_backup))
    
    # Health criteria (example)
    case "$backup_type" in
        "full")
            # Full backup should be < 7 days old
            [ $age -lt $((7 * 86400)) ] && echo 1 || echo 0
            ;;
        "incremental")
            # Incremental should be < 1 day old
            [ $age -lt 86400 ] && echo 1 || echo 0
            ;;
        *)
            echo 0
            ;;
    esac
}

# Generate metrics
{
    echo "# HELP backup_last_success_timestamp Unix timestamp of last successful backup"
    echo "# TYPE backup_last_success_timestamp gauge"
    
    for backup_type in "${BACKUP_TYPES[@]}"; do
        for target in "${BACKUP_TARGETS[@]}"; do
            timestamp=$(get_last_backup_time "$backup_type" "$target")
            echo "backup_last_success_timestamp{backup_type=\"$backup_type\",target=\"$target\"} $timestamp"
        done
    done
    
    echo ""
    echo "# HELP backup_size_bytes Size of last backup in bytes"
    echo "# TYPE backup_size_bytes gauge"
    
    for backup_type in "${BACKUP_TYPES[@]}"; do
        for target in "${BACKUP_TARGETS[@]}"; do
            size=$(get_backup_size "$backup_type" "$target")
            echo "backup_size_bytes{backup_type=\"$backup_type\",target=\"$target\"} $size"
        done
    done
    
    echo ""
    echo "# HELP backup_health_status Backup health status (1=healthy, 0=unhealthy)"
    echo "# TYPE backup_health_status gauge"
    
    for backup_type in "${BACKUP_TYPES[@]}"; do
        for target in "${BACKUP_TARGETS[@]}"; do
            health=$(check_backup_health "$backup_type" "$target")
            echo "backup_health_status{backup_type=\"$backup_type\",target=\"$target\"} $health"
        done
    done
    
    echo ""
    echo "# HELP backup_script_last_run Unix timestamp of last script execution"
    echo "# TYPE backup_script_last_run gauge"
    echo "backup_script_last_run $(date +%s)"
    
} > "$TMP_FILE"

# Atomic move
mv "$TMP_FILE" "$PROM_FILE"

# Alert examples in Prometheus:
# - alert: BackupTooOld
#   expr: time() - backup_last_success_timestamp > 86400
#   for: 1h
#   annotations:
#     summary: "Backup {{ $labels.backup_type }} for {{ $labels.target }} is >24h old"
#
# - alert: BackupUnhealthy
#   expr: backup_health_status == 0
#   for: 30m
#   annotations:
#     summary: "Backup {{ $labels.backup_type }} for {{ $labels.target }} is unhealthy"
