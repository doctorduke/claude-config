# Workflow Implementation Patterns

This document provides detailed implementation patterns for the 7 core workflow orchestration patterns.

## Pattern 1: DAG Workflow

### Overview

Direct Acyclic Graph (DAG) workflows model tasks with dependencies. Tasks execute when all dependencies complete, enabling parallel execution where possible.

### When to Use

- Clear task dependencies
- Parallelization opportunities
- Data pipelines (ETL)
- Build systems
- CI/CD pipelines

### Implementation

```python
from collections import defaultdict, deque
from typing import Callable, Dict, List, Set, Any
from dataclasses import dataclass
from enum import Enum

class TaskStatus(Enum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"

@dataclass
class Task:
    id: str
    func: Callable
    depends_on: List[str] = None
    status: TaskStatus = TaskStatus.PENDING
    result: Any = None
    error: Exception = None

    def __post_init__(self):
        if self.depends_on is None:
            self.depends_on = []

class DAGWorkflow:
    def __init__(self):
        self.tasks: Dict[str, Task] = {}
        self.graph: Dict[str, List[str]] = defaultdict(list)

    def add_task(self, task_id: str, func: Callable, depends_on: List[str] = None):
        """Add task to workflow"""
        task = Task(id=task_id, func=func, depends_on=depends_on or [])
        self.tasks[task_id] = task

        # Build adjacency list
        for dep in task.depends_on:
            self.graph[dep].append(task_id)

    def validate(self) -> bool:
        """Validate DAG has no cycles"""
        visited = set()
        rec_stack = set()

        def has_cycle(node):
            visited.add(node)
            rec_stack.add(node)

            for neighbor in self.graph.get(node, []):
                if neighbor not in visited:
                    if has_cycle(neighbor):
                        return True
                elif neighbor in rec_stack:
                    return True

            rec_stack.remove(node)
            return False

        for task_id in self.tasks:
            if task_id not in visited:
                if has_cycle(task_id):
                    raise ValueError(f"Cycle detected in DAG")

        return True

    def topological_sort(self) -> List[str]:
        """Return tasks in executable order"""
        in_degree = {task_id: len(task.depends_on) for task_id, task in self.tasks.items()}
        queue = deque([task_id for task_id, degree in in_degree.items() if degree == 0])
        result = []

        while queue:
            task_id = queue.popleft()
            result.append(task_id)

            for neighbor in self.graph[task_id]:
                in_degree[neighbor] -= 1
                if in_degree[neighbor] == 0:
                    queue.append(neighbor)

        if len(result) != len(self.tasks):
            raise ValueError("Graph has cycles")

        return result

    def get_ready_tasks(self) -> List[Task]:
        """Get tasks ready to execute (dependencies met)"""
        ready = []
        for task in self.tasks.values():
            if task.status == TaskStatus.PENDING:
                # Check all dependencies completed
                if all(self.tasks[dep].status == TaskStatus.COMPLETED for dep in task.depends_on):
                    ready.append(task)
        return ready

    def execute(self, max_parallel: int = 4) -> Dict[str, Any]:
        """Execute DAG workflow"""
        self.validate()

        # Execute tasks as dependencies are met
        while any(t.status in [TaskStatus.PENDING, TaskStatus.RUNNING] for t in self.tasks.values()):
            ready_tasks = self.get_ready_tasks()

            # Execute ready tasks (up to max_parallel)
            for task in ready_tasks[:max_parallel]:
                task.status = TaskStatus.RUNNING
                try:
                    # Get results from dependencies
                    dep_results = {dep: self.tasks[dep].result for dep in task.depends_on}
                    task.result = task.func(**dep_results) if dep_results else task.func()
                    task.status = TaskStatus.COMPLETED
                except Exception as e:
                    task.error = e
                    task.status = TaskStatus.FAILED
                    raise

        return {task_id: task.result for task_id, task in self.tasks.items()}
```

### Usage Example

