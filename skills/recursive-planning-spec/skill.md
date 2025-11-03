---
name: recursive-planning-spec
description: Recursively decompose a feature into a complete PlanGraph (Intent→…→InteractionSpec) using Nonterminal Expansion and P1–P13 Completion Proofs. Emit delta-only outputs (manifest + deltas + changed nodes), deterministic task order, no code generation. Designed to converge to 100% without guessing. Includes systematic UI expansion for all user-facing nodes (Screen, NavigationSpec, UIComponentContract, SettingsSpec, TutorialSpec, NotificationSpec, BadgeRule, VisualSpec).
---

# Recursive Planning Spec (Skill)

## What this Skill does
- Builds/updates a **PlanGraph** until every branch reaches **InteractionSpecs** (method × interface × operation × state cluster).
- Enforces **Nonterminal Expansion**: a parent cannot be `Ready` until all required child types exist and pass checklists.
- **Systematically projects UI implications** for all user-facing nodes via the UI Implications Questionnaire, generating Screen, NavigationSpec, UIComponentContract, SettingsSpec, TutorialSpec, NotificationSpec, BadgeRule, and VisualSpec nodes.
- Produces **delta-only** outputs in small shards (manifest, deltas, changed nodes) to fit tight context budgets.
- Blocks guessing with **OpenQuestion**; requires **P1–P13 Completion Proofs** before declaring "done."
- Keeps documentation DRY by referencing node IDs instead of inlining large bodies.
- **Plans for depth, not just breadth**: Captures end-to-end flows, architecture patterns, business logic, cross-cutting concerns, and complete UI/UX alongside individual operations.

## When to use
- Any planning pass that must recurse to terminal leaves and *prove* completeness.
- When previous plans looked "big" but contained stubs, guesses, or missing tests/observability.
- When UI/UX planning needs to be systematic and comprehensive, not ad-hoc.

## Inputs and Outputs (per pass)

**Input JSON**
```json
{
  "feature_id": "feat:<slug>",
  "intent": "<one sentence>",
  "prior_plan_version": "vN",
  "knobs": {
    "budgets": {"pass_kb": 8, "node_kb": 3, "max_interactions_per_pass": 40},
    "weights": {"trace":0.25,"ix_cov":0.25,"check":0.20,"risk":0.15,"closure":0.15},
    "lanes": ["Client","API","Worker","Data","Policy","Observability","QA","Migrations","Design"],
    "semver": {"contracts_default":"minor","breaking_requires":"migration_spec"},
    "refactor_caps": {"max_refactors_per_pass": 3},
    "ui_expansion": {"enabled": true, "require_design_system": true}
  }
}
```

**Output JSON**
```json
{
  "plan_version": "v{K}",
  "deltas": [ /* delta ops only */ ],
  "task_order": [ /* ordered leaves with lanes & deps */ ],
  "top_gaps": [ /* unaccounted highlights */ ],
  "changed_nodes": [ /* ids */ ],
  "manifest": {
    "stats": {"nodes":0,"edges":0,"ready":0,"blocked":0,"ui_nodes":0},
    "hotset": {"changed": ["..."], "deferred": ["..."]}
  },
  "proofs": {
    "P1": true, "P2": true, "P3": true, "P4": true,
    "P5": true, "P6": true, "P7": true, "P8": true, "P9": true,
    "P10": true, "P11": true, "P12": true, "P13": true,
    "details": { /* matrices and lists */ }
  }
}
```

## Guardrails (Sycophancy Avoidance)
- **Verify-First Chaining**: list 3 first-principles risks; convert unresolved items to `OpenQuestion`; only then proceed.
- **Rude Persona Check**: add a blunt 2-line critique: "What breaks? What's missing?"
- **Adversarial Critique Pairing**: after proposing deltas, run a critic pass; merge only resolved items; unresolved → `OpenQuestion`.
- **Abstention Calibration**: if confidence <80% on any node, output `INSUFFICIENT` with targeted questions; block that branch.
- **Ensemble Note**: where designs diverge, list ≥2 options; pick one; record rationale in `node.evidence`.

## UI Projection Enforcement (Critical - Duke's Feedback)

**MANDATORY: These rules override all other planning rules when user-facing features are involved.**

### Trigger Detection (Non-Negotiable)
After each pass's deltas merge, run `project_ui_impacts()` over EVERY new/changed:
- `Contract(API|Event)` with `user_facing=true` **OR** `ui_impact=possible`
- `DataModel` with client-visible fields
- `Policy` affecting user features
- `ChangeSpec` **OR** `Scenario` with Client lane interactions

### UI Questionnaire (13 Required Questions)
For EVERY triggered node, ask and persist answers to `node.evidence.ui_answers`:

