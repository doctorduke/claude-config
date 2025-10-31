#!/usr/bin/env bash
#
# runner-status-dashboard.sh - Real-Time GitHub Actions Runner Status Dashboard
#
# Description:
#   Text-based dashboard showing all runners, job queue status, and recent
#   workflow runs. Provides real-time monitoring with auto-refresh capability.
#
# Usage:
#   ./runner-status-dashboard.sh [OPTIONS]
#
# Options:
#   --org OWNER        GitHub organization or user (required for API calls)
#   --refresh N        Auto-refresh interval in seconds (default: 30, 0=no refresh)
#   --compact          Compact view with less details
#   --json             Output in JSON format (disables auto-refresh)
#   --no-color         Disable colored output
#   --runner-dir DIR   Base runner directory (default: $HOME/actions-runner)
#   --help             Display this help message
#
# Examples:
#   ./runner-status-dashboard.sh --org myorg                    # Live dashboard
#   ./runner-status-dashboard.sh --org myorg --refresh 10       # Refresh every 10s
#   ./runner-status-dashboard.sh --org myorg --compact          # Compact view
#   ./runner-status-dashboard.sh --org myorg --json             # JSON output
#
# Requirements:
#   - GitHub CLI (gh) installed and authenticated, OR
#   - GITHUB_TOKEN environment variable set
#

set -euo pipefail

# ============================================================================
# Configuration and Defaults
# ============================================================================

GITHUB_ORG="${GITHUB_ORG:-}"
RUNNER_DIR_BASE="${RUNNER_DIR_BASE:-$HOME/actions-runner}"
REFRESH_INTERVAL=30
COMPACT_VIEW=false
JSON_OUTPUT=false
USE_COLOR=true

# API endpoints
GITHUB_API="${GITHUB_API:-https://api.github.com}"

# Colors
setup_colors() {
    if [ "$USE_COLOR" = true ] && [ -t 1 ]; then
        RED='\033[0;31m'
        YELLOW='\033[1;33m'
        GREEN='\033[0;32m'
        BLUE='\033[0;34m'
        CYAN='\033[0;36m'
        MAGENTA='\033[0;35m'
        BOLD='\033[1m'
        DIM='\033[2m'
        NC='\033[0m'
    else
        RED=''
        YELLOW=''
        GREEN=''
        BLUE=''
        CYAN=''
        MAGENTA=''
        BOLD=''
        DIM=''
        NC=''
    fi
}

setup_colors

# ============================================================================
# Helper Functions
# ============================================================================

usage() {
    grep '^#' "$0" | grep -v '#!/usr/bin/env' | sed 's/^# //' | sed 's/^#//'
    exit 0
}

clear_screen() {
    if [ "$JSON_OUTPUT" = false ] && [ -t 1 ]; then
        clear
    fi
}

print_header() {
    if [ "$JSON_OUTPUT" = false ]; then
        echo -e "${CYAN}${BOLD}$1${NC}"
        echo -e "${CYAN}$(printf '%*s' ${#1} '' | tr ' ' '=')${NC}"
    fi
}

print_subheader() {
    if [ "$JSON_OUTPUT" = false ]; then
        echo -e "\n${BOLD}$1${NC}"
        echo -e "$(printf '%*s' ${#1} '' | tr ' ' '-')"
    fi
}

format_timestamp() {
    local timestamp="$1"
    if command -v date >/dev/null 2>&1; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            date -j -f "%Y-%m-%dT%H:%M:%SZ" "$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$timestamp"
        else
            date -d "$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$timestamp"
        fi
    else
        echo "$timestamp"
    fi
}

format_duration() {
    local seconds="$1"
    if [ "$seconds" -lt 60 ]; then
        echo "${seconds}s"
    elif [ "$seconds" -lt 3600 ]; then
        echo "$((seconds / 60))m $((seconds % 60))s"
    else
        echo "$((seconds / 3600))h $((seconds % 3600 / 60))m"
    fi
}

