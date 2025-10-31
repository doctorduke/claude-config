#!/usr/bin/env bash
#
# test-http-status.sh - Test HTTP Status Code Categorization and Retry Logic
#
# Tests the new HTTP-aware retry logic in common.sh
#

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Test results
declare -a FAILED_TESTS=()

# Colors for output
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BOLD=''
    NC=''
fi

#==============================================================================
# Test Utilities
#==============================================================================

print_test_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}[PASS]${NC} $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}[FAIL]${NC} $test_name"
        echo -e "  Expected: $expected"
        echo -e "  Actual:   $actual"
        FAILED_TESTS+=("$test_name")
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_exit_code() {
    local expected_code="$1"
    local actual_code="$2"
    local test_name="$3"

    if [[ "$expected_code" == "$actual_code" ]]; then
        echo -e "${GREEN}[PASS]${NC} $test_name (exit code: $actual_code)"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}[FAIL]${NC} $test_name"
        echo -e "  Expected exit code: $expected_code"
        echo -e "  Actual exit code:   $actual_code"
        FAILED_TESTS+=("$test_name")
        ((TESTS_FAILED++))
        return 1
    fi
}

#==============================================================================
# Test Functions
#==============================================================================

test_categorize_http_status() {
    print_test_header "Testing categorize_http_status()"

    # Test 2xx Success
    local result
    result=$(categorize_http_status "200")
    local exit_code=$?
    assert_equals "SUCCESS" "$result" "HTTP 200 -> SUCCESS"
    assert_exit_code "0" "$exit_code" "HTTP 200 exit code"

    result=$(categorize_http_status "201")
    exit_code=$?
    assert_equals "SUCCESS" "$result" "HTTP 201 -> SUCCESS"
    assert_exit_code "0" "$exit_code" "HTTP 201 exit code"

    result=$(categorize_http_status "204")
    exit_code=$?
    assert_equals "SUCCESS" "$result" "HTTP 204 -> SUCCESS"
    assert_exit_code "0" "$exit_code" "HTTP 204 exit code"

    # Test 4xx Client Error
    result=$(categorize_http_status "400")
    exit_code=$?
    assert_equals "CLIENT_ERROR" "$result" "HTTP 400 -> CLIENT_ERROR"
    assert_exit_code "1" "$exit_code" "HTTP 400 exit code"

    result=$(categorize_http_status "401")
    exit_code=$?
    assert_equals "CLIENT_ERROR" "$result" "HTTP 401 -> CLIENT_ERROR"
    assert_exit_code "1" "$exit_code" "HTTP 401 exit code"

    result=$(categorize_http_status "403")
    exit_code=$?
    assert_equals "CLIENT_ERROR" "$result" "HTTP 403 -> CLIENT_ERROR"
    assert_exit_code "1" "$exit_code" "HTTP 403 exit code"

    result=$(categorize_http_status "404")
    exit_code=$?
    assert_equals "CLIENT_ERROR" "$result" "HTTP 404 -> CLIENT_ERROR"
    assert_exit_code "1" "$exit_code" "HTTP 404 exit code"

    # Test 429 Rate Limit (special case)
    result=$(categorize_http_status "429")
    exit_code=$?
    assert_equals "RATE_LIMIT" "$result" "HTTP 429 -> RATE_LIMIT"
    assert_exit_code "2" "$exit_code" "HTTP 429 exit code"

    # Test 5xx Server Error
    result=$(categorize_http_status "500")
    exit_code=$?
    assert_equals "SERVER_ERROR" "$result" "HTTP 500 -> SERVER_ERROR"
    assert_exit_code "3" "$exit_code" "HTTP 500 exit code"

    result=$(categorize_http_status "502")
    exit_code=$?
    assert_equals "SERVER_ERROR" "$result" "HTTP 502 -> SERVER_ERROR"
    assert_exit_code "3" "$exit_code" "HTTP 502 exit code"

    result=$(categorize_http_status "503")
    exit_code=$?
    assert_equals "SERVER_ERROR" "$result" "HTTP 503 -> SERVER_ERROR"
    assert_exit_code "3" "$exit_code" "HTTP 503 exit code"

    # Test Unknown
    result=$(categorize_http_status "000")
    exit_code=$?
    assert_equals "UNKNOWN" "$result" "HTTP 000 -> UNKNOWN"
    assert_exit_code "4" "$exit_code" "HTTP 000 exit code"

    result=$(categorize_http_status "999")
    exit_code=$?
    assert_equals "UNKNOWN" "$result" "HTTP 999 -> UNKNOWN"
    assert_exit_code "4" "$exit_code" "HTTP 999 exit code"
}

