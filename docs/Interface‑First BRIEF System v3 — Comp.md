# Interface‑First BRIEF System v3 — Complete Guide & Deployment Playbook

> This extends the prior v3 spec. It adds: (a) **submodule citation rules**, (b) a full **BRIEF generation protocol** with conditions & states, (c) an **initial deployment playbook** for existing repos (ignores, edge cases), and (d) a **document ingestion pipeline** (PRDs, ideation docs, chats → BRIEFs). It remains **interface‑first, human‑readable**, and **agent‑parsable**.

---

## 0) Scope & Ground Rules (Recap)

* **Self‑contained:** Each BRIEF documents **this module** and its **submodules** only.
* **Interface‑first:** Inputs → Outputs, surfaces (Web/Mobile), acceptance oracles.
* **Normative vs Informative:** BRIEF stays short and normative; `_reference/` holds depth (specs, diagrams, research).
* **Truth hierarchy:** running source & tests > runtime config > BRIEF > `_reference/` > issues/PRs > chat.

---

## 1) Submodule Citation & Local Reference Index

### 1.1 Submodule Doctrine

* Every **submodule** under `<module>/` should have **its own BRIEF.md** (same schema) and optional `_reference/`.
* The parent BRIEF **must not re‑explain** submodule internals; it should link to them.

### 1.2 Local Reference Index (required section)

Add this section to parent BRIEFs when submodules exist:

```md
## Local Reference Index
- **submodules/**
  - `submodules/ingest/` → [BRIEF](submodules/ingest/BRIEF.md)
    - key refs: [pipeline diagram](submodules/ingest/_reference/spec/pipeline.png), [error taxonomy](submodules/ingest/_reference/spec/errors.md)
  - `submodules/renderer/` → [BRIEF](submodules/renderer/BRIEF.md)
    - key refs: [gesture map](submodules/renderer/_reference/ux/gestures.md)
```

**Rules**

* Use **relative paths**; links must resolve in Git web UI.
* Keep **2–4 key refs** per submodule (diagrams/specs most useful for onboarding).
* If a linked submodule **lacks** BRIEF, the parent’s **generation check** (see §3) should flag it.

---

## 2) BRIEF.md Schema (v3, with Local Reference Index)

> Use this exact order for consistency and agent parsing.

```md
# <Module Name> — BRIEF

## Purpose & Boundary
(What this module solves + boundary; list submodules owned here.)

## Interface Contract (Inputs → Outputs)
- Inputs: APIs/events, user actions, feature flags
- Outputs: UI states/screens/toasts, emitted events, data writes
- Web — flows, interactions, acceptance
- Mobile — flows, gestures, acceptance
- Inspirations (3–5 bullets)
- Anti‑Goals

## Dependencies & Integration Points
(Upstream inputs consumed; downstream effects/consumers.)

## Work State (Planned / Doing / Done)
(Lists of 3–7 items each; link IDs.)

## SPEC_SNAPSHOT (YYYY‑MM‑DD)
(Short dated summary + links into `_reference/`.)

## Decisions & Rationale
(Short ledger of whys.)

## Local Reference Index
(Links to submodule BRIEFs + 2–4 key refs per submodule.)

## Answer Pack (YAML)
(kind: answerpack; module path; surfaces; work_state; interfaces; spec_snapshot_ref; truth_hierarchy)
```

---

## 3) BRIEF Generation Protocol (Conditions, States, Hooks)

### 3.1 Trigger Conditions

1. **mkdir** inside repo → generate **scaffolded BRIEF** in the new directory.
2. First **Write/Edit/MultiEdit** in a directory lacking BRIEF → block and scaffold.
3. Directory contains `_reference/` but **no BRIEF** → scaffold BRIEF and flag state as **provisional**.
4. **Legacy tree**: scan recursively; any module dir without BRIEF → create draft BRIEF + open an issue/PR in **safe mode**.
5. **Conversation/PRD ingestion** (see §5) proposes new BRIEF or updates.

### 3.2 State Machine

* **missing** → **scaffolded** (blocking; minimal headings only)
* **scaffolded** → **draft‑inferred** (generator fills fields marked `INFERRED:`)
* **draft‑inferred** → **confirmed** (owner edits and removes `INFERRED:` markers)
* **confirmed** → **stale** (snapshot too old or links broken; warn, not block)

**Markers**

* Place `> INFERRED: <text>` under any field populated by heuristics.
* Hooks treat presence of `INFERRED:` in Interface Contract as **Tier‑1 blocker** until a human edits it.

### 3.3 Inference Heuristics (for draft‑inferred)

* **Intent**: infer from directory name, README, package name, `app/feature` routes.
* **Inputs**: search event/API names in code/tests (`onClick`, `emit(...)`, route handlers, pub/sub topics).
* **Outputs**: identify rendered screens/components, emitted events, DB writes.
* **Surfaces**: presence of mobile/web folders, RN/Swift/Kotlin vs React/Next.js hints.
* **Inspirations**: mine PRD/ideation docs’ “comparables” headings.
* **Integration Map**: dependencies in package manifests/import graphs.

