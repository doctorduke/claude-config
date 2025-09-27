#!/usr/bin/env bash
set -euo pipefail

# Monorepo MCP setup script (skips Docker)
# - Re-adds/installs Playwright, ESLint, TypeScript, SQLite, Expo (optional)
# - Creates a local SQLite DB file
# - Verifies MCP connectivity

log() { printf "\033[1;34m[setup-mcps]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[setup-mcps]\033[0m %s\n" "$*"; }
err() { printf "\033[1;31m[setup-mcps]\033[0m %s\n" "$*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
DATA_DIR="$REPO/data"
SQLITE_DB="$DATA_DIR/local.sqlite"

# Ensure PATH includes common locations where claude may be installed
PATH_ADD=("/opt/homebrew/bin" "/usr/local/bin" "$HOME/.local/bin" "$HOME/bin")
for d in "${PATH_ADD[@]}"; do
  if [ -d "$d" ] && [[ ":$PATH:" != *":$d:"* ]]; then
    PATH="$d:$PATH"
  fi
done

CLAUDE_BIN="claude"

# Build a safe PATH that child processes can rely on (helps Claude-spawned servers find node/npx)
PATH_SAFE="/opt/homebrew/bin:/usr/local/bin:$PATH"

log "Repo root: $REPO"

# 1) Optional: source .env to pick up GITHUB_TOKEN if present
if [ -f "$REPO/.env" ]; then
  # shellcheck disable=SC1091
  . "$REPO/.env" || true
fi

# 2) Preflight: ensure node and npx are available
if ! command -v node >/dev/null 2>&1; then
  err "node is not installed or not in PATH. Install Node.js >= 18 and retry."
  exit 1
fi
if ! command -v npx >/dev/null 2>&1; then
  err "npx is not available. Ensure npm is installed and provides npx."
  exit 1
fi

# Warm-install required MCP packages so they are cached for spawns
REQ_PKGS=(
  "@playwright/mcp@latest"
  "@modelcontextprotocol/server-eslint"
  "@modelcontextprotocol/server-typescript"
  "@modelcontextprotocol/server-sqlite"
  "@modelcontextprotocol/server-filesystem"
  "@modelcontextprotocol/server-memory"
  "@modelcontextprotocol/server-github"
)
log "Warming MCP server packages via npx (this may take a minute on first run)"
for pkg in "${REQ_PKGS[@]}"; do
  npx -y "$pkg" --help >/dev/null 2>&1 || true
done

# 3) Remove broken or existing entries we will re-add
REMOVE_LIST=(playwright sqlite eslint typescript expo)
for srv in "${REMOVE_LIST[@]}"; do
  if "$CLAUDE_BIN" -p mcp list | grep -q "^$srv:"; then
    log "Removing existing MCP: $srv"
    if ! "$CLAUDE_BIN" -p mcp remove "$srv"; then
      warn "Could not remove $srv (continuing)"
    fi
  fi
done

# 4) SQLite MCP - create DB and point via env variable
log "Preparing SQLite database at $SQLITE_DB"
mkdir -p "$DATA_DIR"
if [ ! -f "$SQLITE_DB" ]; then
  : > "$SQLITE_DB"
fi

# 5) Playwright browsers (needed for Playwright MCP)
log "Installing Playwright browsers (this may take a minute)"
npx -y playwright install

# 6) Bulk add via add-json with a generated servers.json (user scope)
TMP_JSON="$SCRIPT_DIR/generated-servers.json"
GITHUB_ENV_BLOCK=""
if [ -n "${GITHUB_TOKEN:-}" ]; then
  GITHUB_ENV_BLOCK=",\n      \"env\": { \"GITHUB_TOKEN\": \"$GITHUB_TOKEN\" }"
fi
cat > "$TMP_JSON" <<JSON
[
  {"name":"playwright","json":{"type":"stdio","command":"npx","args":["-y","@playwright/mcp@latest"],"env":{"PATH":"$PATH_SAFE"}}},
  {"name":"eslint","json":{"type":"stdio","command":"npx","args":["-y","@modelcontextprotocol/server-eslint","$REPO"],"env":{"PATH":"$PATH_SAFE"}}},
  {"name":"typescript","json":{"type":"stdio","command":"npx","args":["-y","@modelcontextprotocol/server-typescript","$REPO"],"env":{"PATH":"$PATH_SAFE"}}},
  {"name":"sqlite","json":{"type":"stdio","command":"npx","args":["-y","@modelcontextprotocol/server-sqlite"],"env":{"PATH":"$PATH_SAFE","SQLITE_DB_PATH":"$SQLITE_DB"}}},
  {"name":"filesystem","json":{"type":"stdio","command":"npx","args":["-y","@modelcontextprotocol/server-filesystem","$REPO"],"env":{"PATH":"$PATH_SAFE"}}},
  {"name":"memory","json":{"type":"stdio","command":"npx","args":["-y","@modelcontextprotocol/server-memory"],"env":{"PATH":"$PATH_SAFE"}}},
  {"name":"github","json":{"type":"stdio","command":"npx","args":["-y","@modelcontextprotocol/server-github"],"env":{"PATH":"$PATH_SAFE"}${GITHUB_ENV_BLOCK}}}
]
JSON

if command -v jq >/dev/null 2>&1; then
  log "Bulk adding MCP servers from JSON (user scope)"
  jq -c '.[]' "$TMP_JSON" | while read -r srv; do
    name=$(echo "$srv" | jq -r '.name')
    spec=$(echo "$srv" | jq -c '.json')
    log "Adding $name"
    "$CLAUDE_BIN" -p mcp add-json --scope user "$name" "$spec"
    "$CLAUDE_BIN" -p mcp get "$name" >/dev/null || { err "Add failed: $name"; exit 1; }
  done
else
  warn "jq not found; falling back to direct add commands"
  "$CLAUDE_BIN" -p mcp add playwright --transport stdio npx  @playwright/mcp@latest
  "$CLAUDE_BIN" -p mcp add eslint --transport stdio npx  @modelcontextprotocol/server-eslint "$REPO"
  "$CLAUDE_BIN" -p mcp add typescript --transport stdio npx @modelcontextprotocol/server-typescript "$REPO"
  "$CLAUDE_BIN" -p mcp add sqlite --transport stdio -e SQLITE_DB_PATH="$SQLITE_DB" npx  @modelcontextprotocol/server-sqlite
  "$CLAUDE_BIN" -p mcp add filesystem --transport stdio npx  @modelcontextprotocol/server-filesystem "$REPO"
  "$CLAUDE_BIN" -p mcp add memory --transport stdio npx  @modelcontextprotocol/server-memory
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    "$CLAUDE_BIN" -p mcp add github --transport stdio -e GITHUB_TOKEN="$GITHUB_TOKEN" npx -y @modelcontextprotocol/server-github
  else
    "$CLAUDE_BIN" -p mcp add github --transport stdio npx -y @modelcontextprotocol/server-github || true
  fi
fi

# 7) Expo MCP (optional) - only add if expo CLI is reachable
if npx -y expo --version >/dev/null 2>&1; then
  log "Adding Expo MCP"
  "$CLAUDE_BIN" -p mcp add expo --transport stdio npx -y @modelcontextprotocol/server-expo "$REPO/platforms/mobile"
else
  warn "Expo CLI not found; skipping Expo MCP"
fi

## HACKS left to do it manually. This script may be needed at some point though.
# 8) Verify connectivity
log "Verifying MCP connectivity"
"$CLAUDE_BIN" -p mcp list | sed 's/^/  /'

log "Done. If any server shows 'Failed to connect', re-run this script after addressing its prerequisite."

/Users/doctorduke/Developer/doctorduke/umemee-v0
claude mcp add filesystem --transport stdio npx  @modelcontextprotocol/server-filesystem /Users/doctorduke/Developer/doctorduke/umemee-v0
claude mcp add memory --transport stdio npx  @modelcontextprotocol/server-memory
claude mcp add github --transport stdio -e GITHUB_TOKEN=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 npx -y @modelcontextprotocol/server-github
claude mcp add vercel --transport stdio npx @modelcontextprotocol/server-vercel /Users/doctorduke/Developer/doctorduke/umemee-v0/platforms/web

claude mcp add eslint --transport stdio npx  @eslint/mcp /Users/doctorduke/Developer/doctorduke/umemee-v0
claude mcp add typescript --transport stdio npx @modelcontextprotocol/server-typescript /Users/doctorduke/Developer/doctorduke/umemee-v0
claude mcp add sqlite --transport stdio -e SQLITE_DB_PATH=/Users/doctorduke/Developer/doctorduke/umemee-v0/data/local.sqlite npx  @modelcontextprotocol/server-sqlite
claude mcp add expo --transport stdio npx  @modelcontextprotocol/server-expo /Users/doctorduke/Developer/doctorduke/umemee-v0/platforms/mobile
