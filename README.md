# Umemee v0

**Status:** In Design & Early Development
**Platforms:** Mobile (Expo/React Native), Web (Next.js 15+), Desktop (Migrating to Tauri)

A **media-first social platform** focused on meme sharing, galleries, and threaded conversation. Built as a monorepo showcasing bleeding-edge development practices with AI assistance.

## Overview

Umemee is a block-based content platform designed for visual storytelling and community interaction. Key features include:

- **Block-based posts** (title, meme image, and optional blocks like text, video, GIF, code, file)
- **Quick Commenter** (reply with title + image, promotable to a full post)
- **Composer** with block caps (default 5 per post) and automatic gallery splitting
- **Floating Page UI** with smooth transitions and minimizable panes (on web)
- **Meme dumps/galleries** (multi-post groups stitched into a continuous viewer)
- **Meme templates** (create from predefined layouts, fill text/image segments)
- **Community moderation** (notes/flags, credibility scoring)
- **Attribution & claims** (unclaimed handles like `unclaimed.ted25.twitter` that can be claimed by original creators)
- **Monetization** via physical goods (dropshipping/licensing) and subscriptions (no ads by default)

## Current State

- **Mobile app** scaffolded with Expo + React Navigation
- **Web app** scaffolded with Next.js 15 App Router with Turbopack
- **Desktop app** currently disabled, migrating from Electron to Tauri (see [platforms/desktop/MIGRATION-TO-TAURI.md](platforms/desktop/MIGRATION-TO-TAURI.md))
- Shared packages (`@umemee/types`, `@umemee/config`, `@umemee/utils`, `@umemee/api-client`, `@umemee/ui-web`, `@umemee/ui-mobile`) wired in
- Mock mode planned for both apps (`USE_MOCK_DATA=true`)
- Advanced features (floating pages, composer, templates, attribution) are **specified but not yet implemented**

## Architecture

```
umemee-v0/
├── platforms/
│   ├── mobile/     # React Native (Expo) - iOS/Android
│   ├── web/        # Next.js 15+ with App Router - Responsive web + PWA
│   └── desktop/    # (Migrating) Tauri - Windows/Mac/Linux
├── shared/
│   ├── ui-mobile/  # React Native components
│   ├── ui-web/     # Web-adapted components
│   ├── api-client/ # Unified API layer
│   ├── core/       # Business logic
│   ├── types/      # TypeScript definitions (foundational)
│   ├── config/     # Shared configurations
│   └── utils/      # Common utilities
├── core-modules/   # (Planned) Core business logic modules
├── services/       # (Planned) Backend services via Git subtrees
└── tools/          # Development tools (subtree/worktree management)
```

## Tech Stack

- **Monorepo**: Turborepo + pnpm (>= 9.0.0) for optimal build performance
- **Mobile**: React Native + Expo
- **Web**: Next.js 15+ with App Router, BFF pattern + PWA, Turbopack
- **Desktop**: Tauri (migrating from Electron)
- **Shared**: TypeScript (strict mode), modular packages with workspace protocol
- **State Management**: TanStack Query, Zustand, React Hook Form + Zod
- **CI/CD**: GitHub Actions with platform-specific pipelines
- **Testing**: Jest (unit), Detox (mobile E2E), Playwright (web E2E, to be added)

## Development

```bash
# Install dependencies
pnpm install

# Run all apps in development
pnpm dev

# Build all apps
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

### Mobile
```bash
pnpm dev --filter=@umemee/mobile     # Start Expo dev server
pnpm ios --filter=@umemee/mobile     # Run on iOS simulator
pnpm android --filter=@umemee/mobile # Run on Android emulator
pnpm build --filter=@umemee/mobile   # Export for production
```

### Web
```bash
pnpm dev --filter=@umemee/web        # Start Next.js dev server with Turbopack
pnpm build --filter=@umemee/web      # Production build
pnpm start --filter=@umemee/web      # Start production server
```

### Desktop (Currently Disabled)
```bash
# Desktop commands temporarily disabled during Tauri migration
# See platforms/desktop/MIGRATION-TO-TAURI.md for details
# Will be re-enabled with Tauri
```

## Planned Features (MVP Scope)

### Content
- Posts contain:
  - **Title** (always first)
  - **Main meme block** (image or video)
  - Up to **5 blocks per post** (text, image, video, GIF, quote, poll, code, file)
- Additional posts auto-group into a **gallery (post_group)**
- Comments can target **posts, blocks, or block segments**

### Interaction
- Like / Meh / Dislike reactions
- Quick Commenter: reply with Title + Image → creates child post + comment
- Composer: drag-to-reorder blocks, "Add Block" vs. "Add Post Card"

### UI/UX
- **Floating Pages** with shared-element transitions
- On web: Floating Pages can **minimize into panes** (Gmail chat style)
- Feed supports **grid view, swipe view, and meme chains**
- Comments revealed progressively below posts, with block-anchored options

### Moderation
- Machine filters (Perspective, Rekognition)
- Community notes and flags with credibility scoring
- Visibility tiers (contextualized, soft-hidden, hidden)

### Monetization
- Physical goods (print-on-demand, licensing)
- Subscription options:
  - Creator subscriptions
  - Platform membership (ad-free, early access)
- Attribution model shares revenue between reposter and original creator when claimed

## Git Workflow

This repository uses:
- **Feature branches**: Create from `trunk` branch
- **Git Worktrees**: For parallel feature development (see [tools/worktree/](tools/worktree/))
- **Git Subtrees**: For modular service integration (see [tools/subtree/](tools/subtree/))
- **Conventional Commits**: For automated versioning with changesets

## Roadmap (Next Steps)

1. Align dependencies and scripts with documentation
2. Implement Floating Page navigation with animations
3. Build Quick Commenter and Composer with 5-block cap + gallery split
4. Add Meme Template creation and editing flow
5. Wire mock APIs (`/comments/quick`, `/posts/:id/split`, `/gallery/:groupId`)
6. Add unit tests for new flows and one Detox golden path

## Development Notes

- **Node Version**: Requires Node.js >= 20.0.0
- **Package Manager**: Must use pnpm >= 9.0.0 (don't use npm or yarn)
- **Monorepo management**: PNPM workspaces + Turborepo
- **Mock mode**: Toggleable with env vars (`USE_MOCK_DATA=true`)
- **Testing**: Jest for unit, Detox for mobile E2E, Playwright for web E2E (to be added)
- **Performance**: FlatList/FlashList for feeds, expo-image caching, poster-first video loading
- **Module Resolution**: Use package names (`@umemee/*`) not relative paths for cross-package imports
- **Build Order**: Turborepo handles automatically, but be aware of dependency hierarchy
- **Desktop Platform**: Currently disabled, migrating from Electron to Tauri
- **Documentation**: Every directory must have a [BRIEF.md](BRIEF.md) file

## Metrics

Development progress is measured by:
- Lines of functional code delivered
- Components completed
- API endpoints implemented
- Platform builds passing
- Risk complexity scores per feature

## Contributing

At this stage, the project is still stabilizing its design and core flows.
Contributions should focus on **incremental features that align with the MVP scope** above.

## License

Private - All rights reserved
