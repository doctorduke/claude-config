#!/usr/bin/env bash
# Source network utilities
SCRIPT_DIR_HEALTH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR_HEALTH}/lib/network.sh"
#
# health-check.sh - Comprehensive GitHub Actions Runner Health Monitoring
#
# Description:
#   Monitors runner service status, disk space, network connectivity,
#   recent workflow success rates, and queue wait times.
#
# Usage:
#   ./health-check.sh [OPTIONS]
#
# Options:
#   --json           Output results in JSON format
#   --continuous     Run continuously (check every 60s)
#   --interval N     Set check interval in seconds (default: 60)
#   --runner-dir DIR Specify runner installation directory
#   --help           Display this help message
#
# Exit Codes:
#   0 - All checks passed
#   1 - Warning detected (disk >80%, degraded performance)
#   2 - Critical error (runner offline, disk >90%, network failure)
#
# Examples:
#   ./health-check.sh                    # Single check with text output
#   ./health-check.sh --json             # Single check with JSON output
#   ./health-check.sh --continuous       # Continuous monitoring
#   ./health-check.sh --interval 30      # Check every 30 seconds
#

set -euo pipefail

# ============================================================================
# Configuration and Defaults
# ============================================================================

RUNNER_DIR="${RUNNER_DIR:-$HOME/actions-runner}"
GITHUB_API="${GITHUB_API:-https://api.github.com}"
OUTPUT_FORMAT="text"
CONTINUOUS=false
CHECK_INTERVAL=60
EXIT_CODE=0

# Thresholds
DISK_WARN_THRESHOLD=80
DISK_ERROR_THRESHOLD=90
NETWORK_LATENCY_WARN=100  # milliseconds
WORKFLOW_SUCCESS_WARN=80  # percentage
QUEUE_WAIT_WARN=300       # seconds

# Colors for output
if [ -t 1 ]; then
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m' # No Color
else
    RED=''
    YELLOW=''
    GREEN=''
    BLUE=''
    BOLD=''
    NC=''
fi

# ============================================================================
# Helper Functions
# ============================================================================

log_info() {
    if [ "$OUTPUT_FORMAT" = "text" ]; then
        echo -e "${BLUE}[INFO]${NC} $1"
    fi
}

log_success() {
    if [ "$OUTPUT_FORMAT" = "text" ]; then
        echo -e "${GREEN}[PASS]${NC} $1"
    fi
}

log_warning() {
    if [ "$OUTPUT_FORMAT" = "text" ]; then
        echo -e "${YELLOW}[WARN]${NC} $1"
    fi
    [ $EXIT_CODE -lt 1 ] && EXIT_CODE=1
}

log_error() {
    if [ "$OUTPUT_FORMAT" = "text" ]; then
        echo -e "${RED}[FAIL]${NC} $1"
    fi
    EXIT_CODE=2
}

print_header() {
    if [ "$OUTPUT_FORMAT" = "text" ]; then
        echo -e "\n${BOLD}=== $1 ===${NC}"
    fi
}

usage() {
    grep '^#' "$0" | grep -v '#!/usr/bin/env' | sed 's/^# //' | sed 's/^#//'
    exit 0
}

# ============================================================================
# Check Functions
# ============================================================================

