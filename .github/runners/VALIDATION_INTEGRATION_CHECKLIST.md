# Validation Library Integration Checklist

## Overview

This checklist documents how to integrate the validation library (`scripts/lib/validation.sh`) into all scripts to prevent injection attacks and other security vulnerabilities.

## Integration Pattern

For each script in `scripts/*.sh`, follow these steps:

### 1. Source the Validation Library

Add after the common.sh source:

```bash
# Source validation library
# shellcheck source=lib/validation.sh
source "${SCRIPT_DIR}/lib/validation.sh"
```

### 2. Identify Inputs to Validate

Look for:
- **Command-line arguments** (`$1`, `$2`, etc.)
- **Environment variables** (`GITHUB_TOKEN`, `GITHUB_REPOSITORY`, etc.)
- **API responses** (from GitHub API, external services)
- **File paths** (user-provided or constructed)
- **User input** (read statements, form input)

### 3. Apply Appropriate Validation Functions

| Input Type | Validation Function | Example |
|-----------|---------------------|---------|
| Issue/PR number | `validate_issue_number` | `validate_issue_number "$ISSUE_NUMBER"` |
| File path | `validate_file_path` | `validate_file_path "$FILE_PATH" "false"` |
| GitHub token | `validate_github_token` | `validate_github_token "$GITHUB_TOKEN"` |
| URL | `validate_url` | `validate_url "$API_URL"` |
| Branch name | `validate_branch_name` | `validate_branch_name "$BRANCH"` |
| Commit hash | `validate_commit_hash` | `validate_commit_hash "$COMMIT"` |
| Label | `validate_label` | `validate_label "$LABEL"` |
| Env var name | `validate_env_var_name` | `validate_env_var_name "$VAR_NAME"` |
| Docker image | `validate_docker_image` | `validate_docker_image "$IMAGE"` |
| Workflow name | `validate_workflow_name` | `validate_workflow_name "$WORKFLOW"` |
| Unknown input | `sanitize_input` | `safe_input=$(sanitize_input "$input")` |

### 4. Add Validation After Parsing, Before Use

Pattern:

```bash
# Parse arguments
ISSUE_NUMBER="$1"
FILE_PATH="$2"

# Validate inputs (fail fast)
if ! validate_issue_number "$ISSUE_NUMBER" "issue number"; then
    log_error "Invalid issue number: $ISSUE_NUMBER"
    exit 1
fi

if ! validate_file_path "$FILE_PATH" "false" "config file"; then
    log_error "Invalid file path: $FILE_PATH"
    exit 1
fi

# Now safe to use validated inputs
process_issue "$ISSUE_NUMBER" "$FILE_PATH"
```

### 5. Validate Environment Variables

```bash
# Check required environment variables
if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    log_error "GITHUB_TOKEN environment variable is required"
    exit 1
fi

# Validate format
if ! validate_github_token "$GITHUB_TOKEN" "GITHUB_TOKEN"; then
    log_error "GITHUB_TOKEN has invalid format"
    exit 1
fi
```

### 6. Validate API Responses

```bash
# Get data from API
BRANCH_NAME=$(gh api "repos/${REPO}/branches" --jq '.[0].name' 2>/dev/null || echo "")

# Validate before use
if [[ -z "$BRANCH_NAME" ]]; then
    log_error "Failed to get branch name from API"
    exit 1
fi

if ! validate_branch_name "$BRANCH_NAME" "branch from API"; then
    log_error "API returned invalid branch name: $BRANCH_NAME"
    exit 1
fi

# Safe to use
git checkout "$BRANCH_NAME"
```

## Script-by-Script Integration Status

### High Priority (Handle tokens/sensitive data)

- [ ] `scripts/ai-agent.sh` - Validates issue numbers, API responses
- [ ] `scripts/ai-autofix.sh` - Validates issue numbers, file paths, branch names
- [ ] `scripts/ai-review.sh` - Validates PR numbers, commit hashes
- [ ] `scripts/setup-secrets.sh` - Validates tokens, secret names, file paths
- [ ] `scripts/rotate-tokens.sh` - Validates tokens, API responses

### Medium Priority (Handle user input)

- [ ] `scripts/configure-labels.sh` - Validates labels
- [ ] `scripts/sync-runner-groups.sh` - Validates group names, runner names
- [ ] `scripts/quick-deploy.sh` - Validates branch names, environment names
- [ ] `scripts/setup-runner.sh` - Validates runner names, paths, tokens
- [ ] `scripts/test-workflow-locally.sh` - Validates workflow names, paths

### Low Priority (Validation/reporting scripts)

- [ ] `scripts/validate-ai-scripts.sh` - Validates file paths
- [ ] `scripts/validate-security.sh` - Validates configuration
- [ ] `scripts/validate-setup.sh` - Validates environment
- [ ] `scripts/validate-workflow-permissions.sh` - Validates workflow names
- [ ] `scripts/health-check.sh` - Validates URLs, endpoints
- [ ] `scripts/check-secret-leaks.sh` - Validates patterns, file paths
- [ ] `scripts/lint-workflows.sh` - Validates file paths, workflow names
- [ ] `scripts/runner-status-dashboard.sh` - Validates runner IDs
- [ ] `scripts/test-connectivity.sh` - Validates URLs, endpoints

