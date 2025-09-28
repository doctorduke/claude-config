# Shared Config — BRIEF

## Purpose & Boundary

Centralized configuration management for all platforms and packages in the umemee monorepo. This module defines environment variables, API endpoints, feature flags, and shared constants. Its boundary is configuration data only — no business logic or UI components.

## Interface Contract

**Inputs**
* Environment variables from process.env
* Runtime configuration overrides
* Feature flag toggles

**Outputs**
* Typed configuration objects (`config.api`, `config.app`, `config.features`)
* Environment helper functions (`isDevelopment()`, `isProduction()`, `isTest()`)
* Validated environment variable access (`loadNodeEnv()`, `getEnvVar()`)

**Exported Interface**
* `config` — Main configuration object with api, app, and features namespaces
* `loadNodeEnv(requiredVars)` — Load and validate environment variables
* `getEnvVar(key, defaultValue)` — Safe environment variable access
* `isDevelopment()`, `isProduction()`, `isTest()` — Environment mode checks

**Anti-Goals**
* Does not handle secret management (use secure vaults)
* Does not perform runtime feature evaluation (static flags only)
* Does not include platform-specific UI configuration

## Dependencies & Integration Points

**Upstream Dependencies**
* `@umemee/types` — Type definitions for configuration objects (planned)
* Node.js `process.env` — Environment variable source

**Downstream Consumers**
* All platforms (`@umemee/web`, `@umemee/mobile`, `@umemee/desktop`)
* API client (`@umemee/api-client`) — Uses api.baseUrl and api.timeout
* All shared packages requiring configuration

## Work State

**Planned**
* Add Zod validation for environment schemas
* Implement feature flag system with remote config
* Add per-environment configuration files

**Doing**
* None currently active

**Done**
* Basic config export with api, app, and features
* Environment helper functions
* Node environment loading utility

## Spec Snapshot (2025-09-27)

* **Features**: Environment config, API endpoints, feature flags, app metadata
* **Tech choices**: TypeScript, dotenv for env loading
* **Current structure**: Single config object with nested namespaces
* **Environment support**: Development, staging, production modes

## Decisions & Rationale

* 2025-09-26 — Use single config export instead of multiple (simplicity over granularity)
* 2025-09-26 — Prefix platform-specific env vars (WEB_, MOBILE_, DESKTOP_) for clarity
* 2025-09-27 — Keep secrets out of code, use environment variables only

## Local Reference Index

* **src/**
  * `src/index.ts` — Main config export and barrel exports
  * `src/env.ts` — Environment variable utilities

## Answer Pack

```yaml
kind: answerpack
module: shared/config
intent: "Centralized configuration management across all platforms"
interfaces:
  inputs: ["process.env variables", "runtime overrides", "feature flags"]
  outputs: ["config object", "environment helpers", "validated env access"]
  exports:
    - "config.api.baseUrl"
    - "config.api.timeout"
    - "config.app.name"
    - "config.app.version"
    - "config.features.*"
    - "loadNodeEnv()"
    - "getEnvVar()"
    - "isDevelopment()"
    - "isProduction()"
    - "isTest()"
dependencies:
  upstream: ["@umemee/types (planned)", "process.env"]
  downstream: ["all platforms", "@umemee/api-client", "all shared packages"]
work_state:
  planned: ["zod-validation", "feature-flags", "env-configs"]
  doing: []
  done: ["basic-config", "env-helpers", "node-env-loading"]
spec_snapshot_ref: "2025-09-27"
truth_hierarchy: ["source", "tests", "runtime", "docs", "issues"]
```