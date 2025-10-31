#!/usr/bin/env python3
"""
validate_report.py - Validate evaluation and reporting framework structure and content
"""

import os
import re
import sys
from pathlib import Path
from typing import List, Dict, Tuple

class ReportValidator:
    """Validates report structure, cross-references, and line counts"""

    def __init__(self, skill_dir: str):
        self.skill_dir = Path(skill_dir)
        self.errors = []
        self.warnings = []
        self.info = []

    def validate_all(self) -> bool:
        """Run all validations"""
        print("=" * 60)
        print("EVALUATION-REPORTING-FRAMEWORK VALIDATOR")
        print("=" * 60)

        # Check file existence
        self._validate_files_exist()

        # Check line counts
        self._validate_line_counts()

        # Check cross-references
        self._validate_cross_references()

        # Check headers and structure
        self._validate_structure()

        # Check for common issues
        self._validate_content()

        # Print results
        return self._print_results()

    def _validate_files_exist(self):
        """Validate all required files exist"""
        required_files = [
            'SKILL.md',
            'KNOWLEDGE.md',
            'GOTCHAS.md',
            'PATTERNS.md',
            'EXAMPLES.md',
            'REFERENCE.md'
        ]

        print("\n[1] Checking file existence...")
        for filename in required_files:
            filepath = self.skill_dir / filename
            if filepath.exists():
                self.info.append(f"[OK] {filename} exists")
            else:
                self.errors.append(f"Missing required file: {filename}")

    def _validate_line_counts(self):
        """Validate line counts"""
        print("[2] Checking line counts...")

        # SKILL.md must be < 500 lines
        skill_file = self.skill_dir / 'SKILL.md'
        if skill_file.exists():
            lines = self._count_lines(skill_file)
            self.info.append(f"[OK] SKILL.md: {lines} lines")

            if lines > 500:
                self.errors.append(f"SKILL.md exceeds 500 line limit: {lines} lines")
            elif lines > 400:
                self.warnings.append(f"SKILL.md approaches 500 limit: {lines} lines")
            else:
                self.info.append(f"[OK] SKILL.md well under limit ({lines}/500)")

        # Check other files are > 100 lines (should have TOC)
        other_files = ['KNOWLEDGE.md', 'GOTCHAS.md', 'PATTERNS.md', 'EXAMPLES.md', 'REFERENCE.md']
        for filename in other_files:
            filepath = self.skill_dir / filename
            if filepath.exists():
                lines = self._count_lines(filepath)
                self.info.append(f"[OK] {filename}: {lines} lines")

                if lines < 100:
                    self.warnings.append(f"{filename} is very short ({lines} lines)")

        # Total validation
        total_lines = sum(self._count_lines(self.skill_dir / f)
                         for f in ['SKILL.md', 'KNOWLEDGE.md', 'GOTCHAS.md',
                                   'PATTERNS.md', 'EXAMPLES.md', 'REFERENCE.md']
                         if (self.skill_dir / f).exists())
        self.info.append(f"[OK] Total framework: {total_lines} lines (6 files)")

    def _validate_cross_references(self):
        """Validate cross-references between files"""
        print("[3] Checking cross-references...")

        # Read all files
        files_content = {}
        for filename in ['SKILL.md', 'KNOWLEDGE.md', 'GOTCHAS.md', 'PATTERNS.md', 'EXAMPLES.md', 'REFERENCE.md']:
            filepath = self.skill_dir / filename
            if filepath.exists():
                with open(filepath, 'r', encoding='utf-8') as f:
                    files_content[filename] = f.read()

        # Check SKILL.md references other files
        skill_refs = self._extract_references(files_content.get('SKILL.md', ''))

        for ref in skill_refs:
            if ref not in files_content:
                self.errors.append(f"SKILL.md references missing file: {ref}")
            else:
                self.info.append(f"[OK] SKILL.md references {ref}")

        # Check for broken anchor references
        for filename, content in files_content.items():
            # Find references like `/FILENAME.md`
            references = re.findall(r'/([A-Z_\-]+\.md)', content)
            for ref_file in references:
                if not (self.skill_dir / ref_file).exists():
                    self.warnings.append(f"{filename} references non-existent: {ref_file}")

    def _validate_structure(self):
        """Validate document structure"""
        print("[4] Checking document structure...")

        files_to_check = ['KNOWLEDGE.md', 'GOTCHAS.md', 'PATTERNS.md', 'EXAMPLES.md', 'REFERENCE.md']

        for filename in files_to_check:
            filepath = self.skill_dir / filename
            if filepath.exists():
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()

                # Check for Table of Contents
                if '## Table of Contents' in content or '# Table of Contents' in content:
                    self.info.append(f"[OK] {filename} has Table of Contents")
                else:
                    self.warnings.append(f"{filename} missing Table of Contents (recommended for files > 100 lines)")

                # Check for proper heading structure
                headers = re.findall(r'^#{1,6} ', content, re.MULTILINE)
                if headers:
                    self.info.append(f"[OK] {filename} has {len(headers)} headers")

    def _validate_content(self):
        """Validate content quality"""
        print("[5] Checking content quality...")

        skill_file = self.skill_dir / 'SKILL.md'
        if skill_file.exists():
            with open(skill_file, 'r', encoding='utf-8') as f:
                content = f.read()

            # Check for key sections
            required_sections = [
                '## Purpose',
                '## When to Use This Skill',
                '## Quick Start',
                '## Best Practices',
                '## Related Skills'
            ]

            for section in required_sections:
                if section in content:
                    self.info.append(f"[OK] SKILL.md contains {section}")
                else:
                    self.warnings.append(f"SKILL.md missing section: {section}")

    def _extract_references(self, content: str) -> List[str]:
        """Extract file references from content"""
        # Look for patterns like `/FILENAME.md` or `See: /FILENAME.md`
        matches = re.findall(r'/([A-Z_]+\.md)', content)
        return list(set(matches))

    def _count_lines(self, filepath: Path) -> int:
        """Count lines in a file"""
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                return len(f.readlines())
        except Exception as e:
            self.errors.append(f"Error reading {filepath.name}: {e}")
            return 0

    def _print_results(self) -> bool:
        """Print validation results"""
        print("\n" + "=" * 60)
        print("VALIDATION RESULTS")
        print("=" * 60)

        print(f"\n[OK] INFO ({len(self.info)})")
        for msg in self.info[:10]:  # Show first 10
            print(f"  {msg}")
        if len(self.info) > 10:
            print(f"  ... and {len(self.info) - 10} more")

        if self.warnings:
            print(f"\n[WARN] WARNINGS ({len(self.warnings)})")
            for msg in self.warnings:
                print(f"  {msg}")

        if self.errors:
            print(f"\n[FAIL] ERRORS ({len(self.errors)})")
            for msg in self.errors:
                print(f"  {msg}")

        print("\n" + "=" * 60)
        if self.errors:
            print("RESULT: FAILED (errors found)")
            return False
        elif self.warnings:
            print("RESULT: PASSED (with warnings)")
            return True
        else:
            print("RESULT: PASSED")
            return True

def main():
    """Main entry point"""
    # Get skill directory
    script_dir = Path(__file__).parent.parent

    validator = ReportValidator(script_dir)
    success = validator.validate_all()

    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()
