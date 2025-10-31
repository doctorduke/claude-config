# AI Agent Scripts

Cross-platform bash scripts for AI-powered GitHub operations.

## Overview

This directory contains POSIX-compliant bash scripts that integrate AI capabilities with GitHub workflows for automated code review, issue management, and code fixing.

## Scripts

### 1. ai-review.sh

**Purpose:** Performs AI-powered code review on pull requests and generates structured JSON output.

**Usage:**
```bash
./ai-review.sh --pr 123 [OPTIONS]
```

**Key Features:**
- Fetches PR diff and metadata using GitHub CLI
- Sends code to AI model for analysis
- Generates structured JSON output with review event (APPROVE/REQUEST_CHANGES/COMMENT)
- Supports automatic posting of reviews to GitHub
- Includes retry logic with exponential backoff
- Cross-platform path handling

**Output Format:**
```json
{
  "event": "APPROVE|REQUEST_CHANGES|COMMENT",
  "body": "Review summary text in Markdown",
  "comments": [
    {"path": "file.js", "line": 42, "body": "Comment text"}
  ],
  "metadata": {
    "model": "claude-3-5-sonnet-20241022",
    "timestamp": "2025-10-17T12:00:00Z",
    "pr_number": 123,
    "files_reviewed": 5,
    "issues_found": 3
  }
}
```

**Environment Variables:**
- `GITHUB_TOKEN` (required) - GitHub API authentication
- `AI_API_KEY` (required) - AI service API key
- `AI_API_ENDPOINT` (required) - AI service endpoint URL
- `AI_MODEL` (optional) - Default AI model name

**Examples:**
```bash
# Basic review
./ai-review.sh --pr 123

# Use specific model and auto-post
./ai-review.sh --pr 123 --model claude-3-opus --auto-post

# Review with verbose logging
./ai-review.sh --pr 123 --verbose --output my-review.json
```

---

### 2. ai-agent.sh

**Purpose:** General AI agent for processing issue comments and generating intelligent responses.

**Usage:**
```bash
./ai-agent.sh --issue 123 [OPTIONS]
```

**Key Features:**
- Processes GitHub issue comments and discussions
- Multiple task types: general, summarize, analyze, suggest
- Context-aware responses based on issue history
- Structured JSON output for integration
- Automatic response posting capability

**Task Types:**
- `general` - General Q&A and assistance
- `summarize` - Summarize issue discussion
- `analyze` - Analyze issue for root cause
- `suggest` - Suggest solutions or next steps

**Output Format:**
```json
{
  "response": "AI-generated response in Markdown",
  "actions": [
    {"type": "label", "description": "Add label", "value": "analyzed"}
  ],
  "metadata": {
    "model": "claude-3-5-sonnet-20241022",
    "timestamp": "2025-10-17T12:00:00Z",
    "issue_number": 123,
    "task_type": "analyze",
    "confidence": 0.85
  }
}
```

**Examples:**
```bash
# Respond to latest issue comment
./ai-agent.sh --issue 123

# Summarize issue discussion
./ai-agent.sh --issue 123 --task summarize --auto-post

# Analyze specific comment
./ai-agent.sh --issue 123 --comment 456789 --task analyze
```

---

### 3. ai-autofix.sh

**Purpose:** Runs linters/formatters and uses AI to automatically fix code issues.

**Usage:**
```bash
./ai-autofix.sh [--pr 123] [--path ./src] [OPTIONS]
```

**Key Features:**
- Auto-detects available linters/formatters
- Runs multiple code quality tools
- Uses AI to fix complex issues that tools can't handle
- Supports dry-run mode for safe testing
- Optional automatic git commit
- Configurable max fixes to prevent over-automation

**Supported Tools:**
- `eslint` - JavaScript/TypeScript linter
- `prettier` - Multi-language formatter
- `black` - Python formatter
- `pylint` - Python linter
- `flake8` - Python style checker
- `rubocop` - Ruby linter
- `gofmt` - Go formatter
- `rustfmt` - Rust formatter
- `shellcheck` - Shell script linter

**Examples:**
```bash
# Fix all issues in current directory
./ai-autofix.sh

# Fix specific PR with auto-commit
./ai-autofix.sh --pr 123 --auto-commit

# Use specific tools on path
./ai-autofix.sh --tools eslint,prettier --path src/

# Dry run to preview changes
./ai-autofix.sh --dry-run --verbose
```

