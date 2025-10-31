# GitHub Actions Self-Hosted Runner - Label Taxonomy
## Wave 1: Runner Labeling Strategy & Routing Rules

**Document Version:** 1.0
**Date:** October 17, 2025
**Format:** YAML-based taxonomy with routing logic

---

## Executive Summary

This document defines a comprehensive labeling strategy for self-hosted GitHub Actions runners that enables:
- Automatic runner assignment based on workflow requirements
- Team-based resource isolation and capacity management
- Priority routing for critical workflows
- Clear tracking and reporting by project/team
- Future extensibility for AI/LLM workload classification

**Label Categories:**
1. **System Labels** (8 core labels) - Automatic, fixed
2. **Resource Labels** (6 labels) - Performance/capability tiers
3. **Team/Project Labels** (15+ labels) - Organizational grouping
4. **Workflow Type Labels** (10+ labels) - Automation classification
5. **Priority Labels** (3 labels) - Execution priority
6. **Status Labels** (3 labels) - Operational state

---

## Label Categories & Definitions

### 1. System Labels (Core Infrastructure)

These labels are automatically applied to all runners and identify the fundamental runner characteristics.

#### 1.1: `self-hosted`
- **Purpose**: Identifies runner as self-hosted (required by GitHub)
- **Applied**: Automatically to all runners
- **Usage**: GitHub Actions workflow condition: `runs-on: [self-hosted]`
- **Value**: Fixed string "true"
- **Cardinality**: One per runner (mandatory)

#### 1.2: `linux`
- **Purpose**: Identifies operating system family (Unix-like via WSL)
- **Applied**: All runners (since using WSL 2.0 on Windows)
- **Usage**: Workflows requiring bash, linux tools
- **Value**: Fixed string (can also: `windows`, `macos`)
- **Cardinality**: One per runner (exclusive with windows/macos)

#### 1.3: `x64`
- **Purpose**: Identifies processor architecture
- **Applied**: All current runners (standard Intel/AMD)
- **Usage**: Binary compatibility requirements
- **Value**: Fixed string (alternatives: `arm64`, `arm32`)
- **Cardinality**: One per runner (exclusive)

#### 1.4: `ai-agent`
- **Purpose**: Identifies runner capable of AI/LLM workloads
- **Applied**: All runners with LLM integration configured
- **Usage**: Workflows using GitHub Copilot, external LLM APIs
- **Value**: Presence indicates capability
- **Cardinality**: Optional (1 or 0 per runner)

#### 1.5: `wsl-ubuntu-22.04`
- **Purpose**: Identifies WSL distribution and version
- **Applied**: All runners (since WSL is uniform)
- **Usage**: Workflow targeting specific Linux version
- **Value**: Fixed string (could be: `wsl-ubuntu-20.04`, etc.)
- **Cardinality**: One per runner

#### 1.6: `docker-capable`
- **Purpose**: Identifies runner can execute Docker commands
- **Applied**: Runners with Docker Engine installed in WSL
- **Usage**: Workflows requiring container execution
- **Value**: Presence indicates capability
- **Cardinality**: Optional (1 or 0 per runner)

#### 1.7: `gpu-available`
- **Purpose**: Identifies runner has GPU acceleration
- **Applied**: Runners with NVIDIA CUDA available (future)
- **Usage**: ML model training, intensive compute
- **Value**: Presence indicates capability
- **Cardinality**: Optional (1 or 0 per runner)

#### 1.8: `high-memory`
- **Purpose**: Identifies runner with >16 GB RAM
- **Applied**: Runners with expanded memory allocation
- **Usage**: Memory-intensive workloads (IDE analysis, large builds)
- **Value**: Presence indicates capability
- **Cardinality**: Optional (1 or 0 per runner)

#### Example System Labels
```yaml
# Typical runner label set (core labels only)
runner_001:
  system_labels:
    - self-hosted
    - linux
    - x64
    - ai-agent          # LLM capable
    - wsl-ubuntu-22.04  # WSL version
    - docker-capable    # Docker in WSL
```

---

### 2. Resource Labels (Performance Tiers)

These labels identify runner resource capacity and performance characteristics for workload routing.

