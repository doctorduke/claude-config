# Integration Architecture
## Self-Hosted GitHub Actions AI Agent System - Wave 1

---

## Table of Contents
1. [Overview](#overview)
2. [GitHub API Integration](#github-api-integration)
3. [AI/LLM Service Integration](#aillm-service-integration)
4. [Git Operations Integration](#git-operations-integration)
5. [Integration Contracts & Schemas](#integration-contracts--schemas)
6. [Rate Limiting & Throttling](#rate-limiting--throttling)
7. [Authentication & Authorization](#authentication--authorization)
8. [Error Handling & Circuit Breakers](#error-handling--circuit-breakers)

---

## Overview

### Integration Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     GitHub Actions Workflow                      │
│                    (Self-Hosted Runner)                          │
└───────────┬─────────────────────────────────┬───────────────────┘
            │                                 │
            │                                 │
    ┌───────▼────────┐                ┌──────▼──────┐
    │   GitHub API   │                │   Git CLI   │
    │   Integration  │                │ Integration │
    │                │                │             │
    │  - REST API    │                │ - Clone     │
    │  - GraphQL     │                │ - Commit    │
    │  - GitHub CLI  │                │ - Push      │
    └───────┬────────┘                └──────┬──────┘
            │                                │
            │                                │
    ┌───────▼────────────────────────────────▼──────┐
    │           AI Agent Scripts (Bash)             │
    │                                                │
    │  - Context Extraction                         │
    │  - Request Formatting                         │
    │  - Response Processing                        │
    │  - Action Execution                           │
    └────────────────────┬──────────────────────────┘
                         │
                         │
                  ┌──────▼──────┐
                  │  AI/LLM API │
                  │             │
                  │ - OpenAI    │
                  │ - Anthropic │
                  │ - Custom    │
                  └─────────────┘
```

### Integration Principles

1. **Loose Coupling**: Services communicate via well-defined contracts
2. **Fault Tolerance**: Graceful degradation on external service failures
3. **Observability**: Comprehensive logging and monitoring
4. **Security**: End-to-end encryption, credential isolation
5. **Performance**: Caching, batching, parallel requests

---

## GitHub API Integration

### API Endpoints Used

#### REST API v3 Endpoints

**Pull Request Operations:**
```
GET  /repos/{owner}/{repo}/pulls/{pull_number}
GET  /repos/{owner}/{repo}/pulls/{pull_number}/files
GET  /repos/{owner}/{repo}/pulls/{pull_number}/comments
POST /repos/{owner}/{repo}/pulls/{pull_number}/comments
POST /repos/{owner}/{repo}/pulls/{pull_number}/reviews
GET  /repos/{owner}/{repo}/pulls/{pull_number}/reviews
PATCH /repos/{owner}/{repo}/pulls/{pull_number}
```

**Issue Operations:**
```
GET  /repos/{owner}/{repo}/issues/{issue_number}
GET  /repos/{owner}/{repo}/issues/{issue_number}/comments
POST /repos/{owner}/{repo}/issues/{issue_number}/comments
PATCH /repos/{owner}/{repo}/issues/{issue_number}
POST /repos/{owner}/{repo}/issues/{issue_number}/labels
```

**Repository Operations:**
```
GET  /repos/{owner}/{repo}
GET  /repos/{owner}/{repo}/contents/{path}
GET  /repos/{owner}/{repo}/commits/{ref}
POST /repos/{owner}/{repo}/git/refs
POST /repos/{owner}/{repo}/git/blobs
POST /repos/{owner}/{repo}/git/trees
POST /repos/{owner}/{repo}/git/commits
```

**Rate Limit Monitoring:**
```
GET  /rate_limit
```

#### GraphQL API Queries

**Comprehensive PR Query:**
```graphql
query GetPullRequest($owner: String!, $name: String!, $number: Int!) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      id
      title
      body
      state
      number
      createdAt
      updatedAt
      mergeable
      additions
      deletions
      changedFiles

      author {
        login
        avatarUrl
      }

      baseRef {
        name
        target {
          oid
        }
      }

      headRef {
        name
        target {
          oid
        }
      }

      files(first: 100) {
        nodes {
          path
          additions
          deletions
        }
      }

      comments(first: 50) {
        nodes {
          id
          body
          createdAt
          author {
            login
          }
        }
      }

      reviews(first: 50) {
        nodes {
          id
          state
          body
          createdAt
          author {
            login
          }
        }
      }

      labels(first: 20) {
        nodes {
          name
          color
        }
      }
    }
  }

  rateLimit {
    remaining
    resetAt
  }
}
```

**Issue Query:**
```graphql
query GetIssue($owner: String!, $name: String!, $number: Int!) {
  repository(owner: $owner, name: $name) {
    issue(number: $number) {
      id
      title
      body
      state
      number
      createdAt
      updatedAt

      author {
        login
      }

      comments(first: 100) {
        nodes {
          id
          body
          createdAt
          author {
            login
          }
        }
      }

      labels(first: 20) {
        nodes {
          name
          color
        }
      }
    }
  }
}
```

### GitHub CLI Integration

**Authentication:**
```bash
# Workflow sets GH_TOKEN automatically
export GH_TOKEN="${{ secrets.GITHUB_TOKEN }}"

# Verify authentication
gh auth status

# Use PAT for elevated permissions
export GH_TOKEN="${{ secrets.AI_AGENT_PAT }}"
```

**Common Operations:**

**1. Fetch PR Details:**
```bash
#!/bin/bash
# Fetch PR with all context
gh pr view "$PR_NUMBER" \
  --json number,title,body,state,author,createdAt,updatedAt,\
           baseRefName,headRefName,mergeable,additions,deletions,\
           changedFiles,labels,reviewDecision,reviews,comments \
  > pr-details.json

# Fetch PR diff
gh pr diff "$PR_NUMBER" > pr-diff.patch

# Fetch specific files
gh pr view "$PR_NUMBER" --json files \
  --jq '.files[] | select(.path | endswith(".js"))' > js-files.json
```

**2. Comment Operations:**
```bash
# Post PR comment
gh pr comment "$PR_NUMBER" --body "$(cat comment.md)"

# Post inline review comment
gh pr review "$PR_NUMBER" \
  --comment \
  --body "$(cat review.md)"

# Request changes
gh pr review "$PR_NUMBER" \
  --request-changes \
  --body "$(cat requested-changes.md)"

# Approve PR
gh pr review "$PR_NUMBER" \
  --approve \
  --body "LGTM! ✅"
```

**3. Issue Operations:**
```bash
# View issue
gh issue view "$ISSUE_NUMBER" \
  --json number,title,body,labels,comments \
  > issue-details.json

# Comment on issue
gh issue comment "$ISSUE_NUMBER" --body "$(cat response.md)"

# Add label
gh issue edit "$ISSUE_NUMBER" --add-label "ai-reviewed"

# Close issue with comment
gh issue close "$ISSUE_NUMBER" --comment "Fixed in PR #123"
```

**4. Repository Operations:**
```bash
# Clone repository
gh repo clone "$GITHUB_REPOSITORY"

# View file contents
gh api "/repos/$GITHUB_REPOSITORY/contents/$FILE_PATH" \
  --jq '.content' | base64 -d > file-contents.txt

# Create branch
gh api "/repos/$GITHUB_REPOSITORY/git/refs" \
  -X POST \
  -f ref="refs/heads/ai-fix-$PR_NUMBER" \
  -f sha="$COMMIT_SHA"
```

### Request Examples

**REST API Example - Post PR Review:**
```bash
#!/bin/bash
# Script: .github/scripts/post-pr-review.sh

PR_NUMBER="$1"
REVIEW_FILE="$2"

# Read review content
REVIEW_BODY=$(cat "$REVIEW_FILE")
REVIEW_EVENT="COMMENT"  # or REQUEST_CHANGES, APPROVE

# Check if comments exist
if [ -f "inline-comments.json" ]; then
  COMMENTS=$(cat inline-comments.json)
else
  COMMENTS="[]"
fi

# Create review payload
PAYLOAD=$(jq -n \
  --arg body "$REVIEW_BODY" \
  --arg event "$REVIEW_EVENT" \
  --argjson comments "$COMMENTS" \
  '{
    body: $body,
    event: $event,
    comments: $comments
  }')

# Post review via GitHub CLI
gh api "/repos/$GITHUB_REPOSITORY/pulls/$PR_NUMBER/reviews" \
  -X POST \
  --input - <<< "$PAYLOAD"
```

**GraphQL Example - Fetch PR with Context:**
```bash
#!/bin/bash
# Script: .github/scripts/fetch-pr-graphql.sh

PR_NUMBER="$1"
OWNER=$(echo "$GITHUB_REPOSITORY" | cut -d'/' -f1)
REPO=$(echo "$GITHUB_REPOSITORY" | cut -d'/' -f2)

# GraphQL query
QUERY=$(cat <<'EOF'
query($owner: String!, $name: String!, $number: Int!) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      title
      body
      additions
      deletions
      changedFiles
      files(first: 100) {
        nodes {
          path
          additions
          deletions
        }
      }
    }
  }
}
EOF
)

# Execute query
gh api graphql \
  -f query="$QUERY" \
  -F owner="$OWNER" \
  -F name="$REPO" \
  -F number="$PR_NUMBER" \
  > pr-context.json
```

### Response Handling

**Success Response:**
```json
{
  "id": 12345,
  "node_id": "MDExOlB1bGxSZXF1ZXN0...",
  "html_url": "https://github.com/org/repo/pull/123",
  "body": "Review comment successfully posted",
  "user": {
    "login": "github-actions[bot]"
  },
  "created_at": "2024-01-01T00:00:00Z"
}
```

**Error Response:**
```json
{
  "message": "Not Found",
  "documentation_url": "https://docs.github.com/rest/pulls/comments#create-a-review-comment-for-a-pull-request",
  "status": "404"
}
```

**Error Handling Pattern:**
```bash
if ! RESPONSE=$(gh api "/repos/$GITHUB_REPOSITORY/pulls/$PR_NUMBER" 2>&1); then
  ERROR_CODE=$(echo "$RESPONSE" | jq -r '.status // "unknown"')
  ERROR_MSG=$(echo "$RESPONSE" | jq -r '.message // "Unknown error"')

  case $ERROR_CODE in
    404)
      echo "PR not found: $PR_NUMBER"
      ;;
    403)
      echo "Insufficient permissions"
      ;;
    422)
      echo "Validation failed: $ERROR_MSG"
      ;;
    *)
      echo "API error: $ERROR_MSG"
      ;;
  esac

  exit 1
