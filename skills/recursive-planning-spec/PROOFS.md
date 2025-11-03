# Completion Proofs (CPP)

This file defines the **thirteen proofs** required before a plan may be declared complete. The agent must compute and emit these values in the `proofs` block of every pass. If any proof is `false` (or any matrix shows gaps), the plan is **not complete**.

**Core Proofs (P1-P9)**: Backend and infrastructure completeness
**UI-Specific Proofs (P2-Client, P6-UX, P11-Design, P13-A11y/i18n)**: Client-side and UI/UX completeness

---

## Output schema (embed this in your pass output)
```json
{
  "proofs": {
    "P1": true, "P2": true, "P3": true, "P4": true, "P5": true,
    "P6": true, "P7": true, "P8": true, "P9": true,
    "P2-Client": true, "P6-UX": true, "P10": true, "P11": true,
    "P11-Design": true, "P12": true, "P13-A11y": true,
    "all_passed": true,
    "details": {
      "p1_topology": { "missing": [] },
      "p2_coverage": [
        {
          "scenario": "scenario:<slug>",
          "expected_ix": 0,
          "realized_ix": 0,
          "gaps": 0,
          "by_interface": {
            "S3": { "PutObject": {"clusters": 0, "realized": 0, "missing_clusters": []} }
          }
        }
      ],
      "p2_client_coverage": {
        "total_user_facing_scenarios": 0,
        "scenarios_with_ui_nodes": 0,
        "scenarios_with_exclusions": 0,
        "coverage_percent": 0.0,
        "missing": []
      },
      "p3_data_lifecycle": { "violations": [] },
      "p4_security": { "violations": [] },
      "p5_tests": { "missing": [] },
      "p6_observability": { "missing": [] },
      "p6_ux_completeness": {
        "total_uxflows": 0,
        "complete_uxflows": 0,
        "completeness_percent": 0.0,
        "missing_variants": []
      },
      "p7_rollout": { "violations": [] },
      "p8_ordering": { "blocked_leaves": [] },
      "p9_expansion": { "nonterminals_total": 0, "nonterminals_complete": 0, "expansion_coverage": 0.0, "unexpanded_nodes": [] },
      "p11_design_compliance": {
        "total_ui_components": 0,
        "components_using_tokens": 0,
        "compliance_percent": 0.0,
        "violations": []
      },
      "p13_a11y_i18n": {
        "total_ui_nodes": 0,
        "nodes_with_a11y": 0,
        "nodes_with_i18n": 0,
        "a11y_percent": 0.0,
        "i18n_percent": 0.0,
        "violations": []
      }
    }
  }
}
```

> Convention: a proof is `true` **only if** the corresponding `details` show **no** missing/violations/gaps.

---

## P1 — Topology Proof
**Goal:** Ensure core subsystems exist and are `Ready`.

**Required Ready node categories**
- Client/UI
- API Gateway
- Domain Services
- Data Stores (OLTP/OLAP as applicable)
- Caches/CDN
- Queues/Workers
- Auth/Identity
- Secrets/Key Management
- Moderation/Policy (if applicable)
- Observability (logs, metrics, tracing, dashboards, alerts)
- Analytics/Events
- Config/Flags
- Migrations/Backfills
- Rollout

**Check:** For each category, there is ≥1 node with `status="Ready"`. List any missing categories in `details.p1_topology.missing`.

---

## P2 — Scenario × Interface × State Coverage Matrix
**Goal:** Prove that every Scenario has InteractionSpecs for all interface/operation × state-cluster behaviors.

**Definitions**
- **Interfaces & operations**: concrete dependencies (e.g., S3 `PutObject`, SQL `INSERT posts`, Auth `POST /refresh`).  
- **State clusters**: MECE partitions of influencers that change control-flow or outcomes (e.g., `{token:fresh|expired, quota:under|over, cache:hit|miss, region:us|eu}`).

**Expected interactions per scenario**
```
expected_ix = Σ_over_interfaces Σ_over_operations (number_of_state_clusters_that_change_behavior)
```
**Realized interactions**
```
realized_ix = count(InteractionSpec where traces_to == scenario AND has specific interface, operation and state_cluster)
```
**Requirement:** `expected_ix == realized_ix` for every Scenario; `gaps = expected_ix - realized_ix` must be `0`.

**Report shape (per scenario)**
```json
{
  "scenario": "scenario:<slug>",
  "expected_ix": 3,
  "realized_ix": 3,
  "gaps": 0,
  "by_interface": {
    "S3": { "PutObject": {"clusters": 2, "realized": 2, "missing_clusters": []} },
    "Auth": { "POST /refresh": {"clusters": 1, "realized": 1, "missing_clusters": []} }
  }
}
```

