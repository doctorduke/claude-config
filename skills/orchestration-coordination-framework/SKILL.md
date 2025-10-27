---
name: orchestration-coordination-framework
description: Production-scale multi-agent coordination, task orchestration, and workflow automation. Use for distributed system orchestration, agent communication protocols, DAG workflows, state machines, error handling, resource allocation, load balancing, and observability. Covers Apache Airflow, Temporal, Prefect, Celery, Step Functions, and orchestration patterns.
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, WebFetch]
---

# Orchestration Coordination Framework

## Purpose

Production-scale AI development requires sophisticated orchestration and coordination. This Skill provides comprehensive orchestration capabilities for:

1. **Multi-Agent Coordination** - Coordinate multiple AI agents working on complex tasks
2. **Task Decomposition** - Break down complex objectives into manageable subtasks
3. **Workflow Orchestration** - DAGs, state machines, event-driven patterns
4. **Communication Protocols** - Agent-to-agent messaging, pub/sub, queues
5. **Error Handling** - Retry logic, circuit breakers, fallback strategies
6. **Resource Management** - Load balancing, rate limiting, concurrency control
7. **Observability** - Monitoring, logging, tracing, metrics for distributed systems
8. **Framework Integration** - Apache Airflow, Temporal, Prefect, Celery, Step Functions

## When to Use This Skill

- Orchestrating multiple agents or services working together
- Complex multi-step workflows requiring coordination
- Distributed task execution with dependencies
- Event-driven architectures and reactive systems
- Building CI/CD pipelines with complex dependencies
- Microservices coordination and saga patterns
- Data pipeline orchestration (ETL/ELT)
- Long-running workflows with state management
- Fault-tolerant distributed systems
- Resource allocation across multiple workers
- Implementing retries and error recovery strategies
- Monitoring and observability for distributed systems

## Core Concepts

### Orchestration Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Orchestrator                       │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────┐ │
│  │ Task Queue  │  │ State Manager│  │ Scheduler │ │
│  └─────────────┘  └──────────────┘  └───────────┘ │
└──────────────┬──────────────────────────────────────┘
               │
       ┌───────┴───────┐
       │               │
   ┌───▼───┐       ┌───▼───┐       ┌────────┐
   │Agent 1│       │Agent 2│       │Agent N │
   │       │       │       │       │        │
   │Task A │       │Task B │       │Task N  │
   └───┬───┘       └───┬───┘       └───┬────┘
       │               │               │
       └───────┬───────┴───────────────┘
               │
         ┌─────▼─────┐
         │  Results  │
         │Aggregator │
         └───────────┘
```

### DAG (Directed Acyclic Graph) Pattern

```
Start
  │
  ├──► Task A ──┐
  │            │
  └──► Task B ──┼──► Task D ──► Task F ──► End
       │        │
       └──► Task C ──► Task E ───┘
```

Tasks execute based on dependencies, enabling parallel execution where possible.

### State Machine Pattern

```
     ┌─────────┐
     │  IDLE   │
     └────┬────┘
          │ start()
     ┌────▼────┐
     │ RUNNING │◄──────┐
     └────┬────┘       │
          │            │ retry()
    ┌─────┴─────┐      │
    │           │      │
┌───▼───┐   ┌───▼───┐  │
│SUCCESS│   │FAILURE├──┘
└───────┘   └───┬───┘
                │
                │ max_retries
            ┌───▼───┐
            │ ERROR │
            └───────┘
```

## Knowledge Resources

### Workflow Orchestration Frameworks

#### Apache Airflow
- [Apache Airflow Docs](https://airflow.apache.org/docs/) - Comprehensive workflow orchestration
- [Airflow Concepts](https://airflow.apache.org/docs/apache-airflow/stable/concepts/index.html) - DAGs, operators, sensors
- [Airflow Best Practices](https://airflow.apache.org/docs/apache-airflow/stable/best-practices.html) - Production patterns

**Key Features**:
- Python-based DAG definition
- Rich UI for monitoring
- Extensible with custom operators
- Schedule-based execution

#### Temporal
- [Temporal Docs](https://docs.temporal.io/) - Durable execution platform
- [Temporal Concepts](https://docs.temporal.io/concepts) - Workflows, activities, workers
- [Temporal Patterns](https://docs.temporal.io/dev-guide/patterns) - Common workflow patterns

**Key Features**:
- Durable execution (survives crashes)
- Long-running workflows (months/years)
- Automatic retries and timeouts
- Multi-language support

#### Prefect
- [Prefect Docs](https://docs.prefect.io/) - Modern workflow orchestration
- [Prefect Cloud](https://www.prefect.io/cloud) - Managed orchestration
- [Prefect Concepts](https://docs.prefect.io/latest/concepts/) - Flows, tasks, deployments

**Key Features**:
- Pythonic API
- Dynamic workflows
- Built-in observability
- Hybrid execution model

#### AWS Step Functions
- [Step Functions Docs](https://docs.aws.amazon.com/step-functions/) - Serverless orchestration
- [State Machine Language](https://states-language.net/) - JSON-based workflow definition
- [Step Functions Patterns](https://docs.aws.amazon.com/step-functions/latest/dg/concepts-patterns.html) - Common patterns

**Key Features**:
- Serverless (no infrastructure)
- Visual workflow designer
- AWS service integration
- Pay-per-use pricing

#### Celery
- [Celery Docs](https://docs.celeryq.dev/) - Distributed task queue
- [Celery Best Practices](https://docs.celeryq.dev/en/stable/userguide/tasks.html#best-practices) - Task patterns
- [Celery Monitoring](https://docs.celeryq.dev/en/stable/userguide/monitoring.html) - Flower, events

**Key Features**:
- Distributed task execution
- Multiple broker support (Redis, RabbitMQ)
- Flexible routing
- Real-time monitoring

### Communication Patterns

- [Message Queue Patterns](https://www.enterpriseintegrationpatterns.com/patterns/messaging/) - Enterprise integration
- [Pub/Sub Pattern](https://cloud.google.com/pubsub/docs/overview) - Google Cloud Pub/Sub concepts
- [Event-Driven Architecture](https://aws.amazon.com/event-driven-architecture/) - AWS event patterns
- [CQRS Pattern](https://martinfowler.com/bliki/CQRS.html) - Command Query Responsibility Segregation

### Distributed Systems

- [Patterns of Distributed Systems](https://martinfowler.com/articles/patterns-of-distributed-systems/) - Martin Fowler
- [Microservices Patterns](https://microservices.io/patterns/) - Common patterns
- [Saga Pattern](https://microservices.io/patterns/data/saga.html) - Distributed transactions
- [Circuit Breaker Pattern](https://martinfowler.com/bliki/CircuitBreaker.html) - Fault tolerance

## Common Orchestration Gotchas

1. **Task Dependency Hell** - Complex DAGs become unmaintainable
   - **Solution**: Group related tasks, use dynamic task generation, limit DAG depth to 3-4 levels

2. **State Management Complexity** - Losing track of workflow state across restarts
   - **Solution**: Use durable execution platforms (Temporal), persist state externally, idempotent tasks

3. **Retry Storms** - Failed tasks retry simultaneously, overwhelming systems
   - **Solution**: Exponential backoff, jitter, circuit breakers, max retry limits

4. **Resource Starvation** - High-priority tasks blocked by low-priority tasks
   - **Solution**: Priority queues, separate worker pools, resource quotas

5. **Zombie Workflows** - Workflows stuck in limbo, never completing
   - **Solution**: Timeouts at every level, health checks, automatic cleanup, dead letter queues

6. **Serialization Issues** - Large data passed between tasks causes memory issues
   - **Solution**: Pass references (S3 URLs) not data, use streaming, implement chunking

7. **Distributed Deadlocks** - Tasks waiting for each other in circular dependency
   - **Solution**: DAG validation, timeout on locks, detect cycles before execution

8. **Observability Blind Spots** - Can't debug distributed failures
   - **Solution**: Distributed tracing (OpenTelemetry), structured logging, correlation IDs

9. **Clock Skew Issues** - Different servers have different times, causing ordering issues
   - **Solution**: Use logical clocks (Lamport timestamps), NTP sync, UTC everywhere

10. **Error Propagation** - Errors don't bubble up correctly in distributed systems
    - **Solution**: Explicit error handling at every layer, error aggregation, circuit breakers

## Implementation Patterns

### Pattern 1: Multi-Agent Task Decomposition

Decompose complex tasks and distribute to specialized agents:

```python
from dataclasses import dataclass
from typing import List, Dict, Any, Optional
from enum import Enum
import asyncio
from datetime import datetime

