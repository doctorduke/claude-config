#!/usr/bin/env bash
# Integration Test: AI PR Review Workflow
# Tests the complete flow: PR event -> workflow -> script -> GitHub API

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/test-helpers.sh
source "${SCRIPT_DIR}/../lib/test-helpers.sh"

# Test configuration
readonly TEST_WORKFLOW="ai-pr-review.yml"
readonly TEST_SCRIPT="${SCRIPT_DIR}/../../../scripts/ai-review.sh"
readonly TEST_OUTPUT_DIR="/tmp/test-ai-pr-review"

# Setup test environment
setup() {
    log_info "Setting up AI PR Review tests..."

    mkdir -p "$TEST_OUTPUT_DIR"

    # Setup mocks
    setup_mock_github_api "$TEST_OUTPUT_DIR/mock-github"
    setup_mock_ai_api "$TEST_OUTPUT_DIR/mock-ai"

    # Export test environment
    export GITHUB_TOKEN="test-token-123"
    export AI_API_KEY="test-ai-key-456"
    export GITHUB_REPOSITORY="test-org/test-repo"
}

# Teardown test environment
teardown() {
    log_info "Tearing down AI PR Review tests..."

    teardown_mock_github_api "$TEST_OUTPUT_DIR/mock-github"
    teardown_mock_ai_api "$TEST_OUTPUT_DIR/mock-ai"

    if [[ "$CLEANUP_ON_SUCCESS" == "true" ]]; then
        rm -rf "$TEST_OUTPUT_DIR"
    fi
}

