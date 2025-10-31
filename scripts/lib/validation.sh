#!/bin/bash
#
# Input Validation Library for GitHub Actions Security
# Provides comprehensive validation functions to prevent injection attacks
# including command injection, path traversal, SSRF, and other vulnerabilities
#
# Security Design Principles:
# - Whitelist approach: only allow known-good patterns
# - Fail fast: return error on any suspicious input
# - Log all validation failures for audit
# - No use of eval or dynamic command construction
# - Clear error messages for debugging
#

set -euo pipefail

# Source common functions for logging
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh" 2>/dev/null || {
    # Fallback logging if common.sh not available
    log_info() { echo "[INFO] $*" >&2; }
    log_error() { echo "[ERROR] $*" >&2; }
    log_warning() { echo "[WARNING] $*" >&2; }
}

# ==============================================================================
# VALIDATION FUNCTIONS
# ==============================================================================

# Validate issue number (GitHub issue/PR number)
# Must be positive integer, reasonable range (1-999999)
# Returns: 0 on success, 1 on failure
validate_issue_number() {
    local input="${1:-}"
    local context="${2:-issue number}"

    if [[ -z "$input" ]]; then
        log_error "Validation failed: ${context} is empty"
        return 1
    fi

    # Check if input contains only digits
    if ! [[ "$input" =~ ^[0-9]+$ ]]; then
        log_error "Validation failed: ${context} contains non-digit characters: '$input'"
        return 1
    fi

    # Check if it's a positive integer (not starting with 0 unless it's just "0")
    if [[ "$input" =~ ^0[0-9]+$ ]]; then
        log_error "Validation failed: ${context} has leading zeros: '$input'"
        return 1
    fi

    # Check reasonable range (1-999999)
    if ((input < 1 || input > 999999)); then
        log_error "Validation failed: ${context} out of range (1-999999): '$input'"
        return 1
    fi

    return 0
}

