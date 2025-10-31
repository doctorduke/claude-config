# Test Template for Scripts and Workflows

## Required Tests

All agents that write code, configuration, or scripts MUST include tests.

## Test Types

### 1. Unit Tests
Test individual functions/components in isolation.

```bash
#!/usr/bin/env bash
# test-unit-example.sh

test_function_name() {
  local expected="expected output"
  local actual=$(function_under_test "input")
  
  if [ "$actual" = "$expected" ]; then
    echo "✓ test_function_name PASS"
    return 0
  else
    echo "✗ test_function_name FAIL: expected '$expected', got '$actual'"
    return 1
  fi
}

# Run tests
test_function_name
```

### 2. Integration Tests
Test components working together.

```bash
# test-integration-example.sh

test_workflow_with_script() {
  # Setup
  local test_pr=123
  
  # Execute
  ./scripts/ai-review.sh --pr $test_pr --dry-run > output.json
  
  # Verify
  if jq empty output.json 2>/dev/null; then
    echo "✓ Valid JSON output"
  else
    echo "✗ Invalid JSON output"
    return 1
  fi
  
  # Cleanup
  rm output.json
}
```

### 3. Contract Tests
Verify interfaces/schemas match expectations.

```bash
# test-contract-example.sh

test_json_schema() {
  local output=$(./scripts/ai-agent.sh --test-mode)
  
  # Check required fields exist
  echo "$output" | jq -e '.response.body' >/dev/null || return 1
  echo "$output" | jq -e '.response.type' >/dev/null || return 1
  echo "$output" | jq -e '.metadata' >/dev/null || return 1
  
  echo "✓ JSON schema valid"
}
```

### 4. End-to-End Tests
Test complete workflow from trigger to result.

```bash
# test-e2e-example.sh

test_pr_review_workflow() {
  # Trigger workflow
  gh workflow run ai-pr-review.yml -f pr_number=123
  
  # Wait for completion (up to 5 minutes)
  local run_id=$(gh run list --workflow=ai-pr-review.yml --limit 1 --json databaseId -q '.[0].databaseId')
  local status=""
  local attempts=0
  
  while [ $attempts -lt 30 ]; do
    status=$(gh run view $run_id --json status -q '.status')
    [ "$status" = "completed" ] && break
    sleep 10
    ((attempts++))
  done
  
  # Verify success
  local conclusion=$(gh run view $run_id --json conclusion -q '.conclusion')
  if [ "$conclusion" = "success" ]; then
    echo "✓ E2E workflow successful"
  else
    echo "✗ E2E workflow failed: $conclusion"
    return 1
  fi
}
```

## Test Requirements by Agent Type

### Developers
MUST provide:
- Unit tests for all functions
- Integration tests for component interactions
- Example: `scripts/tests/test-ai-review.sh`

### Configuration Contributors  
MUST provide:
- Schema validation tests
- Integration tests with consuming systems
- Example: `config/tests/test-runner-groups.sh`

### Workflow Contributors
MUST provide:
- Syntax validation (yamllint)
- Permission validation
- Dry-run tests
- Example: `.github/tests/test-workflows.sh`

### Script Contributors
MUST provide:
- All of the above plus:
- Cross-platform tests (if applicable)
- Error handling tests
- Example: `scripts/tests/test-setup-runner.sh`

## Test Harness Template

```bash
#!/usr/bin/env bash
# test-harness-template.sh

set -euo pipefail

# Configuration
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$TEST_DIR/../.." && pwd)"
PASS=0
FAIL=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Test runner
run_test() {
  local test_name=$1
  local test_func=$2
  
  if $test_func; then
    echo -e "${GREEN}✓${NC} $test_name"
    ((PASS++))
  else
    echo -e "${RED}✗${NC} $test_name"
    ((FAIL++))
  fi
}

# Individual test functions
test_example_1() {
  # Test implementation
  return 0  # or 1 for failure
}

test_example_2() {
  # Test implementation
  return 0
}

# Main execution
main() {
  echo "Running tests for [Component Name]"
  echo "=================================="
  
  run_test "Test 1 description" test_example_1
  run_test "Test 2 description" test_example_2
  
  echo "=================================="
  echo "Results: $PASS passed, $FAIL failed"
  
  [ $FAIL -eq 0 ] && exit 0 || exit 1
}

main "$@"
```

## Commit Message Test Section

Include test results in every commit:

```
feat(component): Add new feature

Implementation details here.

Tests:
✓ test_unit_function1 PASS
✓ test_unit_function2 PASS
✓ test_integration_workflow PASS
✓ test_e2e_complete_flow PASS

All 4 tests passed.

Status: READY_FOR_REVIEW
```

## Test Failure Handling

If tests fail:

```
fix(component): Address test failures

Fixed issues:
- Issue 1: [description and fix]
- Issue 2: [description and fix]

Tests:
✓ test_unit_function1 PASS (was failing)
✓ test_unit_function2 PASS
✗ test_integration_workflow FAIL - known issue, will fix in next commit

Status: IN_PROGRESS (1 test still failing)
```

## Pre-Commit Hook (Optional)

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Run tests before allowing commit
if [ -f "./scripts/tests/run-all-tests.sh" ]; then
  ./scripts/tests/run-all-tests.sh
  if [ $? -ne 0 ]; then
    echo "Tests failed. Commit aborted."
    exit 1
  fi
fi
```

## Best Practices

1. **Test First**: Write tests before or during implementation (TDD)
2. **Fast Tests**: Keep test execution under 30 seconds when possible
3. **Isolated Tests**: Each test should be independent
4. **Clear Names**: Test names should describe what they verify
5. **Document Failures**: Explain why a test might fail
6. **Mock External Dependencies**: Don't rely on external services
7. **Include in CI**: Tests should run automatically

## Test Organization

```
project-root/
├── scripts/
│   ├── tests/
│   │   ├── test-ai-review.sh
│   │   ├── test-ai-agent.sh
│   │   └── run-all-tests.sh
│   ├── ai-review.sh
│   └── ai-agent.sh
├── .github/
│   ├── workflows/
│   └── tests/
│       ├── test-workflows.sh
│       └── test-permissions.sh
└── config/
    ├── tests/
    │   └── test-schemas.sh
    └── runner-groups.json
```

