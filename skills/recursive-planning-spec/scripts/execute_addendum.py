#!/usr/bin/env python3
"""
Execute Addendum v3.1-supp: Expansion & Core Wiring
Implements prioritized TODO from addendum to close gaps and wire Core Blueprint.
"""

import json
import os
from pathlib import Path
from datetime import datetime, timezone
from typing import Dict, List, Set, Optional, Tuple
from collections import defaultdict

# State clusters from addendum §B
STATE_CLUSTERS = {
    "token": ["fresh", "expired"],
    "quota": ["under", "over"],
    "cache": ["hit", "miss"],
    "network": ["ok", "flaky"],
    "region": ["primary"]  # Add eu|multi only if control flow differs
}

# Core Blueprint areas needing wiring
CORE_BLUEPRINT_AREAS = [
    "queues-workers",
    "secrets-keys",
    "observability",
    "caching-cdn",
    "feature-flags-config",
    "preferences-settings",
    "i18n-a11y",
    "notifications",
    "payments"
]

class PlanGraph:
    """Plan graph structure"""

    def __init__(self, base_dir: str):
        self.base_dir = Path(base_dir)
        self.nodes: Dict[str, Dict] = {}
        self.edges: List[Dict] = []
        self.node_by_type: Dict[str, Set[str]] = defaultdict(set)
        self.load()

    def load(self):
        """Load existing graph"""
        nodes_dir = self.base_dir / "nodes"
        for type_dir in nodes_dir.iterdir():
            if type_dir.is_dir():
                node_type = type_dir.name
                for node_file in type_dir.glob("*.json"):
                    try:
                        with open(node_file, 'r') as f:
                            node = json.load(f)
                            node_id = node.get('id')
                            if node_id:
                                self.nodes[node_id] = node
                                self.node_by_type[node_type].add(node_id)
                    except Exception as e:
                        pass

        edges_path = self.base_dir / "edges.ndjson"
        if edges_path.exists():
            with open(edges_path, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line:
                        try:
                            edge = json.loads(line)
                            self.edges.append(edge)
                        except Exception:
                            pass

    def get_node(self, node_id: str) -> Optional[Dict]:
        return self.nodes.get(node_id)

    def get_nodes_by_type(self, node_type: str) -> List[Dict]:
        return [self.nodes[nid] for nid in self.node_by_type.get(node_type, []) if nid in self.nodes]

    def has_node(self, node_id: str) -> bool:
        return node_id in self.nodes

    def get_edges_from(self, node_id: str, edge_type: Optional[str] = None) -> List[Dict]:
        results = [e for e in self.edges if e.get('from') == node_id]
        if edge_type:
            results = [e for e in results if e.get('type') == edge_type]
        return results

    def get_edges_to(self, node_id: str, edge_type: Optional[str] = None) -> List[Dict]:
        results = [e for e in self.edges if e.get('to') == node_id]
        if edge_type:
            results = [e for e in results if e.get('type') == edge_type]
        return results


class AddendumExecutor:
    """Execute addendum prioritized TODO"""

    def __init__(self, graph: PlanGraph):
        self.graph = graph
        self.deltas: List[Dict] = []
        self.new_nodes: Dict[str, Dict] = {}
        self.new_edges: List[Dict] = []
        self.changed_nodes: Set[str] = set()

    def execute(self) -> Dict:
        """Execute prioritized TODO in order"""
        print("=" * 80)
        print("EXECUTING ADDENDUM v3.1-supp: Expansion & Core Wiring")
        print("=" * 80)

        # A.1) Core Blueprint remediation (P10)
        print("\n[A.1] Core Blueprint remediation (P10)...")
        self._core_blueprint_remediation()

        # A.2) Nonterminal expansion (P9)
        print("\n[A.2] Nonterminal expansion (P9)...")
        self._nonterminal_expansion()

        # A.3) Traceability restoration
        print("\n[A.3] Traceability restoration...")
        self._traceability_restoration()

        # A.4) Re-run proofs (will be done separately)
        print("\n[A.4] Generating deltas...")

        return {
            "deltas": self.deltas,
            "new_nodes": len(self.new_nodes),
            "new_edges": len(self.new_edges),
            "changed_nodes": len(self.changed_nodes)
        }

    def _core_blueprint_remediation(self):
        """A.1: Core Blueprint remediation"""

        # Check each Core Blueprint area
        for area in CORE_BLUEPRINT_AREAS:
            area_id = f"req:{area}"

            # Check if Requirement exists
            if not self.graph.has_node(area_id):
                print(f"  Creating Requirement + Contract for {area}...")

                # Create Requirement
                req = {
                    "id": area_id,
                    "type": "Requirement",
                    "stmt": self._get_area_description(area),
                    "status": "Open",
                    "change_specs": [],
                    "contracts": [],
                    "components": [],
                    "checklist": [],
                    "evidence": [],
                    "unaccounted": [],
                    "updated_at": datetime.now(timezone.utc).isoformat()
                }
                self.new_nodes[area_id] = req

                # Create Contract
                contract_id = f"contract:api-{area}"
                contract = {
                    "id": contract_id,
                    "type": "Contract",
                    "stmt": self._get_contract_description(area),
                    "status": "Open",
                    "contract_type": "api",
                    "versioning": "semver:minor",
                    "error_taxonomy": [],
                    "timeouts": {},
                    "idempotency": "required",
                    "checklist": [
                        "authZ defined",
                        "rate_limit defined",
                        "versioning defined",
                        "error taxonomy defined",
                        "idempotency defined",
                        "timeouts defined",
                        "observability defined"
                    ],
                    "evidence": [],
                    "unaccounted": [],
                    "updated_at": datetime.now(timezone.utc).isoformat()
                }
                self.new_nodes[contract_id] = contract

                # Create edge
                self.new_edges.append({
                    "from": area_id,
                    "to": contract_id,
                    "type": "depends_on"
                })

                # Update Requirement
                req["contracts"].append(contract_id)

            # Wire write paths to core contracts
            self._wire_write_paths_to_core(area)

    def _get_area_description(self, area: str) -> str:
        """Get description for Core Blueprint area"""
        descriptions = {
            "queues-workers": "Asynchronous job handling with backpressure, retries, DLQ",
            "secrets-keys": "Managed secrets & key rotation via KMS",
            "observability": "Structured logs, metrics, traces; dashboards+alerts; SLIs/SLOs",
            "caching-cdn": "Object & page cache, invalidation/purge, TTLs",
            "feature-flags-config": "Flags, canaries, kill switch",
            "preferences-settings": "Data model, defaults, overrides, per-device sync, UI projection",
            "i18n-a11y": "i18n/l10n; accessibility states and labels",
            "notifications": "Push/email; preferences; deliverability",
            "payments": "Contracts & compliance if applicable"
        }
        return descriptions.get(area, f"Core Blueprint requirement for {area}")

    def _get_contract_description(self, area: str) -> str:
        """Get contract description"""
        descriptions = {
            "queues-workers": "Queue/worker contract (enqueue/dequeue, retries, DLQ, observability)",
            "secrets-keys": "Secret storage, access policies, rotation cadence, audit",
            "observability": "Logging, metrics, tracing contract (SLIs/SLOs, dashboards, alerts)",
            "caching-cdn": "Cache contract (invalidation, purge, TTLs, hit/miss behavior)",
            "feature-flags-config": "Feature flag & config contract (evaluation, canaries, kill switch)",
            "preferences-settings": "Preferences contract (CRUD, sync, retention)",
            "i18n-a11y": "i18n/a11y contract (localization, accessibility labels)",
            "notifications": "Notification contract (push/email, preferences, deliverability)",
            "payments": "Payment contract (processing, compliance, audit)"
        }
        return descriptions.get(area, f"API contract for {area}")

    def _wire_write_paths_to_core(self, core_area: str):
        """Wire write paths to core contracts"""
        contract_id = f"contract:api-{core_area}"
        if not self.graph.has_node(contract_id) and contract_id not in self.new_nodes:
            return

        # Find write paths (ChangeSpecs with write operations)
        change_specs = self.graph.get_nodes_by_type("ChangeSpec")

        for cs in change_specs:
            cs_id = cs.get("id")
            ix_list = cs.get("ix", [])

            # Check if any InteractionSpec is a write operation
            has_write = False
            for ix_id in ix_list:
                ix_node = self.graph.get_node(ix_id)
                if ix_node:
                    operation = ix_node.get("operation", "").lower()
                    method = ix_node.get("method", "").lower()
                    if any(op in operation or op in method for op in ["insert", "update", "delete", "post", "put", "patch", "create", "write"]):
                        has_write = True
                        break

            if has_write:
                # Check if already has depends_on
                existing = self.graph.get_edges_from(cs_id, "depends_on")
                depends_on_contract = any(e.get("to") == contract_id for e in existing)

                if not depends_on_contract:
                    # Add depends_on edge
                    self.new_edges.append({
                        "from": cs_id,
                        "to": contract_id,
                        "type": "depends_on"
                    })
                    print(f"    Wired {cs_id} to {contract_id}")

    def _nonterminal_expansion(self):
        """A.2: Nonterminal expansion"""

        # Expand Capabilities without Scenarios
        capabilities = self.graph.get_nodes_by_type("Capability")
        for cap in capabilities:
            cap_id = cap.get("id")
            scenarios = [e for e in self.graph.get_edges_from(cap_id, "traces_to")
                       if self.graph.get_node(e.get("to", "")) and
                       self.graph.get_node(e.get("to", "")).get("type") == "Scenario"]

            if not scenarios:
                # Create at least happy scenario
                scenario_id = f"scenario:{cap_id.replace('cap:', '')}"
                scenario = {
                    "id": scenario_id,
                    "type": "Scenario",
                    "stmt": f"Happy path scenario for {cap.get('stmt', cap_id)}",
                    "status": "Open",
                    "requirements": [],
                    "tests": [],
                    "acceptance": [],
                    "checklist": [],
                    "evidence": [],
                    "unaccounted": [],
                    "updated_at": datetime.now(timezone.utc).isoformat()
                }
                self.new_nodes[scenario_id] = scenario
                self.new_edges.append({
                    "from": cap_id,
                    "to": scenario_id,
                    "type": "traces_to"
                })
                print(f"  Created scenario for {cap_id}")

        # Expand Requirements missing Contract or ChangeSpec
        requirements = self.graph.get_nodes_by_type("Requirement")
        for req in requirements:
            req_id = req.get("id")

            # Check for Contracts
            contracts = req.get("contracts", [])
            has_api_contract = any("api" in cid for cid in contracts)
            has_data_contract = any("data" in cid for cid in contracts)

            if not has_api_contract:
                # Create API contract
                contract_id = f"contract:api-{req_id.replace('req:', '')}"
                if not self.graph.has_node(contract_id):
                    contract = {
                        "id": contract_id,
                        "type": "Contract",
                        "stmt": f"API contract for {req.get('stmt', req_id)} (endpoints, errors, idempotency, timeouts, versioning, rate limits, observability)",
                        "status": "Open",
                        "contract_type": "api",
                        "versioning": "semver:minor",
                        "checklist": [
                            "authZ defined",
                            "rate_limit defined",
                            "versioning defined",
                            "error taxonomy defined",
                            "idempotency defined",
                            "timeouts defined",
                            "observability defined"
                        ],
                        "evidence": [],
                        "unaccounted": [],
                        "updated_at": datetime.now(timezone.utc).isoformat()
                    }
                    self.new_nodes[contract_id] = contract
                    self.new_edges.append({
                        "from": req_id,
                        "to": contract_id,
                        "type": "depends_on"
                    })
                    if req_id not in self.changed_nodes:
                        self.changed_nodes.add(req_id)
                        req["contracts"] = req.get("contracts", []) + [contract_id]

            if not has_data_contract:
                # Create Data contract if needed (only for data operations)
                stmt = req.get("stmt", "").lower()
                if any(keyword in stmt for keyword in ["data", "storage", "database", "schema", "persist"]):
                    contract_id = f"contract:data-{req_id.replace('req:', '')}"
                    if not self.graph.has_node(contract_id):
                        contract = {
                            "id": contract_id,
                            "type": "Contract",
                            "stmt": f"Data contract for {req.get('stmt', req_id)} (schema, indices, migration/backfill, retention, region/PII)",
                            "status": "Open",
                            "contract_type": "data",
                            "checklist": [
                                "schema defined",
                                "indices defined",
                                "migration/backfill defined",
                                "retention defined",
                                "region/PII defined"
                            ],
                            "evidence": [],
                            "unaccounted": [],
                            "updated_at": datetime.now(timezone.utc).isoformat()
                        }
                        self.new_nodes[contract_id] = contract
                        self.new_edges.append({
                            "from": req_id,
                            "to": contract_id,
                            "type": "depends_on"
                        })
                        if req_id not in self.changed_nodes:
                            self.changed_nodes.add(req_id)
                            req["contracts"] = req.get("contracts", []) + [contract_id]

            # Check for ChangeSpec
            change_specs = req.get("change_specs", [])
            if not change_specs:
                # Create ChangeSpec
                change_id = f"change:{req_id.replace('req:', '')}"
                if not self.graph.has_node(change_id):
                    change = {
                        "id": change_id,
                        "type": "ChangeSpec",
                        "stmt": f"Implement {req.get('stmt', req_id)}",
                        "status": "Open",
                        "implements": [req_id],
                        "ix": [],
                        "accept": [],
                        "checklist": [],
                        "est_h": 0,
                        "owner": "",
                        "rollout_flag": "",
                        "evidence": [],
                        "unaccounted": [],
                        "simple": False,
                        "updated_at": datetime.now(timezone.utc).isoformat()
                    }
                    self.new_nodes[change_id] = change
                    self.new_edges.append({
                        "from": change_id,
                        "to": req_id,
                        "type": "implements"
                    })
                    if req_id not in self.changed_nodes:
                        self.changed_nodes.add(req_id)
                        req["change_specs"] = req.get("change_specs", []) + [change_id]
                    print(f"  Created ChangeSpec for {req_id}")

        # Expand ChangeSpecs missing InteractionSpecs
        change_specs = self.graph.get_nodes_by_type("ChangeSpec")
        for cs in change_specs:
            cs_id = cs.get("id")
            if cs.get("simple", False):
                continue

            ix_list = cs.get("ix", [])
            if not ix_list:
                # Create minimal InteractionSpecs (one per interface/operation/state)
                self._create_interaction_specs_for_changespec(cs)

    def _create_interaction_specs_for_changespec(self, changespec: Dict):
        """Create InteractionSpecs for a ChangeSpec using state clustering"""
        cs_id = changespec.get("id")
        req_id = changespec.get("implements", [None])[0] if changespec.get("implements") else None
        req_node = self.graph.get_node(req_id) if req_id else None
        stmt = changespec.get("stmt", "").lower()

        # Determine interfaces and operations based on ChangeSpec
        interfaces = ["API"]  # Default
        operations = ["create", "read", "update", "delete"]  # Default CRUD

        # Adjust based on statement
        if "read" in stmt or "get" in stmt:
            operations = ["read"]
        elif "write" in stmt or "store" in stmt:
            operations = ["create", "update"]
        elif "delete" in stmt or "remove" in stmt:
            operations = ["delete"]

        # Create InteractionSpecs with state clustering
        for interface in interfaces:
            for operation in operations:
                # Create one IX per state cluster (minimal: fresh token, under quota, ok network)
                state_cluster = {
                    "token": "fresh",
                    "quota": "under",
                    "network": "ok"
                }

                # For read operations, add cache state
                if operation == "read":
                    state_cluster["cache"] = "miss"  # Start with miss, can add hit variant

                ix_id = f"ix:{cs_id.replace('change:', '')}-{interface.lower()}-{operation}-fresh-under-ok"
                if operation == "read":
                    ix_id += "-miss"

                if not self.graph.has_node(ix_id):
                    ix = {
                        "id": ix_id,
                        "type": "InteractionSpec",
                        "stmt": f"{operation.capitalize()} operation via {interface}",
                        "method": f"Svc.{operation}()",
                        "interface": interface,
                        "operation": f"{operation.upper()} /resource" if interface == "API" else f"{operation.upper()} resource",
                        "state": state_cluster,
                        "pre": ["User authenticated", "Resource exists" if operation != "create" else "Input validated"],
                        "in": {
                            "params": "resource_id" if operation != "create" else "resource_data",
                            "headers": ["Authorization"]
                        } if interface == "API" else {
                            "params": "resource_id" if operation != "create" else "resource_data"
                        },
                        "eff": ["Resource created/updated/deleted" if operation != "read" else "Resource returned"],
                        "err": {
                            "retriable": ["5xx", "429", "Network timeout"],
                            "non_retriable": ["400", "401", "403", "404", "413", "415"],
                            "compensation": ["Rollback transaction" if operation != "read" else "None"]
                        },
                        "res": {
                            "timeout_ms": 8000,
                            "retry": {
                                "strategy": "exp",
                                "max": 4,
                                "jitter": True
                            },
                            "idem_key": f"{operation}-{cs_id}" if operation != "read" else None
                        },
                        "obs": {
                            "logs": ["Operation start", "Operation complete"],
                            "metrics": [f"operation_{operation}_count", f"operation_{operation}_duration"],
                            "span": f"{interface.lower()}.{operation}"
                        },
                        "sec": {
                            "authZ": "User owns resource or has permission",
                            "least_priv": "Read/write own resources only",
                            "pii": False
                        },
                        "test": {
                            "mocks": ["Database", "Auth service"],
                            "acc": [f"Given resource exists\nWhen user {operation}s\nThen operation succeeds"]
                        },
                        "depends_on": [f"contract:api-{cs_id.replace('change:', '')}"],
                        "owner": "backend-team",
                        "est_h": 1,
                        "status": "Open",
                        "unaccounted": [],
                        "updated_at": datetime.now(timezone.utc).isoformat()
                    }
                    self.new_nodes[ix_id] = ix
                    self.new_edges.append({
                        "from": ix_id,
                        "to": cs_id,
                        "type": "depends_on"
                    })

                    # Update ChangeSpec
                    if cs_id not in self.changed_nodes:
                        self.changed_nodes.add(cs_id)
                    changespec["ix"] = changespec.get("ix", []) + [ix_id]

        print(f"  Created InteractionSpecs for {cs_id}")

    def _traceability_restoration(self):
        """A.3: Traceability restoration"""

        # Find orphan InteractionSpecs (not reachable via Scenario→Req→Change)
        interaction_specs = self.graph.get_nodes_by_type("InteractionSpec")

        for ix in interaction_specs:
            ix_id = ix.get("id")

            # Check if reachable via ChangeSpec
            change_edges = self.graph.get_edges_to(ix_id, "depends_on")
            change_edges = [e for e in change_edges
                          if self.graph.get_node(e.get("from")) and
                          self.graph.get_node(e.get("from")).get("type") == "ChangeSpec"]

            if not change_edges:
                # Find or create ChangeSpec
                # Try to infer from IX ID
                ix_base = ix_id.replace("ix:", "").split("-")[0]
                change_id = f"change:{ix_base}"

                if self.graph.has_node(change_id):
                    # Link to existing ChangeSpec
                    self.new_edges.append({
                        "from": ix_id,
                        "to": change_id,
                        "type": "depends_on"
                    })
                    change_node = self.graph.get_node(change_id)
                    if change_id not in self.changed_nodes:
                        self.changed_nodes.add(change_id)
                    change_node["ix"] = change_node.get("ix", []) + [ix_id]
                    print(f"  Linked orphan {ix_id} to {change_id}")

    def save_deltas(self, plan_dir: Path):
        """Save new nodes and edges"""
        nodes_dir = plan_dir / "nodes"

        # Save new nodes
        for node_id, node in self.new_nodes.items():
            node_type = node["type"]
            type_dir = nodes_dir / node_type
            type_dir.mkdir(parents=True, exist_ok=True)

            safe_filename = node_id.replace(':', '-').replace('/', '-').replace('&', '-')
            node_file = type_dir / f"{safe_filename}.json"

            with open(node_file, 'w') as f:
                json.dump(node, f, indent=2)

        # Append new edges
        edges_file = plan_dir / "edges.ndjson"
        with open(edges_file, 'a') as f:
            for edge in self.new_edges:
                f.write(json.dumps(edge) + "\n")

        # Update changed nodes
        for node_id in self.changed_nodes:
            node = self.graph.get_node(node_id)
            if node:
                node_file = nodes_dir / node["type"] / f"{node_id.replace(':', '-')}.json"
                if node_file.exists():
                    with open(node_file, 'w') as f:
                        json.dump(node, f, indent=2)


def main():
    """Main entry point"""
    plan_dir = Path("plan-fixed")

    if not plan_dir.exists():
        print(f"Error: {plan_dir} does not exist")
        return 1

    print(f"Loading plan graph from {plan_dir}...")
    graph = PlanGraph(str(plan_dir))
    print(f"Loaded {len(graph.nodes)} nodes and {len(graph.edges)} edges")

    executor = AddendumExecutor(graph)
    result = executor.execute()

    print(f"\nGenerated:")
    print(f"  New nodes: {result['new_nodes']}")
    print(f"  New edges: {result['new_edges']}")
    print(f"  Changed nodes: {result['changed_nodes']}")

    executor.save_deltas(plan_dir)

    print("\nDeltas saved!")
    print("\nNext step: Re-run execute_planning.py to verify P1-P10 proofs")

    return 0


if __name__ == "__main__":
    exit(main())


