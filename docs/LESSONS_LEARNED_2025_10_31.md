# Lessons Learned: Evaluation System Implementation

**Date**: 2025-10-31
**Session**: Initial evaluation system and Hephaestus pattern implementation
**Outcome**: Successful implementation with critical security issues discovered

---

## Executive Summary

Successfully implemented 3-tier evaluation system and 5 Hephaestus workflow patterns. However, made several critical mistakes that delayed deployment and created security vulnerabilities. This document captures what went wrong and how to prevent similar issues in future development.

---

## Critical Mistakes Made

### 1. Security Review Too Late ⚠️

**What Happened:**
- Implemented worktree management with shell command execution
- Pushed code to PR without security review
- Gemini Code Assist found critical command injection vulnerabilities
- Had to fix after PR creation

**Impact:**
- PR #12 blocked from merging
- Rework required after code already written
- Lost development time

**Root Cause:**
- No security-auditor agent used during implementation
- Assumed TypeScript would prevent security issues
- Didn't consider shell command injection risks

**Prevention:**
```typescript
// Before implementing ANY code with shell commands:
Task(security-auditor, "Review design for shell command security")

// During implementation:
Task(typescript-pro, "Implement worktree helpers")
→ Task(security-auditor, "Audit worktree-helpers.ts")
→ Fix vulnerabilities BEFORE pushing

// Use spawn() with arrays, never exec() with strings:
// ❌ BAD
await exec(`git checkout "${userInput}"`);

// ✅ GOOD
import { spawn } from 'child_process';
await spawn('git', ['checkout', userInput]);
```

**New Rule:**
- security-auditor agent is MANDATORY for any code involving:
  - Shell commands
  - File operations with user input
  - Subprocess execution
  - API calls with user data

---

### 2. Pull Requests Too Large

**What Happened:**
- PR #12: 2,562 lines across 17 files
- Bundled 5 separate patterns into one PR
- Too large for effective review
- Difficult to iterate on feedback

**Impact:**
- Review comments harder to address
- Longer review cycle
- More merge conflicts

**Root Cause:**
- Didn't consider reviewer cognitive load
- Optimized for implementation speed over review speed
- Assumed larger PR = faster overall delivery

**Prevention:**
```
Instead of 1 massive PR:
PR #12: Hephaestus Patterns (2,562 lines)

Create 5 focused PRs:
PR #12a: Dynamic Workflow Discovery (300 lines) ✅
PR #12b: Semantic Deduplication (350 lines) ✅
PR #12c: Guardian Monitoring (400 lines) ✅
PR #12d: Phase Coordination (450 lines) ✅
PR #12e: Worktree Helpers (450 lines) ✅
```

**New Rule:**
- Maximum 500 lines of code per PR (excluding tests/docs)
- One module/pattern per PR
- Easier review = faster overall delivery

---

### 3. Parallel Branches Without Coordination

**What Happened:**
- Created 5 worktrees in parallel
- All modified shared files (package.json, tsconfig.json)
- Result: 18 conflicting files in PR #12

**Impact:**
- Merge conflicts blocked PR
- Had to manually resolve conflicts
- Wasted time on conflict resolution

**Root Cause:**
- Didn't coordinate shared file changes across branches
- Optimized for parallel execution without considering overlap
- No merge-conflict-mediator agent used proactively

**Prevention:**
```
Strategy 1: Sequential Merging
1. Merge foundational PR first (custom-eval-framework)
2. Rebase dependent PRs on updated development
3. Merge incrementally
4. Each merge updates shared files for next PR

Strategy 2: File Ownership
- Assign each PR exclusive file ownership
- Shared files get merged in first PR only
- Subsequent PRs rebase on updated shared files

Strategy 3: Use merge-conflict-mediator BEFORE PRs
Task(merge-conflict-mediator, "Check conflicts before creating PR #12")
```

**New Rule:**
- Use merge-conflict-mediator agent BEFORE creating PRs
- Sequential merging for overlapping changes
- Coordinate shared file modifications

---

### 4. No Internal Agent Review Before PR

**What Happened:**
- Implemented code with typescript-pro agent
- Created PR immediately
- External review (Gemini) found issues
- Should have caught internally

**Impact:**
- Issues discovered late
- Rework after PR creation
- Looks unprofessional to external reviewers

**Root Cause:**
- Didn't use available review agents
- Assumed implementation agent would catch all issues
- No quality gate before pushing

**Prevention:**
```
Required Review Pipeline:
1. typescript-pro → Implement
2. security-auditor → Review for vulnerabilities
3. code-reviewer → Review for quality
4. architect-review → Validate patterns
5. test-automator → Validate tests
6. THEN create PR

Example:
Task(typescript-pro, "Implement worktree helpers")
→ Task(security-auditor, "Audit for vulnerabilities")
→ Task(code-reviewer, "Review code quality")
→ Task(architect-review, "Validate pattern usage")
→ Push and create PR (already reviewed)
```

