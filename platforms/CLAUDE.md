# CLAUDE.md - Platforms

## Purpose

The platforms directory contains all platform-specific application implementations for umemee. Each platform shares core business logic and utilities from the shared packages while maintaining platform-specific UI, navigation, and system integrations.

## Dependencies

### Internal Dependencies
- `@umemee/types`: Shared TypeScript definitions
- `@umemee/utils`: Common utility functions
- `@umemee/api-client`: Unified API access
- `@umemee/config`: Shared configuration
- `@umemee/ui-web`: Web UI components (for web platform)
- `@umemee/ui-mobile`: Mobile UI components (for mobile platform)

### External Dependencies
- Platform-specific frameworks (React Native, Next.js, Electron)
- Platform-specific build tools and bundlers

## Key Files

- `mobile/`: React Native application
- `web/`: Next.js web application
- `desktop/`: Electron desktop application
- Each platform has its own package.json, tsconfig.json, and platform-specific configuration

## Conventions

### Directory Structure
```
platform/
├── src/              # Source code
│   ├── app/         # Application routes/screens
│   ├── components/  # Platform-specific components
│   ├── hooks/       # Platform-specific hooks
│   ├── utils/       # Platform-specific utilities
│   └── styles/      # Platform-specific styling
├── public/          # Static assets (web/desktop)
├── assets/          # Static assets (mobile)
├── package.json     # Package configuration
├── tsconfig.json    # TypeScript configuration
└── [platform].config.js  # Platform-specific config
```

### Naming Conventions
- Package names: `@umemee/[platform]` (e.g., `@umemee/web`)
- Entry points: Platform-specific (index.tsx, App.tsx, main.ts)
- Configuration files follow platform conventions

## Testing

### Platform Testing Strategy
```bash
# Test individual platform
pnpm test --filter=@umemee/web
pnpm test --filter=@umemee/mobile
pnpm test --filter=@umemee/desktop

# E2E testing per platform
pnpm e2e:web
pnpm e2e:mobile
pnpm e2e:desktop
```

### Testing Priorities
1. User flows specific to platform
2. Platform API integrations
3. Performance on target devices
4. Accessibility requirements

## Common Tasks

### Start Development Server
```bash
# Web development
pnpm dev --filter=@umemee/web

# Mobile development
pnpm dev --filter=@umemee/mobile

# Desktop development
pnpm dev --filter=@umemee/desktop
```

### Build for Production
```bash
# Build specific platform
pnpm build --filter=@umemee/[platform]

# Build all platforms
pnpm build --filter="./platforms/*"
```

### Add Platform-Specific Dependency
```bash
# Add to specific platform
pnpm add [package] --filter=@umemee/web
```

## Gotchas

### Cross-Platform Gotchas
1. **Import Paths**: Use package aliases, not relative paths for shared code
2. **Platform APIs**: Always check platform availability before using native APIs
3. **Asset Handling**: Different platforms handle assets differently
4. **Environment Variables**: Platform-specific env var loading mechanisms
5. **Bundle Sizes**: Monitor platform-specific bundle sizes independently

### Platform-Specific Issues
- **Web**: SSR vs CSR considerations, SEO requirements
- **Mobile**: iOS vs Android differences, native module linking
- **Desktop**: OS-specific behaviors, code signing requirements

## Architecture Decisions

### Why Separate Platforms?
- Optimal user experience per platform
- Platform-specific optimizations
- Independent deployment cycles
- Specialized developer expertise per platform

### Shared vs Platform-Specific
- **Shared**: Business logic, API calls, data models, utilities
- **Platform-Specific**: UI components, navigation, system integrations, styling

### Platform Selection Criteria
- **Web**: Maximum reach, SEO, instant access
- **Mobile**: Native performance, offline capability, device features
- **Desktop**: Power users, system integration, file system access

## Performance Considerations

### General Performance
- Code splitting strategies per platform
- Lazy loading appropriate to platform
- Asset optimization per platform requirements
- Platform-specific caching strategies

### Platform-Specific Performance
- **Web**: Initial load time, Core Web Vitals, SEO
- **Mobile**: App size, memory usage, battery consumption
- **Desktop**: Startup time, memory footprint, CPU usage

## Security Notes

### Platform Security Requirements
- **Web**: CSP headers, XSS prevention, HTTPS
- **Mobile**: Secure storage, certificate pinning, biometric auth
- **Desktop**: Code signing, secure IPC, sandboxing

### Shared Security Concerns
- API authentication across platforms
- Secure token storage per platform
- Input validation at platform boundaries
- Platform-specific vulnerability scanning

## Platform Feature Matrix

| Feature | Web | Mobile | Desktop |
|---------|-----|---------|---------|
| Offline Support | ⚠️ PWA | ✅ Native | ✅ Native |
| Push Notifications | ⚠️ Web Push | ✅ Native | ✅ Native |
| File System | ❌ Limited | ⚠️ Sandboxed | ✅ Full |
| Biometric Auth | ❌ | ✅ | ⚠️ OS-specific |
| Deep Linking | ✅ | ✅ | ✅ |
| Background Tasks | ❌ | ✅ | ✅ |
| System Tray | ❌ | ❌ | ✅ |

## Development Workflow

### Cross-Platform Development
1. Implement shared logic in core-modules or shared packages
2. Create platform-specific UI implementations
3. Test on all target platforms
4. Optimize per platform requirements
5. Deploy independently per platform

### Platform Coordination
- Regular sync between platform teams
- Shared design system documentation
- Unified API contracts
- Coordinated release planning

## Deployment

### Platform Deployment Targets
- **Web**: Vercel, Netlify, AWS Amplify
- **Mobile**: App Store, Google Play, TestFlight, Internal Distribution
- **Desktop**: Mac App Store, Windows Store, Direct Download

### Deployment Commands
```bash
# Web deployment
pnpm deploy:web

# Mobile deployment
pnpm deploy:mobile:ios
pnpm deploy:mobile:android

# Desktop deployment
pnpm deploy:desktop:mac
pnpm deploy:desktop:windows
pnpm deploy:desktop:linux
```

## Future Considerations

1. Watch OS / TV OS applications
2. Progressive Web App enhancements
3. Platform-specific feature flags
4. A/B testing per platform
5. Platform analytics integration
6. Cross-platform state synchronization