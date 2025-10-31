#!/usr/bin/env bash
set -euo pipefail

# Script: ai-autofix.sh
# Description: Runs linters/formatters and uses AI to fix code issues
# Usage: ./ai-autofix.sh [--pr PR_NUMBER] [--path PATH] [OPTIONS]

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=lib/conflict-detection.sh
source "${SCRIPT_DIR}/lib/conflict-detection.sh"

# Configuration
readonly DEFAULT_MODEL="${AI_MODEL:-claude-3-5-sonnet-20241022}"
readonly DEFAULT_MAX_RETRIES=3
readonly DEFAULT_RETRY_DELAY=5
readonly DEFAULT_MAX_FIXES=10

# Global variables
PR_NUMBER=""
TARGET_PATH="${TARGET_PATH:-.}"
BASE_BRANCH="${BASE_BRANCH:-main}"
MODEL="${DEFAULT_MODEL}"
VERBOSE="${VERBOSE:-false}"
AUTO_COMMIT="${AUTO_COMMIT:-false}"
DRY_RUN="${DRY_RUN:-false}"
MAX_FIXES="${DEFAULT_MAX_FIXES}"
SKIP_CONFLICT_CHECK="${SKIP_CONFLICT_CHECK:-false}"
LINTER_TOOLS=()

# Supported linters/formatters
declare -A LINTER_COMMANDS=(
    ["eslint"]="eslint --fix"
    ["prettier"]="prettier --write"
    ["black"]="black"
    ["pylint"]="pylint"
    ["flake8"]="flake8"
    ["rubocop"]="rubocop -a"
    ["gofmt"]="gofmt -w"
    ["rustfmt"]="rustfmt"
    ["shellcheck"]="shellcheck"
)

# Usage information
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Automatically fixes code issues using linters, formatters, and AI assistance.

Options:
    --pr NUMBER          Pull request number to fix (optional)
    --path PATH          Path to fix (default: current directory)
    --base-branch NAME   Base branch for conflict detection (default: main)
    --tools TOOLS        Comma-separated list of tools to use (default: auto-detect)
    --max-fixes NUM      Maximum number of AI fixes to apply (default: ${DEFAULT_MAX_FIXES})
    --model MODEL        AI model to use (default: ${DEFAULT_MODEL})
    --auto-commit        Automatically commit fixes (default: false)
    --skip-conflict-check Skip merge conflict detection (default: false)
    --dry-run            Show what would be fixed without applying changes
    --verbose            Enable verbose logging
    --help               Show this help message

Environment Variables:
    AI_MODEL             Default AI model name
    AI_API_KEY           AI service API key (required for AI fixes)
    AI_API_ENDPOINT      AI service API endpoint (required for AI fixes)
    GITHUB_TOKEN         GitHub API token (optional)
    TARGET_PATH          Default path to fix
    BASE_BRANCH          Base branch for conflict detection

Supported Tools:
    eslint               JavaScript/TypeScript linter and formatter
    prettier             Code formatter for multiple languages
    black                Python code formatter
    pylint               Python linter
    flake8               Python style checker
    rubocop              Ruby linter and formatter
    gofmt                Go code formatter
    rustfmt              Rust code formatter
    shellcheck           Shell script linter

Examples:
    # Fix all issues in current directory
    ./ai-autofix.sh

    # Fix specific PR (with conflict detection)
    ./ai-autofix.sh --pr 123

    # Fix with custom base branch
    ./ai-autofix.sh --pr 123 --base-branch develop

    # Use specific tools
    ./ai-autofix.sh --tools eslint,prettier --path src/

    # Dry run to see what would be fixed
    ./ai-autofix.sh --dry-run

    # Auto-commit fixes (with conflict check)
    ./ai-autofix.sh --auto-commit

    # Skip conflict detection (force mode)
    ./ai-autofix.sh --pr 123 --skip-conflict-check

