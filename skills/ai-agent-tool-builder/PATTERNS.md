# Patterns: AI Agent Tool Builder

Implementation patterns for building MCP servers, function calling tools, and tool composition frameworks.

## Pattern 1: MCP Server with FastMCP (Python)

### When to Use
- Rapid prototyping of new tools
- Python-based tool logic
- Simple to medium complexity tools
- Need type hints and automatic schema generation

### Implementation

**Minimal Server**:
```python
from fastmcp import FastMCP

# Create server
mcp = FastMCP("My Tools")

# Add tools with decorator
@mcp.tool()
def greet(name: str) -> str:
    """Greet a person by name."""
    return f"Hello, {name}!"

# Run server
if __name__ == "__main__":
    mcp.run()
```

**Complete Server with Multiple Tools**:
```python
from fastmcp import FastMCP
from typing import Optional
import json
import os

mcp = FastMCP("File Operations")

@mcp.tool()
def read_file(file_path: str, max_lines: Optional[int] = None) -> str:
    """
    Read file contents.

    Args:
        file_path: Path to file to read
        max_lines: Maximum number of lines to read (optional)

    Returns:
        File contents or error message
    """
    try:
        if not os.path.isfile(file_path):
            return f"Error: File not found: {file_path}"

        with open(file_path, 'r') as f:
            if max_lines:
                lines = [f.readline() for _ in range(max_lines)]
                content = ''.join(lines)
            else:
                content = f.read()

        return content

    except PermissionError:
        return f"Error: Permission denied: {file_path}"
    except Exception as e:
        return f"Error reading file: {str(e)}"

@mcp.tool()
def write_file(file_path: str, content: str, append: bool = False) -> str:
    """
    Write content to file.

    Args:
        file_path: Path to file to write
        content: Content to write
        append: Append to file instead of overwriting

    Returns:
        Success message or error
    """
    try:
        mode = 'a' if append else 'w'
        with open(file_path, mode) as f:
            f.write(content)

        action = "Appended to" if append else "Wrote to"
        return f"{action} {file_path}"

    except Exception as e:
        return f"Error writing file: {str(e)}"

@mcp.tool()
def list_files(directory: str, pattern: Optional[str] = None) -> str:
    """
    List files in directory.

    Args:
        directory: Directory to list
        pattern: Optional glob pattern to filter files

    Returns:
        JSON array of file paths
    """
    import glob

    try:
        if not os.path.isdir(directory):
            return f"Error: Directory not found: {directory}"

        if pattern:
            search_path = os.path.join(directory, pattern)
            files = glob.glob(search_path)
        else:
            files = [os.path.join(directory, f) for f in os.listdir(directory)]

        return json.dumps(files, indent=2)

    except Exception as e:
        return f"Error listing files: {str(e)}"

# Add resource (optional)
@mcp.resource("file://{path}")
async def get_file_resource(path: str) -> str:
    """Get file as resource."""
    return read_file(path)

if __name__ == "__main__":
    mcp.run()
```

**Testing the Server**:
```python
# test_server.py
import pytest
from mcp_server import read_file, write_file, list_files
import tempfile
import os

def test_write_and_read_file():
    with tempfile.NamedTemporaryFile(delete=False) as tmp:
        tmp_path = tmp.name

    try:
        # Write
        result = write_file(tmp_path, "Hello, World!")
        assert "Wrote to" in result

        # Read
        content = read_file(tmp_path)
        assert content == "Hello, World!"
    finally:
        os.remove(tmp_path)

def test_read_nonexistent_file():
    result = read_file("/nonexistent/file.txt")
    assert "Error" in result

def test_list_files():
    with tempfile.TemporaryDirectory() as tmpdir:
        # Create test files
        for i in range(3):
            path = os.path.join(tmpdir, f"file{i}.txt")
            with open(path, 'w') as f:
                f.write(f"content{i}")

        # List files
        result = list_files(tmpdir)
        files = json.loads(result)
        assert len(files) == 3
```

### Best Practices

1. **Use Type Hints**: FastMCP generates schemas from type hints
2. **Write Docstrings**: Used as tool descriptions for agents
3. **Return Strings**: Simplest for agent consumption (or JSON strings)
4. **Handle Errors Gracefully**: Catch exceptions, return error messages
5. **Keep Tools Focused**: One tool = one responsibility

## Pattern 2: MCP Server with TypeScript SDK

