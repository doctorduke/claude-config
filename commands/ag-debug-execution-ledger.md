# 🔍 AG-DEBUG-EXECUTION-LEDGER

**Purpose**: Advanced debugging system that creates comprehensive execution traces with automated failure analysis, suspect frame identification, and deterministic replay capabilities.

**Technical Implementation**: Implements a distributed tracing system with privacy-preserving data collection, statistical bug localization, and automated reproduction generation.

## Core Debugging Framework

### 1. Trace Propagation & Capture

**Trace ID Generation**:
```typescript
interface TraceContext {
  trace_id: string;           // UUID4 for global trace identification
  span_id: string;           // UUID4 for current operation
  parent_span_id?: string;   // Parent operation linkage
  thread_id: string;         // Thread/async context identifier
  correlation_id?: string;   // Business correlation (RPC, user action)
}
```

**TRACEFRAME Emission**:
```typescript
interface TraceFrame {
  // Core identification
  trace_id: string;
  span_id: string;
  parent_span_id?: string;
  thread_id: string;

  // Location & timing
  file: string;              // Source file path
  line: number;              // Line number
  function: string;          // Function/method name
  timestamp: number;         // Unix timestamp (microseconds)
  duration?: number;         // Execution duration (microseconds)

  // Execution context
  event_type: 'entry' | 'exit' | 'exception' | 'invariant_check';
  args?: Record<string, any>;     // Function arguments (sanitized)
  return_value?: any;             // Return value (sanitized)
  exception?: ExceptionInfo;      // Exception details if applicable

  // Environment & invariants
  environment: EnvironmentSnapshot;
  invariant_status: 'pass' | 'fail' | 'unknown';
  invariant_checks: InvariantCheck[];

  // Data classification
  data_class: 'public' | 'internal' | 'confidential' | 'restricted';
  retention_ttl: number;     // TTL in seconds
}
```

**Serialization Format**: Line-delimited JSON (JSONL) for streaming processing and efficient parsing.

### 2. Privacy-Preserving Data Sanitization

**Sanitization Policy Engine**:
```typescript
interface SanitizationPolicy {
  // Secret masking patterns
  secret_patterns: RegExp[];           // e.g., /password|token|key|secret/i
  secret_replacement: string;          // e.g., "[REDACTED]"

  // Identifier tokenization
  sensitive_identifiers: {
    user_id: boolean;
    session_id: boolean;
    request_id: boolean;
    // ... configurable fields
  };

  // Field allowlisting
  safe_fields: string[];               // Always safe to log
  restricted_fields: string[];         // Never log (even sanitized)

  // Data classification rules
  classification_rules: ClassificationRule[];
}

interface ClassificationRule {
  field_path: string;                  // e.g., "user.email", "request.body"
  condition: (value: any) => boolean;  // Classification logic
  data_class: DataClass;
  retention_ttl: number;
}
```

**Sanitization Process**:
1. **Secret Detection**: Apply regex patterns to identify sensitive strings
2. **Identifier Tokenization**: Replace sensitive IDs with deterministic tokens
3. **Field Filtering**: Remove restricted fields, keep only allowlisted safe fields
4. **Data Classification**: Apply classification rules based on field content
5. **Retention Tagging**: Assign TTL based on data sensitivity

### 3. Error Analysis & Suspect Frame Detection

**Statistical Bug Localization (SBFL)**:
```typescript
interface SuspectFrame {
  file: string;
  line: number;
  function: string;
  suspicion_score: number;    // 0.0 to 1.0
  evidence: {
    failing_traces: number;   // How many failing traces hit this frame
    passing_traces: number;   // How many passing traces hit this frame
    failure_rate: number;     // failure_rate = failing / (failing + passing)
    suspiciousness: number;   // SBFL metric (e.g., Tarantula, Ochiai)
  };
  context: {
    recent_changes: CommitInfo[];
    complexity_metrics: ComplexityMetrics;
    test_coverage: CoverageInfo;
  };
}
```

**SBFL Algorithm Implementation**:
```typescript
function calculateSuspiciousness(failing: number, passing: number, totalFailing: number, totalPassing: number): number {
  // Tarantula formula
  const failRate = failing / totalFailing;
  const passRate = passing / totalPassing;
  const suspiciousness = failRate / (failRate + passRate);
  return suspiciousness;
}
```

### 4. Invariant Violation Detection

