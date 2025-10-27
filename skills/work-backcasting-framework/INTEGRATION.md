# Work Backcasting Framework - Integration Guide

## Purpose

This document describes how the Work Backcasting Framework integrates with other skills and agent roles in the system.

---

## Integration with Other Skills

### 1. Work Forecasting Framework

**Relationship**: Complementary planning approaches

**Integration Points**:
- **Validation**: Use forecasting to validate timeline estimates from backward chains
- **Iteration**: Start with backcasting to identify path, then forecast to refine estimates
- **Comparison**: Compare backward-planned path with forward-projected path to identify discrepancies

**Workflow**:
```
1. Backcast: Define end state → build backward chain → identify prerequisites
2. Forecast: From current state → project forward using team velocity
3. Compare: Validate that backcast timeline matches forecast timeline
4. Iterate: Adjust either end state or execution plan based on comparison
```

**Example**:
```python
# Backcast to find ideal path
backcast_plan = backward_chain(current, target)
backcast_timeline = sum(step.duration for step in backcast_plan)

# Forecast to predict realistic timeline
forecast_timeline = forecast_from_current(current, team_velocity)

# Validate
if backcast_timeline > forecast_timeline * 1.5:
    print("⚠️  Backcast is too optimistic, adjust plan")
```

---

### 2. Context Engineering Framework

**Relationship**: Backcasting defines work context for engineering

**Integration Points**:
- **State Context**: Each state in backward chain needs context engineering
- **Transition Context**: Context for each state transition
- **Prerequisite Context**: Context for satisfying prerequisites

**Workflow**:
```
1. Backcast: Build backward chain with states and transitions
2. Engineer Context: For each state, define:
   - Technical context (architecture, APIs, data)
   - Organizational context (teams, approvals, communication)
   - Knowledge context (skills, training, documentation)
3. Execute: Use engineered context during implementation
```

**Example**:
```yaml
State: "Services Independent"
Context:
  technical:
    - API contracts defined for all services
    - Service discovery mechanism operational
    - Inter-service authentication configured
  organizational:
    - Service ownership assigned to teams
    - On-call rotation established
    - Communication channels set up
  knowledge:
    - Team trained on microservices patterns
    - Runbooks created for each service
    - Architecture decision records documented
```

---

### 3. Gap Analysis Framework

**Relationship**: Backcasting identifies gaps to be analyzed

**Integration Points**:
- **Gap Identification**: Backward chain reveals capability gaps
- **Gap Prioritization**: Use gap analysis to prioritize prerequisite work
- **Gap Closure**: Plan how to close each gap in the chain

**Workflow**:
```
1. Backcast: Identify target state and current state
2. Gap Analysis: Systematically analyze differences across dimensions
3. Prioritize: Focus on critical gaps that block progress
4. Plan: Incorporate gap closure into backward chain
```

---

## Integration with Agent Roles

### 1. project-planner Agent

**Role**: Strategic planning and roadmap creation

**How Backcasting Helps**:
- Provides structured methodology for long-term planning
- Identifies all prerequisites and dependencies upfront
- Validates feasibility before committing resources
- Creates clear milestone sequence

**Usage Pattern**:
```
project-planner receives: "Plan migration to microservices"

1. project-planner invokes: work-backcasting-framework
   - Define end state: Microservices architecture
   - Build backward chain: Monolith → Modular → Services
   - Identify prerequisites: Infrastructure, training, etc.

2. project-planner creates:
   - Quarterly roadmap with milestones from backward chain
   - Resource allocation based on prerequisites
   - Risk register from feasibility analysis
   - Stakeholder communication plan
```

**Output**:
- Detailed project plan with phases matching backward chain
- Timeline with buffer based on complexity scoring
- Dependency graph for cross-team coordination

---

### 2. refactoring-lead Agent

**Role**: Technical refactoring strategy and execution

**How Backcasting Helps**:
- Defines target architecture clearly
- Identifies intermediate architectural states
- Ensures refactoring path is feasible
- Catches missing technical prerequisites

