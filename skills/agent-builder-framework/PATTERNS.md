# Agent Builder Framework - Implementation Patterns

## Pattern 1: Agent Specification Design

### Purpose
Create complete, unambiguous agent specifications that prevent scope creep and enable testability.

### Structure
```yaml
# Agent Specification Template
metadata:
  name: string                    # Unique agent identifier (kebab-case)
  version: string                 # Semantic version (e.g., "1.0.0")
  description: string             # One-sentence purpose
  created: date                   # Creation timestamp
  author: string                  # Creator identifier

role:
  primary: string                 # Main responsibility (one sentence)
  responsibilities:               # Specific duties
    - string
    - string
  out_of_scope:                   # What agent should NOT do
    - string
    - string

capabilities:                     # High-level abilities
  - name: string
    description: string
    priority: critical|high|medium|low

tools:                           # Specific tools/APIs
  - name: string
    purpose: string
    required: boolean

inputs:                          # What agent receives
  - name: string
    type: string
    description: string
    required: boolean
    validation: string           # Validation rules
    example: any

outputs:                         # What agent produces
  - name: string
    type: string
    description: string
    format: string               # Output format (json, markdown, etc.)
    schema: object               # JSON schema if applicable

constraints:
  max_execution_time: duration   # e.g., "300s"
  max_cost: float               # e.g., 0.50 (USD)
  max_tokens: integer           # LLM token limit
  allowed_operations:           # Permitted actions
    - string
  forbidden_operations:         # Prohibited actions
    - string
  resource_limits:
    memory: string              # e.g., "512MB"
    cpu: string                 # e.g., "1 core"
    disk: string                # e.g., "1GB"

success_criteria:                # How to measure success
  - metric: string
    description: string
    threshold: value
    measurement: string          # How to measure

error_handling:
  retry_policy:
    max_attempts: integer
    backoff: exponential|linear|fixed
    initial_delay: duration
  failure_modes:
    - condition: string
      action: string
  fallback_strategy: string

dependencies:                    # Other agents or services
  - name: string
    type: agent|service|api
    required: boolean
    purpose: string

context_requirements:            # Required context
  - name: string
    type: string
    source: string

performance_targets:
  latency_p50: duration
  latency_p99: duration
  throughput: string             # e.g., "10 requests/second"
  success_rate: float            # e.g., 0.99
```

### Implementation

```python
# agent_specification.py

import re
from dataclasses import dataclass
from typing import List, Dict, Any, Optional
from datetime import datetime

@dataclass
class Capability:
    name: str
    description: str
    priority: str  # critical, high, medium, low

@dataclass
class Tool:
    name: str
    purpose: str
    required: bool

@dataclass
class InputSpec:
    name: str
    type: str
    description: str
    required: bool
    validation: Optional[str] = None
    example: Optional[Any] = None

@dataclass
class OutputSpec:
    name: str
    type: str
    description: str
    format: str
    schema: Optional[Dict] = None

@dataclass
class Constraints:
    max_execution_time: str
    max_cost: float
    max_tokens: int
    allowed_operations: List[str]
    forbidden_operations: List[str]
    resource_limits: Dict[str, str]

@dataclass
class SuccessCriterion:
    metric: str
    description: str
    threshold: Any
    measurement: str

@dataclass
class AgentSpecification:
    # Metadata
    name: str
    version: str
    description: str
    created: datetime
    author: str

    # Role definition
    primary_role: str
    responsibilities: List[str]
    out_of_scope: List[str]

    # Capabilities and tools
    capabilities: List[Capability]
    tools: List[Tool]

    # Interface
    inputs: List[InputSpec]
    outputs: List[OutputSpec]

    # Constraints
    constraints: Constraints

    # Success criteria
    success_criteria: List[SuccessCriterion]

    # Error handling
    error_handling: Optional[Dict[str, Any]] = None

    # Optional fields
    dependencies: List[Dict[str, Any]] = None
    context_requirements: List[Dict[str, Any]] = None
    performance_targets: Dict[str, Any] = None

    def validate(self) -> List[str]:
        """Validate specification completeness and consistency."""
        errors = []

        if not self.name or not re.match(r'^[a-z0-9]+(?:-[a-z0-9]+)*$', self.name):
            errors.append("Name must be non-empty kebab-case (e.g., 'my-agent')")

        if not self.primary_role:
            errors.append("Primary role must be defined")

        if not self.capabilities:
            errors.append("At least one capability required")

        if len(self.capabilities) > 10:
            errors.append("Too many capabilities (>10). Consider splitting agent.")

        if not self.tools:
            errors.append("At least one tool required")

        if not self.inputs:
            errors.append("At least one input required")

        if not self.outputs:
            errors.append("At least one output required")

        if not self.success_criteria:
            errors.append("At least one success criterion required")

        return errors

    def to_yaml(self) -> str:
        """Export specification as YAML."""
        import yaml
        return yaml.dump(self.__dict__)

    @classmethod
    def from_yaml(cls, yaml_str: str) -> 'AgentSpecification':
        """Load specification from YAML."""
        import yaml
        data = yaml.safe_load(yaml_str)
        return cls(**data)
```

