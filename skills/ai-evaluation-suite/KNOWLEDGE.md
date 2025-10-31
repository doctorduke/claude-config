# AI Evaluation Knowledge Base

## Table of Contents

1. Evaluation Theory and Frameworks
2. Benchmark Descriptions
3. LLM-as-Judge Resources
4. Bias and Fairness Frameworks
5. Tools and Libraries
6. Production Monitoring Platforms
7. Key Research Papers

## Evaluation Theory and Frameworks

### HELM (Holistic Evaluation of Language Models)

Comprehensive framework by Stanford CRFM covering:
- Language capabilities (classification, QA, generation)
- Fairness and bias assessment
- Robustness to perturbations
- Structured scenarios and adversarial examples
- Multi-dimensional metrics

Website: https://crfm.stanford.edu/helm/

### LangSmith - LangChain's Evaluation Platform

Production evaluation and monitoring for LLM applications:
- Real-time tracing and debugging
- Evaluation datasets and scenarios
- Metrics tracking and comparison
- Multi-run experiments
- Human feedback integration

Website: https://docs.smith.langchain.com/

### Ragas - RAG Evaluation Framework

Specialized for Retrieval-Augmented Generation:
- Context relevance evaluation
- Answer faithfulness assessment
- Retrieval precision/recall
- Question answering evaluation
- Can use LLM-as-judge or reference-based metrics

Website: https://docs.ragas.io/

### OpenAI Evals

Framework for evaluating LLM-based systems:
- Built-in evaluation datasets
- Extensible eval templates
- Comparison across models
- Reproducible evaluation
- Leaderboard generation

Website: https://github.com/openai/evals

## Benchmark Descriptions

### MMLU (Massive Multitask Language Understanding)

**Size**: 15,908 multiple-choice questions across 57 subjects
**Subjects**: Mathematics, history, law, medicine, biology, chemistry, physics, etc.
**Format**: 4-choice multiple choice with A/B/C/D answers
**Difficulty**: Spans elementary to college/professional level
**Key Metric**: Accuracy (% correct answers)
**Challenge**: Models may have seen MMLU test data during training

Use for: General knowledge assessment, model comparison, benchmarking
Paper: https://arxiv.org/abs/2009.03300

### HumanEval (Human-Level Code Generation)

**Size**: 164 programming problems
**Languages**: Primarily Python, extensible
**Format**: Function completion task
**Key Metric**: Pass@k (k=1,10,100) - does generated code pass test cases
**Difficulty**: Easy to medium level programming
**Challenge**: Models may have seen similar code in training

Use for: Code generation evaluation, model capability assessment
Website: https://github.com/openai/human-eval

### MBPP (Mostly Basic Python Problems)

**Size**: 1,000 Python programming problems
**Difficulty**: Basic level (simpler than HumanEval)
**Format**: Function completion with test cases
**Key Metric**: Pass@k
**Dataset**: Curated from existing programming problem sites

Use for: Baseline code generation evaluation, teaching model assessment
Website: https://github.com/google-research/google-research/tree/master/mbpp

### TruthfulQA (Truthfulness and Informativeness)

**Size**: 817 questions designed to elicit falsehoods
**Format**: Open-ended questions testing:
- Factual accuracy
- Resistance to common misconceptions
- Handling of ambiguous questions
**Key Metrics**: GPT-judge score, human evaluation
**Challenge**: Requires understanding of truthfulness vs. informativeness

Use for: Assessing hallucination tendency, factuality evaluation
Website: https://github.com/sylinrl/TruthfulQA

### BBH (BIG-Bench Hard)

**Size**: 23 reasoning tasks, 4,000+ examples
**Focus**: Complex reasoning tasks (not covered by MMLU)
**Tasks**: Logical reasoning, mathematical reasoning, algorithmic tasks
**Key Metric**: Accuracy
**Difficulty**: Hard reasoning problems

