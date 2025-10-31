#!/usr/bin/env bash
# Script: network.sh
# Description: Network utilities with proper timeout and retry handling
# Usage: source "${SCRIPT_DIR}/lib/network.sh"

# Network timeout configuration (can be overridden by environment variables)
CONNECT_TIMEOUT="${CONNECT_TIMEOUT:-10}"      # Connection timeout in seconds
MAX_TIMEOUT="${MAX_TIMEOUT:-30}"              # Maximum request timeout in seconds
READ_TIMEOUT="${READ_TIMEOUT:-20}"            # Read timeout for streaming
# DNS_TIMEOUT: Maximum time to wait for DNS resolution to complete
# This prevents stalls when DNS servers are slow, unresponsive, or misconfigured
# Default: 5 seconds. Requires curl with --dns-timeout support (not available on all platforms)
DNS_TIMEOUT="${DNS_TIMEOUT:-5}"               # DNS resolution timeout in seconds
RETRY_ATTEMPTS="${RETRY_ATTEMPTS:-3}"         # Number of retry attempts
RETRY_BACKOFF="${RETRY_BACKOFF:-exponential}" # Backoff strategy: exponential or linear

# GitHub CLI timeout configuration
export GH_REQUEST_TIMEOUT="${GH_REQUEST_TIMEOUT:-30}"

# Check if curl supports --dns-timeout (not available on all platforms like Windows Git Bash)
CURL_SUPPORTS_DNS_TIMEOUT=false
if curl --help all 2>/dev/null | grep -q -- "--dns-timeout" 2>/dev/null; then
    CURL_SUPPORTS_DNS_TIMEOUT=true
fi

################################################################################
# Core Network Functions
################################################################################

# Execute curl with standardized timeout settings
# Usage: curl_with_timeout [curl_args...]
curl_with_timeout() {
    if [[ "${CURL_SUPPORTS_DNS_TIMEOUT}" == "true" ]]; then
        curl \
            --connect-timeout "${CONNECT_TIMEOUT}" \
            --max-time "${MAX_TIMEOUT}" \
            --dns-timeout "${DNS_TIMEOUT}" \
            "$@"
    else
        curl \
            --connect-timeout "${CONNECT_TIMEOUT}" \
            --max-time "${MAX_TIMEOUT}" \
            "$@"
    fi
}

# Execute curl with timeout and retry logic
# Usage: curl_with_retry URL [MAX_ATTEMPTS] [BASE_TIMEOUT] [CURL_ARGS...]
curl_with_retry() {
    local url="$1"
    local max_attempts="${2:-${RETRY_ATTEMPTS}}"
    local base_timeout="${3:-${MAX_TIMEOUT}}"
    shift 3
    local curl_args=("$@")

    local attempt=1
    local exit_code=0

    while [[ $attempt -le $max_attempts ]]; do
        # Calculate timeout with progressive increase
        local timeout
        if [[ "$RETRY_BACKOFF" == "exponential" ]]; then
            timeout=$((base_timeout * attempt))
        else
            # Linear backoff
            timeout=$((base_timeout + (attempt - 1) * 10))
        fi

        # Cap maximum timeout at 120 seconds
        if [[ $timeout -gt 120 ]]; then
            timeout=120
        fi

        if [[ -n "${LOG_DEBUG:-}" ]] || [[ "${VERBOSE:-false}" == "true" ]]; then
            echo "[DEBUG] Network request attempt ${attempt}/${max_attempts} (timeout: ${timeout}s): ${url}" >&2
        fi

        # Execute curl with timeout
        local curl_cmd=(curl --connect-timeout "${CONNECT_TIMEOUT}" --max-time "$timeout")

        if [[ "${CURL_SUPPORTS_DNS_TIMEOUT}" == "true" ]]; then
            curl_cmd+=(--dns-timeout "${DNS_TIMEOUT}")
        fi

        curl_cmd+=("${curl_args[@]}" "$url")

        if "${curl_cmd[@]}"; then
            return 0
        fi

        exit_code=$?

        # Check if we should retry
        if [[ $attempt -lt $max_attempts ]]; then
            # Calculate backoff delay
            local backoff_delay
            if [[ "$RETRY_BACKOFF" == "exponential" ]]; then
                # Exponential backoff: 1s, 2s, 4s, 8s
                backoff_delay=$((2 ** (attempt - 1)))
            else
                # Linear backoff: 2s, 4s, 6s
                backoff_delay=$((2 * attempt))
            fi

            # Cap maximum backoff at 10 seconds
            if [[ $backoff_delay -gt 10 ]]; then
                backoff_delay=10
            fi

            if [[ -n "${LOG_WARN:-}" ]] || [[ "${VERBOSE:-false}" == "true" ]]; then
                echo "[WARN] Request failed (exit code: ${exit_code}), retrying in ${backoff_delay}s..." >&2
            fi

            sleep "$backoff_delay"
            attempt=$((attempt + 1))
        else
            if [[ -n "${LOG_ERROR:-}" ]] || [[ "${VERBOSE:-false}" == "true" ]]; then
                echo "[ERROR] Request failed after ${max_attempts} attempts (exit code: ${exit_code})" >&2
            fi
            return "$exit_code"
        fi
    done

    return "$exit_code"
}