fi
```

---

## AI/LLM Service Integration

### Supported AI Providers

#### 1. OpenAI API

**Configuration:**
```bash
AI_PROVIDER="openai"
AI_API_URL="https://api.openai.com/v1/chat/completions"
AI_MODEL="gpt-4"
AI_API_KEY="${{ secrets.OPENAI_API_KEY }}"
```

**Request Format:**
```bash
#!/bin/bash
# Script: .github/scripts/ai-openai-request.sh

PROMPT_FILE="$1"
SYSTEM_PROMPT="You are an expert code reviewer."
USER_PROMPT=$(cat "$PROMPT_FILE")

# Create request payload
REQUEST=$(jq -n \
  --arg model "$AI_MODEL" \
  --arg system "$SYSTEM_PROMPT" \
  --arg user "$USER_PROMPT" \
  '{
    model: $model,
    messages: [
      {role: "system", content: $system},
      {role: "user", content: $user}
    ],
    temperature: 0.3,
    max_tokens: 2000,
    response_format: {type: "json_object"}
  }')

# Make API call
curl -X POST "$AI_API_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $AI_API_KEY" \
  -d "$REQUEST" \
  -o response.json \
  --fail --silent --show-error

# Extract response
jq -r '.choices[0].message.content' response.json > ai-response.json
```

#### 2. Anthropic Claude API

**Configuration:**
```bash
AI_PROVIDER="anthropic"
AI_API_URL="https://api.anthropic.com/v1/messages"
AI_MODEL="claude-3-opus-20240229"
AI_API_KEY="${{ secrets.ANTHROPIC_API_KEY }}"
```

**Request Format:**
```bash
#!/bin/bash
# Script: .github/scripts/ai-anthropic-request.sh

