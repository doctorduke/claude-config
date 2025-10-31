# Workflow Architecture
## Self-Hosted GitHub Actions AI Agent System - Wave 1

---

## Table of Contents
1. [Overview](#overview)
2. [Design Principles](#design-principles)
3. [Core Workflow Patterns](#core-workflow-patterns)
4. [Reusable Components](#reusable-components)
5. [Event Routing Architecture](#event-routing-architecture)
6. [Performance Optimization](#performance-optimization)
7. [Error Handling & Retry Logic](#error-handling--retry-logic)
8. [AI/LLM Integration Patterns](#aillm-integration-patterns)

---

## Overview

### Architecture Goals
The workflow architecture is designed to enable AI/CLI agents to perform automated code reviews, issue management, and code modifications on self-hosted runners running Windows + WSL 2.0.

**Primary Workflows:**
1. **PR Review AI** - Automated pull request analysis and feedback
2. **Issue Auto-Respond** - Intelligent issue comment generation
3. **Code Auto-Fix** - Automated code corrections and improvements

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Events Layer                       │
│  (pull_request, issues, push, workflow_dispatch)            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│               Event Router (Label Matching)                  │
│    Filter: [self-hosted, linux, ai-agent]                   │
└────────────────────┬────────────────────────────────────────┘
                     │
         ┌───────────┴───────────┬──────────────┐
         ▼                       ▼              ▼
┌─────────────────┐   ┌─────────────────┐   ┌──────────────┐
│  PR Review      │   │ Issue Response  │   │  Code Fix    │
│  Workflow       │   │ Workflow        │   │  Workflow    │
└────────┬────────┘   └────────┬────────┘   └──────┬───────┘
         │                     │                    │
         └─────────────────────┴────────────────────┘
                               │
                               ▼
         ┌─────────────────────────────────────────┐
         │    Composite Action: setup-ai-agent     │
         │  - Checkout (sparse)                    │
         │  - Setup GitHub CLI                     │
         │  - Configure AI API                     │
         │  - Setup WSL environment                │
         └──────────────────┬──────────────────────┘
                            │
                            ▼
         ┌─────────────────────────────────────────┐
         │        AI Agent Execution Script        │
         │  - Fetch context from GitHub API        │
         │  - Call AI/LLM service                  │
         │  - Parse and validate response          │
         │  - Execute action (comment/commit)      │
         └─────────────────────────────────────────┘
```

---

## Design Principles

### 1. Reusability First
- **Reusable Workflows** using `workflow_call` for common patterns
- **Composite Actions** for repeated setup tasks
- **Shared Scripts** in centralized repository locations
- Target: 80% code reuse across repositories

### 2. Event-Driven Architecture
- Workflows triggered by GitHub webhook events
- Conditional execution based on event payloads
- Label-based routing for workflow selection
- Decoupled components for flexibility

### 3. Idempotency
- All workflows can be safely re-run
- Operations check current state before modifying
- Avoid duplicate comments/commits
- State validation before and after actions

### 4. Performance Optimization
- **Sparse Checkout**: Only fetch required files
- **Parallel Execution**: Independent jobs run concurrently
- **Caching**: Dependencies, build artifacts, AI responses
- **Conditional Steps**: Skip unnecessary work
- Target: < 30 second job startup, < 10 minute total execution

### 5. Cross-Platform Compatibility
- Bash scripts executed in WSL for Linux compatibility
- PowerShell for Windows-specific tasks
- Path handling using `${{ runner.os }}` conditionals
- Test on all target platforms (Windows+WSL, Linux, macOS)

### 6. Security by Default
- Minimal GITHUB_TOKEN permissions (scoped per workflow)
- PAT with limited scope for protected branch operations
- No secrets in logs or outputs
- Secret injection via environment variables only
- Audit logging for all privileged actions

---

## Core Workflow Patterns

### Pattern 1: PR Review AI Workflow

**Trigger Events:**
- `pull_request` types: `[opened, synchronize, reopened]`
- `pull_request_review` types: `[submitted]` (for re-reviews)

**Workflow Structure:**
```yaml
name: AI PR Review
on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  ai-review:
    runs-on: [self-hosted, linux, ai-agent]
    permissions:
      contents: read           # Read PR diff
      pull-requests: write     # Post review comments

    steps:
      - name: Setup AI Agent Environment
        uses: ./.github/actions/setup-ai-agent
        with:
          sparse-checkout: 'true'
          checkout-paths: |
            .github/
            src/

      - name: Fetch PR Context
        id: pr-context
        run: |
          gh pr view ${{ github.event.pull_request.number }} \
            --json title,body,diff,files > pr-context.json
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: AI Analysis
        id: ai-review
        run: bash .github/scripts/ai-pr-review.sh
        env:
          AI_API_KEY: ${{ secrets.AI_API_KEY }}
          PR_CONTEXT_FILE: pr-context.json

      - name: Post Review Comments
        if: steps.ai-review.outputs.has-feedback == 'true'
        run: |
          gh pr review ${{ github.event.pull_request.number }} \
            --comment-body "$(cat review-comments.md)"
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Handle Errors
        if: failure()
        run: bash .github/scripts/notify-error.sh
        env:
          WORKFLOW_NAME: ${{ github.workflow }}
          RUN_URL: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
```

**Key Features:**
- Sparse checkout for performance
- Structured JSON context passed to AI
- Conditional comment posting
- Error notification on failure

### Pattern 2: Issue Auto-Respond Workflow

**Trigger Events:**
- `issues` types: `[opened, labeled]`
- `issue_comment` types: `[created]` (when mentioned)

**Workflow Structure:**
```yaml
name: AI Issue Response
on:
  issues:
    types: [opened, labeled]
  issue_comment:
    types: [created]

jobs:
  auto-respond:
    runs-on: [self-hosted, linux, ai-agent]
    # Only run if specific label present or bot is mentioned
    if: |
      contains(github.event.issue.labels.*.name, 'ai-assist') ||
      contains(github.event.comment.body, '@ai-assistant')

    permissions:
      issues: write            # Post comments
      contents: read           # Read repo context

    steps:
      - uses: ./.github/actions/setup-ai-agent
        with:
          sparse-checkout: 'true'
          checkout-paths: |
            .github/
            docs/

      - name: Fetch Issue Context
        id: issue-context
        run: |
          gh issue view ${{ github.event.issue.number }} \
            --json title,body,labels,comments > issue-context.json
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Generate AI Response
        id: ai-response
        run: bash .github/scripts/ai-issue-respond.sh
        env:
          AI_API_KEY: ${{ secrets.AI_API_KEY }}
          ISSUE_CONTEXT_FILE: issue-context.json

      - name: Post Comment
        if: steps.ai-response.outputs.has-response == 'true'
        run: |
          gh issue comment ${{ github.event.issue.number }} \
            --body "$(cat response-comment.md)"
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**Key Features:**
- Conditional execution based on labels or mentions
- Context-aware responses using issue history
- Markdown formatted responses
- Rate limit handling for AI API

### Pattern 3: Code Auto-Fix Workflow

**Trigger Events:**
- `pull_request` types: `[labeled]` with `auto-fix` label
- `issue_comment` types: `[created]` with `/fix` command
- `workflow_dispatch` for manual triggers

**Workflow Structure:**
```yaml
name: AI Code Auto-Fix
on:
  pull_request:
    types: [labeled]
  issue_comment:
    types: [created]
  workflow_dispatch:
    inputs:
      pr_number:
        description: 'PR number to fix'
        required: true
      fix_type:
        description: 'Type of fix (lint, format, security)'
        required: false
        default: 'lint'

jobs:
  auto-fix:
    runs-on: [self-hosted, linux, ai-agent]
    if: |
      (github.event_name == 'pull_request' && contains(github.event.label.name, 'auto-fix')) ||
      (github.event_name == 'issue_comment' && contains(github.event.comment.body, '/fix'))

    permissions:
      contents: write          # Push fixes to branch
      pull-requests: write     # Update PR

    steps:
      - uses: ./.github/actions/setup-ai-agent
        with:
          sparse-checkout: 'false'  # Need full checkout for fixes
          ref: ${{ github.event.pull_request.head.ref }}

      - name: Run Linters/Analysis
        id: analysis
        run: bash .github/scripts/analyze-code.sh
        env:
          FIX_TYPE: ${{ github.event.inputs.fix_type || 'lint' }}

      - name: AI Generate Fixes
        if: steps.analysis.outputs.issues-found == 'true'
        id: ai-fix
        run: bash .github/scripts/ai-generate-fixes.sh
        env:
          AI_API_KEY: ${{ secrets.AI_API_KEY }}
          ANALYSIS_FILE: analysis-results.json

      - name: Apply Fixes and Commit
        if: steps.ai-fix.outputs.fixes-generated == 'true'
        run: |
          git config user.name "AI Agent"
          git config user.email "ai-agent@github.com"

          # Apply fixes
          bash .github/scripts/apply-fixes.sh

          # Commit and push
          git add .
          git commit -m "chore: AI auto-fix - ${{ steps.ai-fix.outputs.fix-summary }}"
          git push
        env:
          # Use PAT for pushing to protected branches
          GH_TOKEN: ${{ secrets.AI_AGENT_PAT }}

      - name: Comment on PR
        if: steps.ai-fix.outputs.fixes-generated == 'true'
        run: |
          gh pr comment ${{ github.event.pull_request.number }} \
            --body "$(cat fix-summary.md)"
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**Key Features:**
- Multiple trigger mechanisms
- Full checkout for code modifications
- AI-generated fix application
- Automated commit and push
- PAT usage for protected branch access
- Summary comment with fix details

---

## Reusable Components

### Reusable Workflow Pattern

**File:** `.github/workflows/reusable-ai-workflow.yml`

```yaml
name: Reusable AI Workflow
on:
  workflow_call:
    inputs:
      ai-task:
        description: 'AI task to perform (review, respond, fix)'
        required: true
        type: string
      context-type:
        description: 'Context type (pr, issue, commit)'
        required: true
        type: string
      context-id:
        description: 'PR number, issue number, or commit SHA'
        required: true
        type: string
      sparse-checkout:
        description: 'Enable sparse checkout'
        required: false
        type: boolean
        default: true
    secrets:
      ai-api-key:
        required: true
      ai-agent-pat:
        required: false
    outputs:
      task-completed:
        description: 'Whether task completed successfully'
        value: ${{ jobs.ai-task.outputs.completed }}
      result-summary:
        description: 'Summary of task execution'
        value: ${{ jobs.ai-task.outputs.summary }}

jobs:
  ai-task:
    runs-on: [self-hosted, linux, ai-agent]
    outputs:
      completed: ${{ steps.execute.outputs.completed }}
      summary: ${{ steps.execute.outputs.summary }}

    steps:
      - uses: ./.github/actions/setup-ai-agent
        with:
          sparse-checkout: ${{ inputs.sparse-checkout }}

      - name: Execute AI Task
        id: execute
        run: |
          bash .github/scripts/ai-task-dispatcher.sh \
            --task "${{ inputs.ai-task }}" \
            --context-type "${{ inputs.context-type }}" \
            --context-id "${{ inputs.context-id }}"
        env:
          AI_API_KEY: ${{ secrets.ai-api-key }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          AI_AGENT_PAT: ${{ secrets.ai-agent-pat }}
```

**Usage Example:**
```yaml
jobs:
  call-ai-review:
    uses: ./.github/workflows/reusable-ai-workflow.yml
    with:
      ai-task: 'review'
      context-type: 'pr'
      context-id: ${{ github.event.pull_request.number }}
    secrets:
      ai-api-key: ${{ secrets.AI_API_KEY }}
```

### Composite Action: setup-ai-agent

**File:** `.github/actions/setup-ai-agent/action.yml`

```yaml
name: 'Setup AI Agent Environment'
description: 'Common setup for AI agent workflows'
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

runs:
  using: 'composite'
  steps:
    - name: Sparse Checkout Repository
      if: inputs.sparse-checkout == 'true'
      uses: actions/checkout@v4
      with:
        sparse-checkout: ${{ inputs.checkout-paths }}
        sparse-checkout-cone-mode: false
        ref: ${{ inputs.ref || github.ref }}

    - name: Full Checkout Repository
      if: inputs.sparse-checkout != 'true'
      uses: actions/checkout@v4
      with:
        ref: ${{ inputs.ref || github.ref }}

    - name: Setup GitHub CLI
      shell: bash
      run: |
        # Verify gh CLI is installed
        if ! command -v gh &> /dev/null; then
          echo "Installing GitHub CLI..."
          curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
            sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
          echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
            sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
          sudo apt update
          sudo apt install gh -y
        fi

        # Verify authentication
        gh auth status

    - name: Setup WSL Environment (if Windows)
      if: runner.os == 'Windows'
      shell: pwsh
      run: |
        # Ensure WSL is configured
        wsl --set-default-version 2
        wsl --status

    - name: Cache AI Dependencies
      uses: actions/cache@v3
      with:
        path: |
          ~/.cache/ai-models
          .github/scripts/node_modules
        key: ai-deps-${{ runner.os }}-${{ hashFiles('.github/scripts/package-lock.json') }}
        restore-keys: |
          ai-deps-${{ runner.os }}-

    - name: Validate Environment
      shell: bash
      run: |
        echo "Environment Setup Complete"
        echo "Runner OS: ${{ runner.os }}"
        echo "GitHub SHA: ${{ github.sha }}"
        echo "Workspace: ${{ github.workspace }}"
```

---

## Event Routing Architecture

### Label-Based Routing

**Runner Labels:** `[self-hosted, linux, ai-agent]`

- **self-hosted**: Directs to organization's runners (not GitHub-hosted)
- **linux**: Indicates Linux environment (WSL on Windows)
- **ai-agent**: Specific pool for AI-enabled workflows

**Workflow Selection Logic:**
```yaml
jobs:
  route-workflow:
    runs-on: [self-hosted, linux, ai-agent]
    steps:
      - name: Determine Workflow Type
        id: routing
        run: |
          EVENT_TYPE="${{ github.event_name }}"

          case $EVENT_TYPE in
            pull_request)
              echo "workflow=pr-review" >> $GITHUB_OUTPUT
              ;;
            issues|issue_comment)
              echo "workflow=issue-respond" >> $GITHUB_OUTPUT
              ;;
            push)
              echo "workflow=code-check" >> $GITHUB_OUTPUT
              ;;
            *)
              echo "workflow=default" >> $GITHUB_OUTPUT
              ;;
          esac
```

### Event Filtering Patterns

**1. PR-Specific Events:**
```yaml
on:
  pull_request:
    types: [opened, synchronize, reopened]
    branches: [main, develop]  # Only for important branches
    paths:
      - 'src/**'               # Only when source code changes
      - '!docs/**'             # Ignore documentation
```

**2. Issue-Specific Events:**
```yaml
on:
  issues:
    types: [opened, labeled]
  issue_comment:
    types: [created]

jobs:
  filter-issues:
    if: |
      (github.event_name == 'issues' && contains(github.event.issue.labels.*.name, 'ai-assist')) ||
      (github.event_name == 'issue_comment' && contains(github.event.comment.body, '@ai-assistant'))
```

**3. Command-Based Triggers:**
```yaml
on:
  issue_comment:
    types: [created]

jobs:
  parse-command:
    if: startsWith(github.event.comment.body, '/')
    steps:
      - name: Parse Command
        run: |
          COMMAND=$(echo "${{ github.event.comment.body }}" | head -n1)

          case $COMMAND in
            "/review")
              echo "action=review" >> $GITHUB_OUTPUT
              ;;
            "/fix")
              echo "action=fix" >> $GITHUB_OUTPUT
              ;;
            "/explain")
              echo "action=explain" >> $GITHUB_OUTPUT
              ;;
          esac
```

---

## Performance Optimization

### 1. Sparse Checkout Strategy

**Benefits:**
- Reduces checkout time by 60-80%
- Minimizes disk I/O
- Faster workspace initialization

**Implementation:**
```yaml
- uses: actions/checkout@v4
  with:
    sparse-checkout: |
      .github/
      src/
      package.json
    sparse-checkout-cone-mode: false
```

**Cone Mode vs Non-Cone:**
- **Cone Mode (default)**: Faster but less flexible, entire directories
- **Non-Cone Mode**: Granular file selection, slower initial setup

### 2. Parallel Job Execution

**Pattern:**
```yaml
jobs:
  analyze-code:
    runs-on: [self-hosted, linux, ai-agent]
    strategy:
      matrix:
        check-type: [lint, security, performance, style]
      max-parallel: 4
      fail-fast: false

    steps:
      - uses: ./.github/actions/setup-ai-agent
      - name: Run Check
        run: bash .github/scripts/check-${{ matrix.check-type }}.sh
```

### 3. Caching Strategies

**A. Dependency Caching:**
```yaml
- uses: actions/cache@v3
  with:
    path: |
      ~/.npm
      ~/.cache/pip
      ~/.cargo/registry
    key: deps-${{ runner.os }}-${{ hashFiles('**/package-lock.json', '**/requirements.txt', '**/Cargo.lock') }}
```

**B. AI Model/Response Caching:**
```yaml
- name: Cache AI Responses
  uses: actions/cache@v3
  with:
    path: ~/.cache/ai-responses
    key: ai-cache-${{ github.sha }}-${{ hashFiles('src/**') }}
    restore-keys: |
      ai-cache-${{ github.sha }}-
      ai-cache-
```

**C. Build Artifact Caching:**
```yaml
- uses: actions/cache@v3
  with:
    path: |
      dist/
      build/
    key: build-${{ runner.os }}-${{ github.sha }}
```

### 4. Conditional Step Execution

```yaml
- name: Complex Analysis
  if: |
    github.event_name == 'pull_request' &&
    contains(github.event.pull_request.labels.*.name, 'needs-review') &&
    github.event.pull_request.changed_files > 5
  run: bash .github/scripts/deep-analysis.sh
```

---

## Error Handling & Retry Logic

### 1. Graceful Failure Handling

**Workflow Level:**
```yaml
jobs:
  ai-review:
    continue-on-error: true  # Don't fail entire workflow
    steps:
      - name: Risky Operation
        id: risky
        continue-on-error: true
        run: bash .github/scripts/may-fail.sh

      - name: Handle Failure
        if: failure() && steps.risky.outcome == 'failure'
        run: |
          echo "Operation failed, sending notification..."
          bash .github/scripts/notify-error.sh
```

### 2. Retry Pattern for External APIs

**AI API Retry Logic:**
```bash
#!/bin/bash
# .github/scripts/ai-api-call-with-retry.sh

MAX_RETRIES=3
RETRY_DELAY=5

for i in $(seq 1 $MAX_RETRIES); do
  echo "Attempt $i of $MAX_RETRIES..."

  if curl -X POST "$AI_API_URL" \
       -H "Authorization: Bearer $AI_API_KEY" \
       -d "@request.json" \
       -o response.json \
       --fail --silent --show-error; then
    echo "Success!"
    exit 0
  fi

  if [ $i -lt $MAX_RETRIES ]; then
    echo "Failed, retrying in ${RETRY_DELAY}s..."
    sleep $RETRY_DELAY
    RETRY_DELAY=$((RETRY_DELAY * 2))  # Exponential backoff
  fi
done

echo "All retries failed"
exit 1
```

### 3. Rate Limit Handling

**GitHub API Rate Limit Check:**
```yaml
- name: Check GitHub API Rate Limit
  id: rate-limit
  run: |
    REMAINING=$(gh api rate_limit --jq '.rate.remaining')
    echo "remaining=$REMAINING" >> $GITHUB_OUTPUT

    if [ $REMAINING -lt 100 ]; then
      echo "⚠️ Low rate limit: $REMAINING remaining"
      RESET_TIME=$(gh api rate_limit --jq '.rate.reset')
      WAIT_SECONDS=$((RESET_TIME - $(date +%s)))
      echo "wait_seconds=$WAIT_SECONDS" >> $GITHUB_OUTPUT
      exit 1
    fi
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

- name: Wait for Rate Limit Reset
  if: failure() && steps.rate-limit.outputs.wait_seconds != ''
  run: |
    echo "Waiting for rate limit reset..."
    sleep ${{ steps.rate-limit.outputs.wait_seconds }}
```

**AI API Rate Limit:**
```bash
# Check rate limit from response headers
RATE_REMAINING=$(curl -I "$AI_API_URL" -H "Authorization: Bearer $AI_API_KEY" | \
                 grep -i "x-ratelimit-remaining" | \
                 awk '{print $2}' | tr -d '\r')

if [ "$RATE_REMAINING" -lt 5 ]; then
  RATE_RESET=$(curl -I "$AI_API_URL" -H "Authorization: Bearer $AI_API_KEY" | \
               grep -i "x-ratelimit-reset" | \
               awk '{print $2}' | tr -d '\r')
  WAIT_TIME=$((RATE_RESET - $(date +%s)))
  echo "Rate limit low, waiting ${WAIT_TIME}s..."
  sleep $WAIT_TIME
fi
```

### 4. Timeout Configuration

```yaml
jobs:
  ai-task:
    timeout-minutes: 15  # Workflow-level timeout
    steps:
      - name: AI Analysis
        timeout-minutes: 10  # Step-level timeout
        run: bash .github/scripts/ai-analyze.sh
```

---

## AI/LLM Integration Patterns

### 1. Request/Response Schema

**AI Request Schema (JSON):**
```json
{
  "task": "pr-review",
  "context": {
    "repository": "org/repo",
    "pr_number": 123,
    "title": "Add new feature",
    "description": "This PR implements...",
    "diff": "diff --git a/src/file.js...",
    "files_changed": [
      {
        "filename": "src/file.js",
        "status": "modified",
        "additions": 15,
        "deletions": 3,
        "patch": "@@ -10,7 +10,19 @@..."
      }
    ],
    "metadata": {
      "author": "user",
      "created_at": "2024-01-01T00:00:00Z",
      "base_branch": "main",
      "head_branch": "feature/new-thing"
    }
  },
  "config": {
    "model": "gpt-4",
    "temperature": 0.3,
    "max_tokens": 2000,
    "focus_areas": ["code-quality", "security", "performance"]
  }
}
```

**AI Response Schema (JSON):**
```json
{
  "status": "success",
  "task": "pr-review",
  "result": {
    "summary": "Overall assessment of the PR",
    "score": 85,
    "comments": [
      {
        "file": "src/file.js",
        "line": 42,
        "severity": "warning",
        "category": "security",
        "message": "Potential SQL injection vulnerability",
        "suggestion": "Use parameterized queries instead"
      }
    ],
    "recommendations": [
      "Add unit tests for new functionality",
      "Update documentation"
    ]
  },
  "metadata": {
    "model_used": "gpt-4",
    "tokens_used": 1500,
    "processing_time_ms": 3200,
    "timestamp": "2024-01-01T00:00:00Z"
  }
}
```

### 2. Context Extraction Pattern

**Script: `.github/scripts/extract-pr-context.sh`**
```bash
#!/bin/bash
set -euo pipefail

PR_NUMBER="${1}"
OUTPUT_FILE="${2:-pr-context.json}"

# Fetch PR details
PR_DATA=$(gh pr view "$PR_NUMBER" --json \
  number,title,body,state,author,createdAt,updatedAt,\
  baseRefName,headRefName,mergeable,additions,deletions,\
  changedFiles,labels,reviewDecision)

# Fetch PR diff
PR_DIFF=$(gh pr diff "$PR_NUMBER")

# Fetch file changes
FILES_CHANGED=$(gh pr view "$PR_NUMBER" --json files --jq '.files')

# Fetch existing comments
PR_COMMENTS=$(gh pr view "$PR_NUMBER" --json comments --jq '.comments')

# Combine into context object
jq -n \
  --argjson pr "$PR_DATA" \
  --arg diff "$PR_DIFF" \
  --argjson files "$FILES_CHANGED" \
  --argjson comments "$PR_COMMENTS" \
  '{
    task: "pr-review",
    context: {
      repository: $ENV.GITHUB_REPOSITORY,
      pr_number: $pr.number,
      title: $pr.title,
      description: $pr.body,
      diff: $diff,
      files_changed: $files,
      existing_comments: $comments,
      metadata: {
        author: $pr.author.login,
        created_at: $pr.createdAt,
        updated_at: $pr.updatedAt,
        base_branch: $pr.baseRefName,
        head_branch: $pr.headRefName,
        mergeable: $pr.mergeable,
        additions: $pr.additions,
        deletions: $pr.deletions,
        changed_files: $pr.changedFiles,
        labels: $pr.labels,
        review_decision: $pr.reviewDecision
      }
    },
    config: {
      model: $ENV.AI_MODEL,
      temperature: 0.3,
      max_tokens: 2000,
      focus_areas: ["code-quality", "security", "performance", "best-practices"]
    }
  }' > "$OUTPUT_FILE"

echo "Context extracted to $OUTPUT_FILE"
```

### 3. AI Response Processing

**Script: `.github/scripts/process-ai-response.sh`**
```bash
#!/bin/bash
set -euo pipefail

RESPONSE_FILE="${1}"
PR_NUMBER="${2}"

# Validate response
if ! jq -e '.status == "success"' "$RESPONSE_FILE" > /dev/null; then
  echo "AI request failed"
  jq -r '.error.message' "$RESPONSE_FILE"
  exit 1
fi

# Extract comments
COMMENT_COUNT=$(jq '.result.comments | length' "$RESPONSE_FILE")
echo "Found $COMMENT_COUNT review comments"

# Generate review comment body
jq -r '
  "## AI Code Review\n\n" +
  "**Summary:** " + .result.summary + "\n\n" +
  "**Score:** " + (.result.score | tostring) + "/100\n\n" +
  if (.result.comments | length) > 0 then
    "### Issues Found\n\n" +
    (.result.comments | map(
      "- **" + .file + ":" + (.line | tostring) + "** (" + .severity + ")\n" +
      "  " + .message + "\n" +
      if .suggestion then "  *Suggestion:* " + .suggestion + "\n" else "" end
    ) | join("\n"))
  else
    "No issues found! ✅\n"
  end +
  "\n### Recommendations\n\n" +
  (.result.recommendations | map("- " + .) | join("\n"))
' "$RESPONSE_FILE" > review-comment.md

# Post inline comments
jq -c '.result.comments[]' "$RESPONSE_FILE" | while read -r comment; do
  FILE=$(echo "$comment" | jq -r '.file')
  LINE=$(echo "$comment" | jq -r '.line')
  BODY=$(echo "$comment" | jq -r '.message + "\n\n*Suggestion:* " + .suggestion')

  gh pr comment "$PR_NUMBER" \
    --body "$BODY" \
    --file "$FILE" \
    --line "$LINE" || echo "Failed to post inline comment"
done

# Set output
echo "has-feedback=true" >> $GITHUB_OUTPUT
echo "comment-count=$COMMENT_COUNT" >> $GITHUB_OUTPUT
```

### 4. Error Response Handling

```bash
#!/bin/bash
# Handle AI API errors gracefully

if ! AI_RESPONSE=$(curl -X POST "$AI_API_URL" \
     -H "Authorization: Bearer $AI_API_KEY" \
     -d "@request.json" \
     --fail --silent --show-error 2>&1); then

  # Check error type
  HTTP_CODE=$(echo "$AI_RESPONSE" | grep -oP 'HTTP/\d\.\d \K\d+' || echo "000")

  case $HTTP_CODE in
    401|403)
      echo "Authentication error: Check AI_API_KEY"
      echo "error=auth" >> $GITHUB_OUTPUT
      ;;
    429)
      echo "Rate limit exceeded"
      echo "error=rate-limit" >> $GITHUB_OUTPUT
      ;;
    500|502|503)
      echo "AI service unavailable"
      echo "error=service-unavailable" >> $GITHUB_OUTPUT
      ;;
    *)
      echo "Unknown error: $AI_RESPONSE"
      echo "error=unknown" >> $GITHUB_OUTPUT
      ;;
  esac

  # Post fallback comment
  gh pr comment "$PR_NUMBER" \
    --body "❌ AI review failed: $HTTP_CODE. A human review may be needed."

  exit 1
