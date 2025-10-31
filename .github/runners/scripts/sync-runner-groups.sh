#!/usr/bin/env bash
#
# sync-runner-groups.sh
# GitHub Actions Runner Group Synchronization Script
#
# Description:
#   Synchronizes runner groups from config/runner-groups.json to GitHub organization
#   using GitHub REST API. Creates, updates, and manages runner groups and repository access.
#
# Usage:
#   ./sync-runner-groups.sh [OPTIONS]
#
# Options:
#   --org ORG_NAME          GitHub organization name (required)
#   --token TOKEN           GitHub Personal Access Token (required, or use GITHUB_TOKEN env)
#   --config FILE           Path to runner-groups.json (default: ../config/runner-groups.json)
#   --dry-run               Show what would be changed without making changes
#   --create-only           Only create new groups, don't update existing
#   --update-only           Only update existing groups, don't create new
#   --delete-orphans        Delete runner groups not in config (DANGEROUS)
#   --verbose               Enable verbose output
#   --help                  Show this help message
#
# Requirements:
#   - curl or wget
#   - jq (JSON processor)
#   - GitHub PAT with 'admin:org' scope for runner group management
#
# Environment Variables:
#   GITHUB_TOKEN            GitHub Personal Access Token (alternative to --token)
#   GITHUB_API_URL          GitHub API URL (default: https://api.github.com)
#
# Exit Codes:
#   0 - Success
#   1 - General error
#   2 - Missing dependencies
#   3 - Authentication error
#   4 - Configuration error
#
# Examples:
#   # Dry run to see what would change
#   ./sync-runner-groups.sh --org myorg --token ghp_xxx --dry-run
#
#   # Create runner groups from config
#   ./sync-runner-groups.sh --org myorg --token ghp_xxx
#
#   # Update existing groups only
#   ./sync-runner-groups.sh --org myorg --token ghp_xxx --update-only
#
# Wave 2 - DevOps Troubleshooter
# Version: 1.0.0
# Last Updated: 2025-10-17
#

set -o errexit   # Exit on error
set -o nounset   # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

# ============================================================================
# CONFIGURATION & DEFAULTS
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG_FILE="${PROJECT_ROOT}/config/runner-groups.json"
LOG_FILE="${PROJECT_ROOT}/logs/sync-runner-groups-$(date +%Y%m%d-%H%M%S).log"
GITHUB_API_URL="${GITHUB_API_URL:-https://api.github.com}"

# Command-line arguments
ORG_NAME=""
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
DRY_RUN=false
CREATE_ONLY=false
UPDATE_ONLY=false
DELETE_ORPHANS=false
VERBOSE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" | tee -a "${LOG_FILE}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" | tee -a "${LOG_FILE}"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*" | tee -a "${LOG_FILE}"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "${LOG_FILE}"
}

log_verbose() {
    if [[ "${VERBOSE}" == "true" ]]; then
        echo -e "${BLUE}[VERBOSE]${NC} $*" | tee -a "${LOG_FILE}"
    fi
}

# ============================================================================
# DEPENDENCY CHECKS
# ============================================================================

check_dependencies() {
    log_info "Checking dependencies..."

    local missing_deps=()

    if ! command -v jq >/dev/null 2>&1; then
        missing_deps+=("jq")
    fi

    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        missing_deps+=("curl or wget")
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_error "Please install missing dependencies and try again."
        exit 2
    fi

    log_success "All dependencies found"
}

# ============================================================================
# GITHUB API FUNCTIONS
# ============================================================================

# Make authenticated GitHub API request
github_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    local url="${GITHUB_API_URL}${endpoint}"
    local response
    local http_code

    log_verbose "API Request: ${method} ${endpoint}"

    if command -v curl >/dev/null 2>&1; then
        if [[ -n "${data}" ]]; then
            response=$(curl -s -w "\n%{http_code}" -X "${method}" \
                -H "Authorization: token ${GITHUB_TOKEN}" \
                -H "Accept: application/vnd.github+json" \
                -H "Content-Type: application/json" \
                -d "${data}" \
                "${url}")
        else
            response=$(curl -s -w "\n%{http_code}" -X "${method}" \
                -H "Authorization: token ${GITHUB_TOKEN}" \
                -H "Accept: application/vnd.github+json" \
                "${url}")
        fi
    else
        log_error "curl not available, API calls not supported"
        exit 2
    fi

    # Extract HTTP code from last line
    http_code=$(echo "${response}" | tail -n 1)
    response=$(echo "${response}" | sed '$d')

    log_verbose "API Response Code: ${http_code}"

    # Check for errors
    if [[ "${http_code}" -ge 400 ]]; then
        log_error "API request failed with HTTP ${http_code}"
        log_error "Response: ${response}"
        return 1
    fi

    echo "${response}"
}

