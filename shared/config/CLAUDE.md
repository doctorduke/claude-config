# CLAUDE.md - Config Package

## Purpose
The config package centralizes all configuration management for the umemee monorepo. It provides environment-specific settings, feature flags, API endpoints, and shared constants used across all platforms and packages.

## Dependencies

### Internal Dependencies
- `@umemee/types` - Type definitions for config objects

### External Dependencies
- `dotenv` - Environment variable loading
- `zod` - Runtime validation of config values

## Key Files

```
config/
├── src/
│   ├── index.ts           # Main exports
│   ├── env/               # Environment configs
│   │   ├── schema.ts      # Env var validation
│   │   ├── development.ts # Dev config
│   │   ├── staging.ts     # Staging config
│   │   └── production.ts  # Prod config
│   ├── features/          # Feature flags
│   │   └── flags.ts       # Feature flag definitions
│   ├── api/               # API configuration
│   │   ├── endpoints.ts   # API endpoint URLs
│   │   └── keys.ts        # API key management
│   └── constants/         # Shared constants
│       ├── limits.ts      # System limits
│       └── defaults.ts    # Default values
├── package.json
└── tsconfig.json
```

## Conventions

### Configuration Structure
```typescript
// Environment-based config
export const config = {
  api: {
    baseUrl: process.env.API_URL || 'http://localhost:3000',
    timeout: 30000,
  },
  features: {
    darkMode: getFeatureFlag('DARK_MODE'),
    betaFeatures: getFeatureFlag('BETA_FEATURES'),
  },
  limits: {
    maxFileSize: 10 * 1024 * 1024, // 10MB
    maxDocuments: 1000,
  },
}

// Validation with Zod
const envSchema = z.object({
  API_URL: z.string().url(),
  NODE_ENV: z.enum(['development', 'staging', 'production']),
})
```

## Testing

```bash
# Test configuration loading
pnpm test

# Validate environment variables
pnpm validate:env
```

## Common Tasks

### Adding New Config
1. Define type in `@umemee/types`
2. Add config value with validation
3. Export from appropriate module
4. Document in README

### Environment Variables
- Prefix platform-specific: `WEB_`, `MOBILE_`, `DESKTOP_`
- Use `.env.example` for documentation
- Validate at runtime with Zod
- Never commit actual `.env` files

## Security Notes

- Store secrets in secure vaults, not in code
- Use environment variables for sensitive config
- Validate and sanitize all external config
- Implement proper key rotation
