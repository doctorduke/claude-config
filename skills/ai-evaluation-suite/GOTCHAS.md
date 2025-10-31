# AI Evaluation Gotchas & Edge Cases

## Common Pitfalls

### 1. Benchmark Overfitting

**Problem**: High benchmark scores don't guarantee production readiness

Models achieve high MMLU scores (90%+) but fail on simple real-world tasks. This happens because:
- Models may have seen test data during training (data contamination)
- Benchmarks don't reflect actual use case distribution
- Task distribution differs from training data
- Multiple-choice format is easier than open-ended tasks

**Solution**:
- Use diverse evaluation sets including task-specific datasets
- Create private held-out evaluation sets
- Test on data from different time periods
- Compare against human baselines
- Evaluate on multiple benchmarks, not just one

**Example**: A model scores 85% on HumanEval but only passes 40% of real-world code requirements because HumanEval problems are simpler.

### 2. Metric-Human Judgment Mismatch

**Problem**: BLEU and ROUGE don't correlate with human judgment for creative tasks

Reference-based metrics (BLEU, ROUGE) measure n-gram overlap but don't capture:
- Semantic equivalence
- Paraphrases
- Multiple valid outputs
- Stylistic variations
- Creative or novel phrasings

A high BLEU score doesn't mean humans will rate output as good.

**Solution**:
- Combine reference-based metrics with reference-free metrics
- Use LLM-as-judge for semantic evaluation
- Incorporate human evaluation, at least sampled
- Validate metric correlation with human ratings on your specific task
- Use task-specific metrics when available

**Example**: Translation with score 0.35 BLEU but 4.8/5 human rating because output was more fluent despite lower n-gram overlap.

### 3. Evaluation Contamination

**Problem**: Test data leaks into training sets

Models achieve unrealistically high benchmarks when:
- Benchmark data was in the training corpus
- Similar patterns/questions appear in training data
- Data collection overlaps with model pretraining sources
- Benchmark was published before model training started

**Solution**:
- Check for data contamination (string matching, semantic similarity)
- Use benchmarks published after model training starts
- Create private evaluation sets for sensitive applications
- Use version-controlled, timestamped evaluation data
- Compare model performance on known contaminated vs clean subsets

**Example**: Model achieves 95% on MMLU but only 60% on TruthfulQA (newer benchmark).

### 4. Hallucination Blindness

**Problem**: LLMs are confident when wrong; hard to detect without ground truth

LLMs will confidently state incorrect facts because:
- They optimize for fluency, not accuracy
- Lack access to current information
- Misunderstand context or instructions
- Can't distinguish between learned patterns and facts

**Solution**:
- Implement fact-checking against knowledge bases
- Require source attribution and citations
- Use consistency checks (same question, different phrasings)
- Implement claim verification workflow
- Use RAG with trusted sources
- Monitor for common hallucination patterns

**Example**: Model states "Einstein won the 2023 Nobel Prize" confidently with no uncertainty signal.

### 5. Prompt Sensitivity

**Problem**: Small prompt changes cause large output variance

Same semantic intent with different wording produces wildly different outputs:
- Temperature settings affect variance
- Chain-of-thought formatting changes reasoning
- Instruction reordering changes priority
- Example formatting impacts few-shot learning

**Solution**:
- Test prompt variations systematically
- Use temperature=0 for consistency in evaluation
- A/B test prompt variations on representative samples
- Average results across multiple runs
- Use ensemble methods with diverse prompts
- Document final prompt versions with evaluation results

**Example**: "Summarize:" vs "Please provide a concise summary of:" produces 20%+ quality difference.

### 6. Context Window Limitations

**Problem**: Long context degrades performance ("lost in the middle")

Models struggle with:
- Very long contexts (accuracy drops at end)
- Relevant information in middle of context
- Too much irrelevant information
- Context token limits

**Solution**:
- Test evaluation at various context lengths
- Use retrieval to place most relevant chunks first/end
- Implement sliding window evaluation
- Monitor performance degradation with context length
- Consider multi-document reasoning requirements

**Example**: Model achieves 85% accuracy with 2K context, 65% with 8K context on same task.

### 7. Cost vs Quality Tradeoff

**Problem**: Best model is often too expensive for production

Tradeoff challenges:
- Claude 3.5 Sonnet costs 10x more than Haiku
- Quality vs cost curve is non-linear
- Smaller models may be good enough
- Fine-tuning smaller models often beats large models

**Solution**:
- Build cost/quality curves (quality vs cost per request)
- Use model routing (different models for different queries)
- Fine-tune smaller models on your specific task
- Implement fallback chains (try Haiku, fall back to Sonnet)
- Track actual production costs alongside quality metrics

**Example**: Sonnet achieves 90% accuracy at $0.02/request; Haiku achieves 85% at $0.0005/request. Haiku might be better ROI.

### 8. Async and Streaming Evaluation Issues

**Problem**: Hard to evaluate streaming/real-time systems

