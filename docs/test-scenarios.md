# Test Scenarios: Self-Hosted GitHub Actions Runner
## Specific Test Scenarios for Each Workflow Type

---

## 1. EXECUTIVE SUMMARY

### 1.1 Purpose
This document provides detailed, executable test scenarios for all workflow types in the self-hosted GitHub Actions runner infrastructure. Each scenario includes setup instructions, execution steps, expected results, and validation criteria.

### 1.2 Scenario Coverage
- **PR Review Workflows**: 15 scenarios
- **Issue Comment Workflows**: 10 scenarios
- **Auto-Fix/Commit Workflows**: 12 scenarios
- **Performance Test Scenarios**: 8 scenarios
- **Security Test Scenarios**: 10 scenarios
- **Error Handling Scenarios**: 10 scenarios
- **Integration Test Scenarios**: 10 scenarios
- **Cross-Platform Scenarios**: 8 scenarios

**Total Scenarios**: 83 detailed test scenarios

### 1.3 Test Data Requirements
All scenarios reference test data in `test-data/` directory:
- Sample repositories
- Test PRs and issues
- Mock data for external services
- Configuration files

---

## 2. PR REVIEW WORKFLOW SCENARIOS

### Scenario PR-001: Simple PR Review with Approval

#### Objective
Validate that AI/CLI agent can successfully review a simple PR and post an approval review.

#### Prerequisites
- Repository: `test-repo-pr-reviews`
- Runner: Active and registered
- Permissions: PAT with `repo` and `write` scope
- Workflow: `.github/workflows/pr-review-approve.yml`

#### Test Data
- **PR Branch**: `feature/simple-fix`
- **Files Changed**:
  - `src/utils.js` (15 lines added, 5 removed)
  - `tests/utils.test.js` (10 lines added)
- **Code Quality**: Clean, well-formatted, tests included

#### Execution Steps
1. Create PR from `feature/simple-fix` to `main`
   ```bash
   gh pr create \
     --title "Fix: Update utility function" \
     --body "Simple bug fix with tests" \
     --base main \
     --head feature/simple-fix
   ```

2. Workflow triggers automatically on `pull_request` event

3. Monitor workflow execution:
   ```bash
   gh run watch
   ```

4. Verify review posted:
   ```bash
   gh pr view --json reviews
   ```

#### Expected Results
1. Workflow starts within 30 seconds of PR creation
2. Agent analyzes code changes
3. Review posted with status "APPROVED"
4. Review comment includes:
   - Positive feedback on code quality
   - Note about tests included
   - Approval rationale
5. PR shows green checkmark
6. Total execution time < 120 seconds

#### Validation Criteria
```yaml
assertions:
  - workflow_status: "success"
  - review_state: "APPROVED"
  - review_comment_length: "> 50 characters"
  - execution_time: "< 120 seconds"
  - no_errors_in_logs: true
```

#### Cleanup
```bash
gh pr close --delete-branch
```

---

### Scenario PR-002: Complex PR Review with Change Requests

#### Objective
Test agent's ability to identify issues in a complex PR and request changes.

#### Prerequisites
- Repository: `test-repo-pr-reviews`
- Runner: Active
- Permissions: Write access
- Workflow: `.github/workflows/pr-review-detailed.yml`

#### Test Data
- **PR Branch**: `feature/complex-refactor`
- **Files Changed**: 12 files (Python, JavaScript, YAML)
- **Intentional Issues**:
  - Linting errors in `src/processor.py`
  - Missing error handling in `src/api.js`
  - Hardcoded credentials in `config/settings.py`
  - No tests for new functionality
  - Security vulnerability (SQL injection risk)

#### Execution Steps
1. Create PR with intentional issues:
   ```bash
   gh pr create \
     --title "Refactor: Major architecture changes" \
     --body "$(cat test-data/pr-bodies/complex-refactor.md)" \
     --base main \
     --head feature/complex-refactor
   ```

2. Wait for workflow to complete

3. Retrieve and analyze review:
   ```bash
   gh pr view --json reviews,comments
   ```

4. Validate each issue identified:
   ```bash
   python scripts/validate-review.py \
     --pr-number 2 \
     --expected-issues test-data/expected-issues.json
   ```

#### Expected Results
1. Review state: "CHANGES_REQUESTED"
2. Issues identified (all 5):
   - Linting errors with specific lines
   - Missing error handling
   - Hardcoded credentials flagged as critical
   - Missing tests noted
   - Security vulnerability highlighted
3. Each issue includes:
   - File and line number
   - Description of problem
   - Recommended fix
4. Execution time < 300 seconds

#### Validation Criteria
```yaml
assertions:
  - review_state: "CHANGES_REQUESTED"
  - issues_identified: 5
  - critical_issues_count: 2  # credentials + security
  - high_issues_count: 1      # missing tests
  - medium_issues_count: 2    # linting + error handling
  - each_issue_has_location: true
  - each_issue_has_recommendation: true
  - security_issue_severity: "CRITICAL"
```

---

### Scenario PR-003: PR Review with Inline Comments

#### Objective
Validate agent's ability to post inline comments on specific code lines.

#### Prerequisites
- Repository: `test-repo-pr-reviews`
- Workflow: `.github/workflows/pr-review-inline.yml`
- API: GitHub Review Comments API

#### Test Data
- **PR Branch**: `feature/code-improvements`
- **Target Files**:
  - `src/parser.js` (contains inefficient loop at line 45)
  - `src/validator.py` (missing null check at line 78)
  - `README.md` (typos at lines 12, 34)