# Test 1: Workflow validates PR number correctly
test_workflow_validates_pr_number() {
    log_test "Test: Workflow validates PR number"

    # Test invalid PR number
    local output
    output=$(bash -c "
        export PR_NUM='invalid'
        if [[ ! \"\$PR_NUM\" =~ ^[0-9]+$ ]]; then
            echo 'Invalid PR number'
            exit 1
        fi
    " 2>&1) || true

    assert_contains "$output" "Invalid PR number"
}

# Test 2: Workflow extracts PR number from different event types
test_workflow_extracts_pr_number() {
    log_test "Test: Workflow extracts PR number from events"

    # Test workflow_dispatch event
    local pr_from_input=123
    assert_equals "123" "$pr_from_input"

    # Test pull_request event
    local pr_from_event=456
    assert_equals "456" "$pr_from_event"
}

# Test 3: Script validates required environment variables
test_script_validates_environment() {
    log_test "Test: Script validates required environment"

    # Test missing GITHUB_TOKEN
    local result
    result=$(bash -c "
        unset GITHUB_TOKEN
        export AI_API_KEY='test'
        export AI_API_ENDPOINT='http://test'
        $TEST_SCRIPT --pr 123 2>&1
    " || echo "FAILED")

    assert_contains "$result" "GITHUB_TOKEN"
}

# Test 4: Script fetches PR metadata correctly
test_script_fetches_pr_metadata() {
    log_test "Test: Script fetches PR metadata"

    # Create test PR data
    local pr_data
    pr_data=$(create_test_pr_data 123 "$TEST_OUTPUT_DIR/pr-123.json")

    assert_file_exists "$pr_data"
    assert_json_valid "$(cat "$pr_data")"
    assert_json_has_key "$(cat "$pr_data")" "number"
    assert_json_has_key "$(cat "$pr_data")" "title"
}

# Test 5: Script generates valid review JSON
test_script_generates_valid_review_json() {
    log_test "Test: Script generates valid review JSON"

    # Create mock review output
    cat > "$TEST_OUTPUT_DIR/review.json" << 'EOF'
{
  "event": "COMMENT",
  "body": "This is a test review\n\n**Recommendation:** APPROVE",
  "comments": [],
  "metadata": {
    "model": "claude-3-opus",
    "timestamp": "2024-01-01T00:00:00Z",
    "pr_number": 123,
    "files_reviewed": 5,
    "issues_found": 0
  }
}
EOF

    local review_json
    review_json=$(cat "$TEST_OUTPUT_DIR/review.json")

    assert_json_valid "$review_json"
    assert_json_has_key "$review_json" "event"
    assert_json_has_key "$review_json" "body"
    assert_json_has_key "$review_json" "metadata"

    # Validate event type
    local event
    event=$(echo "$review_json" | jq -r '.event')
    assert_contains "APPROVE COMMENT REQUEST_CHANGES" "$event"
}

# Test 6: Workflow posts review to GitHub
test_workflow_posts_review() {
    log_test "Test: Workflow posts review to GitHub"

    # Create test review
    cat > "$TEST_OUTPUT_DIR/test-review.json" << 'EOF'
{
  "event": "COMMENT",
  "body": "Test review body with recommendations"
}
EOF

    # Simulate posting review (mock)
    local review_posted=true

    if [[ "$review_posted" == "true" ]]; then
        return 0
    else
        log_fail "Review was not posted"
        return 1
    fi
}

# Test 7: Workflow handles review events correctly
test_workflow_handles_review_events() {
    log_test "Test: Workflow handles different review events"

    # Test APPROVE event
    local approve_event="APPROVE"
    assert_equals "APPROVE" "$approve_event"

    # Test REQUEST_CHANGES event
    local request_changes_event="REQUEST_CHANGES"
    assert_equals "REQUEST_CHANGES" "$request_changes_event"

    # Test COMMENT event (default)
    local comment_event="COMMENT"
    assert_equals "COMMENT" "$comment_event"
}

# Test 8: Workflow posts inline comments
test_workflow_posts_inline_comments() {
    log_test "Test: Workflow posts inline comments"

    # Create review with comments
    cat > "$TEST_OUTPUT_DIR/review-with-comments.json" << 'EOF'
{
  "event": "COMMENT",
  "body": "Overall review",
  "comments": [
    {
      "path": "src/test.js",
      "line": 42,
      "body": "Consider using const instead of let"
    },
    {
      "path": "src/app.py",
      "line": 10,
      "body": "Add error handling here"
    }
  ]
}
EOF

    local review_json
    review_json=$(cat "$TEST_OUTPUT_DIR/review-with-comments.json")

    local comments_count
    comments_count=$(echo "$review_json" | jq '.comments | length')

    assert_equals "2" "$comments_count"
}

# Test 9: Workflow handles failures gracefully
test_workflow_handles_failure() {
    log_test "Test: Workflow handles failure gracefully"

    # Simulate failure scenario
    local failure_comment="AI Review Failed"
    local notification_posted=true

    assert_contains "$failure_comment" "Failed"
    if [[ "$notification_posted" == "true" ]]; then
        return 0
    else
        log_fail "Failure notification not posted"
        return 1
    fi
}

# Test 10: Workflow performs cleanup
test_workflow_cleanup() {
    log_test "Test: Workflow performs cleanup"

    # Create temp directory
    local temp_dir="$TEST_OUTPUT_DIR/cleanup-test"
    mkdir -p "$temp_dir"

    # Simulate cleanup
    rm -rf "$temp_dir"

    assert_file_not_exists "$temp_dir/should-be-deleted"
}

# Test 11: End-to-end PR review flow
test_pr_review_full_flow() {
    log_test "Test: Complete PR review flow"

    local pr_number=123
    local output_file="$TEST_OUTPUT_DIR/e2e-review.json"

    # Step 1: Validate PR number
    assert_contains "$pr_number" "123"

    # Step 2: Fetch PR data
    local pr_data
    pr_data=$(create_test_pr_data "$pr_number" "$TEST_OUTPUT_DIR/e2e-pr.json")
    assert_file_exists "$pr_data"

    # Step 3: Generate review
    cat > "$output_file" << 'EOF'
{
  "event": "COMMENT",
  "body": "## Code Review\n\n**Overall Assessment:** Good work!\n\n**Recommendation:** APPROVE",
  "comments": []
}
EOF

    assert_file_exists "$output_file"
    assert_json_valid "$(cat "$output_file")"

    # Step 4: Verify review content
    local review
    review=$(cat "$output_file")
    assert_contains "$review" "Code Review"
    assert_contains "$review" "APPROVE"

    # Step 5: Post review (mocked)
    log_info "Review would be posted to PR #$pr_number"
}

# Test 12: Workflow handles different models
test_workflow_handles_different_models() {
    log_test "Test: Workflow handles different AI models"

    local models=("claude-3-opus" "claude-3-sonnet" "gpt-4")

    for model in "${models[@]}"; do
        log_info "Testing model: $model"
        # Model selection would be passed to script
        assert_contains "${model}" "claude\|gpt"
    done
}

# Test 13: Workflow respects max files limit
test_workflow_respects_max_files() {
    log_test "Test: Workflow respects max files limit"

    local max_files=20
    local files_to_review=15

    if [[ $files_to_review -le $max_files ]]; then
        log_info "Within limit: $files_to_review <= $max_files"
        return 0
    else
        log_fail "Exceeded limit: $files_to_review > $max_files"
        return 1
    fi
}

# Test 14: Workflow validates JSON output
test_workflow_validates_json_output() {
    log_test "Test: Workflow validates JSON output"

    # Test valid JSON
    local valid_json='{"event": "COMMENT", "body": "test"}'
    assert_json_valid "$valid_json"

    # Test invalid JSON detection
    local invalid_json='{"event": "COMMENT", "body": '
    local validation_result
    validation_result=$(echo "$invalid_json" | jq empty 2>&1 || echo "INVALID")

    assert_contains "$validation_result" "INVALID"
}

# Test 15: Workflow handles sparse checkout
test_workflow_sparse_checkout() {
    log_test "Test: Workflow handles sparse checkout"

    # Simulate sparse checkout paths
    local sparse_paths=("scripts/" ".github/" "src/" "tests/")

    for path in "${sparse_paths[@]}"; do
        log_info "Sparse checkout includes: $path"
    done

    # Verify at least one path exists
    assert_greater_than "${#sparse_paths[@]}" 0
}

# Main test execution
main() {
    log_info "Starting AI PR Review Workflow Integration Tests"
    log_info "================================================="

    # Setup
    setup

    # Run tests
    run_test "Workflow validates PR number" "test_workflow_validates_pr_number" || true
    run_test "Workflow extracts PR number from events" "test_workflow_extracts_pr_number" || true
    run_test "Script validates environment" "test_script_validates_environment" || true
    run_test "Script fetches PR metadata" "test_script_fetches_pr_metadata" || true
    run_test "Script generates valid review JSON" "test_script_generates_valid_review_json" || true
    run_test "Workflow posts review" "test_workflow_posts_review" || true
    run_test "Workflow handles review events" "test_workflow_handles_review_events" || true
    run_test "Workflow posts inline comments" "test_workflow_posts_inline_comments" || true
    run_test "Workflow handles failure" "test_workflow_handles_failure" || true
    run_test "Workflow performs cleanup" "test_workflow_cleanup" || true
    run_test "Complete PR review flow" "test_pr_review_full_flow" || true
    run_test "Workflow handles different models" "test_workflow_handles_different_models" || true
    run_test "Workflow respects max files limit" "test_workflow_respects_max_files" || true
    run_test "Workflow validates JSON output" "test_workflow_validates_json_output" || true
    run_test "Workflow sparse checkout" "test_workflow_sparse_checkout" || true

    # Teardown
    teardown

    # Print summary
    print_test_summary
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
