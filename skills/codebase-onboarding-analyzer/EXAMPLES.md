# Complete Onboarding Examples

## Table of Contents

1. [Python Django Project](#python-django-project)
2. [React + Express.js Web App](#react--expressjs-web-app)
3. [Go Microservice](#go-microservice)
4. [Rust Library](#rust-library)
5. [Multi-Language Data Pipeline](#multi-language-data-pipeline)

## Python Django Project

### Scenario

Onboarding to an existing Django e-commerce platform with 15,000+ LOC, multiple apps, and complex database models.

### Analysis Steps

**Step 1: Quick Survey**

```bash
./quick-survey.sh .
```

Expected findings:
- Language: Python (main), HTML/CSS, SQL
- Framework: Django 4.x
- Package manager: pip/poetry
- Directory structure: `manage.py` at root, apps in separate folders

**Step 2: Entry Points Discovery**

```bash
python entry_point_finder.py .
```

Expected findings:
```json
{
  "main_functions": [
    {"file": "manage.py", "type": "Python main"}
  ],
  "cli_commands": [
    {
      "file": "manage.py",
      "command": "runserver",
      "type": "Django management command"
    },
    {
      "file": "manage.py",
      "command": "migrate",
      "type": "Django management command"
    }
  ],
  "api_endpoints": [
    {"path": "/api/products/", "method": "GET", "file": "apps/products/views.py"},
    {"path": "/api/orders/", "method": "POST", "file": "apps/orders/views.py"}
  ]
}
```

**Step 3: Dependency Analysis**

```bash
python analyze_dependencies.py .
```

Expected findings:
```json
{
  "total_modules": 24,
  "entry_points": ["manage.py", "wsgi.py"],
  "external_packages": ["django", "djangorestframework", "celery", "psycopg2"],
  "circular_dependencies": [],
  "orphan_modules": ["apps/deprecated/old_module.py"]
}
```

**Step 4: Complexity Analysis**

```bash
python complexity_analyzer.py .
radon cc . -a -nb
radon mi . -n B
```

Key findings:
- Average complexity: 4.2 (low-moderate)
- High complexity functions: 3 (views with business logic)
- Low MI files: `apps/products/models.py` (MI: 58) - needs refactoring
- Recommendation: Break down model methods into service layer

**Step 5: Architecture Documentation**

```bash
python arch_doc_generator.py .
```

Generated `ARCHITECTURE.md` would show:
- Django web application
- 8 apps: products, orders, users, payments, inventory, reports, notifications, admin
- PostgreSQL backend
- Celery async tasks
- REST API with DRF

### Key Insights for New Developer

1. **How to run**: `python manage.py runserver` (dev), `gunicorn config.wsgi` (production)
2. **File structure**: Apps are modular - each has models, views, serializers, urls
3. **First task**: Update `ProductSerializer` in `apps/products/serializers.py`
4. **Gotchas**:
   - Migrations must be run after schema changes
   - Celery tasks need Redis running
   - `settings/` has environment-specific configs

---

## React + Express.js Web App

### Scenario

Full-stack JavaScript application with React frontend and Express.js backend. ~8,000 LOC total.

### Analysis Steps

**Step 1: Directory Structure**

```
project/
├── backend/
│   ├── src/
│   │   ├── routes/
│   │   ├── controllers/
│   │   ├── middleware/
│   │   ├── models/
│   │   └── index.js
│   └── package.json
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   ├── hooks/
│   │   ├── pages/
│   │   └── App.js
│   └── package.json
└── docker-compose.yml
```

**Step 2: Entry Points**

Backend:
- `backend/src/index.js` - Express server startup
- API routes: `/api/users`, `/api/posts`, `/api/comments`

Frontend:
- `frontend/src/index.js` - React mount point
- Routes: `/`, `/login`, `/dashboard`, `/profile`

**Step 3: Dependency Analysis**

Backend dependencies:
- express, cors, mongoose, jsonwebtoken, dotenv
- Dev: jest, supertest, nodemon

Frontend dependencies:
- react, react-router-dom, axios, tailwindcss
- Dev: webpack, babel, eslint

**Step 4: Circular Dependency Check**

```bash
cd backend && npx madge --circular src/
cd frontend && npx madge --circular src/
```

Expected findings: None in well-structured app

**Step 5: Integration Points**

- Frontend calls `http://localhost:3000/api/*`
- JWT tokens in Authorization header
- CORS configured for localhost development

### Key Insights for New Developer

1. **Start**: Run `npm install` in both directories, then `npm start`
2. **Backend port**: 5000 (API)
3. **Frontend port**: 3000 (React)
4. **Database**: MongoDB (see docker-compose.yml)
5. **First task**: Add new endpoint in `backend/src/routes/items.js`
6. **Git flow**: Feature branches from `develop` → PR → merge

---

## Go Microservice

### Scenario

Production Go microservice handling payment processing. 3,000 LOC, well-structured.

### Analysis Steps

**Step 1: Package Organization**

```
payment-service/
├── main.go
├── go.mod / go.sum
├── cmd/
│   └── server/
│       └── main.go
├── internal/
│   ├── handler/
│   ├── service/
│   ├── repository/
│   └── model/
├── pkg/
│   └── paymentgateway/
└── tests/
```

**Step 2: Entry Point**

```bash
go run cmd/server/main.go
# or
go build -o payment-service
./payment-service
```

**Step 3: Dependency Analysis**

```bash
go mod graph
go mod tidy
```

Key dependencies:
- gin-gonic/gin (HTTP framework)
- mongodb/mongo-go-driver (database)
- stripe-go (payment API)

**Step 4: Interface-Based Design**

```go
type PaymentProcessor interface {
    ProcessPayment(ctx context.Context, payment *Payment) error
    RefundPayment(ctx context.Context, transactionID string) error
}

type StripeProcessor struct {
    // Implementation
}

type MockProcessor struct {
    // For testing
}
```

**Step 5: Error Patterns**

- Custom error types in `internal/errors/`
- HTTP error responses with proper status codes
- Context for timeouts and cancellation

### Key Insights for New Developer

1. **Build**: `go build ./...` (all packages)
2. **Test**: `go test ./...`
3. **Format**: `gofmt -w .` (auto-format)
4. **Lint**: `golangci-lint run`
5. **Run**: `go run cmd/server/main.go`
6. **Package structure**:
   - `cmd/`: executable packages
   - `internal/`: private packages
   - `pkg/`: public packages

---

## Rust Library

### Scenario

Rust cryptography library with multiple modules. 2,500 LOC.

### Analysis Steps

**Step 1: Crate Structure**

```bash
cargo modules generate graph --lib | dot -Tpng > modules.png
```

Expected modules:
- `crypto`: Core cryptographic operations
- `encoding`: Serialization utilities
- `errors`: Custom error types

**Step 2: Feature Flags**

```toml
[features]
default = ["std"]
std = []
wasm = []
```

**Step 3: Unsafe Code Analysis**

```bash
cargo geiger
```

Expected output:
- ~50 unsafe code blocks
- Used for: FFI calls, performance-critical code
- All documented in inline comments

**Step 4: Dependency Analysis**

```bash
cargo tree
cargo tree --duplicates
```

Key dependencies:
- `sha2`: SHA hashing
- `aes`: AES encryption
- `rand`: Random number generation

**Step 5: Testing**

```bash
cargo test
cargo test -- --nocapture  # Show output
cargo test --lib           # Library tests only
```

### Key Insights for New Developer

1. **Build**: `cargo build` (debug), `cargo build --release` (optimized)
2. **Test**: `cargo test`
3. **Doc**: `cargo doc --open` (build and open documentation)
4. **Check**: `cargo check` (faster than build)
5. **Clippy**: `cargo clippy` (linting)
6. **Unsafe**: Always documented and justified
7. **Benchmarks**: In `benches/` directory

---

## Multi-Language Data Pipeline

### Scenario

Complex data pipeline: Python data ingestion, Go processing, Rust compute, JavaScript visualization.

### Architecture

```
┌─────────────────┐
│  Python Ingest  │ (databases, APIs)
└────────┬────────┘
         │ (CSV/JSON)
┌────────▼────────┐
│  Go Processing  │ (validation, transformation)
└────────┬────────┘
         │ (Protocol Buffers)
┌────────▼────────────┐
│  Rust Computation   │ (heavy math, ML)
└────────┬────────────┘
         │ (JSON Results)
┌────────▼──────────────┐
│  JavaScript Viz       │ (React dashboards)
└───────────────────────┘
```

### Analysis Approach

**Step 1: Identify Components**

- Python: `ingest/` directory
- Go: `processor/` subdirectory
- Rust: `compute/` subdirectory
- JavaScript: `dashboard/` subdirectory

**Step 2: Integration Points**

```
Python → Go: File system or gRPC
Go → Rust: Shared library or subprocess
Rust → JavaScript: REST API or WebSocket
```

**Step 3: Data Flow Analysis**

```
Database → Python extract() → CSV files
CSV files → Go validate() → Normalized JSON
JSON → Rust compute() → Results file
Results → JS fetch() → React charts
```

**Step 4: Deployment Architecture**

- Docker containers for each component
- Orchestration: Docker Compose or Kubernetes
- Inter-service communication: REST APIs

### Key Insights

1. **Onboarding**: Start with Python ingest, work downstream
2. **Dependencies**: Each language has isolated deps
3. **Testing**: End-to-end tests critical at integration points
4. **Data formats**: Protocol Buffers or JSON for serialization
5. **Monitoring**: Log aggregation crucial with multiple components

---

## Quick Start Templates

### For Python Project

```bash
# 1. Discovery
python entry_point_finder.py .
radon cc . -a -nb
radon mi . -n B

# 2. Analysis
python analyze_dependencies.py .
python complexity_analyzer.py .

# 3. Documentation
python arch_doc_generator.py .

# 4. Output
mkdir -p codebase-analysis
mv *.json *.md codebase-analysis/
```

### For JavaScript Project

```bash
# 1. Dependencies
npx madge --circular src/
npx madge --image deps.png src/

# 2. Complexity
npx cr src/**/*.js --format json > complexity.json

# 3. Duplicates
npx jscpd src/

# 4. Package analysis
npm ls --depth=0
npm audit
```

### For Go Project

```bash
# 1. Structure
go mod graph > deps.txt
go list ./...

# 2. Complexity
gocyclo -avg ./...
go-callvis -format png .

# 3. Testing
go test ./... -cover
go test ./... -v

# 4. Quality
staticcheck ./...
golangci-lint run
```

## Related Documentation

- `PATTERNS.md` - Language-specific patterns
- `GOTCHAS.md` - Common pitfalls to avoid
- `REFERENCE.md` - Tools and their options
- `KNOWLEDGE.md` - Theoretical foundations
