# Shared Packages — BRIEF

## Purpose & Boundary
Reusable packages forming the foundation of code reuse across all platforms. Contains type definitions, utilities, configuration, API client, and UI components. Each package is independently versioned with workspace protocol.

## Interface Contract (Inputs → Outputs)
- **Inputs**: Platform imports, workspace dependencies, TypeScript compilation
- **Outputs**: Typed exports, utility functions, React components, API services
- **Acceptance**:
  - GIVEN package imported WHEN used THEN type-safe
  - GIVEN shared code WHEN modified THEN all platforms affected

## Dependencies & Integration Points
- Upstream: types (foundational) → config/utils → api-client → ui packages
- Downstream: All platforms and services consume shared packages

## Work State (Planned / Doing / Done)
- **Done**: All core packages established and functional

## Spec Snapshot (2025-09-27)
- Packages: types, config, utils, api-client, ui-web, ui-mobile
- Protocol: workspace:* for internal versioning

## Decisions & Rationale
- 2025-09-27 — Separate ui-web/ui-mobile (platform optimization)

## Local Reference Index
- `types/` → [BRIEF](types/BRIEF.md) - TypeScript definitions
- `config/` → [BRIEF](config/BRIEF.md) - Configuration management
- `utils/` → [BRIEF](utils/BRIEF.md) - Utility functions
- `api-client/` → [BRIEF](api-client/BRIEF.md) - API communication
- `ui-web/` → [BRIEF](ui-web/BRIEF.md) - Web components
- `ui-mobile/` → [BRIEF](ui-mobile/BRIEF.md) - Mobile components

## Answer Pack (YAML)
kind: answerpack
module: shared/
intent: "Foundation of code reuse across platforms"