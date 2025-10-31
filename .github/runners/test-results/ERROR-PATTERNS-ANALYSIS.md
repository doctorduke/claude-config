# Error Patterns Analysis - Wave 4 Testing

**Analysis Date:** 2025-10-17
**Methodology:** Static Code Analysis + Pattern Recognition
**Scope:** All workflows and scripts in github-act project

---

## Error Handling Patterns Found

### Pattern 1: Retry with Exponential Backoff

**Location:** `scripts/lib/common.sh:137-165`

**Pattern:**
```bash
retry_with_backoff() {
    local max_retries="${1}"
    local base_delay="${2}"
    shift 2
    local cmd=("$@")

    local attempt=1
    local delay="${base_delay}"

    while [[ ${attempt} -le ${max_retries} ]]; do
        if "${cmd[@]}"; then
            return 0
        fi

        if [[ ${attempt} -lt ${max_retries} ]]; then
            sleep "${delay}"
            delay=$((delay * 2))  # Exponential backoff
            attempt=$((attempt + 1))
        fi
    done
}
```

**Evaluation:**
- Implements exponential backoff correctly
- Configurable retry count and delay
- Proper exit code propagation
- No context-aware retry (retries all errors)
- No HTTP status code checking

**Usage Count:** 2 (ai-review.sh, ai-autofix.sh via call_ai_api)

---

## Anti-Patterns Found

### Anti-Pattern 1: Retry Everything

**Issue:** Retry logic doesn't distinguish between retryable and non-retryable errors.

**Example:**
```bash
# 403 Forbidden will NEVER succeed on retry, but we retry 3 times
retry_with_backoff 3 5 curl -H "Authorization: Bearer invalid-token" ...
```

**Impact:** Wastes 15-45 seconds on client errors.

**Fix:** Categorize HTTP status codes:
```bash
is_retryable_error() {
    local http_code="$1"
    [[ "$http_code" =~ ^5[0-9][0-9]$ ]] && return 0  # Server errors
    [[ "$http_code" == "429" ]] && return 0           # Rate limit
    [[ "$http_code" == "408" ]] && return 0           # Timeout
    return 1  # Don't retry 4xx client errors
}
```

---

## Error Handling Metrics

### Coverage by Error Type

| Error Type | Detection | Retry | Recovery | Message Quality |
|------------|-----------|-------|----------|-----------------|
| Network timeout | Yes | Yes | Yes | 4/5 stars |
| API 500 error | Yes | Yes | Yes | 4/5 stars |
| API 403 error | Yes | No (should not retry) | Yes | 3/5 stars |
| API 404 error | Yes | No (should not retry) | Yes | 5/5 stars |
| Rate limit 429 | Partial | Yes | Partial (no header parsing) | 3/5 stars |
| Merge conflict | No | N/A | No | 2/5 stars |
| Branch protection | No | N/A | No | 2/5 stars |
| Invalid token | Yes | No (should not retry) | Yes | 3/5 stars |
| Missing dependency | Yes | N/A | Yes | 5/5 stars |
| Invalid JSON | Yes | N/A | Yes | 4/5 stars |

---

## Recommendations for Error Pattern Improvements

### 1. Implement Error Classification System

```bash
# Add to common.sh
readonly ERROR_TYPE_TRANSIENT=1
readonly ERROR_TYPE_PERMANENT=2
readonly ERROR_TYPE_USER_ERROR=3

classify_error() {
    local http_code="$1"
    case "$http_code" in
        5*|408|429) echo "$ERROR_TYPE_TRANSIENT" ;;
        4*) echo "$ERROR_TYPE_PERMANENT" ;;
        *) echo "$ERROR_TYPE_USER_ERROR" ;;
    esac
}
```

### 2. Add Structured Error Context

```bash
# Enhanced error logging
log_error_with_context() {
    local error_msg="$1"
    local file="${2:-unknown}"
    local line="${3:-unknown}"
    local remediation="${4:-Contact support}"

    echo "::error file=$file,line=$line::$error_msg"
    echo "::notice::Remediation: $remediation"
}
```

---

## Conclusion

The current error handling implementation has a **strong foundation** with:
- Good retry logic structure
- Comprehensive pre-flight validation
- Proper cleanup on failure
- Clear error messages in most cases

However, it needs **improvements** in:
- Context-aware retry (don't retry 4xx errors)
- Git-specific error handling (conflicts, branch protection)
- Rate limit awareness (parse API headers)
- Error recovery strategies (automatic remediation)

**Overall Assessment:** 7.5/10 - Good but not production-ready without fixes.

---

**Files Referenced:**
- `scripts/lib/common.sh` - Core error handling library
- `.github/workflows/ai-pr-review.yml` - PR review workflow
- `.github/workflows/ai-autofix.yml` - Auto-fix workflow
- `scripts/ai-review.sh` - AI review script
- `scripts/ai-autofix.sh` - AI auto-fix script
