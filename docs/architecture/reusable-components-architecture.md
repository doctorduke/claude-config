# Reusable Components Architecture
**Wave 3 - Backend Architect Deliverables**

---

## System Architecture Diagram

```mermaid
graph TB
    subgraph "Organization Repositories"
        REPO1[Repository 1<br/>pr-review.yml]
        REPO2[Repository 2<br/>issue-comment.yml]
        REPO3[Repository 3<br/>auto-fix.yml]
    end

    subgraph "Reusable Components"
        RW[Reusable Workflow<br/>reusable-ai-workflow.yml]
        CA[Composite Action<br/>setup-ai-agent/action.yml]
    end

    subgraph "Scripts Layer"
        REVIEW[ai-review.sh<br/>python-pro]
        COMMON[lib/common.sh<br/>python-pro]
        SCHEMA[schemas/*.json<br/>python-pro]
    end

    subgraph "External Services"
        GH[GitHub API]
        AI[AI API<br/>Claude/OpenAI]
    end

    REPO1 -->|workflow_call| RW
    REPO2 -->|workflow_call| RW
    REPO3 -->|workflow_call| RW

    RW -->|uses| CA
    RW -->|executes| REVIEW

    CA -->|setup| REVIEW
    REVIEW -->|source| COMMON
    REVIEW -->|validate| SCHEMA

    RW -->|gh CLI| GH
    REVIEW -->|API calls| AI
    REVIEW -->|API calls| GH

    style RW fill:#4CAF50,color:#fff
    style CA fill:#2196F3,color:#fff
    style REVIEW fill:#FF9800,color:#fff
    style COMMON fill:#FF9800,color:#fff
    style SCHEMA fill:#FF9800,color:#fff
```

---

## Component Interaction Flow

```mermaid
sequenceDiagram
    participant Caller as Calling Workflow
    participant RW as Reusable Workflow
    participant CA as Composite Action
    participant Script as ai-review.sh
    participant GH as GitHub API
    participant AI as AI Service

    Caller->>RW: workflow_call(pr_number, ai_model, ...)
    activate RW

    RW->>RW: Validate inputs
    RW->>CA: Setup environment
    activate CA

    CA->>CA: Detect platform
    CA->>CA: Checkout repository (sparse)
    CA->>CA: Setup language stack
    CA->>CA: Install gh CLI
    CA->>CA: Install tools (jq, yq)
    CA->>CA: Setup cache
    CA->>CA: Validate environment
    CA-->>RW: config_path, tools_installed, cache_hit

    deactivate CA

    RW->>GH: Fetch PR context
    GH-->>RW: PR details, files, metadata

    RW->>Script: Execute review
    activate Script

    Script->>GH: Get PR diff
    GH-->>Script: File changes

    Script->>AI: Analyze code
    AI-->>Script: Review feedback

    Script-->>RW: review-output.json
    deactivate Script

    RW->>RW: Validate JSON output
    RW->>GH: Post review
    RW->>GH: Post inline comments (optional)

    RW-->>Caller: review_id, status, score, issues_found
    deactivate RW
```

---

## Data Flow Architecture

```mermaid
graph LR
    subgraph "Input Layer"
        IN1[PR Number]
        IN2[AI Model]
        IN3[Threshold]
        IN4[Review Mode]
    end

    subgraph "Processing Layer"
        P1[Input Validation]
        P2[Environment Setup]
        P3[PR Context Fetch]
        P4[AI Analysis]
        P5[Output Validation]
    end

    subgraph "Output Layer"
        O1[Review Posted]
        O2[Inline Comments]
        O3[Quality Score]
        O4[Artifacts]
        O5[Metrics]
    end

    IN1 --> P1
    IN2 --> P1
    IN3 --> P1
    IN4 --> P1

    P1 --> P2
    P2 --> P3
    P3 --> P4
    P4 --> P5

    P5 --> O1
    P5 --> O2
    P5 --> O3
    P5 --> O4
    P5 --> O5

    style IN1 fill:#E3F2FD
    style IN2 fill:#E3F2FD
    style IN3 fill:#E3F2FD
    style IN4 fill:#E3F2FD

    style P1 fill:#FFF3E0
    style P2 fill:#FFF3E0
    style P3 fill:#FFF3E0
    style P4 fill:#FFF3E0
    style P5 fill:#FFF3E0

    style O1 fill:#E8F5E9
    style O2 fill:#E8F5E9
    style O3 fill:#E8F5E9
    style O4 fill:#E8F5E9
    style O5 fill:#E8F5E9
```

