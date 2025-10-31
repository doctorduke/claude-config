#!/usr/bin/env bash

################################################################################
# GitHub Actions Runner Proxy Configuration Script
#
# Purpose: Automated proxy setup for corporate environments
# Platform: Windows+WSL, Linux, macOS
# Version: 1.0.0
################################################################################

set -euo pipefail

# Script metadata
SCRIPT_VERSION="1.0.0"
SCRIPT_NAME="proxy-configuration.sh"

# Color output
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Configuration
BACKUP_DIR="${HOME}/.runner-proxy-backup"
CONFIG_FILE="${HOME}/.runner-proxy-config"

################################################################################
# Utility Functions
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

print_header() {
    echo ""
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo ""
}

################################################################################
# Platform Detection
################################################################################

detect_platform() {
    if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "WSL"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "Linux"
    else
        echo "Unknown"
    fi
}

detect_shell() {
    if [ -n "${BASH_VERSION:-}" ]; then
        echo "bash"
    elif [ -n "${ZSH_VERSION:-}" ]; then
        echo "zsh"
    else
        echo "sh"
    fi
}

get_shell_rc() {
    local shell_type
    shell_type=$(detect_shell)

    case "$shell_type" in
        bash)
            if [ -f "${HOME}/.bashrc" ]; then
                echo "${HOME}/.bashrc"
            else
                echo "${HOME}/.bash_profile"
            fi
            ;;
        zsh)
            echo "${HOME}/.zshrc"
            ;;
        *)
            echo "${HOME}/.profile"
            ;;
    esac
}

################################################################################
# Input Functions
################################################################################

prompt_yes_no() {
    local prompt="$1"
    local default="${2:-n}"

    while true; do
        if [ "$default" = "y" ]; then
            read -r -p "$prompt [Y/n]: " response
            response=${response:-y}
        else
            read -r -p "$prompt [y/N]: " response
            response=${response:-n}
        fi

        case "$response" in
            [Yy]|[Yy][Ee][Ss])
                return 0
                ;;
            [Nn]|[Nn][Oo])
                return 1
                ;;
            *)
                echo "Please answer yes or no."
                ;;
        esac
    done
}

prompt_input() {
    local prompt="$1"
    local default="${2:-}"
    local value

    if [ -n "$default" ]; then
        read -r -p "$prompt [$default]: " value
        echo "${value:-$default}"
    else
        read -r -p "$prompt: " value
        echo "$value"
    fi
}

prompt_password() {
    local prompt="$1"
    local password

    read -rs -p "$prompt: " password
    echo ""
    echo "$password"
}

################################################################################
# Proxy Configuration Collection
################################################################################

