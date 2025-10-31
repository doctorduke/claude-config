#!/bin/bash
# Unit tests for mocking library

# Source test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/test-helpers.sh"

# Setup: Initialize mocks before each test
setup() {
    init_mocks
}

# Teardown: Cleanup mocks after each test
teardown() {
    cleanup_mocks
}

# Test: Mock a simple command
test_mock_command_returns_expected_response() {
    mock_command "test-cmd" "mocked output"

    local output
    output=$(test-cmd)

    assert_equals "mocked output" "$output"
}

# Test: Mock command with exit code
test_mock_command_with_exit_code() {
    mock_command "fail-cmd" "error" 1

    local output
    local exit_code=0
    output=$(fail-cmd 2>&1) || exit_code=$?

    assert_exit_code 1 "$exit_code"
}

# Test: Get mock call count
test_get_mock_call_count() {
    mock_command "counter" "ok"

    counter
    counter
    counter

    local count
    count=$(get_mock_call_count "counter")

    assert_equals "3" "$count"
}

# Test: Get mock call arguments
test_get_mock_call_args() {
    mock_command "args-cmd" "ok"

    args-cmd --flag value

    local args
    args=$(get_mock_call_args "args-cmd" 1)

    assert_contains "$args" "--flag"
    assert_contains "$args" "value"
}

# Test: Assert mock called with specific args
test_assert_mock_called_with() {
    mock_command "specific-cmd" "ok"

    specific-cmd --test 123

    assert_mock_called_with "specific-cmd" "--test 123"
}

# Test: Mock environment variable
test_mock_env() {
    mock_env "TEST_VAR" "test_value"

    assert_equals "test_value" "$TEST_VAR"

    restore_env "TEST_VAR"
}

# Test: Mock API success response
test_mock_api_success() {
    local response
    response=$(mock_api_success '{"id": 123}')

    assert_contains "$response" "success"
    assert_contains "$response" "123"
}

# Test: Mock API error response
test_mock_api_error() {
    local response
    response=$(mock_api_error "Something went wrong" 500)

    assert_contains "$response" "error"
    assert_contains "$response" "Something went wrong"
    assert_contains "$response" "500"
}

# Test: Mock HTTP response
test_mock_http_response() {
    local response
    response=$(mock_http_response "200" '{"status": "ok"}')

    assert_contains "$response" "HTTP/1.1 200"
    assert_contains "$response" "status"
}

# Test: Mock gh API with multiple endpoints
test_mock_gh_api_multiple_endpoints() {
    init_mocks

    # Mock multiple GitHub API endpoints
    mock_gh_api "api repos list" '{"repo1": "data1"}'
    mock_gh_api "api repos get owner/repo" '{"repo2": "data2"}'

    # Test first endpoint
    local result1
    result1=$(gh api repos list)
    assert_contains "$result1" "repo1"

    # Test second endpoint
    local result2
    result2=$(gh api repos get owner/repo)
    assert_contains "$result2" "repo2"

    cleanup_mocks
}

# Run all tests

# Test: Mock gh API with multiple endpoints
test_mock_ai_api_multiple_providers() {
    init_mocks
    
    # Mock both Anthropic and OpenAI
    mock_ai_api "anthropic" '{"model": "claude"}'
    mock_ai_api "openai" '{"model": "gpt"}'
    
    # Test Anthropic
    local result1
    result1=$(curl -s https://api.anthropic.com/v1/messages)
    assert_contains "$result1" "claude"
    
    # Test OpenAI
    local result2
    result2=$(curl -s https://api.openai.com/v1/chat/completions)
    assert_contains "$result2" "gpt"
    
    cleanup_mocks
}

run_all_tests
