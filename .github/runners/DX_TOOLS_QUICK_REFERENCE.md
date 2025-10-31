# DX Tools Quick Reference Card

> Fast reference for GitHub Actions runner automation tools

## 🚀 Quick Start (3 Commands)

```bash
# 1. Deploy runners
./scripts/quick-deploy.sh

# 2. Check health
./scripts/health-check.sh

# 3. View dashboard
./scripts/runner-status-dashboard.sh --org YOUR_ORG
```

---

## 📋 Tool Summary

| Tool | Purpose | Key Feature |
|------|---------|-------------|
| `quick-deploy.sh` | Deploy runners | One-command setup, 1-20 runners |
| `health-check.sh` | Monitor health | 6 checks, exit codes 0/1/2 |
| `runner-status-dashboard.sh` | Live status | Real-time updates, job queue |

---

## ⚡ Most Common Commands

### Deploy Runners

```bash
# Interactive (recommended for first time)
./scripts/quick-deploy.sh

# Automated deployment
./scripts/quick-deploy.sh \
  --org https://github.com/myorg \
  --token ghp_xxxxxxxxxxxx \
  --count 5 \
  --non-interactive
```

### Check Health

```bash
# One-time check
./scripts/health-check.sh

# Continuous monitoring (every 60s)
./scripts/health-check.sh --continuous --interval 60

# JSON output for automation
./scripts/health-check.sh --json > status.json
```

### View Dashboard

```bash
# Live dashboard (auto-refresh every 30s)
./scripts/runner-status-dashboard.sh --org myorg

# Compact view
./scripts/runner-status-dashboard.sh --org myorg --compact

# One-time snapshot
./scripts/runner-status-dashboard.sh --org myorg --refresh 0
```

---

## 🔧 Quick Deploy Options

```bash
--org URL          # GitHub org URL (required)
--token TOKEN      # Registration token (required)
--count N          # Number of runners (default: 3)
--labels LABELS    # Comma-separated labels
--name PREFIX      # Runner name prefix (default: runner)
--non-interactive  # Skip all prompts
--skip-deps        # Skip dependency install
```

**Example:**
```bash
./scripts/quick-deploy.sh \
  --org https://github.com/acme \
  --token ghp_abc123 \
  --count 5 \
  --labels "self-hosted,linux,x64,prod" \
  --name "prod-runner"
```

---

## 🏥 Health Check Exit Codes

| Code | Status | Action |
|------|--------|--------|
| 0 | ✅ Healthy | None |
| 1 | ⚠️ Warning | Review output |
| 2 | ❌ Critical | Immediate action |

**Checks Performed:**
1. Runner service status
2. Disk space (warn 80%, error 90%)
3. Network connectivity (GitHub endpoints)
4. Runner registration (config/credentials)
5. Recent log errors
6. System resources (CPU, memory, load)

---

## 📊 Dashboard Sections

```
1. System Info       → Timestamp, org, load, memory
2. Runners           → Status, ID, labels for each runner
3. Job Queue         → Queued workflows with wait times
4. Recent Workflows  → Last 10 runs with success rate
```

**Status Icons:**
- 🟢 `●` Online/Success
- 🔴 `●` Offline/Failed
- 🟡 `●` Idle/Warning
- 🔵 `●` Running/Active

---

## 🐛 Quick Troubleshooting

### Issue: No runners found
```bash
# Check directory
ls -la $HOME/actions-runner

# Re-deploy
./scripts/quick-deploy.sh
```

### Issue: Disk space critical
```bash
# Clean logs
rm -rf $HOME/actions-runner/_diag/*.log.*

# Clean work dir
rm -rf $HOME/actions-runner/_work/*
```

### Issue: Service offline
```bash
# Restart service
sudo systemctl restart actions.runner.*.service

# Check logs
sudo journalctl -u actions.runner.*.service -n 50
```

### Issue: Network connectivity failed
```bash
# Test DNS
nslookup github.com

# Test connectivity
curl -v https://api.github.com

# Set proxy (if needed)
export HTTPS_PROXY=http://proxy.example.com:8080
```

---

## 🔑 Get Registration Token

```bash
# Via GitHub CLI
gh api /orgs/YOUR_ORG/actions/runners/registration-token | jq -r .token

# Via Web UI
# Go to: https://github.com/YOUR_ORG/settings/actions/runners/new
```

---

## 📁 File Locations

```
$HOME/actions-runner/
├── .runner              # Runner config
├── .credentials         # Runner credentials
├── _diag/              # Logs
│   └── Runner_*.log
└── _work/              # Job workspace
```

---

## 🔄 Common Workflows

### First-Time Setup
```bash
1. ./scripts/quick-deploy.sh
2. ./scripts/health-check.sh
3. ./scripts/runner-status-dashboard.sh --org myorg
```

### Production Deployment
```bash
./scripts/quick-deploy.sh \
  --org https://github.com/prod-org \
  --token $PROD_TOKEN \
  --count 5 \
  --labels "self-hosted,linux,x64,prod" \
  --non-interactive

./scripts/health-check.sh --continuous --interval 60 &
./scripts/runner-status-dashboard.sh --org prod-org
```

### Automated Monitoring
```bash
# Cron job (every 5 minutes)
*/5 * * * * /path/to/scripts/health-check.sh --json > /var/log/runner-health.json

# Alert on critical
./scripts/health-check.sh || \
  echo "Runner health issue" | mail -s "Alert" ops@example.com
```

---

## 🌐 Environment Variables

```bash
export RUNNER_DIR=$HOME/actions-runner    # Runner directory
export GITHUB_ORG=myorg                   # GitHub org
export GITHUB_TOKEN=ghp_xxx               # GitHub token
export HTTPS_PROXY=http://proxy:8080     # Proxy (if needed)
```

---

## 🚨 Emergency Commands

```bash
# Stop all runners
sudo systemctl stop 'actions.runner.*.service'

# Restart all runners
sudo systemctl restart 'actions.runner.*.service'

# View all runner services
systemctl list-units --type=service | grep actions.runner

# Check runner logs
tail -f $HOME/actions-runner-1/_diag/Runner_*.log

# Remove runner
cd $HOME/actions-runner-1 && ./config.sh remove
```

---

## 📚 Documentation

- **Full Guide:** `docs/developer-tools-guide.md`
- **Wave 2 Spec:** `specs/wave2-infrastructure-spec.md`
- **Summary:** `WAVE2_DX_OPTIMIZER_SUMMARY.md`

---

## 💡 Pro Tips

1. **Use `--json` for automation** - All tools support JSON output
2. **Set environment variables** - Reduce repetitive typing
3. **Enable continuous monitoring** - Catch issues early
4. **Check logs first** - Most issues are in runner logs
5. **Use compact view** - Faster dashboard for quick checks

---

## 🔗 Quick Links

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Self-Hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)
- [GitHub CLI](https://cli.github.com/)
- [Runner API](https://docs.github.com/en/rest/actions/self-hosted-runners)

---

**Need Help?**
```bash
./scripts/quick-deploy.sh --help
./scripts/health-check.sh --help
./scripts/runner-status-dashboard.sh --help
```

---

*Last Updated: 2025-10-17 | Wave 2 DX Optimizer*
