# Agent Orchestration Forensic Workbook — Escalation-Integrated Edition

> Consolidates the base workbook with the escalation policy, early-exit rules, cap/budget guards, and GitHub Router pack. This edition supersedes the separate “Task Escalation Playbook & Cost Model” canvas.

---

## 1) Dependency Graph & Critical Paths

### 1.1 Dependency Table

| Dependency                                                       | Governing Field        | Why It Matters                                    | Failure Mode                           | Detection                            | Mitigation                               |
| ---------------------------------------------------------------- | ---------------------- | ------------------------------------------------- | -------------------------------------- | ------------------------------------ | ---------------------------------------- |
| Canonical ruleset (canon.rules.yaml)                             | Prompt/RAG engineering | Single source of truth for behavioral constraints | Divergent behavior across tools        | Drift checks on compiled manifests   | Codegen pipeline + schema validation     |
| Manifest compilers (to CLAUDE.md / .mdc / AGENTS.md / GEMINI.md) | Developer tooling      | Transport rules into each tool format             | Compiler bugs; unsupported constructs  | Compiler unit tests + roundtrip diff | Feature flags; per-tool adapters         |
| Orchestrator (router + planner + reviewer)                       | Distributed systems    | Task routing, retries, fallbacks, SLAs            | Backpressure collapse; thundering herd | Queue depth, RTO, error budgets      | Token buckets; circuit breakers; queues  |
| GitHub Conversations integration                                 | DevOps/ChatOps         | Shared surface for agent dialogue                 | Missed events; spam                    | Webhook delivery metrics; rate       | Labels, mention-gates, subscription maps |
| Diff/patch format (LLM_PATCH v1)                                 | SCM/Code Review        | Deterministic edits; easy apply/revert            | Non-atomic patches; conflicts          | Patch apply simulation in CI         | 3-way merge, conflict prompts            |
| Budget/quotas (per agent)                                        | FinOps                 | Prevent runaway cost                              | Hard caps; silent refusal              | Spend meters; per-task budget        | Price-aware routing; graceful degrade    |
| Security/SBOM & secret handling                                  | AppSec/Supply Chain    | Prevent leakage/injection                         | Secret spill; prompt injection         | Policy-as-code checks                | Secret scanners; content filters         |
| Telemetry & metrics                                              | SRE/Observability      | Close loop; learning                              | Blind spots                            | Golden signals; tracing              | Structured logs; span tags               |

### 1.2 Critical Path Sketch

```
Task -> Triager(Route, SLA, Budget) -> Planner(Decompose) -> Workers(Claude/Codex/Cursor/Gemini)
     -> Draft PR (LLM_PATCH) -> Multi-bot Review Chain -> Gatekeepers (tests, policy) -> Merge
     -> Post-merge Monitors (rollbacks, canary) -> Learning Store (prompts/upgrades)
```

---

## 2) State Machines

### 2.1 Orchestration State Machine

States: `QUEUED` → `ROUTED(agent)` → `RUNNING` → {`REVIEW`, `FAILED(retryable)`, `BLOCKED(human|policy)`} → `FALLBACK(next_agent)` → `DRAFT_PR` → `REVIEW_CHAIN` → {`APPROVED`, `CHANGES_REQUESTED`} → `MERGED` → `CANARY` → {`ROLLED_BACK`, `STABLE`}.

Guards: `quota_ok`, `policy_ok`, `tests_ok`, `risk_score<threshold`, `time_budget_ok`.

### 2.2 Attention/Interest Gating for Conversations

* **Subscriptions**: agents register interest predicates `(label ∈ {backend, api}, file_glob, risk>0.5)`.
* **Mention gate**: default muted; consume only when `@bot` or predicate matches.
* **Sparse broadcast**: summary digest to muted agents; full thread to subscribers.

---

## 3) Canonical Ruleset & Manifest Compilers

### 3.1 Canonical Schema (excerpt)

```yaml
version: 0.3
style:
  code: ["typescript-strict", "eslint-airbnb"]
  tests: ["vitest", "100% branch coverage for critical paths"]
policies:
  secrets: "never print, redact in logs"
  patch: "produce atomic LLM_PATCH with context"
routing:
  cost_ceiling_usd: 2.00
  risk_tiers:
    - name: low
      agents: [codex, cursor]
    - name: medium
      agents: [gemini, claude]
    - name: high
      agents: [claude]
```

### 3.2 Compiled Manifests (targets)

