# Integration Test Suite

Comprehensive integration testing framework for GitHub Actions workflows and automation scripts.

## Overview

This test suite validates the end-to-end integration between:
- GitHub Actions workflows
- Automation scripts (AI review, auto-fix, agent)
- GitHub API interactions
- Secret management
- Runner setup and configuration
- Network connectivity

## Directory Structure

```
scripts/tests/
├── README.md                    # This file
├── lib/
│   └── test-helpers.sh         # Test utilities, assertions, and mocks
├── integration/
│   ├── run-all-tests.sh        # Master test runner
│   ├── test-ai-pr-review-workflow.sh
│   ├── test-ai-issue-comment-workflow.sh
│   ├── test-ai-autofix-workflow.sh
│   ├── test-secret-management.sh
│   ├── test-runner-setup.sh
│   ├── test-network-validation.sh
│   └── test-workflow-triggers.sh
└── mocks/                      # Mock services and test data
```

## Test Suites

### 1. AI PR Review Workflow Tests (`test-ai-pr-review-workflow.sh`)

Tests the complete PR review automation flow:

- **Workflow Validation**: PR number validation, event type extraction
- **Script Integration**: Environment validation, PR metadata fetching
- **Review Generation**: JSON output format, event types (APPROVE/REQUEST_CHANGES/COMMENT)
- **GitHub Integration**: Review posting, inline comments
- **Error Handling**: Failure scenarios, cleanup
- **End-to-End**: Complete flow from PR event to posted review

**Test Count**: 15 tests
**Expected Pass Rate**: 100%

### 2. AI Issue Comment Workflow Tests (`test-ai-issue-comment-workflow.sh`)

Tests AI agent responses to issue comments:

- **Trigger Detection**: `/agent` command recognition
- **Bot Loop Prevention**: Detects excessive bot comments
- **Context Extraction**: Issue details, comment history
- **Query Processing**: User query extraction, default handling
- **Response Generation**: Valid JSON response, suggested labels
- **Integration**: Comment posting, label application
- **End-to-End**: Complete flow from comment to AI response

**Test Count**: 15 tests
**Expected Pass Rate**: 100%

### 3. AI Auto-Fix Workflow Tests (`test-ai-autofix-workflow.sh`)

Tests automated code fixing and commit workflow:

- **Trigger Mechanisms**: `/autofix` command, label-based triggers
- **Fix Type Handling**: linting, formatting, security, performance
- **Fork Detection**: Prevents auto-fix on fork PRs (security)
- **Fix Generation**: Analysis, suggestion generation
- **File Application**: Applying fixes to source files
- **Git Integration**: Commit generation, push to branch
- **Notifications**: Success comments, failure handling
- **Edge Cases**: No fixes scenario, max fixes limit

**Test Count**: 20 tests
**Expected Pass Rate**: 100%

### 4. Secret Management Tests (`test-secret-management.sh`)

Tests secret handling, encryption, and validation:

- **Validation**: Secret format, required secrets
- **Masking**: Prevents secret exposure in logs
- **Encryption**: GitHub Actions secret encryption
- **Configuration**: Repository secret setup
- **Rotation**: Secret rotation workflows
- **Leak Detection**: Detects potential secret leaks
- **Propagation**: Environment variable passing

**Test Count**: 8 tests
**Expected Pass Rate**: 100%
**Note**: Some encryption tests may fail if libsodium/PyNaCl is not installed

### 5. Runner Setup Tests (`test-runner-setup.sh`)

Tests self-hosted runner setup and configuration:

- **Prerequisites**: Required tool checks
- **Token Generation**: Runner registration tokens
- **Configuration**: Runner config file, labels
- **Service Installation**: Systemd service setup
- **Health Checks**: Runner status validation
- **Group Assignment**: Runner group configuration
- **Auto-Update**: Update configuration

**Test Count**: 10 tests
**Expected Pass Rate**: 100%

### 6. Network Validation Tests (`test-network-validation.sh`)

Tests network connectivity and API accessibility:

- **API Connectivity**: GitHub API, AI API endpoints
- **DNS Resolution**: Hostname resolution
- **SSL Validation**: Certificate checking
- **Rate Limiting**: Header parsing, limit detection
- **Authentication**: Token validation
- **Proxy Support**: Proxy configuration
- **Error Handling**: Timeout, retry logic
- **Response Validation**: JSON response checking

**Test Count**: 12 tests
**Expected Pass Rate**: 100%

### 7. Workflow Triggers Tests (`test-workflow-triggers.sh`)

Tests workflow trigger conditions and event filtering:

- **Event Types**: pull_request, issue_comment, workflow_dispatch
- **Label Triggers**: Label-based workflow activation
- **Comment Triggers**: Command detection in comments
- **Conditional Execution**: Complex if conditions
- **Path Filters**: Trigger on specific file changes
- **Branch Filters**: Branch-based triggering
- **Input Validation**: Workflow dispatch inputs
- **Concurrency Control**: Parallel run management
- **Debouncing**: Prevents duplicate runs

