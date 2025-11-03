# Recursive Planning Patterns

Patterns for cycle-free semantic preservation and iterative planning refinement.

---

## Cycle Remediation Patterns

When planning graphs contain cycles (e.g., InteractionSpec → ChangeSpec → InteractionSpec), these patterns preserve semantic relationships while maintaining a DAG structure.

### Pattern 1: OpenQuestion + Versioning

**Use Case**: InteractionSpec discovers gaps in ChangeSpec that require iteration.

**Original Cyclic Structure**:
```
change:auth → ix:auth-login
ix:auth-login → change:auth  ❌ (creates cycle)
```

**Solution**: Use OpenQuestion nodes and versioned artifacts.

```yaml
# Initial forward flow
change:auth-v1:
  id: "change:auth-v1"
  type: "ChangeSpec"
  stmt: "Implement basic authentication"
  interactions: ["ix:auth-login-v1", "ix:auth-logout-v1"]

ix:auth-login-v1:
  id: "ix:auth-login-v1"
  type: "InteractionSpec"
  depends_on: ["change:auth-v1"]
  discovers: "Missing token rotation, no rate limiting"

# Discovery creates OpenQuestion (not backward edge)
open:auth-gaps-v1:
  id: "open:auth-gaps-v1"
  type: "OpenQuestion"
  raised_by: "ix:auth-login-v1"
  concerns: "change:auth-v1"
  question: "Token rotation and rate limiting needed"
  findings:
    - "No token refresh mechanism"
    - "No rate limiting on failed attempts"
    - "Session fixation vulnerability"
  resolution_creates: ["change:auth-v2"]

# Resolution creates new version (forward only)
change:auth-v2:
  id: "change:auth-v2"
  type: "ChangeSpec"
  stmt: "Enhanced authentication with token rotation and rate limiting"
  supersedes: "change:auth-v1"
  resolves: "open:auth-gaps-v1"
  interactions: ["ix:auth-login-v2", "ix:auth-logout-v2", "ix:auth-refresh"]
```

**Benefits**:
- No cycles - all edges point forward
- Iteration is explicit and traceable
- Questions document the discovery process
- Version chain shows evolution

### Pattern 2: Capability Evolution Chain

**Use Case**: Requirement discovers that a capability needs enhancement.

**Original Cyclic Structure**:
```
cap:storage → scenario:user-data → req:encryption
req:encryption → cap:storage  ❌ (creates cycle)
```

**Solution**: Use Evaluation nodes to bridge capability evolution.

```yaml
# Original capability
cap:storage-v1:
  id: "cap:storage-v1"
  type: "Capability"
  stmt: "Basic file storage"
  version: "1.0.0"
  features: ["upload", "download", "delete"]

# Requirement discovers gap
req:encryption-at-rest:
  id: "req:encryption-at-rest"
  type: "Requirement"
  stmt: "All stored data must be encrypted at rest"
  semantic_links:
    suggests_capability_enhancement: "cap:storage-v1"

# Evaluation node bridges the gap
eval:storage-encryption-gap:
  id: "eval:storage-encryption-gap"
  type: "Evaluation"
  evaluates: "cap:storage-v1"
  against: "req:encryption-at-rest"
  findings:
    - "Current storage has no encryption"
    - "Need key management system"
    - "Need encryption/decryption pipeline"
  generates: "cap:storage-v2"

# New capability version (no backward edge)
cap:storage-v2:
  id: "cap:storage-v2"
  type: "Capability"
  stmt: "Encrypted file storage with key management"
  version: "2.0.0"
  supersedes: "cap:storage-v1"
  satisfies: "req:encryption-at-rest"
  features: ["upload", "download", "delete", "encrypt", "key-rotate"]
```

**Benefits**:
- Capability evolution is versioned
- Evaluation nodes capture the "why"
- Requirements can suggest without creating cycles
- Clear upgrade path

### Pattern 3: Cross-Cutting Concern Aggregator

**Use Case**: Multiple InteractionSpecs discover the same cross-cutting concern.

**Solution**: Aggregate discoveries into a CrossCuttingConcern node.

```yaml
# Multiple IXs discover same concern
ix:payment-process:
  semantic_links:
    reveals_cross_cutting: "xcut:audit-logging"

ix:user-update:
  semantic_links:
    reveals_cross_cutting: "xcut:audit-logging"

# Cross-cutting concern node (aggregates discoveries)
xcut:audit-logging:
  id: "xcut:audit-logging"
  type: "CrossCuttingConcern"
  discovered_by: [
    "ix:payment-process",
    "ix:user-update",
    "ix:order-cancel"
  ]
  affects: [
    "change:payment",
    "change:user-management",
    "change:order-system"
  ]
  requirements:
    - "All state changes must be audited"
    - "Audit logs must be immutable"
    - "PII must be masked in logs"
  generates: "change:audit-system"
```

**Benefits**:
- Cross-cutting concerns are explicit
- Single source of truth
- No cycles - concern node sits between IX and changes
- Clear impact analysis

### Pattern 4: Feedback Aggregation

