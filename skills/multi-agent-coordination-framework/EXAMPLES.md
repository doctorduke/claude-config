# Multi-Agent Coordination - Code Examples

[← Back to Main](./SKILL.md)

This file contains complete, runnable code examples for all 6 implementation patterns.

## Table of Contents

- [Example 1: LangGraph Supervisor](#example-1-langgraph-supervisor)
- [Example 2: AutoGen Conversation](#example-2-autogen-conversation)
- [Example 3: CrewAI Teams](#example-3-crewai-teams)
- [Example 4: Consensus Voting](#example-4-consensus-voting)
- [Example 5: Event Sourcing](#example-5-event-sourcing)
- [Example 6: Lifecycle Management](#example-6-lifecycle-management)

---

## Example 1: LangGraph Supervisor

Multi-agent system with supervisor coordinating specialized agents.

**Pattern**: [PATTERNS.md - Pattern 1](./PATTERNS.md#pattern-1-langgraph-supervisor)

#!/usr/bin/env python3
"""
langgraph_multi_agent.py - Multi-agent coordination with LangGraph
"""

from typing import Annotated, Literal, TypedDict
from langchain_core.messages import HumanMessage, SystemMessage
from langchain_openai import ChatOpenAI
from langgraph.graph import StateGraph, END
from langgraph.prebuilt import ToolNode
import operator

# Define agent state
class AgentState(TypedDict):
    messages: Annotated[list, operator.add]
    next_agent: str
    final_response: str
    task_metadata: dict

# Specialized agents
def create_researcher_agent(llm):
    """Agent specializing in research and information gathering"""
    system_prompt = """You are a research specialist agent.
    Your role is to gather and analyze information.
    When you complete your research, respond with your findings.
    """

    def researcher(state: AgentState):
        messages = [SystemMessage(content=system_prompt)] + state["messages"]
        response = llm.invoke(messages)

        return {
            "messages": [response],
            "next_agent": "analyzer"
        }

    return researcher

def create_analyzer_agent(llm):
    """Agent specializing in analysis and interpretation"""
    system_prompt = """You are an analysis specialist agent.
    Your role is to analyze information and identify patterns.
    When you complete your analysis, provide key insights.
    """

    def analyzer(state: AgentState):
        messages = [SystemMessage(content=system_prompt)] + state["messages"]
        response = llm.invoke(messages)

        return {
            "messages": [response],
            "next_agent": "writer"
        }

    return analyzer

def create_writer_agent(llm):
    """Agent specializing in writing and communication"""
    system_prompt = """You are a writing specialist agent.
    Your role is to synthesize information into clear, concise reports.
    Provide a final summary of the work done.
    """

    def writer(state: AgentState):
        messages = [SystemMessage(content=system_prompt)] + state["messages"]
        response = llm.invoke(messages)

        return {
            "messages": [response],
            "final_response": response.content,
            "next_agent": "FINISH"
        }

    return writer

def create_supervisor_agent(llm, agents: list[str]):
    """Supervisor agent that routes tasks to specialized agents"""

    system_prompt = f"""You are a supervisor coordinating these agents: {', '.join(agents)}.

    Analyze the current state and determine which agent should act next.
    Respond with ONLY the agent name or FINISH when complete.

    Available agents:
    - researcher: Gathers information
    - analyzer: Analyzes data and identifies patterns
    - writer: Creates final reports

    Respond with just the agent name (lowercase) or FINISH.
    """

    def supervisor(state: AgentState):
        messages = [SystemMessage(content=system_prompt)] + state["messages"]
        response = llm.invoke(messages)

        next_agent = response.content.strip().lower()

        # Validate next agent
        if next_agent not in agents and next_agent != "finish":
            next_agent = "researcher"  # Default fallback

        return {"next_agent": next_agent}

    return supervisor

def route_to_agent(state: AgentState) -> str:
    """Route to next agent based on supervisor decision"""
    next_agent = state.get("next_agent", "supervisor")

    if next_agent == "finish" or next_agent == "FINISH":
        return "FINISH"

    return next_agent

# Build the multi-agent graph
def build_multi_agent_system():
    """Construct the multi-agent coordination graph"""

    llm = ChatOpenAI(model="gpt-4", temperature=0)

    # Create specialized agents
    agents = ["researcher", "analyzer", "writer"]

    # Build graph
    workflow = StateGraph(AgentState)

    # Add agent nodes
    workflow.add_node("supervisor", create_supervisor_agent(llm, agents))
    workflow.add_node("researcher", create_researcher_agent(llm))
    workflow.add_node("analyzer", create_analyzer_agent(llm))
    workflow.add_node("writer", create_writer_agent(llm))

    # Add edges - supervisor routes to all agents
    for agent in agents:
        workflow.add_edge(agent, "supervisor")

    # Conditional routing from supervisor
    workflow.add_conditional_edges(
        "supervisor",
        route_to_agent,
        {
            "researcher": "researcher",
            "analyzer": "analyzer",
            "writer": "writer",
            "FINISH": END
        }
    )

    # Set entry point
    workflow.set_entry_point("supervisor")

    return workflow.compile()

# Usage example
if __name__ == "__main__":
    # Create multi-agent system
    agent_system = build_multi_agent_system()

    # Execute task
    initial_state = {
        "messages": [
            HumanMessage(content="Research and analyze the benefits of multi-agent systems in AI. Provide a comprehensive report.")
        ],
        "next_agent": "supervisor",
        "final_response": "",
        "task_metadata": {}
    }

    # Run the agent system
    final_state = agent_system.invoke(initial_state)

    print("Final Response:")
    print(final_state["final_response"])

    print("\n\nAgent Execution History:")
    for msg in final_state["messages"]:
        print(f"\n{msg.type}: {msg.content[:200]}...")
```

---

## Example 2: AutoGen Conversation

Conversational multi-agent system with group chat and human-in-the-loop.

**Pattern**: [PATTERNS.md - Pattern 2](./PATTERNS.md#pattern-2-autogen-conversation)

#!/usr/bin/env python3
"""
autogen_multi_agent.py - Multi-agent conversation with AutoGen
"""

import autogen
from typing import Dict, List

# Configure LLM
config_list = [
    {
        "model": "gpt-4",
        "api_key": "your-api-key"
    }
]

llm_config = {
    "config_list": config_list,
    "temperature": 0.7,
    "timeout": 120,
}

def create_multi_agent_team():
    """Create a team of specialized agents"""

    # 1. Product Manager Agent
    product_manager = autogen.AssistantAgent(
        name="ProductManager",
        system_message="""You are a product manager. Your role is to:
        - Define requirements and user stories
        - Prioritize features
        - Ensure alignment with business goals
        - Coordinate between team members

        Be concise and focused on outcomes.
        """,
        llm_config=llm_config,
    )

    # 2. Software Engineer Agent
    engineer = autogen.AssistantAgent(
        name="Engineer",
        system_message="""You are a senior software engineer. Your role is to:
        - Design technical solutions
        - Write code and implement features
        - Identify technical constraints
        - Suggest architecture improvements

        Provide concrete, implementable solutions.
        """,
        llm_config=llm_config,
    )

    # 3. QA Engineer Agent
    qa_engineer = autogen.AssistantAgent(
        name="QAEngineer",
        system_message="""You are a QA engineer. Your role is to:
        - Identify edge cases and failure modes
        - Suggest test strategies
        - Validate requirements are testable
        - Point out quality concerns

        Be thorough and detail-oriented.
        """,
        llm_config=llm_config,
    )

    # 4. Security Specialist Agent
    security_specialist = autogen.AssistantAgent(
        name="SecuritySpecialist",
        system_message="""You are a security specialist. Your role is to:
        - Identify security vulnerabilities
        - Suggest security best practices
        - Review authentication/authorization
        - Point out data protection concerns

        Focus on threats and mitigations.
        """,
        llm_config=llm_config,
    )

    # 5. Code Reviewer Agent (with code execution)
    code_reviewer = autogen.AssistantAgent(
        name="CodeReviewer",
        system_message="""You are a code reviewer. Your role is to:
        - Review code quality and style
        - Check for bugs and anti-patterns
        - Ensure best practices are followed
        - Suggest improvements

        Be constructive and specific.
        """,
        llm_config=llm_config,
    )

    # 6. Human User Proxy (can execute code)
    user_proxy = autogen.UserProxyAgent(
        name="UserProxy",
        human_input_mode="NEVER",  # Change to "ALWAYS" for human-in-the-loop
        max_consecutive_auto_reply=10,
        is_termination_msg=lambda x: x.get("content", "").rstrip().endswith("TERMINATE"),
        code_execution_config={
            "work_dir": "coding",
            "use_docker": False,  # Set to True for isolation
        },
    )

    return {
        "pm": product_manager,
        "engineer": engineer,
        "qa": qa_engineer,
        "security": security_specialist,
        "reviewer": code_reviewer,
        "user": user_proxy
    }

def run_group_chat(agents: Dict, task: str):
    """Run a group chat with all agents"""

    # Create group chat
    groupchat = autogen.GroupChat(
        agents=list(agents.values()),
        messages=[],
        max_round=20,
        speaker_selection_method="auto",  # or "round_robin", "manual"
    )

    # Create manager to coordinate group chat
    manager = autogen.GroupChatManager(
        groupchat=groupchat,
        llm_config=llm_config
    )

    # Start the conversation
    agents["user"].initiate_chat(
        manager,
        message=task
    )

def run_sequential_chat(agents: Dict, task: str):
    """Run sequential handoffs between agents"""

    # PM defines requirements
    agents["user"].initiate_chat(
        agents["pm"],
        message=f"{task}\n\nPlease define the requirements."
    )

    # Engineer designs solution
    pm_response = agents["pm"].last_message()
    agents["user"].initiate_chat(
        agents["engineer"],
        message=f"Based on these requirements:\n{pm_response}\n\nPlease design a solution."
    )

    # QA reviews design
    eng_response = agents["engineer"].last_message()
    agents["user"].initiate_chat(
        agents["qa"],
        message=f"Based on this design:\n{eng_response}\n\nWhat are the testing considerations?"
    )

    # Security reviews
    qa_response = agents["qa"].last_message()
    agents["user"].initiate_chat(
        agents["security"],
        message=f"Please review for security concerns:\n{eng_response}\n{qa_response}"
    )

def run_debate_chat(agents: Dict, topic: str):
    """Run a debate between agents to reach consensus"""

    # Create debate between engineer and QA on approach
    debate_group = autogen.GroupChat(
        agents=[agents["engineer"], agents["qa"], agents["user"]],
        messages=[],
        max_round=10,
        speaker_selection_method="round_robin",
    )

    manager = autogen.GroupChatManager(
        groupchat=debate_group,
        llm_config=llm_config
    )

    agents["user"].initiate_chat(
        manager,
        message=f"Debate: {topic}\n\nEngineer, argue for your approach. QA, provide counterpoints. Reach consensus."
    )

# Example usage
if __name__ == "__main__":
    agents = create_multi_agent_team()

    # Example 1: Group chat for feature design
    print("=== GROUP CHAT: Feature Design ===")
    run_group_chat(
        agents,
        """Design a new authentication system for our application.
        Consider: security, user experience, scalability, and testing.
        Each team member should contribute their perspective.
        End with TERMINATE when consensus is reached."""
    )

    # Example 2: Sequential handoffs
    print("\n\n=== SEQUENTIAL CHAT: Code Review Process ===")
    run_sequential_chat(
        agents,
        "Implement user password reset functionality"
    )

    # Example 3: Debate for decision making
    print("\n\n=== DEBATE: Technical Decision ===")
    run_debate_chat(
        agents,
        "Should we use microservices or monolithic architecture?"
    )
```

---

## Example 3: CrewAI Teams

Role-based agent teams with task dependencies.

**Pattern**: [PATTERNS.md - Pattern 3](./PATTERNS.md#pattern-3-crewai-teams)

#!/usr/bin/env python3
"""
crewai_agent_teams.py - Role-based multi-agent teams with CrewAI
"""

from crewai import Agent, Task, Crew, Process
from langchain_openai import ChatOpenAI

# Initialize LLM
llm = ChatOpenAI(model="gpt-4", temperature=0.7)

def create_code_review_crew():
    """Create a crew for code review tasks"""

    # Agent 1: Code Analyzer
    code_analyzer = Agent(
        role="Code Analyzer",
        goal="Analyze code structure, complexity, and maintainability",
        backstory="""You are an expert code analyzer with 15 years of experience.
        You can quickly identify code smells, anti-patterns, and architectural issues.
        You focus on code quality metrics like cyclomatic complexity, coupling, and cohesion.""",
        verbose=True,
        allow_delegation=True,
        llm=llm
    )

    # Agent 2: Security Auditor
    security_auditor = Agent(
        role="Security Auditor",
        goal="Identify security vulnerabilities and risks",
        backstory="""You are a security expert specializing in application security.
        You know OWASP Top 10, common vulnerabilities, and secure coding practices.
        You can spot SQL injection, XSS, CSRF, and other security issues.""",
        verbose=True,
        allow_delegation=True,
        llm=llm
    )

    # Agent 3: Performance Optimizer
    performance_optimizer = Agent(
        role="Performance Optimizer",
        goal="Identify performance bottlenecks and optimization opportunities",
        backstory="""You are a performance tuning expert.
        You understand algorithms, data structures, and system architecture.
        You can identify inefficient queries, memory leaks, and scalability issues.""",
        verbose=True,
        allow_delegation=True,
        llm=llm
    )

    # Agent 4: Test Coverage Analyst
    test_analyst = Agent(
        role="Test Coverage Analyst",
        goal="Assess test coverage and identify untested scenarios",
        backstory="""You are a testing expert with deep knowledge of test strategies.
        You can identify edge cases, missing test scenarios, and improve test coverage.
        You understand unit, integration, and end-to-end testing.""",
        verbose=True,
        allow_delegation=True,
        llm=llm
    )

    # Agent 5: Documentation Specialist
    doc_specialist = Agent(
        role="Documentation Specialist",
        goal="Evaluate documentation quality and completeness",
        backstory="""You are a technical writer specializing in code documentation.
        You ensure code is well-documented, APIs are clear, and examples are provided.
        You focus on readability and maintainability through documentation.""",
        verbose=True,
        allow_delegation=True,
        llm=llm
    )

    # Agent 6: Report Synthesizer (Supervisor)
    report_synthesizer = Agent(
        role="Report Synthesizer",
        goal="Synthesize all findings into a comprehensive code review report",
        backstory="""You are a senior technical lead who coordinates code reviews.
        You synthesize feedback from multiple specialists into actionable recommendations.
        You prioritize issues and create clear, structured reports.""",
        verbose=True,
        allow_delegation=False,
        llm=llm
    )

    return {
        "analyzer": code_analyzer,
        "security": security_auditor,
        "performance": performance_optimizer,
        "testing": test_analyst,
        "docs": doc_specialist,
        "synthesizer": report_synthesizer
    }

def create_code_review_tasks(agents: dict, code_path: str):
    """Create tasks for code review workflow"""

    # Task 1: Analyze code structure
    analyze_task = Task(
        description=f"""Analyze the code at {code_path}.

        Focus on:
        - Code structure and organization
        - Complexity metrics
        - Design patterns used
        - Maintainability concerns

        Provide specific examples and line numbers.""",
        agent=agents["analyzer"],
        expected_output="Detailed code structure analysis with specific issues identified"
    )

    # Task 2: Security audit
    security_task = Task(
        description=f"""Perform security audit of code at {code_path}.

        Check for:
        - Input validation issues
        - Authentication/authorization flaws
        - Sensitive data exposure
        - Known vulnerability patterns

        Classify by severity (Critical, High, Medium, Low).""",
        agent=agents["security"],
        expected_output="Security audit report with vulnerabilities categorized by severity"
    )

    # Task 3: Performance analysis
    performance_task = Task(
        description=f"""Analyze performance of code at {code_path}.

        Look for:
        - Inefficient algorithms (O(n²) where O(n log n) possible)
        - Database query optimization opportunities
        - Memory usage concerns
        - Caching opportunities

        Provide estimated performance impact.""",
        agent=agents["performance"],
        expected_output="Performance analysis with optimization recommendations"
    )

    # Task 4: Test coverage analysis
    test_task = Task(
        description=f"""Evaluate test coverage for code at {code_path}.

        Assess:
        - Existing test coverage
        - Missing test scenarios
        - Edge cases not covered
        - Integration test gaps

        Suggest specific tests to add.""",
        agent=agents["testing"],
        expected_output="Test coverage assessment with specific test recommendations"
    )

    # Task 5: Documentation review
    doc_task = Task(
        description=f"""Review documentation for code at {code_path}.

        Check:
        - Function/class docstrings
        - API documentation
        - Code comments quality
        - README completeness

        Identify undocumented or poorly documented code.""",
        agent=agents["docs"],
        expected_output="Documentation review with improvement suggestions"
    )

    # Task 6: Synthesize report (depends on all previous)
    synthesize_task = Task(
        description="""Synthesize all code review findings into a comprehensive report.

        Create a report with:
        1. Executive Summary
        2. Critical Issues (must fix before merge)
        3. High Priority Issues (fix soon)
        4. Medium Priority Issues (address in next sprint)
        5. Low Priority Issues (nice to have)
        6. Positive Findings (what's done well)
        7. Recommended Actions with priorities

        Make it actionable and clear.""",
        agent=agents["synthesizer"],
        expected_output="Comprehensive code review report with prioritized action items",
        context=[analyze_task, security_task, performance_task, test_task, doc_task]
    )

    return [
        analyze_task,
        security_task,
        performance_task,
        test_task,
        doc_task,
        synthesize_task
    ]

def run_code_review_crew(code_path: str):
    """Execute code review with multi-agent crew"""

    # Create agents
    agents = create_code_review_crew()

    # Create tasks
    tasks = create_code_review_tasks(agents, code_path)

    # Create crew with sequential process
    crew = Crew(
        agents=list(agents.values()),
        tasks=tasks,
        process=Process.sequential,  # or Process.hierarchical
        verbose=2,  # Logging level
        full_output=True
    )

    # Execute crew
    result = crew.kickoff()

    return result

def create_parallel_research_crew():
    """Create a crew for parallel research tasks"""

    # Create specialized research agents
    web_researcher = Agent(
        role="Web Researcher",
        goal="Research information from the web",
        backstory="Expert at finding and synthesizing web information",
        llm=llm,
        allow_delegation=False
    )

    paper_researcher = Agent(
        role="Academic Researcher",
        goal="Research academic papers and publications",
        backstory="Expert at finding and analyzing academic research",
        llm=llm,
        allow_delegation=False
    )

    code_researcher = Agent(
        role="Code Researcher",
        goal="Research code examples and repositories",
        backstory="Expert at finding and analyzing code examples",
        llm=llm,
        allow_delegation=False
    )

    synthesizer = Agent(
        role="Research Synthesizer",
        goal="Combine research from multiple sources",
        backstory="Expert at synthesizing information from diverse sources",
        llm=llm,
        allow_delegation=False
    )

    # Create parallel tasks
    web_task = Task(
        description="Research 'multi-agent systems' from web sources",
        agent=web_researcher,
        expected_output="Summary of web research findings"
    )

    paper_task = Task(
        description="Research academic papers on 'multi-agent systems'",
        agent=paper_researcher,
        expected_output="Summary of academic research"
    )

    code_task = Task(
        description="Find code examples of multi-agent systems",
        agent=code_researcher,
        expected_output="Summary of code examples and patterns"
    )

    synthesis_task = Task(
        description="Synthesize all research into comprehensive report",
        agent=synthesizer,
        expected_output="Comprehensive research report",
        context=[web_task, paper_task, code_task]
    )

    # Create crew with parallel execution
    crew = Crew(
        agents=[web_researcher, paper_researcher, code_researcher, synthesizer],
        tasks=[web_task, paper_task, code_task, synthesis_task],
        process=Process.sequential,  # Tasks run in order, but agents work in parallel where possible
        verbose=2
    )

    return crew

# Example usage
if __name__ == "__main__":
    print("=== CODE REVIEW CREW ===")
    result = run_code_review_crew("src/main.py")
    print("\nFinal Report:")
    print(result)

    print("\n\n=== PARALLEL RESEARCH CREW ===")
    research_crew = create_parallel_research_crew()
    research_result = research_crew.kickoff()
    print("\nResearch Report:")
    print(research_result)
```

---

## Example 4: Consensus Voting

Consensus and voting mechanisms for multi-agent decisions.

**Pattern**: [PATTERNS.md - Pattern 4](./PATTERNS.md#pattern-4-consensus-voting)

#!/usr/bin/env python3
"""
consensus_mechanisms.py - Consensus and voting for multi-agent systems
"""

from dataclasses import dataclass
from typing import List, Dict, Any, Optional
from enum import Enum
import statistics

class VoteType(Enum):
    YES = "yes"
    NO = "no"
    ABSTAIN = "abstain"

@dataclass
class Vote:
    agent_id: str
    vote: VoteType
    confidence: float  # 0.0 to 1.0
    reasoning: str

@dataclass
class AgentResponse:
    agent_id: str
    response: Any
    confidence: float
    metadata: Dict[str, Any]

class ConsensusEngine:
    """Implement various consensus mechanisms for multi-agent systems"""

    def __init__(self, agents: List[str]):
        self.agents = agents

    def simple_majority(self, votes: List[Vote]) -> Dict[str, Any]:
        """Simple majority voting - 50% + 1"""

        yes_votes = sum(1 for v in votes if v.vote == VoteType.YES)
        no_votes = sum(1 for v in votes if v.vote == VoteType.NO)
        total = len(votes)

        result = "PASS" if yes_votes > total / 2 else "FAIL"

        return {
            "result": result,
            "yes": yes_votes,
            "no": no_votes,
            "abstain": total - yes_votes - no_votes,
            "percentage": yes_votes / total * 100 if total > 0 else 0
        }

    def weighted_voting(self, votes: List[Vote]) -> Dict[str, Any]:
        """Weighted voting based on agent confidence"""

        yes_weight = sum(v.confidence for v in votes if v.vote == VoteType.YES)
        no_weight = sum(v.confidence for v in votes if v.vote == VoteType.NO)
        total_weight = sum(v.confidence for v in votes)

        result = "PASS" if yes_weight > no_weight else "FAIL"

        return {
            "result": result,
            "yes_weight": yes_weight,
            "no_weight": no_weight,
            "total_weight": total_weight,
            "confidence": yes_weight / total_weight if total_weight > 0 else 0
        }

    def supermajority(self, votes: List[Vote], threshold: float = 0.66) -> Dict[str, Any]:
        """Supermajority voting - requires 2/3 or custom threshold"""

        yes_votes = sum(1 for v in votes if v.vote == VoteType.YES)
        total = len(votes)

        percentage = yes_votes / total if total > 0 else 0
        result = "PASS" if percentage >= threshold else "FAIL"

        return {
            "result": result,
            "yes": yes_votes,
            "total": total,
            "percentage": percentage * 100,
            "threshold": threshold * 100
        }

    def unanimous(self, votes: List[Vote]) -> Dict[str, Any]:
        """Unanimous voting - all agents must agree"""

        all_yes = all(v.vote == VoteType.YES for v in votes)

        return {
            "result": "PASS" if all_yes else "FAIL",
            "unanimous": all_yes,
            "votes": len(votes)
        }

    def quorum_based(self, votes: List[Vote], quorum: int) -> Dict[str, Any]:
        """Quorum-based voting - minimum participation required"""

        if len(votes) < quorum:
            return {
                "result": "INSUFFICIENT_QUORUM",
                "votes": len(votes),
                "required": quorum
            }

        return self.simple_majority(votes)

    def ranking_consensus(self, responses: List[AgentResponse]) -> Dict[str, Any]:
        """Consensus based on ranking/scoring"""

        # Calculate average score
        scores = [r.confidence * hash(str(r.response)) % 100 for r in responses]
        avg_score = statistics.mean(scores) if scores else 0

        # Calculate agreement (how close scores are)
        if len(scores) > 1:
            stdev = statistics.stdev(scores)
            agreement = 1 - (stdev / 100)  # Normalize
        else:
            agreement = 1.0

        # Pick highest confidence response as consensus
        best_response = max(responses, key=lambda r: r.confidence)

        return {
            "consensus_response": best_response.response,
            "consensus_agent": best_response.agent_id,
            "average_score": avg_score,
            "agreement_level": agreement,
            "confidence": best_response.confidence
        }

    def iterative_consensus(
        self,
        responses: List[AgentResponse],
        max_iterations: int = 3
    ) -> Dict[str, Any]:
        """Iterative consensus - agents refine responses based on others"""

        iteration = 0
        current_responses = responses

        while iteration < max_iterations:
            # Calculate variance in responses
            variance = self._calculate_response_variance(current_responses)

            if variance < 0.1:  # Converged
                break

            # In real implementation, agents would see others' responses
            # and refine their own. Simplified here.
            iteration += 1

        # Return consensus
        return self.ranking_consensus(current_responses)

    def _calculate_response_variance(self, responses: List[AgentResponse]) -> float:
        """Calculate variance in agent responses"""
        if len(responses) < 2:
            return 0.0

        confidences = [r.confidence for r in responses]
        return statistics.variance(confidences)

class ConflictResolver:
    """Resolve conflicts between agents"""

    def resolve_by_expertise(
        self,
        responses: List[AgentResponse],
        expertise_scores: Dict[str, float]
    ) -> AgentResponse:
        """Resolve conflict by deferring to expert agent"""

        # Weight responses by expertise
        weighted_responses = [
            (r, expertise_scores.get(r.agent_id, 0.5))
            for r in responses
        ]

        # Pick response from most expert agent
        best = max(weighted_responses, key=lambda x: x[1])
        return best[0]

    def resolve_by_voting(
        self,
        responses: List[AgentResponse],
        voters: List[str]
    ) -> AgentResponse:
        """Resolve conflict by voting among agents"""

        # Each agent votes for their preferred response
        # Simplified: pick most popular response
        response_counts = {}
        for r in responses:
            key = str(r.response)
            response_counts[key] = response_counts.get(key, 0) + 1

        most_popular = max(response_counts.items(), key=lambda x: x[1])[0]

        # Return the response that matches most popular
        for r in responses:
            if str(r.response) == most_popular:
                return r

        return responses[0]  # Fallback

    def resolve_by_compromise(
        self,
        responses: List[AgentResponse]
    ) -> AgentResponse:
        """Create compromise solution from conflicting responses"""

        # Take average of numeric responses
        # For non-numeric, pick median confidence response
        numeric_responses = [
            r for r in responses
            if isinstance(r.response, (int, float))
        ]

        if numeric_responses:
            avg_response = statistics.mean([r.response for r in numeric_responses])
            avg_confidence = statistics.mean([r.confidence for r in numeric_responses])

            return AgentResponse(
                agent_id="compromise",
                response=avg_response,
                confidence=avg_confidence,
                metadata={"type": "compromise", "contributors": len(numeric_responses)}
            )

        # For non-numeric, pick median by confidence
        sorted_responses = sorted(responses, key=lambda r: r.confidence)
        median_idx = len(sorted_responses) // 2
        return sorted_responses[median_idx]

    def resolve_by_chain_of_thought(
        self,
        responses: List[AgentResponse]
    ) -> AgentResponse:
        """Resolve by combining reasoning chains"""

        # Combine all reasoning/metadata
        combined_reasoning = []
        for r in responses:
            if "reasoning" in r.metadata:
                combined_reasoning.append(r.metadata["reasoning"])

        # Pick response with strongest reasoning chain
        # Simplified: pick highest confidence with reasoning
        responses_with_reasoning = [
            r for r in responses
            if "reasoning" in r.metadata
        ]

        if responses_with_reasoning:
            return max(responses_with_reasoning, key=lambda r: r.confidence)

        return max(responses, key=lambda r: r.confidence)

# Example usage
if __name__ == "__main__":
    # Create consensus engine
    agents = ["agent_1", "agent_2", "agent_3", "agent_4", "agent_5"]
    consensus = ConsensusEngine(agents)

    # Example 1: Simple majority vote
    print("=== SIMPLE MAJORITY ===")
    votes = [
        Vote("agent_1", VoteType.YES, 0.9, "Feature is well-tested"),
        Vote("agent_2", VoteType.YES, 0.8, "Code quality is good"),
        Vote("agent_3", VoteType.NO, 0.7, "Performance concerns"),
        Vote("agent_4", VoteType.YES, 0.85, "Meets requirements"),
        Vote("agent_5", VoteType.ABSTAIN, 0.5, "Need more information"),
    ]

    result = consensus.simple_majority(votes)
    print(f"Result: {result}")

    # Example 2: Weighted voting
    print("\n=== WEIGHTED VOTING ===")
    result = consensus.weighted_voting(votes)
    print(f"Result: {result}")

    # Example 3: Supermajority (2/3)
    print("\n=== SUPERMAJORITY (66%) ===")
    result = consensus.supermajority(votes, threshold=0.66)
    print(f"Result: {result}")

    # Example 4: Ranking consensus
    print("\n=== RANKING CONSENSUS ===")
    responses = [
        AgentResponse("agent_1", "Approach A", 0.9, {"reasoning": "Best performance"}),
        AgentResponse("agent_2", "Approach A", 0.85, {"reasoning": "Most maintainable"}),
        AgentResponse("agent_3", "Approach B", 0.7, {"reasoning": "Simpler implementation"}),
        AgentResponse("agent_4", "Approach A", 0.8, {"reasoning": "Industry standard"}),
    ]

    result = consensus.ranking_consensus(responses)
    print(f"Result: {result}")

    # Example 5: Conflict resolution
    print("\n=== CONFLICT RESOLUTION ===")
    resolver = ConflictResolver()

    expertise_scores = {
        "agent_1": 0.9,  # Expert
        "agent_2": 0.7,
        "agent_3": 0.6,
        "agent_4": 0.8,
    }

    resolved = resolver.resolve_by_expertise(responses, expertise_scores)
    print(f"Resolved by expertise: {resolved}")

    compromise = resolver.resolve_by_compromise(responses)
    print(f"Compromise solution: {compromise}")
```

---

## Example 5: Event Sourcing

Shared state management using event sourcing pattern.

**Pattern**: [PATTERNS.md - Pattern 5](./PATTERNS.md#pattern-5-event-sourcing)

#!/usr/bin/env python3
"""
shared_state_management.py - Event sourcing for multi-agent state
"""

from dataclasses import dataclass, field
from typing import List, Dict, Any, Optional
from datetime import datetime
from enum import Enum
import json
from collections import defaultdict

class EventType(Enum):
    AGENT_REGISTERED = "agent.registered"
    AGENT_UPDATED = "agent.updated"
    AGENT_REMOVED = "agent.removed"
    STATE_UPDATED = "state.updated"
    TASK_ASSIGNED = "task.assigned"
    TASK_COMPLETED = "task.completed"
    MESSAGE_SENT = "message.sent"

@dataclass
class Event:
    """Immutable event in the event log"""
    event_id: str
    event_type: EventType
    agent_id: str
    timestamp: datetime
    data: Dict[str, Any]
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> dict:
        return {
            "event_id": self.event_id,
            "event_type": self.event_type.value,
            "agent_id": self.agent_id,
            "timestamp": self.timestamp.isoformat(),
            "data": self.data,
            "metadata": self.metadata
        }

class EventStore:
    """Store and retrieve events (event log)"""

    def __init__(self):
        self.events: List[Event] = []
        self._event_idx = 0

    def append(self, event: Event):
        """Append event to log"""
        self.events.append(event)

    def get_events(
        self,
        agent_id: Optional[str] = None,
        event_type: Optional[EventType] = None,
        since: Optional[datetime] = None
    ) -> List[Event]:
        """Query events with filters"""

        filtered = self.events

        if agent_id:
            filtered = [e for e in filtered if e.agent_id == agent_id]

        if event_type:
            filtered = [e for e in filtered if e.event_type == event_type]

        if since:
            filtered = [e for e in filtered if e.timestamp >= since]

        return filtered

    def replay_events(self, state_builder) -> Any:
        """Replay all events to rebuild state"""
        state = state_builder()

        for event in self.events:
            state = state.apply_event(event)

        return state

    def snapshot(self, state: Any) -> dict:
        """Create state snapshot"""
        return {
            "snapshot_time": datetime.now().isoformat(),
            "event_count": len(self.events),
            "state": state.to_dict()
        }

class SharedState:
    """Shared state built from events"""

    def __init__(self):
        self.agents: Dict[str, Dict[str, Any]] = {}
        self.tasks: Dict[str, Dict[str, Any]] = {}
        self.messages: List[Dict[str, Any]] = []
        self.metadata: Dict[str, Any] = {}

    def apply_event(self, event: Event) -> 'SharedState':
        """Apply event to state (pure function - returns new state)"""

        if event.event_type == EventType.AGENT_REGISTERED:
            self.agents[event.agent_id] = event.data

        elif event.event_type == EventType.AGENT_UPDATED:
            if event.agent_id in self.agents:
                self.agents[event.agent_id].update(event.data)

        elif event.event_type == EventType.AGENT_REMOVED:
            if event.agent_id in self.agents:
                del self.agents[event.agent_id]

        elif event.event_type == EventType.STATE_UPDATED:
            self.metadata.update(event.data)

        elif event.event_type == EventType.TASK_ASSIGNED:
            task_id = event.data["task_id"]
            self.tasks[task_id] = {
                "assigned_to": event.agent_id,
                "status": "assigned",
                **event.data
            }

        elif event.event_type == EventType.TASK_COMPLETED:
            task_id = event.data["task_id"]
            if task_id in self.tasks:
                self.tasks[task_id]["status"] = "completed"
                self.tasks[task_id].update(event.data)

        elif event.event_type == EventType.MESSAGE_SENT:
            self.messages.append({
                "from": event.agent_id,
                "to": event.data.get("to"),
                "message": event.data.get("message"),
                "timestamp": event.timestamp
            })

        return self

    def get_agent_state(self, agent_id: str) -> Optional[Dict[str, Any]]:
        """Get state for specific agent"""
        return self.agents.get(agent_id)

    def get_agent_tasks(self, agent_id: str) -> List[Dict[str, Any]]:
        """Get all tasks assigned to agent"""
        return [
            task for task in self.tasks.values()
            if task.get("assigned_to") == agent_id
        ]

    def get_messages(self, agent_id: str, direction: str = "both") -> List[Dict[str, Any]]:
        """Get messages for agent (sent, received, or both)"""
        messages = []

        for msg in self.messages:
            if direction in ["sent", "both"] and msg["from"] == agent_id:
                messages.append(msg)
            elif direction in ["received", "both"] and msg["to"] == agent_id:
                messages.append(msg)

        return messages

    def to_dict(self) -> dict:
        """Convert state to dictionary"""
        return {
            "agents": self.agents,
            "tasks": self.tasks,
            "message_count": len(self.messages),
            "metadata": self.metadata
        }

class StateManager:
    """Manage shared state across agents using event sourcing"""

    def __init__(self):
        self.event_store = EventStore()
        self._event_counter = 0

    def register_agent(self, agent_id: str, agent_data: Dict[str, Any]):
        """Register new agent"""
        event = Event(
            event_id=self._next_event_id(),
            event_type=EventType.AGENT_REGISTERED,
            agent_id=agent_id,
            timestamp=datetime.now(),
            data=agent_data
        )
        self.event_store.append(event)

    def update_agent(self, agent_id: str, updates: Dict[str, Any]):
        """Update agent state"""
        event = Event(
            event_id=self._next_event_id(),
            event_type=EventType.AGENT_UPDATED,
            agent_id=agent_id,
            timestamp=datetime.now(),
            data=updates
        )
        self.event_store.append(event)

    def assign_task(self, agent_id: str, task_id: str, task_data: Dict[str, Any]):
        """Assign task to agent"""
        event = Event(
            event_id=self._next_event_id(),
            event_type=EventType.TASK_ASSIGNED,
            agent_id=agent_id,
            timestamp=datetime.now(),
            data={"task_id": task_id, **task_data}
        )
        self.event_store.append(event)

    def complete_task(self, agent_id: str, task_id: str, result: Dict[str, Any]):
        """Mark task as completed"""
        event = Event(
            event_id=self._next_event_id(),
            event_type=EventType.TASK_COMPLETED,
            agent_id=agent_id,
            timestamp=datetime.now(),
            data={"task_id": task_id, "result": result}
        )
        self.event_store.append(event)

    def send_message(self, from_agent: str, to_agent: str, message: str):
        """Send message between agents"""
        event = Event(
            event_id=self._next_event_id(),
            event_type=EventType.MESSAGE_SENT,
            agent_id=from_agent,
            timestamp=datetime.now(),
            data={"to": to_agent, "message": message}
        )
        self.event_store.append(event)

    def get_current_state(self) -> SharedState:
        """Get current state by replaying all events"""
        return self.event_store.replay_events(SharedState)

    def get_agent_view(self, agent_id: str) -> Dict[str, Any]:
        """Get agent's view of shared state"""
        state = self.get_current_state()

        return {
            "my_state": state.get_agent_state(agent_id),
            "my_tasks": state.get_agent_tasks(agent_id),
            "my_messages": state.get_messages(agent_id, "received"),
            "all_agents": list(state.agents.keys()),
            "global_metadata": state.metadata
        }

    def get_event_history(self, agent_id: Optional[str] = None) -> List[Event]:
        """Get event history for debugging"""
        return self.event_store.get_events(agent_id=agent_id)

    def _next_event_id(self) -> str:
        """Generate next event ID"""
        self._event_counter += 1
        return f"event_{self._event_counter}"

# Example usage
if __name__ == "__main__":
    # Create state manager
    state_mgr = StateManager()

    # Register agents
    state_mgr.register_agent("agent_1", {
        "name": "Code Analyzer",
        "type": "analyzer",
        "status": "idle"
    })

    state_mgr.register_agent("agent_2", {
        "name": "Security Auditor",
        "type": "security",
        "status": "idle"
    })

    state_mgr.register_agent("agent_3", {
        "name": "Test Generator",
        "type": "testing",
        "status": "idle"
    })

    # Assign tasks
    state_mgr.assign_task("agent_1", "task_1", {
        "description": "Analyze code complexity",
        "priority": "high"
    })

    state_mgr.assign_task("agent_2", "task_2", {
        "description": "Security audit",
        "priority": "critical"
    })

    # Update agent status
    state_mgr.update_agent("agent_1", {"status": "working"})

    # Send messages
    state_mgr.send_message("agent_1", "agent_2", "Found potential security issue in module X")
    state_mgr.send_message("agent_2", "agent_1", "Thanks, investigating now")

    # Complete task
    state_mgr.complete_task("agent_1", "task_1", {
        "complexity_score": 45,
        "issues_found": 3
    })

    # Get current state
    print("=== CURRENT STATE ===")
    current_state = state_mgr.get_current_state()
    print(json.dumps(current_state.to_dict(), indent=2, default=str))

    # Get agent-specific view
    print("\n=== AGENT 1 VIEW ===")
    agent_view = state_mgr.get_agent_view("agent_1")
    print(json.dumps(agent_view, indent=2, default=str))

    # Get event history
    print("\n=== EVENT HISTORY (Agent 1) ===")
    history = state_mgr.get_event_history("agent_1")
    for event in history:
        print(f"{event.timestamp}: {event.event_type.value} - {event.data}")

    # Demonstrate event replay
    print("\n=== EVENT REPLAY ===")
    print(f"Total events: {len(state_mgr.event_store.events)}")
    print("Replaying events to rebuild state...")

    rebuilt_state = state_mgr.get_current_state()
    print(f"Agents in state: {list(rebuilt_state.agents.keys())}")
    print(f"Tasks in state: {list(rebuilt_state.tasks.keys())}")
    print(f"Messages: {len(rebuilt_state.messages)}")
```

---

## Example 6: Lifecycle Management

Agent registration, health monitoring, and auto-scaling.

**Pattern**: [PATTERNS.md - Pattern 6](./PATTERNS.md#pattern-6-lifecycle-management)

#!/usr/bin/env python3
"""
agent_lifecycle.py - Agent lifecycle management and health monitoring
"""

from dataclasses import dataclass, field
from typing import Dict, List, Optional, Callable
from datetime import datetime, timedelta
from enum import Enum
import asyncio
import time

class AgentStatus(Enum):
    REGISTERED = "registered"
    ACTIVE = "active"
    IDLE = "idle"
    BUSY = "busy"
    DEGRADED = "degraded"
    OFFLINE = "offline"
    TERMINATED = "terminated"

@dataclass
class AgentMetrics:
    """Agent performance metrics"""
    tasks_completed: int = 0
    tasks_failed: int = 0
    average_response_time: float = 0.0
    last_heartbeat: Optional[datetime] = None
    uptime_seconds: float = 0.0
    cpu_percent: float = 0.0
    memory_mb: float = 0.0
    error_rate: float = 0.0

@dataclass
class AgentInfo:
    """Agent registration information"""
    agent_id: str
    agent_type: str
    capabilities: List[str]
    max_concurrent_tasks: int
    current_tasks: int = 0
    status: AgentStatus = AgentStatus.REGISTERED
    registered_at: datetime = field(default_factory=datetime.now)
    metrics: AgentMetrics = field(default_factory=AgentMetrics)
    metadata: Dict[str, any] = field(default_factory=dict)

class HealthChecker:
    """Check agent health and detect failures"""

    def __init__(self, heartbeat_interval: int = 30, heartbeat_timeout: int = 60):
        self.heartbeat_interval = heartbeat_interval
        self.heartbeat_timeout = heartbeat_timeout

    def is_healthy(self, agent: AgentInfo) -> bool:
        """Check if agent is healthy"""

        # Check heartbeat
        if not agent.metrics.last_heartbeat:
            return False

        time_since_heartbeat = (datetime.now() - agent.metrics.last_heartbeat).total_seconds()

        if time_since_heartbeat > self.heartbeat_timeout:
            return False

        # Check error rate
        if agent.metrics.error_rate > 0.5:  # More than 50% errors
            return False

        # Check status
        if agent.status == AgentStatus.OFFLINE:
            return False

        return True

    def health_score(self, agent: AgentInfo) -> float:
        """Calculate health score 0.0 to 1.0"""

        score = 1.0

        # Deduct for stale heartbeat
        if agent.metrics.last_heartbeat:
            time_since_heartbeat = (datetime.now() - agent.metrics.last_heartbeat).total_seconds()
            if time_since_heartbeat > self.heartbeat_timeout:
                score -= 0.5
            elif time_since_heartbeat > self.heartbeat_interval:
                score -= 0.2
        else:
            score -= 0.5

        # Deduct for high error rate
        score -= agent.metrics.error_rate * 0.3

        # Deduct for high load
        if agent.current_tasks >= agent.max_concurrent_tasks:
            score -= 0.2

        # Deduct for offline status
        if agent.status == AgentStatus.OFFLINE:
            score = 0.0

        return max(0.0, min(1.0, score))

class AgentRegistry:
    """Central registry for agent lifecycle management"""

    def __init__(self):
        self.agents: Dict[str, AgentInfo] = {}
        self.health_checker = HealthChecker()
        self._monitoring_task = None

    def register(self, agent: AgentInfo):
        """Register new agent"""
        self.agents[agent.agent_id] = agent
        agent.status = AgentStatus.ACTIVE
        agent.metrics.last_heartbeat = datetime.now()

        print(f"Registered agent: {agent.agent_id} (type: {agent.agent_type})")

    def unregister(self, agent_id: str):
        """Unregister agent"""
        if agent_id in self.agents:
            self.agents[agent_id].status = AgentStatus.TERMINATED
            print(f"Unregistered agent: {agent_id}")

    def heartbeat(self, agent_id: str, metrics: Optional[AgentMetrics] = None):
        """Update agent heartbeat"""
        if agent_id in self.agents:
            agent = self.agents[agent_id]
            agent.metrics.last_heartbeat = datetime.now()

            if metrics:
                agent.metrics = metrics

            # Update status based on health
            if self.health_checker.is_healthy(agent):
                if agent.status == AgentStatus.DEGRADED:
                    agent.status = AgentStatus.ACTIVE
            else:
                agent.status = AgentStatus.DEGRADED

    def update_status(self, agent_id: str, status: AgentStatus):
        """Update agent status"""
        if agent_id in self.agents:
            self.agents[agent_id].status = status

    def get_agent(self, agent_id: str) -> Optional[AgentInfo]:
        """Get agent info"""
        return self.agents.get(agent_id)

    def find_agents(
        self,
        agent_type: Optional[str] = None,
        capability: Optional[str] = None,
        status: Optional[AgentStatus] = None,
        min_health_score: float = 0.0
    ) -> List[AgentInfo]:
        """Find agents matching criteria"""

        candidates = list(self.agents.values())

        if agent_type:
            candidates = [a for a in candidates if a.agent_type == agent_type]

        if capability:
            candidates = [a for a in candidates if capability in a.capabilities]

        if status:
            candidates = [a for a in candidates if a.status == status]

        # Filter by health
        candidates = [
            a for a in candidates
            if self.health_checker.health_score(a) >= min_health_score
        ]

        return candidates

    def get_available_agent(
        self,
        agent_type: Optional[str] = None,
        capability: Optional[str] = None
    ) -> Optional[AgentInfo]:
        """Get available agent for task"""

        # Find healthy, idle agents
        candidates = self.find_agents(
            agent_type=agent_type,
            capability=capability,
            min_health_score=0.5
        )

        # Filter by availability
        available = [
            a for a in candidates
            if a.current_tasks < a.max_concurrent_tasks
            and a.status in [AgentStatus.ACTIVE, AgentStatus.IDLE]
        ]

        if not available:
            return None

        # Pick least loaded
        return min(available, key=lambda a: a.current_tasks / a.max_concurrent_tasks)

    def get_registry_status(self) -> Dict[str, any]:
        """Get overall registry status"""

        total = len(self.agents)
        by_status = {}

        for agent in self.agents.values():
            status = agent.status.value
            by_status[status] = by_status.get(status, 0) + 1

        healthy = sum(1 for a in self.agents.values() if self.health_checker.is_healthy(a))

        return {
            "total_agents": total,
            "healthy_agents": healthy,
            "by_status": by_status,
            "health_percentage": healthy / total * 100 if total > 0 else 0
        }

    async def start_monitoring(self, check_interval: int = 30):
        """Start background health monitoring"""

        async def monitor():
            while True:
                await asyncio.sleep(check_interval)
                await self._check_agent_health()

        self._monitoring_task = asyncio.create_task(monitor())
        print("Started agent health monitoring")

    async def _check_agent_health(self):
        """Check health of all agents"""

        for agent_id, agent in list(self.agents.items()):
            is_healthy = self.health_checker.is_healthy(agent)

            if not is_healthy and agent.status != AgentStatus.OFFLINE:
                print(f"ALERT: Agent {agent_id} is unhealthy (status: {agent.status.value})")
                agent.status = AgentStatus.DEGRADED

            # Check for dead agents
            if agent.metrics.last_heartbeat:
                time_since_heartbeat = (datetime.now() - agent.metrics.last_heartbeat).total_seconds()

                if time_since_heartbeat > 300:  # 5 minutes
                    print(f"ALERT: Agent {agent_id} appears dead, marking offline")
                    agent.status = AgentStatus.OFFLINE

class AgentPool:
    """Pool of agents with auto-scaling"""

    def __init__(
        self,
        registry: AgentRegistry,
        agent_factory: Callable[[int], AgentInfo],
        min_agents: int = 2,
        max_agents: int = 10
    ):
        self.registry = registry
        self.agent_factory = agent_factory
        self.min_agents = min_agents
        self.max_agents = max_agents
        self.agent_count = 0

    def initialize(self):
        """Initialize pool with minimum agents"""
        for i in range(self.min_agents):
            agent = self.agent_factory(i)
            self.registry.register(agent)
            self.agent_count += 1

    def scale_up(self, count: int = 1):
        """Add agents to pool"""
        for i in range(count):
            if self.agent_count >= self.max_agents:
                print(f"Cannot scale up: at max agents ({self.max_agents})")
                break

            agent = self.agent_factory(self.agent_count)
            self.registry.register(agent)
            self.agent_count += 1
            print(f"Scaled up: added agent {agent.agent_id}")

    def scale_down(self, count: int = 1):
        """Remove agents from pool"""
        # Find idle agents to remove
        idle_agents = self.registry.find_agents(status=AgentStatus.IDLE)

        removed = 0
        for agent in idle_agents:
            if removed >= count:
                break

            if self.agent_count <= self.min_agents:
                print(f"Cannot scale down: at min agents ({self.min_agents})")
                break

            self.registry.unregister(agent.agent_id)
            self.agent_count -= 1
            removed += 1
            print(f"Scaled down: removed agent {agent.agent_id}")

    def auto_scale(self):
        """Auto-scale based on load"""
        status = self.registry.get_registry_status()

        # Calculate average load
        total_load = sum(
            a.current_tasks / a.max_concurrent_tasks
            for a in self.registry.agents.values()
        )
        avg_load = total_load / len(self.registry.agents) if self.registry.agents else 0

        print(f"Auto-scale check: avg_load={avg_load:.2f}")

        # Scale up if load > 70%
        if avg_load > 0.7:
            self.scale_up(1)

        # Scale down if load < 20%
        elif avg_load < 0.2 and self.agent_count > self.min_agents:
            self.scale_down(1)

# Example usage
if __name__ == "__main__":
    # Create registry
    registry = AgentRegistry()

    # Agent factory
    def create_agent(idx: int) -> AgentInfo:
        return AgentInfo(
            agent_id=f"agent_{idx}",
            agent_type="worker",
            capabilities=["task_execution", "data_processing"],
            max_concurrent_tasks=3
        )

    # Create agent pool
    pool = AgentPool(registry, create_agent, min_agents=2, max_agents=5)
    pool.initialize()

    # Simulate agent lifecycle
    print("\n=== Initial State ===")
    print(registry.get_registry_status())

    # Simulate agent activity
    print("\n=== Simulating Activity ===")

    # Agent 0 sends heartbeat
    registry.heartbeat("agent_0", AgentMetrics(
        tasks_completed=5,
        average_response_time=1.2,
        last_heartbeat=datetime.now()
    ))

    # Agent 1 becomes busy
    agent_1 = registry.get_agent("agent_1")
    agent_1.current_tasks = 3
    registry.update_status("agent_1", AgentStatus.BUSY)

    # Check if we need to scale
    print("\n=== Auto-scale Check ===")
    pool.auto_scale()

    print("\n=== Final State ===")
    print(registry.get_registry_status())

    # List all agents
    print("\n=== All Agents ===")
    for agent in registry.agents.values():
        health = registry.health_checker.health_score(agent)
        print(f"{agent.agent_id}: {agent.status.value} (health: {health:.2f})")
```

---

[← Back to Main](./SKILL.md) | [View Patterns →](./PATTERNS.md)
