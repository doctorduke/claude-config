# Queue Monitoring Quick Reference

Fast reference for common queue monitoring tasks.

## Quick Start

```bash
# Monitor current queue state (JSON)
./scripts/monitor-queue-depth.sh

# Human-readable output
./scripts/monitor-queue-depth.sh --format text

# Enable alerts
./scripts/monitor-queue-depth.sh --alerts --webhook https://your-webhook-url
```

## Common Commands

### Basic Monitoring
```bash
# Check current status
./scripts/monitor-queue-depth.sh --format text

# Save metrics to file
./scripts/monitor-queue-depth.sh --output metrics.json

# Monitor specific repository
./scripts/monitor-queue-depth.sh --repo owner/repo
```

### Alert Configuration
```bash
# Set custom thresholds
export QUEUE_DEPTH_WARNING=3
export QUEUE_DEPTH_CRITICAL=7
export UTILIZATION_WARNING=70
export UTILIZATION_CRITICAL=90

# Enable alerts with webhook
./scripts/monitor-queue-depth.sh --alerts --webhook https://hooks.slack.com/...
```

### Export Formats
```bash
# JSON (default)
./scripts/monitor-queue-depth.sh --format json

# Prometheus
./scripts/monitor-queue-depth.sh --format prometheus

# CSV
./scripts/monitor-queue-depth.sh --format csv

# Text
./scripts/monitor-queue-depth.sh --format text
```

### Dashboard Generation
```bash
# HTML dashboard (last 7 days)
./scripts/generate-dashboard.sh --output-html dashboard.html --days 7

# Grafana JSON
./scripts/generate-dashboard.sh --output-grafana grafana.json
```

## Metrics Cheat Sheet

| Metric | Description | Unit | Threshold |
|--------|-------------|------|-----------|
| queue_depth | Pending workflows | count | W:5, C:10 |
| utilization_percent | Runner usage | % | W:80, C:95 |
| max_wait_time_seconds | Longest wait | seconds | W:300, C:600 |
| avg_wait_time_seconds | Average wait | seconds | - |
| available | Ready runners | count | - |
| busy | Active runners | count | - |

## Status Levels

- **healthy**: All metrics normal
- **warning**: One or more metrics exceed warning threshold
- **critical**: One or more metrics exceed critical threshold

## Common Scenarios

### High Queue Depth
```bash
# Current metrics show queue_depth = 8
# Action: Check runner availability
./scripts/monitor-queue-depth.sh --format text | grep -A5 "Runners:"

# If utilization > 80%, add more runners
```

### No Available Runners
```bash
# All runners busy, workflows queuing
# Immediate action: Scale up runner pool
# Check: Are some runners stuck/offline?

# List runner status
gh api repos/OWNER/REPO/actions/runners | jq '.runners[] | {name, status, busy}'
```

### Long Wait Times
```bash
# Workflows waiting > 5 minutes
# Check: Queue depth and runner count
# Consider: Pre-scaling before peak hours
```

## Scheduled Monitoring

### Cron Setup (Every 5 minutes)
```bash
*/5 * * * * /path/to/scripts/monitor-queue-depth.sh --format json --output /var/metrics/latest.json --alerts
```

### GitHub Actions (Automated)
```yaml
# Already configured in .github/workflows/monitor-queue.yml
# Runs every 5 minutes
# Manual trigger: gh workflow run monitor-queue.yml
```

## Historical Analysis

### View Recent Metrics
```bash
# Last 24 hours (288 data points at 5-min intervals)
tail -n 288 metrics/queue-metrics.csv

# Last hour
tail -n 12 metrics/queue-metrics.csv
```

### Calculate Averages
```bash
# Average queue depth
awk -F',' 'NR>1 {sum+=$8; count++} END {print sum/count}' metrics/queue-metrics.csv

# Average utilization
awk -F',' 'NR>1 {sum+=$9; count++} END {print sum/count}' metrics/queue-metrics.csv

# Peak utilization
awk -F',' 'NR>1 {if($9>max)max=$9} END {print max}' metrics/queue-metrics.csv
```

