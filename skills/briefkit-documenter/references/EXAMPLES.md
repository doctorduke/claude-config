# Briefkit Examples

Quick navigation guide for finding the right BRIEF template for your needs.

---

## Quick Start Examples

These two examples cover 80% of documentation needs. Start here.

### Example 1: Complete Module BRIEF

Documenting a standard feature module with all BRIEF sections.

```markdown
# Offline Cache — BRIEF

## Purpose & Boundary
Provides fast offline reading for articles by managing local cache. Handles cache write/read/eviction operations. Covers submodules: `store/` (SQLite operations), `sync/` (background sync).

## Interface Contract (Inputs → Outputs)
**Inputs**
- `article.fetched` event - New article available for caching
- `network.status` event - Network connectivity changes
- User action: "Save for offline" button/gesture
- Feature flag: `offline_cache_enabled` (boolean)
- Config: `max_cache_size_mb` (number, default 500)

**Outputs**
- UI: "Offline" badge in article list
- Performance: Cached article opens in ≤200ms
- Event: `cache.evicted` when articles removed
- Side effect: SQLite writes to local database
- Error: `cache.full` when storage limit reached

**Web — Interaction & Presentation**
- Key flows: Ctrl+S to save article, offline mode preserves reading list
- Interactions: Toast notification on save success, badge on cached items
- Acceptance:
  - GIVEN airplane mode enabled
    WHEN user opens article list
    THEN cached articles display in ≤200ms
  - GIVEN article is cached
    WHEN network is offline
    THEN article opens without network request

**Mobile — Interaction & Presentation**
- Key flows: Swipe right for command menu, long-press to save
- Gestures: Swipe-right opens commands, long-press shows context menu
- Acceptance:
  - GIVEN user long-presses article
    WHEN "Save offline" selected
    THEN article caches and badge appears within 2s
  - GIVEN cached article list
    WHEN offline
    THEN list scrolls smoothly at 60fps

**Inspirations/Comparables**
- Notion quick-find and offline sync
- Pocket offline reading experience
- Apple News offline article management
- Instapaper save-for-later functionality

**Anti-Goals**
- No media caching in v1 (images/videos excluded)
- No automatic prefetch of related articles
- No predictive caching based on reading patterns

## Dependencies & Integration Points
**Upstream (consumes)**
- `network.status` from network service
- `article.fetched` events from content pipeline
- User authentication state from auth service

**Downstream (provides to)**
- Reader UI (cache status, article availability)
- Sync service (conflict resolution, cache state)
- Analytics (cache hits/misses, storage usage)

## Work State (Planned / Doing / Done)
- **Planned**: [ID-123] Eviction policy revamp - LRU → smart priority (owner @alice, target 2025-11-15)
- **Planned**: [ID-125] Add cache compression to save 30% space (owner @bob, target 2025-11-30)
- **Doing**:   [ID-117] iOS gesture polish - improve swipe responsiveness (owner @charlie, started 2025-10-28)
- **Doing**:   [ID-118] Fix cache corruption on app crash (owner @dave, started 2025-10-29)
- **Done**:    [ID-101] Auth flow v1 - offline mode respects user permissions (merged 2025-09-21, PR #42)
- **Done**:    [ID-110] Initial SQLite integration (merged 2025-10-15, PR #58)

## SPEC_SNAPSHOT (2025-10-31)
- Features: offline article list, cached detail view, background sync, manual save, automatic cleanup
- Tech: React Native (mobile), Next.js (web), SQLite (storage), EventEmitter (event bus)
- Performance: <200ms cached open, <2s save operation, 60fps scroll
- Constraints: 500MB default cache limit, 1000 articles max
- Diagrams: [C4 Level 2](offline-cache/_reference/spec/arch-c4-l2.png), [data flow](offline-cache/_reference/diagrams/cache-flow.svg)
- Full spec: [offline-cache/_reference/spec/2025-10-25-v1.md](offline-cache/_reference/spec/2025-10-25-v1.md)

## Decisions & Rationale
- 2025-09-24 — Keep cache local-only, no cloud backup (privacy first, simpler implementation)
- 2025-10-10 — SQLite over IndexedDB (better performance, cross-platform consistency)
- 2025-10-20 — Manual save only in v1 (automatic caching adds complexity, unclear UX)

## Local Reference Index
- **submodules/**
  - `store/` → [BRIEF](store/BRIEF.md)
    - key refs: [SQLite schema](store/_reference/spec/schema.sql), [migration guide](store/_reference/spec/migrations.md)
  - `sync/` → [BRIEF](sync/BRIEF.md)
    - key refs: [conflict resolution](sync/_reference/spec/conflicts.md), [sync algorithm](sync/_reference/diagrams/sync-flow.svg)

## Answer Pack
\```yaml
kind: answerpack
module: app/reader/offline-cache
intent: "Enable fast offline reading with ≤200ms article opens"
surfaces:
  web:
    key_flows: ["save article via Ctrl+S", "open cached article list", "auto-sync on reconnect"]
    acceptance: ["cached list renders ≤200ms", "offline badge visible", "toast on save success"]
  mobile:
    key_flows: ["long-press to save", "swipe-right command menu", "background sync"]
    gestures: ["swipe-right for commands", "long-press for context menu"]
    acceptance: ["save completes ≤2s", "60fps scroll", "badge appears immediately"]
work_state:
  planned: ["ID-123 eviction policy revamp", "ID-125 cache compression"]
  doing: ["ID-117 iOS gesture polish", "ID-118 fix cache corruption"]
  done: ["ID-101 auth flow v1", "ID-110 SQLite integration"]
interfaces:
  inputs: ["article.fetched", "network.status", "user.save_action", "offline_cache_enabled", "max_cache_size_mb"]
  outputs: ["ui.offline_badge", "cache.evicted", "cache.full", "sqlite.write"]
spec_snapshot_ref: offline-cache/_reference/spec/2025-10-25-v1.md
truth_hierarchy: ["source", "tests", "docs", "issues", "chat"]
\```
```

