# Core Modules — BRIEF

## Purpose & Boundary
Reserved directory for platform-agnostic business logic modules. Will contain domain models, business rules, and core algorithms. Currently in planning phase.

## Interface Contract (Inputs → Outputs)
- **Inputs**: (Planned) Platform API calls, business events, configuration
- **Outputs**: (Planned) Processed data, business rule results, domain events
- **Acceptance**:
  - GIVEN module added WHEN integrated THEN works across all platforms
  - GIVEN business logic WHEN executed THEN platform-agnostic

## Dependencies & Integration Points
- Upstream: Will be consumed by all platforms
- Downstream: Will depend only on @umemee/types

## Work State (Planned / Doing / Done)
- **Planned**: markdown-editor, tiptap-mobile, block-system modules

## Spec Snapshot (2025-09-27)
- Status: Directory reserved, modules not yet implemented
- Architecture: Git subtree integration planned

## Decisions & Rationale
- 2025-09-27 — Git subtree for independent module development

## Local Reference Index
- Future modules will have their own BRIEFs

## Answer Pack (YAML)
kind: answerpack
module: core-modules/
intent: "Platform-agnostic business logic modules (planned)"