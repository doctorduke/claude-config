#!/bin/bash
# PostToolUse Hook: Sanitize Bash Command Output
# Automatically sanitizes verbose command outputs before Claude sees them

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$HOOK_DIR")"
LIB_DIR="$PROJECT_DIR/lib"

# Read JSON input from stdin
input=$(cat)

# Extract command and output using jq
command=$(echo "$input" | jq -r '.tool_input.command // ""')
output=$(echo "$input" | jq -r '.tool_output.output // ""')

# Skip if no output
if [[ -z "$output" ]]; then
    exit 0
fi

# Save raw output to log file
timestamp=$(date +%Y%m%d_%H%M%S)
safe_cmd=$(echo "$command" | tr ' /' '__' | tr -cd '[:alnum:]_-' | cut -c1-50)
log_file="$PROJECT_DIR/logs/${timestamp}_${safe_cmd}.log"
echo "$output" > "$log_file"

# Detect parser type from command
parser_type="generic"
if echo "$command" | grep -q "npm"; then
    parser_type="npm"
elif echo "$command" | grep -q "node"; then
    parser_type="node"
elif echo "$command" | grep -qE "python|python3|pip"; then
    parser_type="python"
fi

# Sanitize output
source "$LIB_DIR/filters/ansi_strip.sh"
cleaned=$(echo "$output" | strip_ansi)

# Apply parser
if [[ -f "$LIB_DIR/parsers/${parser_type}_parser.sh" ]]; then
    sanitized=$(echo "$cleaned" | "$LIB_DIR/parsers/${parser_type}_parser.sh")
else
    sanitized=$(echo "$cleaned" | "$LIB_DIR/parsers/generic_parser.sh")
fi

# Calculate token savings
original_tokens=$(echo "$output" | wc -w)
sanitized_tokens=$(echo "$sanitized" | wc -w)
savings=$((original_tokens - sanitized_tokens))
savings_pct=$((savings * 100 / (original_tokens + 1)))

# Output sanitized version with metadata
cat << EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
��� SANITIZED OUTPUT (${savings_pct}% token reduction)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$sanitized

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
��� Original: ${original_tokens} tokens | Sanitized: ${sanitized_tokens} tokens
��� Full log: $log_file
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF

exit 0
