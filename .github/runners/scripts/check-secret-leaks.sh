#!/usr/bin/env bash
# =============================================================================
# Secret Leak Scanner for GitHub Actions
# =============================================================================
# Description: Scans workflow logs and code for potential secret leaks
# Author: Security Auditor - Wave 3
# Version: 1.0.0
# OWASP References: A02:2021 - Cryptographic Failures, A07:2021 - Identification and Authentication Failures
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
readonly MAGENTA='\033[0;35m'
readonly NC='\033[0m' # No Color

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_LEAK_FOUND=1
readonly EXIT_ERROR=2

# Severity levels
readonly SEVERITY_CRITICAL="CRITICAL"
readonly SEVERITY_HIGH="HIGH"
readonly SEVERITY_MEDIUM="MEDIUM"
readonly SEVERITY_LOW="LOW"
readonly SEVERITY_INFO="INFO"

# Counters
TOTAL_FILES_SCANNED=0
TOTAL_LEAKS_FOUND=0
CRITICAL_LEAKS=0
HIGH_LEAKS=0
MEDIUM_LEAKS=0
LOW_LEAKS=0
INFO_LEAKS=0

# =============================================================================
# Secret Pattern Definitions
# =============================================================================

# Define regex patterns for various secret types with severity levels
declare -A SECRET_PATTERNS=(
    # API Keys and Tokens - CRITICAL
    ["github_token"]="ghp_[a-zA-Z0-9]{36}|github_pat_[a-zA-Z0-9]{22}_[a-zA-Z0-9]{59}"
    ["github_oauth"]="gho_[a-zA-Z0-9]{36}"
    ["github_app_token"]="ghs_[a-zA-Z0-9]{36}"
    ["github_refresh_token"]="ghr_[a-zA-Z0-9]{36}"
    ["npm_token"]="npm_[a-zA-Z0-9]{36}"
    ["slack_token"]="xox[baprs]-[0-9]{10,12}-[0-9]{10,12}-[a-zA-Z0-9]{24,32}"
    ["aws_access_key"]="AKIA[0-9A-Z]{16}"
    ["aws_secret_key"]="[a-zA-Z0-9/+=]{40}"

    # Cloud Provider Secrets - CRITICAL
    ["azure_key"]="[a-zA-Z0-9+/]{86}=="
    ["gcp_api_key"]="AIza[0-9A-Za-z\\-_]{35}"
    ["gcp_oauth"]="[0-9]+-[0-9A-Za-z_]{32}\.apps\.googleusercontent\.com"
    ["heroku_api_key"]="[hH][eE][rR][oO][kK][uU].*[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"

    # Database Credentials - HIGH
    ["postgres_url"]="postgres://[a-zA-Z0-9]+:[a-zA-Z0-9]+@[a-zA-Z0-9.-]+:[0-9]+/[a-zA-Z0-9]+"
    ["mysql_url"]="mysql://[a-zA-Z0-9]+:[a-zA-Z0-9]+@[a-zA-Z0-9.-]+:[0-9]+/[a-zA-Z0-9]+"
    ["mongodb_url"]="mongodb(\\+srv)?://[a-zA-Z0-9]+:[a-zA-Z0-9]+@[a-zA-Z0-9.-]+"

    # Private Keys - CRITICAL
    ["rsa_private_key"]="-----BEGIN RSA PRIVATE KEY-----"
    ["ssh_private_key"]="-----BEGIN OPENSSH PRIVATE KEY-----"
    ["ec_private_key"]="-----BEGIN EC PRIVATE KEY-----"
    ["pgp_private_key"]="-----BEGIN PGP PRIVATE KEY BLOCK-----"

    # JWT and Bearer Tokens - HIGH
    ["jwt_token"]="ey[A-Za-z0-9-_]+\\.ey[A-Za-z0-9-_]+\\.[A-Za-z0-9-_]+"
    ["bearer_token"]="[bB]earer\\s+[a-zA-Z0-9_\\-\\.=]+"

    # API Secrets - HIGH
    ["api_key_generic"]="[aA][pP][iI]_?[kK][eE][yY]\\s*[:=]\\s*['\"][a-zA-Z0-9_\\-]{20,}['\"]"
    ["api_secret_generic"]="[aA][pP][iI]_?[sS][eE][cC][rR][eE][tT]\\s*[:=]\\s*['\"][a-zA-Z0-9_\\-]{20,}['\"]"
    ["client_secret"]="[cC][lL][iI][eE][nN][tT]_?[sS][eE][cC][rR][eE][tT]\\s*[:=]\\s*['\"][a-zA-Z0-9_\\-]{20,}['\"]"

    # Password Patterns - MEDIUM
    ["password_in_url"]="://[a-zA-Z0-9]+:[a-zA-Z0-9]+@"
    ["password_assignment"]="[pP][aA][sS][sS][wW][oO][rR][dD]\\s*[:=]\\s*['\"][^'\"]{8,}['\"]"

    # Webhook URLs - MEDIUM
    ["discord_webhook"]="https://discord(app)?\\.com/api/webhooks/[0-9]+/[a-zA-Z0-9_\\-]+"
    ["slack_webhook"]="https://hooks\\.slack\\.com/services/T[a-zA-Z0-9_]{8}/B[a-zA-Z0-9_]{8}/[a-zA-Z0-9_]{24}"

    # Sensitive Files - INFO
    ["env_file"]="\\.env(\\.[a-zA-Z]+)?"
    ["private_key_file"]=".*\\.(pem|key|p12|pfx)$"
    ["credentials_file"]=".*credentials.*\\.(json|yml|yaml|xml)$"
)