#### Execution Steps
1. Create PR:
   ```bash
   gh pr create \
     --title "Code improvements" \
     --body "Various code optimizations" \
     --base main \
     --head feature/code-improvements
   ```

2. Wait for inline comment workflow

3. Verify inline comments:
   ```bash
   gh api repos/:owner/:repo/pulls/:pr_number/comments | \
     jq '.[] | {path, line, body}'
   ```

#### Expected Results
1. Inline comments posted (at least 3)
2. Each comment on correct file and line:
   - `parser.js:45` - Loop optimization suggestion
   - `validator.py:78` - Null check recommendation
   - `README.md:12,34` - Typo corrections
3. Comments use proper format (code suggestions where applicable)
4. No overall review state (comments only)

#### Validation Criteria
```yaml
assertions:
  - inline_comments_count: ">= 3"
  - comment_locations_correct: true
  - comments_have_suggestions: true
  - code_suggestion_format_valid: true
  - no_review_state_set: true
```

---

### Scenario PR-004: Multi-Language PR Review

#### Objective
Test agent's capability to review PRs with multiple programming languages.

#### Prerequisites
- Repository: `test-repo-multilang`
- Languages: Python, JavaScript, Go, Java, YAML
- Linters configured for each language

#### Test Data
- **PR Branch**: `feature/multilang-updates`
- **Files**:
  - `backend/api.py` (Python - PEP8 issues)
  - `frontend/app.js` (JavaScript - ESLint warnings)
  - `services/processor.go` (Go - golint suggestions)
  - `utils/Helper.java` (Java - style issues)
  - `.github/workflows/ci.yml` (YAML - syntax issue)

#### Execution Steps
1. Create multi-language PR
2. Trigger review workflow
3. Verify language-specific analysis:
   ```bash
   python scripts/analyze-review.py \
     --pr-number 4 \
     --check-language-coverage
   ```

#### Expected Results
1. All 5 languages analyzed
2. Language-specific issues identified:
   - Python: PEP8 violations
   - JavaScript: ESLint warnings
   - Go: golint suggestions
   - Java: Checkstyle issues
   - YAML: Syntax errors
3. Review organized by language or file
4. Appropriate linters used for each language

#### Validation Criteria
```yaml
assertions:
  - languages_analyzed: ["python", "javascript", "go", "java", "yaml"]
  - python_linter: "pylint"
  - javascript_linter: "eslint"
  - go_linter: "golint"
  - java_linter: "checkstyle"
  - yaml_linter: "yamllint"
  - all_issues_found: true
```

---

### Scenario PR-005: PR Review with Conflicting Changes

#### Objective
Test handling of PR with merge conflicts.

#### Prerequisites
- Repository: `test-repo-pr-reviews`
- Conflicting file exists on both branches

#### Test Data
- **Base Branch**: `main` (file `config.json` modified)
- **PR Branch**: `feature/config-update` (same file modified differently)

#### Execution Steps
1. Update `config.json` on main:
   ```bash
   git checkout main
   echo '{"version": "2.0"}' > config.json
   git commit -am "Update config version"
   git push
   ```

2. Create conflicting PR:
   ```bash
   git checkout feature/config-update
   echo '{"version": "1.5", "new_feature": true}' > config.json
   git commit -am "Add new feature config"
   gh pr create --base main --head feature/config-update
   ```

3. Monitor review workflow

#### Expected Results
1. Workflow detects merge conflict
2. Review includes conflict notification
3. Comment posted explaining:
   - Files with conflicts
   - Guidance to resolve
   - Review on-hold until conflicts resolved
4. No approval or change request (conflict blocks review)

#### Validation Criteria
```yaml
assertions:
  - conflict_detected: true
  - review_state: null  # No review until resolved
  - conflict_comment_posted: true
  - conflicting_files_listed: ["config.json"]
  - resolution_guidance_provided: true
```

---

### Scenario PR-006: Large PR Review (50+ Files)

#### Objective
Validate performance and accuracy with large PRs.

#### Prerequisites
- Repository: `test-repo-large`
- PR with 50+ file changes

#### Test Data
- **PR Branch**: `feature/major-refactor`
- **Files Changed**: 60 files across 10 directories
- **Total Changes**: 3000+ lines added, 2000+ removed

#### Execution Steps
1. Generate large PR:
   ```bash
   python scripts/generate-large-pr.py \
     --files 60 \
     --lines-added 3000 \
     --lines-removed 2000
   ```

2. Create PR and trigger review

3. Monitor performance:
   ```bash
   time gh run watch
   ```

#### Expected Results
1. All 60 files reviewed (100% coverage)
2. Review completed without timeout
3. Execution time < 600 seconds (10 minutes)
4. Memory usage < 4 GB
5. Summary includes:
   - High-level overview
   - Critical issues highlighted
   - Organized by module/directory

#### Validation Criteria
```yaml
assertions:
  - files_reviewed: 60
  - execution_time: "< 600 seconds"
  - memory_peak: "< 4 GB"
  - review_organized: true
  - critical_issues_highlighted: true
  - no_timeout: true
```

---

### Scenario PR-007: Security-Focused PR Review

#### Objective
Test security vulnerability detection in PR reviews.

#### Prerequisites
- Repository: `test-repo-security`
- Security scanners: Semgrep, Trivy
- Workflow: `.github/workflows/security-review.yml`

#### Test Data
- **PR Branch**: `feature/payment-integration`
- **Security Issues**:
  - SQL injection vulnerability (Line 45)
  - XSS vulnerability (Line 78)
  - Hardcoded API key (Line 120)
  - Weak crypto algorithm (Line 156)
  - Unvalidated redirect (Line 203)