```python
# Define workflow
workflow = DAGWorkflow()

# Add tasks
workflow.add_task("fetch", lambda: fetch_data_from_api())
workflow.add_task("validate", lambda fetch: validate_data(fetch), depends_on=["fetch"])
workflow.add_task("transform", lambda validate: transform_data(validate), depends_on=["validate"])
workflow.add_task("save_db", lambda transform: save_to_db(transform), depends_on=["transform"])
workflow.add_task("save_cache", lambda transform: save_to_cache(transform), depends_on=["transform"])
workflow.add_task("notify", lambda save_db, save_cache: send_notification(), depends_on=["save_db", "save_cache"])

# Execute
results = workflow.execute()
```

### Key Features

- Automatic dependency resolution
- Parallel execution where possible
- Cycle detection
- Topological sorting
- Status tracking

---

## Pattern 2: State Machine Workflow

### Overview

Finite State Machine (FSM) workflows model complex state transitions with guards (conditions) and actions (side effects).

### When to Use

- Complex state transitions
- Approval workflows
- Deployment pipelines
- Order processing
- Document lifecycle

### Implementation

```python
from dataclasses import dataclass
from typing import Callable, Dict, List, Optional, Any
from enum import Enum

@dataclass
class Transition:
    from_state: str
    to_state: str
    event: str
    guard: Optional[Callable[[], bool]] = None
    action: Optional[Callable[[], None]] = None

class StateMachine:
    def __init__(self, initial_state: str, context: Optional[Dict[str, Any]] = None):
        self.current_state = initial_state
        self.initial_state = initial_state
        self.transitions: List[Transition] = []
        self.context = context or {}
        self.history: List[str] = [initial_state]

    def add_transition(
        self,
        from_state: str,
        to_state: str,
        event: str,
        guard: Optional[Callable[[Dict], bool]] = None,
        action: Optional[Callable[[Dict], None]] = None
    ):
        """Add state transition"""
        # Support wildcard from_state
        if from_state == "*":
            # Add transition from all states
            all_states = {t.from_state for t in self.transitions} | {t.to_state for t in self.transitions}
            all_states.add(self.initial_state)
            for state in all_states:
                self.transitions.append(Transition(state, to_state, event, guard, action))
        else:
            self.transitions.append(Transition(from_state, to_state, event, guard, action))

    def trigger(self, event: str) -> bool:
        """Trigger event to transition state"""
        # Find matching transitions
        matching = [
            t for t in self.transitions
            if t.from_state == self.current_state and t.event == event
        ]

        if not matching:
            raise ValueError(f"No transition for event '{event}' from state '{self.current_state}'")

        # Check guards and execute first valid transition
        for transition in matching:
            if transition.guard is None or transition.guard(self.context):
                # Execute action
                if transition.action:
                    transition.action(self.context)

                # Transition state
                self.current_state = transition.to_state
                self.history.append(self.current_state)
                return True

        return False

    def can_trigger(self, event: str) -> bool:
        """Check if event can be triggered"""
        matching = [
            t for t in self.transitions
            if t.from_state == self.current_state and t.event == event
        ]

        for transition in matching:
            if transition.guard is None or transition.guard(self.context):
                return True

        return False

    def reset(self):
        """Reset to initial state"""
        self.current_state = self.initial_state
        self.history = [self.initial_state]
        self.context.clear()

    def get_available_events(self) -> List[str]:
        """Get events that can be triggered from current state"""
        events = []
        for t in self.transitions:
            if t.from_state == self.current_state:
                if t.guard is None or t.guard(self.context):
                    events.append(t.event)
        return events
```

### Usage Example

