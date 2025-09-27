# CLAUDE.md - Shared Packages Directory

## Purpose
The shared directory contains all reusable packages that are shared across platforms in the umemee monorepo. These packages form the foundation of code reuse, ensuring consistency and reducing duplication across web, mobile, and desktop platforms.

## Dependencies

### Package Dependency Hierarchy
```
shared/
├── types/         # No dependencies (foundational)
├── config/        # Depends on: types
├── utils/         # Depends on: types
├── api-client/    # Depends on: types, config, utils
├── ui-web/        # Depends on: types, utils
└── ui-mobile/     # Depends on: types, utils
```

### What Depends on Shared
- All platform implementations (`platforms/*`)
- Core business modules (`core-modules/*`)
- Backend services (`services/*`)

## Key Files

### Package Structure Template
```
{package}/
├── src/
│   ├── index.ts        # Main exports
│   ├── types.ts        # Type definitions
│   └── [feature]/      # Feature modules
├── tests/
│   └── *.test.ts       # Test files
├── package.json         # Package configuration
├── tsconfig.json        # TypeScript config
├── README.md           # Package documentation
└── CLAUDE.md           # AI development guide
```

## Conventions

### Package Naming
- Package scope: `@umemee/{package-name}`
- Directory names: lowercase with hyphens
- Export names: PascalCase for types/classes, camelCase for functions

### Export Strategy
```typescript
// src/index.ts - Barrel exports
export * from './types'
export * from './utils'
export { specific } from './specific'

// Avoid default exports for better tree-shaking
export const myUtil = () => {}
export type MyType = {}
```

### Version Management
- Use workspace protocol: `"workspace:*"` for internal deps
- Synchronize versions across related packages
- Use changesets for version bumping

## Testing

### Testing Shared Packages
```bash
# Test all shared packages
pnpm test --filter "./shared/*"

# Test specific package
pnpm test --filter @umemee/utils

# Watch mode
pnpm test:watch --filter @umemee/api-client

# Coverage
pnpm test:coverage --filter "./shared/*"
```

### Test Requirements
- Minimum 80% coverage for utilities
- Type testing for TypeScript exports
- Cross-platform compatibility tests
- Performance benchmarks for critical paths

## Common Tasks

### Creating New Shared Package
```bash
# 1. Create package directory
mkdir -p shared/new-package/src
cd shared/new-package

# 2. Initialize package
pnpm init

# 3. Configure package.json
cat > package.json << 'EOF'
{
  "name": "@umemee/new-package",
  "version": "0.0.1",
  "main": "./src/index.ts",
  "types": "./src/index.ts",
  "scripts": {
    "test": "vitest",
    "typecheck": "tsc --noEmit"
  }
}
EOF

# 4. Create TypeScript config
echo '{ "extends": "../../tsconfig.json" }' > tsconfig.json

# 5. Create entry point
echo 'export {}' > src/index.ts
```

### Adding Dependencies
```bash
# Add to specific shared package
pnpm --filter @umemee/utils add lodash

# Add dev dependency
pnpm --filter @umemee/api-client add -D @types/node

# Add workspace dependency
pnpm --filter @umemee/api-client add @umemee/types@workspace:*
```

## Gotchas

### Common Issues
1. **Circular Dependencies**: Avoid packages depending on each other
2. **Platform-Specific Code**: Keep platform code in ui-web/ui-mobile
3. **Side Effects**: Avoid global mutations in shared packages
4. **Bundle Size**: Monitor package size impact on platforms
5. **Type Exports**: Ensure proper type exports for TypeScript

### Best Practices
- Keep packages focused and single-purpose
- Document all public APIs
- Version packages together when possible
- Use peer dependencies for framework dependencies
- Test on all target platforms

## Architecture Decisions

### Why Separate Shared Packages?
- **Modularity**: Clear boundaries and responsibilities
- **Reusability**: Use across multiple platforms
- **Testability**: Isolated testing of functionality
- **Maintainability**: Easier to update and version
- **Tree-shaking**: Better dead code elimination

