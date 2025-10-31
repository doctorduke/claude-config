# Context Engineering Framework - Implementation Patterns

## Table of Contents

1. [Pattern 1: Token Budget Management](#pattern-1-token-budget-management)
2. [Pattern 2: Lossless Compression](#pattern-2-lossless-compression)
3. [Pattern 3: Lossy Compression](#pattern-3-lossy-compression)
4. [Pattern 4: Semantic Chunking](#pattern-4-semantic-chunking)
5. [Pattern 5: Progressive Summarization](#pattern-5-progressive-summarization)
6. [Pattern 6: Handoff Documents](#pattern-6-handoff-documents)
7. [When to Use Each Pattern](#when-to-use-each-pattern)
8. [Token Optimization Strategies](#token-optimization-strategies)

## Pattern 1: Token Budget Management

### Overview

Track and enforce token usage across all context components. Implement alerts before reaching limits and hard boundaries to prevent overflow.

### Implementation

```python
class TokenBudgetManager:
    def __init__(self, model="gpt-4", total_tokens=100000):
        self.model = model
        self.total_tokens = total_tokens
        self.allocations = {}
        self.usage = {}
        self.alerts = {
            'warning': 0.8,  # 80% threshold
            'critical': 0.9,  # 90% threshold
            'overflow': 1.0   # 100% threshold
        }

    def allocate(self, component, tokens):
        """Allocate tokens to a component"""
        if sum(self.allocations.values()) + tokens > self.total_tokens:
            raise ValueError(f"Allocation exceeds total budget")
        self.allocations[component] = tokens
        self.usage[component] = 0

    def use(self, component, text):
        """Track token usage for component"""
        import tiktoken
        enc = tiktoken.encoding_for_model(self.model)
        tokens = len(enc.encode(text))

        if component not in self.allocations:
            raise ValueError(f"No allocation for {component}")

        self.usage[component] += tokens

        # Check component budget
        if self.usage[component] > self.allocations[component]:
            self.handle_overflow(component)

        # Check total budget
        total_used = sum(self.usage.values())
        utilization = total_used / self.total_tokens

        for level, threshold in self.alerts.items():
            if utilization >= threshold:
                self.trigger_alert(level, utilization)

        return tokens

    def handle_overflow(self, component):
        """Handle component budget overflow"""
        overflow = self.usage[component] - self.allocations[component]

        # Try to borrow from buffer
        if 'buffer' in self.allocations:
            available = self.allocations['buffer'] - self.usage.get('buffer', 0)
            if available >= overflow:
                self.usage['buffer'] = self.usage.get('buffer', 0) + overflow
                return

        # Force compression
        raise TokenBudgetExceeded(f"{component} exceeded budget by {overflow} tokens")

    def trigger_alert(self, level, utilization):
        """Trigger budget alerts"""
        if level == 'warning':
            print(f"⚠️ Token budget at {utilization:.0%}")
        elif level == 'critical':
            print(f"🚨 CRITICAL: Token budget at {utilization:.0%}")
            self.emergency_compress()
        elif level == 'overflow':
            raise TokenBudgetExceeded(f"Token limit exceeded: {utilization:.0%}")

    def emergency_compress(self):
        """Emergency compression when approaching limit"""
        # Compress largest components first
        sorted_usage = sorted(self.usage.items(), key=lambda x: x[1], reverse=True)
        for component, tokens in sorted_usage:
            if component not in ['system', 'critical']:  # Don't compress critical
                print(f"Emergency compressing {component}")
                # Trigger compression for component
                break

    def get_status(self):
        """Get current budget status"""
        total_allocated = sum(self.allocations.values())
        total_used = sum(self.usage.values())
        return {
            'allocated': total_allocated,
            'used': total_used,
            'available': self.total_tokens - total_used,
            'utilization': total_used / self.total_tokens,
            'components': {
                k: {'allocated': self.allocations.get(k, 0),
                    'used': self.usage.get(k, 0),
                    'remaining': self.allocations.get(k, 0) - self.usage.get(k, 0)}
                for k in set(self.allocations.keys()) | set(self.usage.keys())
            }
        }
```

### Usage Example

```python
# Initialize budget manager
budget = TokenBudgetManager(model="gpt-4", total_tokens=100000)

# Allocate tokens to components
budget.allocate('system_prompt', 2000)
budget.allocate('working_memory', 30000)
budget.allocate('documents', 40000)
budget.allocate('conversation', 20000)
budget.allocate('buffer', 8000)

# Track usage
budget.use('system_prompt', system_instructions)
budget.use('documents', reference_docs)
budget.use('conversation', chat_history)

# Check status
status = budget.get_status()
print(f"Token utilization: {status['utilization']:.1%}")
print(f"Remaining tokens: {status['available']:,}")
```

## Pattern 2: Lossless Compression

### Overview

Remove redundancy without losing any information. Techniques include deduplication, reference extraction, and formatting normalization.

### Implementation

```python
class LosslessCompressor:
    def __init__(self):
        self.references = {}
        self.ref_counter = 0

    def compress(self, text):
        """Apply lossless compression techniques"""
        text = self.remove_excess_whitespace(text)
        text = self.deduplicate_lines(text)
        text = self.extract_references(text)
        text = self.normalize_formatting(text)
        return text

    def remove_excess_whitespace(self, text):
        """Remove unnecessary whitespace while preserving structure"""
        import re

        # Multiple spaces to single (except in code blocks)
        text = re.sub(r'(?<!^```[\s\S]*?) {2,}', ' ', text)

        # Multiple newlines to double (preserve paragraph breaks)
        text = re.sub(r'\n{3,}', '\n\n', text)

        # Remove trailing whitespace
        text = '\n'.join(line.rstrip() for line in text.split('\n'))

        return text

    def deduplicate_lines(self, text):
        """Remove exact duplicate lines"""
        lines = text.split('\n')
        seen = set()
        deduped = []

        for line in lines:
            line_hash = hash(line.strip())
            if line_hash not in seen or not line.strip():
                seen.add(line_hash)
                deduped.append(line)
            # Keep track of duplicates for reference

        return '\n'.join(deduped)

    def extract_references(self, text, min_length=50, min_occurrences=3):
        """Extract repeated phrases as references"""
        import re
        from collections import Counter

        # Find repeated phrases
        phrases = re.findall(r'[^.!?]{' + str(min_length) + r',}[.!?]', text)
        phrase_counts = Counter(phrases)

        # Extract frequently repeated phrases
        compressed = text
        for phrase, count in phrase_counts.items():
            if count >= min_occurrences:
                self.ref_counter += 1
                ref_id = f"[REF{self.ref_counter}]"
                self.references[ref_id] = phrase

                # Replace with reference
                compressed = compressed.replace(phrase, ref_id)

        # Add reference section if needed
        if self.references:
            ref_section = "\n\n## References\n"
            for ref_id, content in self.references.items():
                ref_section += f"{ref_id}: {content}\n"
            compressed = ref_section + "\n" + compressed

        return compressed

    def normalize_formatting(self, text):
        """Normalize formatting for consistency"""
        import re

        # Normalize quotes
        text = re.sub(r'[""]', '"', text)
        text = re.sub(r'['']', "'", text)

        # Normalize dashes
        text = re.sub(r'—|–', '-', text)

        # Normalize ellipsis
        text = re.sub(r'\.{3,}', '...', text)

        return text

    def decompress(self, text):
        """Restore original text from compressed version"""
        # Restore references
        for ref_id, content in self.references.items():
            text = text.replace(ref_id, content)

        # Remove reference section
        import re
        text = re.sub(r'^## References\n.*?\n\n', '', text, flags=re.MULTILINE | re.DOTALL)

        return text
```

### Usage Example

```python
compressor = LosslessCompressor()

# Original text with redundancy
original = """
This is a test document with some repeated information.
This is a test document with some repeated information.
    There   are   multiple   spaces   here.


And multiple newlines above.

This long phrase about context engineering appears multiple times in the document and could be extracted as a reference. This long phrase about context engineering appears multiple times in the document and could be extracted as a reference. This long phrase about context engineering appears multiple times in the document and could be extracted as a reference.
"""

# Compress
compressed = compressor.compress(original)
print(f"Original: {len(original)} chars")
print(f"Compressed: {len(compressed)} chars")
print(f"Reduction: {(1 - len(compressed)/len(original)):.1%}")

# Decompress to verify lossless
restored = compressor.decompress(compressed)
```

## Pattern 3: Lossy Compression

### Overview

Apply semantic compression when some information loss is acceptable. Includes summarization, abstraction, and pruning.

### Implementation

```python
class LossyCompressor:
    def __init__(self, llm_client=None):
        self.llm_client = llm_client or OpenAI()
        self.compression_levels = {
            'light': 0.8,    # 80% of original
            'medium': 0.5,   # 50% of original
            'heavy': 0.3,    # 30% of original
            'extreme': 0.1   # 10% of original
        }

    def compress(self, text, level='medium', preserve_key_points=None):
        """Apply lossy compression at specified level"""
        target_ratio = self.compression_levels.get(level, 0.5)

        # Different strategies based on content type
        if self.is_code(text):
            return self.compress_code(text, target_ratio)
        elif self.is_conversation(text):
            return self.compress_conversation(text, target_ratio)
        else:
            return self.compress_prose(text, target_ratio, preserve_key_points)

    def compress_prose(self, text, target_ratio, preserve_key_points=None):
        """Compress prose text using summarization"""
        target_length = int(len(text) * target_ratio)

        prompt = f"""Compress the following text to approximately {target_ratio:.0%} of its original length.
Preserve the most important information and maintain coherence.

{f"MUST PRESERVE: {preserve_key_points}" if preserve_key_points else ""}

Text to compress:
{text}

Compressed version:"""

        response = self.llm_client.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": prompt}],
            max_tokens=target_length // 4  # Approximate tokens
        )

        return response.choices[0].message.content

    def compress_code(self, text, target_ratio):
        """Compress code by removing comments, docstrings, and verbose sections"""
        import ast
        import re

        compressed = text

        # Remove comments
        compressed = re.sub(r'#.*$', '', compressed, flags=re.MULTILINE)
        compressed = re.sub(r'/\*[\s\S]*?\*/', '', compressed)
        compressed = re.sub(r'//.*$', '', compressed, flags=re.MULTILINE)

        # Remove docstrings (Python)
        compressed = re.sub(r'"""[\s\S]*?"""', '"""..."""', compressed)
        compressed = re.sub(r"'''[\s\S]*?'''", "'''...'''", compressed)

        # Compress whitespace
        compressed = re.sub(r'\n\s*\n', '\n', compressed)

        # If still too large, abstract functions
        if len(compressed) > len(text) * target_ratio:
            compressed = self.abstract_code(compressed, target_ratio)

        return compressed

    def abstract_code(self, code, target_ratio):
        """Abstract code to signatures and key logic"""
        abstracted = []

        for line in code.split('\n'):
            # Keep imports, class definitions, function signatures
            if any(line.strip().startswith(kw) for kw in ['import', 'from', 'class', 'def']):
                abstracted.append(line)
            # Keep key control flow
            elif any(kw in line for kw in ['if __name__', 'return', 'raise', 'yield']):
                abstracted.append(line)

        result = '\n'.join(abstracted)

        # Add note about abstraction
        result = f"# Code abstracted to {target_ratio:.0%}\n# Showing signatures and key logic only\n\n" + result

        return result

    def compress_conversation(self, text, target_ratio):
        """Compress conversation by summarizing older exchanges"""
        messages = text.split('\n\n')
        total_messages = len(messages)

        # Keep recent messages intact
        recent_count = max(2, int(total_messages * target_ratio))
        recent = messages[-recent_count:]
        older = messages[:-recent_count]

        if older:
            # Summarize older messages
            older_summary = self.summarize_exchanges(older)
            return older_summary + '\n\n' + '\n\n'.join(recent)

        return '\n\n'.join(recent)

    def summarize_exchanges(self, messages):
        """Summarize a list of conversation messages"""
        summary_points = []

        for i, msg in enumerate(messages):
            if 'User:' in msg or 'Assistant:' in msg:
                # Extract key point from each message
                key_point = self.extract_key_point(msg)
                if key_point:
                    summary_points.append(f"- {key_point}")

        return "## Previous Conversation Summary\n" + '\n'.join(summary_points)

    def extract_key_point(self, message):
        """Extract the key point from a message"""
        # Simple heuristic: first sentence or question
        import re
        sentences = re.split(r'[.!?]', message)
        if sentences:
            return sentences[0].strip()
        return None

    def is_code(self, text):
        """Detect if text is primarily code"""
        code_indicators = ['def ', 'class ', 'import ', 'function', '{', '}', ';']
        indicator_count = sum(1 for ind in code_indicators if ind in text)
        return indicator_count > len(code_indicators) / 2

    def is_conversation(self, text):
        """Detect if text is a conversation"""
        return 'User:' in text or 'Assistant:' in text or 'Human:' in text

    def prune_low_importance(self, text, importance_scorer):
        """Remove low-importance sections based on custom scorer"""
        sections = text.split('\n\n')
        scored = [(importance_scorer(s), s) for s in sections]
        scored.sort(reverse=True)

        # Keep top sections up to target
        result = []
        current_length = 0
        target_length = len(text) * 0.5

        for score, section in scored:
            if current_length + len(section) <= target_length:
                result.append(section)
                current_length += len(section)

        return '\n\n'.join(result)
```

## Pattern 4: Semantic Chunking

### Overview

Split context along natural semantic boundaries to maintain coherence within chunks and enable selective retrieval.

### Implementation

```python
class SemanticChunker:
    def __init__(self, embedding_model='text-embedding-ada-002'):
        self.embedding_model = embedding_model
        self.openai_client = OpenAI()

    def chunk(self, text, target_chunk_size=1000, overlap=100):
        """Split text into semantic chunks"""
        # First, split into sentences
        sentences = self.split_sentences(text)

        # Calculate embeddings for semantic similarity
        embeddings = self.get_embeddings(sentences)

        # Find semantic boundaries
        boundaries = self.find_semantic_boundaries(embeddings)

        # Create chunks based on boundaries
        chunks = self.create_chunks(sentences, boundaries, target_chunk_size, overlap)

        return chunks

    def split_sentences(self, text):
        """Split text into sentences"""
        import nltk
        nltk.download('punkt', quiet=True)

        sentences = nltk.sent_tokenize(text)
        return sentences

    def get_embeddings(self, sentences):
        """Get embeddings for sentences"""
        embeddings = []

        # Batch process for efficiency
        batch_size = 100
        for i in range(0, len(sentences), batch_size):
            batch = sentences[i:i+batch_size]
            response = self.openai_client.embeddings.create(
                model=self.embedding_model,
                input=batch
            )
            embeddings.extend([e.embedding for e in response.data])

        return embeddings

    def find_semantic_boundaries(self, embeddings, threshold=0.7):
        """Find boundaries where semantic similarity is low"""
        import numpy as np

        boundaries = [0]  # Start is always a boundary

        for i in range(1, len(embeddings)):
            # Calculate similarity with previous
            similarity = self.cosine_similarity(
                embeddings[i-1],
                embeddings[i]
            )

            # Mark boundary if similarity drops
            if similarity < threshold:
                boundaries.append(i)

        boundaries.append(len(embeddings))  # End is always a boundary
        return boundaries

    def cosine_similarity(self, a, b):
        """Calculate cosine similarity between vectors"""
        import numpy as np

        a = np.array(a)
        b = np.array(b)

        return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))

    def create_chunks(self, sentences, boundaries, target_size, overlap):
        """Create chunks from sentences and boundaries"""
        chunks = []

        for i in range(len(boundaries) - 1):
            start = boundaries[i]
            end = boundaries[i + 1]

            # Get sentences for this semantic section
            section_sentences = sentences[start:end]
            section_text = ' '.join(section_sentences)

            # If section is too large, split further
            if len(section_text) > target_size * 2:
                sub_chunks = self.split_by_size(section_text, target_size, overlap)
                chunks.extend(sub_chunks)
            else:
                # Add overlap from previous chunk if exists
                if chunks and overlap > 0:
                    prev_overlap = chunks[-1][-overlap:] if len(chunks[-1]) > overlap else chunks[-1]
                    section_text = prev_overlap + ' ' + section_text

                chunks.append(section_text)

        return chunks

    def split_by_size(self, text, target_size, overlap):
        """Split text by size when semantic chunking produces too large chunks"""
        chunks = []
        words = text.split()
        current_chunk = []
        current_size = 0

        for word in words:
            word_size = len(word) + 1  # +1 for space

            if current_size + word_size > target_size and current_chunk:
                # Save current chunk
                chunk_text = ' '.join(current_chunk)
                chunks.append(chunk_text)

                # Start new chunk with overlap
                if overlap > 0:
                    overlap_words = current_chunk[-(overlap//10):]  # Approximate word count
                    current_chunk = overlap_words + [word]
                    current_size = sum(len(w) + 1 for w in current_chunk)
                else:
                    current_chunk = [word]
                    current_size = word_size
            else:
                current_chunk.append(word)
                current_size += word_size

        # Add final chunk
        if current_chunk:
            chunks.append(' '.join(current_chunk))

        return chunks

    def chunk_with_hierarchy(self, text):
        """Create hierarchical chunks for multi-level retrieval"""
        # Level 1: Entire document
        level1 = [text]

        # Level 2: Major sections (paragraphs/headers)
        level2 = text.split('\n\n')

        # Level 3: Semantic chunks
        level3 = self.chunk(text, target_chunk_size=500, overlap=50)

        # Level 4: Sentences
        level4 = self.split_sentences(text)

        return {
            'document': level1,
            'sections': level2,
            'chunks': level3,
            'sentences': level4
        }
```

## Pattern 5: Progressive Summarization

### Overview

Create multiple levels of summarization, from detailed to brief, enabling drill-down when needed.

### Implementation

```python
class ProgressiveSummarizer:
    def __init__(self, llm_client=None):
        self.llm_client = llm_client or OpenAI()
        self.levels = {
            'detailed': 0.7,    # 70% of original
            'standard': 0.4,    # 40% of original
            'brief': 0.15,      # 15% of original
            'bullets': 0.05     # 5% of original (key points only)
        }

    def summarize_progressive(self, text, max_levels=3):
        """Create progressive summaries at multiple levels"""
        summaries = {}
        current_text = text

        level_names = list(self.levels.keys())[:max_levels]

        for level_name in level_names:
            ratio = self.levels[level_name]
            summary = self.summarize_at_level(current_text, level_name, ratio)
            summaries[level_name] = summary
            current_text = summary  # Next level summarizes previous

        return summaries

    def summarize_at_level(self, text, level_name, target_ratio):
        """Summarize text at specific level"""
        target_length = int(len(text) * target_ratio)

        if level_name == 'bullets':
            return self.extract_bullet_points(text)

        prompt = self.get_summary_prompt(text, level_name, target_length)

        response = self.llm_client.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": prompt}],
            max_tokens=target_length // 4
        )

        return response.choices[0].message.content

    def get_summary_prompt(self, text, level_name, target_length):
        """Get appropriate prompt for summary level"""
        prompts = {
            'detailed': f"""Create a detailed summary that preserves most important information, examples, and context.
Target length: ~{target_length} characters.

Text:
{text}

Detailed summary:""",

            'standard': f"""Create a standard summary focusing on main points and key details.
Target length: ~{target_length} characters.

Text:
{text}

Standard summary:""",

            'brief': f"""Create a brief summary with only the most essential information.
Target length: ~{target_length} characters.

Text:
{text}

Brief summary:"""
        }

        return prompts.get(level_name, prompts['standard'])

    def extract_bullet_points(self, text):
        """Extract key points as bullets"""
        prompt = f"""Extract the 5-7 most important points from this text as bullet points.

Text:
{text}

Key points:
•"""

        response = self.llm_client.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": prompt}],
            max_tokens=200
        )

        return "• " + response.choices[0].message.content

    def create_recursive_summary(self, text, chunk_size=2000):
        """Recursively summarize by chunks then summarize summaries"""
        # Split into chunks
        chunks = [text[i:i+chunk_size] for i in range(0, len(text), chunk_size)]

        if len(chunks) == 1:
            # Base case: single chunk
            return self.summarize_at_level(chunks[0], 'standard', 0.4)

        # Summarize each chunk
        chunk_summaries = []
        for chunk in chunks:
            summary = self.summarize_at_level(chunk, 'standard', 0.4)
            chunk_summaries.append(summary)

        # Recursively summarize the summaries
        combined = '\n\n'.join(chunk_summaries)
        return self.create_recursive_summary(combined, chunk_size)

    def create_incremental_summary(self, messages):
        """Incrementally build summary as messages are added"""
        summary = ""

        for message in messages:
            # Append new message to existing summary
            combined = summary + "\n\n" + message if summary else message

            # Re-summarize if getting too long
            if len(combined) > 2000:
                summary = self.summarize_at_level(combined, 'standard', 0.4)
            else:
                summary = combined

        return summary

    def hierarchical_summary(self, document):
        """Create hierarchical summary preserving document structure"""
        import re

        # Split by headers (markdown style)
        sections = re.split(r'^#{1,3} ', document, flags=re.MULTILINE)

        summaries = {}
        for section in sections:
            if not section.strip():
                continue

            # Get section title (first line)
            lines = section.split('\n')
            title = lines[0] if lines else 'Untitled'
            content = '\n'.join(lines[1:]) if len(lines) > 1 else ''

            # Summarize section
            if content:
                section_summary = self.summarize_at_level(content, 'brief', 0.3)
                summaries[title] = section_summary

        # Create overall summary
        overall = '\n'.join(f"**{title}**: {summary}"
                          for title, summary in summaries.items())

        return {
            'sections': summaries,
            'overall': self.summarize_at_level(overall, 'brief', 0.2)
        }
```

## Pattern 6: Handoff Documents

### Overview

Create comprehensive handoff documents that capture complete state for work continuation between agents or sessions.

### Implementation

```python
class HandoffDocumentGenerator:
    def __init__(self):
        self.template = {
            'metadata': {},
            'context_summary': '',
            'completed_work': [],
            'current_state': {},
            'next_steps': [],
            'constraints': [],
            'decisions_made': [],
            'open_questions': [],
            'references': {},
            'checkpoints': []
        }

    def create_handoff(self, state, next_agent=None, **kwargs):
        """Create comprehensive handoff document"""
        handoff = self.template.copy()

        # Metadata
        handoff['metadata'] = self.generate_metadata(next_agent)

        # Context summary
        handoff['context_summary'] = self.summarize_context(state.get('context', ''))

        # Work tracking
        handoff['completed_work'] = state.get('completed_tasks', [])
        handoff['current_state'] = self.capture_current_state(state)
        handoff['next_steps'] = self.identify_next_steps(state)

        # Constraints and decisions
        handoff['constraints'] = state.get('constraints', [])
        handoff['decisions_made'] = self.extract_decisions(state)
        handoff['open_questions'] = state.get('open_questions', [])

        # References
        handoff['references'] = self.extract_references(state)

        # Checkpoints for resume
        handoff['checkpoints'] = self.create_checkpoints(state)

        # Additional custom fields
        for key, value in kwargs.items():
            handoff[key] = value

        return self.format_handoff(handoff)

    def generate_metadata(self, next_agent):
        """Generate handoff metadata"""
        from datetime import datetime
        import uuid

        return {
            'handoff_id': str(uuid.uuid4()),
            'timestamp': datetime.utcnow().isoformat(),
            'source_agent': 'current_agent',  # Would be dynamically set
            'target_agent': next_agent,
            'version': '1.0',
            'token_count': 0  # Will be calculated
        }

    def summarize_context(self, context):
        """Create context summary for handoff"""
        if not context:
            return "No context provided"

        # Use progressive summarization
        summarizer = ProgressiveSummarizer()
        summaries = summarizer.summarize_progressive(context, max_levels=2)

        return {
            'brief': summaries.get('brief', ''),
            'detailed': summaries.get('detailed', context[:1000])  # Fallback
        }

    def capture_current_state(self, state):
        """Capture all relevant current state"""
        return {
            'working_memory': state.get('working_memory', {}),
            'active_task': state.get('active_task', None),
            'progress': state.get('progress', 0),
            'variables': state.get('variables', {}),
            'flags': state.get('flags', {}),
            'error_state': state.get('last_error', None)
        }

    def identify_next_steps(self, state):
        """Identify clear next steps from state"""
        next_steps = []

        # From explicit next steps
        if 'next_steps' in state:
            next_steps.extend(state['next_steps'])

        # From remaining tasks
        if 'remaining_tasks' in state:
            for task in state['remaining_tasks'][:5]:  # Top 5
                next_steps.append({
                    'action': task.get('action', 'Unknown'),
                    'priority': task.get('priority', 'medium'),
                    'dependencies': task.get('dependencies', []),
                    'estimated_tokens': task.get('estimated_tokens', 1000)
                })

        return next_steps

    def extract_decisions(self, state):
        """Extract decisions made during work"""
        decisions = []

        if 'decision_log' in state:
            for decision in state['decision_log']:
                decisions.append({
                    'decision': decision.get('description', ''),
                    'rationale': decision.get('rationale', ''),
                    'timestamp': decision.get('timestamp', ''),
                    'impact': decision.get('impact', 'unknown')
                })

        return decisions

    def extract_references(self, state):
        """Extract important references"""
        references = {}

        # File references
        if 'files' in state:
            references['files'] = state['files']

        # Code references
        if 'code_refs' in state:
            references['code'] = state['code_refs']

        # Documentation references
        if 'docs' in state:
            references['documentation'] = state['docs']

        # External references
        if 'urls' in state:
            references['external'] = state['urls']

        return references

    def create_checkpoints(self, state):
        """Create resumable checkpoints"""
        checkpoints = []

        # Create checkpoint for current position
        checkpoint = {
            'id': 'current',
            'description': 'Current work position',
            'state_hash': hash(str(state)),
            'can_resume': True,
            'resume_instructions': self.generate_resume_instructions(state)
        }
        checkpoints.append(checkpoint)

        # Add any saved checkpoints
        if 'checkpoints' in state:
            checkpoints.extend(state['checkpoints'])

        return checkpoints

    def generate_resume_instructions(self, state):
        """Generate specific instructions for resuming work"""
        instructions = []

        # Based on current task
        if state.get('active_task'):
            instructions.append(f"Resume task: {state['active_task']}")

        # Based on error state
        if state.get('last_error'):
            instructions.append(f"Address error: {state['last_error']}")

        # Based on next steps
        if state.get('next_steps'):
            instructions.append(f"Continue with: {state['next_steps'][0]}")

        return ' '.join(instructions) if instructions else "Review state and continue"

    def format_handoff(self, handoff):
        """Format handoff document for readability"""
        import json
        from datetime import datetime

        formatted = f"""# Handoff Document

## Metadata
- **ID**: {handoff['metadata']['handoff_id']}
- **Timestamp**: {handoff['metadata']['timestamp']}
- **Target Agent**: {handoff['metadata'].get('target_agent', 'Any')}

## Context Summary

### Brief Overview
{handoff['context_summary'].get('brief', 'N/A') if isinstance(handoff['context_summary'], dict) else handoff['context_summary']}

### Detailed Context
{handoff['context_summary'].get('detailed', '')[:500] if isinstance(handoff['context_summary'], dict) else ''}...

## Work Status

### Completed Work
"""
        for item in handoff['completed_work']:
            formatted += f"- ✅ {item}\n"

        formatted += f"""
### Current State
- **Active Task**: {handoff['current_state'].get('active_task', 'None')}
- **Progress**: {handoff['current_state'].get('progress', 0)}%
- **Error State**: {handoff['current_state'].get('error_state', 'None')}

### Next Steps
"""
        for step in handoff['next_steps']:
            if isinstance(step, dict):
                formatted += f"- {step.get('action', step)}"
                if step.get('priority'):
                    formatted += f" (Priority: {step['priority']})"
                formatted += "\n"
            else:
                formatted += f"- {step}\n"

        formatted += """
## Constraints & Decisions

### Active Constraints
"""
        for constraint in handoff['constraints']:
            formatted += f"- ⚠️ {constraint}\n"

        formatted += "\n### Decisions Made\n"
        for decision in handoff['decisions_made']:
            if isinstance(decision, dict):
                formatted += f"- **{decision.get('decision', '')}**"
                if decision.get('rationale'):
                    formatted += f": {decision['rationale']}"
                formatted += "\n"
            else:
                formatted += f"- {decision}\n"

        formatted += "\n### Open Questions\n"
        for question in handoff['open_questions']:
            formatted += f"- ❓ {question}\n"

        # Add references if present
        if handoff['references']:
            formatted += "\n## References\n"
            formatted += json.dumps(handoff['references'], indent=2)

        # Add resume instructions
        if handoff['checkpoints']:
            formatted += "\n## Resume Instructions\n"
            for checkpoint in handoff['checkpoints']:
                formatted += f"### {checkpoint.get('description', 'Checkpoint')}\n"
                formatted += f"{checkpoint.get('resume_instructions', '')}\n\n"

        # Calculate and add token count
        import tiktoken
        enc = tiktoken.encoding_for_model("gpt-4")
        token_count = len(enc.encode(formatted))
        handoff['metadata']['token_count'] = token_count

        formatted += f"\n---\n*Handoff document: {token_count} tokens*"

        return formatted

    def validate_handoff(self, handoff_doc):
        """Validate handoff document completeness"""
        required_fields = [
            'metadata', 'context_summary', 'current_state',
            'next_steps'
        ]

        validation_results = {
            'valid': True,
            'missing_fields': [],
            'warnings': []
        }

        # Check required fields
        for field in required_fields:
            if field not in handoff_doc or not handoff_doc[field]:
                validation_results['valid'] = False
                validation_results['missing_fields'].append(field)

        # Check token count
        if 'metadata' in handoff_doc:
            token_count = handoff_doc['metadata'].get('token_count', 0)
            if token_count > 10000:
                validation_results['warnings'].append(
                    f"Handoff document is large: {token_count} tokens"
                )

        # Check next steps
        if not handoff_doc.get('next_steps'):
            validation_results['warnings'].append(
                "No next steps defined - receiver may not know how to proceed"
            )

        return validation_results
```

## When to Use Each Pattern

### Decision Matrix

| Scenario | Recommended Pattern | Why |
|----------|-------------------|-----|
| **Approaching token limit** | Token Budget Management | Prevent overflow, trigger compression |
| **Repeated content** | Lossless Compression | No information loss |
| **Very long context** | Lossy Compression | Acceptable trade-off |
| **Document retrieval** | Semantic Chunking | Maintain coherence |
| **Multi-level detail needed** | Progressive Summarization | Flexible depth |
| **Agent handoff** | Handoff Documents | Complete state transfer |
| **Cost optimization** | Lossy Compression + Budget | Reduce tokens aggressively |
| **High-precision tasks** | Lossless only | Preserve all details |
| **Long conversations** | Progressive + Sliding Window | Maintain relevance |
| **Multi-document QA** | Semantic Chunking + RAG | Selective retrieval |

## Token Optimization Strategies

### Strategy 1: Tiered Compression

```python
def tiered_compression(context, current_tokens, target_tokens):
    """Apply increasingly aggressive compression"""
    strategies = [
        ('lossless', 0.9),      # Try lossless first
        ('light_summary', 0.7),  # Light summarization
        ('heavy_summary', 0.4),  # Heavy summarization
        ('critical_only', 0.2)   # Keep only critical
    ]

    for strategy, expected_ratio in strategies:
        compressed = apply_strategy(context, strategy)
        new_tokens = count_tokens(compressed)

        if new_tokens <= target_tokens:
            return compressed

        context = compressed  # Try next level

    return context  # Return best effort
```

### Strategy 2: Component Prioritization

```python
def prioritize_components(components, token_budget):
    """Allocate tokens by priority"""
    priorities = {
        'system_prompt': 10,      # Highest priority
        'active_task': 9,
        'recent_context': 8,
        'key_decisions': 7,
        'reference_docs': 5,
        'historical_context': 3,
        'examples': 2             # Lowest priority
    }

    # Sort by priority
    sorted_components = sorted(
        components.items(),
        key=lambda x: priorities.get(x[0], 0),
        reverse=True
    )

    result = {}
    remaining_budget = token_budget

    for name, content in sorted_components:
        tokens = count_tokens(content)

        if tokens <= remaining_budget:
            result[name] = content
            remaining_budget -= tokens
        elif remaining_budget > 1000:  # Try compression
            compressed = compress_to_fit(content, remaining_budget)
            result[name] = compressed
            remaining_budget -= count_tokens(compressed)

    return result
```

### Strategy 3: Adaptive Context Window

```python
class AdaptiveContextWindow:
    """Dynamically adjust context based on task needs"""

    def __init__(self, base_window=50000):
        self.base_window = base_window
        self.task_profiles = {
            'code_review': {'code': 0.6, 'context': 0.3, 'history': 0.1},
            'qa_session': {'docs': 0.5, 'history': 0.3, 'context': 0.2},
            'planning': {'requirements': 0.4, 'context': 0.4, 'examples': 0.2}
        }

    def optimize_for_task(self, task_type, available_content):
        """Optimize context for specific task type"""
        profile = self.task_profiles.get(task_type, {})

        optimized = {}
        for content_type, ratio in profile.items():
            if content_type in available_content:
                target_tokens = int(self.base_window * ratio)
                content = available_content[content_type]

                # Fit content to allocation
                if count_tokens(content) > target_tokens:
                    content = compress_to_fit(content, target_tokens)

                optimized[content_type] = content

        return optimized
```

---

*These patterns provide the implementation foundation for the Context Engineering Framework. For theoretical background, see [KNOWLEDGE.md](KNOWLEDGE.md).*