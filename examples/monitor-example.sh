#!/bin/bash
#
# Example: Queue Monitoring Demonstration
#
# This example shows various ways to use the queue monitoring system

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MONITOR_SCRIPT="$PROJECT_ROOT/scripts/monitor-queue-depth.sh"
DASHBOARD_SCRIPT="$PROJECT_ROOT/scripts/generate-dashboard.sh"

echo "=== Queue Monitoring Examples ==="
echo ""

# Example 1: Basic monitoring (JSON format)
echo "Example 1: Basic JSON monitoring"
echo "Command: ./scripts/monitor-queue-depth.sh --format json"
echo ""
echo "This would output metrics in JSON format. For demonstration, here's sample output:"
cat <<'EOF'
{
    "timestamp": "2025-01-15T10:30:00Z",
    "repository": "owner/repo",
    "organization": "owner",
    "workflows": {
        "pending": 3,
        "in_progress": 5,
        "total_active": 8
    },
    "runners": {
        "total": 10,
        "online": 8,
        "available": 3,
        "busy": 5,
        "offline": 2
    },
    "metrics": {
        "queue_depth": 3,
        "utilization_percent": 62,
        "capacity": 3,
        "max_wait_time_seconds": 180,
        "avg_wait_time_seconds": 120
    },
    "status": "healthy",
    "thresholds": {
        "queue_depth_warning": 5,
        "queue_depth_critical": 10,
        "utilization_warning": 80,
        "utilization_critical": 95,
        "wait_time_warning": 300,
        "wait_time_critical": 600
    }
}
EOF
echo ""
echo "---"
echo ""

# Example 2: Text format (human-readable)
echo "Example 2: Human-readable text output"
echo "Command: ./scripts/monitor-queue-depth.sh --format text"
echo ""
echo "Sample output:"
cat <<'EOF'
=== GitHub Actions Queue Monitor ===
Repository: owner/repo
Timestamp: 2025-01-15T10:30:00Z

Workflows:
  Pending:     3
  In Progress: 5
  Total Active: 8

Runners:
  Total:     10
  Available: 3
  Busy:      5
  Offline:   2

Metrics:
  Queue Depth:  3
  Utilization:  62%
  Max Wait:     180s (3m)
  Avg Wait:     120s (2m)

Status: HEALTHY

