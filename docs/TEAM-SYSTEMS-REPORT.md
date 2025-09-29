# umemee-v0 Development Systems Report

*Generated: 2025-09-28*
*Purpose: Team synchronization on tooling, processes, and automation*

## Executive Summary

We have established a comprehensive development infrastructure combining documentation systems (BRIEF), AI agent orchestration, and automated workflows. This report details our current capabilities, processes, and areas for improvement.

## 1. Documentation System (BRIEF v3)

### Current State
- **22 BRIEFs deployed** across all modules
- **Interface-first approach** enforced (Inputs → Outputs)
- **Module-scoped** documentation (each BRIEF covers its module only)
- **_reference/** directories for detailed specifications

### Key Protocol
```
Document Ingestion: Source → Mapping Matrix → BRIEF
- PRDs → Interface Contract (requirements to inputs/outputs)
- Tech Docs → Dependencies & Spec Snapshot
- Chats → Decisions & Rationale
- Images → UI flows in Interface Contract
```

### Quality Gates
- Interface Contract required (Inputs/Outputs defined)
- Under 200 lines (details in _reference/)
- Dated SPEC_SNAPSHOT
- INFERRED: markers for uncertain content

### Deployment Command
```bash
/init-briefs  # Self-deploys with proper instructions
```

## 2. AI Agent Orchestration

### Architecture
```
Risk Scoring → Chain Selection → Agent Execution → Review → Merge
     ↓              ↓                  ↓              ↓        ↓
  (0.0-1.0)    (A/B/C chains)   (Claude/Codex)   (Review)  (Auto)
```

### Review Chains
| Chain | Risk Level | Agents | Human Gate | Use Case |
|-------|-----------|--------|------------|----------|
| A | < 0.25 | Cursor → Codex | No | UI components, utils |
| B | 0.25-0.60 | Codex → Gemini → Claude | No | Config, API changes |
| C | > 0.60 | Claude → Gemini | Yes | Types, critical paths |

### Risk Scoring Weights
```yaml
patch_lines_norm: 0.15    # Size of change
critical_files: 0.35      # shared/types/**, api-client/**
coverage_drop: 0.10       # Test coverage impact
static_sev: 0.20         # Security/quality findings
self_conf_neg: 0.10      # Agent confidence
changed_endpoints: 0.10  # API surface changes
```

### Budget Controls
- **Token Buckets**: Per-agent capacity limits
- **Circuit Breaker**: Opens after 3 errors
- **Cost Cap**: $2.50/PR default
- **Early Exit**: Merge on green when budget < 70%

## 3. GitHub Integration

### Workflows
```yaml
ai-agents-matrix.yml    # Dispatches to parallel agents
claude.yml             # Claude bot workflow
codex.yml.example      # Template for Codex
gemini.yml             # (Planned) Gemini integration
```

### Labels & Commands
- **Risk Override**: `ai:low`, `ai:med`, `ai:high`
- **Agent Subscribe**: `ai:security`, `ai:lint`, `ai:docs`
- **Slash Commands**: `/route`, `/budget`, `/escalate`, `/halt`

### Issues Tracking (#20-27)
- Phase 1: Foundation (policy, labels, risk scoring)
- Phase 2: Agent Integration (CLI wrappers, token buckets)
- Phase 3: Review Chains (escalation logic, human gates)

## 4. Git Workflow & Hygiene

### Current Problems
- ❌ Working directly on trunk
- ❌ No branch protection (free GitHub tier)
- ❌ Inconsistent branch naming

### Proposed Solutions
```bash
# Pre-push hook to prevent trunk pushes
#!/bin/bash
if [ "$(git rev-parse --abbrev-ref HEAD)" = "trunk" ]; then
  echo "Direct push to trunk blocked! Create a feature branch."
  exit 1
fi
```

### Branch Strategy
- `feat/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation
- `chore/` - Maintenance
- ALL work through PRs (even self-merged)

## 5. Task Generation & Automation

### Current Capability
- GitHub issue creation via API
- Linked issues in commits
- Work State tracking in BRIEFs

### Proposed Enhancement
```yaml
# Task template in .github/ISSUE_TEMPLATE/task.yml
name: Development Task
fields:
  - id: brief_module
    label: BRIEF Module
    description: Which module does this affect?
  - id: interface_changes
    label: Interface Changes
    description: Changes to Inputs/Outputs?
  - id: risk_estimate
    label: Risk Level
    options: [Low, Medium, High]
```

### Agent Chain for Tasks
```
Task Issue → Risk Assessment → Chain Assignment → Implementation → Review → Update BRIEF
```

## 6. Team Communication Process

### Documentation Updates
1. Changes require BRIEF updates in same PR
2. Decisions logged with dates
3. Work State reflects current sprint

### Agent Coordination
- Multiple agents can work in parallel
- Each has distinct identity (Claude Bot, Codex Bot)
- Risk-based routing prevents conflicts

### Bad Decision Prevention
```bash
# Git blame analysis for repeated issues
git log --grep="revert" --oneline | \
  xargs -I {} git show {} --stat | \
  grep -E "^\s+(\S+)" | \
  sort | uniq -c | sort -rn

# Top reverted files indicate decision problems
```

## 7. Open Questions Requiring Team Decision

1. **Agent API Keys**: Who manages Codex/Gemini keys?
2. **Budget Limits**: Is $2.50/PR appropriate?
3. **Risk Thresholds**: Adjust 0.25/0.60 boundaries?
4. **Human Gates**: Which paths always need review?
5. **Branch Protection**: Implement client-side enforcement?
6. **Task Templates**: Standardize issue format?
7. **Agent Identity**: How to distinguish bot comments?

## 8. Immediate Action Items

### Today (Before Development)
- [ ] Switch to feature branch (off trunk)
- [ ] Setup pre-push hook
- [ ] Validate all BRIEFs have Interface Contracts

### This Week
- [ ] Deploy Phase 1 orchestration (issue #20)
- [ ] Get API keys for Codex/Gemini
- [ ] Test agent parallel execution

### This Sprint
- [ ] Implement review chains
- [ ] Create task templates
- [ ] Document bad decision patterns

## 9. Success Metrics

### Documentation
- 100% modules have BRIEFs
- 90% decisions captured with dates
- All PRs update affected BRIEFs

### Automation
- 70% PRs resolved at Chain A (low risk)
- <2% post-merge defect rate
- Average PR cost < $2.00

### Process
- Zero direct trunk commits
- All work through feature branches
- Task issues created before implementation

## 10. Appendices

### A. File Locations
```
/docs/ai-dev-workflow/         # Orchestration docs
/.github/workflows/            # Agent workflows
/CLAUDE.md                     # Agent instructions
/BRIEF.md                      # Root documentation
/.github/git-workflow-rules.md # Git processes
```

### B. Command Reference
```bash
/init-briefs          # Initialize BRIEF system
/brief-ingest <doc>   # Parse document to BRIEF
/brief-status         # Check BRIEF coverage
/route low|med|high   # Override risk routing
/budget <amount>      # Set PR budget
```

### C. Integration Status
- ✅ BRIEF System v3
- ✅ Claude Agent
- ✅ GitHub Issues API
- 🚧 Codex Agent (example ready)
- 🚧 Gemini Integration
- 🚧 CodeRabbit
- ⏳ Pre-push hooks
- ⏳ Task templates

---

*This report establishes our baseline. Update after each sprint to track evolution.*