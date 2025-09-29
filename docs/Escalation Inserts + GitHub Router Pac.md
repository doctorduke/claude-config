# Escalation Inserts + GitHub Router Pack

This pack does two things you asked for:

1. **Drop-in replacements** to enhance the *Review Chains* section of your **Agent Orchestration Forensic Workbook** with escalation triggers, early exits, and cap/budget guards.
2. **GitHub wiring** (labels/commands + Actions workflow + tiny router code) to enforce the policy in CI.

---

## A) Drop-in Inserts for the Workbook (Section 6 – Review Chains)

### A.1 Risk Score & Tiering (add to §6 preamble)

```yaml
# .aiops/policy.yaml (checked into repo)
version: 1
risk:
  weights:
    patch_lines_norm: 0.20    # min(1, lines_changed/400)
    critical_files: 0.25      # 1 if touches auth/**, payments/**, migrations/**, secrets/**
    coverage_drop: 0.15       # min(1, max(0, (cov_before - cov_after)/10))
    static_sev: 0.20          # normalized HIGH/CRIT findings
    self_conf_neg: 0.10       # 1 - model_confidence (0..1)
    changed_endpoints: 0.10   # min(1, api_changes/5)
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

### A.2 Escalation/De-escalation Rules (append to §6)

* **Escalate A→B** if any: tests fail twice, static analyzer HIGH/CRIT, `risk ≥ 0.25`, implementer confidence < 0.65, or current agent circuit is **open**.
* **Escalate B→C** if any: unresolved HIGH risks after one amend, `risk > 0.60`, patch churn > 2 rounds, or Codex/Gemini capped.
* **Early exit**: merge at current chain when tests+lint green **and** no HIGH risks **and** budget < 70% of task max.
* **Micro-speculative scan (optional)**: run Gemini logic/static scan in parallel with Chain A; preempt to B if it flags HIGH before A completes.

### A.3 Cap/Budget Guards (add as a sub-bullet under each chain)

* Before invoking the next hop, check `token_buckets[agent] ≥ stage_min_tokens` and `breaker` health. If not, skip/defer or use alternative per the decision table:

| Condition               | Action                                                                    |
| ----------------------- | ------------------------------------------------------------------------- |
| risk=low & A caps OK    | **Run Chain A**                                                           |
| risk=low & A near cap   | **A’**: run Chain A but *without* micro-spec; or short queue              |
| risk=med & tight budget | **A→B-lite**: A implement + Gemini review only                            |
| risk=high               | **Chain C**; if Claude capped → **C’**: Gemini implement + **Human gate** |

---

## B) GitHub Wiring (labels, commands, Actions, router)

### B.1 Labels & Commands

Create repo labels:

* `ai:low`, `ai:med`, `ai:high` — optional manual override.
* `ai:security`, `ai:lint`, `ai:docs` — subscription cues.
* `ai:budget:$` — e.g., `ai:budget:2.50`.

Supported issue/PR comment commands (handled by workflow):

* `/route low|med|high` — set target tier and (re)run router.
* `/budget <dollars>` — set per-PR budget ceiling.
* `/escalate` — force next tier.
* `/halt` — stop automation on the PR.

### B.2 Actions Workflow

Create **.github/workflows/ai-router.yml**

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
        run: |
          npm ci || npm i
      - name: Parse policy & score risk
        id: score
        run: node scripts/ai/risk.js --policy .aiops/policy.yaml --pr ${{ github.event.pull_request.number || 0 }}
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      - name: Decide chain
        id: decide
        run: node scripts/ai/router.js decide --policy .aiops/policy.yaml --event $GITHUB_EVENT_PATH
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
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

> The `npx ai-cli ...` commands are placeholders for your actual per-agent CLIs.

### B.3 Router & Risk Scripts (minimal, Node/TS)

**scripts/ai/risk.ts**

```ts
import fs from 'node:fs';
import { Octokit } from 'octokit';
import yaml from 'js-yaml';

