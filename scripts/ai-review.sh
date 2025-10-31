#!/usr/bin/env bash
set -euo pipefail

# Script: ai-review.sh
# Description: Performs AI-powered code review on pull requests
# Usage: ./ai-review.sh --pr PR_NUMBER [--model MODEL] [--output FILE]

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

# Configuration
readonly DEFAULT_MODEL="${AI_MODEL:-claude-3-5-sonnet-20241022}"
readonly DEFAULT_OUTPUT="review.json"
readonly DEFAULT_MAX_FILES=20
readonly DEFAULT_MAX_RETRIES=3
readonly DEFAULT_RETRY_DELAY=5
readonly DEFAULT_TIMEOUT=120

# Global variables
PR_NUMBER=""
MODEL="${DEFAULT_MODEL}"
OUTPUT_FILE="${DEFAULT_OUTPUT}"
MAX_FILES="${DEFAULT_MAX_FILES}"
VERBOSE="${VERBOSE:-false}"
AUTO_POST="${AUTO_POST:-false}"

# Usage information
usage() {
    cat << EOF
Usage: $(basename "$0") --pr PR_NUMBER [OPTIONS]

Performs AI-powered code review on GitHub pull requests and generates
structured JSON output suitable for GitHub PR review API.

Options:
    --pr NUMBER       Pull request number (required)
    --model MODEL     AI model to use (default: ${DEFAULT_MODEL})
    --output FILE     Output file path (default: ${DEFAULT_OUTPUT})
    --max-files NUM   Maximum files to review (default: ${DEFAULT_MAX_FILES})
    --auto-post       Automatically post review to GitHub (default: false)
    --verbose         Enable verbose logging
    --help            Show this help message

Environment Variables:
    AI_MODEL          Default AI model name
    AI_API_KEY        AI service API key (required)
    AI_API_ENDPOINT   AI service API endpoint (required)
    GITHUB_TOKEN      GitHub API token (required)
    GITHUB_REPOSITORY Repository in format owner/repo

Examples:
    # Basic usage
    ./ai-review.sh --pr 123

    # Use specific model and output file
    ./ai-review.sh --pr 123 --model claude-3-opus --output my-review.json

    # Review and automatically post to GitHub
    ./ai-review.sh --pr 123 --auto-post

Exit Codes:
    0 - Success
    1 - General error
    2 - Invalid arguments
    3 - API error
    4 - Invalid output

EOF
}

# Parse command-line arguments
parse_args() {
    if [[ $# -eq 0 ]]; then
        usage
        exit 2
    fi

    while [[ $# -gt 0 ]]; do
        case $1 in
            --pr)
                if [[ -z "${2:-}" ]]; then
                    error "Missing value for --pr"
                fi
                PR_NUMBER="$2"
                shift 2
                ;;
            --model)
                if [[ -z "${2:-}" ]]; then
                    error "Missing value for --model"
                fi
                MODEL="$2"
                shift 2
                ;;
            --output)
                if [[ -z "${2:-}" ]]; then
                    error "Missing value for --output"
                fi
                OUTPUT_FILE="$2"
                shift 2
                ;;
            --max-files)
                if [[ -z "${2:-}" ]]; then
                    error "Missing value for --max-files"
                fi
                MAX_FILES="$2"
                shift 2
                ;;
            --auto-post)
                AUTO_POST=true
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
    if [[ -z "${PR_NUMBER}" ]]; then
        error "PR number is required. Use --pr NUMBER"
    fi

    if [[ ! "${PR_NUMBER}" =~ ^[0-9]+$ ]]; then
        error "Invalid PR number: ${PR_NUMBER}"
    fi

    if [[ "${MAX_FILES}" -lt 1 ]]; then
        error "Max files must be >= 1"
    fi
}

