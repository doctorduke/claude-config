#!/bin/bash
# rotate-tokens.sh - Automated PAT and token rotation script
# Security Auditor - Wave 2 Infrastructure Provisioning
# Implements zero-downtime token rotation with audit logging

set -euo pipefail
IFS=$'\n\t'

# Script metadata
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly LOG_FILE="${SCRIPT_DIR}/../logs/token-rotation-$(date +%Y%m%d-%H%M%S).log"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Rotation configuration
readonly DEFAULT_ROTATION_DAYS=90
readonly WARNING_DAYS=7
readonly CRITICAL_DAYS=3
readonly STATE_FILE="${SCRIPT_DIR}/../.state/token-rotation-state.json"
readonly AUDIT_LOG="${SCRIPT_DIR}/../audit/token-rotation-audit.log"

# Initialize logging
init_logging() {
    local log_dir
    log_dir="$(dirname "$LOG_FILE")"
    mkdir -p "$log_dir" "$(dirname "$STATE_FILE")" "$(dirname "$AUDIT_LOG")"

    exec 1> >(tee -a "$LOG_FILE")
    exec 2>&1

    echo "=========================================="
    echo "Token Rotation Script v${SCRIPT_VERSION}"
    echo "Started: $(date -Iseconds)"
    echo "User: $(whoami)"
    echo "Host: $(hostname)"
    echo "=========================================="
}

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_audit() {
    local message="$1"
    local severity="${2:-INFO}"
    echo "[$(date -Iseconds)] [${severity}] ${message}" >> "$AUDIT_LOG"
}

