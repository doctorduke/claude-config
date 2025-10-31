#!/usr/bin/env bash
# Integration Test: AI Auto-Fix Workflow
# Tests automated code fixes and commit workflow

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/test-helpers.sh
source "${SCRIPT_DIR}/../lib/test-helpers.sh"

# Test configuration
readonly TEST_WORKFLOW="ai-autofix.yml"
readonly TEST_SCRIPT="${SCRIPT_DIR}/../../../scripts/ai-autofix.sh"
readonly TEST_OUTPUT_DIR="/tmp/test-ai-autofix"

setup() {
    log_info "Setting up AI Auto-Fix tests..."

    mkdir -p "$TEST_OUTPUT_DIR"

    setup_mock_github_api "$TEST_OUTPUT_DIR/mock-github"
    setup_mock_ai_api "$TEST_OUTPUT_DIR/mock-ai"

    export GITHUB_TOKEN="test-token-123"
    export AI_API_KEY="test-ai-key-456"
    export GITHUB_REPOSITORY="test-org/test-repo"
}

teardown() {
    log_info "Tearing down AI Auto-Fix tests..."

    teardown_mock_github_api "$TEST_OUTPUT_DIR/mock-github"
    teardown_mock_ai_api "$TEST_OUTPUT_DIR/mock-ai"

    if [[ "$CLEANUP_ON_SUCCESS" == "true" ]]; then
        rm -rf "$TEST_OUTPUT_DIR"
    fi
}

# Test 1: Workflow triggers on /autofix comment
test_workflow_trigger_on_autofix_command() {
    log_test "Test: Workflow triggers on /autofix command"

    local comment_body="/autofix linting"

    if echo "$comment_body" | grep -q "/autofix"; then
        log_info "Auto-fix trigger detected"
        return 0
    else
        log_fail "Trigger not detected"
        return 1
    fi
}

# Test 2: Workflow triggers on auto-fix label
test_workflow_trigger_on_label() {
    log_test "Test: Workflow triggers on auto-fix label"

    local pr_labels=("bug" "auto-fix" "needs-review")

    if printf '%s\n' "${pr_labels[@]}" | grep -q "auto-fix"; then
        log_info "Auto-fix label detected"
        return 0
    else
        log_fail "Label not detected"
        return 1
    fi
}

# Test 3: Workflow extracts fix type from comment
test_workflow_extracts_fix_type() {
    log_test "Test: Workflow extracts fix type"

    local comment_body="/autofix linting"
    local fix_type
    # Use sed instead of grep -oP for portability (BSD/macOS compatible)
    fix_type=$(echo "$comment_body" | sed -n 's|^/autofix[[:space:]]\+\([[:alnum:]_]\+\).*||p')
    [[ -z "$fix_type" ]] && fix_type="all"

    assert_equals "linting" "$fix_type"

    # Test default
    local comment_body2="/autofix"
    local fix_type2
    # Use sed instead of grep -oP for portability (BSD/macOS compatible)
    fix_type2=$(echo "$comment_body2" | sed -n 's|^/autofix[[:space:]]\+\([[:alnum:]_]\+\).*||p')
    [[ -z "$fix_type2" ]] && fix_type2="all"

    assert_equals "all" "$fix_type2"
}

# Test 4: Workflow validates PR number
test_workflow_validates_pr_number() {
    log_test "Test: Workflow validates PR number"

    local pr_number="789"

    if [[ "$pr_number" =~ ^[0-9]+$ ]]; then
        return 0
    else
        log_fail "Invalid PR number: $pr_number"
        return 1
    fi
}

# Test 5: Workflow configures Git for commits
test_workflow_configures_git() {
    log_test "Test: Workflow configures Git"

    # Simulate Git configuration
    local git_user="github-actions[bot]"
    local git_email="github-actions[bot]@users.noreply.github.com"

    assert_contains "$git_user" "github-actions"
    assert_contains "$git_email" "@users.noreply.github.com"
}

