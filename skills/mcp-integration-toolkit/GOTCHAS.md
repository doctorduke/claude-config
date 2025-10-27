# MCP Integration Gotchas and Troubleshooting

## Common Pitfalls

### 1. Transport Mismatch
**Problem**: Server and client using incompatible transports
```
Error: Failed to connect to MCP server
```

**Solution**: Ensure both use the same transport (stdio is default)
```python
# Server
mcp.run()  # Default stdio

# Client config must also use stdio (default)
{
  "mcpServers": {
    "my-server": {
      "command": "python",
      "args": ["server.py"]
    }
  }
}
```

### 2. Schema Validation Errors
**Problem**: Tool input schemas must be valid JSON Schema
```
Error: Invalid schema for tool 'my_tool'
```

**Common Mistakes**:
```python
# WRONG - Python type hints aren't JSON Schema
def my_tool(items: list[str]) -> dict:
    pass

# CORRECT - Use proper JSON Schema
@mcp.tool()
def my_tool(items: list) -> dict:
    """
    Tool with proper schema

    Args:
        items: List of strings
    """
    pass
```

### 3. Stdio Buffering Issues
**Problem**: Output not appearing, server seems frozen

**Solution**: Always flush stdout in Python
```python
import sys

# After any stdout write
sys.stdout.flush()

# Or use stderr for logging (recommended)
logging.basicConfig(stream=sys.stderr)
```

### 4. Authentication Failures
**Problem**: API keys exposed or not working

**Never Do This**:
```python
API_KEY = "sk-abc123..."  # NEVER hardcode!
```

**Always Do This**:
```python
import os
API_KEY = os.getenv("API_KEY")
if not API_KEY:
    raise ValueError("API_KEY environment variable required")
```

### 5. Unhandled Exceptions Crash Server
**Problem**: One error kills entire server

**Solution**: Always wrap tool logic in try/except
```python
@mcp.tool()
def risky_operation(param: str) -> dict:
    try:
        # Risky code here
        result = perform_operation(param)
        return {"status": "success", "result": result}
    except ValueError as e:
        return {"status": "error", "message": str(e)}
    except Exception as e:
        logger.exception("Unexpected error")
        return {"status": "error", "message": "Internal server error"}
```

### 6. Async/Sync Confusion
**Problem**: Mixing async and sync incorrectly

**FastMCP Handles Both**:
```python
# Sync tool (FastMCP auto-handles)
@mcp.tool()
def sync_tool() -> str:
    return "result"

# Async tool (FastMCP detects async)
@mcp.tool()
async def async_tool() -> str:
    await asyncio.sleep(1)
    return "result"
```

**MCP SDK Requires Explicit Async**:
```typescript
// Always use async in TypeScript SDK
server.setRequestHandler(CallToolRequestSchema, async (request) => {
    // Must be async
});
```

### 7. Resource URI Format
**Problem**: Invalid resource URIs
```
Error: Invalid resource URI: /path/to/file
```

**Solution**: Always use proper URI format
```python
# WRONG
@mcp.resource("/users/123")

# CORRECT - Must have protocol
@mcp.resource("db://users/123")
@mcp.resource("file:///path/to/file")
@mcp.resource("https://api.example.com/data")
```

### 8. Tool Discovery Cache
**Problem**: Client doesn't see new tools after server update

**Solution**: Restart client after server changes
```bash
# Claude Code caches tool list
# After changing server, restart Claude Code
```

### 9. Large Response Truncation
**Problem**: Large responses get cut off

**Solution**: Implement pagination
```python
@mcp.tool()
def list_items(offset: int = 0, limit: int = 100) -> dict:
    items = get_all_items()
    page = items[offset:offset + limit]
    return {
        "items": page,
        "total": len(items),
        "has_more": offset + limit < len(items)
    }
```

### 10. Windows Path Issues
**Problem**: Backslashes in paths cause escaping issues

