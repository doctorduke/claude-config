# MCP Implementation Patterns

## Architectural Patterns

### 1. API Gateway Pattern

Expose multiple external APIs through a single MCP server:

```python
from fastmcp import FastMCP
import httpx
from typing import Optional, Dict, Any

mcp = FastMCP("api-gateway")

# Centralized client with retries
class APIClient:
    def __init__(self):
        self.client = httpx.AsyncClient(
            timeout=30.0,
            limits=httpx.Limits(max_keepalive_connections=5)
        )

    async def call(self, service: str, endpoint: str, **kwargs) -> Dict[Any, Any]:
        """Route to appropriate service"""
        services = {
            "weather": "https://api.weather.com",
            "news": "https://api.news.com",
            "stocks": "https://api.stocks.com"
        }

        base_url = services.get(service)
        if not base_url:
            raise ValueError(f"Unknown service: {service}")

        response = await self.client.get(f"{base_url}/{endpoint}", **kwargs)
        response.raise_for_status()
        return response.json()

api_client = APIClient()

@mcp.tool()
async def query_service(service: str, endpoint: str, params: Optional[Dict] = None) -> Dict:
    """Query any configured API service"""
    try:
        return await api_client.call(service, endpoint, params=params)
    except httpx.HTTPError as e:
        return {"error": f"API call failed: {str(e)}"}
```

### 2. Repository Pattern

Abstract data access with consistent interface:

```python
import json
from abc import ABC, abstractmethod
from typing import List, Optional, Dict

class Repository(ABC):
    @abstractmethod
    async def find(self, id: str) -> Optional[Dict]:
        pass

    @abstractmethod
    async def find_all(self, limit: int = 100) -> List[Dict]:
        pass

    @abstractmethod
    async def create(self, data: Dict) -> str:
        pass

    @abstractmethod
    async def update(self, id: str, data: Dict) -> bool:
        pass

    @abstractmethod
    async def delete(self, id: str) -> bool:
        pass

class SQLRepository(Repository):
    def __init__(self, connection_string: str, table: str):
        self.conn_str = connection_string
        self.table = table

    async def find(self, id: str) -> Optional[Dict]:
        # SQL implementation
        pass

class MongoRepository(Repository):
    def __init__(self, connection_string: str, collection: str):
        self.conn_str = connection_string
        self.collection = collection

    async def find(self, id: str) -> Optional[Dict]:
        # MongoDB implementation
        pass

# Use with MCP
mcp = FastMCP("data-server")
user_repo = SQLRepository("sqlite:///app.db", "users")

@mcp.tool()
async def get_user(user_id: str) -> Optional[Dict]:
    """Get user by ID from repository"""
    return await user_repo.find(user_id)

@mcp.resource("db://users/{user_id}")
async def user_resource(user_id: str) -> str:
    """Expose user as resource"""
    user = await user_repo.find(user_id)
    return json.dumps(user) if user else None
```

### 3. Chain of Responsibility Pattern

Process requests through multiple handlers:

```python
from typing import Optional, Callable

class Handler:
    def __init__(self, name: str):
        self.name = name
        self.next_handler: Optional[Handler] = None

    def set_next(self, handler: 'Handler') -> 'Handler':
        self.next_handler = handler
        return handler

    async def handle(self, request: Dict) -> Dict:
        # Process request
        result = await self._process(request)

        # Pass to next handler if needed
        if self.next_handler and not result.get("completed"):
            return await self.next_handler.handle(request)

        return result

    async def _process(self, request: Dict) -> Dict:
        # Override in subclasses
        return {"completed": False}

class ValidationHandler(Handler):
    async def _process(self, request: Dict) -> Dict:
        if not request.get("data"):
            return {"error": "No data provided", "completed": True}
        return {"completed": False}

class AuthorizationHandler(Handler):
    async def _process(self, request: Dict) -> Dict:
        if not request.get("token"):
            return {"error": "Unauthorized", "completed": True}
        return {"completed": False}

class ProcessingHandler(Handler):
    async def _process(self, request: Dict) -> Dict:
        # Actual processing logic
        result = await perform_operation(request["data"])
        return {"result": result, "completed": True}

# Setup chain
validation = ValidationHandler("validation")
auth = AuthorizationHandler("authorization")
processing = ProcessingHandler("processing")

validation.set_next(auth).set_next(processing)

@mcp.tool()
async def process_request(data: Dict, token: Optional[str] = None) -> Dict:
    """Process request through handler chain"""
    request = {"data": data, "token": token}
    return await validation.handle(request)
```

### 4. Observer Pattern

Notify subscribers when resources change:

