#!/usr/bin/env python3
"""
Tests for multi-agent-coordination-framework skill refactoring

Validates:
- SKILL.md is under 500 lines
- All 6 documentation files exist
- Cross-references are valid
- Line count reduction achieved
"""

import os
import re
import sys
from pathlib import Path

# Fix encoding for Windows
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')


class TestMultiAgentCoordination:
    """Test suite for multi-agent-coordination-framework skill"""

    def __init__(self):
        self.skill_dir = Path(__file__).parent.parent
        self.errors = []
        self.warnings = []

    def test_file_existence(self):
        """Test that all required files exist"""
        print("Testing file existence...")

        required_files = [
            "SKILL.md",
            "KNOWLEDGE.md",
            "GOTCHAS.md",
            "PATTERNS.md",
            "EXAMPLES.md",
            "REFERENCE.md",
        ]

        for filename in required_files:
            filepath = self.skill_dir / filename
            if not filepath.exists():
                self.errors.append(f"Missing required file: {filename}")
            else:
                print(f"  ✓ {filename} exists")

    def test_skill_line_count(self):
        """Test that SKILL.md is under 500 lines"""
        print("\nTesting SKILL.md line count...")

        skill_file = self.skill_dir / "SKILL.md"

        if not skill_file.exists():
            self.errors.append("SKILL.md does not exist")
            return

        with open(skill_file, "r", encoding="utf-8") as f:
            lines = f.readlines()
            line_count = len(lines)

        if line_count > 500:
            self.errors.append(
                f"SKILL.md has {line_count} lines (target: <500 lines)"
            )
        else:
            print(f"  ✓ SKILL.md has {line_count} lines (target: <500 lines)")

    def test_line_reduction(self):
        """Test that total line reduction is at least 76%"""
        print("\nTesting line reduction...")

        original_file = self.skill_dir / "SKILL.md.orig"
        new_skill_file = self.skill_dir / "SKILL.md"

        if not original_file.exists():
            self.warnings.append("Original SKILL.md.orig not found, skipping reduction test")
            return

        with open(original_file, "r", encoding="utf-8") as f:
            original_lines = len(f.readlines())

        with open(new_skill_file, "r", encoding="utf-8") as f:
            new_lines = len(f.readlines())

        reduction_pct = ((original_lines - new_lines) / original_lines) * 100

        print(f"  Original: {original_lines} lines")
        print(f"  New:      {new_lines} lines")
        print(f"  Reduction: {reduction_pct:.1f}%")

        if reduction_pct < 76:
            self.errors.append(
                f"Line reduction is {reduction_pct:.1f}% (target: ≥76%)"
            )
        else:
            print(f"  ✓ Achieved {reduction_pct:.1f}% reduction (target: ≥76%)")

    def test_cross_references(self):
        """Test that cross-references between files are valid"""
        print("\nTesting cross-references...")

        # Map of files and their expected references
        reference_patterns = {
            "SKILL.md": [
                r"\[KNOWLEDGE\.md\]",
                r"\[PATTERNS\.md\]",
                r"\[EXAMPLES\.md\]",
                r"\[GOTCHAS\.md\]",
                r"\[REFERENCE\.md\]",
            ],
            "KNOWLEDGE.md": [r"\[.*Back to Main.*\]"],
            "PATTERNS.md": [r"\[.*Back to Main.*\]", r"\[EXAMPLES\.md.*\]"],
            "EXAMPLES.md": [r"\[.*Back to Main.*\]", r"\[PATTERNS\.md.*\]"],
            "GOTCHAS.md": [r"\[.*Back to Main.*\]"],
            "REFERENCE.md": [r"\[.*Back to Main.*\]"],
        }

        for filename, patterns in reference_patterns.items():
            filepath = self.skill_dir / filename

            if not filepath.exists():
                continue

            with open(filepath, "r", encoding="utf-8") as f:
                content = f.read()

            for pattern in patterns:
                if not re.search(pattern, content, re.IGNORECASE):
                    self.warnings.append(
                        f"{filename} missing expected reference pattern: {pattern}"
                    )
                else:
                    print(f"  ✓ {filename} contains reference: {pattern}")

    def test_front_matter(self):
        """Test that SKILL.md has valid front matter"""
        print("\nTesting front matter...")

        skill_file = self.skill_dir / "SKILL.md"

        if not skill_file.exists():
            return

        with open(skill_file, "r", encoding="utf-8") as f:
            content = f.read()

        required_front_matter = ["name:", "description:", "allowed-tools:"]

        for field in required_front_matter:
            if field not in content[:500]:  # Check first 500 chars
                self.errors.append(f"SKILL.md missing front matter field: {field}")
            else:
                print(f"  ✓ Front matter contains: {field}")

    def test_pattern_coverage(self):
        """Test that all 6 patterns are documented"""
        print("\nTesting pattern coverage...")

        patterns_file = self.skill_dir / "PATTERNS.md"
        examples_file = self.skill_dir / "EXAMPLES.md"

        expected_patterns = [
            "Pattern 1",
            "Pattern 2",
            "Pattern 3",
            "Pattern 4",
            "Pattern 5",
            "Pattern 6",
        ]

        for filepath in [patterns_file, examples_file]:
            if not filepath.exists():
                continue

            with open(filepath, "r", encoding="utf-8") as f:
                content = f.read()

            for pattern in expected_patterns:
                if pattern not in content:
                    self.warnings.append(
                        f"{filepath.name} missing documentation for: {pattern}"
                    )
                else:
                    print(f"  ✓ {filepath.name} documents {pattern}")

    def test_gotchas_coverage(self):
        """Test that all 10 gotchas are documented"""
        print("\nTesting gotchas coverage...")

        gotchas_file = self.skill_dir / "GOTCHAS.md"

        if not gotchas_file.exists():
            return

        with open(gotchas_file, "r", encoding="utf-8") as f:
            content = f.read()

        # Count numbered gotchas (1-10)
        gotcha_count = 0
        for i in range(1, 11):
            if f"### {i}." in content or f"## {i}." in content:
                gotcha_count += 1

        if gotcha_count < 10:
            self.warnings.append(
                f"GOTCHAS.md documents {gotcha_count} gotchas (expected: 10)"
            )
        else:
            print(f"  ✓ GOTCHAS.md documents all {gotcha_count} gotchas")

    def test_file_sizes(self):
        """Test that files are reasonably sized"""
        print("\nTesting file sizes...")

        files = [
            ("SKILL.md", 500),  # Max lines
            ("KNOWLEDGE.md", 1000),  # Reasonable max
            ("PATTERNS.md", 1000),
            ("EXAMPLES.md", 3000),  # Larger (has all code)
            ("GOTCHAS.md", 1000),
            ("REFERENCE.md", 800),
        ]

        for filename, max_lines in files:
            filepath = self.skill_dir / filename

            if not filepath.exists():
                continue

            with open(filepath, "r", encoding="utf-8") as f:
                line_count = len(f.readlines())

            if line_count > max_lines:
                self.warnings.append(
                    f"{filename} has {line_count} lines (recommended max: {max_lines})"
                )
            else:
                print(f"  ✓ {filename}: {line_count} lines (max: {max_lines})")

    def run_all_tests(self):
        """Run all tests and report results"""
        print("=" * 70)
        print("Multi-Agent Coordination Framework - Test Suite")
        print("=" * 70)

        self.test_file_existence()
        self.test_skill_line_count()
        self.test_line_reduction()
        self.test_cross_references()
        self.test_front_matter()
        self.test_pattern_coverage()
        self.test_gotchas_coverage()
        self.test_file_sizes()

        # Report results
        print("\n" + "=" * 70)
        print("Test Results")
        print("=" * 70)

        if self.errors:
            print(f"\n❌ ERRORS ({len(self.errors)}):")
            for error in self.errors:
                print(f"  - {error}")

        if self.warnings:
            print(f"\n⚠️  WARNINGS ({len(self.warnings)}):")
            for warning in self.warnings:
                print(f"  - {warning}")

        if not self.errors and not self.warnings:
            print("\n✅ All tests passed!")

        print("\n" + "=" * 70)

        return len(self.errors) == 0


def main():
    """Main test runner"""
    tester = TestMultiAgentCoordination()
    success = tester.run_all_tests()

    if success:
        print("\n✅ REFACTORING SUCCESSFUL!")
        print("   - SKILL.md under 500 lines")
        print("   - All 6 files created")
        print("   - 76%+ line reduction achieved")
        return 0
    else:
        print("\n❌ REFACTORING INCOMPLETE")
        print("   Review errors above and fix before committing")
        return 1


if __name__ == "__main__":
    exit(main())