### Example: Security Auditor Specification

```yaml
metadata:
  name: security-auditor
  version: 1.0.0
  description: Automated security vulnerability scanning and reporting
  created: 2025-10-27
  author: ai-engineer

role:
  primary: Perform comprehensive security audits on codebases
  responsibilities:
    - Execute SAST (static application security testing)
    - Run DAST (dynamic application security testing)
    - Scan dependencies for known vulnerabilities
    - Detect exposed secrets and credentials
    - Generate security reports
  out_of_scope:
    - Fixing vulnerabilities (only detection)
    - Penetration testing against production
    - Manual code review

capabilities:
  - name: static-analysis
    description: Analyze source code for security issues
    priority: critical
  - name: dynamic-analysis
    description: Test running application for vulnerabilities
    priority: high
  - name: dependency-scanning
    description: Check dependencies for known CVEs
    priority: critical
  - name: secret-detection
    description: Find exposed credentials in code
    priority: critical
  - name: report-generation
    description: Create formatted security reports
    priority: high

tools:
  - name: bandit
    purpose: Python SAST scanner
    required: true
  - name: semgrep
    purpose: Multi-language SAST
    required: true
  - name: safety
    purpose: Python dependency vulnerability scanner
    required: true
  - name: trufflehog
    purpose: Secret detection tool
    required: true
  - name: report-builder
    purpose: Generate HTML/JSON reports
    required: true

inputs:
  - name: repository_path
    type: string
    description: Path to codebase to audit
    required: true
    validation: "must exist and be readable"
    example: "/path/to/repo"
  - name: scan_types
    type: array[string]
    description: Types of scans to perform
    required: false
    validation: "must be subset of [sast, dast, dependencies, secrets]"
    example: ["sast", "dependencies"]
  - name: output_format
    type: string
    description: Report format
    required: false
    validation: "must be one of [json, html, markdown]"
    example: "html"

outputs:
  - name: security_report
    type: object
    description: Comprehensive security audit results
    format: json
    schema:
      type: object
      properties:
        summary:
          type: object
          properties:
            total_issues: integer
            critical: integer
            high: integer
            medium: integer
            low: integer
        findings:
          type: array
          items:
            type: object
            properties:
              severity: string
              category: string
              description: string
              location: string
              remediation: string

constraints:
  max_execution_time: "600s"
  max_cost: 1.00
  max_tokens: 10000
  allowed_operations:
    - read_files
    - execute_security_tools
    - generate_reports
  forbidden_operations:
    - modify_code
    - deploy_changes
    - access_production
  resource_limits:
    memory: "2GB"
    cpu: "2 cores"
    disk: "5GB"

success_criteria:
  - metric: scan_completion
    description: All requested scans completed
    threshold: 100%
    measurement: "percentage of scans finished"
  - metric: report_generated
    description: Valid report produced
    threshold: true
    measurement: "report validates against schema"
  - metric: execution_time
    description: Completed within time limit
    threshold: 600s
    measurement: "actual execution time"

error_handling:
  retry_policy:
    max_attempts: 3
    backoff: exponential
    initial_delay: 5s
  failure_modes:
    - condition: "tool not found"
      action: "skip scan, log warning, continue"
    - condition: "timeout exceeded"
      action: "return partial results"
    - condition: "repository not accessible"
      action: "fail immediately with error"
  fallback_strategy: "return partial results with warnings"

dependencies:
  - name: security-tools
    type: service
    required: true
    purpose: "SAST/DAST tools installation"

performance_targets:
  latency_p50: "120s"
  latency_p99: "300s"
  throughput: "1 scan per 2 minutes"
  success_rate: 0.95
```

