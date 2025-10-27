# Examples: AI Agent Tool Builder

Working code examples demonstrating MCP server creation, function calling, and tool composition.

## Example 1: Complete FastMCP Server (File Operations)

### Use Case
Create a safe file operations MCP server that agents can use to read, write, and list files within a restricted directory.

### Complete Implementation

```python
# file_operations_server.py
from fastmcp import FastMCP
from typing import Optional
import os
import json
import glob

# Create MCP server
mcp = FastMCP("File Operations")

# Restrict operations to safe directory
SAFE_BASE_DIR = os.path.expanduser("~/agent_workspace")
os.makedirs(SAFE_BASE_DIR, exist_ok=True)

def validate_path(file_path: str) -> tuple[bool, str, str]:
    """
    Validate path is within safe directory.

    Returns: (is_valid, absolute_path, error_message)
    """
    try:
        # Resolve real paths to prevent symlink-based traversal attacks
        safe_dir_real = os.path.realpath(SAFE_BASE_DIR)
        file_path_real = os.path.realpath(os.path.join(safe_dir_real, file_path))

        # Check if within safe directory
        if not file_path_real.startswith(safe_dir_real + os.sep):
            return False, "", f"Error: Path must be within {SAFE_BASE_DIR}"

        return True, file_path_real, ""
    except Exception as e:
        return False, "", f"Error: Invalid path: {str(e)}"

@mcp.tool()
def read_file(file_path: str, max_bytes: Optional[int] = None) -> str:
    """
    Read file contents from agent workspace.

    Args:
        file_path: Relative path within workspace
        max_bytes: Maximum bytes to read (optional)

    Returns:
        File contents or error message
    """
    is_valid, abs_path, error = validate_path(file_path)
    if not is_valid:
        return error

    try:
        if not os.path.isfile(abs_path):
            return f"Error: File not found: {file_path}"

        with open(abs_path, 'r', encoding='utf-8') as f:
            if max_bytes:
                content = f.read(max_bytes)
            else:
                content = f.read()

        return content

    except PermissionError:
        return f"Error: Permission denied: {file_path}"
    except UnicodeDecodeError:
        return f"Error: File is not text (binary file?): {file_path}"
    except Exception as e:
        return f"Error reading file: {str(e)}"

@mcp.tool()
def write_file(file_path: str, content: str, append: bool = False) -> str:
    """
    Write content to file in agent workspace.

    Args:
        file_path: Relative path within workspace
        content: Content to write
        append: Append to file instead of overwriting (default: False)

    Returns:
        Success message or error
    """
    is_valid, abs_path, error = validate_path(file_path)
    if not is_valid:
        return error

    try:
        # Create parent directories if needed
        os.makedirs(os.path.dirname(abs_path), exist_ok=True)

        mode = 'a' if append else 'w'
        with open(abs_path, mode, encoding='utf-8') as f:
            f.write(content)

        action = "Appended to" if append else "Wrote to"
        size = os.path.getsize(abs_path)
        return f"{action} {file_path} ({size} bytes)"

    except Exception as e:
        return f"Error writing file: {str(e)}"

@mcp.tool()
def list_files(directory: str = ".", pattern: Optional[str] = None, recursive: bool = False) -> str:
    """
    List files in workspace directory.

    Args:
        directory: Relative directory path (default: current)
        pattern: Glob pattern to filter files (e.g., "*.txt")
        recursive: Search recursively (default: False)

    Returns:
        JSON array of file information
    """
    is_valid, abs_dir, error = validate_path(directory)
    if not is_valid:
        return error

    try:
        if not os.path.isdir(abs_dir):
            return f"Error: Directory not found: {directory}"

        # Build glob pattern
        if recursive:
            search_pattern = os.path.join(abs_dir, "**", pattern or "*")
        else:
            search_pattern = os.path.join(abs_dir, pattern or "*")

        # Find files
        files = glob.glob(search_pattern, recursive=recursive)

        # Convert to relative paths and get metadata
        file_info = []
        for f in files:
            if os.path.isfile(f):
                rel_path = os.path.relpath(f, SAFE_BASE_DIR)
                stat = os.stat(f)
                file_info.append({
                    "path": rel_path,
                    "size": stat.st_size,
                    "modified": stat.st_mtime
                })

        return json.dumps(file_info, indent=2)

    except Exception as e:
        return f"Error listing files: {str(e)}"

@mcp.tool()
def delete_file(file_path: str, confirm: bool = False) -> str:
    """
    Delete file from workspace (requires confirmation).

    Args:
        file_path: Relative path to file to delete
        confirm: Must be True to proceed with deletion

    Returns:
        Success message or error
    """
    if not confirm:
        return "Error: Must set confirm=True to delete file"

    is_valid, abs_path, error = validate_path(file_path)
    if not is_valid:
        return error

    try:
        if not os.path.isfile(abs_path):
            return f"Error: File not found: {file_path}"

        os.remove(abs_path)
        return f"Deleted {file_path}"

    except Exception as e:
        return f"Error deleting file: {str(e)}"

@mcp.tool()
def file_info(file_path: str) -> str:
    """
    Get detailed information about a file.

    Args:
        file_path: Relative path to file

    Returns:
        JSON with file metadata
    """
    is_valid, abs_path, error = validate_path(file_path)
    if not is_valid:
        return error

    try:
        if not os.path.exists(abs_path):
            return f"Error: Path not found: {file_path}"

        stat = os.stat(abs_path)
        info = {
            "path": file_path,
            "exists": True,
            "is_file": os.path.isfile(abs_path),
            "is_directory": os.path.isdir(abs_path),
            "size": stat.st_size,
            "created": stat.st_ctime,
            "modified": stat.st_mtime,
            "accessed": stat.st_atime
        }

        return json.dumps(info, indent=2)

    except Exception as e:
        return f"Error getting file info: {str(e)}"

if __name__ == "__main__":
    print(f"File Operations Server - Workspace: {SAFE_BASE_DIR}")
    mcp.run()
```

