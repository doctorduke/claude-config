#!/bin/bash
# E2E Test Helper Functions
# Provides utilities for end-to-end testing of workflows

set -euo pipefail

# Test colors
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_RESET='\033[0m'

# Test timeouts
readonly WORKFLOW_START_TIMEOUT=60        # 1 minute
readonly WORKFLOW_COMPLETION_TIMEOUT=600  # 10 minutes
readonly STEP_TIMEOUT=120                 # 2 minutes
readonly PR_REVIEW_TIMEOUT=300            # 5 minutes

# Test state
TEST_RESULTS=()
TEST_START_TIME=""
CLEANUP_ITEMS=()

# ============================================================================
# Test Lifecycle Functions
# ============================================================================

# Initialize test environment
init_test_environment() {
    local test_name="${1:-unknown}"

    echo -e "${COLOR_BLUE}[TEST] Starting: $test_name${COLOR_RESET}"
    TEST_START_TIME=$(date +%s)

    # Verify required environment
    assert_env_var "GITHUB_TOKEN"
    assert_env_var "TEST_REPO"

    # Set GitHub CLI to use proper repo
    export GH_REPO="${TEST_REPO}"
}

# Cleanup test resources
cleanup_test_environment() {
    echo -e "${COLOR_BLUE}[CLEANUP] Starting cleanup...${COLOR_RESET}"

    for item in "${CLEANUP_ITEMS[@]}"; do
        local type="${item%%:*}"
        local value="${item#*:}"

        case "$type" in
            pr)
                echo "Closing PR #$value"
                gh pr close "$value" --delete-branch 2>/dev/null || true
                ;;
            issue)
                echo "Closing issue #$value"
                gh issue close "$value" 2>/dev/null || true
                ;;
            branch)
                echo "Deleting branch $value"
                git push origin --delete "$value" 2>/dev/null || true
                ;;
            file)
                echo "Removing file $value"
                rm -f "$value" 2>/dev/null || true
                ;;
        esac
    done

    CLEANUP_ITEMS=()
}

# Register item for cleanup
register_cleanup() {
    local type="$1"
    local value="$2"
    CLEANUP_ITEMS+=("$type:$value")
}

# ============================================================================
# Assertion Functions
# ============================================================================

# Assert environment variable exists
assert_env_var() {
    local var_name="$1"

    if [[ -z "${!var_name:-}" ]]; then
        fail_test "Required environment variable not set: $var_name"
    fi
}

# Assert file exists
assert_file_exists() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        fail_test "File does not exist: $file"
    fi

    echo -e "${COLOR_GREEN}✓${COLOR_RESET} File exists: $file"
}

# Assert directory exists
assert_dir_exists() {
    local dir="$1"

    if [[ ! -d "$dir" ]]; then
        fail_test "Directory does not exist: $dir"
    fi

    echo -e "${COLOR_GREEN}✓${COLOR_RESET} Directory exists: $dir"
}

# Assert command succeeds
assert_command_success() {
    local description="$1"
    shift

    if ! "$@"; then
        fail_test "Command failed: $description"
    fi

    echo -e "${COLOR_GREEN}✓${COLOR_RESET} $description"
}

# Assert string equals
assert_equals() {
    local actual="$1"
    local expected="$2"
    local message="${3:-Values not equal}"

    if [[ "$actual" != "$expected" ]]; then
        fail_test "$message (expected: '$expected', got: '$actual')"
    fi

    echo -e "${COLOR_GREEN}✓${COLOR_RESET} $message"
}

# Assert string contains
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String does not contain expected value}"

    if [[ ! "$haystack" =~ $needle ]]; then
        fail_test "$message (expected to find: '$needle')"
    fi

    echo -e "${COLOR_GREEN}✓${COLOR_RESET} $message"
}

