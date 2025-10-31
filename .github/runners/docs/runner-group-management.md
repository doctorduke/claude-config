# GitHub Actions Runner Group Management Guide
## Wave 2: DevOps Troubleshooter - Complete Management Documentation

**Document Version:** 1.0.0
**Last Updated:** October 17, 2025
**Target Environment:** Windows + WSL 2.0
**Audience:** DevOps Engineers, Platform Teams, System Administrators

---

## Table of Contents

1. [Overview](#overview)
2. [Runner Group Architecture](#runner-group-architecture)
3. [Configuration Reference](#configuration-reference)
4. [Setup & Installation](#setup--installation)
5. [Runner Group Management](#runner-group-management)
6. [Label Assignment Strategy](#label-assignment-strategy)
7. [Workflow Routing Examples](#workflow-routing-examples)
8. [GitHub API Commands](#github-api-commands)
9. [Troubleshooting](#troubleshooting)
10. [Best Practices](#best-practices)
11. [Monitoring & Alerts](#monitoring--alerts)
12. [Security Considerations](#security-considerations)

---

## Overview

### Purpose

This guide provides comprehensive instructions for managing GitHub Actions runner groups in an organization-level self-hosted runner deployment. It covers:

- **Runner group configuration** - Organizing runners into logical groups
- **Label taxonomy implementation** - Applying the 48-label system from Wave 1
- **Repository access control** - Restricting which repos can use which runners
- **Workflow routing strategies** - Directing jobs to appropriate runners
- **Automation and synchronization** - Using GitHub API for programmatic management

### Key Concepts

**Runner Group**: A logical collection of runners that share:
- Common labels and capabilities
- Repository access permissions
- Resource characteristics
- Team ownership or purpose

**Label Assignment**: The process of applying descriptive labels to runners across 6 categories:
1. System labels (8 labels) - OS, architecture, capabilities
2. Resource labels (6 labels) - Performance tiers
3. Team labels (5+ labels) - Organizational ownership
4. Workflow type labels (10+ labels) - Job categorization
5. Priority labels (3 labels) - Queue management
6. Status labels (3 labels) - Operational state

**Repository Access**: Controls which repositories can execute workflows on which runner groups, enabling:
- Team isolation
- Cost allocation
- Security boundaries
- Capacity guarantees

---

## Runner Group Architecture

### Organizational Structure

```
GitHub Organization
│
├── Runner Group: ai-agents
│   ├── Purpose: AI-powered workflows (PR review, issue triage)
│   ├── Labels: [self-hosted, linux, x64, ai-agent]
│   ├── Min Runners: 3
│   ├── Max Runners: 10
│   └── Repository Access: AI agent repos (or all repos)
│
├── Runner Group: backend-team
│   ├── Purpose: Backend service development
│   ├── Labels: [self-hosted, linux, x64, team-backend]
│   ├── Min Runners: 1
│   ├── Max Runners: 5
│   └── Repository Access: api-server, microservices, database
│
├── Runner Group: frontend-team
│   ├── Purpose: Frontend development
│   ├── Labels: [self-hosted, linux, x64, team-frontend]
│   ├── Min Runners: 1
│   ├── Max Runners: 5
│   └── Repository Access: web-app, mobile-app, ui-components
│
├── Runner Group: platform-team
│   ├── Purpose: Infrastructure and DevOps
│   ├── Labels: [self-hosted, linux, x64, team-platform]
│   ├── Min Runners: 1
│   ├── Max Runners: 3
│   └── Repository Access: infra, devops, ci-cd-templates
│
└── Runner Group: shared-pool
    ├── Purpose: General-purpose fallback capacity
    ├── Labels: [self-hosted, linux, x64]
    ├── Min Runners: 2
    ├── Max Runners: 15
    └── Repository Access: All repositories
```

### Label Distribution Across Groups

| Runner Group | System Labels | Resource Labels | Team Labels | Special Capabilities |
|--------------|---------------|-----------------|-------------|---------------------|
| ai-agents | self-hosted, linux, x64, wsl-ubuntu-22.04 | tier-standard | team-ai-agents | ai-agent, docker-capable |
| backend-team | self-hosted, linux, x64, wsl-ubuntu-22.04 | tier-standard | team-backend | docker-capable |
| frontend-team | self-hosted, linux, x64, wsl-ubuntu-22.04 | tier-standard | team-frontend | docker-capable |
| platform-team | self-hosted, linux, x64, wsl-ubuntu-22.04 | tier-standard | team-platform | docker-capable |
| shared-pool | self-hosted, linux, x64, wsl-ubuntu-22.04 | tier-standard | (none) | docker-capable |

---

## Configuration Reference

### File Locations

All configuration files are located in the project root:

```
D:\doctorduke\github-act\
├── config/
│   ├── runner-groups.json              # Runner group definitions
│   └── label-assignment-rules.json     # Label assignment automation rules
├── scripts/
│   └── sync-runner-groups.sh           # GitHub API synchronization script
└── docs/
    ├── runner-group-management.md      # This document
    └── label-taxonomy.md               # Wave 1 label taxonomy specification
```

### Configuration File Structure

**config/runner-groups.json**

```json
{
  "metadata": {
    "version": "1.0.0",
    "last_updated": "2025-10-17",
    "managed_by": "DevOps Team"
  },
  "organization": {
    "name": "YOUR_GITHUB_ORG",
    "runner_groups_enabled": true
  },
  "runner_groups": [
    {
      "id": "ai-agents",
      "name": "ai-agents",
      "display_name": "AI Agent Runners",
      "description": "Self-hosted runners for AI-powered workflows",
      "visibility": "selected",
      "runners": {
        "min_runners": 3,
        "max_runners": 10,
        "default_labels": ["self-hosted", "linux", "x64", "ai-agent"]
      },
      "repository_access": {
        "access_level": "all",
        "repositories": []
      }
    }
  ]
}
```

**config/label-assignment-rules.json**

This file defines automated label assignment logic based on:
- System detection (OS, architecture, resources)
- Manual DevOps assignment (team, project)
- Dynamic workflow-based assignment (workflow type, priority)

See the full file at `D:\doctorduke\github-act\config\label-assignment-rules.json` for complete rules.

---

## Setup & Installation

### Prerequisites

1. **GitHub Organization Admin Access**
   - Organization owner or admin permissions
   - Ability to create and manage runner groups

2. **Personal Access Token (PAT)**
   - Scope: `admin:org` (for runner group management)
   - Scope: `repo` (for repository access)
   - Expiration: 90 days (align with security policy)

3. **Required Tools (WSL/Linux)**
   ```bash
   # Check if tools are installed
   command -v jq >/dev/null 2>&1 || echo "Install jq: sudo apt install jq"
   command -v curl >/dev/null 2>&1 || echo "Install curl: sudo apt install curl"
   ```

### Initial Setup Steps

#### Step 1: Create GitHub Personal Access Token

```bash
# Navigate to: https://github.com/settings/tokens/new
# OR use GitHub CLI:
gh auth login --scopes admin:org,repo

# Set token as environment variable
export GITHUB_TOKEN="ghp_your_token_here"

# Verify token
curl -H "Authorization: token ${GITHUB_TOKEN}" \
     https://api.github.com/user | jq '.login'
```

#### Step 2: Configure Organization Name

Edit `config/runner-groups.json` and set your organization name:

```json
{
  "organization": {
    "name": "your-github-org-name"
  }
}
```

#### Step 3: Customize Runner Groups

Edit `config/runner-groups.json` to match your organizational needs:

- Adjust repository lists in `repository_access.repositories`
- Modify `min_runners` and `max_runners` based on capacity planning
- Update labels to match your use cases

#### Step 4: Validate Configuration

```bash
# Navigate to scripts directory
cd D:/doctorduke/github-act/scripts

# Validate JSON syntax
jq empty ../config/runner-groups.json && echo "Valid JSON" || echo "Invalid JSON"

# Check label consistency with taxonomy
jq -r '.runner_groups[].runners.default_labels[]' ../config/runner-groups.json | sort -u
```

#### Step 5: Dry Run Synchronization

```bash
# Test what would be created/updated (no changes made)
./sync-runner-groups.sh \
  --org your-github-org \
  --token "${GITHUB_TOKEN}" \
  --dry-run \
  --verbose
```

#### Step 6: Create Runner Groups

```bash
# Actually create the runner groups
./sync-runner-groups.sh \
  --org your-github-org \
  --token "${GITHUB_TOKEN}" \
  --verbose

# Check logs
tail -f ../logs/sync-runner-groups-*.log
```

---

## Runner Group Management

### Creating a New Runner Group

#### Via Script (Recommended)

1. Edit `config/runner-groups.json` and add new group:

```json
{
  "id": "new-team",
  "name": "new-team",
  "display_name": "New Team Runners",
  "description": "Runners for new team",
  "visibility": "selected",
  "runners": {
    "min_runners": 1,
    "max_runners": 3,
    "default_labels": ["self-hosted", "linux", "x64", "team-new"]
  },
  "repository_access": {
    "access_level": "selected",
    "repositories": ["new-team-repo-1", "new-team-repo-2"]
  }
}
```

2. Run sync script:

```bash
./sync-runner-groups.sh --org your-org --token "${GITHUB_TOKEN}"
```

#### Via GitHub API (Manual)

```bash
# Create runner group
curl -X POST \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/orgs/YOUR_ORG/actions/runner-groups \
  -d '{
    "name": "new-team",
    "visibility": "selected",
    "allows_public_repositories": false
  }'
```

#### Via GitHub Web UI

1. Navigate to: `https://github.com/organizations/YOUR_ORG/settings/actions/runner-groups`
2. Click "New runner group"
3. Configure:
   - Name: `new-team`
   - Repository access: Selected repositories
   - Select repositories from list
4. Click "Create group"

### Updating Runner Group Configuration

#### Update Repository Access

```bash
# Get runner group ID
GROUP_ID=$(curl -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/orgs/YOUR_ORG/actions/runner-groups | \
  jq -r '.runner_groups[] | select(.name=="ai-agents") | .id')

# Update to allow all repositories
curl -X PATCH \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/orgs/YOUR_ORG/actions/runner-groups/${GROUP_ID} \
  -d '{
    "visibility": "all"
  }'
```

#### Add Specific Repository to Group

```bash
# Get repository ID
REPO_ID=$(curl -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/repos/YOUR_ORG/your-repo | jq -r '.id')

# Add repository to runner group
curl -X PUT \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/orgs/YOUR_ORG/actions/runner-groups/${GROUP_ID}/repositories/${REPO_ID}
```

### Deleting a Runner Group

**WARNING**: This removes the group. Runners in the group are NOT deleted but become unassigned.

```bash
# List runner groups
curl -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/orgs/YOUR_ORG/actions/runner-groups | \
  jq -r '.runner_groups[] | "\(.id) - \(.name)"'

# Delete runner group
curl -X DELETE \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/orgs/YOUR_ORG/actions/runner-groups/${GROUP_ID}
```

---

## Label Assignment Strategy

### Label Application Methods

#### 1. Automatic Assignment (System Labels)

Applied automatically during runner registration based on detected system characteristics.

**Implementation**: During runner setup, detection script applies labels:

```bash
# Detect and apply system labels
detect_labels() {
  local labels=("self-hosted")

  # OS detection
  if grep -q Microsoft /proc/version 2>/dev/null; then
    labels+=("linux" "wsl-ubuntu-22.04")
  fi

  # Architecture detection
  if [[ $(uname -m) == "x86_64" ]]; then
    labels+=("x64")
  fi

  # Docker detection
  if command -v docker >/dev/null 2>&1; then
    labels+=("docker-capable")
  fi

  # AI agent detection (check for LLM API keys)
  if [[ -n "${OPENAI_API_KEY}" ]] || [[ -n "${ANTHROPIC_API_KEY}" ]]; then
    labels+=("ai-agent")
  fi

  # Memory detection
  local mem_gb=$(free -g | awk '/^Mem:/{print $2}')
  if [[ ${mem_gb} -ge 16 ]]; then
    labels+=("high-memory")
  fi

  # Return comma-separated labels
  echo "${labels[@]}" | tr ' ' ','
}

# Apply labels during registration
./config.sh \
  --url https://github.com/YOUR_ORG \
  --token RUNNER_TOKEN \
  --labels "$(detect_labels),tier-standard"
```

#### 2. Manual Assignment (Team/Project Labels)

Applied by DevOps team based on runner purpose and organizational structure.

**Process**:

```bash
# After runner is registered, add team label
RUNNER_ID=$(curl -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/orgs/YOUR_ORG/actions/runners | \
  jq -r '.runners[] | select(.name=="runner-001") | .id')

# NOTE: GitHub API doesn't support direct label modification post-registration
# Labels must be set during initial config.sh run
# To change labels, you must remove and re-register the runner
```

**Alternative - Group Assignment**:

Instead of modifying labels, assign runner to appropriate group:

```bash
# Add runner to team-specific group
curl -X PUT \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/orgs/YOUR_ORG/actions/runner-groups/${GROUP_ID}/runners/${RUNNER_ID}
```

#### 3. Dynamic Assignment (Workflow Labels)

Applied at workflow execution time via `runs-on` directive. These are NOT stored on the runner.

**Workflow Example**:

```yaml
# .github/workflows/pr-review.yml
name: PR Review with AI
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  ai-review:
    runs-on:
      - self-hosted         # System label
      - linux               # System label
      - x64                 # System label
      - ai-agent            # Capability label
      - team-backend        # Team label (optional)
      - workflow-pr-review  # Workflow type label (documentation only)
      - priority-high       # Priority label (documentation only)
    steps:
      - uses: actions/checkout@v3
      - name: Run AI code review
        run: npm run ai:review
```

### Label Validation Rules

From `config/label-assignment-rules.json`:

```json
{
  "label_validation": {
    "rules": [
      {
        "rule": "Must have exactly one resource tier label",
        "validation": "count(tier-*) == 1",
        "severity": "error"
      },
      {
        "rule": "Must have exactly one status label",
        "validation": "count(status-*) == 1",
        "severity": "error"
      },
      {
        "rule": "AI workflows require ai-agent label",
        "validation": "if workflow_type in ['pr-review', 'issue-triage'] then has_label('ai-agent')",
        "severity": "error"
      }
    ]
  }
}
```

**Validation Script** (to be implemented in Wave 3):

```bash
# Validate runner labels against rules
./scripts/validate-runner-labels.sh --runner runner-001
```

---

## Workflow Routing Examples

### Example 1: AI-Powered PR Review

**Requirement**: Execute AI code review on every pull request using LLM-capable runner.

**Workflow Configuration**:

```yaml
# .github/workflows/ai-pr-review.yml
name: AI-Powered PR Review

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  ai-code-review:
    name: AI Code Analysis
    runs-on:
      - self-hosted
      - linux
      - x64
      - ai-agent        # REQUIRED: Runner must have LLM capabilities
    timeout-minutes: 5
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
        with:
          fetch-depth: 0  # Full history for better context

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Run AI code review
        env:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          npm install
          npm run ai:review -- --pr-number ${{ github.event.pull_request.number }}
```

**Runner Matching**:
- Matches runners in `ai-agents` group
- Falls back to `shared-pool` if runner has `ai-agent` label
- Fails if no LLM-capable runner available

### Example 2: Team-Isolated Backend Tests

**Requirement**: Run backend service tests on dedicated backend team runner.

**Workflow Configuration**:

```yaml
# .github/workflows/backend-tests.yml
name: Backend Service Tests

on:
  push:
    branches: [main, develop]
    paths:
      - 'services/**'
      - 'tests/**'

jobs:
  unit-tests:
    name: Unit Tests
    runs-on:
      - self-hosted
      - linux
      - x64
      - team-backend    # Prefer backend team runner
      - tier-standard   # Standard performance tier
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v3

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install pytest pytest-cov

      - name: Run tests
        run: pytest tests/ --cov=services/

  integration-tests:
    name: Integration Tests
    needs: unit-tests
    runs-on:
      - self-hosted
      - linux
      - x64
      - team-backend
      - docker-capable  # REQUIRED: Docker for test databases
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v3

      - name: Start test database
        run: docker-compose -f docker-compose.test.yml up -d

      - name: Run integration tests
        run: pytest tests/integration/

      - name: Cleanup
        if: always()
        run: docker-compose -f docker-compose.test.yml down
```

### Example 3: Multi-Priority Workflow

**Requirement**: Different priority levels for different workflow types.

**Workflow Configuration**:

```yaml
# .github/workflows/ci-pipeline.yml
name: CI Pipeline

on:
  pull_request:
  push:
    branches: [main]

jobs:
  # Critical priority - linting (fast feedback)
  lint:
    name: Code Quality
    runs-on: [self-hosted, linux, x64, tier-standard]
    timeout-minutes: 5
    # Implicit priority-high for PR workflows
    steps:
      - uses: actions/checkout@v3
      - run: npm run lint

  # High priority - unit tests
  test:
    name: Unit Tests
    runs-on: [self-hosted, linux, x64, tier-standard]
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v3
      - run: npm test

  # Normal priority - E2E tests (slower, less frequent)
  e2e:
    name: E2E Tests
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: [self-hosted, linux, x64, tier-performance]
    timeout-minutes: 60
    steps:
      - uses: actions/checkout@v3
      - run: npm run test:e2e
```

### Example 4: Fallback to Shared Pool

**Requirement**: Use team runner if available, otherwise fall back to shared pool.

**Implementation Strategy**:

GitHub Actions will automatically fall back if exact match not found:

1. First tries: `[self-hosted, linux, x64, team-backend]`
2. If not available, matches: `[self-hosted, linux, x64]` (from shared-pool)

**Workflow Configuration**:

```yaml
jobs:
  build:
    runs-on:
      - self-hosted
      - linux
      - x64
      - team-backend  # Prefer team runner, but will use shared pool
    steps:
      - uses: actions/checkout@v3
      - run: make build
```

**Note**: Runner matching is based on ALL labels in `runs-on` being present on the runner. If no runner has ALL labels, the job will queue until one becomes available.

---

## GitHub API Commands

### Authentication

All API commands require authentication. Set your token:

```bash
export GITHUB_TOKEN="ghp_your_token_here"
export GITHUB_ORG="your-org-name"
```

### List Runner Groups

```bash
# List all runner groups
curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/orgs/${GITHUB_ORG}/actions/runner-groups | \
  jq -r '.runner_groups[] | "\(.id) - \(.name) - \(.visibility)"'

# Get specific runner group details
GROUP_ID=12345
curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/orgs/${GITHUB_ORG}/actions/runner-groups/${GROUP_ID} | \
  jq .
```

### List Runners

```bash
# List all runners in organization
curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/orgs/${GITHUB_ORG}/actions/runners | \
  jq -r '.runners[] | "\(.id) - \(.name) - \(.status) - \(.labels | map(.name) | join(","))"'

# List runners in specific group
curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/orgs/${GITHUB_ORG}/actions/runner-groups/${GROUP_ID}/runners | \
  jq -r '.runners[] | "\(.name) - \(.status)"'
```

### Manage Repository Access

```bash
# List repositories with access to runner group
curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/orgs/${GITHUB_ORG}/actions/runner-groups/${GROUP_ID}/repositories | \
  jq -r '.repositories[] | "\(.id) - \(.name)"'

# Get repository ID
REPO_ID=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/repos/${GITHUB_ORG}/your-repo | jq -r '.id')

# Grant repository access to runner group
curl -X PUT \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/orgs/${GITHUB_ORG}/actions/runner-groups/${GROUP_ID}/repositories/${REPO_ID}

# Revoke repository access
curl -X DELETE \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/orgs/${GITHUB_ORG}/actions/runner-groups/${GROUP_ID}/repositories/${REPO_ID}
```

### Runner Registration Token

```bash
# Generate registration token for organization
curl -s -X POST \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/orgs/${GITHUB_ORG}/actions/runners/registration-token | \
  jq -r '.token'

# Generate registration token for specific runner group (if supported)
# Note: Check GitHub API documentation for current capabilities
```

### Remove Runner

```bash
# Get runner ID
RUNNER_ID=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/orgs/${GITHUB_ORG}/actions/runners | \
  jq -r '.runners[] | select(.name=="runner-001") | .id')

# Remove runner from organization
curl -X DELETE \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/orgs/${GITHUB_ORG}/actions/runners/${RUNNER_ID}
```

---

## Troubleshooting

### Issue 1: Runner Not Appearing in Group

**Symptoms**:
- Runner is online but not visible in expected runner group
- Workflows can't find runner with specific labels

**Diagnosis**:

```bash
# Check runner status and labels
curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/orgs/${GITHUB_ORG}/actions/runners | \
  jq -r '.runners[] | select(.name=="runner-001") | {name, status, labels}'

# Check runner group membership
for group_id in $(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/orgs/${GITHUB_ORG}/actions/runner-groups | \
  jq -r '.runner_groups[].id'); do
  echo "Group ${group_id}:"
  curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
    https://api.github.com/orgs/${GITHUB_ORG}/actions/runner-groups/${group_id}/runners | \
    jq -r '.runners[] | select(.name=="runner-001") | .name'
done
```

**Resolution**:

1. Verify runner has correct labels during registration
2. Check runner group visibility settings (must be "selected" or "all")
3. Verify repository has access to the runner group

### Issue 2: Workflow Queuing Forever

**Symptoms**:
- Workflow job status shows "Queued" indefinitely
- No matching runner found

**Diagnosis**:

```bash
# Check what labels workflow is requesting
# (View workflow file .github/workflows/your-workflow.yml)

# Check if any runner has matching labels
curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/orgs/${GITHUB_ORG}/actions/runners | \
  jq -r '.runners[] | select(.status=="online") | {name, labels: (.labels | map(.name))}'

# Check runner group repository access
GROUP_ID=12345
curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/orgs/${GITHUB_ORG}/actions/runner-groups/${GROUP_ID}/repositories | \
  jq -r '.repositories[].name'
```

**Resolution**:

1. Verify runner has ALL labels specified in `runs-on`
2. Check runner status is "online"
3. Verify repository has access to runner group
4. Check if runner is busy (at capacity)

### Issue 3: Permission Denied for Runner Group

**Symptoms**:
- Repository workflows fail with "No runner available"
- Runner group exists but repository can't access it

**Diagnosis**:

```bash
# Check runner group visibility
curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/orgs/${GITHUB_ORG}/actions/runner-groups | \
  jq -r '.runner_groups[] | {name, visibility, allows_public_repositories}'

# Check repository access list
GROUP_ID=12345
curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/orgs/${GITHUB_ORG}/actions/runner-groups/${GROUP_ID}/repositories
```

**Resolution**:

```bash
# Grant repository access
REPO_ID=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/repos/${GITHUB_ORG}/your-repo | jq -r '.id')

curl -X PUT \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/orgs/${GITHUB_ORG}/actions/runner-groups/${GROUP_ID}/repositories/${REPO_ID}
```

### Issue 4: Sync Script Fails

**Symptoms**:
- `sync-runner-groups.sh` exits with error
- API authentication failures

**Diagnosis**:

```bash
# Test GitHub token
curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/user | jq '.login'

# Check token scopes
curl -s -I -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/user | grep -i 'x-oauth-scopes'

# Verify configuration file
jq empty config/runner-groups.json && echo "Valid JSON" || echo "Invalid JSON"

# Run sync script in dry-run mode
./scripts/sync-runner-groups.sh --org ${GITHUB_ORG} --token ${GITHUB_TOKEN} --dry-run --verbose
```

**Resolution**:

1. Verify token has `admin:org` scope
2. Check token hasn't expired
3. Validate JSON configuration syntax
4. Review logs in `logs/sync-runner-groups-*.log`

---

## Best Practices

### 1. Label Naming Conventions

- **Use kebab-case**: `team-backend` not `team_backend` or `teamBackend`
- **Be specific**: `tier-standard` not just `standard`
- **Follow taxonomy**: Use labels from `docs/label-taxonomy.md`
- **Avoid spaces**: GitHub labels cannot contain spaces

### 2. Runner Group Design

- **Dedicated groups for teams**: Guarantees capacity for critical teams
- **Shared pool as fallback**: Always maintain a shared pool for overflow
- **Limit public access**: Set `allows_public_repositories: false` for security
- **Use selected visibility**: Control which repos can use which groups

### 3. Repository Access Control

- **Principle of least privilege**: Only grant access to repos that need it
- **Group by purpose**: AI repos → ai-agents group, Backend repos → backend-team group
- **Document exceptions**: If a repo needs access to multiple groups, document why
- **Regular audits**: Review repository access quarterly

### 4. Capacity Planning

- **Min runners = baseline**: Set `min_runners` to handle typical load
- **Max runners = peak + buffer**: Set `max_runners` to handle 2x peak load
- **Monitor utilization**: Track queue depth and runner utilization
- **Scale proactively**: Add runners before hitting max capacity

### 5. Label Management

- **Automate system labels**: Use detection scripts for OS, arch, capabilities
- **Manual team labels**: DevOps assigns team/project labels during provisioning
- **Document workflow labels**: Workflow labels are informational, not enforced
- **Validate labels**: Run validation before deploying runners

### 6. Security

- **Rotate PATs regularly**: Every 90 days (align with security policy)
- **Use organization secrets**: Store tokens in GitHub Secrets, not in code
- **Audit access logs**: Review who is managing runner groups
- **Restrict group management**: Limit admin:org scope to DevOps team only

### 7. Monitoring

- **Track queue depth**: Alert if queue depth >10 for >5 minutes
- **Monitor runner health**: Heartbeat checks every 30 seconds
- **Measure job wait time**: SLA <2 minutes for high-priority jobs
- **Cost tracking**: Monitor runner utilization vs. cost per group

---

## Monitoring & Alerts

### Key Metrics to Track

| Metric | Target | Alert Threshold | Collection Interval |
|--------|--------|-----------------|---------------------|
| Queue Depth | <5 jobs | >10 jobs | Real-time |
| Avg Wait Time | <2 min | >5 min | Hourly |
| Runner Utilization | 60-80% | <40% or >90% | Hourly |
| Success Rate | >95% | <90% | Daily |
| Runner Health | 100% online | <90% online | Real-time |

### Monitoring Dashboard (Example)

```yaml
# monitoring/runner-metrics.yaml
metrics:
  - name: queue_depth_by_group
    query: |
      SELECT runner_group, COUNT(*) as queued_jobs
      FROM github_workflow_jobs
      WHERE status = 'queued'
      GROUP BY runner_group

  - name: runner_utilization
    query: |
      SELECT
        runner_group,
        COUNT(CASE WHEN status='busy' THEN 1 END) / COUNT(*) * 100 as utilization_percent
      FROM github_runners
      GROUP BY runner_group

  - name: job_wait_time_p95
    query: |
      SELECT
        runner_group,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY wait_time_seconds) as p95_wait_time
      FROM github_workflow_jobs
      WHERE completed_at > NOW() - INTERVAL '1 hour'
      GROUP BY runner_group
```

### Alert Configuration

```yaml
# monitoring/alerts.yaml
alerts:
  - name: high_queue_depth
    condition: queue_depth > 10 AND duration > 5min
    severity: warning
    action: scale_up
    notification: devops-slack-channel

  - name: critical_queue_depth
    condition: queue_depth > 20
    severity: critical
    action: scale_up_urgent
    notification: devops-pagerduty

  - name: runner_offline
    condition: runner_status == 'offline' AND duration > 2min
    severity: warning
    action: investigate
    notification: devops-slack-channel

  - name: low_success_rate
    condition: success_rate < 90% AND window = 1hour
    severity: critical
    action: investigate
    notification: devops-pagerduty
```

### GitHub API Monitoring Script

```bash
#!/bin/bash
# monitor-runner-status.sh

check_runner_health() {
  local org="$1"

  # Get runner status
  local runners=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
    https://api.github.com/orgs/${org}/actions/runners)

  local total=$(echo "$runners" | jq '.total_count')
  local online=$(echo "$runners" | jq '[.runners[] | select(.status=="online")] | length')
  local busy=$(echo "$runners" | jq '[.runners[] | select(.busy==true)] | length')

  echo "Total runners: ${total}"
  echo "Online: ${online} ($(( online * 100 / total ))%)"
  echo "Busy: ${busy} ($(( busy * 100 / online ))% utilization)"

  # Alert if <90% online
  if (( online * 100 / total < 90 )); then
    echo "ALERT: Less than 90% of runners are online"
  fi
}

# Run every 5 minutes via cron
check_runner_health "${GITHUB_ORG}"
```

---

## Security Considerations

### Personal Access Token Management

**Scope Requirements**:
- `admin:org` - Required for runner group management
- `repo` - Required for repository access control

**Security Best Practices**:
- Store tokens in environment variables, never in code
- Use GitHub Secrets for CI/CD workflows
- Rotate tokens every 90 days
- Audit token usage in GitHub settings
- Revoke tokens immediately when team members leave

### Runner Group Security

**Access Control**:
- Use "selected" visibility, not "all" for sensitive groups
- Set `allows_public_repositories: false` for all groups
- Restrict repository access to minimum required
- Regular access reviews (quarterly)

**Workflow Security**:
- Review workflow files that use self-hosted runners
- Validate `runs-on` labels match runner capabilities
- Use required status checks to prevent malicious workflows
- Enable workflow approval for external contributors

### Secret Management

**Organization Secrets**:
- Use organization-level secrets for shared credentials
- Limit secret access to specific repository groups
- Rotate secrets on same schedule as PATs (90 days)

**Runner Secrets**:
- Store runner tokens securely (not in version control)
- Use environment variables for sensitive configuration
- Implement secret scanning in workflows

---

## Appendix: Complete Label Reference

### All 48 Labels from Wave 1 Taxonomy

**System Labels (8)**:
- self-hosted
- linux
- x64
- ai-agent
- wsl-ubuntu-22.04
- docker-capable
- gpu-available
- high-memory

**Resource Labels (6)**:
- tier-basic
- tier-standard
- tier-performance
- tier-compute-optimized
- tier-memory-optimized
- tier-io-optimized

**Team Labels (5+)**:
- team-backend
- team-frontend
- team-platform
- team-data
- team-ai-agents

**Project Labels (2+)**:
- project-payments
- project-docs

**Workflow Type Labels (10)**:
- workflow-pr-review
- workflow-issue-triage
- workflow-code-quality
- workflow-unit-tests
- workflow-integration-tests
- workflow-build
- workflow-security-scan
- workflow-e2e-tests
- workflow-deploy
- workflow-docs

**Priority Labels (3)**:
- priority-critical
- priority-high
- priority-normal

**Status Labels (3)**:
- status-active
- status-draining
- status-offline

**Total: 48 labels** across 6 categories

---

## Quick Reference Card

### Common Commands

```bash
# List runner groups
curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/orgs/${GITHUB_ORG}/actions/runner-groups | jq -r '.runner_groups[].name'

# List runners with labels
curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/orgs/${GITHUB_ORG}/actions/runners | \
  jq -r '.runners[] | "\(.name): \(.labels | map(.name) | join(", "))"'

# Sync runner groups from config
./scripts/sync-runner-groups.sh --org ${GITHUB_ORG} --token ${GITHUB_TOKEN}

# Dry run sync
./scripts/sync-runner-groups.sh --org ${GITHUB_ORG} --token ${GITHUB_TOKEN} --dry-run

# Generate registration token
curl -s -X POST -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/orgs/${GITHUB_ORG}/actions/runners/registration-token | jq -r '.token'
```

### File Paths

- Config: `D:\doctorduke\github-act\config\runner-groups.json`
- Rules: `D:\doctorduke\github-act\config\label-assignment-rules.json`
- Sync Script: `D:\doctorduke\github-act\scripts\sync-runner-groups.sh`
- Taxonomy: `D:\doctorduke\github-act\docs\label-taxonomy.md`
- This Guide: `D:\doctorduke\github-act\docs\runner-group-management.md`

---

## Additional Resources

- **GitHub Documentation**:
  - [Managing access to self-hosted runners using groups](https://docs.github.com/en/actions/hosting-your-own-runners/managing-access-to-self-hosted-runners-using-groups)
  - [REST API - Self-hosted runner groups](https://docs.github.com/en/rest/actions/self-hosted-runner-groups)
  - [Using labels with self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners/using-labels-with-self-hosted-runners)

- **Project Documentation**:
  - Wave 1 Label Taxonomy: `docs/label-taxonomy.md`
  - Wave 1 Requirements: `docs/requirements.md`
  - Wave 1 Capacity Planning: `docs/capacity-planning.md`

---

**Document Status**: Complete
**Next Steps**: Proceed to Wave 3 (Implementation) using this guide for runner group configuration
**Feedback**: Submit issues or improvements to DevOps team

---

*End of Runner Group Management Guide*
