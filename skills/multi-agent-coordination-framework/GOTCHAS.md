# Multi-Agent Coordination - Common Gotchas

[← Back to Main](./SKILL.md)

## Table of Contents

- [Top 10 Gotchas](#top-10-gotchas)
- [Debugging Strategies](#debugging-strategies)
- [Performance Issues](#performance-issues)
- [State Management Problems](#state-management-problems)
- [Communication Failures](#communication-failures)

## Top 10 Gotchas

### 1. Coordination Overhead

**Problem**: Too much agent communication slows everything down

**Symptoms**:
- High latency between agent calls
- Network/message queue saturation
- Agents spend more time communicating than working
- Total execution time exceeds sum of task times

**Root Causes**:
- Synchronous communication for all interactions
- Fine-grained message passing (chatty agents)
- No message batching
- Excessive status updates/heartbeats

**Solutions**:
1. **Batch Communications**: Group multiple messages together
   ```python
   # Bad: Send 100 individual messages
   for item in items:
       send_message(agent, item)

   # Good: Send one batched message
   send_message(agent, {"items": items})
   ```

2. **Use Async Patterns**: Don't wait for responses unless necessary
   ```python
   # Bad: Synchronous blocking
   result = agent.execute_task(task)  # Blocks until complete

   # Good: Async fire-and-forget
   await agent.execute_task_async(task)
   # Do other work while agent processes
   ```

3. **Minimize Chatter**: Only communicate when necessary
   - Reduce heartbeat frequency
   - Send status updates only on significant changes
   - Cache frequently accessed data

**Detection**:
- Monitor message count per second
- Track average message latency
- Calculate communication overhead percentage

### 2. Agent Deadlock

**Problem**: Agents waiting for each other in circular dependency

**Symptoms**:
- System hangs indefinitely
- All agents show "waiting" status
- No progress on tasks
- Circular dependency in agent state

**Root Causes**:
- Agent A waits for Agent B, Agent B waits for Agent A
- Resource locking without timeouts
- No deadlock detection

**Solutions**:
1. **Timeout Everything**: Never wait indefinitely
   ```python
   # Bad: Wait forever
   result = agent.call(other_agent, task)

   # Good: Timeout after 30s
   try:
       result = agent.call(other_agent, task, timeout=30)
   except TimeoutError:
       # Handle timeout, break deadlock
       result = default_value
   ```

2. **Detect Cycles**: Track dependency chains
   ```python
   def assign_task(agent, task, dependency_chain=[]):
       if agent in dependency_chain:
           raise DeadlockError(f"Circular dependency detected: {dependency_chain}")

       new_chain = dependency_chain + [agent]
       # Continue with assignment
   ```

3. **Use Coordinator**: Have a coordinator break deadlocks
   ```python
   coordinator = DeadlockCoordinator()
   coordinator.monitor_agents()
   if coordinator.detect_deadlock():
       coordinator.break_deadlock()  # Cancel lowest priority task
   ```

**Detection**:
- Trace agent state transitions
- Build dependency graph
- Look for cycles in wait graph

### 3. State Inconsistency

**Problem**: Agents have different views of shared state

**Symptoms**:
- Agent decisions based on stale data
- Conflicting actions from different agents
- Race conditions in state updates
- Eventual consistency never converges

**Root Causes**:
- Shared mutable state without synchronization
- Network delays in state propagation
- No versioning or conflict resolution
- Cache invalidation issues

**Solutions**:
1. **Event Sourcing**: Use immutable event log
   ```python
   # Bad: Shared mutable state
   shared_state.counter += 1

   # Good: Event sourcing
   event_store.append(Event(type="INCREMENT", agent_id=agent_id))
   current_state = event_store.replay_events()
   ```

2. **CRDTs**: Use conflict-free data structures
   ```python
   # Good: CRDT counter (no conflicts)
   crdt_counter = GCounter()
   crdt_counter.increment(agent_id, amount=1)
   # Merges automatically without conflicts
   ```

3. **Versioning**: Track state versions
   ```python
   def update_state(new_state, expected_version):
       if current_version != expected_version:
           raise ConflictError("State was modified by another agent")
       current_version += 1
       apply_update(new_state)
   ```

**Detection**:
- Compare agent state snapshots
- Check for divergence over time
- Monitor conflict rate

### 4. Resource Contention

**Problem**: Multiple agents competing for same resources

**Symptoms**:
- Task failures due to resource unavailability
- Agents repeatedly retrying same resource
- Starvation (some agents never get resources)
- Thrashing (constant resource acquisition/release)

**Root Causes**:
- No resource reservation system
- Greedy resource allocation
- No priority system
- No fairness guarantees

**Solutions**:
1. **Resource Pools**: Use managed resource pools
   ```python
   resource_pool = ResourcePool(max_size=10)

   with resource_pool.acquire(timeout=5) as resource:
       agent.use_resource(resource)
   # Resource automatically released
   ```

2. **Priority Queues**: Prioritize resource requests
   ```python
   resource_queue = PriorityQueue()
   resource_queue.request(agent_id, priority=HIGH)
   resource = resource_queue.wait_for_resource()
   ```

3. **Fairness Policies**: Ensure all agents get resources
   ```python
   # Round-robin allocation
   allocator = FairResourceAllocator(policy="round_robin")
   resource = allocator.allocate(agent_id)
   ```

**Detection**:
- Monitor resource utilization
- Track wait times per agent
- Check for starvation patterns

### 5. Agent Personality Conflicts

**Problem**: Different agent prompts/behaviors clash

**Symptoms**:
- Agents disagree on interpretation of tasks
- Communication breakdowns
- Unexpected agent responses
- Incompatible output formats

**Root Causes**:
- Inconsistent system prompts
- No standardized communication protocol
- Agents optimized for different objectives
- Version mismatches in agent code

**Solutions**:
1. **Standardize Protocols**: Define explicit communication contracts
   ```python
   class AgentMessage:
       sender: str
       receiver: str
       message_type: MessageType
       payload: dict
       schema_version: str = "1.0"
   ```

2. **Explicit Handoff Contracts**: Define what each agent expects
   ```python
   @handoff_contract(
       input_schema={"task": str, "context": dict},
       output_schema={"result": str, "confidence": float}
   )
   def agent_task(input_data):
       # Agent implementation
       pass
   ```

3. **Agent Capability Registry**: Match agents to tasks
   ```python
   registry = AgentRegistry()
   registry.register(agent_id="analyzer", capabilities=["code_analysis"])

   # Route task to compatible agent
   agent = registry.find_agent(capability="code_analysis")
   ```

**Detection**:
- Monitor agent conversation logs
- Check for parsing errors
- Track incompatibility issues

### 6. Cascading Failures

**Problem**: One agent failure brings down entire system

**Symptoms**:
- Single agent failure stops all work
- Error propagates through agent chain
- System cannot recover from partial failures
- No graceful degradation

**Root Causes**:
- No error isolation
- Tight coupling between agents
- No fallback mechanisms
- Missing circuit breakers

**Solutions**:
1. **Circuit Breakers**: Stop calling failing agents
   ```python
   circuit_breaker = CircuitBreaker(
       failure_threshold=5,
       timeout=60
   )

   @circuit_breaker.protected
   def call_agent(agent, task):
       return agent.execute(task)
   ```

2. **Bulkheads**: Isolate failure domains
   ```python
   # Separate thread pools per agent type
   analyzer_pool = ThreadPool(max_workers=5)
   writer_pool = ThreadPool(max_workers=5)

   # Analyzer failures don't affect writers
   ```

3. **Graceful Degradation**: Provide fallbacks
   ```python
   try:
       result = primary_agent.execute(task)
   except AgentFailure:
       logger.warning("Primary agent failed, using fallback")
       result = fallback_agent.execute(task)
   ```

**Detection**:
- Monitor agent failure rates
- Track cascading failure patterns
- Check system availability

### 7. Observation Interference

**Problem**: Observability tools overwhelm the system

**Symptoms**:
- High overhead from logging/tracing
- Agent performance degrades with observability enabled
- Log storage fills rapidly
- Network saturated with telemetry

**Root Causes**:
- Synchronous logging blocking agent execution
- Too much detail in logs
- No sampling/rate limiting
- Expensive distributed tracing

**Solutions**:
1. **Async Logging**: Don't block on log writes
   ```python
   # Bad: Synchronous logging
   logger.info(f"Agent {agent_id} completed task")

   # Good: Async logging
   async_logger.info(f"Agent {agent_id} completed task")
   ```

2. **Sampling**: Only trace subset of requests
   ```python
   tracer = DistributedTracer(sample_rate=0.1)  # 10% sampling
   if tracer.should_trace():
       with tracer.span("agent_execution"):
           agent.execute(task)
   ```

3. **Rate Limiting**: Limit telemetry volume
   ```python
   @rate_limited(max_per_second=100)
   def log_agent_status(agent_id, status):
       logger.info(f"{agent_id}: {status}")
   ```

**Detection**:
- Compare performance with/without observability
- Monitor log volume
- Check telemetry overhead percentage

### 8. Byzantine Agents

**Problem**: Malicious or faulty agents give bad information

**Symptoms**:
- Incorrect results from agent consensus
- System makes bad decisions
- Some agents consistently provide wrong answers
- Sabotage or corruption of shared state

**Root Causes**:
- No validation of agent responses
- Blind trust in all agents
- No reputation system
- No Byzantine fault tolerance

**Solutions**:
1. **Voting Mechanisms**: Require multiple agents to agree
   ```python
   results = [agent.execute(task) for agent in agents]

   # Require supermajority (2/3)
   consensus = vote_with_threshold(results, threshold=0.66)
   ```

2. **Reputation Systems**: Track agent reliability
   ```python
   reputation = ReputationSystem()
   reputation.record_outcome(agent_id, success=True)

   # Weight votes by reputation
   trusted_agents = reputation.get_top_agents(percentile=0.8)
   ```

3. **Validation Layers**: Verify agent outputs
   ```python
   def validate_agent_response(response, schema):
       if not schema.validate(response):
           raise InvalidResponseError("Agent response failed validation")
       return response
   ```

**Detection**:
- Compare agent responses
- Track accuracy per agent
- Identify outliers

### 9. Agent Explosion

**Problem**: Creating too many agents for simple tasks

**Symptoms**:
- Hundreds of agents doing trivial work
- High overhead from agent management
- Complexity obscures simple logic
- Debugging becomes difficult

**Root Causes**:
- Over-engineering simple problems
- Creating agent per task instead of agent per capability
- Premature optimization
- Misunderstanding agent granularity

**Solutions**:
1. **Start with Single Agent**: Add agents only when needed
   ```python
   # Bad: 5 agents for simple task
   agents = [ReaderAgent(), ParserAgent(), ValidatorAgent(),
             ProcessorAgent(), WriterAgent()]

   # Good: 1 agent for simple task
   agent = DataProcessingAgent()
   result = agent.process(data)
   ```

2. **Merge Redundant Agents**: Combine similar capabilities
   ```python
   # Bad: Separate agents for similar tasks
   json_parser = JSONParserAgent()
   xml_parser = XMLParserAgent()

   # Good: One agent with multiple formats
   parser = ParserAgent(formats=["json", "xml"])
   ```

3. **Appropriate Granularity**: Agent per capability, not per task
   ```python
   # Good: Capability-based agents
   agents = {
       "analysis": AnalysisAgent(),
       "synthesis": SynthesisAgent(),
       "execution": ExecutionAgent()
   }
   ```

**Detection**:
- Count active agents
- Measure agent utilization
- Review agent responsibilities

### 10. Communication Protocol Drift

**Problem**: Agents stop understanding each other

**Symptoms**:
- Parser errors in agent communication
- Agents sending unexpected message formats
- Version incompatibility
- Broken message routing

**Root Causes**:
- No schema versioning
- Ad-hoc message format evolution
- Incompatible agent updates
- No backward compatibility

**Solutions**:
1. **Schema Validation**: Enforce message schemas
   ```python
   message_schema = {
       "type": "object",
       "properties": {
           "sender": {"type": "string"},
           "payload": {"type": "object"}
       },
       "required": ["sender", "payload"]
   }

   validate(message, message_schema)
   ```

2. **Versioned Protocols**: Support multiple versions
   ```python
   if message.version == "1.0":
       handle_v1(message)
   elif message.version == "2.0":
       handle_v2(message)
   else:
       raise UnsupportedVersionError(message.version)
   ```

3. **Backward Compatibility**: Support old formats
   ```python
   def parse_message(message):
       if "new_field" in message:
           # V2 format
           return parse_v2(message)
       else:
           # V1 format (backward compatible)
           return parse_v1(message)
   ```

**Detection**:
- Monitor parsing errors
- Track schema version distribution
- Check compatibility matrix

## Debugging Strategies

### Distributed Tracing

Trace requests across multiple agents:

```python
from opentelemetry import trace

tracer = trace.get_tracer(__name__)

def agent_execute(agent_id, task, parent_span_context=None):
    with tracer.start_as_current_span(
        f"agent_{agent_id}_execute",
        context=parent_span_context
    ) as span:
        span.set_attribute("agent.id", agent_id)
        span.set_attribute("task.id", task.id)

        result = execute_task(task)

        span.set_attribute("result.status", "success")
        return result
```

### Agent Conversation Logging

Log all agent-to-agent communications:

```python
class ConversationLogger:
    def log_message(self, from_agent, to_agent, message, timestamp):
        log_entry = {
            "from": from_agent,
            "to": to_agent,
            "message": message,
            "timestamp": timestamp
        }
        self.write_log(log_entry)

    def replay_conversation(self, agent_id):
        # Replay all messages for debugging
        return self.get_messages(agent_id=agent_id)
```

### State Snapshot Comparison

Compare agent state over time:

```python
def snapshot_state(agents):
    return {
        agent_id: agent.get_state()
        for agent_id, agent in agents.items()
    }

snapshot_1 = snapshot_state(agents)
# ... agents execute tasks ...
snapshot_2 = snapshot_state(agents)

diff = compare_snapshots(snapshot_1, snapshot_2)
```

### Agent Performance Profiling

Profile individual agent performance:

```python
import cProfile
import pstats

profiler = cProfile.Profile()
profiler.enable()

agent.execute_task(task)

profiler.disable()
stats = pstats.Stats(profiler)
stats.sort_stats('cumulative')
stats.print_stats(20)  # Top 20 slowest functions
```

## Performance Issues

### High Latency

**Symptoms**: Slow agent response times

**Solutions**:
- Use async/await for I/O operations
- Implement caching for repeated queries
- Batch requests where possible
- Profile and optimize slow agents

### Memory Leaks

**Symptoms**: Memory usage grows over time

**Solutions**:
- Properly cleanup agent resources
- Use weak references for agent registries
- Implement agent lifecycle management
- Monitor memory per agent

### CPU Saturation

**Symptoms**: High CPU usage, slow processing

**Solutions**:
- Limit concurrent agents
- Use process pools for CPU-intensive work
- Implement backpressure mechanisms
- Scale horizontally

## State Management Problems

### Lost Updates

**Problem**: Agent updates overwrite each other

**Solution**: Optimistic locking with versioning

```python
def update_state(agent_id, new_value, expected_version):
    current = get_state()
    if current.version != expected_version:
        raise ConcurrentModificationError()

    current.value = new_value
    current.version += 1
    save_state(current)
```

### Stale Reads

**Problem**: Agents read old state

**Solution**: Read-after-write consistency

```python
def write_then_read(agent_id, value):
    write_state(agent_id, value)

    # Ensure read comes from same replica
    state = read_state(agent_id, consistency="strong")
    return state
```

## Communication Failures

### Message Loss

**Problem**: Messages don't reach destination

**Solutions**:
- Implement at-least-once delivery
- Use message queues with persistence
- Add acknowledgments and retries

### Network Partitions

**Problem**: Agents can't reach each other

**Solutions**:
- Implement partition detection
- Use consensus algorithms (Raft, Paxos)
- Graceful degradation on partition

---

[← Back to Main](./SKILL.md) | [View Patterns →](./PATTERNS.md)
