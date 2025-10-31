# Knowledge Base

Code analysis concepts, tools comparison, and best practices.

**Parent:** [SKILL.md](./SKILL.md)

## Table of Contents

1. [Codebase Understanding Layers](#codebase-understanding-layers)
2. [Complexity Metrics](#complexity-metrics)
3. [Code Analysis Tools](#code-analysis-tools)
4. [Architecture Visualization](#architecture-visualization)
5. [Documentation Generators](#documentation-generators)
6. [Best Practices](#best-practices)

## Core Concepts

### Codebase Understanding Layers

```
┌─────────────────────────────────────────┐
│  Surface Layer                          │
│  ├── Languages & Frameworks             │
│  ├── Build System & Package Manager     │
│  └── Directory Structure                │
├─────────────────────────────────────────┤
│  Dependency Layer                       │
│  ├── External Dependencies              │
│  ├── Internal Module Dependencies       │
│  └── Dependency Graph & Cycles          │
├─────────────────────────────────────────┤
│  Architecture Layer                     │
│  ├── Design Patterns                    │
│  ├── Component Boundaries               │
│  ├── Layer Separation                   │
│  └── Service Interactions               │
├─────────────────────────────────────────┤
│  Code Quality Layer                     │
│  ├── Complexity Metrics                 │
│  ├── Code Smells                        │
│  ├── Test Coverage                      │
│  └── Technical Debt                     │
├─────────────────────────────────────────┤
│  Data Flow Layer                        │
│  ├── State Management                   │
│  ├── Data Transformations               │
│  ├── Side Effects                       │
│  └── API Contracts                      │
└─────────────────────────────────────────┘
```

### Complexity Metrics

**Cyclomatic Complexity** - Number of independent paths through code
- 1-10: Simple, easy to test
- 11-20: Moderate complexity
- 21-50: High complexity, hard to test
- 50+: Very high, refactor recommended

**Cognitive Complexity** - How hard code is to understand
- Measures nested control flow, recursion, and non-linear logic
- Better predictor of maintainability than cyclomatic

**Maintainability Index** - Combined metric (0-100)
- 85-100: Highly maintainable
- 65-85: Moderate maintainability
- 0-65: Difficult to maintain



## Knowledge Resources

### Code Analysis Tools

**Multi-Language:**
- [tree-sitter](https://tree-sitter.github.io/tree-sitter/) - Fast, incremental parser for syntax trees
- [ctags](https://github.com/universal-ctags/ctags) - Universal source code indexing
- [tokei](https://github.com/XAMPPRocky/tokei) - Fast code statistics
- [cloc](https://github.com/AlDanial/cloc) - Count lines of code
- [scc](https://github.com/boyter/scc) - Sloc Cloc and Code (faster alternative)

**Python:**
- [radon](https://radon.readthedocs.io/) - Complexity metrics (cyclomatic, maintainability)
- [pydeps](https://github.com/thebjorn/pydeps) - Dependency visualization
- [pyreverse](https://pylint.pycqa.org/en/latest/pyreverse.html) - UML diagrams from code
- [vulture](https://github.com/jendrikseipp/vulture) - Dead code detection
- [bandit](https://bandit.readthedocs.io/) - Security issue scanner

**JavaScript/TypeScript:**
- [madge](https://github.com/pahen/madge) - Dependency graph visualization
- [complexity-report](https://github.com/escomplex/complexity-report) - Complexity analysis
- [dependency-cruiser](https://github.com/sverweij/dependency-cruiser) - Dependency validation
- [ts-morph](https://ts-morph.com/) - TypeScript AST manipulation
- [jscpd](https://github.com/kucherenko/jscpd) - Copy-paste detector

**Go:**
- [gocyclo](https://github.com/fzipp/gocyclo) - Cyclomatic complexity
- [go-callvis](https://github.com/ofabry/go-callvis) - Call graph visualization
- [godepgraph](https://github.com/kisielk/godepgraph) - Dependency graphs
- [staticcheck](https://staticcheck.io/) - Advanced linter

**Rust:**
- [cargo-modules](https://github.com/regexident/cargo-modules) - Module structure visualization
- [cargo-geiger](https://github.com/rust-secure-code/cargo-geiger) - Unsafe code detection
- [cargo-tree](https://doc.rust-lang.org/cargo/commands/cargo-tree.html) - Dependency tree

**Java:**
- [JDepend](https://github.com/clarkware/jdepend) - Design quality metrics
- [ArchUnit](https://www.archunit.org/) - Architecture testing
- [Checkstyle](https://checkstyle.org/) - Code quality checks
- [PMD](https://pmd.github.io/) - Source code analyzer

### Architecture Visualization

- [PlantUML](https://plantuml.com/) - UML diagrams from text
- [Mermaid](https://mermaid.js.org/) - Diagrams and flowcharts from markdown
- [Graphviz](https://graphviz.org/) - Graph visualization
- [Structurizr](https://structurizr.com/) - C4 model architecture diagrams
- [Archi](https://www.archimatetool.com/) - ArchiMate modeling tool

### Documentation Generators

- [Sphinx](https://www.sphinx-doc.org/) - Python documentation
- [JSDoc](https://jsdoc.app/) - JavaScript documentation
- [TypeDoc](https://typedoc.org/) - TypeScript documentation
- [rustdoc](https://doc.rust-lang.org/rustdoc/) - Rust documentation
- [Javadoc](https://www.oracle.com/technical-resources/articles/java/javadoc-tool.html) - Java documentation
- [Doxygen](https://www.doxygen.nl/) - Multi-language documentation



## Best Practices

### DO's

1. **Start Broad, Then Deep** - Overview first, details second
2. **Automate Analysis** - Use scripts for consistency
3. **Version Documentation** - Keep architecture docs in Git
4. **Update Regularly** - Re-run analysis after major changes
5. **Focus on Patterns** - Look for architectural patterns first
6. **Identify Entry Points** - Understand how to run the system
7. **Track Complexity** - Monitor technical debt over time
8. **Use Visualization** - Graphs aid understanding
9. **Document Findings** - Share insights with team
10. **Prioritize Understanding** - Metrics serve understanding, not vice versa

### DON'Ts

1. **Don't Over-Analyze** - Paralysis by analysis is real
2. **Don't Ignore Tests** - Test code reveals usage patterns
3. **Don't Trust Metrics Blindly** - Context matters
4. **Don't Skip Manual Review** - Automated analysis isn't complete
5. **Don't Analyze Generated Code** - Filter build artifacts
6. **Don't Forget Documentation** - Existing docs provide context
7. **Don't Ignore Git History** - History reveals evolution
8. **Don't Analyze in Isolation** - Talk to maintainers



## Dependency Analysis Theory

### Coupling Metrics

**Afferent Coupling (Ca)** - Number of classes that depend on this class
- Measures incoming dependencies
- High Ca = many classes depend on this (stable)

**Efferent Coupling (Ce)** - Number of classes this class depends on
- Measures outgoing dependencies
- High Ce = depends on many others (unstable)

**Instability (I)** = Ce / (Ca + Ce)
- Range: 0 to 1
- 0 = maximally stable (abstract)
- 1 = maximally unstable (concrete)

### Dependency Inversion Principle

**Stable Abstractions Principle:**
- Stable packages should be abstract
- Unstable packages should be concrete

**Main Sequence Distance:**
D = | A + I - 1 |
- A = Abstractness (abstract classes / total classes)
- I = Instability
- D close to 0 = good balance

### Circular Dependencies

**Types:**
1. **Direct** - A → B → A
2. **Indirect** - A → B → C → A
3. **Self-reference** - A → A

**Breaking strategies:**
1. Introduce abstraction layer
2. Use dependency injection
3. Apply mediator pattern
4. Merge cyclic components

## Architecture Patterns

### Layered Architecture

```
┌─────────────────────┐
│   Presentation      │ ← UI, Controllers
├─────────────────────┤
│   Business Logic    │ ← Services, Domain
├─────────────────────┤
│   Data Access       │ ← Repositories, DAO
├─────────────────────┤
│   Database          │ ← Persistence
└─────────────────────┘
```

**Detection:**
- Look for packages named: ui, service, repository, model
- Check import patterns (upper layers shouldn't import lower)

### Hexagonal (Ports & Adapters)

```
      ┌─────────────┐
      │   Adapters  │ (HTTP, CLI, Queue)
      └──────┬──────┘
             │
      ┌──────▼──────┐
      │    Ports    │ (Interfaces)
      └──────┬──────┘
             │
      ┌──────▼──────┐
      │   Domain    │ (Core Logic)
      └─────────────┘
```

**Detection:**
- Look for port/adapter packages
- Interfaces separating core from infrastructure
- Inversion of control pattern

### Microservices

**Detection patterns:**
- Multiple independent deployables
- Each service has own database
- API gateway or service mesh
- Event-driven communication

### Event-Driven

**Detection:**
- Event bus or message queue
- Publisher/subscriber pattern
- Event handlers
- Saga pattern for transactions
