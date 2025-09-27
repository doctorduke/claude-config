# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the umemee-v0 monorepo, a mobile-first multi-platform application showcasing bleeding-edge development practices. Built with pnpm workspaces and Turborepo for optimal performance and code sharing across platforms.

## Build Commands

```bash
# Install dependencies
pnpm install

# Development (all platforms)
pnpm dev

# Build all packages
pnpm build

# Run tests
pnpm test

# Type checking
pnpm typecheck

# Linting
pnpm lint

# Format code
pnpm format

# Clean build artifacts
pnpm clean
```

## Platform-Specific Commands

### Web Platform
```bash
pnpm dev --filter=@umemee/web        # Start Next.js dev server with Turbopack
pnpm build --filter=@umemee/web      # Production build
pnpm start --filter=@umemee/web      # Start production server
```

### Mobile Platform
```bash
pnpm dev --filter=@umemee/mobile     # Start Expo dev server
pnpm ios --filter=@umemee/mobile     # Run on iOS simulator
pnpm android --filter=@umemee/mobile # Run on Android emulator
pnpm build --filter=@umemee/mobile   # Export for production
```

### Desktop Platform
```bash
pnpm dev --filter=@umemee/desktop    # Start Electron app
pnpm build --filter=@umemee/desktop  # Build with electron-builder
pnpm dist --filter=@umemee/desktop   # Create distribution packages
```

## Testing

```bash
# Run all tests
pnpm test

# Test specific package
pnpm test --filter=@umemee/utils

# Test with coverage
pnpm test:coverage

# Watch mode
pnpm test:watch
```

## High-Level Architecture

### Monorepo Structure

The codebase follows a modular monorepo architecture with clear separation of concerns:

```
umemee-v0/
├── platforms/          # Platform-specific applications
│   ├── web/           # Next.js 15+ with App Router for web/PWA
│   ├── mobile/        # React Native with Expo for iOS/Android
│   └── desktop/       # Electron for Windows/Mac/Linux
├── shared/            # Shared packages across all platforms
│   ├── types/         # TypeScript type definitions (foundational)
│   ├── config/        # Shared configuration and constants
│   ├── utils/         # Common utility functions
│   ├── api-client/    # Unified API client for backend communication
│   ├── ui-web/        # React components for web platform
│   └── ui-mobile/     # React Native components for mobile
├── core-modules/      # (Planned) Core business logic modules
├── services/          # (Planned) Backend services
└── tools/            # Development tools (subtree/worktree management)
```

### Key Architectural Patterns

1. **Workspace Protocol**: Internal packages use `workspace:*` for version management
2. **Turbo Pipeline**: Build tasks are orchestrated with dependency awareness
3. **Shared Types**: All platforms import from `@umemee/types` for consistency
4. **Platform-Specific UI**: Separate UI packages for web (`ui-web`) and mobile (`ui-mobile`)
5. **API Client**: Centralized API communication through `@umemee/api-client`

### Build Pipeline (Turborepo)

The build system uses Turborepo with the following task dependencies:
- `build`: Depends on upstream builds (`^build`)
- `test`: Depends on upstream builds
- `typecheck`: Depends on upstream builds
- `dev`: Runs without cache, persistent mode
- `lint`: Runs independently with cache

### State Management Strategy

- **Server State**: TanStack Query for API data caching and synchronization
- **Client State**: Zustand for UI state management
- **Form State**: React Hook Form with Zod validation
- **Navigation State**: Platform-specific (Next.js Router, React Navigation)

### Critical Files to Understand

1. **turbo.json**: Defines the monorepo build pipeline and task dependencies
2. **pnpm-workspace.yaml**: Specifies workspace package locations
3. **package.json** (root): Contains global scripts and dev dependencies
4. **platforms/*/package.json**: Platform-specific dependencies and scripts
5. **shared/*/src/index.ts**: Main exports for shared packages

## Package Dependencies

### Dependency Hierarchy

```
types (no dependencies)
  ↓
config → types
utils → types
  ↓
api-client → types, config, utils
  ↓
ui-web → types, utils
ui-mobile → types, utils
  ↓
platforms/* → all shared packages
```

## MCP Server Setup

The repository includes MCP (Model Context Protocol) servers for enhanced development. Run the setup script to initialize:

```bash
pnpm setup:mcps
```

## Important Notes

- **Node Version**: Requires Node.js >= 20.0.0 (uses latest features)
- **Package Manager**: Must use pnpm >= 9.0.0 (don't use npm or yarn)
- **Husky Hooks**: Pre-commit hooks are installed automatically
- **TypeScript**: Strict mode enabled across all packages
- **Module Resolution**: Use package names (`@umemee/*`) not relative paths for cross-package imports
- **Build Order**: Turborepo handles automatically, but be aware of dependency order

## Common Development Patterns

### Adding a New Shared Package

1. Create directory under `shared/`
2. Initialize with `pnpm init`
3. Set package name as `@umemee/package-name`
4. Add to consuming packages with `pnpm add @umemee/package-name@workspace:*`

### Adding Platform-Specific Dependencies

```bash
# Add to specific platform only
pnpm add <package> --filter=@umemee/web
pnpm add <package> --filter=@umemee/mobile
```

### Cross-Platform Code Sharing

- Business logic → `shared/utils` or `core-modules/`
- Types/Interfaces → `shared/types`
- API calls → `shared/api-client`
- Web UI → `shared/ui-web`
- Mobile UI → `shared/ui-mobile`

## Troubleshooting

### Build Issues

```bash
# Clear all caches and rebuild
pnpm clean
rm -rf node_modules
pnpm install
pnpm build
```

### Type Errors

```bash
# Check TypeScript across entire monorepo
pnpm typecheck

# Check specific package
pnpm typecheck --filter=@umemee/web
```

### Dependency Issues

```bash
# Verify workspace setup
pnpm ls --depth=0

# Check for duplicate dependencies
pnpm dedupe
```

## Git Workflow

The repository uses:
- **Feature branches**: Create from `trunk` branch
- **Git Worktrees**: For parallel development (see `tools/worktree/`)
- **Git Subtrees**: For integrating external modules (see `tools/subtree/`)
- **Conventional Commits**: For automated versioning with changesets

## Performance Optimization

- **Turborepo Caching**: Automatic local caching of build outputs
- **pnpm Efficiency**: Shared dependency storage across projects
- **Code Splitting**: Platform-specific bundles
- **Tree Shaking**: Enabled through proper ESM exports
- **Lazy Loading**: Implemented at route/screen level per platform