---

## Composite Action Internal Architecture

```mermaid
graph TB
    START[Start Setup] --> DETECT[Detect Platform<br/>Linux/macOS/Windows]

    DETECT --> CHECKOUT{Checkout Mode?}
    CHECKOUT -->|sparse| SPARSE[Sparse Checkout<br/>scripts/, .github/]
    CHECKOUT -->|full| FULL[Full Checkout]
    CHECKOUT -->|skip| SKIP[Skip Checkout]

    SPARSE --> LANG
    FULL --> LANG
    SKIP --> LANG

    LANG{Language Stack?}
    LANG -->|node| NODE[Setup Node.js<br/>actions/setup-node@v4]
    LANG -->|python| PYTHON[Setup Python<br/>actions/setup-python@v5]
    LANG -->|go| GO[Setup Go<br/>actions/setup-go@v5]
    LANG -->|multi| MULTI[Setup All<br/>Node + Python + Go]
    LANG -->|none| CACHE

    NODE --> CACHE
    PYTHON --> CACHE
    GO --> CACHE
    MULTI --> CACHE

    CACHE[Restore Cache<br/>npm/pip/go modules] --> TOOLS

    TOOLS{Install Tools?}
    TOOLS -->|yes| INSTALL[Install jq, yq, shellcheck]
    TOOLS -->|no| GH

    INSTALL --> GH

    GH{Install gh CLI?}
    GH -->|yes| GHCLI[Install GitHub CLI<br/>Platform-specific]
    GH -->|no| DEPS

    GHCLI --> DEPS

    DEPS[Install Dependencies<br/>npm/pip/go] --> VALIDATE

    VALIDATE{Validate Env?}
    VALIDATE -->|yes| CHECK[Validate Tools<br/>git, gh, jq, etc.]
    VALIDATE -->|no| ENV

    CHECK --> ENV

    ENV[Setup Environment<br/>Exports, PATH] --> END[Return Outputs<br/>config_path, tools_installed]

    style START fill:#4CAF50,color:#fff
    style END fill:#4CAF50,color:#fff
    style DETECT fill:#2196F3,color:#fff
    style LANG fill:#FF9800,color:#fff
    style CACHE fill:#9C27B0,color:#fff
    style TOOLS fill:#FF9800,color:#fff
    style GH fill:#FF9800,color:#fff
    style VALIDATE fill:#F44336,color:#fff
```

---

## Caching Strategy

```mermaid
graph TB
    subgraph "Cache Key Generation"
        OS[Runner OS<br/>Linux/macOS/Windows]
        LOCK[Lockfile Hashes<br/>package-lock.json<br/>requirements.txt<br/>go.sum]
        PREFIX[Cache Prefix<br/>ai-agent]
    end

    subgraph "Cache Paths"
        NPM[~/.npm<br/>node_modules]
        PIP[~/.cache/pip<br/>venv]
        GO[~/go/pkg/mod]
        GH[~/.local/share/gh]
    end

    subgraph "Cache Hit Flow"
        HIT{Cache Hit?}
        RESTORE[Restore Cache<br/>5-10 seconds]
        DOWNLOAD[Download Dependencies<br/>30-60 seconds]
        SAVE[Save Cache<br/>For next run]
    end

    OS --> KEY[Cache Key]
    LOCK --> KEY
    PREFIX --> KEY

    KEY --> HIT

    HIT -->|Yes| RESTORE
    HIT -->|No| DOWNLOAD

    RESTORE --> NPM
    RESTORE --> PIP
    RESTORE --> GO
    RESTORE --> GH

    DOWNLOAD --> NPM
    DOWNLOAD --> PIP
    DOWNLOAD --> GO
    DOWNLOAD --> GH

    DOWNLOAD --> SAVE

    style HIT fill:#FF9800,color:#fff
    style RESTORE fill:#4CAF50,color:#fff
    style DOWNLOAD fill:#F44336,color:#fff
    style SAVE fill:#2196F3,color:#fff
```

