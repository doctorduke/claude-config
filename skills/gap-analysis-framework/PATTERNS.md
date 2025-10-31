# Gap Analysis Patterns

Detailed implementation patterns for six core gap analysis use cases with complete code examples.

## Table of Contents
1. [Requirements vs Implementation Pattern](#pattern-1-requirements-vs-implementation)
2. [Test Coverage Gap Pattern](#pattern-2-test-coverage-gaps)
3. [Documentation Gap Pattern](#pattern-3-documentation-gaps)
4. [SWOT Analysis Pattern](#pattern-4-swot-analysis)
5. [Capability Maturity Model Pattern](#pattern-5-capability-maturity-model)
6. [Security Posture Pattern](#pattern-6-security-posture)

---

## Pattern 1: Requirements vs Implementation

Identify missing features and incomplete implementations.

### Python Implementation

```python
#!/usr/bin/env python3
"""requirements_gap_analysis.py - Compare requirements to implementation"""

from dataclasses import dataclass, field
from typing import List, Dict, Optional
from enum import Enum
import json
from pathlib import Path

class RequirementStatus(Enum):
    IMPLEMENTED = "implemented"
    PARTIAL = "partial"
    MISSING = "missing"
    DEPRECATED = "deprecated"

class RequirementPriority(Enum):
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"

@dataclass
class Requirement:
    id: str
    title: str
    description: str
    priority: RequirementPriority
    category: str
    acceptance_criteria: List[str]
    tags: List[str] = field(default_factory=list)

@dataclass
class Implementation:
    file_path: str
    function_name: str
    line_number: int
    requirement_ids: List[str]
    completeness: int  # 0-100%
    notes: str = ""

@dataclass
class Gap:
    requirement: Requirement
    status: RequirementStatus
    implementations: List[Implementation]
    missing_criteria: List[str]
    coverage_percent: int
    impact: str
    recommended_action: str

class RequirementGapAnalyzer:
    """Analyze gaps between requirements and implementation"""

    def __init__(self, requirements_file: str, source_dir: str):
        self.requirements_file = Path(requirements_file)
        self.source_dir = Path(source_dir)
        self.requirements: List[Requirement] = []
        self.implementations: List[Implementation] = []
        self.gaps: List[Gap] = []

    def load_requirements(self):
        """Load requirements from JSON/YAML file"""
        with open(self.requirements_file) as f:
            data = json.load(f)

        for req_data in data.get('requirements', []):
            self.requirements.append(Requirement(
                id=req_data['id'],
                title=req_data['title'],
                description=req_data['description'],
                priority=RequirementPriority(req_data['priority']),
                category=req_data.get('category', 'general'),
                acceptance_criteria=req_data.get('acceptance_criteria', []),
                tags=req_data.get('tags', [])
            ))

    def analyze_gaps(self) -> List[Gap]:
        """Identify gaps between requirements and implementations"""
        self.gaps = []

        # Build implementation index
        impl_by_req: Dict[str, List[Implementation]] = {}
        for impl in self.implementations:
            for req_id in impl.requirement_ids:
                if req_id not in impl_by_req:
                    impl_by_req[req_id] = []
                impl_by_req[req_id].append(impl)

        # Analyze each requirement
        for req in self.requirements:
            impls = impl_by_req.get(req.id, [])

            if not impls:
                status = RequirementStatus.MISSING
                coverage = 0
                missing_criteria = req.acceptance_criteria
                impact = f"CRITICAL - {req.title} not implemented"
                action = f"Implement {req.title} - Priority: {req.priority.value}"

            else:
                avg_completeness = sum(i.completeness for i in impls) / len(impls)

                if avg_completeness >= 90:
                    status = RequirementStatus.IMPLEMENTED
                    coverage = 100
                    missing_criteria = []
                    impact = "None"
                    action = "No action needed"
                else:
                    status = RequirementStatus.PARTIAL
                    coverage = int(avg_completeness)
                    missing_count = int(len(req.acceptance_criteria) * (1 - avg_completeness / 100))
                    missing_criteria = req.acceptance_criteria[:missing_count]
                    impact = f"HIGH - {req.title} {coverage}% complete"
                    action = f"Complete implementation of {req.title} (currently {coverage}%)"

            gap = Gap(
                requirement=req,
                status=status,
                implementations=impls,
                missing_criteria=missing_criteria,
                coverage_percent=coverage,
                impact=impact,
                recommended_action=action
            )
            self.gaps.append(gap)

        return self.gaps

    def generate_report(self, output_file: str = "requirements_gap_report.md"):
        """Generate gap analysis report"""
        total = len(self.requirements)
        implemented = sum(1 for g in self.gaps if g.status == RequirementStatus.IMPLEMENTED)
        partial = sum(1 for g in self.gaps if g.status == RequirementStatus.PARTIAL)
        missing = sum(1 for g in self.gaps if g.status == RequirementStatus.MISSING)

        overall_coverage = (implemented + partial * 0.5) / total * 100 if total > 0 else 0

        report = f"""# Requirements Gap Analysis Report

## Executive Summary

- **Total Requirements**: {total}
- **Implemented**: {implemented} ({implemented/total*100:.1f}%)
- **Partially Implemented**: {partial} ({partial/total*100:.1f}%)
- **Missing**: {missing} ({missing/total*100:.1f}%)
- **Overall Coverage**: {overall_coverage:.1f}%

## Status Distribution

```
Implemented:  {'█' * int(implemented/total*50) if total > 0 else ''}
Partial:      {'▓' * int(partial/total*50) if total > 0 else ''}
Missing:      {'░' * int(missing/total*50) if total > 0 else ''}
```

## Critical Gaps

| Requirement | Status | Coverage | Impact |
|-------------|--------|----------|--------|
"""
        critical_gaps = [g for g in self.gaps
                        if g.requirement.priority in [RequirementPriority.CRITICAL, RequirementPriority.HIGH]
                        and g.status != RequirementStatus.IMPLEMENTED]

        if critical_gaps:
            for gap in sorted(critical_gaps, key=lambda g: g.requirement.priority.value):
                report += f"| **{gap.requirement.id}**: {gap.requirement.title} | "
                report += f"{gap.status.value} | {gap.coverage_percent}% | {gap.impact} |\n"

        with open(output_file, 'w') as f:
            f.write(report)

        print(f"Report generated: {output_file}")
        return report

# Usage
if __name__ == "__main__":
    analyzer = RequirementGapAnalyzer("requirements.json", "src/")
    analyzer.load_requirements()
    gaps = analyzer.analyze_gaps()
    analyzer.generate_report()
```

### Example requirements.json

```json
{
  "requirements": [
    {
      "id": "REQ-001",
      "title": "User Authentication",
      "description": "Users must be able to log in with email/password",
      "priority": "critical",
      "category": "authentication",
      "acceptance_criteria": [
        "Login form with email and password",
        "Password validation (min 8 chars)",
        "Session management",
        "Logout functionality"
      ]
    },
    {
      "id": "REQ-002",
      "title": "Password Reset",
      "description": "Users can reset forgotten passwords",
      "priority": "high",
      "category": "authentication",
      "acceptance_criteria": [
        "Reset password link via email",
        "Token expiration (24 hours)",
        "Secure password reset form"
      ]
    }
  ]
}
```

---

## Pattern 2: Test Coverage Gaps

Identify untested code and scenarios.

### Bash Script

```bash
#!/bin/bash
# test_coverage_gap_analysis.sh

set -e

echo "=== Test Coverage Gap Analysis ==="

COVERAGE_THRESHOLD=80
MIN_BRANCH_COVERAGE=75
MIN_FUNCTION_COVERAGE=90

OUTPUT_DIR="coverage_reports"
mkdir -p "$OUTPUT_DIR"

# Python coverage
if [ -f "pytest.ini" ] || [ -f "setup.py" ]; then
    echo "Analyzing Python test coverage..."
    pytest --cov=. --cov-report=html --cov-report=json --cov-report=term-missing

    python3 << 'EOF'
import json
from pathlib import Path

with open('coverage.json') as f:
    coverage = json.load(f)

total_coverage = coverage['totals']['percent_covered']
print(f"\nOverall Coverage: {total_coverage:.1f}%")

print("\n## Low Coverage Files (<80%)")
print("| File | Coverage | Missing Lines |")
print("|------|----------|---------------|")

files_data = coverage.get('files', {})
for file_path, data in sorted(files_data.items(), key=lambda x: x[1]['summary']['percent_covered']):
    coverage_pct = data['summary']['percent_covered']
    if coverage_pct < 80:
        missing = data.get('missing_lines', [])
        print(f"| {file_path} | {coverage_pct:.1f}% | {len(missing)} lines |")
EOF
fi

# JavaScript/TypeScript coverage
if [ -f "package.json" ]; then
    echo "Analyzing JavaScript/TypeScript test coverage..."
    npm run test -- --coverage --coverageReporters=json --coverageReporters=html

    node << 'EOF'
const fs = require('fs');
const coverage = JSON.parse(fs.readFileSync('coverage/coverage-final.json'));

console.log("\n## JavaScript Coverage by File\n");
console.log("| File | Statements | Branches | Functions |");
console.log("|------|------------|----------|-----------|");

Object.entries(coverage).forEach(([file, data]) => {
    const stmtPct = data.s ? (Object.values(data.s).filter(v => v > 0).length / Object.keys(data.s).length * 100) : 0;
    const branchPct = data.b ? (Object.values(data.b).flat().filter(v => v > 0).length / Object.values(data.b).flat().length * 100) : 0;
    const funcPct = data.f ? (Object.values(data.f).filter(v => v > 0).length / Object.keys(data.f).length * 100) : 0;

    if (stmtPct < 80) {
        console.log(`| ${file} | ${stmtPct.toFixed(1)}% | ${branchPct.toFixed(1)}% | ${funcPct.toFixed(1)}% |`);
    }
});
EOF
fi

echo "Coverage gap analysis complete!"
```

### Advanced Coverage Gap Detection

```python
#!/usr/bin/env python3
"""advanced_coverage_gaps.py - Detect subtle coverage gaps"""

import ast
import json
from pathlib import Path
from typing import List, Dict

class CoverageGapDetector(ast.NodeVisitor):
    """Detect coverage gaps beyond line coverage"""

    def __init__(self):
        self.gaps: List[Dict] = []
        self.current_function = None

    def visit_FunctionDef(self, node):
        """Analyze function for coverage gaps"""
        self.current_function = node.name

        # Check for error handling
        has_try_except = any(isinstance(n, ast.Try) for n in ast.walk(node))
        if not has_try_except and self._calls_external_code(node):
            self.gaps.append({
                "type": "missing_error_handling",
                "function": node.name,
                "line": node.lineno,
                "recommendation": "Add try/except for external calls"
            })

        # Check for input validation
        if node.args.args and not self._has_input_validation(node):
            self.gaps.append({
                "type": "missing_input_validation",
                "function": node.name,
                "line": node.lineno,
                "recommendation": "Add input validation/type checking"
            })

        self.generic_visit(node)

    def _calls_external_code(self, node) -> bool:
        """Check if function calls external APIs"""
        for child in ast.walk(node):
            if isinstance(child, ast.Call):
                if isinstance(child.func, ast.Attribute):
                    return True
        return False

    def _has_input_validation(self, node) -> bool:
        """Check if function validates inputs"""
        for child in ast.walk(node):
            if isinstance(child, (ast.Assert, ast.Raise)):
                return True
            if isinstance(child, ast.Call):
                if isinstance(child.func, ast.Name) and child.func.id == 'isinstance':
                    return True
        return False
```

---

## Pattern 3: Documentation Gaps

Find missing or outdated documentation.

### Python Implementation

```python
#!/usr/bin/env python3
"""documentation_gap_analysis.py - Identify documentation gaps"""

import ast
import re
from pathlib import Path
from typing import List, Dict
from dataclasses import dataclass
from datetime import datetime

@dataclass
class DocumentationGap:
    category: str
    file_path: str
    item_name: str
    item_type: str
    severity: str  # critical, high, medium, low
    gap_type: str  # missing, incomplete, outdated
    recommendation: str

class DocstringAnalyzer(ast.NodeVisitor):
    """Analyze Python docstrings for gaps"""

    def __init__(self, file_path: str):
        self.file_path = file_path
        self.gaps: List[DocumentationGap] = []

    def visit_FunctionDef(self, node):
        """Check function docstring"""
        docstring = ast.get_docstring(node)
        is_public = not node.name.startswith('_')
        has_params = len(node.args.args) > 0
        has_return = any(isinstance(n, ast.Return) and n.value for n in ast.walk(node))

        if is_public:
            if not docstring:
                self.gaps.append(DocumentationGap(
                    category="function",
                    file_path=self.file_path,
                    item_name=node.name,
                    item_type="function",
                    severity="high" if has_params else "medium",
                    gap_type="missing",
                    recommendation=f"Add docstring to function {node.name}"
                ))
            else:
                if has_params and 'param' not in docstring.lower():
                    self.gaps.append(DocumentationGap(
                        category="function",
                        file_path=self.file_path,
                        item_name=node.name,
                        item_type="function",
                        severity="medium",
                        gap_type="incomplete",
                        recommendation=f"Document parameters for {node.name}"
                    ))

                if has_return and 'return' not in docstring.lower():
                    self.gaps.append(DocumentationGap(
                        category="function",
                        file_path=self.file_path,
                        item_name=node.name,
                        item_type="function",
                        severity="medium",
                        gap_type="incomplete",
                        recommendation=f"Document return value for {node.name}"
                    ))

        self.generic_visit(node)

class ProjectDocumentationAnalyzer:
    """Analyze entire project for documentation gaps"""

    def __init__(self, project_dir: str):
        self.project_dir = Path(project_dir)
        self.gaps: List[DocumentationGap] = []

    def analyze(self):
        """Run full documentation analysis"""
        print("Analyzing documentation gaps...\n")

        # Check essential documentation files
        essential_files = {
            'README.md': 'critical',
            'CONTRIBUTING.md': 'high',
            'LICENSE': 'critical',
            'CHANGELOG.md': 'medium',
        }

        for file, severity in essential_files.items():
            if not (self.project_dir / file).exists():
                self.gaps.append(DocumentationGap(
                    category="project_docs",
                    file_path=file,
                    item_name=file,
                    item_type="file",
                    severity=severity,
                    gap_type="missing",
                    recommendation=f"Create {file}"
                ))

        # Analyze code documentation
        for py_file in self.project_dir.rglob('*.py'):
            if 'test' in str(py_file) or 'migration' in str(py_file):
                continue

            try:
                with open(py_file) as f:
                    tree = ast.parse(f.read())

                analyzer = DocstringAnalyzer(str(py_file))
                analyzer.visit(tree)
                self.gaps.extend(analyzer.gaps)
            except SyntaxError:
                continue

        return self.gaps

    def generate_report(self, output_file: str = "documentation_gap_report.md"):
        """Generate documentation gap report"""
        by_severity = {}
        for gap in self.gaps:
            if gap.severity not in by_severity:
                by_severity[gap.severity] = []
            by_severity[gap.severity].append(gap)

        report = f"""# Documentation Gap Analysis Report

## Executive Summary

- **Total Gaps**: {len(self.gaps)}
- **Critical**: {len(by_severity.get('critical', []))}
- **High**: {len(by_severity.get('high', []))}
- **Medium**: {len(by_severity.get('medium', []))}

## Critical and High Priority Gaps

"""
        for severity in ['critical', 'high']:
            if severity in by_severity:
                report += f"### {severity.upper()}\n\n"
                for gap in by_severity[severity][:20]:
                    report += f"- **{gap.category}**: {gap.item_name}\n"
                    report += f"  - Action: {gap.recommendation}\n\n"

        with open(output_file, 'w') as f:
            f.write(report)

        return report

# Usage
if __name__ == "__main__":
    analyzer = ProjectDocumentationAnalyzer(".")
    gaps = analyzer.analyze()
    analyzer.generate_report()
```

---

## Pattern 4: SWOT Analysis

Strategic gap analysis using SWOT framework.

```python
#!/usr/bin/env python3
"""swot_analysis.py - SWOT analysis for gap identification"""

from dataclasses import dataclass
from typing import List, Dict
from enum import Enum

class SWOTCategory(Enum):
    STRENGTH = "strength"
    WEAKNESS = "weakness"
    OPPORTUNITY = "opportunity"
    THREAT = "threat"

@dataclass
class SWOTItem:
    category: SWOTCategory
    description: str
    impact: str
    evidence: List[str]
    recommendations: List[str]

class SWOTAnalyzer:
    """Perform SWOT analysis to identify strategic gaps"""

    def __init__(self, project_name: str):
        self.project_name = project_name
        self.items: List[SWOTItem] = []

    def add_item(self, category: SWOTCategory, description: str,
                 impact: str, evidence: List[str], recommendations: List[str]):
        """Add SWOT item"""
        self.items.append(SWOTItem(
            category=category,
            description=description,
            impact=impact,
            evidence=evidence,
            recommendations=recommendations
        ))

    def identify_gaps(self) -> List[str]:
        """Identify gaps from SWOT analysis"""
        gaps = []

        # Weaknesses are internal gaps
        weaknesses = [item for item in self.items if item.category == SWOTCategory.WEAKNESS]
        for weakness in weaknesses:
            gaps.append(f"GAP: {weakness.description} - Impact: {weakness.impact}")

        # Threats that expose gaps
        threats = [item for item in self.items if item.category == SWOTCategory.THREAT]
        for threat in threats:
            gaps.append(f"THREAT GAP: {threat.description} - Impact: {threat.impact}")

        return gaps

    def generate_gap_action_plan(self) -> str:
        """Generate action plan from identified gaps"""
        gaps = self.identify_gaps()

        plan = f"""# Gap Action Plan - {self.project_name}

## Identified Gaps

Total: {len(gaps)}

"""
        high_priority = [g for g in gaps if 'high' in g.lower()]
        if high_priority:
            plan += "### High Priority\n\n"
            for gap in high_priority:
                plan += f"- {gap}\n"

        plan += "\n### Recommended Actions\n\n"
        weaknesses = [item for item in self.items if item.category == SWOTCategory.WEAKNESS]
        for weakness in weaknesses:
            plan += f"- **{weakness.description}**\n"
            for rec in weakness.recommendations[:3]:
                plan += f"  - {rec}\n"

        return plan

# Usage
if __name__ == "__main__":
    analyzer = SWOTAnalyzer("MyProject")
    analyzer.add_item(
        SWOTCategory.WEAKNESS,
        "Low test coverage (65%)",
        "high",
        ["Coverage report shows 65%"],
        ["Implement test-first development", "Add coverage gates"]
    )
    print(analyzer.generate_gap_action_plan())
```

---

## Pattern 5: Capability Maturity Model

Assess organizational capability maturity.

```python
#!/usr/bin/env python3
"""capability_maturity_assessment.py - CMM-based gap analysis"""

from dataclasses import dataclass
from typing import List, Dict
from enum import Enum

class MaturityLevel(Enum):
    INITIAL = 1
    REPEATABLE = 2
    DEFINED = 3
    MANAGED = 4
    OPTIMIZING = 5

@dataclass
class CapabilityArea:
    name: str
    current_level: MaturityLevel
    target_level: MaturityLevel
    gaps: List[str]
    recommendations: List[str]

class CapabilityMaturityAssessment:
    """Assess capability maturity and identify gaps"""

    def __init__(self, organization: str):
        self.organization = organization
        self.areas: List[CapabilityArea] = []

    def assess_area(self, name: str, current_level: int, target_level: int,
                   gaps: List[str], recommendations: List[str]):
        """Assess a capability area"""
        self.areas.append(CapabilityArea(
            name=name,
            current_level=MaturityLevel(current_level),
            target_level=MaturityLevel(target_level),
            gaps=gaps,
            recommendations=recommendations
        ))

    def calculate_gap(self) -> Dict:
        """Calculate maturity gaps"""
        total_gap = sum(a.target_level.value - a.current_level.value for a in self.areas)
        avg_gap = total_gap / len(self.areas) if self.areas else 0

        return {
            "average_gap": avg_gap,
            "total_areas": len(self.areas),
            "areas_at_target": sum(1 for a in self.areas if a.current_level == a.target_level)
        }

    def generate_report(self) -> str:
        """Generate maturity assessment report"""
        report = f"# Capability Maturity Assessment - {self.organization}\n\n"
        report += "## Maturity Matrix\n\n"
        report += "| Area | Current | Target | Gap |\n"
        report += "|------|---------|--------|-----|\n"

        for area in self.areas:
            gap = area.target_level.value - area.current_level.value
            report += f"| {area.name} | {area.current_level.value} | {area.target_level.value} | {gap} |\n"

        stats = self.calculate_gap()
        report += f"\n**Average Gap**: {stats['average_gap']:.1f} levels\n"
        report += f"**Areas at Target**: {stats['areas_at_target']}/{stats['total_areas']}\n"

        return report
```

---

## Pattern 6: Security Posture

Assess security controls and compliance gaps.

See `security-scanning-suite` skill for detailed security gap analysis including:
- SAST analysis for code vulnerabilities
- Dependency scanning for vulnerable packages
- Secret detection and credential leaks
- Container and infrastructure security
- Compliance with OWASP, CWE, SOC 2, HIPAA standards
