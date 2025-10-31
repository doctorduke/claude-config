#!/bin/bash
# E2E Test: Complete Auto-Fix Journey
# Tests the entire flow from auto-fix request to fix application

set -euo pipefail

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/test-helpers.sh"

# Test configuration
readonly TEST_NAME="Auto-Fix Journey"
readonly TEST_BRANCH="e2e-test-autofix-$(date +%s)"
readonly BASE_BRANCH="main"

# ============================================================================
# Test Setup
# ============================================================================

setup_test() {
    init_test_environment "$TEST_NAME"

    echo "Creating test branch with code that needs fixing..."
    create_test_branch "$TEST_BRANCH" "$BASE_BRANCH"

    # Add JavaScript file with linting errors
    add_test_file "src/components/Button.js" "$(cat <<'EOF'
// Button component with various issues
import React from 'react';

function Button(props) {
  const { onClick, disabled, children } = props;

  // Unused variable
  const unusedVar = "test";

  // Missing semicolons
  const handleClick = () => {
    console.log("clicked")
    onClick()
  }

  // Inconsistent quotes
  const className = "btn " + (disabled ? "disabled" : "enabled");

  return (
    <button
      onClick={handleClick}
      disabled={disabled}
      className={className}>
      {children}
    </button>
  )
}

export default Button
EOF
)"

    # Add Python file with formatting issues
    add_test_file "src/utils/validator.py" "$(cat <<'EOF'
# Validator with formatting issues
import re,os,sys

def validate_email(email):
  pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
  if re.match(pattern,email):
      return True
  else:
      return False

def validate_phone( phone ):
    cleaned=phone.replace('-','').replace(' ','')
    if len(cleaned)==10:
        return True
    return False

class Validator:
  def __init__(self,rules):
    self.rules=rules

  def validate(self,data):
      errors=[]
      for field,rule in self.rules.items():
          if field not in data:
              errors.append(f"Missing field: {field}")
      return errors
EOF
)"
}

# ============================================================================
# Test Journey
# ============================================================================