**New Rule:**
- Internal agent review is MANDATORY before any PR
- External review should find zero critical issues
- Quality gate: 4 agent approvals minimum

---

### 5. Chose Paid Service Without Checking

**What Happened:**
- Initially chose Braintrust for TypeScript evaluation
- Assumed "open source" = "free"
- Discovered it's a paid SaaS service
- Had to completely rework (Issue #7)

**Impact:**
- Wasted implementation time
- Had to rebuild from scratch
- Delayed delivery by 1 day

**Root Cause:**
- Didn't research pricing model before implementation
- Didn't ask user about budget constraints upfront
- Assumed based on GitHub stars/popularity

**Prevention:**
```
Before choosing ANY framework:
1. Research pricing model (free tier limits, costs)
2. Ask user about budget constraints
3. Prefer zero-SaaS solutions using existing APIs
4. Document decision in ADR with cost analysis

Example ADR:
## Options Considered
- Braintrust: ❌ Paid SaaS ($50+/month minimum)
- LangSmith: ❌ Paid SaaS ($39+/month minimum)
- Custom framework: ✅ Uses existing OpenAI/Claude/Gemini APIs

## Decision
Build custom framework using existing APIs.
Rationale: No additional costs, full control, aligns with user constraints.
```

**New Rule:**
- Always research pricing BEFORE implementation
- Ask about budget constraints in initial planning
- Document cost analysis in ADR

---

### 6. Implementation Before ADR

**What Happened:**
- Wrote code first
- Documented decisions after
- ADRs describe implementation, not design

**Impact:**
- Architectural decisions made implicitly
- No user sign-off on approach
- Harder to change direction after code written

**Root Cause:**
- Optimized for speed
- Assumed implementation would reveal best design
- Didn't value upfront design validation

**Prevention:**
```
Correct Sequence:
1. Create GitHub issue with requirements
2. architect-review creates ADR with 3 options
3. Present ADR to user for approval
4. User selects option
5. typescript-pro implements based on approved ADR
6. Update ADR with "Decision Made" section

Example:
Issue #7: Custom TypeScript Eval Framework
→ architect-review: Create ADR-007 with options (Braintrust vs Custom vs LangSmith)
→ Present to user: "Which approach do you prefer?"
→ User: "Custom, no paid services"
→ typescript-pro: Implement custom framework per ADR-007
→ Update ADR-007: Decision = Custom, Rationale = No additional costs
```

**New Rule:**
- ADR-first development for all significant features
- Get user approval on architecture before coding
- Update ADR with final decision after implementation

---

### 7. No Cost Tracking in Code

**What Happened:**
- Wrote cost analysis document separately
- Estimated costs manually
- No runtime cost tracking built into code

**Impact:**
- Can't validate actual costs match estimates
- No budget enforcement at runtime
- Users might exceed budget unknowingly

**Root Cause:**
- Treated cost analysis as documentation, not feature
- Didn't consider cost as first-class concern
- Assumed estimates would be accurate

**Prevention:**
```typescript
// Build cost tracking into every LLM-calling module:
class GuardianMonitor {
  private costTracker = new CostTracker();

  async checkTrajectory(...) {
    const result = await this.llm.analyze(...);

    // Track cost in real-time
    this.costTracker.record({
      operation: 'guardian_check',
      model: this.llm.model,
      tokens: result.usage,
      cost: calculateCost(result.usage, this.llm.model),
    });

    // Enforce budget
    if (this.costTracker.getDailyCost() > this.budget) {
      throw new Error('Daily budget exceeded');
    }

    return result;
  }

  getCostStats() {
    return this.costTracker.getStats();
  }
}
```

**New Rule:**
- Cost tracking is a FEATURE, not documentation
- Built into code, not estimated externally
- Budget enforcement at runtime

---

### 8. Documentation Written After Implementation

**What Happened:**
- Wrote code first
- Documented API after
- Documentation describes code, not design

**Impact:**
- API design driven by implementation details
- Harder to use (not designed for users)
- Documentation changes when implementation changes

**Root Cause:**
- Standard practice in most development
- Didn't consider documentation-driven development
- Assumed implementation would determine best API

**Prevention:**
```
Documentation-Driven Development:
1. Write README with usage examples FIRST
2. Design API from examples (what feels natural?)
3. Write TypeScript interfaces from API design
4. Implement to match the interface
5. Tests validate the examples work

Example:
// 1. Write README example first:
## Usage
```typescript
const guardian = new GuardianMonitor({ llm: 'claude-haiku' });
await guardian.monitor({ agentId, goal });
```

// 2. Design interface from example:
interface GuardianOptions {
  llm: 'claude-haiku' | 'gpt-3.5-turbo';
}

// 3. Implement to match interface
class GuardianMonitor {
  constructor(options: GuardianOptions) { ... }
  async monitor(config: MonitorConfig) { ... }
}
```

**New Rule:**
- README-first development for all modules
- API design driven by usage examples
- Implementation matches the documented API

---

### 9. Didn't Use Test-Driven Development

**What Happened:**
- Wrote implementation first
- Wrote tests after to validate implementation
- Tests confirm code works, not that it meets requirements

**Impact:**
- Tests coupled to implementation details
- Harder to refactor (tests break)
- Missed edge cases

**Root Cause:**
- Faster to implement without tests
- Assumed implementation = correct behavior
- Didn't value TDD red-green-refactor cycle

**Prevention:**
```typescript
// TDD Red-Green-Refactor:

// 1. RED: Write failing test (defines requirement)
describe('GuardianMonitor', () => {
  it('should detect stuck agent', async () => {
    const guardian = new GuardianMonitor({ llm: 'mock' });
    const result = await guardian.checkTrajectory({
      goal: 'Fix bug',
      progress: ['Started', 'Started', 'Started'], // Stuck!
    });
    expect(result.drift.type).toBe('stuck');
    expect(result.drift.confidence).toBeGreaterThan(0.7);
  });
});

// 2. Run test → It fails (no implementation yet)

// 3. GREEN: Implement just enough to pass
class GuardianMonitor {
  async checkTrajectory(config) {
    // Minimal implementation to pass test
    if (config.progress.every(p => p === config.progress[0])) {
      return { drift: { type: 'stuck', confidence: 0.8 } };
    }
  }
}

// 4. Run test → It passes

// 5. REFACTOR: Improve implementation without breaking test
class GuardianMonitor {
  async checkTrajectory(config) {
    const analysis = await this.llm.analyze(config);
    return { drift: analysis.drift };
  }
}

// 6. Run test → Still passes
```

**New Rule:**
- Use test-driven-development-framework skill
- Write tests BEFORE implementation
- Red-Green-Refactor cycle for all features

---

### 10. No Integration Testing Before PRs

**What Happened:**
- Created 4 separate PRs
- Assumed they'd integrate cleanly
- Didn't test all components together
- Discovered issues after PR creation

**Impact:**
- Integration bugs found late
- Rework after code review
- Delayed deployment

**Root Cause:**
- Tested each module in isolation
- Assumed isolated tests = integrated system works
- No end-to-end validation

**Prevention:**
```bash
# Integration Validation Checklist:
1. Create test project separate from development
2. Install custom-eval-framework from worktree
3. Install deepeval-setup from worktree
4. Install hephaestus-impl from worktree
5. Run complete workflow:
   - Agent writes code
   - Custom eval validates inline
   - Agent commits
   - PR created
   - DeepEval runs in CI
   - Hephaestus patterns coordinate multi-agent work
6. Fix integration issues BEFORE creating PRs
7. THEN create PRs for validated, working code

Use test-automator agent:
Task(test-automator, "Validate integration of all 3 systems before PR creation")
```

**New Rule:**
- Integration tests BEFORE creating PRs
- Test all components together
- Fix integration issues before external review

---

## Process Improvements

### New Development Workflow

**Old (what I did):**
```
Plan → Implement in parallel → Create PRs → Discover issues → Fix
```

**New (what I should do):**
```
1. Plan
2. Write ADRs with options
3. Get user approval on ADR
4. Implement sequentially with internal reviews
   a. typescript-pro implements
   b. security-auditor reviews
   c. code-reviewer validates
   d. architect-review checks patterns
5. Integration test all components
6. Create PRs for validated code
7. External review finds minimal issues
8. Quick merge
```

### Agent Review Pipeline

**For ANY code before pushing:**
```typescript
// 1. Implementation
Task(typescript-pro, "Implement feature X")

// 2. Security review (MANDATORY for shell/file/subprocess operations)
Task(security-auditor, "Audit for vulnerabilities")

// 3. Quality review
Task(code-reviewer, "Review code quality and patterns")

// 4. Architecture validation
Task(architect-review, "Validate architectural decisions")

// 5. Test validation
Task(test-automator, "Ensure test coverage and quality")

// 6. Integration validation (if multiple components)
Task(test-automator, "Validate integration with existing systems")

// 7. THEN create PR
```

### PR Size Guidelines

**Maximum PR size:**
- Code: 500 lines
- Tests: No limit
- Documentation: No limit
- Total: Prefer <1,000 lines total

**How to split large features:**
```
Feature: Hephaestus Patterns (2,562 lines)

Split into:
- PR #1: Types and interfaces (100 lines)
- PR #2: Dynamic Discovery (300 lines)
- PR #3: Semantic Dedup (350 lines)
- PR #4: Guardian (400 lines)
- PR #5: Phases (450 lines)
- PR #6: Worktrees (450 lines)
- PR #7: Integration tests (500 lines)

Each PR builds on previous, mergeable independently.
```

### Cost Tracking Standards

**All LLM-calling code must include:**
1. Real-time cost tracking via CostTracker
2. Budget enforcement at runtime
3. Cost stats API for monitoring
4. Daily/weekly/monthly cost reports

**Example template:**
```typescript
class MyLLMService {
  private costTracker = new CostTracker();
  private budget: number;

  constructor(options: { budget: number }) {
    this.budget = options.budget;
  }

  async callLLM(input: string): Promise<string> {
    const result = await this.llm.generate(input);

    const cost = calculateCost(result.usage, this.llm.model);
    this.costTracker.record({
      operation: 'generate',
      model: this.llm.model,
      tokens: result.usage,
      cost,
    });

    if (this.costTracker.getDailyCost() > this.budget) {
      throw new Error(`Daily budget ${this.budget} exceeded`);
    }

    return result.output;
  }

  getCostStats() {
    return {
      daily: this.costTracker.getDailyCost(),
      weekly: this.costTracker.getWeeklyCost(),
      monthly: this.costTracker.getMonthlyCost(),
    };
  }
}
```

---

## Security Best Practices

### Command Injection Prevention

**NEVER do this:**
```typescript
// ❌ Command injection vulnerability
const userInput = req.body.branch;
await exec(`git checkout "${userInput}"`);

// Attack: userInput = '"; rm -rf /; echo "'
// Results in: git checkout ""; rm -rf /; echo ""
```

**ALWAYS do this:**
```typescript
// ✅ Safe: spawn with argument array
import { spawn } from 'child_process';

const userInput = req.body.branch;
await spawn('git', ['checkout', userInput]);

// spawn executes: git checkout [userInput as single argument]
// Shell metacharacters are treated as literal text, not commands
```

### Path Traversal Prevention

**NEVER do this:**
```typescript
// ❌ Path traversal vulnerability
const taskId = req.body.taskId;
const worktreePath = path.join(baseDir, taskId);

// Attack: taskId = "../../../etc/passwd"
// Results in: /etc/passwd
```

**ALWAYS do this:**
```typescript
// ✅ Safe: sanitize and validate
function sanitizeTaskId(taskId: string): string {
  // Remove path separators and traversal sequences
  const sanitized = taskId.replace(/[\/\\\.]/g, '-');

  // Validate format
  if (!/^[a-zA-Z0-9_-]+$/.test(sanitized)) {
    throw new Error('Invalid taskId format');
  }

  return sanitized;
}

const taskId = sanitizeTaskId(req.body.taskId);
const worktreePath = path.join(baseDir, taskId);
```

### Input Validation

**Use Zod for all external inputs:**
```typescript
import { z } from 'zod';

const TaskSchema = z.object({
  taskId: z.string().regex(/^[a-zA-Z0-9_-]+$/),
  branch: z.string().regex(/^[a-zA-Z0-9/_-]+$/),
  agentId: z.string().regex(/^[a-zA-Z0-9_-]+$/),
});

// Validate before use
const validated = TaskSchema.parse(req.body);
```

---

## Key Takeaways

### Top 5 Mistakes
1. ❌ Security review too late (should be during, not after)
2. ❌ PRs too large (500 lines max, not 2,500)
3. ❌ Parallel branches without coordination (caused conflicts)
4. ❌ No internal agent review before PR
5. ❌ Implementation-first instead of design-first

### Top 5 Improvements
1. ✅ Use security-auditor PROACTIVELY for shell/file operations
2. ✅ Create ADRs BEFORE implementation
3. ✅ Smaller, focused PRs (<500 lines)
4. ✅ Internal agent review pipeline before pushing
5. ✅ Integration tests BEFORE creating PRs

### Success Metrics

**This session:**
- 6 GitHub issues created and completed
- 4 PRs created (1 with critical security issues)
- ~10,000 lines of code + documentation
- Cost: <$200/month for medium projects

**Future sessions should achieve:**
- Zero critical security issues in PRs
- All PRs <500 lines
- No merge conflicts
- First-pass PR approval (external review finds zero issues)
- Integration validated before PR creation

---

## Conclusion

Despite successful feature delivery, this session revealed critical gaps in development process:
- Security practices
- PR size management
- Integration testing
- Cost tracking

All gaps now documented with prevention strategies. Future development should follow updated CLAUDE.local.md guidelines to avoid repeating these mistakes.

**Next session checklist:**
- [ ] ADR before implementation
- [ ] Internal agent review pipeline
- [ ] Security audit for any shell/file operations
- [ ] PR <500 lines
- [ ] Integration tests before PR
- [ ] Cost tracking built into code