```python
# Deployment pipeline state machine
def can_deploy(ctx):
    return ctx.get("tests_passed") and ctx.get("approved")

def deploy_to_staging(ctx):
    print("Deploying to staging...")
    ctx["staging_url"] = "https://staging.example.com"

def deploy_to_production(ctx):
    print("Deploying to production...")
    ctx["production_url"] = "https://example.com"

def rollback(ctx):
    print("Rolling back deployment...")
    ctx["rolled_back"] = True

# Create state machine
pipeline = StateMachine("idle", context={})

# Define transitions
pipeline.add_transition("idle", "building", "start")
pipeline.add_transition("building", "testing", "build_complete")
pipeline.add_transition("testing", "awaiting_approval", "tests_passed")
pipeline.add_transition("testing", "failed", "tests_failed")
pipeline.add_transition("awaiting_approval", "staging", "approved", action=deploy_to_staging)
pipeline.add_transition("staging", "production", "promote", guard=can_deploy, action=deploy_to_production)
pipeline.add_transition("*", "rollback", "rollback", action=rollback)

# Execute workflow
pipeline.trigger("start")
pipeline.trigger("build_complete")
pipeline.context["tests_passed"] = True
pipeline.trigger("tests_passed")
pipeline.context["approved"] = True
pipeline.trigger("approved")
pipeline.trigger("promote")

print(f"Final state: {pipeline.current_state}")
print(f"History: {' -> '.join(pipeline.history)}")
```

---

## Pattern 3: Event-Driven Workflow

### Overview

Event-driven workflows react to events asynchronously using pub/sub patterns. Components are loosely coupled through event bus.

### When to Use

- Reactive systems
- Microservices coordination
- Async processing
- Event sourcing
- Real-time updates

### Implementation

```python
from dataclasses import dataclass
from typing import Callable, Dict, List, Any
from collections import defaultdict
import json
from datetime import datetime

@dataclass
class Event:
    type: str
    data: Dict[str, Any]
    timestamp: str = None
    id: str = None

    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = datetime.utcnow().isoformat()
        if self.id is None:
            import uuid
            self.id = str(uuid.uuid4())

class EventBus:
    def __init__(self, enable_event_sourcing: bool = False):
        self.subscribers: Dict[str, List[Callable]] = defaultdict(list)
        self.event_store: List[Event] = []
        self.enable_event_sourcing = enable_event_sourcing

    def subscribe(self, event_type: str, handler: Callable[[Event], None]):
        """Subscribe to event type"""
        self.subscribers[event_type].append(handler)

    def unsubscribe(self, event_type: str, handler: Callable):
        """Unsubscribe from event type"""
        if handler in self.subscribers[event_type]:
            self.subscribers[event_type].remove(handler)

    def publish(self, event: Event):
        """Publish event to subscribers"""
        # Store event if event sourcing enabled
        if self.enable_event_sourcing:
            self.event_store.append(event)

        # Notify subscribers
        for handler in self.subscribers[event.type]:
            try:
                handler(event)
            except Exception as e:
                print(f"Error in handler: {e}")
                # Could publish error event
                self.publish(Event("handler.error", {"error": str(e), "original_event": event.id}))

    def replay(self, from_position: int = 0):
        """Replay events from event store"""
        if not self.enable_event_sourcing:
            raise ValueError("Event sourcing not enabled")

        for event in self.event_store[from_position:]:
            # Republish without storing again
            temp = self.enable_event_sourcing
            self.enable_event_sourcing = False
            self.publish(event)
            self.enable_event_sourcing = temp

class EventDrivenWorkflow:
    def __init__(self):
        self.event_bus = EventBus(enable_event_sourcing=True)
        self.state = {}

    def on_event(self, event_type: str):
        """Decorator to register event handler"""
        def decorator(func):
            self.event_bus.subscribe(event_type, func)
            return func
        return decorator

    def emit(self, event_type: str, data: Dict[str, Any]):
        """Emit event"""
        event = Event(event_type, data)
        self.event_bus.publish(event)
```

### Usage Example

