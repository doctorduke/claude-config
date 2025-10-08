---

## 🔄 MODE SHIFT: Orchestration Loop Enabled

**From this point forward**, manage the discussion above using multi-agent orchestration:

### Orchestration Instructions

1. **Synthesize the problem** from our conversation so far
2. **Define execution phases** with clear dependencies
3. **Spawn specialized subagents** for each task
4. **Validate outputs** before proceeding
5. **Handle errors autonomously** (analyze → retry → escalate)
6. **Create state markers** in `.task-state/` for resumability
7. **Pause only when user input is required**

### Operational Loop

Execute this loop until the task is complete:

```
1. Analyze Problem
   ├─ Review conversation history above
   ├─ Extract core requirements and constraints
   ├─ Break into logical phases
   └─ Identify dependencies and parallel opportunities

2. Detect Current State
   ├─ Check for .task-state/phase-*.complete markers
   ├─ If found: Resume from last incomplete phase
   └─ If none: Start from phase 0

3. Execute Phases
   For each remaining phase:
     ├─ User required? → Pause and notify user
     ├─ Execute tasks:
     │   ├─ Parallel: Spawn multiple agents simultaneously
     │   └─ Sequential: Spawn agents one-by-one
     ├─ Validate outputs
     ├─ On failure:
     │   ├─ Spawn error-detective agent
     │   ├─ If recoverable → apply fixes & retry (max 3)
     │   └─ If not → notify user & pause
     └─ Mark phase complete → continue

4. Report Progress
   ├─ Show status after each phase
   ├─ Explain error recovery attempts
   └─ Indicate when user validation needed
```

### State Tracking

**Markers** (created after validation):
```
.task-state/
  ├── phase-{N}-{name}.complete    # JSON with metadata
  └── errors.log                    # Error history
```

**Resumability**:
- Can pause/resume at any time
- State preserved across sessions
- No context loss

### Agent Selection

Use specialized agents from 151 available types:

**Development**: typescript-pro, python-pro, rust-pro, golang-pro
**Debugging**: debugger, error-detective, concurrency-debugger
**Testing**: test-automator, performance-qa, security-tester
**Docs**: docs-architect, api-documenter, tutorial-engineer
**Arch**: backend-architect, cloud-architect, frontend-developer

**Full registry**: `docs/agent-coordination/BRIEF.md` and `.claude/agents/`

### Error Recovery

When errors occur:
1. **Capture**: Error message, context, phase info
2. **Analyze**: Spawn error-detective agent for root cause
3. **Decide**:
   - Recoverable (confidence > 0.7) → Apply fixes & retry
   - Not recoverable OR retries exhausted → Escalate to user
4. **Report**: Clear explanation of decision

### Task Definition

For each task spawned:
```typescript
{
  agent: 'agent-type',              // Specialized subagent
  input: {                          // Context
    files: ['path/to/file'],
    context: {},
    references: ['docs/']
  },
  task: 'Clear instruction',        // What to do
  output: 'Expected deliverable',   // What to produce
  successCriteria: {                // How to validate
    type: 'file_exists' | 'command_succeeds' | 'test_passes' | 'custom',
    command: 'npm run build',
    files: ['dist/']
  }
}
```

### Parallel Execution

**When to parallelize**:
- ✅ Independent tasks (different files/modules)
- ✅ No data dependencies
- ✅ Different agents/resources
- ❌ Sequential dependencies
- ❌ Same file modifications

**Pattern**:
```typescript
// Spawn all agents simultaneously
const results = await Promise.allSettled([
  spawnAgent('typescript-pro', task1),
  spawnAgent('test-automator', task2),
  spawnAgent('docs-architect', task3)
]);
```

### Configuration

Apply these defaults (override if needed):
```yaml
mode: autonomous                    # Minimize user interruption
parallel_limit: 6                  # Max concurrent agents
retry_limit: 3                     # Max retries per phase
error_threshold: 0.7               # Confidence to retry (0-1)
state_dir: .task-state             # State marker location
```

### Integration with BRIEF

Map orchestration to work items:
```markdown
## Work State

**Doing**
- [MOD-XXX] {Task from conversation} (orchestration active)
  - State: .task-state/phase-N-{name}.complete
  - Current: Phase N+1 in progress
```

### Best Practices

**Do**:
- ✅ Define clear phase boundaries
- ✅ Use parallel execution for independent work
- ✅ Create detailed error context
- ✅ Preserve state markers for resumability
- ✅ Batch user validation points

**Don't**:
- ❌ Create monolithic phases (split into smaller units)
- ❌ Skip validation (always verify before marking complete)
- ❌ Swallow errors (always analyze and report)
- ❌ Block on user input mid-automation (batch user tasks)

### Examples from This Conversation

**Task synthesis** (based on our discussion):
{task}

**Suggested phases** (analyze conversation to determine):
- Phase 0: Preparation
- Phase 1: Setup
- Phase 2: Implementation
- Phase 3: Testing
- Phase 4: Documentation
- Phase 5: User validation

### Commands

**Start fresh**:
```bash
rm -rf .task-state/    # Clear state, start from phase 0
```

**Resume** (automatic):
```bash
# Just run /orchestrate-append again
# Auto-detects last completed phase
```

**Skip to phase** (manual):
```bash
echo '{"forced": true}' > .task-state/phase-2-setup.complete
# Will start from phase 3
```

---

**BEGIN ORCHESTRATION NOW**

1. Review the conversation above
2. Synthesize the task and requirements
3. Define execution phases
4. Check for existing .task-state/ markers
5. Execute orchestration loop
6. Report progress after each phase

Start by showing your phase plan and current state detection.
