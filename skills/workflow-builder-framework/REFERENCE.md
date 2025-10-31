# Workflow API Reference

Complete API documentation for workflow engines and patterns.

## Airflow DAG API

### DAG Definition

```python
from airflow import DAG
from datetime import datetime, timedelta

dag = DAG(
    dag_id='my_dag',                          # Unique identifier
    description='DAG description',            # Human-readable description
    schedule_interval='@daily',               # Cron or preset (@hourly, @daily, etc.)
    start_date=datetime(2025, 1, 1),          # First execution date
    end_date=datetime(2025, 12, 31),          # Optional end date
    catchup=False,                            # Whether to backfill past dates
    max_active_runs=1,                        # Max concurrent runs
    default_args={
        'owner': 'data-team',
        'retries': 3,
        'retry_delay': timedelta(minutes=5),
        'email': ['alerts@example.com'],
        'email_on_failure': True,
        'email_on_retry': False
    },
    tags=['production', 'data-pipeline']
)
```

### Operators

```python
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.operators.dummy import DummyOperator

# Python operator
python_task = PythonOperator(
    task_id='process_data',
    python_callable=my_function,
    op_args=[arg1, arg2],                     # Positional arguments
    op_kwargs={'key': 'value'},               # Keyword arguments
    provide_context=True,                     # Pass Airflow context
    dag=dag
)

# Bash operator
bash_task = BashOperator(
    task_id='run_script',
    bash_command='python /path/to/script.py',
    env={'ENV_VAR': 'value'},
    dag=dag
)

# Dummy operator (for structure)
dummy = DummyOperator(task_id='checkpoint', dag=dag)
```

### Dependencies

```python
# Method 1: Bitshift operators
task_a >> task_b >> task_c                    # A before B before C
task_a >> [task_b, task_c]                    # A before B and C (parallel)
[task_a, task_b] >> task_c                    # A and B before C

# Method 2: set_upstream / set_downstream
task_b.set_upstream(task_a)                   # Same as task_a >> task_b
task_c.set_downstream(task_b)                 # Same as task_b >> task_c

# Method 3: Cross products
tasks_a = [task_a1, task_a2]
tasks_b = [task_b1, task_b2]
tasks_a >> tasks_b                            # All A tasks before all B tasks
```

### XCom (Cross-Communication)

```python
def push_value(**context):
    """Push value to XCom"""
    context['ti'].xcom_push(key='my_key', value='my_value')
    # Or return value (automatically pushed with key 'return_value')
    return {'result': 42}

def pull_value(**context):
    """Pull value from XCom"""
    ti = context['ti']
    value = ti.xcom_pull(
        task_ids='push_task',
        key='my_key'
    )
    # Or pull return value
    result = ti.xcom_pull(task_ids='push_task', key='return_value')
```

### Branching

```python
from airflow.operators.python import BranchPythonOperator

def choose_branch(**context):
    """Decide which branch to take"""
    if condition:
        return 'task_a'
    else:
        return 'task_b'

branch = BranchPythonOperator(
    task_id='branch',
    python_callable=choose_branch,
    dag=dag
)

branch >> [task_a, task_b]
```

---

## Temporal Workflow API

### Workflow Definition

```python
from temporalio import workflow, activity
from datetime import timedelta

@workflow.defn
class MyWorkflow:
    @workflow.run
    async def run(self, input_data: str) -> str:
        """Main workflow logic"""
        # Execute activity
        result = await workflow.execute_activity(
            my_activity,
            input_data,
            start_to_close_timeout=timedelta(minutes=5),
            retry_policy={
                "maximum_attempts": 3,
                "initial_interval": timedelta(seconds=1),
                "maximum_interval": timedelta(seconds=10),
                "backoff_coefficient": 2.0
            }
        )
        return result
```

### Activity Definition

```python
@activity.defn
async def my_activity(input_data: str) -> str:
    """Activity implementation"""
    # Activity code here
    return f"Processed: {input_data}"
```

### Workflow Features