test_get_retry_after() {
    print_test_header "Testing get_retry_after()"

    # Create temp file with Retry-After header
    local headers_file
    headers_file=$(mktemp)

    # Test numeric Retry-After
    echo "HTTP/1.1 429 Too Many Requests" > "$headers_file"
    echo "Retry-After: 60" >> "$headers_file"
    echo "Content-Type: application/json" >> "$headers_file"

    local result
    result=$(get_retry_after "$headers_file")
    assert_equals "60" "$result" "Retry-After: 60"

    # Test with different value
    echo "HTTP/1.1 429 Too Many Requests" > "$headers_file"
    echo "Retry-After: 120" >> "$headers_file"

    result=$(get_retry_after "$headers_file")
    assert_equals "120" "$result" "Retry-After: 120"

    # Test missing header (should use default)
    echo "HTTP/1.1 429 Too Many Requests" > "$headers_file"
    echo "Content-Type: application/json" >> "$headers_file"

    result=$(get_retry_after "$headers_file" 45)
    assert_equals "45" "$result" "Missing Retry-After (default: 45)"

    # Test with custom default
    result=$(get_retry_after "$headers_file" 90)
    assert_equals "90" "$result" "Missing Retry-After (default: 90)"

    rm -f "$headers_file"
}

test_should_retry_http_success() {
    print_test_header "Testing should_retry_http() - Success Cases"

    # 200 - should NOT retry
    local delay
    delay=$(should_retry_http 3 1 200 5 2>&1)
    local exit_code=$?
    assert_exit_code "1" "$exit_code" "HTTP 200 should not retry"

    # 201 - should NOT retry
    delay=$(should_retry_http 3 1 201 5 2>&1)
    exit_code=$?
    assert_exit_code "1" "$exit_code" "HTTP 201 should not retry"
}

test_should_retry_http_client_error() {
    print_test_header "Testing should_retry_http() - Client Error Cases"

    # 400 - should NOT retry
    local delay
    delay=$(should_retry_http 3 1 400 5 2>&1)
    local exit_code=$?
    assert_exit_code "1" "$exit_code" "HTTP 400 should not retry"

    # 401 - should NOT retry
    delay=$(should_retry_http 3 1 401 5 2>&1)
    exit_code=$?
    assert_exit_code "1" "$exit_code" "HTTP 401 should not retry"

    # 404 - should NOT retry
    delay=$(should_retry_http 3 1 404 5 2>&1)
    exit_code=$?
    assert_exit_code "1" "$exit_code" "HTTP 404 should not retry"
}

