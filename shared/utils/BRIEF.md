# Shared Utils — BRIEF

## Purpose & Boundary

Platform-agnostic utility functions providing common operations for data manipulation, formatting, validation, and algorithms across all umemee platforms. This module contains only pure, side-effect-free functions that serve as the foundational helpers for the entire monorepo.

**Submodules:**
- `date/` - Date formatting and parsing utilities
- `string/` - String manipulation and validation
- `array/` - Array sorting and filtering helpers
- `object/` - Object merging and transformation
- `crypto/` - Hashing and secure random generation

## Interface Contract

**Inputs**
- Primitive values and objects for transformation
- Format strings for date/string operations
- Configuration objects for utility behavior

**Outputs**
- Transformed/formatted data values
- Boolean validation results
- Computed hashes and random values
- No side effects or mutations

**Key Guarantees**
- All functions are pure with no side effects
- Immutable operations (no input mutation)
- Type-safe with full TypeScript definitions
- Cross-platform compatibility (web, mobile, Node.js)

**Anti-Goals**
- Platform-specific utilities (use ui-web or ui-mobile)
- Stateful operations or global mutations
- External API calls or async operations
- Framework-specific helpers

## Dependencies & Integration Points

**Upstream Dependencies**
- `@umemee/types` - Shared type definitions
- `date-fns` - Date manipulation library
- `lodash` - Cherry-picked utility functions

**Downstream Consumers**
- All platform implementations (`platforms/*`)
- Shared packages (`api-client`, `ui-web`, `ui-mobile`)
- Core business modules (`core-modules/*`)
- Backend services (`services/*`)

## Work State

**Planned**
- [TODO] Implement i18n date formatters
- [TODO] Add currency formatting utilities
- [TODO] Create phone number validators

**Doing**
- [Active] Expanding crypto utilities for JWT operations

**Done**
- [Complete] Core date/time formatters
- [Complete] Email and URL validators
- [Complete] Array and object helpers

## Spec Snapshot (2025-09-27)

- **Features**: Date formatting, string validation, array operations, object utilities, crypto helpers
- **Tech**: TypeScript strict mode, pure functions, date-fns, lodash (cherry-picked)
- **Testing**: Vitest with >80% coverage requirement
- **Performance**: Memoization for expensive ops, native methods preferred

## Decisions & Rationale

- **2024-01-10** — Pure functions only (predictability, testability, tree-shaking)
- **2024-01-15** — date-fns over moment.js (smaller bundle, immutable)
- **2024-02-01** — Cherry-pick lodash functions (minimize bundle size)
- **2024-02-20** — Crypto module for all security operations (never Math.random)

## Local Reference Index

- **date/** → Date/time formatting and parsing
  - `format.ts` - Date to string formatters
  - `parse.ts` - String to date parsers
- **string/** → String manipulation and validation
  - `format.ts` - String formatting utilities
  - `validate.ts` - Email, URL, phone validators
- **array/** → Array transformation helpers
  - `sort.ts` - Sorting with custom comparators
  - `filter.ts` - Advanced filtering operations
- **object/** → Object manipulation utilities
  - `merge.ts` - Deep merge operations
  - `pick.ts` - Object property selection
- **crypto/** → Security utilities
  - `hash.ts` - Hashing functions (SHA, MD5)
  - `random.ts` - Cryptographically secure randoms

## Answer Pack

```yaml
kind: answerpack
module: shared/utils
intent: "Pure utility functions for cross-platform data manipulation and validation"
surfaces:
  all:
    key_functions: ["formatDate", "isValidEmail", "debounce", "deepMerge", "generateSecureToken"]
    guarantees: ["pure-functions", "no-side-effects", "type-safe", "cross-platform"]
work_state:
  planned: ["i18n-formatters", "currency-utils", "phone-validators"]
  doing: ["jwt-crypto-utils"]
  done: ["date-formatters", "validators", "array-helpers"]
interfaces:
  inputs: ["primitives", "objects", "format-strings", "config-objects"]
  outputs: ["transformed-values", "validation-booleans", "formatted-strings"]
spec_snapshot_ref: 2025-09-27
truth_hierarchy: ["source", "tests", "BRIEF", "CLAUDE.md"]
```