# Download file with timeout and retry
# Usage: download_with_retry URL OUTPUT_FILE [MAX_ATTEMPTS]
download_with_retry() {
    local url="$1"
    local output_file="$2"
    local max_attempts="${3:-${RETRY_ATTEMPTS}}"

    curl_with_retry "$url" "$max_attempts" "${MAX_TIMEOUT}" \
        -L -o "$output_file" -f -s -S
}

# Check URL accessibility with timeout
# Usage: check_url_accessible URL [TIMEOUT]
check_url_accessible() {
    local url="$1"
    local timeout="${2:-${MAX_TIMEOUT}}"

    if [[ "${CURL_SUPPORTS_DNS_TIMEOUT}" == "true" ]]; then
        curl \
            --connect-timeout "${CONNECT_TIMEOUT}" \
            --max-time "$timeout" \
            --dns-timeout "${DNS_TIMEOUT}" \
            -s -f -o /dev/null \
            "$url"
    else
        curl \
            --connect-timeout "${CONNECT_TIMEOUT}" \
            --max-time "$timeout" \
            -s -f -o /dev/null \
            "$url"
    fi
}

# Get HTTP status code with timeout
# Usage: get_http_status URL [TIMEOUT]
get_http_status() {
    local url="$1"
    local timeout="${2:-${MAX_TIMEOUT}}"

    if [[ "${CURL_SUPPORTS_DNS_TIMEOUT}" == "true" ]]; then
        curl \
            --connect-timeout "${CONNECT_TIMEOUT}" \
            --max-time "$timeout" \
            --dns-timeout "${DNS_TIMEOUT}" \
            -s -o /dev/null -w "%{http_code}" \
            "$url" || echo "000"
    else
        curl \
            --connect-timeout "${CONNECT_TIMEOUT}" \
            --max-time "$timeout" \
            -s -o /dev/null -w "%{http_code}" \
            "$url" || echo "000"
    fi
}

# Check network connectivity to GitHub
# Usage: check_github_connectivity
check_github_connectivity() {
    local endpoints=(
        "https://api.github.com"
        "https://github.com"
    )

    for endpoint in "${endpoints[@]}"; do
        if ! check_url_accessible "$endpoint" 10; then
            if [[ -n "${LOG_ERROR:-}" ]]; then
                echo "[ERROR] Cannot reach $endpoint" >&2
            fi
            return 1
        fi
    done

    return 0
}

# Test network latency to URL
# Usage: measure_latency URL
measure_latency() {
    local url="$1"

    if [[ "${CURL_SUPPORTS_DNS_TIMEOUT}" == "true" ]]; then
        curl \
            --connect-timeout "${CONNECT_TIMEOUT}" \
            --max-time "${MAX_TIMEOUT}" \
            --dns-timeout "${DNS_TIMEOUT}" \
            -o /dev/null -s -w '%{time_total}' \
            "$url" 2>/dev/null || echo "999"
    else
        curl \
            --connect-timeout "${CONNECT_TIMEOUT}" \
            --max-time "${MAX_TIMEOUT}" \
            -o /dev/null -s -w '%{time_total}' \
            "$url" 2>/dev/null || echo "999"
    fi
}

# Test TCP port connectivity with timeout
# Usage: test_tcp_port HOST PORT [TIMEOUT]
test_tcp_port() {
    local host="$1"
    local port="$2"
    local timeout="${3:-5}"

    if command -v timeout &>/dev/null; then
        timeout "$timeout" bash -c "cat < /dev/null > /dev/tcp/$host/$port" 2>/dev/null
    else
        # Fallback without timeout command (less precise)
        bash -c "cat < /dev/null > /dev/tcp/$host/$port" 2>/dev/null &
        local pid=$!

        # Use floating-point arithmetic for precise timeout tracking
        local elapsed=0
        local sleep_interval=0.1
        # Calculate max iterations: timeout / sleep_interval
        local max_iterations=$((timeout * 10))

        while [[ $elapsed -lt $max_iterations ]]; do
            if ! kill -0 "$pid" 2>/dev/null; then
                wait "$pid"
                return $?
            fi
            sleep "$sleep_interval"
            elapsed=$((elapsed + 1))
        done

        kill -9 "$pid" 2>/dev/null
        return 1
    fi
}

