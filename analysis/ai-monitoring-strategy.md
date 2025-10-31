# AI Agent Monitoring Strategy

**Document Version:** 1.0
**Created:** 2025-10-17
**System:** GitHub Actions AI Agents
**Monitoring Scope:** Production Quality, Performance, Cost, and Reliability

---

## Executive Summary

This document defines a comprehensive monitoring strategy for AI agents in production, covering quality metrics, automated evaluation, human oversight, feedback collection, performance degradation detection, and cost monitoring.

### Monitoring Objectives

1. **Quality Assurance** - Maintain AI output quality above 8.5/10
2. **Cost Control** - Keep monthly AI costs under budget ($100 target)
3. **Performance Monitoring** - Detect degradation within 24 hours
4. **User Satisfaction** - Achieve >85% positive feedback rate
5. **Reliability** - Maintain >99% uptime and <2% error rate

### Key Metrics at a Glance

| Category | Metrics | Targets | Alert Thresholds |
|----------|---------|---------|------------------|
| Quality | Accuracy, Relevance, Consistency | >85% | <75% |
| Performance | Response time, Success rate | <30s, >98% | >45s, <95% |
| Cost | Daily spend, Cost per request | <$5/day | >$7/day |
| User Satisfaction | Feedback score, Adoption rate | >85% | <70% |

---

## 1. Quality Metrics to Track

### 1.1 Core Quality Metrics

#### Metric: Review Accuracy

**Definition:** Percentage of AI-identified issues that are valid (not false positives)

**Measurement:**
```bash
# Calculate from user feedback and manual validation
accuracy = (true_positives) / (true_positives + false_positives)

# Data sources:
# - User feedback (thumbs up/down on issues)
# - Manual spot-checks (weekly sample of 10 reviews)
# - Developer corrections (issues marked as "not applicable")
```

**Target:** ≥ 90%
**Alert Threshold:** < 80%
**Collection Frequency:** Real-time, aggregated daily

**Implementation:**
```bash
# File: scripts/lib/metrics.sh

record_accuracy_feedback() {
    local review_id="$1"
    local issue_id="$2"
    local is_valid="$3"  # true/false

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    cat >> "$METRICS_DIR/accuracy.jsonl" << EOF
{"timestamp":"$timestamp","review_id":"$review_id","issue_id":"$issue_id","is_valid":$is_valid}
EOF

    # Calculate rolling accuracy
    local accuracy
    accuracy=$(jq -s '
        map(select(.timestamp > (now - 86400 | todate))) |
        group_by(.is_valid) |
        {
            true_positives: (map(select(.[0].is_valid == true)) | length),
            false_positives: (map(select(.[0].is_valid == false)) | length)
        } |
        .true_positives / (.true_positives + .false_positives) * 100
    ' "$METRICS_DIR/accuracy.jsonl")

    # Alert if below threshold
    if (( $(echo "$accuracy < 80" | bc -l) )); then
        send_alert "accuracy_low" "Review accuracy dropped to ${accuracy}%"
    fi
}
```

#### Metric: Response Relevance

**Definition:** How well AI responses address the actual question/issue

**Measurement:**
- User ratings (1-5 stars)
- Keyword match between query and response
- Follow-up question rate (lower is better)

**Target:** ≥ 4.0/5.0 average rating
**Alert Threshold:** < 3.5/5.0
**Collection Frequency:** Per response

**Implementation:**
```bash
# Add rating prompt to responses
post_response_with_rating() {
    local issue_num="$1"
    local response="$2"

    gh issue comment "$issue_num" --body "$response

---
**How relevant was this response?**
⭐⭐⭐⭐⭐ [Excellent](${FEEDBACK_URL}?rating=5&id=${RESPONSE_ID})
⭐⭐⭐⭐ [Good](${FEEDBACK_URL}?rating=4&id=${RESPONSE_ID})
⭐⭐⭐ [Okay](${FEEDBACK_URL}?rating=3&id=${RESPONSE_ID})
⭐⭐ [Poor](${FEEDBACK_URL}?rating=2&id=${RESPONSE_ID})
⭐ [Not relevant](${FEEDBACK_URL}?rating=1&id=${RESPONSE_ID})
"
}
```

#### Metric: Output Consistency

**Definition:** Similarity of outputs for similar inputs over time

**Measurement:**
```bash
# Compare current responses to historical baseline
measure_consistency() {
    local current_response="$1"
    local similar_historical="$2"

    # Use semantic similarity (cosine distance)
    # Or simpler: keyword overlap
    local similarity
    similarity=$(calculate_text_similarity "$current_response" "$similar_historical")

    # Log consistency score
    record_metric "output.consistency" "$similarity" "gauge"

    # Alert if major deviation
    if (( $(echo "$similarity < 0.7" | bc -l) )); then
        send_alert "consistency_drift" "Output consistency dropped to ${similarity}"
    fi
}
```

**Target:** ≥ 0.85 similarity score
**Alert Threshold:** < 0.70
**Collection Frequency:** Per response (compared to 7-day average)

### 1.2 Specialized Quality Metrics

#### PR Review Quality

| Metric | Definition | Target | Alert |
|--------|------------|--------|-------|
| Issue Detection Rate | % of known issues found | >90% | <75% |
| False Negative Rate | % of issues missed | <10% | >20% |
| Recommendation Accuracy | % correct APPROVE/REQUEST_CHANGES | >95% | <90% |
| Code Coverage | % of changed lines reviewed | >90% | <80% |

#### Issue Response Quality

