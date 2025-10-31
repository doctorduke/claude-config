#!/usr/bin/env bash
# Script: run-all-security-tests.sh
# Description: Master security test runner for all security tests
# Purpose: Run all security tests and generate comprehensive report
# Usage: bash run-all-security-tests.sh [--verbose] [--report-file <file>]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

VERBOSE_OUTPUT="${VERBOSE_OUTPUT:-false}"
REPORT_FILE="${REPORT_FILE:-}"
RUN_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DEFAULT_REPORT_FILE="${PROJECT_ROOT}/test-results/security-tests-${RUN_TIMESTAMP}.md"

while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v) VERBOSE_OUTPUT="true"; export VERBOSE_OUTPUT; shift ;;
        --report-file|-r) REPORT_FILE="$2"; shift 2 ;;
        --help|-h) echo "Usage: $0 [--verbose] [--report-file FILE]"; exit 0 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [[ -z "$REPORT_FILE" ]]; then
    REPORT_FILE="$DEFAULT_REPORT_FILE"
fi

mkdir -p "$(dirname "$REPORT_FILE")"

if [[ -t 1 ]]; then
    readonly COLOR_GREEN='\033[0;32m'
    readonly COLOR_RED='\033[0;31m'
    readonly COLOR_YELLOW='\033[0;33m'
    readonly COLOR_BLUE='\033[0;34m'
    readonly COLOR_BOLD='\033[1m'
    readonly COLOR_RESET='\033[0m'
else
    readonly COLOR_GREEN='' COLOR_RED='' COLOR_YELLOW='' COLOR_BLUE='' COLOR_BOLD='' COLOR_RESET=''
fi

declare -A TEST_SUITES=(
    ["Task #2: Secret Encryption"]="test-secret-encryption.sh"
    ["Task #3: Token Sanitization"]="test-token-sanitization.sh"
    ["Task #4: Temp File Security"]="test-temp-file-security.sh"
    ["Task #5: Input Validation"]="test-input-validation.sh"
    ["Task #6: No Eval Usage"]="test-no-eval.sh"
    ["Task #7: Secret Masking"]="test-secret-masking.sh"
    ["Task #8: PAT Protected Branches"]="test-pat-protected-branches.sh"
    ["OWASP Compliance"]="test-owasp-compliance.sh"
    ["Security Regression"]="test-security-regression.sh"
)

# Suite execution order (single source of truth)
declare -a SUITE_ORDER=(
    "Task #2: Secret Encryption"
    "Task #3: Token Sanitization"
    "Task #4: Temp File Security"
    "Task #5: Input Validation"
    "Task #6: No Eval Usage"
    "Task #7: Secret Masking"
    "Task #8: PAT Protected Branches"
    "OWASP Compliance"
    "Security Regression"
)

declare -A SUITE_RESULTS
TOTAL_SUITES=0 PASSED_SUITES=0 FAILED_SUITES=0
TOTAL_TESTS=0 PASSED_TESTS=0 FAILED_TESTS=0 SKIPPED_TESTS=0

print_header() {
    echo ""
    echo -e "${COLOR_BOLD}${COLOR_BLUE}=======================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}  Security Test Suite - Task #16${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_BLUE}=======================================${COLOR_RESET}"
    echo ""
    echo "Start Time: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Report: ${REPORT_FILE}"
    echo ""
}

