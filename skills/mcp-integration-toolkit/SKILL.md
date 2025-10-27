---
name: mcp-integration-toolkit
description: Create, configure, and integrate MCP (Model Context Protocol) servers and clients. Use when building MCP servers with FastMCP (Python) or MCP SDK (Node/TypeScript), integrating external APIs, or creating custom tools/resources for LLMs. Handles server creation, client configuration, transport protocols, and security patterns.
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, WebFetch]
---

# MCP Integration Toolkit

## Purpose

The Model Context Protocol (MCP) is the new standard for connecting LLMs to external tools, data sources, and APIs. This Skill provides comprehensive support for:

1. **Creating MCP Servers** - Build servers in Python (FastMCP) or Node/TypeScript (MCP SDK)
2. **Client Integration** - Configure Claude Code and other clients to use MCP servers
3. **Protocol Patterns** - Implement tools, resources, and prompts correctly
4. **Security & Best Practices** - Handle authentication, rate limiting, and error handling
5. **Testing & Debugging** - Validate MCP implementations and troubleshoot issues

## When to Use This Skill

- Building MCP servers to expose APIs or services to LLMs
- Integrating third-party services (databases, APIs, file systems) via MCP
- Creating custom tools for Claude Code or other MCP clients
- Debugging MCP server/client communication issues
- Converting existing tools to MCP protocol
- Setting up MCP transport layers (stdio, SSE, HTTP)

## Quick Start

### 1. Create a Simple MCP Server (Python)

```python
from fastmcp import FastMCP

mcp = FastMCP("my-server")

@mcp.tool()
def hello_world(name: str) -> str:
    """Say hello to someone"""
    return f"Hello, {name}!"

if __name__ == "__main__":
    mcp.run()
```

### 2. Configure Claude Code

Add to `~/.config/claude-code/mcp.json`:
```json
{
  "mcpServers": {
    "my-server": {
      "command": "python",
      "args": ["/path/to/server.py"]
    }
  }
}
```

### 3. Test Your Server

```bash
# Install MCP Inspector
npm install -g @modelcontextprotocol/inspector

# Test your server
mcp-inspector python server.py
```

## Core Concepts

### MCP Architecture

```
┌─────────────┐         ┌──────────────┐         ┌────────────┐
│             │         │              │         │            │
│  LLM Client │◄────────┤  MCP Server  │◄────────┤ External   │
│  (Claude)   │  MCP    │  (FastMCP/   │  API    │ Service    │
│             │  Proto  │   MCP SDK)   │  Calls  │            │
└─────────────┘         └──────────────┘         └────────────┘
```

### MCP Components

1. **Tools** - Functions the LLM can call (like API endpoints)
2. **Resources** - Data the LLM can read (files, database records, API responses)
3. **Prompts** - Pre-configured templates the LLM can use
4. **Transports** - Communication layers (stdio, Server-Sent Events, HTTP)

## Essential Patterns

### API Integration Pattern

```python
from fastmcp import FastMCP
import httpx

mcp = FastMCP("api-server")

@mcp.tool()
async def call_api(endpoint: str, params: dict = None) -> dict:
    """Call external API"""
    async with httpx.AsyncClient() as client:
        response = await client.get(f"https://api.example.com/{endpoint}", params=params)
        response.raise_for_status()
        return response.json()
```

### Database Resource Pattern

```python
@mcp.resource("db://users/{user_id}")
def get_user(user_id: str) -> str:
    """Get user by ID"""
    conn = sqlite3.connect("database.db")
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))
    row = cursor.fetchone()
    conn.close()
    return json.dumps(dict(row)) if row else None
```

## File Structure

This skill has been refactored for better organization:

- **skill.md** (this file) - Quick start and core concepts
- **KNOWLEDGE.md** - Documentation, tools, and references
- **GOTCHAS.md** - Common pitfalls and troubleshooting
- **PATTERNS.md** - Implementation patterns and architectures
- **EXAMPLES.md** - Complete working examples
- **REFERENCE.md** - API reference and configuration options

## Quick Debugging Checklist

1. ✅ Server starts without errors?
2. ✅ Client can discover tools?
3. ✅ Tools execute successfully?
4. ✅ Errors return proper format?
5. ✅ Logging to stderr (not stdout)?

## Related Skills

- `git-mastery-suite` - For managing MCP server code in Git
- `security-scanning-suite` - For security analysis of MCP implementations

## Next Steps

1. Review **PATTERNS.md** for common implementation patterns
2. Check **GOTCHAS.md** for troubleshooting tips
3. See **EXAMPLES.md** for complete working servers
4. Consult **REFERENCE.md** for detailed API documentation