# Common Pitfalls: Beginner Mistakes to Avoid

Learn from these common mistakes to accelerate your journey with GitHub Actions self-hosted runners. Each pitfall includes why it happens, how to identify it, fix it, and prevent it from recurring.

## Quick Navigation

### Configuration Mistakes
1. [Runner Not Picking Up Jobs](#1-runner-not-picking-up-jobs)
2. [Incorrect Label Matching](#2-incorrect-label-matching)
3. [Wrong Working Directory](#3-wrong-working-directory)
4. [Runner Running as Root](#4-runner-running-as-root)
5. [Forgetting to Start Service](#5-forgetting-to-start-service)

### Security Pitfalls
6. [Hardcoding Secrets in Workflows](#6-hardcoding-secrets-in-workflows)
7. [Using GITHUB_TOKEN for Protected Branches](#7-using-github_token-for-protected-branches)
8. [Excessive Workflow Permissions](#8-excessive-workflow-permissions)
9. [Secrets Visible in Logs](#9-secrets-visible-in-logs)
10. [Public Fork Security Risk](#10-public-fork-security-risk)

### Performance Issues
11. [Not Using Sparse Checkout](#11-not-using-sparse-checkout)
12. [Missing Cache Configuration](#12-missing-cache-configuration)
13. [Sequential Tasks Instead of Parallel](#13-sequential-tasks-instead-of-parallel)
14. [Downloading Dependencies Every Run](#14-downloading-dependencies-every-run)
15. [Large Artifacts Slowing Workflows](#15-large-artifacts-slowing-workflows)

### Deployment Errors
16. [Runner Token Expiration](#16-runner-token-expiration)
17. [Insufficient Disk Space](#17-insufficient-disk-space)
18. [Network Connectivity Issues](#18-network-connectivity-issues)
19. [WSL Clock Drift](#19-wsl-clock-drift)
20. [Forgetting Firewall Rules](#20-forgetting-firewall-rules)

### Workflow Problems
21. [Workflow Syntax Errors](#21-workflow-syntax-errors)
22. [Missing Required Contexts](#22-missing-required-contexts)
23. [Incorrect Event Triggers](#23-incorrect-event-triggers)
24. [Job Dependencies Misconfigured](#24-job-dependencies-misconfigured)
25. [Environment Variables Not Set](#25-environment-variables-not-set)

---

## Configuration Mistakes

### 1. Runner Not Picking Up Jobs

**Description**: Jobs queue indefinitely despite runners being online.

**Why It Happens**:
- Labels don't match between workflow and runner
- Runner is busy with another job
- Runner service not actually running
- Organization/repository permissions issue

**How to Identify**:
```bash
# Check runner status
sudo ~/actions-runner-1/svc.sh status

# Check runner labels
cat ~/actions-runner-1/.runner | jq '.labels'

# Check queued jobs
gh run list --status queued
```

**How to Fix**:
```bash
# Restart runner
sudo ~/actions-runner-1/svc.sh restart

# Re-configure with correct labels
./config.sh --url https://github.com/ORG --token TOKEN --labels "self-hosted,linux,x64" --replace
```

**How to Prevent**:
- Use consistent label naming convention
- Document required labels for each workflow type
- Monitor queue depth regularly
- Set up alerts for jobs queued > 5 minutes

---

### 2. Incorrect Label Matching

**Description**: Workflow can't find runner due to label mismatch.

**Why It Happens**:
```yaml
# Workflow expects:
runs-on: [self-hosted, linux, gpu]

# But runner has:
# Labels: self-hosted, linux, x64
```

**How to Identify**:
```bash
# Compare workflow requirements
grep "runs-on:" .github/workflows/*.yml

# With runner labels
gh api orgs/ORG/actions/runners | jq '.runners[].labels[].name'
```

**How to Fix**:
```bash
# Add missing labels to runner
./config.sh --url https://github.com/ORG \
  --token TOKEN \
  --labels "self-hosted,linux,x64,gpu" \
  --replace
```

**How to Prevent**:
- Standardize label taxonomy
- Use label groups (e.g., `type-`, `os-`, `feature-`)
- Create label documentation
- Validate labels in PR reviews

---

### 3. Wrong Working Directory

**Description**: Runner can't find files or scripts fail due to incorrect paths.

**Why It Happens**:
- Assuming specific directory structure
- Using relative paths incorrectly
- Not setting working-directory in steps

**How to Identify**:
```yaml
# Common error messages:
# "No such file or directory"
# "Cannot find module"
# "Script not found"
```

**How to Fix**:
```yaml
# Specify working directory explicitly
- name: Run script
  working-directory: ./scripts
  run: ./deploy.sh

# Or use full paths
- name: Run script
  run: ${{ github.workspace }}/scripts/deploy.sh
```

**How to Prevent**:
- Always use `working-directory` when needed
- Use `${{ github.workspace }}` for absolute paths
- Test locally first
- Log current directory in workflows

---

### 4. Runner Running as Root

**Description**: Security risk and permission issues from root execution.

**Why It Happens**:
- Installing runner with sudo
- Running config.sh as root
- Service misconfiguration

**How to Identify**:
```bash
# Check runner process owner
ps aux | grep Runner.Listener

# If shows root, that's wrong
root  12345  Runner.Listener  # BAD
user  12345  Runner.Listener  # GOOD
```

**How to Fix**:
```bash
# Stop and reconfigure as regular user
sudo ./svc.sh stop
sudo ./svc.sh uninstall

# Re-run as regular user (not root)
./config.sh --url URL --token TOKEN
./svc.sh install  # Will prompt for sudo when needed
```

**How to Prevent**:
- Never run runner as root
- Create dedicated runner user
- Document setup process clearly
- Add checks in setup script

---

### 5. Forgetting to Start Service

**Description**: Runner configured but not running, jobs queue forever.

**Why It Happens**:
- Skipping service start after configuration
- Service not enabled for auto-start
- System reboot without service enabled

**How to Identify**:
```bash
# Check service status
sudo ./svc.sh status
# Shows: inactive (dead)  # Problem!
```

**How to Fix**:
```bash
# Start the service
sudo ./svc.sh start

# Enable auto-start
sudo systemctl enable actions.runner.ORG.RUNNER_NAME
```

**How to Prevent**:
- Include service start in setup documentation
- Add to setup script automatically
- Create health check monitoring
- Use configuration management tools

---

## Security Pitfalls

### 6. Hardcoding Secrets in Workflows

**Description**: Credentials exposed in workflow files.

**Why It Happens**:
```yaml
# NEVER DO THIS!
- name: Deploy
  run: |
    API_KEY="sk-1234567890abcdef"  # EXPOSED!
    deploy.sh
```

**How to Identify**:
```bash
# Scan for potential secrets
grep -r "password\|api[_-]key\|token\|secret" .github/workflows/
```

**How to Fix**:
```yaml
# Use GitHub secrets instead
- name: Deploy
  env:
    API_KEY: ${{ secrets.API_KEY }}
  run: deploy.sh
```

**How to Prevent**:
- Enable secret scanning
- Use pre-commit hooks
- Regular security audits
- Educate team on secret management

---

### 7. Using GITHUB_TOKEN for Protected Branches

**Description**: Auto-fix fails on protected branches due to insufficient permissions.

**Why It Happens**:
- GITHUB_TOKEN can't bypass branch protection
- Required status checks block automation
- Approval requirements not met

**How to Identify**:
```bash
# Error message:
# "Protected branch update failed"
# "Required status checks have not passed"
```

**How to Fix**:
```yaml
# Use Personal Access Token
- uses: actions/checkout@v4
  with:
    token: ${{ secrets.BOT_PAT }}  # PAT with bypass permissions
```

**How to Prevent**:
- Create bot account with bypass permissions
- Document PAT requirements
- Use branch protection exceptions
- Consider PR-based fixes instead

---

### 8. Excessive Workflow Permissions

**Description**: Workflows have more permissions than needed.

**Why It Happens**:
```yaml
# TOO PERMISSIVE!
permissions: write-all

# Or not specifying at all (defaults to write-all)
```

**How to Identify**:
```bash
# Check for missing or broad permissions
grep -L "permissions:" .github/workflows/*.yml
grep "write-all" .github/workflows/*.yml
```

**How to Fix**:
```yaml
# Specify minimal permissions
permissions:
  contents: read       # Only what's needed
  pull-requests: write # Only what's needed
  actions: none       # Explicitly none
  checks: none        # Explicitly none
```

**How to Prevent**:
- Always specify permissions explicitly
- Use least privilege principle
- Review permissions in PRs
- Create permission templates

---

### 9. Secrets Visible in Logs

**Description**: Sensitive data appears in workflow logs.

**Why It Happens**:
```bash
# Echoing secrets
echo "Token: $API_KEY"  # Will show in logs!

# Command expansion
curl -H "Authorization: $TOKEN" api.example.com  # Token visible!
```

**How to Identify**:
- Review workflow logs for exposed values
- Search for patterns matching keys/tokens
- Check for base64 encoded secrets

**How to Fix**:
```yaml
# Add mask to hide values
- name: Mask secret
  run: |
    echo "::add-mask::${{ secrets.API_KEY }}"
    # Now safe to use

# Use silent mode
curl -s -H "Authorization: $TOKEN" api.example.com 2>/dev/null
```

**How to Prevent**:
- Always mask secrets before use
- Avoid echoing sensitive variables
- Use tools that auto-mask
- Regular log audits

---

### 10. Public Fork Security Risk

**Description**: Workflows running on untrusted fork code.

**Why It Happens**:
```yaml
# Dangerous!
on:
  pull_request_target:  # Runs with write permissions
    types: [opened]

# Combined with
- uses: actions/checkout@v4
  with:
    ref: ${{ github.event.pull_request.head.sha }}  # Untrusted code!
```

**How to Identify**:
- Look for `pull_request_target` events
- Check if checking out PR head
- Review for secret access

**How to Fix**:
```yaml
# Safe approach
on:
  pull_request:  # Runs with read-only
    types: [opened]

# Or if you need pull_request_target:
- uses: actions/checkout@v4
  with:
    ref: ${{ github.event.pull_request.base.sha }}  # Base branch only
```

**How to Prevent**:
- Avoid `pull_request_target` when possible
- Never checkout untrusted code with secrets
- Use environment protection rules
- Regular security reviews

---

## Performance Issues

### 11. Not Using Sparse Checkout

**Description**: Wasting time checking out entire repository.

**Why It Happens**:
```yaml
# Slow - checks out everything
- uses: actions/checkout@v4
```

**How to Identify**:
```bash
# Look for checkout times > 30 seconds
# Check workflow logs for:
# "Checking out the repository" taking long time
```

**How to Fix**:
```yaml
# Fast - only what you need
- uses: actions/checkout@v4
  with:
    sparse-checkout: |
      src/
      tests/
      package.json
    sparse-checkout-cone-mode: false
```

**How to Prevent**:
- Default to sparse checkout
- Document which paths are needed
- Measure checkout times
- Add to workflow templates

---

### 12. Missing Cache Configuration

**Description**: Downloading dependencies repeatedly.

**Why It Happens**:
```yaml
# No caching
- run: npm install  # Downloads everything every time
```

**How to Identify**:
```bash
# Look for repeated downloads
grep "npm install\|pip install\|go mod download" .github/workflows/*.yml
```

**How to Fix**:
```yaml
# With caching
- uses: actions/cache@v3
  with:
    path: ~/.npm
    key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}

- run: npm ci  # Uses cache when available
```

**How to Prevent**:
- Add caching to all templates
- Monitor cache hit rates
- Document cache keys
- Regular cache cleanup

---

### 13. Sequential Tasks Instead of Parallel

**Description**: Running tasks one by one when they could run simultaneously.

**Why It Happens**:
```yaml
# Slow sequential execution
- run: npm test
- run: npm run lint
- run: npm audit
# Total: 3 minutes
```

**How to Identify**:
- Look for independent steps running sequentially
- Check total workflow time vs individual steps

**How to Fix**:
```yaml
# Fast parallel execution
- name: Run checks in parallel
  run: |
    npm test &
    npm run lint &
    npm audit &
    wait
    # Total: 1 minute (runs simultaneously)
```

**How to Prevent**:
- Identify independent tasks
- Use job parallelization
- Create parallel templates
- Monitor execution patterns

---

### 14. Downloading Dependencies Every Run

**Description**: Not leveraging dependency caching effectively.

**Why It Happens**:
- Cache key changes too frequently
- Cache path incorrect
- Not using lock files

**How to Identify**:
```bash
# Check cache hit rate
gh run list --json conclusion,name | jq '.[] | select(.name=="Cache") | .conclusion'
```

**How to Fix**:
```yaml
# Effective caching strategy
- uses: actions/cache@v3
  with:
    path: |
      ~/.npm
      ~/.cache/pip
      ~/go/pkg/mod
    key: ${{ runner.os }}-deps-${{ hashFiles('**/lock-files') }}
    restore-keys: |
      ${{ runner.os }}-deps-
```

**How to Prevent**:
- Use stable cache keys
- Include all dependency paths
- Monitor cache effectiveness
- Regular cache warming

---

### 15. Large Artifacts Slowing Workflows

**Description**: Uploading/downloading huge artifacts between jobs.

**Why It Happens**:
```yaml
# Uploading everything
- uses: actions/upload-artifact@v3
  with:
    path: .  # Entire repository!
```

**How to Identify**:
```bash
# Check artifact sizes
gh run view RUN_ID --json artifacts | jq '.artifacts[].sizeInBytes'
```

**How to Fix**:
```yaml
# Upload only necessary files
- uses: actions/upload-artifact@v3
  with:
    path: |
      dist/
      *.log
    exclude: |
      node_modules/
      *.tmp
```

**How to Prevent**:
- Define artifact requirements
- Use .artifactignore
- Compress before upload
- Clean up old artifacts

---

## Deployment Errors

### 16. Runner Token Expiration

**Description**: Runner registration token expires before use.

**Why It Happens**:
- Token only valid for 1 hour
- Delayed setup after token generation
- Storing tokens for later use

**How to Identify**:
```bash
# Error during config:
# "Http response code: Forbidden"
# "A registration token must be provided"
```

**How to Fix**:
```bash
# Generate fresh token immediately before use
TOKEN=$(gh api orgs/ORG/actions/runners/registration-token --jq .token)
./config.sh --url https://github.com/ORG --token "$TOKEN"
```

**How to Prevent**:
- Automate token generation
- Use just-in-time tokens
- Implement token refresh
- Monitor token expiry

---

### 17. Insufficient Disk Space

**Description**: Workflows fail due to full disk.

**Why It Happens**:
- Old build artifacts accumulating
- Large git repositories
- Docker images not cleaned
- Logs filling disk

**How to Identify**:
```bash
# Check disk usage
df -h
du -sh ~/actions-runner-*/_work

# Error messages:
# "No space left on device"
# "Cannot write to disk"
```

**How to Fix**:
```bash
# Clean up immediately
# Remove old workspaces
find ~/actions-runner-*/_work -maxdepth 2 -type d -mtime +7 -exec rm -rf {} +

# Clear Docker
docker system prune -af

# Clear package manager cache
sudo apt-get clean
```

**How to Prevent**:
- Automated cleanup cron jobs
- Monitor disk usage
- Set workspace retention policies
- Alert on 80% disk usage

---

### 18. Network Connectivity Issues

**Description**: Runner can't reach GitHub or other services.

**Why It Happens**:
- Proxy not configured
- Firewall blocking connections
- DNS resolution issues
- SSL/TLS problems

**How to Identify**:
```bash
# Test connectivity
curl -I https://github.com
ping api.github.com
nslookup github.com
```

**How to Fix**:
```bash
# Configure proxy if needed
export https_proxy=http://proxy:8080
export HTTPS_PROXY=$https_proxy

# Fix DNS
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

# Update certificates
sudo apt-get update && sudo apt-get install ca-certificates
```

**How to Prevent**:
- Document network requirements
- Test connectivity in setup
- Monitor network health
- Use redundant DNS

---

### 19. WSL Clock Drift

**Description**: WSL time out of sync causing authentication failures.

**Why It Happens**:
- WSL2 clock drifts when Windows sleeps
- No automatic time sync
- Affects token validation

**How to Identify**:
```bash
# Check time difference
date
# Compare with Windows time

# Errors:
# "Token expired"
# "Invalid timestamp"
```

**How to Fix**:
```bash
# Sync time immediately
sudo hwclock -s

# Or
sudo ntpdate time.windows.com

# Permanent fix - add to .bashrc
echo 'sudo hwclock -s' >> ~/.bashrc
```

**How to Prevent**:
- Enable automatic time sync
- Add to runner startup script
- Monitor time drift
- Use NTP service

---

### 20. Forgetting Firewall Rules

**Description**: Firewall blocking runner connections.

**Why It Happens**:
- Default firewall too restrictive
- Not allowing GitHub IPs
- Blocking outbound HTTPS

**How to Identify**:
```bash
# Check firewall status
sudo iptables -L
sudo ufw status

# Connection timeouts in logs
```

**How to Fix**:
```bash
# Allow outbound HTTPS
sudo iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT

# Or with ufw
sudo ufw allow out 443/tcp
sudo ufw allow out 80/tcp
```

**How to Prevent**:
- Document firewall requirements
- Include in setup automation
- Test connectivity post-setup
- Monitor blocked connections

---

## Workflow Problems

### 21. Workflow Syntax Errors

**Description**: Workflow fails to parse due to YAML errors.

**Why It Happens**:
```yaml
# Common syntax errors
name: Test
on: push
jobs:
  test:
    runs-on: ubuntu-latest
   steps:  # Wrong indentation!
    - run: echo "test"
```

**How to Identify**:
```bash
# Use actionlint
actionlint .github/workflows/*.yml

# Or GitHub's API
gh workflow list --all
# Shows invalid workflows
```

**How to Fix**:
- Fix indentation (2 spaces)
- Quote special characters
- Validate with yamllint
- Test with action-validator

**How to Prevent**:
- Use YAML linters
- IDE extensions for Actions
- Pre-commit validation
- Workflow templates

---

### 22. Missing Required Contexts

**Description**: Workflow fails due to undefined variables.

**Why It Happens**:
```yaml
# Using undefined context
- run: echo ${{ github.event.pull_request.number }}
# Fails when triggered by push!
```

**How to Identify**:
```bash
# Error: "Unable to resolve context"
# Check workflow logs for undefined variables
```

**How to Fix**:
```yaml
# Add conditionals
- name: Get PR number
  run: |
    if [ "${{ github.event_name }}" = "pull_request" ]; then
      echo ${{ github.event.pull_request.number }}
    else
      echo "Not a PR event"
    fi
```

**How to Prevent**:
- Check context availability
- Use conditional steps
- Provide defaults
- Test different triggers

---

### 23. Incorrect Event Triggers

**Description**: Workflow doesn't run when expected.

**Why It Happens**:
```yaml
# Wrong trigger
on:
  push:
    branches: [master]  # But default branch is 'main'!
```

**How to Identify**:
```bash
# Workflow not appearing in Actions tab
# Check default branch
gh repo view --json defaultBranchRef -q .defaultBranchRef.name
```

**How to Fix**:
```yaml
# Correct trigger
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
```

**How to Prevent**:
- Verify branch names
- Use branch patterns
- Test triggers locally
- Document trigger behavior

---

### 24. Job Dependencies Misconfigured

**Description**: Jobs run in wrong order or fail dependencies.

**Why It Happens**:
```yaml
jobs:
  test:
    runs-on: ubuntu-latest

  deploy:
    needs: tests  # Typo! Should be 'test'
    runs-on: ubuntu-latest
```

**How to Identify**:
```bash
# Jobs skipped unexpectedly
# "Job skipped due to failed dependencies"
```

**How to Fix**:
```yaml
jobs:
  test:
    runs-on: ubuntu-latest

  deploy:
    needs: test  # Correct dependency
    if: success()  # Explicit success check
    runs-on: ubuntu-latest
```

**How to Prevent**:
- Use clear job names
- Validate dependencies
- Test job flow
- Document job relationships

---

### 25. Environment Variables Not Set

**Description**: Scripts fail due to missing environment variables.

**Why It Happens**:
```yaml
# Forgot to set env var
- run: deploy.sh
# Script expects $ENVIRONMENT but it's not set!
```

**How to Identify**:
```bash
# Error: "ENVIRONMENT: unbound variable"
# Script exits with code 1
```

**How to Fix**:
```yaml
# Set environment variables
- name: Deploy
  env:
    ENVIRONMENT: production
    API_URL: ${{ secrets.API_URL }}
  run: deploy.sh
```

**How to Prevent**:
- Document required variables
- Provide defaults in scripts
- Validate before running
- Use env check functions

---

# Prevention Strategies

## Best Practices Checklist

### Before Deployment
- [ ] Test workflows locally using act
- [ ] Validate YAML syntax
- [ ] Review security permissions
- [ ] Check label matching
- [ ] Verify network connectivity

### During Deployment
- [ ] Generate fresh tokens
- [ ] Start services properly
- [ ] Monitor initial runs
- [ ] Check logs for warnings
- [ ] Validate runner status

### After Deployment
- [ ] Set up monitoring
- [ ] Configure alerts
- [ ] Document configuration
- [ ] Schedule maintenance
- [ ] Regular audits

## Tools for Prevention

### Validation Tools
```bash
# Workflow linting
actionlint .github/workflows/*.yml

# YAML validation
yamllint .github/

# Secret scanning
trufflehog filesystem .

# Security checks
checkov -d .github/workflows
```

### Monitoring Scripts
```bash
# Runner health check
for i in {1..5}; do
  sudo ~/actions-runner-$i/svc.sh status
done

# Queue monitoring
gh run list --status queued --json created_at | \
  jq 'map(select((now - (.created_at | fromdate)) > 300))'

# Disk space monitoring
df -h | grep -E "9[0-9]%|100%"
```

## Recovery Procedures

### Quick Recovery Commands
```bash
# Restart all runners
for i in {1..5}; do
  sudo ~/actions-runner-$i/svc.sh restart
done

# Clear all caches
gh cache delete --all

# Cancel stuck workflows
gh run list --status in_progress --json databaseId -q '.[].databaseId' | \
  xargs -I {} gh run cancel {}

# Emergency cleanup
find ~/actions-runner-*/_work -type d -mtime +1 -exec rm -rf {} +
docker system prune -af
```

---

# Conclusion

## Key Takeaways

1. **Most issues are preventable** with proper configuration
2. **Security should never be compromised** for convenience
3. **Performance optimizations** compound over time
4. **Monitoring prevents** major incidents
5. **Documentation saves** future debugging time

## If You Remember Nothing Else

### The Golden Rules
1. **Never run as root**
2. **Never hardcode secrets**
3. **Always use sparse checkout**
4. **Always specify minimal permissions**
5. **Always monitor runner health**

## Getting Help

When you encounter issues:

1. **Check this guide first** - Your issue is likely here
2. **Review logs thoroughly** - The answer is often in the logs
3. **Search GitHub Issues** - Others may have faced the same problem
4. **Ask in GitHub Community** - The community is helpful
5. **Create detailed bug reports** - Help others help you

---

**Version**: 1.0.0
**Last Updated**: 2025-10-17
**Total Pitfalls Documented**: 25
**Estimated Time Saved**: 10+ hours of debugging

*Remember: Everyone makes mistakes. The key is learning from them and helping others avoid the same pitfalls.*