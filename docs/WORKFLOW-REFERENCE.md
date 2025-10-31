# GitHub Actions Workflow Reference

## AI PR Review Workflow

**File**: `.github/workflows/ai-pr-review.yml`
**Purpose**: Automated AI-powered code review for pull requests

### Triggers
- `pull_request`: opened, synchronize, reopened
- `workflow_dispatch`: Manual trigger with PR number input

### Permissions
- `contents: read`
- `pull-requests: write`  
- `issues: read`

### Usage
```bash
# Automatic: Triggered on PR events
# Manual: Actions tab > AI PR Review > Run workflow > Enter PR number

# Via gh CLI
gh workflow run ai-pr-review.yml -f pr_number=123
```

### Configuration
- `AI_MODEL`: Model to use (default: claude-3-5-sonnet-20241022)
- `AI_API_KEY`: Required secret

---

## AI Issue Comment Workflow

**File**: `.github/workflows/ai-issue-comment.yml`
**Purpose**: Respond to issue comments with AI assistance

### Triggers
- `issue_comment`: created (only if contains `/agent`)
- `workflow_dispatch`: Manual trigger

### Usage
```bash
# Comment on any issue/PR with: /agent <your question>
# Example: /agent summarize this issue
```

---

## AI Auto-Fix Workflow  

**File**: `.github/workflows/ai-autofix.yml`
**Purpose**: Automatically fix code issues and commit to PR branch

### Triggers
- `pull_request`: labeled with "auto-fix"
- `issue_comment`: created with `/autofix [type]`
- `workflow_dispatch`: Manual trigger

### Fix Types
- `all`: Run all fix types
- `linting`: Fix linting issues
- `formatting`: Fix formatting
- `security`: Fix security issues
- `performance`: Fix performance issues

### Usage
```bash
# Comment on PR: /autofix linting
# Or apply "auto-fix" label to PR
```

---

## Reusable AI Workflow

**File**: `.github/workflows/reusable-ai-workflow.yml`
**Purpose**: Org-wide reusable workflow for consistent PR reviews

### Usage
```yaml
jobs:
  review:
    uses: org/repo/.github/workflows/reusable-ai-workflow.yml@main
    with:
      pr_number: ${{ github.event.pull_request.number }}
      ai_model: 'claude-3-opus'
    secrets:
      ai_api_key: ${{ secrets.AI_API_KEY }}
```

### Inputs
- `pr_number`: PR to review (required)
- `ai_model`: Model name (optional)
- `max_files`: Max files to review (default: 20)
- `threshold_score`: Minimum quality score (default: 70)

### Outputs
- `review_id`: Posted review ID
- `review_status`: approved/changes_requested/commented
- `score`: Quality score 0-100

---

## Security Best Practices

1. **Always use minimal permissions**
2. **Never log secrets**
3. **Validate all inputs**
4. **Use PAT for protected branches**
5. **Review security scan results**

See: `docs/workflow-security-guide.md`