### When to Use
- Creating any new agent
- Refactoring existing agent
- Documenting agent behavior
- Planning multi-agent systems

## Pattern 2: Capability-Tool Mapping

### Purpose
Map high-level agent capabilities to specific tools, ensuring complete coverage and traceability.

### Process

**Step 1: Extract Capabilities**
```python
def extract_capabilities(requirements: str) -> List[Capability]:
    """Extract high-level capabilities from requirements."""
    capabilities = []
    # Parse requirements and identify key capabilities
    # Example: "security audit" -> [static-analysis, dynamic-analysis, ...]
    return capabilities
```

**Step 2: Categorize Tools**
```python
# Tool categories
tool_categories = {
    "file_operations": ["Read", "Write", "Edit", "Glob"],
    "code_analysis": ["Grep", "AST parsers", "linters"],
    "execution": ["Bash", "Docker", "subprocess"],
    "communication": ["HTTP client", "WebSocket"],
    "data_processing": ["pandas", "json", "yaml"],
    "security": ["bandit", "semgrep", "safety"],
    "testing": ["pytest", "unittest", "selenium"],
    "deployment": ["kubectl", "terraform", "ansible"]
}
```

**Step 3: Map Capabilities to Tools**
```python
def map_capabilities_to_tools(
    capabilities: List[Capability],
    available_tools: Dict[str, List[str]]
) -> Dict[Capability, List[str]]:
    """Map each capability to required tools."""
    mapping = {}

    for capability in capabilities:
        tools = []

        if capability.name == "static-analysis":
            tools = available_tools["security"] + available_tools["code_analysis"]
        elif capability.name == "dependency-scanning":
            tools = ["safety", "npm-audit", "bundle-audit"]
        elif capability.name == "report-generation":
            tools = available_tools["file_operations"] + ["jinja2", "markdown"]

        mapping[capability] = tools

    return mapping
```

**Step 4: Validate Coverage**
```python
def validate_tool_coverage(
    capabilities: List[Capability],
    mapping: Dict[Capability, List[str]]
) -> List[str]:
    """Ensure all capabilities have tool coverage."""
    gaps = []

    for capability in capabilities:
        if capability not in mapping or not mapping[capability]:
            gaps.append(f"No tools for capability: {capability.name}")

    return gaps
```

### Implementation Template

```python
# capability_tool_mapper.py

from typing import Dict, List, Set
from dataclasses import dataclass

@dataclass
class ToolRequirement:
    tool_name: str
    purpose: str
    alternatives: List[str]
    required: bool

class CapabilityToolMapper:
    def __init__(self, tool_registry: Dict[str, Dict]):
        self.tool_registry = tool_registry

    def map_capability(self, capability: Capability) -> List[ToolRequirement]:
        """Map a single capability to tools."""
        # Lookup capability in knowledge base
        tool_requirements = []

        # Example: static-analysis capability
        if capability.name == "static-analysis":
            tool_requirements.append(ToolRequirement(
                tool_name="semgrep",
                purpose="Multi-language SAST",
                alternatives=["bandit", "eslint"],
                required=True
            ))
            tool_requirements.append(ToolRequirement(
                tool_name="Read",
                purpose="Read source files",
                alternatives=[],
                required=True
            ))

        return tool_requirements

    def generate_tool_list(
        self,
        capabilities: List[Capability]
    ) -> List[ToolRequirement]:
        """Generate complete tool list for all capabilities."""
        all_tools = []
        seen_tools = set()

        for capability in capabilities:
            tools = self.map_capability(capability)
            for tool in tools:
                if tool.tool_name not in seen_tools:
                    all_tools.append(tool)
                    seen_tools.add(tool.tool_name)

        return all_tools

    def validate_tools_available(
        self,
        required_tools: List[ToolRequirement]
    ) -> List[str]:
        """Check if all required tools are available."""
        missing = []

        for tool_req in required_tools:
            if tool_req.required:
                if tool_req.tool_name not in self.tool_registry:
                    # Check alternatives
                    alternatives_available = any(
                        alt in self.tool_registry
                        for alt in tool_req.alternatives
                    )
                    if not alternatives_available:
                        missing.append(tool_req.tool_name)

        return missing
```