#### 2.1: `tier-basic`
- **CPU**: 2 vCPU
- **RAM**: 4 GB
- **Use Cases**: Linting, code scanning, quick tests
- **Cost**: $30/month (shared infrastructure)
- **Concurrency**: 2-4 jobs per runner

#### 2.2: `tier-standard`
- **CPU**: 4-6 vCPU
- **RAM**: 8-12 GB
- **Use Cases**: Unit tests, builds, integration tests
- **Cost**: $60/month (dedicated runner)
- **Concurrency**: 2-4 jobs per runner
- **Allocation**: Default for all runners (Year 1)

#### 2.3: `tier-performance`
- **CPU**: 8 vCPU
- **RAM**: 16 GB
- **Use Cases**: E2E tests, heavy builds, matrix builds
- **Cost**: $150/month (dedicated, high-end)
- **Concurrency**: 4 jobs per runner
- **Allocation**: On-demand (scaling beyond base capacity)

#### 2.4: `tier-compute-optimized`
- **CPU**: 16+ vCPU
- **RAM**: 32+ GB
- **Use Cases**: Parallel matrix builds, intensive CI
- **Cost**: $300/month (enterprise tier)
- **Concurrency**: 8+ jobs per runner
- **Allocation**: Reserved for specific projects (future)

#### 2.5: `tier-memory-optimized`
- **CPU**: 4 vCPU
- **RAM**: 32+ GB
- **Use Cases**: Memory-heavy analysis, large datasets
- **Cost**: $200/month (specialized)
- **Concurrency**: 2-4 jobs per runner
- **Allocation**: On-demand for specific workloads

#### 2.6: `tier-io-optimized`
- **CPU**: 4 vCPU
- **RAM**: 16 GB
- **Storage**: High-speed SSD (500+ GB)
- **Use Cases**: Database tests, artifact-heavy workflows
- **Cost**: $180/month (storage-focused)
- **Concurrency**: 2-4 jobs per runner
- **Allocation**: On-demand for storage-intensive work

#### Resource Label Allocation (Wave 1)
```yaml
runners:
  runner_001:
    resource_label: tier-standard    # 4-6 CPU, 8-12 GB RAM
  runner_002:
    resource_label: tier-standard
  runner_003:
    resource_label: tier-standard

  # Dynamic runners (auto-scaling)
  runner_scaling_group:
    resource_label: tier-standard    # Spin up as needed
    min_capacity: 3
    max_capacity: 5
    scaling_trigger: queue_depth > 5
```

---

### 3. Team/Project Labels (Organizational Structure)

These labels enable organizational routing and capacity isolation by team and project.

#### Defined Teams/Projects (Example Organization)

```yaml
team_labels:
  backend:
    label: "team-backend"
    repos: ["api-server", "microservices", "database"]
    lead: "backend-eng-lead"
    reserved_capacity: 1 runner

  frontend:
    label: "team-frontend"
    repos: ["web-app", "mobile-app", "ui-components"]
    lead: "frontend-eng-lead"
    reserved_capacity: 1 runner

  platform:
    label: "team-platform"
    repos: ["infra", "devops", "ci-cd"]
    lead: "platform-eng-lead"
    reserved_capacity: 1 runner

  data:
    label: "team-data"
    repos: ["analytics", "ml-models", "data-pipeline"]
    lead: "data-eng-lead"
    reserved_capacity: 0.5 runner (shared)

  ai-agents:
    label: "team-ai-agents"
    repos: ["ai-review-agent", "code-gen-agent", "testing-agent"]
    lead: "ai-lead"
    reserved_capacity: 0.5 runner (specialized)
```

#### Project-Specific Labels
```yaml
project_labels:
  # Critical Projects (guaranteed capacity)
  project-payments:
    label: "project-payments"
    priority: critical
    reserved_capacity: 0.5 runner
    sla: 99.95%

  # Standard Projects (shared capacity)
  project-docs:
    label: "project-docs"
    priority: normal
    reserved_capacity: none
    sla: 95%
```

#### Team Label Routing Rules
```yaml
routing_rules:
  team_based:
    - if: repository.owner_team == "backend"
      then: assign runner with label "team-backend"
      fallback: use shared pool
      priority: 1

    - if: repository.owner_team == "frontend"
      then: assign runner with label "team-frontend"
      fallback: use shared pool
      priority: 1

    - if: workflow contains label "team-*"
      then: prefer runner matching label
      fallback: use shared pool
      priority: 2
```