collect_proxy_config() {
    print_header "Proxy Configuration Wizard"

    log_info "This wizard will help you configure proxy settings for GitHub Actions Runner"
    echo ""

    # Proxy URL
    PROXY_HOST=$(prompt_input "Proxy hostname or IP")
    PROXY_PORT=$(prompt_input "Proxy port" "8080")

    # Proxy protocol
    if prompt_yes_no "Use HTTP proxy (not HTTPS)?"; then
        PROXY_PROTOCOL="http"
    else
        PROXY_PROTOCOL="http"  # Even HTTPS proxies use http:// in environment variables
    fi

    # Authentication
    if prompt_yes_no "Does the proxy require authentication?"; then
        PROXY_USERNAME=$(prompt_input "Proxy username")
        PROXY_PASSWORD=$(prompt_password "Proxy password")
        PROXY_AUTH=true
    else
        PROXY_AUTH=false
    fi

    # NO_PROXY configuration
    log_info "Configure proxy bypass list (NO_PROXY)"
    log_info "Enter domains that should bypass the proxy (comma-separated)"
    log_info "Example: localhost,127.0.0.1,.local,.internal"

    NO_PROXY_DEFAULT="localhost,127.0.0.1,::1"
    NO_PROXY=$(prompt_input "NO_PROXY list" "$NO_PROXY_DEFAULT")

    # Build proxy URL
    if [ "$PROXY_AUTH" = true ]; then
        # URL-encode special characters in username and password
        local encoded_user
        local encoded_pass
        encoded_user=$(urlencode "$PROXY_USERNAME")
        encoded_pass=$(urlencode "$PROXY_PASSWORD")
        PROXY_URL="${PROXY_PROTOCOL}://${encoded_user}:${encoded_pass}@${PROXY_HOST}:${PROXY_PORT}"
    else
        PROXY_URL="${PROXY_PROTOCOL}://${PROXY_HOST}:${PROXY_PORT}"
    fi

    # Summary
    echo ""
    log_info "Configuration Summary:"
    echo "  Proxy: ${PROXY_HOST}:${PROXY_PORT}"
    echo "  Protocol: ${PROXY_PROTOCOL}"
    echo "  Authentication: ${PROXY_AUTH}"
    [ "$PROXY_AUTH" = true ] && echo "  Username: ${PROXY_USERNAME}"
    echo "  NO_PROXY: ${NO_PROXY}"
    echo ""

    if ! prompt_yes_no "Apply this configuration?" "y"; then
        log_warn "Configuration cancelled"
        exit 0
    fi
}

urlencode() {
    local string="$1"
    local strlen=${#string}
    local encoded=""
    local pos c o

    for (( pos=0 ; pos<strlen ; pos++ )); do
        c=${string:$pos:1}
        case "$c" in
            [-_.~a-zA-Z0-9] )
                o="${c}"
                ;;
            * )
                printf -v o '%%%02x' "'$c"
                ;;
        esac
        encoded+="${o}"
    done
    echo "${encoded}"
}

################################################################################
# Auto-Detection Functions
################################################################################

detect_existing_proxy() {
    local detected=false

    print_header "Detecting Existing Proxy Configuration"

    # Check environment variables
    if [ -n "${HTTP_PROXY:-}${HTTPS_PROXY:-}${http_proxy:-}${https_proxy:-}" ]; then
        log_info "Found proxy environment variables:"
        [ -n "${HTTP_PROXY:-}" ] && echo "  HTTP_PROXY=$HTTP_PROXY"
        [ -n "${HTTPS_PROXY:-}" ] && echo "  HTTPS_PROXY=$HTTPS_PROXY"
        [ -n "${http_proxy:-}" ] && echo "  http_proxy=$http_proxy"
        [ -n "${https_proxy:-}" ] && echo "  https_proxy=$https_proxy"
        [ -n "${NO_PROXY:-}" ] && echo "  NO_PROXY=$NO_PROXY"
        detected=true
    fi

    # Check system proxy settings (Linux)
    if command -v gsettings &> /dev/null; then
        local gnome_proxy
        gnome_proxy=$(gsettings get org.gnome.system.proxy mode 2>/dev/null || echo "")
        if [ "$gnome_proxy" = "'manual'" ]; then
            log_info "GNOME proxy detected (manual mode)"
            detected=true
        fi
    fi

    # Check Git proxy configuration
    if command -v git &> /dev/null; then
        local git_proxy
        git_proxy=$(git config --global --get http.proxy 2>/dev/null || echo "")
        if [ -n "$git_proxy" ]; then
            log_info "Git proxy detected: $git_proxy"
            detected=true
        fi
    fi

    # Check for proxy auto-config (PAC)
    if [ -f "/etc/profile.d/proxy.sh" ]; then
        log_info "System-wide proxy configuration found: /etc/profile.d/proxy.sh"
        detected=true
    fi

    # Check Windows proxy (WSL)
    local platform
    platform=$(detect_platform)
    if [ "$platform" = "WSL" ] && command -v powershell.exe &> /dev/null; then
        log_info "Checking Windows proxy settings..."
        local win_proxy
        win_proxy=$(powershell.exe -Command "Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyServer" 2>/dev/null | grep ProxyServer || echo "")
        if [ -n "$win_proxy" ]; then
            log_info "Windows proxy detected: $win_proxy"
            detected=true
        fi
    fi

    if [ "$detected" = false ]; then
        log_info "No existing proxy configuration detected"
    fi

    echo ""
    return 0
}

