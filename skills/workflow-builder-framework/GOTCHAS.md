# Workflow Gotchas and Troubleshooting

Common problems, antipatterns, and solutions when building workflows.

## DAG Workflow Gotchas

### 1. Circular Dependencies

**Problem**: Task A depends on B, B depends on C, C depends on A

```python
# WRONG: Creates a cycle
dag = DAGWorkflow()
dag.add_task("A", func_a, depends_on=["C"])
dag.add_task("B", func_b, depends_on=["A"])
dag.add_task("C", func_c, depends_on=["B"])
# This will raise: ValueError("Cycle detected in DAG")
```

**Detection**:
```python
def detect_cycle(tasks):
    """Detect cycles using DFS"""
    visited = set()
    rec_stack = set()

    def dfs(task):
        visited.add(task.id)
        rec_stack.add(task.id)

        for dep in task.depends_on:
            if dep not in visited:
                if dfs(tasks[dep]):
                    return True
            elif dep in rec_stack:
                print(f"Cycle detected: {task.id} -> {dep}")
                return True

        rec_stack.remove(task.id)
        return False

    for task in tasks.values():
        if task.id not in visited:
            if dfs(task):
                return True
    return False
```

**Solution**: Validate DAG before execution
```python
def validate_dag(workflow):
    """Validate DAG structure"""
    try:
        workflow.validate()  # Checks for cycles
        order = workflow.topological_sort()
        print(f"Execution order: {' -> '.join(order)}")
        return True
    except ValueError as e:
        print(f"Invalid DAG: {e}")
        return False
```

### 2. Missing Dependencies

**Problem**: Task references non-existent dependency

```python
# WRONG: "process" task doesn't exist
dag.add_task("save", save_func, depends_on=["process"])
# Later fails with KeyError
```

**Solution**: Validate all dependencies exist
```python
def validate_dependencies(workflow):
    """Check all dependencies exist"""
    for task_id, task in workflow.tasks.items():
        for dep in task.depends_on:
            if dep not in workflow.tasks:
                raise ValueError(f"Task '{task_id}' depends on non-existent task '{dep}'")
```

### 3. Over-Parallelization

**Problem**: Too many tasks run in parallel, overwhelming resources

```python
# WRONG: All 100 tasks run simultaneously
for i in range(100):
    dag.add_task(f"task_{i}", heavy_computation)
dag.execute()  # OOM or system overload
```

**Solution**: Limit parallelism
```python
# RIGHT: Control parallel execution
dag.execute(max_parallel=4)  # Only 4 tasks run concurrently

# Or use worker pool
from concurrent.futures import ThreadPoolExecutor
with ThreadPoolExecutor(max_workers=4) as executor:
    futures = [executor.submit(task.func) for task in ready_tasks[:4]]
```

### 4. Not Handling Partial Failures

**Problem**: One task fails, leaving workflow in inconsistent state

```python
# WRONG: No error handling
dag.execute()  # If task 5 of 10 fails, tasks 1-4 are done but not cleaned up
```

**Solution**: Implement cleanup and checkpointing
```python
class RobustDAG:
    def execute_with_checkpoints(self):
        """Execute with checkpoints for recovery"""
        checkpoint_file = "workflow_checkpoint.json"

        # Load previous checkpoint if exists
        completed = self._load_checkpoint(checkpoint_file)

        try:
            for task_id in self.topological_sort():
                if task_id in completed:
                    print(f"Skipping completed task: {task_id}")
                    continue

                result = self.tasks[task_id].func()
                completed[task_id] = result
                self._save_checkpoint(checkpoint_file, completed)

            return completed

        except Exception as e:
            print(f"Workflow failed at task {task_id}")
            print(f"Checkpoint saved. Resume with: workflow.execute_with_checkpoints()")
            raise
```

### 5. Ignoring Task Dependencies in Results

**Problem**: Tasks don't receive results from dependencies

```python
# WRONG: Task doesn't accept dependency results
def process():  # Missing parameter
    return transform(data)  # Where does 'data' come from?

dag.add_task("fetch", fetch_data)
dag.add_task("process", process, depends_on=["fetch"])
```

**Solution**: Accept dependency results as parameters
```python
# RIGHT: Accept dependency results
def process(fetch):  # Parameter name matches dependency task ID
    return transform(fetch)

dag.add_task("fetch", fetch_data)
dag.add_task("process", process, depends_on=["fetch"])
```

---

## State Machine Gotchas

### 1. Unreachable States

**Problem**: State can never be reached due to missing transitions

```python
# WRONG: "completed" state is unreachable
fsm = StateMachine("idle")
fsm.add_transition("idle", "running", "start")
fsm.add_transition("running", "paused", "pause")
# No transition to "completed"!
```