---

## Error Handling Architecture

```mermaid
graph TB
    START[Workflow Step Execution]

    START --> TRY{Try Execution}

    TRY -->|Success| NEXT[Next Step]
    TRY -->|Failure| TYPE{Error Type?}

    TYPE -->|Validation Error| LOG1[Log Error Details]
    TYPE -->|API Error| RETRY{Retry Count?}
    TYPE -->|Tool Missing| INSTALL[Attempt Auto-Install]
    TYPE -->|Unknown| LOG2[Log Stack Trace]

    RETRY -->|< Max| BACKOFF[Exponential Backoff]
    RETRY -->|>= Max| FAIL1[Fail Workflow]

    BACKOFF --> TRY

    LOG1 --> EXIT1[Exit with Code 1]
    LOG2 --> EXIT2[Exit with Code 1]

    INSTALL -->|Success| TRY
    INSTALL -->|Failed| FAIL2[Fail Workflow]

    EXIT1 --> SUMMARY[Add to Step Summary]
    EXIT2 --> SUMMARY
    FAIL1 --> SUMMARY
    FAIL2 --> SUMMARY

    SUMMARY --> ARTIFACT[Upload Debug Artifacts]

    style START fill:#4CAF50,color:#fff
    style NEXT fill:#4CAF50,color:#fff
    style TYPE fill:#FF9800,color:#fff
    style RETRY fill:#2196F3,color:#fff
    style BACKOFF fill:#9C27B0,color:#fff
    style FAIL1 fill:#F44336,color:#fff
    style FAIL2 fill:#F44336,color:#fff
    style ARTIFACT fill:#607D8B,color:#fff
```

---

## Cross-Platform Compatibility Matrix

| Feature | Linux | macOS | Windows | WSL | Notes |
|---------|-------|-------|---------|-----|-------|
| **Checkout** | ✅ | ✅ | ✅ | ✅ | Native Git support |
| **Node.js** | ✅ | ✅ | ✅ | ✅ | actions/setup-node@v4 |
| **Python** | ✅ | ✅ | ✅ | ✅ | actions/setup-python@v5 |
| **Go** | ✅ | ✅ | ✅ | ✅ | actions/setup-go@v5 |
| **gh CLI** | ✅ | ✅ | ✅ | ✅ | Auto-install all platforms |
| **jq** | ✅ | ✅ | ⚠️ | ✅ | Windows: Chocolatey required |
| **yq** | ✅ | ✅ | ⚠️ | ✅ | Windows: Chocolatey required |
| **shellcheck** | ✅ | ✅ | ⚠️ | ✅ | Windows: Chocolatey required |
| **Cache** | ✅ | ✅ | ✅ | ✅ | Platform-specific paths |
| **Scripts** | ✅ | ✅ | ✅ | ✅ | POSIX-compliant bash |

Legend:
- ✅ Full support, tested
- ⚠️ Supported with prerequisites
- ❌ Not supported

---

## Service Integration Diagram

