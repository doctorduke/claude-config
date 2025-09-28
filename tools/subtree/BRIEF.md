# Git Subtree Management — BRIEF

## Purpose & Boundary

Automated git subtree management tools for integrating external repositories into the umemee monorepo. Manages bidirectional synchronization of service modules and external dependencies while preserving clean history and contribution ability.

**Boundary**: Shell scripts for git subtree operations (add, update, push). Does not handle submodules, worktrees, or direct repository management.

## Interface Contract (Inputs → Outputs)

**Inputs**
- Service name, repository URL, branch specification via CLI arguments
- Git repository state and remote configurations
- User permissions for remote repository access

**Outputs**
- Integrated service code at `services/<service-name>` path
- Git remotes configured for bidirectional sync
- Squashed merge commits preserving upstream history
- Success/failure status with operation guidance

**Anti-Goals**
- Does not manage git submodules (use native git commands)
- Does not handle authentication (assumes configured SSH/tokens)
- Does not perform automatic conflict resolution
- Does not manage worktrees (see ../worktree/)

## Dependencies & Integration Points

**Upstream**
- Git 2.0+ with subtree support
- Bash 4.0+ shell environment
- SSH keys or access tokens for remote repositories

**Downstream**
- Services integrated at `services/` directory
- Core modules at `core-modules/` for shared components
- CI/CD pipelines consuming integrated code

## Work State (Planned / Doing / Done)

- **Planned**: Config-driven batch operations for multiple subtrees
- **Planned**: Automatic conflict resolution strategies
- **Done**: Basic add/update/push script implementation

## Spec Snapshot (2025-09-27)

- **Features**: Add service, update from upstream, push to upstream
- **Scripts**: add-service.sh, update-service.sh, push-service.sh
- **Tech**: Bash scripts wrapping git subtree commands
- **Full docs**: README.md, CLAUDE.md for detailed usage

## Decisions & Rationale

- 2024-09-26 — Choose git subtree over submodules (complete code in repo, simpler workflow)
- 2024-09-26 — Use squash merges by default (clean main branch history)
- 2024-09-26 — Service prefix pattern `services/<name>` (clear separation from core code)

## Local Reference Index

- **Scripts**:
  - `add-service.sh` → Add new service as subtree
  - `update-service.sh` → Pull upstream changes
  - `push-service.sh` → Push local changes upstream
- **Docs**:
  - `README.md` → Usage examples and best practices
  - `CLAUDE.md` → AI-friendly detailed instructions

## Answer Pack

```yaml
kind: answerpack
module: tools/subtree
intent: "Manage git subtrees for external repository integration"
surfaces:
  cli:
    key_flows:
      - "add-service.sh <name> <url> [branch]"
      - "update-service.sh <name> [branch]"
      - "push-service.sh <name> [branch]"
    acceptance:
      - "Service code appears at services/<name>"
      - "Can pull upstream updates without conflicts"
      - "Can push local changes to service repo"
work_state:
  planned: ["config-driven-batch", "auto-conflict-resolution"]
  doing: []
  done: ["basic-scripts"]
interfaces:
  inputs: ["service-name", "repo-url", "branch-name", "git-state"]
  outputs: ["integrated-code", "merge-commits", "remote-configs", "status-messages"]
spec_snapshot_ref: README.md
truth_hierarchy: ["scripts", "git-history", "BRIEF", "CLAUDE", "README"]
```