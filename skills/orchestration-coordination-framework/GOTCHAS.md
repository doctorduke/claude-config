# Orchestration Gotchas and Troubleshooting

Common pitfalls when building orchestrated agent systems and how to avoid them.

## 1. Task Dependency Hell

**Problem:** Complex DAGs with many dependencies become unmaintainable.

**Solutions:**
- Group related tasks
- Use dynamic task generation
- Limit DAG depth to 3-4 levels
- Break into subdags

## 2. State Management Complexity

**Problem:** Losing track of workflow state across restarts.

**Solutions:**
- Use durable execution platforms (Temporal)
- Persist state externally
- Make tasks idempotent
- Use checkpointing

## 3. Retry Storms

**Problem:** Failed tasks retry simultaneously, overwhelming systems.

**Solutions:**
- Exponential backoff with jitter
- Circuit breakers
- Max retry limits
- Per-task backoff strategies

## 4. Resource Starvation

**Problem:** High-priority tasks blocked by low-priority tasks.

**Solutions:**
- Priority queues
- Separate worker pools
- Resource quotas
- Preemption

## 5. Zombie Workflows

**Problem:** Workflows stuck in limbo, never completing.

**Solutions:**
- Timeouts at every level
- Health checks
- Automatic cleanup
- Dead letter queues

## 6. Serialization Issues

**Problem:** Large data passed between tasks causes memory issues.

**Solutions:**
- Pass references (S3 URLs) not data
- Use streaming
- Implement chunking
- Compress data

## 7. Distributed Deadlocks

**Problem:** Tasks waiting for each other in circular dependency.

**Solutions:**
- DAG validation
- Timeout on locks
- Detect cycles before execution
- Resource ordering

## 8. Observability Blind Spots

**Problem:** Can't debug distributed failures.

**Solutions:**
- Distributed tracing (OpenTelemetry)
- Structured logging
- Correlation IDs
- Centralized logging

## 9. Clock Skew Issues

**Problem:** Different servers have different times.

**Solutions:**
- Use logical clocks (Lamport timestamps)
- NTP synchronization
- Use UTC everywhere
- Use relative time (durations)

## 10. Error Propagation

**Problem:** Errors don't bubble up correctly.

**Solutions:**
- Explicit error handling at every layer
- Error aggregation
- Circuit breakers
- Health endpoints
- Dead letter queues

See [EXAMPLES.md](./EXAMPLES.md) for code examples and [REFERENCE.md](./REFERENCE.md) for monitoring setup.
