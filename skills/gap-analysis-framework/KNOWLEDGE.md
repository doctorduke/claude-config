# Gap Analysis Knowledge Base

Comprehensive frameworks, methodologies, and background knowledge for gap analysis.

## Table of Contents
1. [Gap Analysis Fundamentals](#fundamentals)
2. [Analysis Frameworks](#frameworks)
3. [Maturity Models](#maturity-models)
4. [SWOT Analysis Deep Dive](#swot-analysis)
5. [Research & Learning Resources](#resources)

---

## Fundamentals

### Definition

**Gap Analysis** answers: "What's the difference between where we are and where we should be?"

It systematically identifies the disparity between:
- **Current State** (reality, what exists)
- **Target State** (requirements, standards, best practices)
- **Gap** (the delta, what's missing or deficient)

### Why Gap Analysis Matters

1. **Risk Identification** - Uncover vulnerabilities and deficiencies before they impact production
2. **Resource Planning** - Understand what effort is needed to reach targets
3. **Prioritization** - Focus limited resources on highest-impact gaps
4. **Accountability** - Clear tracking of progress toward objectives
5. **Compliance** - Verify meeting regulatory and standard requirements
6. **Continuous Improvement** - Systematic approach to organizational growth

### Core Process

```
1. Define Target State
   ↓
2. Assess Current State
   ↓
3. Identify & Quantify Gaps
   ↓
4. Prioritize by Impact/Effort
   ↓
5. Create Action Plans
   ↓
6. Execute & Monitor
   ↓
7. Verify Closure & Reassess
```

### Key Principles

**Precision**: Define target state clearly before analyzing (vague targets = vague gaps)

**Quantification**: Use metrics and numbers, not just qualitative assessment

**Stakeholder Involvement**: Gap definitions should come from users, customers, operators, not just developers

**Root Cause Focus**: Understand *why* gaps exist, not just what they are

**Action Orientation**: Analysis is only valuable if it leads to action

**Continuous Monitoring**: One-time analysis becomes outdated; gaps evolve over time

---

## Frameworks

### 1. Impact/Effort Matrix

Prioritize gaps by impact and effort to close:

```
         │ Easy to Fix │ Hard to Fix │
─────────┼─────────────┼─────────────┤
High     │   QUICK     │  STRATEGIC  │  Quick Wins: Do first (high value, low effort)
Impact   │    WINS     │   GAPS      │  Strategic: Plan carefully (high value, high effort)
─────────┼─────────────┼─────────────┤
Low      │  OPTIONAL   │   IGNORE    │  Optional: Do if time permits
Impact   │IMPROVEMENTS │   FOR NOW   │  Ignore: Deprioritize for now
─────────┴─────────────┴─────────────┘
```

**Scoring**:
- Impact: 1 (low) to 5 (critical)
- Effort: 1 (trivial) to 5 (massive)
- Priority Score: Impact / Effort (higher = better)

### 2. Coverage Analysis

Quantify what's covered and what's missing:

```
Coverage % = (Completed / Total) × 100

Examples:
- 45/60 functions have tests = 75% test coverage
- 12/15 requirements implemented = 80% feature parity
- 8/10 documentation sections = 80% documentation coverage
- 140/200 lines executed = 70% code coverage
```

### 3. Root Cause Analysis (5 Whys)

Dig deeper to find underlying causes rather than symptoms:

**Gap**: "Search function returns no results"

```
1. Why? → Search index is empty
2. Why? → Indexing process failed last night
3. Why? → Database connection timeout during indexing
4. Why? → Connection pool exhausted by batch job
5. Why? → No resource limits on batch job

ROOT CAUSE: Batch job lacks resource constraints
SOLUTION: Add CPU/memory limits to batch job, or schedule after off-hours
```

### 4. Fishbone (Ishikawa) Diagram

Organize potential causes by category:

```
                        ╱─ Old library version
              Methods ─┤─ Inefficient algorithm
                        ╲─ No caching

                        ╱─ Undersized database
        Infrastructure─┤─ Network latency
                        ╲─ No load balancing

                                   ╱─ No tests
                                  ╱─ Rushed development
    PROBLEM: Search ────────────┤─ Poor requirements definition
    Returns No Results          ╲─ Incomplete design
                                  ╲─ Outdated documentation
                        ╱─ Inadequate testing
              Processes─┤─ No monitoring
                        ╲─ Unclear handoffs

                        ╱─ Incomplete training
                People─┤─ High turnover
                        ╲─ Unclear responsibilities
```

### 5. Capability Analysis Matrix

Map current capabilities across dimensions:

```
Dimension        │ Level 1    │ Level 2     │ Level 3      │ Level 4      │ Level 5
─────────────────┼────────────┼─────────────┼──────────────┼──────────────┼─────────────
Testing          │ Ad-hoc     │ Some tests  │ Good coverage│ Measured 90% │ Continuous
Coverage         │ (0-20%)    │ (20-50%)    │ (50-80%)     │ (80-95%)     │ improvement
─────────────────┼────────────┼─────────────┼──────────────┼──────────────┼─────────────
Documentation    │ None       │ README only │ API docs     │ Architecture │ Auto-gen
                 │ (0%)       │ (20%)       │ (60%)        │ (80%)        │ (100%)
─────────────────┼────────────┼─────────────┼──────────────┼──────────────┼─────────────
Security         │ None       │ Audits      │ Scanning     │ SAST/DAST    │ Continuous
Controls         │ (0%)       │ (30%)       │ (50%)        │ (80%)        │ (95%+)
```

---

## Maturity Models

### 1. Capability Maturity Model Integration (CMMI)

Framework for measuring organizational capability evolution:

| Level | Name | Characteristics | Timeline |
|-------|------|-----------------|----------|
| **1** | **Initial** | Ad-hoc, chaotic, unpredictable. Success depends on individuals. | Starting point |
| **2** | **Repeatable** | Basic processes established. Can repeat previous successes. Some discipline applied. | 6-12 months |
| **3** | **Defined** | Processes documented, standardized, integrated. Proactive management. | 12-24 months |
| **4** | **Managed** | Processes measured and controlled. Quantitative management. | 24-36 months |
| **5** | **Optimizing** | Continuous process improvement. Data-driven decisions. Innovation. | 36+ months |

**Typical Maturity Gaps**:
- Starting teams: Level 1 → 2 (establish basic processes)
- Growing teams: Level 2 → 3 (standardize and document)
- Mature teams: Level 3 → 4 (measure and control)
- Excellence: Level 4 → 5 (continuous improvement)

### 2. Test Maturity Model

Evolution of testing practices:

```
Level 0: No testing (gap: complete lack of test infrastructure)
Level 1: Manual testing (gap: no automation, high cost)
Level 2: Automated unit tests (gap: no integration/E2E coverage)
Level 3: Automated coverage gates (gap: no performance testing)
Level 4: Continuous testing (gap: no security/chaos testing)
Level 5: AI-driven testing (gap: limited to major orgs)
```

### 3. Documentation Maturity

```
Level 1: No documentation (gap: impossible to onboard)
Level 2: Scattered docs (gap: inconsistent, hard to find)
Level 3: Centralized documentation (gap: outdated, incomplete)
Level 4: Living documentation (gap: specialized areas missing)
Level 5: Docs as code (gap: none, auto-generated and current)
```

### 4. Security Maturity Model (SAMM)

From OWASP - five business functions with maturity levels:

1. **Governance** - Strategy, compliance, risk management
2. **Design** - Security architecture, threat modeling
3. **Implementation** - Secure coding, dependency management
4. **Verification** - Testing, scanning, security reviews
5. **Operations** - Incident response, monitoring

Each function has 3 maturity levels (Initial, Growth, Maturity).

---

## SWOT Analysis

Strategic gap identification using strengths, weaknesses, opportunities, threats.

### Framework Overview

```
┌──────────────────────────────┬──────────────────────────────┐
│ STRENGTHS                    │ WEAKNESSES                   │
│ Internal, positive           │ Internal, negative (GAPS)    │
│                              │                              │
│ • What we do well            │ • What's missing             │
│ • Competitive advantages     │ • Resource constraints       │
│ • Unique capabilities        │ • Skill gaps                 │
│ • Strong team/culture        │ • Technical debt             │
├──────────────────────────────┼──────────────────────────────┤
│ OPPORTUNITIES                │ THREATS                      │
│ External, positive           │ External, negative (RISKS)   │
│                              │                              │
│ • Market gaps we can fill    │ • Competitor actions         │
│ • Emerging technologies      │ • Regulatory changes         │
│ • Growing demand             │ • Technology obsolescence    │
│ • Partnership potential      │ • Economic downturn          │
└──────────────────────────────┴──────────────────────────────┘
```

### Strategic Combinations

**SO Strategy (Strengths + Opportunities)**
- Use strengths to capitalize on opportunities
- Example: Strong engineering team + AI market growth → Invest in AI features

**WO Strategy (Weaknesses + Opportunities)**
- Overcome weaknesses through opportunity pursuit
- Example: Low brand awareness + Market growth → Partner with established players

**ST Strategy (Strengths + Threats)**
- Use strengths to mitigate threats
- Example: Strong moat + New competitor → Accelerate innovation

**WT Strategy (Weaknesses + Threats)**
- Minimize weaknesses and avoid threats (defensive)
- Example: Low test coverage + Security threat → Invest in security testing

### SWOT for Gap Analysis

**Weaknesses = Capability Gaps** (internal deficiencies)

Weakness example: "Test coverage at 45%"
- Gap: Missing tests for 55% of code
- Impact: High - undetected bugs reach production
- Action: Implement coverage goals, add testing infrastructure

**Opportunities with Unmet Prerequisites = Capability Gaps**

Opportunity: "AI-powered features could grow revenue 50%"
- Gap: No ML expertise on team
- Gap: No infrastructure for model serving
- Gap: No data pipeline for training
- Action: Hire ML engineers, build infrastructure, create data pipeline

---

## Resources

### Gap Analysis Methodologies

1. **Gap Analysis Technique** (Project Management Institute)
   - Structured approach to identifying deficiencies
   - Tools: Requirements mapping, capability inventories, benchmarking

2. **Process Mining**
   - Extract actual processes from event logs
   - Compare to ideal processes to identify gaps
   - Tools: ProM, Disco, Celonis

3. **Balanced Scorecard**
   - Measure performance across four perspectives
   - Identify gaps between actual and target metrics
   - Framework: Financial, Customer, Internal Process, Learning

### Tool Categories

**Coverage Analysis**:
- Code: Coverage.py (Python), Jest (JS), JaCoCo (Java)
- API: OpenAPI validators, API coverage analyzers
- Infrastructure: CloudMapper, Prowler

**Maturity Assessment**:
- SonarQube: Code quality and security metrics
- DORA metrics: DevOps performance
- Atlassian metrics: Deployment frequency, lead time

**Benchmarking**:
- Web.dev Lighthouse: Web performance
- CloudCompare: Cloud service benchmarks
- TechEmpower: Framework benchmarks

**Security Gaps**:
- OWASP: Top 10, SAMM, ASVS
- CWE/CVSS: Vulnerability classification
- NIST Cybersecurity Framework: Controls assessment

### Standards & Compliance

**Accessibility**:
- WCAG 2.1 - Web Content Accessibility Guidelines
- ADA - Americans with Disabilities Act
- EN 301 549 - Accessibility of ICT products

**Security**:
- SOC 2 - Security, Availability, Integrity
- ISO 27001 - Information Security Management
- PCI DSS - Payment Card Industry Data Security
- HIPAA - Healthcare data privacy
- GDPR - EU data protection

**Quality**:
- ISO 9001 - Quality Management
- Six Sigma - Process improvement
- Lean Manufacturing - Waste elimination

### Learning Paths

**For Requirements Gaps**:
1. Learn requirements elicitation techniques
2. Study acceptance criteria definition
3. Practice traceability mapping
4. Study requirements change management

**For Test Coverage Gaps**:
1. Understand test types (unit, integration, E2E)
2. Learn coverage metrics and thresholds
3. Study mutation testing
4. Practice test-driven development

**For Documentation Gaps**:
1. Study technical writing best practices
2. Learn docs-as-code tools (Sphinx, MkDocs)
3. Practice API documentation (OpenAPI)
4. Study architecture decision records (ADRs)

**For Organizational Gaps**:
1. Study change management
2. Learn organizational design
3. Practice skill matrix development
4. Study team capabilities assessment

### Key Concepts

**Baseline vs Target**
- Baseline: Current measured state
- Target: Desired future state
- Gap: Baseline → Target (what's needed)

**Quantitative vs Qualitative**
- Quantitative: Measurable (80% coverage vs 90% target)
- Qualitative: Descriptive (team lacks security expertise)
- Best practice: Use both

**Priority vs Effort**
- High priority, low effort: Do immediately (quick wins)
- High priority, high effort: Plan and execute (strategic)
- Low priority, low effort: Do if time permits (filler)
- Low priority, high effort: Deprioritize (avoid)

**Preventive vs Reactive**
- Preventive: Find gaps before they cause problems
- Reactive: Fix gaps after failure/discovery
- Best practice: Proactive gap monitoring

---

## Industry Benchmarks

### Test Coverage Standards

- **Startup**: 40-50% acceptable (get to market first)
- **Growth**: 60-75% target (quality matters now)
- **Enterprise**: 80-90% minimum (risk management)
- **Critical Systems**: 90%+ mandatory (life safety, finance)

### Documentation Completeness

- **API Public**: 100% endpoints documented
- **Internal APIs**: 90% documented
- **Architecture**: 80% design decisions recorded
- **Runbooks**: 100% critical operations documented

### Security Posture

- **Startup**: Basic authentication, HTTPS
- **Growth**: SAST scanning, dependency scanning
- **Enterprise**: SAST, DAST, security scanning, regular audits
- **Financial/Health**: All above + penetration testing, compliance audits

### Infrastructure

- **Availability SLO**: 99.5% (4h/year downtime)
- **Deployment frequency**: Daily (DevOps best practice)
- **Lead time**: < 1 day (modern development)
- **MTTR**: < 15 minutes (high reliability)

---

## References & Further Reading

- Mind Tools: [Gap Analysis Guide](https://www.mindtools.com/pages/article/newTMC_03.htm)
- CMMI Institute: [Capability Maturity Model Integration](https://cmmiinstitute.com/)
- OWASP: [SAMM - Software Assurance Maturity Model](https://owaspsamm.org/)
- Google: [DORA Metrics Research](https://www.devops-research.com/research.html)
- W3C: [WCAG 2.1 Accessibility Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- Project Management Institute: [GAP Analysis Techniques](https://www.projectmanagement.com/)
