#!/bin/bash
# Integration tests for GitHub API interactions

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

# Test: Mock GitHub API - Get PR
test_github_api_get_pr() {
    local pr_data
    pr_data=$(create_test_pr 123 "Integration Test PR")

    mock_gh_api "repos/testorg/testrepo/pulls/123" "$pr_data"

    local response
    response=$(gh api repos/testorg/testrepo/pulls/123)

    assert_contains "$response" "\"number\": 123"
    assert_contains "$response" "Integration Test PR"
}

# Test: Mock GitHub API - List issues
test_github_api_list_issues() {
    local issue_data
    issue_data=$(create_test_issue 456 "Integration Test Issue")

    mock_command "gh" "[${issue_data}]"

    local response
    response=$(gh issue list --json number,title)

    assert_contains "$response" "\"number\": 456"
    assert_contains "$response" "Integration Test Issue"
}

# Test: Mock GitHub API - Workflow run
test_github_api_workflow_run() {
    local run_data
    run_data=$(create_test_workflow_run 789 "completed" "success")

    mock_gh_api "repos/testorg/testrepo/actions/runs/789" "$run_data"

    local response
    response=$(gh api repos/testorg/testrepo/actions/runs/789)

    assert_contains "$response" "\"id\": 789"
    assert_contains "$response" "\"status\": \"completed\""
    assert_contains "$response" "\"conclusion\": \"success\""
}

# Test: Verify GitHub CLI is called with correct arguments
test_github_api_call_verification() {
    mock_command "gh" "ok"

    gh api repos/testorg/testrepo/pulls

    assert_mock_called_with "gh" "api repos/testorg/testrepo/pulls"
}

# Test: Handle GitHub API errors
test_github_api_error_handling() {
    local error_response='{"message": "Not Found", "status": "404"}'

    mock_gh_api "repos/testorg/testrepo/pulls/999" "$error_response" 1

    local exit_code=0
    gh api repos/testorg/testrepo/pulls/999 2>/dev/null || exit_code=$?

    assert_exit_code 1 "$exit_code"
}

# Test: Multiple API calls
test_github_api_multiple_calls() {
    mock_command "gh" "ok"

    gh api repos/testorg/testrepo/pulls
    gh api repos/testorg/testrepo/issues

    local call_count
    call_count=$(get_mock_call_count "gh")

    assert_equals "2" "$call_count"
}

# Run all tests
run_all_tests