### 3.4 Hook Behavior (Claude Code)

* **PostToolUse (mkdir)** → create BRIEF scaffold; **exit 2** with a friendly message.
* **PreToolUse (Write|Edit|MultiEdit)** →

  * If BRIEF missing → **exit 2** (block) and scaffold.
  * If Interface Contract missing or contains `INFERRED:` → **exit 2**.
  * If Spec Snapshot stale or links broken → **exit 0 + warning**.
* **UserPromptSubmit** → print Interface Contract excerpt and current Work State to guide the user/agent.

---

## 4) First‑Time Deployment (Existing Repo)

### 4.1 Preparation

* Commit a `.briefignore` (see §6) at repo root.
* Add `.claude/settings.json` and hook scripts (or equivalent automation in your toolchain).
* Create a PR template requiring BRIEF updates for behavior changes.

### 4.2 Safe Rollout Steps

1. **Dry run scan** (no writes):

   * Walk repo respecting `.briefignore`.
   * Report directories missing BRIEF and any `_reference/` without BRIEF.
2. **Generate drafts** (safe mode):

   * For each candidate dir, create `BRIEF.md` with headings + `INFERRED:` fields.
   * For subtrees, also add **Local Reference Index** skeletons.
   * Open a single PR with one commit per module for easy review.
3. **Adopt gating**:

   * Enable **Tier‑1** blockers (missing BRIEF/Interface Contract).
   * Enable **Tier‑2** warnings (stale snapshot, broken links) after the initial PR merges.

### 4.3 Edge Cases & Ignores

* **Ignore by default:** `node_modules/`, `.git/`, `dist/`, `build/`, `.next/`, `.cache/`, `coverage/`, `android/`, `ios/`, `Pods/`, `vendor/`, `third_party/`, `bin/`, `obj/`, `tmp/`, `__pycache__/`, `*.lock`, `*.min.*`.
* **Binary‑only dirs** (images, fonts) → skip scaffolding unless they have submodules with code.
* **Vendor/third_party** → never scaffold.
* **Monorepos** → start at workspace roots; respect per‑package ignores.
* **Symlinks** → resolve within repo only; skip external targets.

---

## 5) Document Ingestion Pipeline (PRDs, Ideation, Chats → BRIEFs)

### 5.1 Inputs & Normalization

* Accept **Markdown, DOCX, PDF, plaintext chat transcripts**.
* Convert to Markdown; split into sections.
* For **chat transcripts**, apply this policy during extraction only: **prefer USER lines over assistant lines** for authoritative decisions.

### 5.2 Mapping → BRIEF Fields

* **Purpose & Boundary** ← Title/Problem/Scope.
* **Interface Contract** ← Requirements, Use Cases, UX flows, gesture notes.
* **Dependencies & Integration** ← Architecture/“Integrations” sections.
* **Work State** ← Roadmap/Backlog bullets (convert to Planned/Doing/Done with IDs).
* **Spec Snapshot** ← Current feature set, tech choices, diagrams list.
* **Decisions** ← ADRs/Decision threads; distill to 1–2 lines each.
* **Local Reference Index** ← For any submodule‑relevant references in the doc.
* **Answer Pack** ← Synthesize from the above.

### 5.3 Ingest Command (pseudo‑CLI)

```bash
# Dry run: show proposed changes
brief ingest \
  --module reader/offline-cache \
  --src docs/prd/offline-cache-v3.pdf \
  --out ./reader/offline-cache/BRIEF.md \
  --reference-root ./reader/offline-cache/_reference \
  --prefer-user-in-chats

# Apply changes (writes files, adds links under _reference/)
brief ingest --apply ...
```

**Behavior**

* Copies cited artefacts into `_reference/` (preserving folder structure), then inserts relative links into the **Spec Snapshot** and **Local Reference Index**.
* Places `INFERRED:` markers where confidence is low.
* Opens/updates a PR with a diff showing the BRIEF edits.

---

## 6) Ignore & Selection Rules (`.briefignore`)

Create a repo‑root file to control scanning and generation:

```
# Folders
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

# Files
*.min.*
*.lock
*.map
```

You can add module‑local `.briefignore` files to override.

---

## 7) Agent Operating Guide (Q&A + Updates)

**Retrieval order**

1. Current module’s **BRIEF**.
2. Parent BRIEF (one level) if needed.
3. Only then follow links into `_reference/` **explicitly cited** by Spec Snapshot or Local Reference Index.

**Answer shape**

* Intent & invariants → bullets
* Inputs → Outputs (by surface)
* Acceptance oracles → list
* Work State → small lists
* Link to Spec Snapshot & Decisions

