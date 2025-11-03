# Knowledge: AI Agent Tool Builder

Comprehensive theory, architecture, and design principles for building tools that AI agents can use.

## Model Context Protocol (MCP)

### What is MCP?

MCP is an open protocol that standardizes how AI applications connect to external tools and data sources. Think of it as USB for AI - a universal interface.

**Key Components**:
1. **Server**: Exposes tools, resources, and prompts
2. **Client**: Connects to servers and uses capabilities
3. **Transport**: Communication layer (stdio, HTTP, WebSocket)
4. **Protocol**: Message format and semantics

### MCP Architecture

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│   AI Agent  │◄────────┤ MCP Client  │◄────────┤ MCP Server  │
│   (Claude)  │         │  (Consumer) │         │  (Provider) │
└─────────────┘         └─────────────┘         └─────────────┘
                              ▲                         ▲
                              │                         │
                        Requests tools           Implements tools
                        Gets results             Validates inputs
```

**Message Flow**:
1. Agent decides to use tool
2. Client sends `tools/call` request to server
3. Server validates parameters
4. Server executes tool logic
5. Server returns result to client
6. Client passes result back to agent

### MCP vs Alternatives

| Feature | MCP | LangChain Tools | OpenAI Functions |
|---------|-----|-----------------|------------------|
| Protocol Spec | Open standard | Framework-specific | API-specific |
| Language Support | Any (via SDK) | Python/JS focused | Any (JSON schema) |
| Transport | Pluggable | Code-level | HTTP only |
| Server Model | Long-lived | Ephemeral | Stateless |
| Resource Access | Built-in | Manual | Not supported |
| Best For | Reusable tools | Rapid prototyping | OpenAI integration |

## Function Calling Concepts

### What is Function Calling?

LLMs can generate structured function calls based on user intent:

```
User: "What's the weather in Paris?"
↓
LLM analyzes intent
↓
LLM generates function call:
{
  "name": "get_weather",
  "parameters": {
    "location": "Paris",
    "units": "celsius"
  }
}
↓
System executes function
↓
LLM receives result: "22°C, partly cloudy"
↓
LLM responds: "The weather in Paris is 22°C and partly cloudy."
```

### Function Calling Schema

JSON Schema defines function parameters:

```json
{
  "name": "get_weather",
  "description": "Get current weather for a location",
  "parameters": {
    "type": "object",
    "properties": {
      "location": {
        "type": "string",
        "description": "City name or coordinates"
      },
      "units": {
        "type": "string",
        "enum": ["celsius", "fahrenheit"],
        "description": "Temperature units"
      }
    },
    "required": ["location"]
  }
}
```

**Schema Components**:
- **name**: Unique identifier for function
- **description**: What function does (LLM uses for selection)
- **parameters**: JSON Schema object defining inputs
- **required**: Which parameters are mandatory

### Parameter Types

| Type | Example | Validation |
|------|---------|------------|
| string | "hello" | Pattern, minLength, maxLength, enum |
| number | 42, 3.14 | minimum, maximum, multipleOf |
| integer | 42 | minimum, maximum, multipleOf |
| boolean | true, false | None |
| array | [1,2,3] | items, minItems, maxItems, uniqueItems |
| object | {"key": "val"} | properties, required, additionalProperties |

## Tool Design Principles

### 1. Single Responsibility

Each tool does ONE thing well:

```python
# BAD: Tool does too much
@mcp.tool()
def process_data(action: str, data: str):
    if action == "validate":
        return validate(data)
    elif action == "transform":
        return transform(data)
    elif action == "save":
        return save(data)

# GOOD: Separate tools for each action
@mcp.tool()
def validate_data(data: str) -> bool:
    """Check if data is valid."""
    return is_valid(data)

@mcp.tool()
def transform_data(data: str) -> str:
    """Transform data format."""
    return transform(data)

@mcp.tool()
def save_data(data: str, path: str) -> str:
    """Save data to file."""
    write_file(path, data)
    return f"Saved to {path}"
```

### 2. Composability

Tools should work together:

```python
# Tools that compose well
result = validate_data(input_data)
if result:
    transformed = transform_data(input_data)
    save_data(transformed, "output.json")
```

**Design for Composition**:
- Return structured data (JSON, not free text)
- Accept common data formats
- Use consistent naming conventions
- Document output format clearly

### 3. Idempotency

Same input → same output, no side effects:

```python
# GOOD: Idempotent read operation
@mcp.tool()
def get_file_size(path: str) -> int:
    """Get file size in bytes."""
    return os.path.getsize(path)

# BAD: Non-idempotent with side effects
@mcp.tool()
def process_queue() -> str:
    """Process next queue item (destructive!)"""
    item = queue.pop()  # Changes queue state!
    return process(item)