---

## P3 — Data Lifecycle Proof
**Goal:** Ensure each data contract models lifecycle and governance.

**Per Data Contract checks**
- **Schema** (tables/columns/types)
- **Indices** (including unique constraints, hot keys considered)
- **CRUD** coverage
- **Retention** policy (ttl, legal holds)
- **PII** flags & fields
- **Region** (primary/DR, residency constraints)
- **Backup/Restore** plan
- **Migration/Backfill** plan
- **Tests** (apply/rollback/backfill)

**All items must be present** or the contract is a violation.

---

## P4 — Security/AuthZ Proof
**Goal:** Verify least-privilege and access controls across the plan.

**Checks**
- AuthN flows and token lifecycle
- AuthZ scopes/roles for every sensitive path
- Least-privilege policies for each InteractionSpec
- Secrets handling (storage/rotation)
- Web security (CORS/CSRF)
- Rate limits/quotas on endpoints/operations
- Compliance hooks if applicable

List any missing items per node under `details.p4_security.violations`.

---

## P5 — Test Proof
**Goal:** Ensure verifiability before work starts.

**Per Scenario**
- Unit + Integration + E2E tests with fixtures
- Acceptance in Given/When/Then form

**Per InteractionSpec**
- Mocks/fakes for dependencies
- Acceptance checks in Given/When/Then

Report any missing tests under `details.p5_tests.missing`.

---

## P6 — Observability Proof
**Goal:** Ensure visibility and SLO enforcement.

**Per component and InteractionSpec**
- Logs (start/done/error)
- Metrics (latency_ms, error_rate, retries, queue_depth, hit_ratio, etc.)
- Trace spans (named consistently)
- Dashboards and **alerts** tied to SLOs
- Rollout metrics (flag uptake, canary deltas)

Missing items go to `details.p6_observability.missing`.

---

## P7 — Rollout & Versioning Proof
**Goal:** Prevent breaking consumers; enable safe deploys.

**Checks**
- Contract **semver** declared; breaking changes require **migration specs**
- Migrations/backfills scheduled **before** consumers
- Feature flags, canary, **kill switch**
- Rollback procedure

Violations listed under `details.p7_rollout.violations`.

---

## P8 — Ordering & Gate Proof
**Goal:** Only Ready leaves are scheduled; DAG is valid.

**Checks**
- No cycles; topological order exists
- **Work-Start Gate** satisfied for every scheduled leaf:  
  `OpenQuestions=0 ∧ upstream Contracts Ready ∧ migrations scheduled ∧ acceptance checks defined ∧ owner+estimate set ∧ rollout flag set (if applicable)`
- No `Blocked` leaves appear in `task_order`

Report `blocked_leaves` if any.

---

## P9 — Node Expansion Proof
**Goal:** No partially expanded subtrees remain.

**Compute**
- `nonterminals_total` = count(nodes NOT in {InteractionSpec, ChangeSpec(simple=true)})
- `nonterminals_complete` = count(nonterminals with all required children present and passing checklists)
- `expansion_coverage = nonterminals_complete / nonterminals_total`

**Requirement:** `expansion_coverage == 1.00` and `unexpanded_nodes` is empty.

**Report**
```json
{"nonterminals_total":42,"nonterminals_complete":42,"expansion_coverage":1.0,"unexpanded_nodes":[]}
```

---

## P2-Client — Client Lane Coverage Matrix
**Goal:** Ensure all user-facing scenarios have corresponding UI nodes or documented exclusions.

**Checks**
- For every user-facing Scenario (or backend node with `user_facing=true`):
  - **EITHER** has ≥1 of: Screen, UXFlow, UIComponentContract
  - **OR** has explicit `Exclusion(UI)` with owner + rationale
- Coverage matrix for Client lane: `Entity × Screen × StateCluster(role, network, feature_flag, permission, offline, empty, error_type)`

**Threshold:** ≥95% of user-facing scenarios have UI coverage or documented exclusions.

**Report shape**
```json
{
  "total_user_facing_scenarios": 100,
  "scenarios_with_ui_nodes": 95,
  "scenarios_with_exclusions": 4,
  "coverage_percent": 99.0,
  "missing": ["scenario:advanced-admin-only"]
}
```

---

## P6-UX — UXFlow Completeness
**Goal:** Verify all UXFlows have complete state variants and accessibility/i18n checks.

