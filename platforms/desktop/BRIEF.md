# Desktop Platform

**Status: Pending migration from Electron to Tauri**

## Current State
- Initial Electron setup exists but is not functional
- CI/CD builds are disabled to prevent failures
- Migration to Tauri is planned for better performance and smaller bundle size

## Why Tauri?
- Rust-based backend for superior performance
- Smaller bundle sizes (MB vs GB)
- Better security model with isolated contexts
- Native system integration without Node.js overhead
- Cross-platform consistency with native feel

## Contents (Post-Migration)
- Tauri Rust backend for system integration
- Desktop-specific features (system tray, file access)
- Native menu integration
- Auto-update mechanism via Tauri updater

## Key Relationships
- Will embed web platform for UI
- Uses `@umemee/api-client` for backend
- Leverages `@umemee/types` for type safety

## Next Steps
See MIGRATION-TO-TAURI.md for detailed migration plan and timeline.