**Solution**: Use forward slashes or raw strings
```python
# WRONG on Windows
path = "C:\Users\name\file.txt"

# CORRECT
path = "C:/Users/name/file.txt"
# OR
path = r"C:\Users\name\file.txt"
# OR (best)
path = Path("C:/Users/name/file.txt")
```

## Debugging Techniques

### 1. Enable Verbose Logging

```python
import logging
import sys

logging.basicConfig(
    level=logging.DEBUG,
    stream=sys.stderr,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
```

### 2. Test Outside MCP First

```python
# Test your function standalone first
def my_logic(param):
    return result

# Test it
assert my_logic("test") == expected

# Then wrap in MCP
@mcp.tool()
def my_tool(param: str):
    return my_logic(param)
```

### 3. Use MCP Inspector

```bash
# Interactive testing
mcp-inspector python server.py

# In inspector:
# - List tools
# - Call tools with test data
# - See raw protocol messages
```

### 4. Protocol Message Debugging

```python
# Log raw protocol messages
import json

class DebugTransport:
    def write(self, message):
        print(f"SEND: {json.dumps(message)}", file=sys.stderr)

    def read(self):
        message = original_read()
        print(f"RECV: {json.dumps(message)}", file=sys.stderr)
        return message
```

## Error Message Reference

### Common MCP Error Codes

| Code | Meaning | Solution |
|------|---------|----------|
| -32700 | Parse error | Check JSON syntax |
| -32600 | Invalid request | Verify request format |
| -32601 | Method not found | Tool name typo |
| -32602 | Invalid params | Check parameter types |
| -32603 | Internal error | Check server logs |

### FastMCP Specific Errors

```python
# Import errors
"ModuleNotFoundError: No module named 'fastmcp'"
# Solution: pip install fastmcp

# Version mismatch
"FastMCP requires Python 3.8+"
# Solution: Upgrade Python

# Async context errors
"RuntimeError: This event loop is already running"
# Solution: Don't call mcp.run() inside async context
```

### MCP SDK Specific Errors

```typescript
// TypeScript compilation errors
"Cannot find module '@modelcontextprotocol/sdk'"
// Solution: npm install @modelcontextprotocol/sdk

// Transport errors
"Error: stdio transport requires process.stdin"
// Solution: Ensure running in Node.js environment, not browser
```

## Performance Troubleshooting

### Slow Tool Execution

1. **Profile the code**:
```python
import time

@mcp.tool()
def slow_tool():
    start = time.time()
    result = expensive_operation()
    logger.info(f"Operation took {time.time() - start}s")
    return result
```

2. **Add caching**:
```python
from functools import lru_cache

@lru_cache(maxsize=100)
def expensive_operation(param):
    # Cached computation
    return result
```

3. **Use async for I/O**:
```python
@mcp.tool()
async def fast_tool():
    # Parallel I/O operations
    results = await asyncio.gather(
        fetch_data1(),
        fetch_data2(),
        fetch_data3()
    )
    return combine_results(results)
```

### Memory Leaks

Watch for:
- Unbounded caches
- Global state accumulation
- Unclosed connections

```python
# Monitor memory usage
import psutil
import os

def log_memory():
    process = psutil.Process(os.getpid())
    mem = process.memory_info().rss / 1024 / 1024
    logger.info(f"Memory usage: {mem:.2f} MB")
```

## Recovery Procedures

### Server Won't Start

1. Check Python/Node version
2. Verify all dependencies installed
3. Test with minimal server
4. Check for port conflicts (HTTP/SSE transport)
5. Verify file permissions

### Client Can't Connect

1. Verify server is running
2. Check transport configuration matches
3. Verify command path is absolute
4. Check environment variables
5. Review client logs

### Tools Not Working

1. Validate tool schema
2. Check parameter types match
3. Verify return type is JSON-serializable
4. Test tool function standalone
5. Check for exceptions in tool code