#!/bin/bash
#
# GitHub Actions Runner Queue Depth Monitor
#
# Monitors queue depth, runner utilization, and alerts on capacity issues
# Exports metrics in multiple formats for dashboard consumption
#
# Usage:
#   ./monitor-queue-depth.sh [OPTIONS]
#
# Options:
#   --repo OWNER/NAME       Repository to monitor (default: from git remote)
#   --org ORG              Organization to monitor runners (default: from repo)
#   --format FORMAT        Output format: json|prometheus|csv|text (default: json)
#   --alerts               Enable alerting (default: off)
#   --log FILE             Log file path (default: /var/log/github-runner-queue.log)
#   --webhook URL          Webhook URL for alerts (Slack/Discord compatible)
#   --output FILE          Output file for metrics (default: stdout)
#   --help                 Show this help message

set -euo pipefail

# Configuration
REPO="${GITHUB_REPOSITORY:-}"
ORG=""
FORMAT="json"
ENABLE_ALERTS=false
LOG_FILE="/var/log/github-runner-queue.log"
WEBHOOK_URL=""
OUTPUT_FILE=""
METRICS_DIR="${METRICS_DIR:-./metrics}"

# Alerting thresholds
QUEUE_DEPTH_WARNING="${QUEUE_DEPTH_WARNING:-5}"
QUEUE_DEPTH_CRITICAL="${QUEUE_DEPTH_CRITICAL:-10}"
UTILIZATION_WARNING="${UTILIZATION_WARNING:-80}"
UTILIZATION_CRITICAL="${UTILIZATION_CRITICAL:-95}"
WAIT_TIME_WARNING="${WAIT_TIME_WARNING:-300}"     # 5 minutes
WAIT_TIME_CRITICAL="${WAIT_TIME_CRITICAL:-600}"   # 10 minutes

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --repo)
                REPO="$2"
                shift 2
                ;;
            --org)
                ORG="$2"
                shift 2
                ;;
            --format)
                FORMAT="$2"
                shift 2
                ;;
            --alerts)
                ENABLE_ALERTS=true
                shift
                ;;
            --log)
                LOG_FILE="$2"
                shift 2
                ;;
            --webhook)
                WEBHOOK_URL="$2"
                shift 2
                ;;
            --output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            --help)
                grep '^#' "$0" | grep -v '#!/bin/bash' | sed 's/^# //' | sed 's/^#//'
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

# Initialize log file
init_logging() {
    local log_dir=$(dirname "$LOG_FILE")
    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir" 2>/dev/null || LOG_FILE="./github-runner-queue.log"
    fi
    if [[ ! -f "$LOG_FILE" ]]; then
        touch "$LOG_FILE" 2>/dev/null || LOG_FILE="./github-runner-queue.log"
    fi
}

# Log message
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "$timestamp [$level] $message" >> "$LOG_FILE"
}

# Detect repository from git remote
detect_repo() {
    if [[ -z "$REPO" ]]; then
        if git rev-parse --git-dir > /dev/null 2>&1; then
            local remote_url=$(git config --get remote.origin.url || echo "")
            if [[ $remote_url =~ github\.com[:/]([^/]+/[^/]+)(\.git)?$ ]]; then
                REPO="${BASH_REMATCH[1]}"
            fi
        fi
    fi

    if [[ -z "$REPO" ]]; then
        echo "Error: Repository not specified and cannot be detected from git remote" >&2
        echo "Use --repo OWNER/NAME" >&2
        exit 1
    fi

    # Extract org from repo if not specified
    if [[ -z "$ORG" ]]; then
        ORG="${REPO%%/*}"
    fi
}

# Check if gh CLI is installed and authenticated
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        echo "Error: gh CLI is not installed" >&2
        echo "Install from: https://cli.github.com/" >&2
        exit 1
    fi

    if ! gh auth status &> /dev/null; then
        echo "Error: gh CLI is not authenticated" >&2
        echo "Run: gh auth login" >&2
        exit 1
    fi
}

