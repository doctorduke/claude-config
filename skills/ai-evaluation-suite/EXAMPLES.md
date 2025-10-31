# AI Evaluation Examples

Real-world evaluation scenarios and complete workflows.

## Example 1: End-to-End LLM Quality Evaluation

Building an evaluation dataset and running quality assessment.

```python
import json
from pathlib import Path

# Create evaluation dataset
eval_dataset = [
    {
        "id": "q1",
        "query": "What is machine learning?",
        "output": "Machine learning is a subset of AI that enables systems to learn from data.",
        "ground_truth": "ML is a field of AI where systems improve through experience.",
        "domain": "general_knowledge"
    },
    {
        "id": "q2",
        "query": "Solve 25 + 37",
        "output": "The sum is 62.",
        "ground_truth": "25 + 37 = 62",
        "domain": "arithmetic"
    },
    {
        "id": "q3",
        "query": "Summarize: The quick brown fox jumps over the lazy dog.",
        "output": "A fast brown fox jumps above a lazy dog.",
        "ground_truth": "Quick fox jumps over lazy dog.",
        "domain": "summarization"
    }
]

# Save dataset
Path("eval_dataset.json").write_text(json.dumps(eval_dataset, indent=2))

# Run evaluation
from ai_evaluation_suite import LLMQualityEvaluator

evaluator = LLMQualityEvaluator()
results = evaluator.batch_evaluate(eval_dataset)

# Generate report
report = f"""
Quality Evaluation Report
=========================

Total Cases: {len(results['results'])}

Summary Scores:
- Coherence: {results['summary']['coherence']:.2f}
- Relevance: {results['summary']['relevance']:.2f}
- Factuality: {results['summary']['factuality']:.2f}
- Completeness: {results['summary']['completeness']:.2f}
- Conciseness: {results['summary']['conciseness']:.2f}
- Overall: {results['summary']['overall']:.2f}

Details:
"""

for result in results['results']:
    report += f"\n- {result['case_id']}: {result['metrics'].overall_score:.2f}"

print(report)
```

## Example 2: Prompt A/B Testing Workflow

Compare prompt variations on real test set.

```python
# Define prompt variations
variants = [
    {
        "id": "baseline",
        "template": "Summarize in 3 points:\n\n{text}",
        "description": "Simple direct instruction"
    },
    {
        "id": "structured",
        "template": "Summarize using this format:\n1. Main point\n2. Supporting detail\n3. Conclusion\n\nText: {text}",
        "description": "Structured output format"
    },
    {
        "id": "role_based",
        "template": "You are a technical writer. Summarize for a manager:\n\n{text}",
        "description": "Role-based prompt"
    }
]

# Test cases
test_cases = [
    {
        "id": "doc1",
        "inputs": {"text": "Long article about cloud computing..."},
        "expected": "Expected summary points..."
    },
    # ... more test cases
]

# Run comparison
from ai_evaluation_suite import PromptEvaluator

evaluator = PromptEvaluator()
results = evaluator.compare_variants(variants, test_cases)

# Print results
print("Prompt Comparison Results")
print("=" * 40)
for variant_id, metrics in results['summary'].items():
    print(f"{variant_id}: {metrics['mean_score']:.2f} (std: {metrics['std_score']:.3f})")

print(f"\nWinner: {results['winner']} ({results['improvement']:+.2f} improvement)")
```

## Example 3: RAG System Evaluation

Evaluate retrieval augmented generation pipeline.

