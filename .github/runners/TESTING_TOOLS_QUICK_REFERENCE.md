# Wave 3 Testing Tools - Quick Reference Card

**Quick access guide for local testing tools**

---

## Installation

```bash
# Make scripts executable (one-time setup)
chmod +x scripts/*.sh

# Create secrets file
cp .env.example .env.local
# Edit .env.local with your test credentials
```

---

## Test Workflow Locally

**Basic Usage:**
```bash
./scripts/test-workflow-locally.sh .github/workflows/pr-review.yml
```

**Common Options:**
```bash
# Different event type
./scripts/test-workflow-locally.sh -e push workflow.yml

# Custom payload
./scripts/test-workflow-locally.sh -p event.json workflow.yml

# Verbose output
./scripts/test-workflow-locally.sh -v workflow.yml

# Dry run
./scripts/test-workflow-locally.sh -d workflow.yml

# Use real gh CLI
./scripts/test-workflow-locally.sh --no-mock-gh workflow.yml
```

**Outputs:**
- Logs: `.github/test-logs/test-*.log`
- Mock env: `.github/test-env/`

---

## Validate AI Scripts

**Basic Usage:**
```bash
./scripts/validate-ai-scripts.sh --all
```

**Common Options:**
```bash
# Test specific script
./scripts/validate-ai-scripts.sh -s scripts/ai-review.sh

# With benchmarking
./scripts/validate-ai-scripts.sh -b -s scripts/ai-review.sh

# Verbose mode
./scripts/validate-ai-scripts.sh -v --all

# Use real API
./scripts/validate-ai-scripts.sh --no-mock-api -s scripts/ai-review.sh

# Skip schema validation
./scripts/validate-ai-scripts.sh --no-schema -s scripts/ai-review.sh
```

**Outputs:**
- Reports: `.github/test-results/test-report-*.md`
- Test data: `.github/test-data/`

---

## Lint Workflows

**Basic Usage:**
```bash
./scripts/lint-workflows.sh --all
```

**Common Options:**
```bash
# Lint specific workflow
./scripts/lint-workflows.sh .github/workflows/pr-review.yml

# Strict mode
./scripts/lint-workflows.sh --strict --all

# Generate report
./scripts/lint-workflows.sh --report --all

# Skip security checks
./scripts/lint-workflows.sh --no-security workflow.yml

# Skip best practices
./scripts/lint-workflows.sh --no-best-practices workflow.yml

# Verbose output
./scripts/lint-workflows.sh -v --all
```

**Outputs:**
- Reports: `.github/lint-reports/lint-report-*.md`

---

## Complete Pre-Deployment Check

```bash
#!/bin/bash
# Run all tests before deploying

# 1. Lint all workflows (strict mode)
./scripts/lint-workflows.sh --strict --all

# 2. Validate all scripts
./scripts/validate-ai-scripts.sh --all

# 3. Test key workflows
./scripts/test-workflow-locally.sh -d .github/workflows/pr-review.yml
./scripts/test-workflow-locally.sh -d .github/workflows/issue-comment.yml

echo "All tests passed! Ready to deploy."
```

---

## Recommended Tools

```bash
# Install recommended tools

# macOS
brew install yq yamllint actionlint act jq
npm install -g ajv-cli

# Linux (Ubuntu/Debian)
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

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| yq not found | `brew install yq` or `snap install yq` |
| Script not executable | `chmod +x scripts/*.sh` |
| Secrets not loading | Check `.env.local` exists |
| Mock gh not working | Check PATH: `echo $PATH` |
| JSON validation failed | Test with: `jq empty file.json` |

---

## Quick Test Commands

```bash
# Help for any script
./scripts/test-workflow-locally.sh --help
./scripts/validate-ai-scripts.sh --help
./scripts/lint-workflows.sh --help

# Test everything
./scripts/lint-workflows.sh --all
./scripts/validate-ai-scripts.sh --all

# View logs
cat .github/test-logs/test-*.log
cat .github/test-results/test-report-*.md
cat .github/lint-reports/lint-report-*.md

# Clean up old logs
find .github/test-logs -type f -mtime +7 -delete
find .github/lint-reports -type f -mtime +30 -delete
```

---

## CI Integration

**GitHub Actions:**
```yaml
- name: Lint workflows
  run: ./scripts/lint-workflows.sh --strict --all

- name: Validate scripts
  run: ./scripts/validate-ai-scripts.sh --all
```

**Pre-commit Hook:**
```bash
#!/bin/bash
./scripts/lint-workflows.sh --all --strict
```

---

## File Locations

**Scripts:**
- `scripts/test-workflow-locally.sh` - Workflow tester
- `scripts/validate-ai-scripts.sh` - Script validator
- `scripts/lint-workflows.sh` - Workflow linter

**Documentation:**
- `docs/local-testing-guide.md` - Complete guide
- `WAVE3_TESTING_TOOLS_SUMMARY.md` - Detailed summary
- `TESTING_TOOLS_QUICK_REFERENCE.md` - This file

**Generated:**
- `.github/test-env/` - Mock environment
- `.github/test-logs/` - Test logs
- `.github/test-results/` - Validation reports
- `.github/lint-reports/` - Lint reports
- `.github/test-data/` - Test fixtures
- `.github/mock-api/` - Mock services

---

## Exit Codes

**test-workflow-locally.sh:**
- 0: Success
- 1: Error

**validate-ai-scripts.sh:**
- 0: All tests passed
- 1: Some tests failed

**lint-workflows.sh:**
- 0: All checks passed
- 1: Errors found
- 2: Warnings in strict mode

---

## Getting Help

**Documentation:**
- Full guide: `docs/local-testing-guide.md`
- Summary: `WAVE3_TESTING_TOOLS_SUMMARY.md`

**Script Help:**
```bash
./scripts/test-workflow-locally.sh --help
./scripts/validate-ai-scripts.sh --help
./scripts/lint-workflows.sh --help
```

---

**Last Updated:** 2025-10-17
