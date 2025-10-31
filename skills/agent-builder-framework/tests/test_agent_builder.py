"""
Test suite for Agent Builder Framework skill.

Tests validate:
- SKILL.md line count (<500 lines)
- All 6 files exist
- Cross-references are valid
- 5 patterns documented
- Agent specification examples
- Documentation quality
"""

import pytest
import os
import re
from pathlib import Path


SKILL_DIR = Path(__file__).parent.parent
SKILL_FILES = [
    "SKILL.md",
    "KNOWLEDGE.md",
    "PATTERNS.md",
    "EXAMPLES.md",
    "GOTCHAS.md",
    "REFERENCE.md"
]


class TestSkillStructure:
    """Test skill file structure and existence."""

    def test_all_files_exist(self):
        """Test that all 6 required files exist."""
        for filename in SKILL_FILES:
            file_path = SKILL_DIR / filename
            assert file_path.exists(), f"Missing file: {filename}"

    def test_skill_md_line_count(self):
        """Test that SKILL.md is under 500 lines."""
        skill_path = SKILL_DIR / "SKILL.md"
        with open(skill_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            line_count = len(lines)

        assert line_count < 500, f"SKILL.md has {line_count} lines (max: 500)"
        print(f"SKILL.md line count: {line_count}")

    def test_tests_directory_exists(self):
        """Test that tests directory exists."""
        tests_dir = SKILL_DIR / "tests"
        assert tests_dir.exists(), "Tests directory missing"
        assert tests_dir.is_dir(), "tests is not a directory"


class TestCrossReferences:
    """Test that cross-references between files are valid."""

    def test_skill_md_references(self):
        """Test that SKILL.md references to other files are valid."""
        skill_path = SKILL_DIR / "SKILL.md"
        with open(skill_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Find all markdown links
        links = re.findall(r'\[([^\]]+)\]\(\.?/?([\w\./\-]+\.md)\)', content)

        for link_text, link_path in links:
            # Normalize path
            normalized_path = link_path.replace('./', '')

            # Check if file exists
            target_file = SKILL_DIR / normalized_path
            assert target_file.exists(), f"Broken link in SKILL.md: {link_path}"

    def test_pattern_references_in_skill_md(self):
        """Test that SKILL.md references all 5 patterns."""
        skill_path = SKILL_DIR / "SKILL.md"
        with open(skill_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Check for pattern references
        pattern_references = [
            "Agent Specification Design",
            "Capability Definition & Tool Selection",
            "Behavior Testing & Validation",
            "Multi-Agent Coordination",
            "Agent Lifecycle Management"
        ]

        for pattern in pattern_references:
            assert pattern in content, f"Missing pattern reference: {pattern}"

    def test_knowledge_md_referenced(self):
        """Test that KNOWLEDGE.md is referenced in SKILL.md."""
        skill_path = SKILL_DIR / "SKILL.md"
        with open(skill_path, 'r', encoding='utf-8') as f:
            content = f.read()

        assert "KNOWLEDGE.md" in content, "KNOWLEDGE.md not referenced"


class TestPatternsDocumentation:
    """Test that all 5 patterns are documented."""

    def test_patterns_md_exists(self):
        """Test PATTERNS.md exists."""
        patterns_path = SKILL_DIR / "PATTERNS.md"
        assert patterns_path.exists(), "PATTERNS.md missing"

    def test_five_patterns_documented(self):
        """Test that PATTERNS.md documents exactly 5 patterns."""
        patterns_path = SKILL_DIR / "PATTERNS.md"
        with open(patterns_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Look for pattern headers
        pattern_headers = re.findall(r'^## Pattern \d+:', content, re.MULTILINE)

        assert len(pattern_headers) == 5, \
            f"Expected 5 patterns, found {len(pattern_headers)}"

    def test_pattern_1_specification_design(self):
        """Test Pattern 1: Agent Specification Design is documented."""
        patterns_path = SKILL_DIR / "PATTERNS.md"
        with open(patterns_path, 'r', encoding='utf-8') as f:
            content = f.read()

        assert "Pattern 1: Agent Specification Design" in content
        assert "Purpose" in content
        assert "Structure" in content or "Implementation" in content

    def test_pattern_2_capability_tool_mapping(self):
        """Test Pattern 2: Capability-Tool Mapping is documented."""
        patterns_path = SKILL_DIR / "PATTERNS.md"
        with open(patterns_path, 'r', encoding='utf-8') as f:
            content = f.read()

        assert "Pattern 2: Capability" in content or "Capability-Tool Mapping" in content
        assert "map" in content.lower() or "mapping" in content.lower()

    def test_pattern_3_behavior_testing(self):
        """Test Pattern 3: Behavior Testing is documented."""
        patterns_path = SKILL_DIR / "PATTERNS.md"
        with open(patterns_path, 'r', encoding='utf-8') as f:
            content = f.read()

        assert "Pattern 3:" in content
        assert "test" in content.lower() or "Testing" in content

    def test_pattern_4_multi_agent_coordination(self):
        """Test Pattern 4: Multi-Agent Coordination is documented."""
        patterns_path = SKILL_DIR / "PATTERNS.md"
        with open(patterns_path, 'r', encoding='utf-8') as f:
            content = f.read()

        assert "Pattern 4:" in content
        assert "coordination" in content.lower() or "multi-agent" in content.lower()

    def test_pattern_5_lifecycle_management(self):
        """Test Pattern 5: Lifecycle Management is documented."""
        patterns_path = SKILL_DIR / "PATTERNS.md"
        with open(patterns_path, 'r', encoding='utf-8') as f:
            content = f.read()

        assert "Pattern 5:" in content
        assert "lifecycle" in content.lower() or "Lifecycle" in content

    def test_each_pattern_has_purpose(self):
        """Test that each pattern has a Purpose section."""
        patterns_path = SKILL_DIR / "PATTERNS.md"
        with open(patterns_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Split by pattern headers
        pattern_sections = re.split(r'^## Pattern \d+:', content, re.MULTILINE)[1:]

        for i, section in enumerate(pattern_sections, 1):
            assert "Purpose" in section or "purpose" in section.lower(), \
                f"Pattern {i} missing Purpose section"

    def test_each_pattern_has_code_example(self):
        """Test that each pattern has code examples."""
        patterns_path = SKILL_DIR / "PATTERNS.md"
        with open(patterns_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Split by pattern headers
        pattern_sections = re.split(r'^## Pattern \d+:', content, re.MULTILINE)[1:]

        for i, section in enumerate(pattern_sections, 1):
            # Check for code blocks
            has_code = "```" in section
            assert has_code, f"Pattern {i} missing code examples"


class TestAgentSpecification:
    """Test agent specification examples."""

    def test_specification_schema_documented(self):
        """Test that specification schema is documented."""
        reference_path = SKILL_DIR / "REFERENCE.md"
        with open(reference_path, 'r', encoding='utf-8') as f:
            content = f.read()

        assert "AgentSpecification" in content
        assert "schema" in content.lower()

    def test_specification_example_in_examples(self):
        """Test that EXAMPLES.md contains complete specification example."""
        examples_path = SKILL_DIR / "EXAMPLES.md"
        with open(examples_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Check for specification components
        required_components = [
            "metadata",
            "role",
            "capabilities",
            "tools",
            "inputs",
            "outputs",
            "constraints",
            "success_criteria"
        ]

        for component in required_components:
            assert component in content, \
                f"Specification component missing: {component}"

    def test_specification_has_validation(self):
        """Test that specification validation is documented."""
        reference_path = SKILL_DIR / "REFERENCE.md"
        with open(reference_path, 'r', encoding='utf-8') as f:
            content = f.read()

        assert "validate" in content.lower()
        assert "validation" in content.lower()


class TestExamples:
    """Test that examples are complete and functional."""

    def test_examples_md_exists(self):
        """Test EXAMPLES.md exists."""
        examples_path = SKILL_DIR / "EXAMPLES.md"
        assert examples_path.exists(), "EXAMPLES.md missing"

    def test_at_least_five_examples(self):
        """Test that EXAMPLES.md contains at least 5 examples."""
        examples_path = SKILL_DIR / "EXAMPLES.md"
        with open(examples_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Count example headers
        example_headers = re.findall(r'^## Example \d+:', content, re.MULTILINE)

        assert len(example_headers) >= 5, \
            f"Expected at least 5 examples, found {len(example_headers)}"

    def test_example_1_complete_specification(self):
        """Test Example 1: Complete Agent Specification exists."""
        examples_path = SKILL_DIR / "EXAMPLES.md"
        with open(examples_path, 'r', encoding='utf-8') as f:
            content = f.read()

        assert "Example 1:" in content
        assert "Specification" in content or "specification" in content

    def test_example_2_capability_mapping(self):
        """Test Example 2: Capability-Tool Mapping exists."""
        examples_path = SKILL_DIR / "EXAMPLES.md"
        with open(examples_path, 'r', encoding='utf-8') as f:
            content = f.read()

        assert "Example 2:" in content
        assert "capability" in content.lower() or "tool" in content.lower()

    def test_example_3_test_suite(self):
        """Test Example 3: Test Suite exists."""
        examples_path = SKILL_DIR / "EXAMPLES.md"
        with open(examples_path, 'r', encoding='utf-8') as f:
            content = f.read()

        assert "Example 3:" in content
        assert "test" in content.lower()

    def test_example_4_coordination(self):
        """Test Example 4: Multi-Agent Coordination exists."""
        examples_path = SKILL_DIR / "EXAMPLES.md"
        with open(examples_path, 'r', encoding='utf-8') as f:
            content = f.read()

        assert "Example 4:" in content
        assert "handoff" in content.lower() or "coordination" in content.lower()

    def test_example_5_end_to_end(self):
        """Test Example 5: End-to-End Workflow exists."""
        examples_path = SKILL_DIR / "EXAMPLES.md"
        with open(examples_path, 'r', encoding='utf-8') as f:
            content = f.read()

        assert "Example 5:" in content
        assert "end-to-end" in content.lower() or "workflow" in content.lower()

    def test_examples_have_code(self):
        """Test that examples contain code blocks."""
        examples_path = SKILL_DIR / "EXAMPLES.md"
        with open(examples_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Count code blocks
        code_blocks = content.count("```")

        # Should be at least 10 code blocks (5 examples * 2 blocks each minimum)
        assert code_blocks >= 10, \
            f"Expected at least 10 code blocks, found {code_blocks}"


class TestGotchas:
    """Test gotchas and troubleshooting documentation."""

    def test_gotchas_md_exists(self):
        """Test GOTCHAS.md exists."""
        gotchas_path = SKILL_DIR / "GOTCHAS.md"
        assert gotchas_path.exists(), "GOTCHAS.md missing"

    def test_top_3_gotchas_documented(self):
        """Test that top 3 gotchas from SKILL.md are in GOTCHAS.md."""
        skill_path = SKILL_DIR / "SKILL.md"
        gotchas_path = SKILL_DIR / "GOTCHAS.md"

        with open(skill_path, 'r', encoding='utf-8') as f:
            skill_content = f.read()

        with open(gotchas_path, 'r', encoding='utf-8') as f:
            gotchas_content = f.read()

        # Top 3 gotchas from SKILL.md
        top_gotchas = [
            "Scope Creep",
            "Under-Specification",
            "Coordination Failures"
        ]

        for gotcha in top_gotchas:
            assert gotcha in gotchas_content, \
                f"Top gotcha not detailed in GOTCHAS.md: {gotcha}"

    def test_debugging_strategies_present(self):
        """Test that debugging strategies are documented."""
        gotchas_path = SKILL_DIR / "GOTCHAS.md"
        with open(gotchas_path, 'r', encoding='utf-8') as f:
            content = f.read()

        assert "debug" in content.lower() or "Debugging" in content
        assert "troubleshoot" in content.lower() or "Troubleshooting" in content


class TestKnowledge:
    """Test knowledge base documentation."""

    def test_knowledge_md_exists(self):
        """Test KNOWLEDGE.md exists."""
        knowledge_path = SKILL_DIR / "KNOWLEDGE.md"
        assert knowledge_path.exists(), "KNOWLEDGE.md missing"

    def test_agent_architecture_patterns(self):
        """Test that agent architecture patterns are documented."""
        knowledge_path = SKILL_DIR / "KNOWLEDGE.md"
        with open(knowledge_path, 'r', encoding='utf-8') as f:
            content = f.read()

        architectures = [
            "Reactive",
            "Deliberative",
            "Hybrid"
        ]

        for arch in architectures:
            assert arch in content, f"Architecture pattern missing: {arch}"

    def test_bdi_model_documented(self):
        """Test that BDI model is documented."""
        knowledge_path = SKILL_DIR / "KNOWLEDGE.md"
        with open(knowledge_path, 'r', encoding='utf-8') as f:
            content = f.read()

        assert "BDI" in content or "Beliefs, Desires, Intentions" in content
        assert "Beliefs" in content
        assert "Desires" in content
        assert "Intentions" in content

    def test_multi_agent_systems_documented(self):
        """Test that multi-agent systems theory is documented."""
        knowledge_path = SKILL_DIR / "KNOWLEDGE.md"
        with open(knowledge_path, 'r', encoding='utf-8') as f:
            content = f.read()

        assert "multi-agent" in content.lower() or "Multi-Agent" in content
        assert "coordination" in content.lower()

    def test_testing_strategies_documented(self):
        """Test that testing strategies are documented."""
        knowledge_path = SKILL_DIR / "KNOWLEDGE.md"
        with open(knowledge_path, 'r', encoding='utf-8') as f:
            content = f.read()

        test_types = [
            "unit test" in content.lower(),
            "integration test" in content.lower(),
            "acceptance test" in content.lower() or "end-to-end" in content.lower()
        ]

        assert any(test_types), "Testing strategies not documented"

    def test_framework_patterns_documented(self):
        """Test that LangGraph, AutoGen, or CrewAI patterns are documented."""
        knowledge_path = SKILL_DIR / "KNOWLEDGE.md"
        with open(knowledge_path, 'r', encoding='utf-8') as f:
            content = f.read()

        frameworks = ["LangGraph", "AutoGen", "CrewAI"]
        framework_mentioned = any(fw in content for fw in frameworks)

        assert framework_mentioned, "No agent frameworks documented"


class TestReference:
    """Test API reference documentation."""

    def test_reference_md_exists(self):
        """Test REFERENCE.md exists."""
        reference_path = SKILL_DIR / "REFERENCE.md"
        assert reference_path.exists(), "REFERENCE.md missing"

    def test_capability_taxonomy_present(self):
        """Test that capability taxonomy is documented."""
        reference_path = SKILL_DIR / "REFERENCE.md"
        with open(reference_path, 'r', encoding='utf-8') as f:
            content = f.read()

        assert "Capability Taxonomy" in content or "capability" in content.lower()

    def test_tool_selection_matrix_present(self):
        """Test that tool selection matrix is documented."""
        reference_path = SKILL_DIR / "REFERENCE.md"
        with open(reference_path, 'r', encoding='utf-8') as f:
            content = f.read()

        assert "Tool Selection" in content or "tool" in content.lower()

    def test_lifecycle_states_documented(self):
        """Test that lifecycle states are documented."""
        reference_path = SKILL_DIR / "REFERENCE.md"
        with open(reference_path, 'r', encoding='utf-8') as f:
            content = f.read()

        states = [
            "UNINITIALIZED" in content or "uninitialized" in content,
            "READY" in content or "ready" in content,
            "EXECUTING" in content or "executing" in content,
            "COMPLETED" in content or "completed" in content
        ]

        assert any(states), "Lifecycle states not documented"


class TestDocumentationQuality:
    """Test overall documentation quality."""

    def test_no_todo_markers(self):
        """Test that there are no TODO markers in documentation."""
        for filename in SKILL_FILES:
            file_path = SKILL_DIR / filename
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            # Allow TODOs in test checklist context
            if "TODO" in content and "[ ]" not in content:
                pytest.fail(f"TODO marker found in {filename}")

    def test_all_files_have_headers(self):
        """Test that all files start with proper headers."""
        for filename in SKILL_FILES:
            file_path = SKILL_DIR / filename
            with open(file_path, 'r', encoding='utf-8') as f:
                first_line = f.readline()

            assert first_line.startswith("#"), \
                f"{filename} missing header (should start with #)"

    def test_skill_md_has_purpose(self):
        """Test that SKILL.md has Purpose section."""
        skill_path = SKILL_DIR / "SKILL.md"
        with open(skill_path, 'r', encoding='utf-8') as f:
            content = f.read()

        assert "## Purpose" in content, "SKILL.md missing Purpose section"

    def test_skill_md_has_quick_start(self):
        """Test that SKILL.md has Quick Start section."""
        skill_path = SKILL_DIR / "SKILL.md"
        with open(skill_path, 'r', encoding='utf-8') as f:
            content = f.read()

        assert "## Quick Start" in content or "Quick Start" in content, \
            "SKILL.md missing Quick Start section"


class TestIntegrationPoints:
    """Test integration documentation."""

    def test_ai_engineer_integration_documented(self):
        """Test that integration with ai-engineer agent is documented."""
        skill_path = SKILL_DIR / "SKILL.md"
        with open(skill_path, 'r', encoding='utf-8') as f:
            content = f.read()

        assert "ai-engineer" in content or "AI Engineer" in content, \
            "Integration with ai-engineer not documented"

    def test_dependencies_documented(self):
        """Test that dependencies on other skills are documented."""
        skill_path = SKILL_DIR / "SKILL.md"
        with open(skill_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Check for dependency mentions
        dependencies = [
            "AI Agent Tool Builder" in content,
            "Context Engineering" in content,
            "Multi-Agent Coordination" in content
        ]

        assert any(dependencies), "Dependencies not documented"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
