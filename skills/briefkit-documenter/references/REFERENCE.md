# BRIEF v3 Complete Specification Reference

This is the authoritative reference for BRIEF System v3. Use this when you need exact field definitions, format specifications, or validation rules.

## Table of Contents

1. [Schema Overview](#schema-overview)
2. [Field Specifications](#field-specifications)
3. [Answer Pack Specification](#answer-pack-specification)
4. [File Layout Specification](#file-layout-specification)
5. [Validation Rules](#validation-rules)
6. [Truth Hierarchy](#truth-hierarchy)
7. [State Machine](#state-machine)
8. [Ignore Patterns](#ignore-patterns)

---

## Schema Overview

### Required Sections (in order)

1. Title: `# <Module Name> — BRIEF`
2. Purpose & Boundary
3. Interface Contract (Inputs → Outputs)
4. Dependencies & Integration Points
5. Work State (Planned / Doing / Done)
6. SPEC_SNAPSHOT (YYYY-MM-DD)
7. Decisions & Rationale
8. Local Reference Index (if submodules exist)
9. Answer Pack

### Document Constraints

- **Format**: Markdown (.md)
- **Filename**: `BRIEF.md` (case-sensitive)
- **Max length**: 200 lines (excluding code blocks in Answer Pack)
- **Encoding**: UTF-8
- **Line endings**: LF (Unix) preferred, CRLF (Windows) acceptable

---

## Field Specifications

### 1. Title

**Format**: `# <Module Name> — BRIEF`

**Rules**:
- Level-1 heading (`#`)
- Module name should match directory name (case-sensitive)
- Must include ` — BRIEF` suffix with em dash (U+2014)
- No additional text after "BRIEF"

**Examples**:
```markdown
# Authentication — BRIEF          ✓ Valid
# User API — BRIEF                 ✓ Valid
# authentication — BRIEF           ✗ Case mismatch with directory "Authentication"
# Authentication BRIEF             ✗ Missing em dash
# Authentication — BRIEF v2        ✗ Extra text after BRIEF
```

---

### 2. Purpose & Boundary

**Heading**: `## Purpose & Boundary`

**Content**:
- 2-5 sentences describing what the module does
- Clear statement of boundaries (what it does and doesn't do)
- List of owned submodules (if any)

**Format**:
```markdown
## Purpose & Boundary
<2-3 sentences on what this module solves>
<1-2 sentences on boundaries/scope>
<Optional: List submodules owned: `submodule1/`, `submodule2/`>
```

**Rules**:
- Required section
- Must be concise (≤10 lines typically)
- Should answer: "What does this module do?"
- Should answer: "What does this module NOT do?"

**Example**:
```markdown
## Purpose & Boundary
Provides offline reading for articles by managing local cache. Handles
cache writes, reads, and eviction. Covers submodules: `store/` (SQLite),
`sync/` (background sync).
```

---

### 3. Interface Contract (Inputs → Outputs)

**Heading**: `## Interface Contract (Inputs → Outputs)`

**Required Subsections**:
- `**Inputs**`
- `**Outputs**`

**Optional Subsections** (add as needed):
- `**<Surface> — Interaction & Presentation**` (e.g., Web, Mobile, API)
- `**Inspirations/Comparables**` (3-5 bullets)
- `**Anti-Goals**`
- `**Performance Guarantees**`
- `**Security**`

**Format**:
```markdown
## Interface Contract (Inputs → Outputs)
**Inputs**
- <List all inputs: API calls, events, user actions, configs>

**Outputs**
- <List all outputs: UI states, events, side effects, errors>

**<Surface> — Interaction & Presentation**
- Key flows: <what users/callers do>
- Interactions/Gestures: <how they interact>
- Acceptance: <GIVEN/WHEN/THEN oracles>

**Inspirations/Comparables**
- <Product/feature> (<what aspect to emulate>)
- ...

**Anti-Goals**
- <Things explicitly not in scope>
```

**Rules**:
- Required section
- Inputs and Outputs subsections required
- Surface sections added per applicable platform
- Acceptance oracles should be testable (prefer GIVEN/WHEN/THEN)
- Inspirations: 3-5 max, with brief context
- Anti-Goals: Be specific about what's excluded

**Example**:
```markdown
## Interface Contract (Inputs → Outputs)
**Inputs**
- POST /api/auth/login with {username, password}
- Authorization header with Bearer token

**Outputs**
- 200 OK with JWT token (valid 24h)
- 401 Unauthorized if invalid credentials
- 429 Too Many Requests if rate limit exceeded

**Web — Interaction & Presentation**
- Key flows: Login form submission, session validation
- Acceptance:
  - GIVEN valid credentials
    WHEN user submits login form
    THEN receive JWT token within 2s
    AND redirected to dashboard

**Inspirations/Comparables**
- Auth0 login flow (simplicity and security)
- Firebase Auth (magic link option)

**Anti-Goals**
- No OAuth in v1 (separate module)
- No two-factor authentication in v1
```

---

### 4. Dependencies & Integration Points

**Heading**: `## Dependencies & Integration Points`

**Content**:
- **Upstream**: What this module consumes
- **Downstream**: What consumes this module

**Format**:
```markdown
## Dependencies & Integration Points
**Upstream**
- <Dependency 1>: <what is consumed>
- <Dependency 2>: <what is consumed>

**Downstream**
- <Consumer 1>: <what they use>
- <Consumer 2>: <what they use>
```

**Rules**:
- Required section
- Use named contracts, not implementation details
- Be specific about what is consumed/provided
- Include both code and service dependencies

**Example**:
```markdown
## Dependencies & Integration Points
**Upstream**
- Database: users table (read/write user records)
- Redis: session storage (store/retrieve sessions)
- Auth service: token validation API

**Downstream**
- API Gateway: routes protected by auth middleware
- Analytics service: login/logout events
```

---

### 5. Work State (Planned / Doing / Done)

**Heading**: `## Work State (Planned / Doing / Done)`

**Format**:
```markdown
## Work State (Planned / Doing / Done)
- **Planned**: [ID-###] <task> (owner @username, target YYYY-MM-DD)
- **Doing**:   [ID-###] <task> (owner @username, started YYYY-MM-DD)
- **Done**:    [ID-###] <task> (merged YYYY-MM-DD, PR #N)
```

**Rules**:
- Required section
- 3-7 items per subsection (Planned/Doing/Done)
- Each item must have issue/PR ID in [brackets]
- Include owner (@username) for Planned and Doing
- Include dates: target for Planned, started for Doing, merged for Done
- Keep only recent Done items (≤30 days); archive older ones

**Example**:
```markdown
## Work State (Planned / Doing / Done)
- **Planned**: [AUTH-45] Add password reset flow (owner @alice, target 2025-11-15)
- **Planned**: [AUTH-47] Implement rate limiting per endpoint (owner @bob, target 2025-11-25)
- **Doing**:   [AUTH-43] Add email verification (owner @charlie, started 2025-10-28)
- **Done**:    [AUTH-40] Launch v1 API (merged 2025-10-01, PR #401)
- **Done**:    [AUTH-42] Add audit logging (merged 2025-10-20, PR #425)
```

---

### 6. SPEC_SNAPSHOT (YYYY-MM-DD)

**Heading**: `## SPEC_SNAPSHOT (YYYY-MM-DD)`

**Date Format**: `(YYYY-MM-DD)` with parentheses, e.g., `(2025-10-31)`

**Content**:
- Features: Bulleted list of current features
- Tech choices: Frameworks, languages, datastores
- Performance/Constraints: SLAs, limits, guarantees
- Diagrams: Links to _reference/ diagrams
- Full spec: Link to detailed spec document in _reference/

**Format**:
```markdown
## SPEC_SNAPSHOT (YYYY-MM-DD)
- Features: <bulleted list>
- Tech: <frameworks/languages/datastores>
- Performance: <SLAs/limits>
- Diagrams: [name](_reference/diagrams/file.png)
- Full spec: [_reference/spec/YYYY-MM-DD-vN.md](_reference/spec/YYYY-MM-DD-vN.md)
```

**Rules**:
- Required section
- Date in heading must be in (YYYY-MM-DD) format
- Date should be updated when snapshot content changes
- Use relative links to _reference/ materials
- Keep concise (5-10 lines); link to detail

**Example**:
```markdown
## SPEC_SNAPSHOT (2025-10-31)
- Features: JWT auth, login/logout endpoints, session management, rate limiting
- Tech: Node.js (Express), PostgreSQL, Redis, JWT library
- Performance: p95 <200ms, 99.9% uptime SLA, 1000 req/min rate limit
- Architecture: [C4 Level 2](_reference/diagrams/arch-c4-l2.png)
- Full spec: [_reference/spec/2025-10-01-v1.md](_reference/spec/2025-10-01-v1.md)
```

---

### 7. Decisions & Rationale

**Heading**: `## Decisions & Rationale`

**Format**:
```markdown
## Decisions & Rationale
- YYYY-MM-DD — <Decision> (<Rationale>)
- YYYY-MM-DD — <Decision> (<Rationale>)
```

**Rules**:
- Required section
- Chronological order (oldest first or newest first, be consistent)
- Date in YYYY-MM-DD format
- Decision brief (1 line)
- Rationale concise (1-2 sentences or link to ADR)
- Can link to detailed ADR in _reference/adr/

**Example**:
```markdown
## Decisions & Rationale
- 2025-08-15 — Use JWT over session cookies (stateless, easier horizontal scaling)
- 2025-09-01 — PostgreSQL over MongoDB (relational data, strong consistency needs)
- 2025-10-05 — Audit all mutations, not reads (compliance requirement, performance trade-off)
```

---

### 8. Local Reference Index

**Heading**: `## Local Reference Index`

**When Required**: If module has submodules with their own BRIEFs

**Format**:
```markdown
## Local Reference Index
- **submodules/**
  - `submodule-name/` → [BRIEF](submodule-name/BRIEF.md)
    - key refs: [diagram](submodule-name/_reference/spec/diagram.png), [spec](submodule-name/_reference/spec/detail.md)
```

**Rules**:
- Required if submodules exist
- List each submodule with link to its BRIEF
- 2-4 key references per submodule
- Use relative paths
- Links must resolve (validation checks this)

**Example**:
```markdown
## Local Reference Index
- **submodules/**
  - `offline-cache/` → [BRIEF](offline-cache/BRIEF.md)
    - key refs: [SQLite schema](offline-cache/_reference/spec/schema.sql), [eviction policy](offline-cache/_reference/spec/eviction.md)
  - `renderer/` → [BRIEF](renderer/BRIEF.md)
    - key refs: [gesture map](renderer/_reference/ux/gestures.md), [performance](renderer/_reference/spec/rendering.md)
```

---

### 9. Answer Pack

**Heading**: `## Answer Pack`

**Format**: YAML code block

**Schema**:
```yaml
kind: answerpack
module: <path/to/module>
intent: "<one-line description>"
surfaces:
  <surface-name>:
    key_flows: ["<flow>", ...]
    acceptance: ["<oracle>", ...]
    # Surface-specific fields (gestures, endpoints, etc.)
work_state:
  planned: ["<ID> <description>", ...]
  doing: ["<ID> <description>", ...]
  done: ["<ID> <description>", ...]
interfaces:
  inputs: ["<input>", ...]
  outputs: ["<output>", ...]
spec_snapshot_ref: <path to detailed spec>
truth_hierarchy: ["source", "tests", "docs", "issues", "chat"]
```

**Required Fields**:
- `kind`: Must be `"answerpack"`
- `module`: Relative path from repo root
- `intent`: One-line summary
- `interfaces.inputs`: List of inputs
- `interfaces.outputs`: List of outputs
- `truth_hierarchy`: Standard list

**Optional Fields**:
- `surfaces`: Per-surface details (add as needed)
- `work_state`: Current work state
- `spec_snapshot_ref`: Link to detailed spec

**Rules**:
- Required section
- Must be valid YAML (syntax check)
- Strings in quotes if they contain special chars
- Arrays use YAML list syntax

**Example**:
```yaml
kind: answerpack
module: app/auth
intent: "User authentication via username/password with JWT tokens"
surfaces:
  web:
    key_flows: ["login form", "logout", "session validation"]
    acceptance: ["login <2s", "token valid 24h", "auto-logout on expire"]
  api:
    endpoints: ["POST /api/auth/login", "POST /api/auth/logout"]
    authentication: "Bearer JWT token"
work_state:
  planned: ["AUTH-45 password reset", "AUTH-47 rate limiting"]
  doing: ["AUTH-43 email verification"]
  done: ["AUTH-40 v1 launch", "AUTH-42 audit logging"]
interfaces:
  inputs: ["username", "password", "JWT token"]
  outputs: ["JWT token", "401 error", "429 rate limit"]
spec_snapshot_ref: _reference/spec/2025-10-01-v1.md
truth_hierarchy: ["source", "tests", "docs", "issues", "chat"]
```

---

## Answer Pack Specification

### Field Reference

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `kind` | string | Yes | Must be `"answerpack"` |
| `module` | string | Yes | Relative path from repo root |
| `intent` | string | Yes | One-line module purpose |
| `surfaces` | object | No | Per-surface details (web, mobile, api, etc.) |
| `surfaces.<name>.key_flows` | array | No | Main user/caller flows for this surface |
| `surfaces.<name>.acceptance` | array | No | Acceptance criteria for this surface |
| `surfaces.<name>.gestures` | array | No | Mobile gestures (tap, swipe, etc.) |
| `surfaces.<name>.endpoints` | array | No | API endpoints |
| `surfaces.<name>.authentication` | string | No | Auth method for API |
| `work_state` | object | No | Current work state |
| `work_state.planned` | array | No | Planned work items with IDs |
| `work_state.doing` | array | No | In-progress work items with IDs |
| `work_state.done` | array | No | Recently completed work items with IDs |
| `interfaces` | object | Yes | Input/output contracts |
| `interfaces.inputs` | array | Yes | List of all inputs |
| `interfaces.outputs` | array | Yes | List of all outputs |
| `spec_snapshot_ref` | string | No | Link to detailed spec in _reference/ |
| `truth_hierarchy` | array | Yes | Standard: `["source", "tests", "docs", "issues", "chat"]` |

---

## File Layout Specification

### Module Directory Structure

```
<module>/
  BRIEF.md                    # Required: Interface-first doc
  CLAUDE.md                   # Optional: Agent operation guide
  _reference/                 # Optional: Deep materials
    spec/                     # Detailed specifications
      YYYY-MM-DD-vN.md        # Versioned spec snapshots
      *.sql, *.json           # Schemas, configs
    diagrams/                 # Visual materials
      *.png, *.svg            # Architecture, flows
    ux/                       # UX research, flows
    adr/                      # Architecture Decision Records
      NNN-title.md            # Numbered ADRs
    security/                 # Security docs
    api/                      # API documentation
  src/                        # Source code
  tests/                      # Tests
  ...
```

### Naming Conventions

**BRIEF.md**:
- Exactly `BRIEF.md` (case-sensitive)
- Must be at module root

**_reference/**:
- Starts with underscore (indicates informative, not normative)
- Subdirectories for organization
- Use lowercase, hyphens for file names

**Spec files**:
- Date-prefixed: `YYYY-MM-DD-vN.md` (e.g., `2025-10-31-v1.md`)
- Enables chronological sorting

**Diagrams**:
- Descriptive names: `arch-c4-l2.png`, `auth-flow.svg`
- PNG for raster, SVG for vector (preferred)

**ADRs**:
- Numbered: `001-choose-database.md`
- Zero-padded for sorting

---

## Validation Rules

### Tier-1 Blockers

These issues MUST be fixed before code changes can proceed:

1. **Missing BRIEF.md** - Module directory lacks BRIEF.md file
2. **Missing Interface Contract** - BRIEF lacks `## Interface Contract (Inputs → Outputs)` section
3. **INFERRED in Interface Contract** - Interface Contract contains `> INFERRED:` markers
4. **Invalid Answer Pack YAML** - Answer Pack has syntax errors or invalid structure
5. **File too long** - BRIEF.md exceeds 200 lines (excluding Answer Pack code block)

### Tier-2 Warnings

These issues SHOULD be fixed soon but don't block immediately:

1. **Missing SPEC_SNAPSHOT** - BRIEF lacks `## SPEC_SNAPSHOT (YYYY-MM-DD)` section
2. **Undated SPEC_SNAPSHOT** - Snapshot heading doesn't match `(YYYY-MM-DD)` format
3. **Missing Answer Pack** - BRIEF lacks `## Answer Pack` section
4. **Missing Local Reference Index** - Module has submodules but no Local Reference Index
5. **Broken _reference/ links** - Links to _reference/ files don't resolve
6. **Stale SPEC_SNAPSHOT** - Snapshot date is >90 days old

### Validation Algorithm

```python
def validate_brief(brief_path):
    errors = []
    warnings = []

    # Tier-1 checks
    if not exists(brief_path):
        errors.append("Missing BRIEF.md")
        return errors, warnings

    content = read_file(brief_path)
    lines = content.split('\n')

    if not has_section(content, "## Interface Contract (Inputs → Outputs)"):
        errors.append("Missing Interface Contract section")

    interface_section = extract_section(content, "## Interface Contract")
    if "INFERRED:" in interface_section:
        errors.append("INFERRED markers in Interface Contract")

    answer_pack = extract_answer_pack(content)
    if answer_pack and not is_valid_yaml(answer_pack):
        errors.append("Invalid Answer Pack YAML")

    if len(lines) > 200:  # Exclude code blocks in count
        errors.append(f"BRIEF too long: {len(lines)} lines (max 200)")

    # Tier-2 checks
    if not has_section(content, "## SPEC_SNAPSHOT"):
        warnings.append("Missing SPEC_SNAPSHOT")
    elif not matches_pattern(content, r"## SPEC_SNAPSHOT \(\d{4}-\d{2}-\d{2}\)"):
        warnings.append("SPEC_SNAPSHOT not dated correctly")
    else:
        snapshot_date = extract_snapshot_date(content)
        if days_since(snapshot_date) > 90:
            warnings.append(f"Stale SPEC_SNAPSHOT ({days_since(snapshot_date)} days old)")

    if not has_section(content, "## Answer Pack"):
        warnings.append("Missing Answer Pack")

    if has_submodules(dirname(brief_path)) and not has_section(content, "## Local Reference Index"):
        warnings.append("Missing Local Reference Index (submodules detected)")

    broken_links = check_reference_links(content, dirname(brief_path))
    if broken_links:
        warnings.extend([f"Broken link: {link}" for link in broken_links])

    return errors, warnings
```

---

## Truth Hierarchy

When information conflicts, follow this precedence (highest to lowest):

1. **Running source code & tests** - What the code actually does
2. **Runtime configuration** - Environment variables, feature flags, configs
3. **BRIEF.md** - Normative interface documentation
4. **_reference/** - Informative deep specs and research
5. **Issues/PRs** - Historical context and discussions
6. **Chat/discussions** - Informal communications

**Rule**: If BRIEF contradicts code, the code is correct and BRIEF should be updated.

**Exception**: During design phase (before implementation), BRIEF may describe intended behavior that doesn't yet exist in code.

---

## State Machine

BRIEFs progress through a lifecycle:

```
┌─────────┐
│ missing │ (no BRIEF.md exists)
└────┬────┘
     │ create scaffold
┌────▼──────────┐
│  scaffolded   │ (headings only, no content)
└────┬──────────┘
     │ generate/fill content
┌────▼──────────────┐
│ draft-inferred    │ (has INFERRED: markers)
└────┬──────────────┘
     │ human review, remove INFERRED
┌────▼──────────┐
│  confirmed    │ (complete, no INFERRED)
└────┬──────────┘
     │ time passes, links break, or snapshot becomes old
┌────▼──────────┐
│    stale      │ (needs refresh)
└────┬──────────┘
     │ update and refresh
     │
     └──────────┐
                │
     ┌──────────▼──────┐
     │   confirmed     │
     └─────────────────┘
```

### State Definitions

**missing**: No BRIEF.md file in module directory
- **Action**: Block writes, scaffold BRIEF

**scaffolded**: BRIEF.md with headings but no content
- **Action**: Block writes, require completion

**draft-inferred**: Content with `> INFERRED:` markers
- **Action**: Block if Interface Contract has INFERRED, otherwise warn

**confirmed**: Complete BRIEF, no INFERRED markers in Interface Contract
- **Action**: Allow writes

**stale**: Spec Snapshot >90 days old OR broken _reference/ links
- **Action**: Warn, request refresh (don't block)

### INFERRED Marker Usage

Mark low-confidence content:
```markdown
**Inputs**
> INFERRED: Based on route handler signatures
- POST /api/login
- POST /api/logout
```

Rules:
- Place `> INFERRED: <explanation>` before inferred content
- Explain source of inference
- Remove after human verification
- Interface Contract with INFERRED = Tier-1 blocker

---

## Ignore Patterns

### Default .briefignore

```
# Build outputs
dist/
build/
out/
target/
.next/
.cache/
coverage/

# Dependencies
node_modules/
vendor/
Pods/
third_party/

# Platform-specific
android/
ios/
bin/
obj/
__pycache__/

# Version control
.git/

# Temporary
tmp/
temp/
*.tmp

# Minified/generated
*.min.*
*.map
*.lock
```

### Custom .briefignore

Add module-local `.briefignore` to override:
```
# Module-specific ignores
fixtures/
mocks/
```

Module-local ignores merge with parent ignores.

---

## Quick Reference

### Section Heading Quick Reference

```markdown
# <Module Name> — BRIEF
## Purpose & Boundary
## Interface Contract (Inputs → Outputs)
## Dependencies & Integration Points
## Work State (Planned / Doing / Done)
## SPEC_SNAPSHOT (YYYY-MM-DD)
## Decisions & Rationale
## Local Reference Index
## Answer Pack
```

### Common Format Patterns

**Date**: `YYYY-MM-DD` (e.g., `2025-10-31`)
**Issue ID**: `[ID-###]` or `[PROJECT-###]`
**Owner**: `@username`
**Link**: `[text](relative/path)`
**INFERRED**: `> INFERRED: <explanation>`

### Validation Quick Check

```bash
# Check required sections
grep -q "^## Interface Contract (Inputs → Outputs)" BRIEF.md || echo "Missing Interface Contract"
grep -Eq "^## SPEC_SNAPSHOT \([0-9]{4}-[0-9]{2}-[0-9]{2}\)" BRIEF.md || echo "Missing or undated SPEC_SNAPSHOT"
grep -q "^## Answer Pack" BRIEF.md || echo "Missing Answer Pack"

# Check for blockers
grep "INFERRED:" BRIEF.md | grep -q "^## Interface Contract" && echo "INFERRED in Interface Contract"

# Check length
[ $(wc -l < BRIEF.md) -le 200 ] || echo "BRIEF too long"
```

---

*Reference version: 1.0.0*
*Based on: BRIEF System v3*
*Canonical source: This document is authoritative for BRIEF v3*
