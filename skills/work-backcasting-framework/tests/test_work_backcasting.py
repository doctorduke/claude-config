#!/usr/bin/env python3
"""
Comprehensive tests for Work Backcasting Framework skill.

Tests:
1. SKILL.md line count < 500
2. All 6 required files exist
3. Cross-references are valid
4. 5 patterns documented
5. Code examples are runnable
6. Detects infeasible plans
7. Identifies all prerequisites
"""

import os
import re
import sys
from pathlib import Path


class Colors:
    """ANSI color codes for output"""
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    RESET = '\033[0m'


def print_test(name, passed, message=""):
    """Print test result with color coding"""
    status = f"{Colors.GREEN}[PASS]{Colors.RESET}" if passed else f"{Colors.RED}[FAIL]{Colors.RESET}"
    print(f"{status} - {name}")
    if message:
        print(f"       {message}")


def test_skill_line_count(skill_dir):
    """Test 1: SKILL.md must be < 500 lines"""
    skill_file = skill_dir / "SKILL.md"

    if not skill_file.exists():
        print_test("SKILL.md line count", False, "SKILL.md not found")
        return False

    with open(skill_file, encoding='utf-8') as f:
        lines = f.readlines()

    line_count = len(lines)
    passed = line_count < 500

    message = f"{line_count} lines (limit: 500)"
    print_test("SKILL.md line count", passed, message)

    return passed


def test_all_files_exist(skill_dir):
    """Test 2: All 6 required files must exist"""
    required_files = [
        "SKILL.md",
        "KNOWLEDGE.md",
        "PATTERNS.md",
        "EXAMPLES.md",
        "GOTCHAS.md",
        "REFERENCE.md"
    ]

    missing = []
    for filename in required_files:
        filepath = skill_dir / filename
        if not filepath.exists():
            missing.append(filename)

    passed = len(missing) == 0
    message = f"All 6 files present" if passed else f"Missing: {', '.join(missing)}"
    print_test("All required files exist", passed, message)

    return passed


def test_cross_references_valid(skill_dir):
    """Test 3: Cross-references between files must be valid"""
    files_to_check = [
        "SKILL.md",
        "PATTERNS.md",
        "EXAMPLES.md",
        "GOTCHAS.md"
    ]

    # Pattern for markdown links: [text](filename.md) or [text](filename.md#anchor)
    link_pattern = re.compile(r'\[([^\]]+)\]\(([^\)]+\.md[^\)]*)\)')

    invalid_refs = []

    for filename in files_to_check:
        filepath = skill_dir / filename
        if not filepath.exists():
            continue

        with open(filepath, encoding='utf-8') as f:
            content = f.read()

        for match in link_pattern.finditer(content):
            link_text = match.group(1)
            link_target = match.group(2)

            # Extract just the filename (before any #anchor)
            target_file = link_target.split('#')[0]

            # Check if target file exists
            target_path = skill_dir / target_file
            if not target_path.exists():
                invalid_refs.append(f"{filename} -> {target_file}")

    passed = len(invalid_refs) == 0
    message = "All cross-references valid" if passed else f"Invalid: {', '.join(invalid_refs[:3])}"
    print_test("Cross-references valid", passed, message)

    return passed


def test_five_patterns_documented(skill_dir):
    """Test 4: PATTERNS.md must document 5 patterns"""
    patterns_file = skill_dir / "PATTERNS.md"

    if not patterns_file.exists():
        print_test("5 patterns documented", False, "PATTERNS.md not found")
        return False

    with open(patterns_file, encoding='utf-8') as f:
        content = f.read()

    # Look for pattern headers (e.g., "## Pattern 1:", "## Pattern 2:", etc.)
    pattern_headers = re.findall(r'^##\s+Pattern\s+\d+:', content, re.MULTILINE)

    pattern_count = len(pattern_headers)
    passed = pattern_count >= 5

    message = f"Found {pattern_count} patterns (expected: 5)"
    print_test("5 patterns documented", passed, message)

    return passed


def test_code_examples_runnable(skill_dir):
    """Test 5: Code examples should be syntactically valid Python"""
    examples_file = skill_dir / "EXAMPLES.md"

    if not examples_file.exists():
        print_test("Code examples runnable", False, "EXAMPLES.md not found")
        return False

    with open(examples_file, encoding='utf-8') as f:
        content = f.read()

    # Extract Python code blocks
    code_blocks = re.findall(r'```python\n(.*?)```', content, re.DOTALL)

    if not code_blocks:
        print_test("Code examples runnable", False, "No Python code blocks found")
        return False

    errors = []
    for i, code in enumerate(code_blocks, 1):
        try:
            # Try to compile the code (doesn't execute, just checks syntax)
            compile(code, f'<example_{i}>', 'exec')
        except SyntaxError as e:
            errors.append(f"Example {i}: {str(e)}")

    passed = len(errors) == 0
    message = f"{len(code_blocks)} examples, all valid" if passed else f"Errors in {len(errors)} examples"
    print_test("Code examples runnable", passed, message)

    return passed


