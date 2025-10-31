# GitHub Actions Runner Token Auto-Refresh

This document describes the token auto-refresh mechanism that prevents GitHub Actions runner registration failures due to token expiration.

## Overview

GitHub Actions runner registration tokens expire after 1 hour. This auto-refresh service monitors token expiration and automatically refreshes tokens before they expire (default: 5 minutes before expiration).

## Components

1. **Main Script**: `scripts/runner-token-refresh.sh`
   - Token expiration monitoring
   - Automatic token refresh with retry logic
   - Daemon and one-time check modes
   - Metrics tracking and logging

2. **Systemd Service**: `config/systemd/github-runner-token-refresh.service`
   - Runs as background daemon
   - Automatic restart on failure
   - Logs to systemd journal

3. **Cron Job**: `config/cron/runner-token-refresh.cron`
   - Periodic token checks (alternative to daemon)
   - Suitable for simpler setups

## Installation

### Prerequisites

1. **GitHub CLI** (`gh`) installed and authenticated:
   ```bash
   # Install gh CLI
   curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
   sudo apt update
   sudo apt install gh

   # Authenticate
   sudo -u runner gh auth login
   ```

2. **jq** for JSON processing:
   ```bash
   sudo apt install jq
   ```

3. **Runner installed** in `/home/runner/actions-runner` (or custom location)

### Option 1: Systemd Service (Recommended for Production)

1. **Copy the script**:
   ```bash
   sudo mkdir -p /home/runner/scripts
   sudo cp scripts/runner-token-refresh.sh /home/runner/scripts/
   sudo chmod +x /home/runner/scripts/runner-token-refresh.sh
   sudo chown runner:runner /home/runner/scripts/runner-token-refresh.sh
   ```

2. **Create configuration file**:
   ```bash
   sudo mkdir -p /etc/github-runner
   sudo cp config/systemd/token-refresh.env.example /etc/github-runner/token-refresh.env

   # Edit configuration
   sudo nano /etc/github-runner/token-refresh.env
   # Set RUNNER_ORG=your-org-name
   ```

3. **Install systemd service**:
   ```bash
   sudo cp config/systemd/github-runner-token-refresh.service /etc/systemd/system/

   # Edit service file to use environment file
   sudo nano /etc/systemd/system/github-runner-token-refresh.service
   # Uncomment: EnvironmentFile=/etc/github-runner/token-refresh.env
   # Comment out individual Environment= lines
   ```

4. **Create log file**:
   ```bash
   sudo touch /var/log/github-runner-token-refresh.log
   sudo chown runner:runner /var/log/github-runner-token-refresh.log
   ```

5. **Enable and start service**:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable github-runner-token-refresh.service
   sudo systemctl start github-runner-token-refresh.service
   ```

6. **Verify service is running**:
   ```bash
   sudo systemctl status github-runner-token-refresh.service
   sudo journalctl -u github-runner-token-refresh.service -f
   ```

### Option 2: Cron Job (Simpler Alternative)

1. **Copy the script**:
   ```bash
   sudo mkdir -p /home/runner/scripts
   sudo cp scripts/runner-token-refresh.sh /home/runner/scripts/
   sudo chmod +x /home/runner/scripts/runner-token-refresh.sh
   sudo chown runner:runner /home/runner/scripts/runner-token-refresh.sh
   ```

2. **Create log file**:
   ```bash
   sudo touch /var/log/github-runner-token-refresh.log
   sudo chown runner:runner /var/log/github-runner-token-refresh.log
   ```

3. **Set up environment variables** (option A - in user's crontab):
   ```bash
   sudo -u runner crontab -e

   # Add at top of crontab:
   RUNNER_ORG=your-org-name
   RUNNER_DIR=/home/runner/actions-runner
   SHELL=/bin/bash
   PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

   # Add cron job (runs every 30 minutes):
   */30 * * * * /home/runner/scripts/runner-token-refresh.sh --check-and-refresh >> /var/log/github-runner-token-refresh.log 2>&1
   ```

4. **Or install in /etc/cron.d/** (option B - system-wide):
   ```bash
   # Edit the cron file
   sudo cp config/cron/runner-token-refresh.cron /etc/cron.d/github-runner-token-refresh
   sudo nano /etc/cron.d/github-runner-token-refresh

   # Uncomment and customize one of the examples
   # Set your organization name

   sudo chmod 644 /etc/cron.d/github-runner-token-refresh
   ```

## Usage

### Daemon Mode (Systemd Service)

```bash
# Check status
sudo systemctl status github-runner-token-refresh.service

