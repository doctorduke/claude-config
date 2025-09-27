# CLAUDE.md - Core Modules Directory

## Purpose
The core-modules directory contains the business logic and core functionality of the umemee application. These modules are platform-agnostic and can be integrated via git subtree, allowing them to be developed independently while being used across all platforms. Each module encapsulates specific domain expertise.

## Dependencies

### Module Dependencies
- Core modules should minimize external dependencies
- May depend on `@umemee/types` for shared type definitions
- Should be self-contained and independently testable
- Can be published as separate npm packages if needed

### What Depends on Core Modules
- All platform implementations (`platforms/*`)
- Other core modules (with careful dependency management)
- Backend services (`services/*`)

## Key Files

### Planned Module Structure
```
core-modules/
├── markdown-editor/       # Rich markdown editing engine
│   ├── src/
│   ├── tests/
│   ├── package.json
│   └── README.md
├── tiptap-mobile/        # Mobile-optimized Tiptap editor
│   ├── src/
│   ├── tests/
│   ├── package.json
│   └── README.md
└── block-system/         # Block-based content system
    ├── src/
    ├── tests/
    ├── package.json
    └── README.md
```

## Conventions

### Module Structure
```
{module-name}/
├── src/
│   ├── index.ts          # Main exports
│   ├── core/             # Core functionality
│   ├── plugins/          # Plugin system
│   ├── adapters/         # Platform adapters
│   └── types/            # Module types
├── tests/
│   ├── unit/
│   └── integration/
├── docs/
│   ├── API.md
│   └── ARCHITECTURE.md
├── examples/             # Usage examples
├── package.json
├── tsconfig.json
├── CHANGELOG.md
└── README.md
```

### Module Independence
- Each module should work standalone
- Provide clear interfaces and APIs
- Include comprehensive documentation
- Platform-specific code in adapters
- Use dependency injection for flexibility

## Testing

### Testing Strategy
```bash
# Test individual module
pnpm test --filter @umemee/markdown-editor

# Test all core modules
pnpm test --filter "./core-modules/*"

# Integration tests
pnpm test:integration

# Performance benchmarks
pnpm benchmark
```

### Test Requirements
- Unit tests for all public APIs
- Integration tests for module interactions
- Performance benchmarks for critical paths
- Cross-platform compatibility tests
- Memory leak detection

## Common Tasks

### Adding a New Core Module
```bash
# Using git subtree
git subtree add --prefix=core-modules/new-module \
  https://github.com/umemee/new-module.git main --squash

# Or create locally
mkdir -p core-modules/new-module/src
cd core-modules/new-module
pnpm init
```

### Updating a Subtree Module
```bash
# Pull updates from upstream
git subtree pull --prefix=core-modules/markdown-editor \
  https://github.com/umemee/markdown-editor.git main --squash

# Push changes back to upstream
git subtree push --prefix=core-modules/markdown-editor \
  https://github.com/umemee/markdown-editor.git feature-branch
```

### Module Development Workflow
```bash
# Develop in isolation
cd core-modules/markdown-editor
pnpm dev

# Test changes
pnpm test

# Build module
pnpm build

# Link for local development
pnpm link
```

## Gotchas

### Common Issues
1. **Circular Dependencies**: Avoid modules depending on each other circularly
2. **Version Conflicts**: Manage peer dependencies carefully
3. **Bundle Size**: Monitor module size impact on platforms
4. **Breaking Changes**: Use semantic versioning strictly
5. **Platform Compatibility**: Test on all target platforms

### Subtree Specific
- Changes must be committed before subtree operations
- Squash commits to keep history clean
- Maintain separate remotes for each subtree
- Document subtree sources in README
- Use prefix consistently in commands

## Architecture Decisions

### Why Core Modules?
- **Separation of Concerns**: Business logic separate from UI
- **Reusability**: Share across platforms and projects
- **Independent Development**: Teams can work autonomously
- **Version Control**: Independent versioning and releases
- **Testing**: Easier to test in isolation

