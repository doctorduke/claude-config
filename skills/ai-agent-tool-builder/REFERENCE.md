# Reference: AI Agent Tool Builder

API documentation, protocol specifications, and performance benchmarks for MCP servers and function calling tools.

## FastMCP API Reference

### Server Initialization

```python
from fastmcp import FastMCP

mcp = FastMCP(
    name: str,              # Server name (required)
    version: str = "1.0.0", # Server version
    protocol_version: str = "2024-11-05"  # MCP protocol version
)
```

### Tool Registration

**Basic Tool**:
```python
@mcp.tool()
def tool_name(param1: str, param2: int = 0) -> str:
    """Tool description used by agents."""
    return "result"
```

**Type Annotations**:
```python
from typing import Optional, List, Dict, Union

@mcp.tool()
def complex_tool(
    required_str: str,
    optional_int: Optional[int] = None,
    list_param: List[str] = [],
    dict_param: Dict[str, any] = {},
    union_param: Union[str, int] = "default"
) -> str:
    pass
```

**Return Types**:
- `str`: Plain text response
- `dict`: Automatically serialized to JSON string
- `list`: Automatically serialized to JSON string

### Resource Registration

```python
@mcp.resource("template://{name}")
async def get_resource(name: str) -> str:
    """Provide resource content."""
    return f"Resource content for {name}"
```

### Running Server

```python
if __name__ == "__main__":
    mcp.run()  # Runs on stdio transport
```

### FastMCP Features

**Automatic Schema Generation**:
- Type hints → JSON Schema parameters
- Docstrings → tool descriptions
- Default values → optional parameters

**Error Handling**:
- Exceptions automatically caught
- Returned as error responses to client

**Validation**:
- Type validation via Python type hints
- Pydantic models supported for complex types

## MCP TypeScript SDK Reference

### Server Setup

```typescript
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

const server = new Server(
  {
    name: string,           // Server name
    version: string,        // Server version
  },
  {
    capabilities: {
      tools: {},            // Enable tools capability
      resources: {},        // Enable resources (optional)
      prompts: {},          // Enable prompts (optional)
    },
  }
);
```

### Request Handlers

**List Tools**:
```typescript
import { ListToolsRequestSchema } from "@modelcontextprotocol/sdk/types.js";

server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "tool_name",
        description: "Tool description",
        inputSchema: {
          type: "object",
          properties: {
            param: { type: "string" }
          },
          required: ["param"]
        }
      }
    ]
  };
});
```

**Call Tool**:
```typescript
import { CallToolRequestSchema } from "@modelcontextprotocol/sdk/types.js";

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  if (name === "tool_name") {
    return {
      content: [
        { type: "text", text: "result" }
      ]
    };
  }

  throw new Error(`Unknown tool: ${name}`);
});
```

**Error Responses**:
```typescript
return {
  content: [
    { type: "text", text: "Error message" }
  ],
  isError: true  // Mark as error
};
```

### Transport Options

**Stdio Transport**:
```typescript
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

const transport = new StdioServerTransport();
await server.connect(transport);
```

**HTTP Transport** (SSE):
```typescript
import { SSEServerTransport } from "@modelcontextprotocol/sdk/server/sse.js";

const transport = new SSEServerTransport("/message", response);
await server.connect(transport);
```

### TypeScript SDK Features

**Full Protocol Control**:
- Manual schema definition
- Custom error handling
- Fine-grained capability control

**Type Safety**:
- TypeScript types for all protocol messages
- Compile-time validation of schemas

**Async/Await**:
- All handlers are async
- Native promise support

## JSON Schema Validation Reference

### Basic Types

```json
{
  "type": "string",
  "type": "number",
  "type": "integer",
  "type": "boolean",
  "type": "array",
  "type": "object",
  "type": "null"
}
```

### String Constraints

```json
{
  "type": "string",
  "minLength": 1,
  "maxLength": 100,
  "pattern": "^[a-zA-Z0-9]+$",
  "format": "email|uri|date-time|uuid|ipv4|ipv6"
}
```

### Number Constraints

```json
{
  "type": "number",
  "minimum": 0,
  "maximum": 100,
  "exclusiveMinimum": 0,
  "exclusiveMaximum": 100,
  "multipleOf": 0.01
}
```

### Array Constraints

```json
{
  "type": "array",
  "items": { "type": "string" },
  "minItems": 1,
  "maxItems": 10,
  "uniqueItems": true
}
```

### Object Constraints

```json
{
  "type": "object",
  "properties": {
    "name": { "type": "string" },
    "age": { "type": "integer" }
  },
  "required": ["name"],
  "additionalProperties": false
}
```

### Enums

```json
{
  "type": "string",
  "enum": ["option1", "option2", "option3"]
}
```

### Conditional Schemas

**oneOf** (exactly one must match):
```json
{
  "oneOf": [
    { "type": "string" },
    { "type": "number" }
  ]
}
```

**anyOf** (at least one must match):
```json
{
  "anyOf": [
    { "type": "string" },
    { "type": "number" }
  ]
}
```

