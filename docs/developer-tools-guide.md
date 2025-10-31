# Developer Tools Guide

> Complete guide to GitHub Actions runner deployment and management automation tools

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Tools Reference](#tools-reference)
  - [Quick Deploy](#quick-deploy)
  - [Health Check](#health-check)
  - [Status Dashboard](#status-dashboard)
- [Usage Examples](#usage-examples)
- [Troubleshooting](#troubleshooting)
- [Advanced Usage](#advanced-usage)

---

## Overview

This guide covers the automated developer experience (DX) tools for deploying and managing GitHub Actions self-hosted runners. These tools simplify runner deployment, monitoring, and troubleshooting.

### Available Tools

| Tool | Purpose | Key Features |
|------|---------|--------------|
| `quick-deploy.sh` | One-command runner deployment | Interactive setup, multi-runner deployment, dependency installation |
| `health-check.sh` | Comprehensive health monitoring | Service status, disk space, network, logs analysis |
| `runner-status-dashboard.sh` | Real-time status dashboard | Live runner status, job queue, workflow history |

### Prerequisites

**Required:**
- Linux, macOS, or Windows+WSL 2.0
- Bash 4.0+
- Internet connectivity
- Sudo/admin access

**Optional (auto-installed):**
- `curl` or `wget` - For downloads
- `jq` - For JSON processing
- `gh` (GitHub CLI) - For enhanced API features

---

## Quick Start

### 1. Deploy Runners (One Command)

```bash
# Interactive deployment (recommended for first-time setup)
./scripts/quick-deploy.sh

# Non-interactive deployment
./scripts/quick-deploy.sh \
  --org https://github.com/myorg \
  --token ghp_xxxxxxxxxxxx \
  --count 5 \
  --non-interactive
```

### 2. Verify Health

```bash
# Single health check
./scripts/health-check.sh

# Continuous monitoring
./scripts/health-check.sh --continuous --interval 60
```

### 3. View Dashboard

```bash
# Live dashboard (auto-refresh)
./scripts/runner-status-dashboard.sh --org myorg

# One-time snapshot
./scripts/runner-status-dashboard.sh --org myorg --refresh 0
```

---

## Tools Reference

### Quick Deploy

#### Description
Automated runner deployment script that handles everything from dependency installation to multi-runner configuration.

#### Usage

```bash
./scripts/quick-deploy.sh [OPTIONS]
```

#### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--org URL` | GitHub organization URL | Interactive prompt |
| `--token TOKEN` | Runner registration token | Interactive prompt |
| `--count N` | Number of runners to deploy | 3 |
| `--labels LABELS` | Comma-separated labels | `self-hosted,linux,x64,ai-agent` |
| `--name PREFIX` | Runner name prefix | `runner` |
| `--dir DIR` | Installation directory base | `$HOME/actions-runner` |
| `--non-interactive` | Skip all prompts | false |
| `--skip-deps` | Skip dependency installation | false |
| `--help` | Display help | - |

#### Features

**Interactive Setup:**
- Guided prompts for all configuration
- Automatic dependency detection and installation
- Validation of inputs before deployment

**Multi-Runner Deployment:**
- Deploy 1-20 runners in a single command
- Sequential installation with progress tracking
- Automatic service configuration

**Post-Install Validation:**
- Verifies runner registration
- Checks service status
- Validates configuration files

#### Example Output

```
========================================
  GitHub Actions Quick Deploy
========================================

[INFO] Log file: /tmp/quick-deploy-20251017-143022.log

=== Detecting Operating System ===
[SUCCESS] Detected: linux-x64

=== Installing Dependencies ===
[SUCCESS] All required dependencies installed

=== Configuration ===
GitHub Organization URL (e.g., https://github.com/myorg) []: https://github.com/acme
Runner Registration Token []: ghp_xxxxxxxxxxxxxxxxxxxx
Number of runners to deploy [3]: 5
Runner labels (comma-separated) [self-hosted,linux,x64,ai-agent]:
Runner name prefix [runner]: acme-runner
Installation directory base [$HOME/actions-runner]:

=== Deployment Plan ===
Organization: https://github.com/acme
Runner Count: 5
Runner Prefix: acme-runner
Labels: self-hosted,linux,x64,ai-agent
Install Directory: /home/user/actions-runner-{1..5}
Platform: linux-x64

Proceed with deployment? (y/N): y

=== Deploying 5 Runner(s) ===
[INFO] [1/5] Deploying acme-runner-01...
[SUCCESS] [1/5] acme-runner-01 deployed successfully
[INFO] [2/5] Deploying acme-runner-02...
[SUCCESS] [2/5] acme-runner-02 deployed successfully
...

=== Deployment Summary ===
[SUCCESS] Successful: 5

=== Post-Install Validation ===
[SUCCESS] [acme-runner-01] Service is active
[SUCCESS] [acme-runner-02] Service is active
...
[SUCCESS] All validation checks passed!

=== Next Steps ===

1. Verify runners in GitHub:
   https://github.com/acme/settings/actions/runners

2. Run health check:
   ./scripts/health-check.sh --runner-dir /home/user/actions-runner-1

3. View runner status:
   ./scripts/runner-status-dashboard.sh

4. Check logs:
   tail -f /home/user/actions-runner-1/_diag/Runner_*.log

[SUCCESS] Quick Deploy Complete!

Log file saved: /tmp/quick-deploy-20251017-143022.log
```

#### Getting a Registration Token

```bash
# Via GitHub CLI
gh api /orgs/YOUR_ORG/actions/runners/registration-token | jq -r .token

# Via Web UI
# Navigate to: https://github.com/YOUR_ORG/settings/actions/runners/new
```

---

### Health Check

#### Description
Comprehensive health monitoring script that validates runner service status, disk space, network connectivity, and system resources.

#### Usage

```bash
./scripts/health-check.sh [OPTIONS]
```

#### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--json` | Output in JSON format | Text output |
| `--continuous` | Run continuously | Single check |
| `--interval N` | Check interval in seconds | 60 |
| `--runner-dir DIR` | Runner installation directory | `$HOME/actions-runner` |
| `--help` | Display help | - |

#### Health Checks Performed

1. **Runner Service Status**
   - Systemd service status (Linux/WSL)
   - Launchd service status (macOS)
   - Process detection fallback
   - Recent log error detection

2. **Disk Space**
   - Current usage percentage
   - Available space
   - Warning at 80% usage
   - Critical error at 90% usage

3. **Network Connectivity**
   - DNS resolution (github.com)
   - TCP connectivity to GitHub endpoints
   - Latency measurement
   - HTTPS/API endpoint validation

4. **Runner Registration**
   - Configuration file validation
   - Credentials file check
   - Runner name and ID extraction

5. **System Resources**
   - CPU usage
   - Memory usage
   - Load average

#### Exit Codes

| Code | Meaning | Action |
|------|---------|--------|
| 0 | All checks passed | None |
| 1 | Warning detected | Review output |
| 2 | Critical error | Immediate action required |

#### Example Output

```
GitHub Actions Runner Health Check
====================================
Timestamp: 2025-10-17 14:35:22
Runner Directory: /home/user/actions-runner

=== Runner Service Status ===
[PASS] Service actions.runner.myorg.runner-01.service is running
[PASS] No errors in recent logs

=== Disk Space ===
  Mount: /
  Usage: 45% (250G available)
[PASS] Disk usage healthy: 45%

=== Network Connectivity ===
[PASS] DNS resolution working
[PASS] github.com reachable (23ms)
[PASS] api.github.com reachable (28ms)
[PASS] pipelines.actions.githubusercontent.com reachable (31ms)
[PASS] HTTPS connectivity to GitHub API working (HTTP 200)

=== Runner Registration Status ===
[PASS] Runner registered: runner-01 (ID: 12345)
  Config: /home/user/actions-runner/.runner
[PASS] Runner credentials found

=== Recent Workflow Activity ===
[INFO] Workflow checks require organization/repository context
  Use: gh run list --limit 20 in repository directory

=== System Resources ===
  CPU Usage: 15.2%
  Memory: 2.3G / 16G
  Load Average: 0.45 0.52 0.48
[PASS] System resources checked

=== Summary ===
All checks passed!

Exit Code: 0 (0=success, 1=warning, 2=critical)
```

#### Continuous Monitoring

```bash
# Monitor every 30 seconds
./scripts/health-check.sh --continuous --interval 30

# JSON output for automation
./scripts/health-check.sh --json > health-status.json
```

#### Remediation Examples

**Disk Space Warning:**
```bash
# Clean old logs
rm -rf $HOME/actions-runner/_diag/*.log.*

# Clean build artifacts
rm -rf $HOME/actions-runner/_work/*

# Clean Docker (if used)
docker system prune -a -f
```

**Service Offline:**
```bash
# Restart service
sudo systemctl restart actions.runner.*.service

# Check service logs
sudo journalctl -u actions.runner.*.service -n 50
```

**Network Connectivity Issues:**
```bash
# Test DNS
nslookup github.com

# Test with proxy
export HTTPS_PROXY=http://proxy.example.com:8080
curl -v https://api.github.com
```

---

### Status Dashboard

#### Description
Real-time text-based dashboard showing runner status, job queue, and recent workflow runs.

#### Usage

```bash
./scripts/runner-status-dashboard.sh [OPTIONS]
```

#### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--org OWNER` | GitHub organization or user | Required for API calls |
| `--refresh N` | Auto-refresh interval (0=no refresh) | 30 |
| `--compact` | Compact view | Full details |
| `--json` | JSON output | Text output |
| `--no-color` | Disable colors | Colored output |
| `--runner-dir DIR` | Base runner directory | `$HOME/actions-runner` |
| `--help` | Display help | - |

#### Features

**Runner Status:**
- Local runner detection
- GitHub API integration
- Service status monitoring
- Label display

**Job Queue:**
- Queued workflow runs
- Wait time tracking
- Status indicators

**Workflow History:**
- Recent workflow runs (last 10)
- Success/failure tracking
- Duration calculation
- Success rate metrics

#### Example Output

```
GitHub Actions Runner Dashboard
================================

--- System Information ---
  Timestamp: 2025-10-17 14:40:15
  Organization: acme
  Runner Base Dir: /home/user/actions-runner
  Load Average: 0.52 0.48 0.45
  Memory: 3.2G / 16G

--- Self-Hosted Runners ---
  NAME                 STATUS     ID              LABELS
  ---------------------------------------------------------------------------
  acme-runner-01       ● online   12345          self-hosted,linux,x64,ai-agent
  acme-runner-02       ● online   12346          self-hosted,linux,x64,ai-agent
  acme-runner-03       ● online   12347          self-hosted,linux,x64,ai-agent
  acme-runner-04       ● offline  12348          self-hosted,linux,x64,ai-agent
  acme-runner-05       ● online   12349          self-hosted,linux,x64,ai-agent

  Total Runners: 5
  Online: 4 | Offline: 1

--- Job Queue ---
  WORKFLOW                                 STATUS          QUEUED AT
  ---------------------------------------------------------------------------
  CI Pipeline - Backend                    ● queued        2025-10-17 14:38:42
  Deploy Production                        ● queued        2025-10-17 14:39:15

  Queued Jobs: 2

--- Recent Workflow Runs ---
  WORKFLOW                       STATUS          CONCLUSION      DURATION
  ---------------------------------------------------------------------------
  CI Pipeline - Frontend         ● completed     success         2m 34s
  Test Suite                     ● completed     success         4m 12s
  Deploy Staging                 ● completed     success         1m 48s
  CI Pipeline - Backend          ● completed     failure         3m 22s
  Security Scan                  ● completed     success         5m 01s

  Success Rate: 80% (4/5)

Auto-refresh in 30s (Ctrl+C to exit)
```

#### JSON Output

```bash
# Get JSON snapshot
./scripts/runner-status-dashboard.sh --org acme --json > dashboard.json

# Example JSON structure
{
  "timestamp": "2025-10-17T14:40:15Z",
  "organization": "acme",
  "local_runners": [...],
  "org_runners": [...],
  "workflow_runs": [...],
  "job_queue": [...]
}
```

#### Compact Mode

```bash
# Minimal output for quick checks
./scripts/runner-status-dashboard.sh --org acme --compact

# Output:
Self-Hosted Runners
  ● acme-runner-01 (online)
  ● acme-runner-02 (online)
  ● acme-runner-03 (online)
  ○ acme-runner-04 (offline)
  ● acme-runner-05 (online)
```

---

## Usage Examples

### Complete Deployment Workflow

```bash
# 1. Deploy runners
./scripts/quick-deploy.sh \
  --org https://github.com/acme \
  --token ghp_xxxx \
  --count 3 \
  --labels "self-hosted,linux,x64,prod" \
  --name "prod-runner"

# 2. Verify deployment
./scripts/health-check.sh --runner-dir $HOME/actions-runner-1

# 3. Monitor status
./scripts/runner-status-dashboard.sh --org acme
```

### Automated Monitoring Setup

```bash
# Create monitoring cron job
cat > /etc/cron.d/runner-health <<'EOF'
*/5 * * * * user /path/to/scripts/health-check.sh --json > /var/log/runner-health.json
EOF

# Alert on failures
cat > /usr/local/bin/runner-health-alert.sh <<'EOF'
#!/bin/bash
./scripts/health-check.sh --json | jq -e '.status == "critical"' && \
  echo "ALERT: Runner health critical" | mail -s "Runner Alert" ops@example.com
EOF
chmod +x /usr/local/bin/runner-health-alert.sh
```

### CI/CD Integration

```yaml
# .github/workflows/runner-health.yml
name: Runner Health Check

on:
  schedule:
    - cron: '*/15 * * * *'  # Every 15 minutes
  workflow_dispatch:

jobs:
  health-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Health Check
        run: |
          ./scripts/health-check.sh --json > health-report.json

      - name: Upload Report
        uses: actions/upload-artifact@v4
        with:
          name: health-report
          path: health-report.json

      - name: Check Status
        run: |
          if [ $(jq -r '.exit_code' health-report.json) -gt 1 ]; then
            echo "::error::Runner health check failed"
            exit 1
          fi
```

### Multi-Environment Setup

```bash
# Production runners
./scripts/quick-deploy.sh \
  --org https://github.com/acme \
  --token $PROD_TOKEN \
  --count 5 \
  --labels "self-hosted,linux,x64,prod" \
  --name "prod-runner" \
  --dir /opt/runners/prod

# Staging runners
./scripts/quick-deploy.sh \
  --org https://github.com/acme \
  --token $STAGING_TOKEN \
  --count 3 \
  --labels "self-hosted,linux,x64,staging" \
  --name "staging-runner" \
  --dir /opt/runners/staging

# Development runners
./scripts/quick-deploy.sh \
  --org https://github.com/acme \
  --token $DEV_TOKEN \
  --count 2 \
  --labels "self-hosted,linux,x64,dev" \
  --name "dev-runner" \
  --dir /opt/runners/dev
```

---

## Troubleshooting

### Common Issues

#### Issue: "No runner services found"

**Cause:** Runner service not installed or configured.

**Solution:**
```bash
# Re-run configuration
cd $HOME/actions-runner
sudo ./svc.sh install
sudo ./svc.sh start

# Verify
systemctl status actions.runner.*.service
```

#### Issue: "Disk usage critical"

**Cause:** Insufficient disk space.

**Solution:**
```bash
# Clean runner logs
rm -rf $HOME/actions-runner/_diag/*.log.*

# Clean work directories
rm -rf $HOME/actions-runner/_work/*

# Clean Docker
docker system prune -a -f --volumes

# Verify
df -h $HOME/actions-runner
```

#### Issue: "Network connectivity failed"

**Cause:** Firewall, proxy, or DNS issues.

**Solution:**
```bash
# Test DNS
nslookup github.com

# Test with curl
curl -v https://api.github.com

# Configure proxy (if needed)
export HTTPS_PROXY=http://proxy.example.com:8080
export HTTP_PROXY=http://proxy.example.com:8080

# Update runner proxy settings
cd $HOME/actions-runner
./config.sh remove
./config.sh --url ... --token ... --proxyurl http://proxy.example.com:8080
```

#### Issue: "Runner offline after deployment"

**Cause:** Service failed to start or token expired.

**Solution:**
```bash
# Check service status
systemctl status actions.runner.*.service

# Check logs
journalctl -u actions.runner.*.service -n 50

# Regenerate token and reconfigure
TOKEN=$(gh api /orgs/YOUR_ORG/actions/runners/registration-token | jq -r .token)
cd $HOME/actions-runner
./config.sh remove
./config.sh --url https://github.com/YOUR_ORG --token $TOKEN
sudo ./svc.sh install
sudo ./svc.sh start
```

### Debug Mode

```bash
# Enable verbose output
export DEBUG=1

# Run with bash tracing
bash -x ./scripts/quick-deploy.sh

# Check detailed logs
tail -f /tmp/quick-deploy-*.log
```

### Health Check Failures

| Check | Failure | Remedy |
|-------|---------|--------|
| Service | Service not running | `sudo systemctl start actions.runner.*.service` |
| Disk | Usage >90% | Clean logs and artifacts |
| Network | Cannot reach GitHub | Check firewall and proxy |
| Registration | Missing credentials | Re-run config.sh |

---

## Advanced Usage

### Custom Health Checks

Create custom health check scripts:

```bash
#!/bin/bash
# custom-health-check.sh

# Call standard health check
./scripts/health-check.sh --json > /tmp/health.json

# Custom checks
EXIT_CODE=$(jq -r '.exit_code' /tmp/health.json)

if [ $EXIT_CODE -gt 0 ]; then
    # Send Slack notification
    curl -X POST https://hooks.slack.com/... \
      -d "{\"text\":\"Runner health alert: exit code $EXIT_CODE\"}"

    # Create incident
    gh api /repos/YOUR_ORG/YOUR_REPO/issues \
      -f title="Runner Health Alert" \
      -f body="Health check failed with exit code $EXIT_CODE"
fi
```

### Dashboard Integration

Integrate dashboard with monitoring systems:

```bash
# Export to Prometheus
./scripts/runner-status-dashboard.sh --org acme --json | \
  jq -r '.local_runners[] |
    "runner_status{name=\"\(.name)\"} \(if .status == "online" then 1 else 0 end)"' \
  > /var/lib/prometheus/runner_metrics.prom

# Export to InfluxDB
./scripts/runner-status-dashboard.sh --org acme --json | \
  jq -r '.local_runners[] |
    "runner_status,name=\(.name) status=\"\(.status)\" \(now | floor)"' | \
  curl -X POST http://localhost:8086/write?db=runners --data-binary @-
```

### Automated Scaling

```bash
#!/bin/bash
# auto-scale-runners.sh

# Get queue size
QUEUE_SIZE=$(./scripts/runner-status-dashboard.sh --org acme --json | \
  jq '.job_queue | length')

# Get online runners
ONLINE_RUNNERS=$(./scripts/runner-status-dashboard.sh --org acme --json | \
  jq '[.local_runners[] | select(.status == "online")] | length')

# Scale up if queue > runners * 2
if [ $QUEUE_SIZE -gt $((ONLINE_RUNNERS * 2)) ]; then
    echo "Scaling up: queue=$QUEUE_SIZE, runners=$ONLINE_RUNNERS"
    ./scripts/quick-deploy.sh --count 2 --non-interactive
fi
```

### Multi-Organization Support

```bash
#!/bin/bash
# multi-org-dashboard.sh

ORGS=("acme" "example" "test-org")

for org in "${ORGS[@]}"; do
    echo "=== $org ==="
    ./scripts/runner-status-dashboard.sh \
      --org "$org" \
      --refresh 0 \
      --compact
    echo ""
done
```

---

## Best Practices

### Security

1. **Token Management:**
   - Use short-lived tokens
   - Rotate tokens regularly
   - Never commit tokens to version control

2. **Access Control:**
   - Use runner groups for segmentation
   - Apply principle of least privilege
   - Audit runner access regularly

3. **Monitoring:**
   - Enable continuous health checks
   - Set up alerting for failures
   - Monitor security logs

### Performance

1. **Resource Allocation:**
   - Monitor disk space proactively
   - Clean artifacts regularly
   - Size runners appropriately

2. **Network Optimization:**
   - Use local caching when possible
   - Configure proxies correctly
   - Monitor bandwidth usage

3. **Scaling:**
   - Plan for peak loads
   - Implement auto-scaling
   - Test under load

### Maintenance

1. **Regular Tasks:**
   - Weekly: Review logs and metrics
   - Monthly: Update runner software
   - Quarterly: Audit security and access

2. **Documentation:**
   - Keep runbooks updated
   - Document custom configurations
   - Share knowledge with team

3. **Automation:**
   - Automate routine checks
   - Script common remediation
   - Integrate with existing tools

---

## Support and Resources

### Documentation

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Self-Hosted Runners Guide](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Runner API Reference](https://docs.github.com/en/rest/actions/self-hosted-runners)

### Tools

- [GitHub CLI](https://cli.github.com/)
- [jq](https://stedolan.github.io/jq/)
- [systemd](https://systemd.io/)

### Getting Help

1. **Check Logs:**
   - Runner logs: `$RUNNER_DIR/_diag/Runner_*.log`
   - Service logs: `journalctl -u actions.runner.*.service`
   - Script logs: `/tmp/quick-deploy-*.log`

2. **Run Diagnostics:**
   ```bash
   ./scripts/health-check.sh
   ./scripts/runner-status-dashboard.sh --org YOUR_ORG
   ```

3. **Community:**
   - GitHub Discussions
   - Stack Overflow (tag: github-actions)
   - GitHub Actions Community Forum

---

## Appendix

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `RUNNER_DIR` | Runner installation directory | `$HOME/actions-runner` |
| `GITHUB_TOKEN` | GitHub API token | - |
| `GITHUB_ORG` | GitHub organization | - |
| `GITHUB_API` | GitHub API endpoint | `https://api.github.com` |
| `HTTPS_PROXY` | HTTPS proxy URL | - |
| `HTTP_PROXY` | HTTP proxy URL | - |

### File Locations

```
$HOME/actions-runner/
├── .runner              # Runner configuration
├── .credentials         # Runner credentials
├── _diag/              # Diagnostic logs
│   └── Runner_*.log    # Runner logs
├── _work/              # Job workspace
└── bin/                # Runner binaries
```

### Service Management

```bash
# Systemd (Linux/WSL)
sudo systemctl status actions.runner.*.service
sudo systemctl start actions.runner.*.service
sudo systemctl stop actions.runner.*.service
sudo systemctl restart actions.runner.*.service

# View logs
journalctl -u actions.runner.*.service -f

# Launchd (macOS)
launchctl list | grep actions.runner
launchctl start actions.runner.*
launchctl stop actions.runner.*
```

---

**Document Version:** 1.0.0
**Last Updated:** 2025-10-17
**Maintained By:** DX Optimization Team
