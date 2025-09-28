# Desktop Platform — BRIEF

## Purpose & Boundary
Desktop application for Windows, macOS, and Linux. Currently migrating from Electron to Tauri for better performance and smaller bundle size. Owns desktop-specific features like system tray and native menus.

## Interface Contract (Inputs → Outputs)
- **Inputs**: Native OS events, file system access, keyboard shortcuts, IPC from frontend
- **Outputs**: Desktop window, system tray icon, native menus, file operations
- **Acceptance**:
  - GIVEN Tauri migration complete WHEN app launches THEN < 10MB bundle
  - GIVEN native menu WHEN clicked THEN proper action executed
- **Anti-Goals**: Not functional until Tauri migration complete

## Dependencies & Integration Points
- Upstream: Embeds web platform UI, uses shared packages
- Downstream: OS-specific installers and auto-update infrastructure

## Work State (Planned / Doing / Done)
- **Doing**: [DESK-01] Electron to Tauri migration
- **Planned**: [DESK-02] System tray implementation
- **Planned**: [DESK-03] Auto-updater setup

## Spec Snapshot (2025-09-27)
- Status: Migration in progress, CI disabled
- Target: Tauri 2.0+ with Rust backend
- See: MIGRATION-TO-TAURI.md

## Decisions & Rationale
- 2025-09-27 — Tauri over Electron (10x smaller, better security, native performance)

## Local Reference Index
- MIGRATION-TO-TAURI.md → Migration plan and timeline

## Answer Pack (YAML)
kind: answerpack
module: platforms/desktop/
intent: "Native desktop application (migrating to Tauri)"
status: "migration_in_progress"
interfaces:
  inputs: ["os_events", "file_system", "keyboard_shortcuts"]
  outputs: ["desktop_window", "system_tray", "native_menus"]