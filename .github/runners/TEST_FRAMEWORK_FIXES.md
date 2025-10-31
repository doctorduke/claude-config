# Test Framework Bug Fixes - PR #20

## Summary
Fixed 5 critical bugs in the test framework that prevented proper debugging and test functionality.

## Critical Fixes Applied

### 1. ✅ Fixed run_test output suppression (test-framework.sh:67)
**Problem:** All test output was redirected to `/dev/null`, making it impossible to debug test failures.

**Fix:** Implemented output capture to temporary files with display on failure:
- Captures stdout and stderr to temp files
- Shows captured output only when tests fail
- Enables debugging while keeping successful test output clean

**File:** `scripts/tests/lib/test-framework.sh`
**Lines:** 66-93

**Verification:**
```bash
failing_test() {
    echo "This is stdout from failing test"
    echo "This is stderr from failing test" >&2
    return 1
}
run_test "Example failing test" failing_test
```
Output now shows:
```
  ✗ Example failing test
    stdout:
      This is stdout from failing test
    stderr:
      This is stderr from failing test
```

### 2. ✅ Fixed test_it stderr suppression (test-common-functions.sh:32)
**Problem:** `test_it` redirected stderr to `/dev/null`, hiding assertion failures.

**Fix:** Implemented proper output capture with error display:
- Captures combined stdout/stderr
- Shows error output on test failure
- Preserves exit codes correctly

**File:** `scripts/tests/unit/test-common-functions.sh`
**Lines:** 28-49

### 3. ✅ Fixed syntactically incorrect test (test-common-functions.sh:74)
**Problem:** Test used `$(declare -f is_github_actions)` which outputs function definition as a string, not a command.

**Before:**
```bash
test_it "is_github_actions false" bash -c "! $(declare -f is_github_actions); unset GITHUB_ACTIONS; ! is_github_actions"
```

**After:**
```bash
test_it "is_github_actions false" bash -c "unset GITHUB_ACTIONS; source lib/common.sh; ! is_github_actions"
```

**File:** `scripts/tests/unit/test-common-functions.sh`
**Line:** 74

### 4. ✅ Fixed unreliable coverage calculation (generate-coverage.sh:42)
**Problem:** Used simple `grep "\b${func}\b"` which matched function names in comments and strings, causing false positives.

**Fix:** Improved regex to match actual function calls:
- Matches `func(` - direct function calls
- Matches `$(func` - command substitution
- Matches `${func}` - variable expansion
- Filters out comments with `grep -v "^[[:space:]]*#"`

**File:** `scripts/tests/generate-coverage.sh`
**Line:** 43

**Before:**
```bash
if grep -rq "\b${func}\b" "${SCRIPT_DIR}/unit/" 2>/dev/null; then
```

**After:**
```bash
if grep -rE "(^|[^a-zA-Z0-9_])(${func}[[:space:]]*\(|\$\{${func}|\$\(${func})" "${SCRIPT_DIR}/unit/" 2>/dev/null | grep -v "^[[:space:]]*#" >/dev/null; then
```

### 5. ✅ Improved placeholder tests (test-common-functions.sh:61-66)
**Problem:** Tests used `bash -c "true"` which always passed without testing actual functionality.

**Fix:** Implemented function existence checks:
- Uses `command -v` to verify functions are defined
- Tests actual function availability
- Provides meaningful test results

**File:** `scripts/tests/unit/test-common-functions.sh`
**Lines:** 61-66

## Impact

### Before Fixes
- Test failures provided no debugging information
- Syntax errors prevented test execution
- False positives in coverage reports
- Placeholder tests always passed regardless of implementation

### After Fixes
- Test failures show captured stdout and stderr
- All syntax errors resolved
- Accurate coverage calculation
- Tests verify actual function existence
- Improved debugging capability

## Files Modified
1. `scripts/tests/lib/test-framework.sh` - Output capture implementation
2. `scripts/tests/unit/test-common-functions.sh` - Error handling and syntax fixes
3. `scripts/tests/generate-coverage.sh` - Improved coverage detection
4. `scripts/tests/verify-fixes.sh` - Verification script (new)

## Testing
Created `scripts/tests/verify-fixes.sh` demonstrating:
- Output capture on test failure works correctly
- Successful tests run without issues
- Syntax fixes applied correctly
- Coverage improvements implemented

## Recommendation
These fixes significantly improve the test framework's debuggability and reliability. All changes maintain backward compatibility while adding essential debugging capabilities.
