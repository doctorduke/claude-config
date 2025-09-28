# Interface‑First BRIEF System v3 — Spec & Templates

> Purpose: A clean, human‑readable, agent‑friendly documentation system that lives **inside each module** of your repo. It documents **the module itself and its submodules**, not the entire app, while making it trivial for a coding agent to answer “what is this and how does it behave?”

---

## 0) Design Tenets

1. **Interface‑first.** Document inputs → outputs, states, and contracts before inner implementation details.
2. **Self‑contained.** Each module explains **itself and its submodules**, and only references the rest of the app via explicit **integration points**.
3. **Layered, not sprawling.** If BRIEF grows, push long narrative into local `_reference/` and keep BRIEF short, normative, and scannable.
4. **Human‑readable first, agent‑parsable second.** Plain language + predictable section headers + an optional YAML **Answer Pack** for agents.
5. **Truth hierarchy.** Running source & tests > runtime config > BRIEF (normative interface) > `_reference/` (informative) > issues/PRs > chat.

---

## 1) File Layout (per module)

```
<module>/
  BRIEF.md             # short, normative, interface‑first doc (required)
  CLAUDE.md            # how agents & humans should work here (optional but recommended)
  _reference/          # deep specs, diagrams, UX, research (optional)
  src/ ...             # your code
  ...
```

> **Scope rule:** This BRIEF describes `<module>` and any **submodules under it**. It may point to other parts of the app only via **Dependencies & Integration Points**.

---

## 2) BRIEF.md Schema (v3)

Use this exact section order so humans scan quickly and agents can reliably parse.

### Title

```
# <Module Name> — BRIEF
```

### 2.1 Purpose & Boundary

* What problem this module solves and **where its boundary is**.
* Which **submodules** live inside (if any).

### 2.2 Interface Contract (Inputs → Outputs)

Describe the externally visible behavior in **plain language**, split by surface when relevant.

**Inputs**

* API calls / events this module **receives**
* User interactions (clicks, gestures, shortcuts)
* Config flags / feature gates

**Outputs**

* UI states/screens, toasts, navigation
* Data writes, emitted events, side effects
* Performance/error guarantees & invariants

**Per‑Surface Interaction & Presentation** (if both web & mobile)

* **Web** — flows, key interactions, acceptance oracles
* **Mobile** — flows, gestures, acceptance oracles

**Inspirations/Comparables** (3–5 bullets)

* Short list to anchor product taste; link deep notes from `_reference/ux/...`

**Anti‑Goals**

* Things this module explicitly **does not** do in this phase

### 2.3 Dependencies & Integration Points

* Upstream inputs and contracts consumed
* Downstream consumers and side effects

### 2.4 Work State (Planned / Doing / Done)

Keep lists short (3–7 items each) and link to issue/PR IDs.

```
- **Planned**: [ID-123] Offline cache eviction (owner @you, target 2025‑10‑05)
- **Doing**:   [ID-117] Mobile nav gesture (owner @volunteerA, started 2025‑09‑26)
- **Done**:    [ID-101] Auth flow v1 (merged 2025‑09‑21, PR #42)
```

### 2.5 Spec Snapshot (dated)

One compact, dated summary + links into `_reference/`.

```
## SPEC_SNAPSHOT (YYYY‑MM‑DD)
- Features: <bulleted list>
- Tech choices: <frameworks/runtimes/datastores>
- Diagrams: _reference/spec/arch-c4-l2.png
- Full spec: _reference/spec/2025‑09‑25‑v3.md
```

### 2.6 Decisions & Rationale

Short ledger explaining **why** key choices were made.

```
- 2025‑09‑22 — Choose React Native over Flutter (team skills/ecosystem)
- 2025‑09‑24 — Swipe‑right command menu on mobile (one‑hand reach)
```

### 2.7 Answer Pack (agent‑parsable, YAML)

Optional but recommended. Agents can lift this verbatim to answer Q&A.

