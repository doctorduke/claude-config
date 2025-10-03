# Agent Communication Protocols Specification

## Message Format Standards

### Base Message Structure

```typescript
interface AgentMessage {
  id: string;                   // UUID v4
  timestamp: Date;              // ISO 8601 format
  from: string;                 // Sender agent ID
  to: string;                   // Recipient agent ID
  type: MessageType;            // Message type enum
  payload: any;                 // Type-specific payload
  metadata: MessageMetadata;    // Additional context
}

interface MessageMetadata {
  correlation_id?: string;      // Links related messages
  priority: 'low' | 'normal' | 'high' | 'critical';
  ttl_ms?: number;             // Time to live
  retry_count: number;         // Current retry attempt
  max_retries: number;         // Maximum retry attempts
}
```

### Message Types

```typescript
enum MessageType {
  TASK_ASSIGNMENT = 'TASK_ASSIGNMENT',
  TASK_HANDOFF = 'TASK_HANDOFF',
  TASK_UPDATE = 'TASK_UPDATE',
  TASK_COMPLETE = 'TASK_COMPLETE',
  TASK_FAILED = 'TASK_FAILED',
  HELP_REQUEST = 'HELP_REQUEST',
  HELP_RESPONSE = 'HELP_RESPONSE',
  STATUS_UPDATE = 'STATUS_UPDATE',
  HEARTBEAT = 'HEARTBEAT',
  ERROR_REPORT = 'ERROR_REPORT'
}
```

## Task Handoff Protocol

### Handoff Request Format

```typescript
interface TaskHandoffRequest {
  task_id: string;
  from_agent: string;
  to_agent: string;
  reason: HandoffReason;
  context: TaskContext;
  constraints: TaskConstraints;
  deadline: Date;
}

enum HandoffReason {
  CAPABILITY_LIMIT = 'CAPABILITY_LIMIT',
  RATE_LIMIT = 'RATE_LIMIT',
  ERROR_RECOVERY = 'ERROR_RECOVERY',
  ESCALATION = 'ESCALATION',
  LOAD_BALANCING = 'LOAD_BALANCING'
}
```

### Handoff Response Format

```typescript
interface TaskHandoffResponse {
  accepted: boolean;
  agent_id: string;
  estimated_completion: Date;
  requirements: string[];
  constraints: TaskConstraints;
  error?: string;
}
```

## Help Request Protocol

### Help Request Format

```typescript
interface HelpRequest {
  requester_id: string;
  task_id: string;
  help_type: HelpType;
  description: string;
  context: {
    current_state: string;
    error_details?: string;
    attempted_solutions: string[];
  };
  urgency: 'low' | 'medium' | 'high' | 'critical';
  deadline?: Date;
}

enum HelpType {
  TECHNICAL_GUIDANCE = 'TECHNICAL_GUIDANCE',
  DEBUGGING_ASSISTANCE = 'DEBUGGING_ASSISTANCE',
  CODE_REVIEW = 'CODE_REVIEW',
  ARCHITECTURE_ADVICE = 'ARCHITECTURE_ADVICE',
  RESOURCE_SHARING = 'RESOURCE_SHARING'
}
```

### Help Response Format

```typescript
interface HelpResponse {
  responder_id: string;
  request_id: string;
  response_type: HelpResponseType;
  content: string;
  resources?: ResourceReference[];
  follow_up_required: boolean;
  estimated_effort: number; // in minutes
}

enum HelpResponseType {
  DIRECT_ANSWER = 'DIRECT_ANSWER',
  RESOURCE_PROVISION = 'RESOURCE_PROVISION',
  COLLABORATIVE_SESSION = 'COLLABORATIVE_SESSION',
  ESCALATION = 'ESCALATION',
  UNABLE_TO_HELP = 'UNABLE_TO_HELP'
}
```

## Status Update Protocol

### Status Update Format

