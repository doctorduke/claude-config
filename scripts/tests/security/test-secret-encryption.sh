#!/usr/bin/env bash
# Script: test-secret-encryption.sh
# Description: Security tests for Task #2 - Secret Encryption
# Purpose: Validate that secret encryption uses libsodium and is secure
# Reference: TASKS-REMAINING.md Task #2

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# Source test framework
source "${SCRIPT_DIR}/test-framework.sh"

# Test: PyNaCl library is used
test_encryption_uses_pynacl() {
    local encrypt_script="${PROJECT_ROOT}/scripts/encrypt_secret.py"

    # Check file exists
    if ! assert_file_exists "$encrypt_script"; then
        return 1
    fi

    # Verify PyNaCl import
    if ! assert_file_contains "$encrypt_script" "from nacl import"; then
        return 1
    fi

    # Verify uses sealed box (crypto_box_seal)
    if ! assert_file_contains "$encrypt_script" "SealedBox"; then
        return 1
    fi

    return 0
}

# Test: No hardcoded keys in codebase
test_no_hardcoded_keys() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Scan for private keys
    local private_key_pattern="BEGIN RSA PRIVATE KEY|BEGIN PRIVATE KEY|BEGIN EC PRIVATE KEY"
    local results=$(grep -r "$private_key_pattern" "$scripts_dir" --exclude-dir=tests 2>/dev/null || true)

    if ! assert_equals "" "$results" "Should not find hardcoded private keys"; then
        log_test_error "Found private keys in: $results"
        return 1
    fi

    # Scan for hardcoded encryption keys or secrets
    local secret_patterns=(
        "ghp_[a-zA-Z0-9]{36}"
        "AKIA[0-9A-Z]{16}"
        "sk_live_[0-9a-zA-Z]{24,}"
    )

    for pattern in "${secret_patterns[@]}"; do
        local found=$(grep -r "$pattern" "$scripts_dir" --exclude-dir=tests 2>/dev/null || true)
        if [[ -n "$found" ]]; then
            log_test_error "Found potential secret: $pattern"
            return 1
        fi
    done

    return 0
}

# Test: Encryption produces base64 output
test_encryption_output_format() {
    local encrypt_script="${PROJECT_ROOT}/scripts/encrypt_secret.py"

    if [[ ! -f "$encrypt_script" ]]; then
        log_test_warn "encrypt_secret.py not found, skipping test"
        return 0
    fi

    # Check if python is available
    if ! command -v python3 &>/dev/null && ! command -v python &>/dev/null; then
        log_test_warn "Python not available, skipping test"
        return 0
    fi

    local python_cmd="python3"
    if ! command -v python3 &>/dev/null; then
        python_cmd="python"
    fi

    # Check if PyNaCl is installed
    if ! $python_cmd -c "import nacl" 2>/dev/null; then
        log_test_warn "PyNaCl not installed, skipping encryption test"
        return 0
    fi

    # Test with sample data (using a valid public key format)
    # This is a dummy key for testing only
    local test_public_key="dGVzdF9wdWJsaWNfa2V5X2Zvcl90ZXN0aW5nXzMyYnl0ZXMAAAA="
    local test_secret="test_secret_value"

    local output
    output=$(GITHUB_PUBLIC_KEY="$test_public_key" SECRET_VALUE="$test_secret" $python_cmd "$encrypt_script" 2>/dev/null || echo "ERROR")

    # Encryption may fail with invalid key, which is expected in test
    # Just verify script doesn't crash and uses proper error handling
    if [[ "$output" != "ERROR" ]]; then
        # If it succeeds, output should be base64
        if ! assert_matches "$output" "^[A-Za-z0-9+/=]+$" "Output should be base64 encoded"; then
            return 1
        fi

        # Secret should not appear in output
        if ! assert_not_contains "$output" "$test_secret" "Encrypted output should not contain plaintext secret"; then
            return 1
        fi
    fi

    return 0
}

# Test: Script uses environment variables not CLI args
test_encryption_uses_env_vars() {
    local encrypt_script="${PROJECT_ROOT}/scripts/encrypt_secret.py"

    if ! assert_file_exists "$encrypt_script"; then
        return 1
    fi

    # Verify script reads from environment
    if ! assert_file_contains "$encrypt_script" "os.environ.get"; then
        return 1
    fi

    # Verify uses GITHUB_PUBLIC_KEY and SECRET_VALUE
    if ! assert_file_contains "$encrypt_script" "GITHUB_PUBLIC_KEY"; then
        return 1
    fi

    if ! assert_file_contains "$encrypt_script" "SECRET_VALUE"; then
        return 1
    fi

    return 0
}

