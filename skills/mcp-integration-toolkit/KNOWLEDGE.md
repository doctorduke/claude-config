# MCP Integration Knowledge Base

## Official Documentation

### Core Resources

- [MCP Specification](https://spec.modelcontextprotocol.io/) - Protocol specification
- [MCP Documentation](https://modelcontextprotocol.io/docs) - Official guides and tutorials
- [MCP GitHub](https://github.com/modelcontextprotocol) - Official repositories

### Framework Documentation

#### Python - FastMCP
- [FastMCP GitHub](https://github.com/jlowin/fastmcp) - Python framework for MCP servers
- [FastMCP Examples](https://github.com/jlowin/fastmcp/tree/main/examples) - Sample implementations
- [FastMCP API Docs](https://fastmcp.readthedocs.io/) - API reference

#### TypeScript/Node - MCP SDK
- [MCP SDK GitHub](https://github.com/modelcontextprotocol/sdk) - Official TypeScript/Node.js SDK
- [MCP SDK Examples](https://github.com/modelcontextprotocol/sdk/tree/main/examples) - TypeScript examples
- [MCP SDK NPM](https://www.npmjs.com/package/@modelcontextprotocol/sdk) - Package documentation

## Tools and Utilities

### Development Tools

#### MCP Inspector
Official debugging tool for MCP servers:
```bash
npm install -g @modelcontextprotocol/inspector
mcp-inspector python server.py
```

#### Claude Code Configuration
Configuration file location and format:
- **macOS/Linux**: `~/.config/claude-code/mcp.json`
- **Windows**: `%APPDATA%\claude-code\mcp.json`

### Testing Tools

- **pytest-mcp** - Testing framework for FastMCP servers
- **MCP Mock Client** - Simulate client requests for testing
- **MCP Protocol Validator** - Validate protocol compliance

## Community Resources

### MCP Ecosystem

- [MCP Awesome List](https://github.com/punkpeye/awesome-mcp-servers) - Community MCP servers
- [MCP Discord](https://discord.gg/mcp) - Community support
- [MCP Forum](https://forum.modelcontextprotocol.io/) - Discussion board

### Example Servers

#### Official Examples
- Weather API Server
- File System Server
- Database Server
- Git Repository Server

#### Community Servers
- Notion Integration
- Slack Bridge
- GitHub API
- Jira Integration
- AWS Services

## Standards and Specifications

### Protocol Specifications

#### JSON-RPC 2.0
MCP is based on JSON-RPC 2.0:
- [JSON-RPC Specification](https://www.jsonrpc.org/specification)
- Request/Response format
- Error handling standards

#### JSON Schema
Tool parameters use JSON Schema:
- [JSON Schema Docs](https://json-schema.org/)
- [Schema Validator](https://www.jsonschemavalidator.net/)

### Transport Protocols

#### stdio (Standard I/O)
- Default for local servers
- Uses stdin/stdout for communication
- Best for CLI tools

#### Server-Sent Events (SSE)
- For web-based clients
- Real-time streaming
- HTTP-based

#### HTTP/REST
- Traditional request/response
- Stateless communication
- Best for remote servers

## Best Practices Documentation

### Security Guidelines

1. [OWASP API Security](https://owasp.org/www-project-api-security/) - API security best practices
2. [MCP Security Guide](https://modelcontextprotocol.io/docs/security) - MCP-specific security
3. Authentication patterns
4. Rate limiting strategies
5. Input validation techniques

### Performance Optimization

1. Caching strategies
2. Connection pooling
3. Async operation patterns
4. Resource management

## Learning Resources

### Tutorials

#### Getting Started
1. [Building Your First MCP Server](https://modelcontextprotocol.io/docs/tutorial/first-server)
2. [Integrating with Claude Code](https://docs.claude.com/en/docs/claude-code/mcp.md)
3. [MCP Server Patterns](https://modelcontextprotocol.io/docs/patterns)

#### Advanced Topics
1. [Multi-Transport Servers](https://modelcontextprotocol.io/docs/advanced/transports)
2. [Resource Subscriptions](https://modelcontextprotocol.io/docs/advanced/subscriptions)
3. [Custom Prompts](https://modelcontextprotocol.io/docs/advanced/prompts)

### Video Resources

- [MCP Introduction (YouTube)](https://youtube.com/mcp-intro)
- [Building MCP Servers (Video Series)](https://mcp-tutorials.com)
- [MCP Best Practices Talk](https://conf.mcp.io/talks/best-practices)

## Framework Comparisons

### FastMCP vs MCP SDK

| Feature | FastMCP (Python) | MCP SDK (TypeScript) |
|---------|-----------------|---------------------|
| Language | Python 3.8+ | Node.js 16+ |
| Async Support | Native async/await | Promises/async |
| Type Safety | Type hints | Full TypeScript |
| Decorators | Yes (@mcp.tool) | No (explicit) |
| Performance | Good | Excellent |
| Ecosystem | Python libs | NPM packages |

### Choosing a Framework

**Use FastMCP when:**
- Python ecosystem integration needed
- Data science/ML tools
- Existing Python codebase

**Use MCP SDK when:**
- TypeScript/JavaScript preferred
- Web service integration
- Maximum performance needed

## Migration Guides

### From REST API to MCP
Step-by-step guide for converting existing APIs

### From CLI Tools to MCP
Converting command-line tools to MCP servers

### From Claude Code Tools to MCP
Migrating from built-in tools to MCP protocol