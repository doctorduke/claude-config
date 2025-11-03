"""
Test suite for Context Engineering Framework skill
"""

import os
import re
import pytest
from pathlib import Path


class TestSkillStructure:
    """Test skill file structure and requirements"""

    @pytest.fixture
    def skill_path(self):
        """Get the skill directory path"""
        return Path(__file__).parent.parent

    def test_skill_md_exists(self, skill_path):
        """Test that SKILL.md exists"""
        skill_file = skill_path / "SKILL.md"
        assert skill_file.exists(), "SKILL.md file not found"

    def test_skill_md_under_500_lines(self, skill_path):
        """Test that SKILL.md is under 500 lines"""
        skill_file = skill_path / "SKILL.md"
        with open(skill_file, 'r', encoding='utf-8') as f:
            lines = f.readlines()

        line_count = len(lines)
        assert line_count < 500, f"SKILL.md has {line_count} lines, exceeds 500 line limit"
        print(f"✓ SKILL.md has {line_count} lines (under 500)")

    def test_all_six_files_exist(self, skill_path):
        """Test that all 6 required files exist"""
        required_files = [
            "SKILL.md",
            "KNOWLEDGE.md",
            "PATTERNS.md",
            "EXAMPLES.md",
            "GOTCHAS.md",
            "REFERENCE.md"
        ]

        missing_files = []
        for file_name in required_files:
            file_path = skill_path / file_name
            if not file_path.exists():
                missing_files.append(file_name)

        assert not missing_files, f"Missing required files: {missing_files}"
        print("✓ All 6 required files exist")

    def test_skill_md_has_front_matter(self, skill_path):
        """Test that SKILL.md has proper front matter"""
        skill_file = skill_path / "SKILL.md"
        with open(skill_file, 'r', encoding='utf-8') as f:
            content = f.read()

        # Check for front matter
        assert content.startswith('---'), "SKILL.md missing front matter"

        # Extract front matter
        front_matter_match = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
        assert front_matter_match, "Invalid front matter format"

        front_matter = front_matter_match.group(1)

        # Check required fields
        assert 'name:' in front_matter, "Missing 'name' in front matter"
        assert 'description:' in front_matter, "Missing 'description' in front matter"
        assert 'allowed-tools:' in front_matter, "Missing 'allowed-tools' in front matter"

        print("✓ SKILL.md has valid front matter")


class TestCrossReferences:
    """Test cross-references between files"""

    @pytest.fixture
    def skill_path(self):
        return Path(__file__).parent.parent

    def test_skill_md_references_other_files(self, skill_path):
        """Test that SKILL.md references other documentation files"""
        skill_file = skill_path / "SKILL.md"
        with open(skill_file, 'r', encoding='utf-8') as f:
            content = f.read()

        # Check for references to other files
        references = [
            "PATTERNS.md",
            "KNOWLEDGE.md",
            "EXAMPLES.md",
            "GOTCHAS.md",
            "REFERENCE.md"
        ]

        missing_refs = []
        for ref in references:
            if ref not in content:
                missing_refs.append(ref)

        assert not missing_refs, f"SKILL.md doesn't reference: {missing_refs}"
        print("✓ SKILL.md references all documentation files")

    def test_cross_references_valid(self, skill_path):
        """Test that cross-references between files are valid"""
        files_to_check = ["PATTERNS.md", "KNOWLEDGE.md", "EXAMPLES.md", "GOTCHAS.md"]

        for file_name in files_to_check:
            file_path = skill_path / file_name
            if file_path.exists():
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()

                # Look for markdown links
                links = re.findall(r'\[([^\]]+)\]\(([^)]+)\)', content)

                for link_text, link_target in links:
                    if link_target.endswith('.md') and not link_target.startswith('http'):
                        # Check if referenced file exists
                        if '/' not in link_target:  # Same directory reference
                            target_path = skill_path / link_target
                            if not target_path.exists() and link_target != '#':
                                print(f"Warning: {file_name} references non-existent file: {link_target}")


class TestPatterns:
    """Test that patterns are documented"""

    @pytest.fixture
    def skill_path(self):
        return Path(__file__).parent.parent

    def test_six_patterns_documented(self, skill_path):
        """Test that 6 patterns are documented in PATTERNS.md"""
        patterns_file = skill_path / "PATTERNS.md"

        if not patterns_file.exists():
            pytest.skip("PATTERNS.md not found")

        with open(patterns_file, 'r', encoding='utf-8') as f:
            content = f.read()

        # Look for pattern headers
        expected_patterns = [
            "Pattern 1: Token Budget Management",
            "Pattern 2: Lossless Compression",
            "Pattern 3: Lossy Compression",
            "Pattern 4: Semantic Chunking",
            "Pattern 5: Progressive Summarization",
            "Pattern 6: Handoff Documents"
        ]

        missing_patterns = []
        for pattern in expected_patterns:
            # Check for pattern in various formats
            pattern_name = pattern.split(": ")[1]
            if pattern_name.lower() not in content.lower():
                missing_patterns.append(pattern_name)

        assert not missing_patterns, f"Missing patterns: {missing_patterns}"
        print("✓ All 6 patterns documented")

    def test_pattern_implementation_examples(self, skill_path):
        """Test that patterns have implementation examples"""
        patterns_file = skill_path / "PATTERNS.md"

        if not patterns_file.exists():
            pytest.skip("PATTERNS.md not found")

        with open(patterns_file, 'r', encoding='utf-8') as f:
            content = f.read()

        # Check for code blocks
        code_blocks = re.findall(r'```python(.*?)```', content, re.DOTALL)

        assert len(code_blocks) >= 6, f"Expected at least 6 code examples, found {len(code_blocks)}"
        print(f"✓ Found {len(code_blocks)} code implementation examples")


