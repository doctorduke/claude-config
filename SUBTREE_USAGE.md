# Git Subtree Usage Guide for Claude Config

This directory can be distributed and updated across repositories using Git subtrees.

## Why Git Subtree?

Git subtrees allow us to:
- Maintain the same folder structure in all repositories (`.claude/`)
- Easily update the Claude config across all projects
- Share updates without conflicts
- Keep a single source of truth for skills, agents, hooks, and utilities

## Adding This Module to a Repository

### Initial Setup

1. **Add the subtree**:
   ```bash
   git subtree add \
     --prefix=.claude \
     git@github.com:doctorduke/claude-config.git \
     main \
     --squash
   ```

2. **Verify the module structure**:
   ```bash
   ls -la .claude/
   # Should show: agents/, skills/, hooks/, lib/, config/, docs/, etc.
   ```

3. **Configure local settings** (project-specific):
   ```bash
   # Create local settings file (not in subtree)
   cp .claude/config/thresholds.conf .claude/settings.local.json
   # Edit as needed for your project
   ```

### Updating the Module

When updates are made to the config in the source repository:

1. **Pull updates**:
   ```bash
   git subtree pull \
     --prefix=.claude \
     git@github.com:doctorduke/claude-config.git \
     main \
     --squash
   ```

2. **Resolve any conflicts** if they occur (usually in local files)

3. **Push to your repository**:
   ```bash
   git push origin main
   ```

### Pushing Changes Back to the Module

If you make changes to the config that should be shared:

1. **Push to the source repository**:
   ```bash
   git subtree push \
     --prefix=.claude \
     git@github.com:doctorduke/claude-config.git \
     main
   ```

2. **Create a Pull Request** in the source repository to review changes

## Alternative: Using a Remote

For easier management, you can add the source repository as a remote:

```bash
# Add remote
git remote add claude-config git@github.com:doctorduke/claude-config.git

# Pull updates
git subtree pull --prefix=.claude claude-config main --squash

# Push changes
git subtree push --prefix=.claude claude-config main
```

## Module Structure

The module maintains a consistent structure:

```
.claude/
├── README.md              # Module overview (if exists)
├── SUBTREE_USAGE.md       # This file
├── agents/                # Agent definitions (192 files)
├── skills/                # Skill frameworks (~126 files)
├── hooks/                  # Hook scripts (16 files)
├── lib/                    # Utilities and parsers (5 files)
├── config/                 # Configuration templates (5 files)
├── docs/                   # Documentation (5 files)
├── commands/               # Command templates (4 files)
├── expertise/              # Expertise docs (1 file)
└── tests/                  # Test scripts (1 file)
```

## Best Practices

1. **Don't modify files inside `.claude/`** unless you plan to push changes back
2. **Use local files** for project-specific configuration:
   - `.claude/settings.local.json` - Local settings (gitignored)
   - `.claude/logs/` - Log files (gitignored)
3. **Add custom agents locally** if needed (consider pushing back if generic)
4. **Keep hooks registered** - Hooks should work after subtree pull

## Excluded Files (Not in Subtree)

These files are excluded from the subtree and should be project-specific:

- `.claude/logs/` - Generated log files (gitignored)
- `.claude/settings.local.json` - Local project settings (gitignored)
- `.claude/*.local.*` - Local configuration files (gitignored)
- `.claude/investigation-*.md` - Project-specific investigations (gitignored)
- `.claude/orchestration-*.md` - Project-specific docs (gitignored)

## Local Customization

### Adding Custom Agents

You can add custom agents locally:

```bash
# Create custom agent
cat > .claude/agents/my-custom-agent.md << 'EOF'
# My Custom Agent

Agent description here...
EOF

# This file will NOT be pushed back unless you explicitly add it
```

### Overriding Configuration

Use local settings files:

```bash
# .claude/settings.local.json (gitignored)
{
  "project": "my-project",
  "custom_settings": "value"
}
```

## Troubleshooting

### Conflicts During Updates

If you encounter conflicts during updates:

1. **Resolve conflicts** in the module's files:
   ```bash
   # After git subtree pull, if conflicts occur
   git status
   # Edit conflicted files in .claude/
   git add .claude/
   git commit -m "Resolve subtree conflicts"
   ```

2. **Ensure your customizations** are in files outside the subtree (local files)

### Hooks Not Working After Update

1. **Re-register hooks** if needed:
   ```bash
   # In Claude Code, run:
   /hooks
   ```

2. **Verify hook paths** still point to `.claude/hooks/`

### Checking Module Status

```bash
# See what files are part of the subtree
git log --oneline --graph --decorate --prefix=.claude/

# Check when the module was last updated
git log -1 --prefix=.claude/
```

## See Also

- [Git Subtree Documentation](https://git-scm.com/book/en/v2/Git-Tools-Subtree-Merging)
- [Module README](README.md) (if exists)
- [Quick Start Guide](QUICK_START.md) (if exists)

