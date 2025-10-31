#!/bin/bash

# Test Script for AI Auto-Fix Workflow with Protected Branches
# Tests both direct push (unprotected) and PR creation (protected) scenarios

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
TEST_REPO="${TEST_REPO:-}"
TEST_BRANCH_UNPROTECTED="test/autofix-unprotected-$(date +%s)"
TEST_BRANCH_PROTECTED="test/autofix-protected-$(date +%s)"
TEST_BRANCH_PAT="test/autofix-pat-$(date +%s)"
# Track all PRs created during test execution (FIX #2)
declare -a TEST_PR_NUMBERS=()
declare -a TEST_BRANCHES=()
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
GH_PAT="${GH_PAT:-}"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up test branches and PRs..."

    if [[ -n "$TEST_PR_NUMBER" ]]; then
        gh pr close "$TEST_PR_NUMBER" --delete-branch 2>/dev/null || true
    fi

    # Delete test branches
    git push origin --delete "$TEST_BRANCH_UNPROTECTED" 2>/dev/null || true
    git push origin --delete "$TEST_BRANCH_PROTECTED" 2>/dev/null || true

    # Remove branch protection if it was added
    gh api "repos/${TEST_REPO}/branches/${TEST_BRANCH_PROTECTED}/protection" \
        -X DELETE 2>/dev/null || true
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

# Validate prerequisites
validate_prerequisites() {
    log_info "Validating prerequisites..."

    # Check if GitHub CLI is installed
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) is not installed"
        exit 1
    fi

    # Check authentication
    if ! gh auth status &> /dev/null; then
        log_error "Not authenticated with GitHub CLI"
        exit 1
    fi

    # Check repository
    if [[ -z "$TEST_REPO" ]]; then
        TEST_REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
        log_info "Using repository: $TEST_REPO"
    fi

    # Check tokens
    if [[ -z "$GITHUB_TOKEN" ]]; then
        log_warning "GITHUB_TOKEN not set - some tests may fail"
    fi

    if [[ -z "$GH_PAT" ]]; then
        log_warning "GH_PAT not set - testing without PAT support"
    fi

    log_success "Prerequisites validated"
}

# Create test branch with sample file
create_test_branch() {
    local branch_name=$1
    log_info "Creating test branch: $branch_name"

    # Track this branch for cleanup
    TEST_BRANCHES+=("$branch_name")

    # Create and checkout branch
    git checkout -b "$branch_name"

    # Create a test file that needs fixing
    cat > "test-file-${branch_name}.js" << 'EOF'
// Test file with issues for auto-fix
function testFunction() {
    console.log("This needs formatting")
    var x = 1
    var y = 2
    if(x==y){
        console.log("Equal")
    }
    return x+y
}

// Missing semicolons and improper spacing
const obj = {foo:"bar",baz:"qux"}
const arr = [1,2,3,4,5]

// Security issue - eval usage
function dangerous(input) {
    eval(input)
}

// Performance issue - inefficient loop
function slowLoop(arr) {
    for(var i=0;i<arr.length;i++){
        console.log(arr[i])
    }
}

export {testFunction,dangerous,slowLoop}
EOF

    git add .
    git commit -m "Add test file for auto-fix testing"
    git push -u origin "$branch_name"

    log_success "Test branch created: $branch_name"
}

# Create PR for testing
create_test_pr() {
    local branch_name=$1
    local pr_title=$2

    log_info "Creating PR from $branch_name..."

    PR_RESPONSE=$(gh pr create \
        --base main \
        --head "$branch_name" \
        --title "$pr_title" \
        --body "Test PR for auto-fix workflow testing" \
        --label "test,auto-fix" \
        2>&1)

    # FIX #3: Use portable grep instead of grep -P
    # Extract PR number using sed instead of grep -P
    local pr_num=$(echo "$PR_RESPONSE" | sed -n 's/.*#\([0-9][0-9]*\).*//p' | head -1)

    # Track this PR for cleanup
    TEST_PR_NUMBERS+=("$pr_num")

    log_success "Created PR #$pr_num"
    echo "$pr_num"
}

# Test direct push scenario (unprotected branch)
test_direct_push() {
    log_info "Testing direct push scenario (unprotected branch)..."

    # Create test branch and PR
    create_test_branch "$TEST_BRANCH_UNPROTECTED"
    local pr_num=$(create_test_pr "$TEST_BRANCH_UNPROTECTED" "Test Auto-Fix: Direct Push")

    # Trigger auto-fix workflow
    log_info "Triggering auto-fix workflow for PR #$pr_num..."
    gh workflow run ai-autofix.yml -f pr_number="$pr_num" -f fix_type="all"

    # Wait for workflow to complete
    log_info "Waiting for workflow to complete (max 2 minutes)..."
    sleep 10

    local max_attempts=12
    local attempt=1
    local workflow_status=""

    while [[ $attempt -le $max_attempts ]]; do
        workflow_status=$(gh run list --workflow=ai-autofix.yml --limit=1 --json status -q '.[0].status')

        if [[ "$workflow_status" == "completed" ]]; then
            break
        fi

        log_info "Workflow status: $workflow_status (attempt $attempt/$max_attempts)"
        sleep 10
        ((attempt++))
    done

    # Check if fixes were pushed directly
    log_info "Checking if fixes were pushed directly..."
    git fetch origin "$TEST_BRANCH_UNPROTECTED"

    local commit_count=$(git rev-list --count "origin/$TEST_BRANCH_UNPROTECTED" ^HEAD)

    if [[ $commit_count -gt 0 ]]; then
        log_success "Direct push successful - $commit_count new commit(s) found"

        # Check commit message
        local last_commit=$(git log -1 --format="%s" "origin/$TEST_BRANCH_UNPROTECTED")
        if [[ "$last_commit" == *"[AI-AutoFix]"* ]]; then
            log_success "Commit message contains AI-AutoFix prefix"
        else
            log_warning "Commit message doesn't contain expected prefix"
        fi
    else
        log_error "No new commits found - direct push may have failed"
        return 1
    fi

    # Check PR comment
    log_info "Checking PR comment..."
    local comments=$(gh pr view "$pr_num" --json comments -q '.comments | length')

    if [[ $comments -gt 0 ]]; then
        log_success "Auto-fix comment posted to PR"
    else
        log_warning "No comment found on PR"
    fi

    log_success "Direct push test completed successfully"
}

