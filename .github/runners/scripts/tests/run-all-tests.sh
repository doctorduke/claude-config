#!/bin/bash
# Master Test Runner
# Discovers and runs all tests in the test suite

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Default values
TEST_PARALLEL="${TEST_PARALLEL:-1}"
TEST_VERBOSE="${TEST_VERBOSE:-0}"
TEST_COVERAGE="${TEST_COVERAGE:-0}"
TEST_TIMEOUT="${TEST_TIMEOUT:-300}"
TEST_FILTER="${TEST_FILTER:-*}"
TEST_OUTPUT_FORMAT="${TEST_OUTPUT_FORMAT:-console}"  # console, tap, junit
TEST_OUTPUT_FILE="${TEST_OUTPUT_FILE:-}"
TEST_QUIET="${TEST_QUIET:-0}"

# Colors
readonly COLOR_RESET='\033[0m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_CYAN='\033[0;36m'

# Test statistics
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Run all tests in the test suite.

OPTIONS:
    -p, --parallel N        Run tests in parallel with N workers (default: 1)
    -f, --filter PATTERN    Run only tests matching pattern (default: *)
    -v, --verbose           Enable verbose output
    -q, --quiet             Suppress most output, only show failures
    -c, --coverage          Enable coverage tracking
    -t, --timeout SECONDS   Timeout per test (default: 300)
    -o, --output FORMAT     Output format: console, tap, junit (default: console)
    -O, --output-file FILE  Write output to file
    -h, --help              Show this help message

ENVIRONMENT VARIABLES:
    TEST_PARALLEL           Parallel workers (same as -p)
    TEST_VERBOSE            Verbose output (same as -v)
    TEST_COVERAGE           Enable coverage (same as -c)
    TEST_TIMEOUT            Per-test timeout (same as -t)
    TEST_FILTER             Filter pattern (same as -f)
    TEST_OUTPUT_FORMAT      Output format (same as -o)
    TEST_OUTPUT_FILE        Output file (same as -O)
    TEST_QUIET              Quiet mode (same as -q)

EXAMPLES:
    # Run all tests
    $0

    # Run tests in parallel
    $0 --parallel 4

    # Run only unit tests
    $0 --filter "unit/*"

    # Generate TAP output
    $0 --output tap --output-file results.tap

    # Run with coverage
    $0 --coverage

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--parallel)
                TEST_PARALLEL="$2"
                shift 2
                ;;
            -f|--filter)
                TEST_FILTER="$2"
                shift 2
                ;;
            -v|--verbose)
                TEST_VERBOSE=1
                shift
                ;;
            -q|--quiet)
                TEST_QUIET=1
                shift
                ;;
            -c|--coverage)
                TEST_COVERAGE=1
                shift
                ;;
            -t|--timeout)
                TEST_TIMEOUT="$2"
                shift 2
                ;;
            -o|--output)
                TEST_OUTPUT_FORMAT="$2"
                shift 2
                ;;
            -O|--output-file)
                TEST_OUTPUT_FILE="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                usage
                exit 1
                ;;
        esac
    done

    # Export for child processes
    export TEST_PARALLEL
    export TEST_VERBOSE
    export TEST_COVERAGE
    export TEST_TIMEOUT
    export TEST_FILTER
    export TEST_OUTPUT_FORMAT
    export TEST_QUIET
}

# Log message
log_runner() {
    local level="$1"
    shift
    local message="$*"

    [[ "$TEST_QUIET" == "1" ]] && [[ "$level" != "ERROR" ]] && [[ "$level" != "FAIL" ]] && return

    local color="$COLOR_RESET"
    case "$level" in
        INFO) color="$COLOR_BLUE" ;;
        PASS) color="$COLOR_GREEN" ;;
        FAIL) color="$COLOR_RED" ;;
        WARN) color="$COLOR_YELLOW" ;;
        ERROR) color="$COLOR_RED" ;;
    esac

    echo -e "${color}[${level}]${COLOR_RESET} $message" >&2
}

# Discover test files
discover_test_files() {
    local pattern="$1"
    local test_files=()

    # Find all test-*.sh files matching the pattern
    while IFS= read -r -d '' file; do
        # Check if file matches filter
        if [[ "$file" == *"$pattern"* ]] || [[ "$pattern" == "*" ]]; then
            test_files+=("$file")
        fi
    done < <(find "$SCRIPT_DIR" -name "test-*.sh" -type f -print0 | sort -z)

    printf '%s\n' "${test_files[@]}"
}

