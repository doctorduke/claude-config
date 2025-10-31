Principle (Meta & Agents)
- Use a meta-approach to plan and execute work efficiently, employing distributed, specialized agents for distinct tasks.
- Assume access to a broad skills toolkit to support planning and execution.

Parallel Execution Protocol
- CRITICAL RULE: For ALL independent tasks, bundle ALL agent invocations into a SINGLE message. No exceptions.
- DO NOT create artificial batches or "waves" for organizational purposes - if tasks are independent, launch them ALL at once.
- ONLY use sequential execution when there are TRUE dependencies (e.g., Task B cannot start until Task A completes).
- Before launching agents, confirm your execution plan: How many total tasks? How many are independent (launch together)? How many batches due to real dependencies?
- You can launch orchestration agents that report to you what agents they need created. You can perceive the loop that would be taken of an agent that is orchestrating other agents because you perform it. You can derive how it would need to communicate its information to you and how you would need to adapt your inputs and outputs to be compatible. Not just compatible but optimal.

Git Workflow & Persistence
- Use git worktrees dedicated to each agent’s scope; agents should resume from prior state in their own worktree.
- After successful work, commit frequently and use commit logs for memory, review, and information sharing with other agents and users.
- Use git logs as the persistent communication channel across sessions.

Testing & Definition of Done
- No test, no done: every code, configuration, or script task requires tests that validate behavior in the intended system and behavior set.

Collaboration via Pull Requests
- For larger orchestrated tasks, leverage PRs to gather feedback and iterate after the first pass until completion.
- When pushing updates to PR branches, always add a comment to the PR discussion detailing the concerns addressed and their resolutions.
- When pushing updates to PR branches, always close your final comment with "/gemini review", unquoted, to trigger a review by gemini.

Review Convergence Assessment
- After each review response, classify fixes: Critical > Functional > Defensive > Cosmetic.
- Recommend merge when review yields only Defensive + Cosmetic issues and core functionality is proven.
- State explicitly: ready for merge vs. continue iteration, with impact rationale.
- Determine if these are nitpicks or are appropriate to address.
- Address problematic issues.
- If nitpicks, new issues should be created and noted in comment.

Agent Completion & Dependencies
- Agents signal completion via git commits in their worktrees.
- Sequential dependencies (e.g., dev→tester→architect→reviewer) should ONLY be used when truly required.
- Example of TRUE dependency: "Review" agent cannot start until "Implementation" agent finishes.
- Example of FALSE dependency: Implementing 8 independent features does NOT require sequential execution - launch all 8 at once.
- When in doubt, assume tasks are independent and can run in parallel.

Parallel Execution Examples
CORRECT ✅ - Launch all at once:
  Task("Implement Issue #24") +
  Task("Implement Issue #25") +
  Task("Implement Issue #26") +
  Task("Implement Issue #27") +
  Task("Implement Issue #28")
  → All in ONE message with 5 Task calls

INCORRECT ❌ - Artificial batching:
  Message 1: Task("Implement Issue #24") + Task("Implement Issue #25")
  Wait...
  Message 2: Task("Implement Issue #26") + Task("Implement Issue #27")
  Wait...
  Message 3: Task("Implement Issue #28")
  → Wastes time waiting between batches for no reason

CORRECT ✅ - Sequential when truly dependent:
  Message 1: Task("Implement feature X")
  Wait for completion...
  Message 2: Task("Test feature X")
  Wait for completion...
  Message 3: Task("Fix bugs found in testing")
  → Each step depends on previous completion

Optional clarifications (non-binding): Teams may define a naming convention for worktrees and a minimal commit message template (e.g., type(scope): summary | context | next-steps) to enhance cross-agent comprehension.

Metrics and Planning
- We never use time as a metric. We use output and progress to project how long a task will take.

Issue Grooming Process
We need a grooming of our open Issues. We need to know what should still be open and what is valid work. We need to rank them in order of amount of scope to implement. Which means we will need to understand what is required to implement them. Are any of the open issues preventing us from progressing safely with utiliziation? Have we conducted full run throughs by actually executing the trigger?

Grooming Strategy
- Gap Analysis First: Create comprehensive report before executing changes.
- Replace vs Update: Create new well-documented issues rather than updating poorly documented ones.
- Consolidation Pattern: Group cosmetic/defensive items with "non-essential" label.
- Workflow Verification: Validate triggers reveal infrastructure issues (e.g., missing runners).
- Parallel Execution: Run all independent analysis/remediation tasks simultaneously.

Grooming Execution Flow
Batch 1 (Parallel): Analysis + Investigation
├─ Fetch all open issues
├─ Analyze validity and scope
├─ Identify duplicates
├─ Identify blockers
└─ Verify workflow triggers (critical for infrastructure gaps)

Batch 2 (Parallel): Remediation
├─ Investigate critical issues
├─ Create consolidated non-essential issue
├─ Close test artifacts
├─ Close duplicates
└─ Create new well-documented issues

Batch 3 (Parallel): Cleanup
├─ Close old parent issues
└─ Close duplicate consolidations

Batch 4 (Sequential): Documentation
├─ Evaluate process effectiveness
└─ Update grooming instructions

Issue Classification
- Critical: Blockers, infrastructure gaps, security issues
- Functional: Features, enhancements, bug fixes
- Defensive: Error handling, edge cases, validation
- Cosmetic: Formatting, naming, comments (consolidate with "non-essential" label)
