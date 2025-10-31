# Work Backcasting Framework

**Version**: 1.0.0
**Category**: Planning & Strategy
**Allowed Tools**: Read, Write, Edit, Bash, Grep, Glob

## Description

Reverse-engineer implementation plans from desired end states. Define where you want to be, then work backward to identify the exact sequence of steps, prerequisites, and dependencies needed to get there.

---

## Purpose

### Why Backward Planning Matters

**Forward Planning Problem**: Starting from "now" often leads to incremental thinking and missed opportunities.

**Backward Planning Solution**: Starting from the desired future state forces clarity about:
- What success actually looks like (concrete, measurable)
- Critical prerequisites that must be in place
- Dependencies and ordering constraints
- Feasibility bottlenecks early in planning

**When to Use Backcasting**:
- **Large Migrations**: Moving from legacy system to modern architecture
- **Strategic Refactoring**: Evolving toward a target architecture pattern
- **Greenfield Projects**: Ensuring all prerequisites are identified before launch
- **Technology Upgrades**: Planning framework or language version transitions
- **Compliance Goals**: Working backward from regulatory requirements

---

## Quick Start

### 4-Step Backcasting Process

```
1. DEFINE END STATE
   └─> Clear, measurable, achievable target state
       Include: System behavior, architecture, metrics, constraints

2. BACKWARD CHAIN
   └─> Work backward from end state to current state
       Ask: "What must be true immediately before this?"
       Build: Reverse dependency graph of states

3. VALIDATE FEASIBILITY
   └─> Check constraints at each step
       Verify: Resources, time, technical feasibility
       Identify: Blockers, risks, impossibilities

4. REFINE & FORWARD PLAN
   └─> Reverse the backward chain into execution plan
       Add: Contingencies, parallelization, checkpoints
       Produce: Step-by-step implementation roadmap
```

---

## Core Patterns Overview

### 1. End State Definition
Define concrete, measurable target states with clear success criteria. Avoid vague goals like "better performance" - specify "API response time p95 < 200ms with 10k RPS load".

**When**: Always the first step in backcasting.

### 2. Backward Chaining
Build reverse dependency graph by repeatedly asking "what state must exist immediately before this state?" Creates complete prerequisite chain from target to present.

**When**: After end state is clearly defined.

### 3. Prerequisite Identification
Systematically identify dependencies, blockers, and enabling conditions for each state transition. Includes technical, resource, knowledge, and organizational prerequisites.

**When**: For each step in the backward chain.

### 4. Feasibility Validation
Validate that each identified step is actually achievable within constraints (time, resources, technology, team capabilities). Detect impossible requirements early.

**When**: After full backward chain is built, before committing to plan.

### 5. Gap Analysis
Compare current state to target state across all dimensions (architecture, capabilities, skills, infrastructure). Quantify gaps and identify closure strategies.

**When**: To validate starting point and size the effort.

---

## Pattern Details

For detailed pattern documentation, see:
- **[PATTERNS.md](PATTERNS.md)**: Full pattern catalog with algorithms
- **[EXAMPLES.md](EXAMPLES.md)**: Working code examples
- **[KNOWLEDGE.md](KNOWLEDGE.md)**: Theory and methodology

---

## Common Use Cases

### Database Migration
```
End State: All data in PostgreSQL, zero downtime
└─> State N-1: Dual-write to both databases, read from new
    └─> State N-2: Dual-write working, data synchronized
        └─> State N-3: Replication pipeline operational
            └─> State N-4: PostgreSQL schema finalized
                └─> Current: MySQL only
```

### Framework Upgrade
```
End State: Next.js 15, all features working, tests passing
└─> State N-1: All deprecations resolved
    └─> State N-2: Breaking changes addressed
        └─> State N-3: Dependencies upgraded
            └─> State N-4: Migration guide reviewed
                └─> Current: Next.js 12
```

### Architecture Evolution
```
End State: Event-driven microservices, async communication
└─> State N-1: Message bus operational, all services connected
    └─> State N-2: Services decomposed, boundaries clear
        └─> State N-3: Bounded contexts identified
            └─> State N-4: Domain model refactored
                └─> Current: Monolithic architecture
```

---

## Top 3 Gotchas