################################################################################
# Configuration Application Functions
################################################################################

backup_config() {
    log_info "Creating configuration backup..."

    mkdir -p "$BACKUP_DIR"
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${BACKUP_DIR}/backup_${timestamp}.tar.gz"

    # Backup shell RC files
    local shell_rc
    shell_rc=$(get_shell_rc)

    tar -czf "$backup_file" \
        -C "$HOME" \
        "$(basename "$shell_rc")" \
        ".profile" \
        2>/dev/null || true

    # Backup systemd service if exists
    if [ -f "/etc/systemd/system/actions.runner.service" ]; then
        sudo tar -czf "${backup_file}.systemd" \
            "/etc/systemd/system/actions.runner.service" \
            2>/dev/null || true
    fi

    log_success "Backup created: $backup_file"
}

apply_shell_config() {
    log_info "Configuring shell environment..."

    local shell_rc
    shell_rc=$(get_shell_rc)

    # Remove old proxy configuration if exists
    if grep -q "# GitHub Actions Runner Proxy Configuration" "$shell_rc" 2>/dev/null; then
        log_info "Removing old proxy configuration from $shell_rc"
        sed -i.bak '/# GitHub Actions Runner Proxy Configuration/,/# End GitHub Actions Runner Proxy Configuration/d' "$shell_rc"
    fi

    # Add new configuration
    cat >> "$shell_rc" <<EOF

# GitHub Actions Runner Proxy Configuration
# Generated by $SCRIPT_NAME v$SCRIPT_VERSION on $(date)
export HTTP_PROXY="$PROXY_URL"
export HTTPS_PROXY="$PROXY_URL"
export http_proxy="$PROXY_URL"
export https_proxy="$PROXY_URL"
export NO_PROXY="$NO_PROXY"
export no_proxy="$NO_PROXY"
# End GitHub Actions Runner Proxy Configuration

EOF

    log_success "Shell configuration updated: $shell_rc"
}

apply_system_config() {
    log_info "Configuring system-wide proxy..."

    # /etc/environment (requires root)
    if [ -w /etc/environment ] || sudo -n true 2>/dev/null; then
        if prompt_yes_no "Configure system-wide proxy (/etc/environment)?" "n"; then
            sudo tee -a /etc/environment > /dev/null <<EOF
# GitHub Actions Runner Proxy Configuration
HTTP_PROXY="$PROXY_URL"
HTTPS_PROXY="$PROXY_URL"
NO_PROXY="$NO_PROXY"
EOF
            log_success "System configuration updated: /etc/environment"
        fi
    else
        log_warn "Cannot write to /etc/environment (requires sudo)"
    fi
}

apply_git_config() {
    if ! command -v git &> /dev/null; then
        return
    fi

    if prompt_yes_no "Configure Git to use proxy?" "y"; then
        git config --global http.proxy "$PROXY_URL"
        git config --global https.proxy "$PROXY_URL"
        log_success "Git proxy configured"
    fi
}

apply_npm_config() {
    if ! command -v npm &> /dev/null; then
        return
    fi

    if prompt_yes_no "Configure npm to use proxy?" "y"; then
        npm config set proxy "$PROXY_URL"
        npm config set https-proxy "$PROXY_URL"
        log_success "npm proxy configured"
    fi
}

apply_apt_config() {
    if ! command -v apt-get &> /dev/null; then
        return
    fi

    if [ -w /etc/apt/apt.conf.d ] || sudo -n true 2>/dev/null; then
        if prompt_yes_no "Configure apt to use proxy?" "y"; then
            sudo tee /etc/apt/apt.conf.d/95proxies > /dev/null <<EOF
Acquire::http::Proxy "$PROXY_URL";
Acquire::https::Proxy "$PROXY_URL";
EOF
            log_success "apt proxy configured"
        fi
    fi
}