# Assert string does not contain
assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String contains unexpected value}"

    if [[ "$haystack" =~ $needle ]]; then
        fail_test "$message (should not find: '$needle')"
    fi

    echo -e "${COLOR_GREEN}✓${COLOR_RESET} $message"
}

# Assert PR exists
assert_pr_exists() {
    local pr_number="$1"

    if ! gh pr view "$pr_number" &>/dev/null; then
        fail_test "PR #$pr_number does not exist"
    fi

    echo -e "${COLOR_GREEN}✓${COLOR_RESET} PR #$pr_number exists"
}

# Assert issue exists
assert_issue_exists() {
    local issue_number="$1"

    if ! gh issue view "$issue_number" &>/dev/null; then
        fail_test "Issue #$issue_number does not exist"
    fi

    echo -e "${COLOR_GREEN}✓${COLOR_RESET} Issue #$issue_number exists"
}

# Assert issue has label
assert_issue_has_label() {
    local issue_number="$1"
    local label="$2"

    local labels
    labels=$(gh issue view "$issue_number" --json labels --jq '.labels[].name')

    if ! echo "$labels" | grep -q "^$label$"; then
        fail_test "Issue #$issue_number does not have label: $label"
    fi

    echo -e "${COLOR_GREEN}✓${COLOR_RESET} Issue #$issue_number has label: $label"
}

# Assert JSON path exists
assert_json_path_exists() {
    local json="$1"
    local path="$2"

    if ! echo "$json" | jq -e "$path" &>/dev/null; then
        fail_test "JSON path does not exist: $path"
    fi

    echo -e "${COLOR_GREEN}✓${COLOR_RESET} JSON path exists: $path"
}

# Assert JSON path equals value
assert_json_path_equals() {
    local json="$1"
    local path="$2"
    local expected="$3"

    local actual
    actual=$(echo "$json" | jq -r "$path")

    if [[ "$actual" != "$expected" ]]; then
        fail_test "JSON path $path value mismatch (expected: '$expected', got: '$actual')"
    fi

    echo -e "${COLOR_GREEN}✓${COLOR_RESET} JSON path $path = $expected"
}

# ============================================================================
# GitHub API Functions
# ============================================================================

# Create a test PR
create_test_pr() {
    local branch="$1"
    local base="${2:-main}"
    local title="${3:-Test PR}"
    local body="${4:-This is a test PR}"

    echo "Creating PR from $branch to $base..."

    local pr_url
    pr_url=$(gh pr create --base "$base" --head "$branch" --title "$title" --body "$body")

    local pr_number
    # Use sed instead of grep -oP for portability (BSD/macOS compatible)
    pr_number=$(echo "$pr_url" | sed -n 's/.*\/\([0-9][0-9]*\)$//p')

    register_cleanup "pr" "$pr_number"

    echo "$pr_number"
}

# Create a test issue
create_test_issue() {
    local title="$1"
    local body="${2:-This is a test issue}"

    echo "Creating issue: $title"

    local issue_url
    issue_url=$(gh issue create --title "$title" --body "$body")

    local issue_number
    # Use sed instead of grep -oP for portability (BSD/macOS compatible)
    issue_number=$(echo "$issue_url" | sed -n 's/.*\/\([0-9][0-9]*\)$//p')

    register_cleanup "issue" "$issue_number"

    echo "$issue_number"
}

# Get PR review
get_pr_review() {
    local pr_number="$1"

    gh api "repos/:owner/:repo/pulls/$pr_number/reviews" --jq '.[0].body // ""'
}

# Get latest issue comment
get_latest_comment() {
    local issue_number="$1"

    gh api "repos/:owner/:repo/issues/$issue_number/comments" --jq '.[-1] // {}'
}

# Check if branch is protected
is_branch_protected() {
    local branch="${1:-main}"

    if gh api "repos/:owner/:repo/branches/$branch/protection" &>/dev/null; then
        echo "true"
    else
        echo "false"
    fi
}

# ============================================================================
# Workflow Functions
# ============================================================================