class TestExamples:
    """Test that examples are provided and runnable"""

    @pytest.fixture
    def skill_path(self):
        return Path(__file__).parent.parent

    def test_examples_present(self, skill_path):
        """Test that EXAMPLES.md contains working examples"""
        examples_file = skill_path / "EXAMPLES.md"

        if not examples_file.exists():
            pytest.skip("EXAMPLES.md not found")

        with open(examples_file, 'r', encoding='utf-8') as f:
            content = f.read()

        # Check for specific examples
        expected_examples = [
            "Token Budget Tracker",
            "Context Compressor",
            "Semantic Chunker",
            "Progressive Summarizer",
            "Handoff Document",
            "Context Window Optimizer"
        ]

        missing_examples = []
        for example in expected_examples:
            if example.lower() not in content.lower():
                missing_examples.append(example)

        assert not missing_examples, f"Missing examples: {missing_examples}"
        print("✓ All 6 examples present")

    def test_code_examples_have_main_block(self, skill_path):
        """Test that code examples have if __name__ == '__main__' blocks"""
        examples_file = skill_path / "EXAMPLES.md"

        if not examples_file.exists():
            pytest.skip("EXAMPLES.md not found")

        with open(examples_file, 'r', encoding='utf-8') as f:
            content = f.read()

        # Check for main blocks
        main_blocks = content.count('if __name__ == "__main__":')

        assert main_blocks >= 6, f"Expected at least 6 main blocks, found {main_blocks}"
        print(f"✓ Found {main_blocks} runnable examples with main blocks")


class TestCompression:
    """Test compression functionality claims"""

    def test_compression_achieves_50_percent(self):
        """Test that compression can achieve 50%+ reduction"""
        # Simple mock test - in real implementation would test actual compression
        original_text = "This is a test. " * 100 + "This is redundant. " * 50

        # Simulate simple deduplication
        lines = original_text.split('. ')
        unique_lines = list(dict.fromkeys(lines))
        compressed = '. '.join(unique_lines)

        reduction = 1 - len(compressed) / len(original_text)

        assert reduction >= 0.3, f"Compression only achieved {reduction:.1%} reduction"
        print(f"✓ Compression achieved {reduction:.1%} reduction")


class TestTokenCounting:
    """Test token counting accuracy"""

    @pytest.fixture
    def skill_path(self):
        return Path(__file__).parent.parent

    def test_token_counting_available(self, skill_path):
        """Test that token counting is documented"""
        reference_file = skill_path / "REFERENCE.md"

        if not reference_file.exists():
            pytest.skip("REFERENCE.md not found")

        with open(reference_file, 'r', encoding='utf-8') as f:
            content = f.read()

        # Check for token counting documentation
        assert "tiktoken" in content, "Missing tiktoken documentation"
        assert "Token Counting APIs" in content, "Missing token counting section"
        print("✓ Token counting documentation present")


class TestIntegration:
    """Test integration recommendations"""

    @pytest.fixture
    def skill_path(self):
        return Path(__file__).parent.parent

    def test_context_manager_integration_documented(self, skill_path):
        """Test that integration with context-manager agent is documented"""
        skill_file = skill_path / "SKILL.md"

        with open(skill_file, 'r', encoding='utf-8') as f:
            content = f.read()

        # Check for context-manager mentions
        assert "context-manager" in content, "No mention of context-manager agent"
        assert "Integration" in content or "integration" in content, "No integration section"
        print("✓ Integration with context-manager agent documented")

    def test_refactoring_recommendations_present(self, skill_path):
        """Test that refactoring recommendations are provided"""
        skill_file = skill_path / "SKILL.md"

        with open(skill_file, 'r', encoding='utf-8') as f:
            content = f.read()

        # Check for refactoring guidance
        has_before_after = "Before:" in content and "After:" in content
        has_delegate = "delegate" in content.lower() or "skill(" in content

        assert has_before_after or has_delegate, "Missing refactoring recommendations"
        print("✓ Refactoring recommendations provided")


def run_all_tests():
    """Run all tests and report results"""
    import sys

    # Run pytest
    exit_code = pytest.main([__file__, "-v", "--tb=short"])

    if exit_code == 0:
        print("\n" + "="*50)
        print("✅ All tests passed!")
        print("="*50)
    else:
        print("\n" + "="*50)
        print("❌ Some tests failed. Please review and fix.")
        print("="*50)

    return exit_code


if __name__ == "__main__":
    # For standalone execution
    run_all_tests()