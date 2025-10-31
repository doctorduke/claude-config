# Briefkit Patterns Reference

This document contains the core patterns, templates, and rules for creating and maintaining BRIEF documentation.

## Table of Contents

1. [BRIEF.md Schema Pattern](#briefmd-schema-pattern)
2. [Validation Patterns](#validation-patterns)
3. [State Machine Pattern](#state-machine-pattern)
4. [Multi-Surface Documentation Pattern](#multi-surface-documentation-pattern)
5. [Document Ingestion Pattern](#document-ingestion-pattern)
6. [Parent-Child Module Pattern](#parent-child-module-pattern)
7. [Answer Pack Pattern](#answer-pack-pattern)
8. [File Organization Pattern](#file-organization-pattern)

---

## BRIEF.md Schema Pattern

### Required Section Order

BRIEF.md must use this exact section order for consistency and agent parsing:

```markdown
# <Module Name> — BRIEF

## Purpose & Boundary
<What this module solves and where its boundary is>
<List submodules owned here if any>

## Interface Contract (Inputs → Outputs)
**Inputs**
<API calls, events received, user interactions, config flags>

**Outputs**
<UI states/screens, data writes, emitted events, side effects>
<Performance guarantees and invariants>

**Per-Surface Interaction & Presentation** (if multiple surfaces)
- **Web** — <flows, key interactions, acceptance oracles>
- **Mobile** — <flows, gestures, acceptance oracles>

**Inspirations/Comparables** (3–5 bullets)
<Short list to anchor product taste>

**Anti-Goals**
<Things this module explicitly does NOT do>

## Dependencies & Integration Points
<Upstream inputs and contracts consumed>
<Downstream consumers and side effects>

## Work State (Planned / Doing / Done)
- **Planned**: [ID-123] <task> (owner @user, target YYYY-MM-DD)
- **Doing**:   [ID-117] <task> (owner @user, started YYYY-MM-DD)
- **Done**:    [ID-101] <task> (merged YYYY-MM-DD, PR #42)

## SPEC_SNAPSHOT (YYYY-MM-DD)
- Features: <bulleted list>
- Tech choices: <frameworks/runtimes/datastores>
- Diagrams: _reference/spec/arch-c4-l2.png
- Full spec: _reference/spec/YYYY-MM-DD-vN.md

## Decisions & Rationale
- YYYY-MM-DD — <decision> (<rationale>)

## Local Reference Index
- **submodules/**
  - `submodule-name/` → [BRIEF](submodule-name/BRIEF.md)
    - key refs: [diagram](submodule-name/_reference/spec/diagram.png)

## Answer Pack
```yaml
kind: answerpack
module: <path/to/module>
intent: "<one-line intent>"
surfaces:
  web:
    key_flows: ["<flow-1>", "<flow-2>"]
    acceptance: ["<oracle-1>", "<oracle-2>"]
  mobile:
    key_flows: ["<flow-1>", "<flow-2>"]
    gestures: ["<gesture-1>"]
work_state:
  planned: ["ID-123"]
  doing: ["ID-117"]
  done: ["ID-101"]
interfaces:
  inputs: ["<input-1>", "<input-2>"]
  outputs: ["<output-1>", "<output-2>"]
spec_snapshot_ref: _reference/spec/YYYY-MM-DD-vN.md
truth_hierarchy: ["source", "tests", "docs", "issues", "chat"]
```
\```

### Field Guidelines

**Purpose & Boundary**
- 2-4 sentences max
- What problem does this module solve?
- Where does its responsibility start and end?
- List any submodules owned

**Interface Contract**
- Focus on externally visible behavior
- Document inputs (what comes in)
- Document outputs (what goes out)
- Include performance/error guarantees
- Per-surface sections if multi-platform
- Inspirations: 3-5 reference products/features
- Anti-goals: explicitly state what's out of scope

**Dependencies & Integration Points**
- Upstream: what this module consumes
- Downstream: what consumes this module
- Keep as specific named contracts (not implementation details)

**Work State**
- 3-7 items per section (Planned/Doing/Done)
- Link issue/PR IDs
- Include owner and dates
- Keep recent history only (move old items to archive)

**SPEC_SNAPSHOT**
- Always date with (YYYY-MM-DD) format
- Short bulleted summary
- Links to _reference/ for depth
- Update date when refreshing

**Decisions & Rationale**
- Dated entries (YYYY-MM-DD)
- One-line decision + brief rationale
- Why, not how (how is in code/specs)
- Keep ledger-style (chronological)

**Local Reference Index**
- Only needed if submodules exist
- Link to each submodule's BRIEF
- 2-4 key refs per submodule
- Use relative paths

**Answer Pack**
- Valid YAML (check syntax)
- Structured data for agent parsing
- Synthesize from above sections
- Include all surfaces

### Length Constraint

**Target:** ≤200 lines (excluding code blocks)

**If too long:**
- Move detailed specs to _reference/spec/
- Move diagrams to _reference/diagrams/
- Move research to _reference/research/
- Link from BRIEF to these resources

---

## Validation Patterns

### Validation Checklist

Use this checklist when validating BRIEF.md files:

**Tier-1 Blockers** (must fix immediately):
- [ ] BRIEF.md file exists
- [ ] `## Interface Contract` section present
- [ ] No `INFERRED:` markers in Interface Contract section
- [ ] Answer Pack is valid YAML
- [ ] File ≤200 lines (excluding code blocks)

**Tier-2 Warnings** (should fix soon):
- [ ] `## SPEC_SNAPSHOT (YYYY-MM-DD)` section present with date
- [ ] Answer Pack section present
- [ ] Local Reference Index present (if submodules exist)
- [ ] All _reference/ links are valid (files exist)
- [ ] Spec Snapshot not stale (≤90 days old)

### Validation Algorithm

```
FOR each BRIEF.md file:
  1. Check file exists and is readable
  2. Check required sections present (exact heading match)
  3. Check Interface Contract complete (no INFERRED:)
  4. Extract Spec Snapshot date, validate format
  5. Parse Answer Pack YAML, validate structure
  6. Count lines (exclude code blocks), check ≤200
  7. If submodules exist in directory, check Local Reference Index
  8. Validate all _reference/ links resolve
  9. Report all issues with line numbers
END FOR
```

### Section Heading Patterns

Exact matches required (case-sensitive):

```
## Purpose & Boundary
## Interface Contract (Inputs → Outputs)
## Dependencies & Integration Points
## Work State (Planned / Doing / Done)
## SPEC_SNAPSHOT (YYYY-MM-DD)
## Decisions & Rationale
## Local Reference Index
## Answer Pack
```

Common mistakes:
- ❌ `## Interface Contract` (missing suffix)
- ✅ `## Interface Contract (Inputs → Outputs)`
- ❌ `## Spec Snapshot` (wrong case)
- ✅ `## SPEC_SNAPSHOT (YYYY-MM-DD)`
- ❌ `## Work State` (missing detail)
- ✅ `## Work State (Planned / Doing / Done)`

---

## State Machine Pattern

BRIEFs progress through a lifecycle:

```
[missing] → [scaffolded] → [draft-inferred] → [confirmed] → [stale]
     ↓            ↓                ↓               ↓            ↓
  (block)      (block)          (block)        (allow)      (warn)
```

### State Definitions

**missing**
- No BRIEF.md file exists in module directory
- Action: Block writes, scaffold BRIEF

**scaffolded**
- BRIEF.md exists with headings only
- No content filled in
- Action: Block writes, request completion

**draft-inferred**
- BRIEF.md has content marked with `> INFERRED:` markers
- Generated heuristically, needs human review
- Action: Block writes if Interface Contract has INFERRED

**confirmed**
- All fields completed
- No INFERRED markers in Interface Contract
- Human reviewed and approved
- Action: Allow writes

**stale**
- Spec Snapshot >90 days old
- Or links to _reference/ broken
- Action: Warn (don't block), request update

### INFERRED Marker Pattern

Use when confidence is low:

```markdown
## Interface Contract (Inputs → Outputs)
**Inputs**
> INFERRED: Based on route handlers in src/api/
- POST /api/profile - Update user profile
- GET /api/profile/:id - Fetch profile by ID

**Outputs**
> INFERRED: Based on component renders
- Profile edit screen (Web)
- Success toast on save
```

**Rules:**
- Place `> INFERRED: <explanation>` before content
- Explain inference source (code scan, directory name, etc.)
- Remove after human verification
- Interface Contract with INFERRED = Tier-1 blocker

---

## Multi-Surface Documentation Pattern

For applications with multiple platforms (Web, Mobile, Desktop, API):

### Pattern Structure

```markdown
## Interface Contract (Inputs → Outputs)
**Inputs**
<Common inputs across all surfaces>

**Outputs**
<Common outputs across all surfaces>

**Web — Interaction & Presentation**
- Key flows: <what users do on web>
- Interactions: <clicks, keyboard shortcuts>
- Acceptance: GIVEN <state> WHEN <action> THEN <result>

**Mobile — Interaction & Presentation**
- Key flows: <what users do on mobile>
- Gestures: <taps, swipes, long-press>
- Acceptance: GIVEN <state> WHEN <action> THEN <result>

**API — Interaction & Presentation** (if applicable)
- Endpoints: <REST/GraphQL endpoints>
- Authentication: <auth requirements>
- Acceptance: <response codes, contracts>

**Inspirations/Comparables**
- Notion quick-find (Web)
- Apple News reader (Mobile)
- Pocket offline (Multi-platform)

**Anti-Goals**
<Things not in scope for this phase>
```

### Surface Detection Heuristics

When inferring surfaces from code:

**Web indicators:**
- React, Next.js, Vue, Svelte files
- `*.tsx`, `*.jsx` in `web/`, `frontend/`
- Package.json with react-dom

**Mobile indicators:**
- React Native, Swift, Kotlin files
- `*.swift`, `*.kt` in `ios/`, `android/`
- Package.json with react-native

**API indicators:**
- Express, FastAPI, Django routes
- OpenAPI/Swagger specs
- `routes/`, `api/`, `controllers/` directories

### Acceptance Oracle Pattern

Use GIVEN/WHEN/THEN for testable contracts:

```markdown
**Web — Acceptance**
- GIVEN user is on article list page
  WHEN user presses Ctrl+S on an article
  THEN article is saved offline
  AND "Saved" badge appears
  AND cached open is ≤200ms

**Mobile — Acceptance**
- GIVEN user is in article detail
  WHEN user swipes right
  THEN command menu opens
  AND menu contains save/share/bookmark actions
```

---

## Document Ingestion Pattern

Convert PRDs, specs, design docs into BRIEFs:

### Mapping Matrix

| BRIEF Section | Source Document Sections |
|--------------|--------------------------|
| Purpose & Boundary | Title, Problem Statement, Scope, Executive Summary |
| Interface Contract | Requirements, Use Cases, User Stories, UX Flows, API Specs |
| Dependencies & Integration | Architecture, System Diagram, Integrations, Data Flow |
| Work State | Roadmap, Backlog, Sprint Plan, Project Timeline |
| SPEC_SNAPSHOT | Current Features, Tech Stack, Implementation Status |
| Decisions & Rationale | ADRs, Decision Log, Architecture Decisions, Trade-offs |
| Local Reference Index | References, Related Docs, Appendices |
| Answer Pack | Synthesized from all of above |

### Ingestion Algorithm

```
1. Read source document
2. Identify document type (PRD, ADR, spec, chat transcript)
3. Parse sections
4. Map to BRIEF fields using matrix above
5. For diagrams/images:
   - Copy to _reference/spec/ or _reference/diagrams/
   - Link in SPEC_SNAPSHOT
6. For long content:
   - Summarize in BRIEF
   - Store full version in _reference/
   - Link from BRIEF
7. Mark low-confidence mappings with INFERRED
8. Generate Answer Pack from mapped content
9. Validate result against schema
10. Present to user with review instructions
```

### Chat Transcript Pattern

For chat conversations:

**Preference Rule:** During extraction, prefer **USER** lines over **ASSISTANT** lines for authoritative decisions.

**Rationale:** Users state requirements and decisions; assistants propose options. User statements are more authoritative for capturing intent.

```
ASSISTANT: We could use either React or Vue for the frontend.
USER: Let's go with React. The team knows it better.
           ↑
         (This is the decision to capture)
```

Map to:
```markdown
## Decisions & Rationale
- 2025-10-31 — Choose React over Vue (team expertise)
```

---

## Parent-Child Module Pattern

For hierarchical module structures:

### Pattern Structure

**Parent BRIEF** (`app/reader/BRIEF.md`):
```markdown
# Reader — BRIEF

## Purpose & Boundary
Provides reading functionality; owns submodules: `offline-cache/`, `renderer/`.

[... other sections ...]

## Local Reference Index
- **submodules/**
  - `offline-cache/` → [BRIEF](offline-cache/BRIEF.md)
    - key refs: [architecture](offline-cache/_reference/spec/arch.png), [cache policy](offline-cache/_reference/spec/eviction.md)
  - `renderer/` → [BRIEF](renderer/BRIEF.md)
    - key refs: [gesture map](renderer/_reference/ux/gestures.md), [performance](renderer/_reference/spec/rendering.md)
```

**Child BRIEF** (`app/reader/offline-cache/BRIEF.md`):
```markdown
# Offline Cache — BRIEF

## Purpose & Boundary
Manages offline article caching for the Reader module. Handles cache writes, reads, and eviction.

[... detailed interface contract for this submodule ...]
```

### Rules

1. **No duplication**: Parent BRIEF links to child BRIEFs, doesn't re-explain them
2. **2-4 key refs per child**: Link most useful materials for onboarding
3. **Relative links**: Use relative paths so links work in Git web UI
4. **Self-contained children**: Each child BRIEF is complete standalone
5. **Parent boundary**: Parent BRIEF defines scope that includes children

### Navigation Pattern

**Agent navigation order:**
1. Start at current module's BRIEF
2. If need parent context, go up one level to parent BRIEF
3. Follow Local Reference Index to child BRIEFs as needed
4. Only then follow links into _reference/ materials
5. Never roam the tree arbitrarily

---

## Answer Pack Pattern

Structured YAML data for agent parsing.

### Complete Template

```yaml
kind: answerpack
module: <path/to/module>
intent: "<one-line intent describing module purpose>"
surfaces:
  web:
    key_flows: ["<flow-1>", "<flow-2>"]
    acceptance: ["<oracle-1>", "<oracle-2>"]
  mobile:
    key_flows: ["<flow-1>", "<flow-2>"]
    gestures: ["<gesture-1>"]
  api:
    endpoints: ["<endpoint-1>", "<endpoint-2>"]
    authentication: "<auth-method>"
work_state:
  planned: ["ID-123 description", "ID-124 description"]
  doing: ["ID-117 description"]
  done: ["ID-101 description", "ID-102 description"]
interfaces:
  inputs: ["<input-1>", "<input-2>", "<input-3>"]
  outputs: ["<output-1>", "<output-2>"]
spec_snapshot_ref: _reference/spec/YYYY-MM-DD-vN.md
truth_hierarchy: ["source", "tests", "docs", "issues", "chat"]
```

### Field Descriptions

**kind**: Always `answerpack`

**module**: Relative path from repo root to this module

**intent**: One-line summary of what this module does

**surfaces**: Per-platform/interface details
- Add sections for each surface (web, mobile, api, desktop, cli)
- key_flows: What users/callers do
- acceptance: Testable contracts (GIVEN/WHEN/THEN)
- Surface-specific fields (gestures, endpoints, etc.)

**work_state**: Current development state
- planned: Future work with IDs
- doing: In-progress work with IDs
- done: Recently completed work with IDs

**interfaces**: Machine-readable I/O
- inputs: List of all inputs (events, APIs, user actions)
- outputs: List of all outputs (UI, events, side effects)

**spec_snapshot_ref**: Link to detailed spec in _reference/

**truth_hierarchy**: Standard list (rarely changes)

### Validation Rules

- Must be valid YAML (test with parser)
- `kind` must be `"answerpack"`
- `module` must be a path string
- `intent` must be non-empty
- `surfaces` must have at least one surface key
- `truth_hierarchy` should match standard list

---

## File Organization Pattern

### Standard Module Layout

```
<module>/
  BRIEF.md                    # Interface-first doc (required)
  CLAUDE.md                   # Agent operation guide (optional but recommended)
  _reference/                 # Deep materials (optional)
    spec/                     # Detailed specifications
      YYYY-MM-DD-v1.md        # Versioned spec snapshots
      arch-c4-l2.png          # Architecture diagrams
    diagrams/                 # Visual materials
    ux/                       # UX research, flows
    adr/                      # Architecture Decision Records
  src/                        # Source code
  tests/                      # Tests
  ...
```

### _reference/ Organization

**spec/** - Technical specifications
- Versioned spec files: `2025-10-31-v1.md`
- Architecture diagrams: C4, sequence, component
- Data models, schemas

**diagrams/** - Visual materials
- Architecture diagrams
- Flow charts
- System diagrams

**ux/** - UX and design
- User flows
- Wireframes
- Gesture maps
- Accessibility specs

**adr/** - Architecture Decision Records
- Numbered ADRs: `001-choose-database.md`
- Decision rationale and context

### Linking Pattern

**From BRIEF to _reference/:**
```markdown
## SPEC_SNAPSHOT (2025-10-31)
- Full spec: _reference/spec/2025-10-31-v1.md
- Architecture: _reference/diagrams/arch-c4-l2.png
```

**From parent to child:**
```markdown
## Local Reference Index
- `submodule/` → [BRIEF](submodule/BRIEF.md)
  - key refs: [spec](submodule/_reference/spec/detail.md)
```

Use relative paths so links work in:
- Git web UI (GitHub, GitLab, Bitbucket)
- Local filesystem
- IDEs

---

## Best Practices Summary

### DO

✅ Document what (inputs → outputs) before how (implementation)
✅ Keep BRIEF.md ≤200 lines
✅ Link to _reference/ for depth
✅ Update Interface Contract when behavior changes
✅ Date Spec Snapshots with (YYYY-MM-DD)
✅ Mark uncertain content with INFERRED
✅ Use exact section headings
✅ Include Answer Pack for agents
✅ One source of truth per fact
✅ Validate before committing

### DON'T

❌ Document implementation details in BRIEF
❌ Duplicate content (prefer links)
❌ Let BRIEF grow beyond 200 lines
❌ Leave INFERRED in Interface Contract
❌ Use vague "TBD" without context
❌ Skip Spec Snapshot dates
❌ Re-explain submodules in parent BRIEF
❌ Roam tree arbitrarily (follow links only)
❌ Contradict code (code is truth)
❌ Skip validation

---

## Quick Reference Tables

### Section Length Guidelines

| Section | Target Length | Notes |
|---------|--------------|-------|
| Purpose & Boundary | 2-4 sentences | Brief overview |
| Interface Contract | 10-30 lines | Core content |
| Dependencies | 5-10 lines | Named contracts only |
| Work State | 3-7 items each | Recent work only |
| SPEC_SNAPSHOT | 5-10 lines | + links |
| Decisions | 1 line per decision | Dated ledger |
| Local Reference Index | 2-4 refs per child | If submodules exist |
| Answer Pack | Standard structure | Valid YAML |

### Common Issues and Fixes

| Issue | Fix |
|-------|-----|
| BRIEF too long | Move details to _reference/, keep links |
| Missing Interface Contract | Add section with inputs/outputs |
| INFERRED in Interface Contract | Review and replace with verified content |
| Stale Spec Snapshot | Update date, refresh links |
| Broken _reference/ links | Fix paths or create missing files |
| Invalid YAML in Answer Pack | Validate syntax, fix errors |
| Missing submodule links | Add Local Reference Index |

---

*Patterns version: 1.0.0*
*Based on: BRIEF System v3*