**Invariant Check System**:
```typescript
interface InvariantCheck {
  id: string;
  description: string;
  condition: (context: ExecutionContext) => boolean;
  severity: 'low' | 'medium' | 'high' | 'critical';
  expected_value?: any;
  observed_value?: any;
  violation_context: {
    variable_states: Record<string, any>;
    call_stack: string[];
    memory_usage: MemoryInfo;
  };
}
```

**First Violation Capture**:
- Stop trace collection after first invariant violation
- Capture complete frame context at violation point
- Generate expected vs observed comparison
- Preserve execution state for replay

### 5. Cost Management & Budget Controls

**Budget Configuration**:
```typescript
interface TraceBudget {
  max_trace_duration: number;      // Max trace time (seconds)
  max_frame_count: number;         // Max frames per trace
  max_field_size: number;          // Max field value size (bytes)
  max_total_size: number;          // Max total trace size (bytes)
  overhead_threshold: number;      // Max overhead percentage (0.0-1.0)
  early_stop_triggers: string[];   // Conditions for early termination
}
```

**Cost Control Mechanisms**:
1. **Field Truncation**: Large field values truncated with size indicators
2. **Early Termination**: Stop after first invariant violation or budget exceeded
3. **Metadata Fallback**: Switch to metadata-only mode if overhead too high
4. **Sampling**: Reduce trace frequency for high-volume operations

### 6. Output Format & Structure

**Standardized Output Order**:

#### A) NARRATIVE (5-line summary)
```
1. What operation was being performed when the error occurred
2. What specific error/exception was encountered
3. Which invariant was violated and why it matters
4. What the most likely root cause is based on suspect frames
5. What immediate action should be taken to resolve the issue
```

#### B) SUSPECT FRAMES TABLE
```markdown
| File:Line | Function | Suspicion | Evidence | Context |
|-----------|----------|-----------|----------|---------|
| auth.js:45 | validateToken | 0.89 | 12/15 failing, 2/15 passing | Recent auth refactor |
| db.js:123 | executeQuery | 0.76 | 8/15 failing, 1/15 passing | New query optimization |
```

#### C) TIMELINE (chronological frames)
```jsonl
{"timestamp": 1704067200000, "event": "entry", "function": "authenticateUser", "file": "auth.js", "line": 12}
{"timestamp": 1704067200100, "event": "invariant_check", "function": "validateToken", "file": "auth.js", "line": 45, "status": "fail"}
{"timestamp": 1704067200200, "event": "exception", "function": "authenticateUser", "file": "auth.js", "line": 12, "exception": "InvalidTokenError"}
```

#### D) FRAME DETAILS (on-demand)
```json
{
  "frame_id": "span_123",
  "file": "auth.js",
  "line": 45,
  "function": "validateToken",
  "args": {"token": "[REDACTED]", "options": {"strict": true}},
  "local_vars": {"isValid": false, "expiry": 1704067200000},
  "call_stack": ["authenticateUser", "validateToken", "jwt.verify"],
  "memory_snapshot": {...}
}
```

#### E) REPLAY COMMANDS
```bash
# Single-command reproduction
DEBUG_TRACE_ID=trace_456 DEBUG_REPLAY_MODE=true npm test -- --grep "authentication"

# Deterministic replay with captured state
DEBUG_REPLAY_STATE=state_789.json DEBUG_TRACE_ID=trace_456 node --inspect auth.js
```

#### F) PRIVACY REPORT
```markdown
## Data Sanitization Report

**Redactions Applied**:
- 15 password fields → [REDACTED]
- 8 API keys → [REDACTED]
- 3 user IDs → user_123, user_456, user_789

**Data Classification**:
- 45 frames classified as 'internal'
- 12 frames classified as 'confidential'
- 3 frames classified as 'restricted' (metadata only)

**Retention Applied**:
- Internal data: 30 days TTL
- Confidential data: 7 days TTL
- Restricted data: 1 day TTL
```

## Implementation Commands

### Basic Trace Collection
```bash
# Start trace collection for current process
/debug-trace-start --trace-id=auto --budget=standard

# Start trace with custom configuration
/debug-trace-start --trace-id=custom_123 --budget=high --sanitization=strict
```

### Error Analysis
```bash
# Analyze error from trace ID
/debug-analyze-error --trace-id=trace_456 --output=analysis.json

# Compare with nearest passing trace
/debug-compare-traces --failing=trace_456 --passing=trace_789
```