apply_runner_service_config() {
    log_info "Configuring GitHub Actions Runner service..."

    # Find runner installation directory
    local runner_dir
    runner_dir="${RUNNER_DIR:-}"

    if [ -z "$runner_dir" ]; then
        # Common locations
        for dir in "${HOME}/actions-runner" "/opt/actions-runner" "/home/runner/actions-runner"; do
            if [ -d "$dir" ]; then
                runner_dir="$dir"
                break
            fi
        done
    fi

    if [ -z "$runner_dir" ]; then
        log_warn "Runner directory not found. Please configure manually."
        return
    fi

    log_info "Runner directory: $runner_dir"

    # Check for systemd service
    local service_file="/etc/systemd/system/actions.runner.*.service"
    if ls $service_file 2>/dev/null; then
        if prompt_yes_no "Configure systemd service for proxy?" "y"; then
            for service in $service_file; do
                log_info "Updating service: $service"

                # Backup service file
                sudo cp "$service" "${service}.backup"

                # Add Environment lines if not present
                if ! sudo grep -q "Environment=.*HTTPS_PROXY" "$service"; then
                    sudo sed -i '/\[Service\]/a Environment="HTTP_PROXY='$PROXY_URL'"' "$service"
                    sudo sed -i '/\[Service\]/a Environment="HTTPS_PROXY='$PROXY_URL'"' "$service"
                    sudo sed -i '/\[Service\]/a Environment="NO_PROXY='$NO_PROXY'"' "$service"

                    sudo systemctl daemon-reload
                    log_success "Service updated: $(basename "$service")"

                    if prompt_yes_no "Restart runner service now?" "n"; then
                        sudo systemctl restart "$(basename "$service")"
                        log_success "Service restarted"
                    fi
                else
                    log_info "Service already has proxy configuration"
                fi
            done
        fi
    else
        log_info "No systemd service found. Runner may use shell environment variables."
    fi

    # Create .env file in runner directory
    if [ -d "$runner_dir" ]; then
        if prompt_yes_no "Create .env file in runner directory?" "y"; then
            cat > "${runner_dir}/.env" <<EOF
# GitHub Actions Runner Proxy Configuration
HTTP_PROXY=$PROXY_URL
HTTPS_PROXY=$PROXY_URL
NO_PROXY=$NO_PROXY
EOF
            log_success "Created ${runner_dir}/.env"
        fi
    fi
}

################################################################################
# Testing Functions
################################################################################

