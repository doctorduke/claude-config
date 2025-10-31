# AI Agent Scripts - Quick Start Guide

Fast-track guide to using the Wave 3 AI agent scripts.

---

## Prerequisites (2 minutes)

```bash
# 1. Install GitHub CLI
# macOS: brew install gh
# Linux: sudo apt install gh
# Windows: winget install GitHub.cli

# 2. Install jq
# macOS: brew install jq
# Linux: sudo apt install jq
# Windows: winget install jqlang.jq

# 3. Authenticate GitHub CLI
gh auth login
```

---

## Setup (1 minute)

```bash
# 1. Make scripts executable
chmod +x scripts/ai-*.sh

# 2. Set environment variables
export GITHUB_TOKEN="ghp_your_token_here"
export AI_API_KEY="your_anthropic_or_openai_key"
export AI_API_ENDPOINT="https://api.anthropic.com/v1/messages"
# For OpenAI: https://api.openai.com/v1/chat/completions
```

---

## Quick Usage

### 1. AI Code Review

```bash
# Review a pull request
./scripts/ai-review.sh --pr 123

# Output: review.json

# Review and auto-post to GitHub
./scripts/ai-review.sh --pr 123 --auto-post

# Use specific model
./scripts/ai-review.sh --pr 123 --model claude-3-opus
```

### 2. AI Issue Agent

```bash
# Respond to an issue
./scripts/ai-agent.sh --issue 456

# Output: response.json

# Summarize discussion
./scripts/ai-agent.sh --issue 456 --task summarize --auto-post

# Analyze issue
./scripts/ai-agent.sh --issue 456 --task analyze

# Suggest solutions
./scripts/ai-agent.sh --issue 456 --task suggest
```

### 3. AI Auto-Fix

```bash
# Fix code in current directory
./scripts/ai-autofix.sh

# Preview fixes (dry-run)
./scripts/ai-autofix.sh --dry-run

# Fix specific path
./scripts/ai-autofix.sh --path src/

# Fix and commit
./scripts/ai-autofix.sh --auto-commit

# Use specific tools
./scripts/ai-autofix.sh --tools eslint,prettier
```

---

## Common Options

All scripts support:
- `--verbose` - Enable debug logging
- `--help` - Show detailed help
- `--model MODEL` - Specify AI model

---

## Output Files

- **ai-review.sh** → `review.json` (structured PR review)
- **ai-agent.sh** → `response.json` (issue response)
- **ai-autofix.sh** → Modified files + optional commit

---

## Troubleshooting

**Problem:** "GitHub CLI not authenticated"
```bash
gh auth login
```

**Problem:** "Command not found: jq"
```bash
# macOS: brew install jq
# Linux: sudo apt install jq
```

**Problem:** "Missing API key"
```bash
export AI_API_KEY="your_key_here"
export AI_API_ENDPOINT="your_endpoint_here"
```

**Problem:** "Invalid JSON output"
```bash
# Validate output
jq empty review.json

# Enable verbose mode
./scripts/ai-review.sh --pr 123 --verbose
```

---

## GitHub Actions Integration

```yaml
- name: AI Code Review
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    AI_API_KEY: ${{ secrets.AI_API_KEY }}
    AI_API_ENDPOINT: ${{ secrets.AI_API_ENDPOINT }}
  run: |
    ./scripts/ai-review.sh \
      --pr ${{ github.event.pull_request.number }} \
      --auto-post
```

---

## Examples

### Example 1: Review PR with specific settings
```bash
./scripts/ai-review.sh \
  --pr 123 \
  --model claude-3-5-sonnet-20241022 \
  --output my-review.json \
  --max-files 50 \
  --verbose
```

### Example 2: Analyze bug report
```bash
./scripts/ai-agent.sh \
  --issue 789 \
  --task analyze \
  --auto-post
```

### Example 3: Auto-fix with constraints
```bash
./scripts/ai-autofix.sh \
  --pr 456 \
  --path src/ \
  --max-fixes 5 \
  --tools eslint,prettier \
  --dry-run
```

---

## API Providers

### Anthropic Claude
```bash
export AI_API_ENDPOINT="https://api.anthropic.com/v1/messages"
export AI_API_KEY="sk-ant-..."
export AI_MODEL="claude-3-5-sonnet-20241022"
```

### OpenAI
```bash
export AI_API_ENDPOINT="https://api.openai.com/v1/chat/completions"
export AI_API_KEY="sk-..."
export AI_MODEL="gpt-4"
```

---

## Exit Codes

- `0` - Success
- `1` - General error
- `2` - Invalid arguments
- `3` - API error
- `4` - Invalid output

---

## Performance

- PR review: 30-120 seconds (depends on size and API)
- Issue response: 20-60 seconds
- Auto-fix: 10-300 seconds (depends on files)

---

## Getting Help

```bash
# Detailed help for each script
./scripts/ai-review.sh --help
./scripts/ai-agent.sh --help
./scripts/ai-autofix.sh --help

# Full documentation
cat scripts/README.md
```

---

## Next Steps

1. **Read full documentation:** `scripts/README.md`
2. **Review JSON schemas:** `scripts/schemas/`
3. **Check GitHub Actions examples:** Documentation section
4. **Run validation:** `./scripts/validate-ai-scripts.sh`

---

**Quick Reference:**
- ai-review.sh: PR reviews
- ai-agent.sh: Issue responses
- ai-autofix.sh: Code fixes
- lib/common.sh: Shared utilities
- schemas/: JSON output formats

**For issues:** Enable `--verbose` and check logs
