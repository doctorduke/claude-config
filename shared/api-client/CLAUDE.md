# CLAUDE.md - API Client Package

## Purpose
The api-client package provides a unified, type-safe HTTP client for all backend communication across the umemee platforms. It handles authentication, request/response transformation, error handling, and implements common API patterns.

## Dependencies

### Internal Dependencies
- `@umemee/types` - API type definitions
- `@umemee/config` - API endpoints and configuration
- `@umemee/utils` - Utility functions

### External Dependencies
- `axios` or `ky` - HTTP client library
- `@tanstack/react-query` - React Query integration

## Key Files

```
api-client/
├── src/
│   ├── index.ts           # Main exports
│   ├── client/            # Core client
│   │   ├── base.ts        # Base HTTP client
│   │   ├── auth.ts        # Auth interceptors
│   │   └── errors.ts      # Error handling
│   ├── services/          # API services
│   │   ├── auth.ts        # Auth endpoints
│   │   ├── users.ts       # User endpoints
│   │   └── documents.ts   # Document endpoints
│   ├── hooks/             # React hooks
│   │   ├── useAuth.ts     # Auth hooks
│   │   └── useQuery.ts    # Query hooks
│   └── utils/             # Client utilities
│       ├── retry.ts       # Retry logic
│       └── cache.ts       # Cache management
├── tests/
├── package.json
└── tsconfig.json
```

## Conventions

### API Service Pattern
```typescript
// services/users.ts
export class UserService {
  constructor(private client: ApiClient) {}

  async getUser(id: string): Promise<User> {
    return this.client.get(`/users/${id}`)
  }

  async updateUser(id: string, data: UpdateUserDto): Promise<User> {
    return this.client.patch(`/users/${id}`, data)
  }
}

// Hook usage
export const useUser = (id: string) => {
  return useQuery({
    queryKey: ['user', id],
    queryFn: () => userService.getUser(id),
  })
}
```

## Testing

```bash
# Unit tests
pnpm test

# Integration tests with MSW
pnpm test:integration

# Test API mocking
pnpm test:mock
```

## Common Tasks

### Adding New Endpoints
1. Define types in `@umemee/types`
2. Create service method
3. Add React Query hook
4. Write tests with MSW
5. Document in service file

## Performance Considerations

- Implement request deduplication
- Use proper cache strategies
- Implement optimistic updates
- Handle pagination efficiently
- Use request cancellation

## Security Notes

- Store tokens securely
- Implement CSRF protection
- Use request signing if needed
- Validate all responses
- Handle auth expiration gracefully
