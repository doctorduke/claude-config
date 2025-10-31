#!/bin/bash
set -euo pipefail
# PreToolUse Hook: Estimate Token Waste
# Warns or blocks commands that will generate excessive output

# Read JSON input
input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // ""')

# Source configuration from thresholds.conf
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config/thresholds.conf"

# High-waste command patterns (loaded from config or defaults)
declare -A WASTE_PATTERNS=()

# Load configuration if it exists
if [[ -f "$CONFIG_FILE" ]]; then
    # Source the config file to get HIGH_WASTE_COMMANDS array
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
    
    # Convert HIGH_WASTE_COMMANDS array to associative array
    for entry in "${HIGH_WASTE_COMMANDS[@]:-}"; do
        if [[ "$entry" == *":"* ]]; then
            pattern="${entry%%:*}"
            tokens="${entry##*:}"
            WASTE_PATTERNS["$pattern"]="$tokens"
        fi
    done
fi

# Fallback to defaults if config not available or empty
if [[ ${#WASTE_PATTERNS[@]} -eq 0 ]]; then
    WASTE_PATTERNS=(
        ["npm install"]="5000"
        ["npm update"]="4000"
        ["npm ci"]="5000"
        ["npm audit"]="3000"
        ["npm list"]="2000"
        ["cargo build --verbose"]="10000"
        ["make V=1"]="8000"
    )
fi

# Check for high-waste commands
for pattern in "${!WASTE_PATTERNS[@]}"; do
    if echo "$command" | grep -q "$pattern"; then
        estimated_tokens="${WASTE_PATTERNS[$pattern]}"
        
        # Check if command has quieting flags
        QUIET_FLAGS_STR="${QUIET_FLAGS[*]:-"--silent --quiet -q --no-verbose"}"
        if echo "$command" | grep -qE -- "${QUIET_FLAGS_STR// /|\\|}"; then
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

���💡 Suggestion: Add --silent or --quiet flag to reduce output by 70-80%

Example: ${command} --silent
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
        # Allow command to proceed (PostToolUse will sanitize)
        exit 0
    fi
done

# Command is fine, allow it
exit 0
