#!/usr/bin/env bash
# Script: runner-token-refresh.sh
# Description: Auto-refresh GitHub Actions runner tokens before expiration
# Usage: ./runner-token-refresh.sh [OPTIONS]
#
# This script monitors GitHub Actions runner token expiration and automatically
# refreshes tokens before they expire (default: 5 minutes before expiration).
# It can run as a daemon service or as a one-time check via cron.

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

# Configuration with defaults
RUNNER_ORG="${RUNNER_ORG:-}"
RUNNER_NAME="${RUNNER_NAME:-$(hostname)}"
RUNNER_URL="${RUNNER_URL:-}"
RUNNER_DIR="${RUNNER_DIR:-./actions-runner}"
REFRESH_THRESHOLD="${REFRESH_THRESHOLD:-300}"  # 5 minutes before expiry
CHECK_INTERVAL="${CHECK_INTERVAL:-60}"          # Check every 60 seconds
MAX_RETRY_ATTEMPTS="${MAX_RETRY_ATTEMPTS:-3}"
RETRY_BACKOFF_SECONDS="${RETRY_BACKOFF_SECONDS:-30}"
TOKEN_CACHE_FILE="${TOKEN_CACHE_FILE:-${RUNNER_DIR}/.token_cache}"
LOG_FILE="${LOG_FILE:-/var/log/github-runner-token-refresh.log}"
METRICS_FILE="${METRICS_FILE:-/var/tmp/runner-token-metrics.json}"

# Mode flags
DAEMON_MODE=false
CHECK_AND_REFRESH_MODE=false
DRY_RUN=false

# Metrics tracking
declare -A METRICS=(
    [last_check_timestamp]=0
    [last_refresh_timestamp]=0
    [total_refreshes]=0
    [failed_refreshes]=0
    [consecutive_failures]=0
)

#######################################
# Show usage information
#######################################
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Auto-refresh GitHub Actions runner tokens before expiration.

OPTIONS:
    --daemon                Run as daemon service (continuous monitoring)
    --check-and-refresh     Check once and refresh if needed (for cron)
    --dry-run              Simulate refresh without making changes
    --org ORG              GitHub organization name
    --runner-dir DIR       Runner installation directory (default: ./actions-runner)
    --threshold SECONDS    Refresh threshold in seconds (default: 300)
    --interval SECONDS     Check interval in seconds (default: 60)
    --log-file FILE        Log file path (default: /var/log/github-runner-token-refresh.log)
    -h, --help             Show this help message

ENVIRONMENT VARIABLES:
    RUNNER_ORG             GitHub organization name
    RUNNER_NAME            Runner name (default: hostname)
    RUNNER_URL             GitHub runner URL
    RUNNER_DIR             Runner installation directory
    REFRESH_THRESHOLD      Seconds before expiry to refresh token
    CHECK_INTERVAL         Seconds between checks (daemon mode)
    MAX_RETRY_ATTEMPTS     Maximum retry attempts on failure
    RETRY_BACKOFF_SECONDS  Seconds to wait between retries

EXAMPLES:
    # Run as daemon
    $(basename "$0") --daemon --org myorg

    # One-time check (for cron)
    $(basename "$0") --check-and-refresh --org myorg

    # Dry run to test
    $(basename "$0") --check-and-refresh --org myorg --dry-run

EOF
    exit 0
}

#######################################
# Parse command line arguments
#######################################
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --daemon)
                DAEMON_MODE=true
                shift
                ;;
            --check-and-refresh)
                CHECK_AND_REFRESH_MODE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --org)
                RUNNER_ORG="$2"
                shift 2
                ;;
            --runner-dir)
                RUNNER_DIR="$2"
                shift 2
                ;;
            --threshold)
                REFRESH_THRESHOLD="$2"
                shift 2
                ;;
            --interval)
                CHECK_INTERVAL="$2"
                shift 2
                ;;
            --log-file)
                LOG_FILE="$2"
                shift 2
                ;;
            -h|--help)
                usage
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done

    # Validate required parameters
    if [[ -z "$RUNNER_ORG" ]]; then
        log_error "Organization name is required (--org or RUNNER_ORG env var)"
        exit 1
    fi

    # Set RUNNER_URL if not provided
    if [[ -z "$RUNNER_URL" ]]; then
        RUNNER_URL="https://github.com/${RUNNER_ORG}"
    fi

    # Default to check-and-refresh if no mode specified
    if [[ "$DAEMON_MODE" == false ]] && [[ "$CHECK_AND_REFRESH_MODE" == false ]]; then
        CHECK_AND_REFRESH_MODE=true
    fi
}

