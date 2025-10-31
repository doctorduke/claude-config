# Agent Builder Framework - API Reference

## Agent Specification Schema

### Complete Schema Definition

```yaml
AgentSpecification:
  type: object
  required:
    - metadata
    - role
    - capabilities
    - tools
    - inputs
    - outputs
    - constraints
    - success_criteria

  properties:
    metadata:
      type: object
      required: [name, version, description, created, author]
      properties:
        name:
          type: string
          pattern: "^[a-z][a-z0-9-]*$"  # kebab-case
          description: "Unique agent identifier"
        version:
          type: string
          pattern: "^\\d+\\.\\d+\\.\\d+$"  # semver
          description: "Semantic version"
        description:
          type: string
          maxLength: 200
          description: "One-sentence purpose"
        created:
          type: string
          format: date-time
          description: "Creation timestamp"
        author:
          type: string
          description: "Creator identifier"
        tags:
          type: array
          items: {type: string}
          description: "Optional classification tags"

    role:
      type: object
      required: [primary, responsibilities, out_of_scope]
      properties:
        primary:
          type: string
          maxLength: 200
          description: "Main responsibility (one sentence)"
        responsibilities:
          type: array
          minItems: 1
          maxItems: 10
          items: {type: string}
          description: "Specific duties"
        out_of_scope:
          type: array
          items: {type: string}
          description: "What agent should NOT do"

    capabilities:
      type: array
      minItems: 1
      maxItems: 10
      items:
        type: object
        required: [name, description, priority]
        properties:
          name:
            type: string
            pattern: "^[a-z][a-z0-9-]*$"
          description:
            type: string
          priority:
            type: string
            enum: [critical, high, medium, low]

    tools:
      type: array
      minItems: 1
      items:
        type: object
        required: [name, purpose, required]
        properties:
          name:
            type: string
            description: "Tool identifier"
          purpose:
            type: string
            description: "Why tool is needed"
          required:
            type: boolean
            description: "Is tool mandatory"
          version:
            type: string
            description: "Optional tool version"
          configuration:
            type: object
            description: "Optional tool config"

    inputs:
      type: array
      minItems: 1
      items:
        type: object
        required: [name, type, description, required]
        properties:
          name:
            type: string
            pattern: "^[a-z_][a-z0-9_]*$"
          type:
            type: string
            description: "Data type (string, integer, array, object, etc.)"
          description:
            type: string
          required:
            type: boolean
          validation:
            type: string
            description: "Validation rules"
          example:
            description: "Example value"
          default:
            description: "Default value if not required"

    outputs:
      type: array
      minItems: 1
      items:
        type: object
        required: [name, type, description, format]
        properties:
          name:
            type: string
            pattern: "^[a-z_][a-z0-9_]*$"
          type:
            type: string
          description:
            type: string
          format:
            type: string
            description: "Output format (json, markdown, etc.)"
          schema:
            type: object
            description: "Optional JSON schema for structured outputs"

    constraints:
      type: object
      required:
        - max_execution_time
        - max_cost
        - allowed_operations
        - forbidden_operations
      properties:
        max_execution_time:
          type: string
          pattern: "^\\d+[smh]$"  # e.g., "300s", "5m", "2h"
          description: "Maximum execution time"
        max_cost:
          type: number
          minimum: 0
          description: "Maximum cost in USD"
        max_tokens:
          type: integer
          minimum: 0
          description: "Maximum LLM tokens"
        allowed_operations:
          type: array
          items: {type: string}
          description: "Permitted actions"
        forbidden_operations:
          type: array
          items: {type: string}
          description: "Prohibited actions"
        resource_limits:
          type: object
          properties:
            memory: {type: string}
            cpu: {type: string}
            disk: {type: string}

    success_criteria:
      type: array
      minItems: 1
      items:
        type: object
        required: [metric, description, threshold, measurement]
        properties:
          metric:
            type: string
            description: "Metric name"
          description:
            type: string
            description: "What metric measures"
          threshold:
            description: "Success threshold (any type)"
          measurement:
            type: string
            description: "How to measure"

    error_handling:
      type: object
      properties:
        retry_policy:
          type: object
          properties:
            max_attempts: {type: integer, minimum: 1}
            backoff: {type: string, enum: [exponential, linear, fixed]}
            initial_delay: {type: string}
        failure_modes:
          type: array
          items:
            type: object
            properties:
              condition: {type: string}
              action: {type: string}
        fallback_strategy:
          type: string

    dependencies:
      type: array
      items:
        type: object
        properties:
          name: {type: string}
          type: {type: string, enum: [agent, service, api]}
          required: {type: boolean}
          purpose: {type: string}

    context_requirements:
      type: array
      items:
        type: object
        properties:
          name: {type: string}
          type: {type: string}
          source: {type: string}

    performance_targets:
      type: object
      properties:
        latency_p50: {type: string}
        latency_p99: {type: string}
        throughput: {type: string}
        success_rate: {type: number, minimum: 0, maximum: 1}
```

