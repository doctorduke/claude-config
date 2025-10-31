# Event Flow Diagrams
## Self-Hosted GitHub Actions AI Agent System - Wave 1

---

## Table of Contents
1. [System Overview](#system-overview)
2. [Event Routing Flow](#event-routing-flow)
3. [PR Review Workflow Flow](#pr-review-workflow-flow)
4. [Issue Auto-Response Flow](#issue-auto-response-flow)
5. [Code Auto-Fix Flow](#code-auto-fix-flow)
6. [Error Handling Flow](#error-handling-flow)
7. [Rate Limit Handling Flow](#rate-limit-handling-flow)
8. [Job Queue Management](#job-queue-management)

---

## System Overview

### High-Level Architecture

```mermaid
graph TB
    subgraph "GitHub Events"
        PR[Pull Request Event]
        ISSUE[Issue Event]
        COMMENT[Comment Event]
        PUSH[Push Event]
        DISPATCH[Workflow Dispatch]
    end

    subgraph "Event Router"
        FILTER{Event Filter}
        LABEL{Label Matcher}
    end

    subgraph "Runner Pool"
        R1[Runner 1<br/>self-hosted, linux, ai-agent]
        R2[Runner 2<br/>self-hosted, linux, ai-agent]
        R3[Runner N<br/>self-hosted, linux, ai-agent]
    end

    subgraph "Workflow Execution"
        WF1[PR Review Workflow]
        WF2[Issue Response Workflow]
        WF3[Code Fix Workflow]
        WF4[Other Workflows]
    end

    subgraph "External Services"
        GH_API[GitHub API]
        AI_API[AI/LLM API]
        GIT[Git Operations]
    end

    PR --> FILTER
    ISSUE --> FILTER
    COMMENT --> FILTER
    PUSH --> FILTER
    DISPATCH --> FILTER

    FILTER --> LABEL
    LABEL --> R1
    LABEL --> R2
    LABEL --> R3

    R1 --> WF1
    R1 --> WF2
    R1 --> WF3
    R2 --> WF1
    R2 --> WF2
    R2 --> WF3
    R3 --> WF4

    WF1 --> GH_API
    WF1 --> AI_API
    WF1 --> GIT

    WF2 --> GH_API
    WF2 --> AI_API

    WF3 --> GH_API
    WF3 --> AI_API
    WF3 --> GIT
```

---

## Event Routing Flow

### Event-to-Workflow Routing

```mermaid
flowchart TD
    START([GitHub Event Received]) --> EVENT_TYPE{Event Type?}

    EVENT_TYPE -->|pull_request| PR_TYPE{PR Action Type?}
    EVENT_TYPE -->|issues| ISSUE_TYPE{Issue Action?}
    EVENT_TYPE -->|issue_comment| COMMENT_CHECK{Check Comment}
    EVENT_TYPE -->|push| PUSH_BRANCH{Branch Name?}
    EVENT_TYPE -->|workflow_dispatch| DISPATCH_INPUT{Input Parameters}

    PR_TYPE -->|opened| PR_FILTER
    PR_TYPE -->|synchronize| PR_FILTER
    PR_TYPE -->|reopened| PR_FILTER
    PR_TYPE -->|labeled| CHECK_LABEL{Label Name?}
    PR_TYPE -->|other| SKIP[Skip - No Action]

    CHECK_LABEL -->|auto-fix| CODE_FIX_WF
    CHECK_LABEL -->|needs-review| PR_REVIEW_WF
    CHECK_LABEL -->|other| SKIP

    PR_FILTER[Filter by Paths] --> PATH_CHECK{Source Code<br/>Changed?}
    PATH_CHECK -->|Yes| LABEL_MATCH
    PATH_CHECK -->|No| SKIP

    LABEL_MATCH{Runner Labels<br/>Available?} -->|Yes| PR_REVIEW_WF[PR Review Workflow]
    LABEL_MATCH -->|No| QUEUE[Add to Queue]

    ISSUE_TYPE -->|opened| ISSUE_FILTER
    ISSUE_TYPE -->|labeled| ISSUE_LABEL_CHECK{Has 'ai-assist'<br/>label?}
    ISSUE_TYPE -->|other| SKIP

    ISSUE_LABEL_CHECK -->|Yes| ISSUE_RESPOND_WF
    ISSUE_LABEL_CHECK -->|No| SKIP

    ISSUE_FILTER[Check Issue Labels] --> HAS_AI_LABEL{Has 'ai-assist'?}
    HAS_AI_LABEL -->|Yes| ISSUE_RESPOND_WF[Issue Response Workflow]
    HAS_AI_LABEL -->|No| SKIP

    COMMENT_CHECK --> IS_BOT{Is Bot<br/>Mention?}
    IS_BOT -->|@ai-assistant| COMMENT_CONTEXT{Context Type?}
    IS_BOT -->|/fix command| CODE_FIX_WF[Code Fix Workflow]
    IS_BOT -->|/review command| PR_REVIEW_WF
    IS_BOT -->|other| SKIP

    COMMENT_CONTEXT -->|On PR| PR_REVIEW_WF
    COMMENT_CONTEXT -->|On Issue| ISSUE_RESPOND_WF

    PUSH_BRANCH -->|main/develop| QUALITY_CHECK[Quality Check Workflow]
    PUSH_BRANCH -->|other| SKIP

    DISPATCH_INPUT --> MANUAL_WORKFLOW[Configured Workflow]

    PR_REVIEW_WF --> EXECUTE
    ISSUE_RESPOND_WF --> EXECUTE
    CODE_FIX_WF --> EXECUTE
    QUALITY_CHECK --> EXECUTE
    MANUAL_WORKFLOW --> EXECUTE

    EXECUTE[Execute on Runner] --> END([Complete])
    QUEUE --> RETRY{Retry<br/>Available?}
    RETRY -->|Yes| LABEL_MATCH
    RETRY -->|No| FAIL[Workflow Failed]
    SKIP --> END
    FAIL --> END
```

### Runner Label Matching

```mermaid
flowchart LR
    EVENT[Workflow Triggered] --> REQ_LABELS[Required Labels:<br/>self-hosted, linux, ai-agent]

    REQ_LABELS --> RUNNER_POOL{Check Runner Pool}

    RUNNER_POOL --> AVAILABLE{Runner<br/>Available?}

    AVAILABLE -->|Yes| CHECK_CAPACITY{Has Capacity?}
    AVAILABLE -->|No| QUEUE_WAIT[Add to Queue]

    CHECK_CAPACITY -->|Yes| ASSIGN[Assign to Runner]
    CHECK_CAPACITY -->|No| QUEUE_WAIT

    ASSIGN --> START_JOB[Start Job Execution]

    QUEUE_WAIT --> TIMEOUT{Timeout<br/>Reached?}
    TIMEOUT -->|No| WAIT[Wait for Runner]
    TIMEOUT -->|Yes| FAIL[Job Failed - No Runner]

    WAIT --> RUNNER_POOL

    START_JOB --> COMPLETE[Job Complete]
    COMPLETE --> RELEASE[Release Runner]
```

---

## PR Review Workflow Flow

### Complete PR Review Sequence

```mermaid
sequenceDiagram
    participant GH as GitHub
    participant WF as Workflow
    participant SETUP as Setup Action
    participant SCRIPT as Review Script
    participant GH_API as GitHub API
    participant AI as AI API
    participant RESULT as Result Handler

    GH->>WF: pull_request event (opened)
    activate WF

    WF->>WF: Check event filters
    WF->>WF: Match runner labels

    WF->>SETUP: Execute setup-ai-agent
    activate SETUP
    SETUP->>SETUP: Sparse checkout (.github/, src/)
    SETUP->>SETUP: Setup GitHub CLI
    SETUP->>SETUP: Configure WSL environment
    SETUP->>SETUP: Restore caches
    SETUP-->>WF: Environment ready
    deactivate SETUP

    WF->>SCRIPT: Run ai-pr-review.sh
    activate SCRIPT

    SCRIPT->>GH_API: Fetch PR details
    GH_API-->>SCRIPT: PR metadata

    SCRIPT->>GH_API: Fetch PR diff
    GH_API-->>SCRIPT: Code changes

    SCRIPT->>GH_API: Fetch PR files
    GH_API-->>SCRIPT: File list

    SCRIPT->>GH_API: Check rate limit
    GH_API-->>SCRIPT: Rate limit OK

    SCRIPT->>SCRIPT: Build AI context
    SCRIPT->>SCRIPT: Validate request schema

    SCRIPT->>AI: POST review request
    activate AI
    AI->>AI: Process code review
    AI-->>SCRIPT: Review response (JSON)
    deactivate AI

    SCRIPT->>SCRIPT: Validate response schema
    SCRIPT->>SCRIPT: Parse AI comments
    SCRIPT->>SCRIPT: Generate markdown report

    SCRIPT-->>WF: Review data prepared
    deactivate SCRIPT

    WF->>RESULT: Process review results
    activate RESULT

    RESULT->>GH_API: Post review summary
    GH_API-->>RESULT: Comment created

    loop For each inline comment
        RESULT->>GH_API: Post inline comment
        GH_API-->>RESULT: Comment created
    end

    RESULT->>GH_API: Add label (ai-reviewed)
    GH_API-->>RESULT: Label added

    RESULT->>WF: Set outputs (score, issues)
    deactivate RESULT

    WF->>GH: Workflow complete
    deactivate WF

    GH->>GH: Update PR UI with comments
```

### PR Review State Machine

```mermaid
stateDiagram-v2
    [*] --> Triggered: pull_request event

    Triggered --> CheckingFilters: Validate event
    CheckingFilters --> MatchingRunner: Filters passed
    CheckingFilters --> Skipped: Filters failed

    MatchingRunner --> Queued: No runner available
    MatchingRunner --> Initializing: Runner assigned

    Queued --> MatchingRunner: Runner becomes available
    Queued --> Failed: Timeout exceeded

    Initializing --> SettingUp: Job started
    SettingUp --> FetchingContext: Setup complete
    SettingUp --> Failed: Setup error

    FetchingContext --> CheckingRateLimit: Context fetched
    FetchingContext --> Retrying: API error

    CheckingRateLimit --> CallingAI: Rate limit OK
    CheckingRateLimit --> Waiting: Rate limit exceeded

    Waiting --> CheckingRateLimit: Wait complete

    CallingAI --> ProcessingResponse: AI response received
    CallingAI --> Retrying: AI API error

    Retrying --> FetchingContext: Retry attempt
    Retrying --> Failed: Max retries exceeded

    ProcessingResponse --> PostingComments: Response valid
    ProcessingResponse --> Failed: Invalid response

    PostingComments --> Completed: Comments posted
    PostingComments --> PartialSuccess: Some comments failed

    Completed --> [*]
    PartialSuccess --> [*]
    Failed --> [*]
    Skipped --> [*]
```

---

## Issue Auto-Response Flow

### Issue Response Sequence

```mermaid
sequenceDiagram
    participant GH as GitHub
    participant WF as Workflow
    participant FILTER as Event Filter
    participant SETUP as Setup Action
    participant SCRIPT as Response Script
    participant GH_API as GitHub API
    participant AI as AI API

    GH->>WF: issues event (opened/labeled)
    activate WF

    WF->>FILTER: Check event conditions
    activate FILTER

    alt Has 'ai-assist' label
        FILTER-->>WF: Proceed
    else Bot mentioned in comment
        FILTER-->>WF: Proceed
    else No trigger condition
        FILTER-->>WF: Skip
        WF->>GH: Workflow skipped
    end
    deactivate FILTER

    WF->>SETUP: Execute setup-ai-agent
    activate SETUP
    SETUP->>SETUP: Sparse checkout (.github/, docs/)
    SETUP-->>WF: Ready
    deactivate SETUP

    WF->>SCRIPT: Run ai-issue-respond.sh
    activate SCRIPT

    SCRIPT->>GH_API: Fetch issue details
    GH_API-->>SCRIPT: Issue metadata

    SCRIPT->>GH_API: Fetch issue comments
    GH_API-->>SCRIPT: Comment history

    SCRIPT->>GH_API: Fetch linked PRs/issues
    GH_API-->>SCRIPT: Related items

    SCRIPT->>SCRIPT: Build context with history

    alt Check if already responded
        SCRIPT->>SCRIPT: Search for bot comment
        alt Bot already commented
            SCRIPT-->>WF: Skip - already responded
            WF->>GH: Workflow complete
        end
    end

    SCRIPT->>AI: Request response generation
    activate AI
    AI->>AI: Generate contextual response
    AI-->>SCRIPT: Response text
    deactivate AI

    SCRIPT->>SCRIPT: Format response markdown
    SCRIPT->>SCRIPT: Add helpful links

    SCRIPT->>GH_API: Post issue comment
    GH_API-->>SCRIPT: Comment created

    alt Issue can be auto-closed
        SCRIPT->>GH_API: Close issue with comment
        GH_API-->>SCRIPT: Issue closed
    end

    SCRIPT-->>WF: Response posted
    deactivate SCRIPT

    WF->>GH: Workflow complete
    deactivate WF
```

### Issue Response Decision Tree

```mermaid
flowchart TD
    START([Issue Event]) --> EVENT_TYPE{Event Type?}

    EVENT_TYPE -->|opened| NEW_ISSUE[New Issue]
    EVENT_TYPE -->|labeled| LABEL_ADDED{Label<br/>'ai-assist'?}
    EVENT_TYPE -->|comment_created| COMMENT_CHECK{Bot<br/>Mentioned?}

    LABEL_ADDED -->|Yes| CHECK_ALREADY
    LABEL_ADDED -->|No| SKIP[Skip]

    COMMENT_CHECK -->|Yes| CHECK_ALREADY
    COMMENT_CHECK -->|No| SKIP

    NEW_ISSUE --> AUTO_LABEL{Has Trigger<br/>Keywords?}
    AUTO_LABEL -->|Yes| CHECK_ALREADY[Check if Already Responded]
    AUTO_LABEL -->|No| SKIP

    CHECK_ALREADY --> ALREADY{Bot Comment<br/>Exists?}
    ALREADY -->|Yes| UPDATE_RESPONSE[Update Existing Response]
    ALREADY -->|No| NEW_RESPONSE[Generate New Response]

    UPDATE_RESPONSE --> FETCH_CONTEXT
    NEW_RESPONSE --> FETCH_CONTEXT[Fetch Full Context]

    FETCH_CONTEXT --> CATEGORIZE{Issue<br/>Category?}

    CATEGORIZE -->|bug| BUG_RESPONSE[Bug Report Response]
    CATEGORIZE -->|feature| FEATURE_RESPONSE[Feature Request Response]
    CATEGORIZE -->|question| QUESTION_RESPONSE[Answer Question]
    CATEGORIZE -->|documentation| DOCS_RESPONSE[Documentation Help]
    CATEGORIZE -->|other| GENERAL_RESPONSE[General Response]

    BUG_RESPONSE --> AI_GENERATE
    FEATURE_RESPONSE --> AI_GENERATE
    QUESTION_RESPONSE --> AI_GENERATE
    DOCS_RESPONSE --> AI_GENERATE
    GENERAL_RESPONSE --> AI_GENERATE[Generate AI Response]

    AI_GENERATE --> VALIDATE{Response<br/>Valid?}
    VALIDATE -->|Yes| POST_COMMENT[Post Comment]
    VALIDATE -->|No| FALLBACK[Use Template Response]

    FALLBACK --> POST_COMMENT

    POST_COMMENT --> AUTO_ACTION{Can Auto<br/>Close/Label?}

    AUTO_ACTION -->|Close| CLOSE_ISSUE[Close Issue]
    AUTO_ACTION -->|Label| ADD_LABEL[Add Labels]
    AUTO_ACTION -->|None| COMPLETE

    CLOSE_ISSUE --> COMPLETE[Complete]
    ADD_LABEL --> COMPLETE
    SKIP --> COMPLETE
```

---

## Code Auto-Fix Flow

### Code Fix Workflow Sequence

```mermaid
sequenceDiagram
    participant USER as User/Workflow
    participant GH as GitHub
    participant WF as Workflow
    participant SETUP as Setup Action
    participant ANALYZE as Analysis Script
    participant AI as AI API
    participant FIX as Fix Script
    participant GIT as Git Operations
    participant GH_API as GitHub API

    USER->>GH: Add 'auto-fix' label or /fix command
    GH->>WF: Trigger workflow
    activate WF

    WF->>WF: Validate trigger conditions
    WF->>SETUP: Execute setup (full checkout)
    activate SETUP
    SETUP->>SETUP: Full repository checkout
    SETUP->>SETUP: Checkout PR branch
    SETUP-->>WF: Environment ready
    deactivate SETUP

    WF->>ANALYZE: Run code analysis
    activate ANALYZE

    ANALYZE->>ANALYZE: Run linters (ESLint, etc.)
    ANALYZE->>ANALYZE: Run security scan
    ANALYZE->>ANALYZE: Run type checker
    ANALYZE->>ANALYZE: Aggregate issues

    alt No issues found
        ANALYZE-->>WF: No fixes needed
        WF->>GH_API: Comment "Code is clean ✅"
        WF->>GH: Workflow complete
    end

    ANALYZE-->>WF: Issues found (JSON)
    deactivate ANALYZE

    WF->>AI: Request fix generation
    activate AI

    AI->>AI: Analyze issues
    AI->>AI: Generate fixes for each issue
    AI->>AI: Validate fix safety

    AI-->>WF: Fix patches (JSON)
    deactivate AI

    WF->>FIX: Apply fixes
    activate FIX

    loop For each fix
        FIX->>FIX: Apply patch to file
        FIX->>FIX: Verify syntax still valid
        FIX->>FIX: Run tests if applicable
    end

    FIX->>FIX: Generate fix summary

    FIX-->>WF: Fixes applied
    deactivate FIX

    WF->>GIT: Commit and push changes
    activate GIT

    GIT->>GIT: git add .
    GIT->>GIT: git commit -m "chore: AI auto-fix"
    GIT->>GIT: git push

    alt Push to protected branch
        GIT->>GIT: Use PAT with bypass
        GIT->>GIT: git push (with PAT)
    end

    GIT-->>WF: Changes pushed
    deactivate GIT

    WF->>GH_API: Post fix summary comment
    GH_API-->>WF: Comment created

    WF->>GH_API: Remove 'auto-fix' label
    GH_API-->>WF: Label removed

    WF->>GH_API: Add 'ai-fixed' label
    GH_API-->>WF: Label added

    WF->>GH: Workflow complete
    deactivate WF

    GH->>GH: Trigger CI checks on new commit
```

### Code Fix State Machine

```mermaid
stateDiagram-v2
    [*] --> Triggered: auto-fix label or /fix command

    Triggered --> ValidatingTrigger: Check permissions
    ValidatingTrigger --> Analyzing: Validation passed
    ValidatingTrigger --> Failed: Invalid trigger

    Analyzing --> RunningLinters: Start analysis
    RunningLinters --> RunningSecurity: Linters complete
    RunningSecurity --> RunningTypeCheck: Security scan complete
    RunningTypeCheck --> AggregatingResults: Type check complete

    AggregatingResults --> NoIssues: No issues found
    AggregatingResults --> GeneratingFixes: Issues found

    NoIssues --> PostingCleanComment: Post success comment
    PostingCleanComment --> Completed: Done

    GeneratingFixes --> RequestingAI: Prepare fix request
    RequestingAI --> ProcessingFixes: AI response received
    RequestingAI --> Failed: AI error

    ProcessingFixes --> ValidatingFixes: Parse fixes
    ValidatingFixes --> ApplyingFixes: Fixes valid
    ValidatingFixes --> Failed: Invalid fixes

    ApplyingFixes --> ApplyPatch: For each fix
    ApplyPatch --> VerifySyntax: Patch applied
    VerifySyntax --> ApplyPatch: Next fix
    VerifySyntax --> Failed: Syntax error

    ApplyPatch --> AllApplied: All patches done
    AllApplied --> RunningTests: Verify changes

    RunningTests --> TestsPassed: Tests OK
    RunningTests --> TestsFailed: Tests failed

    TestsPassed --> CommittingChanges: Proceed
    TestsFailed --> RevertingChanges: Rollback

    RevertingChanges --> Failed: Reverted

    CommittingChanges --> PushingChanges: Commit created
    PushingChanges --> PostingComment: Push successful
    PushingChanges --> RetryingPush: Push failed (conflict)

    RetryingPush --> Rebasing: Pull changes
    Rebasing --> PushingChanges: Rebase complete
    Rebasing --> Failed: Rebase conflict

    PostingComment --> UpdatingLabels: Comment posted
    UpdatingLabels --> Completed: Labels updated

    Completed --> [*]
    Failed --> [*]
```

---

## Error Handling Flow

### Error Handling Hierarchy

```mermaid
flowchart TD
    ERROR([Error Occurs]) --> ERROR_TYPE{Error Type?}

    ERROR_TYPE -->|API Error| API_ERROR
    ERROR_TYPE -->|Network Error| NETWORK_ERROR
    ERROR_TYPE -->|Auth Error| AUTH_ERROR
    ERROR_TYPE -->|Validation Error| VALIDATION_ERROR
    ERROR_TYPE -->|Timeout| TIMEOUT_ERROR
    ERROR_TYPE -->|Unknown| UNKNOWN_ERROR

    API_ERROR{API Error Code?}
    API_ERROR -->|401/403| AUTH_FAILED[Authentication Failed]
    API_ERROR -->|404| NOT_FOUND[Resource Not Found]
    API_ERROR -->|422| VALIDATION_FAILED[Validation Failed]
    API_ERROR -->|429| RATE_LIMIT[Rate Limit Exceeded]
    API_ERROR -->|500/502/503| SERVICE_ERROR[Service Unavailable]

    AUTH_FAILED --> CHECK_TOKEN{Token Type?}
    CHECK_TOKEN -->|GITHUB_TOKEN| INSUFFICIENT_PERMS[Insufficient Permissions]
    CHECK_TOKEN -->|AI_API_KEY| INVALID_KEY[Invalid API Key]

    INSUFFICIENT_PERMS --> TRY_PAT{PAT Available?}
    TRY_PAT -->|Yes| USE_PAT[Use PAT Token]
    TRY_PAT -->|No| FAIL[Fail with Error Message]

    USE_PAT --> RETRY_OP[Retry Operation]

    INVALID_KEY --> FAIL
    NOT_FOUND --> LOG_SKIP[Log and Skip]
    VALIDATION_FAILED --> FAIL

    RATE_LIMIT --> WAIT_RESET{Can Wait?}
    WAIT_RESET -->|Yes| WAIT[Wait for Reset]
    WAIT_RESET -->|No| CIRCUIT_BREAKER[Open Circuit Breaker]

    WAIT --> RETRY_OP

    SERVICE_ERROR --> RETRY_COUNT{Retry Count?}
    RETRY_COUNT -->|< Max| EXPONENTIAL_BACKOFF[Exponential Backoff]
    RETRY_COUNT -->|>= Max| CIRCUIT_BREAKER

    EXPONENTIAL_BACKOFF --> RETRY_OP
    RETRY_OP --> SUCCESS{Success?}
    SUCCESS -->|Yes| COMPLETE[Complete Successfully]
    SUCCESS -->|No| ERROR_TYPE

    NETWORK_ERROR --> RETRY_COUNT
    TIMEOUT_ERROR --> RETRY_COUNT

    AUTH_ERROR --> CHECK_TOKEN
    VALIDATION_ERROR --> FAIL

    UNKNOWN_ERROR --> LOG_ERROR[Log Full Error]
    LOG_ERROR --> FALLBACK{Fallback<br/>Available?}
    FALLBACK -->|Yes| USE_FALLBACK[Use Fallback Strategy]
    FALLBACK -->|No| FAIL

    USE_FALLBACK --> PARTIAL_SUCCESS[Partial Success]

    CIRCUIT_BREAKER --> NOTIFY[Send Alert]
    NOTIFY --> GRACEFUL_DEGRADATION[Graceful Degradation]
    GRACEFUL_DEGRADATION --> PARTIAL_SUCCESS

    FAIL --> POST_ERROR_COMMENT[Post Error Comment]
    POST_ERROR_COMMENT --> END_FAILURE[End - Failed]

    COMPLETE --> END_SUCCESS[End - Success]
    PARTIAL_SUCCESS --> END_PARTIAL[End - Partial Success]
    LOG_SKIP --> END_SKIPPED[End - Skipped]

    END_SUCCESS --> UPDATE_METRICS[Update Success Metrics]
    END_FAILURE --> UPDATE_METRICS
    END_PARTIAL --> UPDATE_METRICS
    END_SKIPPED --> UPDATE_METRICS

    UPDATE_METRICS --> DONE([Done])
```

### Retry with Exponential Backoff

```mermaid
sequenceDiagram
    participant SCRIPT as Script
    participant SERVICE as External Service
    participant BACKOFF as Backoff Logic

    SCRIPT->>SERVICE: Request (Attempt 1)
    SERVICE-->>SCRIPT: Error

    SCRIPT->>BACKOFF: Calculate delay (base=1s)
    BACKOFF-->>SCRIPT: Delay = 1s
    SCRIPT->>SCRIPT: Sleep 1s

    SCRIPT->>SERVICE: Request (Attempt 2)
    SERVICE-->>SCRIPT: Error

    SCRIPT->>BACKOFF: Calculate delay (2^1)
    BACKOFF-->>SCRIPT: Delay = 2s + jitter
    SCRIPT->>SCRIPT: Sleep ~2s

    SCRIPT->>SERVICE: Request (Attempt 3)
    SERVICE-->>SCRIPT: Error

    SCRIPT->>BACKOFF: Calculate delay (2^2)
    BACKOFF-->>SCRIPT: Delay = 4s + jitter
    SCRIPT->>SCRIPT: Sleep ~4s

    SCRIPT->>SERVICE: Request (Attempt 4)
    SERVICE-->>SCRIPT: Error

    SCRIPT->>BACKOFF: Calculate delay (2^3)
    BACKOFF-->>SCRIPT: Delay = 8s + jitter
    SCRIPT->>SCRIPT: Sleep ~8s

    SCRIPT->>SERVICE: Request (Attempt 5)
    SERVICE-->>SCRIPT: Success

    SCRIPT->>SCRIPT: Process response
```

---

## Rate Limit Handling Flow

### GitHub API Rate Limit Management

```mermaid
flowchart TD
    START([API Request Needed]) --> CHECK_LIMIT[Check Rate Limit Status]

    CHECK_LIMIT --> GET_STATUS[gh api rate_limit]

    GET_STATUS --> PARSE{Parse Response}

    PARSE --> REMAINING[Get Remaining Count]
    REMAINING --> THRESHOLD{Remaining > 100?}

    THRESHOLD -->|Yes| MAKE_REQUEST[Make API Request]
    THRESHOLD -->|No| CRITICAL{Critical<br/>Request?}

    CRITICAL -->|Yes| CALCULATE_WAIT[Calculate Wait Time]
    CRITICAL -->|No| SKIP_REQUEST[Skip Non-Critical Request]

    CALCULATE_WAIT --> RESET_TIME[Get Reset Timestamp]
    RESET_TIME --> WAIT_DURATION[Current Time - Reset Time]
    WAIT_DURATION --> REASONABLE{Wait < 15min?}

    REASONABLE -->|Yes| WAIT[Sleep Until Reset]
    REASONABLE -->|No| USE_CACHE{Cached Data<br/>Available?}

    USE_CACHE -->|Yes| RETURN_CACHE[Return Cached Response]
    USE_CACHE -->|No| FAIL_LIMIT[Fail - Rate Limit]

    WAIT --> CHECK_LIMIT

    MAKE_REQUEST --> REQUEST_SUCCESS{Request<br/>Success?}

    REQUEST_SUCCESS -->|Yes| CACHE_RESPONSE[Cache Response]
    REQUEST_SUCCESS -->|No| ERROR_HANDLE[Handle Error]

    CACHE_RESPONSE --> UPDATE_METRICS[Update Rate Limit Metrics]
    UPDATE_METRICS --> COMPLETE[Complete]

    SKIP_REQUEST --> LOG_SKIP[Log Skipped Request]
    RETURN_CACHE --> LOG_CACHE[Log Cache Hit]
    FAIL_LIMIT --> LOG_FAIL[Log Rate Limit Failure]

    LOG_SKIP --> COMPLETE
    LOG_CACHE --> COMPLETE
    LOG_FAIL --> COMPLETE
    ERROR_HANDLE --> COMPLETE
```

### AI API Rate Limit with Circuit Breaker

```mermaid
stateDiagram-v2
    [*] --> CircuitClosed: Initial State

    CircuitClosed --> CheckingLimit: API Request
    CheckingLimit --> WithinLimit: Limit OK
    CheckingLimit --> AtLimit: Limit Reached

    WithinLimit --> MakingRequest: Proceed
    MakingRequest --> RequestSuccess: Success
    MakingRequest --> RequestFailed: Failure

    RequestSuccess --> RecordSuccess: Record Metrics
    RecordSuccess --> CircuitClosed: Continue

    RequestFailed --> IncrementFailures: Count++
    IncrementFailures --> CheckFailureCount: Evaluate

    CheckFailureCount --> CircuitClosed: Count < Threshold
    CheckFailureCount --> CircuitOpen: Count >= Threshold

    AtLimit --> WaitingForReset: Queue Request
    WaitingForReset --> CircuitHalfOpen: Timer Expired

    CircuitOpen --> Timeout: Wait Period
    Timeout --> CircuitHalfOpen: Test Recovery

    CircuitHalfOpen --> TestRequest: Single Request
    TestRequest --> TestSuccess: Success
    TestRequest --> TestFailed: Failure

    TestSuccess --> ResetFailures: Reset Counter
    ResetFailures --> CircuitClosed: Resume Normal

    TestFailed --> CircuitOpen: Re-open Circuit

    CircuitOpen --> FallbackStrategy: Use Fallback
    FallbackStrategy --> UseCachedData: If Available
    FallbackStrategy --> SkipOperation: If Not Critical
    FallbackStrategy --> NotifyUser: If Critical

    UseCachedData --> [*]
    SkipOperation --> [*]
    NotifyUser --> [*]
```

---

## Job Queue Management

### Job Queue and Runner Assignment

```mermaid
flowchart TD
    EVENT([Workflow Event]) --> QUEUE[Job Queue]

    QUEUE --> PRIORITY{Priority Level?}

    PRIORITY -->|High| HIGH_QUEUE[High Priority Queue]
    PRIORITY -->|Normal| NORMAL_QUEUE[Normal Priority Queue]
    PRIORITY -->|Low| LOW_QUEUE[Low Priority Queue]

    HIGH_QUEUE --> DISPATCHER
    NORMAL_QUEUE --> DISPATCHER
    LOW_QUEUE --> DISPATCHER

    DISPATCHER{Job Dispatcher} --> CHECK_RUNNERS[Check Available Runners]

    CHECK_RUNNERS --> RUNNER_STATUS{Runner<br/>Available?}

    RUNNER_STATUS -->|Yes| MATCH_LABELS{Labels<br/>Match?}
    RUNNER_STATUS -->|No| WAIT_QUEUE[Wait in Queue]

    MATCH_LABELS -->|Yes| CHECK_CAPACITY{Runner<br/>Has Capacity?}
    MATCH_LABELS -->|No| WAIT_QUEUE

    CHECK_CAPACITY -->|Yes| ASSIGN[Assign Job to Runner]
    CHECK_CAPACITY -->|No| WAIT_QUEUE

    ASSIGN --> EXECUTE[Execute Job]

    EXECUTE --> JOB_COMPLETE{Job Status?}

    JOB_COMPLETE -->|Success| RELEASE[Release Runner]
    JOB_COMPLETE -->|Failure| RETRY_CHECK{Retry<br/>Allowed?}
    JOB_COMPLETE -->|Timeout| TIMEOUT_HANDLE[Handle Timeout]

    RETRY_CHECK -->|Yes| REQUEUE[Re-queue Job]
    RETRY_CHECK -->|No| JOB_FAILED[Mark Job Failed]

    REQUEUE --> QUEUE

    TIMEOUT_HANDLE --> CANCEL_JOB[Cancel Job]
    CANCEL_JOB --> JOB_FAILED

    RELEASE --> CLEANUP[Cleanup Runner]
    CLEANUP --> READY[Mark Runner Ready]
    READY --> DISPATCHER

    JOB_FAILED --> NOTIFY_FAILURE[Notify Failure]
    NOTIFY_FAILURE --> END([End])

    WAIT_QUEUE --> TIMEOUT_CHECK{Queue<br/>Timeout?}
    TIMEOUT_CHECK -->|No| WAIT[Wait]
    TIMEOUT_CHECK -->|Yes| JOB_FAILED

    WAIT --> CHECK_RUNNERS
```

### Parallel Job Execution

```mermaid
gantt
    title Job Execution Timeline with Multiple Runners
    dateFormat HH:mm:ss
    axisFormat %H:%M:%S

    section Runner 1
    PR Review #123    :active, r1j1, 00:00:00, 180s
    Idle              :r1i1, after r1j1, 20s
    PR Review #125    :active, r1j2, after r1i1, 150s
    Idle              :r1i2, after r1j2, 10s

    section Runner 2
    Issue Response #45 :active, r2j1, 00:00:10, 60s
    Idle               :r2i1, after r2j1, 30s
    Code Fix #124      :active, r2j2, after r2i1, 200s

    section Runner 3
    Idle               :r3i1, 00:00:00, 45s
    PR Review #124     :active, r3j1, after r3i1, 170s
    Idle               :r3i2, after r3j1, 15s
    Issue Response #46 :active, r3j2, after r3i2, 55s

    section Queue
    Job Waiting        :crit, q1, 00:00:00, 45s
    Job Waiting        :crit, q2, 00:01:10, 30s
```

---

## Integration Flow Summary

### Complete End-to-End Flow

```mermaid
flowchart TB
    START([GitHub Event]) --> WEBHOOK[Webhook Trigger]

    WEBHOOK --> EVENT_VALIDATION{Validate Event}
    EVENT_VALIDATION -->|Valid| WORKFLOW_SELECTION
    EVENT_VALIDATION -->|Invalid| LOG_INVALID[Log Invalid Event]

    WORKFLOW_SELECTION[Select Workflow] --> RUNNER_MATCH[Match Runner Labels]

    RUNNER_MATCH --> QUEUE_OR_START{Runner<br/>Available?}
    QUEUE_OR_START -->|Yes| START_JOB[Start Job]
    QUEUE_OR_START -->|No| QUEUE_JOB[Queue Job]

    QUEUE_JOB --> WAIT_RUNNER[Wait for Runner]
    WAIT_RUNNER --> QUEUE_OR_START

    START_JOB --> CHECKOUT[Checkout Code]
    CHECKOUT --> SETUP[Setup Environment]
    SETUP --> CACHE_CHECK{Cache<br/>Available?}

    CACHE_CHECK -->|Yes| RESTORE_CACHE[Restore Cache]
    CACHE_CHECK -->|No| FRESH_SETUP[Fresh Setup]

    RESTORE_CACHE --> EXEC_SCRIPT
    FRESH_SETUP --> SAVE_CACHE[Save Cache]
    SAVE_CACHE --> EXEC_SCRIPT[Execute Script]

    EXEC_SCRIPT --> FETCH_CONTEXT[Fetch GitHub Context]
    FETCH_CONTEXT --> RATE_CHECK[Check Rate Limits]

    RATE_CHECK --> RATE_OK{Limit OK?}
    RATE_OK -->|Yes| CALL_AI[Call AI API]
    RATE_OK -->|No| WAIT_RESET[Wait for Reset]

    WAIT_RESET --> CALL_AI

    CALL_AI --> AI_SUCCESS{AI Success?}
    AI_SUCCESS -->|Yes| PROCESS_RESPONSE[Process Response]
    AI_SUCCESS -->|No| AI_RETRY{Retry?}

    AI_RETRY -->|Yes| BACKOFF[Exponential Backoff]
    AI_RETRY -->|No| USE_FALLBACK[Use Fallback]

    BACKOFF --> CALL_AI
    USE_FALLBACK --> PROCESS_RESPONSE

    PROCESS_RESPONSE --> VALIDATE_OUTPUT{Output Valid?}
    VALIDATE_OUTPUT -->|Yes| TAKE_ACTION[Take Action]
    VALIDATE_OUTPUT -->|No| ERROR_HANDLE[Handle Error]

    TAKE_ACTION --> ACTION_TYPE{Action Type?}
    ACTION_TYPE -->|Comment| POST_COMMENT[Post Comment]
    ACTION_TYPE -->|Commit| CREATE_COMMIT[Create Commit]
    ACTION_TYPE -->|Label| UPDATE_LABELS[Update Labels]

    POST_COMMENT --> FINALIZE
    CREATE_COMMIT --> PUSH_CHANGES[Push Changes]
    UPDATE_LABELS --> FINALIZE

    PUSH_CHANGES --> PUSH_SUCCESS{Push OK?}
    PUSH_SUCCESS -->|Yes| FINALIZE[Finalize Job]
    PUSH_SUCCESS -->|No| REBASE[Rebase and Retry]

    REBASE --> PUSH_CHANGES

    ERROR_HANDLE --> NOTIFY_ERROR[Notify Error]
    NOTIFY_ERROR --> FINALIZE

    FINALIZE --> UPDATE_STATUS[Update Job Status]
    UPDATE_STATUS --> METRICS[Record Metrics]
    METRICS --> CLEANUP[Cleanup Environment]
    CLEANUP --> RELEASE_RUNNER[Release Runner]

    RELEASE_RUNNER --> COMPLETE[Complete]
    LOG_INVALID --> COMPLETE

    COMPLETE --> END([End])
```

---

## Summary

This document provides comprehensive event flow diagrams covering:

1. **System Overview** - High-level architecture and component interaction
2. **Event Routing** - How events are filtered and routed to appropriate workflows
3. **PR Review Flow** - Complete sequence and state machine for code reviews
4. **Issue Response Flow** - Issue handling and automated responses
5. **Code Auto-Fix Flow** - Automated code correction workflow
6. **Error Handling** - Comprehensive error handling hierarchy and retry logic
7. **Rate Limit Management** - GitHub and AI API rate limit handling with circuit breakers
8. **Job Queue Management** - Runner assignment and parallel execution

All diagrams use Mermaid syntax for easy rendering in GitHub and documentation tools.