# Wait for workflow to start
wait_for_workflow_start() {
    local workflow_name="$1"
    local timeout="${2:-$WORKFLOW_START_TIMEOUT}"

    echo "Waiting for workflow '$workflow_name' to start (timeout: ${timeout}s)..."

    local start_time
    start_time=$(date +%s)

    while true; do
        local elapsed=$(($(date +%s) - start_time))
        if [[ $elapsed -ge $timeout ]]; then
            fail_test "Workflow did not start within ${timeout}s"
        fi

        # Get latest workflow run
        local run_id
        run_id=$(gh run list --workflow "$workflow_name" --limit 1 --json databaseId --jq '.[0].databaseId // ""')

        if [[ -n "$run_id" ]]; then
            echo -e "${COLOR_GREEN}✓${COLOR_RESET} Workflow started (run ID: $run_id)"
            echo "$run_id"
            return 0
        fi

        sleep 2
    done
}

# Wait for workflow completion
wait_for_workflow_completion() {
    local run_id="$1"
    local timeout="${2:-$WORKFLOW_COMPLETION_TIMEOUT}"

    echo "Waiting for workflow run $run_id to complete (timeout: ${timeout}s)..."

    local start_time
    start_time=$(date +%s)

    while true; do
        local elapsed=$(($(date +%s) - start_time))
        if [[ $elapsed -ge $timeout ]]; then
            fail_test "Workflow did not complete within ${timeout}s"
        fi

        local status
        status=$(gh run view "$run_id" --json status --jq '.status')

        case "$status" in
            completed)
                local conclusion
                conclusion=$(gh run view "$run_id" --json conclusion --jq '.conclusion')
                echo -e "${COLOR_GREEN}✓${COLOR_RESET} Workflow completed: $conclusion"
                echo "$conclusion"
                return 0
                ;;
            in_progress|queued)
                echo -n "."
                sleep 5
                ;;
            *)
                fail_test "Unexpected workflow status: $status"
                ;;
        esac
    done
}

# Wait for specific workflow step
wait_for_step() {
    local run_id="$1"
    local step_name="$2"
    local timeout="${3:-$STEP_TIMEOUT}"

    echo "Waiting for step '$step_name' (timeout: ${timeout}s)..."

    local start_time
    start_time=$(date +%s)

    while true; do
        local elapsed=$(($(date +%s) - start_time))
        if [[ $elapsed -ge $timeout ]]; then
            fail_test "Step '$step_name' did not appear within ${timeout}s"
        fi

        local step_status
        step_status=$(gh run view "$run_id" --json jobs --jq ".jobs[].steps[] | select(.name == \"$step_name\") | .status" | head -1)

        if [[ -n "$step_status" ]]; then
            echo -e "${COLOR_GREEN}✓${COLOR_RESET} Step found: $step_name ($step_status)"
            return 0
        fi

        sleep 2
    done
}

# Get workflow logs
get_workflow_logs() {
    local run_id="$1"

    gh run view "$run_id" --log
}

# Assert workflow status
assert_workflow_status() {
    local run_id="$1"
    local expected_status="$2"

    local actual_status
    actual_status=$(gh run view "$run_id" --json conclusion --jq '.conclusion')

    assert_equals "$actual_status" "$expected_status" "Workflow status"
}

# ============================================================================
# Performance Tracking
# ============================================================================

# Start performance timer
start_timer() {
    date +%s
}

# End performance timer and return duration
end_timer() {
    local start_time="$1"
    local end_time
    end_time=$(date +%s)
    echo $((end_time - start_time))
}

# Log performance metric
log_performance() {
    local metric_name="$1"
    local value="$2"
    local unit="${3:-ms}"

    echo -e "${COLOR_BLUE}[PERF]${COLOR_RESET} $metric_name: $value$unit"
}

# ============================================================================
# Test Results
# ============================================================================

