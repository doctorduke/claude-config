# ADR-004: Hephaestus Pattern Extraction and Lightweight Implementation

## Status
Accepted

## Context
We need advanced agent orchestration capabilities similar to the Hephaestus project but without its heavy dependencies (tmux, FastAPI, Qdrant) and AGPL-3.0 licensing constraints. Our goal is to extract valuable architectural patterns and implement them in a lightweight TypeScript manner compatible with Cursor CLI.

## Decision

### Pattern Extraction Approach
We analyzed the Hephaestus codebase to extract five core patterns:

1. **Dynamic Workflow Pattern**: Agents discover and create tasks dynamically
2. **Semantic Ticket System**: Vector-based duplicate detection
3. **Guardian Monitoring**: Trajectory-aware agent supervision
4. **Phase-Based Coordination**: Structured yet flexible workflow phases
5. **Git Worktree Management**: Isolated parallel execution environments

### Implementation Strategy
We will implement lightweight TypeScript versions that:
- Use TodoWrite tool instead of SQLite for task management
- Use OpenAI API directly instead of custom LLM providers
- Use in-memory vectors instead of Qdrant
- Use child processes instead of tmux sessions
- Use native git commands for worktree management

### Integration Points
- **workflow-builder-framework**: Extend with dynamic task discovery
- **TodoWrite tool**: Primary task management interface
- **OpenAI API**: Embeddings and enrichment
- **Git**: State persistence and isolation

## Consequences

### Positive
- **No licensing concerns**: Patterns/concepts not copyrightable, different implementation
- **Lighter dependencies**: No Docker, tmux, or vector DB required
- **Better integration**: Works with existing Cursor CLI tools
- **Incremental adoption**: Each pattern can be implemented independently
- **Simpler deployment**: TypeScript functions vs distributed services

### Negative
- **Reduced robustness**: Simplified versions may lack production hardening
- **Limited scale**: In-memory storage constrains vector search scale
- **Less isolation**: Process isolation weaker than tmux sessions
- **Manual orchestration**: No automatic agent spawning like Hephaestus

### Neutral
- **Different technology stack**: TypeScript vs Python changes development patterns
- **Modified monitoring**: Console-based vs tmux-based agent observation
- **Simplified persistence**: JSON files and git vs SQLite

## Implementation Priorities

### Phase 1 (Core - Week 1)
- Dynamic Workflow Pattern
- Phase-Based Coordination
- Integration with workflow-builder-framework

### Phase 2 (Quality - Week 2)
- Semantic Ticket System
- Guardian Monitoring
- Basic duplicate detection

### Phase 3 (Scale - Week 3)
- Git Worktree Management
- Parallel execution support
- Advanced conflict resolution

## Risk Mitigation

### Licensing Risk (LOW)
- No code copying, only conceptual patterns
- Complete reimplementation in different language
- Different architectural components

### Technical Risk (MEDIUM)
- Start with single-agent workflows
- Extensive testing of edge cases
- Gradual complexity increase
- Fallback to sequential execution if parallel fails

### Integration Risk (LOW)
- Compatible with existing tools
- Uses standard interfaces (TodoWrite, Git)
- Can run alongside current workflows

## Validation Metrics
- Task discovery accuracy
- Duplicate detection precision/recall
- Agent trajectory coherence
- Parallel execution success rate
- Workflow completion time

## References
- Hephaestus Repository: https://github.com/Ido-Levi/Hephaestus
- Pattern Documentation: .claude/docs/hephaestus-patterns.md
- workflow-builder-framework: .claude/skills/workflow-builder-framework/
- TodoWrite Tool Documentation: [Internal]

## Review Notes
Patterns extracted through systematic analysis of Hephaestus source code, focusing on architectural concepts rather than implementation details. Lightweight alternatives designed to maintain pattern benefits while fitting our technology constraints.