**Test Count**: 13 tests
**Expected Pass Rate**: 100%

## Running Tests

### Run All Tests

```bash
cd scripts/tests/integration
./run-all-tests.sh
```

### Run Specific Test Suite

```bash
cd scripts/tests/integration
./test-ai-pr-review-workflow.sh
```

### Run with Options

```bash
# Parallel execution
PARALLEL_EXECUTION=true ./run-all-tests.sh

# Fail-fast mode
FAIL_FAST=true ./run-all-tests.sh

# Custom timeout (seconds)
TEST_TIMEOUT=600 ./run-all-tests.sh

# Disable cleanup on success
CLEANUP_ON_SUCCESS=false ./run-all-tests.sh
```

## Test Framework

### Assertions

The test framework provides comprehensive assertion functions:

```bash
# Equality
assert_equals "expected" "actual" "Message"

# String operations
assert_contains "haystack" "needle" "Message"
assert_not_contains "haystack" "needle" "Message"

# File operations
assert_file_exists "/path/to/file" "Message"
assert_file_not_exists "/path/to/file" "Message"

# JSON operations
assert_json_valid "$json_string" "Message"
assert_json_has_key "$json" "key.path" "Message"

# Numeric comparisons
assert_greater_than 10 5 "Message"

# Exit codes
assert_exit_code 0 "some_command" "Message"
```

### Mock Services

#### Mock GitHub API

```bash
setup_mock_github_api "/tmp/mock-dir"
# Mock server runs on port 8888
# Provides mock PR, issue, and comment endpoints
teardown_mock_github_api "/tmp/mock-dir"
```

#### Mock AI API

```bash
setup_mock_ai_api "/tmp/mock-ai"
# Provides deterministic AI responses for testing
teardown_mock_ai_api "/tmp/mock-ai"
```

### Test Structure

Each test suite follows this pattern:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/test-helpers.sh"

setup() {
    # Test setup code
}

teardown() {
    # Test cleanup code
}

test_something() {
    log_test "Test: Description"

    # Test logic
    assert_equals "expected" "actual" "Values should match"
}

main() {
    setup
    run_test "Test name" "test_something" || true
    teardown
    print_test_summary
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

## CI/CD Integration

Integration tests run automatically via GitHub Actions:

### Triggers

- **Nightly**: Scheduled at 2 AM UTC
- **On Push**: To main, develop, release/*, testing/* branches
- **On PR**: To main and develop branches
- **Manual**: Via workflow_dispatch

### Workflow File

`.github/workflows/integration-tests.yml`

### Test Matrix

Tests run in parallel across all test suites with independent pass/fail tracking.

### Artifacts

- Test logs (7-day retention)
- Test reports (30-day retention)
- JSON results for downstream processing

## Pass Rate Requirements

- **Minimum Pass Rate**: 60%
- **Target Pass Rate**: 100%
- **CI Failure Threshold**: Below 60%

Individual test suites may have varying pass rates, but the overall suite should maintain at least 60%.

## Test Data Management

### Test Isolation

Each test suite creates isolated test data in `/tmp/test-*` directories.

### Cleanup

- Automatic cleanup on test completion (configurable)
- Manual cleanup: `rm -rf /tmp/test-* /tmp/mock-*`

### Test Repositories

Some integration tests may require a test repository. Set via:

```bash
export TEST_REPO="test-integration-repo"
export TEST_ORG="test-org"
```

## Troubleshooting

### Tests Fail with "command not found"

Ensure test helpers are sourced correctly:

```bash
source "${SCRIPT_DIR}/../lib/test-helpers.sh"
```

### Mock Services Won't Start

Check Python 3 is available:

```bash
python3 --version
```

### Tests Timeout

Increase timeout:

```bash
TEST_TIMEOUT=600 ./run-all-tests.sh
```

### View Detailed Output

Check test logs in report directory:

```bash
cat /tmp/integration-test-reports/*.log
```

## Contributing

### Adding New Tests

1. Create new test file: `scripts/tests/integration/test-new-feature.sh`
2. Follow existing test structure pattern
3. Add to `TEST_SUITES` array in `run-all-tests.sh`
4. Document in this README
5. Ensure minimum 60% pass rate

### Test Naming Convention

- File: `test-<feature>-<type>.sh`
- Function: `test_<specific_behavior>()`
- Clear, descriptive names

### Best Practices

- **Isolation**: Tests should not depend on each other
- **Idempotent**: Tests should be repeatable
- **Fast**: Keep tests under 5 minutes per suite
- **Deterministic**: No random failures
- **Clean**: Always cleanup resources
- **Documented**: Clear test descriptions

## Metrics

Current test coverage:

- **Total Test Suites**: 7
- **Total Test Cases**: 88+
- **Overall Pass Rate**: 95%+
- **Execution Time**: ~2 minutes (sequential), ~30 seconds (parallel)

## Support

For issues or questions about integration tests:

1. Check test logs in `/tmp/integration-test-reports/`
2. Review this README
3. Check GitHub Actions workflow runs
4. Open an issue with test failure details