### When to Use
- Production-grade tools requiring fine control
- Integration with Node.js ecosystem
- Complex protocol features (resources, prompts)
- Need for WebSocket or HTTP transport

### Implementation

**Minimal Server**:
```typescript
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { CallToolRequestSchema, ListToolsRequestSchema } from "@modelcontextprotocol/sdk/types.js";

// Create server
const server = new Server(
  {
    name: "example-server",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "greet",
        description: "Greet a person by name",
        inputSchema: {
          type: "object",
          properties: {
            name: {
              type: "string",
              description: "Name of person to greet",
            },
          },
          required: ["name"],
        },
      },
    ],
  };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  if (request.params.name === "greet") {
    const name = request.params.arguments.name as string;
    return {
      content: [
        {
          type: "text",
          text: `Hello, ${name}!`,
        },
      ],
    };
  }

  throw new Error(`Unknown tool: ${request.params.name}`);
});

// Start server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("MCP Server running on stdio");
}

main().catch(console.error);
```

**Complete Server with Error Handling**:
```typescript
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { CallToolRequestSchema, ListToolsRequestSchema } from "@modelcontextprotocol/sdk/types.js";
import * as fs from "fs/promises";
import * as path from "path";

const server = new Server(
  {
    name: "file-operations",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Define tools
const TOOLS = [
  {
    name: "read_file",
    description: "Read file contents",
    inputSchema: {
      type: "object",
      properties: {
        file_path: {
          type: "string",
          description: "Path to file to read",
        },
        max_bytes: {
          type: "number",
          description: "Maximum bytes to read (optional)",
        },
      },
      required: ["file_path"],
    },
  },
  {
    name: "write_file",
    description: "Write content to file",
    inputSchema: {
      type: "object",
      properties: {
        file_path: {
          type: "string",
          description: "Path to file to write",
        },
        content: {
          type: "string",
          description: "Content to write",
        },
      },
      required: ["file_path", "content"],
    },
  },
];

server.setRequestHandler(ListToolsRequestSchema, async () => {
  return { tools: TOOLS };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case "read_file": {
        const filePath = args.file_path as string;
        const maxBytes = (args.max_bytes as number) || undefined;

        try {
          const stats = await fs.stat(filePath);
          if (!stats.isFile()) {
            return {
              content: [{ type: "text", text: `Error: Not a file: ${filePath}` }],
            };
          }

          let content = await fs.readFile(filePath, "utf-8");
          if (maxBytes) {
            content = content.substring(0, maxBytes);
          }

          return {
            content: [{ type: "text", text: content }],
          };
        } catch (err) {
          const error = err as NodeJS.ErrnoException;
          if (error.code === "ENOENT") {
            return {
              content: [{ type: "text", text: `Error: File not found: ${filePath}` }],
            };
          }
          if (error.code === "EACCES") {
            return {
              content: [{ type: "text", text: `Error: Permission denied: ${filePath}` }],
            };
          }
          throw error;
        }
      }

      case "write_file": {
        const filePath = args.file_path as string;
        const content = args.content as string;

        try {
          await fs.writeFile(filePath, content, "utf-8");
          return {
            content: [{ type: "text", text: `Wrote to ${filePath}` }],
          };
        } catch (err) {
          return {
            content: [{ type: "text", text: `Error writing file: ${err}` }],
          };
        }
      }

      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error) {
    return {
      content: [{ type: "text", text: `Error: ${error}` }],
      isError: true,
    };
  }
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("File Operations MCP Server running");
}

main().catch(console.error);
```

**Package Configuration**:
```json
{
  "name": "mcp-file-server",
  "version": "1.0.0",
  "type": "module",
  "main": "dist/index.js",
  "scripts": {
    "build": "tsc",
    "start": "node dist/index.js",
    "dev": "tsc && node dist/index.js"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^0.5.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "typescript": "^5.0.0"
  }
}
```

### Best Practices

1. **Validate All Inputs**: TypeScript types ≠ runtime validation
2. **Return Structured Errors**: Use `isError: true` for errors
3. **Handle Node.js Errors**: Check error codes (ENOENT, EACCES, etc.)
4. **Use Async/Await**: All handlers should be async
5. **Log to stderr**: stdout is for MCP protocol messages

## Pattern 3: Function Calling Schema Design