```python
import numpy as np
from ai_evaluation_suite import RAGEvaluator

# Sample RAG data
rag_test = [
    {
        "query": "What is the capital of France?",
        "retrieved_docs": [
            "Paris is the capital of France",
            "France has many cities",
            "The Eiffel Tower is in Paris"
        ],
        "relevant_doc_ids": [0, 2],
        "generated_answer": "The capital of France is Paris.",
        "ground_truth": "Paris"
    },
    # ... more test cases
]

evaluator = RAGEvaluator()
results = []

for test in rag_test:
    metrics = evaluator.evaluate_pipeline(
        query=test["query"],
        retrieved_docs=test["retrieved_docs"],
        relevant_ids=test["relevant_doc_ids"],
        answer=test["generated_answer"]
    )
    results.append({
        "query": test["query"],
        "metrics": metrics
    })

# Summary statistics
retrieval_precisions = [r["metrics"].retrieval_precision for r in results]
faithfulness_scores = [r["metrics"].faithfulness for r in results]

print(f"Average Retrieval Precision: {np.mean(retrieval_precisions):.2f}")
print(f"Average Faithfulness: {np.mean(faithfulness_scores):.2f}")
```

## Example 4: Hallucination Detection in Production

Monitor for hallucinations in live outputs.

```python
from ai_evaluation_suite import HallucinationDetector

detector = HallucinationDetector()

# Monitor production outputs
production_logs = [
    {
        "context": "The Earth orbits the Sun in 365.25 days.",
        "generated": "The Earth takes 365.25 days to orbit the Sun.",
        "query": "How long is Earth's year?"
    },
    {
        "context": "Albert Einstein won the Nobel Prize in 1921.",
        "generated": "Einstein won the Nobel Prize in 1905 for relativity.",
        "query": "When did Einstein win the Nobel Prize?"
    }
]

hallucination_rate_total = 0
for item in production_logs:
    result = detector.detect(item["context"], item["generated"])
    hallucination_rate_total += result["hallucination_rate"]

    if result["hallucination_rate"] > 0.2:
        print(f"Alert: High hallucination in: {item['query']}")

avg_hallucination = hallucination_rate_total / len(production_logs)
print(f"Average Hallucination Rate: {avg_hallucination:.1%}")
```

## Example 5: Bias and Fairness Assessment

Evaluate gender and demographic bias.

```python
from ai_evaluation_suite import BiasEvaluator

evaluator = BiasEvaluator()

# Test demographic bias
prompt_template = "Describe a {gender} {profession}."

demographic_groups = {
    "gender": ["male", "female", "non-binary"],
    "profession": ["nurse", "engineer", "doctor"]
}

results = evaluator.evaluate_bias(
    prompt_template=prompt_template,
    demographic_groups=demographic_groups,
    num_samples=5
)

# Analyze bias
bias = results['bias_metrics']
print(f"Sentiment Disparity: {bias['sentiment_disparity']:.2f}")
print(f"Has Significant Bias: {bias['has_bias']}")

if bias['has_bias']:
    print("\nBias Analysis:")
    for group, sentiment in bias['sentiment_by_group'].items():
        print(f"  {group}: {sentiment:.2f}")
```

## Example 6: Cost Optimization Analysis

Compare model costs and identify savings.

```python
from ai_evaluation_suite import CostOptimizer

optimizer = CostOptimizer()

# Representative prompts from your workload
representative_prompts = [
    "Simple fact question",
    "Medium complexity task",
    "Complex reasoning task",
    # ... 97 more from your production traffic
]

# Analyze each model
models_to_compare = [
    "claude-3-5-sonnet-20241022",
    "claude-3-haiku-20240307"
]

results = {}
for model in models_to_compare:
    metrics = optimizer.analyze_usage(representative_prompts, model)
    results[model] = {
        "total_cost": metrics.total_cost,
        "tokens": metrics.total_tokens,
        "cost_per_request": metrics.total_cost / len(representative_prompts)
    }

# Calculate ROI
print("Cost Comparison (100 requests):")
print("=" * 40)
for model, data in results.items():
    print(f"{model}:")
    print(f"  Cost per request: ${data['cost_per_request']:.4f}")
    print(f"  Tokens per request: {data['tokens'] // len(representative_prompts)}")

# Project annual costs
annual_requests = 1_000_000
sonnet_annual = results["claude-3-5-sonnet-20241022"]["cost_per_request"] * annual_requests
haiku_annual = results["claude-3-haiku-20240307"]["cost_per_request"] * annual_requests

print(f"\nProjected Annual Cost (1M requests):")
print(f"  Sonnet: ${sonnet_annual:,.2f}")
print(f"  Haiku: ${haiku_annual:,.2f}")
print(f"  Potential Savings: ${sonnet_annual - haiku_annual:,.2f}")
```

