# Claude Code Documentation Enforcement Hooks

This directory contains hooks for enforcing documentation standards in the umemee-v0 project.

## Purpose

The hooks in `hooks.mjs` enforce the following documentation requirements:
1. Every directory should have a `BRIEF.md` file describing its purpose
2. Every directory containing code must have a `CLAUDE.md` file with comprehensive development instructions
3. Documentation files must follow the required structure and quality standards

## Files

- **hooks.mjs** - Main hooks implementation with documentation enforcement logic
- **test-hooks.mjs** - Test script to validate hooks functionality and scan project compliance
- **settings.local.json** - Claude Code permissions configuration

## Hook Functions

### Directory Creation Hooks
- `preDirectoryCreate()` - Validates directory creation and warns about BRIEF.md requirement
- `postDirectoryCreate()` - Checks if BRIEF.md was created after directory creation

### File Operation Hooks
- `onFileChange()` - Ensures CLAUDE.md exists when code files are added to a directory
- `validateDocumentation()` - Validates structure and quality of documentation files

### Utility Functions
- `scanProjectDocumentation()` - Scans entire project for documentation compliance
- `initializeDocumentation()` - Creates template BRIEF.md and CLAUDE.md files
- `isCodeDirectory()` - Determines if a directory contains code files
- `validateBriefStructure()` - Validates BRIEF.md structure
- `validateClaudeStructure()` - Validates CLAUDE.md structure

## Testing

Run the test script to check documentation compliance:

```bash
node .claude/test-hooks.mjs
```

This will:
1. Scan the project for missing documentation
2. Validate existing documentation files
3. Test hook functionality
4. Provide a summary of issues found

## Documentation Standards

### BRIEF.md Requirements
- Must have at least one heading
- Minimum 50 characters of content
- At least 3 non-empty lines
- Should describe the directory's purpose and contents

### CLAUDE.md Requirements
Must include these sections:
- `## Purpose` - Module/directory purpose
- `## Dependencies` - Internal and external dependencies
- `## Key Files` - Important files and their roles
- `## Conventions` - Naming and code style guidelines

Additional recommended sections:
- `## Testing` - Testing approach and commands
- `## Common Tasks` - Frequent development tasks
- `## Gotchas` - Known issues and common mistakes
- `## Architecture Decisions` - Design rationale
- `## Performance Considerations`
- `## Security Notes`

## Enforcement Actions

The hooks log all enforcement actions with timestamps:
- `DIRECTORY_CREATE_ATTEMPT` - Directory creation detected
- `MISSING_BRIEF` - BRIEF.md not found
- `MISSING_CLAUDE` - CLAUDE.md not found in code directory
- `INVALID_BRIEF_STRUCTURE` - BRIEF.md validation failed
- `INVALID_CLAUDE_STRUCTURE` - CLAUDE.md validation failed
- `DOCUMENTATION_QUALITY_CHECK` - Documentation validation performed
- `PROJECT_SCAN_COMPLETE` - Full project scan completed
- `DOCUMENTATION_CREATED` - Documentation file created

## Skip Patterns

The following directories are automatically excluded from enforcement:
- `node_modules`
- `.git`
- `.claude`
- `dist`
- `build`
- `.next`
- `.turbo`
- `coverage`

## Usage Examples

### Initialize documentation for a directory
```javascript
import hooks from './.claude/hooks.mjs';

// Create both BRIEF.md and CLAUDE.md
await hooks.initializeDocumentation('/path/to/directory', 'both');

// Create only BRIEF.md
await hooks.initializeDocumentation('/path/to/directory', 'brief');
```

### Scan project for compliance
```javascript
import hooks from './.claude/hooks.mjs';

const result = await hooks.scanProjectDocumentation();
console.log(`Found ${result.summary.errors} errors and ${result.summary.warnings} warnings`);
```

### Validate a documentation file
```javascript
import hooks from './.claude/hooks.mjs';

const result = await hooks.validateDocumentation({
  filePath: '/path/to/CLAUDE.md'
});
if (result.status === 'error') {
  console.log('Validation errors:', result.errors);
}
```

## Integration with Claude Code

These hooks are designed to integrate with Claude Code's workflow:
1. When creating new directories, hooks provide reminders about documentation
2. When adding code files, hooks check for CLAUDE.md presence
3. Audit logs help track documentation compliance over time

## Maintenance

To update documentation requirements:
1. Edit validation functions in `hooks.mjs`
2. Update required sections arrays
3. Adjust minimum content lengths
4. Test changes with `node .claude/test-hooks.mjs`
