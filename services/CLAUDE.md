# CLAUDE.md - Services Directory

## Purpose
The services directory contains backend services, microservices, and API implementations for the umemee ecosystem. These services handle data persistence, business logic processing, authentication, real-time features, and third-party integrations. Services can be deployed independently and scale based on demand.

## Dependencies

### Service Dependencies
- `@umemee/types` - Shared type definitions
- `@umemee/config` - Configuration management
- Core modules from `core-modules/` for business logic
- External services (databases, message queues, caches)

### What Depends on Services
- Platform applications via `@umemee/api-client`
- Other services for inter-service communication
- Webhooks and external integrations

## Key Files

### Planned Service Structure
```
services/
├── api-gateway/          # API Gateway service
│   ├── src/
│   ├── tests/
│   ├── Dockerfile
│   └── package.json
├── auth-service/         # Authentication service
│   ├── src/
│   ├── tests/
│   ├── Dockerfile
│   └── package.json
├── document-service/     # Document management
│   ├── src/
│   ├── tests/
│   ├── Dockerfile
│   └── package.json
├── sync-service/         # Real-time sync
│   ├── src/
│   ├── tests/
│   ├── Dockerfile
│   └── package.json
└── notification-service/ # Notifications
    ├── src/
    ├── tests/
    ├── Dockerfile
    └── package.json
```

## Conventions

### Service Structure
```
{service-name}/
├── src/
│   ├── index.ts          # Entry point
│   ├── app.ts            # App configuration
│   ├── routes/           # API routes
│   ├── controllers/      # Route handlers
│   ├── services/         # Business logic
│   ├── models/           # Data models
│   ├── middleware/       # Express middleware
│   ├── utils/            # Utilities
│   └── config/           # Service config
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── migrations/           # Database migrations
├── .env.example
├── Dockerfile
├── docker-compose.yml
├── package.json
└── tsconfig.json
```

### API Design Principles
- RESTful API design
- GraphQL for complex queries (optional)
- Versioned APIs (/api/v1/)
- Consistent error responses
- Request/response validation
- Rate limiting and throttling

## Testing

### Testing Strategy
```bash
# Unit tests
pnpm test

# Integration tests
pnpm test:integration

# E2E tests
pnpm test:e2e

# Load testing
pnpm test:load

# All tests for a service
pnpm --filter @umemee/auth-service test
```

### Test Requirements
- Unit tests for business logic
- Integration tests for API endpoints
- E2E tests for critical flows
- Load tests for performance
- Contract tests for inter-service communication

## Common Tasks

### Creating a New Service
```bash
# Create service directory
mkdir -p services/new-service/src
cd services/new-service

# Initialize package
pnpm init

# Add common dependencies
pnpm add express cors helmet
pnpm add -D @types/node typescript nodemon

# Create Dockerfile
cat > Dockerfile << 'EOF'
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["node", "dist/index.js"]
EOF
```

### Service Development
```bash
# Start service in development
pnpm dev

# Build service
pnpm build

# Run with Docker
docker build -t umemee-service .
docker run -p 3000:3000 umemee-service

# Run all services
docker-compose up
```

### Database Management
```bash
# Run migrations
pnpm migrate:up

# Rollback migration
pnpm migrate:down

# Create new migration
pnpm migrate:create add_users_table

# Seed database
pnpm seed
```

## Gotchas

### Common Issues
1. **Port Conflicts**: Services must use different ports
2. **Environment Variables**: Never commit .env files
3. **Database Connections**: Implement connection pooling
4. **Memory Leaks**: Monitor and profile services
5. **Circular Dependencies**: Avoid services calling each other in loops

### Microservice Challenges
- Service discovery and registration
- Distributed tracing
- Circuit breaker patterns
- Data consistency across services
- Transaction management

## Architecture Decisions

### Why Microservices?
- **Scalability**: Scale services independently
- **Technology Diversity**: Use best tool for each job
- **Fault Isolation**: Failures don't cascade
- **Team Autonomy**: Teams own services
- **Deployment Flexibility**: Deploy services independently

### Service Communication
- **Synchronous**: REST/GraphQL for request-response
- **Asynchronous**: Message queues for events
- **Real-time**: WebSockets for live updates
- **Service Mesh**: Consider Istio/Linkerd for complex setups

