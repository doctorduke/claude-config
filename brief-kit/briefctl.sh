#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
T="$ROOT/brief-kit/templates"
BIN="$ROOT/scripts/brief"
mkdir -p "$BIN" "$ROOT/_reference/adr" "$ROOT/_reference/diagrams"

say() { printf "%b\n" "$*"; }
copy_if_absent() { [ -e "$2" ] || { mkdir -p "$(dirname "$2")"; cp "$1" "$2"; say "  + $2"; }; }

detect_ci() {
  if [ -d "$ROOT/.github" ] || [ -n "${GITHUB_ACTIONS-}" ]; then echo "github"; return; fi
  if [ -e "$ROOT/.gitlab-ci.yml" ] || [ -n "${GITLAB_CI-}" ]; then echo "gitlab"; return; fi
  if [ -e "$ROOT/azure-pipelines.yml" ]; then echo "azure"; return; fi
  if [ -e "$ROOT/bitbucket-pipelines.yml" ]; then echo "bitbucket"; return; fi
  echo "github" # default sensible choice
}

seed_brief() {
  local dest="$1"
  if [ ! -f "$dest" ]; then
    sed "s/{{DATE}}/$(date +%F)/" "$T/BRIEF.md.tmpl" > "$dest"
    say "  + $dest"
  else
    say "  = $dest (exists)"
  fi
}

seed_cursor_rules() {
  mkdir -p "$ROOT/.cursor/rules"
  copy_if_absent "$T/cursor/rules/briefs.mdc.tmpl" "$ROOT/.cursor/rules/briefs.mdc"
}

seed_ci() {
  local ci; ci="$(detect_ci)"
  case "$ci" in
    github)
      mkdir -p "$ROOT/.github/workflows"
      copy_if_absent "$T/ci/github.yml.tmpl" "$ROOT/.github/workflows/brief-ci.yml"
      ;;
    gitlab)
      copy_if_absent "$T/ci/gitlab.yml.tmpl" "$ROOT/.gitlab-ci.yml"
      ;;
    azure)
      copy_if_absent "$T/ci/azure.yml.tmpl" "$ROOT/azure-pipelines.yml"
      ;;
    bitbucket)
      copy_if_absent "$T/ci/bitbucket.yml.tmpl" "$ROOT/bitbucket-pipelines.yml"
      ;;
  esac
  say "  -> CI detected: $ci"
}

seed_configs() {
  copy_if_absent "$T/configs/markdownlint.jsonc.tmpl" "$ROOT/.markdownlint.jsonc"
  copy_if_absent "$T/configs/mlc_config.json.tmpl" "$ROOT/mlc_config.json"
  copy_if_absent "$T/configs/vale.ini.tmpl" "$ROOT/.vale.ini"
}

seed_gate() {
  copy_if_absent "$T/scripts/brief/check-brief.sh.tmpl" "$BIN/check-brief.sh"
  chmod +x "$BIN/check-brief.sh"
}

seed_briefs_for_subprojects() {
  # Heuristic: common “module roots”
  mapfile -t mods < <(git ls-files ':!:**/node_modules/**' \
    | grep -E '(^|/)(package\.json|Dockerfile|requirements\.txt|pyproject\.toml|pom\.xml|build\.gradle|Cargo\.toml|go\.mod)$' \
    | xargs -I{} dirname "{}" | sort -u)
  for m in "${mods[@]:-}"; do
    [ "$m" = "." ] && continue
    [ -d "$ROOT/$m" ] || continue
    seed_brief "$ROOT/$m/BRIEF.md"
  done
}

cmd="${1:-help}"
case "$cmd" in
  init)
    say "Seeding BRIEF system..."
    seed_brief "$ROOT/BRIEF.md"
    copy_if_absent "$T/briefignore.tmpl" "$ROOT/.briefignore"
    seed_configs
    seed_gate
    seed_cursor_rules
    seed_ci
    seed_briefs_for_subprojects
    say "Done. Commit changes and push to run CI."
    ;;
  verify)
    bash "$BIN/check-brief.sh"
    ;;
  uninstall)
    say "Manual uninstall recommended (files are safe to delete)."
    ;;
  *)
    say "Usage: $0 {init|verify|uninstall}"
    ;;
esac
