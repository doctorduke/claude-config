#!/usr/bin/env bash
# Source network utilities
SCRIPT_DIR_SETUP="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR_SETUP}/lib/network.sh"

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
# Utility Functions
################################################################################

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" | tee -a "$LOG_FILE"
}

show_help() {
    cat << EOF
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
  $0 --org myorg --token ghp_xxxxxxxxxxxxx

  # Install second runner with custom labels
  $0 --org myorg --token ghp_xxxxxxxxxxxxx --runner-id 2 --labels "self-hosted,linux,x64,gpu"

  # Update existing runner
  $0 --org myorg --token ghp_xxxxxxxxxxxxx --runner-id 1 --update

EOF
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

    cd "$runner_dir" || exit 1

    # Build configuration command using an array for safety
    # This prevents command injection through variable values
    local -a config_cmd=(
        "./config.sh"
        "--url" "https://github.com/${org}"
        "--token" "${token}"
        "--name" "${name}"
    )

    if [[ -n "$labels" ]]; then
        config_cmd+=("--labels" "${labels}")
    fi

    if [[ -n "$work_dir" ]]; then
        mkdir -p "$work_dir"
        config_cmd+=("--work" "${work_dir}")
    fi

    # Add unattended flag for automation
    config_cmd+=("--unattended")

    # Add replace flag for updates
    if [[ "$UPDATE_MODE" == "true" ]]; then
        config_cmd+=("--replace")
    fi

    log_info "Running configuration..."
    if ! "${config_cmd[@]}"; then
        log_error "Runner configuration failed"
        exit 1
    fi
    log "Runner configured successfully"
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

    # Remove old runner configuration
    if [[ -f "./config.sh" ]]; then
        log "Removing old runner configuration..."
        ./config.sh remove --token "$RUNNER_TOKEN"
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
}

# Run main function
main "$@"