## Example 7: Production Monitoring Dashboard

Continuous evaluation metrics tracking.

```python
import numpy as np
from datetime import datetime, timedelta
import json

class EvaluationMonitor:
    def __init__(self, metrics_file="evaluation_metrics.jsonl"):
        self.metrics_file = metrics_file

    def log_evaluation(self, query: str, response: str,
                      quality_score: float, latency: float,
                      cost: float):
        entry = {
            "timestamp": datetime.now().isoformat(),
            "query_length": len(query),
            "response_length": len(response),
            "quality_score": quality_score,
            "latency": latency,
            "cost": cost
        }

        with open(self.metrics_file, 'a') as f:
            f.write(json.dumps(entry) + '\n')

    def generate_dashboard(self, hours: int = 24):
        # Load recent metrics
        recent = []
        cutoff = datetime.now() - timedelta(hours=hours)

        with open(self.metrics_file) as f:
            for line in f:
                entry = json.loads(line)
                if datetime.fromisoformat(entry['timestamp']) > cutoff:
                    recent.append(entry)

        # Calculate metrics
        if recent:
            quality_scores = [e['quality_score'] for e in recent]
            latencies = [e['latency'] for e in recent]
            costs = [e['cost'] for e in recent]

            dashboard = f"""
Evaluation Dashboard (Last {hours} Hours)
==========================================

Quality Metrics:
  Average Quality: {np.mean(quality_scores):.2f}
  Min Quality: {np.min(quality_scores):.2f}
  Max Quality: {np.max(quality_scores):.2f}

Performance:
  Average Latency: {np.mean(latencies):.3f}s
  P95 Latency: {np.percentile(latencies, 95):.3f}s
  P99 Latency: {np.percentile(latencies, 99):.3f}s

Cost:
  Total Cost: ${sum(costs):.2f}
  Average Cost/Request: ${np.mean(costs):.4f}

Requests Processed: {len(recent)}
"""
            return dashboard

monitor = EvaluationMonitor()

# Log examples
monitor.log_evaluation(
    query="What is X?",
    response="X is...",
    quality_score=0.85,
    latency=1.23,
    cost=0.0012
)

# Generate report
print(monitor.generate_dashboard(hours=24))
```

## Example 8: Complete CI/CD Integration

Evaluation in GitHub Actions.

```yaml
# .github/workflows/ai-evaluation.yml
name: AI Evaluation

on:
  pull_request:
  schedule:
    - cron: '0 0 * * *'  # Daily

jobs:
  evaluate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install Dependencies
        run: pip install anthropic numpy pytest

      - name: Run Quality Evaluation
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          python -m pytest tests/test_quality.py \
            --quality-threshold 0.8 \
            --output results/quality.json

      - name: Check Metrics Thresholds
        run: |
          python scripts/check_thresholds.py \
            --quality-threshold 0.8 \
            --hallucination-threshold 0.05 \
            --latency-threshold 2.0

      - name: Generate Report
        if: always()
        run: |
          python scripts/generate_report.py \
            --results-dir results/ \
            --output evaluation_report.md

      - name: Upload Artifacts
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: evaluation-results
          path: results/

      - name: Comment on PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const report = fs.readFileSync('evaluation_report.md', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: report
            });
```

## Key Takeaways

1. **Automate evaluation** - Reduce manual effort, increase consistency
2. **Track metrics over time** - Catch regressions early
3. **Diverse test sets** - Cover edge cases and domains
4. **Multiple metrics** - No single metric captures quality
5. **Production monitoring** - Real-world performance differs from offline evaluation
6. **Document methodology** - Enable reproducibility and auditing