1. **Presence**: Is there UI at all? If **NO**, create `Policy:Exclusion-UI` with rationale+owner.
2. **Entry & context**: New screen? Where does it live? Navigation (route, params, back behavior)?
3. **Representation**: Individual item, collection, or both? Sorting/filtering/pagination?
4. **Interaction**: Create/edit/delete/duplicate/import/export/share? Batch? Undo? Validation (client/server)?
5. **Settings**: User/admin/device/tenant setting required? Defaults and migration?
6. **Tutorial**: Tutorial/coach-mark/empty-state needed? Triggers?
7. **Background updates**: Badges, in-app notifications, push/email? Read/unread semantics?
8. **A11y/i18n**: Keyboard/focus/aria/contrast, copy keys, RTL/truncation?
9. **Device/layout**: Web/iOS/Android/desktop; breakpoints; reduced motion?
10. **Privacy/compliance**: PII surfaced? Consent, masking, export restrictions?
11. **Analytics/experiments**: Tracking plan events, success metrics, variants?

### UI Projection (Automatic Node Creation)
Based on answers, ensure (create or link):
- `Screen` + `NavigationSpec` if new screen
- `UXFlow` (loading/empty/error) for ALL user-facing features
- `UIComponentContract` (list/detail/form) based on representation
- `SettingsSpec` when answers.needs_setting = YES
- `TutorialSpec` when answers.needs_tutorial = YES
- `NotificationSpec` + `BadgeRule` when answers.needs_notifications/badge = YES
- `AnalyticsSpec` with tracking events

Wire edges: backend **→ covered_by →** UI nodes; UI **→ depends_on →** backend.

### Quality Gates (Non-Negotiable - Block Until Satisfied)
A backend **leaf** is **UNSCHEDULABLE** until:

1. **UI Projection Gate**: Paired `UXFlow` + `UIComponentContract` exist OR `Policy:Exclusion-UI` with owner+rationale
2. **Navigation Symmetry Gate**: `NavigationSpec` exists if new/changed route implied
3. **Settings Gate**: If answers.needs_setting = YES → `SettingsSpec` must exist
4. **Tutorial Gate**: If answers.needs_tutorial = YES → `TutorialSpec` must exist
5. **Notification Gate**: If answers.needs_notifications = YES → `NotificationSpec` + opt-out preference must exist
6. **A11y/i18n Gate**: WCAG 2.2 checks pass, i18n keys exist or Exclusion with rationale/owner
7. **Design System Gate**: If `StyleGuide`/`DesignTokens`/`ComponentLibrary` missing → emit `OpenQuestion` and **BLOCK** all `VisualSpec` nodes as Ready. All `UIComponentContract` must reference tokens (no raw colors/sizing).
8. **Analytics Gate**: Tracking events defined or explicitly excluded

### Explainability (Mandatory Logging)
For EVERY skipped UI projection, add to `unaccounted[]` array:
```json
{
  "node_id": "...",
  "reason": "ui_impact=unknown | styleguide_missing | answers_incomplete",
  "owner": "...",
  "due": "YYYY-MM-DD",
  "blocker": true|false
}
```

### Determinism & Idempotency
- Re-running `project_ui_impacts()` with unchanged inputs MUST be no-op (hash stable)
- Sort IDs and edge ops lexicographically before emission
- Use consistent timestamps and UUIDs

### Per-Pass Checklist (Print After Each Pass)
- [ ] Did I run the UI questionnaire for every triggered node?
- [ ] For each "YES," did I create required nodes (Screen/Nav/UXFlow/Component/Settings/Tutorial/Notification)?
- [ ] Are paired UI artifacts present before marking backend leaves "Ready"?
- [ ] Do all UI components reference design tokens/components?
- [ ] Do A11y and i18n checks pass, or is there a blocking Exclusion with owner?
- [ ] Did I log reasons in `unaccounted[]` for anything I skipped?
- [ ] Are all 8 quality gates satisfied or blocking reasons documented?

## Recursion Loop (fixpoint)
1. **Frontier** := all nonterminals missing required children or failing checklists.
2. **Architecture-first**: Before expanding operations, plan end-to-end data flows, cross-service communication, and integration patterns.
3. Expand top-down: Intent → Capabilities → Scenarios → Requirements → Contracts(API/Data/Event/Policy) → Components → Operations/Algorithms → ChangeSpecs.
4. **Leaf forcing**: if a ChangeSpec touches ≥1 dependency or behavior varies by state, explode into **InteractionSpecs** (see `FORMS.md`).
5. **Plan depth**: For complex features, create dedicated architecture nodes (DataFlow, ErrorStrategy, BusinessLogic) before individual operations.
6. **UI Projection** (after backend nodes, before validation):
   - For each user-facing node (Contract, Event, DataModel, Policy, Scenario with UI impact), run **UI Implications Questionnaire**
   - Generate Screen, NavigationSpec, UIComponentContract, SettingsSpec, TutorialSpec, NotificationSpec, BadgeRule, VisualSpec nodes
   - Ensure **Design System foundation** (StyleGuide, DesignTokens, ComponentLibrary) exists; block if absent
   - Create **Client-side InteractionSpecs** with UI state clustering (network, theme, device, reduced_motion, permission, empty)
   - Invoke **UI Subagents** in parallel: UIPlanner, NavSmith, FormSmith, SettingsSmith, TeachBot, NotifyBot, DesignSync, A11yBot, CopyBot
