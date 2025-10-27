# Agent Builder Framework - Examples

## Example 1: Complete Agent Specification (Documentation Writer Agent)

### Scenario
Create an agent that automatically generates and updates documentation from code.

### Specification

```yaml
metadata:
  name: documentation-writer
  version: 1.0.0
  description: Automatically generate and maintain code documentation
  created: 2025-10-27
  author: ai-engineer

role:
  primary: Generate comprehensive documentation from source code
  responsibilities:
    - Extract docstrings and comments from code
    - Generate API documentation
    - Create usage examples
    - Update README files
    - Generate changelog from git history
  out_of_scope:
    - Writing implementation code
    - Refactoring existing code
    - Performance optimization

capabilities:
  - name: code-analysis
    description: Parse and understand code structure
    priority: critical
  - name: docstring-extraction
    description: Extract documentation from code
    priority: critical
  - name: example-generation
    description: Create runnable code examples
    priority: high
  - name: markdown-generation
    description: Generate formatted markdown documentation
    priority: critical
  - name: git-integration
    description: Read git history for changelogs
    priority: medium

tools:
  - name: Read
    purpose: Read source files
    required: true
  - name: Write
    purpose: Write documentation files
    required: true
  - name: Glob
    purpose: Find code files
    required: true
  - name: Grep
    purpose: Search for patterns in code
    required: true
  - name: Bash
    purpose: Run git commands
    required: true
  - name: ast-parser
    purpose: Parse Python AST
    required: true

inputs:
  - name: project_path
    type: string
    description: Path to codebase
    required: true
    validation: "must exist and contain code"
    example: "/path/to/project"
  - name: doc_types
    type: array[string]
    description: Types of documentation to generate
    required: false
    validation: "subset of [api, readme, changelog, examples]"
    example: ["api", "readme"]
  - name: output_dir
    type: string
    description: Where to write documentation
    required: false
    validation: "must be writable"
    example: "/path/to/docs"

outputs:
  - name: documentation_files
    type: object
    description: Generated documentation
    format: markdown
    schema:
      type: object
      properties:
        api_docs:
          type: array
          items:
            type: object
            properties:
              module: string
              file_path: string
              content: string
        readme:
          type: object
          properties:
            file_path: string
            content: string
        changelog:
          type: object
          properties:
            file_path: string
            content: string

constraints:
  max_execution_time: "300s"
  max_cost: 0.50
  max_tokens: 20000
  allowed_operations:
    - read_files
    - write_documentation
    - run_git_commands
    - parse_ast
  forbidden_operations:
    - modify_source_code
    - delete_files
    - access_network
  resource_limits:
    memory: "1GB"
    cpu: "1 core"
    disk: "500MB"

success_criteria:
  - metric: documentation_generated
    description: All requested doc types created
    threshold: 100%
    measurement: "count of generated docs / requested docs"
  - metric: documentation_valid
    description: Generated markdown is valid
    threshold: true
    measurement: "markdown validation passes"
  - metric: examples_runnable
    description: Code examples execute without errors
    threshold: 90%
    measurement: "runnable examples / total examples"
```

### Implementation

