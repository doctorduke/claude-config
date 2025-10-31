#!/usr/bin/env bash
set -euo pipefail

# Delete .claude/logs files older than N days (default from config or 14)

ROOT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
LOG_DIR="$ROOT_DIR/.claude/logs"

if [ ! -d "$LOG_DIR" ]; then
  exit 0
fi

# Prefer reading config for retention_days
RET_DAYS=14
CFG="$ROOT_DIR/.claude/hooks/log-sanitizer.config.json"
if [ -f "$CFG" ] && command -v jq >/dev/null 2>&1; then
  v=$(jq -r '.retention_days // empty' "$CFG" 2>/dev/null || true)
  if [ -n "${v:-}" ]; then RET_DAYS="$v"; fi
fi

find "$LOG_DIR" -type f -mtime "+$RET_DAYS" -print -delete || true

