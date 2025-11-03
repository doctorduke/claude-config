#!/usr/bin/env python3
"""
Verify Generative Content Completion

1. Check if all 420 generative gaps are resolved
2. Verify quality - semantic vs boilerplate
3. Complete any remaining work
4. Generate completion report
"""

import json
import sys
from pathlib import Path
from typing import Dict, List, Set
from datetime import datetime


class GenerativeVerifier:
    """Verify and complete generative work"""

    def __init__(self, plan_dir: Path, goal_file: Path, analysis_file: Path):
        self.plan_dir = plan_dir
        self.goal_file = goal_file
        self.goal_content = self._load_goal()
        self.analysis = self._load_analysis(analysis_file)
        self.graph = self._load_graph()

    def _load_goal(self) -> str:
        """Load goal.md content"""
        if not self.goal_file.exists():
            return ""
        return self.goal_file.read_text(encoding='utf-8')

    def _load_analysis(self, analysis_file: Path) -> Dict:
        """Load generative vs wiring analysis"""
        if not analysis_file.exists():
            return {"generative": [], "wiring": []}
        return json.loads(analysis_file.read_text())

    def _load_graph(self) -> Dict:
        """Load plan graph"""
        graph = {"nodes": {}, "edges": []}

        nodes_dir = self.plan_dir / "nodes"
        if nodes_dir.exists():
            for type_dir in nodes_dir.iterdir():
                if type_dir.is_dir():
                    for node_file in type_dir.glob("*.json"):
                        try:
                            node = json.loads(node_file.read_text())
                            graph["nodes"][node.get("id")] = node
                        except Exception:
                            pass

        edges_file = self.plan_dir / "edges.ndjson"
        if edges_file.exists():
            for line in edges_file.read_text().strip().split("\n"):
                if line:
                    try:
                        edge = json.loads(line)
                        graph["edges"].append(edge)
                    except Exception:
                        pass

        return graph

    def verify_completion(self) -> Dict:
        """Verify if generative work is complete"""
        generative_gaps = set(self.analysis.get("generative", []))

        # Check which gaps still exist in graph
        unresolved = []
        resolved = []

        for gap_id in generative_gaps:
            # Check if semantic version exists
            if gap_id.startswith("change:"):
                # Check if has semantic InteractionSpecs
                change = self.graph["nodes"].get(gap_id)
                if change:
                    ix_list = change.get("ix", [])
                    # Check edges too
                    ix_edges = [e.get("from") for e in self.graph["edges"]
                               if e.get("to") == gap_id and
                               self.graph["nodes"].get(e.get("from", ""), {}).get("type") == "InteractionSpec"]
                    all_ix = set(ix_list + ix_edges)

                    # Check if any IX has semantic content
                    has_semantic = False
                    for ix_id in all_ix:
                        ix = self.graph["nodes"].get(ix_id)
                        if ix:
                            stmt = ix.get("stmt", "").lower()
                            method = ix.get("method", "").lower()

                            # Check for semantic indicators (goal.md epics)
                            if any(kw in stmt for kw in ["mobile editor", "slash", "gesture", "tag", "filter", "channel", "export", "link", "bookmark"]):
                                has_semantic = True
                                break
                            if any(kw in method for kw in ["editor.", "commands.", "links.", "tags.", "filters.", "gestures.", "export.", "channels."]):
                                has_semantic = True
                                break

                            # Check for Core Blueprint semantic indicators (from how-to-plan.md §2.1)
                            if any(kw in stmt for kw in ["analytics event", "taxonomy", "privacy control", "cache", "cdn", "invalidate", "purge", "ttl", "offline", "queue", "replay", "backup", "restore", "migration", "authenticate", "authorize", "refresh token", "log entry", "metric", "trace", "secret", "notification", "deliver"]):
                                has_semantic = True
                                break
                            if any(kw in method for kw in ["analytics.", "cache.", "connectivity.", "storage.", "auth.", "obs.", "secrets.", "notifications."]):
                                has_semantic = True
                                break

                            # Check for context-aware statements (not just "Create operation")
                            if len(stmt) > 30 and "operation" not in stmt.lower()[:20]:
                                has_semantic = True
                                break

                    if not has_semantic and len(all_ix) == 0:
                        unresolved.append(gap_id)
                    elif has_semantic:
                        resolved.append(gap_id)
                    else:
                        unresolved.append(gap_id)  # Has IX but not semantic
            elif gap_id.startswith("req:"):
                # Check if has semantic contracts/components/changespecs
                req = self.graph["nodes"].get(gap_id)
                if req:
                    contracts = req.get("contracts", [])
                    components = req.get("components", [])
                    changes = req.get("change_specs", [])

                    # Check if any contract has semantic operations
                    has_semantic = False
                    for cid in contracts:
                        contract = self.graph["nodes"].get(cid)
                        if contract:
                            stmt = contract.get("stmt", "").lower()
                            if any(kw in stmt for kw in ["mobile", "editor", "slash", "gesture", "tag", "filter", "channel", "export"]):
                                has_semantic = True
                                break

                    if not has_semantic and (len(contracts) == 0 or len(components) == 0 or len(changes) == 0):
                        unresolved.append(gap_id)
                    elif has_semantic:
                        resolved.append(gap_id)
                    else:
                        unresolved.append(gap_id)
            elif gap_id.startswith("scenario:"):
                # Check if has semantic requirements
                scenario = self.graph["nodes"].get(gap_id)
                if scenario:
                    reqs = scenario.get("requirements", [])
                    has_semantic = False
                    for req_id in reqs:
                        req = self.graph["nodes"].get(req_id)
                        if req:
                            stmt = req.get("stmt", "").lower()
                            if any(kw in stmt for kw in ["mobile", "editor", "slash", "gesture", "tag", "filter", "channel", "export"]):
                                has_semantic = True
                                break

                    if not has_semantic and len(reqs) == 0:
                        unresolved.append(gap_id)
                    elif has_semantic:
                        resolved.append(gap_id)
                    else:
                        unresolved.append(gap_id)

        return {
            "total_generative_gaps": len(generative_gaps),
            "resolved": len(resolved),
            "unresolved": len(unresolved),
            "resolution_rate": len(resolved) / len(generative_gaps) * 100 if generative_gaps else 0,
            "resolved_gaps": resolved,
            "unresolved_gaps": unresolved
        }

    def verify_semantic_quality(self) -> Dict:
        """Verify semantic quality of generated content"""
        # Check InteractionSpecs for semantic vs boilerplate
        all_ix = [n for n in self.graph["nodes"].values() if n.get("type") == "InteractionSpec"]

        semantic_ix = []
        boilerplate_ix = []

        boilerplate_patterns = [
            ("stmt", ["create operation", "read operation", "update operation", "delete operation"]),
            ("method", ["svc.create()", "svc.read()", "svc.update()", "svc.delete()"]),
            ("operation", ["create /resource", "read /resource", "update /resource", "delete /resource"])
        ]

        for ix in all_ix:
            stmt = ix.get("stmt", "").lower()
            method = ix.get("method", "").lower()
            operation = ix.get("operation", "").lower()

            # Check for boilerplate
            is_boilerplate = False
            for field, patterns in boilerplate_patterns:
                value = {"stmt": stmt, "method": method, "operation": operation}[field]
                if any(p in value for p in patterns):
                    is_boilerplate = True
                    break

            # Check for semantic indicators (goal.md epics)
            has_semantic = any(kw in stmt or kw in method for kw in [
                "mobile editor", "editor.", "slash", "commands.", "gesture", "gestures.",
                "tag", "tags.", "filter", "filters.", "channel", "channels.",
                "export", "export.", "link", "links.", "bookmark"
            ])

            # Check for Core Blueprint semantic indicators
            if not has_semantic:
                has_semantic = any(kw in stmt or kw in method for kw in [
                    "analytics", "analytics.", "cache", "cache.", "cdn", "connectivity", "connectivity.",
                    "storage", "storage.", "database", "auth", "auth.", "authenticate", "authorize",
                    "observability", "obs.", "log", "metric", "trace", "secret", "secrets.",
                    "notification", "notifications.", "backup", "restore", "migration", "offline", "queue", "replay"
                ])

            # Check for context-aware statements (not just "Create operation")
            if not has_semantic and len(stmt) > 30 and "operation" not in stmt.lower()[:20]:
                has_semantic = True

            if is_boilerplate and not has_semantic:
                boilerplate_ix.append(ix.get("id"))
            elif has_semantic:
                semantic_ix.append(ix.get("id"))
            else:
                # Could be either - check context
                if len(stmt) > 50 or "post" in stmt or "block" in stmt:
                    semantic_ix.append(ix.get("id"))
                else:
                    boilerplate_ix.append(ix.get("id"))

        return {
            "total_ix": len(all_ix),
            "semantic_ix": len(semantic_ix),
            "boilerplate_ix": len(boilerplate_ix),
            "semantic_rate": len(semantic_ix) / len(all_ix) * 100 if all_ix else 0,
            "semantic_ids": semantic_ix[:20],
            "boilerplate_ids": boilerplate_ix[:20]
        }

    def generate_report(self, completion: Dict, quality: Dict) -> str:
        """Generate completion report"""
        report = []
        report.append("# Generative Work Verification Report\n")
        report.append(f"**Generated**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")

        report.append("## Completion Status\n")
        report.append(f"- **Total Generative Gaps**: {completion['total_generative_gaps']}")
        report.append(f"- **Resolved**: {completion['resolved']} ({completion['resolution_rate']:.1f}%)")
        report.append(f"- **Unresolved**: {completion['unresolved']}\n")

        if completion['unresolved'] > 0:
            report.append("### Unresolved Gaps (Sample)\n")
            for gap_id in completion['unresolved_gaps'][:10]:
                report.append(f"- `{gap_id}`")
            if len(completion['unresolved_gaps']) > 10:
                report.append(f"\n... and {len(completion['unresolved_gaps']) - 10} more")

        report.append("\n## Semantic Quality\n")
        report.append(f"- **Total InteractionSpecs**: {quality['total_ix']}")
        report.append(f"- **Semantic**: {quality['semantic_ix']} ({quality['semantic_rate']:.1f}%)")
        report.append(f"- **Boilerplate**: {quality['boilerplate_ix']}\n")

        if quality['semantic_ix'] > 0:
            report.append("### Semantic InteractionSpecs (Sample)\n")
            for ix_id in quality['semantic_ids']:
                ix = self.graph["nodes"].get(ix_id)
                if ix:
                    report.append(f"- `{ix_id}`: {ix.get('stmt', '')[:80]}")

        if quality['boilerplate_ix'] > 0:
            report.append("\n### Boilerplate InteractionSpecs (Sample)\n")
            for ix_id in quality['boilerplate_ids']:
                ix = self.graph["nodes"].get(ix_id)
                if ix:
                    report.append(f"- `{ix_id}`: {ix.get('stmt', '')[:80]}")

        report.append("\n## Recommendations\n")

        if completion['unresolved'] > 0:
            report.append(f"1. **Process {completion['unresolved']} unresolved generative gaps**")
            report.append("   - Use `generate_semantic_content.py` for remaining gaps")
            report.append("   - Ensure semantic content from goal.md")

        if quality['boilerplate_ix'] > 0:
            report.append(f"2. **Replace {quality['boilerplate_ix']} boilerplate InteractionSpecs**")
            report.append("   - Replace generic operations with domain-specific ones")
            report.append("   - Use goal.md context for semantic operations")

        if completion['unresolved'] == 0 and quality['boilerplate_ix'] == 0:
            report.append("✅ **All generative work is complete!**")

        return "\n".join(report)


