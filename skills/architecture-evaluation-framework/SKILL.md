---
name: architecture-evaluation-framework
description: Comprehensive architectural analysis and evaluation framework for system architecture assessment. Use for architecture pattern identification, SOLID principles evaluation, coupling/cohesion analysis, scalability assessment, performance characteristics, security architecture, data architecture, microservices vs monolith, technical debt quantification, and ADRs. Includes C4 model, 4+1 views, QAW, ATAM, architectural fitness functions, and visualization tools.
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, WebFetch]
---

# Architecture Evaluation Framework

## Purpose

"How sound is the architecture?" - This Skill provides comprehensive architectural analysis and evaluation capabilities for assessing system architecture quality, identifying architectural issues, and ensuring long-term maintainability and scalability.

1. **Architecture Pattern Identification** - Detect and analyze architectural patterns in use
2. **SOLID Principles Evaluation** - Assess adherence to SOLID design principles
3. **Coupling and Cohesion Analysis** - Measure module dependencies and cohesion
4. **Scalability Assessment** - Evaluate system's ability to scale
5. **Performance Characteristics Analysis** - Analyze performance bottlenecks and patterns
6. **Security Architecture Review** - Assess security design and patterns
7. **Data Architecture Evaluation** - Analyze data flows, storage, and consistency
8. **Microservices vs Monolith Analysis** - Evaluate architectural style appropriateness
9. **Technical Debt Quantification** - Measure and track architectural technical debt
10. **Architecture Decision Records (ADRs)** - Document and evaluate architectural decisions

## When to Use This Skill

- Pre-development architecture design reviews
- Legacy system modernization planning
- Microservices migration assessments
- Performance optimization initiatives
- Security architecture audits
- Scalability planning and evaluation
- Technical debt assessment and prioritization
- Architecture refactoring planning
- New team member architecture onboarding
- Compliance and regulatory architecture reviews
- Cloud migration architecture planning
- API design and versioning strategies
- Data architecture optimization
- System integration planning
- Architecture governance and standards

## Core Concepts

### Architecture Evaluation Process

```
┌────────────────────────────────────────────────┐
│       Architecture Evaluation Framework        │
├────────────────────────────────────────────────┤
│                                                │
│  1. Discovery & Documentation                 │
│     ├── Map current architecture              │
│     ├── Identify components & boundaries      │
│     ├── Document data flows                   │
│     └── Capture architectural decisions       │
│                                                │
│  2. Pattern Analysis                          │
│     ├── Identify architectural patterns       │
│     ├── Assess pattern appropriateness        │
│     ├── Detect anti-patterns                  │
│     └── Evaluate pattern consistency          │
│                                                │
│  3. Quality Attributes Assessment             │
│     ├── Performance characteristics           │
│     ├── Scalability & elasticity             │
│     ├── Security & privacy                    │
│     ├── Reliability & availability            │
│     ├── Maintainability                       │
│     └── Testability                           │
│                                                │
│  4. Technical Analysis                        │
│     ├── SOLID principles compliance          │
│     ├── Coupling & cohesion metrics          │
│     ├── Dependency analysis                   │
│     ├── Code complexity metrics               │
│     └── API design evaluation                 │
│                                                │
│  5. Risk & Debt Assessment                    │
│     ├── Identify architectural risks          │
│     ├── Quantify technical debt              │
│     ├── Evaluate trade-offs                  │
│     └── Prioritize improvements               │
│                                                │
│  6. Recommendations & Roadmap                 │
│     ├── Document findings                     │
│     ├── Prioritize improvements               │
│     ├── Create remediation plan               │
│     └── Define success metrics                │
│                                                │
└────────────────────────────────────────────────┘
```

### C4 Model - Architecture Documentation

```
Level 1: SYSTEM CONTEXT
┌──────────────────────────────────────┐
│   Shows how system fits in world    │
│   Users, external systems            │
└──────────────────────────────────────┘
                  ↓
Level 2: CONTAINER
┌──────────────────────────────────────┐
│   High-level tech choices            │
│   Web apps, databases, microservices │
└──────────────────────────────────────┘
                  ↓
Level 3: COMPONENT
┌──────────────────────────────────────┐
│   Components within containers       │
│   Services, repositories, controllers│
└──────────────────────────────────────┘
                  ↓
Level 4: CODE
┌──────────────────────────────────────┐
│   Class diagrams, implementation     │
│   (optional - usually IDE generated) │
└──────────────────────────────────────┘
```

### 4+1 Architectural Views

```
┌────────────────┬────────────────┐
│   LOGICAL      │   DEVELOPMENT  │
│   View         │   View         │
│   (Classes,    │   (Packages,   │
│   Objects)     │   Layers)      │
├────────────────┴────────────────┤
│        SCENARIOS                │
│        (+1 View)                │
│        Use Cases & Workflows    │
├────────────────┬────────────────┤
│   PHYSICAL     │   PROCESS      │
│   View         │   View         │
│   (Deployment) │   (Concurrency)│
└────────────────┴────────────────┘
```

### Quality Attribute Scenarios (ATAM)

```
Stimulus → System → Response
   │         │         │
   ├─ Source    ├─ Artifact    ├─ Measure
   ├─ Condition ├─ Environment └─ Response Time
   └─ Frequency

Example (Performance):
Stimulus: 1000 concurrent users
System: Web application under peak load
Response: < 200ms response time, 99th percentile
```

## Knowledge Resources

### Architecture Frameworks & Models

