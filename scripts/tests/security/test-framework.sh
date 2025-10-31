#!/usr/bin/env bash
# Script: test-framework.sh
# Description: Security testing framework with assertion helpers
# Usage: source scripts/tests/security/test-framework.sh

set -euo pipefail

# Test framework configuration
readonly TEST_FRAMEWORK_VERSION="1.0.0"
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0
TEST_START_TIME=""
CURRENT_TEST_NAME=""
VERBOSE_OUTPUT="${VERBOSE_OUTPUT:-false}"

# Colors for output
if [[ -t 1 ]]; then
    readonly COLOR_RED='\033[0;31m'
    readonly COLOR_GREEN='\033[0;32m'
    readonly COLOR_YELLOW='\033[0;33m'
    readonly COLOR_BLUE='\033[0;34m'
    readonly COLOR_CYAN='\033[0;36m'
    readonly COLOR_BOLD='\033[1m'
    readonly COLOR_RESET='\033[0m'
else
    readonly COLOR_RED=''
    readonly COLOR_GREEN=''
    readonly COLOR_YELLOW=''
    readonly COLOR_BLUE=''
    readonly COLOR_CYAN=''
    readonly COLOR_BOLD=''
    readonly COLOR_RESET=''
fi

# Get script directory
get_script_dir() {
    local source="${BASH_SOURCE[0]}"
    while [ -h "$source" ]; do
        local dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ $source != /* ]] && source="$dir/$source"
    done
    cd -P "$(dirname "$source")" && pwd
}

readonly SCRIPT_DIR="$(get_script_dir)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Logging functions
log_test_info() {
    if [[ "$VERBOSE_OUTPUT" == "true" ]]; then
        echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*" >&2
    fi
}

log_test_debug() {
    if [[ "$VERBOSE_OUTPUT" == "true" ]]; then
        echo -e "${COLOR_CYAN}[DEBUG]${COLOR_RESET} $*" >&2
    fi
}

log_test_warn() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $*" >&2
}

log_test_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2
}

log_test_success() {
    echo -e "${COLOR_GREEN}[PASS]${COLOR_RESET} $*"
}

log_test_fail() {
    echo -e "${COLOR_RED}[FAIL]${COLOR_RESET} $*"
}

log_test_skip() {
    echo -e "${COLOR_YELLOW}[SKIP]${COLOR_RESET} $*"
}

# Test lifecycle functions
test_suite_start() {
    local suite_name="$1"
    echo ""
    echo -e "${COLOR_BOLD}${COLOR_BLUE}========================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}Test Suite: ${suite_name}${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_BLUE}========================================${COLOR_RESET}"
    echo ""
    TEST_START_TIME=$(date +%s)
}

test_suite_end() {
    local suite_name="$1"
    local end_time=$(date +%s)
    local duration=$((end_time - TEST_START_TIME))
    local total_tests=$((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))

    echo ""
    echo -e "${COLOR_BOLD}${COLOR_BLUE}========================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}Test Suite Summary: ${suite_name}${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_BLUE}========================================${COLOR_RESET}"
    echo ""
    echo -e "Total Tests:   ${total_tests}"
    echo -e "${COLOR_GREEN}Passed:        ${TESTS_PASSED}${COLOR_RESET}"
    echo -e "${COLOR_RED}Failed:        ${TESTS_FAILED}${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}Skipped:       ${TESTS_SKIPPED}${COLOR_RESET}"
    echo -e "Duration:      ${duration}s"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${COLOR_GREEN}${COLOR_BOLD}All tests passed!${COLOR_RESET}"
        return 0
    else
        echo -e "${COLOR_RED}${COLOR_BOLD}Some tests failed!${COLOR_RESET}"
        return 1
    fi
}

test_start() {
    local test_name="$1"
    CURRENT_TEST_NAME="$test_name"
    log_test_info "Running: $test_name"
}

test_pass() {
    local test_name="${1:-$CURRENT_TEST_NAME}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    log_test_success "$test_name"
}

test_fail() {
    local test_name="${1:-$CURRENT_TEST_NAME}"
    local reason="${2:-No reason provided}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    log_test_fail "$test_name"
    log_test_error "  Reason: $reason"
}

test_skip() {
    local test_name="${1:-$CURRENT_TEST_NAME}"
    local reason="${2:-No reason provided}"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
    log_test_skip "$test_name"
    log_test_info "  Reason: $reason"
}

# Assertion functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Expected '$expected' but got '$actual'}"

    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
        log_test_error "$message"
        return 1
    fi
}

assert_not_equals() {
    local unexpected="$1"
    local actual="$2"
    local message="${3:-Expected value to not equal '$unexpected'}"

    if [[ "$unexpected" != "$actual" ]]; then
        return 0
    else
        log_test_error "$message"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-Expected string to contain '$needle'}"

    if [[ "$haystack" == *"$needle"* ]]; then
        return 0
    else
        log_test_error "$message"
        log_test_debug "  Haystack: $haystack"
        return 1
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-Expected string to not contain '$needle'}"

    if [[ "$haystack" != *"$needle"* ]]; then
        return 0
    else
        log_test_error "$message"
        log_test_debug "  Haystack: $haystack"
        return 1
    fi
}

assert_matches() {
    local text="$1"
    local pattern="$2"
    local message="${3:-Expected text to match pattern '$pattern'}"

    if [[ "$text" =~ $pattern ]]; then
        return 0
    else
        log_test_error "$message"
        log_test_debug "  Text: $text"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-Expected file to exist: $file}"

    if [[ -f "$file" ]]; then
        return 0
    else
        log_test_error "$message"
        return 1
    fi
}

assert_file_not_exists() {
    local file="$1"
    local message="${2:-Expected file to not exist: $file}"

    if [[ ! -f "$file" ]]; then
        return 0
    else
        log_test_error "$message"
        return 1
    fi
}

assert_file_contains() {
    local file="$1"
    local pattern="$2"
    local message="${3:-Expected file '$file' to contain '$pattern'}"

    if [[ ! -f "$file" ]]; then
        log_test_error "File not found: $file"
        return 1
    fi

    if grep -q "$pattern" "$file" 2>/dev/null; then
        return 0
    else
        log_test_error "$message"
        return 1
    fi
}

assert_file_not_contains() {
    local file="$1"
    local pattern="$2"
    local message="${3:-Expected file '$file' to not contain '$pattern'}"

    if [[ ! -f "$file" ]]; then
        log_test_error "File not found: $file"
        return 1
    fi

    if ! grep -q "$pattern" "$file" 2>/dev/null; then
        return 0
    else
        log_test_error "$message"
        return 1
    fi
}

assert_command_success() {
    local message="${1:-Command should succeed}"
    shift

    if "$@" &>/dev/null; then
        return 0
    else
        log_test_error "$message"
        log_test_debug "  Command: $*"
        return 1
    fi
}

assert_command_fails() {
    local message="${1:-Command should fail}"
    shift

    if ! "$@" &>/dev/null; then
        return 0
    else
        log_test_error "$message"
        log_test_debug "  Command: $*"
        return 1
    fi
}

assert_exit_code() {
    local expected_code="$1"
    local message="${2:-Expected exit code $expected_code}"
    shift 2

    local actual_code=0
    "$@" &>/dev/null || actual_code=$?

    if [[ $actual_code -eq $expected_code ]]; then
        return 0
    else
        log_test_error "$message (got $actual_code)"
        log_test_debug "  Command: $*"
        return 1
    fi
}

assert_true() {
    local condition="$1"
    local message="${2:-Expected condition to be true}"

    if [[ "$condition" == "true" ]] || [[ "$condition" == "0" ]]; then
        return 0
    else
        log_test_error "$message"
        return 1
    fi
}

assert_false() {
    local condition="$1"
    local message="${2:-Expected condition to be false}"

    if [[ "$condition" == "false" ]] || [[ "$condition" != "0" ]]; then
        return 0
    else
        log_test_error "$message"
        return 1
    fi
}

# Security-specific assertion functions
assert_no_secrets_in_output() {
    local output="$1"
    local message="${2:-Output should not contain secrets}"

    # Check for common secret patterns
    local secret_patterns=(
        'ghp_[a-zA-Z0-9]{36}'           # GitHub PAT
        'gho_[a-zA-Z0-9]{36}'           # GitHub OAuth
        'ghs_[a-zA-Z0-9]{36}'           # GitHub App
        'github_pat_[a-zA-Z0-9_]{82}'   # Fine-grained PAT
        '[A-Za-z0-9+/]{40,}={0,2}'      # Base64 encoded secrets
        'AKIA[0-9A-Z]{16}'              # AWS Access Key
        'sk_live_[0-9a-zA-Z]{24,}'      # Stripe
    )

    for pattern in "${secret_patterns[@]}"; do
        if [[ "$output" =~ $pattern ]]; then
            log_test_error "$message"
            log_test_error "  Detected pattern: $pattern"
            return 1
        fi
    done

    return 0
}

assert_secure_file_permissions() {
    local file="$1"
    local expected_perms="${2:-600}"
    local message="${3:-File should have secure permissions}"

    if [[ ! -f "$file" ]]; then
        log_test_error "File not found: $file"
        return 1
    fi

    local actual_perms=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%Lp" "$file" 2>/dev/null)

    if [[ "$actual_perms" == "$expected_perms" ]]; then
        return 0
    else
        log_test_error "$message"
        log_test_error "  Expected: $expected_perms, Got: $actual_perms"
        return 1
    fi
}

assert_no_eval_in_file() {
    local file="$1"
    local message="${2:-File should not contain 'eval' statements}"

    if [[ ! -f "$file" ]]; then
        log_test_error "File not found: $file"
        return 1
    fi

    # Look for eval usage (excluding safe patterns like yq eval)
    local eval_count=$(grep "\beval\b" "$file" 2>/dev/null | wc -l)
    local safe_eval_count=$(grep -E "yq eval|# Safe:" "$file" 2>/dev/null | wc -l)
    local dangerous_eval=$((eval_count - safe_eval_count))

    if [[ $dangerous_eval -eq 0 ]]; then
        return 0
    else
        log_test_error "$message"
        log_test_error "  Found $dangerous_eval dangerous eval statement(s)"
        return 1
    fi
}

assert_input_validated() {
    local script="$1"
    local input_var="$2"
    local message="${3:-Script should validate input: $input_var}"

    if [[ ! -f "$script" ]]; then
        log_test_error "Script not found: $script"
        return 1
    fi

    # Check for validation patterns
    if grep -q "validate.*${input_var}\|${input_var}.*validate\|if.*${input_var}.*then" "$script" 2>/dev/null; then
        return 0
    else
        log_test_error "$message"
        return 1
    fi
}

# Mock functions for testing
mock_command() {
    local cmd_name="$1"
    local mock_output="$2"
    local mock_exit_code="${3:-0}"

    # Create a mock function
    eval "${cmd_name}() { echo '${mock_output}'; return ${mock_exit_code}; }"
    export -f "${cmd_name}"
}

mock_file() {
    local file_path="$1"
    local content="$2"

    mkdir -p "$(dirname "$file_path")"
    echo "$content" > "$file_path"
}

# Cleanup functions
cleanup_test_files() {
    local pattern="${1:-/tmp/test-*}"
    rm -f $pattern 2>/dev/null || true
}

cleanup_test_dirs() {
    local pattern="${1:-/tmp/test-dir-*}"
    rm -rf $pattern 2>/dev/null || true
}

# Test runner function
run_test() {
    local test_function="$1"
    local test_name="${2:-$test_function}"

    test_start "$test_name"

    if "$test_function"; then
        test_pass "$test_name"
        return 0
    else
        test_fail "$test_name" "Test function returned non-zero"
        return 1
    fi
}

# Export functions for use in test scripts
export -f get_script_dir
export -f log_test_info log_test_debug log_test_warn log_test_error
export -f log_test_success log_test_fail log_test_skip
export -f test_suite_start test_suite_end test_start test_pass test_fail test_skip
export -f assert_equals assert_not_equals assert_contains assert_not_contains
export -f assert_matches assert_file_exists assert_file_not_exists
export -f assert_file_contains assert_file_not_contains
export -f assert_command_success assert_command_fails assert_exit_code
export -f assert_true assert_false
export -f assert_no_secrets_in_output assert_secure_file_permissions
export -f assert_no_eval_in_file assert_input_validated
export -f mock_command mock_file
export -f cleanup_test_files cleanup_test_dirs
export -f run_test

log_test_info "Test framework v${TEST_FRAMEWORK_VERSION} loaded"
