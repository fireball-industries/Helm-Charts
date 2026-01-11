#!/bin/bash
# ========================================
# CODESYS TargetVisu Health Check Script
# ========================================
# "Checks if your HMI is still alive.
# Spoiler: It's probably fine. The PLC though..."
# ========================================

set -e

# Health check timeout
TIMEOUT=5

# Web server port
HTTP_PORT=${CODESYS_WEB_PORT:-8080}

# Health endpoint
HEALTH_ENDPOINT="http://localhost:${HTTP_PORT}/health"

# Function to check if web server is responding
check_web_server() {
    if command -v curl >/dev/null 2>&1; then
        # Use curl if available
        if curl -sf --max-time $TIMEOUT "$HEALTH_ENDPOINT" >/dev/null 2>&1; then
            return 0
        fi
        # Fallback to root endpoint
        if curl -sf --max-time $TIMEOUT "http://localhost:${HTTP_PORT}/" >/dev/null 2>&1; then
            return 0
        fi
    elif command -v wget >/dev/null 2>&1; then
        # Use wget if curl not available
        if wget -q --timeout=$TIMEOUT --spider "$HEALTH_ENDPOINT" 2>/dev/null; then
            return 0
        fi
        if wget -q --timeout=$TIMEOUT --spider "http://localhost:${HTTP_PORT}/" 2>/dev/null; then
            return 0
        fi
    elif command -v nc >/dev/null 2>&1; then
        # Basic TCP check with netcat
        if nc -z -w$TIMEOUT localhost $HTTP_PORT 2>/dev/null; then
            return 0
        fi
    fi
    
    return 1
}

# Function to check if CODESYS process is running
check_process() {
    if pgrep -f "codesysvisu|codesyscontrol" >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

# Main health check
main() {
    # Check if process is running
    if ! check_process; then
        echo "ERROR: CODESYS process is not running"
        exit 1
    fi
    
    # Check if web server is responding
    if ! check_web_server; then
        echo "ERROR: Web server is not responding on port $HTTP_PORT"
        exit 1
    fi
    
    # All checks passed
    echo "OK: CODESYS TargetVisu is healthy"
    exit 0
}

# Run health check
main
