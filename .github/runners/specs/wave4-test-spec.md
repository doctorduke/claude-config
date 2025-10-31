# Wave 4: System Validation & Testing Specification

## CONTEXT / BACKGROUND

### Problem
After Wave 3 completes implementation of all self-hosted runner workflows, scripts, and automation, we need comprehensive validation to ensure the system meets performance, security, and reliability requirements before production deployment. Without rigorous testing across functional, performance, security, error handling, integration, and failure scenarios, we risk deploying a system that fails under real-world conditions.

### Constraints
- Testing must run in parallel across 6 specialist agents to minimize validation time
- Tests must use real GitHub repositories and events (not just mocks)
- Performance baselines must compare against GitHub-hosted runners
- Security audits must not expose credentials or violate least-privilege principles
- All tests must be deterministic and repeatable
- Test infrastructure must not incur excessive costs

### Current State
Wave 3 has delivered:
- Self-hosted runner infrastructure (Docker containers, network configuration)
- GitHub Actions workflows (.github/workflows/*.yml) for all event types
- AI agent scripts (scripts/agents/*.sh) with GitHub API integration
- Permission configurations (GITHUB_TOKEN vs PAT scenarios)
- Documentation and operational runbooks

Wave 4 validates everything works correctly through systematic testing.

---

## OUTCOMES / SUCCESS CRITERIA (OKRs)

### Objective 1: Validate Functional Correctness
**KR1.1:** All PR review workflows execute successfully (approve, request changes, comment) - 100% pass rate
**KR1.2:** All issue comment workflows execute successfully - 100% pass rate
**KR1.3:** All auto-fix workflows execute successfully (commit, push, PR creation) - 100% pass rate
**KR1.4:** All GitHub event types trigger appropriate workflows - 100% coverage

### Objective 2: Meet Performance Targets
**KR2.1:** Job start latency < 60 seconds (from event to job start) - p95
**KR2.2:** Checkout time 70% faster than GitHub-hosted runners
**KR2.3:** Total workflow duration 50% faster than GitHub-hosted runners
**KR2.4:** Runner idle time < 5% of total uptime

### Objective 3: Ensure Security Compliance
**KR3.1:** Zero credential leaks in logs, artifacts, or outputs
**KR3.2:** All workflows use least-privilege permissions (GITHUB_TOKEN where possible)
**KR3.3:** PAT usage validated only for write operations requiring elevated permissions
**KR3.4:** No secrets exposed in error messages or stack traces

### Objective 4: Validate Error Handling
**KR4.1:** All error scenarios handled gracefully (network, API, Git conflicts)
**KR4.2:** Error messages provide actionable troubleshooting steps
**KR4.3:** Failed workflows do not leave repositories in inconsistent state
**KR4.4:** Retry logic handles transient failures correctly

### Objective 5: Verify Integration Reliability
**KR5.1:** Workflows execute consistently across 5+ different repositories
**KR5.2:** Multi-language codebases handled correctly (Python, JavaScript, Go, Java, etc.)
**KR5.3:** Large repositories (>1000 files) processed without timeout
**KR5.4:** Concurrent workflows do not interfere with each other

### Objective 6: Test Failure Recovery
**KR6.1:** System recovers from runner failures within 2 minutes
**KR6.2:** Disk space exhaustion handled without data loss
**KR6.3:** Network partitions do not cause workflow corruption
**KR6.4:** Runner restarts preserve workflow state correctly

---

## REQUIREMENTS

### Functional Requirements

#### F1: Test Coverage
The test suite **must**:
- Cover all GitHub event types: `pull_request`, `issue_comment`, `push`, `workflow_dispatch`
- Validate all agent capabilities: PR reviews (approve/request_changes/comment), issue comments, commits, branch creation
- Test all permission scenarios: GITHUB_TOKEN (read-only), PAT (write operations)
- Verify branch protection compatibility
- Test webhook delivery and retry mechanisms

#### F2: Test Execution
The test suite **must**:
- Execute tests in parallel across 6 specialist agents
- Use real GitHub repositories (not mocks) for integration tests
- Generate reproducible test data (sample PRs, issues, commits)
- Clean up test artifacts after execution
- Record all test results with timestamps and evidence

#### F3: Test Data Management
The test suite **must**:
- Provide test repositories with representative code (multiple languages)
- Generate PRs with realistic code changes (bugs, style issues, logic errors)
- Create issues with various labels and states
- Maintain test data versioning for repeatability

### Non-Functional Requirements (Quality Attributes)

#### NF1: Performance
- Test execution time < 30 minutes for full suite
- Individual test cases < 5 minutes
- Performance tests run for 10+ iterations to establish p50/p95/p99 metrics

#### NF2: Reliability
- Tests must be deterministic (no flaky tests)
- Test failures must be actionable (clear root cause)
- Tests must clean up resources even when failing

#### NF3: Security
- No credentials in test code or logs
- Test PATs must have minimal scopes (repo only)
- Test repositories must not contain sensitive data

#### NF4: Maintainability
- Test results in markdown format with clear pass/fail status
- Performance metrics in CSV/JSON for trend analysis
- Security findings categorized by severity (critical/high/medium/low)

#### NF5: Portability
- Tests run on Windows, Linux, macOS
- Docker-based tests isolated from host environment
- No hardcoded paths or environment-specific assumptions

---

## PLAN / WORK BREAKDOWN / DELIVERABLES

### Phase 1: Test Infrastructure Setup (Agent: test-automator)
**Duration:** First parallel block
**Deliverables:**
- `test-results/functional-tests.md` - Functional test results
- `test-fixtures/` - Sample repositories, PRs, issues for testing
- `test-scripts/` - Reusable test execution scripts

**Tasks:**
1. Create test fixture repositories (Python, JavaScript, Go, Java samples)
2. Generate sample PRs with intentional issues (linting errors, security bugs)
3. Set up test data cleanup automation
4. Execute functional tests for all workflow types
5. Document test results with evidence (workflow run URLs, commit SHAs)

### Phase 2: Performance Benchmarking (Agent: performance-engineer)
**Duration:** First parallel block
**Deliverables:**
- `test-results/performance-benchmarks.md` - Performance comparison report
- `test-results/performance-metrics.csv` - Raw performance data (p50/p95/p99)
- `test-results/performance-comparison.json` - Self-hosted vs GitHub-hosted comparison

**Tasks:**
1. Baseline GitHub-hosted runner performance (job start, checkout, total duration)
2. Measure self-hosted runner performance for identical workflows
3. Run 20+ iterations to establish statistical significance
4. Calculate p50, p95, p99 latencies for all metrics
5. Generate comparison charts and recommendations

### Phase 3: Security Audit (Agent: security-auditor)
**Duration:** First parallel block
**Deliverables:**
- `test-results/security-audit.md` - Security findings and recommendations
- `test-results/permission-validation.csv` - Permission usage analysis
- `test-results/secret-scan-results.json` - Credential leak scan results

**Tasks:**
1. Audit all workflow files for permission configurations
2. Validate GITHUB_TOKEN vs PAT usage patterns
3. Scan logs and artifacts for credential leaks
4. Test least-privilege enforcement
5. Verify secrets handling in error scenarios

### Phase 4: Error Scenario Testing (Agent: error-detective)
**Duration:** Second parallel block (depends on Phase 1 fixtures)
**Deliverables:**
- `test-results/error-scenarios.md` - Error handling validation results
- `test-results/error-recovery-tests.json` - Recovery behavior analysis

**Tasks:**
1. Test network failure scenarios (API timeout, connection reset)
2. Test GitHub API error responses (rate limits, 500 errors, 403 forbidden)
3. Test Git conflict scenarios (merge conflicts, branch protection violations)
4. Test permission denial scenarios (read-only token for write operations)
5. Validate error messages and retry logic

### Phase 5: Integration Testing (Agent: debugger)
**Duration:** Second parallel block (depends on Phase 1 fixtures)
**Deliverables:**
- `test-results/integration-tests.md` - Multi-repo integration test results
- `test-results/integration-matrix.csv` - Test coverage matrix (repos x workflows)

**Tasks:**
1. Test workflows across 5+ repositories (different languages, sizes)
2. Test concurrent workflow execution (no interference)
3. Test large repository handling (>1000 files)
4. Test multi-language codebases (monorepos)
5. Validate cross-repository consistency

### Phase 6: Failure Simulation (Agent: incident-responder)
**Duration:** Second parallel block (can run in parallel with Phases 4-5)
**Deliverables:**
- `test-results/failure-scenarios.md` - Failure recovery test results
- `test-results/chaos-tests.json` - Chaos engineering test data
- `runbooks/incident-response-validation.md` - Validated incident response procedures

**Tasks:**
1. Simulate runner container crashes (kill -9, Docker stop)
2. Simulate disk space exhaustion (fill disk to 95%+)
3. Simulate network partitions (iptables rules, DNS failures)
4. Test runner restart and workflow state preservation
5. Validate monitoring alerts and recovery procedures

---

## PROBLEMS • RISKS • ASSUMPTIONS • DEPENDENCIES

### Problems
- **Test Data Cleanup:** Test PRs and issues accumulate in repositories - need cleanup automation
- **Rate Limiting:** GitHub API rate limits may throttle test execution - need backoff strategy
- **Test Isolation:** Concurrent tests may interfere - need proper test namespacing
- **Cost Control:** Multiple test iterations consume compute resources - need budget monitoring

### Risks
- **R1 (High):** Flaky tests due to GitHub API variability - Mitigation: Retry logic and statistical sampling
- **R2 (Medium):** Performance tests biased by network conditions - Mitigation: Run tests at consistent times, measure network latency separately
- **R3 (Medium):** Security tests may inadvertently expose credentials - Mitigation: Use dedicated test PATs with minimal scopes, scan all outputs
- **R4 (Low):** Failure simulations may destabilize runner environment - Mitigation: Use isolated test runners, implement failsafes

### Assumptions
- **A1:** Wave 3 deliverables (workflows, scripts, infrastructure) are complete and functional
- **A2:** Test agents have access to GitHub repositories for test fixture creation
- **A3:** Self-hosted runners are deployed and accessible for testing
- **A4:** GitHub API rate limits allow for 100+ API calls during test execution
- **A5:** Test PATs have `repo` scope for creating test data

### Dependencies
- **D1:** Wave 3 completion (all workflows and scripts implemented)
- **D2:** Self-hosted runner infrastructure operational
- **D3:** Test repositories available (or permission to create them)
- **D4:** GitHub PAT with appropriate scopes for test automation
- **D5:** Docker environment for failure simulation tests

---

## PRIORITIZATION (MoSCoW)

### Must Have
- Functional tests for all workflow types (PR review, issue comment, auto-fix)
- Performance benchmarks for job start latency, checkout time, total duration
- Security audit for credential leaks and permission validation
- Error scenario tests for network, API, and Git failures
- Test results documentation for all 6 specialist areas

### Should Have
- Integration tests across 5+ repositories
- Failure recovery simulations (runner crashes, disk full)
- Performance trend analysis (compare against baselines over time)
- Chaos engineering tests (network partitions, resource exhaustion)
- Automated test data cleanup

### Could Have
- Visual performance dashboards (charts, graphs)
- Load testing (concurrent workflow execution limits)
- Multi-region performance comparison
- Advanced security scans (SAST, dependency vulnerabilities)
- Test coverage heatmaps

### Won't Have (This Wave)
- End-user acceptance testing (requires production deployment)
- Cost optimization testing (requires billing data)
- Multi-cloud runner comparison (AWS, GCP, Azure)
- Custom GitHub App development for testing

---

## STATUS & MILESTONES / ROADMAP

### Pre-Wave 4
- [x] Wave 1: Planning and architecture complete
- [x] Wave 2: Infrastructure provisioning complete
- [x] Wave 3: Workflow and script implementation complete

### Wave 4 Milestones
- [ ] M1: Test infrastructure setup complete (test fixtures, repositories)
- [ ] M2: Parallel testing Phase 1 complete (functional, performance, security)
- [ ] M3: Parallel testing Phase 2 complete (error scenarios, integration, failure simulation)
- [ ] M4: All test results documented and analyzed
- [ ] M5: Production readiness assessment complete
- [ ] M6: Wave 4 sign-off (system validated for production)

### Post-Wave 4
- [ ] Wave 5: Production deployment and monitoring

**Timeline:** Wave 4 estimated 2-3 days (assuming parallel execution)

---

## AGENT PROMPT SPECS / POLICIES

### Agent 1: test-automator

**Role:** Execute comprehensive functional tests for all workflows

**Context:**
You are validating the functional correctness of self-hosted GitHub Actions workflows implemented in Wave 3. Your goal is to verify that all workflows execute successfully for their intended event types and produce the expected outcomes (PR reviews, issue comments, commits, branch creation).

**Inputs:**
- Wave 3 workflow files: `.github/workflows/*.yml`
- Wave 3 agent scripts: `scripts/agents/*.sh`
- Test repository configuration: `test-fixtures/repos.json`

**Tasks:**

1. **Test Fixture Setup**
   - Create 3 test repositories: `test-python-app`, `test-javascript-app`, `test-go-app`
   - Populate each repository with realistic code (150-300 lines per file)
   - Add intentional issues: linting errors, security bugs, code smells
   - Create 5 sample PRs per repository with varying complexity

2. **Functional Test Execution**

   **Test Suite 1: PR Review Workflows**
   - Test Case 1.1: PR with critical security issues → Workflow runs, agent posts "request changes" review
   - Test Case 1.2: PR with minor linting issues → Workflow runs, agent posts "comment" review
   - Test Case 1.3: PR with no issues → Workflow runs, agent posts "approve" review
   - Test Case 1.4: PR from fork (GITHUB_TOKEN permissions) → Workflow runs with read-only permissions
   - Test Case 1.5: PR with branch protection → Workflow respects protection rules

   **Test Suite 2: Issue Comment Workflows**
   - Test Case 2.1: Issue with `needs-triage` label → Workflow runs, agent analyzes and comments
   - Test Case 2.2: Issue with `bug` label → Workflow provides debugging suggestions
   - Test Case 2.3: Issue with `question` label → Workflow provides helpful response
   - Test Case 2.4: Issue comment trigger (`/analyze`) → Workflow runs on command

   **Test Suite 3: Auto-Fix Workflows**
   - Test Case 3.1: Auto-fix linting errors → Workflow commits fixes, pushes to branch
   - Test Case 3.2: Auto-fix security issues → Workflow creates new branch, opens PR
   - Test Case 3.3: Auto-fix with Git conflicts → Workflow handles conflicts gracefully
   - Test Case 3.4: Auto-fix with branch protection → Workflow creates PR instead of direct push

3. **Evidence Collection**
   - For each test case, record:
     - Workflow run URL
     - Workflow status (success/failure)
     - Agent output (PR review, comment, commit SHA)
     - Execution time (start to completion)
     - Any errors or warnings

4. **Test Results Documentation**
   - Generate `test-results/functional-tests.md` with:
     - Test case summary table (test ID, description, status, evidence URL)
     - Pass/fail statistics (total tests, passed, failed, skipped)
     - Failure analysis (root cause, recommended fixes)
     - Screenshots or log excerpts for key test cases

**Pass Criteria:**
- 100% of critical workflows pass (PR review, issue comment, auto-fix)
- All test cases have documented evidence (workflow run URLs, commit SHAs)
- No workflows leave repositories in inconsistent state
- All error messages are actionable

**Output Contract:**
```markdown
# Functional Test Results

## Summary
- Total test cases: XX
- Passed: XX (XX%)
- Failed: XX (XX%)
- Execution time: XX minutes

## Test Suite 1: PR Review Workflows
| Test ID | Description | Status | Evidence | Notes |
|---------|-------------|--------|----------|-------|
| 1.1 | PR with critical issues | PASS | [Run URL] | Agent posted request_changes review |
| 1.2 | PR with minor issues | PASS | [Run URL] | Agent posted comment review |
...

## Test Suite 2: Issue Comment Workflows
...

## Test Suite 3: Auto-Fix Workflows
...

## Failures Analysis
[If any test failed, provide root cause and recommended fix]

## Next Actions
[Recommended improvements or follow-up tests]
```

**Constraints:**
- Use real GitHub repositories (not mocks)
- Clean up test data after completion (close PRs, delete branches)
- No hardcoded credentials (use environment variables)
- Test execution time < 20 minutes

---

### Agent 2: performance-engineer

**Role:** Measure and benchmark workflow performance against targets

**Context:**
You are establishing performance baselines for self-hosted runners and comparing them against GitHub-hosted runners. The primary metrics are job start latency, checkout time, and total workflow duration. Performance targets: job start <60s (p95), checkout 70% faster, total duration 50% faster.

**Inputs:**
- Test workflow: `test-fixtures/benchmark-workflow.yml` (standardized workflow for comparison)
- Performance targets: Job start <60s, checkout 70% faster, total 50% faster
- Sample size: 20 iterations per scenario

**Tasks:**

1. **Baseline GitHub-Hosted Runner Performance**
   - Create benchmark workflow that measures: job start time, checkout time, total duration
   - Run workflow 20 times on GitHub-hosted runner (`runs-on: ubuntu-latest`)
   - Record metrics for each run: `job_start_time`, `checkout_time`, `total_duration`
   - Calculate p50, p95, p99 for each metric

2. **Measure Self-Hosted Runner Performance**
   - Run same benchmark workflow 20 times on self-hosted runner (`runs-on: self-hosted`)
   - Record identical metrics for comparison
   - Calculate p50, p95, p99 for each metric

3. **Performance Comparison Analysis**
   - Calculate percentage improvement for each metric:
     - Job start latency: `(github_hosted_p95 - self_hosted_p95) / github_hosted_p95 * 100`
     - Checkout time: `(github_hosted_p95 - self_hosted_p95) / github_hosted_p95 * 100`
     - Total duration: `(github_hosted_p95 - self_hosted_p95) / github_hosted_p95 * 100`
   - Compare against targets (job start <60s, checkout 70% faster, total 50% faster)
   - Identify bottlenecks if targets not met

4. **Repository Size Impact Analysis**
   - Test performance with small repo (<100 files), medium repo (500 files), large repo (2000 files)
   - Measure checkout time scaling
   - Identify optimal repository size limits

5. **Concurrent Workflow Performance**
   - Trigger 5 workflows simultaneously
   - Measure queue time, execution time, total time
   - Validate no resource contention

**Performance Metrics to Collect:**
```
For each workflow run:
- workflow_run_id: GitHub workflow run ID
- runner_type: "github-hosted" | "self-hosted"
- job_queued_at: Timestamp when job queued
- job_started_at: Timestamp when job started
- checkout_started_at: Timestamp when checkout started
- checkout_completed_at: Timestamp when checkout completed
- job_completed_at: Timestamp when job completed
- job_start_latency: job_started_at - job_queued_at (seconds)
- checkout_duration: checkout_completed_at - checkout_started_at (seconds)
- total_duration: job_completed_at - job_queued_at (seconds)
- repo_size_mb: Repository size in MB
- file_count: Number of files in repository
```

**Output Contract:**
```markdown
# Performance Benchmark Results

## Executive Summary
- Job start latency (p95): Xs (Target: <60s) - [PASS/FAIL]
- Checkout time improvement: XX% faster (Target: 70%) - [PASS/FAIL]
- Total duration improvement: XX% faster (Target: 50%) - [PASS/FAIL]

## Detailed Metrics

### GitHub-Hosted Runner Baseline
| Metric | p50 | p95 | p99 | Avg | StdDev |
|--------|-----|-----|-----|-----|--------|
| Job start latency | Xs | Xs | Xs | Xs | Xs |
| Checkout duration | Xs | Xs | Xs | Xs | Xs |
| Total duration | Xs | Xs | Xs | Xs | Xs |

### Self-Hosted Runner Performance
| Metric | p50 | p95 | p99 | Avg | StdDev |
|--------|-----|-----|-----|-----|--------|
| Job start latency | Xs | Xs | Xs | Xs | Xs |
| Checkout duration | Xs | Xs | Xs | Xs | Xs |
| Total duration | Xs | Xs | Xs | Xs | Xs |

### Comparison (% Improvement)
| Metric | p50 | p95 | p99 | Target | Status |
|--------|-----|-----|-----|--------|--------|
| Job start latency | -XX% | -XX% | -XX% | <60s | PASS/FAIL |
| Checkout duration | +XX% | +XX% | +XX% | +70% | PASS/FAIL |
| Total duration | +XX% | +XX% | +XX% | +50% | PASS/FAIL |

## Repository Size Impact
[Table showing checkout time vs repo size]

## Bottleneck Analysis
[Identify why targets not met, if applicable]

## Recommendations
[Optimization suggestions]
```

**Deliverables:**
- `test-results/performance-benchmarks.md` - Main report
- `test-results/performance-metrics.csv` - Raw data for all runs
- `test-results/performance-comparison.json` - JSON data for dashboards

**Constraints:**
- Run tests during consistent time of day (avoid network variability)
- Use identical workflows for GitHub-hosted vs self-hosted comparison
- Measure network latency separately (ping to GitHub API)
- Statistical significance: 20+ iterations per scenario

---

### Agent 3: security-auditor

**Role:** Audit workflows for security vulnerabilities and credential leaks

**Context:**
You are ensuring the self-hosted runner system adheres to security best practices: least-privilege permissions, no credential leaks, proper PAT usage, and secure secrets handling. All workflows must use GITHUB_TOKEN for read operations and PAT only when write permissions are required.

**Inputs:**
- Workflow files: `.github/workflows/*.yml`
- Agent scripts: `scripts/agents/*.sh`
- Logs from test workflow runs
- Environment variable configurations

**Tasks:**

1. **Permission Validation Audit**

   For each workflow file:
   - Verify `permissions:` block is explicitly defined (not default)
   - Check if permissions follow least-privilege:
     - Read operations use `contents: read`, `pull-requests: read`, `issues: read`
     - Write operations use minimal scopes (`contents: write` only when needed)
   - Validate GITHUB_TOKEN vs PAT usage:
     - GITHUB_TOKEN for: fetching PR details, reading files, posting comments
     - PAT for: committing to branches, creating PRs, approving PRs
   - Document permission configurations in matrix

2. **Credential Leak Scanning**

   Scan all outputs for credential exposure:
   - Workflow logs (GitHub Actions logs)
   - Agent script outputs (stdout/stderr)
   - Git commit messages and PR descriptions
   - Error messages and stack traces
   - Artifacts and cache contents

   Search patterns:
   - `github_pat_[A-Za-z0-9_]+` (GitHub PAT tokens)
   - `ghp_[A-Za-z0-9]+` (Classic PAT tokens)
   - `Authorization: Bearer` (HTTP headers)
   - Environment variables in logs (`echo $GITHUB_TOKEN`)
   - Base64-encoded credentials

3. **Secrets Handling Validation**

   Verify proper secrets management:
   - Secrets accessed via `${{ secrets.NAME }}` syntax (not environment variables in logs)
   - No secrets in error messages (`catch` blocks sanitize outputs)
   - No secrets in debug mode outputs
   - Secrets rotation capability tested

4. **Branch Protection Compatibility**

   Test workflows against branch protection rules:
   - Workflows respect `required reviews` rules
   - Workflows cannot bypass `status checks`
   - PAT-based commits trigger status checks correctly
   - No workflows use `--force` push

5. **Network Security Audit**

   Verify network security:
   - All API calls use HTTPS (no HTTP)
   - Certificate validation enabled (no `--insecure` flags)
   - No hardcoded IP addresses (use domain names)
   - Outbound traffic limited to GitHub API endpoints

**Security Checks Checklist:**
```
- [ ] All workflows define explicit permissions (no defaults)
- [ ] GITHUB_TOKEN used for read operations
- [ ] PAT used only for write operations requiring elevated permissions
- [ ] No credentials in workflow logs
- [ ] No credentials in agent script outputs
- [ ] No credentials in error messages
- [ ] No credentials in Git commit messages
- [ ] Secrets accessed via ${{ secrets.NAME }} only
- [ ] All API calls use HTTPS
- [ ] Certificate validation enabled
- [ ] No --force push in workflows
- [ ] Branch protection rules respected
- [ ] Status checks triggered correctly
- [ ] No hardcoded credentials in scripts
- [ ] Environment variables sanitized in outputs
```

**Output Contract:**
```markdown
# Security Audit Report

## Executive Summary
- Critical findings: X
- High findings: X
- Medium findings: X
- Low findings: X
- Overall status: [PASS/FAIL]

## Permission Validation

### Workflow Permission Matrix
| Workflow | File | Permissions | Token Type | Status | Notes |
|----------|------|-------------|------------|--------|-------|
| PR Review | pr-review.yml | contents:read, pull-requests:read | GITHUB_TOKEN | PASS | Correct read-only |
| Auto-Fix | auto-fix.yml | contents:write, pull-requests:write | PAT | PASS | Requires write access |
...

### Findings
- [PASS] All workflows use explicit permissions
- [FAIL] Workflow X uses default permissions (HIGH)

## Credential Leak Scan

### Scan Results
- Files scanned: XX
- Credentials found: X
- False positives: X

### Findings
| Severity | Location | Finding | Recommendation |
|----------|----------|---------|----------------|
| CRITICAL | logs/run-123.txt | Exposed PAT token | Rotate token immediately, sanitize logs |
...

## Secrets Handling

### Findings
- [PASS] All secrets accessed via ${{ secrets.NAME }}
- [PASS] No secrets in error messages
- [FAIL] Debug mode exposes SECRET_X (MEDIUM)

## Branch Protection Compatibility

### Test Results
| Test | Status | Notes |
|------|--------|-------|
| Required reviews respected | PASS | Workflow cannot bypass |
| Status checks enforced | PASS | PAT commits trigger checks |
| No force push | PASS | No --force flags found |

## Network Security

### Findings
- [PASS] All API calls use HTTPS
- [PASS] Certificate validation enabled
- [PASS] No hardcoded IPs

## Recommendations
1. [CRITICAL] Rotate exposed PAT token in workflow X
2. [HIGH] Add explicit permissions to workflow Y
3. [MEDIUM] Disable debug mode in production

## Compliance Status
- OWASP Top 10: [COMPLIANT/NON-COMPLIANT]
- GitHub Security Best Practices: [COMPLIANT/NON-COMPLIANT]
```

**Deliverables:**
- `test-results/security-audit.md` - Main audit report
- `test-results/permission-validation.csv` - Permission matrix
- `test-results/secret-scan-results.json` - Scan results data

**Constraints:**
- Use dedicated test PAT with `repo` scope only (no `admin` or `delete_repo`)
- Do not expose real production credentials during testing
- Rotate test PAT after audit completion
- Report all findings immediately (do not wait for full audit completion)

---

### Agent 4: error-detective

**Role:** Test error scenarios and validate error handling

**Context:**
You are validating that the system handles error conditions gracefully: network failures, API errors, Git conflicts, permission denials, and transient failures. All error paths must provide actionable error messages and not leave repositories in inconsistent state.

**Inputs:**
- Workflows from Wave 3: `.github/workflows/*.yml`
- Agent scripts: `scripts/agents/*.sh`
- Test repositories with various error conditions

**Tasks:**

1. **Network Failure Scenarios**

   Simulate network issues:
   - **Test 4.1.1:** API timeout (mock slow GitHub API response)
     - Trigger workflow, introduce 30s delay in API call
     - Expected: Workflow retries, then fails gracefully with timeout message
   - **Test 4.1.2:** Connection reset (simulate network interruption)
     - Trigger workflow, kill network connection mid-request
     - Expected: Workflow detects connection error, retries with exponential backoff
   - **Test 4.1.3:** DNS failure (invalid GitHub API endpoint)
     - Modify workflow to use invalid endpoint
     - Expected: Workflow fails with clear DNS resolution error

2. **GitHub API Error Scenarios**

   Test API error responses:
   - **Test 4.2.1:** Rate limit exceeded (403 rate limit)
     - Trigger multiple workflows to exceed rate limit
     - Expected: Workflow detects rate limit, waits for reset time
   - **Test 4.2.2:** API 500 error (server error)
     - Mock GitHub API to return 500 error
     - Expected: Workflow retries up to 3 times, then fails with actionable message
   - **Test 4.2.3:** 403 Forbidden (insufficient permissions)
     - Use read-only token for write operation
     - Expected: Workflow fails immediately with permission error (no retry)
   - **Test 4.2.4:** 404 Not Found (resource doesn't exist)
     - Reference non-existent PR or issue
     - Expected: Workflow fails with clear "resource not found" message
   - **Test 4.2.5:** Invalid API response (malformed JSON)
     - Mock API to return invalid JSON
     - Expected: Workflow handles JSON parse error gracefully

3. **Git Operation Error Scenarios**

   Test Git-related failures:
   - **Test 4.3.1:** Merge conflict
     - Create PR with conflicting changes
     - Expected: Auto-fix workflow detects conflict, posts comment explaining conflict
   - **Test 4.3.2:** Branch protection violation
     - Attempt direct commit to protected branch
     - Expected: Workflow detects protection, creates PR instead
   - **Test 4.3.3:** Detached HEAD state
     - Checkout specific commit (not branch)
     - Expected: Workflow detects detached HEAD, fails with clear message
   - **Test 4.3.4:** Stale branch (behind main)
     - Create PR from outdated branch
     - Expected: Workflow suggests rebasing or merging main

4. **Permission Denial Scenarios**

   Test permission errors:
   - **Test 4.4.1:** Read-only token for write operation
     - Use GITHUB_TOKEN to commit changes
     - Expected: Workflow fails with "insufficient permissions" message
   - **Test 4.4.2:** Missing PAT for elevated operation
     - Attempt PR approval without PAT
     - Expected: Workflow fails with "requires PAT" message
   - **Test 4.4.3:** Expired token
     - Use expired PAT
     - Expected: Workflow detects 401 error, requests token rotation

5. **Transient Failure Recovery**

   Test retry logic:
   - **Test 4.5.1:** Temporary API unavailability
     - Simulate 2 failed API calls followed by success
     - Expected: Workflow retries and succeeds on 3rd attempt
   - **Test 4.5.2:** Temporary network blip
     - Simulate 1s network outage during workflow
     - Expected: Workflow retries after backoff and succeeds

**Error Handling Validation Criteria:**
For each error scenario, verify:
- Error detected correctly (no silent failures)
- Error message is actionable (explains what went wrong and how to fix)
- Workflow does not leave repository in inconsistent state (no orphaned branches, partial commits)
- Retry logic works correctly (exponential backoff, max retries)
- No credential exposure in error messages
- Workflow run marked as "failed" (not "success" with hidden errors)

**Output Contract:**
```markdown
# Error Scenario Test Results

## Summary
- Total error scenarios tested: XX
- Handled correctly: XX (XX%)
- Failed to handle: XX (XX%)
- Critical issues: X

## Test Results

### 4.1: Network Failure Scenarios
| Test ID | Scenario | Expected Behavior | Actual Behavior | Status | Notes |
|---------|----------|-------------------|-----------------|--------|-------|
| 4.1.1 | API timeout | Retry then fail gracefully | Workflow timed out after 30s, retried, failed with clear message | PASS | |
| 4.1.2 | Connection reset | Retry with backoff | Workflow retried 3 times, succeeded on 2nd attempt | PASS | |
| 4.1.3 | DNS failure | Fail with DNS error | Workflow failed with "DNS resolution failed" | PASS | |

### 4.2: GitHub API Error Scenarios
| Test ID | Scenario | Expected Behavior | Actual Behavior | Status | Notes |
|---------|----------|-------------------|-----------------|--------|-------|
| 4.2.1 | Rate limit | Wait for reset | Workflow detected rate limit, waited 15 minutes | PASS | |
| 4.2.2 | 500 error | Retry 3 times | Workflow retried, failed with "API error" | PASS | |
...

### 4.3: Git Operation Error Scenarios
...

### 4.4: Permission Denial Scenarios
...

### 4.5: Transient Failure Recovery
...

## Failure Analysis
[Root cause for any failed tests]

## Error Message Quality Assessment
| Test | Error Message | Actionability | Score (1-5) |
|------|---------------|---------------|-------------|
| 4.1.1 | "API request timed out after 30s. Check GitHub API status." | High | 5 |
...

## Critical Issues
[Any error scenarios that exposed credentials, left repos in bad state, etc.]

## Recommendations
1. Improve error message for Test X
2. Add retry logic for Test Y
3. Implement circuit breaker for API failures
```

**Deliverables:**
- `test-results/error-scenarios.md` - Test results report
- `test-results/error-recovery-tests.json` - Raw test data

**Constraints:**
- Use test repositories only (not production repos)
- Clean up any inconsistent state created during testing
- Do not trigger actual GitHub alerts (use test webhooks)
- Limit test execution time to 15 minutes

---

### Agent 5: debugger

**Role:** Execute integration tests across multiple repositories

**Context:**
You are validating that workflows execute consistently across diverse repositories: different languages, sizes, structures, and configurations. Integration tests ensure workflows are not brittle to repository-specific variations.

**Inputs:**
- Test repository matrix: Python, JavaScript, Go, Java, Ruby repos
- Repository sizes: Small (<100 files), Medium (500 files), Large (2000 files)
- Repository types: Single-language, multi-language (monorepo), library, application

**Tasks:**

1. **Multi-Repository Integration Test Matrix**

   Create test matrix:
   ```
   Repositories:
   - test-python-app (Python, 150 files, Django app)
   - test-javascript-app (JavaScript, 300 files, React app)
   - test-go-app (Go, 80 files, CLI tool)
   - test-java-app (Java, 500 files, Spring Boot app)
   - test-monorepo (Python + JavaScript + Go, 1200 files, monorepo)

   Workflows to test:
   - PR review workflow
   - Issue comment workflow
   - Auto-fix workflow

   Test dimensions:
   - Language detection correctness
   - Dependency installation
   - Linting tool selection
   - Code analysis accuracy
   ```

2. **Cross-Repository Test Execution**

   For each repository × workflow combination:
   - **Test 5.1:** Trigger workflow
   - **Test 5.2:** Verify workflow detects language correctly
   - **Test 5.3:** Verify workflow installs correct dependencies
   - **Test 5.4:** Verify workflow runs appropriate linting/analysis tools
   - **Test 5.5:** Verify workflow produces relevant feedback
   - **Test 5.6:** Measure execution time (check for timeouts)

3. **Large Repository Handling**

   Test with large repository (2000+ files):
   - **Test 5.7:** Checkout completes within timeout (10 minutes)
   - **Test 5.8:** Analysis scans all files (no truncation)
   - **Test 5.9:** Workflow does not exceed GitHub Actions resource limits
   - **Test 5.10:** Feedback quality does not degrade with repo size

4. **Monorepo Integration**

   Test multi-language monorepo:
   - **Test 5.11:** Workflow detects multiple languages
   - **Test 5.12:** Workflow analyzes each language with correct tools
   - **Test 5.13:** Workflow handles dependencies for all languages
   - **Test 5.14:** Workflow does not mix feedback across languages

5. **Concurrent Workflow Execution**

   Test concurrent workflows:
   - **Test 5.15:** Trigger 5 workflows simultaneously (different repos)
   - **Test 5.16:** Verify workflows do not interfere (no shared state)
   - **Test 5.17:** Verify all workflows complete successfully
   - **Test 5.18:** Measure queue time (should be <30s)

6. **Edge Cases**

   Test unusual repository configurations:
   - **Test 5.19:** Empty repository (no code files)
   - **Test 5.20:** Binary-heavy repository (images, videos, PDFs)
   - **Test 5.21:** Very deep directory structure (>10 levels)
   - **Test 5.22:** Long file paths (>255 characters)
   - **Test 5.23:** Special characters in file names (spaces, unicode)

**Integration Test Matrix:**
| Repo | Language | Files | Workflow | Status | Time | Notes |
|------|----------|-------|----------|--------|------|-------|
| test-python-app | Python | 150 | PR review | PASS | 45s | Detected Python, ran pylint |
| test-javascript-app | JavaScript | 300 | PR review | PASS | 52s | Detected JS, ran eslint |
| test-go-app | Go | 80 | PR review | PASS | 38s | Detected Go, ran golint |
| test-java-app | Java | 500 | PR review | PASS | 78s | Detected Java, ran checkstyle |
| test-monorepo | Multi | 1200 | PR review | PASS | 120s | Detected all 3 languages |
...

**Output Contract:**
```markdown
# Integration Test Results

## Summary
- Repositories tested: X
- Workflows tested: X
- Total test cases: XX
- Pass rate: XX%
- Average execution time: Xs

## Test Matrix Results

### Cross-Repository Tests
[Table showing repo × workflow results]

### Large Repository Tests
| Test | Repository | File Count | Status | Time | Notes |
|------|------------|------------|--------|------|-------|
| 5.7 | test-large-repo | 2000 | PASS | 180s | Checkout successful |
...

### Monorepo Tests
| Test | Languages | Status | Notes |
|------|-----------|--------|-------|
| 5.11 | Python, JS, Go | PASS | All languages detected |
...

### Concurrent Workflow Tests
| Test | Workflows | Status | Queue Time | Notes |
|------|-----------|--------|------------|-------|
| 5.15 | 5 simultaneous | PASS | 15s avg | No interference |
...

### Edge Case Tests
| Test | Scenario | Status | Notes |
|------|----------|--------|-------|
| 5.19 | Empty repo | PASS | Workflow skipped gracefully |
| 5.20 | Binary-heavy | PASS | Analyzed code files only |
...

## Consistency Analysis
- Language detection accuracy: XX%
- Dependency installation success rate: XX%
- Workflow completion rate: XX%

## Performance by Repository Size
| Size | Avg Time | p95 Time | Timeout Rate |
|------|----------|----------|--------------|
| Small (<100) | Xs | Xs | 0% |
| Medium (500) | Xs | Xs | 0% |
| Large (2000+) | Xs | Xs | 0% |

## Issues Found
[Any repository-specific failures or inconsistencies]

## Recommendations
1. Optimize workflow for large repositories
2. Improve language detection for edge cases
3. Add caching for dependencies
```

**Deliverables:**
- `test-results/integration-tests.md` - Integration test report
- `test-results/integration-matrix.csv` - Test matrix data

**Constraints:**
- Test execution time < 25 minutes
- Use consistent workflow versions across all repos
- Clean up test repositories after completion
- Monitor resource usage (CPU, memory, disk)

---

### Agent 6: incident-responder

**Role:** Simulate failure scenarios and validate recovery

**Context:**
You are testing the system's resilience to infrastructure failures: runner crashes, disk exhaustion, network partitions, Docker failures. The goal is to ensure the system recovers gracefully and workflows can resume after failures.

**Inputs:**
- Self-hosted runner infrastructure (Docker containers)
- Monitoring and alerting configurations
- Incident response runbooks

**Tasks:**

1. **Runner Crash Scenarios**

   Simulate runner container failures:
   - **Test 6.1.1:** Kill runner process (`kill -9`)
     - Trigger workflow
     - While workflow running, kill runner process
     - Expected: Workflow marked as failed, runner restarts automatically, next workflow succeeds
   - **Test 6.1.2:** Docker container stop (`docker stop`)
     - Trigger workflow
     - Stop Docker container mid-workflow
     - Expected: Workflow marked as failed, container restarts, next workflow succeeds
   - **Test 6.1.3:** Docker container crash (OOM)
     - Trigger memory-intensive workflow
     - Expected: Container OOM-killed, restarts, monitoring alert fired

2. **Disk Space Exhaustion**

   Simulate disk full scenarios:
   - **Test 6.2.1:** Fill disk to 95%
     - Fill disk with dummy files
     - Trigger workflow
     - Expected: Workflow detects low disk space, fails with clear message
   - **Test 6.2.2:** Fill disk during workflow execution
     - Trigger workflow
     - Fill disk mid-execution
     - Expected: Workflow fails gracefully, no data loss, disk cleanup triggered
   - **Test 6.2.3:** Disk cleanup recovery
     - After disk full, trigger cleanup
     - Expected: Disk space reclaimed, next workflow succeeds

3. **Network Partition Scenarios**

   Simulate network failures:
   - **Test 6.3.1:** Block GitHub API access
     - Use `iptables` to block GitHub API endpoints
     - Trigger workflow
     - Expected: Workflow fails with network error, unblocks, retries successfully
   - **Test 6.3.2:** DNS resolution failure
     - Block DNS lookups for github.com
     - Trigger workflow
     - Expected: Workflow fails with DNS error, recovers when DNS restored
   - **Test 6.3.3:** Network latency (high ping)
     - Introduce 2s latency to all network calls
     - Trigger workflow
     - Expected: Workflow completes but slower, no timeout

4. **Docker Environment Failures**

   Test Docker-related issues:
   - **Test 6.4.1:** Docker daemon restart
     - Restart Docker daemon while workflow running
     - Expected: Workflow fails, container restarts, next workflow succeeds
   - **Test 6.4.2:** Image pull failure
     - Delete runner image, trigger workflow
     - Expected: Docker pulls image, runner starts, workflow succeeds
   - **Test 6.4.3:** Volume mount failure
     - Unmount required volume
     - Expected: Workflow fails with clear mount error

5. **State Preservation Tests**

   Verify workflow state handling:
   - **Test 6.5.1:** Runner restart mid-workflow
     - Trigger long-running workflow
     - Restart runner halfway through
     - Expected: Workflow fails, GitHub marks as "cancelled", no orphaned processes
   - **Test 6.5.2:** Workflow artifact preservation
     - Trigger workflow that uploads artifacts
     - Kill runner before artifact upload completes
     - Expected: Artifacts lost, workflow marked as failed (not partial success)

6. **Monitoring and Alerting Validation**

   Verify alerts fire correctly:
   - **Test 6.6.1:** Runner down alert
     - Stop runner
     - Expected: Alert fires within 2 minutes
   - **Test 6.6.2:** Disk space alert
     - Fill disk to 90%
     - Expected: Warning alert fires
   - **Test 6.6.3:** Workflow failure alert
     - Trigger failing workflow
     - Expected: Failure alert includes workflow name and error

**Failure Scenario Test Matrix:**
| Test ID | Scenario | Failure Injection | Expected Recovery | Actual Result | Status |
|---------|----------|-------------------|-------------------|---------------|--------|
| 6.1.1 | Runner crash | kill -9 | Auto-restart in 30s | Restarted in 25s | PASS |
| 6.1.2 | Container stop | docker stop | Auto-restart in 30s | Restarted in 28s | PASS |
| 6.2.1 | Disk full | Fill to 95% | Workflow fails gracefully | Failed with clear error | PASS |
| 6.3.1 | Network partition | Block GitHub API | Retry after unblock | Retried successfully | PASS |
...

**Output Contract:**
```markdown
# Failure Scenario Test Results

## Summary
- Total failure scenarios: XX
- Recovery successful: XX (XX%)
- Recovery failed: XX (XX%)
- Average recovery time: Xs

## Test Results

### 6.1: Runner Crash Scenarios
| Test ID | Failure Type | Recovery Time | Status | Notes |
|---------|--------------|---------------|--------|-------|
| 6.1.1 | kill -9 | 25s | PASS | Auto-restart successful |
| 6.1.2 | docker stop | 28s | PASS | Container restarted |
| 6.1.3 | OOM crash | 45s | PASS | Alert fired correctly |

### 6.2: Disk Space Exhaustion
...

### 6.3: Network Partition Scenarios
...

### 6.4: Docker Environment Failures
...

### 6.5: State Preservation Tests
...

### 6.6: Monitoring and Alerting Validation
...

## Recovery Time Analysis
| Failure Type | Min | Max | Avg | p95 | Target | Status |
|--------------|-----|-----|-----|-----|--------|--------|
| Runner crash | 20s | 50s | 30s | 45s | <120s | PASS |
| Disk full | 10s | 30s | 15s | 25s | <60s | PASS |
| Network partition | 5s | 120s | 40s | 100s | <120s | PASS |

## Monitoring Alert Validation
| Alert | Trigger Condition | Expected Time | Actual Time | Status |
|-------|-------------------|---------------|-------------|--------|
| Runner down | Runner stopped | <2min | 1m 30s | PASS |
| Disk space low | 90% full | <5min | 3m 15s | PASS |
| Workflow failure | Job failed | <1min | 45s | PASS |

## Data Loss Assessment
- Workflow state lost: X cases
- Artifacts lost: X cases
- Repository corruption: X cases (should be 0)

## Critical Issues
[Any failures that caused data loss, corruption, or required manual intervention]

## Incident Response Runbook Validation
- [x] Runbook step 1 tested and validated
- [x] Runbook step 2 tested and validated
- [ ] Runbook step X needs update (finding Y)

## Recommendations
1. Reduce recovery time for X scenario (current: Xs, target: Xs)
2. Improve monitoring alert for Y
3. Add automated recovery for Z failure type
```

**Deliverables:**
- `test-results/failure-scenarios.md` - Failure test report
- `test-results/chaos-tests.json` - Raw failure test data
- `runbooks/incident-response-validation.md` - Validated and updated runbooks

**Constraints:**
- Run failure tests on isolated test runners (not production)
- Implement failsafes to prevent cascading failures
- Monitor test infrastructure during chaos testing
- Maximum test duration: 20 minutes
- Clean up all test artifacts (restore disk space, network rules, containers)

---

## ACCEPTANCE CRITERIA

### System Production Readiness Checklist

The system is ready for production when ALL of the following criteria are met:

#### Functional Correctness (test-automator)
- [ ] All PR review workflows execute successfully (100% pass rate)
- [ ] All issue comment workflows execute successfully (100% pass rate)
- [ ] All auto-fix workflows execute successfully (100% pass rate)
- [ ] All GitHub event types tested (pull_request, issue_comment, push, workflow_dispatch)
- [ ] No workflows leave repositories in inconsistent state

#### Performance Targets (performance-engineer)
- [ ] Job start latency p95 < 60 seconds
- [ ] Checkout time 70% faster than GitHub-hosted runners (p95)
- [ ] Total workflow duration 50% faster than GitHub-hosted runners (p95)
- [ ] Large repositories (2000+ files) complete within 10 minutes
- [ ] Concurrent workflows execute without resource contention

#### Security Compliance (security-auditor)
- [ ] Zero credential leaks detected in logs, artifacts, or outputs
- [ ] All workflows use explicit least-privilege permissions
- [ ] GITHUB_TOKEN used for read operations (not PAT)
- [ ] PAT used only for write operations requiring elevated permissions
- [ ] Branch protection rules respected by all workflows
- [ ] No secrets exposed in error messages

#### Error Handling (error-detective)
- [ ] All network failure scenarios handled gracefully
- [ ] All API error responses handled correctly (rate limit, 500, 403, 404)
- [ ] All Git error scenarios handled (merge conflicts, branch protection)
- [ ] All permission denial scenarios provide actionable error messages
- [ ] Retry logic works for transient failures (exponential backoff, max retries)

#### Integration Reliability (debugger)
- [ ] Workflows execute consistently across 5+ repositories
- [ ] Multi-language repositories (monorepos) handled correctly
- [ ] Large repositories (2000+ files) do not timeout
- [ ] Concurrent workflows do not interfere with each other
- [ ] Edge cases handled (empty repos, binary files, deep directories)

#### Failure Recovery (incident-responder)
- [ ] System recovers from runner crashes within 2 minutes
- [ ] Disk space exhaustion handled without data loss
- [ ] Network partitions do not cause workflow corruption
- [ ] Monitoring alerts fire within expected timeframes
- [ ] Incident response runbooks validated and updated

---

## PERFORMANCE BASELINES

### GitHub-Hosted Runner Baselines (for comparison)

These are typical performance metrics for GitHub-hosted runners (`runs-on: ubuntu-latest`):

| Metric | Baseline Value | Source |
|--------|---------------|--------|
| Job start latency (queue to start) | 90-180s (p50), 180-300s (p95) | GitHub docs, observed data |
| Checkout time (small repo <100 files) | 10-15s | GitHub Actions logs |
| Checkout time (medium repo ~500 files) | 20-30s | GitHub Actions logs |
| Checkout time (large repo >2000 files) | 60-120s | GitHub Actions logs |
| Total workflow duration (simple linting) | 120-180s | Typical workflow |
| Runner provisioning time | 30-60s | Time to allocate fresh VM |

### Self-Hosted Runner Targets

Based on baselines above, self-hosted runner targets are:

| Metric | Target Value | Improvement |
|--------|--------------|-------------|
| Job start latency (p95) | <60s | 3-5x faster |
| Checkout time (small repo) | <5s | 2-3x faster |
| Checkout time (medium repo) | <10s | 2-3x faster |
| Checkout time (large repo) | <30s | 2-4x faster |
| Total workflow duration | <90s | 50% faster |
| Runner availability | <5s | Already running |

### Performance Measurement Methodology

1. **Baseline Collection:**
   - Run test workflow 20 times on GitHub-hosted runner
   - Measure: job start time, checkout time, total duration
   - Calculate: p50, p95, p99, average, standard deviation

2. **Self-Hosted Measurement:**
   - Run identical workflow 20 times on self-hosted runner
   - Use same repository, same workflow definition
   - Measure identical metrics

3. **Comparison:**
   - Calculate percentage improvement: `(baseline - self_hosted) / baseline * 100`
   - Verify statistical significance (t-test, p < 0.05)
   - Document outliers and anomalies

4. **Variables to Control:**
   - Network latency (measure separately)
   - Time of day (run tests at consistent times)
   - Repository size (use identical repos)
   - Workflow complexity (identical workflow definitions)

---

## REFERENCES

### Wave 3 Implementation Outputs
- Workflow files: `.github/workflows/pr-review.yml`, `issue-comment.yml`, `auto-fix.yml`
- Agent scripts: `scripts/agents/pr-reviewer.sh`, `issue-analyzer.sh`, `auto-fixer.sh`
- Infrastructure: `docker-compose.yml`, `Dockerfile.runner`
- Documentation: `docs/workflows.md`, `docs/permissions.md`

### Wave 1 Planning Documents
- Performance targets: Job start <60s, checkout 70% faster, total 50% faster
- Security requirements: Least-privilege, no credential leaks, PAT only for writes
- Error handling requirements: Graceful failures, actionable errors, retry logic

### Testing Best Practices
- GitHub Actions Testing Guide: https://docs.github.com/en/actions/testing
- Chaos Engineering Principles: https://principlesofchaos.org/
- Performance Testing Methodology: Statistical sampling, p50/p95/p99 metrics
- Security Testing: OWASP Testing Guide, Secret scanning tools

### Tools and Technologies
- GitHub API: https://docs.github.com/en/rest
- GitHub CLI (`gh`): https://cli.github.com/
- Docker: https://docs.docker.com/
- `jq`: JSON processing for test data
- `iptables`: Network partition simulation
- Performance monitoring: Prometheus, Grafana (optional)

### Performance Metrics References
- GitHub-hosted runner specs: 2-core CPU, 7 GB RAM, 14 GB SSD
- Self-hosted runner specs: (document your actual runner specs)
- Network latency: Measure ping time to `api.github.com`

---

## NOTES

### Test Execution Order

**Parallel Block 1 (run simultaneously):**
1. test-automator → Functional tests
2. performance-engineer → Performance benchmarks
3. security-auditor → Security audit

**Parallel Block 2 (run simultaneously after Block 1):**
4. error-detective → Error scenario tests (uses fixtures from test-automator)
5. debugger → Integration tests (uses fixtures from test-automator)
6. incident-responder → Failure simulations (can run in parallel)

**Estimated Timeline:**
- Block 1: 20-25 minutes
- Block 2: 15-20 minutes
- Total: 35-45 minutes

### Test Data Cleanup Strategy

After all tests complete:
1. Close all test PRs (use `gh pr close --delete-branch`)
2. Close all test issues (use `gh issue close`)
3. Delete test branches (use `git push --delete origin <branch>`)
4. Remove test repositories (if created for testing)
5. Rotate test PAT tokens
6. Clean up Docker containers and volumes
7. Archive test results to `test-results/archive/<date>/`

### Continuous Testing Strategy (Post-Wave 4)

After initial validation, implement continuous testing:
- Run smoke tests daily (subset of functional tests)
- Run performance benchmarks weekly (track trends over time)
- Run security scans on every workflow change
- Run integration tests on every runner upgrade
- Run failure simulations monthly (chaos engineering)

### Test Result Retention

- Keep detailed test results for 90 days
- Archive summary reports indefinitely
- Performance trend data: Keep all data points for analysis
- Security scan results: Keep all findings until remediated

---

## ASSUMPTIONS / HYPOTHESES / PRINCIPLES

### Assumptions
1. Wave 3 deliverables are complete and functional
2. Self-hosted runners are deployed and accessible
3. Test repositories can be created and destroyed freely
4. GitHub API rate limits allow for test execution (2000+ requests)
5. Test PATs have appropriate scopes (repo, workflow)
6. Network between runners and GitHub is stable during testing
7. Docker environment is available for failure simulation tests

### Hypotheses to Validate
1. **H1:** Self-hosted runners will start jobs 3-5x faster than GitHub-hosted runners (hypothesis validated via performance-engineer tests)
2. **H2:** Local Git cache will make checkout 70%+ faster (hypothesis validated via performance benchmarks)
3. **H3:** Error scenarios will be rare in production (<1% of workflows) but must be handled gracefully (hypothesis validated via error-detective tests)
4. **H4:** Concurrent workflows will not interfere if runners are properly isolated (hypothesis validated via debugger integration tests)

### Testing Principles
1. **Test in Production-Like Environment:** Use real GitHub repos, real workflows, real API calls
2. **Deterministic Tests Only:** No flaky tests allowed (if test is flaky, fix it or remove it)
3. **Actionable Failures:** Every test failure must point to specific remediation
4. **Evidence-Based:** Every test result must include evidence (logs, URLs, screenshots)
5. **Clean Up After Yourself:** Every test must clean up resources (branches, PRs, containers)
6. **Security First:** No credential exposure, even in test environments
7. **Performance Matters:** Tests should complete quickly (full suite <30 minutes)

---

## STAKEHOLDERS & RESPONSIBILITIES (RACI)

### Test Execution Phase

| Role | Responsible | Accountable | Consulted | Informed |
|------|-------------|-------------|-----------|----------|
| Test Automation | test-automator | Wave 4 Lead | - | All agents |
| Performance Benchmarking | performance-engineer | Wave 4 Lead | - | All agents |
| Security Audit | security-auditor | Wave 4 Lead | - | All agents |
| Error Testing | error-detective | Wave 4 Lead | test-automator | All agents |
| Integration Testing | debugger | Wave 4 Lead | test-automator | All agents |
| Failure Simulation | incident-responder | Wave 4 Lead | - | All agents |
| Production Readiness Decision | - | Project Lead | All agents | Stakeholders |

### Decision Authority (DACI)

**Decision:** Is the system ready for production deployment?

- **Driver:** Wave 4 Lead (synthesizes all test results)
- **Approver:** Project Lead (final go/no-go decision)
- **Contributors:** All 6 testing specialist agents (provide test results and recommendations)
- **Informed:** Stakeholders, Wave 5 deployment team

**Decision Criteria:**
- All acceptance criteria met (see Acceptance Criteria section)
- No critical or high-severity issues unresolved
- Performance targets achieved
- Security compliance verified

---

## CONSTRAINTS / SLOs & SLIs

### Service Level Objectives (SLOs)

#### Test Execution SLOs
- **SLO-1:** Test suite completes within 45 minutes (95% of the time)
- **SLO-2:** Zero false positive test failures (flaky tests)
- **SLO-3:** Test results delivered in standardized format (100%)
- **SLO-4:** Test data cleanup completes within 10 minutes (100%)

#### System Performance SLOs (validated by tests)
- **SLO-5:** Job start latency p95 < 60 seconds
- **SLO-6:** Checkout time 70% faster than GitHub-hosted (p95)
- **SLO-7:** Total workflow duration 50% faster than GitHub-hosted (p95)
- **SLO-8:** Runner availability > 95% (measured over 7 days)

#### System Reliability SLOs (validated by tests)
- **SLO-9:** Workflow success rate > 95% (excluding intentional failures)
- **SLO-10:** Recovery time from runner failure < 2 minutes (p95)
- **SLO-11:** Zero data loss events (orphaned branches, partial commits)

### Service Level Indicators (SLIs)

#### Test Execution SLIs
- **SLI-1:** Test suite execution time (measured in minutes)
- **SLI-2:** Test pass rate (passed / total tests)
- **SLI-3:** Test coverage (scenarios covered / total scenarios)
- **SLI-4:** Test data cleanup time (measured in seconds)

#### System Performance SLIs (collected during tests)
- **SLI-5:** Job start latency (time from webhook to job start, p50/p95/p99)
- **SLI-6:** Checkout duration (time to clone and checkout repo, p50/p95/p99)
- **SLI-7:** Total workflow duration (end-to-end time, p50/p95/p99)
- **SLI-8:** Runner idle time percentage (idle time / total uptime)

#### System Reliability SLIs (collected during tests)
- **SLI-9:** Workflow success rate (successful workflows / total workflows)
- **SLI-10:** Error rate by category (network, API, Git, permissions)
- **SLI-11:** Recovery time (time from failure to recovery, p50/p95/p99)
- **SLI-12:** Alert latency (time from incident to alert, p50/p95)

---

## DEPENDENCIES & COUPLINGS

### External Dependencies
1. **GitHub API:** Rate limits (5000 requests/hour for authenticated), API availability, response times
2. **GitHub Actions:** Webhook delivery, workflow run logs, artifact storage
3. **Docker:** Container runtime, image registry, volume management
4. **Network:** Internet connectivity, DNS resolution, firewall rules
5. **Git:** Repository access, clone performance, authentication

### Internal Dependencies (Wave 3 Outputs)
1. Workflow files: `.github/workflows/*.yml`
2. Agent scripts: `scripts/agents/*.sh`
3. Runner infrastructure: Docker containers, network configuration
4. Secrets: GitHub PAT, runner registration tokens
5. Documentation: Workflow specs, permission configurations

### Coupling Points (Risk Areas)
1. **GitHub API Changes:** API endpoint or response format changes could break tests
2. **Workflow File Changes:** Changes to workflow definitions during Wave 4 invalidate test results
3. **Runner Configuration Changes:** Infrastructure changes mid-testing require test re-runs
4. **Network Instability:** Unstable network during tests causes flaky results
5. **Resource Contention:** Other processes competing for runner resources skew performance tests

### Dependency Mitigation
- Pin GitHub API version (use versioned endpoints where possible)
- Freeze workflow files during test execution (no changes until tests complete)
- Use dedicated test runners (isolated from other workloads)
- Measure and report network latency separately from workflow performance
- Run tests during low-traffic periods (minimize resource contention)

---

## SCALABILITY & CAPACITY

### Test Infrastructure Capacity

**Current Test Capacity:**
- Concurrent test agents: 6 (running in parallel)
- Test repositories: 5-10 (created for testing)
- Test workflows: 20-30 (across all test scenarios)
- Test duration: 35-45 minutes (full suite)

**Scalability Limits:**
- GitHub API rate limits: 5000 requests/hour (shared across all tests)
- Runner capacity: Limited by self-hosted runner resources (CPU, memory, disk)
- Test data storage: ~10 GB for test repositories and artifacts
- Network bandwidth: Limited by internet connection speed

### System Under Test Capacity

**Runner Capacity Limits (to be validated):**
- Concurrent workflows: 5-10 (limited by runner CPU/memory)
- Repository size: Tested up to 2000 files (~500 MB)
- Workflow duration: Tested up to 10 minutes (longer workflows timeout)
- Artifact size: Tested up to 100 MB

**Capacity Testing Plan:**
- Test with increasing concurrent workflows (1, 5, 10, 15, 20) until failure
- Test with increasing repository sizes (100, 500, 1000, 2000, 5000 files)
- Identify resource bottlenecks (CPU, memory, disk I/O, network)
- Document capacity limits and scaling recommendations

---

## TAXONOMY / LABELS

### Test Result Labels

**Status Labels:**
- `test:pass` - Test passed successfully
- `test:fail` - Test failed
- `test:skip` - Test skipped (blocked or not applicable)
- `test:flaky` - Test passed but exhibited flaky behavior (should be fixed)

**Severity Labels (for failures):**
- `severity:critical` - Blocks production deployment
- `severity:high` - Significant issue, should fix before production
- `severity:medium` - Minor issue, can fix post-deployment
- `severity:low` - Cosmetic issue, low priority

**Category Labels:**
- `category:functional` - Functional correctness test
- `category:performance` - Performance benchmark test
- `category:security` - Security audit test
- `category:error-handling` - Error scenario test
- `category:integration` - Integration test
- `category:failure-recovery` - Failure simulation test

### Test Artifact Organization

```
test-results/
├── functional-tests.md         (test-automator)
├── performance-benchmarks.md   (performance-engineer)
├── performance-metrics.csv     (raw data)
├── performance-comparison.json (comparison data)
├── security-audit.md           (security-auditor)
├── permission-validation.csv   (permission matrix)
├── secret-scan-results.json    (scan results)
├── error-scenarios.md          (error-detective)
├── error-recovery-tests.json   (error test data)
├── integration-tests.md        (debugger)
├── integration-matrix.csv      (test matrix)
├── failure-scenarios.md        (incident-responder)
├── chaos-tests.json            (chaos test data)
└── archive/
    └── 2025-10-17/             (archived test results)
```

---

## DECISION LOG (ADRs)

### ADR-W4-001: Use Real Repositories for Testing (Not Mocks)

**Context:** Testing can be done with mocked GitHub API responses or real repositories.

**Options:**
1. Mock GitHub API responses (faster, isolated)
2. Use real GitHub repositories (slower, realistic)

**Decision:** Use real GitHub repositories for integration tests.

**Rationale:**
- Real repositories test actual GitHub API behavior (including edge cases)
- Mocks may not reflect real-world API responses and rate limiting
- Integration tests are more valuable with real infrastructure
- Functional correctness is critical (worth the extra test time)

**Consequences:**
- Tests take longer to execute (35-45 minutes vs 5-10 minutes with mocks)
- Tests consume GitHub API rate limits (must monitor and throttle)
- Tests require cleanup automation (PRs, branches, issues)
- Tests are more realistic and catch real integration issues

---

### ADR-W4-002: Parallel Test Execution Across 6 Agents

**Context:** Tests can be executed sequentially (one agent at a time) or in parallel (multiple agents simultaneously).

**Options:**
1. Sequential execution (simpler, slower)
2. Parallel execution in 2 blocks (faster, more complex)

**Decision:** Parallel execution in 2 blocks (Block 1: functional/performance/security, Block 2: error/integration/failure).

**Rationale:**
- Parallel execution reduces total test time from ~90 minutes to ~45 minutes
- Block 1 tests are independent (can run in parallel)
- Block 2 tests depend on Block 1 fixtures (must run sequentially after Block 1)
- 6 agents running in parallel is manageable complexity

**Consequences:**
- Faster test execution (50% time savings)
- Requires coordination between agents (shared test fixtures)
- Requires sufficient runner capacity (6 agents running concurrently)
- Risk of resource contention if runners under-provisioned

---

### ADR-W4-003: Performance Metrics Use p50/p95/p99 (Not Just Average)

**Context:** Performance can be reported as average, median, or percentiles (p50/p95/p99).

**Options:**
1. Report average and standard deviation
2. Report median (p50) only
3. Report p50/p95/p99 percentiles

**Decision:** Report p50/p95/p99 percentiles for all performance metrics.

**Rationale:**
- Percentiles better represent tail latencies (p95/p99 show worst-case behavior)
- Average hides outliers (one slow run skews average)
- Industry standard for performance reporting (SLAs use p95/p99)
- Targets are specified as p95 (job start <60s p95)

**Consequences:**
- Requires more sophisticated statistical analysis (sorting, percentile calculation)
- Provides better insights into performance variability
- Aligns with industry best practices and SLA definitions

---

## GOVERNANCE & CHANGE ENABLEMENT

### Change Control During Testing

**Freeze Period:** During Wave 4 test execution, the following are FROZEN (no changes allowed):
- Workflow files (`.github/workflows/*.yml`)
- Agent scripts (`scripts/agents/*.sh`)
- Runner infrastructure (Docker containers, network configuration)
- Secrets and environment variables

**Reason:** Changes during testing invalidate test results and require re-testing.

**Exception Process:**
1. Critical bug fix required during testing
2. Test lead approves change
3. All affected tests re-run after change
4. Document change in test results report

### Production Deployment Approval

**Gate:** Wave 4 test results must be reviewed and approved before Wave 5 (production deployment).

**Approval Process:**
1. All 6 testing agents submit test results
2. Wave 4 lead synthesizes results and creates production readiness report
3. Project lead reviews report against acceptance criteria
4. If all criteria met: Approve production deployment (proceed to Wave 5)
5. If criteria not met: Document gaps, create remediation plan, re-test after fixes

**Rollback Plan:**
- If Wave 5 deployment fails, rollback to GitHub-hosted runners
- Self-hosted runners remain deployed but workflows disabled
- Investigate issues, fix, re-run Wave 4 tests, re-deploy

---

## RELIABILITY & OPERATIONS

### Monitoring During Testing

**Metrics to Monitor:**
- Runner CPU, memory, disk usage (ensure tests don't exhaust resources)
- Network latency to GitHub API (measure separately from workflow performance)
- Docker container health (ensure containers don't crash during tests)
- GitHub API rate limit remaining (avoid hitting rate limits)

**Monitoring Tools:**
- `docker stats` for container resource usage
- `ping api.github.com` for network latency
- GitHub API response headers (`X-RateLimit-Remaining`) for rate limits
- Custom scripts to aggregate test execution metrics

### Incident Response During Testing

**If test infrastructure fails during testing:**
1. Pause test execution
2. Investigate failure (check Docker logs, network connectivity, resource usage)
3. Fix issue (restart containers, free disk space, restore network)
4. Resume or restart affected tests
5. Document incident in test results report

**If test reveals critical production issue:**
1. Immediately notify project lead (CRITICAL severity)
2. Document issue in test results with evidence
3. Recommend blocking production deployment until fixed
4. Create remediation plan with estimated fix time

---

## SECURITY & COMPLIANCE

### Test Data Security

**Test Repositories:**
- Use public repositories for testing (no sensitive data)
- If private repos required, ensure no production data
- Delete test repositories after testing complete

**Test Credentials:**
- Use dedicated test PAT with minimal scopes (`repo` only)
- Rotate test PAT after testing complete
- Never commit test PAT to version control
- Store test PAT in GitHub Secrets or secure environment variable

**Test Logs:**
- Scan all test logs for credential leaks before archiving
- Redact any accidentally exposed credentials
- Do not publish test logs publicly (may contain test PAT references)

### Compliance Validation

**OWASP Compliance:**
- Security auditor validates against OWASP Top 10
- No injection vulnerabilities (command injection, SQL injection)
- No authentication/authorization bypass
- No sensitive data exposure

**GitHub Security Best Practices:**
- Workflows use explicit permissions (not defaults)
- Secrets accessed via `${{ secrets.NAME }}` only
- No `pull_request_target` workflows (dangerous for forks)
- Branch protection enforced

---

## ECONOMICS & RESOURCES

### Test Infrastructure Costs

**GitHub API Costs:**
- Free tier: 5000 requests/hour (authenticated)
- Wave 4 estimated usage: ~500-1000 requests (well within limits)
- No additional cost for API usage

**Compute Costs:**
- Self-hosted runner costs: (depends on infrastructure - EC2, local, etc.)
- Test duration: 35-45 minutes (minimal incremental cost)
- No GitHub Actions minutes consumed (self-hosted runners are free)

**Storage Costs:**
- Test data: ~10 GB (repositories, artifacts, logs)
- Retention: 90 days (then archive)
- Minimal storage cost

**Total Estimated Cost:** <$10 for Wave 4 test execution (mainly compute/storage)

### Resource Budget

**Time Budget:**
- Test infrastructure setup: 2 hours
- Test execution: 45 minutes (automated)
- Results analysis: 3 hours
- Total: ~6 hours of human time, 45 minutes of compute time

**GitHub API Budget:**
- Rate limit budget: 1000 requests (out of 5000/hour allowance)
- 80% buffer remaining for other operations

---

## TIMELINE & RELEASES

### Wave 4 Timeline

**Day 1:**
- Setup test infrastructure (test repositories, fixtures)
- Configure test environments (runners, credentials)
- Verify all dependencies available

**Day 2:**
- Execute Parallel Block 1 tests (functional, performance, security)
- Monitor test execution, address any blockers
- Collect initial test results

**Day 3:**
- Execute Parallel Block 2 tests (error scenarios, integration, failure simulation)
- Aggregate all test results
- Analyze results against acceptance criteria

**Day 4:**
- Synthesize production readiness report
- Present findings to project lead
- Decision: Proceed to Wave 5 or remediate issues

**Total Duration:** 3-4 days (depending on findings and remediation)

### Release Criteria

**Wave 4 Complete (Gate for Wave 5):**
- [ ] All 6 testing agents completed tests
- [ ] All test results documented and reviewed
- [ ] All acceptance criteria evaluated (pass/fail for each)
- [ ] Production readiness report approved by project lead
- [ ] If blockers found: Remediation plan created and executed
- [ ] Test data cleanup completed
- [ ] Test results archived for future reference

**Wave 5 Go/No-Go Decision:**
- **GO:** All critical acceptance criteria met, no critical/high severity issues unresolved
- **NO-GO:** Critical acceptance criteria failed, or critical/high severity issues require remediation