### Find Peak Hours
```bash
awk -F',' 'NR>1 {
  hour=substr($1,12,2)
  util[hour]+=$9
  count[hour]++
}
END {
  for(h in util)
    printf "%s:00 - %d%%\n", h, util[h]/count[h]
}' metrics/queue-metrics.csv | sort -k2 -nr
```

## Troubleshooting

### gh CLI Not Working
```bash
# Check authentication
gh auth status

# Login if needed
gh auth login
```

### Permission Denied (Log File)
```bash
# Use local log file
export LOG_FILE=./github-runner-queue.log
./scripts/monitor-queue-depth.sh
```

### No Metrics Collected
```bash
# Verify GitHub API access
gh api repos/OWNER/REPO/actions/runs --jq '.workflow_runs | length'

# Check runner registration
gh api repos/OWNER/REPO/actions/runners --jq '.runners | length'
```

### Metrics Directory Full
```bash
# Clean old metrics (>7 days)
find metrics/ -name "queue-metrics-*.json" -mtime +7 -delete

# Keep only CSV summary
rm metrics/queue-metrics-*.json
```

## Integration Examples

### Prometheus
```bash
# Export metrics
./scripts/monitor-queue-depth.sh --format prometheus --output /var/metrics/github-actions.prom

# Scrape with Prometheus
# See docs/QUEUE-MONITORING.md for full config
```

### Slack Webhook
```bash
# Set webhook URL
export WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK"

# Run with alerts
./scripts/monitor-queue-depth.sh --alerts --webhook "$WEBHOOK_URL"
```

### Custom Script
```bash
# Get metrics and process
metrics=$(./scripts/monitor-queue-depth.sh --format json)

# Extract specific metric
queue_depth=$(echo "$metrics" | jq -r '.metrics.queue_depth')

# Custom action based on queue depth
if [[ $queue_depth -gt 10 ]]; then
  echo "High queue! Scaling up runners..."
  # Your auto-scaling logic here
fi
```

## Performance Targets

| Metric | Target | Acceptable | Action Required |
|--------|--------|------------|-----------------|
| Queue Depth | 0-3 | 4-5 | >5 |
| Utilization | <70% | 70-80% | >80% |
| Wait Time | <3min | 3-5min | >5min |
| Available Runners | >3 | 1-3 | 0 |

## Capacity Planning

### Runner Sizing Formula
```
Recommended Runners = (Peak Concurrent Jobs × 1.2) + 2 buffer

Example:
  Peak concurrent: 10 jobs
  Recommended: (10 × 1.2) + 2 = 14 runners
```

### Cost vs. Performance
```
Scenario A: 10 runners
  - Cost: $XXX/month
  - Avg wait: 5min
  - Utilization: 85%

Scenario B: 15 runners
  - Cost: $YYY/month (+50%)
  - Avg wait: 2min (-60%)
  - Utilization: 60%

Decision: Choose based on developer time value vs. infrastructure cost
```

## Best Practices

1. **Monitor Regularly**: Every 5 minutes minimum
2. **Set Realistic Thresholds**: Based on your workload patterns
3. **Review Weekly**: Analyze trends for capacity planning
4. **Alert Wisely**: Avoid alert fatigue - tune thresholds
5. **Archive Data**: Keep 30+ days for trend analysis
6. **Document Changes**: Note when runners added/removed
7. **Test Alerts**: Verify webhook notifications work
8. **Plan Capacity**: Scale before hitting limits

## Quick Wins

1. **Set up automated monitoring** (5 min)
   - Enable workflow: `.github/workflows/monitor-queue.yml`

2. **Configure Slack alerts** (10 min)
   - Create webhook, add to workflow

3. **Generate HTML dashboard** (5 min)
   - Run `generate-dashboard.sh`, host on web server

4. **Analyze peak hours** (15 min)
   - Review metrics, identify patterns, pre-scale

5. **Set appropriate thresholds** (10 min)
   - Customize based on your SLAs

## Support

- Full Documentation: `docs/QUEUE-MONITORING.md`
- Examples: `examples/monitor-example.sh`
- Test Suite: `tests/test-monitor-queue-depth.sh`
- Issues: GitHub repository issues
