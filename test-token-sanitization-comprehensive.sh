#!/usr/bin/env bash

################################################################################
# Comprehensive Token Sanitization Test Suite
# Tests for ALL GitHub token patterns
#
# This script verifies that ALL GitHub token types are properly sanitized:
# - ghp_ : GitHub personal access tokens (classic)
# - ghs_ : GitHub server-to-server tokens
# - github_pat_ : GitHub personal access tokens (fine-grained)
# - gho_ : GitHub OAuth tokens
# - ghr_ : GitHub refresh tokens
# - ghu_to_s_ : GitHub user-to-server tokens
################################################################################

set -e
set -u
set -o pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Temporary test directory
TEST_DIR="/tmp/token-sanitization-test-$$"
TEST_LOG="${TEST_DIR}/test.log"

################################################################################
# Test Framework Functions
################################################################################

setup_test_env() {
    echo -e "${BLUE}Setting up test environment...${NC}"
    mkdir -p "$TEST_DIR"
    cp scripts/setup-runner.sh "$TEST_DIR/"
    cd "$TEST_DIR"
}

cleanup_test_env() {
    echo -e "${BLUE}Cleaning up test environment...${NC}"
    cd /
    rm -rf "$TEST_DIR"
}

assert_no_token() {
    local file="$1"
    local test_name="$2"
    local pattern="${3:-}"

    ((TESTS_TOTAL++))

    if [[ -z "$pattern" ]]; then
        # Default token patterns - ALL GitHub token types
        pattern='(ghp_|ghs_|github_pat_|gho_|ghr_|ghu_to_s_)[A-Za-z0-9_]+'
    fi

    if grep -qE "$pattern" "$file" 2>/dev/null; then
        echo -e "${RED}✗ FAILED:${NC} $test_name"
        echo "  Token pattern found in: $file"
        echo "  Matching lines:"
        grep -E "$pattern" "$file" | head -5 | sed 's/^/    /'
        ((TESTS_FAILED++))
        return 1
    else
        echo -e "${GREEN}✓ PASSED:${NC} $test_name"
        ((TESTS_PASSED++))
        return 0
    fi
}

assert_contains() {
    local text="$1"
    local pattern="$2"
    local test_name="$3"

    ((TESTS_TOTAL++))

    if echo "$text" | grep -qE "$pattern"; then
        echo -e "${GREEN}✓ PASSED:${NC} $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAILED:${NC} $test_name"
        echo "  Expected pattern not found: $pattern"
        echo "  In text: $(echo "$text" | head -1)"
        ((TESTS_FAILED++))
        return 1
    fi
}

################################################################################
# Unit Tests for ALL Token Types
################################################################################

test_all_token_patterns() {
    echo -e "\n${YELLOW}Testing ALL GitHub token pattern detection...${NC}"

    # Source the script to get access to functions
    source ./setup-runner.sh 2>/dev/null || true

    # Test each token type
    declare -A token_tests=(
        ["ghp_"]="ghp_1234567890abcdefghijklmnopqrstuvwxyz"
        ["ghs_"]="ghs_abcdefghijklmnop1234567890"
        ["github_pat_"]="github_pat_11ABCDEF2G3HIJKLMNOP4QRSTUV5WXYZ67890abcdefghijklmnop"
        ["gho_"]="gho_16C3B1A21E23D4F5G6H7I8J9K0LMNOPQRSTUVWX"
        ["ghr_"]="ghr_1B2C3D4E5F6A7B8C9D0E1F2G3H4I5J6K7L8M9N0"
        ["ghu_to_s_"]="ghu_to_s_16C3B1A21E23D4F5G6H7I8J9K0LMNOPQRSTUVWX"
    )

    local token_type
    for token_type in "${!token_tests[@]}"; do
        local test_token="${token_tests[$token_type]}"
        local result=$(sanitize_log "Token: $test_token")

        if [[ "$result" == *"[REDACTED]"* ]] && [[ "$result" != *"$token_type"* ]]; then
            echo -e "${GREEN}✓${NC} ${token_type} token sanitized correctly"
            ((TESTS_PASSED++))
        else
            echo -e "${RED}✗${NC} ${token_type} token NOT sanitized: $test_token"
            echo "  Result: $result"
            ((TESTS_FAILED++))
        fi
        ((TESTS_TOTAL++))
    done
}

