#!/usr/bin/env bash
# Source network utilities
SCRIPT_DIR_VALIDATE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR_VALIDATE}/lib/network.sh"

################################################################################
# GitHub Actions Runner Validation Script
# Version: 1.0.0
# Platform: WSL 2.0 / Linux / macOS
#
# Description: Comprehensive validation and health check for GitHub Actions
#              self-hosted runners. Validates installation, configuration,
#              connectivity, and operational status.
#
# Usage:
#   ./validate-setup.sh [options]
#
# Optional Arguments:
#   --runner-id <ID>      Validate specific runner ID (default: all)
#   --org <ORG>           GitHub organization name (for API checks)
#   --token <TOKEN>       GitHub PAT for API validation (optional)
#   --fix                 Attempt to fix common issues
#   --json                Output results in JSON format
#   --help                Show this help message
################################################################################

set -e
set -u
set -o pipefail

# Script constants
readonly SCRIPT_VERSION="1.0.0"
readonly VALIDATION_LOG="validation-$(date +%Y%m%d-%H%M%S).log"

# Color output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Validation results
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0

# Options
RUNNER_ID=""
GITHUB_ORG=""
GITHUB_TOKEN=""
FIX_MODE=false
JSON_OUTPUT=false

################################################################################
# Utility Functions
################################################################################

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*" | tee -a "$VALIDATION_LOG"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $*" | tee -a "$VALIDATION_LOG" >&2
    ((FAILED_CHECKS++))
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "$VALIDATION_LOG"
    ((WARNINGS++))
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $*" | tee -a "$VALIDATION_LOG"
    ((PASSED_CHECKS++))
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" | tee -a "$VALIDATION_LOG"
}

show_help() {
    cat << EOF
GitHub Actions Runner Validation Script v${SCRIPT_VERSION}

Usage: $0 [options]

Optional Arguments:
  --runner-id <ID>      Validate specific runner ID (default: all)
  --org <ORG>           GitHub organization name (for API checks)
  --token <TOKEN>       GitHub PAT for API validation (optional)
  --fix                 Attempt to fix common issues
  --json                Output results in JSON format
  --help                Show this help message

Examples:
  # Validate all runners
  $0

  # Validate specific runner
  $0 --runner-id 1

  # Validate with GitHub API checks
  $0 --org myorg --token ghp_xxxxxxxxxxxxx

  # Validate and attempt fixes
  $0 --runner-id 1 --fix

EOF
    exit 0
}

################################################################################
# System Checks
################################################################################

check_os_compatibility() {
    ((TOTAL_CHECKS++))
    log_info "Checking OS compatibility..."

    local os_type=""
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        os_type="Linux"
        if grep -qi microsoft /proc/version 2>/dev/null; then
            os_type="WSL"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        os_type="macOS"
    else
        log_error "Unsupported OS: $OSTYPE"
        return 1
    fi

    log_pass "OS: $os_type ($(uname -m))"
    return 0
}

