# PR Strategy: Structured Merge Plan
## 19 Branches → 9 Logical PRs

**Goal:** Merge 30,785 lines of code in reviewable, testable chunks
**Timeline:** Staggered merges over 3-5 days
**Approach:** Dependency-ordered, size-limited, independently testable

---

## PR Dependency Graph

```
┌─────────────────────────────────────────────────────────────┐
│                     PR #1: Testing Framework                 │
│                  (Foundation for all testing)                │
└───────────────────┬─────────────────────────────────────────┘
                    │
        ┌───────────┴──────────┬──────────────┬───────────────┐
        │                      │              │               │
┌───────▼──────┐   ┌──────────▼────┐  ┌──────▼──────┐  ┌────▼─────────┐
│ PR #2:       │   │ PR #3:         │  │ PR #4:      │  │ PR #5:       │
│ Security     │   │ Architecture   │  │ Testing     │  │ Network/Perf │
│ Critical     │   │ Resilience     │  │ Suites      │  │ Fixes        │
└──────┬───────┘   └────────┬───────┘  └─────┬───────┘  └──────┬───────┘
       │                    │                 │                 │
       └────────────────────┴─────────────────┴─────────────────┘
                                    │
                         ┌──────────▼──────────┐
                         │  PR #6: Security    │
                         │  Enhancements       │
                         └──────────┬──────────┘
                                    │
                         ┌──────────▼──────────┐
                         │ PR #7-#9: Polish    │
                         │ & Optimizations     │
                         └─────────────────────┘
```

---

## PR Grouping Strategy

### Wave A: Foundation (Merge First - No Dependencies)

#### PR #1: Testing Infrastructure Foundation
**Priority:** P0 - MUST MERGE FIRST
**Size:** ~3,327 lines
**Branch:** `testing/task13-framework`
**Can Review/Merge:** Independently
**Blocks:** All other testing PRs

**Rationale:** Provides framework for validating all other PRs

**Contents:**
- Test framework library
- Assertion helpers
- Mock infrastructure
- Coverage tooling
- CI/CD workflow for tests

**Issue:** New - "Implement comprehensive test framework"

---

### Wave B: Critical Security (Merge Second - Parallel Review Possible)

#### PR #2: Critical Security Fixes - Part 1 (Cryptography & Secrets)
**Priority:** P0 - CRITICAL
**Size:** ~2,328 lines (+1,149 modified)
**Branches:**
- `security/task2-secret-encryption`
- `security/task4-secure-temp-files`
- `security/task7-secret-masking`

**Can Review/Merge:** After PR #1 (for testing)
**Blocks:** None

**Rationale:** Groups all cryptography and secret handling together

**Contents:**
- Secure secret encryption (libsodium)
- Secure temp file handling
- Secret masking in workflows

**Issues:**
- Existing: TASKS-REMAINING.md Tasks #2, #4, #7
- New: "Critical Security: Cryptography & Secret Management"

---

#### PR #3: Critical Security Fixes - Part 2 (Input Validation & Code Safety)
**Priority:** P0 - CRITICAL
**Size:** ~1,676 lines
**Branches:**
- `security/task3-sanitize-logging`
- `security/task5-input-validation`
- `security/task6-remove-eval`

**Can Review/Merge:** After PR #1 (for testing), can be parallel with PR #2
**Blocks:** None

**Rationale:** Groups all input handling and code safety together

**Contents:**
- Token sanitization in logs
- Input validation library (12 functions)
- Remove dangerous eval usage

**Issues:**
- Existing: TASKS-REMAINING.md Tasks #3, #5, #6
- New: "Critical Security: Input Validation & Code Safety"

---

### Wave C: Architecture & Resilience (Merge Third - After Security)

#### PR #4: Architecture Resilience & Error Handling
**Priority:** P1 - HIGH
**Size:** ~4,129 lines
**Branches:**
- `architecture/task9-circuit-breakers`
- `architecture/task10-http-status`
- `architecture/task11-conflict-detection`
- `architecture/task12-protection-bypass`

**Can Review/Merge:** After PR #1, #2, #3
**Blocks:** None

**Rationale:** All architecture improvements for resilience and error handling

**Contents:**
- Circuit breaker pattern (3 states)
- HTTP status categorization (no retry on 4xx)
- Merge conflict detection
- Enhanced branch protection bypass (4 strategies)

**Issues:**
- Existing: TASKS-REMAINING.md Tasks #9, #10, #11, #12
- New: "Architecture: Resilience & Error Handling"

---

### Wave D: Testing Validation (Merge Fourth - After Security & Arch)