# Define severity levels for pattern categories
declare -A PATTERN_SEVERITY=(
    ["github_token"]="$SEVERITY_CRITICAL"
    ["github_oauth"]="$SEVERITY_CRITICAL"
    ["github_app_token"]="$SEVERITY_CRITICAL"
    ["github_refresh_token"]="$SEVERITY_CRITICAL"
    ["npm_token"]="$SEVERITY_CRITICAL"
    ["slack_token"]="$SEVERITY_HIGH"
    ["aws_access_key"]="$SEVERITY_CRITICAL"
    ["aws_secret_key"]="$SEVERITY_CRITICAL"
    ["azure_key"]="$SEVERITY_CRITICAL"
    ["gcp_api_key"]="$SEVERITY_CRITICAL"
    ["gcp_oauth"]="$SEVERITY_HIGH"
    ["heroku_api_key"]="$SEVERITY_HIGH"
    ["postgres_url"]="$SEVERITY_HIGH"
    ["mysql_url"]="$SEVERITY_HIGH"
    ["mongodb_url"]="$SEVERITY_HIGH"
    ["rsa_private_key"]="$SEVERITY_CRITICAL"
    ["ssh_private_key"]="$SEVERITY_CRITICAL"
    ["ec_private_key"]="$SEVERITY_CRITICAL"
    ["pgp_private_key"]="$SEVERITY_CRITICAL"
    ["jwt_token"]="$SEVERITY_HIGH"
    ["bearer_token"]="$SEVERITY_HIGH"
    ["api_key_generic"]="$SEVERITY_HIGH"
    ["api_secret_generic"]="$SEVERITY_HIGH"
    ["client_secret"]="$SEVERITY_HIGH"
    ["password_in_url"]="$SEVERITY_MEDIUM"
    ["password_assignment"]="$SEVERITY_MEDIUM"
    ["discord_webhook"]="$SEVERITY_MEDIUM"
    ["slack_webhook"]="$SEVERITY_MEDIUM"
    ["env_file"]="$SEVERITY_INFO"
    ["private_key_file"]="$SEVERITY_INFO"
    ["credentials_file"]="$SEVERITY_INFO"
)

# =============================================================================
# Helper Functions
# =============================================================================

# Print colored output based on severity
print_severity() {
    local severity="$1"
    local message="$2"

    case "$severity" in
        "$SEVERITY_CRITICAL")
            echo -e "${RED}[CRITICAL]${NC} $message" >&2
            ;;
        "$SEVERITY_HIGH")
            echo -e "${MAGENTA}[HIGH]${NC} $message" >&2
            ;;
        "$SEVERITY_MEDIUM")
            echo -e "${YELLOW}[MEDIUM]${NC} $message" >&2
            ;;
        "$SEVERITY_LOW")
            echo -e "${BLUE}[LOW]${NC} $message" >&2
            ;;
        "$SEVERITY_INFO")
            echo -e "${GREEN}[INFO]${NC} $message" >&2
            ;;
    esac
}

# Print colored output
print_color() {
    local color="$1"
    shift
    echo -e "${color}$*${NC}" >&2
}

# Error message
error() {
    print_color "$RED" "ERROR: $*"
}