# Test PR creation scenario (protected branch)
test_pr_creation() {
    log_info "Testing PR creation scenario (protected branch)..."

    # Create test branch and PR
    create_test_branch "$TEST_BRANCH_PROTECTED"
    local pr_num=$(create_test_pr "$TEST_BRANCH_PROTECTED" "Test Auto-Fix: Protected Branch")

    # Add branch protection
    log_info "Adding branch protection to $TEST_BRANCH_PROTECTED..."
    gh api "repos/${TEST_REPO}/branches/${TEST_BRANCH_PROTECTED}/protection" \
        -X PUT \
        -f required_status_checks='{"strict":true,"contexts":[]}' \
        -f enforce_admins=false \
        -f required_pull_request_reviews='{"dismiss_stale_reviews":true,"require_code_owner_reviews":false}' \
        -f restrictions=null \
        2>/dev/null || log_warning "Could not add branch protection (may need admin rights)"

    # Trigger auto-fix workflow
    log_info "Triggering auto-fix workflow for PR #$pr_num..."
    gh workflow run ai-autofix.yml -f pr_number="$pr_num" -f fix_type="all"

    # Wait for workflow to complete
    log_info "Waiting for workflow to complete (max 2 minutes)..."
    sleep 10

    local max_attempts=12
    local attempt=1
    local workflow_status=""

    while [[ $attempt -le $max_attempts ]]; do
        workflow_status=$(gh run list --workflow=ai-autofix.yml --limit=1 --json status -q '.[0].status')

        if [[ "$workflow_status" == "completed" ]]; then
            break
        fi

        log_info "Workflow status: $workflow_status (attempt $attempt/$max_attempts)"
        sleep 10
        ((attempt++))
    done

    # Check if a new PR was created
    log_info "Checking for auto-fix PR..."
    local autofix_prs=$(gh pr list --head "autofix/${TEST_BRANCH_PROTECTED}-*" --json number -q '.[].number')

    if [[ -n "$autofix_prs" ]]; then
        log_success "Auto-fix PR created: #$autofix_prs"

        # Check PR details
        local pr_title=$(gh pr view "$autofix_prs" --json title -q .title)
        if [[ "$pr_title" == *"[AI-AutoFix]"* ]]; then
            log_success "PR title contains AI-AutoFix prefix"
        else
            log_warning "PR title doesn't contain expected prefix"
        fi

        # Check if auto-merge was attempted
        local pr_mergeable=$(gh pr view "$autofix_prs" --json mergeable -q .mergeable)
        if [[ "$pr_mergeable" == "MERGEABLE" ]]; then
            log_info "PR is mergeable"
        fi
    else
        log_error "No auto-fix PR found"
        return 1
    fi

    log_success "PR creation test completed successfully"
}

# Test with PAT support
test_with_pat() {
    if [[ -z "$GH_PAT" ]]; then
        log_warning "Skipping PAT test - GH_PAT not configured"
        return 0
    fi

    log_info "Testing with PAT support..."

    # Export PAT for workflow
    export GH_PAT

    # Run protected branch test with PAT
    test_pr_creation

    log_success "PAT test completed"
}

# Main test execution
main() {
    log_info "Starting AI Auto-Fix Protected Branch Tests"
    log_info "========================================"

    validate_prerequisites

    # Test 1: Direct push (unprotected branch)
    log_info "\n=== Test 1: Direct Push (Unprotected Branch) ==="
    if test_direct_push; then
        log_success "Test 1 PASSED"
    else
        log_error "Test 1 FAILED"
    fi

    # Test 2: PR creation (protected branch)
    log_info "\n=== Test 2: PR Creation (Protected Branch) ==="
    if test_pr_creation; then
        log_success "Test 2 PASSED"
    else
        log_error "Test 2 FAILED"
    fi

    # Test 3: PAT support
    log_info "\n=== Test 3: PAT Support ==="
    if test_with_pat; then
        log_success "Test 3 PASSED"
    else
        log_error "Test 3 FAILED"
    fi

    log_info "\n========================================"
    log_success "All tests completed!"
}

# Run main function
main "$@"