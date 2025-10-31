#!/usr/bin/env bash
#
# test-secure-temp-files.sh - Security Test Suite for Temporary File Handling
#
# Description:
#   Tests that all temporary files created by scripts use secure permissions
#   (600), proper cleanup traps, and mktemp for secure random names.
#
# Usage:
#   ./test-secure-temp-files.sh
#
# Exit Codes:
#   0 - All tests passed
#   1 - One or more tests failed
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test results
declare -a FAILED_TESTS=()

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================================================
# Test Helper Functions
# ============================================================================

test_start() {
    local test_name="$1"
    ((TESTS_RUN++))
    echo -n "  Testing: ${test_name}... "
}

test_pass() {
    ((TESTS_PASSED++))
    echo -e "${GREEN}PASS${NC}"
}

test_fail() {
    local reason="$1"
    ((TESTS_FAILED++))
    FAILED_TESTS+=("$reason")
    echo -e "${RED}FAIL${NC} - $reason"
}

# ============================================================================
# Test Cases
# ============================================================================

test_common_create_temp_file() {
    test_start "create_temp_file has chmod 600"

    if ! grep -A3 'mktemp -t' "${PROJECT_ROOT}/scripts/lib/common.sh" | grep -q 'chmod 600'; then
        test_fail "create_temp_file doesn't set chmod 600"
        return 1
    fi

    if ! grep -q 'trap.*rm -f.*temp_file' "${PROJECT_ROOT}/scripts/lib/common.sh"; then
        test_fail "create_temp_file doesn't have cleanup trap"
        return 1
    fi

    test_pass
}

test_setup_secrets_encrypt() {
    test_start "encrypt_secret uses secure temp file"

    if ! grep -q 'temp_key_file=$(mktemp)' "${PROJECT_ROOT}/scripts/setup-secrets.sh"; then
        test_fail "encrypt_secret doesn't use mktemp"
        return 1
    fi

    if ! grep -q 'chmod 600 "${temp_key_file}"' "${PROJECT_ROOT}/scripts/setup-secrets.sh"; then
        test_fail "encrypt_secret doesn't set chmod 600"
        return 1
    fi

    if ! grep -q 'trap.*rm -f.*temp_key_file' "${PROJECT_ROOT}/scripts/setup-secrets.sh"; then
        test_fail "encrypt_secret doesn't have cleanup trap"
        return 1
    fi

    test_pass
}

test_check_secret_leaks_workflow_logs() {
    test_start "scan_workflow_logs uses secure temp file"

    if ! grep -q 'temp_log=$(mktemp' "${PROJECT_ROOT}/scripts/check-secret-leaks.sh"; then
        test_fail "scan_workflow_logs doesn't use mktemp"
        return 1
    fi

    if ! grep -q 'chmod 600 "${temp_log}"' "${PROJECT_ROOT}/scripts/check-secret-leaks.sh"; then
        test_fail "scan_workflow_logs doesn't set chmod 600"
        return 1
    fi

    if ! grep -q 'trap.*rm -f.*temp_log' "${PROJECT_ROOT}/scripts/check-secret-leaks.sh"; then
        test_fail "scan_workflow_logs doesn't have cleanup trap"
        return 1
    fi

    test_pass
}

test_common_call_ai_api() {
    test_start "call_ai_api uses secure temp file"

    if ! grep -q 'response_file=$(mktemp)' "${PROJECT_ROOT}/scripts/lib/common.sh"; then
        test_fail "call_ai_api doesn't use mktemp"
        return 1
    fi

    if ! grep -q 'chmod 600 "${response_file}"' "${PROJECT_ROOT}/scripts/lib/common.sh"; then
        test_fail "call_ai_api doesn't set chmod 600"
        return 1
    fi

    if ! grep -q 'trap.*rm -f.*response_file' "${PROJECT_ROOT}/scripts/lib/common.sh"; then
        test_fail "call_ai_api doesn't have cleanup trap"
        return 1
    fi

    test_pass
}

test_common_rate_limit() {
    test_start "check_rate_limit uses secure directory and file"

    if ! grep -q 'chmod 700.*secure_tmp_dir' "${PROJECT_ROOT}/scripts/lib/common.sh"; then
        test_fail "check_rate_limit doesn't secure directory"
        return 1
    fi

    if ! grep -q 'chmod 600.*rate_limit_file' "${PROJECT_ROOT}/scripts/lib/common.sh"; then
        test_fail "check_rate_limit doesn't set chmod 600"
        return 1
    fi

    test_pass
}

test_quick_deploy_log_file() {
    test_start "quick-deploy.sh uses secure log file"

    if ! grep -q 'LOG_FILE=$(mktemp' "${PROJECT_ROOT}/scripts/quick-deploy.sh"; then
        test_fail "quick-deploy.sh doesn't use mktemp for LOG_FILE"
        return 1
    fi

    if ! grep -q 'chmod 600 "${LOG_FILE}"' "${PROJECT_ROOT}/scripts/quick-deploy.sh"; then
        test_fail "quick-deploy.sh doesn't set chmod 600 on LOG_FILE"
        return 1
    fi

    test_pass
}

test_no_insecure_tmp_patterns() {
    test_start "No scripts use insecure /tmp/ hardcoded paths"

    # Find any remaining /tmp/ hardcoded paths (excluding comments)
    local insecure_count
    insecure_count=$(grep -r '>/tmp/' "${PROJECT_ROOT}/scripts" --include="*.sh" | grep -v '^[[:space:]]*#' | wc -l || echo "0")

    if [[ "$insecure_count" -gt 0 ]]; then
        test_fail "Found $insecure_count insecure /tmp/ usage"
        return 1
    fi

    test_pass
}

# ============================================================================
# Main Test Runner
# ============================================================================

main() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}Secure Temp File Test Suite${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""

    # Run all tests
    test_common_create_temp_file
    test_setup_secrets_encrypt
    test_check_secret_leaks_workflow_logs
    test_common_call_ai_api
    test_common_rate_limit
    test_quick_deploy_log_file
    test_no_insecure_tmp_patterns

    # Print summary
    echo ""
    echo -e "${BLUE}================================${NC}"
    echo -e "Tests Run:    ${TESTS_RUN}"
    echo -e "Tests Passed: ${GREEN}${TESTS_PASSED}${NC}"
    echo -e "Tests Failed: ${RED}${TESTS_FAILED}${NC}"
    echo -e "${BLUE}================================${NC}"

    if [[ ${TESTS_FAILED} -gt 0 ]]; then
        echo ""
        echo -e "${RED}Failed Tests:${NC}"
        for failed_test in "${FAILED_TESTS[@]}"; do
            echo -e "  ${RED}✗${NC} $failed_test"
        done
        exit 1
    fi

    echo ""
    echo -e "${GREEN}All security tests passed!${NC}"
    exit 0
}

main "$@"