---

### Example 4: API Service Module

Documenting a RESTful API or backend service.

```markdown
# User API — BRIEF

## Purpose & Boundary
Provides RESTful API for user account management (CRUD operations, authentication, profile updates). Does NOT handle authorization policies (separate authz service) or user-generated content moderation.

## Interface Contract (Inputs → Outputs)
**Inputs**
- REST API calls:
  - `POST /api/v1/users` - Create user
  - `GET /api/v1/users/:id` - Get user by ID
  - `PUT /api/v1/users/:id` - Update user
  - `DELETE /api/v1/users/:id` - Delete user
  - `POST /api/v1/auth/login` - Authenticate user
  - `POST /api/v1/auth/logout` - End session
- Request headers: `Authorization: Bearer <token>`, `Content-Type: application/json`
- Request body: JSON payloads per OpenAPI spec

**Outputs**
- JSON responses per OpenAPI spec
- HTTP status codes: 200 (success), 201 (created), 400 (bad request), 401 (unauthorized), 404 (not found), 500 (server error)
- Response headers: `X-RateLimit-Remaining`, `X-Request-ID`
- Side effects: Database writes, cache updates, audit log entries

**Performance Guarantees**
- p95 latency: <200ms for reads, <500ms for writes
- Availability: 99.9% uptime SLA
- Rate limits: 1000 req/min per API key

**Security**
- JWT authentication (RS256)
- HTTPS only (TLS 1.2+)
- Input validation and sanitization
- SQL injection prevention (parameterized queries)

**Anti-Goals**
- No GraphQL endpoint in v1
- No real-time WebSocket notifications
- No file uploads (profile pictures stored externally)

## Dependencies & Integration Points
**Upstream**
- PostgreSQL database (user data)
- Redis cache (session storage)
- Auth service (token validation)

**Downstream**
- Email service (verification emails)
- Audit log service (compliance)
- Analytics (API usage metrics)

## Work State (Planned / Doing / Done)
- **Planned**: [API-67] Add password reset flow (owner @backend-team, target 2025-11-15)
- **Planned**: [API-68] Implement rate limiting per endpoint (owner @infra-team, target 2025-11-25)
- **Doing**:   [API-65] Add email verification required flag (owner @security-team, started 2025-10-28)
- **Done**:    [API-60] Launch v1 API with CRUD operations (merged 2025-10-01, PR #401)
- **Done**:    [API-63] Add audit logging for all mutations (merged 2025-10-20, PR #425)

## SPEC_SNAPSHOT (2025-10-31)
- Features: user CRUD, authentication (login/logout), JWT tokens, rate limiting, audit logging
- Tech: Node.js (Express), PostgreSQL, Redis, JWT (jsonwebtoken lib)
- API version: v1 (stable)
- OpenAPI spec: [user-api/_reference/spec/openapi-v1.yaml](user-api/_reference/spec/openapi-v1.yaml)
- Architecture: [C4 Level 2](user-api/_reference/diagrams/arch-c4-l2.png)
- Full spec: [user-api/_reference/spec/2025-10-01-v1.md](user-api/_reference/spec/2025-10-01-v1.md)

## Decisions & Rationale
- 2025-08-15 — Use JWT over sessions (stateless, easier scaling)
- 2025-09-01 — PostgreSQL over MongoDB (relational data, strong consistency needs)
- 2025-09-10 — Versioned API URLs (/v1/) from start (backward compatibility strategy)
- 2025-10-05 — Audit all mutations, not reads (compliance, performance balance)

## Local Reference Index
- [OpenAPI specification v1](user-api/_reference/spec/openapi-v1.yaml)
- [Authentication flow diagram](user-api/_reference/diagrams/auth-flow.svg)
- [Database schema](user-api/_reference/spec/db-schema.sql)
- [Error codes reference](user-api/_reference/spec/error-codes.md)
- [Rate limiting policy](user-api/_reference/spec/rate-limits.md)

## Answer Pack
\```yaml
kind: answerpack
module: services/user-api
intent: "RESTful API for user account management and authentication"
surfaces:
  api:
    endpoints: ["POST /api/v1/users", "GET /api/v1/users/:id", "PUT /api/v1/users/:id", "DELETE /api/v1/users/:id", "POST /api/v1/auth/login", "POST /api/v1/auth/logout"]
    authentication: "JWT Bearer tokens (RS256)"
    rate_limits: "1000 req/min per API key"
    acceptance: ["p95 latency <200ms reads", "p95 latency <500ms writes", "99.9% uptime"]
work_state:
  planned: ["API-67 password reset", "API-68 per-endpoint rate limiting"]
  doing: ["API-65 email verification flag"]
  done: ["API-60 v1 launch", "API-63 audit logging"]
interfaces:
  inputs: ["REST API calls", "Authorization headers", "JSON payloads"]
  outputs: ["JSON responses", "HTTP status codes", "rate limit headers", "database writes", "audit logs"]
spec_snapshot_ref: user-api/_reference/spec/2025-10-01-v1.md
truth_hierarchy: ["source", "tests", "docs", "issues", "chat"]
\```
```

