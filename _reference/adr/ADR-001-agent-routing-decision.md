# ADR-001: Risk-Based Agent Routing Decision

**Date**: 2025-10-02
**Status**: Accepted
**Deciders**: Development Team, AI Architecture Review

## Context

The umemee-v0 project requires automated agent coordination for development workflows. We need to decide how to route tasks to appropriate AI agents (Claude, Codex, Gemini, Cursor) based on task characteristics and risk levels.

## Decision

We will implement a **risk-based agent routing system** with three escalation chains:

- **Chain A (Low Risk)**: Cursor → Codex → auto-merge
- **Chain B (Medium Risk)**: Codex → Gemini → Claude → merge
- **Chain C (High Risk)**: Claude → Gemini → human gate required

### Risk Scoring Algorithm

```yaml
risk_weights:
  patch_lines_norm: 0.20    # min(1, lines_changed/400)
  critical_files: 0.25      # auth/**, payments/**, migrations/**
  coverage_drop: 0.15       # min(1, max(0, (cov_before - cov_after)/10))
  static_sev: 0.20          # normalized HIGH/CRIT findings
  self_conf_neg: 0.10       # 1 - model_confidence
  changed_endpoints: 0.10   # min(1, api_changes/5)

thresholds:
  low: 0.25
  high: 0.60
```

## Rationale

### Why Risk-Based Routing?

1. **Cost Optimization**: Low-risk tasks use cheaper agents (Cursor), high-risk tasks use more capable agents (Claude)
2. **Quality Assurance**: High-risk changes get human oversight
3. **Scalability**: Automated routing reduces manual coordination overhead
4. **Audit Trail**: Clear escalation path for debugging and learning

### Why These Specific Chains?

- **Chain A**: Cursor excels at UI/frontend tasks, Codex provides good review
- **Chain B**: Codex handles general coding, Gemini provides logic review, Claude finalizes
- **Chain C**: Claude handles complex architecture, human gate for safety

### Why These Risk Weights?

- **Critical Files (0.25)**: Highest weight - changes to auth/payments affect security
- **Patch Lines (0.20)**: Size correlates with complexity and risk
- **Static Analysis (0.20)**: Automated security/quality findings
- **Coverage Drop (0.15)**: Test coverage is important but not critical
- **Confidence (0.10)**: Agent confidence is useful but not primary factor

## Consequences

### Positive

- **Reduced Costs**: ~70% of tasks use cheaper agents
- **Better Quality**: High-risk changes get appropriate attention
- **Automated Scaling**: System handles varying workloads automatically
- **Clear Escalation**: Predictable path for complex issues

### Negative

- **Complexity**: More complex than simple round-robin
- **Tuning Required**: Risk weights may need adjustment over time
- **False Positives**: Some low-risk tasks may be over-escalated
- **Learning Curve**: Team needs to understand routing logic

### Mitigations

- **Monitoring**: Track routing accuracy and adjust weights
- **Override Commands**: Manual routing when automatic routing fails
- **Gradual Rollout**: Start with conservative thresholds
- **Documentation**: Clear explanation of routing logic

## Implementation Notes

- Risk scoring happens at task creation time
- Routing decisions are logged for audit
- Manual overrides available via GitHub labels
- Circuit breakers prevent infinite escalation

## Related Decisions

- ADR-002: Validation Gate Design
- ADR-003: Brief Modularization Strategy
- ADR-004: Token Budget Management

## References

- [Agent Coordination BRIEF](../docs/agent-coordination/BRIEF.md)
- [Routing Logic Spec](../docs/agent-coordination/_reference/spec/routing-logic.md)
- [Risk Analysis Report](../docs/ai-dev-workflow/_reference/implementation/umemee-integration-plan.md)
