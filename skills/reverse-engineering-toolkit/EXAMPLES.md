# Reverse Engineering Examples

## Example 1: Static Analysis with Python AST

### Goal
Parse Python code and extract all functions, classes, and imports.

### Implementation

```python
import ast
from pathlib import Path
from typing import Dict, List

class StaticAnalyzer:
    def analyze_file(self, filepath: Path) -> Dict:
        with open(filepath) as f:
            tree = ast.parse(f.read())

        return {
            'functions': self._extract_functions(tree),
            'classes': self._extract_classes(tree),
            'imports': self._extract_imports(tree),
        }

    def _extract_functions(self, tree: ast.AST) -> List[Dict]:
        functions = []
        for node in ast.walk(tree):
            if isinstance(node, ast.FunctionDef):
                functions.append({
                    'name': node.name,
                    'lineno': node.lineno,
                    'args': [arg.arg for arg in node.args.args],
                })
        return functions
```

## Example 2: Dynamic Tracing with strace

### Goal
Understand what files a program accesses.

### Usage

```bash
# Trace file operations
strace -e trace=open,openat,stat python script.py

# Save to file
strace -o trace.log -e trace=file ./program

# Analyze trace
grep "open" trace.log | cut -d'"' -f2 | sort | uniq
```

## Example 3: Dependency Graph Builder

### Goal
Visualize module dependencies.

### Implementation

```python
import ast
from pathlib import Path
import graphviz

class DependencyGraphBuilder:
    def analyze_project(self, root: Path):
        deps = {}
        for py_file in root.rglob('*.py'):
            module = self._get_module_name(py_file)
            deps[module] = self._extract_imports(py_file)
        return deps

    def visualize(self, deps, output='deps.png'):
        dot = graphviz.Digraph()
        for module, imports in deps.items():
            for imp in imports:
                dot.edge(module, imp)
        dot.render(output, format='png')
```

## Example 4: Pattern Detector

### Goal
Find Singleton pattern instances.

### Implementation

```python
class PatternDetector:
    def detect_singleton(self, tree: ast.AST):
        for node in ast.walk(tree):
            if isinstance(node, ast.ClassDef):
                has_instance = self._has_class_var(node, '_instance')
                has_get_instance = self._has_method(node, 'get_instance')
                if has_instance and has_get_instance:
                    print(f"Singleton detected: {node.name}")
```

## Example 5: Auto-Documentation Generator

### Goal
Generate Markdown API docs from code.

### Implementation

```python
class DocGenerator:
    def generate_markdown(self, analysis: Dict) -> str:
        md = ["# API Documentation\n"]
        for module, info in analysis.items():
            md.append(f"## {module}\n")
            for func in info['functions']:
                args = ', '.join(func['args'])
                md.append(f"### {func['name']}({args})\n")
        return ''.join(md)
```

## Real-World Use Cases

### Use Case 1: Legacy Migration
**Problem**: Migrate 100K LOC Python 2 codebase to Python 3
**Solution**: Static analysis to find Python 2 idioms, dependency graph to plan migration order

### Use Case 2: Security Audit
**Problem**: Audit third-party library for vulnerabilities
**Solution**: Dynamic tracing to see file/network access, static analysis for dangerous patterns

### Use Case 3: Onboarding
**Problem**: New developer needs to understand large codebase
**Solution**: Generate dependency graphs, extract design patterns, create architecture documentation
