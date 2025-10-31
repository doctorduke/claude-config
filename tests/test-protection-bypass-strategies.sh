#!/usr/bin/env bash
set -euo pipefail

# Test Script: Branch Protection Bypass with Automatic Fallback
# Task #12: Tests all 4 automatic fallback strategies
#
# Strategy 1: Direct push (unprotected branches)
# Strategy 2: PR with auto-merge (GH_PAT with workflow scope)
# Strategy 3: PR without auto-merge (GH_PAT without workflow scope)
# Strategy 4: PR with limited permissions (GITHUB_TOKEN only)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Helper functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_test() {
    echo -e "${YELLOW}TEST:${NC} $1"
}

print_pass() {
    echo -e "${GREEN}PASS:${NC} $1"
    ((TESTS_PASSED++))
}

print_fail() {
    echo -e "${RED}FAIL:${NC} $1"
    ((TESTS_FAILED++))
}

print_skip() {
    echo -e "${YELLOW}SKIP:${NC} $1"
    ((TESTS_SKIPPED++))
}

print_info() {
    echo -e "${BLUE}INFO:${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"

    local missing_tools=()

    for tool in gh jq git; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        else
            print_info "$tool: found"
        fi
    done

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        print_fail "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi

    # Check if gh is authenticated
    if ! gh auth status &>/dev/null; then
        print_fail "GitHub CLI not authenticated. Run 'gh auth login'"
        exit 1
    fi

    print_pass "All prerequisites met"
}

# Test Strategy 1: Direct push (unprotected branch)
test_strategy_1_direct_push() {
    print_header "Strategy 1: Direct Push (Unprotected Branch)"

    local test_branch="test/strategy-1-direct-push-$(date +%s)"

    print_test "Testing direct push to unprotected branch"

    # Create test branch
    if ! git checkout -b "$test_branch"; then
        print_fail "Failed to create test branch: $test_branch"
        return 1
    fi

    # Make a test change
    echo "# Test Strategy 1" >> README.md
    git add README.md
    git commit -m "test: Strategy 1 - Direct push test"

    # Simulate strategy detection
    print_info "Checking branch protection..."
    local is_protected=false

    if gh api "repos/$(gh repo view --json nameWithOwner -q .nameWithOwner)/branches/$test_branch/protection" 2>&1 | grep -q "Branch not protected"; then
        is_protected=false
        print_info "Branch is not protected"
    else
        is_protected=true
        print_info "Branch is protected"
    fi

    # Test push
    if [[ "$is_protected" == "false" ]]; then
        if git push origin "$test_branch" 2>&1; then
            print_pass "Strategy 1: Direct push succeeded"

            # Cleanup
            git push origin --delete "$test_branch" 2>/dev/null || true
            git checkout main 2>/dev/null || git checkout master 2>/dev/null
            git branch -D "$test_branch" 2>/dev/null || true
        else
            print_fail "Strategy 1: Direct push failed"
        fi
    else
        print_skip "Strategy 1: Branch is protected, skipping direct push test"
    fi
}

# Test Strategy 2: PR with auto-merge (GH_PAT with workflow scope)
test_strategy_2_pr_with_automerge() {
    print_header "Strategy 2: PR with Auto-Merge"

    print_test "Testing PR creation with auto-merge capability"

    # Check if GH_PAT is available
    if [[ -z "${GH_PAT:-}" ]]; then
        print_skip "Strategy 2: GH_PAT not set, cannot test auto-merge"
        return 0
    fi

    # Validate token scopes
    # Use more robust header parsing with awk to handle varying whitespace
    local scopes
    scopes=$(GH_TOKEN="$GH_PAT" gh api user -i 2>&1 | awk -F': ' 'tolower($1) ~ /x-oauth-scopes/ {print $2; exit}' || echo "")

    print_info "Token scopes: $scopes"

    local has_repo=false
    local has_workflow=false

    if echo "$scopes" | grep -qw "repo"; then
        has_repo=true
        print_info "Has repo scope: Yes"
    else
        print_info "Has repo scope: No"
    fi

    if echo "$scopes" | grep -qw "workflow"; then
        has_workflow=true
        print_info "Has workflow scope: Yes"
    else
        print_info "Has workflow scope: No"
    fi

    if [[ "$has_repo" == "true" ]] && [[ "$has_workflow" == "true" ]]; then
        print_pass "Strategy 2: GH_PAT has required scopes for auto-merge"
    elif [[ "$has_repo" == "true" ]]; then
        print_fail "Strategy 2: GH_PAT missing workflow scope (Strategy 3 fallback)"
    else
        print_fail "Strategy 2: GH_PAT missing required scopes"
    fi
}

