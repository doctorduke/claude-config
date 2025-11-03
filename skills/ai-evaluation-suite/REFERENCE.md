# AI Evaluation Metrics Reference

Complete reference for evaluation metrics across categories.

## Text Generation Metrics

### BLEU (Bilingual Evaluation Understudy)

**Range**: 0-1 (often expressed 0-100)
**Type**: Reference-based (needs ground truth)
**Calculation**: N-gram precision with brevity penalty

```
BLEU = BP * exp(sum(ln(pn)) / N)
  BP = exp(1 - r/c) if c < r else 1
  pn = modified precision for n-gram
  r = reference length, c = candidate length
```

**Pros**:
- Quick to compute
- Consistent across languages
- Widely used (standardized)

**Cons**:
- Doesn't handle synonyms
- Penalizes valid paraphrases
- Sentence-level scores unreliable

**When to Use**: Machine translation, code generation

**Typical Ranges**:
- 0.00-0.10: Unintelligible
- 0.10-0.30: Poor
- 0.30-0.50: Fair
- 0.50-0.70: Good
- 0.70+: Excellent

### ROUGE (Recall-Oriented Understudy for Gisting Evaluation)

**Range**: 0-1
**Type**: Reference-based (needs ground truth)
**Variants**: ROUGE-1, ROUGE-2, ROUGE-L

**ROUGE-1**: Unigram (single word) overlap

```
ROUGE-1 = (sum(min(count_pred(g), count_ref(g)))) / (sum(count_ref(g)))
  count_pred(g) = count of gram g in prediction
  count_ref(g) = count of gram g in reference
```

**ROUGE-2**: Bigram (two-word phrase) overlap
**ROUGE-L**: Longest common subsequence (LCS)

**Pros**:
- Better for summarization than BLEU
- Captures semantic similarity better
- Multiple variants for different tasks

**Cons**:
- Still doesn't handle true semantics
- Prefers extractive answers
- Reference quality dependent

**When to Use**: Summarization, question answering

**Typical Ranges**:
- ROUGE-1: 0.30-0.60 for good summarization
- ROUGE-2: 0.10-0.30 for good summarization
- ROUGE-L: 0.30-0.60 for good summarization

### BERTScore

**Range**: 0-1
**Type**: Reference-based with semantic understanding
**Calculation**: Cosine similarity of contextual embeddings

```
Precision = (1/|pred|) * sum(max_ref(cos_sim(pred_i, ref_j)))
Recall = (1/|ref|) * sum(max_pred(cos_sim(ref_j, pred_i)))
F1 = 2 * (Precision * Recall) / (Precision + Recall)
```

**Pros**:
- Handles paraphrases and synonyms
- Better correlation with human judgment
- Semantic understanding

**Cons**:
- Slower than BLEU/ROUGE
- Requires large language model
- Model-dependent results

**When to Use**: Summarization, paraphrase detection, semantic evaluation

**Typical Ranges**:
- 0.50-0.70: Reasonable quality
- 0.70-0.85: Good quality
- 0.85+: Excellent quality

### METEOR (Metric for Evaluation of Translation with Explicit Ordering)

**Range**: 0-1
**Type**: Reference-based
**Features**: Handles synonyms, paraphrases, stemming

```
METEOR = (1 - penalty) * (Precision * Recall) / (α*Precision + (1-α)*Recall)
  penalty = (num_chunks-1) / (2*num_matched_words)
```

**When to Use**: Machine translation, general text generation

**Typical Ranges**:
- 0.40-0.60: Acceptable translation
- 0.60-0.80: Good translation
- 0.80+: Excellent translation

### Perplexity

**Range**: > 0 (lower is better)
**Type**: Reference-free
**Calculation**: Cross-entropy on test set

```
Perplexity = exp(-1/N * sum(log(P(word_i))))
  P(word_i) = probability model assigns to word
  N = number of words
```

**Pros**:
- Simple to compute
- No reference needed
- Language model confidence

**Cons**:
- Doesn't measure correctness
- Task-dependent interpretation
- Can't distinguish quality vs fluency

**When to Use**: Language model evaluation, baseline comparison

**Typical Ranges**:
- < 50: Excellent fluency
- 50-100: Good fluency
- 100-200: Acceptable
- > 200: Poor fluency

### MAUVE (Measure of the Gap Between Universes)

**Range**: 0-1
**Type**: Reference-free
**Calculation**: Distribution similarity via likelihood ratio

**When to Use**: Open-ended generation, diversity assessment