```python
import json
from typing import List, Callable, Dict, Any
import asyncio

class ResourceObserver:
    def __init__(self):
        self.observers: Dict[str, List[Callable]] = {}
        self.resources: Dict[str, Any] = {}

    def subscribe(self, resource_uri: str, callback: Callable):
        if resource_uri not in self.observers:
            self.observers[resource_uri] = []
        self.observers[resource_uri].append(callback)

    async def update_resource(self, resource_uri: str, data: Any):
        self.resources[resource_uri] = data

        # Notify all observers
        if resource_uri in self.observers:
            for callback in self.observers[resource_uri]:
                asyncio.create_task(callback(resource_uri, data))

    def get_resource(self, resource_uri: str) -> Any:
        return self.resources.get(resource_uri)

observer = ResourceObserver()

@mcp.resource("data://live/{key}", subscribe=True)
def get_live_data(key: str) -> str:
    """Get live updating resource"""
    data = observer.get_resource(f"data://live/{key}")
    return json.dumps(data) if data else None

async def notify_mcp(resource_uri: str, data: Any):
    """Notify MCP clients of resource change"""
    mcp.notify_resource_changed(resource_uri)

# Subscribe MCP notifications
observer.subscribe("data://live/status", notify_mcp)

@mcp.tool()
async def update_status(key: str, value: Any) -> Dict:
    """Update live status (triggers notifications)"""
    await observer.update_resource(f"data://live/{key}", value)
    return {"status": "updated", "key": key}
```

## Integration Patterns

### 5. Database Connection Pool Pattern

Efficiently manage database connections:

```python
import asyncpg
from contextlib import asynccontextmanager

class DatabasePool:
    def __init__(self, dsn: str, min_size: int = 10, max_size: int = 20):
        self.dsn = dsn
        self.min_size = min_size
        self.max_size = max_size
        self.pool: Optional[asyncpg.Pool] = None

    async def init(self):
        self.pool = await asyncpg.create_pool(
            self.dsn,
            min_size=self.min_size,
            max_size=self.max_size
        )

    async def close(self):
        if self.pool:
            await self.pool.close()

    @asynccontextmanager
    async def acquire(self):
        async with self.pool.acquire() as conn:
            yield conn

db_pool = DatabasePool("postgresql://localhost/mydb")

@mcp.on_startup()
async def startup():
    await db_pool.init()

@mcp.on_shutdown()
async def shutdown():
    await db_pool.close()

@mcp.tool()
async def query_database(sql: str, params: List = None) -> List[Dict]:
    """Execute database query with connection pooling"""
    async with db_pool.acquire() as conn:
        rows = await conn.fetch(sql, *(params or []))
        return [dict(row) for row in rows]
```

### 6. Caching Pattern

Implement intelligent caching:

```python
import asyncio
import hashlib
import json
from datetime import datetime, timedelta
from typing import Optional, Any, Dict, List

class CacheEntry:
    def __init__(self, value: Any, ttl: int):
        self.value = value
        self.expires_at = datetime.now() + timedelta(seconds=ttl)

    def is_expired(self) -> bool:
        return datetime.now() > self.expires_at

class SmartCache:
    def __init__(self):
        self.cache: Dict[str, CacheEntry] = {}

    def _make_key(self, func_name: str, *args, **kwargs) -> str:
        """Generate cache key from function and arguments"""
        key_data = f"{func_name}:{args}:{sorted(kwargs.items())}"
        return hashlib.md5(key_data.encode()).hexdigest()

    def get(self, key: str) -> Optional[Any]:
        if key in self.cache:
            entry = self.cache[key]
            if not entry.is_expired():
                return entry.value
            else:
                del self.cache[key]
        return None

    def set(self, key: str, value: Any, ttl: int = 300):
        self.cache[key] = CacheEntry(value, ttl)

    def invalidate(self, pattern: str = None):
        """Invalidate cache entries matching pattern"""
        if pattern:
            keys_to_delete = [k for k in self.cache if pattern in k]
            for key in keys_to_delete:
                del self.cache[key]
        else:
            self.cache.clear()

cache = SmartCache()

def cached(ttl: int = 300):
    """Decorator for caching tool results"""
    def decorator(func):
        async def wrapper(*args, **kwargs):
            cache_key = cache._make_key(func.__name__, *args, **kwargs)

            # Check cache
            cached_value = cache.get(cache_key)
            if cached_value is not None:
                return cached_value

            # Call function
            result = await func(*args, **kwargs) if asyncio.iscoroutinefunction(func) else func(*args, **kwargs)

            # Cache result
            cache.set(cache_key, result, ttl)
            return result

        return wrapper
    return decorator

@mcp.tool()
@cached(ttl=60)  # Cache for 1 minute
async def expensive_search(query: str) -> List[Dict]:
    """Expensive search operation with caching"""
    # Simulate expensive operation
    await asyncio.sleep(2)
    return perform_search(query)

@mcp.tool()
def clear_cache(pattern: Optional[str] = None) -> Dict:
    """Clear cache entries"""
    cache.invalidate(pattern)
    return {"status": "cache cleared", "pattern": pattern}
```