# Validate file path to prevent path traversal attacks
# Blocks: .., absolute paths (unless allowed), special characters
# Returns: 0 on success, 1 on failure
validate_file_path() {
    local input="${1:-}"
    local allow_absolute="${2:-false}"
    local context="${3:-file path}"

    if [[ -z "$input" ]]; then
        log_error "Validation failed: ${context} is empty"
        return 1
    fi

    # Check for path traversal attempts
    if [[ "$input" == *".."* ]]; then
        log_error "Validation failed: ${context} contains path traversal (..): '$input'"
        return 1
    fi

    if [[ "$allow_absolute" != "true" ]] && [[ "$input" =~ ^/ ]]; then
        log_error "Validation failed: ${context} is absolute path (not allowed): '$input'"
        return 1
    fi

    # Check for Windows absolute paths if not allowed
    if [[ "$allow_absolute" != "true" ]] && [[ "$input" =~ ^[A-Za-z]: ]]; then
        log_error "Validation failed: ${context} is Windows absolute path (not allowed): '$input'"
        return 1
    fi

    # Check for dangerous characters that could lead to command injection
    # Allow: alphanumeric, /, -, _, ., space (for legitimate file names)
    # Using grep for more portable regex
    if ! echo "$input" | grep -qE '^[A-Za-z0-9/_. -]+$'; then
        log_error "Validation failed: ${context} contains invalid characters: '$input'"
        return 1
    fi

    # Check for multiple consecutive slashes (could indicate manipulation)
    if [[ "$input" == *//* ]]; then
        log_error "Validation failed: ${context} contains multiple consecutive slashes: '$input'"
        return 1
    fi

    return 0
}

# Validate GitHub token format
# Supports: ghp_ (personal), gho_ (OAuth), ghs_ (server), github_pat_ (fine-grained)
# Returns: 0 on success, 1 on failure
validate_github_token() {
    local input="${1:-}"
    local context="${2:-GitHub token}"

    if [[ -z "$input" ]]; then
        log_error "Validation failed: ${context} is empty"
        return 1
    fi

    # Check for valid GitHub token prefixes and format
    # ghp_ = GitHub Personal Access Token (classic)
    # gho_ = GitHub OAuth Access Token
    # ghs_ = GitHub Server-to-Server Token
    # github_pat_ = Fine-grained Personal Access Token
    if ! [[ "$input" =~ ^(ghp_[A-Za-z0-9]{36}|gho_[A-Za-z0-9]{36}|ghs_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9]{22}_[A-Za-z0-9]{59})$ ]]; then
        log_error "Validation failed: ${context} has invalid format. Expected ghp_*, gho_*, ghs_*, or github_pat_*"
        return 1
    fi

    return 0
}

# Validate URL to prevent SSRF attacks
# Only allows HTTPS URLs to trusted domains
# Returns: 0 on success, 1 on failure
validate_url() {
    local input="${1:-}"
    local allowed_domains="${2:-github.com,api.github.com}"
    local context="${3:-URL}"

    if [[ -z "$input" ]]; then
        log_error "Validation failed: ${context} is empty"
        return 1
    fi

    # Must start with https://
    if ! [[ "$input" =~ ^https:// ]]; then
        log_error "Validation failed: ${context} must use HTTPS: '$input'"
        return 1
    fi

    # Extract domain from URL
    local domain
    domain=$(echo "$input" | sed -E 's|^https://([^/]+).*|\1|')

    # Check if domain is in allowed list
    local allowed_found=false
    IFS=',' read -ra ALLOWED_ARRAY <<< "$allowed_domains"
    for allowed in "${ALLOWED_ARRAY[@]}"; do
        if [[ "$domain" == "$allowed" ]] || [[ "$domain" == *".$allowed" ]]; then
            allowed_found=true
            break
        fi
    done

    if [[ "$allowed_found" != "true" ]]; then
        log_error "Validation failed: ${context} domain not allowed: '$domain' (allowed: $allowed_domains)"
        return 1
    fi

    # Check for URL encoding attacks (double encoding, etc.)
    if [[ "$input" == *"%25"* ]] || [[ "$input" == *"%2e"* ]] || [[ "$input" == *"%2f"* ]]; then
        log_error "Validation failed: ${context} contains suspicious URL encoding: '$input'"
        return 1
    fi

    # Check for localhost/internal IPs (SSRF prevention)
    if [[ "$domain" =~ ^(localhost|127\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.) ]]; then
        log_error "Validation failed: ${context} points to internal network: '$domain'"
        return 1
    fi

    return 0
}

# Validate Git branch name
# Allows: alphanumeric, -, _, /, . (Git-safe characters)
# Returns: 0 on success, 1 on failure
validate_branch_name() {
    local input="${1:-}"
    local context="${2:-branch name}"

    if [[ -z "$input" ]]; then
        log_error "Validation failed: ${context} is empty"
        return 1
    fi

    # Check length (Git has a limit of 255 characters for ref names)
    if [[ ${#input} -gt 255 ]]; then
        log_error "Validation failed: ${context} exceeds 255 characters: '${input:0:50}...'"
        return 1
    fi

    # Check for valid Git branch name characters
    # Allows: alphanumeric, -, _, /, .
    if ! [[ "$input" =~ ^[A-Za-z0-9/_.-]+$ ]]; then
        log_error "Validation failed: ${context} contains invalid characters: '$input'"
        return 1
    fi

    # Check Git-specific rules
    # Cannot start with . or -
    if [[ "$input" =~ ^\. ]] || [[ "$input" =~ ^- ]]; then
        log_error "Validation failed: ${context} cannot start with . or -: '$input'"
        return 1
    fi

    # Cannot end with .lock
    if [[ "$input" == *.lock ]]; then
        log_error "Validation failed: ${context} cannot end with .lock: '$input'"
        return 1
    fi

    # Cannot contain ..
    if [[ "$input" == *..* ]]; then
        log_error "Validation failed: ${context} cannot contain ..: '$input'"
        return 1
    fi

    # Cannot contain @{
    if [[ "$input" == *@{* ]]; then
        log_error "Validation failed: ${context} cannot contain @{: '$input'"
        return 1
    fi

    # Cannot contain consecutive slashes
    if [[ "$input" == *//* ]]; then
        log_error "Validation failed: ${context} cannot contain consecutive slashes: '$input'"
        return 1
    fi

    return 0
}

# Validate Git commit hash (short or full SHA)
# Must be 7-40 hexadecimal characters
# Returns: 0 on success, 1 on failure
validate_commit_hash() {
    local input="${1:-}"
    local context="${2:-commit hash}"

    if [[ -z "$input" ]]; then
        log_error "Validation failed: ${context} is empty"
        return 1
    fi

    # Check if it's a valid hex string of 7-40 characters
    if ! [[ "$input" =~ ^[a-fA-F0-9]{7,40}$ ]]; then
        log_error "Validation failed: ${context} must be 7-40 hex characters: '$input'"
        return 1
    fi

    return 0
}

# Validate label (GitHub label, Docker label, etc.)
# Allows: alphanumeric, -, _, ., :, / and space (limited special chars)
# Returns: 0 on success, 1 on failure
validate_label() {
    local input="${1:-}"
    local context="${2:-label}"

    if [[ -z "$input" ]]; then
        log_error "Validation failed: ${context} is empty"
        return 1
    fi

    # Check length (reasonable limit for labels)
    if [[ ${#input} -gt 100 ]]; then
        log_error "Validation failed: ${context} exceeds 100 characters: '${input:0:50}...'"
        return 1
    fi

    # Allow: alphanumeric, -, _, ., :, /, space
    # This covers most label formats (GitHub labels, Docker labels, K8s labels)
    # Using grep for more portable regex
    if ! echo "$input" | grep -qE '^[A-Za-z0-9/:. _-]+$'; then
        log_error "Validation failed: ${context} contains invalid characters: '$input'"
        return 1
    fi

    return 0
}

# Sanitize input for safe shell usage
# Removes/escapes dangerous characters that could lead to command injection
# Returns: sanitized string (always succeeds but may return empty string)
sanitize_input() {
    local input="${1:-}"
    local context="${2:-input}"

    # If input is empty, return empty
    if [[ -z "$input" ]]; then
        echo ""
        return 0
    fi

    # Remove null bytes
    input="${input//$'\0'/}"

    # Remove or escape dangerous shell metacharacters
    # This is a defensive approach - remove anything that could be dangerous
    # Keeps: alphanumeric, space, -, _, ., /, :
    local sanitized
    sanitized=$(echo "$input" | tr -cd '[:alnum:] ._/:-')

    # Log if sanitization changed the input
    if [[ "$sanitized" != "$input" ]]; then
        log_warning "Input sanitized for ${context}: original length=${#input}, sanitized length=${#sanitized}"
    fi

    echo "$sanitized"
}

# ==============================================================================
# COMPOSITE VALIDATION FUNCTIONS
# ==============================================================================

# Validate environment variable name
# Must follow POSIX rules: [A-Z_][A-Z0-9_]*
# Returns: 0 on success, 1 on failure
validate_env_var_name() {
    local input="${1:-}"
    local context="${2:-environment variable name}"

    if [[ -z "$input" ]]; then
        log_error "Validation failed: ${context} is empty"
        return 1
    fi

    # Check POSIX environment variable naming rules
    if ! [[ "$input" =~ ^[A-Z_][A-Z0-9_]*$ ]]; then
        log_error "Validation failed: ${context} must match [A-Z_][A-Z0-9_]*: '$input'"
        return 1
    fi

    return 0
}

# Validate JSON string (basic check for JSON injection)
# Returns: 0 on success, 1 on failure
validate_json_string() {
    local input="${1:-}"
    local context="${2:-JSON string}"

    if [[ -z "$input" ]]; then
        log_error "Validation failed: ${context} is empty"
        return 1
    fi

    # Check for unescaped quotes that could break JSON
    if [[ "$input" == *\"* ]] && ! [[ "$input" == *\\\"* ]]; then
        # Contains unescaped quotes
        local test_json="{\"test\": \"$input\"}"
        if ! echo "$test_json" | python3 -m json.tool >/dev/null 2>&1; then
            log_error "Validation failed: ${context} contains unescaped quotes or invalid JSON characters"
            return 1
        fi
    fi

    return 0
}

# Validate Docker image name
# Format: [registry/]name[:tag] or name[@digest]
# Returns: 0 on success, 1 on failure
validate_docker_image() {
    local input="${1:-}"
    local context="${2:-Docker image}"

    if [[ -z "$input" ]]; then
        log_error "Validation failed: ${context} is empty"
        return 1
    fi

    # Basic Docker image name validation
    # Allows: lowercase letters, digits, -, _, ., /, :, @
    if ! echo "$input" | grep -qE "^[a-z0-9/_.:@-]+$"; then
        log_error "Validation failed: ${context} contains invalid characters: '$input'"
        return 1
    fi

    # Cannot start with - or _
    if echo "$input" | grep -qE "^[_-]"; then
        log_error "Validation failed: ${context} cannot start with - or _: '$input'"
        return 1
    fi

    return 0
}

# Validate workflow/action name (GitHub Actions)
# Returns: 0 on success, 1 on failure
validate_workflow_name() {
    local input="${1:-}"
    local context="${2:-workflow name}"

    if [[ -z "$input" ]]; then
        log_error "Validation failed: ${context} is empty"
        return 1
    fi

    # GitHub workflow names: alphanumeric, -, _, space, ., /
    # Using grep for more portable regex
    if ! echo "$input" | grep -qE '^[A-Za-z0-9/_. -]+$'; then
        log_error "Validation failed: ${context} contains invalid characters: '$input'"
        return 1
    fi

    # Check reasonable length
    if [[ ${#input} -gt 255 ]]; then
        log_error "Validation failed: ${context} exceeds 255 characters"
        return 1
    fi

    return 0
}

# ==============================================================================
# TESTING SUPPORT FUNCTIONS
# ==============================================================================

# Run validation test and report result
# Usage: run_validation_test "function_name" "input" "expected_result" "description"
run_validation_test() {
    local func="$1"
    local input="$2"
    local expected="$3"
    local description="$4"

    if $func "$input" 2>/dev/null; then
        actual=0
    else
        actual=1
    fi

    if [[ "$actual" -eq "$expected" ]]; then
        echo "✓ PASS: $description"
        return 0
    else
        echo "✗ FAIL: $description (expected: $expected, got: $actual)"
        return 1
    fi
}

# Export all validation functions
export -f validate_issue_number
export -f validate_file_path
export -f validate_github_token
export -f validate_url
export -f validate_branch_name
export -f validate_commit_hash
export -f validate_label
export -f sanitize_input
export -f validate_env_var_name
export -f validate_json_string
export -f validate_docker_image
export -f validate_workflow_name
export -f run_validation_test