```python
# documentation_writer_agent.py

import ast
import os
from typing import List, Dict, Any
from pathlib import Path

class DocumentationWriterAgent:
    """Agent for automated documentation generation."""

    def __init__(self, specification: AgentSpecification):
        self.spec = specification
        self.tools = self._initialize_tools()

    def execute(self, inputs: Dict[str, Any]) -> Dict[str, Any]:
        """Execute documentation generation."""
        project_path = inputs["project_path"]
        doc_types = inputs.get("doc_types", ["api", "readme"])
        output_dir = inputs.get("output_dir", os.path.join(project_path, "docs"))

        results = {
            "api_docs": [],
            "readme": None,
            "changelog": None
        }

        # Generate requested documentation
        if "api" in doc_types:
            results["api_docs"] = self._generate_api_docs(project_path, output_dir)

        if "readme" in doc_types:
            results["readme"] = self._generate_readme(project_path, output_dir)

        if "changelog" in doc_types:
            results["changelog"] = self._generate_changelog(project_path, output_dir)

        return results

    def _generate_api_docs(self, project_path: str, output_dir: str) -> List[Dict]:
        """Generate API documentation from code."""
        api_docs = []

        # Find all Python files
        python_files = self._find_python_files(project_path)

        for file_path in python_files:
            # Read source code
            source = self.tools["Read"](file_path)

            # Parse AST
            tree = ast.parse(source)

            # Extract documentation
            module_doc = self._extract_module_doc(tree)
            class_docs = self._extract_class_docs(tree)
            function_docs = self._extract_function_docs(tree)

            # Generate markdown
            markdown = self._format_api_doc(module_doc, class_docs, function_docs)

            # Write to file
            rel_path = os.path.relpath(file_path, project_path)
            doc_path = os.path.join(output_dir, "api", f"{rel_path}.md")
            os.makedirs(os.path.dirname(doc_path), exist_ok=True)
            self.tools["Write"](doc_path, markdown)

            api_docs.append({
                "module": rel_path,
                "file_path": doc_path,
                "content": markdown
            })

        return api_docs

    def _extract_module_doc(self, tree: ast.AST) -> str:
        """Extract module-level docstring."""
        return ast.get_docstring(tree) or "No module documentation"

    def _extract_class_docs(self, tree: ast.AST) -> List[Dict]:
        """Extract class documentation."""
        class_docs = []

        for node in ast.walk(tree):
            if isinstance(node, ast.ClassDef):
                class_docs.append({
                    "name": node.name,
                    "docstring": ast.get_docstring(node),
                    "methods": self._extract_methods(node),
                    "lineno": node.lineno
                })

        return class_docs

    def _extract_function_docs(self, tree: ast.AST) -> List[Dict]:
        """Extract function documentation."""
        function_docs = []

        for node in ast.walk(tree):
            if isinstance(node, ast.FunctionDef):
                # Skip methods (handled in class docs)
                if not self._is_method(node):
                    function_docs.append({
                        "name": node.name,
                        "docstring": ast.get_docstring(node),
                        "args": [arg.arg for arg in node.args.args],
                        "returns": self._get_return_type(node),
                        "lineno": node.lineno
                    })

        return function_docs

    def _format_api_doc(
        self,
        module_doc: str,
        class_docs: List[Dict],
        function_docs: List[Dict]
    ) -> str:
        """Format API documentation as markdown."""
        lines = []

        # Module documentation
        lines.append(f"# Module Documentation\n\n{module_doc}\n")

        # Classes
        if class_docs:
            lines.append("## Classes\n")
            for class_doc in class_docs:
                lines.append(f"### `{class_doc['name']}`\n")
                lines.append(f"{class_doc['docstring']}\n")

                if class_doc["methods"]:
                    lines.append("#### Methods\n")
                    for method in class_doc["methods"]:
                        lines.append(f"- `{method['name']}()`: {method['docstring']}\n")

                lines.append("\n")

        # Functions
        if function_docs:
            lines.append("## Functions\n")
            for func_doc in function_docs:
                args = ", ".join(func_doc["args"])
                lines.append(f"### `{func_doc['name']}({args})`\n")
                lines.append(f"{func_doc['docstring']}\n\n")

        return "".join(lines)

    def _generate_readme(self, project_path: str, output_dir: str) -> Dict:
        """Generate README from project structure."""
        # Analyze project structure
        structure = self._analyze_project_structure(project_path)

        # Generate README content
        readme_content = f"""# {structure['project_name']}

{structure['description']}

## Installation

```bash
{structure['install_command']}
```

## Usage

```python
{structure['usage_example']}
```

## Project Structure

```
{structure['tree']}
```

## API Documentation

See [API Documentation]({structure['api_docs_link']}) for detailed API reference.

## License

{structure['license']}
"""

        # Write README
        readme_path = os.path.join(output_dir, "README.md")
        self.tools["Write"](readme_path, readme_content)

        return {
            "file_path": readme_path,
            "content": readme_content
        }

    def _generate_changelog(self, project_path: str, output_dir: str) -> Dict:
        """Generate CHANGELOG from git history."""
        import subprocess

        # Get git log
        result = subprocess.run(
            ["git", "log", "--pretty=format:%H|%an|%ad|%s"],
            cwd=project_path,
            capture_output=True,
            text=True
        )

        commits = []
        for line in result.stdout.split("\n"):
            if line:
                hash, author, date, message = line.split("|", 3)
                commits.append({
                    "hash": hash[:7],
                    "author": author,
                    "date": date,
                    "message": message
                })

        # Group by version (parse from tags)
        versions = self._group_commits_by_version(commits)

        # Generate changelog markdown
        changelog_content = "# Changelog\n\n"

        for version, version_commits in versions.items():
            changelog_content += f"## {version}\n\n"
            for commit in version_commits:
                changelog_content += f"- {commit['message']} ({commit['hash']})\n"
            changelog_content += "\n"

        # Write CHANGELOG
        changelog_path = os.path.join(output_dir, "CHANGELOG.md")
        self.tools["Write"](changelog_path, changelog_content)

        return {
            "file_path": changelog_path,
            "content": changelog_content
        }
```

