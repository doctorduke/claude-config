# Deployment Guide

## Quick Start (15 Minutes)

### 1. Install Runner
```bash
./scripts/setup-runner.sh --org YOUR_ORG --token YOUR_TOKEN --name runner-01
```

### 2. Configure Secrets
```bash
gh secret set AI_API_KEY --org YOUR_ORG --body "your-key"
gh secret set AI_API_ENDPOINT --org YOUR_ORG --body "https://api.anthropic.com/v1"
```

### 3. Deploy Workflows
```bash
cp .github/workflows/*.yml YOUR_REPO/.github/workflows/
git add .github/workflows && git commit -m "Add AI workflows" && git push
```

### 4. Test
```bash
gh workflow run ai-pr-review.yml -f pr_number=123
gh run list --limit 5
```

## Prerequisites

**System:** 4+ cores, 8+ GB RAM, 200+ GB SSD
**OS:** Ubuntu 20.04+, Windows+WSL 2.0, macOS 12+
**Software:** Git 2.25+, gh CLI, jq, curl, bash
**GitHub:** Org admin access, runner registration token

## Installation Steps

### Environment Setup
```bash
sudo apt update && sudo apt install -y git curl jq
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo apt install gh -y
gh auth login
```

### Single Runner
```bash
./scripts/setup-runner.sh --org ORG --token TOKEN --name runner-01 --labels "self-hosted,linux,x64,ai-agent"
./scripts/validate-setup.sh
```

### Multiple Runners (Recommended: 3-5)
```bash
for i in {1..5}; do
  ./scripts/setup-runner.sh --org ORG --token TOKEN --name "runner-0$i" --labels "self-hosted,linux,x64,ai-agent"
done
```

## Validation

```bash
# Health check
./scripts/validate-setup.sh

# Test connectivity
./scripts/test-connectivity.sh

# Verify runner status
gh api orgs/YOUR_ORG/actions/runners
```

## Post-Deployment

### Enable Auto-Start
```bash
sudo systemctl enable actions.runner.ORG.runner-01.service
sudo systemctl start actions.runner.ORG.runner-01.service
```

### Configure Monitoring
```bash
./scripts/runner-status-dashboard.sh --enable
./scripts/setup-alerts.sh --queue-threshold 10
```

## Troubleshooting

**Runner not connecting:**
```bash
sudo systemctl status actions.runner.*
journalctl -u actions.runner.ORG.runner-01 -n 50
sudo systemctl restart actions.runner.ORG.runner-01
```

**Workflow failing:**
```bash
gh run view RUN_ID --log
# Check secrets: gh secret list --org ORG
# Check permissions in workflow YAML
```

## Rollback

```bash
sudo systemctl stop actions.runner.*
./scripts/restore-runner-config.sh --from /backup/TIMESTAMP
sudo systemctl start actions.runner.*
```

## Multi-Environment

**Dev:** 1-2 runners with label "env-dev"
**Staging:** 2-3 runners with label "env-staging"
**Production:** 5+ runners with label "env-prod"

## Next Steps

1. Verify runners online: `gh api orgs/ORG/actions/runners`
2. Test on sample PRs
3. Monitor for 24-48 hours
4. Roll out to all repositories
5. Train team

**See also:** TECHNICAL-MANUAL.md, OPERATIONS-PLAYBOOK.md, troubleshooting-guide.md