# Build review prompt
build_review_prompt() {
    local pr_number="$1"
    local pr_metadata="$2"
    local pr_diff="$3"

    local title
    title=$(echo "${pr_metadata}" | jq -r '.title')

    local body
    body=$(echo "${pr_metadata}" | jq -r '.body // ""')

    local additions
    additions=$(echo "${pr_metadata}" | jq -r '.additions')

    local deletions
    deletions=$(echo "${pr_metadata}" | jq -r '.deletions')

    local changed_files
    changed_files=$(echo "${pr_metadata}" | jq -r '.changedFiles')

    cat << EOF
You are an expert code reviewer. Analyze the following pull request and provide a thorough code review.

**Pull Request #${pr_number}**

**Title:** ${title}

**Description:**
${body}

**Statistics:**
- Files changed: ${changed_files}
- Additions: +${additions}
- Deletions: -${deletions}

**Diff:**
\`\`\`diff
${pr_diff}
\`\`\`

**Your Task:**
Provide a comprehensive code review focusing on:
1. Code quality and best practices
2. Potential bugs or security issues
3. Performance concerns
4. Maintainability and readability
5. Test coverage
6. Documentation

**Output Format:**
Provide your review in the following structure:

1. **Overall Assessment:** Brief summary (2-3 sentences)
2. **Strengths:** What's good about this PR
3. **Issues:** List any problems found with severity (CRITICAL, MAJOR, MINOR)
4. **Suggestions:** Recommendations for improvement
5. **Recommendation:** APPROVE, REQUEST_CHANGES, or COMMENT

Be constructive and specific in your feedback. Reference file names and line numbers when possible.
EOF
}

# Parse AI response and format as review JSON
format_review_output() {
    local ai_response="$1"
    local pr_number="$2"
    local model="$3"
    local files_reviewed="$4"

    # Determine review event based on AI response
    local event="COMMENT"
    if echo "${ai_response}" | grep -qi "APPROVE"; then
        event="APPROVE"
    elif echo "${ai_response}" | grep -qi "REQUEST_CHANGES"; then
        event="REQUEST_CHANGES"
    fi

    # Count issues found
    local issues_found=0
    if echo "${ai_response}" | grep -q "CRITICAL"; then
        issues_found=$((issues_found + $(echo "${ai_response}" | grep -c "CRITICAL" || echo 0)))
    fi
    if echo "${ai_response}" | grep -q "MAJOR"; then
        issues_found=$((issues_found + $(echo "${ai_response}" | grep -c "MAJOR" || echo 0)))
    fi

    # Build JSON output
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Escape the AI response for JSON
    local escaped_response
    escaped_response=$(echo "${ai_response}" | jq -Rs .)

    cat << EOF
{
  "event": "${event}",
  "body": ${escaped_response},
  "comments": [],
  "metadata": {
    "model": "${model}",
    "timestamp": "${timestamp}",
    "pr_number": ${pr_number},
    "files_reviewed": ${files_reviewed},
    "issues_found": ${issues_found}
  }
}
EOF
}

# Perform AI-powered review
perform_review() {
    local pr_number="$1"

    log_info "Starting AI review for PR #${pr_number}"
    log_info "Model: ${MODEL}"
    log_info "Max files: ${MAX_FILES}"

    # Fetch PR metadata
    log_info "Fetching PR metadata..."
    local pr_metadata
    if ! pr_metadata=$(get_pr_metadata "${pr_number}"); then
        error "Failed to fetch PR metadata"
    fi

    # Check if PR exists
    local pr_state
    pr_state=$(echo "${pr_metadata}" | jq -r '.state')
    if [[ "${pr_state}" == "null" ]]; then
        error "PR #${pr_number} not found"
    fi

    log_debug "PR state: ${pr_state}"

    # Get PR files
    log_info "Fetching changed files..."
    local changed_files
    if ! changed_files=$(get_pr_files "${pr_number}" "${MAX_FILES}"); then
        error "Failed to fetch PR files"
    fi

    local files_count
    files_count=$(echo "${changed_files}" | wc -l)
    log_info "Found ${files_count} changed files"

    # Get PR diff
    log_info "Fetching PR diff..."
    local pr_diff
    if ! pr_diff=$(get_pr_diff "${pr_number}" "${MAX_FILES}"); then
        error "Failed to fetch PR diff"
    fi

    local diff_size=${#pr_diff}
    log_debug "Diff size: ${diff_size} bytes"

    # Build review prompt
    log_info "Building review prompt..."
    local prompt
    prompt=$(build_review_prompt "${pr_number}" "${pr_metadata}" "${pr_diff}")

    # Call AI API with retry logic
    log_info "Calling AI API..."
    check_rate_limit 1

    local ai_response
    local escaped_prompt
    escaped_prompt=$(echo "${prompt}" | jq -Rs .)

    if ! ai_response=$(retry_with_backoff \
        "${DEFAULT_MAX_RETRIES}" \
        "${DEFAULT_RETRY_DELAY}" \
        call_ai_api "${escaped_prompt}" "${MODEL}"); then
        error "AI API call failed after retries"
    fi

    # Extract response content
    log_debug "Extracting AI response content..."
    local provider="anthropic"
    if [[ "${MODEL}" == gpt-* ]]; then
        provider="openai"
    fi

    local response_text
    response_text=$(extract_ai_response "${ai_response}" "${provider}")

    if [[ -z "${response_text}" ]]; then
        error "Empty response from AI API"
    fi

    log_info "AI response received (${#response_text} characters)"

    # Format output
    log_info "Formatting review output..."
    local review_json
    review_json=$(format_review_output "${response_text}" "${pr_number}" "${MODEL}" "${files_count}")

    # Write output file
    echo "${review_json}" > "${OUTPUT_FILE}"

    log_info "Review saved to: ${OUTPUT_FILE}"
}

# Validate output JSON
validate_output() {
    local output_file="$1"

    log_info "Validating output JSON..."

    if [[ ! -f "${output_file}" ]]; then
        error "Output file not found: ${output_file}"
    fi

    if ! validate_json "${output_file}"; then
        error "Invalid JSON in output file"
    fi

    # Validate required fields
    local required_fields=("event" "body")
    for field in "${required_fields[@]}"; do
        local value
        value=$(jq -r ".${field}" "${output_file}")
        if [[ "${value}" == "null" ]] || [[ -z "${value}" ]]; then
            error "Missing required field: ${field}"
        fi
    done

    # Validate event value
    local event
    event=$(jq -r '.event' "${output_file}")
    if [[ ! "${event}" =~ ^(APPROVE|REQUEST_CHANGES|COMMENT)$ ]]; then
        error "Invalid event value: ${event}"
    fi

    log_info "Output validation passed"
}

# Post review to GitHub
post_review() {
    local pr_number="$1"
    local review_file="$2"

    log_info "Posting review to PR #${pr_number}..."

    if ! post_pr_review "${pr_number}" "${review_file}"; then
        error "Failed to post review"
    fi

    success "Review posted successfully"
}

# Main execution
main() {
    log_info "AI Code Review Script v1.0"

    # Parse arguments
    parse_args "$@"

    # Enable verbose if requested
    if [[ "${VERBOSE}" == "true" ]]; then
        enable_verbose
    fi

    # Validate arguments
    validate_args

    # Check required environment
    check_required_env "GITHUB_TOKEN" "AI_API_KEY" "AI_API_ENDPOINT"
    check_required_commands "gh" "jq" "curl"

    # Validate GitHub CLI authentication
    validate_gh_auth

    # Normalize output path
    OUTPUT_FILE=$(normalize_path "${OUTPUT_FILE}")

    # Perform review
    perform_review "${PR_NUMBER}"

    # Validate output
    validate_output "${OUTPUT_FILE}"

    # Post review if requested
    if [[ "${AUTO_POST}" == "true" ]]; then
        post_review "${PR_NUMBER}" "${OUTPUT_FILE}"
    fi

    success "Review completed successfully"
    log_info "Output: ${OUTPUT_FILE}"

    exit 0
}

# Run main function
main "$@"