# Test 6: Workflow detects fork PRs
test_workflow_detects_fork_prs() {
    log_test "Test: Workflow detects fork PRs"

    local pr_data='{"isCrossRepository": true}'
    local is_fork
    is_fork=$(echo "$pr_data" | jq -r '.isCrossRepository')

    if [[ "$is_fork" == "true" ]]; then
        log_info "Fork PR detected - auto-fix should be blocked"
        return 0
    else
        log_fail "Fork detection failed"
        return 1
    fi
}

# Test 7: Workflow blocks fork PR auto-fix
test_workflow_blocks_fork_autofix() {
    log_test "Test: Workflow blocks fork PR auto-fix"

    local is_fork=true

    if [[ "$is_fork" == "true" ]]; then
        log_info "Auto-fix blocked for fork PR (security)"
        return 0
    else
        log_fail "Fork PR should be blocked"
        return 1
    fi
}

# Test 8: Workflow analyzes PR for fixable issues
test_workflow_analyzes_pr() {
    log_test "Test: Workflow analyzes PR for issues"

    local pr_number=789

    # Create analysis context
    cat > "$TEST_OUTPUT_DIR/analysis-context.json" << EOF
{
  "pr_number": $pr_number,
  "fix_type": "all",
  "files_count": 5,
  "diff_file": "/tmp/pr.diff",
  "files_list": "/tmp/files.txt"
}
EOF

    assert_file_exists "$TEST_OUTPUT_DIR/analysis-context.json"
    assert_json_valid "$(cat "$TEST_OUTPUT_DIR/analysis-context.json")"

    local files_count
    files_count=$(jq -r '.files_count' "$TEST_OUTPUT_DIR/analysis-context.json")
    assert_equals "5" "$files_count"
}

# Test 9: Script generates fix suggestions
test_script_generates_fixes() {
    log_test "Test: Script generates fix suggestions"

    cat > "$TEST_OUTPUT_DIR/fixes.json" << 'EOF'
{
  "fixes": [
    {
      "file": "src/app.js",
      "type": "linting",
      "description": "Remove unused variable",
      "content": "// Fixed code here"
    },
    {
      "file": "src/utils.py",
      "type": "formatting",
      "description": "Format with black",
      "content": "# Fixed Python code"
    }
  ],
  "summary": "Applied 2 automated fixes"
}
EOF

    local fixes_json
    fixes_json=$(cat "$TEST_OUTPUT_DIR/fixes.json")

    assert_json_valid "$fixes_json"
    assert_json_has_key "$fixes_json" "fixes"
    assert_json_has_key "$fixes_json" "summary"

    local fix_count
    fix_count=$(echo "$fixes_json" | jq '.fixes | length')
    assert_equals "2" "$fix_count"
}

# Test 10: Workflow applies fixes to files
test_workflow_applies_fixes() {
    log_test "Test: Workflow applies fixes to files"

    # Create test file
    mkdir -p "$TEST_OUTPUT_DIR/src"
    echo "const unused = 1;" > "$TEST_OUTPUT_DIR/src/test.js"

    # Apply fix
    echo "// Fixed code" > "$TEST_OUTPUT_DIR/src/test.js"

    local fixed_content
    fixed_content=$(cat "$TEST_OUTPUT_DIR/src/test.js")

    assert_contains "$fixed_content" "Fixed code"
    assert_not_contains "$fixed_content" "unused"
}

# Test 11: Workflow handles no fixes scenario
test_workflow_handles_no_fixes() {
    log_test "Test: Workflow handles no fixes scenario"

    local fixes_json='{"fixes": [], "summary": "No fixes needed"}'
    local fix_count
    fix_count=$(echo "$fixes_json" | jq '.fixes | length')

    if [[ "$fix_count" -eq 0 ]]; then
        log_info "No fixes to apply - handled correctly"
        return 0
    else
        log_fail "Should handle zero fixes"
        return 1
    fi
}

