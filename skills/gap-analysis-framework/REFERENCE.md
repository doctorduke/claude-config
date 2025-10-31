# Gap Analysis Framework Reference

Complete reference documentation for frameworks, templates, and scoring systems.

## Table of Contents
1. [SWOT Template](#swot-template)
2. [Capability Maturity Model (CMM)](#capability-maturity-model)
3. [Impact/Effort Matrix](#impacteffort-matrix)
4. [Gap Scoring & Prioritization](#gap-scoring)
5. [Assessment Checklists](#assessment-checklists)
6. [Report Templates](#report-templates)

---

## SWOT Template

### SWOT Analysis Matrix

```
┌────────────────────────────────────────────┬────────────────────────────────────────────┐
│ STRENGTHS (Internal, Positive)             │ WEAKNESSES (Internal, Negative)            │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ • What we do well                          │ • What's missing (GAPS)                    │
│ • Competitive advantages                   │ • Resource constraints                     │
│ • Unique capabilities                      │ • Skill gaps                               │
│ • Strong team/culture                      │ • Technical debt                           │
│ • Strategic assets                         │ • Process limitations                      │
│                                            │ • Infrastructure deficiencies              │
│                                            │ • Organizational weaknesses                │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ OPPORTUNITIES (External, Positive)         │ THREATS (External, Negative)               │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ • Market gaps we can fill                  │ • Competitor actions                       │
│ • Emerging technologies                    │ • Regulatory changes                       │
│ • Growing demand                           │ • Technology obsolescence                  │
│ • Partnership potential                    │ • Economic downturn                        │
│ • New revenue streams                      │ • Supply chain disruption                  │
│ • Expansion opportunities                  │ • Talent market challenges                 │
└────────────────────────────────────────────┴────────────────────────────────────────────┘
```

### SWOT Framework Template

```markdown
# SWOT Analysis - [Project/Organization Name]

## STRENGTHS

| # | Strength | Evidence | Impact |
|---|----------|----------|--------|
| 1 | [What you do well] | [Data/proof] | [Business value] |
| 2 | | | |
| 3 | | | |

Total Strengths: ___

## WEAKNESSES (GAPS)

| # | Weakness | Root Cause | Impact | Severity |
|---|----------|-----------|--------|----------|
| 1 | [What's missing] | [Why] | [Effect] | High/Med/Low |
| 2 | | | | |
| 3 | | | | |

Total Gaps: ___

## OPPORTUNITIES

| # | Opportunity | Prerequisites | Timeline | Investment |
|---|-------------|---------------|----------|------------|
| 1 | [What we could do] | [What we need first] | [When] | [Cost] |
| 2 | | | | |

## THREATS

| # | Threat | Likelihood | Impact | Mitigation |
|---|--------|-----------|--------|-----------|
| 1 | [What could go wrong] | [Probability] | [Effect] | [Prevention] |
| 2 | | | | |

## Gap-Opportunity Mapping

| Weakness | Related Opportunity | Gap to Exploit |
|----------|-------------------|----------------|
| [Gap] | [Opportunity] | [What to do] |

## Strategic Recommendations

Based on SWOT:
- **SO Strategy** (Strength-Opportunity): Use strengths to capitalize on opportunities
- **WO Strategy** (Weakness-Opportunity): Overcome weaknesses through opportunities
- **ST Strategy** (Strength-Threat): Use strengths to avoid threats
- **WT Strategy** (Weakness-Threat): Minimize weaknesses to avoid threats
```

---

## Capability Maturity Model

### CMM Levels Detailed Reference

```
┌─────────────────────────────────────────────────────────────────────────┐
│ LEVEL 1: INITIAL (Starting Point)                                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│ Characteristics:                                                       │
│ • Ad-hoc, chaotic, unpredictable processes                            │
│ • Success depends on individual heroes/heroics                        │
│ • No documented processes or procedures                               │
│ • Processes change frequently, causing instability                    │
│ • No clear accountability or ownership                                │
│ • Results are unpredictable/inconsistent                              │
│                                                                         │
│ Typical Organization Profile:                                         │
│ • Startup phase (0-1 years)                                           │
│ • New team members (first 90 days)                                    │
│ • Ad-hoc project management                                           │
│ • Success by individual contributor excellence                        │
│ • High-risk, high-reward delivery                                     │
│                                                                         │
│ Visible Gaps (Examples):                                              │
│ • No testing process (test coverage 0-20%)                            │
│ • No code review process (code quality varies widely)                 │
│ • No deployment process (manual, error-prone)                         │
│ • No monitoring (reactive incident response)                          │
│ • No documentation (tribal knowledge)                                 │
│                                                                         │
│ Path Forward:                                                         │
│ → Hire disciplined people                                             │
│ → Document basic processes                                            │
│ → Establish simple standards                                          │
│ → Timeline: 6-12 months to Level 2                                   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ LEVEL 2: REPEATABLE (Managed)                                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│ Characteristics:                                                       │
│ • Basic project management processes established                      │
│ • Can repeat previous successes                                       │
│ • Processes documented (but inconsistently followed)                  │
│ • Requirements tracked                                                │
│ • Some discipline and standards applied                               │
│ • Results are more predictable (60-80% success rate)                  │
│                                                                         │
│ Typical Organization Profile:                                         │
│ • Growing company (1-3 years)                                         │
│ • 20-100 employees                                                    │
│ • Multiple teams                                                      │
│ • Basic processes in place                                            │
│ • Some consistency across teams                                       │
│                                                                         │
│ Visible Characteristics:                                              │
│ • Some testing exists (40-50% coverage)                               │
│ • Code review process started                                         │
│ • Deployment process documented (manual but consistent)               │
│ • Basic monitoring in place                                           │
│ • Some documentation exists (README, basic APIs)                      │
│                                                                         │
│ Visible Gaps (Examples):                                              │
│ • Inconsistent process adherence                                      │
│ • Tests exist but not comprehensive                                   │
│ • No automated CI/CD                                                  │
│ • Metrics not tracked                                                 │
│ • Standards not enforced                                              │
│                                                                         │
│ Path Forward:                                                         │
│ → Define and enforce standards (make optional → mandatory)            │
│ → Automate processes (manual → automatic)                             │
│ → Implement metrics and tracking                                      │
│ → Timeline: 12-24 months to Level 3                                  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ LEVEL 3: DEFINED (Standard)                                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│ Characteristics:                                                       │
│ • Processes are documented, standardized, and integrated              │
│ • Proactive process management                                        │
│ • Consistent adherence to standards                                   │
│ • Clear definition of roles and responsibilities                      │
│ • Processes can be communicated and trained                           │
│ • Results are predictable (80-90% success rate)                       │
│                                                                         │
│ Typical Organization Profile:                                         │
│ • Mature company (3-5 years)                                          │
│ • 100-500 employees                                                   │
│ • Multiple well-established teams                                     │
│ • Engineering culture established                                     │
│ • Professional practices adopted                                      │
│                                                                         │
│ Visible Characteristics:                                              │
│ • Testing is standard (60-75% coverage)                               │
│ • Automated CI/CD pipeline                                            │
│ • Code review enforced by tooling                                     │
│ • Comprehensive documentation                                         │
│ • Well-understood architecture                                        │
│ • Comprehensive monitoring & alerting                                 │
│                                                                         │
│ Visible Gaps (Examples):                                              │
│ • Metrics gathered but not analyzed                                   │
│ • No optimization focus                                               │
│ • Process improvements ad-hoc                                         │
│ • No predictive capability                                            │
│ • Reactive rather than proactive                                      │
│                                                                         │
│ Path Forward:                                                         │
│ → Implement quantitative management (measure everything)              │
│ → Set performance targets and monitor                                 │
│ → Identify improvement opportunities                                  │
│ → Timeline: 12-36 months to Level 4                                  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ LEVEL 4: MANAGED (Measurable)                                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│ Characteristics:                                                       │
│ • Processes are measured and controlled                               │
│ • Quantitative management practices applied                           │
│ • Performance metrics tracked and analyzed                            │
│ • Quality and performance are predictable                             │
│ • Proactive adjustment based on data                                  │
│ • Results are highly predictable (90-95% success rate)                │
│                                                                         │
│ Typical Organization Profile:                                         │
│ • Large company (5+ years)                                            │
│ • 500-5000 employees                                                  │
│ • Data-driven culture                                                 │
│ • Mature engineering practices                                        │
│ • Continuous improvement mindset                                      │
│                                                                         │
│ Visible Characteristics:                                              │
│ • Testing is data-driven (75-85% coverage with metrics)               │
│ • Dashboards track all key metrics                                    │
│ • Performance SLOs defined and monitored                              │
│ • Deployment metrics tracked (lead time, deployment freq)             │
│ • Quality metrics tracked (defect rates, MTTR)                        │
│ • Data-driven decision making                                         │
│                                                                         │
│ Visible Gaps (Examples):                                              │
│ • Limited ability to predict failures                                 │
│ • Optimization not automated                                          │
│ • Improvement initiatives slow to identify                            │
│ • Some manual intervention still needed                               │
│ • Innovation rate slower than desired                                 │
│                                                                         │
│ Path Forward:                                                         │
│ → Implement predictive analytics (ML-based)                           │
│ → Automate optimization                                               │
│ → Focus on continuous innovation                                      │
│ → Timeline: 24-48 months to Level 5                                  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ LEVEL 5: OPTIMIZING (Innovative)                                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│ Characteristics:                                                       │
│ • Continuous process improvement culture                              │
│ • Innovation is systematic and expected                               │
│ • Proactive defect prevention                                         │
│ • Focus on optimization and learning                                  │
│ • Leverages data and AI for decision making                           │
│ • Results are exceptional (99%+ success rate)                         │
│                                                                         │
│ Typical Organization Profile:                                         │
│ • Tech leaders (Google, Netflix, Amazon, etc.)                        │
│ • Mature, large-scale systems                                         │
│ • High-performance culture                                            │
│ • Continuous learning environment                                     │
│ • Innovation-driven                                                   │
│                                                                         │
│ Visible Characteristics:                                              │
│ • Testing is AI-assisted (85%+ coverage, bug prediction)              │
│ • Automated optimization (ML-based performance tuning)                │
│ • Anomaly detection (automated issue prevention)                      │
│ • Continuous deployment (multiple deployments daily)                  │
│ • Predictive failure identification                                   │
│ • Innovation initiatives standard practice                            │
│                                                                         │
│ Gaps (Relative to Excellence):                                        │
│ • Even Level 5 organizations identify gaps:                           │
│   - New technology areas to explore                                   │
│   - Emerging market needs                                             │
│   - Process improvements in cutting-edge areas                        │
│                                                                         │
│ Characteristics:                                                       │
│ • Gaps exist at frontier of capability                                │
│ • Gaps are strategic, not operational                                 │
│ • Gaps are self-identified proactively                                │
│ • Gap closure is innovation opportunity                               │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### CMM Assessment Scoring

```
For each capability area, assess current level:

Level 1: Initial
  ☐ Process is ad-hoc
  ☐ No documented approach
  ☐ Success depends on individuals
  ☐ Results are unpredictable

Level 2: Repeatable
  ☐ Basic process documented
  ☐ Some standards exist
  ☐ Can repeat previous successes
  ☐ Some metrics tracked

Level 3: Defined
  ☐ Process fully documented
  ☐ Standards enforced
  ☐ Training available
  ☐ Process is consistent

Level 4: Managed
  ☐ Metrics regularly measured
  ☐ Performance against targets tracked
  ☐ Process optimized based on data
  ☐ Root causes analyzed

Level 5: Optimizing
  ☐ Continuous improvement culture
  ☐ Innovation systematic
  ☐ Proactive improvement
  ☐ Predictive capabilities
```

---

## Impact/Effort Matrix

### Scoring Guide

```
IMPACT SCORING (1-5 scale):

Score │ Description
──────┼─────────────────────────────────────────────────────────────
  5   │ CRITICAL - Blocks production, prevents launch, regulatory
      │ Examples: Security vulnerability in production, compliance
      │ Business effect: Revenue loss, legal liability
──────┼─────────────────────────────────────────────────────────────
  4   │ HIGH - Major feature missing, significant quality issue
      │ Examples: API not documented, 30% test coverage gap
      │ Business effect: Delayed releases, customer complaints
──────┼─────────────────────────────────────────────────────────────
  3   │ MEDIUM - Important but not blocking, moderate quality impact
      │ Examples: Optimization opportunity, documentation incomplete
      │ Business effect: Some efficiency loss, minor complaints
──────┼─────────────────────────────────────────────────────────────
  2   │ LOW - Minor improvement, small quality issue
      │ Examples: Code style inconsistency, minor performance gap
      │ Business effect: Minimal, mainly affects developer experience
──────┼─────────────────────────────────────────────────────────────
  1   │ TRIVIAL - Nice to have, cosmetic
      │ Examples: UI color adjustment, documentation typo
      │ Business effect: None

EFFORT SCORING (1-5 scale):

Score │ Description
──────┼─────────────────────────────────────────────────────────────
  1   │ TRIVIAL - 1-2 hours, single person
      │ Examples: Config change, simple fix
      │ Complexity: Straightforward
──────┼─────────────────────────────────────────────────────────────
  2   │ SMALL - 1-2 days, one person
      │ Examples: Add feature, write tests
      │ Complexity: Well-defined
──────┼─────────────────────────────────────────────────────────────
  3   │ MEDIUM - 1-2 weeks, one or two people
      │ Examples: Module refactor, architecture change
      │ Complexity: Multiple components
──────┼─────────────────────────────────────────────────────────────
  4   │ LARGE - 1-2 months, multiple people
      │ Examples: New platform, major rewrite
      │ Complexity: Many unknowns
──────┼─────────────────────────────────────────────────────────────
  5   │ MASSIVE - 2+ months, team effort
      │ Examples: Complete system overhaul, major tech switch
      │ Complexity: High risk, many dependencies
```

### Priority Calculation Formula

```
Priority Score = Impact / Effort

Examples:
Gap A: Impact 5, Effort 2 → Score: 5/2 = 2.5 (Excellent - do first!)
Gap B: Impact 5, Effort 5 → Score: 5/5 = 1.0 (Strategic - plan carefully)
Gap C: Impact 2, Effort 1 → Score: 2/1 = 2.0 (Nice to do)
Gap D: Impact 2, Effort 5 → Score: 2/5 = 0.4 (Skip or deprioritize)

Higher score = Higher priority
```

### Visual Matrix

```
        HIGH IMPACT
              │
              │  QUICK WINS      STRATEGIC
         5    │  (Do First!)     (Plan & Execute)
         4    │  Impact/Effort   Impact/Effort
Impact       │  > 2.0           1.0-2.0
         3    │
         2    │  OPTIONAL        AVOID
         1    │  (If Time)       (Skip)
              │
              └────────────────────────────────────
                    1  2  3  4  5
                    LOW     EFFORT    HIGH

Zones:
┌─────────────────────────────────────────────────┐
│ QUICK WINS (High Impact, Low Effort)            │
│ • Do immediately                                │
│ • Build momentum                                │
│ • High ROI                                      │
│ Examples:                                       │
│ - Fix critical bugs                             │
│ - Add missing documentation                     │
│ - Enable monitoring                             │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ STRATEGIC (High Impact, High Effort)            │
│ • Plan carefully                                │
│ • Allocate dedicated resources                  │
│ • Long-term value                               │
│ Examples:                                       │
│ - Architecture refactoring                      │
│ - Microservice migration                        │
│ - Building new platform                         │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ OPTIONAL (Low Impact, Low Effort)               │
│ • Do if time permits                            │
│ • Filler work                                   │
│ • No business pressure                          │
│ Examples:                                       │
│ - Code style improvements                       │
│ - Minor optimizations                           │
│ - Documentation polish                          │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ AVOID (Low Impact, High Effort)                 │
│ • Skip or deprioritize                          │
│ • Not worth the cost                            │
│ • Find alternatives                             │
│ Examples:                                       │
│ - Perfectionist refactoring                     │
│ - Experimental technologies                     │
│ - Vanity projects                               │
└─────────────────────────────────────────────────┘
```

---

## Gap Scoring

### Comprehensive Gap Assessment

```
Gap ID: [Unique identifier]
Title: [Brief gap name]
Category: [Type: Requirement, Test, Doc, Security, etc.]
Date Identified: [YYYY-MM-DD]

QUANTIFICATION:
├─ Current State: [Measurement]
├─ Target State: [Measurement]
├─ Gap Amount: [Difference] (percentage or absolute)
└─ Trend: [Improving/Stable/Worsening]

IMPACT ANALYSIS:
├─ Business Impact: [What's at risk/broken]
├─ Technical Impact: [System effects]
├─ User Impact: [What users can't do]
├─ Risk Level: [Critical/High/Medium/Low]
└─ Affected Stakeholders: [Who cares about this]

EFFORT ESTIMATION:
├─ Effort Level: [Trivial/Small/Medium/Large/Massive]
├─ Timeline: [Rough estimate]
├─ Resource Need: [People, skills, budget]
├─ Dependencies: [What must happen first]
└─ Known Risks: [What could go wrong]

PRIORITY:
├─ Impact Score: [1-5]
├─ Effort Score: [1-5]
├─ Priority Score: [Impact/Effort]
├─ Rank: [1st, 2nd, etc.]
└─ Recommended Action: [Do now/Plan/Defer/Skip]

OWNER:
├─ Gap Owner: [Who tracks closure]
├─ Technical Lead: [Who implements]
└─ Stakeholder: [Who cares about result]

TRACKING:
├─ Target Closure Date: [YYYY-MM-DD]
├─ Current Status: [Open/In Progress/Closed]
├─ % Complete: [0-100%]
└─ Last Updated: [YYYY-MM-DD]
```

---

## Assessment Checklists

### Pre-Gap Analysis Checklist

```
SCOPE & OBJECTIVES
☐ Define analysis scope (what's included, what's excluded)
☐ Identify stakeholders (who needs to be involved)
☐ Set success criteria (how will we know it's successful)
☐ Establish timeline (how long will this take)
☐ Allocate budget/resources (what can we spend)
☐ Define constraints (what limits our options)

TARGET STATE DEFINITION
☐ Define "good enough" (realistic targets, not perfection)
☐ Benchmark against industry standards
☐ Align with business strategy
☐ Get stakeholder buy-in
☐ Document target state clearly
☐ Version control target definitions

BASELINE & MEASUREMENT
☐ Establish baseline metrics (current state)
☐ Define measurement methodology
☐ Ensure metrics are objective (not subjective)
☐ Create measurement tools/dashboards
☐ Schedule baseline measurement
☐ Document data collection process

TEAM & RESPONSIBILITIES
☐ Assign analysis lead
☐ Identify team members
☐ Define roles and responsibilities
☐ Schedule analysis activities
☐ Communicate plan to stakeholders
☐ Set communication cadence
```

### Gap Analysis Execution Checklist

```
DATA GATHERING
☐ Collect current state data
☐ Document findings systematically
☐ Validate data quality/accuracy
☐ Identify data gaps (what data is missing)
☐ Get stakeholder confirmation of findings
☐ Create baseline report

GAP IDENTIFICATION
☐ Compare current vs target for each area
☐ Quantify gaps (numbers, percentages, impact)
☐ Categorize gaps (type, severity, priority)
☐ Identify root causes (use 5 Whys)
☐ Look for patterns (similar gaps in multiple areas)
☐ Document all gaps

PRIORITIZATION
☐ Score each gap (impact and effort)
☐ Create priority ranking
☐ Identify critical path (what must happen first)
☐ Identify quick wins (high impact, low effort)
☐ Consider dependencies
☐ Align prioritization with business strategy

STAKEHOLDER VALIDATION
☐ Share findings with stakeholders
☐ Gather feedback and perspectives
☐ Resolve disagreements on prioritization
☐ Confirm business impact assessment
☐ Get commitment to address critical gaps
☐ Refine prioritization if needed
```

### Action Planning Checklist

```
FOR EACH GAP:
☐ Define specific actions to close gap
☐ Estimate effort (days/weeks/months)
☐ Identify resource needs (people, skills, tools)
☐ Identify dependencies (what must happen first)
☐ Assign owner (who drives closure)
☐ Set target closure date
☐ Define success metrics
☐ Identify risks and mitigation

OVERALL PLAN:
☐ Sequence actions (what order makes sense)
☐ Identify critical path (longest sequence)
☐ Identify quick wins (do first for momentum)
☐ Balance workload (not overwhelming team)
☐ Allocate budget (cost by phase)
☐ Schedule reviews (weekly/monthly/quarterly)
☐ Create communication plan
☐ Document plan clearly

COMMUNICATION:
☐ Share plan with stakeholders
☐ Get approval to proceed
☐ Communicate to team members
☐ Set expectations for timeline
☐ Explain rationale for prioritization
☐ Answer questions
☐ Identify concerns/risks
```

### Execution Monitoring Checklist

```
WEEKLY:
☐ Check gap owner status (on track?)
☐ Identify blockers (what's preventing progress)
☐ Track % complete
☐ Resolve issues quickly
☐ Adjust timeline if needed
☐ Short communication to team

MONTHLY:
☐ Comprehensive status update
☐ Review metrics (are we making progress?)
☐ Closed gaps: Celebrate wins
☐ Stuck gaps: Problem-solve
☐ Adjust priorities if circumstances changed
☐ Stakeholder update
☐ Adjust plan if needed

QUARTERLY:
☐ Comprehensive gap review
☐ Are targets still relevant?
☐ Should we adjust targets?
☐ Any new gaps emerged?
☐ Re-prioritize if needed
☐ Update risk assessment
☐ Executive summary
☐ Plan next quarter

UPON CLOSURE:
☐ Verify gap is actually closed (objective evidence)
☐ Document closure evidence
☐ Update tracking system
☐ Celebrate team achievement
☐ Capture lessons learned
☐ Update documentation if needed
☐ Re-assess area for new gaps
```

---

## Report Templates

### Gap Analysis Report Template

```markdown
# Gap Analysis Report
[Project/Organization Name]

**Analysis Date**: [Date Range]
**Prepared By**: [Names]
**Reviewed By**: [Names]
**Status**: [Draft/Final]

## Executive Summary

[1-2 paragraph overview of gaps found, impact, and recommended actions]

**Key Metrics**:
- Total gaps identified: X
- Critical gaps: Y
- High priority gaps: Z
- Estimated remediation effort: X person-months
- Estimated cost: $X

## Analysis Scope

**What was analyzed**: [Systems, areas, components]
**Target state basis**: [Standards, requirements, benchmarks used]
**Methodology**: [How analysis was performed]
**Limitations**: [What wasn't covered, why]

## Findings Summary

### Gap Summary by Category

| Category | Total Gaps | Critical | High | Medium | Low |
|----------|-----------|----------|------|--------|-----|
| Requirements | X | X | X | X | X |
| Testing | X | X | X | X | X |
| Documentation | X | X | X | X | X |
| Security | X | X | X | X | X |
| Infrastructure | X | X | X | X | X |
| **TOTAL** | **X** | **X** | **X** | **X** | **X** |

### Gap Summary by Impact

| Impact Level | Count | % of Total | Examples |
|--------------|-------|-----------|----------|
| CRITICAL | X | X% | [Gap list] |
| HIGH | X | X% | [Gap list] |
| MEDIUM | X | X% | [Gap list] |
| LOW | X | X% | [Gap list] |

## Critical Gaps (Must Address)

### Gap 1: [Gap Name]

**Current State**: [What exists now]
**Target State**: [What should exist]
**Gap**: [Difference]
**Impact**: [Why it matters]
- Business impact: [Revenue, compliance, risk]
- Technical impact: [System effects]
- User impact: [User experience effects]

**Root Cause**: [Why gap exists]
**Effort to Close**: [Time/resources]
**Recommended Action**: [What to do]
**Target Closure**: [Date]

[Repeat for each critical gap]

## High Priority Gaps

[Summary table of high-priority gaps]

| Gap ID | Title | Current | Target | Impact | Effort | Priority |
|--------|-------|---------|--------|--------|--------|----------|
| [ID] | [Title] | [Status] | [Target] | [1-5] | [1-5] | [Score] |

## Recommended Action Plan

### Phase 1: Immediate Actions (Next 30 Days)

| Gap | Action | Owner | Timeline | Success Criteria |
|-----|--------|-------|----------|------------------|
| [ID] | [Action] | [Owner] | [Date] | [How to verify] |

### Phase 2: Short-term (30-90 Days)

[Similar table for next priority items]

### Phase 3: Long-term (90+ Days)

[Similar table for remaining items]

## Risk Assessment

**Risks in closure efforts**:
1. [Risk description] - Probability: High/Med/Low - Mitigation: [How to address]
2. [Risk description] - Probability: High/Med/Low - Mitigation: [How to address]

**Timeline risks**: [Assumptions that could change]

## Resource Requirements

**Effort Estimate**:
- Phase 1: X person-months
- Phase 2: X person-months
- Phase 3: X person-months
- **Total**: X person-months

**Budget Estimate**:
- Personnel: $X
- Tools/Infrastructure: $X
- Consulting/External: $X
- **Total**: $X

**Skills Required**:
- [Skill 1]
- [Skill 2]
- [Skill 3]

## Success Metrics

**How we'll know we've succeeded**:

| Gap Area | Metric | Current | Target | Timeline |
|----------|--------|---------|--------|----------|
| [Area] | [Metric] | [Value] | [Target] | [Date] |

## Assumptions & Dependencies

**Assumptions**:
- [Assumption 1]
- [Assumption 2]

**Dependencies**:
- [Dependency 1] (blocks: [what])
- [Dependency 2] (blocks: [what])

## Lessons Learned

[Insights from analysis]
- [Learning 1]
- [Learning 2]

## Appendices

- **Appendix A**: Detailed gap inventory
- **Appendix B**: Assessment methodology
- **Appendix C**: Data sources and validation
- **Appendix D**: Stakeholder input summary
```

### Gap Tracking Template

```
# Gap Tracking Dashboard

## Active Gaps

| ID | Title | Status | Owner | Target Close | % Done | Next Step |
|----|-------|--------|-------|---------------|--------|-----------|
| 1 | [Gap] | In Progress | [Name] | [Date] | 40% | [Action] |
| 2 | [Gap] | Planned | [Name] | [Date] | 0% | [Action] |
| 3 | [Gap] | Blocked | [Name] | [Date] | 60% | [Action] |

## Closed Gaps

| ID | Title | Closed | Owner | Closure Date | Evidence |
|----|-------|--------|-------|--------------|----------|
| 1 | [Gap] | ✓ | [Name] | [Date] | [Proof] |

## Status Summary

- Total Gaps: X
- Open: Y
- In Progress: Z
- Closed: W

## Trend

- Last month: X open
- This month: Y open
- Trend: [Improving/Stable/Worsening]

## Top Priorities This Week

1. [Gap ID]: [Action needed]
2. [Gap ID]: [Action needed]
3. [Gap ID]: [Action needed]
```
