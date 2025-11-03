# Evaluate and Refactor Miscellaneous Files

**Purpose**: Evaluate miscellaneous files after work sessions and refactor them into system components (skills, commands, tools, documentation) rather than just moving or deleting them.

**Trigger**: When root-level or scattered files accumulate after work sessions, blocking git operations (subtree pulls, etc.) or creating organizational debt.

**When to use**: Run this command when git status shows many untracked files or when files are blocking git operations.

---

## Phase 1: Evaluation and Scoring

### 1.1 Comprehensive File Discovery

**Action**: Identify all files requiring evaluation

```bash
# Find all untracked files
git status --short | grep "^??"

# Find all modified files
git status --short | grep "^ M"

# Find all deleted files
git status --short | grep "^D"

# Get file metadata (size, lines, date)
for file in $(git status --short | awk '{print $2}'); do
  echo "$file: $(wc -l < "$file" 2>/dev/null || echo 0) lines, $(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0) bytes"
done
```

**Output**: List of all files with pending changes, categorized by change type (untracked, modified, deleted)

### 1.2 Mathematical Scoring Formula

**Critical Principle**: Use a formula that understands value relationships, not simple addition.

**Formula**:
```
Score = (Direct * (1 + Future/10 * Direct/10)) + (Support * min(Direct/5, 1))
```

**Rationale**:
- **Base value**: Direct usefulness is the foundation
- **Compound multiplier**: Future utility amplifies direct value when both are high (exponential relationship)
  - When both are 8+: They compound (8 * 1.72 = 13.76 vs 8+8 = 16)
  - When direct is low: Future doesn't help much (2 * 1.06 = 2.12 vs 2+8 = 10)
- **Support bonus**: Only adds value if base is sufficient (threshold effect)
  - If Direct < 5, support is discounted (can't support what's not useful)
  - Support threshold: `min(Direct/5, 1)` ranges from 0.0 to 1.0

**Scoring Metrics** (0-10 scale for each):
- **Direct Usefulness**: Current value and application
  - 0-2: No current use, artifact only
  - 3-5: Some use, but redundant or superseded
  - 6-7: Useful reference or documentation
  - 8-9: Important documentation or reference
  - 10: Critical documentation
- **Future Utility**: Projected value for future work
  - 0-2: No future value, artifact only
  - 3-5: Some future reference value
  - 6-7: Useful for future work or reference
  - 8-9: Important for future planning or analysis
  - 10: Critical for future work
- **Support Effort**: Value as supporting material
  - 0-2: No support effort needed
  - 3-5: Some support effort for future work
  - 6-7: Useful support material for future work
  - 8-9: Important support material
  - 10: Critical support material

**Score Interpretation**:
- **0-5**: No value (discard)
- **5-10**: Low value (evaluate carefully)
- **10-15**: Moderate value (keep with refactoring)
- **15-20**: High value (important component)
- **20-25**: Very high value (critical component)
- **25+**: Exceptional value (system-critical)

### 1.3 Evaluation Table Generation

**Action**: Create comprehensive evaluation table with columns:

| Column | Description |
|--------|-------------|
| **File** | File name (strip underscores/hyphens for readability in tables) |
| **Changes Description** | What changed or what the file contains |
| **Effect of Changes** | Impact if file is lost or kept |
| **Relationship to Recent Work** | How it relates to active development |
| **Direct Usefulness** | Score 0-10 |
| **Future Utility** | Score 0-10 |
| **Support Effort** | Score 0-10 |
| **Total Score** | Calculated using formula above |
| **Refactor Required** | Yes/No - does it need conversion to component? |
| **Refactor Difficulty** | Low/Medium/High |
| **Refactor Utility** | Low/Medium/High/Critical |
| **Component Type** | Skill Component / Tool / Documentation / Workflow / Command |
| **Target Location** | Where it should live after refactoring |
| **Recommendation** | KEEP / EVALUATE / DISCARD / TEMPORARY |

**Key Terms**:
- **Component Type**: What the file should become (not just where it should move)
- **Refactor Required**: Does it need conversion to a system component?
- **Refactor Utility**: How much value does refactoring provide?

