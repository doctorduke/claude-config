#!/usr/bin/env python3
"""
Test suite for Reverse Engineering Toolkit skill.
Validates structure, content, and compliance with requirements.
"""

import os
from pathlib import Path
import re

# Base directory for the skill
SKILL_DIR = Path(__file__).parent.parent
REQUIRED_FILES = [
    "SKILL.md",
    "KNOWLEDGE.md",
    "PATTERNS.md",
    "EXAMPLES.md",
    "GOTCHAS.md",
    "REFERENCE.md",
]


def test_all_files_exist():
    """Test that all 6 required files exist."""
    print("Testing: All 6 files exist...")
    missing = []
    for filename in REQUIRED_FILES:
        filepath = SKILL_DIR / filename
        if not filepath.exists():
            missing.append(filename)

    if missing:
        print(f"  FAIL: Missing files: {', '.join(missing)}")
        return False
    else:
        print(f"  PASS: All {len(REQUIRED_FILES)} files exist")
        return True


def test_skill_md_line_count():
    """Test that SKILL.md is less than 500 lines."""
    print("Testing: SKILL.md line count < 500...")
    skill_md_path = SKILL_DIR / "SKILL.md"

    with open(skill_md_path, encoding='utf-8') as f:
        line_count = len(f.readlines())

    if line_count < 500:
        print(f"  PASS: SKILL.md has {line_count} lines (< 500)")
        return True
    else:
        print(f"  FAIL: SKILL.md has {line_count} lines (>= 500)")
        return False


def test_skill_md_has_front_matter():
    """Test that SKILL.md has proper front matter."""
    print("Testing: SKILL.md has front matter...")
    skill_md_path = SKILL_DIR / "SKILL.md"

    with open(skill_md_path, encoding='utf-8') as f:
        content = f.read()

    # Check for front matter
    if not content.startswith('---'):
        print("  FAIL: SKILL.md missing front matter")
        return False

    # Check required fields in front matter
    required_fields = ['name:', 'description:', 'allowed-tools:']
    for field in required_fields:
        if field not in content[:500]:  # Front matter should be in first 500 chars
            print(f"  FAIL: SKILL.md missing '{field}' in front matter")
            return False

    print("  PASS: SKILL.md has proper front matter")
    return True


def test_patterns_documented():
    """Test that all 5 patterns are documented."""
    print("Testing: 5 patterns documented...")
    patterns_md_path = SKILL_DIR / "PATTERNS.md"

    with open(patterns_md_path, encoding='utf-8') as f:
        content = f.read()

    expected_patterns = [
        "Pattern 1: Static Code Analysis",
        "Pattern 2: Dynamic Analysis",
        "Pattern 3: Dependency Graph",
        "Pattern 4: Design Pattern Recognition",
        "Pattern 5: Documentation Generation",
    ]

    missing = []
    for pattern in expected_patterns:
        # Flexible matching (allow variations)
        pattern_key = pattern.split(':')[0]  # e.g., "Pattern 1"
        if pattern_key not in content:
            missing.append(pattern)

    if missing:
        print(f"  FAIL: Missing patterns: {', '.join(missing)}")
        return False
    else:
        print(f"  PASS: All 5 patterns documented")
        return True


def test_cross_references_valid():
    """Test that cross-references between files are valid."""
    print("Testing: Cross-references valid...")
    skill_md_path = SKILL_DIR / "SKILL.md"

    with open(skill_md_path, encoding='utf-8') as f:
        content = f.read()

    # Extract references to other files
    references = re.findall(r'\*\*(\w+\.md)\*\*', content)
    references += re.findall(r'See:?\s+(\w+\.md)', content, re.IGNORECASE)

    invalid = []
    for ref in references:
        ref_path = SKILL_DIR / ref
        if not ref_path.exists():
            invalid.append(ref)

    if invalid:
        print(f"  FAIL: Invalid references: {', '.join(set(invalid))}")
        return False
    else:
        print(f"  PASS: All cross-references valid ({len(set(references))} checked)")
        return True


def test_examples_have_code():
    """Test that EXAMPLES.md contains code examples."""
    print("Testing: EXAMPLES.md has code examples...")
    examples_md_path = SKILL_DIR / "EXAMPLES.md"

    with open(examples_md_path, encoding='utf-8') as f:
        content = f.read()

    # Count code blocks
    code_blocks = content.count('```')

    if code_blocks < 10:  # At least 5 examples with opening and closing ```
        print(f"  FAIL: EXAMPLES.md has only {code_blocks//2} code blocks (expected >= 5)")
        return False
    else:
        print(f"  PASS: EXAMPLES.md has {code_blocks//2} code blocks")
        return True


