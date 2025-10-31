# MCP Integration Examples

## Complete Working Examples

### Example 1: Weather API Server

Complete MCP server for weather data:

```python
# weather_server.py
from fastmcp import FastMCP
import httpx
import os
from typing import Optional
from datetime import datetime, timedelta

mcp = FastMCP("weather-server")

# Configuration
API_KEY = os.getenv("WEATHER_API_KEY")
if not API_KEY:
    raise ValueError("WEATHER_API_KEY environment variable required")

BASE_URL = "https://api.openweathermap.org/data/2.5"

# Simple cache
cache = {}
CACHE_TTL = 300  # 5 minutes

class WeatherCache:
    def __init__(self, ttl: int = 300):
        self.ttl = ttl
        self.cache = {}

    def get(self, key: str) -> Optional[dict]:
        if key in self.cache:
            data, timestamp = self.cache[key]
            if datetime.now() - timestamp < timedelta(seconds=self.ttl):
                return data
            else:
                del self.cache[key]
        return None

    def set(self, key: str, data: dict):
        self.cache[key] = (data, datetime.now())

weather_cache = WeatherCache()

@mcp.tool()
async def get_current_weather(city: str, units: str = "metric") -> dict:
    """
    Get current weather for a city

    Args:
        city: City name (e.g., "London", "New York")
        units: Temperature units - "metric" (Celsius) or "imperial" (Fahrenheit)
    """
    # Check cache
    cache_key = f"{city}:{units}"
    cached = weather_cache.get(cache_key)
    if cached:
        return cached

    # Make API call
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{BASE_URL}/weather",
            params={
                "q": city,
                "appid": API_KEY,
                "units": units
            }
        )

        if response.status_code == 404:
            return {"error": f"City '{city}' not found"}

        response.raise_for_status()
        data = response.json()

        # Format response
        result = {
            "city": data["name"],
            "country": data["sys"]["country"],
            "temperature": data["main"]["temp"],
            "feels_like": data["main"]["feels_like"],
            "description": data["weather"][0]["description"],
            "humidity": data["main"]["humidity"],
            "wind_speed": data["wind"]["speed"],
            "units": units
        }

        # Cache result
        weather_cache.set(cache_key, result)
        return result

@mcp.tool()
async def get_forecast(city: str, days: int = 5, units: str = "metric") -> dict:
    """
    Get weather forecast for a city

    Args:
        city: City name
        days: Number of forecast days (1-5)
        units: Temperature units
    """
    if days < 1 or days > 5:
        return {"error": "Days must be between 1 and 5"}

    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{BASE_URL}/forecast",
            params={
                "q": city,
                "appid": API_KEY,
                "units": units,
                "cnt": days * 8  # 8 forecasts per day (3-hour intervals)
            }
        )

        if response.status_code == 404:
            return {"error": f"City '{city}' not found"}

        response.raise_for_status()
        data = response.json()

        # Group forecasts by day
        daily_forecasts = []
        current_date = None
        day_data = []

        for item in data["list"]:
            date = datetime.fromtimestamp(item["dt"]).date()

            if current_date and date != current_date:
                # Process previous day's data
                daily_forecasts.append({
                    "date": str(current_date),
                    "temp_min": min(d["main"]["temp_min"] for d in day_data),
                    "temp_max": max(d["main"]["temp_max"] for d in day_data),
                    "description": day_data[len(day_data)//2]["weather"][0]["description"]
                })
                day_data = []

            current_date = date
            day_data.append(item)

        # Add last day
        if day_data:
            daily_forecasts.append({
                "date": str(current_date),
                "temp_min": min(d["main"]["temp_min"] for d in day_data),
                "temp_max": max(d["main"]["temp_max"] for d in day_data),
                "description": day_data[len(day_data)//2]["weather"][0]["description"]
            })

        return {
            "city": data["city"]["name"],
            "country": data["city"]["country"],
            "forecast": daily_forecasts[:days],
            "units": units
        }

@mcp.resource("weather://current/{city}")
def current_weather_resource(city: str) -> str:
    """Get current weather as a resource"""
    import asyncio
    import json

    # Run async function in sync context
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    try:
        result = loop.run_until_complete(get_current_weather(city))
        return json.dumps(result)
    finally:
        loop.close()

if __name__ == "__main__":
    mcp.run()
```

**Configuration** (`~/.config/claude-code/mcp.json`):
```json
{
  "mcpServers": {
    "weather": {
      "command": "python",
      "args": ["/path/to/weather_server.py"],
      "env": {
        "WEATHER_API_KEY": "your-api-key-here"
      }
    }
  }
}
```

