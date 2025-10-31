# Microservice Notification Example

**When to use this example**: Documenting microservices with gRPC/events

**Key patterns demonstrated**:
- gRPC API documentation
- Event-driven architecture (Kafka, pub/sub)
- Reliability guarantees and circuit breakers
- Service-to-service authentication

**Related documentation**:
- [PATTERNS.md](../PATTERNS.md) - Event-driven and gRPC patterns
- [KNOWLEDGE.md](../KNOWLEDGE.md) - Microservice architecture concepts

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

## Adaptation Checklist
- [ ] Replace notification service with your microservice name
- [ ] Define gRPC methods and their contracts
- [ ] Document Kafka topics consumed and produced
- [ ] Define external service dependencies (APIs, databases)
- [ ] Include performance guarantees (latency, throughput)
- [ ] Document reliability patterns (retry, circuit breaker, idempotency)
- [ ] Define deployment target (Kubernetes, Docker, serverless, etc.)
- [ ] Include monitoring and alerting approach
- [ ] Document SLA and uptime requirements
- [ ] Create architecture and sequence diagrams

## Key Patterns for Microservices
- **gRPC for sync APIs**: Low-latency inter-service communication
- **Kafka for async events**: Decoupled event-driven flows
- **At-least-once semantics**: Simpler than exactly-once, requires idempotency
- **Circuit breakers**: Prevent cascading failures in external dependencies
- **Dead-letter queues**: Handle permanent failures gracefully
- **Kubernetes deployment**: Standard container orchestration

## Performance & Reliability Sections
- **Latency**: p95 and p99 latencies for critical paths
- **Throughput**: Max events/sec or requests/sec capacity
- **Retry strategy**: Number of retries and backoff algorithm
- **Delivery semantics**: At-least-once vs. exactly-once vs. at-most-once
- **SLA/Uptime**: Availability guarantees (99.5%, 99.9%, etc.)
- **Monitoring**: Prometheus metrics and alerting rules

## See Also
- [PATTERNS.md](../PATTERNS.md) - Microservice and event-driven patterns
- [KNOWLEDGE.md](../KNOWLEDGE.md) - gRPC, Kafka, and reliability patterns
- [EXAMPLES.md](../EXAMPLES.md) - Example index and selection guide
