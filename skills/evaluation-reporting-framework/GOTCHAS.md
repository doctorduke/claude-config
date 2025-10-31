# Evaluation & Reporting Framework - Common Gotchas & Pitfalls

## Table of Contents

1. [Metric Selection Gotchas](#metric-selection-gotchas)
2. [Data Collection Pitfalls](#data-collection-pitfalls)
3. [Analysis Mistakes](#analysis-mistakes)
4. [Reporting Errors](#reporting-errors)
5. [Audience Communication Issues](#audience-communication-issues)

## Metric Selection Gotchas

### Vanity Metrics

**Problem**: Measuring things that look good but don't drive decisions

Example: "We have 10,000 page views!" But conversion rate is 0.1%.

**Solution**:
- Focus on actionable metrics tied to business outcomes
- Ask "Does this metric help us make a decision?" for each metric
- Pair output metrics with outcome metrics

---

### Goodhart's Law

**Problem**: "When a measure becomes a target, it ceases to be a good measure"

Example: Measuring code coverage → developers write tests that don't test behavior

**Solution**:
- Use multiple metrics to avoid gaming single metric
- Measure outcomes, not just outputs
- Monitor for unintended consequences
- Regularly review metric relevance

---

### Missing Context

**Problem**: Numbers without context are meaningless

Example: "API latency is 500ms" – is that good or bad?

**Solution**:
- Always include baselines and benchmarks
- Show trends over time
- Provide comparison to industry standards
- Explain what the number means in business terms

---

### Metric Drift

**Problem**: Metrics that were useful become less relevant over time

Example: "Lines of code written" was never a good metric but becomes obvious over time

**Solution**:
- Review metric relevance quarterly
- Retire metrics that no longer drive decisions
- Introduce new metrics as context changes
- Document metric lifecycle and rationale

---

### Cherry-Picked Timeframes

**Problem**: Selecting time periods that show favorable results

Example: Reporting "90% uptime" in a month where we had good uptime, ignoring 3 months of 85% average

**Solution**:
- Use consistent, pre-defined timeframes
- Show rolling averages to smooth variations
- Compare across multiple periods
- Document timeframe selection methodology

## Data Collection Pitfalls

### Survivorship Bias

**Problem**: Only analyzing successful cases, ignoring failures

Example: Evaluating code quality only on code that was successfully deployed, ignoring code that failed review

**Solution**:
- Include all data points, especially failures
- Analyze root causes of failures
- Track edge cases and error scenarios
- Sample randomly, not by success

---

### Correlation vs Causation

**Problem**: Assuming relationships imply cause and effect

Example: "Ice cream sales correlate with drowning deaths, therefore ice cream causes drowning"
(Both correlate with summer)

**Solution**:
- Use controlled experiments when possible
- Consider confounding variables
- Use multiple lines of evidence
- State causality claims carefully

---

### Sample Bias

**Problem**: Non-representative sample distorting reality

Example: Surveying only "happy" users misses pain points from unhappy ones

**Solution**:
- Use random sampling when possible
- Ensure adequate sample size
- Check for sample representativeness
- Weight results appropriately

---

### Data Freshness

**Problem**: Using stale data that no longer reflects reality

Example: Using 3-month-old performance benchmarks in fast-moving systems

**Solution**:
- Define acceptable data staleness for each metric
- Automate data collection where possible
- Use rolling windows for trending data
- Document data collection timestamps

---

### Measurement Reliability

**Problem**: Inconsistent or unreliable measurement methods

Example: Manual testing with different testers getting different results

**Solution**:
- Automate measurements where possible
- Document measurement methodology
- Perform spot-checks and validation
- Calculate measurement reliability/variance

## Analysis Mistakes

### False Precision

**Problem**: Reporting overly precise numbers that imply more certainty than warranted

Example: "Code quality score: 87.349%" (implies measurement to 0.001% precision)

**Solution**:
- Round to appropriate precision (whole percentages are often enough)
- Use confidence intervals to show uncertainty
- State assumptions and limitations
- Avoid false confidence in measurements

---

### Analysis Paralysis

**Problem**: Over-analyzing, never making decisions

Example: Spending 2 months optimizing a metric that impacts 0.1% of business

**Solution**:
- Set analysis timeboxes upfront
- Use 80/20 rule (80% of insight with 20% of effort)
- Make decisions with incomplete data when necessary
- Document assumptions and unknowns

---

### Simpson's Paradox

**Problem**: Trend visible in subgroups reverses in aggregated data

Example: Drug A has higher success rate in both men and women, but lower overall (due to population differences)

**Solution**:
- Segment data and show disaggregated results
- Investigate reversals (they often indicate important insights)
- Use stratified analysis for important metrics
- Show breakdowns in reports

---

### Regression to the Mean

**Problem**: Extreme values naturally move toward average, mistaken for improvement

Example: Worst-performing team improves after intervention (they were just unlucky)

**Solution**:
- Understand baseline patterns
- Use control groups for interventions
- Track metrics over longer periods
- Account for natural variation

---

### Confirmation Bias

**Problem**: Interpreting data to confirm pre-existing beliefs

Example: "I thought this team was slow" → focus on slow metrics, ignore fast ones

**Solution**:
- Use blind analysis (don't know which group is which)
- Have peer review of analysis
- Deliberately look for contradictory evidence
- Document alternative interpretations

---

### Recency Bias

**Problem**: Over-weighting recent events vs long-term trends

Example: One bad week makes you think the product is broken (ignoring 6 months of stability)

**Solution**:
- Use rolling averages instead of point-in-time numbers
- Compare multiple time periods explicitly
- Identify anomalies separately from trends
- Use trend lines to show long-term patterns

## Reporting Errors

### Missing Executive Summary

**Problem**: Expecting busy executives to read 50-page technical report

**Solution**:
- Always start with 1-page executive summary
- Key findings as 3-5 bullets
- Clear recommendation up front
- Details in appendices for interested readers

---

### Unclear Recommendation

**Problem**: Analysis that doesn't lead to clear action

Example: "Performance varies from 100ms to 500ms" – what should we do?

**Solution**:
- End analysis with clear recommendation
- Prioritize recommendations by impact
- Provide implementation guidance
- Explain trade-offs of different options

---

### Jargon Overload

**Problem**: Using technical terminology that non-technical stakeholders don't understand

Example: "Cyclomatic complexity increased by 15%, indicating higher maintenance burden"

**Solution**:
- Translate metrics into business terms
- Explain technical concepts in simple language
- Use analogies that non-technical people understand
- Define jargon when necessary

---

### Inconsistent Formatting

**Problem**: Different styles, units, colors in different reports

Solution**:
- Use standard report template
- Consistent color schemes (always green for good)
- Consistent units and precision
- Style guide for all reports

## Audience Communication Issues

### Wrong Level of Detail

**Problem**: Too much detail for executives, not enough for implementers

**Solution**:
- Create multiple versions: 1-page executive, 5-page summary, detailed 30-page analysis
- Use progressive disclosure (summary → details → appendices)
- Provide appendices with raw data and methodology
- Link to deeper resources in executive summary

---

### Missing Stakeholder Buy-In

**Problem**: Evaluation reveals unfavorable results that teams resist

**Solution**:
- Involve teams in metric selection upfront
- Explain methodology transparently
- Show how metrics will be used
- Frame improvements positively
- Celebrate progress, not just absolutes

---

### One-Size-Fits-All Reports

**Problem**: Same report for different audiences with different needs

Example: Technical details for finance, business terms for engineers

**Solution**:
- Tailor content to audience
- Different visualizations for different audiences
- Adjust recommendation depth
- Provide context relevant to audience

---

### Missing Comparisons

**Problem**: Metrics in isolation without context

Example: "Code quality score is 78" – is that good?

**Solution**:
- Include competitor benchmarks
- Show industry standards
- Track historical trends
- Compare to goals/targets
- Show variability and range

---

### Action Items Without Owner

**Problem**: Recommendations nobody implements because nobody's responsible

**Solution**:
- Clearly assign ownership for each recommendation
- Include implementation timeline
- Define success criteria
- Schedule follow-up review
- Track progress publicly

---

**Total lines**: 356 | **Last Updated**: 2025-10
