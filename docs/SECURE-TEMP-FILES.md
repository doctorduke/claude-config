# Secure Temporary File Handling

## Overview

This document describes the secure patterns for creating and managing temporary files in the GitHub Actions Runner System. All temporary files that may contain sensitive data MUST follow these security guidelines.

## Security Risk

Insecure temporary file handling can lead to:
- **Information Disclosure**: Sensitive data (secrets, API responses, keys) exposed to other users
- **Race Conditions**: Predictable filenames allow attackers to pre-create files
- **Data Persistence**: Temp files not cleaned up after script exit
- **Privilege Escalation**: Insecure permissions allow unauthorized access

## Secure Pattern

### Standard Pattern for Temporary Files

```bash
# Create secure temp file
local temp_file
temp_file=$(mktemp)
chmod 600 "${temp_file}"

# Set up cleanup trap
trap 'rm -f "${temp_file}"' EXIT INT TERM

# Use the temp file
echo "sensitive data" > "${temp_file}"

# Process the file
process_data < "${temp_file}"

# Cleanup (trap will also handle this on exit)
rm -f "${temp_file}"
trap - EXIT INT TERM  # Remove trap after cleanup
```

### For Temp Files with Specific Prefix

```bash
# Create secure temp file with prefix
local temp_file
temp_file=$(mktemp -t "myprefix.XXXXXX")
chmod 600 "${temp_file}"

# Set up cleanup trap
trap 'rm -f "${temp_file}"' EXIT INT TERM

# ... use the file ...

# Cleanup
rm -f "${temp_file}"
trap - EXIT INT TERM
```

### For Persistent Files (Logs, etc.)

```bash
# Create secure log file
if [[ -z "${LOG_FILE:-}" ]]; then
    LOG_FILE=$(mktemp -t "script-name-$(date +%Y%m%d-%H%M%S).XXXXXX.log")
    chmod 600 "${LOG_FILE}"
fi

# Optionally set up trap if file should be cleaned up
# trap 'rm -f "${LOG_FILE}"' EXIT INT TERM
```

### For Secure Directories

```bash
# Create secure temp directory
local secure_dir="${HOME}/.app-name-tmp"
if [[ ! -d "${secure_dir}" ]]; then
    mkdir -p "${secure_dir}"
    chmod 700 "${secure_dir}"
fi

# Create file in secure directory
local secure_file="${secure_dir}/data_file"
echo "sensitive data" > "${secure_file}"
chmod 600 "${secure_file}"
```

## Key Principles

### 1. Always Use mktemp

**DO:**
```bash
temp_file=$(mktemp)
```

**DON'T:**
```bash
temp_file="/tmp/myfile.txt"  # Predictable, insecure
```

### 2. Set Permissions Immediately

**DO:**
```bash
temp_file=$(mktemp)
chmod 600 "${temp_file}"  # Set before writing data
echo "secret" > "${temp_file}"
```

**DON'T:**
```bash
temp_file=$(mktemp)
echo "secret" > "${temp_file}"
chmod 600 "${temp_file}"  # Too late! Data already written with default perms
```

### 3. Always Use Cleanup Traps

**DO:**
```bash
temp_file=$(mktemp)
chmod 600 "${temp_file}"
trap 'rm -f "${temp_file}"' EXIT INT TERM  # Handles all exit scenarios
```

**DON'T:**
```bash
temp_file=$(mktemp)
# ... use file ...
rm -f "${temp_file}"  # Won't clean up if script is interrupted
```

### 4. Quote Variable Names

**DO:**
```bash
rm -f "${temp_file}"
trap 'rm -f "${temp_file}"' EXIT INT TERM
```

**DON'T:**
```bash
rm -f $temp_file  # Breaks with spaces or special characters
trap "rm -f $temp_file" EXIT INT TERM  # Variable expansion happens at trap set time
```

### 5. Use Secure Locations

**DO:**
```bash
# Use mktemp (creates in $TMPDIR or /tmp with secure perms)
temp_file=$(mktemp)

# Or use user-specific directory
secure_dir="${HOME}/.app-tmp"
mkdir -p "${secure_dir}"
chmod 700 "${secure_dir}"
```

**DON'T:**
```bash
# Don't use world-writable directories with predictable names
temp_file="/tmp/myapp_data.txt"
temp_file="/var/tmp/backup_${USER}.sql"
```

## Implementation Examples

### Example 1: API Response (scripts/lib/common.sh)

```bash
call_ai_api() {
    # ... setup code ...

    # Create secure temp file for API response
    local response_file
    response_file=$(mktemp)
    chmod 600 "${response_file}"

    # Set up cleanup trap
    trap 'rm -f "${response_file}"' EXIT INT TERM

    # Make API call
    http_code=$(curl -s -w "%{http_code}" -o "${response_file}" \
        -X POST "${api_endpoint}" \
        -H "Authorization: Bearer ${api_key}" \
        -d "${request_data}")

    # Process response
    cat "${response_file}"

    # Cleanup
    rm -f "${response_file}"
    trap - EXIT INT TERM

    return 0
}
```

### Example 2: Secret Encryption (scripts/setup-secrets.sh)

