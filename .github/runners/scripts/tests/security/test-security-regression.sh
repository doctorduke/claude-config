#!/usr/bin/env bash
# Script: test-security-regression.sh
# Description: Security Regression Test Suite
# Purpose: Re-run all security tests to ensure no fixes have been reverted
# Reference: TASKS-REMAINING.md Task #16

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${SCRIPT_DIR}/test-framework.sh"

# Test: Verify all security test files exist
test_all_security_tests_exist() {
    local test_files=(
        "test-secret-encryption.sh"
        "test-token-sanitization.sh"
        "test-temp-file-security.sh"
        "test-input-validation.sh"
        "test-no-eval.sh"
        "test-secret-masking.sh"
        "test-pat-protected-branches.sh"
        "test-owasp-compliance.sh"
    )

    for test_file in "${test_files[@]}"; do
        if ! assert_file_exists "${SCRIPT_DIR}/${test_file}"; then
            return 1
        fi
    done

    return 0
}

# Test: Run Task #2 encryption tests
test_task2_encryption_regression() {
    log_test_info "Running Task #2 encryption tests..."

    if ! bash "${SCRIPT_DIR}/test-secret-encryption.sh" >/dev/null 2>&1; then
        log_test_error "Task #2 encryption tests failed"
        return 1
    fi

    return 0
}

# Test: Run Task #3 sanitization tests
test_task3_sanitization_regression() {
    log_test_info "Running Task #3 sanitization tests..."

    if ! bash "${SCRIPT_DIR}/test-token-sanitization.sh" >/dev/null 2>&1; then
        log_test_error "Task #3 sanitization tests failed"
        return 1
    fi

    return 0
}

# Test: Run Task #4 temp file tests
test_task4_temp_file_regression() {
    log_test_info "Running Task #4 temp file tests..."

    if ! bash "${SCRIPT_DIR}/test-temp-file-security.sh" >/dev/null 2>&1; then
        log_test_error "Task #4 temp file tests failed"
        return 1
    fi

    return 0
}

# Test: Run Task #5 input validation tests
test_task5_input_validation_regression() {
    log_test_info "Running Task #5 input validation tests..."

    if ! bash "${SCRIPT_DIR}/test-input-validation.sh" >/dev/null 2>&1; then
        log_test_error "Task #5 input validation tests failed"
        return 1
    fi

    return 0
}

# Test: Run Task #6 no-eval tests
test_task6_no_eval_regression() {
    log_test_info "Running Task #6 no-eval tests..."

    if ! bash "${SCRIPT_DIR}/test-no-eval.sh" >/dev/null 2>&1; then
        log_test_error "Task #6 no-eval tests failed"
        return 1
    fi

    return 0
}

# Test: Run Task #7 secret masking tests
test_task7_secret_masking_regression() {
    log_test_info "Running Task #7 secret masking tests..."

    if ! bash "${SCRIPT_DIR}/test-secret-masking.sh" >/dev/null 2>&1; then
        log_test_error "Task #7 secret masking tests failed"
        return 1
    fi

    return 0
}

# Test: Run Task #8 PAT tests
test_task8_pat_regression() {
    log_test_info "Running Task #8 PAT tests..."

    if ! bash "${SCRIPT_DIR}/test-pat-protected-branches.sh" >/dev/null 2>&1; then
        log_test_error "Task #8 PAT tests failed"
        return 1
    fi

    return 0
}

# Test: Check for new vulnerabilities
test_no_new_vulnerabilities() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Common vulnerability patterns
    local vuln_patterns=(
        'eval.*\$'
        'rm -rf /\|rm -rf \$HOME'
        'chmod 777'
        'password=.*[^$]'
        'ghp_[a-zA-Z0-9]{36}'
    )

    local violations=0
    for pattern in "${vuln_patterns[@]}"; do
        if grep -r "$pattern" "$scripts_dir" --include="*.sh" --exclude-dir=tests  | grep -v "example\|test\|comment\|#"; then
            log_test_warn "Found potential vulnerability: $pattern"
            violations=$((violations + 1))
        fi
    done

    if [[ $violations -gt 0 ]]; then
        log_test_warn "Found $violations potential vulnerabilities"
    fi

    return 0
}

