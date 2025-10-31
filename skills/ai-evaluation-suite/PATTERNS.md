# AI Evaluation Patterns

Complete implementations of 8 essential evaluation patterns.

## Pattern 1: LLM Output Quality Evaluation

Multi-dimensional quality scoring using LLM-as-judge.

```python
from dataclasses import dataclass
import anthropic
import numpy as np
import json

@dataclass
class QualityMetrics:
    coherence: float
    relevance: float
    factuality: float
    completeness: float
    conciseness: float
    overall_score: float

class LLMQualityEvaluator:
    def __init__(self, model="claude-3-5-sonnet-20241022"):
        self.client = anthropic.Anthropic()
        self.model = model

    def evaluate(self, query: str, output: str,
                 context: str = None, ground_truth: str = None) -> QualityMetrics:
        eval_prompt = f"""Evaluate this output (0-10 scale):
<query>{query}</query>
<output>{output}</output>
{f'<context>{context}</context>' if context else ''}
{f'<ground_truth>{ground_truth}</ground_truth>' if ground_truth else ''}

Score: {{
  "coherence": X,
  "relevance": X,
  "factuality": X,
  "completeness": X,
  "conciseness": X
}}"""

        response = self.client.messages.create(
            model=self.model,
            max_tokens=256,
            messages=[{"role": "user", "content": eval_prompt}]
        )

        scores = json.loads(response.content[0].text)
        return QualityMetrics(
            coherence=scores["coherence"] / 10.0,
            relevance=scores["relevance"] / 10.0,
            factuality=scores["factuality"] / 10.0,
            completeness=scores["completeness"] / 10.0,
            conciseness=scores["conciseness"] / 10.0,
            overall_score=np.mean(list(scores.values())) / 10.0
        )

    def batch_evaluate(self, test_cases: list) -> dict:
        results = []
        for case in test_cases:
            metrics = self.evaluate(
                query=case["query"],
                output=case["output"],
                context=case.get("context"),
                ground_truth=case.get("ground_truth")
            )
            results.append({"case_id": case.get("id"), "metrics": metrics})

        avg = {
            "coherence": np.mean([r["metrics"].coherence for r in results]),
            "relevance": np.mean([r["metrics"].relevance for r in results]),
            "factuality": np.mean([r["metrics"].factuality for r in results]),
            "completeness": np.mean([r["metrics"].completeness for r in results]),
            "conciseness": np.mean([r["metrics"].conciseness for r in results]),
            "overall": np.mean([r["metrics"].overall_score for r in results])
        }
        return {"results": results, "summary": avg}
```

## Pattern 2: Prompt Engineering A/B Testing

Compare prompt variations on test dataset.

```python
import anthropic
from dataclasses import dataclass
from collections import defaultdict
import numpy as np

@dataclass
class PromptVariant:
    id: str
    template: str
    description: str

class PromptEvaluator:
    def __init__(self, model="claude-3-5-sonnet-20241022"):
        self.client = anthropic.Anthropic()
        self.model = model

    def compare_variants(self, variants: list, test_cases: list) -> dict:
        results = defaultdict(list)

        for variant in variants:
            for case in test_cases:
                prompt = variant.template.format(**case["inputs"])
                response = self.client.messages.create(
                    model=self.model,
                    max_tokens=1024,
                    messages=[{"role": "user", "content": prompt}]
                )

                score = self._score_output(response.content[0].text, case.get("expected"))
                results[variant.id].append({
                    "test_case": case["id"],
                    "output": response.content[0].text,
                    "score": score,
                    "tokens": response.usage.input_tokens + response.usage.output_tokens
                })

        summary = {}
        for variant_id, outputs in results.items():
            scores = [r["score"] for r in outputs]
            tokens = [r["tokens"] for r in outputs]
            summary[variant_id] = {
                "mean_score": np.mean(scores),
                "std_score": np.std(scores),
                "avg_tokens": np.mean(tokens)
            }

        winner = max(summary.items(), key=lambda x: x[1]["mean_score"])
        return {
            "results": dict(results),
            "summary": summary,
            "winner": winner[0],
            "improvement": winner[1]["mean_score"] - summary[variants[0].id]["mean_score"]
        }

    def _score_output(self, output: str, expected: str) -> float:
        import re
        # Simplified - implement your scoring logic
        return float(re.search(r'[\d.]+', "5.0").group()) if expected else 5.0
```