test_should_retry_http_rate_limit() {
    print_test_header "Testing should_retry_http() - Rate Limit Cases"

    # 429 - should retry with longer backoff
    local delay
    delay=$(should_retry_http 3 1 429 5 2>&1)
    local exit_code=$?
    assert_exit_code "0" "$exit_code" "HTTP 429 should retry"
    # Delay should be base_delay * 3 = 5 * 3 = 15
    assert_equals "15" "$delay" "HTTP 429 delay (no headers)"

    # 429 at last attempt - should NOT retry
    delay=$(should_retry_http 3 3 429 5 2>&1)
    exit_code=$?
    assert_exit_code "1" "$exit_code" "HTTP 429 at max retries should not retry"

    # 429 with Retry-After header
    local headers_file
    headers_file=$(mktemp)
    echo "Retry-After: 30" > "$headers_file"

    delay=$(should_retry_http 3 1 429 5 "$headers_file" 2>&1)
    exit_code=$?
    assert_exit_code "0" "$exit_code" "HTTP 429 with Retry-After should retry"
    assert_equals "30" "$delay" "HTTP 429 respects Retry-After header"

    rm -f "$headers_file"
}

test_should_retry_http_server_error() {
    print_test_header "Testing should_retry_http() - Server Error Cases"

    # 500 - should retry with exponential backoff
    local delay
    delay=$(should_retry_http 3 1 500 5 2>&1)
    local exit_code=$?
    assert_exit_code "0" "$exit_code" "HTTP 500 should retry"
    # Delay should be base_delay * (2 ** (attempt - 1)) = 5 * 1 = 5
    assert_equals "5" "$delay" "HTTP 500 delay (attempt 1)"

    # Attempt 2
    delay=$(should_retry_http 3 2 500 5 2>&1)
    exit_code=$?
    assert_exit_code "0" "$exit_code" "HTTP 500 should retry (attempt 2)"
    # Delay should be 5 * 2 = 10
    assert_equals "10" "$delay" "HTTP 500 delay (attempt 2)"

    # 503 - should retry
    delay=$(should_retry_http 3 1 503 5 2>&1)
    exit_code=$?
    assert_exit_code "0" "$exit_code" "HTTP 503 should retry"

    # 500 at last attempt - should NOT retry
    delay=$(should_retry_http 3 3 500 5 2>&1)
    exit_code=$?
    assert_exit_code "1" "$exit_code" "HTTP 500 at max retries should not retry"
}

test_should_retry_http_unknown() {
    print_test_header "Testing should_retry_http() - Unknown Cases"

    # 000 - should NOT retry
    local delay
    delay=$(should_retry_http 3 1 000 5 2>&1)
    local exit_code=$?
    assert_exit_code "1" "$exit_code" "HTTP 000 should not retry"

    # 999 - should NOT retry
    delay=$(should_retry_http 3 1 999 5 2>&1)
    exit_code=$?
    assert_exit_code "1" "$exit_code" "HTTP 999 should not retry"
}

#==============================================================================
# Main Test Runner
#==============================================================================

main() {
    echo -e "${BOLD}======================================${NC}"
    echo -e "${BOLD}HTTP Status Code Retry Logic Tests${NC}"
    echo -e "${BOLD}======================================${NC}"

    # Enable verbose logging for tests
    CURRENT_LOG_LEVEL="${LOG_LEVEL_ERROR}"

    # Run all tests
    test_categorize_http_status
    test_get_retry_after
    test_should_retry_http_success
    test_should_retry_http_client_error
    test_should_retry_http_rate_limit
    test_should_retry_http_server_error
    test_should_retry_http_unknown

    # Print summary
    echo ""
    echo -e "${BOLD}======================================${NC}"
    echo -e "${BOLD}Test Summary${NC}"
    echo -e "${BOLD}======================================${NC}"
    echo -e "Tests Passed: ${GREEN}${TESTS_PASSED}${NC}"
    echo -e "Tests Failed: ${RED}${TESTS_FAILED}${NC}"
    echo -e "Total Tests:  $((TESTS_PASSED + TESTS_FAILED))"

    if [[ ${TESTS_FAILED} -gt 0 ]]; then
        echo ""
        echo -e "${RED}Failed Tests:${NC}"
        for test in "${FAILED_TESTS[@]}"; do
            echo -e "  - $test"
        done
        exit 1
    else
        echo ""
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    fi
}

# Run tests
main "$@"
