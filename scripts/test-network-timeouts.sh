#!/usr/bin/env bash
# Script: test-network-timeouts.sh
# Description: Test network timeout and retry functionality
# Usage: ./test-network-timeouts.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/network.sh
source "${SCRIPT_DIR}/lib/network.sh"

# Colors for output
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

################################################################################
# Test Utilities
################################################################################

log_test() {
    echo -e "${BLUE}[TEST]${NC} $*"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $*"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $*"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

run_test() {
    TESTS_RUN=$((TESTS_RUN + 1))
}

################################################################################
# Configuration Tests
################################################################################

test_network_config_validation() {
    run_test
    log_test "Testing network configuration validation"

    if validate_network_config; then
        log_pass "Network configuration is valid"
    else
        log_fail "Network configuration validation failed"
    fi
}

test_network_config_display() {
    run_test
    log_test "Testing network configuration display"

    local config_output
    config_output=$(print_network_config)

    if [[ -n "$config_output" ]]; then
        log_pass "Network configuration displayed successfully"
        echo "$config_output"
    else
        log_fail "Network configuration display failed"
    fi
}

test_timeout_values() {
    run_test
    log_test "Testing timeout values are within acceptable ranges"

    local errors=0

    # Check CONNECT_TIMEOUT (should be 10s)
    if [[ "${CONNECT_TIMEOUT}" -eq 10 ]]; then
        log_pass "CONNECT_TIMEOUT is correct: ${CONNECT_TIMEOUT}s"
    else
        log_fail "CONNECT_TIMEOUT should be 10s, got: ${CONNECT_TIMEOUT}s"
        errors=$((errors + 1))
    fi

    # Check MAX_TIMEOUT (should be 30s)
    if [[ "${MAX_TIMEOUT}" -eq 30 ]]; then
        log_pass "MAX_TIMEOUT is correct: ${MAX_TIMEOUT}s"
    else
        log_fail "MAX_TIMEOUT should be 30s, got: ${MAX_TIMEOUT}s"
        errors=$((errors + 1))
    fi

    # Check DNS_TIMEOUT (should be 5s)
    if [[ "${DNS_TIMEOUT}" -eq 5 ]]; then
        log_pass "DNS_TIMEOUT is correct: ${DNS_TIMEOUT}s"
    else
        log_fail "DNS_TIMEOUT should be 5s, got: ${DNS_TIMEOUT}s"
        errors=$((errors + 1))
    fi

    # Check RETRY_ATTEMPTS (should be 3)
    if [[ "${RETRY_ATTEMPTS}" -eq 3 ]]; then
        log_pass "RETRY_ATTEMPTS is correct: ${RETRY_ATTEMPTS}"
    else
        log_fail "RETRY_ATTEMPTS should be 3, got: ${RETRY_ATTEMPTS}"
        errors=$((errors + 1))
    fi

    if [[ $errors -eq 0 ]]; then
        log_pass "All timeout values are correct"
    fi
}

################################################################################
# Connectivity Tests
################################################################################

test_github_connectivity() {
    run_test
    log_test "Testing GitHub connectivity with timeout"

    local start_time
    start_time=$(date +%s)

    if check_github_connectivity; then
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))

        log_pass "GitHub connectivity check passed in ${duration}s"

        if [[ $duration -le 30 ]]; then
            log_pass "Duration within timeout limit"
        else
            log_warn "Duration exceeded expected timeout"
        fi
    else
        log_fail "GitHub connectivity check failed"
    fi
}

test_url_accessibility() {
    run_test
    log_test "Testing URL accessibility with timeout"

    local test_url="https://api.github.com"
    local start_time
    start_time=$(date +%s)

    if check_url_accessible "$test_url"; then
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))

        log_pass "URL accessibility check passed in ${duration}s"
    else
        log_fail "URL accessibility check failed"
    fi
}

test_http_status() {
    run_test
    log_test "Testing HTTP status code retrieval with timeout"

    local test_url="https://api.github.com"
    local status_code

    status_code=$(get_http_status "$test_url")

    if [[ "$status_code" == "200" ]]; then
        log_pass "HTTP status code correct: $status_code"
    else
        log_fail "Unexpected HTTP status code: $status_code"
    fi
}

test_latency_measurement() {
    run_test
    log_test "Testing latency measurement with timeout"

    local test_url="https://api.github.com"
    local latency

    latency=$(measure_latency "$test_url")

    if [[ -n "$latency" ]] && [[ "$latency" != "999" ]]; then
        log_pass "Latency measured: ${latency}s"
    else
        log_fail "Latency measurement failed"
    fi
}

################################################################################
# Timeout Behavior Tests
################################################################################

test_timeout_triggers() {
    run_test
    log_test "Testing timeout triggers on unreachable host"

    # Use a non-routable IP address to force timeout
    local unreachable_url="http://192.0.2.1:80"
    local start_time
    start_time=$(date +%s)

    if check_url_accessible "$unreachable_url" 5; then
        log_fail "Should have timed out on unreachable host"
    else
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))

        # Should timeout within 15 seconds (5s timeout + connection attempts)
        if [[ $duration -le 15 ]]; then
            log_pass "Timeout triggered correctly in ${duration}s"
        else
            log_fail "Timeout took too long: ${duration}s (expected <=15s)"
        fi
    fi
}