Challenges:
- Evaluation metrics designed for complete outputs
- Streaming outputs change over time
- Latency is part of quality
- Partial outputs are hard to judge

**Solution**:
- Capture complete interaction including streaming
- Evaluate using end-to-end metrics
- Log all intermediate outputs
- Measure time-to-first-token, streaming latency
- Implement checkpoint-based evaluation (evaluate at token positions)

**Example**: Streaming model produces gibberish first tokens then corrects itself; single-point evaluation misses this.

### 9. Human Evaluation Disagreement

**Problem**: Annotators disagree on subjective evaluation

Agreement challenges:
- Subjective tasks have inherent disagreement
- Annotators have different thresholds
- Context/background knowledge differs
- Instructions are ambiguous

**Solution**:
- Use multiple annotators per example
- Calculate inter-annotator agreement (Kappa, Fleiss' Kappa)
- Define clear rubrics with examples
- Train annotators on guidelines
- Use majority voting or averaged scores
- Track disagreement as metric of task difficulty

**Example**: Human raters give same output 5/5, 3/5, 4/5, 4/5 ratings; consensus is difficult.

### 10. Distribution Shift

**Problem**: Production queries differ from evaluation datasets

Real-world distribution is hard to predict:
- Seasonal patterns in queries
- User base changes over time
- Business requirements evolve
- New query types emerge

**Solution**:
- Continuously evaluate on production data
- Implement distribution monitoring
- Regular evaluation dataset updates
- A/B test new model versions
- Track performance by query type/demographics
- Monitor for drift

**Example**: Model evaluated on news articles but deployed for legal document analysis; performance drops 40%.

## Metric-Specific Gotchas

### BLEU Score Issues

1. **Doesn't handle synonyms** - "car" vs "vehicle" treated as different
2. **Ignores word order** - Only measures n-gram overlap
3. **Penalizes paraphrases** - Valid alternatives score lower
4. **Sentence length bias** - Longer references score higher

### ROUGE Score Issues

1. **Memorization advantage** - Extractive answers score high even if non-informative
2. **Not task-independent** - ROUGE-1 vs ROUGE-L affect rankings differently
3. **Reference dependency** - Quality depends on reference quality
4. **Limited semantic understanding** - Doesn't measure actual informativeness

### Perplexity Issues

1. **Doesn't measure correctness** - Low perplexity doesn't mean good quality
2. **Task-dependent** - Perplexity thresholds vary by task
3. **Doesn't capture diversity** - Same average perplexity, different output distributions

### F1 Score Issues

1. **Assumes error symmetry** - Treats false positives and negatives equally
2. **Task-dependent thresholds** - No universal "good" F1 score
3. **Biased by class imbalance** - Macro vs micro averaging differences
4. **Binary focus** - Multi-class F1 computation ambiguous

## LLM-as-Judge Gotchas

### Judge Model Bias

1. **Own model bias** - Judge models have their own biases
2. **Format bias** - Judge favors outputs matching its style
3. **Length bias** - Longer outputs often scored higher
4. **Language bias** - Non-English outputs sometimes scored lower

### Reproducibility Issues

1. **Temperature affects results** - Different runs give different scores
2. **Model version matters** - GPT-4 vs Claude 3.5 Sonnet score differently
3. **Prompt engineering** - Judge prompt design heavily impacts scores
4. **Cost of calibration** - Need human evaluation to validate judge

### Scalability Tradeoffs

1. **Cost** - LLM-as-judge calls expensive at scale
2. **Latency** - Evaluation bottleneck for real-time systems
3. **Consistency** - Harder to compare across many items

## Task-Specific Pitfalls

### Code Generation

1. **Pass@k is incomplete** - Doesn't measure code quality (readability, efficiency)
2. **Test quality** - Bad tests pass bad code
3. **Environment-specific** - Code that works in one context fails in another
4. **Timeout vs failure** - Distinction matters for evaluation

### Summarization

1. **Abstractive vs extractive** - Different evaluation needs
2. **Summary length** - Optimal length task-dependent
3. **Hallucination in summary** - Possible without reference documents
4. **Coherence** - Metrics don't measure logical flow

### Question Answering

1. **Exact match bias** - Multiple valid answers possible
2. **Partial credit** - Answer partially correct still marked wrong
3. **Context dependency** - Same answer wrong in different contexts
4. **Ambiguous questions** - Multiple valid interpretations

### RAG Systems

1. **Component evaluation** - Retrieval and generation interdependent
2. **Retrieval relevance** - Hard to define "relevant" document
3. **Answer grounding** - Measure faithfulness vs correctness
4. **Context window effects** - Different when context is limiting factor

## Solution Summary

For each gotcha, follow this pattern:

1. **Identify** - Know which gotcha applies to your task
2. **Measure** - Track the gotcha (e.g., inter-annotator agreement)
3. **Mitigate** - Implement countermeasures
4. **Monitor** - Watch for gotcha signals in production
5. **Document** - Record methodology and known limitations