| Metric | Definition | Target | Alert |
|--------|------------|--------|-------|
| Question Answering Accuracy | % of questions fully answered | >85% | <70% |
| Solution Effectiveness | % of suggestions that resolve issue | >70% | <50% |
| Response Completeness | % containing all requested info | >90% | <80% |
| Tone Appropriateness | % rated as "professional and helpful" | >95% | <85% |

#### Auto-Fix Quality

| Metric | Definition | Target | Alert |
|--------|------------|--------|-------|
| Fix Success Rate | % of fixes that don't break tests | >98% | <95% |
| Fix Relevance | % of fixes addressing actual issues | >90% | <80% |
| Code Quality Improvement | Net improvement in linter score | >0 | <0 |
| Introduced Bugs | Count of bugs introduced by fixes | 0 | >0 |

---

## 2. Automated Evaluation Framework

### 2.1 Synthetic Test Suite

**Purpose:** Continuously validate AI performance using known test cases

#### Implementation

**File:** `tests/ai-quality/synthetic-tests.yaml`

```yaml
test_suites:
  - name: PR Review Tests
    tests:
      - id: security-001
        description: "Detect SQL injection vulnerability"
        input: |
          diff --git a/auth.js b/auth.js
          + const query = `SELECT * FROM users WHERE username='${username}'`;
        expected_issues:
          - type: CRITICAL
            category: security
            keyword: "SQL injection"
        expected_event: REQUEST_CHANGES

      - id: quality-001
        description: "Detect missing error handling"
        input: |
          diff --git a/api.js b/api.js
          + const data = await fetch(url);
          + return data.json();
        expected_issues:
          - type: MAJOR
            category: error-handling
            keyword: "try-catch"
        expected_event: REQUEST_CHANGES

      - id: style-001
        description: "Approve clean, well-documented code"
        input: |
          diff --git a/utils.js b/utils.js
          + /**
          +  * Formats a date string
          +  * @param {Date} date - Input date
          +  * @returns {string} Formatted date
          +  */
          + function formatDate(date) {
          +   return date.toISOString().split('T')[0];
          + }
        expected_issues: []
        expected_event: APPROVE

  - name: Issue Response Tests
    tests:
      - id: question-001
        description: "Answer technical question accurately"
        input: "What is the difference between REST and GraphQL?"
        expected_keywords: ["REST", "GraphQL", "endpoints", "query language"]
        min_length: 200

      - id: bug-analysis-001
        description: "Analyze bug report"
        input: "App crashes when clicking submit button"
        expected_keywords: ["error logs", "reproduce", "browser", "console"]
        expected_sections: ["Root Cause", "Solution"]
```

**Execution Script:**

```bash
#!/usr/bin/env bash
# File: tests/ai-quality/run-synthetic-tests.sh

run_synthetic_test() {
    local test_id="$1"
    local test_data="$2"

    # Extract test details
    local input=$(echo "$test_data" | jq -r '.input')
    local expected=$(echo "$test_data" | jq -r '.expected_issues')

    # Run AI agent
    local response
    response=$(./scripts/ai-review.sh --pr "$TEST_PR" --input "$input")

    # Validate response
    local passed=true

    # Check for expected issues
    for expected_issue in $(echo "$expected" | jq -c '.[]'); do
        local keyword=$(echo "$expected_issue" | jq -r '.keyword')

        if ! echo "$response" | grep -qi "$keyword"; then
            echo "FAIL: $test_id - Missing expected keyword: $keyword"
            passed=false
        fi
    done

    # Record result
    if [[ "$passed" == "true" ]]; then
        record_metric "synthetic_test.passed.$test_id" "1" "counter"
        echo "PASS: $test_id"
    else
        record_metric "synthetic_test.failed.$test_id" "1" "counter"
        send_alert "synthetic_test_failure" "Test $test_id failed"
        echo "FAIL: $test_id"
    fi
}

# Run all tests
run_all_synthetic_tests() {
    local test_file="tests/ai-quality/synthetic-tests.yaml"
    local total_tests=0
    local passed_tests=0

    # Parse YAML and run each test
    yq eval '.test_suites[].tests[]' "$test_file" | while read -r test; do
        total_tests=$((total_tests + 1))

        if run_synthetic_test "$test"; then
            passed_tests=$((passed_tests + 1))
        fi
    done

    # Calculate pass rate
    local pass_rate=$((passed_tests * 100 / total_tests))

    record_metric "synthetic_test.pass_rate" "$pass_rate" "gauge"

    # Alert if pass rate drops
    if [[ $pass_rate -lt 90 ]]; then
        send_alert "synthetic_test_pass_rate_low" "Pass rate: ${pass_rate}%"
    fi

    echo "Synthetic tests: $passed_tests/$total_tests passed (${pass_rate}%)"
}

# Schedule: Run every 6 hours
# Cron: 0 */6 * * * /path/to/run-synthetic-tests.sh
```

### 2.2 Regression Test Suite

**Purpose:** Detect when changes break previously working functionality

