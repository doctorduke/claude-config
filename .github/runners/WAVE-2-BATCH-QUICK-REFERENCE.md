# Wave 2 Batch Quick Reference

## Overview
- **Total Echoes:** 76 medium-priority issues
- **Estimated Effort:** 405-520 minutes (6.75-8.67 hours)
- **Strategy:** 5 themed batches, can be executed in parallel or sequence
- **Timeline:** 1-2 days recommended
- **Risk Level:** LOW

---

## Batch 1: Critical Code Quality & Test Framework
**Duration:** 90-120 minutes | **Risk:** LOW | **Dependencies:** None

### PRs to Fix
- PR #8: Testing Infrastructure
- PR #20: Unit Tests
- PR #21: Integration Tests
- PR #22: Security Tests

### Issues (15 total)
1. Eval security warning documentation (PR #8)
2. JSON array empty case handling (PR #8)
3. Test result parsing fragility (PR #8)
4. Incorrect test token data (PR #8)
5. Incomplete mock test coverage (PR #8)
6. run_test output suppression fix (PR #20)
7. test_it output suppression fix (PR #20)
8. Test syntax error correction (PR #20)
9. Coverage calculation warnings (PR #20)
10. Placeholder logging tests (PR #20)
11. Test line count inconsistencies (PR #21)
12. Test setup organization (PR #21)
13. Non-portable grep -oP (PR #21)
14. Security test enforcement (PR #22)
15. Test suite duplication (PR #22)

### Steps
1. Review each test file for output suppression issues
2. Implement proper test output capture and display
3. Replace placeholder tests with actual implementations
4. Add documentation for eval usage
5. Run full test suite to verify

---

## Batch 2: Documentation & File Paths
**Duration:** 60-90 minutes | **Risk:** LOW | **Dependencies:** None

### PRs to Fix
- PR #9: Secret Encryption
- PR #14: Secret Masking
- PR #20: Unit Tests
- PR #24: Network Timeouts
- PR #26: Token Auto-Refresh

### Issues (18 total)
1. Line count documentation accuracy (PR #9)
2. Unused import cleanup (PR #9)
3. Broad exception documentation (PR #9)
4. DRY principle - repeated python detection (PR #9)
5. custom_secrets example clarity (PR #14)
6. Comma-handling documentation (PR #14)
7. Absolute file paths in TASK-14-COMPLETION-REPORT.md (PR #20)
8. Test summary inconsistencies (PR #20)
9. DNS timeout hardcoded value docs (PR #24)
10. Duplicate curl command docs (PR #24)
11. Incomplete validation function docs (PR #24)
12. Disabled test re-enable info (PR #24)
13. Log rotation setup documentation (PR #26)
14. Absolute Windows paths in docs (PR #26)
15. Variable name typo documentation (/var/log) (PR #26)
16. Date command handling docs (PR #26)
17. Environment variable drift risk doc (PR #26)
18. Documentation URL placeholder (PR #26)

### Steps
1. Audit all documentation for absolute paths (Windows, Linux, macOS)
2. Update line count claims with actual file sizes
3. Document configuration requirements and defaults
4. Clarify examples with actual working code
5. Fix variable naming consistency
6. Update placeholders with actual values

---

## Batch 3: Portability & Cross-Platform
**Duration:** 60-80 minutes | **Risk:** LOW | **Dependencies:** None

### PRs to Fix
- PR #15: PAT Protected Branches
- PR #21: Integration Tests
- PR #22: Security Tests
- PR #23: E2E Tests

### Issues (12 total)
1. Non-portable grep -P in PAT test (PR #15)
2. Non-portable grep -oP in integration tests (PR #21)
3. Non-portable grep -oP in AI autofix workflow (PR #21)
4. Non-portable grep -P in security tests (PR #22)
5. Non-portable grep -oP in helper functions (PR #21)
6. Non-portable regex syntax in E2E runner lifecycle (PR #23)
7. Non-portable regex syntax in E2E helpers (PR #23)
8. Non-portable regex patterns in failure recovery (PR #23)
9. Non-portable grep -oP in issue analysis (PR #23)
10. Regex alternation syntax issues (PR #23)
11. Extended regex without proper flags (PR #21, #23)
12. Bash regex operator vs grep -E consistency (PR #23)

### Steps
1. Replace `grep -P` with `grep -E` (POSIX Extended Regular Expressions)
2. Replace `grep -oP` with portable alternatives (sed, awk, bash native)
3. Use `[[ $var =~ pattern ]]` consistently for bash regex
4. Test on BSD grep (macOS) and GNU grep (Linux)
5. Document regex approach in code comments

### Mapping
- grep -P → grep -E (basic conversions)
- grep -oP → awk or sed -n 's/.../&/p' (complex replacements)
- Perl regex → Extended Regular Expressions (POSIX)

---

## Batch 4: Configuration & Test Data
**Duration:** 75-100 minutes | **Risk:** MEDIUM | **Dependencies:** None

### PRs to Fix
- PR #12: Input Validation
- PR #16: Circuit Breaker
- PR #24: Network Timeouts
- PR #25: Queue Monitoring
- PR #26: Token Auto-Refresh

### Issues (9 total)
1. Path traversal test data correction (PR #12)
2. JSON validation test expectations (PR #12)
3. File path validation test expectations (PR #12)
4. Lock timeout logic timestamp-based (PR #16)
5. DNS_TIMEOUT variable definition (PR #24)
6. DNS_TIMEOUT test re-enablement (PR #24)
7. Hardcoded timeout cleanup (PR #24)
8. Inefficient duplicate API calls (PR #25)
9. Inefficient duplicate jq calls (PR #25)

### Steps
1. Verify all hardcoded values have corresponding config variables
2. Update test data to match actual function behavior
3. Validate test expectations align with implementation
4. Combine duplicate API calls into single request
5. Optimize jq invocations to single call where possible
6. Document any intentional configuration defaults

### Key Files to Review
- scripts/lib/validation.sh (test data validation)
- scripts/lib/circuit_breaker.sh (timeout logic)
- scripts/lib/network.sh (DNS_TIMEOUT definition)
- scripts/monitor-queue-depth.sh (API efficiency)

---

## Batch 5: Code Readability & Quality
**Duration:** 120-150 minutes | **Risk:** LOW | **Dependencies:** None

### PRs to Fix
- PR #8: Testing Infrastructure
- PR #9: Secret Encryption
- PR #10: Token Logging
- PR #14: Secret Masking
- PR #17: HTTP Status
- PR #19: Branch Protection Bypass
- PR #23: E2E Tests
- PR #26: Token Auto-Refresh

### Issues (22 total)
1. Eval security risk documentation (PR #8)
2. JSON construction with untested functions (PR #8)
3. Broad exception in secret encryption (PR #9)
4. Unused contains_token function (PR #10)
5. No backup before overwrite (PR #10)
6. Brittle awk pattern for indentation (PR #14)
7. Comma failure in custom_secrets (PR #14)
8. Brittle awk in verify-secret-masking (PR #14)
9. Unusual tr command with multiline string (PR #17)
10. Unreadable single-line curl command (PR #17) - 2 instances
11. Backup file should be removed (PR #19)
12. Markdown formatting broken (PR #19)
13. Missing classic PAT explanation (PR #19)
14. Inconsistent permission matrix (PR #19)
15. Error suppression hiding issues (PR #19)
16. Fragile header parsing with grep/cut (PR #19)
17. Inconsistent regex syntax (PR #23) - 3 instances
18. Assertion incorrect (grep contains slash) (PR #23)
19. Duplicated section headers (PR #26)

### Steps
1. Remove unused functions (contains_token)
2. Replace fragile awk patterns with yq or sed
3. Break long curl commands into multiple lines
4. Replace unusual tr commands with character classes
5. Add proper error handling and backups
6. Remove backup files from version control (.backup extension)
7. Fix markdown formatting issues
8. Add missing documentation and explanations
9. Remove error suppression where it hides problems
10. Replace fragile parsing with robust tools

### Priority Order
- High Priority: unused functions, backup files, error suppression
- Medium Priority: formatting, readability improvements
- Low Priority: documentation clarity

---

## Execution Checklist

### Pre-Batch
- [ ] Review all files listed in batch
- [ ] Create feature branch: `git checkout -b wave-2-batch-X`
- [ ] Set up editor with proper syntax highlighting

### During Batch
- [ ] Make changes with descriptive commit messages
- [ ] Test each fix with relevant test suite
- [ ] Verify no regressions introduced
- [ ] Check for similar patterns in other files

### Post-Batch
- [ ] Run full test suite: `scripts/tests/run-all-tests.sh`
- [ ] Verify no new warnings or errors
- [ ] Create pull request with detailed description
- [ ] Link to echo scan findings
- [ ] Request code review

### Final
- [ ] Merge all 5 batch PRs to development
- [ ] Run integration tests
- [ ] Merge development → main
- [ ] Tag release version

---

## File Summary

### Batch 1 Key Files
- scripts/tests/lib/assertions.sh
- scripts/tests/lib/mocks.sh
- scripts/tests/lib/test-helpers.sh
- scripts/tests/run-all-tests.sh
- scripts/tests/lib/coverage.sh
- scripts/tests/unit/test-common-functions.sh
- scripts/tests/integration/test-*.sh

### Batch 2 Key Files
- scripts/encrypt_secret.py
- scripts/setup-secrets.sh
- .github/actions/mask-secrets/
- scripts/lib/network.sh
- scripts/runner-token-refresh.sh
- TASK documents and README files

### Batch 3 Key Files
- tests/test-autofix-protected-branches.sh
- .github/workflows/ai-autofix.yml
- scripts/tests/integration/test-*.sh
- scripts/tests/security/test-*.sh
- scripts/tests/integration/test-helpers.sh

### Batch 4 Key Files
- scripts/lib/validation.sh
- scripts/lib/circuit_breaker.sh
- scripts/lib/network.sh
- scripts/monitor-queue-depth.sh
- scripts/runner-token-refresh.sh

### Batch 5 Key Files
- scripts/tests/lib/assertions.sh
- scripts/encrypt_secret.py
- scripts/setup-runner.sh
- scripts/lib/common.sh
- .github/workflows/*.yml
- Documentation files

---

## Testing After Each Batch

### Test Commands
```bash
# Test framework tests
./scripts/tests/run-all-tests.sh

# Specific test files
bash ./scripts/tests/unit/test-*.sh
bash ./scripts/tests/integration/test-*.sh
bash ./scripts/tests/security/test-*.sh

# Syntax checking
shellcheck scripts/**/*.sh

# Portability check
bash -n scripts/**/*.sh
```

### Validation Criteria
- All tests pass
- No shell syntax errors
- No shellcheck warnings (except documented)
- No regressions in existing functionality
- New/updated code follows project standards

---

## Batch Dependencies

All 5 batches are **INDEPENDENT** - can be executed in any order or parallel.

No batch depends on another batch's completion.
No batch blocks other batches.

Recommended execution:
- Parallel: Run 2-3 batches simultaneously (different team members)
- Sequential: Complete in order 1-5 (single person over 1-2 days)
- Mixed: Start batches 1 & 2, then 3 & 4, then 5

---

## Effort Estimation Breakdown

| Batch | Issue Count | Est. Min | Est. Max | Avg/Issue |
|-------|------------|----------|----------|-----------|
| 1 | 15 | 90 min | 120 min | 6-8 min |
| 2 | 18 | 60 min | 90 min | 3-5 min |
| 3 | 12 | 60 min | 80 min | 5-7 min |
| 4 | 9 | 75 min | 100 min | 8-11 min |
| 5 | 22 | 120 min | 150 min | 5-7 min |
| **TOTAL** | **76** | **405 min** | **520 min** | **5-7 min** |

---

## Success Criteria

### Overall
- [ ] All 76 echoes addressed
- [ ] No new issues introduced
- [ ] All tests passing
- [ ] Development branch clean
- [ ] Ready for main merge

### Per Batch
- [ ] All issues in batch completed
- [ ] Batch PR created with description
- [ ] Batch PR reviewed and approved
- [ ] Batch PR merged to development

---

## References

- Full Scan: WAVE-COND-ECHO-SCAN.yaml
- Summary: WAVE-COND-ECHO-CONDITIONS-SUMMARY.md
- Visual: ECHO-CONDITIONS-VISUAL-SUMMARY.txt
- Original Issues: review-comments-analysis.md
- Wave 1 Plan: code-review-fix-plan.md

---

**Last Updated:** 2025-10-24
**Status:** Ready for Wave 2 Execution
**Risk Level:** LOW
