# Agent Routing Logic Specification

## Risk-Based Agent Selection

### Risk Calculation Algorithm

```yaml
risk_calculation:
  weights:
    patch_lines_norm: 0.20      # min(1, lines/400)
    critical_files: 0.25        # auth/**, payments/**, migrations/**
    coverage_drop: 0.15         # coverage delta
    static_sev: 0.20           # HIGH/CRIT findings
    self_conf_neg: 0.10        # 1 - model_confidence
    changed_endpoints: 0.10     # min(1, api_changes/5)

score_calculation: "risk_score = Σ(weight[i] * feature[i])"
```

### Agent Selection Matrix

| Risk Level | Primary Agent | Fallback Agent | Human Gate |
|------------|---------------|----------------|------------|
| 0.0-0.25   | Cursor        | Codex          | No         |
| 0.25-0.60  | Codex         | Gemini         | No         |
| 0.60-1.0   | Claude        | Gemini         | Yes        |

### Routing Decision Logic

```typescript
function selectAgent(task: AgentTask): AgentSelection {
  const risk = calculateRiskScore(task);
  
  if (risk < 0.25) {
    return {
      primary: 'cursor',
      fallback: 'codex',
      humanGate: false,
      chain: 'A'
    };
  } else if (risk < 0.60) {
    return {
      primary: 'codex',
      fallback: 'gemini',
      humanGate: false,
      chain: 'B'
    };
  } else {
    return {
      primary: 'claude',
      fallback: 'gemini',
      humanGate: true,
      chain: 'C'
    };
  }
}
```

## Token Budget Management

### Budget Allocation

```yaml
token_buckets:
  cursor:  {capacity: 200000, refill_per_min: 40000}
  codex:   {capacity: 250000, refill_per_min: 50000}
  gemini:  {capacity: 250000, refill_per_min: 50000}
  claude:  {capacity: 150000, refill_per_min: 30000}

budget_rules:
  default_per_pr: 2.50
  early_exit_threshold: 0.70
  max_escalation_cost: 5.00
```

### Circuit Breaker Logic

```typescript
interface CircuitBreaker {
  error_burst: 3;           // Open after 3 consecutive errors
  p95_latency_ms: 120000;   // Open if p95 > 2 minutes
  cooldown_ms: 300000;      // 5 minute cooldown
}
```

## Escalation Conditions

### Chain A → B Escalation
- Tests fail 2x consecutively
- Static analyzer reports HIGH/CRIT findings
- Risk score increases to ≥ 0.25
- Implementer confidence < 0.65
- Agent circuit breaker opens

### Chain B → C Escalation
- Unresolved HIGH risks after amendment
- Risk score increases to > 0.60
- Patch churn > 2 rounds
- Codex/Gemini token caps reached

### Early Exit Conditions
Merge at current chain when ALL conditions met:
- Tests green
- Lint green
- No HIGH risk findings
- Budget consumed < 70% of task max
- `early_exit_when_green: true` in policy