```bash
# File: tests/ai-quality/regression-tests.sh

capture_baseline_response() {
    local test_id="$1"
    local input="$2"

    # Run AI and save response
    local response
    response=$(run_ai_agent "$input")

    # Save as baseline
    echo "$response" > "baselines/$test_id.baseline.txt"

    # Extract quality metrics from baseline
    jq -n \
        --arg test_id "$test_id" \
        --arg response "$response" \
        '{
            test_id: $test_id,
            response: $response,
            length: ($response | length),
            timestamp: (now | todate)
        }' > "baselines/$test_id.baseline.json"
}

compare_to_baseline() {
    local test_id="$1"
    local current_response="$2"
    local baseline_file="baselines/$test_id.baseline.txt"

    if [[ ! -f "$baseline_file" ]]; then
        echo "No baseline found for $test_id, creating..."
        capture_baseline_response "$test_id" "$current_response"
        return 0
    fi

    local baseline
    baseline=$(cat "$baseline_file")

    # Calculate similarity
    local similarity
    similarity=$(calculate_similarity "$current_response" "$baseline")

    # Alert if significant deviation
    if (( $(echo "$similarity < 0.75" | bc -l) )); then
        echo "REGRESSION: $test_id similarity dropped to $similarity"
        send_alert "regression_detected" "Test $test_id regressed (similarity: $similarity)"
        return 1
    fi

    echo "PASS: $test_id (similarity: $similarity)"
    return 0
}
```

### 2.3 Automated Scoring System

```bash
# File: scripts/lib/quality-scorer.sh

calculate_quality_score() {
    local response="$1"
    local response_type="$2"  # review, agent, autofix

    local score=100

    # Deduct for missing elements
    case "$response_type" in
        review)
            # Must have overall assessment
            if ! echo "$response" | grep -qi "overall"; then
                score=$((score - 20))
            fi

            # Must have strengths
            if ! echo "$response" | grep -qi "strength"; then
                score=$((score - 15))
            fi

            # Must have recommendation
            if ! echo "$response" | grep -qiE "(APPROVE|REQUEST_CHANGES|COMMENT)"; then
                score=$((score - 30))
            fi

            # Deduct for vague language
            local vague_count
            vague_count=$(echo "$response" | grep -oiE "(maybe|perhaps|possibly|might)" | wc -l)
            score=$((score - vague_count * 2))
            ;;

        agent)
            # Check completeness
            local word_count
            word_count=$(echo "$response" | wc -w)

            if [[ $word_count -lt 50 ]]; then
                score=$((score - 20))
            fi

            # Check for actionable content
            if ! echo "$response" | grep -qiE "(steps|solution|fix|try)"; then
                score=$((score - 15))
            fi
            ;;
    esac

    # Ensure score is in valid range
    if [[ $score -lt 0 ]]; then
        score=0
    fi

    echo "$score"
}

# Record scores
record_quality_score() {
    local response_id="$1"
    local score="$2"

    record_metric "quality_score.overall" "$score" "gauge"

    # Alert if score is low
    if [[ $score -lt 70 ]]; then
        send_alert "low_quality_score" "Response $response_id scored $score/100"
    fi
}
```

---

## 3. Human-in-the-Loop Evaluation

### 3.1 Manual Review Process

#### Weekly Spot-Check Protocol

**Sample Size:** 10 reviews, 10 issue responses, 5 auto-fixes per week

**Selection Criteria:**
- 5 random samples (unbiased)
- 5 edge cases (longest, shortest, most complex)
- All responses with user feedback (positive or negative)

**Review Checklist:**

**PR Reviews:**
```
[ ] All changed files were considered
[ ] Critical issues were identified (if present)
[ ] No false positives (invalid issues)
[ ] Recommendation (APPROVE/REQUEST_CHANGES) is appropriate
[ ] Feedback is constructive and specific
[ ] Code examples are accurate
[ ] Severity levels (CRITICAL/MAJOR/MINOR) are correct
[ ] Tone is professional and helpful

Score: ___/10
Notes: _________________
```

**Issue Responses:**
```
[ ] Question was fully understood
[ ] Answer addresses all parts of question
[ ] Technical accuracy is high
[ ] Examples/code snippets are correct
[ ] Response is concise but complete
[ ] Tone is helpful and encouraging
[ ] Suggested actions are clear

Score: ___/10
Notes: _________________
```

#### Manual Review Dashboard

**File:** `scripts/quality-dashboard.sh`

```bash
#!/usr/bin/env bash

generate_review_queue() {
    echo "=== Manual Review Queue ==="
    echo ""

    # Random samples
    echo "Random Samples (5):"
    jq -s '
        map(select(.timestamp > (now - 604800 | todate))) |
        [.[] | select(.type == "review")] |
        .[0:5] |
        .[] | "- \(.id) (\(.timestamp)) - \(.pr_number)"
    ' "$METRICS_DIR/responses.jsonl"

    echo ""

    # Edge cases
    echo "Edge Cases (5):"
    jq -s '
        map(select(.timestamp > (now - 604800 | todate))) |
        sort_by(.response_length) |
        ([.[0:2], .[-3:]] | .[]) |
        "- \(.id) (\(.response_length) chars)"
    ' "$METRICS_DIR/responses.jsonl"

    echo ""

    # User flagged
    echo "User Feedback Items:"
    jq -s '
        map(select(.user_feedback == "negative")) |
        .[] | "- \(.id) - Rating: \(.rating)/5"
    ' "$METRICS_DIR/feedback.jsonl"
}

# Usage: ./quality-dashboard.sh > review-queue-$(date +%Y%m%d).txt
```

### 3.2 Expert Review Panel

**Frequency:** Monthly
**Panel Size:** 3 senior engineers
**Duration:** 2 hours

**Process:**
1. Select 30 AI responses (10 per reviewer)
2. Each reviewer scores independently
3. Discuss discrepancies
4. Calculate inter-rater reliability
5. Identify improvement areas

**Scoring Rubric:**

| Dimension | Weight | Score Range |
|-----------|--------|-------------|
| Technical Accuracy | 30% | 0-10 |
| Completeness | 20% | 0-10 |
| Relevance | 20% | 0-10 |
| Clarity | 15% | 0-10 |
| Actionability | 15% | 0-10 |

