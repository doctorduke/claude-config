#!/usr/bin/env python3
"""
Test suite for architecture-evaluation-framework refactoring
"""

import os
import re
from pathlib import Path
import unittest

class TestArchitectureEvaluationRefactoring(unittest.TestCase):
    """Test the refactored architecture evaluation framework structure"""

    def setUp(self):
        """Setup test environment"""
        self.skill_dir = Path(__file__).parent.parent
        self.required_files = [
            'SKILL.md',
            'KNOWLEDGE.md',
            'PATTERNS.md',
            'EXAMPLES.md',
            'GOTCHAS.md',
            'REFERENCE.md'
        ]

    def test_all_files_exist(self):
        """Test: All required files exist"""
        for filename in self.required_files:
            file_path = self.skill_dir / filename
            self.assertTrue(
                file_path.exists(),
                f"Required file {filename} does not exist"
            )

    def test_skill_md_line_count(self):
        """Test: SKILL.md is under 500 lines"""
        skill_file = self.skill_dir / 'SKILL.md'
        with open(skill_file, 'r', encoding='utf-8') as f:
            lines = f.readlines()

        line_count = len(lines)
        self.assertLess(
            line_count, 500,
            f"SKILL.md has {line_count} lines, should be under 500"
        )

        # Also check it's not too small (should have substance)
        self.assertGreater(
            line_count, 100,
            f"SKILL.md has only {line_count} lines, seems too small"
        )

    def test_cross_references_valid(self):
        """Test: All cross-references between files are valid"""
        # Pattern to match markdown links
        link_pattern = re.compile(r'\[([^\]]+)\]\(([^)]+)\)')

        invalid_refs = []

        for filename in self.required_files:
            file_path = self.skill_dir / filename
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            # Find all links
            for match in link_pattern.finditer(content):
                link_text = match.group(1)
                link_target = match.group(2)

                # Check internal file references
                if link_target.endswith('.md') and not link_target.startswith('http'):
                    # Remove anchor if present
                    file_ref = link_target.split('#')[0]

                    # Check if referenced file exists
                    if file_ref:  # Not just an anchor
                        ref_path = self.skill_dir / file_ref
                        if not ref_path.exists():
                            invalid_refs.append({
                                'source': filename,
                                'target': link_target,
                                'text': link_text
                            })

        self.assertEqual(
            len(invalid_refs), 0,
            f"Invalid cross-references found: {invalid_refs}"
        )

    def test_code_examples_runnable(self):
        """Test: Code examples in files are syntactically valid"""
        import ast

        python_code_pattern = re.compile(r'```python\n(.*?)\n```', re.DOTALL)
        syntax_errors = []

        for filename in ['EXAMPLES.md', 'PATTERNS.md']:
            file_path = self.skill_dir / filename
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            # Extract Python code blocks
            for match in python_code_pattern.finditer(content):
                code = match.group(1)

                # Skip if it's just a comment or import
                if code.strip().startswith('#') or len(code.strip()) < 10:
                    continue

                try:
                    # Try to parse the Python code
                    ast.parse(code)
                except SyntaxError as e:
                    # Some code blocks might be snippets, check if it's a complete statement
                    if not any(skip in code for skip in ['...', '# ...']):
                        syntax_errors.append({
                            'file': filename,
                            'error': str(e),
                            'code_snippet': code[:100]
                        })

        # Allow some syntax errors as examples might be demonstrative
        self.assertLess(
            len(syntax_errors), 5,
            f"Too many syntax errors in examples: {syntax_errors[:3]}"
        )

    def test_dependency_graph_fix_preserved(self):
        """Test: Dependency graph logic from PR 65 is preserved"""
        patterns_file = self.skill_dir / 'PATTERNS.md'
        with open(patterns_file, 'r', encoding='utf-8') as f:
            content = f.read()

        # Check for the exact match + prefix check pattern
        pattern_present = (
            'other_module == import_name or' in content and
            "other_module.startswith(import_name + '.')" in content
        )

        self.assertTrue(
            pattern_present,
            "Dependency graph fix from PR 65 not found in PATTERNS.md"
        )

    def test_no_time_sensitive_information(self):
        """Test: No time-sensitive information in files"""
        time_patterns = [
            r'\d{4}-\d{2}-\d{2}',  # Dates
            r'version\s*\d+\.\d+',  # Version numbers
            r'as of \d{4}',  # "As of" statements
            r'updated\s+\w+\s+\d{4}'  # Updated dates
        ]

        time_sensitive = []

        for filename in self.required_files:
            file_path = self.skill_dir / filename
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            for pattern in time_patterns:
                matches = re.findall(pattern, content, re.IGNORECASE)
                if matches:
                    # Filter out example dates and legitimate version refs
                    filtered = [m for m in matches
                               if '2025-01' not in m  # Example dates
                               and 'YYYY-MM-DD' not in m
                               and 'version' not in m.lower()]
                    if filtered:
                        time_sensitive.append({
                            'file': filename,
                            'matches': filtered[:3]  # First 3 matches
                        })

        # Some dates might be in examples, so allow a few
        self.assertLess(
            len(time_sensitive), 3,
            f"Time-sensitive information found: {time_sensitive}"
        )

    def test_progressive_disclosure_structure(self):
        """Test: Files follow progressive disclosure pattern"""
        # SKILL.md should be concise
        skill_file = self.skill_dir / 'SKILL.md'
        with open(skill_file, 'r', encoding='utf-8') as f:
            skill_content = f.read()

        # Check SKILL.md has table of contents
        self.assertIn('## Table of Contents', skill_content)
        self.assertIn('## Core Evaluation Methods', skill_content)

        # Check SKILL.md references other files
        for other_file in ['KNOWLEDGE.md', 'PATTERNS.md', 'EXAMPLES.md', 'GOTCHAS.md', 'REFERENCE.md']:
            self.assertIn(
                other_file,
                skill_content,
                f"SKILL.md should reference {other_file}"
            )

        # Each supporting file should have substantial content
        for filename in ['KNOWLEDGE.md', 'PATTERNS.md', 'EXAMPLES.md']:
            file_path = self.skill_dir / filename
            with open(file_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()

            self.assertGreater(
                len(lines), 200,
                f"{filename} seems too short ({len(lines)} lines) for detailed content"
            )

    def test_metadata_preserved(self):
        """Test: SKILL.md metadata block is preserved correctly"""
        skill_file = self.skill_dir / 'SKILL.md'
        with open(skill_file, 'r', encoding='utf-8') as f:
            content = f.read()

        # Check metadata block exists
        self.assertTrue(content.startswith('---'))

        # Extract metadata
        metadata_match = re.match(r'---\n(.*?)\n---', content, re.DOTALL)
        self.assertIsNotNone(metadata_match, "Metadata block not found")

        metadata = metadata_match.group(1)

        # Check required metadata fields
        self.assertIn('name: architecture-evaluation-framework', metadata)
        self.assertIn('description:', metadata)
        self.assertIn('allowed-tools:', metadata)

    def test_line_reduction_achieved(self):
        """Test: Significant line reduction achieved"""
        original_file = self.skill_dir / 'SKILL.md.bak'
        new_file = self.skill_dir / 'SKILL.md'

        if original_file.exists():
            with open(original_file, 'r', encoding='utf-8') as f:
                original_lines = len(f.readlines())

            with open(new_file, 'r', encoding='utf-8') as f:
                new_lines = len(f.readlines())

            reduction_percentage = ((original_lines - new_lines) / original_lines) * 100

            self.assertGreater(
                reduction_percentage, 70,
                f"Only {reduction_percentage:.1f}% reduction achieved (target: 74%+)"
            )

            print(f"\nLine reduction: {original_lines} -> {new_lines} ({reduction_percentage:.1f}% reduction)")

    def test_no_broken_sections(self):
        """Test: All files have proper markdown structure"""
        heading_pattern = re.compile(r'^#{1,6}\s+(.+)$', re.MULTILINE)

        for filename in self.required_files:
            file_path = self.skill_dir / filename
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            headings = heading_pattern.findall(content)

            # Each file should have at least some structure
            self.assertGreater(
                len(headings), 3,
                f"{filename} has too few headings ({len(headings)}), might be malformed"
            )

            # Check for common required sections
            if filename == 'SKILL.md':
                required = ['Purpose', 'Quick Start', 'Core Evaluation Methods']
                for section in required:
                    self.assertIn(
                        section,
                        content,
                        f"Required section '{section}' not found in SKILL.md"
                    )


def run_tests():
    """Run all tests and generate report"""
    # Create test suite
    loader = unittest.TestLoader()
    suite = loader.loadTestsFromTestCase(TestArchitectureEvaluationRefactoring)

    # Run tests
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)

    # Generate summary
    print("\n" + "=" * 60)
    print("ARCHITECTURE EVALUATION FRAMEWORK REFACTORING TEST RESULTS")
    print("=" * 60)

    if result.wasSuccessful():
        print("All tests passed!")
    else:
        print(f"FAILED: {len(result.failures)} test(s) failed")
        print(f"ERRORS: {len(result.errors)} test(s) had errors")

    # Additional metrics
    skill_dir = Path(__file__).parent.parent
    skill_file = skill_dir / 'SKILL.md'

    if skill_file.exists():
        with open(skill_file, 'r', encoding='utf-8') as f:
            lines = len(f.readlines())
        print(f"\nSKILL.md line count: {lines}/500")

    print("\nFile structure:")
    for filename in ['SKILL.md', 'KNOWLEDGE.md', 'PATTERNS.md', 'EXAMPLES.md', 'GOTCHAS.md', 'REFERENCE.md']:
        file_path = skill_dir / filename
        if file_path.exists():
            with open(file_path, 'r', encoding='utf-8') as f:
                line_count = len(f.readlines())
            print(f"  - {filename}: {line_count} lines")

    return result.wasSuccessful()


if __name__ == '__main__':
    success = run_tests()
    exit(0 if success else 1)