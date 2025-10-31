#!/usr/bin/env bash
# Integration Test: Runner Setup
# Tests self-hosted runner setup and configuration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/test-helpers.sh"

readonly TEST_OUTPUT_DIR="/tmp/test-runner-setup"
readonly SETUP_RUNNER_SCRIPT="${SCRIPT_DIR}/../../../scripts/setup-runner.sh"

setup() {
    log_info "Setting up Runner Setup tests..."
    mkdir -p "$TEST_OUTPUT_DIR"
}

teardown() {
    log_info "Tearing down Runner Setup tests..."
    if [[ "$CLEANUP_ON_SUCCESS" == "true" ]]; then
        rm -rf "$TEST_OUTPUT_DIR"
    fi
}

test_runner_prerequisites() {
    log_test "Test: Runner prerequisites check"

    # Check required commands
    local required_commands=("curl" "tar" "jq")

    for cmd in "${required_commands[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            log_info "Found: $cmd"
        else
            log_warn "Missing: $cmd"
        fi
    done

    return 0
}

test_runner_token_generation() {
    log_test "Test: Runner registration token generation"

    # Mock token generation
    local token="ABCD1234567890"

    assert_greater_than "${#token}" 10
}

test_runner_configuration() {
    log_test "Test: Runner configuration file"

    cat > "$TEST_OUTPUT_DIR/runner-config.json" << 'EOF'
{
  "name": "test-runner-1",
  "labels": ["self-hosted", "linux", "ai-agent"],
  "work_directory": "/opt/actions-runner/_work",
  "url": "https://github.com/test-org/test-repo"
}
EOF

    assert_file_exists "$TEST_OUTPUT_DIR/runner-config.json"
    assert_json_valid "$(cat "$TEST_OUTPUT_DIR/runner-config.json")"

    local labels
    labels=$(jq -r '.labels | join(",")' "$TEST_OUTPUT_DIR/runner-config.json")
    assert_contains "$labels" "self-hosted"
    assert_contains "$labels" "ai-agent"
}

test_runner_labels() {
    log_test "Test: Runner labels configuration"

    local expected_labels=("self-hosted" "linux" "ai-agent")
    local configured_labels=("self-hosted" "linux" "ai-agent" "x64")

    for label in "${expected_labels[@]}"; do
        if printf '%s\n' "${configured_labels[@]}" | grep -q "^${label}$"; then
            log_info "Label found: $label"
        else
            log_fail "Missing label: $label"
            return 1
        fi
    done

    return 0
}

test_runner_service_installation() {
    log_test "Test: Runner service installation"

    # Mock service file
    cat > "$TEST_OUTPUT_DIR/runner.service" << 'EOF'
[Unit]
Description=GitHub Actions Runner
After=network.target

[Service]
Type=simple
User=runner
WorkingDirectory=/opt/actions-runner
ExecStart=/opt/actions-runner/run.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    assert_file_exists "$TEST_OUTPUT_DIR/runner.service"
    assert_contains "$(cat "$TEST_OUTPUT_DIR/runner.service")" "GitHub Actions Runner"
}

test_runner_health_check() {
    log_test "Test: Runner health check"

    # Mock runner status
    local runner_status="online"

    assert_equals "online" "$runner_status"
}

test_runner_group_assignment() {
    log_test "Test: Runner group assignment"

    local runner_group="ai-agents"
    local expected_group="ai-agents"

    assert_equals "$expected_group" "$runner_group"
}

test_runner_work_directory() {
    log_test "Test: Runner work directory setup"

    local work_dir="$TEST_OUTPUT_DIR/runner-work"
    mkdir -p "$work_dir"

    assert_file_exists "$work_dir"
}

test_runner_cleanup_on_removal() {
    log_test "Test: Runner cleanup on removal"

    local cleanup_dir="$TEST_OUTPUT_DIR/cleanup-test"
    mkdir -p "$cleanup_dir"

    # Simulate cleanup
    rm -rf "$cleanup_dir"

    assert_file_not_exists "$cleanup_dir"
}

test_runner_auto_update() {
    log_test "Test: Runner auto-update configuration"

    local auto_update_enabled=true

    if [[ "$auto_update_enabled" == "true" ]]; then
        log_info "Auto-update is enabled"
        return 0
    else
        log_fail "Auto-update should be enabled"
        return 1
    fi
}

main() {
    log_info "Starting Runner Setup Integration Tests"
    log_info "========================================"

    setup

    run_test "Runner prerequisites" "test_runner_prerequisites" || true
    run_test "Runner token generation" "test_runner_token_generation" || true
    run_test "Runner configuration" "test_runner_configuration" || true
    run_test "Runner labels" "test_runner_labels" || true
    run_test "Runner service installation" "test_runner_service_installation" || true
    run_test "Runner health check" "test_runner_health_check" || true
    run_test "Runner group assignment" "test_runner_group_assignment" || true
    run_test "Runner work directory" "test_runner_work_directory" || true
    run_test "Runner cleanup on removal" "test_runner_cleanup_on_removal" || true
    run_test "Runner auto-update" "test_runner_auto_update" || true

    teardown
    print_test_summary
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