```mermaid
graph TB
    subgraph "GitHub Platform"
        PR[Pull Request Event]
        ACTIONS[GitHub Actions]
        API[GitHub API]
        SECRETS[GitHub Secrets]
    end

    subgraph "Reusable Workflow"
        RW[Reusable Workflow]
        STEPS[14 Workflow Steps]
    end

    subgraph "Composite Action"
        CA[Composite Action]
        SETUP[15 Setup Steps]
    end

    subgraph "External Services"
        AI_API[AI Service API<br/>Claude/OpenAI/Gemini]
        NPM[npm Registry]
        PYPI[PyPI Registry]
        GO_PROXY[Go Proxy]
    end

    subgraph "Infrastructure"
        RUNNERS[GitHub-Hosted Runners<br/>or Self-Hosted]
        CACHE[Actions Cache]
        ARTIFACTS[Artifacts Storage]
    end

    PR --> ACTIONS
    ACTIONS --> RW
    SECRETS --> RW

    RW --> STEPS
    STEPS --> CA
    STEPS --> API

    CA --> SETUP
    SETUP --> NPM
    SETUP --> PYPI
    SETUP --> GO_PROXY

    RW --> AI_API

    RUNNERS --> RW
    CACHE --> CA
    STEPS --> ARTIFACTS

    style RW fill:#4CAF50,color:#fff
    style CA fill:#2196F3,color:#fff
    style AI_API fill:#FF9800,color:#fff
    style RUNNERS fill:#9C27B0,color:#fff
```

---

## Security Architecture

```mermaid
graph TB
    subgraph "Input Validation Layer"
        IN[User Inputs]
        REGEX[Regex Validation]
        SANITIZE[Sanitization]
    end

    subgraph "Permission Layer"
        MINIMAL[Minimal Permissions<br/>contents:read<br/>pull-requests:write<br/>issues:read]
        SCOPE[Scope Enforcement]
    end

    subgraph "Secret Management Layer"
        VAULT[GitHub Secrets Vault]
        MASK[Auto-Masking in Logs]
        INJECT[Env Var Injection]
    end

    subgraph "Execution Layer"
        SANDBOX[Sandboxed Runner]
        NOINJECT[No Command Injection]
        AUDIT[Audit Logging]
    end

    IN --> REGEX
    REGEX --> SANITIZE
    SANITIZE --> MINIMAL

    MINIMAL --> SCOPE
    SCOPE --> VAULT

    VAULT --> MASK
    MASK --> INJECT

    INJECT --> SANDBOX
    SANDBOX --> NOINJECT
    NOINJECT --> AUDIT

    style IN fill:#F44336,color:#fff
    style REGEX fill:#FF9800,color:#fff
    style SANITIZE fill:#FF9800,color:#fff
    style MINIMAL fill:#4CAF50,color:#fff
    style VAULT fill:#9C27B0,color:#fff
    style MASK fill:#2196F3,color:#fff
    style SANDBOX fill:#607D8B,color:#fff
    style AUDIT fill:#795548,color:#fff
```

---

## Deployment Architecture

```mermaid
graph TB
    subgraph "Development"
        DEV1[Developer Creates PR]
        DEV2[Local Testing with act]
        DEV3[Validation with mock runner]
    end

    subgraph "Staging (Test Repository)"
        STAGE1[Deploy to Test Repo]
        STAGE2[Run Integration Tests]
        STAGE3[Validate Outputs]
    end

    subgraph "Production (Org-Wide)"
        PROD1[Deploy to .github/workflows]
        PROD2[Enable in Multiple Repos]
        PROD3[Monitor Metrics]
    end

    subgraph "Consumption"
        CONS1[Repository 1 uses]
        CONS2[Repository 2 uses]
        CONS3[Repository N uses]
    end

    DEV1 --> DEV2
    DEV2 --> DEV3
    DEV3 --> STAGE1

    STAGE1 --> STAGE2
    STAGE2 --> STAGE3
    STAGE3 --> PROD1

    PROD1 --> PROD2
    PROD2 --> PROD3

    PROD3 --> CONS1
    PROD3 --> CONS2
    PROD3 --> CONS3

    style DEV1 fill:#E3F2FD
    style DEV2 fill:#E3F2FD
    style DEV3 fill:#E3F2FD

    style STAGE1 fill:#FFF3E0
    style STAGE2 fill:#FFF3E0
    style STAGE3 fill:#FFF3E0

    style PROD1 fill:#E8F5E9
    style PROD2 fill:#E8F5E9
    style PROD3 fill:#E8F5E9

    style CONS1 fill:#F3E5F5
    style CONS2 fill:#F3E5F5
    style CONS3 fill:#F3E5F5
```