#######################################
# Load metrics from file
#######################################
load_metrics() {
    if [[ -f "$METRICS_FILE" ]] && command -v jq &>/dev/null; then
        local metrics_json
        metrics_json=$(cat "$METRICS_FILE")

        METRICS[last_check_timestamp]=$(echo "$metrics_json" | jq -r '.last_check_timestamp // 0')
        METRICS[last_refresh_timestamp]=$(echo "$metrics_json" | jq -r '.last_refresh_timestamp // 0')
        METRICS[total_refreshes]=$(echo "$metrics_json" | jq -r '.total_refreshes // 0')
        METRICS[failed_refreshes]=$(echo "$metrics_json" | jq -r '.failed_refreshes // 0')
        METRICS[consecutive_failures]=$(echo "$metrics_json" | jq -r '.consecutive_failures // 0')
    fi
}

#######################################
# Save metrics to file
#######################################
save_metrics() {
    if command -v jq &>/dev/null; then
        local metrics_dir
        metrics_dir=$(dirname "$METRICS_FILE")
        mkdir -p "$metrics_dir" 2>/dev/null || true

        cat > "$METRICS_FILE" <<EOF
{
  "last_check_timestamp": ${METRICS[last_check_timestamp]},
  "last_refresh_timestamp": ${METRICS[last_refresh_timestamp]},
  "total_refreshes": ${METRICS[total_refreshes]},
  "failed_refreshes": ${METRICS[failed_refreshes]},
  "consecutive_failures": ${METRICS[consecutive_failures]},
  "runner_org": "$RUNNER_ORG",
  "runner_name": "$RUNNER_NAME"
}
EOF
    fi
}

#######################################
# Log to file with timestamp
#######################################
log_to_file() {
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Create log directory if needed
    local log_dir
    log_dir=$(dirname "$LOG_FILE")
    mkdir -p "$log_dir" 2>/dev/null || true

    echo "[${timestamp}] ${message}" >> "$LOG_FILE" 2>/dev/null || true
}

#######################################
# Check if GitHub CLI is installed and authenticated
#######################################
check_gh_cli() {
    if ! command -v gh &>/dev/null; then
        log_error "GitHub CLI (gh) is not installed"
        log_error "Install from: https://cli.github.com/"
        return 1
    fi

    if ! gh auth status &>/dev/null; then
        log_error "GitHub CLI is not authenticated"
        log_error "Run: gh auth login"
        return 1
    fi

    return 0
}

#######################################
# Extract token expiration from runner configuration
# Arguments:
#   $1 - Runner directory (optional)
# Returns:
#   Unix timestamp of token expiration, or empty if not found
#######################################
get_token_expiration_from_config() {
    local runner_dir="${1:-$RUNNER_DIR}"
    local runner_config="${runner_dir}/.runner"
    local credentials_file="${runner_dir}/.credentials"

    # Try to extract expiration from .runner file (JSON format)
    if [[ -f "$runner_config" ]] && command -v jq &>/dev/null; then
        local expires_at
        expires_at=$(jq -r '.credentials.expires_at // empty' "$runner_config" 2>/dev/null)

        if [[ -n "$expires_at" ]]; then
            # Convert ISO 8601 to Unix timestamp
            local timestamp
            timestamp=$(date -d "$expires_at" +%s 2>/dev/null)
            if [[ -n "$timestamp" ]]; then
                echo "$timestamp"
                return 0
            fi
        fi
    fi
    # Try credentials file
    if [[ -f "$credentials_file" ]] && command -v jq &>/dev/null; then
        local expires_at
        expires_at=$(jq -r '.expires_at // empty' "$credentials_file" 2>/dev/null)

        if [[ -n "$expires_at" ]]; then
            local timestamp
            timestamp=$(date -d "$expires_at" +%s 2>/dev/null)
            if [[ -n "$timestamp" ]]; then
                echo "$timestamp"
                return 0
            fi
        fi
    fi

    # Try token cache file
    if [[ -f "$TOKEN_CACHE_FILE" ]]; then
        local cached_expiry
        cached_expiry=$(cat "$TOKEN_CACHE_FILE" 2>/dev/null)
        if [[ -n "$cached_expiry" ]] && [[ "$cached_expiry" =~ ^[0-9]+$ ]]; then
            echo "$cached_expiry"
            return 0
        fi
    fi

    return 1
}

