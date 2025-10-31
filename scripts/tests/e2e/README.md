# End-to-End Test Suite

Comprehensive E2E tests for the GitHub Actions Self-Hosted Runner System.

## Overview

This test suite validates complete user journeys from trigger to completion, ensuring all workflows function correctly in production-like environments.

## Test Coverage

### 1. PR Review Journey (`test-pr-review-journey.sh`)
Tests the complete PR review workflow:
- Developer creates PR with code changes
- Workflow triggers automatically
- AI analyzes PR code
- Review is posted to PR
- Review quality validation
- Performance metrics tracking

**Target Duration:** <60s
**Key Validations:**
- Review content quality
- Security analysis included
- Code quality feedback
- Proper attribution

### 2. Issue Analysis Journey (`test-issue-analysis-journey.sh`)
Tests the issue analysis workflow:
- User creates issue with bug report
- User requests analysis via `/analyze`
- Workflow triggers on comment
- AI analyzes issue context
- Response posted as comment
- Auto-labeling applied

**Target Duration:** <30s
**Key Validations:**
- Response structure correct
- Analysis content helpful
- Labels auto-applied
- Comment attribution

### 3. Auto-Fix Journey (`test-autofix-journey.sh`)
Tests the automatic code fixing workflow:
- PR created with linting errors
- User requests `/autofix`
- Branch protection detection
- Fixes applied (direct or PR)
- Code quality improvements
- Verification of changes

**Target Duration:** <90s
**Key Validations:**
- Branch protection respected
- Fixes applied correctly
- No regressions introduced
- Proper commit messages

### 4. Runner Lifecycle (`test-runner-lifecycle.sh`)
Tests complete runner management:
- Runner download
- Configuration
- Registration with GitHub
- Workflow execution
- Health monitoring
- Removal and cleanup

**Target Duration:** <120s
**Key Validations:**
- Runner appears online
- Workflow can execute
- Cleanup is complete
- No orphaned resources

### 5. Failure Recovery (`test-failure-recovery.sh`)
Tests error handling and recovery:
- API failure recovery
- Rate limit handling
- Network timeout recovery
- Git conflict detection
- Invalid input sanitization
- Circuit breaker behavior

**Target Duration:** <60s
**Key Validations:**
- Graceful error handling
- Helpful error messages
- Automatic retry logic
- State recovery

## Quick Start

### Prerequisites

```bash
# Required environment variables
export GITHUB_TOKEN="your-token"
export TEST_REPO="owner/repo"

# Optional
export RUNNER_ORG="your-org"
export TEST_ENV="staging"
```

### Run All Tests

```bash
cd scripts/tests/e2e
bash run-all-e2e-tests.sh
```

### Run Individual Test

```bash
cd scripts/tests/e2e
bash test-pr-review-journey.sh
```

### Run Specific Suite via Workflow

```bash
gh workflow run e2e-tests.yml \
  -f test_suite=pr-review \
  -f environment=staging
```

## Test Configuration

### Environment Variables

| Variable | Required | Description | Default |
|----------|----------|-------------|---------|
| `GITHUB_TOKEN` | Yes | GitHub API token | - |
| `TEST_REPO` | No | Test repository | Current repo |
| `RUNNER_ORG` | No | Organization for runner tests | - |
| `TEST_ENV` | No | Test environment | staging |
| `REPORT_DIR` | No | Report output directory | ./test-results/e2e |

### Timeouts

| Operation | Timeout | Configurable Via |
|-----------|---------|------------------|
| Workflow Start | 60s | `WORKFLOW_START_TIMEOUT` |
| Workflow Completion | 600s | `WORKFLOW_COMPLETION_TIMEOUT` |
| Step Execution | 120s | `STEP_TIMEOUT` |
| PR Review | 300s | `PR_REVIEW_TIMEOUT` |

## Test Structure

```
scripts/tests/e2e/
├── lib/
│   └── test-helpers.sh           # Shared test utilities
├── test-pr-review-journey.sh     # PR review E2E test
├── test-issue-analysis-journey.sh # Issue analysis E2E test
├── test-autofix-journey.sh       # Auto-fix E2E test
├── test-runner-lifecycle.sh      # Runner lifecycle E2E test
├── test-failure-recovery.sh      # Failure recovery tests
├── run-all-e2e-tests.sh          # Master test runner
└── README.md                      # This file
```

## Helper Functions

### Test Lifecycle
- `init_test_environment(name)` - Initialize test
- `cleanup_test_environment()` - Cleanup resources
- `register_cleanup(type, value)` - Register cleanup item

