# Reverse Engineering Knowledge Base

## Core Concepts

### What is Reverse Engineering?

Reverse engineering is the process of extracting design and implementation information from a finished product (software, hardware, or system) to understand how it works, how it was built, and how to modify or replicate it.

**Key aspects**:
- Analysis over synthesis (decompose rather than build)
- Discovery over documentation (observe rather than read specs)
- Inference over instruction (deduce rather than follow)

### Types of Reverse Engineering Analysis

#### 1. Black-Box Analysis
**Definition**: Understanding system behavior without access to internals

**Characteristics**:
- Only inputs and outputs observed
- Internal structure unknown
- Behavior inferred from testing
- Common for closed-source systems

**Techniques**:
- Fuzzing (systematic input testing)
- Network traffic analysis
- API endpoint discovery
- Behavioral observation

**Example**: Understanding Twitter API by making requests and observing responses

#### 2. White-Box Analysis
**Definition**: Full access to source code and internal structure

**Characteristics**:
- Complete visibility into implementation
- Can read all code
- Can modify and instrument
- Common for legacy code modernization

**Techniques**:
- Source code reading
- AST parsing and analysis
- Control flow graph generation
- Data flow analysis

**Example**: Analyzing open-source library to understand design patterns

#### 3. Gray-Box Analysis
**Definition**: Partial access - some source, some binaries, some documentation

**Characteristics**:
- Mix of available and unavailable information
- Combine multiple techniques
- Fill gaps through inference
- Most common in practice

**Techniques**:
- Hybrid static/dynamic analysis
- Combining docs with code inspection
- Using available source to understand binaries

**Example**: Analyzing framework with public API docs but private implementation

## Static vs Dynamic Analysis

### Static Analysis

**Definition**: Examining code without executing it

**Advantages**:
- Complete code coverage possible
- No need for test environments
- Can analyze all paths (even error paths)
- Safe (no risk of executing malicious code)

**Disadvantages**:
- May miss runtime behavior
- Dynamic features hard to analyze (reflection, eval)
- Approximations may have false positives

**Key Techniques**:
```
- Abstract Syntax Tree (AST) parsing
- Control Flow Graph (CFG) construction
- Data Flow Analysis (DFA)
- Taint analysis
- Symbol table extraction
- Type inference
```

**Tools**:
- tree-sitter: Multi-language parser
- libclang: C/C++ analysis
- JavaParser: Java AST analysis
- esprima/acorn: JavaScript parsing
- ast module (Python): Built-in AST parsing

### Dynamic Analysis

**Definition**: Observing program execution at runtime

**Advantages**:
- See actual behavior (not approximation)
- Observe real data values
- Understand performance characteristics
- Detect runtime-only features

**Disadvantages**:
- Only covers executed paths
- Requires test environment
- May have side effects
- Slower than static analysis

**Key Techniques**:
```
- Execution tracing
- Memory inspection
- System call monitoring
- Network traffic capture
- Performance profiling
- Debugging
```

**Tools**:
- strace/dtrace: System call tracing
- gdb/lldb: Debuggers
- Valgrind: Memory analysis
- Wireshark: Network analysis
- perf/py-spy: Performance profiling

## Program Comprehension Techniques

### Bottom-Up Approach
Start with details (individual functions) → build understanding → reach high-level architecture

**Best for**:
- Well-structured code
- When looking for specific functionality
- Detailed understanding needed

**Process**:
1. Identify interesting function
2. Analyze implementation
3. Find callers and callees
4. Build local understanding
5. Connect to larger context

### Top-Down Approach
Start with architecture → understand modules → drill into details as needed

**Best for**:
- Getting overview quickly
- Large codebases
- Identifying components

**Process**:
1. Identify entry points (main, server, etc.)
2. Map high-level structure
3. Identify major modules
4. Understand interactions
5. Dive into details selectively