#######################################
# Check token expiration time
# Returns:
#   Seconds until token expiration, or -1 if cannot determine
#######################################
check_token_expiration() {
    local expires_timestamp

    if ! expires_timestamp=$(get_token_expiration_from_config); then
        log_warn "Cannot determine token expiration time"
        return 1
    fi

    local current_timestamp
    current_timestamp=$(date +%s)
    local time_until_expiry=$((expires_timestamp - current_timestamp))

    echo "$time_until_expiry"
    return 0
}

#######################################
# Get new registration token from GitHub
# Arguments:
#   $1 - Organization name
# Returns:
#   New token and expiration timestamp
#######################################
get_new_registration_token() {
    local org="$1"
    local api_response

    log_info "Requesting new registration token from GitHub..."

    if ! api_response=$(gh api "orgs/${org}/actions/runners/registration-token" 2>&1); then
        log_error "Failed to get registration token: $api_response"
        return 1
    fi

    if ! command -v jq &>/dev/null; then
        log_error "jq is required but not installed"
        return 1
    fi

    local token
    local expires_at
    token=$(echo "$api_response" | jq -r '.token // empty')
    expires_at=$(echo "$api_response" | jq -r '.expires_at // empty')

    if [[ -z "$token" ]] || [[ -z "$expires_at" ]]; then
        log_error "Invalid API response: missing token or expires_at"
        return 1
    fi

    # Convert expiration to Unix timestamp and cache it
    local expires_timestamp
    expires_timestamp=$(date -d "$expires_at" +%s 2>/dev/null)

    if [[ -n "$expires_timestamp" ]]; then
        echo "$expires_timestamp" > "$TOKEN_CACHE_FILE"
        log_debug "Cached token expiration: $expires_at ($expires_timestamp)"
    fi

    echo "$token"
    return 0
}

#######################################
# Get removal token for unregistering runner
# Arguments:
#   $1 - Organization name
#   $2 - Runner ID (optional)
# Returns:
#   Removal token or empty if failed
#######################################
get_removal_token() {
    local org="$1"
    local runner_id="$2"
    local api_response

    # If runner_id not provided, try to get it from runner config
    if [[ -z "$runner_id" ]]; then
        if [[ -f "${RUNNER_DIR}/.runner" ]] && command -v jq &>/dev/null; then
            runner_id=$(jq -r '.agentId // empty' "${RUNNER_DIR}/.runner" 2>/dev/null)
        fi
    fi

    # If still no runner_id, cannot get removal token
    if [[ -z "$runner_id" ]]; then
        log_warn "Runner ID not found, cannot get removal token"
        return 1
    fi

    log_debug "Getting removal token for runner ID: $runner_id"

    if ! api_response=$(gh api "orgs/${org}/actions/runners/${runner_id}/removal-token" 2>&1); then
        log_warn "Failed to get removal token: $api_response"
        return 1
    fi

    local token
    token=$(echo "$api_response" | jq -r '.token // empty')

    if [[ -z "$token" ]]; then
        log_warn "Invalid removal token response"
        return 1
    fi

    echo "$token"
    return 0
}

