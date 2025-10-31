#!/usr/bin/env bash
# Script: test-working.sh
# Description: Working unit tests for common.sh
# Usage: ./test-working.sh

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Counters
PASSED=0
FAILED=0

# Get directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo -e "${BLUE}==========================================
Unit Tests for common.sh
==========================================${RESET}
"

# Test runner
test_it() {
    local name="$1"
    shift

    # Capture output for debugging
    local output
    local exit_code
    output=$("$@" 2>&1)
    exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        echo -e "  ${GREEN}✓${RESET} ${name}"
        ((PASSED++))
    else
        echo -e "  ${RED}✗${RESET} ${name}"
        # Show error output for debugging
        if [[ -n "$output" ]]; then
            echo "    Error: $output" >&2
        fi
        ((FAILED++))
    fi
}

# Source common.sh once
cd "${ROOT_DIR}"
source lib/common.sh

# ============================================================
# Tests
# ============================================================

echo "=== Logging Functions (6 tests) ==="

test_it "log_info exists" command -v log_info
test_it "log_warn exists" command -v log_warn
test_it "log_error exists" command -v log_error
test_it "log_debug exists" command -v log_debug
test_it "success exists" command -v success
test_it "enable_verbose exists" command -v enable_verbose

echo ""
echo "=== Environment Functions (4 tests) ==="

export TEST_VAR="value"
test_it "check_required_env with valid var" check_required_env TEST_VAR
test_it "check_required_commands with bash" check_required_commands bash
test_it "is_github_actions false" bash -c "unset GITHUB_ACTIONS; source lib/common.sh; ! is_github_actions"

export GITHUB_ACTIONS="true"
test_it "is_github_actions true" is_github_actions

echo ""
echo "=== Path Functions (2 tests) ==="

test_it "normalize_path works" bash -c "[[ -n \$(normalize_path '/test') ]]"
test_it "create_temp_file works" bash -c "f=\$(create_temp_file 'test'); [[ -f \$f ]]; rm -f \$f"

echo ""
echo "=== JSON Functions (3 tests) ==="

test_it "escape_json works" bash -c "[[ -n \$(escape_json 'test') ]]"

tmpfile=$(mktemp)
echo '{"key":"value"}' > "${tmpfile}"
test_it "validate_json valid" validate_json "${tmpfile}"
rm -f "${tmpfile}"

tmpfile=$(mktemp)
echo '{invalid}' > "${tmpfile}"
test_it "validate_json invalid" bash -c "! validate_json '${tmpfile}'"
rm -f "${tmpfile}"

echo ""
echo "=== GitHub Functions (3 tests) ==="

export GITHUB_TOKEN="test_token"
test_it "get_github_token from GITHUB_TOKEN" bash -c "[[ \$(get_github_token) == 'test_token' ]]"

export GITHUB_REPOSITORY="user/repo"
test_it "get_current_repo from env" bash -c "[[ \$(get_current_repo) == 'user/repo' ]]"

unset GITHUB_ACTIONS
test_it "is_github_actions false when unset" bash -c "! is_github_actions"

echo ""
echo "=== AI API Functions (2 tests) ==="

test_it "extract_ai_response anthropic" bash -c "[[ \$(extract_ai_response '{\"content\":[{\"text\":\"result\"}]}' 'anthropic') == 'result' ]]"
test_it "extract_ai_response openai" bash -c "[[ \$(extract_ai_response '{\"choices\":[{\"message\":{\"content\":\"result\"}}]}' 'openai') == 'result' ]]"

echo ""

# ============================================================
# Summary
# ============================================================

TOTAL=$((PASSED + FAILED))

echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Total:   ${TOTAL}"
echo -e "Passed:  ${GREEN}${PASSED}${RESET}"
echo -e "Failed:  ${RED}${FAILED}${RESET}"

# Calculate percentage
if [[ ${TOTAL} -gt 0 ]]; then
    PCT=$((PASSED * 100 / TOTAL))
    echo "Success: ${PCT}%"
fi

echo "=========================================="

if [[ ${FAILED} -eq 0 ]]; then
    echo -e "${GREEN}ALL TESTS PASSED${RESET}"
    exit 0
else
    echo -e "${RED}SOME TESTS FAILED${RESET}"
    exit 1
fi
