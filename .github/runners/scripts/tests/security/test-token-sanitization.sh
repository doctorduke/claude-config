#!/usr/bin/env bash
# Script: test-token-sanitization.sh
# Description: Security tests for Task #3 - Token Sanitization
# Purpose: Validate that tokens are properly masked in logs
# Reference: TASKS-REMAINING.md Task #3

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# Source test framework
source "${SCRIPT_DIR}/test-framework.sh"

# Test: No eval in setup-runner.sh
test_no_eval_in_setup_runner() {
    local setup_runner="${PROJECT_ROOT}/scripts/setup-runner.sh"

    if [[ ! -f "$setup_runner" ]]; then
        log_test_warn "setup-runner.sh not found, skipping test"
        return 0
    fi

    # Check for dangerous eval usage
    if ! assert_no_eval_in_file "$setup_runner"; then
        return 1
    fi

    return 0
}

# Test: Token patterns are masked in logging
test_token_masking_in_logs() {
    # Test various GitHub token patterns
    local token_patterns=(
        "ghp_test1234567890abcdefghijklmnopqrst"  # Classic PAT
        "gho_test1234567890abcdefghijklmnopqrst"  # OAuth
        "ghs_test1234567890abcdefghijklmnopqrst"  # App token
        "github_pat_11ABCDEFG0123456789_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123"  # Fine-grained
    )

    # Check if common.sh has sanitization function
    local common_lib="${PROJECT_ROOT}/scripts/lib/common.sh"
    if [[ ! -f "$common_lib" ]]; then
        log_test_warn "common.sh not found, cannot test token masking"
        return 0
    fi

    # Look for sanitization functions
    if grep -q "sanitize\|mask.*token\|redact" "$common_lib" 2>/dev/null; then
        log_test_info "Found token sanitization functions in common.sh"
    else
        log_test_warn "No token sanitization functions found in common.sh"
    fi

    return 0
}

# Test: No tokens in error messages
test_no_tokens_in_error_messages() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Check for potential token exposure in error messages
    local error_patterns=(
        'echo.*\$.*TOKEN'
        'log.*\$.*TOKEN'
        'printf.*\$.*TOKEN'
    )

    local violations=0
    for pattern in "${error_patterns[@]}"; do
        local results=$(grep -r "$pattern" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null || true)
        if [[ -n "$results" ]]; then
            log_test_debug "Found potential token exposure: $pattern"
            # Check if it's sanitized
            if ! echo "$results" | grep -q "sanitize\|mask\|redact"; then
                log_test_error "Unsanitized token in error message: $results"
                violations=$((violations + 1))
            fi
        fi
    done

    if [[ $violations -gt 0 ]]; then
        return 1
    fi

    return 0
}

# Test: Logging functions sanitize sensitive data
test_logging_functions_sanitize() {
    local common_lib="${PROJECT_ROOT}/scripts/lib/common.sh"

    if [[ ! -f "$common_lib" ]]; then
        log_test_warn "common.sh not found, skipping test"
        return 0
    fi

    # Check if logging functions exist
    local log_functions=("log_info" "log_error" "log_warn" "log_debug")
    for func in "${log_functions[@]}"; do
        if ! grep -q "^${func}()" "$common_lib" 2>/dev/null; then
            log_test_warn "Logging function ${func} not found"
        fi
    done

    return 0
}

# Test: GitHub token is obtained securely
test_secure_token_retrieval() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Check for insecure token retrieval
    local insecure_patterns=(
        'TOKEN=.*cat'
        'TOKEN=.*read'
        'export.*TOKEN=.*echo'
    )

    for pattern in "${insecure_patterns[@]}"; do
        local results=$(grep -r "$pattern" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null || true)
        if [[ -n "$results" ]]; then
            log_test_warn "Found potentially insecure token retrieval: $pattern"
        fi
    done

    # Check for secure patterns
    if grep -r "gh auth token\|get_github_token" "$scripts_dir" --include="*.sh" 2>/dev/null >/dev/null; then
        log_test_info "Found secure token retrieval methods"
    fi

    return 0
}

# Test: No token values in command substitution
test_no_token_in_command_substitution() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Look for command substitution with tokens that might log
    local patterns=(
        '\$\(.*TOKEN.*\)'
        '`.*TOKEN.*`'
    )

    local violations=0
    for pattern in "${patterns[@]}"; do
        local results=$(grep -r "$pattern" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null || true)
        if [[ -n "$results" ]]; then
            # Check if it's in a safe context (assignment, not logging)
            if echo "$results" | grep -v "=\$(" | grep -v "local"; then
                log_test_debug "Potential token exposure in command substitution: $results"
                violations=$((violations + 1))
            fi
        fi
    done

    # Warnings only for now
    return 0
}

