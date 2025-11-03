# Implementation Patterns

Complete implementation patterns for codebase analysis.

**Parent:** [SKILL.md](./SKILL.md)

## Implementation Patterns

### Pattern 1: Quick Codebase Survey

Get high-level overview in minutes:

```bash
#!/bin/bash
# quick-survey.sh - 5-minute codebase overview

PROJECT_DIR=${1:-.}
OUTPUT_DIR="codebase-analysis"

mkdir -p "$OUTPUT_DIR"

echo "=== Quick Codebase Survey ==="
echo "Project: $PROJECT_DIR"
echo ""

# 1. Basic Statistics
echo "## Code Statistics" > "$OUTPUT_DIR/survey.md"
echo "" >> "$OUTPUT_DIR/survey.md"

if command -v tokei &> /dev/null; then
    echo "### Lines of Code" >> "$OUTPUT_DIR/survey.md"
    tokei "$PROJECT_DIR" --output json | jq -r '
        to_entries[] |
        select(.key != "Total") |
        "- **\(.key)**: \(.value.code) lines (\(.value.comments) comments)"
    ' >> "$OUTPUT_DIR/survey.md"
else
    # Fallback to cloc
    cloc "$PROJECT_DIR" --json | jq -r '
        to_entries[] |
        select(.key != "header" and .key != "SUM") |
        "- **\(.key)**: \(.value.code) lines"
    ' >> "$OUTPUT_DIR/survey.md"
fi

# 2. Directory Structure
echo "" >> "$OUTPUT_DIR/survey.md"
echo "### Directory Structure" >> "$OUTPUT_DIR/survey.md"
echo "\`\`\`" >> "$OUTPUT_DIR/survey.md"
tree -L 3 -d "$PROJECT_DIR" >> "$OUTPUT_DIR/survey.md"
echo "\`\`\`" >> "$OUTPUT_DIR/survey.md"

# 3. Technology Detection
echo "" >> "$OUTPUT_DIR/survey.md"
echo "### Technology Stack" >> "$OUTPUT_DIR/survey.md"
echo "" >> "$OUTPUT_DIR/survey.md"

# Languages
echo "**Languages:**" >> "$OUTPUT_DIR/survey.md"
find "$PROJECT_DIR" -type f -name "*.py" | head -1 && echo "- Python" >> "$OUTPUT_DIR/survey.md"
find "$PROJECT_DIR" -type f -name "*.js" | head -1 && echo "- JavaScript" >> "$OUTPUT_DIR/survey.md"
find "$PROJECT_DIR" -type f -name "*.ts" | head -1 && echo "- TypeScript" >> "$OUTPUT_DIR/survey.md"
find "$PROJECT_DIR" -type f -name "*.go" | head -1 && echo "- Go" >> "$OUTPUT_DIR/survey.md"
find "$PROJECT_DIR" -type f -name "*.rs" | head -1 && echo "- Rust" >> "$OUTPUT_DIR/survey.md"
find "$PROJECT_DIR" -type f -name "*.java" | head -1 && echo "- Java" >> "$OUTPUT_DIR/survey.md"

echo "" >> "$OUTPUT_DIR/survey.md"
echo "**Package Managers:**" >> "$OUTPUT_DIR/survey.md"
[ -f "$PROJECT_DIR/package.json" ] && echo "- npm/yarn (Node.js)" >> "$OUTPUT_DIR/survey.md"
[ -f "$PROJECT_DIR/requirements.txt" ] && echo "- pip (Python)" >> "$OUTPUT_DIR/survey.md"
[ -f "$PROJECT_DIR/Pipfile" ] && echo "- pipenv (Python)" >> "$OUTPUT_DIR/survey.md"
[ -f "$PROJECT_DIR/pyproject.toml" ] && echo "- poetry (Python)" >> "$OUTPUT_DIR/survey.md"
[ -f "$PROJECT_DIR/go.mod" ] && echo "- go modules" >> "$OUTPUT_DIR/survey.md"
[ -f "$PROJECT_DIR/Cargo.toml" ] && echo "- cargo (Rust)" >> "$OUTPUT_DIR/survey.md"
[ -f "$PROJECT_DIR/pom.xml" ] && echo "- maven (Java)" >> "$OUTPUT_DIR/survey.md"

# 4. Entry Points
echo "" >> "$OUTPUT_DIR/survey.md"
echo "### Entry Points" >> "$OUTPUT_DIR/survey.md"
echo "" >> "$OUTPUT_DIR/survey.md"

# Look for main functions, CLI scripts, server starts
grep -r "if __name__ == '__main__':" "$PROJECT_DIR" --include="*.py" | head -5 >> "$OUTPUT_DIR/survey.md"
grep -r "func main()" "$PROJECT_DIR" --include="*.go" | head -5 >> "$OUTPUT_DIR/survey.md"
grep -r "fn main()" "$PROJECT_DIR" --include="*.rs" | head -5 >> "$OUTPUT_DIR/survey.md"

# 5. Git Activity
echo "" >> "$OUTPUT_DIR/survey.md"
echo "### Recent Activity" >> "$OUTPUT_DIR/survey.md"
echo "" >> "$OUTPUT_DIR/survey.md"

cd "$PROJECT_DIR"
echo "**Total Commits:** $(git rev-list --count HEAD)" >> "$OUTPUT_DIR/survey.md"
echo "" >> "$OUTPUT_DIR/survey.md"
echo "**Top Contributors:**" >> "$OUTPUT_DIR/survey.md"
git shortlog -sn --all | head -10 >> "$OUTPUT_DIR/survey.md"

echo "" >> "$OUTPUT_DIR/survey.md"
echo "**Commit Activity (Last 30 Days):**" >> "$OUTPUT_DIR/survey.md"
git log --since="30 days ago" --oneline | wc -l | xargs echo "- Commits:" >> "$OUTPUT_DIR/survey.md"

echo ""
echo "=== Survey Complete ==="
echo "Report: $OUTPUT_DIR/survey.md"
```

### Pattern 2: Dependency Analysis

Map and visualize dependencies:

```python
# analyze_dependencies.py - Comprehensive dependency analysis

import ast
import importlib.util
import json
import os
import sys
from pathlib import Path
from collections import defaultdict
from typing import Dict, Set, List

class DependencyAnalyzer:
    """Analyze Python project dependencies"""

    def __init__(self, project_root: str):
        self.root = Path(project_root)
        self.internal_deps = defaultdict(set)  # module -> set of dependencies
        self.external_deps = defaultdict(set)  # module -> set of packages
        self.reverse_deps = defaultdict(set)   # module -> set of dependents
        self.entry_points = set()

    def analyze(self):
        """Run full dependency analysis"""
        print("Analyzing Python dependencies...")

        # Find all Python files
        py_files = list(self.root.rglob("*.py"))
        print(f"Found {len(py_files)} Python files")

        for py_file in py_files:
            self._analyze_file(py_file)

        return self._generate_report()

    def _analyze_file(self, filepath: Path):
        """Analyze single Python file"""
        try:
            with open(filepath) as f:
                tree = ast.parse(f.read(), filename=str(filepath))

            module_name = self._get_module_name(filepath)

            # Find imports
            for node in ast.walk(tree):
                if isinstance(node, ast.Import):
                    for alias in node.names:
                        self._add_dependency(module_name, alias.name)

                elif isinstance(node, ast.ImportFrom):
                    if node.module:
                        self._add_dependency(module_name, node.module)

            # Check if entry point
            if self._is_entry_point(tree):
                self.entry_points.add(module_name)

        except Exception as e:
            print(f"Error analyzing {filepath}: {e}")

    def _get_module_name(self, filepath: Path) -> str:
        """Convert file path to module name"""
        rel_path = filepath.relative_to(self.root)
        module_parts = list(rel_path.parts[:-1])

        # Add filename without .py extension
        if rel_path.name != "__init__.py":
            module_parts.append(rel_path.stem)

        return ".".join(module_parts) if module_parts else "__main__"

    def _add_dependency(self, module: str, dependency: str):
        """Add dependency relationship"""
        # First check if it's a standard library module
        package = dependency.split(".")[0]

        # Python 3.10+ has sys.stdlib_module_names
        if hasattr(sys, 'stdlib_module_names'):
            is_stdlib = package in sys.stdlib_module_names
        else:
            # Fallback: Check if module is in Python's standard library paths
            try:
                spec = importlib.util.find_spec(package)
                if spec and spec.origin:
                    # Standard library modules are typically in sys.prefix
                    is_stdlib = spec.origin.startswith(sys.prefix)
                else:
                    is_stdlib = False
            except (ImportError, ValueError):
                # If we can't find the module, assume external
                is_stdlib = False

        if is_stdlib:
            # Standard library - treat as external
            self.external_deps[module].add(package)
        else:
            # Check if internal or external third-party
            dep_path = self.root / dependency.replace(".", os.sep)

            if dep_path.exists() or (dep_path.parent / "__init__.py").exists():
                # Internal dependency
                self.internal_deps[module].add(dependency)
                self.reverse_deps[dependency].add(module)
            else:
                # External third-party dependency
                self.external_deps[module].add(package)

    def _is_entry_point(self, tree: ast.AST) -> bool:
        """Check if module is an entry point"""
        for node in ast.walk(tree):
            if isinstance(node, ast.If):
                if isinstance(node.test, ast.Compare):
                    # Look for if __name__ == "__main__"
                    if (isinstance(node.test.left, ast.Name) and
                        node.test.left.id == "__name__"):
                        return True
        return False

    def _generate_report(self) -> Dict:
        """Generate analysis report"""
        # Find circular dependencies
        circular = self._find_circular_deps()

        # Find orphan modules (no dependencies)
        all_modules = set(self.internal_deps.keys()) | set(self.reverse_deps.keys())
        orphans = {m for m in all_modules
                   if not self.internal_deps[m] and not self.reverse_deps[m]}

        # Calculate coupling metrics
        coupling = {
            module: {
                "afferent": len(self.reverse_deps[module]),  # Incoming
                "efferent": len(self.internal_deps[module]), # Outgoing
                "instability": self._calculate_instability(module)
            }
            for module in all_modules
        }

        return {
            "total_modules": len(all_modules),
            "entry_points": list(self.entry_points),
            "external_packages": sorted(set(
                pkg for deps in self.external_deps.values() for pkg in deps
            )),
            "circular_dependencies": circular,
            "orphan_modules": sorted(orphans),
            "coupling_metrics": coupling,
            "dependency_graph": {
                "internal": {k: list(v) for k, v in self.internal_deps.items()},
                "external": {k: list(v) for k, v in self.external_deps.items()}
            }
        }

    def _find_circular_deps(self) -> List[List[str]]:
        """Find circular dependency chains"""
        cycles = []
        visited = set()

        def dfs(node, path):
            if node in path:
                # Found cycle
                cycle_start = path.index(node)
                cycle = path[cycle_start:]
                if cycle not in cycles:
                    cycles.append(cycle)
                return

            if node in visited:
                return

            visited.add(node)
            for dep in self.internal_deps.get(node, []):
                dfs(dep, path + [node])

        for module in self.internal_deps:
            dfs(module, [])

        return cycles

    def _calculate_instability(self, module: str) -> float:
        """Calculate instability metric (0=stable, 1=unstable)"""
        afferent = len(self.reverse_deps[module])
        efferent = len(self.internal_deps[module])

        if afferent + efferent == 0:
            return 0.0

        return efferent / (afferent + efferent)

    def generate_graphviz(self, output_file: str = "dependencies.dot"):
        """Generate Graphviz visualization"""
        lines = ["digraph Dependencies {"]
        lines.append('  rankdir=LR;')
        lines.append('  node [shape=box];')

        # Add nodes
        for module in set(self.internal_deps.keys()) | set(self.reverse_deps.keys()):
            color = "green" if module in self.entry_points else "lightblue"
            lines.append(f'  "{module}" [fillcolor={color}, style=filled];')

        # Add edges
        for module, deps in self.internal_deps.items():
            for dep in deps:
                lines.append(f'  "{module}" -> "{dep}";')

        lines.append("}")

        with open(output_file, "w") as f:
            f.write("\n".join(lines))

        print(f"Graphviz file generated: {output_file}")
        print(f"Generate PNG: dot -Tpng {output_file} -o dependencies.png")


# JavaScript/TypeScript dependency analyzer
def analyze_js_dependencies(project_root: str) -> Dict:
    """Analyze JavaScript/TypeScript dependencies"""
    import subprocess

    print("Analyzing JavaScript/TypeScript dependencies...")

    # Use madge for dependency analysis
    result = subprocess.run(
        ["npx", "madge", "--json", project_root],
        capture_output=True,
        text=True
    )

    if result.returncode == 0:
        deps = json.loads(result.stdout)

        # Find circular dependencies
        circ_result = subprocess.run(
            ["npx", "madge", "--circular", "--json", project_root],
            capture_output=True,
            text=True
        )

        circular = json.loads(circ_result.stdout) if circ_result.returncode == 0 else []

        return {
            "dependencies": deps,
            "circular": circular,
            "total_modules": len(deps)
        }

    return {}


# Usage
if __name__ == "__main__":
    import sys

    project_path = sys.argv[1] if len(sys.argv) > 1 else "."

    # Python analysis
    if Path(project_path).glob("**/*.py"):
        analyzer = DependencyAnalyzer(project_path)
        report = analyzer.analyze()

        # Save report
        with open("dependency-analysis.json", "w") as f:
            json.dump(report, f, indent=2)

        print("\n=== Dependency Analysis Report ===")
        print(f"Total Modules: {report['total_modules']}")
        print(f"Entry Points: {len(report['entry_points'])}")
        print(f"External Packages: {len(report['external_packages'])}")
        print(f"Circular Dependencies: {len(report['circular_dependencies'])}")

        if report['circular_dependencies']:
            print("\n⚠️  Circular Dependencies Found:")
            for cycle in report['circular_dependencies']:
                print(f"  {' -> '.join(cycle)}")

        # Generate visualization
        analyzer.generate_graphviz()

    # JavaScript/TypeScript analysis
    if Path(project_path).glob("**/*.{js,ts,jsx,tsx}"):
        js_report = analyze_js_dependencies(project_path)
        if js_report:
            with open("js-dependency-analysis.json", "w") as f:
                json.dump(js_report, f, indent=2)
```