## Capability Taxonomy

### Analysis Capabilities
```yaml
code-analysis:
  description: "Parse and understand code structure"
  typical_tools: [Read, AST parser, Grep]
  use_cases: [documentation, testing, refactoring]

static-analysis:
  description: "Analyze code without execution"
  typical_tools: [SAST tools, linters, Grep]
  use_cases: [security, quality, standards]

dynamic-analysis:
  description: "Analyze code during execution"
  typical_tools: [DAST tools, profilers, debuggers]
  use_cases: [security, performance, behavior]

dependency-analysis:
  description: "Analyze project dependencies"
  typical_tools: [package managers, vulnerability scanners]
  use_cases: [security, licensing, updates]
```

### Generation Capabilities
```yaml
code-generation:
  description: "Generate source code"
  typical_tools: [Write, templates, LLM]
  use_cases: [scaffolding, boilerplate, automation]

documentation-generation:
  description: "Generate documentation from code"
  typical_tools: [Read, Write, AST parser]
  use_cases: [API docs, README, guides]

test-generation:
  description: "Generate test code"
  typical_tools: [Read, Write, AST parser, coverage]
  use_cases: [unit tests, integration tests]

report-generation:
  description: "Generate reports"
  typical_tools: [Write, templates, visualization]
  use_cases: [status, metrics, analysis]
```

### Execution Capabilities
```yaml
test-execution:
  description: "Run test suites"
  typical_tools: [Bash, test frameworks]
  use_cases: [CI/CD, quality assurance]

deployment:
  description: "Deploy applications"
  typical_tools: [Bash, kubectl, terraform]
  use_cases: [releases, infrastructure]

monitoring:
  description: "Monitor systems"
  typical_tools: [metrics APIs, log aggregators]
  use_cases: [observability, alerts]
```

### Validation Capabilities
```yaml
schema-validation:
  description: "Validate against schema"
  typical_tools: [JSON schema, validators]
  use_cases: [data validation, API contracts]

coverage-validation:
  description: "Validate test coverage"
  typical_tools: [coverage tools]
  use_cases: [quality gates, CI/CD]

security-validation:
  description: "Validate security posture"
  typical_tools: [scanners, validators]
  use_cases: [compliance, audits]
```

## Tool Selection Matrix

### File Operations
| Capability | Primary Tool | Alternatives | Notes |
|------------|-------------|--------------|-------|
| Read files | Read | cat (Bash) | Read is preferred |
| Write files | Write | echo/tee (Bash) | Write is preferred |
| Edit files | Edit | sed (Bash) | Edit for targeted changes |
| Find files | Glob | find (Bash) | Glob is faster |
| Search content | Grep | grep (Bash) | Grep is optimized |

### Code Analysis
| Capability | Primary Tool | Alternatives | Language |
|------------|-------------|--------------|----------|
| Parse Python | ast module | lib2to3 | Python |
| Parse JavaScript | @babel/parser | acorn | JavaScript |
| Parse TypeScript | typescript | ts-morph | TypeScript |
| Parse Go | go/parser | tree-sitter | Go |
| Parse Java | JavaParser | Eclipse JDT | Java |

### Security Scanning
| Capability | Primary Tool | Alternatives | Coverage |
|------------|-------------|--------------|----------|
| Python SAST | bandit | semgrep | Python |
| Multi-language SAST | semgrep | SonarQube | Many |
| Dependency scan (Python) | safety | pip-audit | Python |
| Dependency scan (JS) | npm audit | snyk | JavaScript |
| Secret detection | trufflehog | gitleaks | Any |

### Testing
| Capability | Primary Tool | Alternatives | Framework |
|------------|-------------|--------------|-----------|
| Python testing | pytest | unittest | Python |
| JavaScript testing | jest | mocha | JavaScript |
| Coverage (Python) | coverage.py | pytest-cov | Python |
| Coverage (JS) | jest --coverage | nyc | JavaScript |

