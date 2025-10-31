#!/usr/bin/env python3
"""
Conservative PreCompact hook stub.
- Reads session JSON on stdin, scans for oversized tool_result outputs.
- Emits a short, human-readable hint to stdout about pruning and where raw logs live.
- Does not attempt to mutate the runtime payload (fail-open behavior).
"""
import json
import os
import sys


def main() -> int:
    try:
        data = sys.stdin.read()
        obj = json.loads(data)
    except Exception:
        return 0

    # Best-effort scan
    oversized = 0
    threshold = int(os.environ.get("CLAUDE_PRECOMPACT_THRESHOLD", "50000"))  # ~50k chars

    def walk(x):
        nonlocal oversized
        if isinstance(x, dict):
            # common shape: {tool_result: {output: str}}
            tr = x.get("tool_result") or x.get("toolResult")
            if isinstance(tr, dict):
                out = tr.get("output") or tr.get("stdout") or tr.get("content") or tr.get("text")
                if isinstance(out, str) and len(out) > threshold:
                    oversized += 1
            for v in x.values():
                walk(v)
        elif isinstance(x, list):
            for v in x:
                walk(v)

    walk(obj)

    if oversized:
        print(f"[PreCompact] {oversized} oversized tool outputs detected. Using sanitized summaries; raw logs saved under .claude/logs/.")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        sys.exit(0)