---

## Shared Library

### lib/common.sh

Common utility functions used by all scripts:

**Functions:**
- `log_*()` - Logging with levels (debug, info, warn, error)
- `check_required_env()` - Validate environment variables
- `check_required_commands()` - Verify required commands exist
- `normalize_path()` - Cross-platform path handling
- `validate_json()` - JSON validation with jq
- `retry_with_backoff()` - Exponential backoff retry logic
- `call_ai_api()` - AI API integration with error handling
- `get_pr_*()` - GitHub PR operations
- `post_pr_*()` - Post reviews and comments

**Usage:**
```bash
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Now you can use all common functions
check_required_env "GITHUB_TOKEN" "AI_API_KEY"
log_info "Starting process..."
```

---

## JSON Schemas

### schemas/review-output.json

JSON Schema for ai-review.sh output format. Validates:
- Required fields: `event`, `body`
- Event enum: `APPROVE`, `REQUEST_CHANGES`, `COMMENT`
- Optional inline comments array
- Metadata structure

### schemas/comment-output.json

JSON Schema for ai-agent.sh output format. Validates:
- Required field: `response`
- Optional actions array
- Metadata structure

---

## Installation

### Prerequisites

1. **GitHub CLI (gh)** - Required for all scripts
   ```bash
   # macOS
   brew install gh

   # Linux
   sudo apt install gh

   # Windows (Git Bash)
   winget install GitHub.cli
   ```

2. **jq** - JSON processor (required)
   ```bash
   # macOS
   brew install jq

   # Linux
   sudo apt install jq

   # Windows (Git Bash)
   winget install jqlang.jq
   ```

3. **curl** - HTTP client (usually pre-installed)

4. **Optional Linters** (for ai-autofix.sh)
   ```bash
   # JavaScript/TypeScript
   npm install -g eslint prettier

   # Python
   pip install black pylint flake8

   # Ruby
   gem install rubocop
   ```

### Setup

1. **Clone Repository:**
   ```bash
   git clone <repository-url>
   cd github-act/scripts
   ```

2. **Make Scripts Executable:**
   ```bash
   chmod +x ai-review.sh ai-agent.sh ai-autofix.sh
   ```

3. **Configure Environment:**
   ```bash
   # Create .env file
   cat > .env << EOF
   GITHUB_TOKEN=ghp_your_token_here
   AI_API_KEY=your_ai_api_key
   AI_API_ENDPOINT=https://api.anthropic.com/v1/messages
   AI_MODEL=claude-3-5-sonnet-20241022
   EOF

   # Load environment
   source .env
   ```

4. **Authenticate GitHub CLI:**
   ```bash
   gh auth login
   ```

---

## Cross-Platform Compatibility

All scripts are designed to work on:
- Linux (Ubuntu, Debian, RHEL, etc.)
- macOS (Intel and Apple Silicon)
- Windows (Git Bash, MSYS2, WSL)

**Key Features:**
- POSIX-compliant bash syntax
- Cross-platform path handling with `cygpath` on Windows
- No bashisms (works with sh, bash, zsh)
- Proper error handling with `set -euo pipefail`
- Color output detection (disabled on non-TTY)

---

## Error Handling

All scripts implement comprehensive error handling:

**Exit Codes:**
- `0` - Success
- `1` - General error
- `2` - Invalid arguments
- `3` - API error
- `4` - Invalid output

**Retry Logic:**
- Exponential backoff for API calls
- Configurable max retries (default: 3)
- Rate limiting awareness
- Timeout handling

**Logging:**
- All logs written to stderr
- Structured output to stdout
- Color-coded by severity
- Verbose mode available

---

## Integration with GitHub Actions

These scripts are designed to be called from GitHub Actions workflows:

```yaml
- name: Run AI Review
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    AI_API_KEY: ${{ secrets.AI_API_KEY }}
    AI_API_ENDPOINT: ${{ secrets.AI_API_ENDPOINT }}
  run: |
    ./scripts/ai-review.sh \
      --pr ${{ github.event.pull_request.number }} \
      --auto-post

- name: Run AI Agent
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    AI_API_KEY: ${{ secrets.AI_API_KEY }}
    AI_API_ENDPOINT: ${{ secrets.AI_API_ENDPOINT }}
  run: |
    ./scripts/ai-agent.sh \
      --issue ${{ github.event.issue.number }} \
      --task analyze \
      --auto-post

- name: Run Auto-Fix
  env:
    AI_API_KEY: ${{ secrets.AI_API_KEY }}
    AI_API_ENDPOINT: ${{ secrets.AI_API_ENDPOINT }}
  run: |
    ./scripts/ai-autofix.sh \
      --pr ${{ github.event.pull_request.number }} \
      --auto-commit
```

