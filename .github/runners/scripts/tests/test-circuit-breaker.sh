#!/usr/bin/env bash
# Script: test-circuit-breaker.sh
# Description: Comprehensive tests for circuit breaker functionality
# Usage: ./test-circuit-breaker.sh

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source circuit breaker library
source "${SCRIPT_DIR}/../lib/circuit_breaker.sh"
source "${SCRIPT_DIR}/../lib/common.sh"

# Test configuration
readonly TEST_ENDPOINT="test_service"
readonly TEST_DIR="${TMPDIR:-/tmp}/cb_test_$$"
export CB_STATE_DIR="${TEST_DIR}"
export CB_FAILURE_THRESHOLD=3
export CB_TIMEOUT=5
export CB_HALF_OPEN_TIMEOUT=3
export CB_SUCCESS_THRESHOLD=2

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Setup test environment
setup_test() {
    mkdir -p "${TEST_DIR}"
    TESTS_RUN=$((TESTS_RUN + 1))
}

# Cleanup test environment
cleanup_test() {
    rm -rf "${TEST_DIR}"
}

# Assert equals
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"

    if [[ "${expected}" == "${actual}" ]]; then
        echo "  [PASS] ${message}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo "  [FAIL] ${message}"
        echo "    Expected: ${expected}"
        echo "    Actual:   ${actual}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Assert command succeeds