**allOf** (all must match - used for composition):
```json
{
  "allOf": [
    { "type": "object", "properties": { "name": { "type": "string" } } },
    { "properties": { "age": { "type": "integer" } } }
  ]
}
```

## MCP Protocol Specification

### Message Format

All MCP messages are JSON-RPC 2.0:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "tool_name",
    "arguments": { "param": "value" }
  }
}
```

### Core Methods

| Method | Direction | Purpose |
|--------|-----------|---------|
| `initialize` | Client → Server | Establish connection |
| `tools/list` | Client → Server | Get available tools |
| `tools/call` | Client → Server | Execute tool |
| `resources/list` | Client → Server | Get available resources |
| `resources/read` | Client → Server | Read resource |
| `prompts/list` | Client → Server | Get available prompts |
| `prompts/get` | Client → Server | Get prompt template |

### Tool Call Request

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "tool_name",
    "arguments": {
      "param1": "value1",
      "param2": 42
    }
  }
}
```

### Tool Call Response

**Success**:
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "Tool result"
      }
    ]
  }
}
```

**Error**:
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "error": {
    "code": -32602,
    "message": "Invalid params"
  }
}
```

### Error Codes

| Code | Meaning |
|------|---------|
| -32700 | Parse error |
| -32600 | Invalid request |
| -32601 | Method not found |
| -32602 | Invalid params |
| -32603 | Internal error |

### Content Types

**Text**:
```json
{ "type": "text", "text": "string content" }
```

**Image**:
```json
{ "type": "image", "data": "base64data", "mimeType": "image/png" }
```

**Resource**:
```json
{ "type": "resource", "uri": "file:///path/to/file" }
```

## Tool Registration Patterns

### Pattern: Tool with Validation

```python
from pydantic import BaseModel, validator

class ToolInput(BaseModel):
    email: str
    age: int

    @validator('email')
    def validate_email(cls, v):
        if '@' not in v:
            raise ValueError('Invalid email')
        return v

    @validator('age')
    def validate_age(cls, v):
        if not 0 <= v <= 150:
            raise ValueError('Age must be 0-150')
        return v

@mcp.tool()
def register_user(input: ToolInput) -> str:
    """Register user with validation."""
    return f"Registered {input.email}"
```

### Pattern: Tool with State

```python
from dataclasses import dataclass
from typing import Dict

@dataclass
class ServerState:
    cache: Dict[str, any]
    request_count: int

state = ServerState(cache={}, request_count=0)

@mcp.tool()
def cached_fetch(key: str) -> str:
    """Fetch with caching."""
    state.request_count += 1

    if key in state.cache:
        return f"Cached: {state.cache[key]}"

    result = fetch_data(key)
    state.cache[key] = result
    return result
```

### Pattern: Tool with Rate Limiting

```python
from collections import defaultdict
from time import time

rate_limits = defaultdict(list)

@mcp.tool()
def rate_limited_api(endpoint: str) -> str:
    """API call with rate limiting."""
    now = time()
    window = 60  # 1 minute
    max_calls = 10

    # Clean old calls
    rate_limits[endpoint] = [
        t for t in rate_limits[endpoint]
        if now - t < window
    ]

    # Check limit
    if len(rate_limits[endpoint]) >= max_calls:
        return f"Error: Rate limit exceeded ({max_calls} calls per minute)"

    # Record call
    rate_limits[endpoint].append(now)

    # Execute
    return call_api(endpoint)
```

## Performance Benchmarks

### Tool Execution Time Targets

| Category | Target | Acceptable | Poor |
|----------|--------|------------|------|
| Simple query | < 100ms | < 500ms | > 1s |
| File operations | < 200ms | < 1s | > 2s |
| API calls | < 500ms | < 2s | > 5s |
| Data processing | < 1s | < 5s | > 10s |

### MCP Protocol Overhead

**Typical Latency Breakdown**:
- JSON-RPC serialization: ~1ms
- Transport (stdio): ~5-10ms
- Transport (HTTP): ~20-50ms
- Schema validation: ~1-5ms
- Tool execution: Varies

**Total Overhead**: ~10-60ms (excluding tool logic)

### Optimization Strategies

**1. Reduce Payload Size**:
```python
# BAD: Return entire file
@mcp.tool()
def analyze_file(path: str) -> str:
    with open(path) as f:
        content = f.read()  # Could be huge!
    return content

# GOOD: Return summary
@mcp.tool()
def analyze_file(path: str) -> str:
    stats = {
        "lines": count_lines(path),
        "size": os.path.getsize(path),
        "type": detect_type(path)
    }
    return json.dumps(stats)
```

**2. Use Streaming**:
```python
@mcp.tool()
def process_stream(path: str) -> str:
    """Stream results incrementally."""
    results = []
    for chunk in read_chunks(path):
        results.append(process(chunk))
        if len(results) % 10 == 0:
            yield json.dumps({"progress": len(results)})

    yield json.dumps({"complete": True, "total": len(results)})
```

