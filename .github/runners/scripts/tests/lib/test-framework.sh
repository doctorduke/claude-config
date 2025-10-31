#!/usr/bin/env bash
# Script: test-framework.sh
# Description: Core testing framework with assertion library and test runner
# Usage: source "${SCRIPT_DIR}/tests/lib/test-framework.sh"

# Test framework configuration
TEST_RESULTS_DIR="${TEST_RESULTS_DIR:-${PWD}/test-results}"
TEST_TEMP_DIR="${TEST_TEMP_DIR:-${TMPDIR:-/tmp}/test-$$}"
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0
CURRENT_TEST_FILE=""
CURRENT_TEST_SUITE=""

# Color output for test results
if [[ "${TERM:-}" == "dumb" ]] || [[ ! -t 1 ]]; then
    TEST_COLOR_GREEN=''
    TEST_COLOR_RED=''
    TEST_COLOR_YELLOW=''
    TEST_COLOR_BLUE=''
    TEST_COLOR_RESET=''
else
    TEST_COLOR_GREEN='\033[0;32m'
    TEST_COLOR_RED='\033[0;31m'
    TEST_COLOR_YELLOW='\033[0;33m'
    TEST_COLOR_BLUE='\033[0;34m'
    TEST_COLOR_RESET='\033[0m'
fi

# Initialize test framework
init_test_framework() {
    mkdir -p "${TEST_RESULTS_DIR}"
    mkdir -p "${TEST_TEMP_DIR}"

    # Reset counters
    TESTS_PASSED=0
    TESTS_FAILED=0
    TESTS_SKIPPED=0
}

# Cleanup test framework
cleanup_test_framework() {
    # Clean up temp directory
    if [[ -d "${TEST_TEMP_DIR}" ]]; then
        rm -rf "${TEST_TEMP_DIR}"
    fi
}

# Start a test suite
start_test_suite() {
    local suite_name="$1"
    CURRENT_TEST_SUITE="${suite_name}"
    echo -e "${TEST_COLOR_BLUE}=== Test Suite: ${suite_name} ===${TEST_COLOR_RESET}"
}

# End a test suite
end_test_suite() {
    echo ""
}

# Run a single test
run_test() {
    local test_name="$1"
    local test_function="$2"

    # Create temp files for output capture
    local stdout_file="${TEST_TEMP_DIR}/stdout.$$"
    local stderr_file="${TEST_TEMP_DIR}/stderr.$$"

    # Run the test and capture output
    if "${test_function}" > "${stdout_file}" 2> "${stderr_file}"; then
        echo -e "  ${TEST_COLOR_GREEN}✓${TEST_COLOR_RESET} ${test_name}"
        ((TESTS_PASSED++))
        rm -f "${stdout_file}" "${stderr_file}"
        return 0
    else
        echo -e "  ${TEST_COLOR_RED}✗${TEST_COLOR_RESET} ${test_name}"

        # Show captured output on failure for debugging
        if [[ -s "${stdout_file}" ]]; then
            echo "    stdout:" >&2
            sed 's/^/      /' "${stdout_file}" >&2
        fi
        if [[ -s "${stderr_file}" ]]; then
            echo "    stderr:" >&2
            sed 's/^/      /' "${stderr_file}" >&2
        fi

        ((TESTS_FAILED++))
        rm -f "${stdout_file}" "${stderr_file}"
        return 1
    fi
}

# Skip a test
skip_test() {
    local test_name="$1"
    local reason="${2:-No reason provided}"

    echo -e "  ${TEST_COLOR_YELLOW}⊘${TEST_COLOR_RESET} ${test_name} (skipped: ${reason})"
    ((TESTS_SKIPPED++))
}