class TaskStatus(Enum):
    PENDING = "pending"
    ASSIGNED = "assigned"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    FAILED = "failed"

@dataclass
class Task:
    id: str
    name: str
    description: str
    agent_type: str
    dependencies: List[str]
    status: TaskStatus
    result: Optional[Any] = None
    error: Optional[str] = None
    retries: int = 0
    max_retries: int = 3

@dataclass
class Agent:
    id: str
    type: str
    capabilities: List[str]
    max_concurrent_tasks: int
    current_tasks: int = 0

class TaskDecomposer:
    """Decompose complex objectives into agent-specific tasks"""

    def decompose(self, objective: str, context: Dict[str, Any]) -> List[Task]:
        """Break down objective into executable tasks with dependencies"""

        # Example: Code review objective
        if "code review" in objective.lower():
            return [
                Task(
                    id="task_1",
                    name="syntax_analysis",
                    description="Check syntax and formatting",
                    agent_type="linter",
                    dependencies=[],
                    status=TaskStatus.PENDING
                ),
                Task(
                    id="task_2",
                    name="security_scan",
                    description="Scan for security vulnerabilities",
                    agent_type="security",
                    dependencies=[],
                    status=TaskStatus.PENDING
                ),
                Task(
                    id="task_3",
                    name="logic_analysis",
                    description="Analyze code logic and patterns",
                    agent_type="analyzer",
                    dependencies=["task_1"],
                    status=TaskStatus.PENDING
                ),
                Task(
                    id="task_4",
                    name="test_coverage",
                    description="Check test coverage",
                    agent_type="tester",
                    dependencies=["task_3"],
                    status=TaskStatus.PENDING
                ),
                Task(
                    id="task_5",
                    name="generate_report",
                    description="Aggregate results and generate report",
                    agent_type="reporter",
                    dependencies=["task_1", "task_2", "task_3", "task_4"],
                    status=TaskStatus.PENDING
                )
            ]

        # Add more objective patterns...
        return []

class Orchestrator:
    """Coordinate task execution across multiple agents"""

    def __init__(self):
        self.tasks: Dict[str, Task] = {}
        self.agents: Dict[str, Agent] = {}
        self.task_queue: asyncio.Queue = asyncio.Queue()

    def register_agent(self, agent: Agent):
        """Register an agent with the orchestrator"""
        self.agents[agent.id] = agent
        print(f"Registered agent: {agent.id} (type: {agent.type})")

    async def execute_workflow(self, tasks: List[Task]) -> Dict[str, Any]:
        """Execute workflow with dependency resolution"""

        # Index tasks
        for task in tasks:
            self.tasks[task.id] = task

        # Validate DAG (no cycles)
        if self._has_cycle(tasks):
            raise ValueError("Workflow contains circular dependencies")

        # Execute tasks respecting dependencies
        completed_tasks = set()

        while len(completed_tasks) < len(tasks):
            # Find ready tasks (dependencies met)
            ready_tasks = [
                task for task in tasks
                if task.status == TaskStatus.PENDING
                and all(dep in completed_tasks for dep in task.dependencies)
            ]

            if not ready_tasks:
                # Check for failures or stuck tasks
                failed = [t for t in tasks if t.status == TaskStatus.FAILED]
                if failed:
                    raise Exception(f"Tasks failed: {[t.id for t in failed]}")

                # Wait for in-progress tasks
                await asyncio.sleep(0.1)
                continue

            # Execute ready tasks in parallel
            results = await asyncio.gather(
                *[self._execute_task(task) for task in ready_tasks],
                return_exceptions=True
            )

            # Update completed tasks
            for task in ready_tasks:
                if task.status == TaskStatus.COMPLETED:
                    completed_tasks.add(task.id)

        # Aggregate results
        return {
            "status": "completed",
            "tasks": {t.id: t.result for t in tasks if t.result},
            "errors": {t.id: t.error for t in tasks if t.error}
        }

    async def _execute_task(self, task: Task) -> Any:
        """Execute a single task on appropriate agent"""

        # Find available agent
        agent = self._find_agent(task.agent_type)
        if not agent:
            task.status = TaskStatus.FAILED
            task.error = f"No agent available for type: {task.agent_type}"
            return None

        # Check agent capacity
        if agent.current_tasks >= agent.max_concurrent_tasks:
            await asyncio.sleep(0.5)
            return await self._execute_task(task)

        # Assign and execute
        task.status = TaskStatus.IN_PROGRESS
        agent.current_tasks += 1

        try:
            print(f"Executing {task.id} on agent {agent.id}")

            # Simulate task execution (replace with actual agent call)
            await asyncio.sleep(1)
            result = f"Result of {task.name}"

            task.status = TaskStatus.COMPLETED
            task.result = result
            return result

        except Exception as e:
            task.retries += 1

            if task.retries < task.max_retries:
                print(f"Task {task.id} failed, retry {task.retries}/{task.max_retries}")
                task.status = TaskStatus.PENDING
                await asyncio.sleep(2 ** task.retries)  # Exponential backoff
                return await self._execute_task(task)
            else:
                task.status = TaskStatus.FAILED
                task.error = str(e)
                raise

        finally:
            agent.current_tasks -= 1

    def _find_agent(self, agent_type: str) -> Optional[Agent]:
        """Find available agent of specified type"""
        for agent in self.agents.values():
            if agent.type == agent_type and agent.current_tasks < agent.max_concurrent_tasks:
                return agent
        return None

    def _has_cycle(self, tasks: List[Task]) -> bool:
        """Detect circular dependencies using DFS"""
        visited = set()
        rec_stack = set()

        def dfs(task_id: str) -> bool:
            visited.add(task_id)
            rec_stack.add(task_id)

            task = next((t for t in tasks if t.id == task_id), None)
            if task:
                for dep_id in task.dependencies:
                    if dep_id not in visited:
                        if dfs(dep_id):
                            return True
                    elif dep_id in rec_stack:
                        return True

            rec_stack.remove(task_id)
            return False

        for task in tasks:
            if task.id not in visited:
                if dfs(task.id):
                    return True

        return False

