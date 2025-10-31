#!/bin/bash
# SessionEnd Hook: Cleanup and report
# Cleans up old logs and reports session statistics

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$HOOK_DIR")"

# Clean up old logs (keep last 7 days)
find "$PROJECT_DIR/logs" -type f -name "*.log" -mtime +7 -delete 2>/dev/null

# Report session statistics if available
if [[ -f "$PROJECT_DIR/cache/current_session" ]]; then
    SESSION_ID=$(cat "$PROJECT_DIR/cache/current_session")
    STATS_FILE="$PROJECT_DIR/cache/$SESSION_ID/stats.json"
    
    if [[ -f "$STATS_FILE" ]]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
        echo "��� Log Sanitization Session Summary" >&2
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
        cat "$STATS_FILE" >&2
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    fi
fi

exit 0
