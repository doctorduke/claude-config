# Umemee v0

Mobile-first multi-platform application showcasing bleeding-edge development with AI assistance.

## Architecture

```
umemee-v0/
├── apps/
│   ├── mobile/     # React Native (Expo) - iOS/Android
│   ├── web/        # Next.js - Responsive web + PWA
│   └── desktop/    # Electron - Windows/Mac/Linux
├── packages/
│   ├── ui-mobile/  # Mobile-first React Native components
│   ├── ui-web/     # Web-adapted components
│   ├── api-client/ # Shared API layer
│   ├── core/       # Business logic
│   ├── types/      # TypeScript definitions
│   └── config/     # Shared configurations
└── services/       # Git subtrees for modular services
```

## Tech Stack

- **Monorepo**: Turborepo + pnpm for optimal build performance
- **Mobile**: React Native + Expo
- **Web**: Next.js with BFF pattern + PWA
- **Desktop**: Electron + embedded Next.js
- **Shared**: TypeScript, modular packages
- **CI/CD**: GitHub Actions with platform-specific pipelines

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
```

## Platform-Specific Commands

### Mobile
```bash
pnpm --filter @umemee/mobile dev
pnpm --filter @umemee/mobile ios
pnpm --filter @umemee/mobile android
```

### Web
```bash
pnpm --filter @umemee/web dev
pnpm --filter @umemee/web build
```

### Desktop
```bash
pnpm --filter @umemee/desktop dev
pnpm --filter @umemee/desktop build
```

## Git Workflow

This repository uses:
- **Git Worktrees** for parallel feature development
- **Git Subtrees** for modular service integration

## Metrics

Development progress is measured by:
- Lines of functional code delivered
- Components completed
- API endpoints implemented
- Platform builds passing
- Risk complexity scores per feature

## License

Private - All rights reserved