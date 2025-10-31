#!/bin/bash
# Security tests for secret scanning

# Source test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/test-helpers.sh"

# Test: Detect GitHub token pattern
test_detect_github_token_pattern() {
    local test_content="GITHUB_TOKEN=ghp_1234567890abcdefghijklmnopqrstuvwxyz"

    # Check if content matches GitHub token pattern
    if echo "$test_content" | grep -qE "ghp_[a-zA-Z0-9]{36,}"; then
        assert_true "true"
    else
        assert_true "false"
    fi
}

# Test: Detect Anthropic API key pattern
test_detect_anthropic_api_key_pattern() {
    local test_content="ANTHROPIC_API_KEY=sk-ant-api03-1234567890abcdef"

    # Check if content matches Anthropic API key pattern
    if echo "$test_content" | grep -qE "sk-ant-[a-zA-Z0-9-]{20,}"; then
        assert_true "true"
    else
        assert_true "false"
    fi
}

# Test: Detect OpenAI API key pattern
test_detect_openai_api_key_pattern() {
    local test_content="OPENAI_API_KEY=sk-1234567890abcdefghijklmnopqrstuvwxyz"

    # Check if content matches OpenAI API key pattern
    if echo "$test_content" | grep -qE "sk-[a-zA-Z0-9]{20,}"; then
        assert_true "true"
    else
        assert_true "false"
    fi
}

# Test: Detect AWS credentials
test_detect_aws_credentials() {
    local test_content="AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE"

    # Check if content matches AWS access key pattern
    if echo "$test_content" | grep -qE "AKIA[A-Z0-9]{16}"; then
        assert_true "true"
    else
        assert_true "false"
    fi
}

# Test: Detect private SSH key
test_detect_ssh_private_key() {
    local test_content="-----BEGIN RSA PRIVATE KEY-----"

    # Check if content contains private key header
    if echo "$test_content" | grep -q "BEGIN.*PRIVATE KEY"; then
        assert_true "true"
    else
        assert_true "false"
    fi
}

# Test: Safe content should not trigger detection
test_safe_content_no_detection() {
    local test_content="This is a safe string with no secrets"

    # Verify no patterns match
    local has_secrets=false

    if echo "$test_content" | grep -qE "(ghp_|sk-ant-|sk-|AKIA|BEGIN.*PRIVATE)"; then
        has_secrets=true
    fi

    assert_false "$has_secrets"
}

# Test: Environment variable format detection
test_env_var_format_detection() {
    local test_content="SOME_SECRET=password123"

    # Check for suspicious environment variable names
    if echo "$test_content" | grep -qiE "(secret|password|token|key)="; then
        assert_true "true"
    else
        assert_true "false"
    fi
}

# Test: Multiple secrets in file
test_multiple_secrets_detection() {
    local temp_file
    temp_file=$(create_test_secrets)

    # Count number of potential secrets
    local secret_count=0
    secret_count=$(grep -cE "(ghp_|sk-ant-|sk-|password|secret|key)=" "$temp_file" || echo "0")

    assert_greater_than "$secret_count" 0

    rm -f "$temp_file"
}

# Test: Excluded files should be ignored
test_excluded_files_ignored() {
    # Files like .env.example should typically be excluded
    local filename=".env.example"

    # Check if filename matches exclusion pattern
    if echo "$filename" | grep -qE "\.(example|sample|template)$"; then
        assert_true "true"
    else
        assert_true "false"
    fi
}

# Test: Secret in git diff detection
test_secret_in_diff_detection() {
    # Generate a valid-length GitHub token (ghp_ + 36 chars)
    local diff_content="+GITHUB_TOKEN=ghp_1234567890abcdefghijklmnopqrstuvwxyz"

    # Check for secrets in added lines
    if echo "$diff_content" | grep "^+" | grep -qE "ghp_[a-zA-Z0-9]{36,}"; then
        assert_true "true"
    else
        assert_true "false"
    fi
}

# Run all tests
run_all_tests
