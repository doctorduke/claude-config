# API Complete Reference

## Scripts API

### ai-review.sh

**Purpose:** Generate AI-powered PR code review

**Usage:**
```bash
./scripts/ai-review.sh --pr NUMBER [OPTIONS]
```

**Parameters:**
- `--pr NUMBER` (required): PR number to review
- `--model MODEL` (optional): AI model (default: claude-3-5-sonnet-20241022)
- `--output FILE` (optional): Output JSON file (default: review.json)
- `--max-files N` (optional): Max files to review (default: 20)
- `--dry-run` (optional): Validate without API calls

**Environment Variables:**
- `GH_TOKEN` or `GITHUB_TOKEN`: GitHub token
- `AI_API_KEY`: AI service API key
- `AI_API_ENDPOINT`: AI service endpoint

**Output Format:**
```json
{
  "event": "APPROVE|REQUEST_CHANGES|COMMENT",
  "body": "Review summary",
  "comments": [{"path": "file.js", "line": 42, "body": "..."}],
  "metadata": {"model": "...", "timestamp": "...", "pr_number": 123}
}
```

**Exit Codes:**
- 0: Success
- 1: General error
- 2: Invalid arguments
- 3: API error
- 4: Invalid output

### ai-agent.sh

**Purpose:** Respond to issue/PR comments

**Usage:**
```bash
./scripts/ai-agent.sh --issue NUMBER --query "QUESTION" [OPTIONS]
```

**Parameters:**
- `--issue NUMBER` (required): Issue/PR number
- `--query TEXT` (required): User question
- `--task-type TYPE` (optional): general|summarize|analyze|suggest
- `--model MODEL` (optional): AI model
- `--output FILE` (optional): Output file

**Output Format:**
```json
{
  "response": {"body": "...", "type": "comment", "suggested_labels": []},
  "metadata": {"model": "...", "timestamp": "...", "issue_number": 456}
}
```

### ai-autofix.sh

**Purpose:** Automatically fix code issues

**Usage:**
```bash
./scripts/ai-autofix.sh --pr NUMBER --fix-type TYPE [OPTIONS]
```

**Parameters:**
- `--pr NUMBER` (required): PR number
- `--fix-type TYPE` (required): all|linting|formatting|security|performance
- `--commit` (optional): Commit changes automatically
- `--push` (optional): Push changes to PR branch

**Supported Linters:**
- JavaScript: eslint, prettier
- Python: black, pylint, flake8
- Ruby: rubocop
- Go: gofmt
- Rust: rustfmt
- Shell: shellcheck

## Workflows API

### ai-pr-review.yml

**Triggers:**
- `pull_request`: opened, synchronize, reopened
- `workflow_dispatch`: Manual with pr_number input

**Inputs (workflow_dispatch):**
- `pr_number` (number, required): PR to review

**Outputs:**
- `review_id`: Posted review ID
- `review_status`: approved|changes_requested|commented

### ai-issue-comment.yml

**Triggers:**
- `issue_comment`: created (if contains /agent)
- `workflow_dispatch`: Manual

**Inputs:**
- `issue_number` (number): Issue to respond to
- `query` (string): Question to answer

### ai-autofix.yml

**Triggers:**
- `pull_request`: labeled with "auto-fix"
- `issue_comment`: /autofix command
- `workflow_dispatch`: Manual

**Inputs:**
- `pr_number` (number): PR to fix
- `fix_type` (choice): all|linting|formatting|security|performance

### reusable-ai-workflow.yml

**Usage:**
```yaml
jobs:
  review:
    uses: org/repo/.github/workflows/reusable-ai-workflow.yml@main
    with:
      pr_number: ${{ github.event.pull_request.number }}
      ai_model: claude-3-5-sonnet-20241022
      max_files: 20
      threshold_score: 70
    secrets:
      ai_api_key: ${{ secrets.AI_API_KEY }}
```

**Inputs:**
- `pr_number` (number, required): PR to review
- `ai_model` (string): Model name
- `max_files` (number): Max files to review (default: 20)
- `threshold_score` (number): Min quality score (default: 70)

**Outputs:**
- `review_id`: Review ID
- `review_status`: Review event type
- `score`: Quality score 0-100

## Actions API

### setup-ai-agent

**Purpose:** Initialize AI agent environment

**Usage:**
```yaml
- uses: ./.github/actions/setup-ai-agent
  with:
    api-key: ${{ secrets.AI_API_KEY }}
    model: claude-3-5-sonnet-20241022
```

**Inputs:**
- `api-key` (required): AI API key
- `model` (optional): Model name
- `endpoint` (optional): API endpoint

## Configuration Reference

### runner-groups.json

**Structure:**
```json
{
  "GROUP_NAME": {
    "runners": "3-10",
    "labels": ["self-hosted", "linux", "x64"],
    "access": "all-repos|selected-repos",
    "auto_scaling": {"triggers": [...]}
  }
}
```

### security-policy.json

**Structure:**
```json
{
  "secrets_rotation_days": 90,
  "required_permissions": ["contents: read", "pull-requests: write"],
  "allowed_actions": ["actions/checkout@v4"]
}
```

## Error Codes

### Script Exit Codes
- 0: Success
- 1: General error
- 2: Invalid arguments
- 3: API error
- 4: Invalid output
- 5: Permission denied
- 6: Not found

### HTTP Status Codes
- 200: Success
- 401: Unauthorized (check token)
- 403: Forbidden (check permissions)
- 404: Not found
- 422: Validation failed
- 500: Server error (retry)

## Rate Limits

**GitHub API:**
- 5000 requests/hour (authenticated)
- Check: `gh api rate_limit`

**AI API:**
- Model-dependent (see provider docs)
- Retry with exponential backoff implemented