## Testing Framework API

### Test Levels

```python
# Unit Test Template
class TestAgentUnit:
    """Unit tests for individual agent functions."""

    def test_function_name(self):
        """Test specific function behavior."""
        # Arrange
        agent = Agent(spec)
        inputs = create_test_inputs()

        # Act
        result = agent.function_name(inputs)

        # Assert
        assert result["status"] == "success"
        assert "output" in result

# Integration Test Template
class TestAgentIntegration:
    """Integration tests for agent with tools."""

    @pytest.fixture
    def agent_with_tools(self):
        """Create agent with initialized tools."""
        agent = Agent(spec)
        agent.initialize_tools()
        return agent

    def test_workflow_step(self, agent_with_tools):
        """Test agent workflow with real tools."""
        result = agent_with_tools.execute_step(inputs)
        assert result["step_completed"] == True

# Acceptance Test Template
class TestAgentAcceptance:
    """Acceptance tests for end-to-end scenarios."""

    def test_user_scenario(self):
        """
        Scenario: [Description]
        Given: [Initial state]
        When: [Action]
        Then: [Expected outcome]
        """
        # Setup
        scenario = create_scenario()

        # Execute
        result = agent.execute(scenario["inputs"])

        # Verify
        assert result["status"] == scenario["expected_status"]
```

### Test Utilities

```python
# Fixture Creation
def create_test_specification() -> AgentSpecification:
    """Create specification for testing."""
    return AgentSpecification(
        name="test-agent",
        version="1.0.0",
        # ... minimal valid spec
    )

def create_test_inputs(overrides: dict = None) -> dict:
    """Create valid test inputs."""
    defaults = {
        "input_1": "default_value",
        "input_2": 42
    }
    if overrides:
        defaults.update(overrides)
    return defaults

# Assertion Helpers
def assert_valid_output(output: dict, schema: dict):
    """Validate output against schema."""
    import jsonschema
    jsonschema.validate(output, schema)

def assert_execution_time(agent_result: dict, max_time: float):
    """Assert execution completed within time limit."""
    assert agent_result["execution_time"] < max_time

def assert_resource_limits(agent: Agent, limits: dict):
    """Assert agent respects resource limits."""
    metrics = agent.get_resource_usage()
    assert metrics["memory"] < limits["memory"]
    assert metrics["cpu"] < limits["cpu"]
```

## Coordination Protocol Specifications

### Handoff Protocol API

```python
class HandoffProtocol:
    """Protocol for agent-to-agent handoff."""

    def __init__(
        self,
        protocol_id: str,
        sender_agent: str,
        receiver_agent: str,
        trigger_condition: str,
        trigger_check: Callable[[], bool],
        payload_schema: dict,
        payload_data: Any,
        requires_ack: bool = True,
        ack_timeout: float = 30.0,
        max_retries: int = 3,
        retry_delay: float = 5.0,
        fallback_action: Optional[Callable] = None
    ):
        """
        Initialize handoff protocol.

        Args:
            protocol_id: Unique identifier for this handoff
            sender_agent: Agent initiating handoff
            receiver_agent: Agent receiving handoff
            trigger_condition: Description of trigger
            trigger_check: Function to check if trigger is met
            payload_schema: JSON schema for payload validation
            payload_data: Data to transfer
            requires_ack: Whether acknowledgment is required
            ack_timeout: Maximum time to wait for ack (seconds)
            max_retries: Maximum retry attempts
            retry_delay: Delay between retries (seconds)
            fallback_action: Action to take if handoff fails
        """

    def validate(self) -> List[str]:
        """Validate protocol configuration."""

    def execute(self) -> HandoffResult:
        """Execute the handoff."""
```

### Coordination Patterns

