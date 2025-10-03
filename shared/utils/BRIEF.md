# Shared Utils — BRIEF

## Purpose & Boundary

Platform-agnostic utility functions AND task management framework providing common operations for data manipulation, formatting, validation, and algorithms across all umemee platforms. This module contains both pure, side-effect-free functions and a comprehensive task management system with quality gates.

**Submodules:**
- `utils/` - Pure utility functions (date, string, array, object, crypto)
- `task-management/` - Task state machine and lifecycle management
- `quality-gates/` - Validation layers and bypass mechanisms
- `validation/` - False positive detection and test validation

## Interface Contract

**Inputs**
- Primitive values and objects for transformation (utils)
- Task definitions and state transitions (task-management)
- Validation rules and gate configurations (quality-gates)
- Test results and failure patterns (validation)

**Outputs**
- Transformed/formatted data values (utils)
- Task state transitions and validation results (task-management)
- Gate pass/fail decisions with bypass options (quality-gates)
- False positive detection and test analysis (validation)

**Key Guarantees**
- Pure utility functions with no side effects (utils)
- Enforced state transitions with validation gates (task-management)
- Configurable bypass mechanisms for quality gates (quality-gates)
- Cross-platform compatibility (web, mobile, Node.js)
- Type-safe with full TypeScript definitions

**Anti-Goals**
- Platform-specific utilities (use ui-web or ui-mobile)
- External API calls or async operations (except task management)
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
- [TODO] Add task dependency management
- [TODO] Implement parallel task execution

**Doing**
- [Active] Expanding crypto utilities for JWT operations

**Done**
- [Complete] Core date/time formatters
- [Complete] Email and URL validators
- [Complete] Array and object helpers
- [Complete] Task state machine (PLANNED → IN_PROGRESS → COMPLETE → VERIFIED)
- [Complete] 3-tier validation system (Automation → Agent → Human)
- [Complete] Bypass handler with configurable rules
- [Complete] False positive detector for flaky tests

## Spec Snapshot (2025-10-02)

- **Features**: Date formatting, string validation, array operations, object utilities, crypto helpers, task state machine, quality gates, validation layers
- **Tech**: TypeScript strict mode, pure functions, date-fns, lodash (cherry-picked), Vitest testing
- **Testing**: Vitest with >80% coverage requirement, 41 tests for task management
- **Performance**: Memoization for expensive ops, native methods preferred
- **Task Management**: 6-state workflow with validation gates and bypass mechanisms

## Decisions & Rationale

- **2024-01-10** — Pure functions only (predictability, testability, tree-shaking)
- **2024-01-15** — date-fns over moment.js (smaller bundle, immutable)
- **2024-02-01** — Cherry-pick lodash functions (minimize bundle size)
- **2024-02-20** — Crypto module for all security operations (never Math.random)
- **2025-10-02** — Task state machine with validation gates (quality control, audit trail)
- **2025-10-02** — 3-tier validation system (automation → agent → human escalation)
- **2025-10-02** — Bypass mechanisms for experimental development (flexibility with safety)

## Local Reference Index

- **utils/** → Pure utility functions
  - `date/` - Date/time formatting and parsing
  - `string/` - String manipulation and validation
  - `array/` - Array transformation helpers
  - `object/` - Object manipulation utilities
  - `crypto/` - Security utilities
- **task-management/** → Task lifecycle management
  - `task-state-machine.ts` - State transitions and validation
  - `services.ts` - Task service layer
  - `constants.ts` - Task-related constants
- **quality-gates/** → Validation and bypass systems
  - `validation-layers.ts` - 3-tier validation system
  - `bypass-handler.ts` - Bypass mechanisms and rules
- **validation/** → Test and quality validation
  - `false-positive-detector.ts` - Flaky test detection
  - `__tests__/` - Comprehensive test suite (41 tests)

## Answer Pack

```yaml
kind: answerpack
module: shared/utils
intent: "Pure utility functions AND task management framework for cross-platform development"
surfaces:
  utils:
    key_functions: ["formatDate", "isValidEmail", "debounce", "deepMerge", "generateSecureToken"]
    guarantees: ["pure-functions", "no-side-effects", "type-safe", "cross-platform"]
  task_management:
    key_functions: ["createTask", "transitionTask", "validateTask", "bypassGate"]
    guarantees: ["state-enforcement", "validation-gates", "audit-trail", "bypass-safety"]
work_state:
  planned: ["i18n-formatters", "currency-utils", "phone-validators", "task-dependencies", "parallel-execution"]
  doing: ["jwt-crypto-utils"]
  done: ["date-formatters", "validators", "array-helpers", "task-state-machine", "validation-layers", "bypass-handler", "false-positive-detector"]
interfaces:
  inputs: ["primitives", "objects", "format-strings", "config-objects", "task-definitions", "validation-rules"]
  outputs: ["transformed-values", "validation-booleans", "formatted-strings", "task-states", "gate-decisions"]
spec_snapshot_ref: 2025-10-02
truth_hierarchy: ["source", "tests", "BRIEF", "CLAUDE.md"]
```