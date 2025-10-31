# Claude Configuration Module

Reusable Claude Code configuration, skills, agents, hooks, and utilities that can be shared across projects via git subtree.

## Overview

This module provides:
- **192 Agent Definitions** - Specialized AI agents for various domains
- **126 Skill Frameworks** - Reusable skill templates and patterns
- **16 Hook Scripts** - Log sanitization and session management
- **Utilities** - Parsers, filters, and core utilities
- **Configuration Templates** - Reusable configs and thresholds
- **Documentation** - Guides and reference materials

## Directory Structure

```
.claude/
├── README.md              # This file
├── SUBTREE_USAGE.md       # Git subtree usage guide
├── QUICK_START.md         # Quick start guide
├── agents/                # Agent definitions (192 files)
├── skills/                # Skill frameworks (126 files)
├── hooks/                  # Hook scripts (16 files)
├── lib/                    # Utilities and parsers (5 files)
├── config/                 # Configuration templates (6 files)
├── docs/                   # Documentation (5 files)
├── commands/               # Command templates (4 files)
├── expertise/              # Expertise docs (1 file)
└── tests/                  # Test scripts (1 file)
```

## Quick Start

### Using as Subtree

1. **Add to your repository**:
   ```bash
   git subtree add \
     --prefix=.claude \
     git@github.com:doctorduke/claude-config.git \
     main \
     --squash
   ```

2. **Configure hooks** (in Claude Code):
   ```bash
   /hooks
   # Add PostToolUse -> Bash -> .claude/hooks/sanitize_bash_output.sh
   ```

3. **Register agents**: Agents are automatically available in `agents/`

See [SUBTREE_USAGE.md](SUBTREE_USAGE.md) for detailed instructions.

## Components

### Agents (`agents/`)
192 specialized agent definitions covering:
- Development (backend-architect, frontend-developer, etc.)
- Architecture (ai-systems-architect, cloud-architect, etc.)
- Security (security-architect, security-auditor, etc.)
- Operations (devops-troubleshooter, incident-responder, etc.)
- Data & AI (data-scientist, mlops-engineer, ai-engineer, etc.)
- And many more...

### Skills (`skills/`)
126 skill framework files including:
- Architecture evaluation framework
- Multi-agent coordination framework
- Context engineering framework
- Security scanning suite
- Test-driven development framework
- And more...

### Hooks (`hooks/`)
16 hook scripts for:
- Log sanitization (PostToolUse)
- Token waste estimation (PreToolUse)
- Session management (SessionStart/End)
- And more...

### Utilities (`lib/`)
5 utility files:
- Parsers (npm, node, python, generic)
- Filters
- Core utilities

### Configuration (`config/`)
6 configuration files:
- Parser configurations
- Thresholds
- Templates

## Distribution

This module is designed to be distributed as a **Git subtree**, allowing it to maintain the same folder structure across repositories while enabling easy updates.

## Files NOT Included

These files are excluded from the subtree (project-specific):
- `logs/` - Generated log files
- `settings.local.json` - Local project settings
- `*.local.*` - Local configuration files
- `investigation-*.md` - Project-specific investigations
- `orchestration-*.md` - Project-specific docs

## Usage

### Automatic Agent Invocation
Claude Code automatically uses agents based on task context.

### Explicit Agent Invocation
```
"Use the backend-architect to design this API"
"Have the security-auditor scan for vulnerabilities"
```

### Custom Agents
Add custom agents locally:
```bash
# Create .claude/agents/my-agent.md
# This file stays local (not in subtree)
```

### Local Configuration
Use `settings.local.json` for project-specific settings:
```json
{
  "project": "my-project",
  "custom_settings": "value"
}
```
This file is gitignored and stays local.

## Updates

### Pull Updates
```bash
git subtree pull \
  --prefix=.claude \
  git@github.com:doctorduke/claude-config.git \
  main \
  --squash
```

### Push Changes Back
```bash
git subtree push \
  --prefix=.claude \
  git@github.com:doctorduke/claude-config.git \
  main
```

## See Also

- [Subtree Usage Guide](SUBTREE_USAGE.md)
- [Quick Start Guide](QUICK_START.md)
- [Documentation](docs/README.md)

## License

See repository LICENSE file.