# Usage
async def main():
    decomposer = TaskDecomposer()
    orchestrator = Orchestrator()

    # Register agents
    orchestrator.register_agent(Agent("agent_1", "linter", ["syntax"], 2))
    orchestrator.register_agent(Agent("agent_2", "security", ["scan"], 2))
    orchestrator.register_agent(Agent("agent_3", "analyzer", ["analysis"], 1))
    orchestrator.register_agent(Agent("agent_4", "tester", ["testing"], 1))
    orchestrator.register_agent(Agent("agent_5", "reporter", ["reporting"], 1))

    # Decompose objective
    tasks = decomposer.decompose("Perform code review", {})

    # Execute workflow
    results = await orchestrator.execute_workflow(tasks)
    print(f"Workflow completed: {results}")

if __name__ == "__main__":
    asyncio.run(main())
```

### Pattern 2: Airflow DAG for Agent Coordination

Orchestrate AI agents using Apache Airflow:

```python
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.utils.dates import days_ago
from airflow.models import Variable
from datetime import timedelta
import json

default_args = {
    'owner': 'ai-orchestrator',
    'depends_on_past': False,
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 3,
    'retry_delay': timedelta(minutes=2),
    'retry_exponential_backoff': True,
    'max_retry_delay': timedelta(minutes=10),
}

def call_agent(agent_name: str, task_data: dict) -> dict:
    """Call an AI agent with task data"""
    import requests

    agent_endpoint = Variable.get(f"{agent_name}_endpoint")

    response = requests.post(
        agent_endpoint,
        json=task_data,
        timeout=300
    )
    response.raise_for_status()

    return response.json()

def code_analysis_agent(**context):
    """Agent 1: Analyze code structure"""
    repo_url = context['dag_run'].conf.get('repo_url')

    result = call_agent('code_analyzer', {
        'repo_url': repo_url,
        'analysis_type': 'structure'
    })

    # Push result to XCom for downstream tasks
    context['ti'].xcom_push(key='code_analysis', value=result)
    return result

def security_scan_agent(**context):
    """Agent 2: Security vulnerability scan"""
    repo_url = context['dag_run'].conf.get('repo_url')

    result = call_agent('security_scanner', {
        'repo_url': repo_url,
        'scan_types': ['sast', 'dependency']
    })

    context['ti'].xcom_push(key='security_scan', value=result)
    return result

def test_coverage_agent(**context):
    """Agent 3: Test coverage analysis"""
    repo_url = context['dag_run'].conf.get('repo_url')

    # Get code analysis results from upstream
    code_analysis = context['ti'].xcom_pull(
        task_ids='code_analysis_task',
        key='code_analysis'
    )

    result = call_agent('test_analyzer', {
        'repo_url': repo_url,
        'code_analysis': code_analysis
    })

    context['ti'].xcom_push(key='test_coverage', value=result)
    return result

def documentation_agent(**context):
    """Agent 4: Generate documentation"""
    code_analysis = context['ti'].xcom_pull(
        task_ids='code_analysis_task',
        key='code_analysis'
    )

    result = call_agent('doc_generator', {
        'code_analysis': code_analysis,
        'format': 'markdown'
    })

    context['ti'].xcom_push(key='documentation', value=result)
    return result

def aggregation_agent(**context):
    """Agent 5: Aggregate all results"""

    # Pull all results from XCom
    code_analysis = context['ti'].xcom_pull(
        task_ids='code_analysis_task',
        key='code_analysis'
    )
    security_scan = context['ti'].xcom_pull(
        task_ids='security_scan_task',
        key='security_scan'
    )
    test_coverage = context['ti'].xcom_pull(
        task_ids='test_coverage_task',
        key='test_coverage'
    )
    documentation = context['ti'].xcom_pull(
        task_ids='documentation_task',
        key='documentation'
    )

    # Aggregate results
    final_report = {
        'code_quality': code_analysis.get('quality_score'),
        'security_issues': security_scan.get('issues', []),
        'test_coverage': test_coverage.get('coverage_percentage'),
        'documentation': documentation.get('url'),
        'timestamp': context['ts']
    }

    # Store in database or send to notification service
    result = call_agent('report_generator', final_report)

    print(f"Final Report: {json.dumps(final_report, indent=2)}")
    return final_report

# Define DAG
with DAG(
    'ai_agent_coordination',
    default_args=default_args,
    description='Coordinate multiple AI agents for code analysis',
    schedule_interval='@daily',
    start_date=days_ago(1),
    catchup=False,
    tags=['ai', 'orchestration', 'agents'],
) as dag:

    # Task 1: Code analysis (independent)
    code_analysis_task = PythonOperator(
        task_id='code_analysis_task',
        python_callable=code_analysis_agent,
        provide_context=True,
    )

    # Task 2: Security scan (independent)
    security_scan_task = PythonOperator(
        task_id='security_scan_task',
        python_callable=security_scan_agent,
        provide_context=True,
    )

    # Task 3: Test coverage (depends on code analysis)
    test_coverage_task = PythonOperator(
        task_id='test_coverage_task',
        python_callable=test_coverage_agent,
        provide_context=True,
    )

    # Task 4: Documentation (depends on code analysis)
    documentation_task = PythonOperator(
        task_id='documentation_task',
        python_callable=documentation_agent,
        provide_context=True,
    )

    # Task 5: Aggregation (depends on all)
    aggregation_task = PythonOperator(
        task_id='aggregation_task',
        python_callable=aggregation_agent,
        provide_context=True,
    )

    # Define dependencies
    code_analysis_task >> [test_coverage_task, documentation_task]
    [code_analysis_task, security_scan_task, test_coverage_task, documentation_task] >> aggregation_task
```

### Pattern 3: Temporal Workflow for Durable Agent Execution

Long-running agent workflows with Temporal:

```python
from temporalio import workflow, activity
from temporalio.client import Client
from temporalio.worker import Worker
from datetime import timedelta
from dataclasses import dataclass
from typing import List
import asyncio

@dataclass
class AgentTask:
    task_id: str
    agent_type: str
    input_data: dict
    timeout: int = 300

@dataclass
class AgentResult:
    task_id: str
    status: str
    output: dict
    error: str = None

# Activities (actual agent calls)
@activity.defn
async def call_code_analyzer(task: AgentTask) -> AgentResult:
    """Activity: Call code analyzer agent"""
    try:
        # Simulate agent call
        await asyncio.sleep(2)

        return AgentResult(
            task_id=task.task_id,
            status="completed",
            output={
                "complexity": 45,
                "maintainability": 82,
                "issues": []
            }
        )
    except Exception as e:
        return AgentResult(
            task_id=task.task_id,
            status="failed",
            output={},
            error=str(e)
        )

@activity.defn
async def call_security_scanner(task: AgentTask) -> AgentResult:
    """Activity: Call security scanner agent"""
    try:
        await asyncio.sleep(3)

        return AgentResult(
            task_id=task.task_id,
            status="completed",
            output={
                "vulnerabilities": 2,
                "severity": "medium"
            }
        )
    except Exception as e:
        return AgentResult(
            task_id=task.task_id,
            status="failed",
            output={},
            error=str(e)
        )

