# Workflow Templates Reference
## Self-Hosted GitHub Actions AI Agent System - Wave 1

---

## Table of Contents
1. [Overview](#overview)
2. [Template Usage Guide](#template-usage-guide)
3. [Core Workflow Templates](#core-workflow-templates)
4. [Reusable Components](#reusable-components)
5. [Supporting Script Templates](#supporting-script-templates)
6. [Configuration Examples](#configuration-examples)

---

## Overview

### Template Library Structure

```
.github/
├── workflows/
│   ├── pr-review-ai.yml              # AI-powered PR review
│   ├── issue-auto-respond.yml        # Automatic issue responses
│   ├── code-auto-fix.yml             # Automated code fixes
│   ├── reusable-ai-workflow.yml      # Reusable workflow pattern
│   ├── security-scan.yml             # Security scanning
│   ├── test-matrix.yml               # Cross-platform testing
│   ├── dependency-update.yml         # Dependency management
│   ├── release-automation.yml        # Release process
│   ├── documentation-update.yml      # Docs generation
│   └── notification-handler.yml      # Alert management
├── actions/
│   └── setup-ai-agent/
│       └── action.yml                # Composite setup action
└── scripts/
    ├── ai-pr-review.sh               # PR review script
    ├── ai-issue-respond.sh           # Issue response script
    ├── ai-generate-fixes.sh          # Fix generation script
    ├── extract-pr-context.sh         # Context extraction
    ├── validate-schema.sh            # Schema validation
    └── notify-error.sh               # Error notification
```

### Design Principles

1. **Reusability**: Templates designed for copy-paste deployment
2. **Configurability**: Environment variables for customization
3. **Security**: Minimal permissions, secret management
4. **Performance**: Sparse checkout, caching strategies
5. **Observability**: Comprehensive logging and metrics

---

## Template Usage Guide

### Quick Start

**1. Copy Template to Repository:**
```bash
# Copy workflow template
cp templates/workflows/pr-review-ai.yml .github/workflows/

# Copy composite action
cp -r templates/actions/setup-ai-agent .github/actions/

# Copy supporting scripts
mkdir -p .github/scripts
cp templates/scripts/*.sh .github/scripts/
chmod +x .github/scripts/*.sh
```

**2. Configure Secrets:**
```bash
# GitHub CLI method
gh secret set AI_API_KEY --body "$YOUR_AI_API_KEY"
gh secret set AI_AGENT_PAT --body "$YOUR_PAT_TOKEN"

# Or via GitHub UI: Settings → Secrets and variables → Actions
```

**3. Customize Configuration:**
```yaml
# In workflow file, adjust these variables:
env:
  AI_MODEL: "gpt-4"              # or claude-3-opus-20240229
  AI_PROVIDER: "openai"          # or anthropic, azure-openai
  AI_TEMPERATURE: "0.3"
  SPARSE_CHECKOUT: "true"
```

**4. Test Workflow:**
```bash
# Trigger manually first
gh workflow run pr-review-ai.yml

# Check status
gh run list --workflow=pr-review-ai.yml
```

### Customization Points

**Runner Labels:**
```yaml
runs-on: [self-hosted, linux, ai-agent]  # Standard
# OR
runs-on: [self-hosted, linux, ai-agent, high-memory]  # Custom pool
```

**Event Triggers:**
```yaml
on:
  pull_request:
    types: [opened, synchronize]
    branches: [main, develop]    # Only important branches
    paths:
      - 'src/**'                 # Only source code changes
      - '!docs/**'               # Ignore documentation
```

**Permissions:**
```yaml
permissions:
  contents: read                 # Minimum required
  pull-requests: write           # Only what's needed
  # Add more as required
```

---

## Core Workflow Templates

### 1. PR Review AI (pr-review-ai.yml)

**Purpose**: Automated AI-powered code review for pull requests

**Triggers**:
- `pull_request`: opened, synchronize, reopened
- Manual via workflow_dispatch

**Key Features**:
- Sparse checkout for performance
- Comprehensive PR context extraction
- AI-generated review comments
- Inline comment posting
- Quality score calculation

**Configuration Options**:
```yaml
env:
  AI_MODEL: "gpt-4"                    # AI model to use
  AI_FOCUS_AREAS: "security,performance,style"  # Review focus
  MIN_SCORE_FOR_APPROVAL: "85"        # Auto-approve threshold
  SKIP_DRAFT_PRS: "true"              # Skip draft PRs
  MAX_FILES_FOR_REVIEW: "20"          # Limit file count
```

**Outputs**:
- Review summary comment on PR
- Inline comments on specific lines
- Quality score (0-100)
- Issue count by severity
- Label: `ai-reviewed`

**Usage Example**:
```yaml
# Minimal configuration
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  ai-review:
    uses: ./.github/workflows/pr-review-ai.yml
    secrets:
      ai-api-key: ${{ secrets.AI_API_KEY }}
```

### 2. Issue Auto-Respond (issue-auto-respond.yml)

**Purpose**: Intelligent automated responses to issues and comments

**Triggers**:
- `issues`: opened, labeled (with 'ai-assist')
- `issue_comment`: created (when bot mentioned)

**Key Features**:
- Context-aware responses
- Issue categorization (bug, feature, question, etc.)
- Duplicate detection
- Auto-labeling
- Conditional auto-close

**Configuration Options**:
```yaml
env:
  AI_MODEL: "gpt-4"
  ENABLE_AUTO_CLOSE: "true"           # Auto-close resolved issues
  ENABLE_AUTO_LABEL: "true"           # Auto-label by category
  RESPONSE_TEMPLATE_DIR: ".github/templates/responses"
  CHECK_DUPLICATES: "true"            # Check for duplicate issues
```

**Outputs**:
- Contextual comment on issue
- Applied labels
- Linked related issues/PRs
- Close issue if resolved

**Usage Example**:
```yaml
on:
  issues:
    types: [opened, labeled]
  issue_comment:
    types: [created]

jobs:
  auto-respond:
    if: |
      contains(github.event.issue.labels.*.name, 'ai-assist') ||
      contains(github.event.comment.body, '@ai-assistant')
    uses: ./.github/workflows/issue-auto-respond.yml
    secrets:
      ai-api-key: ${{ secrets.AI_API_KEY }}
```

### 3. Code Auto-Fix (code-auto-fix.yml)

**Purpose**: Automated code corrections based on linting and analysis

**Triggers**:
- `pull_request`: labeled (with 'auto-fix')
- `issue_comment`: created (with '/fix' command)
- Manual via workflow_dispatch

**Key Features**:
- Multi-tool analysis (ESLint, Prettier, etc.)
- AI-generated fixes
- Automated commit and push
- Safety validation
- Test verification

**Configuration Options**:
```yaml
env:
  FIX_TYPES: "lint,format,security"   # Types of fixes to apply
  RUN_TESTS_AFTER_FIX: "true"        # Verify with tests
  CREATE_SEPARATE_COMMIT: "true"     # Don't amend existing
  PUSH_TO_NEW_BRANCH: "false"        # Push to same branch
```

**Outputs**:
- Fixes committed to branch
- Summary comment with fix details
- Test results (if enabled)
- Labels: `ai-fixed`, remove `auto-fix`

**Usage Example**:
```yaml
on:
  pull_request:
    types: [labeled]
  issue_comment:
    types: [created]

jobs:
  auto-fix:
    if: |
      (github.event_name == 'pull_request' &&
       contains(github.event.label.name, 'auto-fix')) ||
      (github.event_name == 'issue_comment' &&
       contains(github.event.comment.body, '/fix'))
    uses: ./.github/workflows/code-auto-fix.yml
    secrets:
      ai-api-key: ${{ secrets.AI_API_KEY }}
      ai-agent-pat: ${{ secrets.AI_AGENT_PAT }}  # For protected branches
```

### 4. Reusable AI Workflow (reusable-ai-workflow.yml)

**Purpose**: Generic reusable workflow for any AI task

**Trigger**: workflow_call only

**Key Features**:
- Flexible AI task dispatcher
- Configurable inputs
- Standardized outputs
- Error handling
- Metrics collection

**Input Parameters**:
```yaml
inputs:
  ai-task:
    description: 'AI task (review, respond, fix, explain)'
    required: true
    type: string
  context-type:
    description: 'Context (pr, issue, commit)'
    required: true
    type: string
  context-id:
    description: 'PR/issue number or commit SHA'
    required: true
    type: string
  ai-model:
    description: 'AI model to use'
    required: false
    type: string
    default: 'gpt-4'
  sparse-checkout:
    description: 'Enable sparse checkout'
    required: false
    type: boolean
    default: true
```

**Usage Example**:
```yaml
jobs:
  call-ai-task:
    uses: ./.github/workflows/reusable-ai-workflow.yml
    with:
      ai-task: 'review'
      context-type: 'pr'
      context-id: '${{ github.event.pull_request.number }}'
      ai-model: 'claude-3-opus-20240229'
      sparse-checkout: true
    secrets:
      ai-api-key: ${{ secrets.ANTHROPIC_API_KEY }}
```

### 5. Security Scan (security-scan.yml)

**Purpose**: Automated security vulnerability scanning

**Triggers**:
- `pull_request`: opened, synchronize
- `push`: to main/develop
- `schedule`: daily at 2 AM UTC

**Key Features**:
- Dependency vulnerability scanning
- SAST (static analysis)
- Secret detection
- License compliance
- AI-powered threat assessment

**Configuration Options**:
```yaml
env:
  SCAN_DEPENDENCIES: "true"
  SCAN_CODE: "true"
  SCAN_SECRETS: "true"
  SCAN_LICENSES: "true"
  FAIL_ON_HIGH_SEVERITY: "true"
  AI_ANALYSIS: "true"                # Use AI for threat assessment
```

**Outputs**:
- Security report comment
- SARIF file for GitHub Security tab
- Vulnerability labels
- Block merge on high severity (optional)

### 6. Test Matrix (test-matrix.yml)

**Purpose**: Cross-platform testing with matrix strategy

**Triggers**:
- `pull_request`: opened, synchronize
- `push`: to main/develop

**Key Features**:
- Multi-OS testing (Windows, Linux, macOS)
- Multi-version testing (Node, Python, etc.)
- Parallel execution
- Result aggregation
- AI-powered failure analysis

**Configuration Options**:
```yaml
strategy:
  matrix:
    os: [ubuntu-latest, windows-latest, macos-latest]
    node: [16, 18, 20]
    include:
      - os: ubuntu-latest
        node: 18
        coverage: true
  fail-fast: false
  max-parallel: 6
```

### 7. Dependency Update (dependency-update.yml)

**Purpose**: Automated dependency updates with AI analysis

**Triggers**:
- `schedule`: weekly on Monday
- Manual via workflow_dispatch

**Key Features**:
- Dependency scanning
- Version comparison
- Breaking change detection
- AI-powered changelog summary
- Automated PR creation

**Configuration Options**:
```yaml
env:
  UPDATE_MAJOR: "false"              # Only minor/patch
  RUN_TESTS: "true"                  # Verify updates
  CREATE_PR: "true"                  # Auto-create PR
  AI_CHANGELOG_SUMMARY: "true"       # AI summary of changes
```

### 8. Release Automation (release-automation.yml)

**Purpose**: Automated release process with changelog generation

**Triggers**:
- `push`: tags matching 'v*'
- Manual via workflow_dispatch

**Key Features**:
- Changelog generation
- Asset building
- GitHub release creation
- Notification distribution
- AI-generated release notes

**Configuration Options**:
```yaml
env:
  BUILD_ASSETS: "true"
  GENERATE_CHANGELOG: "true"
  AI_RELEASE_NOTES: "true"
  NOTIFY_CHANNELS: "slack,discord"
```

### 9. Documentation Update (documentation-update.yml)

**Purpose**: Automated documentation generation and updates

**Triggers**:
- `push`: to main (when code changes)
- `schedule`: weekly
- Manual via workflow_dispatch

**Key Features**:
- API documentation generation
- README updates
- Code example generation
- AI-powered doc improvements
- Automated commit to docs

**Configuration Options**:
```yaml
env:
  GENERATE_API_DOCS: "true"
  UPDATE_README: "true"
  GENERATE_EXAMPLES: "true"
  AI_IMPROVE_DOCS: "true"
  DOCS_BRANCH: "main"                # or "docs"
```

### 10. Notification Handler (notification-handler.yml)

**Purpose**: Centralized notification and alerting

**Triggers**:
- `workflow_run`: completion (of other workflows)
- Manual via workflow_call

**Key Features**:
- Multi-channel notifications (Slack, Discord, Email)
- Status aggregation
- AI-powered message formatting
- Failure summaries
- Metric reporting

**Configuration Options**:
```yaml
env:
  NOTIFY_ON_SUCCESS: "false"
  NOTIFY_ON_FAILURE: "true"
  CHANNELS: "slack,email"
  AI_FORMAT_MESSAGE: "true"
  INCLUDE_METRICS: "true"
```

---

## Reusable Components

### Composite Action: setup-ai-agent

**Location**: `.github/actions/setup-ai-agent/action.yml`

**Purpose**: Common setup tasks for all AI workflows

**Inputs**:
```yaml
inputs:
  sparse-checkout:
    description: 'Enable sparse checkout'
    required: false
    default: 'true'
  checkout-paths:
    description: 'Paths to checkout (newline separated)'
    required: false
    default: |
      .github/
  ref:
    description: 'Git ref to checkout'
    required: false
    default: ''
  setup-node:
    description: 'Setup Node.js'
    required: false
    default: 'false'
  node-version:
    description: 'Node.js version'
    required: false
    default: '18'
  setup-python:
    description: 'Setup Python'
    required: false
    default: 'false'
  python-version:
    description: 'Python version'
    required: false
    default: '3.11'
```

**Steps Performed**:
1. Sparse or full checkout
2. GitHub CLI setup and verification
3. WSL environment configuration (if Windows)
4. Cache restoration
5. Optional language runtime setup
6. Environment validation

**Usage Example**:
```yaml
steps:
  - name: Setup AI Agent Environment
    uses: ./.github/actions/setup-ai-agent
    with:
      sparse-checkout: 'true'
      checkout-paths: |
        .github/
        src/
        package.json
      setup-node: 'true'
      node-version: '18'
```

---

## Supporting Script Templates

### Script: ai-pr-review.sh

**Purpose**: Extract PR context, call AI API, process review

**Usage**:
```bash
bash .github/scripts/ai-pr-review.sh \
  --pr-number "$PR_NUMBER" \
  --ai-model "$AI_MODEL" \
  --focus-areas "security,performance"
```

**Environment Variables Required**:
- `GITHUB_TOKEN` or `GH_TOKEN`
- `AI_API_KEY`
- `GITHUB_REPOSITORY`

**Outputs**:
- `pr-context.json` - Extracted context
- `ai-response.json` - AI review response
- `review-comment.md` - Formatted comment
- Exit code: 0 (success), 1 (error)

### Script: ai-issue-respond.sh

**Purpose**: Generate contextual issue responses

**Usage**:
```bash
bash .github/scripts/ai-issue-respond.sh \
  --issue-number "$ISSUE_NUMBER" \
  --response-type "auto"
```

**Outputs**:
- `issue-context.json`
- `response-comment.md`
- `suggested-labels.txt`

### Script: ai-generate-fixes.sh

**Purpose**: Generate code fixes from analysis results

**Usage**:
```bash
bash .github/scripts/ai-generate-fixes.sh \
  --analysis-file "analysis-results.json" \
  --fix-types "lint,format"
```

**Outputs**:
- `fixes.json` - Structured fixes
- `fix-patches/` - Individual patch files
- `fix-summary.md`

### Script: extract-pr-context.sh

**Purpose**: Extract comprehensive PR context for AI processing

**Usage**:
```bash
bash .github/scripts/extract-pr-context.sh "$PR_NUMBER" pr-context.json
```

**Output Schema**:
```json
{
  "task": "pr-review",
  "context": {
    "repository": "org/repo",
    "pr_number": 123,
    "title": "...",
    "description": "...",
    "diff": "...",
    "files_changed": [...],
    "metadata": {...}
  },
  "config": {
    "model": "gpt-4",
    "temperature": 0.3,
    "max_tokens": 2000
  }
}
```

### Script: validate-schema.sh

**Purpose**: Validate JSON against schema

**Usage**:
```bash
bash .github/scripts/validate-schema.sh \
  --schema ".github/schemas/ai-request-schema.json" \
  --data "request.json"
```

### Script: notify-error.sh

**Purpose**: Send error notifications

**Usage**:
```bash
bash .github/scripts/notify-error.sh \
  --workflow "$WORKFLOW_NAME" \
  --error "$ERROR_MESSAGE" \
  --run-url "$RUN_URL"
```

---

## Configuration Examples

### Example 1: Basic PR Review Setup

```yaml
# .github/workflows/ai-pr-review.yml
name: AI PR Review

on:
  pull_request:
    types: [opened, synchronize, reopened]
    branches: [main]

jobs:
  ai-review:
    runs-on: [self-hosted, linux, ai-agent]
    permissions:
      contents: read
      pull-requests: write

    steps:
      - uses: ./.github/actions/setup-ai-agent
        with:
          sparse-checkout: 'true'
          checkout-paths: |
            .github/
            src/

      - name: Run AI Review
        run: bash .github/scripts/ai-pr-review.sh
        env:
          AI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
          AI_MODEL: gpt-4
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Example 2: Multi-Workflow Setup with Reusable Pattern

```yaml
# .github/workflows/ai-workflows.yml
name: AI Workflows

on:
  pull_request:
    types: [opened, synchronize, labeled]
  issues:
    types: [opened, labeled]
  issue_comment:
    types: [created]

jobs:
  route-workflow:
    runs-on: ubuntu-latest
    outputs:
      workflow-type: ${{ steps.determine.outputs.type }}
      context-id: ${{ steps.determine.outputs.id }}
    steps:
      - name: Determine Workflow
        id: determine
        run: |
          if [ "${{ github.event_name }}" == "pull_request" ]; then
            echo "type=pr-review" >> $GITHUB_OUTPUT
            echo "id=${{ github.event.pull_request.number }}" >> $GITHUB_OUTPUT
          elif [ "${{ github.event_name }}" == "issues" ]; then
            echo "type=issue-response" >> $GITHUB_OUTPUT
            echo "id=${{ github.event.issue.number }}" >> $GITHUB_OUTPUT
          fi

  execute-workflow:
    needs: route-workflow
    uses: ./.github/workflows/reusable-ai-workflow.yml
    with:
      ai-task: ${{ needs.route-workflow.outputs.workflow-type }}
      context-type: ${{ github.event_name }}
      context-id: ${{ needs.route-workflow.outputs.context-id }}
    secrets:
      ai-api-key: ${{ secrets.AI_API_KEY }}
```

### Example 3: Advanced Configuration with Multiple AI Providers

```yaml
# .github/workflows/multi-provider-review.yml
name: Multi-Provider AI Review

on:
  pull_request:
    types: [opened]

jobs:
  openai-review:
    runs-on: [self-hosted, linux, ai-agent]
    steps:
      - uses: ./.github/actions/setup-ai-agent
      - name: OpenAI Review
        run: bash .github/scripts/ai-pr-review.sh
        env:
          AI_PROVIDER: openai
          AI_MODEL: gpt-4
          AI_API_KEY: ${{ secrets.OPENAI_API_KEY }}

  anthropic-review:
    runs-on: [self-hosted, linux, ai-agent]
    steps:
      - uses: ./.github/actions/setup-ai-agent
      - name: Anthropic Review
        run: bash .github/scripts/ai-pr-review.sh
        env:
          AI_PROVIDER: anthropic
          AI_MODEL: claude-3-opus-20240229
          AI_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}

  aggregate-reviews:
    needs: [openai-review, anthropic-review]
    runs-on: [self-hosted, linux, ai-agent]
    steps:
      - name: Aggregate Results
        run: bash .github/scripts/aggregate-reviews.sh
```

### Example 4: Environment-Specific Configuration

```yaml
# .github/workflows/environment-aware-workflow.yml
name: Environment-Aware Workflow

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    runs-on: [self-hosted, linux, ai-agent]
    environment: ${{ github.base_ref == 'main' && 'production' || 'development' }}
    steps:
      - uses: ./.github/actions/setup-ai-agent

      - name: Configure Environment
        run: |
          if [ "${{ github.base_ref }}" == "main" ]; then
            echo "AI_MODEL=gpt-4" >> $GITHUB_ENV
            echo "AI_TEMPERATURE=0.2" >> $GITHUB_ENV
          else
            echo "AI_MODEL=gpt-3.5-turbo" >> $GITHUB_ENV
            echo "AI_TEMPERATURE=0.5" >> $GITHUB_ENV
          fi

      - name: Run Review
        run: bash .github/scripts/ai-pr-review.sh
        env:
          AI_API_KEY: ${{ secrets.AI_API_KEY }}
```

---

## Best Practices

### 1. Security

**DO**:
- Use secrets for all API keys and tokens
- Scope permissions to minimum required
- Validate all inputs before processing
- Never log secrets or sensitive data

**DON'T**:
- Hardcode credentials
- Use overly broad permissions
- Trust user input without validation

### 2. Performance

**DO**:
- Use sparse checkout when possible
- Cache dependencies and AI responses
- Run independent jobs in parallel
- Set appropriate timeouts

**DON'T**:
- Checkout full repository unless needed
- Make unnecessary API calls
- Run sequential jobs that could be parallel

### 3. Reliability

**DO**:
- Implement retry logic for external APIs
- Handle rate limits gracefully
- Provide fallback strategies
- Log errors comprehensively

**DON'T**:
- Assume external services are always available
- Fail silently without notification
- Retry indefinitely without backoff

### 4. Maintainability

**DO**:
- Use reusable workflows and actions
- Document configuration options
- Version your workflows
- Test changes in development first

**DON'T**:
- Duplicate code across workflows
- Make workflows overly complex
- Skip documentation

---

## Troubleshooting

### Common Issues

**1. Runner Not Picking Up Jobs**
```yaml
# Check runner labels match exactly
runs-on: [self-hosted, linux, ai-agent]  # Correct
runs-on: [self-hosted, ai-agent]         # Missing 'linux'
```

**2. Permission Denied Errors**
```yaml
# Ensure permissions are set
permissions:
  contents: write  # Required for push operations
  pull-requests: write  # Required for PR comments
```

**3. Rate Limit Exceeded**
```bash
# Check rate limit before API calls
bash .github/scripts/check-github-rate-limit.sh

# Implement exponential backoff
bash .github/scripts/exponential-backoff.sh
```

**4. AI API Failures**
```bash
# Enable retry logic
MAX_RETRIES=3
RETRY_DELAY=5

# Use fallback strategies
if ! call_ai_api; then
  use_cached_response
fi
```

---

## Migration Guide

### From GitHub-Hosted to Self-Hosted

**1. Update Runner Labels:**
```yaml
# Before
runs-on: ubuntu-latest

# After
runs-on: [self-hosted, linux, ai-agent]
```

**2. Adjust Checkout Strategy:**
```yaml
# Before (full checkout is fast on GitHub-hosted)
- uses: actions/checkout@v4

# After (sparse checkout for performance)
- uses: actions/checkout@v4
  with:
    sparse-checkout: |
      .github/
      src/
```

**3. Update Cache Paths:**
```yaml
# Before (GitHub-hosted paths)
path: ~/.npm

# After (self-hosted paths, may vary)
path: |
  ~/.npm
  ~/.cache/ai-responses
```

---

## Summary

This document provides comprehensive reference for all workflow templates including:

1. **10+ workflow templates** covering PR review, issue response, code fixes, and more
2. **Reusable composite action** for common setup tasks
3. **Supporting scripts** for AI integration and processing
4. **Configuration examples** for various use cases
5. **Best practices** for security, performance, and reliability
6. **Troubleshooting guide** for common issues

All templates are production-ready and designed for self-hosted Windows + WSL 2.0 environments.