---

## Specialized Examples Library

Find examples for specific scenarios:

### 📱 Multi-Platform Applications
**File**: [`examples/multi-surface-checkout.md`](examples/multi-surface-checkout.md)
- **Use when**: Building apps with Web + Mobile + Kiosk/Hardware interfaces
- **Key patterns**: Surface-specific acceptance criteria, gesture documentation
- **Example**: E-commerce checkout across web, mobile, and in-store kiosks

### 🏗️ Hierarchical Module Systems
**File**: [`examples/parent-child-analytics.md`](examples/parent-child-analytics.md)
- **Use when**: Organizing parent modules with submodules
- **Key patterns**: Parent BRIEF referencing child BRIEFs, scope boundaries
- **Example**: Analytics system with collectors, processors, and dashboards

### 📦 Legacy Code Documentation
**File**: [`examples/legacy-documentation.md`](examples/legacy-documentation.md)
- **Use when**: Documenting existing undocumented code
- **Key patterns**: INFERRED markers, security concerns, migration plans
- **Example**: Legacy authentication module reverse-engineering

### 📄 PRD to BRIEF Conversion
**File**: [`examples/prd-to-brief-conversion.md`](examples/prd-to-brief-conversion.md)
- **Use when**: Converting Product Requirements Documents to BRIEFs
- **Key patterns**: Extracting structure from prose, inferring contracts
- **Example**: Smart Search PRD transformation

### 🚀 Application Root BRIEF
**File**: [`examples/app-level-root-brief.md`](examples/app-level-root-brief.md)
- **Use when**: Creating top-level repository documentation
- **Key patterns**: System map, global policies, cross-cutting concerns
- **Example**: KnowledgeHub cross-platform application

