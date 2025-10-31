#!/bin/bash
# SessionStart Hook: Initialize session
# Sets up cache and environment for the session

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$HOOK_DIR")"

# Create session cache directory
SESSION_ID=$(date +%Y%m%d_%H%M%S)
CACHE_DIR="$PROJECT_DIR/cache/$SESSION_ID"
mkdir -p "$CACHE_DIR"

# Save session ID for other hooks
echo "$SESSION_ID" > "$PROJECT_DIR/cache/current_session"

# Initialize statistics
cat > "$CACHE_DIR/stats.json" << 'EOFJSON'
{
  "session_start": "'"$(date -Iseconds)"'",
  "commands_processed": 0,
  "tokens_saved": 0,
  "original_tokens": 0
}
EOFJSON

echo "✓ Log sanitization session initialized: $SESSION_ID" >&2

exit 0