Use for: Assessing advanced reasoning capabilities
Website: https://github.com/suzgunmirac/BIG-Bench-Hard

### GSM8K (Grade School Math)

**Size**: 8,500 grade school math problems
**Format**: Word problems with numeric answers
**Solution Paths**: Average 5 steps per problem
**Key Metric**: Accuracy (exact match on numeric answer)
**Difficulty**: Elementary to middle school level

Use for: Math reasoning evaluation, step-by-step reasoning assessment
Website: https://github.com/openai/grade-school-math

### HellaSwag (Commonsense Reasoning)

**Size**: 70,000 video-based scenarios
**Format**: Complete activity description given video context
**Tasks**: Predict next event in video clip
**Key Metric**: Accuracy
**Difficulty**: Hard for supervised models, easy for humans

Use for: Commonsense reasoning evaluation, video understanding
Website: https://rowanzellers.com/hellaswag/

### BEIR (Benchmark for Information Retrieval)

**Size**: 15 diverse IR datasets, 1M+ documents
**Format**: Information retrieval tasks (search, ranking)
**Key Metrics**: NDCG, MRR, Precision@k, Recall@k
**Datasets**: MS MARCO, Natural Questions, TriviaQA, etc.

Use for: Retrieval system evaluation, RAG component testing
Website: https://github.com/beir-cellar/beir

## LLM-as-Judge Resources

### G-Eval Framework

**Approach**: LLM evaluation with chain-of-thought
**Features**:
- Generates evaluation steps
- Scores using intermediate reasoning
- More aligned with human judgment than direct scoring
- Hierarchical scoring

Use for: Quality assessment, content evaluation
Paper: https://arxiv.org/abs/2303.16634

### Prometheus Framework

**Approach**: Open-source alternative to GPT-4 judge
**Features**:
- Fine-tuned models for evaluation
- Reference-based and reference-free variants
- Detailed rubric scoring
- Reproducible and auditable

Use for: Production evaluation without external APIs
Website: https://arxiv.org/abs/2310.08491

### AlpacaEval

**Approach**: LLM-based evaluator for instruction-following
**Features**:
- Automated comparison of instruction-following
- GPT-4 as evaluator
- Win-rate calculation
- Instruction-following focus

Use for: Chatbot and instruction-following evaluation
Website: https://github.com/tatsu-lab/alpaca_eval

### MT-Bench (Multi-Turn Conversation Benchmark)

**Size**: 80 high-quality multi-turn questions
**Format**: Multi-turn conversation evaluation
**Key Metrics**: Turn-wise quality scores
**Evaluator**: GPT-4 as judge

Use for: Conversational AI evaluation, multi-turn dialogue assessment
Paper: https://arxiv.org/abs/2306.05685

## Bias and Fairness Frameworks

### BOLD (Bias in Open-Ended Language Generation)

**Focus**: Bias in open-ended generation (not multiple choice)
**Method**: Prompt completion with demographic mentions
**Bias Types**: Gender, race, religion, occupation
**Evaluation**: Human annotation of biased language

Use for: Generative model bias assessment
Paper: https://arxiv.org/abs/2101.11718

### Winogender

**Focus**: Gender bias in coreference resolution
**Format**: Winograd-style sentences with gender-ambiguous pronouns
**Evaluation**: Accuracy of coreference resolution by gender
**Key Metric**: Gender bias - accuracy difference across genders

Use for: Pronoun resolution bias, gender stereotyping assessment
Website: https://github.com/rudinger/winogender-schemas

### StereoSet

**Focus**: Stereotypical bias measurement
**Format**: Intra-sentence consistency task (stereotyped vs anti-stereotyped)
**Stereotypes**: Gender, profession, race, religion
**Evaluation**: Stereotype association scores

Use for: Bias and stereotype assessment
Website: https://stereoset.mit.edu/

### HONEST (Hurtful Sentence Completion)

**Focus**: Hurtful stereotype assessment
**Format**: Sentence completion to assess hurtfulness
**Categories**: Gender, race, religion, sexual orientation, disability
**Evaluation**: Percentage of harmful completions