* **CLAUDE.md**: consolidated rules, file globs, patch contract.
* **.cursor/rules/*.mdc**: split by domain; includes `@rule` headers.
* **AGENTS.md (Codex)**: batch job specs + output schema.
* **GEMINI.md / .gemini/system.md**: system persona + tool bindings.

---

## 4) Artifact Contracts

### 4.1 LLM_PATCH v1 (unified diff)

```json
{
  "base": "commit-sha",
  "edits": [
    {"file": "src/api.ts", "op": "patch", "unified": "@@ -12,7 +12,9 @@ ..."},
    {"file": "package.json", "op": "set", "content": "{...}"}
  ],
  "tests": {"command": "pnpm test", "expect": {"passed": true}}
}
```

### 4.2 Review Card Schema

```json
{
  "kind": "logic_review",
  "risks": [{"id":"r1","sev":"high","msg":"null deref"}],
  "suggestions": ["add guard"],
  "approval": false
}
```

---

## 5) GitHub Conversations Playbook

* Webhooks: issues, PRs, review comments → Event bus
* Label-to-agent map: `ai:security` → SecurityBot; `ai:lint` → LintBot
* Commands: `/route low|med|high`, `/budget 1.50`, `/fallback codex>gemini>claude`
* Digest bot: nightly summary → subscribers
* Privacy: blocklist files; redact diffs in public repos

---

## 6) Review Chains (Escalation-Integrated)

### 6.1 Chains

* **Chain A (low-risk)**: Cursor → Codex review → **merge on green**
* **Chain B (medium)**: Codex → Gemini logic review → Claude final edit
* **Chain C (high)**: Claude implement → Gemini adversarial check → **Human gate**

### 6.2 Risk Score & Tiering

Create `.aiops/policy.yaml`:

```yaml
version: 1
risk:
  weights:
    patch_lines_norm: 0.20
    critical_files: 0.25      # touches auth/**, payments/**, migrations/**, secrets/**
    coverage_drop: 0.15
    static_sev: 0.20
    self_conf_neg: 0.10
    changed_endpoints: 0.10
  thresholds:
    low: 0.25
    high: 0.60
caps:
  token_buckets:
    cursor:  {capacity: 200000, refill_per_min: 40000}
    codex:   {capacity: 250000, refill_per_min: 50000}
    gemini:  {capacity: 250000, refill_per_min: 50000}
    claude:  {capacity: 150000, refill_per_min: 30000}
  breaker:
    error_burst: 3
    p95_latency_ms: 120000
budget:
  default_max_usd: 2.50
  early_exit_when_green: true
attention:
  subscribe:
    LintBot:     {labels: ["ai:lint"], globs: ["**/*.ts","**/*.js"], min_risk: 0.0}
    SecurityBot: {labels: ["ai:security"], globs: ["**/*"], min_risk: 0.4}
    DocsBot:     {labels: ["ai:docs"], globs: ["**/*.md"], min_risk: 0.0}
```

### 6.3 Escalation / De-escalation Rules

* **Escalate A→B** on: (a) tests fail twice; (b) static analyzer HIGH/CRIT; (c) `risk ≥ 0.25`; (d) implementer confidence < 0.65; (e) current agent circuit **open**.
* **Escalate B→C** on: (a) unresolved HIGH after one amend; (b) `risk > 0.60`; (c) patch churn > 2 rounds; (d) Codex/Gemini capped.
* **Early exit**: merge at current chain when tests+lint green **and** no HIGH risks **and** budget < 70% of task max.
* **Micro-speculative scan (optional)**: run Gemini logic/static scan in parallel with Chain A; preempt to B if it flags HIGH before A completes.

### 6.4 Cap/Budget Guards (Decision Table)

| Condition               | Action                                                                    |
| ----------------------- | ------------------------------------------------------------------------- |
| risk=low & caps OK      | Run **Chain A**                                                           |
| risk=low & A near cap   | **A’**: Chain A without micro-spec; or short queue                        |
| risk=med & tight budget | **A→B-lite**: A implement + Gemini review only                            |
| risk=high               | **Chain C**; if Claude capped → **C’**: Gemini implement + **Human gate** |

### 6.5 Cost & Latency Model

Let `Ca/La` = cost/latency for Chain A, `Rb/Lb` = B review, `Cc/Lc` = C implement; `p_ab`, `p_bc` are escalation probabilities.

* **Expected cost**: `E[C] = Ca + p_ab*Rb + p_ab*p_bc*Cc`
* **Expected latency (seq)**: `E[L] ≈ La + p_ab*Lb + p_ab*p_bc*Lc`
  Tune to reduce `p_ab` via better preflight and accurate risk scoring.

---

## 7) Policy & Security

* Prompt-injection sanitizer: strip tool-escape sequences; deny `!include` in manifests
* SBOM & license gates via CI job
* Secrets scanner on diffs; quarantine on hit

---

## 8) Metrics & SLOs

* Lead time (task→merge), Change failure rate, MTTR
* **% PRs resolved at Chain A (≥70%)**, **Post-merge defect rate (≤2%)**
* **Avg cost per merged PR**, **token burn per PR**
* **Cap-related retries/week**, **breaker open time**
* Attention efficiency: % messages consumed vs directed

---

## 9) Ready-to-Use Snippets

* GitHub Actions matrix for agents
* Example fallback policy (HCL-ish)
* Attention gate regex samples

---

## 10) GitHub Router Pack

### 10.1 Labels & Commands

Create labels: `ai:low`, `ai:med`, `ai:high`, `ai:security`, `ai:lint`, `ai:docs`, `ai:budget:$`.
Commands (issue/PR comments): `/route low|med|high`, `/budget <dollars>`, `/escalate`, `/halt`.

### 10.2 Actions Workflow (ai-router.yml)

```yaml
name: AI Router
on:
  pull_request:
    types: [opened, synchronize, labeled]
  issue_comment:
    types: [created]
  workflow_dispatch: {}