---

### 4. Workflow Type Labels (Automation Classification)

These labels categorize workflows by function for targeting and tracking.

#### 4.1: `workflow-pr-review`
- **Purpose**: AI-powered pull request review
- **Typical Jobs**: LLM code analysis, comment generation
- **Requirements**: ai-agent label, <5 minute timeout
- **Frequency**: 50-100/day
- **Priority**: High

#### 4.2: `workflow-issue-triage`
- **Purpose**: Automated issue categorization and response
- **Typical Jobs**: Issue analysis, label assignment, auto-response
- **Requirements**: ai-agent label, <2 minute timeout
- **Frequency**: 20-40/day
- **Priority**: Normal

#### 4.3: `workflow-code-quality`
- **Purpose**: Code linting, SAST, style checks
- **Typical Jobs**: Lint, format check, dependency scan
- **Requirements**: Standard runner, <5 minute timeout
- **Frequency**: 80-120/day
- **Priority**: High

#### 4.4: `workflow-unit-tests`
- **Purpose**: Unit test execution
- **Typical Jobs**: Jest, pytest, go test, cargo test
- **Requirements**: Standard runner, <15 minute timeout
- **Frequency**: 60-100/day
- **Priority**: Critical

#### 4.5: `workflow-integration-tests`
- **Purpose**: Integration and API tests
- **Typical Jobs**: DB tests, API tests, microservice tests
- **Requirements**: Standard/Performance runner, <30 minute timeout
- **Frequency**: 40-60/day
- **Priority**: High

#### 4.6: `workflow-build`
- **Purpose**: Build and package artifacts
- **Typical Jobs**: Compile, docker build, npm build
- **Requirements**: Standard runner, <10 minute timeout
- **Frequency**: 50-80/day
- **Priority**: Critical

#### 4.7: `workflow-security-scan`
- **Purpose**: Security scanning and vulnerability detection
- **Typical Jobs**: SAST, dependency scan, container scan
- **Requirements**: Standard runner, <15 minute timeout
- **Frequency**: 20-30/day
- **Priority**: Critical

#### 4.8: `workflow-e2e-tests`
- **Purpose**: End-to-end and UI testing
- **Typical Jobs**: Selenium, Playwright, Cypress tests
- **Requirements**: Performance runner, <60 minute timeout
- **Frequency**: 10-20/day
- **Priority**: Normal

#### 4.9: `workflow-deploy`
- **Purpose**: Deployment to staging/production
- **Typical Jobs**: Build, push artifacts, deploy
- **Requirements**: Performance runner, special permissions
- **Frequency**: 5-10/day
- **Priority**: Critical

#### 4.10: `workflow-docs`
- **Purpose**: Documentation generation and deployment
- **Typical Jobs**: Build docs, deploy to GitHub Pages
- **Requirements**: Standard runner, <10 minute timeout
- **Frequency**: 5-10/day
- **Priority**: Low

#### Workflow Label Assignment Strategy
```yaml
workflow_routing:
  by_workflow_trigger:
    pull_request:
      default_labels:
        - workflow-code-quality
        - workflow-unit-tests
        - workflow-build
      optional_labels:
        - workflow-pr-review        # If AI agent enabled
        - workflow-integration-tests # If complex project

    issue:
      default_labels:
        - workflow-issue-triage     # If AI agent enabled

    schedule:
      default_labels:
        - workflow-security-scan
        - workflow-e2e-tests

    push:
      default_labels:
        - workflow-code-quality
        - workflow-build
      optional_labels:
        - workflow-deploy           # If deployment trigger
```

---

### 5. Priority Labels (Execution Priority)

These labels control workflow prioritization in the queue.

#### 5.1: `priority-critical`
- **Queue Position**: Jump to front (if <3 queued)
- **Use Cases**: Production deployments, security fixes, outages
- **Frequency**: <5 per day
- **SLA**: <30 seconds queue wait

#### 5.2: `priority-high`
- **Queue Position**: After critical, before normal
- **Use Cases**: PR reviews, unit tests, feature development
- **Frequency**: 50-100 per day
- **SLA**: <2 minutes queue wait

