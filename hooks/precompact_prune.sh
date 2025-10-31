#!/usr/bin/env bash
set -euo pipefail

# PreCompact hook entrypoint (conservative, fail-open).
# Reads session JSON on stdin. Logs pruning intent and emits a short hint.
# Note: Without transformation support in the runtime, this does not mutate payloads.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRUNER="$SCRIPT_DIR/precompact_prune.py"

if ! command -v python3 >/dev/null 2>&1; then
  # Fail-open
  cat >/dev/null || true
  exit 0
fi

exec python3 "$PRUNER"