# Run a single test file
run_test_file() {
    local test_file="$1"
    local result_file="${2:-}"  # Optional: for parallel execution
    local test_name="$(basename "$test_file")"

    log_runner "INFO" "Running test suite: $test_name"

    # Run the test file
    local output
    local exit_code=0

    output=$(bash "$test_file" 2>&1) || exit_code=$?

    # Parse results from output (strip ANSI color codes first)
    # FORMAT CONTRACT: Test suites must output lines containing:
    #   "Passed: <number>"
    #   "Failed: <number>"
    #   "Skipped: <number>"
    # Alternative: Consider using a structured output file (JSON/CSV) for robustness
    local passed=0
    local failed=0
    local skipped=0
    local clean_output=$(echo "$output" | sed 's/\x1b\[[0-9;]*m//g')

    if echo "$clean_output" | grep -q "Passed:"; then
        passed=$(echo "$clean_output" | grep "Passed:" | grep -oE '[0-9]+' | head -1 || echo "0")
        failed=$(echo "$clean_output" | grep "Failed:" | grep -oE '[0-9]+' | head -1 || echo "0")
        skipped=$(echo "$clean_output" | grep -E "Skipped:" | grep -oE '[0-9]+' | head -1 || echo "0")
    fi

    # If result_file is provided (parallel mode), write to file instead of updating globals
    if [[ -n "$result_file" ]]; then
        # Format: passed,failed,skipped,exit_code
        echo "$passed,$failed,$skipped,$exit_code" > "$result_file"
        
        if [[ $exit_code -eq 0 ]]; then
            log_runner "PASS" "$test_name ($passed passed, $failed failed, $skipped skipped)"
        else
            log_runner "FAIL" "$test_name ($passed passed, $failed failed, $skipped skipped)"
            if [[ "$TEST_VERBOSE" == "1" ]]; then
                echo "$output" | sed 's/^/  /'
            fi
        fi
        return $exit_code
    fi

    # Sequential mode: update global statistics directly
    ((TOTAL_SUITES++))
    ((TOTAL_TESTS += passed + failed + skipped))
    ((PASSED_TESTS += passed))
    ((FAILED_TESTS += failed))
    ((SKIPPED_TESTS += skipped))

    if [[ $exit_code -eq 0 ]]; then
        ((PASSED_SUITES++))
        log_runner "PASS" "$test_name ($passed passed, $failed failed, $skipped skipped)"
        return 0
    else
        ((FAILED_SUITES++))
        log_runner "FAIL" "$test_name ($passed passed, $failed failed, $skipped skipped)"

        if [[ "$TEST_VERBOSE" == "1" ]]; then
            echo "$output" | sed 's/^/  /'
        fi

        return 1
    fi
}

# Run tests in parallel
run_tests_parallel() {
    local test_files=("$@")
    local pids=()
    local result_files=()
    local result_dir=$(mktemp -d)

    local max_parallel="$TEST_PARALLEL"
    local running=0
    local test_index=0

    for test_file in "${test_files[@]}"; do
        # Wait if we've reached max parallel
        while [[ $running -ge $max_parallel ]]; do
            for i in "${!pids[@]}"; do
                if ! kill -0 "${pids[$i]}" 2>/dev/null; then
                    wait "${pids[$i]}" || true
                    unset "pids[$i]"
                    ((running--))
                fi
            done
            sleep 0.1
        done

        # Create result file for this test
        local result_file="$result_dir/result_$test_index"
        result_files+=("$result_file")
        
        # Start test in background with result file
        run_test_file "$test_file" "$result_file" &
        pids+=($!)
        ((running++))
        ((test_index++))
    done

    # Wait for all remaining tests
    for pid in "${pids[@]}"; do
        wait "$pid" || true
    done

    # Aggregate results from temp files
    for result_file in "${result_files[@]}"; do
        if [[ -f "$result_file" ]]; then
            IFS=',' read -r passed failed skipped exit_code < "$result_file"
            ((TOTAL_SUITES++))
            ((TOTAL_TESTS += passed + failed + skipped))
            ((PASSED_TESTS += passed))
            ((FAILED_TESTS += failed))
            ((SKIPPED_TESTS += skipped))
            
            if [[ $exit_code -eq 0 ]]; then
                ((PASSED_SUITES++))
            else
                ((FAILED_SUITES++))
            fi
        fi
    done

    # Cleanup
    rm -rf "$result_dir"
}
# Run tests sequentially
run_tests_sequential() {
    local test_files=("$@")
    local failed_files=()

    for test_file in "${test_files[@]}"; do
        if ! run_test_file "$test_file"; then
            failed_files+=("$test_file")
        fi
    done

    return "${#failed_files[@]}"
}

# Generate coverage report
generate_coverage() {
    log_runner "INFO" "Generating coverage report..."

    local coverage_script="$SCRIPT_DIR/lib/coverage.sh"

    if [[ -f "$coverage_script" ]]; then
        bash "$coverage_script"
    else
        log_runner "WARN" "Coverage script not found: $coverage_script"
    fi
}