**Use Case**: Multiple InteractionSpecs for the same ChangeSpec reveal different issues.

**Solution**: Aggregate feedback into a FeedbackAggregation node.

```yaml
# ChangeSpec with multiple interactions
change:search:
  id: "change:search"
  interactions: [
    "ix:search-basic",
    "ix:search-advanced",
    "ix:search-faceted"
  ]

# Each IX has feedback (via semantic links)
ix:search-basic:
  semantic_links:
    informs: "feedback:search-improvements"
    reveals: ["no fuzzy matching", "no typo correction"]

# Feedback aggregation node
feedback:search-improvements:
  id: "feedback:search-improvements"
  type: "FeedbackAggregation"
  from_interactions: [
    "ix:search-basic",
    "ix:search-advanced",
    "ix:search-faceted"
  ]
  target: "change:search"
  consolidated_findings:
    search_quality:
      - "Add fuzzy matching"
      - "Add typo correction"
    performance:
      - "Implement result caching"
  priority: "high"
  resolution: "change:search-v2"
```

**Benefits**:
- All feedback in one place
- Prioritization is clearer
- No backward edges needed
- Resolution path is explicit

### Pattern 5: Evaluation-Driven Iteration

**Use Case**: Need formal quality gates for iteration.

**Solution**: Use Evaluation nodes as decision gates.

```yaml
# Phase 1: Initial design
change:api-gateway:
  id: "change:api-gateway"
  interactions: [
    "ix:api-auth",
    "ix:api-routing",
    "ix:api-throttle"
  ]

# Phase 2: Evaluation gate
eval:api-gateway-review:
  id: "eval:api-gateway-review"
  type: "Evaluation"
  evaluates: ["ix:api-auth", "ix:api-routing", "ix:api-throttle"]
  criteria:
    security:
      - "OAuth2 compliance"
      - "Rate limiting per client"
    performance:
      - "< 50ms overhead"
      - "10k req/sec capacity"
  findings:
    passed: ["OAuth2 compliance ✓", "Rate limiting ✓"]
    failed: ["No circuit breaking ✗", "Missing retry logic ✗"]
  status: "Blocked"
  generates_requirements: [
    "req:circuit-breaking",
    "req:retry-logic"
  ]

# Phase 3: New requirements from evaluation
req:circuit-breaking:
  id: "req:circuit-breaking"
  from_evaluation: "eval:api-gateway-review"
  generates: "change:api-gateway-resilience"
```

**Benefits**:
- Evaluation gates are explicit
- Criteria are measurable
- Failures generate new requirements
- No cycles - always moving forward

---

## Implementation Guidelines

### When to Use Each Pattern

| Situation | Pattern | Key Benefit |
|-----------|---------|-------------|
| IX reveals gaps in ChangeSpec | OpenQuestion + Versioning | Preserves discovery process |
| Requirement needs new capability | Capability Evolution Chain | Tracks capability growth |
| Multiple IXs reveal same issue | Cross-Cutting Concern | Single resolution point |
| Many IXs have feedback | Feedback Aggregation | Consolidated improvements |
| Need quality gates | Evaluation-Driven | Measurable criteria |

### Node Naming Conventions

- **Versions**: `<type>:<name>-v<N>` (e.g., `change:auth-v2`)
- **OpenQuestions**: `open:<from>-to-<to>` (e.g., `open:ix-auth-to-change-auth`)
- **Evaluations**: `eval:<target>-<aspect>` (e.g., `eval:auth-security`)
- **Feedback**: `feedback:<target>-<topic>` (e.g., `feedback:search-improvements`)
- **Cross-cutting**: `xcut:<concern>` (e.g., `xcut:audit-logging`)

### Semantic Link Types

```yaml
semantic_links:
  # Discovery relationships
  informs: ["node-id"]           # Provides information to
  reveals_gaps_in: ["node-id"]   # Identifies missing pieces
  suggests_capability: ["id"]     # Proposes new capabilities
  requires_iteration_on: ["id"]   # Needs refinement

  # Cross-cutting relationships
  reveals_cross_cutting: ["id"]   # Identifies shared concern
  impacts: ["node-id"]            # Will affect these nodes

  # Versioning relationships
  supersedes: "node-id"           # Replaces previous version
  evolved_from: "node-id"         # Derived from earlier version
```

### Validation Checklist

- [ ] All removed edges have corresponding OpenQuestions or annotations
- [ ] Version chains are complete and traceable
- [ ] Cross-cutting concerns are aggregated
- [ ] Evaluation gates are defined at phase boundaries
- [ ] Semantic links preserve all relationships
- [ ] Graph remains acyclic (verify with topological sort)
- [ ] Traversal tools can follow all patterns
- [ ] No information is lost, only restructured

---

## References

- See `docs/_reference/patterns/cycle-remediation-patterns.md` for complete examples
- See `docs/_reference/architecture/planning-graph-structure-analysis.md` for architectural analysis
- See `docs/_reference/adr/cycle-remediation-architectural-review.md` for ADR on cycle remediation