status_icon() {
    local status="$1"
    case "$status" in
        online|active|success|completed)
            echo -e "${GREEN}●${NC}"
            ;;
        offline|inactive|failure|failed)
            echo -e "${RED}●${NC}"
            ;;
        idle|waiting|queued|pending)
            echo -e "${YELLOW}●${NC}"
            ;;
        running|in_progress)
            echo -e "${BLUE}●${NC}"
            ;;
        *)
            echo -e "${DIM}○${NC}"
            ;;
    esac
}

# ============================================================================
# API Functions
# ============================================================================

check_github_auth() {
    # Check if gh CLI is available and authenticated
    if command -v gh >/dev/null 2>&1; then
        if gh auth status >/dev/null 2>&1; then
            return 0
        fi
    fi

    # Check for GITHUB_TOKEN
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        return 0
    fi

    echo -e "${RED}Error: GitHub authentication required${NC}"
    echo ""
    echo "Please either:"
    echo "  1. Install and authenticate GitHub CLI: gh auth login"
    echo "  2. Set GITHUB_TOKEN environment variable"
    echo ""
    exit 1
}

api_call() {
    local endpoint="$1"
    local method="${2:-GET}"

    if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
        gh api "$endpoint" --method "$method" 2>/dev/null || echo "{}"
    elif [ -n "${GITHUB_TOKEN:-}" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $GITHUB_TOKEN" \
            -H "Accept: application/vnd.github+json" \
            "${GITHUB_API}${endpoint}" 2>/dev/null || echo "{}"
    else
        echo "{}"
    fi
}

# ============================================================================
# Data Collection Functions
# ============================================================================

get_local_runners() {
    local runners=()
    local i=1

    # Find all runner directories
    while [ -d "${RUNNER_DIR_BASE}-${i}" ] || [ -d "${RUNNER_DIR_BASE}" ]; do
        local runner_dir=""
        if [ -d "${RUNNER_DIR_BASE}-${i}" ]; then
            runner_dir="${RUNNER_DIR_BASE}-${i}"
        elif [ -d "${RUNNER_DIR_BASE}" ] && [ $i -eq 1 ]; then
            runner_dir="${RUNNER_DIR_BASE}"
        else
            break
        fi

        if [ -f "$runner_dir/.runner" ]; then
            local runner_data=""
            if command -v jq >/dev/null 2>&1; then
                runner_data=$(cat "$runner_dir/.runner" 2>/dev/null | jq -c '.' || echo "{}")
            else
                runner_data="{\"path\":\"$runner_dir\"}"
            fi

            # Check if service is running
            local status="unknown"
            local runner_name=""

            if command -v jq >/dev/null 2>&1; then
                runner_name=$(echo "$runner_data" | jq -r '.agentName // "unknown"')
            fi

            if systemctl is-active --quiet "actions.runner.*${runner_name}.service" 2>/dev/null; then
                status="online"
            elif pgrep -f "Runner.Listener.*${runner_name}" >/dev/null 2>&1; then
                status="online"
            else
                status="offline"
            fi

            runners+=("{\"name\":\"$runner_name\",\"path\":\"$runner_dir\",\"status\":\"$status\",\"data\":$runner_data}")
        fi

        ((i++))
    done

    printf '%s\n' "${runners[@]}" | jq -s '.' 2>/dev/null || echo "[]"
}

get_org_runners() {
    if [ -z "$GITHUB_ORG" ]; then
        echo "[]"
        return
    fi

    local response
    response=$(api_call "/orgs/$GITHUB_ORG/actions/runners?per_page=100")

    if command -v jq >/dev/null 2>&1; then
        echo "$response" | jq '.runners // []' 2>/dev/null || echo "[]"
    else
        echo "[]"
    fi
}

get_workflow_runs() {
    if [ -z "$GITHUB_ORG" ]; then
        echo "[]"
        return
    fi

    # Get repos in org (limited to 10 most active)
    local repos
    repos=$(api_call "/orgs/$GITHUB_ORG/repos?sort=updated&per_page=10")

    local all_runs="[]"

    if command -v jq >/dev/null 2>&1; then
        local repo_names
        repo_names=$(echo "$repos" | jq -r '.[].name' 2>/dev/null || echo "")

        for repo in $repo_names; do
            local runs
            runs=$(api_call "/repos/$GITHUB_ORG/$repo/actions/runs?per_page=5")
            local repo_runs
            repo_runs=$(echo "$runs" | jq ".workflow_runs // [] | map(. + {repo: \"$repo\"})" 2>/dev/null || echo "[]")

            all_runs=$(echo "$all_runs $repo_runs" | jq -s 'add | sort_by(.created_at) | reverse | .[0:10]' 2>/dev/null || echo "[]")
        done
    fi

    echo "$all_runs"
}

get_job_queue() {
    if [ -z "$GITHUB_ORG" ]; then
        echo "[]"
        return
    fi

    # Get pending jobs from workflow runs
    local runs
    runs=$(api_call "/orgs/$GITHUB_ORG/actions/runs?status=queued&per_page=20")

    if command -v jq >/dev/null 2>&1; then
        echo "$runs" | jq '.workflow_runs // []' 2>/dev/null || echo "[]"
    else
        echo "[]"
    fi
}

# ============================================================================
# Display Functions
# ============================================================================

display_runner_status() {
    local local_runners="$1"
    local org_runners="$2"

    print_subheader "Self-Hosted Runners"

    if ! command -v jq >/dev/null 2>&1; then
        echo "  (jq not installed - limited data available)"
        return
    fi

    local runner_count
    runner_count=$(echo "$local_runners" | jq 'length')

    if [ "$runner_count" -eq 0 ]; then
        echo "  No local runners found"
        echo "  Check: $RUNNER_DIR_BASE"
        return
    fi

    # Table header
    if [ "$COMPACT_VIEW" = false ]; then
        printf "  ${BOLD}%-20s %-10s %-15s %-30s${NC}\n" "NAME" "STATUS" "ID" "LABELS"
        echo "  $(printf '%*s' 75 '' | tr ' ' '-')"
    fi

    # Merge local and org runner data
    local i=0
    while [ $i -lt "$runner_count" ]; do
        local runner
        runner=$(echo "$local_runners" | jq -r ".[$i]")

        local name
        local status
        local runner_id=""
        local labels=""

        name=$(echo "$runner" | jq -r '.name // "unknown"')
        status=$(echo "$runner" | jq -r '.status // "unknown"')

        # Find matching org runner
        local org_runner
        org_runner=$(echo "$org_runners" | jq -r ".[] | select(.name == \"$name\") // {}" 2>/dev/null || echo "{}")

        if [ "$org_runner" != "{}" ]; then
            runner_id=$(echo "$org_runner" | jq -r '.id // ""')
            labels=$(echo "$org_runner" | jq -r '.labels[]?.name // empty' | tr '\n' ',' | sed 's/,$//')
            status=$(echo "$org_runner" | jq -r '.status // "unknown"')
        fi

        local icon
        icon=$(status_icon "$status")

        if [ "$COMPACT_VIEW" = false ]; then
            printf "  %-20s %b %-9s %-15s %-30s\n" "$name" "$icon" "$status" "${runner_id:-N/A}" "${labels:-N/A}"
        else
            printf "  %b %s (%s)\n" "$icon" "$name" "$status"
        fi

        ((i++))
    done

    echo ""
    echo "  Total Runners: $runner_count"

    # Count by status
    if [ "$COMPACT_VIEW" = false ]; then
        local online_count
        local offline_count
        online_count=$(echo "$local_runners" | jq '[.[] | select(.status == "online")] | length')
        offline_count=$(echo "$local_runners" | jq '[.[] | select(.status == "offline")] | length')

        echo -e "  ${GREEN}Online: $online_count${NC} | ${RED}Offline: $offline_count${NC}"
    fi
}

display_job_queue() {
    local queue_jobs="$1"

    print_subheader "Job Queue"

    if ! command -v jq >/dev/null 2>&1; then
        echo "  (jq not installed - skipping)"
        return
    fi

    local job_count
    job_count=$(echo "$queue_jobs" | jq 'length')

    if [ "$job_count" -eq 0 ]; then
        echo "  No jobs in queue"
        return
    fi

    if [ "$COMPACT_VIEW" = false ]; then
        printf "  ${BOLD}%-40s %-15s %-20s${NC}\n" "WORKFLOW" "STATUS" "QUEUED AT"
        echo "  $(printf '%*s' 75 '' | tr ' ' '-')"
    fi

    local i=0
    while [ $i -lt "$job_count" ] && [ $i -lt 10 ]; do
        local job
        job=$(echo "$queue_jobs" | jq -r ".[$i]")

        local workflow
        local status
        local created_at

        workflow=$(echo "$job" | jq -r '.name // "unknown"' | cut -c1-40)
        status=$(echo "$job" | jq -r '.status // "unknown"')
        created_at=$(echo "$job" | jq -r '.created_at // "unknown"')

        local formatted_time
        formatted_time=$(format_timestamp "$created_at")

        local icon
        icon=$(status_icon "$status")

        if [ "$COMPACT_VIEW" = false ]; then
            printf "  %-40s %b %-14s %-20s\n" "$workflow" "$icon" "$status" "$formatted_time"
        else
            printf "  %b %s\n" "$icon" "$workflow"
        fi

        ((i++))
    done

    echo ""
    echo "  Queued Jobs: $job_count"
}

display_recent_workflows() {
    local workflow_runs="$1"

    print_subheader "Recent Workflow Runs"

    if ! command -v jq >/dev/null 2>&1; then
        echo "  (jq not installed - skipping)"
        return
    fi

    local run_count
    run_count=$(echo "$workflow_runs" | jq 'length')

    if [ "$run_count" -eq 0 ]; then
        echo "  No recent workflow runs"
        return
    fi

    if [ "$COMPACT_VIEW" = false ]; then
        printf "  ${BOLD}%-30s %-15s %-15s %-15s${NC}\n" "WORKFLOW" "STATUS" "CONCLUSION" "DURATION"
        echo "  $(printf '%*s' 75 '' | tr ' ' '-')"
    fi

    local success=0
    local failed=0
    local i=0

    while [ $i -lt "$run_count" ] && [ $i -lt 10 ]; do
        local run
        run=$(echo "$workflow_runs" | jq -r ".[$i]")

        local workflow
        local status
        local conclusion
        local created_at
        local updated_at

        workflow=$(echo "$run" | jq -r '.name // "unknown"' | cut -c1-30)
        status=$(echo "$run" | jq -r '.status // "unknown"')
        conclusion=$(echo "$run" | jq -r '.conclusion // "N/A"')
        created_at=$(echo "$run" | jq -r '.created_at // "unknown"')
        updated_at=$(echo "$run" | jq -r '.updated_at // "unknown"')

        # Calculate duration
        local duration="N/A"
        if [ "$created_at" != "unknown" ] && [ "$updated_at" != "unknown" ]; then
            if command -v date >/dev/null 2>&1; then
                local start_ts
                local end_ts
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    start_ts=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$created_at" "+%s" 2>/dev/null || echo 0)
                    end_ts=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$updated_at" "+%s" 2>/dev/null || echo 0)
                else
                    start_ts=$(date -d "$created_at" "+%s" 2>/dev/null || echo 0)
                    end_ts=$(date -d "$updated_at" "+%s" 2>/dev/null || echo 0)
                fi
                local diff=$((end_ts - start_ts))
                if [ $diff -gt 0 ]; then
                    duration=$(format_duration $diff)
                fi
            fi
        fi

        # Count success/failure
        if [ "$conclusion" = "success" ]; then
            ((success++))
        elif [ "$conclusion" = "failure" ]; then
            ((failed++))
        fi

        local icon
        icon=$(status_icon "$conclusion")

        if [ "$COMPACT_VIEW" = false ]; then
            printf "  %-30s %b %-14s %-15s %-15s\n" "$workflow" "$icon" "$status" "$conclusion" "$duration"
        else
            printf "  %b %s (%s)\n" "$icon" "$workflow" "$conclusion"
        fi

        ((i++))
    done

    echo ""
    if [ "$run_count" -gt 0 ]; then
        local success_rate=$((success * 100 / run_count))
        echo -e "  Success Rate: ${GREEN}$success_rate%${NC} ($success/$run_count)"
    fi
}

display_system_info() {
    print_subheader "System Information"

    echo "  Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"

    if [ -n "$GITHUB_ORG" ]; then
        echo "  Organization: $GITHUB_ORG"
    fi

    echo "  Runner Base Dir: $RUNNER_DIR_BASE"

    # System load
    if [ -f /proc/loadavg ]; then
        local load
        load=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
        echo "  Load Average: $load"
    fi

    # Memory
    if command -v free >/dev/null 2>&1; then
        local mem_used
        local mem_total
        mem_used=$(free -h | grep Mem: | awk '{print $3}')
        mem_total=$(free -h | grep Mem: | awk '{print $2}')
        echo "  Memory: $mem_used / $mem_total"
    fi
}

# ============================================================================
# JSON Output
# ============================================================================

output_json() {
    local local_runners="$1"
    local org_runners="$2"
    local workflow_runs="$3"
    local job_queue="$4"

    cat <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "organization": "$GITHUB_ORG",
  "local_runners": $local_runners,
  "org_runners": $org_runners,
  "workflow_runs": $workflow_runs,
  "job_queue": $job_queue
}
EOF
}

