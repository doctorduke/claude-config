# ADR-003: Brief Modularization Strategy

**Date**: 2025-10-02
**Status**: Accepted
**Deciders**: Documentation Team, AI Architecture Review

## Context

The umemee-v0 project has grown to include complex frameworks (agent coordination, validation systems, task management) that need to be properly documented and modularized. The existing brief system needs to be updated to handle these new capabilities and prepare for design documentation ingestion.

## Decision

We will implement a **modular brief system** with the following structure:

### Brief Hierarchy

1. **Root BRIEF**: Project overview and navigation
2. **Module BRIEFs**: Each major component gets its own BRIEF
3. **Reference Structure**: Detailed specs in `_reference/` directories
4. **ADR System**: Architecture decisions in `_reference/adr/`

### Brief Template Standards

- **Interface Contract**: Clear inputs/outputs/guarantees
- **Spec Snapshot**: Current state with date stamps
- **Work State**: Planned/Doing/Done with specific items
- **Local Reference Index**: Links to detailed documentation
- **Answer Pack**: YAML format for AI consumption

### Modularization Rules

- **<200 lines**: Keep BRIEFs under 200 lines
- **Single Responsibility**: Each BRIEF covers one module
- **Reference Depth**: Move details to `_reference/` subdirectories
- **Consistent Structure**: Follow template across all modules

## Rationale

### Why Modular Briefs?

1. **Maintainability**: Easier to update individual modules
2. **Clarity**: Each BRIEF focuses on one concern
3. **AI Consumption**: Agents can focus on relevant modules
4. **Scalability**: System grows without becoming unwieldy

### Why Reference Structure?

1. **Separation of Concerns**: BRIEFs for overview, references for details
2. **Flexibility**: References can be updated without changing BRIEFs
3. **Depth**: Complex topics get proper space for explanation
4. **Navigation**: Clear hierarchy for finding information

### Why ADR System?

1. **Decision Tracking**: Record why architectural choices were made
2. **Context Preservation**: Future developers understand reasoning
3. **Change Management**: Track evolution of architectural decisions
4. **Learning**: Patterns for future similar decisions

## Consequences

### Positive

- **Better Organization**: Clear structure for complex information
- **AI Friendly**: Modular structure works well with AI agents
- **Maintainable**: Easy to update individual components
- **Scalable**: System can grow without becoming unwieldy

### Negative

- **Initial Overhead**: Significant work to modularize existing docs
- **Coordination**: Need to keep BRIEFs and references in sync
- **Learning Curve**: Team needs to understand new structure
- **Tooling**: May need tools to validate brief consistency

### Mitigations

- **Gradual Migration**: Migrate modules one at a time
- **Validation Tools**: Scripts to check brief consistency
- **Documentation**: Clear guidelines for brief maintenance
- **Training**: Team training on new structure

## Implementation Plan

### Phase 1: Fix Existing BRIEFs ✅

- [x] Update `shared/utils/BRIEF.md` for task management
- [x] Create `docs/agent-coordination/BRIEF.md`
- [x] Create `tools/validation-framework/BRIEF.md`

### Phase 2: Modularize Large Documents ✅

- [x] Break down agent coordination spec into focused references
- [x] Create routing logic, state machines, communication protocols
- [x] Create implementation guides for agent selection and handoff

### Phase 3: Establish ADR System ✅

- [x] Create ADR directory structure
- [x] Create initial ADRs for key decisions
- [x] Establish ADR template and process

### Phase 4: Design Documentation Ingestion ✅

- [x] Test brief system with sample design docs (completed 2025-10-02)
- [x] Refine modularization based on results (completed 2025-10-02)
- [ ] Create ingestion guidelines for design team

## Brief Template

```markdown
# Module Name — BRIEF

## Purpose & Boundary
[One paragraph describing what this module does and its scope]

## Interface Contract
**Inputs**: [What goes in]
**Outputs**: [What comes out]
**Key Guarantees**: [What this module promises]

## Work State
**Planned**: [Future work items]
**Doing**: [Current work items]
**Done**: [Completed work items]

## Spec Snapshot (YYYY-MM-DD)
[Current state, constraints, release gates]

## Decisions & Rationale
[Key architectural decisions with dates]

## Local Reference Index
[Links to detailed documentation in _reference/]

## Answer Pack
[YAML format for AI consumption]
```

## Related Decisions

- ADR-001: Agent Routing Decision
- ADR-002: Validation Gate Design
- ADR-004: Design Documentation Ingestion Strategy

## References

- [Brief Kit Templates](../brief-kit/templates/BRIEF.md.tmpl)
- [Agent Coordination BRIEF](../docs/agent-coordination/BRIEF.md)
- [Validation Framework BRIEF](../tools/validation-framework/BRIEF.md)