---

## Phase 2: Component Meta-Analysis

### 2.1 Component Type Classification

**Critical Principle**: Refactoring is about converting files into usable system components, not just moving them.

**Component Types**:

1. **Skill Component**
   - **Definition**: Reusable knowledge/capability that can be invoked
   - **Location**: `.claude/skills/{skill-name}/`
   - **Structure**: PATTERNS.md, KNOWLEDGE.md, REFERENCE.md, EXAMPLES.md, scripts/
   - **When to use**: Files contain reusable methodology, patterns, or knowledge
   - **Examples**: Planning patterns, architectural patterns, analysis methodologies

2. **Command Template**
   - **Definition**: Workflow template that guides multi-step processes
   - **Location**: `.claude/commands/{command-name}.md`
   - **Structure**: Markdown file with workflow instructions
   - **When to use**: Files contain repeatable workflows or processes
   - **Examples**: Apply cycle remediation patterns, generate ADRs, execute planning

3. **Tool**
   - **Definition**: Standalone executable for analysis/generation
   - **Location**: `tools/{category}/`
   - **Structure**: Python/Node.js scripts with CLI interface
   - **When to use**: Reusable analysis or generation tools
   - **Examples**: Graph analysis, gap analysis, plan conversion

4. **Documentation**
   - **Definition**: Reference material for understanding
   - **Location**: `docs/_reference/{category}/`
   - **Structure**: Markdown files organized by category
   - **Categories**: patterns/, architecture/, adr/, implementation/, planning/
   - **When to use**: Reference documentation, architectural decisions, patterns
   - **Examples**: Architectural analysis, ADR reviews, implementation reports

5. **Workflow**
   - **Definition**: Multi-step process that orchestrates actions
   - **Location**: `docs/_reference/workflows/` or `.claude/commands/`
   - **Structure**: Sequential instructions or orchestration template
   - **When to use**: Complex multi-step processes
   - **Examples**: Evaluation workflow, refactoring workflow

### 2.2 Meta-Analysis Questions

For each file, ask:

1. **What does this file contain?**
   - Process knowledge? → Skill component
   - Workflow instructions? → Command template
   - Reusable analysis? → Tool
   - Reference documentation? → Documentation
   - Multi-step process? → Workflow

2. **Is this part of an existing system component?**
   - Yes → Enhance existing component
   - No → Evaluate if it should create new component or be standalone

3. **Can this be invoked/reused?**
   - Yes → Skill, Command, or Tool
   - No → Documentation

4. **What form should this take?**
   - Executable capability → Skill or Tool
   - Instruction template → Command
   - Reference material → Documentation
   - Orchestrated process → Workflow

**Key Principle**: Don't just move files - convert them into system components that enhance capabilities.

### 2.3 Skill Enhancement Analysis

**For Pattern Documentation Files**:
- **Question**: Does this enhance an existing skill?
- **Action**: Add to skill's PATTERNS.md or KNOWLEDGE.md
- **Secondary**: Keep as documentation reference in `docs/_reference/patterns/`

**For Architectural Documentation**:
- **Question**: Is this core methodology knowledge?
- **Action**: Add to skill's KNOWLEDGE.md
- **Secondary**: Keep as documentation in `docs/_reference/architecture/`

**For Usage Guides**:
- **Question**: Is this part of a skill's workflow?
- **Action**: Add to skill's REFERENCE.md
- **Secondary**: Keep as documentation in `docs/_reference/adr/` or relevant category

### 2.4 Script Component Analysis

**For Python/Node.js Scripts**:

**Analysis Framework**:
1. **Skill component?**: Does it implement a skill capability?
   - Yes → Move to `.claude/skills/{skill-name}/scripts/`
   - Example: `execute_planning.py` → `recursive-planning-spec/scripts/`

2. **Command helper?**: Does it support a command workflow?
   - Yes → Move to `.claude/commands/` or keep with command
   - Example: Helper script for a command template