## Example 2: Capability-Tool Mapping (Security Auditor)

### Capability Analysis

```python
# Security auditor capability requirements
capabilities = [
    {
        "name": "static-analysis",
        "description": "Analyze source code for security vulnerabilities",
        "requirements": [
            "Read source files",
            "Parse code syntax",
            "Run SAST tools",
            "Parse tool output",
            "Aggregate results"
        ]
    },
    {
        "name": "dependency-scanning",
        "description": "Check dependencies for known vulnerabilities",
        "requirements": [
            "Read dependency manifests",
            "Query vulnerability databases",
            "Match versions to CVEs",
            "Generate vulnerability report"
        ]
    },
    {
        "name": "secret-detection",
        "description": "Find exposed credentials",
        "requirements": [
            "Read all text files",
            "Run entropy analysis",
            "Pattern matching",
            "Deduplicate findings"
        ]
    }
]
```

### Tool Mapping

```python
# Map capabilities to tools
capability_tool_map = {
    "static-analysis": {
        "core_tools": ["semgrep", "bandit"],
        "supporting_tools": ["Read", "Grep", "Bash"],
        "workflow": [
            ("Read", "Load source files"),
            ("Bash", "Execute semgrep with security rules"),
            ("Bash", "Execute bandit on Python files"),
            ("Read", "Read tool output files"),
            ("custom", "Parse and aggregate results")
        ],
        "configuration": {
            "semgrep": {
                "config": "p/security-audit",
                "output": "json"
            },
            "bandit": {
                "severity": "medium",
                "confidence": "medium",
                "format": "json"
            }
        }
    },
    "dependency-scanning": {
        "core_tools": ["safety", "npm-audit"],
        "supporting_tools": ["Read", "Bash"],
        "workflow": [
            ("Read", "Read requirements.txt or package.json"),
            ("Bash", "Run safety check / npm audit"),
            ("Read", "Read vulnerability report"),
            ("custom", "Parse CVE data")
        ],
        "configuration": {
            "safety": {
                "output": "json",
                "continue_on_error": True
            }
        }
    },
    "secret-detection": {
        "core_tools": ["trufflehog"],
        "supporting_tools": ["Read", "Grep", "Glob"],
        "workflow": [
            ("Glob", "Find all text files"),
            ("Bash", "Run trufflehog entropy scan"),
            ("Grep", "Search for API key patterns"),
            ("custom", "Deduplicate and validate findings")
        ],
        "configuration": {
            "trufflehog": {
                "entropy": True,
                "regex": True,
                "max_depth": 100
            }
        }
    }
}

# Validate coverage
def validate_capability_coverage(capabilities, tool_map):
    """Ensure all capabilities have complete tool coverage."""
    coverage_report = {}

    for capability in capabilities:
        cap_name = capability["name"]
        if cap_name not in tool_map:
            coverage_report[cap_name] = "MISSING"
            continue

        tools = tool_map[cap_name]
        workflow_steps = [step[0] for step in tools["workflow"]]

        # Check if workflow covers all requirements
        missing_tools = []
        for req in capability["requirements"]:
            # Simple heuristic: check if requirement keywords match workflow
            if not any(
                keyword in " ".join(workflow_steps).lower()
                for keyword in req.lower().split()
            ):
                missing_tools.append(req)

        if missing_tools:
            coverage_report[cap_name] = f"PARTIAL: Missing {missing_tools}"
        else:
            coverage_report[cap_name] = "COMPLETE"

    return coverage_report

coverage = validate_capability_coverage(capabilities, capability_tool_map)
print(coverage)
# Output: {'static-analysis': 'COMPLETE', 'dependency-scanning': 'COMPLETE', ...}
```

## Example 3: Agent Behavior Test Suite

### Test Structure

