#!/bin/bash
# Health check script for token refresh monitoring
# Fixes null handling issues when fields are missing

METRICS_FILE="/var/tmp/runner-token-metrics.json"

if [[ ! -f "$METRICS_FILE" ]]; then
    echo "CRITICAL: Metrics file not found"
    exit 2
fi

# Use jq with defaults to handle null/missing fields
consecutive_failures=$(jq -r '.consecutive_failures // 0' "$METRICS_FILE")
last_check=$(jq -r '.last_check_timestamp // 0' "$METRICS_FILE")
current_time=$(date +%s)

# Handle cases where last_check might be 0 or null
if [[ "$last_check" == "0" ]] || [[ "$last_check" == "null" ]]; then
    echo "WARNING: No check timestamp found in metrics"
    exit 1
fi

time_since_check=$((current_time - last_check))

# Handle null/missing consecutive_failures
if [[ "$consecutive_failures" == "null" ]]; then
    consecutive_failures=0
fi

if [[ $consecutive_failures -ge 3 ]]; then
    echo "CRITICAL: $consecutive_failures consecutive refresh failures"
    exit 2
fi

if [[ $time_since_check -gt 300 ]]; then
    echo "WARNING: Last check was ${time_since_check}s ago"
    exit 1
fi

echo "OK: Token refresh healthy (last check: ${time_since_check}s ago, failures: ${consecutive_failures})"
exit 0