Exit Codes:
    0 - Success (fixes applied or no issues found)
    1 - General error
    2 - Invalid arguments
    3 - Linter/formatter error
    4 - AI fix error
    5 - Merge conflicts detected

EOF
}

# Parse command-line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --pr)
                if [[ -z "${2:-}" ]]; then
                    error "Missing value for --pr"
                fi
                PR_NUMBER="$2"
                shift 2
                ;;
            --path)
                if [[ -z "${2:-}" ]]; then
                    error "Missing value for --path"
                fi
                TARGET_PATH="$2"
                shift 2
                ;;
            --base-branch)
                if [[ -z "${2:-}" ]]; then
                    error "Missing value for --base-branch"
                fi
                BASE_BRANCH="$2"
                shift 2
                ;;
            --tools)
                if [[ -z "${2:-}" ]]; then
                    error "Missing value for --tools"
                fi
                IFS=',' read -ra LINTER_TOOLS <<< "$2"
                shift 2
                ;;
            --max-fixes)
                if [[ -z "${2:-}" ]]; then
                    error "Missing value for --max-fixes"
                fi
                MAX_FIXES="$2"
                shift 2
                ;;
            --model)
                if [[ -z "${2:-}" ]]; then
                    error "Missing value for --model"
                fi
                MODEL="$2"
                shift 2
                ;;
            --auto-commit)
                AUTO_COMMIT=true
                shift
                ;;
            --skip-conflict-check)
                SKIP_CONFLICT_CHECK=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                enable_verbose
                shift
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done
}

# Validate arguments
validate_args() {
    if [[ ! -d "${TARGET_PATH}" ]] && [[ ! -f "${TARGET_PATH}" ]]; then
        error "Path not found: ${TARGET_PATH}"
    fi

    if [[ "${MAX_FIXES}" -lt 0 ]]; then
        error "Max fixes must be >= 0"
    fi
}

# Detect available linters
detect_linters() {
    log_info "Detecting available linters..."

    local detected=()
    for tool in "${!LINTER_COMMANDS[@]}"; do
        if command -v "${tool}" &>/dev/null; then
            detected+=("${tool}")
            log_debug "Found: ${tool}"
        fi
    done

    if [[ ${#detected[@]} -eq 0 ]]; then
        log_warn "No linters detected"
    else
        log_info "Available linters: ${detected[*]}"
    fi

    printf '%s\n' "${detected[@]}"
}

# Run linter
run_linter() {
    local tool="$1"
    local path="$2"

    log_info "Running ${tool} on ${path}..."

    local cmd="${LINTER_COMMANDS[$tool]}"
    local output_file
    output_file=$(create_temp_file "linter_${tool}")

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY RUN] Would run: ${cmd} ${path}"
        return 0
    fi

    # Run linter and capture output
    local exit_code=0
    if ! ${cmd} "${path}" > "${output_file}" 2>&1; then
        exit_code=$?
    fi

    # Store output for analysis
    if [[ -s "${output_file}" ]]; then
        cat "${output_file}"
    fi

    rm -f "${output_file}"
    return ${exit_code}
}

# Parse linter output
parse_linter_output() {
    local tool="$1"
    local output="$2"

    log_debug "Parsing ${tool} output..."

    local issues=0

    case "${tool}" in
        eslint)
            issues=$(echo "${output}" | grep -c "error\|warning" || echo 0)
            ;;
        pylint|flake8)
            issues=$(echo "${output}" | grep -c ":" || echo 0)
            ;;
        shellcheck)
            issues=$(echo "${output}" | grep -c "SC[0-9]" || echo 0)
            ;;
        *)
            issues=$(echo "${output}" | wc -l)
            ;;
    esac

    echo "${issues}"
}