7. Validate & gap: run checklists; write `unaccounted`; create **OpenQuestions** (owner+due); keep parent **Blocked**.
8. Back-propagate: induce missing Contracts/Policies/Algorithms; apply semver & migrations for breaking changes.
9. Detect **RefactorSpecs** conservatively (dup retry patterns; star-dependencies; policy gaps; polling → events), capped by `refactor_caps`.
10. Recompute DAG + lanes; recompute completeness; repeat until the frontier is empty.

## Nonterminal Expansion (required children by type)
- **Intent →** Capabilities **+ Architecture** (DataFlow, ErrorStrategy, BusinessLogic for complex features)
- **Capability →** Scenarios {happy, error, edge, permission} **+ Integration** (how it integrates with other capabilities)
- **Scenario(user-facing) →** Screen OR UIComponentContract OR Exclusion(UI) with rationale
- **Scenario(any) →** Requirements {Functional, Non-Functional: perf/a11y/security} + Test(acceptance) **+ EndToEndFlow** (user journey)
- **Requirement →** Contracts {API, Data, Event, Policy} **and** Components; link ≥1 ChangeSpec **+ CrossCutting** (caching, rate limiting)
- **Contract(API) →** endpoints, error taxonomy, idempotency, timeouts, rate limits, versioning, observability, Test(contract)
- **Contract(API/Event, user-facing) →** UXFlow {Loading, Empty, Error, Ready} + NavigationSpec (if new screen) + UIComponentContract + Analytics
- **Contract(Data) →** schema, indices, migration/backfill, retention, region/PII, Test(migration)
- **Component →** Operations/Algorithms **+ Integration** (how it integrates with other components)
- **Operation/Algorithm →** ≥1 **InteractionSpec** **+ ErrorHandling** (circuit breakers, fallbacks, compensation)
- **Screen →** NavigationSpec + UIComponentContract + VisualSpec + Test(E2E-UI)
- **UIComponentContract →** props/state_machine + validation + VisualSpec + Test(component)
- **SettingsSpec →** scope/defaults + Policy mapping + migration
- **TutorialSpec →** triggers + steps + completion
- **NotificationSpec →** channels + templates + throttling + BadgeRule + SettingsSpec(opt-out)
- **VisualSpec →** DesignTokens reference (no raw values)
- **UXFlow →** states {loading, ready, empty, error} + a11y + i18n + Test(E2E)
- **Risk →** mitigation(owner/date)
- **ChangeSpec(simple=false) →** lists its InteractionSpecs **+ Architecture** (data flow, error handling, business logic)

Unknowns → **OpenQuestion**; parent stays **Blocked**.

## InteractionSpec Granularity

### Backend InteractionSpecs
Create one per tuple **(method, interface, operation, state_cluster)**.
State clustering: enumerate influencers (auth_role, token_state, feature_flag, quota, cache hit/miss, data_version, region, network, idempotency, time_window, partial_failure). Keep only factors that change control-flow or externally observable outcomes. Cluster MECE; emit one InteractionSpec per interface×operation×cluster.

### Client-side InteractionSpecs (UI State Clustering)
Beyond backend state clustering, **Client-side InteractionSpecs** also cluster on:
- **network**: online/offline/slow
- **theme**: light/dark/high_contrast
- **device**: mobile/tablet/desktop (form factor, orientation, safe areas)
- **reduced_motion**: true/false
- **permission**: granted/denied/not_requested
- **empty**: true/false (for list/collection views)
- **feature_flag**: enabled/disabled (UI-specific flags)
- **auth_role**: user/admin/guest (UI access patterns)
- **error_type**: recoverable/terminal/partial

Emit one **InteractionSpec(Client)** per meaningful UI state cluster.

**Each InteractionSpec MUST include**: `pre`, `inputs`, `expected_effects`, `error_model` (retriable/non-retriable + compensation), `resilience` (timeout/retry/idempotency), `observability` (logs/metrics/span), `security` (authZ/least-priv/PII), `test` (mocks + Given/When/Then), `depends_on` (Contracts/Policies), `owner`, `est_h`, `status`.

For **Client InteractionSpecs**, also include: `a11y` (keyboard/screen reader/contrast), `i18n` (copy keys/pluralization/RTL), `analytics` (tracking events), `visual_spec_ref` (design tokens).

## UI Implications Questionnaire (Systematic)

For every user-facing node (Contract(API/Event), DataModel, Policy, Scenario with UI), answer:

**A. Discoverability** - Where/how users find this? Entry points? Role/flag gating?

**B. Representation** - Item or collection? List/grid/table? Detail view? Filters/sort?

