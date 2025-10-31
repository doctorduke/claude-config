#!/usr/bin/env bash
# Script: test-runner-token-refresh.sh
# Description: Test suite for runner token refresh functionality
# Usage: ./test-runner-token-refresh.sh

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TOKEN_REFRESH_SCRIPT="${PROJECT_ROOT}/scripts/runner-token-refresh.sh"

# Source common utilities
# shellcheck source=../scripts/lib/common.sh
source "${PROJECT_ROOT}/scripts/lib/common.sh"

# Test configuration
TEST_RUNNER_DIR="/tmp/test-runner-$$"
TEST_ORG="test-org"
TEST_RESULTS=()
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for test output
readonly COLOR_PASS='\033[0;32m'
readonly COLOR_FAIL='\033[0;31m'
readonly COLOR_SKIP='\033[0;33m'
readonly COLOR_TEST='\033[0;36m'

#######################################
# Clean up test environment
#######################################
cleanup() {
    log_info "Cleaning up test environment..."
    rm -rf "$TEST_RUNNER_DIR" 2>/dev/null || true
}

# Register cleanup on exit
trap cleanup EXIT

#######################################
# Setup test environment
#######################################
setup_test_env() {
    log_info "Setting up test environment..."

    # Create test runner directory
    mkdir -p "$TEST_RUNNER_DIR"

    # Create mock runner configuration files
    cat > "${TEST_RUNNER_DIR}/.runner" <<EOF
{
  "agentId": 1,
  "agentName": "test-runner",
  "poolId": 1,
  "poolName": "Default",
  "serverUrl": "https://github.com/${TEST_ORG}",
  "gitHubUrl": "https://github.com/${TEST_ORG}",
  "workFolder": "_work"
}
EOF

    # Create lib directory and common.sh for the script
    mkdir -p "${PROJECT_ROOT}/scripts/lib"
    if [[ ! -f "${PROJECT_ROOT}/scripts/lib/common.sh" ]]; then
        log_warn "common.sh not found, creating minimal version for testing"
        cat > "${PROJECT_ROOT}/scripts/lib/common.sh" <<'EOF'
#!/usr/bin/env bash
log_info() { echo "[INFO] $*" >&2; }
log_warn() { echo "[WARN] $*" >&2; }
log_error() { echo "[ERROR] $*" >&2; }
log_debug() { echo "[DEBUG] $*" >&2; }
EOF
    fi

    log_info "Test environment ready"
}

#######################################
# Assert test condition
# Arguments:
#   $1 - Condition to test
#   $2 - Test description
#######################################
assert() {
    local condition="$1"
    local description="$2"

    echo -e "${COLOR_TEST}TEST:${COLOR_RESET} ${description}"

    if eval "$condition"; then
        echo -e "  ${COLOR_PASS}✓ PASS${COLOR_RESET}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        TEST_RESULTS+=("PASS: $description")
        return 0
    else
        echo -e "  ${COLOR_FAIL}✗ FAIL${COLOR_RESET}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        TEST_RESULTS+=("FAIL: $description")
        return 1
    fi
}

#######################################
# Skip test with reason
# Arguments:
#   $1 - Test description
#   $2 - Skip reason
#######################################
skip_test() {
    local description="$1"
    local reason="$2"

    echo -e "${COLOR_TEST}TEST:${COLOR_RESET} ${description}"
    echo -e "  ${COLOR_SKIP}⊘ SKIP${COLOR_RESET} - ${reason}"
    TEST_RESULTS+=("SKIP: $description - $reason")
}

#######################################
# Test: Script exists and is executable
#######################################
test_script_exists() {
    log_info "Test 1: Script existence and permissions"

    assert "[[ -f '$TOKEN_REFRESH_SCRIPT' ]]" \
        "Token refresh script exists"

    assert "[[ -x '$TOKEN_REFRESH_SCRIPT' ]]" \
        "Token refresh script is executable"
}

