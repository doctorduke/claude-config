#!/bin/bash
# Master E2E Test Runner
# Executes all end-to-end tests and generates comprehensive report

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source helpers
source "$SCRIPT_DIR/lib/test-helpers.sh"

# Test configuration
readonly REPORT_DIR="${REPORT_DIR:-./test-results/e2e}"
readonly REPORT_FILE="$REPORT_DIR/e2e-report-$(date +%Y%m%d-%H%M%S).txt"
readonly JSON_REPORT="$REPORT_DIR/e2e-report-$(date +%Y%m%d-%H%M%S).json"

# Test suites
readonly TEST_SUITES=(
    "test-pr-review-journey.sh:PR Review Journey"
    "test-issue-analysis-journey.sh:Issue Analysis Journey"
    "test-autofix-journey.sh:Auto-Fix Journey"
    "test-runner-lifecycle.sh:Runner Lifecycle"
    "test-failure-recovery.sh:Failure Recovery"
)

# Results tracking
SUITE_RESULTS=()
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
TOTAL_TIME=0

# ============================================================================
# Reporting Functions
# ============================================================================

# Initialize report directory
init_reports() {
    mkdir -p "$REPORT_DIR"

    echo "E2E Test Report" > "$REPORT_FILE"
    echo "Generated: $(date)" >> "$REPORT_FILE"
    echo "Repository: ${GH_REPO:-unknown}" >> "$REPORT_FILE"
    echo "============================================================================" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
}

# Record suite result
record_suite_result() {
    local suite_name="$1"
    local status="$2"
    local duration="$3"
    local details="$4"

    SUITE_RESULTS+=("$suite_name|$status|$duration|$details")

    if [[ "$status" == "PASS" ]]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    TOTAL_TIME=$((TOTAL_TIME + duration))
}

# Generate final report
generate_report() {
    echo ""
    echo "============================================================================"
    echo "E2E TEST SUMMARY"
    echo "============================================================================"

    local pass_rate=0
    if [[ $TOTAL_TESTS -gt 0 ]]; then
        pass_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    fi

    # Console output
    echo ""
    echo "Test Suites:"
    for result in "${SUITE_RESULTS[@]}"; do
        IFS='|' read -r name status duration details <<< "$result"

        if [[ "$status" == "PASS" ]]; then
            echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} $name (${duration}s)"
        else
            echo -e "  ${COLOR_RED}✗${COLOR_RESET} $name (${duration}s)"
            if [[ -n "$details" ]]; then
                echo "    Error: $details"
            fi
        fi
    done

    echo ""
    echo "----------------------------------------------------------------------------"
    echo "Total Suites: $TOTAL_TESTS"
    echo "Passed: $PASSED_TESTS"
    echo "Failed: $FAILED_TESTS"
    echo "Pass Rate: ${pass_rate}%"
    echo "Total Time: ${TOTAL_TIME}s"
    echo "----------------------------------------------------------------------------"

    # File report
    {
        echo ""
        echo "SUMMARY"
        echo "======="
        echo "Total Suites: $TOTAL_TESTS"
        echo "Passed: $PASSED_TESTS"
        echo "Failed: $FAILED_TESTS"
        echo "Pass Rate: ${pass_rate}%"
        echo "Total Time: ${TOTAL_TIME}s"
        echo ""
        echo "DETAILED RESULTS"
        echo "================"
        for result in "${SUITE_RESULTS[@]}"; do
            IFS='|' read -r name status duration details <<< "$result"
            echo ""
            echo "Suite: $name"
            echo "Status: $status"
            echo "Duration: ${duration}s"
            if [[ -n "$details" ]]; then
                echo "Details: $details"
            fi
        done
    } >> "$REPORT_FILE"

    # JSON report
    generate_json_report

    echo ""
    echo "Report saved to: $REPORT_FILE"
    echo "JSON report saved to: $JSON_REPORT"

    # Determine success
    if [[ $pass_rate -ge 60 ]]; then
        echo -e "${COLOR_GREEN}✓ E2E TESTS PASSED (${pass_rate}% ≥ 60%)${COLOR_RESET}"
        return 0
    else
        echo -e "${COLOR_RED}✗ E2E TESTS FAILED (${pass_rate}% < 60%)${COLOR_RESET}"
        return 1
    fi
}

# Generate JSON report
generate_json_report() {
    local json_results="[]"

    for result in "${SUITE_RESULTS[@]}"; do
        IFS='|' read -r name status duration details <<< "$result"

        local result_json
        result_json=$(jq -n \
            --arg name "$name" \
            --arg status "$status" \
            --arg duration "$duration" \
            --arg details "$details" \
            '{
                name: $name,
                status: $status,
                duration: ($duration | tonumber),
                details: $details
            }')

        json_results=$(echo "$json_results" | jq ". += [$result_json]")
    done

    local pass_rate=0
    if [[ $TOTAL_TESTS -gt 0 ]]; then
        pass_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    fi

    jq -n \
        --argjson suites "$json_results" \
        --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --arg repo "${GH_REPO:-unknown}" \
        --arg total "$TOTAL_TESTS" \
        --arg passed "$PASSED_TESTS" \
        --arg failed "$FAILED_TESTS" \
        --arg rate "$pass_rate" \
        --arg time "$TOTAL_TIME" \
        '{
            timestamp: $timestamp,
            repository: $repo,
            summary: {
                total: ($total | tonumber),
                passed: ($passed | tonumber),
                failed: ($failed | tonumber),
                passRate: ($rate | tonumber),
                totalTime: ($time | tonumber)
            },
            suites: $suites
        }' > "$JSON_REPORT"
}

# ============================================================================
# Test Execution
# ============================================================================

# Run single test suite
run_test_suite() {
    local test_file="$1"
    local test_name="$2"

    echo ""
    echo "###############################################################################"
    echo "# Running: $test_name"
    echo "###############################################################################"

    local start_time
    start_time=$(date +%s)

    local status="PASS"
    local details=""

    if bash "$SCRIPT_DIR/$test_file" 2>&1 | tee "$REPORT_DIR/$(basename "$test_file" .sh).log"; then
        status="PASS"
    else
        status="FAIL"
        details="Test suite failed. See log for details."
    fi

    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    record_suite_result "$test_name" "$status" "$duration" "$details"
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    echo ""
    echo "###############################################################################"
    echo "# E2E TEST SUITE - GITHUB ACTIONS RUNNER SYSTEM"
    echo "###############################################################################"
    echo ""
    echo "Starting end-to-end test execution..."
    echo "Report directory: $REPORT_DIR"
    echo ""

    # Initialize
    init_reports

    # Verify environment
    echo "Verifying test environment..."
    if [[ -z "${GITHUB_TOKEN:-}" ]]; then
        echo -e "${COLOR_YELLOW}⚠${COLOR_RESET} GITHUB_TOKEN not set - some tests may be limited"
    fi

    if [[ -z "${TEST_REPO:-}" ]]; then
        echo -e "${COLOR_YELLOW}⚠${COLOR_RESET} TEST_REPO not set - using current repo"
        export TEST_REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null || echo "unknown")
    fi

    echo "Test repository: $TEST_REPO"
    echo ""

    # Run all test suites
    for suite_def in "${TEST_SUITES[@]}"; do
        IFS=':' read -r test_file test_name <<< "$suite_def"
        run_test_suite "$test_file" "$test_name"
    done

    # Generate final report
    generate_report

    local exit_code=$?

    echo ""
    echo "E2E test execution completed."

    return $exit_code
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