**Implementation:**

```bash
# File: scripts/expert-review.sh

generate_expert_review_packet() {
    local reviewer_name="$1"
    local output_dir="expert-reviews/$(date +%Y%m%d)"

    mkdir -p "$output_dir"

    # Select 10 responses
    local samples
    samples=$(jq -s '[.[] | select(.needs_expert_review == true)] | .[0:10]' "$METRICS_DIR/responses.jsonl")

    # Generate review form
    cat > "$output_dir/${reviewer_name}-review-form.md" << EOF
# Expert Review Form - $(date +%Y-%m-%d)
## Reviewer: $reviewer_name

Instructions:
- Review each response carefully
- Score each dimension 0-10
- Provide specific feedback
- Suggest improvements

---

$(echo "$samples" | jq -r '.[] | "
## Response ID: \(.id)

### Context
- Type: \(.type)
- Date: \(.timestamp)
- PR/Issue: #\(.number)

### AI Response
\`\`\`
\(.response)
\`\`\`

### Scoring
- Technical Accuracy (0-10): ____
- Completeness (0-10): ____
- Relevance (0-10): ____
- Clarity (0-10): ____
- Actionability (0-10): ____

### Feedback
[Your detailed feedback here]

### Suggested Improvements
[Specific suggestions]

---
"')
EOF

    echo "Review packet generated: $output_dir/${reviewer_name}-review-form.md"
}
```

---

## 4. Feedback Collection Mechanisms

### 4.1 Inline Feedback Buttons

```bash
# Add to all AI responses
add_feedback_buttons() {
    local response_id="$1"
    local response_body="$2"

    cat << EOF
$response_body

---
**Was this helpful?**
👍 [Yes, helpful](${FEEDBACK_URL}/helpful/${response_id}) •
👎 [Not helpful](${FEEDBACK_URL}/not-helpful/${response_id}) •
💭 [Partially helpful](${FEEDBACK_URL}/partial/${response_id})

<details>
<summary>Provide detailed feedback</summary>

**What worked well?**
[Click to add comment]

**What could be improved?**
[Click to add comment]

**Suggestions:**
[Click to add comment]

</details>
EOF
}
```

### 4.2 Feedback Collection API

**File:** `api/feedback-collector.js`

```javascript
// Simple Express endpoint for feedback
app.post('/feedback/:type/:response_id', (req, res) => {
    const { type, response_id } = req.params;
    const { comment, rating } = req.body;

    const feedback = {
        response_id,
        type,  // helpful, not-helpful, partial
        rating: rating || (type === 'helpful' ? 5 : 1),
        comment,
        timestamp: new Date().toISOString(),
        user: req.user.login
    };

    // Store feedback
    fs.appendFileSync(
        'metrics/feedback.jsonl',
        JSON.stringify(feedback) + '\n'
    );

    // Update metrics
    recordMetric('feedback.received', 1, 'counter');
    recordMetric(`feedback.${type}`, 1, 'counter');

    // Check for negative feedback threshold
    checkNegativeFeedbackThreshold();

    res.json({ success: true, message: 'Thank you for your feedback!' });
});

function checkNegativeFeedbackThreshold() {
    const recentFeedback = getRecentFeedback(86400); // Last 24h

    const negativeRate = recentFeedback.filter(f => f.type === 'not-helpful').length
                       / recentFeedback.length;

    if (negativeRate > 0.3) {
        sendAlert('high_negative_feedback', `Negative feedback rate: ${negativeRate * 100}%`);
    }
}
```

### 4.3 Follow-Up Question Tracking

```bash
# Detect if user asks follow-up question (indicates incomplete answer)
track_follow_up_questions() {
    local issue_num="$1"
    local agent_comment_id="$2"

    # Get all comments after agent response
    local follow_ups
    follow_ups=$(gh api repos/$GITHUB_REPOSITORY/issues/$issue_num/comments \
        --jq ".[] | select(.id > $agent_comment_id and .user.login != \"github-actions[bot]\")")

    local follow_up_count
    follow_up_count=$(echo "$follow_ups" | jq -s 'length')

    # Record metric
    record_metric "follow_up_questions.count" "$follow_up_count" "gauge"

    # If multiple follow-ups, mark as incomplete response
    if [[ $follow_up_count -ge 2 ]]; then
        record_metric "incomplete_response" "1" "counter"

        # Flag for manual review
        echo "$agent_comment_id" >> "$METRICS_DIR/incomplete-responses.txt"
    fi
}
```

### 4.4 Feedback Analysis Dashboard

```bash
# File: scripts/feedback-dashboard.sh

generate_feedback_report() {
    local period="${1:-7}"  # Days

    echo "=== Feedback Report (Last $period days) ==="
    echo ""

    # Overall satisfaction
    echo "Overall Satisfaction:"
    jq -s "
        map(select(.timestamp > (now - $period * 86400 | todate))) |
        group_by(.type) |
        map({
            type: .[0].type,
            count: length,
            percentage: (length / $(jq -s 'length' "$METRICS_DIR/feedback.jsonl") * 100)
        })
    " "$METRICS_DIR/feedback.jsonl"

    echo ""

    # Average rating
    echo "Average Rating:"
    jq -s "
        map(select(.timestamp > (now - $period * 86400 | todate) and .rating != null)) |
        map(.rating) |
        add / length
    " "$METRICS_DIR/feedback.jsonl"

    echo ""

    # Common themes in negative feedback
    echo "Negative Feedback Themes:"
    jq -s "
        map(select(.type == \"not-helpful\" and .comment != null)) |
        map(.comment)
    " "$METRICS_DIR/feedback.jsonl" | grep -oE '\w+' | sort | uniq -c | sort -rn | head -20

    echo ""

    # Improvement suggestions
    echo "Top Improvement Suggestions:"
    jq -s '
        map(select(.comment != null)) |
        group_by(.comment) |
        sort_by(length) |
        reverse |
        .[0:5] |
        .[] | "- \(.[0].comment) (mentioned \(length) times)"
    ' "$METRICS_DIR/feedback.jsonl"
}

# Run weekly
generate_feedback_report 7 > "reports/feedback-$(date +%Y%m%d).txt"
```