**When code contradicts BRIEF**

* Prefer code; open a doc‑update issue and prompt human to refresh the snapshot.

---

## 8) Hook Skeletons (portable)

> Use any task runner; shown here in bash pseudo‑scripts. Exit **2** to block, **0** to allow, **1** for generic error.


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
echo "Scaffolded $B — please fill Interface Contract; generation is blocking until you do."; exit 2
```


```bash
#!/usr/bin/env bash
set -euo pipefail
FILE="${1:-}"; [[ -z "$FILE" ]] && { echo "usage: check-brief.sh <file>"; exit 1; }
DIR="$(dirname "$FILE")"; B="$DIR/BRIEF.md"
[[ ! -f "$B" ]] && { echo "Tier‑1: Missing BRIEF ($B)"; exit 2; }
grep -q "^## Interface Contract" "$B" || { echo "Tier‑1: Missing Interface Contract"; exit 2; }
if grep -q "INFERRED:" "$B"; then echo "Tier‑1: Interface fields still INFERRED"; exit 2; fi
if ! grep -q "^## SPEC_SNAPSHOT" "$B"; then echo "Tier‑2: Missing SPEC_SNAPSHOT"; exit 0; fi
# Optional: link checks here
exit 0
```


```bash
#!/usr/bin/env bash
set -euo pipefail
DIR="$PWD"; B="$DIR/BRIEF.md"
[[ ! -f "$B" ]] && { echo "[Blocker] No BRIEF in $DIR"; exit 2; }
awk '/^## Interface Contract/,/^## Dependencies/{print}' "$B" | head -n 40 || true
```

---

## 9) Example: Parent with Submodules

```md
# Reader — BRIEF
## Purpose & Boundary
Provides reading features; owns submodules: `offline-cache/`, `renderer/`.

## Interface Contract (Inputs → Outputs)
Inputs: article events, user saves; Outputs: list badges, cached opens ≤200ms

## Dependencies & Integration Points
Consumes `network.status`; emits `cache.*` events

## Work State
- Planned: [ID-123] improve eviction
- Doing:   [ID-117] gesture polish
- Done:    [ID-101] auth v1

## SPEC_SNAPSHOT (2025‑09‑27)
- Features: offline list, cached detail
- Full spec: _reference/spec/2025‑09‑25‑v3.md

## Decisions & Rationale
- 2025‑09‑24 — local cache only

## Local Reference Index
- submodules/
  - `offline-cache/` → [BRIEF](offline-cache/BRIEF.md)
    - key refs: [arch](offline-cache/_reference/spec/arch-c4-l2.png)
  - `renderer/` → [BRIEF](renderer/BRIEF.md)
    - key refs: [gestures](renderer/_reference/ux/gestures.md)

## Answer Pack
kind: answerpack
module: reader/
intent: "Reading experience with offline support"
```

---

## 10) Quick Start Checklists

### Author

| ☐ | Item |
|---|------|
| ☐ | Create or refresh `BRIEF.md` using the v3 schema (Interface‑first, Work State, Spec Snapshot, Decisions; add Local Reference Index if submodules exist). |
| ☐ | Keep **Interface Contract** up to date whenever behavior changes (per surface: Web/Mobile). |
| ☐ | Update **Work State** (Planned / Doing / Done) in the same PR as related code changes. |
| ☐ | Date the **SPEC_SNAPSHOT** and link deep materials in `_reference/`. |
| ☐ | Keep BRIEF ≤ ~200 lines; move long narrative and assets into `_reference/` and link. |

### Maintainer

| ☐ | Item |
|---|------|
| ☐ | Add `.briefignore` at repo root (see Appendix A). |
| ☐ | Enable **Tier‑1** blockers (missing BRIEF / missing Interface Contract). |
| ☐ | Enable **Tier‑2** warnings (stale snapshot / broken BRIEF→`_reference/` links). |
| ☐ | Add a PR template requiring BRIEF deltas for behavior changes (Appendix B). |
| ☐ | Run an initial scan and open a single PR with draft BRIEFs for missing modules. |

### Agent

| ☐ | Item |
|---|------|
| ☐ | Retrieve in this order: current module BRIEF → parent BRIEF (one level) → only `_reference/` docs linked by BRIEF. |
| ☐ | Answer with: Intent & invariants; Inputs→Outputs (per surface); Acceptance oracles; Work State; Spec Snapshot; Decisions. |
| ☐ | If code contradicts BRIEF, prefer code and prompt for a snapshot refresh. |## 11) Notes on Conversation Mining vs BRIEF Authoring

* “Prefer USER over assistant” weighting is **only** for mining chat transcripts (e.g., deriving requirements). It is **not** part of the BRIEF schema or generation unless you run the **ingestion pipeline** in §5 against a conversation file.

---

*End of Playbook*