# DEPRECATED - Migrating to Tauri

## Purpose
The desktop platform delivers umemee as a native desktop application using Tauri, combining a Rust backend with a React frontend. This platform provides system-level integration, file system access, native performance, and enhanced security while maintaining a small bundle size and resource footprint.

## Dependencies

### Internal Dependencies
- `@umemee/ui-web` - Web UI components (adapted for desktop)
- `@umemee/types` - Shared TypeScript definitions
- `@umemee/api-client` - API client for backend communication
- `@umemee/config` - Shared configuration
- `@umemee/utils` - Common utility functions
- Core modules from `core-modules/` when implemented

### External Dependencies
- **Tauri 2.0+** - Rust-based desktop framework
- **React 18+** - UI library
- **Vite** - Build tool and dev server
- **Rust** - Backend language for Tauri
- **WebView2 (Windows)** - Web rendering engine
- **WebKit (macOS/Linux)** - Web rendering engine
- **TanStack Query** - Server state management
- **Zustand** - Client state management

## Key Files

```
desktop/
├── src/                   # Frontend source
│   ├── App.tsx           # Main React app
│   ├── main.tsx         # Entry point
│   ├── components/       # React components
│   ├── hooks/           # Custom hooks
│   ├── lib/             # Libraries and utilities
│   └── styles/          # Styling
├── src-tauri/            # Rust backend
│   ├── src/
│   │   ├── main.rs       # Rust entry point
│   │   ├── commands.rs   # Tauri commands
│   │   └── lib.rs       # Library exports
│   ├── Cargo.toml       # Rust dependencies
│   ├── tauri.conf.json  # Tauri configuration
│   └── icons/           # App icons
├── index.html            # HTML entry
├── vite.config.ts        # Vite configuration
├── tsconfig.json         # TypeScript config
└── package.json          # Node dependencies
```

## Conventions

### Frontend Structure
```typescript
// Frontend component pattern
import { invoke } from '@tauri-apps/api/tauri'
import { listen } from '@tauri-apps/api/event'

export function FileManager() {
  // Call Rust backend
  const openFile = async () => {
    const contents = await invoke('read_file', { 
      path: '/path/to/file' 
    })
    return contents
  }
  
  // Listen to backend events
  useEffect(() => {
    const unlisten = listen('file-changed', (event) => {
      console.log('File changed:', event.payload)
    })
    return () => { unlisten.then(fn => fn()) }
  }, [])
}
```

### Backend Structure
```rust
// src-tauri/src/commands.rs
use tauri::command;

#[command]
fn read_file(path: String) -> Result<String, String> {
    std::fs::read_to_string(path)
        .map_err(|e| e.to_string())
}

#[command]
async fn fetch_data(url: String) -> Result<String, String> {
    // Async command implementation
    Ok("data".to_string())
}
```

### IPC Communication
```typescript
// Frontend -> Backend
import { invoke } from '@tauri-apps/api/tauri'

const result = await invoke('command_name', { 
  arg1: 'value' 
})

// Backend -> Frontend
import { emit } from '@tauri-apps/api/event'

await emit('event-name', { data: 'payload' })
```

## Testing

### Test Setup
```bash
# Frontend tests
pnpm test

# Rust tests
cd src-tauri && cargo test

# Integration tests
pnpm test:integration

# E2E tests
pnpm test:e2e
```

### Testing Strategy
- **Frontend Unit Tests**: Vitest for React components
- **Backend Unit Tests**: Rust's built-in test framework
- **Integration Tests**: Test IPC communication
- **E2E Tests**: WebDriver for full app testing
- **Platform Testing**: Test on Windows, macOS, Linux

## Common Tasks

### Development
```bash
# Start development server
pnpm tauri dev

# Start with specific features
pnpm tauri dev -- --features custom-feature

# Start with debug logging
RUST_LOG=debug pnpm tauri dev

# Hot reload frontend only
pnpm dev
```