# BETTER: Explicit intent
@mcp.tool()
def peek_queue() -> str:
    """View next queue item without removing."""
    return queue[0]

@mcp.tool()
def consume_queue() -> str:
    """Remove and process next queue item."""
    item = queue.pop()
    return process(item)
```

### 4. Fail-Safe Defaults

Safe behavior when parameters missing:

```python
@mcp.tool()
def delete_files(
    pattern: str,
    confirm: bool = True,  # Require explicit confirmation
    dry_run: bool = True   # Default to simulation
) -> str:
    """Delete files matching pattern."""
    if not confirm:
        return "Error: confirm=True required for deletion"

    files = glob.glob(pattern)

    if dry_run:
        return f"Would delete {len(files)} files: {files}"

    for f in files:
        os.remove(f)
    return f"Deleted {len(files)} files"
```

### 5. Clear Error Messages

Help agent understand what went wrong:

```python
# BAD: Cryptic error
@mcp.tool()
def divide(a: float, b: float) -> float:
    return a / b  # ZeroDivisionError: division by zero

# GOOD: Descriptive error
@mcp.tool()
def divide(a: float, b: float) -> str:
    """Divide a by b."""
    if b == 0:
        return "Error: Cannot divide by zero. Please provide non-zero divisor."
    result = a / b
    return f"{a} / {b} = {result}"
```

## JSON Schema for Parameters

### Basic Schema Structure

```json
{
  "type": "object",
  "properties": {
    "param_name": {
      "type": "string",
      "description": "What this parameter does"
    }
  },
  "required": ["param_name"]
}
```

### Advanced Validation

```json
{
  "type": "object",
  "properties": {
    "email": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+$",
      "description": "User email address"
    },
    "age": {
      "type": "integer",
      "minimum": 0,
      "maximum": 150,
      "description": "User age in years"
    },
    "tags": {
      "type": "array",
      "items": {"type": "string"},
      "minItems": 1,
      "maxItems": 10,
      "uniqueItems": true,
      "description": "List of tags"
    },
    "priority": {
      "type": "string",
      "enum": ["low", "medium", "high", "critical"],
      "default": "medium",
      "description": "Task priority level"
    }
  },
  "required": ["email", "priority"]
}
```

### Nested Objects

```json
{
  "type": "object",
  "properties": {
    "user": {
      "type": "object",
      "properties": {
        "name": {"type": "string"},
        "age": {"type": "integer"}
      },
      "required": ["name"]
    },
    "permissions": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "resource": {"type": "string"},
          "actions": {
            "type": "array",
            "items": {"type": "string"}
          }
        }
      }
    }
  }
}
```

## Security Considerations

### 1. Input Validation

**Always validate before execution**:

```python
import os
import re

@mcp.tool()
def read_file(file_path: str) -> str:
    """Read file contents."""
    # Validate path doesn't escape allowed directory
    allowed_dir = "/data"
    abs_path = os.path.abspath(file_path)
    if not abs_path.startswith(allowed_dir):
        return f"Error: Access denied. Path must be within {allowed_dir}"

    # Check file exists
    if not os.path.isfile(abs_path):
        return f"Error: File not found: {file_path}"

    # Check file size (prevent reading huge files)
    if os.path.getsize(abs_path) > 10_000_000:  # 10MB
        return "Error: File too large (>10MB)"

    with open(abs_path) as f:
        return f.read()
```

### 2. Command Injection Prevention

```python
import subprocess
import shlex

# BAD: Command injection vulnerability
@mcp.tool()
def run_command(cmd: str) -> str:
    return subprocess.run(cmd, shell=True, capture_output=True).stdout.decode()

# GOOD: Whitelist approach
ALLOWED_COMMANDS = {"ls", "pwd", "date", "whoami"}

@mcp.tool()
def run_command(cmd: str) -> str:
    """Run whitelisted command."""
    parts = shlex.split(cmd)
    if not parts or parts[0] not in ALLOWED_COMMANDS:
        return f"Error: Command not allowed. Allowed: {ALLOWED_COMMANDS}"

    result = subprocess.run(parts, capture_output=True, text=True)
    return result.stdout
```

### 3. Path Traversal Prevention

```python
import os

@mcp.tool()
def write_file(filename: str, content: str) -> str:
    """Write content to file in safe directory."""
    # Sanitize filename
    safe_filename = os.path.basename(filename)  # Remove path components
    if safe_filename != filename:
        return f"Error: Invalid filename. Use basename only."

    # Check for dangerous patterns
    if ".." in filename or filename.startswith("/"):
        return "Error: Path traversal not allowed"

    # Write to safe directory
    safe_dir = "/data/uploads"
    full_path = os.path.join(safe_dir, safe_filename)

    with open(full_path, "w") as f:
        f.write(content)

    return f"Written to {full_path}"
