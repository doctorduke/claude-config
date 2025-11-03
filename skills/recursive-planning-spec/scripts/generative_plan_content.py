#!/usr/bin/env python3
"""
Generative Content System for PlanGraf

Uses LLM/generative approaches to create semantically rich content based on goal.md
for gaps that need NEW content, not just wiring connections.

Distinguishes between:
1. GENERATIVE: Needs semantic content from goal.md → Use LLM generation
2. WIRING: Just connections → Use automated wiring logic
"""

import json
import sys
from pathlib import Path
from typing import Dict, List, Set, Optional
from datetime import datetime, timezone
import re


class GenerativeContentGenerator:
    """Generate semantic content for plan gaps using goal.md context"""

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
        data = json.loads(analysis_file.read_text())
        return data

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

    def generate_content_for_gaps(self) -> List[Dict]:
        """Generate semantic content for all generative gaps"""
        deltas = []

        generative_gaps = set(self.analysis.get("generative", []))

        print(f"Generating semantic content for {len(generative_gaps)} generative gaps...")

        # Group by type
        scenarios = [nid for nid in generative_gaps if nid.startswith("scenario:")]
        requirements = [nid for nid in generative_gaps if nid.startswith("req:")]
        changes = [nid for nid in generative_gaps if nid.startswith("change:")]
        ix_orphans = [nid for nid in generative_gaps if nid.startswith("ix:")]

        print(f"  - Scenarios: {len(scenarios)}")
        print(f"  - Requirements: {len(requirements)}")
        print(f"  - ChangeSpecs: {len(changes)}")
        print(f"  - InteractionSpecs: {len(ix_orphans)}")

        # Generate content for each type
        for scenario_id in scenarios[:10]:  # Process first 10 as example
            deltas.extend(self._generate_scenario_content(scenario_id))

        for req_id in requirements[:20]:  # Process first 20
            deltas.extend(self._generate_requirement_content(req_id))

        for change_id in changes[:30]:  # Process first 30
            deltas.extend(self._generate_changespec_content(change_id))

        return deltas

    def _generate_scenario_content(self, scenario_id: str) -> List[Dict]:
        """Generate semantic content for a scenario based on goal.md"""
        scenario = self.graph["nodes"].get(scenario_id)
        if not scenario:
            return []

        deltas = []
        stmt = scenario.get("stmt", "")

        # Extract semantic context from goal.md based on scenario
        context = self._extract_context_from_goal(stmt, scenario_id)

        # Generate Requirement with semantic content
        req_id = f"req:{scenario_id.replace('scenario:', '')}-semantic"
        if not self.graph["nodes"].get(req_id):
            req_stmt = self._generate_requirement_stmt(stmt, context)
            req = {
                "id": req_id,
                "type": "Requirement",
                "stmt": req_stmt,
                "status": "Open",
                "change_specs": [],
                "contracts": [],
                "components": [],
                "checklist": [],
                "evidence": [],
                "unaccounted": [],
                "updated_at": datetime.now(timezone.utc).isoformat()
            }
            deltas.append({"op": "add_node", "node": req})

            # Update scenario to link to requirement
            scenario["requirements"] = scenario.get("requirements", []) + [req_id]
            deltas.append({"op": "update_node", "node": scenario})

        return deltas

    def _generate_requirement_content(self, req_id: str) -> List[Dict]:
        """Generate semantic content for a requirement based on goal.md"""
        req = self.graph["nodes"].get(req_id)
        if not req:
            return []

        deltas = []
        stmt = req.get("stmt", "")

        # Extract semantic context from goal.md
        context = self._extract_context_from_goal(stmt, req_id)

        # Generate Contracts with semantic content
        api_contract_id = f"contract:api-{req_id.replace('req:', '')}-semantic"
        if not self.graph["nodes"].get(api_contract_id):
            api_contract = self._generate_api_contract(req_id, stmt, context)
            if api_contract:
                deltas.append({"op": "add_node", "node": api_contract})
                req["contracts"] = req.get("contracts", []) + [api_contract_id]

        data_contract_id = f"contract:data-{req_id.replace('req:', '')}-semantic"
        if not self.graph["nodes"].get(data_contract_id):
            data_contract = self._generate_data_contract(req_id, stmt, context)
            if data_contract:
                deltas.append({"op": "add_node", "node": data_contract})
                req["contracts"] = req.get("contracts", []) + [data_contract_id]

        # Generate ChangeSpec with semantic content
        change_id = f"change:{req_id.replace('req:', '')}-semantic"
        if not self.graph["nodes"].get(change_id):
            change = self._generate_changespec(req_id, stmt, context)
            if change:
                deltas.append({"op": "add_node", "node": change})
                req["change_specs"] = req.get("change_specs", []) + [change_id]

        # Update requirement
        if deltas:
            deltas.append({"op": "update_node", "node": req})

        return deltas

    def _generate_changespec_content(self, change_id: str) -> List[Dict]:
        """Generate semantic InteractionSpecs for a ChangeSpec based on goal.md"""
        change = self.graph["nodes"].get(change_id)
        if not change:
            return []

        deltas = []
        stmt = change.get("stmt", "")

        # Find requirement this implements
        implements = change.get("implements", [])
        req = None
        if implements:
            req = self.graph["nodes"].get(implements[0])

        # Extract semantic context
        context = self._extract_context_from_goal(stmt, change_id)
        if req:
            context += f"\nRequirement: {req.get('stmt', '')}"

        # Generate semantic InteractionSpecs
        ix_specs = self._generate_interaction_specs(change_id, stmt, context)

        for ix in ix_specs:
            deltas.append({"op": "add_node", "node": ix})
            change["ix"] = change.get("ix", []) + [ix["id"]]

        if ix_specs:
            deltas.append({"op": "update_node", "node": change})

        return deltas

    def _extract_context_from_goal(self, stmt: str, node_id: str) -> str:
        """Extract relevant context from goal.md based on statement/node"""
        if not self.goal_content:
            return ""

        # Simple keyword matching to find relevant sections
        keywords = self._extract_keywords(stmt, node_id)

        # Find sections containing keywords
        lines = self.goal_content.split("\n")
        relevant_lines = []
        in_relevant_section = False

        for i, line in enumerate(lines):
            line_lower = line.lower()
            # Check if line contains any keyword
            if any(kw in line_lower for kw in keywords):
                in_relevant_section = True
                relevant_lines.append(line)
            elif in_relevant_section and line.startswith("#"):
                # Start of new section
                break

        return "\n".join(relevant_lines[:50])  # Limit context

    def _extract_keywords(self, stmt: str, node_id: str) -> List[str]:
        """Extract keywords from statement/node ID"""
        keywords = []

        # From statement
        stmt_lower = stmt.lower()
        semantic_keywords = [
            "mobile editor", "feed", "slash command", "gesture", "tag", "filter",
            "channel", "export", "keyboard", "AR", "geospatial", "smart link",
            "condensed", "view education", "mode", "bookmark"
        ]

        for kw in semantic_keywords:
            if kw in stmt_lower:
                keywords.append(kw)

        # From node ID
        node_lower = node_id.lower()
        if "mobile" in node_lower or "editor" in node_lower:
            keywords.extend(["mobile", "editor"])
        if "feed" in node_lower:
            keywords.append("feed")
        if "slash" in node_lower or "command" in node_lower:
            keywords.extend(["slash", "command"])
        if "tag" in node_lower or "filter" in node_lower:
            keywords.extend(["tag", "filter"])
        if "channel" in node_lower:
            keywords.append("channel")
        if "export" in node_lower:
            keywords.append("export")
        if "keyboard" in node_lower:
            keywords.append("keyboard")
        if "ar" in node_lower or "geospatial" in node_lower:
            keywords.extend(["AR", "geospatial"])

        return list(set(keywords))  # Unique keywords

    def _generate_requirement_stmt(self, scenario_stmt: str, context: str) -> str:
        """Generate semantic requirement statement"""
        # This would use LLM in production, but for now use template + context
        if context:
            # Extract key action from context
            return f"Functional requirement: {scenario_stmt} - Implemented based on goal.md context"
        return f"Functional requirement: {scenario_stmt}"

    def _generate_api_contract(self, req_id: str, req_stmt: str, context: str) -> Optional[Dict]:
        """Generate semantic API contract"""
        req_base = req_id.replace("req:", "").replace(":", "-")[:50]
        contract_id = f"contract:api-{req_base}-semantic"

        return {
            "id": contract_id,
            "type": "Contract",
            "stmt": f"API contract for {req_stmt[:80]} - AuthZ scopes, rate limits, idempotency, timeouts, error taxonomy, observability",
            "status": "Open",
            "contract_type": "api",
            "versioning": "semver:minor",
            "checklist": ["authZ defined", "rate_limit defined", "idempotency defined", "timeouts defined", "error taxonomy defined", "observability defined"],
            "evidence": [],
            "unaccounted": [],
            "updated_at": datetime.now(timezone.utc).isoformat()
        }

    def _generate_data_contract(self, req_id: str, req_stmt: str, context: str) -> Optional[Dict]:
        """Generate semantic data contract"""
        req_base = req_id.replace("req:", "").replace(":", "-")[:50]
        contract_id = f"contract:data-{req_base}-semantic"

        return {
            "id": contract_id,
            "type": "Contract",
            "stmt": f"Data contract for {req_stmt[:80]} - Schema, migration, retention, PII, region, index, backup, restore",
            "status": "Open",
            "contract_type": "data",
            "lifecycle_fields": ["schema", "migration", "retention", "PII", "region", "index", "backup", "restore"],
            "checklist": ["schema defined", "migration defined", "retention defined", "PII defined", "region defined", "index defined", "backup defined", "restore defined"],
            "evidence": [],
            "unaccounted": [],
            "updated_at": datetime.now(timezone.utc).isoformat()
        }

    def _generate_changespec(self, req_id: str, req_stmt: str, context: str) -> Optional[Dict]:
        """Generate semantic ChangeSpec"""
        req_base = req_id.replace("req:", "").replace(":", "-")[:50]
        change_id = f"change:{req_base}-semantic"

        return {
            "id": change_id,
            "type": "ChangeSpec",
            "stmt": f"Implement {req_stmt[:80]}",
            "status": "Open",
            "implements": [req_id],
            "ix": [],
            "accept": [],
            "checklist": [],
            "est_h": 0,
            "owner": "backend-team",
            "rollout_flag": f"feature.{req_base}",
            "evidence": [],
            "unaccounted": [],
            "simple": False,
            "updated_at": datetime.now(timezone.utc).isoformat()
        }

    def _generate_interaction_specs(self, change_id: str, change_stmt: str, context: str) -> List[Dict]:
        """Generate semantic InteractionSpecs based on goal.md context"""
        specs = []

        change_base = change_id.replace("change:", "").replace(":", "-")[:50]

        # Extract operations from context
        operations = self._extract_operations_from_context(context, change_stmt)

        # Generate IX for each operation
        for i, operation in enumerate(operations[:3]):  # Max 3 operations per ChangeSpec
            ix_id = f"ix:{change_base}-{operation['name']}-{i}"

            ix = {
                "id": ix_id,
                "type": "InteractionSpec",
                "stmt": operation.get("description", f"{operation['name']} operation"),
                "method": operation.get("method", f"Svc.{operation['name']}()"),
                "interface": operation.get("interface", "API"),
                "operation": operation.get("operation", f"{operation['name'].upper()} /resource"),
                "state": operation.get("state", {"token": "fresh", "quota": "under", "network": "ok"}),
                "pre": operation.get("preconditions", ["User authenticated", "Input validated"]),
                "in": operation.get("inputs", {"params": "resource_data", "headers": ["Authorization"]}),
                "eff": operation.get("effects", [f"Resource {operation['name']}d"]),
                "err": operation.get("errors", {"retriable": ["5xx", "429"], "non_retriable": ["400", "401", "403"], "compensation": ["Rollback transaction"]}),
                "res": {"timeout_ms": 8000, "retry": {"strategy": "exp", "max": 4, "jitter": True}, "idem_key": f"{operation['name']}-{change_id}"},
                "obs": {"logs": ["Operation start", "Operation complete"], "metrics": [f"operation_{operation['name']}_count", f"operation_{operation['name']}_duration"], "span": f"api.{operation['name']}"},
                "sec": {"authZ": "User owns resource or has permission", "least_priv": "Read/write own resources only", "pii": False},
                "test": {"mocks": ["Database", "Auth service"], "acc": [f"Given resource exists\nWhen user {operation['name']}s\nThen operation succeeds"]},
                "depends_on": [],
                "owner": "backend-team",
                "est_h": 1,
                "status": "Open",
                "unaccounted": [],
                "updated_at": datetime.now(timezone.utc).isoformat()
            }

            specs.append(ix)

        return specs

    def _extract_operations_from_context(self, context: str, change_stmt: str) -> List[Dict]:
        """Extract operations from context/statement"""
        operations = []

        # Look for common operations in context
        context_lower = context.lower()
        change_lower = change_stmt.lower()

        # Check for CRUD operations
        if "create" in change_lower or "add" in change_lower or "post" in change_lower:
            operations.append({
                "name": "create",
                "description": "Create resource",
                "method": "Svc.create()",
                "interface": "API",
                "operation": "POST /resource"
            })

        if "read" in change_lower or "get" in change_lower or "fetch" in change_lower or "view" in change_lower:
            operations.append({
                "name": "read",
                "description": "Read resource",
                "method": "Svc.read()",
                "interface": "API",
                "operation": "GET /resource"
            })

        if "update" in change_lower or "edit" in change_lower or "put" in change_lower or "patch" in change_lower:
            operations.append({
                "name": "update",
                "description": "Update resource",
                "method": "Svc.update()",
                "interface": "API",
                "operation": "PUT /resource"
            })

        if "delete" in change_lower or "remove" in change_lower:
            operations.append({
                "name": "delete",
                "description": "Delete resource",
                "method": "Svc.delete()",
                "interface": "API",
                "operation": "DELETE /resource"
            })

        # If no operations found, default to create
        if not operations:
            operations.append({
                "name": "create",
                "description": "Create resource",
                "method": "Svc.create()",
                "interface": "API",
                "operation": "POST /resource"
            })

        return operations


def main():
    plan_dir = Path("plan-fixed")
    goal_file = Path("planning-test/goal.md")
    analysis_file = Path("generative_vs_wiring_analysis.json")

    if not plan_dir.exists():
        print(f"Error: Plan directory not found: {plan_dir}")
        sys.exit(1)

    if not goal_file.exists():
        print(f"Error: Goal file not found: {goal_file}")
        sys.exit(1)

    if not analysis_file.exists():
        print(f"Error: Analysis file not found: {analysis_file}")
        print("Run analyze_generative_vs_wiring.py first")
        sys.exit(1)

    generator = GenerativeContentGenerator(plan_dir, goal_file, analysis_file)
    deltas = generator.generate_content_for_gaps()

    print(f"\nGenerated {len(deltas)} deltas for semantic content")

    # Save deltas
    deltas_file = Path("generative_content_deltas.json")
    deltas_file.write_text(json.dumps(deltas, indent=2), encoding='utf-8')
    print(f"Deltas saved to: {deltas_file}")

    # Note: In production, these deltas would be applied via the graph.save_node() method
    print("\nNote: This is a template. In production, integrate with LLM API to generate rich semantic content.")


if __name__ == "__main__":
    main()


