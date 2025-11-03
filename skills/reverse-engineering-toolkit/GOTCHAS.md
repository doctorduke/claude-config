# Reverse Engineering Gotchas

## 1. Obfuscated Code Challenges

### Problem
Code intentionally made hard to understand through:
- Minification (single-letter variables)
- Obfuscation (control flow flattening)
- Packing/encryption
- Dead code insertion

### Solutions

**JavaScript Minification**:
```bash
# Use beautifier first
js-beautify obfuscated.min.js > readable.js
```

**Python Bytecode**:
```bash
# Decompile .pyc files
uncompyle6 module.pyc > module.py
```

**General Approach**:
- Focus on runtime behavior (dynamic analysis)
- Use deobfuscation tools
- Analyze I/O patterns
- Look for string constants (often not obfuscated)

## 2. Large Codebase Performance Issues

### Problem
Analysis tools timeout or run out of memory on codebases with:
- Millions of lines of code
- Thousands of files
- Deep dependency chains

### Solutions

**Incremental Analysis**:
```python
# Analyze one module at a time
for module in modules:
    analysis = analyzer.analyze_file(module)
    cache.save(module, analysis)
```

**Sampling**:
```python
# Analyze random 10% sample first
sample = random.sample(all_files, len(all_files) // 10)
quick_analysis = [analyze(f) for f in sample]
```

**Parallel Processing**:
```python
from multiprocessing import Pool
with Pool(8) as p:
    results = p.map(analyze_file, files)
```

## 3. Dynamic Language Challenges

### Problem
Languages like Python, JavaScript, Ruby have:
- Dynamic typing (type unknown until runtime)
- Runtime code generation (eval, exec)
- Monkey patching
- Dynamic imports

### Solutions

**Type Inference**:
```python
# Use type hints if available
from typing import get_type_hints
hints = get_type_hints(function)
```

**Runtime Instrumentation**:
```python
# Trace actual types at runtime
def trace_types(frame, event, arg):
    if event == 'call':
        for var, value in frame.f_locals.items():
            print(f"{var}: {type(value)}")
```

**Hybrid Analysis**:
- Static analysis for structure
- Dynamic analysis for types and behavior

## 4. Incomplete Symbol Information

### Problem
Missing debug symbols in binaries:
- Function names are addresses
- Variable names stripped
- Type information unavailable

### Solutions
- Use symbol databases (if available)
- Infer function purpose from behavior
- Look for string references
- Analyze calling patterns

## 5. Build System Complexity

### Problem
Can't build/run the code:
- Missing dependencies
- Complex build process
- Platform-specific requirements

### Solutions
- Static analysis only (don't need to build)
- Use containers for reproducible builds
- Study build scripts to understand dependencies
- Partial analysis of buildable modules

## 6. Circular Dependencies

### Problem
Modules depend on each other circularly.

### Detection
```python
def find_cycles(graph):
    visited = set()
    path = []
    cycles = []

    def dfs(node):
        if node in path:
            cycles.append(path[path.index(node):])
            return
        if node in visited:
            return

        visited.add(node)
        path.append(node)
        for neighbor in graph.get(node, []):
            dfs(neighbor)
        path.pop()

    for node in graph:
        dfs(node)

    return cycles
```

### Solutions
- Visualize to understand cycle
- Consider refactoring to break cycle
- Document as architectural issue

## Debugging Strategies

### When Static Analysis Fails
1. Try dynamic analysis instead
2. Manually trace critical paths
3. Use debugger to step through
4. Focus on public APIs (interfaces)

### When Dynamic Analysis Fails
1. Check test environment matches production
2. Verify all inputs provided
3. Look at logs/traces for errors
4. Try simpler inputs first

### When Both Fail
1. Ask for documentation (even if incomplete)
2. Contact original developers if possible
3. Search for similar codebases
4. Reverse engineer incrementally (start small)
