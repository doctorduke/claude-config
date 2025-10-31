# Installation Guide

## Quick Installation (5 minutes)

### Step 1: Verify Directory Structure

The toolkit should already be installed in `.claude/` directory:

```bash
ls -la .claude/
# Should show: hooks/, lib/, config/, logs/, docs/
```

### Step 2: Make Scripts Executable

```bash
chmod +x .claude/hooks/*.sh
chmod +x .claude/lib/parsers/*.sh
chmod +x .claude/lib/filters/*.sh
chmod +x .claude/lib/core/*.sh
```

### Step 3: Register Hooks in Claude Code

#### Option A: Using /hooks Command (Recommended)

1. In Claude Code, type: `/hooks`
2. Select `PostToolUse` event
3. Select `+ Add new matcher...`
4. Type: `Bash`
5. Select `+ Add new hook...`
6. Enter: `$CLAUDE_PROJECT_DIR/.claude/hooks/log_sanitizer.py`
7. Select storage location: `Project settings`
8. Press Esc to save

Repeat for other hooks:
- **PreToolUse** → Bash → `$CLAUDE_PROJECT_DIR/.claude/hooks/estimate_token_waste.sh`
- **SessionStart** → * → `$CLAUDE_PROJECT_DIR/.claude/hooks/session_init.sh`
- **SessionEnd** → * → `$CLAUDE_PROJECT_DIR/.claude/hooks/session_cleanup.sh`

#### Option B: Manual Configuration

Edit `.claude/settings.json` in your project:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/log_sanitizer.py"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/estimate_token_waste.sh"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/session_init.sh"
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/session_cleanup.sh"
          }
        ]
      }
    ]
  }
}
```

### Step 4: Test Installation

Ask Claude to run a test command:

```
Can you run: echo "Testing hooks" && npm --version
```

You should see the sanitized output format with token savings displayed.

## Verification

### Check Hook Registration

```bash
# View registered hooks
cat .claude/settings.json | grep -A 20 "hooks"
```

### Test Individual Components

```bash
# Test ANSI stripper
echo -e "\033[31mRed Text\033[0m" | .claude/lib/filters/ansi_strip.sh

# Test npm parser
cat sample_npm_error.log | .claude/lib/parsers/npm_parser.sh

# Test generic parser
cat sample_output.log | .claude/lib/parsers/generic_parser.sh
```

### Check Logs Directory

```bash
ls -la .claude/logs/
# Should show timestamped log files after running commands
```

## Troubleshooting

### Hooks Not Running

**Problem**: Commands run but no sanitization happens

**Solutions**:
1. Check hook registration: `/hooks` in Claude Code
2. Verify file permissions: `chmod +x .claude/hooks/*.sh`
3. Check for errors: Look at Claude Code's output
4. Verify paths: Ensure `$CLAUDE_PROJECT_DIR` is set correctly

### Permission Denied Errors

**Problem**: `Permission denied` when running hooks

**Solution**:
```bash
# Make all scripts executable
find .claude -name "*.sh" -type f -exec chmod +x {} \;
```

### jq Not Found

**Problem**: `jq: command not found`

**Solution**:
```bash
# Windows (Git Bash)
# jq should be included with Git for Windows

# Linux
sudo apt-get install jq

# macOS
brew install jq
```

### Hooks Run But No Output

**Problem**: Hooks execute but don't show sanitized output

**Solutions**:
1. Check if output is being generated: `ls .claude/logs/`
2. Test parser manually: `cat .claude/logs/latest.log | .claude/lib/parsers/npm_parser.sh`
3. Check for script errors: Add `set -x` to hook scripts for debugging

### Path Issues on Windows

**Problem**: Paths with spaces or backslashes cause issues

**Solution**:
- Use Git Bash or WSL for consistent path handling
- Ensure `$CLAUDE_PROJECT_DIR` uses forward slashes
- Quote paths in hook commands

## Uninstallation

To remove the hooks:

1. Run `/hooks` in Claude Code
2. Remove each hook entry
3. Or delete `.claude/settings.json` hooks section
4. Optionally remove `.claude/` directory

## Next Steps

- Read [CONFIGURATION.md](CONFIGURATION.md) to customize parsers
- See [README.md](README.md) for usage examples
- Check [PATTERNS.md](PATTERNS.md) for advanced patterns