PROMPT_FILE="$1"
USER_PROMPT=$(cat "$PROMPT_FILE")

REQUEST=$(jq -n \
  --arg model "$AI_MODEL" \
  --arg prompt "$USER_PROMPT" \
  '{
    model: $model,
    max_tokens: 2000,
    messages: [
      {role: "user", content: $prompt}
    ]
  }')

curl -X POST "$AI_API_URL" \
  -H "Content-Type: application/json" \
  -H "x-api-key: $AI_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d "$REQUEST" \
  -o response.json \
  --fail --silent --show-error

jq -r '.content[0].text' response.json > ai-response.json
```

#### 3. Azure OpenAI Service

**Configuration:**
```bash
AI_PROVIDER="azure-openai"
AI_API_URL="https://${AZURE_OPENAI_ENDPOINT}.openai.azure.com/openai/deployments/${DEPLOYMENT_NAME}/chat/completions?api-version=2024-02-15-preview"
AI_API_KEY="${{ secrets.AZURE_OPENAI_API_KEY }}"
```

**Request Format:**
```bash
curl -X POST "$AI_API_URL" \
  -H "Content-Type: application/json" \
  -H "api-key: $AI_API_KEY" \
  -d "$REQUEST" \
  -o response.json
```

### AI Request Construction

**Context Preparation:**
```bash
#!/bin/bash
# Script: .github/scripts/prepare-ai-context.sh

PR_NUMBER="$1"

# Fetch PR details
gh pr view "$PR_NUMBER" \
  --json title,body,additions,deletions,changedFiles,files \
  > pr-data.json

# Fetch diff
gh pr diff "$PR_NUMBER" > pr-diff.patch

# Limit diff size (AI token limits)
DIFF_SIZE=$(wc -c < pr-diff.patch)
MAX_DIFF_SIZE=50000  # ~12k tokens

if [ "$DIFF_SIZE" -gt "$MAX_DIFF_SIZE" ]; then
  echo "Diff too large, using file summaries only"
  DIFF_CONTENT=$(jq -r '.files | map("\(.path): +\(.additions)/-\(.deletions) lines") | join("\n")' pr-data.json)
else
  DIFF_CONTENT=$(cat pr-diff.patch)
fi

# Construct AI prompt
cat > ai-prompt.txt <<EOF
Please review the following pull request:

**Title:** $(jq -r '.title' pr-data.json)

**Description:**
$(jq -r '.body // "No description provided"' pr-data.json)

**Statistics:**
- Files changed: $(jq -r '.changedFiles' pr-data.json)
- Additions: +$(jq -r '.additions' pr-data.json)
- Deletions: -$(jq -r '.deletions' pr-data.json)

**Code Changes:**
\`\`\`diff
$DIFF_CONTENT
\`\`\`

Please provide:
1. Overall assessment (1-2 sentences)
2. Code quality score (0-100)
3. Specific issues found (file, line, severity, message, suggestion)
4. Recommendations for improvement

Respond in JSON format matching this schema:
{
  "summary": "string",
  "score": number,
  "comments": [
    {
      "file": "string",
      "line": number,
      "severity": "error|warning|info",
      "category": "security|performance|style|best-practices",
      "message": "string",
      "suggestion": "string"
    }
  ],
  "recommendations": ["string"]
}
EOF
```

### AI Response Parsing

