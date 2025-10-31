#!/bin/bash
# Test Suite for Log Sanitization Parsers

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LIB_DIR="$PROJECT_DIR/lib"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
assert_contains() {
    local output="$1"
    local expected="$2"
    local test_name="$3"
    
    ((TESTS_RUN++))
    
    if echo "$output" | grep -q "$expected"; then
        echo -e "${GREEN}✓${NC} PASS: $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} FAIL: $test_name"
        echo "  Expected to find: $expected"
        echo "  In output: $(echo "$output" | head -3)"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_not_contains() {
    local output="$1"
    local unexpected="$2"
    local test_name="$3"
    
    ((TESTS_RUN++))
    
    if ! echo "$output" | grep -q "$unexpected"; then
        echo -e "${GREEN}✓${NC} PASS: $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} FAIL: $test_name"
        echo "  Did not expect to find: $unexpected"
        ((TESTS_FAILED++))
        return 1
    fi
}

count_lines() {
    echo "$1" | wc -l
}

# Test npm parser
test_npm_parser() {
    echo -e "\n${YELLOW}Testing NPM Parser${NC}"
    
    # Create sample npm error output
    local npm_output=$(cat << 'NPMEOF'
npm WARN deprecated package@1.0.0: This package is deprecated
npm WARN deprecated another@2.0.0: Use new-package instead
npm ERR! code ENOENT
npm ERR! syscall open
npm ERR! path /path/to/package.json
npm ERR! errno -2
npm ERR! enoent ENOENT: no such file or directory, open '/path/to/package.json'
npm ERR! enoent This is related to npm not being able to find a file.
npm ERR! 
npm ERR! A complete log of this run can be found in:
npm ERR!     /home/user/.npm/_logs/2025-01-27T14_30_22_123Z-debug.log
NPMEOF
)
    
    local result=$("$LIB_DIR/parsers/npm_parser.sh" <<< "$npm_output")
    
    assert_contains "$result" "ENOENT" "npm parser extracts error code"
    assert_contains "$result" "package.json" "npm parser extracts file path"
    assert_not_contains "$result" "deprecated" "npm parser filters warnings"
    assert_not_contains "$result" "complete log" "npm parser filters noise"
    
    local line_count=$(count_lines "$result")
    if [[ $line_count -lt 20 ]]; then
        echo -e "${GREEN}✓${NC} PASS: npm parser reduces output ($line_count lines)"
        ((TESTS_PASSED++))
        ((TESTS_RUN++))
    else
        echo -e "${RED}✗${NC} FAIL: npm parser output too long ($line_count lines)"
        ((TESTS_FAILED++))
        ((TESTS_RUN++))
    fi
}

# Test node parser
test_node_parser() {
    echo -e "\n${YELLOW}Testing Node.js Parser${NC}"
    
    local node_output=$(cat << 'NODEEOF'
/path/to/app.js:42
    throw new Error('Something went wrong');
    ^

Error: Something went wrong
    at Object.<anonymous> (/path/to/app.js:42:11)
    at Module._compile (node:internal/modules/cjs/loader:1254:14)
    at Module._extensions..js (node:internal/modules/cjs/loader:1308:10)
    at Module.load (node:internal/modules/cjs/loader:1117:32)
    at Function.Module._load (node:internal/modules/cjs/loader:958:12)
    at Function.executeUserEntryPoint [as runMain] (node:internal/modules/run_main:81:12)
    at node:internal/main/run_main_module:23:47
NODEEOF
)
    
    local result=$("$LIB_DIR/parsers/node_parser.sh" <<< "$node_output")
    
    assert_contains "$result" "Error: Something went wrong" "node parser captures error message"
    assert_contains "$result" "at Object.<anonymous>" "node parser includes stack trace"
    assert_contains "$result" "/path/to/app.js:42" "node parser includes file location"
}

# Test python parser
test_python_parser() {
    echo -e "\n${YELLOW}Testing Python Parser${NC}"
    
    local python_output=$(cat << 'PYEOF'
Traceback (most recent call last):
  File "/path/to/script.py", line 10, in <module>
    result = divide(10, 0)
  File "/path/to/script.py", line 5, in divide
    return a / b
ZeroDivisionError: division by zero
PYEOF
)
    
    local result=$("$LIB_DIR/parsers/python_parser.sh" <<< "$python_output")
    
    assert_contains "$result" "Traceback" "python parser captures traceback"
    assert_contains "$result" "ZeroDivisionError" "python parser captures exception type"
    assert_contains "$result" "script.py" "python parser includes file name"
}

# Test generic parser
test_generic_parser() {
    echo -e "\n${YELLOW}Testing Generic Parser${NC}"
    
    local generic_output=$(cat << 'GENEOF'
INFO: Starting process...
INFO: Loading configuration...
ERROR: Failed to connect to database
ERROR: Connection timeout after 30 seconds
WARNING: Retrying connection...
ERROR: Max retries exceeded
INFO: Process terminated
GENEOF
)
    
    local result=$("$LIB_DIR/parsers/generic_parser.sh" <<< "$generic_output")
    
    assert_contains "$result" "ERROR" "generic parser captures errors"
    assert_contains "$result" "WARNING" "generic parser captures warnings"
    assert_not_contains "$result" "INFO: Loading" "generic parser filters info lines"
}

# Test ANSI stripper
test_ansi_stripper() {
    echo -e "\n${YELLOW}Testing ANSI Stripper${NC}"
    
    local ansi_output=$(echo -e "\033[31mRed Error\033[0m \033[32mGreen Success\033[0m")
    local result=$("$LIB_DIR/filters/ansi_strip.sh" <<< "$ansi_output")
    
    assert_contains "$result" "Red Error" "ANSI stripper preserves text"
    assert_not_contains "$result" "\033" "ANSI stripper removes escape codes"
}

# Test deduplication
test_dedup() {
    echo -e "\n${YELLOW}Testing Deduplication${NC}"
    
    local dup_output=$(cat << 'DUPEOF'
Error: Connection failed
Error: Connection failed
Error: Connection failed
Warning: Timeout
Error: Connection failed
DUPEOF
)
    
    local result=$("$LIB_DIR/filters/dedup.sh" <<< "$dup_output")
    local line_count=$(count_lines "$result")
    
    if [[ $line_count -eq 2 ]]; then
        echo -e "${GREEN}✓${NC} PASS: dedup removes duplicates (2 unique lines)"
        ((TESTS_PASSED++))
        ((TESTS_RUN++))
    else
        echo -e "${RED}✗${NC} FAIL: dedup didn't work correctly ($line_count lines)"
        ((TESTS_FAILED++))
        ((TESTS_RUN++))
    fi
}

# Run all tests
echo "========================================="
echo "  Log Sanitization Parser Test Suite"
echo "========================================="

test_npm_parser
test_node_parser
test_python_parser
test_generic_parser
test_ansi_stripper
test_dedup

# Print summary
echo ""
echo "========================================="
echo "  Test Summary"
echo "========================================="
echo "Total tests: $TESTS_RUN"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}✗ Some tests failed${NC}"
    exit 1
fi