**Detection**:
```python
def find_unreachable_states(fsm):
    """Find states that can never be reached"""
    all_states = {t.from_state for t in fsm.transitions} | {t.to_state for t in fsm.transitions}
    reachable = {fsm.initial_state}
    changed = True

    while changed:
        changed = False
        for transition in fsm.transitions:
            if transition.from_state in reachable and transition.to_state not in reachable:
                reachable.add(transition.to_state)
                changed = True

    unreachable = all_states - reachable
    if unreachable:
        print(f"Unreachable states: {unreachable}")
    return unreachable
```

### 2. Guard Conditions Always False

**Problem**: Guard never evaluates to True, blocking transition

```python
# WRONG: Guard will never be True
def impossible_guard(ctx):
    return ctx["value"] > 100 and ctx["value"] < 50

fsm.add_transition("waiting", "ready", "check", guard=impossible_guard)
# Transition will never happen
```

**Solution**: Test guard conditions and add logging
```python
def logged_guard(ctx):
    """Guard with logging"""
    result = ctx["value"] > 50
    print(f"Guard check: value={ctx['value']}, result={result}")
    return result

fsm.add_transition("waiting", "ready", "check", guard=logged_guard)
```

### 3. Forgotten State in Wildcard Transition

**Problem**: Wildcard (*) transition doesn't work as expected

```python
# WRONG: Wildcard added before some states are defined
fsm.add_transition("*", "error", "error")
fsm.add_transition("new_state", "other", "continue")
# "new_state" -> "error" transition doesn't exist
```

**Solution**: Add wildcard transitions last
```python
# RIGHT: Add all normal transitions first
fsm.add_transition("idle", "running", "start")
fsm.add_transition("running", "paused", "pause")
fsm.add_transition("paused", "running", "resume")

# Then add wildcard transitions
fsm.add_transition("*", "error", "error")
```

### 4. Shared Context Mutations

**Problem**: Multiple transitions mutate shared context, causing race conditions

```python
# WRONG: Concurrent transitions mutate context
def action1(ctx):
    ctx["count"] += 1

def action2(ctx):
    ctx["count"] += 2

# If triggered concurrently, count may be incorrect
```

**Solution**: Use thread-safe context or atomic operations
```python
from threading import Lock

class ThreadSafeContext:
    def __init__(self):
        self._data = {}
        self._lock = Lock()

    def update(self, key, value):
        with self._lock:
            self._data[key] = value

    def get(self, key):
        with self._lock:
            return self._data.get(key)
```

---

## Event-Driven Gotchas

### 1. Event Ordering Issues

**Problem**: Events processed out of order

```python
# WRONG: Events processed in arbitrary order
bus.publish(Event("payment.process", {...}))
bus.publish(Event("order.cancel", {...}))
# Cancel might process before payment!
```

**Solution**: Add sequence numbers or timestamps
```python
class OrderedEventBus:
    def __init__(self):
        self.events = []
        self.sequence = 0

    def publish(self, event):
        event.data["sequence"] = self.sequence
        self.sequence += 1
        self.events.append(event)

        # Process in order
        self.events.sort(key=lambda e: e.data["sequence"])
        for e in self.events:
            self._process(e)
```

### 2. Lost Events

**Problem**: Subscriber not ready when event published

```python
# WRONG: Event published before subscriber registered
bus.publish(Event("important.event", {...}))
bus.subscribe("important.event", handler)  # Too late!
```

**Solution**: Use event sourcing with replay
```python
class EventStore:
    def __init__(self):
        self.events = []
        self.subscribers = {}

    def subscribe(self, event_type, handler, replay=True):
        """Subscribe and optionally replay past events"""
        if event_type not in self.subscribers:
            self.subscribers[event_type] = []
        self.subscribers[event_type].append(handler)

        if replay:
            # Replay past events of this type
            for event in self.events:
                if event.type == event_type:
                    handler(event)
```

### 3. Infinite Event Loops

**Problem**: Handler publishes event that triggers itself

```python
# WRONG: Creates infinite loop
@workflow.on_event("data.changed")
def on_data_changed(event):
    process_data(event.data)
    workflow.emit("data.changed", event.data)  # Infinite loop!
```

**Solution**: Add loop detection or use different event types
```python
class LoopDetectingEventBus:
    def __init__(self):
        self.event_stack = []

    def publish(self, event):
        event_key = (event.type, str(event.data))
        if event_key in self.event_stack:
            raise ValueError(f"Event loop detected: {event.type}")

        self.event_stack.append(event_key)
        try:
            self._notify_subscribers(event)
        finally:
            self.event_stack.pop()
```

### 4. Memory Leaks in Event Store

