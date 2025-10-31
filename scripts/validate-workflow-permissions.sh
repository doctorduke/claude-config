#!/usr/bin/env bash
# =============================================================================
# Workflow Permissions Validator
# =============================================================================
# Description: Validates GitHub Actions workflow permission blocks for security
# Author: Security Auditor - Wave 3
# Version: 1.0.0
# OWASP References: A01:2021 - Broken Access Control, A05:2021 - Security Misconfiguration
# =============================================================================

set -euo pipefail

# Configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly VERSION="1.0.0"

# Color codes for output
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_VALIDATION_FAILED=1
readonly EXIT_MISSING_DEPENDENCY=2
readonly EXIT_INVALID_INPUT=3

# Security policy defaults
readonly MAX_PERMISSION_LEVEL="write"
readonly DANGEROUS_PERMISSIONS=("admin" "delete" "write-all" "read-all")
readonly REQUIRED_PERMISSIONS_BLOCK="true"

# Counters for summary
TOTAL_WORKFLOWS=0
PASSED_WORKFLOWS=0
FAILED_WORKFLOWS=0
WARNING_COUNT=0

# =============================================================================
# Helper Functions
# =============================================================================

# Print colored output
print_color() {
    local color="$1"
    shift
    echo -e "${color}$*${NC}" >&2
}

# Print error message
error() {
    print_color "$RED" "ERROR: $*"
}

# Print warning message
warning() {
    print_color "$YELLOW" "WARNING: $*"
    ((WARNING_COUNT++))
}

# Print success message
success() {
    print_color "$GREEN" "SUCCESS: $*"
}

# Print info message
info() {
    print_color "$BLUE" "INFO: $*"
}

# Print usage information
usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS] [WORKFLOW_FILE|DIRECTORY]

Validates GitHub Actions workflow permission blocks for security compliance.

Options:
    -h, --help              Show this help message
    -v, --version           Show version information
    -r, --recursive         Recursively validate workflows in directory
    -s, --strict            Strict mode - fail on any warning
    -o, --output FILE       Output validation report to file
    -p, --policy FILE       Use custom permissions policy file
    -j, --json              Output results in JSON format
    --ci                    CI mode - optimized output for automated checks

Examples:
    # Validate single workflow
    $SCRIPT_NAME .github/workflows/pr-review.yml

    # Validate all workflows in directory
    $SCRIPT_NAME -r .github/workflows/

    # Strict validation with custom policy
    $SCRIPT_NAME -s -p security-policy.yml workflow.yml

    # CI mode with JSON output
    $SCRIPT_NAME --ci -j -o results.json .github/workflows/

Security Checks Performed:
    - Explicit permissions block requirement
    - Minimal scope validation (no admin/delete)
    - Dangerous permission detection
    - Pull request target validation
    - Third-party action permissions
    - Secret exposure risk assessment

Exit Codes:
    0 - All validations passed
    1 - Validation failures detected
    2 - Missing dependencies
    3 - Invalid input

EOF
}

# Check for required dependencies
check_dependencies() {
    local deps=("yq" "jq")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing required dependencies: ${missing[*]}"
        info "Install with: brew install ${missing[*]} (macOS) or apt-get install ${missing[*]} (Linux)"
        exit $EXIT_MISSING_DEPENDENCY
    fi
}

# =============================================================================
# Validation Functions
# =============================================================================

# Validate YAML syntax
validate_yaml_syntax() {
    local file="$1"

    if ! yq eval '.' "$file" > /dev/null 2>&1; then
        error "Invalid YAML syntax in $file"
        return 1
    fi
    return 0
}

# Check for explicit permissions block
check_permissions_block() {
    local file="$1"
    local has_permissions

    has_permissions=$(yq eval '.permissions' "$file" 2>/dev/null)

    if [[ "$has_permissions" == "null" || -z "$has_permissions" ]]; then
        if [[ "$REQUIRED_PERMISSIONS_BLOCK" == "true" ]]; then
            error "$file: No explicit permissions block found"
            return 1
        else
            warning "$file: No explicit permissions block - will inherit default permissions"
            return 0
        fi
    fi

    return 0
}

# Validate permission scopes
validate_permission_scopes() {
    local file="$1"
    local permissions
    local validation_failed=0

    permissions=$(yq eval '.permissions' "$file" 2>/dev/null)

    # Check for dangerous broad permissions
    for dangerous in "${DANGEROUS_PERMISSIONS[@]}"; do
        if [[ "$permissions" == *"$dangerous"* ]]; then
            error "$file: Dangerous permission detected: $dangerous"
            info "  Use specific permissions instead (e.g., contents: read, pull-requests: write)"
            validation_failed=1
        fi
    done

    # Check job-level permissions
    local job_count
    job_count=$(yq eval '.jobs | keys | length' "$file" 2>/dev/null)

    if [[ "$job_count" -gt 0 ]]; then
        for job in $(yq eval '.jobs | keys | .[]' "$file" 2>/dev/null); do
            local job_perms
            job_perms=$(yq eval ".jobs.${job}.permissions" "$file" 2>/dev/null)

            if [[ "$job_perms" != "null" ]]; then
                for dangerous in "${DANGEROUS_PERMISSIONS[@]}"; do
                    if [[ "$job_perms" == *"$dangerous"* ]]; then
                        error "$file: Job '$job' has dangerous permission: $dangerous"
                        validation_failed=1
                    fi
                done
            fi
        done
    fi

    return $validation_failed
}

