#!/usr/bin/env python3
"""
Claude Code PostToolUse log sanitizer.

Behavior:
- Read event JSON from stdin (best effort schema: tool/tool_input/tool_result).
- Persist full raw tool output to .claude/logs with a stable filename.
- Produce a concise, deterministic summary suitable for LLM consumption.
- Emit only the short summary to stdout to reduce token usage.

Notes:
- Purely script-based sanitization (no LLM calls).
- Keeps a JSON metadata artifact alongside raw logs for later retrieval.
"""
import os
import re
import sys
import json
import hashlib
import datetime as dt
from typing import Dict, Any, Tuple


ANSI_RE = re.compile(r"\x1b\[[0-9;?]*[A-Za-z]")
NODE_STACK_RE_1 = re.compile(r"^\s*at\s+(.+?) \((.*?):(\d+):(\d+)\)\s*$")
NODE_STACK_RE_2 = re.compile(r"^\s*at\s+(.*?):(\d+):(\d+)\s*$")
TS_ERROR_RE = re.compile(r"^(.+\.(?:ts|tsx)):(\d+):(\d+) - error TS(\d+): (.+)$")
JEST_FAIL_RE = re.compile(r"^FAIL\s+(.+)$")
PY_TRACE_START_RE = re.compile(r"^Traceback \(most recent call last\):\s*$")
PY_FRAME_RE = re.compile(r"^\s*File \"(.+?)\", line (\d+), in (.+?)\s*$")
PY_EXC_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):\s+(.+)$")
WARN_RE = re.compile(r"\b(warn|warning|npm WARN)\b", re.IGNORECASE)


def read_event(stdin: str) -> Dict[str, Any]:
    try:
        return json.loads(stdin)
    except Exception:
        # Fallback: if the hook runtime changes schema or content, don't break
        return {}


def extract_fields(evt: Dict[str, Any]) -> Tuple[str, str, str]:
    tool = (
        evt.get("tool")
        or evt.get("tool_name")
        or evt.get("name")
        or evt.get("toolInput", {}).get("name")
        or evt.get("tool_input", {}).get("name")
        or "unknown"
    )
    # Best-effort command string
    cmd = (
        (evt.get("tool_input") or {}).get("command")
        or (evt.get("toolInput") or {}).get("command")
        or (evt.get("tool_input") or {}).get("args")
        or (evt.get("toolInput") or {}).get("args")
        or ""
    )
    # Best-effort output
    tool_result = evt.get("tool_result") or evt.get("toolResult") or {}
    output = (
        tool_result.get("output")
        or tool_result.get("stdout")
        or tool_result.get("content")
        or tool_result.get("text")
        or ""
    )
    if isinstance(output, (list, dict)):
        try:
            output = json.dumps(output, ensure_ascii=False)
        except Exception:
            output = str(output)
    return str(tool), str(cmd), str(output)


def strip_ansi(s: str) -> str:
    return ANSI_RE.sub("", s)


def squash_progress(s: str) -> str:
    # Replace carriage-return style progress with final line
    s = s.replace("\r\n", "\n").replace("\r", "\n")
    lines = [ln for ln in s.splitlines() if ln.strip()]
    return "\n".join(lines)


def collapse_duplicates(lines, max_dupes=3):
    out = []
    last = None
    count = 0
    for ln in lines:
        if ln == last:
            count += 1
            if count <= max_dupes:
                out.append(ln)
            elif count == max_dupes + 1:
                out.append(f"[... {count- max_dupes} similar lines omitted ...]")
        else:
            last = ln
            count = 1
            out.append(ln)
    return out


def trim_long_lines(lines, max_len=500):
    out = []
    for ln in lines:
        if len(ln) > max_len:
            out.append(ln[:max_len] + " â€¦ [truncated]")
        else:
            out.append(ln)
    return out


