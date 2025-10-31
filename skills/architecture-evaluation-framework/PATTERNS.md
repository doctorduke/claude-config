# Architecture Evaluation Implementation Patterns

## Table of Contents
1. [Pattern Identification](#pattern-identification)
2. [SOLID Analyzer](#solid-analyzer)
3. [Coupling and Cohesion Analysis](#coupling-cohesion)
4. [ADR Management](#adr-management)
5. [C4 Model Generation](#c4-model-generation)
6. [ATAM Evaluation](#atam-evaluation)
7. [Dependency Graph Building](#dependency-graph-building)
8. [Technical Debt Quantification](#technical-debt)
9. [Architectural Fitness Functions](#fitness-functions)

## Pattern Identification

### Architecture Pattern Detection Algorithm

```python
def identify_architecture_patterns(codebase_path):
    """Detect architectural patterns in codebase"""
    patterns = {
        'layered': check_layered_architecture,
        'microservices': check_microservices,
        'mvc': check_mvc_pattern,
        'event_driven': check_event_driven,
        'hexagonal': check_hexagonal
    }

    results = {}
    for pattern_name, check_func in patterns.items():
        confidence = check_func(codebase_path)
        if confidence > 0.7:  # 70% confidence threshold
            results[pattern_name] = confidence

    return results

def check_layered_architecture(path):
    """Check for layered architecture pattern"""
    layers = ['presentation', 'business', 'data', 'domain', 'service']
    found_layers = []

    for root, dirs, files in os.walk(path):
        for dir_name in dirs:
            if any(layer in dir_name.lower() for layer in layers):
                found_layers.append(dir_name)

    # Check for dependency direction (top layers shouldn't import bottom)
    violations = check_layer_violations(path, found_layers)

    confidence = len(found_layers) / len(layers)
    if violations > 0:
        confidence *= (1 - violations / 10)  # Reduce confidence for violations

    return confidence
```

### Anti-Pattern Detection

```python
def detect_anti_patterns(codebase_path):
    """Detect common architectural anti-patterns"""
    anti_patterns = []

    # God Object detection
    for file_path in glob.glob(f"{codebase_path}/**/*.py", recursive=True):
        try:
            tree = ast.parse(open(file_path).read())
        except (SyntaxError, UnicodeDecodeError) as e:
            print(f"Warning: Skipping {file_path} due to parsing error: {e}")
            continue
        for node in ast.walk(tree):
            if isinstance(node, ast.ClassDef):
                method_count = len([n for n in node.body if isinstance(n, ast.FunctionDef)])
                if method_count > 20:
                    anti_patterns.append({
                        'type': 'god_object',
                        'file': file_path,
                        'class': node.name,
                        'methods': method_count
                    })

    # Circular Dependencies
    dep_graph = build_dependency_graph(codebase_path)
    cycles = find_cycles(dep_graph)
    if cycles:
        anti_patterns.append({
            'type': 'circular_dependencies',
            'cycles': cycles
        })

    return anti_patterns
```

## SOLID Analyzer

### Core SOLID Analysis Implementation

```python
class SOLIDAnalyzer(ast.NodeVisitor):
    """Analyze code for SOLID principle violations"""

    def __init__(self, file_path):
        self.file_path = file_path
        self.violations = []
        self.classes = {}

    def analyze(self):
        """Run complete SOLID analysis"""
        try:
            with open(self.file_path) as f:
                tree = ast.parse(f.read())
        except (SyntaxError, UnicodeDecodeError) as e:
            print(f"Warning: Skipping {self.file_path} due to parsing error: {e}")
            return self.violations
        self.visit(tree)
        return self.violations

    def check_single_responsibility(self, node):
        """Check SRP - class should have one reason to change"""
        methods = [n for n in node.body if isinstance(n, ast.FunctionDef)]

        # Analyze method names for different concerns
        concerns = set()
        patterns = {
            'data_access': ['load', 'save', 'fetch', 'query'],
            'validation': ['validate', 'check', 'verify'],
            'transformation': ['transform', 'convert', 'parse'],
            'presentation': ['render', 'display', 'format']
        }

        for method in methods:
            for concern, keywords in patterns.items():
                if any(kw in method.name.lower() for kw in keywords):
                    concerns.add(concern)

        if len(concerns) >= 3:
            return ViolationReport(
                principle='SRP',
                severity='medium',
                description=f'Class has {len(concerns)} responsibilities'
            )

    def check_open_closed(self, node):
        """Check OCP - open for extension, closed for modification"""
        # Look for if/elif chains (switch-like behavior)
        for child in ast.walk(node):
            if isinstance(child, ast.If):
                elif_count = count_elif_chain(child)
                if elif_count >= 4:
                    return ViolationReport(
                        principle='OCP',
                        severity='medium',
                        description=f'Long if/elif chain ({elif_count} branches)'
                    )
```

### SOLID Metrics Calculation

```python
def calculate_solid_score(violations):
    """Calculate overall SOLID compliance score"""
    principle_weights = {
        'SRP': 0.25,
        'OCP': 0.20,
        'LSP': 0.20,
        'ISP': 0.15,
        'DIP': 0.20
    }

    scores = {}
    for principle in principle_weights:
        violations_count = len([v for v in violations if v.principle == principle])
        # Score decreases with violations (exponential decay)
        scores[principle] = max(0, 1 - (violations_count * 0.1))

    # Weighted average
    total_score = sum(scores[p] * principle_weights[p] for p in principle_weights)
    return total_score, scores
```

## Coupling and Cohesion Analysis

### Dependency Graph Building

```python
def build_dependency_graph(source_dir):
    """Build module dependency graph with exact match and prefix checking"""
    modules = {}
    dependency_graph = defaultdict(set)

    # Discover all modules
    for py_file in Path(source_dir).rglob('*.py'):
        if 'test' in str(py_file):
            continue

        module_name = get_module_name(py_file, source_dir)
        imports = extract_imports(py_file)
        modules[module_name] = {
            'file': str(py_file),
            'imports': imports
        }

    # Build dependency relationships
    for module_name, module_data in modules.items():
        for import_name in module_data['imports']:
            # Find matching module
            for other_module in modules.keys():
                # IMPORTANT: Fix from PR 65 - check both exact match and prefix
                # This ensures "pkg.module" matches both "pkg.module" exactly
                # AND serves as prefix for "pkg.module.submodule"
                if (other_module == import_name or
                    other_module.startswith(import_name + '.')):
                    dependency_graph[module_name].add(other_module)

    return dependency_graph

def extract_imports(file_path):
    """Extract all imports from a Python file"""
    imports = set()

    try:
        with open(file_path) as f:
            tree = ast.parse(f.read())
    except (SyntaxError, UnicodeDecodeError) as e:
        print(f"Warning: Skipping {file_path} due to parsing error: {e}")
        return imports

    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for alias in node.names:
                imports.add(alias.name)
        elif isinstance(node, ast.ImportFrom):
            if node.module:
                imports.add(node.module)

    return imports
```

### Coupling Metrics

```python
def calculate_coupling_metrics(dependency_graph):
    """Calculate coupling metrics for all modules"""
    metrics = []

    for module in dependency_graph.keys():
        # Efferent coupling (Ce): modules this depends on
        ce = len(dependency_graph[module])

        # Afferent coupling (Ca): modules that depend on this
        ca = sum(1 for deps in dependency_graph.values() if module in deps)

        # Instability (I = Ce / (Ca + Ce))
        instability = ce / (ca + ce) if (ca + ce) > 0 else 0

        # Distance from main sequence
        abstractness = estimate_abstractness(module)
        distance = abs(abstractness + instability - 1)

        metrics.append({
            'module': module,
            'ca': ca,
            'ce': ce,
            'instability': instability,
            'distance': distance
        })

    return metrics
```

### Cohesion Analysis

```python
def calculate_lcom(class_node):
    """Calculate Lack of Cohesion of Methods (LCOM4)"""
    methods = [n for n in class_node.body if isinstance(n, ast.FunctionDef)]
    attributes = extract_class_attributes(class_node)

    # Build method-attribute usage graph
    method_attrs = {}
    for method in methods:
        used_attrs = extract_used_attributes(method, attributes)
        method_attrs[method.name] = used_attrs

    # Calculate connected components
    components = find_connected_components(method_attrs)

    # LCOM4 = number of connected components
    return len(components)
```

## ADR Management

### ADR Template Generation

```python
ADR_TEMPLATE = """# ADR-{number}: {title}

Date: {date}
Status: {status}
Deciders: {deciders}
Tags: {tags}

## Context
{context}

## Decision
{decision}

## Consequences

### Positive
{positive}

### Negative
{negative}

### Neutral
{neutral}

## Alternatives Considered
{alternatives}

## References
{references}
"""

def create_adr(title, context, decision, consequences):
    """Create new ADR with auto-numbering"""
    adr_dir = Path("docs/adr")
    adr_dir.mkdir(parents=True, exist_ok=True)

    # Get next number
    existing = list(adr_dir.glob("ADR-*.md"))
    next_num = len(existing) + 1

    # Generate content
    content = ADR_TEMPLATE.format(
        number=f"{next_num:03d}",
        title=title,
        date=datetime.now().strftime("%Y-%m-%d"),
        status="Proposed",
        context=context,
        decision=decision,
        # ... other fields
    )

    # Save file
    filename = f"ADR-{next_num:03d}-{slugify(title)}.md"
    (adr_dir / filename).write_text(content)

    return filename
```

### ADR Status Management

```python
def update_adr_status(adr_number, new_status, superseded_by=None):
    """Update ADR status (e.g., mark as superseded)"""
    adr_file = find_adr_file(adr_number)

    content = adr_file.read_text()

    # Update status line
    if superseded_by:
        new_status = f"Superseded by ADR-{superseded_by:03d}"

    content = re.sub(
        r'Status: .*',
        f'Status: {new_status}',
        content
    )

    adr_file.write_text(content)
```

## C4 Model Generation

### PlantUML C4 Diagram Generation

```python
class C4Generator:
    """Generate C4 model diagrams in PlantUML format"""

    def __init__(self, system_name):
        self.system_name = system_name
        self.elements = []
        self.relationships = []

    def generate_context_diagram(self):
        """Generate Level 1: System Context"""
        diagram = f"""@startuml
!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Context.puml

title System Context diagram for {self.system_name}

"""
        # Add persons and systems
        for elem in self.elements:
            if elem['type'] == 'Person':
                diagram += f'Person({self._id(elem["name"])}, "{elem["name"]}", "{elem["description"]}")\n'
            elif elem['type'] == 'System':
                if elem.get('external'):
                    diagram += f'System_Ext({self._id(elem["name"])}, "{elem["name"]}", "{elem["description"]}")\n'
                else:
                    diagram += f'System({self._id(elem["name"])}, "{elem["name"]}", "{elem["description"]}")\n'

        # Add relationships
        for rel in self.relationships:
            diagram += f'Rel({self._id(rel["from"])}, {self._id(rel["to"])}, "{rel["label"]}")\n'

        diagram += "@enduml"
        return diagram

    def _id(self, name):
        """Convert name to valid PlantUML ID"""
        return name.replace(" ", "_").replace("-", "_")
```

### Automatic C4 Discovery

```python
def discover_c4_elements(codebase_path):
    """Automatically discover C4 elements from codebase"""
    elements = {
        'containers': [],
        'components': []
    }

    # Discover containers (apps, services, databases)
    for config_file in glob.glob(f"{codebase_path}/**/docker-compose*.yml", recursive=True):
        services = parse_docker_compose(config_file)
        for service in services:
            elements['containers'].append({
                'name': service['name'],
                'technology': service.get('image', 'Unknown'),
                'description': f"Service from {config_file}"
            })

    # Discover components from code structure
    for package_dir in find_packages(codebase_path):
        elements['components'].append({
            'name': package_dir.name,
            'container': guess_container(package_dir),
            'technology': detect_technology(package_dir)
        })

    return elements
```

## ATAM Evaluation

### Quality Attribute Scenario Evaluation

```python
class ATAMEvaluator:
    """Evaluate architecture using ATAM methodology"""

    def evaluate_scenario(self, scenario, architecture):
        """Evaluate a quality attribute scenario"""
        results = {
            'scenario': scenario,
            'sensitivity_points': [],
            'tradeoff_points': [],
            'risks': [],
            'non_risks': []
        }

        # Analyze architectural decisions affecting this scenario
        for decision in architecture['decisions']:
            impact = self.assess_impact(decision, scenario)

            if impact['sensitivity'] > 0.7:
                results['sensitivity_points'].append({
                    'decision': decision,
                    'impact': impact['sensitivity']
                })

            if impact['tradeoff']:
                results['tradeoff_points'].append({
                    'decision': decision,
                    'positive': impact['positive_attributes'],
                    'negative': impact['negative_attributes']
                })

        # Identify risks
        if scenario['priority'] == 'high' and len(results['sensitivity_points']) > 3:
            results['risks'].append(
                "High-priority scenario affected by multiple architectural decisions"
            )

        return results
```

### Trade-off Analysis

```python
def analyze_tradeoffs(architectural_approaches):
    """Analyze trade-offs between quality attributes"""
    tradeoff_matrix = {}

    for approach in architectural_approaches:
        positive = []
        negative = []

        for attribute, impact in approach['impacts'].items():
            if impact > 0:
                positive.append(attribute)
            elif impact < 0:
                negative.append(attribute)

        if positive and negative:
            tradeoff_matrix[approach['name']] = {
                'improves': positive,
                'degrades': negative,
                'severity': calculate_severity(positive, negative)
            }

    return tradeoff_matrix
```

## Technical Debt

### Technical Debt Quantification

```python
def quantify_technical_debt(codebase_path):
    """Quantify technical debt using multiple metrics"""
    debt_items = []

    # Code quality debt
    for file_path in find_source_files(codebase_path):
        complexity = calculate_cyclomatic_complexity(file_path)
        if complexity > 10:
            debt_items.append({
                'type': 'complexity',
                'file': file_path,
                'metric': complexity,
                'effort_hours': (complexity - 10) * 0.5
            })

    # Architecture debt
    coupling_metrics = calculate_coupling_metrics(codebase_path)
    for metric in coupling_metrics:
        if metric['instability'] > 0.8:
            debt_items.append({
                'type': 'coupling',
                'module': metric['module'],
                'metric': metric['instability'],
                'effort_hours': 4  # Estimated refactoring effort
            })

    # Calculate total debt
    total_hours = sum(item['effort_hours'] for item in debt_items)

    return {
        'items': debt_items,
        'total_hours': total_hours,
        'total_days': total_hours / 8,
        'categories': group_by_type(debt_items)
    }
```

### Debt Prioritization

```python
def prioritize_technical_debt(debt_items, business_impact):
    """Prioritize technical debt based on risk and business impact"""
    prioritized = []

    for item in debt_items:
        # Calculate priority score
        risk_score = calculate_risk_score(item)
        impact_score = business_impact.get(item['module'], 0.5)

        priority = risk_score * impact_score * item['effort_hours']

        prioritized.append({
            **item,
            'priority_score': priority,
            'roi': impact_score / item['effort_hours']  # Return on investment
        })

    # Sort by ROI (highest first)
    return sorted(prioritized, key=lambda x: x['roi'], reverse=True)
```

## Fitness Functions

### Architectural Fitness Function Examples

```python
class ArchitecturalFitnessTests:
    """Automated tests for architectural fitness"""

    def test_no_circular_dependencies(self):
        """Ensure no circular dependencies exist"""
        graph = build_dependency_graph("src/")
        cycles = find_cycles(graph)
        assert not cycles, f"Circular dependencies found: {cycles}"

    def test_layer_dependencies(self):
        """Ensure layers only depend on lower layers"""
        layers = ['presentation', 'business', 'data']
        violations = []

        for upper_idx, upper_layer in enumerate(layers[:-1]):
            for lower_layer in layers[upper_idx + 1:]:
                deps = find_dependencies(upper_layer, lower_layer)
                if deps:
                    violations.append(f"{lower_layer} depends on {upper_layer}")

        assert not violations, f"Layer violations: {violations}"

    def test_package_coupling_threshold(self):
        """Ensure package coupling stays below threshold"""
        MAX_COUPLING = 0.5

        metrics = calculate_coupling_metrics("src/")
        high_coupling = [m for m in metrics if m['instability'] > MAX_COUPLING]

        assert not high_coupling, f"High coupling modules: {high_coupling}"

    def test_complexity_threshold(self):
        """Ensure cyclomatic complexity stays manageable"""
        MAX_COMPLEXITY = 10
        violations = []

        for file_path in find_source_files("src/"):
            complexity = calculate_cyclomatic_complexity(file_path)
            if complexity > MAX_COMPLEXITY:
                violations.append(f"{file_path}: {complexity}")

        assert not violations, f"High complexity files: {violations}"
```

### Continuous Fitness Monitoring

```python
def setup_continuous_fitness_monitoring():
    """Setup continuous architectural fitness monitoring"""

    # Define fitness functions
    fitness_functions = [
        {
            'name': 'dependency_cycles',
            'test': test_no_circular_dependencies,
            'frequency': 'commit',
            'threshold': 0
        },
        {
            'name': 'response_time',
            'test': test_api_response_time,
            'frequency': 'hourly',
            'threshold': 200  # ms
        },
        {
            'name': 'test_coverage',
            'test': test_code_coverage,
            'frequency': 'daily',
            'threshold': 80  # percent
        }
    ]

    # Generate CI/CD configuration
    ci_config = generate_ci_config(fitness_functions)

    # Setup monitoring dashboard
    dashboard_config = generate_dashboard_config(fitness_functions)

    return ci_config, dashboard_config
```

## Utility Functions

### Cycle Detection in Dependency Graphs

```python
def find_cycles(graph):
    """Find all cycles in a directed graph using DFS"""
    cycles = []
    visited = set()
    rec_stack = set()

    def dfs(node, path):
        visited.add(node)
        rec_stack.add(node)
        path.append(node)

        for neighbor in graph.get(node, []):
            if neighbor not in visited:
                if dfs(neighbor, path.copy()):
                    return True
            elif neighbor in rec_stack:
                # Found cycle
                cycle_start = path.index(neighbor)
                cycles.append(path[cycle_start:] + [neighbor])

        path.pop()
        rec_stack.remove(node)
        return False

    for node in graph:
        if node not in visited:
            dfs(node, [])

    return cycles
```

### Module Name Resolution

```python
def get_module_name(file_path, source_dir):
    """Convert file path to Python module name"""
    rel_path = Path(file_path).relative_to(Path(source_dir))

    # Remove .py extension
    module_parts = rel_path.with_suffix('').parts

    # Join with dots
    return '.'.join(module_parts)
```

### Complexity Calculation

```python
def calculate_cyclomatic_complexity(file_path):
    """Calculate cyclomatic complexity for a Python file"""
    try:
        with open(file_path) as f:
            tree = ast.parse(f.read())
    except (SyntaxError, UnicodeDecodeError) as e:
        print(f"Warning: Skipping {file_path} due to parsing error: {e}")
        return 0  # Return base complexity on error

    complexity = 1  # Base complexity

    for node in ast.walk(tree):
        # Each decision point adds to complexity
        if isinstance(node, (ast.If, ast.While, ast.For)):
            complexity += 1
        elif isinstance(node, ast.ExceptHandler):
            complexity += 1
        elif isinstance(node, ast.BoolOp):
            # and/or operators
            complexity += len(node.values) - 1

    return complexity
```