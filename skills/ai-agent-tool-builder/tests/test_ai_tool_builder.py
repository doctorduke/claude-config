"""
Tests for AI Agent Tool Builder Skill

Validates skill structure, content quality, and completeness.
"""

import os
import re
import json
from pathlib import Path


SKILL_DIR = Path(__file__).parent.parent
REQUIRED_FILES = [
    "SKILL.md",
    "KNOWLEDGE.md",
    "PATTERNS.md",
    "EXAMPLES.md",
    "GOTCHAS.md",
    "REFERENCE.md"
]


class TestSkillStructure:
    """Test skill file structure and organization."""

    def test_all_required_files_exist(self):
        """Verify all 6 required files exist."""
        for filename in REQUIRED_FILES:
            file_path = SKILL_DIR / filename
            assert file_path.exists(), f"Missing required file: {filename}"

    def test_skill_md_under_500_lines(self):
        """SKILL.md must be under 500 lines (progressive disclosure)."""
        skill_path = SKILL_DIR / "SKILL.md"
        with open(skill_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()

        line_count = len(lines)
        assert line_count < 500, \
            f"SKILL.md has {line_count} lines, must be < 500"

    def test_skill_md_has_front_matter(self):
        """SKILL.md must have valid front matter."""
        skill_path = SKILL_DIR / "SKILL.md"
        with open(skill_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Check for front matter delimiters
        assert content.startswith("---"), "Missing front matter start"
        assert "\n---\n" in content, "Missing front matter end"

        # Extract front matter
        front_matter = content.split("---")[1]

        # Required fields
        assert "name:" in front_matter, "Missing 'name' in front matter"
        assert "description:" in front_matter, "Missing 'description' in front matter"
        assert "allowed-tools:" in front_matter, "Missing 'allowed-tools' in front matter"


class TestSkillContent:
    """Test skill content quality and completeness."""

    def test_five_patterns_documented(self):
        """PATTERNS.md must document 5 implementation patterns."""
        patterns_path = SKILL_DIR / "PATTERNS.md"
        with open(patterns_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Look for pattern headers
        pattern_headers = re.findall(r'^##\s+Pattern\s+\d+:', content, re.MULTILINE)
        assert len(pattern_headers) >= 5, \
            f"Found {len(pattern_headers)} patterns, expected 5"

    def test_patterns_have_implementation_code(self):
        """Each pattern must include implementation code."""
        patterns_path = SKILL_DIR / "PATTERNS.md"
        with open(patterns_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Count code blocks
        code_blocks = re.findall(r'```\w+', content)
        assert len(code_blocks) >= 10, \
            f"Found {len(code_blocks)} code blocks, expected at least 10 (2 per pattern)"

    def test_examples_have_working_code(self):
        """EXAMPLES.md must have syntactically valid code."""
        examples_path = SKILL_DIR / "EXAMPLES.md"
        with open(examples_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Extract Python code blocks
        python_blocks = re.findall(r'```python\n(.*?)```', content, re.DOTALL)

        assert len(python_blocks) >= 5, \
            f"Found {len(python_blocks)} Python examples, expected at least 5"

        # Basic syntax check (no obvious errors)
        for i, code in enumerate(python_blocks):
            # Skip if it's just partial/template code
            if "..." in code or "# Implementation" in code:
                continue

            # Check for basic syntax elements
            if "def " in code or "class " in code:
                # Should have proper indentation
                assert "    " in code or "\t" in code, \
                    f"Code block {i+1} missing indentation"

    def test_mcp_server_examples_present(self):
        """Examples must include both FastMCP and TypeScript MCP servers."""
        examples_path = SKILL_DIR / "EXAMPLES.md"
        with open(examples_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Check for FastMCP example
        assert "FastMCP" in content, "Missing FastMCP example"
        assert "from fastmcp import FastMCP" in content, \
            "Missing FastMCP import in example"

        # Check for TypeScript example
        assert "TypeScript" in content or "typescript" in content, \
            "Missing TypeScript example"
        assert "@modelcontextprotocol/sdk" in content, \
            "Missing MCP SDK import in TypeScript example"

    def test_gotchas_document_common_issues(self):
        """GOTCHAS.md must document common issues and solutions."""
        gotchas_path = SKILL_DIR / "GOTCHAS.md"
        with open(gotchas_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Check for key gotchas mentioned in SKILL.md
        required_gotchas = [
            "Schema",
            "Error",
            "Security"
        ]

        for gotcha in required_gotchas:
            assert gotcha in content, \
                f"Missing gotcha topic: {gotcha}"

    def test_knowledge_covers_mcp_architecture(self):
        """KNOWLEDGE.md must cover MCP architecture and concepts."""
        knowledge_path = SKILL_DIR / "KNOWLEDGE.md"
        with open(knowledge_path, 'r', encoding='utf-8') as f:
            content = f.read()

        required_topics = [
            "Model Context Protocol",
            "Function Calling",
            "Tool Design",
            "JSON Schema",
            "Security"
        ]

        for topic in required_topics:
            assert topic in content, \
                f"Missing knowledge topic: {topic}"

    def test_reference_has_api_documentation(self):
        """REFERENCE.md must include API documentation."""
        reference_path = SKILL_DIR / "REFERENCE.md"
        with open(reference_path, 'r', encoding='utf-8') as f:
            content = f.read()

        required_sections = [
            "FastMCP",
            "TypeScript SDK",
            "JSON Schema",
            "MCP Protocol"
        ]

        for section in required_sections:
            assert section in content, \
                f"Missing reference section: {section}"


class TestCrossReferences:
    """Test that cross-references between files are valid."""

    def test_skill_md_links_to_other_files(self):
        """SKILL.md must link to detailed documentation files."""
        skill_path = SKILL_DIR / "SKILL.md"
        with open(skill_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Check for links to other files
        expected_links = [
            "KNOWLEDGE.md",
            "PATTERNS.md",
            "EXAMPLES.md",
            "GOTCHAS.md",
            "REFERENCE.md"
        ]

        for link in expected_links:
            assert link in content, \
                f"SKILL.md missing link to {link}"

    def test_linked_files_exist(self):
        """All linked files must exist."""
        for filename in REQUIRED_FILES:
            file_path = SKILL_DIR / filename
            assert file_path.exists(), \
                f"Linked file does not exist: {filename}"


class TestCodeExamples:
    """Test that code examples are valid and functional."""

    def test_fastmcp_example_syntax(self):
        """FastMCP example should have valid Python syntax."""
        examples_path = SKILL_DIR / "EXAMPLES.md"
        with open(examples_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Find FastMCP example
        match = re.search(
            r'```python\n# file_operations_server\.py\n(.*?)```',
            content,
            re.DOTALL
        )

        assert match, "FastMCP example not found"

        code = match.group(1)

        # Basic validation
        assert "from fastmcp import FastMCP" in code
        assert "mcp = FastMCP(" in code
        assert "@mcp.tool()" in code
        assert "if __name__ == \"__main__\":" in code

    def test_typescript_example_syntax(self):
        """TypeScript example should have valid structure."""
        examples_path = SKILL_DIR / "EXAMPLES.md"
        with open(examples_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Find TypeScript example
        typescript_blocks = re.findall(
            r'```typescript\n(.*?)```',
            content,
            re.DOTALL
        )

        assert len(typescript_blocks) >= 1, "No TypeScript examples found"

        code = typescript_blocks[0]

        # Basic validation
        assert "import" in code
        assert "Server" in code
        assert "tools" in code.lower()

    def test_json_schema_examples_valid(self):
        """JSON Schema examples should be valid JSON."""
        examples_path = SKILL_DIR / "EXAMPLES.md"
        with open(examples_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Find JSON blocks
        json_blocks = re.findall(r'```json\n(.*?)```', content, re.DOTALL)

        assert len(json_blocks) >= 2, \
            f"Found {len(json_blocks)} JSON examples, expected at least 2"

        # Validate JSON syntax
        for i, json_str in enumerate(json_blocks[:5]):  # Test first 5
            try:
                json.loads(json_str)
            except json.JSONDecodeError as e:
                assert False, f"Invalid JSON in block {i+1}: {e}"


class TestDocumentationQuality:
    """Test documentation quality and completeness."""

    def test_skill_has_purpose_section(self):
        """SKILL.md must have Purpose section."""
        skill_path = SKILL_DIR / "SKILL.md"
        with open(skill_path, 'r', encoding='utf-8') as f:
            content = f.read()

        assert "## Purpose" in content, "Missing Purpose section"

    def test_skill_has_quick_start(self):
        """SKILL.md must have Quick Start section."""
        skill_path = SKILL_DIR / "SKILL.md"
        with open(skill_path, 'r', encoding='utf-8') as f:
            content = f.read()

        assert "## Quick Start" in content or "Quick Start" in content, \
            "Missing Quick Start section"

    def test_skill_has_gotchas_summary(self):
        """SKILL.md must summarize top gotchas."""
        skill_path = SKILL_DIR / "SKILL.md"
        with open(skill_path, 'r', encoding='utf-8') as f:
            content = f.read()

        assert "Gotchas" in content or "gotchas" in content, \
            "Missing gotchas summary"

    def test_patterns_have_when_to_use(self):
        """Each pattern should explain when to use it."""
        patterns_path = SKILL_DIR / "PATTERNS.md"
        with open(patterns_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Should have multiple "When to Use" sections
        when_to_use_count = content.count("### When to Use")
        assert when_to_use_count >= 5, \
            f"Found {when_to_use_count} 'When to Use' sections, expected 5"

    def test_examples_have_use_cases(self):
        """Examples should explain their use cases."""
        examples_path = SKILL_DIR / "EXAMPLES.md"
        with open(examples_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Should explain use cases
        assert "Use Case" in content or "use case" in content, \
            "Missing use case explanations"


class TestSecurityDocumentation:
    """Test that security best practices are documented."""

    def test_security_section_in_knowledge(self):
        """KNOWLEDGE.md must have security section."""
        knowledge_path = SKILL_DIR / "KNOWLEDGE.md"
        with open(knowledge_path, 'r', encoding='utf-8') as f:
            content = f.read()

        assert "## Security" in content or "Security Considerations" in content, \
            "Missing security section"

    def test_security_examples_in_gotchas(self):
        """GOTCHAS.md must document security vulnerabilities."""
        gotchas_path = SKILL_DIR / "GOTCHAS.md"
        with open(gotchas_path, 'r', encoding='utf-8') as f:
            content = f.read()

        security_topics = [
            "injection",
            "security",
            "validation"
        ]

        for topic in security_topics:
            assert topic.lower() in content.lower(), \
                f"Missing security topic: {topic}"


class TestIntegrationPoints:
    """Test integration with other skills and agents."""

    def test_documents_integration_with_agents(self):
        """SKILL.md should document which agents use this skill."""
        skill_path = SKILL_DIR / "SKILL.md"
        with open(skill_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Should mention relevant agents
        relevant_agents = [
            "mcp-server-engineer",
            "mcp-tool-engineer"
        ]

        mentions = sum(1 for agent in relevant_agents if agent in content)
        assert mentions >= 1, \
            "Should mention at least one relevant agent"


def run_all_tests():
    """Run all tests and report results."""
    import sys

    test_classes = [
        TestSkillStructure,
        TestSkillContent,
        TestCrossReferences,
        TestCodeExamples,
        TestDocumentationQuality,
        TestSecurityDocumentation,
        TestIntegrationPoints
    ]

    total_tests = 0
    passed_tests = 0
    failed_tests = []

    for test_class in test_classes:
        print(f"\n{test_class.__name__}:")
        instance = test_class()

        for method_name in dir(instance):
            if method_name.startswith("test_"):
                total_tests += 1
                method = getattr(instance, method_name)

                try:
                    method()
                    passed_tests += 1
                    print(f"  [PASS] {method_name}")
                except AssertionError as e:
                    failed_tests.append((test_class.__name__, method_name, str(e)))
                    print(f"  [FAIL] {method_name}: {e}")
                except Exception as e:
                    failed_tests.append((test_class.__name__, method_name, f"Exception: {e}"))
                    print(f"  [FAIL] {method_name}: Exception: {e}")

    print(f"\n{'='*60}")
    print(f"Results: {passed_tests}/{total_tests} tests passed")

    if failed_tests:
        print(f"\nFailed tests:")
        for test_class, method, error in failed_tests:
            print(f"  {test_class}.{method}")
            print(f"    {error}")
        sys.exit(1)
    else:
        print("All tests passed!")
        sys.exit(0)


if __name__ == "__main__":
    run_all_tests()
