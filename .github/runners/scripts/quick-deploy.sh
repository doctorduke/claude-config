#!/usr/bin/env bash
# Source network utilities
SCRIPT_DIR_DEPLOY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR_DEPLOY}/lib/network.sh"
#
# quick-deploy.sh - One-Command GitHub Actions Runner Deployment
#
# Description:
#   Interactive deployment script that sets up complete GitHub Actions
#   runner infrastructure with minimal user input. Handles dependency
#   installation, multi-runner setup, and post-install validation.
#
# Usage:
#   ./quick-deploy.sh [OPTIONS]
#
# Options:
#   --org URL          GitHub organization URL (e.g., https://github.com/myorg)
#   --token TOKEN      GitHub registration token
#   --count N          Number of runners to deploy (default: 3)
#   --labels LABELS    Comma-separated labels (default: self-hosted,linux,x64,ai-agent)
#   --name PREFIX      Runner name prefix (default: runner)
#   --dir DIR          Installation directory (default: $HOME/actions-runner)
#   --non-interactive  Skip all prompts, use defaults or CLI args
#   --skip-deps        Skip dependency installation
#   --help             Display this help message
#
# Examples:
#   ./quick-deploy.sh                                    # Interactive mode
#   ./quick-deploy.sh --org https://github.com/acme      # Pre-fill org
#   ./quick-deploy.sh --count 5 --non-interactive        # Deploy 5 runners
#
# Prerequisites:
#   - Linux, macOS, or Windows+WSL 2.0
#   - Internet connectivity
#   - Sudo access (for service installation)
#

set -euo pipefail

# ============================================================================
# Configuration and Defaults
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITHUB_ORG="${GITHUB_ORG:-}"
RUNNER_TOKEN="${RUNNER_TOKEN:-}"
RUNNER_COUNT="${RUNNER_COUNT:-3}"
RUNNER_LABELS="${RUNNER_LABELS:-self-hosted,linux,x64,ai-agent}"
RUNNER_NAME_PREFIX="${RUNNER_NAME_PREFIX:-runner}"
INSTALL_DIR_BASE="${INSTALL_DIR_BASE:-$HOME/actions-runner}"
INTERACTIVE=true
SKIP_DEPS=false
# Create secure log file
if [[ -z "${LOG_FILE:-}" ]]; then
    LOG_FILE=$(mktemp -t "quick-deploy-$(date +%Y%m%d-%H%M%S).XXXXXX.log")
    chmod 600 "${LOG_FILE}"
fi

# Runner version (latest)
RUNNER_VERSION="${RUNNER_VERSION:-2.311.0}"

# Colors
if [ -t 1 ]; then
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED=''
    YELLOW=''
    GREEN=''
    BLUE=''
    CYAN=''
    BOLD=''
    NC=''
fi

# ============================================================================
# Helper Functions
# ============================================================================

log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

log_info() {
    log "${BLUE}[INFO]${NC} $1"
}

log_success() {
    log "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    log "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    log "${RED}[ERROR]${NC} $1"
}

print_banner() {
    log ""
    log "${CYAN}${BOLD}========================================${NC}"
    log "${CYAN}${BOLD}  GitHub Actions Quick Deploy${NC}"
    log "${CYAN}${BOLD}========================================${NC}"
    log ""
}

print_section() {
    log ""
    log "${BOLD}=== $1 ===${NC}"
}

usage() {
    grep '^#' "$0" | grep -v '#!/usr/bin/env' | sed 's/^# //' | sed 's/^#//'
    exit 0
}

prompt() {
    local prompt_text="$1"
    local default_value="$2"
    local var_name="$3"
    local is_secret="${4:-false}"

    if [ "$INTERACTIVE" = false ]; then
        declare -g "$var_name=$default_value"
        return
    fi

    local input_value
    if [ "$is_secret" = true ]; then
        read -rsp "$(echo -e "${CYAN}$prompt_text${NC} [$default_value]: ")" input_value
        echo ""
    else
        read -rp "$(echo -e "${CYAN}$prompt_text${NC} [$default_value]: ")" input_value
    fi

    if [ -z "$input_value" ]; then
        declare -g "$var_name=$default_value"
    else
        declare -g "$var_name=$input_value"
    fi
}

