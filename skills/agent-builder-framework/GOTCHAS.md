# Agent Builder Framework - Gotchas & Troubleshooting

## Common Pitfalls

### 1. Scope Creep

**Problem**: Agent responsibilities grow unchecked, becoming a "Swiss Army knife" that's difficult to maintain.

**Symptoms**:
- Agent has >10 capabilities
- Agent specification is >200 lines
- Agent handles multiple unrelated domains
- Tests are difficult to write
- Debugging takes excessive time

**Example**:
```python
# BAD: Scope creep
class MonolithicAgent:
    capabilities = [
        "code-analysis",
        "testing",
        "security-scanning",
        "deployment",
        "monitoring",
        "documentation",
        "database-migration",
        "api-integration",
        "logging",
        "notification"  # Too many!
    ]
```

**Solution**:
- **Apply Single Responsibility Principle**: Each agent should have ONE primary purpose
- **Limit to 3-5 core capabilities**: If you need more, split into multiple agents
- **Use multi-agent coordination**: Create specialized agents and coordinate them

```python
# GOOD: Focused agents
class SecurityAuditor:
    capabilities = [
        "static-analysis",
        "dependency-scanning",
        "secret-detection",
        "report-generation"
    ]

class Deployer:
    capabilities = [
        "build-validation",
        "environment-setup",
        "deployment-execution",
        "rollback"
    ]
```

**Prevention**:
- Review specification regularly
- Reject feature requests outside core purpose
- Create new agents instead of extending existing ones

### 2. Under-Specification

**Problem**: Vague or incomplete agent specifications lead to unpredictable behavior and failed deployments.

**Symptoms**:
- Missing input validation
- No error handling defined
- Success criteria unclear
- No resource constraints
- Outputs undefined or inconsistent

**Example**:
```yaml
# BAD: Under-specified
name: data-processor
role: Process data
capabilities:
  - processing
inputs:
  - data  # What type? Format? Validation?
outputs:
  - results  # What format? Schema?
```

**Solution**:
Use complete specification template with all required fields:

```yaml
# GOOD: Well-specified
name: data-processor
role: Transform CSV data to normalized JSON
capabilities:
  - name: csv-parsing
    description: Parse CSV with error handling
    priority: critical
  - name: data-validation
    description: Validate data against schema
    priority: critical
  - name: json-serialization
    description: Output normalized JSON
    priority: critical

inputs:
  - name: csv_file
    type: string
    description: Path to CSV file
    required: true
    validation: "must exist, be readable, have .csv extension"
    example: "/data/input.csv"
  - name: schema_file
    type: string
    description: JSON schema for validation
    required: true
    validation: "must be valid JSON schema"
    example: "/schemas/data.schema.json"

outputs:
  - name: normalized_data
    type: object
    description: Validated, normalized JSON data
    format: json
    schema:
      type: array
      items:
        type: object
        properties:
          id: {type: string}
          value: {type: number}

constraints:
  max_execution_time: "60s"
  max_file_size: "100MB"
  max_rows: 100000

success_criteria:
  - metric: all_rows_processed
    threshold: 100%
    measurement: "processed / total rows"
  - metric: validation_passed
    threshold: true
    measurement: "schema validation result"
```

**Prevention**:
- Use specification validation before implementation
- Require all template fields
- Review specifications with peers
- Test against specification

### 3. Tool Selection Errors

**Problem**: Choosing wrong tools for agent capabilities, leading to failures or inefficiency.

**Symptoms**:
- Agent can't complete tasks
- High error rates
- Slow performance
- Missing dependencies at runtime
- Tool version conflicts

**Example**:
```python
# BAD: Wrong tool selection
capability = "static-analysis"
tools = ["Read", "Write"]  # Not enough! Missing actual analysis tools
```

**Solution**:
Systematic capability-to-tool mapping:

```python
# GOOD: Complete tool mapping
capability = "static-analysis"
tools = {
    "core": ["semgrep", "bandit", "pylint"],  # Analysis tools
    "supporting": ["Read", "Grep", "Bash"],    # File and execution
    "optional": ["flake8", "mypy"]             # Additional checkers
}

# Validate tools available
def validate_tools(required_tools):
    for tool in required_tools["core"]:
        if not tool_available(tool):
            raise RuntimeError(f"Required tool missing: {tool}")
```