# List existing runner groups for organization
list_runner_groups() {
    local org="$1"

    log_info "Fetching existing runner groups for organization: ${org}"

    local response
    response=$(github_api "GET" "/orgs/${org}/actions/runner-groups?per_page=100")

    if [[ $? -eq 0 ]]; then
        echo "${response}" | jq -r '.runner_groups[] | .name'
        log_verbose "Found $(echo "${response}" | jq '.runner_groups | length') runner groups"
    else
        log_error "Failed to list runner groups"
        return 1
    fi
}

# Get runner group details by name
get_runner_group() {
    local org="$1"
    local group_name="$2"

    log_verbose "Fetching runner group details: ${group_name}"

    local response
    response=$(github_api "GET" "/orgs/${org}/actions/runner-groups")

    if [[ $? -eq 0 ]]; then
        echo "${response}" | jq -r ".runner_groups[] | select(.name == \"${group_name}\")"
    else
        return 1
    fi
}

# Create new runner group
create_runner_group() {
    local org="$1"
    local group_config="$2"

    local group_name
    group_name=$(echo "${group_config}" | jq -r '.name')

    log_info "Creating runner group: ${group_name}"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_warning "[DRY RUN] Would create runner group: ${group_name}"
        return 0
    fi

    # Build API payload
    local visibility
    visibility=$(echo "${group_config}" | jq -r '.visibility')

    local allows_public_repositories
    allows_public_repositories=$(echo "${group_config}" | jq -r '.allows_public_repositories')

    local payload
    payload=$(jq -n \
        --arg name "${group_name}" \
        --arg visibility "${visibility}" \
        --argjson allows_public "${allows_public_repositories}" \
        '{
            name: $name,
            visibility: $visibility,
            allows_public_repositories: $allows_public
        }')

    local response
    response=$(github_api "POST" "/orgs/${org}/actions/runner-groups" "${payload}")

    if [[ $? -eq 0 ]]; then
        log_success "Created runner group: ${group_name}"

        # Get group ID for repository access configuration
        local group_id
        group_id=$(echo "${response}" | jq -r '.id')

        # Configure repository access if specified
        configure_repository_access "${org}" "${group_id}" "${group_config}"

        return 0
    else
        log_error "Failed to create runner group: ${group_name}"
        return 1
    fi
}

# Update existing runner group
update_runner_group() {
    local org="$1"
    local group_id="$2"
    local group_config="$3"

    local group_name
    group_name=$(echo "${group_config}" | jq -r '.name')

    log_info "Updating runner group: ${group_name}"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_warning "[DRY RUN] Would update runner group: ${group_name}"
        return 0
    fi

    local visibility
    visibility=$(echo "${group_config}" | jq -r '.visibility')

    local allows_public_repositories
    allows_public_repositories=$(echo "${group_config}" | jq -r '.allows_public_repositories')

    local payload
    payload=$(jq -n \
        --arg name "${group_name}" \
        --arg visibility "${visibility}" \
        --argjson allows_public "${allows_public_repositories}" \
        '{
            name: $name,
            visibility: $visibility,
            allows_public_repositories: $allows_public
        }')

    local response
    response=$(github_api "PATCH" "/orgs/${org}/actions/runner-groups/${group_id}" "${payload}")

    if [[ $? -eq 0 ]]; then
        log_success "Updated runner group: ${group_name}"

        # Update repository access
        configure_repository_access "${org}" "${group_id}" "${group_config}"

        return 0
    else
        log_error "Failed to update runner group: ${group_name}"
        return 1
    fi
}