### Building
```bash
# Build for current platform
pnpm tauri build

# Build for specific target
pnpm tauri build --target x86_64-pc-windows-msvc
pnpm tauri build --target x86_64-apple-darwin
pnpm tauri build --target x86_64-unknown-linux-gnu

# Build with custom config
pnpm tauri build -- --config custom.conf.json

# Build debug version
pnpm tauri build --debug
```

### Managing Rust Dependencies
```bash
# Add Rust dependency
cd src-tauri && cargo add serde

# Update Rust dependencies
cd src-tauri && cargo update

# Check for outdated
cd src-tauri && cargo outdated
```

## Gotchas

### Common Issues
1. **WebView2 Installation**: Required on Windows, auto-downloaded
2. **Code Signing**: Required for distribution on macOS/Windows
3. **Permissions**: File system access needs proper configuration
4. **IPC Types**: Keep TypeScript and Rust types synchronized
5. **Bundle Size**: Monitor Rust dependencies for size
6. **Memory Leaks**: Properly cleanup event listeners

### Platform-Specific Issues
- **Windows**: Antivirus may flag unsigned builds
- **macOS**: Gatekeeper and notarization requirements
- **Linux**: Different distributions need different packages

### Security Considerations
- CSP is enforced by default
- IPC commands must be explicitly allowed
- File system access is sandboxed
- External URLs need allowlisting

## Architecture Decisions

### Why Tauri?
- **Performance**: Native performance with Rust backend
- **Security**: Sandboxed with minimal attack surface
- **Size**: ~10MB bundles vs 50-150MB Electron
- **Memory**: Lower memory footprint
- **Native APIs**: Direct system integration

### Frontend Architecture
- React for familiar development experience
- Vite for fast builds and HMR
- TypeScript for type safety
- Tailwind CSS for styling

### Backend Architecture
```rust
// Modular Rust structure
mod commands;      // Tauri commands
mod state;        // Application state
mod database;     // Local database
mod filesystem;   // File operations
mod system;       // System integration
```

## Performance Considerations

### Startup Performance
- Minimize initial bundle size
- Lazy load heavy components
- Optimize Rust compilation (release mode)
- Use splash screen for perceived performance

### Runtime Performance
```rust
// Use async commands for heavy operations
#[command]
async fn heavy_operation() -> Result<String, String> {
    tokio::spawn(async {
        // Heavy computation
    }).await.map_err(|e| e.to_string())
}
```

### Memory Management
- Monitor WebView memory usage
- Clean up Rust resources properly
- Use weak references where appropriate
- Implement proper Drop traits

## Security Notes

### Tauri Security Config
```json
// tauri.conf.json
{
  "tauri": {
    "security": {
      "csp": "default-src 'self'",
      "dangerousDisableAssetCspModification": false
    },
    "allowlist": {
      "all": false,
      "fs": {
        "all": false,
        "readFile": true,
        "writeFile": true,
        "scope": ["$APP/*"]
      },
      "shell": {
        "all": false,
        "open": true
      },
      "protocol": {
        "all": false,
        "asset": true
      }
    }
  }
}
```

### Secure Storage
```rust
// Use OS keychain for sensitive data
use keyring::Entry;

#[command]
fn store_secret(key: String, value: String) -> Result<(), String> {
    let entry = Entry::new("umemee", &key)?;
    entry.set_password(&value)?;
    Ok(())
}
```

## Native Features

### File System Access
```rust
#[command]
fn read_file(path: PathBuf) -> Result<Vec<u8>, String> {
    std::fs::read(path).map_err(|e| e.to_string())
}

#[command]
fn write_file(path: PathBuf, contents: Vec<u8>) -> Result<(), String> {
    std::fs::write(path, contents).map_err(|e| e.to_string())
}
```

### System Tray
```rust
// Setup system tray
use tauri::SystemTray;

fn main() {
    let tray = SystemTray::new()
        .with_menu(tray_menu());
    
    tauri::Builder::default()
        .system_tray(tray)
        .run(tauri::generate_context!())
        .expect("error running tauri app");
}
```

### Native Menus
```rust
// Create native menu bar
use tauri::Menu;

fn create_menu() -> Menu {
    let menu = Menu::new()
        .add_native_item(MenuItem::Copy)
        .add_native_item(MenuItem::Paste);
    menu
}
```

