# Agent Builder Framework

**Type**: Meta-skill for creating specialized AI agents
**Purpose**: Design, implement, test, and deploy custom AI agents with proper specifications
**Dependencies**: AI Agent Tool Builder, Context Engineering
**Version**: 1.0.0

## Allowed Tools

```yaml
allowed_tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - WebSearch
  - WebFetch
  - TodoWrite
```

## Purpose

Building specialized AI agents requires systematic approaches to:
- **Specialization**: Define clear agent roles and responsibilities
- **Maintainability**: Create testable, debuggable agents with well-defined interfaces
- **Coordination**: Enable multi-agent workflows with proper handoff mechanisms
- **Quality**: Validate agent behavior through comprehensive testing

This skill provides frameworks for creating production-ready agents that are specialized, composable, and maintainable.

## Quick Start

### 4-Step Agent Creation Process

**Step 1: Specify** - Define agent role, capabilities, and constraints
```yaml
name: security-auditor
role: Automated security analysis and reporting
capabilities: [sast, dast, dependency-scan, secret-detection]
constraints: {max_scan_time: 300s, report_formats: [json, html]}
```

**Step 2: Implement** - Map capabilities to tools and create agent logic
```python
tools = map_capabilities_to_tools(capabilities)
agent = create_agent(specification, tools)
```

**Step 3: Test** - Validate behavior with unit, integration, and acceptance tests
```python
test_agent_behavior(agent, test_suite)
validate_outputs(agent, expected_results)
```

**Step 4: Deploy** - Register agent and integrate with orchestration system
```python
register_agent(agent, agent_registry)
configure_coordination(agent, handoff_protocols)
```

## Core Patterns Overview

### 1. Agent Specification Design
Define complete agent specifications with role, capabilities, constraints, inputs/outputs, and success criteria. Ensures clarity and prevents scope creep.

### 2. Capability Definition & Tool Selection
Map high-level agent capabilities to specific tools and resources. Creates traceable requirements-to-implementation mapping.

### 3. Behavior Testing & Validation
Test agent behavior through unit tests (individual functions), integration tests (tool interactions), and acceptance tests (end-to-end scenarios).

### 4. Multi-Agent Coordination
Implement protocols for agent-to-agent communication including handoffs, collaboration, and conflict resolution.

### 5. Agent Lifecycle Management
Manage agent states: initialization, execution, monitoring, error handling, and termination. Track performance metrics.

## When to Use This Skill

**Use for:**
- Creating new specialized agents (documentation-writer, security-auditor, test-generator)
- Refactoring existing agents to improve clarity and testability
- Designing multi-agent systems with coordination requirements
- Building agent libraries for reusable components
- Implementing agent testing frameworks

**Don't use for:**
- Simple single-function utilities (use regular tool creation instead)
- One-off tasks that don't require agent abstraction
- Generic AI assistants (agents should be specialized)

## Detailed Documentation

- **[KNOWLEDGE.md](./KNOWLEDGE.md)** - Agent architecture theory, BDI model, multi-agent systems
- **[PATTERNS.md](./PATTERNS.md)** - 5 implementation patterns with code examples
- **[EXAMPLES.md](./EXAMPLES.md)** - Complete agent creation workflows
- **[GOTCHAS.md](./GOTCHAS.md)** - Common pitfalls and troubleshooting
- **[REFERENCE.md](./REFERENCE.md)** - API documentation and schemas

## Top 3 Gotchas

### 1. Scope Creep
**Problem**: Agent responsibilities grow unchecked, becoming difficult to maintain
**Solution**: Enforce single responsibility principle. If agent needs >5 capabilities, split into multiple agents

### 2. Under-Specification
**Problem**: Vague role definitions lead to unpredictable behavior
**Solution**: Complete specification template with explicit inputs, outputs, constraints, and success criteria

