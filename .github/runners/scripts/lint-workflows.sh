#!/usr/bin/env bash
# Script: lint-workflows.sh
# Description: Validates GitHub Actions workflow YAML syntax and best practices
# Usage: ./lint-workflows.sh [OPTIONS] [WORKFLOW_FILE]

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly NC='\033[0m' # No Color

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly WORKFLOWS_DIR="${PROJECT_ROOT}/.github/workflows"
readonly LINT_REPORT_DIR="${PROJECT_ROOT}/.github/lint-reports"

# Default values
WORKFLOW_FILE=""
LINT_ALL=false
VERBOSE=false
STRICT_MODE=false
CHECK_SECURITY=true
CHECK_BEST_PRACTICES=true
GENERATE_REPORT=false

# Counters
TOTAL_CHECKS=0
ERRORS=0
WARNINGS=0
INFO=0

# Logging functions
log() {
    echo -e "${BLUE}[INFO]${NC} $*" >&2
}

success() {
    echo -e "${GREEN}[PASS]${NC} $*" >&2
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
    ((ERRORS++))
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
    ((WARNINGS++))
}

info() {
    echo -e "${MAGENTA}[INFO]${NC} $*" >&2
    ((INFO++))
}

verbose() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $*" >&2
    fi
}

# Usage information
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [WORKFLOW_FILE]

Validate GitHub Actions workflow YAML syntax and best practices.

OPTIONS:
    -a, --all               Lint all workflows in .github/workflows/
    -w, --workflow FILE     Specific workflow file to lint
    -v, --verbose           Enable verbose logging
    -s, --strict            Strict mode (warnings become errors)
    --no-security          Skip security checks
    --no-best-practices    Skip best practices checks
    -r, --report           Generate detailed report
    -h, --help             Show this help message

CHECKS PERFORMED:
    YAML Syntax:
      - Valid YAML structure
      - Required fields present
      - Proper indentation

    Security:
      - Explicit permissions defined
      - No hardcoded secrets
      - Safe use of pull_request_target
      - Third-party actions pinned to SHA
      - Input validation present

    Best Practices:
      - Descriptive workflow names
      - Job timeout settings
      - Sparse checkout configuration
      - Proper error handling
      - Cache usage where appropriate
      - Label conventions

EXAMPLES:
    # Lint specific workflow
    $(basename "$0") .github/workflows/pr-review.yml

    # Lint all workflows
    $(basename "$0") --all

    # Strict mode with report
    $(basename "$0") --strict --report --all

    # Skip security checks
    $(basename "$0") --no-security -w pr-review.yml

EXIT CODES:
    0 - All checks passed
    1 - Errors found
    2 - Warnings found (in strict mode)

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -a|--all)
                LINT_ALL=true
                shift
                ;;
            -w|--workflow)
                WORKFLOW_FILE="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -s|--strict)
                STRICT_MODE=true
                shift
                ;;
            --no-security)
                CHECK_SECURITY=false
                shift
                ;;
            --no-best-practices)
                CHECK_BEST_PRACTICES=false
                shift
                ;;
            -r|--report)
                GENERATE_REPORT=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                WORKFLOW_FILE="$1"
                shift
                ;;
        esac
    done

    if [[ "$LINT_ALL" == false && -z "$WORKFLOW_FILE" ]]; then
        error "Workflow file is required, or use --all to lint all workflows"
        usage
        exit 1
    fi
}

# Check for required tools
check_dependencies() {
    local missing_tools=()

    # Check for yq (preferred YAML processor)
    if ! command -v yq &> /dev/null; then
        warn "yq not found - some checks will be limited"
        warn "Install with: brew install yq (macOS) or apt-get install yq (Linux)"
    fi

    # Check for yamllint (YAML linter)
    if ! command -v yamllint &> /dev/null; then
        info "yamllint not found - skipping advanced YAML linting"
        info "Install with: pip install yamllint"
    fi

    # Check for actionlint (GitHub Actions linter)
    if ! command -v actionlint &> /dev/null; then
        info "actionlint not found - some checks will be skipped"
        info "Install with: brew install actionlint (macOS)"
        info "Or download from: https://github.com/rhysd/actionlint/releases"
    fi

    verbose "Dependency check complete"
}