@activity.defn
async def call_report_generator(tasks: List[AgentResult]) -> AgentResult:
    """Activity: Generate final report"""
    try:
        await asyncio.sleep(1)

        # Aggregate results
        report = {
            "summary": f"Processed {len(tasks)} tasks",
            "details": [t.output for t in tasks]
        }

        return AgentResult(
            task_id="report",
            status="completed",
            output=report
        )
    except Exception as e:
        return AgentResult(
            task_id="report",
            status="failed",
            output={},
            error=str(e)
        )

# Workflow definition
@workflow.defn
class AgentOrchestrationWorkflow:
    """Temporal workflow for orchestrating agents"""

    @workflow.run
    async def run(self, repo_url: str) -> dict:
        """Execute multi-agent workflow"""

        workflow.logger.info(f"Starting workflow for repo: {repo_url}")

        # Phase 1: Parallel analysis tasks
        analysis_tasks = [
            AgentTask(
                task_id="code_analysis",
                agent_type="analyzer",
                input_data={"repo_url": repo_url}
            ),
            AgentTask(
                task_id="security_scan",
                agent_type="security",
                input_data={"repo_url": repo_url}
            )
        ]

        # Execute in parallel with retries
        results = await asyncio.gather(
            workflow.execute_activity(
                call_code_analyzer,
                analysis_tasks[0],
                start_to_close_timeout=timedelta(seconds=300),
                retry_policy={
                    "maximum_attempts": 3,
                    "initial_interval": timedelta(seconds=1),
                    "backoff_coefficient": 2.0,
                    "maximum_interval": timedelta(seconds=30),
                }
            ),
            workflow.execute_activity(
                call_security_scanner,
                analysis_tasks[1],
                start_to_close_timeout=timedelta(seconds=300),
                retry_policy={
                    "maximum_attempts": 3,
                    "initial_interval": timedelta(seconds=1),
                    "backoff_coefficient": 2.0,
                }
            )
        )

        # Check for failures
        failed = [r for r in results if r.status == "failed"]
        if failed:
            workflow.logger.error(f"Tasks failed: {[r.task_id for r in failed]}")
            raise Exception(f"Workflow failed with {len(failed)} task failures")

        # Phase 2: Generate report
        report_result = await workflow.execute_activity(
            call_report_generator,
            results,
            start_to_close_timeout=timedelta(seconds=60)
        )

        # Phase 3: Send notification (optional)
        if report_result.status == "completed":
            # Could send notification here
            workflow.logger.info("Workflow completed successfully")

        return report_result.output

# Worker setup
async def run_worker():
    """Run Temporal worker"""
    client = await Client.connect("localhost:7233")

    worker = Worker(
        client,
        task_queue="agent-orchestration",
        workflows=[AgentOrchestrationWorkflow],
        activities=[call_code_analyzer, call_security_scanner, call_report_generator]
    )

    await worker.run()

# Client to start workflow
async def start_workflow(repo_url: str):
    """Start a new workflow execution"""
    client = await Client.connect("localhost:7233")

    result = await client.execute_workflow(
        AgentOrchestrationWorkflow.run,
        repo_url,
        id=f"agent-workflow-{repo_url}",
        task_queue="agent-orchestration",
    )

    return result

# Usage
if __name__ == "__main__":
    # Run worker: python script.py worker
    # Start workflow: python script.py start https://github.com/user/repo
    import sys

    if sys.argv[1] == "worker":
        asyncio.run(run_worker())
    elif sys.argv[1] == "start":
        result = asyncio.run(start_workflow(sys.argv[2]))
        print(f"Workflow result: {result}")
```

### Pattern 4: Event-Driven Coordination with Pub/Sub

Message-based agent coordination:

```python
import asyncio
import json
from typing import Dict, Callable, List
from dataclasses import dataclass, asdict
from datetime import datetime
from enum import Enum
import redis.asyncio as redis

class EventType(Enum):
    TASK_CREATED = "task.created"
    TASK_ASSIGNED = "task.assigned"
    TASK_COMPLETED = "task.completed"
    TASK_FAILED = "task.failed"
    AGENT_REGISTERED = "agent.registered"
    AGENT_HEARTBEAT = "agent.heartbeat"

@dataclass
class Event:
    type: EventType
    data: dict
    timestamp: str
    correlation_id: str

class EventBus:
    """Redis-based event bus for agent communication"""

    def __init__(self, redis_url: str = "redis://localhost"):
        self.redis_url = redis_url
        self.redis_client = None
        self.handlers: Dict[EventType, List[Callable]] = {}

    async def connect(self):
        """Connect to Redis"""
        self.redis_client = await redis.from_url(
            self.redis_url,
            encoding="utf-8",
            decode_responses=True
        )

    async def publish(self, event: Event):
        """Publish event to all subscribers"""
        if not self.redis_client:
            await self.connect()

        channel = f"events:{event.type.value}"
        message = json.dumps(asdict(event))

        await self.redis_client.publish(channel, message)
        print(f"Published event: {event.type.value}")

    async def subscribe(self, event_type: EventType, handler: Callable):
        """Subscribe to event type"""
        if event_type not in self.handlers:
            self.handlers[event_type] = []

        self.handlers[event_type].append(handler)

    async def start_listening(self):
        """Start listening for events"""
        if not self.redis_client:
            await self.connect()

        pubsub = self.redis_client.pubsub()

        # Subscribe to all registered event types
        channels = [f"events:{et.value}" for et in self.handlers.keys()]
        await pubsub.subscribe(*channels)

        print(f"Listening on channels: {channels}")

        async for message in pubsub.listen():
            if message['type'] == 'message':
                await self._handle_message(message)

    async def _handle_message(self, message: dict):
        """Handle received message"""
        try:
            event_data = json.loads(message['data'])
            event_type = EventType(event_data['type'])

            # Call all handlers for this event type
            if event_type in self.handlers:
                for handler in self.handlers[event_type]:
                    await handler(event_data)

        except Exception as e:
            print(f"Error handling message: {e}")

class EventDrivenAgent:
    """Agent that communicates via events"""

    def __init__(self, agent_id: str, agent_type: str, event_bus: EventBus):
        self.agent_id = agent_id
        self.agent_type = agent_type
        self.event_bus = event_bus
        self.current_task = None

    async def start(self):
        """Start agent and register with orchestrator"""
        # Subscribe to task events
        await self.event_bus.subscribe(EventType.TASK_CREATED, self.on_task_created)

        # Publish registration event
        await self.event_bus.publish(Event(
            type=EventType.AGENT_REGISTERED,
            data={
                "agent_id": self.agent_id,
                "agent_type": self.agent_type,
                "capabilities": self.get_capabilities()
            },
            timestamp=datetime.utcnow().isoformat(),
            correlation_id=self.agent_id
        ))

        print(f"Agent {self.agent_id} started")

    async def on_task_created(self, event_data: dict):
        """Handle task creation event"""
        task_data = event_data['data']

        # Check if task is for this agent type
        if task_data.get('agent_type') != self.agent_type:
            return

        # Check if agent is available
        if self.current_task:
            print(f"Agent {self.agent_id} busy, skipping task")
            return

        # Assign task
        task_id = task_data['task_id']
        self.current_task = task_id

        await self.event_bus.publish(Event(
            type=EventType.TASK_ASSIGNED,
            data={
                "task_id": task_id,
                "agent_id": self.agent_id
            },
            timestamp=datetime.utcnow().isoformat(),
            correlation_id=task_id
        ))

        # Execute task
        await self.execute_task(task_data)

    async def execute_task(self, task_data: dict):
        """Execute assigned task"""
        task_id = task_data['task_id']

        try:
            print(f"Agent {self.agent_id} executing task {task_id}")

            # Simulate task execution
            await asyncio.sleep(2)
            result = {"status": "success", "output": "Task completed"}

            # Publish completion event
            await self.event_bus.publish(Event(
                type=EventType.TASK_COMPLETED,
                data={
                    "task_id": task_id,
                    "agent_id": self.agent_id,
                    "result": result
                },
                timestamp=datetime.utcnow().isoformat(),
                correlation_id=task_id
            ))

        except Exception as e:
            # Publish failure event
            await self.event_bus.publish(Event(
                type=EventType.TASK_FAILED,
                data={
                    "task_id": task_id,
                    "agent_id": self.agent_id,
                    "error": str(e)
                },
                timestamp=datetime.utcnow().isoformat(),
                correlation_id=task_id
            ))

        finally:
            self.current_task = None

    def get_capabilities(self) -> List[str]:
        """Return agent capabilities"""
        return [self.agent_type]