### Example 2: Database Query Server

MCP server for database operations:

```python
# database_server.py
from fastmcp import FastMCP
import sqlite3
import json
from typing import List, Dict, Optional, Any
from contextlib import contextmanager
import os

mcp = FastMCP("database-server")

# Database configuration
DB_PATH = os.getenv("DATABASE_PATH", "app.db")

@contextmanager
def get_db():
    """Database connection context manager"""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
    finally:
        conn.close()

def init_database():
    """Initialize database with sample schema"""
    with get_db() as conn:
        conn.executescript("""
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT UNIQUE NOT NULL,
                email TEXT UNIQUE NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS posts (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                title TEXT NOT NULL,
                content TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users (id)
            );

            CREATE INDEX IF NOT EXISTS idx_posts_user_id ON posts(user_id);
        """)
        conn.commit()

# Initialize on startup
init_database()

@mcp.tool()
def query_table(table_name: str, columns: Optional[List[str]] = None,
                where_clause: Optional[str] = None,
                limit: int = 100) -> Dict[str, Any]:
    """
    Query a database table safely using parameterized queries

    Args:
        table_name: Name of the table to query (whitelist enforced)
        columns: List of columns to select (default: all)
        where_clause: Optional WHERE condition (without WHERE keyword)
        limit: Maximum number of rows to return
    """
    # Whitelist of allowed tables to prevent SQL injection
    ALLOWED_TABLES = {"users", "posts", "comments", "tasks"}

    if table_name not in ALLOWED_TABLES:
        return {"error": f"Table '{table_name}' not allowed. Allowed tables: {', '.join(ALLOWED_TABLES)}"}

    # Validate limit
    if not 1 <= limit <= 1000:
        return {"error": "Limit must be between 1 and 1000"}

    try:
        # Build query safely
        cols = ", ".join(columns) if columns else "*"

        # Use parameterized queries to prevent SQL injection
        # Note: Table names can't be parameterized, so we use whitelisting instead
        if where_clause:
            # WARNING: where_clause should also be validated or use a query builder
            # For production, use an ORM or SQL parser library
            query = f"SELECT {cols} FROM {table_name} WHERE {where_clause} LIMIT ?"
            params = [limit]
        else:
            query = f"SELECT {cols} FROM {table_name} LIMIT ?"
            params = [limit]

        with get_db() as conn:
            cursor = conn.execute(query, params)
            columns_desc = [description[0] for description in cursor.description]
            rows = cursor.fetchall()

            return {
                "columns": columns_desc,
                "rows": [dict(row) for row in rows],
                "count": len(rows)
            }
    except sqlite3.Error as e:
        return {"error": f"Database error: {str(e)}"}

@mcp.tool()
def create_user(username: str, email: str) -> Dict[str, Any]:
    """
    Create a new user

    Args:
        username: Unique username
        email: User's email address
    """
    try:
        with get_db() as conn:
            cursor = conn.execute(
                "INSERT INTO users (username, email) VALUES (?, ?)",
                (username, email)
            )
            conn.commit()

            return {
                "success": True,
                "user_id": cursor.lastrowid,
                "message": f"User '{username}' created successfully"
            }
    except sqlite3.IntegrityError as e:
        return {"error": "Username or email already exists"}
    except sqlite3.Error as e:
        return {"error": f"Database error: {str(e)}"}

@mcp.tool()
def create_post(user_id: int, title: str, content: str = "") -> Dict[str, Any]:
    """
    Create a new post

    Args:
        user_id: ID of the user creating the post
        title: Post title
        content: Post content (optional)
    """
    try:
        with get_db() as conn:
            # Verify user exists
            user = conn.execute("SELECT id FROM users WHERE id = ?", (user_id,)).fetchone()
            if not user:
                return {"error": f"User with ID {user_id} not found"}

            cursor = conn.execute(
                "INSERT INTO posts (user_id, title, content) VALUES (?, ?, ?)",
                (user_id, title, content)
            )
            conn.commit()

            return {
                "success": True,
                "post_id": cursor.lastrowid,
                "message": f"Post '{title}' created successfully"
            }
    except sqlite3.Error as e:
        return {"error": f"Database error: {str(e)}"}

@mcp.tool()
def get_user_posts(username: str, limit: int = 10) -> Dict[str, Any]:
    """
    Get all posts by a specific user

    Args:
        username: Username to get posts for
        limit: Maximum number of posts to return
    """
    query = """
        SELECT p.id, p.title, p.content, p.created_at, u.username
        FROM posts p
        JOIN users u ON p.user_id = u.id
        WHERE u.username = ?
        ORDER BY p.created_at DESC
        LIMIT ?
    """

    try:
        with get_db() as conn:
            cursor = conn.execute(query, (username, limit))
            posts = [dict(row) for row in cursor.fetchall()]

            return {
                "username": username,
                "posts": posts,
                "count": len(posts)
            }
    except sqlite3.Error as e:
        return {"error": f"Database error: {str(e)}"}

@mcp.resource("db://users")
def list_users_resource() -> str:
    """List all users as a resource"""
    with get_db() as conn:
        cursor = conn.execute("SELECT * FROM users ORDER BY created_at DESC")
        users = [dict(row) for row in cursor.fetchall()]
        return json.dumps(users)

@mcp.resource("db://user/{username}")
def get_user_resource(username: str) -> Optional[str]:
    """Get specific user as a resource"""
    with get_db() as conn:
        cursor = conn.execute("SELECT * FROM users WHERE username = ?", (username,))
        user = cursor.fetchone()
        return json.dumps(dict(user)) if user else None

@mcp.tool()
def get_database_stats() -> Dict[str, Any]:
    """Get database statistics"""
    with get_db() as conn:
        stats = {}

        # Count tables
        cursor = conn.execute("SELECT COUNT(*) FROM sqlite_master WHERE type='table'")
        stats["table_count"] = cursor.fetchone()[0]

        # Count users
        cursor = conn.execute("SELECT COUNT(*) FROM users")
        stats["user_count"] = cursor.fetchone()[0]

        # Count posts
        cursor = conn.execute("SELECT COUNT(*) FROM posts")
        stats["post_count"] = cursor.fetchone()[0]

        # Database size
        cursor = conn.execute("SELECT page_count * page_size as size FROM pragma_page_count(), pragma_page_size()")
        stats["database_size_bytes"] = cursor.fetchone()[0]

        return stats

if __name__ == "__main__":
    mcp.run()
```

