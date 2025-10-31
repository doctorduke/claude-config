# Legacy Code Documentation Example

**When to use this example**: Documenting existing undocumented code

**Key patterns demonstrated**:
- INFERRED markers for reverse-engineered information
- Security concerns identification
- Migration planning in work state
- Caveats and review requirements

**Related documentation**:
- [PATTERNS.md](../PATTERNS.md) - INFERRED marker guidelines
- [PHILOSOPHY.md](../PHILOSOPHY.md) - Legacy modernization strategies

---

## Example 5: Legacy Code Documentation

### Scenario
Documenting an undocumented legacy authentication module.

### File: `legacy/auth/BRIEF.md`

```markdown
# Legacy Authentication — BRIEF

## Purpose & Boundary
> INFERRED: Based on code analysis of legacy/auth/ directory

Handles user authentication for the legacy monolith application. Manages login, logout, session management, and password hashing. Appears to be replaced gradually by new auth-service but still in active use by older parts of application.

## Interface Contract (Inputs → Outputs)
**Inputs**
> INFERRED: From route handlers and function signatures

- Form POST: `/login` with username, password
- Form POST: `/logout`
- Session cookie: `LEGACY_SESS_ID`
- Config: `AUTH_SECRET` environment variable

**Outputs**
> INFERRED: From response handlers and redirects

- Session cookie on successful login
- Redirect to `/dashboard` on success
- Redirect to `/login?error=invalid` on failure
- Database writes to `sessions` table
- Audit log entries (appears to write to `auth_log` table)

**Performance**
> INFERRED: No explicit SLAs found in code

- Login appears to be synchronous (no async/await)
- Password hashing uses bcrypt (potentially slow, 10 rounds configured)

**Security Concerns**
- Uses MD5 for session IDs (weak, should migrate to crypto.randomBytes)
- No rate limiting apparent in code
- SQL queries use string concatenation (SQL injection risk in username field)

**Anti-Goals**
> INFERRED: Based on missing features
- No OAuth/SSO support
- No two-factor authentication
- No password reset flow (might be in separate module)

## Dependencies & Integration Points
**Upstream**
- MySQL database (`users` and `sessions` tables)
- `bcrypt` library for password hashing

**Downstream**
- Application routes (checks session validity)
- Audit logging system

## Work State (Planned / Doing / Done)
- **Planned**: [LEG-10] Security audit and fixes (owner @security-team, target TBD)
- **Planned**: [LEG-11] Migrate to new auth-service (owner @modernization-team, target Q1 2026)
- **Doing**:   [LEG-08] Fix SQL injection vulnerability (owner @backend-team, started 2025-10-25)
- **Done**:    [LEG-05] Documentation of current behavior (this BRIEF) (completed 2025-10-31)

## SPEC_SNAPSHOT (2025-10-31)
> INFERRED: Based on code as of 2025-10-31

- Features: username/password login, logout, session management, bcrypt password hashing
- Tech: Node.js (Express), MySQL, bcrypt, express-session
- Security: HTTPS enforced, sessions expire after 24h
- Known issues: MD5 session IDs, SQL injection risk, no rate limiting
- Code location: `legacy/auth/routes.js` (main), `legacy/auth/middleware.js` (session check)
- Database schema: `legacy/auth/_reference/spec/db-schema.sql` (reverse-engineered)

## Decisions & Rationale
> INFERRED: No explicit ADRs found

- Unknown date — bcrypt for passwords (industry standard, good choice)
- Unknown date — MD5 for session IDs (weak choice, needs replacement)
- Unknown date — 24h session expiry (reasonable for this app type)

## Local Reference Index
- [Reverse-engineered database schema](legacy/auth/_reference/spec/db-schema.sql)
- [Security audit findings](legacy/auth/_reference/security/audit-2025-10.md)
- [Migration plan to new auth-service](legacy/auth/_reference/planning/migration-plan.md)

## Answer Pack
\```yaml
kind: answerpack
module: legacy/auth
intent: "Legacy authentication system for monolith application"
surfaces:
  web:
    key_flows: ["login form submission", "logout", "session validation"]
    acceptance: ["successful login redirects to /dashboard", "failed login shows error", "session persists 24h"]
work_state:
  planned: ["LEG-10 security audit", "LEG-11 migrate to auth-service"]
  doing: ["LEG-08 fix SQL injection"]
  done: ["LEG-05 documentation"]
interfaces:
  inputs: ["POST /login", "POST /logout", "LEGACY_SESS_ID cookie", "AUTH_SECRET env"]
  outputs: ["session cookie", "redirects", "database writes", "audit logs"]
spec_snapshot_ref: "legacy/auth/_reference/spec/db-schema.sql"
truth_hierarchy: ["source", "tests", "docs", "issues", "chat"]
\```

**NOTE**: This BRIEF has significant INFERRED content. Requires review by someone familiar with legacy codebase.
```

---

## Adaptation Checklist
- [ ] Identify and document all code files (routes, handlers, middleware, utils)
- [ ] Use INFERRED marker for each inference from code analysis
- [ ] Document security concerns found during reverse-engineering
- [ ] Create database schema documentation if needed
- [ ] List known bugs and tech debt in SPEC_SNAPSHOT
- [ ] Add security audit as high-priority planned work
- [ ] Include migration path to modern replacement
- [ ] Mark BRIEF with review requirement statement

## See Also
- [PATTERNS.md](../PATTERNS.md) - INFERRED marker and legacy patterns
- [PHILOSOPHY.md](../PHILOSOPHY.md) - Legacy code analysis techniques
- [EXAMPLES.md](../EXAMPLES.md) - Example index and selection guide