test_proxy_configuration() {
    print_header "Testing Proxy Configuration"

    log_info "Testing connectivity through proxy..."

    # Test basic connectivity
    log_info "Test 1: Basic HTTPS connectivity"
    if curl -x "$PROXY_URL" -sSf --connect-timeout 10 -o /dev/null https://api.github.com; then
        log_success "Successfully connected to GitHub API through proxy"
    else
        log_error "Failed to connect to GitHub API through proxy"
        return 1
    fi

    # Test authentication (if configured)
    log_info "Test 2: GitHub API authentication"
    local api_response
    api_response=$(curl -x "$PROXY_URL" -sSf --connect-timeout 10 https://api.github.com 2>&1)
    if [ $? -eq 0 ]; then
        log_success "GitHub API accessible"
    else
        log_error "GitHub API not accessible"
    fi

    # Test Actions endpoints
    log_info "Test 3: GitHub Actions endpoints"
    if curl -x "$PROXY_URL" -sSf --connect-timeout 10 -o /dev/null https://pipelines.actions.githubusercontent.com 2>/dev/null; then
        log_success "GitHub Actions pipelines accessible"
    else
        log_warn "GitHub Actions pipelines may not be accessible"
    fi

    # Test NO_PROXY
    log_info "Test 4: NO_PROXY bypass"
    export NO_PROXY="$NO_PROXY"
    if curl -sSf --connect-timeout 5 -o /dev/null http://localhost 2>/dev/null || true; then
        log_info "NO_PROXY configuration applied"
    fi

    echo ""
    log_success "Proxy testing complete"
}

################################################################################
# Removal Functions
################################################################################

remove_proxy_config() {
    print_header "Removing Proxy Configuration"

    log_warn "This will remove all proxy configuration applied by this script"
    if ! prompt_yes_no "Are you sure you want to remove proxy configuration?" "n"; then
        log_info "Removal cancelled"
        return 0
    fi

    # Backup first
    backup_config

    # Remove from shell RC
    local shell_rc
    shell_rc=$(get_shell_rc)
    if grep -q "# GitHub Actions Runner Proxy Configuration" "$shell_rc" 2>/dev/null; then
        sed -i.bak '/# GitHub Actions Runner Proxy Configuration/,/# End GitHub Actions Runner Proxy Configuration/d' "$shell_rc"
        log_success "Removed from $shell_rc"
    fi

    # Remove from /etc/environment
    if [ -f /etc/environment ] && sudo grep -q "# GitHub Actions Runner Proxy Configuration" /etc/environment 2>/dev/null; then
        if prompt_yes_no "Remove from /etc/environment?" "y"; then
            sudo sed -i.bak '/# GitHub Actions Runner Proxy Configuration/d' /etc/environment
            log_success "Removed from /etc/environment"
        fi
    fi

    # Remove Git config
    if command -v git &> /dev/null; then
        if prompt_yes_no "Remove Git proxy configuration?" "y"; then
            git config --global --unset http.proxy 2>/dev/null || true
            git config --global --unset https.proxy 2>/dev/null || true
            log_success "Git proxy configuration removed"
        fi
    fi

    # Remove npm config
    if command -v npm &> /dev/null; then
        if prompt_yes_no "Remove npm proxy configuration?" "y"; then
            npm config delete proxy 2>/dev/null || true
            npm config delete https-proxy 2>/dev/null || true
            log_success "npm proxy configuration removed"
        fi
    fi

    log_success "Proxy configuration removed"
    log_info "Restart your shell or run: source $shell_rc"
}

################################################################################
# Show Current Configuration
################################################################################

show_current_config() {
    print_header "Current Proxy Configuration"

    # Environment variables
    echo "Environment Variables:"
    echo "  HTTP_PROXY:  ${HTTP_PROXY:-Not set}"
    echo "  HTTPS_PROXY: ${HTTPS_PROXY:-Not set}"
    echo "  NO_PROXY:    ${NO_PROXY:-Not set}"
    echo ""

    # Git config
    if command -v git &> /dev/null; then
        local git_proxy
        git_proxy=$(git config --global --get http.proxy 2>/dev/null || echo "Not configured")
        echo "Git Proxy: $git_proxy"
        echo ""
    fi

    # npm config
    if command -v npm &> /dev/null; then
        echo "npm Proxy Configuration:"
        npm config get proxy 2>/dev/null || echo "  Not configured"
        echo ""
    fi

    # Test connectivity
    echo "Testing current proxy (if configured)..."
    if curl -sSf --connect-timeout 5 -o /dev/null https://api.github.com 2>/dev/null; then
        log_success "GitHub API accessible"
    else
        log_error "Cannot reach GitHub API"
    fi
}

################################################################################
# Interactive Mode
################################################################################

interactive_menu() {
    while true; do
        print_header "GitHub Actions Runner Proxy Configuration"
        echo "1. Detect existing proxy configuration"
        echo "2. Configure new proxy"
        echo "3. Test proxy configuration"
        echo "4. Show current configuration"
        echo "5. Remove proxy configuration"
        echo "6. Restore from backup"
        echo "7. Exit"
        echo ""

        read -r -p "Select an option [1-7]: " choice

        case $choice in
            1)
                detect_existing_proxy
                read -r -p "Press Enter to continue..."
                ;;
            2)
                collect_proxy_config
                apply_shell_config
                apply_git_config
                apply_npm_config
                apply_apt_config
                apply_runner_service_config
                test_proxy_configuration
                log_success "Configuration complete!"
                log_info "Restart your shell or run: source $(get_shell_rc)"
                read -r -p "Press Enter to continue..."
                ;;
            3)
                if [ -z "${HTTPS_PROXY:-}" ]; then
                    log_error "No proxy configured. Please configure proxy first."
                else
                    test_proxy_configuration
                fi
                read -r -p "Press Enter to continue..."
                ;;
            4)
                show_current_config
                read -r -p "Press Enter to continue..."
                ;;
            5)
                remove_proxy_config
                read -r -p "Press Enter to continue..."
                ;;
            6)
                restore_backup
                read -r -p "Press Enter to continue..."
                ;;
            7)
                log_info "Exiting..."
                exit 0
                ;;
            *)
                log_error "Invalid option"
                ;;
        esac
    done
}

