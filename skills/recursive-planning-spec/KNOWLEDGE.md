# Recursive Planning Knowledge Base

Critical architectural knowledge and lessons learned from planning graph operations.

---

## Graph Structure Analysis

### Bidirectional Planning Problem

The planning graph supports two information flows:

**1. Top-Down Planning (Waterfall-style)**:
```
Business Intent
    ↓ realizes
System Capability
    ↓ traces_to
Usage Scenario
    ↓ derives
Functional Requirement
    ↓ implements
Interface Contract
    ↓ realizes
Software Component
```

**2. Bottom-Up Discovery (Agile-style)**:
```
User Interaction
    ↓ discovers_need_for
Domain-Level Change
    ↓ refines_into
Specific Requirement
    ↓ validates_via
Scenario & Test
```

**When these flows meet**: CYCLE

### Critical Discovery: Bottom-Up Planning Algorithm

The cycle removal operation (Nov 2025) removed 4,480 edges that represented the **core bottom-up planning algorithm**:

**Pattern Removed**:
```
InteractionSpec (user interaction)
    ↓ depends_on [REMOVED]
ChangeSpec-auto (domain-level changes)
    ↓ depends_on
Requirement (system capability)
```

**Impact**:
- 4,432 edges (98.9%) were InteractionSpec → ChangeSpec
- 1,955 InteractionSpec nodes became isolated (lost connection to implementation)
- Auto ChangeSpecs served as domain-level aggregation hubs (4.1x more edges removed than manual)

**Key Insight**: The removed edges were NOT accidental - they represented legitimate bottom-up discovery where user scenarios drive code changes. This is a valid planning pattern that needs to be preserved through cycle remediation patterns (see PATTERNS.md).

**Solution**: Use cycle remediation patterns (OpenQuestion + Versioning, Evaluation nodes, etc.) to preserve semantic relationships while maintaining DAG structure.

### Graph Metrics Impact

**Before Cycle Removal**:
- Total Edges: 18,059
- Active Nodes: 6,459
- Cycles: 24 (96 nodes)
- Average Out-Degree: 2.26
- Average In-Degree: 1.83

**After Cycle Removal**:
- Total Edges: 13,579 (-4,480, -24.8%)
- Active Nodes: 4,504 (-1,955, -30.3%)
- Cycles: 0 (0 nodes)
- Average Out-Degree: 3.41 (+1.15, +50.9%)
- Average In-Degree: 1.41 (-0.42, -23.0%)

**Paradox Explained**: Average out-degree increased despite removing edges because:
- 1,955 sparsely-connected nodes became isolated (degree 0)
- Remaining 4,504 nodes retained most connections
- Average computed over remaining nodes only

**Information Lost**:
- ❌ InteractionSpec → ChangeSpec traceability (4,432 edges)
- ❌ Bottom-up discovery mechanism
- ❌ Domain clustering via auto ChangeSpecs
- ❌ 1,955 user-facing scenarios disconnected from implementation

**Information Preserved**:
- ✅ Top-down requirements flow (Requirement → Contract → Component)
- ✅ Implementation tasks (ChangeSpec → ImplementationTask: 3,016 edges)
- ✅ Scenario validation (Scenario → Requirement: 2,222 edges)
- ✅ Capability mapping (Intent → Capability → Scenario: 85 edges)
- ✅ Core dependencies (5,621 depends_on edges remain)

---

## Screen Consolidation Knowledge

### Screen Salvage Pattern (v45 Learning)

**Critical Lesson**: When node type classification identifies misclassified "screens", DO NOT just delete them. Many represent legitimate UI requirements that should be converted to the proper artifact type.

**v45 Analysis Results**:
- **169 Screen nodes** identified
- **Only 27** are legitimate user-facing UI screens
- **84% misclassified** (142/169):
  - 36 are backend/infrastructure systems (NOT screens)
  - 47 are action states or API endpoints (NOT screens)
  - 59 are miscellaneous/uncategorized items

**Salvage Classification Decision Tree**:

```python
def salvage_misclassified_screen(screen_node):
    """
    Convert misclassified 'Screen' nodes to proper artifact types instead of deleting.

    Lesson: v45 had 169 screens, 148 were misclassified. Salvage analysis found 83.4%
    represented real UI needs (dashboards, settings, components) not standalone screens.
    """

    purpose = screen_node.stmt.lower()

    # 1. Monitoring/analytics data? → Dashboard panel
    if any(keyword in purpose for keyword in [
        "analytics", "metrics", "monitoring", "observability",
        "logs", "traces", "alerts", "slo"
    ]):
        return convert_to_dashboard_panel(screen_node)

    # 2. Configuration/settings? → Settings section
    if any(keyword in purpose for keyword in [
        "config", "settings", "preferences", "feature flag",
        "toggle", "enable", "disable"
    ]):
        return convert_to_settings_section(screen_node)

    # 3. UI element within another screen? → Component
    if any(keyword in purpose for keyword in [
        "modal", "drawer", "overlay", "widget", "panel",
        "notification", "toast", "banner", "indicator"
    ]):
        return convert_to_component(screen_node)

    # 4. Admin/developer-only? → Admin tool
    if any(keyword in purpose for keyword in [
        "admin", "debug", "developer", "internal tool"
    ]):
        return convert_to_admin_tool(screen_node)

    # 5. Modal/wizard flow? → UX Flow
    if any(keyword in purpose for keyword in [
        "wizard", "flow", "step", "onboarding", "tutorial"
    ]):
        return convert_to_ux_flow(screen_node)

    # 6. Pure backend operation? → Delete (no UI)
    if any(keyword in purpose for keyword in [
        "worker processes", "cache stores", "queue", "background job",
        "backend", "internal process"
    ]):
        return delete_no_ui_needed(screen_node)

    # 7. Legitimate standalone screen? → Keep
    return {"action": "keep", "node": screen_node}
```

### Screen Consolidation Strategy

**Target**: Reduce 169 screens to ~12-15 actual user-facing screens (90% reduction)

**Categories**:

1. **Infrastructure "Screens" (36 nodes)** → Convert to **Service** or **APIEndpoint**
   - Analytics, observability, caching, data storage, queues, workers, secrets, payments, feature flags

2. **Action/State "Screens" (47 nodes)** → Convert to **APIEndpoint**, **UserAction**, or **StateMachine**
   - CDN cache operations, identity/auth actions, navigation actions, user profile actions, preferences, notifications, connectivity events, analytics events

3. **User-Facing Screens (27 nodes)** → Consolidate duplicates to ~12-15 screens
   - Bookmarks (3 → 1)
   - Feed Views (2 → 1)
   - Export Threads (2 → 1)
   - Preferences/Settings (6 → 1)
   - Privacy (2 → 1)
   - Slash Commands (2 → 1)
   - Thread (2 → 1)

**Key Principle**: BEFORE deleting any misclassified screen, classify what it SHOULD be using the salvage decision tree.

---

## References

- See `PATTERNS.md` for cycle remediation patterns
- See `docs/_reference/architecture/planning-graph-structure-analysis.md` for complete graph structure analysis
- See `docs/_reference/architecture/screen-consolidation-analysis.md` for complete screen consolidation analysis

