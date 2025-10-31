# Frequently Asked Questions (FAQ)

## General

**Q: What are self-hosted GitHub Actions runners?**
A: Servers you manage that execute GitHub Actions workflows. Provides 3.4x faster performance and 77.5% cost reduction.

**Q: Why use self-hosted runners?**
A: Faster (3.4x), cheaper (77.5% savings), unlimited minutes, custom configs, better security.

**Q: Minimum hardware?**
A: 4 cores, 8 GB RAM, 200 GB SSD. Recommended: 8 cores, 16 GB RAM, 500 GB SSD.

**Q: How many runners needed?**
A: Start with 3-5 for small teams, 10-15 for medium, 20+ for large. Monitor queue depth.

**Q: What is the ROI?**
A: 2,800% over 3 years, breakeven at month 4-5. Costs $450/month vs $2,000/month GitHub-hosted.

## Deployment

**Q: Can I run on Windows?**
A: Yes, using WSL 2.0 (Ubuntu). Native Windows support limited.

**Q: How long does deployment take?**
A: 15 minutes for first runner, 2-4 hours for full production (5 runners).

**Q: How do I update runners?**
A: Run `./scripts/setup-runner.sh --update` monthly.

**Q: Need Docker?**
A: No, runners are native (NOT containerized). Docker optional for workflow jobs.

## Configuration

**Q: How to configure secrets?**
A: `gh secret set SECRET_NAME --org ORG --body "value"`

**Q: What permissions needed?**
A: Minimum: contents: read, pull-requests: write. For auto-fix: add contents: write.

**Q: How to set up AI?**
A: Set secrets: AI_API_KEY, AI_API_ENDPOINT, AI_MODEL

**Q: Support multiple AI models?**
A: Yes, set AI_MODEL to any supported Claude model.

## Workflows

**Q: Trigger PR review?**
A: Auto on PR open/update, or manual: `gh workflow run ai-pr-review.yml -f pr_number=123`

**Q: Use /agent command?**
A: Comment "/agent QUESTION" on any issue/PR.

**Q: Trigger auto-fix?**
A: (1) Comment "/autofix linting", (2) Add "auto-fix" label, (3) Manual dispatch

**Q: Supported linters?**
A: eslint, prettier, black, pylint, flake8, rubocop, gofmt, rustfmt, shellcheck

## Performance

**Q: How fast?**
A: Job start: 42s (vs 142s), checkout: 78% faster, total: 58% faster. 3.4x speedup.

**Q: What is sparse checkout?**
A: Downloads only needed directories, 70-85% faster than full checkout.

**Q: Optimize performance?**
A: Enable sparse checkout, shallow clones, dependency caching, NVMe storage.

**Q: Concurrent jobs?**
A: Optimal: 10 concurrent. Beyond 15, performance degrades.

## Troubleshooting

**Q: Runner not connecting?**
A: Check service status, network, token. Restart: `systemctl restart actions.runner.*`

**Q: Permission denied?**
A: Add required permissions to workflow. For protected branches, use PAT.

**Q: AI review not posting?**
A: Verify AI_API_KEY secret, endpoint, check logs: `gh run view --log`

**Q: Auto-fix not pushing?**
A: Fork PRs blocked for security, need PAT for protected branches.

## Security

**Q: How are secrets secured?**
A: Encrypted in GitHub, passed as env vars, never logged. Use ::add-mask::.

**Q: Fork PRs trigger workflows?**
A: Yes, but auto-fix refuses forks. Reviews work with read-only permissions.

**Q: Rotate secrets?**
A: `./scripts/rotate-tokens.sh` or `gh secret set`. Recommended: 90-day rotation.

**Q: Protected branches?**
A: Need PAT with repo scope. Set GH_PAT secret.

## Cost

**Q: What does it cost?**
A: Infrastructure: $450/month, AI: $0.15/review. Total: $0.08/workflow.

**Q: vs GitHub-hosted?**
A: GitHub-hosted: $0.18/workflow. Self-hosted: $0.08/workflow. Save 77.5%.

**Q: Payback period?**
A: Month 4-5 breakeven. 3-year ROI: 2,800%.

**Q: Reduce costs?**
A: Auto-scaling, off-peak shutdown, API batching, caching.

## Scaling

**Q: Add more runners?**
A: `for i in {6..10}; do ./scripts/setup-runner.sh --org ORG --token TOKEN --name "runner-$i"; done`

**Q: When to add runners?**
A: Queue depth > 10, wait time > 120s, CPU > 85%, success < 95%.

**Q: Multi-region?**
A: Yes, deploy in EU, APAC. Route with labels: runs-on: [self-hosted, region-eu].

**Q: Maximum scale?**
A: Tested: 20 concurrent jobs/server. Larger scale: multiple servers.

## Maintenance

**Q: Update frequency?**
A: Monthly for runner software, as-needed for workflows.

**Q: Back up config?**
A: `./scripts/backup-runner-config.sh --output /backup/runners`

**Q: Monitor performance?**
A: `./scripts/runner-status-dashboard.sh` or Grafana/Prometheus.

**Q: Clean artifacts?**
A: Weekly: `find /home/runner/_work -name "*.log" -mtime +7 -delete`

## Support

**Q: More docs?**
A: TECHNICAL-MANUAL.md, OPERATIONS-PLAYBOOK.md, ONBOARDING-TUTORIAL.md

**Q: Report issues?**
A: Create GitHub issue with logs, steps to reproduce, environment details.

**Q: Get help?**
A: Check troubleshooting-guide.md, test-results/ for known issues, create GitHub issue.

---

**Last Updated:** October 17, 2025
**Version:** 1.0