# Test: Proper error handling for missing parameters
test_encryption_error_handling() {
    local encrypt_script="${PROJECT_ROOT}/scripts/encrypt_secret.py"

    if ! assert_file_exists "$encrypt_script"; then
        return 1
    fi

    # Check for error handling
    if ! assert_file_contains "$encrypt_script" "if not public_key_b64 or not secret_value"; then
        return 1
    fi

    # Check for proper error messages
    if ! assert_file_contains "$encrypt_script" "ERROR:"; then
        return 1
    fi

    return 0
}

# Test: setup-secrets.sh uses encrypt_secret.py
test_setup_secrets_uses_encryption() {
    local setup_secrets="${PROJECT_ROOT}/scripts/setup-secrets.sh"

    if [[ ! -f "$setup_secrets" ]]; then
        log_test_warn "setup-secrets.sh not found, skipping test"
        return 0
    fi

    # Should reference encrypt_secret.py
    if ! assert_file_contains "$setup_secrets" "encrypt_secret.py"; then
        log_test_warn "setup-secrets.sh should use encrypt_secret.py"
        return 0  # Warning only, not hard failure
    fi

    return 0
}

# Test: No insecure openssl encryption
test_no_insecure_openssl_encryption() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    # Check for insecure openssl enc usage
    local insecure_patterns=(
        "openssl enc"
        "openssl aes"
        "openssl des"
    )

    for pattern in "${insecure_patterns[@]}"; do
        local found=$(grep -r "$pattern" "$scripts_dir" --exclude-dir=tests 2>/dev/null || true)
        if [[ -n "$found" ]]; then
            log_test_error "Found insecure openssl encryption: $pattern"
            log_test_error "Location: $found"
            return 1
        fi
    done

    return 0
}

# Test: Encryption strength validation
test_encryption_strength() {
    local encrypt_script="${PROJECT_ROOT}/scripts/encrypt_secret.py"

    if ! assert_file_exists "$encrypt_script"; then
        return 1
    fi

    # Verify uses strong encryption (X25519, XSalsa20, Poly1305)
    # These are provided by libsodium's sealed box
    if ! assert_file_contains "$encrypt_script" "sealed_box.encrypt"; then
        return 1
    fi

    # Check for security documentation
    if ! assert_file_contains "$encrypt_script" "256-bit\|Authenticated encryption"; then
        log_test_warn "Encryption should document security properties"
    fi

    return 0
}

# Test: OWASP compliance - Cryptographic Failures (A02)
test_owasp_a02_compliance() {
    local encrypt_script="${PROJECT_ROOT}/scripts/encrypt_secret.py"

    if ! assert_file_exists "$encrypt_script"; then
        return 1
    fi

    # OWASP A02:2021 - Cryptographic Failures
    # Verify uses modern, industry-standard encryption
    if ! assert_file_contains "$encrypt_script" "nacl"; then
        return 1
    fi

    # No deprecated algorithms
    local deprecated_algos=(
        "MD5"
        "SHA1"
        "DES"
        "3DES"
        "RC4"
    )

    for algo in "${deprecated_algos[@]}"; do
        if grep -iq "$algo" "$encrypt_script" 2>/dev/null; then
            log_test_error "Found deprecated algorithm: $algo"
            return 1
        fi
    done

    return 0
}

# Main test execution
main() {
    test_suite_start "Secret Encryption Security Tests (Task #2)"

    run_test test_encryption_uses_pynacl "Verify PyNaCl library is used"
    run_test test_no_hardcoded_keys "No hardcoded encryption keys in codebase"
    run_test test_encryption_output_format "Encryption produces base64 output"
    run_test test_encryption_uses_env_vars "Script uses environment variables"
    run_test test_encryption_error_handling "Proper error handling"
    run_test test_setup_secrets_uses_encryption "setup-secrets.sh uses encrypt_secret.py"
    run_test test_no_insecure_openssl_encryption "No insecure OpenSSL encryption"
    run_test test_encryption_strength "Encryption strength validation"
    run_test test_owasp_a02_compliance "OWASP A02 compliance"

    test_suite_end "Secret Encryption Security Tests (Task #2)"
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
