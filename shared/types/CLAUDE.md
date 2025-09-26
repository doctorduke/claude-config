# CLAUDE.md - Types Package

## Purpose
The types package is the foundational type definition library for the umemee monorepo. It provides shared TypeScript types, interfaces, and type utilities used across all platforms and packages, ensuring type safety and consistency throughout the codebase.

## Dependencies

### Internal Dependencies
- None (foundational package)

### External Dependencies
- TypeScript (dev dependency only)

## Key Files

```
types/
├── src/
│   ├── index.ts           # Main exports
│   ├── api/               # API-related types
│   │   ├── requests.ts    # Request types
│   │   ├── responses.ts   # Response types
│   │   └── errors.ts      # Error types
│   ├── domain/            # Domain models
│   │   ├── user.ts        # User types
│   │   ├── document.ts    # Document types
│   │   └── workspace.ts   # Workspace types
│   ├── ui/                # UI-related types
│   │   ├── components.ts  # Component prop types
│   │   └── themes.ts      # Theme types
│   └── utils/             # Utility types
│       ├── helpers.ts     # Type helpers
│       └── branded.ts     # Branded types
├── package.json
└── tsconfig.json
```

## Conventions

### Type Definition Guidelines
```typescript
// Use interfaces for objects that can be extended
export interface User {
  id: string
  email: string
  name: string
}

// Use type aliases for unions, primitives, and utilities
export type UserRole = 'admin' | 'user' | 'guest'
export type UserId = string & { __brand: 'UserId' }

// Use enums sparingly, prefer const assertions
export const Status = {
  PENDING: 'pending',
  ACTIVE: 'active',
  ARCHIVED: 'archived'
} as const
export type Status = typeof Status[keyof typeof Status]
```

## Testing

```bash
# Type checking
pnpm typecheck

# Test type exports
pnpm test:types
```

## Common Tasks

### Adding New Types
```typescript
// 1. Create new type file
// src/domain/new-entity.ts
export interface NewEntity {
  id: string
  // properties
}

// 2. Export from index
// src/index.ts
export * from './domain/new-entity'

// 3. Use in other packages
import { NewEntity } from '@umemee/types'
```

## Architecture Decisions

- No runtime code, only type definitions
- Use branded types for type-safe IDs
- Prefer interfaces for extensibility
- Use const assertions over enums
- Export everything from index for simplicity

## Security Notes

- Never include sensitive values in type definitions
- Use branded types to prevent type confusion attacks
- Document security requirements in type comments