# Print test summary
print_test_summary() {
    local total=$((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))

    echo ""
    echo "=========================================="
    echo "Test Summary"
    echo "=========================================="
    echo -e "Total:   ${total}"
    echo -e "Passed:  ${TEST_COLOR_GREEN}${TESTS_PASSED}${TEST_COLOR_RESET}"
    echo -e "Failed:  ${TEST_COLOR_RED}${TESTS_FAILED}${TEST_COLOR_RESET}"
    echo -e "Skipped: ${TEST_COLOR_YELLOW}${TESTS_SKIPPED}${TEST_COLOR_RESET}"
    echo "=========================================="

    if [[ ${TESTS_FAILED} -gt 0 ]]; then
        echo -e "${TEST_COLOR_RED}FAILED${TEST_COLOR_RESET}"
        return 1
    else
        echo -e "${TEST_COLOR_GREEN}PASSED${TEST_COLOR_RESET}"
        return 0
    fi
}

# ============================================================
# Assertion Functions
# ============================================================

# Assert that a command succeeds
assert_success() {
    if [[ $? -ne 0 ]]; then
        echo "ASSERTION FAILED: Expected success but got failure" >&2
        return 1
    fi
    return 0
}

# Assert that a command fails
assert_failure() {
    if [[ $? -eq 0 ]]; then
        echo "ASSERTION FAILED: Expected failure but got success" >&2
        return 1
    fi
    return 0
}

# Assert command succeeds
assert_command_success() {
    local cmd=("$@")

    if ! "${cmd[@]}" &>/dev/null; then
        echo "ASSERTION FAILED: Command failed: ${cmd[*]}" >&2
        return 1
    fi
    return 0
}

# Assert command fails
assert_command_fails() {
    local cmd=("$@")

    if "${cmd[@]}" &>/dev/null; then
        echo "ASSERTION FAILED: Command succeeded but should have failed: ${cmd[*]}" >&2
        return 1
    fi
    return 0
}

# Assert equals
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"

    if [[ "${actual}" != "${expected}" ]]; then
        echo "ASSERTION FAILED: Expected '${expected}' but got '${actual}'" >&2
        if [[ -n "${message}" ]]; then
            echo "  ${message}" >&2
        fi
        return 1
    fi
    return 0
}

# Assert not equals
assert_not_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"

    if [[ "${actual}" == "${expected}" ]]; then
        echo "ASSERTION FAILED: Expected not to equal '${expected}'" >&2
        if [[ -n "${message}" ]]; then
            echo "  ${message}" >&2
        fi
        return 1
    fi
    return 0
}

# Assert contains
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-}"

    if [[ "${haystack}" != *"${needle}"* ]]; then
        echo "ASSERTION FAILED: Expected to contain '${needle}'" >&2
        echo "  In: ${haystack}" >&2
        if [[ -n "${message}" ]]; then
            echo "  ${message}" >&2
        fi
        return 1
    fi
    return 0
}

# Assert not contains
assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-}"

    if [[ "${haystack}" == *"${needle}"* ]]; then
        echo "ASSERTION FAILED: Expected not to contain '${needle}'" >&2
        echo "  In: ${haystack}" >&2
        if [[ -n "${message}" ]]; then
            echo "  ${message}" >&2
        fi
        return 1
    fi
    return 0
}

# Assert matches regex
assert_matches() {
    local text="$1"
    local pattern="$2"
    local message="${3:-}"

    if [[ ! "${text}" =~ ${pattern} ]]; then
        echo "ASSERTION FAILED: Expected to match pattern '${pattern}'" >&2
        echo "  Text: ${text}" >&2
        if [[ -n "${message}" ]]; then
            echo "  ${message}" >&2
        fi
        return 1
    fi
    return 0
}

# Assert not matches regex
assert_not_matches() {
    local text="$1"
    local pattern="$2"
    local message="${3:-}"

    if [[ "${text}" =~ ${pattern} ]]; then
        echo "ASSERTION FAILED: Expected not to match pattern '${pattern}'" >&2
        echo "  Text: ${text}" >&2
        if [[ -n "${message}" ]]; then
            echo "  ${message}" >&2
        fi
        return 1
    fi
    return 0
}

