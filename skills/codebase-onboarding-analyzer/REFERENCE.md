# Reference Documentation

API documentation, function signatures, and language-specific configurations.

**Parent:** [SKILL.md](./SKILL.md)

## Table of Contents

1. [Language-Specific Analysis](#language-specific-analysis)
2. [Tool Configuration](#tool-configuration)
3. [API Reference](#api-reference)
4. [Supported File Types](#supported-file-types)

## Language-Specific Analysis

### Python Project Analysis

```bash
# Python-specific analysis
radon cc . -a -nb        # Cyclomatic complexity
radon mi . -n B          # Maintainability index
vulture .                # Dead code
bandit -r .              # Security issues
pydeps . --max-bacon 2   # Dependency graph
```

### JavaScript/TypeScript Analysis

```bash
# JavaScript/TypeScript analysis
npx madge --circular .                    # Circular dependencies
npx madge --image graph.png .             # Dependency graph
npx complexity-report src/**/*.js         # Complexity
npx jscpd src/                            # Copy-paste detection
npx dependency-cruiser --output-type dot src | dot -T png > deps.png
```

### Go Analysis

```bash
# Go analysis
gocyclo -avg .                           # Complexity
go-callvis -format png .                 # Call graph
godepgraph -s . | dot -Tpng -o deps.png  # Dependency graph
staticcheck ./...                        # Advanced linting
```

### Rust Analysis

```bash
# Rust analysis
cargo modules generate graph --lib | dot -Tpng > modules.png  # Module graph
cargo geiger                             # Unsafe code detection
cargo tree                               # Dependency tree
cargo clippy                             # Linting
```



## Tool Configuration

### Radon Configuration (.radon.cfg)

```ini
[radon]
exclude = **/tests/**,**/node_modules/**,**/dist/**,**/build/**
average = True
show_complexity = True
```

### Madge Configuration (.madgerc)

```json
{
  "exclude": "^(node_modules|dist|build|coverage)",
  "fileExtensions": ["js", "ts", "jsx", "tsx"],
  "detectiveOptions": {
    "ts": {
      "skipTypeImports": true
    }
  }
}
```

### Pylint Configuration (.pylintrc)

```ini
[MASTER]
ignore=tests,migrations
max-line-length=100

[MESSAGES CONTROL]
disable=C0111,C0103  # Missing docstring, invalid name
```

## API Reference

### DependencyAnalyzer

**Python implementation for analyzing project dependencies**

```python
class DependencyAnalyzer:
    """Analyze Python project dependencies"""

    def __init__(self, project_root: str):
        """
        Initialize analyzer

        Args:
            project_root: Path to project root directory
        """

    def analyze(self) -> Dict:
        """
        Run full dependency analysis

        Returns:
            Dict containing:
                - total_modules: int
                - entry_points: List[str]
                - external_packages: List[str]
                - circular_dependencies: List[List[str]]
                - dependency_graph: Dict
        """

    def generate_graphviz(self, output_file: str = "dependencies.dot"):
        """
        Generate Graphviz DOT file

        Args:
            output_file: Path to output .dot file
        """
```

### ComplexityAnalyzer

**Analyze code complexity metrics**

```python
class ComplexityAnalyzer:
    """Analyze code complexity metrics"""

    def __init__(self, project_root: str):
        """
        Initialize analyzer

        Args:
            project_root: Path to project root directory
        """

    def analyze_python(self) -> Dict:
        """
        Analyze Python code complexity

        Returns:
            Dict containing:
                - files: List[Dict] - Per-file metrics
                - summary: Dict - Aggregate statistics
        """

    def generate_complexity_report(self, results: Dict, output_file: str):
        """
        Generate human-readable report

        Args:
            results: Output from analyze_python()
            output_file: Path to markdown report
        """
```

### EntryPointFinder

**Find all application entry points**

```python
class EntryPointFinder:
    """Find all entry points in a codebase"""

    def __init__(self, project_root: str):
        """
        Initialize finder

        Args:
            project_root: Path to project root directory
        """

    def find_all(self) -> Dict:
        """
        Find all types of entry points

        Returns:
            Dict containing:
                - main_functions: List[Dict]
                - cli_commands: List[Dict]
                - api_endpoints: List[Dict]
                - scripts: List[Dict]
                - docker_entrypoints: List[Dict]
        """

    def generate_entry_point_guide(self, output_file: str):
        """
        Generate entry point guide

        Args:
            output_file: Path to markdown guide
        """
```

## Supported File Types

### By Language

| Language | Extensions | Tools |
|----------|------------|-------|
| **Python** | `.py`, `.pyx`, `.pyi` | radon, pydeps, vulture, bandit |
| **JavaScript** | `.js`, `.mjs`, `.cjs` | madge, complexity-report |
| **TypeScript** | `.ts`, `.tsx` | madge, ts-morph, typedoc |
| **Go** | `.go` | gocyclo, go-callvis, staticcheck |
| **Rust** | `.rs` | cargo-modules, cargo-geiger |
| **Java** | `.java` | checkstyle, pmd, jdepend |
| **C/C++** | `.c`, `.cpp`, `.h`, `.hpp` | cppcheck, complexity |
| **Ruby** | `.rb` | flog, reek, rubocop |
| **PHP** | `.php` | phpmetrics, pdepend |

### Configuration Files

Automatically detected:

- **Python:** `requirements.txt`, `Pipfile`, `pyproject.toml`, `setup.py`
- **JavaScript:** `package.json`, `package-lock.json`, `yarn.lock`
- **Go:** `go.mod`, `go.sum`
- **Rust:** `Cargo.toml`, `Cargo.lock`
- **Java:** `pom.xml`, `build.gradle`, `settings.gradle`
- **Ruby:** `Gemfile`, `Gemfile.lock`
- **PHP:** `composer.json`, `composer.lock`
