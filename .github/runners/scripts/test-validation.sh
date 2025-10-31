#!/bin/bash
#
# Comprehensive test suite for validation.sh library
# Tests all validation functions with valid inputs, invalid inputs,
# injection attempts, and edge cases
#

set -euo pipefail

# Source the validation library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/validation.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test helper function
run_test() {
    local func="$1"
    local input="$2"
    local expected="$3"
    local description="$4"

    TESTS_RUN=$((TESTS_RUN + 1))

    if $func "$input" 2>/dev/null; then
        actual=0
    else
        actual=1
    fi

    if [[ "$actual" -eq "$expected" ]]; then
        echo -e "${GREEN}✓${NC} PASS: $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} FAIL: $description (expected: $expected, got: $actual)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Test with additional parameters
run_test_with_params() {
    local func="$1"
    local input="$2"
    local param="$3"
    local expected="$4"
    local description="$5"

    TESTS_RUN=$((TESTS_RUN + 1))

    if $func "$input" "$param" 2>/dev/null; then
        actual=0
    else
        actual=1
    fi

    if [[ "$actual" -eq "$expected" ]]; then
        echo -e "${GREEN}✓${NC} PASS: $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} FAIL: $description (expected: $expected, got: $actual)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# ==============================================================================
# TEST: validate_issue_number
# ==============================================================================
echo -e "\n${YELLOW}Testing validate_issue_number...${NC}"

# Valid inputs (should pass)
run_test validate_issue_number "1" 0 "Valid single digit issue"
run_test validate_issue_number "123" 0 "Valid multi-digit issue"
run_test validate_issue_number "999999" 0 "Valid max range issue"

# Invalid inputs (should fail)
run_test validate_issue_number "" 1 "Empty input"
run_test validate_issue_number "0" 1 "Zero issue number"
run_test validate_issue_number "-1" 1 "Negative number"
run_test validate_issue_number "1.5" 1 "Decimal number"
run_test validate_issue_number "abc" 1 "Non-numeric input"
run_test validate_issue_number "123abc" 1 "Mixed alphanumeric"
run_test validate_issue_number "1000000" 1 "Out of range (too large)"
run_test validate_issue_number "01234" 1 "Leading zeros"

# Injection attempts (should fail)
run_test validate_issue_number "1; rm -rf /" 1 "Command injection attempt"
run_test validate_issue_number "1\$(whoami)" 1 "Command substitution attempt"
run_test validate_issue_number "1&&ls" 1 "Command chaining attempt"
run_test validate_issue_number "1|cat /etc/passwd" 1 "Pipe injection attempt"

# ==============================================================================
# TEST: validate_file_path
# ==============================================================================
echo -e "\n${YELLOW}Testing validate_file_path...${NC}"

# Valid inputs (should pass)
run_test validate_file_path "file.txt" 0 "Simple filename"
run_test validate_file_path "path/to/file.txt" 0 "Relative path"
run_test validate_file_path "path-with_underscore/file.txt" 0 "Path with underscore and dash"
run_test validate_file_path ".github/workflows/test.yml" 0 "Hidden directory path"
run_test_with_params validate_file_path "/absolute/path" "true" 0 "Absolute path (allowed)"

# Invalid inputs (should fail)
run_test validate_file_path "" 1 "Empty path"
run_test validate_file_path "../etc/passwd" 1 "Path traversal with .."
run_test validate_file_path "path/../file" 1 "Path traversal in middle"
run_test validate_file_path "/absolute/path" 1 "Absolute path (not allowed by default)"
run_test validate_file_path "C:/Windows/System32" 1 "Windows absolute path"
run_test validate_file_path "file\$(whoami).txt" 1 "Command substitution in filename"
run_test validate_file_path "file;rm -rf /" 1 "Command injection in filename"
run_test validate_file_path "file|cat" 1 "Pipe in filename"
run_test validate_file_path "file&ls" 1 "Background command in filename"
run_test validate_file_path "file//with//double//slashes" 1 "Multiple consecutive slashes"
run_test validate_file_path "file\x00.txt" 1 "Null byte in filename"
run_test validate_file_path "file*.txt" 1 "Wildcard in filename"
run_test validate_file_path "file?.txt" 1 "Question mark wildcard"
run_test validate_file_path "file[a-z].txt" 1 "Bracket glob pattern"

# ==============================================================================
# TEST: validate_github_token
# ==============================================================================
echo -e "\n${YELLOW}Testing validate_github_token...${NC}"

# Valid inputs (should pass)
run_test validate_github_token "ghp_abcd1234567890ABCD1234567890ABCD1234" 0 "Valid personal access token"
run_test validate_github_token "gho_abcd1234567890ABCD1234567890ABCD1234" 0 "Valid OAuth token"
run_test validate_github_token "ghs_abcd1234567890ABCD1234567890ABCD1234" 0 "Valid server token"
run_test validate_github_token "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" 0 "Valid fine-grained PAT"

# Invalid inputs (should fail)
run_test validate_github_token "" 1 "Empty token"
run_test validate_github_token "invalid_token" 1 "Invalid format"
run_test validate_github_token "ghp_tooshort" 1 "Token too short"
run_test validate_github_token "ghp_waytoolongabcd1234567890ABCD1234567890ABCD1234567890" 1 "Token too long"
run_test validate_github_token "gh_abcd1234567890ABCD1234567890ABCD1234" 1 "Invalid prefix"
run_test validate_github_token "ghp_abcd!@#$%^&*()1234567890ABCD123456" 1 "Special characters in token"
run_test validate_github_token "\$(echo ghp_abcd1234567890ABCD1234567890ABCD1234)" 1 "Command substitution"
run_test validate_github_token "ghp_abcd1234567890ABCD1234567890ABCD123 " 1 "Token with space"

# ==============================================================================
# TEST: validate_url
# ==============================================================================
echo -e "\n${YELLOW}Testing validate_url...${NC}"

# Valid inputs (should pass)
run_test validate_url "https://github.com/user/repo" 0 "Valid GitHub URL"
run_test validate_url "https://api.github.com/repos" 0 "Valid GitHub API URL"
run_test_with_params validate_url "https://example.com/path" "example.com" 0 "Valid custom domain"

# Invalid inputs (should fail)
run_test validate_url "" 1 "Empty URL"
run_test validate_url "http://github.com" 1 "HTTP instead of HTTPS"
run_test validate_url "ftp://github.com" 1 "FTP protocol"
run_test validate_url "https://evil.com/redirect" 1 "Non-whitelisted domain"
run_test validate_url "https://localhost/admin" 1 "Localhost URL (SSRF)"
run_test validate_url "https://127.0.0.1/admin" 1 "Loopback IP (SSRF)"
run_test validate_url "https://192.168.1.1/router" 1 "Private IP (SSRF)"
run_test validate_url "https://10.0.0.1/internal" 1 "Private IP range (SSRF)"
run_test validate_url "https://172.16.0.1/internal" 1 "Private IP range 2 (SSRF)"
run_test validate_url "https://github.com%2e%2e/admin" 1 "URL encoded traversal"
run_test validate_url "https://github.com%00.evil.com" 1 "Null byte in domain"
run_test validate_url "javascript:alert(1)" 1 "JavaScript protocol"
run_test validate_url "https://github.com@evil.com" 1 "Credentials in URL"

# ==============================================================================
# TEST: validate_branch_name
# ==============================================================================
echo -e "\n${YELLOW}Testing validate_branch_name...${NC}"

# Valid inputs (should pass)
run_test validate_branch_name "main" 0 "Simple branch name"
run_test validate_branch_name "feature/new-feature" 0 "Branch with slash"
run_test validate_branch_name "bugfix-123" 0 "Branch with dash"
run_test validate_branch_name "release_v1.2.3" 0 "Branch with underscore and dots"
run_test validate_branch_name "user/feature/JIRA-1234" 0 "Complex branch name"

# Invalid inputs (should fail)
run_test validate_branch_name "" 1 "Empty branch name"
run_test validate_branch_name ".hidden" 1 "Starting with dot"
run_test validate_branch_name "-feature" 1 "Starting with dash"
run_test validate_branch_name "feature..bugfix" 1 "Contains double dots"
run_test validate_branch_name "feature.lock" 1 "Ends with .lock"
run_test validate_branch_name "feature@{upstream}" 1 "Contains @{"
run_test validate_branch_name "feature//double" 1 "Double slashes"
run_test validate_branch_name "feature branch" 1 "Contains space"
run_test validate_branch_name "feature;rm -rf /" 1 "Command injection"
run_test validate_branch_name "feature\$(whoami)" 1 "Command substitution"
run_test validate_branch_name "feature|pipe" 1 "Pipe character"
run_test validate_branch_name "a$(printf 'x%.0s' {1..256})" 1 "Branch name too long"

# ==============================================================================
# TEST: validate_commit_hash
# ==============================================================================
echo -e "\n${YELLOW}Testing validate_commit_hash...${NC}"

# Valid inputs (should pass)
run_test validate_commit_hash "abc1234" 0 "Short hash (7 chars)"
run_test validate_commit_hash "1234567890abcdef" 0 "Medium hash (16 chars)"
run_test validate_commit_hash "1234567890abcdef1234567890abcdef12345678" 0 "Full hash (40 chars)"
run_test validate_commit_hash "ABCDEF1234567890" 0 "Uppercase hex"

# Invalid inputs (should fail)
run_test validate_commit_hash "" 1 "Empty hash"
run_test validate_commit_hash "abc123" 1 "Too short (6 chars)"
run_test validate_commit_hash "1234567890abcdef1234567890abcdef123456789" 1 "Too long (41 chars)"
run_test validate_commit_hash "ghijklm" 1 "Invalid hex characters"
run_test validate_commit_hash "abc123g" 1 "Non-hex character"
run_test validate_commit_hash "abc-123" 1 "Contains dash"
run_test validate_commit_hash "abc 123" 1 "Contains space"
run_test validate_commit_hash "abc\$(ls)" 1 "Command substitution"
run_test validate_commit_hash "abc;pwd" 1 "Command injection"

# ==============================================================================
# TEST: validate_label
# ==============================================================================
echo -e "\n${YELLOW}Testing validate_label...${NC}"

# Valid inputs (should pass)
run_test validate_label "bug" 0 "Simple label"
run_test validate_label "priority:high" 0 "Label with colon"
run_test validate_label "type/feature" 0 "Label with slash"
run_test validate_label "work-in-progress" 0 "Label with dashes"
run_test validate_label "v1.2.3" 0 "Version label"
run_test validate_label "needs review" 0 "Label with space"

# Invalid inputs (should fail)
run_test validate_label "" 1 "Empty label"
run_test validate_label "a$(printf 'x%.0s' {1..101})" 1 "Label too long"
run_test validate_label "label;rm -rf /" 1 "Command injection"
run_test validate_label "label\$(whoami)" 1 "Command substitution"
run_test validate_label "label|pipe" 1 "Pipe character"
run_test validate_label "label&background" 1 "Background operator"
run_test validate_label "label>output" 1 "Redirect operator"
run_test validate_label "label*" 1 "Wildcard"
run_test validate_label "label[abc]" 1 "Bracket glob"

# ==============================================================================
# TEST: sanitize_input
# ==============================================================================
echo -e "\n${YELLOW}Testing sanitize_input...${NC}"

# Test sanitization
test_sanitize() {
    local input="$1"
    local expected="$2"
    local description="$3"

    TESTS_RUN=$((TESTS_RUN + 1))
    local result
    result=$(sanitize_input "$input" 2>/dev/null)

    if [[ "$result" == "$expected" ]]; then
        echo -e "${GREEN}✓${NC} PASS: $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} FAIL: $description (expected: '$expected', got: '$result')"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

test_sanitize "" "" "Empty input returns empty"
test_sanitize "safe_input-123" "safe_input-123" "Safe input unchanged"
test_sanitize "input;rm -rf /" "input rm -rf /" "Semicolon removed"
test_sanitize "input\$(whoami)" "input whoami" "Command substitution removed"
test_sanitize "input|pipe&background" "input pipe background" "Shell operators removed"
test_sanitize "input*?.txt" "input.txt" "Wildcards removed"
test_sanitize "path/../etc/passwd" "path/../etc/passwd" "Dots kept but not consecutive"
test_sanitize "inputx00null" "inputx00null" "Null byte removed"
test_sanitize "input!@#\$%^&*()" "input" "Special characters removed"

# ==============================================================================
# TEST: Additional validation functions
# ==============================================================================
echo -e "\n${YELLOW}Testing validate_env_var_name...${NC}"

run_test validate_env_var_name "GITHUB_TOKEN" 0 "Valid env var name"
run_test validate_env_var_name "MY_VAR_123" 0 "Valid with numbers"
run_test validate_env_var_name "_PRIVATE_VAR" 0 "Valid starting with underscore"
run_test validate_env_var_name "" 1 "Empty env var name"
run_test validate_env_var_name "lowercase" 1 "Lowercase not allowed"
run_test validate_env_var_name "123_VAR" 1 "Starting with number"
run_test validate_env_var_name "VAR-NAME" 1 "Contains dash"
run_test validate_env_var_name "VAR NAME" 1 "Contains space"

echo -e "\n${YELLOW}Testing validate_docker_image...${NC}"

run_test validate_docker_image "nginx" 0 "Simple image name"
run_test validate_docker_image "nginx:latest" 0 "Image with tag"
run_test validate_docker_image "docker.io/library/nginx" 0 "Full registry path"
run_test validate_docker_image "myregistry.com:5000/myimage:v1.0" 0 "Custom registry with port"
run_test validate_docker_image "nginx@sha256:abc123" 0 "Image with digest"
run_test validate_docker_image "" 1 "Empty image name"
run_test validate_docker_image "UPPERCASE" 1 "Uppercase not allowed"
run_test validate_docker_image "-nginx" 1 "Starting with dash"
run_test validate_docker_image "nginx;ls" 1 "Command injection"

echo -e "\n${YELLOW}Testing validate_workflow_name...${NC}"

run_test validate_workflow_name "CI/CD Pipeline" 0 "Workflow with space and slash"
run_test validate_workflow_name "build-and-test" 0 "Workflow with dashes"
run_test validate_workflow_name "release_v1.0" 0 "Workflow with underscore and dot"
run_test validate_workflow_name "" 1 "Empty workflow name"
run_test validate_workflow_name "workflow;injection" 1 "Command injection"
run_test validate_workflow_name "a$(printf 'x%.0s' {1..256})" 1 "Workflow name too long"

# ==============================================================================
# EDGE CASES AND STRESS TESTS
# ==============================================================================
echo -e "\n${YELLOW}Testing edge cases...${NC}"

# Very long inputs
LONG_STRING=$(printf 'a%.0s' {1..10000})
run_test validate_issue_number "$LONG_STRING" 1 "Very long string for issue number"
run_test validate_branch_name "$LONG_STRING" 1 "Very long string for branch name"

# Unicode and special characters
run_test validate_file_path "file🔥.txt" 1 "Unicode emoji in path"
run_test validate_label "label™" 1 "Unicode trademark symbol"
run_test validate_branch_name "branch→main" 1 "Unicode arrow"

# Null and special bytes
run_test validate_file_path $'file\nnewline.txt' 1 "Newline in filename"
run_test validate_url $'https://github.com\r\n\r\nGET /admin' 1 "CRLF injection"

# ==============================================================================
# SUMMARY
# ==============================================================================
echo -e "\n${YELLOW}========================================${NC}"
echo -e "${YELLOW}Test Summary${NC}"
echo -e "${YELLOW}========================================${NC}"
echo "Tests run: $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}Some tests failed!${NC}"
    exit 1
fi