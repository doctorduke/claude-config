#!/usr/bin/env python3
"""
Preserve Semantic Relationships from Removed Edges

This script creates OpenQuestion nodes and semantic annotations to preserve
the architectural information lost during cycle remediation.
"""
import json
import os
from collections import defaultdict
from datetime import datetime
from pathlib import Path

class SemanticPreserver:
    def __init__(self, plan_dir="plan-fixed"):
        self.plan_dir = Path(plan_dir)
        self.nodes_dir = self.plan_dir / "nodes"
        self.open_questions = []
        self.semantic_annotations = defaultdict(lambda: {
            "informs": [],
            "reveals_gaps_in": [],
            "suggests_capability": [],
            "requires_iteration_on": []
        })

    def load_removed_edges(self):
        """Load the edges that were removed during cycle remediation."""
        # Load original edges
        original_edges = []
        with open(self.plan_dir / "edges.ndjson.backup-all-cycles", 'r') as f:
            for line in f:
                try:
                    original_edges.append(json.loads(line.strip()))
                except:
                    pass

        # Load current edges
        current_edges = []
        with open(self.plan_dir / "edges.ndjson", 'r') as f:
            for line in f:
                try:
                    current_edges.append(json.loads(line.strip()))
                except:
                    pass

        # Find removed edges
        current_set = {(e['from'], e['to'], e.get('type')) for e in current_edges}
        removed_edges = [e for e in original_edges
                        if (e['from'], e['to'], e.get('type')) not in current_set]

        return removed_edges

    def categorize_removed_edge(self, edge):
        """Categorize a removed edge by pattern."""
        from_node = edge.get('from', '')
        to_node = edge.get('to', '')
        edge_type = edge.get('type', '')

        from_type = from_node.split(':')[0] if ':' in from_node else ''
        to_type = to_node.split(':')[0] if ':' in to_node else ''

        if from_type == 'ix' and to_type == 'change':
            return 'ix_to_change'
        elif from_type == 'req' and to_type == 'cap':
            return 'req_to_cap'
        elif from_type == 'req' and to_type == 'change':
            return 'req_to_change'
        else:
            return 'other'

    def create_open_question(self, removed_edge, category):
        """Create an OpenQuestion node for a removed edge."""
        from_node = removed_edge['from']
        to_node = removed_edge['to']
        edge_type = removed_edge.get('type', 'unknown')

        # Determine the question based on category
        if category == 'ix_to_change':
            question = (
                f"InteractionSpec '{from_node}' revealed considerations that may "
                f"require updates to ChangeSpec '{to_node}'. Review for: "
                f"missing error handling, state management gaps, performance implications, "
                f"security considerations, or emergent complexity."
            )
            question_type = "iteration_feedback"
        elif category == 'req_to_cap':
            question = (
                f"Requirement '{from_node}' suggests need for capability '{to_node}'. "
                f"Evaluate if this capability needs enhancement or if a new capability "
                f"is required to fully satisfy the requirement."
            )
            question_type = "capability_evolution"
        elif category == 'req_to_change':
            question = (
                f"Requirement '{from_node}' has direct implementation dependency on "
                f"ChangeSpec '{to_node}'. Verify this change fully addresses the "
                f"requirement and consider if intermediate design artifacts are needed."
            )
            question_type = "direct_implementation"
        else:
            question = f"Removed {edge_type} relationship from '{from_node}' to '{to_node}' needs review."
            question_type = "general_feedback"

        open_question = {
            "id": f"open:{from_node.replace(':', '-')}-to-{to_node.replace(':', '-')}",
            "type": "OpenQuestion",
            "raised_by": from_node,
            "concerns": to_node,
            "question": question,
            "question_type": question_type,
            "original_edge_type": edge_type,
            "priority": "medium" if category == 'ix_to_change' else "high",
            "status": "Open",
            "resolution_pattern": self.get_resolution_pattern(category),
            "created_at": datetime.utcnow().isoformat() + 'Z',
            "checklist": [
                "Review raised concerns",
                "Identify required changes",
                "Create resolution nodes",
                "Update affected nodes",
                "Verify no new cycles introduced"
            ],
            "unaccounted": [],
            "evidence": []
        }

        return open_question

    def get_resolution_pattern(self, category):
        """Get the resolution pattern for a category of removed edge."""
        patterns = {
            'ix_to_change': {
                "pattern": "iterative_refinement",
                "steps": [
                    "Aggregate all IX feedback for the ChangeSpec",
                    "Create evaluation node summarizing findings",
                    "Generate new version of ChangeSpec if needed",
                    "Update requirements if scope changes"
                ]
            },
            'req_to_cap': {
                "pattern": "capability_evolution",
                "steps": [
                    "Assess if existing capability can be enhanced",
                    "Create new capability version if needed",
                    "Update capability dependencies",
                    "Trace impact to scenarios"
                ]
            },
            'req_to_change': {
                "pattern": "direct_implementation_tracking",
                "steps": [
                    "Verify change completeness for requirement",
                    "Add intermediate design nodes if needed",
                    "Ensure traceability chain is complete",
                    "Update requirement status when change is ready"
                ]
            },
            'other': {
                "pattern": "general_review",
                "steps": [
                    "Analyze relationship necessity",
                    "Find alternative representation",
                    "Update documentation",
                    "Verify semantic preservation"
                ]
            }
        }
        return patterns.get(category, patterns['other'])

    def add_semantic_annotation(self, node_id, annotation_type, target_id):
        """Add a semantic annotation to a node."""
        self.semantic_annotations[node_id][annotation_type].append(target_id)

    def update_node_with_annotations(self, node_path, annotations):
        """Update a node file with semantic annotations."""
        if not node_path.exists():
            return False

        with open(node_path, 'r') as f:
            node = json.load(f)

        # Add semantic_links field
        if 'semantic_links' not in node:
            node['semantic_links'] = {}

        # Merge annotations
        for key, values in annotations.items():
            if values:  # Only add non-empty lists
                if key not in node['semantic_links']:
                    node['semantic_links'][key] = []
                node['semantic_links'][key].extend(values)
                # Remove duplicates
                node['semantic_links'][key] = list(set(node['semantic_links'][key]))

        # Update timestamp
        node['updated_at'] = datetime.utcnow().isoformat() + 'Z'

        # Write back
        with open(node_path, 'w') as f:
            json.dump(node, f, indent=2)

        return True

    def create_evaluation_nodes(self):
        """Create evaluation nodes for groups of related interactions."""
        # Group InteractionSpecs by their parent ChangeSpec
        ix_by_change = defaultdict(list)

        for removed_edge in self.removed_edges:
            if self.categorize_removed_edge(removed_edge) == 'ix_to_change':
                ix_by_change[removed_edge['to']].append(removed_edge['from'])

        evaluation_nodes = []
        for change_id, ix_list in ix_by_change.items():
            if len(ix_list) >= 3:  # Only create evaluation nodes for significant groups
                eval_node = {
                    "id": f"eval:{change_id.replace(':', '-')}-interactions",
                    "type": "Evaluation",
                    "evaluates": ix_list,
                    "target": change_id,
                    "status": "Pending",
                    "criteria": [
                        "completeness - all states covered",
                        "consistency - uniform error handling",
                        "security - authorization properly enforced",
                        "performance - within SLO bounds",
                        "observability - adequate logging/metrics"
                    ],
                    "findings": [],
                    "recommendations": [],
                    "created_at": datetime.utcnow().isoformat() + 'Z',
                    "checklist": [
                        "Review all interaction patterns",
                        "Identify common concerns",
                        "Check for missing states",
                        "Verify error handling",
                        "Assess security posture"
                    ],
                    "unaccounted": [],
                    "evidence": []
                }
                evaluation_nodes.append(eval_node)

        return evaluation_nodes

    def generate_summary_report(self):
        """Generate a summary report of semantic preservation."""
        report = {
            "summary": {
                "removed_edges_total": len(self.removed_edges),
                "open_questions_created": len(self.open_questions),
                "nodes_annotated": len(self.semantic_annotations),
                "evaluation_nodes_created": len(self.evaluation_nodes)
            },
            "by_category": {},
            "resolution_required": []
        }

        # Categorize removed edges
        category_counts = defaultdict(int)
        for edge in self.removed_edges:
            category = self.categorize_removed_edge(edge)
            category_counts[category] += 1

        report["by_category"] = dict(category_counts)

        # Identify high-priority resolutions
        for oq in self.open_questions:
            if oq.get("priority") == "high":
                report["resolution_required"].append({
                    "id": oq["id"],
                    "concerns": oq["concerns"],
                    "type": oq["question_type"]
                })

        return report

    def run(self):
        """Main execution flow."""
        print("=" * 80)
        print("Semantic Relationship Preservation")
        print("=" * 80)

        # Step 1: Load removed edges
        print("\n1. Loading removed edges...")
        self.removed_edges = self.load_removed_edges()
        print(f"   Found {len(self.removed_edges)} removed edges")

        # Step 2: Process removed edges
        print("\n2. Creating OpenQuestions and annotations...")
        for edge in self.removed_edges:
            category = self.categorize_removed_edge(edge)

            # Create OpenQuestion
            open_question = self.create_open_question(edge, category)
            self.open_questions.append(open_question)

            # Add semantic annotations
            from_node = edge['from']
            to_node = edge['to']

            if category == 'ix_to_change':
                self.add_semantic_annotation(from_node, "informs", to_node)
                self.add_semantic_annotation(from_node, "requires_iteration_on", to_node)
            elif category == 'req_to_cap':
                self.add_semantic_annotation(from_node, "suggests_capability", to_node)
            elif category == 'req_to_change':
                self.add_semantic_annotation(from_node, "requires_iteration_on", to_node)

        print(f"   Created {len(self.open_questions)} OpenQuestion nodes")
        print(f"   Prepared annotations for {len(self.semantic_annotations)} nodes")

        # Step 3: Create evaluation nodes
        print("\n3. Creating evaluation nodes...")
        self.evaluation_nodes = self.create_evaluation_nodes()
        print(f"   Created {len(self.evaluation_nodes)} evaluation nodes")

        # Step 4: Write OpenQuestion nodes
        print("\n4. Writing OpenQuestion nodes...")
        oq_dir = self.nodes_dir / "OpenQuestion"
        oq_dir.mkdir(exist_ok=True)

        for oq in self.open_questions:
            oq_path = oq_dir / f"{oq['id'].replace(':', '-')}.json"
            with open(oq_path, 'w') as f:
                json.dump(oq, f, indent=2)

        print(f"   Wrote {len(self.open_questions)} OpenQuestion files")

        # Step 5: Write Evaluation nodes
        print("\n5. Writing Evaluation nodes...")
        eval_dir = self.nodes_dir / "Evaluation"
        eval_dir.mkdir(exist_ok=True)

        for eval_node in self.evaluation_nodes:
            eval_path = eval_dir / f"{eval_node['id'].replace(':', '-')}.json"
            with open(eval_path, 'w') as f:
                json.dump(eval_node, f, indent=2)

        print(f"   Wrote {len(self.evaluation_nodes)} Evaluation files")

        # Step 6: Update nodes with annotations
        print("\n6. Updating nodes with semantic annotations...")
        updated_count = 0
        for node_id, annotations in self.semantic_annotations.items():
            # Find the node file
            node_type = node_id.split(':')[0] if ':' in node_id else 'unknown'
            type_mappings = {
                'ix': 'InteractionSpec',
                'change': 'ChangeSpec',
                'req': 'Requirement',
                'cap': 'Capability',
                'scenario': 'Scenario',
                'contract': 'Contract',
                'component': 'Component'
            }

            node_type_dir = type_mappings.get(node_type, node_type)
            node_filename = node_id.replace(':', '-') + '.json'
            node_path = self.nodes_dir / node_type_dir / node_filename

            if self.update_node_with_annotations(node_path, annotations):
                updated_count += 1

        print(f"   Updated {updated_count} nodes with annotations")

        # Step 7: Generate summary report
        print("\n7. Generating summary report...")
        report = self.generate_summary_report()

        with open(self.plan_dir / "semantic_preservation_report.json", 'w') as f:
            json.dump(report, f, indent=2)

        print("\n" + "=" * 80)
        print("SEMANTIC PRESERVATION COMPLETE")
        print("=" * 80)
        print(f"\n✓ Created {len(self.open_questions)} OpenQuestion nodes")
        print(f"✓ Created {len(self.evaluation_nodes)} Evaluation nodes")
        print(f"✓ Updated {updated_count} nodes with semantic annotations")
        print(f"✓ Preserved {len(self.removed_edges)} semantic relationships")
        print("\nNext steps:")
        print("  1. Review OpenQuestion nodes in nodes/OpenQuestion/")
        print("  2. Process Evaluation nodes in nodes/Evaluation/")
        print("  3. Use semantic_links in nodes for traversal")
        print("  4. Resolve high-priority questions first")

        return True

if __name__ == '__main__':
    preserver = SemanticPreserver()
    success = preserver.run()
    exit(0 if success else 1)