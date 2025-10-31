# Multi-Agent Coordination - Reference

[← Back to Main](./SKILL.md)

## Table of Contents

- [Architectures](#architectures)
- [Communication Patterns](#communication-patterns)
- [Consensus Mechanisms](#consensus-mechanisms)
- [Framework Feature Matrix](#framework-feature-matrix)
- [API Reference](#api-reference)

## Architectures

### 1. Hub-Spoke (Centralized)

```
        ┌─────────────┐
        │ Coordinator │
        │   Agent     │
        └──────┬──────┘
               │
    ┏━━━━━━━━━┻━━━━━━━━━┓
    ▼          ▼         ▼
┌────────┐ ┌────────┐ ┌────────┐
│Agent 1 │ │Agent 2 │ │Agent 3 │
└────────┘ └────────┘ └────────┘
```

**Pros**:
- Simple to implement and debug
- Predictable execution flow
- Easy to add/remove agents
- Clear responsibility (coordinator owns routing)

**Cons**:
- Single point of failure (coordinator)
- Bottleneck at coordinator
- Coordinator can become complex
- No direct agent-to-agent communication

**Best for**: Simple workflows, prototyping, when coordinator logic is straightforward

### 2. Peer-to-Peer (Distributed)

```
┌────────┐     ┌────────┐
│Agent 1 │◄───►│Agent 2 │
└───┬────┘     └───┬────┘
    │              │
    │    ┌────────┐│
    └───►│Agent 3 │◄
         └────────┘
```

**Pros**:
- No single point of failure
- Scalable (no bottleneck)
- Resilient to agent failures
- Direct agent communication

**Cons**:
- Complex coordination logic
- Potential for conflicts
- Harder to debug (no central view)
- Need consensus mechanisms

**Best for**: High availability systems, distributed processing, resilient systems

### 3. Hierarchical (Tree)

```
         ┌─────────────┐
         │Orchestrator │
         └──────┬──────┘
                │
        ┌───────┴───────┐
        ▼               ▼
   ┌─────────┐     ┌─────────┐
   │Supervisor│     │Supervisor│
   └────┬────┘     └────┬────┘
        │               │
    ┌───┴───┐       ┌───┴───┐
    ▼       ▼       ▼       ▼
┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐
│Agent │ │Agent │ │Agent │ │Agent │
└──────┘ └──────┘ └──────┘ └──────┘
```

**Pros**:
- Clear hierarchy and delegation
- Specialized supervision at each level
- Scalable (distribute supervision)
- Mimics organizational structures

**Cons**:
- More complex than hub-spoke
- Supervisor overhead at each level
- Potential bottleneck at top
- Harder to implement

**Best for**: Large teams, organizational simulations, multi-level delegation

### 4. Mesh (Fully Connected)

```
    ┌────────┐◄───►┌────────┐
    │Agent 1 │     │Agent 2 │
    └───┬────┘◄───►└───┬────┘
        │              │
        │◄────────────►│
        │              │
    ┌───▼────┐◄───►┌───▼────┐
    │Agent 3 │◄───►│Agent 4 │
    └────────┘     └────────┘
```

**Pros**:
- Maximum resilience (no single point of failure)
- Any agent can communicate with any other
- Redundant paths for messages
- No coordinator needed

**Cons**:
- O(n²) communication overhead
- Complex to manage at scale
- Message routing complexity
- Potential for message storms

**Best for**: Small agent counts (< 10), maximum reliability required

## Communication Patterns

### Synchronous (Request-Response)

```
Agent A ──request──► Agent B
Agent A ◄─response── Agent B
```

**Characteristics**:
- Blocking: Agent A waits for response
- Simple to implement
- Clear causality
- Timeout required

**Use when**:
- Need immediate response
- Response required to proceed
- Simple workflows

**Example**:
```python
response = await agent_b.execute(request, timeout=30)
```

### Asynchronous (Message Queue)

```
Agent A ──msg──► Queue ──msg──► Agent B
```

**Characteristics**:
- Non-blocking: Agent A continues
- Decoupled agents
- Persistence (queue survives crashes)
- At-least-once delivery

**Use when**:
- Don't need immediate response
- Want loose coupling
- Need message persistence

**Example**:
```python
queue.publish(message)
# Agent A continues without waiting
```

### Pub/Sub (Broadcast)

```
Publisher ──event──► Topic ──┬──► Subscriber 1
                             ├──► Subscriber 2
                             └──► Subscriber 3
```

**Characteristics**:
- One-to-many communication
- Subscribers don't know about each other
- Publisher doesn't know subscribers
- Event-driven

**Use when**:
- Multiple agents need same information
- Event notifications
- Broadcast updates

**Example**:
```python
topic.publish("task_completed", data)
# All subscribers receive event
```

### Gossip (Peer-to-Peer)

```
Agent 1 ──tells──► Agent 2 ──tells──► Agent 3
   ▲                                      │
   └──────────────tells────────────────┘
```

**Characteristics**:
- Eventually consistent
- No central coordinator
- Fault-tolerant
- Slow convergence

**Use when**:
- Eventual consistency acceptable
- No central authority
- High fault tolerance needed

**Example**:
```python
agent.gossip(rumor, fanout=3)
```

## Consensus Mechanisms

### Voting (Democratic)

```
Decision Question
        │
   ┌────┴────┬────────┬────────┐
   ▼         ▼        ▼        ▼
┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐
│ YES │  │ YES │  │ NO  │  │ YES │
└─────┘  └─────┘  └─────┘  └─────┘
   │         │        │        │
   └─────────┴────────┴────────┘
              │
        Result: PASS (3/4 = 75%)
```

**Types**:
- **Simple Majority**: > 50% required
- **Supermajority**: 2/3 or higher required
- **Unanimous**: 100% agreement required

**Use for**: Classification, decision making, binary choices

### Weighted Voting

```
┌─────────────────────────────┐
│ Agent 1: YES (weight: 0.9)  │
│ Agent 2: YES (weight: 0.8)  │
│ Agent 3: NO  (weight: 0.7)  │
│ Agent 4: YES (weight: 0.6)  │
└─────────────────────────────┘
         │
   YES weight: 2.3
   NO weight:  0.7
         │
    Result: PASS
```

**Weighting Factors**:
- Agent expertise/confidence
- Historical accuracy
- Domain specialization
- Response time

**Use for**: Expert systems, confidence-based decisions

### Quorum

```
Total Agents: 10
Quorum: 7

Voted: 6 ─► INSUFFICIENT QUORUM
Voted: 8 ─► Proceed with majority vote
```

**Purpose**: Ensure minimum participation

**Use for**: Critical decisions, preventing decisions with too few agents

### Leader Election

```
┌────────┐  ┌────────┐  ┌────────┐
│Agent 1 │  │Agent 2 │  │Agent 3 │
└───┬────┘  └───┬────┘  └───┬────┘
    │           │           │
    └───────────┴───────────┘
                │
          Election Process
                │
           ┌────▼────┐
           │ Leader  │
           │(Agent 2)│
           └─────────┘
```

**Algorithms**:
- **Bully Algorithm**: Highest ID wins
- **Ring Algorithm**: Token-based election
- **Raft**: Consensus-based leader election

**Use for**: Conflict resolution, coordination, tie-breaking

### Consensus Protocols

**Raft Consensus**:
1. Leader election
2. Log replication
3. Safety guarantees

**Paxos**:
1. Prepare phase
2. Accept phase
3. Learn phase

**Use for**: State synchronization, distributed agreement

## Framework Feature Matrix

### Detailed Comparison

| Feature | LangGraph | AutoGen | CrewAI | Custom |
|---------|-----------|---------|--------|--------|
| **Ease of Use** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐ |
| **Flexibility** | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Graph Support** | ✅ Native | ❌ No | ❌ No | ⚠️ Manual |
| **State Management** | ✅ Built-in | ⚠️ Basic | ⚠️ Basic | ⚠️ Custom |
| **Human-in-Loop** | ⚠️ Custom | ✅ Native | ⚠️ Custom | ⚠️ Custom |
| **Code Execution** | ❌ No | ✅ Native | ✅ Tools | ⚠️ Custom |
| **Conversation** | ⚠️ Via LangChain | ✅ Native | ⚠️ Basic | ⚠️ Custom |
| **Task Dependencies** | ✅ Graph edges | ⚠️ Manual | ✅ Built-in | ⚠️ Custom |
| **Agent Roles** | ⚠️ Manual | ✅ System messages | ✅ Built-in | ⚠️ Custom |
| **Parallel Execution** | ✅ Via graph | ⚠️ Manual | ✅ Built-in | ⚠️ Custom |
| **Checkpointing** | ✅ Yes | ❌ No | ❌ No | ⚠️ Custom |
| **Streaming** | ✅ Yes | ⚠️ Limited | ❌ No | ⚠️ Custom |
| **Tool Use** | ✅ LangChain | ✅ Native | ✅ Native | ⚠️ Custom |
| **Learning Curve** | Medium | Low | Low | High |
| **Documentation** | ✅ Excellent | ✅ Excellent | ✅ Good | N/A |
| **Community** | Large | Large | Growing | N/A |
| **Production Ready** | ✅ Yes | ✅ Yes | ⚠️ Emerging | Depends |
| **Best For** | Complex workflows | Conversations | Role-based teams | Full control |

### Framework-Specific Features

**LangGraph**:
- Conditional edges
- Cycle detection
- State schemas (TypedDict)
- Visualization tools
- Integration with LangChain ecosystem

**AutoGen**:
- Multiple conversation patterns (group, sequential, nested)
- Built-in code execution (UserProxyAgent)
- Speaker selection strategies
- Teachability (agents learn from feedback)
- GPT-4V vision support

**CrewAI**:
- Role/goal/backstory agent definition
- Task context (dependencies)
- Process types (sequential, hierarchical)
- Memory (short-term, long-term, entity)
- Built-in tools and custom tools

## API Reference

### LangGraph API

#### StateGraph

```python
from langgraph.graph import StateGraph, END

workflow = StateGraph(state_schema)
workflow.add_node(name, function)
workflow.add_edge(from_node, to_node)
workflow.add_conditional_edges(source, condition_fn, mapping)
workflow.set_entry_point(node_name)
app = workflow.compile()
```

#### State Schema

```python
from typing import Annotated, TypedDict
import operator

class AgentState(TypedDict):
    messages: Annotated[list, operator.add]  # Accumulate
    next_agent: str                          # Replace
    metadata: dict                           # Replace
```

### AutoGen API

#### Agents

```python
from autogen import AssistantAgent, UserProxyAgent

agent = AssistantAgent(
    name="AgentName",
    system_message="Role description",
    llm_config=config
)

user_proxy = UserProxyAgent(
    name="User",
    human_input_mode="NEVER",  # NEVER, ALWAYS, TERMINATE
    code_execution_config={"work_dir": "coding"}
)
```

#### Group Chat

```python
from autogen import GroupChat, GroupChatManager

groupchat = GroupChat(
    agents=[agent1, agent2, agent3],
    messages=[],
    max_round=20,
    speaker_selection_method="auto"  # auto, round_robin, manual
)

manager = GroupChatManager(groupchat=groupchat, llm_config=config)
```

### CrewAI API

#### Agent

```python
from crewai import Agent

agent = Agent(
    role="Role Title",
    goal="Agent's goal",
    backstory="Agent's background",
    verbose=True,
    allow_delegation=True,
    llm=llm
)
```

#### Task

```python
from crewai import Task

task = Task(
    description="Task description",
    agent=agent,
    expected_output="Expected output description",
    context=[dependent_task1, dependent_task2]  # Dependencies
)
```

#### Crew

```python
from crewai import Crew, Process

crew = Crew(
    agents=[agent1, agent2, agent3],
    tasks=[task1, task2, task3],
    process=Process.sequential,  # or Process.hierarchical
    verbose=2
)

result = crew.kickoff()
```

### Consensus API (Custom)

```python
from multi_agent_coordination import ConsensusEngine, Vote, VoteType

consensus = ConsensusEngine(agents=["a1", "a2", "a3"])

votes = [
    Vote(agent_id="a1", vote=VoteType.YES, confidence=0.9, reasoning="..."),
    Vote(agent_id="a2", vote=VoteType.YES, confidence=0.8, reasoning="..."),
    Vote(agent_id="a3", vote=VoteType.NO, confidence=0.7, reasoning="..."),
]

# Various voting mechanisms
result = consensus.simple_majority(votes)
result = consensus.weighted_voting(votes)
result = consensus.supermajority(votes, threshold=0.66)
result = consensus.unanimous(votes)
result = consensus.quorum_based(votes, quorum=3)
```

### Event Sourcing API (Custom)

```python
from multi_agent_coordination import StateManager, EventType

state_mgr = StateManager()

# Register agent
state_mgr.register_agent("agent_1", {"name": "Analyzer", "type": "analysis"})

# Assign task
state_mgr.assign_task("agent_1", "task_1", {"description": "Analyze code"})

# Send message
state_mgr.send_message("agent_1", "agent_2", "Found issue in module X")

# Complete task
state_mgr.complete_task("agent_1", "task_1", {"result": "Analysis complete"})

# Get current state
current_state = state_mgr.get_current_state()

# Get agent view
agent_view = state_mgr.get_agent_view("agent_1")

# Get event history
history = state_mgr.get_event_history("agent_1")
```

### Lifecycle Management API (Custom)

```python
from multi_agent_coordination import AgentRegistry, AgentInfo, AgentStatus

registry = AgentRegistry()

# Register agent
agent = AgentInfo(
    agent_id="agent_1",
    agent_type="worker",
    capabilities=["analysis", "writing"],
    max_concurrent_tasks=3
)
registry.register(agent)

# Heartbeat
registry.heartbeat("agent_1", metrics)

# Update status
registry.update_status("agent_1", AgentStatus.BUSY)

# Find agents
agents = registry.find_agents(
    agent_type="worker",
    capability="analysis",
    min_health_score=0.7
)

# Get available agent
agent = registry.get_available_agent(capability="analysis")

# Registry status
status = registry.get_registry_status()
```

---

[← Back to Main](./SKILL.md) | [View Knowledge →](./KNOWLEDGE.md)
