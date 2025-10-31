---
name: briefkit-documenter
description: This skill should be used when creating interface-first documentation for codebases using the BRIEF system v3. It enables generating BRIEF.md files, validating documentation structure, converting design documents into BRIEFs, and maintaining module-level documentation with inputs-outputs contracts. Use for documenting software modules, creating architectural documentation, or establishing interface-first documentation practices.
---

# Briefkit Documenter

This skill provides comprehensive guidance for creating, validating, and maintaining interface-first documentation using the BRIEF system v3. BRIEF (Boundary, Requirements, Interface, Evaluation, Foresight) is a documentation methodology that prioritizes documenting what a module does (inputs → outputs) before how it does it (implementation details).

## Purpose

Enable creating professional, agent-friendly, human-readable module documentation that lives inside each part of a codebase. BRIEF documentation helps developers and AI agents quickly understand:

- What a module does and its boundaries
- How to interact with it (inputs and outputs)
- Current work state and decisions
- Dependencies and integration points

## When to Use This Skill

Use this skill when:

- **Creating module documentation** - Document new or existing code modules
- **Establishing documentation standards** - Set up interface-first docs for a project
- **Converting design documents** - Transform PRDs, ADRs, or specifications into BRIEFs
- **Validating documentation** - Check existing BRIEFs for completeness and correctness
- **Refactoring documentation** - Update docs to match code changes
- **Onboarding codebases** - Create comprehensive documentation for legacy projects
- **Multi-surface projects** - Document applications with Web, Mobile, or multiple platforms
- **Agent-friendly docs** - Create documentation optimized for AI agent consumption

## Core Concepts

### Interface-First Philosophy

Document the **what** before the **how**:

1. **Start with boundaries** - What does this module do? What doesn't it do?
2. **Define contracts** - What inputs does it accept? What outputs does it produce?
3. **Specify behavior** - How should it respond to various inputs?
4. **Document decisions** - Why was it built this way?

### Truth Hierarchy

When documentation conflicts with reality, follow this precedence:

1. **Running source code & tests** (highest truth)
2. **Runtime configuration** (environment, feature flags)
3. **BRIEF.md** (normative interface documentation)
4. **_reference/** (informative deep specs)
5. **Issues/PRs** (historical context)
6. **Chat/discussions** (lowest truth)

If code contradicts BRIEF, the code is correct and BRIEF should be updated.

### Layered Documentation

Keep documentation scannable and maintainable:

- **BRIEF.md** - Short (≤200 lines), normative, interface-focused
- **_reference/** - Deep specs, diagrams, research, detailed guides
- **CLAUDE.md** - Operational guide for AI agents working in the module

## How to Use This Skill

### Quick Start: Generate a BRIEF

When asked to create a BRIEF.md:

1. **Understand the module**
   - Analyze code, imports, exports, APIs
   - Identify boundaries and responsibilities
   - Determine surfaces (Web, Mobile, API, CLI)

2. **Generate BRIEF.md with required sections**
   - Title: `# <Module Name> — BRIEF`
   - Purpose & Boundary
   - Interface Contract (Inputs → Outputs)
   - Dependencies & Integration Points
   - Work State (Planned / Doing / Done)
   - SPEC_SNAPSHOT (dated with YYYY-MM-DD)
   - Decisions & Rationale
   - Local Reference Index
   - Answer Pack (YAML)

3. **Validate completeness**
   - All required sections present
   - Interface Contract complete (no INFERRED markers)
   - Spec Snapshot dated correctly
   - Answer Pack valid YAML
   - File ≤200 lines
   - Mark uncertain fields with `> INFERRED: <explanation>`

4. **Provide next steps**
   - Request review of Interface Contract
   - Suggest _reference/ materials to create
   - Recommend validation workflow

### Validation Workflow

When asked to validate BRIEF.md files:

1. **Scan for BRIEF.md files** in the repository
2. **Check each BRIEF** against required sections
3. **Validate structure:**
   - Required sections present and in correct order
   - Interface Contract complete (no `INFERRED:` markers in this section)
   - Spec Snapshot uses correct date format: `(YYYY-MM-DD)`
   - Local Reference Index present (if submodules exist)
   - Answer Pack is valid YAML
   - File length ≤200 lines (excluding code blocks)
4. **Report issues** with specific line references
5. **Offer to fix** identified problems

### Document Ingestion

When asked to convert documents (PRDs, specs, design docs) to BRIEF:

1. **Read source document**
2. **Map sections to BRIEF fields:**
   - Title/Problem → Purpose & Boundary
   - Requirements/Use Cases → Interface Contract
   - Architecture → Dependencies & Integration Points
   - Roadmap/Backlog → Work State
   - Technical Decisions → Decisions & Rationale
   - Diagrams/Specs → Copy to _reference/, link in Spec Snapshot
3. **Generate complete BRIEF.md**
4. **Mark uncertain fields** with `> INFERRED: <explanation>`
5. **Store referenced materials** in _reference/ with proper links

### Multi-Surface Documentation

For applications with multiple platforms (Web, Mobile, Desktop):

1. **Document per-surface in Interface Contract:**
   - **Web** - flows, key interactions, acceptance oracles
   - **Mobile** - flows, gestures, acceptance oracles
   - **Desktop** - flows, keyboard shortcuts, acceptance oracles

2. **Specify surface-specific behavior:**
   - Different inputs (clicks vs taps vs key combos)
   - Different outputs (screens vs toasts vs notifications)
   - Platform-specific constraints

3. **Include inspirations** - 3-5 examples for product taste

## Bundled Resources

### References (`references/`)

- **PATTERNS.md** - Core briefkit patterns and best practices
  - BRIEF.md schema details
  - Validation rules
  - State machine (missing → scaffolded → confirmed → stale)
  - Multi-surface patterns

- **EXAMPLES.md** - Real-world BRIEF examples
  - Complete module BRIEFs
  - Multi-surface documentation
  - Parent-child module relationships
  - Document ingestion examples

- **KNOWLEDGE.md** - Deep methodology and philosophy
  - Interface-first design principles
  - When to use interface-first docs
  - How BRIEF differs from traditional docs
  - Agent-parsable documentation design

- **REFERENCE.md** - Complete BRIEF v3 specification
  - Full schema reference
  - Field-by-field explanations
  - Hook integration patterns
  - CI/CD integration

To access these resources, use the Read tool:
```
Read references/PATTERNS.md    # For pattern guidance
Read references/EXAMPLES.md    # For concrete examples
Read references/KNOWLEDGE.md   # For deep methodology
Read references/REFERENCE.md   # For complete spec
```

### Assets (`assets/`)

- **BRIEF.md.template** - Complete BRIEF template with placeholders
- **claude-rules.md.template** - CLAUDE.md template for repos
- **.briefignore.template** - Default ignore patterns

These assets can be copied and customized when initializing briefkit in a repository.

## Workflow Patterns

### Pattern 1: New Module Documentation

```
User: "Document the authentication module"

Steps:
1. Analyze app/auth/ directory structure
2. Identify interfaces (API endpoints, events)
3. Determine boundaries (what auth does/doesn't do)
4. Generate complete BRIEF.md with all sections
5. Validate against rules
6. Provide to user with review instructions
```

### Pattern 2: Repository-Wide Initialization

```
User: "Set up briefkit for this entire repository"

Steps:
1. Create root BRIEF.md (app-level overview)
2. Identify module directories (packages, services, components)
3. Generate BRIEF.md for each module
4. Create .briefignore with sensible defaults
5. Establish Local Reference Index linking structure
6. Provide validation workflow instructions
```

### Pattern 3: BRIEF Validation

```
User: "Validate all BRIEF.md files"

Steps:
1. Find all BRIEF.md files using Glob
2. Read each file
3. Check against validation rules
4. Report issues with specifics
5. Offer automated fixes for common problems
```

### Pattern 4: PRD → BRIEF Conversion

```
User: "Convert this PRD into a BRIEF for the search module"

Steps:
1. Read PRD document
2. Extract sections and map to BRIEF fields
3. Generate BRIEF.md with mapped content
4. Mark low-confidence sections with INFERRED
5. Store referenced diagrams in _reference/
6. Create Spec Snapshot with links
7. Request review of inferred sections
```

## Best Practices

### Keep BRIEF Scannable

- Limit BRIEF.md to ≤200 lines
- Use bullet points for lists
- Link to _reference/ for depth
- Avoid duplication (one source of truth per fact)

### Maintain Currency

- Update Interface Contract when behavior changes
- Update Work State in same PR as code changes
- Date Spec Snapshots with format: `(YYYY-MM-DD)`
- Add decisions when making architectural choices

### Interface-First Ordering

Document in this sequence:

1. What it does (Purpose)
2. How to interact (Interface Contract)
3. What it depends on (Dependencies)
4. Current state (Work State)
5. Technical details (Spec Snapshot)
6. Why decisions were made (Decisions)

### Agent-Parsable Structure

- Use consistent section headings (exact match required)
- Include Answer Pack (YAML) for structured data
- Follow truth hierarchy when conflicts arise
- Mark uncertain content with `> INFERRED:`

## Validation Rules

Apply these rules when validating BRIEFs:

**Tier-1 Blockers** (must fix before proceeding):
- Missing BRIEF.md file
- Missing Interface Contract section
- `INFERRED:` markers in Interface Contract section
- Invalid YAML in Answer Pack
- File >200 lines (excluding code blocks)

**Tier-2 Warnings** (should fix soon):
- Missing Spec Snapshot
- Spec Snapshot not dated with `(YYYY-MM-DD)` format
- Missing Answer Pack section
- Missing Local Reference Index (when submodules exist)
- Broken links to _reference/ files
- Stale Spec Snapshot (>90 days old)

## Common Questions

**Q: What if I don't know some details?**
A: Mark uncertain sections with `> INFERRED: <explanation>`. This signals to reviewers that human verification is needed.

**Q: How do I handle submodules?**
A: Each submodule gets its own BRIEF.md. Parent BRIEF includes Local Reference Index linking to child BRIEFs. Never re-explain submodule internals in parent.

**Q: What goes in _reference/ vs BRIEF.md?**
A: BRIEF.md = short, normative, scannable interface docs. _reference/ = deep specs, diagrams, research, detailed guides. Link from BRIEF to _reference/.

**Q: How do I document legacy code?**
A: Start with Interface Contract (analyze public APIs, exports). Infer purpose from directory name and code. Mark everything with INFERRED markers, then refine with team input.

**Q: Should I document implementation details?**
A: No. BRIEF focuses on "what" (interface, behavior, contracts), not "how" (implementation). Implementation details go in code comments or _reference/spec/ if needed.

## Next Steps

After loading this skill:

1. **Try it out**: Ask to create a BRIEF.md for an existing module
2. **Validate**: Ask to validate existing BRIEFs in the repository
3. **Establish workflow**: Set up regular BRIEF validation in PR process
4. **Customize**: Add organization-specific patterns to references/
5. **Share**: Distribute skill to team members for consistency

---

## Skill Metadata

- **Version**: 1.0.0
- **Based on**: BRIEF System v3
- **Compatible with**: Claude Code, Cursor, Cody
- **License**: MIT (adapt freely for your organization)
- **Maintenance**: Review every 6 months or when BRIEF spec updates