```python
# Sequential Pipeline
def create_sequential_pipeline(
    agents: List[str],
    data_flow: Optional[Callable] = None
) -> CoordinationGraph:
    """
    Create sequential agent pipeline.

    Args:
        agents: List of agent IDs in execution order
        data_flow: Optional function to transform data between agents

    Returns:
        CoordinationGraph with sequential handoffs
    """

# Parallel Coordination
def create_parallel_coordination(
    coordinator: str,
    workers: List[str],
    aggregation: Optional[Callable] = None
) -> CoordinationGraph:
    """
    Create parallel worker coordination.

    Args:
        coordinator: Coordinator agent ID
        workers: Worker agent IDs
        aggregation: Optional function to aggregate worker results

    Returns:
        CoordinationGraph with parallel execution
    """

# Conditional Routing
def create_conditional_router(
    router_agent: str,
    routes: Dict[str, Tuple[Callable, str]]
) -> CoordinationGraph:
    """
    Create conditional routing graph.

    Args:
        router_agent: Router agent ID
        routes: Dict of {route_name: (condition_func, target_agent)}

    Returns:
        CoordinationGraph with conditional routing
    """
```

## Lifecycle State Machine

### States

```python
class AgentState(Enum):
    """Agent lifecycle states."""

    UNINITIALIZED = "uninitialized"  # Agent created but not initialized
    INITIALIZING = "initializing"    # Initialization in progress
    READY = "ready"                  # Ready to execute tasks
    EXECUTING = "executing"          # Currently executing task
    PAUSED = "paused"                # Execution paused
    COMPLETING = "completing"        # Finalizing execution
    COMPLETED = "completed"          # Task completed successfully
    FAILED = "failed"                # Task failed
    TERMINATED = "terminated"        # Agent shut down
```

### State Transitions

```
UNINITIALIZED -> INITIALIZING -> READY
READY -> EXECUTING -> COMPLETING -> COMPLETED
READY -> EXECUTING -> FAILED
EXECUTING -> PAUSED -> EXECUTING
EXECUTING -> PAUSED -> TERMINATED
Any State -> TERMINATED (emergency shutdown)
```

### Lifecycle API

```python
class AgentLifecycle:
    """Manage agent lifecycle."""

    def __init__(self, agent_id: str, specification: AgentSpecification):
        """Initialize lifecycle manager."""

    def initialize(self) -> bool:
        """
        Initialize agent.

        Returns:
            True if initialization succeeded, False otherwise
        """

    def execute(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute agent task.

        Args:
            task: Task specification

        Returns:
            Task results

        Raises:
            ValueError: If agent is not in READY state
            Exception: If execution fails
        """

    def pause(self):
        """Pause agent execution."""

    def resume(self):
        """Resume paused agent."""

    def terminate(self):
        """Terminate agent and cleanup resources."""

    def get_state(self) -> AgentState:
        """Get current agent state."""

    def get_health(self) -> Dict[str, Any]:
        """
        Get agent health status.

        Returns:
            {
                "agent_id": str,
                "state": str,
                "metrics": dict,
                "healthy": bool
            }
        """

    def get_metrics(self) -> Dict[str, Any]:
        """
        Get agent performance metrics.

        Returns:
            {
                "start_time": float,
                "end_time": float,
                "execution_time": float,
                "errors": int,
                "tasks_completed": int
            }
        """
```

## Performance Metrics

### Metric Definitions

```python
class AgentMetrics:
    """Agent performance metrics."""

    # Latency metrics
    latency_p50: float      # Median execution time
    latency_p95: float      # 95th percentile
    latency_p99: float      # 99th percentile
    latency_max: float      # Maximum execution time

    # Throughput metrics
    tasks_per_second: float  # Task throughput
    tokens_per_second: float # LLM token throughput

    # Success metrics
    success_rate: float      # Successful tasks / total tasks
    error_rate: float        # Failed tasks / total tasks
    retry_rate: float        # Retried tasks / total tasks

    # Resource metrics
    avg_memory_mb: float     # Average memory usage
    peak_memory_mb: float    # Peak memory usage
    avg_cpu_percent: float   # Average CPU utilization
    peak_cpu_percent: float  # Peak CPU utilization

    # Cost metrics
    total_cost_usd: float    # Total cost
    avg_cost_per_task: float # Average cost per task
    token_cost_usd: float    # LLM token cost

    def to_dict(self) -> dict:
        """Export metrics as dictionary."""

    def to_json(self) -> str:
        """Export metrics as JSON."""

    @classmethod
    def from_agent(cls, agent: Agent) -> 'AgentMetrics':
        """Calculate metrics from agent."""
```

### Metric Collection

