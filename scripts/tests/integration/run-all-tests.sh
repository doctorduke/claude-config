#!/usr/bin/env bash
# Master Integration Test Runner
# Runs all integration tests and generates comprehensive report

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/test-helpers.sh"

# Test configuration
readonly TEST_REPORT_DIR="${TEST_REPORT_DIR:-/tmp/integration-test-reports}"
readonly PARALLEL_EXECUTION="${PARALLEL_EXECUTION:-false}"
readonly FAIL_FAST="${FAIL_FAST:-false}"

# Test suites
declare -a TEST_SUITES=(
    "test-ai-pr-review-workflow.sh"
    "test-ai-issue-comment-workflow.sh"
    "test-ai-autofix-workflow.sh"
    "test-secret-management.sh"
    "test-runner-setup.sh"
    "test-network-validation.sh"
    "test-workflow-triggers.sh"
)

# Setup test environment
setup_test_environment() {
    log_info "Setting up integration test environment..."

    # Create report directory
    mkdir -p "$TEST_REPORT_DIR"

    # Set environment variables
    export CLEANUP_ON_SUCCESS=true
    export TEST_TIMEOUT=300

    log_info "Test report directory: $TEST_REPORT_DIR"
}

# Run a single test suite
run_test_suite() {
    local test_suite="$1"
    local test_file="${SCRIPT_DIR}/${test_suite}"

    if [[ ! -f "$test_file" ]]; then
        log_fail "Test suite not found: $test_suite"
        return 1
    fi

    log_info "Running test suite: $test_suite"

    local output_file="${TEST_REPORT_DIR}/${test_suite%.sh}.log"
    local start_time
    start_time=$(date +%s)

    if bash "$test_file" > "$output_file" 2>&1; then
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))

        log_pass "Test suite passed: $test_suite (${duration}s)"
        return 0
    else
        local exit_code=$?
        log_fail "Test suite failed: $test_suite (exit code: $exit_code)"

        if [[ "$FAIL_FAST" == "true" ]]; then
            log_fail "Fail-fast enabled - stopping execution"
            exit 1
        fi

        return 1
    fi
}

# Run all test suites
run_all_test_suites() {
    log_info "Running ${#TEST_SUITES[@]} test suites..."

    local total_suites=0
    local passed_suites=0
    local failed_suites=0

    for test_suite in "${TEST_SUITES[@]}"; do
        total_suites=$((total_suites + 1))

        if [[ "$PARALLEL_EXECUTION" == "true" ]]; then
            # Run in background for parallel execution
            run_test_suite "$test_suite" &
        else
            # Run sequentially
            if run_test_suite "$test_suite"; then
                passed_suites=$((passed_suites + 1))
            else
                failed_suites=$((failed_suites + 1))
            fi
        fi
    done

    # Wait for parallel jobs
    if [[ "$PARALLEL_EXECUTION" == "true" ]]; then
        wait

        # Count results from log files
        for test_suite in "${TEST_SUITES[@]}"; do
            local output_file="${TEST_REPORT_DIR}/${test_suite%.sh}.log"
            if [[ -f "$output_file" ]] && grep -q "Pass rate:" "$output_file"; then
                if grep "Pass rate:" "$output_file" | grep -q "[6-9][0-9]%\|100%"; then
                    passed_suites=$((passed_suites + 1))
                else
                    failed_suites=$((failed_suites + 1))
                fi
            else
                failed_suites=$((failed_suites + 1))
            fi
        done
    fi

    echo ""
    echo "========================================="
    echo "Integration Test Summary"
    echo "========================================="
    echo "Total Suites:  $total_suites"
    echo -e "Passed:        ${GREEN}${passed_suites}${NC}"
    echo -e "Failed:        ${RED}${failed_suites}${NC}"
    echo "========================================="

    # Calculate overall pass rate
    local pass_rate=0
    if [[ $total_suites -gt 0 ]]; then
        pass_rate=$((passed_suites * 100 / total_suites))
    fi

    echo "Overall Pass Rate: ${pass_rate}%"

    if [[ $pass_rate -ge 60 ]]; then
        echo -e "${GREEN}✓ Acceptable pass rate (≥60%)${NC}"
        return 0
    else
        echo -e "${RED}✗ Pass rate below 60%${NC}"
        return 1
    fi
}