permissions:
  contents: write
  pull-requests: write
  issues: write
jobs:
  route:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: {node-version: 20}
      - name: Install deps
        run: npm ci || npm i
      - name: Parse policy & score risk
        id: score
        run: node scripts/ai/risk.js --policy .aiops/policy.yaml --pr ${{ github.event.pull_request.number || 0 }}
        env: { GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }} }
      - name: Decide chain
        id: decide
        run: node scripts/ai/router.js decide --policy .aiops/policy.yaml --event $GITHUB_EVENT_PATH
        env: { GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }} }
      - name: Chain A implement (Cursor)
        if: steps.decide.outputs.chain == 'A'
        run: |
          npx ai-cli cursor implement --out patch.json
          node scripts/ci/apply-patch.js patch.json
          npm test --silent
      - name: Gemini scan (micro-spec)
        if: steps.decide.outputs.micro_spec == 'true'
        run: npx ai-cli gemini review --in patch.json --out review.json || true
      - name: Escalate to B
        if: failure() || steps.decide.outputs.chain == 'B'
        run: |
          npx ai-cli gemini review --in patch.json --out review.json
          node scripts/ci/apply-suggestions.js review.json
          npm test --silent
      - name: Escalate to C
        if: failure() || steps.decide.outputs.chain == 'C'
        run: |
          npx ai-cli claude implement --out patch2.json
          node scripts/ci/apply-patch.js patch2.json
          npm test --silent
      - name: Require human gate on C
        if: steps.decide.outputs.chain == 'C'
        run: node scripts/ci/request-human-gate.js
```

### 10.3 Minimal Scorers/Router (TypeScript stubs)

**scripts/ai/risk.ts** (stub for real signals)

```ts
import fs from 'node:fs';
import { Octokit } from 'octokit';
import yaml from 'js-yaml';

function normLines(lines: number){ return Math.min(1, lines/400); }
function repoCtx(){ const [owner, repo] = (process.env.GITHUB_REPOSITORY||'').split('/'); return { owner, repo }; }

export async function scoreRisk(prNumber: number, policyPath: string){
  const policy = yaml.load(fs.readFileSync(policyPath, 'utf8')) as any;
  const gh = new Octokit({ auth: process.env.GITHUB_TOKEN });
  const { data: files } = await gh.rest.pulls.listFiles({ ...repoCtx(), pull_number: prNumber, per_page: 300 });
  const lines = files.reduce((a,f)=> a + (f.additions||0) + (f.deletions||0), 0);
  const critical = files.some(f => /^(auth|payments|migrations|secrets)\//.test(f.filename));
  const w = policy.risk.weights;
  const feats = { patch_lines_norm: normLines(lines), critical_files: +critical, coverage_drop: 0, static_sev: 0, self_conf_neg: 0.35, changed_endpoints: 0 };
  const score = Object.entries(feats).reduce((s,[k,v]) => s + (w[k]||0)*Number(v), 0);
  console.log(JSON.stringify({ score, feats }));
}
```

**scripts/ai/router.ts** (stub logic)

```ts
import fs from 'node:fs';
import yaml from 'js-yaml';

export function decide(policyPath: string, riskScore: number, caps: Record<string,boolean>, budgetLeft: number){
  const p = yaml.load(fs.readFileSync(policyPath,'utf8')) as any;
  const low = p.risk.thresholds.low, high = p.risk.thresholds.high;
  const microSpec = riskScore >= low && riskScore < high && caps.gemini;
  if (riskScore < low && caps.cursor) return { chain:'A', micro_spec: microSpec };
  if (riskScore <= high && caps.codex && caps.gemini) return { chain:'B', micro_spec: microSpec };
  if (caps.claude) return { chain:'C', micro_spec:false };
  return { chain:'C', micro_spec:false };
}
```

---

## 11) Ops & KPIs (Quick Reference)

* % PRs resolved at Chain A (goal ≥70%)
* Post-merge defect rate (≤2%)
* Avg cost per merged PR; token burn per PR
* Cap-related retries/week; breaker open time
* p95 latency; rework rate

---

## 12) Notes

* Replace `npx ai-cli ...` with actual Claude/Cursor/Codex/Gemini commands.
* Wire coverage/static-sev from CI artifacts; remove stubbed zeros.
* Keep provider keys in repo/environment secrets; never echo in logs.
* This edition **supersedes** the separate “Task Escalation Playbook & Cost Model” doc for day-to-day use.