**Usage Pattern**:
```
refactoring-lead receives: "Evolve to event-driven architecture"

1. refactoring-lead invokes: work-backcasting-framework
   - Define end state: All services communicate via events
   - Build backward chain: Sync → Hybrid → Async
   - Identify prerequisites: Message broker, schemas, etc.

2. refactoring-lead plans:
   - Strangler fig pattern to incrementally migrate
   - Test strategy for each transition
   - Rollback procedures for safety
   - Performance monitoring at each stage
```

**Output**:
- Technical refactoring roadmap
- Code change sequence
- Test coverage requirements
- Performance benchmarks per phase

---

### 3. migration-specialist Agent

**Role**: System and data migration execution

**How Backcasting Helps**:
- Plans migration path from current to target system
- Identifies data migration prerequisites
- Validates zero-downtime migration feasibility
- Catches data integrity requirements early

**Usage Pattern**:
```
migration-specialist receives: "Migrate from MySQL to PostgreSQL"

1. migration-specialist invokes: work-backcasting-framework
   - Define end state: All data in Postgres, MySQL decommissioned
   - Build backward chain: MySQL only → Dual-write → Postgres primary → MySQL gone
   - Identify prerequisites: Schema migration, data validation, rollback plan

2. migration-specialist executes:
   - Phase 1: Deploy Postgres, test schema
   - Phase 2: Implement dual-write
   - Phase 3: Validate data parity
   - Phase 4: Switch reads to Postgres
   - Phase 5: Decommission MySQL
```

**Output**:
- Migration runbook with exact steps
- Data validation procedures
- Rollback procedures per phase
- Downtime estimation

---

### 4. architecture-reviewer Agent

**Role**: Validate architectural decisions and plans

**How Backcasting Helps**:
- Provides reviewable architectural evolution path
- Makes assumptions and constraints explicit
- Enables validation of each intermediate state
- Surfaces architectural contradictions early

**Usage Pattern**:
```
architecture-reviewer receives: Architecture evolution plan

1. Validate end state:
   - Check for contradictory properties
   - Verify technical feasibility
   - Assess alignment with principles

2. Review backward chain:
   - Validate each intermediate state
   - Check transition feasibility
   - Identify missing states

3. Check prerequisites:
   - Verify all technical prerequisites listed
   - Assess infrastructure readiness
   - Flag missing organizational prerequisites
```

**Output**:
- Architecture review report
- List of issues/risks
- Recommended changes to plan
- Sign-off or request for revision

---

## Cross-Skill Workflows

### Workflow 1: Strategic Migration Planning

```
Objective: Plan major system migration

Agents: project-planner, migration-specialist, architecture-reviewer

Steps:
1. project-planner uses work-backcasting:
   - Define migration end state
   - Build backward chain
   - Identify high-level prerequisites

2. migration-specialist refines:
   - Add data migration specifics
   - Detail rollback procedures
   - Plan validation steps

3. architecture-reviewer validates:
   - Check architectural consistency
   - Validate technical feasibility
   - Approve or request changes

4. project-planner finalizes:
   - Create timeline with buffers
   - Assign resources
   - Communicate to stakeholders
```

---

### Workflow 2: Architecture Evolution

```
Objective: Evolve system architecture over time

Agents: refactoring-lead, project-planner

Steps:
1. refactoring-lead uses work-backcasting:
   - Define target architecture
   - Build backward chain of architectural states
   - Identify refactoring prerequisites

2. project-planner converts to roadmap:
   - Map chain to quarterly milestones
   - Allocate team capacity
   - Plan stakeholder communication

3. refactoring-lead executes:
   - Implement each phase
   - Validate architecture at each state
   - Adjust plan based on learnings
```

---

### Workflow 3: Greenfield Project Planning