class EventDrivenOrchestrator:
    """Orchestrator using event-driven coordination"""

    def __init__(self, event_bus: EventBus):
        self.event_bus = event_bus
        self.agents = {}
        self.tasks = {}

    async def start(self):
        """Start orchestrator"""
        await self.event_bus.subscribe(EventType.AGENT_REGISTERED, self.on_agent_registered)
        await self.event_bus.subscribe(EventType.TASK_COMPLETED, self.on_task_completed)
        await self.event_bus.subscribe(EventType.TASK_FAILED, self.on_task_failed)

        print("Orchestrator started")

    async def on_agent_registered(self, event_data: dict):
        """Handle agent registration"""
        agent_data = event_data['data']
        agent_id = agent_data['agent_id']

        self.agents[agent_id] = agent_data
        print(f"Registered agent: {agent_id} (type: {agent_data['agent_type']})")

    async def on_task_completed(self, event_data: dict):
        """Handle task completion"""
        task_data = event_data['data']
        task_id = task_data['task_id']

        if task_id in self.tasks:
            self.tasks[task_id]['status'] = 'completed'
            self.tasks[task_id]['result'] = task_data['result']
            print(f"Task {task_id} completed by {task_data['agent_id']}")

    async def on_task_failed(self, event_data: dict):
        """Handle task failure"""
        task_data = event_data['data']
        task_id = task_data['task_id']

        if task_id in self.tasks:
            self.tasks[task_id]['status'] = 'failed'
            self.tasks[task_id]['error'] = task_data['error']
            print(f"Task {task_id} failed: {task_data['error']}")

    async def submit_task(self, task_id: str, agent_type: str, task_data: dict):
        """Submit task for execution"""
        self.tasks[task_id] = {
            'status': 'created',
            'agent_type': agent_type,
            'data': task_data
        }

        # Publish task creation event
        await self.event_bus.publish(Event(
            type=EventType.TASK_CREATED,
            data={
                "task_id": task_id,
                "agent_type": agent_type,
                **task_data
            },
            timestamp=datetime.utcnow().isoformat(),
            correlation_id=task_id
        ))

# Usage
async def main():
    # Create event bus
    event_bus = EventBus("redis://localhost")
    await event_bus.connect()

    # Create orchestrator
    orchestrator = EventDrivenOrchestrator(event_bus)
    await orchestrator.start()

    # Create agents
    agent1 = EventDrivenAgent("agent_1", "analyzer", event_bus)
    agent2 = EventDrivenAgent("agent_2", "analyzer", event_bus)
    agent3 = EventDrivenAgent("agent_3", "security", event_bus)

    await agent1.start()
    await agent2.start()
    await agent3.start()

    # Start event listeners
    asyncio.create_task(event_bus.start_listening())

    # Submit tasks
    await orchestrator.submit_task("task_1", "analyzer", {"repo": "repo1"})
    await orchestrator.submit_task("task_2", "analyzer", {"repo": "repo2"})
    await orchestrator.submit_task("task_3", "security", {"repo": "repo3"})

    # Keep running
    await asyncio.sleep(10)

    print(f"Final task status: {orchestrator.tasks}")

if __name__ == "__main__":
    asyncio.run(main())
```

### Pattern 5: Circuit Breaker for Fault Tolerance

Prevent cascading failures in distributed agent systems:

```python
from enum import Enum
from typing import Callable, Any
from datetime import datetime, timedelta
import asyncio
from dataclasses import dataclass

class CircuitState(Enum):
    CLOSED = "closed"      # Normal operation
    OPEN = "open"          # Failing, reject requests
    HALF_OPEN = "half_open"  # Testing recovery

@dataclass
class CircuitBreakerConfig:
    failure_threshold: int = 5
    success_threshold: int = 2
    timeout: int = 60  # seconds
    half_open_max_calls: int = 3

class CircuitBreaker:
    """Circuit breaker pattern for agent calls"""

    def __init__(self, name: str, config: CircuitBreakerConfig = None):
        self.name = name
        self.config = config or CircuitBreakerConfig()
        self.state = CircuitState.CLOSED
        self.failure_count = 0
        self.success_count = 0
        self.last_failure_time = None
        self.half_open_calls = 0

    async def call(self, func: Callable, *args, **kwargs) -> Any:
        """Execute function with circuit breaker protection"""

        # Check circuit state
        if self.state == CircuitState.OPEN:
            # Check if timeout elapsed
            if self._should_attempt_reset():
                self.state = CircuitState.HALF_OPEN
                self.half_open_calls = 0
                print(f"Circuit breaker {self.name}: OPEN -> HALF_OPEN")
            else:
                raise Exception(f"Circuit breaker {self.name} is OPEN")

        # Limit calls in HALF_OPEN state
        if self.state == CircuitState.HALF_OPEN:
            if self.half_open_calls >= self.config.half_open_max_calls:
                raise Exception(f"Circuit breaker {self.name} HALF_OPEN call limit reached")
            self.half_open_calls += 1

        try:
            # Execute function
            result = await func(*args, **kwargs)

            # Record success
            self._on_success()

            return result

        except Exception as e:
            # Record failure
            self._on_failure()
            raise

    def _on_success(self):
        """Handle successful call"""
        if self.state == CircuitState.HALF_OPEN:
            self.success_count += 1

            if self.success_count >= self.config.success_threshold:
                self.state = CircuitState.CLOSED
                self.failure_count = 0
                self.success_count = 0
                print(f"Circuit breaker {self.name}: HALF_OPEN -> CLOSED")

        elif self.state == CircuitState.CLOSED:
            # Reset failure count on success
            self.failure_count = 0

    def _on_failure(self):
        """Handle failed call"""
        self.failure_count += 1
        self.last_failure_time = datetime.now()

        if self.state == CircuitState.HALF_OPEN:
            # Failed during recovery, back to OPEN
            self.state = CircuitState.OPEN
            self.success_count = 0
            print(f"Circuit breaker {self.name}: HALF_OPEN -> OPEN")

        elif self.state == CircuitState.CLOSED:
            if self.failure_count >= self.config.failure_threshold:
                self.state = CircuitState.OPEN
                print(f"Circuit breaker {self.name}: CLOSED -> OPEN")

    def _should_attempt_reset(self) -> bool:
        """Check if enough time has passed to attempt reset"""
        if not self.last_failure_time:
            return True

        elapsed = (datetime.now() - self.last_failure_time).total_seconds()
        return elapsed >= self.config.timeout

    def get_state(self) -> dict:
        """Get current circuit breaker state"""
        return {
            "name": self.name,
            "state": self.state.value,
            "failure_count": self.failure_count,
            "success_count": self.success_count
        }

