# umemee-v0 — BRIEF (App)

> This BRIEF is the **agent-facing, normative overview** of this project. Keep it short and link all depth.
> For daily use, start here; follow **Local Reference Index** for details.

## Purpose & Scope
A mobile-first multi-platform application showcasing bleeding-edge development practices. Built with pnpm workspaces and Turborepo for optimal performance and code sharing.

## Surface Overview
- **Web**: Next.js 15+ with App Router for web/PWA
- **Mobile**: React Native with Expo for iOS/Android
- **Desktop**: (Disabled) Migrating from Electron to Tauri

## Interface Contract
- **Intent**: Deliver unified user experience across web, mobile, and desktop platforms
- **Inputs**: User interactions, API responses, platform events
- **Outputs**: Responsive UI, cached data, cross-platform state sync
- **Acceptance Oracles**:
  - GIVEN any platform WHEN user action THEN consistent behavior across platforms
  - GIVEN offline state WHEN reconnected THEN data syncs automatically

## Spec Snapshot (2025-09-27)
- Scope: Web and mobile platforms active; desktop in migration
- Constraints: Node.js >= 20.0.0, pnpm >= 9.0.0, strict TypeScript
- Release gates: All tests pass, type checks clean, BRIEF validation passes

## System Map
- **platforms/**
  - `web/` → [BRIEF](platforms/web/BRIEF.md) - Next.js web application
  - `mobile/` → [BRIEF](platforms/mobile/BRIEF.md) - React Native mobile app
  - `desktop/` → [BRIEF](platforms/desktop/BRIEF.md) - Tauri desktop (migrating)
- **shared/**
  - `types/` → [BRIEF](shared/types/BRIEF.md) - TypeScript definitions
  - `config/` → [BRIEF](shared/config/BRIEF.md) - Shared configuration
  - `utils/` → [BRIEF](shared/utils/BRIEF.md) - Common utilities
  - `api-client/` → [BRIEF](shared/api-client/BRIEF.md) - API communication
  - `ui-web/` → [BRIEF](shared/ui-web/BRIEF.md) - Web components
  - `ui-mobile/` → [BRIEF](shared/ui-mobile/BRIEF.md) - Mobile components

## Local Reference Index
- [ADRs](_reference/adr/)
- [Diagrams](_reference/diagrams/)
- [Architecture](docs/) - BRIEF System v3 documentation

## Work State (App-wide)
- **Done**: [APP-01] BRIEF System v3 deployment

## Decisions & Rationale
- 2025-09-27 — Interface-First BRIEF System v3 adoption (human-readable, agent-parsable)
- 2025-09-27 — pnpm workspaces + Turborepo for monorepo management

## Claude Code Integration — Update `CLAUDE.md`
Add (or update) a `CLAUDE.md` at the project root with rules that make Claude read BRIEFs first.
If you already have one (Claude Code may create it during `/init`), append this block.

```md
# CLAUDE.md — BRIEF-first rules

## Orientation
1) Always open the **nearest `BRIEF.md`** (current dir or parent).
2) Read sections in this order: **Interface Contract → Spec Snapshot → Answer Pack**.
3) For details, only follow links in **Local Reference Index**; do not roam the tree.

## Editing Discipline
- If a BRIEF section is missing/stale, propose the minimal edit to `BRIEF.md` with a dated **Spec Snapshot (YYYY-MM-DD)**.
- Keep `BRIEF.md` ≤ 200 lines; move depth to `_reference/`.

## File Priorities
- Prefer: `BRIEF.md`, `_reference/adr/*`, `_reference/diagrams/*`.
- Avoid vendor/build artifacts and large auto-generated files.
```

> Notes:
> - Claude Code recognizes a project-level `CLAUDE.md` as persistent instructions; many teams keep one per repo (and optionally per module).  
> - In **Cursor**, project rules live in `.cursor/rules/` and accomplish the same “read BRIEF first” behavior.
> - In **Cody**, add `BRIEF.md` explicitly as context (e.g., `@BRIEF.md`) or use org-level Context Filters.

## Answer Pack (YAML)
kind: answerpack
module: umemee-v0/
intent: "Mobile-first multi-platform application with unified UX"
surfaces:
  web:
    key_flows: ["browse", "interact", "offline_support"]
    tech: "Next.js 15+, React, TypeScript"
  mobile:
    key_flows: ["native_gestures", "offline_first", "push_notifications"]
    tech: "React Native, Expo"
work_state:
  done: ["APP-01 BRIEF deployment"]
interfaces:
  inputs: ["user_interactions", "api_responses", "platform_events"]
  outputs: ["responsive_ui", "cached_data", "cross_platform_sync"]
truth_hierarchy: ["source", "tests", "BRIEF", "docs", "issues"]
