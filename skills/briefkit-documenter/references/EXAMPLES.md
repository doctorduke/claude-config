# Briefkit Examples

This document provides complete, real-world examples of BRIEF documentation for various scenarios.

## Table of Contents

1. [Complete Module BRIEF](#example-1-complete-module-brief)
2. [Multi-Surface Application](#example-2-multi-surface-application)
3. [Parent-Child Modules](#example-3-parent-child-modules)
4. [API Service Module](#example-4-api-service-module)
5. [Legacy Code Documentation](#example-5-legacy-code-documentation)
6. [Document Ingestion (PRD → BRIEF)](#example-6-document-ingestion-prd--brief)
7. [App-Level BRIEF](#example-7-app-level-brief)
8. [Microservice BRIEF](#example-8-microservice-brief)

---

## Example 1: Complete Module BRIEF

### Scenario
Documenting an offline caching module for a reading application.

### File: `app/reader/offline-cache/BRIEF.md`

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

## Example 2: Multi-Surface Application

### Scenario
E-commerce checkout module supporting web, mobile, and kiosk interfaces.

### File: `app/checkout/BRIEF.md`

```markdown
# Checkout — BRIEF

## Purpose & Boundary
Handles payment processing and order completion across web, mobile app, and in-store kiosks. Manages cart finalization, payment methods, and order confirmation. Does NOT handle inventory management or shipping logistics.

## Interface Contract (Inputs → Outputs)
**Inputs**
- Cart data (items, quantities, prices)
- Payment method selection (credit card, PayPal, Apple Pay, Google Pay)
- Shipping address and preferences
- Promo codes and discounts
- User authentication token

**Outputs**
- Order confirmation with order ID
- Payment receipt (email and in-app)
- Inventory reservation events
- Analytics events (checkout started, completed, abandoned)
- Error states (payment failed, address invalid)

**Web — Interaction & Presentation**
- Key flows: Multi-step checkout wizard, express checkout (saved payment), guest checkout
- Interactions: Form validation, autofill support, keyboard navigation (Tab/Enter)
- Acceptance:
  - GIVEN user has items in cart
    WHEN user clicks "Checkout"
    THEN checkout wizard loads in ≤1s with cart summary
  - GIVEN payment info entered
    WHEN user submits
    THEN payment processes in ≤5s OR shows error with retry option

**Mobile — Interaction & Presentation**
- Key flows: One-tap checkout (biometric auth), saved address selection, in-app payment
- Gestures: Swipe between steps, pull-to-refresh order status
- Acceptance:
  - GIVEN user has Face ID/Touch ID enabled
    WHEN user taps "Pay with Face ID"
    THEN payment completes after biometric auth in ≤3s
  - GIVEN mobile payment selected
    WHEN user confirms
    THEN native payment sheet appears (Apple Pay/Google Pay)

**Kiosk — Interaction & Presentation**
- Key flows: QR code scan for cart import, card reader integration, receipt printing
- Interactions: Touch-only (no keyboard), large touch targets (min 44x44pt)
- Acceptance:
  - GIVEN customer scans QR code
    WHEN cart imports
    THEN checkout screen shows within 2s with cart contents
  - GIVEN payment completed
    WHEN receipt requested
    THEN receipt prints within 5s

**Inspirations/Comparables**
- Amazon one-click checkout (speed and simplicity)
- Shopify mobile checkout (native payment integration)
- Square kiosk UI (large touch targets, accessibility)
- Apple Store checkout (minimal friction, biometric auth)

**Anti-Goals**
- No subscription management (separate module)
- No split payments across multiple cards in v1
- No cryptocurrency payments in v1

## Dependencies & Integration Points
**Upstream**
- Cart service (cart contents, pricing)
- Auth service (user identity, saved payment methods)
- Payment gateway (Stripe API)
- Address validation service (Smarty Streets)

**Downstream**
- Order management system (order creation)
- Inventory service (reservation, deduction)
- Email service (receipts, confirmation)
- Analytics (conversion tracking)

## Work State (Planned / Doing / Done)
- **Planned**: [CHK-45] Add buy-now-pay-later options (Klarna, Afterpay) (owner @payments-team, target 2025-12-01)
- **Planned**: [CHK-47] Implement saved payment method management (owner @frontend-team, target 2025-11-20)
- **Doing**:   [CHK-42] Fix kiosk card reader timeout issues (owner @hardware-team, started 2025-10-28)
- **Doing**:   [CHK-43] Add promo code validation API (owner @backend-team, started 2025-10-29)
- **Done**:    [CHK-38] Launch mobile biometric checkout (merged 2025-10-20, PR #234)
- **Done**:    [CHK-40] Kiosk receipt printing integration (merged 2025-10-25, PR #241)

## SPEC_SNAPSHOT (2025-10-31)
- Features: multi-surface checkout, saved payments, guest checkout, promo codes, biometric auth (mobile)
- Tech: React (web), React Native (mobile), Electron (kiosk), Stripe SDK, Smarty Streets API
- Performance: <1s page load (web), <3s payment processing, <5s receipt printing
- Security: PCI DSS Level 1 compliant, tokenized payments, no card data stored
- Diagrams: [checkout flow](checkout/_reference/diagrams/flow-diagram.svg), [payment integration](checkout/_reference/spec/stripe-integration.png)
- Full spec: [checkout/_reference/spec/2025-10-20-v2.md](checkout/_reference/spec/2025-10-20-v2.md)

## Decisions & Rationale
- 2025-08-15 — Use Stripe for all payments (consolidate providers, reduce complexity)
- 2025-09-10 — Build kiosk version with Electron (code reuse from web, faster development)
- 2025-10-01 — Biometric auth mobile-only in v1 (web lacks consistent browser support)
- 2025-10-15 — Save payment methods server-side (security, cross-device sync)

## Local Reference Index
- [Stripe integration guide](checkout/_reference/spec/stripe-setup.md)
- [PCI compliance checklist](checkout/_reference/security/pci-compliance.md)
- [Error handling matrix](checkout/_reference/spec/error-codes.md)
- [Kiosk hardware specs](checkout/_reference/hardware/kiosk-requirements.md)

## Answer Pack
\```yaml
kind: answerpack
module: app/checkout
intent: "Process payments and complete orders across web, mobile, and kiosk"
surfaces:
  web:
    key_flows: ["multi-step wizard", "express checkout", "guest checkout"]
    acceptance: ["wizard loads ≤1s", "payment processes ≤5s", "keyboard navigable"]
  mobile:
    key_flows: ["one-tap biometric checkout", "saved address selection"]
    gestures: ["swipe between steps", "tap for native payment"]
    acceptance: ["biometric payment ≤3s", "native payment sheet appears"]
  kiosk:
    key_flows: ["QR cart import", "card reader payment", "receipt printing"]
    acceptance: ["cart imports ≤2s", "receipt prints ≤5s", "44x44pt touch targets"]
work_state:
  planned: ["CHK-45 buy-now-pay-later", "CHK-47 payment method management"]
  doing: ["CHK-42 kiosk card reader fix", "CHK-43 promo validation API"]
  done: ["CHK-38 mobile biometric", "CHK-40 kiosk receipt printing"]
interfaces:
  inputs: ["cart_data", "payment_method", "shipping_address", "promo_code", "auth_token"]
  outputs: ["order_confirmation", "payment_receipt", "inventory_reservation", "analytics_events", "error_states"]
spec_snapshot_ref: checkout/_reference/spec/2025-10-20-v2.md
truth_hierarchy: ["source", "tests", "docs", "issues", "chat"]
\```
```

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

## Example 4: API Service Module

### Scenario
RESTful API for user management.

### File: `services/user-api/BRIEF.md`

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

## Example 5: Legacy Code Documentation

### Scenario
Documenting an undocumented legacy authentication module.

### File: `legacy/auth/BRIEF.md`

```markdown
# Legacy Authentication — BRIEF

## Purpose & Boundary
> INFERRED: Based on code analysis of legacy/auth/ directory

Handles user authentication for the legacy monolith application. Manages login, logout, session management, and password hashing. Appears to be replaced gradually by new auth-service but still in active use by older parts of application.

## Interface Contract (Inputs → Outputs)
**Inputs**
> INFERRED: From route handlers and function signatures

- Form POST: `/login` with username, password
- Form POST: `/logout`
- Session cookie: `LEGACY_SESS_ID`
- Config: `AUTH_SECRET` environment variable

**Outputs**
> INFERRED: From response handlers and redirects

- Session cookie on successful login
- Redirect to `/dashboard` on success
- Redirect to `/login?error=invalid` on failure
- Database writes to `sessions` table
- Audit log entries (appears to write to `auth_log` table)

**Performance**
> INFERRED: No explicit SLAs found in code

- Login appears to be synchronous (no async/await)
- Password hashing uses bcrypt (potentially slow, 10 rounds configured)

**Security Concerns**
- Uses MD5 for session IDs (weak, should migrate to crypto.randomBytes)
- No rate limiting apparent in code
- SQL queries use string concatenation (SQL injection risk in username field)

**Anti-Goals**
> INFERRED: Based on missing features
- No OAuth/SSO support
- No two-factor authentication
- No password reset flow (might be in separate module)

## Dependencies & Integration Points
**Upstream**
- MySQL database (`users` and `sessions` tables)
- `bcrypt` library for password hashing

**Downstream**
- Application routes (checks session validity)
- Audit logging system

## Work State (Planned / Doing / Done)
- **Planned**: [LEG-10] Security audit and fixes (owner @security-team, target TBD)
- **Planned**: [LEG-11] Migrate to new auth-service (owner @modernization-team, target Q1 2026)
- **Doing**:   [LEG-08] Fix SQL injection vulnerability (owner @backend-team, started 2025-10-25)
- **Done**:    [LEG-05] Documentation of current behavior (this BRIEF) (completed 2025-10-31)

## SPEC_SNAPSHOT (2025-10-31)
> INFERRED: Based on code as of 2025-10-31

- Features: username/password login, logout, session management, bcrypt password hashing
- Tech: Node.js (Express), MySQL, bcrypt, express-session
- Security: HTTPS enforced, sessions expire after 24h
- Known issues: MD5 session IDs, SQL injection risk, no rate limiting
- Code location: `legacy/auth/routes.js` (main), `legacy/auth/middleware.js` (session check)
- Database schema: `legacy/auth/_reference/spec/db-schema.sql` (reverse-engineered)

## Decisions & Rationale
> INFERRED: No explicit ADRs found

- Unknown date — bcrypt for passwords (industry standard, good choice)
- Unknown date — MD5 for session IDs (weak choice, needs replacement)
- Unknown date — 24h session expiry (reasonable for this app type)

## Local Reference Index
- [Reverse-engineered database schema](legacy/auth/_reference/spec/db-schema.sql)
- [Security audit findings](legacy/auth/_reference/security/audit-2025-10.md)
- [Migration plan to new auth-service](legacy/auth/_reference/planning/migration-plan.md)

## Answer Pack
\```yaml
kind: answerpack
module: legacy/auth
intent: "Legacy authentication system for monolith application"
surfaces:
  web:
    key_flows: ["login form submission", "logout", "session validation"]
    acceptance: ["successful login redirects to /dashboard", "failed login shows error", "session persists 24h"]
work_state:
  planned: ["LEG-10 security audit", "LEG-11 migrate to auth-service"]
  doing: ["LEG-08 fix SQL injection"]
  done: ["LEG-05 documentation"]
interfaces:
  inputs: ["POST /login", "POST /logout", "LEGACY_SESS_ID cookie", "AUTH_SECRET env"]
  outputs: ["session cookie", "redirects", "database writes", "audit logs"]
spec_snapshot_ref: "legacy/auth/_reference/spec/db-schema.sql"
truth_hierarchy: ["source", "tests", "docs", "issues", "chat"]
\```

**NOTE**: This BRIEF has significant INFERRED content. Requires review by someone familiar with legacy codebase.
```

---

## Example 6: Document Ingestion (PRD → BRIEF)

### Scenario
Converting a Product Requirements Document into a BRIEF.

### Input: PRD for "Smart Search" Feature

```
PRODUCT REQUIREMENTS: Smart Search v1

PROBLEM
Users struggle to find specific articles in large reading lists. Current search is keyword-only and slow.

SOLUTION
Implement semantic search with filters and ranking.

REQUIREMENTS
- Full-text search across titles and content
- Filter by: date range, author, tags, read status
- Rank by relevance (TF-IDF) and recency
- Search suggestions (autocomplete)
- Search history for logged-in users

SURFACES
Web: Search bar in header, results page with filters sidebar
Mobile: Search icon in tab bar, modal results with swipeable filters

UX INSPIRATION
- Notion's quick-find (speed + keyboard navigation)
- Gmail search (powerful filters, simple UI)

TECH CHOICES
- Elasticsearch for search index
- React components for UI
- Background indexer job

ACCEPTANCE CRITERIA
- Search returns results in <500ms
- Autocomplete appears after 2 characters
- Results update as user types (debounced 300ms)
- Filters applied client-side without re-query

OUT OF SCOPE
- No image search
- No search analytics in v1
- No saved searches

ROADMAP
Q4 2025: Basic search + filters
Q1 2026: Autocomplete + search history
Q2 2026: ML-based ranking

TECHNICAL DECISIONS
- Use Elasticsearch over PostgreSQL full-text (better performance, more features)
- Index updates via background job every 5 minutes (acceptable staleness for this use case)
```

### Output: Generated BRIEF

### File: `app/search/BRIEF.md`

```markdown
# Smart Search — BRIEF

## Purpose & Boundary
> INFERRED: Derived from PRD "Problem" and "Solution" sections

Provides semantic search functionality for article discovery. Enables users to search across titles and content with filtering and relevance ranking. Covers search UI, query processing, and result ranking. Does NOT handle article content indexing (separate indexer service).

## Interface Contract (Inputs → Outputs)
**Inputs**
> INFERRED: From "Requirements" section

- User text input (search queries)
- Filter selections: date range, author, tags, read status
- User interactions: typing, selecting suggestions, applying filters

**Outputs**
> INFERRED: From "Requirements" and "Acceptance Criteria"

- Search results list (ranked by relevance and recency)
- Autocomplete suggestions (appears after 2 characters)
- Search history for logged-in users
- Filter state persistence

**Performance Guarantees**
> INFERRED: From "Acceptance Criteria"

- Search results return in <500ms (p95)
- Autocomplete debounced 300ms
- Filter application client-side (instant)

**Web — Interaction & Presentation**
> INFERRED: From "Surfaces" section

- Key flows: Type in header search bar, review results page, apply filters via sidebar
- Interactions: Keyboard navigation (↑↓ for suggestions, Enter to search), click filters
- Acceptance:
  - GIVEN user types in search bar
    WHEN 2+ characters entered
    THEN autocomplete suggestions appear within 300ms
  - GIVEN search results displayed
    WHEN user applies filter
    THEN results update instantly client-side

**Mobile — Interaction & Presentation**
> INFERRED: From "Surfaces" section

- Key flows: Tap search icon, enter query in modal, swipe filters horizontally
- Gestures: Tap to select suggestion, swipe for more filters
- Acceptance:
  - GIVEN user taps search icon
    WHEN search modal opens
    THEN keyboard appears and search input focused
  - GIVEN results displayed
    WHEN user swipes filter carousel
    THEN filters scroll smoothly at 60fps

**Inspirations/Comparables**
> INFERRED: From "UX Inspiration"

- Notion quick-find (speed + keyboard navigation)
- Gmail search (powerful filters, simple UI)

**Anti-Goals**
> INFERRED: From "Out of Scope"

- No image search
- No search analytics in v1
- No saved searches

## Dependencies & Integration Points
**Upstream**
> INFERRED: From "Tech Choices" and general architecture

- Elasticsearch cluster (search index)
- Indexer service (keeps search index updated)
- Auth service (user identity for search history)

**Downstream**
> INFERRED: From typical search system dependencies

- Article detail pages (navigation on result click)
- Analytics (search queries, result clicks)

## Work State (Planned / Doing / Done)
> INFERRED: From "Roadmap" section

- **Planned**: [SRCH-05] ML-based ranking (owner @ml-team, target Q2 2026)
- **Planned**: [SRCH-04] Autocomplete + search history (owner @frontend-team, target Q1 2026)
- **Doing**:   [SRCH-01] Basic search implementation (owner @search-team, started 2025-10-20)
- **Doing**:   [SRCH-02] Filters implementation (owner @frontend-team, started 2025-10-25)
- **Done**:    [SRCH-00] PRD approved and BRIEF created (completed 2025-10-31)

## SPEC_SNAPSHOT (2025-10-31)
> INFERRED: From "Tech Choices" and "Requirements"

- Features (v1): full-text search, filters (date/author/tags/status), relevance ranking (TF-IDF + recency)
- Features (planned): autocomplete, search history, ML ranking
- Tech: Elasticsearch 8.x, React components, background indexer (Node.js)
- Performance: <500ms search, 300ms autocomplete debounce, 60fps filter scroll
- Indexing: Background job every 5 minutes
- Full spec: [app/search/_reference/spec/prd-smart-search-v1.pdf](app/search/_reference/spec/prd-smart-search-v1.pdf) (original PRD stored)

## Decisions & Rationale
> INFERRED: From "Technical Decisions" section

- 2025-10-15 — Use Elasticsearch over PostgreSQL full-text (better performance, richer features)
- 2025-10-18 — Background indexing every 5 minutes (acceptable staleness vs complexity trade-off)

## Local Reference Index
- [Original PRD](app/search/_reference/spec/prd-smart-search-v1.pdf)
- [Elasticsearch schema design](app/search/_reference/spec/elasticsearch-mapping.json) (to be created)
- [UI wireframes](app/search/_reference/ux/wireframes.pdf) (to be created)

## Answer Pack
\```yaml
kind: answerpack
module: app/search
intent: "Semantic search with filters and ranking for article discovery"
surfaces:
  web:
    key_flows: ["search from header", "apply filters", "navigate to result"]
    acceptance: ["results <500ms", "autocomplete after 2 chars", "instant filter application"]
  mobile:
    key_flows: ["tap search icon", "enter query", "swipe filters"]
    gestures: ["tap to select", "swipe filters"]
    acceptance: ["modal opens with keyboard", "smooth 60fps filter scroll"]
work_state:
  planned: ["SRCH-05 ML ranking", "SRCH-04 autocomplete + history"]
  doing: ["SRCH-01 basic search", "SRCH-02 filters"]
  done: ["SRCH-00 PRD approved"]
interfaces:
  inputs: ["search queries", "filter selections", "user typing"]
  outputs: ["search results", "autocomplete suggestions", "search history", "filter state"]
spec_snapshot_ref: app/search/_reference/spec/prd-smart-search-v1.pdf
truth_hierarchy: ["source", "tests", "docs", "issues", "chat"]
\```

**REVIEW REQUIRED**: This BRIEF was generated from PRD. Please verify:
1. Interface Contract accuracy (inputs/outputs complete?)
2. Performance guarantees realistic?
3. Dependencies correct?
4. Work State IDs and timeline feasible?
5. Remove INFERRED markers after verification.
```

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
**Diagrams**: [C4 Level 1 System Context](\_reference/architecture/c4-level-1.png), [Deployment Diagram](_reference/architecture/deployment.svg)
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

## Example 8: Microservice BRIEF

### Scenario
Documenting a notification microservice.

### File: `services/notification-service/BRIEF.md`

```markdown
# Notification Service — BRIEF

## Purpose & Boundary
Delivers notifications to users across email, push (iOS/Android), and in-app channels. Handles notification templates, delivery scheduling, and retry logic. Does NOT handle notification preferences (separate preferences-service) or analytics tracking (separate analytics).

## Interface Contract (Inputs → Outputs)
**Inputs**
- gRPC calls:
  - `SendNotification(user_id, template_id, variables, channels)`
  - `ScheduleNotification(user_id, template_id, variables, channels, send_at)`
  - `CancelScheduledNotification(notification_id)`
- Kafka events (from other services):
  - `user.registered` → welcome email
  - `article.saved` → confirmation push
  - `sync.completed` → in-app notification

**Outputs**
- Email sent via SendGrid API
- Push notifications via FCM (Android) and APNS (iOS)
- In-app notifications stored in Redis (7-day TTL)
- Delivery status events to `notifications.delivered` Kafka topic
- Failure events to `notifications.failed` Kafka topic

**Performance Guarantees**
- <100ms p95 for SendNotification gRPC call
- <1s for actual email delivery (SendGrid SLA)
- <500ms for push notification delivery
- Retry failed deliveries 3 times with exponential backoff

**Reliability**
- At-least-once delivery (duplicates possible, idempotency key in payload)
- Dead-letter queue for permanent failures
- Circuit breaker for external APIs (SendGrid, FCM, APNS)

**Anti-Goals**
- No SMS notifications in v1
- No rich media in push (images, videos)
- No notification grouping/threading

## Dependencies & Integration Points
**Upstream**
- All application services (notification triggers)
- Preferences service (user notification settings)
- Template service (notification templates)

**Downstream**
- SendGrid (email delivery)
- Firebase Cloud Messaging (Android push)
- Apple Push Notification Service (iOS push)
- Redis (in-app notification storage)
- Kafka (delivery status events)

## Work State (Planned / Doing / Done)
- **Planned**: [NOTIF-30] Add SMS via Twilio (owner @backend-team, target Q1 2026)
- **Planned**: [NOTIF-31] Implement notification grouping (owner @backend-team, target Q2 2026)
- **Doing**:   [NOTIF-28] Add retry dashboard in admin panel (owner @ops-team, started 2025-10-25)
- **Doing**:   [NOTIF-29] Improve circuit breaker sensitivity (owner @reliability-team, started 2025-10-28)
- **Done**:    [NOTIF-25] Launch v1 with email + push (deployed 2025-10-01)
- **Done**:    [NOTIF-26] Add in-app notifications (deployed 2025-10-15)

## SPEC_SNAPSHOT (2025-10-31)
- Features: email, push (iOS/Android), in-app notifications, scheduling, templates, retry logic, dead-letter queue
- Tech: Go (gRPC server), Kafka consumer, SendGrid SDK, FCM/APNS clients, Redis
- Deployment: Kubernetes (3 replicas), auto-scaling on CPU >70%
- Monitoring: Prometheus metrics, Grafana dashboards, PagerDuty alerts
- SLA: 99.5% uptime, <100ms p95 latency
- Architecture: [C4 Level 2](notification-service/_reference/diagrams/arch-c4-l2.png), [sequence diagram](notification-service/_reference/diagrams/notification-flow.svg)
- Full spec: [notification-service/_reference/spec/2025-09-20-v1.md](notification-service/_reference/spec/2025-09-20-v1.md)

## Decisions & Rationale
- 2025-07-10 — Use Go for service (high concurrency needs, gRPC ecosystem)
- 2025-08-01 — SendGrid over AWS SES (better deliverability, richer templates)
- 2025-08-15 — At-least-once delivery (simpler than exactly-once, acceptable duplicates)
- 2025-09-01 — Store in-app notifications in Redis (fast reads, auto-expiration)

## Local Reference Index
- [gRPC API proto files](notification-service/_reference/spec/notification.proto)
- [Notification templates](notification-service/_reference/templates/)
- [Monitoring runbook](notification-service/_reference/ops/runbook.md)
- [Circuit breaker configuration](notification-service/_reference/spec/circuit-breaker-config.yaml)

## Answer Pack
\```yaml
kind: answerpack
module: services/notification-service
intent: "Deliver notifications across email, push, and in-app channels"
surfaces:
  api:
    protocol: "gRPC"
    methods: ["SendNotification", "ScheduleNotification", "CancelScheduledNotification"]
    authentication: "Service-to-service JWT"
  events:
    consumes: ["user.registered", "article.saved", "sync.completed"]
    produces: ["notifications.delivered", "notifications.failed"]
work_state:
  planned: ["NOTIF-30 SMS via Twilio", "NOTIF-31 notification grouping"]
  doing: ["NOTIF-28 retry dashboard", "NOTIF-29 circuit breaker tuning"]
  done: ["NOTIF-25 v1 launch", "NOTIF-26 in-app notifications"]
interfaces:
  inputs: ["gRPC calls", "Kafka events", "user preferences"]
  outputs: ["email via SendGrid", "push via FCM/APNS", "in-app via Redis", "delivery status events"]
performance:
  latency_p95: "100ms (gRPC call)"
  delivery_time: "<1s (email), <500ms (push)"
reliability:
  delivery_semantics: "at-least-once"
  retries: "3 with exponential backoff"
  uptime_sla: "99.5%"
spec_snapshot_ref: notification-service/_reference/spec/2025-09-20-v1.md
truth_hierarchy: ["source", "tests", "docs", "issues", "chat"]
\```
```

---

## Usage Notes

### When to Use Each Example

- **Example 1** (Complete Module): Default template for most modules
- **Example 2** (Multi-Surface): When documenting apps with Web + Mobile + other platforms
- **Example 3** (Parent-Child): For hierarchical codebases with submodules
- **Example 4** (API Service): For RESTful APIs, GraphQL services
- **Example 5** (Legacy): When documenting undocumented code (uses INFERRED markers heavily)
- **Example 6** (Document Ingestion): Template for converting PRDs/specs to BRIEFs
- **Example 7** (App-Level): Top-level BRIEF at repository root
- **Example 8** (Microservice): For microservices with gRPC/messaging

### Adaptation Tips

1. **Copy structure**, not content - Each example shows section organization
2. **Adjust surface sections** - Include only relevant platforms (Web, Mobile, API, etc.)
3. **Scale work state** - 3-7 items per section; archive older items
4. **Link appropriately** - Use relative paths to _reference/ materials
5. **Mark uncertainties** - Use INFERRED when confidence is low
6. **Validate** - Check against patterns in PATTERNS.md

---

*Examples version: 1.0.0*
*Based on: BRIEF System v3*
