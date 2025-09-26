# CLAUDE.md - umemee-v0 Monorepo

## Purpose

This is the root of the umemee-v0 monorepo, a mobile-first multi-platform application showcasing bleeding-edge development practices. The project demonstrates modern cross-platform development with shared code, modular architecture, and efficient monorepo management using pnpm workspaces and Turborepo.

## Project Architecture

```
umemee-v0/
├── platforms/          # Platform-specific applications
│   ├── mobile/        # React Native mobile app
│   ├── web/           # Next.js web application
│   └── desktop/       # Electron desktop application
├── shared/            # Shared packages across platforms
│   ├── ui-mobile/     # React Native UI components
│   ├── ui-web/        # React web UI components
│   ├── types/         # TypeScript type definitions
│   ├── config/        # Shared configuration
│   ├── utils/         # Utility functions
│   └── api-client/    # API client library
├── core-modules/      # Core business logic modules
│   ├── markdown-editor/  # (Planned) Markdown editing engine
│   ├── tiptap-mobile/   # (Planned) TipTap editor for mobile
│   └── block-system/    # (Planned) Block-based content system
├── services/          # Backend services (future)
└── tools/            # Development tools
    ├── subtree/      # Git subtree management
    └── worktree/     # Git worktree utilities
```

## Development Workflow

### Initial Setup
```bash
# Install dependencies
pnpm install

# Build all packages
pnpm build

# Start development servers
pnpm dev
```

### Daily Development
```bash
# Work on specific platform
pnpm dev --filter=@umemee/web
pnpm dev --filter=@umemee/mobile

# Run tests across monorepo
pnpm test

# Type checking
pnpm typecheck

# Linting
pnpm lint

# Format code
pnpm format
```

## Dependencies

### Runtime Requirements
- Node.js >= 23.11.0
- pnpm >= 9.0.0

### Key Technologies
- **Build System**: Turborepo for parallel builds and caching
- **Package Manager**: pnpm for efficient dependency management
- **Version Control**: Git with subtree/worktree strategies
- **Change Management**: Changesets for versioning and changelog

## Monorepo Management

### Workspace Structure
```json
{
  "workspaces": [
    "platforms/*",
    "shared/*",
    "core-modules/*",
    "services/*"
  ]
}
```

### Adding New Packages
1. Create package directory under appropriate workspace
2. Initialize with `pnpm init`
3. Set package name following convention: `@umemee/package-name`
4. Add to turbo.json pipeline if needed
5. Update dependencies in consuming packages

### Dependency Management
```bash
# Add dependency to specific package
pnpm add <package> --filter=@umemee/web

# Add shared dependency to root
pnpm add -D <package> -w

# Update dependencies
pnpm update --recursive

# Check for outdated packages
pnpm outdated --recursive
```

## Build and Deploy

### Build Pipeline
```bash
# Production build
pnpm build

# Build specific platform
pnpm build --filter=@umemee/web

# Clean build artifacts
pnpm clean
```

### Deployment Strategies
- **Web**: Deploy to Vercel/Netlify via Next.js
- **Mobile**: Build via EAS Build or local Xcode/Android Studio
- **Desktop**: Package with Electron Forge

## Documentation Philosophy

### Documentation Structure
```
package/
├── CLAUDE.md      # AI development instructions
├── BRIEF.md       # Human-readable overview
└── _reference/    # Technical reference docs
    ├── api.md     # API documentation
    ├── arch.md    # Architecture decisions
    └── perf.md    # Performance notes
```

