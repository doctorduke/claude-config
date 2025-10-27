# Gotchas: AI Agent Tool Builder

Common issues, troubleshooting strategies, and debugging techniques for tool development.

## Schema Validation Failures

### Issue: LLM Generates Invalid Parameters

**Symptom**: Tool call fails with schema validation error, agent receives "Invalid parameters" message.

**Common Causes**:
1. Schema too complex for LLM to understand
2. Ambiguous parameter descriptions
3. Type mismatches (string vs number)
4. Missing required parameters

**Example**:
```python
# BAD: Ambiguous schema
{
  "name": "process_data",
  "description": "Process data",  # Too vague!
  "parameters": {
    "data": {"type": "string"}  # What format? What constraints?
  }
}

# GOOD: Clear, constrained schema
{
  "name": "process_json_data",
  "description": "Parse and validate JSON data, returning key statistics",
  "parameters": {
    "json_string": {
      "type": "string",
      "description": "Valid JSON string to process (e.g., '{\"key\": \"value\"}')",
      "minLength": 2
    }
  }
}
```

**Solution**:
1. Simplify parameter structure
2. Add examples in descriptions
3. Use enums for limited choices
4. Provide defaults for optional parameters

**Debugging**:
```python
import jsonschema

def validate_tool_call(schema, params):
    """Test if parameters match schema."""
    try:
        jsonschema.validate(instance=params, schema=schema)
        print("✓ Valid parameters")
    except jsonschema.ValidationError as e:
        print(f"✗ Validation error: {e.message}")
        print(f"  Failed path: {'.'.join(str(p) for p in e.path)}")
        print(f"  Schema path: {'.'.join(str(p) for p in e.schema_path)}")

# Test your schema
validate_tool_call(
    schema={"type": "integer", "minimum": 0, "maximum": 100},
    params=-5  # Should fail
)
```

### Issue: Type Coercion Problems

**Symptom**: Tool receives unexpected types (string "123" instead of integer 123).

**Solution**:
```python
@mcp.tool()
def process_number(value: str) -> str:  # Accept as string
    """Process a number."""
    try:
        # Validate and convert
        num = int(value)
        if not 0 <= num <= 100:
            return "Error: Number must be between 0 and 100"

        return f"Processed: {num}"
    except ValueError:
        return f"Error: '{value}' is not a valid integer"
```

## MCP Protocol Versioning

### Issue: Client and Server Version Mismatch

**Symptom**: Connection fails with "Protocol version mismatch" or undefined behavior.

**Common Causes**:
1. Client uses newer protocol version than server
2. SDK versions out of sync
3. Breaking changes between MCP versions

**Solution**:
```python
# In FastMCP - specify protocol version
from fastmcp import FastMCP

mcp = FastMCP(
    "My Server",
    version="1.0.0",
    protocol_version="2024-11-05"  # Pin protocol version
)
```

```typescript
// In TypeScript SDK - check compatibility
const server = new Server(
  {
    name: "my-server",
    version: "1.0.0",
    protocolVersion: "2024-11-05"
  },
  { capabilities: { tools: {} } }
);
```

**Prevention**:
- Pin SDK versions in requirements.txt / package.json
- Test with multiple client versions
- Document minimum required versions

## Error Handling Patterns

### Issue: Raw Exceptions Leak Internal Details

**Symptom**: Agent sees "FileNotFoundError: /internal/secret/path/file.txt" exposing internal paths.

**BAD**:
```python
@mcp.tool()
def read_config() -> str:
    with open("/internal/secret/config.json") as f:
        return f.read()  # Leaks internal path in exception!
```

**GOOD**:
```python
@mcp.tool()
def read_config() -> str:
    """Read application configuration."""
    try:
        with open("/internal/secret/config.json") as f:
            return f.read()
    except FileNotFoundError:
        return "Error: Configuration file not found"
    except PermissionError:
        return "Error: Permission denied reading configuration"
    except Exception as e:
        # Log internally but don't expose details
        import logging
        logging.error(f"Config read failed: {e}")
        return "Error: Failed to read configuration"
```

### Issue: Silent Failures

**Symptom**: Tool returns success but didn't actually work.

**BAD**:
```python
@mcp.tool()
def send_email(to: str, subject: str) -> str:
    try:
        send(to, subject)
    except:
        pass  # Silent failure!
    return "Email sent"
```