### Pattern 3: Complexity Analysis

Calculate code complexity metrics:

```python
# complexity_analyzer.py - Multi-metric complexity analysis

import radon.complexity as radon_cc
import radon.metrics as radon_mi
from radon.raw import analyze as radon_raw
from pathlib import Path
import json
from typing import Dict, List

class ComplexityAnalyzer:
    """Analyze code complexity metrics"""

    def __init__(self, project_root: str):
        self.root = Path(project_root)

    def analyze_python(self) -> Dict:
        """Analyze Python code complexity"""
        results = {
            "files": [],
            "summary": {
                "total_files": 0,
                "total_functions": 0,
                "avg_complexity": 0,
                "max_complexity": 0,
                "high_complexity_functions": []
            }
        }

        py_files = list(self.root.rglob("*.py"))
        total_complexity = 0
        total_functions = 0

        for py_file in py_files:
            if self._should_skip(py_file):
                continue

            try:
                file_results = self._analyze_python_file(py_file)
                results["files"].append(file_results)

                for func in file_results["functions"]:
                    total_complexity += func["complexity"]
                    total_functions += 1

                    if func["complexity"] > 10:
                        results["summary"]["high_complexity_functions"].append({
                            "file": str(py_file.relative_to(self.root)),
                            "function": func["name"],
                            "complexity": func["complexity"]
                        })

            except Exception as e:
                print(f"Error analyzing {py_file}: {e}")

        results["summary"]["total_files"] = len(results["files"])
        results["summary"]["total_functions"] = total_functions
        results["summary"]["avg_complexity"] = (
            total_complexity / total_functions if total_functions > 0 else 0
        )
        results["summary"]["max_complexity"] = max(
            (f["complexity"] for file_res in results["files"]
             for f in file_res["functions"]),
            default=0
        )

        return results

    def _analyze_python_file(self, filepath: Path) -> Dict:
        """Analyze single Python file"""
        with open(filepath) as f:
            code = f.read()

        # Cyclomatic complexity
        cc_results = radon_cc.cc_visit(code)

        # Maintainability index
        mi_score = radon_mi.mi_visit(code, multi=True)

        # Raw metrics (LOC, comments, etc.)
        raw = radon_raw(code)

        functions = []
        for block in cc_results:
            functions.append({
                "name": block.name,
                "complexity": block.complexity,
                "line_start": block.lineno,
                "rank": self._complexity_rank(block.complexity)
            })

        return {
            "path": str(filepath.relative_to(self.root)),
            "maintainability_index": mi_score,
            "maintainability_rank": self._mi_rank(mi_score),
            "lines_of_code": raw.loc,
            "logical_lines": raw.lloc,
            "comments": raw.comments,
            "functions": functions
        }

    def _complexity_rank(self, complexity: int) -> str:
        """Get complexity rank (A=best, F=worst)"""
        if complexity <= 5:
            return "A"
        elif complexity <= 10:
            return "B"
        elif complexity <= 20:
            return "C"
        elif complexity <= 30:
            return "D"
        elif complexity <= 40:
            return "E"
        else:
            return "F"

    def _mi_rank(self, mi: float) -> str:
        """Get maintainability index rank"""
        if mi >= 85:
            return "A"
        elif mi >= 65:
            return "B"
        elif mi >= 50:
            return "C"
        else:
            return "D"

    def _should_skip(self, filepath: Path) -> bool:
        """Check if file should be skipped"""
        skip_patterns = [
            "node_modules", "__pycache__", ".git", "venv",
            "dist", "build", ".pytest_cache", ".tox"
        ]
        return any(pattern in str(filepath) for pattern in skip_patterns)

    def generate_complexity_report(self, results: Dict, output_file: str):
        """Generate human-readable complexity report"""
        report = []
        report.append("# Code Complexity Report\n")

        # Summary
        summary = results["summary"]
        report.append("## Summary\n")
        report.append(f"- **Total Files Analyzed:** {summary['total_files']}")
        report.append(f"- **Total Functions:** {summary['total_functions']}")
        report.append(f"- **Average Complexity:** {summary['avg_complexity']:.2f}")
        report.append(f"- **Maximum Complexity:** {summary['max_complexity']}")
        report.append("")

        # High complexity functions
        if summary["high_complexity_functions"]:
            report.append("## High Complexity Functions (>10)\n")
            report.append("These functions should be considered for refactoring:\n")

            # Sort by complexity descending
            high_complexity = sorted(
                summary["high_complexity_functions"],
                key=lambda x: x["complexity"],
                reverse=True
            )

            for func in high_complexity[:20]:  # Top 20
                report.append(
                    f"- **{func['function']}** ({func['file']}): "
                    f"Complexity {func['complexity']}"
                )
            report.append("")

        # Maintainability issues
        report.append("## Maintainability Issues\n")
        low_mi = [
            f for f in results["files"]
            if f["maintainability_index"] < 65
        ]

        if low_mi:
            report.append("Files with low maintainability index (<65):\n")
            for file_info in sorted(low_mi, key=lambda x: x["maintainability_index"]):
                report.append(
                    f"- **{file_info['path']}**: "
                    f"MI {file_info['maintainability_index']:.2f} "
                    f"(Rank {file_info['maintainability_rank']})"
                )
        else:
            report.append("✅ No major maintainability issues found!")

        report.append("")

        # Recommendations
        report.append("## Recommendations\n")
        report.append("1. **Refactor high complexity functions** - "
                     "Functions with complexity >10 are harder to test and maintain")
        report.append("2. **Improve low MI files** - "
                     "Files with MI <65 should be simplified")
        report.append("3. **Add tests** - High complexity code needs comprehensive tests")
        report.append("4. **Extract methods** - Break down large functions into smaller ones")

        # Write report
        with open(output_file, "w") as f:
            f.write("\n".join(report))

        print(f"Complexity report generated: {output_file}")


# JavaScript complexity analysis
def analyze_js_complexity(project_root: str) -> Dict:
    """Analyze JavaScript/TypeScript complexity"""
    import subprocess

    print("Analyzing JavaScript complexity...")

    # Use complexity-report (escomplex)
    try:
        result = subprocess.run(
            ["npx", "cr", project_root, "--format", "json"],
            capture_output=True,
            text=True
        )

        if result.returncode == 0:
            return json.loads(result.stdout)
    except Exception as e:
        print(f"JavaScript complexity analysis failed: {e}")

    return {}


# Usage
if __name__ == "__main__":
    import sys

    project_path = sys.argv[1] if len(sys.argv) > 1 else "."

    # Python complexity
    if list(Path(project_path).rglob("*.py")):
        analyzer = ComplexityAnalyzer(project_path)
        results = analyzer.analyze_python()

        # Save JSON results
        with open("complexity-analysis.json", "w") as f:
            json.dump(results, f, indent=2)

        # Generate report
        analyzer.generate_complexity_report(results, "complexity-report.md")

        print("\n=== Complexity Analysis Complete ===")
        print(f"Average Complexity: {results['summary']['avg_complexity']:.2f}")
        print(f"High Complexity Functions: "
              f"{len(results['summary']['high_complexity_functions'])}")

    # JavaScript complexity
    if list(Path(project_path).glob("**/*.{js,ts}")):
        js_results = analyze_js_complexity(project_path)
        if js_results:
            with open("js-complexity-analysis.json", "w") as f:
                json.dump(js_results, f, indent=2)
```

