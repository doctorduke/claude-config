# MCP Server Usage Guide

## Overview

MCP (Model Context Protocol) servers enhance Claude Code's capabilities with direct tool access. This document explains how to use the available MCP servers in the umemee-v0 project.

## Available MCP Servers

### 1. Filesystem Operations (`mcp__filesystem__*`)
Direct file operations without shell commands:
- `mcp__filesystem__read_text_file` - Read files directly
- `mcp__filesystem__write_file` - Write files
- `mcp__filesystem__edit_file` - Make line-based edits
- `mcp__filesystem__create_directory` - Create directories
- `mcp__filesystem__list_directory` - List directory contents
- `mcp__filesystem__search_files` - Search for files by pattern

**Benefit**: Faster than bash commands, better error handling

### 2. GitHub Operations (`mcp__github__*`)
Direct GitHub API access:
- `mcp__github__get_pull_request` - Get PR details
- `mcp__github__create_pull_request` - Create new PRs
- `mcp__github__create_issue` - Create issues
- `mcp__github__list_commits` - View commit history
- `mcp__github__push_files` - Push multiple files

**Benefit**: No need for `gh` CLI, direct API access

### 3. Browser Automation (`mcp__playwright__*`)
Web testing and automation:
- `mcp__playwright__browser_navigate` - Navigate to URLs
- `mcp__playwright__browser_click` - Click elements
- `mcp__playwright__browser_snapshot` - Take screenshots
- `mcp__playwright__browser_fill_form` - Fill forms

**Benefit**: Automated testing, web scraping capabilities

### 4. ESLint Operations (`mcp__eslint__*`)
Direct linting without CLI:
- `mcp__eslint__lint-files` - Lint specific files

**Benefit**: Faster linting, direct results

### 5. IDE Operations (`mcp__ide__*`)
IDE integration:
- `mcp__ide__getDiagnostics` - Get language diagnostics
- `mcp__ide__executeCode` - Execute code in Jupyter

**Benefit**: Direct IDE feedback

### 6. Memory Operations (`mcp__memory__*`)
Knowledge graph management:
- `mcp__memory__create_entities` - Store information
- `mcp__memory__search_nodes` - Search stored knowledge
- `mcp__memory__read_graph` - View knowledge graph

**Benefit**: Persistent context across sessions

## Usage Changes

### Before (using bash):
```javascript
// Old way
Bash("cat file.txt")
Bash("echo 'content' > file.txt")
Bash("gh pr view 1")
```

### After (using MCP):
```javascript
// New way
mcp__filesystem__read_text_file({ path: "file.txt" })
mcp__filesystem__write_file({ path: "file.txt", content: "content" })
mcp__github__get_pull_request({ owner: "doctorduke", repo: "umemee-v0", pull_number: 1 })
```

## Best Practices

1. **Prefer MCP over Bash** when available - faster and more reliable
2. **Use filesystem MCP** for all file operations
3. **Use GitHub MCP** for repository operations
4. **Use memory MCP** for maintaining context across sessions
5. **Batch operations** when possible for efficiency

## Performance Improvements

- **File operations**: ~50% faster than bash
- **GitHub operations**: Direct API, no CLI overhead
- **Linting**: Direct results without parsing output
- **Memory**: Instant context retrieval

## Example Workflows

### Creating and Editing Files
```javascript
// Create directory
mcp__filesystem__create_directory({ path: "/path/to/dir" })

// Write file
mcp__filesystem__write_file({
  path: "/path/to/file.txt",
  content: "File content"
})

// Edit file
mcp__filesystem__edit_file({
  path: "/path/to/file.txt",
  edits: [{
    oldText: "old",
    newText: "new"
  }]
})
```

### GitHub Workflow
```javascript
// Get PR details
mcp__github__get_pull_request({
  owner: "doctorduke",
  repo: "umemee-v0",
  pull_number: 1
})

// Create issue
mcp__github__create_issue({
  owner: "doctorduke",
  repo: "umemee-v0",
  title: "Bug report",
  body: "Description"
})
```

## When to Use Each Server

| Task | Use | Instead of |
|------|-----|------------|
| Reading files | `mcp__filesystem__read_text_file` | `Bash("cat")` |
| Writing files | `mcp__filesystem__write_file` | `Bash("echo >")` |
| Searching files | `mcp__filesystem__search_files` | `Bash("find")` |
| GitHub operations | `mcp__github__*` | `Bash("gh")` |
| Linting | `mcp__eslint__lint-files` | `Bash("pnpm lint")` |
| Web testing | `mcp__playwright__*` | Manual testing |

## Configuration

MCP servers are configured in:
- `.claude/settings.local.json` - Local settings
- `tools/mcp/generated-servers.json` - Server configurations

## Troubleshooting

- **Permission errors**: Check `.claude/settings.local.json` allowlist
- **Server not found**: Run `pnpm setup:mcps` to regenerate
- **API limits**: GitHub MCP respects rate limits
- **File paths**: Always use absolute paths with filesystem MCP

## Security Notes

- MCP servers respect file system permissions
- GitHub operations require proper token configuration
- Memory server data is local only
- Browser automation runs in sandboxed environment