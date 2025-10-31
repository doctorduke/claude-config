# Architecture Evaluation Knowledge Base

## Table of Contents
1. [Architecture Frameworks](#architecture-frameworks)
2. [SOLID Principles](#solid-principles)
3. [C4 Model](#c4-model)
4. [4+1 Architectural Views](#41-architectural-views)
5. [ATAM Methodology](#atam-methodology)
6. [Quality Attributes](#quality-attributes)
7. [Architecture Patterns](#architecture-patterns)
8. [Coupling and Cohesion Theory](#coupling-and-cohesion-theory)
9. [Technical Debt](#technical-debt)
10. [Academic References](#academic-references)

## Architecture Frameworks

### Overview
Architecture frameworks provide structured approaches for documenting, analyzing, and evaluating system architecture. They help ensure consistent communication and comprehensive coverage of architectural concerns.

### Key Frameworks

#### C4 Model
Simon Brown's C4 model provides a hierarchical approach to architecture documentation:
- **Context**: System boundaries and external interactions
- **Container**: High-level technology choices and runtime components
- **Component**: Internal structure of containers
- **Code**: Optional detailed class/module level

#### 4+1 Architectural Views
Philippe Kruchten's model for describing software architecture:
- **Logical View**: Functional requirements (classes, objects)
- **Development View**: Software organization (packages, layers)
- **Process View**: Concurrency and synchronization
- **Physical View**: Deployment and infrastructure
- **+1 Scenarios**: Use cases tying views together

#### Arc42
Template for architecture documentation:
- Provides 12 sections covering all aspects of architecture
- Includes context, constraints, solution strategy, building blocks
- Emphasizes decision documentation and risk assessment

## SOLID Principles

### Single Responsibility Principle (SRP)
"A class should have only one reason to change"
- Each module/class should have one clear responsibility
- Changes to one aspect shouldn't affect others
- Promotes high cohesion within modules

### Open/Closed Principle (OCP)
"Software entities should be open for extension, closed for modification"
- Add new functionality without changing existing code
- Use abstractions and polymorphism
- Prevents regression bugs from modifications

### Liskov Substitution Principle (LSP)
"Subtypes must be substitutable for their base types"
- Derived classes must honor base class contracts
- No strengthening of preconditions
- No weakening of postconditions

### Interface Segregation Principle (ISP)
"Clients shouldn't depend on interfaces they don't use"
- Create small, focused interfaces
- Avoid fat interfaces with unused methods
- Reduces coupling between components

### Dependency Inversion Principle (DIP)
"Depend on abstractions, not concretions"
- High-level modules shouldn't depend on low-level modules
- Both should depend on abstractions
- Enables flexibility and testability

## C4 Model

### System Context (Level 1)
Shows the system as a box in the center, surrounded by its users and other systems it interacts with:
```
┌──────────────────────────────────────┐
│   Shows how system fits in world    │
│   Users, external systems            │
└──────────────────────────────────────┘
```

### Container (Level 2)
Zooms into the system boundary to show high-level technical building blocks:
```
┌──────────────────────────────────────┐
│   High-level tech choices            │
│   Web apps, databases, microservices │
└──────────────────────────────────────┘
```

### Component (Level 3)
Zooms into individual containers to show their internal components:
```
┌──────────────────────────────────────┐
│   Components within containers       │
│   Services, repositories, controllers│
└──────────────────────────────────────┘
```

### Code (Level 4)
Optional zoom into component implementation details:
```
┌──────────────────────────────────────┐
│   Class diagrams, implementation     │
│   (optional - usually IDE generated) │
└──────────────────────────────────────┘
```

## 4+1 Architectural Views

### View Relationships
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

### View Purposes
- **Logical**: What functionality the system provides
- **Development**: How the system is organized for development
- **Process**: How runtime processes communicate
- **Physical**: How software maps to hardware
- **Scenarios**: How the views work together

## ATAM Methodology

### Architecture Tradeoff Analysis Method
Systematic approach for evaluating architecture decisions against quality attributes.

### Quality Attribute Scenarios
```
Stimulus → System → Response
   │         │         │
   ├─ Source    ├─ Artifact    ├─ Measure
   ├─ Condition ├─ Environment └─ Response Time
   └─ Frequency
```

### Example Scenario (Performance)
- **Stimulus**: 1000 concurrent users
- **System**: Web application under peak load
- **Response**: < 200ms response time, 99th percentile

### Trade-off Analysis Process
1. Identify architectural approaches
2. Map approaches to quality attributes
3. Identify sensitivity points
4. Identify trade-off points
5. Document risks and non-risks

## Quality Attributes

### Performance
- Response time, throughput, resource utilization
- Measured through load testing, profiling
- Trade-offs with scalability and modifiability

### Scalability
- Ability to handle increased load
- Horizontal vs vertical scaling
- Trade-offs with consistency and complexity

### Availability
- System uptime and reliability
- Measured as percentage (e.g., 99.9% = 43 min/month downtime)
- Trade-offs with performance and cost

### Security
- Confidentiality, integrity, availability (CIA triad)
- Authentication, authorization, audit
- Trade-offs with usability and performance

### Modifiability
- Ease of making changes
- Measured by change effort and impact
- Trade-offs with performance and simplicity

### Testability
- Ease of testing components
- Test coverage, automation capability
- Trade-offs with encapsulation and performance

## Architecture Patterns

### Layered Architecture
- Organizes system into horizontal layers
- Each layer only communicates with adjacent layers
- Common layers: Presentation, Business, Data Access, Database
- **Pros**: Separation of concerns, testability
- **Cons**: Performance overhead, tendency toward monoliths

### Microservices
- Decomposes system into small, independent services
- Each service owns its data and business logic
- Communication via APIs or messaging
- **Pros**: Independent deployment, technology diversity, scalability
- **Cons**: Distributed complexity, network latency, data consistency

### Event-Driven Architecture
- Components communicate through events
- Loose coupling via publish-subscribe patterns
- Enables asynchronous processing
- **Pros**: Scalability, flexibility, decoupling
- **Cons**: Eventual consistency, debugging complexity

### Hexagonal Architecture (Ports and Adapters)
- Isolates core business logic from external concerns
- Ports define interfaces, adapters implement them
- Enables testing without external dependencies
- **Pros**: Testability, flexibility, clear boundaries
- **Cons**: Additional abstraction complexity

### Domain-Driven Design (DDD)
- Organizes code around business domains
- Bounded contexts separate domain models
- Ubiquitous language aligns code with business
- **Pros**: Business alignment, maintainability
- **Cons**: Learning curve, upfront design effort

## Coupling and Cohesion Theory

### Coupling Types (Worst to Best)
1. **Content Coupling**: Direct access to internal data
2. **Common Coupling**: Shared global data
3. **Control Coupling**: Passing control flags
4. **Stamp Coupling**: Passing data structures
5. **Data Coupling**: Passing only necessary data
6. **Message Coupling**: Passing messages with no data

### Cohesion Types (Worst to Best)
1. **Coincidental**: Random grouping
2. **Logical**: Similar functionality
3. **Temporal**: Executed at same time
4. **Procedural**: Part of same procedure
5. **Communicational**: Operate on same data
6. **Sequential**: Output of one is input to next
7. **Functional**: Single well-defined task

### Metrics
- **Afferent Coupling (Ca)**: Number of classes that depend on this class
- **Efferent Coupling (Ce)**: Number of classes this class depends on
- **Instability (I)**: Ce / (Ca + Ce)
- **LCOM**: Lack of Cohesion of Methods

## Technical Debt

### Types of Technical Debt
1. **Intentional Debt**: Conscious trade-offs for speed
2. **Unintentional Debt**: Lack of knowledge or poor practices
3. **Environmental Debt**: Outdated tools/frameworks
4. **Architectural Debt**: Fundamental design issues

### Quantification Methods
- **SQALE Method**: Technical debt as time to fix issues
- **Code Metrics**: Complexity, duplication, coverage
- **Architecture Metrics**: Coupling, cohesion, dependencies
- **Business Impact**: Performance degradation, feature velocity

### Management Strategies
1. Track debt in backlog
2. Allocate percentage of capacity to debt reduction
3. Refactor during feature development
4. Periodic debt sprints
5. Architectural fitness functions

## Academic References

### Foundational Works
- **Software Architecture in Practice** - Bass, Clements, Kazman
- **Design Patterns** - Gang of Four (Gamma, Helm, Johnson, Vlissides)
- **Clean Architecture** - Robert C. Martin
- **Building Evolutionary Architectures** - Ford, Parsons, Kua

### Research Papers
- "Architectural Patterns for Self-Adaptive Software Systems" - Weyns et al.
- "A Classification and Comparison Framework for Software Architecture Description Languages" - Medvidovic & Taylor
- "Managing Technical Debt in Software-Reliant Systems" - Brown et al.

### Online Resources
- [C4 Model](https://c4model.com/) - Simon Brown
- [Martin Fowler's Architecture Guide](https://martinfowler.com/architecture/)
- [SEI Architecture Resources](https://resources.sei.cmu.edu/library/asset-view.cfm?assetid=513908)
- [Microservices.io](https://microservices.io/patterns/) - Chris Richardson

### Tools and Frameworks
- [SonarQube](https://www.sonarqube.org/) - Code quality and architecture analysis
- [Dependency Cruiser](https://github.com/sverweij/dependency-cruiser) - Dependency validation
- [ArchUnit](https://www.archunit.org/) - Architecture unit testing
- [Structure101](https://structure101.com/) - Architecture visualization

## Quality Attribute Workshop (QAW)

### Process
1. **Business/Mission Presentation**: Stakeholders present drivers
2. **Architectural Plan Presentation**: Architects present approach
3. **Scenario Brainstorming**: Generate quality attribute scenarios
4. **Scenario Consolidation**: Combine similar scenarios
5. **Scenario Prioritization**: Vote on importance
6. **Scenario Refinement**: Detail top scenarios

### Scenario Template
- **Source**: Who/what generates stimulus
- **Stimulus**: What happens
- **Environment**: Under what conditions
- **Artifact**: What part of system
- **Response**: How system should respond
- **Response Measure**: How to measure response

## Architectural Fitness Functions

### Definition
Automated tests that validate architecture characteristics remain within acceptable bounds.

### Types
- **Atomic**: Test single characteristic (e.g., response time)
- **Holistic**: Test combinations (e.g., security + performance)
- **Triggered**: Run on specific events
- **Continuous**: Always running
- **Static**: Analyze code without execution
- **Dynamic**: Test running system

### Examples
```python
# Dependency fitness function
def test_no_circular_dependencies():
    graph = build_dependency_graph()
    assert not has_cycles(graph), "Circular dependencies detected"

# Performance fitness function
def test_response_time():
    response = make_request("/api/endpoint")
    assert response.time < 200, f"Response time {response.time}ms exceeds 200ms limit"

# Modularity fitness function
def test_package_coupling():
    coupling = calculate_package_coupling()
    assert coupling < 0.5, f"Package coupling {coupling} exceeds threshold"
```

### Implementation Strategy
1. Identify critical architecture characteristics
2. Define measurable thresholds
3. Implement automated tests
4. Integrate into CI/CD pipeline
5. Monitor and adjust thresholds