### Pattern 4: Entry Point Discovery

Automatically identify application entry points:

```python
# entry_point_finder.py - Find all ways to run the application

import ast
import importlib.util
import json
import re
from pathlib import Path
from typing import Dict, List, Set

class EntryPointFinder:
    """Find all entry points in a codebase"""

    def __init__(self, project_root: str):
        self.root = Path(project_root)
        self.entry_points = {
            "main_functions": [],
            "cli_commands": [],
            "api_endpoints": [],
            "event_handlers": [],
            "scripts": [],
            "docker_entrypoints": [],
            "systemd_services": []
        }

    def find_all(self) -> Dict:
        """Find all types of entry points"""
        self._find_python_main()
        self._find_cli_commands()
        self._find_api_endpoints()
        self._find_scripts()
        self._find_docker_entrypoints()
        self._find_config_entries()

        return self.entry_points

    def _find_python_main(self):
        """Find Python main functions"""
        for py_file in self.root.rglob("*.py"):
            try:
                with open(py_file) as f:
                    tree = ast.parse(f.read())

                for node in ast.walk(tree):
                    if isinstance(node, ast.If):
                        # Look for if __name__ == "__main__"
                        if self._is_main_guard(node):
                            self.entry_points["main_functions"].append({
                                "file": str(py_file.relative_to(self.root)),
                                "type": "Python main"
                            })
                            break

            except Exception:
                pass

    def _is_main_guard(self, node: ast.If) -> bool:
        """Check if node is __name__ == '__main__' guard"""
        if not isinstance(node.test, ast.Compare):
            return False

        test = node.test
        if isinstance(test.left, ast.Name) and test.left.id == "__name__":
            for comparator in test.comparators:
                if isinstance(comparator, ast.Constant):
                    if comparator.value == "__main__":
                        return True
        return False

    def _find_cli_commands(self):
        """Find CLI command definitions"""
        # Click commands
        for py_file in self.root.rglob("*.py"):
            try:
                with open(py_file) as f:
                    content = f.read()

                # Look for Click decorators
                click_commands = re.findall(
                    r'@click\.(command|group)\(["\'](\w+)["\']',
                    content
                )

                for cmd_type, cmd_name in click_commands:
                    self.entry_points["cli_commands"].append({
                        "file": str(py_file.relative_to(self.root)),
                        "command": cmd_name,
                        "type": "Click CLI",
                        "framework": "click"
                    })

                # Look for argparse
                if "ArgumentParser" in content:
                    self.entry_points["cli_commands"].append({
                        "file": str(py_file.relative_to(self.root)),
                        "type": "argparse CLI",
                        "framework": "argparse"
                    })

            except Exception:
                pass

        # package.json scripts
        package_json = self.root / "package.json"
        if package_json.exists():
            try:
                with open(package_json) as f:
                    data = json.load(f)

                if "scripts" in data:
                    for script_name, script_cmd in data["scripts"].items():
                        self.entry_points["scripts"].append({
                            "name": script_name,
                            "command": script_cmd,
                            "type": "npm script"
                        })

                if "bin" in data:
                    for bin_name, bin_path in data["bin"].items():
                        self.entry_points["cli_commands"].append({
                            "name": bin_name,
                            "file": bin_path,
                            "type": "npm binary",
                            "framework": "node"
                        })

            except Exception:
                pass

    def _find_api_endpoints(self):
        """Find API endpoint definitions"""
        # Flask routes
        for py_file in self.root.rglob("*.py"):
            try:
                with open(py_file) as f:
                    content = f.read()

                # Flask routes
                flask_routes = re.findall(
                    r'@app\.route\(["\']([^"\']+)["\']',
                    content
                )
                for route in flask_routes:
                    self.entry_points["api_endpoints"].append({
                        "file": str(py_file.relative_to(self.root)),
                        "path": route,
                        "framework": "Flask"
                    })

                # FastAPI routes
                fastapi_routes = re.findall(
                    r'@app\.(get|post|put|delete|patch)\(["\']([^"\']+)["\']',
                    content
                )
                for method, route in fastapi_routes:
                    self.entry_points["api_endpoints"].append({
                        "file": str(py_file.relative_to(self.root)),
                        "method": method.upper(),
                        "path": route,
                        "framework": "FastAPI"
                    })

            except Exception:
                pass

        # Express.js routes
        for js_file in self.root.rglob("*.js"):
            try:
                with open(js_file) as f:
                    content = f.read()

                express_routes = re.findall(
                    r'app\.(get|post|put|delete|patch)\(["\']([^"\']+)["\']',
                    content
                )
                for method, route in express_routes:
                    self.entry_points["api_endpoints"].append({
                        "file": str(js_file.relative_to(self.root)),
                        "method": method.upper(),
                        "path": route,
                        "framework": "Express.js"
                    })

            except Exception:
                pass

    def _find_scripts(self):
        """Find executable scripts"""
        # Shell scripts
        for script in self.root.rglob("*.sh"):
            if script.stat().st_mode & 0o111:  # Executable
                self.entry_points["scripts"].append({
                    "file": str(script.relative_to(self.root)),
                    "type": "Shell script"
                })

        # Makefile targets
        makefile = self.root / "Makefile"
        if makefile.exists():
            try:
                with open(makefile) as f:
                    content = f.read()

                targets = re.findall(r'^([a-zA-Z0-9_-]+):', content, re.MULTILINE)
                for target in targets:
                    if not target.startswith('.'):  # Skip special targets
                        self.entry_points["scripts"].append({
                            "name": target,
                            "type": "Makefile target"
                        })

            except Exception:
                pass

    def _find_docker_entrypoints(self):
        """Find Docker entrypoints"""
        for dockerfile in self.root.rglob("*Dockerfile*"):
            try:
                with open(dockerfile) as f:
                    content = f.read()

                # Find ENTRYPOINT and CMD
                entrypoints = re.findall(
                    r'ENTRYPOINT\s+\[(.*?)\]|ENTRYPOINT\s+(.+)',
                    content
                )
                cmds = re.findall(
                    r'CMD\s+\[(.*?)\]|CMD\s+(.+)',
                    content
                )

                for ep in entrypoints:
                    cmd = ep[0] if ep[0] else ep[1]
                    self.entry_points["docker_entrypoints"].append({
                        "file": str(dockerfile.relative_to(self.root)),
                        "entrypoint": cmd.strip(),
                        "type": "Docker ENTRYPOINT"
                    })

                for cmd in cmds:
                    cmd_str = cmd[0] if cmd[0] else cmd[1]
                    self.entry_points["docker_entrypoints"].append({
                        "file": str(dockerfile.relative_to(self.root)),
                        "command": cmd_str.strip(),
                        "type": "Docker CMD"
                    })

            except Exception:
                pass

    def _find_config_entries(self):
        """Find configuration-based entry points"""
        # setup.py entry points
        setup_py = self.root / "setup.py"
        if setup_py.exists():
            try:
                with open(setup_py) as f:
                    content = f.read()

                # Look for console_scripts
                console_scripts = re.findall(
                    r'["\']console_scripts["\']\s*:\s*\[(.*?)\]',
                    content,
                    re.DOTALL
                )
                for scripts in console_scripts:
                    script_entries = re.findall(
                        r'["\']([^"\']+)\s*=\s*([^"\']+)["\']',
                        scripts
                    )
                    for name, target in script_entries:
                        self.entry_points["cli_commands"].append({
                            "name": name.strip(),
                            "target": target.strip(),
                            "type": "setuptools console_script"
                        })

            except Exception:
                pass

    def generate_entry_point_guide(self, output_file: str):
        """Generate guide for running the application"""
        guide = []
        guide.append("# Application Entry Points\n")
        guide.append("This guide shows all the ways to run and interact with this application.\n")

        # Main entry points
        if self.entry_points["main_functions"]:
            guide.append("## Main Entry Points\n")
            for entry in self.entry_points["main_functions"]:
                guide.append(f"### {entry['file']}\n")
                guide.append(f"Run with: `python {entry['file']}`\n")

        # CLI Commands
        if self.entry_points["cli_commands"]:
            guide.append("## Command-Line Interface\n")
            for cmd in self.entry_points["cli_commands"]:
                if "command" in cmd:
                    guide.append(f"- **{cmd['command']}** ({cmd['framework']})")
                elif "name" in cmd:
                    guide.append(f"- **{cmd['name']}** - {cmd.get('type', 'CLI')}")
            guide.append("")

        # API Endpoints
        if self.entry_points["api_endpoints"]:
            guide.append("## API Endpoints\n")
            framework_groups = {}
            for endpoint in self.entry_points["api_endpoints"]:
                fw = endpoint["framework"]
                if fw not in framework_groups:
                    framework_groups[fw] = []
                framework_groups[fw].append(endpoint)

            for framework, endpoints in framework_groups.items():
                guide.append(f"### {framework} Routes\n")
                for ep in endpoints:
                    method = ep.get("method", "GET")
                    guide.append(f"- `{method} {ep['path']}` ({ep['file']})")
                guide.append("")

        # Scripts
        if self.entry_points["scripts"]:
            guide.append("## Available Scripts\n")
            for script in self.entry_points["scripts"]:
                if "file" in script:
                    guide.append(f"- `./{script['file']}`")
                elif "name" in script:
                    if script["type"] == "npm script":
                        guide.append(f"- `npm run {script['name']}` - {script.get('command', '')}")
                    elif script["type"] == "Makefile target":
                        guide.append(f"- `make {script['name']}`")
            guide.append("")

        # Docker
        if self.entry_points["docker_entrypoints"]:
            guide.append("## Docker\n")
            for docker in self.entry_points["docker_entrypoints"]:
                guide.append(f"- {docker['type']}: `{docker.get('entrypoint') or docker.get('command')}`")
            guide.append("")

        # Quick Start
        guide.append("## Quick Start\n")
        guide.append("1. Install dependencies (see README)")
        if self.entry_points["docker_entrypoints"]:
            guide.append("2. Run with Docker: `docker build -t app . && docker run app`")
        elif self.entry_points["main_functions"]:
            main = self.entry_points["main_functions"][0]
            guide.append(f"2. Run: `python {main['file']}`")
        elif self.entry_points["scripts"]:
            script = self.entry_points["scripts"][0]
            if "file" in script:
                guide.append(f"2. Run: `./{script['file']}`")
            elif script["type"] == "npm script":
                guide.append(f"2. Run: `npm run {script['name']}`")

        with open(output_file, "w") as f:
            f.write("\n".join(guide))

        print(f"Entry point guide generated: {output_file}")


# Usage
if __name__ == "__main__":
    import sys

    project_path = sys.argv[1] if len(sys.argv) > 1 else "."

    finder = EntryPointFinder(project_path)
    entry_points = finder.find_all()

    # Save JSON
    with open("entry-points.json", "w") as f:
        json.dump(entry_points, f, indent=2)

    # Generate guide
    finder.generate_entry_point_guide("ENTRY-POINTS.md")

    print("\n=== Entry Points Found ===")
    print(f"Main Functions: {len(entry_points['main_functions'])}")
    print(f"CLI Commands: {len(entry_points['cli_commands'])}")
    print(f"API Endpoints: {len(entry_points['api_endpoints'])}")
    print(f"Scripts: {len(entry_points['scripts'])}")
    print(f"Docker Entrypoints: {len(entry_points['docker_entrypoints'])}")
```

