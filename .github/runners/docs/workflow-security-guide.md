# GitHub Actions Workflow Security Guide

## Table of Contents
1. [Overview](#overview)
2. [Permission Scoping](#permission-scoping)
3. [Secret Management](#secret-management)
4. [Workflow Security Checklist](#workflow-security-checklist)
5. [Common Vulnerabilities](#common-vulnerabilities)
6. [Security Best Practices](#security-best-practices)
7. [Branch Protection](#branch-protection)
8. [Security Tools](#security-tools)
9. [Incident Response](#incident-response)

---

## Overview

This guide provides comprehensive security best practices for GitHub Actions workflows, focusing on preventing common vulnerabilities and implementing defense-in-depth strategies.

### Key Security Principles

1. **Principle of Least Privilege**: Grant minimal permissions required
2. **Defense in Depth**: Multiple layers of security controls
3. **Zero Trust**: Never trust user input, always validate
4. **Fail Securely**: No information leakage in error states
5. **Audit and Monitor**: Log all security-relevant events

### OWASP Top 10 Relevance

- **A01:2021 - Broken Access Control**: Workflow permissions
- **A02:2021 - Cryptographic Failures**: Secret management
- **A03:2021 - Injection**: Command injection in workflows
- **A05:2021 - Security Misconfiguration**: Default permissions
- **A07:2021 - Identification and Authentication Failures**: Token scoping

---

## Permission Scoping

### GITHUB_TOKEN vs Personal Access Token (PAT)

#### GITHUB_TOKEN (Recommended)

Automatically provided by GitHub Actions with scoped permissions:

```yaml
permissions:
  contents: read        # Read repository contents
  pull-requests: write  # Create/update pull requests
  issues: read         # Read issues
  actions: read        # Read workflow runs
```

**Advantages:**
- Automatically scoped to repository
- Short-lived (expires after job)
- No manual rotation needed
- Auditable through workflow logs

#### Personal Access Token (Use Sparingly)

Required for cross-repository operations:

```yaml
steps:
  - name: Cross-repo operation
    env:
      GITHUB_TOKEN: ${{ secrets.PAT_TOKEN }}  # Store in repository secrets
    run: |
      gh repo clone other-org/other-repo
```

**Security Requirements:**
- Use fine-grained PATs with minimal scopes
- Set expiration dates (max 90 days)
- Rotate regularly
- Never use classic PATs with broad scopes

### Minimal Permission Examples

#### Pull Request Review Workflow

```yaml
name: PR Review
on:
  pull_request:
    types: [opened, synchronize, reopened]

permissions:
  contents: read        # Read code
  pull-requests: write  # Post reviews

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run review
        run: ./scripts/review.sh
```

#### Issue Comment Handler

```yaml
name: Issue Comment
on:
  issue_comment:
    types: [created]

permissions:
  issues: write  # Respond to issues

jobs:
  respond:
    if: |
      !github.event.issue.pull_request &&
      github.event.comment.author_association == 'MEMBER'
    runs-on: ubuntu-latest
    steps:
      - name: Process comment
        run: echo "Processing comment"
```

#### Deploy Workflow (Restricted)

```yaml
name: Deploy
on:
  push:
    branches: [main]

permissions:
  contents: read       # Read code
  deployments: write   # Create deployments

environment: production  # Requires approval

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Deploy
        run: ./deploy.sh
```

### Permission Inheritance

```yaml
# Repository-level default (settings)
permissions:
  contents: read

# Workflow-level override
permissions:
  contents: read
  issues: write

jobs:
  job1:
    # Inherits workflow permissions
    runs-on: ubuntu-latest

  job2:
    # Job-level override
    permissions:
      contents: write  # Only for this job
    runs-on: ubuntu-latest
```

---

## Secret Management

### Types of Secrets

#### 1. Repository Secrets
```yaml
env:
  API_KEY: ${{ secrets.API_KEY }}  # Repository secret
```

#### 2. Environment Secrets
```yaml
environment: production
env:
  PROD_KEY: ${{ secrets.PROD_KEY }}  # Environment-specific
```

#### 3. Organization Secrets
```yaml
env:
  ORG_TOKEN: ${{ secrets.ORG_TOKEN }}  # Shared across repos
```

### Secret Handling Best Practices

#### Never Log Secrets

**BAD:**
```yaml
- name: Debug
  run: |
    echo "Token: ${{ secrets.GITHUB_TOKEN }}"  # NEVER DO THIS
```

**GOOD:**
```yaml
- name: Use secret safely
  env:
    TOKEN: ${{ secrets.GITHUB_TOKEN }}
  run: |
    # GitHub automatically masks secrets in logs
    ./script-that-uses-token.sh
```

#### Mask Custom Secrets

```yaml
- name: Mask value
  run: |
    VALUE=$(generate-secret)
    echo "::add-mask::$VALUE"  # Mask in logs
    echo "MASKED_VALUE=$VALUE" >> $GITHUB_ENV
```

#### Secure Secret Generation

```yaml
- name: Generate secure token
  run: |
    TOKEN=$(openssl rand -hex 32)
    echo "::add-mask::$TOKEN"
    echo "TOKEN=$TOKEN" >> $GITHUB_ENV

- name: Use token
  run: |
    curl -H "Authorization: Bearer $TOKEN" https://api.example.com
```

### Secret Rotation Strategy

```yaml
name: Secret Rotation Check
on:
  schedule:
    - cron: '0 0 1 * *'  # Monthly

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - name: Check secret age
        run: |
          # Check last rotation date
          LAST_ROTATION="${{ secrets.LAST_ROTATION_DATE }}"
          DAYS_OLD=$(( ($(date +%s) - $(date -d "$LAST_ROTATION" +%s)) / 86400 ))

          if [ $DAYS_OLD -gt 90 ]; then
            echo "::warning::Secrets older than 90 days - rotation needed"
            exit 1
          fi
```

---

## Workflow Security Checklist

### Pre-Deployment Checklist

- [ ] **Permissions Block**: Explicit minimal permissions defined
- [ ] **No Hardcoded Secrets**: All sensitive data in secrets
- [ ] **Input Validation**: All user inputs validated
- [ ] **Third-Party Actions**: Pinned to SHA or specific version
- [ ] **PR Target Guards**: Security checks for pull_request_target
- [ ] **Environment Protection**: Production environments require approval
- [ ] **Branch Protection**: Main branch has protection rules
- [ ] **Secret Scanning**: Repository has secret scanning enabled
- [ ] **Audit Logs**: Workflow changes are logged
- [ ] **Testing**: Security tests pass

### Security Validation Script

```bash
#!/usr/bin/env bash
# validate-security.sh

echo "Running security validation..."

# Check permissions
./scripts/validate-workflow-permissions.sh .github/workflows/

# Scan for secrets
./scripts/check-secret-leaks.sh .

# Validate dependencies
npm audit --audit-level=high

# Check branch protection
gh api repos/:owner/:repo/branches/main/protection

echo "Security validation complete"
```

---

## Common Vulnerabilities

### 1. Command Injection

**VULNERABLE:**
```yaml
- name: Process input
  run: |
    echo "Processing ${{ github.event.issue.title }}"  # Injectable!
```

**SECURE:**
```yaml
- name: Process input safely
  env:
    TITLE: ${{ github.event.issue.title }}
  run: |
    echo "Processing ${TITLE//[^a-zA-Z0-9 ]/}"  # Sanitized
```

### 2. Script Injection in PR Titles

**VULNERABLE:**
```yaml
on: pull_request_target  # Runs with write permissions

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - run: |
          echo "${{ github.event.pull_request.title }}"  # Injectable!
```

**SECURE:**
```yaml
on: pull_request_target

jobs:
  check:
    if: |
      github.event.pull_request.head.repo.full_name == github.repository
    runs-on: ubuntu-latest
    steps:
      - name: Validate title
        env:
          PR_TITLE: ${{ github.event.pull_request.title }}
        run: |
          # Validate format
          if [[ ! "$PR_TITLE" =~ ^[a-zA-Z0-9\s\-\:]+$ ]]; then
            echo "Invalid PR title format"
            exit 1
          fi
```

### 3. Workflow Bypass via Fork

**VULNERABLE:**
```yaml
on: pull_request_target
permissions: write-all  # Dangerous!

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.pull_request.head.sha }}  # Untrusted code!
```

**SECURE:**
```yaml
on: pull_request_target
permissions:
  pull-requests: write

jobs:
  deploy:
    if: |
      contains(github.event.pull_request.labels.*.name, 'safe-to-test') &&
      github.actor == 'maintainer-username'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.pull_request.head.sha }}
```

### 4. Secret Exposure in Artifacts

**VULNERABLE:**
```yaml
- name: Create artifact
  run: |
    echo "${{ secrets.API_KEY }}" > config.txt  # Secret in artifact!

- uses: actions/upload-artifact@v3
  with:
    name: config
    path: config.txt  # Downloadable by anyone!
```

**SECURE:**
```yaml
- name: Create safe artifact
  run: |
    # Never include secrets in artifacts
    echo "Config created at $(date)" > config.txt

- uses: actions/upload-artifact@v3
  with:
    name: config
    path: config.txt
    retention-days: 1  # Minimize retention
```

---

## Security Best Practices

### 1. Use Environments for Deployment

```yaml
name: Deploy
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://example.com
    steps:
      - name: Deploy to production
        run: ./deploy.sh
```

**Environment Protection Rules:**
- Required reviewers
- Deployment branches restriction
- Wait timer
- Secret scoping

### 2. Implement CODEOWNERS

```plaintext
# .github/CODEOWNERS
.github/workflows/ @security-team @devops-team
scripts/ @backend-team
*.yml @security-team
```

### 3. Use Reusable Workflows

```yaml
# .github/workflows/reusable-secure.yml
name: Secure Reusable Workflow
on:
  workflow_call:
    secrets:
      token:
        required: true

permissions:
  contents: read

jobs:
  secure-job:
    runs-on: ubuntu-latest
    steps:
      - name: Secure operation
        env:
          TOKEN: ${{ secrets.token }}
        run: ./secure-script.sh
```

### 4. Implement Rate Limiting

```yaml
- name: API call with rate limiting
  run: |
    for i in {1..10}; do
      if curl -f -H "Authorization: token $TOKEN" \
         https://api.github.com/rate_limit; then
        break
      fi

      echo "Retry $i/10 - waiting..."
      sleep $((2 ** i))  # Exponential backoff
    done
```

### 5. Audit Workflow Changes

```yaml
name: Workflow Audit
on:
  push:
    paths:
      - '.github/workflows/**'

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Audit changes
        run: |
          # Log workflow changes
          git diff HEAD^ HEAD -- .github/workflows/ > workflow-changes.txt

          # Validate security
          ./scripts/validate-workflow-permissions.sh .github/workflows/

          # Alert security team
          gh issue create \
            --title "Workflow changes detected" \
            --body-file workflow-changes.txt \
            --label security-review
```

---

## Branch Protection

### Recommended Settings

```json
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "security-scan",
      "test-suite",
      "code-review"
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismissal_restrictions": {
      "users": ["security-lead"],
      "teams": ["security-team"]
    },
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "required_approving_review_count": 2
  },
  "restrictions": {
    "users": [],
    "teams": ["maintainers"]
  },
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_linear_history": true,
  "allow_squash_merge": true,
  "allow_merge_commit": false,
  "allow_rebase_merge": false,
  "delete_branch_on_merge": true
}
```

### Setting via GitHub CLI

```bash
#!/usr/bin/env bash
# setup-branch-protection.sh

REPO="owner/repo"
BRANCH="main"

gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/$REPO/branches/$BRANCH/protection" \
  --input branch-protection.json

echo "Branch protection configured for $BRANCH"
```

---

## Security Tools

### 1. Secret Scanning

Enable in repository settings or via API:

```bash
gh api \
  --method PATCH \
  -H "Accept: application/vnd.github+json" \
  /repos/:owner/:repo \
  -f security_and_analysis='{"secret_scanning":{"status":"enabled"},"secret_scanning_push_protection":{"status":"enabled"}}'
```

### 2. Dependabot Security Updates

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    reviewers:
      - "security-team"
    labels:
      - "security"
      - "dependencies"
```

### 3. Security Workflow

```yaml
name: Security Scan
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 0 * * *'  # Daily

jobs:
  scan:
    runs-on: ubuntu-latest
    permissions:
      security-events: write

    steps:
      - uses: actions/checkout@v4

      - name: Run permission validator
        run: |
          ./scripts/validate-workflow-permissions.sh .github/workflows/

      - name: Secret leak scan
        run: |
          ./scripts/check-secret-leaks.sh .

      - name: Dependency scan
        run: |
          npm audit --audit-level=high

      - name: CodeQL Analysis
        uses: github/codeql-action/analyze@v2
```

### 4. Pre-commit Hooks

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']

  - repo: https://github.com/zricethezav/gitleaks
    rev: v8.16.1
    hooks:
      - id: gitleaks
```

---

## Incident Response

### Security Incident Workflow

```yaml
name: Security Incident Response
on:
  workflow_dispatch:
    inputs:
      incident_type:
        description: 'Type of incident'
        required: true
        type: choice
        options:
          - secret-leak
          - permission-breach
          - suspicious-activity

jobs:
  respond:
    runs-on: ubuntu-latest
    steps:
      - name: Rotate secrets
        if: inputs.incident_type == 'secret-leak'
        run: |
          # Trigger secret rotation
          gh workflow run rotate-secrets.yml

      - name: Audit permissions
        if: inputs.incident_type == 'permission-breach'
        run: |
          # Review all workflow permissions
          ./scripts/audit-all-permissions.sh

      - name: Lock down
        if: inputs.incident_type == 'suspicious-activity'
        run: |
          # Disable workflows temporarily
          gh api \
            --method PUT \
            -H "Accept: application/vnd.github+json" \
            /repos/:owner/:repo/actions/permissions \
            -f enabled=false
```

### Incident Response Checklist

1. **Immediate Actions**
   - [ ] Identify scope of incident
   - [ ] Disable affected workflows if needed
   - [ ] Rotate compromised secrets
   - [ ] Review audit logs

2. **Investigation**
   - [ ] Analyze workflow run logs
   - [ ] Check for unauthorized changes
   - [ ] Review recent PRs and commits
   - [ ] Identify root cause

3. **Remediation**
   - [ ] Fix vulnerabilities
   - [ ] Update security controls
   - [ ] Test fixes thoroughly
   - [ ] Deploy patches

4. **Post-Incident**
   - [ ] Document lessons learned
   - [ ] Update security policies
   - [ ] Conduct security training
   - [ ] Improve monitoring

---

## Security Contacts

For security issues or questions:
- Security Team: security@example.com
- GitHub Security: https://github.com/security
- OWASP: https://owasp.org/www-project-top-ten/

---

## References

- [GitHub Actions Security Hardening](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- [OWASP Top 10 2021](https://owasp.org/www-project-top-ten/)
- [GitHub Security Best Practices](https://docs.github.com/en/code-security)
- [CIS GitHub Benchmark](https://www.cisecurity.org/benchmark/github)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)