#!/usr/bin/env bash
# Script: common.sh
# Description: Shared utility functions for AI agent scripts
# Usage: source "${SCRIPT_DIR}/lib/common.sh"

# Logging configuration
readonly LOG_LEVEL_DEBUG=0
readonly LOG_LEVEL_INFO=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_ERROR=3

# Default log level
CURRENT_LOG_LEVEL="${LOG_LEVEL_INFO}"

# Colors for output (disabled on Windows without ANSI support)
if [[ "${TERM:-}" != "dumb" ]] && [[ -t 2 ]]; then
    readonly COLOR_RED='\033[0;31m'
    readonly COLOR_GREEN='\033[0;32m'
    readonly COLOR_YELLOW='\033[0;33m'
    readonly COLOR_BLUE='\033[0;34m'
    readonly COLOR_RESET='\033[0m'
else
    readonly COLOR_RED=''
    readonly COLOR_GREEN=''
    readonly COLOR_YELLOW=''
    readonly COLOR_BLUE=''
    readonly COLOR_RESET=''
fi

# Logging functions
log_debug() {
    if [[ "${CURRENT_LOG_LEVEL}" -le "${LOG_LEVEL_DEBUG}" ]]; then
        echo -e "${COLOR_BLUE}[DEBUG]${COLOR_RESET} $*" >&2
    fi
}

log_info() {
    if [[ "${CURRENT_LOG_LEVEL}" -le "${LOG_LEVEL_INFO}" ]]; then
        echo -e "[INFO] $*" >&2
    fi
}

log() {
    log_info "$@"
}

log_warn() {
    if [[ "${CURRENT_LOG_LEVEL}" -le "${LOG_LEVEL_WARN}" ]]; then
        echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $*" >&2
    fi
}

log_error() {
    if [[ "${CURRENT_LOG_LEVEL}" -le "${LOG_LEVEL_ERROR}" ]]; then
        echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2
    fi
}

error() {
    log_error "$@"
    exit 1
}

success() {
    echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} $*" >&2
}

# Enable verbose logging
enable_verbose() {
    CURRENT_LOG_LEVEL="${LOG_LEVEL_DEBUG}"
}

# Check required environment variables
check_required_env() {
    local missing=()
    for var in "$@"; do
        if [[ -z "${!var:-}" ]]; then
            missing+=("$var")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing required environment variables: ${missing[*]}"
    fi
}

# Check required commands
check_required_commands() {
    local missing=()
    for cmd in "$@"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing required commands: ${missing[*]}"
    fi
}

# Cross-platform path handling
normalize_path() {
    local path="$1"

    # Check if running on Windows (Git Bash, MSYS2, Cygwin)
    if [[ "$(uname -s)" == MINGW* ]] || [[ "$(uname -s)" == MSYS* ]] || [[ "$(uname -s)" == CYGWIN* ]]; then
        # Use cygpath if available
        if command -v cygpath &> /dev/null; then
            cygpath -u "$path"
        else
            # Basic conversion for Git Bash
            echo "$path" | sed 's|\\|/|g'
        fi
    else
        echo "$path"
    fi
}

# JSON validation
validate_json() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        return 1
    fi

    if ! jq empty "$file" 2>/dev/null; then
        log_error "Invalid JSON in file: $file"
        return 1
    fi

    return 0
}


# ============================================================================
# HTTP Status Code Categorization and Retry Logic
# ============================================================================

# Categorize HTTP status code to determine retry behavior
# Returns: category name via stdout, exit code indicates retry recommendation
#   0 = SUCCESS (no retry needed)
#   1 = CLIENT_ERROR (don't retry)
#   2 = RATE_LIMIT (retry with longer backoff)
#   3 = SERVER_ERROR (retry with exponential backoff)
#   4 = UNKNOWN (don't retry by default)
categorize_http_status() {
    local status="$1"

    # 2xx - Success
    if [[ "$status" =~ ^2[0-9]{2}$ ]]; then
        echo "SUCCESS"
        return 0
    fi

    # 429 - Rate limit (retry with backoff)
    if [[ "$status" == "429" ]]; then
        echo "RATE_LIMIT"
        return 2
    fi

    # 4xx - Client error (don't retry)
    if [[ "$status" =~ ^4[0-9]{2}$ ]]; then
        echo "CLIENT_ERROR"
        return 1
    fi

    # 5xx - Server error (retry)
    if [[ "$status" =~ ^5[0-9]{2}$ ]]; then
        echo "SERVER_ERROR"
        return 3
    fi

    # Other - Unknown (don't retry by default)
    echo "UNKNOWN"
    return 4
}