### Opportunistic Approach
Follow interesting paths as discovered, combining top-down and bottom-up

**Best for**:
- Exploratory analysis
- Complex systems
- When goals are unclear

**Process**:
1. Start anywhere interesting
2. Follow connections
3. Build understanding incrementally
4. Revisit and refine mental model

## Dependency Analysis Theory

### Types of Dependencies

#### 1. Structural Dependencies
- Import/include statements
- Module references
- Package dependencies

#### 2. Functional Dependencies
- Function calls
- Method invocations
- Callback registrations

#### 3. Data Dependencies
- Variable usage
- Data flow
- Shared state

#### 4. Temporal Dependencies
- Execution order requirements
- Initialization sequences
- Resource lifecycle

### Dependency Metrics

**Coupling**: Degree of interdependence between modules
- Tight coupling: Hard to change one without affecting others
- Loose coupling: Modules can change independently

**Cohesion**: How focused a module's responsibilities are
- High cohesion: Module has single, well-defined purpose
- Low cohesion: Module does many unrelated things

**Cyclic Dependencies**: Circular reference chains
- Create tight coupling
- Hard to understand and test
- Indicate architectural issues

### Dependency Graph Analysis

**Graph Metrics**:
- In-degree: How many modules depend on this one (used by)
- Out-degree: How many modules this one depends on (uses)
- Centrality: Importance in the graph
- Connected components: Independent subsystems

**Common Patterns**:
- Hub: High in-degree (many depend on it) - utility modules
- Sink: High out-degree (depends on many) - composition modules
- Island: Low connectivity - independent feature

## Pattern Recognition Algorithms

### Structural Pattern Matching

**Goal**: Identify code structures matching known patterns

**Approach**:
1. Define pattern signature (AST structure)
2. Search codebase for matches
3. Validate semantic correctness
4. Report findings

**Example - Singleton Detection**:
```python
# Pattern signature:
- Private static instance variable
- Private constructor
- Public static getInstance() method
- Returns single instance
```

### Behavioral Pattern Matching

**Goal**: Identify patterns by runtime behavior

**Approach**:
1. Define expected behavior
2. Instrument code
3. Execute with test inputs
4. Match observed behavior to pattern

**Example - Observer Detection**:
```python
# Behavioral signature:
- Subject maintains list of observers
- Subject notifies all on state change
- Observers update in response
```

### Design Pattern Catalog

**Creational Patterns**:
- Singleton: Ensure single instance
- Factory: Create objects without specifying exact class
- Builder: Construct complex objects step-by-step
- Prototype: Clone existing objects

**Structural Patterns**:
- Adapter: Convert interface to another
- Decorator: Add behavior to objects
- Facade: Simplified interface to complex system
- Proxy: Placeholder for another object

**Behavioral Patterns**:
- Observer: Subscribe to state changes
- Strategy: Encapsulate algorithms
- Command: Encapsulate requests as objects
- Iterator: Sequential access to elements

## Tools Comparison

### AST/Parsing Tools

| Tool | Languages | Strengths | Use Case |
|------|-----------|-----------|----------|
| tree-sitter | 50+ languages | Fast, incremental, syntax highlighting | Multi-language analysis |
| libclang | C/C++ | Complete, accurate, C++ templates | Deep C++ analysis |
| JavaParser | Java | Full Java support, symbol resolution | Java refactoring |
| esprima/acorn | JavaScript | ES6+ support, fast | JavaScript analysis |
| ast (Python) | Python | Built-in, no dependencies | Python scripts |

### Dynamic Analysis Tools

| Tool | Platform | Strengths | Use Case |
|------|----------|-----------|----------|
| strace | Linux | System calls, file access | Understanding I/O behavior |
| dtrace | BSD/Mac | Low overhead, production use | Performance analysis |
| gdb | Multi | Full debugger, scriptable | Deep debugging |
| Valgrind | Linux | Memory errors, leaks | Memory analysis |
| Wireshark | Multi | Network protocol analysis | API reverse engineering |