test_verify_no_tokens_function() {
    echo -e "\n${YELLOW}Testing verify_no_tokens_in_logs function with ALL token types...${NC}"

    # Source the script to get access to functions
    source ./setup-runner.sh 2>/dev/null || true

    # Test each token type in log file
    declare -A token_tests=(
        ["GitHub PAT classic"]="ghp_1234567890abcdefghijklmnopqrstuvwxyz"
        ["GitHub server token"]="ghs_abcdefghijklmnop1234567890"
        ["GitHub PAT fine-grained"]="github_pat_11ABCDEF2G3HIJKLMNOP4QRSTUV5WXYZ67890"
        ["GitHub OAuth token"]="gho_16C3B1A21E23D4F5G6H7I8J9K0LMNOPQRSTUVWX"
        ["GitHub refresh token"]="ghr_1B2C3D4E5F6A7B8C9D0E1F2G3H4I5J6K7L8M9N0"
        ["GitHub user-to-server"]="ghu_to_s_16C3B1A21E23D4F5G6H7I8J9K0LMNOPQRSTUVWX"
    )

    local token_name
    for token_name in "${!token_tests[@]}"; do
        local test_token="${token_tests[$token_name]}"

        # Create test log with token
        echo "Test with token $test_token" > test_token.log
        LOG_FILE="test_token.log"

        if verify_no_tokens_in_logs 2>/dev/null; then
            echo -e "${RED}✗${NC} verify_no_tokens_in_logs didn't detect: $token_name"
            ((TESTS_FAILED++))
        else
            echo -e "${GREEN}✓${NC} verify_no_tokens_in_logs detected: $token_name"
            ((TESTS_PASSED++))
        fi
        ((TESTS_TOTAL++))

        rm -f test_token.log
    done
}

test_mixed_tokens_sanitization() {
    echo -e "\n${YELLOW}Testing sanitization of mixed token types...${NC}"

    # Source the script to get access to functions
    source ./setup-runner.sh 2>/dev/null || true

    # Test with multiple tokens in one message
    local mixed_message="Auth: ghp_abc123 OAuth: gho_def456 Refresh: ghr_xyz789 U2S: ghu_to_s_mnop012"
    local result=$(sanitize_log "$mixed_message")

    # Check that ALL tokens are redacted
    if [[ "$result" != *"ghp_"* ]] && \
       [[ "$result" != *"gho_"* ]] && \
       [[ "$result" != *"ghr_"* ]] && \
       [[ "$result" != *"ghu_to_s_"* ]] && \
       [[ "$result" == *"[REDACTED]"* ]]; then
        echo -e "${GREEN}✓ PASSED:${NC} Mixed tokens all sanitized"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAILED:${NC} Mixed tokens not fully sanitized"
        echo "  Original: $mixed_message"
        echo "  Result: $result"
        ((TESTS_FAILED++))
    fi
    ((TESTS_TOTAL++))
}

test_no_contains_token_function() {
    echo -e "\n${YELLOW}Verifying contains_token function was removed...${NC}"

    # Check that contains_token function doesn't exist
    if grep -q "contains_token()" ./setup-runner.sh; then
        echo -e "${RED}✗ FAILED:${NC} contains_token function still exists"
        ((TESTS_FAILED++))
    else
        echo -e "${GREEN}✓ PASSED:${NC} contains_token function removed"
        ((TESTS_PASSED++))
    fi
    ((TESTS_TOTAL++))
}

test_regex_consistency() {
    echo -e "\n${YELLOW}Testing regex consistency between functions...${NC}"

    # Extract regex patterns from both functions
    local sanitize_pattern=$(grep -A1 "sanitize_log()" ./setup-runner.sh | grep "ghp_" | sed -n "s/.*'\(([^']*)\).*/\1/p" | head -1)
    local verify_pattern=$(grep -A3 "verify_no_tokens_in_logs()" ./setup-runner.sh | grep "ghp_" | sed -n "s/.*'\(([^']*)\).*/\1/p" | head -1)

    if [[ "$sanitize_pattern" == "$verify_pattern" ]]; then
        echo -e "${GREEN}✓ PASSED:${NC} Regex patterns are consistent"
        echo "  Pattern: $sanitize_pattern"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAILED:${NC} Regex patterns are inconsistent"
        echo "  sanitize_log: $sanitize_pattern"
        echo "  verify_no_tokens: $verify_pattern"
        ((TESTS_FAILED++))
    fi
    ((TESTS_TOTAL++))
}

################################################################################
# Main Test Execution
################################################################################

main() {
    echo "========================================================"
    echo "Comprehensive Token Sanitization Test Suite"
    echo "Testing ALL GitHub Token Types"
    echo "========================================================"

    # Set up test environment
    setup_test_env

    # Run all tests
    test_all_token_patterns
    test_verify_no_tokens_function
    test_mixed_tokens_sanitization
    test_no_contains_token_function
    test_regex_consistency

    # Clean up
    cleanup_test_env

    # Print summary
    echo ""
    echo "========================================================"
    echo "Test Results Summary"
    echo "========================================================"
    echo -e "${GREEN}Passed:${NC} $TESTS_PASSED"
    echo -e "${RED}Failed:${NC} $TESTS_FAILED"
    echo -e "${BLUE}Total:${NC} $TESTS_TOTAL"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo ""
        echo -e "${GREEN}✓ All tests passed! Token sanitization is comprehensive.${NC}"
        echo ""
        echo "Token types properly handled:"
        echo "  • ghp_ - GitHub personal access tokens (classic)"
        echo "  • ghs_ - GitHub server-to-server tokens"
        echo "  • github_pat_ - GitHub personal access tokens (fine-grained)"
        echo "  • gho_ - GitHub OAuth tokens"
        echo "  • ghr_ - GitHub refresh tokens"
        echo "  • ghu_to_s_ - GitHub user-to-server tokens"
        exit 0
    else
        echo ""
        echo -e "${RED}✗ Some tests failed. Please review the security implementation.${NC}"
        exit 1
    fi
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi