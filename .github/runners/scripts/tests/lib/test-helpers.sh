#!/usr/bin/env bash
# Test Helper Functions for Integration Testing
# Provides utilities for mocking, assertions, and test orchestration

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Test tracking
declare -g TESTS_RUN=0
declare -g TESTS_PASSED=0
declare -g TESTS_FAILED=0
declare -A TEST_RESULTS

# Test configuration
readonly TEST_TIMEOUT="${TEST_TIMEOUT:-300}"
readonly CLEANUP_ON_SUCCESS="${CLEANUP_ON_SUCCESS:-true}"
readonly MOCK_SERVER_PORT="${MOCK_SERVER_PORT:-8888}"
readonly TEST_REPO="${TEST_REPO:-test-integration-repo}"
readonly TEST_ORG="${TEST_ORG:-test-org}"

# Logging functions
log_test() {
    echo -e "${BLUE}[TEST]${NC} $*"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $*"
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

# Test execution wrapper
run_test() {
    local test_name="$1"
    local test_func="$2"

    TESTS_RUN=$((TESTS_RUN + 1))
    log_test "Running: $test_name"

    local start_time
    start_time=$(date +%s)

    if $test_func 2>&1; then
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))

        TESTS_PASSED=$((TESTS_PASSED + 1))
        TEST_RESULTS["$test_name"]="PASS"
        log_pass "$test_name (${duration}s)"
        return 0
    else
        local exit_code=$?
        TESTS_FAILED=$((TESTS_FAILED + 1))
        TEST_RESULTS["$test_name"]="FAIL"
        log_fail "$test_name (exit code: $exit_code)"
        return 1
    fi
}

# Assertion functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Assertion failed}"

    if [[ "$actual" == "$expected" ]]; then
        return 0
    else
        log_fail "$message"
        log_fail "  Expected: '$expected'"
        log_fail "  Actual:   '$actual'"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String not found}"

    if echo "$haystack" | grep -q "$needle"; then
        return 0
    else
        log_fail "$message"
        log_fail "  Looking for: '$needle'"
        log_fail "  In: '${haystack:0:100}...'"
        return 1
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should not be found}"

    if echo "$haystack" | grep -q "$needle"; then
        log_fail "$message"
        log_fail "  Found unwanted: '$needle'"
        return 1
    else
        return 0
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-File does not exist}"

    if [[ -f "$file" ]]; then
        return 0
    else
        log_fail "$message: $file"
        return 1
    fi
}

assert_file_not_exists() {
    local file="$1"
    local message="${2:-File should not exist}"

    if [[ ! -f "$file" ]]; then
        return 0
    else
        log_fail "$message: $file"
        return 1
    fi
}

assert_json_valid() {
    local json="$1"
    local message="${2:-Invalid JSON}"

    if echo "$json" | jq empty 2>/dev/null; then
        return 0
    else
        log_fail "$message"
        log_fail "  JSON: '${json:0:200}...'"
        return 1
    fi
}

assert_json_has_key() {
    local json="$1"
    local key="$2"
    local message="${3:-JSON missing key}"

    local value
    value=$(echo "$json" | jq -r ".$key" 2>/dev/null)

    if [[ "$value" != "null" ]] && [[ -n "$value" ]]; then
        return 0
    else
        log_fail "$message: $key"
        return 1
    fi
}

assert_exit_code() {
    local expected="$1"
    local command="$2"
    local message="${3:-Unexpected exit code}"

    set +e
    # WARNING: Using eval can be risky with untrusted input
    # Only use this function with hardcoded test commands, never with user input
    # Alternative: Consider using a function reference or command array if possible
    eval "$command" >/dev/null 2>&1
    local actual=$?
    set -e

    if [[ $actual -eq $expected ]]; then
        return 0
    else
        log_fail "$message"
        log_fail "  Expected: $expected"
        log_fail "  Actual:   $actual"
        return 1
    fi
}

