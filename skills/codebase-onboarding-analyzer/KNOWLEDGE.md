# Architecture Knowledge and Theory

## Table of Contents

1. [Core Concepts](#core-concepts)
2. [Codebase Understanding Layers](#codebase-understanding-layers)
3. [Complexity Metrics Explained](#complexity-metrics-explained)
4. [Architectural Patterns](#architectural-patterns)
5. [Code Quality Indicators](#code-quality-indicators)
6. [Learning Resources](#learning-resources)

## Core Concepts

### What Is Codebase Understanding?

**Definition**: The process of comprehending how a software system is organized, how its components interact, what its dependencies are, and what quality characteristics it exhibits.

**Why It Matters**:
- Faster developer onboarding
- Better code review quality
- Informed refactoring decisions
- Risk assessment for changes
- Knowledge preservation
- Architecture documentation

### Understanding vs Memorization

**Key Distinction**:
- **Memorization**: "There's a function called `process_data()` in `utils.py`"
- **Understanding**: "The data pipeline has 5 stages: ingest → validate → transform → aggregate → export, each with clear boundaries and responsibility"

**Goal of Analysis**: Build the understanding, not memorization

### Systematic vs Ad-Hoc Analysis

**Ad-Hoc**: Exploring as you go (useful but incomplete)

**Systematic**: Structured approach covering:
1. Structure (how is code organized?)
2. Dependencies (what depends on what?)
3. Complexity (where is it hard?)
4. Quality (how well is it written?)
5. Documentation (what exists to explain things?)

## Codebase Understanding Layers

### Layer 1: Surface Layer

**What to Analyze**:
- Languages and frameworks used
- Build system and package manager
- Directory structure and organization
- Entry points and how to run code
- Technology stack

**Key Questions**:
- What language(s) is this written in?
- What framework(s) are used?
- How is the codebase organized?
- How do I run this?
- What build tools are needed?

**Tools**: tokei, file system analysis, package managers

**Time to Understand**: 15-30 minutes

### Layer 2: Dependency Layer

**What to Analyze**:
- External dependencies (frameworks, libraries, packages)
- Internal module dependencies
- Dependency graphs and cycles
- Import patterns
- Coupling between modules

**Key Questions**:
- What external packages does this depend on?
- How do modules depend on each other?
- Are there circular dependencies?
- Which modules are tightly coupled?
- What's the dependency hierarchy?

**Tools**: madge, pydeps, godepgraph, cargo tree

**Time to Understand**: 30-60 minutes

**Key Metric**: Coupling (number of dependencies)

### Layer 3: Architecture Layer

**What to Analyze**:
- Design patterns used
- Component boundaries
- Layer separation (if layered architecture)
- Service interactions
- Data flow paths

**Key Questions**:
- What architectural pattern(s) are used? (MVC, microservices, layered, etc.)
- How are components separated?
- Where are the boundaries?
- How do components communicate?
- What's the data flow?

**Tools**: Code review, architecture visualization, entry point analysis

**Time to Understand**: 1-2 hours

### Layer 4: Code Quality Layer

**What to Analyze**:
- Complexity metrics (cyclomatic, cognitive)
- Code smells
- Test coverage
- Technical debt
- Maintainability indicators

**Key Questions**:
- How complex is the code?
- Are there code smells?
- What's the test coverage?
- Where's the technical debt?
- How maintainable is it?

**Tools**: radon, linters, coverage tools, complexity analyzers

**Time to Understand**: 1-2 hours

### Layer 5: Data Flow Layer

**What to Analyze**:
- State management
- Data transformations
- Side effects
- API contracts
- Data persistence

**Key Questions**:
- How does data flow through the system?
- What state is managed where?
- What transformations happen?
- What side effects exist?
- What are the API contracts?

**Tools**: Code review, tracing, documentation analysis

**Time to Understand**: 2-4 hours

## Complexity Metrics Explained

### Cyclomatic Complexity (CC)

**Definition**: Number of independent paths through code

**Calculation**: Count decision points (if, while, for, case, &&, ||, ternary)

**Example**:
```python
def simple(x):  # CC = 1
    return x * 2

def moderate(x):  # CC = 3
    if x > 0:
        return x * 2
    elif x < 0:
        return x * -1
    else:
        return 0
```

**Interpretation**:
- 1-5: Simple, easy to test
- 6-10: Moderate complexity
- 11-20: Complex, hard to test, plan refactoring
- 21+: Very complex, refactor immediately

**Limitations**:
- Doesn't account for nesting depth
- Different tools calculate slightly differently
- Language-dependent (match statements vs if/else)

### Cognitive Complexity

**Definition**: How hard code is to understand (more practical than cyclomatic)

**Factors**:
- Nested control flow
- Recursion
- Non-linear logic
- Long methods
- Multiple decision points

**Advantages**:
- Better predictor of maintainability
- Accounts for code nesting
- Reflects developer perspective

**Example**:
```python
# High cyclomatic, low cognitive (straightforward)
def process(items):
    match item_type:
        case TYPE_A:
            return process_a()
        case TYPE_B:
            return process_b()
        case TYPE_C:
            return process_c()

# Low cyclomatic, high cognitive (confusing)
def calculate(x):
    return ((x > 0 and x < 100) or x == 0) and (
        (y > 0 and y < 50) or y == 0
    ) if condition else None
```

### Maintainability Index (MI)

**Definition**: Combined metric (0-100 scale)

**Factors**:
- Lines of code per file
- Cyclomatic complexity
- Halstead volume (code metrics)
- Comment percentage

**Interpretation**:
- 85-100: Highly maintainable (green)
- 65-84: Good maintainability (yellow)
- 50-64: Moderate, improvement needed (orange)
- 0-49: Difficult to maintain (red)

**How to Improve**:
- Reduce file size
- Lower complexity
- Add comments
- Refactor complex functions

### Instability (I)

**Definition**: Measure of a module's resistance to change

**Calculation**: I = Efferent / (Afferent + Efferent)

**Terms**:
- **Efferent Coupling**: Outgoing dependencies (this module depends on others)
- **Afferent Coupling**: Incoming dependencies (other modules depend on this)

**Interpretation**:
- I = 0: Maximally stable (nothing depends on it)
- I = 1: Maximally unstable (only depends on others)
- I = 0.5: Balanced
- Ideal range: 0.3-0.7

**Analysis**:
- High I (>0.8): Core library, but frequently changed
- Low I (<0.2): Few dependents, but many dependencies
- Stable modules (low I) should be rarely changed
- Volatile modules (high I) should be depended on minimally

## Architectural Patterns

### Monolithic Architecture

**Characteristics**:
- Single codebase and deployment
- All code runs in same process
- Shared database
- Tightly coupled components

**Indicators in Analysis**:
- Single entry point
- All modules depend on each other
- Large overall complexity

**When Suitable**:
- Small teams
- Simple domains
- High performance needed
- Development simplicity priority

**Challenges**:
- Scaling individual features difficult
- High coupling
- Technology lock-in

### Microservices Architecture

**Characteristics**:
- Multiple independent services
- Separate deployments
- Service-specific databases
- Communication via APIs

**Indicators in Analysis**:
- Multiple independent entry points
- Clear service boundaries
- Separate dependency graphs
- Event-driven communication

**When Suitable**:
- Large teams
- Complex domains
- Independent scaling needed
- Heterogeneous technologies acceptable

**Challenges**:
- Distributed system complexity
- Data consistency
- Operational overhead
- Network latency

### MVC (Model-View-Controller)

**Separation**:
- **Models**: Data and business logic
- **Views**: Presentation layer
- **Controllers**: Request handling and coordination

**Identified By**:
- Files named `models.py`, `views.py`, `controllers.js`
- Clear separation of concerns
- Controller entry points to views

**Common In**: Django, Rails, Spring MVC

### Layered Architecture

**Typical Layers**:
1. **Presentation** (UI, API endpoints)
2. **Business Logic** (Services, domain logic)
3. **Data Access** (Repositories, DAOs)
4. **Database** (Persistence layer)

**Identified By**:
- Directory structure: `presentation/`, `service/`, `repository/`
- Strict dependency direction (downward)
- Clear separation of concerns

**Advantages**:
- Clear separation of concerns
- Easy to understand
- Easy to scale horizontally

**Disadvantages**:
- Layer coupling
- Performance (many layers)
- Not suitable for microservices

### Event-Driven Architecture

**Components**:
- Event producers
- Event brokers/buses
- Event consumers

**Communication**: Asynchronous via events

**Identified By**:
- Message queues
- Event handlers
- Publish-subscribe patterns
- Decoupled components

**Common In**: Real-time systems, reactive frameworks

## Code Quality Indicators

### High-Quality Codebase Signals

1. **Low Complexity**: Most functions < 10 CC
2. **Good Test Coverage**: >80% coverage
3. **Clear Documentation**: Self-documenting code + comments
4. **Few Dependencies**: Minimal coupling
5. **Small File Sizes**: Most files < 300 lines
6. **Consistent Style**: Linters pass
7. **No Code Duplication**: DRY principles followed
8. **Clear Naming**: Variables/functions clearly named
9. **Separation of Concerns**: Single responsibility
10. **Updated Documentation**: Matches current code

### Warning Signs of Technical Debt

1. **High Complexity**: Functions with CC > 20
2. **Low Coverage**: <50% test coverage
3. **Outdated Documentation**: Doesn't match code
4. **Circular Dependencies**: Modules depend on each other
5. **Large Files**: Files > 500 lines
6. **Dead Code**: Unused imports/functions
7. **Code Duplication**: Copy-pasted code sections
8. **Poor Naming**: Cryptic variable names
9. **No Tests**: Critical paths untested
10. **Inconsistent Style**: Mixed conventions

### Technical Debt Quadrant

```
        | Obvious    | Hidden
───────────────────────────────
Reckless| Wow        | Yikes
(Aware) | (quick)    | (fast but risky)
───────────────────────────────
Prudent | Hmm        | Well Advised
(Not    | (good)     | (slow but solid)
aware)  |            |
```

**Strategy**: Move toward prudent/obvious (known debt) from reckless/hidden

## Learning Resources

### Classic Books

**[Software Architecture Patterns](https://www.oreilly.com/library/view/software-architecture-patterns/9781491971437/)**
- O'Reilly publication
- Covers layered, event-driven, microservices
- Practical, illustrated examples

**[Code Complete](https://www.microsoftpressstore.com/store/code-complete-9780735619678)**
- Steve McConnell
- Comprehensive software construction guide
- Complexity and metrics deep-dive

**[Clean Architecture](https://www.oreilly.com/library/view/clean-architecture-a/9780134494166/)**
- Robert C. Martin
- Dependency management
- Architectural principles

**[Refactoring](https://refactoring.com/)**
- Martin Fowler
- Catalog of refactoring techniques
- When and how to refactor

**[The Pragmatic Programmer](https://pragprog.com/titles/tpp20/)**
- Hunt & Thomas
- Practical software development
- Technical debt management

### Architecture Resources

**[Structurizr](https://structurizr.com/)**
- C4 model documentation
- Architecture as code approach
- Cloud-based collaboration

**[PlantUML](https://plantuml.com/)**
- UML diagrams as text
- Easy version control
- Multiple output formats

**[ArchiMate](https://pubs.opengroup.org/architecture/archimate3-doc/)**
- Enterprise architecture modeling language
- Formal notation for architecture

### Complexity Resources

**[Cyclomatic Complexity](https://en.wikipedia.org/wiki/Cyclomatic_complexity)**
- Wikipedia definition
- Historical context
- Limitations

**[Maintainability Index](https://en.wikipedia.org/wiki/Maintainability_index)**
- Formula and interpretation
- Practical application

### SOLID Principles

**Single Responsibility**: Class should have one reason to change

**Open/Closed**: Open for extension, closed for modification

**Liskov Substitution**: Derived classes should be substitutable

**Interface Segregation**: Many specific interfaces > one general interface

**Dependency Inversion**: Depend on abstractions, not concretions

### DRY (Don't Repeat Yourself)

**Principle**: Every piece of knowledge should have a single source of truth

**Application**:
- Extract duplicate code into functions
- Use inheritance for shared behavior
- Create reusable components
- Centralize configuration

### YAGNI (You Aren't Gonna Need It)

**Principle**: Don't implement features you don't currently need

**Balance with DRY**:
- Write for current needs
- Refactor when pattern emerges
- Avoid premature generalization

## Analysis Workflow

### Quick Understanding (30 minutes)

1. Run surface analysis (tokei, directory structure)
2. Identify entry points
3. Check README and key files
4. Skim main modules
5. Document findings

### Moderate Understanding (2 hours)

1. Complete surface analysis
2. Map dependencies
3. Check for circular deps
4. Analyze complexity metrics
5. Identify patterns
6. Create architecture diagram

### Deep Understanding (4-8 hours)

1. Complete layers 1-5 analysis
2. Code review critical paths
3. Trace data flows
4. Document findings comprehensively
5. Create onboarding guide
6. Present to team

## Related Documentation

- `PATTERNS.md` - Language-specific pattern examples
- `REFERENCE.md` - Tool-specific resources
- `EXAMPLES.md` - Real-world architecture examples
- `GOTCHAS.md` - Common pitfalls in analysis
