# Circuit Breaker Pattern Implementation

## Overview

The circuit breaker pattern prevents cascading failures by failing fast when a service is experiencing issues. This implementation protects AI API calls and GitHub API calls from infinite retry loops and cascading failures.

## Architecture

### States

The circuit breaker operates in three states:

1. **CLOSED** (Normal Operation)
   - Requests flow through normally
   - Failures are counted
   - Transitions to OPEN when failure threshold is reached

2. **OPEN** (Failing Fast)
   - Requests fail immediately without attempting
   - Service is given time to recover
   - Transitions to HALF_OPEN after timeout period

3. **HALF_OPEN** (Testing Recovery)
   - Limited requests are allowed to test if service recovered
   - Success transitions to CLOSED
   - Failure immediately returns to OPEN

### State Diagram

```
        [failures >= threshold]
CLOSED -----------------------> OPEN
  ^                              |
  |                              | [timeout elapsed]
  |                              v
  |                         HALF_OPEN
  |                              |
  | [successes >= threshold]     |
  +------------------------------+
  |                              |
  |                              | [any failure]
  |                              v
  +--------------------------> OPEN
```

## Configuration

Circuit breaker behavior is controlled via environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `CB_FAILURE_THRESHOLD` | 5 | Number of failures before opening circuit |
| `CB_TIMEOUT` | 60 | Seconds circuit stays open before HALF_OPEN |
| `CB_HALF_OPEN_TIMEOUT` | 30 | Seconds to test in HALF_OPEN state |
| `CB_SUCCESS_THRESHOLD` | 2 | Consecutive successes needed to close from HALF_OPEN |
| `CB_STATE_DIR` | `/tmp/circuit_breakers` | Directory for state files |

### Example Configuration

```bash
# More aggressive circuit breaker
export CB_FAILURE_THRESHOLD=3
export CB_TIMEOUT=30
export CB_SUCCESS_THRESHOLD=1

# Conservative circuit breaker
export CB_FAILURE_THRESHOLD=10
export CB_TIMEOUT=120
export CB_SUCCESS_THRESHOLD=5
```

## Usage

### Basic Usage

```bash
# Source the library
source "scripts/lib/common.sh"

# Initialize circuit breaker for an endpoint
init_circuit_breaker "my_service"

# Execute command with circuit breaker protection
call_with_circuit_breaker "my_service" curl -s https://api.example.com/endpoint

# Check circuit state
if is_circuit_open "my_service"; then
    echo "Service is unavailable"
    exit 1
fi
```

### Protected Functions

The following functions are automatically protected by circuit breakers:

#### AI API Calls
- `call_ai_api()` - Protected per provider (ai_api_anthropic, ai_api_openai)

#### GitHub API Calls
- `get_pr_diff()`
- `get_pr_files()`
- `get_pr_metadata()`
- `post_pr_comment()`
- `post_pr_review()`

### Manual Circuit Breaker Control

```bash
# Get current state
state=$(get_circuit_state "endpoint_name")
echo "Circuit state: ${state}"

# Get detailed statistics
get_circuit_stats "endpoint_name"

# Reset circuit breaker (for testing or manual recovery)
reset_circuit_breaker "endpoint_name"

# Record success/failure manually
record_success "endpoint_name"
record_failure "endpoint_name"
```

## Implementation Details

### State Persistence

Circuit breaker state is persisted in files under `CB_STATE_DIR`:
- Each endpoint has a separate state file
- State files include: current state, failure count, success count, timestamps
- File locking prevents race conditions in concurrent scenarios

### State File Format

```bash
STATE=CLOSED
FAILURE_COUNT=0
SUCCESS_COUNT=0
FAILURE_THRESHOLD=5
TIMEOUT=60
LAST_FAILURE_TIME=0
OPEN_TIME=0
HALF_OPEN_TIME=0
```

### Locking Mechanism

- Uses directory-based locks for cross-process synchronization
- Lock timeout of 5 seconds prevents deadlocks
- Failed lock acquisitions fall back to safe defaults

## Integration Points