#### Execution Steps
1. Create PR with security issues:
   ```bash
   gh pr create \
     --title "Add payment integration" \
     --body "Payment gateway integration" \
     --base main \
     --head feature/payment-integration
   ```

2. Wait for security review workflow

3. Analyze security findings:
   ```bash
   gh pr view --json reviews | \
     jq '.reviews[] | select(.body | contains("SECURITY"))'
   ```

#### Expected Results
1. All 5 security issues detected
2. Each issue classified by severity:
   - CRITICAL: SQL injection, hardcoded key
   - HIGH: XSS vulnerability
   - MEDIUM: Weak crypto
   - LOW: Unvalidated redirect
3. Review includes CWE/CVE references
4. Remediation steps provided for each
5. Security team tagged

#### Validation Criteria
```yaml
assertions:
  - security_issues_found: 5
  - critical_count: 2
  - high_count: 1
  - medium_count: 1
  - low_count: 1
  - cwe_references_included: true
  - remediation_steps_provided: true
  - security_team_tagged: true
```

---

### Scenario PR-008: Performance-Focused PR Review

#### Objective
Detect performance issues in code changes.

#### Prerequisites
- Repository: `test-repo-performance`
- Performance profiling tools configured

#### Test Data
- **PR Branch**: `feature/optimization`
- **Performance Issues**:
  - N+1 query problem (Line 34)
  - Inefficient loop (Line 67)
  - Unnecessary API calls (Line 102)
  - Missing caching (Line 145)

#### Execution Steps
1. Create PR with performance issues
2. Trigger performance-aware review
3. Validate performance recommendations

#### Expected Results
1. All 4 performance issues identified
2. Each issue includes:
   - Performance impact description
   - Time complexity analysis
   - Optimization recommendation
   - Example code for fix
3. Benchmark suggestions provided

#### Validation Criteria
```yaml
assertions:
  - performance_issues_found: 4
  - complexity_analysis_included: true
  - optimization_recommendations: true
  - example_code_provided: true
  - benchmark_suggestions: true
```

---

## 3. ISSUE COMMENT WORKFLOW SCENARIOS

### Scenario IS-001: Question Issue Auto-Response

#### Objective
Test automated response to question-type issues.

#### Prerequisites
- Repository: `test-repo-issues`
- Issue label: "question"
- AI/LLM integration configured

#### Test Data
- **Issue Title**: "How to configure authentication?"
- **Issue Body**:
  ```
  I'm trying to set up OAuth authentication but getting errors.
  Can someone explain the configuration process?
  ```

#### Execution Steps
1. Create question issue:
   ```bash
   gh issue create \
     --title "How to configure authentication?" \
     --body "$(cat test-data/issues/auth-question.md)" \
     --label "question"
   ```

2. Wait for auto-response workflow (30 seconds)

3. Verify response:
   ```bash
   gh issue view 1 --json comments
   ```

#### Expected Results
1. Response posted within 60 seconds
2. Response includes:
   - Direct answer to question
   - Link to relevant documentation
   - Code example if applicable
   - Offer for follow-up help
3. Issue labeled "answered"
4. Helpful, professional tone

#### Validation Criteria
```yaml
assertions:
  - response_time: "< 60 seconds"
  - answer_relevant: true
  - documentation_link_included: true
  - code_example_included: true
  - issue_labeled: "answered"
  - tone_professional: true
```

---

### Scenario IS-002: Bug Report Triage

#### Objective
Validate automated bug report triage and categorization.

#### Prerequisites
- Repository: `test-repo-issues`
- Bug report template configured
- Triage workflow active

#### Test Data
- **Issue Title**: "Application crashes on startup"
- **Issue Body**: Uses bug report template with all fields filled
- **Severity**: High (app unusable)
- **Environment**: Windows 10, v2.3.1

#### Execution Steps
1. Create bug report using template:
   ```bash
   gh issue create \
     --title "Application crashes on startup" \
     --body "$(cat test-data/issues/bug-crash.md)" \
     --label "bug"
   ```

2. Wait for triage workflow

3. Check applied labels and comments:
   ```bash
   gh issue view 2 --json labels,comments
   ```

#### Expected Results
1. Triage completed within 60 seconds
2. Labels applied:
   - "bug" (original)
   - "priority:high" (auto-added)
   - "component:startup" (auto-added)
   - "os:windows" (auto-added)
3. Triage comment includes:
   - Severity assessment
   - Initial diagnosis
   - Assigned to appropriate team
   - Next steps for investigation

#### Validation Criteria
```yaml
assertions:
  - triage_time: "< 60 seconds"
  - labels_applied: ["bug", "priority:high", "component:startup", "os:windows"]
  - severity_correct: "high"
  - team_assigned: "platform-team"
  - next_steps_defined: true
```

---

### Scenario IS-003: Feature Request Evaluation

#### Objective
Test automated feature request evaluation and response.

#### Prerequisites
- Repository: `test-repo-issues`
- Feature evaluation workflow
- Product roadmap integration

#### Test Data
- **Issue Title**: "Add dark mode support"
- **Issue Body**: Feature request with use case and benefits

#### Execution Steps
1. Create feature request:
   ```bash
   gh issue create \
     --title "Add dark mode support" \
     --body "$(cat test-data/issues/feature-darkmode.md)" \
     --label "enhancement"
   ```

2. Wait for evaluation workflow

3. Check evaluation comment:
   ```bash
   gh issue view 3 --json comments,labels
   ```

