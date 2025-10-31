# Context Engineering Framework - Common Gotchas & Troubleshooting

## Table of Contents

1. [Information Loss During Compression](#information-loss-during-compression)
2. [Semantic Boundaries in Code vs Prose](#semantic-boundaries-in-code-vs-prose)
3. [Token Counting Inconsistencies](#token-counting-inconsistencies)
4. [Embedding Drift and Staleness](#embedding-drift-and-staleness)
5. [Handoff Document Completeness](#handoff-document-completeness)
6. [Context Reconstruction Errors](#context-reconstruction-errors)
7. [Performance Degradation at Scale](#performance-degradation-at-scale)
8. [Debugging Strategies](#debugging-strategies)

## Information Loss During Compression

### The Problem

Aggressive compression can remove critical details that seem redundant but are actually essential.

```python
# Original code with important edge case handling
def process_data(data):
    if data is None:
        return default_value()  # Critical for null safety
    if len(data) == 0:
        return empty_result()   # Different from None case!
    if len(data) == 1:
        return single_item_handler(data[0])  # Special optimization
    return batch_process(data)

# After aggressive compression - BROKEN!
def process_data(data):
    return batch_process(data)  # Lost all edge cases!
```

### Common Scenarios

1. **Removing "redundant" error handling** that's actually critical
2. **Summarizing technical specifications** and losing precision
3. **Compressing configuration** and dropping important overrides
4. **Abstracting algorithm steps** and losing implementation details

### Solutions

```python
class SafeCompressor:
    def __init__(self):
        self.protected_patterns = [
            r'if.*None',           # Null checks
            r'except.*Error',      # Error handling
            r'assert',             # Assertions
            r'raise',              # Exceptions
            r'return.*default',    # Default values
            r'fallback',           # Fallback logic
            r'WARNING|ERROR|CRITICAL',  # Log levels
            r'TODO|FIXME|BUG',     # Important markers
        ]

    def compress_safely(self, text, level='medium'):
        # First, extract protected content
        protected = self.extract_protected(text)

        # Compress non-protected content
        compressed = self.compress_regular(text, level)

        # Merge back protected content
        return self.merge_protected(compressed, protected)

    def extract_protected(self, text):
        """Extract content that must not be compressed"""
        protected = []
        for pattern in self.protected_patterns:
            matches = re.findall(f'.*{pattern}.*', text, re.MULTILINE)
            protected.extend(matches)
        return protected

    def validate_compression(self, original, compressed):
        """Validate that critical information is preserved"""
        critical_terms = ['error', 'exception', 'null', 'none', 'empty']

        for term in critical_terms:
            original_count = original.lower().count(term)
            compressed_count = compressed.lower().count(term)

            if original_count > 0 and compressed_count == 0:
                print(f"WARNING: Lost all mentions of '{term}'")
                return False

        return True
```

### Best Practices

1. **Always validate compression output**
2. **Maintain a "do not compress" list** for critical sections
3. **Use tiered compression** - try less aggressive methods first
4. **Test with edge cases** after compression
5. **Keep original available** for reference

## Semantic Boundaries in Code vs Prose

### The Problem

Code and prose have different semantic boundaries. Splitting code at paragraph breaks can break syntax.

```python
# Original code - semantically complete function
def calculate_total(items):
    total = 0
    for item in items:
        total += item.price * item.quantity
    return total

# Bad semantic split - breaks in middle of loop!
# Chunk 1:
def calculate_total(items):
    total = 0
    for item in items:

# Chunk 2:
        total += item.price * item.quantity
    return total
```

### Language-Specific Boundaries

```python
class LanguageAwareChunker:
    def get_boundaries(self, text, language):
        """Get semantic boundaries based on language"""
        boundaries = {
            'python': [
                r'^def ',           # Function definitions
                r'^class ',         # Class definitions
                r'^if __name__',    # Main blocks
                r'^\S',             # Top-level statements
            ],
            'javascript': [
                r'^function ',      # Functions
                r'^const.*=.*{',    # Arrow functions
                r'^class ',         # Classes
                r'^export ',        # Exports
            ],
            'prose': [
                r'\n\n',            # Paragraphs
                r'^#{1,6} ',        # Markdown headers
                r'^\d+\.',          # Numbered lists
                r'^[-*] ',          # Bullet points
            ]
        }

        return boundaries.get(language, boundaries['prose'])

    def chunk_code(self, code, language='python'):
        """Chunk code respecting syntax boundaries"""
        import ast

        if language == 'python':
            try:
                tree = ast.parse(code)
                chunks = []

                for node in ast.walk(tree):
                    if isinstance(node, (ast.FunctionDef, ast.ClassDef)):
                        source = ast.get_source_segment(code, node)
                        if source:
                            chunks.append(source)

                return chunks
            except SyntaxError:
                # Fallback to line-based chunking
                return self.fallback_chunk(code)

    def fallback_chunk(self, text):
        """Fallback chunking when parsing fails"""
        # Use indentation as boundary indicator
        chunks = []
        current = []

        for line in text.split('\n'):
            if line and not line[0].isspace():  # New top-level element
                if current:
                    chunks.append('\n'.join(current))
                current = [line]
            else:
                current.append(line)

        if current:
            chunks.append('\n'.join(current))

        return chunks
```

### Detection and Prevention

```python
def validate_chunk_syntax(chunk, language):
    """Validate that chunk has valid syntax"""
    validators = {
        'python': validate_python_syntax,
        'javascript': validate_js_syntax,
        'sql': validate_sql_syntax,
    }

    validator = validators.get(language, lambda x: True)
    return validator(chunk)

def validate_python_syntax(code):
    """Check if Python code is syntactically valid"""
    try:
        compile(code, '<string>', 'exec')
        return True
    except SyntaxError:
        return False

def smart_merge_chunks(chunks, language):
    """Merge chunks that are syntactically incomplete"""
    merged = []
    buffer = ""

    for chunk in chunks:
        buffer += "\n" + chunk if buffer else chunk

        if validate_chunk_syntax(buffer, language):
            merged.append(buffer)
            buffer = ""

    # Add remaining buffer if any
    if buffer:
        if merged:
            merged[-1] += "\n" + buffer
        else:
            merged.append(buffer)

    return merged
```

## Token Counting Inconsistencies

### The Problem

Different models use different tokenizers, leading to count mismatches.

```python
# Same text, different token counts!
text = "Hello, world! 你好世界"

# GPT-4 tokenizer
gpt4_tokens = 8  # Hypothetical count

# Claude tokenizer
claude_tokens = 7  # Different count

# Llama tokenizer
llama_tokens = 10  # Yet another count
```

### Model-Specific Tokenizers

```python
class UniversalTokenCounter:
    def __init__(self):
        self.tokenizers = {}
        self._load_tokenizers()

    def _load_tokenizers(self):
        """Load tokenizers for different models"""
        try:
            import tiktoken
            self.tokenizers['gpt-4'] = tiktoken.encoding_for_model('gpt-4')
            self.tokenizers['gpt-3.5'] = tiktoken.encoding_for_model('gpt-3.5-turbo')
        except ImportError:
            print("tiktoken not available")

        try:
            from transformers import AutoTokenizer
            self.tokenizers['llama'] = AutoTokenizer.from_pretrained('meta-llama/Llama-2-7b')
            self.tokenizers['mistral'] = AutoTokenizer.from_pretrained('mistralai/Mistral-7B-v0.1')
        except ImportError:
            print("transformers not available")

    def count_tokens(self, text, model='gpt-4'):
        """Count tokens for specific model"""
        if model not in self.tokenizers:
            # Fallback to approximation
            return self.approximate_tokens(text)

        tokenizer = self.tokenizers[model]

        if hasattr(tokenizer, 'encode'):
            # tiktoken style
            return len(tokenizer.encode(text))
        else:
            # transformers style
            return len(tokenizer.tokenize(text))

    def approximate_tokens(self, text):
        """Approximate token count when tokenizer not available"""
        # Rules of thumb
        char_count = len(text)
        word_count = len(text.split())

        # Different approximations for different content
        if self._is_code(text):
            # Code has more tokens per character
            return int(char_count / 2.5)
        elif self._is_chinese(text):
            # Chinese text ~1 token per character
            return char_count
        else:
            # English prose ~1 token per 4 characters
            return int(char_count / 4)

    def add_safety_margin(self, tokens, margin=0.1):
        """Add safety margin to token count"""
        return int(tokens * (1 + margin))

    def _is_code(self, text):
        code_indicators = ['{', '}', '()', 'def ', 'function', '==', '!=']
        return sum(ind in text for ind in code_indicators) > 2

    def _is_chinese(self, text):
        chinese_chars = sum(1 for char in text if '\u4e00' <= char <= '\u9fff')
        return chinese_chars > len(text) * 0.3
```

### Handling Mismatches

```python
class TokenBudgetWithSafety:
    def __init__(self, model, total_budget):
        self.model = model
        self.total_budget = total_budget
        self.safety_margin = 0.1  # 10% safety margin
        self.effective_budget = int(total_budget * (1 - self.safety_margin))

    def validate_across_models(self, text, models=['gpt-4', 'claude', 'llama']):
        """Check token counts across multiple models"""
        counter = UniversalTokenCounter()
        counts = {}

        for model in models:
            counts[model] = counter.count_tokens(text, model)

        max_count = max(counts.values())
        min_count = min(counts.values())
        variance = (max_count - min_count) / min_count if min_count > 0 else 0

        if variance > 0.2:  # >20% variance
            print(f"WARNING: High token count variance: {variance:.1%}")
            print(f"Counts: {counts}")
            print(f"Using maximum count ({max_count}) for safety")

        return max_count
```

## Embedding Drift and Staleness

### The Problem

Embeddings become stale over time as models are updated or content changes.

```python
# Embeddings created with model v1
old_embeddings = {
    "doc1": [0.1, 0.2, 0.3, ...],  # Created January 2024
    "doc2": [0.2, 0.3, 0.4, ...]   # Created January 2024
}

# New embeddings with model v2 - not comparable!
new_embedding = [0.15, 0.25, 0.35, ...]  # Created June 2024

# Similarity calculation is now meaningless
similarity = cosine_similarity(old_embeddings["doc1"], new_embedding)
# Result is unreliable!
```

### Detection and Mitigation

```python
class EmbeddingManager:
    def __init__(self):
        self.embedding_metadata = {}
        self.model_versions = {}

    def create_embedding(self, text, model='text-embedding-ada-002'):
        """Create embedding with metadata"""
        embedding = self._generate_embedding(text, model)

        metadata = {
            'model': model,
            'model_version': self._get_model_version(model),
            'created_at': datetime.now().isoformat(),
            'text_hash': hashlib.md5(text.encode()).hexdigest(),
            'dimensions': len(embedding)
        }

        return {
            'embedding': embedding,
            'metadata': metadata
        }

    def validate_compatibility(self, embedding1, embedding2):
        """Check if embeddings are compatible for comparison"""
        meta1 = embedding1.get('metadata', {})
        meta2 = embedding2.get('metadata', {})

        issues = []

        # Check model compatibility
        if meta1.get('model') != meta2.get('model'):
            issues.append(f"Model mismatch: {meta1.get('model')} vs {meta2.get('model')}")

        # Check version compatibility
        if meta1.get('model_version') != meta2.get('model_version'):
            issues.append(f"Version mismatch: {meta1.get('model_version')} vs {meta2.get('model_version')}")

        # Check staleness
        date1 = datetime.fromisoformat(meta1.get('created_at', '2000-01-01'))
        date2 = datetime.fromisoformat(meta2.get('created_at', '2000-01-01'))
        age_diff = abs((date1 - date2).days)

        if age_diff > 90:  # More than 90 days apart
            issues.append(f"Large age difference: {age_diff} days")

        # Check dimensions
        if meta1.get('dimensions') != meta2.get('dimensions'):
            issues.append(f"Dimension mismatch: {meta1.get('dimensions')} vs {meta2.get('dimensions')}")

        return len(issues) == 0, issues

    def refresh_stale_embeddings(self, embeddings, max_age_days=30):
        """Refresh embeddings older than max_age"""
        refreshed = {}
        now = datetime.now()

        for key, emb_data in embeddings.items():
            metadata = emb_data.get('metadata', {})
            created = datetime.fromisoformat(metadata.get('created_at', '2000-01-01'))
            age = (now - created).days

            if age > max_age_days:
                print(f"Refreshing stale embedding: {key} (age: {age} days)")
                # Re-generate embedding
                original_text = self._retrieve_original_text(key)
                if original_text:
                    refreshed[key] = self.create_embedding(original_text)
            else:
                refreshed[key] = emb_data

        return refreshed
```

## Handoff Document Completeness

### The Problem

Incomplete handoff documents cause next agent/session to fail or repeat work.

```python
# Incomplete handoff - missing critical information
handoff = {
    'completed_tasks': ['task1', 'task2'],
    'next_steps': ['task3']
    # Missing: current state, decisions made, constraints, context!
}

# Next agent has no idea:
# - What was the approach for task1 and task2?
# - What decisions were made and why?
# - What constraints exist?
# - What's the full context?
```

### Validation Framework

```python
class HandoffValidator:
    def __init__(self):
        self.required_fields = [
            'metadata',
            'context_summary',
            'completed_tasks',
            'current_state',
            'next_steps'
        ]
        self.recommended_fields = [
            'decisions_made',
            'constraints',
            'open_questions',
            'resources',
            'warnings'
        ]

    def validate(self, handoff):
        """Comprehensive handoff validation"""
        results = {
            'valid': True,
            'score': 100,
            'errors': [],
            'warnings': [],
            'suggestions': []
        }

        # Check required fields
        for field in self.required_fields:
            if field not in handoff or not handoff[field]:
                results['valid'] = False
                results['errors'].append(f"Missing required field: {field}")
                results['score'] -= 20

        # Check recommended fields
        for field in self.recommended_fields:
            if field not in handoff or not handoff[field]:
                results['warnings'].append(f"Missing recommended field: {field}")
                results['score'] -= 5

        # Validate specific fields
        self._validate_metadata(handoff.get('metadata', {}), results)
        self._validate_context(handoff.get('context_summary', ''), results)
        self._validate_next_steps(handoff.get('next_steps', []), results)
        self._validate_state(handoff.get('current_state', {}), results)

        # Check for completeness
        self._check_completeness(handoff, results)

        return results

    def _validate_metadata(self, metadata, results):
        """Validate metadata completeness"""
        required_meta = ['id', 'timestamp', 'source_agent', 'target_agent']

        for field in required_meta:
            if field not in metadata:
                results['warnings'].append(f"Metadata missing: {field}")
                results['score'] -= 2

    def _validate_context(self, context, results):
        """Validate context quality"""
        if isinstance(context, str) and len(context) < 100:
            results['warnings'].append("Context summary too brief")
            results['suggestions'].append("Provide more detailed context summary")

        if isinstance(context, dict):
            if 'summary' not in context or 'key_facts' not in context:
                results['warnings'].append("Context missing summary or key facts")

    def _validate_next_steps(self, next_steps, results):
        """Validate next steps clarity"""
        if not next_steps:
            results['errors'].append("No next steps provided")
            results['valid'] = False
            return

        for step in next_steps:
            if isinstance(step, str) and len(step) < 10:
                results['warnings'].append(f"Next step too vague: '{step}'")

            if isinstance(step, dict):
                if 'action' not in step:
                    results['warnings'].append("Next step missing 'action' field")
                if 'priority' not in step:
                    results['suggestions'].append("Consider adding priority to next steps")

    def _validate_state(self, state, results):
        """Validate state completeness"""
        if not state:
            results['warnings'].append("No state information provided")
            return

        # Check for common state elements
        if 'error_state' in state and state['error_state']:
            results['warnings'].append(f"Unresolved error state: {state['error_state']}")

        if 'progress' in state and state['progress'] < 10:
            results['warnings'].append("Very low progress - verify handoff timing")

    def _check_completeness(self, handoff, results):
        """Check overall completeness"""
        # Calculate completeness score
        total_fields = len(self.required_fields) + len(self.recommended_fields)
        present_fields = sum(1 for f in self.required_fields + self.recommended_fields
                           if f in handoff and handoff[f])
        completeness = present_fields / total_fields

        if completeness < 0.6:
            results['warnings'].append(f"Low completeness: {completeness:.0%}")
            results['suggestions'].append("Add more detail to improve handoff quality")

        # Check token count
        import json
        handoff_str = json.dumps(handoff)
        if len(handoff_str) < 500:
            results['warnings'].append("Handoff document seems too small")
        elif len(handoff_str) > 50000:
            results['warnings'].append("Handoff document very large - consider compression")

    def create_validation_report(self, results):
        """Create readable validation report"""
        report = f"""
Handoff Validation Report
========================
Valid: {results['valid']}
Score: {results['score']}/100
"""

        if results['errors']:
            report += "\n❌ Errors:\n"
            for error in results['errors']:
                report += f"  - {error}\n"

        if results['warnings']:
            report += "\n⚠️ Warnings:\n"
            for warning in results['warnings']:
                report += f"  - {warning}\n"

        if results['suggestions']:
            report += "\n💡 Suggestions:\n"
            for suggestion in results['suggestions']:
                report += f"  - {suggestion}\n"

        return report
```

## Context Reconstruction Errors

### The Problem

Errors occur when trying to reconstruct original context from compressed/chunked versions.

```python
# Original context with precise relationships
original = """
The user authentication module depends on the database module.
The database module requires configuration from the config module.
The config module loads environment variables at startup.
"""

# After compression and reconstruction - relationships lost!
reconstructed = """
Authentication uses database. Database needs configuration.
Config loads variables.
"""
# Lost: module relationships, timing (at startup), precise dependencies
```

### Preservation Strategies

```python
class ContextPreserver:
    def __init__(self):
        self.preservation_rules = {
            'relationships': self._preserve_relationships,
            'sequences': self._preserve_sequences,
            'hierarchies': self._preserve_hierarchies,
            'references': self._preserve_references
        }

    def compress_with_preservation(self, text, preserve=['relationships', 'sequences']):
        """Compress while preserving specified aspects"""
        preserved_elements = {}

        # Extract elements to preserve
        for aspect in preserve:
            if aspect in self.preservation_rules:
                preserved_elements[aspect] = self.preservation_rules[aspect](text)

        # Compress the text
        compressed = self._compress_text(text)

        # Inject preserved elements back
        compressed = self._inject_preserved(compressed, preserved_elements)

        # Add reconstruction hints
        compressed = self._add_reconstruction_hints(compressed, preserved_elements)

        return compressed

    def _preserve_relationships(self, text):
        """Extract and preserve relationships"""
        relationships = []

        # Pattern matching for relationships
        patterns = [
            r'(\w+)\s+depends on\s+(\w+)',
            r'(\w+)\s+requires\s+(\w+)',
            r'(\w+)\s+uses\s+(\w+)',
            r'(\w+)\s+->?\s+(\w+)',
        ]

        for pattern in patterns:
            matches = re.findall(pattern, text, re.IGNORECASE)
            for match in matches:
                relationships.append({
                    'source': match[0],
                    'target': match[1],
                    'type': 'dependency'
                })

        return relationships

    def _preserve_sequences(self, text):
        """Extract and preserve sequences/order"""
        sequences = []

        # Look for ordered lists
        ordered_patterns = [
            r'(?:^|\n)\d+\.\s+(.+)',          # 1. First step
            r'(?:^|\n)Step\s+\d+:\s+(.+)',    # Step 1: First
            r'(?:^|\n)(?:First|Second|Third|Then|Finally),?\s+(.+)',
        ]

        for pattern in ordered_patterns:
            matches = re.findall(pattern, text, re.MULTILINE)
            if matches:
                sequences.append(matches)

        return sequences

    def _add_reconstruction_hints(self, compressed, preserved):
        """Add hints for accurate reconstruction"""
        hints = []

        if preserved.get('relationships'):
            hints.append(f"[RELATIONSHIPS: {len(preserved['relationships'])} preserved]")

        if preserved.get('sequences'):
            hints.append(f"[SEQUENCES: {len(preserved['sequences'])} preserved]")

        if hints:
            return '\n'.join(hints) + '\n\n' + compressed

        return compressed

    def reconstruct(self, compressed, hints=None):
        """Reconstruct context with preserved elements"""
        reconstructed = compressed

        # Apply reconstruction hints
        if '[RELATIONSHIPS:' in reconstructed:
            reconstructed = self._reconstruct_relationships(reconstructed)

        if '[SEQUENCES:' in reconstructed:
            reconstructed = self._reconstruct_sequences(reconstructed)

        return reconstructed

    def validate_reconstruction(self, original, reconstructed):
        """Validate reconstruction accuracy"""
        issues = []

        # Check key terms preservation
        key_terms = self._extract_key_terms(original)
        for term in key_terms:
            if term not in reconstructed:
                issues.append(f"Lost key term: {term}")

        # Check relationship preservation
        original_rels = self._preserve_relationships(original)
        recon_rels = self._preserve_relationships(reconstructed)

        if len(recon_rels) < len(original_rels) * 0.8:
            issues.append("Significant relationship loss")

        return len(issues) == 0, issues
```

## Performance Degradation at Scale

### The Problem

Context engineering operations slow down significantly with large contexts.

```python
# Performance degrades non-linearly
small_context = "..." * 1000     # 1k chars - 10ms
medium_context = "..." * 10000   # 10k chars - 200ms
large_context = "..." * 100000   # 100k chars - 5000ms!
huge_context = "..." * 1000000   # 1M chars - timeout!
```

### Performance Optimization

```python
class PerformantContextProcessor:
    def __init__(self):
        self.cache = {}
        self.chunk_size = 10000  # Process in chunks

    def process_large_context(self, context):
        """Process large context efficiently"""
        import time
        start = time.time()

        # Check cache first
        cache_key = hashlib.md5(context.encode()).hexdigest()
        if cache_key in self.cache:
            print(f"Cache hit - returned in {time.time()-start:.2f}s")
            return self.cache[cache_key]

        # Process in parallel chunks
        chunks = self._split_into_chunks(context)
        results = self._process_chunks_parallel(chunks)

        # Combine results
        final_result = self._combine_results(results)

        # Cache for future use
        self.cache[cache_key] = final_result

        print(f"Processed in {time.time()-start:.2f}s")
        return final_result

    def _split_into_chunks(self, context):
        """Split context into processable chunks"""
        chunks = []
        for i in range(0, len(context), self.chunk_size):
            chunk = context[i:i+self.chunk_size]
            chunks.append(chunk)
        return chunks

    def _process_chunks_parallel(self, chunks):
        """Process chunks in parallel"""
        from concurrent.futures import ThreadPoolExecutor, as_completed
        import multiprocessing

        # Use thread pool for I/O bound, process pool for CPU bound
        max_workers = min(multiprocessing.cpu_count(), len(chunks))

        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            futures = {executor.submit(self._process_chunk, chunk): i
                      for i, chunk in enumerate(chunks)}

            results = [None] * len(chunks)
            for future in as_completed(futures):
                index = futures[future]
                results[index] = future.result()

        return results

    def _process_chunk(self, chunk):
        """Process individual chunk"""
        # Simulate processing
        import time
        time.sleep(0.01)  # Simulate work

        # Actual processing would go here
        return {
            'size': len(chunk),
            'tokens': len(chunk) // 4,
            'summary': chunk[:100]
        }

    def _combine_results(self, results):
        """Combine chunk results"""
        combined = {
            'total_size': sum(r['size'] for r in results),
            'total_tokens': sum(r['tokens'] for r in results),
            'summaries': [r['summary'] for r in results]
        }
        return combined

    def optimize_memory(self, context):
        """Optimize memory usage for large contexts"""
        import gc
        import sys

        # Process iteratively to avoid memory bloat
        if sys.getsizeof(context) > 100_000_000:  # >100MB
            # Use generator for processing
            return self._process_streaming(context)

        return self.process_large_context(context)

    def _process_streaming(self, context):
        """Stream process very large contexts"""
        def context_generator():
            for i in range(0, len(context), self.chunk_size):
                yield context[i:i+self.chunk_size]

        results = []
        for chunk in context_generator():
            result = self._process_chunk(chunk)
            results.append(result)

            # Aggressive garbage collection
            if len(results) % 10 == 0:
                import gc
                gc.collect()

        return self._combine_results(results)
```

### Profiling and Monitoring

```python
class PerformanceMonitor:
    def __init__(self):
        self.metrics = []

    def profile_operation(self, operation_name):
        """Decorator to profile operations"""
        def decorator(func):
            def wrapper(*args, **kwargs):
                import time
                import tracemalloc

                # Start profiling
                tracemalloc.start()
                start_time = time.time()
                start_memory = tracemalloc.get_traced_memory()[0]

                # Execute operation
                result = func(*args, **kwargs)

                # End profiling
                end_time = time.time()
                end_memory = tracemalloc.get_traced_memory()[0]
                tracemalloc.stop()

                # Record metrics
                self.metrics.append({
                    'operation': operation_name,
                    'duration': end_time - start_time,
                    'memory_used': end_memory - start_memory,
                    'timestamp': datetime.now()
                })

                # Warn if slow
                if end_time - start_time > 1.0:
                    print(f"⚠️ Slow operation: {operation_name} took {end_time-start_time:.2f}s")

                return result
            return wrapper
        return decorator

    def get_performance_report(self):
        """Generate performance report"""
        if not self.metrics:
            return "No metrics collected"

        report = "Performance Report\n==================\n"

        for metric in self.metrics[-10:]:  # Last 10 operations
            report += f"\n{metric['operation']}:\n"
            report += f"  Duration: {metric['duration']:.3f}s\n"
            report += f"  Memory: {metric['memory_used']/1024/1024:.1f}MB\n"

        # Calculate averages
        avg_duration = sum(m['duration'] for m in self.metrics) / len(self.metrics)
        avg_memory = sum(m['memory_used'] for m in self.metrics) / len(self.metrics)

        report += f"\nAverages:\n"
        report += f"  Duration: {avg_duration:.3f}s\n"
        report += f"  Memory: {avg_memory/1024/1024:.1f}MB\n"

        return report
```

## Debugging Strategies

### Comprehensive Debugging Toolkit

```python
class ContextDebugger:
    def __init__(self):
        self.debug_mode = True
        self.log = []

    def debug_compression(self, original, compressed):
        """Debug compression issues"""
        report = {
            'original_size': len(original),
            'compressed_size': len(compressed),
            'reduction': 1 - len(compressed)/len(original),
            'issues': []
        }

        # Check for information loss
        key_terms = self._extract_key_terms(original)
        lost_terms = [term for term in key_terms if term not in compressed]
        if lost_terms:
            report['issues'].append(f"Lost terms: {lost_terms}")

        # Check structure preservation
        original_structure = self._analyze_structure(original)
        compressed_structure = self._analyze_structure(compressed)

        if original_structure['paragraphs'] > 0:
            para_loss = 1 - compressed_structure['paragraphs']/original_structure['paragraphs']
            if para_loss > 0.5:
                report['issues'].append(f"Lost {para_loss:.0%} of paragraphs")

        return report

    def debug_token_count(self, text, expected_tokens):
        """Debug token counting issues"""
        import tiktoken

        models = ['gpt-4', 'gpt-3.5-turbo']
        counts = {}

        for model in models:
            try:
                enc = tiktoken.encoding_for_model(model)
                counts[model] = len(enc.encode(text))
            except:
                counts[model] = 'error'

        # Calculate variance
        valid_counts = [c for c in counts.values() if isinstance(c, int)]
        if valid_counts:
            min_count = min(valid_counts)
            max_count = max(valid_counts)
            variance = (max_count - min_count) / min_count if min_count > 0 else 0

            return {
                'counts': counts,
                'variance': variance,
                'expected': expected_tokens,
                'recommendation': max_count * 1.1  # Add 10% safety
            }

    def debug_handoff(self, handoff):
        """Debug handoff document issues"""
        issues = []

        # Check for circular references
        if self._has_circular_refs(handoff):
            issues.append("Circular references detected")

        # Check for missing context
        if 'context' in handoff:
            if len(str(handoff['context'])) < 100:
                issues.append("Context too brief")

        # Check for unserializable data
        try:
            import json
            json.dumps(handoff)
        except TypeError as e:
            issues.append(f"Unserializable data: {e}")

        return issues

    def debug_memory_usage(self):
        """Debug memory usage"""
        import psutil
        import gc

        process = psutil.Process()
        memory_info = process.memory_info()

        return {
            'rss': memory_info.rss / 1024 / 1024,  # MB
            'vms': memory_info.vms / 1024 / 1024,  # MB
            'percent': process.memory_percent(),
            'gc_stats': gc.get_stats()
        }

    def create_debug_report(self, operation, input_data, output_data, error=None):
        """Create comprehensive debug report"""
        report = f"""
Debug Report
============
Operation: {operation}
Timestamp: {datetime.now().isoformat()}

Input:
------
Size: {len(str(input_data))} chars
Type: {type(input_data).__name__}
Preview: {str(input_data)[:200]}...

Output:
-------
Size: {len(str(output_data))} chars
Type: {type(output_data).__name__}
Preview: {str(output_data)[:200]}...

Memory Usage:
------------
{self.debug_memory_usage()}

"""

        if error:
            report += f"""
Error:
------
{error}

Traceback:
----------
{traceback.format_exc()}
"""

        return report
```

## Best Practices Summary

### DO
1. ✅ **Validate all compressions** - Always check information preservation
2. ✅ **Use model-specific tokenizers** - Don't assume token counts are universal
3. ✅ **Add safety margins** - Budget 10-20% buffer for token counts
4. ✅ **Version your embeddings** - Track model versions and timestamps
5. ✅ **Test with edge cases** - Empty, null, very large, special characters
6. ✅ **Monitor performance** - Profile operations, especially at scale
7. ✅ **Validate handoffs** - Ensure complete state transfer
8. ✅ **Keep originals** - Maintain ability to recover from bad compression

### DON'T
1. ❌ **Don't compress blindly** - Understand what you're removing
2. ❌ **Don't mix embedding versions** - Results will be unreliable
3. ❌ **Don't ignore syntax boundaries** - Respect code structure
4. ❌ **Don't skip validation** - Catch issues early
5. ❌ **Don't hardcode limits** - Context windows change
6. ❌ **Don't process huge contexts synchronously** - Use chunking
7. ❌ **Don't trust approximate counts** - Use actual tokenizers
8. ❌ **Don't compress critical information** - Protect key details

---

*For implementation patterns, see [PATTERNS.md](PATTERNS.md). For theoretical background, see [KNOWLEDGE.md](KNOWLEDGE.md).*