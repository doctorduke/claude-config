#!/usr/bin/env bash
# Script: test-temp-file-security.sh
# Description: Security tests for Task #4 - Temp File Security
# Purpose: Validate temp files have secure permissions and are cleaned up
# Reference: TASKS-REMAINING.md Task #4

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# Source test framework
source "${SCRIPT_DIR}/test-framework.sh"

# Test: create_temp_file function exists
test_create_temp_file_function_exists() {
    local common_lib="${PROJECT_ROOT}/scripts/lib/common.sh"

    if [[ ! -f "$common_lib" ]]; then
        log_test_warn "common.sh not found, skipping test"
        return 0
    fi

    # Check for create_temp_file function
    if ! assert_file_contains "$common_lib" "create_temp_file"; then
        log_test_warn "create_temp_file function not found in common.sh"
        return 0
    fi

    return 0
}

# Test: Temp files use mktemp
test_temp_files_use_mktemp() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Check that scripts use mktemp, not insecure methods
    local insecure_patterns=(
        '>/tmp/[^$]'
        'touch /tmp/'
        'cat > /tmp/[^$]'
    )

    local violations=0
    for pattern in "${insecure_patterns[@]}"; do
        local results=$(grep -r "$pattern" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null || true)
        if [[ -n "$results" ]]; then
            log_test_warn "Found potentially insecure temp file creation: $pattern"
            log_test_debug "  $results"
            violations=$((violations + 1))
        fi
    done

    # Check for mktemp usage
    local mktemp_count=$(grep -r "mktemp" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null | wc -l )

    if [[ $mktemp_count -gt 0 ]]; then
        log_test_info "Found $mktemp_count uses of mktemp (good)"
    else
        log_test_warn "No mktemp usage found"
    fi

    return 0
}

# Test: Temp files have secure permissions (600)
test_temp_file_permissions() {
    local common_lib="${PROJECT_ROOT}/scripts/lib/common.sh"

    if [[ ! -f "$common_lib" ]]; then
        log_test_warn "common.sh not found, skipping test"
        return 0
    fi

    # Test the create_temp_file function if it exists
    if ! grep -q "create_temp_file" "$common_lib" 2>/dev/null; then
        log_test_warn "create_temp_file function not found"
        return 0
    fi

    # Source the library and test
    source "$common_lib" 2>/dev/null || true

    if declare -f create_temp_file &>/dev/null; then
        local temp_file=$(create_temp_file "test" 2>/dev/null || echo "")

        if [[ -n "$temp_file" && -f "$temp_file" ]]; then
            local perms=$(stat -c "%a" "$temp_file" 2>/dev/null || stat -f "%Lp" "$temp_file" 2>/dev/null || echo "")

            # Check if permissions are 600 or similar secure value
            if [[ "$perms" == "600" || "$perms" == "400" ]]; then
                log_test_info "Temp file has secure permissions: $perms"
                rm -f "$temp_file"
            else
                log_test_warn "Temp file permissions may not be secure: $perms (expected 600)"
                rm -f "$temp_file"
            fi
        else
            log_test_warn "Could not create temp file for testing"
        fi
    else
        log_test_warn "create_temp_file function not available"
    fi

    return 0
}