def load_config(cwd: str) -> Dict[str, Any]:
    candidates = [
        os.path.join(cwd, ".claude", "hooks", "log-sanitizer.config.json"),
        os.path.join(os.path.dirname(__file__), "log-sanitizer.config.json"),
    ]
    cfg = {
        "mask_secrets": True,
        "mask_in_raw": False,
        "retention_days": 14,
        "limits": {
            "max_errors": 5,
            "max_error_snippet_lines": 6,
            "warn_cap": 10,
            "dupes_cap": 3,
            "max_line_len": 500,
        },
    }
    for p in candidates:
        try:
            if os.path.exists(p):
                with open(p, "r", encoding="utf-8") as f:
                    user_cfg = json.load(f)
                cfg.update({k: v for k, v in user_cfg.items() if k in cfg})
                if isinstance(user_cfg.get("limits"), dict):
                    cfg["limits"].update(user_cfg["limits"])  # type: ignore
                break
        except Exception:
            pass
    return cfg


SECRET_PATTERNS = [
    (re.compile(r"ghp_[A-Za-z0-9]{30,}"), "[REDACTED:GITHUB_PAT]"),
    (re.compile(r"AKIA[0-9A-Z]{16}"), "[REDACTED:AWS_ACCESS_KEY_ID]"),
    (re.compile(r"(?i)aws[^\n]{0,20}(secret|access)[^\n]{0,20}([A-Za-z0-9/+=]{30,})"), "[REDACTED:AWS_SECRET]"),
    (re.compile(r"Bearer\s+[A-Za-z0-9\-._~+/=]{20,}"), "[REDACTED:BEARER]"),
    (re.compile(r"eyJ[\w-]{10,}\.[\w-]{10,}\.[\w-]{10,}"), "[REDACTED:JWT]"),
    (re.compile(r"([a-zA-Z0-9._%+-]+):([^\s@]+)@"), r"\1:[REDACTED]@"),
]


def mask_secrets(s: str) -> str:
    out = s
    for pat, repl in SECRET_PATTERNS:
        try:
            out = pat.sub(repl, out)
        except Exception:
            continue
        
    return out


def detect_tool_family(tool: str, cmd: str, text: str) -> str:
    t = (tool or "").lower()
    c = (cmd or "").lower()
    if any(x in c for x in [" npm ", " npm\n", "npm ", "npm run", "npm ci", "npm install"]) or "npm" == t:
        return "npm"
    if any(x in c for x in [" node ", "node "]) or t in ("node",):
        return "node"
    if "tsc" in c or t in ("tsc", "typescript") or TS_ERROR_RE.search(text):
        return "tsc"
    if "jest" in c or JEST_FAIL_RE.search(text):
        return "jest"
    if "eslint" in c or re.search(r"\beslint\b", text):
        return "eslint"
    if "pytest" in c or re.search(r"^FAILED ", text, flags=re.M):
        return "pytest"
    if "python" in c or PY_TRACE_START_RE.search(text):
        return "python"
    return "generic"


def parse_node_stack(lines, workspace: str) -> Dict[str, Any]:
    frames = []
    for ln in lines:
        m = NODE_STACK_RE_1.match(ln) or NODE_STACK_RE_2.match(ln)
        if not m:
            continue
        if len(m.groups()) == 4:
            func, file, line, col = m.groups()
        else:
            file, line, col = m.groups()
            func = "<anonymous>"
        frames.append({
            "func": func,
            "file": file,
            "line": int(line),
            "col": int(col),
            "in_project": (workspace and file.startswith(workspace)) or ("node_modules" not in file and not file.startswith("internal/")),
        })
    # Prefer in-project top frames
    key_frames = [f for f in frames if f.get("in_project")] or frames[:3]
    return {"frames": key_frames[:5]}


def extract_npm(text: str) -> Dict[str, Any]:
    errors = []
    warns = {}
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        ln = lines[i]
        if ln.startswith("npm ERR!"):
            block = [ln]
            j = i + 1
            while j < len(lines) and lines[j].strip() != "":
                block.append(lines[j])
                j += 1
            msg = " ".join([l.replace("npm ERR!", "").strip() for l in block])
            code_match = re.search(r"code\s+([A-Z0-9_]+)", " ".join(block))
            errors.append({
                "type": "npm",
                "code": code_match.group(1) if code_match else None,
                "message": msg[:400],
                "raw": "\n".join(block)[:1200],
            })
            i = j
            continue
        m = WARN_RE.search(ln)
        if m:
            warns[ln.strip()] = warns.get(ln.strip(), 0) + 1
        i += 1
    return {"errors": dedup_errors(errors), "warnings": top_warnings(warns)}