**3. Cache Expensive Operations**:
```python
from functools import lru_cache

@lru_cache(maxsize=128)
def expensive_computation(input: str) -> str:
    # Cached for repeated calls
    return compute(input)
```

### Memory Usage Guidelines

**Target**: < 100MB per MCP server

**Monitoring**:
```python
import psutil
import os

def get_memory_usage() -> int:
    """Get current memory usage in MB."""
    process = psutil.Process(os.getpid())
    return process.memory_info().rss // 1024 // 1024

@mcp.tool()
def memory_status() -> str:
    """Check server memory usage."""
    usage_mb = get_memory_usage()
    return f"Memory usage: {usage_mb}MB"
```

## Error Code Conventions

### Custom Error Codes

Use negative codes for application errors:

```python
ERROR_CODES = {
    -1001: "Resource not found",
    -1002: "Permission denied",
    -1003: "Invalid input",
    -1004: "Operation timeout",
    -1005: "External service unavailable"
}

@mcp.tool()
def guarded_operation(input: str) -> str:
    if not validate(input):
        return json.dumps({
            "error": {
                "code": -1003,
                "message": ERROR_CODES[-1003],
                "details": "Input must be alphanumeric"
            }
        })

    return process(input)
```

## Configuration Reference

### Environment Variables

**Common Configuration**:
```bash
# Server settings
MCP_SERVER_NAME="my-server"
MCP_SERVER_VERSION="1.0.0"

# Logging
LOG_LEVEL="INFO"  # DEBUG, INFO, WARNING, ERROR
LOG_FORMAT="json"  # json or text

# Performance
MAX_CONCURRENT_TOOLS=10
TOOL_TIMEOUT_SECONDS=30

# Security
ALLOWED_ORIGINS="http://localhost:3000"
REQUIRE_AUTH=true
```

**Loading Configuration**:
```python
import os

CONFIG = {
    "name": os.getenv("MCP_SERVER_NAME", "default-server"),
    "version": os.getenv("MCP_SERVER_VERSION", "1.0.0"),
    "log_level": os.getenv("LOG_LEVEL", "INFO"),
    "tool_timeout": int(os.getenv("TOOL_TIMEOUT_SECONDS", "30"))
}
```

## Testing Utilities

### Schema Validator

```python
import jsonschema

def validate_schema(schema: dict) -> list[str]:
    """Validate JSON schema is correct."""
    errors = []
    try:
        jsonschema.Draft7Validator.check_schema(schema)
    except jsonschema.SchemaError as e:
        errors.append(f"Invalid schema: {e.message}")

    return errors
```

### Tool Call Tester

```python
def test_tool_call(tool_func, args: dict, expected_contains: str):
    """Test tool with arguments."""
    result = tool_func(**args)
    assert expected_contains in result, \
        f"Expected '{expected_contains}' in result, got: {result}"
```

### Performance Profiler

```python
import time
from functools import wraps

def profile_tool(func):
    """Decorator to profile tool execution."""
    @wraps(func)
    def wrapper(*args, **kwargs):
        start = time.time()
        result = func(*args, **kwargs)
        duration = time.time() - start

        print(f"Tool {func.__name__} took {duration*1000:.2f}ms")
        return result
    return wrapper
```

## External Resources

### Official Documentation
- **MCP Specification**: https://spec.modelcontextprotocol.io/
- **FastMCP GitHub**: https://github.com/jlowin/fastmcp
- **MCP TypeScript SDK**: https://github.com/modelcontextprotocol/typescript-sdk
- **JSON Schema**: https://json-schema.org/understanding-json-schema/

### Community Resources
- **MCP Examples**: https://github.com/modelcontextprotocol/servers
- **FastMCP Examples**: https://github.com/jlowin/fastmcp/tree/main/examples

### Related Standards
- **JSON-RPC 2.0**: https://www.jsonrpc.org/specification
- **OpenAPI**: https://swagger.io/specification/
- **gRPC**: https://grpc.io/ (alternative protocol)

## Quick Reference Tables

### Common Schema Patterns

| Use Case | Schema |
|----------|--------|
| Email | `{"type": "string", "format": "email"}` |
| URL | `{"type": "string", "format": "uri"}` |
| Date | `{"type": "string", "format": "date-time"}` |
| Enum | `{"type": "string", "enum": ["a", "b", "c"]}` |
| Optional | `{"type": "string", "default": "value"}` |
| Range | `{"type": "integer", "minimum": 0, "maximum": 100}` |

### Tool Design Checklist

- [ ] Clear, descriptive name
- [ ] Detailed description
- [ ] Well-defined parameter schema
- [ ] Input validation
- [ ] Error handling
- [ ] Security checks
- [ ] Performance timeout
- [ ] Test coverage
- [ ] Documentation

### Debugging Commands

```bash
# Test JSON schema validity
python -m jsonschema -i params.json schema.json

# Monitor MCP server (stderr output)
python server.py 2> debug.log

# Test tool directly (bypass MCP)
python -c "from server import my_tool; print(my_tool('test'))"

# Check memory usage
ps aux | grep "python server.py"
```
