# Security Advisory: Temp File Vulnerabilities Fixed

## Summary
This commit addresses critical and high severity security vulnerabilities related to temporary file handling in the GitHub Actions automation scripts.

## Vulnerabilities Fixed

### 1. CRITICAL: Unused Secure Temp File (CVE pending)
**Location:** `scripts/setup-secrets.sh:177`
**Severity:** Critical
**Impact:** Public key was being processed insecurely, potentially exposing encrypted secrets
**Fix:** Modified to use the secure temp file created at line 171

### 2. HIGH: Race Condition in File Permissions (CVE pending)
**Location:** `scripts/lib/common.sh:279`
**Severity:** High
**Impact:** Brief window where rate limit file is world-readable before permissions are set
**Fix:** Implemented atomic file creation with restrictive umask (077) and atomic move operation

### 3. HIGH: Unsafe Trap with Unquoted Variable (CVE pending)
**Location:** `scripts/lib/common.sh:320`
**Severity:** High
**Impact:** Variable expansion at trap set time could lead to command injection with crafted filenames
**Fix:** Changed to single-quoted trap with proper variable escaping

## Technical Details

### Race Condition Mitigation
The fix uses a two-step process:
1. Create temp file with umask 077 (ensures 600 permissions from creation)
2. Atomic move to final location (prevents partial writes)

```bash
# Before (vulnerable):
date +%s > "${rate_limit_file}"
chmod 600 "${rate_limit_file}"  # Race condition window

# After (secure):
local temp_rate_file="${rate_limit_file}.$$"
(umask 077 && date +%s > "${temp_rate_file}")
mv -f "${temp_rate_file}" "${rate_limit_file}"
```

### Trap Security Enhancement
The fix ensures variables are evaluated at trap execution time, not set time:

```bash
# Before (vulnerable):
trap "rm -f ${temp_file}" EXIT INT TERM  # Variable expanded immediately

# After (secure):
trap 'rm -f "${temp_file}"' EXIT INT TERM  # Variable expanded at trap time
```

## Testing
Comprehensive security tests have been added to verify:
- Proper file permissions (600 on Unix, 644 on Windows due to FS limitations)
- Atomic file operations
- Proper trap quoting
- Handling of special characters in filenames

## Recommendation
All users should update to this version immediately. These vulnerabilities could potentially allow:
- Information disclosure through world-readable temp files
- Command injection through crafted filenames
- Exposure of encryption keys through improper temp file usage

## Credits
Security audit performed as part of PR #11 (Secure Temp Files) review.

## References
- OWASP: Insecure Temporary Files
- CWE-377: Insecure Temporary File
- CWE-362: Concurrent Execution using Shared Resource with Improper Synchronization (Race Condition)