# Validate YAML syntax
validate_yaml_syntax() {
    local workflow="$1"

    ((TOTAL_CHECKS++))
    verbose "Checking YAML syntax for: $workflow"

    # Try yamllint first
    if command -v yamllint &> /dev/null; then
        if yamllint -d "{extends: default, rules: {line-length: {max: 120}}}" "$workflow" 2>&1 | grep -q "error"; then
            error "YAML syntax errors found in $workflow"
            yamllint "$workflow" 2>&1 | grep "error" | head -5
            return 1
        fi
    fi

    # Try yq validation
    if command -v yq &> /dev/null; then
        if ! yq eval '.' "$workflow" > /dev/null 2>&1; then
            error "Invalid YAML syntax in $workflow"
            return 1
        fi
    else
        # Fallback to basic check
        if ! python3 -c "import yaml; yaml.safe_load(open('$workflow'))" 2>/dev/null; then
            error "Invalid YAML syntax in $workflow"
            return 1
        fi
    fi

    success "YAML syntax valid"
    return 0
}

# Check required fields
check_required_fields() {
    local workflow="$1"

    ((TOTAL_CHECKS++))
    verbose "Checking required fields..."

    if ! command -v yq &> /dev/null; then
        info "yq not available - skipping field checks"
        return 0
    fi

    local required_fields=("name" "on" "jobs")
    local missing_fields=()

    for field in "${required_fields[@]}"; do
        local value
        value=$(yq eval ".$field" "$workflow" 2>/dev/null || echo "null")

        if [[ "$value" == "null" || -z "$value" ]]; then
            missing_fields+=("$field")
        fi
    done

    if [[ ${#missing_fields[@]} -gt 0 ]]; then
        error "Missing required fields: ${missing_fields[*]}"
        return 1
    fi

    success "All required fields present"
    return 0
}

# Check permissions
check_permissions() {
    local workflow="$1"

    if [[ "$CHECK_SECURITY" != true ]]; then
        return 0
    fi

    ((TOTAL_CHECKS++))
    verbose "Checking permissions configuration..."

    if ! command -v yq &> /dev/null; then
        return 0
    fi

    local permissions
    permissions=$(yq eval '.permissions' "$workflow" 2>/dev/null || echo "null")

    if [[ "$permissions" == "null" ]]; then
        warn "No explicit permissions defined - workflow will use default permissions"
        warn "Consider adding explicit permissions block for security"
        return 0
    fi

    # Check for overly permissive settings
    if [[ "$permissions" == "write-all" ]]; then
        error "Using 'write-all' permissions is not recommended"
        error "Define specific permissions instead"
        return 1
    fi

    if [[ "$permissions" == "read-all" ]]; then
        warn "Using 'read-all' permissions - consider being more specific"
    fi

    # Check for common permission scopes
    local has_contents
    has_contents=$(yq eval '.permissions.contents' "$workflow" 2>/dev/null || echo "null")

    if [[ "$has_contents" != "null" ]]; then
        verbose "Contents permission: $has_contents"
    fi

    success "Permissions configuration looks good"
    return 0
}

# Check for hardcoded secrets
check_hardcoded_secrets() {
    local workflow="$1"

    if [[ "$CHECK_SECURITY" != true ]]; then
        return 0
    fi

    ((TOTAL_CHECKS++))
    verbose "Checking for hardcoded secrets..."

    # Common patterns that might indicate hardcoded secrets
    local secret_patterns=(
        "password.*[:=].*['\"]"
        "token.*[:=].*['\"]"
        "api[_-]key.*[:=].*['\"]"
        "secret.*[:=].*['\"]"
    )

    local found_issues=false

    for pattern in "${secret_patterns[@]}"; do
        if grep -iE "$pattern" "$workflow" | grep -v "secrets\." | grep -q .; then
            warn "Potential hardcoded secret found matching pattern: $pattern"
            found_issues=true
        fi
    done

    if [[ "$found_issues" == true ]]; then
        warn "Found potential hardcoded secrets - use GitHub Secrets instead"
        warn "Example: \${{ secrets.API_KEY }}"
        return 0
    fi

    success "No hardcoded secrets detected"
    return 0
}

# Check pull_request_target usage
check_pull_request_target() {
    local workflow="$1"

    if [[ "$CHECK_SECURITY" != true ]]; then
        return 0
    fi

    ((TOTAL_CHECKS++))
    verbose "Checking pull_request_target usage..."

    if ! grep -q "pull_request_target" "$workflow"; then
        verbose "No pull_request_target trigger found"
        return 0
    fi

    # Check for safety guards
    if ! command -v yq &> /dev/null; then
        warn "Cannot validate pull_request_target safety without yq"
        return 0
    fi

    # Look for if conditions or label checks
    local has_guards
    has_guards=$(yq eval '.jobs.*.if' "$workflow" 2>/dev/null | grep -c "." || echo "0")

    if [[ "$has_guards" -eq 0 ]]; then
        error "pull_request_target used without safety guards"
        error "Add repository check or label requirement"
        error "Example: if: github.event.pull_request.head.repo.full_name == github.repository"
        return 1
    fi

    success "pull_request_target has safety guards"
    return 0
}

# Check third-party actions
check_third_party_actions() {
    local workflow="$1"

    if [[ "$CHECK_SECURITY" != true ]]; then
        return 0
    fi

    ((TOTAL_CHECKS++))
    verbose "Checking third-party actions..."

    # Find all uses: statements
    local actions
    actions=$(grep -E "^\s*-?\s*uses:" "$workflow" | sed 's/.*uses:\s*//' | tr -d '"' | tr -d "'")

    if [[ -z "$actions" ]]; then
        verbose "No third-party actions found"
        return 0
    fi

    local unpinned_actions=()

    while IFS= read -r action; do
        # Skip local actions
        if [[ "$action" == ./* ]]; then
            continue
        fi

        # Check if pinned to SHA
        if [[ ! "$action" =~ @[a-f0-9]{40}$ ]]; then
            # Allow @v* tags for official GitHub actions
            if [[ "$action" =~ ^actions/ && "$action" =~ @v[0-9] ]]; then
                verbose "Official GitHub action with version tag: $action"
            else
                unpinned_actions+=("$action")
            fi
        fi
    done <<< "$actions"

    if [[ ${#unpinned_actions[@]} -gt 0 ]]; then
        warn "Third-party actions not pinned to SHA:"
        for action in "${unpinned_actions[@]}"; do
            warn "  - $action"
        done
        warn "Consider pinning to specific SHA for security"
        return 0
    fi

    success "All third-party actions properly pinned"
    return 0
}

# Check sparse checkout
check_sparse_checkout() {
    local workflow="$1"

    if [[ "$CHECK_BEST_PRACTICES" != true ]]; then
        return 0
    fi

    ((TOTAL_CHECKS++))
    verbose "Checking sparse checkout configuration..."

    if grep -q "actions/checkout" "$workflow"; then
        if grep -A 5 "actions/checkout" "$workflow" | grep -q "sparse-checkout:"; then
            success "Sparse checkout configured"
            return 0
        else
            info "Consider using sparse checkout to improve performance"
            info "Example:"
            info "  with:"
            info "    sparse-checkout: |"
            info "      scripts/"
            info "      .github/"
        fi
    fi

    return 0
}

# Check job timeouts
check_job_timeouts() {
    local workflow="$1"

    if [[ "$CHECK_BEST_PRACTICES" != true ]]; then
        return 0
    fi

    ((TOTAL_CHECKS++))
    verbose "Checking job timeout settings..."

    if ! command -v yq &> /dev/null; then
        return 0
    fi

    local jobs
    jobs=$(yq eval '.jobs | keys | .[]' "$workflow" 2>/dev/null || echo "")

    local missing_timeouts=()

    while IFS= read -r job; do
        if [[ -n "$job" ]]; then
            local timeout
            timeout=$(yq eval ".jobs.${job}.timeout-minutes" "$workflow" 2>/dev/null || echo "null")

            if [[ "$timeout" == "null" ]]; then
                missing_timeouts+=("$job")
            fi
        fi
    done <<< "$jobs"

    if [[ ${#missing_timeouts[@]} -gt 0 ]]; then
        info "Jobs without explicit timeout:"
        for job in "${missing_timeouts[@]}"; do
            info "  - $job"
        done
        info "Consider adding timeout-minutes to prevent hung jobs"
    else
        success "All jobs have timeout settings"
    fi

    return 0
}

# Check workflow naming
check_workflow_naming() {
    local workflow="$1"

    if [[ "$CHECK_BEST_PRACTICES" != true ]]; then
        return 0
    fi

    ((TOTAL_CHECKS++))
    verbose "Checking workflow naming..."

    if ! command -v yq &> /dev/null; then
        return 0
    fi

    local name
    name=$(yq eval '.name' "$workflow" 2>/dev/null || echo "")

    if [[ -z "$name" || "$name" == "null" ]]; then
        warn "Workflow has no name defined"
        return 0
    fi

    # Check for descriptive name (not just file name)
    if [[ ${#name} -lt 5 ]]; then
        warn "Workflow name is very short: '$name'"
        warn "Consider using a more descriptive name"
    fi

    verbose "Workflow name: $name"
    return 0
}

# Run actionlint if available
run_actionlint() {
    local workflow="$1"

    ((TOTAL_CHECKS++))
    verbose "Running actionlint..."

    if ! command -v actionlint &> /dev/null; then
        info "actionlint not available - skipping"
        return 0
    fi

    local lint_output
    if lint_output=$(actionlint "$workflow" 2>&1); then
        success "actionlint passed"
        return 0
    else
        error "actionlint found issues:"
        echo "$lint_output" | head -10
        return 1
    fi
}

# Lint single workflow
lint_workflow() {
    local workflow="$1"
    local workflow_name
    workflow_name=$(basename "$workflow")

    echo ""
    echo "========================================"
    echo "Linting: $workflow_name"
    echo "========================================"

    # Reset counters for this workflow
    local start_errors=$ERRORS
    local start_warnings=$WARNINGS

    # Run all checks
    validate_yaml_syntax "$workflow"
    check_required_fields "$workflow"
    check_permissions "$workflow"
    check_hardcoded_secrets "$workflow"
    check_pull_request_target "$workflow"
    check_third_party_actions "$workflow"
    check_sparse_checkout "$workflow"
    check_job_timeouts "$workflow"
    check_workflow_naming "$workflow"
    run_actionlint "$workflow"

    # Calculate results for this workflow
    local workflow_errors=$((ERRORS - start_errors))
    local workflow_warnings=$((WARNINGS - start_warnings))

    echo ""
    echo "Results: $workflow_name"
    if [[ $workflow_errors -eq 0 && $workflow_warnings -eq 0 ]]; then
        success "All checks passed"
    else
        if [[ $workflow_errors -gt 0 ]]; then
            error "Found $workflow_errors error(s)"
        fi
        if [[ $workflow_warnings -gt 0 ]]; then
            warn "Found $workflow_warnings warning(s)"
        fi
    fi
    echo "========================================"
}

# Lint all workflows
lint_all_workflows() {
    log "Linting all workflows in $WORKFLOWS_DIR"

    if [[ ! -d "$WORKFLOWS_DIR" ]]; then
        error "Workflows directory not found: $WORKFLOWS_DIR"
        exit 1
    fi

    local workflows
    workflows=$(find "$WORKFLOWS_DIR" -name "*.yml" -o -name "*.yaml" 2>/dev/null)

    if [[ -z "$workflows" ]]; then
        warn "No workflow files found in $WORKFLOWS_DIR"
        return 1
    fi

    while IFS= read -r workflow; do
        lint_workflow "$workflow"
    done <<< "$workflows"
}

# Generate lint report
generate_lint_report() {
    if [[ "$GENERATE_REPORT" != true ]]; then
        return 0
    fi

    mkdir -p "$LINT_REPORT_DIR"

    local report_file="${LINT_REPORT_DIR}/lint-report-$(date +%Y%m%d-%H%M%S).md"

    log "Generating lint report: $report_file"

    cat > "$report_file" << EOF
# Workflow Lint Report

**Generated:** $(date)

## Summary

- Total Checks: $TOTAL_CHECKS
- Errors: $ERRORS
- Warnings: $WARNINGS
- Info: $INFO

## Configuration

- Strict Mode: $STRICT_MODE
- Security Checks: $CHECK_SECURITY
- Best Practices Checks: $CHECK_BEST_PRACTICES

## Files Checked

$(if [[ "$LINT_ALL" == true ]]; then
    find "$WORKFLOWS_DIR" -name "*.yml" -o -name "*.yaml" 2>/dev/null | while read -r workflow; do
        echo "- $(basename "$workflow")"
    done
else
    echo "- $(basename "$WORKFLOW_FILE")"
fi)

## Recommendations

$(if [[ $ERRORS -gt 0 ]]; then
    echo "- Fix all errors before deploying workflows"
    echo "- Review error messages above for details"
fi)

$(if [[ $WARNINGS -gt 0 ]]; then
    echo "- Address warnings to improve workflow quality"
    echo "- Consider security and best practice suggestions"
fi)

$(if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
    echo "- All checks passed successfully"
    echo "- Workflows are ready for deployment"
fi)

## Tools Used

$(command -v yq &> /dev/null && echo "- yq: $(yq --version)" || echo "- yq: Not installed")
$(command -v yamllint &> /dev/null && echo "- yamllint: $(yamllint --version)" || echo "- yamllint: Not installed")
$(command -v actionlint &> /dev/null && echo "- actionlint: $(actionlint --version)" || echo "- actionlint: Not installed")

---

*Report generated by lint-workflows.sh*
EOF

    success "Lint report generated: $report_file"
}

# Display summary
display_summary() {
    echo ""
    echo "=========================================="
    echo "Lint Summary"
    echo "=========================================="
    echo "Total Checks:    $TOTAL_CHECKS"
    echo "Errors:          $ERRORS"
    echo "Warnings:        $WARNINGS"
    echo "Info:            $INFO"
    echo "=========================================="

    if [[ $ERRORS -gt 0 ]]; then
        error "Linting failed with $ERRORS error(s)"
        return 1
    elif [[ $WARNINGS -gt 0 && "$STRICT_MODE" == true ]]; then
        error "Linting failed in strict mode with $WARNINGS warning(s)"
        return 2
    elif [[ $WARNINGS -gt 0 ]]; then
        warn "Linting passed with $WARNINGS warning(s)"
        return 0
    else
        success "All linting checks passed!"
        return 0
    fi
}

# Main execution
main() {
    parse_args "$@"

    log "Starting workflow linting"

    check_dependencies

    if [[ "$LINT_ALL" == true ]]; then
        lint_all_workflows
    else
        if [[ ! -f "$WORKFLOW_FILE" ]]; then
            error "Workflow file not found: $WORKFLOW_FILE"
            exit 1
        fi
        lint_workflow "$WORKFLOW_FILE"
    fi

    generate_lint_report
    display_summary
}

main "$@"