```python
# Create event-driven workflow
workflow = EventDrivenWorkflow()

# Define handlers
@workflow.on_event("order.created")
def handle_order_created(event: Event):
    print(f"Order created: {event.data['order_id']}")
    workflow.state["order_id"] = event.data["order_id"]
    workflow.emit("payment.process", {"order_id": event.data["order_id"]})

@workflow.on_event("payment.process")
def handle_payment(event: Event):
    print(f"Processing payment for order: {event.data['order_id']}")
    # Simulate payment processing
    workflow.emit("payment.completed", {"order_id": event.data["order_id"], "payment_id": "pay-123"})

@workflow.on_event("payment.completed")
def handle_payment_completed(event: Event):
    print(f"Payment completed: {event.data['payment_id']}")
    workflow.emit("shipping.start", {"order_id": event.data["order_id"]})

@workflow.on_event("shipping.start")
def handle_shipping(event: Event):
    print(f"Shipping order: {event.data['order_id']}")
    workflow.emit("order.completed", {"order_id": event.data["order_id"]})

@workflow.on_event("order.completed")
def handle_order_completed(event: Event):
    print(f"Order completed: {event.data['order_id']}")

# Trigger workflow
workflow.emit("order.created", {"order_id": "order-456"})

# Replay events (e.g., for debugging or recovery)
print("\nReplaying events:")
workflow.event_bus.replay()
```

---

## Pattern 4: Saga Pattern

### Overview

Saga pattern coordinates distributed transactions without 2PC (two-phase commit). Each step has a compensating action for rollback.

### When to Use

- Distributed transactions
- Multi-service coordination
- Long-running transactions
- Need for compensation logic
- Eventual consistency acceptable

### Implementation

```python
from dataclasses import dataclass
from typing import Callable, List, Any, Optional
from enum import Enum

class SagaStatus(Enum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    COMPENSATING = "compensating"
    COMPENSATED = "compensated"
    FAILED = "failed"

@dataclass
class SagaStep:
    name: str
    forward: Callable[[], Any]
    compensate: Callable[[], None]
    result: Optional[Any] = None
    executed: bool = False

class SagaOrchestrator:
    def __init__(self, name: str):
        self.name = name
        self.steps: List[SagaStep] = []
        self.status = SagaStatus.PENDING
        self.executed_steps: List[SagaStep] = []

    def add_step(self, name: str, forward: Callable, compensate: Callable):
        """Add saga step with forward and compensate actions"""
        self.steps.append(SagaStep(name, forward, compensate))

    def execute(self) -> Any:
        """Execute saga with compensation on failure"""
        self.status = SagaStatus.RUNNING
        results = {}

        try:
            # Execute forward actions
            for step in self.steps:
                print(f"Executing step: {step.name}")
                step.result = step.forward()
                step.executed = True
                self.executed_steps.append(step)
                results[step.name] = step.result

            self.status = SagaStatus.COMPLETED
            return results

        except Exception as e:
            print(f"Saga failed at step '{step.name}': {e}")
            self.status = SagaStatus.COMPENSATING

            # Compensate in reverse order
            for step in reversed(self.executed_steps):
                try:
                    print(f"Compensating step: {step.name}")
                    step.compensate()
                except Exception as comp_err:
                    print(f"Compensation failed for '{step.name}': {comp_err}")
                    # Log but continue compensating other steps

            self.status = SagaStatus.COMPENSATED
            raise Exception(f"Saga '{self.name}' failed and compensated") from e

class SagaChoreography:
    """Alternative: Choreography-based saga (no central orchestrator)"""
    def __init__(self):
        self.event_handlers = {}

    def on_event(self, event_type: str, handler: Callable, compensate: Callable):
        """Register event handler with compensation"""
        self.event_handlers[event_type] = {"handler": handler, "compensate": compensate}
```

### Usage Example (Orchestration)