3. **Standalone tool?**: Is it a reusable analysis/generation tool?
   - Yes → Move to `tools/{category}/`
   - Example: `analyze_graph_structure.py` → `tools/planning/`

4. **Workflow step?**: Is it part of a larger workflow?
   - Yes → Move to workflow directory or orchestration location

**Decision Tree**:
```
Is it core skill functionality?
├─ Yes → Skill component (scripts/)
└─ No → Is it reusable across projects?
    ├─ Yes → Tool (tools/)
    └─ No → Is it project-specific?
        ├─ Yes → Project-specific location
        └─ No → Evaluate for discard
```

---

## Phase 3: Refactoring Execution

### 3.1 Directory Structure Creation

**Action**: Create necessary directories before moving files

```bash
# Documentation structure
mkdir -p docs/_reference/{patterns,architecture,adr,implementation,planning,evaluation}

# Design system structure
mkdir -p docs/design-system/_reference

# Skill scripts directories (create as needed)
mkdir -p .claude/skills/{skill-name}/scripts

# Tools directories
mkdir -p tools/{category}
```

### 3.2 Skill Enhancements

**Action**: Add knowledge to existing skills

**Pattern Documentation**:
- Add cycle remediation patterns to `recursive-planning-spec/PATTERNS.md`
- Add architectural insights to `recursive-planning-spec/KNOWLEDGE.md`
- Add usage guides to `architecture-evaluation-framework/REFERENCE.md`

**Script Organization**:
- Move skill-specific scripts to `.claude/skills/{skill-name}/scripts/`
- Move general tools to `tools/{category}/`
- Move ADR generation to architecture skill if it's part of evaluation framework

### 3.3 Documentation Organization

**Action**: Move documentation to organized reference locations

**Categories**:
- **Patterns**: `docs/_reference/patterns/` - Pattern documentation with examples
- **Architecture**: `docs/_reference/architecture/` - Architectural analysis and insights
- **ADRs**: `docs/_reference/adr/` - Architectural decision records
- **Implementation**: `docs/_reference/implementation/` - Implementation details
- **Planning**: `docs/_reference/planning/` - Planning-specific documentation
- **Evaluation**: `docs/_reference/evaluation/` - Evaluation session archives

**Naming Convention**: Use descriptive names, strip underscores/hyphens for readability in tables

### 3.4 Cleanup Operations

**Action**: Remove discard files

**Categories to Delete**:
1. **Superseded Reports**: Intermediate reports superseded by final reports
2. **Status Artifacts**: Temporary status snapshots
3. **Redundant Reports**: Information already in final documentation
4. **JSON/Text Artifacts**: Large regenerable execution artifacts

**Archive Instead of Delete**:
- Evaluation session documents → `docs/_reference/evaluation/{name}-{date}.md`
- Temporary but valuable methodology → Archive if contains reusable evaluation methodology

---

## Phase 4: Commit Organization

### 4.1 Commit Strategy

**Principle**: Group related changes into logical commits following Conventional Commits format.

**Commit Types**:
1. **feat(scope)**: New capabilities (skill enhancements, new skills)
2. **docs(scope)**: Documentation changes (organization, additions)
3. **refactor(scope)**: Code reorganization (script moves, tool organization)
4. **chore**: Cleanup (deletions, maintenance)

### 4.2 Commit Grouping

**Group 1: Skill Enhancements**
- `feat(recursive-planning-spec): add cycle remediation patterns and knowledge base`
- `feat(architecture-evaluation-framework): add ADR usage guide to reference`

**Group 2: Documentation Organization**
- `docs: organize architectural documentation into _reference structure`
- `docs(design-system): organize design system documentation`
- `docs: add revised evaluation table with mathematical scoring formula`

**Group 3: Script Organization**
- `refactor(recursive-planning-spec): organize planning scripts as skill components`
- `refactor(architecture-evaluation-framework): move ADR generation script to skill`
- `refactor(tools): organize general planning analysis tools`

**Group 4: Cleanup**
- `chore: remove execution artifacts and superseded reports`

### 4.3 Commit Message Format

