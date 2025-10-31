# MCP Integration Reference

## FastMCP API Reference

### Core Decorators

#### @mcp.tool()
Define a tool that LLMs can call:

```python
@mcp.tool()
def tool_name(param1: type, param2: type = default) -> ReturnType:
    """Tool description for LLM"""
    pass
```

**Parameters:**
- Function parameters become tool inputs
- Type hints are used for schema generation
- Default values are supported
- Docstring becomes tool description

**Return Types:**
- Must be JSON-serializable (dict, list, str, int, float, bool, None)
- Pydantic models are automatically serialized

#### @mcp.resource(uri_pattern)
Define a resource that LLMs can read:

```python
@mcp.resource("protocol://path/{variable}")
def resource_name(variable: str) -> Optional[str]:
    """Resource description"""
    return json.dumps(data)
```

**URI Patterns:**
- Must include protocol: `file://`, `db://`, `http://`, etc.
- Support path variables: `{variable_name}`
- Variables become function parameters

**Options:**
- `subscribe=True` - Enable change notifications
- `mime_type="application/json"` - Specify content type

#### @mcp.prompt(name)
Define a reusable prompt template:

```python
@mcp.prompt("template-name")
def prompt_name(param: str) -> str:
    """Generate prompt with parameters"""
    return f"Prompt text with {param}"
```

### Lifecycle Hooks

#### @mcp.on_startup()
Run code when server starts:

```python
@mcp.on_startup()
async def startup():
    # Initialize connections, pools, etc.
    await database.connect()
```

#### @mcp.on_shutdown()
Clean up when server stops:

```python
@mcp.on_shutdown()
async def shutdown():
    # Close connections, save state, etc.
    await database.disconnect()
```

### Server Methods

#### mcp.run()
Start server with stdio transport (default):

```python
if __name__ == "__main__":
    mcp.run()
```

#### mcp.run_http(host, port)
Start server with HTTP transport:

```python
mcp.run_http(host="0.0.0.0", port=8000)
```

**Parameters:**
- `host`: Bind address (default: "127.0.0.1")
- `port`: Port number (default: 8000)
- `path`: URL path (default: "/")

#### mcp.run_sse(host, port)
Start server with Server-Sent Events transport:

```python
mcp.run_sse(host="0.0.0.0", port=8000)
```

#### mcp.notify_resource_changed(uri)
Notify clients of resource changes:

```python
mcp.notify_resource_changed("db://users/123")
```

## MCP SDK (TypeScript) API Reference

### Server Class

```typescript
import { Server } from "@modelcontextprotocol/sdk/server/index.js";

const server = new Server({
  name: "server-name",
  version: "1.0.0"
});
```

### Request Handlers

#### Tool Handler
```typescript
import { ListToolsRequestSchema, CallToolRequestSchema } from "@modelcontextprotocol/sdk/types.js";

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [{
    name: "tool_name",
    description: "Tool description",
    inputSchema: {
      type: "object",
      properties: {
        param: { type: "string" }
      }
    }
  }]
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  if (request.params.name === "tool_name") {
    // Handle tool call
    return { result: {} };
  }
});
```

#### Resource Handler
```typescript
import { ListResourcesRequestSchema, ReadResourceRequestSchema } from "@modelcontextprotocol/sdk/types.js";

server.setRequestHandler(ListResourcesRequestSchema, async () => ({
  resources: [{
    uri: "file:///path",
    name: "Resource Name",
    mimeType: "application/json"
  }]
}));

server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
  const uri = request.params.uri;
  // Read resource
  return {
    contents: [{
      uri: uri,
      mimeType: "application/json",
      text: JSON.stringify(data)
    }]
  };
});
```

### Transport Classes

#### StdioServerTransport
```typescript
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

const transport = new StdioServerTransport();
await server.connect(transport);
```

#### HttpServerTransport
```typescript
import { HttpServerTransport } from "@modelcontextprotocol/sdk/server/http.js";

const transport = new HttpServerTransport({
  port: 8000,
  host: "0.0.0.0"
});
await server.connect(transport);
```

## Configuration Reference

### Claude Code Configuration

**Location:**
- macOS/Linux: `~/.config/claude-code/mcp.json`
- Windows: `%APPDATA%\claude-code\mcp.json`

**Format:**
```json
{
  "mcpServers": {
    "server-name": {
      "command": "executable",
      "args": ["arg1", "arg2"],
      "env": {
        "ENV_VAR": "value",
        "API_KEY": "${API_KEY}"  // Reference from environment
      },
      "cwd": "/working/directory",  // Optional
      "disabled": false  // Optional, to disable server
    }
  }
}
```

### Environment Variables

#### Server Environment
```bash
# Python server
MCP_TRANSPORT=stdio|http|sse
MCP_HOST=0.0.0.0
MCP_PORT=8000

# Common
LOG_LEVEL=DEBUG|INFO|WARNING|ERROR
API_KEY=your-key
DATABASE_URL=connection-string
```

#### Client Environment
```bash
# Reference in mcp.json
export API_KEY=actual-key
# Use as ${API_KEY} in config
```

## JSON Schema Reference

### Tool Input Schema

Tools use JSON Schema for parameter validation:

```json
{
  "type": "object",
  "properties": {
    "stringParam": {
      "type": "string",
      "description": "A string parameter",
      "minLength": 1,
      "maxLength": 100
    },
    "numberParam": {
      "type": "number",
      "minimum": 0,
      "maximum": 100
    },
    "boolParam": {
      "type": "boolean"
    },
    "arrayParam": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "minItems": 1,
      "maxItems": 10
    },
    "enumParam": {
      "type": "string",
      "enum": ["option1", "option2", "option3"]
    },
    "objectParam": {
      "type": "object",
      "properties": {
        "nested": {
          "type": "string"
        }
      },
      "required": ["nested"]
    }
  },
  "required": ["stringParam"],
  "additionalProperties": false
}
```

### Common Schema Patterns

#### Optional Parameters
```json
{
  "type": "object",
  "properties": {
    "required": { "type": "string" },
    "optional": { "type": "string" }
  },
  "required": ["required"]
}
```

#### Union Types
```json
{
  "oneOf": [
    { "type": "string" },
    { "type": "number" }
  ]
}
```

#### Pattern Validation
```json
{
  "type": "string",
  "pattern": "^[A-Za-z0-9]+$"
}
```

## Protocol Messages

### Request Format
```json
{
  "jsonrpc": "2.0",
  "id": "unique-id",
  "method": "tools/call",
  "params": {
    "name": "tool_name",
    "arguments": {
      "param": "value"
    }
  }
}
```

### Response Format
```json
{
  "jsonrpc": "2.0",
  "id": "unique-id",
  "result": {
    "data": "response-data"
  }
}
```

### Error Format
```json
{
  "jsonrpc": "2.0",
  "id": "unique-id",
  "error": {
    "code": -32602,
    "message": "Invalid params",
    "data": {
      "details": "Additional error information"
    }
  }
}
```

## Security Configuration

### Authentication

#### API Key Authentication
```python
import os
from fastmcp import FastMCP

mcp = FastMCP("secure-server")

API_KEY = os.getenv("SERVER_API_KEY")

@mcp.tool()
def secure_operation(auth_token: str, data: dict) -> dict:
    if auth_token != API_KEY:
        raise PermissionError("Invalid authentication")
    return process_data(data)
```

#### OAuth2 Integration
```python
from fastmcp import FastMCP
import httpx

@mcp.tool()
async def oauth_operation(access_token: str) -> dict:
    # Validate token with OAuth provider
    async with httpx.AsyncClient() as client:
        response = await client.get(
            "https://oauth.provider.com/validate",
            headers={"Authorization": f"Bearer {access_token}"}
        )
        if response.status_code != 200:
            raise PermissionError("Invalid token")

    # Proceed with operation
    return perform_operation()
```

### Rate Limiting Configuration

```python
RATE_LIMITS = {
    "default": {
        "calls": 100,
        "window": 60  # seconds
    },
    "expensive": {
        "calls": 10,
        "window": 60
    },
    "bulk": {
        "calls": 1000,
        "window": 3600
    }
}
```

### CORS Configuration (HTTP Transport)

```python
from fastmcp import FastMCP

mcp = FastMCP("server")

# Configure CORS
mcp.configure_cors(
    allow_origins=["https://example.com"],
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "Authorization"],
    max_age=3600
)
```

## Testing Reference

### Unit Testing Tools

```python
import pytest
from your_server import mcp

def test_tool():
    result = mcp.tools["tool_name"]("param")
    assert result["status"] == "success"

@pytest.mark.asyncio
async def test_async_tool():
    result = await mcp.tools["async_tool"]()
    assert result is not None
```

### Integration Testing

```python
import subprocess
import json

def test_server_integration():
    # Start server
    proc = subprocess.Popen(
        ["python", "server.py"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE
    )

    # Send request
    request = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/list"
    }
    proc.stdin.write(json.dumps(request).encode())
    proc.stdin.flush()

    # Read response
    response = json.loads(proc.stdout.readline())
    assert "result" in response
```

## Performance Tuning

### Connection Pooling
```python
# HTTP client pooling
httpx.AsyncClient(
    limits=httpx.Limits(
        max_keepalive_connections=5,
        max_connections=10,
        keepalive_expiry=30
    )
)
```

### Database Connection Pool
```python
# PostgreSQL with asyncpg
pool = await asyncpg.create_pool(
    dsn,
    min_size=10,
    max_size=20,
    max_queries=50000,
    max_inactive_connection_lifetime=300
)
```

### Caching Configuration
```python
from functools import lru_cache

@lru_cache(maxsize=128, typed=True)
def expensive_operation(param: str) -> dict:
    # Cached computation
    pass
```

## Deployment Configurations

### Docker Deployment
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY server.py .

ENV MCP_TRANSPORT=stdio

CMD ["python", "server.py"]
```

### Systemd Service
```ini
[Unit]
Description=MCP Server
After=network.target

[Service]
Type=simple
User=mcp
WorkingDirectory=/opt/mcp-server
ExecStart=/usr/bin/python3 /opt/mcp-server/server.py
Restart=always
Environment="API_KEY=your-key"

[Install]
WantedBy=multi-user.target
```

### PM2 Configuration
```json
{
  "apps": [{
    "name": "mcp-server",
    "script": "server.py",
    "interpreter": "python3",
    "env": {
      "MCP_TRANSPORT": "http",
      "MCP_PORT": "8000"
    }
  }]
}
```