def extract_tsc(text: str) -> Dict[str, Any]:
    errors = []
    warns = {}
    lines = text.splitlines()
    n = len(lines)
    i = 0
    while i < n:
        ln = lines[i]
        m = TS_ERROR_RE.match(ln)
        if m:
            file, line, col, code, msg = m.groups()
            block = [ln]
            j = i + 1
            while j < n and lines[j].strip() != "":
                block.append(lines[j])
                j += 1
            errors.append({
                "type": "tsc",
                "code": f"TS{code}",
                "file": file,
                "line": int(line),
                "col": int(col),
                "message": msg[:400],
                "raw": "\n".join(block)[:1200],
            })
            i = j
            continue
        m2 = WARN_RE.search(ln)
        if m2:
            warns[ln.strip()] = warns.get(ln.strip(), 0) + 1
        i += 1
    return {"errors": dedup_errors(errors), "warnings": top_warnings(warns)}


def extract_jest(text: str) -> Dict[str, Any]:
    errors = []
    warns = {}
    lines = text.splitlines()
    n = len(lines)
    i = 0
    while i < n:
        m = JEST_FAIL_RE.match(lines[i])
        if m:
            file = m.group(1).strip()
            block = [lines[i]]
            j = i + 1
            reason = None
            while j < n and (lines[j].strip() != "" or (j < n and not lines[j].startswith("PASS "))):
                block.append(lines[j])
                if lines[j].lstrip().startswith("â— ") and not reason:
                    reason = lines[j].strip()
                j += 1
            errors.append({
                "type": "jest",
                "file": file,
                "message": (reason or "Test failure")[:400],
                "raw": "\n".join(block)[:1200],
            })
            i = j
            continue
        m2 = WARN_RE.search(lines[i])
        if m2:
            warns[lines[i].strip()] = warns.get(lines[i].strip(), 0) + 1
        i += 1
    return {"errors": dedup_errors(errors), "warnings": top_warnings(warns)}


def extract_python(text: str) -> Dict[str, Any]:
    errors = []
    warns = {}
    lines = text.splitlines()
    n = len(lines)
    i = 0
    while i < n:
        if PY_TRACE_START_RE.match(lines[i]):
            block = [lines[i]]
            frames = []
            j = i + 1
            while j < n and not PY_EXC_RE.match(lines[j]):
                block.append(lines[j])
                fm = PY_FRAME_RE.match(lines[j])
                if fm:
                    file, ln, func = fm.groups()
                    frames.append({"file": file, "line": int(ln), "func": func})
                j += 1
            exc_type = "Error"
            exc_msg = ""
            if j < n:
                block.append(lines[j])
                em = PY_EXC_RE.match(lines[j])
                if em:
                    exc_type, exc_msg = em.groups()
                j += 1
            errors.append({
                "type": exc_type,
                "message": exc_msg[:400],
                "frames": frames[-5:],
                "raw": "\n".join(block)[:1200],
            })
            i = j
            continue
        m2 = WARN_RE.search(lines[i])
        if m2:
            warns[lines[i].strip()] = warns.get(lines[i].strip(), 0) + 1
        i += 1
    return {"errors": dedup_errors(errors), "warnings": top_warnings(warns)}


def extract_eslint(text: str) -> Dict[str, Any]:
    errors = []
    warns = {}
    current_file = None
    lines = text.splitlines()
    file_header = re.compile(r"^(?!\s)(.*\.(?:js|jsx|ts|tsx|mjs|cjs))\s*$")
    issue_line = re.compile(r"^\s*(\d+):(\d+)\s+(error|warning)\s+(.*?)(?:\s{2,}([a-z0-9-]+))?\s*$")
    unix_line = re.compile(r"^(.*?):(\d+):(\d+):\s*(error|warning)\s+(.*?)(?:\s+\[(.+?)\])?\s*$")
    for ln in lines:
        m_unix = unix_line.match(ln)
        if m_unix:
            f, line, col, sev, msg, rule = m_unix.groups()
            if sev == "error":
                errors.append({
                    "type": "eslint",
                    "file": f,
                    "line": int(line),
                    "col": int(col),
                    "message": msg[:400],
                    "rule": rule,
                    "raw": ln[:1200],
                })
            else:
                key = f"{f}:{line}:{col} {msg}"
                warns[key] = warns.get(key, 0) + 1
            continue
        m_file = file_header.match(ln)
        if m_file:
            current_file = m_file.group(1)
            continue
        m_issue = issue_line.match(ln)
        if m_issue and current_file:
            line, col, sev, msg, rule = m_issue.groups()
            if sev == "error":
                errors.append({
                    "type": "eslint",
                    "file": current_file,
                    "line": int(line),
                    "col": int(col),
                    "message": msg[:400],
                    "rule": rule,
                    "raw": ln[:1200],
                })
            else:
                key = f"{current_file}:{line}:{col} {msg}"
                warns[key] = warns.get(key, 0) + 1
            continue
        if WARN_RE.search(ln):
            warns[ln.strip()] = warns.get(ln.strip(), 0) + 1
    return {"errors": dedup_errors(errors), "warnings": top_warnings(warns)}