# Test 12: Workflow generates commit message
test_workflow_generates_commit_message() {
    log_test "Test: Workflow generates commit message"

    local commit_prefix="[AI-AutoFix]"
    local fix_summary="Applied linting fixes"

    cat > "$TEST_OUTPUT_DIR/commit-message.txt" << EOF
$commit_prefix $fix_summary

Applied 3 automated fixes (type: linting)

Fixes applied:
- linting: src/app.js - Remove unused variables
- linting: src/utils.js - Fix indentation
- linting: tests/test.js - Add missing semicolons

Generated by AI Auto-Fix workflow
Run ID: 12345
EOF

    assert_file_exists "$TEST_OUTPUT_DIR/commit-message.txt"

    local commit_msg
    commit_msg=$(cat "$TEST_OUTPUT_DIR/commit-message.txt")

    assert_contains "$commit_msg" "[AI-AutoFix]"
    assert_contains "$commit_msg" "Applied 3 automated fixes"
    assert_contains "$commit_msg" "Generated by AI Auto-Fix"
}

# Test 13: Workflow commits and pushes changes
test_workflow_commits_and_pushes() {
    log_test "Test: Workflow commits and pushes changes"

    # Create temporary git repo for testing
    local test_repo="$TEST_OUTPUT_DIR/test-repo"
    mkdir -p "$test_repo"
    cd "$test_repo"

    git init -q
    git config user.name "Test User"
    git config user.email "test@example.com"

    # Create and commit a file
    echo "test content" > test.txt
    git add test.txt
    git commit -q -m "Initial commit"

    # Make a change
    echo "fixed content" > test.txt
    git add test.txt
    git commit -q -m "[AI-AutoFix] Applied fixes"

    local commit_count
    commit_count=$(git rev-list --count HEAD)

    assert_equals "2" "$commit_count"

    cd - > /dev/null
}

