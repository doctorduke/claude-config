# umemee-v0 Development Systems: Complete Synthesis

*Purpose: Unified briefing on our development infrastructure, building from foundational concepts to complex orchestration.*

---

## Part I: Foundation - Documentation as Code

### The BRIEF System: Our Knowledge Layer

Every piece of our codebase speaks through BRIEFs - interface-first documentation that defines what goes IN and what comes OUT before describing implementation.

**Core Principle**: A module is its interface contract. Implementation can change; contracts should not.

```
Module → BRIEF.md (Interface Contract) → Implementation
         ↓
    Inputs/Outputs defined FIRST
```

**Data Flow**:
1. Business requirements enter as documents (PRDs, chats, specs)
2. Mapping matrix transforms them to BRIEFs (Requirements → Interface Contract)
3. BRIEFs define module boundaries and contracts
4. Code implements the contracts
5. Tests validate the contracts

**Quality Gates**:
- No module without BRIEF
- No BRIEF without Interface Contract
- No implementation without contract definition
- No PR without BRIEF update

This creates a **traceable path** from business need to code change.

---

## Part II: Orchestration - Intelligent Automation

### AI Agent Workflow: Risk-Based Routing

Building on our documentation foundation, agents read BRIEFs to understand context, then execute based on risk assessment.

**Risk Calculation** (builds on BRIEF data):
```
Risk = Σ(weight × feature)

Features extracted from:
- BRIEF critical paths (shared/types/**, api-client/**)
- Code change size (lines modified)
- Test coverage impact
- Static analysis findings
```

**Chain Selection** (risk drives complexity):
- **Chain A** (Risk < 0.25): Simple agent → Quick review → Auto-merge
  - For: UI components, documentation, utilities
  - Agents: Cursor → Codex
  - Human Gate: No

- **Chain B** (Risk 0.25-0.60): Multiple reviews → Consensus
  - For: Config changes, API modifications
  - Agents: Codex → Gemini → Claude
  - Human Gate: No

- **Chain C** (Risk > 0.60): Expert review → Human approval
  - For: Type definitions, critical paths
  - Agents: Claude → Gemini
  - Human Gate: Required

**Data Flow Through Chains**:
```
Task Issue → BRIEF Context → Risk Score → Chain Selection →
Agent Execution → Review Generation → Merge Decision → BRIEF Update
```

---

## Part III: Process Control - Git & Workflow

### Git as Process Backbone

Our Git workflow enforces the documentation-first approach and maintains system integrity.

**Branch Strategy** (enforces isolation):
```
trunk (protected)
  ├── feat/feature-name    (new capabilities)
  ├── fix/issue-id         (bug fixes)
  ├── docs/area           (documentation)
  └── chore/task          (maintenance)
```

**Enforcement Mechanisms**:
1. **Pre-push Hook**: Blocks direct trunk pushes
2. **PR Requirement**: All changes through pull requests
3. **BRIEF Update**: PRs must update affected BRIEFs
4. **Agent Review**: Automated review based on risk

**Data Flow**:
```
Feature Branch → PR Creation → Agent Analysis → Risk Assessment →
Review Chain → Tests → BRIEF Validation → Merge to Trunk
```

---

## Part IV: Feedback Loops - Evaluation System

### Continuous Process Improvement

Every action generates metrics that feed back into system optimization.

**Measurement Points**:
1. **Task Clarity** (start): How well-defined is the work?
2. **Agent Performance** (execution): Success rate, cost, time
3. **Review Quality** (review): Changes requested, accuracy
4. **Production Impact** (post-merge): Defects, reverts

**Optimization Cycle**:
```
Measure → Analyze → Recommend → Adjust → Measure
   ↓        ↓          ↓          ↓        ↓
Events   Formulas   Thresholds  Configs  Events
```

**Feedback Integration**:
- Poor task clarity → Enforce templates
- High agent errors → Adjust prompts
- Excessive rework → Strengthen early review
- Budget overruns → Lower risk thresholds

---

## Part V: Team Protocols - Communication & Coordination

### Structured Collaboration

All team interactions follow defined protocols that integrate with our systems.

**Communication Channels**:
1. **GitHub Issues**: Task definition with BRIEF references
2. **PR Comments**: Technical discussion with agent participation
3. **BRIEFs**: Persistent documentation updates
4. **Agent Responses**: Automated analysis and suggestions

**Decision Recording**:
```
Discussion → Decision → BRIEF Update → Implementation
    ↓           ↓            ↓              ↓
PR/Issue    Dated Entry   Rationale    Code Change
```

**Agent Coordination**:
- Multiple agents work in parallel (@claude, @codex, @gemini)
- Each maintains distinct identity
- Risk routing prevents conflicts
- Budget controls prevent overrun

---

## Part VI: Integration - The Complete System

### How It All Works Together

**Task Lifecycle** (full integration):

1. **Business Need Identified**
   - Captured in issue/PR
   - References existing BRIEFs
   - Defines Interface Contract changes