### Example 3: File System Browser

Safe file system access via MCP:

```python
# filesystem_server.py
from fastmcp import FastMCP
from pathlib import Path
import json
import os
import mimetypes
from typing import List, Dict, Optional
from datetime import datetime

mcp = FastMCP("filesystem-server")

# Configure allowed paths (sandbox)
ALLOWED_PATHS = [
    Path(os.path.expanduser("~/Documents")),
    Path(os.path.expanduser("~/Downloads")),
]

def is_safe_path(path: str) -> bool:
    """Check if path is within allowed directories"""
    try:
        p = Path(path).expanduser().resolve()
        return any(
            p == allowed or p.is_relative_to(allowed)
            for allowed in ALLOWED_PATHS
        )
    except Exception:
        return False

def path_info(path: Path) -> Dict:
    """Get information about a path"""
    stat = path.stat()
    mime_type, _ = mimetypes.guess_type(str(path))

    return {
        "name": path.name,
        "path": str(path),
        "type": "directory" if path.is_dir() else "file",
        "size": stat.st_size if path.is_file() else None,
        "mime_type": mime_type,
        "modified": datetime.fromtimestamp(stat.st_mtime).isoformat(),
        "created": datetime.fromtimestamp(stat.st_ctime).isoformat(),
    }

@mcp.tool()
def list_directory(path: str = "~", show_hidden: bool = False) -> Dict:
    """
    List contents of a directory

    Args:
        path: Directory path (must be in allowed paths)
        show_hidden: Include hidden files (starting with .)
    """
    path = os.path.expanduser(path)

    if not is_safe_path(path):
        return {"error": f"Access denied: {path}"}

    p = Path(path).resolve()

    if not p.exists():
        return {"error": f"Path does not exist: {path}"}

    if not p.is_dir():
        return {"error": f"Not a directory: {path}"}

    try:
        items = []
        for item in p.iterdir():
            if not show_hidden and item.name.startswith('.'):
                continue

            try:
                items.append(path_info(item))
            except PermissionError:
                items.append({
                    "name": item.name,
                    "path": str(item),
                    "error": "Permission denied"
                })

        # Sort: directories first, then files, alphabetically
        items.sort(key=lambda x: (x.get("type") != "directory", x["name"].lower()))

        return {
            "path": str(p),
            "items": items,
            "count": len(items),
            "allowed_paths": [str(p) for p in ALLOWED_PATHS]
        }
    except Exception as e:
        return {"error": f"Error reading directory: {str(e)}"}

@mcp.tool()
def read_file(path: str, encoding: str = "utf-8", max_size: int = 1048576) -> Dict:
    """
    Read contents of a text file

    Args:
        path: File path (must be in allowed paths)
        encoding: Text encoding (default: utf-8)
        max_size: Maximum file size in bytes (default: 1MB)
    """
    path = os.path.expanduser(path)

    if not is_safe_path(path):
        return {"error": f"Access denied: {path}"}

    p = Path(path).resolve()

    if not p.exists():
        return {"error": f"File does not exist: {path}"}

    if not p.is_file():
        return {"error": f"Not a file: {path}"}

    if p.stat().st_size > max_size:
        return {"error": f"File too large (max {max_size} bytes)"}

    try:
        content = p.read_text(encoding=encoding)
        return {
            "path": str(p),
            "content": content,
            "size": len(content),
            "lines": content.count('\n') + 1,
            "encoding": encoding
        }
    except UnicodeDecodeError:
        return {"error": f"Cannot decode file with encoding '{encoding}'"}
    except Exception as e:
        return {"error": f"Error reading file: {str(e)}"}

@mcp.tool()
def search_files(pattern: str, path: str = "~", recursive: bool = True) -> Dict:
    """
    Search for files matching a pattern

    Args:
        pattern: Glob pattern (e.g., "*.txt", "report_*.pdf")
        path: Starting directory
        recursive: Search subdirectories
    """
    path = os.path.expanduser(path)

    if not is_safe_path(path):
        return {"error": f"Access denied: {path}"}

    p = Path(path).resolve()

    if not p.exists() or not p.is_dir():
        return {"error": f"Invalid directory: {path}"}

    try:
        if recursive:
            matches = list(p.rglob(pattern))
        else:
            matches = list(p.glob(pattern))

        # Filter for allowed paths
        matches = [m for m in matches if is_safe_path(str(m))]

        results = []
        for match in matches[:100]:  # Limit results
            try:
                results.append(path_info(match))
            except Exception:
                continue

        return {
            "pattern": pattern,
            "path": str(p),
            "matches": results,
            "count": len(results),
            "truncated": len(matches) > 100
        }
    except Exception as e:
        return {"error": f"Search error: {str(e)}"}

@mcp.resource("file://{path}")
def file_resource(path: str) -> Optional[str]:
    """Access file as a resource"""
    result = read_file(path)
    if "error" in result:
        return None
    return json.dumps({
        "content": result["content"],
        "metadata": {
            "path": result["path"],
            "size": result["size"],
            "lines": result["lines"]
        }
    })

if __name__ == "__main__":
    mcp.run()
```

