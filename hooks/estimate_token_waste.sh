#!/bin/bash
set -euo pipefail
# PreToolUse Hook: Estimate Token Waste
# Warns or blocks commands that will generate excessive output

# Read JSON input
input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // ""')

# High-waste command patterns
declare -A WASTE_PATTERNS=(
    ["npm install"]="5000"
    ["npm update"]="4000"
    ["npm ci"]="5000"
    ["npm audit"]="3000"
    ["npm list"]="2000"
    ["cargo build --verbose"]="10000"
    ["make V=1"]="8000"
)

# Check for high-waste commands
for pattern in "${!WASTE_PATTERNS[@]}"; do
    if echo "$command" | grep -q "$pattern"; then
        estimated_tokens="${WASTE_PATTERNS[$pattern]}"
        
        # Check if command has quieting flags
        if echo "$command" | grep -qE -- "--silent|--quiet|-q|--no-verbose"; then
            # Command already optimized, allow it
            exit 0
        fi
        
        # Warn but don't block (exit 0 = allow, exit 2 = block)
        # For now, just warn - user can configure to block
        cat << EOF

⚠️  TOKEN WASTE WARNING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Command: $command
Estimated output: ~${estimated_tokens} tokens

��� Suggestion: Add --silent or --quiet flag to reduce output by 70-80%

Example: ${command} --silent
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
        # Allow command to proceed (PostToolUse will sanitize)
        exit 0
    fi
done

# Command is fine, allow it
exit 0