assert_greater_than() {
    local actual="$1"
    local threshold="$2"
    local message="${3:-Value not greater than threshold}"

    if [[ $actual -gt $threshold ]]; then
        return 0
    else
        log_fail "$message"
        log_fail "  Value:     $actual"
        log_fail "  Threshold: $threshold"
        return 1
    fi
}

# Mock GitHub API
setup_mock_github_api() {
    local mock_dir="${1:-/tmp/mock-github-api}"

    mkdir -p "$mock_dir"
    export MOCK_API_DIR="$mock_dir"
    export GITHUB_API_URL="http://localhost:${MOCK_SERVER_PORT}"

    # Start simple HTTP server for mocking
    cat > "$mock_dir/server.py" << 'EOF'
#!/usr/bin/env python3
import http.server
import socketserver
import json
import os
import re
from urllib.parse import urlparse, parse_qs

PORT = int(os.environ.get('MOCK_SERVER_PORT', 8888))
MOCK_DIR = os.environ.get('MOCK_API_DIR', '/tmp/mock-github-api')

class MockGitHubHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        path = urlparse(self.path).path

        # Mock PR metadata
        if re.match(r'/repos/.+/.+/pulls/\d+$', path):
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = {
                "number": 123,
                "state": "open",
                "title": "Test PR",
                "body": "Test PR description",
                "additions": 100,
                "deletions": 50,
                "changedFiles": 5
            }
            self.wfile.write(json.dumps(response).encode())
            return

        # Mock PR files
        if re.match(r'/repos/.+/.+/pulls/\d+/files$', path):
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = [
                {"filename": "test.js", "status": "modified"},
                {"filename": "test2.py", "status": "added"}
            ]
            self.wfile.write(json.dumps(response).encode())
            return

        # Mock issue
        if re.match(r'/repos/.+/.+/issues/\d+$', path):
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = {
                "number": 456,
                "state": "open",
                "title": "Test Issue",
                "body": "Test issue description",
                "labels": [{"name": "bug"}]
            }
            self.wfile.write(json.dumps(response).encode())
            return

        self.send_error(404)

    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length)

        # Mock PR review
        if re.match(r'/repos/.+/.+/pulls/\d+/reviews$', self.path):
            self.send_response(201)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = {"id": 789, "state": "COMMENTED"}
            self.wfile.write(json.dumps(response).encode())
            return

        # Mock issue comment
        if re.match(r'/repos/.+/.+/issues/\d+/comments$', self.path):
            self.send_response(201)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = {"id": 999}
            self.wfile.write(json.dumps(response).encode())
            return

        self.send_error(404)

with socketserver.TCPServer(("", PORT), MockGitHubHandler) as httpd:
    print(f"Mock GitHub API server running on port {PORT}")
    httpd.serve_forever()
EOF

    chmod +x "$mock_dir/server.py"

    # Start mock server in background
    python3 "$mock_dir/server.py" > "$mock_dir/server.log" 2>&1 &
    local pid=$!
    echo "$pid" > "$mock_dir/server.pid"

    # Wait for server to start
    sleep 2

    log_info "Mock GitHub API started (PID: $pid, Port: $MOCK_SERVER_PORT)"
}

teardown_mock_github_api() {
    local mock_dir="${1:-/tmp/mock-github-api}"

    if [[ -f "$mock_dir/server.pid" ]]; then
        local pid
        pid=$(cat "$mock_dir/server.pid")
        kill "$pid" 2>/dev/null || true
        rm -f "$mock_dir/server.pid"
        log_info "Mock GitHub API stopped"
    fi

    if [[ "$CLEANUP_ON_SUCCESS" == "true" ]]; then
        rm -rf "$mock_dir"
    fi
}