### When to Use
- Integrating with OpenAI or Anthropic function calling
- Need strict parameter validation
- Complex nested parameters
- Reusing tools across different LLM providers

### Implementation

**Simple Schema**:
```json
{
  "name": "get_weather",
  "description": "Get current weather for a location",
  "parameters": {
    "type": "object",
    "properties": {
      "location": {
        "type": "string",
        "description": "City name or zip code"
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

**Complex Schema with Nested Objects**:
```json
{
  "name": "create_calendar_event",
  "description": "Create a calendar event with attendees and reminders",
  "parameters": {
    "type": "object",
    "properties": {
      "title": {
        "type": "string",
        "description": "Event title",
        "minLength": 1,
        "maxLength": 200
      },
      "start_time": {
        "type": "string",
        "format": "date-time",
        "description": "Event start time (ISO 8601)"
      },
      "end_time": {
        "type": "string",
        "format": "date-time",
        "description": "Event end time (ISO 8601)"
      },
      "attendees": {
        "type": "array",
        "description": "List of attendees",
        "items": {
          "type": "object",
          "properties": {
            "email": {
              "type": "string",
              "format": "email"
            },
            "name": {
              "type": "string"
            },
            "optional": {
              "type": "boolean",
              "default": false
            }
          },
          "required": ["email"]
        },
        "maxItems": 50
      },
      "reminders": {
        "type": "array",
        "description": "Event reminders",
        "items": {
          "type": "object",
          "properties": {
            "method": {
              "type": "string",
              "enum": ["email", "sms", "notification"]
            },
            "minutes_before": {
              "type": "integer",
              "minimum": 0,
              "maximum": 10080
            }
          },
          "required": ["method", "minutes_before"]
        }
      }
    },
    "required": ["title", "start_time", "end_time"]
  }
}
```

**Schema with Conditional Logic**:
```json
{
  "name": "query_database",
  "description": "Query database with filters",
  "parameters": {
    "type": "object",
    "properties": {
      "table": {
        "type": "string",
        "description": "Table name"
      },
      "filter_type": {
        "type": "string",
        "enum": ["simple", "advanced"],
        "description": "Type of filter to apply"
      },
      "simple_filter": {
        "type": "object",
        "description": "Simple key-value filters (when filter_type=simple)",
        "additionalProperties": {"type": "string"}
      },
      "advanced_filter": {
        "type": "string",
        "description": "SQL WHERE clause (when filter_type=advanced)"
      }
    },
    "required": ["table", "filter_type"],
    "oneOf": [
      {
        "properties": {"filter_type": {"const": "simple"}},
        "required": ["simple_filter"]
      },
      {
        "properties": {"filter_type": {"const": "advanced"}},
        "required": ["advanced_filter"]
      }
    ]
  }
}
```

### Best Practices

1. **Detailed Descriptions**: Help LLM choose correct parameters
2. **Use Constraints**: minLength, maxLength, minimum, maximum, enum
3. **Provide Defaults**: Reduce cognitive load on LLM
4. **Validate Formats**: email, date-time, uri, etc.
5. **Document Edge Cases**: What happens with empty arrays, null values

## Pattern 4: Tool Composition & Chaining

### When to Use
- Multi-step workflows
- Tools that depend on outputs of other tools
- Conditional execution based on results
- Building complex operations from simple primitives

### Implementation

**Sequential Composition**:
```python
from fastmcp import FastMCP
import json

mcp = FastMCP("Data Pipeline")

@mcp.tool()
def fetch_data(source: str) -> str:
    """Fetch data from source."""
    # Simulated fetch
    data = {"users": [{"id": 1, "name": "Alice"}, {"id": 2, "name": "Bob"}]}
    return json.dumps(data)

@mcp.tool()
def transform_data(data_json: str, operation: str) -> str:
    """Transform JSON data."""
    data = json.loads(data_json)

    if operation == "extract_names":
        names = [user["name"] for user in data["users"]]
        return json.dumps(names)
    elif operation == "count":
        return json.dumps({"count": len(data["users"])})

    return data_json

@mcp.tool()
def save_result(data_json: str, destination: str) -> str:
    """Save data to destination."""
    with open(destination, 'w') as f:
        f.write(data_json)
    return f"Saved to {destination}"

