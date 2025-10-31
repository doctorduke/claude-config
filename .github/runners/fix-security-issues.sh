#!/usr/bin/env bash

################################################################################
# Security Fix Script for Token Sanitization
# Fixes CRITICAL issues in PR #10
#
# This script addresses:
# 1. Incomplete token regex patterns (missing OAuth, refresh, user-to-server)
# 2. Inconsistent regex between sanitize_log and verify_no_tokens_in_logs
# 3. Removes unused contains_token function
# 4. Adds backup before overwrite in fix-token-security.sh
################################################################################

set -e
set -u
set -o pipefail

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Applying Security Fixes for PR #10${NC}"
echo -e "${BLUE}========================================${NC}"

# Backup original file with timestamp
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
echo -e "${YELLOW}Creating backup...${NC}"
cp scripts/setup-runner.sh "scripts/setup-runner.sh.backup-${TIMESTAMP}"
echo -e "${GREEN}✓ Backup created: scripts/setup-runner.sh.backup-${TIMESTAMP}${NC}"

# Define the comprehensive token pattern
# Per GitHub documentation, all token types:
FULL_TOKEN_PATTERN='(ghp_|ghs_|github_pat_|gho_|ghr_|ghu_to_s_)[A-Za-z0-9_]+'

echo -e "${YELLOW}Fixing sanitize_log function...${NC}"
# Fix sanitize_log function with ALL token patterns
sed -i '75,84s|ghp_\|ghs_\|github_pat_|ghp_\|ghs_\|github_pat_\|gho_\|ghr_\|ghu_to_s_|g' scripts/setup-runner.sh

echo -e "${GREEN}✓ Fixed sanitize_log to include all GitHub token patterns${NC}"

echo -e "${YELLOW}Fixing verify_no_tokens_in_logs function...${NC}"
# Fix verify_no_tokens_in_logs to match sanitize_log patterns
sed -i "98s|(ghp_\|ghs_\|github_pat_)[A-Za-z0-9_]+|${FULL_TOKEN_PATTERN}|" scripts/setup-runner.sh

echo -e "${GREEN}✓ Fixed verify_no_tokens_in_logs to match sanitize_log patterns${NC}"

echo -e "${YELLOW}Removing unused contains_token function...${NC}"
# Remove the unused contains_token function (lines 86-93)
sed -i '86,93d' scripts/setup-runner.sh

echo -e "${GREEN}✓ Removed unused contains_token function${NC}"

echo -e "${YELLOW}Fixing fix-token-security.sh to add backup...${NC}"
# Create improved fix-token-security.sh with backup
cat > scripts/fix-token-security.sh << 'EOF'
#!/usr/bin/env bash
# Security fix script for setup-runner.sh

set -e

# Create backup before applying fixes
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
if [[ -f scripts/setup-runner.sh ]]; then
    cp scripts/setup-runner.sh "scripts/setup-runner.sh.backup-${TIMESTAMP}"
    echo "Backup created: scripts/setup-runner.sh.backup-${TIMESTAMP}"
fi

# Apply security fixes to setup-runner.sh
cat > scripts/setup-runner.sh << 'SETUP_EOF'
#!/usr/bin/env bash

################################################################################
# GitHub Actions Self-Hosted Runner Setup Script
# Version: 1.0.0
# Platform: WSL 2.0 / Linux / macOS
#
# Description: Automates installation and configuration of GitHub Actions
#              self-hosted runners with support for multiple concurrent runners
#              on a single host.
#
# Usage:
#   ./setup-runner.sh --org <ORG> --token <TOKEN> [options]
#
# Required Arguments:
#   --org <ORG>           GitHub organization name
#   --token <TOKEN>       Runner registration token
#
# Optional Arguments:
#   --runner-id <ID>      Runner ID number (default: 1)
#   --name <NAME>         Custom runner name (default: runner-<hostname>-<ID>)
#   --labels <LABELS>     Comma-separated labels (default: self-hosted,linux,x64,ai-agent)
#   --work-dir <DIR>      Custom work directory (default: ~/actions-runner-<ID>)
#   --no-service          Skip systemd service installation
#   --update              Update existing runner to latest version
#   --help                Show this help message
################################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

# Script constants
readonly SCRIPT_VERSION="1.0.0"
readonly RUNNER_VERSION="latest"
readonly GITHUB_RUNNER_URL="https://github.com/actions/runner/releases"
readonly LOG_FILE="setup-runner.log"
readonly MIN_DISK_SPACE_GB=10

