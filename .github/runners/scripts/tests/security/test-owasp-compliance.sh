#!/usr/bin/env bash
# Script: test-owasp-compliance.sh
# Description: OWASP Top 10 2021 Compliance Tests
# Purpose: Validate compliance with OWASP security standards
# Reference: https://owasp.org/Top10/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${SCRIPT_DIR}/test-framework.sh"

# A01:2021 - Broken Access Control
test_owasp_a01_broken_access_control() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Check for authentication/authorization
    if grep -r "gh auth status\|GITHUB_TOKEN\|check.*auth" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null >/dev/null; then
        log_test_info "Found authentication checks"
    else
        log_test_warn "No authentication checks found"
    fi

    # Check for permission validation
    if grep -r "permission\|authorize\|validate.*user" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null >/dev/null; then
        log_test_info "Found permission checks"
    fi

    return 0
}

# A02:2021 - Cryptographic Failures
test_owasp_a02_cryptographic_failures() {
    local encrypt_script="${PROJECT_ROOT}/scripts/encrypt_secret.py"

    # Verify strong encryption
    if [[ -f "$encrypt_script" ]]; then
        if ! assert_file_contains "$encrypt_script" "nacl"; then
            log_test_error "Should use libsodium (PyNaCl) for encryption"
            return 1
        fi
    fi

    # No weak crypto
    local weak_crypto=("MD5" "SHA1" "DES" "3DES" "RC4")
    for algo in "${weak_crypto[@]}"; do
        if grep -ri "$algo" "${PROJECT_ROOT}/scripts" --include="*.sh" --include="*.py" --exclude-dir=tests 2>/dev/null | grep -v "comment\|#"; then
            log_test_warn "Found weak cryptographic algorithm: $algo"
        fi
    done

    return 0
}

# A03:2021 - Injection
test_owasp_a03_injection() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Verify input validation exists
    if ! grep -r "validate_\|sanitize_\|check_.*input" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null >/dev/null; then
        log_test_warn "No input validation functions found (injection risk)"
    fi

    # No eval usage
    local eval_count=$(grep -r "\beval\b" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null | grep -v "yq eval" | grep -v "# Safe:" | wc -l )
    if [[ $eval_count -gt 0 ]]; then
        log_test_error "Found $eval_count dangerous eval statements"
        return 1
    fi

    # Proper quoting
    if grep -r 'rm -rf \$[A-Z_][A-Z_]*[^"]' "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null >/dev/null; then
        log_test_warn "Found potentially unquoted variables in dangerous commands"
    fi

    return 0
}

