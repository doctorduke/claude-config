#!/usr/bin/env bash
set -euo pipefail

# PreToolUse hook that intercepts verbose GH CLI calls and suggests compact alternatives.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXEC="$SCRIPT_DIR/pretool_interceptor.py"

if ! command -v python3 >/dev/null 2>&1; then
  # No Python — do not block
  cat >/dev/null || true
  exit 0
fi

exec python3 "$EXEC"