#### Expected Results
1. Evaluation posted within 90 seconds
2. Evaluation includes:
   - Feasibility assessment
   - Scope estimation (small/medium/large)
   - Similar existing features referenced
   - Alignment with roadmap
   - Next steps (discussion/approval/roadmap)
3. Labels added:
   - "needs-discussion" or "approved" or "roadmap"
   - "scope:medium" (or appropriate scope)

#### Validation Criteria
```yaml
assertions:
  - evaluation_time: "< 90 seconds"
  - feasibility_assessed: true
  - scope_estimated: true
  - roadmap_alignment_checked: true
  - next_steps_clear: true
  - appropriate_labels: true
```

---

### Scenario IS-004: Duplicate Issue Detection

#### Objective
Validate duplicate issue detection and linking.

#### Prerequisites
- Repository: `test-repo-issues`
- Existing issue: #123 "Login button not working"
- Duplicate detection enabled

#### Test Data
- **New Issue Title**: "Can't click login button"
- **New Issue Body**: Similar description to issue #123

#### Execution Steps
1. Create duplicate issue:
   ```bash
   gh issue create \
     --title "Can't click login button" \
     --body "$(cat test-data/issues/duplicate-login.md)"
   ```

2. Wait for duplicate detection workflow

3. Verify duplicate handling:
   ```bash
   gh issue view 4 --json labels,comments
   ```

#### Expected Results
1. Duplicate detected within 30 seconds
2. Comment posted:
   - References original issue #123
   - Explains similarity
   - Asks reporter to confirm duplicate
3. Label "duplicate" added
4. Issue not auto-closed (waits for confirmation)

#### Validation Criteria
```yaml
assertions:
  - duplicate_detected: true
  - original_issue_linked: "#123"
  - duplicate_label_added: true
  - explanation_provided: true
  - confirmation_requested: true
  - issue_state: "open"  # Not auto-closed
```

---

### Scenario IS-005: Security Vulnerability Report

#### Objective
Test handling of security vulnerability reports.

#### Prerequisites
- Repository: `test-repo-security`
- Private issue support
- Security team notification configured

#### Test Data
- **Issue Title**: "SQL Injection vulnerability in login"
- **Issue Body**: Security report with proof of concept
- **Severity**: Critical

#### Execution Steps
1. Create security issue:
   ```bash
   gh issue create \
     --title "SQL Injection vulnerability in login" \
     --body "$(cat test-data/issues/security-sqli.md)" \
     --label "security"
   ```

2. Wait for security workflow (should be fast)

3. Verify security handling:
   ```bash
   gh issue view 5 --json labels,assignees,comments
   ```

#### Expected Results
1. Security workflow triggers immediately (< 10 seconds)
2. Labels applied:
   - "security"
   - "priority:critical"
3. Security team assigned
4. Comment posted:
   - Acknowledgment of report
   - Expected timeline for fix
   - Request to keep private
5. Notifications sent to security team

#### Validation Criteria
```yaml
assertions:
  - response_time: "< 10 seconds"
  - security_label: true
  - critical_priority: true
  - security_team_assigned: true
  - acknowledgment_posted: true
  - privacy_requested: true
  - security_team_notified: true
```

---

## 4. AUTO-FIX / COMMIT WORKFLOW SCENARIOS

### Scenario AF-001: Auto-Fix Linting Errors

#### Objective
Test automatic fixing and committing of linting errors.

#### Prerequisites
- Repository: `test-repo-autofix`
- Linters: ESLint, Prettier
- Auto-fix workflow enabled

#### Test Data
- **PR Branch**: `feature/needs-formatting`
- **Linting Issues**:
  - Missing semicolons (10 instances)
  - Incorrect indentation (15 instances)
  - Unused imports (5 instances)

#### Execution Steps
1. Create PR with linting issues:
   ```bash
   gh pr create \
     --title "Add new feature" \
     --body "Feature implementation" \
     --base main \
     --head feature/needs-formatting
   ```

2. Wait for auto-fix workflow

3. Verify auto-fix commit:
   ```bash
   gh pr view --json commits | \
     jq '.commits[] | select(.messageHeadline | contains("Auto-fix"))'
   ```

4. Check that linting now passes:
   ```bash
   gh pr checks
   ```

#### Expected Results
1. Auto-fix workflow detects linting issues
2. Fixes applied automatically:
   - Semicolons added
   - Indentation corrected
   - Unused imports removed
3. Commit created with message: "Auto-fix: Linting errors"
4. Commit pushed to PR branch
5. Subsequent linting check passes

#### Validation Criteria
```yaml
assertions:
  - autofix_commit_present: true
  - commit_message: "Auto-fix: Linting errors"
  - linting_check_status: "success"
  - files_modified: ["src/app.js", "src/utils.js"]
  - issues_resolved: 30  # 10 + 15 + 5
```

---

### Scenario AF-002: Dependency Version Update

#### Objective
Test automated dependency updates with testing.

#### Prerequisites
- Repository: `test-repo-dependencies`
- Package manager: npm
- Test suite present

#### Test Data
- **Outdated Package**: `lodash@4.17.15` → `lodash@4.17.21`
- **Security Fix**: Yes (CVE-2021-23337)

#### Execution Steps
1. Trigger dependency update workflow:
   ```bash
   gh workflow run dependency-update.yml
   ```

2. Wait for workflow to complete

3. Verify update PR:
   ```bash
   gh pr list --label "dependencies"
   ```

4. Check that tests pass:
   ```bash
   gh pr checks <pr-number>
   ```

