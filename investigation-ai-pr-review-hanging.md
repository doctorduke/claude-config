# Investigation Report: ai-pr-review.yml Workflow Hanging

**Investigation Date:** 2025-10-27
**Status:** ROOT CAUSE IDENTIFIED
**Severity:** CRITICAL - Blocking all PR reviews

---

## Executive Summary

The ai-pr-review.yml workflow is **not hanging** - it is **permanently queued** because there are **zero self-hosted runners configured or running**. All 20 most recent workflow runs have been stuck in "queued" status for up to 12+ hours, waiting for a runner that doesn't exist.

---

## Evidence

### Workflow Run Analysis

```json
{
  "status": "queued",
  "count": 20,
  "oldest": "2025-10-27T05:27:10Z"
}
```

- 10 most recent runs all show `status: "queued"` with empty `conclusion`
- All triggered by `pull_request` events
- `createdAt` and `updatedAt` timestamps are identical (no progress)
- Oldest queued workflow is 12+ hours old

### Runner Inventory

**Command:** `gh api repos/:owner/:repo/actions/runners`

**Result:** `[]` (empty array)

**Critical Finding:** ZERO self-hosted runners are registered or running.

### Workflow Configuration

**File:** `.github/workflows/ai-pr-review.yml`
**Line 36:** `runs-on: [self-hosted, linux, ai-agent]`

The workflow specifically requires:
- `self-hosted` runner
- `linux` platform
- `ai-agent` label

**Line 43:** `uses: ./.github/actions/mask-secrets`

The workflow's first step references a local composite action, which cannot execute until a runner picks up the job and checks out the repository.

---

## Root Cause Analysis

### Primary Cause

**Missing Self-Hosted Runners**

The workflow is configured to run on self-hosted runners with labels `[self-hosted, linux, ai-agent]`, but zero runners with these labels (or any labels) are registered to the repository/organization.

### Contributing Factors

1. **No Runner Auto-Provisioning**: GitHub Actions does not automatically provision self-hosted runners
2. **No Timeout on Queue**: Workflows remain queued indefinitely until:
   - A matching runner becomes available
   - The workflow is manually cancelled
   - GitHub's internal queue timeout (typically 24-72 hours)
3. **Silent Failure**: No notification or error is raised when runners are missing
4. **Local Action Dependency**: First step uses `./.github/actions/mask-secrets` which cannot execute without a runner

### Why Workflows Appear to "Hang"

- Workflows show as "in progress" in the GitHub UI (yellow spinner)
- No logs are available because no runner has started execution
- Workflows are not timing out because the 5-minute `timeout-minutes: 5` only applies **after** job execution begins
- The queue timeout is extremely long (days), making it appear like a hang

---

## Impact Assessment

### Immediate Impact

- **ALL** PR reviews are blocked
- 20+ workflows consuming queue capacity
- No AI review feedback on pull requests
- Developer productivity impacted

### Historical Impact

- **Oldest queued workflow:** 12+ hours (since 2025-10-27 05:27:10Z)
- **Recent queued workflow:** 30 minutes (since 2025-10-27 17:09:37Z)
- Likely **dozens of PRs** have been merged without AI review

---

## Recommended Solutions

### Immediate Actions (Required)

#### 1. Cancel All Queued Workflows

```bash
# Already attempted - first run (18849604704) was successfully cancelled
# Remaining runs returned 404, indicating they may have been auto-cancelled
```

**Status:** Partially completed. Verify remaining queued runs.

#### 2. Install Self-Hosted Runner(s)

Reference: `docs/runner-installation-guide.md`

**Quick Start:**
```bash
# Generate registration token
gh api repos/:owner/:repo/actions/runners/registration-token --jq '.token'

# Install first runner
./scripts/setup-runner.sh \
  --org "your-org" \
  --token "$RUNNER_TOKEN" \
  --runner-id 1 \
  --name "runner-linux-ai-agent-1" \
  --labels "self-hosted,linux,x64,ai-agent"

# Validate installation
./scripts/validate-setup.sh --runner-id 1
```

**Minimum Requirements:**
- 1 runner to unblock workflows
- Recommended: 3-5 runners for concurrent PR reviews

#### 3. Verify Runner Registration

```bash
# Check runner status
gh api repos/:owner/:repo/actions/runners --jq '.runners[] | {name: .name, status: .status, labels: [.labels[].name]}'
```

Expected output should show at least one runner with:
- `status: "online"`
- Labels including: `self-hosted`, `linux`, `ai-agent`

### Short-Term Actions (Next 24 Hours)

#### 4. Add Fallback to GitHub-Hosted Runners

Modify `.github/workflows/ai-pr-review.yml` to support both runner types:

**Option A: Use GitHub-hosted runners with feature flag**
```yaml
jobs:
  review:
    runs-on: ${{ vars.USE_SELF_HOSTED == 'true' && fromJSON('["self-hosted", "linux", "ai-agent"]') || 'ubuntu-latest' }}
```

**Option B: Separate workflow for GitHub-hosted runners**
Create `.github/workflows/ai-pr-review-fallback.yml` with:
```yaml
jobs:
  review:
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
```

#### 5. Add Pre-Job Runner Health Check

Add a pre-job check to fail fast if no runners are available:

