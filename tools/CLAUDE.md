# CLAUDE.md - Tools Directory

## Purpose
The tools directory contains development tools, build scripts, and utilities that support the umemee monorepo development workflow. These tools handle git subtree/worktree management, code generation, development automation, and other developer experience improvements.

## Dependencies

### Tool Dependencies
- Node.js scripts and CLI tools
- Shell scripts for automation
- Git for version control operations
- External CLI tools as needed

### What Uses Tools
- Developers during local development
- CI/CD pipelines for automation
- Build processes for optimization
- Release processes for versioning

## Key Files

```
tools/
├── subtree/              # Git subtree management
│   ├── add.sh            # Add new subtree
│   ├── update.sh         # Update subtree
│   ├── push.sh           # Push changes
│   └── README.md         # Documentation
├── worktree/             # Git worktree utilities
│   ├── create.sh         # Create worktree
│   ├── list.sh           # List worktrees
│   ├── clean.sh          # Clean worktrees
│   └── README.md         # Documentation
├── scripts/              # Build and dev scripts
│   ├── create-package.js # Package generator
│   ├── check-deps.js     # Dependency checker
│   └── clean.js          # Clean script
└── cli/                  # CLI tools
    ├── umemee-cli.js     # Main CLI
    └── commands/         # CLI commands
```

## Conventions

### Tool Structure
```
{tool-name}/
├── index.js|sh           # Entry point
├── lib/                  # Supporting code
├── config/               # Tool configuration
├── templates/            # Code templates
├── tests/                # Tool tests
└── README.md             # Documentation
```

### Script Naming
- Shell scripts: `kebab-case.sh`
- Node scripts: `kebab-case.js`
- Executable: Mark with shebang and chmod +x

## Testing

### Testing Tools
```bash
# Test shell scripts
shellcheck tools/**/*.sh

# Test Node scripts
pnpm test --filter ./tools

# Integration tests
pnpm test:tools
```

## Common Tasks

### Creating New Tool
```bash
# Create tool directory
mkdir -p tools/new-tool

# For shell script
cat > tools/new-tool/index.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Tool implementation
EOF
chmod +x tools/new-tool/index.sh

# For Node script
cat > tools/new-tool/index.js << 'EOF'
#!/usr/bin/env node

// Tool implementation
EOF
chmod +x tools/new-tool/index.js
```

### Using Tools
```bash
# Run tool directly
./tools/subtree/add.sh

# Run through npm script
pnpm tool:subtree:add

# Run with npx
npx umemee-cli
```

## Gotchas

### Common Issues
1. **Path Issues**: Use absolute paths or resolve relative to script
2. **Shell Compatibility**: Test on bash/zsh/sh
3. **Cross-Platform**: Consider Windows compatibility
4. **Error Handling**: Always handle errors gracefully
5. **Dependencies**: Document required system tools

## Architecture Decisions

### Why Separate Tools?
- **Organization**: Clear location for development utilities
- **Reusability**: Share tools across projects
- **Maintenance**: Easier to update and version
- **Documentation**: Centralized tool documentation

### Tool Selection
- **Shell Scripts**: For git operations and simple automation
- **Node Scripts**: For complex logic and cross-platform needs
- **Python Scripts**: For data processing and ML tasks

## Performance Considerations

- Optimize for developer experience
- Cache results when possible
- Parallel execution where applicable
- Progress indicators for long operations
- Minimal dependencies for fast execution

## Security Notes

### Security Best Practices
- Validate all inputs
- Use secure temp directories
- Never commit credentials
- Sanitize file paths
- Check permissions before operations

### Secure Script Template
```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Validate inputs
[[ -z "${1:-}" ]] && echo "Error: Missing argument" && exit 1

# Use mktemp for temp files
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT
```

## Tool Categories

### Git Management
- Subtree operations
- Worktree management
- Branch automation
- Commit helpers

### Development
- Package generators
- Code scaffolding
- Dev server management
- Hot reload utilities

### Build & Deploy
- Build optimization
- Bundle analysis
- Deploy scripts
- Release automation

### Quality
- Linting automation
- Test runners
- Coverage reporters
- Performance profilers

### Documentation
- Doc generators
- API extractors
- Changelog creators
- README updaters

## Future Enhancements

1. **Unified CLI**: Single entry point for all tools
2. **Plugin System**: Extensible tool architecture
3. **AI Integration**: AI-powered code generation
4. **Cloud Tools**: Cloud development environments
5. **Monitoring**: Development metrics and insights
6. **Automation**: More intelligent automation
7. **Cross-Project**: Share tools across projects
8. **Tool Marketplace**: Community tool sharing