def test_detects_infeasible_plans(skill_dir):
    """Test 6: Examples should show detection of infeasible plans"""
    examples_file = skill_dir / "EXAMPLES.md"

    if not examples_file.exists():
        print_test("Detects infeasible plans", False, "EXAMPLES.md not found")
        return False

    with open(examples_file, encoding='utf-8') as f:
        content = f.read()

    # Look for feasibility-related content
    feasibility_keywords = [
        'feasibility',
        'infeasible',
        'impossible',
        'contradiction',
        'not feasible',
        'FeasibilityChecker'
    ]

    keyword_found = any(keyword.lower() in content.lower() for keyword in feasibility_keywords)

    # Also check GOTCHAS.md
    gotchas_file = skill_dir / "GOTCHAS.md"
    if gotchas_file.exists():
        with open(gotchas_file, encoding='utf-8') as f:
            gotchas_content = f.read()
        keyword_found = keyword_found or any(
            keyword.lower() in gotchas_content.lower()
            for keyword in feasibility_keywords
        )

    passed = keyword_found
    message = "Feasibility validation documented" if passed else "No feasibility validation found"
    print_test("Detects infeasible plans", passed, message)

    return passed


def test_identifies_prerequisites(skill_dir):
    """Test 7: Examples should show prerequisite identification"""
    examples_file = skill_dir / "EXAMPLES.md"

    if not examples_file.exists():
        print_test("Identifies prerequisites", False, "EXAMPLES.md not found")
        return False

    with open(examples_file, encoding='utf-8') as f:
        content = f.read()

    # Look for prerequisite-related content
    prerequisite_indicators = [
        'prerequisite',
        'PrerequisiteDetector',
        'PrerequisiteIdentifier',
        'blocking',
        'dependency',
        'requirement'
    ]

    matches = sum(1 for keyword in prerequisite_indicators if keyword in content)

    passed = matches >= 3  # Should mention prerequisites multiple times
    message = f"Found {matches} prerequisite references" if passed else "Insufficient prerequisite coverage"
    print_test("Identifies prerequisites", passed, message)

    return passed


def test_pattern_completeness(skill_dir):
    """Bonus Test: Each pattern should have structure, when-to-use, and example"""
    patterns_file = skill_dir / "PATTERNS.md"

    if not patterns_file.exists():
        print_test("Pattern completeness", False, "PATTERNS.md not found")
        return False

    with open(patterns_file, encoding='utf-8') as f:
        content = f.read()

    # Check that each pattern section has key components
    required_sections = [
        'Purpose',
        'When to Use',
        'Algorithm',
        'Example',
        'Solution'
    ]

    section_counts = {section: content.count(f"### {section}") for section in required_sections}

    # Should have at least 3 of these sections appearing multiple times (once per pattern)
    well_documented_sections = sum(1 for count in section_counts.values() if count >= 3)

    passed = well_documented_sections >= 3
    message = f"{well_documented_sections}/5 section types well documented"
    print_test("Pattern completeness", passed, message)

    return passed


def test_integration_documented(skill_dir):
    """Bonus Test: Integration with other skills/agents should be documented"""
    skill_file = skill_dir / "SKILL.md"

    if not skill_file.exists():
        print_test("Integration documented", False, "SKILL.md not found")
        return False

    with open(skill_file, encoding='utf-8') as f:
        content = f.read()

    integration_keywords = [
        'integration',
        'refactoring-lead',
        'project-planner',
        'work forecasting',
        'context engineering'
    ]

    matches = sum(1 for keyword in integration_keywords if keyword.lower() in content.lower())

    passed = matches >= 2
    message = f"Integration points documented ({matches} references)"
    print_test("Integration documented", passed, message)

    return passed


def run_all_tests(skill_dir):
    """Run all tests and return summary"""
    print(f"\n{Colors.BLUE}{'=' * 70}{Colors.RESET}")
    print(f"{Colors.BLUE}Work Backcasting Framework - Test Suite{Colors.RESET}")
    print(f"{Colors.BLUE}{'=' * 70}{Colors.RESET}\n")

    tests = [
        ("Line Count", test_skill_line_count),
        ("File Existence", test_all_files_exist),
        ("Cross-References", test_cross_references_valid),
        ("Pattern Count", test_five_patterns_documented),
        ("Code Examples", test_code_examples_runnable),
        ("Feasibility Detection", test_detects_infeasible_plans),
        ("Prerequisite Identification", test_identifies_prerequisites),
        ("Pattern Completeness", test_pattern_completeness),
        ("Integration Documentation", test_integration_documented),
    ]

    results = []
    for test_name, test_func in tests:
        try:
            passed = test_func(skill_dir)
            results.append((test_name, passed))
        except Exception as e:
            print_test(test_name, False, f"Exception: {str(e)}")
            results.append((test_name, False))

    # Summary
    print(f"\n{Colors.BLUE}{'=' * 70}{Colors.RESET}")
    passed_count = sum(1 for _, passed in results if passed)
    total_count = len(results)

    if passed_count == total_count:
        print(f"{Colors.GREEN}ALL TESTS PASSED ({passed_count}/{total_count}){Colors.RESET}")
    else:
        print(f"{Colors.YELLOW}WARNING: {passed_count}/{total_count} tests passed{Colors.RESET}")
        failed = [name for name, passed in results if not passed]
        print(f"{Colors.RED}Failed tests: {', '.join(failed)}{Colors.RESET}")

    print(f"{Colors.BLUE}{'=' * 70}{Colors.RESET}\n")

    return passed_count == total_count


if __name__ == "__main__":
    # Determine skill directory
    if len(sys.argv) > 1:
        skill_dir = Path(sys.argv[1])
    else:
        # Assume we're in tests/ subdirectory
        skill_dir = Path(__file__).parent.parent

    if not skill_dir.exists():
        print(f"{Colors.RED}Error: Skill directory not found: {skill_dir}{Colors.RESET}")
        sys.exit(1)

    print(f"Testing skill at: {skill_dir.absolute()}\n")

    success = run_all_tests(skill_dir)
    sys.exit(0 if success else 1)