def main():
    plan_dir = Path("plan-fixed")
    goal_file = Path("planning-test/goal.md")
    analysis_file = Path("generative_vs_wiring_analysis.json")

    if not plan_dir.exists():
        print(f"Error: Plan directory not found: {plan_dir}")
        sys.exit(1)

    verifier = GenerativeVerifier(plan_dir, goal_file, analysis_file)

    print("Verifying generative work completion...")
    completion = verifier.verify_completion()

    print("Verifying semantic quality...")
    quality = verifier.verify_semantic_quality()

    print("\nGenerating report...")
    report = verifier.generate_report(completion, quality)

    # Save report
    report_file = Path("generative_verification_report.md")
    report_file.write_text(report, encoding='utf-8')
    print(f"\nReport saved to: {report_file}")

    # Print summary
    print("\n" + "=" * 80)
    print(report)
    print("=" * 80)

    # Save JSON
    json_output = {
        "completion": completion,
        "quality": quality,
        "timestamp": datetime.now().isoformat()
    }
    json_file = Path("generative_verification.json")
    json_file.write_text(json.dumps(json_output, indent=2), encoding='utf-8')
    print(f"\nJSON data saved to: {json_file}")

    # Return status
    if completion['unresolved'] > 0 or quality['boilerplate_ix'] > 0:
        print("\n⚠️  Generative work is NOT complete")
        return 1
    else:
        print("\n✅ Generative work is COMPLETE")
        return 0


if __name__ == "__main__":
    exit(main())