**Problem**: Event store grows unbounded

```python
# WRONG: Never clean up old events
class EventStore:
    def __init__(self):
        self.events = []  # Grows forever

    def publish(self, event):
        self.events.append(event)  # Memory leak
```

**Solution**: Implement retention policy
```python
class EventStore:
    def __init__(self, max_events=10000, max_age_days=30):
        self.events = []
        self.max_events = max_events
        self.max_age_days = max_age_days

    def publish(self, event):
        self.events.append(event)
        self._cleanup()

    def _cleanup(self):
        """Remove old or excess events"""
        # Remove by age
        cutoff = time.time() - (self.max_age_days * 86400)
        self.events = [e for e in self.events if e.timestamp > cutoff]

        # Remove by count
        if len(self.events) > self.max_events:
            self.events = self.events[-self.max_events:]
```

---

## Saga Gotchas

### 1. Non-Idempotent Compensations

**Problem**: Compensating action applied multiple times causes issues

```python
# WRONG: Refund called multiple times refunds multiple times
def refund_payment():
    charge_api.refund(payment_id)  # Called twice = double refund!
```

**Solution**: Make compensations idempotent
```python
def idempotent_refund():
    """Idempotent refund using status check"""
    payment = payment_api.get_payment(payment_id)
    if payment.status != "refunded":
        payment_api.refund(payment_id)
        payment.status = "refunded"
    else:
        print(f"Payment {payment_id} already refunded")
```

### 2. Wrong Compensation Order

**Problem**: Compensations executed in wrong order

```python
# WRONG: Compensate in forward order
saga.execute()  # Steps: A, B, C
# On failure: compensate A, B, C (WRONG)
```

**Solution**: Always compensate in reverse order
```python
class SagaOrchestrator:
    def execute(self):
        try:
            for step in self.steps:
                step.forward()
                self.executed_steps.append(step)
        except Exception:
            # Compensate in REVERSE order
            for step in reversed(self.executed_steps):
                step.compensate()
```

### 3. Compensation Failures

**Problem**: Compensation itself fails, leaving inconsistent state

```python
# WRONG: Compensation failure stops compensation chain
def compensate_step():
    raise Exception("Compensation failed!")  # Stops here
```

**Solution**: Log compensation failures but continue
```python
def execute_with_robust_compensation(self):
    """Execute with robust compensation"""
    try:
        for step in self.steps:
            step.forward()
            self.executed_steps.append(step)
    except Exception as forward_error:
        compensation_errors = []

        for step in reversed(self.executed_steps):
            try:
                step.compensate()
            except Exception as comp_error:
                # Log but continue compensating
                compensation_errors.append({
                    "step": step.name,
                    "error": str(comp_error)
                })
                print(f"Compensation failed for {step.name}: {comp_error}")

        if compensation_errors:
            # Alert ops team for manual intervention
            alert_ops_team(compensation_errors)
```

### 4. Long-Running Saga Timeouts

**Problem**: Saga times out before all steps complete

```python
# WRONG: No timeout handling
def long_running_step():
    time.sleep(3600)  # 1 hour, might timeout
```

**Solution**: Implement saga timeout and heartbeat
```python
class TimeoutAwareSaga:
    def __init__(self, timeout_seconds=300):
        self.timeout = timeout_seconds
        self.start_time = None

    def execute(self):
        self.start_time = time.time()

        for step in self.steps:
            # Check timeout before each step
            if time.time() - self.start_time > self.timeout:
                raise TimeoutError(f"Saga timeout after {self.timeout}s")

            step.forward()
```

---

## Error Handling Gotchas

### 1. Infinite Retry Loops

**Problem**: Retry logic never gives up

```python
# WRONG: Retries forever
while True:
    try:
        result = unreliable_operation()
        break
    except:
        time.sleep(1)  # Retry forever
```

**Solution**: Add max attempts and circuit breaker
```python
def retry_with_limit(func, max_attempts=3):
    """Retry with maximum attempts"""
    for attempt in range(max_attempts):
        try:
            return func()
        except Exception as e:
            if attempt == max_attempts - 1:
                raise
            time.sleep(2 ** attempt)  # Exponential backoff
```

### 2. Swallowing Exceptions

**Problem**: Catching all exceptions hides real issues

```python
# WRONG: Silently swallows all errors
try:
    critical_operation()
except:
    pass  # What went wrong?
```

**Solution**: Log exceptions and re-raise if critical
```python
try:
    critical_operation()
except Exception as e:
    logger.error(f"Operation failed: {e}", exc_info=True)
    metrics.increment("errors.critical_operation")
    # Decide whether to re-raise
    if is_critical_error(e):
        raise
```

### 3. Circuit Breaker Stuck Open