# Get queue metrics from GitHub API
get_queue_metrics() {
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Query workflow runs (queued and in_progress)
    local workflow_runs=$(gh api "repos/$REPO/actions/runs?status=queued&per_page=100" --jq '.workflow_runs' 2>/dev/null || echo "[]")
    local pending=$(echo "$workflow_runs" | jq 'length')

    local in_progress_runs=$(gh api "repos/$REPO/actions/runs?status=in_progress&per_page=100" --jq '.workflow_runs' 2>/dev/null || echo "[]")
    local in_progress=$(echo "$in_progress_runs" | jq 'length')

    # Calculate wait times for queued runs
    local max_wait_time=0
    local avg_wait_time=0
    if [[ $pending -gt 0 ]]; then
        local wait_times=$(echo "$workflow_runs" | jq -r '.[].created_at' | while read created; do
            local created_epoch=$(date -d "$created" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$created" +%s 2>/dev/null || echo 0)
            local now_epoch=$(date +%s)
            echo $((now_epoch - created_epoch))
        done)

        if [[ -n "$wait_times" ]]; then
            max_wait_time=$(echo "$wait_times" | sort -nr | head -1)
            avg_wait_time=$(echo "$wait_times" | awk '{sum+=$1; count++} END {if(count>0) print int(sum/count); else print 0}')
        fi
    fi

    # Query runners (self-hosted runners)
    local runners=$(gh api "repos/$REPO/actions/runners?per_page=100" --jq '.runners' 2>/dev/null || echo "[]")
    local available=$(echo "$runners" | jq '[.[] | select(.status=="online" and .busy==false)] | length')
    local busy=$(echo "$runners" | jq '[.[] | select(.busy==true)] | length')
    local offline=$(echo "$runners" | jq '[.[] | select(.status=="offline")] | length')
    local total_runners=$(echo "$runners" | jq 'length')

    # Calculate utilization
    local online_runners=$((busy + available))
    local utilization=0
    if [[ $online_runners -gt 0 ]]; then
        utilization=$((busy * 100 / online_runners))
    fi

    # Queue depth is the number of pending workflows
    local queue_depth=$pending

    # Calculate capacity (runners that could accept work)
    local capacity=$available

    # Determine health status
    local status="healthy"
    if [[ $queue_depth -ge $QUEUE_DEPTH_CRITICAL ]] || [[ $utilization -ge $UTILIZATION_CRITICAL ]] || [[ $max_wait_time -ge $WAIT_TIME_CRITICAL ]]; then
        status="critical"
    elif [[ $queue_depth -ge $QUEUE_DEPTH_WARNING ]] || [[ $utilization -ge $UTILIZATION_WARNING ]] || [[ $max_wait_time -ge $WAIT_TIME_WARNING ]]; then
        status="warning"
    fi

    # Output JSON
    cat <<EOF
{
    "timestamp": "$timestamp",
    "repository": "$REPO",
    "organization": "$ORG",
    "workflows": {
        "pending": $pending,
        "in_progress": $in_progress,
        "total_active": $((pending + in_progress))
    },
    "runners": {
        "total": $total_runners,
        "online": $online_runners,
        "available": $available,
        "busy": $busy,
        "offline": $offline
    },
    "metrics": {
        "queue_depth": $queue_depth,
        "utilization_percent": $utilization,
        "capacity": $capacity,
        "max_wait_time_seconds": $max_wait_time,
        "avg_wait_time_seconds": $avg_wait_time
    },
    "status": "$status",
    "thresholds": {
        "queue_depth_warning": $QUEUE_DEPTH_WARNING,
        "queue_depth_critical": $QUEUE_DEPTH_CRITICAL,
        "utilization_warning": $UTILIZATION_WARNING,
        "utilization_critical": $UTILIZATION_CRITICAL,
        "wait_time_warning": $WAIT_TIME_WARNING,
        "wait_time_critical": $WAIT_TIME_CRITICAL
    }
}
EOF
}

# Export metrics in Prometheus format
export_prometheus() {
    local metrics_json=$1

    local pending=$(echo "$metrics_json" | jq -r '.workflows.pending')
    local in_progress=$(echo "$metrics_json" | jq -r '.workflows.in_progress')
    local available=$(echo "$metrics_json" | jq -r '.runners.available')
    local busy=$(echo "$metrics_json" | jq -r '.runners.busy')
    local offline=$(echo "$metrics_json" | jq -r '.runners.offline')
    local queue_depth=$(echo "$metrics_json" | jq -r '.metrics.queue_depth')
    local utilization=$(echo "$metrics_json" | jq -r '.metrics.utilization_percent')
    local max_wait=$(echo "$metrics_json" | jq -r '.metrics.max_wait_time_seconds')
    local avg_wait=$(echo "$metrics_json" | jq -r '.metrics.avg_wait_time_seconds')

    cat <<EOF
# HELP github_actions_workflows_pending Number of pending workflow runs
# TYPE github_actions_workflows_pending gauge
github_actions_workflows_pending{repo="$REPO"} $pending

# HELP github_actions_workflows_in_progress Number of in-progress workflow runs
# TYPE github_actions_workflows_in_progress gauge
github_actions_workflows_in_progress{repo="$REPO"} $in_progress

# HELP github_actions_runners_available Number of available runners
# TYPE github_actions_runners_available gauge
github_actions_runners_available{org="$ORG",repo="$REPO"} $available

# HELP github_actions_runners_busy Number of busy runners
# TYPE github_actions_runners_busy gauge
github_actions_runners_busy{org="$ORG",repo="$REPO"} $busy

# HELP github_actions_runners_offline Number of offline runners
# TYPE github_actions_runners_offline gauge
github_actions_runners_offline{org="$ORG",repo="$REPO"} $offline

# HELP github_actions_queue_depth Number of queued workflow runs
# TYPE github_actions_queue_depth gauge
github_actions_queue_depth{repo="$REPO"} $queue_depth

# HELP github_actions_runner_utilization Runner utilization percentage
# TYPE github_actions_runner_utilization gauge
github_actions_runner_utilization{org="$ORG",repo="$REPO"} $utilization

# HELP github_actions_max_wait_time_seconds Maximum wait time for queued workflows
# TYPE github_actions_max_wait_time_seconds gauge
github_actions_max_wait_time_seconds{repo="$REPO"} $max_wait

# HELP github_actions_avg_wait_time_seconds Average wait time for queued workflows
# TYPE github_actions_avg_wait_time_seconds gauge
github_actions_avg_wait_time_seconds{repo="$REPO"} $avg_wait
EOF
}

# Export metrics in CSV format
export_csv() {
    local metrics_json=$1
    local include_header=${2:-false}

    local timestamp=$(echo "$metrics_json" | jq -r '.timestamp')
    local pending=$(echo "$metrics_json" | jq -r '.workflows.pending')
    local in_progress=$(echo "$metrics_json" | jq -r '.workflows.in_progress')
    local available=$(echo "$metrics_json" | jq -r '.runners.available')
    local busy=$(echo "$metrics_json" | jq -r '.runners.busy')
    local offline=$(echo "$metrics_json" | jq -r '.runners.offline')
    local queue_depth=$(echo "$metrics_json" | jq -r '.metrics.queue_depth')
    local utilization=$(echo "$metrics_json" | jq -r '.metrics.utilization_percent')
    local max_wait=$(echo "$metrics_json" | jq -r '.metrics.max_wait_time_seconds')
    local avg_wait=$(echo "$metrics_json" | jq -r '.metrics.avg_wait_time_seconds')
    local status=$(echo "$metrics_json" | jq -r '.status')

    if [[ "$include_header" == "true" ]]; then
        echo "timestamp,repo,pending,in_progress,available,busy,offline,queue_depth,utilization,max_wait,avg_wait,status"
    fi

    echo "$timestamp,$REPO,$pending,$in_progress,$available,$busy,$offline,$queue_depth,$utilization,$max_wait,$avg_wait,$status"
}

# Export metrics in human-readable text format
export_text() {
    local metrics_json=$1

    local timestamp=$(echo "$metrics_json" | jq -r '.timestamp')
    local pending=$(echo "$metrics_json" | jq -r '.workflows.pending')
    local in_progress=$(echo "$metrics_json" | jq -r '.workflows.in_progress')
    local available=$(echo "$metrics_json" | jq -r '.runners.available')
    local busy=$(echo "$metrics_json" | jq -r '.runners.busy')
    local offline=$(echo "$metrics_json" | jq -r '.runners.offline')
    local total=$(echo "$metrics_json" | jq -r '.runners.total')
    local queue_depth=$(echo "$metrics_json" | jq -r '.metrics.queue_depth')
    local utilization=$(echo "$metrics_json" | jq -r '.metrics.utilization_percent')
    local max_wait=$(echo "$metrics_json" | jq -r '.metrics.max_wait_time_seconds')
    local avg_wait=$(echo "$metrics_json" | jq -r '.metrics.avg_wait_time_seconds')
    local status=$(echo "$metrics_json" | jq -r '.status')

    # Status color
    local status_color=$GREEN
    case $status in
        warning) status_color=$YELLOW ;;
        critical) status_color=$RED ;;
    esac

    echo -e "${BLUE}=== GitHub Actions Queue Monitor ===${NC}"
    echo "Repository: $REPO"
    echo "Timestamp: $timestamp"
    echo ""
    echo -e "${BLUE}Workflows:${NC}"
    echo "  Pending:     $pending"
    echo "  In Progress: $in_progress"
    echo "  Total Active: $((pending + in_progress))"
    echo ""
    echo -e "${BLUE}Runners:${NC}"
    echo "  Total:     $total"
    echo "  Available: $available"
    echo "  Busy:      $busy"
    echo "  Offline:   $offline"
    echo ""
    echo -e "${BLUE}Metrics:${NC}"
    echo "  Queue Depth:  $queue_depth"
    echo "  Utilization:  $utilization%"
    echo "  Max Wait:     ${max_wait}s ($((max_wait / 60))m)"
    echo "  Avg Wait:     ${avg_wait}s ($((avg_wait / 60))m)"
    echo ""
    echo -e "Status: ${status_color}${status^^}${NC}"

    # ASCII chart for utilization
    if [[ $utilization -gt 0 ]]; then
        echo ""
        echo "Utilization Chart:"
        local bar_length=$((utilization / 2))
        printf "  ["
        for ((i=1; i<=50; i++)); do
            if [[ $i -le $bar_length ]]; then
                printf "#"
            else
                printf " "
            fi
        done
        printf "] %d%%\n" $utilization
    fi
}