class ResilientAgentCaller:
    """Agent caller with circuit breaker and retries"""

    def __init__(self):
        self.circuit_breakers: dict[str, CircuitBreaker] = {}

    async def call_agent(
        self,
        agent_name: str,
        func: Callable,
        *args,
        max_retries: int = 3,
        retry_delay: int = 1,
        **kwargs
    ) -> Any:
        """Call agent with circuit breaker and retry logic"""

        # Get or create circuit breaker
        if agent_name not in self.circuit_breakers:
            self.circuit_breakers[agent_name] = CircuitBreaker(agent_name)

        circuit_breaker = self.circuit_breakers[agent_name]

        # Retry logic with exponential backoff
        last_exception = None

        for attempt in range(max_retries):
            try:
                result = await circuit_breaker.call(func, *args, **kwargs)
                return result

            except Exception as e:
                last_exception = e

                # Don't retry if circuit breaker is open
                if circuit_breaker.state == CircuitState.OPEN:
                    print(f"Agent {agent_name} circuit breaker OPEN, not retrying")
                    break

                if attempt < max_retries - 1:
                    wait_time = retry_delay * (2 ** attempt)  # Exponential backoff
                    print(f"Agent {agent_name} call failed, retry {attempt + 1}/{max_retries} in {wait_time}s")
                    await asyncio.sleep(wait_time)

        # All retries exhausted
        raise Exception(f"Agent {agent_name} failed after {max_retries} attempts: {last_exception}")

    def get_circuit_breaker_status(self) -> dict:
        """Get status of all circuit breakers"""
        return {
            name: cb.get_state()
            for name, cb in self.circuit_breakers.items()
        }

# Example usage
async def unstable_agent_call(fail_probability: float = 0.5):
    """Simulate unstable agent that fails randomly"""
    import random

    await asyncio.sleep(0.1)

    if random.random() < fail_probability:
        raise Exception("Agent call failed")

    return {"status": "success", "data": "result"}

async def main():
    caller = ResilientAgentCaller()

    # Simulate multiple calls
    for i in range(20):
        try:
            result = await caller.call_agent(
                "unstable_agent",
                unstable_agent_call,
                fail_probability=0.7,  # 70% failure rate
                max_retries=3
            )
            print(f"Call {i}: Success - {result}")

        except Exception as e:
            print(f"Call {i}: Failed - {e}")

        await asyncio.sleep(0.5)

    # Print circuit breaker status
    print("\nCircuit Breaker Status:")
    print(caller.get_circuit_breaker_status())

if __name__ == "__main__":
    asyncio.run(main())
```

### Pattern 6: Resource Pool with Load Balancing

Manage agent resources and distribute load:

```python
from typing import List, Optional, Dict, Any
from dataclasses import dataclass, field
from enum import Enum
import asyncio
from collections import deque
import time

class AgentStatus(Enum):
    IDLE = "idle"
    BUSY = "busy"
    OFFLINE = "offline"

@dataclass
class AgentResource:
    id: str
    type: str
    capacity: int
    current_load: int = 0
    status: AgentStatus = AgentStatus.IDLE
    last_heartbeat: float = field(default_factory=time.time)
    total_tasks_completed: int = 0
    total_tasks_failed: int = 0
    average_response_time: float = 0.0

@dataclass
class Task:
    id: str
    type: str
    priority: int  # Higher = more important
    created_at: float = field(default_factory=time.time)
    assigned_agent: Optional[str] = None

class LoadBalancingStrategy(Enum):
    ROUND_ROBIN = "round_robin"
    LEAST_LOADED = "least_loaded"
    LEAST_RESPONSE_TIME = "least_response_time"
    RANDOM = "random"

class ResourcePool:
    """Manage pool of agent resources with load balancing"""

    def __init__(self, strategy: LoadBalancingStrategy = LoadBalancingStrategy.LEAST_LOADED):
        self.agents: Dict[str, AgentResource] = {}
        self.task_queue: deque[Task] = deque()
        self.strategy = strategy
        self.round_robin_index = 0
        self.lock = asyncio.Lock()

    def register_agent(self, agent: AgentResource):
        """Register agent in resource pool"""
        self.agents[agent.id] = agent
        print(f"Registered agent: {agent.id} (type: {agent.type}, capacity: {agent.capacity})")

    def unregister_agent(self, agent_id: str):
        """Unregister agent from pool"""
        if agent_id in self.agents:
            self.agents[agent_id].status = AgentStatus.OFFLINE
            print(f"Unregistered agent: {agent_id}")

    async def submit_task(self, task: Task) -> str:
        """Submit task to pool for execution"""
        async with self.lock:
            # Try to assign immediately
            agent = self._select_agent(task.type)

            if agent and agent.current_load < agent.capacity:
                task.assigned_agent = agent.id
                agent.current_load += 1

                if agent.current_load >= agent.capacity:
                    agent.status = AgentStatus.BUSY

                print(f"Task {task.id} assigned to {agent.id}")
                return agent.id

            # No available agent, queue task
            self.task_queue.append(task)
            print(f"Task {task.id} queued (position: {len(self.task_queue)})")
            return None

    async def complete_task(self, task_id: str, agent_id: str, success: bool = True, response_time: float = 0.0):
        """Mark task as completed and update agent state"""
        async with self.lock:
            agent = self.agents.get(agent_id)

            if not agent:
                return

            # Update agent metrics
            agent.current_load = max(0, agent.current_load - 1)

            if success:
                agent.total_tasks_completed += 1
            else:
                agent.total_tasks_failed += 1

            # Update average response time (exponential moving average)
            if agent.average_response_time == 0:
                agent.average_response_time = response_time
            else:
                alpha = 0.3
                agent.average_response_time = (alpha * response_time +
                                              (1 - alpha) * agent.average_response_time)

            # Update status
            if agent.current_load < agent.capacity:
                agent.status = AgentStatus.IDLE

            print(f"Task {task_id} completed on {agent_id} (load: {agent.current_load}/{agent.capacity})")

            # Try to assign queued tasks
            await self._assign_queued_tasks()

    async def _assign_queued_tasks(self):
        """Assign queued tasks to available agents"""
        while self.task_queue:
            task = self.task_queue[0]

            agent = self._select_agent(task.type)

            if not agent or agent.current_load >= agent.capacity:
                break

            # Assign task
            self.task_queue.popleft()
            task.assigned_agent = agent.id
            agent.current_load += 1

            if agent.current_load >= agent.capacity:
                agent.status = AgentStatus.BUSY

            print(f"Queued task {task.id} assigned to {agent.id}")

    def _select_agent(self, task_type: str) -> Optional[AgentResource]:
        """Select agent using configured load balancing strategy"""

        # Filter agents by type and availability
        available = [
            agent for agent in self.agents.values()
            if agent.type == task_type
            and agent.status != AgentStatus.OFFLINE
            and agent.current_load < agent.capacity
        ]

        if not available:
            return None

        # Apply strategy
        if self.strategy == LoadBalancingStrategy.ROUND_ROBIN:
            agent = available[self.round_robin_index % len(available)]
            self.round_robin_index += 1
            return agent

        elif self.strategy == LoadBalancingStrategy.LEAST_LOADED:
            return min(available, key=lambda a: a.current_load / a.capacity)

        elif self.strategy == LoadBalancingStrategy.LEAST_RESPONSE_TIME:
            return min(available, key=lambda a: a.average_response_time)

        elif self.strategy == LoadBalancingStrategy.RANDOM:
            import random
            return random.choice(available)

        return available[0]

    def get_pool_status(self) -> dict:
        """Get current pool status"""
        total_capacity = sum(a.capacity for a in self.agents.values())
        total_load = sum(a.current_load for a in self.agents.values())

        return {
            "total_agents": len(self.agents),
            "total_capacity": total_capacity,
            "total_load": total_load,
            "utilization": total_load / total_capacity if total_capacity > 0 else 0,
            "queued_tasks": len(self.task_queue),
            "agents": {
                agent_id: {
                    "type": agent.type,
                    "status": agent.status.value,
                    "load": f"{agent.current_load}/{agent.capacity}",
                    "completed": agent.total_tasks_completed,
                    "failed": agent.total_tasks_failed,
                    "avg_response_time": f"{agent.average_response_time:.2f}s"
                }
                for agent_id, agent in self.agents.items()
            }
        }