# Mock AI API
setup_mock_ai_api() {
    local mock_dir="${1:-/tmp/mock-ai-api}"

    mkdir -p "$mock_dir"
    export MOCK_AI_DIR="$mock_dir"

    # Create mock AI response
    cat > "$mock_dir/response.json" << 'EOF'
{
  "id": "mock-response-123",
  "model": "claude-3-opus",
  "content": [{
    "type": "text",
    "text": "This is a mock AI review response.\n\n**Overall Assessment:** The code looks good.\n\n**Recommendation:** APPROVE"
  }],
  "usage": {
    "input_tokens": 100,
    "output_tokens": 50
  }
}
EOF

    # Create mock API endpoint
    export AI_API_ENDPOINT="file://$mock_dir/response.json"
    log_info "Mock AI API configured"
}

teardown_mock_ai_api() {
    local mock_dir="${1:-/tmp/mock-ai-api}"

    if [[ "$CLEANUP_ON_SUCCESS" == "true" ]]; then
        rm -rf "$mock_dir"
    fi
}

# Test data helpers
create_test_pr_data() {
    local pr_number="${1:-123}"
    local output_file="${2:-/tmp/test-pr-$pr_number.json}"

    cat > "$output_file" << EOF
{
  "number": $pr_number,
  "state": "open",
  "title": "Test PR $pr_number",
  "body": "This is a test PR for integration testing",
  "additions": 100,
  "deletions": 50,
  "changedFiles": 5,
  "head": {
    "ref": "feature-branch",
    "sha": "abc123def456"
  },
  "base": {
    "ref": "main",
    "sha": "def456abc123"
  }
}
EOF

    echo "$output_file"
}

create_test_issue_data() {
    local issue_number="${1:-456}"
    local output_file="${2:-/tmp/test-issue-$issue_number.json}"

    cat > "$output_file" << EOF
{
  "number": $issue_number,
  "state": "open",
  "title": "Test Issue $issue_number",
  "body": "This is a test issue for integration testing",
  "labels": [
    {"name": "bug"},
    {"name": "needs-triage"}
  ],
  "comments": 3
}
EOF

    echo "$output_file"
}

# Workflow helpers
wait_for_workflow() {
    local workflow_name="$1"
    local timeout="${2:-120}"
    local repo="${3:-$GITHUB_REPOSITORY}"

    log_info "Waiting for workflow: $workflow_name"

    local elapsed=0
    while [[ $elapsed -lt $timeout ]]; do
        local status
        status=$(gh run list --workflow="$workflow_name" --repo="$repo" --limit=1 --json status --jq '.[0].status' 2>/dev/null || echo "unknown")

        if [[ "$status" == "completed" ]]; then
            log_info "Workflow completed"
            return 0
        fi

        sleep 5
        elapsed=$((elapsed + 5))
    done

    log_fail "Workflow timeout after ${timeout}s"
    return 1
}

get_workflow_conclusion() {
    local workflow_name="$1"
    local repo="${2:-$GITHUB_REPOSITORY}"

    gh run list --workflow="$workflow_name" --repo="$repo" --limit=1 --json conclusion --jq '.[0].conclusion'
}

trigger_workflow() {
    local workflow_file="$1"
    shift
    local args=("$@")
    local repo="${GITHUB_REPOSITORY:-test/repo}"

    log_info "Triggering workflow: $workflow_file"

    # Use gh CLI to trigger workflow
    gh workflow run "$workflow_file" --repo="$repo" "${args[@]}"
}

# PR helpers
create_test_pr() {
    local title="${1:-Test PR}"
    local body="${2:-Test PR body}"
    local base="${3:-main}"
    local head="${4:-test-branch}"
    local repo="${5:-$GITHUB_REPOSITORY}"

    log_info "Creating test PR: $title"

    # Create PR using gh CLI
    local pr_number
    pr_number=$(gh pr create --repo="$repo" --title="$title" --body="$body" --base="$base" --head="$head" --json number --jq '.number')

    echo "$pr_number"
}

get_pr_review() {
    local pr_number="$1"
    local repo="${2:-$GITHUB_REPOSITORY}"

    gh api "repos/$repo/pulls/$pr_number/reviews" --jq '.[-1]'
}