#### PR #5: Comprehensive Test Suites
**Priority:** P1 - HIGH
**Size:** ~12,586 lines
**Branches:**
- `testing/task14-unit-tests`
- `testing/task15-integration`
- `testing/task16-security`
- `testing/task17-e2e`

**Can Review/Merge:** After PR #1, #2, #3, #4
**Blocks:** None

**Rationale:** All test suites together - they validate the security and architecture fixes

**Contents:**
- Unit tests (87.5% coverage)
- Integration tests (95% pass rate)
- Security tests (100% detection)
- E2E tests (20+ scenarios)

**Issues:**
- Existing: TASKS-REMAINING.md Tasks #14, #15, #16, #17
- New: "Testing: Comprehensive Test Coverage"

**Note:** This is a large PR but it's all testing code, easy to review

---

### Wave E: Network & Performance (Merge Fifth - Independent)

#### PR #6: Network & Performance Improvements
**Priority:** P2 - MEDIUM
**Size:** ~5,632 lines
**Branches:**
- `network/task18-fix-timeouts`
- `performance/task19-queue-monitoring`
- `performance/task20-token-refresh`

**Can Review/Merge:** After PR #1 (for testing), independent of security/arch
**Blocks:** None

**Rationale:** All network and performance improvements together

**Contents:**
- Network timeout fixes (10min → 30s)
- Queue depth monitoring (6 export formats)
- Runner token auto-refresh

**Issues:**
- Existing: TASKS-REMAINING.md Tasks #18, #19, #20
- New: "Network & Performance: Timeouts, Monitoring, Auto-Refresh"

---

### Wave F: Protected Branch Enhancement (Merge Sixth - After Security)

#### PR #7: GitHub Actions Protected Branch Support
**Priority:** P2 - MEDIUM
**Size:** ~791 lines
**Branch:** `security/task8-pat-protected-branches`

**Can Review/Merge:** After PR #2 (secret masking), independent otherwise
**Blocks:** None

**Rationale:** Isolated feature, clear functionality, easy to review

**Contents:**
- PAT support for protected branches
- Dual-mode push strategy
- PR fallback for protected branches
- Documentation

**Issues:**
- Existing: TASKS-REMAINING.md Task #8
- New: "Feature: Protected Branch Auto-Fix Support"

---

## PR Size Summary

| PR # | Title | Lines | Branches | Priority | Dependency |
|------|-------|-------|----------|----------|------------|
| #1 | Testing Framework | ~3,327 | 1 | P0 | None |
| #2 | Security - Crypto & Secrets | ~2,328 | 3 | P0 | PR #1 |
| #3 | Security - Input & Code Safety | ~1,676 | 3 | P0 | PR #1 |
| #4 | Architecture - Resilience | ~4,129 | 4 | P1 | PR #1, #2, #3 |
| #5 | Comprehensive Test Suites | ~12,586 | 4 | P1 | PR #1, #2, #3, #4 |
| #6 | Network & Performance | ~5,632 | 3 | P2 | PR #1 |
| #7 | Protected Branch Support | ~791 | 1 | P2 | PR #2 |
| **Total** | | **~30,469** | **19** | | |

---

## Merge Timeline (Recommended)

### Day 1: Foundation
- ✅ Create all GitHub issues
- ✅ Create PR #1 (Testing Framework)
- ⏳ Review PR #1 (2-3 hours)
- ✅ Merge PR #1
- 🧪 Validate PR #1 tests pass

### Day 2: Critical Security
- ✅ Create PR #2 (Security - Crypto)
- ✅ Create PR #3 (Security - Input)
- ⏳ Review PR #2 & #3 (parallel, 3-4 hours each)
- 🧪 Run security tests from PR #1 framework
- ✅ Merge PR #2 & #3

### Day 3: Architecture & Network
- ✅ Create PR #4 (Architecture)
- ✅ Create PR #6 (Network/Perf)
- ⏳ Review PR #4 & #6 (parallel, 4-5 hours each)
- 🧪 Run integration tests
- ✅ Merge PR #4 & #6

### Day 4: Testing & Polish
- ✅ Create PR #5 (Test Suites)
- ✅ Create PR #7 (Protected Branches)
- ⏳ Review PR #5 (6-8 hours - large but all tests)
- ⏳ Review PR #7 (1-2 hours)
- ✅ Merge PR #5 & #7

### Day 5: Validation
- 🧪 Run complete E2E test suite (all PRs merged)
- 🧪 Security audit
- 🧪 Performance benchmarks
- 📊 Generate final metrics
- ✅ Production readiness sign-off

---

## Review Guidelines for Each PR

### PR #1: Testing Framework
**Review Focus:**
- ✓ Test helper functions are correct
- ✓ Assertions work as expected
- ✓ Mock infrastructure is sound
- ✓ CI/CD workflow is proper
- ⚠️ Don't worry about test coverage yet (that's PR #5)

