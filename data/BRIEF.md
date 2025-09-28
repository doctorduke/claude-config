# Data Directory — BRIEF

## Purpose & Boundary
Local development data storage including SQLite database, seed data, and test fixtures. Development-only, not for production use.

## Interface Contract (Inputs → Outputs)
- **Inputs**: Development data writes, test data generation
- **Outputs**: SQLite database, fixture files, local storage
- **Acceptance**:
  - GIVEN dev environment WHEN initialized THEN local.sqlite created
  - GIVEN tests run WHEN fixtures needed THEN data available

## Dependencies & Integration Points
- Upstream: Development scripts, test runners
- Downstream: Local development environment only

## Work State (Planned / Doing / Done)
- **Done**: SQLite database setup

## Spec Snapshot (2025-09-27)
- Contents: local.sqlite, future seed data
- Note: Most files gitignored

## Decisions & Rationale
- 2025-09-27 — SQLite for local development simplicity

## Local Reference Index
- No submodules

## Answer Pack (YAML)
kind: answerpack
module: data/
intent: "Local development data storage"