**Response Validation:**
```bash
#!/bin/bash
# Script: .github/scripts/validate-ai-response.sh

RESPONSE_FILE="$1"

# Check if valid JSON
if ! jq empty "$RESPONSE_FILE" 2>/dev/null; then
  echo "Invalid JSON response"
  exit 1
fi

# Validate schema
REQUIRED_FIELDS=("summary" "score" "comments" "recommendations")
for field in "${REQUIRED_FIELDS[@]}"; do
  if ! jq -e ".$field" "$RESPONSE_FILE" > /dev/null; then
    echo "Missing required field: $field"
    exit 1
  fi
done

# Validate score range
SCORE=$(jq -r '.score' "$RESPONSE_FILE")
if [ "$SCORE" -lt 0 ] || [ "$SCORE" -gt 100 ]; then
  echo "Invalid score: $SCORE (must be 0-100)"
  exit 1
fi

# Validate comment structure
if ! jq -e '.comments | length' "$RESPONSE_FILE" > /dev/null; then
  echo "Invalid comments array"
  exit 1
fi

echo "✅ Response validation passed"
```

**Response Transformation:**
```bash
#!/bin/bash
# Script: .github/scripts/transform-ai-response.sh

RESPONSE_FILE="$1"
OUTPUT_FORMAT="${2:-markdown}"  # markdown, json, github

case $OUTPUT_FORMAT in
  markdown)
    # Convert to markdown for PR comment
    jq -r '
      "## 🤖 AI Code Review\n\n" +
      "**Summary:** " + .summary + "\n\n" +
      "**Quality Score:** " + (.score | tostring) + "/100\n\n" +
      (if (.comments | length) > 0 then
        "### 📋 Issues Found\n\n" +
        (.comments | group_by(.severity) | map(
          "#### " + (.[0].severity | ascii_upcase) + "\n\n" +
          (map("- **" + .file + ":" + (.line | tostring) + "** (" + .category + ")\n  " + .message + "\n  *Suggestion:* " + .suggestion + "\n") | join("\n"))
        ) | join("\n\n"))
      else
        "### ✅ No Issues Found\n\n"
      end) +
      "\n\n### 💡 Recommendations\n\n" +
      (.recommendations | map("- " + .) | join("\n"))
    ' "$RESPONSE_FILE" > review-comment.md
    ;;

  github)
    # Convert to GitHub review format
    jq '{
      body: .summary,
      event: (if .score < 70 then "REQUEST_CHANGES" elif .score >= 90 then "APPROVE" else "COMMENT" end),
      comments: [.comments[] | {
        path: .file,
        line: .line,
        body: .message + "\n\n**Suggestion:** " + .suggestion
      }]
    }' "$RESPONSE_FILE" > github-review.json
    ;;

  json)
    # Keep as JSON
    cp "$RESPONSE_FILE" output.json
    ;;
esac
```

---

## Git Operations Integration

### Git Configuration

**Workflow Setup:**
```yaml
- name: Configure Git
  run: |
    git config --global user.name "AI Agent"
    git config --global user.email "ai-agent@github.com"
    git config --global core.autocrlf input  # Handle line endings
```

### Common Git Operations

**1. Branch Operations:**
```bash
#!/bin/bash
# Script: .github/scripts/git-branch-operations.sh

# Create new branch from PR head
PR_HEAD_REF="${{ github.event.pull_request.head.ref }}"
git checkout "$PR_HEAD_REF"

# Create fix branch
FIX_BRANCH="ai-fix-${PR_NUMBER}"
git checkout -b "$FIX_BRANCH"

# Push branch
git push origin "$FIX_BRANCH"
```

**2. Commit Operations:**
```bash
#!/bin/bash
# Script: .github/scripts/git-commit-changes.sh

# Stage changes
git add .

# Check if there are changes to commit
if git diff --cached --quiet; then
  echo "No changes to commit"
  exit 0
fi

# Create commit
git commit -m "chore: AI auto-fix

$(cat commit-message.txt)

Co-authored-by: github-actions[bot] <github-actions[bot]@users.noreply.github.com>"

# Push with retry
MAX_RETRIES=3
for i in $(seq 1 $MAX_RETRIES); do
  if git push origin HEAD; then
    echo "✅ Push successful"
    exit 0
  fi

  if [ $i -lt $MAX_RETRIES ]; then
    echo "Push failed, rebasing and retrying..."
    git pull --rebase origin "$BRANCH_NAME"
  fi
done

echo "❌ Push failed after $MAX_RETRIES attempts"
exit 1
```

**3. Diff Operations:**
```bash
#!/bin/bash
# Script: .github/scripts/git-analyze-diff.sh

PR_NUMBER="$1"

# Get base and head refs
BASE_REF="${{ github.event.pull_request.base.ref }}"
HEAD_REF="${{ github.event.pull_request.head.sha }}"

# Fetch refs
git fetch origin "$BASE_REF"
git fetch origin "$HEAD_REF"

# Generate diff
git diff "origin/$BASE_REF...$HEAD_REF" > pr-diff.patch

# Get changed files
git diff --name-only "origin/$BASE_REF...$HEAD_REF" > changed-files.txt

# Get stats
git diff --stat "origin/$BASE_REF...$HEAD_REF" > diff-stats.txt

# Filter by file type
git diff --name-only "origin/$BASE_REF...$HEAD_REF" | \
  grep -E '\.(js|ts|py|go|java)$' > changed-code-files.txt
```

**4. File Operations:**
```bash
#!/bin/bash
# Script: .github/scripts/git-file-operations.sh

# Read file from specific commit
git show "$COMMIT_SHA:$FILE_PATH" > file-content.txt

# Check if file exists in PR
if git diff --name-only "$BASE_REF...$HEAD_REF" | grep -q "$FILE_PATH"; then
  echo "File changed in PR"
fi

# Get file history
git log --follow --pretty=format:"%h %an %ad %s" -- "$FILE_PATH" > file-history.txt

# Get blame for file
git blame -L "$START_LINE,$END_LINE" "$FILE_PATH" > blame-output.txt
```