# Send alert via webhook (Slack/Discord compatible)
send_webhook_alert() {
    local metrics_json=$1
    local status=$2

    if [[ -z "$WEBHOOK_URL" ]]; then
        return
    fi

    local queue_depth=$(echo "$metrics_json" | jq -r '.metrics.queue_depth')
    local utilization=$(echo "$metrics_json" | jq -r '.metrics.utilization_percent')
    local max_wait=$(echo "$metrics_json" | jq -r '.metrics.max_wait_time_seconds')
    local available=$(echo "$metrics_json" | jq -r '.runners.available')

    local color="good"
    local emoji=":white_check_mark:"
    if [[ "$status" == "warning" ]]; then
        color="warning"
        emoji=":warning:"
    elif [[ "$status" == "critical" ]]; then
        color="danger"
        emoji=":rotating_light:"
    fi

    local message="$emoji GitHub Actions Queue Alert: **$status**"
    message="$message\n\n**Repository:** \`$REPO\`"
    message="$message\n**Queue Depth:** $queue_depth"
    message="$message\n**Utilization:** ${utilization}%"
    message="$message\n**Max Wait Time:** ${max_wait}s ($((max_wait / 60))m)"
    message="$message\n**Available Runners:** $available"

    # Send to webhook (supports both Slack and Discord format)
    curl -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "{\"text\":\"$message\",\"color\":\"$color\"}" \
        --silent --output /dev/null || true
}

