#!/bin/bash
set -euo pipefail
# PostToolUse Hook: Sanitize Bash Command Output
# DEPRECATED: This script is deprecated in favor of post_tool_sanitize.sh -> log_sanitizer.py
# This wrapper exists for backwards compatibility and delegates to the Python implementation.
# Please update your hooks to use: .claude/hooks/post_tool_sanitize.sh

# Redirect to the Python-based sanitizer
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SANITIZER="$SCRIPT_DIR/log_sanitizer.py"
BASH_WRAPPER="$SCRIPT_DIR/post_tool_sanitize.sh"

# Prefer the wrapper script, fall back to direct Python call
if [[ -f "$BASH_WRAPPER" ]]; then
    exec "$BASH_WRAPPER"
elif [[ -f "$PYTHON_SANITIZER" ]] && command -v python3 >/dev/null 2>&1; then
    exec python3 "$PYTHON_SANITIZER"
else
    echo "log-sanitizer: post_tool_sanitize.sh or log_sanitizer.py not found; skipping sanitization." 1>&2
    # Pass stdin through (no-op) to avoid breaking the hook pipeline
    cat >/dev/null || true
    exit 0
fi