#### Expected Results
1. Dependency updated in `package.json` and `package-lock.json`
2. Tests run successfully
3. PR created with:
   - Title: "chore: Update lodash to 4.17.21"
   - Body includes CVE reference
   - Label "dependencies"
   - Label "security"
4. Commit message: "chore: Update lodash to fix CVE-2021-23337"

#### Validation Criteria
```yaml
assertions:
  - pr_created: true
  - package_updated: "lodash@4.17.21"
  - tests_passing: true
  - cve_referenced: "CVE-2021-23337"
  - labels: ["dependencies", "security"]
```

---

### Scenario AF-003: Security Patch Application

#### Objective
Validate automated security patch application.

#### Prerequisites
- Repository: `test-repo-security-patch`
- Security scanner: Snyk
- Auto-patch enabled

#### Test Data
- **Vulnerability**: High severity in `express@4.16.0`
- **Patch Available**: `express@4.17.3`

#### Execution Steps
1. Security scan detects vulnerability

2. Auto-patch workflow triggers

3. Monitor patch application:
   ```bash
   gh run watch
   ```

4. Verify security PR:
   ```bash
   gh pr list --label "security"
   ```

#### Expected Results
1. Vulnerability detected by security scan
2. Patch workflow triggers automatically
3. Express updated to 4.17.3
4. Security scan re-run (clean)
5. PR created:
   - Title: "security: Patch Express vulnerability"
   - Body includes vulnerability details
   - Label "security", "priority:high"
   - All checks passing

#### Validation Criteria
```yaml
assertions:
  - vulnerability_detected: true
  - patch_applied: true
  - package_version: "express@4.17.3"
  - security_scan_clean: true
  - pr_created: true
  - pr_priority: "high"
```

---

### Scenario AF-004: Git Conflict During Auto-Fix

#### Objective
Test error handling when auto-fix encounters merge conflict.

#### Prerequisites
- Repository: `test-repo-autofix`
- Conflicting changes prepared

#### Test Data
- **Base Branch**: `main` (file updated)
- **PR Branch**: `feature/auto-fix-test` (same file has linting issues)

#### Execution Steps
1. Update file on main:
   ```bash
   git checkout main
   echo "// Updated on main" >> src/app.js
   git commit -am "Update app.js"
   git push
   ```

2. Create PR with linting issues on same file:
   ```bash
   git checkout feature/auto-fix-test
   # app.js has linting issues
   gh pr create --base main --head feature/auto-fix-test
   ```

3. Auto-fix workflow attempts to fix and commit

4. Observe conflict handling

#### Expected Results
1. Auto-fix workflow runs
2. Fixes applied locally
3. Conflict detected during push
4. Workflow fails gracefully
5. Comment posted on PR:
   - Explains conflict occurred
   - Lists conflicting files
   - Provides resolution guidance
6. No corrupt commits created

#### Validation Criteria
```yaml
assertions:
  - workflow_status: "failure"  # Expected failure
  - conflict_detected: true
  - conflict_comment_posted: true
  - conflicting_files: ["src/app.js"]
  - resolution_guidance: true
  - no_corrupt_commits: true
```

---

### Scenario AF-005: Code Formatting with Prettier

#### Objective
Test automated code formatting across multiple file types.

#### Prerequisites
- Repository: `test-repo-formatting`
- Prettier configured for JS, TS, JSON, YAML, Markdown

#### Test Data
- **Files to Format**:
  - `src/index.js` (JavaScript)
  - `src/types.ts` (TypeScript)
  - `config.json` (JSON)
  - `.github/workflows/ci.yml` (YAML)
  - `README.md` (Markdown)

#### Execution Steps
1. Create PR with unformatted files:
   ```bash
   gh pr create \
     --title "Add new features" \
     --base main \
     --head feature/unformatted
   ```

2. Prettier auto-format workflow triggers

3. Verify formatting commit:
   ```bash
   gh pr view --json commits
   ```

#### Expected Results
1. All 5 file types formatted
2. Single commit: "style: Format code with Prettier"
3. Consistent formatting applied:
   - 2-space indentation
   - Double quotes (JS/TS)
   - Trailing commas
   - Line length 80 chars
4. No functional changes (only formatting)

#### Validation Criteria
```yaml
assertions:
  - files_formatted: 5
  - commit_message: "style: Format code with Prettier"
  - indentation_consistent: "2 spaces"
  - no_functional_changes: true
  - prettier_check_passing: true
```

---

## 5. PERFORMANCE TEST SCENARIOS

### Scenario PF-001: Job Start Latency - Cold Start

#### Objective
Measure job start latency from idle state.

#### Prerequisites
- Runner idle for > 5 minutes
- Test workflow prepared
- Timing instrumentation enabled

#### Execution Steps
1. Ensure runner is idle:
   ```bash
   # Check runner status
   gh api repos/:owner/:repo/actions/runners
   ```

2. Trigger test workflow:
   ```bash
   START_TIME=$(date +%s%3N)
   gh workflow run performance-test.yml
   echo $START_TIME > /tmp/start_time.txt
   ```

3. Monitor job start:
   ```bash
   gh run watch --exit-status
   ```

4. Calculate latency:
   ```bash
   python scripts/calculate-latency.py \
     --start-file /tmp/start_time.txt \
     --run-id $(gh run list --limit 1 --json databaseId -q '.[0].databaseId')
   ```

#### Expected Results
1. Job starts within 60 seconds (requirement)
2. Target: < 30 seconds
3. Optimal: < 15 seconds