### Documentation Principles
1. **CLAUDE.md**: Comprehensive AI instructions for development
2. **BRIEF.md**: Concise human-readable summaries
3. **_reference/**: Detailed technical documentation
4. **Inline Comments**: Implementation-specific details
5. **Type Definitions**: Self-documenting TypeScript interfaces

## Git Strategies

### Subtree Management
```bash
# Add external repository as subtree
git subtree add --prefix=core-modules/markdown-editor \
  https://github.com/org/markdown-editor main --squash

# Update subtree
git subtree pull --prefix=core-modules/markdown-editor \
  https://github.com/org/markdown-editor main --squash

# Push changes back
git subtree push --prefix=core-modules/markdown-editor \
  https://github.com/org/markdown-editor feature-branch
```

### Worktree Management
```bash
# Create worktree for feature development
git worktree add ../umemee-feature feature-branch

# List worktrees
git worktree list

# Remove worktree
git worktree remove ../umemee-feature
```

## Cross-Platform Guidelines

### Code Sharing Strategy
1. **Types**: Shared across all platforms via `@umemee/types`
2. **Utils**: Platform-agnostic utilities in `@umemee/utils`
3. **API Client**: Unified API access via `@umemee/api-client`
4. **UI Components**: Separate packages for web and mobile UI
5. **Business Logic**: Core modules shared where possible

### Platform-Specific Considerations
- **Web**: Server-side rendering, SEO optimization
- **Mobile**: Native performance, offline capabilities
- **Desktop**: System integration, file system access

## Testing Strategy

### Test Levels
1. **Unit Tests**: Per package with Jest/Vitest
2. **Integration Tests**: Cross-package functionality
3. **E2E Tests**: Platform-specific user flows
4. **Performance Tests**: Build time and runtime metrics

### Running Tests
```bash
# All tests
pnpm test

# Specific package
pnpm test --filter=@umemee/utils

# Watch mode
pnpm test:watch

# Coverage
pnpm test:coverage
```

## Performance Considerations

### Build Performance
- Turborepo caching for incremental builds
- Parallel execution of independent tasks
- Remote caching for CI/CD (when configured)

### Runtime Performance
- Code splitting per platform
- Tree shaking for optimal bundle sizes
- Lazy loading of features
- Shared dependencies deduplication

## Security Notes

### Development Security
- Husky pre-commit hooks for security checks
- Dependency vulnerability scanning
- Environment variable management
- Secrets never committed to repository

### Production Security
- Platform-specific security configurations
- API authentication and authorization
- Input validation at boundaries
- Regular dependency updates

## Common Tasks

### Create New Feature
```bash
# 1. Create feature branch
git checkout -b feature/new-feature

# 2. Develop across packages
pnpm dev

# 3. Run tests
pnpm test

# 4. Create changeset
pnpm changeset

# 5. Commit and push
git add .
git commit -m "feat: add new feature"
git push origin feature/new-feature
```

### Release Process
```bash
# 1. Update versions
pnpm changeset version

# 2. Build all packages
pnpm build

# 3. Publish (if applicable)
pnpm changeset publish

# 4. Tag and push
git push --follow-tags
```

## Conventions

### Naming Conventions
- **Packages**: `@umemee/package-name` (kebab-case)
- **Components**: PascalCase (e.g., `ButtonPrimary`)
- **Utilities**: camelCase (e.g., `formatDate`)
- **Types**: PascalCase with suffix (e.g., `UserType`, `ApiResponse`)
- **Files**: kebab-case for utilities, PascalCase for components

### Code Style
- TypeScript for type safety
- ESLint for linting
- Prettier for formatting
- Conventional commits for version management

## Architecture Decisions

### Why Monorepo?
- Code sharing between platforms
- Atomic changes across packages
- Unified versioning and deployment
- Consistent development experience

### Why pnpm + Turborepo?
- **pnpm**: Efficient disk usage, strict dependencies
- **Turborepo**: Parallel builds, intelligent caching
- Together: Fast, reliable monorepo management

### Why Separate UI Libraries?
- Platform-specific optimizations
- Native look and feel per platform
- Shared design tokens and theming
- Independent evolution of UI components

## Gotchas

### Common Issues
1. **Workspace Resolution**: Always use `@umemee/` prefix for internal packages
2. **Build Order**: Turborepo handles automatically, but check turbo.json for pipeline
3. **Platform Dependencies**: Keep platform-specific deps in respective packages
4. **Type Exports**: Ensure proper exports in package.json for TypeScript
5. **Cache Invalidation**: Use `pnpm clean` if builds seem stale

### Troubleshooting
```bash
# Clear all caches
pnpm clean
rm -rf node_modules
pnpm install

# Verify workspace setup
pnpm ls --depth=0

# Check Turborepo pipeline
pnpm turbo run build --dry-run
```

## Key Files

- `package.json`: Root package configuration and scripts
- `pnpm-workspace.yaml`: Workspace package locations
- `turbo.json`: Turborepo pipeline configuration
- `.npmrc`: pnpm configuration
- `tsconfig.json`: Root TypeScript configuration
- `.eslintrc.json`: Linting rules
- `.prettierrc`: Code formatting rules
- `.husky/`: Git hooks configuration

## Next Steps

1. Set up CI/CD pipeline
2. Configure remote caching for Turborepo
3. Implement core-modules architecture
4. Add E2E testing framework
5. Set up monitoring and analytics
6. Document API contracts
7. Create design system documentation