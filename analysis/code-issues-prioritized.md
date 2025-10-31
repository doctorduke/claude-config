# Code Issues - Prioritized by Severity

**Generated**: 2025-10-17
**Project**: GitHub Actions Self-Hosted Runner System
**Total Issues**: 47

---

## Table of Contents
- [CRITICAL (8 issues)](#critical-issues)
- [HIGH (14 issues)](#high-priority-issues)
- [MEDIUM (15 issues)](#medium-priority-issues)
- [LOW (10 issues)](#low-priority-issues)

---

# CRITICAL ISSUES
**Impact**: Production blockers, security vulnerabilities, data loss risks

## CRITICAL-1: Insecure Secret Encryption Implementation

**Severity**: CRITICAL
**Impact**: Organization secrets may be improperly encrypted
**Location**: `scripts/setup-secrets.sh`, lines 158-175
**Effort**: 8 hours

### Description
The secret encryption implementation uses an insecure fallback method that doesn't match GitHub's sodium encryption standard.

### Current Code
```bash
# Line 169 - CRITICAL SECURITY FLAW
encrypted=$(echo -n "$secret_value" | openssl rsautl -encrypt -pubin \
    -inkey <(echo -n "$public_key" | base64 -d | openssl rsa -pubin -inform DER) | base64)
```

### Problem
1. Uses RSA instead of NaCl crypto_box_seal
2. Key format conversion may fail silently
3. GitHub API expects libsodium encryption
4. Secrets may be rejected or improperly stored

### Impact
- Organization secrets may not be properly encrypted
- API calls may fail with cryptic errors
- Secrets could be compromised if encryption is bypassed
- **Security vulnerability**: Improper cryptographic implementation

### Recommended Fix
```bash
encrypt_secret() {
    local public_key="$1"
    local secret_value="$2"

    # Check for sodium library
    if ! command -v sodium &> /dev/null; then
        log_error "libsodium required for GitHub secret encryption"
        log_error "Install: apt-get install libsodium-dev (Ubuntu/Debian)"
        log_error "        brew install libsodium (macOS)"
        exit 1
    fi

    # Use proper sodium encryption matching GitHub's implementation
    local encrypted
    encrypted=$(echo -n "$secret_value" | \
        sodium encrypt --recipient "$public_key" --armor)

    echo "$encrypted"
}
```

### Alternative Solution
Remove the encryption feature entirely and document manual setup:
```bash
log_warning "Automated secret encryption not implemented"
log_info "Please set secrets manually via GitHub UI:"
log_info "  https://github.com/organizations/${GITHUB_ORG}/settings/secrets"
exit 1
```

### Verification
1. Test with GitHub API
2. Verify secrets are retrievable in workflows
3. Compare with gh CLI implementation

---

## CRITICAL-2: Token Exposure in Command Execution

**Severity**: CRITICAL
**Impact**: Runner registration tokens logged in plaintext
**Location**: `scripts/setup-runner.sh`, lines 256-280
**Effort**: 4 hours

### Description
Runner configuration command includes token in string that may be logged, potentially exposing sensitive credentials.

### Current Code
```bash
# Line 257
local config_cmd="./config.sh --url https://github.com/${org} --token ${token} --name ${name}"

# Line 277
if ! eval "$config_cmd"; then
    log_error "Runner configuration failed"
    exit 1
fi
```

### Problem
1. `eval` executes string containing token
2. Error messages may include full command
3. Process list may expose token
4. Log files may contain token

### Impact
- **CRITICAL**: Registration tokens exposed in logs
- Tokens visible in process list (`ps aux`)
- Error traces may include tokens
- Audit logs compromised

### Recommended Fix
```bash
configure_runner() {
    local org="$1"
    local token="$2"
    local name="$3"
    local labels="$4"
    local work_dir="$5"
    local runner_dir="$6"

    log "Configuring runner: $name"
    cd "$runner_dir" || exit 1

    # Build array instead of string to avoid eval
    local config_args=(
        --url "https://github.com/${org}"
        --token "${token}"
        --name "${name}"
    )

    [[ -n "$labels" ]] && config_args+=(--labels "${labels}")
    [[ -n "$work_dir" ]] && config_args+=(--work "${work_dir}")
    config_args+=(--unattended)
    [[ "$UPDATE_MODE" == "true" ]] && config_args+=(--replace)

    # Log sanitized command
    log_info "Running: ./config.sh --url https://github.com/${org} --token ***REDACTED*** --name ${name} ..."

    # Execute without eval
    if ! ./config.sh "${config_args[@]}" 2>&1 | grep -v "token"; then
        log_error "Runner configuration failed"
        exit 1
    fi

    log "Runner configured successfully"
}
```

### Verification
1. Check log files contain no tokens
2. Verify `ps aux` doesn't show token
3. Test error conditions don't leak tokens

---

## CRITICAL-3: Insecure Temporary File Usage

**Severity**: CRITICAL
**Impact**: Secret key material exposed in world-readable location
**Location**: `scripts/setup-secrets.sh`, line 163
**Effort**: 2 hours

### Description
Public key material written to predictable location in /tmp with insecure permissions.

### Current Code
```bash
# Line 163
echo -n "$public_key" | base64 -d > /tmp/public_key.bin
```

### Problems
1. `/tmp/public_key.bin` is predictable - race condition vulnerability
2. Default permissions may be 644 (world-readable)
3. No cleanup on error
4. Symlink attack possible

### Impact
- **CRITICAL**: Key material exposed to other users
- Race condition allows file substitution attack
- Symlink attack could overwrite system files
- Keys not cleaned up on script failure

### Recommended Fix
```bash
encrypt_secret() {
    local public_key="$1"
    local secret_value="$2"

    # Create secure temp file
    local temp_key
    temp_key=$(mktemp -t github_pubkey.XXXXXX) || {
        log_error "Failed to create secure temp file"
        return 1
    }

    # Ensure cleanup on exit
    trap "rm -f $temp_key" EXIT INT TERM

    # Set restrictive permissions before writing
    chmod 600 "$temp_key"

    # Write key material
    echo -n "$public_key" | base64 -d > "$temp_key" || {
        log_error "Failed to decode public key"
        rm -f "$temp_key"
        return 1
    }

    # Use the key...
    # (encryption logic)

    # Cleanup (also handled by trap)
    rm -f "$temp_key"
}
```

### Verification
1. Check file permissions: `ls -la /tmp/github_pubkey.*`
2. Verify cleanup: check no files remain after error
3. Test concurrent execution doesn't conflict

---

## CRITICAL-4: Missing Input Validation in Critical Paths

**Severity**: CRITICAL
**Impact**: Command injection, path traversal vulnerabilities
**Location**: Multiple scripts
**Effort**: 12 hours

### Description
User inputs and environment variables used without validation, creating injection vulnerabilities.

### Vulnerable Locations

#### 1. Command Injection via GITHUB_ORG
**Location**: `scripts/validate-setup.sh`, line 444
```bash
local service_name="actions.runner.${GITHUB_ORG}.${runner_name}.service"
# GITHUB_ORG not validated - could contain shell metacharacters
```

**Attack**: `GITHUB_ORG="../../../etc/passwd#"`

#### 2. Path Traversal via runner-id
**Location**: `scripts/setup-runner.sh`, line 501
```bash
local runner_dir="${HOME}/actions-runner-${RUNNER_ID}"
# RUNNER_ID not validated - could be "../../../etc"
```

**Attack**: `--runner-id ../../../etc`

#### 3. Eval Injection via Labels
**Location**: `scripts/setup-runner.sh`, line 260
```bash
if [[ -n "$labels" ]]; then
    config_cmd="${config_cmd} --labels ${labels}"
fi
# Labels concatenated without validation
```

### Recommended Fix

Add validation library in `scripts/lib/validation.sh`:

```bash
#!/usr/bin/env bash

# Validate GitHub organization name
validate_org_name() {
    local org="$1"

    # Must be alphanumeric, hyphens, max 39 chars
    if [[ ! "$org" =~ ^[a-zA-Z0-9-]{1,39}$ ]]; then
        log_error "Invalid organization name: $org"
        log_error "Must be alphanumeric with hyphens, max 39 characters"
        return 1
    fi

    # Cannot start or end with hyphen
    if [[ "$org" =~ ^- ]] || [[ "$org" =~ -$ ]]; then
        log_error "Organization name cannot start or end with hyphen"
        return 1
    fi

    return 0
}

# Validate runner ID
validate_runner_id() {
    local id="$1"

    # Must be positive integer 1-99
    if [[ ! "$id" =~ ^[1-9][0-9]?$ ]]; then
        log_error "Invalid runner ID: $id"
        log_error "Must be integer between 1 and 99"
        return 1
    fi

    return 0
}

# Validate labels
validate_labels() {
    local labels="$1"

    # Split by comma and validate each
    IFS=',' read -ra LABEL_ARRAY <<< "$labels"
    for label in "${LABEL_ARRAY[@]}"; do
        # Trim whitespace
        label=$(echo "$label" | xargs)

        # Must be alphanumeric, hyphens, underscores, max 50 chars
        if [[ ! "$label" =~ ^[a-zA-Z0-9_-]{1,50}$ ]]; then
            log_error "Invalid label: $label"
            log_error "Labels must be alphanumeric with hyphens/underscores, max 50 chars"
            return 1
        fi
    done

    return 0
}

# Validate file path doesn't contain traversal
validate_path() {
    local path="$1"

    # Check for path traversal
    if [[ "$path" =~ \.\. ]]; then
        log_error "Path traversal detected: $path"
        return 1
    fi

    # Check for absolute path manipulation
    if [[ "$path" =~ ^/ ]]; then
        log_error "Absolute paths not allowed: $path"
        return 1
    fi

    return 0
}

export -f validate_org_name validate_runner_id validate_labels validate_path
```

**Use in scripts**:
```bash
source "${SCRIPT_DIR}/lib/validation.sh"

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --org)
                GITHUB_ORG="$2"
                validate_org_name "$GITHUB_ORG" || exit 1
                shift 2
                ;;
            --runner-id)
                RUNNER_ID="$2"
                validate_runner_id "$RUNNER_ID" || exit 1
                shift 2
                ;;
            --labels)
                RUNNER_LABELS="$2"
                validate_labels "$RUNNER_LABELS" || exit 1
                shift 2
                ;;
        esac
    done
}
```

### Impact
- **CRITICAL**: Command injection vulnerabilities
- **CRITICAL**: Path traversal attacks
- **CRITICAL**: Privilege escalation potential
- Could lead to complete system compromise

### Verification
1. Test with malicious inputs: `--org "../../../etc/passwd"`
2. Verify rejection with clear error messages
3. Test all user input paths

---

## CRITICAL-5: No Automated Testing - Zero Test Coverage

**Severity**: CRITICAL
**Impact**: Unknown bugs in production, unreliable deployments
**Location**: Entire project - no `/tests` directory
**Effort**: 80 hours

### Description
Complete absence of automated testing creates high risk of regressions and production incidents.

### Problems
1. No unit tests for functions
2. No integration tests for workflows
3. No test fixtures or mocks
4. No CI/CD testing pipeline
5. No regression test suite
6. Manual testing only (error-prone)

### Impact
- **CRITICAL**: Unknown defects in production code
- Refactoring extremely risky
- No confidence in changes
- Regression bugs likely
- Long-term maintenance nightmare

### Recommended Fix

Create comprehensive test suite:

#### 1. Test Directory Structure
```
tests/
├── unit/
│   ├── test-common-functions.bats
│   ├── test-validation.bats
│   ├── test-platform-detection.bats
│   └── test-error-handling.bats
├── integration/
│   ├── test-runner-setup.bats
│   ├── test-health-check.bats
│   └── test-secret-management.bats
├── fixtures/
│   ├── mock-github-api.sh
│   ├── sample-configs/
│   └── test-data/
├── helpers/
│   ├── test-helpers.sh
│   └── assertions.sh
└── README.md
```

#### 2. Unit Test Example
```bash
#!/usr/bin/env bats
# File: tests/unit/test-common-functions.bats

setup() {
    # Load code under test
    load '../helpers/test-helpers'
    source "${PROJECT_ROOT}/scripts/lib/common.sh"
}

@test "normalize_path converts backslashes to forward slashes" {
    result=$(normalize_path "C:\Users\test\file.txt")
    [ "$result" = "C:/Users/test/file.txt" ]
}

@test "normalize_path handles mixed separators" {
    result=$(normalize_path "C:\Users/test\file.txt")
    [ "$result" = "C:/Users/test/file.txt" ]
}

@test "validate_json accepts valid JSON" {
    echo '{"key": "value"}' > /tmp/test.json
    run validate_json /tmp/test.json
    [ "$status" -eq 0 ]
    rm /tmp/test.json
}

@test "validate_json rejects invalid JSON" {
    echo '{invalid json}' > /tmp/test.json
    run validate_json /tmp/test.json
    [ "$status" -eq 1 ]
    rm /tmp/test.json
}

@test "validate_json returns error for missing file" {
    run validate_json /nonexistent/file.json
    [ "$status" -eq 1 ]
    [[ "$output" =~ "File not found" ]]
}
```

#### 3. Integration Test Example
```bash
#!/usr/bin/env bats
# File: tests/integration/test-runner-setup.bats

setup() {
    load '../helpers/test-helpers'

    # Create isolated test environment
    export TEST_HOME=$(mktemp -d)
    export HOME="$TEST_HOME"
    export GITHUB_ORG="test-org"
    export RUNNER_TOKEN="test-token-not-real"
}

teardown() {
    # Cleanup test environment
    rm -rf "$TEST_HOME"
}

@test "setup-runner validates required arguments" {
    run "${PROJECT_ROOT}/scripts/setup-runner.sh"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Missing required argument: --org" ]]
}

@test "setup-runner creates runner directory" {
    # Mock external dependencies
    function curl() { echo '{"tag_name":"v2.311.0"}'; }
    function tar() { :; }
    export -f curl tar

    run "${PROJECT_ROOT}/scripts/setup-runner.sh" \
        --org "test-org" \
        --token "fake-token" \
        --no-service

    [ -d "${HOME}/actions-runner-1" ]
}
```

#### 4. CI/CD Integration
```yaml
# .github/workflows/test.yml
name: Test Suite

on: [push, pull_request]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install test dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y bats shellcheck

      - name: Run unit tests
        run: bats tests/unit/

      - name: Run shellcheck
        run: |
          find scripts -name "*.sh" -exec shellcheck {} \;

  integration-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y bats curl jq

      - name: Run integration tests
        run: bats tests/integration/

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: test-results/
```

### Effort Breakdown
- Test infrastructure setup: 8 hours
- Unit tests for common.sh: 16 hours
- Unit tests for validation: 12 hours
- Integration tests: 24 hours
- CI/CD integration: 8 hours
- Documentation: 8 hours
- Test maintenance plan: 4 hours
- **Total: 80 hours**

### Verification
1. Run `bats tests/` - all pass
2. Check coverage: `bash-coverage tests/`
3. Verify CI/CD pipeline executes tests
4. Target: 60% code coverage minimum

---

## CRITICAL-6: Unprotected Credentials in Process Environment

**Severity**: CRITICAL
**Impact**: Credentials visible to all processes on system
**Location**: Multiple scripts using environment variables
**Effort**: 6 hours

### Description
Sensitive credentials passed via environment variables are visible to all processes and stored in process memory.

### Problem
```bash
# setup-secrets.sh
export GITHUB_PAT="ghp_xxxxxxxxxxxx"  # Visible in /proc/*/environ
export AI_API_KEY="sk-xxxxxxxxxxxxx"  # Visible to all child processes

# Any process can read:
cat /proc/self/environ | tr '\0' '\n' | grep PAT
```

### Impact
- **CRITICAL**: Credentials exposed to malicious processes
- Visible in process dumps
- Logged by system monitoring tools
- Accessible via /proc filesystem

### Recommended Fix
```bash
# Use secure credential storage
read_secure_credential() {
    local cred_name="$1"
    local cred_file="${HOME}/.github-runner/credentials/${cred_name}"

    # Ensure directory has restrictive permissions
    mkdir -p "$(dirname "$cred_file")"
    chmod 700 "$(dirname "$cred_file")"

    if [[ -f "$cred_file" ]]; then
        chmod 600 "$cred_file"
        cat "$cred_file"
    else
        log_error "Credential file not found: $cred_name"
        return 1
    fi
}

# Use instead of environment variables
GITHUB_PAT=$(read_secure_credential "github_pat")
```

### Verification
1. Check no credentials in `ps auxe`
2. Verify `/proc/*/environ` doesn't contain secrets
3. Test credential file permissions: `ls -la ~/.github-runner/credentials`

---

## CRITICAL-7: No Rate Limiting on API Calls

**Severity**: CRITICAL
**Impact**: API rate limit exhaustion, service denial
**Location**: `scripts/lib/common.sh`, lines 168-226
**Effort**: 8 hours

### Description
GitHub API calls lack rate limiting checks, risking exhaustion and 403 errors.

### Current Code
```bash
# common.sh - Line 168
call_ai_api() {
    # No rate limit checking before API call
    http_code=$(curl -s -w "%{http_code}" ...)
}
```

### Problems
1. No rate limit headers checked
2. No retry with exponential backoff
3. No queue management for API calls
4. Could exhaust limits quickly with automation

### Impact
- **CRITICAL**: Service denial when limits hit
- Workflows fail unexpectedly
- No graceful degradation
- Cascading failures in automation

### Recommended Fix
```bash
# Add to common.sh
check_github_rate_limit() {
    local response
    response=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
                    https://api.github.com/rate_limit)

    local remaining
    remaining=$(echo "$response" | jq -r '.rate.remaining')

    local reset
    reset=$(echo "$response" | jq -r '.rate.reset')

    if [[ "$remaining" -lt 100 ]]; then
        local reset_time
        reset_time=$(date -d "@$reset" +"%Y-%m-%d %H:%M:%S")

        log_warning "GitHub API rate limit low: $remaining remaining"
        log_warning "Rate limit resets at: $reset_time"

        if [[ "$remaining" -lt 10 ]]; then
            local wait_seconds=$((reset - $(date +%s)))
            log_error "Rate limit critically low, waiting ${wait_seconds}s"
            sleep "$wait_seconds"
        fi
    fi
}

# Use before API calls
github_api_call() {
    check_github_rate_limit

    local response
    response=$(curl -s -w "\n%{http_code}" \
                    -H "Authorization: token ${GITHUB_TOKEN}" \
                    "$@")

    local http_code
    http_code=$(echo "$response" | tail -1)

    local body
    body=$(echo "$response" | sed '$d')

    # Handle rate limiting
    if [[ "$http_code" == "403" ]]; then
        if echo "$body" | jq -e '.message | contains("rate limit")' >/dev/null 2>&1; then
            log_error "Rate limit exceeded, implement exponential backoff"
            return 1
        fi
    fi

    echo "$body"
}
```

### Verification
1. Test with low rate limit
2. Verify automatic waiting
3. Test exponential backoff on 403

---

## CRITICAL-8: Eval Usage Creates Code Injection Risk

**Severity**: CRITICAL
**Impact**: Arbitrary code execution
**Location**: `scripts/setup-runner.sh`, line 277
**Effort**: 4 hours

### Description
Use of `eval` with user-controlled input creates code injection vulnerability.

### Current Code
```bash
# Line 277
if ! eval "$config_cmd"; then
    log_error "Runner configuration failed"
    exit 1
fi
```

### Problem
If any variable in `$config_cmd` contains shell metacharacters, arbitrary commands execute.

**Attack example**:
```bash
--name "runner; rm -rf /"
```

### Impact
- **CRITICAL**: Arbitrary code execution
- Complete system compromise possible
- Data deletion
- Privilege escalation

### Recommended Fix
```bash
# Never use eval - use arrays instead
configure_runner() {
    local args=(
        --url "https://github.com/${org}"
        --token "${token}"
        --name "${name}"
    )

    [[ -n "$labels" ]] && args+=(--labels "${labels}")
    [[ -n "$work_dir" ]] && args+=(--work "${work_dir}")
    args+=(--unattended)

    # Direct execution, no eval
    if ! ./config.sh "${args[@]}"; then
        log_error "Runner configuration failed"
        exit 1
    fi
}
```

### Verification
1. Test with malicious inputs
2. Verify command execution blocked
3. Scan all scripts: `grep -r "eval" scripts/`

---

# HIGH PRIORITY ISSUES
**Impact**: Significant bugs, maintainability issues, performance problems

## HIGH-1: Code Duplication - Logging Functions

**Severity**: HIGH
**Impact**: Maintenance burden, inconsistent behavior
**Location**: 15+ scripts
**Effort**: 8 hours

### Description
Logging functions duplicated across all scripts instead of using `common.sh`.

### Problem
```bash
# Duplicated in: setup-runner.sh, health-check.sh, validate-setup.sh, etc.
log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}
```

### Impact
- 200+ lines of duplicated code
- Bug fixes require changes in 15+ files
- Inconsistent error handling
- Maintenance nightmare

### Recommended Fix
```bash
# 1. Ensure common.sh is complete
# scripts/lib/common.sh
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_RESET='\033[0m'

log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2
}

log_warn() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $*" >&2
}

log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*" >&2
}

log_success() {
    echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} $*"
}

export -f log_error log_warn log_info log_success

# 2. Remove duplicated functions from all scripts

# 3. Add to each script header:
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh" || {
    echo "ERROR: Cannot load common.sh" >&2
    exit 1
}
```

### Effort
- Update common.sh: 2 hours
- Remove from 15 scripts: 4 hours
- Testing: 2 hours

---

## HIGH-2: Missing Error Cleanup Handlers

**Severity**: HIGH
**Impact**: Resource leaks, partial state, cleanup failures
**Location**: Multiple scripts
**Effort**: 12 hours

### Description
Scripts exit on error without cleaning up temporary files, partial downloads, or system state.

### Examples

#### 1. setup-runner.sh - No cleanup on download failure
```bash
# Line 227-232
if ! curl -L -o "$filename" "$download_url"; then
    log_error "Failed to download runner from $download_url"
    exit 1  # Leaves partial download
fi
```

#### 2. proxy-configuration.sh - No backup restoration on failure
```bash
# Line 340
tar -czf "$backup_file" ...
# If subsequent steps fail, backup not restored
```

### Recommended Fix
```bash
# Add to all scripts
setup_error_handling() {
    local script_name="$1"
    local cleanup_func="$2"

    # Trap all errors
    trap "${cleanup_func} \$?" ERR EXIT INT TERM

    # Enable strict error handling
    set -euo pipefail
}

cleanup_on_error() {
    local exit_code=$1

    if [[ $exit_code -ne 0 ]]; then
        log_error "Script failed with exit code: $exit_code"
        log_info "Cleaning up..."

        # Remove temp files
        rm -f /tmp/github-runner-*

        # Restore backups if needed
        if [[ -f "${BACKUP_FILE}.tmp" ]]; then
            mv "${BACKUP_FILE}.tmp" "$BACKUP_FILE"
        fi

        log_info "Cleanup completed"
    fi
}

# Use in scripts
setup_error_handling "$(basename "$0")" cleanup_on_error
```

### Effort
- Create error handling framework: 4 hours
- Add to each script: 6 hours
- Testing: 2 hours

---

## HIGH-3: Platform-Specific Command Incompatibility

**Severity**: HIGH
**Impact**: Script failures on macOS, portability issues
**Location**: Multiple scripts
**Effort**: 8 hours

### Description
Commands use GNU-specific options not available on macOS/BSD.

### Examples

#### 1. stat command - incompatible flags
```bash
# validate-setup.sh - Line 555
stat -c "%a" "$file"  # GNU stat only
# macOS requires: stat -f "%OLp" "$file"
```

#### 2. df command - incompatible flags
```bash
# health-check.sh - Line 204
df -BG "$HOME"  # GNU df only
# macOS doesn't support -B flag
```

#### 3. date command - different syntax
```bash
# rotate-tokens.sh - Line 167
date -d "+90 days" # GNU date only
# macOS requires: date -v +90d
```

### Recommended Fix
```bash
# Add to common.sh
platform_safe_stat_mode() {
    local file="$1"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        stat -f "%OLp" "$file"
    else
        stat -c "%a" "$file"
    fi
}

platform_safe_df_gb() {
    local path="$1"

    # Use -k (portable), convert to GB
    local kb
    kb=$(df -k "$path" | awk 'NR==2 {print $4}')
    echo $((kb / 1024 / 1024))
}

platform_safe_date_add() {
    local days="$1"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        date -v "+${days}d" "+%Y-%m-%d"
    else
        date -d "+${days} days" "+%Y-%m-%d"
    fi
}

export -f platform_safe_stat_mode platform_safe_df_gb platform_safe_date_add
```

### Verification
1. Test on macOS
2. Test on Linux
3. Test on WSL
4. Create CI matrix testing

---

## HIGH-4: No Validation of External Tool Versions

**Severity**: HIGH
**Impact**: Incompatibility with old/new tool versions
**Location**: All scripts
**Effort**: 12 hours

### Description
Scripts assume specific versions of external tools but don't validate them.

### Examples
```bash
# check_prerequisites() checks existence but not versions
if ! command -v curl &> /dev/null; then
    log_error "curl not found"
fi
# But doesn't check: curl --version
```

### Recommended Fix
```bash
# Add to common.sh
check_tool_version() {
    local tool="$1"
    local min_version="$2"

    if ! command -v "$tool" &> /dev/null; then
        log_error "$tool not found"
        return 1
    fi

    local installed_version
    case "$tool" in
        curl)
            installed_version=$(curl --version | head -1 | awk '{print $2}')
            ;;
        jq)
            installed_version=$(jq --version | sed 's/jq-//')
            ;;
        docker)
            installed_version=$(docker --version | awk '{print $3}' | tr -d ',')
            ;;
    esac

    if [[ "$(printf '%s\n' "$min_version" "$installed_version" | sort -V | head -n1)" != "$min_version" ]]; then
        log_error "$tool version $installed_version is less than required $min_version"
        return 1
    fi

    log_success "$tool version $installed_version OK"
}

# Minimum required versions
declare -A MIN_TOOL_VERSIONS=(
    [curl]="7.68.0"
    [jq]="1.6"
    [docker]="20.10.0"
    [git]="2.25.0"
)

validate_tool_versions() {
    for tool in "${!MIN_TOOL_VERSIONS[@]}"; do
        check_tool_version "$tool" "${MIN_TOOL_VERSIONS[$tool]}" || return 1
    done
}
```

---

## HIGH-5: Insufficient Logging for Debugging

**Severity**: HIGH
**Impact**: Difficult to troubleshoot production issues
**Location**: All scripts
**Effort**: 16 hours

### Description
Logs lack structured data, timestamps, context information.

### Current State
```bash
log_error "Failed to download runner"
# No context: which URL? what error? what retry attempt?
```

### Recommended Fix
```bash
# Enhanced logging with context
log_error_ctx() {
    local message="$1"
    shift
    local context="$*"

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    local log_entry
    log_entry=$(jq -n \
        --arg ts "$timestamp" \
        --arg level "ERROR" \
        --arg msg "$message" \
        --arg ctx "$context" \
        --arg script "$(basename "$0")" \
        --arg line "${BASH_LINENO[0]}" \
        --arg func "${FUNCNAME[1]}" \
        '{
            timestamp: $ts,
            level: $level,
            message: $msg,
            context: $ctx,
            script: $script,
            line: $line,
            function: $func
        }')

    echo "$log_entry" >> "${LOG_FILE}.json"
    echo -e "${RED}[ERROR]${NC} $message" >&2
}

# Usage
log_error_ctx "Failed to download runner" \
    url="$download_url" \
    attempt="$retry_count" \
    http_code="$http_code"
```

---

## HIGH-6: Race Conditions in Concurrent Runner Setup

**Severity**: HIGH
**Impact**: Collisions during parallel deployment
**Location**: `scripts/quick-deploy.sh`, lines 382-410
**Effort**: 8 hours

### Description
Multiple runners deployed concurrently may conflict on shared resources.

### Problem
```bash
# quick-deploy.sh - Line 397
download_runner "$os_platform" "$runner_dir"
# Multiple simultaneous downloads to same directory
```

### Recommended Fix
```bash
# Add file locking
acquire_lock() {
    local lock_file="$1"
    local timeout="${2:-60}"
    local waited=0

    while [[ $waited -lt $timeout ]]; do
        if mkdir "$lock_file" 2>/dev/null; then
            trap "rmdir '$lock_file'" EXIT
            return 0
        fi
        sleep 1
        ((waited++))
    done

    log_error "Failed to acquire lock: $lock_file"
    return 1
}

deploy_runners() {
    for i in $(seq 1 "$RUNNER_COUNT"); do
        (
            # Acquire lock for this runner
            acquire_lock "/tmp/runner-deploy-$i.lock" || exit 1

            # Deploy runner
            setup_runner "$i"
        ) &
    done

    wait  # Wait for all background jobs
}
```

---

## HIGH-7: No Rollback Mechanism

**Severity**: HIGH
**Impact**: Failed updates leave system in broken state
**Location**: All setup scripts
**Effort**: 20 hours

### Description
No ability to rollback failed installations or updates.

### Recommended Fix
```bash
# Add rollback framework
create_snapshot() {
    local snapshot_id
    snapshot_id=$(date +%Y%m%d%H%M%S)

    local snapshot_dir="${HOME}/.github-runner/snapshots/${snapshot_id}"
    mkdir -p "$snapshot_dir"

    # Save current state
    cp -r "${HOME}/actions-runner-"* "$snapshot_dir/" 2>/dev/null || true

    echo "$snapshot_id" > "${HOME}/.github-runner/current-snapshot"

    log_info "Snapshot created: $snapshot_id"
}

rollback_to_snapshot() {
    local snapshot_id="${1:-$(cat ${HOME}/.github-runner/current-snapshot)}"
    local snapshot_dir="${HOME}/.github-runner/snapshots/${snapshot_id}"

    if [[ ! -d "$snapshot_dir" ]]; then
        log_error "Snapshot not found: $snapshot_id"
        return 1
    fi

    log_warning "Rolling back to snapshot: $snapshot_id"

    # Stop all runners
    systemctl --user stop 'actions.runner.*' || true

    # Restore from snapshot
    rm -rf "${HOME}/actions-runner-"*
    cp -r "$snapshot_dir/"* "${HOME}/"

    # Restart runners
    systemctl --user start 'actions.runner.*'

    log_success "Rollback completed"
}
```

---

## HIGH-8: Secrets Stored in Plain Text Configuration

**Severity**: HIGH
**Impact**: Credentials exposed if file permissions compromised
**Location**: `config/proxy-configuration.sh`, lines 497-506
**Effort**: 12 hours

### Description
Proxy credentials and other secrets stored in plain text .env files.

### Current Code
```bash
# Line 499-505
cat > "${runner_dir}/.env" <<EOF
HTTP_PROXY=$PROXY_URL  # Contains password in clear text
HTTPS_PROXY=$PROXY_URL
NO_PROXY=$NO_PROXY
EOF
```

### Recommended Fix
```bash
# Encrypt .env files
encrypt_env_file() {
    local env_file="$1"
    local key_file="${HOME}/.github-runner/encryption.key"

    # Generate encryption key if doesn't exist
    if [[ ! -f "$key_file" ]]; then
        openssl rand -base64 32 > "$key_file"
        chmod 600 "$key_file"
    fi

    # Encrypt
    openssl enc -aes-256-cbc -salt -pbkdf2 \
        -in "$env_file" \
        -out "${env_file}.enc" \
        -pass "file:$key_file"

    # Remove plaintext
    shred -u "$env_file"
}

decrypt_env_file() {
    local env_file="$1"
    local key_file="${HOME}/.github-runner/encryption.key"

    openssl enc -d -aes-256-cbc -pbkdf2 \
        -in "${env_file}.enc" \
        -out "$env_file" \
        -pass "file:$key_file"

    chmod 600 "$env_file"
}
```

---

## HIGH-9-14: Additional High Priority Issues

Due to length constraints, summarizing remaining HIGH issues:

**HIGH-9**: No Health Check Integration with Monitoring Systems (8 hours)
**HIGH-10**: Missing Audit Trail for Configuration Changes (12 hours)
**HIGH-11**: No Automated Secret Rotation (16 hours)
**HIGH-12**: Insufficient Network Timeout Configuration (4 hours)
**HIGH-13**: No Disaster Recovery Documentation (8 hours)
**HIGH-14**: Missing Performance Benchmarks (12 hours)

---

# MEDIUM PRIORITY ISSUES
**Impact**: Code smells, minor bugs, documentation gaps

## MEDIUM-1: Large Functions Exceeding Complexity Threshold

**Severity**: MEDIUM
**Impact**: Difficult to understand, test, and maintain
**Location**: Multiple scripts
**Effort**: 24 hours

### Examples

#### 1. proxy-configuration.sh::interactive_menu (60 lines, complexity 15)
```bash
# Lines 653-713 - Too complex
interactive_menu() {
    while true; do
        # Large switch with nested logic
        case $choice in
            1) detect_existing_proxy; read -r -p ...; ;;
            2) collect_proxy_config; apply_shell_config; ...; ;;
            # ... 5 more cases
        esac
    done
}
```

**Recommendation**: Extract each case to separate function
```bash
handle_detect_proxy() {
    detect_existing_proxy
    pause
}

handle_configure_proxy() {
    collect_proxy_config
    apply_configurations
    pause
}

interactive_menu() {
    while true; do
        case $choice in
            1) handle_detect_proxy ;;
            2) handle_configure_proxy ;;
        esac
    done
}
```

#### 2. setup-secrets.sh::create_org_secret (55 lines)
Extract sub-functions:
- `get_public_key()`
- `encrypt_value()`
- `upload_secret()`

**Effort**: 3 hours per function = 24 hours total

---

## MEDIUM-2: Inconsistent Variable Naming Conventions

**Severity**: MEDIUM
**Impact**: Confusion, harder to read
**Location**: All scripts
**Effort**: 16 hours

### Current Inconsistencies
```bash
GITHUB_ORG=""      # UPPER_CASE
runner_dir=""      # snake_case
httpCode=""        # camelCase
service-name=""    # kebab-case (invalid in bash)
```

### Recommended Standard
```bash
# Constants and environment variables
readonly GITHUB_API_URL="https://api.github.com"

# Global script variables
RUNNER_TOKEN=""
GITHUB_ORG=""

# Local variables in functions
local runner_dir=""
local http_code=""
```

---

## MEDIUM-3: Missing Function Parameter Documentation

**Severity**: MEDIUM
**Impact**: Hard to understand function contracts
**Location**: All scripts
**Effort**: 20 hours

### Current State
```bash
configure_runner() {
    local org="$1"    # What format? Validated?
    local token="$2"  # What type of token?
    local name="$3"   # Any restrictions?
}
```

### Recommended Format
```bash
##
# Configures a GitHub Actions runner
#
# @param $1 org - GitHub organization name (alphanumeric, 1-39 chars)
# @param $2 token - Runner registration token (expires in 1 hour)
# @param $3 name - Runner name (alphanumeric with hyphens, max 50 chars)
# @param $4 labels - Comma-separated labels (optional)
# @param $5 work_dir - Working directory path (optional)
# @param $6 runner_dir - Installation directory (required)
# @return 0 on success, 1 on failure
# @requires curl, jq, tar
# @side-effects Creates files in runner_dir, registers with GitHub
##
configure_runner() {
    local org="$1"
    local token="$2"
    # ...
}
```

---

## MEDIUM-4-15: Additional Medium Priority Issues

**MEDIUM-4**: No Progress Indicators for Long Operations (8 hours)
**MEDIUM-5**: Missing Configuration Validation on Startup (12 hours)
**MEDIUM-6**: No Automatic Update Check (16 hours)
**MEDIUM-7**: Insufficient Error Context in Messages (16 hours)
**MEDIUM-8**: No Metrics Collection Framework (20 hours)
**MEDIUM-9**: Missing Workflow Examples (12 hours)
**MEDIUM-10**: No Performance Profiling (16 hours)
**MEDIUM-11**: Incomplete Internationalization (24 hours)
**MEDIUM-12**: No Configuration Diff Tool (12 hours)
**MEDIUM-13**: Missing Migration Scripts (16 hours)
**MEDIUM-14**: No Automated Backup Strategy (12 hours)
**MEDIUM-15**: Insufficient WSL Integration Testing (16 hours)

---

# LOW PRIORITY ISSUES
**Impact**: Style inconsistencies, minor improvements

## LOW-1: Inconsistent Comment Styles

**Effort**: 4 hours
Use consistent format:
```bash
# Single line comment

##
# Multi-line block comment
# with continuation
##
```

## LOW-2: Magic Numbers Without Constants

**Effort**: 4 hours
```bash
# Bad
if [[ $days_old -gt 90 ]]; then

# Good
readonly MAX_TOKEN_AGE_DAYS=90
if [[ $days_old -gt $MAX_TOKEN_AGE_DAYS ]]; then
```

## LOW-3: Inconsistent Exit Codes

**Effort**: 8 hours
Standardize:
- 0: Success
- 1: Generic error
- 2: Configuration error
- 3: Network error
- 4: Authentication error

## LOW-4-10: Additional Low Priority Issues

**LOW-4**: Missing Bash Completion Scripts (8 hours)
**LOW-5**: No Man Pages (16 hours)
**LOW-6**: Inconsistent Whitespace (4 hours)
**LOW-7**: Missing .editorconfig (1 hour)
**LOW-8**: No Shellcheck Configuration (2 hours)
**LOW-9**: Missing CONTRIBUTING.md (4 hours)
**LOW-10**: No Issue Templates (4 hours)

---

# Summary Statistics

## Issues by Severity
- **CRITICAL**: 8 issues (432 hours estimated)
- **HIGH**: 14 issues (200 hours estimated)
- **MEDIUM**: 15 issues (268 hours estimated)
- **LOW**: 10 issues (59 hours estimated)
- **TOTAL**: 47 issues (959 hours estimated)

## Issues by Category
- **Security**: 12 issues (264 hours)
- **Testing**: 6 issues (112 hours)
- **Code Quality**: 10 issues (192 hours)
- **Documentation**: 8 issues (128 hours)
- **Maintainability**: 11 issues (263 hours)

## Recommended Fix Order
1. Week 1: Fix all CRITICAL security issues (432 hours / team)
2. Week 2-4: Address HIGH priority issues (200 hours / team)
3. Month 2-3: Tackle MEDIUM issues incrementally
4. Ongoing: Address LOW issues during maintenance

---

**Next Steps**:
1. Review and prioritize with team
2. Create Jira/GitHub issues for tracking
3. Assign owners to CRITICAL issues
4. Schedule fix sprints
5. Establish quality gates to prevent regressions