### Sparse Checkout Strategy

**Implementation:**
```yaml
- name: Sparse Checkout
  uses: actions/checkout@v4
  with:
    sparse-checkout: |
      .github/
      src/
      package.json
      package-lock.json
    sparse-checkout-cone-mode: false
```

**Custom Sparse Checkout:**
```bash
#!/bin/bash
# Script: .github/scripts/sparse-checkout-custom.sh

# Initialize sparse checkout
git config core.sparseCheckout true

# Define sparse checkout paths based on PR
echo ".github/" >> .git/info/sparse-checkout
echo "src/" >> .git/info/sparse-checkout

# Get changed files from PR and add to sparse checkout
gh pr view "$PR_NUMBER" --json files --jq '.files[].path' | while read -r file; do
  echo "$file" >> .git/info/sparse-checkout
done

# Apply sparse checkout
git read-tree -mu HEAD
```

**Performance Comparison:**
```
Full Checkout:    15-30 seconds, 500MB
Sparse Checkout:  3-5 seconds, 50MB
Savings:          80-90% time, 90% disk space
```

---

## Integration Contracts & Schemas

### Workflow → Script Contract

**Input Schema (Environment Variables):**
```bash
# Required
GITHUB_TOKEN=ghp_xxx              # GitHub API authentication
GITHUB_REPOSITORY=org/repo        # Repository identifier
GITHUB_EVENT_NAME=pull_request    # Event type
GITHUB_SHA=abc123                 # Commit SHA
GITHUB_WORKSPACE=/path/to/repo    # Repository path

# Event-specific
GITHUB_EVENT_PATH=/path/to/event.json  # Event payload

# AI-specific
AI_API_KEY=sk_xxx                 # AI service API key
AI_MODEL=gpt-4                    # AI model identifier
AI_PROVIDER=openai                # AI provider name

# Optional configuration
AI_TEMPERATURE=0.3                # AI temperature
AI_MAX_TOKENS=2000                # Max response tokens
RATE_LIMIT_ENABLED=true           # Enable rate limiting
CACHE_ENABLED=true                # Enable response caching
```

**Output Schema (GitHub Outputs):**
```bash
# Standard outputs (set via $GITHUB_OUTPUT)
echo "task-completed=true" >> $GITHUB_OUTPUT
echo "result-summary=Successfully reviewed PR" >> $GITHUB_OUTPUT
echo "error-message=" >> $GITHUB_OUTPUT
echo "warnings-count=3" >> $GITHUB_OUTPUT
echo "issues-count=5" >> $GITHUB_OUTPUT
echo "score=85" >> $GITHUB_OUTPUT
```

**File-Based Outputs:**
```
pr-context.json       - Extracted PR context
ai-request.json       - AI API request payload
ai-response.json      - AI API response
review-comment.md     - Generated review comment
error.log             - Error details
metrics.json          - Execution metrics
```

### Script → AI API Contract

**Request Schema:**
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["task", "context", "config"],
  "properties": {
    "task": {
      "type": "string",
      "enum": ["pr-review", "issue-response", "code-fix", "code-explain"]
    },
    "context": {
      "type": "object",
      "required": ["repository", "event_type"],
      "properties": {
        "repository": {"type": "string"},
        "event_type": {"type": "string"},
        "pr_number": {"type": "integer"},
        "issue_number": {"type": "integer"},
        "title": {"type": "string"},
        "description": {"type": "string"},
        "diff": {"type": "string"},
        "files_changed": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "filename": {"type": "string"},
              "status": {"type": "string"},
              "additions": {"type": "integer"},
              "deletions": {"type": "integer"},
              "patch": {"type": "string"}
            }
          }
        },
        "metadata": {
          "type": "object",
          "properties": {
            "author": {"type": "string"},
            "created_at": {"type": "string", "format": "date-time"},
            "base_branch": {"type": "string"},
            "head_branch": {"type": "string"}
          }
        }
      }
    },
    "config": {
      "type": "object",
      "required": ["model"],
      "properties": {
        "model": {"type": "string"},
        "temperature": {"type": "number", "minimum": 0, "maximum": 1},
        "max_tokens": {"type": "integer", "minimum": 1},
        "focus_areas": {
          "type": "array",
          "items": {"type": "string"}
        }
      }
    }
  }
}
```

**Response Schema:**
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["status", "task", "result"],
  "properties": {
    "status": {
      "type": "string",
      "enum": ["success", "partial_success", "error"]
    },
    "task": {"type": "string"},
    "result": {
      "type": "object",
      "properties": {
        "summary": {"type": "string"},
        "score": {"type": "integer", "minimum": 0, "maximum": 100},
        "comments": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["file", "line", "severity", "message"],
            "properties": {
              "file": {"type": "string"},
              "line": {"type": "integer"},
              "severity": {
                "type": "string",
                "enum": ["error", "warning", "info"]
              },
              "category": {
                "type": "string",
                "enum": ["security", "performance", "style", "best-practices", "bugs"]
              },
              "message": {"type": "string"},
              "suggestion": {"type": "string"}
            }
          }
        },
        "recommendations": {
          "type": "array",
          "items": {"type": "string"}
        }
      }
    },
    "metadata": {
      "type": "object",
      "properties": {
        "model_used": {"type": "string"},
        "tokens_used": {"type": "integer"},
        "processing_time_ms": {"type": "integer"},
        "timestamp": {"type": "string", "format": "date-time"}
      }
    },
    "error": {
      "type": "object",
      "properties": {
        "code": {"type": "string"},
        "message": {"type": "string"},
        "details": {"type": "string"}
      }
    }
  }
}
```

