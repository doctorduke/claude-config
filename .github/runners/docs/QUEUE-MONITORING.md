# Queue Monitoring System

Comprehensive monitoring system for GitHub Actions runner queue depth, utilization, and capacity planning.

## Overview

The queue monitoring system provides real-time visibility into:
- **Queue Depth**: Number of workflows waiting to execute
- **Runner Utilization**: Percentage of runners currently busy
- **Wait Times**: How long workflows wait before execution
- **Runner Status**: Available, busy, and offline runners
- **Capacity Planning**: Historical trends and recommendations

## Components

### 1. Monitor Script (`scripts/monitor-queue-depth.sh`)

Main monitoring script that collects metrics from GitHub API.

**Features:**
- Query GitHub API for workflow runs and runner status
- Calculate queue depth and utilization metrics
- Alert on configurable thresholds
- Export metrics in multiple formats (JSON, Prometheus, CSV, text)
- Historical tracking and logging

**Usage:**
```bash
# Basic usage (JSON output)
./scripts/monitor-queue-depth.sh

# With specific repository
./scripts/monitor-queue-depth.sh --repo owner/repo

# Enable alerts
./scripts/monitor-queue-depth.sh --alerts --webhook https://hooks.slack.com/...

# Prometheus format
./scripts/monitor-queue-depth.sh --format prometheus

# CSV format
./scripts/monitor-queue-depth.sh --format csv

# Text format (human-readable)
./scripts/monitor-queue-depth.sh --format text

# Save to file
./scripts/monitor-queue-depth.sh --output metrics/latest.json
```

**Environment Variables:**
```bash
# Alert thresholds
export QUEUE_DEPTH_WARNING=5         # Warning at 5 queued runs
export QUEUE_DEPTH_CRITICAL=10       # Critical at 10 queued runs
export UTILIZATION_WARNING=80        # Warning at 80% utilization
export UTILIZATION_CRITICAL=95       # Critical at 95% utilization
export WAIT_TIME_WARNING=300         # Warning at 5min wait (seconds)
export WAIT_TIME_CRITICAL=600        # Critical at 10min wait (seconds)

# Metrics storage
export METRICS_DIR=./metrics         # Directory for metrics storage
export LOG_FILE=/var/log/github-runner-queue.log  # Log file path
```

### 2. Monitoring Workflow (`.github/workflows/monitor-queue.yml`)

Automated workflow that runs every 5 minutes to collect metrics.

**Features:**
- Scheduled execution (cron: `*/5 * * * *`)
- Manual trigger support
- Job summary with metrics visualization
- Alert on critical conditions
- Artifact upload for historical analysis

**Outputs:**
- Job summary with ASCII charts
- Metrics artifacts (retained for 30 days)
- Recommendations when issues detected

### 3. Dashboard Generator (`scripts/generate-dashboard.sh`)

Generate dashboards from historical metrics.

**Usage:**
```bash
# Generate HTML dashboard
./scripts/generate-dashboard.sh \
  --metrics-dir ./metrics \
  --output-html dashboard.html \
  --days 7

# Generate Grafana JSON
./scripts/generate-dashboard.sh \
  --metrics-dir ./metrics \
  --output-grafana grafana-dashboard.json
```

**HTML Dashboard Features:**
- Real-time metrics display
- Interactive charts (Chart.js)
- 7-day historical trends
- Responsive design
- Auto-refresh support

**Grafana Dashboard:**
- Pre-configured panels for all metrics
- Prometheus datasource compatible
- 5-minute refresh interval
- 7-day default time range

## Metrics Collected

### Workflow Metrics
- `workflows.pending`: Number of queued workflows
- `workflows.in_progress`: Number of running workflows
- `workflows.total_active`: Total active workflows (pending + in_progress)

### Runner Metrics
- `runners.total`: Total number of runners
- `runners.online`: Online runners (available + busy)
- `runners.available`: Runners ready to accept jobs
- `runners.busy`: Runners currently executing jobs
- `runners.offline`: Offline runners

### Performance Metrics
- `metrics.queue_depth`: Number of workflows in queue
- `metrics.utilization_percent`: Runner utilization (0-100%)
- `metrics.capacity`: Number of available runners
- `metrics.max_wait_time_seconds`: Longest wait time for queued workflow
- `metrics.avg_wait_time_seconds`: Average wait time for queued workflows

### Status
- `status`: Overall health status
  - `healthy`: All metrics within normal range
  - `warning`: One or more metrics exceed warning threshold
  - `critical`: One or more metrics exceed critical threshold

## Alert Thresholds

| Metric | Warning | Critical |
|--------|---------|----------|
| Queue Depth | 5 workflows | 10 workflows |
| Utilization | 80% | 95% |
| Wait Time | 5 minutes | 10 minutes |

**Alert Actions:**
1. Log to file: `/var/log/github-runner-queue.log`
2. Webhook notification (Slack/Discord)
3. Workflow failure on critical status
4. GitHub issue creation (optional)

## Export Formats

### JSON Format
```json
{
  "timestamp": "2025-01-15T10:30:00Z",
  "repository": "owner/repo",
  "organization": "owner",
  "workflows": {
    "pending": 2,
    "in_progress": 3,
    "total_active": 5
  },
  "runners": {
    "total": 5,
    "online": 4,
    "available": 2,
    "busy": 2,
    "offline": 1
  },
  "metrics": {
    "queue_depth": 2,
    "utilization_percent": 50,
    "capacity": 2,
    "max_wait_time_seconds": 120,
    "avg_wait_time_seconds": 90
  },
  "status": "healthy"
}
```

