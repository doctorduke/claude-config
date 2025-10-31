# TDD Quick Reference

## Red/Green/Refactor Loop

- Red: Write the smallest failing test for a behavior
- Green: Implement minimal code to pass
- Refactor: Improve names, extract duplication, enforce boundaries

Commit after green. Keep steps 1–5 minutes.

## Choosing Test Doubles

- Prefer real in-process collaborators if fast and deterministic
- Otherwise: Fake > Stub/Spy > Mock
- Mock only across service boundaries for behavior-significant interactions

## Naming Template

- given_<context>_when_<action>_then_<outcome>
- when_<condition>_then_<expected>

## Time/Randomness/Stability

- Inject `Clock`/`Now()` wrappers; fake timers for async
- Seed RNGs; inject PRNG instance
- Avoid sleeps; advance fake time

## Language Quick Commands

- Python (pytest)
  - Run: `pytest -q`
  - Watch: `ptw` (pytest-watch)
  - Time: `freezegun`, custom clock interfaces
  - Props: `hypothesis`

- JS/TS (Jest/Vitest)
  - Run: `npm test -- -u`
  - Watch: `npm test -- --watch`
  - Timers: `jest.useFakeTimers()` / Vitest fake timers
  - UI: React Testing Library

- Go
  - Run: `go test ./...`
  - Race: `go test -race ./...`
  - Table tests; interfaces for seams

- Java/Kotlin
  - Run: `mvn -q -Dtest=* test` or `gradle test`
  - JUnit5, Mockito, Testcontainers (sparingly)
  - Clock: `java.time.Clock` injection

- Rust
  - Run: `cargo test`
  - RNG: `StdRng::seed_from_u64`

## Contract Testing

- Define OpenAPI/Protobuf with examples
- Consumer tests publish contracts; provider verifies against versions
- CI enforces compatibility on both sides

## Checklists

- Before coding
  - Behavior example(s) defined
  - Test scope chosen (unit/contract/integration)
  - Seams identified; doubles selected

- During loop
  - Red test is meaningful and fails for the right reason
  - Green with minimal change only
  - Refactor safely with green tests

- After
  - Flake controls in place (time/random)
  - Naming conveys behavior
  - Commit message references behavior/issue

