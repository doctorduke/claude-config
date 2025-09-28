# Git Worktree Management — BRIEF

## Purpose & Boundary
Git worktree automation layer. Transforms branch operations into isolated development environments for parallel feature work, code reviews, and hotfix workflows in the umemee monorepo.

## Interface Contract

```yaml
accepts:
  - branch_names: "feature/* | hotfix/* | review/*"
  - base_branches: "trunk | main | develop"
  - cleanup_requests: "merged | stale | named"

provides:
  - worktrees: ".trees/{feature-name}/"
  - isolation: "parallel development environments"
  - state_preservation: "working directory persistence"

guarantees:
  - shared_objects: "single git database"
  - branch_exclusivity: "one worktree per branch"
  - automatic_cleanup: "post-merge removal"
```

## Dependencies & Integration Points

```yaml
requires:
  - git: ">=2.15 with worktree support"
  - bash: ">=4.0 for script execution"
  - disk_space: "working copy per worktree"

integrates_with:
  - pnpm_workspaces: "independent node_modules"
  - turborepo: "separate build caches"
  - ci_cd: "parallel testing pipelines"
```

## Work State

```yaml
active_scripts:
  - create-feature.sh: "operational"
  - list-worktrees.sh: "operational"
  - remove-feature.sh: "operational"

planned_scripts:
  - sync.sh: "sync with base branch"
  - switch.sh: "quick worktree switching"
  - clean.sh: "batch cleanup operations"

worktree_location: ".trees/"
naming_pattern: "{type}-{identifier}"
```

## Spec Snapshot (2025-09-27)

Operational git worktree management with create/list/remove capabilities. Planned expansion to include sync, switch, and batch cleanup operations. All worktrees isolated in `.trees/` directory.

## Decisions & Rationale

1. **`.trees/` directory**: Centralized, gitignored location for all worktrees
2. **Shared object database**: Efficient disk usage vs multiple clones
3. **Feature-branch naming**: Automatic `feature/*` prefixing for consistency
4. **Script-based approach**: Simple bash automation over complex tooling

## Local Reference Index

- `CLAUDE.md`: Detailed implementation guide and workflows
- `README.md`: Usage documentation and best practices
- `create-feature.sh`: Worktree creation implementation
- `list-worktrees.sh`: Active worktree enumeration
- `remove-feature.sh`: Cleanup and removal logic

## Answer Pack

```yaml
what: "Git worktree management automation"
why: "Enable parallel development without branch switching"
how: "Shell scripts orchestrating git worktree commands"
when: "Feature development, code reviews, hotfixes"
where: ".trees/ directory within repository"
who: "Developers needing parallel workflows"
```