## Common Validation Patterns by Script Type

### Pattern 1: Issue/PR Processing Scripts

```bash
# Required validations:
- Issue/PR number: validate_issue_number
- Comment IDs: validate_issue_number (same format)
- Labels: validate_label
- Branch names (from API): validate_branch_name
- File paths (for artifacts): validate_file_path
```

### Pattern 2: Token Management Scripts

```bash
# Required validations:
- GitHub tokens: validate_github_token
- Secret names: validate_env_var_name
- File paths (for token storage): validate_file_path (absolute allowed)
- Repository names: sanitize_input + custom validation
```

### Pattern 3: Runner Management Scripts

```bash
# Required validations:
- Runner names: sanitize_input (no strict format)
- Group names: sanitize_input
- URLs: validate_url
- Paths: validate_file_path
```

### Pattern 4: Workflow Scripts

```bash
# Required validations:
- Workflow names: validate_workflow_name
- File paths (.github/workflows/): validate_file_path
- Branch names: validate_branch_name
- Docker images: validate_docker_image
```

### Pattern 5: Validation/Testing Scripts

```bash
# Required validations:
- File paths: validate_file_path
- Pattern strings: sanitize_input
- Configuration values: appropriate validator based on type
```

## Testing After Integration

For each updated script:

1. Run the script with valid inputs - should work normally
2. Run with invalid inputs - should fail with validation error
3. Test injection attempts:
   ```bash
   ./script.sh "123; rm -rf /"
   ./script.sh "\$(whoami)"
   ./script.sh "../../../etc/passwd"
   ```
4. Verify validation errors are logged properly
5. Check exit codes (should be non-zero on validation failure)

## Example Integration: ai-agent.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

# Source common utilities and validation
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/validation.sh"

# ... (argument parsing code) ...

# Validate required arguments
if [[ -z "$ISSUE_NUMBER" ]]; then
    log_error "Issue number is required"
    usage
    exit 1
fi

if ! validate_issue_number "$ISSUE_NUMBER" "issue number"; then
    log_error "Invalid issue number: $ISSUE_NUMBER"
    exit 1
fi

if [[ -n "$COMMENT_ID" ]]; then
    if ! validate_issue_number "$COMMENT_ID" "comment ID"; then
        log_error "Invalid comment ID: $COMMENT_ID"
        exit 1
    fi
fi

# Validate environment variables
required_env_vars=(
    "AI_API_KEY"
    "AI_API_ENDPOINT"
    "GITHUB_TOKEN"
    "GITHUB_REPOSITORY"
)

for var in "${required_env_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        log_error "Required environment variable not set: $var"
        exit 1
    fi
done

# Validate GitHub token format
if ! validate_github_token "$GITHUB_TOKEN" "GITHUB_TOKEN"; then
    log_error "GITHUB_TOKEN has invalid format"
    exit 1
fi

# Validate API endpoint URL
if ! validate_url "$AI_API_ENDPOINT" "api.anthropic.com,api.openai.com" "AI API endpoint"; then
    log_error "AI_API_ENDPOINT is not a valid URL: $AI_API_ENDPOINT"
    exit 1
fi

# Validate output file path
if ! validate_file_path "$OUTPUT_FILE" "true" "output file"; then
    log_error "Invalid output file path: $OUTPUT_FILE"
    exit 1
fi

# ... (rest of script - now safe to use validated inputs) ...
```

## Validation Checklist Per Script

For each script, verify:

- [ ] Validation library is sourced
- [ ] All command-line arguments are validated
- [ ] All environment variables are validated
- [ ] All API responses are validated before use
- [ ] All file paths are validated
- [ ] All user input is validated
- [ ] Validation happens before first use of input
- [ ] Validation failures log errors and exit with non-zero code
- [ ] Script has been tested with invalid inputs
- [ ] Script has been tested with injection attempts

## Benefits of Validation

1. **Security**: Prevents command injection, path traversal, SSRF, and other injection attacks
2. **Reliability**: Fails fast on invalid input rather than producing errors later
3. **Debugging**: Clear error messages pinpoint validation failures
4. **Audit Trail**: All validation failures are logged
5. **Compliance**: Helps meet OWASP Top 10 requirements for input validation

## OWASP Compliance

This integration addresses:

- **A03:2021 - Injection**: All inputs validated to prevent injection attacks
- **A05:2021 - Security Misconfiguration**: Secure defaults, input validation
- **A04:2021 - Insecure Design**: Defense in depth, fail securely

## Next Steps

1. ✅ Create validation library (`scripts/lib/validation.sh`)
2. ✅ Create comprehensive test suite (`scripts/test-validation.sh`)
3. ✅ Create usage documentation (`scripts/lib/VALIDATION_USAGE.md`)
4. ⏳ Integrate validation into all scripts (following this checklist)
5. ⏳ Test each script after integration
6. ⏳ Document any script-specific validation requirements
7. ⏳ Add validation to PR review checklist

## Maintenance

- Review validation patterns quarterly
- Update validation functions as new attack vectors are discovered
- Monitor logs for validation failures - may indicate attack attempts
- Keep test suite updated with new edge cases
