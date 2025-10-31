# E2E Tests - Quick Start Guide

## 30-Second Setup

```bash
# 1. Set environment
export GITHUB_TOKEN="your-token"
export TEST_REPO="owner/repo"

# 2. Go to E2E directory
cd scripts/tests/e2e

# 3. Run validation
bash validate-tests.sh

# 4. Run all tests
bash run-all-e2e-tests.sh
```

## Run Individual Tests

```bash
# PR Review Journey
bash test-pr-review-journey.sh

# Issue Analysis Journey
bash test-issue-analysis-journey.sh

# Auto-Fix Journey
bash test-autofix-journey.sh

# Runner Lifecycle
bash test-runner-lifecycle.sh

# Failure Recovery
bash test-failure-recovery.sh
```

## Run via GitHub Actions

```bash
# Run all tests
gh workflow run e2e-tests.yml

# Run specific suite
gh workflow run e2e-tests.yml \
  -f test_suite=pr-review \
  -f environment=staging
```

## Check Results

```bash
# View latest report
cd test-results/e2e
cat e2e-report-*.txt | tail -50

# View JSON report
jq '.' e2e-report-*.json | tail -50
```

## Common Issues

### "Workflow not triggered"
- Enable GitHub Actions in repository
- Check workflow file exists: `.github/workflows/e2e-tests.yml`

### "API rate limit"
- Use authenticated `GITHUB_TOKEN`
- Run during off-peak hours

### "Tests timing out"
- Increase timeout in environment: `export WORKFLOW_COMPLETION_TIMEOUT=900`
- Check runner availability

## Success Criteria

- Pass rate ≥ 60%
- Performance within targets
- No security issues

## Documentation

- **Full README:** `scripts/tests/e2e/README.md`
- **Implementation Summary:** `docs/E2E-TEST-SUMMARY.md`
- **Completion Report:** `TASK17-COMPLETION-REPORT.md`

## Support

See troubleshooting section in README.md or TASK17-COMPLETION-REPORT.md
