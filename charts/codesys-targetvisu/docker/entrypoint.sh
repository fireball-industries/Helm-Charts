#!/bin/bash
# ========================================
# CODESYS TargetVisu Entrypoint Script
# ========================================
# "The script that tries its best to start
# your HMI before the operators notice."
# ========================================

set -e

echo "========================================="
echo "CODESYS TargetVisu for Linux SL"
echo "Container Startup"
echo "========================================="
echo "Made with 💀 by Fireball Industries"
echo "========================================="

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to log errors
error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
}

# Check if running as root
if [ "$(id -u)" -eq 0 ]; then
    log "Running as root (CODESYS may require elevated privileges)"
else
    log "Running as user: $(id -un)"
fi

# ========================================
# Environment Setup
# ========================================
log "Setting up environment..."

export CODESYS_HOME=${CODESYS_HOME:-/opt/codesys}
export CODESYS_CONFIG=${CODESYS_CONFIG:-/var/opt/codesys}
export CODESYS_PROJECTS=${CODESYS_PROJECTS:-/projects}
export CODESYS_LOGS=${CODESYS_LOGS:-/var/log/codesys}

# ========================================
# Verify Directories
# ========================================
log "Verifying directories..."

for dir in "$CODESYS_CONFIG" "$CODESYS_PROJECTS" "$CODESYS_LOGS"; do
    if [ ! -d "$dir" ]; then
        log "Creating directory: $dir"
        mkdir -p "$dir"
    fi
done

# ========================================
# License Handling
# ========================================
log "Checking license..."

LICENSE_DIR="$CODESYS_CONFIG/license"
if [ -d "$LICENSE_DIR" ] && [ -n "$(ls -A $LICENSE_DIR 2>/dev/null)" ]; then
    log "License file(s) found in $LICENSE_DIR"
    ls -lh "$LICENSE_DIR"
else
    log "WARNING: No license file found. Running in demo/trial mode."
    log "Place license file in Kubernetes Secret mounted at $LICENSE_DIR"
fi

# ========================================
# Configuration Files
# ========================================
log "Checking configuration files..."

CONFIG_FILE="$CODESYS_CONFIG/CODESYSControl.cfg"
if [ ! -f "$CONFIG_FILE" ]; then
    log "Creating default configuration..."
    cat > "$CONFIG_FILE" <<EOF
[SysTarget]
TargetVersionName=CODESYS Control for Linux SL
TargetVersionManufacturer=Fireball Industries
TargetVersionVersion=1.0.0

[CmpWebServer]
Port.Https=${CODESYS_HTTPS_PORT:-8443}
Port.Http=${CODESYS_WEB_PORT:-8080}

[CmpWebServerHandlerV3]
Port=${CODESYS_WEBVISU_PORT:-8081}

[CmpLog]
Logger.0.Name=/tmp/codesyscontrol.log
Logger.0.Filter=0x0000000F
Logger.0.Type=normal
Logger.0.Backend.0.ClassId=0x00000104

[SysMem]
; Adjust memory pool size as needed
LinuxMemAllocator.Size=8388608

[SysFile]
; File paths
FilePath.1=/projects
FilePath.2=/var/opt/codesys

EOF
    log "Default configuration created."
else
    log "Using existing configuration file."
fi

# ========================================
# Network Configuration
# ========================================
log "Network configuration:"
log "  HTTP Port:    ${CODESYS_WEB_PORT:-8080}"
log "  HTTPS Port:   ${CODESYS_HTTPS_PORT:-8443}"
log "  WebVisu Port: ${CODESYS_WEBVISU_PORT:-8081}"

if [ "${OPCUA_ENABLED}" = "true" ]; then
    log "  OPC UA Port:  ${OPCUA_PORT:-4840}"
fi

if [ "${MODBUS_TCP_ENABLED}" = "true" ]; then
    log "  Modbus TCP:   ${MODBUS_TCP_PORT:-502}"
fi