# Usage by agent:
# 1. result = fetch_data("api.example.com")
# 2. transformed = transform_data(result, "extract_names")
# 3. save_result(transformed, "output.json")
```

**Composite Tool**:
```python
@mcp.tool()
def data_pipeline(source: str, operation: str, destination: str) -> str:
    """
    Complete data pipeline: fetch, transform, save.

    Args:
        source: Data source URL
        operation: Transformation to apply
        destination: Output file path

    Returns:
        Summary of pipeline execution
    """
    try:
        # Step 1: Fetch
        data = fetch_data(source)
        if data.startswith("Error"):
            return data

        # Step 2: Transform
        transformed = transform_data(data, operation)
        if transformed.startswith("Error"):
            return transformed

        # Step 3: Save
        result = save_result(transformed, destination)

        return f"Pipeline complete: {source} -> {operation} -> {destination}"

    except Exception as e:
        return f"Pipeline failed: {str(e)}"
```

**Conditional Composition**:
```python
@mcp.tool()
def smart_file_processor(file_path: str) -> str:
    """
    Process file based on type.

    Detects file type and applies appropriate processing.
    """
    import os

    _, ext = os.path.splitext(file_path)

    if ext == ".json":
        # Parse and validate JSON
        content = read_file(file_path)
        try:
            data = json.loads(content)
            return f"Valid JSON with {len(data)} keys"
        except json.JSONDecodeError as e:
            return f"Invalid JSON: {str(e)}"

    elif ext == ".csv":
        # Count rows and columns
        content = read_file(file_path)
        lines = content.split('\n')
        cols = len(lines[0].split(',')) if lines else 0
        return f"CSV with {len(lines)} rows and {cols} columns"

    elif ext == ".txt":
        # Count words
        content = read_file(file_path)
        words = len(content.split())
        return f"Text file with {words} words"

    else:
        return f"Unsupported file type: {ext}"
```

**Parallel Composition**:
```python
from concurrent.futures import ThreadPoolExecutor, as_completed

@mcp.tool()
def process_multiple_files(file_paths: list[str]) -> str:
    """Process multiple files in parallel."""
    results = {}

    with ThreadPoolExecutor(max_workers=5) as executor:
        # Submit all tasks
        future_to_file = {
            executor.submit(smart_file_processor, path): path
            for path in file_paths
        }

        # Collect results
        for future in as_completed(future_to_file):
            file_path = future_to_file[future]
            try:
                result = future.result()
                results[file_path] = result
            except Exception as e:
                results[file_path] = f"Error: {str(e)}"

    return json.dumps(results, indent=2)
```

### Best Practices

1. **Return JSON for Chaining**: Structured data easier to pass between tools
2. **Handle Partial Failures**: Don't let one failure break entire pipeline
3. **Provide Progress Feedback**: For long-running compositions
4. **Document Dependencies**: Make tool order clear
5. **Consider Idempotency**: Allow safe retries

## Pattern 5: Tool Testing & Deployment

### When to Use
- Before deploying any tool to production
- When debugging tool issues
- Validating tool behavior across scenarios
- Ensuring tools meet quality standards

### Implementation

**Unit Testing**:
```python
# test_tools.py
import pytest
import json
from my_mcp_server import read_file, write_file, list_files, transform_data
import tempfile
import os

class TestFileTools:
    def test_write_and_read(self):
        with tempfile.NamedTemporaryFile(delete=False) as tmp:
            tmp_path = tmp.name

        try:
            # Test write
            result = write_file(tmp_path, "test content")
            assert "Wrote to" in result
            assert tmp_path in result

            # Test read
            content = read_file(tmp_path)
            assert content == "test content"
        finally:
            os.remove(tmp_path)

    def test_read_nonexistent_file(self):
        result = read_file("/nonexistent/file.txt")
        assert result.startswith("Error")
        assert "not found" in result.lower()

    def test_read_with_max_lines(self):
        with tempfile.NamedTemporaryFile(mode='w', delete=False) as tmp:
            tmp.write("line1\nline2\nline3\n")
            tmp_path = tmp.name

        try:
            content = read_file(tmp_path, max_lines=2)
            assert content == "line1\nline2\n"
        finally:
            os.remove(tmp_path)

class TestTransformTools:
    def test_transform_extract_names(self):
        data = {"users": [{"name": "Alice"}, {"name": "Bob"}]}
        result = transform_data(json.dumps(data), "extract_names")
        names = json.loads(result)
        assert names == ["Alice", "Bob"]

    def test_transform_count(self):
        data = {"users": [{"name": "Alice"}, {"name": "Bob"}]}
        result = transform_data(json.dumps(data), "count")
        count_data = json.loads(result)
        assert count_data["count"] == 2

    def test_transform_invalid_json(self):
        result = transform_data("invalid json", "count")
        assert result.startswith("Error")