# Check thresholds and trigger alerts
check_alerts() {
    local metrics_json=$1

    if [[ "$ENABLE_ALERTS" != "true" ]]; then
        return
    fi

    local status=$(echo "$metrics_json" | jq -r '.status')
    local queue_depth=$(echo "$metrics_json" | jq -r '.metrics.queue_depth')
    local utilization=$(echo "$metrics_json" | jq -r '.metrics.utilization_percent')
    local max_wait=$(echo "$metrics_json" | jq -r '.metrics.max_wait_time_seconds')

    if [[ "$status" == "critical" ]]; then
        log "CRITICAL" "Queue depth=$queue_depth, Utilization=$utilization%, Max wait=${max_wait}s"
        send_webhook_alert "$metrics_json" "critical"
    elif [[ "$status" == "warning" ]]; then
        log "WARNING" "Queue depth=$queue_depth, Utilization=$utilization%, Max wait=${max_wait}s"
        send_webhook_alert "$metrics_json" "warning"
    else
        log "INFO" "Queue depth=$queue_depth, Utilization=$utilization%, Max wait=${max_wait}s"
    fi
}

# Save metrics to file for historical tracking
save_metrics() {
    local metrics_json=$1

    mkdir -p "$METRICS_DIR"

    # Save JSON with timestamp
    local timestamp=$(date +%Y%m%d-%H%M%S)
    echo "$metrics_json" > "$METRICS_DIR/queue-metrics-$timestamp.json"

    # Append to CSV log
    local csv_file="$METRICS_DIR/queue-metrics.csv"
    if [[ ! -f "$csv_file" ]]; then
        export_csv "$metrics_json" true > "$csv_file"
    else
        export_csv "$metrics_json" false >> "$csv_file"
    fi

    # Keep only last 7 days of JSON files
    find "$METRICS_DIR" -name "queue-metrics-*.json" -mtime +7 -delete 2>/dev/null || true
}

# Main function
main() {
    parse_args "$@"
    init_logging
    detect_repo
    check_gh_cli

    log "INFO" "Starting queue monitoring for $REPO"

    # Collect metrics
    local metrics_json=$(get_queue_metrics)

    # Check alerts
    check_alerts "$metrics_json"

    # Save metrics for historical tracking
    save_metrics "$metrics_json"

    # Output in requested format
    local output=""
    case $FORMAT in
        json)
            output="$metrics_json"
            ;;
        prometheus)
            output=$(export_prometheus "$metrics_json")
            ;;
        csv)
            output=$(export_csv "$metrics_json" true)
            ;;
        text)
            output=$(export_text "$metrics_json")
            ;;
        *)
            echo "Unknown format: $FORMAT" >&2
            exit 1
            ;;
    esac

    # Write output
    if [[ -n "$OUTPUT_FILE" ]]; then
        echo "$output" > "$OUTPUT_FILE"
        log "INFO" "Metrics written to $OUTPUT_FILE"
    else
        echo "$output"
    fi

    log "INFO" "Queue monitoring complete"
}

# Run main function
main "$@"