### ⚡ Microservice Documentation
**File**: [`examples/microservice-notification.md`](examples/microservice-notification.md)
- **Use when**: Documenting microservices with gRPC/events
- **Key patterns**: Protocol definitions, reliability guarantees, circuit breakers
- **Example**: Notification service with multiple delivery channels

---

## Example Selection Matrix

Choose the example that best matches your scenario:

| Your Scenario | Recommended Example | Key Sections to Focus On |
|--------------|-------------------|-------------------------|
| New feature module | Example 1: Complete Module | All sections |
| REST API | Example 4: API Service | Interface Contract, Performance |
| Mobile app | Multi-Surface Checkout | Surface sections, Gestures |
| Microservices | Microservice Notification | gRPC, Events, Reliability |
| Undocumented code | Legacy Documentation | INFERRED markers |
| Converting specs | PRD to BRIEF | Document ingestion patterns |
| Repository overview | App-Level Root | System Map, Global Policies |
| Complex architecture | Parent-Child Analytics | Submodule references |

---

## Usage Notes

### When to Use Each Example

- **Example 1** (Complete Module): Default template for most modules - shows all BRIEF sections with realistic content
- **Example 4** (API Service): For RESTful APIs, GraphQL services, or backend-only modules
- **Multi-Surface Checkout**: Multi-platform UIs requiring different interaction models
- **Parent-Child Analytics**: Hierarchical codebases with parent and child modules
- **Legacy Documentation**: Undocumented code requiring reverse-engineering (uses INFERRED markers)
- **PRD to BRIEF**: Template for converting PRDs/specs to BRIEFs (includes conversion checklist)
- **App-Level Root**: Top-level BRIEF at repository root (focuses on system map and policies)
- **Microservice Notification**: For microservices with gRPC/event-driven architectures

### Adaptation Tips

1. **Copy structure**, not content - Each example shows section organization and patterns
2. **Adjust surface sections** - Include only relevant platforms (Web, Mobile, API, Kiosk, etc.)
3. **Scale work state** - Maintain 3-7 items per section; archive older items to git history
4. **Link appropriately** - Use relative paths to `_reference/` materials in your module
5. **Mark uncertainties** - Use INFERRED when confidence is low (especially for legacy code)
6. **Validate** - Check against patterns in PATTERNS.md
7. **Answer Pack** - Include at the end of your BRIEF as YAML metadata block

---

## Finding What You Need

### By Pattern Type
- **Interaction & Presentation**: See Example 1, 2 (Web/Mobile sections)
- **Dependencies**: See Example 4 (API Service)
- **Work State Organization**: See Example 3 (Parent-Child)
- **Performance Guarantees**: See Example 8 (Microservice)
- **Reliability/Resilience**: See Example 8 (Circuit breakers, retries)
- **Security**: See Example 4 (API) or Example 5 (Legacy)

### By Complexity
- **Simplest**: Example 1 (Complete Module) - use as-is for most modules
- **Multi-layered**: Example 3 (Parent-Child) - for complex hierarchies
- **Most detailed**: Example 8 (Microservice) - includes reliability patterns
- **Most constrained**: Example 5 (Legacy) - for undocumented code

### By Document Type
- **Feature module**: Example 1
- **Service/API**: Example 4
- **Microservice**: Example 8
- **App-level**: App-Level Root
- **Legacy code**: Legacy Documentation
- **From PRD**: PRD to BRIEF Conversion

---

## Quick Reference: BRIEF Sections

Every BRIEF should include:

1. **Purpose & Boundary** - What this module does and doesn't do
2. **Interface Contract** - Inputs, outputs, performance, security, anti-goals
3. **Surface Sections** - Web, Mobile, API, Kiosk (as needed)
4. **Dependencies** - Upstream and downstream
5. **Work State** - Planned, Doing, Done
6. **SPEC_SNAPSHOT** - Tech stack, features, diagrams
7. **Decisions & Rationale** - Why specific choices were made
8. **Local Reference Index** - Links to related files
9. **Answer Pack** - YAML metadata block

Optional but recommended:
- **Inspirations/Comparables** - Similar systems for reference
- **Anti-Goals** - What's explicitly NOT in scope

---

*Examples version: 1.0.0*
*Based on: BRIEF System v3*
