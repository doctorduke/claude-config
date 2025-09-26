# CLAUDE.md - Git Subtree Tools

## Purpose
The subtree tools provide automated git subtree management for the umemee monorepo. These tools simplify adding, updating, and pushing changes to external repositories that are integrated as subtrees, particularly for the core-modules that may have independent repositories.

## Dependencies

### System Requirements
- Git 2.0+ with subtree support
- Bash 4.0+ for script execution
- Write access to subtree remotes

### Used By
- Core module management
- External library integration
- Shared component repositories

## Key Files

```
subtree/
├── add.sh              # Add new subtree to monorepo
├── update.sh           # Pull updates from upstream
├── push.sh             # Push changes to upstream
├── list.sh             # List all subtrees
├── config.json         # Subtree configuration
└── README.md           # Usage documentation
```

## Conventions

### Subtree Naming
- Remote name: `{module}-origin`
- Branch prefix: `subtree/{module}`
- Commit prefix: `[subtree:{module}]`

### Configuration Format
```json
{
  "subtrees": {
    "core-modules/markdown-editor": {
      "remote": "https://github.com/umemee/markdown-editor.git",
      "branch": "main",
      "prefix": "core-modules/markdown-editor"
    }
  }
}
```

## Common Tasks

### Adding a Subtree
```bash
# Add new subtree
./tools/subtree/add.sh \
  --prefix=core-modules/new-module \
  --remote=https://github.com/org/module.git \
  --branch=main

# Or with config file
./tools/subtree/add.sh --from-config
```

### Updating from Upstream
```bash
# Update specific subtree
./tools/subtree/update.sh core-modules/markdown-editor

# Update all subtrees
./tools/subtree/update.sh --all
```

### Pushing Changes
```bash
# Push to upstream
./tools/subtree/push.sh \
  --prefix=core-modules/markdown-editor \
  --branch=feature-branch

# Force push (careful!)
./tools/subtree/push.sh --force
```

## Gotchas

### Common Issues
1. **Merge Conflicts**: Resolve carefully to maintain history
2. **Squash Commits**: Use --squash to keep history clean
3. **Remote Access**: Ensure SSH keys or tokens are configured
4. **Large History**: Initial add can be slow for large repos
5. **Subtree Strategy**: Changes strategy from normal git workflow

## Architecture Decisions

### Why Git Subtree?
- No .gitmodules file needed
- Complete code in repository
- Works with standard git commands
- Better monorepo integration
- Simpler than submodules

## Security Notes

- Use SSH URLs for private repositories
- Store credentials securely
- Validate remote URLs before operations
- Review changes before pushing upstream

## Best Practices

1. Always squash when pulling updates
2. Create topic branches for subtree changes
3. Document subtree sources in README
4. Regular upstream synchronization
5. Test changes before pushing upstream