fi
```

---

## Job Composition Strategies

### 1. Sequential Dependencies

```yaml
jobs:
  analyze:
    runs-on: [self-hosted, linux, ai-agent]
    outputs:
      needs-review: ${{ steps.check.outputs.needs-review }}
    steps:
      - id: check
        run: |
          # Determine if review is needed
          if [ ${{ github.event.pull_request.changed_files }} -gt 10 ]; then
            echo "needs-review=true" >> $GITHUB_OUTPUT
          else
            echo "needs-review=false" >> $GITHUB_OUTPUT
          fi

  ai-review:
    needs: analyze
    if: needs.analyze.outputs.needs-review == 'true'
    runs-on: [self-hosted, linux, ai-agent]
    steps:
      - run: bash .github/scripts/ai-pr-review.sh

  notify:
    needs: [analyze, ai-review]
    if: always()
    runs-on: [self-hosted, linux, ai-agent]
    steps:
      - run: bash .github/scripts/send-notification.sh
```

### 2. Parallel Independent Jobs

```yaml
jobs:
  lint:
    runs-on: [self-hosted, linux, ai-agent]
    steps:
      - run: npm run lint

  security-scan:
    runs-on: [self-hosted, linux, ai-agent]
    steps:
      - run: npm audit

  type-check:
    runs-on: [self-hosted, linux, ai-agent]
    steps:
      - run: npm run type-check

  # All run in parallel, aggregate results
  aggregate:
    needs: [lint, security-scan, type-check]
    if: always()
    runs-on: [self-hosted, linux, ai-agent]
    steps:
      - run: bash .github/scripts/aggregate-results.sh
