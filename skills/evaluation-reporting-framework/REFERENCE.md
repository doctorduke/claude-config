# Evaluation & Reporting Framework - Reference & Templates

## Table of Contents

1. [Report Format Reference](#report-format-reference)
2. [Template Library](#template-library)
3. [Metrics Catalog](#metrics-catalog)
4. [Report Checklist](#report-checklist)

## Report Format Reference

### Markdown Format

**Best for**: Quick reports, version control, collaboration

**Advantages**:
- Plain text, easy to version control
- Readable source and rendered
- Can be converted to other formats
- GitHub-friendly

**Template**:
```markdown
# Report Title

**Date**: YYYY-MM-DD
**Author**: Name
**Status**: GREEN/AMBER/RED

## Executive Summary

[1-2 sentences with key finding]

## Key Metrics

| Metric | Value | Target | Status |
|--------|-------|--------|--------|

## Findings

- Finding 1
- Finding 2

## Recommendations

1. Action 1
2. Action 2

## Methodology

[Explain how measurements were taken]
```

---

### HTML Format

**Best for**: Web viewing, stakeholder presentations, professional appearance

**Advantages**:
- Professional appearance
- Interactive on web
- Print-to-PDF supported
- Can include charts/visualizations

**CSS Styling**:
```css
/* Status colors */
.status-green { color: #27ae60; font-weight: bold; }
.status-amber { color: #f39c12; font-weight: bold; }
.status-red { color: #e74c3c; font-weight: bold; }

/* Tables */
table { width: 100%; border-collapse: collapse; }
th { background: #3498db; color: white; padding: 12px; }
td { padding: 10px; border-bottom: 1px solid #ecf0f1; }
```

---

### PDF Format

**Best for**: Formal reports, distribution, archival

**Advantages**:
- Fixed formatting regardless of viewer
- Print-ready
- Professional distribution format
- Portable

**Tools**:
- WeasyPrint (HTML/CSS to PDF)
- ReportLab (programmatic PDF generation)
- Pandoc (Markdown to PDF)

---

### JSON Format

**Best for**: Machine consumption, API integration, data analysis

**Schema**:
```json
{
  "title": "Report Title",
  "author": "Name",
  "date": "2024-12-15",
  "metadata": {
    "status": "GREEN",
    "period": "Q4 2024"
  },
  "sections": [
    {
      "title": "Executive Summary",
      "content": "...",
      "level": 2,
      "tables": [],
      "charts": []
    }
  ]
}
```

---

## Template Library

### 1. Executive Summary (1-page)

```markdown
# [Project/Product] - Executive Summary

**Date**: [Date]
**Period**: [Period]
**Overall Status**: GREEN ✓

## Key Finding

[Headline: One sentence capturing the most important finding]

## Metrics at a Glance

| KPI | Current | Target | Status |
|-----|---------|--------|--------|
| [KPI 1] | [Val] | [Target] | [Status] |
| [KPI 2] | [Val] | [Target] | [Status] |
| [KPI 3] | [Val] | [Target] | [Status] |

## What Changed

- **Improvement**: [What got better] (+X%)
- **Concern**: [What needs attention] (-Y%)
- **New Issue**: [Something to watch]

## What's Next

**Action 1**: [Description] - Owner: [Name] - Timeline: [Date]
**Action 2**: [Description] - Owner: [Name] - Timeline: [Date]

**Questions?** Contact [Name] at [Email]
```

---

### 2. Technical Deep-Dive (5-page)

```markdown
# Technical Evaluation Report - [System Name]

**Date**: [Date]
**Evaluators**: [Names]
**Data Range**: [Dates]

## 1. Overview

[2-3 paragraphs explaining what was evaluated and why]

## 2. Methodology

**Metrics Evaluated**:
- [Metric 1]: [How measured]
- [Metric 2]: [How measured]

**Data Collection**:
- [Data source 1]: [Frequency]
- [Data source 2]: [Frequency]

**Analysis Period**: [Dates]

## 3. Findings

### Finding 1: [Title]

[Description]

[Detailed table/data]

**Impact**: [Business/Technical impact]

## 4. Analysis & Interpretation

[Detailed analysis of findings]

## 5. Recommendations

**Priority 1 - Critical**:
- [ ] Action 1
- [ ] Action 2

**Priority 2 - Important**:
- [ ] Action 3
- [ ] Action 4

## 6. Appendices

- A: Raw Data
- B: Detailed Methodology
- C: Tool Documentation
- D: Historical Trends
```

---

### 3. Comparative Analysis Template

```markdown
# Comparative Evaluation Report

**Date**: [Date]
**Compared Items**: [Item A] vs [Item B]

## Overview

[Summary of comparison]

## Criteria & Scoring

| Criteria | Weight | Item A | Item B | Winner |
|----------|--------|--------|--------|--------|
| [Criterion 1] | 30% | [Score] | [Score] | [A/B] |
| [Criterion 2] | 25% | [Score] | [Score] | [A/B] |
| [Criterion 3] | 25% | [Score] | [Score] | [A/B] |
| [Criterion 4] | 20% | [Score] | [Score] | [A/B] |
| **TOTAL** | 100% | [Total] | [Total] | **[Winner]** |

## Detailed Comparison

### Criterion 1: [Title]

**Item A**: [Description and analysis]
- Strength: [Strength]
- Weakness: [Weakness]
- Score: [X/100]

**Item B**: [Description and analysis]
- Strength: [Strength]
- Weakness: [Weakness]
- Score: [X/100]

## Recommendation

[Clear recommendation with rationale]

## Trade-offs

[Discussion of what's being given up with chosen option]
```

---

### 4. Compliance Report Template

```markdown
# Compliance Evaluation Report

**Date**: [Date]
**Standard/Framework**: [e.g., SOC2, HIPAA, GDPR]
**Scope**: [What is being evaluated]

## Executive Summary

**Status**: COMPLIANT / NON-COMPLIANT / PARTIAL

**Gaps Found**: [Number]
- Critical: [Count]
- High: [Count]
- Medium: [Count]

## Requirements Checklist

| Requirement | Status | Evidence | Comments |
|-------------|--------|----------|----------|
| [Req 1] | ✓ / ✗ | [Artifact] | [Note] |
| [Req 2] | ✓ / ✗ | [Artifact] | [Note] |

## Non-Compliance Items

### Gap 1: [Title]

**Requirement**: [What was required]
**Current State**: [What we have]
**Gap**: [What's missing]
**Remediation Plan**:
- Step 1: [Description] - Timeline: [Date]
- Step 2: [Description] - Timeline: [Date]
**Owner**: [Name]

## Certification Statement

[Legal/formal statement about compliance status]
```

---

## Metrics Catalog

### Performance Metrics

| Metric | Unit | Excellent | Good | Acceptable | Poor |
|--------|------|-----------|------|------------|------|
| API Latency (p95) | ms | <100 | <200 | <500 | >500 |
| Error Rate | % | <0.1 | <0.5 | <1.0 | >1.0 |
| Uptime | % | >99.9 | >99.5 | >99.0 | <99.0 |
| Throughput | req/s | Baseline+20% | Baseline+10% | Baseline | <Baseline |

### Code Quality Metrics

| Metric | Unit | Excellent | Good | Acceptable | Poor |
|--------|------|-----------|------|------------|------|
| Test Coverage | % | >90 | >80 | >70 | <70 |
| Duplication | % | <5 | <10 | <15 | >15 |
| Complexity | avg CC | <5 | <7 | <10 | >10 |
| Maintainability | index | >85 | >75 | >65 | <65 |

### Team Metrics

| Metric | Unit | Excellent | Good | Acceptable | Poor |
|--------|------|-----------|------|------------|------|
| Deployment Freq | / week | >1 | 1x | <1x | Monthly |
| Lead Time | days | <1 | <7 | <30 | >30 |
| MTTR | minutes | <15 | <30 | <60 | >60 |
| Change Failure | % | <15 | <30 | <50 | >50 |

### Security Metrics

| Metric | Unit | Excellent | Good | Acceptable | Critical |
|--------|------|-----------|------|------------|----------|
| Vuln Scan | issues | 0 HIGH | <5 | <10 | >10 |
| Secret Exposure | incidents | 0 | <1/yr | <2/yr | >2/yr |
| Cert Expiry | days | >90 | >30 | >7 | <7 |
| Patch Currency | % | >95 | >80 | >60 | <60 |

---

## Report Checklist

### Pre-Report Checklist

- [ ] Define evaluation scope and objectives
- [ ] Identify stakeholders and their needs
- [ ] Select appropriate metrics
- [ ] Agree on data sources
- [ ] Plan data collection timeline
- [ ] Ensure data access and permissions

### During Analysis

- [ ] Collect complete data set
- [ ] Verify data quality and completeness
- [ ] Perform sanity checks on metrics
- [ ] Calculate scores and grades
- [ ] Identify trends and anomalies
- [ ] Compare to baselines and benchmarks

### Report Writing

- [ ] Start with executive summary
- [ ] Use clear, simple language
- [ ] Include supporting data and tables
- [ ] Add visualizations where helpful
- [ ] Explain methodology clearly
- [ ] Provide actionable recommendations
- [ ] Ensure report is coherent and flows well

### Pre-Distribution

- [ ] Proofread for grammar and spelling
- [ ] Verify all data and numbers
- [ ] Check formatting consistency
- [ ] Validate cross-references
- [ ] Test hyperlinks
- [ ] Get stakeholder review
- [ ] Obtain sign-off from owner

### Post-Report

- [ ] Distribute to relevant stakeholders
- [ ] Schedule follow-up review meeting
- [ ] Track action items to completion
- [ ] Archive report in standard location
- [ ] Update metrics dashboard
- [ ] Plan next evaluation period

---

**Total lines**: 389 | **Last Updated**: 2025-10
