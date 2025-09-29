# Agent Orchestration Detailed Specification v1

## Full Implementation Details

### Risk Scoring Algorithm

```yaml
risk:
  weights:
    patch_lines_norm: 0.20    # min(1, lines_changed/400)
    critical_files: 0.25      # 1 if touches auth/**, payments/**, migrations/**, secrets/**
    coverage_drop: 0.15       # min(1, max(0, (cov_before - cov_after)/10))
    static_sev: 0.20          # normalized HIGH/CRIT findings
    self_conf_neg: 0.10       # 1 - model_confidence (0..1)
    changed_endpoints: 0.10   # min(1, api_changes/5)
```

Score calculation:
```
risk_score = Σ(weight[i] * feature[i])
```

### Token Budget Management

```yaml
caps:
  token_buckets:
    cursor:  {capacity: 200000, refill_per_min: 40000}
    codex:   {capacity: 250000, refill_per_min: 50000}
    gemini:  {capacity: 250000, refill_per_min: 50000}
    claude:  {capacity: 150000, refill_per_min: 30000}
  breaker:
    error_burst: 3
    p95_latency_ms: 120000
```

### Escalation Decision Matrix

| From Chain | Condition | Action |
|------------|-----------|--------|
| A | Tests fail 2x | Escalate to B |
| A | Static analyzer HIGH/CRIT | Escalate to B |
| A | risk ≥ 0.25 | Escalate to B |
| A | Implementer confidence < 0.65 | Escalate to B |
| A | Agent circuit open | Escalate to B |
| B | Unresolved HIGH after amend | Escalate to C |
| B | risk > 0.60 | Escalate to C |
| B | Patch churn > 2 rounds | Escalate to C |
| B | Codex/Gemini capped | Escalate to C |

### Early Exit Conditions

Merge at current chain when ALL conditions met:
- Tests green
- Lint green
- No HIGH risk findings
- Budget consumed < 70% of task max
- `early_exit_when_green: true` in policy

### Cap/Budget Decision Table

| Risk Level | Budget Status | Cap Status | Action |
|------------|--------------|------------|--------|
| Low | OK | Cursor OK | Run Chain A |
| Low | OK | Cursor near cap | Chain A without micro-spec |
| Medium | Tight | Codex/Gemini OK | A→B-lite (skip final Claude) |
| High | Any | Claude OK | Chain C |
| High | Any | Claude capped | C': Gemini impl + Human gate |

### LLM_PATCH v1 Format

```json
{
  "base": "commit-sha",
  "edits": [
    {
      "file": "src/api.ts",
      "op": "patch",
      "unified": "@@ -12,7 +12,9 @@\n-old line\n+new line"
    },
    {
      "file": "package.json",
      "op": "set",
      "content": "{complete file content}"
    }
  ],
  "tests": {
    "command": "pnpm test",
    "expect": {"passed": true}
  }
}
```

### Review Card Schema

```json
{
  "kind": "logic_review",
  "risks": [
    {
      "id": "r1",
      "sev": "high",
      "msg": "null dereference on line 42",
      "file": "src/handler.ts",
      "line": 42
    }
  ],
  "suggestions": [
    "Add null check before accessing user.id",
    "Consider using optional chaining"
  ],
  "approval": false,
  "confidence": 0.75
}
```

### GitHub Integration Commands

#### Supported Labels
- `ai:low`, `ai:med`, `ai:high` - Manual risk override
- `ai:security` - Subscribe SecurityBot
- `ai:lint` - Subscribe LintBot
- `ai:docs` - Subscribe DocsBot
- `ai:budget:$` - e.g., `ai:budget:2.50`

#### Slash Commands
- `/route low|med|high` - Override automatic routing
- `/budget <dollars>` - Set PR-specific budget
- `/escalate` - Force next tier
- `/halt` - Stop all automation

### Attention Gating (Subscription Model)

Agents consume messages only when:
1. PR has subscribed label for that bot, OR
2. Bot is explicitly @mentioned, OR
3. Risk score exceeds bot's min_risk threshold

Example subscription config:
```yaml
attention:
  subscribe:
    LintBot:
      labels: ["ai:lint"]
      globs: ["**/*.ts","**/*.js"]
      min_risk: 0.0
    SecurityBot:
      labels: ["ai:security"]
      globs: ["**/*"]
      min_risk: 0.4
```

### Cost Model

Expected cost calculation:
```
E[C] = Ca + p_ab*Rb + p_ab*p_bc*Cc
```

Where:
- Ca/La = cost/latency for Chain A
- Rb/Lb = cost/latency for B review
- Cc/Lc = cost/latency for C implement
- p_ab = probability of A→B escalation
- p_bc = probability of B→C escalation

### State Machine

```
QUEUED → ROUTED(agent) → RUNNING →
  {REVIEW, FAILED(retryable), BLOCKED(human|policy)} →
  FALLBACK(next_agent) → DRAFT_PR → REVIEW_CHAIN →
  {APPROVED, CHANGES_REQUESTED} → MERGED → CANARY →
  {ROLLED_BACK, STABLE}
```

Guards:
- quota_ok
- policy_ok
- tests_ok
- risk_score < threshold
- time_budget_ok

### Manifest Compilation Targets

Source: `canon.rules.yaml`

Targets:
- `CLAUDE.md` - Consolidated rules for Claude
- `.cursor/rules/*.mdc` - Split by domain for Cursor
- `AGENTS.md` - Batch job specs for Codex
- `GEMINI.md` / `.gemini/system.md` - System persona for Gemini

### Metrics & SLOs

Key metrics:
- % PRs resolved at Chain A (target ≥70%)
- Post-merge defect rate (target ≤2%)
- Avg cost per merged PR
- Token burn per PR
- Cap-related retries/week
- Circuit breaker open time
- p95 latency
- Rework rate

### Security Policies

- Prompt injection sanitization
- Strip tool-escape sequences
- Deny `!include` in manifests
- SBOM & license gates via CI
- Secrets scanner on diffs
- Quarantine on detection