```

---

## Permission Scoping

### Minimal GITHUB_TOKEN Permissions

**PR Review Workflow:**
```yaml
permissions:
  contents: read           # Read repository code
  pull-requests: write     # Comment on PRs
  issues: read             # Read linked issues
```

**Issue Response Workflow:**
```yaml
permissions:
  issues: write            # Comment on issues
  contents: read           # Read repository context
```

**Code Auto-Fix Workflow:**
```yaml
permissions:
  contents: write          # Push commits (non-protected branches)
  pull-requests: write     # Update PR
```

### PAT for Protected Branches

**When to Use PAT:**
- Pushing to protected branches
- Bypassing branch protection rules
- Creating releases
- Managing workflow files

**PAT Scope Configuration:**
```yaml
env:
  # Regular operations
  GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  # Protected branch operations
  GH_PAT: ${{ secrets.AI_AGENT_PAT }}
```

**PAT Security:**
- Store as organization or repository secret
- Minimum scope: `repo` or `public_repo`
- Enable expiration (90 days recommended)
- Audit usage regularly
- Rotate on security events

---

## Matrix Build Optimization

### Cross-Platform Testing

```yaml
jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        node: [16, 18, 20]
        exclude:
          - os: macos-latest
            node: 16  # Drop unsupported combinations
      fail-fast: false  # Continue even if one fails
      max-parallel: 6   # Limit concurrent jobs

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v3
        with:
          node-version: ${{ matrix.node }}
      - run: npm test
```

### Dynamic Matrix Generation

```yaml
jobs:
  generate-matrix:
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.set-matrix.outputs.matrix }}
    steps:
      - id: set-matrix
        run: |
          # Generate matrix based on changed files
          MATRIX=$(jq -n '{
            include: [
              {file: "service-a", test: "unit"},
              {file: "service-b", test: "integration"}
            ]
          }')
          echo "matrix=$MATRIX" >> $GITHUB_OUTPUT

  test:
    needs: generate-matrix
    strategy:
      matrix: ${{ fromJson(needs.generate-matrix.outputs.matrix) }}
    steps:
      - run: test-${{ matrix.file }}-${{ matrix.test }}
```

---

## Summary

This workflow architecture provides:

1. **Three core workflows** for PR review, issue response, and code auto-fix
2. **Reusable patterns** via workflow_call and composite actions
3. **Event-driven routing** using runner labels
4. **Performance optimization** through sparse checkout and caching
5. **Robust error handling** with retries and graceful degradation
6. **Secure permission scoping** with minimal GITHUB_TOKEN and PAT strategy
7. **Structured AI integration** with JSON schemas and validation

**Next Steps:**
- Review integration architecture for API details
- Examine event flow diagrams for routing logic
- Explore workflow templates for implementation examples
