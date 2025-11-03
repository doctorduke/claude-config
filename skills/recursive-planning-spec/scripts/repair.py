#!/usr/bin/env python3
import os, re, json, argparse, shutil, hashlib
from typing import Tuple, Dict

# -------- JSON fixers --------
COMMENT_SL_RE = re.compile(r"//.*?$", re.MULTILINE)
COMMENT_ML_RE = re.compile(r"/\*.*?\*/", re.DOTALL)
TRAILING_COMMA_RE = re.compile(r",(\s*[}\]])")

def read_text(p):
    with open(p, "r", encoding="utf-8") as f:
        return f.read().replace("\ufeff","")

def write_text(p, s):
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "w", encoding="utf-8") as f:
        f.write(s)

def write_json_min(p, obj):
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "w", encoding="utf-8") as f:
        json.dump(obj, f, sort_keys=True, ensure_ascii=False, separators=(",",":"))

def strip_js_comments(s: str) -> str:
    s = COMMENT_ML_RE.sub("", s)
    s = COMMENT_SL_RE.sub("", s)
    return s

def strip_trailing_commas(s: str) -> str:
    prev = None
    while prev != s:
        prev = s
        s = TRAILING_COMMA_RE.sub(r"\1", s)
    return s

def extract_first_object_region(s: str) -> Tuple[str, str]:
    i0 = s.find("{")
    if i0 == -1:
        return "", s
    n = len(s); i = i0
    dob, dar = 0, 0
    ins, esc = False, False
    while i < n:
        ch = s[i]
        if ins:
            if esc: esc = False
            elif ch == "\\": esc = True
            elif ch == '"': ins = False
        else:
            if ch == '"': ins = True
            elif ch == "{": dob += 1
            elif ch == "}":
                dob -= 1
                if dob == 0 and dar == 0:
                    return s[i0:i+1], s[i+1:]
            elif ch == "[": dar += 1
            elif ch == "]":
                if dar > 0: dar -= 1
        i += 1
    closers = "}" * max(dob, 0) + "]" * max(dar, 0)
    return s[i0:] + closers, ""

def try_load_obj(txt: str):
    try:
        return json.loads(txt), None
    except Exception as e:
        return None, e

def repair_json_text(raw: str) -> Tuple[dict, str]:
    s = strip_js_comments(raw)
    first, rem = extract_first_object_region(s)
    if not first.strip().startswith("{"):
        raise ValueError("No top-level JSON object found")
    first = strip_trailing_commas(first)
    obj, err = try_load_obj(first)
    if obj is None:
        first2 = strip_trailing_commas(first)
        obj2, err2 = try_load_obj(first2)
        if obj2 is None:
            raise ValueError(f"Unrepairable JSON: {err2 or err}")
        obj = obj2
    return obj, rem.lstrip()

# -------- Name sanitizers --------
_BAD_CHARS_RE = re.compile(r'[^A-Za-z0-9._-]')  # conservative safe set
_WIN_FORBIDDEN = set('<>:"/\\|?*') | set(chr(i) for i in range(32))

UNICODE_LOOKALIKES = {
    ':': '∶',  # U+2236
    '?': '？',  # U+FF1F
    '*': '∗',  # U+2217
    '<': '‹',  # U+2039
    '>': '›',  # U+203A
    '"': '＂',  # U+FF02
    '|': '⎮',  # U+23EE
    '\\': '⧵', # U+29F5
    '/': '_'   # cannot preserve slash—use underscore
}

def sanitize_component_hex(name: str) -> str:
    base = name.replace("/", "_")
    def repl(m): return "~%02X" % ord(m.group(0))
    safe = _BAD_CHARS_RE.sub(repl, base).rstrip(". ")
    if not safe:
        safe = "_"
    if len(safe) > 120:
        h = hashlib.sha256(name.encode("utf-8")).hexdigest()[:8]
        safe = safe[:100] + "-" + h
    return safe

def sanitize_component_unicode(name: str) -> str:
    out = []
    for ch in name:
        if ch in _WIN_FORBIDDEN:
            out.append(UNICODE_LOOKALIKES.get(ch, '·'))
        elif 0 <= ord(ch) < 32:
            out.append('·')
        else:
            out.append(ch)
    safe = "".join(out).replace("/", "_").rstrip(". ")
    if not safe:
        safe = "_"
    if len(safe) > 120:
        h = hashlib.sha256(name.encode("utf-8")).hexdigest()[:8]
        safe = safe[:100] + "-" + h
    return safe