```

### 4. Rate Limiting

```python
from collections import defaultdict
from time import time

# Simple rate limiter
call_times = defaultdict(list)
MAX_CALLS_PER_MINUTE = 10

@mcp.tool()
def expensive_operation(input: str) -> str:
    """Rate-limited expensive operation."""
    tool_name = "expensive_operation"
    now = time()

    # Remove calls older than 1 minute
    call_times[tool_name] = [t for t in call_times[tool_name] if now - t < 60]

    # Check rate limit
    if len(call_times[tool_name]) >= MAX_CALLS_PER_MINUTE:
        return "Error: Rate limit exceeded. Try again in 1 minute."

    # Record this call
    call_times[tool_name].append(now)

    # Execute operation
    return do_expensive_work(input)
```

## Tool Ecosystem Design

### Tool Categories

**Query Tools**: Read-only information retrieval
- Example: `get_file_contents`, `search_database`, `fetch_url`
- Characteristics: Idempotent, no side effects, fast

**Mutation Tools**: Modify state
- Example: `write_file`, `update_database`, `send_email`
- Characteristics: Require confirmation, logged, reversible if possible

**Analysis Tools**: Process and transform data
- Example: `analyze_code`, `parse_json`, `calculate_metrics`
- Characteristics: Pure functions, deterministic, composable

**Integration Tools**: Connect to external systems
- Example: `github_create_pr`, `slack_send_message`, `jira_create_ticket`
- Characteristics: Handle auth, retry logic, error translation

### Tool Discovery

Help agents find the right tool:

```python
@mcp.tool()
def list_available_tools() -> str:
    """List all available tools with descriptions."""
    tools = [
        {"name": "read_file", "category": "query", "description": "Read file contents"},
        {"name": "write_file", "category": "mutation", "description": "Write data to file"},
        {"name": "analyze_code", "category": "analysis", "description": "Analyze code complexity"},
    ]
    return json.dumps(tools, indent=2)

@mcp.tool()
def search_tools(keyword: str) -> str:
    """Search for tools by keyword."""
    # Return tools matching keyword in name or description
    pass
```

## Agent-Tool Communication Patterns

### Synchronous Request-Response

Standard pattern for most tools:

```
Agent: "Call read_file with path=/data/config.json"
  ↓
Tool executes
  ↓
Tool: "{'api_key': 'xxx', 'timeout': 30}"
  ↓
Agent: "The API key is xxx and timeout is 30 seconds."
```

### Streaming Results

For long-running operations:

```python
@mcp.tool()
def process_large_file(path: str) -> str:
    """Process file and stream progress."""
    total_lines = count_lines(path)
    for i, line in enumerate(read_lines(path)):
        process_line(line)
        if i % 1000 == 0:
            yield f"Processed {i}/{total_lines} lines"
    yield f"Complete: {total_lines} lines processed"
```

### Confirmation Required

For dangerous operations:

```python
@mcp.tool()
def delete_all_files(directory: str, confirmed: bool = False) -> str:
    """Delete all files in directory. Requires confirmation."""
    if not confirmed:
        files = os.listdir(directory)
        return f"WARNING: This will delete {len(files)} files in {directory}. Call again with confirmed=true to proceed."

    # Proceed with deletion
    for f in os.listdir(directory):
        os.remove(os.path.join(directory, f))
    return f"Deleted all files in {directory}"
```

## Performance Considerations

### Tool Execution Time

**Targets**:
- Query tools: < 1 second
- Mutation tools: < 2 seconds
- Analysis tools: < 5 seconds
- Long operations: Use streaming or background tasks

**Optimization Strategies**:
- Cache expensive computations
- Use async I/O for network calls
- Batch operations when possible
- Provide progress feedback for long tasks

### Resource Management

```python
import functools
from concurrent.futures import ThreadPoolExecutor

# Connection pooling
executor = ThreadPoolExecutor(max_workers=10)

@functools.lru_cache(maxsize=100)
def expensive_computation(input: str) -> str:
    """Cached expensive computation."""
    return compute(input)

@mcp.tool()
def parallel_process(items: list[str]) -> str:
    """Process items in parallel."""
    futures = [executor.submit(process_item, item) for item in items]
    results = [f.result() for f in futures]
    return json.dumps(results)
```

## References

- **MCP Specification**: https://spec.modelcontextprotocol.io/
- **FastMCP Documentation**: https://github.com/jlowin/fastmcp
- **MCP TypeScript SDK**: https://github.com/modelcontextprotocol/typescript-sdk
- **JSON Schema Specification**: https://json-schema.org/
- **OpenAI Function Calling**: https://platform.openai.com/docs/guides/function-calling
- **Anthropic Tool Use**: https://docs.anthropic.com/claude/docs/tool-use