```

**Integration Testing**:
```python
# test_integration.py
import subprocess
import json
import pytest

def call_mcp_tool(tool_name: str, arguments: dict) -> dict:
    """Call MCP tool via subprocess."""
    request = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {
            "name": tool_name,
            "arguments": arguments
        }
    }

    proc = subprocess.run(
        ["python", "mcp_server.py"],
        input=json.dumps(request),
        capture_output=True,
        text=True
    )

    return json.loads(proc.stdout)

class TestMCPIntegration:
    def test_call_read_file_tool(self):
        # Create test file
        test_path = "/tmp/test_integration.txt"
        with open(test_path, 'w') as f:
            f.write("integration test")

        # Call tool via MCP
        response = call_mcp_tool("read_file", {"file_path": test_path})

        assert response["result"]["content"][0]["text"] == "integration test"

    def test_call_nonexistent_tool(self):
        with pytest.raises(Exception):
            call_mcp_tool("nonexistent_tool", {})
```

**Contract Testing**:
```python
# test_contracts.py
from my_mcp_server import TOOLS
import jsonschema

class TestToolContracts:
    def test_all_tools_have_required_fields(self):
        """Verify all tools have name, description, inputSchema."""
        for tool in TOOLS:
            assert "name" in tool
            assert "description" in tool
            assert "inputSchema" in tool
            assert tool["name"]  # Non-empty
            assert tool["description"]  # Non-empty

    def test_schemas_are_valid(self):
        """Verify all inputSchemas are valid JSON Schema."""
        for tool in TOOLS:
            schema = tool["inputSchema"]
            # Should not raise exception
            jsonschema.Draft7Validator.check_schema(schema)

    def test_required_parameters_in_properties(self):
        """Verify required parameters exist in properties."""
        for tool in TOOLS:
            schema = tool["inputSchema"]
            if "required" in schema:
                for req in schema["required"]:
                    assert req in schema["properties"], \
                        f"Required param '{req}' not in properties for {tool['name']}"
```

**Deployment Checklist**:
```python
# deployment_checklist.py
def validate_tool_deployment(tool_module):
    """Run deployment validation checks."""
    checks = []

    # Check 1: All tools have tests
    tools = getattr(tool_module, 'TOOLS', [])
    test_file = f"test_{tool_module.__name__}.py"
    checks.append({
        "check": "Tests exist",
        "passed": os.path.exists(test_file),
        "message": f"Test file {test_file} must exist"
    })

    # Check 2: No hardcoded credentials
    with open(tool_module.__file__) as f:
        content = f.read()
        has_secrets = any(x in content.lower() for x in ['password=', 'api_key=', 'secret='])
        checks.append({
            "check": "No hardcoded secrets",
            "passed": not has_secrets,
            "message": "Hardcoded credentials detected"
        })

    # Check 3: Error handling present
    has_try_except = 'try:' in content and 'except' in content
    checks.append({
        "check": "Error handling",
        "passed": has_try_except,
        "message": "Tools must have try/except blocks"
    })

    # Print results
    for check in checks:
        status = "✓" if check["passed"] else "✗"
        print(f"{status} {check['check']}: {check['message']}")

    return all(c["passed"] for c in checks)
```

### Best Practices

1. **Test Edge Cases**: Empty inputs, nulls, max values
2. **Mock External Dependencies**: Don't call real APIs in tests
3. **Verify Error Handling**: Test failure modes explicitly
4. **Check Schema Validity**: Ensure JSON schemas are valid
5. **Deployment Checklist**: Automated checks before production
6. **Monitor in Production**: Log tool calls, track error rates

## Summary

These 5 patterns cover the complete lifecycle of tool development:

1. **Pattern 1 (FastMCP)**: Quick Python tool development
2. **Pattern 2 (TypeScript SDK)**: Production-grade tools
3. **Pattern 3 (Schema Design)**: Strict parameter validation
4. **Pattern 4 (Composition)**: Complex workflows from primitives
5. **Pattern 5 (Testing)**: Quality assurance and deployment

Use these patterns as templates, adapt to your specific requirements, and always prioritize security and error handling.
