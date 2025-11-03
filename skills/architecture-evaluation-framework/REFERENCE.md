# Architecture Evaluation API Reference

## Table of Contents
1. [Core Classes](#core-classes)
2. [Analysis Functions](#analysis-functions)
3. [Metrics Catalog](#metrics-catalog)
4. [Configuration Options](#configuration-options)
5. [Tool-Specific APIs](#tool-specific-apis)

## Core Classes

### ArchitectureEvaluator

Main class for architecture evaluation.

```python
class ArchitectureEvaluator:
    """
    Main architecture evaluation class.

    Args:
        project_path (str): Path to project root
        config (dict): Configuration options

    Example:
        evaluator = ArchitectureEvaluator("./src", {"depth": 3})
        results = evaluator.evaluate()
    """

    def __init__(self, project_path: str, config: dict = None)
    def evaluate(self) -> EvaluationResults
    def analyze_patterns(self) -> List[Pattern]
    def analyze_solid(self) -> SOLIDResults
    def analyze_coupling(self) -> CouplingMetrics
    def generate_report(self, output_path: str) -> None
```

### SOLIDAnalyzer

Analyzes SOLID principles compliance.

```python
class SOLIDAnalyzer:
    """
    SOLID principles analyzer.

    Methods:
        analyze_file(path): Analyze single file
        analyze_directory(path): Analyze directory
        get_violations(): Get all violations
        calculate_score(): Calculate compliance score
    """

    def analyze_file(self, file_path: str) -> List[Violation]
    def analyze_directory(self, dir_path: str) -> List[Violation]
    def get_violations(self) -> Dict[str, List[Violation]]
    def calculate_score(self) -> float
```

### C4Generator

Generates C4 architecture diagrams.

```python
class C4Generator:
    """
    C4 model diagram generator.

    Args:
        system_name (str): Name of the system

    Methods:
        add_person(): Add user/actor
        add_system(): Add external system
        add_container(): Add container
        add_component(): Add component
        add_relationship(): Add relationship
        generate_*_diagram(): Generate specific diagram level
    """

    def add_person(self, name: str, description: str, tags: List[str] = None) -> None
    def add_system(self, name: str, description: str, external: bool = False) -> None
    def add_container(self, name: str, description: str, technology: str) -> None
    def add_component(self, name: str, description: str, technology: str) -> None
    def add_relationship(self, source: str, target: str, description: str) -> None
    def generate_context_diagram(self) -> str
    def generate_container_diagram(self) -> str
    def generate_component_diagram(self, container: str) -> str
```

## Analysis Functions

### Pattern Detection

```python
def identify_patterns(codebase_path: str) -> Dict[str, float]:
    """
    Identify architectural patterns in codebase.

    Args:
        codebase_path: Path to codebase

    Returns:
        Dict mapping pattern names to confidence scores (0-1)

    Example:
        patterns = identify_patterns("./src")
        # {'layered': 0.85, 'mvc': 0.72}
    """

def detect_anti_patterns(codebase_path: str) -> List[AntiPattern]:
    """
    Detect architectural anti-patterns.

    Returns:
        List of detected anti-patterns with severity
    """
```

### Dependency Analysis

```python
def build_dependency_graph(source_dir: str) -> Dict[str, Set[str]]:
    """
    Build module dependency graph.

    Args:
        source_dir: Source directory path

    Returns:
        Dict mapping modules to their dependencies

    Note:
        Uses exact match and prefix checking for proper dependency resolution
    """

def find_cycles(graph: Dict[str, Set[str]]) -> List[List[str]]:
    """
    Find circular dependencies in graph.

    Returns:
        List of cycles (each cycle is a list of nodes)
    """

def calculate_coupling_metrics(dependency_graph: Dict) -> List[CouplingMetric]:
    """
    Calculate coupling metrics for all modules.

    Returns:
        List of coupling metrics per module
    """
```

### Complexity Analysis

```python
def calculate_cyclomatic_complexity(file_path: str) -> int:
    """
    Calculate cyclomatic complexity for a file.

    Args:
        file_path: Path to source file

    Returns:
        Cyclomatic complexity score
    """

def calculate_cognitive_complexity(file_path: str) -> int:
    """
    Calculate cognitive complexity (human readability).
    """

def measure_halstead_metrics(file_path: str) -> HalsteadMetrics:
    """
    Calculate Halstead complexity metrics.
    """
```

## Metrics Catalog

### Architecture Metrics

| Metric | Description | Formula | Good Range |
|--------|-------------|---------|------------|
| **Coupling (Ca)** | Afferent coupling - incoming dependencies | Count of modules depending on this | < 7 |
| **Coupling (Ce)** | Efferent coupling - outgoing dependencies | Count of dependencies | < 7 |
| **Instability (I)** | Susceptibility to change | Ce / (Ca + Ce) | 0.3 - 0.7 |
| **Abstractness (A)** | Ratio of abstract to concrete | Abstract / Total classes | 0.2 - 0.5 |
| **Distance (D)** | Distance from main sequence | \|A + I - 1\| | < 0.3 |
| **LCOM** | Lack of Cohesion of Methods | See LCOM4 algorithm | < 2 |

### Quality Attributes

| Attribute | Metrics | Measurement |
|-----------|---------|-------------|
| **Performance** | Response time, Throughput, Resource usage | ms, req/s, CPU% |
| **Scalability** | Load capacity, Elasticity | Users, req/s |
| **Availability** | Uptime, MTBF, MTTR | %, hours |
| **Security** | Vulnerabilities, Attack surface | Count, LOC |
| **Modifiability** | Change effort, Impact radius | Hours, modules |
| **Testability** | Test coverage, Test complexity | %, cyclomatic |

### Technical Debt Metrics

| Metric | Description | Calculation |
|--------|-------------|-------------|
| **Debt Ratio** | Technical debt vs development time | Debt hours / Dev hours |
| **Debt Density** | Debt per line of code | Debt hours / KLOC |
| **Interest Rate** | Ongoing cost of debt | Extra effort % |
| **Break-even Point** | When fixing pays off | Fix cost / Interest rate |

## Configuration Options

### Global Configuration

```yaml
# .architecture.yaml
architecture:
  # Analysis depth
  max_depth: 5

  # File filters
  include:
    - "src/**/*.py"
    - "lib/**/*.js"
  exclude:
    - "test/**"
    - "vendor/**"
    - "**/node_modules/**"

  # Thresholds
  thresholds:
    coupling: 0.5
    complexity: 10
    coverage: 80
    response_time: 200

  # Analysis features
  features:
    patterns: true
    solid: true
    coupling: true
    complexity: true
    security: false

  # Output formats
  output:
    formats: ["markdown", "json", "html"]
    directory: "reports/architecture"
```

### Tool-Specific Configuration

```python
# Python configuration
PYTHON_CONFIG = {
    'ast_parser': 'ast',  # or 'astroid'
    'ignore_decorators': ['property', 'staticmethod'],
    'max_line_length': 120,
    'complexity_threshold': 10
}

# JavaScript configuration
JS_CONFIG = {
    'parser': '@babel/parser',
    'ecma_version': 2021,
    'source_type': 'module',
    'frameworks': ['react', 'vue', 'angular']
}

# Go configuration
GO_CONFIG = {
    'go_version': '1.19',
    'vendor': 'exclude',  # or 'include'
    'test_files': 'exclude'
}
```

## Tool-Specific APIs

### Java Tools

#### ArchUnit
```java
@Test
public void architecture_rules() {
    JavaClasses classes = new ClassFileImporter()
        .importPackages("com.myapp");

    // Layer rules
    layeredArchitecture()
        .layer("Controllers").definedBy("..controller..")
        .layer("Services").definedBy("..service..")
        .layer("Persistence").definedBy("..repository..")
        .whereLayer("Controllers").mayNotBeAccessedByAnyLayer()
        .whereLayer("Services").mayOnlyBeAccessedByLayers("Controllers")
        .whereLayer("Persistence").mayOnlyBeAccessedByLayers("Services")
        .check(classes);
}
```

#### jQAssistant
```xml
<!-- jqassistant-rules.xml -->
<group id="architecture">
    <constraint id="dependency:Package">
        <description>Check package dependencies</description>
        <cypher><![CDATA[
            MATCH (p1:Package)-[:DEPENDS_ON]->(p2:Package)
            WHERE p1.name STARTS WITH 'com.myapp.ui'
            AND p2.name STARTS WITH 'com.myapp.data'
            RETURN p1, p2
        ]]></cypher>
    </constraint>
</group>
```

### .NET Tools

#### NDepend
```csharp
// CQL Query
warn if count > 0 from t in JustMyCode.Types
where t.CyclomaticComplexity > 10
select new {
    t,
    t.CyclomaticComplexity,
    t.NbLinesOfCode
}
```

### Python Tools

#### Prospector
```yaml
# .prospector.yaml
inherits:
  - strictness_veryhigh

ignore-paths:
  - tests

pylint:
  disable:
    - too-many-arguments
    - too-few-public-methods

mccabe:
  complexity: 10
```

#### Radon
```python
from radon.complexity import cc_visit
from radon.metrics import mi_visit

def analyze_with_radon(filepath):
    """Analyze using Radon metrics"""
    with open(filepath) as f:
        code = f.read()

    # Cyclomatic complexity
    cc = cc_visit(code)

    # Maintainability index
    mi = mi_visit(code, multi=True)

    return {
        'complexity': cc,
        'maintainability': mi
    }
```

## CLI Reference

### Command Line Interface

```bash
# Basic analysis
architecture-eval analyze <path> [options]

# Options
--depth <n>          Analysis depth (default: 3)
--output <dir>       Output directory
--format <fmt>       Output format (md|json|html)
--config <file>      Configuration file
--parallel           Enable parallel processing
--cache              Use cached results
--verbose            Verbose output

# Specific analyses
architecture-eval solid <path>      # SOLID analysis only
architecture-eval coupling <path>   # Coupling analysis only
architecture-eval patterns <path>   # Pattern detection only
architecture-eval fitness <path>    # Fitness tests only

# Utilities
architecture-eval generate-c4 <path>     # Generate C4 diagrams
architecture-eval generate-adr <title>   # Create ADR template
architecture-eval compare <v1> <v2>      # Compare versions
```

### Environment Variables

```bash
# Configuration
ARCH_EVAL_CONFIG=/path/to/config.yaml
ARCH_EVAL_CACHE_DIR=/path/to/cache
ARCH_EVAL_PARALLEL=true
ARCH_EVAL_MAX_WORKERS=4

# Tool paths
PLANTUML_JAR=/path/to/plantuml.jar
SONAR_HOST_URL=http://localhost:9000
DEPENDENCY_CRUISER_CONFIG=/path/to/.dependency-cruiser.js

# Performance
ARCH_EVAL_MEMORY_LIMIT=2048  # MB
ARCH_EVAL_TIMEOUT=600        # seconds
```

## Architectural Decision Records (ADRs)

### Using UI Architecture ADRs

**Location**: `plan-fixed/nodes/ADR/adr-ui-*.json`
**Count**: 7 ADR nodes
**Format**: JSON (ADR schema from recursive-planning-spec/FORMS.md)
**Links**: Each ADR links to its Architecture node via `depends_on`

#### For Developers

When implementing UI features, consult the relevant ADR:

**1. State Management Questions?**
→ Read: `adr-ui-state-management-tanstack-query.json`
- Why TanStack Query instead of Redux?
- When to use TanStack Query vs Zustand?
- What are the trade-offs?

**2. Responsive Design Questions?**
→ Read: `adr-ui-responsive-mobile-first.json`
- Why mobile-first instead of desktop-first?
- What breakpoints to use?
- How to handle desktop features?

**3. Internationalization Questions?**
→ Read: `adr-ui-i18n-icu-messageformat.json`
- Why ICU MessageFormat instead of simple strings?
- How to handle pluralization?
- What about gender/case support?

**4. Navigation Questions?**
→ Read: `adr-ui-navigation-stack-based.json`
- Why stack-based instead of tabs?
- How to handle deep linking?
- What about modals?

**5. Accessibility Questions?**
→ Read: `adr-ui-accessibility-wcag-aa.json`
- Why WCAG AA instead of AAA?
- What contrast ratios are required?
- What about keyboard navigation?

**6. Analytics Questions?**
→ Read: `adr-ui-analytics-10-percent-sampling.json`
- Why 10% sampling instead of 100%?
- What about error tracking?
- Privacy implications?

**7. Onboarding Questions?**
→ Read: `adr-ui-onboarding-progressive-disclosure.json`
- Why progressive disclosure instead of forced tours?
- How to balance learning vs flow?
- What about tooltips?

#### For Architects

**Reviewing or changing decisions**:

Each ADR documents:
- **Context**: The problem that needed solving
- **Options**: What alternatives were considered (4 per decision)
- **Decision**: What was chosen
- **Rationale**: WHY it was chosen (quantified benefits)
- **Consequences**: Positive, negative, and risks

**If circumstances change**:

1. **Review the ADR**: Understand the original rationale
2. **Check if context changed**: Are the assumptions still valid?
3. **Evaluate consequences**: Did predicted outcomes occur?
4. **Document new ADR**: If changing, create new ADR with updated decision
5. **Link ADRs**: Reference the superseded ADR

**Example workflow**:
```bash
# Read current ADR
cat plan-fixed/nodes/ADR/adr-ui-state-management-tanstack-query.json | jq

# If changing decision, create new ADR:
# adr:ui-state-management-tanstack-query-v2.json
# Reference the original in "supersedes" field
```

#### For Product Managers

**Understanding trade-offs**:

Each ADR lists consequences in three categories:
- **Positive** = Benefits we gain
- **Negative** = Trade-offs we accept
- **Risks** = Things to watch out for

See `docs/_reference/adr/ui-adrs-usage-guide.md` for complete usage documentation.

---

## Return Types

### EvaluationResults
```python
@dataclass
class EvaluationResults:
    patterns: List[Pattern]
    solid_violations: List[Violation]
    coupling_metrics: List[CouplingMetric]
    complexity_scores: Dict[str, float]
    technical_debt: DebtReport
    recommendations: List[Recommendation]
    score: float  # Overall architecture score 0-100
```

### CouplingMetric
```python
@dataclass
class CouplingMetric:
    module: str
    afferent_coupling: int  # Ca
    efferent_coupling: int  # Ce
    instability: float      # I = Ce / (Ca + Ce)
    abstractness: float     # A
    distance: float         # D = |A + I - 1|
```

### Violation
```python
@dataclass
class Violation:
    principle: str  # SRP, OCP, LSP, ISP, DIP
    file_path: str
    line_number: int
    severity: str   # low, medium, high
    description: str
    recommendation: str
```