check_required_commands() {
    ((TOTAL_CHECKS++))
    log_info "Checking required commands..."

    local required_cmds=("curl" "tar" "jq" "systemctl")
    local missing_cmds=()

    for cmd in "${required_cmds[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_cmds+=("$cmd")
        fi
    done

    if [[ ${#missing_cmds[@]} -gt 0 ]]; then
        log_error "Missing required commands: ${missing_cmds[*]}"
        log_info "Install with: sudo apt-get install ${missing_cmds[*]}"
        return 1
    fi

    log_pass "All required commands available"
    return 0
}

check_system_resources() {
    ((TOTAL_CHECKS++))
    log_info "Checking system resources..."

    # Check disk space
    local available_space
    available_space=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')

    if [[ "$available_space" -lt 10 ]]; then
        log_warn "Low disk space: ${available_space}GB available (recommended: 10GB+)"
    fi

    # Check memory
    local total_mem
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        total_mem=$(free -g | awk 'NR==2 {print $2}')
        if [[ "$total_mem" -lt 4 ]]; then
            log_warn "Low memory: ${total_mem}GB (recommended: 4GB+)"
        fi
    fi

    log_pass "System resources checked (Disk: ${available_space}GB)"
    return 0
}

################################################################################
# Network Checks
################################################################################

check_github_connectivity() {
    ((TOTAL_CHECKS++))
    log_info "Checking GitHub connectivity..."

    local endpoints=(
        "https://github.com"
        "https://api.github.com"
        "https://ghcr.io"
        "https://objects.githubusercontent.com"
    )

    local failed_endpoints=()

    for endpoint in "${endpoints[@]}"; do
        if ! curl -s --connect-timeout "${CONNECT_TIMEOUT}" --max-time "${MAX_TIMEOUT}" --dns-timeout "${DNS_TIMEOUT}" --head "$endpoint" > /dev/null 2>&1; then
            failed_endpoints+=("$endpoint")
        fi
    done

    if [[ ${#failed_endpoints[@]} -gt 0 ]]; then
        log_error "Cannot reach: ${failed_endpoints[*]}"
        log_info "Check firewall rules and proxy settings"
        return 1
    fi

    log_pass "All GitHub endpoints reachable"
    return 0
}

check_network_latency() {
    ((TOTAL_CHECKS++))
    log_info "Checking network latency to GitHub..."

    if ! command -v ping &> /dev/null; then
        log_warn "ping command not available, skipping latency check"
        return 0
    fi

    local latency
    latency=$(ping -c 3 github.com 2>/dev/null | tail -1 | awk '{print $4}' | cut -d '/' -f 2)

    if [[ -z "$latency" ]]; then
        log_warn "Could not measure latency to github.com"
        return 0
    fi

    local latency_int="${latency%.*}"
    if [[ "$latency_int" -gt 100 ]]; then
        log_warn "High latency to github.com: ${latency}ms (recommended: <100ms)"
    else
        log_pass "Latency to github.com: ${latency}ms"
    fi

    return 0
}

check_dns_resolution() {
    ((TOTAL_CHECKS++))
    log_info "Checking DNS resolution..."

    local test_domains=("github.com" "api.github.com")
    local failed_dns=()

    for domain in "${test_domains[@]}"; do
        if ! nslookup "$domain" > /dev/null 2>&1 && ! host "$domain" > /dev/null 2>&1; then
            failed_dns+=("$domain")
        fi
    done

    if [[ ${#failed_dns[@]} -gt 0 ]]; then
        log_error "DNS resolution failed for: ${failed_dns[*]}"
        return 1
    fi

    log_pass "DNS resolution working"
    return 0
}

################################################################################
# Runner Installation Checks
################################################################################

find_runner_directories() {
    local runner_id="$1"

    if [[ -n "$runner_id" ]]; then
        echo "${HOME}/actions-runner-${runner_id}"
    else
        # Find all runner directories
        find "$HOME" -maxdepth 1 -type d -name "actions-runner-*" 2>/dev/null | sort
    fi
}

check_runner_installation() {
    local runner_dir="$1"

    ((TOTAL_CHECKS++))
    log_info "Checking runner installation: $runner_dir"

    if [[ ! -d "$runner_dir" ]]; then
        log_error "Runner directory not found: $runner_dir"
        return 1
    fi

    # Check for required files
    local required_files=("run.sh" "config.sh" ".runner" ".credentials")
    local missing_files=()

    for file in "${required_files[@]}"; do
        if [[ ! -f "$runner_dir/$file" ]]; then
            missing_files+=("$file")
        fi
    done

    if [[ ${#missing_files[@]} -gt 0 ]]; then
        log_error "Missing required files in $runner_dir: ${missing_files[*]}"
        return 1
    fi

    # Check executable permissions
    if [[ ! -x "$runner_dir/run.sh" ]]; then
        log_error "run.sh is not executable in $runner_dir"
        if [[ "$FIX_MODE" == "true" ]]; then
            log_info "Fixing permissions..."
            chmod +x "$runner_dir/run.sh"
            log_pass "Permissions fixed"
        fi
        return 1
    fi

    log_pass "Runner installation valid: $runner_dir"
    return 0
}

check_runner_configuration() {
    local runner_dir="$1"

    ((TOTAL_CHECKS++))
    log_info "Checking runner configuration: $runner_dir"

    if [[ ! -f "$runner_dir/.runner" ]]; then
        log_error "Runner configuration file missing: $runner_dir/.runner"
        return 1
    fi

    # Parse runner configuration
    local runner_name
    runner_name=$(jq -r '.agentName // empty' "$runner_dir/.runner" 2>/dev/null)

    if [[ -z "$runner_name" ]]; then
        log_error "Cannot read runner name from configuration"
        return 1
    fi

    log_pass "Runner configured: $runner_name"
    log_info "Runner config: $(cat "$runner_dir/.runner" | jq -c '.')"
    return 0
}

check_runner_credentials() {
    local runner_dir="$1"

    ((TOTAL_CHECKS++))
    log_info "Checking runner credentials: $runner_dir"

    if [[ ! -f "$runner_dir/.credentials" ]]; then
        log_error "Runner credentials missing: $runner_dir/.credentials"
        return 1
    fi

    # Verify credentials file is readable
    if [[ ! -r "$runner_dir/.credentials" ]]; then
        log_error "Cannot read credentials file: $runner_dir/.credentials"
        return 1
    fi

    log_pass "Runner credentials present"
    return 0
}

check_work_directory() {
    local runner_dir="$1"

    ((TOTAL_CHECKS++))
    log_info "Checking work directory: $runner_dir"

    local work_dir="${runner_dir}/_work"

    if [[ ! -d "$work_dir" ]]; then
        log_warn "Work directory not found: $work_dir (will be created on first job)"
    else
        log_pass "Work directory exists: $work_dir"
    fi

    return 0
}

################################################################################
# Service Checks
################################################################################

check_runner_service() {
    local runner_dir="$1"

    ((TOTAL_CHECKS++))
    log_info "Checking runner service: $runner_dir"

    if [[ ! -f "$runner_dir/svc.sh" ]]; then
        log_warn "Service script not found (runner may not be installed as service)"
        return 0
    fi

    # Get runner name for service
    local runner_name
    runner_name=$(jq -r '.agentName // empty' "$runner_dir/.runner" 2>/dev/null)

    if [[ -z "$runner_name" ]]; then
        log_error "Cannot determine runner name for service check"
        return 1
    fi

    # Check service status
    cd "$runner_dir" || return 1

    if sudo ./svc.sh status &> /dev/null; then
        log_pass "Runner service is active: $runner_name"
    else
        log_error "Runner service is not running: $runner_name"
        if [[ "$FIX_MODE" == "true" ]]; then
            log_info "Attempting to start service..."
            if sudo ./svc.sh start; then
                log_pass "Service started successfully"
            else
                log_error "Failed to start service"
                return 1
            fi
        fi
        return 1
    fi

    return 0
}

check_systemd_unit() {
    local runner_dir="$1"

    ((TOTAL_CHECKS++))
    log_info "Checking systemd unit status: $runner_dir"

    local runner_name
    runner_name=$(jq -r '.agentName // empty' "$runner_dir/.runner" 2>/dev/null)

    if [[ -z "$GITHUB_ORG" ]]; then
        log_warn "GitHub org not provided, skipping systemd unit check"
        return 0
    fi

    local service_name="actions.runner.${GITHUB_ORG}.${runner_name}.service"

    if ! systemctl --user list-unit-files "$service_name" &> /dev/null; then
        log_warn "Systemd unit not found: $service_name"
        return 0
    fi

    if systemctl --user is-active "$service_name" &> /dev/null; then
        log_pass "Systemd unit active: $service_name"
    else
        log_error "Systemd unit inactive: $service_name"
        return 1
    fi

    return 0
}

################################################################################
# GitHub API Checks
################################################################################

check_runner_registration() {
    local runner_dir="$1"

    if [[ -z "$GITHUB_ORG" ]] || [[ -z "$GITHUB_TOKEN" ]]; then
        log_warn "GitHub org/token not provided, skipping API registration check"
        return 0
    fi

    ((TOTAL_CHECKS++))
    log_info "Checking runner registration via GitHub API: $runner_dir"

    local runner_name
    runner_name=$(jq -r '.agentName // empty' "$runner_dir/.runner" 2>/dev/null)

    if [[ -z "$runner_name" ]]; then
        log_error "Cannot determine runner name for API check"
        return 1
    fi

    # Query GitHub API for runners
    local api_url="https://api.github.com/orgs/${GITHUB_ORG}/actions/runners"
    local response
    response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
                         -H "Accept: application/vnd.github.v3+json" \
                         "$api_url")

    if [[ -z "$response" ]]; then
        log_error "Failed to query GitHub API"
        return 1
    fi

    # Check if runner is registered
    local runner_status
    runner_status=$(echo "$response" | jq -r --arg name "$runner_name" \
        '.runners[] | select(.name == $name) | .status')

    if [[ -z "$runner_status" ]]; then
        log_error "Runner not found in GitHub: $runner_name"
        return 1
    fi

    if [[ "$runner_status" == "online" ]]; then
        log_pass "Runner registered and online in GitHub: $runner_name"
    else
        log_warn "Runner registered but status is: $runner_status"
    fi

    return 0
}

################################################################################
# Label Checks
################################################################################

check_runner_labels() {
    local runner_dir="$1"

    ((TOTAL_CHECKS++))
    log_info "Checking runner labels: $runner_dir"

    if [[ ! -f "$runner_dir/.runner" ]]; then
        log_error "Cannot check labels: .runner file missing"
        return 1
    fi

    local labels
    labels=$(jq -r '.labels // [] | join(",")' "$runner_dir/.runner" 2>/dev/null)

    if [[ -z "$labels" ]]; then
        log_warn "No labels configured for runner"
    else
        log_pass "Runner labels: $labels"
    fi

    return 0
}

################################################################################
# Security Checks
################################################################################

check_file_permissions() {
    local runner_dir="$1"

    ((TOTAL_CHECKS++))
    log_info "Checking file permissions: $runner_dir"

    # Check credentials file permissions (should not be world-readable)
    if [[ -f "$runner_dir/.credentials" ]]; then
        local perms
        perms=$(stat -c "%a" "$runner_dir/.credentials" 2>/dev/null || stat -f "%OLp" "$runner_dir/.credentials" 2>/dev/null)

        if [[ "$perms" =~ [0-9][0-9][4567] ]]; then
            log_error "Credentials file is world-readable: $runner_dir/.credentials"
            if [[ "$FIX_MODE" == "true" ]]; then
                log_info "Fixing permissions..."
                chmod 600 "$runner_dir/.credentials"
                log_pass "Permissions fixed"
            fi
            return 1
        fi
    fi

    log_pass "File permissions are secure"
    return 0
}

################################################################################
# Summary and Reporting
################################################################################

print_summary() {
    echo ""
    log "==================================================================="
    log "Validation Summary"
    log "==================================================================="
    log_info "Total Checks: $TOTAL_CHECKS"
    log_info "Passed: ${GREEN}$PASSED_CHECKS${NC}"
    log_info "Failed: ${RED}$FAILED_CHECKS${NC}"
    log_info "Warnings: ${YELLOW}$WARNINGS${NC}"
    echo ""

    if [[ $FAILED_CHECKS -eq 0 ]]; then
        log "${GREEN}All critical checks passed!${NC}"
        return 0
    else
        log "${RED}Some checks failed. Review the log for details.${NC}"
        log_info "Log file: $VALIDATION_LOG"
        return 1
    fi
}

generate_json_report() {
    cat << EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "total_checks": $TOTAL_CHECKS,
  "passed": $PASSED_CHECKS,
  "failed": $FAILED_CHECKS,
  "warnings": $WARNINGS,
  "status": $([ $FAILED_CHECKS -eq 0 ] && echo '"PASS"' || echo '"FAIL"')
}
EOF
}

################################################################################
# Main Validation Flow
################################################################################

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --runner-id)
                RUNNER_ID="$2"
                shift 2
                ;;
            --org)
                GITHUB_ORG="$2"
                shift 2
                ;;
            --token)
                GITHUB_TOKEN="$2"
                shift 2
                ;;
            --fix)
                FIX_MODE=true
                shift
                ;;
            --json)
                JSON_OUTPUT=true
                shift
                ;;
            --help)
                show_help
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                ;;
        esac
    done
}

main() {
    log "==================================================================="
    log "GitHub Actions Runner Validation v${SCRIPT_VERSION}"
    log "==================================================================="

    parse_arguments "$@"

    # System-level checks
    check_os_compatibility
    check_required_commands
    check_system_resources

    # Network checks
    check_github_connectivity
    check_network_latency
    check_dns_resolution

    # Find and validate runner installations
    local runner_dirs
    mapfile -t runner_dirs < <(find_runner_directories "$RUNNER_ID")

    if [[ ${#runner_dirs[@]} -eq 0 ]]; then
        log_error "No runner directories found"
        exit 1
    fi

    log_info "Found ${#runner_dirs[@]} runner(s)"

    # Validate each runner
    for runner_dir in "${runner_dirs[@]}"; do
        echo ""
        log "Validating: $runner_dir"
        log "-------------------------------------------------------------------"

        check_runner_installation "$runner_dir"
        check_runner_configuration "$runner_dir"
        check_runner_credentials "$runner_dir"
        check_work_directory "$runner_dir"
        check_runner_service "$runner_dir"
        check_runner_labels "$runner_dir"
        check_file_permissions "$runner_dir"
        check_runner_registration "$runner_dir"
    done

    # Print summary
    if [[ "$JSON_OUTPUT" == "true" ]]; then
        generate_json_report
    else
        print_summary
    fi

    # Exit with appropriate code
    if [[ $FAILED_CHECKS -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