### Running the Server

```bash
# Install FastMCP
pip install fastmcp

# Run server
python file_operations_server.py
```

### Testing with MCP Client

```python
# test_client.py
from fastmcp.client import Client

async def test_file_operations():
    async with Client("python", "file_operations_server.py") as client:
        # Write a file
        result = await client.call_tool("write_file", {
            "file_path": "test.txt",
            "content": "Hello, World!"
        })
        print(result)

        # Read it back
        result = await client.call_tool("read_file", {
            "file_path": "test.txt"
        })
        print(result)

        # List files
        result = await client.call_tool("list_files", {
            "pattern": "*.txt"
        })
        print(result)

import asyncio
asyncio.run(test_file_operations())
```

## Example 2: TypeScript MCP Server (GitHub API Wrapper)

### Use Case
Wrap GitHub API in MCP server so agents can interact with repositories.

### Complete Implementation

```typescript
// github_mcp_server.ts
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { CallToolRequestSchema, ListToolsRequestSchema } from "@modelcontextprotocol/sdk/types.js";

interface GitHubConfig {
  token: string;
  baseUrl: string;
}

const config: GitHubConfig = {
  token: process.env.GITHUB_TOKEN || "",
  baseUrl: "https://api.github.com",
};

const server = new Server(
  {
    name: "github-tools",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Helper function for GitHub API calls
async function githubRequest(
  endpoint: string,
  method: string = "GET",
  body?: any
): Promise<any> {
  const url = `${config.baseUrl}${endpoint}`;
  const headers: Record<string, string> = {
    Accept: "application/vnd.github+json",
    "X-GitHub-Api-Version": "2022-11-28",
  };

  if (config.token) {
    headers.Authorization = `Bearer ${config.token}`;
  }

  const options: RequestInit = {
    method,
    headers,
  };

  if (body) {
    options.body = JSON.stringify(body);
  }

  const response = await fetch(url, options);

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`GitHub API error: ${response.status} - ${error}`);
  }

  return response.json();
}

// Define tools
const TOOLS = [
  {
    name: "get_repository",
    description: "Get information about a GitHub repository",
    inputSchema: {
      type: "object",
      properties: {
        owner: {
          type: "string",
          description: "Repository owner (username or organization)",
        },
        repo: {
          type: "string",
          description: "Repository name",
        },
      },
      required: ["owner", "repo"],
    },
  },
  {
    name: "list_pull_requests",
    description: "List pull requests for a repository",
    inputSchema: {
      type: "object",
      properties: {
        owner: {
          type: "string",
          description: "Repository owner",
        },
        repo: {
          type: "string",
          description: "Repository name",
        },
        state: {
          type: "string",
          enum: ["open", "closed", "all"],
          description: "Filter by PR state",
        },
      },
      required: ["owner", "repo"],
    },
  },
  {
    name: "create_issue",
    description: "Create an issue in a repository",
    inputSchema: {
      type: "object",
      properties: {
        owner: {
          type: "string",
          description: "Repository owner",
        },
        repo: {
          type: "string",
          description: "Repository name",
        },
        title: {
          type: "string",
          description: "Issue title",
        },
        body: {
          type: "string",
          description: "Issue description (markdown)",
        },
        labels: {
          type: "array",
          items: { type: "string" },
          description: "Issue labels",
        },
      },
      required: ["owner", "repo", "title"],
    },
  },
  {
    name: "search_code",
    description: "Search for code in GitHub repositories",
    inputSchema: {
      type: "object",
      properties: {
        query: {
          type: "string",
          description: "Search query (use repo:owner/name to limit scope)",
        },
        max_results: {
          type: "number",
          description: "Maximum number of results (default: 10)",
          minimum: 1,
          maximum: 100,
        },
      },
      required: ["query"],
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
      case "get_repository": {
        const { owner, repo } = args as { owner: string; repo: string };
        const data = await githubRequest(`/repos/${owner}/${repo}`);

        const summary = {
          name: data.name,
          full_name: data.full_name,
          description: data.description,
          stars: data.stargazers_count,
          forks: data.forks_count,
          open_issues: data.open_issues_count,
          language: data.language,
          url: data.html_url,
        };

        return {
          content: [{ type: "text", text: JSON.stringify(summary, null, 2) }],
        };
      }

      case "list_pull_requests": {
        const { owner, repo, state = "open" } = args as {
          owner: string;
          repo: string;
          state?: string;
        };

        const data = await githubRequest(
          `/repos/${owner}/${repo}/pulls?state=${state}`
        );

        const prs = data.map((pr: any) => ({
          number: pr.number,
          title: pr.title,
          state: pr.state,
          author: pr.user.login,
          created_at: pr.created_at,
          url: pr.html_url,
        }));

        return {
          content: [{ type: "text", text: JSON.stringify(prs, null, 2) }],
        };
      }

      case "create_issue": {
        const { owner, repo, title, body = "", labels = [] } = args as {
          owner: string;
          repo: string;
          title: string;
          body?: string;
          labels?: string[];
        };

        const data = await githubRequest(
          `/repos/${owner}/${repo}/issues`,
          "POST",
          { title, body, labels }
        );

        return {
          content: [
            {
              type: "text",
              text: `Created issue #${data.number}: ${data.html_url}`,
            },
          ],
        };
      }

      case "search_code": {
        const { query, max_results = 10 } = args as {
          query: string;
          max_results?: number;
        };

        const data = await githubRequest(
          `/search/code?q=${encodeURIComponent(query)}&per_page=${max_results}`
        );

        const results = data.items.map((item: any) => ({
          path: item.path,
          repository: item.repository.full_name,
          url: item.html_url,
        }));

        return {
          content: [{ type: "text", text: JSON.stringify(results, null, 2) }],
        };
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
  if (!config.token) {
    console.error("Warning: GITHUB_TOKEN not set. API rate limits will apply.");
  }

  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("GitHub MCP Server running");
}