```python
# tests/test_documentation_writer.py

import pytest
import tempfile
import os
from documentation_writer_agent import DocumentationWriterAgent

class TestDocumentationWriterAgent:
    """Comprehensive test suite for documentation writer agent."""

    @pytest.fixture
    def sample_project(self):
        """Create sample Python project for testing."""
        with tempfile.TemporaryDirectory() as tmpdir:
            # Create sample module
            module_code = '''
"""Sample module for testing documentation generation."""

class Calculator:
    """A simple calculator class."""

    def add(self, a: int, b: int) -> int:
        """Add two numbers.

        Args:
            a: First number
            b: Second number

        Returns:
            Sum of a and b
        """
        return a + b

def multiply(x: int, y: int) -> int:
    """Multiply two numbers."""
    return x * y
'''
            module_path = os.path.join(tmpdir, "calculator.py")
            with open(module_path, "w") as f:
                f.write(module_code)

            # Create setup.py
            setup_code = '''
from setuptools import setup
setup(name="calculator", version="1.0.0")
'''
            with open(os.path.join(tmpdir, "setup.py"), "w") as f:
                f.write(setup_code)

            yield tmpdir

    # Unit Tests
    def test_extract_module_doc(self, sample_project):
        """Test module docstring extraction."""
        agent = DocumentationWriterAgent(get_spec())
        source = open(os.path.join(sample_project, "calculator.py")).read()
        tree = ast.parse(source)

        module_doc = agent._extract_module_doc(tree)

        assert "Sample module" in module_doc
        assert "documentation generation" in module_doc

    def test_extract_class_docs(self, sample_project):
        """Test class documentation extraction."""
        agent = DocumentationWriterAgent(get_spec())
        source = open(os.path.join(sample_project, "calculator.py")).read()
        tree = ast.parse(source)

        class_docs = agent._extract_class_docs(tree)

        assert len(class_docs) == 1
        assert class_docs[0]["name"] == "Calculator"
        assert "simple calculator" in class_docs[0]["docstring"]
        assert len(class_docs[0]["methods"]) == 1

    def test_extract_function_docs(self, sample_project):
        """Test function documentation extraction."""
        agent = DocumentationWriterAgent(get_spec())
        source = open(os.path.join(sample_project, "calculator.py")).read()
        tree = ast.parse(source)

        func_docs = agent._extract_function_docs(tree)

        multiply_doc = next(d for d in func_docs if d["name"] == "multiply")
        assert multiply_doc is not None
        assert multiply_doc["args"] == ["x", "y"]

    # Integration Tests
    def test_generate_api_docs_integration(self, sample_project):
        """Test API documentation generation end-to-end."""
        agent = DocumentationWriterAgent(get_spec())
        output_dir = os.path.join(sample_project, "docs")

        api_docs = agent._generate_api_docs(sample_project, output_dir)

        assert len(api_docs) == 1
        assert os.path.exists(api_docs[0]["file_path"])

        # Verify content
        content = api_docs[0]["content"]
        assert "Calculator" in content
        assert "add" in content
        assert "multiply" in content

    def test_generate_readme_integration(self, sample_project):
        """Test README generation."""
        agent = DocumentationWriterAgent(get_spec())
        output_dir = os.path.join(sample_project, "docs")

        readme = agent._generate_readme(sample_project, output_dir)

        assert os.path.exists(readme["file_path"])
        assert "Installation" in readme["content"]
        assert "Usage" in readme["content"]

    # Acceptance Tests
    def test_full_documentation_workflow(self, sample_project):
        """Test complete documentation generation workflow."""
        agent = DocumentationWriterAgent(get_spec())

        inputs = {
            "project_path": sample_project,
            "doc_types": ["api", "readme"],
            "output_dir": os.path.join(sample_project, "docs")
        }

        results = agent.execute(inputs)

        # Verify all documentation generated
        assert len(results["api_docs"]) > 0
        assert results["readme"] is not None

        # Verify files exist
        for api_doc in results["api_docs"]:
            assert os.path.exists(api_doc["file_path"])
        assert os.path.exists(results["readme"]["file_path"])

    # Error Handling Tests
    def test_handles_missing_docstrings(self):
        """Test agent handles code without docstrings."""
        code_without_docs = '''
class Foo:
    def bar(self):
        pass
'''
        agent = DocumentationWriterAgent(get_spec())
        tree = ast.parse(code_without_docs)

        class_docs = agent._extract_class_docs(tree)

        assert len(class_docs) == 1
        assert class_docs[0]["docstring"] is None or "No documentation" in class_docs[0]["docstring"]

    def test_handles_invalid_project_path(self):
        """Test agent handles non-existent project."""
        agent = DocumentationWriterAgent(get_spec())

        with pytest.raises(FileNotFoundError):
            agent.execute({"project_path": "/nonexistent/path"})

    # Performance Tests
    def test_large_project_performance(self):
        """Test agent handles large projects within timeout."""
        with tempfile.TemporaryDirectory() as tmpdir:
            # Create 100 Python files
            for i in range(100):
                with open(os.path.join(tmpdir, f"module_{i}.py"), "w") as f:
                    f.write(f"def func_{i}(): pass\n")

            agent = DocumentationWriterAgent(get_spec())

            import time
            start = time.time()
            api_docs = agent._generate_api_docs(tmpdir, os.path.join(tmpdir, "docs"))
            elapsed = time.time() - start

            assert len(api_docs) == 100
            assert elapsed < 60  # Should complete within 60 seconds
```