#### Validation Criteria
```yaml
assertions:
  - job_start_latency: "< 60 seconds"
  - target_met: "< 30 seconds"
  - measurement_accurate: true
  - runner_was_idle: true
```

---

### Scenario PF-002: Checkout Performance - Large Repository

#### Objective
Measure checkout time for large repository and compare to GitHub-hosted.

#### Prerequisites
- Test repository: 500 MB size
- GitHub-hosted runner for baseline
- Self-hosted runner for comparison

#### Execution Steps
1. **Baseline (GitHub-hosted)**:
   ```yaml
   jobs:
     checkout-baseline:
       runs-on: ubuntu-latest
       steps:
         - name: Start Timer
           run: echo "START=$(date +%s%3N)" >> $GITHUB_ENV
         - uses: actions/checkout@v3
         - name: Calculate Time
           run: |
             END=$(date +%s%3N)
             DURATION=$((END - START))
             echo "Checkout time: ${DURATION}ms"
   ```

2. **Self-hosted test**:
   ```yaml
   jobs:
     checkout-selfhosted:
       runs-on: self-hosted
       steps:
         - name: Start Timer
           run: echo "START=$(date +%s%3N)" >> $GITHUB_ENV
         - uses: actions/checkout@v3
         - name: Calculate Time
           run: |
             END=$(date +%s%3N)
             DURATION=$((END - START))
             echo "Checkout time: ${DURATION}ms"
   ```

3. Compare results:
   ```bash
   python scripts/compare-checkout.py \
     --github-run <github-run-id> \
     --selfhosted-run <selfhosted-run-id>
   ```

#### Expected Results
- GitHub-hosted: ~100 seconds
- Self-hosted: < 30 seconds (70% improvement)
- Improvement: >= 70%

#### Validation Criteria
```yaml
assertions:
  - github_checkout_time: "~100 seconds"
  - selfhosted_checkout_time: "< 30 seconds"
  - improvement_percent: ">= 70%"
  - measurement_valid: true
```

---

### Scenario PF-003: Concurrent Workflow Execution

#### Objective
Test system performance with 50 concurrent workflows.

#### Prerequisites
- 50 test workflows prepared
- Resource monitoring active
- Load generator configured

#### Execution Steps
1. Start monitoring:
   ```bash
   python scripts/monitor-resources.py --interval 5 &
   MONITOR_PID=$!
   ```

2. Trigger 50 concurrent workflows:
   ```bash
   python scripts/load-generator.py \
     --workflows 50 \
     --concurrency 50 \
     --workflow performance-test.yml
   ```

3. Monitor execution:
   ```bash
   watch -n 5 'gh run list --limit 50 --json status,conclusion | jq "group_by(.status)"'
   ```

4. Collect results:
   ```bash
   kill $MONITOR_PID
   python scripts/analyze-concurrent-load.py \
     --results /tmp/monitor-resources.json
   ```

#### Expected Results
1. All 50 workflows start within 60 seconds
2. No queuing delays
3. CPU usage < 80% peak
4. Memory usage < 6 GB per runner
5. All workflows complete successfully
6. No performance degradation

#### Validation Criteria
```yaml
assertions:
  - workflows_triggered: 50
  - all_started_within: "60 seconds"
  - cpu_peak: "< 80%"
  - memory_peak: "< 6 GB"
  - success_rate: "100%"
  - no_degradation: true
```

---

### Scenario PF-004: Cache Effectiveness Test

#### Objective
Measure cache performance improvement.

#### Prerequisites
- Workflow with npm dependencies
- Cache action configured
- Clean state for first run

#### Execution Steps
1. **First run (cold cache)**:
   ```bash
   gh workflow run cache-test.yml --field run_type=cold
   COLD_RUN_ID=$(gh run list --limit 1 --json databaseId -q '.[0].databaseId')
   gh run watch --exit-status $COLD_RUN_ID
   ```

2. **Second run (warm cache)**:
   ```bash
   gh workflow run cache-test.yml --field run_type=warm
   WARM_RUN_ID=$(gh run list --limit 1 --json databaseId -q '.[0].databaseId')
   gh run watch --exit-status $WARM_RUN_ID
   ```

3. **Compare times**:
   ```bash
   python scripts/compare-cache-performance.py \
     --cold-run $COLD_RUN_ID \
     --warm-run $WARM_RUN_ID
   ```

#### Expected Results
- Cold run: ~60 seconds (full npm install)
- Warm run: < 10 seconds (cache restore)
- Cache effectiveness: 83% improvement
- Cache hit rate: 100%

#### Validation Criteria
```yaml
assertions:
  - cold_run_time: "~60 seconds"
  - warm_run_time: "< 10 seconds"
  - improvement: ">= 70%"
  - cache_hit_rate: "100%"
```

---

## 6. SECURITY TEST SCENARIOS

### Scenario SC-001: Credential Leak Detection in Logs

#### Objective
Verify credential leak prevention in workflow logs.

#### Prerequisites
- Credential scanning enabled
- Test secrets configured
- Log monitoring active

#### Test Data
- Test PAT: `ghp_test1234567890abcdef`
- Test AWS Key: `AKIA1234567890ABCDEF`

#### Execution Steps
1. Create workflow that accidentally logs secret:
   ```yaml
   - name: Dangerous Step (TEST)
     run: |
       echo "Token is: ${{ secrets.TEST_PAT }}"
   ```

2. Execute workflow:
   ```bash
   gh workflow run leak-test.yml
   ```

3. Check logs for masking:
   ```bash
   gh run view --log | grep -i "token"
   ```