**GOOD**:
```python
@mcp.tool()
def send_email(to: str, subject: str) -> str:
    """Send email to recipient."""
    try:
        result = send(to, subject)
        return f"Email sent to {to} (ID: {result.message_id})"
    except SMTPException as e:
        return f"Error: Failed to send email: {str(e)}"
    except Exception as e:
        return f"Error: Unexpected failure sending email"
```

## Security Vulnerabilities

### Issue: Command Injection

**Symptom**: Malicious input executes arbitrary commands.

**VULNERABLE**:
```python
@mcp.tool()
def convert_image(input_file: str, output_format: str) -> str:
    # DANGEROUS: Command injection via input_file!
    cmd = f"convert {input_file} output.{output_format}"
    subprocess.run(cmd, shell=True)  # Shell=True is dangerous!
    return "Converted"

# Agent could call with:
# input_file = "image.png; rm -rf /"  # Deletes everything!
```

**SECURE**:
```python
import shlex
import subprocess

@mcp.tool()
def convert_image(input_file: str, output_format: str) -> str:
    """Convert image to different format."""
    # Whitelist allowed formats
    allowed_formats = ["jpg", "png", "gif", "webp"]
    if output_format not in allowed_formats:
        return f"Error: Format must be one of {allowed_formats}"

    # Validate input file
    if not os.path.isfile(input_file):
        return f"Error: Input file not found"

    # Use list arguments (NOT shell=True)
    output_file = f"output.{output_format}"
    try:
        subprocess.run(
            ["convert", input_file, output_file],  # List, not string
            check=True,
            capture_output=True
        )
        return f"Converted to {output_file}"
    except subprocess.CalledProcessError as e:
        return f"Error: Conversion failed: {e.stderr.decode()}"
```

### Issue: Path Traversal

**Symptom**: Attacker accesses files outside intended directory.

**VULNERABLE**:
```python
@mcp.tool()
def read_user_file(filename: str) -> str:
    # DANGEROUS: Path traversal via ../
    path = f"/data/uploads/{filename}"
    with open(path) as f:
        return f.read()

# Agent could call with:
# filename = "../../../etc/passwd"  # Reads system files!
```

**SECURE**:
```python
import os

@mcp.tool()
def read_user_file(filename: str) -> str:
    """Read file from user uploads directory."""
    # Validate filename has no path components
    if os.path.dirname(filename):
        return "Error: Filename must not contain path separators"

    # Use basename to strip any path
    safe_filename = os.path.basename(filename)

    # Build safe path
    base_dir = "/data/uploads"
    file_path = os.path.join(base_dir, safe_filename)

    # Verify result is within base directory
    abs_path = os.path.abspath(file_path)
    if not abs_path.startswith(os.path.abspath(base_dir)):
        return "Error: Invalid file path"

    # Now safe to read
    try:
        with open(abs_path) as f:
            return f.read()
    except FileNotFoundError:
        return f"Error: File not found: {safe_filename}"
```

### Issue: Sensitive Data in Logs

**Symptom**: API keys, passwords logged in plain text.

**BAD**:
```python
@mcp.tool()
def call_api(api_key: str, query: str) -> str:
    logger.info(f"Calling API with key={api_key}, query={query}")  # Logs key!
    return api_call(api_key, query)
```

**GOOD**:
```python
@mcp.tool()
def call_api(api_key: str, query: str) -> str:
    """Call external API with authentication."""
    # Mask sensitive data in logs
    masked_key = f"{api_key[:4]}...{api_key[-4:]}" if len(api_key) > 8 else "***"
    logger.info(f"Calling API with key={masked_key}, query={query}")

    return api_call(api_key, query)
```

## Performance Issues

### Issue: Slow Tools Block Agent

**Symptom**: Agent waits 30+ seconds for tool to respond, poor user experience.

**Causes**:
1. Synchronous blocking I/O
2. No timeout on external calls
3. Processing large datasets synchronously

**Solution 1: Add Timeouts**
```python
import requests

@mcp.tool()
def fetch_url(url: str) -> str:
    """Fetch URL with timeout."""
    try:
        response = requests.get(url, timeout=5)  # 5 second timeout
        return response.text
    except requests.Timeout:
        return "Error: Request timed out after 5 seconds"
    except requests.RequestException as e:
        return f"Error: Request failed: {str(e)}"
```