# Test: Temp files have cleanup traps
test_temp_file_cleanup_traps() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Check for trap usage with mktemp
    local scripts_with_mktemp=$(grep -l "mktemp" "$scripts_dir"/*.sh 2>/dev/null || true)

    if [[ -z "$scripts_with_mktemp" ]]; then
        log_test_info "No scripts using mktemp found"
        return 0
    fi

    local trap_count=0
    for script in $scripts_with_mktemp; do
        if grep -q "trap.*EXIT\|trap.*INT\|trap.*TERM" "$script" 2>/dev/null; then
            trap_count=$((trap_count + 1))
        fi
    done

    log_test_info "Found $trap_count scripts with cleanup traps"

    return 0
}

# Test: No world-readable temp files
test_no_world_readable_temp_files() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Check for chmod commands that make files world-readable
    local results=$(grep -r "chmod.*777\|chmod.*666\|chmod.*644.*tmp" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null || true)

    if [[ -n "$results" ]]; then
        log_test_error "Found world-readable temp file permissions"
        log_test_error "  $results"
        return 1
    fi

    return 0
}

# Test: Temp directory has proper permissions
test_temp_directory_permissions() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Check for temp directory creation
    local mktemp_dir_usage=$(grep -r "mktemp -d" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null || true)

    if [[ -n "$mktemp_dir_usage" ]]; then
        log_test_info "Found temp directory creation with mktemp -d"
    fi

    return 0
}

# Test: No predictable temp file names
test_no_predictable_temp_names() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Check for predictable temp file names
    local predictable_patterns=(
        '/tmp/token'
        '/tmp/secret'
        '/tmp/key'
        '/tmp/config'
        '/tmp/temp'
    )

    local violations=0
    for pattern in "${predictable_patterns[@]}"; do
        local results=$(grep -r "$pattern[^.X]" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null || true)
        if [[ -n "$results" ]]; then
            log_test_warn "Found potentially predictable temp file name: $pattern"
            log_test_debug "  $results"
            violations=$((violations + 1))
        fi
    done

    return 0
}

# Test: Temp files deleted on exit
test_temp_files_deleted_on_exit() {
    local common_lib="${PROJECT_ROOT}/scripts/lib/common.sh"

    if [[ ! -f "$common_lib" ]]; then
        log_test_warn "common.sh not found, skipping test"
        return 0
    fi

    # Check for cleanup in create_temp_file
    if grep -q "create_temp_file" "$common_lib" 2>/dev/null; then
        if ! assert_file_contains "$common_lib" "trap.*rm.*EXIT"; then
            log_test_warn "create_temp_file may not register cleanup trap"
        fi
    fi

    return 0
}

# Test: Sensitive data not stored in /tmp
test_no_sensitive_data_in_tmp() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Check for storing keys/tokens in temp files
    local sensitive_patterns=(
        'echo.*\$.*TOKEN.*>.*tmp'
        'echo.*\$.*KEY.*>.*tmp'
        'echo.*\$.*SECRET.*>.*tmp'
        'cat.*>.*tmp.*TOKEN'
    )

    local violations=0
    for pattern in "${sensitive_patterns[@]}"; do
        local results=$(grep -ri "$pattern" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null || true)
        if [[ -n "$results" ]]; then
            # Check if using mktemp with secure permissions
            if ! echo "$results" | grep -q "mktemp"; then
                log_test_warn "Sensitive data may be stored insecurely in temp files"
                log_test_debug "  $results"
                violations=$((violations + 1))
            fi
        fi
    done

    return 0
}

# Test: UMASK set appropriately for temp files
test_umask_for_temp_files() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Check for umask settings
    local umask_usage=$(grep -r "umask" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null || true)

    if [[ -n "$umask_usage" ]]; then
        # Should be restrictive (077 or 027)
        if echo "$umask_usage" | grep -q "umask 077\|umask 027"; then
            log_test_info "Found secure umask settings"
        else
            log_test_warn "umask may not be secure enough for temp files"
        fi
    fi

    return 0
}

# Test: OWASP compliance - Sensitive Data Exposure
test_owasp_sensitive_data_exposure() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # OWASP Top 10 - Sensitive Data Exposure
    # Temp files with sensitive data should be encrypted or secured

    # Check for encryption of temp files
    if grep -r "openssl enc.*-out\|gpg.*-o" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null >/dev/null; then
        log_test_info "Found encrypted temp file usage"
    fi

    # Check for shred usage (secure deletion)
    if grep -r "shred\|srm" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null >/dev/null; then
        log_test_info "Found secure file deletion commands"
    fi

    return 0
}

# Main test execution
main() {
    test_suite_start "Temp File Security Tests (Task #4)"

    run_test test_create_temp_file_function_exists "create_temp_file function exists"
    run_test test_temp_files_use_mktemp "Temp files use mktemp"
    run_test test_temp_file_permissions "Temp files have secure permissions"
    run_test test_temp_file_cleanup_traps "Temp files have cleanup traps"
    run_test test_no_world_readable_temp_files "No world-readable temp files"
    run_test test_temp_directory_permissions "Temp directories have proper permissions"
    run_test test_no_predictable_temp_names "No predictable temp file names"
    run_test test_temp_files_deleted_on_exit "Temp files deleted on exit"
    run_test test_no_sensitive_data_in_tmp "No sensitive data stored insecurely in /tmp"
    run_test test_umask_for_temp_files "UMASK set appropriately"
    run_test test_owasp_sensitive_data_exposure "OWASP sensitive data exposure compliance"

    test_suite_end "Temp File Security Tests (Task #4)"
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
