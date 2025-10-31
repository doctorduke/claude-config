# Local Testing Guide

Complete guide for testing GitHub Actions workflows and AI scripts locally before deployment.

**Version:** 1.0.0
**Last Updated:** 2025-10-17

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Testing Tools](#testing-tools)
- [Quick Start](#quick-start)
- [Testing Workflows Locally](#testing-workflows-locally)
- [Validating AI Scripts](#validating-ai-scripts)
- [Linting Workflows](#linting-workflows)
- [Creating Test Fixtures](#creating-test-fixtures)
- [Mocking External Services](#mocking-external-services)
- [CI Integration](#ci-integration)
- [Common Testing Patterns](#common-testing-patterns)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

---

## Overview

Local testing is essential for rapid iteration and debugging of GitHub Actions workflows and AI agent scripts. This guide covers three main testing tools:

1. **test-workflow-locally.sh** - Simulates GitHub Actions environment
2. **validate-ai-scripts.sh** - Tests AI scripts with mock data
3. **lint-workflows.sh** - Validates workflow YAML and best practices

### Benefits of Local Testing

- **Fast Feedback:** Test changes in seconds, not minutes
- **Cost Savings:** Reduce GitHub Actions minutes usage
- **Better Debugging:** Access to full local environment
- **Offline Development:** Work without internet connectivity
- **Confidence:** Deploy with confidence after thorough testing

---

## Prerequisites

### Required Tools

```bash
# Bash shell (Git Bash on Windows)
bash --version  # 4.0 or higher

# Git
git --version   # 2.0 or higher

# jq (JSON processor)
jq --version    # 1.6 or higher
```

### Recommended Tools

```bash
# yq (YAML processor)
yq --version    # 4.0 or higher
# Install: brew install yq (macOS) or snap install yq (Linux)

# yamllint (YAML linter)
yamllint --version
# Install: pip install yamllint

# actionlint (GitHub Actions linter)
actionlint --version
# Install: brew install actionlint
# Or: https://github.com/rhysd/actionlint/releases

# act (Local GitHub Actions runner)
act --version
# Install: brew install act
# Or: https://github.com/nektos/act

# ajv (JSON schema validator)
ajv --version
# Install: npm install -g ajv-cli
```

### Installation Scripts

**macOS:**
```bash
# Install all recommended tools
brew install yq yamllint actionlint act jq
npm install -g ajv-cli
```

**Linux (Ubuntu/Debian):**
```bash
# Install tools
sudo apt-get update
sudo apt-get install -y jq
sudo snap install yq
pip3 install yamllint
npm install -g ajv-cli

# Install act
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Install actionlint
curl -fsSL https://raw.githubusercontent.com/rhysd/actionlint/main/scripts/download-actionlint.bash | bash
sudo mv actionlint /usr/local/bin/
```

**Windows (Git Bash):**
```bash
# Install tools via Chocolatey
choco install jq yq

# Install Python tools
pip install yamllint

# Install Node.js tools
npm install -g ajv-cli

# For act and actionlint, download binaries from GitHub releases
```

---

## Testing Tools

### 1. test-workflow-locally.sh

Simulates GitHub Actions environment for local workflow testing.

**Features:**
- Creates mock GitHub Actions environment variables
- Simulates sparse checkout
- Mocks `gh` CLI commands
- Generates detailed execution logs
- Supports multiple event types

**Location:** `scripts/test-workflow-locally.sh`

### 2. validate-ai-scripts.sh

Tests AI agent scripts with mock data and validates outputs.

**Features:**
- Tests scripts with sample inputs
- Mocks AI API responses
- Validates JSON output format
- Tests error handling scenarios
- Performance benchmarking

**Location:** `scripts/validate-ai-scripts.sh`

### 3. lint-workflows.sh

Validates workflow YAML syntax and best practices.

**Features:**
- YAML syntax validation
- Security checks (permissions, secrets)
- Best practices verification
- Third-party action validation
- Comprehensive reporting

**Location:** `scripts/lint-workflows.sh`

---

## Quick Start

### Test a Workflow

```bash
# 1. Create secrets file
cp .env.example .env.local
# Edit .env.local with your test credentials

# 2. Test a workflow
./scripts/test-workflow-locally.sh .github/workflows/pr-review.yml

# 3. Check logs
cat .github/test-logs/test-*.log
```

### Validate AI Scripts

```bash
# 1. Test all AI scripts
./scripts/validate-ai-scripts.sh --all

# 2. Test specific script with benchmarking
./scripts/validate-ai-scripts.sh -b -s scripts/ai-review.sh

# 3. View results
cat .github/test-results/test-report-*.md
```

### Lint Workflows

```bash
# 1. Lint all workflows
./scripts/lint-workflows.sh --all

# 2. Strict mode with report
./scripts/lint-workflows.sh --strict --report --all

# 3. View report
cat .github/lint-reports/lint-report-*.md
```

---

## Testing Workflows Locally

### Basic Workflow Testing

**Test with default pull_request event:**
```bash
./scripts/test-workflow-locally.sh .github/workflows/pr-review.yml
```

**Test with different event types:**
```bash
# Push event
./scripts/test-workflow-locally.sh -e push .github/workflows/pr-review.yml

# Issue comment event
./scripts/test-workflow-locally.sh -e issue_comment .github/workflows/issue-comment.yml

# Workflow dispatch
./scripts/test-workflow-locally.sh -e workflow_dispatch .github/workflows/auto-fix.yml
```

### Custom Event Payloads

**Create custom payload:**
```json
# custom-event.json
{
  "action": "opened",
  "number": 456,
  "pull_request": {
    "number": 456,
    "title": "My Custom PR",
    "body": "Testing with custom data",
    "head": {
      "ref": "my-feature",
      "sha": "custom123"
    },
    "base": {
      "ref": "main"
    }
  }
}
```

**Test with custom payload:**
```bash
./scripts/test-workflow-locally.sh \
  -p custom-event.json \
  .github/workflows/pr-review.yml
```

### Using Real gh CLI

By default, `gh` CLI is mocked. To use the real `gh` CLI:

```bash
# Ensure you're authenticated
gh auth login

# Test without mocking
./scripts/test-workflow-locally.sh \
  --no-mock-gh \
  .github/workflows/pr-review.yml
```

### Verbose Mode and Dry Run

**Enable verbose logging:**
```bash
./scripts/test-workflow-locally.sh -v .github/workflows/pr-review.yml
```

**Dry run (show what would execute):**
```bash
./scripts/test-workflow-locally.sh -d .github/workflows/pr-review.yml
```

### Environment Setup

The test script creates a mock GitHub Actions environment:

**Environment Variables Set:**
- `GITHUB_ACTIONS=true`
- `GITHUB_WORKFLOW`, `GITHUB_RUN_ID`, `GITHUB_RUN_NUMBER`
- `GITHUB_JOB`, `GITHUB_ACTION`, `GITHUB_ACTOR`
- `GITHUB_REPOSITORY`, `GITHUB_EVENT_NAME`
- `GITHUB_SHA`, `GITHUB_REF`
- `GITHUB_WORKSPACE`, `RUNNER_OS`, `RUNNER_TEMP`
- `GITHUB_ENV`, `GITHUB_OUTPUT`, `GITHUB_PATH`

**Files Created:**
- `.github/test-env/` - Mock environment directory
- `.github/test-env/github_env` - Environment variables file
- `.github/test-env/github_output` - Step outputs file
- `.github/test-env/event.json` - Event payload
- `.github/test-logs/` - Execution logs

### Secrets Management

**Create `.env.local` file:**
```bash
# .env.local
GITHUB_TOKEN=ghp_your_test_token
AI_API_KEY=sk-your-test-api-key
AI_MODEL=claude-3-opus
MAX_FILES=20
```

**Load secrets during testing:**
```bash
./scripts/test-workflow-locally.sh \
  -s .env.local \
  .github/workflows/pr-review.yml
```

---

## Validating AI Scripts

### Test All Scripts

```bash
# Test all scripts in scripts/ directory
./scripts/validate-ai-scripts.sh --all
```

### Test Specific Script

```bash
# Test ai-review.sh
./scripts/validate-ai-scripts.sh -s scripts/ai-review.sh

# With verbose logging
./scripts/validate-ai-scripts.sh -v -s scripts/ai-review.sh
```

### Performance Benchmarking

```bash
# Run with benchmarks
./scripts/validate-ai-scripts.sh -b -s scripts/ai-review.sh

# Output example:
# Average execution time: 45ms (over 5 runs)
# Excellent performance (<100ms)
```

### Schema Validation

Scripts are validated against JSON schemas:

**Review Output Schema:**
```json
{
  "review": {
    "body": "string (markdown)",
    "event": "APPROVE|REQUEST_CHANGES|COMMENT",
    "comments": [
      {
        "path": "file.js",
        "line": 10,
        "body": "comment text"
      }
    ]
  },
  "metadata": {
    "model": "claude-3-opus",
    "timestamp": "2025-10-17T12:00:00Z",
    "pr_number": 123
  }
}
```

**Enable/disable schema validation:**
```bash
# With schema validation (default)
./scripts/validate-ai-scripts.sh -s scripts/ai-review.sh

# Skip schema validation
./scripts/validate-ai-scripts.sh --no-schema -s scripts/ai-review.sh
```

### Error Handling Tests

Tests verify proper error handling:

```bash
# Run error handling tests (default)
./scripts/validate-ai-scripts.sh -s scripts/ai-review.sh

# Skip error tests
./scripts/validate-ai-scripts.sh --no-error-tests -s scripts/ai-review.sh
```

**Error scenarios tested:**
- Missing required arguments
- Invalid input data
- Network timeouts (simulated)
- API errors (simulated)
- Invalid JSON output

### Using Real API

```bash
# Test with real AI API (requires valid API key)
./scripts/validate-ai-scripts.sh \
  --no-mock-api \
  -s scripts/ai-review.sh
```

**Note:** Real API testing will consume API credits.

### Test Reports

Reports are generated in `.github/test-results/`:

```bash
# View latest report
cat .github/test-results/test-report-*.md

# Example output:
# Total Tests: 15
# Passed: 14
# Failed: 1
# Success Rate: 93%
```

---

## Linting Workflows

### Lint All Workflows

```bash
# Lint all workflows in .github/workflows/
./scripts/lint-workflows.sh --all
```

### Lint Specific Workflow

```bash
# Lint pr-review.yml
./scripts/lint-workflows.sh .github/workflows/pr-review.yml

# With verbose logging
./scripts/lint-workflows.sh -v .github/workflows/pr-review.yml
```

### Strict Mode

In strict mode, warnings become errors:

```bash
./scripts/lint-workflows.sh --strict --all
```

### Security Checks

**Enabled by default:**
- Explicit permissions verification
- Hardcoded secrets detection
- `pull_request_target` safety checks
- Third-party action pinning validation

**Skip security checks:**
```bash
./scripts/lint-workflows.sh --no-security .github/workflows/pr-review.yml
```

### Best Practices Checks

**Checks performed:**
- Sparse checkout configuration
- Job timeout settings
- Descriptive workflow names
- Error handling patterns
- Cache usage recommendations

**Skip best practices checks:**
```bash
./scripts/lint-workflows.sh --no-best-practices .github/workflows/pr-review.yml
```

### Generate Reports

```bash
# Generate detailed report
./scripts/lint-workflows.sh --report --all

# View report
cat .github/lint-reports/lint-report-*.md
```

### Lint Report Example

```markdown
# Workflow Lint Report

## Summary
- Total Checks: 45
- Errors: 0
- Warnings: 3
- Info: 2

## Files Checked
- pr-review.yml
- issue-comment.yml
- auto-fix.yml

## Recommendations
- All checks passed successfully
- Address 3 warnings to improve quality
```

---

## Creating Test Fixtures

### Mock PR Data

**Create `.github/test-data/sample-pr.json`:**
```json
{
  "number": 123,
  "title": "Test PR: Add feature X",
  "body": "Description of changes",
  "state": "open",
  "files": [
    {
      "path": "src/main.js",
      "additions": 50,
      "deletions": 10
    }
  ],
  "additions": 50,
  "deletions": 10,
  "changed_files": 1
}
```

### Mock Issue Data

**Create `.github/test-data/sample-issue.json`:**
```json
{
  "number": 456,
  "title": "Bug: Application crashes",
  "body": "Steps to reproduce...",
  "state": "open",
  "labels": ["bug", "priority:high"]
}
```

### Mock Diff Files

**Create `.github/test-data/sample-diff.txt`:**
```diff
diff --git a/src/main.js b/src/main.js
index abc123..def456 100644
--- a/src/main.js
+++ b/src/main.js
@@ -1,5 +1,10 @@
 export function main() {
-  console.log('Hello');
+  // Enhanced version
+  console.log('Hello, World!');
 }
```

### Mock API Responses

**Create `.github/mock-api/mock-response.json`:**
```json
{
  "id": "mock-123",
  "model": "claude-3-opus",
  "content": [
    {
      "type": "text",
      "text": "## Code Review\n\nLooks good!"
    }
  ]
}
```

---

## Mocking External Services

### Mock GitHub CLI

The test script includes built-in `gh` CLI mocking:

```bash
# Mock gh is enabled by default
./scripts/test-workflow-locally.sh .github/workflows/pr-review.yml

# Use real gh CLI
./scripts/test-workflow-locally.sh --no-mock-gh .github/workflows/pr-review.yml
```

**Mock gh CLI supports:**
- `gh pr view` - Returns sample PR data
- `gh pr review` - Simulates posting review
- `gh pr comment` - Simulates posting comment
- `gh issue comment` - Simulates issue comment
- `gh api` - Returns generic success response

### Mock AI API

**Create mock API script:**
```bash
# .github/mock-api/mock-ai-api.sh
#!/usr/bin/env bash
cat << 'EOF'
{
  "response": "This is a mock AI response for testing",
  "model": "test-model",
  "tokens": 100
}
EOF
```

**Use in tests:**
```bash
export AI_API_ENDPOINT=".github/mock-api/mock-ai-api.sh"
./scripts/validate-ai-scripts.sh -s scripts/ai-review.sh
```

### Mock HTTP Endpoints

**Using netcat for simple mocking:**
```bash
# Start mock HTTP server
while true; do
  echo -e "HTTP/1.1 200 OK\n\n{\"status\":\"ok\"}" | nc -l 8080
done
```

**Using Python's http.server:**
```bash
# Create mock responses
mkdir -p mock-server
echo '{"status":"ok"}' > mock-server/api/health

# Start server
cd mock-server && python3 -m http.server 8080
```

---

## CI Integration

### GitHub Actions Integration

Add local testing to CI pipeline:

```yaml
# .github/workflows/test.yml
name: Local Tests

on: [pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install dependencies
        run: |
          sudo apt-get install -y jq
          sudo snap install yq
          pip install yamllint
          npm install -g ajv-cli

      - name: Lint workflows
        run: |
          chmod +x scripts/lint-workflows.sh
          ./scripts/lint-workflows.sh --strict --all

      - name: Validate AI scripts
        run: |
          chmod +x scripts/validate-ai-scripts.sh
          ./scripts/validate-ai-scripts.sh --all

      - name: Upload reports
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-reports
          path: |
            .github/lint-reports/
            .github/test-results/
```

### Pre-commit Hooks

**Setup pre-commit hook:**
```bash
# .git/hooks/pre-commit
#!/bin/bash

echo "Running workflow linter..."
./scripts/lint-workflows.sh --all --strict

if [ $? -ne 0 ]; then
    echo "Linting failed. Commit aborted."
    exit 1
fi

echo "Linting passed!"
```

**Make executable:**
```bash
chmod +x .git/hooks/pre-commit
```

### Using act for Full Workflow Tests

**Install act:**
```bash
# macOS
brew install act

# Linux
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
```

**Run workflows with act:**
```bash
# List available workflows
act -l

# Run pull_request event
act pull_request -W .github/workflows/pr-review.yml

# Run with secrets
act pull_request -s GITHUB_TOKEN=ghp_xxx -s AI_API_KEY=sk-xxx

# Use custom event payload
act pull_request -e event.json -W .github/workflows/pr-review.yml

# Run specific job
act -j review

# Verbose mode
act pull_request --verbose
```

**Create `.actrc` for configuration:**
```bash
# .actrc
--platform ubuntu-latest=catthehacker/ubuntu:act-latest
--secret-file .env.local
--artifact-server-path /tmp/artifacts
--verbose
```

---

## Common Testing Patterns

### Pattern 1: Test-Driven Workflow Development

```bash
# 1. Write workflow
vim .github/workflows/new-workflow.yml

# 2. Lint immediately
./scripts/lint-workflows.sh .github/workflows/new-workflow.yml

# 3. Fix issues
vim .github/workflows/new-workflow.yml

# 4. Test locally
./scripts/test-workflow-locally.sh .github/workflows/new-workflow.yml

# 5. Test with act
act pull_request -W .github/workflows/new-workflow.yml

# 6. Deploy
git add .github/workflows/new-workflow.yml
git commit -m "Add new workflow"
```

### Pattern 2: Script Validation Pipeline

```bash
# 1. Develop script
vim scripts/new-script.sh

# 2. Make executable
chmod +x scripts/new-script.sh

# 3. Test syntax
bash -n scripts/new-script.sh

# 4. Validate with mock data
./scripts/validate-ai-scripts.sh -s scripts/new-script.sh

# 5. Benchmark performance
./scripts/validate-ai-scripts.sh -b -s scripts/new-script.sh

# 6. Test in workflow context
./scripts/test-workflow-locally.sh .github/workflows/pr-review.yml
```

### Pattern 3: Comprehensive Pre-Deployment Check

```bash
#!/bin/bash
# pre-deploy.sh - Run all tests before deployment

set -e

echo "Running comprehensive tests..."

# 1. Lint all workflows
echo "1. Linting workflows..."
./scripts/lint-workflows.sh --strict --all

# 2. Validate all scripts
echo "2. Validating scripts..."
./scripts/validate-ai-scripts.sh --all

# 3. Test key workflows
echo "3. Testing workflows..."
./scripts/test-workflow-locally.sh -d .github/workflows/pr-review.yml
./scripts/test-workflow-locally.sh -d .github/workflows/issue-comment.yml

# 4. Run act tests
echo "4. Running act tests..."
act pull_request -W .github/workflows/pr-review.yml --dryrun

echo "All tests passed! Ready to deploy."
```

### Pattern 4: Debugging Failed Workflow

```bash
# 1. Get workflow logs from GitHub
gh run view <run-id> --log > failed-run.log

# 2. Identify failing step
grep "ERROR" failed-run.log

# 3. Test locally with verbose mode
./scripts/test-workflow-locally.sh -v .github/workflows/pr-review.yml

# 4. Test specific script
./scripts/validate-ai-scripts.sh -v -s scripts/ai-review.sh

# 5. Fix and retest
vim scripts/ai-review.sh
./scripts/validate-ai-scripts.sh -s scripts/ai-review.sh
```

---

## Troubleshooting

### Common Issues

#### Issue: "yq not found"

**Solution:**
```bash
# macOS
brew install yq

# Linux
snap install yq

# Windows (Chocolatey)
choco install yq
```

#### Issue: "Mock gh CLI not working"

**Solution:**
```bash
# Check PATH
echo $PATH

# Verify mock gh is created
ls -la .github/test-env/bin/gh

# Make sure it's executable
chmod +x .github/test-env/bin/gh

# Run with verbose mode
./scripts/test-workflow-locally.sh -v .github/workflows/pr-review.yml
```

#### Issue: "Scripts not executable"

**Solution:**
```bash
# Make all scripts executable
chmod +x scripts/*.sh

# Or individually
chmod +x scripts/test-workflow-locally.sh
chmod +x scripts/validate-ai-scripts.sh
chmod +x scripts/lint-workflows.sh
```

#### Issue: "JSON validation failed"

**Solution:**
```bash
# Validate JSON manually
jq empty output.json

# Check schema
ajv validate -s schema.json -d output.json

# View detailed error
./scripts/validate-ai-scripts.sh -v -s scripts/ai-review.sh
```

#### Issue: "act failing with permission denied"

**Solution:**
```bash
# Run Docker with proper permissions
sudo usermod -aG docker $USER

# Or use Docker Desktop

# Check Docker is running
docker ps
```

### Debug Mode

**Enable debug mode in scripts:**
```bash
# Set bash debug mode
bash -x ./scripts/test-workflow-locally.sh .github/workflows/pr-review.yml

# Or add to script
set -x  # Enable debug output
```

### Log Analysis

**View detailed logs:**
```bash
# Test logs
cat .github/test-logs/test-*.log

# Lint reports
cat .github/lint-reports/lint-report-*.md

# Validation results
cat .github/test-results/test-report-*.md
```

**Search logs for errors:**
```bash
# Find errors
grep -i "error" .github/test-logs/test-*.log

# Find warnings
grep -i "warn" .github/test-logs/test-*.log
```

---

## Best Practices

### 1. Test Early and Often

- Lint workflows before committing
- Validate scripts during development
- Run full tests before pull requests

### 2. Use Realistic Test Data

- Create fixtures based on real scenarios
- Include edge cases in test data
- Test with various input sizes

### 3. Mock External Dependencies

- Use mock APIs to avoid rate limits
- Simulate network failures
- Test timeout scenarios

### 4. Automate Testing

- Add pre-commit hooks
- Integrate with CI pipeline
- Run tests automatically on PR

### 5. Document Test Cases

- Document expected behavior
- Include test examples in code
- Maintain test data inventory

### 6. Version Control Test Assets

```bash
# Track test data
git add .github/test-data/
git add .github/mock-api/

# Track test scripts
git add scripts/*test*.sh
git add scripts/*validate*.sh
git add scripts/*lint*.sh
```

### 7. Regular Test Maintenance

- Update test data regularly
- Review and update mocks
- Clean up old test artifacts

```bash
# Clean up old logs
find .github/test-logs -type f -mtime +7 -delete

# Clean up old reports
find .github/lint-reports -type f -mtime +30 -delete
```

### 8. Use Secrets Management

```bash
# Never commit secrets
echo ".env.local" >> .gitignore
echo ".env.test" >> .gitignore

# Use example files
cp .env.example .env.local
# Then edit .env.local with actual values
```

### 9. Parallel Testing

```bash
# Test multiple workflows in parallel
./scripts/lint-workflows.sh .github/workflows/pr-review.yml &
./scripts/lint-workflows.sh .github/workflows/issue-comment.yml &
wait

echo "All linting complete"
```

### 10. Continuous Improvement

- Track test metrics
- Monitor test execution time
- Optimize slow tests
- Add new tests for bugs found

---

## Quick Reference

### Test Workflow

```bash
./scripts/test-workflow-locally.sh [OPTIONS] WORKFLOW_FILE
```

**Options:**
- `-e, --event TYPE` - Event type (pull_request, push, etc.)
- `-p, --payload FILE` - Custom event payload
- `-s, --secrets FILE` - Secrets file (default: .env.local)
- `-m, --no-mock-gh` - Don't mock gh CLI
- `-v, --verbose` - Verbose output
- `-d, --dry-run` - Dry run mode

### Validate Scripts

```bash
./scripts/validate-ai-scripts.sh [OPTIONS] [SCRIPT_FILE]
```

**Options:**
- `-a, --all` - Test all scripts
- `-s, --script FILE` - Specific script
- `-v, --verbose` - Verbose output
- `-b, --benchmark` - Run benchmarks
- `--no-mock-api` - Use real API
- `--no-schema` - Skip schema validation

### Lint Workflows

```bash
./scripts/lint-workflows.sh [OPTIONS] [WORKFLOW_FILE]
```

**Options:**
- `-a, --all` - Lint all workflows
- `-w, --workflow FILE` - Specific workflow
- `-v, --verbose` - Verbose output
- `-s, --strict` - Strict mode
- `--no-security` - Skip security checks
- `-r, --report` - Generate report

---

## Additional Resources

### Documentation
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Workflow Syntax](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions)
- [Security Hardening](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)

### Tools
- [act](https://github.com/nektos/act) - Run GitHub Actions locally
- [actionlint](https://github.com/rhysd/actionlint) - Lint workflows
- [yamllint](https://yamllint.readthedocs.io/) - YAML linter
- [yq](https://mikefarah.gitbook.io/yq/) - YAML processor
- [jq](https://stedolan.github.io/jq/) - JSON processor

### Community
- [GitHub Actions Forum](https://github.community/c/github-actions)
- [act Issues](https://github.com/nektos/act/issues)

---

## Feedback and Contributions

Have suggestions for improving the testing tools? Please:

1. Open an issue describing the enhancement
2. Submit a pull request with improvements
3. Update documentation for new features

---

**Last Updated:** 2025-10-17
**Version:** 1.0.0
