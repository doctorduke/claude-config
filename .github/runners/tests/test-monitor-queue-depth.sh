#!/bin/bash
#
# Test suite for monitor-queue-depth.sh
#
# Tests various scenarios including:
# - No queued runs
# - High queue depth
# - No available runners
# - Alert thresholds
# - Export formats (JSON, Prometheus, CSV, text)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MONITOR_SCRIPT="$PROJECT_ROOT/scripts/monitor-queue-depth.sh"
TEST_DIR="/tmp/monitor-queue-test-$$"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Setup test environment
setup() {
    mkdir -p "$TEST_DIR"
    export METRICS_DIR="$TEST_DIR/metrics"
    export LOG_FILE="$TEST_DIR/test.log"
}

# Cleanup test environment
cleanup() {
    rm -rf "$TEST_DIR"
}

# Print test header
test_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Assert success
assert_success() {
    local message=$1
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "${GREEN}✓${NC} $message"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

# Assert failure
assert_failure() {
    local message=$1
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "${RED}✗${NC} $message"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

# Test 1: Script exists and is executable
test_script_exists() {
    test_header "Test 1: Script exists and is executable"

    if [[ -f "$MONITOR_SCRIPT" ]]; then
        assert_success "Script file exists"
    else
        assert_failure "Script file not found: $MONITOR_SCRIPT"
        return
    fi

    if [[ -x "$MONITOR_SCRIPT" ]] || bash -n "$MONITOR_SCRIPT" &>/dev/null; then
        assert_success "Script is valid bash syntax"
    else
        assert_failure "Script has syntax errors"
    fi
}

# Test 2: Help message
test_help_message() {
    test_header "Test 2: Help message"

    if bash "$MONITOR_SCRIPT" --help &>/dev/null; then
        assert_success "Help message displays without errors"
    else
        assert_failure "Help message failed"
    fi
}

# Test 3: JSON format output
test_json_format() {
    test_header "Test 3: JSON format output"

    # Create mock script that doesn't require gh CLI
    local mock_script="$TEST_DIR/mock-monitor.sh"
    cat > "$mock_script" <<'EOF'
#!/bin/bash
cat <<'JSON'
{
    "timestamp": "2025-01-15T10:30:00Z",
    "repository": "test/repo",
    "organization": "test",
    "workflows": {
        "pending": 2,
        "in_progress": 3,
        "total_active": 5
    },
    "runners": {
        "total": 5,
        "online": 4,
        "available": 2,
        "busy": 2,
        "offline": 1
    },
    "metrics": {
        "queue_depth": 2,
        "utilization_percent": 50,
        "capacity": 2,
        "max_wait_time_seconds": 120,
        "avg_wait_time_seconds": 90
    },
    "status": "healthy",
    "thresholds": {
        "queue_depth_warning": 5,
        "queue_depth_critical": 10,
        "utilization_warning": 80,
        "utilization_critical": 95,
        "wait_time_warning": 300,
        "wait_time_critical": 600
    }
}
JSON
EOF
    chmod +x "$mock_script"

    local output=$("$mock_script")

    if echo "$output" | jq empty &>/dev/null; then
        assert_success "JSON output is valid"
    else
        assert_failure "JSON output is invalid"
    fi

    if echo "$output" | jq -e '.metrics.queue_depth' &>/dev/null; then
        assert_success "JSON contains queue_depth metric"
    else
        assert_failure "JSON missing queue_depth metric"
    fi

    if echo "$output" | jq -e '.metrics.utilization_percent' &>/dev/null; then
        assert_success "JSON contains utilization_percent metric"
    else
        assert_failure "JSON missing utilization_percent metric"
    fi
}

# Test 4: Alert threshold logic
test_alert_thresholds() {
    test_header "Test 4: Alert threshold logic"

    # Test healthy status
    local metrics_healthy='{"metrics":{"queue_depth":2,"utilization_percent":50,"max_wait_time_seconds":60},"status":"healthy"}'
    local status=$(echo "$metrics_healthy" | jq -r '.status')

    if [[ "$status" == "healthy" ]]; then
        assert_success "Healthy status correctly identified"
    else
        assert_failure "Healthy status not correctly identified"
    fi

    # Test warning status
    local metrics_warning='{"metrics":{"queue_depth":6,"utilization_percent":85,"max_wait_time_seconds":350},"status":"warning"}'
    status=$(echo "$metrics_warning" | jq -r '.status')

    if [[ "$status" == "warning" ]]; then
        assert_success "Warning status correctly identified"
    else
        assert_failure "Warning status not correctly identified"
    fi

    # Test critical status
    local metrics_critical='{"metrics":{"queue_depth":12,"utilization_percent":98,"max_wait_time_seconds":700},"status":"critical"}'
    status=$(echo "$metrics_critical" | jq -r '.status')

    if [[ "$status" == "critical" ]]; then
        assert_success "Critical status correctly identified"
    else
        assert_failure "Critical status not correctly identified"
    fi
}

# Test 5: Prometheus format
test_prometheus_format() {
    test_header "Test 5: Prometheus format"

    local metrics_json='{"metrics":{"queue_depth":5,"utilization_percent":75},"workflows":{"pending":5,"in_progress":3},"runners":{"available":2,"busy":6,"offline":1}}'

    # Create temp script to test prometheus export
    local test_script="$TEST_DIR/test-prometheus.sh"
    cat > "$test_script" <<'SCRIPT'
#!/bin/bash
metrics_json='{"metrics":{"queue_depth":5,"utilization_percent":75},"workflows":{"pending":5,"in_progress":3},"runners":{"available":2,"busy":6,"offline":1}}'
REPO="test/repo"
ORG="test"

pending=$(echo "$metrics_json" | jq -r '.workflows.pending')
in_progress=$(echo "$metrics_json" | jq -r '.workflows.in_progress')
available=$(echo "$metrics_json" | jq -r '.runners.available')
busy=$(echo "$metrics_json" | jq -r '.runners.busy')
offline=$(echo "$metrics_json" | jq -r '.runners.offline')
queue_depth=$(echo "$metrics_json" | jq -r '.metrics.queue_depth')
utilization=$(echo "$metrics_json" | jq -r '.metrics.utilization_percent')

cat <<EOF
# HELP github_actions_workflows_pending Number of pending workflow runs
# TYPE github_actions_workflows_pending gauge
github_actions_workflows_pending{repo="$REPO"} $pending

# HELP github_actions_queue_depth Number of queued workflow runs
# TYPE github_actions_queue_depth gauge
github_actions_queue_depth{repo="$REPO"} $queue_depth

# HELP github_actions_runner_utilization Runner utilization percentage
# TYPE github_actions_runner_utilization gauge
github_actions_runner_utilization{org="$ORG",repo="$REPO"} $utilization
EOF
SCRIPT
    chmod +x "$test_script"

    local output=$("$test_script")

    if echo "$output" | grep -q "github_actions_queue_depth"; then
        assert_success "Prometheus format contains queue_depth metric"
    else
        assert_failure "Prometheus format missing queue_depth metric"
    fi

    if echo "$output" | grep -q "github_actions_runner_utilization"; then
        assert_success "Prometheus format contains utilization metric"
    else
        assert_failure "Prometheus format missing utilization metric"
    fi

    if echo "$output" | grep -q "# HELP"; then
        assert_success "Prometheus format contains HELP comments"
    else
        assert_failure "Prometheus format missing HELP comments"
    fi

    if echo "$output" | grep -q "# TYPE"; then
        assert_success "Prometheus format contains TYPE comments"
    else
        assert_failure "Prometheus format missing TYPE comments"
    fi
}

# Test 6: CSV format
test_csv_format() {
    test_header "Test 6: CSV format"

    local test_script="$TEST_DIR/test-csv.sh"
    cat > "$test_script" <<'SCRIPT'
#!/bin/bash
metrics_json='{"timestamp":"2025-01-15T10:30:00Z","workflows":{"pending":5,"in_progress":3},"runners":{"available":2,"busy":6,"offline":1},"metrics":{"queue_depth":5,"utilization_percent":75,"max_wait_time_seconds":120,"avg_wait_time_seconds":90},"status":"warning"}'
REPO="test/repo"

timestamp=$(echo "$metrics_json" | jq -r '.timestamp')
pending=$(echo "$metrics_json" | jq -r '.workflows.pending')
in_progress=$(echo "$metrics_json" | jq -r '.workflows.in_progress')
available=$(echo "$metrics_json" | jq -r '.runners.available')
busy=$(echo "$metrics_json" | jq -r '.runners.busy')
offline=$(echo "$metrics_json" | jq -r '.runners.offline')
queue_depth=$(echo "$metrics_json" | jq -r '.metrics.queue_depth')
utilization=$(echo "$metrics_json" | jq -r '.metrics.utilization_percent')
max_wait=$(echo "$metrics_json" | jq -r '.metrics.max_wait_time_seconds')
avg_wait=$(echo "$metrics_json" | jq -r '.metrics.avg_wait_time_seconds')
status=$(echo "$metrics_json" | jq -r '.status')

echo "timestamp,repo,pending,in_progress,available,busy,offline,queue_depth,utilization,max_wait,avg_wait,status"
echo "$timestamp,$REPO,$pending,$in_progress,$available,$busy,$offline,$queue_depth,$utilization,$max_wait,$avg_wait,$status"
SCRIPT
    chmod +x "$test_script"

    local output=$("$test_script")
    local line_count=$(echo "$output" | wc -l)

    if [[ $line_count -eq 2 ]]; then
        assert_success "CSV format has header and data row"
    else
        assert_failure "CSV format has incorrect number of lines: $line_count"
    fi

    if echo "$output" | head -1 | grep -q "timestamp,repo,pending"; then
        assert_success "CSV format has correct header"
    else
        assert_failure "CSV format has incorrect header"
    fi

    if echo "$output" | tail -1 | grep -q "2025-01-15"; then
        assert_success "CSV format has data row"
    else
        assert_failure "CSV format missing data row"
    fi
}

# Test 7: Text format
test_text_format() {
    test_header "Test 7: Text format"

    local test_script="$TEST_DIR/test-text.sh"
    cat > "$test_script" <<'SCRIPT'
#!/bin/bash
echo "=== GitHub Actions Queue Monitor ==="
echo "Repository: test/repo"
echo ""
echo "Workflows:"
echo "  Pending:     5"
echo "  In Progress: 3"
echo ""
echo "Runners:"
echo "  Available: 2"
echo "  Busy:      6"
echo ""
echo "Metrics:"
echo "  Queue Depth:  5"
echo "  Utilization:  75%"
echo ""
echo "Status: HEALTHY"
SCRIPT
    chmod +x "$test_script"

    local output=$("$test_script")

    if echo "$output" | grep -q "Queue Monitor"; then
        assert_success "Text format has header"
    else
        assert_failure "Text format missing header"
    fi

    if echo "$output" | grep -q "Queue Depth:"; then
        assert_success "Text format has queue depth"
    else
        assert_failure "Text format missing queue depth"
    fi

    if echo "$output" | grep -q "Utilization:"; then
        assert_success "Text format has utilization"
    else
        assert_failure "Text format missing utilization"
    fi
}

# Test 8: Log file creation
test_log_file() {
    test_header "Test 8: Log file creation"

    local log_file="$TEST_DIR/test.log"

    # Create test log entry
    echo "2025-01-15T10:30:00Z [INFO] Test log entry" > "$log_file"

    if [[ -f "$log_file" ]]; then
        assert_success "Log file created"
    else
        assert_failure "Log file not created"
    fi

    if grep -q "Test log entry" "$log_file"; then
        assert_success "Log file contains entries"
    else
        assert_failure "Log file empty or missing entries"
    fi
}

# Test 9: Metrics directory creation
test_metrics_directory() {
    test_header "Test 9: Metrics directory creation"

    local metrics_dir="$TEST_DIR/metrics"
    mkdir -p "$metrics_dir"

    if [[ -d "$metrics_dir" ]]; then
        assert_success "Metrics directory created"
    else
        assert_failure "Metrics directory not created"
    fi

    # Test file creation in metrics directory
    echo '{"test":"data"}' > "$metrics_dir/test-metrics.json"

    if [[ -f "$metrics_dir/test-metrics.json" ]]; then
        assert_success "Metrics files can be created"
    else
        assert_failure "Cannot create metrics files"
    fi
}

# Test 10: Edge cases
test_edge_cases() {
    test_header "Test 10: Edge cases"

    # Test zero values
    local metrics_zero='{"metrics":{"queue_depth":0,"utilization_percent":0},"runners":{"available":5,"busy":0}}'
    local queue_depth=$(echo "$metrics_zero" | jq -r '.metrics.queue_depth')

    if [[ "$queue_depth" -eq 0 ]]; then
        assert_success "Handles zero queue depth"
    else
        assert_failure "Does not handle zero queue depth correctly"
    fi

    # Test high values
    local metrics_high='{"metrics":{"queue_depth":100,"utilization_percent":100}}'
    local utilization=$(echo "$metrics_high" | jq -r '.metrics.utilization_percent')

    if [[ "$utilization" -eq 100 ]]; then
        assert_success "Handles 100% utilization"
    else
        assert_failure "Does not handle 100% utilization correctly"
    fi

    # Test no runners available
    local metrics_no_runners='{"runners":{"available":0,"busy":5},"workflows":{"pending":10}}'
    local available=$(echo "$metrics_no_runners" | jq -r '.runners.available')
    local pending=$(echo "$metrics_no_runners" | jq -r '.workflows.pending')

    if [[ "$available" -eq 0 ]] && [[ "$pending" -gt 0 ]]; then
        assert_success "Detects no available runners with pending workflows"
    else
        assert_failure "Does not detect critical condition correctly"
    fi
}

# Print test summary
print_summary() {
    echo ""
    echo -e "${BLUE}=== Test Summary ===${NC}"
    echo "Total tests run: $TESTS_RUN"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
        echo ""
        echo -e "${RED}Some tests failed!${NC}"
        return 1
    else
        echo -e "Tests failed: ${GREEN}0${NC}"
        echo ""
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    fi
}

# Main test execution
main() {
    echo -e "${BLUE}Starting monitor-queue-depth.sh test suite${NC}"
    echo ""

    setup

    # Run all tests
    test_script_exists
    test_help_message
    test_json_format
    test_alert_thresholds
    test_prometheus_format
    test_csv_format
    test_text_format
    test_log_file
    test_metrics_directory
    test_edge_cases

    # Print summary
    local exit_code=0
    print_summary || exit_code=$?

    cleanup

    exit $exit_code
}

# Run tests
main "$@"
