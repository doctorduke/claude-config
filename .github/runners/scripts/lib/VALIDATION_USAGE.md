# Validation Library Usage Guide

## Overview

The `validation.sh` library provides comprehensive input validation functions to prevent injection attacks including command injection, path traversal, SSRF, and other vulnerabilities.

## Security Principles

1. **Whitelist Approach**: Only allow known-good patterns
2. **Fail Fast**: Return error on any suspicious input
3. **Log All Failures**: All validation failures are logged for audit
4. **No eval**: No use of eval or dynamic command construction
5. **Clear Error Messages**: Provide actionable feedback

## Quick Start

```bash
#!/bin/bash
set -euo pipefail

# Source the validation library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/validation.sh"

# Validate user input
if ! validate_issue_number "$1" "issue number"; then
    echo "Error: Invalid issue number" >&2
    exit 1
fi
```

## Available Validation Functions

### validate_issue_number()
Validates GitHub issue/PR numbers (positive integers, range 1-999999).

```bash
# Usage
validate_issue_number "$issue_num" "issue number"

# Examples
validate_issue_number "123"          # Valid
validate_issue_number "0"            # Invalid (must be >= 1)
validate_issue_number "-5"           # Invalid (negative)
validate_issue_number "1; rm -rf /"  # Invalid (injection attempt)
```

### validate_file_path()
Prevents path traversal attacks. Blocks `..`, absolute paths (unless allowed), and special characters.

```bash
# Usage
validate_file_path "$path" "$allow_absolute" "context"

# Examples
validate_file_path "file.txt"              # Valid (relative)
validate_file_path "../etc/passwd"         # Invalid (path traversal)
validate_file_path "/etc/passwd" "true"    # Valid (absolute allowed)
validate_file_path "/etc/passwd" "false"   # Invalid (absolute not allowed)
validate_file_path "file;ls.txt"           # Invalid (dangerous char)
```

### validate_github_token()
Validates GitHub token format (ghp_, gho_, ghs_, github_pat_).

```bash
# Usage
validate_github_token "$token" "GitHub token"

# Examples
validate_github_token "ghp_abcd1234567890ABCD1234567890ABCD1234"  # Valid (PAT)
validate_github_token "gho_abcd1234567890ABCD1234567890ABCD1234"  # Valid (OAuth)
validate_github_token "invalid_token"                             # Invalid
validate_github_token "$(cat /etc/passwd)"                        # Invalid (injection)
```

### validate_url()
Prevents SSRF attacks. Only allows HTTPS URLs to trusted domains.

```bash
# Usage
validate_url "$url" "$allowed_domains" "context"

# Examples
validate_url "https://github.com/repo"                    # Valid (default)
validate_url "http://github.com"                          # Invalid (must be HTTPS)
validate_url "https://evil.com"                           # Invalid (not whitelisted)
validate_url "https://localhost/admin"                    # Invalid (SSRF attempt)
validate_url "https://example.com" "example.com,test.com" # Valid (custom domain)
```

### validate_branch_name()
Validates Git branch names according to Git rules.

```bash
# Usage
validate_branch_name "$branch" "branch name"

# Examples
validate_branch_name "main"                    # Valid
validate_branch_name "feature/new-feature"     # Valid
validate_branch_name "..invalid"               # Invalid (Git rule)
validate_branch_name "branch.lock"             # Invalid (Git rule)
validate_branch_name "branch;rm -rf /"         # Invalid (injection)
```

### validate_commit_hash()
Validates Git commit hash (7-40 hexadecimal characters).

```bash
# Usage
validate_commit_hash "$hash" "commit hash"

# Examples
validate_commit_hash "abc1234"                                    # Valid (short)
validate_commit_hash "1234567890abcdef1234567890abcdef12345678"  # Valid (full)
validate_commit_hash "ghijkl"                                     # Invalid (not hex)
validate_commit_hash "abc12"                                      # Invalid (too short)
```

### validate_label()
Validates labels (GitHub labels, Docker labels, etc.).

```bash
# Usage
validate_label "$label" "label"

# Examples
validate_label "bug"              # Valid
validate_label "priority:high"    # Valid
validate_label "label;injection"  # Invalid (dangerous char)
```

### sanitize_input()
Removes dangerous characters for safe shell usage.

```bash
# Usage
sanitized=$(sanitize_input "$input" "context")

# Examples
sanitized=$(sanitize_input "user input; rm -rf /")
# Returns: "user input rm -rf /"
# (semicolon removed, dangerous chars filtered)
```

### validate_env_var_name()
Validates environment variable names (POSIX rules).

```bash
# Usage
validate_env_var_name "$name" "env var name"

# Examples
validate_env_var_name "GITHUB_TOKEN"  # Valid
validate_env_var_name "MY_VAR_123"    # Valid
validate_env_var_name "lowercase"     # Invalid (must be uppercase)
validate_env_var_name "123_VAR"       # Invalid (can't start with digit)
```

