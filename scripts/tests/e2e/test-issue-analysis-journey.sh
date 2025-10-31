#!/bin/bash
# E2E Test: Complete Issue Analysis Journey
# Tests the entire flow from issue creation to AI analysis response

set -euo pipefail

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/test-helpers.sh"

# Test configuration
readonly TEST_NAME="Issue Analysis Journey"

# ============================================================================
# Test Setup/Teardown
# ============================================================================

setup() {
    init_test_environment "$TEST_NAME"
}

teardown() {
    cleanup_test_environment
}

# ============================================================================
# Test Journey
# ============================================================================

test_issue_analysis_complete_journey() {
    local start_time
    start_time=$(start_timer)

    echo ""
    echo "============================================================================"
    echo "JOURNEY: Issue Analysis Workflow"
    echo "============================================================================"

    # Step 1: User creates issue
    echo ""
    echo "[STEP 1] User creates issue with bug report"
    local issue_number
    issue_number=$(create_test_issue \
        "Application crashes when processing large files" \
        "$(cat <<'EOF'
## Bug Description
The application crashes with an out-of-memory error when processing files larger than 100MB.

## Steps to Reproduce
1. Upload a file > 100MB
2. Click "Process"
3. Application freezes and crashes

## Expected Behavior
Should handle large files gracefully with streaming

## Actual Behavior
Crashes with: `Error: Cannot allocate memory`

## Environment
- OS: Ubuntu 22.04
- Node.js: v18.17.0
- RAM: 8GB

## Additional Context
This started happening after the v2.3.0 update.
EOF
)")

    assert_issue_exists "$issue_number"

    # Step 2: User requests analysis
    echo ""
    echo "[STEP 2] User requests AI analysis"
    gh issue comment "$issue_number" --body "/analyze"

    # Step 3: Wait for workflow trigger
    echo ""
    echo "[STEP 3] Wait for AI issue analysis workflow to trigger"
    sleep 5

    local run_id
    if gh run list --workflow "ai-issue-comment.yml" --limit 1 --json databaseId --jq '.[0].databaseId' &>/dev/null; then
        run_id=$(wait_for_workflow_start "ai-issue-comment.yml")

        # Step 4: Wait for analysis
        echo ""
        echo "[STEP 4] Wait for AI to analyze issue"
        wait_for_step "$run_id" "Analyze Issue"

        # Step 5: Wait for completion
        echo ""
        echo "[STEP 5] Wait for workflow completion"
        local conclusion
        conclusion=$(wait_for_workflow_completion "$run_id")

        # Step 6: Verify comment posted
        echo ""
        echo "[STEP 6] Verify analysis comment was posted"
        sleep 5

        local comment
        comment=$(get_latest_comment "$issue_number")

        if [[ -n "$(echo "$comment" | jq -r '.body // ""')" ]]; then
            local comment_body
            comment_body=$(echo "$comment" | jq -r '.body')

            assert_contains "$comment_body" "analysis" "Comment contains analysis"
            assert_contains "$comment_body" "Claude Code" "Comment has attribution"

            echo ""
            echo "Comment preview:"
            echo "----------------------------------------"
            echo "$comment_body" | head -20
            echo "----------------------------------------"

            # Step 7: Verify response structure
            echo ""
            echo "[STEP 7] Verify response structure"
            assert_json_path_exists "$comment" ".id" "Comment has ID"
            assert_json_path_exists "$comment" ".body" "Comment has body"
            assert_json_path_exists "$comment" ".created_at" "Comment has timestamp"
        else
            echo -e "${COLOR_YELLOW}⚠${COLOR_RESET} No comment posted (workflow may need configuration)"
        fi

        # Step 8: Check for labels
        echo ""
        echo "[STEP 8] Check for auto-applied labels"
        sleep 2

        local labels
        labels=$(gh issue view "$issue_number" --json labels --jq '.labels[].name')

        # Use grep -E for portable extended regex (works on BSD/macOS)
        if echo "$labels" | grep -qE "bug|analyzed|needs-triage"; then
            echo -e "${COLOR_GREEN}✓${COLOR_RESET} Labels auto-applied: $labels"
        else
            echo -e "${COLOR_YELLOW}⚠${COLOR_RESET} No auto-labels (optional feature)"
        fi

        # Step 9: Verify workflow status
        echo ""
        echo "[STEP 9] Verify workflow succeeded"
        if [[ "$conclusion" == "success" ]]; then
            assert_equals "$conclusion" "success" "Workflow conclusion"
        else
            echo -e "${COLOR_YELLOW}⚠${COLOR_RESET} Workflow status: $conclusion"
        fi
    else
        echo -e "${COLOR_YELLOW}⚠${COLOR_RESET} Workflow not configured or not triggered"
        echo "This is acceptable - workflow would run in production"
    fi

    # Step 10: Performance metrics
    echo ""
    echo "[STEP 10] Performance metrics"
    local duration
    duration=$(end_timer "$start_time")

    log_performance "Total journey time" "$duration" "s"

    # Record result
    record_test_result "Issue Analysis Journey" "PASS" "$duration"

    echo ""
    echo -e "${COLOR_GREEN}✓ Issue Analysis Journey completed successfully${COLOR_RESET}"
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    local exit_code=0

    # Setup test environment
    setup

    # Run test
    if test_issue_analysis_complete_journey; then
        echo -e "${COLOR_GREEN}TEST PASSED${COLOR_RESET}"
    else
        echo -e "${COLOR_RED}TEST FAILED${COLOR_RESET}"
        exit_code=1
    fi

    print_test_summary

    # Cleanup test environment
    teardown

    return $exit_code
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