# Parse Retry-After header from response headers
# Returns: seconds to wait, or default value
get_retry_after() {
    local headers_file="$1"
    local default_seconds="${2:-60}"

    # Try to extract Retry-After header from response
    local retry_after
    retry_after=$(grep -i "^Retry-After:" "${headers_file}" 2>/dev/null | cut -d: -f2 | tr -d ' 

' || echo "")

    if [[ -n "${retry_after}" ]]; then
        # Check if it's a number (seconds) or date
        if [[ "${retry_after}" =~ ^[0-9]+$ ]]; then
            echo "${retry_after}"
        else
            # Date format - calculate difference (simplified, return default)
            echo "${default_seconds}"
        fi
    else
        echo "${default_seconds}"
    fi
}

# HTTP-aware retry - check if we should retry based on HTTP status code
# Usage: should_retry_http MAX_RETRIES CURRENT_ATTEMPT HTTP_STATUS BASE_DELAY [HEADERS_FILE]
# Returns: 0 if should retry, 1 if should not retry
# Outputs: delay time in seconds via stdout if should retry
should_retry_http() {
    local max_retries="${1}"
    local current_attempt="${2}"
    local http_status="${3}"
    local base_delay="${4}"
    local headers_file="${5:-}"

    # Categorize the HTTP status
    local category
    local retry_code
    category=$(categorize_http_status "${http_status}")
    retry_code=$?

    log_debug "HTTP ${http_status} categorized as: ${category}"

    case ${retry_code} in
        0)
            # SUCCESS - no retry needed
            log_debug "Success status ${http_status}, no retry needed"
            return 1
            ;;
        1)
            # CLIENT_ERROR - don't retry (4xx)
            log_error "Client error ${http_status}, will not retry (check request parameters)"
            return 1
            ;;
        2)
            # RATE_LIMIT - retry with longer backoff (429)
            if [[ ${current_attempt} -lt ${max_retries} ]]; then
                # Check for Retry-After header
                local delay="${base_delay}"
                if [[ -n "${headers_file}" ]] && [[ -f "${headers_file}" ]]; then
                    delay=$(get_retry_after "${headers_file}" "$((base_delay * 3))")
                else
                    delay=$((base_delay * 3))  # Longer delay for rate limits
                fi
                log_warn "Rate limit (429), will retry after ${delay}s (attempt ${current_attempt}/${max_retries})"
                echo "${delay}"
                return 0
            else
                log_error "Rate limit (429) after ${max_retries} attempts, giving up"
                return 1
            fi
            ;;
        3)
            # SERVER_ERROR - retry with exponential backoff (5xx)
            if [[ ${current_attempt} -lt ${max_retries} ]]; then
                local delay=$((base_delay * (2 ** (current_attempt - 1))))
                log_warn "Server error ${http_status}, will retry after ${delay}s (attempt ${current_attempt}/${max_retries})"
                echo "${delay}"
                return 0
            else
                log_error "Server error ${http_status} after ${max_retries} attempts, giving up"
                return 1
            fi
            ;;
        4 | *)
            # UNKNOWN - don't retry by default
            log_error "Unknown/unexpected status ${http_status}, will not retry"
            return 1
            ;;
    esac
}

# Retry logic with exponential backoff
retry_with_backoff() {
    local max_retries="${1}"
    local base_delay="${2}"
    shift 2
    local cmd=("$@")

    local attempt=1
    local delay="${base_delay}"

    while [[ ${attempt} -le ${max_retries} ]]; do
        log_debug "Attempt ${attempt}/${max_retries}: ${cmd[*]}"

        if "${cmd[@]}"; then
            return 0
        fi

        local exit_code=$?

        if [[ ${attempt} -lt ${max_retries} ]]; then
            log_warn "Command failed (exit code: ${exit_code}), retrying in ${delay}s..."
            sleep "${delay}"
            delay=$((delay * 2))
            attempt=$((attempt + 1))
        else
            log_error "Command failed after ${max_retries} attempts"
            return ${exit_code}
        fi
    done
}

