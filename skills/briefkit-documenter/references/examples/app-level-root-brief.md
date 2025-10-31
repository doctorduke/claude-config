# App-Level Root BRIEF Example

**When to use this example**: Creating top-level repository documentation

**Key patterns demonstrated**:
- System map with module references
- Global policies and invariants
- Cross-cutting concerns documentation
- App-wide work state

**Related documentation**:
- [PATTERNS.md](../PATTERNS.md) - System map and global policy patterns
- [KNOWLEDGE.md](../KNOWLEDGE.md) - Application-level architecture concepts

---

## Example 7: App-Level BRIEF

### Scenario
Top-level BRIEF for entire application.

### File: `BRIEF.md` (repository root)

```markdown
# KnowledgeHub — BRIEF (Application)

## Purpose & Scope
KnowledgeHub is a cross-platform application for reading, saving, and managing articles. Supports Web, iOS, and Android. Enables offline reading, smart search, and personal libraries.

## Surface Overview
- **Web**: Desktop and mobile-responsive browser experience
- **iOS**: Native app with offline sync and widgets
- **Android**: Native app with Material Design

## System Map
- [Authentication](app/auth/BRIEF.md) - User accounts and SSO
- [Reader](app/reader/BRIEF.md) - Article viewing and offline cache
- [Search](app/search/BRIEF.md) - Semantic search and filters
- [Library](app/library/BRIEF.md) - Personal collections and tags
- [Sync](app/sync/BRIEF.md) - Cross-device synchronization
- [Analytics](analytics/BRIEF.md) - Usage metrics and dashboards
- [API Services](services/BRIEF.md) - Backend APIs (user, content, sync)

## Global Invariants & Policies
**Authentication**: Email magic-link (Web), biometric (Mobile), OAuth (Google, Apple)
**Accessibility**: WCAG 2.1 AA compliance across all surfaces
**Performance Budgets**:
- Web: FCP ≤2s, LCP ≤2.5s (Core Web Vitals)
- Mobile: App launch ≤1s, cached article open ≤200ms
**Privacy**: No tracking without consent, local-first data storage, GDPR compliant
**Security**: HTTPS only, JWT authentication, encrypted data at rest

## Work State (App-Wide)
- **Planned**: [APP-50] Launch Android app (target Q1 2026)
- **Planned**: [APP-51] Implement share-sheet integration (iOS, Android) (target Q2 2026)
- **Doing**:   [APP-45] Offline sync polish - conflict resolution improvements (started 2025-10-20)
- **Done**:    [APP-40] Launch iOS app v1.0 (released 2025-10-01, App Store)
- **Done**:    [APP-42] Implement smart search with Elasticsearch (released 2025-10-15)

## SPEC_SNAPSHOT (2025-10-31)
**Features**: Article reading, offline cache, search, personal library, tagging, cross-device sync
**Architecture**: React (Web), React Native (iOS, Android), Node.js (APIs), PostgreSQL (primary DB), Redis (cache), Elasticsearch (search)
**Infrastructure**: AWS (ECS for services, S3 for media, CloudFront CDN)
**Monitoring**: Datadog (APM), Sentry (error tracking), Amplitude (product analytics)
**Diagrams**: [C4 Level 1 System Context](_reference/architecture/c4-level-1.png), [Deployment Diagram](_reference/architecture/deployment.svg)
**Full architecture docs**: [_reference/architecture/2025-10-01-v2.md](_reference/architecture/2025-10-01-v2.md)

## Decisions & Rationale (App-Level)
- 2025-06-01 — Use React Native over native Swift/Kotlin (faster development, code sharing)
- 2025-07-15 — PostgreSQL as primary database (relational data model, ACID guarantees)
- 2025-08-01 — Offline-first architecture for mobile (better UX in poor connectivity)
- 2025-09-01 — Magic-link auth over password (simpler UX, more secure)

## Global Reference Index
- [Architecture Decision Records](_reference/adr/)
- [C4 Architecture Diagrams](_reference/architecture/)
- [API Documentation](services/_reference/api-docs/)
- [Design System](_reference/design-system/)
- [Security Policies](_reference/security/)

## Answer Pack
\```yaml
kind: answerpack
module: "."
intent: "Cross-platform article reading and management application"
surfaces:
  web:
    key_features: ["article reading", "search", "library management", "responsive design"]
  ios:
    key_features: ["offline reading", "biometric auth", "widgets", "background sync"]
  android:
    key_features: ["offline reading", "material design", "background sync"]
work_state:
  planned: ["APP-50 Android launch", "APP-51 share-sheet integration"]
  doing: ["APP-45 offline sync polish"]
  done: ["APP-40 iOS v1.0 launch", "APP-42 smart search"]
global_policies:
  authentication: ["magic-link (web)", "biometric (mobile)", "OAuth (Google, Apple)"]
  accessibility: "WCAG 2.1 AA"
  performance: ["FCP ≤2s (web)", "LCP ≤2.5s (web)", "launch ≤1s (mobile)"]
  security: ["HTTPS only", "JWT auth", "encrypted at rest"]
tech_stack: ["React", "React Native", "Node.js", "PostgreSQL", "Redis", "Elasticsearch", "AWS"]
spec_snapshot_ref: _reference/architecture/2025-10-01-v2.md
truth_hierarchy: ["source", "tests", "docs", "issues", "chat"]
\```
```

---

## Adaptation Checklist
- [ ] Replace KnowledgeHub with your application name
- [ ] Update Surface Overview with your supported platforms
- [ ] Create System Map with links to your major modules
- [ ] Document global policies for authentication, accessibility, performance, privacy, security
- [ ] Update Work State with app-wide initiatives and releases
- [ ] Include architecture diagrams (C4 Level 1, deployment, system context)
- [ ] List all reference materials in Global Reference Index
- [ ] Document major architectural decisions in Decisions & Rationale
- [ ] Update SPEC_SNAPSHOT with current tech stack and infrastructure

## Best Practices for App-Level BRIEFs
- **System Map**: Link to module BRIEFs in subdirectories (not inline)
- **Global Policies**: Define cross-cutting concerns (auth, perf, security, privacy, accessibility)
- **Tech Stack**: List primary technologies only (avoid exhaustive dependencies)
- **Work State**: Track app-wide initiatives and major releases (not feature details)
- **References**: Organize by type (architecture, security, design system, APIs)

## Differences from Module-Level BRIEFs
- **Purpose**: System overview instead of module details
- **Interface Contract**: System-level inputs/outputs (external integrations)
- **Surfaces**: User-facing platforms/clients
- **Dependencies**: External systems and services
- **Work State**: App-wide roadmap and releases
- **Answer Pack**: High-level system description

## See Also
- [PATTERNS.md](../PATTERNS.md) - Application-level BRIEF patterns
- [KNOWLEDGE.md](../KNOWLEDGE.md) - System mapping and global policies
- [EXAMPLES.md](../EXAMPLES.md) - Example index and selection guide
