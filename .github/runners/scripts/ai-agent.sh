#!/usr/bin/env bash
set -euo pipefail

# Script: ai-agent.sh
# Description: General AI agent for processing issue comments and generating responses
# Usage: ./ai-agent.sh --issue ISSUE_NUMBER --comment COMMENT_ID [OPTIONS]

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

# Configuration
readonly DEFAULT_MODEL="${AI_MODEL:-claude-3-5-sonnet-20241022}"
readonly DEFAULT_OUTPUT="response.json"
readonly DEFAULT_MAX_RETRIES=3
readonly DEFAULT_RETRY_DELAY=5
readonly DEFAULT_CONTEXT_LINES=50

# Global variables
ISSUE_NUMBER=""
COMMENT_ID=""
MODEL="${DEFAULT_MODEL}"
OUTPUT_FILE="${DEFAULT_OUTPUT}"
VERBOSE="${VERBOSE:-false}"
AUTO_POST="${AUTO_POST:-false}"
TASK_TYPE="general"

# Usage information
usage() {
    cat << EOF
Usage: $(basename "$0") --issue ISSUE_NUMBER [OPTIONS]

Processes GitHub issue comments and generates AI-powered responses.

Options:
    --issue NUMBER      Issue or PR number (required)
    --comment ID        Specific comment ID to respond to (optional)
    --task TYPE         Task type: general, summarize, analyze, suggest (default: general)
    --model MODEL       AI model to use (default: ${DEFAULT_MODEL})
    --output FILE       Output file path (default: ${DEFAULT_OUTPUT})
    --auto-post         Automatically post response to GitHub (default: false)
    --verbose           Enable verbose logging
    --help              Show this help message

Environment Variables:
    AI_MODEL            Default AI model name
    AI_API_KEY          AI service API key (required)
    AI_API_ENDPOINT     AI service API endpoint (required)
    GITHUB_TOKEN        GitHub API token (required)
    GITHUB_REPOSITORY   Repository in format owner/repo

Task Types:
    general             General Q&A and assistance
    summarize           Summarize issue discussion
    analyze             Analyze issue for root cause
    suggest             Suggest solutions or next steps

Examples:
    # Respond to the latest issue comment
    ./ai-agent.sh --issue 123

    # Respond to a specific comment
    ./ai-agent.sh --issue 123 --comment 456789

    # Summarize issue discussion
    ./ai-agent.sh --issue 123 --task summarize --auto-post

    # Analyze issue and suggest solutions
    ./ai-agent.sh --issue 123 --task suggest

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
            --issue)
                if [[ -z "${2:-}" ]]; then
                    error "Missing value for --issue"
                fi
                ISSUE_NUMBER="$2"
                shift 2
                ;;
            --comment)
                if [[ -z "${2:-}" ]]; then
                    error "Missing value for --comment"
                fi
                COMMENT_ID="$2"
                shift 2
                ;;
            --task)
                if [[ -z "${2:-}" ]]; then
                    error "Missing value for --task"
                fi
                TASK_TYPE="$2"
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
    if [[ -z "${ISSUE_NUMBER}" ]]; then
        error "Issue number is required. Use --issue NUMBER"
    fi

    if [[ ! "${ISSUE_NUMBER}" =~ ^[0-9]+$ ]]; then
        error "Invalid issue number: ${ISSUE_NUMBER}"
    fi

    if [[ ! "${TASK_TYPE}" =~ ^(general|summarize|analyze|suggest)$ ]]; then
        error "Invalid task type: ${TASK_TYPE}"
    fi
}

# Get issue details
get_issue_details() {
    local issue_number="$1"

    log_debug "Fetching issue #${issue_number} details"

    gh issue view "${issue_number}" --json \
        number,title,body,author,state,labels,comments,createdAt,updatedAt
}

# Get specific comment
get_comment_details() {
    local issue_number="$1"
    local comment_id="$2"

    log_debug "Fetching comment #${comment_id}"

    # Get all comments and filter by ID
    gh issue view "${issue_number}" --json comments \
        | jq ".comments[] | select(.id == ${comment_id})"
}

# Get recent comments
get_recent_comments() {
    local issue_number="$1"
    local limit="${2:-5}"

    log_debug "Fetching recent comments (limit: ${limit})"

    gh issue view "${issue_number}" --json comments \
        | jq ".comments[-${limit}:]"
}

# Build task-specific prompt
build_agent_prompt() {
    local task_type="$1"
    local issue_data="$2"
    local comment_data="${3:-}"

    local title
    title=$(echo "${issue_data}" | jq -r '.title')

    local body
    body=$(echo "${issue_data}" | jq -r '.body // ""')

    local state
    state=$(echo "${issue_data}" | jq -r '.state')

    local labels
    labels=$(echo "${issue_data}" | jq -r '.labels[].name' | tr '\n' ', ' | sed 's/,$//')

    # Build base context
    local base_context
    base_context=$(cat << EOF
**Issue #${ISSUE_NUMBER}**

**Title:** ${title}

**State:** ${state}

**Labels:** ${labels}

**Description:**
${body}
EOF
    )

    # Add recent comments for context
    local comments
    comments=$(get_recent_comments "${ISSUE_NUMBER}" 5)
    local comments_text
    comments_text=$(echo "${comments}" | jq -r '.[] | "**\(.author.login)** (\(.createdAt)):\n\(.body)\n"')

    if [[ -n "${comments_text}" ]]; then
        base_context="${base_context}

**Recent Comments:**
${comments_text}"
    fi

    # Add specific comment if provided
    if [[ -n "${comment_data}" ]]; then
        local comment_author
        comment_author=$(echo "${comment_data}" | jq -r '.author.login')

        local comment_body
        comment_body=$(echo "${comment_data}" | jq -r '.body')

        base_context="${base_context}

**Comment to Respond To:**
**${comment_author}** wrote:
${comment_body}"
    fi

    # Build task-specific prompt
    local task_prompt=""
    case "${task_type}" in
        general)
            task_prompt="Provide a helpful response to this issue or comment. Be constructive and specific."
            ;;
        summarize)
            task_prompt="Provide a concise summary of this issue discussion, highlighting:
1. The main problem or request
2. Key points from the discussion
3. Current status and next steps
4. Any decisions or conclusions reached"
            ;;
        analyze)
            task_prompt="Analyze this issue to identify:
1. Root cause or underlying problem
2. Impact and severity
3. Related issues or dependencies
4. Technical considerations
5. Risk assessment"
            ;;
        suggest)
            task_prompt="Suggest solutions or next steps for this issue:
1. Possible approaches to solve the problem
2. Pros and cons of each approach
3. Recommended solution with rationale
4. Implementation considerations
5. Testing strategy"
            ;;
    esac

    cat << EOF
You are an expert software development assistant. Analyze the following GitHub issue and provide a helpful response.

${base_context}

**Your Task:**
${task_prompt}

**Guidelines:**
- Be concise but thorough
- Use Markdown formatting
- Reference specific details from the issue
- Provide actionable recommendations
- Be constructive and professional

Provide your response in clear Markdown format.
EOF
}

# Format response output
format_response_output() {
    local ai_response="$1"
    local issue_number="$2"
    local model="$3"
    local task_type="$4"

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Escape the AI response for JSON
    local escaped_response
    escaped_response=$(echo "${ai_response}" | jq -Rs .)

    # Build suggested labels based on task type
    local suggested_labels="[]"
    if [[ "${task_type}" == "analyze" ]]; then
        suggested_labels='["analyzed"]'
    elif [[ "${task_type}" == "summarize" ]]; then
        suggested_labels='["needs-review"]'
    fi

    # Build JSON output with nested response object
    cat << EOF
{
  "response": {
    "body": ${escaped_response},
    "type": "comment",
    "suggested_labels": ${suggested_labels}
  },
  "metadata": {
    "model": "${model}",
    "timestamp": "${timestamp}",
    "issue_number": ${issue_number},
    "task_type": "${task_type}",
    "confidence": 0.85
  }
}
EOF
}

# Process issue comment
process_issue() {
    local issue_number="$1"

    log_info "Processing issue #${issue_number}"
    log_info "Task type: ${TASK_TYPE}"
    log_info "Model: ${MODEL}"

    # Fetch issue details
    log_info "Fetching issue details..."
    local issue_data
    if ! issue_data=$(get_issue_details "${issue_number}"); then
        error "Failed to fetch issue details"
    fi

    # Check if issue exists
    local issue_state
    issue_state=$(echo "${issue_data}" | jq -r '.state')
    if [[ "${issue_state}" == "null" ]]; then
        error "Issue #${issue_number} not found"
    fi

    log_debug "Issue state: ${issue_state}"

    # Get specific comment if requested
    local comment_data=""
    if [[ -n "${COMMENT_ID}" ]]; then
        log_info "Fetching specific comment #${COMMENT_ID}..."
        if ! comment_data=$(get_comment_details "${issue_number}" "${COMMENT_ID}"); then
            error "Failed to fetch comment"
        fi
    fi

    # Build prompt
    log_info "Building prompt..."
    local prompt
    prompt=$(build_agent_prompt "${TASK_TYPE}" "${issue_data}" "${comment_data}")

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
    log_info "Formatting response output..."
    local response_json
    response_json=$(format_response_output "${response_text}" "${issue_number}" "${MODEL}" "${TASK_TYPE}")

    # Write output file
    echo "${response_json}" > "${OUTPUT_FILE}"

    log_info "Response saved to: ${OUTPUT_FILE}"
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
    local response
    response=$(jq -r '.response' "${output_file}")
    if [[ "${response}" == "null" ]] || [[ -z "${response}" ]]; then
        error "Missing required field: response"
    fi

    log_info "Output validation passed"
}

# Post response to GitHub
post_response() {
    local issue_number="$1"
    local response_file="$2"

    log_info "Posting response to issue #${issue_number}..."

    local response_text
    response_text=$(jq -r '.response' "${response_file}")

    if ! post_pr_comment "${issue_number}" "${response_text}"; then
        error "Failed to post response"
    fi

    success "Response posted successfully"
}

# Main execution
main() {
    log_info "AI Agent Script v1.0"

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

    # Process issue
    process_issue "${ISSUE_NUMBER}"

    # Validate output
    validate_output "${OUTPUT_FILE}"

    # Post response if requested
    if [[ "${AUTO_POST}" == "true" ]]; then
        post_response "${ISSUE_NUMBER}" "${OUTPUT_FILE}"
    fi

    success "Processing completed successfully"
    log_info "Output: ${OUTPUT_FILE}"

    exit 0
}

# Run main function
main "$@"
