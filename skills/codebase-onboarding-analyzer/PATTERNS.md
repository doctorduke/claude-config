# Language-Specific Analysis Patterns

## Overview

Analysis patterns vary significantly by language and framework. This reference provides language-specific approaches, tools, and interpretation guides for accurate codebase understanding.

## Table of Contents

1. [Python Analysis](#python-analysis)
2. [JavaScript/TypeScript Analysis](#javascripttypescript-analysis)
3. [Go Analysis](#go-analysis)
4. [Rust Analysis](#rust-analysis)
5. [Java Analysis](#java-analysis)
6. [Language Comparison](#language-comparison)

## Python Analysis

### Tools & Commands

```bash
# Cyclomatic complexity analysis
radon cc . -a -nb              # Detailed with color
radon cc . --json > cc.json    # JSON output

# Maintainability metrics
radon mi . -n B                # Show files with B or worse

# Dead code detection
vulture .                       # Find unused code
vulture . --min-confidence 80   # Filter false positives

# Security scanning
bandit -r .                    # Security issues
bandit -r . -f json > issues.json

# Dependency visualization
pydeps . --max-bacon 2         # Package hierarchy
pydeps . --show-cycles         # Find circular deps
```

### Framework Detection

**Django**
- Look for `manage.py`, `settings.py` in project root
- Entry points: `manage.py runserver`, Django management commands
- Key files: `urls.py`, `views.py`, `models.py`, `settings.py`

**Flask**
- Check for `app = Flask(__name__)` pattern
- Entry points: `flask run`, `@app.route()` decorators
- Key files: application factory, blueprint files

**FastAPI**
- Look for `FastAPI()` instantiation
- Entry points: `uvicorn` or `hypercorn` servers
- Key files: main app file with `@app.get()`, `@app.post()` decorators

**Celery**
- Check for `celery.py` or celery configuration in settings
- Entry points: `celery worker`, `celery beat`
- Distributed task queue patterns

### Entry Point Patterns

```python
# Standard main guard
if __name__ == "__main__":
    main()

# Click CLI
@click.command()
@click.option('--name')
def hello(name):
    pass

# ArgumentParser
parser = ArgumentParser()
parser.add_argument('--input')
args = parser.parse_args()

# Setup.py entry points
entry_points={
    'console_scripts': [
        'mycli=mypackage.cli:main',
    ]
}
```

### Dependency Analysis Patterns

**Internal Dependencies**
- Use AST analysis: `ast.parse()` to find imports
- Distinguish `import x` vs `from x import y`
- Handle relative imports (`.`, `..`)

**Circular Dependencies**
- Build dependency graph with modules as nodes
- Use depth-first search (DFS) to detect cycles
- Common in large projects, may indicate design issues

**External Dependencies**
- Parse `requirements.txt`, `setup.py`, `pyproject.toml`
- Check `pip freeze` for installed versions
- Track version constraints and conflicts

### Complexity Interpretation

**Cyclomatic Complexity (CC)**
- 1-5: Simple functions (ideal)
- 6-10: Moderate, still testable
- 11-20: Complex, hard to test
- 21+: Very complex, refactor recommended

**Maintainability Index (MI)**
- 85-100: Highly maintainable
- 65-84: Good maintainability
- 50-64: Moderate, improvement needed
- 0-49: Difficult to maintain

## JavaScript/TypeScript Analysis

### Tools & Commands

```bash
# Circular dependencies
npx madge --circular .              # List circular deps
npx madge --circular --format cjs . # CommonJS format

# Dependency graph visualization
npx madge --image graph.png .       # PNG visualization
npx madge --json > deps.json        # JSON export

# Complexity analysis
npx cr src/**/*.js                  # Complexity report
npx jscpd src/                      # Duplicate code

# Dependency validation
npx dependency-cruiser --output-type dot src | dot -T png > deps.png

# TypeScript specific
ts-morph for AST manipulation
```

### Framework Detection

**React**
- Look for `import React` or JSX syntax
- Entry points: `ReactDOM.render()`, Next.js pages
- Key files: components, hooks, context providers

**Vue**
- Check for `new Vue({})` or `createApp()`
- Entry points: main.js, app.vue
- Single-file components: `.vue` files

**Angular**
- Look for `@NgModule`, `@Component` decorators
- Entry points: `main.ts`, `bootstrapModule`
- Build tools: `ng serve`, `ng build`

**Express.js**
- Find `express()` instantiation
- Entry points: `app.listen()`, middleware chains
- Routing: `app.get()`, `app.post()`, etc.

**Next.js**
- Check for `next.config.js`
- Entry points: API routes in `pages/api/`
- Pages: file-based routing in `pages/`

### Entry Point Patterns

```javascript
// React component mounting
ReactDOM.render(<App />, document.getElementById('root'));

// Express server
app.listen(3000, () => console.log('Server running'));

// Next.js API route
export default function handler(req, res) {
  res.status(200).json({});
}

// Vue app
createApp(App).mount('#app');

// Webpack entry
module.exports = {
  entry: './src/index.js'
};

// npm scripts (package.json)
"scripts": {
  "start": "react-scripts start",
  "build": "react-scripts build"
}
```

### Dependency Analysis Patterns

**Module Systems**
- CommonJS: `require()`, `module.exports`
- ES Modules: `import`, `export`
- Detect using madge or dependency-cruiser

**Circular Dependencies**
- Use graph analysis tools (madge, dependency-cruiser)
- In JS, circular deps often work due to module system
- Still indicate potential design issues

**Peer Dependencies**
- Check package.json for `peerDependencies`
- Indicates framework plugins or extensions
- May cause version conflicts

### Complexity Interpretation

**Cyclomatic Complexity**
- 1-3: Excellent
- 4-7: Good
- 8-10: Moderate
- 11+: Consider refactoring

**Cognitive Complexity**
- Better metric for JS/TS than cyclomatic
- Accounts for modern features (destructuring, arrow functions)
- Use escomplex for detailed analysis

## Go Analysis

### Tools & Commands

```bash
# Cyclomatic complexity
gocyclo -avg .                      # Average complexity
gocyclo -over 10 .                  # Functions > 10

# Call graph visualization
go-callvis -format png .            # Visual call graph
go-callvis -focus main .            # Focus on main package

# Dependency analysis
godepgraph -s . | dot -Tpng > deps.png  # Dependency graph
go mod graph                         # Module dependencies

# Code quality
staticcheck ./...                   # Advanced linter
golangci-lint run                  # Multiple linters
```

### Structure Analysis

**Package Organization**
- Each directory is a package
- Import paths: `github.com/user/project/pkg`
- Package boundaries indicate module separation

**Interface-Based Design**
- Go favors composition and interfaces
- Look for small, focused interfaces
- Check for duck typing patterns

### Entry Point Patterns

```go
// main function
func main() {
    // Program entry point
}

// Server startup
func main() {
    http.HandleFunc("/", handler)
    http.ListenAndServe(":8080", nil)
}

// CLI app
func main() {
    app := cli.NewApp()
    app.Run(os.Args)
}

// Command package
type Command interface {
    Execute()
}

// Build constraints
// +build linux darwin
```

### Dependency Analysis

**Import Patterns**
- Understand Go's circular import restrictions
- Tools like godepgraph show package dependencies
- `go mod graph` shows module-level dependencies

**Standard Library Dependencies**
- Classify standard library vs third-party
- Third-party packages in `go.mod`
- Version management through `go.sum`

## Rust Analysis

### Tools & Commands

```bash
# Module structure visualization
cargo modules generate graph --lib | dot -Tpng > modules.png

# Unsafe code detection
cargo geiger                        # Counts unsafe code
cargo geiger --output sarif > report.sarif

# Dependency tree
cargo tree                          # Full dependency tree
cargo tree --depth 1                # Top-level only
cargo tree --duplicates             # Find duplicate versions

# Code quality
cargo clippy                        # Linting recommendations
cargo fmt --check                   # Code formatting
```

### Module Organization

**Crate Structure**
- Single crate per project (typically)
- Modules organized in `src/lib.rs` or `src/main.rs`
- Visibility: `pub`, `crate`, `private`

**Workspace Projects**
- Multiple related crates in one repo
- `Cargo.toml` at workspace root
- Each member has own `Cargo.toml`

### Entry Point Patterns

```rust
// Library entry point
pub mod module_name;
pub fn public_function() {}

// Binary entry point
fn main() {
    // Program starts here
}

// Macro system
#[cfg(test)]
mod tests {
    #[test]
    fn test_name() {}
}

// Procedural macros
#[derive(Serialize)]
struct MyStruct;
```

### Dependency Management

**Cargo.toml Analysis**
- Regular deps: runtime dependencies
- Dev-deps: test/build-time only
- Build-deps: used by build scripts
- Features: optional functionality

**Unsafe Code**
- Rust uses `unsafe` keyword for unsafe operations
- cargo-geiger counts unsafe usage
- May indicate FFI, performance-critical code

## Java Analysis

### Tools & Commands

```bash
# Design metrics
java -jar jdepend.jar .             # JDepend analysis
mvn jdepend:jdepend                 # Maven plugin

# Architecture testing
mvn test -Dtest=ArchitectureTests   # ArchUnit tests

# Code quality
checkstyle -c google_checks.xml -r .  # Code style
pmd -d . -f text                    # Static analysis

# Dependency analysis
mvn dependency:tree                 # Dependency tree
mvn dependency:analyze              # Unused/missing deps

# Complexity
javancss                            # Metrics calculation
```

### Structure Analysis

**Package Organization**
- Packages indicate module boundaries
- Convention: `com.company.project.feature`
- Analyze coupling between packages

**Class Hierarchies**
- Inheritance: extends relationships
- Interfaces: contract definitions
- Abstract classes: partial implementation

**Build Tool Analysis**
- Maven: `pom.xml` for configuration and deps
- Gradle: `build.gradle` for build scripts
- Check for multi-module projects

### Entry Point Patterns

```java
// Application main
public class Application {
    public static void main(String[] args) {
        // Entry point
    }
}

// Spring Boot
@SpringBootApplication
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}

// Spring MVC
@RestController
@RequestMapping("/api")
public class Controller {
    @GetMapping("/endpoint")
    public String handler() {}
}

// Service interface
public interface UserService {
    User findById(long id);
}
```

### Dependency Analysis

**Maven Dependencies**
- Parse `pom.xml` for explicit dependencies
- Use `mvn dependency:tree` for tree view
- Check for version conflicts

**JARs and Classpaths**
- Classpath indicates which JARs are loaded
- Look for version mismatches
- Check for missing required JARs

## Language Comparison

| Aspect | Python | JavaScript | Go | Rust | Java |
|--------|--------|-----------|----|----|------|
| **Dependency Tool** | pip, poetry | npm, yarn | go modules | cargo | maven, gradle |
| **Package Manager** | pip/conda | npm/yarn | go get | cargo | maven/gradle |
| **Circular Deps** | Possible, problematic | Possible, often work | Prevented | Prevented | Possible, discouraged |
| **Entry Points** | `if __name__` | Scripts in package.json | `func main()` | `fn main()` | Static main method |
| **Build System** | setuptools, poetry | npm, webpack | `go build` | `cargo build` | maven, gradle |
| **Primary Pattern** | Modular, OOP | Component-based | Interface-driven | Type-driven | Class hierarchy |
| **Complexity Metric** | Cyclomatic, MI | Cyclomatic, ESComplex | Cyclomatic | N/A | JDepend metrics |
| **Testing** | pytest, unittest | Jest, Mocha | testing package | cargo test | JUnit |

## Cross-Language Analysis

When analyzing polyglot codebases:

1. **Identify language boundaries** - Which components are written in which language
2. **Map FFI/Integration points** - How languages communicate (APIs, shared memory, etc.)
3. **Analyze separately first** - Language-specific tools and patterns
4. **Then integrate findings** - Build unified architecture view
5. **Consider interop overhead** - Performance implications of cross-language calls

### Common Polyglot Patterns

- **Python backend + JavaScript frontend** - Most common web stack
- **Go microservices + Python data** - Data pipelines with services
- **Rust system code + Python scripting** - Performance-critical code with scripting
- **Java backend + Kotlin utilities** - JVM ecosystem
- **TypeScript + WebAssembly** - Web performance optimization

## Framework-Specific Patterns

### Monolithic vs Distributed

**Monolithic Indicators**
- Single entry point
- All code in one codebase
- Shared database
- Tightly coupled modules

**Microservices Indicators**
- Multiple services (detected by entry points)
- Independent deployments
- Service-to-service communication
- Multiple databases

### MVC vs Layered vs Event-Driven

**MVC Pattern**
- Models: data layer
- Views: presentation layer
- Controllers: business logic
- Common in: Rails, Django, Spring MVC

**Layered Architecture**
- Controller/API layer
- Service layer
- Repository/persistence layer
- Multiple layers with clear boundaries
- Common in: enterprise Java, .NET

**Event-Driven**
- Event producers and consumers
- Message queues or event buses
- Loosely coupled components
- Common in: Node.js, Go services

## Related References

- `KNOWLEDGE.md` - Architecture theory and concepts
- `EXAMPLES.md` - Real-world analysis scenarios
- `GOTCHAS.md` - Language-specific analysis pitfalls