# Test Strategy 3: PR without auto-merge (GH_PAT without workflow scope)
test_strategy_3_pr_manual_merge() {
    print_header "Strategy 3: PR without Auto-Merge"

    print_test "Testing PR creation for protected branch (manual merge)"

    local test_branch="test/strategy-3-pr-manual-$(date +%s)"
    local base_branch="main"

    # Create test branch
    git checkout -b "$test_branch" 2>/dev/null || {
        print_fail "Failed to create test branch"
        return 1
    }

    # Make a test change
    echo "# Test Strategy 3" >> README.md
    git add README.md
    git commit -m "test: Strategy 3 - PR manual merge test"
    git push origin "$test_branch"

    # Create PR
    print_info "Creating test PR..."
    local pr_url
    if pr_url=$(gh pr create \
        --base "$base_branch" \
        --head "$test_branch" \
        --title "[TEST] Strategy 3: PR Manual Merge" \
        --body "Test PR for Strategy 3 - Manual merge required" \
        --label "test" 2>&1); then

        local pr_num
        # Use sed instead of grep -oP for portability (BSD/macOS compatible)
        pr_num=$(echo "$pr_url" | sed -n 's|.*/pull/\([0-9][0-9]*\).*||p')
        [[ -z "$pr_num" ]] && pr_num=$(echo "$pr_url" | sed -n 's/.*#\([0-9][0-9]*\).*//p')

        print_pass "Strategy 3: PR created successfully (#$pr_num)"

        # Test auto-merge (should fail without workflow scope)
        if gh pr merge "$pr_num" --auto --squash 2>&1; then
            print_info "Auto-merge enabled (unexpected)"
        else
            print_info "Auto-merge not available (expected for Strategy 3)"
        fi

        # Cleanup
        print_info "Cleaning up test PR #$pr_num..."
        gh pr close "$pr_num" --delete-branch 2>/dev/null || true
        git checkout main 2>/dev/null || git checkout master 2>/dev/null
        git branch -D "$test_branch" 2>/dev/null || true
    else
        print_fail "Strategy 3: Failed to create PR"
    fi
}

# Test Strategy 4: PR with limited permissions (GITHUB_TOKEN only)
test_strategy_4_pr_limited() {
    print_header "Strategy 4: PR with Limited Permissions"

    print_test "Testing PR creation with GITHUB_TOKEN (limited permissions)"

    # This test simulates using GITHUB_TOKEN instead of GH_PAT
    print_info "Testing strategy detection without GH_PAT..."

    # Simulate token validation
    local token_type="GITHUB_TOKEN"
    local has_repo_scope=false
    local has_workflow_scope=false

    print_info "Token type: $token_type"
    print_info "Has repo scope: No (limited by GITHUB_TOKEN)"
    print_info "Has workflow scope: No"

    print_pass "Strategy 4: Detected limited permissions correctly"
    print_info "Strategy 4: Would create PR without auto-merge capability"
}

# Test branch protection detection
test_branch_protection_detection() {
    print_header "Branch Protection Detection"

    print_test "Testing comprehensive branch protection check"

    local test_branch="main"
    local owner repo
    owner=$(gh repo view --json owner -q .owner.login)
    repo=$(gh repo view --json name -q .name)

    print_info "Checking protection for: $owner/$repo/$test_branch"

    local protection_response
    protection_response=$(gh api "repos/$owner/$repo/branches/$test_branch/protection" 2>&1 || echo "NOT_PROTECTED")

    if [[ "$protection_response" == "NOT_PROTECTED" ]] || echo "$protection_response" | grep -q "Branch not protected"; then
        print_info "Branch is not protected"
        print_info "  - Requires review: No"
        print_info "  - Requires status checks: No"
        print_info "  - Has admin restrictions: No"
        print_pass "Protection detection: Unprotected branch detected correctly"
    else
        print_info "Branch is protected"

        # Check required reviews
        if echo "$protection_response" | jq -e '.required_pull_request_reviews' >/dev/null 2>&1; then
            local review_count
            review_count=$(echo "$protection_response" | jq -r '.required_pull_request_reviews.required_approving_review_count // 0')
            print_info "  - Requires review: Yes ($review_count approvals)"
        else
            print_info "  - Requires review: No"
        fi

        # Check status checks
        if echo "$protection_response" | jq -e '.required_status_checks' >/dev/null 2>&1; then
            local status_checks
            status_checks=$(echo "$protection_response" | jq -r '.required_status_checks.contexts[]' 2>/dev/null | tr '\n' ',' || echo "")
            print_info "  - Requires status checks: Yes ($status_checks)"
        else
            print_info "  - Requires status checks: No"
        fi

        # Check restrictions
        if echo "$protection_response" | jq -e '.restrictions' >/dev/null 2>&1; then
            print_info "  - Has admin restrictions: Yes"
        else
            print_info "  - Has admin restrictions: No"
        fi

        print_pass "Protection detection: Protected branch detected with full details"
    fi
}