**Solution 2: Streaming for Long Operations**
```python
@mcp.tool()
def process_large_file(file_path: str) -> str:
    """Process file with progress updates."""
    results = []
    total_lines = sum(1 for _ in open(file_path))

    with open(file_path) as f:
        for i, line in enumerate(f):
            process_line(line)

            # Provide progress every 1000 lines
            if i % 1000 == 0:
                progress = (i / total_lines) * 100
                results.append(f"Progress: {progress:.1f}%")

    results.append(f"Complete: Processed {total_lines} lines")
    return "\n".join(results)
```

**Solution 3: Background Tasks**
```python
import asyncio
from typing import Optional

task_status = {}

@mcp.tool()
def start_long_task(task_id: str, input_data: str) -> str:
    """Start long-running task in background."""
    async def run_task():
        task_status[task_id] = {"status": "running", "progress": 0}
        try:
            result = await expensive_operation(input_data)
            task_status[task_id] = {"status": "complete", "result": result}
        except Exception as e:
            task_status[task_id] = {"status": "failed", "error": str(e)}

    asyncio.create_task(run_task())
    return f"Task {task_id} started. Use check_task_status to monitor."

@mcp.tool()
def check_task_status(task_id: str) -> str:
    """Check status of background task."""
    status = task_status.get(task_id)
    if not status:
        return f"Error: Task {task_id} not found"

    return json.dumps(status)
```

### Issue: Memory Leaks in Long-Running Servers

**Symptom**: Server memory grows unbounded over time.

**Causes**:
1. Caching without size limits
2. Not closing file handles
3. Circular references preventing garbage collection

**Solution**:
```python
from functools import lru_cache
import weakref

# Use bounded cache
@lru_cache(maxsize=100)  # Limit cache size
def expensive_computation(input: str) -> str:
    return compute(input)

# Close resources properly
@mcp.tool()
def process_file(path: str) -> str:
    """Process file with proper resource management."""
    try:
        with open(path) as f:  # Automatically closed
            data = f.read()
        return process(data)
    except Exception as e:
        return f"Error: {str(e)}"

# Use weak references for cache
class ResourceCache:
    def __init__(self):
        self._cache = weakref.WeakValueDictionary()

    def get(self, key):
        return self._cache.get(key)

    def set(self, key, value):
        self._cache[key] = value
```

## Testing Challenges

### Issue: Mocking External Dependencies

**Problem**: Tool calls external API, hard to test without real API.

**Solution**:
```python
# my_tool.py
import os
import requests

def get_api_client():
    """Get API client (mockable for tests)."""
    if os.getenv("TEST_MODE"):
        return MockAPIClient()
    return RealAPIClient()

@mcp.tool()
def fetch_data(query: str) -> str:
    """Fetch data from API."""
    client = get_api_client()
    return client.fetch(query)

# test_my_tool.py
import os
import pytest

class MockAPIClient:
    def fetch(self, query):
        return f"Mock result for {query}"

def test_fetch_data():
    os.environ["TEST_MODE"] = "1"
    result = fetch_data("test query")
    assert "Mock result" in result
```

### Issue: Testing MCP Protocol Integration

**Problem**: Hard to test tool works correctly with actual MCP client.

**Solution**:
```python
# test_mcp_integration.py
import asyncio
from fastmcp.client import Client

async def test_tool_via_mcp():
    """Test tool through actual MCP protocol."""
    # Start server as subprocess
    async with Client("python", "my_server.py") as client:
        # List tools
        tools = await client.list_tools()
        assert any(t.name == "my_tool" for t in tools)

        # Call tool
        result = await client.call_tool("my_tool", {"param": "value"})
        assert "expected output" in result.content[0].text

asyncio.run(test_tool_via_mcp())
```

## Deployment Considerations

### Issue: Environment-Specific Configuration

**Problem**: Tool works in dev but fails in production (different paths, credentials).

**Solution**:
```python
import os
from pathlib import Path

# Load configuration from environment
CONFIG = {
    "data_dir": os.getenv("DATA_DIR", "/data"),
    "api_key": os.getenv("API_KEY"),
    "timeout": int(os.getenv("TIMEOUT", "30")),
    "debug": os.getenv("DEBUG", "false").lower() == "true"
}

# Validate required config
required_keys = ["api_key"]
missing = [k for k in required_keys if not CONFIG.get(k)]
if missing:
    raise RuntimeError(f"Missing required config: {missing}")

@mcp.tool()
def get_data(query: str) -> str:
    """Fetch data using configured API."""
    # Use environment-specific config
    response = requests.get(
        "https://api.example.com/query",
        params={"q": query},
        headers={"Authorization": f"Bearer {CONFIG['api_key']}"},
        timeout=CONFIG["timeout"]
    )
    return response.text
```

