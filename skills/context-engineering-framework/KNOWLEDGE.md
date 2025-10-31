# Context Engineering Framework - Knowledge Base

## Table of Contents

1. [Context Window Concepts](#context-window-concepts)
2. [Information Theory](#information-theory)
3. [Semantic Similarity](#semantic-similarity)
4. [Retrieval Augmented Generation (RAG)](#retrieval-augmented-generation-rag)
5. [Memory Systems](#memory-systems)
6. [Token Budgeting Strategies](#token-budgeting-strategies)
7. [LLM Context Management Research](#llm-context-management-research)
8. [Tool Comparisons](#tool-comparisons)

## Context Window Concepts

### Understanding Tokens

Tokens are the atomic units of text that LLMs process. They're not characters or words, but something in between:

- **English text**: ~1 token per 4 characters
- **Code**: ~1 token per 2-3 characters (more symbols)
- **Other languages**: Varies widely (Chinese ~1 token per character)

```python
# Example tokenization
"Hello world" → ["Hello", " world"] → 2 tokens
"function()" → ["function", "(", ")"] → 3 tokens
```

### Attention Mechanisms

LLMs use attention to relate tokens to each other. Attention has quadratic complexity O(n²) with context length:

- 1k tokens: 1M attention computations
- 10k tokens: 100M computations
- 100k tokens: 10B computations

This drives both computational cost and quality degradation at scale.

### Context Retrieval Patterns

How LLMs access information varies by position in context:

1. **Primacy Effect**: Strong recall of beginning context
2. **Recency Effect**: Strong recall of recent context
3. **Lost in the Middle**: Weak recall of middle sections

Optimal placement strategy:
```
[Critical Instructions] → Beginning
[Reference Material] → Middle
[Working Context] → End
```

## Information Theory

### Entropy and Compression

Information entropy measures the minimum bits needed to encode information:

```python
# Shannon entropy
H(X) = -Σ p(x) * log2(p(x))

# High entropy = high information content = hard to compress
# Low entropy = redundancy = easy to compress
```

### Lossless Compression Techniques

1. **Deduplication**: Remove exact repetitions
2. **Reference Extraction**: Replace repeated phrases with references
3. **Whitespace Normalization**: Consistent formatting
4. **Symbol Substitution**: Short aliases for long identifiers

### Lossy Compression Techniques

1. **Summarization**: Preserve key points, drop details
2. **Abstraction**: Extract patterns, discard instances
3. **Pruning**: Remove low-importance sections
4. **Quantization**: Reduce precision of numeric data

## Semantic Similarity

### Embedding Models

Transform text into dense vector representations:

```python
# Popular embedding models
- OpenAI text-embedding-ada-002: 1536 dimensions
- Anthropic claude-embeddings: 1024 dimensions
- SentenceTransformers: 384-768 dimensions
- Cohere embed-v3: 1024 dimensions
```

### Similarity Metrics

```python
# Cosine similarity (most common)
similarity = cos(θ) = (A·B) / (||A|| * ||B||)

# Euclidean distance
distance = √Σ(ai - bi)²

# Dot product (for normalized vectors)
similarity = A·B
```

### Clustering Techniques

Group similar content for compression:

1. **K-means**: Fast, requires preset K
2. **DBSCAN**: Finds natural clusters
3. **Hierarchical**: Creates cluster tree
4. **HDBSCAN**: Robust to noise, varying densities

## Retrieval Augmented Generation (RAG)

### RAG Architecture

```
Query → Embedding → Vector Search → Retrieved Chunks
                                           ↓
                                    Augmented Prompt → LLM → Response
```

### Chunking Strategies

1. **Fixed-size chunks**: Simple but breaks semantic units
2. **Sentence-based**: Preserves complete thoughts
3. **Paragraph-based**: Maintains local context
4. **Semantic chunking**: Splits at topic boundaries
5. **Recursive chunking**: Hierarchical splitting

### Retrieval Optimization

```python
# Hybrid search combining dense and sparse retrieval
results = α * dense_search(query_embedding) +
         (1-α) * sparse_search(query_keywords)

# Re-ranking with cross-encoder
reranked = cross_encoder.rank(query, results)
```

## Memory Systems

### Short-term Memory (Working Context)

- **Capacity**: Current conversation/task state
- **Duration**: Single session
- **Implementation**: Direct context inclusion
- **Size**: 5-30k tokens typically

### Long-term Memory (Persistent Storage)

- **Capacity**: Unlimited (database/files)
- **Duration**: Across sessions
- **Implementation**: Vector databases, key-value stores
- **Access**: RAG retrieval

### Working Memory (Active Focus)

- **Capacity**: 3-7 "chunks" of information
- **Duration**: Current processing step
- **Implementation**: Prompt engineering, few-shot examples
- **Size**: 1-5k tokens

### Memory Consolidation Patterns

```python
# Progressive consolidation
detailed_memory → summary → key_points → archived

# Hierarchical memory
episode_memory → semantic_memory → procedural_memory
```

## Token Budgeting Strategies

### Static Allocation

Pre-allocate tokens to different context components:

```python
budget = {
    'system': 2000,      # 2%
    'examples': 5000,    # 5%
    'documents': 50000,  # 50%
    'conversation': 33000, # 33%
    'buffer': 10000      # 10%
}
```

### Dynamic Allocation

Adjust allocation based on task needs:

```python
if task_type == 'code_review':
    prioritize('code_context', 0.6)
    minimize('conversation_history', 0.1)
elif task_type == 'creative_writing':
    prioritize('examples', 0.3)
    prioritize('conversation', 0.5)
```

### Sliding Window

Maintain fixed window, drop oldest content:

```python
def sliding_window(context, max_tokens=50000):
    while count_tokens(context) > max_tokens:
        context = drop_oldest_exchange(context)
    return context
```

### Priority-based Truncation

Score and rank context elements:

```python
scored_context = [
    (score_importance(chunk), chunk)
    for chunk in context_chunks
]
sorted_context = sorted(scored_context, reverse=True)
return fit_to_budget(sorted_context, max_tokens)
```

## LLM Context Management Research

### Key Papers

1. **"Lost in the Middle"** (Liu et al., 2023)
   - Performance degrades with context position
   - Best recall at beginning and end

2. **"Length Generalization in Transformers"** (Anthropic, 2023)
   - Context extension techniques
   - Position encoding improvements

3. **"Extending Context Windows"** (Meta, 2023)
   - RoPE scaling methods
   - Fine-tuning for longer contexts

4. **"Efficient Attention Mechanisms"** (Google, 2023)
   - Linear attention approximations
   - Sparse attention patterns

### Emerging Techniques

1. **Landmark Attention**: Mark important tokens
2. **Blockwise Attention**: Process in chunks
3. **Retrieval-Enhanced Transformers**: Dynamic context fetching
4. **Continuous Context**: Stream processing approaches

## Tool Comparisons

### Context Management Frameworks

| Tool | Strengths | Weaknesses | Best For |
|------|-----------|------------|----------|
| **LangChain** | Comprehensive, many integrations | Complex, heavyweight | Full-stack apps |
| **LlamaIndex** | Excellent RAG, data connectors | Learning curve | Document QA |
| **Haystack** | Production-ready, scalable | Enterprise focus | Search systems |
| **DSPy** | Optimization-focused | Research-oriented | Prompt optimization |
| **Semantic Kernel** | Microsoft ecosystem | Windows-centric | .NET applications |

### Embedding Models Comparison

| Model | Dimensions | Context | Speed | Quality | Cost |
|-------|------------|---------|-------|---------|------|
| **OpenAI Ada-002** | 1536 | 8k | Fast | Excellent | $$$ |
| **Cohere Embed-v3** | 1024 | 512 | Fast | Excellent | $$ |
| **BGE-large** | 1024 | 512 | Medium | Very Good | Free |
| **E5-large-v2** | 1024 | 512 | Medium | Very Good | Free |
| **MiniLM** | 384 | 512 | Very Fast | Good | Free |

### Vector Databases

| Database | Type | Scale | Features | Best For |
|----------|------|-------|----------|----------|
| **Pinecone** | Managed | Billions | Full-featured | Production SaaS |
| **Qdrant** | Self/Managed | Billions | Rust-based, fast | Performance-critical |
| **Weaviate** | Self/Managed | Billions | Multi-modal | Complex queries |
| **Chroma** | Embedded | Millions | Simple, Python | Prototyping |
| **FAISS** | Library | Billions | Meta-built, fast | Research, local |

### Token Counting Libraries

```python
# tiktoken (OpenAI official)
import tiktoken
enc = tiktoken.encoding_for_model("gpt-4")
tokens = enc.encode("text")

# transformers (Hugging Face)
from transformers import AutoTokenizer
tokenizer = AutoTokenizer.from_pretrained("model")
tokens = tokenizer.encode("text")

# Anthropic tokenizer
from anthropic import Anthropic
client = Anthropic()
count = client.count_tokens("text")
```

## Advanced Techniques

### Semantic Compression

```python
def semantic_compress(text, target_ratio=0.5):
    # Extract key sentences using TextRank
    sentences = sent_tokenize(text)
    graph = build_similarity_graph(sentences)
    scores = pagerank(graph)

    # Select top sentences up to target ratio
    ranked = sorted(zip(scores, sentences), reverse=True)
    target_length = len(text) * target_ratio

    compressed = []
    current_length = 0
    for score, sent in ranked:
        if current_length + len(sent) <= target_length:
            compressed.append(sent)
            current_length += len(sent)

    return ' '.join(compressed)
```

### Hierarchical Summarization

```python
def hierarchical_summarize(text, levels=3):
    summaries = []
    current = text

    for level in range(levels):
        compression_ratio = 0.3 ** (level + 1)
        summary = summarize(current, ratio=compression_ratio)
        summaries.append(summary)
        current = summary

    return summaries  # [detailed, medium, brief]
```

### Context Caching Strategies

```python
class ContextCache:
    def __init__(self, max_size=100):
        self.cache = LRU(max_size)
        self.embeddings = {}

    def get_or_compute(self, key, compute_fn):
        if key in self.cache:
            return self.cache[key]

        result = compute_fn(key)
        self.cache[key] = result
        return result

    def semantic_get(self, query, threshold=0.9):
        query_emb = embed(query)
        for key, emb in self.embeddings.items():
            if cosine_similarity(query_emb, emb) > threshold:
                return self.cache.get(key)
        return None
```

## Best Practices from Production

### 1. Token Budget Monitoring

```python
class TokenBudgetMonitor:
    def __init__(self, limit=100000):
        self.limit = limit
        self.used = 0
        self.history = []

    def use(self, tokens, component):
        self.used += tokens
        self.history.append((component, tokens))

        if self.used > self.limit * 0.8:
            self.alert("80% budget used")
        if self.used > self.limit * 0.9:
            self.compress_context()
```

### 2. Gradual Degradation

```python
compression_tiers = [
    (1.0, 'none'),         # Full context
    (0.8, 'deduplicate'),  # Remove redundancy
    (0.6, 'summarize'),    # Semantic compression
    (0.4, 'aggressive'),   # Heavy summarization
    (0.2, 'critical_only') # Only essential
]
```

### 3. Context Validation

```python
def validate_context_preservation(original, compressed):
    # Check key information preserved
    key_facts = extract_key_facts(original)
    preserved = all(fact in compressed for fact in key_facts)

    # Check semantic similarity
    similarity = semantic_similarity(original, compressed)

    # Check specific requirements
    required_elements = extract_requirements(original)
    complete = all(elem in compressed for elem in required_elements)

    return preserved and similarity > 0.8 and complete
```

## Future Directions

### Emerging Research Areas

1. **Infinite Context**: Techniques for unbounded context
2. **Selective Attention**: Dynamic focus mechanisms
3. **Context Compilation**: Pre-computing attention patterns
4. **Memory-Augmented Models**: External memory integration
5. **Streaming Transformers**: Continuous context processing

### Industry Trends

- Move toward 1M+ token contexts
- Hardware acceleration for attention
- Hybrid retrieval-generation architectures
- Context-aware token pricing models
- Automated context optimization tools

## References

### Essential Reading

1. Anthropic's "Constitutional AI" papers on context handling
2. OpenAI's "Long Context" research series
3. Google's "Efficient Transformers" survey
4. Meta's "Retrieval-Augmented Generation" papers
5. Microsoft's "Semantic Kernel" documentation

### Tools and Libraries

- **tiktoken**: OpenAI's fast tokenizer
- **langchain**: Comprehensive LLM framework
- **llama-index**: Data framework for LLMs
- **sentence-transformers**: State-of-art embeddings
- **faiss**: Efficient similarity search

### Communities and Resources

- r/LocalLLaMA - Context optimization discussions
- Hugging Face forums - Model-specific techniques
- LangChain Discord - RAG patterns and tips
- Papers with Code - Latest context research
- GitHub - Open-source context tools

---

*This knowledge base provides the theoretical foundation for the Context Engineering Framework. For practical implementation, see [PATTERNS.md](PATTERNS.md).*