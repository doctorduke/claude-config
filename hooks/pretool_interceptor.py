#!/usr/bin/env python3
"""
Claude Code PreToolUse interceptor.

Goal: For noisy GitHub CLI calls (gh pr view / gh issue view), block and suggest
using compact scripts instead, unless explicitly bypassed.

Behavior:
- Reads event JSON from stdin, extracts tool_input.command if present.
- If command matches patterns and no bypass flag, prints a concise instruction
  with a replacement command and exits with code 2 (block) to let Claude
  reroute.
- Fail-open otherwise: exit 0 without output.
"""
import json
import os
import re
import subprocess
import sys
from typing import Optional, Tuple


def read_event() -> dict:
    try:
        return json.load(sys.stdin)
    except Exception:
        return {}


def get_command(evt: dict) -> str:
    ti = evt.get("tool_input") or evt.get("toolInput") or {}
    cmd = ti.get("command") or ti.get("args") or ""
    return str(cmd)


def has_bypass(cmd: str) -> bool:
    if os.environ.get("CLAUDE_PRETOOL_ALLOW_RAW") == "1":
        return True
    return any(tok in cmd for tok in ["--no-compact", "--raw", "NO_COMPACT", "RAW:"])


def resolve_repo() -> Optional[str]:
    try:
        proc = subprocess.run(
            ["gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"],
            capture_output=True,
            text=True,
            check=False,
        )
        if proc.returncode == 0:
            return proc.stdout.strip()
    except Exception:
        pass
    return None


def parse_target(cmd: str) -> Tuple[Optional[str], Optional[str], Optional[int]]:
    # Return (kind, repo, number) where kind in {"pr","issue"}
    # Try to extract explicit --repo
    repo = None
    mrepo = re.search(r"--repo\s+([\w_.-]+/[\w_.-]+)", cmd)
    if mrepo:
        repo = mrepo.group(1)
    # GH PR
    mpr = re.search(r"\bgh\s+pr\s+view\s+(\d+)", cmd)
    if mpr:
        return "pr", repo, int(mpr.group(1))
    # GH Issue
    mis = re.search(r"\bgh\s+issue\s+view\s+(\d+)", cmd)
    if mis:
        return "issue", repo, int(mis.group(1))
    return None, repo, None


def main() -> int:
    evt = read_event()
    cmd = get_command(evt)
    tool = (evt.get("tool") or evt.get("tool_name") or "").lower()

    if tool and tool not in ("bash", "shell", "sh"):
        return 0
    if not cmd or "gh " not in cmd:
        return 0
    if has_bypass(cmd):
        return 0

    kind, repo, number = parse_target(cmd)
    if kind not in ("pr", "issue"):
        return 0

    if not repo:
        repo = resolve_repo() or "<owner/name>"

    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", ".")
    if kind == "pr" and number:
        replacement = f"\"{project_dir}\"/tools/gh-compact/gh-pr-compact --repo {repo} --pr {number}"
        msg = (
            "GitHub PR view intercepted. Prefer compact summary to reduce tokens.\n"
            f"Run instead:\n{replacement}\n\n"
            "To bypass once, append --no-compact (or set CLAUDE_PRETOOL_ALLOW_RAW=1)."
        )
    elif kind == "issue" and number:
        # If issue compact tool exists, suggest it; otherwise minimal view
        issue_tool = os.path.join(project_dir, "tools", "gh-compact", "gh-issue-compact")
        if os.path.exists(issue_tool):
            replacement = f"\"{project_dir}\"/tools/gh-compact/gh-issue-compact --repo {repo} --issue {number}"
        else:
            replacement = f"gh issue view {number} --repo {repo} --json number,title,state,author,labels,assignees,updatedAt --jq ."
        msg = (
            "GitHub Issue view intercepted. Prefer compact summary to reduce tokens.\n"
            f"Run instead:\n{replacement}\n\n"
            "To bypass once, append --no-compact (or set CLAUDE_PRETOOL_ALLOW_RAW=1)."
        )
    else:
        return 0

    # Print guidance and block original tool call
    print(msg)
    # Exit 2 signals block per hooks example
    sys.exit(2)


if __name__ == "__main__":
    try:
        main()
    except SystemExit as e:
        raise
    except Exception:
        # Fail-open
        sys.exit(0)