### Example: Security Auditor Mapping

```python
capability_tool_map = {
    "static-analysis": {
        "tools": ["semgrep", "bandit", "Read", "Grep"],
        "workflow": [
            "Read source files",
            "Run semgrep with security rules",
            "Run bandit on Python files",
            "Parse results",
            "Aggregate findings"
        ]
    },
    "dependency-scanning": {
        "tools": ["safety", "npm-audit", "Read", "Bash"],
        "workflow": [
            "Read requirements.txt / package.json",
            "Run safety check / npm audit",
            "Parse vulnerability reports",
            "Map CVEs to dependencies"
        ]
    },
    "secret-detection": {
        "tools": ["trufflehog", "Grep", "Read"],
        "workflow": [
            "Read all text files",
            "Run trufflehog entropy scan",
            "Grep for common secret patterns",
            "Deduplicate findings"
        ]
    },
    "report-generation": {
        "tools": ["Write", "jinja2"],
        "workflow": [
            "Aggregate all findings",
            "Render report template",
            "Write to output file"
        ]
    }
}
```

### When to Use
- During agent design phase
- When adding new capabilities
- When debugging missing functionality
- For documentation

## Pattern 3: Behavior Testing & Validation

### Purpose
Ensure agent behaves correctly through comprehensive testing at multiple levels.

### Testing Pyramid

```
        /\
       /  \  Acceptance Tests (few, slow, high confidence)
      /____\
     /      \  Integration Tests (moderate, medium speed)
    /________\
   /          \  Unit Tests (many, fast, low-level)
  /__________  \
```

### Unit Tests

```python
# tests/unit/test_security_auditor.py

import pytest
from security_auditor import SecurityAuditor

class TestSecurityAuditor:
    def test_parse_semgrep_output(self):
        """Test parsing semgrep JSON output."""
        auditor = SecurityAuditor()
        raw_output = {
            "results": [
                {
                    "check_id": "python.lang.security.sqli",
                    "path": "app.py",
                    "start": {"line": 10},
                    "extra": {"severity": "ERROR"}
                }
            ]
        }

        findings = auditor.parse_semgrep_output(raw_output)

        assert len(findings) == 1
        assert findings[0]["severity"] == "high"
        assert findings[0]["category"] == "sql-injection"
        assert findings[0]["location"] == "app.py:10"

    def test_aggregate_findings_deduplicates(self):
        """Test that duplicate findings are removed."""
        auditor = SecurityAuditor()
        findings = [
            {"id": "1", "description": "SQL injection"},
            {"id": "1", "description": "SQL injection"},
            {"id": "2", "description": "XSS vulnerability"}
        ]

        aggregated = auditor.aggregate_findings(findings)

        assert len(aggregated) == 2

    def test_calculate_severity_score(self):
        """Test severity scoring."""
        auditor = SecurityAuditor()
        findings = [
            {"severity": "critical"},
            {"severity": "high"},
            {"severity": "medium"}
        ]

        score = auditor.calculate_severity_score(findings)

        assert score > 0
        assert isinstance(score, float)
```

### Integration Tests