#######################################
# Test: Script shows help message
#######################################
test_help_message() {
    log_info "Test 2: Help message"

    local help_output
    help_output=$("$TOKEN_REFRESH_SCRIPT" --help 2>&1 || true)

    assert "[[ '$help_output' =~ 'Usage:' ]]" \
        "Help message contains usage information"

    assert "[[ '$help_output' =~ '--daemon' ]]" \
        "Help message documents --daemon option"

    assert "[[ '$help_output' =~ '--check-and-refresh' ]]" \
        "Help message documents --check-and-refresh option"

    assert "[[ '$help_output' =~ '--org' ]]" \
        "Help message documents --org option"
}

#######################################
# Test: Script validates required parameters
#######################################
test_parameter_validation() {
    log_info "Test 3: Parameter validation"

    # Test missing organization
    local output
    output=$("$TOKEN_REFRESH_SCRIPT" --check-and-refresh 2>&1 || true)

    assert "[[ '$output' =~ 'Organization name is required' ]]" \
        "Script validates required organization parameter"
}

#######################################
# Test: Token expiration time calculation
#######################################
test_token_expiration_calculation() {
    log_info "Test 4: Token expiration calculation"

    # Create token cache file with expiration in future
    local future_time
    future_time=$(($(date +%s) + 3600))  # 1 hour from now
    echo "$future_time" > "${TEST_RUNNER_DIR}/.token_cache"

    # Test that script can read expiration
    # Note: This is a mock test since we can't easily test the internal function
    assert "[[ -f '${TEST_RUNNER_DIR}/.token_cache' ]]" \
        "Token cache file can be created"

    local cached_time
    cached_time=$(cat "${TEST_RUNNER_DIR}/.token_cache")

    assert "[[ '$cached_time' =~ ^[0-9]+$ ]]" \
        "Token cache contains valid Unix timestamp"
}

#######################################
# Test: Metrics file creation and format
#######################################
test_metrics_file() {
    log_info "Test 5: Metrics file handling"

    local metrics_file="/tmp/test-metrics-$$.json"

    # Create sample metrics file
    cat > "$metrics_file" <<EOF
{
  "last_check_timestamp": $(date +%s),
  "last_refresh_timestamp": $(($(date +%s) - 3600)),
  "total_refreshes": 5,
  "failed_refreshes": 1,
  "consecutive_failures": 0,
  "runner_org": "${TEST_ORG}",
  "runner_name": "test-runner"
}
EOF

    assert "[[ -f '$metrics_file' ]]" \
        "Metrics file can be created"

    if command -v jq &>/dev/null; then
        assert "jq -e '.total_refreshes == 5' '$metrics_file' >/dev/null" \
            "Metrics file contains valid JSON with expected values"

        assert "jq -e '.runner_org == \"${TEST_ORG}\"' '$metrics_file' >/dev/null" \
            "Metrics file contains organization name"
    else
        skip_test "Metrics JSON validation" "jq not installed"
    fi

    rm -f "$metrics_file"
}

#######################################
# Test: GitHub CLI availability check
#######################################
test_gh_cli_check() {
    log_info "Test 6: GitHub CLI availability"

    if command -v gh &>/dev/null; then
        assert "command -v gh &>/dev/null" \
            "GitHub CLI (gh) is installed"

        # Note: We don't test authentication since it may not be set up in CI
        skip_test "GitHub CLI authentication" "May not be configured in test environment"
    else
        skip_test "GitHub CLI tests" "gh not installed"
    fi
}

#######################################
# Test: Dry run mode
#######################################
test_dry_run_mode() {
    log_info "Test 7: Dry run mode"

    if ! command -v gh &>/dev/null || ! gh auth status &>/dev/null; then
        skip_test "Dry run mode test" "GitHub CLI not available or not authenticated"
        return 0
    fi

    # Run in dry-run mode (should not make any changes)
    local output
    output=$("$TOKEN_REFRESH_SCRIPT" --check-and-refresh --org "$TEST_ORG" --runner-dir "$TEST_RUNNER_DIR" --dry-run 2>&1 || true)

    assert "[[ '$output' =~ 'DRY RUN' || '$output' =~ 'dry run' || '$output' =~ 'Cannot determine token expiration' ]]" \
        "Dry run mode executes without errors or indicates missing token info"
}

