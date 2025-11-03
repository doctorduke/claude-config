# Reverse Engineering Tool Reference

## tree-sitter

### Purpose
Multi-language parser for static analysis.

### Installation
```bash
pip install tree-sitter
```

### Basic Usage
```python
from tree_sitter import Language, Parser

# Load language
python_lang = Language('build/my-languages.so', 'python')

# Parse code
parser = Parser()
parser.set_language(python_lang)
tree = parser.parse(bytes(source_code, "utf8"))
```

### Supported Languages
50+ including Python, JavaScript, Go, Rust, Java, C/C++

## strace (Linux)

### Purpose
Trace system calls and signals.

### Key Options
```bash
-e trace=SYSCALL    # Trace specific syscalls
-o FILE             # Output to file
-f                  # Follow child processes
-T                  # Show time spent in each call
-tt                 # Timestamps
-c                  # Summary statistics
```

### Common Traces
```bash
# File operations
strace -e trace=file ./program

# Network operations
strace -e trace=network ./program

# All syscalls
strace -o trace.log ./program
```

## Python ast Module

### Purpose
Parse Python code into Abstract Syntax Tree.

### Basic Usage
```python
import ast

with open('script.py') as f:
    tree = ast.parse(f.read())

# Walk all nodes
for node in ast.walk(tree):
    if isinstance(node, ast.FunctionDef):
        print(f"Function: {node.name}")
```

### Node Types
- FunctionDef: Function definition
- ClassDef: Class definition
- Import: Import statement
- Call: Function call
- Assign: Variable assignment

## graphviz

### Purpose
Create dependency graph visualizations.

### Installation
```bash
pip install graphviz
# Also need graphviz system package
```

### Usage
```python
import graphviz

dot = graphviz.Digraph()
dot.edge('module_a', 'module_b')
dot.render('output.png', format='png')
```

## gdb (GNU Debugger)

### Purpose
Debug programs, inspect memory, trace execution.

### Key Commands
```bash
break main          # Set breakpoint
run                 # Start program
step                # Step into function
next                # Step over function
print variable      # Print variable value
backtrace           # Show call stack
```

### Scripting
```bash
# Run gdb commands from file
gdb -x script.gdb ./program
```

## Performance Tuning

### Large Codebase Strategies
- Use incremental parsing
- Cache analysis results
- Parallel processing (multiprocessing)
- Sample first, then full analysis
- Focus on changed files only

### Memory Optimization
- Process files one at a time
- Use generators instead of lists
- Clear caches periodically
- Stream results to disk

## Supported Languages Matrix

| Language | Static Tools | Dynamic Tools | Difficulty |
|----------|-------------|---------------|------------|
| Python | ast, tree-sitter, pylint | pdb, py-spy, strace | Easy |
| JavaScript | esprima, acorn, eslint | Chrome DevTools, node --inspect | Easy |
| Java | JavaParser, ANTLR | jdb, VisualVM | Medium |
| C/C++ | libclang, cppcheck | gdb, valgrind | Hard |
| Go | go/ast, go/parser | delve, pprof | Easy |
| Rust | syn, rust-analyzer | lldb, cargo-flamegraph | Medium |
| Ruby | ripper, parser | ruby-debug | Medium |
| C# | Roslyn | dnSpy, dotTrace | Medium |

## Configuration Examples

### .pylintrc for Static Analysis
```ini
[MASTER]
ignore=migrations,tests

[MESSAGES CONTROL]
disable=C0111,C0103

[REPORTS]
output-format=colorized
```

### tree-sitter query
```scheme
; Find all function definitions
(function_definition
  name: (identifier) @func.name)
```

### strace filter
```bash
# Only show successful opens
strace -e trace=openat -e status=successful ./program
```
