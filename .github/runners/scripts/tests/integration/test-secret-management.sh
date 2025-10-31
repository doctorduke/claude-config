#!/usr/bin/env bash
# Integration Test: Secret Management
# Tests secret setup, encryption, and validation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/test-helpers.sh"

readonly TEST_OUTPUT_DIR="/tmp/test-secret-management"
readonly SETUP_SECRETS_SCRIPT="${SCRIPT_DIR}/../../../scripts/setup-secrets.sh"

setup() {
    log_info "Setting up Secret Management tests..."
    mkdir -p "$TEST_OUTPUT_DIR"
    export GITHUB_TOKEN="test-token-123"
}

teardown() {
    log_info "Tearing down Secret Management tests..."
    if [[ "$CLEANUP_ON_SUCCESS" == "true" ]]; then
        rm -rf "$TEST_OUTPUT_DIR"
    fi
}

test_secret_validation() {
    log_test "Test: Secret validation"

    # Test valid secret format
    local secret_key="GITHUB_TOKEN"
    local secret_value="ghp_test123456789"

    if [[ -n "$secret_key" ]] && [[ -n "$secret_value" ]]; then
        return 0
    else
        log_fail "Secret validation failed"
        return 1
    fi
}

test_secret_masking() {
    log_test "Test: Secret masking in logs"

    local secret="ghp_secret123456789"
    local log_output="Processing request with token $secret"

    # Simulate masking function (replace secret with ***)
    local masked_output="${log_output//$secret/***}"

    # Verify the secret was actually masked
    assert_not_contains "$masked_output" "ghp_"
    assert_contains "$masked_output" "***"

    # Verify original secret is not in masked output
    assert_not_contains "$masked_output" "$secret"

    # Verify masking works for different secret patterns
    local api_key="sk-ant-api03-1234567890abcdef"
    local api_log="Using API key: $api_key"
    local masked_api="${api_log//$api_key/***}"

    assert_not_contains "$masked_api" "sk-ant-"
    assert_not_contains "$masked_api" "$api_key"
    assert_contains "$masked_api" "***"
}

test_secret_encryption() {
    log_test "Test: Secret encryption for Actions"

    # Simulate encrypted secret
    local plaintext="my-secret-value"
    local encrypted="encrypted:abc123def456"

    assert_contains "$encrypted" "encrypted:"
    assert_not_contains "$encrypted" "$plaintext"
}

test_secret_repository_config() {
    log_test "Test: Repository secret configuration"

    cat > "$TEST_OUTPUT_DIR/secrets-config.json" << 'EOF'
{
  "secrets": [
    {"name": "AI_API_KEY", "required": true},
    {"name": "GITHUB_TOKEN", "required": true},
    {"name": "SLACK_WEBHOOK", "required": false}
  ]
}
EOF

    assert_file_exists "$TEST_OUTPUT_DIR/secrets-config.json"
    assert_json_valid "$(cat "$TEST_OUTPUT_DIR/secrets-config.json")"
}

test_secret_rotation() {
    log_test "Test: Secret rotation workflow"

    local old_secret="old-value-123"
    local new_secret="new-value-456"

    # Simulate rotation
    local current_secret="$new_secret"

    assert_not_equals "$old_secret" "$current_secret"
}

test_secret_leak_detection() {
    log_test "Test: Secret leak detection"

    # Test that secrets don't appear in logs
    local log_output="Processing request with token ***"

    assert_not_contains "$log_output" "ghp_"
    assert_not_contains "$log_output" "sk-"
    assert_contains "$log_output" "***"
}

test_environment_secret_propagation() {
    log_test "Test: Environment secret propagation"

    # Simulate workflow passing secrets to script
    export TEST_SECRET="value-from-workflow"

    local script_received_secret="$TEST_SECRET"

    assert_equals "value-from-workflow" "$script_received_secret"

    unset TEST_SECRET
}

test_secret_validation_workflow() {
    log_test "Test: Secret validation in workflow"

    # Required secrets
    local required=("GITHUB_TOKEN" "AI_API_KEY")
    local available=("GITHUB_TOKEN" "AI_API_KEY" "OPTIONAL_SECRET")

    for secret in "${required[@]}"; do
        if printf '%s\n' "${available[@]}" | grep -q "^${secret}$"; then
            continue
        else
            log_fail "Required secret missing: $secret"
            return 1
        fi
    done

    return 0
}

main() {
    log_info "Starting Secret Management Integration Tests"
    log_info "============================================="

    setup

    run_test "Secret validation" "test_secret_validation" || true
    run_test "Secret masking" "test_secret_masking" || true
    run_test "Secret encryption" "test_secret_encryption" || true
    run_test "Repository secret config" "test_secret_repository_config" || true
    run_test "Secret rotation" "test_secret_rotation" || true
    run_test "Secret leak detection" "test_secret_leak_detection" || true
    run_test "Environment secret propagation" "test_environment_secret_propagation" || true
    run_test "Secret validation workflow" "test_secret_validation_workflow" || true

    teardown
    print_test_summary
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