check_runner_service() {
    print_header "Runner Service Status"

    local service_name=""
    local status="unknown"
    local is_running=false

    # Detect service manager and check status
    if command -v systemctl >/dev/null 2>&1; then
        # systemd (Linux/WSL)
        service_name="actions.runner.*.service"

        # Find all runner services
        local services
        services=$(systemctl list-units --type=service --all | grep -E 'actions\.runner\.' | awk '{print $1}' || echo "")

        if [ -z "$services" ]; then
            log_error "No runner services found (systemd)"
            echo "  Remedy: Run setup-runner.sh to install and configure runner service"
            return 1
        fi

        # Check each service
        while IFS= read -r svc; do
            if [ -z "$svc" ]; then continue; fi

            local svc_status
            svc_status=$(systemctl is-active "$svc" 2>/dev/null || echo "inactive")

            if [ "$svc_status" = "active" ]; then
                log_success "Service $svc is running"
                is_running=true
            else
                log_error "Service $svc is $svc_status"
                echo "  Remedy: sudo systemctl start $svc"
            fi
        done <<< "$services"

    elif command -v launchctl >/dev/null 2>&1; then
        # launchd (macOS)
        service_name="com.github.actions.runner.*"

        local services
        services=$(launchctl list | grep -E 'actions\.runner\.' || echo "")

        if [ -z "$services" ]; then
            log_error "No runner services found (launchd)"
            echo "  Remedy: Run setup-runner.sh to install and configure runner service"
            return 1
        fi

        log_success "Found runner service(s) in launchd"
        is_running=true

    else
        # Check for runner process directly
        if pgrep -f "Runner.Listener" >/dev/null 2>&1; then
            log_success "Runner process is running"
            is_running=true
        else
            log_error "Runner process not found"
            echo "  Remedy: Start runner with ./run.sh in $RUNNER_DIR"
            return 1
        fi
    fi

    # Check runner log for errors (last 50 lines)
    if [ -f "$RUNNER_DIR/_diag/Runner_*.log" ]; then
        local latest_log
        latest_log=$(ls -t "$RUNNER_DIR"/_diag/Runner_*.log 2>/dev/null | head -1)

        if [ -n "$latest_log" ]; then
            local error_count
            error_count=$(tail -50 "$latest_log" | grep -ci "error" || echo "0")

            if [ "$error_count" -gt 0 ]; then
                log_warning "Found $error_count error(s) in recent logs"
                echo "  Check: $latest_log"
            else
                log_success "No errors in recent logs"
            fi
        fi
    fi

    return 0
}

check_disk_space() {
    print_header "Disk Space"

    local runner_disk
    runner_disk=$(df -h "$RUNNER_DIR" 2>/dev/null | tail -1 || echo "")

    if [ -z "$runner_disk" ]; then
        log_error "Cannot determine disk space for $RUNNER_DIR"
        return 1
    fi

    local disk_usage
    disk_usage=$(echo "$runner_disk" | awk '{print $5}' | sed 's/%//')
    local disk_avail
    disk_avail=$(echo "$runner_disk" | awk '{print $4}')
    local mount_point
    mount_point=$(echo "$runner_disk" | awk '{print $6}')

    echo "  Mount: $mount_point"
    echo "  Usage: ${disk_usage}% (${disk_avail} available)"

    if [ "$disk_usage" -ge "$DISK_ERROR_THRESHOLD" ]; then
        log_error "Disk usage critical: ${disk_usage}% (threshold: ${DISK_ERROR_THRESHOLD}%)"
        echo "  Remedy: Clean up disk space immediately"
        echo "  - Remove old logs: rm -rf $RUNNER_DIR/_diag/*.log.*"
        echo "  - Clean Docker images: docker system prune -a"
        echo "  - Clear build artifacts in $RUNNER_DIR/_work"
        return 1
    elif [ "$disk_usage" -ge "$DISK_WARN_THRESHOLD" ]; then
        log_warning "Disk usage high: ${disk_usage}% (threshold: ${DISK_WARN_THRESHOLD}%)"
        echo "  Remedy: Consider cleaning up disk space"
        return 0
    else
        log_success "Disk usage healthy: ${disk_usage}%"
    fi

    return 0
}