main().catch(console.error);
```

### Package Setup

```json
{
  "name": "github-mcp-server",
  "version": "1.0.0",
  "type": "module",
  "main": "dist/index.js",
  "scripts": {
    "build": "tsc",
    "start": "node dist/index.js"
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

## Example 3: Complex Function Calling Schema

### Use Case
Create a schema for a database query tool with complex filtering options.

```json
{
  "name": "query_database",
  "description": "Query database with flexible filters and pagination",
  "parameters": {
    "type": "object",
    "properties": {
      "database": {
        "type": "string",
        "description": "Database name",
        "enum": ["users", "products", "orders", "analytics"]
      },
      "operation": {
        "type": "string",
        "description": "Query operation type",
        "enum": ["select", "count", "aggregate"]
      },
      "filters": {
        "type": "array",
        "description": "Query filters (AND logic)",
        "items": {
          "type": "object",
          "properties": {
            "field": {
              "type": "string",
              "description": "Field name to filter on"
            },
            "operator": {
              "type": "string",
              "enum": ["eq", "ne", "gt", "lt", "gte", "lte", "in", "like"],
              "description": "Comparison operator"
            },
            "value": {
              "description": "Value to compare against (type varies)"
            }
          },
          "required": ["field", "operator", "value"]
        }
      },
      "sort": {
        "type": "object",
        "description": "Sort order",
        "properties": {
          "field": {
            "type": "string",
            "description": "Field to sort by"
          },
          "direction": {
            "type": "string",
            "enum": ["asc", "desc"],
            "default": "asc"
          }
        },
        "required": ["field"]
      },
      "pagination": {
        "type": "object",
        "description": "Pagination settings",
        "properties": {
          "page": {
            "type": "integer",
            "minimum": 1,
            "default": 1,
            "description": "Page number (1-indexed)"
          },
          "page_size": {
            "type": "integer",
            "minimum": 1,
            "maximum": 100,
            "default": 20,
            "description": "Results per page"
          }
        }
      },
      "fields": {
        "type": "array",
        "items": { "type": "string" },
        "description": "Fields to return (empty = all fields)"
      }
    },
    "required": ["database", "operation"]
  }
}
```

## Example 4: Tool Composition Workflow

### Use Case
Build a code analysis pipeline that combines multiple tools.

```python
from fastmcp import FastMCP
import json
import subprocess

mcp = FastMCP("Code Analysis Pipeline")

@mcp.tool()
def get_file_list(directory: str, extension: str = ".py") -> str:
    """Get list of files with extension."""
    import glob
    import os

    pattern = os.path.join(directory, f"**/*{extension}")
    files = glob.glob(pattern, recursive=True)
    return json.dumps(files)

@mcp.tool()
def analyze_complexity(file_path: str) -> str:
    """Analyze code complexity using radon."""
    try:
        result = subprocess.run(
            ["radon", "cc", file_path, "-j"],
            capture_output=True,
            text=True
        )
        return result.stdout
    except Exception as e:
        return json.dumps({"error": str(e)})

@mcp.tool()
def check_style(file_path: str) -> str:
    """Check code style using flake8."""
    try:
        result = subprocess.run(
            ["flake8", file_path, "--format=json"],
            capture_output=True,
            text=True
        )
        return result.stdout
    except Exception as e:
        return json.dumps({"error": str(e)})

@mcp.tool()
def aggregate_results(complexity_json: str, style_json: str) -> str:
    """Aggregate analysis results."""
    complexity = json.loads(complexity_json)
    style = json.loads(style_json)

    summary = {
        "complexity": {
            "average": sum(f["complexity"] for f in complexity) / len(complexity) if complexity else 0,
            "max": max((f["complexity"] for f in complexity), default=0)
        },
        "style_issues": len(style),
        "critical_issues": [s for s in style if s.get("severity") == "error"]
    }

    return json.dumps(summary, indent=2)

@mcp.tool()
def analyze_project(directory: str) -> str:
    """
    Complete project analysis pipeline.

    Combines file discovery, complexity analysis, style checking,
    and result aggregation.
    """
    results = {"files": [], "summary": {}}

    # Step 1: Get file list
    files_json = get_file_list(directory, ".py")
    files = json.loads(files_json)
    results["files"] = files

    if not files:
        return json.dumps({"error": "No Python files found"})

    # Step 2: Analyze each file
    all_complexity = []
    all_style_issues = []

    for file_path in files[:10]:  # Limit to 10 files for demo
        complexity = analyze_complexity(file_path)
        style = check_style(file_path)

        try:
            all_complexity.extend(json.loads(complexity).get(file_path, []))
            all_style_issues.extend(json.loads(style))
        except:
            pass

    # Step 3: Aggregate results
    summary = aggregate_results(
        json.dumps(all_complexity),
        json.dumps(all_style_issues)
    )

    results["summary"] = json.loads(summary)
    return json.dumps(results, indent=2)

if __name__ == "__main__":
    mcp.run()
```

## Example 5: End-to-End Tool Creation Workflow

### Scenario
Create a weather tool from scratch, following best practices.

### Step 1: Design Schema

```json
{
  "name": "get_weather",
  "description": "Get current weather for a location",
  "parameters": {
    "type": "object",
    "properties": {
      "location": {
        "type": "string",
        "description": "City name (e.g., 'London'), coordinates (e.g., '51.5,-0.1'), or zip code"
      },
      "units": {
        "type": "string",
        "enum": ["celsius", "fahrenheit", "kelvin"],
        "default": "celsius",
        "description": "Temperature units"
      },
      "include_forecast": {
        "type": "boolean",
        "default": false,
        "description": "Include 3-day forecast"
      }
    },
    "required": ["location"]
  }
}
```

### Step 2: Implement Tool

```python
from fastmcp import FastMCP
import json
import os
from typing import Optional

mcp = FastMCP("Weather Service")

def geocode_location(location: str) -> Optional[tuple[float, float]]:
    """Convert location string to coordinates."""
    # In production, use geocoding API
    # For demo, simple mapping
    cities = {
        "london": (51.5074, -0.1278),
        "paris": (48.8566, 2.3522),
        "new york": (40.7128, -74.0060)
    }
    return cities.get(location.lower())

def fetch_weather(lat: float, lon: float, units: str) -> dict:
    """Fetch weather from API."""
    # In production, call real weather API
    # For demo, mock data
    return {
        "temperature": 20 if units == "celsius" else 68,
        "condition": "partly cloudy",
        "humidity": 65,
        "wind_speed": 15
    }

@mcp.tool()
def get_weather(
    location: str,
    units: str = "celsius",
    include_forecast: bool = False
) -> str:
    """
    Get current weather for a location.

    Args:
        location: City name, coordinates, or zip code
        units: Temperature units (celsius/fahrenheit/kelvin)
        include_forecast: Include 3-day forecast

    Returns:
        JSON with weather information
    """
    # Validate units
    valid_units = ["celsius", "fahrenheit", "kelvin"]
    if units not in valid_units:
        return json.dumps({
            "error": f"Invalid units. Must be one of: {valid_units}"
        })

    # Geocode location
    coords = geocode_location(location)
    if not coords:
        return json.dumps({
            "error": f"Location not found: {location}"
        })

    lat, lon = coords

    # Fetch weather
    try:
        weather = fetch_weather(lat, lon, units)
        result = {
            "location": location,
            "coordinates": {"lat": lat, "lon": lon},
            "current": weather
        }

        if include_forecast:
            # In production, fetch real forecast
            result["forecast"] = [
                {"day": "tomorrow", "temp_high": 22, "temp_low": 15},
                {"day": "day_2", "temp_high": 24, "temp_low": 16},
                {"day": "day_3", "temp_high": 21, "temp_low": 14}
            ]

        return json.dumps(result, indent=2)

    except Exception as e:
        return json.dumps({"error": f"Failed to fetch weather: {str(e)}"})

if __name__ == "__main__":
    mcp.run()
```

### Step 3: Write Tests

```python
# test_weather_tool.py
import pytest
import json
from weather_server import get_weather, geocode_location

def test_geocode_known_city():
    coords = geocode_location("London")
    assert coords is not None
    assert coords[0] == pytest.approx(51.5074, abs=0.1)

def test_geocode_unknown_city():
    coords = geocode_location("Atlantis")
    assert coords is None

def test_get_weather_success():
    result = get_weather("London", "celsius", False)
    data = json.loads(result)

    assert "error" not in data
    assert data["location"] == "London"
    assert "current" in data
    assert "temperature" in data["current"]

def test_get_weather_with_forecast():
    result = get_weather("Paris", "celsius", True)
    data = json.loads(result)

    assert "forecast" in data
    assert len(data["forecast"]) == 3

def test_get_weather_invalid_units():
    result = get_weather("London", "invalid", False)
    data = json.loads(result)

    assert "error" in data
    assert "Invalid units" in data["error"]

def test_get_weather_unknown_location():
    result = get_weather("Atlantis", "celsius", False)
    data = json.loads(result)

    assert "error" in data
    assert "not found" in data["error"].lower()
```

### Step 4: Deploy

```bash
# Install dependencies
pip install fastmcp

# Run tests
pytest test_weather_tool.py

# Start server
python weather_server.py
```

## Real-World Use Cases

### Use Case 1: Database Query Tool
Agent needs to query production database safely:
- Tool validates queries (prevent DROP/DELETE)
- Enforces read-only access
- Adds automatic query timeouts
- Logs all queries for audit

### Use Case 2: Code Execution Sandbox
Agent needs to run user code:
- Tool uses Docker container for isolation
- Resource limits (CPU, memory, time)
- Network access disabled
- Captures stdout/stderr safely

### Use Case 3: Multi-API Aggregator
Agent needs data from multiple sources:
- Tool fetches from 3+ APIs in parallel
- Normalizes response formats
- Handles rate limiting
- Caches results for 5 minutes

## Summary

These examples demonstrate:
1. **Production-ready code** with error handling
2. **Security best practices** (path validation, sandboxing)
3. **Composability** (tools that work together)
4. **Testing strategies** (unit and integration tests)
5. **Real-world patterns** (API wrappers, data pipelines)

Use these as templates for your own tools. Always prioritize safety, validation, and clear error messages.