- [C4 Model](https://c4model.com/) - Context, Container, Component, Code
- [4+1 Architectural Views](https://en.wikipedia.org/wiki/4%2B1_architectural_view_model) - Kruchten's model
- [ATAM](https://resources.sei.cmu.edu/library/asset-view.cfm?assetid=513908) - Architecture Tradeoff Analysis Method
- [Quality Attribute Workshop](https://wiki.sei.cmu.edu/sad/index.php/Quality_Attribute_Workshop_(QAW)) - SEI method
- [ADR](https://adr.github.io/) - Architecture Decision Records
- [Arc42](https://arc42.org/) - Architecture documentation template
- [Architectural Fitness Functions](https://www.thoughtworks.com/insights/articles/fitness-function-driven-development) - Automated governance

### Architecture Patterns

- [Microservices Patterns](https://microservices.io/patterns/) - Chris Richardson's patterns
- [Enterprise Integration Patterns](https://www.enterpriseintegrationpatterns.com/) - EIP catalog
- [Cloud Design Patterns](https://docs.microsoft.com/en-us/azure/architecture/patterns/) - Azure patterns
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/) - Cloud architecture
- [12 Factor App](https://12factor.net/) - Modern application principles
- [Domain-Driven Design](https://www.domainlanguage.com/ddd/) - Strategic design

### SOLID Principles

- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID) - Object-oriented design
  - **S**ingle Responsibility Principle
  - **O**pen/Closed Principle
  - **L**iskov Substitution Principle
  - **I**nterface Segregation Principle
  - **D**ependency Inversion Principle

### Analysis Tools

- [SonarQube](https://www.sonarqube.org/) - Code quality and architecture analysis
- [Dependency Cruiser](https://github.com/sverweij/dependency-cruiser) - Dependency validation
- [Madge](https://github.com/pahen/madge) - Visual dependency graphs
- [jQAssistant](https://jqassistant.org/) - Java architecture analysis
- [ArchUnit](https://www.archunit.org/) - Architecture unit testing
- [Structure101](https://structure101.com/) - Architecture visualization
- [CodeScene](https://codescene.com/) - Behavioral code analysis

## Common Architecture Evaluation Gotchas

1. **Analysis Paralysis** - Over-analyzing architecture without implementation
   - **Solution**: Use iterative architecture, validate with prototypes, timebox analysis

2. **Premature Optimization** - Over-engineering for scale that may never come
   - **Solution**: Design for current +1 order of magnitude, refactor when needed

3. **Resume-Driven Development** - Choosing trendy tech without business justification
   - **Solution**: Use ADRs to document decisions, evaluate against business requirements

4. **Big Ball of Mud** - No clear architecture, everything depends on everything
   - **Solution**: Introduce bounded contexts, enforce layering, use fitness functions

5. **Distributed Monolith** - Microservices with tight coupling
   - **Solution**: Design for bounded contexts, use event-driven patterns, avoid shared databases

6. **Ignoring Non-Functional Requirements** - Only focusing on features
   - **Solution**: Use quality attribute scenarios, define NFRs early, measure continuously

7. **Gold Plating** - Over-engineering for imagined future requirements
   - **Solution**: YAGNI principle, validate assumptions, incremental architecture

8. **Vendor Lock-in** - Architecture too tightly coupled to specific vendor
   - **Solution**: Use abstraction layers, prefer open standards, evaluate portability

9. **Not Documenting Decisions** - No record of why architecture choices were made
   - **Solution**: Use ADRs, document trade-offs, maintain architecture diagrams

10. **Ignoring Conway's Law** - Architecture doesn't match team structure
    - **Solution**: Align team boundaries with architectural boundaries, use inverse Conway

## Implementation Patterns

### Pattern 1: SOLID Principles Evaluation

Assess code adherence to SOLID design principles:

```python
#!/usr/bin/env python3
"""
solid_principles_analyzer.py - Evaluate SOLID compliance
"""

import ast
from pathlib import Path
from typing import List, Dict, Set, Tuple
from dataclasses import dataclass
from collections import defaultdict

@dataclass
class SOLIDViolation:
    principle: str  # S, O, L, I, or D
    file_path: str
    class_name: str
    line_number: int
    severity: str
    description: str
    recommendation: str

class SOLIDAnalyzer(ast.NodeVisitor):
    """Analyze code for SOLID principle violations"""

    def __init__(self, file_path: str):
        self.file_path = file_path
        self.violations: List[SOLIDViolation] = []
        self.classes: Dict[str, ast.ClassDef] = {}

    def visit_ClassDef(self, node: ast.ClassDef):
        """Analyze class for SOLID violations"""
        self.classes[node.name] = node

        # Single Responsibility Principle
        self._check_srp(node)

        # Open/Closed Principle
        self._check_ocp(node)

        # Liskov Substitution Principle
        self._check_lsp(node)

        # Interface Segregation Principle
        self._check_isp(node)

        # Dependency Inversion Principle
        self._check_dip(node)

        self.generic_visit(node)

    def _check_srp(self, node: ast.ClassDef):
        """Check Single Responsibility Principle"""
        # Count distinct responsibilities (heuristic: method groups)
        methods = [n for n in node.body if isinstance(n, ast.FunctionDef)]

        # Analyze method names for different concerns
        concerns = set()
        patterns = {
            'data_access': ['load', 'save', 'fetch', 'query', 'insert', 'update', 'delete'],
            'validation': ['validate', 'check', 'verify', 'ensure'],
            'transformation': ['transform', 'convert', 'map', 'parse', 'serialize'],
            'presentation': ['render', 'display', 'format', 'show'],
            'notification': ['notify', 'send', 'email', 'alert'],
            'logging': ['log', 'audit', 'track'],
        }

        for method in methods:
            method_name = method.name.lower()
            for concern, keywords in patterns.items():
                if any(kw in method_name for kw in keywords):
                    concerns.add(concern)

        # If class has 3+ different concerns, likely SRP violation
        if len(concerns) >= 3:
            self.violations.append(SOLIDViolation(
                principle="SRP",
                file_path=self.file_path,
                class_name=node.name,
                line_number=node.lineno,
                severity="medium",
                description=f"Class has {len(concerns)} different responsibilities: {', '.join(concerns)}",
                recommendation=f"Split {node.name} into separate classes, one per responsibility"
            ))

        # Check method count (high method count may indicate SRP violation)
        if len(methods) > 15:
            self.violations.append(SOLIDViolation(
                principle="SRP",
                file_path=self.file_path,
                class_name=node.name,
                line_number=node.lineno,
                severity="low",
                description=f"Class has {len(methods)} methods - may have too many responsibilities",
                recommendation="Consider splitting into smaller, focused classes"
            ))

    def _check_ocp(self, node: ast.ClassDef):
        """Check Open/Closed Principle"""
        # Look for large if/elif chains or switch-like behavior
        for child in ast.walk(node):
            if isinstance(child, ast.If):
                # Count elif chain length
                elif_count = 0
                current = child
                while hasattr(current, 'orelse') and current.orelse:
                    if isinstance(current.orelse[0], ast.If):
                        elif_count += 1
                        current = current.orelse[0]
                    else:
                        break

                if elif_count >= 4:
                    self.violations.append(SOLIDViolation(
                        principle="OCP",
                        file_path=self.file_path,
                        class_name=node.name,
                        line_number=child.lineno,
                        severity="medium",
                        description=f"Long if/elif chain ({elif_count} branches) - violates OCP",
                        recommendation="Replace with polymorphism or strategy pattern"
                    ))

        # Check for type checking (isinstance checks)
        isinstance_checks = []
        for child in ast.walk(node):
            if isinstance(child, ast.Call):
                if isinstance(child.func, ast.Name) and child.func.id == 'isinstance':
                    isinstance_checks.append(child)

        if len(isinstance_checks) >= 3:
            self.violations.append(SOLIDViolation(
                principle="OCP",
                file_path=self.file_path,
                class_name=node.name,
                line_number=node.lineno,
                severity="medium",
                description=f"{len(isinstance_checks)} isinstance checks - code not closed for modification",
                recommendation="Use polymorphism instead of type checking"
            ))

    def _check_lsp(self, node: ast.ClassDef):
        """Check Liskov Substitution Principle"""
        # Look for subclasses that throw NotImplementedError
        if node.bases:  # Has parent classes
            for method in node.body:
                if isinstance(method, ast.FunctionDef):
                    # Check if method raises NotImplementedError
                    for stmt in ast.walk(method):
                        if isinstance(stmt, ast.Raise):
                            if isinstance(stmt.exc, ast.Call):
                                if isinstance(stmt.exc.func, ast.Name):
                                    if stmt.exc.func.id == 'NotImplementedError':
                                        self.violations.append(SOLIDViolation(
                                            principle="LSP",
                                            file_path=self.file_path,
                                            class_name=node.name,
                                            line_number=stmt.lineno,
                                            severity="high",
                                            description=f"Method {method.name} raises NotImplementedError - LSP violation",
                                            recommendation="Remove method from interface or provide implementation"
                                        ))

    def _check_isp(self, node: ast.ClassDef):
        """Check Interface Segregation Principle"""
        # For Python, check for large abstract base classes
        methods = [n for n in node.body if isinstance(n, ast.FunctionDef)]

        # Check if class looks like an interface (all abstract methods)
        abstract_methods = []
        for method in methods:
            # Check for @abstractmethod decorator
            if method.decorator_list:
                for dec in method.decorator_list:
                    if isinstance(dec, ast.Name) and dec.id in ['abstractmethod', 'abstractproperty']:
                        abstract_methods.append(method)

        # If interface has many methods (>7), likely ISP violation
        if len(abstract_methods) > 7:
            self.violations.append(SOLIDViolation(
                principle="ISP",
                file_path=self.file_path,
                class_name=node.name,
                line_number=node.lineno,
                severity="medium",
                description=f"Interface has {len(abstract_methods)} abstract methods - too broad",
                recommendation="Split into smaller, more specific interfaces"
            ))

    def _check_dip(self, node: ast.ClassDef):
        """Check Dependency Inversion Principle"""
        # Look for direct instantiation of concrete classes in methods
        instantiations = []

        for method in node.body:
            if isinstance(method, ast.FunctionDef):
                for stmt in ast.walk(method):
                    if isinstance(stmt, ast.Call):
                        # Direct class instantiation (not factory/builder)
                        if isinstance(stmt.func, ast.Name):
                            # Exclude built-in types
                            if stmt.func.id[0].isupper() and stmt.func.id not in [
                                'Dict', 'List', 'Set', 'Tuple', 'Optional', 'Exception'
                            ]:
                                instantiations.append((stmt.func.id, stmt.lineno))

        if len(instantiations) >= 5:
            self.violations.append(SOLIDViolation(
                principle="DIP",
                file_path=self.file_path,
                class_name=node.name,
                line_number=node.lineno,
                severity="medium",
                description=f"Class directly instantiates {len(instantiations)} concrete classes",
                recommendation="Use dependency injection and depend on abstractions"
            ))

def analyze_solid_compliance(source_dir: str) -> Dict[str, List[SOLIDViolation]]:
    """Analyze entire codebase for SOLID compliance"""

    all_violations = {
        'SRP': [],
        'OCP': [],
        'LSP': [],
        'ISP': [],
        'DIP': []
    }

    for py_file in Path(source_dir).rglob('*.py'):
        if 'test' in str(py_file):
            continue

        try:
            with open(py_file) as f:
                tree = ast.parse(f.read())

            analyzer = SOLIDAnalyzer(str(py_file))
            analyzer.visit(tree)

            for violation in analyzer.violations:
                all_violations[violation.principle].append(violation)

        except SyntaxError:
            continue

    return all_violations

def generate_solid_report(violations: Dict[str, List[SOLIDViolation]], output_file: str):
    """Generate SOLID compliance report"""

    total = sum(len(v) for v in violations.values())

    report = f"""# SOLID Principles Compliance Report

## Executive Summary

- **Total Violations**: {total}
- **Single Responsibility**: {len(violations['SRP'])} violations
- **Open/Closed**: {len(violations['OCP'])} violations
- **Liskov Substitution**: {len(violations['LSP'])} violations
- **Interface Segregation**: {len(violations['ISP'])} violations
- **Dependency Inversion**: {len(violations['DIP'])} violations

## Compliance Score

```
SRP: {'█' * int((1 - min(1, len(violations['SRP'])/10)) * 50)}░ {max(0, 100 - len(violations['SRP'])*10)}%
OCP: {'█' * int((1 - min(1, len(violations['OCP'])/10)) * 50)}░ {max(0, 100 - len(violations['OCP'])*10)}%
LSP: {'█' * int((1 - min(1, len(violations['LSP'])/10)) * 50)}░ {max(0, 100 - len(violations['LSP'])*10)}%
ISP: {'█' * int((1 - min(1, len(violations['ISP'])/10)) * 50)}░ {max(0, 100 - len(violations['ISP'])*10)}%
DIP: {'█' * int((1 - min(1, len(violations['DIP'])/10)) * 50)}░ {max(0, 100 - len(violations['DIP'])*10)}%
```

## Detailed Violations

"""

    for principle, viols in violations.items():
        if not viols:
            continue

        principle_names = {
            'SRP': 'Single Responsibility Principle',
            'OCP': 'Open/Closed Principle',
            'LSP': 'Liskov Substitution Principle',
            'ISP': 'Interface Segregation Principle',
            'DIP': 'Dependency Inversion Principle'
        }

        report += f"### {principle_names[principle]}\n\n"

        # Group by severity
        by_severity = defaultdict(list)
        for v in viols:
            by_severity[v.severity].append(v)

        for severity in ['high', 'medium', 'low']:
            if severity in by_severity:
                report += f"#### {severity.upper()} Severity\n\n"

                for v in by_severity[severity][:10]:  # Top 10
                    report += f"**{v.class_name}** (`{v.file_path}:{v.line_number}`)\n"
                    report += f"- Issue: {v.description}\n"
                    report += f"- Fix: {v.recommendation}\n\n"

    report += """
## Recommendations

### Immediate Actions (High Severity)

"""

    # Collect high severity violations
    high_severity = []
    for viols in violations.values():
        high_severity.extend([v for v in viols if v.severity == 'high'])

    for v in high_severity[:5]:
        report += f"1. **{v.principle}**: {v.recommendation} ({v.class_name})\n"

    report += """
### Long-term Improvements

1. **Establish Architecture Guidelines** - Document SOLID principles for team
2. **Use Static Analysis** - Add linting rules to enforce SOLID
3. **Code Reviews** - Focus on SOLID compliance
4. **Refactoring Sprints** - Dedicate time to fix violations
5. **Training** - Educate team on SOLID principles

## SOLID Principles Quick Reference

### Single Responsibility Principle (SRP)
"A class should have only one reason to change"
- Each class should have a single, well-defined responsibility
- Separate concerns into different classes

### Open/Closed Principle (OCP)
"Open for extension, closed for modification"
- Use inheritance and polymorphism instead of modifying existing code
- Replace if/else chains with strategy pattern

### Liskov Substitution Principle (LSP)
"Subtypes must be substitutable for their base types"
- Subclasses should enhance, not break, parent behavior
- Avoid NotImplementedError in subclasses

### Interface Segregation Principle (ISP)
"Clients shouldn't depend on interfaces they don't use"
- Create small, focused interfaces
- Split large interfaces into smaller ones

### Dependency Inversion Principle (DIP)
"Depend on abstractions, not concretions"
- Use dependency injection
- Code to interfaces, not implementations
"""

    with open(output_file, 'w') as f:
        f.write(report)

    print(f"SOLID compliance report generated: {output_file}")

# Example usage
if __name__ == "__main__":
    violations = analyze_solid_compliance("src/")
    generate_solid_report(violations, "solid_compliance_report.md")
```

### Pattern 2: Coupling and Cohesion Analysis

Measure module dependencies and internal cohesion:

```python
#!/usr/bin/env python3
"""
coupling_cohesion_analyzer.py - Analyze coupling and cohesion
"""

import ast
from pathlib import Path
from typing import List, Dict, Set, Tuple
from dataclasses import dataclass
from collections import defaultdict
import json

@dataclass
class Module:
    name: str
    file_path: str
    imports: Set[str]
    exports: Set[str]  # Classes and functions defined
    internal_calls: int  # Calls within module
    external_calls: int  # Calls to other modules

@dataclass
class CouplingMetric:
    module: str
    afferent_coupling: int  # Ca - modules that depend on this
    efferent_coupling: int  # Ce - modules this depends on
    instability: float      # I = Ce / (Ca + Ce)
    abstractness: float     # A = abstract classes / total classes
    distance: float         # D = |A + I - 1|

class CouplingCohesionAnalyzer:
    """Analyze coupling and cohesion in codebase"""

    def __init__(self, source_dir: str):
        self.source_dir = Path(source_dir)
        self.modules: Dict[str, Module] = {}
        self.dependency_graph: Dict[str, Set[str]] = defaultdict(set)

    def analyze(self):
        """Run full coupling/cohesion analysis"""
        print("Analyzing modules...")
        self._discover_modules()

        print("Building dependency graph...")
        self._build_dependency_graph()

        print("Calculating metrics...")
        metrics = self._calculate_coupling_metrics()

        return metrics

    def _discover_modules(self):
        """Discover all modules and their exports"""
        for py_file in self.source_dir.rglob('*.py'):
            if 'test' in str(py_file):
                continue

            module_name = self._get_module_name(py_file)

            try:
                with open(py_file) as f:
                    tree = ast.parse(f.read())

                imports = self._extract_imports(tree)
                exports = self._extract_exports(tree)
                internal, external = self._count_calls(tree, module_name)

                self.modules[module_name] = Module(
                    name=module_name,
                    file_path=str(py_file),
                    imports=imports,
                    exports=exports,
                    internal_calls=internal,
                    external_calls=external
                )

            except SyntaxError:
                continue

    def _get_module_name(self, file_path: Path) -> str:
        """Convert file path to module name"""
        rel_path = file_path.relative_to(self.source_dir)
        return str(rel_path).replace('/', '.').replace('\\', '.').replace('.py', '')

    def _extract_imports(self, tree: ast.AST) -> Set[str]:
        """Extract all imports from module"""
        imports = set()

        for node in ast.walk(tree):
            if isinstance(node, ast.Import):
                for alias in node.names:
                    imports.add(alias.name)
            elif isinstance(node, ast.ImportFrom):
                if node.module:
                    imports.add(node.module)

        return imports

    def _extract_exports(self, tree: ast.AST) -> Set[str]:
        """Extract all classes and functions defined in module"""
        exports = set()

        for node in ast.walk(tree):
            if isinstance(node, (ast.ClassDef, ast.FunctionDef)):
                if not node.name.startswith('_'):  # Public only
                    exports.add(node.name)

        return exports

    def _count_calls(self, tree: ast.AST, module_name: str) -> Tuple[int, int]:
        """Count internal vs external function calls"""
        internal = 0
        external = 0

        for node in ast.walk(tree):
            if isinstance(node, ast.Call):
                # Heuristic: attribute calls are likely external
                if isinstance(node.func, ast.Attribute):
                    external += 1
                else:
                    internal += 1

        return internal, external

    def _build_dependency_graph(self):
        """Build module dependency graph"""
        for module_name, module in self.modules.items():
            for import_name in module.imports:
                # Find matching module
                for other_module in self.modules.keys():
                    if import_name in other_module or other_module in import_name:
                        self.dependency_graph[module_name].add(other_module)

    def _calculate_coupling_metrics(self) -> List[CouplingMetric]:
        """Calculate coupling metrics for all modules"""
        metrics = []

        for module_name, module in self.modules.items():
            # Efferent coupling (Ce): modules this depends on
            ce = len(self.dependency_graph[module_name])

            # Afferent coupling (Ca): modules that depend on this
            ca = sum(1 for deps in self.dependency_graph.values() if module_name in deps)

            # Instability (I = Ce / (Ca + Ce))
            instability = ce / (ca + ce) if (ca + ce) > 0 else 0

            # Abstractness (A = abstract classes / total classes)
            # Simplified: check for ABC usage
            abstractness = 0.0  # Would need deeper analysis

            # Distance from main sequence (D = |A + I - 1|)
            distance = abs(abstractness + instability - 1)

            metrics.append(CouplingMetric(
                module=module_name,
                afferent_coupling=ca,
                efferent_coupling=ce,
                instability=instability,
                abstractness=abstractness,
                distance=distance
            ))

        return metrics

    def calculate_cohesion(self, module_name: str) -> float:
        """
        Calculate LCOM (Lack of Cohesion of Methods) for a module
        Lower is better (0 = perfect cohesion, 1 = no cohesion)
        """
        module = self.modules.get(module_name)
        if not module:
            return 0.0

        # Simplified cohesion: internal calls / total calls
        total_calls = module.internal_calls + module.external_calls
        if total_calls == 0:
            return 0.0

        cohesion = module.internal_calls / total_calls
        lcom = 1 - cohesion  # Invert so lower is better

        return lcom

    def generate_report(self, metrics: List[CouplingMetric], output_file: str):
        """Generate coupling/cohesion report"""

        report = f"""# Coupling and Cohesion Analysis Report

## Metrics Overview

Total modules analyzed: {len(metrics)}

### Coupling Distribution

"""

        # Sort by instability
        metrics_sorted = sorted(metrics, key=lambda m: m.instability, reverse=True)

        report += "| Module | Ca | Ce | Instability | Distance |\n"
        report += "|--------|----|----|-------------|----------|\n"

        for m in metrics_sorted[:20]:  # Top 20
            report += f"| {m.module} | {m.afferent_coupling} | {m.efferent_coupling} | "
            report += f"{m.instability:.2f} | {m.distance:.2f} |\n"

        report += """
## Coupling Guidelines

- **Ca (Afferent Coupling)**: High Ca = many modules depend on this (stable, hard to change)
- **Ce (Efferent Coupling)**: High Ce = depends on many modules (unstable, fragile)
- **Instability (I)**: 0 = maximally stable, 1 = maximally unstable
- **Distance (D)**: 0 = on main sequence (good), 1 = far from ideal

### Ideal Zones

```
Stable & Abstract (Ca high, Ce low, Abstract)
    ↑
    │  MAIN SEQUENCE
    │  (good zone)
    │ /
    │/
────┼──────────→
    │  Unstable & Concrete
    │  (implementation details)
```

## Problem Areas

### High Instability (I > 0.7)

"""

        high_instability = [m for m in metrics if m.instability > 0.7]
        for m in high_instability[:10]:
            report += f"- **{m.module}**: I={m.instability:.2f}, Ce={m.efferent_coupling}\n"
            report += f"  - Depends on {m.efferent_coupling} modules - consider reducing dependencies\n"

        report += "\n### Low Cohesion Modules\n\n"

        # Calculate cohesion for all modules
        low_cohesion = []
        for module_name in self.modules.keys():
            lcom = self.calculate_cohesion(module_name)
            if lcom > 0.6:  # High LCOM = low cohesion
                low_cohesion.append((module_name, lcom))

        low_cohesion.sort(key=lambda x: x[1], reverse=True)

        for module_name, lcom in low_cohesion[:10]:
            report += f"- **{module_name}**: LCOM={lcom:.2f}\n"
            report += f"  - Low cohesion - consider splitting module\n"

        report += """
## Recommendations

### Reduce Coupling

1. **Apply Dependency Inversion** - Depend on abstractions, not concretions
2. **Use Facade Pattern** - Simplify complex subsystem dependencies
3. **Event-Driven Architecture** - Decouple through events/messages
4. **Dependency Injection** - Invert control, reduce direct dependencies

### Increase Cohesion

1. **Single Responsibility** - Each module should have one clear purpose
2. **Related Functions Together** - Group related functionality
3. **Extract Unrelated Code** - Move unrelated code to separate modules
4. **Use Domain-Driven Design** - Organize by business domain, not technical layers

### Architectural Patterns

- **Layered Architecture** - Enforce one-way dependencies
- **Hexagonal Architecture** - Isolate core domain from external concerns
- **Microservices** - Split into independent, loosely coupled services (when appropriate)
"""

        with open(output_file, 'w') as f:
            f.write(report)

        print(f"Coupling/cohesion report generated: {output_file}")

        # Also generate JSON for visualization tools
        json_data = {
            "modules": [
                {
                    "name": m.module,
                    "ca": m.afferent_coupling,
                    "ce": m.efferent_coupling,
                    "instability": m.instability,
                    "distance": m.distance
                }
                for m in metrics
            ],
            "dependencies": {
                module: list(deps)
                for module, deps in self.dependency_graph.items()
            }
        }

        json_file = output_file.replace('.md', '.json')
        with open(json_file, 'w') as f:
            json.dump(json_data, f, indent=2)

        print(f"JSON data for visualization: {json_file}")

# Example usage
if __name__ == "__main__":
    analyzer = CouplingCohesionAnalyzer("src/")
    metrics = analyzer.analyze()
    analyzer.generate_report(metrics, "coupling_cohesion_report.md")
```

### Pattern 3: Architecture Decision Records (ADRs)

Document and track architectural decisions:

```markdown
# ADR Template and Management

## ADR Template

```markdown
# ADR-{NUMBER}: {Title}

Date: {YYYY-MM-DD}
Status: {Proposed | Accepted | Deprecated | Superseded by ADR-XXX}
Deciders: {List of people involved in decision}
Tags: {performance, security, scalability, etc.}

## Context

What is the issue we're trying to solve? What are the forces at play?
- Technical constraints
- Business requirements
- Team capabilities
- Timeline pressures

## Decision

What architecture decision did we make?

Describe the decision in full sentences, with active voice. "We will..."

## Consequences

What becomes easier or more difficult to do because of this change?

### Positive
- Benefit 1
- Benefit 2

### Negative
- Trade-off 1
- Trade-off 2

### Neutral
- Changes to existing systems
- Migration requirements

## Alternatives Considered

What other options did we evaluate?

### Alternative 1: {Name}
- Pros: ...
- Cons: ...
- Why not chosen: ...

### Alternative 2: {Name}
- Pros: ...
- Cons: ...
- Why not chosen: ...

## References

- Links to relevant documentation
- RFCs, design docs
- Research/benchmarks
```

## Example ADR

```markdown
# ADR-001: Use Microservices Architecture

Date: 2025-01-15
Status: Accepted
Deciders: Tech Lead, CTO, Senior Engineers
Tags: architecture, scalability, microservices

## Context

Our monolithic application is experiencing:
- Difficulty scaling specific features independently
- Long deployment times (30+ minutes)
- Team bottlenecks as codebase grows
- Technology lock-in (entire app in Python)

We have 5 distinct bounded contexts:
1. User Management
2. Product Catalog
3. Order Processing
4. Payment
5. Notifications

## Decision

We will migrate from monolithic architecture to microservices architecture using:
- One service per bounded context
- Event-driven communication via message queue (RabbitMQ)
- API Gateway for client-facing endpoints
- Shared authentication service
- Independent databases per service (no shared DB)

## Consequences

### Positive
- Independent scaling of services
- Technology diversity (can use best tool for each service)
- Faster deployments (deploy only changed services)
- Team autonomy (teams own services end-to-end)
- Fault isolation (one service failure doesn't crash entire system)

### Negative
- Increased operational complexity
- Distributed system challenges (eventual consistency, debugging)
- Network latency between services
- Data consistency challenges
- Need for robust monitoring/observability

### Neutral
- Migration will take 6-9 months
- Need to hire DevOps engineer
- Learning curve for team

## Alternatives Considered

### Alternative 1: Modular Monolith
- Pros: Simpler operations, easier debugging, single deployment
- Cons: Still can't scale components independently, technology lock-in
- Why not chosen: Doesn't solve scaling or team autonomy issues

### Alternative 2: Serverless Functions
- Pros: Auto-scaling, no infrastructure management
- Cons: Vendor lock-in, cold starts, limited execution time
- Why not chosen: Too fine-grained, difficult to manage complex workflows

## References
- [Microservices Patterns](https://microservices.io/patterns/)
- [Building Microservices by Sam Newman](https://samnewman.io/books/building_microservices/)
- Load testing results: docs/load-test-2025-01.md
```

## ADR Management Script

```python
#!/usr/bin/env python3
"""
adr_manager.py - Manage Architecture Decision Records
"""

from pathlib import Path
from datetime import datetime
import re

class ADRManager:
    """Manage ADRs in a project"""

    def __init__(self, adr_dir: str = "docs/adr"):
        self.adr_dir = Path(adr_dir)
        self.adr_dir.mkdir(parents=True, exist_ok=True)

    def create_adr(self, title: str, template: str = "default") -> Path:
        """Create new ADR from template"""
        # Get next ADR number
        existing_adrs = list(self.adr_dir.glob("ADR-*.md"))
        if existing_adrs:
            numbers = [
                int(re.search(r'ADR-(\d+)', adr.name).group(1))
                for adr in existing_adrs
            ]
            next_number = max(numbers) + 1
        else:
            next_number = 1

        # Create ADR file
        filename = f"ADR-{next_number:03d}-{self._slugify(title)}.md"
        filepath = self.adr_dir / filename

        template_content = self._get_template(template)
        content = template_content.format(
            number=next_number,
            title=title,
            date=datetime.now().strftime("%Y-%m-%d")
        )

        filepath.write_text(content)
        print(f"Created ADR: {filepath}")
        return filepath

    def _slugify(self, text: str) -> str:
        """Convert title to slug"""
        return re.sub(r'[^\w]+', '-', text.lower()).strip('-')

    def _get_template(self, template_name: str) -> str:
        """Get ADR template"""
        return """# ADR-{number}: {title}

Date: {date}
Status: Proposed
Deciders:
Tags:

## Context

What is the issue we're trying to solve?

## Decision

What did we decide?

## Consequences

### Positive
-

### Negative
-

### Neutral
-

## Alternatives Considered

### Alternative 1:
- Pros:
- Cons:
- Why not chosen:

## References
-
"""

    def list_adrs(self):
        """List all ADRs"""
        adrs = sorted(self.adr_dir.glob("ADR-*.md"))

        print("\n=== Architecture Decision Records ===\n")

        for adr in adrs:
            # Extract status from file
            content = adr.read_text()
            status_match = re.search(r'Status:\s*(\w+)', content)
            status = status_match.group(1) if status_match else "Unknown"

            # Extract number and title
            match = re.match(r'ADR-(\d+)-(.+)\.md', adr.name)
            if match:
                number, slug = match.groups()
                print(f"ADR-{number}: {slug.replace('-', ' ').title()} [{status}]")

    def supersede_adr(self, old_number: int, new_number: int):
        """Mark ADR as superseded"""
        old_adrs = list(self.adr_dir.glob(f"ADR-{old_number:03d}-*.md"))

        if not old_adrs:
            print(f"ADR-{old_number} not found")
            return

        old_adr = old_adrs[0]
        content = old_adr.read_text()

        # Update status
        content = re.sub(
            r'Status:\s*\w+',
            f'Status: Superseded by ADR-{new_number:03d}',
            content
        )

        old_adr.write_text(content)
        print(f"Marked ADR-{old_number} as superseded by ADR-{new_number}")

# Example usage
if __name__ == "__main__":
    import sys

    manager = ADRManager()

    if len(sys.argv) < 2:
        print("Usage:")
        print("  python adr_manager.py new 'Decision Title'")
        print("  python adr_manager.py list")
        print("  python adr_manager.py supersede OLD_NUM NEW_NUM")
        sys.exit(1)

    command = sys.argv[1]

    if command == "new":
        title = sys.argv[2] if len(sys.argv) > 2 else "New Decision"
        manager.create_adr(title)
    elif command == "list":
        manager.list_adrs()
    elif command == "supersede":
        old = int(sys.argv[2])
        new = int(sys.argv[3])
        manager.supersede_adr(old, new)
```

### Pattern 4: C4 Model Architecture Visualization

Generate C4 model diagrams for architecture documentation:

```python
#!/usr/bin/env python3
"""
c4_model_generator.py - Generate C4 model diagrams
"""

from dataclasses import dataclass
from typing import List, Dict, Set
from enum import Enum

class C4Level(Enum):
    CONTEXT = "System Context"
    CONTAINER = "Container"
    COMPONENT = "Component"
    CODE = "Code"

@dataclass
class C4Element:
    name: str
    type: str  # Person, System, Container, Component
    description: str
    technology: str = ""
    tags: List[str] = None

@dataclass
class C4Relationship:
    source: str
    target: str
    description: str
    technology: str = ""

class C4ModelGenerator:
    """Generate C4 model diagrams using PlantUML"""

    def __init__(self, system_name: str):
        self.system_name = system_name
        self.elements: List[C4Element] = []
        self.relationships: List[C4Relationship] = []

    def add_person(self, name: str, description: str, tags: List[str] = None):
        """Add person (external user)"""
        self.elements.append(C4Element(
            name=name,
            type="Person",
            description=description,
            tags=tags or []
        ))

    def add_system(self, name: str, description: str, tags: List[str] = None):
        """Add external system"""
        self.elements.append(C4Element(
            name=name,
            type="System",
            description=description,
            tags=tags or []
        ))

    def add_container(self, name: str, description: str, technology: str, tags: List[str] = None):
        """Add container (app, database, etc.)"""
        self.elements.append(C4Element(
            name=name,
            type="Container",
            description=description,
            technology=technology,
            tags=tags or []
        ))

    def add_component(self, name: str, description: str, technology: str, tags: List[str] = None):
        """Add component within container"""
        self.elements.append(C4Element(
            name=name,
            type="Component",
            description=description,
            technology=technology,
            tags=tags or []
        ))

    def add_relationship(self, source: str, target: str, description: str, technology: str = ""):
        """Add relationship between elements"""
        self.relationships.append(C4Relationship(
            source=source,
            target=target,
            description=description,
            technology=technology
        ))

    def generate_context_diagram(self) -> str:
        """Generate Level 1: System Context diagram"""
        diagram = f"""@startuml
!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Context.puml

title System Context diagram for {self.system_name}

"""

        # Add elements
        for elem in self.elements:
            if elem.type == "Person":
                diagram += f'Person({elem.name.replace(" ", "_")}, "{elem.name}", "{elem.description}")\n'
            elif elem.type == "System":
                if any("internal" in tag for tag in elem.tags):
                    diagram += f'System({elem.name.replace(" ", "_")}, "{elem.name}", "{elem.description}")\n'
                else:
                    diagram += f'System_Ext({elem.name.replace(" ", "_")}, "{elem.name}", "{elem.description}")\n'

        diagram += "\n"

        # Add relationships
        for rel in self.relationships:
            source = rel.source.replace(" ", "_")
            target = rel.target.replace(" ", "_")
            diagram += f'Rel({source}, {target}, "{rel.description}"'
            if rel.technology:
                diagram += f', "{rel.technology}"'
            diagram += ")\n"

        diagram += "\n@enduml\n"
        return diagram

    def generate_container_diagram(self) -> str:
        """Generate Level 2: Container diagram"""
        diagram = f"""@startuml
!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Container.puml

title Container diagram for {self.system_name}

"""

        # Add people
        for elem in self.elements:
            if elem.type == "Person":
                diagram += f'Person({elem.name.replace(" ", "_")}, "{elem.name}", "{elem.description}")\n'

        diagram += "\n"

        # Add containers
        diagram += f'System_Boundary(c1, "{self.system_name}") {{\n'
        for elem in self.elements:
            if elem.type == "Container":
                diagram += f'  Container({elem.name.replace(" ", "_")}, "{elem.name}", "{elem.technology}", "{elem.description}")\n'
        diagram += "}\n\n"

        # Add external systems
        for elem in self.elements:
            if elem.type == "System":
                diagram += f'System_Ext({elem.name.replace(" ", "_")}, "{elem.name}", "{elem.description}")\n'

        diagram += "\n"

        # Add relationships
        for rel in self.relationships:
            source = rel.source.replace(" ", "_")
            target = rel.target.replace(" ", "_")
            diagram += f'Rel({source}, {target}, "{rel.description}"'
            if rel.technology:
                diagram += f', "{rel.technology}"'
            diagram += ")\n"

        diagram += "\n@enduml\n"
        return diagram

    def generate_component_diagram(self, container_name: str) -> str:
        """Generate Level 3: Component diagram for a specific container"""
        diagram = f"""@startuml
!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Component.puml

title Component diagram for {container_name}

"""

        # Add container boundary
        diagram += f'Container_Boundary(c1, "{container_name}") {{\n'

        # Add components
        for elem in self.elements:
            if elem.type == "Component":
                diagram += f'  Component({elem.name.replace(" ", "_")}, "{elem.name}", "{elem.technology}", "{elem.description}")\n'

        diagram += "}\n\n"

        # Add relationships
        for rel in self.relationships:
            source = rel.source.replace(" ", "_")
            target = rel.target.replace(" ", "_")
            diagram += f'Rel({source}, {target}, "{rel.description}"'
            if rel.technology:
                diagram += f', "{rel.technology}"'
            diagram += ")\n"

        diagram += "\n@enduml\n"
        return diagram

    def export_diagrams(self, output_dir: str = "docs/architecture"):
        """Export all C4 diagrams"""
        from pathlib import Path

        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)

        # Context diagram
        context_file = output_path / "01-system-context.puml"
        context_file.write_text(self.generate_context_diagram())
        print(f"Generated: {context_file}")

        # Container diagram
        container_file = output_path / "02-container.puml"
        container_file.write_text(self.generate_container_diagram())
        print(f"Generated: {container_file}")

        # Component diagrams (one per container)
        containers = [e.name for e in self.elements if e.type == "Container"]
        for i, container in enumerate(containers):
            component_file = output_path / f"03-component-{container.lower().replace(' ', '-')}.puml"
            component_file.write_text(self.generate_component_diagram(container))
            print(f"Generated: {component_file}")

        # Generate README
        readme = f"""# Architecture Documentation

C4 model diagrams for {self.system_name}.

## Viewing Diagrams

Use PlantUML to render these diagrams:

```bash
# Install PlantUML
brew install plantuml  # macOS
apt install plantuml   # Ubuntu

# Render diagrams
plantuml *.puml
```

Or use online viewer: http://www.plantuml.com/plantuml/uml/

## Diagrams

1. **System Context** (`01-system-context.puml`) - How system fits in environment
2. **Container** (`02-container.puml`) - High-level technology choices
3. **Component** (`03-component-*.puml`) - Components within each container

## C4 Model Resources

- [C4 Model](https://c4model.com/)
- [PlantUML C4](https://github.com/plantuml-stdlib/C4-PlantUML)
"""

        readme_file = output_path / "README.md"
        readme_file.write_text(readme)
        print(f"Generated: {readme_file}")

# Example usage
if __name__ == "__main__":
    # Create C4 model for an e-commerce system
    c4 = C4ModelGenerator("E-Commerce Platform")

    # Level 1: System Context
    c4.add_person("Customer", "A customer of the e-commerce platform")
    c4.add_person("Admin", "Platform administrator")
    c4.add_system("Payment Gateway", "External payment processor", tags=["external"])
    c4.add_system("Email Service", "External email provider", tags=["external"])

    # Level 2: Containers
    c4.add_container("Web Application", "Delivers content to customers", "React, TypeScript", tags=["internal"])
    c4.add_container("API Gateway", "API gateway and authentication", "Kong, Lua", tags=["internal"])
    c4.add_container("Order Service", "Handles order processing", "Python, FastAPI", tags=["internal"])
    c4.add_container("Product Service", "Manages product catalog", "Python, FastAPI", tags=["internal"])
    c4.add_container("Database", "Stores data", "PostgreSQL", tags=["internal"])
    c4.add_container("Message Queue", "Async communication", "RabbitMQ", tags=["internal"])

    # Level 3: Components (for Order Service)
    c4.add_component("Order Controller", "REST API endpoints", "FastAPI")
    c4.add_component("Order Service Logic", "Business logic", "Python")
    c4.add_component("Payment Integration", "Payment processing", "Python")
    c4.add_component("Order Repository", "Data access", "SQLAlchemy")

    # Relationships
    c4.add_relationship("Customer", "Web Application", "Uses", "HTTPS")
    c4.add_relationship("Web Application", "API Gateway", "Makes API calls", "HTTPS/REST")
    c4.add_relationship("API Gateway", "Order Service", "Routes requests", "HTTP/REST")
    c4.add_relationship("API Gateway", "Product Service", "Routes requests", "HTTP/REST")
    c4.add_relationship("Order Service", "Database", "Reads/writes", "SQL")
    c4.add_relationship("Order Service", "Payment Gateway", "Processes payments", "HTTPS/REST")
    c4.add_relationship("Order Service", "Message Queue", "Publishes events", "AMQP")

    # Component relationships
    c4.add_relationship("Order Controller", "Order Service Logic", "Uses")
    c4.add_relationship("Order Service Logic", "Payment Integration", "Uses")
    c4.add_relationship("Order Service Logic", "Order Repository", "Uses")

    # Export diagrams
    c4.export_diagrams()
```

### Pattern 5: ATAM (Architecture Tradeoff Analysis Method)

Evaluate architecture quality attributes and trade-offs:

```python
#!/usr/bin/env python3
"""
atam_evaluator.py - Architecture Tradeoff Analysis Method
"""

from dataclasses import dataclass
from typing import List, Dict
from enum import Enum

class QualityAttribute(Enum):
    PERFORMANCE = "Performance"
    SCALABILITY = "Scalability"
    AVAILABILITY = "Availability"
    SECURITY = "Security"
    MODIFIABILITY = "Modifiability"
    TESTABILITY = "Testability"
    USABILITY = "Usability"
    DEPLOYABILITY = "Deployability"

@dataclass
class QualityScenario:
    """Quality attribute scenario"""
    attribute: QualityAttribute
    stimulus: str  # What happens
    source: str  # Who/what causes it
    environment: str  # Under what conditions
    artifact: str  # What part of system
    response: str  # What should happen
    measure: str  # How to measure

@dataclass
class ArchitecturalApproach:
    """Architectural decision/pattern"""
    name: str
    description: str
    patterns: List[str]
    quality_impacts: Dict[QualityAttribute, int]  # -2 to +2 scale

@dataclass
class Tradeoff:
    """Trade-off between quality attributes"""
    approach: str
    positive_attributes: List[QualityAttribute]
    negative_attributes: List[QualityAttribute]
    description: str
    severity: str  # low, medium, high

class ATAMEvaluator:
    """Architecture Tradeoff Analysis Method evaluator"""

    def __init__(self, system_name: str):
        self.system_name = system_name
        self.scenarios: List[QualityScenario] = []
        self.approaches: List[ArchitecturalApproach] = []
        self.tradeoffs: List[Tradeoff] = []

    def add_scenario(self, scenario: QualityScenario):
        """Add quality attribute scenario"""
        self.scenarios.append(scenario)

    def add_approach(self, approach: ArchitecturalApproach):
        """Add architectural approach"""
        self.approaches.append(approach)
        self._analyze_tradeoffs(approach)

    def _analyze_tradeoffs(self, approach: ArchitecturalApproach):
        """Analyze trade-offs in architectural approach"""
        positive = [attr for attr, impact in approach.quality_impacts.items() if impact > 0]
        negative = [attr for attr, impact in approach.quality_impacts.items() if impact < 0]

        if positive and negative:
            severity = "high" if any(impact < -1 for impact in approach.quality_impacts.values()) else "medium"

            self.tradeoffs.append(Tradeoff(
                approach=approach.name,
                positive_attributes=positive,
                negative_attributes=negative,
                description=f"{approach.name} improves {', '.join(a.value for a in positive)} "
                           f"but negatively impacts {', '.join(a.value for a in negative)}",
                severity=severity
            ))

    def generate_atam_report(self) -> str:
        """Generate ATAM evaluation report"""

        report = f"""# Architecture Tradeoff Analysis Method (ATAM)
## System: {self.system_name}

## Quality Attribute Scenarios

"""

        # Group scenarios by attribute
        by_attribute: Dict[QualityAttribute, List[QualityScenario]] = {}
        for scenario in self.scenarios:
            if scenario.attribute not in by_attribute:
                by_attribute[scenario.attribute] = []
            by_attribute[scenario.attribute].append(scenario)

        for attribute, scenarios in by_attribute.items():
            report += f"### {attribute.value}\n\n"

            for i, scenario in enumerate(scenarios, 1):
                report += f"**Scenario {i}**: {scenario.stimulus}\n\n"
                report += f"- **Source**: {scenario.source}\n"
                report += f"- **Environment**: {scenario.environment}\n"
                report += f"- **Artifact**: {scenario.artifact}\n"
                report += f"- **Response**: {scenario.response}\n"
                report += f"- **Measure**: {scenario.measure}\n\n"

        report += "## Architectural Approaches\n\n"

        for approach in self.approaches:
            report += f"### {approach.name}\n\n"
            report += f"{approach.description}\n\n"
            report += f"**Patterns Used**: {', '.join(approach.patterns)}\n\n"

            report += "**Quality Attribute Impact**:\n\n"
            report += "| Attribute | Impact | Rating |\n"
            report += "|-----------|--------|--------|\n"

            for attr, impact in approach.quality_impacts.items():
                impact_str = "+++" if impact == 2 else "++" if impact == 1 else "o" if impact == 0 else "--" if impact == -1 else "---"
                rating = "Excellent" if impact == 2 else "Good" if impact == 1 else "Neutral" if impact == 0 else "Poor" if impact == -1 else "Very Poor"
                report += f"| {attr.value} | {impact_str} | {rating} |\n"

            report += "\n"

        report += "## Trade-off Analysis\n\n"

        if not self.tradeoffs:
            report += "No significant trade-offs identified.\n\n"
        else:
            # Group by severity
            high_severity = [t for t in self.tradeoffs if t.severity == "high"]
            medium_severity = [t for t in self.tradeoffs if t.severity == "medium"]

            if high_severity:
                report += "### High-Impact Trade-offs\n\n"
                for tradeoff in high_severity:
                    report += f"**{tradeoff.approach}**\n\n"
                    report += f"{tradeoff.description}\n\n"
                    report += f"- Improves: {', '.join(a.value for a in tradeoff.positive_attributes)}\n"
                    report += f"- Degrades: {', '.join(a.value for a in tradeoff.negative_attributes)}\n\n"

            if medium_severity:
                report += "### Medium-Impact Trade-offs\n\n"
                for tradeoff in medium_severity:
                    report += f"**{tradeoff.approach}**: {tradeoff.description}\n\n"

        report += """## Recommendations

### Critical Decisions

"""

        # Identify critical decisions (high impact trade-offs)
        for tradeoff in high_severity:
            report += f"1. **{tradeoff.approach}**\n"
            report += f"   - Carefully evaluate impact on {', '.join(a.value for a in tradeoff.negative_attributes)}\n"
            report += f"   - Consider mitigation strategies\n\n"

        report += """
### Quality Attribute Priorities

Based on business drivers, prioritize quality attributes:

1. Rank quality attributes by business importance
2. Validate architectural approaches support top priorities
3. Accept trade-offs that negatively impact lower-priority attributes
4. Mitigate impacts on critical attributes

### Risk Mitigation

For each high-impact trade-off:
1. Identify mitigation strategies
2. Create proof-of-concept to validate approach
3. Define metrics to monitor quality attributes
4. Plan for iterative improvement
"""

        return report

# Example usage
if __name__ == "__main__":
    evaluator = ATAMEvaluator("E-Commerce Platform")

    # Define quality scenarios
    evaluator.add_scenario(QualityScenario(
        attribute=QualityAttribute.PERFORMANCE,
        stimulus="1000 concurrent users browse product catalog",
        source="End users",
        environment="Normal operations, peak traffic",
        artifact="Product Service API",
        response="System returns product list",
        measure="< 200ms response time, 99th percentile"
    ))

    evaluator.add_scenario(QualityScenario(
        attribute=QualityAttribute.SCALABILITY,
        stimulus="Black Friday traffic spike (10x normal)",
        source="Marketing campaign",
        environment="Peak load",
        artifact="Entire system",
        response="System scales to handle load",
        measure="Auto-scale within 2 minutes, maintain < 500ms response"
    ))

    evaluator.add_scenario(QualityScenario(
        attribute=QualityAttribute.AVAILABILITY,
        stimulus="Database server fails",
        source="Infrastructure failure",
        environment="Production",
        artifact="Order Service",
        response="System continues to operate",
        measure="< 5 seconds downtime, automatic failover"
    ))

    evaluator.add_scenario(QualityScenario(
        attribute=QualityAttribute.SECURITY,
        stimulus="Unauthorized access attempt",
        source="Attacker",
        environment="Production",
        artifact="API Gateway",
        response="Request is blocked and logged",
        measure="100% of unauthorized requests blocked, alerts sent within 1 minute"
    ))

    # Define architectural approaches
    evaluator.add_approach(ArchitecturalApproach(
        name="Microservices Architecture",
        description="Split monolith into independent microservices",
        patterns=["Microservices", "API Gateway", "Event-Driven"],
        quality_impacts={
            QualityAttribute.SCALABILITY: 2,
            QualityAttribute.DEPLOYABILITY: 2,
            QualityAttribute.MODIFIABILITY: 1,
            QualityAttribute.PERFORMANCE: -1,  # Network latency
            QualityAttribute.TESTABILITY: -1,  # Distributed testing complexity
        }
    ))

    evaluator.add_approach(ArchitecturalApproach(
        name="Caching Strategy",
        description="Implement multi-tier caching (Redis, CDN)",
        patterns=["Cache-Aside", "Read-Through", "CDN"],
        quality_impacts={
            QualityAttribute.PERFORMANCE: 2,
            QualityAttribute.SCALABILITY: 1,
            QualityAttribute.MODIFIABILITY: -1,  # Cache invalidation complexity
        }
    ))

    evaluator.add_approach(ArchitecturalApproach(
        name="Database Replication",
        description="Master-slave replication for read scalability",
        patterns=["Read Replicas", "CQRS"],
        quality_impacts={
            QualityAttribute.SCALABILITY: 2,
            QualityAttribute.AVAILABILITY: 1,
            QualityAttribute.PERFORMANCE: 1,
            QualityAttribute.MODIFIABILITY: -1,  # Eventual consistency
        }
    ))

    # Generate report
    report = evaluator.generate_atam_report()
    print(report)

    # Save report
    with open("atam_evaluation.md", "w") as f:
        f.write(report)

    print("\nATAM evaluation complete! Report saved to atam_evaluation.md")
```

## Best Practices

### DO's

1. **Document Architecture Early** - Create architecture diagrams before coding
2. **Use Standard Models** - Adopt C4, 4+1, or other standard frameworks
3. **Capture Decisions** - Write ADRs for all significant architectural choices
4. **Measure Quality Attributes** - Define metrics for performance, scalability, etc.
5. **Automate Governance** - Use architectural fitness functions to enforce rules
6. **Review Regularly** - Conduct architecture reviews at key milestones
7. **Validate Assumptions** - Build prototypes to test architectural hypotheses
8. **Consider Trade-offs** - Use ATAM to analyze quality attribute trade-offs
9. **Align with Business** - Ensure architecture supports business goals
10. **Evolve Incrementally** - Architecture should evolve, not be perfect upfront

### DON'Ts

1. **Don't Over-Engineer** - YAGNI - build for current +1 order of magnitude
2. **Don't Ignore NFRs** - Non-functional requirements are as important as features
3. **Don't Copy Blindly** - Netflix's architecture won't work for your startup
4. **Don't Skip Documentation** - Undocumented architecture is technical debt
5. **Don't Ignore Conway's Law** - Org structure will influence architecture
6. **Don't Optimize Prematurely** - Measure first, then optimize
7. **Don't Create Distributed Monoliths** - Microservices need proper boundaries
8. **Don't Forget Security** - Security must be architectural, not bolted on
9. **Don't Ignore Technical Debt** - Track and pay down architectural debt
10. **Don't Work in Isolation** - Involve stakeholders in architecture decisions

## Architecture Evaluation Checklist

### Discovery Phase
- [ ] Map current architecture (C4 diagrams)
- [ ] Identify all components and dependencies
- [ ] Document data flows and integration points
- [ ] Review existing ADRs and design docs
- [ ] Interview stakeholders and developers

### Pattern Analysis
- [ ] Identify architectural patterns in use
- [ ] Detect anti-patterns
- [ ] Evaluate pattern appropriateness
- [ ] Check pattern consistency across codebase

### Quality Attributes
- [ ] Define quality attribute scenarios (ATAM)
- [ ] Measure performance characteristics
- [ ] Assess scalability and elasticity
- [ ] Evaluate security posture
- [ ] Check reliability and availability
- [ ] Review maintainability and modifiability
- [ ] Assess testability

### Technical Analysis
- [ ] Analyze SOLID compliance
- [ ] Measure coupling and cohesion
- [ ] Review dependency graph
- [ ] Check code complexity metrics
- [ ] Evaluate API design
- [ ] Review data architecture

### Risk Assessment
- [ ] Identify architectural risks
- [ ] Quantify technical debt
- [ ] Analyze trade-offs (ATAM)
- [ ] Prioritize improvements
- [ ] Create mitigation plans

### Documentation & Recommendations
- [ ] Update architecture diagrams
- [ ] Write/update ADRs
- [ ] Document findings and recommendations
- [ ] Create remediation roadmap
- [ ] Define success metrics

## Related Skills

- `gap-analysis-framework` - For identifying architectural gaps
- `security-scanning-suite` - For security architecture assessment
- `evaluation-reporting-framework` - For comprehensive reports
- `codebase-onboarding-analyzer` - For architecture understanding
- `git-mastery-suite` - For analyzing architectural evolution

## References

- [C4 Model](https://c4model.com/) - Simon Brown's architecture documentation
- [ATAM](https://resources.sei.cmu.edu/library/asset-view.cfm?assetid=513908) - SEI's tradeoff analysis
- [Arc42](https://arc42.org/) - Architecture documentation template
- [Architectural Fitness Functions](https://www.thoughtworks.com/insights/articles/fitness-function-driven-development) - Automated governance
- [ADR](https://adr.github.io/) - Architecture Decision Records
- [Software Architecture Patterns](https://www.oreilly.com/library/view/software-architecture-patterns/9781491971437/) - O'Reilly book
- [Building Evolutionary Architectures](https://www.thoughtworks.com/books/building-evolutionary-architectures) - Ford, Parsons, Kua
- [Fundamentals of Software Architecture](https://www.oreilly.com/library/view/fundamentals-of-software/9781492043447/) - Richards, Ford
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/) - Cloud architecture best practices
- [12 Factor App](https://12factor.net/) - Modern app development methodology