# Assert null (empty)
assert_null() {
    local value="$1"
    local message="${2:-}"

    if [[ -n "${value}" ]]; then
        echo "ASSERTION FAILED: Expected empty but got '${value}'" >&2
        if [[ -n "${message}" ]]; then
            echo "  ${message}" >&2
        fi
        return 1
    fi
    return 0
}

# Assert not null (not empty)
assert_not_null() {
    local value="$1"
    local message="${2:-}"

    if [[ -z "${value}" ]]; then
        echo "ASSERTION FAILED: Expected non-empty value" >&2
        if [[ -n "${message}" ]]; then
            echo "  ${message}" >&2
        fi
        return 1
    fi
    return 0
}

# Assert true (0 exit code)
assert_true() {
    local cmd=("$@")

    if ! "${cmd[@]}" &>/dev/null; then
        echo "ASSERTION FAILED: Expected true but got false: ${cmd[*]}" >&2
        return 1
    fi
    return 0
}

# Assert false (non-zero exit code)
assert_false() {
    local cmd=("$@")

    if "${cmd[@]}" &>/dev/null; then
        echo "ASSERTION FAILED: Expected false but got true: ${cmd[*]}" >&2
        return 1
    fi
    return 0
}

# Assert file exists
assert_file_exists() {
    local file="$1"
    local message="${2:-}"

    if [[ ! -f "${file}" ]]; then
        echo "ASSERTION FAILED: File does not exist: ${file}" >&2
        if [[ -n "${message}" ]]; then
            echo "  ${message}" >&2
        fi
        return 1
    fi
    return 0
}

# Assert file not exists
assert_file_not_exists() {
    local file="$1"
    local message="${2:-}"

    if [[ -f "${file}" ]]; then
        echo "ASSERTION FAILED: File exists but should not: ${file}" >&2
        if [[ -n "${message}" ]]; then
            echo "  ${message}" >&2
        fi
        return 1
    fi
    return 0
}

# Assert directory exists
assert_dir_exists() {
    local dir="$1"
    local message="${2:-}"

    if [[ ! -d "${dir}" ]]; then
        echo "ASSERTION FAILED: Directory does not exist: ${dir}" >&2
        if [[ -n "${message}" ]]; then
            echo "  ${message}" >&2
        fi
        return 1
    fi
    return 0
}

# Assert exit code
assert_exit_code() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"

    if [[ ${actual} -ne ${expected} ]]; then
        echo "ASSERTION FAILED: Expected exit code ${expected} but got ${actual}" >&2
        if [[ -n "${message}" ]]; then
            echo "  ${message}" >&2
        fi
        return 1
    fi
    return 0
}

# Assert greater than
assert_greater_than() {
    local value="$1"
    local min="$2"
    local message="${3:-}"

    if [[ ${value} -le ${min} ]]; then
        echo "ASSERTION FAILED: Expected ${value} > ${min}" >&2
        if [[ -n "${message}" ]]; then
            echo "  ${message}" >&2
        fi
        return 1
    fi
    return 0
}

# Assert less than
assert_less_than() {
    local value="$1"
    local max="$2"
    local message="${3:-}"

    if [[ ${value} -ge ${max} ]]; then
        echo "ASSERTION FAILED: Expected ${value} < ${max}" >&2
        if [[ -n "${message}" ]]; then
            echo "  ${message}" >&2
        fi
        return 1
    fi
    return 0
}

# Export functions
export -f init_test_framework cleanup_test_framework
export -f start_test_suite end_test_suite run_test skip_test
export -f print_test_summary
export -f assert_success assert_failure
export -f assert_command_success assert_command_fails
export -f assert_equals assert_not_equals
export -f assert_contains assert_not_contains
export -f assert_matches assert_not_matches
export -f assert_null assert_not_null
export -f assert_true assert_false
export -f assert_file_exists assert_file_not_exists
export -f assert_dir_exists assert_exit_code
export -f assert_greater_than assert_less_than