### ChrF (Character n-gram F-score)

**Range**: 0-1
**Type**: Reference-based
**Calculation**: F1 of character n-grams

**Pros**:
- Works across languages
- Robust to morphological variations

**When to Use**: Low-resource language translation, multilingual systems

## Ranking Metrics

### Precision@k

**Definition**: Fraction of top-k retrieved items that are relevant

```
Precision@k = (number of relevant items in top k) / k
```

**Range**: 0-1
**When to Use**: Information retrieval, ranking evaluation

**Typical Ranges**:
- < 0.5: Poor ranking
- 0.5-0.7: Acceptable
- 0.7-0.9: Good
- 0.9+: Excellent

### Recall@k

**Definition**: Fraction of all relevant items found in top-k

```
Recall@k = (number of relevant items in top k) / (total relevant items)
```

**Range**: 0-1
**When to Use**: Information retrieval, completeness assessment

### F1 Score

**Definition**: Harmonic mean of precision and recall

```
F1 = 2 * (Precision * Recall) / (Precision + Recall)
```

**Range**: 0-1
**When to Use**: Binary classification, when you care about both false positives and false negatives

### MRR (Mean Reciprocal Rank)

**Definition**: Average of inverse rank of first relevant item

```
MRR = (1/Q) * sum(1/rank_i) for first relevant item
```

**Range**: 0-1
**When to Use**: Search quality, top-1 accuracy

**Interpretation**:
- 1.0: Always first
- 0.5: Relevant item at rank 2 on average
- 0.33: Relevant item at rank 3 on average

### NDCG (Normalized Discounted Cumulative Gain)

**Definition**: DCG normalized by ideal ranking

```
DCG = rel_1 + sum(rel_i / log2(i+1))
NDCG = DCG / IDCG
```

**Range**: 0-1
**When to Use**: Ranked recommendation, relevance gradations

**NDCG@k**: Only consider top-k items

## LLM-as-Judge Patterns

### G-Eval Framework

**Approach**: LLM evaluation with chain-of-thought

**Format**:
1. Generate evaluation steps
2. Score based on steps
3. Provide confidence

**Prompt Structure**:
```
You will be given a task and outputs. Evaluate step-by-step:

Task: [task]
Output: [output]

Step 1: [self-generated evaluation criterion]
Step 2: [self-generated evaluation criterion]
Step 3: [self-generated evaluation criterion]

Score (1-5): [score]
Confidence: [high/medium/low]
```

**Pros**:
- Better human correlation
- Transparent reasoning
- Customizable criteria

**Cons**:
- More expensive (longer responses)
- Judge model bias
- Requires careful prompt design

### Prometheus Pattern

**Approach**: Open-source fine-tuned evaluator

**Model**: Weights & Biases trained LLM

**Benefits**:
- Reproducible evaluations
- No external API dependency
- Customizable training

**Usage**:
```python
evaluator = Prometheus(model="prometheus-7b-v2.0")
score = evaluator.score(
    instruction="Summarize this",
    output=model_output,
    rubric="Factuality: 0-3 scale"
)
```

### AlpacaEval Pattern

**Approach**: Instruction-following evaluation

**Metric**: Win rate vs reference model

**Calculation**:
```
Win Rate = (number of wins) / (number of comparisons)
```

**When to Use**: Chatbot comparison, instruction-following

## Classification Metrics

### Accuracy

**Definition**: Fraction of correct predictions

```
Accuracy = (True Positives + True Negatives) / Total
```

**Range**: 0-1
**Limitation**: Biased by class imbalance

### Precision (for binary classification)

**Definition**: Fraction of positive predictions that are correct

```
Precision = True Positives / (True Positives + False Positives)
```

**Interpretation**: Of items we marked positive, how many were right?

### Recall (for binary classification)

**Definition**: Fraction of actual positives we found

```
Recall = True Positives / (True Positives + False Negatives)
```

**Interpretation**: Of actual positive items, how many did we find?

### Macro vs Micro Averaging

**Macro F1**: Average F1 across all classes (equal weight)

```
Macro F1 = (1/num_classes) * sum(F1_i)
```

**Micro F1**: Global TP, FP, FN across all classes

```
Micro F1 = 2 * (precision_global * recall_global) / (precision_global + recall_global)
```

**When to Use Macro**: Balanced classes, care about minority class
**When to Use Micro**: Imbalanced classes, overall performance

## Code Generation Metrics

### Pass@k

**Definition**: Probability that at least one of k generated solutions passes tests