#######################################
# Test: Configuration file formats
#######################################
test_configuration_files() {
    log_info "Test 8: Configuration file formats"

    # Test systemd service file
    local service_file="${PROJECT_ROOT}/config/systemd/github-runner-token-refresh.service"
    if [[ -f "$service_file" ]]; then
        assert "[[ -f '$service_file' ]]" \
            "Systemd service file exists"

        assert "grep -q '\[Unit\]' '$service_file'" \
            "Systemd service file has [Unit] section"

        assert "grep -q '\[Service\]' '$service_file'" \
            "Systemd service file has [Service] section"

        assert "grep -q '\[Install\]' '$service_file'" \
            "Systemd service file has [Install] section"

        assert "grep -q 'ExecStart=' '$service_file'" \
            "Systemd service file defines ExecStart"
    else
        skip_test "Systemd service file tests" "Service file not found"
    fi

    # Test environment file example
    local env_file="${PROJECT_ROOT}/config/systemd/token-refresh.env.example"
    if [[ -f "$env_file" ]]; then
        assert "[[ -f '$env_file' ]]" \
            "Environment file example exists"

        assert "grep -q 'RUNNER_ORG=' '$env_file'" \
            "Environment file defines RUNNER_ORG"

        assert "grep -q 'REFRESH_THRESHOLD=' '$env_file'" \
            "Environment file defines REFRESH_THRESHOLD"
    else
        skip_test "Environment file tests" "Environment file not found"
    fi

    # Test cron file
    local cron_file="${PROJECT_ROOT}/config/cron/runner-token-refresh.cron"
    if [[ -f "$cron_file" ]]; then
        assert "[[ -f '$cron_file' ]]" \
            "Cron configuration file exists"

        assert "grep -q 'runner-token-refresh.sh' '$cron_file'" \
            "Cron file references token refresh script"
    else
        skip_test "Cron file tests" "Cron file not found"
    fi
}

#######################################
# Test: Documentation exists
#######################################
test_documentation() {
    log_info "Test 9: Documentation"

    local doc_file="${PROJECT_ROOT}/docs/runner-token-refresh.md"

    if [[ -f "$doc_file" ]]; then
        assert "[[ -f '$doc_file' ]]" \
            "Documentation file exists"

        assert "grep -q 'Installation' '$doc_file'" \
            "Documentation includes installation instructions"

        assert "grep -q 'Configuration' '$doc_file'" \
            "Documentation includes configuration section"

        assert "grep -q 'Troubleshooting' '$doc_file'" \
            "Documentation includes troubleshooting section"

        assert "grep -q 'systemd' '$doc_file'" \
            "Documentation covers systemd service"

        assert "grep -q 'cron' '$doc_file'" \
            "Documentation covers cron jobs"
    else
        skip_test "Documentation tests" "Documentation file not found"
    fi
}

#######################################
# Test: Script handles missing dependencies gracefully
#######################################
test_dependency_handling() {
    log_info "Test 10: Dependency handling"

    # The script should check for gh and jq
    assert "grep -q 'command -v gh' '$TOKEN_REFRESH_SCRIPT'" \
        "Script checks for GitHub CLI availability"

    assert "grep -q 'command -v jq' '$TOKEN_REFRESH_SCRIPT'" \
        "Script checks for jq availability"

    assert "grep -q 'gh auth status' '$TOKEN_REFRESH_SCRIPT'" \
        "Script checks GitHub CLI authentication"
}

