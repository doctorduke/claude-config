# Claude Code Log Sanitization Toolkit

Automatically sanitize verbose command outputs (npm, node, python, etc.) to reduce token waste by 50-70% in Claude Code workflows.

## Features

- **Automatic Sanitization**: PostToolUse hooks intercept all Bash command outputs
- **Proactive Warnings**: PreToolUse hooks warn about wasteful commands
- **Tool-Specific Parsers**: Intelligent parsing for npm, node, python, and more
- **Raw Log Preservation**: Full outputs saved to disk for reference
- **Zero Configuration**: Works out of the box with sensible defaults

## Quick Start

### 1. Installation

The toolkit is already installed in `.claude/` directory. Just register the hooks:

```bash
# In Claude Code, run:
/hooks

# Add these hooks:
# - PostToolUse -> Bash -> .claude/hooks/sanitize_bash_output.sh
# - PreToolUse -> Bash -> .claude/hooks/estimate_token_waste.sh
# - SessionStart -> * -> .claude/hooks/session_init.sh
# - SessionEnd -> * -> .claude/hooks/session_cleanup.sh
```

### 2. Test It

Ask Claude to run a verbose command:

```
Can you run: npm install
```

You'll see sanitized output instead of thousands of lines!

## How It Works

### PostToolUse Hook (sanitize_bash_output.sh)

1. Intercepts command output after execution
2. Saves raw output to `.claude/logs/`
3. Detects command type (npm, node, python, etc.)
4. Applies appropriate parser
5. Returns sanitized summary to Claude

### PreToolUse Hook (estimate_token_waste.sh)

1. Analyzes command before execution
2. Warns if command will generate excessive output
3. Suggests optimization flags (--silent, --quiet)
4. Allows command to proceed (PostToolUse will sanitize)

## Supported Tools

- **npm**: Error codes, module resolution, dependency issues
- **node**: Stack traces, JavaScript errors, module errors
- **python**: Tracebacks, import errors, exceptions
- **generic**: Fallback for any command

## Configuration

Edit `.claude/config/parsers.conf` to customize:

- Error patterns to match
- Lines to ignore
- Compression levels
- Context preservation

Edit `.claude/config/thresholds.conf` to customize:

- Token waste limits
- Commands to warn about
- Blocking thresholds

## Examples

### Before (5000 tokens)
```
npm WARN deprecated package@1.0.0
npm WARN deprecated another@2.0.0
[... 200 more lines ...]
npm ERR! code ENOENT
npm ERR! syscall open
[... 50 more error lines ...]
```

### After (500 tokens)
```
=== NPM ERROR SUMMARY ===
Error Code: ENOENT
File: /path/to/package.json
Type: MODULE_NOT_FOUND

Fix: Run 'npm init' or verify path exists
Raw log: .claude/logs/20250127_143022_npm_install.log
```

## Token Savings

- **npm install**: 70-80% reduction
- **node errors**: 60-70% reduction
- **python tracebacks**: 50-60% reduction
- **generic commands**: 40-50% reduction

## Troubleshooting

### Hooks not running?

1. Check registration: `/hooks` in Claude Code
2. Verify file permissions: `chmod +x .claude/hooks/*.sh`
3. Check logs: `.claude/logs/`

### Parser not working?

1. Check parser exists: `ls .claude/lib/parsers/`
2. Test manually: `cat log.txt | .claude/lib/parsers/npm_parser.sh`
3. Check configuration: `.claude/config/parsers.conf`

## Advanced Usage

### Custom Parsers

Create your own parser in `.claude/lib/parsers/`:

```bash
#!/bin/bash
# my_tool_parser.sh

parse_my_tool() {
    grep "ERROR" | head -10
}

parse_my_tool
```

### Standalone Usage

Use parsers outside Claude Code:

```bash
npm install 2>&1 | .claude/lib/parsers/npm_parser.sh
```

## Files Structure

```
.claude/
├── hooks/              # Hook scripts
├── lib/
│   ├── parsers/       # Tool-specific parsers
│   ├── filters/       # Utility filters
│   └── core/          # Core logic
├── config/            # Configuration
├── logs/              # Raw command outputs
└── docs/              # Documentation
```

## License

MIT - Use freely in your projects

## Contributing

Found a bug or want to add a parser? Submit a PR!