```python
# tests/integration/test_security_auditor_integration.py

import pytest
import tempfile
import os

class TestSecurityAuditorIntegration:
    @pytest.fixture
    def test_repo(self):
        """Create test repository with vulnerabilities."""
        with tempfile.TemporaryDirectory() as tmpdir:
            # Create vulnerable Python file
            vulnerable_code = '''
import sqlite3
def get_user(username):
    conn = sqlite3.connect("db.sqlite")
    cursor = conn.cursor()
    query = f"SELECT * FROM users WHERE name = '{username}'"
    cursor.execute(query)  # SQL injection
    return cursor.fetchone()
'''
            with open(os.path.join(tmpdir, "app.py"), "w") as f:
                f.write(vulnerable_code)

            # Create requirements.txt with vulnerable dependency
            with open(os.path.join(tmpdir, "requirements.txt"), "w") as f:
                f.write("django==2.0.0\\n")  # Old vulnerable version

            yield tmpdir

    def test_sast_scan_finds_sql_injection(self, test_repo):
        """Test SAST scan detects SQL injection."""
        auditor = SecurityAuditor()
        results = auditor.run_sast_scan(test_repo)

        assert results["status"] == "completed"
        assert any(
            "sql" in finding["category"].lower()
            for finding in results["findings"]
        )

    def test_dependency_scan_finds_vulnerable_packages(self, test_repo):
        """Test dependency scan detects vulnerable Django."""
        auditor = SecurityAuditor()
        results = auditor.run_dependency_scan(test_repo)

        assert results["status"] == "completed"
        assert any(
            "django" in finding["package"].lower()
            for finding in results["vulnerabilities"]
        )

    def test_full_audit_generates_report(self, test_repo):
        """Test complete audit workflow."""
        auditor = SecurityAuditor(output_format="json")
        report = auditor.run_full_audit(test_repo)

        assert report["summary"]["total_issues"] > 0
        assert "sast" in report["scans_completed"]
        assert "dependencies" in report["scans_completed"]
        assert os.path.exists(report["report_path"])
```

### Acceptance Tests

```python
# tests/acceptance/test_security_auditor_scenarios.py

import pytest

class TestSecurityAuditorScenarios:
    def test_scenario_audit_python_web_app(self):
        """
        Scenario: Security audit of Python web application
        Given: A Python Flask application with known vulnerabilities
        When: Full security audit is performed
        Then: Report contains SAST, dependency, and secret scan results
        """
        # Setup
        project = setup_flask_app_with_vulnerabilities()
        auditor = SecurityAuditor()

        # Execute
        report = auditor.run_full_audit(project)

        # Verify
        assert report["status"] == "completed"
        assert report["summary"]["total_issues"] >= 3
        assert any(f["category"] == "sql-injection" for f in report["findings"])
        assert any(v["package"] == "flask" for v in report["vulnerabilities"])
        assert report["scans_completed"] == ["sast", "dependencies", "secrets"]

    def test_scenario_timeout_handling(self):
        """
        Scenario: Audit times out on large repository
        Given: A very large codebase
        When: Audit runs with strict timeout
        Then: Partial results returned with timeout indication
        """
        large_project = create_large_project(files=10000)
        auditor = SecurityAuditor(timeout=10)  # 10 seconds

        report = auditor.run_full_audit(large_project)

        assert report["status"] == "timeout"
        assert "partial_results" in report
        assert report["scans_completed"] != report["scans_requested"]

    def test_scenario_no_vulnerabilities_found(self):
        """
        Scenario: Audit clean codebase
        Given: A secure, well-maintained project
        When: Full audit performed
        Then: Report shows zero issues
        """
        clean_project = create_secure_project()
        auditor = SecurityAuditor()

        report = auditor.run_full_audit(clean_project)

        assert report["status"] == "completed"
        assert report["summary"]["total_issues"] == 0
```

### Property-Based Testing

```python
# tests/property/test_security_auditor_properties.py

from hypothesis import given, strategies as st
import pytest

class TestSecurityAuditorProperties:
    @given(st.text(), st.lists(st.text()))
    def test_never_crashes_on_arbitrary_input(self, path, scan_types):
        """Agent should never crash regardless of input."""
        auditor = SecurityAuditor()

        try:
            result = auditor.run_full_audit(path, scan_types=scan_types)
            assert "status" in result
        except Exception as e:
            pytest.fail(f"Agent crashed: {e}")

    @given(st.integers(min_value=1, max_value=1000))
    def test_timeout_always_respected(self, timeout):
        """Agent must respect timeout constraints."""
        import time
        auditor = SecurityAuditor(timeout=timeout)

        start = time.time()
        result = auditor.run_full_audit(large_project)
        elapsed = time.time() - start

        assert elapsed <= timeout * 1.2  # 20% grace period
```

### When to Use
- During agent development
- Before deploying agents
- For regression testing
- When adding new capabilities

## Pattern 4: Multi-Agent Coordination Protocols

### Purpose
Enable reliable communication and collaboration between multiple agents.

### Protocol Structure