def extract_pytest(text: str) -> Dict[str, Any]:
    out = extract_python(text)
    errors = out.get("errors", [])
    fails = re.findall(r"^FAILED\s+(.+?)\s+-\s+(.+)$", text, flags=re.M)
    for f, msg in fails[:3]:
        errors.append({"type": "pytest", "file": f, "message": msg[:400]})
    out["errors"] = dedup_errors(errors)
    return out


def extract_node(text: str, workspace: str) -> Dict[str, Any]:
    errors = []
    warns = {}
    lines = text.splitlines()
    n = len(lines)
    i = 0
    while i < n:
        # Find error header
        if re.match(r"^[A-Za-z_][A-Za-z0-9_]*: ", lines[i]):
            header = lines[i]
            block = [header]
            j = i + 1
            k = j
            # collect stack frames
            while k < n and (lines[k].startswith("    at ") or lines[k].startswith(" at ")):
                block.append(lines[k])
                k += 1
            parsed = parse_node_stack(block[1:], workspace)
            etype, emsg = header.split(": ", 1) if ": " in header else ("Error", header)
            errors.append({
                "type": etype,
                "message": emsg[:400],
                "frames": parsed.get("frames", []),
                "raw": "\n".join(block)[:1200],
            })
            i = k
            continue
        m2 = WARN_RE.search(lines[i])
        if m2:
            warns[lines[i].strip()] = warns.get(lines[i].strip(), 0) + 1
        i += 1
    return {"errors": dedup_errors(errors), "warnings": top_warnings(warns)}


def extract_generic(text: str) -> Dict[str, Any]:
    errors = []
    warns = {}
    lines = text.splitlines()
    n = len(lines)
    i = 0
    while i < n:
        ln = lines[i]
        if re.search(r"\b(error|failed|fatal)\b", ln, re.IGNORECASE):
            block = [ln]
            j = i + 1
            while j < n and lines[j].strip() != "":
                block.append(lines[j])
                j += 1
            errors.append({"type": "generic", "message": ln[:400], "raw": "\n".join(block)[:1200]})
            i = j
            continue
        m2 = WARN_RE.search(ln)
        if m2:
            warns[ln.strip()] = warns.get(ln.strip(), 0) + 1
        i += 1
    return {"errors": dedup_errors(errors), "warnings": top_warnings(warns)}


def dedup_errors(errs):
    unique = []
    seen = set()
    for e in errs:
        key = e.get("type", "") + "|" + e.get("message", "") + "|" + e.get("raw", "")[:120]
        h = hashlib.sha1(key.encode("utf-8", errors="ignore")).hexdigest()[:10]
        if h not in seen:
            seen.add(h)
            unique.append(e)
    return unique[:5]


def top_warnings(warns: Dict[str, int]):
    return sorted([(k, c) for k, c in warns.items()], key=lambda x: -x[1])[:10]


def extract_error_blocks(text: str, tool: str, cmd: str, cwd: str) -> Dict[str, Any]:
    fam = detect_tool_family(tool, cmd, text)
    if fam == "npm":
        return extract_npm(text)
    if fam == "tsc":
        return extract_tsc(text)
    if fam == "jest":
        return extract_jest(text)
    if fam == "python":
        return extract_python(text)
    if fam == "node":
        return extract_node(text, cwd)
    if fam == "eslint":
        return extract_eslint(text)
    if fam == "pytest":
        return extract_pytest(text)
    return extract_generic(text)