```python
@workflow.defn
class AdvancedWorkflow:
    def __init__(self):
        self.state = None
        self.signal_received = False

    @workflow.run
    async def run(self, data: str) -> str:
        # Timer
        await workflow.sleep(timedelta(hours=1))

        # Wait for signal
        await workflow.wait_condition(lambda: self.signal_received)

        # Child workflow
        result = await workflow.execute_child_workflow(
            ChildWorkflow.run,
            data,
            id='child-workflow-id'
        )

        # Query current state
        return result

    @workflow.signal
    async def update_signal(self, value: str):
        """Handle signal"""
        self.signal_received = True
        self.state = value

    @workflow.query
    def get_state(self) -> str:
        """Query workflow state"""
        return self.state
```

### Client Usage

```python
from temporalio.client import Client

# Connect to Temporal
client = await Client.connect("localhost:7233")

# Start workflow
handle = await client.start_workflow(
    MyWorkflow.run,
    "input_data",
    id="my-workflow-id",
    task_queue="my-task-queue"
)

# Send signal
await handle.signal(MyWorkflow.update_signal, "new_value")

# Query state
state = await handle.query(MyWorkflow.get_state)

# Wait for result
result = await handle.result()

# Cancel workflow
await handle.cancel()
```

---

## Prefect Flow API

### Flow Definition

```python
from prefect import flow, task
from prefect.task_runners import ConcurrentTaskRunner, DaskTaskRunner

@flow(
    name="my-flow",
    description="Flow description",
    task_runner=ConcurrentTaskRunner(),       # Concurrent execution
    retries=3,
    retry_delay_seconds=60,
    timeout_seconds=3600
)
def my_flow(param1: str, param2: int):
    """Main flow logic"""
    result1 = task1(param1)
    result2 = task2(param2)
    return combine_results(result1, result2)
```

### Task Definition

```python
@task(
    name="process-data",
    description="Process data task",
    retries=3,
    retry_delay_seconds=60,
    cache_key_fn=lambda *args, **kwargs: f"cache-{args[0]}",
    cache_expiration=timedelta(hours=1),
    timeout_seconds=300
)
def task1(data: str) -> str:
    """Task implementation"""
    return f"Processed: {data}"
```

### Task Mapping

```python
@flow
def parallel_flow(items: list):
    """Process items in parallel"""
    # Map task over items
    results = task1.map(items)

    # Submit tasks manually
    futures = [task1.submit(item) for item in items]
    results = [future.result() for future in futures]

    return results
```

### Subflows

```python
@flow
def subflow(data: str) -> str:
    return task1(data)

@flow
def parent_flow():
    # Call subflow
    result = subflow("data")
    return result
```

### Deployments

```python
from prefect.deployments import Deployment
from prefect.server.schemas.schedules import CronSchedule

deployment = Deployment.build_from_flow(
    flow=my_flow,
    name="my-deployment",
    schedule=CronSchedule(cron="0 0 * * *"),  # Daily at midnight
    work_queue_name="default",
    parameters={"param1": "value1", "param2": 42}
)

deployment.apply()
```

---

## Celery Task API

### Task Definition

```python
from celery import Celery

app = Celery('tasks', broker='redis://localhost:6379')

@app.task(
    bind=True,                                # Bind task instance as first arg
    name='process_data',                      # Task name
    max_retries=3,                            # Max retry attempts
    default_retry_delay=60,                   # Retry delay in seconds
    rate_limit='10/m',                        # Rate limit
    time_limit=300,                           # Hard time limit
    soft_time_limit=250,                      # Soft time limit
    acks_late=True,                           # Ack after task completes
    reject_on_worker_lost=True                # Reject if worker dies
)
def process_data(self, data):
    """Task implementation"""
    try:
        result = expensive_operation(data)
        return result
    except Exception as exc:
        # Retry with exponential backoff
        raise self.retry(exc=exc, countdown=2 ** self.request.retries)
```

### Task Execution