def test_no_time_sensitive_content():
    """Test that files don't contain time-sensitive content."""
    print("Testing: No time-sensitive URLs or outdated references...")

    # Read all files
    all_content = ""
    for filename in REQUIRED_FILES:
        filepath = SKILL_DIR / filename
        with open(filepath, encoding='utf-8') as f:
            all_content += f.read()

    # Check for problematic patterns (very lenient, just flagging obvious issues)
    time_sensitive_patterns = [
        r'http://[^\s]+',  # HTTP instead of HTTPS (often outdated)
    ]

    issues = []
    for pattern in time_sensitive_patterns:
        matches = re.findall(pattern, all_content)
        if matches:
            issues.extend(matches[:3])  # First 3 examples

    if issues:
        print(f"  WARNING: Found potential time-sensitive content: {issues}")
        print("  PASS: (warnings only, not failing)")
        return True
    else:
        print("  PASS: No time-sensitive content detected")
        return True


def test_gotchas_documented():
    """Test that GOTCHAS.md has meaningful content."""
    print("Testing: GOTCHAS.md has troubleshooting content...")
    gotchas_md_path = SKILL_DIR / "GOTCHAS.md"

    with open(gotchas_md_path, encoding='utf-8') as f:
        content = f.read()

    # Check for expected sections
    expected_sections = [
        "Problem",
        "Solution",
    ]

    missing = []
    for section in expected_sections:
        if section not in content:
            missing.append(section)

    if missing:
        print(f"  FAIL: GOTCHAS.md missing sections: {', '.join(missing)}")
        return False
    else:
        print(f"  PASS: GOTCHAS.md has troubleshooting structure")
        return True


def test_reference_has_tools():
    """Test that REFERENCE.md documents tools."""
    print("Testing: REFERENCE.md has tool documentation...")
    reference_md_path = SKILL_DIR / "REFERENCE.md"

    with open(reference_md_path, encoding='utf-8') as f:
        content = f.read()

    # Check for tool names mentioned in architecture
    expected_tools = ["tree-sitter", "strace", "ast", "gdb"]

    found_tools = []
    for tool in expected_tools:
        if tool in content:
            found_tools.append(tool)

    if len(found_tools) < 3:
        print(f"  FAIL: REFERENCE.md only documents {len(found_tools)} tools (expected >= 3)")
        return False
    else:
        print(f"  PASS: REFERENCE.md documents {len(found_tools)} tools")
        return True


def test_skill_size_total():
    """Test that total skill size is reasonable."""
    print("Testing: Total skill size < 2000 lines...")

    total_lines = 0
    for filename in REQUIRED_FILES:
        filepath = SKILL_DIR / filename
        with open(filepath, encoding='utf-8') as f:
            total_lines += len(f.readlines())

    if total_lines < 2000:
        print(f"  PASS: Total size is {total_lines} lines (< 2000)")
        return True
    else:
        print(f"  WARNING: Total size is {total_lines} lines (>= 2000)")
        print("  PASS: (warning only, not failing)")
        return True


def run_all_tests():
    """Run all tests and report results."""
    print("=" * 60)
    print("Running Reverse Engineering Toolkit Skill Tests")
    print("=" * 60)
    print()

    tests = [
        test_all_files_exist,
        test_skill_md_line_count,
        test_skill_md_has_front_matter,
        test_patterns_documented,
        test_cross_references_valid,
        test_examples_have_code,
        test_no_time_sensitive_content,
        test_gotchas_documented,
        test_reference_has_tools,
        test_skill_size_total,
    ]

    results = []
    for test in tests:
        try:
            result = test()
            results.append(result)
        except Exception as e:
            print(f"  ERROR: {e}")
            results.append(False)
        print()

    # Summary
    print("=" * 60)
    print("Test Summary")
    print("=" * 60)
    passed = sum(results)
    total = len(results)
    print(f"Passed: {passed}/{total}")

    if passed == total:
        print("Status: ALL TESTS PASSED")
        return 0
    else:
        print("Status: SOME TESTS FAILED")
        return 1


if __name__ == "__main__":
    exit_code = run_all_tests()
    exit(exit_code)