### Replay Generation
```bash
# Generate replay commands for trace
/debug-generate-replay --trace-id=trace_456 --output=replay.sh

# Execute deterministic replay
/debug-execute-replay --trace-id=trace_456 --state=state_789.json
```

### Privacy & Compliance
```bash
# Generate privacy report
/debug-privacy-report --trace-id=trace_456 --output=privacy.md

# Apply additional sanitization
/debug-sanitize-trace --trace-id=trace_456 --policy=gdpr_strict
```

## Configuration Examples

### Development Environment
```yaml
debug_execution_ledger:
  budget:
    max_trace_duration: 300
    max_frame_count: 1000
    max_field_size: 1024
    overhead_threshold: 0.05
  sanitization:
    secret_patterns: ["password", "token", "key", "secret"]
    safe_fields: ["timestamp", "function", "file", "line"]
    data_classification: "internal"
  output:
    format: "jsonl"
    include_timeline: true
    include_frame_details: false
```

### Production Environment
```yaml
debug_execution_ledger:
  budget:
    max_trace_duration: 60
    max_frame_count: 100
    max_field_size: 256
    overhead_threshold: 0.01
  sanitization:
    secret_patterns: ["password", "token", "key", "secret", "auth"]
    safe_fields: ["timestamp", "function", "file", "line", "event_type"]
    data_classification: "restricted"
  output:
    format: "metadata_only"
    include_timeline: false
    include_frame_details: false
```

## Integration Points

### Framework Integration
- **Node.js**: Async hooks for automatic trace propagation
- **React**: Error boundaries with trace context
- **Express**: Middleware for request-scoped tracing
- **Database**: Query-level trace instrumentation
- **RPC**: Distributed trace propagation headers

### CI/CD Integration
- **Test Failures**: Automatic trace collection on test failures
- **Build Errors**: Trace collection during build process
- **Deployment**: Trace collection for deployment validation
- **Monitoring**: Integration with APM tools

### Storage & Retrieval
- **Local Storage**: File-based trace storage for development
- **Cloud Storage**: S3/GCS for production trace archives
- **Database**: Structured storage for trace metadata
- **Search**: Elasticsearch for trace search and analysis

## Best Practices

### Trace Collection
- ✅ Start traces at operation boundaries (API calls, user actions)
- ✅ Use consistent trace ID propagation across async boundaries
- ✅ Set appropriate budgets based on operation criticality
- ❌ Don't trace high-frequency operations without sampling
- ❌ Don't collect traces in production without strict budgets

### Privacy & Security
- ✅ Always sanitize before storage or transmission
- ✅ Use appropriate data classification levels
- ✅ Implement proper retention policies
- ❌ Never log raw secrets or PII
- ❌ Don't store traces longer than necessary

### Analysis & Debugging
- ✅ Focus on suspect frames with highest suspicion scores
- ✅ Compare failing traces with recent passing traces
- ✅ Use invariant violations as debugging starting points
- ❌ Don't ignore low-suspicion frames without investigation
- ❌ Don't rely solely on automated analysis

### Performance
- ✅ Monitor overhead and adjust budgets accordingly
- ✅ Use early termination for invariant violations
- ✅ Implement sampling for high-volume operations
- ❌ Don't collect traces without performance impact assessment
- ❌ Don't ignore budget violations

## Troubleshooting

### Common Issues

**High Overhead**:
- Reduce trace budget (duration, frame count, field size)
- Enable early termination on first invariant violation
- Switch to metadata-only mode for high-frequency operations

**Missing Traces**:
- Check trace ID propagation across async boundaries
- Verify framework integration is properly configured
- Ensure trace collection is started before operation begins

**Privacy Violations**:
- Review sanitization policy configuration
- Check for new sensitive field patterns
- Verify data classification rules are comprehensive

**Analysis Failures**:
- Ensure sufficient passing traces for comparison
- Check suspect frame calculation logic
- Verify invariant definitions are correct

---

**Usage**: `/ag-debug-execution-ledger [command] [options]`

**Commands**: `start`, `analyze`, `compare`, `replay`, `sanitize`, `report`

**Examples**:
- `/ag-debug-execution-ledger start --budget=standard`
- `/ag-debug-execution-ledger analyze --trace-id=trace_123`
- `/ag-debug-execution-ledger replay --trace-id=trace_123 --generate-commands`