```
Pass@k = 1 - (C(n-c, k) / C(n, k))
  n = total problems
  c = correct solutions
  C = binomial coefficient
```

**Range**: 0-1
**When to Use**: Code generation evaluation (HumanEval, MBPP)

**Typical Ranges**:
- Pass@1: 0.1-0.5 (single generation)
- Pass@10: 0.3-0.7 (diverse sampling)
- Pass@100: 0.5-0.9 (Monte Carlo sampling)

**Important Notes**:
- Requires proper test case execution
- Language-specific runtime needed
- Timeout handling critical

## Semantic Similarity Metrics

### Cosine Similarity

**Definition**: Cosine of angle between embedding vectors

```
cos(A, B) = (A · B) / (||A|| * ||B||)
```

**Range**: -1 to 1 (often 0-1 for embeddings)
**When to Use**: Semantic similarity, clustering

### Levenshtein Distance

**Definition**: Minimum edits (insert, delete, replace) to transform string

```
Range: 0 to max(len(s1), len(s2))
Normalized: 1 - (distance / max_length)
```

**When to Use**: String similarity, typo detection

## Diversity Metrics

### Self-BLEU

**Definition**: BLEU score of output against itself (diversity measure)

**Calculation**: Generate multiple outputs, compute BLEU between them

**Interpretation**: Lower self-BLEU = higher diversity

### Distinct-n

**Definition**: Ratio of unique n-grams

```
Distinct-n = (count unique n-grams) / (total n-grams)
```

**Range**: 0-1
**When to Use**: Generative model diversity

## Benchmark-Specific Metrics

### Exact Match (EM)

**Definition**: Prediction exactly matches reference

```
EM = (number of exact matches) / (total examples)
```

**Range**: 0-1
**When to Use**: QA, semantic parsing where precision is critical

### Overlap F1

**Definition**: Token-level F1 between prediction and reference

**Calculation**:
1. Split both into tokens
2. Calculate precision and recall
3. Compute F1

**When to Use**: QA evaluation with fuzzy matching

## Latency Metrics

### Percentile Latencies

- **P50 (Median)**: 50th percentile latency
- **P95**: 95th percentile latency (most requests faster)
- **P99**: 99th percentile latency (tail latency)

**When to Use**: Service level agreements, performance monitoring

### Throughput

**Definition**: Requests processed per unit time

```
Throughput = Total Requests / Total Time (in seconds)
```

**Unit**: requests/second (RPS)

**When to Use**: Scalability assessment, load testing

## Cost Metrics

### Cost per Request

**Definition**: Total cost divided by requests processed

```
Cost per Request = Total Cost / Number of Requests
```

**When to Use**: Budget tracking, model comparison

### Cost per Token

**Definition**: Cost divided by tokens consumed

```
Cost per Token = Total Cost / (Input Tokens + Output Tokens)
```

**When to Use**: Fine-grained cost analysis, prompt optimization

### Cost-Quality Curve

Plot: X-axis = Quality score, Y-axis = Cost per request

**Interpretation**: Identify sweet spots where quality-to-cost ratio is best

## Fairness Metrics

### Demographic Parity

**Definition**: Equal selection rates across demographic groups

```
Parity = P(positive | group_A) - P(positive | group_B)
```

**Interpretation**: Zero means equal treatment

### Equal Opportunity Difference

**Definition**: Equal true positive rates across groups

```
EOD = TPR_A - TPR_B
```

**Interpretation**: Zero means equal performance on positives

### Calibration

**Definition**: Predicted probability matches actual probability

```
Calibration: P(positive | score=0.7) ≈ 0.7
```

## Summary: Metrics by Use Case

| Use Case | Metric | Alternative |
|----------|--------|-------------|
| Translation | BLEU | METEOR, ChrF |
| Summarization | ROUGE-1/2/L | BERTScore |
| General Generation | BLEU, Perplexity | BERTScore, MAUVE |
| Code Generation | Pass@k | Execution accuracy |
| QA | EM, F1 | BLEU, ROUGE-L |
| Information Retrieval | Precision@k, NDCG@k | MRR, Recall@k |
| Classification | Accuracy, F1 | Precision, Recall |
| Semantic Similarity | Cosine similarity | BERTScore |
| Diversity | Distinct-n | Self-BLEU |
| Fairness | Demographic Parity | Equal Opportunity Difference |
| Cost Analysis | Cost/Request | Cost/Token |
| Performance | P95 Latency | P99, Throughput |