#### 5.3: `priority-normal`
- **Queue Position**: Standard FIFO
- **Use Cases**: Regular CI/CD, documentation, non-urgent
- **Frequency**: 100-200 per day
- **SLA**: <5 minutes queue wait

#### Priority Enforcement Rules
```yaml
priority_rules:
  - label: priority-critical
    queue_position: 1
    conditions:
      - repository.name == "main-product"
      - workflow.name includes "deploy"
      - branch == "production"

  - label: priority-high
    queue_position: 2
    conditions:
      - workflow.type == "code-quality"
      - pull_request.draft == false

  - label: priority-normal
    queue_position: 3
    conditions:
      - default for all workflows
```

---

### 6. Status Labels (Operational State)

These labels track runner operational state.

#### 6.1: `status-active`
- **Meaning**: Runner is operational and accepting jobs
- **Applied**: Active runners with <5 minute uptime
- **Monitoring**: Heartbeat check every 30 seconds

#### 6.2: `status-draining`
- **Meaning**: Runner completing current jobs, not accepting new
- **Applied**: During maintenance or scale-down
- **Behavior**: Graceful shutdown after current jobs complete

#### 6.3: `status-offline`
- **Meaning**: Runner not responsive
- **Applied**: After 2 consecutive failed heartbeats
- **Action**: Alert DevOps, attempt recovery, mark for re-image

---

## Label Assignment Strategy

### Automatic Assignment

Labels automatically assigned at runner provisioning:

```yaml
auto_assign_on_provision:
  system_labels:
    - self-hosted           # Always
    - linux                 # Via WSL 2.0
    - x64                   # Standard arch
    - wsl-ubuntu-22.04      # Fixed WSL version
    - ai-agent              # If LLM configured
    - docker-capable        # If Docker installed

  resource_labels:
    - tier-standard         # Default tier (Year 1)

  status_labels:
    - status-active         # Upon successful registration
```

### Manual Assignment

Labels assigned by DevOps team based on context:

```yaml
manual_assign_by_devops:
  team_labels:
    - based on runner dedicated team
    - example: team-backend for backend projects

  project_labels:
    - based on critical project assignment
    - example: project-payments for payments team

  status_labels:
    - status-draining when maintenance scheduled
    - status-offline when unresponsive
```

### Dynamic Assignment

Labels applied by automation based on workflow analysis:

```yaml
dynamic_assignment:
  workflow_type_labels:
    - determined by workflow file content
    - applied by GitHub Actions on job queue
    - not stored on runner (ephemeral)

  priority_labels:
    - applied by workflow definition
    - can be overridden per job
```

---

## Workflow Usage Examples

### Example 1: Standard PR Review Workflow

```yaml
name: PR Review Pipeline
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  code-quality:
    runs-on: [self-hosted, linux, x64, tier-standard, workflow-code-quality]
    steps:
      - uses: actions/checkout@v3
      - run: npm lint
      - run: npm audit

  unit-tests:
    runs-on: [self-hosted, linux, x64, tier-standard, workflow-unit-tests]
    steps:
      - uses: actions/checkout@v3
      - run: npm test

  ai-review:
    runs-on: [self-hosted, linux, x64, ai-agent, workflow-pr-review]
    steps:
      - uses: actions/checkout@v3
      - run: npm run ai:review
```

**Routing Logic:**
- `code-quality` job: Matches label `workflow-code-quality`, routed to tier-standard runner
- `unit-tests` job: Matches label `workflow-unit-tests`, routed to tier-standard runner
- `ai-review` job: Requires `ai-agent` label, routed to AI-capable runner

### Example 2: Team-Isolated Workflow

```yaml
name: Backend Services CI
on:
  push:
    branches: [main, develop]
    paths:
      - 'services/**'

jobs:
  tests:
    runs-on:
      - self-hosted
      - linux
      - x64
      - tier-standard
      - team-backend           # Team isolation
      - priority-high          # High priority
    steps:
      - uses: actions/checkout@v3
      - run: make test-backend
```

**Routing Logic:**
- `team-backend` label ensures backend team has reserved capacity
- Shared runner pool fallback if no dedicated runner available
- `priority-high` ensures reasonable queue position

