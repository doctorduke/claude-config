#!/bin/bash
# Unit tests for fixtures library

# Source test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/test-helpers.sh"

# Test: Create test PR fixture
test_create_test_pr() {
    local pr_json
    pr_json=$(create_test_pr 123 "Test PR" "open")

    assert_contains "$pr_json" "\"number\": 123"
    assert_contains "$pr_json" "\"title\": \"Test PR\""
    assert_contains "$pr_json" "\"state\": \"open\""
}

# Test: Create test issue fixture
test_create_test_issue() {
    local issue_json
    issue_json=$(create_test_issue 456 "Test Issue" "open" "bug")

    assert_contains "$issue_json" "\"number\": 456"
    assert_contains "$issue_json" "\"title\": \"Test Issue\""
    assert_contains "$issue_json" "\"state\": \"open\""
}

# Test: Create test workflow run fixture
test_create_test_workflow_run() {
    local run_json
    run_json=$(create_test_workflow_run 789 "completed" "success")

    assert_contains "$run_json" "\"id\": 789"
    assert_contains "$run_json" "\"status\": \"completed\""
    assert_contains "$run_json" "\"conclusion\": \"success\""
}

# Test: Create test AI response
test_create_test_ai_response() {
    local ai_json
    ai_json=$(create_test_ai_response "Hello world")

    assert_contains "$ai_json" "Hello world"
    assert_contains "$ai_json" "\"role\": \"assistant\""
}

# Test: Create test env file
test_create_test_env_file() {
    local temp_dir
    temp_dir=$(create_temp_dir)

    local env_file
    env_file=$(create_test_env_file "$temp_dir/test.env")

    assert_file_exists "$env_file"
    assert_contains "$(cat "$env_file")" "GITHUB_TOKEN"
    assert_contains "$(cat "$env_file")" "ANTHROPIC_API_KEY"

    rm -rf "$temp_dir"
}

# Test: Create test config
test_create_test_config() {
    local temp_dir
    temp_dir=$(create_temp_dir)

    local config_file
    config_file=$(create_test_config "$temp_dir/config.json")

    assert_file_exists "$config_file"
    assert_contains "$(cat "$config_file")" "ai_provider"
    assert_contains "$(cat "$config_file")" "anthropic"

    rm -rf "$temp_dir"
}

# Test: Create test script
test_create_test_script() {
    local temp_dir
    temp_dir=$(create_temp_dir)

    local script_file
    script_file=$(create_test_script "$temp_dir/test.sh" "echo 'test'")

    assert_file_exists "$script_file"

    # Test that script is executable
    if [[ -x "$script_file" ]]; then
        assert_true "true"
    else
        assert_true "false"
    fi

    rm -rf "$temp_dir"
}

# Test: Create test webhook payload
test_create_test_webhook_payload() {
    local payload
    payload=$(create_test_webhook_payload "pull_request" "opened")

    assert_contains "$payload" "\"action\": \"opened\""
    assert_contains "$payload" "pull_request"
}

# Test: Create test runner token
test_create_test_runner_token() {
    local token_json
    token_json=$(create_test_runner_token "ABC123")

    assert_contains "$token_json" "\"token\": \"ABC123\""
    assert_contains "$token_json" "expires_at"
}

# Test: Create test diff
test_create_test_diff() {
    local diff_output
    diff_output=$(create_test_diff)

    assert_contains "$diff_output" "diff --git"
    assert_contains "$diff_output" "Version 2.0"
}

# Test: Create test directory structure
test_create_test_directory_structure() {
    local temp_dir
    temp_dir=$(create_temp_dir)

    cd "$temp_dir" || return 1

    local project_dir
    project_dir=$(create_test_directory_structure "test-project")

    assert_dir_exists "$project_dir"
    assert_dir_exists "$project_dir/src"
    assert_dir_exists "$project_dir/tests"
    assert_file_exists "$project_dir/src/main.sh"

    rm -rf "$temp_dir"
}

# Run all tests
run_all_tests
