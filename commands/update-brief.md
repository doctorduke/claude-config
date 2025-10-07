# /update-brief - BRIEF Documentation Maintenance

Maintain and synchronize BRIEF.md documentation across the umemee-v0 monorepo using the brief-maintainer agent.

## Usage

```bash
/update-brief <subcommand> [options]
```

## Subcommands

### `init` - Initialize BRIEF for New Module
Creates a new BRIEF.md file for a module following the v3 schema.

```bash
/update-brief init [path]
```

**Example:**
```bash
/update-brief init shared/auth
# Creates: shared/auth/BRIEF.md with proper module prefix [AUTH-xxx]
# Sets up: _reference/ directory structure
# Generates: Initial interface contract from package.json exports
```

### `check` - Validate Current Module's BRIEF
Validates BRIEF.md against the v3 schema and checks consistency with code.

```bash
/update-brief check [path]
```

**Example:**
```bash
/update-brief check shared/api-client
# Validates: BRIEF.md schema compliance
# Checks: Work item ID format [API-xxx]
# Verifies: Dependencies match package.json
# Reports: Missing or outdated sections
```

### `sync` - Synchronize BRIEF with Code State
Updates BRIEF.md based on detected code changes and git status.

```bash
/update-brief sync [path]
```

**Example:**
```bash
/update-brief sync platforms/web
# Detects: Modified files since last commit
# Updates: Dependencies from package.json changes
# Prompts: Work State updates for active items
# Suggests: New work items for untracked changes
```

### `sop` - Create Standard Operating Procedure
Creates a new SOP document in `_reference/sop/` for recurring patterns.

```bash
/update-brief sop <name> [--template=<type>]
```

**Example:**
```bash
/update-brief sop turbo-pipeline-setup --template=build
# Creates: _reference/sop/SOP-001-turbo-pipeline-setup.md
# Template: Build configuration SOP template
# Links: Updates relevant BRIEFs with SOP reference
```

## Implementation

This command invokes the **brief-maintainer agent** which:

1. **Analyzes Context**
   - Current git branch and status
   - Modified files from `git diff`
   - Turborepo dependency graph
   - pnpm workspace structure

2. **Module Detection**
   - Identifies affected modules from changed files
   - Maps files to workspace packages
   - Traces dependency impacts

3. **BRIEF Updates**
   - Interface Contract from TypeScript exports
   - Dependencies from package.json
   - Work State from git commits
   - Local Reference Index from _reference/

4. **Work Item Management**
   - Auto-generates module prefixes (e.g., `[WEB-001]`, `[API-002]`)
   - Tracks item progression (Planned → Doing → Done)
   - Links commits to work items
   - Creates GitHub issues (when enabled)

## Workflow Examples

### Starting New Feature
```bash
git checkout -b feature/auth-system
/update-brief init shared/auth
# Implement authentication module...
/update-brief sync shared/auth
git commit -m "feat(auth): implement JWT authentication [AUTH-001]"
```

### After Code Changes
```bash
pnpm add @tanstack/query --filter=@umemee/web
/update-brief sync platforms/web
# Updates dependencies section
# Prompts: "Add work item for TanStack Query integration?"
```

### Creating Build SOP
```bash
/update-brief sop turborepo-caching --template=performance
# Documents caching strategy
# Links from turbo.json BRIEF
```

## Module Prefix Convention

The command automatically assigns module prefixes:

| Directory | Prefix | Example |
|-----------|--------|---------|
| `platforms/web` | WEB | `[WEB-001]` |
| `platforms/mobile` | MOB | `[MOB-001]` |
| `shared/api-client` | API | `[API-001]` |
| `shared/utils` | UTIL | `[UTIL-001]` |
| `shared/types` | TYPE | `[TYPE-001]` |
| `shared/ui-web` | UIW | `[UIW-001]` |
| `shared/ui-mobile` | UIM | `[UIM-001]` |
| `core-modules/*` | Auto-generated | `[AUTH-001]` |

## Options

### Global Options
- `--dry-run` - Preview changes without writing files
- `--verbose` - Show detailed processing steps
- `--format` - Auto-format markdown output

### Sync Options
- `--since=<commit>` - Sync changes since specific commit
- `--all` - Sync all modules with changes
- `--interactive` - Prompt for each change

### Check Options
- `--fix` - Auto-fix minor schema violations
- `--strict` - Enforce all optional sections

## Integration Points

### Git Hooks
Add to `.husky/pre-commit`:
```bash
/update-brief check --all
```

### CI/CD Pipeline
Add to `.github/workflows/ci.yml`:
```yaml
- name: Validate BRIEFs
  run: pnpm exec claude-cli update-brief check --all --strict
```

### Turborepo Tasks
Add to `turbo.json`:
```json
{
  "pipeline": {
    "brief:check": {
      "cache": false,
      "outputs": []
    }
  }
}
```

## Related Documentation

- [`docs/agent-coordination/_reference/spec/brief-maintainer-agent.md`](../../docs/agent-coordination/_reference/spec/brief-maintainer-agent.md) - Brief system overview
- [`docs/agent-coordination/_reference/spec/brief-maintainer-agent.md`](../../docs/agent-coordination/_reference/spec/brief-maintainer-agent.md) - Maintainer agent spec
- [`CLAUDE.md`](../../CLAUDE.md) - Project documentation philosophy
- [`docs/Interface‑First BRIEF System v3 — Spec.md`](../../docs/Interface%E2%80%91First%20BRIEF%20System%20v3%20%E2%80%94%20Spec.md) - BRIEF v3 schema specification

## Notes

- BRIEFs should be <200 lines; details go in `_reference/`
- Work items track actual implementation, not planning
- SOPs capture patterns that repeat across modules
- The agent reads git history to suggest updates
- Manual edits to BRIEFs are preserved during sync