assert_success() {
    local message="${1:-}"
    shift
    local cmd=("$@")

    if "${cmd[@]}" &>/dev/null; then
        echo "  [PASS] ${message}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo "  [FAIL] ${message}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Assert command fails
assert_failure() {
    local message="${1:-}"
    shift
    local cmd=("$@")

    if ! "${cmd[@]}" &>/dev/null; then
        echo "  [PASS] ${message}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo "  [FAIL] ${message}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test: Circuit breaker initialization
test_initialization() {
    echo "[TEST 1] Circuit breaker initialization"
    setup_test

    init_circuit_breaker "${TEST_ENDPOINT}"

    local state
    state=$(get_circuit_state "${TEST_ENDPOINT}")
    assert_equals "CLOSED" "${state}" "Initial state should be CLOSED"

    cleanup_test
}

# Test: CLOSED to OPEN transition
test_closed_to_open() {
    echo "[TEST 2] CLOSED to OPEN transition after threshold failures"
    setup_test

    init_circuit_breaker "${TEST_ENDPOINT}"

    # Record failures up to threshold
    for i in $(seq 1 "${CB_FAILURE_THRESHOLD}"); do
        record_failure "${TEST_ENDPOINT}"
    done

    local state
    state=$(get_circuit_state "${TEST_ENDPOINT}")
    assert_equals "OPEN" "${state}" "State should be OPEN after ${CB_FAILURE_THRESHOLD} failures"

    cleanup_test
}

# Test: Fail fast when OPEN
test_fail_fast_when_open() {
    echo "[TEST 3] Fail fast when circuit is OPEN"
    setup_test

    init_circuit_breaker "${TEST_ENDPOINT}"

    # Open the circuit
    for i in $(seq 1 "${CB_FAILURE_THRESHOLD}"); do
        record_failure "${TEST_ENDPOINT}"
    done

    assert_success "Circuit should be OPEN" is_circuit_open "${TEST_ENDPOINT}"

    cleanup_test
}

# Test: OPEN to HALF_OPEN transition
test_open_to_half_open() {
    echo "[TEST 4] OPEN to HALF_OPEN transition after timeout"
    setup_test

    init_circuit_breaker "${TEST_ENDPOINT}"

    # Open the circuit
    for i in $(seq 1 "${CB_FAILURE_THRESHOLD}"); do
        record_failure "${TEST_ENDPOINT}"
    done

    # Wait for timeout
    sleep $((CB_TIMEOUT + 1))

    local state
    state=$(get_circuit_state "${TEST_ENDPOINT}")
    assert_equals "HALF_OPEN" "${state}" "State should be HALF_OPEN after timeout"

    cleanup_test
}

# Test: HALF_OPEN to CLOSED transition
test_half_open_to_closed() {
    echo "[TEST 5] HALF_OPEN to CLOSED transition after successes"
    setup_test

    init_circuit_breaker "${TEST_ENDPOINT}"

    # Open the circuit
    for i in $(seq 1 "${CB_FAILURE_THRESHOLD}"); do
        record_failure "${TEST_ENDPOINT}"
    done

    # Wait for HALF_OPEN
    sleep $((CB_TIMEOUT + 1))

    # Record successes to close the circuit
    for i in $(seq 1 "${CB_SUCCESS_THRESHOLD}"); do
        record_success "${TEST_ENDPOINT}"
    done

    local state
    state=$(get_circuit_state "${TEST_ENDPOINT}")
    assert_equals "CLOSED" "${state}" "State should be CLOSED after ${CB_SUCCESS_THRESHOLD} successes"

    cleanup_test
}

# Test: HALF_OPEN to OPEN on failure
test_half_open_to_open_on_failure() {
    echo "[TEST 6] HALF_OPEN to OPEN transition on failure"
    setup_test

    init_circuit_breaker "${TEST_ENDPOINT}"

    # Open the circuit
    for i in $(seq 1 "${CB_FAILURE_THRESHOLD}"); do
        record_failure "${TEST_ENDPOINT}"
    done

    # Wait for HALF_OPEN
    sleep $((CB_TIMEOUT + 1))

    # Record one failure in HALF_OPEN
    record_failure "${TEST_ENDPOINT}"

    local state
    state=$(get_circuit_state "${TEST_ENDPOINT}")
    assert_equals "OPEN" "${state}" "State should be OPEN after failure in HALF_OPEN"

    cleanup_test
}

# Test: Multiple endpoints independently
test_multiple_endpoints() {
    echo "[TEST 7] Multiple endpoints operate independently"
    setup_test

    local endpoint1="service1"
    local endpoint2="service2"

    init_circuit_breaker "${endpoint1}"
    init_circuit_breaker "${endpoint2}"

    # Open circuit for endpoint1
    for i in $(seq 1 "${CB_FAILURE_THRESHOLD}"); do
        record_failure "${endpoint1}"
    done

    # Record success for endpoint2
    record_success "${endpoint2}"

    local state1
    state1=$(get_circuit_state "${endpoint1}")
    local state2
    state2=$(get_circuit_state "${endpoint2}")

    assert_equals "OPEN" "${state1}" "Endpoint1 should be OPEN"
    assert_equals "CLOSED" "${state2}" "Endpoint2 should be CLOSED"

    cleanup_test
}

# Test: Reset circuit breaker
test_reset() {
    echo "[TEST 8] Reset circuit breaker"
    setup_test

    init_circuit_breaker "${TEST_ENDPOINT}"

    # Open the circuit
    for i in $(seq 1 "${CB_FAILURE_THRESHOLD}"); do
        record_failure "${TEST_ENDPOINT}"
    done

    # Reset
    reset_circuit_breaker "${TEST_ENDPOINT}"

    local state
    state=$(get_circuit_state "${TEST_ENDPOINT}")
    assert_equals "CLOSED" "${state}" "State should be CLOSED after reset"

    cleanup_test
}

# Test: Success resets failure count
test_success_resets_failure_count() {
    echo "[TEST 9] Success resets failure count in CLOSED state"
    setup_test

    init_circuit_breaker "${TEST_ENDPOINT}"

    # Record some failures (below threshold)
    for i in $(seq 1 $((CB_FAILURE_THRESHOLD - 1))); do
        record_failure "${TEST_ENDPOINT}"
    done

    # Record success
    record_success "${TEST_ENDPOINT}"

    # Record failures again (should not open if count was reset)
    for i in $(seq 1 $((CB_FAILURE_THRESHOLD - 1))); do
        record_failure "${TEST_ENDPOINT}"
    done

    local state
    state=$(get_circuit_state "${TEST_ENDPOINT}")
    assert_equals "CLOSED" "${state}" "State should still be CLOSED after success reset"

    cleanup_test
}

# Test: call_with_circuit_breaker integration
test_call_with_circuit_breaker() {
    echo "[TEST 10] call_with_circuit_breaker integration"
    setup_test

    # Test successful command
    assert_success "Successful command should work" \
        call_with_circuit_breaker "${TEST_ENDPOINT}" echo "test"

    # Test failing command opens circuit
    for i in $(seq 1 "${CB_FAILURE_THRESHOLD}"); do
        call_with_circuit_breaker "${TEST_ENDPOINT}" false || true
    done

    # Next call should fail fast
    assert_failure "Should fail fast when circuit is OPEN" \
        call_with_circuit_breaker "${TEST_ENDPOINT}" echo "test"

    cleanup_test
}

# Test: Concurrent access (basic locking test)
test_concurrent_access() {
    echo "[TEST 11] Concurrent access with locking"
    setup_test

    init_circuit_breaker "${TEST_ENDPOINT}"

    # Simulate concurrent accesses
    (
        for i in $(seq 1 5); do
            record_failure "${TEST_ENDPOINT}" &
        done
        wait
    )

    # Circuit should be open after concurrent failures
    local state
    state=$(get_circuit_state "${TEST_ENDPOINT}")
    assert_equals "OPEN" "${state}" "State should be OPEN after concurrent failures"

    cleanup_test
}

# Test: get_circuit_stats
test_get_stats() {
    echo "[TEST 12] Get circuit breaker statistics"
    setup_test

    init_circuit_breaker "${TEST_ENDPOINT}"
    record_failure "${TEST_ENDPOINT}"

    assert_success "Should be able to get stats" \
        get_circuit_stats "${TEST_ENDPOINT}"

    cleanup_test
}

# Run all tests
run_all_tests() {
    echo "========================================"
    echo "Circuit Breaker Comprehensive Test Suite"
    echo "========================================"
    echo ""

    test_initialization
    test_closed_to_open
    test_fail_fast_when_open
    test_open_to_half_open
    test_half_open_to_closed
    test_half_open_to_open_on_failure
    test_multiple_endpoints
    test_reset
    test_success_resets_failure_count
    test_call_with_circuit_breaker
    test_concurrent_access
    test_get_stats

    echo ""
    echo "========================================"
    echo "Test Summary"
    echo "========================================"
    echo "Tests Run:    ${TESTS_RUN}"
    echo "Tests Passed: ${TESTS_PASSED}"
    echo "Tests Failed: ${TESTS_FAILED}"
    echo ""

    if [[ ${TESTS_FAILED} -eq 0 ]]; then
        echo "All tests passed!"
        return 0
    else
        echo "Some tests failed!"
        return 1
    fi
}

# Run tests
run_all_tests
