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
- **settings.local.json** - Claude Code permissions configuration (NOT COMMITTED - see below)

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

---

## settings.local.json - Local Permissions Configuration

### Purpose

`settings.local.json` is a **developer-specific** file that grants Claude Code elevated permissions for development operations. This file is excluded from version control to prevent security risks and allow per-developer customization.

### Why Not Committed

**Security Concerns**:
- Grants broad permissions for bash commands, git operations, and file system access
- Permissions are environment-specific (developer machine, CI/CD, etc.)
- Committing would force all developers to use the same permission set
- Could expose unintended permission grants to code reviewers

**Developer Flexibility**:
- Each developer can customize permissions based on their workflow
- Local experimentation without affecting team
- Different permission requirements for different development tasks

### Location

`.claude/settings.local.json` is listed in `.gitignore` at line 75:
```
# Claude settings
.claude/settings.local.json
```

### Permissions Granted

This configuration grants Claude Code permission for:

#### Build & Package Management
- `Bash(node:*)` - Node.js execution
- `Bash(npm:*)` - npm commands
- `Bash(pnpm:*)` - pnpm package manager operations
- `Bash(pnpm install:*)` - Dependency installation
- `Bash(pnpm build:*)` - Build operations
- `Bash(pnpm typecheck:*)` - TypeScript validation
- `Bash(pnpm lint:*)` - Linting operations
- `Bash(pnpm test:*)` - Test execution
- `Bash(pnpm add:*)` - Add dependencies
- `Bash(pnpm view:*)` - View package info

#### Git Operations
- `Bash(git:*)` - Full git command suite including:
  - `git add`, `git commit`, `git push` - Version control
  - `git checkout`, `git fetch`, `git pull` - Branch operations
  - `git worktree` - Parallel development workflows
  - `git diff`, `git status` - Repository inspection
  - `git config`, `git rm`, `git stash` - Configuration and cleanup
  - `git subtree add` - External module integration

#### GitHub Integration
- `Bash(gh:*)` - GitHub CLI operations
- `mcp__github__*` - GitHub MCP server tools:
  - Pull request operations (get, create, review, merge)
  - Issue management (get, create, update, comment)
  - Repository operations

#### File System Operations
- `Bash(cat:*)`, `Bash(grep:*)`, `Bash(find:*)` - File reading/searching
- `Bash(echo:*)`, `Bash(mkdir:*)`, `Bash(mv:*)` - File manipulation
- `Bash(chmod:*)` - Permission changes
- `mcp__filesystem__*` - Filesystem MCP server tools
- `Read(//private/tmp/**)` - Temporary file access

#### Development Tools
- `Bash(npx:*)` - Package execution (create-expo-app, create-next-app, etc.)
- `Bash(python3:*)` - Python script execution
- `Bash(for:*)`, `Bash(while:*)`, `Bash(do:*)` - Shell scripting constructs
- `Bash(awk:*)`, `Bash(tail:*)` - Text processing
- `WebSearch`, `WebFetch(domain:github.com)` - Web operations

#### Quality Assurance
- `Bash(pnpm eslint:*)` - ESLint execution
- `Bash(pnpm fix:newlines:*)` - Newline fixing automation
- `Bash(pnpm lint:newlines:*)` - Newline validation

### Creating Your Own settings.local.json

1. **Copy from template** (if one exists in repository documentation)
2. **Start minimal** and add permissions as needed:
```json
{
  "permissions": {
    "allow": [
      "Bash(git status)",
      "Bash(pnpm build:*)",
      "WebSearch"
    ],
    "deny": [],
    "ask": []
  }
}
```

3. **Grant permissions incrementally**:
   - Start with read-only operations (`git status`, `cat`, `grep`)
   - Add build operations when needed (`pnpm build`, `pnpm test`)
   - Add write operations carefully (`git commit`, `git push`)

4. **Use wildcards wisely**:
   - `Bash(pnpm:*)` grants ALL pnpm commands
   - `Bash(pnpm build:*)` grants only `pnpm build` with any arguments
   - More specific is safer

### Security Best Practices

**DO**:
- Keep `settings.local.json` in `.gitignore`
- Review permissions periodically
- Use specific patterns over wildcards when possible
- Document why broad permissions are granted (like this section)
- Test with minimal permissions first

**DON'T**:
- Commit `settings.local.json` to version control
- Grant `Bash(*:*)` without understanding implications
- Share your local settings file with untrusted parties
- Use production credentials in local settings

### Troubleshooting

**Permission Denied Errors**:
1. Check if command is in `settings.local.json` allow list
2. Add specific command pattern (e.g., `Bash(git commit:*)`)
3. Test with minimal pattern first, expand if needed

**Settings Not Taking Effect**:
1. Verify file is at `.claude/settings.local.json`
2. Check JSON syntax is valid
3. Restart Claude Code session
4. Check Claude Code logs for parsing errors

### Related Documentation

- Claude Code documentation: https://docs.anthropic.com/claude/docs
- Project CLAUDE.md: `/Users/doctorduke/Developer/doctorduke/umemee-v0/CLAUDE.md`
- Git workflow: `tools/worktree/CLAUDE.md`, `tools/subtree/CLAUDE.md`
