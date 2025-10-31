#!/usr/bin/env bash
# Script: run-unit-tests.sh
# Description: Master test runner for all unit tests
# Usage: ./run-unit-tests.sh [--verbose] [--coverage]

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Configuration
VERBOSE=0
GENERATE_COVERAGE=0
TEST_RESULTS_DIR="${SCRIPT_DIR}/results"
COVERAGE_REPORT="${TEST_RESULTS_DIR}/coverage-report.txt"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose|-v)
            VERBOSE=1
            shift
            ;;
        --coverage|-c)
            GENERATE_COVERAGE=1
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--verbose] [--coverage]"
            echo ""
            echo "Options:"
            echo "  --verbose, -v    Enable verbose output"
            echo "  --coverage, -c   Generate coverage report"
            echo "  --help, -h       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Create results directory
mkdir -p "${TEST_RESULTS_DIR}"

# Colors
if [[ "${TERM:-}" == "dumb" ]] || [[ ! -t 1 ]]; then
    COLOR_GREEN=''
    COLOR_RED=''
    COLOR_YELLOW=''
    COLOR_BLUE=''
    COLOR_RESET=''
else
    COLOR_GREEN='\033[0;32m'
    COLOR_RED='\033[0;31m'
    COLOR_YELLOW='\033[0;33m'
    COLOR_BLUE='\033[0;34m'
    COLOR_RESET='\033[0m'
fi

# Print header
echo "=========================================="
echo "Running Unit Tests"
echo "=========================================="
echo ""

# Find all test files
TEST_FILES=()
while IFS= read -r -d '' file; do
    TEST_FILES+=("${file}")
done < <(find "${SCRIPT_DIR}/unit" -name "test-*.sh" -type f -print0 | sort -z)

if [[ ${#TEST_FILES[@]} -eq 0 ]]; then
    echo -e "${COLOR_RED}No test files found${COLOR_RESET}"
    exit 1
fi

echo "Found ${#TEST_FILES[@]} test suite(s)"
echo ""

# Track overall results
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

# Run each test file
for test_file in "${TEST_FILES[@]}"; do
    TOTAL_SUITES=$((TOTAL_SUITES + 1))

    test_name=$(basename "${test_file}")
    echo -e "${COLOR_BLUE}Running: ${test_name}${COLOR_RESET}"
    echo "----------------------------------------"

    # Run test and capture output
    if [[ ${VERBOSE} -eq 1 ]]; then
        if bash "${test_file}"; then
            PASSED_SUITES=$((PASSED_SUITES + 1))
            echo -e "${COLOR_GREEN}✓ ${test_name} PASSED${COLOR_RESET}"
        else
            FAILED_SUITES=$((FAILED_SUITES + 1))
            echo -e "${COLOR_RED}✗ ${test_name} FAILED${COLOR_RESET}"
        fi
    else
        output_file="${TEST_RESULTS_DIR}/${test_name}.log"
        if bash "${test_file}" > "${output_file}" 2>&1; then
            PASSED_SUITES=$((PASSED_SUITES + 1))
            echo -e "${COLOR_GREEN}✓ ${test_name} PASSED${COLOR_RESET}"

            # Show summary line from output
            if grep -q "Test Summary" "${output_file}"; then
                grep -A 5 "Test Summary" "${output_file}" | grep -E "(Total|Passed|Failed|Skipped):" || true
            fi
        else
            FAILED_SUITES=$((FAILED_SUITES + 1))
            echo -e "${COLOR_RED}✗ ${test_name} FAILED${COLOR_RESET}"

            # Show failure output
            echo ""
            echo "Error output:"
            tail -n 20 "${output_file}" || true
        fi
    fi

    echo ""
done

# Print overall summary
echo "=========================================="
echo "Overall Test Summary"
echo "=========================================="
echo "Total Suites:  ${TOTAL_SUITES}"
echo -e "Passed:        ${COLOR_GREEN}${PASSED_SUITES}${COLOR_RESET}"
echo -e "Failed:        ${COLOR_RED}${FAILED_SUITES}${COLOR_RESET}"
echo "=========================================="

# Generate coverage report if requested
if [[ ${GENERATE_COVERAGE} -eq 1 ]]; then
    echo ""
    echo "Generating coverage report..."
    "${SCRIPT_DIR}/generate-coverage.sh" > "${COVERAGE_REPORT}"

    echo -e "${COLOR_BLUE}Coverage report saved to: ${COVERAGE_REPORT}${COLOR_RESET}"
    echo ""
    cat "${COVERAGE_REPORT}"
fi

# Exit with appropriate code
if [[ ${FAILED_SUITES} -eq 0 ]]; then
    echo -e "${COLOR_GREEN}ALL TESTS PASSED${COLOR_RESET}"
    exit 0
else
    echo -e "${COLOR_RED}SOME TESTS FAILED${COLOR_RESET}"
    exit 1
fi