# Build AI fix prompt
build_fix_prompt() {
    local file_path="$1"
    local linter_output="$2"
    local file_content="$3"

    cat << EOF
You are an expert code reviewer and fixer. Analyze the following linter output and code, then provide fixes.

**File:** ${file_path}

**Linter Output:**
\`\`\`
${linter_output}
\`\`\`

**Current Code:**
\`\`\`
${file_content}
\`\`\`

**Your Task:**
1. Analyze the linter errors and warnings
2. Provide a fixed version of the code
3. Explain what changes were made and why

**Output Format:**
Provide your response in the following structure:

1. **Summary:** Brief description of issues found
2. **Fixed Code:** Complete fixed version (in code block)
3. **Changes:** List of changes made
4. **Explanation:** Why these fixes are needed

Be precise and only fix the reported issues. Do not make unnecessary changes.
EOF
}

# Apply AI fixes
apply_ai_fixes() {
    local file_path="$1"
    local linter_output="$2"

    log_info "Requesting AI fix for ${file_path}..."

    # Check if AI API is available
    if [[ -z "${AI_API_KEY:-}" ]] || [[ -z "${AI_API_ENDPOINT:-}" ]]; then
        log_warn "AI API not configured, skipping AI fixes"
        return 1
    fi

    # Read file content
    local file_content
    if [[ ! -f "${file_path}" ]]; then
        log_error "File not found: ${file_path}"
        return 1
    fi

    file_content=$(cat "${file_path}")

    # Build fix prompt
    local prompt
    prompt=$(build_fix_prompt "${file_path}" "${linter_output}" "${file_content}")

    # Call AI API
    check_rate_limit 2

    local ai_response
    local escaped_prompt
    escaped_prompt=$(echo "${prompt}" | jq -Rs .)

    if ! ai_response=$(retry_with_backoff \
        "${DEFAULT_MAX_RETRIES}" \
        "${DEFAULT_RETRY_DELAY}" \
        call_ai_api "${escaped_prompt}" "${MODEL}"); then
        log_error "AI API call failed"
        return 1
    fi

    # Extract response
    local provider="anthropic"
    if [[ "${MODEL}" == gpt-* ]]; then
        provider="openai"
    fi

    local response_text
    response_text=$(extract_ai_response "${ai_response}" "${provider}")

    if [[ -z "${response_text}" ]]; then
        log_error "Empty response from AI"
        return 1
    fi

    # Extract fixed code from response (between code fences)
    local fixed_code
    fixed_code=$(echo "${response_text}" | sed -n '/```/,/```/p' | sed '1d;$d')

    if [[ -z "${fixed_code}" ]]; then
        log_warn "No fixed code found in AI response"
        return 1
    fi

    # Apply fixes
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY RUN] Would apply AI fixes to ${file_path}"
        log_debug "Fixed code length: ${#fixed_code} characters"
    else
        log_info "Applying AI fixes to ${file_path}..."
        echo "${fixed_code}" > "${file_path}"
        success "Fixes applied to ${file_path}"
    fi

    return 0
}

# Run all linters and fix issues
run_fixes() {
    local target_path="$1"

    log_info "Starting auto-fix process..."
    log_info "Target: ${target_path}"

    # Detect or use specified linters
    local tools_to_use=()
    if [[ ${#LINTER_TOOLS[@]} -eq 0 ]]; then
        mapfile -t tools_to_use < <(detect_linters)
    else
        tools_to_use=("${LINTER_TOOLS[@]}")
    fi

    if [[ ${#tools_to_use[@]} -eq 0 ]]; then
        log_warn "No linters available or specified"
        return 0
    fi

    local total_fixes=0
    local total_issues=0

    # Run each linter
    for tool in "${tools_to_use[@]}"; do
        log_info "Processing with ${tool}..."

        local linter_output
        linter_output=$(run_linter "${tool}" "${target_path}" 2>&1 || true)

        local issues_count
        issues_count=$(parse_linter_output "${tool}" "${linter_output}")

        total_issues=$((total_issues + issues_count))

        if [[ ${issues_count} -gt 0 ]]; then
            log_info "Found ${issues_count} issues with ${tool}"

            # Apply AI fixes if enabled and below max fixes
            if [[ ${total_fixes} -lt ${MAX_FIXES} ]] && [[ -n "${AI_API_KEY:-}" ]]; then
                # Find affected files
                local affected_files
                if [[ -f "${target_path}" ]]; then
                    affected_files=("${target_path}")
                else
                    # Use awk instead of grep -oP for portability (BSD/macOS compatible)
                    mapfile -t affected_files < <(echo "${linter_output}" | awk -F: '{print $1}' | sort -u | head -n 5)
                fi

                for file in "${affected_files[@]}"; do
                    if [[ ${total_fixes} -ge ${MAX_FIXES} ]]; then
                        break
                    fi

                    if apply_ai_fixes "${file}" "${linter_output}"; then
                        total_fixes=$((total_fixes + 1))
                    fi
                done
            fi
        else
            log_info "No issues found with ${tool}"
        fi
    done

    log_info "Auto-fix complete"
    log_info "Total issues found: ${total_issues}"
    log_info "AI fixes applied: ${total_fixes}"
}

# Commit changes if requested
commit_changes() {
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY RUN] Would commit changes"
        return 0
    fi

    log_info "Checking for changes to commit..."

    # Check if there are changes
    if ! git diff --quiet; then
        log_info "Changes detected, committing..."

        git add -A

        local commit_msg
        commit_msg=$(cat << 'EOF'
fix: Auto-fix code issues

Applied automatic fixes using linters and AI assistance.

Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
EOF
        )

        git commit -m "${commit_msg}"

        success "Changes committed"
    else
        log_info "No changes to commit"
    fi
}

# Main execution
main() {
    log_info "AI Auto-Fix Script v1.1 (with conflict detection)"

    # Parse arguments
    parse_args "$@"

    # Enable verbose if requested
    if [[ "${VERBOSE}" == "true" ]]; then
        enable_verbose
    fi

    # Validate arguments
    validate_args

    # Check required commands (AI API optional)
    check_required_commands "jq"

    # Normalize target path
    TARGET_PATH=$(normalize_path "${TARGET_PATH}")

    # Run conflict detection if PR is specified and not in dry-run
    if [[ -n "${PR_NUMBER}" ]] && [[ "${SKIP_CONFLICT_CHECK}" == "false" ]] && [[ "${DRY_RUN}" == "false" ]]; then
        log_info "Running pre-flight conflict detection for PR #${PR_NUMBER}..."

        # Check if we're in a git repository
        if ! command -v git &>/dev/null || ! git rev-parse --git-dir &>/dev/null 2>&1; then
            log_warn "Not in a git repository, skipping conflict detection"
        else
            # Run conflict detection workflow
            if ! handle_conflict_workflow "${PR_NUMBER}" "${BASE_BRANCH}" "HEAD"; then
                local conflict_status=$?

                if [[ ${conflict_status} -eq 1 ]]; then
                    log_error "Merge conflicts detected. Auto-fix cannot proceed."
                    log_info "Review the PR comment for resolution guidance."
                    exit 5
                elif [[ ${conflict_status} -eq 2 ]]; then
                    log_error "Error during conflict detection."
                    log_error "Cannot proceed with auto-fix due to detection failure."
                    log_info "Use --skip-conflict-check to bypass (not recommended)"
                    exit 5
                else
                    log_error "Unexpected error during conflict detection (status: ${conflict_status})"
                    exit 1
                fi
            else
                log_info "No conflicts detected, proceeding with auto-fix"
            fi
        fi
    elif [[ "${SKIP_CONFLICT_CHECK}" == "true" ]]; then
        log_warn "Skipping conflict detection (--skip-conflict-check enabled)"
    fi

    # Run fixes
    run_fixes "${TARGET_PATH}"

    # Commit if requested
    if [[ "${AUTO_COMMIT}" == "true" ]]; then
        if command -v git &>/dev/null; then
            commit_changes
        else
            log_warn "Git not available, skipping commit"
        fi
    fi

    success "Auto-fix completed successfully"

    exit 0
}

# Run main function
main "$@"