# A04:2021 - Insecure Design
test_owasp_a04_insecure_design() {
    local docs_dir="${PROJECT_ROOT}/docs"

    # Check for security documentation
    if [[ -d "$docs_dir" ]]; then
        if ls "$docs_dir"/*security* "$docs_dir"/*threat* 2>/dev/null >/dev/null; then
            log_test_info "Found security design documentation"
        else
            log_test_warn "No security design documentation found"
        fi
    fi

    # Check for rate limiting
    if grep -r "rate.*limit\|throttle\|backoff" "${PROJECT_ROOT}/scripts" --include="*.sh" --exclude-dir=tests 2>/dev/null >/dev/null; then
        log_test_info "Found rate limiting implementation"
    fi

    return 0
}

# A05:2021 - Security Misconfiguration
test_owasp_a05_security_misconfiguration() {
    local workflows_dir="${PROJECT_ROOT}/.github/workflows"

    # Check workflow permissions
    if [[ -d "$workflows_dir" ]]; then
        local workflows_with_perms=0
        local total_workflows=0

        for workflow in "$workflows_dir"/*.yml "$workflows_dir"/*.yaml; do
            if [[ -f "$workflow" ]]; then
                total_workflows=$((total_workflows + 1))
                if grep -q "permissions:" "$workflow" 2>/dev/null; then
                    workflows_with_perms=$((workflows_with_perms + 1))
                fi
            fi
        done

        if [[ $workflows_with_perms -gt 0 ]]; then
            log_test_info "Workflows with explicit permissions: $workflows_with_perms/$total_workflows"
        else
            log_test_warn "No workflows have explicit permissions set"
        fi
    fi

    # Check for default deny policies
    if grep -r "permissions:\s*{}" "$workflows_dir" 2>/dev/null >/dev/null; then
        log_test_info "Found default deny permission policies"
    fi

    return 0
}

# A06:2021 - Vulnerable and Outdated Components
test_owasp_a06_vulnerable_components() {
    local project_root="${PROJECT_ROOT}"

    # Check for dependency scanning
    if [[ -f "$project_root/.github/dependabot.yml" ]]; then
        log_test_info "Found Dependabot configuration"
    else
        log_test_warn "No Dependabot configuration found"
    fi

    # Check for security scanning workflows
    if ls "$project_root/.github/workflows"/*security* "$project_root/.github/workflows"/*scan* 2>/dev/null >/dev/null; then
        log_test_info "Found security scanning workflows"
    fi

    return 0
}

# A07:2021 - Identification and Authentication Failures
test_owasp_a07_auth_failures() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Check for authentication validation
    if grep -r "validate_gh_auth\|gh auth status" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null >/dev/null; then
        log_test_info "Found authentication validation"
    fi

    # No hardcoded credentials
    if grep -r "password.*=.*['\"].*['\"]" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null | grep -v "example\|test\|dummy"; then
        log_test_error "Found potential hardcoded passwords"
        return 1
    fi

    return 0
}

# A08:2021 - Software and Data Integrity Failures
test_owasp_a08_integrity_failures() {
    local workflows_dir="${PROJECT_ROOT}/.github/workflows"

    # Check for action version pinning
    if [[ -d "$workflows_dir" ]]; then
        if grep -r "uses:.*@v[0-9]" "$workflows_dir" 2>/dev/null >/dev/null; then
            log_test_warn "Found version tags (should use commit SHAs for security)"
        fi

        if grep -r "uses:.*@[a-f0-9]\{40\}" "$workflows_dir" 2>/dev/null >/dev/null; then
            log_test_info "Found commit SHA pinning (good)"
        fi
    fi

    # Check for checksum validation
    if grep -r "sha256sum\|shasum\|verify" "${PROJECT_ROOT}/scripts" --include="*.sh" --exclude-dir=tests 2>/dev/null >/dev/null; then
        log_test_info "Found checksum validation"
    fi

    return 0
}

# A09:2021 - Security Logging and Monitoring Failures
test_owasp_a09_logging_failures() {
    local common_lib="${PROJECT_ROOT}/scripts/lib/common.sh"

    # Verify logging framework exists
    if [[ -f "$common_lib" ]]; then
        if ! assert_file_contains "$common_lib" "log_info\|log_error\|log_warn"; then
            log_test_warn "No structured logging functions found"
        fi
    fi

    # Check for secret masking in logs
    if grep -r "sanitize.*log\|mask.*token\|redact" "${PROJECT_ROOT}/scripts" --include="*.sh" --exclude-dir=tests 2>/dev/null >/dev/null; then
        log_test_info "Found log sanitization functions"
    else
        log_test_warn "No log sanitization found"
    fi

    return 0
}

# A10:2021 - Server-Side Request Forgery (SSRF)
test_owasp_a10_ssrf() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Check for URL validation
    if grep -r "validate.*url\|check.*url" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null >/dev/null; then
        log_test_info "Found URL validation"
    else
        log_test_warn "No URL validation found (SSRF risk)"
    fi

    # Check for localhost/internal IP blocking
    if grep -r "127\.0\.0\.1\|localhost\|169\.254" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null | grep -i "block\|deny\|reject"; then
        log_test_info "Found internal IP blocking"
    fi

    return 0
}

# Additional: Check for common security best practices
test_security_best_practices() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Check for set -euo pipefail
    local scripts_without_safety=0
    for script in "$scripts_dir"/*.sh; do
        if [[ -f "$script" ]]; then
            if ! grep -q "set -euo pipefail\|set -eu" "$script" 2>/dev/null; then
                scripts_without_safety=$((scripts_without_safety + 1))
            fi
        fi
    done

    if [[ $scripts_without_safety -gt 0 ]]; then
        log_test_warn "$scripts_without_safety scripts without safety flags (set -euo pipefail)"
    else
        log_test_info "All scripts have safety flags"
    fi

    return 0
}

# Main test execution
main() {
    test_suite_start "OWASP Top 10 2021 Compliance Tests"

    run_test test_owasp_a01_broken_access_control "A01: Broken Access Control"
    run_test test_owasp_a02_cryptographic_failures "A02: Cryptographic Failures"
    run_test test_owasp_a03_injection "A03: Injection"
    run_test test_owasp_a04_insecure_design "A04: Insecure Design"
    run_test test_owasp_a05_security_misconfiguration "A05: Security Misconfiguration"
    run_test test_owasp_a06_vulnerable_components "A06: Vulnerable Components"
    run_test test_owasp_a07_auth_failures "A07: Authentication Failures"
    run_test test_owasp_a08_integrity_failures "A08: Integrity Failures"
    run_test test_owasp_a09_logging_failures "A09: Logging Failures"
    run_test test_owasp_a10_ssrf "A10: SSRF"
    run_test test_security_best_practices "Security Best Practices"

    test_suite_end "OWASP Top 10 2021 Compliance Tests"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
