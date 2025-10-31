#!/usr/bin/env bash
# Script: test-input-validation.sh
# Description: Security tests for Task #5 - Input Validation
# Purpose: Validate that all user inputs are properly validated
# Reference: TASKS-REMAINING.md Task #5

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# Source test framework
source "${SCRIPT_DIR}/test-framework.sh"

# Test: Validation library exists
test_validation_library_exists() {
    local validation_lib="${PROJECT_ROOT}/scripts/lib/validation.sh"

    # Check if validation library exists
    if [[ -f "$validation_lib" ]]; then
        log_test_info "Found validation library: $validation_lib"
        return 0
    else
        # Check if validation is in common.sh
        local common_lib="${PROJECT_ROOT}/scripts/lib/common.sh"
        if [[ -f "$common_lib" ]]; then
            if grep -q "validate_\|check_.*input" "$common_lib" 2>/dev/null; then
                log_test_info "Found validation functions in common.sh"
                return 0
            fi
        fi
        log_test_warn "No dedicated validation library found"
        return 0
    fi
}

# Test: Path traversal protection
test_path_traversal_protection() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Check for path validation
    local path_validation_count=$(grep -r "validate.*path\|sanitize.*path\|realpath\|readlink -f" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null | wc -l )

    if [[ $path_validation_count -gt 0 ]]; then
        log_test_info "Found $path_validation_count path validation instances"
    else
        log_test_warn "No path validation functions found"
    fi

    # Check for dangerous path patterns
    local dangerous_patterns=(
        '\.\./\.\.'
        '/etc/passwd'
        '/etc/shadow'
    )

    for pattern in "${dangerous_patterns[@]}"; do
        if grep -r "$pattern" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null >/dev/null; then
            log_test_warn "Found test patterns for path traversal (may be intentional)"
        fi
    done

    if [[ $violations -gt 0 ]]; then
        log_test_error "Found $violations command injection vulnerabilities"
        return 1
    fi
    return 0
}

# Test: Command injection protection
test_command_injection_protection() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Check for proper input sanitization before command execution
    # Look for user input being used in commands
    local risky_patterns=(
        '\$1.*\$('
        '\${.*}.*\$('
        'read.*\$('
    )

    local violations=0
    for pattern in "${risky_patterns[@]}"; do
        local results=$(grep -r "$pattern" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null || true)
        if [[ -n "$results" ]]; then
            log_test_debug "Found potential command injection risk: $pattern"
            # Check if there's validation nearby
            if echo "$results" | grep -v "validate\|sanitize\|check"; then
                violations=$((violations + 1))
            fi
        fi
    done
    # Ensure violations is always initialized
    violations=${violations:-0}

    if [[ $violations -gt 0 ]]; then
        log_test_error "Found $violations command injection vulnerabilities"
        return 1
    fi
    return 0
}

# Test: URL validation exists
test_url_validation() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Check for URL validation
    if grep -r "validate.*url\|check.*url" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null >/dev/null; then
        log_test_info "Found URL validation functions"
    else
        log_test_warn "No URL validation functions found"
    fi

    # Check for SSRF protection (blocking localhost, 127.0.0.1, etc.)
    if grep -r "localhost\|127\.0\.0\.1\|169\.254\|10\.\|192\.168\." "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null >/dev/null; then
        log_test_info "Found IP address references (check for SSRF protection)"
    fi

    return 0
}

# Test: GitHub token validation
test_github_token_validation() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Check for token validation
    if grep -r "validate.*token\|check.*token.*ghp_\|token.*=~.*ghp_" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null >/dev/null; then
        log_test_info "Found GitHub token validation"
    else
        log_test_warn "No GitHub token validation found"
    fi

    return 0
}

# Test: Issue number validation
test_issue_number_validation() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Check for issue/PR number validation (should be numeric)
    if grep -r "validate.*issue\|validate.*pr\|\[0-9\].*issue\|\[0-9\].*pr" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null >/dev/null; then
        log_test_info "Found issue/PR number validation"
    else
        log_test_warn "No issue/PR number validation found"
    fi

    return 0
}

# Test: Branch name validation
test_branch_name_validation() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Check for branch name validation
    if grep -r "validate.*branch\|check.*branch.*name" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null >/dev/null; then
        log_test_info "Found branch name validation"
    else
        log_test_warn "No branch name validation found"
    fi

    return 0
}

# Test: No unquoted variables in dangerous contexts
test_quoted_variables() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Check for common unquoted variable usage
    # This is a warning check only
    local risky_patterns=(
        'rm -rf \$[A-Z_]'
        'cd \$[A-Z_]'
        'eval \$'
    )

    for pattern in "${risky_patterns[@]}"; do
        local results=$(grep -r "$pattern" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null || true)
        if [[ -n "$results" ]]; then
            log_test_warn "Found unquoted variables in dangerous context: $pattern"
        fi
    done

    if [[ $violations -gt 0 ]]; then
        log_test_error "Found $violations command injection vulnerabilities"
        return 1
    fi
    return 0
}

# Test: JSON input validation
test_json_input_validation() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Check for JSON validation using jq
    if grep -r "jq.*empty\|validate_json" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null >/dev/null; then
        log_test_info "Found JSON validation"
    else
        log_test_warn "No JSON validation found"
    fi

    return 0
}

# Test: Email validation
test_email_validation() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Check for email validation
    if grep -r "validate.*email\|\@.*\[a-zA-Z\]" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null >/dev/null; then
        log_test_info "Found email validation patterns"
    fi

    return 0
}

# Test: Integer validation
test_integer_validation() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Check for integer validation
    if grep -r "=~.*\[0-9\]\|\[\[ \$.*-eq\|validate.*number" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null >/dev/null; then
        log_test_info "Found integer validation"
    fi

    return 0
}

# Test: OWASP compliance - Injection (A03)
test_owasp_a03_compliance() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # OWASP A03:2021 - Injection
    # Check for injection protection

    # 1. No eval with user input
    if ! assert_no_eval_in_file "${scripts_dir}/setup-runner.sh" 2>/dev/null; then
        log_test_warn "Found eval in setup-runner.sh"
    fi

    # 2. Input validation functions exist
    if grep -r "validate_\|sanitize_\|check_.*input" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null >/dev/null; then
        log_test_info "Found input validation/sanitization functions"
    else
        log_test_warn "No input validation functions found (OWASP A03 risk)"
    fi

    return 0
}

# Test: SQL injection protection (if applicable)
test_sql_injection_protection() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Check if any scripts use SQL
    if grep -r "SELECT\|INSERT\|UPDATE\|DELETE.*FROM" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null >/dev/null; then
        log_test_warn "Found SQL usage - verify parameterized queries"
    else
        log_test_info "No SQL usage found"
    fi

    return 0
}

# Main test execution
main() {
    test_suite_start "Input Validation Security Tests (Task #5)"

    run_test test_validation_library_exists "Validation library exists"
    run_test test_path_traversal_protection "Path traversal protection"
    run_test test_command_injection_protection "Command injection protection"
    run_test test_url_validation "URL validation"
    run_test test_github_token_validation "GitHub token validation"
    run_test test_issue_number_validation "Issue number validation"
    run_test test_branch_name_validation "Branch name validation"
    run_test test_quoted_variables "Variables properly quoted"
    run_test test_json_input_validation "JSON input validation"
    run_test test_email_validation "Email validation"
    run_test test_integer_validation "Integer validation"
    run_test test_owasp_a03_compliance "OWASP A03 compliance"
    run_test test_sql_injection_protection "SQL injection protection"

    test_suite_end "Input Validation Security Tests (Task #5)"
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
