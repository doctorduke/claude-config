# CLAUDE.md - Git Worktree Tools

## Purpose
The worktree tools provide automated git worktree management for parallel development workflows in the umemee monorepo. These tools enable working on multiple branches simultaneously without the overhead of multiple full repository clones, perfect for feature development, bug fixes, and code reviews.

## Dependencies

### System Requirements
- Git 2.15+ with worktree support
- Sufficient disk space for worktrees
- Bash 4.0+ for script execution

### Used By
- Parallel feature development
- Quick branch switching
- Code review workflows
- Hotfix development

## Key Files

```
worktree/
├── create.sh           # Create new worktree
├── list.sh            # List active worktrees
├── clean.sh           # Remove worktrees
├── switch.sh          # Switch between worktrees
├── sync.sh            # Sync worktree with main
├── config.json        # Worktree configuration
└── README.md          # Usage documentation
```

## Conventions

### Worktree Naming
- Directory pattern: `../umemee-{branch-name}`
- Feature branches: `../umemee-feature-{name}`
- Hotfix branches: `../umemee-hotfix-{issue}`
- Review branches: `../umemee-review-{pr-number}`

### Directory Structure
```
parent-directory/
├── umemee-v0/          # Main repository
├── umemee-feature-x/   # Feature worktree
├── umemee-hotfix-123/  # Hotfix worktree
└── umemee-review-456/  # Review worktree
```

## Common Tasks

### Creating Worktree
```bash
# Create worktree for new feature
./tools/worktree/create.sh feature/new-feature

# Create from existing branch
./tools/worktree/create.sh --branch origin/feature-branch

# Create with custom path
./tools/worktree/create.sh --path ../custom-path feature/branch
```

### Managing Worktrees
```bash
# List all worktrees
./tools/worktree/list.sh

# Switch to worktree
./tools/worktree/switch.sh feature-x

# Clean up finished worktrees
./tools/worktree/clean.sh feature-x

# Clean all merged worktrees
./tools/worktree/clean.sh --merged
```

### Syncing Changes
```bash
# Sync with main branch
./tools/worktree/sync.sh

# Sync specific worktree
./tools/worktree/sync.sh --worktree feature-x

# Force sync (careful!)
./tools/worktree/sync.sh --force
```

## Gotchas

### Common Issues
1. **Locked Worktrees**: Remove lock files if git crashes
2. **Disk Space**: Worktrees share object database but need working copy space
3. **Branch Conflicts**: Can't checkout same branch in multiple worktrees
4. **Submodules**: Need to be initialized in each worktree
5. **Node Modules**: Each worktree needs its own node_modules

## Architecture Decisions

### Why Git Worktree?
- Instant branch switching
- Parallel development workflows
- Shared git object database
- Preserve working directory state
- Better than multiple clones

## Security Notes

- Worktrees share git config and hooks
- Ensure proper file permissions
- Clean up temporary worktrees
- Don't commit sensitive data

## Best Practices

1. One worktree per feature/fix
2. Clean up after merging
3. Use descriptive worktree names
4. Regular main branch sync
5. Document active worktrees in team

## Workflow Examples

### Feature Development
```bash
# Start feature
./tools/worktree/create.sh feature/awesome-feature
cd ../umemee-feature-awesome-feature
pnpm install
pnpm dev

# Work on feature...

# Sync with main
./tools/worktree/sync.sh

# After merge
./tools/worktree/clean.sh feature-awesome-feature
```

### Code Review
```bash
# Review PR
./tools/worktree/create.sh --branch origin/pr/123 review-123
cd ../umemee-review-123
pnpm install
pnpm test

# After review
./tools/worktree/clean.sh review-123
```
