---
name: codebase-onboarding-analyzer
description: Rapidly understand new codebases through automated analysis of structure, dependencies, architecture, complexity, and data flow. Use when exploring unfamiliar code, onboarding to projects, documenting legacy systems, or generating quick-start guides. Supports Python, JavaScript/TypeScript, Go, Rust, Java, and more.
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, WebFetch]
---

# Codebase Onboarding Analyzer

## Purpose

Accelerate understanding of unfamiliar codebases by systematically analyzing architecture, dependencies, complexity, and patterns. This skill guides analysis across 5 layers: surface (structure), dependencies, architecture, code quality, and data flow.

**Use this skill when**:
- Onboarding to a new project or team
- Understanding legacy codebases without documentation
- Planning refactoring efforts or code reviews
- Assessing technical debt and codebase health
- Creating developer onboarding materials
- Reverse engineering application behavior
- Performing technical due diligence

## 5-Minute Quick Start

### Step 1: Directory & Technology Detection

```bash
# Analyze structure and statistics
tokei .                          # or: cloc .
ls -la                           # Check for key files
find . -name "*.py" -o -name "*.js" -o -name "go.mod" | head -5
```

**What you will learn**: Language mix, approximate size, build tools used

### Step 2: Find Entry Points

Entry points show how the system runs:

```bash
# Python: if __name__ == "__main__" blocks
grep -r "if __name__" .

# JavaScript: main in package.json, scripts, entry points
cat package.json | grep -A 5 '"main"'

# Go: func main()
grep -r "func main()" .

# Java: public static void main
grep -r "public static void main" .
```

### Step 3: Map Dependencies

```bash
# JavaScript: find circular deps
npx madge --circular src/ 2>/dev/null || echo "install: npm install madge"

# Go: show package structure
go list ./... | head -20

# Python: dependency graph
python -c "
import ast
from pathlib import Path
for py in Path('.').rglob('*.py'):
    try:
        with open(py) as f: ast.parse(f.read())
        print(f'{py.relative_to(\".\")}'[:50])
    except: pass
" | head -20
```

### Step 4: Check Code Complexity

```bash
# Python
radon cc . -a -nb --exclude=venv,tests 2>/dev/null | head -10

# JavaScript
npx complexity-report src/**/*.js 2>/dev/null || echo "install: npm install complexity-report"

# Count by language
tokei . --output json 2>/dev/null | grep -o '"code":[0-9]*' | head -5
```

### Step 5: Understand Architecture

Ask these questions:

1. How many modules/components (count top-level dirs)
2. Clear separation (models/, views/, services/, api/, handlers/)
3. Entry points from Step 2
4. Database (migrations/, schema, db config)
5. Testing (tests/, test files, test config)

## Key Concepts

### Codebase Understanding Levels

| Level | What | Time | Output |
|-------|------|------|--------|
| Surface | Structure, languages, build tools | 15-30m | Tech stack checklist |
| Dependency | What depends on what, cycles | 30-60m | Dependency graph |
| Architecture | Patterns, components, design | 1-2h | Architecture diagram |
| Quality | Complexity, maintainability, debt | 1-2h | Metrics report |
| Data Flow | How data moves, state management | 2-4h | Flow diagrams |

### Complexity Metrics

**Cyclomatic Complexity (CC)**
- 1-10: OK, easy to test
- 11-20: Complex, plan refactoring
- 21+: Very complex, refactor now

**Maintainability Index (MI)**
- 85-100: Good (green)
- 65-84: Acceptable (yellow)
- Under 65: Needs work (red)

**Circular Dependencies**
- 0: Ideal
- 1-3: Minor issue
- 4+: Architecture problem

## Language-Specific Quick Reference

### Python

**Key files**: setup.py, pyproject.toml, requirements.txt, manage.py, wsgi.py

**Tools**:
```bash
radon cc . -a -nb                    # Complexity
radon mi . -n B                      # Maintainability
vulture . --min-confidence 80        # Dead code
pydeps . --show-cycles               # Circular deps
```

### JavaScript/TypeScript

**Key files**: package.json, webpack.config.js, tsconfig.json, .babelrc

**Tools**:
```bash
npx madge --circular src/            # Circular deps
npx madge --image deps.png src/      # Visualization
npx cr src/**/*.js                   # Complexity
npm ls --depth=0                     # Direct deps
```

### Go

**Key files**: go.mod, go.sum, main.go, cmd/*/main.go

**Tools**:
```bash
go list ./...                        # Packages
go mod graph                         # Dependencies
gocyclo -avg .                       # Complexity
staticcheck ./...                    # Linting
```

### Rust

**Key files**: Cargo.toml, Cargo.lock, src/lib.rs, src/main.rs

**Tools**:
```bash
cargo tree                           # Dependencies
cargo geiger                         # Unsafe code
cargo clippy                         # Linting
cargo doc --open                     # Documentation
```

## Foundational Knowledge

### Architecture Patterns

**Monolithic**: Single codebase and deployment, all code runs together

**Microservices**: Multiple independent services with separate deployments and databases

**MVC**: Models (data), Views (presentation), Controllers (logic)

**Layered**: Presentation, Service, Repository, Database layers with clear boundaries

**Event-Driven**: Event producers and consumers with message queues

### Code Quality Signals

**Good Signs**
- Low complexity (most functions under 10 CC)
- Good test coverage (over 70%)
- Clear documentation
- Minimal circular dependencies
- Small files (under 300 lines)

**Warning Signs**
- High complexity functions (over 20 CC)
- Low test coverage (under 50%)
- Dead code or unused imports
- Circular dependencies
- Large files (over 500 lines)

## Progressive Documentation

This skill uses progressive disclosure for learning:

1. **SKILL.md** (this file) - Quick overview and entry point
2. **PATTERNS.md** - Language-specific patterns and framework detection
3. **EXAMPLES.md** - Complete real-world walkthroughs
4. **GOTCHAS.md** - Common pitfalls and how to avoid them
5. **REFERENCE.md** - Tools catalog with installation details
6. **KNOWLEDGE.md** - Architecture theory and foundations

## Common Commands Reference

```bash
# Size metrics
tokei .                              # Fast code statistics
cloc .                               # Lines of code count
scc .                                # Fast alternative

# Structure analysis
find . -type f -name "*.py" | wc -l  # File count
ls -d */ | head -10                  # Top directories

# Pattern search
grep -r "class " . --include="*.py"  # Python classes
grep -r "function " . --include="*.js" # JS functions
grep -r "struct " . --include="*.go"  # Go structs

# Git insights
git shortlog -sn | head -10          # Top contributors
git log --oneline | wc -l            # Total commits
git log --since="3 months ago" | wc -l # Recent activity
```

## When to Use Each File

- **Language-specific guidance?** - PATTERNS.md
- **Worked examples?** - EXAMPLES.md
- **Hitting issues?** - GOTCHAS.md
- **Tool documentation?** - REFERENCE.md
- **Architecture theory?** - KNOWLEDGE.md

## Next Steps After Analysis

1. Document findings in ARCHITECTURE.md
2. Create onboarding guide with entry points
3. Prioritize refactoring using metrics
4. Share with team for validation
5. Plan improvements based on debt

## Tips for Effective Analysis

- Start broad, go deep
- Automate what you can
- Verify with team
- Document assumptions
- Track progress over time
- Focus on patterns, not just functions

## Related Documentation

- PATTERNS.md - Language and framework guidance
- REFERENCE.md - Complete tool catalog
- EXAMPLES.md - Real-world scenarios
- KNOWLEDGE.md - Theoretical foundations
- GOTCHAS.md - Common pitfalls
