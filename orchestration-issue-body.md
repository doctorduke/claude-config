## Executive Summary

This issue serves as the master orchestration plan for all remaining work identified during the comprehensive code review and grooming process. It provides a structured execution framework with clear priorities, dependencies, and success criteria.

**Current State:**
- **36 open issues** requiring resolution (#76-#109, plus legacy issues)
- **1 CRITICAL blocker** (#92) preventing AI PR review workflow
- **30 new issues** from recent grooming (#80-#109)
- **3 enhancement issues** (#76-#78) for defensive improvements
- **1 consolidated issue** (#79) for non-essential cosmetic changes

**Scope:**
- All issues organized into prioritized execution waves
- Clear dependency mapping and parallelization opportunities
- Forecasting with timeline estimates
- Evaluation framework for continuous improvement

---

## Critical Path (URGENT)

### Issue #92: Install Self-Hosted Runners (BLOCKER)

**Status:** CRITICAL - Blocking all AI PR review workflows

**Problem:**
- 20+ workflows stuck in queue indefinitely
- Zero self-hosted runners registered to repository
- Workflow requires `runs-on: [self-hosted, linux, ai-agent]`
- No automated alerting when runners go offline

**Success Criteria:**
- [ ] At least 1 self-hosted runner installed and online
- [ ] Runner has labels: `self-hosted`, `linux`, `ai-agent`
- [ ] Test workflow completes successfully in < 5 minutes
- [ ] Runner monitoring implemented to prevent recurrence

**Timeline:** 15-30 minutes (immediate fix)

**Dependencies:** None - must be resolved before Wave 1 begins

**Implementation Steps:**
1. Generate runner registration token
2. Install runner using `scripts/setup-runner.sh`
3. Validate runner is online with `gh api repos/:owner/:repo/actions/runners`
4. Test workflow execution with `gh workflow run ai-pr-review.yml`
5. Implement runner health monitoring (scheduled workflow)

**Verification:**
```bash
# Check runner status
gh api repos/:owner/:repo/actions/runners --jq '.runners[] | {name, status, busy}'

# Trigger test run
gh workflow run ai-pr-review.yml

# Monitor execution
gh run watch $(gh run list --workflow=ai-pr-review.yml --limit 1 --json databaseId -q '.[0].databaseId')
```

---

## Prioritized Execution Waves

### Wave 1: Critical & Security Issues (HIGH PRIORITY)

**Scope:** 9 issues - Security vulnerabilities and functional bugs requiring immediate attention

**Issues:**
- [ ] #92 - CRITICAL: Install self-hosted runners (BLOCKER) **[DONE FIRST]**
- [ ] #95 - Fix lock timeout logic in circuit_breaker.sh (bug, affects reliability)
- [ ] #98 - Replace non-portable grep -P with awk (bug, portability issue)
- [ ] #99 - Fix fragile workflow polling using PR head SHA (bug, test reliability)
- [ ] #101 - Fix custom_secrets multi-line format support (bug/enhancement)
- [ ] #106 - Fix test: sanitize_input should preserve spaces (bug, validation logic)
- [ ] #107 - Fix test: validate_filename should fail for newlines (bug, security)
- [ ] #104 - Remove confusing eval example from docs (security documentation)
- [ ] #109 - Strengthen trap quoting test enforcement (security, testing)

**Estimated Effort:** 4-6 hours
**Timeline:** Complete within 1 business day after #92 resolved

**Dependencies:**
- All items in this wave depend on #92 being resolved first
- Items can be parallelized after #92 completion
- No inter-dependencies within this wave

**Success Criteria:**
- All critical/security bugs fixed
- All tests passing
- No workflows blocked by infrastructure issues
- Security documentation updated and verified

---

### Wave 2: Functional Improvements & Code Quality (MEDIUM PRIORITY)

**Scope:** 14 issues - Functional improvements, code quality, and test robustness

**Issues:**
- [ ] #82 - Remove backup file from repository (code-quality)
- [ ] #86 - Remove stderr suppression in test-protection-bypass-strategies.sh (testing)
- [ ] #87 - Replace fragile header parsing with sed (code-quality, testing)
- [ ] #89 - Remove unused temp file creation logic (code-quality)
- [ ] #90 - Strengthen JSON validation test assertions (testing)
- [ ] #91 - Use POSIX character class [:space:] in tr command (code-quality)
- [ ] #93 - Format long curl commands across multiple lines (code-quality)
- [ ] #94 - Remove stderr suppression in test-http-status.sh (testing)
- [ ] #96 - Remove unused LAST_FAILURE_TIME variable (code-quality)
- [ ] #103 - Make awk pattern more flexible for whitespace (defensive-programming)
- [ ] #78 - Temp file security defensive improvements (5 sub-items)
- [ ] #80 - Replace absolute paths in TASK-14-COMPLETION-REPORT.md (documentation)
- [ ] #81 - Fix duplicated test summaries in TEST-SUMMARY.md (documentation)
- [ ] #102 - Replace absolute paths in SECURITY-TASK7-SUMMARY.md (documentation)

**Estimated Effort:** 6-8 hours
**Timeline:** 2-3 business days after Wave 1 completion

**Dependencies:**
- Wave 1 must be complete
- Items within this wave can be parallelized
- #78 has 5 sub-items that should be batched together

**Success Criteria:**
- All code quality improvements implemented
- No unused code or variables remaining
- Test robustness significantly improved
- Documentation paths corrected

---

### Wave 3: Documentation & Consistency (LOW-MEDIUM PRIORITY)

**Scope:** 11 issues - Documentation improvements, formatting fixes, and consistency

**Issues:**
- [ ] #83 - Fix markdown formatting in TASKS-REMAINING.md (documentation)
- [ ] #84 - Add Classic PAT requirement explanation (documentation)
- [ ] #85 - Fix inconsistent permission matrix (documentation)
- [ ] #88 - Fix escaped backticks in CONFLICT-DETECTION.md (documentation)
- [ ] #97 - Fix incorrect YAML conditional syntax in PAT-SETUP-GUIDE.md (documentation)
- [ ] #100 - Add multi-secret example to documentation (documentation)
- [ ] #105 - Add validate_json_string documentation (documentation)
- [ ] #108 - Document trap conflict limitations (documentation)
- [ ] #76 - Improve logging consistency in network.sh (enhancement)
- [ ] #77 - Improve eval alternatives documentation style (documentation)
- [ ] #68 - Improve secure temp file documentation clarity (documentation)

**Estimated Effort:** 3-4 hours
**Timeline:** 1-2 business days after Wave 2 completion

**Dependencies:**
- Wave 2 should be complete for consistency
- All items can be parallelized
- Can be batched into documentation-focused sessions

**Success Criteria:**
- All documentation complete and accurate
- Consistent formatting across all docs
- Clear examples for all documented features
- No markdown formatting errors

---

### Wave 4: Non-Essential Improvements (LOW PRIORITY)

**Scope:** 2 issues - Consolidated cosmetic changes and legacy cleanup

**Issues:**
- [ ] #79 - Consolidated cosmetic and documentation improvements (7 sub-items)
- [ ] #69 - Remove redundant return statement in check-secret-leaks.sh

**Estimated Effort:** 2-3 hours
**Timeline:** Can be deferred or addressed in maintenance windows

**Dependencies:**
- No blocking dependencies
- Should be addressed last
- Can be batched with other maintenance work

**Success Criteria:**
- Code clarity improvements implemented
- No redundant or confusing code patterns
- Logging consistency achieved
- Documentation style polished

---

## Dependency Map

### Critical Dependencies

```
#92 (Self-Hosted Runners)
  |
  +-- BLOCKS ALL OTHER WORK
      |
      +-- Wave 1 (Security & Critical Bugs)
          |
          +-- Wave 2 (Functional Improvements)
              |
              +-- Wave 3 (Documentation)
                  |
                  +-- Wave 4 (Non-Essential)
```

### Parallelization Opportunities

**Within Wave 1 (after #92):**
- All 8 remaining items can be addressed in parallel
- Group by area: security (3), bugs (4), tests (1)

**Within Wave 2:**
- Code quality items (#82, #89, #91, #93, #96) - parallel
- Test improvements (#86, #87, #90, #94) - parallel
- Documentation (#80, #81, #102) - parallel
- Defensive programming (#78, #103) - can batch together

**Within Wave 3:**
- All documentation items fully parallelizable
- Recommend batching into themed sessions

**Within Wave 4:**
- Fully parallelizable, low priority

### True Dependencies vs. Artificial Sequencing

**True Dependencies:**
- #92 blocks everything (infrastructure requirement)
- #78 sub-items should be batched (same context)
- #79 sub-items should be batched (cosmetic cleanup)

**Artificial Sequencing (can parallelize):**
- Wave 1 items after #92 - no inter-dependencies
- Wave 2 items - independent changes
- Wave 3 items - documentation-only changes
- Wave 4 items - cosmetic-only changes

**Recommendation:** Use parallel branches for independent items within each wave to maximize velocity.

---

## Forecasting

### Effort Estimates by Wave

| Wave | Issues | Estimated Hours | Timeline |
|------|--------|-----------------|----------|
| **Critical Path** | 1 (#92) | 0.5 hours | Immediate |
| **Wave 1** | 8 issues | 4-6 hours | 1 business day |
| **Wave 2** | 14 issues | 6-8 hours | 2-3 business days |
| **Wave 3** | 11 issues | 3-4 hours | 1-2 business days |
| **Wave 4** | 2 issues | 2-3 hours | Maintenance window |
| **TOTAL** | 36 issues | 16-22 hours | 5-7 business days |

### Velocity Assumptions

- **Serial execution:** 5-7 business days total
- **Parallel execution (2-3 concurrent streams):** 3-4 business days
- **Aggressive parallel (4+ streams):** 2-3 business days

### Resource Requirements

**Minimum (serial execution):**
- 1 developer
- Access to repository and runner infrastructure
- 2-3 hours per day capacity

**Optimal (parallel execution):**
- 2-3 developers or automated agents
- Ability to create parallel branches
- 4-6 hours per day aggregate capacity

### Risk Assessment

**High Risk Items:**
- #92 (infrastructure) - Requires system access, potential environment issues
- #95 (lock timeout) - Logic changes, could affect reliability
- #101 (multi-line secrets) - Parameter handling, breaking change potential

**Medium Risk Items:**
- #98, #99 (portability/polling) - Test reliability improvements
- #106, #107 (test expectations) - Validation logic changes

**Low Risk Items:**
- All documentation changes (Wave 3)
- All code quality/cosmetic changes (Wave 2, Wave 4)
- Test improvements without logic changes

**Mitigation Strategies:**
1. Address #92 first with validation and rollback plan
2. Test high-risk items thoroughly in isolation
3. Batch low-risk items for efficiency
4. Maintain rollback capability for each wave

---

## Backcasting Plan

### Wave 1 Success State

**What does success look like?**
- Self-hosted runners operational and monitored
- All critical bugs fixed with passing tests
- Security issues resolved and documented
- CI/CD pipeline fully functional

**Checkpoints:**
1. Runner installed and validated (15 min mark)
2. First 3 bugs fixed with tests passing (2 hour mark)
3. All Wave 1 items complete with green CI (end of day 1)

**Validation Gates:**
- [ ] All Wave 1 tests passing locally and in CI
- [ ] No regression in existing functionality
- [ ] Runner health monitoring active
- [ ] Code review completed for security-sensitive changes

**Rollback Plans:**
- Runner issues: Fall back to GitHub-hosted runners temporarily
- Bug fixes: Git revert capability for each commit
- Test failures: Roll back to previous stable state

---

### Wave 2 Success State

**What does success look like?**
- Codebase cleaner with no unused code
- Test suite more robust and maintainable
- Code quality metrics improved
- Documentation paths corrected

**Checkpoints:**
1. Code quality items complete (day 2, 2-hour mark)
2. Test improvements complete (day 2, 4-hour mark)
3. Documentation corrections complete (day 3, 2-hour mark)
4. Full Wave 2 validation (end of day 3)

**Validation Gates:**
- [ ] All tests passing with improved robustness
- [ ] Code coverage maintained or improved
- [ ] Static analysis shows no new warnings
- [ ] Documentation builds successfully

**Rollback Plans:**
- Individual commits can be reverted independently
- Test improvements isolated from production code
- Documentation changes have minimal risk

---

### Wave 3 Success State

**What does success look like?**
- Documentation complete, accurate, and well-formatted
- Consistent terminology and style across all docs
- Clear examples for all documented features
- User-facing documentation improved

**Checkpoints:**
1. Markdown formatting fixes complete (2-hour mark)
2. Content additions complete (4-hour mark)
3. Consistency review complete (6-hour mark)
4. Full documentation build validation (end of wave)

**Validation Gates:**
- [ ] All markdown linting passes
- [ ] Links validated and functional
- [ ] Examples tested and accurate
- [ ] Peer review of documentation changes

**Rollback Plans:**
- Documentation changes are low-risk
- Simple git revert for any issues
- Preview/staging environment for validation

---

### Wave 4 Success State

**What does success look like?**
- Codebase polished with no cosmetic issues
- Consistent code style throughout
- Logging patterns uniform
- Repository clean and maintainable

**Checkpoints:**
1. Cosmetic changes complete (#79 sub-items)
2. Redundant code removed (#69)
3. Final validation and cleanup
4. Repository health check passes

**Validation Gates:**
- [ ] No functional changes introduced
- [ ] All tests still passing
- [ ] Code review confirms cosmetic-only changes
- [ ] Repository metrics improved (clean files, consistent style)

**Rollback Plans:**
- Minimal risk - cosmetic changes only
- Can be deferred if needed
- Individual item rollback capability

---

## Evaluation Framework

### After Each Wave: Lessons Learned

**Process:**
1. Hold brief retrospective (15-30 minutes)
2. Document what worked well
3. Identify bottlenecks or challenges
4. Adjust approach for next wave

**Questions to Answer:**
- Were effort estimates accurate?
- Were dependencies correctly identified?
- Were parallelization opportunities utilized?
- What unexpected issues arose?
- What could be improved for next wave?

---

### Metrics to Track

**Velocity Metrics:**
- Issues resolved per day
- Actual vs. estimated time per issue
- Time blocked on dependencies
- Parallelization efficiency

**Quality Metrics:**
- Test coverage maintained/improved
- Number of bugs introduced vs. fixed
- Code review cycles per issue
- CI/CD pipeline success rate

**Process Metrics:**
- Wave completion time vs. forecast
- Dependency blocking frequency
- Rollback frequency (goal: 0)
- Rework percentage (goal: <10%)

**Tracking Mechanism:**
- Update this issue daily with progress
- Mark completed items with timestamps
- Document blockers immediately
- Record actual vs. estimated effort

---

### Process Improvements to Implement

**Between Waves:**
1. Adjust effort estimates based on actual data
2. Refine parallelization strategy
3. Update dependency map if new dependencies discovered
4. Optimize tooling and automation

**Continuous:**
- Maintain daily progress log
- Flag blockers immediately
- Share learning across parallel workstreams
- Update documentation as patterns emerge

---

### Review Gates Before Next Wave

**Gate Criteria:**
- [ ] All issues in current wave resolved
- [ ] All tests passing in CI/CD
- [ ] Code review completed and approved
- [ ] Documentation updated
- [ ] Retrospective completed
- [ ] Metrics recorded
- [ ] Learnings documented

**Gate Process:**
1. Run full test suite
2. Validate all issue acceptance criteria met
3. Review metrics and adjust forecasts
4. Document lessons learned
5. Obtain approval to proceed to next wave
6. Update this orchestration issue with status

---

## Issue Checklist

### Critical Path (IMMEDIATE)
- [ ] #92 - CRITICAL: Install self-hosted runners **[BLOCKER]**

### Wave 1: Critical & Security (HIGH PRIORITY)
- [ ] #95 - Fix lock timeout logic in circuit_breaker.sh
- [ ] #98 - Replace non-portable grep -P with awk
- [ ] #99 - Fix fragile workflow polling using PR head SHA
- [ ] #101 - Fix custom_secrets multi-line format support
- [ ] #106 - Fix test: sanitize_input should preserve spaces
- [ ] #107 - Fix test: validate_filename should fail for newlines
- [ ] #104 - Remove confusing eval example from docs
- [ ] #109 - Strengthen trap quoting test enforcement

### Wave 2: Functional Improvements (MEDIUM PRIORITY)
- [ ] #82 - Remove backup file from repository
- [ ] #86 - Remove stderr suppression in test-protection-bypass-strategies.sh
- [ ] #87 - Replace fragile header parsing with sed
- [ ] #89 - Remove unused temp file creation logic
- [ ] #90 - Strengthen JSON validation test assertions
- [ ] #91 - Use POSIX character class [:space:] in tr command
- [ ] #93 - Format long curl commands across multiple lines
- [ ] #94 - Remove stderr suppression in test-http-status.sh
- [ ] #96 - Remove unused LAST_FAILURE_TIME variable
- [ ] #103 - Make awk pattern more flexible for whitespace
- [ ] #78 - Temp file security defensive improvements (5 sub-items)
- [ ] #80 - Replace absolute paths in TASK-14-COMPLETION-REPORT.md
- [ ] #81 - Fix duplicated test summaries in TEST-SUMMARY.md
- [ ] #102 - Replace absolute paths in SECURITY-TASK7-SUMMARY.md

### Wave 3: Documentation & Consistency (LOW-MEDIUM PRIORITY)
- [ ] #83 - Fix markdown formatting in TASKS-REMAINING.md
- [ ] #84 - Add Classic PAT requirement explanation
- [ ] #85 - Fix inconsistent permission matrix
- [ ] #88 - Fix escaped backticks in CONFLICT-DETECTION.md
- [ ] #97 - Fix incorrect YAML conditional syntax in PAT-SETUP-GUIDE.md
- [ ] #100 - Add multi-secret example to documentation
- [ ] #105 - Add validate_json_string documentation
- [ ] #108 - Document trap conflict limitations
- [ ] #76 - Improve logging consistency in network.sh
- [ ] #77 - Improve eval alternatives documentation style
- [ ] #68 - Improve secure temp file documentation clarity

### Wave 4: Non-Essential (LOW PRIORITY)
- [ ] #79 - Consolidated cosmetic and documentation improvements (7 sub-items)
- [ ] #69 - Remove redundant return statement

### Legacy Issues (EVALUATE FOR DEFERRAL)
- [ ] #1 - Testing Infrastructure Foundation (Task #13)
- [ ] #4 - Architecture: Resilience & Error Handling (Tasks #9-#12)
- [ ] #5 - Testing: Comprehensive Test Coverage (Tasks #14-#17)
- [ ] #6 - Network & Performance: Timeouts, Monitoring, Auto-Refresh (Tasks #18-#20)
- [ ] #7 - Feature: Protected Branch Auto-Fix Support (Task #8)
- [ ] #27 - [Tech Debt] PR #8: Medium Priority Code Review Items
- [ ] #28 - [Tech Debt] PR #9: Medium Priority Code Review Items
- [ ] #29 - [Tech Debt] PR #10: Medium Priority Code Review Items

**Total Active Issues:** 36 (Critical: 1, Wave 1: 8, Wave 2: 14, Wave 3: 11, Wave 4: 2)
**Legacy Issues for Evaluation:** 8

---

## Success Criteria

### Project Completion

- [ ] All 36 active issues resolved OR properly deferred with justification
- [ ] All tests passing in CI/CD pipeline
- [ ] No CRITICAL or HIGH priority issues remain open
- [ ] Self-hosted runners operational with monitoring
- [ ] Code quality metrics improved or maintained
- [ ] Documentation complete and accurate
- [ ] Legacy issues evaluated and either resolved or formally deferred

### Quality Gates

- [ ] Test coverage >= baseline (maintained or improved)
- [ ] No new bugs introduced (validated through testing)
- [ ] Code review completed for all changes
- [ ] Security-sensitive changes peer-reviewed
- [ ] Documentation reviewed for accuracy

### Process Success

- [ ] Evaluation completed after each wave
- [ ] Lessons learned documented
- [ ] Metrics tracked and analyzed
- [ ] Process improvements identified and documented
- [ ] Velocity data captured for future planning

### Repository Health

- [ ] CI/CD pipeline fully functional
- [ ] All workflows completing successfully
- [ ] No technical debt introduced
- [ ] Clear path forward for legacy issues
- [ ] Repository ready for next phase of development

---

## Progress Tracking

**Last Updated:** 2025-10-27

### Wave Status
| Wave | Status | Issues Complete | Issues Total | % Complete |
|------|--------|-----------------|--------------|------------|
| Critical Path | Not Started | 0 | 1 | 0% |
| Wave 1 | Waiting | 0 | 8 | 0% |
| Wave 2 | Waiting | 0 | 14 | 0% |
| Wave 3 | Waiting | 0 | 11 | 0% |
| Wave 4 | Waiting | 0 | 2 | 0% |

**Overall Progress:** 0/36 issues complete (0%)

### Blockers
- #92 (Self-hosted runners) - ACTIVE BLOCKER

### Next Actions
1. Resolve #92 immediately (install self-hosted runners)
2. Validate runner functionality
3. Begin Wave 1 execution
4. Update this issue with daily progress

---

## References

- All issues: #76-#109, #1, #4-#7, #27-#29, #68-#69
- Critical blocker: #92
- Consolidated issues: #78 (5 sub-items), #79 (7 sub-items)
- Runner installation guide: `docs/runner-installation-guide.md`
- Investigation report: `.claude/investigation-ai-pr-review-hanging.md`

---

**Orchestration Owner:** Development Team
**Created:** 2025-10-27
**Target Completion:** 5-7 business days from #92 resolution
