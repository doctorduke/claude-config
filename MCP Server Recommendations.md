MCP Server Recommendations

Essential (for immediate needs):
1. github ✓ (you're adding)
2. playwright ✓ (you're adding)
3. filesystem - Better file operations than built-in
4. memory - Maintain context across sessions

Highly Recommended (for your monorepo):
5. postgres/sqlite - Database for services/
6. docker - Container management
7. eslint - Direct lint fixing (would solve current CI issue!)
8. typescript - TS-specific operations

Platform-Specific (for Wave 2):
9. expo - Mobile development
10. electron/tauri - Desktop migration
11. vercel - Web deployment

The ESLint MCP would be particularly helpful right now since that's blocking your CI/CD pipeline.

Looking at your MCP Server Recommendations, I'll help you install the essential and recommended MCP servers using properly structured `claude mcp add` commands. Let me first examine your recommendations file and then provide the exact commands needed.

### 3. Filesystem MCP Server
```bash
claude mcp add filesystem --transport stdio npx @modelcontextprotocol/server-filesystem /Users/doctorduke/Developer/doctorduke/umemee-v0
```

### 4. Memory MCP Server
```bash
claude mcp add memory --transport stdio npx @modelcontextprotocol/server-memory
```

## Highly Recommended for Your Monorepo

### 5. SQLite MCP Server (for database operations)
```bash
claude mcp add sqlite --transport stdio npx @modelcontextprotocol/server-sqlite
```

### 6. Docker MCP Server
```bash
claude mcp add docker --transport stdio npx @modelcontextprotocol/server-docker
```

### 7. ESLint MCP Server (Priority - fixes your CI issue!)
```bash
claude mcp add eslint --transport stdio npx @modelcontextprotocol/server-eslint /Users/doctorduke/Developer/doctorduke/umemee-v0
```

### 8. TypeScript MCP Server
```bash
claude mcp add typescript --transport stdio npx @modelcontextprotocol/server-typescript /Users/doctorduke/Developer/doctorduke/umemee-v0
```

## Platform-Specific (For Wave 2 Development)

### 9. Expo MCP Server
```bash
claude mcp add expo --transport stdio npx @modelcontextprotocol/server-expo /Users/doctorduke/Developer/doctorduke/umemee-v0/platforms/mobile
```

### 10. Vercel MCP Server
```bash
claude mcp add vercel --transport stdio npx @modelcontextprotocol/server-vercel /Users/doctorduke/Developer/doctorduke/umemee-v0/platforms/web
```

## Installation Priority

**Start with these in order:**
1. **ESLint** (immediate CI/CD fix)
2. **Filesystem** (better file operations)
3. **Memory** (context persistence)
4. **TypeScript** (your project is TypeScript-heavy)

## Verification Commands

After installation, verify with:
```bash
claude mcp list
```

And test ESLint integration (your priority):
```bash
/mcp__eslint__fix_file eslint.config.mjs
```

## Alternative Manual Configuration

If `claude mcp add` doesn't work as expected, you can manually add these to your Claude configuration file at `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/doctorduke/Developer/doctorduke/umemee-v0"]
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    },
    "eslint": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-eslint", "/Users/doctorduke/Developer/doctorduke/umemee-v0"]
    },
    "typescript": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-typescript", "/Users/doctorduke/Developer/doctorduke/umemee-v0"]
    }
  }
}
```