### Why Git Subtree?
- **Monorepo Benefits**: Single checkout, atomic commits
- **Independence**: Modules can have separate repositories
- **Flexibility**: Can be extracted or merged as needed
- **History Preservation**: Maintains commit history
- **No Submodule Complexity**: Simpler than git submodules

### Module Design Principles
1. **Single Responsibility**: Each module has one clear purpose
2. **Interface Segregation**: Small, specific interfaces
3. **Dependency Inversion**: Depend on abstractions
4. **Open/Closed**: Open for extension, closed for modification
5. **Platform Agnostic**: No platform-specific code in core

## Performance Considerations

### Module Optimization
- Lazy loading of features
- Code splitting support
- Tree-shaking friendly exports
- Minimal runtime overhead
- Efficient memory usage

### Bundle Size Management
```json
// package.json
{
  "sideEffects": false,
  "module": "dist/index.esm.js",
  "main": "dist/index.cjs.js",
  "types": "dist/index.d.ts"
}
```

## Security Notes

### Security Considerations
- Validate all inputs at module boundaries
- Sanitize user-generated content
- Use secure defaults
- Document security requirements
- Regular dependency audits

### Security Checklist
- [ ] Input validation implemented
- [ ] Output sanitization for XSS prevention
- [ ] No sensitive data in logs
- [ ] Secure random generation used
- [ ] Dependencies audited

## Planned Modules

### markdown-editor
**Purpose**: Advanced markdown editing with live preview
**Features**:
- CommonMark compliance
- Custom syntax extensions
- Plugin system for extensions
- Real-time collaboration support
- Export to multiple formats

**Key Technologies**:
- Unified.js ecosystem
- CodeMirror or Monaco editor
- Virtual DOM for preview

### tiptap-mobile
**Purpose**: Mobile-optimized rich text editing
**Features**:
- Touch-optimized controls
- Native keyboard integration
- Gesture support
- Minimal UI footprint
- Offline-first architecture

**Key Technologies**:
- Tiptap/ProseMirror core
- React Native integration
- Custom mobile extensions

### block-system
**Purpose**: Modular content block system
**Features**:
- Drag-and-drop blocks
- Nested block support
- Custom block types
- Block templates
- Version history

**Key Technologies**:
- Block protocol standard
- CRDT for collaboration
- Plugin architecture

## Module API Design

### Standard Module Interface
```typescript
// Every module should export
export interface CoreModule<T = any> {
  // Initialization
  init(config?: ModuleConfig): Promise<void>
  
  // Lifecycle
  start(): Promise<void>
  stop(): Promise<void>
  destroy(): Promise<void>
  
  // State
  getState(): T
  setState(state: Partial<T>): void
  subscribe(listener: (state: T) => void): () => void
  
  // Plugin system
  use(plugin: Plugin): void
  
  // Serialization
  serialize(): string
  deserialize(data: string): void
}
```

## Documentation Requirements

### Each Module Must Have
1. **README.md**: Overview and quick start
2. **API.md**: Complete API documentation
3. **ARCHITECTURE.md**: Design decisions and patterns
4. **CHANGELOG.md**: Version history
5. **CONTRIBUTING.md**: Development guidelines
6. **Examples/**: Usage examples for each platform

## Integration Patterns

### Platform Integration
```typescript
// Platform adapter pattern
import { MarkdownEditor } from '@umemee/markdown-editor'
import { WebAdapter } from '@umemee/markdown-editor/adapters/web'

const editor = new MarkdownEditor({
  adapter: new WebAdapter(),
  plugins: [/* ... */]
})

// React hook wrapper
export function useMarkdownEditor(config) {
  const [editor] = useState(() => new MarkdownEditor(config))
  
  useEffect(() => {
    editor.init()
    return () => editor.destroy()
  }, [])
  
  return editor
}
```

## Future Considerations

1. **More Modules**:
   - Search engine
   - Sync engine
   - AI integration module
   - Analytics module
   - Authentication module

2. **Module Marketplace**: Platform for sharing community modules

3. **Module Federation**: Dynamic loading of modules at runtime

4. **WASM Modules**: Performance-critical modules in WebAssembly

5. **Module Composition**: Combining modules for complex features