## Example 4: Multi-Agent Handoff Protocol

### Scenario: Code Review Workflow

```python
# Multi-agent code review system

from coordination_protocol import HandoffProtocol, CoordinationProtocol

# Define agents
agents = {
    "analyzer": "code-analyzer-agent",
    "security": "security-auditor-agent",
    "reviewer": "code-reviewer-agent",
    "reporter": "report-generator-agent"
}

# Create coordination system
coordinator = CoordinationProtocol()

# Protocol 1: Orchestrator -> Analyzer
analyze_handoff = HandoffProtocol(
    protocol_id="analyze_code",
    sender_agent="orchestrator",
    receiver_agent=agents["analyzer"],
    trigger_condition="code_review_requested",
    trigger_check=lambda: check_review_requested(),
    payload_schema={
        "type": "object",
        "properties": {
            "repository": {"type": "string"},
            "branch": {"type": "string"},
            "files_changed": {"type": "array"}
        },
        "required": ["repository", "branch"]
    },
    payload_data={
        "repository": "/path/to/repo",
        "branch": "feature/new-feature",
        "files_changed": ["app.py", "tests/test_app.py"]
    },
    requires_ack=True,
    ack_timeout=30.0,
    max_retries=3,
    retry_delay=5.0
)

# Protocol 2: Analyzer -> Security Auditor (conditional)
security_handoff = HandoffProtocol(
    protocol_id="security_audit",
    sender_agent=agents["analyzer"],
    receiver_agent=agents["security"],
    trigger_condition="security_files_detected",
    trigger_check=lambda: any(
        file.endswith((".py", ".js"))
        for file in analyze_results["files"]
    ),
    payload_schema={
        "type": "object",
        "properties": {
            "files": {"type": "array"},
            "analysis_results": {"type": "object"}
        }
    },
    payload_data=None,  # Set by analyzer agent
    requires_ack=True,
    ack_timeout=120.0,  # Security scans take longer
    max_retries=2,
    retry_delay=10.0,
    fallback_action=lambda: log_warning("Security scan skipped")
)

# Protocol 3: Parallel aggregation (Analyzer + Security -> Reviewer)
review_handoff = HandoffProtocol(
    protocol_id="aggregate_review",
    sender_agent="coordinator",
    receiver_agent=agents["reviewer"],
    trigger_condition="all_analysis_complete",
    trigger_check=lambda: (
        analyzer_done() and (security_done() or security_skipped())
    ),
    payload_schema={
        "type": "object",
        "properties": {
            "code_analysis": {"type": "object"},
            "security_analysis": {"type": "object"},
            "metadata": {"type": "object"}
        }
    },
    payload_data=None,  # Aggregated by coordinator
    requires_ack=True,
    ack_timeout=60.0,
    max_retries=3,
    retry_delay=5.0
)

# Protocol 4: Reviewer -> Reporter
report_handoff = HandoffProtocol(
    protocol_id="generate_report",
    sender_agent=agents["reviewer"],
    receiver_agent=agents["reporter"],
    trigger_condition="review_complete",
    trigger_check=lambda: reviewer_completed(),
    payload_schema={
        "type": "object",
        "properties": {
            "review_results": {"type": "object"},
            "recommendations": {"type": "array"},
            "report_format": {"type": "string"}
        }
    },
    payload_data=None,
    requires_ack=False,  # Fire and forget
    ack_timeout=0,
    max_retries=2,
    retry_delay=5.0
)

# Execute workflow
def run_code_review_workflow(repository: str, branch: str):
    """Execute multi-agent code review workflow."""

    # Step 1: Initiate analysis
    analyze_handoff.payload_data = {
        "repository": repository,
        "branch": branch
    }
    coordinator.initiate_handoff(analyze_handoff)

    # Step 2: Wait for analysis to complete
    analyzer_results = wait_for_agent(agents["analyzer"])

    # Step 3: Conditional security audit
    if should_run_security_scan(analyzer_results):
        security_handoff.payload_data = {
            "files": analyzer_results["files"],
            "analysis_results": analyzer_results
        }
        coordinator.initiate_handoff(security_handoff)
        security_results = wait_for_agent(agents["security"])
    else:
        security_results = None

    # Step 4: Aggregate and review
    review_handoff.payload_data = {
        "code_analysis": analyzer_results,
        "security_analysis": security_results,
        "metadata": {"repository": repository, "branch": branch}
    }
    coordinator.initiate_handoff(review_handoff)
    review_results = wait_for_agent(agents["reviewer"])

    # Step 5: Generate report
    report_handoff.payload_data = {
        "review_results": review_results,
        "recommendations": review_results["recommendations"],
        "report_format": "markdown"
    }
    coordinator.initiate_handoff(report_handoff)

    # Return final report path (async)
    return {"status": "workflow_initiated", "tracking_id": "review-123"}
```