### validate_docker_image()
Validates Docker image names.

```bash
# Usage
validate_docker_image "$image" "Docker image"

# Examples
validate_docker_image "nginx"                      # Valid
validate_docker_image "nginx:latest"               # Valid
validate_docker_image "registry.io/my/image:v1.0"  # Valid
validate_docker_image "UPPERCASE"                  # Invalid (must be lowercase)
```

### validate_workflow_name()
Validates GitHub Actions workflow/action names.

```bash
# Usage
validate_workflow_name "$name" "workflow name"

# Examples
validate_workflow_name "CI/CD Pipeline"     # Valid
validate_workflow_name "build-and-test"     # Valid
validate_workflow_name "workflow;injection" # Invalid
```

### validate_json_string()
Validates strings intended for use in JSON to prevent JSON injection attacks.

```bash
# Usage
validate_json_string "$string" "context"

# Examples
validate_json_string "safe value"                    # Valid
validate_json_string "value with spaces"             # Valid
validate_json_string 'value with \"escaped quotes\"' # Valid
validate_json_string 'value with "unescaped quotes"' # Invalid (JSON injection risk)
validate_json_string ""                              # Invalid (empty)
```

## Integration Examples

### Example 1: Validate Script Arguments

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/validation.sh"

# Validate required arguments
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <issue_number>" >&2
    exit 1
fi

ISSUE_NUMBER="$1"

# Validate issue number
if ! validate_issue_number "$ISSUE_NUMBER" "issue number"; then
    echo "Error: Invalid issue number: $ISSUE_NUMBER" >&2
    exit 1
fi

# Safe to use $ISSUE_NUMBER now
echo "Processing issue #$ISSUE_NUMBER"
```

### Example 2: Validate Environment Variables

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/validation.sh"

# Validate GitHub token format
if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    echo "Error: GITHUB_TOKEN environment variable is not set" >&2
    exit 1
fi

if ! validate_github_token "$GITHUB_TOKEN" "GITHUB_TOKEN"; then
    echo "Error: GITHUB_TOKEN has invalid format" >&2
    exit 1
fi

# Safe to use $GITHUB_TOKEN now
```

### Example 3: Validate API Responses

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/validation.sh"

# Get branch name from API
BRANCH_NAME=$(curl -s "https://api.github.com/repos/user/repo" | jq -r '.default_branch')

# Validate before using
if ! validate_branch_name "$BRANCH_NAME" "branch name from API"; then
    echo "Error: API returned invalid branch name: $BRANCH_NAME" >&2
    exit 1
fi

# Safe to use $BRANCH_NAME now
git checkout "$BRANCH_NAME"
```

### Example 4: Validate File Paths

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/validation.sh"

CONFIG_FILE="$1"

# Validate file path (relative only)
if ! validate_file_path "$CONFIG_FILE" "false" "config file"; then
    echo "Error: Invalid config file path: $CONFIG_FILE" >&2
    exit 1
fi

# Check file exists (after validation)
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Config file not found: $CONFIG_FILE" >&2
    exit 1
fi

# Safe to read file
source "$CONFIG_FILE"
```

## Best Practices

1. **Validate Early**: Validate all external inputs as soon as they enter your script
2. **Validate Everything**: User args, environment variables, API responses, file contents
3. **Fail Fast**: Exit immediately on validation failure
4. **Use Appropriate Functions**: Choose the most specific validation function for your input type
5. **Provide Context**: Always provide meaningful context in validation calls
6. **Log Failures**: Validation failures are automatically logged - review logs regularly
7. **Never Skip Validation**: Even if you "trust" the source, validate anyway
8. **Combine Validations**: Use multiple validation functions when needed

## Testing Validation

Use the provided test suite to verify validation functions:

```bash
./scripts/test-validation.sh
```

All 146 tests should pass.

## OWASP References

This library helps prevent:

- **A03:2021 - Injection** (OWASP Top 10)
  - Command injection (all functions)
  - Path traversal (validate_file_path)
  - SQL injection (validate_json_string)
  - SSRF (validate_url)

- **A05:2021 - Security Misconfiguration**
  - Input validation (all functions)
  - Secure defaults (whitelist approach)

- **A04:2021 - Insecure Design**
  - Defense in depth (multiple validation layers)
  - Fail securely (fail closed, not open)

## Security Considerations

1. **Regex Limitations**: Some complex injection attacks may still bypass regex validation
2. **Context Matters**: Validation is not a substitute for proper escaping/quoting when using values
3. **Keep Updated**: Review and update validation patterns as new attack vectors are discovered
4. **Monitor Logs**: Watch for repeated validation failures - may indicate attack attempts
5. **Defense in Depth**: Use validation + proper shell quoting + least privilege + sandboxing

## Support

For questions or issues with the validation library:
1. Check the test suite (`test-validation.sh`) for examples
2. Review this documentation
3. Consult the source code comments in `validation.sh`