### Schema Validation Scripts

**Validate Request:**
```bash
#!/bin/bash
# Script: .github/scripts/validate-request-schema.sh

REQUEST_FILE="$1"
SCHEMA_FILE=".github/schemas/ai-request-schema.json"

if ! command -v ajv &> /dev/null; then
  npm install -g ajv-cli
fi

if ajv validate -s "$SCHEMA_FILE" -d "$REQUEST_FILE"; then
  echo "✅ Request schema valid"
  exit 0
else
  echo "❌ Request schema validation failed"
  exit 1
fi
```

**Validate Response:**
```bash
#!/bin/bash
# Script: .github/scripts/validate-response-schema.sh

RESPONSE_FILE="$1"
SCHEMA_FILE=".github/schemas/ai-response-schema.json"

if ajv validate -s "$SCHEMA_FILE" -d "$RESPONSE_FILE"; then
  echo "✅ Response schema valid"
  exit 0
else
  echo "❌ Response schema validation failed"
  echo "Response:"
  cat "$RESPONSE_FILE"
  exit 1
fi
```

---

## Rate Limiting & Throttling

### GitHub API Rate Limits

**Limits:**
- **REST API**: 5,000 requests/hour (authenticated)
- **GraphQL API**: 5,000 points/hour
- **Search API**: 30 requests/minute
- **Secondary rate limit**: Avoid > 100 concurrent requests

**Monitoring:**
```bash
#!/bin/bash
# Script: .github/scripts/check-github-rate-limit.sh

# Get rate limit status
RATE_DATA=$(gh api rate_limit)

# Extract limits
REMAINING=$(echo "$RATE_DATA" | jq -r '.rate.remaining')
LIMIT=$(echo "$RATE_DATA" | jq -r '.rate.limit')
RESET=$(echo "$RATE_DATA" | jq -r '.rate.reset')

echo "GitHub API Rate Limit: $REMAINING/$LIMIT remaining"

# Calculate time until reset
CURRENT_TIME=$(date +%s)
WAIT_TIME=$((RESET - CURRENT_TIME))

# Warn if low
if [ "$REMAINING" -lt 100 ]; then
  echo "⚠️ WARNING: Low rate limit!"
  echo "Reset in $((WAIT_TIME / 60)) minutes"

  # Optionally wait
  if [ "$WAIT_IF_LOW" = "true" ]; then
    echo "Waiting for reset..."
    sleep "$WAIT_TIME"
  fi
fi

# Set outputs
echo "remaining=$REMAINING" >> $GITHUB_OUTPUT
echo "reset_at=$RESET" >> $GITHUB_OUTPUT
echo "wait_seconds=$WAIT_TIME" >> $GITHUB_OUTPUT
```

**Rate Limit Handling:**
```yaml
- name: Check Rate Limit
  id: rate-limit
  run: bash .github/scripts/check-github-rate-limit.sh
  continue-on-error: true

- name: Wait if Needed
  if: steps.rate-limit.outputs.remaining < '100'
  run: |
    echo "Rate limit low, waiting..."
    sleep ${{ steps.rate-limit.outputs.wait_seconds }}
```

### AI API Rate Limits

**OpenAI Limits (GPT-4):**
- **Requests**: 500/minute, 10,000/day
- **Tokens**: 150,000/minute, 2,000,000/day

**Anthropic Claude Limits:**
- **Requests**: 50/minute (tier 1)
- **Tokens**: 100,000/minute

**Rate Limit Implementation:**
```bash
#!/bin/bash
# Script: .github/scripts/ai-rate-limiter.sh

RATE_LIMIT_FILE="$HOME/.cache/ai-rate-limit.json"
MAX_REQUESTS_PER_MINUTE=50
MAX_TOKENS_PER_MINUTE=100000

# Initialize rate limit file
if [ ! -f "$RATE_LIMIT_FILE" ]; then
  echo '{"requests": [], "tokens": []}' > "$RATE_LIMIT_FILE"
fi

# Get current timestamp
NOW=$(date +%s)
MINUTE_AGO=$((NOW - 60))

# Load rate limit data
RATE_DATA=$(cat "$RATE_LIMIT_FILE")

# Filter to last minute
RECENT_REQUESTS=$(echo "$RATE_DATA" | jq --arg ts "$MINUTE_AGO" '[.requests[] | select(. > ($ts | tonumber))]')
RECENT_TOKENS=$(echo "$RATE_DATA" | jq --arg ts "$MINUTE_AGO" '[.tokens[] | select(.timestamp > ($ts | tonumber))]')

# Count requests and tokens
REQUEST_COUNT=$(echo "$RECENT_REQUESTS" | jq 'length')
TOKEN_COUNT=$(echo "$RECENT_TOKENS" | jq '[.[].count] | add // 0')

echo "Rate limit: $REQUEST_COUNT/$MAX_REQUESTS_PER_MINUTE requests, $TOKEN_COUNT/$MAX_TOKENS_PER_MINUTE tokens"

# Check if we need to wait
if [ "$REQUEST_COUNT" -ge "$MAX_REQUESTS_PER_MINUTE" ] || [ "$TOKEN_COUNT" -ge "$MAX_TOKENS_PER_MINUTE" ]; then
  # Find oldest request
  OLDEST=$(echo "$RECENT_REQUESTS" | jq 'min')
  WAIT_TIME=$((OLDEST + 60 - NOW))

  echo "Rate limit reached, waiting ${WAIT_TIME}s..."
  sleep "$WAIT_TIME"
fi

# Record this request
TOKENS_USED="${1:-1000}"
echo "$RATE_DATA" | jq \
  --arg now "$NOW" \
  --arg tokens "$TOKENS_USED" \
  '.requests += [$now | tonumber] | .tokens += [{timestamp: ($now | tonumber), count: ($tokens | tonumber)}]' \
  > "$RATE_LIMIT_FILE"
```