```python
# coordination_protocol.py

from dataclasses import dataclass
from typing import Any, Callable, Optional
from enum import Enum

class HandoffStatus(Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    FAILED = "failed"
    TIMEOUT = "timeout"

@dataclass
class HandoffProtocol:
    """Protocol for agent-to-agent handoff."""
    # Identification
    protocol_id: str
    sender_agent: str
    receiver_agent: str

    # Trigger
    trigger_condition: str
    trigger_check: Callable[[], bool]

    # Payload
    payload_schema: dict
    payload_data: Any

    # Acknowledgment
    requires_ack: bool
    ack_timeout: float  # seconds

    # Error handling
    max_retries: int
    retry_delay: float
    fallback_action: Optional[Callable] = None

    # State
    status: HandoffStatus = HandoffStatus.PENDING
    attempts: int = 0

class CoordinationProtocol:
    """Base class for multi-agent coordination."""

    def __init__(self):
        self.active_handoffs = {}
        self.handoff_history = []

    def initiate_handoff(
        self,
        protocol: HandoffProtocol
    ) -> str:
        """Initiate handoff from one agent to another."""
        # Validate protocol
        if not self._validate_protocol(protocol):
            raise ValueError("Invalid handoff protocol")

        # Check trigger condition
        if not protocol.trigger_check():
            return "trigger_not_met"

        # Validate payload against schema
        if not self._validate_payload(protocol.payload_data, protocol.payload_schema):
            raise ValueError("Payload doesn't match schema")

        # Execute handoff
        protocol.status = HandoffStatus.IN_PROGRESS
        self.active_handoffs[protocol.protocol_id] = protocol

        try:
            result = self._execute_handoff(protocol)
            protocol.status = HandoffStatus.COMPLETED
            return result
        except Exception as e:
            protocol.status = HandoffStatus.FAILED
            return self._handle_handoff_failure(protocol, e)

    def _execute_handoff(self, protocol: HandoffProtocol) -> str:
        """Execute the actual handoff."""
        # Send payload to receiver
        self._send_to_agent(
            protocol.receiver_agent,
            protocol.payload_data
        )

        # Wait for acknowledgment if required
        if protocol.requires_ack:
            ack = self._wait_for_ack(
                protocol.receiver_agent,
                protocol.ack_timeout
            )
            if not ack:
                raise TimeoutError("No acknowledgment received")

        return "handoff_completed"

    def _handle_handoff_failure(
        self,
        protocol: HandoffProtocol,
        error: Exception
    ) -> str:
        """Handle failed handoff with retries."""
        protocol.attempts += 1

        if protocol.attempts < protocol.max_retries:
            # Retry with backoff (consider exponential backoff for better resilience)
            time.sleep(protocol.retry_delay * protocol.attempts)
            return self.initiate_handoff(protocol)
        else:
            # Execute fallback
            if protocol.fallback_action:
                protocol.fallback_action()
            return "handoff_failed"
```

### Coordination Patterns

#### Pattern 4a: Sequential Handoff

```python
def create_sequential_pipeline(agents: List[str]) -> CoordinationGraph:
    """Create sequential agent pipeline."""
    graph = CoordinationGraph()

    for i in range(len(agents) - 1):
        protocol = HandoffProtocol(
            protocol_id=f"handoff_{i}",
            sender_agent=agents[i],
            receiver_agent=agents[i + 1],
            trigger_condition=f"{agents[i]}_completed",
            trigger_check=lambda: check_agent_completed(agents[i]),
            payload_schema={"results": "object"},
            payload_data=None,  # Set at runtime
            requires_ack=True,
            ack_timeout=30.0,
            max_retries=3,
            retry_delay=5.0
        )
        graph.add_handoff(protocol)

    return graph
```

#### Pattern 4b: Parallel Coordination

