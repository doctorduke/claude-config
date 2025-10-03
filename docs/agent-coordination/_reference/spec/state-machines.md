# Agent State Machines Specification

## Task State Machine

### Core States

```typescript
enum TaskState {
  QUEUED = 'QUEUED',           // Initial state, waiting for routing
  ROUTED = 'ROUTED',           // Assigned to specific agent
  RUNNING = 'RUNNING',         // Agent actively processing
  REVIEW = 'REVIEW',           // Awaiting review/validation
  FAILED = 'FAILED',           // Failed with retryable error
  BLOCKED = 'BLOCKED',         // Blocked by policy or dependency
  FALLBACK = 'FALLBACK',       // Escalated to fallback agent
  DRAFT_PR = 'DRAFT_PR',       // Changes ready for PR
  REVIEW_CHAIN = 'REVIEW_CHAIN', // In review chain
  APPROVED = 'APPROVED',       // Approved for merge
  CHANGES_REQUESTED = 'CHANGES_REQUESTED', // Needs changes
  MERGED = 'MERGED',           // Successfully merged
  CANARY = 'CANARY',           // Deployed to canary
  ROLLED_BACK = 'ROLLED_BACK', // Rolled back due to issues
  STABLE = 'STABLE'            // Stable in production
}
```

### State Transition Rules

```typescript
const VALID_TRANSITIONS: Record<TaskState, TaskState[]> = {
  QUEUED: [ROUTED, BLOCKED],
  ROUTED: [RUNNING, BLOCKED],
  RUNNING: [REVIEW, FAILED, BLOCKED],
  REVIEW: [APPROVED, CHANGES_REQUESTED, FAILED, BLOCKED],
  FAILED: [RUNNING, FALLBACK, BLOCKED],
  BLOCKED: [QUEUED, RUNNING],
  FALLBACK: [RUNNING, REVIEW, FAILED, BLOCKED],
  DRAFT_PR: [REVIEW_CHAIN, FAILED],
  REVIEW_CHAIN: [APPROVED, CHANGES_REQUESTED, FAILED],
  APPROVED: [MERGED, FAILED],
  CHANGES_REQUESTED: [RUNNING, FAILED],
  MERGED: [CANARY, FAILED],
  CANARY: [STABLE, ROLLED_BACK],
  ROLLED_BACK: [STABLE, FAILED],
  STABLE: [] // Terminal state
};
```

### Guard Conditions

```typescript
interface StateGuard {
  quota_ok: boolean;           // Token budget available
  policy_ok: boolean;          // Policy rules satisfied
  tests_ok: boolean;           // All tests passing
  risk_score_ok: boolean;      // Risk within threshold
  time_budget_ok: boolean;     // Timeout not exceeded
  dependencies_met: boolean;   // All dependencies complete
}
```

## Agent Coordination State Machine

### Agent States

```typescript
enum AgentState {
  IDLE = 'IDLE',               // Available for new tasks
  BUSY = 'BUSY',               // Processing current task
  RATE_LIMITED = 'RATE_LIMITED', // Hit rate limits
  CIRCUIT_OPEN = 'CIRCUIT_OPEN', // Circuit breaker open
  MAINTENANCE = 'MAINTENANCE',  // Scheduled maintenance
  ERROR = 'ERROR'              // Error state requiring intervention
}
```

### Agent State Transitions

```typescript
const AGENT_TRANSITIONS: Record<AgentState, AgentState[]> = {
  IDLE: [BUSY, MAINTENANCE],
  BUSY: [IDLE, RATE_LIMITED, CIRCUIT_OPEN, ERROR],
  RATE_LIMITED: [IDLE, BUSY],
  CIRCUIT_OPEN: [IDLE, MAINTENANCE],
  MAINTENANCE: [IDLE],
  ERROR: [IDLE, MAINTENANCE]
};
```

## Workflow State Machine

### Workflow Phases

```typescript
enum WorkflowPhase {
  INITIALIZATION = 'INITIALIZATION',   // Setting up workflow
  TASK_CREATION = 'TASK_CREATION',     // Creating tasks
  EXECUTION = 'EXECUTION',             // Running tasks
  VALIDATION = 'VALIDATION',           // Validating results
  INTEGRATION = 'INTEGRATION',         // Integrating changes
  COMPLETION = 'COMPLETION'            // Workflow complete
}
```

### Phase Transitions

```typescript
const WORKFLOW_TRANSITIONS: Record<WorkflowPhase, WorkflowPhase[]> = {
  INITIALIZATION: [TASK_CREATION, COMPLETION],
  TASK_CREATION: [EXECUTION, COMPLETION],
  EXECUTION: [VALIDATION, COMPLETION],
  VALIDATION: [INTEGRATION, EXECUTION, COMPLETION],
  INTEGRATION: [COMPLETION],
  COMPLETION: [] // Terminal state
};
```

## Error Recovery State Machine

### Error Types

```typescript
enum ErrorType {
  TRANSIENT = 'TRANSIENT',     // Temporary, retryable
  RATE_LIMIT = 'RATE_LIMIT',   // Rate limit exceeded
  QUOTA_EXCEEDED = 'QUOTA_EXCEEDED', // Budget exceeded
  POLICY_VIOLATION = 'POLICY_VIOLATION', // Policy violation
  DEPENDENCY_FAILED = 'DEPENDENCY_FAILED', // Dependency failed
  CRITICAL = 'CRITICAL'        // Critical, requires intervention
}
```

### Recovery Actions

```typescript
const RECOVERY_ACTIONS: Record<ErrorType, string[]> = {
  TRANSIENT: ['retry', 'fallback_agent', 'escalate'],
  RATE_LIMIT: ['wait', 'fallback_agent'],
  QUOTA_EXCEEDED: ['escalate', 'reduce_scope'],
  POLICY_VIOLATION: ['escalate', 'human_review'],
  DEPENDENCY_FAILED: ['wait', 'escalate'],
  CRITICAL: ['escalate', 'human_intervention']
};
```
