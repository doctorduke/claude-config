# Common Analysis Gotchas and Pitfalls

## Overview

When analyzing codebases, many things can mislead or invalidate analysis results. This guide documents common pitfalls and solutions.

## Table of Contents

1. [Code Organization Issues](#code-organization-issues)
2. [Metrics Misinterpretation](#metrics-misinterpretation)
3. [Tool Limitations](#tool-limitations)
4. [Language-Specific Gotchas](#language-specific-gotchas)
5. [Monorepo Challenges](#monorepo-challenges)
6. [Legacy Code Issues](#legacy-code-issues)

## Code Organization Issues

### Generated Code Skews Metrics

**Problem**: Build artifacts and generated code inflate complexity and LOC metrics.

**Common Sources**:
- Compiled output: `dist/`, `build/`, `out/`
- Generated SQL: ORM-generated migration files
- Minified code: `*.min.js`
- Bundle artifacts: Webpack bundles
- Protobuf/gRPC generated code
- OpenAPI client generators

**Solution**:
```bash
# Explicitly exclude generated code
radon cc . --exclude="dist,build,node_modules,*.min.js"

# Use .codemetrics or similar ignore file
# Configure in analysis tools:
# .madgerc.json:
{
  "excludeRegExp": ["node_modules", "dist"]
}
```

**Analysis Impact**: Generated code can increase metrics by 30-50% falsely

### node_modules and Dependencies

**Problem**: Including `node_modules/`, `venv/`, `.m2/` in analysis inflates metrics dramatically.

**Gotcha**: These are often in Git repo or analysis scope.

**Solution**:
```bash
# Exclude from analysis
find . -type d -name "node_modules" -prune -o -type f -name "*.py"

# Use gitignore patterns
grep "^node_modules" .gitignore
```

**Impact**: Can increase analysis time by 10x and metrics by 100%+

### Test Code Confounds Metrics

**Problem**: Test files have different complexity patterns than production code.

Test patterns inflate:
- Cyclomatic complexity (many branches for different test cases)
- File count metrics
- Test data setup code

**Solution**:
```bash
# Analyze separately
radon cc src/ -a -nb          # Production only
radon cc tests/ -a -nb        # Tests separately

# Compare metrics
# High complexity in tests is often acceptable
# High complexity in production code is not
```

**Different Thresholds**:
- Production code: Complexity > 10 is concerning
- Test code: Complexity > 15 is acceptable

### Dead Code Inflation

**Problem**: Unused imports, deprecated functions, dead branches distort metrics.

**Causes**:
- Old code never removed
- Import statements with unused dependencies
- Copy-pasted code
- Conditional code for deprecated features

**Solution**:
```bash
# Find dead code first
vulture .                           # Python
npx jscpd src/                     # JS/TS copy-paste
# Then remove before analysis

# Or tag dead code separately
# @deprecated annotations
# FIXME comments
# Then separate metrics
```

**Impact**: Dead code can indicate maintenance burden, separate from actual complexity

## Metrics Misinterpretation

### Cyclomatic Complexity Is Language-Dependent

**Problem**: Same complexity score means different things in different languages.

**Examples**:
```python
# Python - CC=5 (simple)
if x:
    return 1
elif y:
    return 2
elif z:
    return 3
elif w:
    return 4
else:
    return 5
```

```rust
// Rust - CC=1 (match is optimized)
match x {
    A => 1,
    B => 2,
    C => 3,
    D => 4,
    _ => 5,
}
```

**Solution**: Use language-specific complexity metrics
- JavaScript: ESComplex
- Python: Radon (tuned for Python idioms)
- Go: gocyclo (accounts for switch statements)
- Rust: No standard (use external tests)

### High LOC Doesn't Mean Bad Code

**Problem**: Larger files aren't necessarily worse.

**Context matters**:
- Declarative code (data definitions): Long is fine
- Generated code: LOC is meaningless
- Well-documented code: More lines for clarity
- Type-heavy languages: More verbosity (Java, Go)

**Solution**:
```
LOC metrics should be paired with:
- Complexity metrics (cyclomatic)
- Maintainability index
- Test coverage
- Documentation percentage
```

### Coupling Metrics Are Relative

**Problem**: Coupling numbers without context are meaningless.

**Factors**:
- Library code naturally has high efferent coupling
- Framework-heavy code has high dependencies
- Middleware connects many components

**Solution**:
```bash
# Compare instability metric (I)
# I = efferent / (afferent + efferent)
# I = 0: Maximally stable (no dependencies)
# I = 1: Maximally unstable (only outgoing deps)

# Good modules: I between 0.3-0.7
# High I (>0.8): Potential problem
# Low I (<0.2): May be too decoupled
```

## Tool Limitations

### Static Analysis Can't Detect Runtime Behavior

**What tools miss**:
- Dynamic imports: `__import__()`, `require(variable)`
- Reflection: Finding methods by string
- Configuration-driven execution
- Plugin systems
- Dependency injection containers

**Example**:
```python
# Tool thinks 'service' is unused
service = __import__(config.SERVICE_CLASS)

# But it's used at runtime
result = service.process()
```

**Solution**: Complement static analysis with:
- Runtime profiling
- Code review
- Tests coverage analysis
- Architecture documentation

### Dependency Analysis Limitations

**Python**:
- Can't resolve dynamic imports
- Relative imports sometimes fail
- Conditional imports (different Python versions) need context

**JavaScript**:
- Webpack aliases confuse tools
- Barrel exports can hide dependencies
- Monorepo workspaces may be misconfigured

**Go**:
- Interface satisfaction detected statically (good)
- But behavioral contracts not enforced

**Solution**: Manual verification for:
- Complex import patterns
- Dynamic code loading
- Runtime plugins
- Monorepo edge cases

### Tool False Positives/Negatives

**Common issues**:
- Unused import detection: ~20% false positives
- Circular dependency detection: Framework patterns flagged as circular
- Complexity metrics: Short methods with many branches vs long sequential code
- Security scanning: Framework annotations flagged as issues

**Solution**:
```bash
# Configure tool thresholds
# Suppress false positives
# Use multiple tools for validation
# Review results with team
```

## Language-Specific Gotchas

### Python: Dynamic Typing Confuses Tools

**Problem**: Import statements don't show actual dependencies.

```python
# Tool sees 'requests' import
import requests

# But doesn't know this is conditional
if use_api:
    response = requests.get(url)
```

**Solution**:
- Use type hints for clarity
- Configure linters: `mypy`, `pyright`
- Document dynamic imports explicitly

### JavaScript: Module Confusion

**Problem**: CommonJS vs ES6 modules analyzed differently.

```javascript
// CommonJS (older)
const module = require('./module.js');

// ES6 (newer)
import module from './module.js';

// Both valid, but tools handle differently
```

**Solution**:
- Configure tool for your module system
- Use consistent module format
- Configure Babel/webpack properly

### Go: Interface Satisfaction Is Implicit

**Problem**: Interfaces are satisfied implicitly (no explicit declaration).

```go
type Writer interface {
    Write(p []byte) (n int, err error)
}

type MyFile struct {}

// MyFile automatically satisfies Writer
// No "implements" declaration needed
func (f *MyFile) Write(p []byte) (int, error) {
    // ...
}
```

**Solution**:
- Document which types implement which interfaces
- Use interface{} carefully (loses type information)
- Consider explicit interface definitions for clarity

### Rust: Compile-Time Dependencies

**Problem**: Some dependencies are compile-time only (feature flags, build scripts).

```toml
[dependencies]
serde = "1.0"

[dev-dependencies]
tokio = { version = "1.0", features = ["full"] }

[build-dependencies]
cc = "1.0"
```

**Solution**:
- Separate analysis of different dependency types
- Use `cargo tree --kind all`
- Understand feature flags impact

## Monorepo Challenges

### Monorepo Structure Confusion

**Problem**: Single Git repo with multiple independent projects.

**Gotchas**:
- Dependencies between projects analyzed as internal/external incorrectly
- Metrics for "whole repo" vs "individual projects" differ
- Entry points unclear
- CI/CD assumes single project

**Example Structure**:
```
repo/
├── apps/
│   ├── api/ (independent)
│   ├── web/ (independent)
│   └── admin/ (independent)
├── packages/
│   ├── shared-utils/
│   ├── ui-components/
│   └── types/
```

**Solution**:
```bash
# Analyze each workspace separately
analyze_dependencies.py ./apps/api
analyze_dependencies.py ./apps/web

# Then aggregate findings
# Document dependency relationships between apps
```

### Workspace Configuration Ignored

**Problem**: Tools don't understand monorepo workspace configuration.

**Examples**:
- npm workspaces (package.json workspaces field)
- Yarn workspaces
- Lerna monorepos
- Gradle multi-project builds
- Cargo workspaces

**Solution**:
- Configure tools for monorepo:
```json
{
  "workspaces": [
    "apps/*",
    "packages/*"
  ]
}
```

- Analyze with monorepo awareness
- Document workspace dependencies

### Shared Code Coupling

**Problem**: Shared utilities create implicit coupling between projects.

**Risk**: Shared code changes affect all dependent projects.

**Solution**:
- Treat shared packages as APIs
- Version independently
- Clear versioning strategy
- Breaking change documentation

## Legacy Code Issues

### Mixed Code Styles

**Problem**: Codebase contains both old and new code with different styles.

```python
# Old style (Python 2)
def old_function((a, b)):
    return a + b

# New style (Python 3)
def new_function(a, b):
    return a + b
```

**Impact**:
- Metrics vary within same codebase
- Patterns confusing
- Maintenance confusion

**Solution**:
```bash
# Tag by style
# Separate metrics by age
# Plan migration strategy
# Document transition timeline
```

### Multiple Versions of Dependencies

**Problem**: Same dependency at different versions.

**Causes**:
- Gradual upgrades
- Transitive dependencies
- Version constraints conflicts

**Example**:
```
Package A requires lodash 3.x
Package B requires lodash 4.x
Result: Both versions bundled (waste)
```

**Solution**:
```bash
# Detect duplicates
npm ls --all | grep -E "^.* [0-9]+\.[0-9]" | sort | uniq

# Resolve conflicts
npm dedupe
npm audit fix

# Document version matrix
```

### Deprecated Code Cluttering Analysis

**Problem**: Old, deprecated functions still in codebase.

**Signal**: Code may be in transition state.

**Solution**:
```python
# Find deprecated code
grep -r "@deprecated" .
grep -r "TODO: remove" .
grep -r "FIXME:" .

# Document deprecation timeline
# Plan removal
# Separate from active code analysis
```

## Analysis Best Practices

### DO's

1. **Exclude known artifacts** before analysis
2. **Run multiple tools** for validation
3. **Analyze production and test separately**
4. **Document analysis scope** (what was included/excluded)
5. **Re-run analysis regularly** (track trends)
6. **Compare metrics over time** (what's improving?)
7. **Pair metrics with context** (why is this number high?)
8. **Involve team** in interpretation
9. **Focus on actionable findings** (what can we improve?)
10. **Document assumptions** in analysis

### DON'Ts

1. **Don't trust metrics blindly** - Always verify with review
2. **Don't over-weight single metrics** - Use multiple signals
3. **Don't analyze generated code** - Exclude before analysis
4. **Don't skip tool configuration** - Proper setup is crucial
5. **Don't ignore false positives** - Configure tools to reduce noise
6. **Don't compare across languages** - Metrics are relative
7. **Don't analyze isolated from context** - Talk to team
8. **Don't make decisions based on one snapshot** - Track trends
9. **Don't ignore documentation** - Existing docs provide context
10. **Don't automate without human review** - Always verify results

## Related Documentation

- `PATTERNS.md` - Language-specific patterns for accurate analysis
- `REFERENCE.md` - Tool-specific configuration and limitations
- `EXAMPLES.md` - Real-world gotchas in practice