### 1. Vague End States
**Problem**: "Make the system faster" → undefined success criteria
**Solution**: "Reduce p95 API latency from 800ms to <200ms under 5k RPS load"
**See**: [GOTCHAS.md#vague-end-states](GOTCHAS.md#vague-end-states)

### 2. Missing Hidden Prerequisites
**Problem**: Planning UI changes but missing required API endpoints
**Solution**: Systematically ask "what must exist?" for each step
**See**: [GOTCHAS.md#missing-prerequisites](GOTCHAS.md#missing-prerequisites)

### 3. Infeasible Intermediate States
**Problem**: "Step 4" requires the system to be both stateless AND stateful
**Solution**: Validate each state for internal consistency
**See**: [GOTCHAS.md#infeasible-states](GOTCHAS.md#infeasible-states)

---

## Quick Reference Card

### End State Checklist
- [ ] Concrete and specific (no vague terms)
- [ ] Measurable (quantified success criteria)
- [ ] Achievable (within constraints)
- [ ] Complete (all system dimensions covered)
- [ ] Testable (can verify when reached)

### Backward Chaining Steps
1. Start at end state
2. Ask: "What must be true immediately before?"
3. Document that prerequisite state
4. Repeat until reaching current state
5. Validate chain completeness

### Feasibility Check
- [ ] Technical: Can we build this?
- [ ] Resource: Do we have time/budget?
- [ ] Knowledge: Does team have skills?
- [ ] Dependency: Are external deps available?
- [ ] Risk: Are blockers manageable?

### Gap Analysis Dimensions
- Architecture (current vs target structure)
- Capabilities (existing vs required features)
- Data (schema, volume, quality)
- Infrastructure (hosting, scaling, monitoring)
- Skills (team knowledge gaps)
- Process (development, deployment, operations)

---

## Integration Points

### With Other Skills
- **Work Forecasting**: Validate timelines for backward chain steps
- **Context Engineering**: Build context for each state transition
- **Refactoring Lead**: Apply to refactoring strategy planning
- **Project Planner**: Convert backward chain to forward execution plan

### With Agent Roles
- **project-planner**: Uses backcasting for strategic roadmaps
- **refactoring-lead**: Plans architecture evolution paths
- **migration-specialist**: Designs system migration strategies

---

## Example Workflow

```bash
# 1. Define end state
python -m work_backcasting.define_end_state \
  --goal "Migrate to microservices architecture" \
  --criteria "criteria.yaml" \
  --output end_state.json

# 2. Build backward chain
python -m work_backcasting.backward_chain \
  --end-state end_state.json \
  --current-state current.json \
  --output chain.json

# 3. Validate feasibility
python -m work_backcasting.validate_feasibility \
  --chain chain.json \
  --constraints constraints.yaml \
  --output validation_report.json

# 4. Analyze gaps
python -m work_backcasting.gap_analysis \
  --current current.json \
  --target end_state.json \
  --output gaps.json

# 5. Generate execution plan
python -m work_backcasting.to_execution_plan \
  --chain chain.json \
  --gaps gaps.json \
  --output roadmap.md
```

---

## Pattern Selection Guide

| Scenario | Primary Pattern | Secondary Pattern |
|----------|----------------|-------------------|
| Starting a migration | End State Definition | Gap Analysis |
| Midway through refactor | Backward Chaining | Feasibility Validation |
| Planning stuck | Prerequisite Identification | Gap Analysis |
| Timeline concerns | Feasibility Validation | Backward Chaining |
| Unclear requirements | End State Definition | Gap Analysis |

---

## Validation Strategies

### End State Validation
- Run through "Five Whys" to ensure clarity
- Create mock acceptance tests
- Build prototype UI/API contract
- Get stakeholder sign-off

### Chain Validation
- Each step is independently achievable
- No circular dependencies
- All prerequisites explicitly listed
- States are mutually exclusive

### Feasibility Validation
- Resource estimation per step
- Risk assessment per transition
- Technical spike for unknowns
- Team capacity planning

---

## Getting Started Checklist

- [ ] Read [KNOWLEDGE.md](KNOWLEDGE.md) for methodology background
- [ ] Review [PATTERNS.md](PATTERNS.md) for pattern details
- [ ] Study [EXAMPLES.md](EXAMPLES.md) for working code
- [ ] Check [GOTCHAS.md](GOTCHAS.md) for common pitfalls
- [ ] Reference [REFERENCE.md](REFERENCE.md) for APIs

---

## Advanced Topics

### Multi-Path Backcasting
When multiple paths from current to target exist, evaluate:
- Risk profile of each path
- Resource requirements
- Timeline differences
- Reversibility (can we back out?)

### Parallel State Transitions
Identify independent chains that can execute concurrently:
- Database migration + UI modernization
- API versioning + client library updates

### Contingency Planning
For each critical step, plan:
- Rollback procedure
- Alternative path
- Risk mitigation

---

## Real-World Success Metrics

Track these to measure backcasting effectiveness:
- **Plan Accuracy**: % of steps that execute as planned
- **Surprise Rate**: # of unexpected prerequisites discovered
- **Feasibility Hits**: % of infeasible plans caught early
- **Time to Plan**: Hours spent on backcasting phase
- **Execution Efficiency**: Actual vs estimated timeline

---

## Further Reading

- [KNOWLEDGE.md](KNOWLEDGE.md) - Theory, research, methodology
- [PATTERNS.md](PATTERNS.md) - Detailed pattern implementations
- [EXAMPLES.md](EXAMPLES.md) - Working code examples
- [GOTCHAS.md](GOTCHAS.md) - Troubleshooting and debugging
- [REFERENCE.md](REFERENCE.md) - API documentation and templates

---

## Summary

Backcasting is reverse planning: define the target state clearly, work backward to identify all prerequisites, validate feasibility, then reverse into an execution plan. This approach catches missing dependencies early and ensures strategic alignment.

**Key Advantage**: Forces clarity about the destination before committing to the journey.

**When Not to Use**: Exploratory projects where the destination is deliberately unclear (use forecasting instead).