### Reverse Engineering Platforms

| Tool | Type | Strengths | Use Case |
|------|------|-----------|----------|
| Ghidra | Disassembler | Free, NSA-developed, multi-arch | Binary analysis |
| IDA Pro | Disassembler | Industry standard, powerful | Professional RE |
| radare2 | Framework | Open-source, scriptable | Automated analysis |
| Binary Ninja | Disassembler | Modern UI, HLIL | Interactive analysis |

### Dependency Analysis Tools

| Tool | Language | Strengths | Use Case |
|------|----------|-----------|----------|
| pydeps | Python | Visual graphs, filtering | Python dependency viz |
| madge | JavaScript | CommonJS/ES6, circular detection | JS dependency analysis |
| jdeps | Java | Built-in, accurate | Java module analysis |
| go mod graph | Go | Built-in, simple | Go module dependencies |

## Academic References

### Foundational Papers

1. **"Program Comprehension: A Survey"** - von Mayrhauser & Vans (1995)
   - Comprehensive survey of program understanding
   - Top-down vs bottom-up vs opportunistic models
   - Cognitive aspects of code reading

2. **"Design Pattern Detection Using Similarity Scoring"** - Tsantalis et al. (2006)
   - Automated pattern recognition techniques
   - Similarity metrics for pattern matching
   - Validation on real systems

3. **"Static Analysis: A Survey"** - Bessey et al. (2010)
   - Overview of static analysis techniques
   - Industrial applications
   - False positive reduction

### Reverse Engineering Methodology

4. **"A Taxonomy of Reverse Engineering and Design Recovery Techniques"** - Canfora & Di Penta (2007)
   - Classification of RE techniques
   - Tool comparison framework
   - Application domains

5. **"Understanding Software Systems Using Reverse Engineering Technology"** - Muller et al. (2000)
   - Practical RE approaches
   - Tool-supported analysis
   - Case studies

### Dependency Analysis

6. **"Analyzing Dependencies to Improve Modularity"** - Wong et al. (2011)
   - Dependency metrics
   - Refactoring recommendations
   - Modularity assessment

7. **"Detecting Structural Design Patterns in Java"** - Gueheneuc & Antoniol (2008)
   - Pattern detection algorithms
   - Precision and recall analysis
   - Tool evaluation

## Key Concepts Summary

### Mental Models for Reverse Engineering

**The Archaeologist Model**:
- System is ancient artifact
- Must be carefully excavated
- Context provides meaning
- Documentation is discovered, not given

**The Detective Model**:
- System is crime scene
- Evidence must be gathered
- Hypotheses must be tested
- Truth emerges from clues

**The Cartographer Model**:
- System is unexplored territory
- Must be mapped systematically
- Landmarks guide navigation
- Multiple maps needed (structure, behavior, data)

### Key Principles

1. **Start Broad, Go Deep**: Overview first, details later
2. **Follow the Data**: Data flow reveals structure
3. **Test Hypotheses**: Verify assumptions with experiments
4. **Document As You Go**: Memory fades, write it down
5. **Use Multiple Techniques**: Cross-validate findings
6. **Focus on Interfaces**: Boundaries reveal design
7. **Understand Context**: Why it was built this way matters

## Further Reading

### Online Resources
- Reverse Engineering Stack Exchange: https://reverseengineering.stackexchange.com/
- Trail of Bits Blog: https://blog.trailofbits.com/
- Hasherezade's Blog: https://hshrzd.wordpress.com/

### Courses
- "Reverse Engineering 101" - Malware Unicorn
- "Reverse Engineering for Beginners" - Dennis Yurichev
- "Binary Analysis" - RPI CSCI 4974

### Communities
- r/ReverseEngineering: Reddit community
- RE Discord servers
- DEF CON and Black Hat conferences