---

## 5. Model Performance Degradation Detection

### 5.1 Baseline Establishment

```bash
# File: scripts/establish-baseline.sh

establish_quality_baseline() {
    echo "Establishing quality baseline..."

    # Run synthetic tests to get baseline scores
    local baseline_file="baselines/quality-baseline-$(date +%Y%m%d).json"

    local synthetic_score
    synthetic_score=$(run_all_synthetic_tests | grep "pass_rate" | cut -d':' -f2)

    # Calculate average response quality from recent production data
    local avg_quality
    avg_quality=$(jq -s '
        map(select(.timestamp > (now - 604800 | todate))) |
        map(.quality_score) |
        add / length
    ' "$METRICS_DIR/metrics.jsonl")

    # Calculate average user satisfaction
    local avg_satisfaction
    avg_satisfaction=$(jq -s '
        map(select(.timestamp > (now - 604800 | todate) and .rating != null)) |
        map(.rating) |
        add / length
    ' "$METRICS_DIR/feedback.jsonl")

    # Save baseline
    jq -n \
        --arg date "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --argjson synthetic "$synthetic_score" \
        --argjson quality "$avg_quality" \
        --argjson satisfaction "$avg_satisfaction" \
        '{
            date: $date,
            synthetic_test_score: $synthetic,
            avg_quality_score: $quality,
            avg_user_satisfaction: $satisfaction,
            model: "claude-3-5-sonnet-20241022",
            prompt_version: "1.0"
        }' > "$baseline_file"

    # Symlink to current baseline
    ln -sf "$baseline_file" "baselines/current-baseline.json"

    echo "Baseline established: $baseline_file"
}

# Run monthly or after major changes
```

### 5.2 Drift Detection

```bash
# File: scripts/detect-quality-drift.sh

detect_quality_drift() {
    local baseline_file="baselines/current-baseline.json"

    if [[ ! -f "$baseline_file" ]]; then
        echo "No baseline found, establishing..."
        establish_quality_baseline
        return 0
    fi

    # Load baseline
    local baseline_quality
    baseline_quality=$(jq -r '.avg_quality_score' "$baseline_file")

    local baseline_satisfaction
    baseline_satisfaction=$(jq -r '.avg_user_satisfaction' "$baseline_file")

    # Calculate current metrics (last 7 days)
    local current_quality
    current_quality=$(jq -s '
        map(select(.timestamp > (now - 604800 | todate))) |
        map(.quality_score) |
        add / length
    ' "$METRICS_DIR/metrics.jsonl")

    local current_satisfaction
    current_satisfaction=$(jq -s '
        map(select(.timestamp > (now - 604800 | todate))) |
        map(.rating) |
        add / length
    ' "$METRICS_DIR/feedback.jsonl")

    # Calculate drift percentages
    local quality_drift
    quality_drift=$(echo "scale=2; ($baseline_quality - $current_quality) / $baseline_quality * 100" | bc)

    local satisfaction_drift
    satisfaction_drift=$(echo "scale=2; ($baseline_satisfaction - $current_satisfaction) / $baseline_satisfaction * 100" | bc)

    echo "Quality Drift Analysis:"
    echo "  Baseline Quality: $baseline_quality"
    echo "  Current Quality: $current_quality"
    echo "  Drift: ${quality_drift}%"
    echo ""
    echo "  Baseline Satisfaction: $baseline_satisfaction"
    echo "  Current Satisfaction: $current_satisfaction"
    echo "  Drift: ${satisfaction_drift}%"

    # Alert on significant drift
    if (( $(echo "$quality_drift > 10" | bc -l) )); then
        send_alert "quality_drift_detected" "Quality drifted -${quality_drift}% from baseline"
        return 1
    fi

    if (( $(echo "$satisfaction_drift > 15" | bc -l) )); then
        send_alert "satisfaction_drift_detected" "Satisfaction drifted -${satisfaction_drift}% from baseline"
        return 1
    fi

    return 0
}

# Run daily
# Cron: 0 8 * * * /path/to/detect-quality-drift.sh
```

### 5.3 Statistical Process Control (SPC)