```python
class MetricsCollector:
    """Collect and aggregate agent metrics."""

    def record_execution(
        self,
        agent_id: str,
        execution_time: float,
        success: bool,
        cost: float
    ):
        """Record single execution."""

    def get_metrics(self, agent_id: str) -> AgentMetrics:
        """Get aggregated metrics for agent."""

    def get_all_metrics(self) -> Dict[str, AgentMetrics]:
        """Get metrics for all agents."""

    def export_prometheus(self) -> str:
        """Export metrics in Prometheus format."""
```

## Validation Functions

```python
def validate_specification(spec: AgentSpecification) -> List[str]:
    """
    Validate agent specification.

    Args:
        spec: Agent specification to validate

    Returns:
        List of validation errors (empty if valid)
    """

def validate_capability_coverage(
    capabilities: List[Capability],
    tools: List[Tool]
) -> Dict[str, str]:
    """
    Validate that tools cover all capabilities.

    Args:
        capabilities: Agent capabilities
        tools: Agent tools

    Returns:
        Dict of {capability_name: coverage_status}
    """

def validate_inputs(
    inputs: Dict[str, Any],
    spec: AgentSpecification
) -> List[str]:
    """
    Validate inputs against specification.

    Args:
        inputs: Input values
        spec: Agent specification

    Returns:
        List of validation errors (empty if valid)
    """

def validate_outputs(
    outputs: Dict[str, Any],
    spec: AgentSpecification
) -> List[str]:
    """
    Validate outputs against specification.

    Args:
        outputs: Output values
        spec: Agent specification

    Returns:
        List of validation errors (empty if valid)
    """
```

## Helper Functions

```python
def create_agent_from_spec(
    spec_path: str
) -> Agent:
    """
    Create agent from YAML specification file.

    Args:
        spec_path: Path to specification YAML

    Returns:
        Initialized agent
    """

def export_agent_spec(
    agent: Agent,
    output_path: str
):
    """
    Export agent specification to YAML.

    Args:
        agent: Agent instance
        output_path: Where to write YAML
    """

def clone_agent(
    agent: Agent,
    new_name: str
) -> Agent:
    """
    Clone agent with new name.

    Args:
        agent: Agent to clone
        new_name: Name for cloned agent

    Returns:
        New agent instance
    """

def merge_agent_specs(
    specs: List[AgentSpecification]
) -> AgentSpecification:
    """
    Merge multiple agent specifications (for composition).

    Args:
        specs: Specifications to merge

    Returns:
        Merged specification
    """
```

## Constants

```python
# Priority levels
PRIORITY_CRITICAL = "critical"
PRIORITY_HIGH = "high"
PRIORITY_MEDIUM = "medium"
PRIORITY_LOW = "low"

# Backoff strategies
BACKOFF_EXPONENTIAL = "exponential"
BACKOFF_LINEAR = "linear"
BACKOFF_FIXED = "fixed"

# Agent types
AGENT_TYPE_ANALYZER = "analyzer"
AGENT_TYPE_GENERATOR = "generator"
AGENT_TYPE_VALIDATOR = "validator"
AGENT_TYPE_EXECUTOR = "executor"

# Default constraints
DEFAULT_MAX_EXECUTION_TIME = "300s"
DEFAULT_MAX_COST = 1.00
DEFAULT_MAX_TOKENS = 10000
DEFAULT_MAX_RETRIES = 3
DEFAULT_RETRY_DELAY = 5.0
```

## Usage Examples

### Create Agent from Specification

```python
from agent_builder import create_agent_from_spec

# Load specification
agent = create_agent_from_spec("specs/security-auditor.yaml")

# Initialize
if not agent.lifecycle.initialize():
    raise RuntimeError("Initialization failed")

# Execute
result = agent.execute({
    "repository_path": "/path/to/repo",
    "scan_types": ["sast", "dependencies"]
})

# Check results
print(f"Status: {result['status']}")
print(f"Findings: {len(result['findings'])}")
```

### Validate Specification

```python
from agent_builder import validate_specification, AgentSpecification

spec = AgentSpecification.from_yaml("spec.yaml")
errors = validate_specification(spec)

if errors:
    print("Specification errors:")
    for error in errors:
        print(f"  - {error}")
else:
    print("Specification is valid")
```

### Create Coordination Graph

```python
from agent_builder import create_sequential_pipeline

# Create pipeline
pipeline = create_sequential_pipeline([
    "code-analyzer",
    "security-auditor",
    "report-generator"
])

# Execute pipeline
results = pipeline.execute({"repository": "/path/to/repo"})
```