```python
def create_parallel_coordination(
    coordinator: str,
    workers: List[str]
) -> CoordinationGraph:
    """Coordinate multiple agents in parallel."""
    graph = CoordinationGraph()

    # Coordinator distributes work
    for worker in workers:
        distribute_protocol = HandoffProtocol(
            protocol_id=f"distribute_to_{worker}",
            sender_agent=coordinator,
            receiver_agent=worker,
            trigger_condition="work_available",
            trigger_check=lambda: True,
            payload_schema={"task": "object"},
            payload_data=None,
            requires_ack=True,
            ack_timeout=10.0,
            max_retries=2,
            retry_delay=3.0
        )
        graph.add_handoff(distribute_protocol)

    # Workers report back
    for worker in workers:
        report_protocol = HandoffProtocol(
            protocol_id=f"report_from_{worker}",
            sender_agent=worker,
            receiver_agent=coordinator,
            trigger_condition=f"{worker}_completed",
            trigger_check=lambda: check_agent_completed(worker),
            payload_schema={"results": "object"},
            payload_data=None,
            requires_ack=False,
            ack_timeout=0,
            max_retries=3,
            retry_delay=5.0
        )
        graph.add_handoff(report_protocol)

    return graph
```

#### Pattern 4c: Conditional Routing

```python
def create_conditional_router(
    router_agent: str,
    specialists: Dict[str, str]
) -> CoordinationGraph:
    """Route work to specialists based on conditions."""
    graph = CoordinationGraph()

    def route_condition(specialist_type: str) -> Callable:
        return lambda state: state["work_type"] == specialist_type

    for specialist_type, specialist_agent in specialists.items():
        protocol = HandoffProtocol(
            protocol_id=f"route_to_{specialist_agent}",
            sender_agent=router_agent,
            receiver_agent=specialist_agent,
            trigger_condition=f"work_type_{specialist_type}",
            trigger_check=route_condition(specialist_type),
            payload_schema={"work": "object"},
            payload_data=None,
            requires_ack=True,
            ack_timeout=20.0,
            max_retries=2,
            retry_delay=5.0
        )
        graph.add_handoff(protocol)

    return graph
```

### Conflict Resolution

```python
class ConflictResolver:
    """Resolve conflicts between multiple agents."""

    def resolve_priority_conflict(
        self,
        conflicting_actions: List[Dict]
    ) -> Dict:
        """Resolve conflict using priority."""
        return max(conflicting_actions, key=lambda a: a["priority"])

    def resolve_voting_conflict(
        self,
        agents: List[str],
        proposals: List[Dict]
    ) -> Dict:
        """Resolve conflict through voting."""
        votes = {}
        for agent in agents:
            vote = self._get_agent_vote(agent, proposals)
            votes[vote] = votes.get(vote, 0) + 1

        winning_proposal = max(votes.items(), key=lambda x: x[1])[0]
        return next(p for p in proposals if p["id"] == winning_proposal)

    def resolve_negotiation_conflict(
        self,
        agent_a: str,
        agent_b: str,
        conflict: Dict
    ) -> Dict:
        """Resolve conflict through negotiation."""
        rounds = 0
        max_rounds = 5

        while rounds < max_rounds:
            proposal_a = self._get_proposal(agent_a, conflict)
            proposal_b = self._get_proposal(agent_b, conflict)

            if self._proposals_compatible(proposal_a, proposal_b):
                return self._merge_proposals(proposal_a, proposal_b)

            rounds += 1

        # No agreement, use arbitration
        return self._arbitrate(agent_a, agent_b, conflict)
```

### When to Use
- Multi-agent systems
- Agent handoff requirements
- Parallel processing needs
- Complex workflows

## Pattern 5: Agent Lifecycle Management

### Purpose
Manage agent states throughout initialization, execution, monitoring, and termination.

### State Machine

