# Integration Guide: Reverse Engineering Toolkit

## Overview

This document describes how the Reverse Engineering Toolkit skill integrates with agents, particularly the `code-archaeologist` agent.

## Primary Agent: code-archaeologist

### Current State
The `code-archaeologist` agent currently embeds reverse engineering knowledge directly in its definition (as noted in issue-60-skills-architecture.md, line 603).

### Integration Pattern

**Agent delegates to skill for**:
1. Code structure analysis techniques
2. Dependency mapping methodologies
3. Pattern recognition algorithms
4. Documentation generation approaches
5. Tool selection and usage

**Agent retains responsibility for**:
1. User interaction and requirements gathering
2. High-level analysis strategy
3. Results presentation and visualization
4. Workflow orchestration
5. Context management across analysis sessions

### Example Usage in Agent

```markdown
# In .claude/agents/code-archaeologist/AGENT.md

## Skills Used
- reverse-engineering-toolkit: Core analysis techniques

## Workflow

When analyzing undocumented codebase:

1. User Request → Agent gathers requirements
2. Agent invokes reverse-engineering-toolkit skill
3. Skill provides analysis approach (static/dynamic/hybrid)
4. Agent executes analysis using provided patterns
5. Agent presents results to user with visualizations
6. Agent manages follow-up questions and deeper analysis
```

### Refactoring Recommendation

**Before** (current overloaded agent):
```markdown
# code-archaeologist agent has embedded knowledge:
- How to parse AST
- How to build dependency graphs
- How to detect patterns
- Tool command references
- etc. (100+ lines of embedded knowledge)
```

**After** (using skill):
```markdown
# code-archaeologist agent delegates to skill:

## Mission
Understand undocumented codebases using reverse engineering techniques.

## Skills
- reverse-engineering-toolkit

## Approach
1. Assess codebase (size, language, availability)
2. Consult reverse-engineering-toolkit for analysis strategy
3. Execute analysis following skill patterns
4. Present findings with visualizations
5. Answer user questions about discovered structure
```

## Other Compatible Agents

### security-auditor
**Use Case**: Security-focused code analysis
**Integration**: Uses Pattern 2 (Dynamic Analysis) for runtime behavior inspection
**Specific Focus**: Taint analysis, vulnerability detection, privilege escalation paths

### integration-engineer
**Use Case**: Understanding third-party APIs
**Integration**: Uses Pattern 2 (Dynamic Analysis) for API behavior observation
**Specific Focus**: Protocol reverse engineering, request/response mapping

### api-consumer-advocate
**Use Case**: Documenting undocumented APIs
**Integration**: Uses Pattern 5 (Documentation Generation) after analysis
**Specific Focus**: Generating OpenAPI specs from observed behavior

### refactoring-lead
**Use Case**: Understanding code before refactoring
**Integration**: Uses Pattern 1 (Static Analysis) and Pattern 3 (Dependency Graph)
**Specific Focus**: Identifying refactoring boundaries, impact analysis

## Tool Requirements

This skill requires agents to have access to:

**Required Tools**:
- `Read`: Analyze source files
- `Grep`: Search for patterns
- `Glob`: Find files
- `Bash`: Execute analysis tools

**Optional Tools** (enhance capabilities):
- `Write`: Save analysis results
- `Edit`: Annotate code with findings
- `WebFetch`: Research similar systems

## Skill Invocation Pattern

### Direct Invocation
```bash
# Agent loads skill
/skill reverse-engineering-toolkit

# Agent consults specific section
See: reverse-engineering-toolkit/PATTERNS.md → Static Code Analysis
```

### Contextual Reference
```markdown
Agent: "I need to understand this codebase's dependency structure."
Skill: "Use Pattern 3: Dependency Graph Extraction"
Agent: *follows pattern, executes analysis*
Agent: *presents dependency graph to user*
```

## Data Flow

```
User Request
    ↓
code-archaeologist agent
    ↓
Skill Consultation (which pattern to use?)
    ↓
reverse-engineering-toolkit skill
    ↓
Pattern Selection & Tool Recommendations
    ↓
Agent Executes Analysis
    ↓
Skill Validates Results
    ↓
Agent Presents to User
```

## Success Metrics

Integration is successful when:

1. **Agent Stays Lean**: code-archaeologist definition < 150 lines
2. **Skill Reuse**: Multiple agents use this skill
3. **Consistent Approach**: All agents use same RE patterns
4. **Maintainability**: Update skill once, all agents benefit
5. **Specialization**: Agents focus on user interaction, skill provides expertise

## Migration Path

### Phase 1: Add Skill (Current)
- Implement reverse-engineering-toolkit skill
- Test in isolation
- Validate all patterns work

### Phase 2: Refactor Agent
- Update code-archaeologist to reference skill
- Remove embedded knowledge
- Test agent still works correctly

### Phase 3: Expand Usage
- Update security-auditor to use skill
- Update integration-engineer to use skill
- Monitor for shared issues

### Phase 4: Optimize
- Identify commonly-used patterns
- Add convenience shortcuts
- Improve cross-references

## Integration Testing

### Test Scenarios

**Scenario 1: Analyze Python Codebase**
```
Input: Path to Python project
Agent: code-archaeologist
Skill: reverse-engineering-toolkit
Expected: Dependency graph, pattern catalog, API docs
```

**Scenario 2: Audit Third-Party Library**
```
Input: NPM package name
Agent: security-auditor
Skill: reverse-engineering-toolkit (Pattern 2)
Expected: Runtime behavior analysis, security findings
```

**Scenario 3: Document Legacy API**
```
Input: Service endpoint
Agent: api-consumer-advocate
Skill: reverse-engineering-toolkit (Pattern 2 + 5)
Expected: OpenAPI specification
```

## Known Limitations

1. **Binary-Only Analysis**: Patterns focus on source code; binary RE requires different tools
2. **Language Coverage**: Examples are Python-heavy; other languages need adaptation
3. **Tool Availability**: Some tools (strace, gdb) platform-specific
4. **Performance**: Large codebases may need sampling strategies

## Future Enhancements

1. **Pattern Library Expansion**: Add more language-specific patterns
2. **Tool Abstraction**: Cross-platform tool wrappers
3. **Result Caching**: Speed up repeated analyses
4. **Agent Coordination**: Multi-agent analysis (one per module)

## Support

For integration issues:
1. Check skill tests are passing
2. Verify agent has required tools
3. Review GOTCHAS.md for known issues
4. Consult EXAMPLES.md for working code

## Version History

- v1.0.0 (2025-10-27): Initial skill implementation
- Integration with code-archaeologist: Planned
- Multi-agent integration: Planned