################################################################################
# GitHub API Functions with Timeout
################################################################################

# Call GitHub API with timeout and retry
# Usage: github_api_call ENDPOINT [METHOD] [DATA]
github_api_call() {
    local endpoint="$1"
    local method="${2:-GET}"
    local data="${3:-}"

    local token
    token="${GITHUB_TOKEN:-}"
    if [[ -z "$token" ]] && command -v gh &>/dev/null; then
        token=$(gh auth token 2>/dev/null || echo "")
    fi

    local curl_args=(-s -f)

    if [[ -n "$token" ]]; then
        curl_args+=(-H "Authorization: Bearer $token")
    fi

    curl_args+=(-H "Accept: application/vnd.github+json")
    curl_args+=(-H "X-GitHub-Api-Version: 2022-11-28")

    if [[ "$method" != "GET" ]]; then
        curl_args+=(-X "$method")
    fi

    if [[ -n "$data" ]]; then
        curl_args+=(-H "Content-Type: application/json")
        curl_args+=(-d "$data")
    fi

    curl_with_retry "$endpoint" "${RETRY_ATTEMPTS}" "${MAX_TIMEOUT}" "${curl_args[@]}"
}

# Get GitHub rate limit with timeout
# Usage: get_github_rate_limit
get_github_rate_limit() {
    github_api_call "https://api.github.com/rate_limit"
}

################################################################################
# Utility Functions
################################################################################

# Print network configuration
print_network_config() {
    cat <<EOF
Network Configuration:
  Connect Timeout: ${CONNECT_TIMEOUT}s
  Max Timeout: ${MAX_TIMEOUT}s
  Read Timeout: ${READ_TIMEOUT}s
  DNS Timeout: ${DNS_TIMEOUT}s
  DNS Timeout Support: ${CURL_SUPPORTS_DNS_TIMEOUT}
  Retry Attempts: ${RETRY_ATTEMPTS}
  Retry Backoff: ${RETRY_BACKOFF}
  GH Request Timeout: ${GH_REQUEST_TIMEOUT}s
EOF
}

# Export timeout values for subprocesses
export_network_config() {
    export CONNECT_TIMEOUT
    export MAX_TIMEOUT
    export READ_TIMEOUT
    export DNS_TIMEOUT
    export RETRY_ATTEMPTS
    export RETRY_BACKOFF
    export GH_REQUEST_TIMEOUT
}

# Validate timeout configuration
validate_network_config() {
    local errors=0

    if [[ $CONNECT_TIMEOUT -lt 1 ]] || [[ $CONNECT_TIMEOUT -gt 60 ]]; then
        echo "[ERROR] CONNECT_TIMEOUT must be between 1-60 seconds" >&2
        errors=$((errors + 1))
    fi

    if [[ $MAX_TIMEOUT -lt 1 ]] || [[ $MAX_TIMEOUT -gt 300 ]]; then
        echo "[ERROR] MAX_TIMEOUT must be between 1-300 seconds" >&2
        errors=$((errors + 1))
    fi

    if [[ $READ_TIMEOUT -lt 1 ]] || [[ $READ_TIMEOUT -gt 120 ]]; then
        echo "[ERROR] READ_TIMEOUT must be between 1-120 seconds" >&2
        errors=$((errors + 1))
    fi

    if [[ $DNS_TIMEOUT -lt 1 ]] || [[ $DNS_TIMEOUT -gt 30 ]]; then
        echo "[ERROR] DNS_TIMEOUT must be between 1-30 seconds" >&2
        errors=$((errors + 1))
    fi

    if [[ $RETRY_ATTEMPTS -lt 1 ]] || [[ $RETRY_ATTEMPTS -gt 10 ]]; then
        echo "[ERROR] RETRY_ATTEMPTS must be between 1-10" >&2
        errors=$((errors + 1))
    fi

    if [[ "$RETRY_BACKOFF" != "exponential" ]] && [[ "$RETRY_BACKOFF" != "linear" ]]; then
        echo "[ERROR] RETRY_BACKOFF must be 'exponential' or 'linear'" >&2
        errors=$((errors + 1))
    fi

    return "$errors"
}

# Export functions for use in other scripts
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Only export if sourced
    export -f curl_with_timeout curl_with_retry download_with_retry
    export -f check_url_accessible get_http_status check_github_connectivity
    export -f measure_latency test_tcp_port github_api_call get_github_rate_limit
    export -f print_network_config export_network_config validate_network_config
fi