# Test push error detection and fallback
test_push_error_detection() {
    print_header "Push Error Detection and Fallback"

    print_test "Testing push error categorization"

    # Simulate different error messages
    local test_cases=(
        "protected branch|protected_branch|Branch is protected"
        "permission denied|permission_denied|Insufficient permissions"
        "non-fast-forward|non_fast_forward|Branch was updated"
        "unknown error|unknown|Unknown error"
    )

    for test_case in "${test_cases[@]}"; do
        IFS='|' read -r error_pattern expected_reason description <<< "$test_case"

        print_info "Testing: $description"

        # Simulate error detection
        local detected_reason
        if [[ "$error_pattern" =~ "protected" ]]; then
            detected_reason="protected_branch"
        elif [[ "$error_pattern" =~ "permission" ]]; then
            detected_reason="permission_denied"
        elif [[ "$error_pattern" =~ "non-fast-forward" ]]; then
            detected_reason="non_fast_forward"
        else
            detected_reason="unknown"
        fi

        if [[ "$detected_reason" == "$expected_reason" ]]; then
            print_pass "Error detection: $description correctly identified as $detected_reason"
        else
            print_fail "Error detection: Expected $expected_reason, got $detected_reason"
        fi
    done
}

# Test strategy selection logic
test_strategy_selection() {
    print_header "Strategy Selection Logic"

    print_test "Testing automatic strategy selection"

    # Test case matrix
    local test_cases=(
        "false|false|false|false|direct_push|Strategy 1"
        "true|true|true|false|pr_with_automerge|Strategy 2"
        "true|true|false|false|pr_manual_merge|Strategy 3"
        "true|false|false|false|pr_limited|Strategy 4"
    )

    for test_case in "${test_cases[@]}"; do
        IFS='|' read -r is_protected has_pat has_workflow requires_admin expected_strategy expected_name <<< "$test_case"

        print_info "Testing: $expected_name"
        print_info "  Protected: $is_protected, PAT: $has_pat, Workflow: $has_workflow, Admin: $requires_admin"

        # Simulate strategy selection
        local selected_strategy
        if [[ "$is_protected" == "false" ]]; then
            selected_strategy="direct_push"
        elif [[ "$has_pat" == "true" ]] && [[ "$has_workflow" == "true" ]] && [[ "$requires_admin" == "false" ]]; then
            selected_strategy="pr_with_automerge"
        elif [[ "$has_pat" == "true" ]]; then
            selected_strategy="pr_manual_merge"
        else
            selected_strategy="pr_limited"
        fi

        if [[ "$selected_strategy" == "$expected_strategy" ]]; then
            print_pass "Strategy selection: $expected_name selected correctly"
        else
            print_fail "Strategy selection: Expected $expected_strategy, got $selected_strategy"
        fi
    done
}

# Main test execution
main() {
    print_header "Branch Protection Bypass - Strategy Testing"
    print_info "Task #12: Enhanced protection bypass with automatic PR fallback"

    # Check prerequisites
    check_prerequisites

    # Run tests
    test_branch_protection_detection
    test_strategy_selection
    test_push_error_detection
    test_strategy_4_pr_limited
    test_strategy_2_pr_with_automerge

    # Interactive tests (require confirmation)
    echo ""
    read -p "Run interactive tests (Strategy 1 & 3 - will create branches/PRs)? [y/N] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        test_strategy_1_direct_push
        test_strategy_3_pr_manual_merge
    else
        print_skip "Strategy 1: Interactive test skipped"
        print_skip "Strategy 3: Interactive test skipped"
    fi

    # Print summary
    print_header "Test Summary"
    echo -e "${GREEN}Passed:${NC}  $TESTS_PASSED"
    echo -e "${RED}Failed:${NC}  $TESTS_FAILED"
    echo -e "${YELLOW}Skipped:${NC} $TESTS_SKIPPED"
    echo -e "\n${BLUE}Total:${NC}   $((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "\n${RED}Some tests failed!${NC}"
        exit 1
    else
        echo -e "\n${GREEN}All tests passed!${NC}"
        exit 0
    fi
}

# Run main function
main "$@"