## Pattern 3: RAG System Evaluation

Evaluate retrieval + generation components.

```python
import anthropic
import numpy as np
from dataclasses import dataclass

@dataclass
class RAGMetrics:
    retrieval_precision: float
    retrieval_recall: float
    retrieval_mrr: float
    faithfulness: float
    answer_relevance: float
    overall_score: float

class RAGEvaluator:
    def __init__(self, model="claude-3-5-sonnet-20241022"):
        self.client = anthropic.Anthropic()
        self.model = model

    def evaluate_retrieval(self, retrieved: list, relevant_ids: list) -> dict:
        retrieved_set = set(range(len(retrieved)))
        relevant_set = set(relevant_ids)

        precision = len(retrieved_set & relevant_set) / len(retrieved_set) or 0
        recall = len(retrieved_set & relevant_set) / len(relevant_set) or 0
        mrr = 0
        for i in range(len(retrieved)):
            if i in relevant_ids:
                mrr = 1 / (i + 1)
                break

        return {
            "precision": precision,
            "recall": recall,
            "f1": 2 * (precision * recall) / (precision + recall) if (precision + recall) else 0,
            "mrr": mrr
        }

    def evaluate_faithfulness(self, context: str, answer: str) -> float:
        prompt = f"""Is answer grounded in context? (0-10)
Context: {context}
Answer: {answer}
Score:"""

        response = self.client.messages.create(
            model=self.model,
            max_tokens=10,
            messages=[{"role": "user", "content": prompt}]
        )

        import re
        match = re.search(r'\d+', response.content[0].text)
        return float(match.group()) / 10 if match else 0.5

    def evaluate_pipeline(self, query: str, retrieved_docs: list,
                         relevant_ids: list, answer: str) -> RAGMetrics:
        retrieval_metrics = self.evaluate_retrieval(retrieved_docs, relevant_ids)
        faithfulness = self.evaluate_faithfulness(' '.join(retrieved_docs), answer)

        overall = np.mean([
            retrieval_metrics["f1"],
            faithfulness,
            0.7  # Placeholder for answer relevance
        ])

        return RAGMetrics(
            retrieval_precision=retrieval_metrics["precision"],
            retrieval_recall=retrieval_metrics["recall"],
            retrieval_mrr=retrieval_metrics["mrr"],
            faithfulness=faithfulness,
            answer_relevance=0.7,
            overall_score=overall
        )
```

## Pattern 4: Hallucination Detection

Detect factual inconsistencies in outputs.

```python
class HallucinationDetector:
    def __init__(self, model="claude-3-5-sonnet-20241022"):
        self.client = anthropic.Anthropic()
        self.model = model

    def detect(self, context: str, generated: str) -> dict:
        # Method 1: Context comparison
        prompt = f"""What % of this text is supported by context? (0-100)
Context: {context}
Generated: {generated}
Percentage:"""

        response = self.client.messages.create(
            model=self.model,
            max_tokens=50,
            messages=[{"role": "user", "content": prompt}]
        )

        import re
        match = re.search(r'\d+', response.content[0].text)
        supported = float(match.group()) if match else 50

        # Method 2: Self-consistency
        consistency_prompt = f"""Rate internal consistency (0-10):
Text: {generated}
Score:"""

        consistency_response = self.client.messages.create(
            model=self.model,
            max_tokens=10,
            messages=[{"role": "user", "content": consistency_prompt}]
        )

        consistency_match = re.search(r'\d+', consistency_response.content[0].text)
        consistency = float(consistency_match.group()) / 10 if consistency_match else 0.5

        return {
            "hallucination_rate": 1 - (supported / 100),
            "supported_percentage": supported,
            "consistency_score": consistency
        }
```

## Pattern 5: Bias and Fairness Assessment

Evaluate demographic bias across groups.