# Warning message
warning() {
    print_color "$YELLOW" "WARNING: $*"
}

# Success message
success() {
    print_color "$GREEN" "SUCCESS: $*"
}

# Info message
info() {
    print_color "$BLUE" "INFO: $*"
}

# Print usage
usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS] [FILE|DIRECTORY]

Scans files and logs for potential secret leaks and hardcoded credentials.

Options:
    -h, --help              Show this help message
    -v, --version           Show version information
    -r, --recursive         Recursively scan directories
    -o, --output FILE       Save report to file
    -j, --json              Output in JSON format
    -s, --severity LEVEL    Minimum severity to report (CRITICAL|HIGH|MEDIUM|LOW|INFO)
    -e, --exclude PATTERN   Exclude files matching pattern
    -i, --include PATTERN   Only scan files matching pattern
    --no-git-ignore        Don't respect .gitignore files
    --show-matches         Show actual matched strings (CAREFUL: may expose secrets)
    --ci                   CI mode - simplified output

Examples:
    # Scan current directory
    $SCRIPT_NAME .

    # Scan specific workflow file
    $SCRIPT_NAME .github/workflows/deploy.yml

    # Recursive scan with high severity only
    $SCRIPT_NAME -r -s HIGH /path/to/project

    # Generate JSON report
    $SCRIPT_NAME -j -o report.json .

    # Scan only JavaScript files
    $SCRIPT_NAME -r -i "*.js" src/

Security Checks:
    - GitHub tokens and PATs
    - Cloud provider credentials (AWS, Azure, GCP)
    - Database connection strings
    - API keys and secrets
    - Private keys (SSH, RSA, PGP)
    - JWT tokens
    - Webhook URLs
    - Hardcoded passwords
    - Sensitive files (.env, .pem, credentials)

Exit Codes:
    0 - No leaks found
    1 - Potential leaks detected
    2 - Error during execution

EOF
}

# =============================================================================
# Scanning Functions
# =============================================================================

# Check if file should be excluded
should_exclude() {
    local file="$1"
    local exclude_pattern="${2:-}"

    # Default exclusions
    local default_excludes=(
        "*.log"
        "*.tmp"
        "*.bak"
        "node_modules/*"
        ".git/*"
        "vendor/*"
        "dist/*"
        "build/*"
    )

    # Check default exclusions
    for pattern in "${default_excludes[@]}"; do
        if [[ "$file" == $pattern ]]; then
            return 0
        fi
    done

    # Check custom exclusion
    if [[ -n "$exclude_pattern" ]] && [[ "$file" == $exclude_pattern ]]; then
        return 0
    fi

    return 1
}

# Increment leak counter based on severity
increment_counter() {
    local severity="$1"

    ((TOTAL_LEAKS_FOUND++))

    case "$severity" in
        "$SEVERITY_CRITICAL")
            ((CRITICAL_LEAKS++))
            ;;
        "$SEVERITY_HIGH")
            ((HIGH_LEAKS++))
            ;;
        "$SEVERITY_MEDIUM")
            ((MEDIUM_LEAKS++))
            ;;
        "$SEVERITY_LOW")
            ((LOW_LEAKS++))
            ;;
        "$SEVERITY_INFO")
            ((INFO_LEAKS++))
            ;;
    esac
}

# Scan file for secrets
scan_file() {
    local file="$1"
    local min_severity="${2:-$SEVERITY_INFO}"
    local show_matches="${3:-false}"
    local file_has_leaks=false

    # Skip binary files
    if ! file "$file" | grep -q "text"; then
        return 0
    fi

    ((TOTAL_FILES_SCANNED++))

    # Read file content
    local content
    content=$(cat "$file" 2>/dev/null) || return 0

    # Check each pattern
    for pattern_name in "${!SECRET_PATTERNS[@]}"; do
        local pattern="${SECRET_PATTERNS[$pattern_name]}"
        local severity="${PATTERN_SEVERITY[$pattern_name]}"

        # Check severity threshold
        if ! should_report_severity "$severity" "$min_severity"; then
            continue
        fi

        # Search for pattern
        local matches
        matches=$(echo "$content" | grep -n -E "$pattern" 2>/dev/null) || continue

        if [[ -n "$matches" ]]; then
            file_has_leaks=true

            while IFS= read -r match; do
                local line_num
                line_num=$(echo "$match" | cut -d: -f1)

                print_severity "$severity" "Potential secret found in $file:$line_num"
                info "  Type: $pattern_name"

                if [[ "$show_matches" == "true" ]]; then
                    local match_text
                    match_text=$(echo "$match" | cut -d: -f2-)
                    # Partially redact the match for safety
                    match_text=$(echo "$match_text" | sed -E 's/(.{10}).*(.{5})/\1***REDACTED***\2/')
                    warning "  Match: $match_text"
                fi

                increment_counter "$severity"
            done <<< "$matches"
        fi
    done

    # Check for suspicious file names
    local filename
    filename=$(basename "$file")

    if [[ "$filename" =~ ^\.env(\.|$) ]] || \
       [[ "$filename" =~ credentials ]] || \
       [[ "$filename" =~ secret ]] || \
       [[ "$filename" =~ private.*key ]]; then
        print_severity "$SEVERITY_INFO" "Sensitive filename detected: $file"
        increment_counter "$SEVERITY_INFO"
        file_has_leaks=true
    fi

    return $([ "$file_has_leaks" = true ] && echo 1 || echo 0)
}

