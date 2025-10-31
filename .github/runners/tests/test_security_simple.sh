#!/usr/bin/env bash
# Simplified security test suite for temp files

set -euo pipefail

echo "=== Running Temp File Security Tests ==="
echo

TESTS_PASSED=0
TESTS_FAILED=0

# Test 1: Check setup-secrets.sh fix
echo -n "1. setup-secrets.sh uses secure temp file... "
if grep -q 'openssl rsautl.*"${temp_key_file}"' scripts/setup-secrets.sh; then
    echo "✓ PASSED"
    ((TESTS_PASSED++))
else
    echo "✗ FAILED: Not using temp_key_file variable"
    ((TESTS_FAILED++))
fi

# Test 2: Check atomic file creation in common.sh
echo -n "2. Rate limit uses atomic file creation... "
if grep -q 'mv -f.*temp_rate_file.*rate_limit_file' scripts/lib/common.sh; then
    echo "✓ PASSED"
    ((TESTS_PASSED++))
else
    echo "✗ FAILED: Not using atomic move operation"
    ((TESTS_FAILED++))
fi

# Test 3: Check properly quoted trap
echo -n "3. Trap uses proper quoting... "
if grep -q "trap 'rm -f \"\${temp_file}\"'" scripts/lib/common.sh; then
    echo "✓ PASSED"
    ((TESTS_PASSED++))
else
    echo "✗ FAILED: Trap not properly quoted"
    ((TESTS_FAILED++))
fi

# Test 4: Check umask usage for security
echo -n "4. Umask 077 used for secure creation... "
if grep -q 'umask 077' scripts/lib/common.sh; then
    echo "✓ PASSED"
    ((TESTS_PASSED++))
else
    echo "✗ FAILED: umask 077 not found"
    ((TESTS_FAILED++))
fi

# Test 5: Verify no direct write without umask
echo -n "5. No direct write to rate_limit_file... "
if ! grep -q 'date +%s > "${rate_limit_file}"' scripts/lib/common.sh; then
    echo "✓ PASSED"
    ((TESTS_PASSED++))
else
    echo "✗ FAILED: Direct write still present"
    ((TESTS_FAILED++))
fi

echo
echo "=== Test Summary ==="
echo "Passed: ${TESTS_PASSED}"
echo "Failed: ${TESTS_FAILED}"

if [[ ${TESTS_FAILED} -eq 0 ]]; then
    echo "✓ All security tests passed!"
    exit 0
else
    echo "✗ Some tests failed!"
    exit 1
fi