```bash
# File: scripts/spc-monitoring.sh

# Implement control charts for quality metrics
calculate_control_limits() {
    local metric_name="$1"
    local window_days="${2:-30}"

    # Get historical data
    local data
    data=$(jq -s "
        map(select(.metric == \"$metric_name\" and
                   .timestamp > (now - $window_days * 86400 | todate))) |
        map(.value)
    " "$METRICS_DIR/metrics.jsonl")

    # Calculate mean and standard deviation
    local mean
    mean=$(echo "$data" | jq 'add / length')

    local stddev
    stddev=$(echo "$data" | jq -r '
        . as $data |
        ($data | add / length) as $mean |
        ($data | map(pow(. - $mean; 2)) | add / length | sqrt)
    ')

    # Control limits (±3 sigma)
    local ucl
    ucl=$(echo "$mean + 3 * $stddev" | bc -l)

    local lcl
    lcl=$(echo "$mean - 3 * $stddev" | bc -l)

    echo "mean=$mean"
    echo "stddev=$stddev"
    echo "ucl=$ucl"
    echo "lcl=$lcl"
}

check_out_of_control() {
    local current_value="$1"
    local control_limits="$2"

    local mean=$(echo "$control_limits" | grep "mean=" | cut -d'=' -f2)
    local ucl=$(echo "$control_limits" | grep "ucl=" | cut -d'=' -f2)
    local lcl=$(echo "$control_limits" | grep "lcl=" | cut -d'=' -f2)

    # Check if value exceeds control limits
    if (( $(echo "$current_value > $ucl" | bc -l) )) || \
       (( $(echo "$current_value < $lcl" | bc -l) )); then
        return 0  # Out of control
    fi

    return 1  # In control
}

# Monitor key metrics
monitor_quality_spc() {
    local metrics=("quality_score.overall" "feedback.satisfaction" "synthetic_test.pass_rate")

    for metric in "${metrics[@]}"; do
        # Calculate control limits
        local limits
        limits=$(calculate_control_limits "$metric")

        # Get current value
        local current
        current=$(jq -s "
            map(select(.metric == \"$metric\")) |
            sort_by(.timestamp) |
            .[-1].value
        " "$METRICS_DIR/metrics.jsonl")

        # Check if out of control
        if check_out_of_control "$current" "$limits"; then
            send_alert "spc_out_of_control" "Metric $metric is out of control: $current"
        fi
    done
}

# Run every 6 hours
```

### 5.4 Anomaly Detection

```bash
# File: scripts/anomaly-detection.sh

detect_anomalies() {
    local metric_name="$1"

    # Get recent data (last 7 days)
    local recent_data
    recent_data=$(jq -s "
        map(select(.metric == \"$metric_name\" and
                   .timestamp > (now - 604800 | todate))) |
        map(.value)
    " "$METRICS_DIR/metrics.jsonl")

    # Simple anomaly detection using IQR method
    local q1=$(echo "$recent_data" | jq 'sort | .[length * 0.25 | floor]')
    local q3=$(echo "$recent_data" | jq 'sort | .[length * 0.75 | floor]')
    local iqr=$(echo "$q3 - $q1" | bc -l)

    local lower_bound=$(echo "$q1 - 1.5 * $iqr" | bc -l)
    local upper_bound=$(echo "$q3 + 1.5 * $iqr" | bc -l)

    # Get latest value
    local latest
    latest=$(echo "$recent_data" | jq '.[-1]')

    # Check if anomaly
    if (( $(echo "$latest < $lower_bound" | bc -l) )) || \
       (( $(echo "$latest > $upper_bound" | bc -l) )); then
        send_alert "anomaly_detected" "Metric $metric_name anomaly: $latest (bounds: $lower_bound - $upper_bound)"
        return 0
    fi

    return 1
}

# Run hourly for critical metrics
```

---

## 6. Cost Monitoring and Budget Alerts

### 6.1 Cost Tracking

```bash
# File: scripts/lib/cost-tracker.sh

# Track costs per request
record_request_cost() {
    local request_type="$1"  # review, agent, autofix
    local model="$2"
    local input_tokens="$3"
    local output_tokens="$4"

    # Model pricing (per 1M tokens)
    declare -A INPUT_COSTS=(
        ["claude-3-5-sonnet-20241022"]="3.00"
        ["claude-3-5-haiku-20241022"]="0.80"
        ["claude-3-opus-20240229"]="15.00"
    )

    declare -A OUTPUT_COSTS=(
        ["claude-3-5-sonnet-20241022"]="15.00"
        ["claude-3-5-haiku-20241022"]="4.00"
        ["claude-3-opus-20240229"]="75.00"
    )

    # Calculate cost
    local input_cost=$(echo "scale=6; $input_tokens * ${INPUT_COSTS[$model]} / 1000000" | bc)
    local output_cost=$(echo "scale=6; $output_tokens * ${OUTPUT_COSTS[$model]} / 1000000" | bc)
    local total_cost=$(echo "$input_cost + $output_cost" | bc)

    # Record metrics
    record_metric "cost.total" "$total_cost" "counter"
    record_metric "cost.$request_type" "$total_cost" "counter"
    record_metric "cost.model.$model" "$total_cost" "counter"
    record_metric "tokens.input.$request_type" "$input_tokens" "counter"
    record_metric "tokens.output.$request_type" "$output_tokens" "counter"

    # Detailed cost log
    cat >> "$METRICS_DIR/costs.jsonl" << EOF
{"timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","type":"$request_type","model":"$model","input_tokens":$input_tokens,"output_tokens":$output_tokens,"cost":$total_cost}
EOF
}
```

### 6.2 Budget Management

