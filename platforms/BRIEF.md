# Platforms — BRIEF

## Purpose & Boundary
Platform-specific application implementations for web, mobile, and desktop. Each platform maintains its own UI while sharing business logic from shared packages.

## Interface Contract (Inputs → Outputs)
- **Inputs**: User interactions, platform events, shared package APIs
- **Outputs**: Platform-optimized UI, native integrations, deployment artifacts
- **Acceptance**:
  - GIVEN shared logic WHEN platform renders THEN consistent behavior
  - GIVEN platform build WHEN deployed THEN runs on target devices

## Dependencies & Integration Points
- Upstream: Consumes all shared/* packages
- Downstream: Deploys to platform stores/hosting

## Work State (Planned / Doing / Done)
- **Done**: Web and mobile platforms active
- **Doing**: Desktop migration to Tauri

## Spec Snapshot (2025-09-27)
- Platforms: web (Next.js), mobile (React Native/Expo), desktop (Electron→Tauri)
- Deployment: Vercel, App stores, direct download

## Decisions & Rationale
- 2025-09-27 — Separate platforms for optimal UX per device

## Local Reference Index
- `web/` → [BRIEF](web/BRIEF.md)
- `mobile/` → [BRIEF](mobile/BRIEF.md)
- `desktop/` → [BRIEF](desktop/BRIEF.md)

## Answer Pack (YAML)
kind: answerpack
module: platforms/
intent: "Platform-specific application implementations"