**C. Interaction** - CRUD? Batch? Inline vs modal? Validation (client/server)?

**D. Navigation** - New screen? Push/modal/replace? Back behavior? Deep links?

**E. Settings** - New setting? Scope (user/tenant/device)? Defaults? Admin controls?

**F. Tutorial** - Guided flow needed? Triggers? Format (coach/checklist/sample)?

**G. Notifications** - Background updates? Badge? Push/email? Opt-out preference?

**H. Context** - Which screen? Cross-links? Contextual actions?

**I. States** - Loading/empty/error? Offline? Permission denied? Feature gated?

**J. A11y/i18n** - Keyboard nav? Screen reader? Color contrast? i18n keys? RTL?

**K. Device** - Web/iOS/Android? Breakpoints? Orientation? Safe areas?

**L. Privacy** - PII surfaced? Consent required? Redaction? Export controls?

**M. Analytics** - Tracking events? Experiment buckets? Success metrics?

Answers drive UI node generation. Missing answers → OpenQuestion.

**Quick mapping from backend changes → UI obligations**:

| Change type                      | Typical UI obligations                                                                                              |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| New **GET /items**               | `Screen:list`, `UIComponent:list`, `UXFlow:list` (loading/empty/error), filters/sort, analytics events              |
| New **POST /items**              | `Screen:create` or inline form, `UIComponentContract:form`, validation, success/error toasts, navigation on success |
| New **Event item.updated**       | `BadgeRule` for inbox/surface, optimistic updates, toasts, cache invalidation                                       |
| New **Policy scope/limit**       | Guarded `Screen`, "upgrade/paywall" UX, copy, analytics                                                             |
| New **Data field PII/sensitive** | Redaction/masking, consent gating, export/print restrictions                                                        |
| New **Async job**                | Background status indicator, job progress view, inbox entry, retry UI                                               |

## UI Node Types

Add these **UI node types** to the PlanGraph:

- **Screen** (aka Destination) — registered route with purpose and entry points.
- **UXFlow** — stepwise user journey (includes Loading/Empty/Error variants).
- **UIComponentContract** — props/types/state machine for a component or form.
- **NavigationSpec** — route name, params, guards, transitions, back behavior.
- **SettingsSpec** — key/scope/defaults/change events/admin policy.
- **TutorialSpec** — triggers, steps, completion, re-entry rules.
- **NotificationSpec** — channels, template IDs, throttling, preferences linkage.
- **BadgeRule** — increment/decrement sources, reset semantics.
- **VisualSpec** — mapping to style guide tokens, spacing, densities.
- **StyleGuide** / **DesignTokens** / **ComponentLibrary** — design system artifacts (foundational).

**Edges**:
- Backend node (`Contract|Event|DataModel|Policy`) **→ covered_by →** `UXFlow|Screen|UIComponentContract|SettingsSpec|NotificationSpec`
- UI nodes **→ depends_on →** backend/schema/policy versions
- `Screen` **→ gated_by →** `Policy` (roles/flags/plans)
- `NavigationSpec` **→ covered_by →** `Test(Client)` and **measured_by →** analytics events

**UI leaf requirement**: Every UI node yields **InteractionSpec(Client)** per state-cluster.

## UI Subagents (Parallel Execution)

When UI projection is triggered, invoke these specialized subagents **in parallel** for independent UI concerns:

- **UIPlanner** - Runs questionnaire, drafts UXFlow/Screen
- **NavSmith** - NavigationSpec + deep links + tests
- **FormSmith** - UIComponentContracts for forms with validation
- **SettingsSmith** - SettingsSpec + defaults/migrations
- **TeachBot** - TutorialSpec + triggers + completion
- **NotifyBot** - NotificationSpec + BadgeRule + preferences
- **DesignSync** - VisualSpec + DesignTokens enforcement (lint for raw values)
- **A11yBot** - WCAG checks + keyboard nav + screen reader labels
- **CopyBot** - i18n keys + pluralization + RTL hints

These subagents report back to the main planning loop with their generated UI nodes and edges.

## UI Node Templates (copy/paste)

**Screen**
```yaml
id: Screen:<slug>
route: /<path>/{id?}
entry_points: [CTA:..., DeepLink:..., NavItem:...]
guards: {auth_role: [...], plan: [...], feature_flag: [...], unsaved_changes_guard: true}
layout: {type: detail|list|grid|wizard|map, breakpoints: [sm, md, lg]}
depends_on: [Contract:..., DataModel:...]
```

**NavigationSpec**
```yaml
id: NavigationSpec:<from>-><to>
action: push|replace|modal|sheet
params: {id?: string, source?: string}
back_behavior: pop|dismiss|custom
tests:
  - name: deep_link_opens_detail
    given: url:/item/123
    then: route_is:/item/123
```