### Assertions
- `assert_env_var(var)` - Check environment variable
- `assert_file_exists(file)` - Verify file exists
- `assert_command_success(desc, cmd)` - Verify command succeeds
- `assert_equals(actual, expected, msg)` - Compare values
- `assert_contains(haystack, needle, msg)` - Check substring
- `assert_pr_exists(number)` - Verify PR exists
- `assert_issue_exists(number)` - Verify issue exists
- `assert_json_path_exists(json, path)` - Check JSON path

### GitHub Operations
- `create_test_pr(branch, base, title, body)` - Create PR
- `create_test_issue(title, body)` - Create issue
- `get_pr_review(pr_number)` - Get PR review
- `get_latest_comment(issue_number)` - Get issue comment
- `is_branch_protected(branch)` - Check protection

### Workflow Operations
- `wait_for_workflow_start(name, timeout)` - Wait for workflow
- `wait_for_workflow_completion(run_id, timeout)` - Wait for completion
- `wait_for_step(run_id, step_name, timeout)` - Wait for step
- `get_workflow_logs(run_id)` - Get workflow logs
- `assert_workflow_status(run_id, status)` - Check status

### Performance Tracking
- `start_timer()` - Start timing
- `end_timer(start)` - End timing, return duration
- `log_performance(name, value, unit)` - Log metric

## Test Reports

### Text Report
```
E2E Test Report
Generated: 2025-10-23 14:30:00
Repository: owner/repo
============================================================================

SUMMARY
=======
Total Suites: 5
Passed: 4
Failed: 1
Pass Rate: 80%
Total Time: 345s

DETAILED RESULTS
================
Suite: PR Review Journey
Status: PASS
Duration: 58s
...
```

### JSON Report
```json
{
  "timestamp": "2025-10-23T14:30:00Z",
  "repository": "owner/repo",
  "summary": {
    "total": 5,
    "passed": 4,
    "failed": 1,
    "passRate": 80,
    "totalTime": 345
  },
  "suites": [
    {
      "name": "PR Review Journey",
      "status": "PASS",
      "duration": 58,
      "details": ""
    }
  ]
}
```

## CI/CD Integration

### Workflow Triggers
- **Manual:** `workflow_dispatch` with options
- **Scheduled:** Weekly on Sundays at 2 AM UTC
- **Release:** On new releases

### Workflow Inputs
- `test_repo` - Target repository
- `test_suite` - Specific suite or "all"
- `environment` - staging or production

### Success Criteria
- Pass rate ≥ 60%
- All critical journeys pass
- Performance within targets
- No security issues

### Failure Actions
- Upload test artifacts
- Create GitHub issue (scheduled runs)
- Post to Slack (optional)
- Block deployment (optional)

## Performance Benchmarks

Based on TASKS-REMAINING.md targets:

| Test Suite | Target | Acceptable | Blocker |
|------------|--------|------------|---------|
| PR Review | <60s | <90s | >120s |
| Issue Analysis | <30s | <45s | >60s |
| Auto-Fix | <90s | <120s | >180s |
| Runner Lifecycle | <120s | <180s | >300s |
| Failure Recovery | <60s | <90s | >120s |

## Troubleshooting

### Test Fails: "Workflow not triggered"
- Verify workflows are enabled in repository
- Check GitHub Actions permissions
- Ensure `GITHUB_TOKEN` has required scopes

### Test Fails: "PR creation failed"
- Check write permissions to repository
- Verify branch protection settings
- Ensure no name conflicts

### Test Fails: "Timeout waiting for workflow"
- Increase timeout values
- Check runner availability
- Verify workflow YAML syntax

### Test Fails: "API rate limit"
- Use authenticated requests
- Implement rate limit backoff
- Run tests during off-peak hours

## Best Practices

1. **Run tests in isolated environment** - Use test repository
2. **Clean up after tests** - Register cleanup handlers
3. **Use realistic data** - Simulate real user behavior
4. **Monitor performance** - Track timing metrics
5. **Document failures** - Include detailed error messages
6. **Version test data** - Keep test fixtures up to date

## Contributing

When adding new E2E tests:

1. Follow existing naming convention: `test-*-journey.sh`
2. Use helper functions from `lib/test-helpers.sh`
3. Include cleanup handlers
4. Document in this README
5. Add to `run-all-e2e-tests.sh`
6. Update CI/CD workflow if needed

## Resources

- [Testing Guide](../../../docs/testing-guide.md)
- [Architecture](../../../docs/architecture.md)
- [TASKS-REMAINING.md](../../../TASKS-REMAINING.md)
- [GitHub Actions Docs](https://docs.github.com/en/actions)

## License

Same as parent project.