# Call AI API with HTTP-aware retry logic
# Usage: call_ai_api REQUEST_DATA [MODEL] [MAX_TOKENS] [MAX_RETRIES] [RETRY_DELAY]
call_ai_api() {
    local request_data="$1"
    local model="${2:-claude-3-opus}"
    local max_tokens="${3:-4096}"
    local max_retries="${4:-3}"
    local retry_delay="${5:-5}"

    check_required_env "AI_API_KEY" "AI_API_ENDPOINT"

    local api_endpoint="${AI_API_ENDPOINT}"
    local api_key="${AI_API_KEY}"

    # Determine API provider from endpoint or model
    local provider="anthropic"
    if [[ "$model" == gpt-* ]]; then
        provider="openai"
    fi

    # Use circuit breaker for API endpoint
    local cb_endpoint="ai_api_${provider}"
    init_circuit_breaker "${cb_endpoint}"

    # Check circuit breaker state
    if is_circuit_open "${cb_endpoint}"; then
        log_error "Circuit breaker OPEN for ${cb_endpoint} - failing fast"
        return 1
    fi

    local attempt=1
    local response_file
    local headers_file

    while [[ ${attempt} -le ${max_retries} ]]; do
        response_file=$(mktemp)
        headers_file=$(mktemp)
        chmod 600 "${response_file}" "${headers_file}"

        log_debug "Calling AI API (attempt ${attempt}/${max_retries}): ${api_endpoint} (model: ${model})"

        # Build API request based on provider, capturing headers
        local http_code
        if [[ "$provider" == "openai" ]]; then
            http_code=$(curl --connect-timeout "${CONNECT_TIMEOUT:-10}" --max-time 60 --dns-timeout "${DNS_TIMEOUT:-5}" -s -w "%{http_code}" -o "${response_file}" -D "${headers_file}"                 -X POST "${api_endpoint}"                 -H "Content-Type: application/json"                 -H "Authorization: Bearer ${api_key}"                 -d "{
                    \"model\": \"${model}\",
                    \"messages\": [{\"role\": \"user\", \"content\": ${request_data}}],
                    \"max_tokens\": ${max_tokens}
                }")
        else
            # Anthropic Claude API
            http_code=$(curl --connect-timeout "${CONNECT_TIMEOUT:-10}" --max-time 60 --dns-timeout "${DNS_TIMEOUT:-5}" -s -w "%{http_code}" -o "${response_file}" -D "${headers_file}"                 -X POST "${api_endpoint}"                 -H "Content-Type: application/json"                 -H "x-api-key: ${api_key}"                 -H "anthropic-version: 2023-06-01"                 -d "{
                    \"model\": \"${model}\",
                    \"messages\": [{\"role\": \"user\", \"content\": ${request_data}}],
                    \"max_tokens\": ${max_tokens}
                }")
        fi

        log_debug "AI API returned HTTP ${http_code}"

        # Check HTTP response code using status categorization
        if [[ "${http_code}" =~ ^2[0-9]{2}$ ]]; then
            # Success - return response
            cat "${response_file}"
            rm -f "${response_file}" "${headers_file}"
            record_success "${cb_endpoint}"
            return 0
        else
            # Failure - check if we should retry
            log_warn "AI API request failed with HTTP ${http_code}"

            # Show error response for debugging
            if [[ -s "${response_file}" ]]; then
                log_debug "Error response: $(cat "${response_file}")"
            fi

            # Determine if we should retry based on HTTP status
            local delay
            if delay=$(should_retry_http "${max_retries}" "${attempt}" "${http_code}" "${retry_delay}" "${headers_file}"); then
                # Should retry - sleep and continue
                log_info "Retrying AI API call after ${delay}s..."
                sleep "${delay}"
                rm -f "${response_file}" "${headers_file}"
                attempt=$((attempt + 1))
            else
                # Should not retry - fail immediately
                log_error "AI API request failed with HTTP ${http_code}, not retrying"
                cat "${response_file}" >&2
                rm -f "${response_file}" "${headers_file}"
                record_failure "${cb_endpoint}"
                return 1
            fi
        fi
    done

    # All retries exhausted
    log_error "AI API request failed after ${max_retries} attempts"
    record_failure "${cb_endpoint}"
    return 1
}

# Extract AI response content
extract_ai_response() {
    local response="$1"
    local provider="${2:-anthropic}"

    if [[ "$provider" == "openai" ]]; then
        echo "$response" | jq -r '.choices[0].message.content // empty'
    else
        # Anthropic
        echo "$response" | jq -r '.content[0].text // empty'
    fi
}

# Rate limiting check
check_rate_limit() {
    local rate_limit_file="${TMPDIR:-/tmp}/.ai_rate_limit"
    local min_interval="${1:-1}"  # Minimum seconds between calls

    if [[ -f "${rate_limit_file}" ]]; then
        local last_call
        last_call=$(cat "${rate_limit_file}")
        local current_time
        current_time=$(date +%s)
        local elapsed=$((current_time - last_call))

        if [[ ${elapsed} -lt ${min_interval} ]]; then
            local wait_time=$((min_interval - elapsed))
            log_debug "Rate limiting: waiting ${wait_time}s"
            sleep "${wait_time}"
        fi
    fi

    date +%s > "${rate_limit_file}"
}

