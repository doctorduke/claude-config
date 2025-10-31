# Configuration Guide

## Overview

The log sanitization toolkit is highly configurable. You can customize:
- Parser behavior and thresholds
- Token waste limits
- Error templates
- Filter settings

## Configuration Files

### parsers.conf

Location: `.claude/config/parsers.conf`

Controls how different parsers extract and filter output.

```bash
# NPM Parser Settings
NPM_ERROR_PATTERNS="npm ERR!|Error:|ENOENT|EACCES|ETIMEDOUT|ECONNREFUSED"
NPM_IGNORE_PATTERNS="npm WARN deprecated|npm notice|npm timing"
NPM_MAX_LINES=20

# Node.js Parser Settings
NODE_STACK_TRACE_LINES=15
NODE_FILTER_NODE_MODULES=true
NODE_MAX_ERRORS=10

# Python Parser Settings
PYTHON_TRACEBACK_LINES=20
PYTHON_FILTER_SITE_PACKAGES=true

# Generic Parser Settings
COMPRESSION_LEVEL=medium  # low|medium|high
PRESERVE_CONTEXT_LINES=3
MAX_OUTPUT_LINES=50

# Entropy Filter Settings
ENTROPY_THRESHOLD=2.0
```

### thresholds.conf

Location: `.claude/config/thresholds.conf`

Defines limits for token waste detection and blocking.

```bash
# Token limits
MAX_OUTPUT_TOKENS=500        # Warn if output exceeds this
BLOCK_OUTPUT_TOKENS=10000    # Block if output would exceed this

# Commands known to be verbose (estimated tokens)
HIGH_WASTE_COMMANDS=(
    "npm install:5000"
    "npm update:4000"
    "npm ci:5000"
    "npm audit:3000"
    "npm list:2000"
    "cargo build --verbose:10000"
    "make V=1:8000"
    "pip install --verbose:3000"
    "composer install:4000"
)

# Quiet flags that reduce output
QUIET_FLAGS=(
    "--silent"
    "--quiet"
    "-q"
    "--no-verbose"
    "-s"
)
```

## Customization Examples

### Example 1: Increase npm Error Context

To show more context around npm errors:

```bash
# Edit .claude/config/parsers.conf
NPM_MAX_LINES=30
PRESERVE_CONTEXT_LINES=5
```

### Example 2: Block Verbose Commands

To block (not just warn) about verbose commands:

```bash
# Edit .claude/hooks/estimate_token_waste.sh
# Change: exit 0  # Allow command
# To:     exit 2  # Block command
```

### Example 3: Add Custom Command Pattern

To add a new high-waste command:

```bash
# Edit .claude/config/thresholds.conf
HIGH_WASTE_COMMANDS=(
    # ... existing commands ...
    "gradle build --info:6000"
    "mvn clean install -X:8000"
)
```

### Example 4: Adjust Compression Level

To change how aggressively output is compressed:

```bash
# Edit .claude/config/parsers.conf
COMPRESSION_LEVEL=high  # Options: low, medium, high

# low    = 30-40% reduction, preserves more context
# medium = 50-60% reduction, balanced (default)
# high   = 70-80% reduction, aggressive filtering
```

### Example 5: Custom Error Template

Create a new template for a specific error type:

```bash
# Create .claude/config/templates/my_error.tmpl
cat > .claude/config/templates/my_error.tmpl << 'TMPL'
Error: CUSTOM_ERROR_TYPE
Component: {{component}}
Message: {{message}}

Fix Suggestions:
1. Check configuration
2. Verify dependencies
3. Review logs at: {{log_file}}
TMPL
```

## Parser-Specific Configuration

### NPM Parser

**Error Patterns**: Regex patterns to identify npm errors
```bash
NPM_ERROR_PATTERNS="npm ERR!|Error:|ENOENT|EACCES"
```

**Ignore Patterns**: Lines to skip (noise reduction)
```bash
NPM_IGNORE_PATTERNS="npm WARN deprecated|npm notice"
```

**Max Lines**: Maximum error lines to show
```bash
NPM_MAX_LINES=20
```

### Node.js Parser

**Stack Trace Lines**: How many stack frames to show
```bash
NODE_STACK_TRACE_LINES=15
```

**Filter node_modules**: Skip node_modules in stack traces
```bash
NODE_FILTER_NODE_MODULES=true
```

### Python Parser

**Traceback Lines**: Maximum traceback depth
```bash
PYTHON_TRACEBACK_LINES=20
```

**Filter site-packages**: Skip library code in tracebacks
```bash
PYTHON_FILTER_SITE_PACKAGES=true
```

## Hook-Specific Configuration

### PostToolUse Hook (log_sanitizer.py)

Modify the hook to change output format:

```bash
# Edit .claude/hooks/log_sanitizer.py or its config: .claude/hooks/log-sanitizer.config.json

# Change output format
cat << EOF
=== SANITIZED OUTPUT ===
$sanitized

Tokens saved: $savings ($savings_pct%)
Full log: $log_file