### 3. Coordination Failures
**Problem**: Multi-agent systems fail due to race conditions, missed handoffs, or conflicting actions
**Solution**: Use formal coordination protocols (see PATTERNS.md #4) with explicit state management

## Quick Reference Card

### Agent Specification Template
```yaml
name: string                    # Unique identifier
role: string                    # One-sentence purpose
capabilities: [string]          # High-level abilities
tools: [string]                 # Specific tools/APIs
inputs:                         # What agent receives
  - name: string
    type: string
    required: boolean
outputs:                        # What agent produces
  - name: string
    type: string
    format: string
constraints:                    # Limitations
  max_execution_time: duration
  max_cost: float
  allowed_operations: [string]
success_criteria:               # How to measure success
  - metric: string
    threshold: value
```

### Capability-Tool Mapping Process
1. List high-level capabilities from requirements
2. Identify required tool categories (file ops, analysis, generation)
3. Select specific tools from AI Agent Tool Builder
4. Validate tool coverage (all capabilities mappable)
5. Document tool usage patterns

### Testing Checklist
- [ ] Unit tests: Individual functions work correctly
- [ ] Integration tests: Tools interact properly
- [ ] Acceptance tests: End-to-end scenarios pass
- [ ] Error handling: Graceful failure modes
- [ ] Performance: Meets latency/cost constraints
- [ ] Edge cases: Handles invalid inputs

### Coordination Protocol Template
```python
protocol = {
    "trigger": "condition that initiates handoff",
    "sender": "agent initiating handoff",
    "receiver": "agent receiving handoff",
    "payload": "data transferred",
    "acknowledgment": "confirmation mechanism",
    "timeout": "max wait time",
    "fallback": "action if handoff fails"
}
```

## Workflow Examples

### Create New Specialized Agent
1. Define role and capabilities (PATTERNS.md #1)
2. Map capabilities to tools (PATTERNS.md #2)
3. Implement agent logic with tools
4. Create test suite (PATTERNS.md #3)
5. Validate behavior
6. Deploy and register

### Refactor Existing Agent
1. Extract current specification
2. Identify scope creep or missing constraints
3. Redesign with clearer boundaries
4. Add missing tests
5. Validate equivalent behavior
6. Deploy improved version

### Multi-Agent System Design
1. Decompose problem into agent responsibilities
2. Design coordination protocols (PATTERNS.md #4)
3. Implement individual agents
4. Test agent interactions
5. Deploy with orchestration (use Orchestration Coordination Framework)

## Agent Specialization Guidelines

**Good Specialization:**
- Single clear purpose
- 2-5 well-defined capabilities
- Predictable inputs and outputs
- Testable behavior
- Clear success criteria

**Poor Specialization:**
- Multiple unrelated purposes
- >10 capabilities (too broad)
- Vague or unbounded inputs
- Untestable behavior
- No measurable success

## Integration with AI Engineer Agent

The ai-engineer agent uses this skill to:
1. **Create new agents** for specific tasks (e.g., "create a documentation generator agent")
2. **Refactor agents** to improve maintainability
3. **Design multi-agent workflows** for complex problems
4. **Generate agent test suites** for quality assurance

The ai-engineer invokes this skill via:
```
Use the agent-builder-framework to create a new agent for [purpose]
with capabilities [list] and constraints [list]
```

## Performance Considerations

- **Agent complexity**: More capabilities = longer initialization, higher maintenance
- **Tool count**: Each tool adds latency and potential failure points
- **Coordination overhead**: Multi-agent systems have communication costs
- **Testing coverage**: More tests = higher confidence but longer CI/CD

**Optimization strategies:**
- Keep agents focused (3-5 capabilities max)
- Lazy-load tools (only initialize when needed)
- Use async communication for multi-agent systems
- Implement tiered testing (fast unit tests, slower acceptance tests)

## Common Use Cases

1. **Documentation Agent**: Reads code, generates docs, validates examples
2. **Security Auditor**: SAST, DAST, dependency scanning, report generation
3. **Test Generator**: Analyzes code, generates test cases, validates coverage
4. **Deployment Agent**: Validates builds, runs tests, deploys to environments
5. **Code Reviewer**: Analyzes PRs, checks standards, suggests improvements
6. **Data Pipeline Agent**: Extracts, transforms, loads, validates data
7. **Monitoring Agent**: Collects metrics, detects anomalies, sends alerts

## Next Steps

1. **Read PATTERNS.md** - Learn the 5 core implementation patterns
2. **Review EXAMPLES.md** - See complete agent creation workflows
3. **Check GOTCHAS.md** - Avoid common pitfalls
4. **Reference KNOWLEDGE.md** - Deep dive into agent theory
5. **Use REFERENCE.md** - API documentation for implementation

## Resources

- Multi-Agent Coordination Framework skill (for deployment)
- AI Agent Tool Builder skill (for tool selection)
- Context Engineering skill (for agent context management)
- LangGraph documentation (agent framework)
- AutoGen patterns (multi-agent systems)
- CrewAI examples (agent orchestration)