```python
# Execute asynchronously
result = process_data.delay(data)

# Execute with options
result = process_data.apply_async(
    args=[data],
    countdown=60,                             # Delay 60 seconds
    expires=3600,                             # Expire in 1 hour
    priority=5,                               # Priority (0-9)
    queue='high-priority'                     # Specific queue
)

# Execute synchronously (blocking)
result = process_data.apply(args=[data])

# Get result
value = result.get(timeout=10)
```

### Workflows (Canvas)

```python
from celery import chain, group, chord, chunks

# Sequential execution (chain)
workflow = chain(task1.s(arg1), task2.s(), task3.s())
result = workflow()

# Parallel execution (group)
job = group(task1.s(1), task1.s(2), task1.s(3))
result = job()

# Map-reduce (chord)
callback = task_aggregate.s()
header = group(task1.s(i) for i in range(10))
job = chord(header)(callback)

# Chunks
job = chunks(task1.s(), 100)                  # Process in chunks of 100
```

### Callbacks

```python
# Success callback
task1.apply_async(
    args=[data],
    link=task2.s(),                           # Call task2 on success
    link_error=error_handler.s()              # Call error_handler on failure
)
```

---

## State Machine Specifications

### JSON State Machine

```json
{
  "initial": "idle",
  "states": {
    "idle": {
      "on": {
        "START": "running"
      }
    },
    "running": {
      "on": {
        "PAUSE": "paused",
        "COMPLETE": "completed",
        "ERROR": "failed"
      }
    },
    "paused": {
      "on": {
        "RESUME": "running",
        "CANCEL": "idle"
      }
    },
    "completed": {
      "type": "final"
    },
    "failed": {
      "on": {
        "RETRY": "running"
      }
    }
  }
}
```

### XState (JavaScript)

```javascript
import { createMachine } from 'xstate';

const workflowMachine = createMachine({
  id: 'workflow',
  initial: 'idle',
  context: {
    data: null,
    error: null
  },
  states: {
    idle: {
      on: {
        START: {
          target: 'running',
          actions: 'initialize'
        }
      }
    },
    running: {
      invoke: {
        src: 'runWorkflow',
        onDone: {
          target: 'completed',
          actions: 'saveResult'
        },
        onError: {
          target: 'failed',
          actions: 'saveError'
        }
      }
    },
    completed: {
      type: 'final'
    },
    failed: {
      on: {
        RETRY: 'running'
      }
    }
  }
});
```

---

## Event Schema Definitions

### CloudEvents Standard

```json
{
  "specversion": "1.0",
  "type": "com.example.order.created",
  "source": "https://api.example.com/orders",
  "id": "A234-1234-1234",
  "time": "2025-10-27T10:30:00Z",
  "datacontenttype": "application/json",
  "data": {
    "order_id": "order-123",
    "customer_id": "cust-456",
    "amount": 99.99
  }
}
```

### Custom Event Schema

```python
from dataclasses import dataclass
from typing import Dict, Any
from datetime import datetime

@dataclass
class WorkflowEvent:
    """Standard workflow event"""
    event_type: str                           # Event type
    event_id: str                             # Unique event ID
    workflow_id: str                          # Workflow instance ID
    timestamp: datetime                       # Event timestamp
    data: Dict[str, Any]                      # Event payload
    metadata: Dict[str, Any]                  # Additional metadata

    def to_dict(self) -> dict:
        return {
            "event_type": self.event_type,
            "event_id": self.event_id,
            "workflow_id": self.workflow_id,
            "timestamp": self.timestamp.isoformat(),
            "data": self.data,
            "metadata": self.metadata
        }
```

---

## Saga Coordinator API

### Saga Definition