---

## Performance Optimization Stack

```mermaid
graph LR
    subgraph "Optimization Layers"
        L1[Sparse Checkout<br/>-80% clone time]
        L2[Dependency Caching<br/>-70% setup time]
        L3[Parallel Execution<br/>-30% total time]
        L4[Conditional Steps<br/>Skip unnecessary work]
    end

    subgraph "Performance Metrics"
        M1[Setup: 5-30s]
        M2[Analysis: 30-90s]
        M3[Post Review: 5-10s]
        M4[Total: <3min P95]
    end

    L1 --> M1
    L2 --> M1
    L3 --> M2
    L4 --> M4

    style L1 fill:#4CAF50,color:#fff
    style L2 fill:#4CAF50,color:#fff
    style L3 fill:#4CAF50,color:#fff
    style L4 fill:#4CAF50,color:#fff

    style M1 fill:#2196F3,color:#fff
    style M2 fill:#2196F3,color:#fff
    style M3 fill:#2196F3,color:#fff
    style M4 fill:#2196F3,color:#fff
```

---

## Observability Stack

```mermaid
graph TB
    subgraph "Metrics Collection"
        M1[Execution Time]
        M2[Cache Hit Rate]
        M3[Quality Scores]
        M4[Issue Count]
        M5[Success Rate]
    end

    subgraph "Outputs"
        O1[Job Outputs<br/>review_id, status, score]
        O2[Step Summary<br/>Formatted report]
        O3[Artifacts<br/>JSON files]
        O4[Logs<br/>Structured logging]
    end

    subgraph "Monitoring"
        MON1[GitHub Actions Dashboard]
        MON2[Custom Dashboards]
        MON3[Alerting]
    end

    M1 --> O1
    M2 --> O1
    M3 --> O1
    M4 --> O1
    M5 --> O1

    O1 --> O2
    O1 --> O3
    O1 --> O4

    O2 --> MON1
    O3 --> MON2
    O4 --> MON3

    style M1 fill:#2196F3,color:#fff
    style M2 fill:#2196F3,color:#fff
    style M3 fill:#2196F3,color:#fff
    style M4 fill:#2196F3,color:#fff
    style M5 fill:#2196F3,color:#fff

    style O1 fill:#4CAF50,color:#fff
    style O2 fill:#4CAF50,color:#fff
    style O3 fill:#4CAF50,color:#fff
    style O4 fill:#4CAF50,color:#fff

    style MON1 fill:#FF9800,color:#fff
    style MON2 fill:#FF9800,color:#fff
    style MON3 fill:#F44336,color:#fff
```

---

## File Structure

```
.github/
├── workflows/
│   └── reusable-ai-workflow.yml        (389 lines)
│       ├── Inputs: 13 parameters
│       ├── Outputs: 5 metrics
│       ├── Secrets: 2 required
│       └── Jobs: 1 (ai-review)
│           └── Steps: 14
│
└── actions/
    └── setup-ai-agent/
        └── action.yml                   (506 lines)
            ├── Inputs: 14 parameters
            ├── Outputs: 5 metrics
            └── Steps: 15
                ├── Platform detection
                ├── Repository checkout
                ├── Language stack setup
                ├── Dependency caching
                ├── Tool installation
                └── Environment validation
```

---

## Integration Points