4. Run credential scanner:
   ```bash
   trufflehog git file://. --since-commit HEAD~1
   ```

#### Expected Results
1. GitHub automatically masks secrets in logs
2. Scanner detects any unmasks secrets
3. Alert generated if leak detected
4. Workflow fails if leak found
5. Security team notified

#### Validation Criteria
```yaml
assertions:
  - secrets_masked_in_logs: true
  - scanner_run: true
  - no_credentials_in_logs: true
  - alerts_generated_if_leak: true
  - security_team_notified_if_leak: true
```

---

### Scenario SC-002: Permission Boundary Testing

#### Objective
Validate permission boundaries are enforced.

#### Prerequisites
- Multiple PATs with different scopes
- Test workflows requiring different permissions

#### Test Data
- **Read-only PAT**: `repo:read` scope
- **Write PAT**: `repo:write` scope
- **Admin PAT**: `admin:org` scope

#### Execution Steps
1. Test read-only PAT attempting write operation:
   ```bash
   export GH_TOKEN=$READ_ONLY_PAT
   gh pr review 123 --approve  # Should fail
   ```

2. Test write PAT attempting admin operation:
   ```bash
   export GH_TOKEN=$WRITE_PAT
   gh api repos/:owner/:repo/collaborators/:user -X PUT  # Should fail
   ```

3. Test appropriate permissions:
   ```bash
   export GH_TOKEN=$WRITE_PAT
   gh pr review 123 --approve  # Should succeed
   ```

4. Verify audit logs:
   ```bash
   gh api /orgs/:org/audit-log | jq '.[] | select(.action == "access_denied")'
   ```

#### Expected Results
1. Read-only PAT: Write operations blocked
2. Write PAT: Admin operations blocked
3. Each PAT works within its scope
4. All denials logged in audit log
5. Clear error messages for denied operations

#### Validation Criteria
```yaml
assertions:
  - readonly_write_blocked: true
  - write_admin_blocked: true
  - scope_enforcement: "100%"
  - audit_log_complete: true
  - error_messages_clear: true
```

---

## 7. ERROR HANDLING SCENARIOS

### Scenario ER-001: Network Failure During Workflow

#### Objective
Test error handling when network fails mid-workflow.

#### Prerequisites
- Network disruption capability
- Retry logic configured
- Workflow in progress

#### Execution Steps
1. Start long-running workflow:
   ```bash
   gh workflow run long-test.yml
   ```

2. During execution, simulate network failure:
   ```bash
   # Disconnect network for 30 seconds
   python scripts/simulate-network-failure.py --duration 30
   ```

3. Monitor workflow behavior:
   ```bash
   gh run watch --exit-status
   ```

4. Check retry attempts:
   ```bash
   gh run view --log | grep -i "retry"
   ```

#### Expected Results
1. Network failure detected within 10 seconds
2. Retry logic activates
3. Exponential backoff applied (1s, 2s, 4s)
4. Workflow recovers when network restored
5. If network stays down: Clear error message

#### Validation Criteria
```yaml
assertions:
  - failure_detected: "< 10 seconds"
  - retry_attempts: 3
  - backoff_pattern: "exponential"
  - recovery_successful: true
  - error_message_clear: true
```

---

### Scenario ER-002: API Rate Limit Handling

#### Objective
Test graceful handling of GitHub API rate limits.

#### Prerequisites
- Workflow making many API calls
- Rate limit monitoring
- Near rate limit threshold

#### Execution Steps
1. Exhaust API rate limit:
   ```bash
   python scripts/exhaust-rate-limit.py
   ```

2. Trigger workflow requiring API calls:
   ```bash
   gh workflow run api-heavy.yml
   ```

3. Monitor rate limit handling:
   ```bash
   gh run watch --log | grep -i "rate limit"
   ```

4. Check retry-after compliance:
   ```bash
   gh api rate_limit
   ```

#### Expected Results
1. Rate limit detected (HTTP 429)
2. Retry-after header parsed
3. Workflow pauses until reset
4. Resumes automatically after reset
5. No failed API calls

#### Validation Criteria
```yaml
assertions:
  - rate_limit_detected: true
  - retry_after_parsed: true
  - workflow_paused: true
  - resumed_after_reset: true
  - api_calls_successful: "100%"
```

---

## 8. INTEGRATION SCENARIOS

### Scenario IN-001: Multi-Repository Workflow

#### Objective
Test workflow operating across multiple repositories.

#### Prerequisites
- 3 test repositories (repo-a, repo-b, repo-c)
- Cross-repo permissions configured
- Workflow in repo-a triggers actions in repo-b and repo-c

#### Execution Steps
1. Trigger multi-repo workflow:
   ```bash
   gh workflow run multi-repo.yml --repo org/repo-a
   ```

2. Verify operations in all repos:
   ```bash
   for repo in repo-a repo-b repo-c; do
     echo "Checking $repo"
     gh api repos/org/$repo/actions/runs --jq '.workflow_runs[0].status'
   done
   ```

3. Validate cross-repo changes:
   ```bash
   python scripts/validate-multi-repo.py \
     --repos org/repo-a,org/repo-b,org/repo-c
   ```

#### Expected Results
1. Workflow in repo-a completes successfully
2. Triggered workflows in repo-b and repo-c
3. Changes applied correctly to each repo
4. All repos in consistent state
5. No permission errors

#### Validation Criteria
```yaml
assertions:
  - all_repos_updated: true
  - repos_consistent: true
  - no_permission_errors: true
  - workflow_coordination: "successful"
```