```python
from dataclasses import dataclass
from typing import Callable, List, Optional

@dataclass
class SagaStep:
    name: str
    forward: Callable                         # Forward action
    compensate: Callable                      # Compensation action
    timeout: Optional[int] = None             # Timeout in seconds

class SagaCoordinator:
    def __init__(self, saga_id: str):
        self.saga_id = saga_id
        self.steps: List[SagaStep] = []
        self.completed_steps: List[str] = []
        self.status = "pending"

    def add_step(self, step: SagaStep):
        """Add step to saga"""
        self.steps.append(step)

    def execute(self) -> dict:
        """Execute saga"""
        results = {}

        try:
            for step in self.steps:
                result = self._execute_step(step)
                results[step.name] = result
                self.completed_steps.append(step.name)

            self.status = "completed"
            return results

        except Exception as e:
            self.status = "compensating"
            self._compensate()
            self.status = "compensated"
            raise

    def _execute_step(self, step: SagaStep):
        """Execute single step with timeout"""
        if step.timeout:
            from concurrent.futures import TimeoutError
            import signal

            def timeout_handler(signum, frame):
                raise TimeoutError(f"Step {step.name} timeout")

            signal.signal(signal.SIGALRM, timeout_handler)
            signal.alarm(step.timeout)

            try:
                return step.forward()
            finally:
                signal.alarm(0)
        else:
            return step.forward()

    def _compensate(self):
        """Execute compensations in reverse order"""
        for step_name in reversed(self.completed_steps):
            step = next(s for s in self.steps if s.name == step_name)
            try:
                step.compensate()
            except Exception as e:
                # Log but continue compensating
                print(f"Compensation failed for {step_name}: {e}")
```

---

## Observability Hooks

### OpenTelemetry Integration

```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.jaeger import JaegerExporter

# Setup tracer
trace.set_tracer_provider(TracerProvider())
jaeger_exporter = JaegerExporter(
    agent_host_name="localhost",
    agent_port=6831
)
trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(jaeger_exporter)
)

tracer = trace.get_tracer(__name__)

# Use in workflow
def workflow_with_tracing():
    with tracer.start_as_current_span("workflow") as span:
        span.set_attribute("workflow.id", "wf-123")

        with tracer.start_as_current_span("task1") as child:
            child.set_attribute("task.name", "fetch_data")
            result = fetch_data()

        with tracer.start_as_current_span("task2") as child:
            child.set_attribute("task.name", "process_data")
            process_data(result)
```

### Prometheus Metrics

```python
from prometheus_client import Counter, Histogram, Gauge

# Define metrics
workflow_started = Counter(
    'workflow_started_total',
    'Total workflows started',
    ['workflow_name']
)

workflow_duration = Histogram(
    'workflow_duration_seconds',
    'Workflow duration',
    ['workflow_name']
)

workflow_active = Gauge(
    'workflow_active',
    'Currently active workflows',
    ['workflow_name']
)

# Use in workflow
class MetricsWorkflow:
    def execute(self):
        workflow_started.labels(workflow_name='my_workflow').inc()
        workflow_active.labels(workflow_name='my_workflow').inc()

        with workflow_duration.labels(workflow_name='my_workflow').time():
            # Execute workflow
            result = self._run()

        workflow_active.labels(workflow_name='my_workflow').dec()
        return result
```

---

## Performance Metrics

### Key Performance Indicators

```python
from dataclasses import dataclass
from typing import Dict

@dataclass
class WorkflowMetrics:
    """Standard workflow metrics"""
    # Throughput
    tasks_per_second: float                   # Task execution rate
    workflows_per_hour: float                 # Workflow completion rate

    # Latency
    p50_latency_ms: float                     # Median latency
    p95_latency_ms: float                     # 95th percentile latency
    p99_latency_ms: float                     # 99th percentile latency

    # Reliability
    success_rate: float                       # Successful workflows %
    error_rate: float                         # Failed workflows %
    retry_rate: float                         # Retried tasks %

    # Resource usage
    cpu_utilization: float                    # CPU usage %
    memory_usage_mb: float                    # Memory usage
    queue_depth: int                          # Pending tasks

    # Business metrics
    sla_compliance: float                     # SLA met %
    cost_per_workflow: float                  # Cost per execution
```

### Benchmarking

```python
import time
from contextlib import contextmanager

@contextmanager
def benchmark(name: str):
    """Benchmark code block"""
    start = time.time()
    yield
    duration = time.time() - start
    print(f"{name}: {duration*1000:.2f}ms")

# Usage
with benchmark("workflow_execution"):
    workflow.execute()
```