### Issue: Logging and Monitoring

**Problem**: Tool fails in production, no visibility into what went wrong.

**Solution**:
```python
import logging
import time
import json

# Configure structured logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@mcp.tool()
def monitored_tool(input: str) -> str:
    """Tool with logging and metrics."""
    start_time = time.time()
    tool_name = "monitored_tool"

    # Log invocation
    logger.info(f"Tool {tool_name} called", extra={
        "tool": tool_name,
        "input_length": len(input)
    })

    try:
        result = do_work(input)

        # Log success
        duration = time.time() - start_time
        logger.info(f"Tool {tool_name} succeeded", extra={
            "tool": tool_name,
            "duration_ms": int(duration * 1000),
            "result_length": len(result)
        })

        return result

    except Exception as e:
        # Log failure
        duration = time.time() - start_time
        logger.error(f"Tool {tool_name} failed", extra={
            "tool": tool_name,
            "duration_ms": int(duration * 1000),
            "error": str(e),
            "error_type": type(e).__name__
        }, exc_info=True)

        return f"Error: {str(e)}"
```

## Debugging Strategies

### Strategy 1: Add Debug Mode

```python
import os

DEBUG = os.getenv("DEBUG", "false").lower() == "true"

@mcp.tool()
def debug_tool(input: str) -> str:
    """Tool with debug output."""
    if DEBUG:
        print(f"DEBUG: Input received: {repr(input)}", file=sys.stderr)

    result = process(input)

    if DEBUG:
        print(f"DEBUG: Result computed: {repr(result)}", file=sys.stderr)

    return result
```

### Strategy 2: Request/Response Logging

```python
import json
from datetime import datetime

LOG_FILE = "tool_calls.jsonl"

def log_tool_call(tool_name: str, args: dict, result: str):
    """Log all tool calls for debugging."""
    entry = {
        "timestamp": datetime.utcnow().isoformat(),
        "tool": tool_name,
        "arguments": args,
        "result": result[:100]  # First 100 chars
    }
    with open(LOG_FILE, "a") as f:
        f.write(json.dumps(entry) + "\n")

@mcp.tool()
def logged_tool(input: str) -> str:
    """Tool that logs all calls."""
    result = do_work(input)
    log_tool_call("logged_tool", {"input": input}, result)
    return result
```

### Strategy 3: Interactive Testing

```python
# test_interactive.py
from my_server import my_tool

def interactive_test():
    """Manually test tool from command line."""
    print("Tool Interactive Tester")
    print("Type 'quit' to exit\n")

    while True:
        input_data = input("Enter input: ")
        if input_data.lower() == "quit":
            break

        result = my_tool(input_data)
        print(f"Result: {result}\n")

if __name__ == "__main__":
    interactive_test()
```

## Common Error Messages

### "Tool not found"
- **Cause**: Tool name mismatch between registration and call
- **Fix**: Check tool name spelling, ensure tool is registered

### "Schema validation failed"
- **Cause**: Arguments don't match parameter schema
- **Fix**: Validate schema with jsonschema, check types

### "Connection refused"
- **Cause**: MCP server not running or wrong port
- **Fix**: Check server is running, verify transport configuration

### "Timeout waiting for response"
- **Cause**: Tool taking too long to execute
- **Fix**: Add timeouts, use background tasks for long operations

### "Permission denied"
- **Cause**: Tool trying to access restricted resource
- **Fix**: Check file permissions, validate paths are within allowed directories

## Summary

**Top Issues to Avoid**:
1. Schema validation failures → Use clear, simple schemas
2. Security vulnerabilities → Validate all inputs, sanitize paths
3. Poor error handling → Catch specific exceptions, return clear messages
4. Performance problems → Add timeouts, use streaming for long tasks
5. Testing challenges → Mock external dependencies, test via MCP protocol

**Debugging Checklist**:
- [ ] Enable debug logging
- [ ] Log all tool calls to file
- [ ] Test with multiple input variations
- [ ] Check schema matches implementation
- [ ] Verify error messages are clear
- [ ] Monitor performance and memory usage
- [ ] Review security implications

**When Stuck**:
1. Check MCP server logs (stderr)
2. Validate JSON schema independently
3. Test tool function directly (without MCP)
4. Compare with working example
5. Enable debug mode and trace execution