### Pattern 5: Architecture Documentation Generator

Auto-generate architecture documentation:

```python
# arch_doc_generator.py - Generate comprehensive architecture documentation

import json
from pathlib import Path
from typing import Dict, List
from datetime import datetime

class ArchitectureDocGenerator:
    """Generate architecture documentation from analysis results"""

    def __init__(self, project_root: str):
        self.root = Path(project_root)
        self.project_name = self.root.name

    def generate_full_documentation(
        self,
        survey_data: Dict,
        dependency_data: Dict,
        complexity_data: Dict,
        entry_point_data: Dict
    ) -> str:
        """Generate complete architecture documentation"""

        doc = []

        # Title and metadata
        doc.append(f"# {self.project_name} - Architecture Documentation\n")
        doc.append(f"*Auto-generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}*\n")
        doc.append("---\n")

        # Executive Summary
        doc.append("## Executive Summary\n")
        doc.append(self._generate_executive_summary(
            survey_data, dependency_data, complexity_data
        ))

        # Technology Stack
        doc.append("## Technology Stack\n")
        doc.append(self._generate_tech_stack(survey_data))

        # Architecture Overview
        doc.append("## Architecture Overview\n")
        doc.append(self._generate_architecture_overview(dependency_data))

        # Component Breakdown
        doc.append("## Component Breakdown\n")
        doc.append(self._generate_component_breakdown(dependency_data))

        # Entry Points
        doc.append("## Entry Points\n")
        doc.append(self._generate_entry_points_section(entry_point_data))

        # Code Quality Metrics
        doc.append("## Code Quality Metrics\n")
        doc.append(self._generate_quality_metrics(complexity_data))

        # Dependency Graph
        doc.append("## Dependency Analysis\n")
        doc.append(self._generate_dependency_analysis(dependency_data))

        # Architecture Patterns
        doc.append("## Identified Patterns\n")
        doc.append(self._identify_patterns(dependency_data, entry_point_data))

        # Technical Debt
        doc.append("## Technical Debt\n")
        doc.append(self._identify_tech_debt(complexity_data, dependency_data))

        # Recommendations
        doc.append("## Recommendations\n")
        doc.append(self._generate_recommendations(
            complexity_data, dependency_data
        ))

        # Appendix
        doc.append("## Appendix\n")
        doc.append("### How to Run\n")
        doc.append(self._generate_how_to_run(entry_point_data))

        return "\n".join(doc)

    def _generate_executive_summary(
        self, survey: Dict, deps: Dict, complexity: Dict
    ) -> str:
        """Generate executive summary"""
        lines = []

        # Project stats
        total_loc = sum(lang.get("code", 0) for lang in survey.get("languages", {}).values())
        lines.append(f"**Project Size:** ~{total_loc:,} lines of code")

        # Primary languages
        languages = list(survey.get("languages", {}).keys())[:3]
        lines.append(f"**Primary Languages:** {', '.join(languages)}")

        # Complexity assessment
        avg_complexity = complexity.get("summary", {}).get("avg_complexity", 0)
        if avg_complexity < 5:
            complexity_rating = "Low (Easy to maintain)"
        elif avg_complexity < 10:
            complexity_rating = "Moderate"
        else:
            complexity_rating = "High (Consider refactoring)"

        lines.append(f"**Complexity Rating:** {complexity_rating}")

        # Architecture type
        if deps.get("external_packages", []):
            lines.append(f"**External Dependencies:** {len(deps['external_packages'])} packages")

        lines.append("")
        lines.append("This document provides a comprehensive overview of the system architecture, "
                    "components, dependencies, and code quality metrics.")
        lines.append("")

        return "\n".join(lines)

    def _generate_tech_stack(self, survey: Dict) -> str:
        """Generate technology stack section"""
        lines = []

        # Languages
        lines.append("### Languages\n")
        for lang, stats in survey.get("languages", {}).items():
            lines.append(f"- **{lang}**: {stats.get('code', 0):,} lines")
        lines.append("")

        # Frameworks (detected from dependencies)
        lines.append("### Frameworks & Libraries\n")
        lines.append("*(Detected from package manifests)*\n")

        # TODO: Parse package.json, requirements.txt, etc.
        lines.append("See dependency analysis for full list.\n")

        # Build tools
        lines.append("### Build Tools\n")
        build_tools = []
        if (self.root / "package.json").exists():
            build_tools.append("npm/yarn")
        if (self.root / "Makefile").exists():
            build_tools.append("Make")
        if (self.root / "Dockerfile").exists():
            build_tools.append("Docker")

        if build_tools:
            for tool in build_tools:
                lines.append(f"- {tool}")
        else:
            lines.append("*No build tools detected*")

        lines.append("")
        return "\n".join(lines)

    def _generate_architecture_overview(self, deps: Dict) -> str:
        """Generate architecture overview"""
        lines = []

        total_modules = deps.get("total_modules", 0)
        entry_points = deps.get("entry_points", [])

        lines.append(f"The system consists of **{total_modules} modules** "
                    f"with **{len(entry_points)} entry point(s)**.\n")

        # Architectural style detection
        if any("api" in ep.lower() or "endpoint" in ep.lower() for ep in entry_points):
            lines.append("**Architectural Style:** Web API / Service-Oriented")
        elif any("cli" in ep.lower() or "command" in ep.lower() for ep in entry_points):
            lines.append("**Architectural Style:** Command-Line Application")
        else:
            lines.append("**Architectural Style:** Library / Framework")

        lines.append("")

        # Module organization
        lines.append("### Module Organization\n")
        lines.append("```")
        lines.append(f"Total Modules: {total_modules}")
        if entry_points:
            lines.append(f"Entry Points: {', '.join(entry_points[:5])}")
        lines.append("```\n")

        return "\n".join(lines)

    def _generate_component_breakdown(self, deps: Dict) -> str:
        """Generate component breakdown"""
        lines = []

        # Group modules by top-level package
        graph = deps.get("dependency_graph", {}).get("internal", {})

        components = {}
        for module in graph.keys():
            top_level = module.split(".")[0]
            if top_level not in components:
                components[top_level] = []
            components[top_level].append(module)

        for component, modules in sorted(components.items()):
            lines.append(f"### {component}\n")
            lines.append(f"Contains {len(modules)} module(s)\n")

            # Show submodules
            if len(modules) <= 10:
                for mod in sorted(modules):
                    lines.append(f"- `{mod}`")
            else:
                for mod in sorted(modules)[:5]:
                    lines.append(f"- `{mod}`")
                lines.append(f"- *...and {len(modules) - 5} more*")

            lines.append("")

        return "\n".join(lines)

    def _generate_entry_points_section(self, entry_points: Dict) -> str:
        """Generate entry points section"""
        lines = []

        if entry_points.get("main_functions"):
            lines.append("### Main Functions\n")
            for entry in entry_points["main_functions"]:
                lines.append(f"- `{entry['file']}`")
            lines.append("")

        if entry_points.get("api_endpoints"):
            lines.append("### API Endpoints\n")
            for endpoint in entry_points["api_endpoints"][:10]:
                method = endpoint.get("method", "")
                path = endpoint.get("path", "")
                lines.append(f"- `{method} {path}`")
            if len(entry_points["api_endpoints"]) > 10:
                lines.append(f"- *...and {len(entry_points['api_endpoints']) - 10} more*")
            lines.append("")

        if entry_points.get("cli_commands"):
            lines.append("### CLI Commands\n")
            for cmd in entry_points["cli_commands"]:
                name = cmd.get("name") or cmd.get("command")
                lines.append(f"- `{name}`")
            lines.append("")

        return "\n".join(lines)

    def _generate_quality_metrics(self, complexity: Dict) -> str:
        """Generate quality metrics section"""
        lines = []

        summary = complexity.get("summary", {})

        lines.append("### Complexity Metrics\n")
        lines.append(f"- **Average Cyclomatic Complexity:** {summary.get('avg_complexity', 0):.2f}")
        lines.append(f"- **Maximum Complexity:** {summary.get('max_complexity', 0)}")
        lines.append(f"- **High Complexity Functions:** "
                    f"{len(summary.get('high_complexity_functions', []))}")
        lines.append("")

        # Show top complex functions
        if summary.get("high_complexity_functions"):
            lines.append("### Most Complex Functions\n")
            high = sorted(
                summary["high_complexity_functions"],
                key=lambda x: x["complexity"],
                reverse=True
            )[:5]

            for func in high:
                lines.append(
                    f"- **{func['function']}** "
                    f"(Complexity: {func['complexity']}) "
                    f"in `{func['file']}`"
                )
            lines.append("")

        return "\n".join(lines)

    def _generate_dependency_analysis(self, deps: Dict) -> str:
        """Generate dependency analysis"""
        lines = []

        # External dependencies
        ext_deps = deps.get("external_packages", [])
        if ext_deps:
            lines.append("### External Dependencies\n")
            lines.append(f"Total: {len(ext_deps)} packages\n")

            for pkg in sorted(ext_deps)[:20]:
                lines.append(f"- `{pkg}`")

            if len(ext_deps) > 20:
                lines.append(f"- *...and {len(ext_deps) - 20} more*")

            lines.append("")

        # Circular dependencies
        circular = deps.get("circular_dependencies", [])
        if circular:
            lines.append("### ⚠️ Circular Dependencies\n")
            lines.append(f"Found {len(circular)} circular dependency chain(s):\n")

            for cycle in circular[:5]:
                lines.append(f"- {' → '.join(cycle)}")

            lines.append("\n**Impact:** Circular dependencies can make code harder to test and maintain.\n")

        return "\n".join(lines)

    def _identify_patterns(self, deps: Dict, entry_points: Dict) -> str:
        """Identify architectural patterns"""
        lines = []

        patterns = []

        # MVC pattern
        graph = deps.get("dependency_graph", {}).get("internal", {})
        has_models = any("model" in mod.lower() for mod in graph.keys())
        has_views = any("view" in mod.lower() for mod in graph.keys())
        has_controllers = any("controller" in mod.lower() for mod in graph.keys())

        if has_models and has_views and has_controllers:
            patterns.append("**MVC (Model-View-Controller)**")

        # API pattern
        if entry_points.get("api_endpoints"):
            patterns.append("**REST API**")

        # CLI pattern
        if entry_points.get("cli_commands"):
            patterns.append("**Command-Line Interface**")

        # Layered architecture
        has_layers = any(
            layer in " ".join(graph.keys()).lower()
            for layer in ["service", "repository", "controller"]
        )
        if has_layers:
            patterns.append("**Layered Architecture**")

        if patterns:
            lines.append("Detected architectural patterns:\n")
            for pattern in patterns:
                lines.append(f"- {pattern}")
        else:
            lines.append("*No clear architectural patterns detected*")

        lines.append("")
        return "\n".join(lines)

    def _identify_tech_debt(self, complexity: Dict, deps: Dict) -> str:
        """Identify technical debt"""
        lines = []

        debt_items = []

        # High complexity
        high_complexity = len(complexity.get("summary", {}).get("high_complexity_functions", []))
        if high_complexity > 5:
            debt_items.append(
                f"- **{high_complexity} high-complexity functions** - "
                "Consider refactoring"
            )

        # Circular dependencies
        circular = len(deps.get("circular_dependencies", []))
        if circular > 0:
            debt_items.append(
                f"- **{circular} circular dependency chains** - "
                "Should be resolved"
            )

        # Low maintainability
        low_mi_files = [
            f for f in complexity.get("files", [])
            if f.get("maintainability_index", 100) < 65
        ]
        if low_mi_files:
            debt_items.append(
                f"- **{len(low_mi_files)} files with low maintainability** - "
                "Need improvement"
            )

        if debt_items:
            lines.append("Identified technical debt:\n")
            lines.extend(debt_items)
        else:
            lines.append("✅ No major technical debt identified!")

        lines.append("")
        return "\n".join(lines)

    def _generate_recommendations(self, complexity: Dict, deps: Dict) -> str:
        """Generate actionable recommendations"""
        lines = []

        recommendations = []

        # Complexity recommendations
        high_complexity = complexity.get("summary", {}).get("high_complexity_functions", [])
        if high_complexity:
            recommendations.append(
                "1. **Refactor high-complexity functions** - "
                f"Target the {len(high_complexity)} functions with complexity >10"
            )

        # Circular dependency recommendations
        if deps.get("circular_dependencies"):
            recommendations.append(
                "2. **Resolve circular dependencies** - "
                "These make testing and maintenance difficult"
            )

        # Testing recommendations
        recommendations.append(
            "3. **Increase test coverage** - "
            "Especially for high-complexity code"
        )

        # Documentation recommendations
        recommendations.append(
            "4. **Add inline documentation** - "
            "Document complex functions and public APIs"
        )

        # Dependency recommendations
        ext_deps = len(deps.get("external_packages", []))
        if ext_deps > 50:
            recommendations.append(
                f"5. **Review dependencies** - "
                f"{ext_deps} external packages may be excessive"
            )

        for rec in recommendations:
            lines.append(rec)

        lines.append("")
        return "\n".join(lines)

    def _generate_how_to_run(self, entry_points: Dict) -> str:
        """Generate how to run section"""
        lines = []

        if entry_points.get("docker_entrypoints"):
            lines.append("### Docker\n")
            lines.append("```bash")
            lines.append("docker build -t app .")
            lines.append("docker run app")
            lines.append("```\n")

        if entry_points.get("main_functions"):
            lines.append("### Python\n")
            lines.append("```bash")
            main = entry_points["main_functions"][0]
            lines.append(f"python {main['file']}")
            lines.append("```\n")

        if entry_points.get("scripts"):
            lines.append("### Scripts\n")
            for script in entry_points["scripts"][:5]:
                if script["type"] == "npm script":
                    lines.append(f"- `npm run {script['name']}`")
                elif script["type"] == "Makefile target":
                    lines.append(f"- `make {script['name']}`")
                elif "file" in script:
                    lines.append(f"- `./{script['file']}`")
            lines.append("")

        return "\n".join(lines)