2. **Task Issued**
   - Template enforces clarity
   - Links to module BRIEF
   - Estimates risk level

3. **Agent Assignment**
   - Risk score calculated
   - Chain selected (A/B/C)
   - Budget allocated

4. **Implementation**
   - Agent reads BRIEF context
   - Generates code changes
   - Updates tests

5. **Review Process**
   - Chain executes reviews
   - Risk reassessed if needed
   - Escalation if required

6. **Merge Decision**
   - Tests must pass
   - BRIEF must be updated
   - Budget checked
   - Human gate if high risk

7. **Post-Merge**
   - Metrics collected
   - Defects tracked
   - Feedback processed
   - System adjusted

---

## Part VII: Practical Application

### Day 1: Starting a Feature

```bash
# 1. Create feature branch
git checkout -b feat/user-auth

# 2. Review module BRIEF
cat features/auth/BRIEF.md

# 3. Create task issue
gh issue create --title "Implement JWT authentication" \
  --body "Updates Interface Contract: adds login endpoint"

# 4. Agent analyzes and implements
@claude implement the JWT authentication per BRIEF

# 5. Review chain executes
# Risk: 0.45 → Chain B → Codex→Gemini→Claude

# 6. Merge with updated BRIEF
# PR includes auth/BRIEF.md changes
```

### Debugging a Production Issue

```bash
# 1. Issue reported
Error: Type mismatch in api-client

# 2. Risk assessed
shared/types/** affected → Risk: 0.75 → Chain C

# 3. Claude investigates with BRIEF context
@claude analyze type mismatch using types/BRIEF.md

# 4. Fix implemented with human gate
# Requires approval before merge
```

### Improving Process

```yaml
# Weekly metrics show:
task_clarity: 0.65  # Below 0.8 target
rework_rate: 2.1    # Above 1.5 target

# System recommends:
- Strengthen issue templates
- Add Chain A pre-review
- Adjust risk weight for coverage

# Team implements:
- New template required fields
- Codex pre-review for all chains
- coverage_drop weight: 0.10 → 0.15
```

---

## Part VIII: Success Metrics & Monitoring

### What We Track

**Documentation Health**:
- BRIEF coverage: 100% (22/22 modules)
- Interface Contracts: 100% defined
- Decision capture rate: Target >90%

**Process Efficiency**:
- Task → PR time: Target <24h (low risk)
- PR → Merge time: Target <4h (Chain A)
- Rework rate: Target <1.5 cycles

**Quality Outcomes**:
- Post-merge defects: Target <2%
- Direct trunk commits: Target 0
- Budget per PR: Target <$2.00

**Team Velocity**:
- PRs per sprint
- Story points completed
- Cycle time reduction

---

## Part IX: Tools & Commands Reference

### Essential Commands

```bash
# BRIEF System
/init-briefs              # Initialize documentation
/brief-ingest <doc>       # Parse document to BRIEF
/brief-status            # Check coverage

# Agent Control
@claude <task>           # Invoke Claude
@codex <task>           # Invoke Codex (when enabled)
/route low|med|high     # Override risk routing
/budget <amount>        # Set PR budget
/halt                   # Stop automation

# Git Workflow
git checkout -b feat/X  # Create feature branch
gh pr create           # Create pull request
gh issue create        # Create task issue
```

### Configuration Files

```yaml
.aiops/policy.yaml      # Risk weights, thresholds
.github/workflows/      # Agent automation
.githooks/pre-push     # Branch protection
BRIEF.md               # Module documentation
CLAUDE.md              # Agent instructions
```

---

## Part X: Evolution & Scaling

### Current State → Future State

**Today**:
- Single agent (Claude) active
- Manual task creation
- Basic risk scoring
- Local evaluation

**Next Sprint**:
- Codex integration
- Automated task generation
- Refined risk weights
- Centralized metrics

**Next Quarter**:
- Full agent orchestra
- Self-improving prompts
- Predictive risk scoring
- Real-time dashboards

### Scaling Considerations

As we grow:
1. **More agents** → Better parallel execution
2. **More data** → Smarter risk assessment
3. **More automation** → Less manual overhead
4. **More metrics** → Continuous improvement

The system is designed to scale horizontally (more agents) and vertically (smarter agents).

---

## Conclusion: The Synthesis

Our development system is a **self-reinforcing cycle**:

1. **BRIEFs** define clear contracts
2. **Agents** implement those contracts
3. **Git workflow** ensures quality
4. **Evaluation** improves the process
5. **Better process** creates better BRIEFs

Each component strengthens the others, creating a development environment that:
- Accelerates delivery through automation
- Maintains quality through systematic review
- Improves continuously through measurement
- Scales efficiently through parallelization

This is not just tooling - it's a **development philosophy** where documentation drives development, risk drives review depth, and metrics drive improvement.

The result: A sharp, efficient process that transforms business needs into production code with minimal friction and maximum quality.

---

*This document represents our current development methodology. It will evolve as we refine our processes based on measured outcomes.*