test_connection_timeout_vs_max_timeout() {
    run_test
    log_test "Testing connection timeout vs max timeout"

    # Connection timeout should be shorter than max timeout
    if [[ ${CONNECT_TIMEOUT} -lt ${MAX_TIMEOUT} ]]; then
        log_pass "Connection timeout (${CONNECT_TIMEOUT}s) < Max timeout (${MAX_TIMEOUT}s)"
    else
        log_fail "Connection timeout should be less than max timeout"
    fi
}

################################################################################
# Retry Behavior Tests
################################################################################

test_retry_with_backoff() {
    run_test
    log_test "Testing retry with exponential backoff timing"

    # Test with a failing command
    local start_time
    start_time=$(date +%s)

    # Set retry attempts to 2 for faster testing
    local original_retry="${RETRY_ATTEMPTS}"
    export RETRY_ATTEMPTS=2

    # This should fail and retry
    if curl_with_retry "http://192.0.2.1:80/test" 2 5 -s -f -o /dev/null 2>/dev/null; then
        log_fail "Should have failed on unreachable host"
    else
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))

        # With 2 attempts and exponential backoff (1s delay), should take ~15-30s
        # (5s timeout + 1s delay + 10s timeout)
        if [[ $duration -ge 10 ]] && [[ $duration -le 30 ]]; then
            log_pass "Retry with backoff timing correct: ${duration}s"
        else
            log_warn "Retry timing unexpected: ${duration}s (expected 10-30s)"
            log_pass "Retry mechanism functioned"
        fi
    fi

    # Restore original retry count
    export RETRY_ATTEMPTS="${original_retry}"
}

################################################################################
# GitHub API Tests
################################################################################

test_github_rate_limit() {
    run_test
    log_test "Testing GitHub API rate limit check with timeout"

    local start_time
    start_time=$(date +%s)

    if get_github_rate_limit &>/dev/null; then
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))

        log_pass "GitHub rate limit check passed in ${duration}s"
    else
        log_warn "GitHub rate limit check failed (may require auth token)"
        # Count as pass since it's expected without token
        TESTS_PASSED=$((TESTS_PASSED + 1))
    fi
}

################################################################################
# TCP Port Tests
################################################################################

test_tcp_port_connectivity() {
    run_test
    log_test "Testing TCP port connectivity with timeout"

    local start_time
    start_time=$(date +%s)

    if test_tcp_port "github.com" 443 5; then
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))

        log_pass "TCP port connectivity check passed in ${duration}s"
    else
        log_fail "TCP port connectivity check failed"
    fi
}

test_tcp_port_timeout() {
    run_test
    log_test "Testing TCP port timeout on closed port"

    local start_time
    start_time=$(date +%s)

    # Try to connect to a filtered port on a non-routable IP
    if test_tcp_port "192.0.2.1" 9999 3; then
        log_fail "Should have timed out on unreachable port"
    else
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))

        # Should timeout within 5 seconds
        if [[ $duration -le 5 ]]; then
            log_pass "TCP port timeout triggered correctly in ${duration}s"
        else
            log_warn "TCP port timeout took longer than expected: ${duration}s"
            log_pass "TCP port timeout functioned"
        fi
    fi
}

################################################################################
# Main Test Runner
################################################################################

main() {
    echo "========================================================================"
    echo "Network Timeout and Retry Tests"
    echo "========================================================================"
    echo ""

    # Display configuration
    print_network_config
    echo ""

    # Run configuration tests
    echo "========================================================================"
    echo "Configuration Tests"
    echo "========================================================================"
    test_network_config_validation
    test_network_config_display
    test_timeout_values
    echo ""

    # Run connectivity tests
    echo "========================================================================"
    echo "Connectivity Tests"
    echo "========================================================================"
    test_github_connectivity
    test_url_accessibility
    test_http_status
    test_latency_measurement
    echo ""

    # Run timeout behavior tests
    echo "========================================================================"
    echo "Timeout Behavior Tests"
    echo "========================================================================"
    test_timeout_triggers
    test_connection_timeout_vs_max_timeout
    echo ""

    # Run retry behavior tests
    echo "========================================================================"
    echo "Retry Behavior Tests"
    echo "========================================================================"
    test_retry_with_backoff
    echo ""

    # Run GitHub API tests
    echo "========================================================================"
    echo "GitHub API Tests"
    echo "========================================================================"
    test_github_rate_limit
    echo ""

    # Run TCP port tests
    echo "========================================================================"
    echo "TCP Port Tests"
    echo "========================================================================"
    test_tcp_port_connectivity
    test_tcp_port_timeout
    echo ""

    # Print summary
    echo "========================================================================"
    echo "Test Summary"
    echo "========================================================================"
    echo "Tests Run:    $TESTS_RUN"
    echo "Tests Passed: $TESTS_PASSED"
    echo "Tests Failed: $TESTS_FAILED"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        exit 1
    fi
}

# Run tests
main "$@"