# Get PR diff
get_pr_diff() {
    local pr_number="$1"
    local max_files="${2:-20}"

    log_debug "Fetching PR #${pr_number} diff"

    # Get PR diff using gh CLI
    gh pr diff "${pr_number}" --patch | head -n 10000
}

# Get PR files
get_pr_files() {
    local pr_number="$1"
    local max_files="${2:-20}"

    log_debug "Fetching PR #${pr_number} files"

    gh pr view "${pr_number}" --json files \
        | jq -r ".files[0:${max_files}][] | .path"
}

# Get PR metadata
get_pr_metadata() {
    local pr_number="$1"

    gh pr view "${pr_number}" --json \
        number,title,body,author,additions,deletions,changedFiles,state,isDraft
}

# Create temporary file with cleanup
create_temp_file() {
    local prefix="${1:-ai_script}"
    local temp_file
    temp_file=$(mktemp -t "${prefix}.XXXXXX")

    # Register cleanup trap
    trap "rm -f ${temp_file}" EXIT INT TERM

    echo "${temp_file}"
}

# Escape JSON strings
escape_json() {
    local input="$1"
    # Escape backslashes, quotes, and control characters
    echo "$input" | jq -Rs .
}

# Validate GitHub CLI authentication
validate_gh_auth() {
    if ! gh auth status &>/dev/null; then
        error "GitHub CLI not authenticated. Run: gh auth login"
    fi
}

# Get current repository
get_current_repo() {
    if [[ -n "${GITHUB_REPOSITORY:-}" ]]; then
        echo "${GITHUB_REPOSITORY}"
    else
        gh repo view --json nameWithOwner -q .nameWithOwner
    fi
}

# Check if running in GitHub Actions
is_github_actions() {
    [[ "${GITHUB_ACTIONS:-false}" == "true" ]]
}

# Get GitHub token
get_github_token() {
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        echo "${GITHUB_TOKEN}"
    elif [[ -n "${GH_TOKEN:-}" ]]; then
        echo "${GH_TOKEN}"
    else
        gh auth token 2>/dev/null || error "No GitHub token available"
    fi
}

# Post PR comment
post_pr_comment() {
    local pr_number="$1"
    local comment_body="$2"

    log_debug "Posting comment to PR #${pr_number}"

    gh pr comment "${pr_number}" --body "${comment_body}"
}

# Post PR review
post_pr_review() {
    local pr_number="$1"
    local review_file="$2"

    validate_json "${review_file}" || error "Invalid review JSON"

    local event
    event=$(jq -r '.event // "COMMENT"' "${review_file}")

    local body
    body=$(jq -r '.body // ""' "${review_file}")

    log_debug "Posting ${event} review to PR #${pr_number}"

    # Build gh pr review command
    local gh_args=()

    case "${event}" in
        APPROVE)
            gh_args+=("--approve")
            ;;
        REQUEST_CHANGES)
            gh_args+=("--request-changes")
            ;;
        COMMENT)
            gh_args+=("--comment")
            ;;
        *)
            log_warn "Unknown review event: ${event}, using COMMENT"
            gh_args+=("--comment")
            ;;
    esac

    if [[ -n "${body}" ]]; then
        gh_args+=("--body" "${body}")
    fi

    gh pr review "${pr_number}" "${gh_args[@]}"

    # Post inline comments if present
    local comments_count
    comments_count=$(jq -r '.comments | length' "${review_file}")

    if [[ "${comments_count}" -gt 0 ]]; then
        log_debug "Posting ${comments_count} inline comments"
        # Note: GitHub CLI doesn't support inline comments directly
        # This would require GitHub API calls
        log_warn "Inline comments not implemented yet (requires GitHub API)"
    fi
}

# Export functions for use in other scripts
export -f log_debug log_info log log_warn log_error error success
export -f enable_verbose check_required_env check_required_commands
export -f normalize_path validate_json retry_with_backoff
export -f call_ai_api extract_ai_response check_rate_limit
export -f get_pr_diff get_pr_files get_pr_metadata
export -f create_temp_file escape_json validate_gh_auth
export -f get_current_repo is_github_actions get_github_token
export -f post_pr_comment post_pr_review
export -f categorize_http_status get_retry_after should_retry_http
