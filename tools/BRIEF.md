# Development Tools — BRIEF

## Purpose & Boundary

Development and automation tooling that orchestrates monorepo workflows. Boundary includes git management (subtree/worktree), MCP server configuration, build scripts, and development helpers. Parent module for specialized tool submodules.

## Interface Contract (Inputs → Outputs)

**Inputs**
- Developer commands (shell/npm scripts)
- Git operations (branch, subtree, worktree management)
- Build triggers from turbo pipeline
- MCP server configuration requests

**Outputs**
- Automated workflow execution
- Git tree/worktree state changes
- Build artifacts and reports
- Development environment setup
- MCP server connections

**Command Surface**
- Direct execution: `./tools/{tool}/index.sh`
- NPM scripts: `pnpm tool:{category}:{action}`
- CLI invocation: `npx umemee-cli`

**Anti-Goals**
- Not a CI/CD system replacement
- Not a package manager replacement
- Not responsible for business logic

## Dependencies & Integration Points

**Upstream**
- Git for version control operations
- Node.js/pnpm for script execution
- Turborepo build pipeline triggers
- MCP servers for enhanced capabilities

**Downstream**
- All platform packages consume build tools
- Developer workflows depend on automation
- CI/CD pipelines execute tool scripts

## Work State (Planned / Doing / Done)

- **Planned**: Unified CLI entry point for all tools
- **Planned**: Plugin architecture for tool extensions
- **Done**: Git subtree management scripts
- **Done**: Git worktree utilities
- **Done**: MCP server setup automation

## Spec Snapshot (2025-09-27)

- Features: Git subtree/worktree management, MCP server config, build scripts
- Tech choices: Bash scripts for git ops, Node.js for complex tools
- Key scripts: subtree operations, worktree management, MCP setup
- Full spec: See CLAUDE.md for detailed tool documentation

## Decisions & Rationale

- 2025-09-20 — Bash for git operations (native git integration)
- 2025-09-20 — Separate subtree/worktree directories (clear separation of concerns)
- 2025-09-25 — MCP servers for enhanced development capabilities

## Local Reference Index

- **subtree/** → [README](subtree/README.md)
  - Git subtree management for external module integration
  - Key scripts: add.sh, update.sh, push.sh
- **worktree/** → [README](worktree/README.md)
  - Git worktree utilities for parallel development
  - Key scripts: create.sh, list.sh, clean.sh
- **mcp/** → Configuration for Model Context Protocol servers
  - Enhanced capabilities via filesystem, github, playwright servers

## Answer Pack

```yaml
kind: answerpack
module: tools
intent: "Orchestrate development workflows and build automation for monorepo"
surfaces:
  command_line:
    key_flows: ["git subtree add", "worktree create", "mcp setup"]
    acceptance: ["scripts execute without errors", "git state updates correctly"]
work_state:
  planned: ["unified-cli", "plugin-architecture"]
  doing: []
  done: ["subtree-scripts", "worktree-utils", "mcp-setup"]
interfaces:
  inputs: ["shell-commands", "npm-scripts", "git-operations", "build-triggers"]
  outputs: ["workflow-execution", "git-state", "build-artifacts", "env-setup"]
spec_snapshot_ref: CLAUDE.md
truth_hierarchy: ["source", "tests", "docs", "issues", "chat"]
```