Utilization Chart:
  [###############################                   ] 62%
EOF
echo ""
echo "---"
echo ""

# Example 3: Prometheus format
echo "Example 3: Prometheus format for metrics export"
echo "Command: ./scripts/monitor-queue-depth.sh --format prometheus"
echo ""
echo "Sample output:"
cat <<'EOF'
# HELP github_actions_workflows_pending Number of pending workflow runs
# TYPE github_actions_workflows_pending gauge
github_actions_workflows_pending{repo="owner/repo"} 3

# HELP github_actions_workflows_in_progress Number of in-progress workflow runs
# TYPE github_actions_workflows_in_progress gauge
github_actions_workflows_in_progress{repo="owner/repo"} 5

# HELP github_actions_queue_depth Number of queued workflow runs
# TYPE github_actions_queue_depth gauge
github_actions_queue_depth{repo="owner/repo"} 3

# HELP github_actions_runner_utilization Runner utilization percentage
# TYPE github_actions_runner_utilization gauge
github_actions_runner_utilization{org="owner",repo="owner/repo"} 62
EOF
echo ""
echo "---"
echo ""

# Example 4: CSV format for historical tracking
echo "Example 4: CSV format for historical analysis"
echo "Command: ./scripts/monitor-queue-depth.sh --format csv"
echo ""
echo "Sample output:"
cat <<'EOF'
timestamp,repo,pending,in_progress,available,busy,offline,queue_depth,utilization,max_wait,avg_wait,status
2025-01-15T10:30:00Z,owner/repo,3,5,3,5,2,3,62,180,120,healthy
EOF
echo ""
echo "---"
echo ""

# Example 5: Monitoring with alerts enabled
echo "Example 5: Enable alerting"
echo "Command: ./scripts/monitor-queue-depth.sh --alerts --webhook https://hooks.slack.com/..."
echo ""
echo "This would:"
echo "  1. Check thresholds against current metrics"
echo "  2. Log alerts to file: /var/log/github-runner-queue.log"
echo "  3. Send webhook notifications for warning/critical status"
echo "  4. Create alert entries like:"
echo ""
echo "2025-01-15T10:30:00Z [WARNING] Queue depth=6, Utilization=85%, Max wait=350s"
echo ""
echo "---"
echo ""

# Example 6: Custom thresholds
echo "Example 6: Custom alert thresholds"
echo "Command:"
cat <<'EOF'
export QUEUE_DEPTH_WARNING=3
export QUEUE_DEPTH_CRITICAL=7
export UTILIZATION_WARNING=70
export UTILIZATION_CRITICAL=90
export WAIT_TIME_WARNING=180
export WAIT_TIME_CRITICAL=360
./scripts/monitor-queue-depth.sh --alerts
EOF
echo ""
echo "This allows customizing when alerts trigger based on your workload."
echo ""
echo "---"
echo ""

# Example 7: Continuous monitoring
echo "Example 7: Continuous monitoring with cron"
echo ""
echo "Add to crontab:"
cat <<'EOF'
# Monitor every 5 minutes
*/5 * * * * /path/to/scripts/monitor-queue-depth.sh --format json --output /var/metrics/latest.json --alerts

# Generate daily HTML dashboard at 8 AM
0 8 * * * /path/to/scripts/generate-dashboard.sh --output-html /var/www/dashboard.html --days 7
EOF
echo ""
echo "---"
echo ""

# Example 8: Integration with monitoring systems
echo "Example 8: Prometheus integration"
echo ""
echo "1. Export metrics to file:"
echo "   ./scripts/monitor-queue-depth.sh --format prometheus --output /var/metrics/github-actions.prom"
echo ""
echo "2. Configure Prometheus scraper:"
cat <<'EOF'
scrape_configs:
  - job_name: 'github-actions'
    static_configs:
      - targets: ['localhost:9090']
    file_sd_configs:
      - files:
        - '/var/metrics/*.prom'
    scrape_interval: 5m
EOF
echo ""
echo "---"
echo ""

# Example 9: Historical analysis
echo "Example 9: Analyze historical trends"
echo ""
echo "After collecting metrics for several days:"
cat <<'EOF'
# View last 24 hours
tail -n 288 metrics/queue-metrics.csv

# Calculate average queue depth
awk -F',' 'NR>1 {sum+=$8; count++} END {print "Avg Queue:", sum/count}' \
  metrics/queue-metrics.csv

# Find peak utilization
awk -F',' 'NR>1 {if($9>max){max=$9; time=$1}} END {print "Peak:", max"% at", time}' \
  metrics/queue-metrics.csv

# Identify peak hours
awk -F',' 'NR>1 {hour=substr($1,12,2); util[hour]+=$9; count[hour]++}
  END {for(h in util) printf "%s:00 - %d%%\n", h, util[h]/count[h]}' \
  metrics/queue-metrics.csv | sort -k2 -nr | head -3
EOF
echo ""
echo "---"
echo ""

# Example 10: Dashboard generation
echo "Example 10: Generate dashboards"
echo ""
echo "HTML Dashboard:"
echo "  ./scripts/generate-dashboard.sh --output-html dashboard.html --days 7"
echo ""
echo "Grafana Dashboard:"
echo "  ./scripts/generate-dashboard.sh --output-grafana grafana.json"
echo "  # Import grafana.json in Grafana UI"
echo ""
echo "---"
echo ""

# Example 11: Alert scenarios
echo "Example 11: Common alert scenarios"
echo ""
echo "Scenario 1: High queue depth (warning)"
cat <<'EOF'
{
  "metrics": {"queue_depth": 6, "utilization_percent": 75},
  "status": "warning"
}
Action: Check if more runners needed
EOF
echo ""

echo "Scenario 2: Critical utilization"
cat <<'EOF'
{
  "metrics": {"queue_depth": 12, "utilization_percent": 98},
  "status": "critical"
}
Action: Immediate capacity increase required
EOF
echo ""

echo "Scenario 3: No available runners"
cat <<'EOF'
{
  "runners": {"available": 0, "busy": 10},
  "workflows": {"pending": 15},
  "status": "critical"
}
Action: All runners busy, workflows queuing - add runners urgently
EOF
echo ""
echo "---"
echo ""

# Example 12: Capacity planning
echo "Example 12: Capacity planning recommendations"
echo ""
echo "Based on collected metrics, the system can recommend:"
echo ""
cat <<'EOF'
Current State:
  - Average queue depth: 8 workflows
  - Average utilization: 85%
  - Peak hours: 10:00-12:00, 14:00-16:00
  - Average wait time: 5 minutes

Recommendations:
  1. Add 3 more runners (current: 10, recommended: 13)
  2. Pre-scale before peak hours (10:00 and 14:00)
  3. Consider auto-scaling based on queue depth > 5
  4. Review workflow efficiency (5min avg wait exceeds 3min target)

Cost Impact:
  - Additional runners: $XXX/month
  - Reduced wait time: 5min → 2min (60% improvement)
  - Developer productivity gain: ~XX hours/month
EOF
echo ""
echo "---"
echo ""

echo "=== End of Examples ==="
echo ""
echo "For more information, see docs/QUEUE-MONITORING.md"