```python
import anthropic
import numpy as np
from collections import defaultdict

class BiasEvaluator:
    def __init__(self, model="claude-3-5-sonnet-20241022"):
        self.client = anthropic.Anthropic()
        self.model = model

    def evaluate_bias(self, prompt_template: str,
                     demographic_groups: dict, num_samples: int = 3) -> dict:
        results = defaultdict(list)

        for category, values in demographic_groups.items():
            for value in values:
                for _ in range(num_samples):
                    prompt = prompt_template.format(**{category: value})
                    response = self.client.messages.create(
                        model=self.model,
                        max_tokens=256,
                        messages=[{"role": "user", "content": prompt}]
                    )

                    sentiment = self._analyze_sentiment(response.content[0].text)
                    results[f"{category}:{value}"].append({
                        "output": response.content[0].text,
                        "sentiment": sentiment,
                        "length": len(response.content[0].text)
                    })

        bias_metrics = self._calculate_disparity(results)
        return {"detailed_results": dict(results), "bias_metrics": bias_metrics}

    def _analyze_sentiment(self, text: str) -> float:
        prompt = f"""Rate sentiment (-10 to 10):
Text: {text}
Score:"""

        response = self.client.messages.create(
            model=self.model,
            max_tokens=50,
            messages=[{"role": "user", "content": prompt}]
        )

        import re
        match = re.search(r'-?\d+', response.content[0].text)
        return float(match.group()) / 10 if match else 0.0

    def _calculate_disparity(self, results: dict) -> dict:
        sentiments = {}
        for group, outputs in results.items():
            sentiments[group] = np.mean([o["sentiment"] for o in outputs])

        sentiment_range = max(sentiments.values()) - min(sentiments.values())
        return {
            "sentiment_by_group": sentiments,
            "sentiment_disparity": sentiment_range,
            "has_bias": sentiment_range > 0.3
        }
```

## Pattern 6: Cost and Token Optimization

Track and optimize token usage.

```python
@dataclass
class CostMetrics:
    total_tokens: int
    input_tokens: int
    output_tokens: int
    total_cost: float

class CostOptimizer:
    PRICING = {
        "claude-3-5-sonnet-20241022": {"input": 3.0, "output": 15.0},
        "claude-3-haiku-20240307": {"input": 0.25, "output": 1.25}
    }

    def __init__(self):
        self.client = anthropic.Anthropic()

    def analyze_usage(self, prompts: list, model: str) -> CostMetrics:
        total_input = 0
        total_output = 0

        for prompt in prompts:
            response = self.client.messages.create(
                model=model,
                max_tokens=1024,
                messages=[{"role": "user", "content": prompt}]
            )
            total_input += response.usage.input_tokens
            total_output += response.usage.output_tokens

        pricing = self.PRICING.get(model)
        cost = ((total_input / 1_000_000) * pricing["input"] +
               (total_output / 1_000_000) * pricing["output"])

        return CostMetrics(
            total_tokens=total_input + total_output,
            input_tokens=total_input,
            output_tokens=total_output,
            total_cost=cost
        )

    def compare_models(self, prompt: str, models: list) -> dict:
        results = {}
        for model in models:
            response = self.client.messages.create(
                model=model,
                max_tokens=1024,
                messages=[{"role": "user", "content": prompt}]
            )

            pricing = self.PRICING.get(model)
            cost = ((response.usage.input_tokens / 1_000_000) * pricing["input"] +
                   (response.usage.output_tokens / 1_000_000) * pricing["output"])

            results[model] = {
                "tokens": response.usage.input_tokens + response.usage.output_tokens,
                "cost": cost,
                "cost_per_1k_tokens": (cost / (response.usage.input_tokens + response.usage.output_tokens)) * 1000
            }

        return results
```

## Pattern 7: Performance and Latency Evaluation

Measure response times and throughput.