# Usage
if __name__ == "__main__":
    import sys

    project_path = sys.argv[1] if len(sys.argv) > 1 else "."

    # Load analysis results
    try:
        with open("codebase-analysis/survey.md") as f:
            survey_data = {}  # Parse markdown or load JSON

        with open("dependency-analysis.json") as f:
            dependency_data = json.load(f)

        with open("complexity-analysis.json") as f:
            complexity_data = json.load(f)

        with open("entry-points.json") as f:
            entry_point_data = json.load(f)

        # Generate documentation
        generator = ArchitectureDocGenerator(project_path)
        documentation = generator.generate_full_documentation(
            survey_data,
            dependency_data,
            complexity_data,
            entry_point_data
        )

        # Save
        with open("ARCHITECTURE.md", "w") as f:
            f.write(documentation)

        print("Architecture documentation generated: ARCHITECTURE.md")

    except FileNotFoundError as e:
        print(f"Error: {e}")
        print("Run analysis scripts first to generate input data")
```

### Pattern 6: Git History Analysis

Analyze Git history for insights:

```bash
#!/bin/bash
# git-history-analyzer.sh - Analyze Git history for codebase insights

PROJECT_DIR=${1:-.}
OUTPUT_FILE="git-analysis.md"

cd "$PROJECT_DIR" || exit 1