### Prometheus Format
```
# HELP github_actions_queue_depth Number of queued workflow runs
# TYPE github_actions_queue_depth gauge
github_actions_queue_depth{repo="owner/repo"} 2

# HELP github_actions_runner_utilization Runner utilization percentage
# TYPE github_actions_runner_utilization gauge
github_actions_runner_utilization{org="owner",repo="owner/repo"} 50
```

### CSV Format
```csv
timestamp,repo,pending,in_progress,available,busy,offline,queue_depth,utilization,max_wait,avg_wait,status
2025-01-15T10:30:00Z,owner/repo,2,3,2,2,1,2,50,120,90,healthy
```

### Text Format
```
=== GitHub Actions Queue Monitor ===
Repository: owner/repo
Timestamp: 2025-01-15T10:30:00Z

Workflows:
  Pending:     2
  In Progress: 3
  Total Active: 5

Runners:
  Total:     5
  Available: 2
  Busy:      2
  Offline:   1

Metrics:
  Queue Depth:  2
  Utilization:  50%
  Max Wait:     120s (2m)
  Avg Wait:     90s (1m)

Status: HEALTHY

Utilization Chart:
  [#########################                         ] 50%
```

## Integration Options

### Prometheus/Grafana
1. Configure Prometheus to scrape metrics:
   ```yaml
   scrape_configs:
     - job_name: 'github-actions-queue'
       static_configs:
         - targets: ['localhost:9090']
       file_sd_configs:
         - files:
           - '/path/to/metrics/*.prom'
   ```

2. Import Grafana dashboard:
   ```bash
   ./scripts/generate-dashboard.sh --output-grafana grafana.json
   # Import grafana.json in Grafana UI
   ```

### Slack/Discord Webhooks
```bash
# Slack
export WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
./scripts/monitor-queue-depth.sh --alerts --webhook "$WEBHOOK_URL"

# Discord
export WEBHOOK_URL="https://discord.com/api/webhooks/YOUR/WEBHOOK"
./scripts/monitor-queue-depth.sh --alerts --webhook "$WEBHOOK_URL"
```

### Email Notifications
Configure email alerts via webhook or custom script:
```bash
# Example: Send email on critical status
if [[ $(jq -r '.status' metrics.json) == "critical" ]]; then
  mail -s "GitHub Actions Queue Critical" admin@example.com < metrics.json
fi
```

## Historical Analysis

### View Trends
```bash
# Last 24 hours
tail -n 288 metrics/queue-metrics.csv | column -t -s,

# Calculate average queue depth
awk -F',' 'NR>1 {sum+=$8; count++} END {print sum/count}' \
  metrics/queue-metrics.csv

# Find peak utilization
awk -F',' 'NR>1 {if($9>max){max=$9}} END {print max}' \
  metrics/queue-metrics.csv
```

### Capacity Planning
```bash
# Identify peak usage times
awk -F',' 'NR>1 {hour=substr($1,12,2); util[hour]+=$9; count[hour]++}
  END {for(h in util) printf "%s:00 - %d%%\n", h, util[h]/count[h]}' \
  metrics/queue-metrics.csv | sort

# Recommend runner count
# If avg utilization > 70%, recommend adding runners
avg_util=$(awk -F',' 'NR>1 {sum+=$9; count++} END {print sum/count}' \
  metrics/queue-metrics.csv)
if (( $(echo "$avg_util > 70" | bc -l) )); then
  echo "Recommendation: Add more runners"
fi
```

## Testing

Run the test suite:
```bash
chmod +x tests/test-monitor-queue-depth.sh
./tests/test-monitor-queue-depth.sh
```

**Test Coverage:**
- Script syntax validation
- JSON format validation
- Alert threshold logic
- Prometheus format
- CSV format
- Text format
- Log file creation
- Metrics directory creation
- Edge cases (zero values, high values, no runners)

## Troubleshooting

### gh CLI Not Authenticated
```bash
gh auth login
gh auth status
```

### Permission Denied on Log File
```bash
# Use local log file
export LOG_FILE=./github-runner-queue.log
```

### No Metrics Data
```bash
# Check if runners are registered
gh api repos/OWNER/REPO/actions/runners

# Check workflow runs
gh api repos/OWNER/REPO/actions/runs
```

### High Memory Usage
```bash
# Limit historical data retention
find metrics/ -name "queue-metrics-*.json" -mtime +7 -delete
```

## Best Practices

1. **Monitor Regularly**: Run every 5 minutes for timely alerts
2. **Set Appropriate Thresholds**: Adjust based on your workload
3. **Archive Historical Data**: Keep at least 30 days for trend analysis
4. **Review Weekly**: Analyze trends for capacity planning
5. **Alert Fatigue**: Tune thresholds to avoid too many warnings
6. **Correlate with CI/CD**: Track queue depth against deployment frequency
7. **Scale Proactively**: Add runners before reaching critical thresholds

## Performance Impact

- **API Calls**: 2-3 calls per monitoring run (minimal rate limit impact)
- **Storage**: ~10KB per metrics file, ~5MB per month (5-min intervals)
- **Execution Time**: <5 seconds per run
- **Network**: <1KB per API request

## Security Considerations

- **GitHub Token**: Requires `actions:read` permission
- **Webhooks**: Use HTTPS endpoints with authentication
- **Log Files**: May contain sensitive repository information
- **Metrics Storage**: Ensure proper access controls

## Future Enhancements

- [ ] Auto-scaling integration (trigger runner creation)
- [ ] Cost analysis (runner hours vs queue time)
- [ ] SLA tracking (% of workflows within time targets)
- [ ] Anomaly detection (ML-based alerting)
- [ ] Multi-repository aggregation
- [ ] Mobile dashboard support
- [ ] Real-time WebSocket updates
