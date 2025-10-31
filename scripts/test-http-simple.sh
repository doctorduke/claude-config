#!/usr/bin/env bash
#
# Simple HTTP status code tests
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Suppress logging during tests
CURRENT_LOG_LEVEL=10

echo "Testing HTTP Status Categorization..."
echo "======================================"

# Test categorize_http_status
echo -n "Test 200 (SUCCESS): "
result=$(categorize_http_status "200") && code=$? || code=$?
[[ "$result" == "SUCCESS" ]] && [[ $code == 0 ]] && echo "PASS" || echo "FAIL"

echo -n "Test 400 (CLIENT_ERROR): "
result=$(categorize_http_status "400") && code=$? || code=$?
[[ "$result" == "CLIENT_ERROR" ]] && [[ $code == 1 ]] && echo "PASS" || echo "FAIL"

echo -n "Test 429 (RATE_LIMIT): "
result=$(categorize_http_status "429") && code=$? || code=$?
[[ "$result" == "RATE_LIMIT" ]] && [[ $code == 2 ]] && echo "PASS" || echo "FAIL"

echo -n "Test 500 (SERVER_ERROR): "
result=$(categorize_http_status "500") && code=$? || code=$?
[[ "$result" == "SERVER_ERROR" ]] && [[ $code == 3 ]] && echo "PASS" || echo "FAIL"

echo -n "Test 000 (UNKNOWN): "
result=$(categorize_http_status "000") && code=$? || code=$?
[[ "$result" == "UNKNOWN" ]] && [[ $code == 4 ]] && echo "PASS" || echo "FAIL"

echo ""
echo "Testing should_retry_http..."
echo "======================================"

# Test should_retry_http - 200 should not retry
echo -n "Test HTTP 200 (no retry): "
should_retry_http 3 1 200 5 >/dev/null 2>&1 && echo "FAIL (should not retry)" || echo "PASS"

# Test should_retry_http - 400 should not retry
echo -n "Test HTTP 400 (no retry): "
should_retry_http 3 1 400 5 >/dev/null 2>&1 && echo "FAIL (should not retry)" || echo "PASS"

# Test should_retry_http - 429 should retry
echo -n "Test HTTP 429 (should retry): "
delay=$(should_retry_http 3 1 429 5 2>/dev/null) && code=$? || code=$?
[[ $code == 0 ]] && [[ "$delay" == "15" ]] && echo "PASS (delay: ${delay}s)" || echo "FAIL"

# Test should_retry_http - 500 should retry
echo -n "Test HTTP 500 (should retry): "
delay=$(should_retry_http 3 1 500 5 2>/dev/null) && code=$? || code=$?
[[ $code == 0 ]] && [[ "$delay" == "5" ]] && echo "PASS (delay: ${delay}s)" || echo "FAIL"

# Test should_retry_http - 500 at max retries should not retry
echo -n "Test HTTP 500 at max retries (no retry): "
should_retry_http 3 3 500 5 >/dev/null 2>&1 && echo "FAIL (should not retry)" || echo "PASS"

echo ""
echo "Testing Retry-After header..."
echo "======================================"

# Create temp file with Retry-After header
headers_file=$(mktemp)
echo "Retry-After: 120" > "$headers_file"

echo -n "Test Retry-After: 120: "
delay=$(get_retry_after "$headers_file")
[[ "$delay" == "120" ]] && echo "PASS" || echo "FAIL (got: $delay)"

# Test missing header
echo "Content-Type: application/json" > "$headers_file"
echo -n "Test missing Retry-After (default 60): "
delay=$(get_retry_after "$headers_file" 60)
[[ "$delay" == "60" ]] && echo "PASS" || echo "FAIL (got: $delay)"

rm -f "$headers_file"

echo ""
echo "All tests completed!"