# Load rotation state
load_state() {
    if [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    else
        echo '{}'
    fi
}

# Save rotation state
save_state() {
    local state="$1"
    echo "$state" | jq '.' > "$STATE_FILE"
    chmod 600 "$STATE_FILE"
}

# Check token age
check_token_age() {
    local token_name="$1"
    local last_rotation="${2:-}"

    if [[ -z "$last_rotation" ]]; then
        log_warning "No rotation history for ${token_name}"
        return 2  # Unknown state
    fi

    local last_rotation_epoch
    last_rotation_epoch=$(date -d "$last_rotation" +%s 2>/dev/null || echo 0)

    local current_epoch
    current_epoch=$(date +%s)

    local days_since_rotation
    days_since_rotation=$(( (current_epoch - last_rotation_epoch) / 86400 ))

    log_info "Token '${token_name}' last rotated: ${days_since_rotation} days ago"

    if [[ $days_since_rotation -ge $DEFAULT_ROTATION_DAYS ]]; then
        log_error "Token '${token_name}' has expired (${days_since_rotation} days old)"
        return 3  # Expired
    elif [[ $days_since_rotation -ge $((DEFAULT_ROTATION_DAYS - CRITICAL_DAYS)) ]]; then
        log_error "Token '${token_name}' expires in less than ${CRITICAL_DAYS} days!"
        return 2  # Critical
    elif [[ $days_since_rotation -ge $((DEFAULT_ROTATION_DAYS - WARNING_DAYS)) ]]; then
        log_warning "Token '${token_name}' expires in less than ${WARNING_DAYS} days"
        return 1  # Warning
    else
        log_success "Token '${token_name}' is valid (${days_since_rotation} days old)"
        return 0  # Valid
    fi
}

# Get GitHub PAT expiration
get_pat_expiration() {
    local pat="$1"

    local response
    response=$(curl -s -H "Authorization: token ${pat}" \
                    -H "Accept: application/vnd.github.v3+json" \
                    "https://api.github.com/user")

    if [[ $? -ne 0 ]]; then
        log_error "Failed to check PAT status"
        return 1
    fi

    # Check rate limit headers for token info
    local rate_response
    rate_response=$(curl -s -I -H "Authorization: token ${pat}" \
                          -H "Accept: application/vnd.github.v3+json" \
                          "https://api.github.com/rate_limit")

    # Extract expiration from headers (if available)
    local expires_at
    expires_at=$(echo "$rate_response" | grep -i "github-authentication-token-expiration:" | cut -d: -f2- | tr -d ' \r')

    if [[ -n "$expires_at" ]]; then
        log_info "PAT expires at: ${expires_at}"
        echo "$expires_at"
        return 0
    else
        log_info "PAT has no expiration (classic token without expiry)"
        echo "never"
        return 0
    fi
}

# Create new PAT via GitHub API (requires existing PAT with admin:org scope)
create_new_pat() {
    local description="$1"
    local scopes="$2"
    local expiry_days="${3:-90}"

    log_info "Creating new PAT: ${description}"

    # Calculate expiry date
    local expiry_date
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS date command
        expiry_date=$(date -v +${expiry_days}d -u +"%Y-%m-%dT%H:%M:%SZ")
    else
        # Linux date command
        expiry_date=$(date -u -d "+${expiry_days} days" +"%Y-%m-%dT%H:%M:%SZ")
    fi

    # Note: GitHub API doesn't support creating PATs directly
    # This would need to be done via GitHub App or OAuth flow
    # For now, we'll provide instructions for manual rotation

    log_warning "Automated PAT creation requires GitHub App authentication"
    log_info "Please create a new PAT manually with the following settings:"
    echo ""
    echo "  Description: ${description}"
    echo "  Expiration: ${expiry_days} days (${expiry_date})"
    echo "  Scopes: ${scopes}"
    echo ""
    echo "  URL: https://github.com/settings/tokens/new"
    echo ""

    return 1
}

# Rotate BOT_PAT
rotate_bot_pat() {
    log_info "Starting BOT_PAT rotation..."

    local state
    state=$(load_state)

    local last_rotation
    last_rotation=$(echo "$state" | jq -r '.bot_pat.last_rotation // ""')

    # Check if rotation is needed
    local rotation_status
    check_token_age "BOT_PAT" "$last_rotation"
    rotation_status=$?

    if [[ $rotation_status -eq 0 ]]; then
        log_info "BOT_PAT rotation not needed yet"
        return 0
    fi

    log_warning "BOT_PAT rotation required (status: ${rotation_status})"

    # Check if we have the current PAT
    if [[ -z "${BOT_PAT:-}" ]]; then
        log_error "Current BOT_PAT not available in environment"
        log_info "Please set BOT_PAT environment variable with current token"
        return 1
    fi

    # Get current PAT expiration
    local current_expiry
    current_expiry=$(get_pat_expiration "$BOT_PAT")

    log_info "Current BOT_PAT expiry: ${current_expiry}"

    # Provide rotation instructions
    echo ""
    echo "=========================================="
    echo "BOT_PAT ROTATION REQUIRED"
    echo "=========================================="
    echo "1. Create new PAT at: https://github.com/settings/tokens/new"
    echo "   - Name: bot-pat-$(date +%Y%m%d)"
    echo "   - Expiration: 90 days"
    echo "   - Scopes: repo, workflow"
    echo ""
    echo "2. Update organization secret:"
    echo "   export NEW_BOT_PAT='<new-pat-value>'"
    echo "   ./setup-secrets.sh"
    echo ""
    echo "3. Test new PAT:"
    echo "   curl -H \"Authorization: token \$NEW_BOT_PAT\" https://api.github.com/user"
    echo ""
    echo "4. Update rotation state:"
    echo "   Run: $0 --mark-rotated BOT_PAT"
    echo "=========================================="

    log_audit "BOT_PAT rotation initiated" "WARNING"

    return 1
}

# Rotate runner registration tokens
rotate_runner_tokens() {
    log_info "Rotating runner registration tokens..."

    if [[ -z "${GITHUB_ORG:-}" ]] || [[ -z "${GITHUB_PAT:-}" ]]; then
        log_error "GITHUB_ORG and GITHUB_PAT required for runner token rotation"
        return 1
    fi

    # Get current runners
    local runners_response
    runners_response=$(curl -s -H "Authorization: token ${GITHUB_PAT}" \
                             -H "Accept: application/vnd.github.v3+json" \
                             "https://api.github.com/orgs/${GITHUB_ORG}/actions/runners")

    local runner_count
    runner_count=$(echo "$runners_response" | jq -r '.total_count // 0')

    log_info "Found ${runner_count} runners in organization"

    # Generate new registration token
    local token_response
    token_response=$(curl -s -X POST \
                           -H "Authorization: token ${GITHUB_PAT}" \
                           -H "Accept: application/vnd.github.v3+json" \
                           "https://api.github.com/orgs/${GITHUB_ORG}/actions/runners/registration-token")

    local new_token
    new_token=$(echo "$token_response" | jq -r '.token')

    if [[ -z "$new_token" ]] || [[ "$new_token" == "null" ]]; then
        log_error "Failed to generate new runner registration token"
        return 1
    fi

    # Save new token
    local token_file="${SCRIPT_DIR}/../.secrets/runner-registration-token"
    mkdir -p "$(dirname "$token_file")"
    echo "$new_token" > "$token_file"
    chmod 600 "$token_file"

    log_success "New runner registration token generated"
    log_info "Token expires in 1 hour"
    log_audit "Runner registration token rotated"

    # Update state
    local state
    state=$(load_state)
    state=$(echo "$state" | jq --arg date "$(date -Iseconds)" '.runner_token.last_rotation = $date')
    save_state "$state"

    return 0
}

# Mark token as rotated
mark_token_rotated() {
    local token_name="$1"

    log_info "Marking ${token_name} as rotated..."

    local state
    state=$(load_state)

    # Update rotation timestamp
    local current_time
    current_time=$(date -Iseconds)

    state=$(echo "$state" | jq --arg token "$token_name" --arg time "$current_time" \
            '.[$token | ascii_downcase | gsub("_"; "_")].last_rotation = $time')

    save_state "$state"

    log_success "Token '${token_name}' marked as rotated at ${current_time}"
    log_audit "Token marked as rotated: ${token_name}"

    return 0
}

# Check all tokens
check_all_tokens() {
    log_info "Checking all token rotation status..."

    local state
    state=$(load_state)

    local tokens=("BOT_PAT" "RUNNER_TOKEN")
    local overall_status=0

    echo ""
    echo "Token Rotation Status Report"
    echo "============================="

    for token in "${tokens[@]}"; do
        local last_rotation
        last_rotation=$(echo "$state" | jq -r --arg t "${token,,}" '.[$t].last_rotation // ""')

        if [[ -z "$last_rotation" ]]; then
            echo "  ${token}: No rotation history (UNKNOWN)"
            overall_status=1
        else
            local days_since
            if [[ "$OSTYPE" == "darwin"* ]]; then
                # macOS date command
                days_since=$(( ($(date +%s) - $(date -j -f "%Y-%m-%dT%H:%M:%S" "${last_rotation%%.*}" +%s 2>/dev/null || echo 0)) / 86400 ))
            else
                # Linux date command
                days_since=$(( ($(date +%s) - $(date -d "$last_rotation" +%s 2>/dev/null || echo 0)) / 86400 ))
            fi

            local status="VALID"
            if [[ $days_since -ge $DEFAULT_ROTATION_DAYS ]]; then
                status="EXPIRED"
                overall_status=2
            elif [[ $days_since -ge $((DEFAULT_ROTATION_DAYS - CRITICAL_DAYS)) ]]; then
                status="CRITICAL"
                overall_status=$((overall_status < 2 ? 2 : overall_status))
            elif [[ $days_since -ge $((DEFAULT_ROTATION_DAYS - WARNING_DAYS)) ]]; then
                status="WARNING"
                overall_status=$((overall_status < 1 ? 1 : overall_status))
            fi

            echo "  ${token}: ${status} (${days_since} days old, rotated: ${last_rotation})"
        fi
    done

    echo "============================="

    # Provide recommendation
    if [[ $overall_status -eq 0 ]]; then
        echo "Status: All tokens are valid"
    elif [[ $overall_status -eq 1 ]]; then
        echo "Status: Some tokens need attention soon"
    else
        echo "Status: IMMEDIATE ACTION REQUIRED"
    fi

    return $overall_status
}

# Schedule rotation check (for cron)
schedule_rotation() {
    log_info "Setting up automated rotation schedule..."

    local cron_entry="0 0 * * * ${SCRIPT_DIR}/rotate-tokens.sh --check >> ${LOG_FILE} 2>&1"

    # Check if cron entry exists
    if crontab -l 2>/dev/null | grep -q "rotate-tokens.sh"; then
        log_info "Rotation schedule already configured"
    else
        # Add to crontab
        (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -
        log_success "Rotation schedule added to crontab"
        log_info "Tokens will be checked daily at midnight"
    fi

    # Create systemd timer for systems using systemd
    if command -v systemctl &> /dev/null; then
        create_systemd_timer
    fi

    log_audit "Automated rotation schedule configured"
    return 0
}

# Create systemd timer for token rotation
create_systemd_timer() {
    log_info "Creating systemd timer for token rotation..."

    local service_file="/etc/systemd/system/github-token-rotation.service"
    local timer_file="/etc/systemd/system/github-token-rotation.timer"

    # Create service unit
    cat << EOF | sudo tee "$service_file" > /dev/null
[Unit]
Description=GitHub Token Rotation Check
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=$(whoami)
WorkingDirectory=${SCRIPT_DIR}
ExecStart=${SCRIPT_DIR}/rotate-tokens.sh --check
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    # Create timer unit
    cat << EOF | sudo tee "$timer_file" > /dev/null
[Unit]
Description=Daily GitHub Token Rotation Check
Requires=github-token-rotation.service

[Timer]
OnCalendar=daily
OnBootSec=10min
Persistent=true

[Install]
WantedBy=timers.target
EOF

    # Enable and start timer
    sudo systemctl daemon-reload
    sudo systemctl enable github-token-rotation.timer
    sudo systemctl start github-token-rotation.timer

    log_success "Systemd timer created and enabled"
    return 0
}

# Generate rotation report
generate_rotation_report() {
    log_info "Generating token rotation report..."

    local report_file="${SCRIPT_DIR}/../reports/token-rotation-report-$(date +%Y%m%d-%H%M%S).json"
    mkdir -p "$(dirname "$report_file")"

    local state
    state=$(load_state)

    # Check all tokens and get status
    local token_status
    token_status=$(check_all_tokens 2>&1)

    # Build report
    local report
    report=$(jq -n \
        --arg timestamp "$(date -Iseconds)" \
        --arg version "${SCRIPT_VERSION}" \
        --arg rotation_days "${DEFAULT_ROTATION_DAYS}" \
        --arg warning_days "${WARNING_DAYS}" \
        --arg critical_days "${CRITICAL_DAYS}" \
        --argjson state "$state" \
        '{
            timestamp: $timestamp,
            script_version: $version,
            configuration: {
                rotation_period_days: $rotation_days,
                warning_threshold_days: $warning_days,
                critical_threshold_days: $critical_days
            },
            rotation_state: $state,
            recommendations: []
        }')

    echo "$report" | jq '.' > "$report_file"

    log_success "Rotation report generated: ${report_file}"
    log_audit "Token rotation report generated"

    return 0
}

# Display usage information
usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Token rotation and management script for GitHub Actions infrastructure.

OPTIONS:
    --check                 Check rotation status of all tokens
    --rotate-bot-pat        Rotate BOT_PAT token
    --rotate-runner-tokens  Rotate runner registration tokens
    --mark-rotated TOKEN    Mark TOKEN as recently rotated
    --schedule              Set up automated rotation schedule
    --report                Generate rotation status report
    --help                  Display this help message

EXAMPLES:
    # Check all token statuses
    $SCRIPT_NAME --check

    # Rotate BOT_PAT
    $SCRIPT_NAME --rotate-bot-pat

    # Mark BOT_PAT as rotated after manual rotation
    $SCRIPT_NAME --mark-rotated BOT_PAT

    # Set up automated daily checks
    $SCRIPT_NAME --schedule

ENVIRONMENT VARIABLES:
    GITHUB_ORG      GitHub organization name
    GITHUB_PAT      GitHub Personal Access Token
    BOT_PAT         Bot account PAT (for rotation)

EOF
}

# Main execution
main() {
    init_logging

    # Parse command line arguments
    if [[ $# -eq 0 ]]; then
        usage
        exit 0
    fi

    case "$1" in
        --check)
            check_all_tokens
            exit $?
            ;;
        --rotate-bot-pat)
            rotate_bot_pat
            exit $?
            ;;
        --rotate-runner-tokens)
            rotate_runner_tokens
            exit $?
            ;;
        --mark-rotated)
            if [[ -z "${2:-}" ]]; then
                log_error "Token name required for --mark-rotated"
                exit 1
            fi
            mark_token_rotated "$2"
            exit $?
            ;;
        --schedule)
            schedule_rotation
            exit $?
            ;;
        --report)
            generate_rotation_report
            exit $?
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"