# Parent-Child Analytics Example

**When to use this example**: Organizing parent modules with submodules

**Key patterns demonstrated**:
- Parent BRIEF referencing child BRIEFs
- Scope boundaries between parent and child modules
- Hierarchical module structure
- Shared vs. isolated responsibilities

**Related documentation**:
- [PATTERNS.md](../PATTERNS.md) - Submodule reference patterns
- [KNOWLEDGE.md](../KNOWLEDGE.md) - Module organization concepts

---

## Example 3: Parent-Child Modules

### Scenario
Analytics system with parent module and specialized submodules.

### Parent: `analytics/BRIEF.md`

```markdown
# Analytics — BRIEF

## Purpose & Boundary
Collects, processes, and reports application usage data. Owns submodules: `collectors/` (event collection), `processors/` (data pipeline), `dashboards/` (visualization).

## Interface Contract (Inputs → Outputs)
**Inputs**
- Application events (user actions, system events)
- Custom metrics from application modules
- Third-party analytics data (Google Analytics, Mixpanel)

**Outputs**
- Real-time dashboards
- Weekly/monthly reports
- Anomaly alerts
- Data exports (CSV, JSON)

**Web — Interaction & Presentation**
- Admin dashboard with charts and filters
- Acceptance: Dashboard loads in ≤2s with last 30 days data

**Anti-Goals**
- No personally identifiable information (PII) collection
- No real-time user tracking (privacy-first)

## Dependencies & Integration Points
**Upstream**: All application modules (event emitters)
**Downstream**: Business intelligence tools, email service (reports)

## Work State (Planned / Doing / Done)
- **Planned**: [AN-88] Add custom dashboard builder (owner @viz-team, target 2025-12-10)
- **Doing**:   [AN-85] Implement anomaly detection ML model (owner @data-team, started 2025-10-20)
- **Done**:    [AN-80] Launch real-time event streaming (merged 2025-10-15, PR #310)

## SPEC_SNAPSHOT (2025-10-31)
- Features: event collection, batch processing, dashboards, exports, alerting
- Tech: Node.js collectors, Python processors (Pandas), React dashboards, PostgreSQL
- Performance: <100ms event ingestion, <2s dashboard load, 1M events/day capacity
- Full spec: [analytics/_reference/spec/2025-10-01-v3.md](analytics/_reference/spec/2025-10-01-v3.md)

## Decisions & Rationale
- 2025-08-01 — Use Kafka for event streaming (scalability, decoupling)
- 2025-09-15 — Python for processing (ecosystem, data science team skills)

## Local Reference Index
- **submodules/**
  - `collectors/` → [BRIEF](collectors/BRIEF.md)
    - key refs: [event schema](collectors/_reference/spec/event-schema.json), [client libraries](collectors/_reference/spec/client-libs.md)
  - `processors/` → [BRIEF](processors/BRIEF.md)
    - key refs: [pipeline architecture](processors/_reference/diagrams/pipeline.svg), [batch jobs](processors/_reference/spec/batch-jobs.md)
  - `dashboards/` → [BRIEF](dashboards/BRIEF.md)
    - key refs: [chart library](dashboards/_reference/spec/charts.md), [API endpoints](dashboards/_reference/spec/api.md)

## Answer Pack
\```yaml
kind: answerpack
module: analytics
intent: "Collect, process, and visualize application usage data"
surfaces:
  web:
    key_flows: ["view dashboards", "export reports", "configure alerts"]
    acceptance: ["dashboard loads ≤2s", "exports complete ≤10s"]
work_state:
  planned: ["AN-88 custom dashboard builder"]
  doing: ["AN-85 anomaly detection"]
  done: ["AN-80 real-time streaming"]
interfaces:
  inputs: ["application_events", "custom_metrics", "third_party_data"]
  outputs: ["dashboards", "reports", "anomaly_alerts", "data_exports"]
spec_snapshot_ref: analytics/_reference/spec/2025-10-01-v3.md
truth_hierarchy: ["source", "tests", "docs", "issues", "chat"]
\```
```

### Child: `analytics/collectors/BRIEF.md`

```markdown
# Event Collectors — BRIEF

## Purpose & Boundary
Provides client libraries and APIs for collecting application events. Handles event validation, enrichment, and forwarding to processing pipeline. Does NOT process or store events long-term.

## Interface Contract (Inputs → Outputs)
**Inputs**
- Client SDK calls (`track(event, properties)`)
- HTTP POST to `/api/events` endpoint
- Batch event uploads

**Outputs**
- Validated events to Kafka topic `raw.events`
- Enriched events with timestamp, session ID, user context
- 400 errors for invalid events
- 202 accepted for valid events

**Performance Guarantees**
- <100ms p95 latency for event ingestion
- 99.9% availability
- No event data loss (at-least-once delivery)

**Anti-Goals**
- No event storage (processing pipeline owns that)
- No real-time analytics computation

## Dependencies & Integration Points
**Upstream**: Client applications (JavaScript, iOS, Android SDKs)
**Downstream**: Kafka cluster, processing pipeline

## Work State (Planned / Doing / Done)
- **Planned**: [COL-22] Add Flutter SDK (owner @mobile-team, target 2025-11-30)
- **Doing**:   [COL-20] Implement event batching in JS SDK (owner @web-team, started 2025-10-25)
- **Done**:    [COL-15] Launch iOS/Android SDKs (merged 2025-10-10, PR #290)

## SPEC_SNAPSHOT (2025-10-31)
- Features: JS/iOS/Android SDKs, HTTP API, event validation, enrichment, Kafka integration
- Tech: Node.js API server, TypeScript/Swift/Kotlin SDKs, Kafka producer
- Capacity: 10K events/sec, horizontal scaling via load balancer
- Full spec: [collectors/_reference/spec/2025-09-15-v2.md](collectors/_reference/spec/2025-09-15-v2.md)

## Decisions & Rationale
- 2025-07-20 — Use Kafka over SQS (better throughput, lower latency)
- 2025-08-10 — Stateless API servers (easier scaling, no session affinity needed)

## Local Reference Index
- [Event schema v2](collectors/_reference/spec/event-schema.json)
- [Client SDK documentation](collectors/_reference/spec/client-libs.md)
- [API reference](collectors/_reference/spec/api.md)

## Answer Pack
\```yaml
kind: answerpack
module: analytics/collectors
intent: "Collect and validate application events via SDKs and APIs"
interfaces:
  inputs: ["sdk.track()", "POST /api/events", "batch uploads"]
  outputs: ["kafka.raw.events", "validation errors", "enriched events"]
work_state:
  planned: ["COL-22 Flutter SDK"]
  doing: ["COL-20 JS SDK batching"]
  done: ["COL-15 iOS/Android SDKs"]
spec_snapshot_ref: collectors/_reference/spec/2025-09-15-v2.md
truth_hierarchy: ["source", "tests", "docs", "issues", "chat"]
\```
```

---

## Adaptation Checklist
- [ ] Replace analytics context with your hierarchical module structure
- [ ] Define clear scope boundaries between parent and children
- [ ] Ensure parent BRIEF references child BRIEFs in Local Reference Index
- [ ] Update work state for both parent and child modules
- [ ] Verify interface contracts don't duplicate across hierarchy
- [ ] Document which decisions apply to parent vs. each child
- [ ] Include cross-module dependencies in Interface Contract

## See Also
- [PATTERNS.md](../PATTERNS.md) - Module hierarchy and scoping patterns
- [KNOWLEDGE.md](../KNOWLEDGE.md) - Parent-child relationship concepts
- [EXAMPLES.md](../EXAMPLES.md) - Example index and selection guide