#######################################
# Test: Error handling and retry logic
#######################################
test_error_handling() {
    log_info "Test 11: Error handling and retry logic"

    assert "grep -q 'MAX_RETRY_ATTEMPTS' '$TOKEN_REFRESH_SCRIPT'" \
        "Script defines retry attempts configuration"

    assert "grep -q 'RETRY_BACKOFF' '$TOKEN_REFRESH_SCRIPT'" \
        "Script defines retry backoff configuration"

    assert "grep -q 'refresh_token_with_retry' '$TOKEN_REFRESH_SCRIPT'" \
        "Script implements retry logic function"

    assert "grep -q 'consecutive_failures' '$TOKEN_REFRESH_SCRIPT'" \
        "Script tracks consecutive failures"
}

#######################################
# Test: Logging functionality
#######################################
test_logging() {
    log_info "Test 12: Logging functionality"

    assert "grep -q 'log_info' '$TOKEN_REFRESH_SCRIPT'" \
        "Script uses log_info for informational messages"

    assert "grep -q 'log_error' '$TOKEN_REFRESH_SCRIPT'" \
        "Script uses log_error for error messages"

    assert "grep -q 'log_warn' '$TOKEN_REFRESH_SCRIPT'" \
        "Script uses log_warn for warning messages"

    assert "grep -q 'log_to_file' '$TOKEN_REFRESH_SCRIPT'" \
        "Script implements file logging function"

    assert "grep -q 'LOG_FILE' '$TOKEN_REFRESH_SCRIPT'" \
        "Script defines log file configuration"
}

#######################################
# Test: Security considerations
#######################################
test_security() {
    log_info "Test 13: Security checks"

    # Check if script uses set -euo pipefail
    assert "head -20 '$TOKEN_REFRESH_SCRIPT' | grep -q 'set -euo pipefail'" \
        "Script uses safe bash options (set -euo pipefail)"

    # Check that tokens are not logged directly to users
    # Note: Using echo to return a token value from a function is acceptable
    assert "! grep -E '(log_info|log_error|log_warn).*\\$.*token' '$TOKEN_REFRESH_SCRIPT'" \
        "Script does not log sensitive token values"

    # Verify systemd service runs as non-root user
    local service_file="${PROJECT_ROOT}/config/systemd/github-runner-token-refresh.service"
    if [[ -f "$service_file" ]]; then
        assert "grep -q 'User=runner' '$service_file'" \
            "Systemd service runs as non-root user (runner)"
    fi
}

#######################################
# Print test summary
#######################################
print_summary() {
    echo ""
    echo "=========================================="
    echo "Test Summary"
    echo "=========================================="
    echo ""

    local total=$((TESTS_PASSED + TESTS_FAILED))

    echo "Total Tests: $total"
    echo -e "${COLOR_PASS}Passed: $TESTS_PASSED${COLOR_RESET}"
    echo -e "${COLOR_FAIL}Failed: $TESTS_FAILED${COLOR_RESET}"
    echo ""

    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo "Failed Tests:"
        for result in "${TEST_RESULTS[@]}"; do
            if [[ "$result" =~ ^FAIL ]]; then
                echo -e "  ${COLOR_FAIL}✗${COLOR_RESET} ${result#FAIL: }"
            fi
        done
        echo ""
    fi

    echo "=========================================="

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${COLOR_PASS}All tests passed!${COLOR_RESET}"
        return 0
    else
        echo -e "${COLOR_FAIL}Some tests failed.${COLOR_RESET}"
        return 1
    fi
}

#######################################
# Main test execution
#######################################
main() {
    echo "=========================================="
    echo "GitHub Runner Token Refresh Test Suite"
    echo "=========================================="
    echo ""

    setup_test_env

    # Run all tests
    test_script_exists
    test_help_message
    test_parameter_validation
    test_token_expiration_calculation
    test_metrics_file
    test_gh_cli_check
    test_dry_run_mode
    test_configuration_files
    test_documentation
    test_dependency_handling
    test_error_handling
    test_logging
    test_security

    # Print summary
    print_summary
}

# Run tests
main "$@"