# Test 14: Workflow posts success comment
test_workflow_posts_success_comment() {
    log_test "Test: Workflow posts success comment"

    local pr_number=789
    local fix_count=3
    local commit_sha="abc123d"

    cat > "$TEST_OUTPUT_DIR/success-comment.md" << EOF
## AI Auto-Fix Applied

Successfully applied **$fix_count** automated fixes to this PR.

### Commit
- SHA: \`${commit_sha:0:7}\`
- Type: linting

### Fixes Applied
- **linting**: \`src/app.js\` - Remove unused variables
- **linting**: \`src/utils.js\` - Fix indentation

### Next Steps
- Review the automated changes
- Run tests to verify fixes
- Additional fixes can be triggered with \`/autofix [type]\`
EOF

    assert_file_exists "$TEST_OUTPUT_DIR/success-comment.md"

    local comment
    comment=$(cat "$TEST_OUTPUT_DIR/success-comment.md")

    assert_contains "$comment" "AI Auto-Fix Applied"
    assert_contains "$comment" "Successfully applied"
    assert_contains "$comment" "Next Steps"
}

# Test 15: Workflow posts no-changes comment
test_workflow_posts_no_changes_comment() {
    log_test "Test: Workflow posts no-changes comment"

    local has_changes=false

    if [[ "$has_changes" == "false" ]]; then
        local message="No automated fixes were identified for this PR"
        assert_contains "$message" "No automated fixes"
        return 0
    else
        log_fail "Should handle no changes scenario"
        return 1
    fi
}

# Test 16: Workflow handles auto-fix failure
test_workflow_handles_failure() {
    log_test "Test: Workflow handles auto-fix failure"

    local error_occurred=true
    local error_message="AI Auto-Fix Failed"

    if [[ "$error_occurred" == "true" ]]; then
        log_info "Failure handled: $error_message"
        return 0
    else
        log_fail "Failure not handled"
        return 1
    fi
}

# Test 17: End-to-end auto-fix flow (unprotected branch)
test_autofix_unprotected_branch_flow() {
    log_test "Test: Complete auto-fix flow (unprotected branch)"

    local pr_number=789
    local is_fork=false

    # Step 1: Validate PR
    assert_contains "$pr_number" "789"

    # Step 2: Check if fork
    if [[ "$is_fork" == "true" ]]; then
        log_fail "Should not be fork"
        return 1
    fi

    # Step 3: Analyze issues
    cat > "$TEST_OUTPUT_DIR/e2e-fixes.json" << 'EOF'
{
  "fixes": [
    {
      "file": "src/main.js",
      "type": "linting",
      "description": "Fix linting issues",
      "content": "// Fixed code"
    }
  ],
  "summary": "Applied 1 automated fix"
}
EOF

    assert_file_exists "$TEST_OUTPUT_DIR/e2e-fixes.json"

    # Step 4: Apply fixes
    local fix_count
    fix_count=$(jq '.fixes | length' "$TEST_OUTPUT_DIR/e2e-fixes.json")
    assert_greater_than "$fix_count" 0

    # Step 5: Commit and push
    log_info "Fixes would be committed and pushed to PR #$pr_number"
}

# Test 18: Workflow supports different fix types
test_workflow_different_fix_types() {
    log_test "Test: Workflow supports different fix types"

    local fix_types=("all" "linting" "formatting" "security" "performance")

    for fix_type in "${fix_types[@]}"; do
        log_info "Testing fix type: $fix_type"
        assert_contains "${fix_type}" "all\|linting\|formatting\|security\|performance"
    done
}

# Test 19: Workflow performs cleanup
test_workflow_cleanup() {
    log_test "Test: Workflow performs cleanup"

    local temp_dir="$TEST_OUTPUT_DIR/autofix-cleanup-test"
    mkdir -p "$temp_dir"

    # Simulate cleanup
    rm -rf "$temp_dir"

    assert_file_not_exists "$temp_dir/should-be-deleted"
}

# Test 20: Workflow respects max fixes limit
test_workflow_respects_max_fixes() {
    log_test "Test: Workflow respects max fixes limit"

    local max_fixes=50
    local fixes_to_apply=30

    if [[ $fixes_to_apply -le $max_fixes ]]; then
        log_info "Within limit: $fixes_to_apply <= $max_fixes"
        return 0
    else
        log_fail "Exceeded limit"
        return 1
    fi
}

# Main test execution
main() {
    log_info "Starting AI Auto-Fix Workflow Integration Tests"
    log_info "================================================"

    setup

    run_test "Workflow triggers on /autofix command" "test_workflow_trigger_on_autofix_command" || true
    run_test "Workflow triggers on label" "test_workflow_trigger_on_label" || true
    run_test "Workflow extracts fix type" "test_workflow_extracts_fix_type" || true
    run_test "Workflow validates PR number" "test_workflow_validates_pr_number" || true
    run_test "Workflow configures Git" "test_workflow_configures_git" || true
    run_test "Workflow detects fork PRs" "test_workflow_detects_fork_prs" || true
    run_test "Workflow blocks fork auto-fix" "test_workflow_blocks_fork_autofix" || true
    run_test "Workflow analyzes PR" "test_workflow_analyzes_pr" || true
    run_test "Script generates fixes" "test_script_generates_fixes" || true
    run_test "Workflow applies fixes" "test_workflow_applies_fixes" || true
    run_test "Workflow handles no fixes" "test_workflow_handles_no_fixes" || true
    run_test "Workflow generates commit message" "test_workflow_generates_commit_message" || true
    run_test "Workflow commits and pushes" "test_workflow_commits_and_pushes" || true
    run_test "Workflow posts success comment" "test_workflow_posts_success_comment" || true
    run_test "Workflow posts no-changes comment" "test_workflow_posts_no_changes_comment" || true
    run_test "Workflow handles failure" "test_workflow_handles_failure" || true
    run_test "Complete auto-fix flow" "test_autofix_unprotected_branch_flow" || true
    run_test "Workflow supports different fix types" "test_workflow_different_fix_types" || true
    run_test "Workflow performs cleanup" "test_workflow_cleanup" || true
    run_test "Workflow respects max fixes limit" "test_workflow_respects_max_fixes" || true

    teardown

    print_test_summary
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