# Scan GitHub Actions logs
scan_workflow_logs() {
    local workflow_run_id="$1"
    local repo="${2:-}"

    if [[ -z "$repo" ]]; then
        # Try to get repo from git remote
        repo=$(git remote get-url origin 2>/dev/null | \
               sed -E 's|.*github.com[:/]([^/]+/[^/]+).*|\1|' | \
               sed 's/\.git$//')
    fi

    if [[ -z "$repo" ]]; then
        error "Cannot determine repository. Specify with --repo option"
        return 1
    fi

    info "Scanning workflow logs for run ID: $workflow_run_id in repo: $repo"

    # Use gh CLI to get logs
    if ! command -v gh &> /dev/null; then
        error "GitHub CLI (gh) not found. Install from https://cli.github.com"
        return 1
    fi

    # Download logs
    # Create secure temp file for logs
    local temp_log
    temp_log=$(mktemp -t "workflow_logs_${workflow_run_id}.XXXXXX")
    chmod 600 "${temp_log}"

    # Set up cleanup trap
    trap 'rm -f "${temp_log}"' EXIT INT TERM

    # Download logs
    if ! gh run view "$workflow_run_id" --repo "$repo" --log > "$temp_log" 2>/dev/null; then
        error "Failed to download workflow logs. Check run ID and permissions."
        rm -f "${temp_log}"
        trap - EXIT INT TERM
        return 1
    fi

    # Scan the log file
    scan_file "$temp_log" "$SEVERITY_HIGH" "false"

    # Cleanup (trap will also handle this on exit)
    rm -f "${temp_log}"
    trap - EXIT INT TERM  # Remove trap after cleanup
}

# Check if severity should be reported
should_report_severity() {
    local severity="$1"
    local min_severity="$2"

    local severity_order=("$SEVERITY_INFO" "$SEVERITY_LOW" "$SEVERITY_MEDIUM" "$SEVERITY_HIGH" "$SEVERITY_CRITICAL")

    local severity_index=-1
    local min_index=-1

    for i in "${!severity_order[@]}"; do
        if [[ "${severity_order[$i]}" == "$severity" ]]; then
            severity_index=$i
        fi
        if [[ "${severity_order[$i]}" == "$min_severity" ]]; then
            min_index=$i
        fi
    done

    [[ $severity_index -ge $min_index ]]
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
  "scan_summary": {
    "files_scanned": $TOTAL_FILES_SCANNED,
    "total_findings": $TOTAL_LEAKS_FOUND,
    "critical": $CRITICAL_LEAKS,
    "high": $HIGH_LEAKS,
    "medium": $MEDIUM_LEAKS,
    "low": $LOW_LEAKS,
    "info": $INFO_LEAKS
  },
  "severity_distribution": {
    "CRITICAL": $CRITICAL_LEAKS,
    "HIGH": $HIGH_LEAKS,
    "MEDIUM": $MEDIUM_LEAKS,
    "LOW": $LOW_LEAKS,
    "INFO": $INFO_LEAKS
  },
  "status": $([ $TOTAL_LEAKS_FOUND -eq 0 ] && echo '"clean"' || echo '"leaks_found"'),
  "exit_code": $([ $TOTAL_LEAKS_FOUND -eq 0 ] && echo 0 || echo 1)
}
EOF

    success "JSON report saved to: $output_file"
}