# View logs
sudo journalctl -u github-runner-token-refresh.service -f

# Restart service
sudo systemctl restart github-runner-token-refresh.service

# Stop service
sudo systemctl stop github-runner-token-refresh.service
```

### One-Time Check (Manual or Cron)

```bash
# Check and refresh if needed
/home/runner/scripts/runner-token-refresh.sh --check-and-refresh --org your-org

# Dry run (test without making changes)
/home/runner/scripts/runner-token-refresh.sh --check-and-refresh --org your-org --dry-run

# Custom threshold (refresh 10 minutes before expiry)
/home/runner/scripts/runner-token-refresh.sh --check-and-refresh --org your-org --threshold 600
```

### View Metrics

```bash
# View current metrics
cat /var/tmp/runner-token-metrics.json | jq .

# Example output:
# {
#   "last_check_timestamp": 1729695600,
#   "last_refresh_timestamp": 1729692000,
#   "total_refreshes": 12,
#   "failed_refreshes": 0,
#   "consecutive_failures": 0,
#   "runner_org": "my-org",
#   "runner_name": "runner-01"
# }
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `RUNNER_ORG` | (required) | GitHub organization name |
| `RUNNER_NAME` | `$(hostname)` | Runner name |
| `RUNNER_URL` | `https://github.com/${RUNNER_ORG}` | GitHub URL |
| `RUNNER_DIR` | `./actions-runner` | Runner installation directory |
| `REFRESH_THRESHOLD` | `300` | Refresh N seconds before expiry (5 min) |
| `CHECK_INTERVAL` | `60` | Check every N seconds (daemon mode) |
| `MAX_RETRY_ATTEMPTS` | `3` | Maximum retry attempts on failure |
| `RETRY_BACKOFF_SECONDS` | `30` | Wait N seconds between retries |
| `LOG_FILE` | `/var/log/...` | Log file path |
| `METRICS_FILE` | `/var/tmp/...` | Metrics file path |

### Command Line Options

```
--daemon                Run as daemon service (continuous monitoring)
--check-and-refresh     Check once and refresh if needed (for cron)
--dry-run              Simulate refresh without making changes
--org ORG              GitHub organization name
--runner-dir DIR       Runner installation directory
--threshold SECONDS    Refresh threshold in seconds
--interval SECONDS     Check interval in seconds (daemon mode)
--log-file FILE        Log file path
-h, --help             Show help message
```

## How It Works

### Token Expiration Check

1. Script reads token expiration from runner configuration files:
   - `.runner` file (JSON format with `credentials.expires_at`)
   - `.credentials` file
   - Token cache file

2. Converts ISO 8601 timestamp to Unix timestamp

3. Calculates time until expiration

### Auto-Refresh Logic

1. **Check token expiration** every N seconds (default: 60s)

2. **Refresh if needed**:
   - Token expires in less than threshold (default: 300s = 5 min)
   - Token has already expired
   - Cannot determine expiration time

3. **Refresh process**:
   - Get new registration token from GitHub API
   - Stop runner service (if running)
   - Remove old runner configuration
   - Register runner with new token
   - Restart runner service
   - Cache new expiration time

4. **Retry on failure**:
   - Up to 3 attempts (configurable)
   - 30-second backoff between attempts
   - Track consecutive failures
   - Alert after 3 consecutive failures

### Metrics and Monitoring

The service tracks:
- Last check timestamp
- Last successful refresh timestamp
- Total number of refreshes
- Number of failed refreshes
- Consecutive failures count

Metrics are saved to JSON file for monitoring:
```bash
cat /var/tmp/runner-token-metrics.json | jq .
```

## Troubleshooting

### Service won't start

```bash
# Check service status
sudo systemctl status github-runner-token-refresh.service

# Check logs
sudo journalctl -u github-runner-token-refresh.service -n 50 --no-pager

# Verify GitHub CLI authentication
sudo -u runner gh auth status

# Test script manually
sudo -u runner /home/runner/scripts/runner-token-refresh.sh --check-and-refresh --org your-org --dry-run
```

### Token refresh fails

1. **Check GitHub CLI authentication**:
   ```bash
   sudo -u runner gh auth status
   # If not authenticated:
   sudo -u runner gh auth login
   ```

2. **Verify API access**:
   ```bash
   sudo -u runner gh api orgs/your-org/actions/runners/registration-token
   ```

3. **Check runner service permissions**:
   ```bash
   ls -la /home/runner/actions-runner/
   sudo systemctl status actions.runner.*.service
   ```

4. **Review logs**:
   ```bash
   tail -f /var/log/github-runner-token-refresh.log
   ```