echo "# Git History Analysis" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "*Generated on $(date)*" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Repository overview
echo "## Repository Overview" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "- **Total Commits:** $(git rev-list --count HEAD)" >> "$OUTPUT_FILE"
echo "- **Branches:** $(git branch -a | wc -l)" >> "$OUTPUT_FILE"
echo "- **Contributors:** $(git shortlog -sn --all | wc -l)" >> "$OUTPUT_FILE"
echo "- **First Commit:** $(git log --reverse --format='%aI' | head -1)" >> "$OUTPUT_FILE"
echo "- **Latest Commit:** $(git log -1 --format='%aI')" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Top contributors
echo "## Top Contributors" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
git shortlog -sn --all | head -10 | while read commits author; do
    echo "- **$author**: $commits commits" >> "$OUTPUT_FILE"
done
echo "" >> "$OUTPUT_FILE"

# Commit activity by month
echo "## Commit Activity (Last 12 Months)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
for i in {0..11}; do
    month=$(date -d "$i months ago" +%Y-%m)
    count=$(git log --since="$month-01" --until="$month-31" --oneline | wc -l)
    echo "- **$month**: $count commits" >> "$OUTPUT_FILE"
done
echo "" >> "$OUTPUT_FILE"

# Most changed files
echo "## Most Changed Files" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
git log --pretty=format: --name-only | sort | uniq -c | sort -rg | head -20 | while read count file; do
    if [ -n "$file" ]; then
        echo "- **$file**: $count changes" >> "$OUTPUT_FILE"
    fi
done
echo "" >> "$OUTPUT_FILE"

# Code ownership (by lines)
echo "## Code Ownership (Top Files)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Find top files by LOC
git ls-files | grep -E '\.(py|js|ts|go|rs|java)$' | head -20 | while read file; do
    if [ -f "$file" ]; then
        echo "### $file" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        git blame --line-porcelain "$file" 2>/dev/null | \
            grep "^author " | \
            sort | uniq -c | sort -rg | head -5 | while read count _ author; do
            echo "- $author: $count lines" >> "$OUTPUT_FILE"
        done
        echo "" >> "$OUTPUT_FILE"
    fi
done

# Hotspots (files changed together)
echo "## Hotspots (Frequently Changed Files)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "*Files that change frequently may indicate areas of active development or instability*" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

git log --format=format: --name-only --since="6 months ago" | \
    egrep -v '^$' | \
    sort | uniq -c | sort -rg | head -15 | while read count file; do
    echo "- **$file**: $count changes (last 6 months)" >> "$OUTPUT_FILE"
done
echo "" >> "$OUTPUT_FILE"

echo "Git history analysis complete: $OUTPUT_FILE"
```

