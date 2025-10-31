# TDD Patterns

## Pattern 1: Outside-In Feature Slice (Contract-First)

When: Building a feature that crosses boundaries (API/service/UI) and needs clear contracts.

Steps:
- Define behavior with example mapping (Given/When/Then) and a contract (OpenAPI/JSON schema/Pact).
- Write consumer test(s) driving the outer API or UI.
- Add contract tests between consumer and provider.
- Mock only across service boundaries; prefer in-process real collaborators.
- Drive internals with unit tests as design emerges.

Tips:
- Keep one thin E2E happy-path scenario; rely on contract + unit/integration for breadth.
- Use testcontainers or local emulators only when necessary; default to fakes.

## Pattern 2: Inside-Out Domain Rule (Classic TDD)

When: Core algorithm or domain rule with little I/O.

Steps:
- Write the smallest example test (red) for a rule.
- Implement the simplest code (green).
- Generalize with additional examples; refactor for clarity.

Tips:
- Add property-based tests for invariants and edge cases.
- Keep tests table-driven where it improves readability.

## Pattern 3: Bug Fix via Regression Test First

When: A defect is reported and can be reproduced.

Steps:
- Create a failing test reproducing the bug (red) using the public API.
- Fix the code with minimal changes (green).
- Add variants for similar edge cases; refactor for readability.

Tips:
- Link test name to bug ID for traceability.
- Prevent recurrence by adding assertions around root cause.

## Pattern 4: Legacy Code — Characterization + Seams

When: Code without tests or with tight coupling.

Steps:
- Write characterization tests capturing current behavior at stable boundaries.
- Introduce seams (dependency injection, adapters, feature flags) to isolate change.
- Incrementally replace internals behind tests (strangler/branch-by-abstraction).

Tips:
- Start at higher scope (module/service) if units are too coupled.
- Favor fakes and adapters to remove I/O.

## Pattern 5: UI Component TDD

When: Building UI widgets or pages.

Steps:
- Write behavior-focused tests (visible output, ARIA roles, keyboard interactions).
- Drive minimal rendering and state transitions.
- Extract presentation vs container logic for testability.

Tips:
- Prefer queries by role/label over selectors; avoid snapshot assertions for behavior.
- Use accessibility assertions to encode UX guarantees.

## Pattern 6: API-First with Contract Tests

When: Service interfaces shared across teams.

Steps:
- Define contract (OpenAPI/Protobuf) with examples.
- Add consumer-driven contract tests (e.g., Pact) and provider verification.
- Implement provider to satisfy contract; add unit tests for business logic.

Tips:
- Version contracts; test compatibility against previous versions.
- Validate examples as executable tests.

## Pattern 7: Data Access with Fakes

When: Repositories/DAOs and business rules on data.

Steps:
- Define repository interfaces and inject them.
- Use in-memory fakes in unit tests; keep behavior consistent with production DB.
- Add a thin integration test against real DB or testcontainer for schema drift.

Tips:
- Keep SQL/ORM specifics behind ports; assert behavior not queries.

## Pattern 8: Async/Concurrency Determinism

When: Timers, schedulers, async flows.

Steps:
- Inject a test clock and controllable scheduler/executor.
- Use fake time advancement and await points deterministically.
- Assert on outcomes and ordering where behaviorally relevant.

Tips:
- Never sleep; advance the fake clock.
- Seed and inject PRNG for deterministic outcomes.

## Pattern 9: Time and Randomness Control

When: Code depends on now()/UUID/random.

Steps:
- Wrap time and randomness behind interfaces.
- Provide fixed/seeded implementations in tests.
- Assert expected values and sequences.

## Pattern 10: Safe Refactoring with Tests

When: Improving design without changing behavior.

Steps:
- Ensure behavior coverage via unit/integration and mutation tests if available.
- Apply small refactorings (rename, extract, inline) with green tests after each.
- Use approval tests for complex outputs before refactoring, then reduce reliance after.

Tips:
- Keep refactors atomic and frequently committed.