Use for**: Harmful stereotype detection, safety assessment
Paper: https://arxiv.org/abs/2102.08781

### Fairlearn

**Focus**: Algorithmic fairness toolkit
**Features**:
- Fairness metrics (demographic parity, equalized odds)
- Fairness constraints
- Mitigation algorithms
- Visualization and reporting

Use for: Systematic fairness assessment and mitigation
Website: https://fairlearn.org/

## Tools and Libraries

### PromptFoo

**Purpose**: LLM evaluation and testing tool
**Features**:
- Prompt testing framework
- Template-based evaluation
- Model comparison
- CSV/JSON datasets
- Extensible evaluators

Website: https://www.promptfoo.dev/

### TruLens

**Purpose**: LLM observability and evaluation
**Features**:
- Evaluation recipe composition
- Model monitoring
- Feedback integration
- Leaderboards and dashboards

Website: https://www.trulens.org/

### DeepEval

**Purpose**: LLM evaluation framework
**Features**:
- Pre-built metrics (G-Eval, Prometheus-style)
- Custom metric creation
- Batch evaluation
- Comparison and versioning

Website: https://docs.confident-ai.com/

### LlamaIndex Evaluation Tools

**Purpose**: RAG and indexing evaluation
**Features**:
- Document retrieval evaluation
- Generation quality assessment
- Integration with LlamaIndex

Website: https://docs.llamaindex.ai/

## Production Monitoring Platforms

### LangSmith

**Features**:
- Real-time tracing and debugging
- Evaluation datasets and runs
- Metrics dashboarding
- Collaboration tools

Website: https://smith.langchain.com/

### Weights & Biases (LLMOps)

**Features**:
- Training and inference logging
- Metric tracking
- Model versioning
- Prompt management

Website: https://wandb.ai/site/solutions/llmops

### Phoenix (by Arize)

**Features**:
- LLM observability
- Trace collection
- Embedding visualization
- Performance monitoring

Website: https://docs.arize.com/phoenix

### Helicone

**Features**:
- LLM API proxy for logging
- Cost tracking
- Performance metrics
- Response caching

Website: https://www.helicone.ai/

### LangFuse

**Purpose**: Open-source LLM engineering platform
**Features**:
- Tracing and debugging
- Cost tracking
- Analytics and monitoring
- Self-hostable

Website: https://langfuse.com/

## Key Research Papers

### BLEU: Automatic Evaluation of Machine Translation

Foundational metric for machine translation and text generation
https://aclanthology.org/P02-1040/

### ROUGE: Automatic Summarization Evaluation

Key metric for summarization tasks
https://aclanthology.org/W04-1013/

### BERTScore: Evaluating Text Generation with BERT

Semantic similarity using embeddings
https://arxiv.org/abs/1904.09675

### SelfCheckGPT: Hallucination Detection

Method for detecting hallucinations in LLM outputs
https://arxiv.org/abs/2303.08896

### MMLU: Massive Multitask Language Understanding

Comprehensive benchmark for language model evaluation
https://arxiv.org/abs/2009.03300

### GPT-3.5-Turbo Fine-tuning and Evaluation

Practical evaluation strategies for LLMs
https://platform.openai.com/docs/guides/fine-tuning

## Best Practices Summary

1. **Select benchmarks strategically** - Not all benchmarks apply to your use case
2. **Combine multiple evaluation approaches** - Reference-based, reference-free, LLM-as-judge
3. **Evaluate on task-specific data** - General benchmarks don't guarantee production performance
4. **Monitor for bias and fairness** - Use appropriate datasets and frameworks
5. **Track evaluation metrics over time** - Detect regressions early
6. **Validate LLM judges against humans** - Calibrate regularly
7. **Document evaluation methodology** - For reproducibility and auditability
8. **Automate evaluation in CI/CD** - Catch issues before production
