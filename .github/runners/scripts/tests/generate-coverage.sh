#!/usr/bin/env bash
# Script: generate-coverage.sh
# Description: Generate code coverage report for unit tests
# Usage: ./generate-coverage.sh

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ============================================================
# Function Coverage Analysis
# ============================================================

echo "=========================================="
echo "Code Coverage Report"
echo "=========================================="
echo ""
echo "Generated: $(date)"
echo ""

# Analyze common.sh coverage
analyze_common_coverage() {
    local lib_file="${ROOT_DIR}/lib/common.sh"

    echo "File: scripts/lib/common.sh"
    echo "----------------------------------------"

    # Extract all function names from common.sh
    local all_functions=()
    while IFS= read -r func; do
        all_functions+=("${func}")
    done < <(grep -E '^[a-zA-Z_][a-zA-Z0-9_]*\(\)' "${lib_file}" | sed 's/().*$//' | sort -u)

    local total_functions=${#all_functions[@]}

    # Find tested functions by searching test files
    local tested_functions=()
    for func in "${all_functions[@]}"; do
        # Search for actual function calls (not just mentions in comments)
        # Look for patterns like: func, $(func, or ${func}
        if grep -rE "(^|[^a-zA-Z0-9_])(${func}[[:space:]]*\(|\$\{${func}|\$\(${func})" "${SCRIPT_DIR}/unit/" 2>/dev/null | grep -v "^[[:space:]]*#" >/dev/null; then
            tested_functions+=("${func}")
        fi
    done

    local tested_count=${#tested_functions[@]}
    local untested_count=$((total_functions - tested_count))

    # Calculate percentage
    local coverage_pct=0
    if [[ ${total_functions} -gt 0 ]]; then
        coverage_pct=$((tested_count * 100 / total_functions))
    fi

    echo "Total Functions:    ${total_functions}"
    echo "Tested Functions:   ${tested_count}"
    echo "Untested Functions: ${untested_count}"
    echo "Coverage:           ${coverage_pct}%"
    echo ""

    # List tested functions
    echo "Tested Functions:"
    for func in "${tested_functions[@]}"; do
        echo "  ✓ ${func}"
    done
    echo ""

    # List untested functions
    if [[ ${untested_count} -gt 0 ]]; then
        echo "Untested Functions:"
        for func in "${all_functions[@]}"; do
            if [[ ! " ${tested_functions[*]} " =~ " ${func} " ]]; then
                echo "  ✗ ${func}"
            fi
        done
        echo ""
    fi

    # Return coverage percentage
    echo "${coverage_pct}"
}

# Analyze test coverage by category
analyze_test_coverage() {
    echo "Test Coverage by Category"
    echo "----------------------------------------"

    local test_files=()
    while IFS= read -r -d '' file; do
        test_files+=("${file}")
    done < <(find "${SCRIPT_DIR}/unit" -name "test-*.sh" -type f -print0)

    for test_file in "${test_files[@]}"; do
        local test_name
        test_name=$(basename "${test_file}" .sh)

        # Count test functions
        local test_count
        test_count=$(grep -c "^test_" "${test_file}" || echo "0")

        # Count test suites
        local suite_count
        suite_count=$(grep -c "start_test_suite" "${test_file}" || echo "0")

        echo "${test_name}:"
        echo "  Test Suites: ${suite_count}"
        echo "  Test Cases:  ${test_count}"
    done
    echo ""
}

# Count total test cases
count_total_tests() {
    echo "Test Statistics"
    echo "----------------------------------------"

    local total_tests=0
    local total_suites=0

    while IFS= read -r -d '' file; do
        local tests
        tests=$(grep -c "^test_" "${file}" || echo "0")
        total_tests=$((total_tests + tests))

        local suites
        suites=$(grep -c "start_test_suite" "${file}" || echo "0")
        total_suites=$((total_suites + suites))
    done < <(find "${SCRIPT_DIR}/unit" -name "test-*.sh" -type f -print0)

    echo "Total Test Suites: ${total_suites}"
    echo "Total Test Cases:  ${total_tests}"
    echo ""
}

# Main coverage analysis
main() {
    # Generate coverage report
    local coverage_pct
    coverage_pct=$(analyze_common_coverage)

    analyze_test_coverage
    count_total_tests

    # Overall summary
    echo "=========================================="
    echo "Overall Coverage Summary"
    echo "=========================================="
    echo "scripts/lib/common.sh: ${coverage_pct}%"
    echo ""

    # Determine status
    if [[ ${coverage_pct} -ge 60 ]]; then
        echo "Status: ✓ Coverage target met (≥60%)"
    else
        echo "Status: ✗ Coverage below target (${coverage_pct}% < 60%)"
    fi
    echo ""

    # Recommendations
    echo "Recommendations:"
    if [[ ${coverage_pct} -lt 60 ]]; then
        echo "  - Add tests for untested functions"
        echo "  - Focus on edge cases and error paths"
        echo "  - Consider integration tests for complex flows"
    else
        echo "  - Maintain current coverage level"
        echo "  - Add tests for new functions"
        echo "  - Consider improving edge case coverage"
    fi
    echo ""
}

main "$@"
