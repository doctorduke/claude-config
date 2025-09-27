# Git Worktree Management

These scripts facilitate parallel development using git worktrees, allowing work on multiple features simultaneously without switching branches.

All worktrees are created in the `.trees/` directory within the repository root for better organization and consistency.

## Creating a Feature Worktree

```bash
./tools/worktree/create-feature.sh <feature-name> [base-branch]
```

Example:
```bash
./tools/worktree/create-feature.sh user-authentication trunk
```

This creates:
- A new branch: `feature/user-authentication`
- A worktree at: `.trees/user-authentication`

## Listing Active Worktrees

```bash
./tools/worktree/list-worktrees.sh
```

Shows all active worktrees and their associated branches.

## Removing a Feature Worktree

```bash
./tools/worktree/remove-feature.sh <feature-name>
```

Example:
```bash
./tools/worktree/remove-feature.sh user-authentication
```

## Benefits of Worktrees

- **Parallel Development**: Work on multiple features simultaneously
- **No Context Switching**: Each feature has its own directory
- **Clean Working State**: No need to stash/unstash changes
- **Faster Builds**: Each worktree maintains its own build cache
- **Independent Testing**: Run tests in parallel across features

## Workflow

1. Create a worktree for your feature:
   ```bash
   ./tools/worktree/create-feature.sh new-feature
   ```

2. Navigate to the worktree:
   ```bash
   cd .trees/new-feature
   ```

3. Install dependencies and start development:
   ```bash
   pnpm install
   pnpm dev
   ```

4. Work on the feature, commit changes as usual

5. Create a pull request when ready

6. After merging, remove the worktree:
   ```bash
   ./tools/worktree/remove-feature.sh new-feature
   ```

## Best Practices

- Use descriptive feature names
- Keep worktrees for active development only
- Clean up worktrees after merging
- Each worktree should focus on a single feature/fix
- Worktrees are automatically created in `.trees/` directory
- The `.trees/` directory is ignored by git for cleaner repository