confirm() {
    if [ "$INTERACTIVE" = false ]; then
        return 0
    fi

    local prompt_text="$1"
    local response

    read -rp "$(echo -e "${YELLOW}$prompt_text (y/N):${NC} ")" response

    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# ============================================================================
# System Detection
# ============================================================================

detect_os() {
    print_section "Detecting Operating System"

    local os_type=""
    local os_arch=""

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        os_type="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        os_type="osx"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        os_type="linux"  # WSL/Git Bash treated as Linux
    else
        log_error "Unsupported OS type: $OSTYPE"
        exit 1
    fi

    os_arch=$(uname -m)
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

    log_success "Detected: $os_type-$os_arch"

    echo "$os_type-$os_arch"
}

# ============================================================================
# Dependency Installation
# ============================================================================

install_dependencies() {
    if [ "$SKIP_DEPS" = true ]; then
        log_info "Skipping dependency installation (--skip-deps)"
        return 0
    fi

    print_section "Installing Dependencies"

    local missing_deps=()

    # Check for required tools
    command -v curl >/dev/null 2>&1 || missing_deps+=("curl")
    command -v tar >/dev/null 2>&1 || missing_deps+=("tar")
    command -v jq >/dev/null 2>&1 || missing_deps+=("jq")

    if [ ${#missing_deps[@]} -eq 0 ]; then
        log_success "All required dependencies installed"
        return 0
    fi

    log_warning "Missing dependencies: ${missing_deps[*]}"

    if ! confirm "Install missing dependencies?"; then
        log_error "Cannot proceed without dependencies"
        exit 1
    fi

    # Detect package manager and install
    if command -v apt-get >/dev/null 2>&1; then
        log_info "Installing via apt-get..."
        sudo apt-get update -qq
        sudo apt-get install -y "${missing_deps[@]}"

    elif command -v yum >/dev/null 2>&1; then
        log_info "Installing via yum..."
        sudo yum install -y "${missing_deps[@]}"

    elif command -v brew >/dev/null 2>&1; then
        log_info "Installing via Homebrew..."
        brew install "${missing_deps[@]}"

    else
        log_error "No supported package manager found"
        log_error "Please install manually: ${missing_deps[*]}"
        exit 1
    fi

    log_success "Dependencies installed"
}

# ============================================================================
# GitHub CLI Installation (Optional)
# ============================================================================

install_github_cli() {
    if command -v gh >/dev/null 2>&1; then
        log_success "GitHub CLI already installed"
        return 0
    fi

    if ! confirm "Install GitHub CLI for enhanced features?"; then
        log_info "Skipping GitHub CLI installation"
        return 0
    fi

    log_info "Installing GitHub CLI..."

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt-get update -qq
        sudo apt-get install -y gh

    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install gh

    else
        log_warning "Auto-install not supported on this platform"
        log_info "Visit: https://cli.github.com/ for manual installation"
        return 0
    fi

    log_success "GitHub CLI installed"
}

# ============================================================================
# Runner Download and Installation
# ============================================================================

download_runner() {
    local os_platform="$1"
    local download_dir="$2"

    print_section "Downloading GitHub Actions Runner"

    # Determine download URL
    local runner_url="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-${os_platform}-${RUNNER_VERSION}.tar.gz"

    log_info "Download URL: $runner_url"
    log_info "Target directory: $download_dir"

    # Create directory
    mkdir -p "$download_dir"

    # Download
    if ! curl -L -o "$download_dir/actions-runner.tar.gz" "$runner_url"; then
        log_error "Failed to download runner"
        exit 1
    fi

    log_success "Downloaded runner package"

    # Extract
    log_info "Extracting runner..."
    tar xzf "$download_dir/actions-runner.tar.gz" -C "$download_dir"
    rm "$download_dir/actions-runner.tar.gz"

    log_success "Extracted runner to $download_dir"
}

# ============================================================================
# Runner Configuration
# ============================================================================

configure_runner() {
    local runner_dir="$1"
    local runner_name="$2"
    local org_url="$3"
    local token="$4"
    local labels="$5"

    print_section "Configuring Runner: $runner_name"

    cd "$runner_dir"

    log_info "Running configuration script..."

    # Run config.sh with parameters
    if ! ./config.sh \
        --url "$org_url" \
        --token "$token" \
        --name "$runner_name" \
        --labels "$labels" \
        --work "_work" \
        --unattended \
        --replace; then
        log_error "Runner configuration failed"
        return 1
    fi

    log_success "Runner configured: $runner_name"

    # Install as service
    if [ -f ./svc.sh ]; then
        log_info "Installing runner as service..."

        if sudo ./svc.sh install; then
            log_success "Service installed"

            if sudo ./svc.sh start; then
                log_success "Service started"
            else
                log_warning "Failed to start service (may need manual start)"
            fi
        else
            log_warning "Service installation failed (may need manual setup)"
        fi
    fi

    return 0
}

# ============================================================================
# Multi-Runner Deployment
# ============================================================================

deploy_runners() {
    local os_platform="$1"

    print_section "Deploying $RUNNER_COUNT Runner(s)"

    local success_count=0
    local fail_count=0

    for i in $(seq 1 "$RUNNER_COUNT"); do
        local runner_name="${RUNNER_NAME_PREFIX}-$(printf "%02d" "$i")"
        local runner_dir="${INSTALL_DIR_BASE}-${i}"

        log_info "[$i/$RUNNER_COUNT] Deploying $runner_name..."

        # Download and extract
        download_runner "$os_platform" "$runner_dir"

        # Configure
        if configure_runner "$runner_dir" "$runner_name" "$GITHUB_ORG" "$RUNNER_TOKEN" "$RUNNER_LABELS"; then
            ((success_count++))
            log_success "[$i/$RUNNER_COUNT] $runner_name deployed successfully"
        else
            ((fail_count++))
            log_error "[$i/$RUNNER_COUNT] $runner_name deployment failed"
        fi

        # Brief pause between runners
        sleep 2
    done

    print_section "Deployment Summary"
    log_success "Successful: $success_count"
    if [ "$fail_count" -gt 0 ]; then
        log_error "Failed: $fail_count"
    fi

    return $([ "$fail_count" -eq 0 ] && echo 0 || echo 1)
}

# ============================================================================
# Post-Install Validation
# ============================================================================

validate_deployment() {
    print_section "Post-Install Validation"

    log_info "Waiting 10 seconds for runners to initialize..."
    sleep 10

    local validation_passed=true

    # Check each runner
    for i in $(seq 1 "$RUNNER_COUNT"); do
        local runner_dir="${INSTALL_DIR_BASE}-${i}"
        local runner_name="${RUNNER_NAME_PREFIX}-$(printf "%02d" "$i")"

        if [ ! -f "$runner_dir/.runner" ]; then
            log_error "[$runner_name] Configuration file missing"
            validation_passed=false
            continue
        fi

        if [ ! -f "$runner_dir/.credentials" ]; then
            log_error "[$runner_name] Credentials file missing"
            validation_passed=false
            continue
        fi

        # Check if service is running
        if systemctl is-active --quiet "actions.runner.*${runner_name}.service" 2>/dev/null; then
            log_success "[$runner_name] Service is active"
        elif pgrep -f "Runner.Listener.*${runner_name}" >/dev/null 2>&1; then
            log_success "[$runner_name] Process is running"
        else
            log_warning "[$runner_name] Service/process not detected"
            validation_passed=false
        fi
    done

    if [ "$validation_passed" = true ]; then
        log_success "All validation checks passed!"
        return 0
    else
        log_warning "Some validation checks failed - review above"
        return 1
    fi
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --org)
                GITHUB_ORG="$2"
                shift 2
                ;;
            --token)
                RUNNER_TOKEN="$2"
                shift 2
                ;;
            --count)
                RUNNER_COUNT="$2"
                shift 2
                ;;
            --labels)
                RUNNER_LABELS="$2"
                shift 2
                ;;
            --name)
                RUNNER_NAME_PREFIX="$2"
                shift 2
                ;;
            --dir)
                INSTALL_DIR_BASE="$2"
                shift 2
                ;;
            --non-interactive)
                INTERACTIVE=false
                shift
                ;;
            --skip-deps)
                SKIP_DEPS=true
                shift
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

    # Start logging
    echo "Quick Deploy Log - $(date)" > "$LOG_FILE"

    print_banner

    log_info "Log file: $LOG_FILE"

    # Detect OS
    OS_PLATFORM=$(detect_os)

    # Install dependencies
    install_dependencies

    # Optional: GitHub CLI
    install_github_cli

    # Interactive prompts
    print_section "Configuration"

    prompt "GitHub Organization URL (e.g., https://github.com/myorg)" "$GITHUB_ORG" GITHUB_ORG
    prompt "Runner Registration Token" "$RUNNER_TOKEN" RUNNER_TOKEN true
    prompt "Number of runners to deploy" "$RUNNER_COUNT" RUNNER_COUNT
    prompt "Runner labels (comma-separated)" "$RUNNER_LABELS" RUNNER_LABELS
    prompt "Runner name prefix" "$RUNNER_NAME_PREFIX" RUNNER_NAME_PREFIX
    prompt "Installation directory base" "$INSTALL_DIR_BASE" INSTALL_DIR_BASE

    # Validate inputs
    if [ -z "$GITHUB_ORG" ]; then
        log_error "GitHub organization URL is required"
        exit 1
    fi

    if [ -z "$RUNNER_TOKEN" ]; then
        log_error "Runner registration token is required"
        log_info "Generate token at: $GITHUB_ORG/settings/actions/runners/new"
        exit 1
    fi

    if ! [[ "$RUNNER_COUNT" =~ ^[0-9]+$ ]] || [ "$RUNNER_COUNT" -lt 1 ] || [ "$RUNNER_COUNT" -gt 20 ]; then
        log_error "Runner count must be between 1 and 20"
        exit 1
    fi

    # Confirmation
    print_section "Deployment Plan"
    log "Organization: $GITHUB_ORG"
    log "Runner Count: $RUNNER_COUNT"
    log "Runner Prefix: $RUNNER_NAME_PREFIX"
    log "Labels: $RUNNER_LABELS"
    log "Install Directory: $INSTALL_DIR_BASE-{1..$RUNNER_COUNT}"
    log "Platform: $OS_PLATFORM"
    log ""

    if ! confirm "Proceed with deployment?"; then
        log_warning "Deployment cancelled by user"
        exit 0
    fi

    # Deploy runners
    if deploy_runners "$OS_PLATFORM"; then
        log_success "Deployment completed successfully!"
    else
        log_error "Deployment completed with errors"
    fi

    # Validate deployment
    validate_deployment || true

    # Final summary
    print_section "Next Steps"
    log ""
    log "1. Verify runners in GitHub:"
    log "   ${GITHUB_ORG}/settings/actions/runners"
    log ""
    log "2. Run health check:"
    log "   $SCRIPT_DIR/health-check.sh --runner-dir ${INSTALL_DIR_BASE}-1"
    log ""
    log "3. View runner status:"
    log "   $SCRIPT_DIR/runner-status-dashboard.sh"
    log ""
    log "4. Check logs:"
    log "   tail -f ${INSTALL_DIR_BASE}-1/_diag/Runner_*.log"
    log ""
    log_success "Quick Deploy Complete!"
    log ""
    log "Log file saved: $LOG_FILE"
}

# Run main function
main "$@"
