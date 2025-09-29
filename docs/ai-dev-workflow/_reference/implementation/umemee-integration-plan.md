# Agent Orchestration Application Analysis for umemee-v0

## Current Project State vs Orchestration Requirements

### 1. Integration Points with umemee-v0

The agent orchestration system maps to umemee-v0's architecture as follows:

#### Monorepo Structure Alignment
- **platforms/** modules would each get risk scoring based on criticality
  - `web/`: Medium risk (0.25-0.60) - user-facing changes
  - `mobile/`: Medium-High risk (0.40-0.70) - app store deployment implications
  - `desktop/`: Currently disabled, would be Low risk during Tauri migration

- **shared/** packages require careful orchestration
  - `types/`: HIGH risk (0.60+) - breaks everything downstream
  - `api-client/`: HIGH risk (0.60+) - affects all platforms
  - `config/`: Medium risk (0.25-0.60) - configuration changes
  - `utils/`: Low-Medium risk (0.10-0.40) - isolated functions
  - `ui-web/`, `ui-mobile/`: Low risk (0.10-0.25) - UI components

#### Critical Files Pattern Matching
Based on the orchestration docs, these paths would trigger HIGH risk:
- `**/auth/**` - Authentication logic (not yet implemented)
- `**/payments/**` - Payment processing (not yet implemented)
- `**/migrations/**` - Database migrations (not yet implemented)
- `**/secrets/**` - Secrets management (not yet implemented)
- `shared/types/**` - Type definitions (foundational)
- `shared/api-client/**` - API communication layer

### 2. Immediate Implementation Needs

#### Required Infrastructure
1. **.aiops/policy.yaml** - Risk scoring configuration
2. **.github/workflows/ai-router.yml** - GitHub Actions workflow
3. **scripts/ai/** directory with:
   - `risk.ts` - Risk scoring implementation
   - `router.ts` - Chain decision logic
4. **scripts/ci/** directory with:
   - `apply-patch.js` - LLM_PATCH application
   - `apply-suggestions.js` - Review integration
   - `request-human-gate.js` - Human approval workflow

#### Missing Dependencies
- Octokit for GitHub API interaction
- js-yaml for policy parsing
- Agent CLI wrappers (Claude, Cursor, Codex, Gemini)

### 3. Work Items & Decisions Needed

#### Immediate Decisions Required

**DECISION-001: Agent Selection**
- Which agents to enable initially?
- Current GitHub Actions has claude-code, need others?
- Cost implications of each agent tier

**DECISION-002: Risk Thresholds**
- Adjust default thresholds for umemee-v0 context?
- Current: low < 0.25, high > 0.60
- Consider: More conservative for production readiness?

**DECISION-003: Budget Limits**
- Default $2.50/PR appropriate?
- Different limits for different package types?
- Monthly cap considerations?

**DECISION-004: Critical Paths**
- Define critical paths beyond default patterns
- Platform-specific critical paths?
- Deployment-blocking paths?

#### Implementation Tasks

**Phase 1: Foundation (Priority)**
1. Create .aiops/policy.yaml with umemee-specific weights
2. Setup GitHub labels (ai:low, ai:med, ai:high, etc.)
3. Implement basic risk scoring for monorepo structure
4. Create minimal ai-router.yml workflow

**Phase 2: Agent Integration**
1. Wrap Claude Code in standardized CLI interface
2. Add Cursor integration (if available)
3. Setup Gemini API access
4. Implement token bucket management

**Phase 3: Review Chains**
1. Implement Chain A for low-risk changes (UI components)
2. Setup Chain B for medium-risk (config, utils)
3. Configure Chain C with human gates for types/, api-client/

**Phase 4: Monitoring & Learning**
1. Setup metrics collection
2. Implement learning store
3. Create feedback loop for weight adjustment

### 4. Risk Assessment for Implementation

#### Risks
1. **Complexity Overhead**: Full system may be overkill for current project size
2. **Cost Escalation**: Without proper caps, agent costs could spiral
3. **False Positives**: Risk scoring might be too conservative initially
4. **Integration Effort**: Significant work to integrate all agents

#### Mitigations
1. Start with single chain (A) and one agent (Claude)
2. Implement hard budget caps from day one
3. Manual override commands for all automated decisions
4. Incremental rollout with monitoring

### 5. Recommended Minimal Viable Implementation

Start with:
1. Simple risk scoring based on file paths
2. Single agent (Claude Code) with budget cap
3. GitHub labels for manual override
4. Basic ai-router.yml that:
   - Scores risk
   - Routes to Claude if risk < 0.60
   - Requires human approval if risk ≥ 0.60

This provides value immediately while allowing gradual sophistication.

### 6. Configuration Mapping

Map umemee-v0 structure to orchestration config:

```yaml
# Proposed .aiops/policy.yaml for umemee-v0
version: 1
risk:
  weights:
    patch_lines_norm: 0.15    # Less weight on size
    critical_files: 0.35       # More weight on critical paths
    coverage_drop: 0.10        # Less weight until tests mature
    static_sev: 0.20
    self_conf_neg: 0.10
    changed_endpoints: 0.10
  critical_patterns:
    - "shared/types/**"        # Type changes affect everything
    - "shared/api-client/**"   # API changes affect all platforms
    - "**/package.json"        # Dependency changes
    - "turbo.json"            # Build pipeline changes
    - "pnpm-workspace.yaml"   # Workspace structure
  thresholds:
    low: 0.20                 # Slightly lower for agility
    high: 0.55                # Slightly lower for current stage
```

### 7. Next Steps

1. **Validate** this analysis with project goals
2. **Decide** on initial agent set and budgets
3. **Create** work items for Phase 1 implementation
4. **Test** with low-risk changes first
5. **Monitor** and adjust based on results