### 7. Rate Limiting Pattern

Implement sophisticated rate limiting:

```python
from collections import defaultdict, deque
from datetime import datetime, timedelta
import asyncio

class RateLimiter:
    def __init__(self):
        self.limits = {
            "default": {"calls": 60, "window": 60},  # 60 calls per minute
            "expensive": {"calls": 10, "window": 60},  # 10 calls per minute
            "bulk": {"calls": 1000, "window": 3600},  # 1000 calls per hour
        }
        self.requests = defaultdict(deque)

    async def check_limit(self, client_id: str, operation_type: str = "default") -> bool:
        """Check if client has exceeded rate limit"""
        limit_config = self.limits.get(operation_type, self.limits["default"])
        now = datetime.now()
        window = timedelta(seconds=limit_config["window"])
        cutoff = now - window

        # Clean old requests
        client_requests = self.requests[f"{client_id}:{operation_type}"]
        while client_requests and client_requests[0] < cutoff:
            client_requests.popleft()

        # Check limit
        if len(client_requests) >= limit_config["calls"]:
            return False

        # Record request
        client_requests.append(now)
        return True

    def get_wait_time(self, client_id: str, operation_type: str = "default") -> float:
        """Get seconds until rate limit resets"""
        limit_config = self.limits.get(operation_type, self.limits["default"])
        client_requests = self.requests[f"{client_id}:{operation_type}"]

        if not client_requests:
            return 0

        oldest = client_requests[0]
        reset_time = oldest + timedelta(seconds=limit_config["window"])
        wait = (reset_time - datetime.now()).total_seconds()
        return max(0, wait)

limiter = RateLimiter()

def rate_limited(operation_type: str = "default"):
    """Decorator for rate limiting"""
    def decorator(func):
        async def wrapper(client_id: str, *args, **kwargs):
            if not await limiter.check_limit(client_id, operation_type):
                wait_time = limiter.get_wait_time(client_id, operation_type)
                return {
                    "error": "Rate limit exceeded",
                    "retry_after": wait_time,
                    "operation_type": operation_type
                }

            return await func(client_id, *args, **kwargs)
        return wrapper
    return decorator

@mcp.tool()
@rate_limited("expensive")
async def expensive_operation(client_id: str, data: Dict) -> Dict:
    """Rate-limited expensive operation"""
    result = await perform_expensive_operation(data)
    return {"status": "success", "result": result}
```

### 8. Circuit Breaker Pattern

Prevent cascading failures:

```python
from collections import defaultdict
from enum import Enum
from datetime import datetime, timedelta

class CircuitState(Enum):
    CLOSED = "closed"  # Normal operation
    OPEN = "open"      # Failing, reject requests
    HALF_OPEN = "half_open"  # Testing recovery

class CircuitBreaker:
    def __init__(self, failure_threshold: int = 5, recovery_timeout: int = 60):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.failure_count = 0
        self.last_failure_time = None
        self.state = CircuitState.CLOSED

    def call(self, func, *args, **kwargs):
        if self.state == CircuitState.OPEN:
            if self._should_attempt_reset():
                self.state = CircuitState.HALF_OPEN
            else:
                raise Exception("Circuit breaker is OPEN")

        try:
            result = func(*args, **kwargs)
            self._on_success()
            return result
        except Exception as e:
            self._on_failure()
            raise e

    def _should_attempt_reset(self) -> bool:
        return (
            self.last_failure_time and
            datetime.now() - self.last_failure_time > timedelta(seconds=self.recovery_timeout)
        )

    def _on_success(self):
        self.failure_count = 0
        self.state = CircuitState.CLOSED

    def _on_failure(self):
        self.failure_count += 1
        self.last_failure_time = datetime.now()

        if self.failure_count >= self.failure_threshold:
            self.state = CircuitState.OPEN

# Per-service circuit breakers
circuit_breakers = defaultdict(lambda: CircuitBreaker())

@mcp.tool()
def call_external_service(service_name: str, endpoint: str) -> Dict:
    """Call external service with circuit breaker"""
    breaker = circuit_breakers[service_name]

    try:
        return breaker.call(make_api_call, service_name, endpoint)
    except Exception as e:
        return {
            "error": str(e),
            "circuit_state": breaker.state.value,
            "retry_after": breaker.recovery_timeout if breaker.state == CircuitState.OPEN else 0
        }
```