function normLines(lines: number){ return Math.min(1, lines/400); }

export async function scoreRisk(prNumber: number, policyPath: string){
  const policy = yaml.load(fs.readFileSync(policyPath, 'utf8')) as any;
  const gh = new Octokit({ auth: process.env.GITHUB_TOKEN });
  const { data: pr } = await gh.rest.pulls.get({ ...repoCtx(), pull_number: prNumber });
  const { data: files } = await gh.rest.pulls.listFiles({ ...repoCtx(), pull_number: prNumber, per_page: 300 });

  const lines = files.reduce((a,f)=> a + (f.additions||0) + (f.deletions||0), 0);
  const critical = files.some(f => /^(auth|payments|migrations|secrets)\//.test(f.filename));
  const weights = policy.risk.weights;

  // TODO: wire real coverage/static/severity/self_conf/api_changes
  const features = {
    patch_lines_norm: normLines(lines),
    critical_files: critical ? 1 : 0,
    coverage_drop: 0,
    static_sev: 0,
    self_conf_neg: 0.35,
    changed_endpoints: 0
  };

  const score = Object.entries(features).reduce((s,[k,v]) => s + (weights[k]||0)*Number(v), 0);
  return { score, features };
}

function repoCtx(){
  const [owner, repo] = (process.env.GITHUB_REPOSITORY||'').split('/');
  return { owner, repo };
}

if (require.main === module){
  const pr = Number(process.argv.at(-1));
  scoreRisk(pr, process.argv[3]).then(r => {
    console.log(JSON.stringify(r));
  });
}
```

**scripts/ai/router.ts**

```ts
import fs from 'node:fs';
import yaml from 'js-yaml';

export function decide(policyPath: string, riskScore: number, caps: Record<string,boolean>, budgetLeft: number){
  const p = yaml.load(fs.readFileSync(policyPath,'utf8')) as any;
  const low = p.risk.thresholds.low, high = p.risk.thresholds.high;

  const nearBudget = budgetLeft < (p.budget.default_max_usd * 0.3);
  const microSpec = riskScore >= low && riskScore < high && caps.gemini;

  if (riskScore < low && caps.cursor) return { chain:'A', micro_spec: microSpec };
  if (riskScore <= high && caps.codex && caps.gemini) return { chain:'B', micro_spec: microSpec };
  if (caps.claude) return { chain:'C', micro_spec:false };
  return { chain:'C', micro_spec:false }; // C-prime handled by workflow
}

if (require.main === module){
  const out = decide(process.argv[3], Number(process.env.RISK||0.3), {cursor:true,codex:true,gemini:true,claude:true}, Number(process.env.BUDGET_LEFT||2.5));
  console.log(`::set-output name=chain::${out.chain}`);
  console.log(`::set-output name=micro_spec::${out.micro_spec}`);
}
```

### B.4 Slash Commands (issue_comment handler)

You can keep it inside the same workflow by parsing `github.event.comment.body` in `router.js` to:

* set `labels` and write a small state file `.aiops/state/<pr>.json` storing `budget`, `forced_tier`, `halted`.

### B.5 Attention Gating

Add a tiny filter in your bots to only fetch thread content when:

* the PR has a subscribed label for that bot, **or**
* the bot is explicitly `@mentioned`, **or**
* the risk score exceeds the bot’s `min_risk`.

---

## C) Ops & KPIs (attach to Workbook §8)

* **% PRs resolved at Chain A** (goal ≥70%)
* **Post-merge defect rate** (≤2%)
* **Avg cost per merged PR** and **token burn per PR**
* **Cap-related retries/week** and **breaker open time**

---

## D) Notes

* Replace `npx ai-cli ...` with your actual Claude/Cursor/Codex/Gemini commands.
* Wire real coverage and static severity into `risk.ts` (from your CI artifacts).
* Use repo/environment secrets for provider API keys; never echo secrets in logs.
