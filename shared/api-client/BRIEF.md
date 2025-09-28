# API Client — BRIEF

## Purpose & Boundary

Unified HTTP client for all backend communication across umemee platforms. Provides type-safe API calls, authentication, error handling, and request/response transformation.

**Submodules:**
- `client/` — Core HTTP client with interceptors
- `services/` — Domain-specific API endpoints
- `hooks/` — React Query integration hooks
- `utils/` — Retry logic and cache management

## Interface Contract (Inputs → Outputs)

**Inputs**
- API endpoint definitions from `@umemee/config`
- Type definitions from `@umemee/types`
- Authentication tokens from platform storage
- Request data (GET/POST/PATCH/DELETE payloads)
- Query parameters and pagination cursors

**Outputs**
- Typed promises with API response data
- Normalized error objects with retry info
- Request cancellation tokens
- Cache invalidation triggers
- Auth refresh side effects

**API Communication Patterns**
- Service classes wrap endpoint groups
- React Query hooks provide caching/dedup
- Interceptors handle auth injection
- Exponential backoff on retries
- Request/response transformation pipelines

**Anti-Goals**
- Direct platform-specific UI rendering
- Business logic beyond API contracts
- Local state management (use stores)
- WebSocket/SSE connections (separate package)

## Dependencies & Integration Points

**Upstream:**
- `@umemee/types` — API contracts and DTOs
- `@umemee/config` — Endpoints and environment config
- `@umemee/utils` — Shared utility functions

**Downstream Consumers:**
- `platforms/web` — Next.js app uses hooks
- `platforms/mobile` — React Native uses services
- `platforms/desktop` — (Future) Tauri integration

**External:**
- HTTP client (axios/ky decision pending)
- `@tanstack/react-query` for cache management

## Work State (Planned / Doing / Done)

**Planned:**
- Implement base HTTP client with axios
- Add auth interceptor with token refresh
- Create user service with CRUD endpoints
- Setup React Query provider and hooks
- Add MSW for integration testing

**Doing:**
- Migrating from old API structure

**Done:**
- Package scaffolding and dependencies

## Spec Snapshot (2025-09-27)

- **Features:** Type-safe API calls, auth handling, request retry, cache management
- **Tech:** TypeScript, axios/ky, React Query, MSW for testing
- **Patterns:** Service classes, interceptor chains, optimistic updates
- **Testing:** Unit tests with vitest, integration with MSW

## Decisions & Rationale

- **2025-09-27** — Service class pattern over individual functions (better organization)
- **2025-09-27** — React Query for cache (battle-tested, good DX)
- **2025-09-27** — Separate hooks from services (platform flexibility)

## Local Reference Index

- **client/** → Core HTTP implementation
  - `base.ts` — Axios/ky wrapper with defaults
  - `auth.ts` — Token injection and refresh logic
  - `errors.ts` — Error normalization and codes
- **services/** → Domain API endpoints
  - `auth.ts` — Login/logout/refresh endpoints
  - `users.ts` — User CRUD operations
  - `documents.ts` — Document management
- **hooks/** → React Query wrappers
  - `useAuth.ts` — Auth state and mutations
  - `useQuery.ts` — Generic query builder
- **utils/** → Support utilities
  - `retry.ts` — Exponential backoff logic
  - `cache.ts` — Cache key generation

## Answer Pack

```yaml
kind: answerpack
module: shared/api-client
intent: "Unified type-safe HTTP client for backend API communication"
surfaces:
  all_platforms:
    key_flows: ["authenticate", "fetch-data", "mutate-data", "handle-errors"]
    acceptance: ["type-safe responses", "auto-retry on failure", "token refresh"]
work_state:
  planned: ["base-client", "auth-interceptor", "user-service", "react-query", "msw-tests"]
  doing: ["migration-from-old-api"]
  done: ["package-setup"]
interfaces:
  inputs: ["api-endpoints", "type-defs", "auth-tokens", "request-data"]
  outputs: ["typed-promises", "error-objects", "cache-triggers", "auth-refresh"]
spec_snapshot_ref: shared/api-client/CLAUDE.md
truth_hierarchy: ["source", "tests", "BRIEF", "CLAUDE", "issues"]
```