def make_sanitizer(style: str):
    if style == "unicode":
        return sanitize_component_unicode
    return sanitize_component_hex  # default

def sanitize_relpath(relpath: str, style: str, seen: Dict[str,str]) -> str:
    """
    Sanitize every path component; avoid collisions by suffixing a short hash if needed.
    Keep the directory structure but with sanitized names.
    """
    parts = relpath.split(os.sep)
    san_part = []
    san = make_sanitizer(style)
    for i, p in enumerate(parts):
        sp = san(p)
        # collision guard per directory level
        key = (os.sep.join(parts[:i]) or ".") + "|" + sp
        if key in seen and seen[key] != p:
            # different original produced same sanitized name -> add hash
            h = hashlib.sha256(p.encode("utf-8")).hexdigest()[:8]
            sp = f"{sp}-{h}"
        seen[key] = p
        san_part.append(sp)
    return os.sep.join(san_part)

# -------- Processing --------
def process_nodes(src_root: str, dst_root: str, style: str, name_map: list):
    fixed, remainder, failed = 0, 0, 0
    seen = {}  # for collision avoidance per directory level
    for dirpath, _, files in os.walk(src_root):
        rel_dir = os.path.relpath(dirpath, src_root)
        for fn in files:
            src_rel = os.path.join(rel_dir, fn) if rel_dir != "." else fn
            dst_rel = sanitize_relpath(src_rel, style, seen)
            src = os.path.join(src_root, src_rel)
            dst = os.path.join(dst_root, dst_rel)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            if fn.lower().endswith(".json"):
                try:
                    raw = read_text(src)
                    obj, rem = repair_json_text(raw)
                    write_json_min(dst, obj)
                    fixed += 1
                    if rem:
                        write_text(dst + ".remainder.txt", rem)
                        remainder += 1
                    print(f"[fixed] {src_rel} -> {dst_rel}" + (" + remainder" if rem else ""))
                except Exception as e:
                    write_text(dst + ".error.txt", f"{e}\n")
                    failed += 1
                    print(f"[ERROR] {src_rel}  -> {e}")
            else:
                shutil.copy2(src, dst)
            name_map.append({"src": src_rel, "dst": dst_rel})
    return fixed, remainder, failed

def mirror_rest(src_root: str, dst_root: str, style: str, name_map: list):
    seen = {}
    for path in ("manifest.json", "edges.ndjson", "views"):
        s = os.path.join(src_root, path)
        if not os.path.exists(s):
            continue
        if os.path.isdir(s):
            # sanitize each file under views/
            for dirpath, _, files in os.walk(s):
                rel = os.path.relpath(dirpath, src_root)
                for fn in files:
                    src_rel = os.path.join(rel, fn)
                    dst_rel = sanitize_relpath(src_rel, style, seen)
                    src = os.path.join(src_root, src_rel)
                    dst = os.path.join(dst_root, dst_rel)
                    os.makedirs(os.path.dirname(dst), exist_ok=True)
                    shutil.copy2(src, dst)
                    name_map.append({"src": src_rel, "dst": dst_rel})
        else:
            dst_rel = sanitize_relpath(path, style, seen)
            dst = os.path.join(dst_root, dst_rel)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copy2(s, dst)
            name_map.append({"src": path, "dst": dst_rel})

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", required=True, help="Original plan root (contains nodes/)")
    ap.add_argument("--dst", required=True, help="Destination mirror with repaired JSON & sanitized names")
    ap.add_argument("--style", choices=["hex","unicode"], default="hex",
                    help="Filename sanitization style: 'hex' (~3A) or 'unicode' (∶) for illegal characters")
    args = ap.parse_args()

    src = os.path.abspath(args.src)
    dst = os.path.abspath(args.dst)
    if os.path.exists(dst): shutil.rmtree(dst, ignore_errors=True)
    os.makedirs(dst, exist_ok=True)

    name_map = []

    # nodes/**.json: repair + sanitize names
    fixed, remainder, failed = process_nodes(os.path.join(src, "nodes"), os.path.join(dst, "nodes"), args.style, name_map)

    # mirror the rest (manifest, edges, views) with sanitized names
    mirror_rest(src, dst, args.style, name_map)

    # emit name map
    write_json_min(os.path.join(dst, "name_map.json"), {"style": args.style, "entries": name_map})

    print(f"\nDone. Fixed: {fixed}, with remainders: {remainder}, failed: {failed}")
    if failed:
        print("See *.error.txt beside the problematic files in the mirror.")
    print(f"Name map written to: {os.path.join(dst, 'name_map.json')}")

if __name__ == "__main__":
    main()
