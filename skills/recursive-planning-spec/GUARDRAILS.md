# Guardrails (Sycophancy Avoidance & Decision Hygiene)

These guardrails prevent premature “looks good” assertions and force honest, verifiable planning. Use them **every pass** before emitting deltas or declaring completeness.

---

## 1) Verify-First Chaining (first principles)
**Goal:** Stress-test the premise and current plan before building more.

**Procedure**
1. Independently list **3 first-principles flaws or risks** in the current plan.
2. If any remain unresolved → convert each into an **OpenQuestion** (owner, due, impact) and **block** affected nodes.
3. Only proceed with expansion if all critical items are resolved or consciously deferred with a Risk owner/date.

**Output shape**
```json
{
  "guardrails": {
    "verify_first": {
      "risks": [
        "Auth refresh undefined for mobile; IX lacks token_state clusters",
        "No retention on media variants; Data contract incomplete",
        "Missing rollback steps for posts v2"
      ],
      "converted_to_open_questions": ["q:auth-refresh-mobile","q:media-retention","q:rollback-posts-v2"]
    }
  }
}
```

---

## 2) Rude Persona Prompting (no-BS critique)
**Goal:** Surface obvious breakages fast.

**Prompt** (always add a 2-line blunt critique):
> *What breaks? What’s missing?*

**Examples**
- “Your API plan ignores rate limits; 429s will cascade. Define bucket & retry policy.”
- “Data contract has no retention; legal & storage costs will bite. Add retention + purge job.”

---

## 3) Adversarial Critique Pairing (proposer vs critic)
**Goal:** Avoid single-track optimism.

**Steps**
- **Agent A (Proposer):** Generate deltas.
- **Agent B (Critic):** Attack them—“Where’s the lie?” Flag anything that breaks downstream completeness (e.g., tests, observability, migrations).
- **Merge:** Only deltas with resolved critiques survive; unresolved are turned into **OpenQuestions** and block scheduling.

**Output hint**
```json
{
  "guardrails": {
    "adversarial": {
      "critic_flags": ["Missing E2E tests for compose offline", "No dashboard/alerts for upload latency"],
      "merged": ["add test:e2e-compose-offline","add dashboard:upload-latency"],
      "deferred_as_open_questions": ["q:alerts-coverage"]
    }
  }
}
```

---

## 4) Abstention Calibration (penalize guessing)
**Rule:** If confidence < **80%** on any node, output `INSUFFICIENT`, emit targeted **OpenQuestions**, and **Block** the branch. Do not hallucinate specifics.

**Example**
```json
{"insufficient_for":"contract:data:media","needs":["indices","retention","region","migration"]}
```

---

## 5) Consortium Voting Ensemble (lightweight)
**Goal:** Handle uncertainty with explicit options and rationale.

**Procedure**
- List ≥2 design options with **pros/cons/risks**.
- Pick one; record the rationale in an **ADR** node; link `resolves` to disputed nodes.

**ADR example**
```json
{
  "id":"adr:media-variants-storage",
  "type":"ADR",
  "stmt":"Store media originals + 3 renditions in S3 with lifecycle rules",
  "options":["S3+CDN","Blob DB"],
  "chosen":"S3+CDN",
  "rationale":"Cheaper at scale; CDN hit ratio high; simple lifecycle",
  "status":"Ready"
}
```

---

## Auto-blocking rules (always-on)
- Any missing **Contract(API/Data)** field in required checklists → `record_unaccounted` and create **OpenQuestion**; keep parent `Blocked`.
- Any InteractionSpec missing **state**, **operation**, **error_model**, **observability**, or **security** → create **OpenQuestion**; keep parent `Blocked`.
- Any Scenario missing **unit+integration+E2E** tests → Scenario `Blocked`.
- Any leaf without **owner + estimate** → not eligible for scheduling.

---

## Critical language to avoid
- “Looks good”, “probably fine”, “seems covered”, “we can add later” → **Disallowed**. Replace with either:
  - A concrete delta that resolves the issue, **or**
  - `OpenQuestion` with owner/due and explicit blocking edges.

---

## Guardrail outputs to include with each pass
Append a compact `guardrails` section to your pass output:
```json
{
  "guardrails": {
    "verify_first": {"risks":[ "...", "...", "..." ]},
    "rude_persona": {"critique": "Two lines: what breaks, what's missing"},
    "adversarial": {"critic_flags":[ "..."], "merged":[ "..."], "deferred_as_open_questions":[ "..."]},
    "abstention": {"insufficient_for":[ "contract:data:media" ]},
    "ensemble": {"adr_created":[ "adr:media-variants-storage" ]}
  }
}
```

---

## Run order (integrate with the main loop)
1) Run **Verify-First** and **Rude Persona**.  
2) Propose deltas.  
3) Run **Adversarial Critique**; merge or open questions.  
4) Apply **Abstention** (INSUFFICIENT → OpenQuestions).  
5) If uncertainty remains, apply **Ensemble** and write an ADR.  
6) Only then recompute proofs (P1–P9) and emit the pass output.
