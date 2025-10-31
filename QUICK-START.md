# Quick Start Guide - Self-Hosted GitHub Actions Runners

**Platform:** Windows + WSL 2.0 / Linux / macOS
**Installation Time:** 5-10 minutes per runner

---

## Prerequisites (2 minutes)

```bash
# Ubuntu/Debian/WSL
sudo apt-get update && sudo apt-get install -y curl jq tar systemd

# macOS
brew install curl jq

# Verify installation
command -v curl jq tar systemctl
```

---

## Generate Registration Token (1 minute)

### Method 1: GitHub UI
1. Go to: `https://github.com/organizations/YOUR_ORG/settings/actions/runners/new`
2. Copy the token from the configuration command

### Method 2: GitHub API
```bash
export ORG="your-org"
export PAT="ghp_your_personal_access_token"

RUNNER_TOKEN=$(curl -s -X POST \
  -H "Authorization: token $PAT" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/orgs/$ORG/actions/runners/registration-token \
  | jq -r '.token')

echo $RUNNER_TOKEN
```

---

## Install Single Runner (3 minutes)

```bash
# Navigate to project directory
cd ~/github-act

# Make scripts executable
chmod +x scripts/*.sh

# Install runner
./scripts/setup-runner.sh \
  --org "your-org" \
  --token "your-registration-token"

# Validate installation
./scripts/validate-setup.sh --runner-id 1
```

---

## Install Multiple Runners (5-10 minutes)

```bash
export ORG="your-org"
export TOKEN="your-registration-token"

# Install 3 runners
for i in {1..3}; do
  ./scripts/setup-runner.sh \
    --org "$ORG" \
    --token "$TOKEN" \
    --runner-id "$i" \
    --name "runner-wsl-prod-$i"
  sleep 5
done

# Validate all
./scripts/validate-setup.sh
```

---

## Common Commands

### Check Runner Status
```bash
# Service status
cd ~/actions-runner-1
sudo ./svc.sh status

# Or via systemd
systemctl --user status actions.runner.YOUR_ORG.RUNNER_NAME
```

### View Logs
```bash
# Follow logs
journalctl -u actions.runner.YOUR_ORG.RUNNER_NAME -f

# Last 100 lines
journalctl -u actions.runner.YOUR_ORG.RUNNER_NAME -n 100
```

### Restart Runner
```bash
cd ~/actions-runner-1
sudo ./svc.sh stop
sudo ./svc.sh start
```

### Manage Labels
```bash
# List labels
./scripts/configure-labels.sh --runner-id 1 --action list

# Validate labels
./scripts/configure-labels.sh --runner-id 1 --action validate
```

---

## Verify in GitHub

1. Navigate to: `https://github.com/organizations/YOUR_ORG/settings/actions/runners`
2. Your runner should show as **"Idle"** (green status)

---

## Test Workflow

Create `.github/workflows/test-runner.yml`:

```yaml
name: Test Self-Hosted Runner
on: workflow_dispatch

jobs:
  test:
    runs-on: [self-hosted, linux, x64, ai-agent]
    steps:
      - name: Check Runner
        run: |
          echo "Runner: $RUNNER_NAME"
          echo "OS: $RUNNER_OS"
          uname -a
```

---

## Troubleshooting

### Runner Not Showing in GitHub
```bash
# Check service status
cd ~/actions-runner-1
sudo ./svc.sh status

# Check logs
journalctl -u actions.runner.YOUR_ORG.RUNNER_NAME -n 50

# Restart service
sudo ./svc.sh stop && sudo ./svc.sh start
```

### Validation Failures
```bash
# Run validation with fix mode
./scripts/validate-setup.sh --runner-id 1 --fix
```

### Network Issues
```bash
# Test GitHub connectivity
curl -s https://api.github.com
curl -s https://github.com

# Check DNS
nslookup github.com
```

---

## Default Labels

All runners installed with default labels:
- `self-hosted`
- `linux`
- `x64`
- `ai-agent`
- `wsl-ubuntu-22.04`

---

## File Locations

- **Runner Directory:** `~/actions-runner-N/`
- **Work Directory:** `~/actions-runner-N/_work/`
- **Configuration:** `~/actions-runner-N/.runner`
- **Credentials:** `~/actions-runner-N/.credentials`
- **Logs:** `journalctl -u actions.runner.*`

---

## Next Steps

1. Read full documentation: `docs/runner-installation-guide.md`
2. Review validation output: `./scripts/validate-setup.sh`
3. Test with a workflow
4. Monitor runner status in GitHub UI

---

## Support

- **Full Documentation:** `docs/runner-installation-guide.md`
- **Wave 2 Spec:** `specs/wave2-infrastructure-spec.md`
- **GitHub Docs:** https://docs.github.com/actions/hosting-your-own-runners

---

**Version:** 1.0.0
**Last Updated:** 2025-10-17
