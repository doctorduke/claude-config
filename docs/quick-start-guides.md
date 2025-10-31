# Quick Start Guides

## 1. Developer Quick Start (Create Workflows)

**Goal**: Create your first AI-powered PR review workflow in 15 minutes

**Prerequisites**:
- Access to repository with self-hosted runners
- Basic YAML knowledge

**Steps**:

1. Create workflow file: `.github/workflows/ai-pr-review.yml`

```yaml
name: AI PR Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    runs-on: [self-hosted, linux, ai-agent]
    permissions:
      contents: read
      pull-requests: write

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          sparse-checkout: |
            src/
            tests/

      - name: Run AI Review
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          AI_API_KEY: ${{ secrets.AI_API_KEY }}
        run: |
          git diff origin/${{ github.base_ref }}...HEAD > pr-diff.txt
          ./scripts/ai-review.sh pr-diff.txt > review.json

          gh pr review ${{ github.event.pull_request.number }} \
            --$(jq -r '.event' review.json) \
            --body "$(jq -r '.body' review.json)"
```

2. Commit and push to trigger on next PR

3. Verify workflow runs on self-hosted runner

**Next Steps**: Add issue comment automation, auto-fix workflows

---

## 2. Operations Quick Start (Administer Runners)

**Goal**: Install and configure self-hosted runner in 20 minutes

**Prerequisites**:
- Windows 10/11 with WSL 2.0 (Ubuntu 22.04)
- GitHub org admin access
- Registration token from GitHub

**Steps**:

1. Download runner in WSL:
```bash
mkdir ~/actions-runner && cd ~/actions-runner
curl -o actions-runner-linux-x64-2.314.1.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.314.1/actions-runner-linux-x64-2.314.1.tar.gz
tar xzf actions-runner-linux-x64-2.314.1.tar.gz
```

2. Configure runner:
```bash
./config.sh \
  --url https://github.com/YOUR_ORG \
  --token YOUR_REGISTRATION_TOKEN \
  --labels self-hosted,linux,x64,ai-agent \
  --name runner-1 \
  --work _work \
  --unattended
```

3. Install as service:
```bash
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status
```

4. Verify runner online in GitHub UI: Settings > Actions > Runners

**Next Steps**: Set up monitoring, add more runners, configure runner groups

---

## 3. Security Quick Start (Secure Infrastructure)

**Goal**: Implement security best practices in 30 minutes

**Prerequisites**:
- Runners installed
- Org admin access

**Steps**:

1. **Configure Minimal Permissions**
```yaml
# In every workflow
permissions:
  actions: none
  checks: none
  contents: read  # Only if needed
  pull-requests: write  # Only if needed
```

2. **Create PAT for Branch Protection**
- GitHub Settings > Developer settings > Personal access tokens > Fine-grained tokens
- Generate token with repo scope
- Set expiration: 90 days
- Add as org secret: `BOT_PAT`

3. **Enable Secret Scanning**
- Org Settings > Code security and analysis
- Enable: Secret scanning, Push protection

4. **Configure Network Security**
```bash
# In WSL, configure proxy if needed
export https_proxy=http://proxy:8080

# Verify outbound HTTPS (443) only
sudo iptables -L  # Should allow outbound 443, deny inbound
```

5. **Set Up Audit Logging**
- Enable in GitHub org settings
- Configure log forwarding to SIEM

**Next Steps**: Implement secret rotation, security scanning in workflows

---

## 4. AI Integration Quick Start (Set Up AI Agents)

**Goal**: Integrate AI service in 25 minutes

**Prerequisites**:
- API key from AI provider (Claude, OpenAI, etc.)
- Self-hosted runner online

**Steps**:

1. **Add AI API Key as Secret**
- Org Settings > Secrets and variables > Actions
- New repository secret: `AI_API_KEY`
- Value: Your API key

2. **Create AI Review Script**: `scripts/ai-review.sh`
```bash
#!/usr/bin/env bash
set -euo pipefail

DIFF_FILE=$1
API_KEY=${AI_API_KEY}

# Call AI API
RESPONSE=$(curl -s -X POST https://api.anthropic.com/v1/messages \
  -H "x-api-key: $API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d "{
    \"model\": \"claude-3-5-sonnet-20241022\",
    \"max_tokens\": 4096,
    \"messages\": [{
      \"role\": \"user\",
      \"content\": \"Review this PR diff: $(cat $DIFF_FILE)\"
    }]
  }")

# Parse and format response
echo "$RESPONSE" | jq '{
  event: "COMMENT",
  body: .content[0].text
}'
```

3. **Make script executable**:
```bash
chmod +x scripts/ai-review.sh
```

4. **Test locally**:
```bash
git diff > test-diff.txt
./scripts/ai-review.sh test-diff.txt
```

5. **Use in workflow** (see Developer Quick Start)

**Next Steps**: Add retry logic, rate limiting, multiple AI providers

---

## 5. Migration Quick Start (From GitHub-Hosted)

**Goal**: Migrate existing workflows to self-hosted in 20 minutes

**Prerequisites**:
- Existing workflows on GitHub-hosted runners
- Self-hosted runners installed

**Steps**:

1. **Identify Workflows to Migrate**
```bash
# List all workflows
find .github/workflows -name "*.yml"

# Start with non-critical workflows
```

2. **Update runs-on**
```yaml
# Before
runs-on: ubuntu-latest

# After
runs-on: [self-hosted, linux, ai-agent]
```

3. **Add Sparse Checkout** (performance optimization)
```yaml
# Add to checkout step
- uses: actions/checkout@v4
  with:
    fetch-depth: 1
    sparse-checkout: |
      src/
      tests/
```

4. **Adjust Permissions** (explicit scoping)
```yaml
# Add at job level
permissions:
  contents: read
  pull-requests: write
```

5. **Test Migration**
- Create test PR in migrated repo
- Verify workflow runs on self-hosted runner
- Check job startup time (<60s target)

**Migration Checklist**:
- [ ] Update runs-on to self-hosted
- [ ] Add sparse-checkout for large repos
- [ ] Explicit permissions blocks
- [ ] Test on self-hosted runner
- [ ] Verify performance improvement
- [ ] Monitor for 1 week

**Rollback Plan**: Change `runs-on` back to `ubuntu-latest`

---

## Common Next Steps

After completing quick starts:

1. **Set Up Monitoring**
   - Prometheus + Grafana for runner metrics
   - GitHub Actions usage dashboard

2. **Create Reusable Workflows**
   - Share workflows across repos
   - Reduce duplication

3. **Implement Autoscaling**
   - Add more runners based on queue depth
   - Or deploy Actions Runner Controller (ARC)

4. **Optimize Performance**
   - Fine-tune sparse-checkout patterns
   - Implement caching strategies

5. **Enhance Security**
   - Automate secret rotation
   - Regular security audits

---

## Getting Help

- **Documentation**: See `docs/` directory
- **Troubleshooting**: See `docs/troubleshooting-guide.md`
- **API Reference**: See `docs/api-reference.md`
- **CLI Commands**: See `docs/cli-commands.md`
- **GitHub Actions Docs**: https://docs.github.com/actions