```
type(scope): summary

Detailed description of changes:

- Bullet point 1
- Bullet point 2
- Bullet point 3

Context: Why this change was made
Impact: What this enables or improves
```

---

## Phase 5: Validation

### 5.1 Post-Refactoring Checks

**Actions**:
1. Verify all files moved successfully
2. Check git status is clean
3. Verify directory structure is correct
4. Confirm skill enhancements are complete
5. Verify documentation is accessible

**Commands**:
```bash
# Check git status
git status --short

# Verify directory structure
find docs/_reference -type f | head -20
find .claude/skills -name "scripts" -type d
find tools -type d

# Verify skill enhancements
ls -la .claude/skills/recursive-planning-spec/
ls -la .claude/skills/architecture-evaluation-framework/
```

### 5.2 Documentation Verification

**Check**:
- All documentation files are in organized locations
- Skill enhancements are complete
- Scripts are in appropriate locations
- No orphaned files remain

---

## Common Patterns

### Pattern 1: Pattern Documentation

**File**: Pattern examples, remediation patterns, architectural patterns
**Component Type**: Skill Enhancement + Documentation
**Action**: Add to skill's PATTERNS.md, keep copy in docs/_reference/patterns/
**Example**: `ALTERNATIVE_PATTERN_EXAMPLES.md` → `recursive-planning-spec/PATTERNS.md` + `docs/_reference/patterns/cycle-remediation-patterns.md`

### Pattern 2: Architectural Analysis

**File**: Graph structure analysis, architectural reviews
**Component Type**: Skill Knowledge + Documentation
**Action**: Add to skill's KNOWLEDGE.md, keep copy in docs/_reference/architecture/
**Example**: `GRAPH_STRUCTURE_ANALYSIS_REPORT.md` → `recursive-planning-spec/KNOWLEDGE.md` + `docs/_reference/architecture/planning-graph-structure-analysis.md`

### Pattern 3: Usage Guides

**File**: How-to guides, usage documentation
**Component Type**: Skill Reference + Documentation
**Action**: Add to skill's REFERENCE.md, keep copy in docs/_reference/adr/ or relevant category
**Example**: `HOW_TO_USE_UI_ADRS.md` → `architecture-evaluation-framework/REFERENCE.md` + `docs/_reference/adr/ui-adrs-usage-guide.md`

### Pattern 4: Core Skill Scripts

**File**: Scripts that implement core skill functionality
**Component Type**: Skill Component
**Action**: Move to `.claude/skills/{skill-name}/scripts/`
**Example**: `execute_planning.py` → `recursive-planning-spec/scripts/`

### Pattern 5: General Tools

**File**: Reusable analysis/generation tools
**Component Type**: Tool
**Action**: Move to `tools/{category}/`
**Example**: `analyze_graph_structure.py` → `tools/planning/`

---

## Reproducibility Checklist

When this state occurs again:

- [ ] **Phase 1**: Discover all files with pending changes
- [ ] **Phase 1**: Calculate scores using mathematical formula
- [ ] **Phase 1**: Generate evaluation table with all columns
- [ ] **Phase 2**: Perform component meta-analysis for each file
- [ ] **Phase 2**: Determine component type (Skill, Command, Tool, Documentation, Workflow)
- [ ] **Phase 2**: Identify skill enhancements needed
- [ ] **Phase 3**: Create directory structure
- [ ] **Phase 3**: Enhance existing skills
- [ ] **Phase 3**: Move documentation to organized locations
- [ ] **Phase 3**: Organize scripts (skill components vs tools)
- [ ] **Phase 3**: Delete discard files
- [ ] **Phase 3**: Archive temporary evaluation files
- [ ] **Phase 4**: Create logical commit groups
- [ ] **Phase 4**: Write detailed commit messages
- [ ] **Phase 5**: Validate refactoring is complete
- [ ] **Phase 5**: Verify git status is clean

---

**Usage**: Invoke this command when miscellaneous files accumulate after work sessions. Follow each phase sequentially, performing component meta-analysis to convert files into system components rather than just moving them.