### Window Management
```typescript
// Frontend window control
import { appWindow } from '@tauri-apps/api/window'

// Minimize, maximize, close
await appWindow.minimize()
await appWindow.maximize()
await appWindow.close()

// Create new window
const webview = new WebviewWindow('settings', {
  url: 'settings.html',
  width: 600,
  height: 400
})
```

## Database Integration

### SQLite with SQLx
```rust
// src-tauri/src/database.rs
use sqlx::sqlite::SqlitePool;

#[derive(Debug, serde::Serialize)]
struct User {
    id: i32,
    name: String,
}

#[command]
async fn get_users(state: tauri::State<'_, DbState>) -> Result<Vec<User>, String> {
    let users = sqlx::query_as!(User, "SELECT * FROM users")
        .fetch_all(&state.pool)
        .await
        .map_err(|e| e.to_string())?;
    Ok(users)
}
```

## Auto-Update

### Configure Updates
```json
// tauri.conf.json
{
  "tauri": {
    "updater": {
      "active": true,
      "endpoints": [
        "https://updates.umemee.com/{{target}}/{{current_version}}"
      ],
      "dialog": true,
      "pubkey": "YOUR_PUBLIC_KEY"
    }
  }
}
```

### Handle Updates
```typescript
import { checkUpdate, installUpdate } from '@tauri-apps/api/updater'

const update = await checkUpdate()
if (update.shouldUpdate) {
  await installUpdate()
  await relaunch()
}
```

## Distribution

### Code Signing
```bash
# macOS
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Your Name" \
  --options runtime target/release/bundle/macos/Umemee.app

# Windows
signtool sign /tr http://timestamp.digicert.com /td sha256 \
  /fd sha256 /a target/release/bundle/msi/Umemee.msi
```

### Creating Installers
```bash
# Build installers
pnpm tauri build

# Output locations
# Windows: target/release/bundle/msi/
# macOS: target/release/bundle/dmg/
# Linux: target/release/bundle/appimage/
```

### Auto-Update Server
```json
// Update manifest
{
  "version": "1.2.0",
  "notes": "Bug fixes and improvements",
  "pub_date": "2024-01-01T00:00:00Z",
  "platforms": {
    "darwin-x86_64": {
      "signature": "...",
      "url": "https://cdn.umemee.com/releases/1.2.0/Umemee.app.tar.gz"
    },
    "windows-x86_64": {
      "signature": "...",
      "url": "https://cdn.umemee.com/releases/1.2.0/Umemee.msi.zip"
    }
  }
}
```

## Monitoring

### Error Tracking
```rust
// Integrate Sentry
use sentry;

fn main() {
    let _guard = sentry::init(("DSN", sentry::ClientOptions {
        release: sentry::release_name!(),
        ..Default::default()
    }));
}
```

### Analytics
```typescript
// Frontend analytics
import { trackEvent } from './analytics'

trackEvent('app_launched', {
  version: await getVersion(),
  platform: await platform()
})
```

## Accessibility

### Keyboard Navigation
```typescript
// Global keyboard shortcuts
import { register } from '@tauri-apps/api/globalShortcut'

await register('CommandOrControl+N', () => {
  // New document
})

await register('CommandOrControl+O', () => {
  // Open file
})
```

### Screen Reader Support
- Use semantic HTML
- Provide ARIA labels
- Ensure keyboard accessibility
- Test with screen readers

## Platform Integration

### Deep OS Integration
```rust
// File associations
#[cfg(target_os = "windows")]
fn register_file_association() {
    // Windows registry manipulation
}

#[cfg(target_os = "macos")]
fn register_file_association() {
    // macOS Info.plist configuration
}

#[cfg(target_os = "linux")]
fn register_file_association() {
    // .desktop file configuration
}
```

## Future Enhancements

1. Implement plugin system with WASM
2. Add multi-window support
3. Integrate native notifications
4. Implement global search with OS integration
5. Add cloud sync capabilities
6. Implement collaborative features
7. Add CLI companion tool
8. Support ARM architectures