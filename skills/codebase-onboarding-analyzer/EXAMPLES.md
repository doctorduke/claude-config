# Working Examples

Real-world codebase analysis examples and complete workflows.

**Parent:** [SKILL.md](./SKILL.md)

## Table of Contents

1. [Complete Onboarding Workflow](#complete-onboarding-workflow)
2. [Integration with Development](#integration-with-development)
3. [Real-World Analysis Examples](#real-world-analysis-examples)

## Complete Onboarding Workflow

### All-in-One Analysis Script

```bash
#!/bin/bash
# onboard-codebase.sh - Complete codebase onboarding analysis

set -e

PROJECT_DIR=${1:-.}
ANALYSIS_DIR="codebase-onboarding"

echo "=== Codebase Onboarding Analyzer ==="
echo "Project: $PROJECT_DIR"
echo "Output: $ANALYSIS_DIR"
echo ""

# Create output directory
mkdir -p "$ANALYSIS_DIR"

# 1. Quick Survey
echo "[1/6] Running quick survey..."
./quick-survey.sh "$PROJECT_DIR" > /dev/null 2>&1 || echo "Survey failed (non-critical)"

# 2. Dependency Analysis
echo "[2/6] Analyzing dependencies..."
if ls "$PROJECT_DIR"/**/*.py >/dev/null 2>&1; then
    python analyze_dependencies.py "$PROJECT_DIR" > /dev/null 2>&1 || echo "Python dependency analysis failed"
fi
if [ -f "$PROJECT_DIR/package.json" ]; then
    npx madge --json "$PROJECT_DIR" > "$ANALYSIS_DIR/js-dependencies.json" 2>/dev/null || echo "JS dependency analysis failed"
fi

# 3. Complexity Analysis
echo "[3/6] Calculating complexity metrics..."
if ls "$PROJECT_DIR"/**/*.py >/dev/null 2>&1; then
    python complexity_analyzer.py "$PROJECT_DIR" > /dev/null 2>&1 || echo "Complexity analysis failed"
fi

# 4. Entry Point Discovery
echo "[4/6] Finding entry points..."
python entry_point_finder.py "$PROJECT_DIR" > /dev/null 2>&1 || echo "Entry point discovery failed"

# 5. Git History Analysis
echo "[5/6] Analyzing Git history..."
if [ -d "$PROJECT_DIR/.git" ]; then
    ./git-history-analyzer.sh "$PROJECT_DIR" > /dev/null 2>&1 || echo "Git analysis failed"
fi

# 6. Generate Documentation
echo "[6/6] Generating documentation..."
python arch_doc_generator.py "$PROJECT_DIR" > /dev/null 2>&1 || echo "Documentation generation failed"

# Move all outputs to analysis directory
mv dependency-analysis.json "$ANALYSIS_DIR/" 2>/dev/null || true
mv complexity-analysis.json "$ANALYSIS_DIR/" 2>/dev/null || true
mv entry-points.json "$ANALYSIS_DIR/" 2>/dev/null || true
mv git-analysis.md "$ANALYSIS_DIR/" 2>/dev/null || true
mv ARCHITECTURE.md "$ANALYSIS_DIR/" 2>/dev/null || true
mv dependencies.dot "$ANALYSIS_DIR/" 2>/dev/null || true
mv complexity-report.md "$ANALYSIS_DIR/" 2>/dev/null || true
mv ENTRY-POINTS.md "$ANALYSIS_DIR/" 2>/dev/null || true

echo ""
echo "=== Onboarding Complete ==="
echo ""
echo "Generated documentation:"
echo "  - $ANALYSIS_DIR/ARCHITECTURE.md (Main documentation)"
echo "  - $ANALYSIS_DIR/ENTRY-POINTS.md (How to run)"
echo "  - $ANALYSIS_DIR/complexity-report.md (Code quality)"
echo "  - $ANALYSIS_DIR/git-analysis.md (History & ownership)"
echo ""
echo "Start here: $ANALYSIS_DIR/ARCHITECTURE.md"
```



## Integration with Development

### Pre-Onboarding Checklist

```markdown
## New Developer Onboarding Checklist

- [ ] Clone repository
- [ ] Run `./onboard-codebase.sh`
- [ ] Read `ARCHITECTURE.md`
- [ ] Review `ENTRY-POINTS.md`
- [ ] Check `complexity-report.md` for hotspots
- [ ] Explore dependency graph visualization
- [ ] Review Git history for active areas
- [ ] Set up development environment
- [ ] Run tests
- [ ] Make first commit (documentation fix)
```

### Continuous Documentation

```yaml
# .github/workflows/architecture-docs.yml
name: Update Architecture Documentation

on:
  push:
    branches: [main]

jobs:
  update-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Analyze Codebase
        run: |
          ./onboard-codebase.sh .

      - name: Commit Documentation
        run: |
          git config user.name "Architecture Bot"
          git config user.email "bot@example.com"
          git add codebase-onboarding/
          git commit -m "docs: Update architecture documentation [skip ci]" || true
          git push
```



## Real-World Analysis Examples

### Example 1: Analyzing a Flask Application

```bash
#!/bin/bash
# analyze-flask-app.sh

PROJECT="my-flask-app"

# 1. Find entry points
echo "=== Entry Points ==="
grep -r "@app.route" $PROJECT --include="*.py"
grep -r "if __name__ == '__main__'" $PROJECT --include="*.py"

# 2. Map dependencies
echo "=== Dependencies ==="
python -c "
import ast
from pathlib import Path

deps = set()
for py_file in Path('$PROJECT').rglob('*.py'):
    with open(py_file) as f:
        try:
            tree = ast.parse(f.read())
            for node in ast.walk(tree):
                if isinstance(node, ast.Import):
                    for alias in node.names:
                        deps.add(alias.name.split('.')[0])
        except: pass

for dep in sorted(deps):
    print(dep)
"

# 3. Complexity hotspots
echo "=== High Complexity Functions ==="
radon cc $PROJECT -n B  # Show B grade or worse

# 4. Architecture patterns
echo "=== Architecture Patterns ==="
echo "Models:" && find $PROJECT -name "models.py" -o -name "model.py"
echo "Views:" && find $PROJECT -name "views.py" -o -name "view.py"
echo "Forms:" && find $PROJECT -name "forms.py" -o -name "form.py"
```

### Example 2: Analyzing a React Application

```bash
#!/bin/bash
# analyze-react-app.sh

PROJECT="my-react-app"

# 1. Technology detection
echo "=== Technology Stack ==="
cat $PROJECT/package.json | jq '.dependencies + .devDependencies'

# 2. Component structure
echo "=== Component Structure ==="
tree -L 3 -I "node_modules|dist|build" $PROJECT/src

# 3. Dependency graph
echo "=== Generating Dependency Graph ==="
npx madge --image dependency-graph.png $PROJECT/src

# 4. Circular dependencies
echo "=== Circular Dependencies ==="
npx madge --circular $PROJECT/src

# 5. Unused exports
echo "=== Unused Exports ==="
npx ts-prune $PROJECT/src
```

### Example 3: Analyzing a Go Microservice

```bash
#!/bin/bash
# analyze-go-service.sh

PROJECT="my-go-service"

# 1. Package structure
echo "=== Package Structure ==="
go list ./... | grep "^$PROJECT"

# 2. Dependency tree
echo "=== Dependency Tree ==="
go list -m all

# 3. Call graph
echo "=== Call Graph ==="
go-callvis -group pkg,type -format png $PROJECT | dot -Tpng -o callgraph.png

# 4. Complexity
echo "=== Cyclomatic Complexity ==="
gocyclo -avg .

# 5. Static analysis
echo "=== Static Analysis ==="
staticcheck ./...
```