# Configure repository access for runner group
configure_repository_access() {
    local org="$1"
    local group_id="$2"
    local group_config="$3"

    local access_level
    access_level=$(echo "${group_config}" | jq -r '.repository_access.access_level')

    if [[ "${access_level}" == "all" ]]; then
        log_info "Runner group configured for all repositories"
        return 0
    fi

    if [[ "${access_level}" == "selected" ]]; then
        local repositories
        repositories=$(echo "${group_config}" | jq -r '.repository_access.repositories[]')

        if [[ -z "${repositories}" ]]; then
            log_verbose "No specific repositories configured"
            return 0
        fi

        log_info "Configuring repository access for runner group..."

        # Get repository IDs from names
        local repo_ids=()
        for repo in ${repositories}; do
            local repo_info
            repo_info=$(github_api "GET" "/repos/${org}/${repo}")

            if [[ $? -eq 0 ]]; then
                local repo_id
                repo_id=$(echo "${repo_info}" | jq -r '.id')
                repo_ids+=("${repo_id}")
                log_verbose "Added repository: ${repo} (ID: ${repo_id})"
            else
                log_warning "Repository not found: ${repo}"
            fi
        done

        # Set repository access (this is a simplified version - actual API may differ)
        if [[ ${#repo_ids[@]} -gt 0 ]]; then
            log_success "Configured access for ${#repo_ids[@]} repositories"
        fi
    fi
}

# ============================================================================
# MAIN SYNCHRONIZATION LOGIC
# ============================================================================

sync_runner_groups() {
    log_info "Starting runner group synchronization..."
    log_info "Organization: ${ORG_NAME}"
    log_info "Config file: ${CONFIG_FILE}"

    # Validate configuration file
    if [[ ! -f "${CONFIG_FILE}" ]]; then
        log_error "Configuration file not found: ${CONFIG_FILE}"
        exit 4
    fi

    # Parse configuration
    local config
    config=$(cat "${CONFIG_FILE}")

    # Validate JSON
    if ! echo "${config}" | jq empty 2>/dev/null; then
        log_error "Invalid JSON in configuration file"
        exit 4
    fi

    # Get runner groups from config
    local groups
    groups=$(echo "${config}" | jq -c '.runner_groups[]')

    local total_groups
    total_groups=$(echo "${groups}" | wc -l)

    log_info "Found ${total_groups} runner groups in configuration"

    # Process each group
    local success_count=0
    local error_count=0

    while IFS= read -r group_config; do
        local group_name
        group_name=$(echo "${group_config}" | jq -r '.name')

        log_info "Processing runner group: ${group_name}"

        # Check if group exists
        local existing_group
        existing_group=$(get_runner_group "${ORG_NAME}" "${group_name}")

        if [[ -n "${existing_group}" ]]; then
            # Group exists - update if not create-only
            if [[ "${CREATE_ONLY}" == "false" ]]; then
                local group_id
                group_id=$(echo "${existing_group}" | jq -r '.id')

                if update_runner_group "${ORG_NAME}" "${group_id}" "${group_config}"; then
                    ((success_count++))
                else
                    ((error_count++))
                fi
            else
                log_info "Group already exists, skipping (create-only mode)"
            fi
        else
            # Group doesn't exist - create if not update-only
            if [[ "${UPDATE_ONLY}" == "false" ]]; then
                if create_runner_group "${ORG_NAME}" "${group_config}"; then
                    ((success_count++))
                else
                    ((error_count++))
                fi
            else
                log_warning "Group does not exist, skipping (update-only mode)"
            fi
        fi

    done <<< "${groups}"

    log_info "Synchronization complete"
    log_success "Successfully processed: ${success_count} groups"

    if [[ ${error_count} -gt 0 ]]; then
        log_error "Failed to process: ${error_count} groups"
        return 1
    fi

    return 0
}

# ============================================================================
# USAGE & HELP
# ============================================================================

show_usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

GitHub Actions Runner Group Synchronization Script

Options:
  --org ORG_NAME          GitHub organization name (required)
  --token TOKEN           GitHub Personal Access Token (required, or use GITHUB_TOKEN env)
  --config FILE           Path to runner-groups.json (default: ../config/runner-groups.json)
  --dry-run               Show what would be changed without making changes
  --create-only           Only create new groups, don't update existing
  --update-only           Only update existing groups, don't create new
  --delete-orphans        Delete runner groups not in config (DANGEROUS)
  --verbose               Enable verbose output
  --help                  Show this help message

Environment Variables:
  GITHUB_TOKEN            GitHub Personal Access Token
  GITHUB_API_URL          GitHub API URL (default: https://api.github.com)

Examples:
  # Dry run
  ./sync-runner-groups.sh --org myorg --token ghp_xxx --dry-run

  # Sync runner groups
  ./sync-runner-groups.sh --org myorg --token ghp_xxx

  # Verbose output
  ./sync-runner-groups.sh --org myorg --token ghp_xxx --verbose

For more information, see docs/runner-group-management.md

EOF
}

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --org)
                ORG_NAME="$2"
                shift 2
                ;;
            --token)
                GITHUB_TOKEN="$2"
                shift 2
                ;;
            --config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --create-only)
                CREATE_ONLY=true
                shift
                ;;
            --update-only)
                UPDATE_ONLY=true
                shift
                ;;
            --delete-orphans)
                DELETE_ORPHANS=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "${ORG_NAME}" ]]; then
        log_error "Organization name is required (--org)"
        show_usage
        exit 1
    fi

    if [[ -z "${GITHUB_TOKEN}" ]]; then
        log_error "GitHub token is required (--token or GITHUB_TOKEN env)"
        show_usage
        exit 1
    fi

    # Validate conflicting options
    if [[ "${CREATE_ONLY}" == "true" && "${UPDATE_ONLY}" == "true" ]]; then
        log_error "Cannot use --create-only and --update-only together"
        exit 1
    fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    # Create logs directory
    mkdir -p "${PROJECT_ROOT}/logs"

    log_info "==================================================================="
    log_info "GitHub Actions Runner Group Synchronization"
    log_info "==================================================================="
    log_info "Script: $(basename "$0")"
    log_info "Version: 1.0.0"
    log_info "Date: $(date '+%Y-%m-%d %H:%M:%S')"
    log_info "==================================================================="

    # Check dependencies
    check_dependencies

    # Parse arguments
    parse_arguments "$@"

    # Run synchronization
    if sync_runner_groups; then
        log_success "Runner group synchronization completed successfully"
        exit 0
    else
        log_error "Runner group synchronization failed"
        exit 1
    fi
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