### 1. AI API Integration

```bash
# In call_ai_api()
local cb_endpoint="ai_api_${provider}"
init_circuit_breaker "${cb_endpoint}"

if is_circuit_open "${cb_endpoint}"; then
    log_error "Circuit breaker OPEN for ${cb_endpoint} - failing fast"
    return 1
fi

# ... perform API call ...

if [[ $? -eq 0 ]]; then
    record_success "${cb_endpoint}"
else
    record_failure "${cb_endpoint}"
fi
```

### 2. GitHub API Integration

```bash
# Wraps all gh CLI calls
call_with_circuit_breaker "github_api" gh pr diff "${pr_number}"
```

## Testing

Comprehensive test suite at `scripts/tests/test-circuit-breaker.sh`:

```bash
# Run all tests
./scripts/tests/test-circuit-breaker.sh

# Test coverage:
# 1. Circuit breaker initialization
# 2. CLOSED to OPEN transition
# 3. Fail fast when OPEN
# 4. OPEN to HALF_OPEN transition
# 5. HALF_OPEN to CLOSED recovery
# 6. HALF_OPEN to OPEN on failure
# 7. Multiple endpoints independently
# 8. Reset functionality
# 9. Success resets failure count
# 10. Integration with call_with_circuit_breaker
# 11. Concurrent access with locking
# 12. Statistics retrieval
```

## Performance Characteristics

### Overhead

- **State check**: ~5ms (includes file I/O and lock acquisition)
- **Success/failure recording**: ~10ms (includes file write)
- **Lock acquisition timeout**: 5 seconds (prevents deadlock)

### Scalability

- Multiple endpoints operate independently
- File-based state allows cross-process coordination
- Lock-free state reads when circuit is CLOSED

### Memory Usage

- Minimal: ~1KB per endpoint state file
- No in-memory state required
- Automatic cleanup on process termination

## Best Practices

### 1. Endpoint Granularity

```bash
# Good: Separate circuits per service
call_with_circuit_breaker "github_api" gh api ...
call_with_circuit_breaker "ai_api_anthropic" curl ...

# Bad: Single circuit for everything
call_with_circuit_breaker "api" any_command
```

### 2. Threshold Tuning

- Start conservative (higher thresholds)
- Monitor failure rates in production
- Adjust based on service SLAs

### 3. Timeout Configuration

- `CB_TIMEOUT`: Should match service recovery time
- `CB_HALF_OPEN_TIMEOUT`: Should be short (test window)
- `CB_SUCCESS_THRESHOLD`: Balance between confidence and responsiveness

### 4. Monitoring

```bash
# Regular health checks
for endpoint in github_api ai_api_anthropic; do
    get_circuit_stats "${endpoint}"
done
```

## Troubleshooting

### Circuit Stuck Open

```bash
# Check circuit state
get_circuit_stats "endpoint_name"

# Manual reset
reset_circuit_breaker "endpoint_name"
```

### High Failure Rate

```bash
# Increase threshold temporarily
export CB_FAILURE_THRESHOLD=10

# Or increase timeout
export CB_TIMEOUT=300
```

### Lock Contention

```bash
# Check for stale locks
ls -la /tmp/circuit_breakers/*.lock

# Remove stale locks (if process terminated abnormally)
rm -rf /tmp/circuit_breakers/*.lock
```

## Future Enhancements

1. **Metrics Export**: Export circuit breaker metrics to monitoring systems
2. **Adaptive Thresholds**: Automatically adjust thresholds based on error rates
3. **Health Checks**: Proactive health checks during OPEN state
4. **Bulkhead Pattern**: Limit concurrent requests per endpoint
5. **Fallback Strategies**: Configurable fallback behavior per endpoint

## References

- [Circuit Breaker Pattern - Martin Fowler](https://martinfowler.com/bliki/CircuitBreaker.html)
- [Release It! - Michael Nygard](https://pragprog.com/titles/mnee2/release-it-second-edition/)
- [Task #9 - TASKS-REMAINING.md](../TASKS-REMAINING.md)