```bash
# File: scripts/budget-monitor.sh

check_budget() {
    local daily_budget="${DAILY_BUDGET:-5.00}"
    local monthly_budget="${MONTHLY_BUDGET:-100.00}"

    # Calculate today's spending
    local today_spend
    today_spend=$(jq -s "
        map(select(.timestamp > (now - 86400 | todate))) |
        map(.cost) |
        add
    " "$METRICS_DIR/costs.jsonl")

    # Calculate this month's spending
    local month_start=$(date -d "$(date +%Y-%m-01)" +%s)
    local month_spend
    month_spend=$(jq -s "
        map(select(.timestamp | fromdateiso8601 > $month_start)) |
        map(.cost) |
        add
    " "$METRICS_DIR/costs.jsonl")

    echo "Budget Status:"
    echo "  Daily: \$${today_spend} / \$${daily_budget}"
    echo "  Monthly: \$${month_spend} / \$${monthly_budget}"

    # Check thresholds
    local daily_pct=$(echo "scale=0; $today_spend / $daily_budget * 100" | bc)
    local monthly_pct=$(echo "scale=0; $month_spend / $monthly_budget * 100" | bc)

    # Alert at 80% threshold
    if [[ $daily_pct -ge 80 ]]; then
        send_alert "budget_warning_daily" "Daily budget at ${daily_pct}%: \$${today_spend} / \$${daily_budget}"
    fi

    if [[ $monthly_pct -ge 80 ]]; then
        send_alert "budget_warning_monthly" "Monthly budget at ${monthly_pct}%: \$${month_spend} / \$${monthly_budget}"
    fi

    # Hard stop at 100%
    if [[ $daily_pct -ge 100 ]]; then
        send_alert "budget_exceeded_daily" "Daily budget exceeded: \$${today_spend}"
        return 1
    fi

    if [[ $monthly_pct -ge 100 ]]; then
        send_alert "budget_exceeded_monthly" "Monthly budget exceeded: \$${month_spend}"
        return 1
    fi

    return 0
}

# Run before each AI request
before_ai_request() {
    if ! check_budget; then
        echo "::error::Budget exceeded, AI request blocked"
        exit 1
    fi
}
```

### 6.3 Cost Optimization Monitoring

```bash
# File: scripts/cost-optimization.sh

analyze_cost_efficiency() {
    echo "=== Cost Efficiency Analysis ==="
    echo ""

    # Cost per agent type
    echo "Cost per Agent Type:"
    jq -s '
        group_by(.type) |
        map({
            type: .[0].type,
            total_cost: (map(.cost) | add),
            avg_cost: (map(.cost) | add / length),
            count: length
        })
    ' "$METRICS_DIR/costs.jsonl"

    echo ""

    # Cost by model
    echo "Cost by Model:"
    jq -s '
        group_by(.model) |
        map({
            model: .[0].model,
            total_cost: (map(.cost) | add),
            usage_pct: (length / $(jq -s 'length' "$METRICS_DIR/costs.jsonl") * 100),
            avg_tokens: (map(.input_tokens + .output_tokens) | add / length)
        })
    ' "$METRICS_DIR/costs.jsonl"

    echo ""

    # Identify cost-saving opportunities
    echo "Cost Optimization Opportunities:"

    # Find expensive requests
    jq -s '
        sort_by(.cost) |
        reverse |
        .[0:10] |
        .[] | "- \(.type) (\(.model)): $\(.cost) - \(.input_tokens + .output_tokens) tokens"
    ' "$METRICS_DIR/costs.jsonl"

    echo ""

    # Calculate potential savings from tiered models
    local current_cost
    current_cost=$(jq -s 'map(.cost) | add' "$METRICS_DIR/costs.jsonl")

    # Estimate with tiered strategy (assuming 30% use Haiku, 65% Sonnet, 5% Opus)
    local estimated_optimized
    estimated_optimized=$(echo "$current_cost * 0.6" | bc)  # ~40% savings

    echo "Estimated savings with tiered model strategy: \$$estimated_optimized per period"
}

# Run weekly
```

### 6.4 Cost Alerts

```bash
# File: scripts/lib/alerts.sh

send_alert() {
    local alert_type="$1"
    local message="$2"
    local severity="${3:-warning}"  # info, warning, critical

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Log alert
    cat >> "$METRICS_DIR/alerts.jsonl" << EOF
{"timestamp":"$timestamp","type":"$alert_type","message":"$message","severity":"$severity"}
EOF

    # Send notification based on severity
    case "$severity" in
        critical)
            # PagerDuty/Slack/Email
            send_pagerduty_alert "$alert_type" "$message"
            send_slack_alert "#alerts-critical" "🚨 $message"
            send_email_alert "team@example.com" "CRITICAL: $alert_type" "$message"
            ;;
        warning)
            send_slack_alert "#alerts-warning" "⚠️ $message"
            ;;
        info)
            send_slack_alert "#alerts-info" "ℹ️ $message"
            ;;
    esac

    # Log to GitHub Actions
    echo "::$severity::$message"
}

# Alert types:
# - accuracy_low
# - consistency_drift
# - synthetic_test_failure
# - budget_warning_daily
# - budget_exceeded_monthly
# - quality_drift_detected
# - high_negative_feedback
# - spc_out_of_control
# - anomaly_detected
```

---

## 7. Dashboards and Reporting

### 7.1 Real-Time Dashboard

**File:** `dashboards/ai-metrics.html`

```html
<!DOCTYPE html>
<html>
<head>
    <title>AI Agent Metrics Dashboard</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@3.9.1/dist/chart.min.js"></script>
</head>
<body>
    <h1>AI Agent Metrics Dashboard</h1>

    <div class="metrics-grid">
        <div class="metric-card">
            <h3>Quality Score</h3>
            <canvas id="qualityChart"></canvas>
            <p class="current-value" id="currentQuality">Loading...</p>
        </div>

        <div class="metric-card">
            <h3>Response Time</h3>
            <canvas id="latencyChart"></canvas>
            <p class="current-value" id="currentLatency">Loading...</p>
        </div>

        <div class="metric-card">
            <h3>Daily Cost</h3>
            <canvas id="costChart"></canvas>
            <p class="current-value" id="currentCost">Loading...</p>
        </div>

        <div class="metric-card">
            <h3>User Satisfaction</h3>
            <canvas id="satisfactionChart"></canvas>
            <p class="current-value" id="currentSatisfaction">Loading...</p>
        </div>
    </div>

    <script>
        // Fetch metrics and update charts
        async function fetchMetrics() {
            const response = await fetch('/api/metrics/summary');
            const data = await response.json();

            updateQualityChart(data.quality);
            updateLatencyChart(data.latency);
            updateCostChart(data.cost);
            updateSatisfactionChart(data.satisfaction);
        }

        // Refresh every 30 seconds
        setInterval(fetchMetrics, 30000);
        fetchMetrics();
    </script>
</body>
</html>
```

