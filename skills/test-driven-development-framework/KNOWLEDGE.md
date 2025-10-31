# TDD Knowledge Base

## Principles

- Red/Green/Refactor: behavior first, minimal code, then design improvement
- Specify behavior, not implementation details
- Tests as documentation and design feedback
- Small steps, fast feedback, frequent commits

## Test Types and Their Purpose

- Unit: fastest feedback on behavior of a small unit; no I/O
- Integration: multiple units or components together in process
- Contract: verifies producer/consumer compatibility at boundaries
- E2E: validates critical user journeys end-to-end; slow and few
- Property-based: asserts invariants across generated inputs

## Test Doubles

- Dummy, Stub, Spy, Mock, Fake — choose the lightest double that achieves isolation
- Prefer fakes over mocks for stable behavior and lower brittleness
- Use mocks to assert cross-service interactions that define behavior (not internals)

## Seams and Testability

- Seams: injection points, adapters, environment boundaries where behavior can be substituted
- Hexagonal architecture (ports/adapters) improves testability and contracts
- Feature flags and branch-by-abstraction enable incremental change safely

## Naming and Structure

- Test name format: when_<condition>_then_<expected> or given_<context>_when_<action>_then_<outcome>
- Structure: Arrange/Act/Assert or Given/When/Then; one main behavior per test
- Keep assertions meaningful; avoid asserting multiple unrelated behaviors in one test

## Assertions and Matchers

- Prefer semantic matchers (contains, equals, raises, within tolerance) over raw comparisons
- For floating point, use epsilon-based assertions
- For collections, assert on key properties, not whole-object snapshots

## Determinism Techniques

- Inject clocks and PRNGs; use fake timers/schedulers
- Replace network and filesystem with fakes/in-memory implementations
- Seed data explicitly; isolate tests and reset state between cases

## Coverage and Quality

- Coverage is a proxy; optimize for behavior relevance
- Mutation testing reveals weak assertions and gaps in behavior checks
- Track flake rate; prioritize eliminating nondeterminism

## Language-Specific Notes (Quick)

- Python (pytest): fixtures for isolation, `freezegun` or clock wrappers, `hypothesis` for properties
- JavaScript/TypeScript (Jest/Vitest): fake timers, React Testing Library for behavior-focused UI tests
- Go: table-driven tests, interfaces for seams, `testing` + fakes; avoid global state
- Java/Kotlin: JUnit5, Mockito for boundary mocks, Testcontainers sparingly; use clock interfaces
- Rust: trait-based seams, deterministic RNG via `rand::rngs::StdRng` with seed