#######################################
# Update runner configuration with new token
# Arguments:
#   $1 - New registration token
# Returns:
#   0 on success, 1 on failure
#######################################
update_runner_token() {
    local new_token="$1"
    local runner_dir="${RUNNER_DIR}"

    if [[ ! -d "$runner_dir" ]]; then
        log_error "Runner directory not found: $runner_dir"
        return 1
    fi

    log_info "Updating runner configuration with new token..."

    # Check if runner service is running
    local service_name
    service_name=$(systemctl list-units --type=service --all 2>/dev/null | grep -E "actions.runner.${RUNNER_ORG}.${RUNNER_NAME}.service|actions.runner.[^[:space:]]+.service" | awk '{print $1}' | head -1 || true)

    local service_was_running=false
    if [[ -n "$service_name" ]]; then
        if systemctl is-active --quiet "$service_name" 2>/dev/null; then
            service_was_running=true
            log_info "Stopping runner service: $service_name"

            if [[ "$DRY_RUN" == false ]]; then
                if ! sudo systemctl stop "$service_name" 2>&1; then
                    log_warn "Failed to stop service (continuing anyway)"
                fi
                sleep 2
            else
                log_info "[DRY RUN] Would stop service: $service_name"
            fi
        fi
    fi

    # Reconfigure runner with new token
    cd "$runner_dir" || return 1

    if [[ "$DRY_RUN" == false ]]; then
        # Remove old configuration
        # Get removal token if possible
        local removal_token
        if removal_token=$(get_removal_token "$RUNNER_ORG" ""); then
            log_debug "Using removal token for unregistration"
            if ! ./config.sh remove --token "$removal_token" 2>&1; then
                log_warn "Failed to remove with removal token, trying without token"
                # Fall back to remove without token
                if ! ./config.sh remove 2>&1; then
                    log_warn "Failed to remove old configuration (may not be registered)"
                fi
            fi
        else
            # Try to remove without token as fallback
            log_debug "Attempting removal without token"
            if ! ./config.sh remove 2>&1; then
                log_warn "Failed to remove old configuration (may not be registered)"
            fi
        fi

        # Register with new token
        log_info "Registering runner with new token..."
        if ! ./config.sh --url "$RUNNER_URL" --token "$new_token" --name "$RUNNER_NAME" --unattended 2>&1; then
            log_error "Failed to register runner with new token"
            return 1
        fi
    else
        log_info "[DRY RUN] Would remove and re-register runner"
    fi

    # Restart service if it was running
    if [[ "$service_was_running" == true ]] && [[ -n "$service_name" ]]; then
        log_info "Starting runner service: $service_name"

        if [[ "$DRY_RUN" == false ]]; then
            if ! sudo systemctl start "$service_name" 2>&1; then
                log_error "Failed to start service"
                return 1
            fi

            # Wait for service to be active
            sleep 2
            if systemctl is-active --quiet "$service_name"; then
                log_info "Runner service is active"
            else
                log_warn "Runner service may not be active"
            fi
        else
            log_info "[DRY RUN] Would start service: $service_name"
        fi
    fi

    log_info "Runner configuration updated successfully"
    return 0
}

