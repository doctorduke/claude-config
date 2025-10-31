# Multi-Agent Coordination - Implementation Patterns

[← Back to Main](./SKILL.md)

## Table of Contents

- [Pattern 1: LangGraph Supervisor](#pattern-1-langgraph-supervisor)
- [Pattern 2: AutoGen Conversation](#pattern-2-autogen-conversation)
- [Pattern 3: CrewAI Teams](#pattern-3-crewai-teams)
- [Pattern 4: Consensus Voting](#pattern-4-consensus-voting)
- [Pattern 5: Event Sourcing](#pattern-5-event-sourcing)
- [Pattern 6: Lifecycle Management](#pattern-6-lifecycle-management)

## Pattern 1: LangGraph Supervisor

### Overview

Centralized supervisor coordinates multiple specialized agents using graph-based routing.

### When to Use

- Complex workflows with conditional routing
- Need state persistence across agent interactions
- Want to visualize agent flow as a graph
- Require cycle detection and prevention
- Need checkpointing/replay capabilities

### Architecture

```
┌──────────────┐
│  Supervisor  │ (Routes to specialized agents)
└──────┬───────┘
       │
   ┌───┴─────┬────────┬────────┐
   ▼         ▼        ▼        ▼
┌────────┐┌────────┐┌────────┐┌────────┐
│Research││Analyzer││ Writer ││Reviewer│
└────┬───┘└────┬───┘└────┬───┘└────┬───┘
     │         │         │         │
     └─────────┴─────────┴─────────┘
                   │
                   ▼
                 [END]
```

### Key Components

**1. Agent State**
- Shared state passed between agents
- Messages accumulate (operator.add)
- Routing decisions stored in state

**2. Specialized Agents**
- Each agent has focused responsibility
- Agents receive state, return updated state
- System prompts define agent personality

**3. Supervisor Agent**
- Analyzes current state
- Decides which agent should act next
- Returns routing decision

**4. Conditional Routing**
- Route to next agent based on supervisor decision
- Support for cycles (with limits)
- End condition when task complete

### Pros

- Clean separation of concerns
- Visualizable workflow
- State persistence
- Flexible routing logic
- Easy to add new agents

### Cons

- Single point of failure (supervisor)
- Can become bottleneck
- More complex than simple chains
- Supervisor routing logic can be fragile

### Best Practices

1. **Keep agents focused**: Each agent should have one clear responsibility
2. **Limit cycles**: Set max iterations to prevent infinite loops
3. **Validate state**: Check state consistency between agents
4. **Handle errors**: Supervisor should handle agent failures gracefully
5. **Test routing**: Verify supervisor makes correct routing decisions

### Code Example

See [EXAMPLES.md - Example 1](./EXAMPLES.md#example-1-langgraph-supervisor) for complete implementation.

---

## Pattern 2: AutoGen Conversation

### Overview

Conversational multi-agent system with natural dialogue flow and optional human-in-the-loop.

### When to Use

- Conversational/chat-based workflows
- Need human interaction during execution
- Agents should debate/discuss approaches
- Code execution required
- Rapid prototyping of multi-agent systems

### Architecture

```
GROUP CHAT:
┌────────────────┐
│ Group Manager  │
└───────┬────────┘
        │ (Selects speaker)
   ┌────┴─────┬─────────┬──────────┐
   ▼          ▼         ▼          ▼
┌──────┐  ┌──────┐  ┌──────┐  ┌───────┐
│Agent1│  │Agent2│  │Agent3│  │ Human │
└──────┘  └──────┘  └──────┘  └───────┘
```

### Key Components

**1. AssistantAgent**
- AI agent with specific role
- System message defines personality
- Can use tools/functions

**2. UserProxyAgent**
- Can execute code
- Human-in-the-loop interface
- Termination detection

**3. GroupChat**
- Manages conversation between multiple agents
- Speaker selection (auto, round-robin, manual)
- Conversation history tracking

**4. GroupChatManager**
- Orchestrates group chat
- Manages turn-taking
- Enforces max rounds

### Chat Patterns

**Group Chat**: All agents in one conversation
- Good for: Brainstorming, debate, multi-perspective analysis
- Challenge: Keeping conversation focused

**Sequential Chat**: Agents in sequence
- Good for: Workflow stages (PM → Engineer → QA)
- Challenge: No parallelism

**Nested Chat**: Sub-conversations within main conversation
- Good for: Complex tasks requiring sub-teams
- Challenge: Managing conversation depth

### Pros

- Natural conversation flow
- Easy human interaction
- Simple to set up
- Built-in code execution
- Conversation history automatic

### Cons

- Can be chatty (high token usage)
- Conversation can drift off-topic
- Limited parallelism
- Basic state management

### Best Practices

1. **Clear system messages**: Define agent roles explicitly
2. **Termination conditions**: Set clear conversation end points
3. **Max rounds**: Limit conversation length
4. **Speaker selection**: Choose appropriate method (auto/round-robin)
5. **Human override**: Allow human to intervene when needed

### Code Example

See [EXAMPLES.md - Example 2](./EXAMPLES.md#example-2-autogen-conversation) for complete implementation.

---

## Pattern 3: CrewAI Teams

### Overview

Role-based agent teams with task dependencies and sequential/parallel execution.

### When to Use

- Clear role definitions (PM, Engineer, QA, etc.)
- Task dependencies well-defined
- Need sequential or parallel task execution
- Want minimal setup code
- Built-in tool integration needed

### Architecture

```
┌────────────┐
│    Crew    │
└─────┬──────┘
      │
      ├─ Agent: Product Manager (role: PM)
      ├─ Agent: Engineer (role: Developer)
      ├─ Agent: QA (role: Tester)
      │
      └─ Tasks:
          ├─ Define Requirements (→ PM)
          ├─ Implement Feature (→ Engineer, depends on Requirements)
          └─ Test Feature (→ QA, depends on Implementation)
```

### Key Components

**1. Agent**
- Role definition (role, goal, backstory)
- Capabilities and tools
- Delegation permissions

**2. Task**
- Description and expected output
- Assigned agent
- Dependencies (context parameter)

**3. Crew**
- Collection of agents
- Process type (sequential/hierarchical)
- Task execution coordination

**4. Process**
- Sequential: Tasks execute in order
- Hierarchical: Manager delegates to agents

### Task Dependencies

```python
# Task 1: No dependencies
research_task = Task(
    description="Research topic",
    agent=researcher
)

# Task 2: Depends on Task 1
analysis_task = Task(
    description="Analyze research",
    agent=analyzer,
    context=[research_task]  # Waits for research_task
)

# Task 3: Depends on Task 2
report_task = Task(
    description="Write report",
    agent=writer,
    context=[analysis_task]  # Waits for analysis_task
)
```

### Pros

- Clear role separation
- Built-in task dependencies
- Easy to understand
- Good documentation
- Tool integration included

### Cons

- Less flexible than custom
- Limited routing logic
- Still emerging framework
- Less control over execution flow

### Best Practices

1. **Specific roles**: Define clear, non-overlapping roles
2. **Expected outputs**: Specify expected output for each task
3. **Task dependencies**: Use context parameter for dependencies
4. **Delegation wisely**: Only enable delegation when needed
5. **Process selection**: Choose sequential for simple, hierarchical for complex

### Code Example

See [EXAMPLES.md - Example 3](./EXAMPLES.md#example-3-crewai-teams) for complete implementation.

---

## Pattern 4: Consensus Voting

### Overview

Multiple agents vote or reach consensus on decisions using various voting mechanisms.

### When to Use

- Critical decisions need multiple perspectives
- Want to aggregate agent opinions
- Need confidence-weighted decisions
- Byzantine fault tolerance required
- Ensemble predictions for accuracy

### Voting Types

**Simple Majority**: 50% + 1 votes needed
- Use for: General decisions, binary choices
- Pros: Simple, fast
- Cons: Ignores confidence, 51% attack risk

**Weighted Voting**: Votes weighted by confidence/expertise
- Use for: Expert opinions, confidence-based decisions
- Pros: Considers agent expertise
- Cons: Need to set weights carefully

**Supermajority**: Require 2/3 or higher threshold
- Use for: Critical decisions, high-stakes choices
- Pros: Strong consensus, fewer errors
- Cons: Harder to reach consensus

**Unanimous**: All agents must agree
- Use for: Safety-critical decisions
- Pros: Maximum consensus
- Cons: Any agent can block

**Quorum**: Minimum participation required
- Use for: Ensuring sufficient input
- Pros: Prevents decisions with too few agents
- Cons: Can block progress if quorum not met

### Architecture

```
Decision Required
       │
       ▼
┌──────────────────┐
│ Collect Votes    │
└────────┬─────────┘
         │
    ┌────┴────┬────────┬────────┐
    ▼         ▼        ▼        ▼
 ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐
 │Agent│  │Agent│  │Agent│  │Agent│
 │  1  │  │  2  │  │  3  │  │  4  │
 └──┬──┘  └──┬──┘  └──┬──┘  └──┬──┘
    │        │        │        │
    └────────┴────────┴────────┘
              │
              ▼
    ┌──────────────────┐
    │ Consensus Engine │
    └────────┬─────────┘
             │
             ▼
         [Result]
```

### Conflict Resolution

When agents disagree:

**By Expertise**: Trust expert agent
**By Voting**: Majority wins
**By Compromise**: Average/median response
**By Chain-of-Thought**: Strongest reasoning wins

### Pros

- Multiple perspectives
- Byzantine fault tolerance
- Improved accuracy (ensemble)
- Democratic decisions

### Cons

- Coordination overhead
- Can be slow
- Requires multiple agents
- May not converge

### Best Practices

1. **Choose right mechanism**: Match voting type to decision criticality
2. **Track confidence**: Include confidence scores in votes
3. **Explain votes**: Require reasoning with each vote
4. **Detect outliers**: Identify and investigate extreme votes
5. **Iterative consensus**: Allow agents to refine based on others' votes

### Code Example

See [EXAMPLES.md - Example 4](./EXAMPLES.md#example-4-consensus-voting) for complete implementation.

---

## Pattern 5: Event Sourcing

### Overview

Manage shared state as immutable sequence of events that can be replayed to reconstruct state.

### When to Use

- Need complete audit trail
- State reconstruction required
- Time-travel debugging needed
- Distributed state management
- Event-driven architecture

### Architecture

```
┌─────────────┐
│ Agent State │  (Rebuilt from events)
└──────▲──────┘
       │
       │ Replay
       │
┌──────┴─────────────┐
│   Event Store      │
│ ┌────────────────┐ │
│ │ Event 1        │ │ (Immutable log)
│ │ Event 2        │ │
│ │ Event 3        │ │
│ │ ...            │ │
│ └────────────────┘ │
└────────────────────┘
       ▲
       │ Append
       │
┌──────┴──────┐
│   Agents    │
└─────────────┘
```

### Event Types

- **Agent Events**: Registration, updates, removal
- **Task Events**: Assignment, completion, failure
- **State Events**: Global state changes
- **Message Events**: Inter-agent communication

### Key Components

**1. Event**
- Immutable record of what happened
- Includes: event ID, type, agent, timestamp, data

**2. Event Store**
- Append-only log
- Query by agent, type, time
- Replay capability

**3. Shared State**
- Rebuilt from events
- Pure functions (apply_event)
- No direct mutation

**4. State Manager**
- Publishes events
- Provides current state view
- Handles queries

### Event Replay

```
Initial State = {}

Event 1: AgentRegistered(agent_id="A")
State = {agents: {A: {status: "active"}}}

Event 2: TaskAssigned(agent_id="A", task_id="T1")
State = {agents: {A: {...}}, tasks: {T1: {assigned_to: "A"}}}

Event 3: TaskCompleted(agent_id="A", task_id="T1", result={...})
State = {agents: {A: {...}}, tasks: {T1: {status: "completed"}}}
```

### Pros

- Complete history
- State reconstruction
- Time-travel debugging
- Audit trail
- Event-driven

### Cons

- Storage overhead
- Replay can be slow
- More complex than direct state
- Eventual consistency

### Best Practices

1. **Immutable events**: Never modify events after creation
2. **Event versioning**: Support schema evolution
3. **Snapshots**: Periodic state snapshots to speed replay
4. **Idempotency**: Events should be safely replayable
5. **Event IDs**: Unique IDs for deduplication

### Code Example

See [EXAMPLES.md - Example 5](./EXAMPLES.md#example-5-event-sourcing) for complete implementation.

---

## Pattern 6: Lifecycle Management

### Overview

Manage agent registration, health monitoring, auto-scaling, and retirement.

### When to Use

- Dynamic agent pools
- Need health monitoring
- Auto-scaling required
- Long-running agent systems
- Production deployments

### Architecture

```
┌────────────────────┐
│ Agent Registry     │
│ ┌────────────────┐ │
│ │ Agent 1: ⚡    │ │ (Healthy)
│ │ Agent 2: ⚡    │ │ (Healthy)
│ │ Agent 3: ⚠️     │ │ (Degraded)
│ │ Agent 4: ❌    │ │ (Offline)
│ └────────────────┘ │
└──────────┬─────────┘
           │
    ┌──────┴──────┐
    │             │
    ▼             ▼
┌─────────┐  ┌──────────┐
│ Health  │  │  Auto    │
│ Monitor │  │  Scaler  │
└─────────┘  └──────────┘
```

### Key Components

**1. Agent Registry**
- Central agent catalog
- Agent discovery
- Health tracking
- Metrics collection

**2. Health Checker**
- Heartbeat monitoring
- Health scores
- Failure detection

**3. Agent Pool**
- Min/max agent limits
- Scale up/down
- Load balancing

**4. Agent Metrics**
- Tasks completed/failed
- Response times
- Resource usage
- Error rates

### Agent Lifecycle

```
REGISTERED → ACTIVE → BUSY → IDLE → ACTIVE
                ↓
           DEGRADED → OFFLINE → TERMINATED
```

### Health Checks

**Heartbeat**: Periodic check-in
**Error Rate**: Track failures
**Response Time**: Detect slow agents
**Resource Usage**: Monitor CPU/memory

### Auto-Scaling

**Scale Up** when:
- Average load > 70%
- Task queue growing
- Response times increasing

**Scale Down** when:
- Average load < 20%
- Idle agents exist
- Above minimum agents

### Pros

- Dynamic scaling
- Automatic failure detection
- Health monitoring
- Resource optimization

### Cons

- Additional complexity
- Monitoring overhead
- Scale decisions can lag
- Need careful tuning

### Best Practices

1. **Heartbeat interval**: Balance between overhead and detection speed
2. **Graceful shutdown**: Finish tasks before terminating
3. **Health scores**: Use multiple metrics, not just heartbeat
4. **Scale gradually**: Avoid rapid scaling oscillations
5. **Metrics**: Track and visualize agent health

### Code Example

See [EXAMPLES.md - Example 6](./EXAMPLES.md#example-6-lifecycle-management) for complete implementation.

---

## Pattern Selection Guide

### Decision Tree

```
Need graph-based workflow?
├─ Yes → LangGraph Supervisor
└─ No
   └─ Need conversation/debate?
      ├─ Yes → AutoGen Conversation
      └─ No
         └─ Have clear roles?
            ├─ Yes → CrewAI Teams
            └─ No
               └─ Need consensus?
                  ├─ Yes → Consensus Voting
                  └─ No
                     └─ Need state audit trail?
                        ├─ Yes → Event Sourcing
                        └─ No → Lifecycle Management
```

### Complexity vs Control

```
Low Complexity                    High Complexity
High Abstraction                  Low Abstraction
│                                              │
├──────────┬──────────┬──────────┬───────────┤
AutoGen   CrewAI   LangGraph   Event      Custom
                               Sourcing
```

### Use Case Matrix

| Use Case | Recommended Pattern | Alternative |
|----------|---------------------|-------------|
| Code review by specialists | LangGraph Supervisor | CrewAI Teams |
| Chat-based assistance | AutoGen Conversation | Custom |
| Multi-stage pipeline | CrewAI Teams | LangGraph |
| Critical decisions | Consensus Voting | Weighted voting |
| Audit trail needed | Event Sourcing | Custom logging |
| Production scaling | Lifecycle Management | Kubernetes |
| Research synthesis | AutoGen Group Chat | LangGraph |
| Hierarchical teams | CrewAI Hierarchical | LangGraph |

---

[← Back to Main](./SKILL.md) | [View Examples →](./EXAMPLES.md)