```typescript
interface StatusUpdate {
  agent_id: string;
  status: AgentStatus;
  current_tasks: string[];
  resource_usage: ResourceUsage;
  health_metrics: HealthMetrics;
  next_available?: Date;
}

interface AgentStatus {
  state: AgentState;
  capability_level: number;     // 0-100
  error_rate: number;          // 0-1
  avg_response_time_ms: number;
  last_heartbeat: Date;
}

interface ResourceUsage {
  tokens_used: number;
  tokens_remaining: number;
  cost_usd: number;
  cpu_usage: number;           // 0-100
  memory_usage: number;        // 0-100
}

interface HealthMetrics {
  uptime_seconds: number;
  success_rate: number;        // 0-1
  avg_latency_ms: number;
  error_count: number;
  last_error?: Date;
}

enum AgentState {
  IDLE = 'IDLE',
  BUSY = 'BUSY',
  ERROR = 'ERROR',
  OFFLINE = 'OFFLINE',
  MAINTENANCE = 'MAINTENANCE'
}

interface TaskContext {
  task_id: string;
  task_type: string;
  priority: 'low' | 'normal' | 'high' | 'critical';
  metadata: Record<string, any>;
  dependencies: string[];
  history: TaskEvent[];
}

interface TaskConstraints {
  max_tokens?: number;
  deadline?: Date;
  required_capabilities: string[];
  budget_usd?: number;
  quality_threshold?: number;
}

interface ResourceReference {
  type: 'documentation' | 'code' | 'api' | 'example' | 'tool';
  url: string;
  title: string;
  description?: string;
}

interface TaskEvent {
  timestamp: Date;
  event_type: string;
  agent_id?: string;
  details: Record<string, any>;
}
```

## Error Reporting Protocol

### Error Report Format

```typescript
interface ErrorReport {
  error_id: string;
  agent_id: string;
  task_id?: string;
  error_type: ErrorType;
  severity: 'low' | 'medium' | 'high' | 'critical';
  message: string;
  stack_trace?: string;
  context: {
    input_data?: any;
    configuration?: any;
    environment?: any;
  };
  recovery_attempts: RecoveryAttempt[];
  suggested_actions: string[];
}

enum ErrorType {
  TIMEOUT = 'TIMEOUT',
  RATE_LIMIT = 'RATE_LIMIT',
  VALIDATION_ERROR = 'VALIDATION_ERROR',
  NETWORK_ERROR = 'NETWORK_ERROR',
  AUTHENTICATION_ERROR = 'AUTHENTICATION_ERROR',
  RESOURCE_EXHAUSTED = 'RESOURCE_EXHAUSTED',
  INTERNAL_ERROR = 'INTERNAL_ERROR',
  EXTERNAL_SERVICE_ERROR = 'EXTERNAL_SERVICE_ERROR'
}

interface RecoveryAttempt {
  attempt_number: number;
  timestamp: Date;
  strategy: string;
  outcome: 'success' | 'failure' | 'partial';
  details: string;
}
```

## Message Routing Rules

### Routing Priority

1. **Critical** - Error reports, system failures
2. **High** - Task handoffs, help requests
3. **Normal** - Status updates, task progress
4. **Low** - Heartbeats, routine communications

### Message Delivery Guarantees

- **At-least-once** delivery for critical and high priority messages
- **At-most-once** delivery for normal and low priority messages
- **Ordered** delivery within the same task context
- **Timeout** handling with exponential backoff

### Retry Logic

```typescript
interface RetryConfig {
  max_attempts: number;
  base_delay_ms: number;
  max_delay_ms: number;
  backoff_multiplier: number;
  jitter: boolean;
}
```

## Shared State Management

### State Synchronization

```typescript
interface SharedState {
  task_registry: Map<string, TaskState>;
  agent_registry: Map<string, AgentStatus>;
  resource_allocations: Map<string, ResourceAllocation>;
  policy_state: PolicyState;
  last_updated: Date;
}

interface TaskState {
  id: string;
  status: 'pending' | 'in_progress' | 'completed' | 'failed' | 'cancelled';
  assigned_agent?: string;
  created_at: Date;
  updated_at: Date;
  context: TaskContext;
  result?: any;
  error?: ErrorReport;
}

interface ResourceAllocation {
  agent_id: string;
  resource_type: 'tokens' | 'cpu' | 'memory' | 'budget';
  allocated: number;
  consumed: number;
  limit: number;
  expires_at?: Date;
}

interface PolicyState {
  version: string;
  enabled_chains: string[];
  risk_thresholds: {
    low: number;
    high: number;
  };
  budget_limits: {
    per_task: number;
    per_agent: number;
    total: number;
  };
  circuit_breaker_config: {
    error_threshold: number;
    timeout_ms: number;
    reset_timeout_ms: number;
  };
}
```

### State Update Protocol

```typescript
interface StateUpdate {
  operation: 'CREATE' | 'UPDATE' | 'DELETE';
  entity_type: 'TASK' | 'AGENT' | 'RESOURCE' | 'POLICY';
  entity_id: string;
  changes: Record<string, any>;
  version: number;
  timestamp: Date;
}
```