def sanitize_output(raw: str, tool: str, cmd: str, cwd: str) -> Dict[str, Any]:
    cfg = load_config(cwd)
    bytes_raw = len(raw.encode("utf-8", errors="ignore"))
    stripped = strip_ansi(raw)
    squashed = squash_progress(stripped)
    lines = squashed.splitlines()
    lines = trim_long_lines(lines, cfg["limits"].get("max_line_len", 500))
    lines = collapse_duplicates(lines, cfg["limits"].get("dupes_cap", 3))
    cleaned = "\n".join(lines)
    if cfg.get("mask_secrets", True):
        cleaned = mask_secrets(cleaned)
    extracted = extract_error_blocks(cleaned, tool, cmd, cwd)

    # Build summary
    err_count = len(extracted["errors"]) if extracted.get("errors") else 0
    warn_count = sum(c for _, c in (extracted.get("warnings") or []))
    summary = []
    if err_count:
        summary.append(f"Detected {err_count} error block(s)")
    if warn_count:
        summary.append(f"Aggregated {warn_count} warning line(s)")
    if not summary:
        summary.append("No obvious errors; output condensed for brevity")

    return {
        "summary_line": "; ".join(summary),
        "cleaned": cleaned,
        "extracted": extracted,
        "bytes_raw": bytes_raw,
    }


def ensure_log_dirs(base_dir: str) -> str:
    log_dir = os.path.join(base_dir, "logs")
    os.makedirs(log_dir, exist_ok=True)
    return log_dir


def write_artifacts(log_dir: str, tool: str, cmd: str, raw: str, sanitized: Dict[str, Any]) -> Tuple[str, str]:
    try:
        ts = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%d-%H%M%S")
    except Exception:
        ts = dt.datetime.utcnow().strftime("%Y%m%d-%H%M%S")
    h = hashlib.sha1(raw.encode("utf-8", errors="ignore")).hexdigest()[:10]
    base = f"{ts}-{tool}-{h}"
    raw_path = os.path.join(log_dir, base + ".log")
    meta_path = os.path.join(log_dir, base + ".json")

    raw_to_write = raw
    try:
        cfg = load_config(os.getcwd())
        if cfg.get("mask_in_raw", False):
            raw_to_write = mask_secrets(raw)
    except Exception:
        pass
    with open(raw_path, "w", encoding="utf-8", errors="ignore") as f:
        f.write(raw_to_write)

    meta = {
        "tool": tool,
        "command": cmd,
        "raw_path": raw_path,
        "summary": sanitized.get("summary_line", ""),
        "bytes_raw": sanitized.get("bytes_raw", 0),
        "extracted": sanitized.get("extracted", {}),
    }
    with open(meta_path, "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=2)

    return raw_path, meta_path


def main() -> int:
    data = sys.stdin.read()
    evt = read_event(data)
    tool, cmd, output = extract_fields(evt)

    # If nothing to do, exit quietly
    if not output:
        return 0

    cwd = os.getcwd()
    base_dir = os.environ.get("CLAUDE_PROJECT_DIR") or os.path.join(cwd, ".claude")
    log_dir = ensure_log_dirs(base_dir)

    sanitized = sanitize_output(output, tool, cmd, cwd)
    raw_path, meta_path = write_artifacts(log_dir, tool, cmd, output, sanitized)

    # Emit a compact summary. Keep it short to save tokens.
    summary_lines = [
        f"[{tool}] {sanitized['summary_line']}",
        f"Raw: {raw_path}",
    ]

    # Add top error snippets (short)
    errors = (sanitized.get("extracted") or {}).get("errors") or []
    max_lines = load_config(cwd)["limits"].get("max_error_snippet_lines", 6)
    for i, err in enumerate(errors[:3], start=1):
        snippet = (err.get("raw") or err.get("message") or "").splitlines()[:max_lines]
        summary_lines.append(f"- Error #{i}:\\n" + "\\n".join(snippet))

    print("\n".join(summary_lines).rstrip() + "\n")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:
        print(f"log-sanitizer: non-fatal error: {e}", file=sys.stderr)
        # Fail-open: do not block or break the agent loop
        sys.exit(0)