# Record test result
record_test_result() {
    local test_name="$1"
    local status="$2"  # PASS or FAIL
    local duration="$3"

    TEST_RESULTS+=("$test_name|$status|$duration")
}

# Fail current test
fail_test() {
    local message="$1"

    echo -e "${COLOR_RED}✗ TEST FAILED: $message${COLOR_RESET}"

    # Cleanup
    cleanup_test_environment

    exit 1
}

# Print test summary
print_test_summary() {
    local total=0
    local passed=0
    local failed=0
    local total_time=0

    echo ""
    echo "============================================================================"
    echo "TEST SUMMARY"
    echo "============================================================================"

    for result in "${TEST_RESULTS[@]}"; do
        IFS='|' read -r name status duration <<< "$result"
        total=$((total + 1))
        total_time=$((total_time + duration))

        if [[ "$status" == "PASS" ]]; then
            passed=$((passed + 1))
            echo -e "${COLOR_GREEN}✓${COLOR_RESET} $name (${duration}s)"
        else
            failed=$((failed + 1))
            echo -e "${COLOR_RED}✗${COLOR_RESET} $name (${duration}s)"
        fi
    done

    echo "----------------------------------------------------------------------------"
    echo "Total: $total | Passed: $passed | Failed: $failed | Time: ${total_time}s"

    if [[ $failed -eq 0 ]]; then
        echo -e "${COLOR_GREEN}ALL TESTS PASSED${COLOR_RESET}"
        return 0
    else
        local pass_rate=$((passed * 100 / total))
        echo -e "${COLOR_YELLOW}PASS RATE: ${pass_rate}%${COLOR_RESET}"

        if [[ $pass_rate -ge 60 ]]; then
            echo -e "${COLOR_YELLOW}ACCEPTABLE (≥60%)${COLOR_RESET}"
            return 0
        else
            echo -e "${COLOR_RED}BELOW THRESHOLD (<60%)${COLOR_RESET}"
            return 1
        fi
    fi
}

# ============================================================================
# Utilities
# ============================================================================

# Create test branch with sample code
create_test_branch() {
    local branch_name="$1"
    local base="${2:-main}"

    echo "Creating test branch: $branch_name"

    git fetch origin "$base"
    git checkout -b "$branch_name" "origin/$base"

    register_cleanup "branch" "$branch_name"
}

# Add sample file to branch
add_test_file() {
    local file_path="$1"
    local content="$2"

    echo "Adding test file: $file_path"

    mkdir -p "$(dirname "$file_path")"
    echo "$content" > "$file_path"
    git add "$file_path"
    git commit -m "Add test file: $file_path"
    git push -u origin HEAD
}

# Simulate API failure
mock_api_failure() {
    export AI_API_URL="http://localhost:9999/mock-failure"
    echo "Mocked AI API to fail"
}

# Simulate rate limit
mock_api_rate_limit() {
    export AI_API_RATE_LIMITED="true"
    echo "Mocked AI API rate limit"
}

# ============================================================================
# Export functions
# ============================================================================

export -f init_test_environment
export -f cleanup_test_environment
export -f register_cleanup
export -f assert_env_var
export -f assert_file_exists
export -f assert_dir_exists
export -f assert_command_success
export -f assert_equals
export -f assert_contains
export -f assert_not_contains
export -f assert_pr_exists
export -f assert_issue_exists
export -f assert_issue_has_label
export -f assert_json_path_exists
export -f assert_json_path_equals
export -f create_test_pr
export -f create_test_issue
export -f get_pr_review
export -f get_latest_comment
export -f is_branch_protected
export -f wait_for_workflow_start
export -f wait_for_workflow_completion
export -f wait_for_step
export -f get_workflow_logs
export -f assert_workflow_status
export -f start_timer
export -f end_timer
export -f log_performance
export -f record_test_result
export -f fail_test
export -f print_test_summary
export -f create_test_branch
export -f add_test_file
export -f mock_api_failure
export -f mock_api_rate_limit