**Per UXFlow checks**
- **States**: Loading, Empty, Error, Ready variants present
- **Tests**: E2E tests for all states
- **A11y**: Keyboard navigation, ARIA labels, color contrast verified
- **i18n**: Copy keys present (no hardcoded strings), RTL support validated

**Threshold:** ≥90% of UXFlows have all variants + tests + a11y/i18n checks.

**Report shape**
```json
{
  "total_uxflows": 50,
  "complete_uxflows": 47,
  "completeness_percent": 94.0,
  "missing_variants": [
    {"uxflow": "ux:item-list", "missing": ["empty_state"]}
  ]
}
```

---

## P10 — Core Blueprint Coverage
**Goal:** Ensure architecture patterns, data flows, and error strategies are documented.

**Checks**
- For complex features (≥5 scenarios or cross-service), require dedicated Architecture nodes:
  - `arch:data-flow:<slug>` - End-to-end data flow
  - `arch:error-strategy:<slug>` - Circuit breakers, fallbacks, compensation
  - `arch:business-logic:<slug>` - State machines, workflows, algorithms
- Integration patterns documented for cross-feature dependencies

**Threshold:** All complex features have architecture documentation.

---

## P11 — Incident Readiness
**Goal:** Verify runbooks, alerts, and rollback procedures are defined.

**Checks**
- Runbooks for critical paths
- Alerts tied to SLO violations
- Rollback procedures for each deployment
- On-call rotation defined

**Threshold:** All critical paths have incident readiness artifacts.

---

## P11-Design — Design System Compliance
**Goal:** Ensure all UI components reference design tokens (no raw CSS values).

**Checks**
- `StyleGuide`, `DesignTokens`, `ComponentLibrary` nodes exist and are Ready
- All `UIComponentContract` and `VisualSpec` nodes reference design tokens
- Raw CSS values (colors, sizes, fonts) forbidden unless justified in `node.evidence`
- Design token usage lint enforced

**Threshold:** ≥95% of UI components reference tokens.

**Report shape**
```json
{
  "total_ui_components": 70,
  "components_using_tokens": 68,
  "compliance_percent": 97.1,
  "violations": [
    {"component": "ui-component:legacy-form", "raw_values": ["#FF0000", "16px"]}
  ]
}
```

---

## P12 — Compliance
**Goal:** Address GDPR/CCPA/HIPAA requirements if applicable.

**Checks**
- Data processing agreements documented
- PII handling policies defined
- User consent flows implemented
- Data export/deletion capabilities present
- Audit trails for sensitive operations

**Threshold:** All applicable compliance requirements addressed.

---

## P13-A11y/i18n — Accessibility & Internationalization
**Goal:** Verify WCAG 2.1 AA compliance and internationalization support for all UI nodes.

**Per UI node checks**
- **A11y**:
  - Keyboard navigation support (focus order, shortcuts)
  - Screen reader labels (ARIA attributes)
  - Color contrast meets WCAG AA (4.5:1 for text, 3:1 for UI)
  - Focus indicators visible
  - Reduced motion support
- **i18n**:
  - All copy uses i18n keys (no hardcoded strings)
  - Pluralization rules defined
  - RTL layout validated
  - Date/number formatting localized

**Threshold:** ≥95% of UI nodes pass a11y/i18n checks.

**Report shape**
```json
{
  "total_ui_nodes": 200,
  "nodes_with_a11y": 195,
  "nodes_with_i18n": 198,
  "a11y_percent": 97.5,
  "i18n_percent": 99.0,
  "violations": [
    {"node": "ui-component:quick-action", "issue": "missing_keyboard_shortcut"},
    {"node": "screen:admin-panel", "issue": "hardcoded_string"}
  ]
}
```

---

## Additional UI Completeness Score Components

Beyond the core proofs, track these UI-specific metrics:

- **% Screens with NavigationSpec**: All Screen nodes have corresponding NavigationSpec
- **% UIComponentContracts with validation + tests**: Forms have client/server validation + tests
- **% UXFlows with tutorial decision**: Tutorial present OR intentional no-tutorial documented
- **% Notifications with preference link**: All NotificationSpec nodes link to SettingsSpec opt-out
- **% components referencing tokens**: Target 100% design token usage

---

## Failing the plan
If any proof is `false` or any matrix shows gaps, the agent **must not** declare completion. It should emit:
- The `proofs` block (with details and gaps),
- The minimal `deltas` to add missing nodes (or **OpenQuestions** where info is unknown),
- A refreshed `task_order` that schedules only leaves passing the Work-Start Gate.

This prevents premature “done,” forces complete recursion, and avoids duplicated documentation by referencing node IDs and emitting only changed shards.