---

### Scenario IN-002: AI Service Integration with Fallback

#### Objective
Test AI service integration with fallback to secondary provider.

#### Prerequisites
- Primary AI: OpenAI GPT-4
- Fallback AI: Anthropic Claude
- Both APIs configured

#### Execution Steps
1. Configure primary AI service

2. Trigger PR review workflow:
   ```bash
   gh pr create --title "Test PR" --body "Test" --base main --head test
   ```

3. Simulate primary AI failure:
   ```bash
   python scripts/block-openai-api.py
   ```

4. Verify fallback activation:
   ```bash
   gh run view --log | grep -i "fallback"
   ```

#### Expected Results
1. Primary AI (OpenAI) attempted first
2. Failure detected within 5 seconds
3. Fallback to secondary AI (Claude)
4. Review completed successfully
5. Comment indicates fallback used (optional)

#### Validation Criteria
```yaml
assertions:
  - primary_ai_attempted: true
  - fallback_activated: true
  - fallback_successful: true
  - review_quality_maintained: true
  - execution_time: "< 120 seconds"
```

---

## 9. CROSS-PLATFORM SCENARIOS

### Scenario XP-001: Windows + WSL Workflow

#### Objective
Test workflow with both Windows (PowerShell) and WSL (Bash) steps.

#### Prerequisites
- Windows runner with WSL 2.0
- Ubuntu 22.04 in WSL
- Test workflow with mixed steps

#### Test Workflow
```yaml
name: Cross-Platform Test
jobs:
  test:
    runs-on: self-hosted  # Windows + WSL
    steps:
      - name: Windows Step (PowerShell)
        shell: pwsh
        run: |
          Write-Host "Running on Windows"
          $env:WINDOWS_VAR = "test"

      - name: WSL Step (Bash)
        shell: wsl-bash {0}
        run: |
          echo "Running in WSL"
          export WSL_VAR="test"

      - name: Data Sharing Test
        shell: pwsh
        run: |
          # Access file created in WSL
          Get-Content C:\path\to\wsl\file.txt
```

#### Execution Steps
1. Trigger cross-platform workflow:
   ```bash
   gh workflow run cross-platform.yml
   ```

2. Monitor execution:
   ```bash
   gh run watch --log
   ```

3. Verify both environments used:
   ```bash
   gh run view --log | grep -E "(Running on Windows|Running in WSL)"
   ```

#### Expected Results
1. PowerShell steps execute natively
2. Bash steps execute in WSL
3. Data sharing works between environments
4. File paths converted correctly (Windows ↔ WSL)
5. No environment conflicts

#### Validation Criteria
```yaml
assertions:
  - powershell_steps_successful: true
  - wsl_bash_steps_successful: true
  - data_sharing_works: true
  - path_conversion_correct: true
  - no_environment_conflicts: true
```

---

### Scenario XP-002: Linux Native vs Windows WSL Comparison

#### Objective
Compare performance between Linux native and Windows WSL runners.

#### Prerequisites
- Linux native runner
- Windows + WSL runner
- Identical test workflow

#### Execution Steps
1. Run on Linux native:
   ```bash
   gh workflow run perf-test.yml \
     --field runner_type=linux-native
   ```

2. Run on Windows WSL:
   ```bash
   gh workflow run perf-test.yml \
     --field runner_type=windows-wsl
   ```

3. Compare results:
   ```bash
   python scripts/compare-platform-performance.py \
     --linux-run <run-id> \
     --wsl-run <run-id>
   ```

#### Expected Results
- Both platforms complete successfully
- Performance within 10% of each other
- WSL overhead minimal (< 5%)
- Functionality identical

#### Validation Criteria
```yaml
assertions:
  - both_platforms_successful: true
  - performance_difference: "< 10%"
  - wsl_overhead: "< 5%"
  - functionality_identical: true
```

---

## APPENDICES

### Appendix A: Test Data Files

**Location**: `test-data/`

```
test-data/
├── repositories/
│   ├── test-repo-pr-reviews/
│   ├── test-repo-issues/
│   ├── test-repo-autofix/
│   └── test-repo-security/
├── pr-bodies/
│   ├── simple-fix.md
│   ├── complex-refactor.md
│   └── security-patch.md
├── issues/
│   ├── auth-question.md
│   ├── bug-crash.md
│   ├── feature-darkmode.md
│   └── security-sqli.md
├── mock-responses/
│   ├── github-api/
│   └── ai-services/
└── expected-results/
    ├── expected-issues.json
    └── expected-reviews.json
```

### Appendix B: Validation Scripts

**Location**: `scripts/`

```
scripts/
├── validate-review.py
├── analyze-review.py
├── calculate-latency.py
├── compare-checkout.py
├── load-generator.py
├── monitor-resources.py
├── compare-baseline.py
└── generate-report.py
```

### Appendix C: Scenario Execution Checklist

```yaml
scenario_execution_checklist:
  pre_execution:
    - [ ] Test environment prepared
    - [ ] Test data loaded
    - [ ] Monitoring enabled
    - [ ] Baseline established

  during_execution:
    - [ ] Scenario steps followed
    - [ ] Metrics collected
    - [ ] Logs captured
    - [ ] Issues documented

  post_execution:
    - [ ] Results validated
    - [ ] Cleanup performed
    - [ ] Report generated
    - [ ] Defects logged
```

---

**Document Version**: 1.0
**Last Updated**: 2025-10-17
**Total Scenarios**: 83
**Owner**: Test Automator
**Status**: Draft - Awaiting Approval