---

## Security Considerations

1. **Secret Management:**
   - Never commit API keys to repository
   - Use GitHub Secrets for CI/CD
   - Use `.env` files for local development (add to .gitignore)

2. **Input Validation:**
   - All user inputs are validated
   - PR numbers checked against regex
   - Path traversal prevented
   - JSON output validated

3. **API Security:**
   - HTTPS only for API calls
   - Authentication headers properly set
   - Rate limiting implemented
   - Timeout enforcement

4. **Code Execution:**
   - Scripts use `set -euo pipefail` for safety
   - No `eval` or dynamic code execution
   - Proper quoting of variables
   - shellcheck validated

---

## Testing

### Local Testing

```bash
# Test ai-review.sh
export GITHUB_TOKEN="your_token"
export AI_API_KEY="your_key"
export AI_API_ENDPOINT="https://api.anthropic.com/v1/messages"

./ai-review.sh --pr 123 --verbose

# Test with dry-run
./ai-autofix.sh --dry-run --verbose

# Test output validation
jq empty review.json && echo "Valid JSON" || echo "Invalid JSON"
```

### Validation Scripts

```bash
# Validate against schema
jq -e '. | has("event") and has("body")' review.json

# Check exit codes
./ai-review.sh --pr 123 && echo "Success" || echo "Failed: $?"

# Test error handling
./ai-review.sh --pr invalid 2>&1 | grep "Invalid PR number"
```

---

## Troubleshooting

### Common Issues

**1. "GitHub CLI not authenticated"**
```bash
# Solution: Authenticate
gh auth login
gh auth status
```

**2. "Missing required environment variables"**
```bash
# Solution: Export required vars
export GITHUB_TOKEN="..."
export AI_API_KEY="..."
export AI_API_ENDPOINT="..."
```

**3. "Command not found: jq"**
```bash
# Solution: Install jq
# macOS: brew install jq
# Linux: sudo apt install jq
# Windows: winget install jqlang.jq
```

**4. "AI API call failed"**
```bash
# Check API endpoint and key
curl -H "x-api-key: $AI_API_KEY" $AI_API_ENDPOINT

# Enable verbose logging
./ai-review.sh --pr 123 --verbose
```

**5. "Invalid JSON output"**
```bash
# Validate JSON syntax
jq empty review.json

# Check against schema
jq -e '. | has("event") and has("body")' review.json
```

**6. Windows Path Issues**
```bash
# Ensure using Git Bash or WSL
# Paths are automatically normalized by scripts

# Or use cygpath manually
cygpath -u "C:\path\to\file"
```

---

## Development

### Adding New Features

1. **Add to common.sh** for shared functionality
2. **Update schemas** if changing output format
3. **Document in README** with examples
4. **Test on all platforms** (Linux, macOS, Windows)
5. **Validate with shellcheck**

### Code Style

- POSIX-compliant syntax
- Use `readonly` for constants
- Quote all variables: `"${var}"`
- Use `[[ ]]` for conditionals
- Document functions with comments
- Error messages to stderr

### Testing Checklist

- [ ] Works on Linux
- [ ] Works on macOS
- [ ] Works on Windows Git Bash
- [ ] Proper error handling
- [ ] Valid JSON output
- [ ] Schema validation passes
- [ ] shellcheck clean
- [ ] Exit codes correct
- [ ] Logging appropriate
- [ ] Documentation updated

---

## Contributing

When contributing to these scripts:

1. Maintain POSIX compliance
2. Test on multiple platforms
3. Update documentation
4. Add usage examples
5. Validate with shellcheck
6. Follow existing code style
7. Include error handling
8. Write descriptive commit messages

---

## License

See repository LICENSE file.

---

## Support

For issues or questions:
1. Check troubleshooting section above
2. Run with `--verbose` for detailed logs
3. Validate environment variables
4. Check GitHub CLI authentication
5. Review API quotas and rate limits

---

**Version:** 1.0.0
**Last Updated:** 2025-10-17
**Maintainer:** Wave 3 python-pro specialist