```bash
encrypt_secret() {
    local public_key="$1"
    local secret_value="$2"

    # Create secure temp file for public key
    local temp_key_file
    temp_key_file=$(mktemp)
    chmod 600 "${temp_key_file}"

    # Set up cleanup trap
    trap 'rm -f "${temp_key_file}"' EXIT INT TERM

    # Decode the base64 public key to secure temp file
    echo -n "$public_key" | base64 -d > "${temp_key_file}"

    # Encrypt using the temp file
    encrypted=$(openssl rsautl -encrypt -pubin -inkey "${temp_key_file}" \
        -in <(echo -n "$secret_value") | base64)

    # Cleanup
    rm -f "${temp_key_file}"
    trap - EXIT INT TERM

    echo "$encrypted"
}
```

### Example 3: Log Files (scripts/quick-deploy.sh)

```bash
# Create secure log file
if [[ -z "${LOG_FILE:-}" ]]; then
    LOG_FILE=$(mktemp -t "quick-deploy-$(date +%Y%m%d-%H%M%S).XXXXXX.log")
    chmod 600 "${LOG_FILE}"
fi

# Use throughout script
echo "Starting deployment..." >> "${LOG_FILE}"
deploy_runner >> "${LOG_FILE}" 2>&1

# Optionally clean up or inform user of location
echo "Logs saved to: ${LOG_FILE}"
```

## Testing

### Verify Temp File Permissions

```bash
# Run security test suite
./tests/test-secure-temp-files.sh

# Manual verification
temp_file=$(mktemp)
chmod 600 "${temp_file}"
ls -la "${temp_file}"  # Should show: -rw------- (600)
stat -c %a "${temp_file}"  # Should output: 600
```

### Audit for Insecure Patterns

```bash
# Find hardcoded /tmp/ paths
grep -r '>/tmp/' scripts/ --include="*.sh"

# Find mktemp without chmod
grep -A2 'mktemp' scripts/ --include="*.sh" | grep -v 'chmod 600'

# Find missing cleanup traps
for f in $(grep -l 'mktemp' scripts/*.sh scripts/lib/*.sh); do
    if ! grep -q 'trap.*rm -f' "$f"; then
        echo "Missing trap in: $f"
    fi
done
```

## Common Pitfalls

### 1. Race Condition Between mktemp and chmod

**ISSUE:**
```bash
temp_file=$(mktemp)  # Created with 600, but...
# Another process could access here if umask is wrong
chmod 600 "${temp_file}"
```

**SOLUTION:**
```bash
# mktemp already creates with 600, but explicitly setting doesn't hurt
temp_file=$(mktemp)
chmod 600 "${temp_file}"  # Defensive: ensure 600 regardless of umask
```

### 2. Trap Conflicts in Nested Functions

**ISSUE:**
```bash
function outer() {
    temp1=$(mktemp)
    trap 'rm -f "${temp1}"' EXIT
    inner  # This overwrites the trap!
}

function inner() {
    temp2=$(mktemp)
    trap 'rm -f "${temp2}"' EXIT  # Overwrites outer trap
}
```

**SOLUTION:**
```bash
# Use separate cleanup for each scope
function outer() {
    local temp1
    temp1=$(mktemp)
    chmod 600 "${temp1}"
    trap 'rm -f "${temp1}"' EXIT INT TERM

    inner

    # Explicit cleanup
    rm -f "${temp1}"
    trap - EXIT INT TERM
}
```

### 3. Forgetting to Clean Up on Error

**ISSUE:**
```bash
temp_file=$(mktemp)
chmod 600 "${temp_file}"
# No trap set
process_data > "${temp_file}" || return 1  # File not cleaned up on error!
```

**SOLUTION:**
```bash
temp_file=$(mktemp)
chmod 600 "${temp_file}"
trap 'rm -f "${temp_file}"' EXIT INT TERM  # Cleans up even on error
process_data > "${temp_file}" || return 1
```

## References

- OWASP: [Insecure Temporary File](https://owasp.org/www-community/vulnerabilities/Insecure_Temporary_File)
- CWE-377: [Insecure Temporary File](https://cwe.mitre.org/data/definitions/377.html)
- CWE-379: [Creation of Temporary File in Directory with Insecure Permissions](https://cwe.mitre.org/data/definitions/379.html)
- POSIX mktemp specification
- Bash trap builtin documentation

## Checklist for Code Review

- [ ] All temp files use `mktemp` (not hardcoded paths)
- [ ] `chmod 600` is set immediately after `mktemp`
- [ ] Cleanup trap is registered: `trap 'rm -f "${temp_file}"' EXIT INT TERM`
- [ ] Trap is removed after manual cleanup: `trap - EXIT INT TERM`
- [ ] Variable names are properly quoted in traps and commands
- [ ] No temp files persist after script exit (verify with tests)
- [ ] Sensitive data is not written before setting permissions
- [ ] Error paths also clean up temp files (trap handles this)

## Compliance

This pattern complies with:
- OWASP Secure Coding Practices
- CIS Benchmark for Linux
- NIST 800-53 SC-4 (Information in Shared Resources)
- PCI-DSS Requirement 3.4 (Render PAN unreadable)
