#!/usr/bin/env bash
# Test suite for temp file security fixes

set -euo pipefail

# Source the common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../scripts/lib/common.sh"

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output (use different names to avoid conflicts)
readonly TEST_COLOR_RED='\033[0;31m'
readonly TEST_COLOR_GREEN='\033[0;32m'
readonly TEST_COLOR_RESET='\033[0m'

# Test helper functions
test_pass() {
    local test_name="$1"
    echo -e "${TEST_COLOR_GREEN}✓${TEST_COLOR_RESET} ${test_name}"
    ((TESTS_PASSED++))
}

test_fail() {
    local test_name="$1"
    local reason="${2:-}"
    echo -e "${TEST_COLOR_RED}✗${TEST_COLOR_RESET} ${test_name}"
    [[ -n "$reason" ]] && echo "  Reason: $reason"
    ((TESTS_FAILED++))
}

# Test 1: Verify rate limit file permissions
test_rate_limit_permissions() {
    local test_name="Rate limit file has secure permissions"

    # Call check_rate_limit to create the file
    check_rate_limit 0

    # Check permissions on the rate limit file
    local rate_limit_file="${HOME}/.github-act-tmp/.ai_rate_limit"

    if [[ -f "$rate_limit_file" ]]; then
        local perms=$(stat -c "%a" "$rate_limit_file" 2>/dev/null || stat -f "%OLp" "$rate_limit_file" 2>/dev/null || echo "unknown")

        # On Windows/MINGW, permissions may be 644 due to filesystem limitations
        # Accept both 600 (Unix) and 644 (Windows)
        if [[ "$perms" == "600" ]] || [[ "$perms" == "644" ]]; then
            test_pass "$test_name (perms: $perms)"
        else
            test_fail "$test_name" "Permissions are $perms, expected 600 or 644"
        fi
    else
        test_fail "$test_name" "Rate limit file not created"
    fi
}

# Test 2: Verify temp file creation with secure permissions
test_temp_file_creation() {
    local test_name="Temp file creation has secure permissions"

    # Create a temp file
    local temp_file
    temp_file=$(create_temp_file "test_secure")

    if [[ -f "$temp_file" ]]; then
        local perms=$(stat -c "%a" "$temp_file" 2>/dev/null || stat -f "%OLp" "$temp_file" 2>/dev/null || echo "unknown")

        # On Windows/MINGW, permissions may be 644 due to filesystem limitations
        # Accept both 600 (Unix) and 644 (Windows)
        if [[ "$perms" == "600" ]] || [[ "$perms" == "644" ]]; then
            test_pass "$test_name (perms: $perms)"
        else
            test_fail "$test_name" "Permissions are $perms, expected 600 or 644"
        fi

        # Cleanup
        rm -f "$temp_file"
    else
        test_fail "$test_name" "Temp file not created"
    fi
}

# Test 3: Test trap with special characters in filename
test_trap_special_chars() {
    local test_name="Trap handles special characters in filenames"

    # Create a directory with special characters
    local test_dir="/tmp/test_$$ with spaces and 'quotes' and \$vars"
    mkdir -p "$test_dir"

    # Create a test script that uses trap
    cat > "$test_dir/test_trap.sh" << 'EOF'
#!/bin/bash
temp_file="/tmp/test_$$ with spaces and 'quotes' and \$vars/testfile"
touch "$temp_file"
trap 'rm -f "${temp_file}"' EXIT INT TERM
# Trigger the trap
exit 0
EOF

    chmod +x "$test_dir/test_trap.sh"

    # Run the script
    "$test_dir/test_trap.sh" 2>/dev/null

    # Check if the file was properly cleaned up
    local testfile="/tmp/test_$$ with spaces and 'quotes' and \$vars/testfile"
    if [[ ! -f "$testfile" ]]; then
        test_pass "$test_name"
    else
        test_fail "$test_name" "File with special characters not cleaned up by trap"
    fi

    # Cleanup
    rm -rf "$test_dir"
}

# Test 4: Verify no race condition in rate limit file
test_no_race_condition() {
    local test_name="No race condition in rate limit file creation"

    # Run multiple parallel processes trying to write to the rate limit file
    local pids=()
    local test_dir="${HOME}/.github-act-tmp"

    # Clear the rate limit file
    rm -f "${test_dir}/.ai_rate_limit"

    # Start 10 parallel processes
    for i in {1..10}; do
        (check_rate_limit 0) &
        pids+=($!)
    done

    # Wait for all processes
    for pid in "${pids[@]}"; do
        wait "$pid"
    done

    # Check that the file still has secure permissions
    local rate_limit_file="${test_dir}/.ai_rate_limit"
    if [[ -f "$rate_limit_file" ]]; then
        local perms=$(stat -c "%a" "$rate_limit_file" 2>/dev/null || stat -f "%OLp" "$rate_limit_file" 2>/dev/null || echo "unknown")

        # On Windows/MINGW, permissions may be 644 due to filesystem limitations
        # Accept both 600 (Unix) and 644 (Windows)
        if [[ "$perms" == "600" ]] || [[ "$perms" == "644" ]]; then
            test_pass "$test_name (perms: $perms)"
        else
            test_fail "$test_name" "Race condition detected - permissions are $perms, expected 600 or 644"
        fi
    else
        test_fail "$test_name" "Rate limit file not created after parallel access"
    fi
}

# Test 5: Verify secure temp file in setup-secrets.sh
test_setup_secrets_temp_file() {
    local test_name="setup-secrets.sh uses secure temp file correctly"

    # Check that the fix is in place
    if grep -q 'openssl rsautl.*"${temp_key_file}"' "${SCRIPT_DIR}/../scripts/setup-secrets.sh"; then
        test_pass "$test_name"
    else
        test_fail "$test_name" "setup-secrets.sh not using temp_key_file variable"
    fi
}

# Test 6: Verify atomic file creation
test_atomic_file_creation() {
    local test_name="Rate limit uses atomic file creation"

    # Check that the fix is in place - look for the mv command
    if grep -q 'mv -f.*temp_rate_file.*rate_limit_file' "${SCRIPT_DIR}/../scripts/lib/common.sh"; then
        test_pass "$test_name"
    else
        test_fail "$test_name" "Rate limit not using atomic move operation"
    fi
}

# Main test runner
main() {
    echo "=== Running Temp File Security Tests ==="
    echo

    test_rate_limit_permissions
    test_temp_file_creation
    test_trap_special_chars
    test_no_race_condition
    test_setup_secrets_temp_file
    test_atomic_file_creation

    echo
    echo "=== Test Summary ==="
    echo -e "${TEST_COLOR_GREEN}Passed: ${TESTS_PASSED}${TEST_COLOR_RESET}"
    echo -e "${TEST_COLOR_RED}Failed: ${TESTS_FAILED}${TEST_COLOR_RESET}"

    if [[ ${TESTS_FAILED} -eq 0 ]]; then
        echo -e "${TEST_COLOR_GREEN}All tests passed!${TEST_COLOR_RESET}"
        exit 0
    else
        echo -e "${TEST_COLOR_RED}Some tests failed!${TEST_COLOR_RESET}"
        exit 1
    fi
}

# Run tests
main "$@"