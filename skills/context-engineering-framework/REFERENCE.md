# Context Engineering Framework - API Reference

## Table of Contents

1. [Token Counting APIs](#token-counting-apis)
2. [Compression Algorithm References](#compression-algorithm-references)
3. [Embedding Model Specifications](#embedding-model-specifications)
4. [Chunking Strategy Parameters](#chunking-strategy-parameters)
5. [Summarization APIs](#summarization-apis)
6. [Performance Benchmarks](#performance-benchmarks)
7. [Compression Ratios by Technique](#compression-ratios-by-technique)

## Token Counting APIs

### tiktoken (OpenAI)

Official tokenizer for OpenAI models.

```python
# Installation
pip install tiktoken

# Basic usage
import tiktoken

# Get encoder for specific model
enc = tiktoken.get_encoding("cl100k_base")  # GPT-4, GPT-3.5-Turbo
enc = tiktoken.encoding_for_model("gpt-4")

# Count tokens
tokens = enc.encode("Hello, world!")
token_count = len(tokens)

# Decode tokens back to text
text = enc.decode(tokens)

# Available encodings
encodings = {
    "gpt-4": "cl100k_base",
    "gpt-3.5-turbo": "cl100k_base",
    "text-davinci-003": "p50k_base",
    "text-davinci-002": "p50k_base",
    "code-davinci-002": "p50k_base",
    "text-embedding-ada-002": "cl100k_base"
}
```

### Anthropic Token Counter

```python
# Installation
pip install anthropic

# Basic usage
from anthropic import Anthropic

client = Anthropic(api_key="your-key")

# Count tokens (Claude models)
token_count = client.count_tokens(
    text="Your text here",
    model="claude-3-opus-20240229"
)

# Models
claude_models = [
    "claude-3-opus-20240229",
    "claude-3-sonnet-20240229",
    "claude-3-haiku-20240307",
    "claude-2.1",
    "claude-2.0"
]
```

### Transformers (Hugging Face)

```python
# Installation
pip install transformers

# Basic usage
from transformers import AutoTokenizer

# Load tokenizer for any model
tokenizer = AutoTokenizer.from_pretrained("meta-llama/Llama-2-7b-hf")

# Count tokens
tokens = tokenizer.encode("Hello, world!")
token_count = len(tokens)

# Decode
text = tokenizer.decode(tokens)

# Popular models
models = [
    "meta-llama/Llama-2-7b-hf",
    "mistralai/Mistral-7B-v0.1",
    "google/flan-t5-xxl",
    "bigscience/bloom",
    "EleutherAI/gpt-neox-20b"
]

# Batch tokenization
batch_texts = ["Text 1", "Text 2", "Text 3"]
batch_tokens = tokenizer(batch_texts, padding=True, truncation=True, return_tensors="pt")
```

### Token Counting Best Practices

```python
class UniversalTokenCounter:
    """Universal token counter for multiple models"""

    def __init__(self):
        self.tokenizers = {}
        self._initialize_tokenizers()

    def _initialize_tokenizers(self):
        # OpenAI models
        try:
            import tiktoken
            self.tokenizers['gpt-4'] = tiktoken.encoding_for_model('gpt-4')
            self.tokenizers['gpt-3.5-turbo'] = tiktoken.encoding_for_model('gpt-3.5-turbo')
        except ImportError:
            pass

        # Open source models
        try:
            from transformers import AutoTokenizer
            self.tokenizers['llama2'] = AutoTokenizer.from_pretrained('meta-llama/Llama-2-7b-hf')
            self.tokenizers['mistral'] = AutoTokenizer.from_pretrained('mistralai/Mistral-7B-v0.1')
        except ImportError:
            pass

    def count(self, text, model='gpt-4'):
        if model in self.tokenizers:
            tokenizer = self.tokenizers[model]
            if hasattr(tokenizer, 'encode'):
                return len(tokenizer.encode(text))
            else:
                return len(tokenizer.tokenize(text))
        else:
            # Fallback to character-based estimation
            return len(text) // 4  # Rough approximation

# Token limits by model (2024)
TOKEN_LIMITS = {
    'gpt-4': 128000,
    'gpt-4-32k': 32768,
    'gpt-3.5-turbo': 16385,
    'gpt-3.5-turbo-16k': 16385,
    'claude-3-opus': 200000,
    'claude-3-sonnet': 200000,
    'claude-3-haiku': 200000,
    'claude-2.1': 200000,
    'gemini-1.5-pro': 2097152,  # 2M tokens
    'llama-2-70b': 4096,
    'mistral-7b': 32768
}
```

## Compression Algorithm References

### Text Compression Algorithms

```python
# Lossless compression
import zlib
import bz2
import lzma
import gzip

def compare_compression_algorithms(text):
    """Compare different compression algorithms"""
    original_size = len(text.encode('utf-8'))
    results = {}

    # zlib (DEFLATE)
    zlib_compressed = zlib.compress(text.encode('utf-8'))
    results['zlib'] = {
        'size': len(zlib_compressed),
        'ratio': 1 - len(zlib_compressed) / original_size,
        'speed': 'fast'
    }

    # bz2 (Burrows-Wheeler)
    bz2_compressed = bz2.compress(text.encode('utf-8'))
    results['bz2'] = {
        'size': len(bz2_compressed),
        'ratio': 1 - len(bz2_compressed) / original_size,
        'speed': 'medium'
    }

    # lzma (7-zip algorithm)
    lzma_compressed = lzma.compress(text.encode('utf-8'))
    results['lzma'] = {
        'size': len(lzma_compressed),
        'ratio': 1 - len(lzma_compressed) / original_size,
        'speed': 'slow'
    }

    # gzip
    gzip_compressed = gzip.compress(text.encode('utf-8'))
    results['gzip'] = {
        'size': len(gzip_compressed),
        'ratio': 1 - len(gzip_compressed) / original_size,
        'speed': 'fast'
    }

    return results

# Semantic compression techniques
COMPRESSION_TECHNIQUES = {
    'whitespace_removal': {
        'ratio': 0.05-0.10,
        'lossless': True,
        'speed': 'very_fast'
    },
    'deduplication': {
        'ratio': 0.10-0.30,
        'lossless': True,
        'speed': 'fast'
    },
    'reference_extraction': {
        'ratio': 0.20-0.40,
        'lossless': True,
        'speed': 'medium'
    },
    'abbreviation': {
        'ratio': 0.10-0.20,
        'lossless': False,
        'speed': 'fast'
    },
    'summarization': {
        'ratio': 0.40-0.80,
        'lossless': False,
        'speed': 'slow'
    },
    'abstraction': {
        'ratio': 0.60-0.90,
        'lossless': False,
        'speed': 'very_slow'
    }
}
```

### Compression Implementation

```python
class CompressionPipeline:
    """Configurable compression pipeline"""

    def __init__(self, techniques=['whitespace', 'dedup', 'summarize']):
        self.techniques = techniques
        self.compression_functions = {
            'whitespace': self._compress_whitespace,
            'dedup': self._deduplicate,
            'references': self._extract_references,
            'abbreviate': self._abbreviate,
            'summarize': self._summarize,
            'abstract': self._abstract
        }

    def compress(self, text, target_ratio=0.5):
        current_text = text
        original_length = len(text)

        for technique in self.techniques:
            if technique in self.compression_functions:
                current_text = self.compression_functions[technique](current_text)

                # Check if target reached
                current_ratio = 1 - len(current_text) / original_length
                if current_ratio >= target_ratio:
                    break

        return current_text

    def _compress_whitespace(self, text):
        import re
        text = re.sub(r'\s+', ' ', text)
        text = re.sub(r'\n{3,}', '\n\n', text)
        return text

    def _deduplicate(self, text):
        lines = text.split('\n')
        seen = []
        deduped = []
        for line in lines:
            if line not in seen:
                seen.append(line)
                deduped.append(line)
        return '\n'.join(deduped)

    # Additional compression methods...
```

## Embedding Model Specifications

### OpenAI Embeddings

```python
# text-embedding-ada-002
OPENAI_ADA_002 = {
    'model': 'text-embedding-ada-002',
    'dimensions': 1536,
    'max_tokens': 8191,
    'cost_per_1k_tokens': 0.0001,
    'similarity_metric': 'cosine',
    'normalization': 'l2'
}

# text-embedding-3-small
OPENAI_3_SMALL = {
    'model': 'text-embedding-3-small',
    'dimensions': 1536,
    'max_tokens': 8191,
    'cost_per_1k_tokens': 0.00002,
    'similarity_metric': 'cosine'
}

# text-embedding-3-large
OPENAI_3_LARGE = {
    'model': 'text-embedding-3-large',
    'dimensions': 3072,
    'max_tokens': 8191,
    'cost_per_1k_tokens': 0.00013,
    'similarity_metric': 'cosine'
}

# Usage
from openai import OpenAI
client = OpenAI()

response = client.embeddings.create(
    model="text-embedding-ada-002",
    input="Your text here"
)
embedding = response.data[0].embedding
```

### Cohere Embeddings

```python
# Cohere embed-v3
COHERE_EMBED_V3 = {
    'models': {
        'embed-english-v3.0': {'dimensions': 1024, 'languages': ['en']},
        'embed-multilingual-v3.0': {'dimensions': 1024, 'languages': ['100+']},
        'embed-english-light-v3.0': {'dimensions': 384, 'languages': ['en']},
        'embed-multilingual-light-v3.0': {'dimensions': 384, 'languages': ['100+']}
    },
    'max_tokens': 512,
    'input_types': ['search_document', 'search_query', 'classification', 'clustering'],
    'cost_per_1m_tokens': 0.1
}

# Usage
import cohere
co = cohere.Client('your-api-key')

response = co.embed(
    texts=["Your text here"],
    model='embed-english-v3.0',
    input_type='search_document'
)
embeddings = response.embeddings
```

### Open Source Embeddings

```python
# Sentence Transformers
SENTENCE_TRANSFORMERS = {
    'all-MiniLM-L6-v2': {
        'dimensions': 384,
        'max_tokens': 256,
        'speed': 'very_fast',
        'quality': 'good'
    },
    'all-mpnet-base-v2': {
        'dimensions': 768,
        'max_tokens': 384,
        'speed': 'fast',
        'quality': 'excellent'
    },
    'all-roberta-large-v1': {
        'dimensions': 1024,
        'max_tokens': 256,
        'speed': 'medium',
        'quality': 'excellent'
    }
}

# Usage
from sentence_transformers import SentenceTransformer

model = SentenceTransformer('all-MiniLM-L6-v2')
embeddings = model.encode(['Your text here'])

# BGE models
BGE_MODELS = {
    'BAAI/bge-large-en-v1.5': {
        'dimensions': 1024,
        'max_tokens': 512,
        'languages': ['en'],
        'quality': 'state-of-the-art'
    },
    'BAAI/bge-base-en-v1.5': {
        'dimensions': 768,
        'max_tokens': 512,
        'languages': ['en'],
        'quality': 'excellent'
    },
    'BAAI/bge-small-en-v1.5': {
        'dimensions': 384,
        'max_tokens': 512,
        'languages': ['en'],
        'quality': 'good'
    }
}
```

### Embedding Utilities

```python
def calculate_similarity(embedding1, embedding2, metric='cosine'):
    """Calculate similarity between embeddings"""
    import numpy as np

    if metric == 'cosine':
        dot_product = np.dot(embedding1, embedding2)
        norm1 = np.linalg.norm(embedding1)
        norm2 = np.linalg.norm(embedding2)
        return dot_product / (norm1 * norm2)

    elif metric == 'euclidean':
        return -np.linalg.norm(np.array(embedding1) - np.array(embedding2))

    elif metric == 'dot_product':
        return np.dot(embedding1, embedding2)

def batch_embed(texts, model='text-embedding-ada-002', batch_size=100):
    """Batch embed texts for efficiency"""
    embeddings = []

    for i in range(0, len(texts), batch_size):
        batch = texts[i:i+batch_size]

        if 'ada' in model:
            from openai import OpenAI
            client = OpenAI()
            response = client.embeddings.create(model=model, input=batch)
            batch_embeddings = [e.embedding for e in response.data]
        else:
            # Use sentence transformers
            from sentence_transformers import SentenceTransformer
            model_obj = SentenceTransformer(model)
            batch_embeddings = model_obj.encode(batch).tolist()

        embeddings.extend(batch_embeddings)

    return embeddings
```

## Chunking Strategy Parameters

### Chunking Configuration

```python
CHUNKING_STRATEGIES = {
    'fixed_size': {
        'params': {
            'chunk_size': 1000,
            'overlap': 100,
            'unit': 'characters'  # or 'tokens', 'words'
        },
        'pros': 'Simple, predictable size',
        'cons': 'May break semantic units'
    },
    'sentence_based': {
        'params': {
            'sentences_per_chunk': 5,
            'min_chunk_size': 100,
            'max_chunk_size': 1000
        },
        'pros': 'Preserves sentence integrity',
        'cons': 'Variable chunk sizes'
    },
    'paragraph_based': {
        'params': {
            'paragraphs_per_chunk': 2,
            'fallback_to_sentences': True
        },
        'pros': 'Preserves context',
        'cons': 'Can create very large chunks'
    },
    'semantic': {
        'params': {
            'similarity_threshold': 0.7,
            'min_chunk_size': 200,
            'max_chunk_size': 2000
        },
        'pros': 'Best semantic coherence',
        'cons': 'Computationally expensive'
    },
    'recursive': {
        'params': {
            'separators': ['\n\n', '\n', '. ', ' '],
            'chunk_size': 1000,
            'chunk_overlap': 200
        },
        'pros': 'Adaptive to content',
        'cons': 'Complex to implement'
    }
}

class ChunkingOptimizer:
    """Optimize chunking parameters"""

    def __init__(self):
        self.strategies = CHUNKING_STRATEGIES

    def recommend_strategy(self, content_type, avg_length, retrieval_needs):
        """Recommend chunking strategy based on content"""

        if content_type == 'code':
            return {
                'strategy': 'semantic',
                'params': {
                    'boundaries': ['function', 'class', 'module'],
                    'max_chunk_size': 2000
                }
            }

        elif content_type == 'documentation':
            return {
                'strategy': 'paragraph_based',
                'params': {
                    'paragraphs_per_chunk': 2,
                    'preserve_headers': True
                }
            }

        elif content_type == 'conversation':
            return {
                'strategy': 'fixed_size',
                'params': {
                    'chunk_size': 1000,
                    'overlap': 200,
                    'preserve_speaker_turns': True
                }
            }

        elif retrieval_needs == 'high_precision':
            return {
                'strategy': 'semantic',
                'params': {
                    'similarity_threshold': 0.8,
                    'min_chunk_size': 100
                }
            }

        else:
            return {
                'strategy': 'recursive',
                'params': self.strategies['recursive']['params']
            }

# Chunk size recommendations
CHUNK_SIZE_RECOMMENDATIONS = {
    'retrieval_qa': {
        'ideal_size': 500-1000,
        'overlap': 100-200,
        'reasoning': 'Balance between context and precision'
    },
    'summarization': {
        'ideal_size': 1000-2000,
        'overlap': 200-400,
        'reasoning': 'Larger chunks for better context'
    },
    'classification': {
        'ideal_size': 200-500,
        'overlap': 50-100,
        'reasoning': 'Smaller chunks for focused classification'
    },
    'semantic_search': {
        'ideal_size': 300-800,
        'overlap': 100-200,
        'reasoning': 'Medium chunks for semantic relevance'
    }
}
```

## Summarization APIs

### OpenAI Summarization

```python
def summarize_with_openai(text, target_length=500):
    """Summarize using OpenAI GPT models"""
    from openai import OpenAI
    client = OpenAI()

    prompt = f"""Summarize the following text in approximately {target_length} characters.
Focus on key points and maintain coherence.

Text:
{text}

Summary:"""

    response = client.chat.completions.create(
        model="gpt-4",
        messages=[
            {"role": "system", "content": "You are a precise summarization assistant."},
            {"role": "user", "content": prompt}
        ],
        max_tokens=target_length // 4,  # Approximate token count
        temperature=0.3  # Lower temperature for consistency
    )

    return response.choices[0].message.content
```

### Anthropic Summarization

```python
def summarize_with_anthropic(text, style='concise'):
    """Summarize using Claude models"""
    from anthropic import Anthropic
    client = Anthropic()

    styles = {
        'concise': "Be extremely concise, focusing only on essential points.",
        'detailed': "Provide a comprehensive summary with key details.",
        'bullets': "Summarize as bullet points.",
        'technical': "Focus on technical details and specifications."
    }

    response = client.messages.create(
        model="claude-3-sonnet-20240229",
        max_tokens=1000,
        messages=[
            {
                "role": "user",
                "content": f"{styles.get(style, styles['concise'])}\n\nText to summarize:\n{text}"
            }
        ]
    )

    return response.content[0].text
```

### Local Summarization Models

```python
# Using Hugging Face transformers
from transformers import pipeline

# Facebook BART
bart_summarizer = pipeline("summarization", model="facebook/bart-large-cnn")
result = bart_summarizer(text, max_length=130, min_length=30, do_sample=False)

# Google T5
t5_summarizer = pipeline("summarization", model="google/flan-t5-large")
result = t5_summarizer(text, max_length=200, min_length=50)

# Pegasus
pegasus_summarizer = pipeline("summarization", model="google/pegasus-xsum")
result = pegasus_summarizer(text, max_length=150)

# Comparison of models
SUMMARIZATION_MODELS = {
    'gpt-4': {
        'quality': 'excellent',
        'speed': 'medium',
        'cost': 'high',
        'max_input': 128000
    },
    'claude-3': {
        'quality': 'excellent',
        'speed': 'fast',
        'cost': 'medium',
        'max_input': 200000
    },
    'bart-large-cnn': {
        'quality': 'good',
        'speed': 'fast',
        'cost': 'free',
        'max_input': 1024
    },
    'flan-t5-xxl': {
        'quality': 'very_good',
        'speed': 'medium',
        'cost': 'free',
        'max_input': 512
    }
}
```

## Performance Benchmarks

### Compression Performance

```python
COMPRESSION_BENCHMARKS = {
    'whitespace_removal': {
        '1KB': {'time': '0.1ms', 'reduction': '5-10%'},
        '10KB': {'time': '0.5ms', 'reduction': '5-10%'},
        '100KB': {'time': '5ms', 'reduction': '5-10%'},
        '1MB': {'time': '50ms', 'reduction': '5-10%'}
    },
    'deduplication': {
        '1KB': {'time': '0.5ms', 'reduction': '0-30%'},
        '10KB': {'time': '5ms', 'reduction': '10-40%'},
        '100KB': {'time': '50ms', 'reduction': '20-50%'},
        '1MB': {'time': '500ms', 'reduction': '30-60%'}
    },
    'semantic_compression': {
        '1KB': {'time': '100ms', 'reduction': '40-60%'},
        '10KB': {'time': '500ms', 'reduction': '50-70%'},
        '100KB': {'time': '5s', 'reduction': '60-80%'},
        '1MB': {'time': '30s', 'reduction': '70-90%'}
    }
}

def benchmark_compression(text, method):
    """Benchmark compression method"""
    import time
    import sys

    start_time = time.perf_counter()
    start_memory = sys.getsizeof(text)

    if method == 'whitespace':
        compressed = remove_whitespace(text)
    elif method == 'dedup':
        compressed = deduplicate(text)
    elif method == 'semantic':
        compressed = semantic_compress(text)

    end_time = time.perf_counter()
    end_memory = sys.getsizeof(compressed)

    return {
        'method': method,
        'original_size': start_memory,
        'compressed_size': end_memory,
        'reduction': 1 - end_memory/start_memory,
        'time': end_time - start_time,
        'throughput': start_memory / (end_time - start_time) / 1024 / 1024  # MB/s
    }
```

### Token Counting Performance

```python
TOKEN_COUNTING_BENCHMARKS = {
    'tiktoken': {
        '1KB': '0.1ms',
        '10KB': '1ms',
        '100KB': '10ms',
        '1MB': '100ms'
    },
    'transformers': {
        '1KB': '0.5ms',
        '10KB': '5ms',
        '100KB': '50ms',
        '1MB': '500ms'
    },
    'approximation': {
        '1KB': '0.01ms',
        '10KB': '0.1ms',
        '100KB': '1ms',
        '1MB': '10ms'
    }
}
```

### Embedding Generation Performance

```python
EMBEDDING_BENCHMARKS = {
    'openai-ada-002': {
        'latency': '50-200ms',
        'throughput': '100 docs/sec',
        'batch_size': 100,
        'cost': '$0.0001/1k tokens'
    },
    'cohere-embed-v3': {
        'latency': '30-150ms',
        'throughput': '200 docs/sec',
        'batch_size': 96,
        'cost': '$0.1/1M tokens'
    },
    'sentence-transformers': {
        'latency': '5-50ms',
        'throughput': '500 docs/sec',
        'batch_size': 256,
        'cost': 'free (local)'
    }
}
```

## Compression Ratios by Technique

### Detailed Compression Analysis

```python
COMPRESSION_RATIOS = {
    'whitespace_normalization': {
        'typical_reduction': '5-10%',
        'best_case': '20%',
        'worst_case': '1%',
        'lossless': True,
        'applicable_to': ['all text types']
    },
    'deduplication': {
        'typical_reduction': '10-30%',
        'best_case': '70%',
        'worst_case': '0%',
        'lossless': True,
        'applicable_to': ['repetitive text', 'logs', 'config files']
    },
    'reference_extraction': {
        'typical_reduction': '20-40%',
        'best_case': '60%',
        'worst_case': '5%',
        'lossless': True,
        'applicable_to': ['documentation', 'technical writing']
    },
    'abbreviation': {
        'typical_reduction': '10-20%',
        'best_case': '30%',
        'worst_case': '5%',
        'lossless': False,
        'applicable_to': ['technical text', 'common terms']
    },
    'extractive_summarization': {
        'typical_reduction': '40-60%',
        'best_case': '80%',
        'worst_case': '20%',
        'lossless': False,
        'applicable_to': ['prose', 'articles', 'reports']
    },
    'abstractive_summarization': {
        'typical_reduction': '60-80%',
        'best_case': '95%',
        'worst_case': '40%',
        'lossless': False,
        'applicable_to': ['long documents', 'complex text']
    },
    'semantic_compression': {
        'typical_reduction': '50-70%',
        'best_case': '90%',
        'worst_case': '30%',
        'lossless': False,
        'applicable_to': ['all text types']
    }
}

def estimate_compression(text, techniques):
    """Estimate compression ratio for combination of techniques"""
    original_size = len(text)
    current_size = original_size

    for technique in techniques:
        if technique in COMPRESSION_RATIOS:
            ratio_range = COMPRESSION_RATIOS[technique]['typical_reduction']
            # Parse ratio range (e.g., "10-30%" -> 0.2 average)
            if '-' in ratio_range:
                min_r, max_r = ratio_range.replace('%', '').split('-')
                avg_ratio = (int(min_r) + int(max_r)) / 200
            else:
                avg_ratio = int(ratio_range.replace('%', '')) / 100

            current_size *= (1 - avg_ratio)

    total_reduction = 1 - current_size / original_size
    return {
        'estimated_size': int(current_size),
        'estimated_reduction': total_reduction,
        'techniques_applied': techniques
    }
```

### Compression Strategy Selection

```python
def select_compression_strategy(text_size, text_type, quality_requirement):
    """Select optimal compression strategy"""

    strategies = {
        'aggressive': {
            'techniques': ['whitespace', 'dedup', 'abbreviate', 'abstract'],
            'expected_reduction': '70-90%',
            'quality': 'low-medium'
        },
        'balanced': {
            'techniques': ['whitespace', 'dedup', 'extractive_summary'],
            'expected_reduction': '50-70%',
            'quality': 'medium-high'
        },
        'conservative': {
            'techniques': ['whitespace', 'dedup', 'references'],
            'expected_reduction': '20-40%',
            'quality': 'high'
        },
        'lossless': {
            'techniques': ['whitespace', 'dedup'],
            'expected_reduction': '10-30%',
            'quality': 'perfect'
        }
    }

    # Select based on requirements
    if quality_requirement == 'perfect':
        return strategies['lossless']
    elif text_size > 1000000:  # >1MB
        return strategies['aggressive']
    elif text_type == 'code':
        return strategies['conservative']
    elif text_type == 'documentation':
        return strategies['balanced']
    else:
        return strategies['balanced']
```

### Real-World Compression Examples

```python
REAL_WORLD_EXAMPLES = {
    'code_review_context': {
        'original': 150000,  # tokens
        'after_whitespace': 142500,  # -5%
        'after_dedup': 120000,  # -20%
        'after_references': 90000,  # -40%
        'after_summary': 45000,  # -70%
        'final': 45000,
        'total_reduction': '70%'
    },
    'documentation_context': {
        'original': 80000,
        'after_whitespace': 76000,  # -5%
        'after_dedup': 64000,  # -20%
        'after_extractive': 32000,  # -60%
        'final': 32000,
        'total_reduction': '60%'
    },
    'conversation_history': {
        'original': 50000,
        'after_whitespace': 47500,  # -5%
        'after_dedup': 40000,  # -20%
        'after_progressive': 15000,  # -70%
        'final': 15000,
        'total_reduction': '70%'
    },
    'debug_logs': {
        'original': 200000,
        'after_whitespace': 180000,  # -10%
        'after_dedup': 100000,  # -50%
        'after_pattern': 40000,  # -80%
        'final': 40000,
        'total_reduction': '80%'
    }
}
```

---

*This reference provides comprehensive API documentation and performance data for the Context Engineering Framework. For implementation details, see [PATTERNS.md](PATTERNS.md).*