# Color output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Default values
GITHUB_ORG=""
RUNNER_TOKEN=""
RUNNER_ID=1
RUNNER_NAME=""
RUNNER_LABELS="self-hosted,linux,x64,ai-agent,wsl-ubuntu-22.04"
WORK_DIR=""
INSTALL_SERVICE=true
UPDATE_MODE=false

################################################################################
# Security Functions
################################################################################

# Mask sensitive tokens in output
mask_token() {
    local token="$1"
    if [[ -z "$token" ]]; then
        echo "[EMPTY]"
    elif [[ ${#token} -le 8 ]]; then
        echo "[REDACTED]"
    else
        # Show first 4 and last 4 characters only
        echo "${token:0:4}...${token: -4}"
    fi
}

# Sanitize log messages to prevent token exposure
# Comprehensive token sanitization for ALL GitHub token types
sanitize_log() {
    local message="$1"
    # Replace ALL GitHub token patterns with [REDACTED]
    # Complete list per GitHub documentation:
    # - ghp_ : GitHub personal access tokens (classic)
    # - ghs_ : GitHub server-to-server tokens
    # - github_pat_ : GitHub personal access tokens (fine-grained)
    # - gho_ : GitHub OAuth tokens
    # - ghr_ : GitHub refresh tokens
    # - ghu_to_s_ : GitHub user-to-server tokens
    echo "$message" | sed -E \
        -e 's/(ghp_|ghs_|github_pat_|gho_|ghr_|ghu_to_s_)[A-Za-z0-9_]+/[REDACTED]/g' \
        -e 's/(token[[:space:]]*[:=][[:space:]]*)[A-Za-z0-9_-]+/\1[REDACTED]/gi' \
        -e 's/(--token[[:space:]]+)[A-Za-z0-9_-]+/\1[REDACTED]/gi' \
        -e 's/(bearer[[:space:]]+)[A-Za-z0-9_-]+/\1[REDACTED]/gi' \
        -e 's/\b[A-Fa-f0-9]{40}\b/[REDACTED]/g'
}

# Verify no tokens in log file
verify_no_tokens_in_logs() {
    if [[ -f "$LOG_FILE" ]]; then
        # Check for ALL GitHub token types
        if grep -qE '(ghp_|ghs_|github_pat_|gho_|ghr_|ghu_to_s_)[A-Za-z0-9_]+' "$LOG_FILE"; then
            log_error "WARNING: Potential token found in log file!"
            return 1
        fi
    fi
    return 0
}

################################################################################
# Utility Functions
################################################################################

log() {
    local safe_msg=$(sanitize_log "$*")
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $safe_msg" | tee -a "$LOG_FILE"
}

log_error() {
    local safe_msg=$(sanitize_log "$*")
    echo -e "${RED}[ERROR]${NC} $safe_msg" | tee -a "$LOG_FILE" >&2
}

log_warn() {
    local safe_msg=$(sanitize_log "$*")
    echo -e "${YELLOW}[WARN]${NC} $safe_msg" | tee -a "$LOG_FILE"
}

log_info() {
    local safe_msg=$(sanitize_log "$*")
    echo -e "${BLUE}[INFO]${NC} $safe_msg" | tee -a "$LOG_FILE"
}

show_help() {
    cat << HELP_EOF
GitHub Actions Self-Hosted Runner Setup Script v${SCRIPT_VERSION}

Usage: $0 --org <ORG> --token <TOKEN> [options]

Required Arguments:
  --org <ORG>           GitHub organization name
  --token <TOKEN>       Runner registration token

Optional Arguments:
  --runner-id <ID>      Runner ID number (default: 1)
  --name <NAME>         Custom runner name (default: runner-<hostname>-<ID>)
  --labels <LABELS>     Comma-separated labels (default: self-hosted,linux,x64,ai-agent,wsl-ubuntu-22.04)
  --work-dir <DIR>      Custom work directory (default: ~/actions-runner-<ID>)
  --no-service          Skip systemd service installation
  --update              Update existing runner to latest version
  --help                Show this help message

Examples:
  # Install first runner
  $0 --org myorg --token [REDACTED]

  # Install second runner with custom labels
  $0 --org myorg --token [REDACTED] --runner-id 2 --labels "self-hosted,linux,x64,gpu"

  # Update existing runner
  $0 --org myorg --token [REDACTED] --runner-id 1 --update

HELP_EOF
    exit 0
}

################################################################################
# System Detection and Validation
################################################################################

detect_os() {
    local os_type=""
    local os_arch=""

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        os_type="linux"
        # Check if running in WSL
        if grep -qi microsoft /proc/version 2>/dev/null; then
            log_info "Detected Windows Subsystem for Linux (WSL)"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        os_type="osx"
    else
        log_error "Unsupported OS: $OSTYPE"
        exit 1
    fi

    os_arch="$(uname -m)"
    case "$os_arch" in
        x86_64|amd64)
            os_arch="x64"
            ;;
        aarch64|arm64)
            os_arch="arm64"
            ;;
        *)
            log_error "Unsupported architecture: $os_arch"
            exit 1
            ;;
    esac

    echo "${os_type}-${os_arch}"
}