### Throttling Strategy

**Exponential Backoff:**
```bash
#!/bin/bash
# Script: .github/scripts/exponential-backoff.sh

make_api_call() {
  local url="$1"
  local max_retries="${2:-5}"
  local base_delay="${3:-1}"

  for attempt in $(seq 0 $max_retries); do
    echo "Attempt $((attempt + 1))/$((max_retries + 1))..."

    if curl -X POST "$url" --fail --silent --show-error; then
      echo "✅ Success"
      return 0
    fi

    if [ "$attempt" -lt "$max_retries" ]; then
      # Calculate exponential backoff with jitter
      delay=$((base_delay * (2 ** attempt)))
      jitter=$((RANDOM % delay))
      total_delay=$((delay + jitter))

      echo "Failed, waiting ${total_delay}s before retry..."
      sleep "$total_delay"
    fi
  done

  echo "❌ All retries failed"
  return 1
}

# Usage
make_api_call "https://api.example.com/endpoint" 5 2
```

---

## Authentication & Authorization

### GitHub Token Management

**GITHUB_TOKEN (Automatic):**
```yaml
permissions:
  contents: read
  pull-requests: write
  issues: write

env:
  GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**Scopes:**
- `contents:read` - Read repository contents
- `contents:write` - Push commits, create branches
- `pull-requests:read` - View PRs
- `pull-requests:write` - Comment, review, merge PRs
- `issues:read` - View issues
- `issues:write` - Comment, edit issues
- `metadata:read` - Read repository metadata (always granted)

**PAT (Personal Access Token):**
```yaml
# For operations requiring elevated permissions
env:
  GH_TOKEN: ${{ secrets.AI_AGENT_PAT }}
```

**PAT Scopes Required:**
- `repo` - Full repository access
- `workflow` - Update workflow files
- `write:discussion` - Participate in discussions

### AI API Authentication

**OpenAI:**
```bash
curl -X POST "https://api.openai.com/v1/chat/completions" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json"
```

**Anthropic:**
```bash
curl -X POST "https://api.anthropic.com/v1/messages" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01"
```

**Azure OpenAI:**
```bash
curl -X POST "$AZURE_OPENAI_ENDPOINT" \
  -H "api-key: $AZURE_OPENAI_API_KEY"
```

### Secrets Management

**Secrets Hierarchy:**
```
Organization Secrets (highest precedence)
  ├─ AI_API_KEY
  ├─ AI_AGENT_PAT
  └─ NOTIFICATION_WEBHOOK

Repository Secrets
  ├─ CUSTOM_AI_MODEL
  └─ REPO_SPECIFIC_CONFIG

Environment Secrets (environment-specific)
  ├─ PRODUCTION_API_KEY
  └─ STAGING_API_KEY
```

**Secret Rotation:**
```bash
#!/bin/bash
# Script: .github/scripts/check-secret-expiry.sh

# This would be run periodically to check secret age
SECRET_AGE_DAYS=90
WARNING_DAYS=7

LAST_ROTATION=$(gh api "/repos/$GITHUB_REPOSITORY/actions/secrets/AI_AGENT_PAT" \
  --jq '.updated_at' 2>/dev/null || echo "1970-01-01T00:00:00Z")

LAST_ROTATION_TS=$(date -d "$LAST_ROTATION" +%s)
NOW=$(date +%s)
AGE_DAYS=$(( (NOW - LAST_ROTATION_TS) / 86400 ))

echo "Secret age: $AGE_DAYS days"

if [ "$AGE_DAYS" -gt "$SECRET_AGE_DAYS" ]; then
  echo "❌ Secret expired! Rotation required."
  exit 1
elif [ "$AGE_DAYS" -gt $((SECRET_AGE_DAYS - WARNING_DAYS)) ]; then
  echo "⚠️ Secret expiring soon!"
  exit 0
else
  echo "✅ Secret valid"
  exit 0
fi
```

---

## Error Handling & Circuit Breakers

### Circuit Breaker Pattern

**Implementation:**
```bash
#!/bin/bash
# Script: .github/scripts/circuit-breaker.sh

CIRCUIT_FILE="$HOME/.cache/circuit-breaker-${SERVICE_NAME}.json"
FAILURE_THRESHOLD=5
TIMEOUT_SECONDS=300

# Initialize circuit breaker state
if [ ! -f "$CIRCUIT_FILE" ]; then
  echo '{"state": "closed", "failures": 0, "last_failure": 0}' > "$CIRCUIT_FILE"
fi

