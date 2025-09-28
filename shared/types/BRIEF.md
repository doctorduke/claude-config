# Shared Types — BRIEF

## Purpose & Boundary

Foundational TypeScript type definitions package providing shared types, interfaces, and type utilities across all platforms (web, mobile, desktop). This is the base dependency with no internal dependencies — all other packages depend on this.

## Interface Contract (Inputs → Outputs)

**Inputs**
* No runtime inputs — pure compile-time type definitions
* TypeScript compiler consumes exported types
* Build tools reference type declarations

**Outputs**
* Type definitions for API contracts (`ApiResponse<T>`)
* Domain model interfaces (`User`)
* Platform discriminators (`Platform` type)
* No runtime code, no side effects, no state

**Anti-Goals**
* No runtime validation logic (belongs in utils)
* No business logic or implementations
* No framework-specific types (belong in ui packages)

## Dependencies & Integration Points

* **Upstream**: None (foundational package)
* **Downstream Consumers**: All packages (`@umemee/config`, `@umemee/utils`, `@umemee/api-client`, `@umemee/ui-web`, `@umemee/ui-mobile`, all platform apps)

## Work State (Planned / Doing / Done)

- **Planned**: Expand domain models for workspace/document types
- **Planned**: Add branded types for type-safe IDs
- **Done**: Basic User and ApiResponse types established

## Spec Snapshot (2025-09-27)

- **Features**: User model, ApiResponse wrapper, Platform discriminator
- **Tech**: Pure TypeScript type definitions, no runtime
- **Structure**: Single `src/index.ts` barrel export

## Decisions & Rationale

- 2025-09-26 — No runtime code policy (keeps package pure, zero bundle impact)
- 2025-09-26 — Barrel exports from index (simplifies imports, better tree-shaking)
- 2025-09-26 — Interfaces over type aliases for domain models (extensibility)

## Local Reference Index
- No submodules (single index.ts export)

## Answer Pack (YAML)

```yaml
kind: answerpack
module: shared/types
intent: "Provide foundational TypeScript types for type-safe development across all platforms"
surfaces:
  all:
    key_exports: ["User interface", "ApiResponse<T>", "Platform type"]
    guarantees: ["Zero runtime overhead", "No dependencies", "Pure types only"]
work_state:
  planned: ["Domain model expansion", "Branded types"]
  doing: []
  done: ["Basic type foundation"]
interfaces:
  inputs: ["TypeScript compilation"]
  outputs: ["Type definitions", "Interface contracts", "Type utilities"]
spec_snapshot_ref: 2025-09-27
truth_hierarchy: ["source", "tests", "types", "docs", "issues", "chat"]
```