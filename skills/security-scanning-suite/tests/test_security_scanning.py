"""Tests for security-scanning-suite refactoring."""

import os
from pathlib import Path


class TestSkillRefactoring:
    """Test suite for security-scanning-suite skill refactoring."""

    @property
    def skill_dir(self):
        """Get the skill directory path."""
        return Path(__file__).parent.parent

    def test_skill_md_line_count(self):
        """Test that SKILL.md is under 500 lines."""
        skill_file = self.skill_dir / "SKILL.md"
        assert skill_file.exists(), "SKILL.md does not exist"

        with open(skill_file, 'r', encoding='utf-8') as f:
            lines = f.readlines()

        line_count = len(lines)
        assert line_count < 500, f"SKILL.md has {line_count} lines (should be < 500)"
        print(f"[PASS] SKILL.md: {line_count} lines")

    def test_all_files_exist(self):
        """Test that all required files exist."""
        required_files = [
            "SKILL.md",
            "KNOWLEDGE.md",
            "GOTCHAS.md",
            "PATTERNS.md",
            "EXAMPLES.md",
            "REFERENCE.md"
        ]

        for filename in required_files:
            file_path = self.skill_dir / filename
            assert file_path.exists(), f"{filename} does not exist"
            print(f"[PASS] {filename} exists")

    def test_cross_references_valid(self):
        """Test that cross-references between files are valid."""
        skill_file = self.skill_dir / "SKILL.md"

        with open(skill_file, 'r', encoding='utf-8') as f:
            content = f.read()

        # Check for cross-references
        expected_refs = [
            "[KNOWLEDGE.md]",
            "[PATTERNS.md]",
            "[GOTCHAS.md]",
            "[EXAMPLES.md]",
            "[REFERENCE.md]"
        ]

        for ref in expected_refs:
            assert ref in content, f"Missing reference to {ref} in SKILL.md"
            print(f"[PASS] Reference to {ref} found")

    def test_line_reduction_achieved(self):
        """Test that significant line reduction was achieved."""
        skill_file = self.skill_dir / "SKILL.md"

        with open(skill_file, 'r', encoding='utf-8') as f:
            new_lines = len(f.readlines())

        original_lines = 901  # Original SKILL.md was 901 lines
        reduction_percentage = ((original_lines - new_lines) / original_lines) * 100

        assert reduction_percentage >= 45, f"Only {reduction_percentage:.1f}% reduction (target: 45%+)"
        print(f"[PASS] Line reduction: {reduction_percentage:.1f}% ({original_lines} -> {new_lines} lines)")


if __name__ == "__main__":
    # Run tests
    test_suite = TestSkillRefactoring()

    print("Running Security Scanning Suite Refactoring Tests")
    print("="*50)

    # Run each test
    tests = [
        test_suite.test_skill_md_line_count,
        test_suite.test_all_files_exist,
        test_suite.test_cross_references_valid,
        test_suite.test_line_reduction_achieved,
    ]

    passed = 0
    failed = 0

    for test in tests:
        try:
            print(f"\n{test.__name__}:")
            test()
            passed += 1
        except AssertionError as e:
            print(f"[FAIL] {e}")
            failed += 1
        except Exception as e:
            print(f"[ERROR] {e}")
            failed += 1

    print("\n" + "="*50)
    print(f"Results: {passed} passed, {failed} failed")

    if failed == 0:
        print("[SUCCESS] All tests passed!")
    else:
        print("[FAILURE] Some tests failed")
        exit(1)