**Problem**: Circuit breaker never closes, permanently blocking requests

```python
# WRONG: No half-open state to test recovery
if self.state == CircuitState.OPEN:
    raise Exception("Circuit open")
```

**Solution**: Implement half-open state
```python
def call(self, func):
    if self.state == CircuitState.OPEN:
        if time.time() - self.last_failure > self.timeout:
            self.state = CircuitState.HALF_OPEN
            try:
                result = func()
                self.state = CircuitState.CLOSED
                return result
            except:
                self.state = CircuitState.OPEN
                raise
        else:
            raise Exception("Circuit open")
```

---

## Observability Gotchas

### 1. Missing Trace Context

**Problem**: Spans not properly linked, losing trace context

```python
# WRONG: Child spans don't reference parent
span1 = tracer.start_span("parent")
span2 = tracer.start_span("child")  # Not linked to parent
```

**Solution**: Always propagate trace context
```python
@contextmanager
def start_span(self, name):
    parent_id = self.current_span.span_id if self.current_span else None
    span = Span(name=name, parent_id=parent_id)

    previous = self.current_span
    self.current_span = span
    try:
        yield span
    finally:
        span.finish()
        self.current_span = previous
```

### 2. High Cardinality Metrics

**Problem**: Creating metrics with too many unique labels

```python
# WRONG: User ID in metric label creates millions of time series
metrics.increment(f"requests.user_{user_id}")
```

**Solution**: Use bounded cardinality
```python
# RIGHT: Use general labels
metrics.increment("requests.total", labels={"user_type": user_type})
```

### 3. Unstructured Logging

**Problem**: Logs are strings, hard to query

```python
# WRONG: Unstructured log
print(f"User {user_id} did {action} at {timestamp}")
```

**Solution**: Use structured logging
```python
# RIGHT: Structured log
logger.log("INFO", "user_action", user_id=user_id, action=action, timestamp=timestamp)
```

---

## Performance Gotchas

### 1. Blocking Event Handlers

**Problem**: Slow handler blocks entire event bus

```python
# WRONG: Slow handler blocks all events
@bus.on_event("data.process")
def slow_handler(event):
    time.sleep(10)  # Blocks other events
```

**Solution**: Process events asynchronously
```python
from concurrent.futures import ThreadPoolExecutor

class AsyncEventBus:
    def __init__(self):
        self.executor = ThreadPoolExecutor(max_workers=10)

    def publish(self, event):
        for handler in self.subscribers[event.type]:
            self.executor.submit(handler, event)
```

### 2. No Backpressure

**Problem**: Producer overwhelms consumer

```python
# WRONG: No rate limiting
while True:
    task = generate_task()
    workflow.submit(task)  # Unbounded queue growth
```

**Solution**: Implement backpressure
```python
class BackpressureQueue:
    def __init__(self, max_size=1000):
        self.queue = Queue(maxsize=max_size)

    def put(self, item):
        try:
            self.queue.put(item, timeout=5)
        except Full:
            raise Exception("Queue full, slow down producer")
```

### 3. Memory Leaks in Workflow State

**Problem**: Workflow state grows unbounded

```python
# WRONG: Never clean up completed workflows
workflow_states = {}  # Grows forever
```

**Solution**: Clean up old workflow state
```python
class WorkflowManager:
    def __init__(self, retention_hours=24):
        self.workflows = {}
        self.retention = retention_hours

    def cleanup_old_workflows(self):
        """Remove completed workflows older than retention period"""
        cutoff = time.time() - (self.retention * 3600)
        self.workflows = {
            wf_id: wf for wf_id, wf in self.workflows.items()
            if wf.completed_at is None or wf.completed_at > cutoff
        }
```

---

## Debugging Tips

### 1. Visualize Workflow

```python
def visualize_dag(workflow):
    """Generate DOT format for Graphviz"""
    print("digraph workflow {")
    for task_id, task in workflow.tasks.items():
        for dep in task.depends_on:
            print(f'  "{dep}" -> "{task_id}";')
    print("}")
```

### 2. Add Workflow Replay

```python
def replay_workflow(workflow, event_log):
    """Replay workflow from event log"""
    for event in event_log:
        print(f"Replaying: {event}")
        workflow.handle_event(event)
```

### 3. Use Workflow Debugger

```python
class WorkflowDebugger:
    def __init__(self):
        self.breakpoints = set()

    def set_breakpoint(self, task_id):
        self.breakpoints.add(task_id)

    def execute_with_debugging(self, workflow):
        for task_id in workflow.topological_sort():
            if task_id in self.breakpoints:
                print(f"Breakpoint at {task_id}")
                import pdb; pdb.set_trace()
            workflow.execute_task(task_id)
```