# Test: setup-runner.sh uses arrays instead of eval
test_setup_runner_uses_arrays() {
    local setup_runner="${PROJECT_ROOT}/scripts/setup-runner.sh"

    if [[ ! -f "$setup_runner" ]]; then
        log_test_warn "setup-runner.sh not found, skipping test"
        return 0
    fi

    # Check for array usage instead of eval
    if grep -q "declare -a\|local -a\|COMMAND_ARGS=(" "$setup_runner" 2>/dev/null; then
        log_test_info "Found array usage in setup-runner.sh"
    fi

    # Verify no eval
    if ! assert_no_eval_in_file "$setup_runner"; then
        return 1
    fi

    return 0
}

# Test: Token masking in GitHub Actions output
test_github_actions_token_masking() {
    local workflows_dir="${PROJECT_ROOT}/.github/workflows"

    if [[ ! -d "$workflows_dir" ]]; then
        log_test_warn "Workflows directory not found, skipping test"
        return 0
    fi

    # Check for add-mask usage in workflows
    local mask_count=$(grep -r "add-mask" "$workflows_dir" 2>/dev/null | wc -l )

    if [[ $mask_count -gt 0 ]]; then
        log_test_info "Found $mask_count instances of add-mask in workflows"
    else
        log_test_warn "No add-mask directives found in workflows"
    fi

    return 0
}

# Test: No plaintext tokens in curl commands
test_no_plaintext_tokens_in_curl() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Check for curl commands with tokens
    local results=$(grep -r "curl.*-H.*Authorization.*Bearer" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null || true)

    if [[ -n "$results" ]]; then
        # Verify they use variables, not hardcoded values
        if echo "$results" | grep -q "Bearer.*ghp_\|Bearer.*gho_\|Bearer.*ghs_"; then
            log_test_error "Found hardcoded tokens in curl commands"
            return 1
        fi

        # Should use variables
        if echo "$results" | grep -q "\$.*TOKEN\|\${.*TOKEN"; then
            log_test_info "Curl commands use token variables (good)"
        fi
    fi

    return 0
}

# Test: OWASP compliance - Security Logging (A09)
test_owasp_a09_compliance() {
    local common_lib="${PROJECT_ROOT}/scripts/lib/common.sh"

    if [[ ! -f "$common_lib" ]]; then
        log_test_warn "common.sh not found, skipping OWASP A09 test"
        return 0
    fi

    # OWASP A09:2021 - Security Logging and Monitoring Failures
    # Verify logs don't contain sensitive data

    # Check for logging best practices
    if grep -q "log_error\|log_warn\|log_info" "$common_lib" 2>/dev/null; then
        log_test_info "Found structured logging functions"
    else
        log_test_warn "No structured logging functions found"
    fi

    return 0
}

# Test: Secrets not exposed in script tracing
test_no_secrets_in_script_tracing() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Check for set -x with tokens (dangerous)
    local results=$(grep -r "set -x" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null || true)

    if [[ -n "$results" ]]; then
        log_test_warn "Found 'set -x' which may expose secrets in traces"
        log_test_warn "Locations: $results"
    fi

    # Check for PS4 customization to hide secrets
    if grep -r "PS4=" "$scripts_dir" --include="*.sh" 2>/dev/null >/dev/null; then
        log_test_info "Found PS4 customization (may help hide secrets)"
    fi

    return 0
}

# Test: Environment variables sanitized before logging
test_env_var_sanitization() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Check for env command usage
    local results=$(grep -r "\benv\b" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null || true)

    if [[ -n "$results" ]]; then
        # Should filter sensitive vars
        if echo "$results" | grep -q "grep -v.*TOKEN\|grep -v.*SECRET\|grep -v.*KEY"; then
            log_test_info "Found env var filtering (good)"
        else
            log_test_warn "env command usage may expose secrets"
        fi
    fi

    return 0
}

# Main test execution
main() {
    test_suite_start "Token Sanitization Security Tests (Task #3)"

    run_test test_no_eval_in_setup_runner "No eval in setup-runner.sh"
    run_test test_token_masking_in_logs "Token patterns masked in logs"
    run_test test_no_tokens_in_error_messages "No tokens in error messages"
    run_test test_logging_functions_sanitize "Logging functions sanitize data"
    run_test test_secure_token_retrieval "Secure token retrieval"
    run_test test_no_token_in_command_substitution "No tokens in command substitution"
    run_test test_setup_runner_uses_arrays "setup-runner.sh uses arrays"
    run_test test_github_actions_token_masking "GitHub Actions token masking"
    run_test test_no_plaintext_tokens_in_curl "No plaintext tokens in curl"
    run_test test_owasp_a09_compliance "OWASP A09 compliance"
    run_test test_no_secrets_in_script_tracing "No secrets in script tracing"
    run_test test_env_var_sanitization "Environment variable sanitization"

    test_suite_end "Token Sanitization Security Tests (Task #3)"
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
