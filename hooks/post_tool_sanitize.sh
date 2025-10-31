#!/usr/bin/env bash
set -euo pipefail

# PostToolUse hook entrypoint.
# Reads event JSON on stdin and produces a concise summary while persisting raw logs.
# Delegates to log_sanitizer.py for the heavy lifting.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SANITIZER="$SCRIPT_DIR/log_sanitizer.py"

if ! command -v python3 >/dev/null 2>&1; then
  echo "log-sanitizer: python3 not found; skipping sanitization." 1>&2
  # Pass stdin through (no-op) to avoid breaking the hook pipeline
  cat >/dev/null || true
  exit 0
fi

exec python3 "$SANITIZER"