**Validation:**
```bash
cd scripts/tests
./run-all-tests.sh --verbose
```

---

### PR #2: Security - Crypto & Secrets
**Review Focus:**
- ✓ Libsodium implementation is correct
- ✓ Temp file permissions are 600
- ✓ Secret masking works in all workflows
- ✓ No hardcoded secrets remain
- ⚠️ Critical: Verify encryption algorithm

**Validation:**
```bash
# Run security tests (after PR #1 merged)
cd scripts/tests/security
./test-secret-encryption.sh
./test-temp-file-security.sh
./test-secret-masking.sh
```

---

### PR #3: Security - Input & Code Safety
**Review Focus:**
- ✓ Input validation catches injection attacks
- ✓ No eval usage remains
- ✓ Token sanitization works correctly
- ✓ All 12 validation functions are sound
- ⚠️ Critical: Test injection prevention

**Validation:**
```bash
# Run security tests
cd scripts/tests/security
./test-input-validation.sh
./test-token-sanitization.sh
./test-no-eval.sh
```

---

### PR #4: Architecture - Resilience
**Review Focus:**
- ✓ Circuit breaker state transitions work
- ✓ HTTP status categorization is correct
- ✓ Conflict detection is accurate
- ✓ Branch protection strategies work
- ⚠️ Verify retry logic doesn't cause loops

**Validation:**
```bash
# Run architecture tests
cd scripts/tests
./test-circuit-breaker.sh
./test-http-status.sh
./test-conflict-detection.sh
```

---

### PR #5: Comprehensive Test Suites
**Review Focus:**
- ✓ Test coverage is comprehensive
- ✓ Tests are well-structured
- ✓ All critical paths covered
- ✓ Tests pass consistently
- ⚠️ This is a large PR but it's all test code

**Validation:**
```bash
# Run all test suites
cd scripts/tests
./run-all-tests.sh --coverage
```

---

### PR #6: Network & Performance
**Review Focus:**
- ✓ Timeout values are appropriate
- ✓ Monitoring metrics are useful
- ✓ Token refresh logic is sound
- ✓ No breaking changes to existing code
- ⚠️ Verify timeout doesn't break existing workflows

**Validation:**
```bash
# Run network tests
cd scripts/tests
./test-network-timeouts.sh
./test-monitor-queue-depth.sh
./test-runner-token-refresh.sh
```

---

### PR #7: Protected Branch Support
**Review Focus:**
- ✓ PAT configuration is documented
- ✓ Fallback strategies work
- ✓ No breaking changes
- ✓ Tests cover both protected/unprotected
- ⚠️ Easy to review, isolated feature

**Validation:**
```bash
# Run protected branch tests
cd scripts/tests
./test-protection-bypass-strategies.sh
```

---

## Issue Template for Each PR

```markdown
## Issue: [PR Title]

**Related TASKS-REMAINING.md:** Task #X, #Y, #Z
**Priority:** [P0/P1/P2]
**Estimated Review Time:** [X hours]

### Summary
[Brief description of what this PR does]

### Changes
- [List of main changes]

### Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Security tests pass (if applicable)
- [ ] E2E tests pass

### Dependencies
- Depends on: PR #X (if applicable)
- Blocks: PR #Y (if applicable)

### Review Checklist
- [ ] Code quality reviewed
- [ ] Security implications reviewed
- [ ] Performance impact reviewed
- [ ] Tests are comprehensive
- [ ] Documentation is updated

### Validation Commands
```bash
# Commands to validate this PR
```

### Risk Assessment
**Risk Level:** [Low/Medium/High]
**Rollback Plan:** [How to rollback if issues found]
```

---

## Success Criteria

✅ Each PR:
- Is independently reviewable
- Has clear issue linking
- Includes validation tests
- Has documented dependencies
- Is under 5000 lines (except test suite PR #5)
- Can be merged without breaking main

✅ Overall:
- All 19 branches merged via 7 PRs
- 30,785 lines of code reviewed and merged
- All critical security issues fixed
- Test coverage from 0% → 87.5%
- Production readiness achieved

---

## Next Actions

1. ✅ Create 7 GitHub issues (one per PR)
2. ✅ Create 7 PRs with proper descriptions and linking
3. 🔄 Stagger PR creation (don't overwhelm reviewers)
4. 📊 Track progress in project board
5. 🧪 Run E2E tests after all PRs merged

---

**Document Status:** Ready for Execution
**Estimated Timeline:** 5 days (with parallel reviews)
**Total Review Time:** ~30 hours (distributed across reviewers)
