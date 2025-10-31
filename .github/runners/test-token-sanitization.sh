#!/usr/bin/env bash

################################################################################
# Token Sanitization Test Suite
# Tests for CRITICAL SECURITY FIX - Task #3
#
# This script verifies that tokens are properly sanitized in all log output
# and that no sensitive information is exposed during runner setup.
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
        # Default token patterns
        pattern='(ghp_|ghs_|github_pat_)[A-Za-z0-9_]+'
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

assert_equals() {
    local actual="$1"
    local expected="$2"
    local test_name="$3"

    ((TESTS_TOTAL++))

    if [[ "$actual" == "$expected" ]]; then
        echo -e "${GREEN}✓ PASSED:${NC} $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAILED:${NC} $test_name"
        echo "  Expected: $expected"
        echo "  Actual: $actual"
        ((TESTS_FAILED++))
        return 1
    fi
}

################################################################################
# Unit Tests for Security Functions
################################################################################

test_mask_token_function() {
    echo -e "\n${YELLOW}Testing mask_token function...${NC}"

    # Source the script to get access to functions
    source ./setup-runner.sh 2>/dev/null || true

    # Test empty token
    local result=$(mask_token "")
    assert_equals "$result" "[EMPTY]" "mask_token: empty string"

    # Test short token
    result=$(mask_token "short")
    assert_equals "$result" "[REDACTED]" "mask_token: short token"

    # Test normal token
    result=$(mask_token "ghp_1234567890abcdefghij")
    assert_equals "$result" "ghp_...ghij" "mask_token: normal token"

    # Test long token
    result=$(mask_token "github_pat_11ABCDEF2G3HIJKLMNOP4QRSTUV5WXYZ67890abcdefghijklmnop")
    assert_equals "$result" "gith...mnop" "mask_token: long token"
}

test_sanitize_log_function() {
    echo -e "\n${YELLOW}Testing sanitize_log function...${NC}"

    # Source the script to get access to functions
    source ./setup-runner.sh 2>/dev/null || true

    # Test GitHub personal access token
    local result=$(sanitize_log "Using token ghp_1234567890abcdefghij for authentication")
    assert_contains "$result" "\[REDACTED\]" "sanitize_log: GitHub PAT"
    assert_no_token <(echo "$result") "sanitize_log: No exposed GitHub PAT" "ghp_"

    # Test GitHub server token
    result=$(sanitize_log "Token: ghs_abcdef123456 is valid")
    assert_contains "$result" "\[REDACTED\]" "sanitize_log: GitHub server token"
    assert_no_token <(echo "$result") "sanitize_log: No exposed server token" "ghs_"

    # Test new GitHub PAT format
    result=$(sanitize_log "github_pat_11ABCDEF2G3HIJKLMNOP4QRSTUV5WXYZ67890abcdefghijklmnop")
    assert_contains "$result" "\[REDACTED\]" "sanitize_log: New GitHub PAT format"
    assert_no_token <(echo "$result") "sanitize_log: No exposed new PAT" "github_pat_"

    # Test command line token
    result=$(sanitize_log "./config.sh --token ghp_secrettoken123 --name runner")
    assert_contains "$result" "\[REDACTED\]" "sanitize_log: Command line token"
    assert_no_token <(echo "$result") "sanitize_log: No exposed CLI token" "ghp_"

    # Test token in various formats
    result=$(sanitize_log "token=ghp_abc123 TOKEN: ghs_def456 --token github_pat_xyz789")
    assert_no_token <(echo "$result") "sanitize_log: Multiple token formats" "(ghp_|ghs_|github_pat_)"
}

################################################################################
# Integration Tests
################################################################################

test_no_eval_usage() {
    echo -e "\n${YELLOW}Testing removal of eval command...${NC}"

    # Check that eval is not used for command execution
    if grep -n "eval.*config_cmd" ./setup-runner.sh; then
        echo -e "${RED}✗ FAILED:${NC} eval command still present in setup-runner.sh"
        ((TESTS_FAILED++))
        ((TESTS_TOTAL++))
    else
        echo -e "${GREEN}✓ PASSED:${NC} No eval usage for config commands"
        ((TESTS_PASSED++))
        ((TESTS_TOTAL++))
    fi
}

test_array_based_commands() {
    echo -e "\n${YELLOW}Testing array-based command construction...${NC}"

    # Check for array-based command construction
    if grep -q 'config_args\[\@\]' ./setup-runner.sh; then
        echo -e "${GREEN}✓ PASSED:${NC} Array-based command construction found"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAILED:${NC} Array-based command construction not found"
        ((TESTS_FAILED++))
    fi
    ((TESTS_TOTAL++))
}

test_log_output_sanitization() {
    echo -e "\n${YELLOW}Testing log output sanitization...${NC}"

    # Create a test script that uses the logging functions
    cat > test_logging.sh << 'TEST_EOF'
#!/bin/bash
source ./setup-runner.sh 2>/dev/null || true

# Test various log functions with tokens
log "Setting up with token ghp_testtoken123456"
log_info "Token: ghs_servertoken789 initialized"
log_error "Failed with github_pat_11ABCDEF2G3HIJKLMNOP"
log_warn "Using --token ghp_anothertoken for config"
TEST_EOF

    chmod +x test_logging.sh

    # Run the test and capture output
    ./test_logging.sh > test_output.txt 2>&1 || true

    # Verify no tokens in output
    assert_no_token test_output.txt "Log output contains no GitHub tokens"
    assert_contains "$(cat test_output.txt)" "\[REDACTED\]" "Log output contains [REDACTED] placeholders"
}

