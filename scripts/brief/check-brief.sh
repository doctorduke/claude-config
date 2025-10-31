#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "BRIEF CHECK FAILED: $1"; exit 2; }
targets=$(git ls-files | grep -E '/?BRIEF\.md$' || true)
[ -z "$targets" ] && fail "No BRIEF.md found (root or modules)."
for f in $targets; do
  grep -q '^## Interface Contract' "$f" || fail "$f missing Interface Contract"
  grep -Eq '^## Spec Snapshot \([0-9]{4}-[0-9]{2}-[0-9]{2}\)$' "$f" || fail "$f needs dated Spec Snapshot (YYYY-MM-DD)"
  grep -q '^## Local Reference Index' "$f" || fail "$f missing Local Reference Index"
  grep -q '^## Answer Pack' "$f" || fail "$f missing Answer Pack"
  [ "$(wc -l < "$f")" -le "${BRIEF_MAX_LINES:-200}" ] || fail "$f too long; keep ≤200 lines"
  ! grep -q 'INFERRED:' "$f" || fail "$f has INFERRED: markers; resolve"
done
echo "BRIEF CHECK OK"