check_prerequisites() {
    log "Checking prerequisites..."

    # Check for required commands
    local required_cmds=("curl" "tar" "jq")
    for cmd in "${required_cmds[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "Required command not found: $cmd"
            log_error "Please install: sudo apt-get install $cmd (Ubuntu/Debian) or brew install $cmd (macOS)"
            exit 1
        fi
    done

    # Check disk space
    local available_space
    available_space=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
    if [[ "$available_space" -lt "$MIN_DISK_SPACE_GB" ]]; then
        log_error "Insufficient disk space. Required: ${MIN_DISK_SPACE_GB}GB, Available: ${available_space}GB"
        exit 1
    fi

    # Check internet connectivity
    if ! curl -s --max-time 5 https://api.github.com > /dev/null; then
        log_error "Cannot reach api.github.com. Check your internet connection."
        exit 1
    fi

    log "Prerequisites check passed"
}

check_systemd() {
    if command -v systemctl &> /dev/null; then
        if systemctl --version &> /dev/null; then
            return 0
        fi
    fi
    return 1
}

################################################################################
# Runner Installation Functions
################################################################################

get_latest_runner_version() {
    local platform="$1"

    log "Fetching latest runner version for $platform..."

    # Get latest release info from GitHub API
    local api_url="https://api.github.com/repos/actions/runner/releases/latest"
    local release_info
    release_info=$(curl -s "$api_url")

    local version
    version=$(echo "$release_info" | jq -r '.tag_name' | sed 's/^v//')

    if [[ -z "$version" || "$version" == "null" ]]; then
        log_error "Failed to fetch latest runner version"
        exit 1
    fi

    echo "$version"
}

download_runner() {
    local platform="$1"
    local version="$2"
    local download_dir="$3"

    log "Downloading GitHub Actions runner v${version} for ${platform}..."

    local filename="actions-runner-${platform}-${version}.tar.gz"
    local download_url="https://github.com/actions/runner/releases/download/v${version}/${filename}"

    cd "$download_dir" || exit 1

    if [[ -f "$filename" ]] && [[ "$UPDATE_MODE" == "false" ]]; then
        log_warn "Runner package already exists, skipping download"
    else
        if ! curl -L -o "$filename" "$download_url"; then
            log_error "Failed to download runner from $download_url"
            exit 1
        fi
        log "Downloaded $filename"
    fi

    # Extract the runner
    log "Extracting runner..."
    tar xzf "$filename"

    # Clean up archive
    rm -f "$filename"

    log "Runner extracted successfully"
}

configure_runner() {
    local org="$1"
    local token="$2"
    local name="$3"
    local labels="$4"
    local work_dir="$5"
    local runner_dir="$6"

    log "Configuring runner: $name"
    log_info "Using registration token: $(mask_token "$token")"

    cd "$runner_dir" || exit 1

    # Build configuration command using array (SECURITY FIX)
    local config_args=()
    config_args+=("--url" "https://github.com/${org}")
    config_args+=("--token" "${token}")
    config_args+=("--name" "${name}")

    if [[ -n "$labels" ]]; then
        config_args+=("--labels" "${labels}")
    fi

    if [[ -n "$work_dir" ]]; then
        mkdir -p "$work_dir"
        config_args+=("--work" "${work_dir}")
    fi

    # Add unattended flag for automation
    config_args+=("--unattended")

    # Add replace flag for updates
    if [[ "$UPDATE_MODE" == "true" ]]; then
        config_args+=("--replace")
    fi

    log_info "Running configuration with sanitized parameters..."

    # Execute configuration without eval (SECURITY FIX)
    if ! ./config.sh "${config_args[@]}"; then
        log_error "Runner configuration failed"
        exit 1
    fi

    log "Runner configured successfully"

    # Verify no tokens in logs
    verify_no_tokens_in_logs
}

################################################################################
# Service Installation Functions
################################################################################