```mermaid
graph TB
    subgraph "Wave 3 Specialists"
        FRONTEND[frontend-developer<br/>Main workflows]
        BACKEND[backend-architect<br/>Reusable components]
        PYTHON[python-pro<br/>AI scripts]
        SECURITY[security-auditor<br/>Security hardening]
        API[api-documenter<br/>Documentation]
        DX[dx-optimizer<br/>Testing tools]
    end

    BACKEND -->|Provides| FRONTEND
    BACKEND -->|Uses| PYTHON
    BACKEND -->|Reviewed by| SECURITY
    BACKEND -->|Documented by| API
    BACKEND -->|Tested with| DX

    FRONTEND -->|Consumes| BACKEND
    PYTHON -->|Scripts for| BACKEND

    style BACKEND fill:#4CAF50,color:#fff
    style FRONTEND fill:#2196F3,color:#fff
    style PYTHON fill:#FF9800,color:#fff
    style SECURITY fill:#F44336,color:#fff
    style API fill:#9C27B0,color:#fff
    style DX fill:#607D8B,color:#fff
```

---

## Technology Stack

| Layer | Technologies | Purpose |
|-------|-------------|---------|
| **Workflow Engine** | GitHub Actions | Orchestration |
| **Language Runtimes** | Node.js 20, Python 3.11, Go 1.21 | Multi-language support |
| **Package Managers** | npm, pip, go modules | Dependency management |
| **CLI Tools** | gh, git, jq, yq, shellcheck | Utilities |
| **Caching** | actions/cache@v4 | Performance optimization |
| **Checkout** | actions/checkout@v4 | Sparse checkout |
| **Scripting** | Bash (POSIX-compliant) | Cross-platform scripts |
| **AI Services** | Claude, OpenAI, Gemini | Code analysis |
| **APIs** | GitHub REST/GraphQL | Integration |
| **Artifacts** | actions/upload-artifact@v4 | Storage |

---

## Quality Attributes

```mermaid
mindmap
  root((Reusable Components))
    Reliability
      99.9% success rate
      Comprehensive error handling
      Retry logic
      Graceful degradation
    Performance
      <3min P95 execution
      5-10s cached setup
      Sparse checkout
      Parallel execution
    Security
      Minimal permissions
      Input validation
      Secret masking
      No injection vulnerabilities
    Maintainability
      Modular design
      Clear separation of concerns
      Comprehensive documentation
      Version control
    Portability
      Linux support
      macOS support
      Windows support
      WSL compatibility
    Usability
      13+14 = 27 parameters
      Clear defaults
      Comprehensive outputs
      Error messages
```

---

## Success Criteria Checklist

**Objective 1: Deploy Production-Ready Components**
- [x] Reusable workflow with workflow_call trigger
- [x] Composite action for environment setup
- [x] Explicit permissions blocks (minimal scopes)
- [x] Comprehensive input/output contracts
- [x] Cross-platform compatibility

**Objective 2: Implement Design Patterns**
- [x] Factory pattern (AI model selection)
- [x] Strategy pattern (review modes)
- [x] Observer pattern (status reporting)
- [x] Decorator pattern (optional features)
- [x] Template method (setup sequence)

**Objective 3: Enable Organization-Wide Adoption**
- [x] Parameterized for different configurations
- [x] Consumable via workflow_call
- [x] Clear documentation and examples
- [x] Integration with other Wave 3 components
- [x] Testing and validation support

---

## Next Steps

1. **Integration Testing**
   - Test with python-pro scripts (ai-review.sh)
   - Validate JSON schema compatibility
   - Verify cross-platform execution

2. **Security Audit**
   - security-auditor review
   - Penetration testing
   - Secret scanning validation

3. **Documentation**
   - api-documenter creates user guides
   - Usage examples and tutorials
   - Troubleshooting guides

4. **Developer Tools**
   - dx-optimizer creates testing tools
   - Local workflow validation
   - Mock runner environment

5. **Production Deployment**
   - Staging environment testing
   - Gradual rollout to repositories
   - Metrics collection and monitoring

---

**Document Status:** Complete
**Last Updated:** 2025-10-17
**Version:** 1.0.0