run_test_suite() {
    local suite_name="$1"
    local test_file="$2"
    local test_path="${SCRIPT_DIR}/${test_file}"

    TOTAL_SUITES=$((TOTAL_SUITES + 1))

    echo ""
    echo -e "${COLOR_BOLD}Running: ${suite_name}${COLOR_RESET}"
    echo "----------------------------------------"

    if [[ ! -f "$test_path" ]]; then
        echo -e "${COLOR_RED}ERROR: Test file not found${COLOR_RESET}"
        SUITE_RESULTS["$suite_name"]="ERROR"
        FAILED_SUITES=$((FAILED_SUITES + 1))
        return 1
    fi

    chmod +x "$test_path"

    local output_file=$(mktemp)
    local exit_code=0

    if bash "$test_path" > "$output_file" 2>&1; then
        exit_code=0
    else
        exit_code=$?
    fi

    if [[ "$VERBOSE_OUTPUT" == "true" ]] || [[ $exit_code -ne 0 ]]; then
        cat "$output_file"
    fi

    local suite_passed=$(grep "\[PASS\]" "$output_file" 2>/dev/null | wc -l)
    local suite_failed=$(grep "\[FAIL\]" "$output_file" 2>/dev/null | wc -l)
    local suite_skipped=$(grep "\[SKIP\]" "$output_file" 2>/dev/null | wc -l)

    TOTAL_TESTS=$((TOTAL_TESTS + suite_passed + suite_failed + suite_skipped))
    PASSED_TESTS=$((PASSED_TESTS + suite_passed))
    FAILED_TESTS=$((FAILED_TESTS + suite_failed))
    SKIPPED_TESTS=$((SKIPPED_TESTS + suite_skipped))

    if [[ $exit_code -eq 0 ]]; then
        echo -e "${COLOR_GREEN}✓ PASSED${COLOR_RESET}"
        SUITE_RESULTS["$suite_name"]="PASSED ($suite_passed/$((suite_passed + suite_failed + suite_skipped)) tests)"
        PASSED_SUITES=$((PASSED_SUITES + 1))
    else
        echo -e "${COLOR_RED}✗ FAILED${COLOR_RESET}"
        SUITE_RESULTS["$suite_name"]="FAILED ($suite_failed failures)"
        FAILED_SUITES=$((FAILED_SUITES + 1))
    fi

    rm -f "$output_file"
    return $exit_code
}

generate_report() {
    cat > "$REPORT_FILE" <<EOFREPORT
# Security Test Report - Task #16

**Date:** $(date '+%Y-%m-%d %H:%M:%S')
**Project:** GitHub Actions Self-Hosted Runner System

## Executive Summary

- Total Test Suites: $TOTAL_SUITES
- Passed Suites: $PASSED_SUITES
- Failed Suites: $FAILED_SUITES

- Total Tests: $TOTAL_TESTS
- Passed: $PASSED_TESTS
- Failed: $FAILED_TESTS
- Skipped: $SKIPPED_TESTS

**Status:** $(if [[ $FAILED_SUITES -eq 0 ]]; then echo "✅ ALL PASSED"; else echo "❌ FAILURES"; fi)

## Test Results

EOFREPORT

    # Use global SUITE_ORDER array to avoid duplication
    for suite_name in "${SUITE_ORDER[@]}"; do
        local result="${SUITE_RESULTS[$suite_name]}"
        local status="✅"
        [[ "$result" == FAILED* ]] || [[ "$result" == ERROR* ]] && status="❌"
        echo "### $status $suite_name: $result" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    done

    echo -e "\n${COLOR_GREEN}Report: ${REPORT_FILE}${COLOR_RESET}"
}

print_summary() {
    echo ""
    echo -e "${COLOR_BOLD}${COLOR_BLUE}=======================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}  Summary${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_BLUE}=======================================${COLOR_RESET}"
    echo ""
    echo "Suites: $PASSED_SUITES passed, $FAILED_SUITES failed (total: $TOTAL_SUITES)"
    echo "Tests: $PASSED_TESTS passed, $FAILED_TESTS failed, $SKIPPED_TESTS skipped"
    echo ""

    if [[ $FAILED_SUITES -eq 0 ]]; then
        echo -e "${COLOR_GREEN}${COLOR_BOLD}✓ ALL TESTS PASSED${COLOR_RESET}"
        return 0
    else
        echo -e "${COLOR_RED}${COLOR_BOLD}✗ SOME TESTS FAILED${COLOR_RESET}"
        return 1
    fi
}

main() {
    print_header

    # Use global SUITE_ORDER array
    for suite_name in "${SUITE_ORDER[@]}"; do
        run_test_suite "$suite_name" "${TEST_SUITES[$suite_name]}" || true
    done

    generate_report
    print_summary
}

main "$@"