# ============================================================================
# Main Display Loop
# ============================================================================

display_dashboard() {
    # Collect data
    local local_runners
    local org_runners
    local workflow_runs
    local job_queue

    local_runners=$(get_local_runners)
    org_runners=$(get_org_runners)
    workflow_runs=$(get_workflow_runs)
    job_queue=$(get_job_queue)

    if [ "$JSON_OUTPUT" = true ]; then
        output_json "$local_runners" "$org_runners" "$workflow_runs" "$job_queue"
        return
    fi

    # Display dashboard
    clear_screen

    print_header "GitHub Actions Runner Dashboard"
    echo ""

    display_system_info
    display_runner_status "$local_runners" "$org_runners"
    display_job_queue "$job_queue"
    display_recent_workflows "$workflow_runs"

    if [ "$REFRESH_INTERVAL" -gt 0 ]; then
        echo ""
        echo -e "${DIM}Auto-refresh in ${REFRESH_INTERVAL}s (Ctrl+C to exit)${NC}"
    fi
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --org)
                GITHUB_ORG="$2"
                shift 2
                ;;
            --refresh)
                REFRESH_INTERVAL="$2"
                shift 2
                ;;
            --compact)
                COMPACT_VIEW=true
                shift
                ;;
            --json)
                JSON_OUTPUT=true
                REFRESH_INTERVAL=0
                shift
                ;;
            --no-color)
                USE_COLOR=false
                setup_colors
                shift
                ;;
            --runner-dir)
                RUNNER_DIR_BASE="$2"
                shift 2
                ;;
            --help|-h)
                usage
                ;;
            *)
                echo "Unknown option: $1"
                usage
                ;;
        esac
    done

    # Check GitHub authentication
    check_github_auth

    # Validate refresh interval
    if ! [[ "$REFRESH_INTERVAL" =~ ^[0-9]+$ ]]; then
        echo "Error: Refresh interval must be a number"
        exit 1
    fi

    # Main loop
    if [ "$REFRESH_INTERVAL" -gt 0 ]; then
        while true; do
            display_dashboard
            sleep "$REFRESH_INTERVAL"
        done
    else
        display_dashboard
    fi
}

# Run main function
main "$@"