### Technology Stack
```typescript
// Typical service stack
{
  framework: 'Express/Fastify/NestJS',
  database: 'PostgreSQL/MongoDB',
  cache: 'Redis',
  queue: 'RabbitMQ/AWS SQS',
  monitoring: 'Prometheus/Grafana',
  logging: 'Winston/Pino',
  tracing: 'Jaeger/Zipkin'
}
```

## Performance Considerations

### Service Optimization
- Connection pooling for databases
- Caching strategies (Redis)
- Query optimization
- Pagination for large datasets
- Compression for responses
- CDN for static assets

### Scaling Strategies
```yaml
# docker-compose.yml
services:
  api:
    image: umemee/api
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
```

## Security Notes

### Security Best Practices
- JWT authentication
- API key management
- Rate limiting per endpoint
- Input validation and sanitization
- SQL injection prevention
- CORS configuration
- HTTPS everywhere
- Secrets management (Vault/AWS Secrets)

### Security Middleware
```typescript
// Security setup
import helmet from 'helmet'
import rateLimit from 'express-rate-limit'
import cors from 'cors'

app.use(helmet())
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',')
}))
app.use(rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100
}))
```

## Planned Services

### api-gateway
**Purpose**: Single entry point for all API requests
**Responsibilities**:
- Request routing
- Authentication/authorization
- Rate limiting
- Request/response transformation
- API documentation (Swagger)

### auth-service
**Purpose**: Handle authentication and authorization
**Features**:
- User registration/login
- JWT token management
- OAuth2/OIDC support
- Role-based access control
- Session management

### document-service
**Purpose**: Manage documents and content
**Features**:
- CRUD operations
- Version control
- Collaborative editing
- Search and indexing
- Export/import

### sync-service
**Purpose**: Real-time data synchronization
**Features**:
- WebSocket connections
- Conflict resolution
- Offline sync
- Presence awareness
- Change streaming

### notification-service
**Purpose**: Handle all notifications
**Features**:
- Email notifications
- Push notifications
- In-app notifications
- SMS notifications
- Notification preferences

## Deployment

### Container Orchestration
```yaml
# kubernetes/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: auth-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: auth-service
  template:
    metadata:
      labels:
        app: auth-service
    spec:
      containers:
      - name: auth-service
        image: umemee/auth-service:latest
        ports:
        - containerPort: 3000
```

### CI/CD Pipeline
```yaml
# .github/workflows/deploy.yml
name: Deploy Service
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build and push Docker image
        run: |
          docker build -t umemee/service .
          docker push umemee/service
      - name: Deploy to Kubernetes
        run: kubectl apply -f k8s/
```

## Monitoring

### Observability Stack
```typescript
// Metrics
import { register } from 'prom-client'

// Logging
import winston from 'winston'
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.Console()
  ]
})

// Tracing
import { NodeTracerProvider } from '@opentelemetry/sdk-trace-node'
```

### Health Checks
```typescript
// Health check endpoint
app.get('/health', async (req, res) => {
  const health = {
    uptime: process.uptime(),
    message: 'OK',
    timestamp: Date.now(),
    checks: {
      database: await checkDatabase(),
      redis: await checkRedis(),
    }
  }
  res.status(200).json(health)
})
```

## Data Management

### Database Patterns
- Database per service
- Event sourcing for audit trails
- CQRS for read/write separation
- Saga pattern for distributed transactions

### Migration Strategy
```typescript
// migrations/001_create_users.ts
export async function up(db) {
  await db.schema.createTable('users', table => {
    table.uuid('id').primary()
    table.string('email').unique()
    table.timestamps()
  })
}

export async function down(db) {
  await db.schema.dropTable('users')
}
```

## Future Considerations

1. **Service Mesh**: Implement Istio/Linkerd for advanced networking
2. **Serverless**: Migrate appropriate services to Lambda/Functions
3. **GraphQL Federation**: Unified GraphQL schema across services
4. **Event Streaming**: Kafka for event-driven architecture
5. **AI Services**: ML model serving and inference
6. **Edge Computing**: Deploy services closer to users
7. **Multi-tenancy**: Support for multiple organizations
8. **Compliance**: GDPR, HIPAA compliance features