test_help_output_sanitization() {
    echo -e "\n${YELLOW}Testing help output sanitization...${NC}"

    # Check that help examples don't contain real tokens
    if grep -q 'ghp_xxxxxxxxxxxxx' ./setup-runner.sh; then
        echo -e "${RED}✗ FAILED:${NC} Help output contains example tokens"
        ((TESTS_FAILED++))
    else
        if grep -q '\[REDACTED\]' ./setup-runner.sh; then
            echo -e "${GREEN}✓ PASSED:${NC} Help output uses [REDACTED] for tokens"
            ((TESTS_PASSED++))
        else
            echo -e "${YELLOW}⚠ WARNING:${NC} Help output doesn't show token examples"
            ((TESTS_PASSED++))
        fi
    fi
    ((TESTS_TOTAL++))
}

test_verification_function() {
    echo -e "\n${YELLOW}Testing token verification function...${NC}"

    # Source the script to get access to functions
    source ./setup-runner.sh 2>/dev/null || true

    # Create a test log with a token
    echo "Test with token ghp_secrettoken123" > test_with_token.log
    LOG_FILE="test_with_token.log"
    if verify_no_tokens_in_logs 2>/dev/null; then
        echo -e "${RED}✗ FAILED:${NC} verify_no_tokens_in_logs didn't detect token"
        ((TESTS_FAILED++))
    else
        echo -e "${GREEN}✓ PASSED:${NC} verify_no_tokens_in_logs detected token"
        ((TESTS_PASSED++))
    fi
    ((TESTS_TOTAL++))

    # Create a clean log
    echo "Test without any secrets" > test_clean.log
    LOG_FILE="test_clean.log"
    if verify_no_tokens_in_logs; then
        echo -e "${GREEN}✓ PASSED:${NC} verify_no_tokens_in_logs passed on clean log"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAILED:${NC} verify_no_tokens_in_logs failed on clean log"
        ((TESTS_FAILED++))
    fi
    ((TESTS_TOTAL++))
}

################################################################################
# Security Validation Tests
################################################################################

test_common_token_patterns() {
    echo -e "\n${YELLOW}Testing common token pattern detection...${NC}"

    # Test file for various token patterns
    cat > token_patterns.txt << 'PATTERNS_EOF'
# GitHub Personal Access Token (classic)
ghp_1234567890abcdefghijklmnopqrstuvwxyz

# GitHub Server Token
ghs_abcdefghijklmnop1234567890

# New GitHub PAT format
github_pat_11ABCDEF2G3HIJKLMNOP4QRSTUV5WXYZ67890abcdefghijklmnop

# OAuth tokens
gho_16C3B1A21E23D4F5G6H7I8J9K0LMNOPQRSTUVWX

# Installation access tokens
ghs_16C3B1A21E23D4F5G6H7I8J9K0LMNOPQRSTUVWX

# Refresh tokens
ghr_1B2C3D4E5F6A7B8C9D0E1F2G3H4I5J6K7L8M9N0

# User-to-server tokens
ghu_16C3B1A21E23D4F5G6H7I8J9K0LMNOPQRSTUVWX
PATTERNS_EOF

    # Source script and test each pattern
    source ./setup-runner.sh 2>/dev/null || true

    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue

        # Test sanitization
        local sanitized=$(sanitize_log "$line")
        if [[ "$sanitized" == *"[REDACTED]"* ]] && [[ "$sanitized" != *"ghp_"* ]] && [[ "$sanitized" != *"ghs_"* ]] && [[ "$sanitized" != *"github_pat_"* ]] && [[ "$sanitized" != *"gho_"* ]] && [[ "$sanitized" != *"ghr_"* ]] && [[ "$sanitized" != *"ghu_"* ]]; then
            echo -e "${GREEN}✓${NC} Pattern sanitized: ${line:0:10}..."
            ((TESTS_PASSED++))
        else
            echo -e "${RED}✗${NC} Pattern NOT sanitized: $line"
            ((TESTS_FAILED++))
        fi
        ((TESTS_TOTAL++))
    done < token_patterns.txt
}

################################################################################
# Main Test Execution
################################################################################

main() {
    echo "========================================================"
    echo "Token Sanitization Security Test Suite"
    echo "Testing CRITICAL SECURITY FIX - Task #3"
    echo "========================================================"

    # Set up test environment
    setup_test_env

    # Run all tests
    test_mask_token_function
    test_sanitize_log_function
    test_no_eval_usage
    test_array_based_commands
    test_log_output_sanitization
    test_help_output_sanitization
    test_verification_function
    test_common_token_patterns

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
        echo -e "${GREEN}✓ All tests passed! Token sanitization is working correctly.${NC}"
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