```yaml
jobs:
  check-runners:
    runs-on: ubuntu-latest
    outputs:
      has_runners: ${{ steps.check.outputs.has_runners }}
    steps:
      - name: Check for available runners
        id: check
        run: |
          RUNNER_COUNT=$(gh api repos/${{ github.repository }}/actions/runners --jq '.runners | length')
          echo "has_runners=$([ $RUNNER_COUNT -gt 0 ] && echo 'true' || echo 'false')" >> $GITHUB_OUTPUT
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  review:
    needs: check-runners
    if: needs.check-runners.outputs.has_runners == 'true'
    runs-on: [self-hosted, linux, ai-agent]
    # ... rest of job
```

### Long-Term Actions (Next Week)

#### 6. Implement Runner Monitoring

Set up monitoring for runner availability:

**Option A: Scheduled workflow**
```yaml
name: Monitor Runners
on:
  schedule:
    - cron: '*/15 * * * *'  # Every 15 minutes

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - name: Check runner health
        run: |
          RUNNERS=$(gh api repos/${{ github.repository }}/actions/runners)
          ONLINE=$(echo "$RUNNERS" | jq '[.runners[] | select(.status == "online")] | length')
          if [ "$ONLINE" -eq 0 ]; then
            gh issue create \
              --title "ALERT: No online self-hosted runners" \
              --label "infrastructure,critical" \
              --body "All self-hosted runners are offline. Check runner services."
          fi
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**Option B: External monitoring**
- Prometheus metrics from runner hosts
- Datadog/CloudWatch alerts
- PagerDuty integration

#### 7. Add Runner Auto-Scaling

Implement dynamic runner provisioning:
- AWS Auto Scaling Groups with runner AMIs
- Kubernetes-based runners (Actions Runner Controller)
- Azure Container Instances
- GCP Compute Engine managed instance groups

#### 8. Documentation Updates

Update workflow README to include:
- Runner requirements
- Troubleshooting queued workflows
- Runner health check commands
- Escalation procedures

---

## Configuration Issues Found

### Issue 1: No Runner Availability Check

**Problem:** Workflow assumes runners are always available
**Impact:** Workflows queue indefinitely when runners are missing
**Fix:** Add pre-job runner health check (see Solution #5)

### Issue 2: Timeout Only Applies After Job Start

**Problem:** `timeout-minutes: 5` only applies after a runner picks up the job
**Impact:** Workflows can queue forever without timing out
**Fix:** Add queue timeout monitoring (see Solution #6)

### Issue 3: No Alerting for Missing Runners

**Problem:** No automated alerts when runners go offline
**Impact:** Issues go unnoticed until workflows fail
**Fix:** Implement runner monitoring (see Solution #6)

### Issue 4: Local Action Dependency in First Step

**Problem:** `./.github/actions/mask-secrets` requires repo checkout, but workflow can't start without a runner
**Impact:** Cannot validate action syntax without a runner
**Fix:** Consider using reusable actions from a central repository or moving to inline steps

---

## Preventive Measures

### 1. Pre-Merge Workflow Validation

Add to CI pipeline:
```bash
# Validate workflow syntax
act --list --workflow .github/workflows/ai-pr-review.yml

# Check runner label references
grep -r "runs-on:" .github/workflows/ | grep "self-hosted"
```

### 2. Runner SLA Monitoring

Establish service level objectives:
- **Availability:** >= 99% uptime
- **Response time:** < 30 seconds to pick up queued jobs
- **Capacity:** >= 2 idle runners at all times

### 3. Disaster Recovery Plan

**If all runners go offline:**
1. Cancel queued workflows: `gh run list --json databaseId -q '.[].databaseId' | xargs -I {} gh run cancel {}`
2. Temporarily disable ai-pr-review workflow: `gh workflow disable ai-pr-review.yml`
3. Deploy emergency runner: `./scripts/setup-runner.sh --quick`
4. Re-enable workflow: `gh workflow enable ai-pr-review.yml`

---

## Verification Steps

After implementing fixes:

1. **Verify runner registration:**
   ```bash
   gh api repos/:owner/:repo/actions/runners --jq '.runners[] | {name, status, busy, labels: [.labels[].name]}'
   ```

2. **Trigger test workflow:**
   ```bash
   gh workflow run ai-pr-review.yml --ref main
   ```

3. **Monitor execution:**
   ```bash
   gh run watch $(gh run list --workflow=ai-pr-review.yml --limit 1 --json databaseId -q '.[0].databaseId')
   ```

4. **Check workflow completion:**
   ```bash
   gh run list --workflow=ai-pr-review.yml --limit 5 --json status,conclusion
   ```

Expected results:
- Runner picks up job within 30 seconds
- Workflow completes within 5 minutes
- Status shows `completed` with conclusion `success` or `failure` (not empty)

---

## Related Files

- **Workflow:** `.github/workflows/ai-pr-review.yml`
- **Action:** `.github/actions/mask-secrets/action.yml`
- **Script:** `scripts/ai-review.sh`
- **Installation Guide:** `docs/runner-installation-guide.md`
- **Runner Management:** `docs/runner-group-management.md`

---

## Conclusion

The ai-pr-review.yml workflow is not hanging - it is correctly queued, waiting for self-hosted runners that do not exist. The immediate fix is to install at least one self-hosted runner with the required labels. Long-term solutions include fallback to GitHub-hosted runners, automated runner provisioning, and comprehensive monitoring.

**Next Steps:**
1. Install self-hosted runner (15 minutes)
2. Verify runner is online and accepting jobs (5 minutes)
3. Test ai-pr-review workflow execution (5 minutes)
4. Implement monitoring and alerting (1-2 hours)
5. Document runner maintenance procedures (30 minutes)

**Estimated Time to Resolution:** 25-30 minutes (excluding monitoring setup)