### Package Responsibilities

#### types/
- Shared TypeScript type definitions
- API contracts and interfaces
- Domain models
- Utility types

#### config/
- Environment configuration
- Feature flags
- API endpoints
- Constants and enums

#### utils/
- Pure utility functions
- Date/time helpers
- String manipulation
- Data transformations

#### api-client/
- HTTP client wrapper
- API method implementations
- Request/response interceptors
- Error handling

#### ui-web/
- React components for web
- Web-specific hooks
- Browser-specific utilities
- CSS-in-JS styles

#### ui-mobile/
- React Native components
- Mobile-specific hooks
- Native module wrappers
- Platform-specific styles

## Performance Considerations

### Bundle Size Optimization
```json
// package.json - Specify side effects
{
  "sideEffects": false,
  "exports": {
    ".": {
      "import": "./src/index.ts",
      "require": "./src/index.ts"
    },
    "./utils": "./src/utils/index.ts"
  }
}
```

### Code Splitting Support
```typescript
// Support dynamic imports
export const lazyLoadFeature = () => 
  import('./features/heavy-feature')
```

### Performance Guidelines
- Keep initial bundle small
- Use lazy loading for heavy features
- Implement proper tree-shaking
- Monitor package size with bundlephobia
- Use performance budgets

## Security Notes

### Security Considerations
- Never include secrets or API keys
- Validate inputs at package boundaries
- Sanitize data in utils package
- Use secure random generation
- Implement proper encryption utilities

### Secure Patterns
```typescript
// utils/crypto.ts
import { randomBytes } from 'crypto'

export const generateSecureToken = (): string => {
  return randomBytes(32).toString('hex')
}

export const sanitizeInput = (input: string): string => {
  // Implement sanitization
  return input.replace(/<script>/gi, '')
}
```

## Documentation Standards

### Package Documentation
```typescript
/**
 * Formats a date according to the specified format
 * @param date - The date to format
 * @param format - The format string
 * @returns Formatted date string
 * @example
 * ```ts
 * formatDate(new Date(), 'YYYY-MM-DD')
 * // Returns: '2024-01-15'
 * ```
 */
export function formatDate(date: Date, format: string): string {
  // Implementation
}
```

### API Documentation
- Use TSDoc comments for all exports
- Provide usage examples
- Document edge cases
- Include migration guides
- Maintain changelog

## Publishing Strategy

### Internal Consumption
```json
// For internal monorepo use
{
  "private": true,
  "main": "./src/index.ts",
  "types": "./src/index.ts"
}
```

### External Publishing
```json
// For npm publishing
{
  "private": false,
  "main": "./dist/index.js",
  "types": "./dist/index.d.ts",
  "files": ["dist"],
  "scripts": {
    "prepublishOnly": "pnpm build"
  }
}
```

## Quality Assurance

### Quality Checklist
- [ ] TypeScript strict mode enabled
- [ ] ESLint rules passing
- [ ] Unit tests with >80% coverage
- [ ] API documentation complete
- [ ] No circular dependencies
- [ ] Bundle size acceptable
- [ ] Cross-platform compatibility verified
- [ ] Security review completed

## Migration Guide

### Moving Code to Shared
1. Identify reusable code in platforms
2. Extract to appropriate shared package
3. Add necessary abstractions
4. Update platform imports
5. Test on all platforms
6. Update documentation

### Breaking Changes
```typescript
// Mark deprecated APIs
/**
 * @deprecated Use `newFunction` instead
 */
export const oldFunction = () => {
  console.warn('oldFunction is deprecated')
  return newFunction()
}
```

## Future Considerations

1. Consider monorepo-wide type checking
2. Implement automated API documentation
3. Add visual regression testing for UI packages
4. Create shared testing utilities package
5. Implement shared state management
6. Add internationalization package
7. Create shared validation schemas
8. Implement shared error handling