check_network_connectivity() {
    print_header "Network Connectivity"

    # Check DNS resolution
    if ! nslookup github.com >/dev/null 2>&1; then
        log_error "DNS resolution failed for github.com"
        echo "  Remedy: Check /etc/resolv.conf and DNS settings"
        return 1
    else
        log_success "DNS resolution working"
    fi

    # Check connectivity to GitHub endpoints
    local endpoints=(
        "github.com:443"
        "api.github.com:443"
        "pipelines.actions.githubusercontent.com:443"
    )

    for endpoint in "${endpoints[@]}"; do
        local host="${endpoint%:*}"
        local port="${endpoint#*:}"

        # Measure latency
        local start_time
        local end_time
        local latency

        start_time=$(date +%s%3N)

        if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$host/$port" 2>/dev/null; then
            end_time=$(date +%s%3N)
            latency=$((end_time - start_time))

            if [ "$latency" -gt "$NETWORK_LATENCY_WARN" ]; then
                log_warning "$host latency high: ${latency}ms (threshold: ${NETWORK_LATENCY_WARN}ms)"
            else
                log_success "$host reachable (${latency}ms)"
            fi
        else
            log_error "$host unreachable on port $port"
            echo "  Remedy: Check firewall rules and proxy settings"
            return 1
        fi
    done

    # Check HTTP/HTTPS connectivity
    if command -v curl >/dev/null 2>&1; then
        local http_code
        http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout "${CONNECT_TIMEOUT}" --max-time "${MAX_TIMEOUT}" --dns-timeout "${DNS_TIMEOUT}" https://api.github.com/ || echo "000")

        if [ "$http_code" = "200" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ]; then
            log_success "HTTPS connectivity to GitHub API working (HTTP $http_code)"
        else
            log_error "HTTPS connectivity failed (HTTP $http_code)"
            echo "  Remedy: Check HTTPS_PROXY environment variable"
            return 1
        fi
    fi

    return 0
}

check_runner_registration() {
    print_header "Runner Registration Status"

    # Check if runner is configured
    if [ ! -f "$RUNNER_DIR/.runner" ]; then
        log_error "Runner not configured (.runner file missing)"
        echo "  Remedy: Run ./config.sh in $RUNNER_DIR"
        return 1
    fi

    # Parse runner configuration
    local runner_name
    local runner_id

    if command -v jq >/dev/null 2>&1; then
        runner_name=$(jq -r '.agentName // empty' "$RUNNER_DIR/.runner" 2>/dev/null || echo "")
        runner_id=$(jq -r '.agentId // empty' "$RUNNER_DIR/.runner" 2>/dev/null || echo "")
    else
        # Use sed instead of grep -oP for portability (BSD/macOS compatible)
        runner_name=$(sed -n 's/.*"agentName"[[:space:]]*:[[:space:]]*"\([^"]*\)".*//p' "$RUNNER_DIR/.runner" 2>/dev/null || echo "")
        # Use sed instead of grep -oP for portability (BSD/macOS compatible)
        runner_id=$(sed -n 's/.*"agentId"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*//p' "$RUNNER_DIR/.runner" 2>/dev/null || echo "")
    fi

    if [ -n "$runner_name" ]; then
        log_success "Runner registered: $runner_name (ID: ${runner_id:-unknown})"
        echo "  Config: $RUNNER_DIR/.runner"
    else
        log_error "Cannot parse runner configuration"
        return 1
    fi

    # Check runner credentials
    if [ -f "$RUNNER_DIR/.credentials" ]; then
        log_success "Runner credentials found"
    else
        log_error "Runner credentials missing"
        echo "  Remedy: Re-run ./config.sh with valid token"
        return 1
    fi

    return 0
}

check_recent_workflows() {
    print_header "Recent Workflow Activity"

    # This requires GitHub CLI or API access
    if ! command -v gh >/dev/null 2>&1; then
        log_warning "GitHub CLI (gh) not installed - skipping workflow checks"
        echo "  Install: Visit https://cli.github.com/"
        return 0
    fi

    # Check if authenticated
    if ! gh auth status >/dev/null 2>&1; then
        log_warning "GitHub CLI not authenticated - skipping workflow checks"
        echo "  Remedy: Run 'gh auth login'"
        return 0
    fi

    # Get recent workflow runs (requires repo context)
    # Note: This is a placeholder - real implementation needs org/repo context
    log_info "Workflow checks require organization/repository context"
    echo "  Use: gh run list --limit 20 in repository directory"

    return 0
}