# Generate HTML report
generate_html_report() {
    log_info "Generating HTML test report..."

    local html_report="${TEST_REPORT_DIR}/index.html"

    cat > "$html_report" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Integration Test Report</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background: #f5f5f5;
        }
        h1 {
            color: #333;
            border-bottom: 3px solid #4CAF50;
            padding-bottom: 10px;
        }
        .summary {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin: 20px 0;
        }
        .test-suite {
            background: white;
            padding: 15px;
            margin: 10px 0;
            border-radius: 8px;
            border-left: 4px solid #ddd;
        }
        .pass { border-left-color: #4CAF50; }
        .fail { border-left-color: #f44336; }
        .stats {
            display: flex;
            gap: 20px;
            margin: 20px 0;
        }
        .stat {
            flex: 1;
            text-align: center;
            padding: 15px;
            background: #f9f9f9;
            border-radius: 4px;
        }
        .stat-value {
            font-size: 2em;
            font-weight: bold;
            color: #333;
        }
        .stat-label {
            color: #666;
            margin-top: 5px;
        }
        pre {
            background: #f4f4f4;
            padding: 10px;
            border-radius: 4px;
            overflow-x: auto;
        }
    </style>
</head>
<body>
    <h1>Integration Test Report</h1>

    <div class="summary">
        <h2>Test Execution Summary</h2>
        <div class="stats">
            <div class="stat">
                <div class="stat-value">__TOTAL__</div>
                <div class="stat-label">Test Suites</div>
            </div>
            <div class="stat">
                <div class="stat-value" style="color: #4CAF50">__PASSED__</div>
                <div class="stat-label">Passed</div>
            </div>
            <div class="stat">
                <div class="stat-value" style="color: #f44336">__FAILED__</div>
                <div class="stat-label">Failed</div>
            </div>
            <div class="stat">
                <div class="stat-value">__RATE__%</div>
                <div class="stat-label">Pass Rate</div>
            </div>
        </div>
    </div>

    <h2>Test Suites</h2>
    __TEST_SUITES__

</body>
</html>
EOF

    log_info "HTML report generated: $html_report"
}

# Generate JSON report
generate_json_report() {
    log_info "Generating JSON test report..."

    local json_report="${TEST_REPORT_DIR}/results.json"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    cat > "$json_report" << EOF
{
  "timestamp": "$timestamp",
  "environment": {
    "os": "$(uname -s)",
    "shell": "$BASH_VERSION"
  },
  "configuration": {
    "parallel": $PARALLEL_EXECUTION,
    "fail_fast": $FAIL_FAST,
    "timeout": $TEST_TIMEOUT
  },
  "test_suites": [
EOF

    local first=true
    for test_suite in "${TEST_SUITES[@]}"; do
        if [[ "$first" != "true" ]]; then
            echo "," >> "$json_report"
        fi
        first=false

        local output_file="${TEST_REPORT_DIR}/${test_suite%.sh}.log"
        local status="unknown"
        local pass_rate=0

        if [[ -f "$output_file" ]]; then
            if grep -q "Pass rate:" "$output_file"; then
                # Use sed instead of grep -oP for portability (BSD/macOS compatible)
                pass_rate=$(grep "Pass rate:" "$output_file" | sed -n 's/.*Pass rate: *\([0-9][0-9]*\)%.*//p')
                if [[ $pass_rate -ge 60 ]]; then
                    status="passed"
                else
                    status="failed"
                fi
            fi
        fi

        cat >> "$json_report" << SUITE_EOF
    {
      "name": "$test_suite",
      "status": "$status",
      "pass_rate": $pass_rate
    }
SUITE_EOF
    done

    cat >> "$json_report" << 'EOF'
  ]
}
EOF

    log_info "JSON report generated: $json_report"
}

# Cleanup test environment
cleanup_test_environment() {
    log_info "Cleaning up test environment..."

    # Archive logs
    local archive="${TEST_REPORT_DIR}/test-logs-$(date +%Y%m%d-%H%M%S).tar.gz"
    tar -czf "$archive" -C "$TEST_REPORT_DIR" . 2>/dev/null || true

    log_info "Test logs archived: $archive"
}

# Main execution
main() {
    log_info "Integration Test Runner"
    log_info "======================="
    log_info "Suites: ${#TEST_SUITES[@]}"
    log_info "Parallel: $PARALLEL_EXECUTION"
    log_info "Fail Fast: $FAIL_FAST"
    echo ""

    # Setup
    setup_test_environment

    # Run tests
    local exit_code=0
    if run_all_test_suites; then
        log_pass "Integration tests completed successfully"
    else
        log_fail "Integration tests completed with failures"
        exit_code=1
    fi

    # Generate reports
    generate_json_report
    # generate_html_report  # Uncomment when ready

    # Cleanup
    cleanup_test_environment

    exit $exit_code
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
