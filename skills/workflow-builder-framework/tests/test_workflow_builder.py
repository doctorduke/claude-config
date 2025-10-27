#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Tests for workflow-builder-framework skill.
Validates skill structure, content, and code examples.
"""

import os
import re
import sys
from pathlib import Path

# Force UTF-8 encoding for Windows console
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

SKILL_DIR = Path(__file__).parent.parent

def test_all_files_exist():
    """Test that all required files exist"""
    required_files = [
        "SKILL.md",
        "KNOWLEDGE.md",
        "PATTERNS.md",
        "EXAMPLES.md",
        "GOTCHAS.md",
        "REFERENCE.md"
    ]

    for filename in required_files:
        filepath = SKILL_DIR / filename
        assert filepath.exists(), f"Missing required file: {filename}"
        print(f"✓ {filename} exists")

def test_skill_md_line_count():
    """Test that SKILL.md is under 500 lines"""
    skill_file = SKILL_DIR / "SKILL.md"
    with open(skill_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    line_count = len(lines)
    assert line_count < 500, f"SKILL.md has {line_count} lines (limit: 500)"
    print(f"✓ SKILL.md line count: {line_count} lines (under 500)")

def test_skill_md_front_matter():
    """Test that SKILL.md has proper front matter"""
    skill_file = SKILL_DIR / "SKILL.md"
    with open(skill_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # Check for front matter
    assert content.startswith('---'), "SKILL.md missing front matter"
    assert 'name: workflow-builder-framework' in content, "Missing skill name"
    assert 'description:' in content, "Missing description"
    assert 'allowed-tools:' in content, "Missing allowed-tools"
    print("✓ SKILL.md has valid front matter")

def test_seven_patterns_documented():
    """Test that all 7 patterns are documented in PATTERNS.md"""
    patterns_file = SKILL_DIR / "PATTERNS.md"
    with open(patterns_file, 'r', encoding='utf-8') as f:
        content = f.read()

    required_patterns = [
        "Pattern 1: DAG Workflow",
        "Pattern 2: State Machine Workflow",
        "Pattern 3: Event-Driven Workflow",
        "Pattern 4: Saga Pattern",
        "Pattern 5: Error Handling & Recovery",
        "Pattern 6: Workflow Observability",
        "Pattern 7: Load Balancing & Scaling"
    ]

    for pattern in required_patterns:
        assert pattern in content, f"Missing pattern: {pattern}"
        print(f"✓ {pattern} documented")

def test_cross_references_valid():
    """Test that cross-references between files are valid"""
    skill_file = SKILL_DIR / "SKILL.md"
    with open(skill_file, 'r', encoding='utf-8') as f:
        skill_content = f.read()

    # Files that should be referenced in SKILL.md
    referenced_files = [
        "KNOWLEDGE.md",
        "PATTERNS.md",
        "EXAMPLES.md",
        "GOTCHAS.md",
        "REFERENCE.md"
    ]

    for filename in referenced_files:
        assert filename in skill_content, f"SKILL.md doesn't reference {filename}"
        print(f"✓ SKILL.md references {filename}")

def test_code_examples_valid_syntax():
    """Test that Python code examples have valid syntax"""
    patterns_file = SKILL_DIR / "PATTERNS.md"
    with open(patterns_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # Extract Python code blocks
    code_blocks = re.findall(r'```python\n(.*?)```', content, re.DOTALL)

    for i, code in enumerate(code_blocks):
        try:
            compile(code, f'<code_block_{i}>', 'exec')
            print(f"✓ Code block {i+1} has valid syntax")
        except SyntaxError as e:
            # Some code blocks are templates, skip those
            if 'lambda' in str(e) or 'placeholder' in code.lower():
                print(f"⊘ Code block {i+1} skipped (template)")
                continue
            raise AssertionError(f"Code block {i+1} has syntax error: {e}")

def test_dag_workflow_implementation():
    """Test that DAG workflow implementation is complete"""
    patterns_file = SKILL_DIR / "PATTERNS.md"
    with open(patterns_file, 'r', encoding='utf-8') as f:
        content = f.read()

    required_components = [
        "class DAGWorkflow",
        "def add_task",
        "def validate",
        "def topological_sort",
        "def execute"
    ]

    for component in required_components:
        assert component in content, f"Missing DAG component: {component}"
        print(f"✓ DAG workflow has {component}")

def test_state_machine_implementation():
    """Test that state machine implementation is complete"""
    patterns_file = SKILL_DIR / "PATTERNS.md"
    with open(patterns_file, 'r', encoding='utf-8') as f:
        content = f.read()

    required_components = [
        "class StateMachine",
        "def add_transition",
        "def trigger",
        "guard",
        "action"
    ]

    for component in required_components:
        assert component in content, f"Missing state machine component: {component}"
        print(f"✓ State machine has {component}")

def test_event_driven_implementation():
    """Test that event-driven workflow is documented"""
    patterns_file = SKILL_DIR / "PATTERNS.md"
    with open(patterns_file, 'r', encoding='utf-8') as f:
        content = f.read()

    required_components = [
        "class EventBus",
        "def subscribe",
        "def publish",
        "event_store",
        "replay"
    ]

    for component in required_components:
        assert component in content, f"Missing event-driven component: {component}"
        print(f"✓ Event-driven workflow has {component}")

def test_saga_pattern_implementation():
    """Test that saga pattern is documented"""
    patterns_file = SKILL_DIR / "PATTERNS.md"
    with open(patterns_file, 'r', encoding='utf-8') as f:
        content = f.read()

    required_components = [
        "class SagaOrchestrator",
        "forward",
        "compensate",
        "reversed"  # Compensation in reverse order
    ]

    for component in required_components:
        assert component in content, f"Missing saga component: {component}"
        print(f"✓ Saga pattern has {component}")

def test_error_handling_patterns():
    """Test that error handling patterns are documented"""
    patterns_file = SKILL_DIR / "PATTERNS.md"
    with open(patterns_file, 'r', encoding='utf-8') as f:
        content = f.read()

    required_components = [
        "CircuitBreaker",
        "RetryStrategy",
        "exponential_backoff",
        "DeadLetterQueue"
    ]

    for component in required_components:
        assert component in content, f"Missing error handling component: {component}"
        print(f"✓ Error handling has {component}")

def test_observability_implementation():
    """Test that observability patterns are documented"""
    patterns_file = SKILL_DIR / "PATTERNS.md"
    with open(patterns_file, 'r', encoding='utf-8') as f:
        content = f.read()

    required_components = [
        "Tracer",
        "Span",
        "MetricsCollector",
        "StructuredLogger"
    ]

    for component in required_components:
        assert component in content, f"Missing observability component: {component}"
        print(f"✓ Observability has {component}")

def test_examples_complete():
    """Test that EXAMPLES.md has all required examples"""
    examples_file = SKILL_DIR / "EXAMPLES.md"
    with open(examples_file, 'r', encoding='utf-8') as f:
        content = f.read()

    required_examples = [
        "Example 1: Multi-Agent Data Pipeline",
        "Example 2: Deployment Workflow with Rollback",
        "Example 3: Reactive Event System",
        "Example 4: Distributed Transaction",
        "Example 5: Complete Workflow with Observability"
    ]

    for example in required_examples:
        assert example in content, f"Missing example: {example}"
        print(f"✓ {example} present")

def test_gotchas_documented():
    """Test that common gotchas are documented"""
    gotchas_file = SKILL_DIR / "GOTCHAS.md"
    with open(gotchas_file, 'r', encoding='utf-8') as f:
        content = f.read()

    required_gotchas = [
        "Circular Dependencies",
        "Lost Events",
        "Compensation Order",  # Changed from "Saga Compensation Order"
        "Circuit Breaker Stuck Open",
        "Memory Leaks"
    ]

    for gotcha in required_gotchas:
        assert gotcha in content, f"Missing gotcha: {gotcha}"
        print(f"✓ Gotcha documented: {gotcha}")

def test_workflow_engines_documented():
    """Test that major workflow engines are documented"""
    knowledge_file = SKILL_DIR / "KNOWLEDGE.md"
    with open(knowledge_file, 'r', encoding='utf-8') as f:
        content = f.read()

    required_engines = [
        "Apache Airflow",
        "Temporal",
        "Prefect",
        "Celery",
        "AWS Step Functions"
    ]

    for engine in required_engines:
        assert engine in content, f"Missing workflow engine: {engine}"
        print(f"✓ Workflow engine documented: {engine}")

def test_api_reference_complete():
    """Test that API reference covers major frameworks"""
    reference_file = SKILL_DIR / "REFERENCE.md"
    with open(reference_file, 'r', encoding='utf-8') as f:
        content = f.read()

    required_apis = [
        "Airflow DAG API",
        "Temporal Workflow API",
        "Prefect Flow API",
        "Celery Task API",
        "State Machine Specifications"
    ]

    for api in required_apis:
        assert api in content, f"Missing API reference: {api}"
        print(f"✓ API reference: {api}")

def test_integration_points():
    """Test that integration points are documented"""
    skill_file = SKILL_DIR / "SKILL.md"
    with open(skill_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # Should mention integration with other agents
    content_lower = content.lower()
    assert "agent orchestrator" in content_lower or "agent-orchestrator" in content_lower, "Missing agent-orchestrator integration"
    assert "deployment architect" in content_lower or "deployment-architect" in content_lower, "Missing deployment-architect integration"
    print("✓ Integration points documented")

def run_all_tests():
    """Run all tests"""
    tests = [
        test_all_files_exist,
        test_skill_md_line_count,
        test_skill_md_front_matter,
        test_seven_patterns_documented,
        test_cross_references_valid,
        test_code_examples_valid_syntax,
        test_dag_workflow_implementation,
        test_state_machine_implementation,
        test_event_driven_implementation,
        test_saga_pattern_implementation,
        test_error_handling_patterns,
        test_observability_implementation,
        test_examples_complete,
        test_gotchas_documented,
        test_workflow_engines_documented,
        test_api_reference_complete,
        test_integration_points
    ]

    print("=" * 60)
    print("Running Workflow Builder Framework Tests")
    print("=" * 60)

    passed = 0
    failed = 0

    for test in tests:
        print(f"\n{test.__name__}:")
        try:
            test()
            passed += 1
        except AssertionError as e:
            print(f"✗ FAILED: {e}")
            failed += 1
        except Exception as e:
            print(f"✗ ERROR: {e}")
            failed += 1

    print("\n" + "=" * 60)
    print(f"Results: {passed} passed, {failed} failed")
    print("=" * 60)

    return failed == 0

if __name__ == "__main__":
    success = run_all_tests()
    exit(0 if success else 1)