# Example usage
async def simulate_task_execution(pool: ResourcePool, task: Task):
    """Simulate task execution"""

    # Submit task
    agent_id = await pool.submit_task(task)

    if not agent_id:
        # Task queued, wait for assignment
        while not task.assigned_agent:
            await asyncio.sleep(0.1)
        agent_id = task.assigned_agent

    # Simulate task execution
    start_time = time.time()
    await asyncio.sleep(1 + (task.priority % 3))  # Variable execution time
    response_time = time.time() - start_time

    # Complete task
    success = True  # Simulate 100% success rate
    await pool.complete_task(task.id, agent_id, success, response_time)

async def main():
    # Create resource pool with least-loaded strategy
    pool = ResourcePool(strategy=LoadBalancingStrategy.LEAST_LOADED)

    # Register agents
    pool.register_agent(AgentResource("agent_1", "analyzer", capacity=2))
    pool.register_agent(AgentResource("agent_2", "analyzer", capacity=3))
    pool.register_agent(AgentResource("agent_3", "analyzer", capacity=1))
    pool.register_agent(AgentResource("agent_4", "security", capacity=2))

    # Submit tasks
    tasks = [
        Task(f"task_{i}", "analyzer" if i % 3 != 0 else "security", priority=i)
        for i in range(20)
    ]

    # Execute tasks concurrently
    await asyncio.gather(*[
        simulate_task_execution(pool, task)
        for task in tasks
    ])

    # Print final pool status
    print("\nFinal Pool Status:")
    import json
    print(json.dumps(pool.get_pool_status(), indent=2))

if __name__ == "__main__":
    asyncio.run(main())
```

### Pattern 7: Distributed Tracing and Observability

Monitor and debug distributed agent workflows:

```python
from dataclasses import dataclass, field
from typing import Optional, Dict, List, Any
from datetime import datetime
import uuid
import json
import time

@dataclass
class Span:
    """Distributed tracing span"""
    trace_id: str
    span_id: str
    parent_span_id: Optional[str]
    operation_name: str
    start_time: float
    end_time: Optional[float] = None
    status: str = "started"
    tags: Dict[str, Any] = field(default_factory=dict)
    logs: List[Dict[str, Any]] = field(default_factory=list)

    def finish(self, status: str = "completed"):
        """Finish span"""
        self.end_time = time.time()
        self.status = status

    def add_tag(self, key: str, value: Any):
        """Add tag to span"""
        self.tags[key] = value

    def add_log(self, message: str, level: str = "info", **kwargs):
        """Add log entry to span"""
        self.logs.append({
            "timestamp": time.time(),
            "level": level,
            "message": message,
            **kwargs
        })

    def duration(self) -> float:
        """Get span duration in seconds"""
        if self.end_time:
            return self.end_time - self.start_time
        return time.time() - self.start_time

    def to_dict(self) -> dict:
        """Convert span to dictionary"""
        return {
            "trace_id": self.trace_id,
            "span_id": self.span_id,
            "parent_span_id": self.parent_span_id,
            "operation_name": self.operation_name,
            "start_time": self.start_time,
            "end_time": self.end_time,
            "duration": self.duration(),
            "status": self.status,
            "tags": self.tags,
            "logs": self.logs
        }

class Tracer:
    """Distributed tracing system"""

    def __init__(self):
        self.spans: Dict[str, Span] = {}
        self.active_traces: Dict[str, List[str]] = {}

    def start_trace(self, operation_name: str, **tags) -> Span:
        """Start new trace (root span)"""
        trace_id = str(uuid.uuid4())
        span_id = str(uuid.uuid4())

        span = Span(
            trace_id=trace_id,
            span_id=span_id,
            parent_span_id=None,
            operation_name=operation_name,
            start_time=time.time(),
            tags=tags
        )

        self.spans[span_id] = span
        self.active_traces[trace_id] = [span_id]

        return span

    def start_span(self, trace_id: str, parent_span_id: str, operation_name: str, **tags) -> Span:
        """Start child span"""
        span_id = str(uuid.uuid4())

        span = Span(
            trace_id=trace_id,
            span_id=span_id,
            parent_span_id=parent_span_id,
            operation_name=operation_name,
            start_time=time.time(),
            tags=tags
        )

        self.spans[span_id] = span

        if trace_id in self.active_traces:
            self.active_traces[trace_id].append(span_id)

        return span

    def finish_span(self, span_id: str, status: str = "completed"):
        """Finish span"""
        if span_id in self.spans:
            self.spans[span_id].finish(status)

    def get_trace(self, trace_id: str) -> List[Span]:
        """Get all spans for trace"""
        if trace_id not in self.active_traces:
            return []

        return [
            self.spans[span_id]
            for span_id in self.active_traces[trace_id]
            if span_id in self.spans
        ]

    def visualize_trace(self, trace_id: str) -> str:
        """Generate ASCII visualization of trace"""
        spans = self.get_trace(trace_id)

        if not spans:
            return "No spans found for trace"

        # Sort by start time
        spans.sort(key=lambda s: s.start_time)

        # Find root span
        root = next((s for s in spans if not s.parent_span_id), None)

        if not root:
            return "No root span found"

        # Build tree
        output = []
        output.append(f"Trace: {trace_id}")
        output.append(f"Total Duration: {spans[-1].end_time - root.start_time:.3f}s\n")

        self._visualize_span(root, spans, output, 0)

        return "\n".join(output)

    def _visualize_span(self, span: Span, all_spans: List[Span], output: List[str], depth: int):
        """Recursively visualize span tree"""
        indent = "  " * depth
        duration = f"{span.duration():.3f}s"
        status_icon = "✓" if span.status == "completed" else "✗"

        output.append(f"{indent}{status_icon} {span.operation_name} ({duration})")

        # Add tags if present
        if span.tags:
            output.append(f"{indent}  Tags: {span.tags}")

        # Find and visualize children
        children = [s for s in all_spans if s.parent_span_id == span.span_id]
        for child in children:
            self._visualize_span(child, all_spans, output, depth + 1)

    def export_trace_json(self, trace_id: str) -> str:
        """Export trace as JSON"""
        spans = self.get_trace(trace_id)
        return json.dumps([s.to_dict() for s in spans], indent=2)