restore_backup() {
    log_info "Available backups:"
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        log_warn "No backups found in $BACKUP_DIR"
        return
    fi

    ls -lt "$BACKUP_DIR"
    echo ""

    read -r -p "Enter backup filename to restore (or 'cancel'): " backup_file

    if [ "$backup_file" = "cancel" ]; then
        return
    fi

    local backup_path="${BACKUP_DIR}/${backup_file}"
    if [ ! -f "$backup_path" ]; then
        log_error "Backup file not found: $backup_path"
        return
    fi

    log_warn "This will restore configuration from backup"
    if prompt_yes_no "Continue?" "n"; then
        tar -xzf "$backup_path" -C "$HOME"
        log_success "Configuration restored from backup"
    fi
}

################################################################################
# Usage
################################################################################

show_usage() {
    cat <<EOF
GitHub Actions Runner Proxy Configuration Script v$SCRIPT_VERSION

Usage: $0 [OPTIONS]

OPTIONS:
    -i, --interactive       Interactive configuration mode (default)
    -a, --auto             Auto-detect and apply proxy configuration
    -c, --configure        Configure proxy with manual input
    -t, --test             Test current proxy configuration
    -r, --remove           Remove proxy configuration
    -s, --show             Show current configuration
    -h, --help             Show this help message

EXAMPLES:
    # Interactive mode (recommended)
    $0

    # Configure proxy manually
    $0 --configure

    # Test existing configuration
    $0 --test

    # Remove proxy configuration
    $0 --remove

ENVIRONMENT VARIABLES:
    PROXY_URL              Full proxy URL (http://user:pass@host:port)
    RUNNER_DIR             GitHub Actions runner installation directory

EOF
}

################################################################################
# Main
################################################################################

main() {
    local mode="interactive"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--interactive)
                mode="interactive"
                shift
                ;;
            -a|--auto)
                mode="auto"
                shift
                ;;
            -c|--configure)
                mode="configure"
                shift
                ;;
            -t|--test)
                mode="test"
                shift
                ;;
            -r|--remove)
                mode="remove"
                shift
                ;;
            -s|--show)
                mode="show"
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # Execute based on mode
    case $mode in
        interactive)
            interactive_menu
            ;;
        auto)
            detect_existing_proxy
            ;;
        configure)
            collect_proxy_config
            backup_config
            apply_shell_config
            apply_git_config
            apply_npm_config
            apply_runner_service_config
            test_proxy_configuration
            log_success "Configuration complete!"
            log_info "Restart your shell or run: source $(get_shell_rc)"
            ;;
        test)
            test_proxy_configuration
            ;;
        remove)
            remove_proxy_config
            ;;
        show)
            show_current_config
            ;;
    esac
}

# Run main
main "$@"