```python
# E-commerce order saga
saga = SagaOrchestrator("OrderSaga")

# Step 1: Reserve inventory
def reserve_inventory():
    print("  -> Reserving inventory")
    # Simulate API call
    return {"reservation_id": "res-123"}

def release_inventory():
    print("  <- Releasing inventory")
    # Simulate API call

saga.add_step("reserve_inventory", reserve_inventory, release_inventory)

# Step 2: Process payment
def process_payment():
    print("  -> Processing payment")
    # Simulate payment processing
    return {"payment_id": "pay-456"}

def refund_payment():
    print("  <- Refunding payment")
    # Simulate refund

saga.add_step("process_payment", process_payment, refund_payment)

# Step 3: Create shipment
def create_shipment():
    print("  -> Creating shipment")
    # Simulate failure
    raise Exception("Shipment service unavailable")

def cancel_shipment():
    print("  <- Canceling shipment")

saga.add_step("create_shipment", create_shipment, cancel_shipment)

# Execute saga (will fail and compensate)
try:
    result = saga.execute()
except Exception as e:
    print(f"\nSaga result: {saga.status}")
```

---

## Pattern 5: Error Handling & Recovery

### Overview

Robust error handling with retry strategies, circuit breakers, fallbacks, and dead letter queues.

### Implementation

```python
import time
import random
from typing import Callable, Any
from enum import Enum
from dataclasses import dataclass

class CircuitState(Enum):
    CLOSED = "closed"
    OPEN = "open"
    HALF_OPEN = "half_open"

class CircuitBreaker:
    def __init__(self, failure_threshold: int = 5, timeout: float = 60):
        self.failure_threshold = failure_threshold
        self.timeout = timeout
        self.failures = 0
        self.last_failure_time = None
        self.state = CircuitState.CLOSED

    def call(self, func: Callable, *args, **kwargs) -> Any:
        if self.state == CircuitState.OPEN:
            if time.time() - self.last_failure_time > self.timeout:
                self.state = CircuitState.HALF_OPEN
            else:
                raise Exception("Circuit breaker is OPEN")

        try:
            result = func(*args, **kwargs)
            if self.state == CircuitState.HALF_OPEN:
                self.state = CircuitState.CLOSED
                self.failures = 0
            return result
        except Exception as e:
            self.failures += 1
            self.last_failure_time = time.time()
            if self.failures >= self.failure_threshold:
                self.state = CircuitState.OPEN
            raise

class RetryStrategy:
    @staticmethod
    def exponential_backoff(
        func: Callable,
        max_attempts: int = 3,
        base_delay: float = 1.0,
        multiplier: float = 2.0,
        jitter: bool = True
    ) -> Any:
        """Retry with exponential backoff"""
        for attempt in range(max_attempts):
            try:
                return func()
            except Exception as e:
                if attempt == max_attempts - 1:
                    raise

                # Calculate delay
                delay = base_delay * (multiplier ** attempt)
                if jitter:
                    delay *= random.uniform(0.5, 1.5)

                print(f"Attempt {attempt + 1} failed, retrying in {delay:.2f}s...")
                time.sleep(delay)

class DeadLetterQueue:
    def __init__(self):
        self.messages = []

    def send(self, message: Any):
        """Send message to DLQ"""
        self.messages.append({
            "message": message,
            "timestamp": time.time()
        })

    def get_messages(self):
        """Retrieve DLQ messages"""
        return self.messages
```

### Usage Example

```python
# Circuit breaker example
circuit = CircuitBreaker(failure_threshold=3, timeout=10)

def unreliable_api_call():
    if random.random() < 0.7:  # 70% failure rate
        raise Exception("API call failed")
    return "Success"

# Retry with circuit breaker
for i in range(10):
    try:
        result = RetryStrategy.exponential_backoff(
            lambda: circuit.call(unreliable_api_call),
            max_attempts=3
        )
        print(f"Call {i+1}: {result}")
    except Exception as e:
        print(f"Call {i+1}: Failed - {e}")
        # Send to DLQ
        dlq = DeadLetterQueue()
        dlq.send({"call": i+1, "error": str(e)})
```

---

## Pattern 6: Workflow Observability

### Overview

Comprehensive observability with distributed tracing, metrics, and structured logging.

### Implementation