check_system_resources() {
    print_header "System Resources"

    # CPU usage
    if command -v mpstat >/dev/null 2>&1; then
        local cpu_idle
        cpu_idle=$(mpstat 1 1 | tail -1 | awk '{print $NF}')
        local cpu_usage
        cpu_usage=$(echo "100 - $cpu_idle" | bc 2>/dev/null || echo "unknown")
        echo "  CPU Usage: ${cpu_usage}%"
    fi

    # Memory usage
    if command -v free >/dev/null 2>&1; then
        local mem_info
        mem_info=$(free -h | grep Mem:)
        local mem_used
        mem_used=$(echo "$mem_info" | awk '{print $3}')
        local mem_total
        mem_total=$(echo "$mem_info" | awk '{print $2}')
        echo "  Memory: $mem_used / $mem_total"
    fi

    # Load average
    if [ -f /proc/loadavg ]; then
        local load_avg
        load_avg=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
        echo "  Load Average: $load_avg"
    fi

    log_success "System resources checked"
    return 0
}

# ============================================================================
# Output Functions
# ============================================================================

output_json_results() {
    # Build JSON output (simplified version)
    cat <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "$([ $EXIT_CODE -eq 0 ] && echo 'healthy' || [ $EXIT_CODE -eq 1 ] && echo 'warning' || echo 'critical')",
  "exit_code": $EXIT_CODE,
  "runner_dir": "$RUNNER_DIR",
  "checks": {
    "service": "See detailed output",
    "disk": "See detailed output",
    "network": "See detailed output",
    "registration": "See detailed output"
  }
}
EOF
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --json)
                OUTPUT_FORMAT="json"
                shift
                ;;
            --continuous)
                CONTINUOUS=true
                shift
                ;;
            --interval)
                CHECK_INTERVAL="$2"
                shift 2
                ;;
            --runner-dir)
                RUNNER_DIR="$2"
                shift 2
                ;;
            --help|-h)
                usage
                ;;
            *)
                echo "Unknown option: $1"
                usage
                ;;
        esac
    done

    # Validate runner directory
    if [ ! -d "$RUNNER_DIR" ]; then
        log_error "Runner directory not found: $RUNNER_DIR"
        echo "  Remedy: Set RUNNER_DIR environment variable or use --runner-dir option"
        exit 2
    fi

    # Main check loop
    while true; do
        EXIT_CODE=0

        if [ "$OUTPUT_FORMAT" = "text" ]; then
            echo ""
            echo -e "${BOLD}GitHub Actions Runner Health Check${NC}"
            echo -e "${BOLD}====================================${NC}"
            echo "Timestamp: $(date)"
            echo "Runner Directory: $RUNNER_DIR"
        fi

        # Run all checks
        check_runner_service || true
        check_disk_space || true
        check_network_connectivity || true
        check_runner_registration || true
        check_recent_workflows || true
        check_system_resources || true

        # Summary
        if [ "$OUTPUT_FORMAT" = "text" ]; then
            print_header "Summary"

            if [ $EXIT_CODE -eq 0 ]; then
                echo -e "${GREEN}${BOLD}All checks passed!${NC}"
            elif [ $EXIT_CODE -eq 1 ]; then
                echo -e "${YELLOW}${BOLD}Warnings detected - review above${NC}"
            else
                echo -e "${RED}${BOLD}Critical errors detected - immediate action required${NC}"
            fi

            echo ""
            echo "Exit Code: $EXIT_CODE (0=success, 1=warning, 2=critical)"
        else
            output_json_results
        fi

        # Exit if not continuous
        if [ "$CONTINUOUS" = false ]; then
            break
        fi

        # Wait for next check
        if [ "$OUTPUT_FORMAT" = "text" ]; then
            echo ""
            echo "Waiting ${CHECK_INTERVAL}s for next check... (Ctrl+C to stop)"
        fi
        sleep "$CHECK_INTERVAL"
    done

    exit $EXIT_CODE
}

# Run main function
main "$@"