```yaml
kind: answerpack
module: <path/to/module>
intent: "<one‑line intent>"
surfaces:
  web:
    key_flows: ["<flow-1>", "<flow-2>"]
    acceptance: ["<oracle-1>", "<oracle-2>"]
  mobile:
    key_flows: ["<flow-1>", "<flow-2>"]
    gestures: ["<gesture-1>"]
work_state:
  planned: ["ID-…"]
  doing: ["ID-…"]
  done: ["ID-…"]
interfaces:
  inputs: ["<event/api/input...>"]
  outputs: ["<ui-state/event/side‑effect...>"]
spec_snapshot_ref: _reference/spec/<YYYY‑MM‑DD>-vN.md
truth_hierarchy: ["source", "tests", "docs", "issues", "chat"]
```

### 2.8 Local Reference Index (if submodules)

If this module owns submodules, add a compact index that **links to each submodule’s BRIEF** and 2–4 key references inside that submodule.

```md
## Local Reference Index
- **submodules/**
  - `submodules/ingest/` → [BRIEF](submodules/ingest/BRIEF.md)
    - key refs: [pipeline diagram](submodules/ingest/_reference/spec/pipeline.png), [error taxonomy](submodules/ingest/_reference/spec/errors.md)
  - `submodules/renderer/` → [BRIEF](submodules/renderer/BRIEF.md)
    - key refs: [gesture map](submodules/renderer/_reference/ux/gestures.md)
```

> Keep BRIEF ≤ ~200 lines. Push long prose, diagrams, and research into `_reference/` and link.

---

## 3) CLAUDE.md (Operations Guide)

**Purpose**

* Tell agents (and humans) how to work in this module.

**Scope & Retrieval**

* Read **this** module’s BRIEF first.
* If needed, read parent BRIEF (one level up).
* Only then follow links from SPEC_SNAPSHOT into `_reference/`.

**Truth Hierarchy**

* Source & tests > runtime config > BRIEF (this file’s interface sections) > `_reference/` > issues/PRs > chat.

**Preflight**

* If BRIEF missing ⇒ scaffold and stop with instructions.
* If **Interface Contract** section missing ⇒ stop with instructions.
* If **Spec Snapshot** is stale ⇒ warn and continue.

**Answer Shape** (for agent responses)

* Intent & invariants → bullets
* Per‑surface interaction/presentation → bullets
* Acceptance oracles → list
* Work state → 3–7 items each
* Link to snapshot & decisions

**Security**

* Hooks run commands in your environment; review any script before enabling.

---

## 4) Hooks & Tooling (Claude Code)

Add a project‑level settings file (example structure shown below). You can reference scripts in your repo using `$CLAUDE_PROJECT_DIR`.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/check-brief.sh", "timeout": 5 }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash(mkdir*)",
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/scaffold-brief.sh", "timeout": 5 }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/prompt-preflight.sh", "timeout": 5 }
        ]
      }
    ]
  }
}
```

**Hook policy**

* **Tier‑1 blockers:** missing BRIEF, missing **Interface Contract** section.
* **Tier‑2 warnings:** stale Spec Snapshot, broken BRIEF → `_reference/` links.

> Exit code 2 blocks with an error message; 0 succeeds; other codes warn. (Keep hooks fast and deterministic.)

---

## 5) Authoring Rules (Plain‑Language)

* Write for humans first: short sentences, concrete examples.
* Use verbs for flows and acceptance oracles (GIVEN / WHEN / THEN is fine but keep it brief).
* Prefer links to duplication; one source of truth per fact.
* Keep **Interface Contract** current whenever behavior changes.
* Update **Work State** in the same PR as the code change.
* Date the **Spec Snapshot**; if it’s older than your policy window, refresh or flag as stale.

---

## 6) Example BRIEF (Filled‑in Sketch)

```
# Reader / Offline Cache — BRIEF

## Purpose & Boundary
Provides fast offline reading for articles; covers cache write/read/eviction; submodules: `store/`, `sync/`.