```python
# agent_lifecycle.py

from enum import Enum
from typing import Dict, Any, Callable, Optional
import time

class AgentState(Enum):
    UNINITIALIZED = "uninitialized"
    INITIALIZING = "initializing"
    READY = "ready"
    EXECUTING = "executing"
    PAUSED = "paused"
    COMPLETING = "completing"
    COMPLETED = "completed"
    FAILED = "failed"
    TERMINATED = "terminated"

class AgentLifecycle:
    """Manage agent lifecycle states."""

    def __init__(self, agent_id: str, specification: AgentSpecification):
        self.agent_id = agent_id
        self.specification = specification
        self.state = AgentState.UNINITIALIZED
        self.metrics = {
            "start_time": None,
            "end_time": None,
            "execution_time": 0,
            "errors": 0,
            "tasks_completed": 0
        }
        self.state_history = []

    def initialize(self) -> bool:
        """Initialize agent."""
        self._transition_state(AgentState.INITIALIZING)

        try:
            # Load configuration
            self._load_configuration()

            # Initialize tools
            self._initialize_tools()

            # Validate readiness
            self._validate_readiness()

            # Register with orchestrator
            self._register()

            self._transition_state(AgentState.READY)
            return True

        except Exception as e:
            self._handle_error(e)
            self._transition_state(AgentState.FAILED)
            return False

    def execute(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """Execute agent task."""
        if self.state != AgentState.READY:
            raise ValueError(f"Agent not ready. Current state: {self.state}")

        self._transition_state(AgentState.EXECUTING)
        self.metrics["start_time"] = time.time()

        try:
            result = self._execute_task(task)
            self.metrics["tasks_completed"] += 1
            self._transition_state(AgentState.COMPLETING)
            return result

        except Exception as e:
            self.metrics["errors"] += 1
            self._handle_error(e)
            self._transition_state(AgentState.FAILED)
            raise

        finally:
            self.metrics["end_time"] = time.time()
            self.metrics["execution_time"] = (
                self.metrics["end_time"] - self.metrics["start_time"]
            )

    def pause(self):
        """Pause agent execution."""
        if self.state == AgentState.EXECUTING:
            self._persist_state()
            self._transition_state(AgentState.PAUSED)

    def resume(self):
        """Resume paused agent."""
        if self.state == AgentState.PAUSED:
            self._restore_state()
            self._transition_state(AgentState.EXECUTING)

    def terminate(self):
        """Terminate agent."""
        # Cleanup resources
        self._cleanup_resources()

        # Persist final state
        self._persist_final_state()

        # Unregister
        self._unregister()

        self._transition_state(AgentState.TERMINATED)

    def _transition_state(self, new_state: AgentState):
        """Transition to new state with logging."""
        old_state = self.state
        self.state = new_state
        self.state_history.append({
            "from": old_state,
            "to": new_state,
            "timestamp": time.time()
        })
        self._log_state_transition(old_state, new_state)

    def get_health(self) -> Dict[str, Any]:
        """Get agent health status."""
        return {
            "agent_id": self.agent_id,
            "state": self.state.value,
            "metrics": self.metrics,
            "healthy": self.state in [
                AgentState.READY,
                AgentState.EXECUTING,
                AgentState.COMPLETED
            ]
        }
```

### Monitoring

```python
class AgentMonitor:
    """Monitor agent performance and health."""

    def __init__(self):
        self.agents = {}
        self.alerts = []

    def register_agent(self, agent_id: str, agent: AgentLifecycle):
        """Register agent for monitoring."""
        self.agents[agent_id] = {
            "agent": agent,
            "last_check": time.time(),
            "health_history": []
        }

    def monitor_agents(self):
        """Continuously monitor all agents."""
        for agent_id, data in self.agents.items():
            health = data["agent"].get_health()
            data["health_history"].append(health)

            # Check for issues
            if not health["healthy"]:
                self._alert(agent_id, "Agent unhealthy", health)

            # Check performance
            if health["metrics"]["execution_time"] > 300:
                self._alert(agent_id, "Slow execution", health)

            if health["metrics"]["errors"] > 5:
                self._alert(agent_id, "High error rate", health)

    def get_metrics_summary(self) -> Dict[str, Any]:
        """Get summary of all agent metrics."""
        return {
            "total_agents": len(self.agents),
            "healthy_agents": sum(
                1 for data in self.agents.values()
                if data["agent"].get_health()["healthy"]
            ),
            "total_tasks": sum(
                data["agent"].metrics["tasks_completed"]
                for data in self.agents.values()
            ),
            "total_errors": sum(
                data["agent"].metrics["errors"]
                for data in self.agents.values()
            )
        }
```

### When to Use
- Production agent deployment
- Long-running agents
- Agent reliability requirements
- Debugging agent behavior

## Summary

These 5 patterns provide comprehensive coverage of agent development:

1. **Specification Design** - Clear agent contracts
2. **Capability-Tool Mapping** - Requirements to implementation
3. **Behavior Testing** - Quality assurance
4. **Multi-Agent Coordination** - Collaboration protocols
5. **Lifecycle Management** - Production operations

Use patterns together for production-ready agents that are maintainable, testable, and reliable.
