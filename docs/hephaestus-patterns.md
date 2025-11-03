# Hephaestus Pattern Extraction & Lightweight Implementation Guide

## Executive Summary

This document extracts key architectural patterns from the Hephaestus project (https://github.com/Ido-Levi/Hephaestus) and designs lightweight TypeScript equivalents that can integrate with our existing system without requiring tmux, FastAPI, or Qdrant dependencies.

## Pattern 1: Dynamic Workflow Pattern

### Core Concept
Agents dynamically discover and create tasks as they work, rather than following predetermined plans. This enables self-adapting workflows that expand based on what agents find during execution.

### How Hephaestus Implements It
- Agents create tasks via MCP server endpoints during execution
- Tasks are enriched by LLM based on accumulated context
- New agents spawn in tmux sessions for each task
- Parent-child task relationships tracked in SQLite

### Lightweight Implementation Design
```typescript
interface DynamicTask {
  id: string;
  description: string;
  parentTaskId?: string;
  phaseId: string;
  discoveredBy: string;
  context: string[];
  status: 'pending' | 'in_progress' | 'completed';
}

class DynamicWorkflowManager {
  // Use TodoWrite tool as task store
  async createDiscoveredTask(
    description: string,
    context: string[],
    parentTask?: string
  ): Promise<DynamicTask> {
    // Enrich with OpenAI API instead of custom LLM interface
    const enriched = await this.enrichTaskWithContext(description, context);

    // Store in TodoWrite format
    await TodoWrite({
      todos: [...existingTodos, {
        content: enriched.description,
        activeForm: `Investigating: ${enriched.description}`,
        status: 'pending'
      }]
    });

    return enriched;
  }
}
```

### Integration Points
- TodoWrite tool for task management (replaces SQLite task tracking)
- OpenAI API for task enrichment (replaces custom LLM provider)
- Git commits as persistent state (replaces tmux sessions)

## Pattern 2: Semantic Ticket System

### Core Concept
Detect duplicate tasks using vector embeddings to prevent redundant work across parallel agents. Tasks with high semantic similarity are flagged or merged.

### How Hephaestus Implements It
- Generates embeddings for all task descriptions
- Stores vectors in Qdrant database
- Compares new tasks against existing using cosine similarity
- Configurable thresholds for duplicate detection (0.85) and related tasks (0.7)

### Lightweight Implementation Design
```typescript
interface TaskEmbedding {
  taskId: string;
  vector: number[];
  description: string;
  phaseId: string;
}

class SemanticDuplicateDetector {
  private embeddings: Map<string, TaskEmbedding> = new Map();

  async checkDuplicate(description: string, phaseId: string): Promise<{
    isDuplicate: boolean;
    duplicateOf?: string;
    relatedTasks: string[];
  }> {
    // Use OpenAI embeddings API
    const embedding = await openai.embeddings.create({
      model: "text-embedding-3-small",
      input: description,
    });

    const vector = embedding.data[0].embedding;

    // Compare with existing embeddings in-memory
    const similarities = this.calculateSimilarities(vector, phaseId);

    return {
      isDuplicate: similarities.max > 0.85,
      duplicateOf: similarities.max > 0.85 ? similarities.maxId : undefined,
      relatedTasks: similarities.filter(s => s.score > 0.7).map(s => s.id)
    };
  }

  private cosineSimilarity(a: number[], b: number[]): number {
    // Simple cosine similarity calculation
    const dotProduct = a.reduce((sum, val, i) => sum + val * b[i], 0);
    const magnitudeA = Math.sqrt(a.reduce((sum, val) => sum + val * val, 0));
    const magnitudeB = Math.sqrt(b.reduce((sum, val) => sum + val * val, 0));
    return dotProduct / (magnitudeA * magnitudeB);
  }
}
```

### Integration Points
- OpenAI Embeddings API (replaces Qdrant)
- In-memory vector storage for session (or JSON file persistence)
- Integrates with TodoWrite to prevent duplicate todos

## Pattern 3: Guardian Monitoring

### Core Concept
Intelligent monitoring that builds accumulated context from agent sessions, tracks persistent constraints, detects trajectory drift, and provides targeted interventions.

### How Hephaestus Implements It
- Guardian analyzes agent output using trajectory thinking
- Tracks agent phases: exploration, planning, implementation, verification
- Detects patterns: stuck, drifting, violating constraints, over-engineering
- Provides LLM-powered steering interventions via tmux messages

### Lightweight Implementation Design
```typescript
interface AgentTrajectory {
  agentId: string;
  phase: 'exploration' | 'planning' | 'implementation' | 'verification';
  accumulatedContext: string[];
  constraints: string[];
  steeringHistory: SteeringIntervention[];
}

class GuardianMonitor {
  private trajectories: Map<string, AgentTrajectory> = new Map();

  async analyzeAgentOutput(
    agentId: string,
    output: string
  ): Promise<SteeringDecision> {
    const trajectory = this.trajectories.get(agentId) || this.initTrajectory(agentId);

    // Use OpenAI to analyze trajectory
    const analysis = await openai.chat.completions.create({
      model: "gpt-4-turbo-preview",
      messages: [
        {
          role: "system",
          content: this.getGuardianPrompt(trajectory)
        },
        {
          role: "user",
          content: `Analyze this agent output: ${output}`
        }
      ]
    });

    return this.parseSteeringDecision(analysis);
  }

  private getGuardianPrompt(trajectory: AgentTrajectory): string {
    return `You are monitoring an agent in ${trajectory.phase} phase.
      Accumulated context: ${trajectory.accumulatedContext.join('\n')}
      Active constraints: ${trajectory.constraints.join('\n')}

      Detect if agent is: stuck, drifting, violating constraints, over-engineering.
      Provide steering if needed.`;
  }
}
```

### Integration Points
- Git log as persistent communication channel
- Console output monitoring instead of tmux
- Comment-based interventions in code files

## Pattern 4: Phase-Based Coordination

### Core Concept
Organize work into logical phases (Analysis → Implementation → Validation) that provide structure while maintaining agent autonomy. Each phase has clear completion criteria and outputs.

### How Hephaestus Implements It
- Phase definitions in YAML with descriptions, done definitions, outputs
- Phase manager tracks executions and transitions
- Tasks tagged with phase_id to scope duplicate detection
- Validation phase for quality control

### Lightweight Implementation Design
```typescript
interface PhaseDefinition {
  id: string;
  name: string;
  description: string;
  doneDefinitions: string[];
  outputs: string[];
  nextPhases: string[];
}

class PhaseCoordinator {
  private phases: Map<string, PhaseDefinition> = new Map();
  private currentPhase: string = 'analysis';

  async transitionPhase(
    fromPhase: string,
    completedOutputs: string[]
  ): Promise<string> {
    const phase = this.phases.get(fromPhase);

    // Check done definitions
    const isDone = await this.verifyDoneDefinitions(phase, completedOutputs);

    if (isDone) {
      // Determine next phase based on outputs
      const nextPhase = this.selectNextPhase(phase, completedOutputs);
      this.currentPhase = nextPhase;

      // Update TodoWrite with phase transition
      await this.updateTodosForPhase(nextPhase);

      return nextPhase;
    }

    return fromPhase; // Stay in current phase
  }

  private async updateTodosForPhase(phaseId: string): Promise<void> {
    const phase = this.phases.get(phaseId);
    // Create phase-specific todos
    const phaseTodos = phase.outputs.map(output => ({
      content: `[${phase.name}] ${output}`,
      activeForm: `Working on ${output}`,
      status: 'pending' as const
    }));

    await TodoWrite({ todos: phaseTodos });
  }
}
```

### Integration Points
- Phase definitions in TypeScript/JSON (simpler than YAML)
- TodoWrite tracks phase-specific tasks
- Git branches for phase isolation

## Pattern 5: Git Worktree Management

### Core Concept
Isolate agent work in separate git worktrees to enable parallel execution without conflicts. Each agent gets its own branch and workspace.

### How Hephaestus Implements It
- Creates worktree per agent with unique branch
- Tracks parent-child relationships for dependent tasks
- Auto-saves progress with periodic commits
- Handles merge conflicts with timestamp-based resolution
- Cleans up worktrees after task completion

### Lightweight Implementation Design
```typescript
interface WorktreeInfo {
  agentId: string;
  branchName: string;
  worktreePath: string;
  parentCommit: string;
  status: 'active' | 'merged' | 'abandoned';
}

class LightweightWorktreeManager {
  private worktrees: Map<string, WorktreeInfo> = new Map();

  async createWorktree(taskId: string): Promise<WorktreeInfo> {
    const branchName = `task/${taskId}-${Date.now()}`;
    const worktreePath = `./worktrees/${taskId}`;

    // Create worktree with git commands
    await exec(`git worktree add -b ${branchName} ${worktreePath}`);

    const info: WorktreeInfo = {
      agentId: taskId,
      branchName,
      worktreePath,
      parentCommit: await this.getCurrentCommit(),
      status: 'active'
    };

    this.worktrees.set(taskId, info);
    return info;
  }

  async mergeWorktree(taskId: string): Promise<void> {
    const info = this.worktrees.get(taskId);
    if (!info) return;

    // Simple merge strategy
    await exec(`git checkout main`);
    await exec(`git merge --no-ff ${info.branchName}`);

    // Cleanup
    await exec(`git worktree remove ${info.worktreePath}`);
    await exec(`git branch -d ${info.branchName}`);

    info.status = 'merged';
  }
}
```

### Integration Points
- Native git commands via child_process
- Simplified conflict resolution (no complex timestamp logic)
- Works with existing git workflow

## Implementation Recommendations

### Priority 1: Core Patterns (Week 1)
1. **Dynamic Workflow Pattern** - Essential for task discovery
2. **Phase-Based Coordination** - Provides necessary structure

### Priority 2: Quality Control (Week 2)
3. **Semantic Ticket System** - Prevents duplicate work
4. **Guardian Monitoring** - Ensures agents stay on track

### Priority 3: Scale & Isolation (Week 3)
5. **Git Worktree Management** - Enables true parallel execution

### Technology Mapping

| Hephaestus Component | Our Lightweight Alternative |
|---------------------|---------------------------|
| FastAPI Server | Direct TypeScript functions |
| Qdrant Vector DB | In-memory embeddings + OpenAI API |
| tmux Sessions | Child processes or async functions |
| SQLite | TodoWrite tool + JSON files |
| Custom LLM Provider | OpenAI API directly |
| MCP Server | Function calls in TypeScript |

### Risk Assessment

#### Licensing (LOW RISK)
- Patterns and concepts are not copyrightable
- Our implementation uses completely different tech stack
- No code is being copied, only architectural concepts

#### Complexity (MEDIUM RISK)
- Simplified versions may lose some robustness
- Need careful testing of edge cases
- May need to add complexity back for production use

#### Integration (LOW RISK)
- Designed to work with existing tools
- Incremental adoption possible
- Each pattern can work independently

### Key Insights from Hephaestus

1. **Trajectory Thinking**: The Guardian's approach of maintaining accumulated context and detecting drift is more sophisticated than simple health checks.

2. **Semantic Deduplication**: Using embeddings for duplicate detection is more robust than string matching and catches conceptually similar tasks.

3. **Phase Boundaries**: Phases provide structure without rigidity - agents can still discover unexpected work within phase constraints.

4. **Worktree Isolation**: Complete file system isolation prevents subtle conflicts that process isolation alone cannot.

5. **Self-Healing**: The combination of Guardian monitoring and Conductor orchestration creates a self-correcting system.

### Next Steps

1. **Prototype Phase 1**: Implement Dynamic Workflow Pattern with TodoWrite
2. **Test Integration**: Verify compatibility with workflow-builder-framework skill
3. **Gradual Rollout**: Start with single-agent workflows, then expand to parallel
4. **Monitor & Iterate**: Use learnings to refine implementations

## Conclusion

The Hephaestus patterns provide valuable architectural insights for building self-adapting, parallel agent systems. Our lightweight TypeScript implementations preserve the core benefits while avoiding heavy dependencies and licensing concerns. The modular approach allows incremental adoption and testing of each pattern independently.