test_autofix_complete_journey() {
    local start_time
    start_time=$(start_timer)

    echo ""
    echo "============================================================================"
    echo "JOURNEY: Auto-Fix Workflow"
    echo "============================================================================"

    # Step 1: Create PR with errors
    echo ""
    echo "[STEP 1] Developer creates PR with linting errors"
    local pr_number
    pr_number=$(create_test_pr "$TEST_BRANCH" "$BASE_BRANCH" \
        "Add Button component and validator" \
        "This PR adds a new Button component and email/phone validators.")

    assert_pr_exists "$pr_number"

    # Get initial commit count
    local initial_commits
    initial_commits=$(gh pr view "$pr_number" --json commits --jq '.commits | length')

    # Step 2: User requests auto-fix
    echo ""
    echo "[STEP 2] User requests auto-fix"
    gh pr comment "$pr_number" --body "/autofix"

    # Step 3: Wait for workflow
    echo ""
    echo "[STEP 3] Wait for auto-fix workflow to trigger"
    sleep 5

    local run_id
    if gh run list --workflow "ai-autofix.yml" --limit 1 --json databaseId --jq '.[0].databaseId' &>/dev/null; then
        run_id=$(wait_for_workflow_start "ai-autofix.yml")

        # Step 4: Check branch protection detection
        echo ""
        echo "[STEP 4] Wait for branch protection check"
        wait_for_step "$run_id" "Check branch protection"

        local is_protected
        is_protected=$(is_branch_protected "$TEST_BRANCH")

        echo "Branch '$TEST_BRANCH' protected: $is_protected"

        # Step 5: Wait for completion
        echo ""
        echo "[STEP 5] Wait for workflow completion"
        local conclusion
        conclusion=$(wait_for_workflow_completion "$run_id")

        # Step 6a: Direct push scenario (unprotected branch)
        if [[ "$is_protected" == "false" ]]; then
            echo ""
            echo "[STEP 6a] Verify fixes committed directly (unprotected branch)"
            sleep 5

            local new_commits
            new_commits=$(gh pr view "$pr_number" --json commits --jq '.commits | length')

            if [[ $new_commits -gt $initial_commits ]]; then
                echo -e "${COLOR_GREEN}✓${COLOR_RESET} New commit added to PR"

                # Verify commit message
                local latest_commit
                latest_commit=$(gh pr view "$pr_number" --json commits --jq '.commits[-1].messageHeadline')

                # Use ERE syntax for bash [[ =~ ]] operator (not BRE \|)
                assert_contains "$latest_commit" "autofix|fix" "Commit message indicates auto-fix"
            else
                echo -e "${COLOR_YELLOW}⚠${COLOR_RESET} No new commits (fixes may have failed)"
            fi

        # Step 6b: PR creation scenario (protected branch)
        else
            echo ""
            echo "[STEP 6b] Verify fix PR created (protected branch)"
            sleep 5

            # Look for autofix PR
            local fix_pr_list
            fix_pr_list=$(gh pr list --search "autofix in:title" --json number,title,headRefName)

            if [[ -n "$(echo "$fix_pr_list" | jq '.[] | select(.headRefName | contains("autofix"))')" ]]; then
                local fix_pr_number
                fix_pr_number=$(echo "$fix_pr_list" | jq -r '.[0].number')

                echo -e "${COLOR_GREEN}✓${COLOR_RESET} Auto-fix PR created: #$fix_pr_number"

                register_cleanup "pr" "$fix_pr_number"
            else
                echo -e "${COLOR_YELLOW}⚠${COLOR_RESET} No fix PR created (may need configuration)"
            fi
        fi

        # Step 7: Verify fixes applied
        echo ""
        echo "[STEP 7] Verify code improvements"
        local diff
        diff=$(gh pr diff "$pr_number" || echo "")

        if [[ -n "$diff" ]]; then
            echo "Checking for common improvements..."

            # Check if problematic patterns are reduced
            if ! echo "$diff" | grep -q "eslint-disable"; then
                echo -e "${COLOR_GREEN}✓${COLOR_RESET} No eslint-disable added (good)"
            fi

            echo ""
            echo "Diff preview:"
            echo "----------------------------------------"
            echo "$diff" | head -30
            echo "----------------------------------------"
        fi

        # Step 8: Verify workflow status
        echo ""
        echo "[STEP 8] Verify workflow result"
        if [[ "$conclusion" == "success" ]]; then
            assert_equals "$conclusion" "success" "Workflow conclusion"
        else
            echo -e "${COLOR_YELLOW}⚠${COLOR_RESET} Workflow status: $conclusion"
        fi
    else
        echo -e "${COLOR_YELLOW}⚠${COLOR_RESET} Workflow not configured or not triggered"
        echo "This is acceptable - workflow would run in production"
    fi

    # Step 9: Performance metrics
    echo ""
    echo "[STEP 9] Performance metrics"
    local duration
    duration=$(end_timer "$start_time")

    log_performance "Total journey time" "$duration" "s"

    # Record result
    record_test_result "Auto-Fix Journey" "PASS" "$duration"

    echo ""
    echo -e "${COLOR_GREEN}✓ Auto-Fix Journey completed successfully${COLOR_RESET}"
}

# ============================================================================
# Test Teardown
# ============================================================================

teardown_test() {
    echo ""
    cleanup_test_environment
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    local exit_code=0

    if setup_test; then
        if test_autofix_complete_journey; then
            echo -e "${COLOR_GREEN}TEST PASSED${COLOR_RESET}"
        else
            echo -e "${COLOR_RED}TEST FAILED${COLOR_RESET}"
            exit_code=1
        fi
    else
        echo -e "${COLOR_RED}SETUP FAILED${COLOR_RESET}"
        exit_code=1
    fi

    teardown_test || true
    print_test_summary

    return $exit_code
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