# ========================================
# PLC Connection
# ========================================
if [ "${PLC_ENABLED}" = "true" ]; then
    log "PLC Integration enabled"
    log "  Connection Type: ${PLC_CONNECTION_TYPE:-local}"
    
    if [ "${PLC_CONNECTION_TYPE}" = "remote" ]; then
        log "  Remote PLC: ${PLC_REMOTE_HOST}:${PLC_REMOTE_PORT:-11740}"
        
        # Test connectivity
        if command -v nc >/dev/null 2>&1; then
            if nc -z -w5 "${PLC_REMOTE_HOST}" "${PLC_REMOTE_PORT:-11740}"; then
                log "  ✅ PLC is reachable"
            else
                error "❌ Cannot reach PLC at ${PLC_REMOTE_HOST}:${PLC_REMOTE_PORT:-11740}"
                log "  Continuing anyway (it might come up later)"
            fi
        fi
    else
        log "  Using local shared memory connection"
    fi
fi

# ========================================
# Prometheus Metrics
# ========================================
if [ "${PROMETHEUS_ENABLED}" = "true" ]; then
    log "Prometheus metrics enabled on port ${PROMETHEUS_PORT:-9100}"
fi

# ========================================
# Runtime Diagnostics
# ========================================
log "System information:"
log "  Hostname: $(hostname)"
log "  CPU cores: $(nproc)"
log "  Memory: $(free -h | awk '/^Mem:/ {print $2}')"
log "  Disk space:"
df -h | grep -E "^/dev|^Filesystem" | while read line; do
    log "    $line"
done

# ========================================
# Pre-flight Checks
# ========================================
log "Running pre-flight checks..."

# Check if CODESYS executable exists
if [ ! -f "$CODESYS_HOME/bin/codesysvisu" ] && [ ! -f "$CODESYS_HOME/bin/codesyscontrol" ]; then
    error "CODESYS executable not found!"
    error "Expected at: $CODESYS_HOME/bin/codesysvisu"
    exit 1
fi

# Check write permissions
for dir in "$CODESYS_CONFIG" "$CODESYS_PROJECTS" "$CODESYS_LOGS"; do
    if [ ! -w "$dir" ]; then
        error "No write permission for: $dir"
        exit 1
    fi
done

log "✅ Pre-flight checks passed"

# ========================================
# Signal Handling
# ========================================
log "Setting up signal handlers..."

# Graceful shutdown function
shutdown() {
    log "Received shutdown signal, stopping CODESYS gracefully..."
    if [ -n "$CODESYS_PID" ]; then
        kill -TERM "$CODESYS_PID" 2>/dev/null || true
        wait "$CODESYS_PID" 2>/dev/null || true
    fi
    log "CODESYS stopped. Goodbye!"
    exit 0
}

trap shutdown SIGTERM SIGINT

# ========================================
# Start CODESYS TargetVisu
# ========================================
log "========================================="
log "Starting CODESYS TargetVisu..."
log "========================================="
log "Log level: ${CODESYS_LOG_LEVEL:-info}"
log "Max clients: ${CODESYS_MAX_CLIENTS:-10}"
log "========================================="

# Determine which executable to run
if [ -f "$CODESYS_HOME/bin/codesysvisu" ]; then
    CODESYS_BIN="$CODESYS_HOME/bin/codesysvisu"
elif [ -f "$CODESYS_HOME/bin/codesyscontrol" ]; then
    CODESYS_BIN="$CODESYS_HOME/bin/codesyscontrol"
else
    error "No CODESYS executable found!"
    exit 1
fi

log "Executable: $CODESYS_BIN"

# If arguments are provided, use them; otherwise use defaults
if [ $# -eq 0 ]; then
    log "No arguments provided, using default command"
    exec "$CODESYS_BIN" &
else
    log "Running: $@"
    exec "$@" &
fi

CODESYS_PID=$!
log "CODESYS started with PID: $CODESYS_PID"

log "========================================="
log "🏭 CODESYS TargetVisu is running! 🏭"
log "========================================="
log "Your HMI is live. Your PLC might not be."
log "The operators are already complaining."
log "Welcome to industrial automation."
log "========================================="

# Wait for CODESYS process
wait $CODESYS_PID
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    error "CODESYS exited with code: $EXIT_CODE"
    error "Check logs in $CODESYS_LOGS"
fi

exit $EXIT_CODE