class ObservableOrchestrator:
    """Orchestrator with built-in observability"""

    def __init__(self, tracer: Tracer):
        self.tracer = tracer

    async def execute_workflow(self, workflow_name: str, tasks: List[Dict[str, Any]]):
        """Execute workflow with full tracing"""

        # Start root span
        root_span = self.tracer.start_trace(
            f"workflow:{workflow_name}",
            workflow=workflow_name,
            task_count=len(tasks)
        )

        try:
            results = []

            for task in tasks:
                # Create span for each task
                task_span = self.tracer.start_span(
                    root_span.trace_id,
                    root_span.span_id,
                    f"task:{task['name']}",
                    task_type=task.get('type', 'unknown'),
                    agent=task.get('agent', 'unknown')
                )

                try:
                    task_span.add_log("Task started", level="info")

                    # Execute task
                    result = await self._execute_task(task, task_span)

                    task_span.add_log("Task completed", level="info", result=result)
                    task_span.add_tag("result", result)

                    self.tracer.finish_span(task_span.span_id, "completed")
                    results.append(result)

                except Exception as e:
                    task_span.add_log(f"Task failed: {str(e)}", level="error")
                    task_span.add_tag("error", str(e))
                    self.tracer.finish_span(task_span.span_id, "failed")
                    raise

            root_span.add_tag("success_count", len(results))
            self.tracer.finish_span(root_span.span_id, "completed")

            return {
                "trace_id": root_span.trace_id,
                "results": results
            }

        except Exception as e:
            root_span.add_log(f"Workflow failed: {str(e)}", level="error")
            self.tracer.finish_span(root_span.span_id, "failed")
            raise

    async def _execute_task(self, task: Dict[str, Any], span: Span) -> Any:
        """Execute individual task"""
        import asyncio
        import random

        # Simulate task execution
        await asyncio.sleep(random.uniform(0.1, 1.0))

        # Simulate 10% failure rate
        if random.random() < 0.1:
            raise Exception("Task execution failed")

        return {"status": "success", "data": f"result_{task['name']}"}

# Example usage
async def main():
    tracer = Tracer()
    orchestrator = ObservableOrchestrator(tracer)

    # Execute workflow
    tasks = [
        {"name": "analyze_code", "type": "analysis", "agent": "agent_1"},
        {"name": "scan_security", "type": "security", "agent": "agent_2"},
        {"name": "run_tests", "type": "testing", "agent": "agent_3"},
        {"name": "generate_report", "type": "reporting", "agent": "agent_4"},
    ]

    try:
        result = await orchestrator.execute_workflow("code_review", tasks)

        # Visualize trace
        print("\nTrace Visualization:")
        print(tracer.visualize_trace(result['trace_id']))

        # Export trace
        print("\nTrace JSON:")
        print(tracer.export_trace_json(result['trace_id']))

    except Exception as e:
        print(f"Workflow failed: {e}")

if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
```

## Best Practices

### DO's

1. **Design for Idempotency** - Tasks should be safely retryable without side effects
2. **Use Correlation IDs** - Track requests across distributed systems
3. **Implement Timeouts** - Every operation should have a timeout
4. **Fail Fast** - Detect failures quickly, don't let requests hang
5. **Use Dead Letter Queues** - Capture failed messages for analysis
6. **Monitor Everything** - Metrics, logs, traces for all components
7. **Implement Circuit Breakers** - Prevent cascading failures
8. **Use Exponential Backoff** - Space out retries to avoid thundering herd
9. **Validate DAGs** - Check for cycles before execution
10. **Version Workflows** - Track workflow changes over time

### DON'Ts

1. **Don't Pass Large Data** - Use references (S3 URLs, database IDs) instead
2. **Don't Ignore Partial Failures** - Handle them explicitly
3. **Don't Use Distributed Transactions** - Use saga pattern instead
4. **Don't Synchronous Chain** - Use async/parallel execution where possible
5. **Don't Skip Health Checks** - Monitor agent health continuously
6. **Don't Hardcode Timeouts** - Make them configurable per task type
7. **Don't Trust Clocks** - Use logical ordering, not wall clock time
8. **Don't Forget Cleanup** - Clean up zombie workflows and stale state

## Framework Comparison

| Feature | Airflow | Temporal | Prefect | Celery | Step Functions |
|---------|---------|----------|---------|--------|----------------|
| **Language** | Python | Multi | Python | Python | JSON |
| **Durable Execution** | ❌ | ✅ | ✅ | ❌ | ✅ |
| **UI** | ✅ Rich | ✅ Good | ✅ Modern | ⚠️ Basic | ✅ Visual |
| **Scalability** | ✅ High | ✅ Very High | ✅ High | ✅ High | ✅ Unlimited |
| **Learning Curve** | Medium | Medium | Low | Low | Low |
| **Self-Hosted** | ✅ | ✅ | ✅ | ✅ | ❌ |
| **Cloud-Native** | ⚠️ | ✅ | ✅ | ⚠️ | ✅ |
| **Best For** | Batch ETL | Long workflows | Data science | Task queues | AWS serverless |

## Production Deployment

### Deployment Checklist

- [ ] Define clear task boundaries and responsibilities
- [ ] Implement comprehensive error handling and retries
- [ ] Set up distributed tracing (OpenTelemetry, Jaeger)
- [ ] Configure monitoring and alerting (Prometheus, Grafana)
- [ ] Implement circuit breakers for external dependencies
- [ ] Use message queues for async communication (RabbitMQ, Kafka)
- [ ] Set up health checks for all agents
- [ ] Implement graceful shutdown handling
- [ ] Configure resource limits and quotas
- [ ] Set up log aggregation (ELK, Loki)
- [ ] Implement authentication and authorization
- [ ] Configure rate limiting and throttling
- [ ] Set up auto-scaling for worker pools
- [ ] Implement chaos engineering tests
- [ ] Document workflow patterns and runbooks

## Related Skills

- `mcp-integration-toolkit` - For agent communication via MCP protocol
- `git-mastery-suite` - For orchestrating Git-based workflows
- `security-scanning-suite` - For security orchestration and SAST/DAST coordination
- `deployment-automation-toolkit` - For CI/CD orchestration patterns
- `code-review-framework` - For multi-agent code review orchestration

## References

- [Orchestration vs Choreography](https://stackoverflow.blog/2020/11/23/the-macro-problem-with-microservices/) - Architectural patterns
- [Saga Pattern](https://microservices.io/patterns/data/saga.html) - Distributed transactions
- [Circuit Breaker Pattern](https://martinfowler.com/bliki/CircuitBreaker.html) - Fault tolerance
- [Two-Phase Commit](https://en.wikipedia.org/wiki/Two-phase_commit_protocol) - Distributed consensus
- [Event Sourcing](https://martinfowler.com/eaaDev/EventSourcing.html) - State management
- [CQRS](https://martinfowler.com/bliki/CQRS.html) - Command Query Responsibility Segregation
- [OpenTelemetry](https://opentelemetry.io/) - Observability standard
- [Temporal Patterns](https://docs.temporal.io/dev-guide/patterns) - Workflow patterns
- [Airflow Best Practices](https://airflow.apache.org/docs/apache-airflow/stable/best-practices.html) - Production patterns
