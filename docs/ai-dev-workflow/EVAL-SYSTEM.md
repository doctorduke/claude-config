# Process Evaluation & Improvement System

## Purpose
Measure, analyze, and optimize every dimension of our development workflow from task issuance to deployment.

## Core Evaluation Dimensions

### 1. Task Lifecycle Metrics
```yaml
dimensions:
  task_clarity:
    input: Issue description completeness (0-1)
    formula: (has_acceptance + has_interface + has_risk) / 3
    target: > 0.8

  task_to_pr_time:
    input: Hours from issue creation to PR
    formula: pr_created_at - issue_created_at
    target: < 24h for low risk

  pr_to_merge_time:
    input: Hours from PR to merge
    formula: merged_at - pr_created_at
    target: < 4h for Chain A

  rework_rate:
    input: Number of review cycles
    formula: review_requested_count / PR_count
    target: < 1.5
```

### 2. Agent Performance Metrics
```yaml
dimensions:
  agent_accuracy:
    input: Successful completions / attempts
    formula: success_count / total_runs
    target: > 0.85

  agent_cost_efficiency:
    input: $ per successful task
    formula: total_cost / successful_tasks
    target: < $2.00

  parallel_efficiency:
    input: Time saved via parallelization
    formula: sequential_time - parallel_time
    target: > 40% reduction
```

### 3. Process Quality Metrics
```yaml
dimensions:
  brief_coverage:
    input: Modules with complete BRIEFs
    formula: complete_briefs / total_modules
    target: 100%

  decision_capture_rate:
    input: Decisions with dates/rationale
    formula: documented_decisions / total_decisions
    target: > 90%

  post_merge_defect_rate:
    input: Bugs found after merge
    formula: post_merge_bugs / merged_prs
    target: < 2%
```

## Feedback Loop Implementation

### Collection Points
1. **Task Start**: Capture clarity, requirements completeness
2. **Agent Execution**: Token usage, time, errors
3. **Review Phase**: Changes requested, risk reassessment
4. **Post-Merge**: Defects, reverts, performance

### Analysis Pipeline
```
Collect → Normalize → Calculate → Compare → Recommend → Adjust
   ↓         ↓           ↓          ↓          ↓          ↓
Events   0-1 scale   Formulas   Targets   Changes   Prompts
```

### Improvement Actions
```yaml
if task_clarity < 0.8:
  action: Enforce issue template

if agent_accuracy < 0.85:
  action: Refine prompts, adjust risk weights

if rework_rate > 1.5:
  action: Strengthen Chain A review

if cost > budget:
  action: Lower risk thresholds, increase early exit
```

## Recording & Reporting Structure

### Event Schema
```typescript
interface EvalEvent {
  id: string
  timestamp: Date
  type: 'task' | 'agent' | 'review' | 'merge'
  dimensions: Record<string, number>
  context: {
    issue_id?: number
    pr_id?: number
    agent?: string
    chain?: 'A' | 'B' | 'C'
  }
}
```

### Storage
```yaml
.aiops/
├── metrics/
│   ├── daily/
│   │   └── 2025-09-28.jsonl
│   ├── aggregates/
│   │   └── weekly.json
│   └── recommendations/
│       └── current.yaml
```

### Reports
1. **Daily Standup**: Key metrics, blockers, recommendations
2. **Sprint Retro**: Trends, improvements, configuration changes
3. **Monthly Deep Dive**: Full analysis, prompt refinements

## Integration Points

### With BRIEF System
- Update Work State automatically
- Track Interface Contract changes
- Measure decision documentation rate

### With Agent Orchestration
- Adjust risk weights based on accuracy
- Tune token budgets based on efficiency
- Modify chain thresholds based on rework

### With Git Workflow
- Measure branch lifetime
- Track commit quality
- Identify revert patterns

## Success Criteria
- 20% reduction in task-to-merge time per sprint
- 50% reduction in rework rate within 3 sprints
- Cost per PR < $1.50 average
- Zero direct trunk commits
- 100% BRIEF coverage maintained