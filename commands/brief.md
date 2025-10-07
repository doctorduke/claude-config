# /brief Command

Generate BRIEF.md documentation for a directory.

## Usage
```
/brief [path]
```

## Parameters
- `path` (optional): Directory path to document. Defaults to current directory.

## Behavior
1. Analyzes directory structure and contents
2. Infers purpose from file types, names, and patterns
3. Identifies key files and their relationships
4. Generates concise BRIEF.md following standard format
5. Ensures output is under 15 lines for quick scanning

## Template
```markdown
# [Directory Name]

[One-line purpose statement based on contents]

## Contents
- [Main file/folder]: [Brief description]
- [Key file/folder]: [Brief description]
- [Supporting items]: [Brief description]

## Key Relationships
- [Primary relationship or dependency]
- [Secondary relationship if critical]

## Usage
[Single line on how to use/run if applicable]
```

## Implementation Logic
1. **Directory Analysis**
   - List all files and subdirectories
   - Identify file types (config, source, docs, tests)
   - Detect patterns (package.json, tsconfig, etc.)

2. **Purpose Inference**
   - Package.json → Node/JS project details
   - Cargo.toml → Rust project
   - *.py → Python module
   - index.* → Entry point
   - test/* → Testing suite
   - config/* → Configuration management

3. **Content Prioritization**
   - Entry points first (index, main, app)
   - Configuration files second
   - Core source files third
   - Tests and docs last

4. **Relationship Detection**
   - Import statements → Dependencies
   - Config files → Build relationships
   - File naming → Functional groupings

## Examples

### Example 1: Package Directory
```markdown
# ui-mobile

React Native component library for mobile platforms.

## Contents
- index.ts: Component exports
- components/: UI component implementations
- styles/: Shared styling and themes

## Key Relationships
- Imports from @umemee/types
- Used by platforms/mobile
```

### Example 2: Tool Directory
```markdown
# mcp-tools

MCP server tool implementations and handlers.

## Contents
- server.ts: MCP server setup
- tools/: Tool definitions and schemas
- handlers/: Tool execution logic

## Key Relationships
- Implements MCP protocol
- Provides tools to AI assistants
```

## Error Handling
- If directory doesn't exist: "Directory not found: [path]"
- If directory is empty: Generate minimal BRIEF.md noting empty state
- If BRIEF.md exists: Prompt for overwrite confirmation

## Output
Creates `BRIEF.md` in the specified directory with human-readable documentation that can be quickly scanned to understand the directory's purpose and structure.