# Output results in TAP format
output_tap() {
    echo "TAP version 13"
    echo "1..$TOTAL_TESTS"

    local test_num=1
    # This is simplified - in a real implementation, we'd collect detailed test results
    for ((i=1; i<=PASSED_TESTS; i++)); do
        echo "ok $test_num - test passed"
        ((test_num++))
    done

    for ((i=1; i<=FAILED_TESTS; i++)); do
        echo "not ok $test_num - test failed"
        ((test_num++))
    done

    for ((i=1; i<=SKIPPED_TESTS; i++)); do
        echo "ok $test_num - test # SKIP"
        ((test_num++))
    done
}

# Output results in JUnit XML format
output_junit() {
    local timestamp="$(date -u +"%Y-%m-%dT%H:%M:%S")"
    local duration="${1:-0}"

    cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
  <testsuite name="All Tests" tests="$TOTAL_TESTS" failures="$FAILED_TESTS" skipped="$SKIPPED_TESTS" time="$duration" timestamp="$timestamp">
EOF

    # This is simplified - in a real implementation, we'd collect detailed test results
    for ((i=1; i<=PASSED_TESTS; i++)); do
        echo "    <testcase name=\"test_$i\" time=\"0\"/>"
    done

    for ((i=1; i<=FAILED_TESTS; i++)); do
        echo "    <testcase name=\"test_$i\" time=\"0\">"
        echo "      <failure message=\"Test failed\"/>"
        echo "    </testcase>"
    done

    for ((i=1; i<=SKIPPED_TESTS; i++)); do
        echo "    <testcase name=\"test_$i\" time=\"0\">"
        echo "      <skipped/>"
        echo "    </testcase>"
    done

    cat << EOF
  </testsuite>
</testsuites>
EOF
}

# Print summary
print_summary() {
    local duration="$1"

    echo ""
    echo "========================================"
    echo "           TEST SUMMARY"
    echo "========================================"
    echo ""
    echo "Test Suites:"
    echo "  Total:  $TOTAL_SUITES"
    echo -e "  ${COLOR_GREEN}Passed: $PASSED_SUITES${COLOR_RESET}"
    [[ $FAILED_SUITES -eq 0 ]] && echo "  Failed: $FAILED_SUITES" || echo -e "  ${COLOR_RED}Failed: $FAILED_SUITES${COLOR_RESET}"
    echo ""
    echo "Tests:"
    echo "  Total:  $TOTAL_TESTS"
    echo -e "  ${COLOR_GREEN}Passed: $PASSED_TESTS${COLOR_RESET}"
    [[ $FAILED_TESTS -eq 0 ]] && echo "  Failed: $FAILED_TESTS" || echo -e "  ${COLOR_RED}Failed: $FAILED_TESTS${COLOR_RESET}"
    [[ $SKIPPED_TESTS -gt 0 ]] && echo -e "  ${COLOR_YELLOW}Skipped: $SKIPPED_TESTS${COLOR_RESET}"
    echo ""
    echo "Duration: ${duration}s"
    echo "========================================"
}

# Main execution
main() {
    parse_args "$@"

    log_runner "INFO" "Starting test run..."
    log_runner "INFO" "Filter: $TEST_FILTER"
    [[ "$TEST_PARALLEL" -gt 1 ]] && log_runner "INFO" "Parallel workers: $TEST_PARALLEL"

    local start_time=$(date +%s)

    # Discover test files
    local test_files
    mapfile -t test_files < <(discover_test_files "$TEST_FILTER")

    if [[ ${#test_files[@]} -eq 0 ]]; then
        log_runner "ERROR" "No test files found matching pattern: $TEST_FILTER"
        exit 1
    fi

    log_runner "INFO" "Found ${#test_files[@]} test suite(s)"

    # Run tests
    if [[ "$TEST_PARALLEL" -gt 1 ]]; then
        run_tests_parallel "${test_files[@]}"
    else
        run_tests_sequential "${test_files[@]}"
    fi

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    # Generate coverage if requested
    if [[ "$TEST_COVERAGE" == "1" ]]; then
        generate_coverage
    fi

    # Output results
    case "$TEST_OUTPUT_FORMAT" in
        tap)
            local output="$(output_tap)"
            if [[ -n "$TEST_OUTPUT_FILE" ]]; then
                echo "$output" > "$TEST_OUTPUT_FILE"
                log_runner "INFO" "TAP output written to: $TEST_OUTPUT_FILE"
            else
                echo "$output"
            fi
            ;;
        junit)
            local output="$(output_junit "$duration")"
            if [[ -n "$TEST_OUTPUT_FILE" ]]; then
                echo "$output" > "$TEST_OUTPUT_FILE"
                log_runner "INFO" "JUnit output written to: $TEST_OUTPUT_FILE"
            else
                echo "$output"
            fi
            ;;
        console|*)
            print_summary "$duration"
            ;;
    esac

    # Exit with appropriate code
    if [[ $FAILED_TESTS -eq 0 && $FAILED_SUITES -eq 0 ]]; then
        log_runner "PASS" "All tests passed!"
        exit 0
    else
        log_runner "FAIL" "Some tests failed"
        exit 1
    fi
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