```python
import anthropic
import numpy as np
import time
from dataclasses import dataclass

@dataclass
class PerformanceMetrics:
    mean_latency: float
    p50_latency: float
    p95_latency: float
    p99_latency: float
    throughput: float
    error_rate: float

class PerformanceEvaluator:
    def __init__(self, model="claude-3-5-sonnet-20241022"):
        self.client = anthropic.Anthropic()
        self.model = model

    def measure_latency(self, prompts: list) -> PerformanceMetrics:
        latencies = []
        errors = 0
        start_time = time.time()

        for prompt in prompts:
            try:
                req_start = time.time()
                response = self.client.messages.create(
                    model=self.model,
                    max_tokens=256,
                    messages=[{"role": "user", "content": prompt}]
                )
                latencies.append(time.time() - req_start)
            except Exception:
                errors += 1

        total_time = time.time() - start_time
        latencies_sorted = sorted(latencies)
        n = len(latencies)

        return PerformanceMetrics(
            mean_latency=np.mean(latencies) if latencies else 0,
            p50_latency=latencies_sorted[n // 2] if latencies else 0,
            p95_latency=latencies_sorted[int(n * 0.95)] if latencies else 0,
            p99_latency=latencies_sorted[int(n * 0.99)] if latencies else 0,
            throughput=len(prompts) / total_time,
            error_rate=errors / len(prompts)
        )
```

## Pattern 8: Benchmark Evaluation

Run standard benchmarks.

```python
class BenchmarkEvaluator:
    def __init__(self, model="claude-3-5-sonnet-20241022"):
        self.client = anthropic.Anthropic()
        self.model = model

    def run_mmlu(self, questions: list) -> dict:
        correct = 0
        for q in questions:
            prompt = f"""Question: {q['question']}
A) {q['choices'][0]}
B) {q['choices'][1]}
C) {q['choices'][2]}
D) {q['choices'][3]}
Answer:"""

            response = self.client.messages.create(
                model=self.model,
                max_tokens=10,
                messages=[{"role": "user", "content": prompt}]
            )

            predicted = response.content[0].text.strip()[0].upper()
            if predicted == q['answer']:
                correct += 1

        return {
            "accuracy": correct / len(questions),
            "total": len(questions),
            "correct": correct
        }

    def run_humaneval(self, problems: list) -> dict:
        passed = 0
        for problem in problems:
            prompt = f"Complete this function:\n\n{problem['prompt']}"

            response = self.client.messages.create(
                model=self.model,
                max_tokens=1024,
                messages=[{"role": "user", "content": prompt}]
            )

            # Simplified - use actual test execution in production
            if self._test_code(response.content[0].text, problem.get('test')):
                passed += 1

        return {
            "pass_rate": passed / len(problems),
            "total": len(problems),
            "passed": passed
        }

    # CRITICAL SECURITY WARNING:
    # exec() runs untrusted LLM-generated code with full system access.
    # NEVER use in production without proper sandboxing.
    #
    # Recommended sandboxing approaches:
    # 1. Docker container with no network, limited resources
    # 2. gVisor/Firecracker for kernel-level isolation
    # 3. Use RestrictedPython library for safer evaluation
    # 4. Run in separate process with timeout and resource limits
    #
    # Example Docker sandbox:
    # docker run --rm --network=none --memory=256m --cpus=0.5 \
    #   -v /tmp/code:/code:ro python:3.11 python /code/script.py
    #
    # For demonstration only - DO NOT use in production:
    def _test_code(self, code: str, test: str) -> bool:
        try:
            namespace = {}
            exec(code, namespace)  # UNSAFE: Executes untrusted LLM code
            exec(test, namespace)  # UNSAFE: Executes untrusted test code
            return True
        except:
            return False
```

## Usage Examples

### Quality Evaluation
```python
evaluator = LLMQualityEvaluator()
metrics = evaluator.evaluate(
    query="Explain machine learning",
    output="Machine learning is...",
    ground_truth="ML is a field where..."
)
```

### Prompt Comparison
```python
evaluator = PromptEvaluator()
results = evaluator.compare_variants(
    variants=[variant1, variant2, variant3],
    test_cases=test_set
)
print(f"Best: {results['winner']}")
```

### RAG Evaluation
```python
rag = RAGEvaluator()
metrics = rag.evaluate_pipeline(
    query="What is X?",
    retrieved_docs=docs,
    relevant_ids=[0, 2],
    answer="X is..."
)
```

### Performance Testing
```python
perf = PerformanceEvaluator()
metrics = perf.measure_latency(prompts)
print(f"P95 Latency: {metrics.p95_latency:.3f}s")
```

Each pattern is self-contained and can be adapted to your specific needs.
