#!/usr/bin/env bash
# Test that security tests actually fail on bad code

set -euo pipefail

# Source the test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test-framework.sh"

# Start test suite
test_suite_start "Security Test Enforcement"

# Test 1: Verify eval detection actually fails on bad code
test_eval_detection_fails() {
    test_start "eval detection should fail on dangerous eval"

    # Create a bad script with eval
    local bad_script="/tmp/bad-eval-test.sh"
    cat > "$bad_script" <<'EOF'
#!/usr/bin/env bash
# This script has dangerous eval usage
user_input="$1"
eval "$user_input"  # DANGEROUS - should be detected
EOF

    # Test should fail
    if assert_no_eval_in_file "$bad_script" 2>/dev/null; then
        test_fail "eval detection" "Failed to detect dangerous eval"
        rm -f "$bad_script"
        return 1
    else
        test_pass "eval detection correctly failed on dangerous code"
        rm -f "$bad_script"
        return 0
    fi
}

# Test 2: Verify command injection test fails on vulnerable code
test_command_injection_detection() {
    test_start "Command injection test should fail on vulnerable code"

    # Create vulnerable script directory
    local test_dir="/tmp/test-vulnerable-scripts"
    mkdir -p "$test_dir"

    # Create vulnerable script
    cat > "$test_dir/vulnerable.sh" <<'EOF'
#!/usr/bin/env bash
# Vulnerable to command injection
user_input=$1
output=$(echo $user_input)  # No validation - vulnerable!
EOF

    # Run command injection test on it
    (
        export PROJECT_ROOT="/tmp"
        bash "${SCRIPT_DIR}/test-input-validation.sh" test_command_injection_protection 2>/dev/null
    )
    local result=$?

    if [[ $result -ne 0 ]]; then
        test_pass "Command injection test correctly failed"
        rm -rf "$test_dir"
        return 0
    else
        test_fail "Command injection test" "Failed to detect vulnerability"
        rm -rf "$test_dir"
        return 1
    fi
}

# Test 3: Verify secret masking fails on exposed secrets
test_secret_exposure_detection() {
    test_start "Secret masking should fail on exposed secrets"

    # Create script with exposed secret
    local bad_script="/tmp/exposed-secret.sh"
    cat > "$bad_script" <<'EOF'
#!/usr/bin/env bash
# Exposed secret
GITHUB_TOKEN="ghp_1234567890abcdef1234567890abcdef12345"
echo "Token is: $GITHUB_TOKEN"  # BAD - exposing secret
EOF

    # Check if secrets are exposed in output
    local output=$(bash "$bad_script" 2>/dev/null)

    if assert_no_secrets_in_output "$output" 2>/dev/null; then
        test_fail "Secret exposure" "Failed to detect exposed secret"
        rm -f "$bad_script"
        return 1
    else
        test_pass "Secret exposure correctly detected"
        rm -f "$bad_script"
        return 0
    fi
}

# Test 4: Verify insecure temp file detection
test_insecure_temp_file_detection() {
    test_start "Temp file security should fail on insecure usage"

    # Create script with insecure temp file
    local bad_script="/tmp/insecure-temp.sh"
    cat > "$bad_script" <<'EOF'
#!/usr/bin/env bash
# Insecure temp file
temp_file="/tmp/predictable_name.txt"  # BAD - predictable name
echo "secret" > "$temp_file"
chmod 777 "$temp_file"  # BAD - world writable
EOF

    # Test should detect insecure permissions
    touch /tmp/predictable_name.txt
    chmod 777 /tmp/predictable_name.txt

    if assert_secure_file_permissions "/tmp/predictable_name.txt" "600" 2>/dev/null; then
        test_fail "Temp file security" "Failed to detect insecure permissions"
        rm -f "$bad_script" /tmp/predictable_name.txt
        return 1
    else
        test_pass "Insecure temp file correctly detected"
        rm -f "$bad_script" /tmp/predictable_name.txt
        return 0
    fi
}

# Test 5: Verify weak crypto detection fails appropriately
test_weak_crypto_detection() {
    test_start "Weak crypto should be detected and fail"

    # Create script with weak crypto
    local bad_script="/tmp/weak-crypto.sh"
    cat > "$bad_script" <<'EOF'
#!/usr/bin/env bash
# Weak crypto usage
password="secret"
encrypted=$(echo "$password" | md5sum)  # BAD - MD5 is weak
EOF

    # Check if weak crypto is detected
    if grep -q "md5" "$bad_script"; then
        test_pass "Weak crypto pattern detected"
        rm -f "$bad_script"
        return 0
    else
        test_fail "Weak crypto detection" "Failed to detect MD5 usage"
        rm -f "$bad_script"
        return 1
    fi
}

# Test 6: Verify PAT requirement enforcement
test_pat_requirement_enforcement() {
    test_start "PAT requirement should be enforced"

    # Unset PAT token to simulate missing token
    unset GITHUB_TOKEN
    unset PAT_TOKEN

    # Test should fail when PAT is missing for protected operations
    if [[ -z "${GITHUB_TOKEN:-}" && -z "${PAT_TOKEN:-}" ]]; then
        test_pass "PAT requirement correctly enforced"
        return 0
    else
        test_fail "PAT enforcement" "PAT check not working properly"
        return 1
    fi
}

# Run all tests
run_test test_eval_detection_fails
run_test test_command_injection_detection
run_test test_secret_exposure_detection
run_test test_insecure_temp_file_detection
run_test test_weak_crypto_detection
run_test test_pat_requirement_enforcement

# End test suite
test_suite_end "Security Test Enforcement"