### 7.2 Weekly Reports

```bash
# File: scripts/weekly-report.sh

generate_weekly_report() {
    local report_file="reports/weekly-$(date +%Y%m%d).md"

    cat > "$report_file" << EOF
# AI Agent Weekly Report
## Week of $(date -d "7 days ago" +%Y-%m-%d) to $(date +%Y-%m-%d)

### Executive Summary
$(generate_executive_summary)

### Quality Metrics
$(generate_quality_metrics_section)

### Performance Metrics
$(generate_performance_metrics_section)

### Cost Analysis
$(generate_cost_analysis_section)

### User Feedback
$(generate_feedback_section)

### Issues and Actions
$(generate_issues_and_actions)

### Next Week Focus
$(generate_next_week_focus)
EOF

    echo "Weekly report generated: $report_file"

    # Email report to team
    send_email_report "team@example.com" "AI Agent Weekly Report" "$report_file"
}

# Schedule: Run every Monday at 9 AM
# Cron: 0 9 * * 1 /path/to/weekly-report.sh
```

### 7.3 Monthly Business Review

```bash
generate_monthly_review() {
    local month=$(date -d "last month" +%Y-%m)

    cat > "reports/monthly-${month}.md" << EOF
# AI Agent Monthly Review - $month

## Key Achievements
- Total requests processed: $(count_monthly_requests)
- Average quality score: $(calculate_monthly_avg_quality)
- Cost efficiency: \$$(calculate_monthly_cost) ($(calculate_cost_per_request) per request)
- User satisfaction: $(calculate_monthly_satisfaction)%

## Trends
$(analyze_monthly_trends)

## Model Performance Comparison
$(compare_models_monthly)

## Cost Breakdown
$(generate_monthly_cost_breakdown)

## User Feedback Themes
$(analyze_monthly_feedback)

## Improvements Implemented
$(list_monthly_improvements)

## Action Items for Next Month
$(generate_action_items)
EOF
}
```

---

## 8. Alert Configuration

### 8.1 Alert Thresholds

| Metric | Warning | Critical | Action |
|--------|---------|----------|--------|
| Quality Score | < 8.0 | < 7.0 | Review prompts, check model |
| Accuracy | < 85% | < 75% | Manual review, adjust confidence threshold |
| Response Time | > 45s | > 60s | Check API status, optimize context |
| Daily Cost | > $4 | > $6 | Review usage, implement rate limiting |
| Monthly Cost | > $90 | > $120 | Emergency review, block non-critical |
| Error Rate | > 5% | > 10% | Check logs, review error handling |
| Negative Feedback | > 20% | > 30% | Urgent quality review |
| Synthetic Test Pass Rate | < 95% | < 90% | Regression detected, investigate |

### 8.2 Alert Routing

**Severity Levels:**

**INFO:**
- Slack #ai-agents-info
- Log only

**WARNING:**
- Slack #ai-agents-alerts
- Email to team@example.com
- Create GitHub issue

**CRITICAL:**
- PagerDuty (on-call engineer)
- Slack #incidents
- Email to leadership
- Auto-create incident ticket

---

## 9. Continuous Improvement Process

### 9.1 Monthly Review Cycle

1. **Week 1:** Analyze previous month data
2. **Week 2:** Identify top 3 improvement areas
3. **Week 3:** Implement improvements, A/B test
4. **Week 4:** Evaluate results, update baseline

### 9.2 Improvement Tracking

```bash
# File: improvements/improvement-log.jsonl

{
  "date": "2025-10-17",
  "improvement": "Added few-shot examples to PR review prompts",
  "expected_impact": "+15% format compliance",
  "actual_impact": "+18% format compliance",
  "status": "successful",
  "rollout": "100%"
}
```

### 9.3 Success Criteria

**Quality Improvements:**
- Sustained quality score > 8.5/10 for 30 days
- User satisfaction > 85% for 30 days
- Accuracy > 90% for 30 days

**Cost Optimizations:**
- Monthly cost reduction of 10% or more
- No degradation in quality (< 2% drop)
- Maintained user satisfaction

---

## Appendix A: Metrics Glossary

| Metric | Definition | Calculation | Target |
|--------|------------|-------------|--------|
| Quality Score | Overall AI output quality | Automated scoring + manual review | > 8.5/10 |
| Accuracy | Validity of AI findings | True positives / (TP + FP) | > 90% |
| Relevance | Response addresses query | User rating average | > 4.0/5.0 |
| Consistency | Output similarity over time | Cosine similarity to baseline | > 0.85 |
| Response Time | API latency | Time from request to response | < 30s |
| Success Rate | Non-error requests | Successful / Total requests | > 98% |
| Cost per Request | Average cost | Total cost / Request count | < $0.02 |
| User Satisfaction | Positive feedback rate | Positive / Total feedback | > 85% |
| Synthetic Test Pass Rate | Test suite success | Passed tests / Total tests | > 95% |

---

**Monitoring Strategy Version:** 1.0
**Last Updated:** 2025-10-17
**Next Review:** 2025-11-17
**Owner:** ML Engineering Team
