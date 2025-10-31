Log Sanitization via Claude Hooks

Overview
- Goal: Cut token waste by replacing verbose tool outputs with concise summaries while always saving full raw logs to disk.
- Scope: Works across most tools via PostToolUse hooks in Claude Code. No changes to agent scripts.

Files
- `.claude/hooks/post_tool_sanitize.sh`: Hook entrypoint (Bash), calls the Python sanitizer.
- `.claude/hooks/log_sanitizer.py`: Reads event JSON, saves raw output to `.claude/logs/`, emits a short summary.
- `.claude/hooks/config.examples/log-sanitization-posttooluse.json`: Example hook configuration snippet.
- `.claude/hooks/log-sanitizer.config.json`: Config to tune limits, masking, and retention.
- `.claude/hooks/precompact_prune.sh` + `precompact_prune.py`: Optional PreCompact hook stub that reports oversized payloads before compaction.
- `.claude/hooks/config.examples/precompact.json`: Example config to register PreCompact hook.

Install
1) Ensure Python 3 is available in your shell.
2) Make the Bash hook executable:
   `chmod +x .claude/hooks/post_tool_sanitize.sh`
3) Register a PostToolUse hook in Claude Code (REPL: `/hooks` → PostToolUse):
   Use the JSON from `.claude/hooks/config.examples/log-sanitization-posttooluse.json` or add a matcher for `Bash` and set the command to:
   `"$CLAUDE_PROJECT_DIR"/.claude/hooks/post_tool_sanitize.sh`

How it works
- After any tool call finishes, the hook receives the event payload on stdin.
- The sanitizer:
  - Extracts the tool name, command, and output (stdout/stderr, best effort).
  - Saves the full raw output under `.claude/logs/<timestamp>-<tool>-<hash>.log`.
- Produces a deterministic summary: error blocks, warning aggregates, and a raw log pointer.
  - Prints only the compact summary, which Claude includes instead of the full raw stream.

Notes
- This is deterministic and script-based (no LLMs invoked) to keep costs down.
- The sanitizer uses conservative, multi-tool regexes and caps snippets to keep responses small.
- If a tool emits little or no output, the hook emits nothing.

Extending
- Tool-specific support included: npm, node, tsc (TypeScript), jest, python, eslint, and pytest with structured extraction.
- To add more tools, extend `log_sanitizer.py` by:
  - Adding a detector in `detect_tool_family`
  - Implementing an `extract_<tool>()` that returns `{ errors: [...], warnings: [...] }`
  - Returning short `raw` snippets and structured fields like `file`, `line`, `code`, `frames`
- If you want stronger guarantees, pair this with a PreToolUse command wrapper that routes executions through a sanitizer-aware runner (future phase).

Configuration
- Edit `.claude/hooks/log-sanitizer.config.json` to adjust:
  - `mask_secrets` (default true): mask common secrets in summaries
  - `mask_in_raw` (default false): also mask before saving raw logs
  - `limits.max_errors`, `limits.max_error_snippet_lines`, `limits.warn_cap`, `limits.dupes_cap`, `limits.max_line_len`

PreCompact Hook
- Register the PreCompact stub using the example in `config.examples/precompact.json`.
- Current behavior is conservative: it does not mutate payloads, but emits a short hint. If Claude Code adds payload-transformation support in PreCompact hooks, switch it to replace large tool outputs with sanitized summaries before compaction.