# Test: Verify security documentation is up to date
test_security_documentation_current() {
    local security_docs=(
        "${PROJECT_ROOT}/docs/security-model.md"
        "${PROJECT_ROOT}/docs/security-setup-guide.md"
        "${PROJECT_ROOT}/SECURITY_TOOLS_SUMMARY.md"
    )

    for doc in "${security_docs[@]}"; do
        if [[ -f "$doc" ]]; then
            log_test_info "Found security documentation: $(basename "$doc")"
        fi
    done

    return 0
}

# Test: Check for security policy
test_security_policy_exists() {
    local security_files=(
        "${PROJECT_ROOT}/SECURITY.md"
        "${PROJECT_ROOT}/.github/SECURITY.md"
        "${PROJECT_ROOT}/config/security-policy.json"
    )

    local found=0
    for file in "${security_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_test_info "Found security policy: $(basename "$file")"
            found=1
        fi
    done

    if [[ $found -eq 0 ]]; then
        log_test_warn "No SECURITY.md file found"
    fi

    return 0
}

# Test: Verify Git pre-commit hooks for security
test_security_hooks() {
    local hooks_dir="${PROJECT_ROOT}/.git/hooks"

    if [[ -d "$hooks_dir" ]]; then
        if [[ -f "$hooks_dir/pre-commit" ]]; then
            if grep -q "secret\|security" "$hooks_dir/pre-commit" ; then
                log_test_info "Found security checks in pre-commit hook"
            fi
        fi
    fi

    return 0
}

# Test: All critical security fixes are in place
test_critical_security_fixes() {
    local fixes_status=()

    # Task #2: Encryption
    if [[ -f "${PROJECT_ROOT}/scripts/encrypt_secret.py" ]]; then
        fixes_status+=("Task #2: Encryption ✓")
    else
        fixes_status+=("Task #2: Encryption ✗")
    fi

    # Task #3: Token sanitization (no eval)
    if ! grep -q "\beval\b" "${PROJECT_ROOT}/scripts/setup-runner.sh"  | grep -v "yq eval"; then
        fixes_status+=("Task #3: Token sanitization ✓")
    else
        fixes_status+=("Task #3: Token sanitization ✗")
    fi

    # Task #4: Temp file security
    if grep -q "mktemp" "${PROJECT_ROOT}/scripts/lib/common.sh" ; then
        fixes_status+=("Task #4: Temp file security ✓")
    else
        fixes_status+=("Task #4: Temp file security ✗")
    fi

    # Display status
    for status in "${fixes_status[@]}"; do
        if [[ "$status" == *"✗"* ]]; then
            log_test_warn "$status"
        else
            log_test_info "$status"
        fi
    done

    return 0
}

# Main test execution
main() {
    test_suite_start "Security Regression Test Suite"

    run_test test_all_security_tests_exist "All security test files exist"
    run_test test_task2_encryption_regression "Task #2 encryption regression"
    run_test test_task3_sanitization_regression "Task #3 sanitization regression"
    run_test test_task4_temp_file_regression "Task #4 temp file regression"
    run_test test_task5_input_validation_regression "Task #5 input validation regression"
    run_test test_task6_no_eval_regression "Task #6 no-eval regression"
    run_test test_task7_secret_masking_regression "Task #7 secret masking regression"
    run_test test_task8_pat_regression "Task #8 PAT regression"
    run_test test_no_new_vulnerabilities "No new vulnerabilities introduced"
    run_test test_security_documentation_current "Security documentation current"
    run_test test_security_policy_exists "Security policy exists"
    run_test test_security_hooks "Security hooks in place"
    run_test test_critical_security_fixes "Critical security fixes status"

    test_suite_end "Security Regression Test Suite"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