### Cron job not running

1. **Check cron is running**:
   ```bash
   sudo systemctl status cron
   ```

2. **Verify crontab**:
   ```bash
   sudo -u runner crontab -l
   ```

3. **Check cron logs**:
   ```bash
   sudo grep runner-token-refresh /var/log/syslog
   ```

4. **Test script manually**:
   ```bash
   sudo -u runner /home/runner/scripts/runner-token-refresh.sh --check-and-refresh --org your-org
   ```

## Testing

### Test Token Expiration Detection

```bash
# Run in dry-run mode
./scripts/runner-token-refresh.sh --check-and-refresh --org your-org --dry-run

# Check with very high threshold (will always trigger refresh)
./scripts/runner-token-refresh.sh --check-and-refresh --org your-org --threshold 86400 --dry-run
```

### Test Refresh Process

```bash
# Run actual refresh
./scripts/runner-token-refresh.sh --check-and-refresh --org your-org

# Verify runner is still working
sudo systemctl status actions.runner.*.service
```

### Test Daemon Mode

```bash
# Run daemon in foreground
./scripts/runner-token-refresh.sh --daemon --org your-org --interval 10

# Press Ctrl+C to stop
```

## Security Considerations

1. **GitHub CLI Authentication**: The `gh` CLI must be authenticated for the runner user. Tokens are stored securely by the GitHub CLI.

2. **Service User**: Run the service as the `runner` user, not root.

3. **File Permissions**: Ensure log files and metrics files have appropriate permissions.

4. **Token Storage**: Registration tokens are short-lived (1 hour) and not stored persistently by this script.

5. **Systemd Hardening**: The systemd service includes security options (commented out by default). Enable them based on your security requirements.

## Performance Impact

- **CPU**: Negligible (checks run every 60 seconds, take <1 second)
- **Memory**: ~10-20 MB for bash script
- **Network**: Minimal (API call only when refresh needed, ~1-2 KB)
- **Disk I/O**: Minimal (small log and metrics files)

## Monitoring and Alerting

### Monitor Metrics

```bash
# Create monitoring script
cat > /usr/local/bin/check-token-refresh-health.sh <<'EOF'
#!/bin/bash
METRICS_FILE=/var/tmp/runner-token-metrics.json

if [[ ! -f "$METRICS_FILE" ]]; then
    echo "CRITICAL: Metrics file not found"
    exit 2
fi

# Use jq with defaults to handle null/missing fieldsconsecutive_failures=$(jq -r '.consecutive_failures // 0' "$METRICS_FILE")last_check=$(jq -r '.last_check_timestamp // 0' "$METRICS_FILE")current_time=$(date +%s)# Handle cases where last_check might be 0 or nullif [[ "$last_check" == "0" ]] || [[ "$last_check" == "null" ]]; then    echo "WARNING: No check timestamp found in metrics"    exit 1fitime_since_check=$((current_time - last_check))# Handle null/missing consecutive_failuresif [[ "$consecutive_failures" == "null" ]]; then    consecutive_failures=0fi

if [[ $consecutive_failures -ge 3 ]]; then
    echo "CRITICAL: $consecutive_failures consecutive refresh failures"
    exit 2
fi

if [[ $time_since_check -gt 300 ]]; then
    echo "WARNING: Last check was ${time_since_check}s ago"
    exit 1
fi

echo "OK: Token refresh healthy"
exit 0
EOF

chmod +x /usr/local/bin/check-token-refresh-health.sh
```

### Integrate with Monitoring Systems

- **Nagios/Icinga**: Use the health check script above
- **Prometheus**: Export metrics from JSON file
- **CloudWatch**: Parse logs and send metrics
- **Datadog**: Use log integration

## Alternatives

### Manual Token Refresh

```bash
# Get new token
NEW_TOKEN=$(gh api orgs/your-org/actions/runners/registration-token --jq '.token')

# Reconfigure runner
cd /home/runner/actions-runner
sudo systemctl stop actions.runner.*.service
./config.sh remove --token "$NEW_TOKEN"
./config.sh --url https://github.com/your-org --token "$NEW_TOKEN" --name "$(hostname)" --unattended
sudo systemctl start actions.runner.*.service
```

### GitHub Actions Workflow

Use a scheduled workflow to refresh runner tokens (requires workflow to run on a different runner).

## References

- [GitHub Actions Runner Documentation](https://docs.github.com/en/actions/hosting-your-own-runners)
- [GitHub CLI Documentation](https://cli.github.com/)
- [Systemd Service Documentation](https://www.freedesktop.org/software/systemd/man/systemd.service.html)
