# CLAUDE.md - Utils Package

## Purpose
The utils package provides common utility functions used across all platforms in the umemee monorepo. It contains pure, side-effect-free functions for data manipulation, formatting, validation, and other common operations.

## Dependencies

### Internal Dependencies
- `@umemee/types` - Type definitions

### External Dependencies
- `date-fns` - Date manipulation
- `lodash` - Utility functions (cherry-picked)

## Key Files

```
utils/
├── src/
│   ├── index.ts           # Main exports
│   ├── date/              # Date utilities
│   │   ├── format.ts      # Date formatting
│   │   └── parse.ts       # Date parsing
│   ├── string/            # String utilities
│   │   ├── format.ts      # String formatting
│   │   └── validate.ts    # String validation
│   ├── array/             # Array utilities
│   │   ├── sort.ts        # Sorting helpers
│   │   └── filter.ts      # Filtering helpers
│   ├── object/            # Object utilities
│   │   ├── merge.ts       # Object merging
│   │   └── pick.ts        # Object picking
│   └── crypto/            # Cryptography utils
│       ├── hash.ts        # Hashing functions
│       └── random.ts      # Random generation
├── tests/
├── package.json
└── tsconfig.json
```

## Conventions

### Utility Function Guidelines
```typescript
// Pure functions only
export const formatDate = (date: Date, format: string): string => {
  // No side effects
  return formattedDate
}

// Use descriptive names
export const isValidEmail = (email: string): boolean => {
  return EMAIL_REGEX.test(email)
}

// Add JSDoc comments
/**
 * Debounces a function call
 * @param fn Function to debounce
 * @param delay Delay in milliseconds
 */
export const debounce = <T extends (...args: any[]) => any>(
  fn: T,
  delay: number
): T => {
  // Implementation
}
```

## Testing

```bash
# Run tests
pnpm test

# Test with coverage
pnpm test:coverage

# Run specific test
pnpm test format.test.ts
```

## Common Tasks

### Adding New Utilities
1. Create function in appropriate module
2. Add comprehensive tests
3. Export from module index
4. Export from package index
5. Document with JSDoc

## Performance Considerations

- Avoid creating unnecessary objects
- Use memoization for expensive operations
- Prefer native methods when available
- Keep functions small and focused

## Security Notes

- Validate all inputs
- Use crypto module for security-sensitive operations
- Never use Math.random() for security
- Sanitize user input in string utilities