### Example 4: Multi-Service Orchestrator

Coordinate multiple services:

```python
# orchestrator_server.py
from fastmcp import FastMCP
import asyncio
from typing import List, Dict, Any
from datetime import datetime
import httpx

mcp = FastMCP("orchestrator")

# Service registry
SERVICES = {
    "weather": "http://localhost:8001",
    "news": "http://localhost:8002",
    "stocks": "http://localhost:8003"
}

@mcp.tool()
async def get_morning_briefing(city: str, stock_symbols: List[str] = None) -> Dict:
    """
    Get a morning briefing with weather, news, and stocks

    Args:
        city: City for weather
        stock_symbols: Stock symbols to check (optional)
    """
    tasks = []

    # Weather task
    async def get_weather():
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{SERVICES['weather']}/tool/get_current_weather",
                    json={"city": city}
                )
                return {"weather": response.json()}
        except Exception as e:
            return {"weather": {"error": str(e)}}

    # News task
    async def get_news():
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{SERVICES['news']}/tool/get_headlines",
                    json={"category": "general", "limit": 5}
                )
                return {"news": response.json()}
        except Exception as e:
            return {"news": {"error": str(e)}}

    # Stocks task
    async def get_stocks():
        if not stock_symbols:
            return {"stocks": None}

        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{SERVICES['stocks']}/tool/get_quotes",
                    json={"symbols": stock_symbols}
                )
                return {"stocks": response.json()}
        except Exception as e:
            return {"stocks": {"error": str(e)}}

    # Run all tasks in parallel
    results = await asyncio.gather(
        get_weather(),
        get_news(),
        get_stocks()
    )

    # Combine results
    briefing = {}
    for result in results:
        briefing.update(result)

    return {
        "timestamp": datetime.now().isoformat(),
        "city": city,
        "briefing": briefing
    }

if __name__ == "__main__":
    mcp.run()
```