**Common Mistakes**:
- Forgetting supporting tools (e.g., Read for SAST tools)
- Not checking tool availability before runtime
- Missing tool configuration files
- Version incompatibilities

**Prevention**:
- Use capability-tool mapping pattern (PATTERNS.md #2)
- Validate tool availability during initialization
- Document tool versions in specification
- Test with actual tools, not mocks

### 4. Testing Challenges

**Problem**: AI agents are difficult to test due to non-determinism, long execution times, and complex dependencies.

**Symptoms**:
- Flaky tests that pass/fail randomly
- Tests take too long to run
- Difficult to reproduce failures
- Low test coverage
- Can't test edge cases

**Example**:
```python
# BAD: Brittle test
def test_agent():
    result = agent.execute(input)
    assert result == expected_exact_output  # Will fail due to LLM variance
```

**Solution**:
Test properties, not exact outputs:

```python
# GOOD: Property-based test
def test_agent():
    result = agent.execute(input)

    # Test structure
    assert "status" in result
    assert "findings" in result

    # Test properties
    assert isinstance(result["findings"], list)
    assert len(result["findings"]) > 0

    # Test semantics (not exact text)
    assert any("vulnerability" in str(f).lower() for f in result["findings"])

    # Test constraints
    assert result["execution_time"] < 300
```

**Strategies**:

**1. Mock LLM calls in unit tests**:
```python
@patch("agent.llm_call")
def test_with_mock(mock_llm):
    mock_llm.return_value = "mocked response"
    result = agent.execute(input)
    assert result["status"] == "success"
```

**2. Use deterministic mode for integration tests**:
```python
agent = Agent(temperature=0)  # Deterministic outputs
```

**3. Test ranges instead of exact values**:
```python
assert 0.7 <= result["confidence"] <= 0.9
```

**4. Use fixtures for slow operations**:
```python
@pytest.fixture(scope="session")
def expensive_setup():
    # Run once for all tests
    return setup_large_project()
```

**Prevention**:
- Follow testing pyramid (many unit tests, fewer integration tests)
- Mock external dependencies
- Use property-based testing (hypothesis)
- Set timeouts on all tests
- Test error paths, not just happy path

### 5. Coordination Failures

**Problem**: Multi-agent systems fail due to race conditions, missed handoffs, or conflicting actions.

**Symptoms**:
- Agents waiting indefinitely for handoff
- Duplicate work by multiple agents
- Conflicting actions (agent A writes, agent B deletes)
- Deadlocks
- Lost messages

**Example**:
```python
# BAD: No acknowledgment or timeout
def handoff(sender, receiver, data):
    send_message(receiver, data)  # Fire and forget - could be lost!
    # No timeout, no retry, no verification
```

**Solution**:
Use formal coordination protocols with acknowledgments and timeouts:

```python
# GOOD: Reliable handoff with acknowledgment
protocol = HandoffProtocol(
    sender_agent="agent-a",
    receiver_agent="agent-b",
    payload_data=data,
    requires_ack=True,        # Require acknowledgment
    ack_timeout=30.0,         # 30 second timeout
    max_retries=3,            # Retry up to 3 times
    retry_delay=5.0,          # 5 seconds between retries
    fallback_action=lambda: handle_failure()  # Fallback if all retries fail
)

result = coordinator.initiate_handoff(protocol)
if result != "handoff_completed":
    handle_coordination_failure(protocol)
```

**Common Coordination Issues**:

**1. Race Conditions**:
```python
# BAD: Race condition
def process():
    data = read_shared_state()
    modified = transform(data)
    write_shared_state(modified)  # Another agent might write between read and write!

# GOOD: Use locking
def process():
    with state_lock:
        data = read_shared_state()
        modified = transform(data)
        write_shared_state(modified)
```

**2. Missed Handoffs**:
```python
# BAD: No verification
send_to_agent(agent_b, data)
# What if agent_b is down?

# GOOD: Verify receipt
if not send_to_agent(agent_b, data, wait_for_ack=True):
    retry_or_fallback()
```

**3. Deadlocks**:
```python
# BAD: Circular dependency
agent_a_waits_for(agent_b)
agent_b_waits_for(agent_a)  # Deadlock!

# GOOD: Use timeout
agent_a_waits_for(agent_b, timeout=30)
if not received:
    break_deadlock()
```

**Prevention**:
- Always use timeouts on waits
- Require acknowledgments for critical handoffs
- Implement retry logic with backoff
- Design acyclic coordination graphs
- Use monitoring to detect stuck agents

### 6. Performance Issues

**Problem**: Agents are too slow, blocking workflows and exceeding time/cost constraints.

**Symptoms**:
- Agent execution exceeds timeout
- High LLM token usage
- Slow tool invocations
- Resource exhaustion (memory, CPU)
- Cascading delays in multi-agent systems

**Example**:
```python
# BAD: Inefficient implementation
def analyze_project(project_path):
    for file in os.listdir(project_path):
        content = read_file(file)  # One at a time
        analysis = llm_call(f"Analyze: {content}")  # Separate LLM call per file!
        results.append(analysis)
```

**Solution**:
Optimize with batching, caching, and parallelization:

```python
# GOOD: Optimized implementation
def analyze_project(project_path):
    # Batch file reads
    files = glob_files(project_path, "*.py")
    contents = parallel_read(files)  # Read in parallel

    # Batch LLM calls
    batch_prompt = "Analyze these files:\n" + "\n---\n".join(contents)
    batch_analysis = llm_call(batch_prompt)  # Single LLM call

    # Cache results
    cache_results(project_path, batch_analysis)

    return batch_analysis
```

**Optimization Strategies**:

**1. Caching**:
```python
from functools import lru_cache

@lru_cache(maxsize=128)
def expensive_operation(key):
    return slow_computation(key)
```

**2. Parallel Execution**:
```python
from concurrent.futures import ThreadPoolExecutor

with ThreadPoolExecutor(max_workers=4) as executor:
    results = list(executor.map(process_file, files))
```

**3. Lazy Loading**:
```python
class Agent:
    def __init__(self):
        self._tools = None  # Don't initialize yet

    @property
    def tools(self):
        if self._tools is None:
            self._tools = self._initialize_tools()  # Initialize on first use
        return self._tools
```

**4. Token Optimization**:
```python
# BAD: Sending entire file
prompt = f"Analyze: {entire_file_content}"  # Could be 10k+ tokens

# GOOD: Send only relevant parts
relevant_sections = extract_relevant_sections(file_content)
prompt = f"Analyze: {relevant_sections}"  # <1k tokens
```

**Prevention**:
- Profile agent performance
- Set performance targets in specification
- Monitor token usage
- Use async I/O for network operations
- Batch operations when possible

### 7. Deployment Issues

**Problem**: Agent works in development but fails in production.

**Symptoms**:
- Environment differences (dev vs prod)
- Missing dependencies
- Permission errors
- Configuration issues
- Resource limits exceeded

**Example**:
```python
# BAD: Hardcoded paths
def read_config():
    return read_file("/home/dev/config.json")  # Breaks in production!
```

**Solution**:
Environment-aware configuration:

```python
# GOOD: Environment-based configuration
import os

def read_config():
    env = os.getenv("ENVIRONMENT", "development")
    config_path = os.getenv("CONFIG_PATH", f"/etc/agent/config.{env}.json")
    return read_file(config_path)
```

**Deployment Checklist**:
- [ ] All dependencies documented and versioned
- [ ] Environment variables configured
- [ ] Permissions validated
- [ ] Resource limits set (memory, CPU, disk)
- [ ] Logging configured
- [ ] Monitoring enabled
- [ ] Health check endpoint implemented
- [ ] Graceful shutdown implemented
- [ ] Secrets managed securely (not in code)

**Prevention**:
- Use containerization (Docker)
- Test in staging environment
- Use infrastructure as code
- Automate deployments
- Monitor after deployment

## Debugging Strategies

### 1. Agent Not Executing

**Symptoms**: Agent initializes but doesn't execute tasks

**Debug Steps**:
```python
# Check agent state
print(agent.lifecycle.state)  # Should be READY, not FAILED or UNINITIALIZED

# Check tool availability
for tool in agent.spec.tools:
    print(f"{tool.name}: {tool_available(tool.name)}")

# Check input validation
try:
    agent.validate_inputs(inputs)
except ValidationError as e:
    print(f"Input validation failed: {e}")

# Enable debug logging
logging.basicConfig(level=logging.DEBUG)
agent.execute(inputs)
```

### 2. Agent Produces Wrong Results

**Symptoms**: Agent completes but outputs are incorrect

**Debug Steps**:
```python
# Add intermediate logging
def execute(self, inputs):
    logger.debug(f"Inputs: {inputs}")

    step1_result = self.step1(inputs)
    logger.debug(f"Step 1 result: {step1_result}")

    step2_result = self.step2(step1_result)
    logger.debug(f"Step 2 result: {step2_result}")

    return step2_result

# Compare against expected workflow
expected_workflow = load_spec()["workflow"]
actual_workflow = extract_execution_trace(agent)
diff = compare_workflows(expected_workflow, actual_workflow)
```

### 3. Agent Times Out

**Symptoms**: Agent exceeds execution time limit

**Debug Steps**:
```python
import time

# Profile each step
def execute(self, inputs):
    start = time.time()

    step1_start = time.time()
    step1_result = self.step1(inputs)
    logger.info(f"Step 1 took {time.time() - step1_start}s")

    step2_start = time.time()
    step2_result = self.step2(step1_result)
    logger.info(f"Step 2 took {time.time() - step2_start}s")

    logger.info(f"Total: {time.time() - start}s")

# Identify bottleneck and optimize
```

### 4. Multi-Agent Coordination Fails

**Symptoms**: Agents don't communicate or get stuck

**Debug Steps**:
```python
# Enable coordination tracing
coordinator.enable_tracing()

# Check handoff status
for handoff_id, protocol in coordinator.active_handoffs.items():
    print(f"{handoff_id}: {protocol.status} (attempts: {protocol.attempts})")

# Check agent states
for agent_id in agents:
    state = get_agent_state(agent_id)
    print(f"{agent_id}: {state}")

# Visualize coordination graph
visualize_coordination(coordinator.handoff_history)
```

### 5. Agent Crashes

**Symptoms**: Agent terminates unexpectedly

**Debug Steps**:
```python
# Add comprehensive error handling
def execute(self, inputs):
    try:
        return self._execute_impl(inputs)
    except ToolError as e:
        logger.error(f"Tool error: {e}", exc_info=True)
        return {"status": "tool_error", "error": str(e)}
    except ValidationError as e:
        logger.error(f"Validation error: {e}", exc_info=True)
        return {"status": "validation_error", "error": str(e)}
    except Exception as e:
        logger.error(f"Unexpected error: {e}", exc_info=True)
        return {"status": "error", "error": str(e)}

# Check logs
grep "ERROR" agent.log
grep "CRITICAL" agent.log

# Check resource usage
monitor_resources(agent_id)
```

## Best Practices Summary

1. **Specification**: Complete all fields, validate before implementing
2. **Scope**: Keep agents focused (3-5 capabilities max)
3. **Tools**: Map capabilities systematically, validate availability
4. **Testing**: Test properties not exact outputs, use testing pyramid
5. **Coordination**: Use timeouts, acknowledgments, retries
6. **Performance**: Profile, optimize, cache
7. **Deployment**: Test in staging, use containers, monitor
8. **Debugging**: Enable logging, trace execution, profile performance

## Quick Reference: Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| `Agent not ready` | State is not READY | Check initialization logs, validate tools |
| `Tool not found` | Missing dependency | Install tool, update tool registry |
| `Validation failed` | Invalid inputs | Check input schema, validate before calling |
| `Timeout exceeded` | Execution too slow | Profile and optimize, increase timeout |
| `Handoff failed` | Coordination error | Check receiver agent, increase retries |
| `Resource limit exceeded` | Memory/CPU/disk full | Increase limits, optimize resource usage |
| `Permission denied` | Insufficient permissions | Check file/directory permissions |

## Getting Help

When troubleshooting fails:

1. **Check logs**: Enable DEBUG logging and review full execution trace
2. **Reproduce minimally**: Create minimal example that reproduces issue
3. **Review specification**: Ensure specification is complete and valid
4. **Test in isolation**: Test agent components individually
5. **Check dependencies**: Verify all tools and services available
6. **Monitor resources**: Check memory, CPU, disk usage
7. **Consult documentation**: Review PATTERNS.md and EXAMPLES.md
8. **Ask for help**: Provide specification, logs, and minimal reproduction

## Additional Resources

- **PATTERNS.md**: Implementation patterns for common scenarios
- **EXAMPLES.md**: Working code examples and use cases
- **KNOWLEDGE.md**: Agent architecture theory and concepts
- **REFERENCE.md**: API documentation and schemas