# Check for pull_request_target usage
check_pull_request_target() {
    local file="$1"
    local uses_pr_target
    local has_guards=0

    uses_pr_target=$(yq eval '.on.pull_request_target' "$file" 2>/dev/null)

    if [[ "$uses_pr_target" != "null" && "$uses_pr_target" != "false" ]]; then
        warning "$file: Uses pull_request_target trigger - requires security review"

        # Check for security guards
        local jobs
        jobs=$(yq eval '.jobs | keys | .[]' "$file" 2>/dev/null)

        for job in $jobs; do
            local condition
            condition=$(yq eval ".jobs.${job}.if" "$file" 2>/dev/null)

            if [[ "$condition" != "null" ]]; then
                # Check for common security patterns
                if [[ "$condition" == *"github.repository"* ]] || \
                   [[ "$condition" == *"safe-to-test"* ]] || \
                   [[ "$condition" == *"trusted"* ]]; then
                    has_guards=1
                    info "$file: Job '$job' has security guard condition"
                fi
            fi
        done

        if [[ $has_guards -eq 0 ]]; then
            error "$file: pull_request_target without security guards detected!"
            info "  Add conditions to check repository ownership or label verification"
            return 1
        fi
    fi

    return 0
}

# Validate third-party actions
check_third_party_actions() {
    local file="$1"
    local unpinned_actions=()

    # Extract all uses statements
    local uses_statements
    uses_statements=$(yq eval '.. | select(has("uses")) | .uses' "$file" 2>/dev/null | sort -u)

    while IFS= read -r action; do
        if [[ -n "$action" && "$action" != "null" ]]; then
            # Skip first-party actions
            if [[ "$action" == actions/* ]] || [[ "$action" == github/* ]]; then
                # Check if pinned to SHA
                if [[ ! "$action" =~ @[a-f0-9]{40}$ ]] && [[ ! "$action" =~ @v[0-9]+ ]]; then
                    warning "$file: Action '$action' should be pinned to specific version or SHA"
                fi
            else
                # Third-party action - must be pinned to SHA
                if [[ ! "$action" =~ @[a-f0-9]{40}$ ]]; then
                    error "$file: Third-party action '$action' must be pinned to SHA"
                    unpinned_actions+=("$action")
                fi
            fi
        fi
    done <<< "$uses_statements"

    if [[ ${#unpinned_actions[@]} -gt 0 ]]; then
        info "  Pin actions to specific SHA for security. Example:"
        info "  uses: third-party/action@8a9b3c... (full SHA)"
        return 1
    fi

    return 0
}

# Check for secret exposure risks
check_secret_exposure() {
    local file="$1"
    local risky_patterns=0

    # Check for echo/print of secrets
    local content
    content=$(cat "$file")

    if echo "$content" | grep -qE 'echo.*\$\{\{.*secrets\..*\}\}'; then
        error "$file: Potential secret exposure via echo detected"
        risky_patterns=1
    fi

    # Check for secrets in artifact uploads
    if echo "$content" | grep -qE 'upload-artifact.*secrets'; then
        warning "$file: Potential secret in artifact upload detected"
        risky_patterns=1
    fi

    # Check for debug mode with secrets
    if echo "$content" | grep -qE 'ACTIONS_STEP_DEBUG.*true' && \
       echo "$content" | grep -qE '\$\{\{.*secrets\..*\}\}'; then
        warning "$file: Debug mode enabled with secrets - risk of exposure"
        risky_patterns=1
    fi

    return $risky_patterns
}

# Generate permission recommendations
generate_recommendations() {
    local file="$1"
    local triggers

    triggers=$(yq eval '.on | keys | .[]' "$file" 2>/dev/null)

    info "Recommended minimal permissions for $file:"

    for trigger in $triggers; do
        case "$trigger" in
            "pull_request"|"pull_request_target")
                info "  contents: read"
                info "  pull-requests: write"
                ;;
            "issues"|"issue_comment")
                info "  issues: write"
                ;;
            "push"|"workflow_dispatch")
                info "  contents: read"
                ;;
            "release")
                info "  contents: write"
                ;;
            *)
                info "  contents: read (default minimal)"
                ;;
        esac
    done
}

# =============================================================================
# Main Validation Function
# =============================================================================

validate_workflow() {
    local file="$1"
    local validation_passed=1

    ((TOTAL_WORKFLOWS++))

    info "Validating: $file"

    # Check YAML syntax
    if ! validate_yaml_syntax "$file"; then
        ((FAILED_WORKFLOWS++))
        return $EXIT_VALIDATION_FAILED
    fi

    # Check for permissions block
    if ! check_permissions_block "$file"; then
        validation_passed=0
    fi

    # Validate permission scopes
    if ! validate_permission_scopes "$file"; then
        validation_passed=0
    fi

    # Check pull_request_target usage
    if ! check_pull_request_target "$file"; then
        validation_passed=0
    fi

    # Check third-party actions
    if ! check_third_party_actions "$file"; then
        validation_passed=0
    fi

    # Check for secret exposure
    if ! check_secret_exposure "$file"; then
        validation_passed=0
    fi

    # Generate recommendations if validation failed
    if [[ $validation_passed -eq 0 ]]; then
        generate_recommendations "$file"
        ((FAILED_WORKFLOWS++))
        return $EXIT_VALIDATION_FAILED
    else
        success "$file: All security checks passed"
        ((PASSED_WORKFLOWS++))
        return $EXIT_SUCCESS
    fi
}

# =============================================================================
# Output Functions
# =============================================================================

# Generate JSON report
generate_json_report() {
    local output_file="$1"

    cat > "$output_file" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "version": "$VERSION",
  "summary": {
    "total_workflows": $TOTAL_WORKFLOWS,
    "passed": $PASSED_WORKFLOWS,
    "failed": $FAILED_WORKFLOWS,
    "warnings": $WARNING_COUNT
  },
  "status": $([ $FAILED_WORKFLOWS -eq 0 ] && echo '"passed"' || echo '"failed"'),
  "exit_code": $([ $FAILED_WORKFLOWS -eq 0 ] && echo 0 || echo 1)
}
EOF
}

# Print summary
print_summary() {
    echo ""
    info "========================================="
    info "Validation Summary"
    info "========================================="
    info "Total workflows scanned: $TOTAL_WORKFLOWS"
    success "Passed: $PASSED_WORKFLOWS"
    if [[ $FAILED_WORKFLOWS -gt 0 ]]; then
        error "Failed: $FAILED_WORKFLOWS"
    fi
    if [[ $WARNING_COUNT -gt 0 ]]; then
        warning "Warnings: $WARNING_COUNT"
    fi
    info "========================================="
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    local recursive=false
    local strict_mode=false
    local output_file=""
    local policy_file=""
    local json_output=false
    local ci_mode=false
    local target=""

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit $EXIT_SUCCESS
                ;;
            -v|--version)
                echo "$SCRIPT_NAME version $VERSION"
                exit $EXIT_SUCCESS
                ;;
            -r|--recursive)
                recursive=true
                shift
                ;;
            -s|--strict)
                strict_mode=true
                shift
                ;;
            -o|--output)
                output_file="$2"
                shift 2
                ;;
            -p|--policy)
                policy_file="$2"
                shift 2
                ;;
            -j|--json)
                json_output=true
                shift
                ;;
            --ci)
                ci_mode=true
                shift
                ;;
            -*)
                error "Unknown option: $1"
                usage
                exit $EXIT_INVALID_INPUT
                ;;
            *)
                target="$1"
                shift
                ;;
        esac
    done

    # Check dependencies
    check_dependencies

    # Default target if not specified
    if [[ -z "$target" ]]; then
        target=".github/workflows"
    fi

    # Validate target exists
    if [[ ! -e "$target" ]]; then
        error "Target not found: $target"
        exit $EXIT_INVALID_INPUT
    fi

    # Process workflows
    if [[ -f "$target" ]]; then
        # Single file validation
        validate_workflow "$target" || true
    elif [[ -d "$target" ]]; then
        # Directory validation
        if [[ "$recursive" == "true" ]]; then
            while IFS= read -r -d '' workflow; do
                validate_workflow "$workflow" || true
            done < <(find "$target" -name "*.yml" -o -name "*.yaml" -print0 2>/dev/null)
        else
            for workflow in "$target"/*.yml "$target"/*.yaml; do
                [[ -f "$workflow" ]] && validate_workflow "$workflow" || true
            done
        fi
    fi

    # Generate output
    if [[ "$json_output" == "true" ]] && [[ -n "$output_file" ]]; then
        generate_json_report "$output_file"
        success "JSON report saved to: $output_file"
    fi

    # Print summary unless in CI mode with JSON
    if [[ "$ci_mode" != "true" ]] || [[ "$json_output" != "true" ]]; then
        print_summary
    fi

    # Exit code based on results
    if [[ $FAILED_WORKFLOWS -gt 0 ]]; then
        exit $EXIT_VALIDATION_FAILED
    elif [[ "$strict_mode" == "true" ]] && [[ $WARNING_COUNT -gt 0 ]]; then
        error "Strict mode: Warnings treated as failures"
        exit $EXIT_VALIDATION_FAILED
    else
        exit $EXIT_SUCCESS
    fi
}

# Run main function with all arguments
main "$@"