# Print scan summary
print_summary() {
    echo ""
    info "========================================="
    info "Secret Leak Scan Summary"
    info "========================================="
    info "Files scanned: $TOTAL_FILES_SCANNED"
    info "Total findings: $TOTAL_LEAKS_FOUND"

    if [[ $CRITICAL_LEAKS -gt 0 ]]; then
        print_severity "$SEVERITY_CRITICAL" "Critical: $CRITICAL_LEAKS"
    fi
    if [[ $HIGH_LEAKS -gt 0 ]]; then
        print_severity "$SEVERITY_HIGH" "High: $HIGH_LEAKS"
    fi
    if [[ $MEDIUM_LEAKS -gt 0 ]]; then
        print_severity "$SEVERITY_MEDIUM" "Medium: $MEDIUM_LEAKS"
    fi
    if [[ $LOW_LEAKS -gt 0 ]]; then
        print_severity "$SEVERITY_LOW" "Low: $LOW_LEAKS"
    fi
    if [[ $INFO_LEAKS -gt 0 ]]; then
        print_severity "$SEVERITY_INFO" "Info: $INFO_LEAKS"
    fi

    info "========================================="

    if [[ $TOTAL_LEAKS_FOUND -eq 0 ]]; then
        success "No potential leaks detected!"
    else
        error "Potential secrets found! Review and rotate affected credentials immediately."
        info "Recommendations:"
        info "  1. Remove secrets from code and use environment variables"
        info "  2. Use GitHub Secrets for sensitive values in workflows"
        info "  3. Rotate any exposed credentials immediately"
        info "  4. Add pre-commit hooks to prevent future leaks"
        info "  5. Consider using tools like git-secrets or truffleHog"
    fi
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    local recursive=false
    local output_file=""
    local json_output=false
    local min_severity="$SEVERITY_INFO"
    local exclude_pattern=""
    local include_pattern=""
    local show_matches=false
    local ci_mode=false
    local target=""
    local scan_logs=false
    local workflow_run_id=""
    local repo=""

    # Parse arguments
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
            -o|--output)
                output_file="$2"
                shift 2
                ;;
            -j|--json)
                json_output=true
                shift
                ;;
            -s|--severity)
                min_severity="$2"
                shift 2
                ;;
            -e|--exclude)
                exclude_pattern="$2"
                shift 2
                ;;
            -i|--include)
                include_pattern="$2"
                shift 2
                ;;
            --show-matches)
                show_matches=true
                shift
                ;;
            --ci)
                ci_mode=true
                shift
                ;;
            --scan-logs)
                scan_logs=true
                workflow_run_id="$2"
                shift 2
                ;;
            --repo)
                repo="$2"
                shift 2
                ;;
            *)
                target="$1"
                shift
                ;;
        esac
    done

    # Default target
    if [[ -z "$target" ]] && [[ "$scan_logs" != "true" ]]; then
        target="."
    fi

    # Scan workflow logs if requested
    if [[ "$scan_logs" == "true" ]]; then
        scan_workflow_logs "$workflow_run_id" "$repo"
    elif [[ -f "$target" ]]; then
        # Single file scan
        scan_file "$target" "$min_severity" "$show_matches"
    elif [[ -d "$target" ]]; then
        # Directory scan
        if [[ "$recursive" == "true" ]]; then
            while IFS= read -r -d '' file; do
                # Check if should exclude
                if should_exclude "$file" "$exclude_pattern"; then
                    continue
                fi

                # Check include pattern
                if [[ -n "$include_pattern" ]] && [[ ! "$file" == $include_pattern ]]; then
                    continue
                fi

                scan_file "$file" "$min_severity" "$show_matches"
            done < <(find "$target" -type f -print0 2>/dev/null)
        else
            for file in "$target"/*; do
                [[ -f "$file" ]] && scan_file "$file" "$min_severity" "$show_matches"
            done
        fi
    else
        error "Target not found: $target"
        exit $EXIT_ERROR
    fi

    # Generate output
    if [[ "$json_output" == "true" ]] && [[ -n "$output_file" ]]; then
        generate_json_report "$output_file"
    fi

    # Print summary unless CI mode with JSON
    if [[ "$ci_mode" != "true" ]] || [[ "$json_output" != "true" ]]; then
        print_summary
    fi

    # Exit based on findings
    if [[ $TOTAL_LEAKS_FOUND -gt 0 ]]; then
        exit $EXIT_LEAK_FOUND
    else
        exit $EXIT_SUCCESS
    fi
}

# Run main
main "$@"
