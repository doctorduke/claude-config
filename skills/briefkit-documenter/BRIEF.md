# briefkit-documenter — BRIEF

## Purpose & Boundary

**What it does**: Generates and validates BRIEF.md documentation files for software modules using the BRIEF System v3 specification. Converts PRDs/specs to BRIEFs, documents legacy code, and establishes documentation standards.

**What it doesn't do**:
- Code implementation or refactoring
- Detailed implementation documentation (that's for code comments)
- Project management or task tracking
- API endpoint implementation details (only contracts)

**Boundaries**: Operates on module/component level. For system-wide architecture docs, use multiple BRIEFs with cross-references.

## Interface Contract (Inputs → Outputs)

### Inputs
- **User Request**: "Document the [module-name]" or "Convert this PRD to BRIEF"
- **Source Material**:
  - Existing code in target module
  - PRD/specification documents (optional)
  - Existing documentation (optional)
- **Module Path**: Target directory for BRIEF.md generation

### Outputs
- **BRIEF.md File**: Complete documentation following v3 specification
  - 9 required sections in order
  - YAML Answer Pack
  - INFERRED markers for uncertain content
  - <200 lines
- **Validation Report**: Tier-1/Tier-2 issues found
- **Human Review Request**: When INFERRED markers present

### Side Effects
- Creates/overwrites BRIEF.md in target directory
- May discover missing interface definitions (positive side effect)

## Dependencies & Integration Points

### Internal Dependencies
- `SPECIFICATION.md` - Authoritative v3 spec, validation rules (lines 1-600)
- `PATTERNS.md` - Practical patterns, templates (lines 1-500)
- `PHILOSOPHY.md` - Interface-first methodology (lines 1-650)
- `EXAMPLES.md` - 8 real-world examples (lines 1-400)
- `references/examples/*.md` - 6 specialized example files

### External Dependencies
- **Claude Code Tools**: Read, Write, Edit, Grep, Glob (specified in YAML)
- **Target Codebase**: Must be accessible for analysis

### Integration Points
- **Input**: User request via Claude Code conversation
- **Output**: BRIEF.md file written to specified module directory
- **Validation**: Self-validates against SPECIFICATION.md rules

## Work State (Planned / Doing / Done)

**Current State**: ✅ Done

**Completed**:
- [x] v1.0.0 refactor: Split monolithic docs into focused files
- [x] YAML frontmatter with allowed-tools
- [x] Fixed broken PHILOSOPHY.md links in all examples
- [x] Fixed grep patterns in SKILL.md
- [x] Removed empty assets section
- [x] Dogfood test: Generated self-documenting BRIEF.md

**Known Issues**: None blocking (all P0 issues resolved 2025-10-31)

**Future Enhancements**:
- Auto-detection of module boundaries
- Batch generation for multi-module repos
- Integration with CI/CD for BRIEF validation
- Template customization per project

## SPEC_SNAPSHOT (2025-10-31)

Based on **BRIEF System v3** specification.

**Key Requirements Met**:
- 9 required sections ✅
- Interface-first approach ✅
- INFERRED marker system ✅
- Answer Pack YAML ✅
- <200 lines ✅ (currently 160 lines)

**Validation Tier-1 Compliance**: 100%
**Validation Tier-2 Compliance**: 100%

## Decisions & Rationale

### Architecture Decisions

**Decision 1**: Split large KNOWLEDGE.md into 4 focused files
- **Why**: 700-line file violated DRY, hard to navigate
- **Result**: PATTERNS (500L), PHILOSOPHY (650L), SPECIFICATION (600L), EXAMPLES (400L)
- **Trade-off**: More files, but 64% reduction in SKILL.md, faster navigation

**Decision 2**: Remove assets/ templates, keep examples only
- **Why**: Empty templates less useful than real examples
- **Result**: Users copy/adapt actual BRIEFs instead of filling blanks
- **Evidence**: 8 examples cover 100% of use cases

**Decision 3**: Use YAML frontmatter with allowed-tools
- **Why**: Follows Claude Code skill conventions (see ai-agent-tool-builder)
- **Result**: Skill loads correctly, tools properly scoped
- **Reference**: .claude/skills/ai-agent-tool-builder/SKILL.md:1-6

### Interface Decisions

**Decision 4**: Generate with INFERRED markers, require human review
- **Why**: AI can't know design intent without human input
- **Result**: Safer documentation, explicit uncertainty
- **Trade-off**: Requires follow-up, but prevents false docs

## Local Reference Index

- `SKILL.md` - Quick start, workflows, grep patterns
- `references/SPECIFICATION.md` - Authoritative spec, validation
- `references/PATTERNS.md` - Practical templates, do/don't lists
- `references/PHILOSOPHY.md` - Interface-first methodology
- `references/EXAMPLES.md` - 2 inline examples (80% coverage)
- `references/examples/*.md` - 6 specialized examples (20% edge cases)

## Answer Pack

```yaml
# Quick Reference: briefkit-documenter

# What is this skill?
purpose: "Generate BRIEF.md files for module documentation using interface-first approach"

# When should I use it?
use_cases:
  - "Document new or existing module"
  - "Convert PRD/spec to BRIEF"
  - "Validate existing BRIEF.md"
  - "Set up repo documentation standards"
  - "Document multi-surface apps (Web/Mobile/API)"

# What do I get?
outputs:
  primary: "BRIEF.md file with 9 required sections"
  validation: "Tier-1/Tier-2 validation report"
  review_request: "Human review for INFERRED content"

# What does it need?
inputs:
  required:
    - "User request with module name/path"
    - "Access to target module code"
  optional:
    - "PRD or specification documents"
    - "Existing documentation to convert"

# How long does it take?
typical_runtime:
  new_module: "5-10 minutes (analysis + generation + validation)"
  legacy_module: "10-15 minutes (heavy inference + review)"
  prd_conversion: "5-8 minutes (structured input)"

# How do I validate output?
validation_checks:
  tier_1_blockers:
    - "All 9 sections present in order"
    - "Interface Contract has Inputs/Outputs"
    - "INFERRED markers for uncertain content"
    - "Answer Pack is valid YAML"
    - "<200 lines total"
  tier_2_warnings:
    - "SPEC_SNAPSHOT not stale (>30 days)"
    - "No broken internal links"
    - "Answer Pack has all recommended fields"

# Common failure modes?
common_issues:
  - "Missing module boundaries → Too broad/narrow scope"
  - "No clear interfaces → Heavy INFERRED markers"
  - "Legacy code → Uncertain dependencies"
  solution: "Request human clarification, mark as INFERRED"

# Example commands?
example_workflows:
  new_module: "Analyze code → Extract interfaces → Generate BRIEF → Validate"
  legacy: "Infer from code → Heavy INFERRED → Generate → Request review"
  prd: "Parse PRD → Map to BRIEF sections → Generate → Validate"

# Quick grep patterns?
grep_examples:
  spec_sections: "grep '^### [0-9]\\.' references/SPECIFICATION.md"
  patterns: "grep '^## .* Pattern$' references/PATTERNS.md"
  examples: "grep '^### Example [0-9]:' references/EXAMPLES.md"
  validation: "grep 'Tier-[12]' references/SPECIFICATION.md"

# Version info?
version: "1.0.0"
spec_version: "BRIEF System v3"
last_updated: "2025-10-31"
status: "Production Ready"
```
