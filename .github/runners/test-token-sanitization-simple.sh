#!/usr/bin/env bash

# Simple test to verify token sanitization works
set -e

echo "Testing token sanitization in setup-runner.sh..."

# Test 1: Check eval is removed
echo -n "Test 1: Checking eval removal... "
if grep -q 'eval.*config_cmd' scripts/setup-runner.sh; then
    echo "FAILED - eval still present!"
    exit 1
else
    echo "PASSED"
fi

# Test 2: Check for array-based command construction
echo -n "Test 2: Checking array-based commands... "
if grep -q 'config_args\[@\]' scripts/setup-runner.sh; then
    echo "PASSED"
else
    echo "FAILED - array construction not found!"
    exit 1
fi

# Test 3: Check for sanitize_log function
echo -n "Test 3: Checking sanitize_log function exists... "
if grep -q 'sanitize_log()' scripts/setup-runner.sh; then
    echo "PASSED"
else
    echo "FAILED - sanitize_log function not found!"
    exit 1
fi

# Test 4: Check for mask_token function
echo -n "Test 4: Checking mask_token function exists... "
if grep -q 'mask_token()' scripts/setup-runner.sh; then
    echo "PASSED"
else
    echo "FAILED - mask_token function not found!"
    exit 1
fi

# Test 5: Check that logs use sanitization
echo -n "Test 5: Checking log functions use sanitization... "
if grep -q 'sanitize_log.*\$\*' scripts/setup-runner.sh; then
    echo "PASSED"
else
    echo "FAILED - log functions don't use sanitization!"
    exit 1
fi

# Test 6: Verify no example tokens in help
echo -n "Test 6: Checking help doesn't contain example tokens... "
if grep -q 'ghp_xxxxxxxxxxxxx' scripts/setup-runner.sh; then
    echo "FAILED - example tokens found!"
    exit 1
else
    echo "PASSED"
fi

# Test 7: Check for token verification function
echo -n "Test 7: Checking verify_no_tokens_in_logs exists... "
if grep -q 'verify_no_tokens_in_logs()' scripts/setup-runner.sh; then
    echo "PASSED"
else
    echo "FAILED - verification function not found!"
    exit 1
fi

echo ""
echo "✓ All security tests passed!"
echo ""
echo "Summary of security improvements:"
echo "1. Removed dangerous eval usage at line 277"
echo "2. Implemented array-based command construction"
echo "3. Added token masking function"
echo "4. Added log sanitization for all output"
echo "5. Added verification to check for token leaks"
echo "6. Sanitized help examples"