## Interface Contract (Inputs → Outputs)
**Inputs**: `article.fetched`, `network.status`, user taps "Save"; flag `offline_cache_enabled`.
**Outputs**: badge "offline" in list; cached open ≤200ms; event `cache.evicted`.
**Web — Interaction & Presentation**: Ctrl+S saves; toast on success; acceptance: GIVEN airplane mode WHEN open THEN cached list shows in ≤200ms.
**Mobile — Interaction & Presentation**: Swipe‑right opens command menu; long‑press saves; same acceptance.
**Inspirations**: Notion quick‑find; Pocket offline; Apple News reader.
**Anti‑Goals**: No media caching in v1.

## Dependencies & Integration Points
Consumes `network.status`; emits `cache.*` domain events; writes to local SQLite.

## Work State
- Planned: [ID-123] Eviction policy revamp (owner @you, target 2025‑10‑05)
- Doing:   [ID-117] iOS gesture polish (owner @volunteerA, started 2025‑09‑26)
- Done:    [ID-101] Auth flow v1 (merged 2025‑09‑21, PR #42)

## SPEC_SNAPSHOT (2025‑09‑27)
- Features: offline list, cached detail, background sync
- Tech: RN mobile; Next.js web; SQLite; event bus
- Diagram: _reference/spec/arch-c4-l2.png
- Full spec: _reference/spec/2025‑09‑25‑v3.md

## Decisions & Rationale
- 2025‑09‑24 — Keep cache local only (privacy, simplicity)

## Local Reference Index
- submodules/
  - `offline-cache/` → [BRIEF](offline-cache/BRIEF.md)
    - key refs: [arch](offline-cache/_reference/spec/arch-c4-l2.png)
  - `renderer/` → [BRIEF](renderer/BRIEF.md)
    - key refs: [gestures](renderer/_reference/ux/gestures.md)

## Answer Pack
kind: answerpack
module: reader/offline-cache
intent: "Enable offline reading ≤200ms open time"
surfaces:
  web:
    key_flows: ["save article", "open cached list"]
    acceptance: ["list renders ≤200ms", "offline badge visible"]
  mobile:
    key_flows: ["resume last read", "sync on reconnect"]
    gestures: ["swipe‑right command menu"]
work_state:
  planned: ["ID-123 eviction policy"]
  doing: ["ID-117 gesture polish"]
  done: ["ID-101 auth v1"]
interfaces:
  inputs: ["article.fetched", "network.status", "user.save"]
  outputs: ["ui.offline_badge", "cache.evicted"]
spec_snapshot_ref: _reference/spec/2025‑09‑25‑v3.md
truth_hierarchy: ["source","tests","docs","issues","chat"]
```

---

## 7) FAQ

**Q. Does BRIEF ever describe the whole app?**
A. No. It documents **this module** (and submodules). Reference other areas only via named **integration points**.

**Q. How technical should BRIEF be?**
A. Just technical **enough** to specify behavior; keep heavy details in `_reference/`.

**Q. Where did the earlier “user vs assistant” weighting go?**
A. That policy is only relevant when you’re **parsing conversations** to derive specs. BRIEF creation is a **task/tool** flow, so it’s not part of the module schema.

**Q. Can a coding agent answer questions from this alone?**
A. Yes. The **Interface Contract** + **Answer Pack** give an agent everything needed to summarize intent, describe inputs→outputs, list acceptance oracles, and report current work state.

---

# BRIEF v3 — Post‑FAQ Continuation (Clean Edition)

> Continuation from the FAQ you cited. This edition removes problematic bullet syntax in the **Quick Start Checklists** and fixes code‑fence glitches. It completes: app‑level BRIEF guidance, BRIEF generation (conditions & states), first‑time deployment, agent setup (ignores & edge cases), and a document‑to‑BRIEF ingestion pipeline.

---

## 8) Quick Start Checklists (Bullet‑Free)

### 8.1 Authors

| ☐ | Item                                                                                                                                                     |
| - | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ☐ | Create or refresh `BRIEF.md` using the v3 schema (Interface‑first, Work State, Spec Snapshot, Decisions; add Local Reference Index if submodules exist). |
| ☐ | Keep **Interface Contract** up to date whenever behavior changes (per surface: Web/Mobile).                                                              |
| ☐ | Update **Work State** (Planned / Doing / Done) in the same PR as related code changes.                                                                   |
| ☐ | Date the **SPEC_SNAPSHOT** and link deep materials in `_reference/`.                                                                                     |
| ☐ | Keep BRIEF ≤ ~200 lines; move long narrative and assets into `_reference/` and link.                                                                     |

### 8.2 Maintainers

| ☐ | Item                                                                            |
| - | ------------------------------------------------------------------------------- |
| ☐ | Add `.briefignore` at repo root (see Appendix A).                               |
| ☐ | Enable **Tier‑1** blockers (missing BRIEF / missing Interface Contract).        |
| ☐ | Enable **Tier‑2** warnings (stale snapshot / broken BRIEF→`_reference/` links). |
| ☐ | Add a PR template requiring BRIEF deltas for behavior changes (Appendix B).     |
| ☐ | Run an initial scan and open a single PR with draft BRIEFs for missing modules. |

### 8.3 Agents

| ☐ | Item                                                                                                                      |
| - | ------------------------------------------------------------------------------------------------------------------------- |
| ☐ | Retrieve in this order: current module BRIEF → parent BRIEF (one level) → only `_reference/` docs linked by BRIEF.        |
| ☐ | Answer with: Intent & invariants; Inputs→Outputs (per surface); Acceptance oracles; Work State; Spec Snapshot; Decisions. |
| ☐ | If code contradicts BRIEF, prefer code and prompt for a snapshot refresh.                                                 |

---

## 9) App‑Level BRIEF vs Module BRIEF

**Your clarification:** “The BRIEF is the introduction to the whole app.” This is handled by placing an **App BRIEF** at the repo root, plus **Module BRIEFs** in subdirectories.

### 9.1 App BRIEF (root `BRIEF.md`)

**Required sections:** Purpose & Scope of the App; Surface Overview (Web/Mobile); System Map (links to Module BRIEFs); Global Invariants & Policies (auth, performance, accessibility, privacy); Global Inspirations & Anti‑Goals; App‑wide Work State; App **SPEC_SNAPSHOT** (dated) with links to architecture/product docs; App‑level Decisions & Rationale.

**Scope note:** The App BRIEF introduces the application and links down to modules; it does not restate module internals.

### 9.2 Module BRIEF (per subdirectory)

Uses the v3 schema (Interface Contract, Work State, Spec Snapshot, Decisions). If submodules exist, include a **Local Reference Index** that **cites each submodule’s BRIEF** and 2–4 key refs within that submodule.

### 9.3 Linking Rules

Use **relative links** so they resolve in the code host.

* App BRIEF → Module BRIEFs (System Map)
* Module BRIEF → Submodule BRIEFs (Local Reference Index)
* Any BRIEF → its own `_reference/` items for depth

---

## 10) BRIEF Generation Protocol (Conditions, States, Heuristics)

### 10.1 Trigger Conditions

1. Directory creation (`mkdir`) inside repo triggers a BRIEF scaffold in that directory.
2. First write/edit in a directory lacking BRIEF blocks and scaffolds.
3. Directory contains `_reference/` but no BRIEF → scaffold and mark **provisional**.
4. Legacy trees → recursive scan; create **draft‑inferred** BRIEFs and open a PR.
5. Ingestion of PRDs/ideation/chats (Section 12) proposes a BRIEF or delta.

### 10.2 State Machine

* **missing** → **scaffolded** (blocking, headings only)
* **scaffolded** → **draft‑inferred** (generator fills `INFERRED:` fields)
* **draft‑inferred** → **confirmed** (human edited; `INFERRED:` removed)
* **confirmed** → **stale** (snapshot too old or links broken; warning only)

**Marker rule:** Put `> INFERRED: …` under any field populated heuristically. If **Interface Contract** contains `INFERRED:`, it remains a **Tier‑1 blocker** until a human edits it away.

### 10.3 Inference Heuristics (for draft‑inferred)

Intent from directory/README/routes; Inputs from handlers/events/tests; Outputs from rendered screens/events/writes; Surface detection from tech hints (RN/Swift/Kotlin vs React/Next.js); Comparables from PRD “inspiration/competitors” sections; Integration Map from imports/manifests.

### 10.4 Hook Behavior (Claude Code or your automation)

* **PostToolUse (mkdir):** create scaffold; **exit 2** (block) with guidance.
* **PreToolUse (Write|Edit):**

  * Missing BRIEF ⇒ **exit 2** and scaffold.
  * Missing Interface Contract or any `INFERRED:` in that section ⇒ **exit 2**.
  * Stale Spec Snapshot or broken links ⇒ **exit 0** with warning.
* **UserPromptSubmit:** print an excerpt of Interface Contract + current Work State.

---

## 11) First‑Time Deployment in an Existing Repo

### 11.1 Preparation

Add a repository‑root `.briefignore` (Appendix A). Place hook scripts in `.claude/hooks/` (or `tools/hooks/`). Add a PR template (Appendix B).

### 11.2 Safe Rollout

**Step 1 — Dry Run (no writes):** walk the repo honoring `.briefignore`; list missing BRIEFs and `_reference/` without BRIEF.

**Step 2 — Draft Generation:** create `BRIEF.md` with headings + `INFERRED:` fields. For parent directories, add a **Local Reference Index** skeleton.

**Step 3 — PR:** one module per commit; reviewers confirm or edit Interface Contracts.

**Step 4 — Enable Gating:** start with Tier‑1 blockers; add Tier‑2 warnings after the initial PR merges.

### 11.3 Edge Cases & Ignores

Ignored by default: `node_modules/`, `.git/`, `dist/`, `build/`, `.next/`, `.cache/`, `coverage/`, `android/`, `ios/`, `Pods/`, `vendor/`, `third_party/`, `bin/`, `obj/`, `tmp/`, `__pycache__/`, `*.lock`, `*.min.*`.
Binary‑only directories are skipped unless they contain code submodules. Vendor/third_party is never scaffolded. In monorepos, start at package roots and allow local `.briefignore`. Symlinks are resolved within the repo only; external targets are skipped.

---

## 12) Document → BRIEF Ingestion (PRDs, Ideation, Chats)

### 12.1 Inputs & Normalization

Accepted: Markdown, DOCX, PDF, plaintext chat transcripts. Normalize to Markdown and split into sections. For **chat transcripts only**, prefer **USER** lines during extraction.

### 12.2 Mapping Matrix

| BRIEF Field                | Typical Source Section(s)                                    |
| -------------------------- | ------------------------------------------------------------ |
| Purpose & Boundary         | Title / Problem / Scope                                      |
| Interface Contract         | Requirements / Use Cases / UX flows / Gestures               |
| Dependencies & Integration | Architecture / Integrations                                  |
| Work State                 | Roadmap / Backlog (normalize to Planned/Doing/Done with IDs) |
| Spec Snapshot              | Current features, tech choices, diagram list                 |
| Decisions & Rationale      | ADRs / Decision threads (1–2 lines each)                     |
| Local Reference Index      | Submodule‑relevant references                                |
| Answer Pack                | Synthesis of the above                                       |

### 12.3 Ingest CLI (pseudo‑commands)

```bash
# Dry run
brief ingest \
  --module app/reader/offline-cache \
  --src docs/prd/offline-cache-v3.pdf \
  --out app/reader/offline-cache/BRIEF.md \
  --reference-root app/reader/offline-cache/_reference \
  --prefer-user-in-chats

# Apply
brief ingest --apply ...
```

**Behavior:** copies cited artefacts into the module’s `_reference/`, injects relative links into **SPEC_SNAPSHOT** and **Local Reference Index**, writes `INFERRED:` markers where confidence is low, and opens/updates a PR with the BRIEF changes.

---

## 13) Hook Skeletons (portable, fixed fences)

**`scaffold-brief.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail
DIR="${1:-.}"
B="$DIR/BRIEF.md"
if [[ -f "$B" ]]; then echo "BRIEF exists"; exit 0; fi
cat > "$B" <<'EOF'
# <Module Name> — BRIEF
## Purpose & Boundary
## Interface Contract (Inputs → Outputs)
## Dependencies & Integration Points
## Work State (Planned / Doing / Done)
## SPEC_SNAPSHOT (YYYY‑MM‑DD)
## Decisions & Rationale
## Local Reference Index
## Answer Pack (YAML)
EOF
echo "Scaffolded $B — please fill Interface Contract; generation blocks until you do."; exit 2
```

**`check-brief.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail
FILE="${1:-}"; [[ -z "$FILE" ]] && { echo "usage: check-brief.sh <file>"; exit 1; }
DIR="$(dirname "$FILE")"; B="$DIR/BRIEF.md"
[[ ! -f "$B" ]] && { echo "Tier‑1: Missing BRIEF ($B)"; exit 2; }
grep -q "^## Interface Contract" "$B" || { echo "Tier‑1: Missing Interface Contract"; exit 2; }
if grep -q "INFERRED:" "$B"; then echo "Tier‑1: Interface fields still INFERRED"; exit 2; fi
if ! grep -q "^## SPEC_SNAPSHOT" "$B"; then echo "Tier‑2: Missing SPEC_SNAPSHOT"; exit 0; fi
exit 0
```

**`prompt-preflight.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail
DIR="$PWD"; B="$DIR/BRIEF.md"
[[ ! -f "$B" ]] && { echo "[Blocker] No BRIEF in $DIR"; exit 2; }
awk '/^## Interface Contract/,/^## Dependencies/{print}' "$B" | head -n 40 || true
```

---

## 14) Example: App BRIEF + Modules

**Root `BRIEF.md` (App BRIEF)**

```md
# MyApp — BRIEF (App)
## Purpose & Scope
A knowledge app for reading/saving articles across Web & Mobile.

## Surface Overview
Web: search, read, library management
Mobile: offline reading, gesture navigation

## System Map
- app/reader/ → [BRIEF](app/reader/BRIEF.md)
- app/auth/ → [BRIEF](app/auth/BRIEF.md)

## Global Invariants & Policies
Auth: email‑magic‑link
Accessibility: WCAG AA
Performance budgets: FCP ≤ 2s (web), open ≤ 200ms (mobile)

## Work State (App‑wide)
Planned: [A‑12] share‑sheet integration
Doing:   [A‑07] offline sync polish
Done:    [A‑01] auth v1

## SPEC_SNAPSHOT (2025‑09‑27)
Features: offline reading, command menu
Architecture: Next.js, RN, SQLite, event bus

## Decisions & Rationale
2025‑09‑20 — privacy‑first, local cache only
```

**Module `app/reader/BRIEF.md`** — use the schema in Section 2 and include a **Local Reference Index** for `offline-cache/` and `renderer/`.

---

## Appendix A — Default `.briefignore`

```
node_modules/
.git/
dist/
build/
.next/
.cache/
coverage/
android/
ios/
Pods/
vendor/
third_party/
bin/
obj/
tmp/
__pycache__/
*.min.*
*.lock
*.map
```

## Appendix B — PR Template

```
## Summary
Explain the change and why it’s needed.

## BRIEF Updates (required)
- [ ] Updated Work State
- [ ] Updated Interface Contract (if behavior/UX changed)
- [ ] Updated SPEC_SNAPSHOT date & links
- [ ] Added/updated Decisions & Rationale

## Tests / Acceptance
List acceptance oracles touched.
```

## Appendix C — Answer Pack (canonical shape)

```yaml
kind: answerpack
module: <path/to/module>
intent: "<one‑line intent>"
surfaces:
  web:
    key_flows: ["<flow-1>", "<flow-2>"]
    acceptance: ["<oracle-1>", "<oracle-2>"]
  mobile:
    key_flows: ["<flow-1>", "<flow-2>"]
    gestures: ["<gesture-1>"]
work_state:
  planned: ["ID-…"]
  doing: ["ID-…"]
  done: ["ID-…"]
interfaces:
  inputs: ["<event/api/input…>"]
  outputs: ["<ui-state/event/side‑effect…>"]
spec_snapshot_ref: _reference/spec/<YYYY‑MM‑DD>-vN.md
truth_hierarchy: ["source", "tests", "docs", "issues", "chat"]
```

---

*End of Clean Edition*
