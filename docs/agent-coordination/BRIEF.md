# Agent Coordination — BRIEF

## Purpose & Boundary

Orchestrates AI coding agents (Claude, Codex, Gemini, Cursor) for automated development workflows. Implements risk-based routing, review chains, and budget controls for PR automation. Manages 151 specialized AI agents with standardized coordination patterns.

**Submodules:**
- `routing/` - Risk-based agent selection and task routing
- `chains/` - Escalation chains and review workflows
- `policy/` - Configuration and decision rules
- `communication/` - Inter-agent messaging and handoff protocols

## Interface Contract

**Inputs**
- GitHub events: PRs, issues, comments with `/route`, `/budget`, `/escalate` commands
- Task specifications with risk scores (0.0-1.0 scale)
- Agent availability signals (token caps, circuit breaker state)
- Policy configuration (.aiops/policy.yaml)

**Outputs**
- Routed tasks to appropriate agent chains (A/B/C)
- LLM_PATCH v1 unified diffs for code changes
- Review cards with risk assessments and suggestions
- Budget consumption metrics and cap enforcement
- Merge/rollback decisions based on quality gates

**Chain A (Low Risk) — Flow**
- Cursor implements → Codex review → auto-merge on green tests
- Acceptance: GIVEN risk < 0.25 WHEN tests pass THEN merge without human gate

**Chain B (Medium Risk) — Flow**
- Codex implements → Gemini logic review → Claude final edit
- Acceptance: GIVEN risk 0.25-0.60 WHEN HIGH risks resolved THEN merge

**Chain C (High Risk) — Flow**
- Claude implements → Gemini adversarial check → Human gate required
- Acceptance: GIVEN risk > 0.60 THEN require human approval before merge

**Anti-Goals**
- No autonomous deployment to production
- No secret handling or credential management
- No direct database modifications

## Dependencies & Integration Points

**Upstream**
- GitHub webhooks for PR/issue events
- Risk scoring from static analysis & coverage tools
- Agent APIs: Claude, Cursor, Codex, Gemini

**Downstream**
- CI/CD pipelines consume patches
- Monitoring systems track success metrics
- Learning store updates prompts/weights

## Work State

**Planned**
- [ORC-001] Token bucket implementation (target 2025-10-01)
- [ORC-002] Circuit breaker for error bursts (target 2025-10-05)
- [ORC-003] Micro-speculative scanning (target 2025-10-10)
- [ORC-006] Agent pairing protocols for complex tasks
- [ORC-007] Decision register for architectural choices

**Doing**
- [ORC-004] GitHub Actions workflow setup (started 2025-09-28)

**Done**
- [ORC-005] Risk scoring weights defined (merged 2025-09-27)
- [ORC-008] Agent coordination patterns documented
- [ORC-009] Task handoff protocols established

## Spec Snapshot (2025-10-02)

- **Features**: 3-tier escalation chains, token budget caps, early exit optimization, 151 agent patterns
- **Tech**: TypeScript, GitHub Actions, Octokit API, YAML policy configs
- **Risk weights**: patch_lines (0.20), critical_files (0.25), coverage_drop (0.15)
- **Thresholds**: low < 0.25, high > 0.60
- **Budget**: $2.50 default per PR, early exit at 70%
- **Agents**: 151 specialized coordination patterns documented

## Decisions & Rationale

- **2025-09-27** — Token buckets over rate limits (burst handling flexibility)
- **2025-09-27** — Risk-based routing over round-robin (cost optimization)
- **2025-09-28** — LLM_PATCH v1 format (deterministic, revertable edits)
- **2025-10-02** — Agent pairing patterns for complex multi-step tasks
- **2025-10-02** — Decision register pattern for architectural choices

## Local Reference Index

- **_reference/spec/routing-logic.md** → Risk-based agent selection and routing logic
- **_reference/spec/state-machines.md** → Task, agent, and workflow state machine definitions
- **_reference/spec/communication-protocols.md** → Inter-agent messaging formats and protocols
- **_reference/implementation/agent-selection.md** → Implementation details for agent selection algorithms
- **_reference/implementation/task-handoff.md** → Implementation details for task handoff protocols

## Answer Pack

```yaml
kind: answerpack
module: docs/agent-coordination
intent: "Risk-based multi-agent task routing with escalation chains and budget controls"
chains:
  A:
    risk_range: [0.0, 0.25]
    agents: ["cursor", "codex"]
    human_gate: false
  B:
    risk_range: [0.25, 0.60]
    agents: ["codex", "gemini", "claude"]
    human_gate: false
  C:
    risk_range: [0.60, 1.0]
    agents: ["claude", "gemini"]
    human_gate: true
work_state:
  planned: ["ORC-001 token buckets", "ORC-002 circuit breaker", "ORC-003 micro-spec", "ORC-006 agent pairing", "ORC-007 decision register"]
  doing: ["ORC-004 github workflow"]
  done: ["ORC-005 risk weights", "ORC-008 coordination patterns", "ORC-009 handoff protocols"]
interfaces:
  inputs: ["github_events", "risk_scores", "agent_caps", "policy_yaml"]
  outputs: ["task_routes", "llm_patches", "review_cards", "merge_decisions"]
truth_hierarchy: ["source", "tests", "BRIEF", "_reference", "issues"]
```