**UIComponentContract**
```yaml
id: UIComponentContract:<entity>-form
props: {entityId?: string}
state_machine: [Idle -> Editing -> Submitting -> Success|InlineError]
validation: {client_rules:[...], server_rules:[...]}
events: [submit, cancel, delete]
links: {tracking_events:[...], spans:[...]}
```

**SettingsSpec**
```yaml
id: SettingsSpec:<key>
scope: user|tenant|device
default: true|false|value
controls: toggle|select|range
policy: {admin_enforced?: bool, allowed_values?: [...]}
migration: {from_version: vN, fallback: value}
```

**TutorialSpec**
```yaml
id: TutorialSpec:<feature>
triggers: [first_use_of:<screen>, low_adoption_below:<metric>]
steps: [coachmark:<selector>, highlight:<selector>, checklist:<id>]
completion: {event: tutorial_completed, cooldown_days: 90}
```

**NotificationSpec + BadgeRule**
```yaml
id: NotificationSpec:<topic>
channels: [in_app, push, email]
template_ids: {in_app: tpl_..., push: tpl_...}
throttle: {max_per_hour: 2}
preference_link: SettingsSpec:notifications.<topic>

id: BadgeRule:<surface>
increments_on: [Event:<name>|Query:unread_count]
resets_on: [screen_visit:<slug>, action:<name>]
```

**VisualSpec**
```yaml
id: VisualSpec:<component>
tokens: {color.bg: var(--bg-surface), space.x: 16, radius: 12}
modes: {light: true, dark: true, high_contrast: true}
```

## Completion Proofs (CPP) — ALL must be true

### Core Proofs (P1-P9, renumbered)
- **P1 Topology** — Ready nodes exist for: Client/UI, API Gateway, Services, Data Stores, Caches/CDN, Queues/Workers, Auth/Identity, Secrets, Moderation/Policy (if used), Observability, Analytics, Config/Flags, Migrations/Backfills, Rollout.
- **P2 Scenario × Interface × State Coverage Matrix (Backend)** — for every Scenario, enumerate expected backend interactions; require `expected_ix == realized_ix` (zero gaps).
- **P3 Data Lifecycle** — per Data contract: CRUD, retention, PII, region, backup/restore, migration/backfill, indexing.
- **P4 Security/AuthZ** — authN, scopes/roles, least privilege, secrets, CSRF/CORS (web), rate limits/quotas.
- **P5 Tests** — per Scenario (unit+integration+E2E) and per InteractionSpec (mocks + G/W/T).
- **P6 Observability** — logs, metrics, trace spans; dashboards + alerts; rollout metrics.
- **P7 Rollout/Versioning** — contract semver; migrations/backfills precede consumers; flags/canary/rollback.
- **P8 Ordering/Gate** — task DAG has no blocked leaves; all pass Work-Start Gate.
- **P9 Node-Expansion** — all nonterminals have required children and pass checklists; coverage = 1.00.

### UI-Specific Proofs (P2-Client, P6-UX, P11-Design, P13-A11y/i18n)
- **P2-Client: Client Lane Coverage Matrix** — for every user-facing Scenario, coverage matrix for Client lane satisfied: all interactions have corresponding UI nodes (Screen/UXFlow/UIComponentContract) OR documented Exclusion(UI).
- **P6-UX: UXFlow Completeness** — All UXFlow variants (Loading/Empty/Error/Ready) present with tests + a11y/i18n checks.
- **P10 Core Blueprint Coverage** — Architecture patterns, data flows, error strategies documented.
- **P11 Incident Readiness** — Runbooks, alerts, rollback procedures defined.
- **P11-Design: Design System Compliance** — All UI components reference DesignTokens (no raw color/size values); StyleGuide, DesignTokens, ComponentLibrary nodes exist and are Ready.
- **P12 Compliance** — GDPR/CCPA/HIPAA requirements (if applicable) addressed.
- **P13-A11y/i18n: Accessibility & Internationalization** — WCAG 2.1 AA checks pass for all UI nodes; all copy uses i18n keys (no hardcoded strings); RTL layouts validated; keyboard navigation and screen reader support verified.

**Additional UI completeness score components**:
- `% Screens with NavigationSpec`
- `% UIComponentContracts with validation + tests`
- `% UXFlows with tutorial or intentional no-tutorial decision`
- `% Notifications with linked preference`
- `% components referencing tokens (target: 100%)`

## UI Projection Algorithm (Enforced - Duke's Feedback)

**This algorithm is MANDATORY and MUST run after every delta merge pass.**

**Trigger set**: any new/updated `Contract(API|Event)`, `DataModel`, `Policy`, or `ChangeSpec` with `user_facing=true` or `ui_impact=possible`.

