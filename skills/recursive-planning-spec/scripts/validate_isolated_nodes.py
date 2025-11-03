#!/usr/bin/env python3
"""
Validate and categorize the 1,955 isolated nodes to determine if they are spurious.
"""

import json
import os
import random
from collections import defaultdict

def load_edges(filepath):
    """Load edges from NDJSON file."""
    edges = []
    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            if line.strip():
                edges.append(json.loads(line))
    return edges

def load_nodes_from_dir(nodes_dir):
    """Load all nodes from directory structure."""
    nodes = {}
    for root, dirs, files in os.walk(nodes_dir):
        for file in files:
            if file.endswith('.json'):
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        node = json.load(f)
                        nodes[node['id']] = node
                except Exception as e:
                    print(f"Warning: Could not load {file_path}: {e}")
    return nodes

def get_connected_nodes(edges):
    """Get set of all nodes that have at least one edge."""
    connected = set()
    for edge in edges:
        src = edge.get('from') or edge.get('source')
        tgt = edge.get('to') or edge.get('target')
        if src:
            connected.add(src)
        if tgt:
            connected.add(tgt)
    return connected

def find_cycles_containing_node(node_id, before_edges):
    """Check if a node was part of a cycle in the before graph."""
    # Build adjacency
    forward = defaultdict(set)
    for edge in before_edges:
        src = edge.get('from') or edge.get('source')
        tgt = edge.get('to') or edge.get('target')
        if src and tgt:
            forward[src].add(tgt)

    # DFS to detect if node can reach itself
    visited = set()
    rec_stack = set()

    def has_cycle_from(current, target):
        if current == target and current in rec_stack:
            return True
        if current in visited:
            return False

        visited.add(current)
        rec_stack.add(current)

        for neighbor in forward.get(current, set()):
            if neighbor == target and target in rec_stack:
                return True
            if neighbor not in visited:
                if has_cycle_from(neighbor, target):
                    return True

        rec_stack.discard(current)
        return False

    return has_cycle_from(node_id, node_id)

def get_node_degree(node_id, edges):
    """Get in-degree and out-degree for a node."""
    in_degree = 0
    out_degree = 0

    for edge in edges:
        src = edge.get('from') or edge.get('source')
        tgt = edge.get('to') or edge.get('target')

        if src == node_id:
            out_degree += 1
        if tgt == node_id:
            in_degree += 1

    return in_degree, out_degree

def categorize_isolated_node(node_id, nodes, before_edges, after_edges):
    """Categorize why a node became isolated."""
    node = nodes.get(node_id, {})

    # Get degrees
    before_in, before_out = get_node_degree(node_id, before_edges)
    after_in, after_out = get_node_degree(node_id, after_edges)

    # Check if in cycle
    in_cycle = find_cycles_containing_node(node_id, before_edges)

    category = None
    if in_cycle:
        category = "cycle_only"  # Only connected via cycles
    elif before_in == 0 and before_out > 0:
        category = "source_node"  # Was a source node
    elif before_in > 0 and before_out == 0:
        category = "sink_node"  # Was a sink node
    elif before_in + before_out < 3:
        category = "sparse"  # Had very few connections
    else:
        category = "well_connected"  # Had many connections

    return {
        'id': node_id,
        'type': node.get('type', 'unknown'),
        'label': node.get('label', 'unknown')[:80],
        'before_in': before_in,
        'before_out': before_out,
        'after_in': after_in,
        'after_out': after_out,
        'in_cycle': in_cycle,
        'category': category
    }

def main():
    base_path = 'D:\\doctorduke\\umemee\\umemee-v0\\plan-fixed'

    print("Loading data...")
    before_edges = load_edges(os.path.join(base_path, 'edges.ndjson.backup-all-cycles'))
    after_edges = load_edges(os.path.join(base_path, 'edges.ndjson'))
    nodes = load_nodes_from_dir(os.path.join(base_path, 'nodes'))

    print(f"Loaded {len(before_edges)} edges before, {len(after_edges)} edges after")
    print(f"Loaded {len(nodes)} nodes")

    # Find isolated nodes
    before_connected = get_connected_nodes(before_edges)
    after_connected = get_connected_nodes(after_edges)

    isolated_nodes = before_connected - after_connected

    print(f"\nFound {len(isolated_nodes)} isolated nodes")

    # Sample 20 random isolated nodes for detailed analysis
    sample_size = min(20, len(isolated_nodes))
    sample_nodes = random.sample(list(isolated_nodes), sample_size)

    print(f"\nAnalyzing {sample_size} random isolated nodes...")

    categorized = []
    for node_id in sample_nodes:
        cat = categorize_isolated_node(node_id, nodes, before_edges, after_edges)
        categorized.append(cat)

    # Count categories across full set (sample-based estimate)
    category_counts = defaultdict(int)
    for cat in categorized:
        category_counts[cat['category']] += 1

    # Print results
    print("\n" + "="*80)
    print("ISOLATED NODE SAMPLE ANALYSIS")
    print("="*80)

    print("\nCategory Distribution (sample of {}):\n".format(sample_size))
    for category, count in sorted(category_counts.items(), key=lambda x: -x[1]):
        percentage = (count / sample_size) * 100
        print(f"  {category}: {count} ({percentage:.1f}%)")

    print("\n" + "-"*80)
    print("DETAILED NODE INSPECTION")
    print("-"*80)

    for cat in categorized:
        print(f"\nNode ID: {cat['id']}")
        print(f"  Type: {cat['type']}")
        print(f"  Label: {cat['label']}")
        print(f"  Before: in={cat['before_in']}, out={cat['before_out']}")
        print(f"  After: in={cat['after_in']}, out={cat['after_out']}")
        print(f"  In Cycle: {cat['in_cycle']}")
        print(f"  Category: {cat['category']}")

    # Extrapolate to full dataset
    print("\n" + "="*80)
    print("EXTRAPOLATED FULL DATASET ESTIMATES")
    print("="*80)

    total_isolated = len(isolated_nodes)
    print(f"\nTotal isolated nodes: {total_isolated}\n")

    for category, count in sorted(category_counts.items(), key=lambda x: -x[1]):
        percentage = count / sample_size
        estimated_total = int(total_isolated * percentage)
        print(f"  {category}: ~{estimated_total} nodes ({percentage*100:.1f}%)")

    # Save detailed results
    results = {
        'total_isolated': total_isolated,
        'sample_size': sample_size,
        'category_distribution': dict(category_counts),
        'sample_nodes': categorized,
        'extrapolated_estimates': {
            category: int(total_isolated * (count / sample_size))
            for category, count in category_counts.items()
        }
    }

    output_path = os.path.join(base_path, 'isolated_nodes_analysis.json')
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(results, f, indent=2)

    print(f"\n\nDetailed results saved to: {output_path}")

if __name__ == '__main__':
    main()
