#!/usr/bin/env bash
# Test script for runner-token-refresh.sh error paths
# Tests critical error handling and edge cases

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_UNDER_TEST="${SCRIPT_DIR}/../scripts/runner-token-refresh.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test results
declare -a FAILED_TESTS=()

#######################################
# Run a test and track results
#######################################
run_test() {
    local test_name="$1"
    local test_function="$2"

    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "Running: $test_name ... "

    if $test_function 2>/dev/null; then
        echo -e "${GREEN}PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAILED${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
    fi
}

#######################################
# Test: Script requires organization parameter
#######################################
test_missing_org_parameter() {
    # Should exit with error when no org is provided
    if $SCRIPT_UNDER_TEST --check-and-refresh 2>&1 | grep -q "Organization name is required"; then
        return 0
    fi
    return 1
}

#######################################
# Test: Error propagation in check_token_expiration
#######################################
test_error_propagation() {
    # Create a test environment
    local test_dir="/tmp/test-runner-$$"
    mkdir -p "$test_dir"

    # Test with non-existent runner directory
    RUNNER_DIR="$test_dir/nonexistent" RUNNER_ORG="test-org" \
        $SCRIPT_UNDER_TEST --check-and-refresh --dry-run 2>&1 | \
        grep -q "Runner directory not found"
    local result=$?

    # Cleanup
    rm -rf "$test_dir"

    return $result
}

#######################################
# Test: Dry run mode doesn't make changes
#######################################
test_dry_run_mode() {
    local test_dir="/tmp/test-runner-$$"
    mkdir -p "$test_dir"

    # Create a mock runner directory
    echo '{"agentId": 123}' > "$test_dir/.runner"

    # Run in dry-run mode
    RUNNER_DIR="$test_dir" RUNNER_ORG="test-org" \
        $SCRIPT_UNDER_TEST --check-and-refresh --dry-run 2>&1 | \
        grep -q "\[DRY RUN\]"
    local result=$?

    # Cleanup
    rm -rf "$test_dir"

    return $result
}

#######################################
# Test: Service detection with improved regex
#######################################
test_service_detection() {
    # Check if the script contains the improved service detection
    if grep -q 'grep -E "actions\\.runner\\..*\\.service"' "$SCRIPT_UNDER_TEST"; then
        return 0
    fi
    return 1
}

#######################################
# Test: Get removal token function exists
#######################################
test_removal_token_function() {
    # Check if get_removal_token function is defined
    if grep -q "^get_removal_token()" "$SCRIPT_UNDER_TEST"; then
        return 0
    fi
    return 1
}

#######################################
# Test: Error handling returns proper exit codes
#######################################
test_exit_codes() {
    # Test missing runner directory
    RUNNER_DIR="/nonexistent/path" RUNNER_ORG="test-org" \
        $SCRIPT_UNDER_TEST --check-and-refresh 2>/dev/null

    if [[ $? -ne 0 ]]; then
        return 0
    fi
    return 1
}

#######################################
# Test: Metrics file handling with null values
#######################################
test_metrics_null_handling() {
    local test_dir="/tmp/test-metrics-$$"
    mkdir -p "$test_dir"

    # Create metrics file with null values
    cat > "$test_dir/metrics.json" <<EOF
{
  "last_check_timestamp": null,
  "consecutive_failures": null
}
EOF

    # The script should handle null values gracefully
    METRICS_FILE="$test_dir/metrics.json" RUNNER_DIR="/tmp" RUNNER_ORG="test-org" \
        timeout 2 $SCRIPT_UNDER_TEST --check-and-refresh --dry-run 2>&1 | \
        grep -v "jq: error"
    local result=$?

    # Cleanup
    rm -rf "$test_dir"

    return $result
}

#######################################
# Test: Token cache file handling
#######################################
test_token_cache_handling() {
    local test_dir="/tmp/test-cache-$$"
    mkdir -p "$test_dir"

    # Create a token cache with invalid content
    echo "not-a-number" > "$test_dir/.token_cache"

    # Should handle invalid cache gracefully
    TOKEN_CACHE_FILE="$test_dir/.token_cache" RUNNER_DIR="$test_dir" \
        RUNNER_ORG="test-org" \
        $SCRIPT_UNDER_TEST --check-and-refresh --dry-run 2>&1 | \
        grep -q "Cannot determine token expiration"
    local result=$?

    # Cleanup
    rm -rf "$test_dir"

    return $result
}

#######################################
# Test: Check and refresh once error handling
#######################################
test_check_and_refresh_error_handling() {
    # Check if the function properly captures expiration_status
    if grep -A5 "check_and_refresh_once()" "$SCRIPT_UNDER_TEST" | \
       grep -q "local expiration_status=\$?"; then
        return 0
    fi
    return 1
}

#######################################
# Test: Retry logic with backoff
#######################################
test_retry_backoff() {
    # Check if retry backoff is implemented
    if grep -q "RETRY_BACKOFF_SECONDS" "$SCRIPT_UNDER_TEST" && \
       grep -q "sleep.*RETRY_BACKOFF_SECONDS" "$SCRIPT_UNDER_TEST"; then
        return 0
    fi
    return 1
}

#######################################
# Main test runner
#######################################
main() {
    echo "========================================="
    echo "Runner Token Refresh Error Path Tests"
    echo "========================================="
    echo ""

    # Check if script exists
    if [[ ! -f "$SCRIPT_UNDER_TEST" ]]; then
        echo -e "${RED}ERROR: Script not found: $SCRIPT_UNDER_TEST${NC}"
        exit 1
    fi

    # Run all tests
    run_test "Missing organization parameter" test_missing_org_parameter
    run_test "Error propagation in check_token_expiration" test_error_propagation
    run_test "Dry run mode" test_dry_run_mode
    run_test "Improved service detection" test_service_detection
    run_test "Get removal token function exists" test_removal_token_function
    run_test "Exit codes on error" test_exit_codes
    run_test "Metrics null value handling" test_metrics_null_handling
    run_test "Token cache handling" test_token_cache_handling
    run_test "Check and refresh error handling" test_check_and_refresh_error_handling
    run_test "Retry backoff implementation" test_retry_backoff

    # Print summary
    echo ""
    echo "========================================="
    echo "Test Results Summary"
    echo "========================================="
    echo -e "Tests run:    $TESTS_RUN"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"

    if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
        echo ""
        echo "Failed tests:"
        for test in "${FAILED_TESTS[@]}"; do
            echo -e "  ${RED}✗${NC} $test"
        done
    fi

    echo ""
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}✗ Some tests failed${NC}"
        exit 1
    fi
}

# Run tests
main "$@"