# Load state
STATE=$(jq -r '.state' "$CIRCUIT_FILE")
FAILURES=$(jq -r '.failures' "$CIRCUIT_FILE")
LAST_FAILURE=$(jq -r '.last_failure' "$CIRCUIT_FILE")
NOW=$(date +%s)

# Check circuit state
case $STATE in
  open)
    # Check if timeout has passed
    if [ $((NOW - LAST_FAILURE)) -gt "$TIMEOUT_SECONDS" ]; then
      echo "Circuit breaker: transitioning to half-open"
      jq '.state = "half-open"' "$CIRCUIT_FILE" > "$CIRCUIT_FILE.tmp"
      mv "$CIRCUIT_FILE.tmp" "$CIRCUIT_FILE"
    else
      echo "❌ Circuit breaker OPEN - service unavailable"
      exit 1
    fi
    ;;

  half-open)
    echo "Circuit breaker: half-open, attempting request"
    ;;

  closed)
    echo "Circuit breaker: closed, normal operation"
    ;;
esac

# Make the actual API call
if make_api_call "$@"; then
  # Success - reset or close circuit
  echo '{"state": "closed", "failures": 0, "last_failure": 0}' > "$CIRCUIT_FILE"
  echo "✅ Request successful"
  exit 0
else
  # Failure - increment counter
  FAILURES=$((FAILURES + 1))

  if [ "$FAILURES" -ge "$FAILURE_THRESHOLD" ]; then
    echo "❌ Failure threshold reached - opening circuit"
    jq --arg now "$NOW" \
      '.state = "open" | .failures = 0 | .last_failure = ($now | tonumber)' \
      "$CIRCUIT_FILE" > "$CIRCUIT_FILE.tmp"
  else
    echo "⚠️ Request failed ($FAILURES/$FAILURE_THRESHOLD)"
    jq --arg failures "$FAILURES" --arg now "$NOW" \
      '.failures = ($failures | tonumber) | .last_failure = ($now | tonumber)' \
      "$CIRCUIT_FILE" > "$CIRCUIT_FILE.tmp"
  fi

  mv "$CIRCUIT_FILE.tmp" "$CIRCUIT_FILE"
  exit 1
fi
```

### Fallback Strategies

**1. Graceful Degradation:**
```bash
#!/bin/bash
# Try AI review, fall back to basic checks

if ! bash .github/scripts/ai-pr-review.sh; then
  echo "AI review failed, running basic checks..."

  # Basic linting
  npm run lint || echo "Linting found issues"

  # Basic security scan
  npm audit || echo "Security vulnerabilities found"

  # Post fallback comment
  gh pr comment "$PR_NUMBER" --body \
    "⚠️ AI review unavailable. Basic checks completed. Manual review recommended."
fi
```

**2. Cached Response:**
```bash
#!/bin/bash
# Use cached AI response if available

CACHE_KEY="ai-review-$(git rev-parse HEAD)"
CACHE_FILE="$HOME/.cache/ai-responses/$CACHE_KEY.json"

if [ -f "$CACHE_FILE" ]; then
  echo "Using cached AI response"
  cp "$CACHE_FILE" ai-response.json
  exit 0
fi

# Make AI request
if make_ai_request; then
  # Cache response
  mkdir -p "$(dirname "$CACHE_FILE")"
  cp ai-response.json "$CACHE_FILE"
else
  echo "AI request failed and no cache available"
  exit 1
fi
```

### Monitoring & Alerting

**Error Tracking:**
```bash
#!/bin/bash
# Script: .github/scripts/track-errors.sh

ERROR_LOG="$HOME/.cache/error-log.json"

log_error() {
  local service="$1"
  local error_type="$2"
  local error_message="$3"

  ERROR_ENTRY=$(jq -n \
    --arg service "$service" \
    --arg type "$error_type" \
    --arg message "$error_message" \
    --arg timestamp "$(date -Iseconds)" \
    '{
      service: $service,
      type: $type,
      message: $message,
      timestamp: $timestamp
    }')

  # Append to log
  if [ -f "$ERROR_LOG" ]; then
    jq ". += [$ERROR_ENTRY]" "$ERROR_LOG" > "$ERROR_LOG.tmp"
    mv "$ERROR_LOG.tmp" "$ERROR_LOG"
  else
    echo "[$ERROR_ENTRY]" > "$ERROR_LOG"
  fi

  # Check error frequency
  ERROR_COUNT=$(jq --arg service "$service" \
    '[.[] | select(.service == $service and .timestamp > (now - 3600 | todate))] | length' \
    "$ERROR_LOG")

  if [ "$ERROR_COUNT" -gt 10 ]; then
    echo "⚠️ High error rate detected for $service: $ERROR_COUNT errors in last hour"
    # Trigger alert
    bash .github/scripts/send-alert.sh "High error rate: $service"
  fi
}

# Usage
log_error "ai-api" "rate_limit" "AI API rate limit exceeded"
```

---

## Summary

This integration architecture provides:

1. **GitHub API Integration** - REST, GraphQL, and CLI access patterns
2. **AI/LLM Integration** - Multi-provider support with structured contracts
3. **Git Operations** - Comprehensive git workflows and sparse checkout
4. **Integration Contracts** - JSON schemas for workflow/script/AI communication
5. **Rate Limiting** - GitHub and AI API rate limit handling
6. **Authentication** - Token management and secrets handling
7. **Error Handling** - Circuit breakers, retries, and fallback strategies

All integrations are designed for reliability, observability, and maintainability in a production self-hosted runner environment.