## Example 5: End-to-End Agent Creation Workflow

### Scenario: Create Test Generator Agent

```python
# Step-by-step agent creation from requirements to deployment

# STEP 1: Define Requirements
requirements = """
Create an agent that automatically generates unit tests for Python code.

Requirements:
- Analyze Python source files
- Identify functions and classes that need tests
- Generate pytest-compatible test code
- Achieve >80% coverage
- Handle edge cases and error conditions
"""

# STEP 2: Create Specification
specification = AgentSpecification(
    # Metadata
    name="test-generator",
    version="1.0.0",
    description="Automatically generate unit tests for Python code",
    created=datetime.now(),
    author="ai-engineer",

    # Role
    primary_role="Generate comprehensive unit tests from source code",
    responsibilities=[
        "Analyze Python source code structure",
        "Identify testable functions and methods",
        "Generate pytest test cases",
        "Create test fixtures and mocks",
        "Ensure edge case coverage"
    ],
    out_of_scope=[
        "Integration testing",
        "Performance testing",
        "Manual test writing"
    ],

    # Capabilities
    capabilities=[
        Capability("code-analysis", "Parse and understand Python code", "critical"),
        Capability("test-generation", "Generate pytest test code", "critical"),
        Capability("coverage-analysis", "Measure test coverage", "high"),
        Capability("edge-case-detection", "Identify edge cases", "high")
    ],

    # Tools
    tools=[
        Tool("Read", "Read source files", True),
        Tool("Write", "Write test files", True),
        Tool("Bash", "Run pytest", True),
        Tool("ast-parser", "Parse Python AST", True),
        Tool("coverage.py", "Measure coverage", True)
    ],

    # Interface
    inputs=[
        InputSpec("source_file", "string", "Python file to test", True,
                  "must be .py file", "/path/to/module.py")
    ],
    outputs=[
        OutputSpec("test_file", "string", "Generated test file path", "python", None),
        OutputSpec("coverage_report", "object", "Coverage metrics", "json", {})
    ],

    # Constraints
    constraints=Constraints(
        max_execution_time="180s",
        max_cost=0.25,
        max_tokens=15000,
        allowed_operations=["read_files", "write_tests", "run_pytest"],
        forbidden_operations=["modify_source", "delete_files"],
        resource_limits={"memory": "512MB", "cpu": "1 core", "disk": "100MB"}
    ),

    # Success criteria
    success_criteria=[
        SuccessCriterion("tests_generated", "Test file created", True, "file exists"),
        SuccessCriterion("coverage", "Code coverage achieved", 0.80, "coverage.py"),
        SuccessCriterion("tests_pass", "All generated tests pass", True, "pytest")
    ]
)

# STEP 3: Validate Specification
validation_errors = specification.validate()
if validation_errors:
    raise ValueError(f"Invalid specification: {validation_errors}")

# STEP 4: Map Capabilities to Tools
mapper = CapabilityToolMapper(tool_registry)
tool_requirements = mapper.generate_tool_list(specification.capabilities)
missing_tools = mapper.validate_tools_available(tool_requirements)
if missing_tools:
    raise RuntimeError(f"Missing required tools: {missing_tools}")

# STEP 5: Implement Agent
class TestGeneratorAgent:
    """Agent for automated test generation."""

    def __init__(self, spec: AgentSpecification):
        self.spec = spec
        self.lifecycle = AgentLifecycle("test-generator", spec)

    def execute(self, inputs: Dict[str, Any]) -> Dict[str, Any]:
        """Generate tests for source file."""
        source_file = inputs["source_file"]

        # Read source code
        source = self._read_source(source_file)

        # Parse AST
        tree = ast.parse(source)

        # Identify testable functions
        functions = self._find_testable_functions(tree)
        classes = self._find_testable_classes(tree)

        # Generate test code
        test_code = self._generate_test_code(functions, classes)

        # Write test file
        test_file = self._write_test_file(source_file, test_code)

        # Run tests to verify
        test_results = self._run_tests(test_file)

        # Measure coverage
        coverage = self._measure_coverage(source_file, test_file)

        return {
            "test_file": test_file,
            "coverage_report": coverage,
            "tests_passed": test_results["passed"],
            "tests_failed": test_results["failed"]
        }

    def _generate_test_code(self, functions: List, classes: List) -> str:
        """Generate pytest code."""
        lines = ["import pytest\n\n"]

        for func in functions:
            lines.append(self._generate_function_test(func))

        for cls in classes:
            lines.append(self._generate_class_test(cls))

        return "".join(lines)

# STEP 6: Create Test Suite
# (See Example 3 for comprehensive test suite)

# STEP 7: Deploy Agent
def deploy_test_generator():
    """Deploy test generator agent."""
    # Initialize
    agent = TestGeneratorAgent(specification)
    lifecycle = agent.lifecycle

    if not lifecycle.initialize():
        raise RuntimeError("Failed to initialize agent")

    # Register with orchestrator
    orchestrator.register_agent("test-generator", agent)

    # Start monitoring
    monitor.register_agent("test-generator", lifecycle)

    return agent

# STEP 8: Use Agent
deployed_agent = deploy_test_generator()

result = deployed_agent.execute({
    "source_file": "/path/to/calculator.py"
})

print(f"Tests generated: {result['test_file']}")
print(f"Coverage: {result['coverage_report']['percentage']}%")
```

