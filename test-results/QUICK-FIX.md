# Quick Fix Guide - Test 2.5 JSON Structure Mismatch

## Problem
The `ai-agent.sh` script outputs JSON that doesn't match what the `ai-issue-comment.yml` workflow expects.

## Current Output (WRONG)
```json
{
  "response": "Direct string content here...",
  "actions": [],
  "metadata": {...}
}
```

## Expected Output (CORRECT)
```json
{
  "response": {
    "body": "String content here...",
    "type": "comment",
    "suggested_labels": []
  },
  "metadata": {...}
}
```

## Fix Instructions

### File: `scripts/ai-agent.sh`
### Function: `format_response_output()` (Lines 307-339)

Replace the entire function with this corrected version:

```bash
# Format response output
format_response_output() {
    local ai_response="$1"
    local issue_number="$2"
    local model="$3"
    local task_type="$4"

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Escape the AI response for JSON
    local escaped_response
    escaped_response=$(echo "${ai_response}" | jq -Rs .)

    # Build suggested labels based on task type
    local suggested_labels="[]"
    if [[ "${task_type}" == "analyze" ]]; then
        suggested_labels='["analyzed"]'
    elif [[ "${task_type}" == "summarize" ]]; then
        suggested_labels='["needs-review"]'
    fi

    # Build JSON output with nested response object
    cat << EOF
{
  "response": {
    "body": ${escaped_response},
    "type": "comment",
    "suggested_labels": ${suggested_labels}
  },
  "metadata": {
    "model": "${model}",
    "timestamp": "${timestamp}",
    "issue_number": ${issue_number},
    "task_type": "${task_type}",
    "confidence": 0.85
  }
}
EOF
}
```

## Verification Steps

### 1. Apply the Fix
```bash
# Edit the file
nano scripts/ai-agent.sh

# Or create backup first
cp scripts/ai-agent.sh scripts/ai-agent.sh.backup
```

### 2. Test the Fix Locally
```bash
# Set up test environment variables
export GITHUB_TOKEN="your-token"
export AI_API_KEY="your-key"
export AI_API_ENDPOINT="https://api.anthropic.com/v1/messages"

# Run the script on a test issue
./scripts/ai-agent.sh --issue 1 --output /tmp/test-response.json

# Verify the JSON structure
jq '.' /tmp/test-response.json

# Check required fields
jq '.response.body' /tmp/test-response.json
jq '.response.type' /tmp/test-response.json
jq '.response.suggested_labels' /tmp/test-response.json
```

### 3. Expected Output
```
# Should return the response text
"String content here..."

# Should return
"comment"

# Should return
[]
```

## Testing Checklist

- [ ] Fix applied to scripts/ai-agent.sh
- [ ] Local JSON structure validation passes
- [ ] Script runs without errors
- [ ] Workflow parse step extracts correct values
- [ ] Comment posts successfully to test issue
- [ ] Test 2.5 re-executed and marked PASS

## Estimated Time
- Apply fix: 5 minutes
- Local testing: 10 minutes
- Workflow testing: 15 minutes
- **Total: 30 minutes**

---
Document Version: 1.0
Created: 2025-10-17