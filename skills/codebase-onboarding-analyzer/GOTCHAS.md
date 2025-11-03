# Common Analysis Gotchas

Troubleshooting guide for common issues in codebase analysis.

**Parent:** [SKILL.md](./SKILL.md)

## Common Analysis Gotchas

1. **Generated Code** - Build artifacts skew metrics
   - **Solution**: Configure `.gitignore` patterns, exclude `dist/`, `build/`, `node_modules/`

2. **Monorepo Complexity** - Multiple projects in one repo
   - **Solution**: Analyze each workspace separately, then aggregate

3. **Dead Code** - Unused imports/functions inflate complexity
   - **Solution**: Run dead code detection first, separate metrics

4. **Test Code** - Tests increase complexity metrics
   - **Solution**: Analyze production code separately from tests

5. **Legacy vs Modern** - Mixed coding styles confuse analysis
   - **Solution**: Tag/separate old code, track migration progress

6. **Dynamic Languages** - Harder to trace dependencies (Python imports, JS requires)
   - **Solution**: Use runtime tracing tools, static analysis with limitations

7. **Macro/Template Code** - Expanded code not visible in source
   - **Solution**: Analyze post-preprocessing for languages like C/C++

8. **Circular Dependencies** - Valid in some languages, problematic in others
   - **Solution**: Visualize cycles, evaluate if architectural smell or language idiom



## Tool Installation Issues

### Missing Dependencies

**Problem:** Tools fail to install or run

**Solutions:**

#### Python Tools
```bash
# Ensure pip is up-to-date
python -m pip install --upgrade pip

# Install with user flag if permission issues
pip install --user radon pydeps vulture bandit

# Use virtual environment
python -m venv venv
source venv/bin/activate  # or venv\Scripts\activate on Windows
pip install radon pydeps vulture bandit
```

#### Node.js Tools
```bash
# Update npm
npm install -g npm@latest

# Install with specific permissions
sudo npm install -g madge complexity-report

# Use nvm for version management
nvm install node
nvm use node
npm install -g madge
```

#### Go Tools
```bash
# Ensure GOPATH/bin is in PATH
export PATH=$PATH:$(go env GOPATH)/bin

# Install tools
go install github.com/fzipp/gocyclo/cmd/gocyclo@latest
go install github.com/ofabry/go-callvis@latest
```

### Large Codebase Performance

**Problem:** Analysis takes too long or runs out of memory

**Solutions:**

1. **Exclude directories:**
```bash
# radon
radon cc . --exclude="**/node_modules/**,**/dist/**,**/build/**"

# madge
madge --exclude "^(node_modules|dist|build)" src/
```

2. **Sample analysis:**
```python
# Analyze subset first
import random
all_files = list(Path('.').rglob('*.py'))
sample = random.sample(all_files, min(100, len(all_files)))
# Analyze sample only
```

3. **Incremental analysis:**
```bash
# Only analyze changed files
git diff --name-only HEAD~1 | grep '.py$' | xargs radon cc
```

4. **Increase memory limits:**
```bash
# Node.js
NODE_OPTIONS="--max-old-space-size=4096" madge src/

# Python
PYTHONMALLOC=malloc python analyze.py
```

### Path and Encoding Issues

**Problem:** Files with special characters or non-UTF-8 encoding

**Solutions:**

```python
# Always use UTF-8 with error handling
with open(file, 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

# Or use chardet to detect encoding
import chardet
with open(file, 'rb') as f:
    raw = f.read()
    detected = chardet.detect(raw)
    encoding = detected['encoding']
```

## Monorepo Analysis

**Problem:** Multiple projects in one repository

**Solution:**

```bash
# Analyze each workspace separately
for workspace in packages/*/; do
    echo "Analyzing $workspace"
    radon cc "$workspace" > "analysis-$(basename $workspace).txt"
done

# Aggregate results
python aggregate_reports.py analysis-*.txt
```

## False Positives in Dead Code Detection

**Problem:** Vulture reports used code as unused

**Solution:**

```bash
# Adjust confidence threshold
vulture . --min-confidence 80

# Create whitelist
vulture . --make-whitelist > whitelist.py
vulture . whitelist.py

# Ignore specific patterns
vulture . --exclude="**/test_*.py,**/conftest.py"
```
