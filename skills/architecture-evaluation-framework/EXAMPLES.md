# Architecture Evaluation Examples

## Table of Contents
1. [Python Architecture Analysis](#python-analysis)
2. [JavaScript/TypeScript Analysis](#javascript-analysis)
3. [Go Analysis](#go-analysis)
4. [SOLID Analysis Example](#solid-analysis)
5. [Microservices Evaluation](#microservices-evaluation)
6. [C4 Diagrams Generation](#c4-diagrams)
7. [Complete Evaluation Workflow](#complete-workflow)

## Python Architecture Analysis

### Complete Python Project Analysis

```python
#!/usr/bin/env python3
"""
Complete architecture analysis for Python projects
"""

import ast
import json
from pathlib import Path
from typing import Dict, List, Set
from collections import defaultdict

def analyze_python_architecture(project_path: str):
    """Complete architecture analysis for Python project"""

    results = {
        'patterns': identify_patterns(project_path),
        'solid': analyze_solid_compliance(project_path),
        'coupling': analyze_coupling(project_path),
        'complexity': analyze_complexity(project_path),
        'dependencies': analyze_dependencies(project_path)
    }

    # Generate reports
    generate_architecture_report(results, f"{project_path}/reports/architecture.md")
    generate_metrics_dashboard(results, f"{project_path}/reports/metrics.html")

    return results

# Usage
if __name__ == "__main__":
    results = analyze_python_architecture("src/")
    print(f"Architecture Score: {results['score']}/100")
```

## JavaScript Analysis

### Node.js/Express Analysis

```javascript
// analyze-express-architecture.js
const fs = require('fs');
const path = require('path');

function analyzeExpressArchitecture(projectPath) {
    const results = {
        routes: [],
        middleware: [],
        controllers: [],
        services: [],
        models: []
    };

    // Analyze route structure
    const routesDir = path.join(projectPath, 'routes');
    if (fs.existsSync(routesDir)) {
        results.routes = analyzeRoutes(routesDir);
    }

    // Check for common issues
    results.issues = [];

    // Check for route handler complexity
    results.routes.forEach(route => {
        if (route.handlerComplexity > 10) {
            results.issues.push(`Complex route handler: ${route.path}`);
        }
    });

    return results;
}
```

## Go Analysis

### Go Project Architecture Analysis

```go
// analyze_architecture.go
package main

import (
    "go/ast"
    "go/parser"
    "go/token"
    "path/filepath"
)

type ArchitectureAnalysis struct {
    Packages     map[string]*PackageInfo
    Dependencies map[string][]string
    Patterns     []string
    Issues       []Issue
}

func AnalyzeGoArchitecture(projectPath string) (*ArchitectureAnalysis, error) {
    analysis := &ArchitectureAnalysis{
        Packages:     make(map[string]*PackageInfo),
        Dependencies: make(map[string][]string),
    }

    // Walk through all Go files
    err := filepath.Walk(projectPath, func(path string, info os.FileInfo, err error) error {
        if strings.HasSuffix(path, ".go") && !strings.Contains(path, "vendor") {
            pkg := analyzePackage(path)
            analysis.Packages[pkg.Name] = pkg
        }
        return nil
    })

    return analysis, nil
}
```

## SOLID Analysis

### Complete SOLID Analysis Example

```python
#!/usr/bin/env python3
"""
Complete SOLID principles analysis with reporting
"""

from solid_analyzer import SOLIDAnalyzer
from pathlib import Path
import json

def run_solid_analysis(project_path):
    """Run complete SOLID analysis on project"""

    analyzer = SOLIDAnalyzer()
    violations = analyzer.analyze_directory(project_path)

    # Generate detailed report
    report = generate_solid_report(violations)

    # Save reports
    with open('solid_report.md', 'w') as f:
        f.write(report['markdown'])

    # Calculate compliance score
    score = calculate_solid_score(violations)
    print(f"SOLID Compliance Score: {score:.1%}")

    return violations

# Example usage
if __name__ == "__main__":
    violations = run_solid_analysis("src/")
```

## Microservices Evaluation

### Microservices Architecture Assessment

```python
#!/usr/bin/env python3
"""
Evaluate microservices architecture
"""

import requests
import docker
import yaml
from typing import Dict, List

class MicroservicesEvaluator:
    def __init__(self, config_path: str):
        self.config = self.load_config(config_path)
        self.docker_client = docker.from_env()

    def evaluate(self) -> Dict:
        """Complete microservices evaluation"""

        results = {
            'services': self.discover_services(),
            'boundaries': self.analyze_boundaries(),
            'communication': self.analyze_communication(),
            'data_management': self.analyze_data_management()
        }

        # Calculate maturity score
        results['maturity_score'] = self.calculate_maturity(results)

        # Identify anti-patterns
        results['anti_patterns'] = self.detect_anti_patterns(results)

        return results

    def detect_anti_patterns(self, analysis: Dict) -> List[str]:
        """Detect microservices anti-patterns"""
        anti_patterns = []

        # Distributed monolith
        if analysis['boundaries']['coupling_score'] > 0.7:
            anti_patterns.append("Distributed Monolith - services too tightly coupled")

        # Shared database
        if analysis['boundaries']['shared_databases']:
            anti_patterns.append(f"Shared Database - {len(analysis['boundaries']['shared_databases'])} instances")

        return anti_patterns

# Usage
evaluator = MicroservicesEvaluator('microservices.yaml')
results = evaluator.evaluate()
print(f"Microservices Maturity: {results['maturity_score']}/10")
```

## C4 Diagrams

### Automated C4 Diagram Generation

```python
#!/usr/bin/env python3
"""
Generate C4 diagrams from codebase analysis
"""

from c4_generator import C4Generator

def generate_c4_from_analysis(project_path: str, output_dir: str):
    """Generate C4 diagrams from project analysis"""

    # Analyze project structure
    analysis = analyze_project_structure(project_path)

    # Initialize C4 generator
    c4 = C4Generator(analysis['system_name'])

    # Level 1: System Context
    for user in analysis['users']:
        c4.add_person(user['name'], user['description'])

    # Level 2: Containers
    for container in analysis['containers']:
        c4.add_container(
            container['name'],
            container['description'],
            container['technology']
        )

    # Generate all diagrams
    diagrams = {
        'context': c4.generate_context_diagram(),
        'container': c4.generate_container_diagram()
    }

    # Save diagrams
    for name, content in diagrams.items():
        with open(f"{output_dir}/{name}.puml", 'w') as f:
            f.write(content)

    return diagrams

# Usage
diagrams = generate_c4_from_analysis("./src", "./docs/architecture")
print(f"Generated {len(diagrams)} C4 diagrams")
```

## Complete Workflow

### End-to-End Architecture Evaluation

```python
#!/usr/bin/env python3
"""
Complete architecture evaluation workflow
"""

import os
from datetime import datetime
from pathlib import Path

class ArchitectureEvaluationWorkflow:
    def __init__(self, project_path: str, output_dir: str = "architecture-report"):
        self.project_path = Path(project_path)
        self.output_dir = Path(output_dir)
        self.timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

    def run_complete_evaluation(self):
        """Run complete architecture evaluation"""

        # Setup output directory
        report_dir = self.output_dir / self.timestamp
        report_dir.mkdir(parents=True, exist_ok=True)

        print("Starting Architecture Evaluation...")
        print("=" * 50)

        # Step 1: Pattern Identification
        print("\n[1/6] Identifying Architecture Patterns...")
        patterns = self.identify_patterns()

        # Step 2: SOLID Analysis
        print("[2/6] Analyzing SOLID Compliance...")
        solid_results = self.analyze_solid()

        # Step 3: Coupling & Cohesion
        print("[3/6] Measuring Coupling and Cohesion...")
        coupling_results = self.analyze_coupling()

        # Step 4: Quality Attributes
        print("[4/6] Evaluating Quality Attributes...")
        quality_results = self.evaluate_quality_attributes()

        # Step 5: Technical Debt
        print("[5/6] Quantifying Technical Debt...")
        debt_results = self.quantify_debt()

        # Step 6: Generate Reports
        print("[6/6] Generating Reports...")
        self.generate_reports({
            'patterns': patterns,
            'solid': solid_results,
            'coupling': coupling_results,
            'quality': quality_results,
            'debt': debt_results
        }, report_dir)

        print("\n" + "=" * 50)
        print("EVALUATION COMPLETE")
        print(f"Full report available at: {report_dir}")

        return report_dir

# Usage
workflow = ArchitectureEvaluationWorkflow("./src")
report_dir = workflow.run_complete_evaluation()
```

### GitHub Actions Integration

```yaml
# .github/workflows/architecture-fitness.yml
name: Architecture Fitness Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  architecture-fitness:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2

    - name: Setup Python
      uses: actions/setup-python@v2
      with:
        python-version: '3.9'

    - name: Run Architecture Analysis
      run: |
        python -m architecture_evaluator.analyze \
          --path . \
          --output reports/

    - name: Check Architecture Fitness
      run: |
        python -m architecture_evaluator.fitness \
          --config .architecture.yaml \
          --fail-on-violation

    - name: Upload Reports
      uses: actions/upload-artifact@v2
      if: always()
      with:
        name: architecture-reports
        path: reports/
```