### Example 3: AI Agent Workflow

```yaml
name: Issue Auto-Response
on:
  issues:
    types: [opened]

jobs:
  triage:
    runs-on:
      - self-hosted
      - linux
      - x64
      - ai-agent              # AI capability required
      - workflow-issue-triage
      - priority-normal
    steps:
      - uses: actions/checkout@v3
      - uses: my-org/ai-triage-action@v1
        with:
          api_token: ${{ secrets.OPENAI_API_KEY }}
```

**Requirements:**
- Runner MUST have `ai-agent` label (LLM integration configured)
- Timeout: 2 minutes
- Secret injection: OPENAI_API_KEY available

---

## Label Management Procedures

### Adding New Team/Project

```yaml
procedure:
  1. DevOps creates new label: "team-newteam" or "project-newproject"
  2. Label added to runner pool allocation
  3. Workflow documentation updated with new label
  4. Team notified of label availability
  5. Capacity monitoring enabled for new label
```

### Modifying Runner Resource Tier

```yaml
procedure:
  1. Identify runner for modification
  2. Drain runner (status-draining)
  3. Update resource configuration
  4. Update resource label (e.g., tier-standard → tier-performance)
  5. Re-image runner and re-register
  6. Update team capacity planning
  7. Status-active when ready
```

### Retiring Runner/Label

```yaml
procedure:
  1. Set status-draining on runner
  2. Allow current jobs to complete (<30 min)
  3. Remove from GitHub runner group
  4. Archive runner in tracking system
  5. Notify teams of capacity change
  6. Update capacity planning model
```

---

## Reporting & Analytics

### Dashboard Metrics

```yaml
metrics_by_label:
  - workflow_type:
      - avg_job_duration (group by workflow-* labels)
      - success_rate
      - queue_wait_time
      - frequency

  - team:
      - total_workflows_run (group by team-* labels)
      - cost_allocation
      - reserved_capacity_utilization
      - peak_concurrency

  - priority:
      - avg_queue_wait (group by priority-* labels)
      - sla_compliance
      - frequency

  - resource_tier:
      - utilization_percent (group by tier-* labels)
      - cost_per_workflow
      - job_distribution
```

### Sample Reports

**Daily Standup:**
- Total workflows: 200
- Queue depth: 3 (target: <5)
- Avg wait time: 45 seconds (target: <2 min)
- Success rate: 97.5% (target: >95%)
- Runners active: 4/5 (one scaling)

**Weekly Analysis:**
- Workflow distribution by type
- Team usage and cost allocation
- Top issues and blockers
- Capacity forecast for next week

---

## Future Enhancements

### V2: Advanced Labeling
- Geographic labels: `region-us-east`, `region-eu-west`
- Workload type: `gpu-intensive`, `memory-intensive`
- Compliance labels: `sox-compliant`, `hipaa-ready`

### V3: ML-Based Routing
- Predictive label assignment based on workflow content
- Dynamic tier selection based on historical performance
- Automatic resource optimization

### V4: Cost Attribution
- Per-team cost tracking with labels
- Chargeback model integration
- Budget alerts and capacity limits

---

## Appendix: Complete Label Reference

```yaml
system_labels:
  - self-hosted
  - linux
  - x64
  - ai-agent
  - wsl-ubuntu-22.04
  - docker-capable
  - gpu-available
  - high-memory

resource_labels:
  - tier-basic
  - tier-standard
  - tier-performance
  - tier-compute-optimized
  - tier-memory-optimized
  - tier-io-optimized

team_labels:
  - team-backend
  - team-frontend
  - team-platform
  - team-data
  - team-ai-agents

project_labels:
  - project-payments
  - project-docs

workflow_type_labels:
  - workflow-pr-review
  - workflow-issue-triage
  - workflow-code-quality
  - workflow-unit-tests
  - workflow-integration-tests
  - workflow-build
  - workflow-security-scan
  - workflow-e2e-tests
  - workflow-deploy
  - workflow-docs

priority_labels:
  - priority-critical
  - priority-high
  - priority-normal

status_labels:
  - status-active
  - status-draining
  - status-offline

total_labels_defined: 48
```

---

*End of Label Taxonomy Document*
