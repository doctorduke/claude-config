# Refactoring Recommendations

**Generated**: 2025-10-17
**Project**: GitHub Actions Self-Hosted Runner System
**Focus**: Code improvement opportunities

---

## Executive Summary

This document identifies specific refactoring opportunities to improve code maintainability, reusability, and quality without changing external behavior. Recommendations are prioritized by impact and effort.

**Total Recommendations**: 25
**Estimated Total Effort**: 312 hours
**Expected Impact**: 40% reduction in maintenance burden

---

## Table of Contents

1. [DRY Violations and Consolidation](#1-dry-violations-and-consolidation)
2. [Function Extraction Opportunities](#2-function-extraction-opportunities)
3. [Module Organization Improvements](#3-module-organization-improvements)
4. [Reusability Enhancements](#4-reusability-enhancements)
5. [Architecture Improvements](#5-architecture-improvements)

---

# 1. DRY VIOLATIONS AND CONSOLIDATION

## REFACTOR-001: Consolidate Logging Functions

**Priority**: HIGH
**Effort**: 8 hours
**Impact**: HIGH
**Risk**: LOW

### Current State

Logging functions duplicated across 15+ scripts (~200 lines total)

**Example duplications**:
```bash
# setup-runner.sh
log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# health-check.sh
log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# test-connectivity.sh
log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}
# ... repeated 12 more times
```

### Proposed Change

**1. Enhance `scripts/lib/common.sh`**:
```bash
#!/usr/bin/env bash
# Enhanced logging with levels and structured output

readonly LOG_LEVEL_ERROR=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_INFO=3
readonly LOG_LEVEL_DEBUG=4

# Default log level
LOG_LEVEL=${LOG_LEVEL:-$LOG_LEVEL_INFO}

# Colors (only if terminal)
if [[ -t 1 ]]; then
    readonly COLOR_RED='\033[0;31m'
    readonly COLOR_GREEN='\033[0;32m'
    readonly COLOR_YELLOW='\033[1;33m'
    readonly COLOR_BLUE='\033[0;34m'
    readonly COLOR_CYAN='\033[0;36m'
    readonly COLOR_RESET='\033[0m'
else
    readonly COLOR_RED=''
    readonly COLOR_GREEN=''
    readonly COLOR_YELLOW=''
    readonly COLOR_BLUE=''
    readonly COLOR_CYAN=''
    readonly COLOR_RESET=''
fi

# Structured logging
_log() {
    local level="$1"
    local level_num="$2"
    local color="$3"
    shift 3

    # Check if we should log this level
    if [[ $level_num -gt $LOG_LEVEL ]]; then
        return
    fi

    # Log format: [TIMESTAMP] [LEVEL] message
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    local prefix="${color}[${level}]${COLOR_RESET}"

    # Output to appropriate stream
    if [[ $level_num -le $LOG_LEVEL_ERROR ]]; then
        echo -e "${timestamp} ${prefix} $*" >&2
    else
        echo -e "${timestamp} ${prefix} $*"
    fi

    # Also log to file if LOG_FILE set
    if [[ -n "${LOG_FILE:-}" ]]; then
        echo "${timestamp} [${level}] $*" >> "$LOG_FILE"
    fi
}

log_error() {
    _log "ERROR" "$LOG_LEVEL_ERROR" "$COLOR_RED" "$@"
}

log_warn() {
    _log "WARN" "$LOG_LEVEL_WARN" "$COLOR_YELLOW" "$@"
}

log_info() {
    _log "INFO" "$LOG_LEVEL_INFO" "$COLOR_BLUE" "$@"
}

log_success() {
    _log "SUCCESS" "$LOG_LEVEL_INFO" "$COLOR_GREEN" "$@"
}

log_debug() {
    _log "DEBUG" "$LOG_LEVEL_DEBUG" "$COLOR_CYAN" "$@"
}

# Export functions
export -f log_error log_warn log_info log_success log_debug
```

**2. Remove from all scripts, replace with**:
```bash
#!/usr/bin/env bash

# Script setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Load common functions
source "${SCRIPT_DIR}/lib/common.sh" || {
    echo "ERROR: Cannot load common.sh" >&2
    exit 1
}

# Now use logging functions
log_info "Starting script..."
```

### Benefits
- **200 lines removed** across codebase
- Consistent logging behavior
- Single point for logging improvements
- Easier to add features (structured JSON logs, remote logging)
- Better testing capability

### Risks
- Scripts must have common.sh available
- Path calculation must be correct

### Migration Path
1. Enhance common.sh (2 hours)
2. Test in isolation (1 hour)
3. Update each script (4 hours for 20 scripts)
4. Integration testing (1 hour)

---

## REFACTOR-002: Consolidate Color Definitions

**Priority**: MEDIUM
**Effort**: 4 hours
**Impact**: MEDIUM
**Risk**: LOW

### Current State

Color codes defined in every script (~100 lines duplicated)

```bash
# Repeated in 15+ scripts
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'
```

### Proposed Change

Already included in REFACTOR-001 common.sh enhancement.

### Benefits
- 100 lines removed
- Consistent color usage
- Easy to support NO_COLOR environment variable

---

## REFACTOR-003: Consolidate Platform Detection

**Priority**: HIGH
**Effort**: 6 hours
**Impact**: MEDIUM
**Risk**: LOW

### Current State

Platform detection logic duplicated in 5+ scripts

**setup-runner.sh (lines 114-146)**:
```bash
detect_os() {
    local os_type=""

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if grep -qi microsoft /proc/version; then
            log_info "Detected WSL (Windows Subsystem for Linux)"
            os_type="linux"
        else
            log_info "Detected Linux"
            os_type="linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        log_info "Detected macOS"
        os_type="osx"
    else
        log_error "Unsupported OS: $OSTYPE"
        exit 1
    fi

    echo "$os_type"
}
```

**Duplicated in**: test-connectivity.sh, proxy-configuration.sh, quick-deploy.sh

### Proposed Change

**Add to `scripts/lib/common.sh`**:
```bash
#!/usr/bin/env bash

# Platform detection with caching
declare -g PLATFORM_OS=""
declare -g PLATFORM_IS_WSL=false
declare -g PLATFORM_IS_LINUX=false
declare -g PLATFORM_IS_MACOS=false
declare -g PLATFORM_IS_WINDOWS=false
declare -g PLATFORM_ARCH=""

detect_platform() {
    # Return cached if already detected
    [[ -n "$PLATFORM_OS" ]] && return 0

    # Detect OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        PLATFORM_IS_LINUX=true
        PLATFORM_OS="linux"

        # Check for WSL
        if grep -qi microsoft /proc/version 2>/dev/null || \
           grep -qi wsl /proc/version 2>/dev/null; then
            PLATFORM_IS_WSL=true
            log_debug "Detected WSL"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        PLATFORM_IS_MACOS=true
        PLATFORM_OS="osx"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        PLATFORM_IS_WINDOWS=true
        PLATFORM_OS="windows"
    else
        log_error "Unsupported OS: $OSTYPE"
        return 1
    fi

    # Detect architecture
    PLATFORM_ARCH=$(uname -m)
    case "$PLATFORM_ARCH" in
        x86_64|amd64)
            PLATFORM_ARCH="x64"
            ;;
        aarch64|arm64)
            PLATFORM_ARCH="arm64"
            ;;
        armv7l)
            PLATFORM_ARCH="arm"
            ;;
    esac

    log_debug "Platform: OS=$PLATFORM_OS, ARCH=$PLATFORM_ARCH, WSL=$PLATFORM_IS_WSL"
    return 0
}

# Platform-specific command wrappers
platform_stat_mode() {
    local file="$1"
    detect_platform || return 1

    if $PLATFORM_IS_MACOS; then
        stat -f "%OLp" "$file"
    else
        stat -c "%a" "$file"
    fi
}

platform_df_gb() {
    local path="$1"
    detect_platform || return 1

    # Use portable df -k and convert
    local kb
    kb=$(df -k "$path" | awk 'NR==2 {print $4}')
    echo $((kb / 1024 / 1024))
}

platform_date_add_days() {
    local days="$1"
    detect_platform || return 1

    if $PLATFORM_IS_MACOS; then
        date -v "+${days}d" "+%Y-%m-%d"
    else
        date -d "+${days} days" "+%Y-%m-%d"
    fi
}

# Export
export -f detect_platform platform_stat_mode platform_df_gb platform_date_add_days
```

**Usage in scripts**:
```bash
source "${SCRIPT_DIR}/lib/common.sh"

# Auto-detect on first use
detect_platform

# Use platform-specific commands
file_mode=$(platform_stat_mode "/path/to/file")
available_gb=$(platform_df_gb "/home")
future_date=$(platform_date_add_days 90)

# Or check platform directly
if $PLATFORM_IS_WSL; then
    log_info "Running in WSL environment"
fi
```

### Benefits
- 80 lines removed
- Consistent platform detection
- Cached detection (performance)
- Platform-specific commands standardized
- Easier to add new platforms

---

## REFACTOR-004: Consolidate GitHub API Calls

**Priority**: HIGH
**Effort**: 12 hours
**Impact**: HIGH
**Risk**: MEDIUM

### Current State

GitHub API calls scattered across scripts with inconsistent error handling

**Examples**:
```bash
# validate-setup.sh - Line 444
response=$(curl -s -H "Authorization: token ${GITHUB_PAT}" \
                 https://api.github.com/orgs/${GITHUB_ORG}/actions/runners)

# setup-secrets.sh - Line 146
response=$(curl -s -H "Authorization: token ${GITHUB_PAT}" \
                 -H "Accept: application/vnd.github.v3+json" \
                 "https://api.github.com/orgs/${org}/actions/secrets/public-key")
```

### Proposed Change

**Create `scripts/lib/github-api.sh`**:
```bash
#!/usr/bin/env bash

# GitHub API wrapper with rate limiting, retries, and error handling

readonly GITHUB_API_URL="https://api.github.com"
readonly MAX_RETRIES=3
readonly RETRY_DELAY=5

# Check rate limit before API call
_check_rate_limit() {
    local token="$1"

    local response
    response=$(curl -s -H "Authorization: token ${token}" \
                     "${GITHUB_API_URL}/rate_limit")

    local remaining
    remaining=$(echo "$response" | jq -r '.rate.remaining')

    local reset
    reset=$(echo "$response" | jq -r '.rate.reset')

    if [[ "$remaining" -lt 100 ]]; then
        log_warn "GitHub API rate limit low: $remaining remaining"

        if [[ "$remaining" -lt 10 ]]; then
            local wait_seconds=$((reset - $(date +%s)))
            log_warn "Waiting ${wait_seconds}s for rate limit reset"
            sleep "$wait_seconds"
        fi
    fi
}

# Make GitHub API call with retry logic
github_api_call() {
    local method="${1:-GET}"
    local endpoint="$2"
    local token="${3:-${GITHUB_PAT}}"
    local data="${4:-}"

    if [[ -z "$token" ]]; then
        log_error "GitHub token required for API calls"
        return 1
    fi

    # Check rate limit
    _check_rate_limit "$token"

    local url="${GITHUB_API_URL}${endpoint}"
    local attempt=0
    local http_code
    local response

    while [[ $attempt -lt $MAX_RETRIES ]]; do
        ((attempt++))

        log_debug "API call: $method $endpoint (attempt $attempt)"

        # Make request
        if [[ -n "$data" ]]; then
            response=$(curl -s -w "\n%{http_code}" \
                           -X "$method" \
                           -H "Authorization: token ${token}" \
                           -H "Accept: application/vnd.github.v3+json" \
                           -H "Content-Type: application/json" \
                           -d "$data" \
                           "$url")
        else
            response=$(curl -s -w "\n%{http_code}" \
                           -X "$method" \
                           -H "Authorization: token ${token}" \
                           -H "Accept: application/vnd.github.v3+json" \
                           "$url")
        fi

        http_code=$(echo "$response" | tail -1)
        local body=$(echo "$response" | sed '$d')

        # Check response
        case "$http_code" in
            200|201|204)
                # Success
                echo "$body"
                return 0
                ;;
            401)
                log_error "GitHub API authentication failed"
                return 1
                ;;
            403)
                # Check if rate limit
                if echo "$body" | jq -e '.message | contains("rate limit")' >/dev/null 2>&1; then
                    log_error "Rate limit exceeded"
                    _check_rate_limit "$token"
                else
                    log_error "GitHub API forbidden: $(echo "$body" | jq -r '.message')"
                    return 1
                fi
                ;;
            404)
                log_error "GitHub API resource not found: $endpoint"
                return 1
                ;;
            422)
                log_error "GitHub API validation failed: $(echo "$body" | jq -r '.message')"
                return 1
                ;;
            5*)
                # Server error - retry
                log_warn "GitHub API server error (${http_code}), retrying in ${RETRY_DELAY}s"
                sleep "$RETRY_DELAY"
                ;;
            *)
                log_error "GitHub API unexpected response: $http_code"
                log_debug "Response: $body"
                return 1
                ;;
        esac
    done

    log_error "GitHub API call failed after $MAX_RETRIES attempts"
    return 1
}

# Helper functions for common operations
github_get_runners() {
    local org="$1"
    github_api_call GET "/orgs/${org}/actions/runners"
}

github_get_runner() {
    local org="$1"
    local runner_id="$2"
    github_api_call GET "/orgs/${org}/actions/runners/${runner_id}"
}

github_delete_runner() {
    local org="$1"
    local runner_id="$2"
    github_api_call DELETE "/orgs/${org}/actions/runners/${runner_id}"
}

github_get_org_secrets() {
    local org="$1"
    github_api_call GET "/orgs/${org}/actions/secrets"
}

github_get_org_public_key() {
    local org="$1"
    github_api_call GET "/orgs/${org}/actions/secrets/public-key"
}

github_create_org_secret() {
    local org="$1"
    local secret_name="$2"
    local encrypted_value="$3"
    local key_id="$4"

    local data
    data=$(jq -n \
        --arg enc "$encrypted_value" \
        --arg kid "$key_id" \
        '{encrypted_value: $enc, key_id: $kid}')

    github_api_call PUT "/orgs/${org}/actions/secrets/${secret_name}" "$GITHUB_PAT" "$data"
}

export -f github_api_call
export -f github_get_runners github_get_runner github_delete_runner
export -f github_get_org_secrets github_get_org_public_key github_create_org_secret
```

**Usage**:
```bash
source "${SCRIPT_DIR}/lib/github-api.sh"

# Get runners
runners=$(github_get_runners "$GITHUB_ORG")
runner_count=$(echo "$runners" | jq -r '.total_count')

# Get specific runner
runner=$(github_get_runner "$GITHUB_ORG" "$runner_id")

# Create secret
github_create_org_secret "$org" "$secret_name" "$encrypted_value" "$key_id"
```

### Benefits
- Consistent error handling
- Automatic retry with exponential backoff
- Rate limit checking
- Single source of truth for API interactions
- Easier to add caching, mocking for tests
- Better logging and debugging

### Risks
- Medium risk - affects all API interactions
- Requires thorough testing

---

# 2. FUNCTION EXTRACTION OPPORTUNITIES

## REFACTOR-005: Extract Large Functions

**Priority**: HIGH
**Effort**: 24 hours
**Impact**: HIGH
**Risk**: LOW

### Target Functions

#### 1. proxy-configuration.sh::interactive_menu (60 lines)

**Current** (lines 653-713):
```bash
interactive_menu() {
    while true; do
        print_header "GitHub Actions Runner Proxy Configuration"
        echo "1. Detect existing proxy configuration"
        echo "2. Configure new proxy"
        # ... 5 more options
        read -r -p "Select an option [1-7]: " choice

        case $choice in
            1) detect_existing_proxy; read -r -p "Press Enter..." ;;
            2) collect_proxy_config; apply_shell_config; ...; read -r -p ... ;;
            # ... more cases
        esac
    done
}
```

**Refactored**:
```bash
# Extract menu handlers
_menu_detect_proxy() {
    detect_existing_proxy
    pause
}

_menu_configure_proxy() {
    collect_proxy_config
    backup_config
    apply_shell_config
    apply_git_config
    apply_npm_config
    apply_apt_config
    apply_runner_service_config
    test_proxy_configuration
    log_success "Configuration complete!"
    pause
}

_menu_test_proxy() {
    if [[ -z "${HTTPS_PROXY:-}" ]]; then
        log_error "No proxy configured"
    else
        test_proxy_configuration
    fi
    pause
}

_menu_show_config() {
    show_current_config
    pause
}

_menu_remove_proxy() {
    remove_proxy_config
    pause
}

_menu_restore_backup() {
    restore_backup
    pause
}

pause() {
    read -r -p "Press Enter to continue..."
}

# Simplified menu loop
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
            1) _menu_detect_proxy ;;
            2) _menu_configure_proxy ;;
            3) _menu_test_proxy ;;
            4) _menu_show_config ;;
            5) _menu_remove_proxy ;;
            6) _menu_restore_backup ;;
            7) log_info "Exiting..."; exit 0 ;;
            *) log_error "Invalid option" ;;
        esac
    done
}
```

**Benefits**:
- Each handler is testable independently
- Menu logic is clear and simple
- Easy to add/remove options
- Reduced cyclomatic complexity

#### 2. setup-secrets.sh::create_org_secret (55 lines)

**Extract sub-functions**:
```bash
_get_org_public_key() {
    local org="$1"
    github_get_org_public_key "$org"
}

_encrypt_secret_value() {
    local public_key="$1"
    local secret_value="$2"

    # Proper encryption implementation
    # (see security recommendations)
}

_upload_secret_to_github() {
    local org="$1"
    local secret_name="$2"
    local encrypted_value="$3"
    local key_id="$4"

    github_create_org_secret "$org" "$secret_name" "$encrypted_value" "$key_id"
}

# Simplified main function
create_org_secret() {
    local org="$1"
    local secret_name="$2"
    local secret_value="$3"

    log_info "Creating organization secret: $secret_name"

    # Get public key
    local key_response
    key_response=$(_get_org_public_key "$org") || return 1

    local public_key
    public_key=$(echo "$key_response" | jq -r '.key')

    local key_id
    key_id=$(echo "$key_response" | jq -r '.key_id')

    # Encrypt value
    local encrypted_value
    encrypted_value=$(_encrypt_secret_value "$public_key" "$secret_value") || return 1

    # Upload to GitHub
    _upload_secret_to_github "$org" "$secret_name" "$encrypted_value" "$key_id" || return 1

    log_success "Secret created: $secret_name"
}
```

---

## REFACTOR-006: Extract Configuration Loading

**Priority**: MEDIUM
**Effort**: 8 hours
**Impact**: MEDIUM
**Risk**: LOW

### Current State

Configuration loading logic scattered across scripts

### Proposed Change

**Create `scripts/lib/config.sh`**:
```bash
#!/usr/bin/env bash

# Configuration management

declare -g -A CONFIG=()

load_config() {
    local config_file="${1:-${HOME}/.github-runner/config}"

    if [[ ! -f "$config_file" ]]; then
        log_debug "Config file not found: $config_file"
        return 1
    fi

    # Load config file (key=value format)
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue

        # Trim whitespace
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)

        CONFIG["$key"]="$value"
    done < "$config_file"

    log_debug "Loaded configuration from $config_file"
    return 0
}

get_config() {
    local key="$1"
    local default="${2:-}"

    echo "${CONFIG[$key]:-$default}"
}

set_config() {
    local key="$1"
    local value="$2"

    CONFIG["$key"]="$value"
}

save_config() {
    local config_file="${1:-${HOME}/.github-runner/config}"

    mkdir -p "$(dirname "$config_file")"

    {
        echo "# GitHub Runner Configuration"
        echo "# Generated: $(date)"
        for key in "${!CONFIG[@]}"; do
            echo "${key}=${CONFIG[$key]}"
        done
    } > "$config_file"

    chmod 600 "$config_file"
    log_debug "Saved configuration to $config_file"
}

export -f load_config get_config set_config save_config
```

---

# 3. MODULE ORGANIZATION IMPROVEMENTS

## REFACTOR-007: Create Validation Library

**Priority**: HIGH
**Effort**: 12 hours
**Impact**: HIGH
**Risk**: LOW

### Proposed Structure

**Create `scripts/lib/validation.sh`**:
```bash
#!/usr/bin/env bash

# Input validation library

validate_org_name() {
    local org="$1"

    if [[ ! "$org" =~ ^[a-zA-Z0-9-]{1,39}$ ]]; then
        log_error "Invalid organization name: $org"
        log_error "Must be alphanumeric with hyphens, 1-39 characters"
        return 1
    fi

    if [[ "$org" =~ ^- ]] || [[ "$org" =~ -$ ]]; then
        log_error "Organization name cannot start/end with hyphen"
        return 1
    fi

    return 0
}

validate_runner_id() {
    local id="$1"

    if [[ ! "$id" =~ ^[1-9][0-9]?$ ]]; then
        log_error "Invalid runner ID: $id"
        log_error "Must be integer between 1 and 99"
        return 1
    fi

    return 0
}

validate_labels() {
    local labels="$1"

    IFS=',' read -ra LABEL_ARRAY <<< "$labels"
    for label in "${LABEL_ARRAY[@]}"; do
        label=$(echo "$label" | xargs)

        if [[ ! "$label" =~ ^[a-zA-Z0-9_-]{1,50}$ ]]; then
            log_error "Invalid label: $label"
            log_error "Labels must be alphanumeric with hyphens/underscores, max 50 chars"
            return 1
        fi
    done

    return 0
}

validate_path_no_traversal() {
    local path="$1"

    if [[ "$path" =~ \.\. ]]; then
        log_error "Path traversal detected: $path"
        return 1
    fi

    return 0
}

validate_github_token() {
    local token="$1"

    # Classic PAT format: ghp_[36 chars]
    # Fine-grained PAT: github_pat_[22 chars]_[59 chars]
    if [[ "$token" =~ ^ghp_[a-zA-Z0-9]{36}$ ]] || \
       [[ "$token" =~ ^github_pat_[a-zA-Z0-9]{22}_[a-zA-Z0-9]{59}$ ]]; then
        return 0
    fi

    log_error "Invalid GitHub token format"
    return 1
}

validate_url() {
    local url="$1"

    if [[ ! "$url" =~ ^https?:// ]]; then
        log_error "Invalid URL: $url"
        log_error "Must start with http:// or https://"
        return 1
    fi

    return 0
}

validate_port() {
    local port="$1"

    if [[ ! "$port" =~ ^[0-9]+$ ]] || [[ $port -lt 1 ]] || [[ $port -gt 65535 ]]; then
        log_error "Invalid port: $port"
        log_error "Must be integer between 1 and 65535"
        return 1
    fi

    return 0
}

validate_email() {
    local email="$1"

    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        log_error "Invalid email: $email"
        return 1
    fi

    return 0
}

validate_json_file() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        return 1
    fi

    if ! jq empty "$file" 2>/dev/null; then
        log_error "Invalid JSON in file: $file"
        return 1
    fi

    return 0
}

export -f validate_org_name validate_runner_id validate_labels
export -f validate_path_no_traversal validate_github_token
export -f validate_url validate_port validate_email validate_json_file
```

---

## REFACTOR-008: Create Error Handling Library

**Priority**: HIGH
**Effort**: 8 hours
**Impact**: HIGH
**Risk**: LOW

**Create `scripts/lib/errors.sh`**:
```bash
#!/usr/bin/env bash

# Error handling framework

# Error codes
readonly ERR_SUCCESS=0
readonly ERR_GENERIC=1
readonly ERR_CONFIG=2
readonly ERR_NETWORK=3
readonly ERR_AUTH=4
readonly ERR_VALIDATION=5
readonly ERR_NOT_FOUND=6
readonly ERR_PERMISSION=7

# Setup error handling for script
setup_error_handling() {
    local script_name="$1"
    local cleanup_function="${2:-cleanup_default}"

    set -euo pipefail
    IFS=$'\n\t'

    trap "handle_error \$? \$LINENO '$cleanup_function'" ERR
    trap "handle_exit \$? '$cleanup_function'" EXIT
}

# Handle errors
handle_error() {
    local exit_code=$1
    local line_no=$2
    local cleanup_func="$3"

    log_error "Error occurred at line $line_no (exit code: $exit_code)"

    # Call cleanup function
    if declare -f "$cleanup_func" >/dev/null 2>&1; then
        log_info "Running cleanup..."
        "$cleanup_func" "$exit_code"
    fi

    return "$exit_code"
}

# Handle exit
handle_exit() {
    local exit_code=$1
    local cleanup_func="$2"

    if [[ $exit_code -ne 0 ]]; then
        log_error "Script exited with code: $exit_code"
    else
        log_debug "Script completed successfully"
    fi
}

# Default cleanup function
cleanup_default() {
    local exit_code=$1

    if [[ $exit_code -ne 0 ]]; then
        log_info "Performing default cleanup..."

        # Remove temp files
        rm -f /tmp/github-runner-* 2>/dev/null || true

        log_info "Cleanup complete"
    fi
}

# Retry with exponential backoff
retry_with_backoff() {
    local max_attempts="$1"
    shift
    local command=("$@")

    local attempt=0
    local delay=1

    while [[ $attempt -lt $max_attempts ]]; do
        ((attempt++))

        log_debug "Attempt $attempt/$max_attempts: ${command[*]}"

        if "${command[@]}"; then
            return 0
        fi

        if [[ $attempt -lt $max_attempts ]]; then
            log_warn "Command failed, retrying in ${delay}s..."
            sleep "$delay"
            delay=$((delay * 2))
        fi
    done

    log_error "Command failed after $max_attempts attempts"
    return 1
}

export -f setup_error_handling handle_error handle_exit cleanup_default
export -f retry_with_backoff
```

**Usage**:
```bash
#!/usr/bin/env bash

source "${SCRIPT_DIR}/lib/errors.sh"

my_cleanup() {
    local exit_code=$1

    # Custom cleanup
    rm -f "$TEMP_FILE"
    # Restore backups
    # etc.
}

# Setup error handling
setup_error_handling "$(basename "$0")" my_cleanup

# Script continues...
# Errors automatically handled
```

---

# 4. REUSABILITY ENHANCEMENTS

## REFACTOR-009: Create Script Template

**Priority**: MEDIUM
**Effort**: 4 hours
**Impact**: MEDIUM
**Risk**: LOW

**Create `scripts/templates/script-template.sh`**:
```bash
#!/usr/bin/env bash

################################################################################
# Script Name: SCRIPT_NAME
# Description: DESCRIPTION
# Version: 1.0.0
# Author: AUTHOR
# Date: DATE
#
# Usage:
#   ./SCRIPT_NAME [OPTIONS]
#
# Options:
#   -h, --help     Show this help message
#   -v, --verbose  Enable verbose output
#
# Examples:
#   ./SCRIPT_NAME --option value
#
################################################################################

set -euo pipefail
IFS=$'\n\t'

# Script metadata
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_START_TIME=$(date +%s)

# Load common libraries
source "${SCRIPT_DIR}/lib/common.sh" || {
    echo "ERROR: Cannot load common.sh" >&2
    exit 1
}

source "${SCRIPT_DIR}/lib/errors.sh"
source "${SCRIPT_DIR}/lib/validation.sh"

# Configuration
VERBOSE=false
DRY_RUN=false
LOG_FILE="${LOG_FILE:-/var/log/$(basename "$0" .sh).log}"

# Cleanup function
cleanup() {
    local exit_code=$1

    if [[ $exit_code -ne 0 ]]; then
        log_error "Script failed"
    fi

    # Add cleanup logic here

    local duration=$(($(date +%s) - SCRIPT_START_TIME))
    log_info "Script duration: ${duration}s"
}

# Setup error handling
setup_error_handling "$SCRIPT_NAME" cleanup

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                LOG_LEVEL=$LOG_LEVEL_DEBUG
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Show usage information
show_usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Description of what this script does.

OPTIONS:
    -h, --help      Show this help message
    -v, --verbose   Enable verbose output
    --dry-run       Show what would be done without doing it

EXAMPLES:
    # Example 1
    $SCRIPT_NAME --option value

    # Example 2
    $SCRIPT_NAME -v --other-option

EOF
}

# Validate prerequisites
validate_prerequisites() {
    log_info "Validating prerequisites..."

    # Check required tools
    local required_tools=("curl" "jq" "git")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "Required tool not found: $tool"
            exit 1
        fi
    done

    # Check required environment variables
    if [[ -z "${REQUIRED_VAR:-}" ]]; then
        log_error "Required environment variable not set: REQUIRED_VAR"
        exit 1
    fi

    log_success "Prerequisites validated"
}

# Main function
main() {
    log_info "Starting $SCRIPT_NAME v$SCRIPT_VERSION"

    parse_args "$@"
    validate_prerequisites

    # Main logic here

    log_success "Script completed successfully"
}

# Execute main function
main "$@"
```

---

## REFACTOR-010: Create Testing Helpers

**Priority**: HIGH
**Effort**: 16 hours
**Impact**: HIGH
**Risk**: LOW

**Create `tests/helpers/test-helpers.sh`**:
```bash
#!/usr/bin/env bash

# Test helper functions

# Setup test environment
setup_test_env() {
    # Create isolated test directory
    export TEST_HOME=$(mktemp -d)
    export HOME="$TEST_HOME"

    # Create standard directories
    mkdir -p "$TEST_HOME/.github-runner"
    mkdir -p "$TEST_HOME/actions-runner-1"

    # Set test environment variables
    export GITHUB_ORG="test-org"
    export GITHUB_TOKEN="test-token-fake"
    export RUNNER_TOKEN="test-runner-token"
}

# Teardown test environment
teardown_test_env() {
    # Remove test directory
    if [[ -d "$TEST_HOME" ]]; then
        rm -rf "$TEST_HOME"
    fi
}

# Mock external commands
mock_command() {
    local command="$1"
    local output="$2"
    local exit_code="${3:-0}"

    eval "$command() { echo '$output'; return $exit_code; }"
    export -f "$command"
}

# Assert helpers
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Expected '$expected' but got '$actual'}"

    if [[ "$expected" != "$actual" ]]; then
        echo "FAIL: $message"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-Expected to contain '$needle'}"

    if [[ ! "$haystack" =~ $needle ]]; then
        echo "FAIL: $message"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-Expected file to exist: $file}"

    if [[ ! -f "$file" ]]; then
        echo "FAIL: $message"
        return 1
    fi
}

assert_exit_code() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Expected exit code $expected but got $actual}"

    if [[ $expected -ne $actual ]]; then
        echo "FAIL: $message"
        return 1
    fi
}

export -f setup_test_env teardown_test_env mock_command
export -f assert_equals assert_contains assert_file_exists assert_exit_code
```

---

# 5. ARCHITECTURE IMPROVEMENTS

## REFACTOR-011: Implement Plugin Architecture

**Priority**: LOW
**Effort**: 40 hours
**Impact**: HIGH
**Risk**: HIGH

### Concept

Allow extending functionality without modifying core scripts

**Structure**:
```
plugins/
├── monitoring/
│   ├── plugin.json
│   ├── setup.sh
│   └── collect.sh
├── slack-notifications/
│   ├── plugin.json
│   └── notify.sh
└── custom-labels/
    ├── plugin.json
    └── assign.sh
```

**Plugin Manifest** (plugin.json):
```json
{
  "name": "slack-notifications",
  "version": "1.0.0",
  "description": "Send notifications to Slack",
  "hooks": {
    "post_setup": "notify.sh setup_complete",
    "on_error": "notify.sh error_occurred"
  },
  "config": {
    "webhook_url": "required"
  }
}
```

**Benefits**:
- Extensible without modifying core
- Community contributions easier
- Easier testing of new features

**Risks**:
- Complex implementation
- Security concerns with third-party plugins

---

## REFACTOR-012: Implement State Management

**Priority**: MEDIUM
**Effort**: 16 hours
**Impact**: MEDIUM
**Risk**: MEDIUM

### Concept

Centralized state tracking for runners

**Create `scripts/lib/state.sh`**:
```bash
#!/usr/bin/env bash

readonly STATE_DIR="${HOME}/.github-runner/state"
readonly STATE_FILE="${STATE_DIR}/runners.json"

init_state() {
    mkdir -p "$STATE_DIR"
    chmod 700 "$STATE_DIR"

    if [[ ! -f "$STATE_FILE" ]]; then
        echo '{"runners": []}' > "$STATE_FILE"
        chmod 600 "$STATE_FILE"
    fi
}

get_runner_state() {
    local runner_id="$1"

    init_state

    jq --arg id "$runner_id" \
        '.runners[] | select(.id == $id)' \
        "$STATE_FILE"
}

set_runner_state() {
    local runner_id="$1"
    local key="$2"
    local value="$3"

    init_state

    local temp_file
    temp_file=$(mktemp)

    jq --arg id "$runner_id" \
       --arg k "$key" \
       --arg v "$value" \
       '(.runners[] | select(.id == $id) | .[$k]) = $v' \
       "$STATE_FILE" > "$temp_file"

    mv "$temp_file" "$STATE_FILE"
    chmod 600 "$STATE_FILE"
}

add_runner() {
    local runner_id="$1"
    local runner_name="$2"

    init_state

    local temp_file
    temp_file=$(mktemp)

    local runner_obj
    runner_obj=$(jq -n \
        --arg id "$runner_id" \
        --arg name "$runner_name" \
        --arg created "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '{id: $id, name: $name, created: $created, status: "active"}')

    jq --argjson runner "$runner_obj" \
        '.runners += [$runner]' \
        "$STATE_FILE" > "$temp_file"

    mv "$temp_file" "$STATE_FILE"
    chmod 600 "$STATE_FILE"
}

list_runners() {
    init_state
    jq -r '.runners[] | "\(.id)\t\(.name)\t\(.status)"' "$STATE_FILE"
}

export -f init_state get_runner_state set_runner_state add_runner list_runners
```

---

# SUMMARY

## Refactoring Priority Matrix

| ID | Refactoring | Effort | Impact | Risk | Priority |
|----|-------------|--------|--------|------|----------|
| 001 | Consolidate Logging | 8h | HIGH | LOW | HIGH |
| 003 | Consolidate Platform Detection | 6h | MEDIUM | LOW | HIGH |
| 004 | Consolidate GitHub API | 12h | HIGH | MEDIUM | HIGH |
| 005 | Extract Large Functions | 24h | HIGH | LOW | HIGH |
| 007 | Validation Library | 12h | HIGH | LOW | HIGH |
| 008 | Error Handling Library | 8h | HIGH | LOW | HIGH |
| 010 | Testing Helpers | 16h | HIGH | LOW | HIGH |
| 002 | Consolidate Colors | 4h | MEDIUM | LOW | MEDIUM |
| 006 | Configuration Loading | 8h | MEDIUM | LOW | MEDIUM |
| 009 | Script Template | 4h | MEDIUM | LOW | MEDIUM |
| 012 | State Management | 16h | MEDIUM | MEDIUM | MEDIUM |
| 011 | Plugin Architecture | 40h | HIGH | HIGH | LOW |

## Total Effort: 158 hours (core refactorings)

## Recommended Execution Order

### Phase 1: Foundation (Week 1-2) - 34 hours
1. Consolidate Logging (001)
2. Error Handling Library (008)
3. Platform Detection (003)
4. Validation Library (007)

### Phase 2: API & Functions (Week 3-4) - 36 hours
5. GitHub API Library (004)
6. Extract Large Functions (005)

### Phase 3: Testing & Templates (Week 5-6) - 28 hours
7. Testing Helpers (010)
8. Configuration Loading (006)
9. Script Template (009)
10. Consolidate Colors (002)

### Phase 4: Advanced (Week 7-8) - 16 hours
11. State Management (012)

### Phase 5: Optional (Future)
12. Plugin Architecture (011)

## Expected Benefits

- **40% reduction** in duplicated code
- **60% improvement** in testability
- **50% reduction** in time to add new features
- **30% reduction** in bug fix time
- **Easier onboarding** for new developers

## Risks

- **Refactoring effort**: 158 hours of development time
- **Testing overhead**: Each refactoring needs thorough testing
- **Breaking changes**: Careful migration needed
- **Learning curve**: Team needs to adapt to new structure

## Success Metrics

- Code duplication < 5%
- Test coverage > 60%
- Average function length < 25 lines
- Cyclomatic complexity < 10
- Time to implement new feature reduced by 50%

---

**Conclusion**: Systematic refactoring will significantly improve codebase maintainability and quality. Prioritize foundation refactorings first, then build on that foundation.