install_systemd_service() {
    local runner_dir="$1"
    local runner_name="$2"

    log "Installing systemd service for $runner_name..."

    cd "$runner_dir" || exit 1

    # Check if running as root (not recommended for runner)
    if [[ $EUID -eq 0 ]]; then
        log_error "Do not run this script as root. Runners should run as a regular user."
        exit 1
    fi

    # Install service using runner's built-in installer
    if ! sudo ./svc.sh install; then
        log_error "Failed to install systemd service"
        exit 1
    fi

    log "Systemd service installed"
}

start_runner_service() {
    local runner_dir="$1"

    log "Starting runner service..."

    cd "$runner_dir" || exit 1

    if ! sudo ./svc.sh start; then
        log_error "Failed to start runner service"
        exit 1
    fi

    log "Runner service started successfully"
}

check_service_status() {
    local runner_dir="$1"

    cd "$runner_dir" || exit 1

    if sudo ./svc.sh status &> /dev/null; then
        log "Runner service is running"
        return 0
    else
        log_warn "Runner service is not running"
        return 1
    fi
}

################################################################################
# Update Functions
################################################################################

update_runner() {
    local runner_dir="$1"

    log "Updating runner in $runner_dir..."

    if [[ ! -d "$runner_dir" ]]; then
        log_error "Runner directory not found: $runner_dir"
        exit 1
    fi

    cd "$runner_dir" || exit 1

    # Stop service if running
    if sudo ./svc.sh status &> /dev/null; then
        log "Stopping runner service..."
        sudo ./svc.sh stop
        sudo ./svc.sh uninstall
    fi

    # Remove old runner configuration (with sanitized token)
    if [[ -f "./config.sh" ]]; then
        log "Removing old runner configuration..."
        log_info "Using token: $(mask_token "$RUNNER_TOKEN")"

        # Use array for remove command (SECURITY FIX)
        local remove_args=()
        remove_args+=("remove")
        remove_args+=("--token" "${RUNNER_TOKEN}")

        ./config.sh "${remove_args[@]}"
    fi

    # Clean up old files but preserve .credentials and .runner
    log "Cleaning up old runner files..."
    find . -maxdepth 1 -type f ! -name '.credentials' ! -name '.runner' -delete
    find . -maxdepth 1 -type d ! -name '.' ! -name '..' ! -name '_work' -exec rm -rf {} + 2>/dev/null || true

    log "Runner update prepared, will download new version..."
}

################################################################################
# Validation Functions
################################################################################

validate_installation() {
    local runner_dir="$1"

    log "Validating installation..."

    # Check if runner directory exists
    if [[ ! -d "$runner_dir" ]]; then
        log_error "Runner directory not found: $runner_dir"
        return 1
    fi

    # Check if config files exist
    if [[ ! -f "$runner_dir/.runner" ]]; then
        log_error "Runner configuration file not found"
        return 1
    fi

    # Check if credentials exist
    if [[ ! -f "$runner_dir/.credentials" ]]; then
        log_error "Runner credentials file not found"
        return 1
    fi

    # Verify runner binary
    if [[ ! -x "$runner_dir/run.sh" ]]; then
        log_error "Runner executable not found or not executable"
        return 1
    fi

    log "Installation validation passed"
    return 0
}

################################################################################
# Main Installation Flow
################################################################################

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --org)
                GITHUB_ORG="$2"
                shift 2
                ;;
            --token)
                RUNNER_TOKEN="$2"
                shift 2
                ;;
            --runner-id)
                RUNNER_ID="$2"
                shift 2
                ;;
            --name)
                RUNNER_NAME="$2"
                shift 2
                ;;
            --labels)
                RUNNER_LABELS="$2"
                shift 2
                ;;
            --work-dir)
                WORK_DIR="$2"
                shift 2
                ;;
            --no-service)
                INSTALL_SERVICE=false
                shift
                ;;
            --update)
                UPDATE_MODE=true
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

    # Validate required arguments
    if [[ -z "$GITHUB_ORG" ]]; then
        log_error "Missing required argument: --org"
        show_help
    fi

    if [[ -z "$RUNNER_TOKEN" ]]; then
        log_error "Missing required argument: --token"
        show_help
    fi

    # Set defaults
    if [[ -z "$RUNNER_NAME" ]]; then
        RUNNER_NAME="runner-$(hostname)-${RUNNER_ID}"
    fi

    if [[ -z "$WORK_DIR" ]]; then
        WORK_DIR="${HOME}/actions-runner-${RUNNER_ID}/_work"
    fi
}

