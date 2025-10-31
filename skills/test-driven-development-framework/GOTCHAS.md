# TDD Gotchas

## Overspecifying Mocks

Symptom: Tests break on refactor without behavior change. Cause: mocks assert call-order/args of internal collaborations. Fix: Mock only at boundaries; assert outcomes over interactions.

## Testing Implementation Details

Symptom: Tests know private internals. Fix: Test via public API or stable seams; remove assertions coupled to structure.

## Flaky Tests from Time/Randomness

Symptom: Intermittent failures; sleeps. Fix: Inject clocks/PRNG; use fake timers; remove sleeps; seed RNGs.

## Network/Filesystem in Unit Tests

Symptom: Slow, brittle tests. Fix: Replace with fakes; elevate to integration if real I/O is necessary.

## Shared Mutable State / Order Dependence

Symptom: Tests pass individually but fail in suite. Fix: Isolate and reset state per test; avoid globals and hidden singletons.

## Snapshot Overuse

Symptom: Large snapshots that change frequently. Fix: Assert semantic behavior; use targeted snapshot for stable structures only.

## E2E Dominance

Symptom: Too many slow E2E tests; long lead time. Fix: Move coverage down to contract/integration/unit tests; keep few critical-path E2E.

## Missing Characterization Before Change

Symptom: Legacy change introduces regressions. Fix: Characterization tests first; introduce seams; then modify.

## Coverage Worship

Symptom: High % but low confidence. Fix: Prioritize behavior relevance; add mutation testing; prune trivial tests.