```python
import time
import json
from typing import Dict, Any, Optional
from dataclasses import dataclass, field
from contextlib import contextmanager

@dataclass
class Span:
    trace_id: str
    span_id: str
    parent_id: Optional[str]
    name: str
    start_time: float = field(default_factory=time.time)
    end_time: Optional[float] = None
    attributes: Dict[str, Any] = field(default_factory=dict)
    status: str = "ok"

    def finish(self):
        self.end_time = time.time()

    def duration(self) -> float:
        if self.end_time:
            return self.end_time - self.start_time
        return time.time() - self.start_time

class Tracer:
    def __init__(self):
        self.spans: Dict[str, Span] = {}
        self.current_span: Optional[Span] = None

    @contextmanager
    def start_span(self, name: str, attributes: Dict[str, Any] = None):
        """Start new span"""
        import uuid
        trace_id = str(uuid.uuid4()) if not self.current_span else self.current_span.trace_id
        span_id = str(uuid.uuid4())
        parent_id = self.current_span.span_id if self.current_span else None

        span = Span(
            trace_id=trace_id,
            span_id=span_id,
            parent_id=parent_id,
            name=name,
            attributes=attributes or {}
        )

        self.spans[span_id] = span
        previous_span = self.current_span
        self.current_span = span

        try:
            yield span
        except Exception as e:
            span.status = "error"
            span.attributes["error"] = str(e)
            raise
        finally:
            span.finish()
            self.current_span = previous_span

class MetricsCollector:
    def __init__(self):
        self.metrics = {
            "counters": {},
            "gauges": {},
            "histograms": {}
        }

    def increment(self, name: str, value: int = 1):
        """Increment counter"""
        self.metrics["counters"][name] = self.metrics["counters"].get(name, 0) + value

    def gauge(self, name: str, value: float):
        """Set gauge value"""
        self.metrics["gauges"][name] = value

    def histogram(self, name: str, value: float):
        """Record histogram value"""
        if name not in self.metrics["histograms"]:
            self.metrics["histograms"][name] = []
        self.metrics["histograms"][name].append(value)

class StructuredLogger:
    @staticmethod
    def log(level: str, message: str, **kwargs):
        """Structured logging"""
        log_entry = {
            "timestamp": time.time(),
            "level": level,
            "message": message,
            **kwargs
        }
        print(json.dumps(log_entry))
```

---

## Pattern 7: Load Balancing & Scaling

### Overview

Distribute work across workers with load balancing, work stealing, and backpressure.

### Implementation

```python
from queue import Queue, PriorityQueue
from threading import Thread, Lock
from typing import Callable, Any
from dataclasses import dataclass
import time

@dataclass
class Task:
    priority: int
    func: Callable
    args: tuple
    kwargs: dict

    def __lt__(self, other):
        return self.priority < other.priority

class WorkerPool:
    def __init__(self, num_workers: int = 4):
        self.num_workers = num_workers
        self.task_queue = PriorityQueue()
        self.workers = []
        self.results = []
        self.lock = Lock()

    def start(self):
        """Start worker threads"""
        for i in range(self.num_workers):
            worker = Thread(target=self._worker, args=(i,))
            worker.daemon = True
            worker.start()
            self.workers.append(worker)

    def _worker(self, worker_id: int):
        """Worker thread"""
        while True:
            try:
                task = self.task_queue.get(timeout=1)
                result = task.func(*task.args, **task.kwargs)
                with self.lock:
                    self.results.append(result)
                self.task_queue.task_done()
            except:
                pass

    def submit(self, func: Callable, priority: int = 0, *args, **kwargs):
        """Submit task to pool"""
        task = Task(priority, func, args, kwargs)
        self.task_queue.put(task)

    def wait(self):
        """Wait for all tasks to complete"""
        self.task_queue.join()
```

### Usage Example

```python
# Create worker pool
pool = WorkerPool(num_workers=4)
pool.start()

# Submit tasks
for i in range(20):
    pool.submit(lambda x: x**2, priority=i, x=i)

# Wait for completion
pool.wait()
print(f"Results: {pool.results}")
```