#######################################
# Refresh token with retry logic
# Returns:
#   0 on success, 1 on failure
#######################################
refresh_token_with_retry() {
    local attempt=1
    local new_token

    while [[ $attempt -le $MAX_RETRY_ATTEMPTS ]]; do
        log_info "Refresh attempt $attempt of $MAX_RETRY_ATTEMPTS..."

        # Get new token
        if new_token=$(get_new_registration_token "$RUNNER_ORG"); then
            # Update runner configuration
            if update_runner_token "$new_token"; then
                log_info "Token refreshed successfully on attempt $attempt"
                log_to_file "Token refreshed successfully (attempt $attempt)"

                # Update metrics
                METRICS[last_refresh_timestamp]=$(date +%s)
                METRICS[total_refreshes]=$((METRICS[total_refreshes] + 1))
                METRICS[consecutive_failures]=0
                save_metrics

                return 0
            else
                log_error "Failed to update runner configuration"
            fi
        else
            log_error "Failed to get new token from GitHub"
        fi

        # Increment attempt and backoff
        attempt=$((attempt + 1))

        if [[ $attempt -le $MAX_RETRY_ATTEMPTS ]]; then
            log_warn "Waiting ${RETRY_BACKOFF_SECONDS}s before retry..."
            sleep "$RETRY_BACKOFF_SECONDS"
        fi
    done

    log_error "Failed to refresh token after $MAX_RETRY_ATTEMPTS attempts"
    log_to_file "Token refresh failed after $MAX_RETRY_ATTEMPTS attempts"

    # Update metrics
    METRICS[failed_refreshes]=$((METRICS[failed_refreshes] + 1))
    METRICS[consecutive_failures]=$((METRICS[consecutive_failures] + 1))
    save_metrics

    # Alert on consecutive failures
    if [[ ${METRICS[consecutive_failures]} -ge 3 ]]; then
        log_error "ALERT: ${METRICS[consecutive_failures]} consecutive refresh failures!"
        log_to_file "ALERT: ${METRICS[consecutive_failures]} consecutive refresh failures!"
    fi

    return 1
}

#######################################
# Perform single check and refresh if needed
# Returns:
#   0 if no action needed or refresh successful, 1 on error
#######################################
check_and_refresh_once() {
    log_info "Checking token expiration..."

    local time_left
    time_left=$(check_token_expiration)
    local expiration_status=$?

    # Update metrics
    METRICS[last_check_timestamp]=$(date +%s)
    save_metrics

    if [[ $expiration_status -ne 0 ]]; then
        log_warn "Cannot determine token expiration - attempting refresh anyway"
        log_to_file "Token expiration unknown - refreshing"
        refresh_token_with_retry
        return $?
    fi

    if [[ $time_left -lt 0 ]]; then
        log_error "Token has EXPIRED (${time_left}s ago)!"
        log_to_file "Token expired (${time_left}s ago)"
        refresh_token_with_retry
        return $?
    fi

    if [[ $time_left -lt $REFRESH_THRESHOLD ]]; then
        log_warn "Token expires in ${time_left}s (threshold: ${REFRESH_THRESHOLD}s) - refreshing..."
        log_to_file "Token expires in ${time_left}s - refreshing"
        refresh_token_with_retry
        return $?
    fi

    log_info "Token is valid for ${time_left}s (threshold: ${REFRESH_THRESHOLD}s) - no refresh needed"
    log_to_file "Token valid for ${time_left}s"
    return 0
}

#######################################
# Run daemon mode (continuous monitoring)
#######################################
run_daemon() {
    log_info "Starting token refresh daemon..."
    log_info "Organization: $RUNNER_ORG"
    log_info "Runner: $RUNNER_NAME"
    log_info "Check interval: ${CHECK_INTERVAL}s"
    log_info "Refresh threshold: ${REFRESH_THRESHOLD}s"
    log_to_file "Daemon started (org: $RUNNER_ORG, runner: $RUNNER_NAME)"

    while true; do
        check_and_refresh_once || log_warn "Check failed, will retry in ${CHECK_INTERVAL}s"

        log_debug "Sleeping for ${CHECK_INTERVAL}s..."
        sleep "$CHECK_INTERVAL"
    done
}

#######################################
# Main function
#######################################
main() {
    parse_args "$@"

    log_info "GitHub Actions Runner Token Refresh Service"
    log_info "==========================================="

    # Load existing metrics
    load_metrics

    # Verify prerequisites
    if ! check_gh_cli; then
        exit 1
    fi

    # Verify runner directory exists
    if [[ ! -d "$RUNNER_DIR" ]]; then
        log_error "Runner directory not found: $RUNNER_DIR"
        exit 1
    fi

    # Run in appropriate mode
    if [[ "$DAEMON_MODE" == true ]]; then
        run_daemon
    else
        check_and_refresh_once
        exit $?
    fi
}

# Run main function
main "$@"