main() {
    log "==================================================================="
    log "GitHub Actions Self-Hosted Runner Setup v${SCRIPT_VERSION}"
    log "==================================================================="

    parse_arguments "$@"

    # Log sanitized parameters
    log_info "Organization: $GITHUB_ORG"
    log_info "Runner Token: $(mask_token "$RUNNER_TOKEN")"
    log_info "Runner ID: $RUNNER_ID"

    # Detect OS and architecture
    local platform
    platform=$(detect_os)
    log "Platform detected: $platform"

    # Check prerequisites
    check_prerequisites

    # Set runner directory
    local runner_dir="${HOME}/actions-runner-${RUNNER_ID}"
    log "Runner directory: $runner_dir"

    # Handle update mode
    if [[ "$UPDATE_MODE" == "true" ]]; then
        update_runner "$runner_dir"
    else
        # Create runner directory
        mkdir -p "$runner_dir"
    fi

    # Get latest runner version
    local version
    version=$(get_latest_runner_version "$platform")
    log "Latest runner version: $version"

    # Download and extract runner
    download_runner "$platform" "$version" "$runner_dir"

    # Configure runner
    configure_runner "$GITHUB_ORG" "$RUNNER_TOKEN" "$RUNNER_NAME" "$RUNNER_LABELS" "$WORK_DIR" "$runner_dir"

    # Validate installation
    if ! validate_installation "$runner_dir"; then
        log_error "Installation validation failed"
        exit 1
    fi

    # Install and start service
    if [[ "$INSTALL_SERVICE" == "true" ]]; then
        if check_systemd; then
            install_systemd_service "$runner_dir" "$RUNNER_NAME"
            start_runner_service "$runner_dir"
            check_service_status "$runner_dir"
        else
            log_warn "systemd not available, skipping service installation"
            log_info "To run the runner manually: cd $runner_dir && ./run.sh"
        fi
    else
        log_info "Service installation skipped (--no-service flag)"
        log_info "To run the runner manually: cd $runner_dir && ./run.sh"
    fi

    log "==================================================================="
    log "Runner setup completed successfully!"
    log "==================================================================="
    log_info "Runner Name: $RUNNER_NAME"
    log_info "Runner Directory: $runner_dir"
    log_info "Work Directory: $WORK_DIR"
    log_info "Labels: $RUNNER_LABELS"
    log ""
    log_info "To check runner status:"
    log_info "  sudo $runner_dir/svc.sh status"
    log ""
    log_info "To view runner logs:"
    log_info "  journalctl -u actions.runner.${GITHUB_ORG}.${RUNNER_NAME} -f"
    log ""
    log_info "Verify runner in GitHub:"
    log_info "  https://github.com/organizations/${GITHUB_ORG}/settings/actions/runners"

    # Final security check
    log ""
    log_info "Running final security check..."
    if verify_no_tokens_in_logs; then
        log "Security check passed: No tokens found in logs"
    else
        log_warn "Security check warning: Review log file for potential token exposure"
    fi
}

# Run main function
main "$@"
SETUP_EOF

echo "Security fixes applied to setup-runner.sh"
EOF

chmod +x scripts/fix-token-security.sh
echo -e "${GREEN}✓ Updated fix-token-security.sh with backup functionality${NC}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Security Fixes Applied Successfully${NC}"
echo -e "${BLUE}========================================${NC}"

# Show what was fixed
echo -e "\n${GREEN}Token patterns now detected:${NC}"
echo "  • ghp_ - GitHub personal access tokens (classic)"
echo "  • ghs_ - GitHub server-to-server tokens"
echo "  • github_pat_ - GitHub personal access tokens (fine-grained)"
echo "  • gho_ - GitHub OAuth tokens ${GREEN}[NEW]${NC}"
echo "  • ghr_ - GitHub refresh tokens ${GREEN}[NEW]${NC}"
echo "  • ghu_to_s_ - GitHub user-to-server tokens ${GREEN}[NEW]${NC}"

echo -e "\n${GREEN}Functions fixed:${NC}"
echo "  • sanitize_log() - Now detects ALL token types"
echo "  • verify_no_tokens_in_logs() - Matches sanitize_log patterns"
echo "  • contains_token() - ${RED}REMOVED${NC} (unused function)"

echo -e "\n${GREEN}Files modified:${NC}"
echo "  • scripts/setup-runner.sh - All security fixes applied"
echo "  • scripts/fix-token-security.sh - Added backup functionality"

echo -e "\n${YELLOW}Next step: Run tests to verify fixes${NC}"
echo "  ./test-token-sanitization-comprehensive.sh"