## Real-World Use Cases

### Use Case 1: Create Documentation Generator
See Example 1 above for complete specification and implementation.

### Use Case 2: Refactor Existing Agent

```python
# Before: Monolithic agent with unclear responsibilities
class MonolithicAgent:
    def do_everything(self, project):
        self.analyze_code(project)
        self.run_tests(project)
        self.check_security(project)
        self.deploy(project)
        self.monitor(project)

# After: Specialized agents with clear boundaries
specs = {
    "analyzer": create_code_analyzer_spec(),
    "tester": create_test_runner_spec(),
    "security": create_security_auditor_spec(),
    "deployer": create_deployer_spec(),
    "monitor": create_monitor_spec()
}

# Create coordination
workflow = create_sequential_pipeline([
    "analyzer", "tester", "security", "deployer", "monitor"
])

# Deploy
for name, spec in specs.items():
    agent = create_agent(spec)
    deploy_agent(name, agent)
```

### Use Case 3: Multi-Agent Testing System

```python
# Parallel test execution with multiple test-runner agents
test_files = glob("tests/test_*.py")
num_agents = 4
chunks = split_into_chunks(test_files, num_agents)

# Deploy multiple test-runner agents
agents = []
for i in range(num_agents):
    spec = create_test_runner_spec(f"test-runner-{i}")
    agent = TestRunnerAgent(spec)
    agents.append(agent)

# Coordinate parallel execution
coordinator = create_parallel_coordination("orchestrator", [
    f"test-runner-{i}" for i in range(num_agents)
])

# Execute
results = []
for agent, chunk in zip(agents, chunks):
    result = agent.execute({"test_files": chunk})
    results.append(result)

# Aggregate results
total_coverage = aggregate_coverage(results)
print(f"Total coverage: {total_coverage}%")
```

## Summary

These examples demonstrate:
1. Complete agent specifications with all required fields
2. Systematic capability-to-tool mapping
3. Comprehensive test suites at multiple levels
4. Multi-agent coordination with handoff protocols
5. End-to-end agent creation workflows

Use these as templates for creating your own specialized agents.