**Implementation (Duke's Specification - Section 3 of dukes/feedback.md)**:
```python
def project_ui_impacts(changed_nodes):
    # Track unaccounted UI skips for explainability
    unaccounted = []

    # 1. Ensure design system foundation exists
    if not design_system_exists():
        create_openquestion(
            "Design System Foundation Missing",
            "Which design system? Who owns tokens? When will StyleGuide/DesignTokens/ComponentLibrary be created?",
            owner="Design Lead",
            due="+14d",
            blocks=["All VisualSpec nodes"]
        )
        # BLOCK all VisualSpec nodes until design system exists
        mark_blocked(find_nodes(type="VisualSpec"), reason="design_system_missing")

    # 2. Process each user-facing node
    for n in changed_nodes:
        # 2a. Check if this node triggers UI obligations
        if not is_ui_trigger(n):  # user_facing=true | ui_impact=possible | client-lane involved
            continue

        # 2b. Run the 13-question UI questionnaire
        answers = ui_questionnaire(n)  # persist answers on node.evidence.ui_answers

        # 2c. If explicitly no UI, create Exclusion and continue
        if answers.no_ui:
            ensure_ui_exclusion(n)  # Create Policy:Exclusion-UI with owner+rationale
            continue

        # 2d. Generate required UI nodes based on answers
        ensure_screen_and_navigation(n, answers)      # Screen + NavigationSpec
        ensure_representation_components(n, answers)  # list/detail/form UIComponentContracts
        ensure_uxflows(n, answers)                    # loading/empty/error variants

        # 2e. Conditional UI nodes based on questionnaire answers
        if answers.needs_setting:
            ensure_settings_spec(n, answers)
        if answers.needs_tutorial:
            ensure_tutorial_spec(n, answers)
        if answers.needs_notifications or answers.needs_badge:
            ensure_notification_and_badge(n, answers)  # NotificationSpec + BadgeRule

        # 2f. Quality checks
        ensure_a11y_i18n_checks(n)                    # WCAG/i18n gate
        ensure_analytics_spec(n, answers)             # tracking plan events

        # 2g. Log if UI was skipped for any reason
        if not has_ui_nodes(n) and not has_exclusion(n):
            unaccounted.append({
                "node_id": n.id,
                "reason": determine_skip_reason(n, answers),
                "owner": n.owner or "Unassigned",
                "due": calculate_due_date(n),
                "blocker": True
            })

    # 3. Apply UI gates and block nodes that don't satisfy requirements
    apply_ui_gates_and_block_on_failure(unaccounted)

    # 4. Return updated graph with UI nodes and blockages
    return {
        "ui_nodes_added": count_new_ui_nodes(),
        "gates_applied": list_gates_applied(),
        "unaccounted": unaccounted,
        "blocked_nodes": find_nodes(status="Blocked")
    }
```

**Key helper functions**:
- `is_ui_trigger(node)` - Returns true if node has user_facing=true OR ui_impact=possible OR involves client lane
- `ui_questionnaire(node)` - Runs 13-question questionnaire, persists answers to node.evidence.ui_answers
- `ensure_ui_exclusion(node)` - Creates Policy:Exclusion-UI with owner+rationale+date
- `ensure_*` functions - Create missing UI nodes and wire edges
- `apply_ui_gates_and_block_on_failure(unaccounted)` - Enforces all 8 quality gates, marks nodes Blocked with reasons

## UI Lint Rules & Gates (Enforced - Duke's Feedback Section 4)

**These lints are NON-NEGOTIABLE and MUST block execution when violated.**

Add these to existing spec-lint:

1. **UI Projection Rule** (MANDATORY) - Any `user_facing=true` backend node requires:
   - ≥1 `UXFlow` **AND**
   - ≥1 `InteractionSpec(Client)` **AND**
   - ≥1 Client-lane interaction spec
   - **OR** recorded `Policy:Exclusion-UI` with owner+rationale+date
   - **Consequence**: Mark parent as BLOCKED until satisfied

2. **Coverage Matrix (Client)** - For each affected entity: `Entity × Screen × StateCluster(role, network, feature_flag, data_version, cache_hit, permission, offline, empty, error_type)` has ≥1 IX or documented Exclusion.
   - **Consequence**: Add to `unaccounted[]` with owner+due

3. **Navigation Symmetry** (MANDATORY) - If new destination exists:
   - `NavigationSpec` with route/params/guards/back behavior MUST exist
   - Tests for navigation MUST exist
   - **Consequence**: Mark Screen as BLOCKED until NavigationSpec created

4. **Settings/Tutorial/Notification Gates** (MANDATORY) - YES answers create required specs:
   - Settings: `SettingsSpec` + `Policy` mapping + migration default
   - Tutorial: `TutorialSpec` + triggers + completion events
   - Notification: `NotificationSpec` + `BadgeRule` + opt-out preference
   - **Consequence**: Mark parent as BLOCKED; add to `unaccounted[]`

5. **A11y/i18n Gate** (MANDATORY) - All `UXFlow` and `UIComponentContract` nodes MUST pass:
   - WCAG 2.2 Level AA checks (keyboard nav, contrast 4.5:1, labels, roles)
   - i18n keys present (no hardcoded strings)
   - RTL layout validated
   - **OR** `Policy:Exclusion-A11y` with owner+rationale (requires legal review)
   - **Consequence**: Mark as BLOCKED; emit OpenQuestion with A11y owner

6. **Design System Gate** (MANDATORY) - If `StyleGuide`/`DesignTokens`/`ComponentLibrary` absent:
   - Create `OpenQuestion` ("Which design system? Who owns tokens?")
   - BLOCK all `VisualSpec` nodes as Ready
   - All `UIComponentContract` and `VisualSpec` nodes MUST reference tokens
   - Raw CSS values forbidden unless `node.evidence` justifies (requires Design approval)
   - **Consequence**: 199 nodes blocked until design system created (expected)

7. **Explainability Gate** (MANDATORY) - For any failure, `unaccounted[]` includes:
   - Short, actionable reason
   - Owner (person responsible for resolution)
   - Due date (when this must be resolved)
   - **Consequence**: Block release until all `unaccounted[]` items resolved

8. **Work-Start Gate (Amended)** (MANDATORY) - Backend leaf is unschedulable until:
   - Paired `UXFlow` + `UIComponentContract` exist AND are Ready
   - `NavigationSpec` exists AND is Ready (if new screen)
   - A11y/i18n checks pass
   - Analytics events defined or excluded
   - Design tokens referenced (no raw values)
   - **Consequence**: Cannot generate ImplementationTasks until all gates satisfied

**Audit Mechanism**: Run lint checker at end of each pass; print violations; refuse to mark plan "complete" until all lints pass.

## Work-Start Gate (Complete Definition)

A leaf can be scheduled only if:
- **No OpenQuestions** blocking it
- Upstream **Contracts** are `Ready`
- **Migrations** scheduled (if breaking changes)
- **Acceptance checks** defined
- **Owner + estimate** set
- **Rollout flag** set (if applicable)
- **P1–P13 true** for its ancestry
- **If user-facing**: paired `UXFlow/Screen` + `UIComponentContract` + `NavigationSpec` (if new screen) + A11y/i18n checks + Analytics events + `VisualSpec` (referencing tokens)

Do **not** generate ImplementationTasks until the parent ChangeSpec **and** all child InteractionSpecs (both backend and client) are `Ready`.

## Emission Rules (DRY, low duplication)
- Emit **deltas only** + **changed node bodies** within the pass KB budget.
- Reference upstream by **IDs** (and optional hash) instead of inlining; keep large bodies in shards.
- Use `FORMS.md` for canonical templates; `PROOFS.md` for matrices to avoid repeating the same text.

## Examples

**First pass**
```json
{"feature_id":"feat:post-image-upload","intent":"Allow users to attach an image to a post."}
```

**Add missing auth refresh Contract, link to IX**
```json
{"deltas":[
  {"op":"add_node","node":{"id":"contract:auth-refresh","type":"Contract","stmt":"POST /auth/refresh ...","status":"Open"}},
  {"op":"add_edge","from":"contract:auth-refresh","to":"ix:compose.auth.refresh.expired","type":"depends_on"}
]}
```

**Add UI nodes for new POST /items endpoint**
```json
{"deltas":[
  {"op":"add_node","node":{"id":"screen:items-create","type":"Screen","route":"/items/new","entry_points":["CTA:create-item"],"status":"Open"}},
  {"op":"add_node","node":{"id":"nav:items-list->items-create","type":"NavigationSpec","action":"push","status":"Open"}},
  {"op":"add_node","node":{"id":"ui-component:items-form","type":"UIComponentContract","state_machine":"Idle->Editing->Submitting->Success","status":"Open"}},
  {"op":"add_node","node":{"id":"visual:items-form","type":"VisualSpec","tokens":{"color.bg":"var(--bg-surface)"},"status":"Open"}},
  {"op":"add_edge","from":"contract:post-items","to":"screen:items-create","type":"covered_by"},
  {"op":"add_edge","from":"screen:items-create","to":"ui-component:items-form","type":"depends_on"}
]}
```

## Planning Depth Requirements

**Beyond Completeness: Plan for Integration and Depth**

The skill should plan for **depth, not just breadth**. Completeness (all operations, contracts, tests) is necessary but not sufficient. Also plan:

1. **Architecture & Data Flow**
   - End-to-end data flow diagrams (user action → API → service → DB → cache → response)
   - Request/response lifecycle across services
   - Cross-service communication patterns (sync, async, events)

2. **Error Handling & Resilience**
   - Error taxonomy across services (consistent error codes, messages)
   - Circuit breaker patterns and fallback strategies
   - Compensation workflows (sagas) for distributed operations
   - Partial failure handling

3. **Business Logic Deep Dive**
   - State machines for complex flows (payment states, subscription lifecycle)
   - Business rules and workflows (payout, revenue reporting)
   - Algorithm specifications (pathfinding, golden ratio calculations)

4. **Integration Patterns**
   - How features integrate (monetization + content, chat + agent access)
   - Shared concerns (caching, rate limiting) across features
   - Data consistency across services

5. **Cross-Cutting Concerns**
   - Caching strategy (what/when to cache, invalidation)
   - Rate limiting strategy (per user/feature/endpoint)
   - Search strategy (full-text, indexing, ranking)
   - Analytics strategy (event tracking, behavior analytics)

6. **UI/UX Architecture** (NEW)
   - Design system foundation (StyleGuide, DesignTokens, ComponentLibrary)
   - Navigation architecture (screen hierarchy, deep linking strategy)
   - State management strategy (local vs global, optimistic updates)
   - Accessibility architecture (keyboard navigation, screen reader support)
   - Internationalization architecture (copy management, RTL support)
   - Responsive design strategy (breakpoints, device capabilities)

## Meta Dimensions Planning

**Expand view beyond basic dimensions to include indirect interfaces and meta dimensions**

Each planning iteration must expand beyond basic implementation dimensions to include:

1. **Indirect Interface Dimensions**
   - How the item interfaces with other areas of the application that support the action/behavior
   - Cross-feature dependencies and interactions
   - Service boundaries and integration points
   - Data flow through indirect paths

2. **User Experience Meta Dimensions**
   - How users discover and access the feature
   - User mental models and expectations
   - Contextual interactions (where/when/how users engage)
   - Accessibility and internationalization considerations
   - Error recovery from user perspective

3. **System Meta Dimensions**
   - Observability and monitoring touchpoints
   - Security and compliance touchpoints
   - Performance and scalability implications
   - Operational and deployment considerations
   - Maintenance and evolution pathways

4. **Planning Meta Dimensions**
   - How the planning itself should evolve
   - Feedback loops for planning improvements
   - Risk assessment for planning gaps
   - Validation mechanisms for planning completeness

5. **Behavioral Support Dimensions**
   - Supporting infrastructure for the behavior (not just the behavior itself)
   - Background processes that enable the action
   - Data consistency and state management
   - Event propagation and side effects
   - Failure modes and recovery mechanisms

6. **UI/UX Meta Dimensions** (NEW)
   - How UI features integrate with each other (cross-screen workflows)
   - Design system evolution and component reusability
   - Analytics and experimentation infrastructure
   - User education and onboarding flows
   - Settings and preference management
   - Notification and communication strategy

**Guidance**: For every feature/capability, ask:
- "What other areas support this action or behavior?"
- "How does this interface with the user in indirect ways?"
- "What meta-infrastructure enables this feature?"
- "What are the indirect consequences and dependencies?"
- "How does the UI discovery and navigation work?"
- "What supporting UI patterns are needed (settings, tutorials, notifications)?"

For complex features mentioned in goal documents (monetization, chat, pathfinding), create dedicated **Architecture** nodes before expanding to operations. Capture the "how it works together" before the "what exists," including indirect interfaces, meta dimensions, and comprehensive UI/UX architecture.

## Decision Heuristics: "Do we need a tutorial/setting/screen?"

Use these cues to guide questionnaire answers:

- **Tutorial**: Required if flow has ≥3 steps, error rate > threshold, or introduces non-obvious affordances; otherwise add empty-state guidance or contextual help.

- **Setting**: Required if behavior materially affects user risk or noisy channels (notifications), or if admins must enforce policy; otherwise prefer adaptive defaults with inline controls.

- **New screen**: Required if the entity needs **discoverable** list + detail, or if navigation/state sharing across sessions is needed; otherwise consider inline/ephemeral UI (modals, sheets, drawers).

- **Tutorial format**: Coach marks for simple features, checklists for multi-step processes, sample data for creative tools, empty-state learning for first use.

- **Notification channels**: In-app for immediate feedback, push for time-sensitive updates, email for reports/summaries, webhooks for integrations.

## Design System Foundation

**Detection & Enforcement**:

If **StyleGuide/DesignTokens/ComponentLibrary** nodes are missing:
1. Create `StyleGuide:App` (owner: Design)
2. Create `DesignTokens:v1` (colors/typography/spacing/radii/shadows/breakpoints/animations)
3. Create `ComponentLibrary:v1` (Button, Input, List, Card, Modal, Toast, Badge, Tabs, Table, Empty, Skeleton, Avatar, Dropdown, Checkbox, Radio, Switch, Slider, DatePicker, FileUpload, Pagination, Breadcrumb, ProgressBar, Tooltip, Popover, Alert, Banner)

**Lint**: Every `UIComponentContract` and `VisualSpec` **must** reference tokens or components; raw CSS values (colors, sizes, fonts) are forbidden unless justified in `node.evidence`.

**DesignAudit pass** (periodic):
- Crawl `UIComponentContract` → verify token usage
- Flag anti-patterns (raw values, inconsistent spacing, non-standard components)
- Propose refactors to shared components
- Identify component library gaps

See `FORMS.md` for node templates and `PROOFS.md` for Completion Proof details.