```
Objective: Plan new system from scratch

Agents: project-planner, architecture-reviewer

Steps:
1. project-planner uses work-backcasting:
   - Define production-ready end state
   - Build backward chain to empty repo
   - Identify all prerequisites (infrastructure, team, etc.)

2. architecture-reviewer validates:
   - Review technical decisions in end state
   - Check prerequisite completeness
   - Validate timeline feasibility

3. project-planner creates plan:
   - Phase work based on backward chain
   - Add contingencies for risks
   - Create launch checklist
```

---

## Integration API

### Invoking from Another Agent

```python
from skills.work_backcasting import BackcastingFramework

# Initialize
framework = BackcastingFramework()

# Define end state
end_state = framework.define_end_state(
    name="Microservices Architecture",
    description="15 independently deployable services",
    metrics=[
        {"name": "deployment_frequency", "current": 1, "target": 10, "unit": "per_day"},
        {"name": "service_count", "current": 1, "target": 15, "unit": "services"}
    ]
)

# Build backward chain
current_state = framework.describe_current_state(
    architecture="monolith",
    deployment="manual"
)

chain = framework.build_chain(current_state, end_state)

# Identify prerequisites
prerequisites = framework.identify_prerequisites(chain)

# Check feasibility
constraints = {
    "max_timeline_weeks": 52,
    "max_budget_usd": 500000,
    "team_size": 8
}

is_feasible, issues = framework.check_feasibility(
    chain,
    prerequisites,
    constraints
)

# Generate plan
if is_feasible:
    plan = framework.generate_execution_plan(chain, prerequisites)
    return plan
else:
    return {"error": "Plan not feasible", "issues": issues}
```

---

## Configuration

### Enabling Backcasting in Agent Config

```yaml
agent:
  name: project-planner
  skills:
    - work-backcasting-framework
    - work-forecasting-framework
    - gap-analysis-framework

  workflows:
    migration_planning:
      steps:
        - skill: work-backcasting-framework
          action: define_end_state
        - skill: work-backcasting-framework
          action: build_backward_chain
        - skill: work-forecasting-framework
          action: validate_timeline
        - skill: gap-analysis-framework
          action: analyze_capability_gaps
```

---

## Best Practices for Integration

### 1. Always Define End State First
Before invoking backward chaining, ensure end state meets SMART criteria.

### 2. Combine with Forecasting
Use forecasting to validate backward-planned timelines.

### 3. Iterate on Plans
First pass often misses prerequisites. Review and refine.

### 4. Share Context
Use context engineering to document assumptions at each state.

### 5. Gate on Feasibility
Don't proceed with infeasible plans. Fix issues first.

---

## Troubleshooting Integration Issues

### Issue: Plans are consistently infeasible

**Cause**: End state too ambitious or constraints too tight

**Solution**:
1. Relax constraints if possible (extend timeline, increase budget)
2. Reduce scope of end state
3. Break into multiple phases

---

### Issue: Backward chain has gaps

**Cause**: Missing domain knowledge about intermediate states

**Solution**:
1. Consult domain experts
2. Build prototype to understand transitions
3. Use existing migration patterns as templates

---

### Issue: Prerequisites keep growing

**Cause**: Incomplete initial analysis

**Solution**:
1. Use systematic 7-dimension prerequisite checklist
2. Do team brainstorming session
3. Review similar past projects

---

## Future Integration Plans

### Planned Skills to Integrate

1. **AI Evaluation Suite**: Evaluate quality of backward chains
2. **Security Scanning Suite**: Validate security at each state
3. **Orchestration Framework**: Execute backward chains in production

### Planned Agent Roles

1. **complexity-estimator**: Provide effort estimates per transition
2. **risk-assessor**: Evaluate risk at each phase
3. **stakeholder-communicator**: Generate updates based on chain progress

---

## Summary

The Work Backcasting Framework is designed to integrate seamlessly with:

- **Strategic planning** (project-planner, architecture-reviewer)
- **Technical execution** (refactoring-lead, migration-specialist)
- **Validation** (forecasting, gap analysis, feasibility checks)

Use backcasting when you have a clear destination but need to figure out how to get there systematically.