assert_pr_has_review() {
    local pr_number="$1"
    local message="${2:-PR should have review}"

    local reviews
    reviews=$(gh api "repos/$GITHUB_REPOSITORY/pulls/$pr_number/reviews" --jq 'length')

    if [[ $reviews -gt 0 ]]; then
        return 0
    else
        log_fail "$message: PR #$pr_number"
        return 1
    fi
}

assert_pr_has_comment() {
    local pr_number="$1"
    local comment_text="$2"
    local message="${3:-PR should have comment}"

    local comments
    comments=$(gh pr view "$pr_number" --json comments --jq '.comments[].body')

    if echo "$comments" | grep -q "$comment_text"; then
        return 0
    else
        log_fail "$message: '$comment_text'"
        return 1
    fi
}

# Issue helpers
create_test_issue() {
    local title="${1:-Test Issue}"
    local body="${2:-Test issue body}"
    local repo="${3:-$GITHUB_REPOSITORY}"

    log_info "Creating test issue: $title"

    local issue_number
    issue_number=$(gh issue create --repo="$repo" --title="$title" --body="$body" --json number --jq '.number')

    echo "$issue_number"
}

assert_issue_has_comment() {
    local issue_number="$1"
    local message="${2:-Issue should have comment}"

    local comments
    comments=$(gh issue view "$issue_number" --json comments --jq '.comments | length')

    if [[ $comments -gt 0 ]]; then
        return 0
    else
        log_fail "$message: Issue #$issue_number"
        return 1
    fi
}

get_latest_comment() {
    local issue_number="$1"

    gh issue view "$issue_number" --json comments --jq '.comments[-1].body'
}

# Cleanup helpers
cleanup_test_data() {
    local test_id="${1:-test}"

    log_info "Cleaning up test data: $test_id"

    # Remove temp files
    rm -rf "/tmp/${test_id}-"* 2>/dev/null || true

    # Close test PRs
    if command -v gh &> /dev/null; then
        gh pr list --label "test-integration" --json number --jq '.[].number' | while read -r pr; do
            gh pr close "$pr" --delete-branch 2>/dev/null || true
        done
    fi
}

# Test summary
print_test_summary() {
    echo ""
    echo "========================================="
    echo "Test Summary"
    echo "========================================="
    echo "Total:  $TESTS_RUN"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo ""
        echo "Failed tests:"
        for test_name in "${!TEST_RESULTS[@]}"; do
            if [[ "${TEST_RESULTS[$test_name]}" == "FAIL" ]]; then
                echo -e "  ${RED}✗${NC} $test_name"
            fi
        done
    fi

    echo "========================================="

    local pass_rate=0
    if [[ $TESTS_RUN -gt 0 ]]; then
        pass_rate=$(( TESTS_PASSED * 100 / TESTS_RUN ))
    fi

    echo "Pass rate: ${pass_rate}%"

    if [[ $pass_rate -ge 60 ]]; then
        echo -e "${GREEN}✓ Acceptable pass rate (≥60%)${NC}"
        return 0
    else
        echo -e "${RED}✗ Pass rate below 60%${NC}"
        return 1
    fi
}


assert_not_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values should not be equal}"

    if [[ "$actual" != "$expected" ]]; then
        return 0
    else
        log_fail "$message"
        log_fail "  Expected to be different from: '$expected'"
        log_fail "  Actual value: '$actual'"
        return 1
    fi
}

# Export functions
export -f log_test log_pass log_fail log_warn log_info
export -f run_test
export -f assert_equals assert_contains assert_not_contains assert_not_equals
export -f assert_file_exists assert_file_not_exists
export -f assert_json_valid assert_json_has_key
export -f assert_exit_code assert_greater_than
export -f setup_mock_github_api teardown_mock_github_api
export -f setup_mock_ai_api teardown_mock_ai_api
export -f create_test_pr_data create_test_issue_data
export -f wait_for_workflow get_workflow_conclusion trigger_workflow
export -f create_test_pr get_pr_review assert_pr_has_review assert_pr_has_comment
export -f create_test_issue assert_issue_has_comment get_latest_comment
export -f cleanup_test_data print_test_summary
