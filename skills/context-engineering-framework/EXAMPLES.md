# Context Engineering Framework - Working Examples

## Table of Contents

1. [Example 1: Token Budget Tracker with Alerts](#example-1-token-budget-tracker-with-alerts)
2. [Example 2: Context Compressor (50%+ Reduction)](#example-2-context-compressor-50-reduction)
3. [Example 3: Semantic Chunker for Large Documents](#example-3-semantic-chunker-for-large-documents)
4. [Example 4: Progressive Summarizer (3 Levels)](#example-4-progressive-summarizer-3-levels)
5. [Example 5: Handoff Document Generator](#example-5-handoff-document-generator)
6. [Example 6: Context Window Optimizer](#example-6-context-window-optimizer)
7. [Real-World Use Cases](#real-world-use-cases)

## Example 1: Token Budget Tracker with Alerts

Track token usage across multiple components with automatic alerts and overflow handling.

```python
import tiktoken
from typing import Dict, Optional
from datetime import datetime

class TokenBudgetTracker:
    """Production-ready token budget tracker with alerts"""

    def __init__(self, model: str = "gpt-4", total_budget: int = 100000):
        self.model = model
        self.encoder = tiktoken.encoding_for_model(model)
        self.total_budget = total_budget
        self.allocations: Dict[str, int] = {}
        self.usage: Dict[str, int] = {}
        self.history = []
        self.alerts_triggered = set()

    def allocate(self, component: str, tokens: int) -> bool:
        """Allocate tokens to a component"""
        current_allocated = sum(self.allocations.values())
        if current_allocated + tokens > self.total_budget:
            print(f"❌ Cannot allocate {tokens} tokens to {component}")
            print(f"   Available: {self.total_budget - current_allocated}")
            return False

        self.allocations[component] = tokens
        self.usage[component] = 0
        print(f"✅ Allocated {tokens:,} tokens to {component}")
        return True

    def use(self, component: str, content: str) -> Dict:
        """Use tokens from component allocation"""
        if component not in self.allocations:
            raise ValueError(f"Component '{component}' has no allocation")

        # Count tokens
        tokens = len(self.encoder.encode(content))

        # Update usage
        self.usage[component] = self.usage.get(component, 0) + tokens

        # Log to history
        self.history.append({
            'timestamp': datetime.now(),
            'component': component,
            'tokens': tokens,
            'content_preview': content[:100]
        })

        # Check thresholds
        self._check_alerts()

        return {
            'component': component,
            'tokens_used': tokens,
            'component_usage': self.usage[component],
            'component_allocation': self.allocations[component],
            'component_utilization': self.usage[component] / self.allocations[component],
            'total_usage': sum(self.usage.values()),
            'total_utilization': sum(self.usage.values()) / self.total_budget
        }

    def _check_alerts(self):
        """Check and trigger alerts"""
        total_usage = sum(self.usage.values())
        utilization = total_usage / self.total_budget

        # System-wide alerts
        if utilization >= 0.8 and 'warning_80' not in self.alerts_triggered:
            self.alerts_triggered.add('warning_80')
            print(f"⚠️ WARNING: Token usage at {utilization:.0%} ({total_usage:,}/{self.total_budget:,})")

        if utilization >= 0.9 and 'critical_90' not in self.alerts_triggered:
            self.alerts_triggered.add('critical_90')
            print(f"🚨 CRITICAL: Token usage at {utilization:.0%}")
            self._trigger_emergency_compression()

        if utilization >= 1.0:
            raise TokenBudgetExceeded(f"Token budget exceeded: {total_usage:,} > {self.total_budget:,}")

        # Component-level alerts
        for component, used in self.usage.items():
            allocated = self.allocations.get(component, 0)
            if allocated and used > allocated * 0.9:
                alert_key = f"component_{component}_90"
                if alert_key not in self.alerts_triggered:
                    self.alerts_triggered.add(alert_key)
                    print(f"⚠️ Component '{component}' at {used/allocated:.0%} capacity")

    def _trigger_emergency_compression(self):
        """Emergency compression when approaching limits"""
        print("🔄 Initiating emergency compression...")

        # Find largest non-critical components
        compressible = [
            (comp, usage) for comp, usage in self.usage.items()
            if comp not in ['system', 'critical', 'active_task']
        ]
        compressible.sort(key=lambda x: x[1], reverse=True)

        if compressible:
            target = compressible[0][0]
            print(f"   Targeting '{target}' for compression (using {compressible[0][1]:,} tokens)")

    def get_report(self) -> str:
        """Generate usage report"""
        total_allocated = sum(self.allocations.values())
        total_used = sum(self.usage.values())

        report = f"""
Token Budget Report
==================
Model: {self.model}
Total Budget: {self.total_budget:,} tokens
Total Allocated: {total_allocated:,} tokens ({total_allocated/self.total_budget:.0%})
Total Used: {total_used:,} tokens ({total_used/self.total_budget:.0%})
Available: {self.total_budget - total_used:,} tokens

Component Breakdown:
"""
        for component in self.allocations:
            allocated = self.allocations[component]
            used = self.usage.get(component, 0)
            report += f"\n{component:20} | Allocated: {allocated:8,} | Used: {used:8,} | Utilization: {used/allocated:6.1%}"

        return report

class TokenBudgetExceeded(Exception):
    pass

# Usage Example
if __name__ == "__main__":
    # Initialize tracker
    tracker = TokenBudgetTracker(model="gpt-4", total_budget=100000)

    # Allocate budgets
    tracker.allocate("system_prompt", 2000)
    tracker.allocate("working_memory", 30000)
    tracker.allocate("reference_docs", 40000)
    tracker.allocate("conversation", 20000)
    tracker.allocate("buffer", 8000)

    # Simulate usage
    tracker.use("system_prompt", "You are a helpful assistant..." * 100)
    tracker.use("reference_docs", "Documentation content..." * 1000)
    tracker.use("conversation", "User: Hello\nAssistant: Hi!" * 500)

    # Get report
    print(tracker.get_report())
```

## Example 2: Context Compressor (50%+ Reduction)

Achieve 50%+ context compression while preserving critical information.

```python
import re
import hashlib
from collections import Counter
from typing import Dict, List, Tuple

class ContextCompressor:
    """Compress context by 50%+ while preserving information"""

    def __init__(self):
        self.compression_stats = {}
        self.reference_map = {}
        self.ref_counter = 0

    def compress(self, text: str, target_reduction: float = 0.5) -> str:
        """Compress text to achieve target reduction"""
        original_len = len(text)
        compressed = text

        # Apply compression techniques in order of information preservation
        techniques = [
            ("whitespace", self._compress_whitespace),
            ("deduplication", self._deduplicate),
            ("references", self._extract_references),
            ("abbreviations", self._apply_abbreviations),
            ("summarization", self._selective_summarization)
        ]

        for name, technique in techniques:
            before_len = len(compressed)
            compressed = technique(compressed)
            after_len = len(compressed)

            reduction = (before_len - after_len) / before_len if before_len > 0 else 0
            self.compression_stats[name] = reduction

            current_reduction = 1 - (after_len / original_len)
            if current_reduction >= target_reduction:
                break

        # Final stats
        final_reduction = 1 - (len(compressed) / original_len)
        self.compression_stats['total'] = final_reduction

        return self._add_compression_header(compressed, original_len)

    def _compress_whitespace(self, text: str) -> str:
        """Remove unnecessary whitespace"""
        # Multiple spaces to single
        text = re.sub(r' {2,}', ' ', text)
        # Multiple newlines to double
        text = re.sub(r'\n{3,}', '\n\n', text)
        # Remove trailing spaces
        text = '\n'.join(line.rstrip() for line in text.split('\n'))
        # Remove empty lines in code blocks
        text = re.sub(r'\n\s*\n\s*\n', '\n\n', text)
        return text

    def _deduplicate(self, text: str) -> str:
        """Remove duplicate content"""
        lines = text.split('\n')
        seen_hashes = set()
        deduped = []

        for line in lines:
            line_hash = hashlib.md5(line.strip().encode()).hexdigest()[:8]

            # Keep empty lines and unique content
            if not line.strip() or line_hash not in seen_hashes:
                deduped.append(line)
                if line.strip():
                    seen_hashes.add(line_hash)

        return '\n'.join(deduped)

    def _extract_references(self, text: str) -> str:
        """Extract repeated content as references"""
        # Find repeated sentences (3+ times)
        sentences = re.split(r'[.!?]+', text)
        sentence_counts = Counter(sentences)

        compressed = text
        for sentence, count in sentence_counts.items():
            if count >= 3 and len(sentence) > 50:
                self.ref_counter += 1
                ref_id = f"[REF{self.ref_counter}]"
                self.reference_map[ref_id] = sentence.strip()

                # Replace all but first occurrence
                first_occurrence = True
                def replace_fn(match):
                    nonlocal first_occurrence
                    if first_occurrence:
                        first_occurrence = False
                        return match.group(0)
                    return ref_id

                pattern = re.escape(sentence)
                compressed = re.sub(pattern, replace_fn, compressed)

        return compressed

    def _apply_abbreviations(self, text: str) -> str:
        """Apply common abbreviations"""
        abbreviations = {
            'function': 'fn',
            'variable': 'var',
            'constant': 'const',
            'configuration': 'config',
            'application': 'app',
            'database': 'db',
            'repository': 'repo',
            'development': 'dev',
            'production': 'prod',
            'environment': 'env'
        }

        for full, abbr in abbreviations.items():
            # Case-insensitive replacement
            text = re.sub(rf'\b{full}\b', abbr, text, flags=re.IGNORECASE)

        return text

    def _selective_summarization(self, text: str) -> str:
        """Summarize verbose sections"""
        # Identify verbose sections (paragraphs > 500 chars)
        paragraphs = text.split('\n\n')
        compressed_paragraphs = []

        for para in paragraphs:
            if len(para) > 500:
                # Simple extractive summarization
                sentences = re.split(r'[.!?]+', para)
                if len(sentences) > 3:
                    # Keep first, last, and most important sentence
                    important = max(sentences[1:-1], key=len) if len(sentences) > 2 else ""
                    summary = f"{sentences[0]}. {important}. {sentences[-1]}"
                    compressed_paragraphs.append(f"[SUMMARIZED] {summary}")
                else:
                    compressed_paragraphs.append(para)
            else:
                compressed_paragraphs.append(para)

        return '\n\n'.join(compressed_paragraphs)

    def _add_compression_header(self, text: str, original_len: int) -> str:
        """Add compression metadata header"""
        compression_ratio = 1 - (len(text) / original_len)
        header = f"""[COMPRESSED CONTEXT]
Original: {original_len:,} chars
Compressed: {len(text):,} chars
Reduction: {compression_ratio:.1%}
Techniques: {', '.join(k for k, v in self.compression_stats.items() if v > 0)}
"""
        # Add references if any
        if self.reference_map:
            header += "\nReferences:\n"
            for ref_id, content in self.reference_map.items():
                header += f"{ref_id}: {content[:50]}...\n"

        return header + "\n---\n" + text

    def decompress(self, compressed_text: str) -> str:
        """Restore original content from compressed version"""
        # Remove header
        if '[COMPRESSED CONTEXT]' in compressed_text:
            compressed_text = compressed_text.split('---\n', 1)[1]

        # Restore references
        for ref_id, content in self.reference_map.items():
            compressed_text = compressed_text.replace(ref_id, content)

        # Restore abbreviations (reverse mapping)
        reverse_abbr = {
            'fn': 'function',
            'var': 'variable',
            'const': 'constant',
            # ... etc
        }
        for abbr, full in reverse_abbr.items():
            compressed_text = re.sub(rf'\b{abbr}\b', full, compressed_text)

        return compressed_text

# Usage Example
if __name__ == "__main__":
    # Sample text with redundancy
    sample_text = """
    This is a comprehensive documentation about context engineering.
    Context engineering is crucial for managing large language model interactions.

    This is a comprehensive documentation about context engineering.
    We need to carefully manage our token budget to ensure efficient processing.

    The configuration file contains database settings and application parameters.
    The configuration should be updated in the production environment.
    Database connections must be properly configured in the configuration file.

    This is a comprehensive documentation about context engineering.
    The function processes input and returns output.
    Another function handles error cases.
    The main function coordinates everything.
    """ * 3  # Multiply to create more redundancy

    compressor = ContextCompressor()
    compressed = compressor.compress(sample_text, target_reduction=0.5)

    print("Original length:", len(sample_text))
    print("Compressed length:", len(compressed))
    print("Reduction:", f"{1 - len(compressed)/len(sample_text):.1%}")
    print("\nCompression stats:", compressor.compression_stats)
    print("\n" + "="*50)
    print("Compressed text preview:")
    print(compressed[:500])
```

## Example 3: Semantic Chunker for Large Documents

Split large documents into semantically coherent chunks for retrieval.

```python
import numpy as np
from typing import List, Dict, Tuple
from dataclasses import dataclass

@dataclass
class Chunk:
    text: str
    start_idx: int
    end_idx: int
    embedding: Optional[List[float]] = None
    metadata: Dict = None

class SemanticChunker:
    """Split documents into semantic chunks"""

    def __init__(self, chunk_size: int = 1000, overlap: int = 100):
        self.chunk_size = chunk_size
        self.overlap = overlap
        self.chunks: List[Chunk] = []

    def chunk_document(self, document: str) -> List[Chunk]:
        """Chunk document into semantic units"""
        # Split into sentences first
        sentences = self._split_sentences(document)

        # Group sentences into semantic chunks
        chunks = self._create_semantic_chunks(sentences)

        # Add overlap between chunks
        chunks = self._add_overlap(chunks)

        # Calculate embeddings for retrieval
        chunks = self._calculate_embeddings(chunks)

        self.chunks = chunks
        return chunks

    def _split_sentences(self, text: str) -> List[str]:
        """Split text into sentences"""
        import re

        # Simple sentence splitter (can use nltk for better results)
        sentences = re.split(r'(?<=[.!?])\s+', text)
        return [s.strip() for s in sentences if s.strip()]

    def _create_semantic_chunks(self, sentences: List[str]) -> List[Chunk]:
        """Group sentences into semantic chunks"""
        chunks = []
        current_chunk = []
        current_size = 0
        start_idx = 0

        for i, sentence in enumerate(sentences):
            sentence_size = len(sentence)

            # Check if adding sentence exceeds chunk size
            if current_size + sentence_size > self.chunk_size and current_chunk:
                # Save current chunk
                chunk_text = ' '.join(current_chunk)
                chunks.append(Chunk(
                    text=chunk_text,
                    start_idx=start_idx,
                    end_idx=i-1,
                    metadata={'sentence_count': len(current_chunk)}
                ))

                # Start new chunk
                current_chunk = [sentence]
                current_size = sentence_size
                start_idx = i
            else:
                current_chunk.append(sentence)
                current_size += sentence_size + 1  # +1 for space

        # Add final chunk
        if current_chunk:
            chunk_text = ' '.join(current_chunk)
            chunks.append(Chunk(
                text=chunk_text,
                start_idx=start_idx,
                end_idx=len(sentences)-1,
                metadata={'sentence_count': len(current_chunk)}
            ))

        return chunks

    def _add_overlap(self, chunks: List[Chunk]) -> List[Chunk]:
        """Add overlap between adjacent chunks"""
        if len(chunks) <= 1:
            return chunks

        overlapped_chunks = []
        for i, chunk in enumerate(chunks):
            text = chunk.text

            # Add overlap from previous chunk
            if i > 0 and self.overlap > 0:
                prev_text = chunks[i-1].text
                overlap_text = prev_text[-self.overlap:] if len(prev_text) > self.overlap else prev_text
                text = overlap_text + " ... " + text

            # Add overlap from next chunk
            if i < len(chunks) - 1 and self.overlap > 0:
                next_text = chunks[i+1].text
                overlap_text = next_text[:self.overlap] if len(next_text) > self.overlap else next_text
                text = text + " ... " + overlap_text

            overlapped_chunks.append(Chunk(
                text=text,
                start_idx=chunk.start_idx,
                end_idx=chunk.end_idx,
                metadata=chunk.metadata
            ))

        return overlapped_chunks

    def _calculate_embeddings(self, chunks: List[Chunk]) -> List[Chunk]:
        """Calculate embeddings for chunks (mock implementation)"""
        # In production, use actual embedding model
        for chunk in chunks:
            # Mock embedding - in reality, use OpenAI/Cohere/etc.
            chunk.embedding = self._mock_embedding(chunk.text)
        return chunks

    def _mock_embedding(self, text: str) -> List[float]:
        """Create mock embedding for demonstration"""
        # Simple hash-based mock embedding
        import hashlib
        hash_obj = hashlib.md5(text.encode())
        hash_hex = hash_obj.hexdigest()

        # Convert to float vector (mock 384 dimensions)
        embedding = []
        for i in range(0, min(len(hash_hex), 384), 2):
            if i < len(hash_hex) - 1:
                value = int(hash_hex[i:i+2], 16) / 255.0
                embedding.append(value)

        # Pad to 384 dimensions
        while len(embedding) < 384:
            embedding.append(0.0)

        return embedding

    def retrieve_similar_chunks(self, query: str, top_k: int = 5) -> List[Tuple[Chunk, float]]:
        """Retrieve chunks similar to query"""
        query_embedding = self._mock_embedding(query)

        # Calculate similarities
        similarities = []
        for chunk in self.chunks:
            if chunk.embedding:
                similarity = self._cosine_similarity(query_embedding, chunk.embedding)
                similarities.append((chunk, similarity))

        # Sort by similarity
        similarities.sort(key=lambda x: x[1], reverse=True)

        return similarities[:top_k]

    def _cosine_similarity(self, a: List[float], b: List[float]) -> float:
        """Calculate cosine similarity between vectors"""
        a_arr = np.array(a)
        b_arr = np.array(b)

        dot_product = np.dot(a_arr, b_arr)
        norm_a = np.linalg.norm(a_arr)
        norm_b = np.linalg.norm(b_arr)

        if norm_a == 0 or norm_b == 0:
            return 0.0

        return dot_product / (norm_a * norm_b)

# Usage Example
if __name__ == "__main__":
    # Sample large document
    document = """
    Introduction to Machine Learning

    Machine learning is a subset of artificial intelligence that enables systems to learn and improve from experience without being explicitly programmed. It focuses on developing computer programs that can access data and use it to learn for themselves.

    Types of Machine Learning

    There are three main types of machine learning: supervised learning, unsupervised learning, and reinforcement learning. Supervised learning uses labeled data to train models. The algorithm learns from training data that includes both the input and the desired output. Common applications include classification and regression problems.

    Unsupervised learning works with unlabeled data. The system tries to learn patterns and structures from the data without explicit instructions. Common techniques include clustering and dimensionality reduction. This approach is useful for exploratory data analysis and finding hidden patterns.

    Reinforcement learning is about taking suitable actions to maximize reward in a particular situation. It is employed by various software and machines to find the best possible behavior or path in a specific situation. The agent learns from the consequences of its actions rather than from explicit teaching.

    Deep Learning and Neural Networks

    Deep learning is a subset of machine learning that uses neural networks with multiple layers. These neural networks attempt to simulate the behavior of the human brain to "learn" from large amounts of data. While a neural network with a single layer can make approximate predictions, additional hidden layers help optimize accuracy.

    Applications in Real World

    Machine learning has numerous applications in the real world. In healthcare, it's used for disease diagnosis and drug discovery. In finance, it powers fraud detection and algorithmic trading. In transportation, it enables autonomous vehicles and route optimization. In retail, it drives recommendation systems and demand forecasting.
    """ * 5  # Multiply to make larger

    # Create chunker
    chunker = SemanticChunker(chunk_size=500, overlap=50)

    # Chunk the document
    chunks = chunker.chunk_document(document)

    print(f"Document split into {len(chunks)} chunks")
    print(f"Average chunk size: {np.mean([len(c.text) for c in chunks]):.0f} chars")

    # Show first few chunks
    for i, chunk in enumerate(chunks[:3]):
        print(f"\n--- Chunk {i+1} ---")
        print(f"Size: {len(chunk.text)} chars")
        print(f"Sentences: {chunk.metadata.get('sentence_count', 0)}")
        print(f"Text preview: {chunk.text[:150]}...")

    # Test retrieval
    query = "neural networks and deep learning"
    similar_chunks = chunker.retrieve_similar_chunks(query, top_k=3)

    print(f"\n\nTop chunks for query: '{query}'")
    for chunk, similarity in similar_chunks:
        print(f"\nSimilarity: {similarity:.3f}")
        print(f"Text: {chunk.text[:200]}...")
```

## Example 4: Progressive Summarizer (3 Levels)

Create multi-level summaries for flexible detail access.

```python
from typing import Dict, List, Optional
import re

class ProgressiveSummarizer:
    """Create progressive summaries at multiple detail levels"""

    def __init__(self):
        self.summaries = {}
        self.compression_ratios = {
            'detailed': 0.7,   # 70% of original
            'standard': 0.4,   # 40% of original
            'brief': 0.15      # 15% of original
        }

    def summarize(self, text: str, levels: int = 3) -> Dict[str, str]:
        """Create progressive summaries at specified levels"""
        self.summaries = {}
        current_text = text
        level_names = list(self.compression_ratios.keys())[:levels]

        for level_name in level_names:
            target_ratio = self.compression_ratios[level_name]
            summary = self._create_summary(current_text, level_name, target_ratio)
            self.summaries[level_name] = summary
            current_text = summary  # Next level summarizes this level

        return self.summaries

    def _create_summary(self, text: str, level: str, target_ratio: float) -> str:
        """Create summary at specific level"""
        if level == 'detailed':
            return self._detailed_summary(text, target_ratio)
        elif level == 'standard':
            return self._standard_summary(text, target_ratio)
        elif level == 'brief':
            return self._brief_summary(text, target_ratio)

    def _detailed_summary(self, text: str, target_ratio: float) -> str:
        """Create detailed summary preserving key information"""
        sentences = self._split_sentences(text)
        target_count = max(1, int(len(sentences) * target_ratio))

        # Score sentences by importance
        scored_sentences = self._score_sentences(sentences)

        # Select top sentences
        selected = sorted(scored_sentences[:target_count], key=lambda x: sentences.index(x[1]))
        summary = ' '.join([sent for _, sent in selected])

        return summary

    def _standard_summary(self, text: str, target_ratio: float) -> str:
        """Create standard summary with main points"""
        # Extract key points
        key_points = self._extract_key_points(text)

        # Limit to target length
        target_length = int(len(text) * target_ratio)
        summary = []
        current_length = 0

        for point in key_points:
            if current_length + len(point) <= target_length:
                summary.append(point)
                current_length += len(point) + 1
            else:
                break

        return ' '.join(summary)

    def _brief_summary(self, text: str, target_ratio: float) -> str:
        """Create brief summary with essential information only"""
        # Extract the most important sentence from each paragraph
        paragraphs = text.split('\n\n')
        key_sentences = []

        for para in paragraphs:
            if para.strip():
                sentences = self._split_sentences(para)
                if sentences:
                    # Get most important sentence (longest or with key terms)
                    important = max(sentences, key=lambda s: len(s) + sum(kw in s.lower() for kw in ['important', 'critical', 'key', 'main', 'essential']))
                    key_sentences.append(important)

        # Combine and trim to target
        summary = ' '.join(key_sentences)
        target_length = int(len(text) * target_ratio)

        if len(summary) > target_length:
            summary = summary[:target_length].rsplit(' ', 1)[0] + '...'

        return summary

    def _split_sentences(self, text: str) -> List[str]:
        """Split text into sentences"""
        sentences = re.split(r'(?<=[.!?])\s+', text)
        return [s.strip() for s in sentences if s.strip()]

    def _score_sentences(self, sentences: List[str]) -> List[Tuple[float, str]]:
        """Score sentences by importance"""
        scored = []

        for sent in sentences:
            score = 0.0

            # Length score (prefer moderate length)
            length = len(sent)
            if 50 <= length <= 200:
                score += 1.0
            elif length > 200:
                score += 0.5

            # Position score (prefer beginning and end)
            position = sentences.index(sent)
            if position < 2:
                score += 1.5
            elif position >= len(sentences) - 2:
                score += 1.0

            # Keyword score
            keywords = ['important', 'key', 'main', 'critical', 'essential', 'must', 'should', 'summary']
            for keyword in keywords:
                if keyword in sent.lower():
                    score += 0.5

            # Numeric data (often important)
            if any(char.isdigit() for char in sent):
                score += 0.5

            scored.append((score, sent))

        # Sort by score
        scored.sort(key=lambda x: x[0], reverse=True)
        return scored

    def _extract_key_points(self, text: str) -> List[str]:
        """Extract key points from text"""
        key_points = []

        # Look for bullet points or numbered lists
        list_items = re.findall(r'(?:^|\n)[\s]*[-•*\d]+\.?\s+(.+?)(?=\n|$)', text)
        key_points.extend(list_items)

        # Look for sentences with key indicators
        sentences = self._split_sentences(text)
        for sent in sentences:
            if any(indicator in sent.lower() for indicator in ['in summary', 'in conclusion', 'key point', 'important']):
                key_points.append(sent)

        # If no specific key points, use first sentence of each paragraph
        if not key_points:
            paragraphs = text.split('\n\n')
            for para in paragraphs:
                sentences = self._split_sentences(para)
                if sentences:
                    key_points.append(sentences[0])

        return key_points

    def get_summary_at_level(self, level: str) -> Optional[str]:
        """Get summary at specific level"""
        return self.summaries.get(level)

    def get_compression_stats(self) -> Dict:
        """Get compression statistics for each level"""
        if not self.summaries:
            return {}

        original_length = max(len(s) for s in self.summaries.values())
        stats = {}

        for level, summary in self.summaries.items():
            stats[level] = {
                'length': len(summary),
                'compression_ratio': 1 - (len(summary) / original_length) if original_length > 0 else 0,
                'sentence_count': len(self._split_sentences(summary))
            }

        return stats

# Usage Example
if __name__ == "__main__":
    # Sample document to summarize
    document = """
    Artificial Intelligence and Its Impact on Society

    Artificial Intelligence (AI) has emerged as one of the most transformative technologies of the 21st century. It encompasses a broad range of techniques including machine learning, natural language processing, computer vision, and robotics. These technologies are fundamentally changing how we work, communicate, and solve complex problems.

    The healthcare industry has seen remarkable improvements through AI applications. Machine learning algorithms can now detect diseases like cancer at early stages with accuracy that rivals or exceeds human specialists. AI-powered drug discovery platforms are reducing the time and cost of bringing new medications to market. Personalized treatment plans based on genetic data and patient history are becoming increasingly common.

    In the business sector, AI is revolutionizing operations and decision-making. Predictive analytics help companies forecast demand and optimize supply chains. Natural language processing enables automated customer service through chatbots and virtual assistants. Financial institutions use AI for fraud detection, risk assessment, and algorithmic trading.

    Education is being transformed through personalized learning systems that adapt to individual student needs. AI tutors provide 24/7 assistance, and automated grading systems free teachers to focus on instruction. Learning analytics help identify at-risk students early and provide targeted interventions.

    However, AI also presents significant challenges. Job displacement due to automation is a major concern, particularly for routine and repetitive tasks. Privacy issues arise from the vast amounts of data AI systems require. Bias in AI algorithms can perpetuate and amplify existing social inequalities. The "black box" nature of some AI systems makes it difficult to understand how decisions are made.

    Ethical considerations are paramount as AI becomes more prevalent. Questions about accountability, transparency, and fairness must be addressed. Regulatory frameworks are being developed worldwide to ensure AI is used responsibly. The concept of "explainable AI" is gaining traction, requiring systems to provide understandable justifications for their decisions.

    Looking forward, the future of AI holds both promise and uncertainty. Advances in quantum computing may enable AI systems of unprecedented capability. Artificial General Intelligence (AGI), while still theoretical, could surpass human intelligence across all domains. The integration of AI with other emerging technologies like biotechnology and nanotechnology may lead to breakthroughs we can barely imagine.

    In conclusion, AI represents a pivotal moment in human history. Its potential to solve complex global challenges is immense, but it requires careful management to ensure benefits are distributed equitably and risks are mitigated. Society must engage in ongoing dialogue about how to shape AI development in ways that align with human values and promote the common good.
    """

    # Create summarizer
    summarizer = ProgressiveSummarizer()

    # Generate 3 levels of summaries
    summaries = summarizer.summarize(document, levels=3)

    # Display results
    print("ORIGINAL DOCUMENT")
    print("=" * 50)
    print(f"Length: {len(document)} characters")
    print(document[:300] + "...\n")

    for level, summary in summaries.items():
        print(f"\n{level.upper()} SUMMARY")
        print("=" * 50)
        print(f"Length: {len(summary)} characters")
        print(f"Compression: {1 - len(summary)/len(document):.1%}")
        print(summary)

    # Show compression stats
    print("\n\nCOMPRESSION STATISTICS")
    print("=" * 50)
    stats = summarizer.get_compression_stats()
    for level, stat in stats.items():
        print(f"{level:10} - Length: {stat['length']:5} chars, "
              f"Compression: {stat['compression_ratio']:.1%}, "
              f"Sentences: {stat['sentence_count']}")
```

## Example 5: Handoff Document Generator

Create comprehensive handoff documents for agent transitions.

```python
import json
import uuid
from datetime import datetime
from typing import Dict, List, Any, Optional

class HandoffGenerator:
    """Generate complete handoff documents for agent transitions"""

    def __init__(self):
        self.handoff_id = None
        self.template = self._get_template()

    def _get_template(self) -> Dict:
        """Get handoff document template"""
        return {
            'metadata': {
                'id': '',
                'created_at': '',
                'source_agent': '',
                'target_agent': '',
                'session_id': '',
                'token_count': 0
            },
            'context': {
                'summary': '',
                'full_context': '',
                'key_facts': []
            },
            'work_status': {
                'completed_tasks': [],
                'current_task': None,
                'pending_tasks': [],
                'blocked_items': []
            },
            'state': {
                'variables': {},
                'flags': {},
                'counters': {},
                'checkpoints': []
            },
            'decisions': {
                'made': [],
                'pending': [],
                'rationale': {}
            },
            'constraints': [],
            'next_steps': [],
            'warnings': [],
            'resources': {
                'files': [],
                'urls': [],
                'tools_used': [],
                'dependencies': []
            }
        }

    def create_handoff(
        self,
        source_agent: str,
        target_agent: str,
        context: str,
        work_status: Dict,
        state: Optional[Dict] = None,
        **kwargs
    ) -> str:
        """Create a complete handoff document"""
        self.handoff_id = str(uuid.uuid4())[:8]
        handoff = self.template.copy()

        # Fill metadata
        handoff['metadata'] = {
            'id': self.handoff_id,
            'created_at': datetime.now().isoformat(),
            'source_agent': source_agent,
            'target_agent': target_agent,
            'session_id': kwargs.get('session_id', 'unknown'),
            'token_count': 0  # Will calculate at the end
        }

        # Process context
        handoff['context'] = self._process_context(context)

        # Process work status
        handoff['work_status'] = self._process_work_status(work_status)

        # Process state if provided
        if state:
            handoff['state'] = self._process_state(state)

        # Add additional fields from kwargs
        for key in ['decisions', 'constraints', 'next_steps', 'warnings', 'resources']:
            if key in kwargs:
                handoff[key] = kwargs[key]

        # Generate formatted document
        formatted = self._format_handoff(handoff)

        # Calculate token count
        import tiktoken
        enc = tiktoken.encoding_for_model("gpt-4")
        handoff['metadata']['token_count'] = len(enc.encode(formatted))

        return formatted

    def _process_context(self, context: str) -> Dict:
        """Process and summarize context"""
        # Extract key facts (simple heuristic)
        key_facts = []
        lines = context.split('\n')
        for line in lines:
            if any(indicator in line.lower() for indicator in ['important:', 'note:', 'key:', 'critical:']):
                key_facts.append(line.strip())

        # Create summary (first and last paragraphs)
        paragraphs = context.split('\n\n')
        if len(paragraphs) > 2:
            summary = f"{paragraphs[0]}\n\n...\n\n{paragraphs[-1]}"
        else:
            summary = context[:500] + "..." if len(context) > 500 else context

        return {
            'summary': summary,
            'full_context': context if len(context) < 5000 else context[:5000] + "... [truncated]",
            'key_facts': key_facts[:10]  # Limit to 10 facts
        }

    def _process_work_status(self, work_status: Dict) -> Dict:
        """Process work status information"""
        processed = {
            'completed_tasks': [],
            'current_task': None,
            'pending_tasks': [],
            'blocked_items': []
        }

        # Process completed tasks
        if 'completed' in work_status:
            for task in work_status['completed']:
                if isinstance(task, str):
                    processed['completed_tasks'].append({'name': task, 'status': 'complete'})
                else:
                    processed['completed_tasks'].append(task)

        # Process current task
        if 'current' in work_status:
            processed['current_task'] = work_status['current']

        # Process pending tasks
        if 'pending' in work_status:
            for task in work_status['pending']:
                if isinstance(task, str):
                    processed['pending_tasks'].append({'name': task, 'priority': 'normal'})
                else:
                    processed['pending_tasks'].append(task)

        # Process blocked items
        if 'blocked' in work_status:
            processed['blocked_items'] = work_status['blocked']

        return processed

    def _process_state(self, state: Dict) -> Dict:
        """Process state information"""
        processed = {
            'variables': {},
            'flags': {},
            'counters': {},
            'checkpoints': []
        }

        # Separate different types of state
        for key, value in state.items():
            if isinstance(value, bool):
                processed['flags'][key] = value
            elif isinstance(value, (int, float)):
                processed['counters'][key] = value
            elif key == 'checkpoints':
                processed['checkpoints'] = value
            else:
                processed['variables'][key] = value

        return processed

    def _format_handoff(self, handoff: Dict) -> str:
        """Format handoff document as readable text"""
        doc = f"""# Agent Handoff Document

## Metadata
- **Handoff ID**: {handoff['metadata']['id']}
- **Timestamp**: {handoff['metadata']['created_at']}
- **From**: {handoff['metadata']['source_agent']}
- **To**: {handoff['metadata']['target_agent']}
- **Session**: {handoff['metadata']['session_id']}

## Context Summary

{handoff['context']['summary']}

### Key Facts
"""
        for fact in handoff['context']['key_facts']:
            doc += f"- {fact}\n"

        doc += """
## Work Status

### Completed Tasks
"""
        for task in handoff['work_status']['completed_tasks']:
            if isinstance(task, dict):
                doc += f"- ✅ {task.get('name', task)}\n"
            else:
                doc += f"- ✅ {task}\n"

        current = handoff['work_status']['current_task']
        doc += f"\n### Current Task\n{current if current else 'None'}\n"

        doc += "\n### Pending Tasks\n"
        for task in handoff['work_status']['pending_tasks']:
            if isinstance(task, dict):
                priority = task.get('priority', 'normal')
                doc += f"- [ ] {task.get('name', task)} ({priority})\n"
            else:
                doc += f"- [ ] {task}\n"

        if handoff['work_status']['blocked_items']:
            doc += "\n### ⚠️ Blocked Items\n"
            for item in handoff['work_status']['blocked_items']:
                doc += f"- {item}\n"

        # Add state information
        if handoff['state']['variables']:
            doc += "\n## State Variables\n```json\n"
            doc += json.dumps(handoff['state']['variables'], indent=2)
            doc += "\n```\n"

        if handoff['state']['flags']:
            doc += "\n## Flags\n"
            for flag, value in handoff['state']['flags'].items():
                doc += f"- {flag}: {'✓' if value else '✗'}\n"

        # Add constraints
        if handoff.get('constraints'):
            doc += "\n## Constraints\n"
            for constraint in handoff['constraints']:
                doc += f"- ⚠️ {constraint}\n"

        # Add next steps
        if handoff.get('next_steps'):
            doc += "\n## Recommended Next Steps\n"
            for i, step in enumerate(handoff['next_steps'], 1):
                doc += f"{i}. {step}\n"

        # Add warnings
        if handoff.get('warnings'):
            doc += "\n## ⚠️ Warnings\n"
            for warning in handoff['warnings']:
                doc += f"- {warning}\n"

        # Add resources
        if handoff.get('resources'):
            doc += "\n## Resources\n"
            if handoff['resources'].get('files'):
                doc += "\n### Files\n"
                for file in handoff['resources']['files']:
                    doc += f"- {file}\n"

            if handoff['resources'].get('tools_used'):
                doc += "\n### Tools Used\n"
                for tool in handoff['resources']['tools_used']:
                    doc += f"- {tool}\n"

        doc += f"\n---\n*Handoff document generated at {datetime.now().isoformat()}*"

        return doc

    def validate_handoff(self, handoff_doc: str) -> Dict[str, Any]:
        """Validate handoff document completeness"""
        validation = {
            'valid': True,
            'errors': [],
            'warnings': [],
            'score': 100
        }

        # Check for required sections
        required_sections = ['Metadata', 'Context Summary', 'Work Status']
        for section in required_sections:
            if section not in handoff_doc:
                validation['valid'] = False
                validation['errors'].append(f"Missing required section: {section}")
                validation['score'] -= 20

        # Check for completeness indicators
        if 'Current Task' in handoff_doc and 'None' in handoff_doc:
            validation['warnings'].append("No current task specified")
            validation['score'] -= 5

        if 'Pending Tasks' in handoff_doc and '- [ ]' not in handoff_doc:
            validation['warnings'].append("No pending tasks listed")
            validation['score'] -= 5

        # Check token count
        import tiktoken
        enc = tiktoken.encoding_for_model("gpt-4")
        token_count = len(enc.encode(handoff_doc))

        if token_count > 10000:
            validation['warnings'].append(f"Large handoff document: {token_count} tokens")
            validation['score'] -= 10

        validation['token_count'] = token_count

        return validation

# Usage Example
if __name__ == "__main__":
    # Create handoff generator
    generator = HandoffGenerator()

    # Simulate agent state
    context = """
    Working on implementing a new authentication system for the application.

    Important: Must support OAuth2 and SAML protocols.
    Note: Database schema has been updated to support new auth fields.
    Key: Integration with existing user management system is critical.

    The authentication module will handle user login, token generation, and session management.
    Security considerations have been reviewed and approved by the security team.
    """

    work_status = {
        'completed': [
            'Database schema design',
            'OAuth2 provider integration',
            'Unit tests for auth module'
        ],
        'current': 'Implementing SAML support',
        'pending': [
            {'name': 'Integration testing', 'priority': 'high'},
            {'name': 'Documentation update', 'priority': 'medium'},
            {'name': 'Security audit', 'priority': 'high'}
        ],
        'blocked': ['Waiting for SAML test credentials from IT']
    }

    state = {
        'auth_providers_configured': 2,
        'oauth_enabled': True,
        'saml_enabled': False,
        'test_coverage': 0.75,
        'last_error': None,
        'config_file': '/config/auth.yaml'
    }

    # Create handoff document
    handoff = generator.create_handoff(
        source_agent='backend_developer',
        target_agent='integration_tester',
        context=context,
        work_status=work_status,
        state=state,
        constraints=[
            'Must maintain backward compatibility',
            'Cannot modify existing user table structure',
            'Must complete before Friday deployment'
        ],
        next_steps=[
            'Complete SAML implementation',
            'Run full integration test suite',
            'Update API documentation',
            'Schedule security review'
        ],
        warnings=[
            'SAML credentials still pending from IT',
            'Performance testing not yet completed'
        ],
        resources={
            'files': [
                'src/auth/oauth_provider.py',
                'src/auth/saml_provider.py',
                'tests/test_authentication.py'
            ],
            'tools_used': ['pytest', 'postman', 'jwt.io'],
            'dependencies': ['python-saml', 'authlib', 'pyjwt']
        }
    )

    # Display handoff document
    print(handoff)

    # Validate the handoff
    print("\n\n" + "="*50)
    print("VALIDATION RESULTS")
    print("="*50)
    validation = generator.validate_handoff(handoff)
    print(f"Valid: {validation['valid']}")
    print(f"Score: {validation['score']}/100")
    print(f"Token count: {validation['token_count']}")

    if validation['errors']:
        print("\nErrors:")
        for error in validation['errors']:
            print(f"  ❌ {error}")

    if validation['warnings']:
        print("\nWarnings:")
        for warning in validation['warnings']:
            print(f"  ⚠️ {warning}")
```

## Example 6: Context Window Optimizer

Optimize context window usage based on task requirements.

```python
from typing import Dict, List, Any, Optional
import json

class ContextWindowOptimizer:
    """Optimize context window allocation for different tasks"""

    def __init__(self, max_tokens: int = 100000):
        self.max_tokens = max_tokens
        self.task_profiles = self._load_task_profiles()
        self.current_allocation = {}

    def _load_task_profiles(self) -> Dict:
        """Load predefined task profiles"""
        return {
            'code_review': {
                'code': 0.50,
                'comments': 0.15,
                'history': 0.10,
                'docs': 0.15,
                'buffer': 0.10
            },
            'debugging': {
                'error_logs': 0.30,
                'code': 0.35,
                'stack_trace': 0.15,
                'context': 0.10,
                'buffer': 0.10
            },
            'documentation': {
                'existing_docs': 0.40,
                'code': 0.25,
                'examples': 0.20,
                'references': 0.10,
                'buffer': 0.05
            },
            'planning': {
                'requirements': 0.35,
                'constraints': 0.20,
                'existing_work': 0.25,
                'references': 0.10,
                'buffer': 0.10
            },
            'qa_testing': {
                'test_cases': 0.30,
                'code': 0.25,
                'requirements': 0.20,
                'logs': 0.15,
                'buffer': 0.10
            }
        }

    def optimize(
        self,
        task_type: str,
        available_content: Dict[str, str],
        custom_weights: Optional[Dict[str, float]] = None
    ) -> Dict[str, str]:
        """Optimize context window for specific task"""
        # Get task profile or use custom weights
        if custom_weights:
            profile = custom_weights
        else:
            profile = self.task_profiles.get(task_type, self._get_default_profile())

        # Calculate token allocations
        allocations = self._calculate_allocations(profile)

        # Fit content to allocations
        optimized_content = self._fit_content_to_allocations(
            available_content,
            allocations
        )

        # Track current allocation
        self.current_allocation = self._calculate_usage(optimized_content)

        return optimized_content

    def _get_default_profile(self) -> Dict[str, float]:
        """Get default balanced profile"""
        return {
            'context': 0.30,
            'working_memory': 0.30,
            'references': 0.25,
            'buffer': 0.15
        }

    def _calculate_allocations(self, profile: Dict[str, float]) -> Dict[str, int]:
        """Calculate token allocations from profile"""
        allocations = {}

        for component, weight in profile.items():
            tokens = int(self.max_tokens * weight)
            allocations[component] = tokens

        return allocations

    def _fit_content_to_allocations(
        self,
        content: Dict[str, str],
        allocations: Dict[str, int]
    ) -> Dict[str, str]:
        """Fit content to allocated token budgets"""
        import tiktoken
        enc = tiktoken.encoding_for_model("gpt-4")

        optimized = {}

        for component, text in content.items():
            if component not in allocations:
                # Find best matching allocation
                component_key = self._find_matching_allocation(component, allocations.keys())
                if not component_key:
                    continue
            else:
                component_key = component

            max_tokens = allocations[component_key]
            current_tokens = len(enc.encode(text))

            if current_tokens <= max_tokens:
                # Content fits within allocation
                optimized[component] = text
            else:
                # Need to compress
                optimized[component] = self._compress_to_fit(text, max_tokens)

        return optimized

    def _find_matching_allocation(self, component: str, allocation_keys: List[str]) -> Optional[str]:
        """Find best matching allocation key for component"""
        # Simple matching heuristic
        component_lower = component.lower()

        for key in allocation_keys:
            if key.lower() in component_lower or component_lower in key.lower():
                return key

        # Default to 'context' if available
        return 'context' if 'context' in allocation_keys else None

    def _compress_to_fit(self, text: str, max_tokens: int) -> str:
        """Compress text to fit within token limit"""
        import tiktoken
        enc = tiktoken.encoding_for_model("gpt-4")

        current_tokens = len(enc.encode(text))
        if current_tokens <= max_tokens:
            return text

        # Calculate compression ratio needed
        compression_ratio = max_tokens / current_tokens

        # Apply progressive compression
        if compression_ratio > 0.8:
            # Light compression - just whitespace and deduplication
            compressed = self._light_compression(text)
        elif compression_ratio > 0.5:
            # Medium compression - summarization
            compressed = self._medium_compression(text, compression_ratio)
        else:
            # Heavy compression - aggressive summarization
            compressed = self._heavy_compression(text, compression_ratio)

        # Verify we're under limit
        final_tokens = len(enc.encode(compressed))
        if final_tokens > max_tokens:
            # Truncate if still too large
            tokens = enc.encode(compressed)
            tokens = tokens[:max_tokens-10]  # Leave small buffer
            compressed = enc.decode(tokens) + "...[truncated]"

        return compressed

    def _light_compression(self, text: str) -> str:
        """Light compression - whitespace and deduplication"""
        import re

        # Remove excess whitespace
        text = re.sub(r'\s+', ' ', text)
        text = re.sub(r'\n{3,}', '\n\n', text)

        # Remove duplicate lines
        lines = text.split('\n')
        seen = set()
        deduped = []
        for line in lines:
            if line not in seen:
                seen.add(line)
                deduped.append(line)

        return '\n'.join(deduped)

    def _medium_compression(self, text: str, ratio: float) -> str:
        """Medium compression - selective summarization"""
        # Split into paragraphs
        paragraphs = text.split('\n\n')

        # Keep first and last paragraph, summarize middle
        if len(paragraphs) <= 2:
            return text

        result = [paragraphs[0]]

        # Summarize middle paragraphs
        middle = paragraphs[1:-1]
        for para in middle:
            if len(para) > 200:
                # Extract key sentence
                sentences = para.split('. ')
                if sentences:
                    key_sentence = max(sentences, key=len)
                    result.append(key_sentence + '...')
            else:
                result.append(para)

        result.append(paragraphs[-1])

        return '\n\n'.join(result)

    def _heavy_compression(self, text: str, ratio: float) -> str:
        """Heavy compression - aggressive summarization"""
        # Extract only the most important content
        lines = text.split('\n')

        # Keep lines with key indicators
        important_lines = []
        for line in lines:
            if any(indicator in line.lower() for indicator in
                   ['important', 'critical', 'error', 'warning', 'must', 'required']):
                important_lines.append(line)

        # If too few important lines, take first and last
        if len(important_lines) < 5:
            important_lines = lines[:2] + ['...'] + lines[-2:]

        return '\n'.join(important_lines)

    def _calculate_usage(self, content: Dict[str, str]) -> Dict[str, int]:
        """Calculate token usage for content"""
        import tiktoken
        enc = tiktoken.encoding_for_model("gpt-4")

        usage = {}
        for component, text in content.items():
            usage[component] = len(enc.encode(text))

        return usage

    def get_optimization_report(self) -> str:
        """Generate optimization report"""
        total_used = sum(self.current_allocation.values())
        utilization = total_used / self.max_tokens if self.max_tokens > 0 else 0

        report = f"""Context Window Optimization Report
=====================================
Maximum Tokens: {self.max_tokens:,}
Total Used: {total_used:,}
Utilization: {utilization:.1%}
Available: {self.max_tokens - total_used:,}

Component Allocation:
"""
        for component, tokens in sorted(self.current_allocation.items(),
                                       key=lambda x: x[1], reverse=True):
            percentage = tokens / self.max_tokens if self.max_tokens > 0 else 0
            report += f"  {component:20} {tokens:8,} tokens ({percentage:5.1%})\n"

        return report

    def suggest_reallocation(self, usage_patterns: Dict[str, float]) -> Dict[str, float]:
        """Suggest reallocation based on usage patterns"""
        suggestions = {}

        # Analyze usage patterns
        total_accesses = sum(usage_patterns.values())
        if total_accesses == 0:
            return self._get_default_profile()

        # Calculate suggested weights based on access patterns
        for component, accesses in usage_patterns.items():
            weight = accesses / total_accesses
            # Apply smoothing to avoid extreme allocations
            weight = 0.7 * weight + 0.3 * (1.0 / len(usage_patterns))
            suggestions[component] = round(weight, 2)

        # Ensure weights sum to 1.0
        total_weight = sum(suggestions.values())
        if total_weight > 0:
            suggestions = {k: v/total_weight for k, v in suggestions.items()}

        return suggestions

# Usage Example
if __name__ == "__main__":
    # Create optimizer
    optimizer = ContextWindowOptimizer(max_tokens=50000)

    # Prepare content for code review task
    available_content = {
        'code': """
def process_payment(order_id, payment_method, amount):
    '''Process payment for an order'''

    # Validate input
    if not order_id or amount <= 0:
        raise ValueError("Invalid order or amount")

    # Get order details
    order = get_order(order_id)
    if not order:
        raise OrderNotFound(f"Order {order_id} not found")

    # Check order status
    if order.status != 'pending':
        raise InvalidOrderStatus(f"Order {order_id} is {order.status}")

    # Process payment based on method
    if payment_method == 'credit_card':
        result = process_credit_card(order, amount)
    elif payment_method == 'paypal':
        result = process_paypal(order, amount)
    elif payment_method == 'bank_transfer':
        result = process_bank_transfer(order, amount)
    else:
        raise UnsupportedPaymentMethod(f"Method {payment_method} not supported")

    # Update order status
    if result.success:
        order.status = 'paid'
        order.payment_id = result.transaction_id
        save_order(order)
        send_confirmation_email(order)
    else:
        order.status = 'payment_failed'
        save_order(order)
        raise PaymentFailed(f"Payment failed: {result.error}")

    return result
""" * 20,  # Multiply to simulate larger codebase

        'comments': """
        Review comments from previous iteration:
        - Need to add retry logic for payment processing
        - Should log all payment attempts for audit
        - Consider adding rate limiting
        - Email sending should be async
        """ * 5,

        'history': """
        Previous changes:
        - Added PayPal support (commit abc123)
        - Fixed decimal precision issue (commit def456)
        - Added input validation (commit ghi789)
        """ * 3,

        'docs': """
        Payment Processing Documentation

        This module handles all payment processing for the e-commerce platform.
        Supported payment methods: credit card, PayPal, bank transfer.

        Security considerations:
        - All payment data must be encrypted
        - PCI compliance required for credit card processing
        - Rate limiting to prevent abuse
        """ * 10
    }

    # Optimize for code review
    optimized = optimizer.optimize('code_review', available_content)

    print("OPTIMIZATION RESULTS")
    print("="*50)
    print(optimizer.get_optimization_report())

    print("\n\nOPTIMIZED CONTENT PREVIEW")
    print("="*50)
    for component, content in optimized.items():
        print(f"\n{component.upper()}:")
        print(f"Length: {len(content)} chars")
        print(f"Preview: {content[:200]}...")

    # Test custom task profile
    print("\n\nCUSTOM OPTIMIZATION")
    print("="*50)

    custom_profile = {
        'code': 0.60,      # Prioritize code
        'docs': 0.20,      # Some documentation
        'comments': 0.10,  # Minimal comments
        'buffer': 0.10     # Safety buffer
    }

    optimized_custom = optimizer.optimize(
        'custom',
        available_content,
        custom_weights=custom_profile
    )

    print(optimizer.get_optimization_report())

    # Suggest reallocation based on usage
    print("\n\nREALLOCATION SUGGESTIONS")
    print("="*50)

    # Simulate usage patterns (which components were accessed most)
    usage_patterns = {
        'code': 150,       # Accessed 150 times
        'docs': 50,        # Accessed 50 times
        'comments': 30,    # Accessed 30 times
        'history': 10      # Accessed 10 times
    }

    suggestions = optimizer.suggest_reallocation(usage_patterns)
    print("Based on usage patterns, suggested allocation:")
    for component, weight in suggestions.items():
        tokens = int(optimizer.max_tokens * weight)
        print(f"  {component:15} {weight:5.1%} ({tokens:,} tokens)")
```

## Real-World Use Cases

### 100k+ Token Projects

Managing large-scale projects with extensive context:

```python
class LargeProjectManager:
    """Manage 100k+ token projects efficiently"""

    def __init__(self):
        self.budget = TokenBudgetTracker(total_budget=150000)
        self.compressor = ContextCompressor()
        self.chunker = SemanticChunker()

    def process_large_project(self, project_files: List[str]) -> Dict:
        """Process large project with efficient context management"""
        # Allocate budget
        self.budget.allocate('system', 5000)
        self.budget.allocate('active_files', 50000)
        self.budget.allocate('reference_files', 60000)
        self.budget.allocate('history', 20000)
        self.budget.allocate('buffer', 15000)

        # Process files
        active_context = ""
        reference_context = ""

        for file_path in project_files:
            with open(file_path, 'r') as f:
                content = f.read()

            # Determine if active or reference
            if self._is_active_file(file_path):
                active_context += f"\n\n# {file_path}\n{content}"
            else:
                # Compress reference files more aggressively
                compressed = self.compressor.compress(content, target_reduction=0.7)
                reference_context += f"\n\n# {file_path}\n{compressed}"

        # Track usage
        self.budget.use('active_files', active_context)
        self.budget.use('reference_files', reference_context)

        return {
            'active': active_context,
            'reference': reference_context,
            'status': self.budget.get_report()
        }
```

### Multi-Agent Workflows

Coordinating context across multiple agents:

```python
class MultiAgentCoordinator:
    """Coordinate context across multiple agents"""

    def __init__(self):
        self.handoff_generator = HandoffGenerator()
        self.optimizer = ContextWindowOptimizer()

    def coordinate_agents(self, agents: List[str], task: str) -> None:
        """Coordinate work across multiple agents"""
        context = {}

        for i, agent in enumerate(agents):
            # Optimize context for agent's role
            if 'reviewer' in agent:
                profile = 'code_review'
            elif 'tester' in agent:
                profile = 'qa_testing'
            else:
                profile = 'planning'

            # Get optimized context
            agent_context = self.optimizer.optimize(profile, context)

            # Execute agent work
            result = self._execute_agent(agent, agent_context, task)

            # Create handoff for next agent
            if i < len(agents) - 1:
                handoff = self.handoff_generator.create_handoff(
                    source_agent=agent,
                    target_agent=agents[i+1],
                    context=result['output'],
                    work_status=result['status']
                )
                context['handoff'] = handoff

            # Update shared context
            context.update(result['context_updates'])
```

---

*These examples demonstrate practical applications of the Context Engineering Framework. For more patterns, see [PATTERNS.md](PATTERNS.md).*