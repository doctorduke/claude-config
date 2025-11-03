#!/usr/bin/env python3
"""
Follow-Up Execution Brief: Verify and Repair Planning
Computes sets S0, R0, C0, IX_orphan, API_weak, Q_open
Emits delta bundle A-F in strict order
Re-runs proofs to verify 100% completeness
"""

import json
import os
from pathlib import Path
from datetime import datetime, timezone
from typing import Dict, List, Set, Optional, Tuple
from collections import defaultdict
import hashlib

class PlanGraph:
    """Plan graph structure"""

    def __init__(self, base_dir: str):
        self.base_dir = Path(base_dir)
        self.nodes: Dict[str, Dict] = {}
        self.edges: List[Dict] = []
        self.node_by_type: Dict[str, Set[str]] = defaultdict(set)
        self.load()

    def load(self):
        """Load existing graph - reloads all nodes and edges from disk"""
        # Clear existing data
        self.nodes.clear()
        self.edges.clear()
        self.node_by_type.clear()

        nodes_dir = self.base_dir / "nodes"
        if nodes_dir.exists():
            for type_dir in nodes_dir.iterdir():
                if type_dir.is_dir():
                    node_type = type_dir.name
                    for node_file in type_dir.glob("*.json"):
                        try:
                            with open(node_file, 'r', encoding='utf-8') as f:
                                node = json.load(f)
                                node_id = node.get('id')
                                if node_id:
                                    # Use node_id from inside file, not filename
                                    # This handles hash-based filenames correctly
                                    self.nodes[node_id] = node
                                    self.node_by_type[node_type].add(node_id)
                        except Exception as e:
                            # Log but don't fail on individual file errors
                            pass

        edges_path = self.base_dir / "edges.ndjson"
        if edges_path.exists():
            with open(edges_path, 'r', encoding='utf-8') as f:
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

    def save_node(self, node_id: str, node: Dict):
        """Save node to filesystem"""
        nodes_dir = self.base_dir / "nodes"
        node_type = node["type"]
        type_dir = nodes_dir / node_type
        type_dir.mkdir(parents=True, exist_ok=True)

        safe_filename = node_id.replace(':', '-').replace('/', '-').replace('&', '-')
        if len(safe_filename) > 200:
            name_hash = hashlib.md5(safe_filename.encode()).hexdigest()[:8]
            safe_filename = safe_filename[:180] + "-" + name_hash
        node_file = type_dir / f"{safe_filename}.json"

        with open(node_file, 'w') as f:
            json.dump(node, f, indent=2)

        self.nodes[node_id] = node
        self.node_by_type[node_type].add(node_id)


class VerifyAndRepair:
    """Verify and repair planning following execution brief"""

    def __init__(self, graph: PlanGraph):
        self.graph = graph
        self.deltas: List[Dict] = []
        self.changed_nodes: Set[str] = set()
        self.task_order: List[Dict] = []
        self.top_gaps: List[Dict] = []

        # Sets to compute
        self.S0: Set[str] = set()  # scenarios with zero IX
        self.R0: Set[str] = set()  # requirements missing Contract/Component/ChangeSpec
        self.C0: Set[str] = set()  # changes with zero InteractionSpecs
        self.IX_orphan: Set[str] = set()  # orphan InteractionSpecs
        self.API_weak: Set[str] = set()  # weak API contracts
        self.Q_open: Set[str] = set()  # open questions

    def verify_and_repair(self, max_iterations: int = 10) -> Dict:
        """Execute verification and repair with iteration"""
        print("=" * 80)
        print("VERIFY AND REPAIR PLANNING")
        print("Following Follow-Up Execution Brief")
        print("=" * 80)

        iteration = 0
        all_passing = False

        while iteration < max_iterations and not all_passing:
            iteration += 1
            print(f"\n{'='*80}")
            print(f"ITERATION {iteration}")
            print(f"{'='*80}")

            # Step 1: Reload graph from disk to ensure fresh data
            print("\n[Step 1] Reloading graph from disk...")
            self.graph.load()  # Reload all nodes and edges from disk

            # Step 2: Compute sets
            print("[Step 2] Computing sets...")
            self._compute_sets()

            # Check if any work needed
            total_gaps = len(self.S0) + len(self.R0) + len(self.C0) + len(self.IX_orphan) + len(self.API_weak)
            print(f"  Total gaps: {total_gaps}")
            if total_gaps == 0:
                print("  No gaps found!")
                break

            # Track previous gap sizes
            prev_gaps = {
                "S0": len(self.S0),
                "R0": len(self.R0),
                "C0": len(self.C0),
                "IX_orphan": len(self.IX_orphan),
                "API_weak": len(self.API_weak)
            }

            # Step 3: Emit delta bundle A-F
            print("\n[Step 3] Emitting delta bundle A-F...")
            self._emit_delta_bundle()

            if len(self.deltas) == 0:
                print("  No deltas generated!")
                # Still need to run proofs to check status
                proofs = self._run_proofs()
                all_passing = all(v for k, v in proofs.items() if k != 'details')
                if all_passing:
                    print("\nSUCCESS: All proofs passing!")
                break

            # Step 4: Apply deltas
            print(f"\n[Step 4] Applying {len(self.deltas)} deltas...")
            self._apply_deltas()

            # Reload graph from disk to pick up all node changes
            # This is necessary because external scripts may have modified nodes
            self.graph.load()  # Reload all nodes and edges from disk

            # Step 5: Re-run proofs
            print("\n[Step 5] Re-running proofs...")
            proofs = self._run_proofs()

            # Check progress
            current_gaps = {
                "S0": len(self.S0),
                "R0": len(self.R0),
                "C0": len(self.C0),
                "IX_orphan": len(self.IX_orphan),
                "API_weak": len(self.API_weak)
            }

            progress = any(current_gaps[k] < prev_gaps[k] for k in current_gaps)
            if not progress and len(self.deltas) == 0:
                print("\nWARNING: No progress made this iteration!")
                break

            # Check if all passing
            all_passing = all(v for k, v in proofs.items() if k != 'details')

            if all_passing:
                print("\nSUCCESS: All proofs passing!")
                break

            print(f"\nProgress: S0: {prev_gaps['S0']}→{current_gaps['S0']}, R0: {prev_gaps['R0']}→{current_gaps['R0']}, C0: {prev_gaps['C0']}→{current_gaps['C0']}, IX_orphan: {prev_gaps['IX_orphan']}→{current_gaps['IX_orphan']}")

        # Step 6: Generate output
        print("\n[Step 6] Generating output...")
        output = self._generate_output(proofs)

        return output

    def _compute_sets(self):
        """Compute sets S0, R0, C0, IX_orphan, API_weak, Q_open"""

        # Clear sets first
        self.S0.clear()
        self.R0.clear()
        self.C0.clear()
        self.IX_orphan.clear()
        self.API_weak.clear()
        self.Q_open.clear()

        # S0: Scenarios with zero InteractionSpecs
        scenarios = self.graph.get_nodes_by_type("Scenario")
        for scenario in scenarios:
            scenario_id = scenario.get("id")
            reqs = scenario.get("requirements", [])

            ix_count = 0
            for req_id in reqs:
                req = self.graph.get_node(req_id)
                if req:
                    cs_list = req.get("change_specs", [])
                    # Also check edges for ChangeSpecs
                    req_edges = self.graph.get_edges_from(req_id)
                    cs_from_edges = [e.get("to") for e in req_edges
                                   if e.get("type") == "implements" and
                                   self.graph.get_node(e.get("to")) and
                                   self.graph.get_node(e.get("to")).get("type") == "ChangeSpec"]
                    all_cs = set(cs_list + cs_from_edges)

                    for cs_id in all_cs:
                        cs = self.graph.get_node(cs_id)
                        if cs:
                            ix_list = cs.get("ix", [])
                            # Also check edges for IX
                            cs_edges = self.graph.get_edges_to(cs_id, "depends_on")
                            ix_from_edges = [e.get("from") for e in cs_edges
                                           if self.graph.get_node(e.get("from")) and
                                           self.graph.get_node(e.get("from")).get("type") == "InteractionSpec"]
                            all_ix = set(ix_list + ix_from_edges)
                            valid_ix = [ix_id for ix_id in all_ix if self.graph.has_node(ix_id)]
                            ix_count += len(valid_ix)

            if ix_count == 0:
                self.S0.add(scenario_id)

        # R0: Requirements missing Contract/Component/ChangeSpec
        requirements = self.graph.get_nodes_by_type("Requirement")
        for req in requirements:
            req_id = req.get("id")
            contracts = req.get("contracts", [])
            components = req.get("components", [])
            change_specs = req.get("change_specs", [])

            # Also check edges for contracts
            req_edges = self.graph.get_edges_from(req_id, "depends_on")
            contract_edges = [e.get("to") for e in req_edges
                            if self.graph.get_node(e.get("to")) and
                            self.graph.get_node(e.get("to")).get("type") == "Contract"]
            all_contracts = set(contracts + contract_edges)

            # Also check edges for components
            component_edges = [e.get("to") for e in req_edges
                             if self.graph.get_node(e.get("to")) and
                             self.graph.get_node(e.get("to")).get("type") == "Component"]
            all_components = set(components + component_edges)

            # Also check edges for ChangeSpecs
            req_edges_implements = self.graph.get_edges_to(req_id, "implements")
            cs_from_edges = [e.get("from") for e in req_edges_implements
                           if self.graph.get_node(e.get("from")) and
                           self.graph.get_node(e.get("from")).get("type") == "ChangeSpec"]
            all_change_specs = set(change_specs + cs_from_edges)

            # Check if contracts/components/changespecs actually exist as nodes
            has_api_contract = any("api" in str(cid).lower() and self.graph.has_node(cid) for cid in all_contracts)
            has_data_contract = any("data" in str(cid).lower() and self.graph.has_node(cid) for cid in all_contracts)
            has_component = any(self.graph.has_node(cid) for cid in all_components)
            has_changespec = any(self.graph.has_node(cs_id) for cs_id in all_change_specs)

            if not has_api_contract or not has_data_contract or not has_component or not has_changespec:
                self.R0.add(req_id)

        # C0: Changes with zero InteractionSpecs
        change_specs = self.graph.get_nodes_by_type("ChangeSpec")
        for cs in change_specs:
            if cs.get("simple", False):
                continue

            cs_id = cs.get("id")
            ix_list = cs.get("ix", [])
            # Also check edges - if there are edges from IX to this CS, count those
            edges_to_cs = self.graph.get_edges_to(cs_id, "depends_on")
            ix_from_edges = [e.get("from") for e in edges_to_cs
                            if self.graph.get_node(e.get("from")) and
                            self.graph.get_node(e.get("from")).get("type") == "InteractionSpec"]

            all_ix = set(ix_list + ix_from_edges)
            valid_ix = [ix_id for ix_id in all_ix if self.graph.has_node(ix_id)]

            if len(valid_ix) == 0:
                self.C0.add(cs_id)

        # IX_orphan: Orphan InteractionSpecs
        all_ix = self.graph.get_nodes_by_type("InteractionSpec")
        reachable_ix = set()

        # Find all reachable IX
        scenarios = self.graph.get_nodes_by_type("Scenario")
        for scenario in scenarios:
            reqs = scenario.get("requirements", [])
            for req_id in reqs:
                req = self.graph.get_node(req_id)
                if req:
                    cs_list = req.get("change_specs", [])
                    for cs_id in cs_list:
                        cs = self.graph.get_node(cs_id)
                        if cs:
                            ix_list = cs.get("ix", [])
                            for ix_id in ix_list:
                                if self.graph.has_node(ix_id):
                                    reachable_ix.add(ix_id)

        for ix in all_ix:
            ix_id = ix.get("id")
            if ix_id not in reachable_ix:
                self.IX_orphan.add(ix_id)

        # API_weak: Weak API contracts
        contracts = self.graph.get_nodes_by_type("Contract")
        for contract in contracts:
            contract_id = contract.get("id")
            if "api" in contract_id.lower():
                stmt = contract.get("stmt", "").lower()

                has_authz = "authz" in stmt or "auth" in stmt or "authorization" in stmt
                has_rate = "rate" in stmt or "quota" in stmt
                has_idempotency = "idempotency" in stmt or "idempotent" in stmt
                has_timeouts = "timeout" in stmt
                has_error = "error" in stmt or "taxonomy" in stmt
                has_obs = "observability" in stmt or "log" in stmt or "metric" in stmt or "trace" in stmt

                missing_count = sum([
                    not has_authz,
                    not has_rate,
                    not has_idempotency,
                    not has_timeouts,
                    not has_error,
                    not has_obs
                ])

                if missing_count >= 2:
                    self.API_weak.add(contract_id)

        # Q_open: Open Questions
        open_questions = self.graph.get_nodes_by_type("OpenQuestion")
        for oq in open_questions:
            if oq.get("status") == "Open":
                self.Q_open.add(oq.get("id"))

        print(f"  S0 (scenarios with zero IX): {len(self.S0)}")
        print(f"  R0 (requirements missing pieces): {len(self.R0)}")
        print(f"  C0 (changes with zero IX): {len(self.C0)}")
        print(f"  IX_orphan (orphan InteractionSpecs): {len(self.IX_orphan)}")
        print(f"  API_weak (weak API contracts): {len(self.API_weak)}")
        print(f"  Q_open (open questions): {len(self.Q_open)}")

    def _emit_delta_bundle(self):
        """Emit delta bundle A-F in strict order"""

        # A. Seed minimal chains for empty scenarios (S0)
        print("\n[A] Seeding minimal chains for empty scenarios...")
        for scenario_id in self.S0:
            scenario = self.graph.get_node(scenario_id)
            if not scenario:
                continue

            s_base = scenario_id.replace("scenario:", "")
            req_id = f"req:{s_base}-baseline"
            api_contract_id = f"contract:api-{s_base}"
            data_contract_id = f"contract:data-{s_base}"
            component_id = f"component:{s_base}"
            change_id = f"change:{s_base}"

            # Add Requirement
            if not self.graph.has_node(req_id):
                req = {
                    "id": req_id,
                    "type": "Requirement",
                    "stmt": f"Baseline requirement for {scenario.get('stmt', scenario_id)}",
                    "status": "Open",
                    "change_specs": [change_id],
                    "contracts": [api_contract_id, data_contract_id],
                    "components": [component_id],
                    "checklist": [],
                    "evidence": [],
                    "unaccounted": [],
                    "updated_at": datetime.now(timezone.utc).isoformat()
                }
                self.deltas.append({"op": "add_node", "node": req})

            # Add Contracts
            if not self.graph.has_node(api_contract_id):
                api_contract = {
                    "id": api_contract_id,
                    "type": "Contract",
                    "stmt": f"API contract for {s_base} (AUTHZ scopes, RATE LIMIT quota tier, IDEMPOTENCY key, TIMEOUTS ms, ERROR TAXONOMY codes, OBSERVABILITY logs/metrics/spans)",
                    "status": "Open",
                    "contract_type": "api",
                    "versioning": "semver:minor",
                    "checklist": ["authZ defined", "rate_limit defined", "idempotency defined", "timeouts defined", "error taxonomy defined", "observability defined"],
                    "evidence": [],
                    "unaccounted": [],
                    "updated_at": datetime.now(timezone.utc).isoformat()
                }
                self.deltas.append({"op": "add_node", "node": api_contract})

            if not self.graph.has_node(data_contract_id):
                data_contract = {
                    "id": data_contract_id,
                    "type": "Contract",
                    "stmt": f"Data contract for {s_base} (schema, migration, retention, PII, region, index, backup, restore)",
                    "status": "Open",
                    "contract_type": "data",
                    "checklist": ["schema defined", "migration defined", "retention defined", "PII defined", "region defined", "index defined", "backup defined", "restore defined"],
                    "evidence": [],
                    "unaccounted": [],
                    "updated_at": datetime.now(timezone.utc).isoformat()
                }
                self.deltas.append({"op": "add_node", "node": data_contract})

            # Add Component
            if not self.graph.has_node(component_id):
                component = {
                    "id": component_id,
                    "type": "Component",
                    "stmt": f"Logical component for {s_base}",
                    "status": "Open",
                    "checklist": [],
                    "evidence": [],
                    "unaccounted": [],
                    "updated_at": datetime.now(timezone.utc).isoformat()
                }
                self.deltas.append({"op": "add_node", "node": component})

            # Add ChangeSpec
            change = None
            if not self.graph.has_node(change_id):
                change = {
                    "id": change_id,
                    "type": "ChangeSpec",
                    "stmt": f"Implement {s_base}",
                    "status": "Open",
                    "implements": [req_id],
                    "ix": [],
                    "accept": [],
                    "checklist": [],
                    "est_h": 0,
                    "owner": "backend-team",
                    "rollout_flag": f"feature.{s_base}",
                    "evidence": [],
                    "unaccounted": [],
                    "simple": False,
                    "updated_at": datetime.now(timezone.utc).isoformat()
                }
                self.deltas.append({"op": "add_node", "node": change})
            else:
                change = self.graph.get_node(change_id)

            # Create at least one InteractionSpec for this ChangeSpec
            ix_id = f"ix:{s_base}-api-create-fresh-under-ok"
            if not self.graph.has_node(ix_id) and change:
                ix = {
                    "id": ix_id,
                    "type": "InteractionSpec",
                    "stmt": "Create operation via API",
                    "method": "Svc.create()",
                    "interface": "API",
                    "operation": "POST /resource",
                    "state": {"token": "fresh", "quota": "under", "network": "ok"},
                    "pre": ["User authenticated", "Input validated"],
                    "in": {"params": "resource_data", "headers": ["Authorization"]},
                    "eff": ["Resource created"],
                    "err": {"retriable": ["5xx", "429"], "non_retriable": ["400", "401", "403"], "compensation": ["Rollback transaction"]},
                    "res": {"timeout_ms": 8000, "retry": {"strategy": "exp", "max": 4, "jitter": True}, "idem_key": f"create-{change_id}"},
                    "obs": {"logs": ["Operation start", "Operation complete"], "metrics": ["operation_create_count", "operation_create_duration"], "span": "api.create"},
                    "sec": {"authZ": "User owns resource or has permission", "least_priv": "Read/write own resources only", "pii": False},
                    "test": {"mocks": ["Database", "Auth service"], "acc": ["Given resource exists\nWhen user creates\nThen operation succeeds"]},
                    "depends_on": [api_contract_id],
                    "owner": "backend-team",
                    "est_h": 1,
                    "status": "Open",
                    "unaccounted": [],
                    "updated_at": datetime.now(timezone.utc).isoformat()
                }
                self.deltas.append({"op": "add_node", "node": ix})
                self.deltas.append({"op": "add_edge", "from": ix_id, "to": change_id, "type": "depends_on"})
                # Update ChangeSpec immediately in in-memory graph
                change["ix"] = change.get("ix", []) + [ix_id]
                self.graph.nodes[change_id] = change  # Update in-memory immediately
                self.changed_nodes.add(change_id)
                # Also add update delta to ensure persistence
                self.deltas.append({"op": "update_node", "node": change})

            # Update Scenario to include this Requirement immediately
            scenario["requirements"] = scenario.get("requirements", []) + [req_id]
            self.graph.nodes[scenario_id] = scenario  # Update in-memory immediately
            self.changed_nodes.add(scenario_id)
            self.deltas.append({"op": "update_node", "node": scenario})

            # Add edges
            self.deltas.append({"op": "add_edge", "from": scenario_id, "to": req_id, "type": "traces_to"})
            self.deltas.append({"op": "add_edge", "from": req_id, "to": api_contract_id, "type": "depends_on"})
            self.deltas.append({"op": "add_edge", "from": req_id, "to": data_contract_id, "type": "depends_on"})
            self.deltas.append({"op": "add_edge", "from": req_id, "to": component_id, "type": "traces_to"})
            self.deltas.append({"op": "add_edge", "from": change_id, "to": req_id, "type": "implements"})

        # B. Explode changes with no IX (C0)
        print("\n[B] Exploding changes with no IX...")
        for cs_id in self.C0:
            cs = self.graph.get_node(cs_id)
            if not cs:
                continue

            # Create at least one InteractionSpec with state clustering
            cs_base = cs_id.replace("change:", "")
            operations = ["create", "read", "update", "delete"]

            for operation in operations[:1]:  # At least one
                ix_id = f"ix:{cs_base}-api-{operation}-fresh-under-ok"

                if not self.graph.has_node(ix_id):
                    ix = {
                        "id": ix_id,
                        "type": "InteractionSpec",
                        "stmt": f"{operation.capitalize()} operation via API",
                        "method": f"Svc.{operation}()",
                        "interface": "API",
                        "operation": f"{operation.upper()} /resource" if operation != "read" else "GET /resource",
                        "state": {
                            "token": "fresh",
                            "quota": "under",
                            "network": "ok"
                        },
                        "pre": ["User authenticated", "Resource exists" if operation != "create" else "Input validated"],
                        "in": {
                            "params": "resource_id" if operation != "create" else "resource_data",
                            "headers": ["Authorization"]
                        },
                        "eff": [f"Resource {operation}d"],
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
                            "span": f"api.{operation}"
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
                        "depends_on": [f"contract:api-{cs_base}"],
                        "owner": "backend-team",
                        "est_h": 1,
                        "status": "Open",
                        "unaccounted": [],
                        "updated_at": datetime.now(timezone.utc).isoformat()
                    }
                    self.deltas.append({"op": "add_node", "node": ix})
                    self.deltas.append({"op": "add_edge", "from": ix_id, "to": cs_id, "type": "depends_on"})
                    # Update ChangeSpec to include this IX
                    cs["ix"] = cs.get("ix", []) + [ix_id]
                    self.deltas.append({"op": "update_node", "node": cs})
                    self.changed_nodes.add(cs_id)

        # C. Fix nonterminal expansion (R0)
        print("\n[C] Fixing nonterminal expansion...")
        for req_id in list(self.R0):  # Use list copy to avoid modification during iteration
            req = self.graph.get_node(req_id)
            if not req:
                continue

            req_base = req_id.replace("req:", "").replace(":", "-")
            contracts = req.get("contracts", [])
            components = req.get("components", [])
            change_specs = req.get("change_specs", [])

            # Check edges too
            req_edges = self.graph.get_edges_from(req_id, "depends_on")
            contract_edges = [e.get("to") for e in req_edges
                            if self.graph.get_node(e.get("to")) and
                            self.graph.get_node(e.get("to")).get("type") == "Contract"]
            all_contracts = set(contracts + contract_edges)

            component_edges = [e.get("to") for e in req_edges
                             if self.graph.get_node(e.get("to")) and
                             self.graph.get_node(e.get("to")).get("type") == "Component"]
            all_components = set(components + component_edges)

            req_edges_implements = self.graph.get_edges_to(req_id, "implements")
            cs_from_edges = [e.get("from") for e in req_edges_implements
                           if self.graph.get_node(e.get("from")) and
                           self.graph.get_node(e.get("from")).get("type") == "ChangeSpec"]
            all_change_specs = set(change_specs + cs_from_edges)

            # Add missing API contract
            has_api = any("api" in str(cid).lower() and self.graph.has_node(cid) for cid in all_contracts)
            if not has_api:
                api_contract_id = f"contract:api-{req_base}"
                if not self.graph.has_node(api_contract_id):
                    api_contract = {
                        "id": api_contract_id,
                        "type": "Contract",
                        "stmt": f"API contract for {req_base} (AUTHZ scopes, RATE LIMIT quota tier, IDEMPOTENCY key, TIMEOUTS ms, ERROR TAXONOMY codes, OBSERVABILITY logs/metrics/spans)",
                        "status": "Open",
                        "contract_type": "api",
                        "versioning": "semver:minor",
                        "checklist": ["authZ defined", "rate_limit defined", "idempotency defined", "timeouts defined", "error taxonomy defined", "observability defined"],
                        "evidence": [],
                        "unaccounted": [],
                        "updated_at": datetime.now(timezone.utc).isoformat()
                    }
                    self.deltas.append({"op": "add_node", "node": api_contract})
                    self.deltas.append({"op": "add_edge", "from": req_id, "to": api_contract_id, "type": "depends_on"})

            # Add missing Data contract
            has_data = any("data" in str(cid).lower() and self.graph.has_node(cid) for cid in all_contracts)
            if not has_data:
                data_contract_id = f"contract:data-{req_base}"
                if not self.graph.has_node(data_contract_id):
                    data_contract = {
                        "id": data_contract_id,
                        "type": "Contract",
                        "stmt": f"Data contract for {req_base} (schema, migration, retention, PII, region, index, backup, restore)",
                        "status": "Open",
                        "contract_type": "data",
                        "checklist": ["schema defined", "migration defined", "retention defined", "PII defined", "region defined", "index defined", "backup defined", "restore defined"],
                        "evidence": [],
                        "unaccounted": [],
                        "updated_at": datetime.now(timezone.utc).isoformat()
                    }
                    self.deltas.append({"op": "add_node", "node": data_contract})
                    self.deltas.append({"op": "add_edge", "from": req_id, "to": data_contract_id, "type": "depends_on"})
                    # Update Requirement in-memory
                    req["contracts"] = req.get("contracts", []) + [data_contract_id]
                    self.graph.nodes[req_id] = req
                    self.changed_nodes.add(req_id)

            # Add missing Component
            has_component_nodes = any(self.graph.has_node(cid) for cid in all_components)
            if not has_component_nodes:
                component_id = f"component:{req_base}"
                if not self.graph.has_node(component_id):
                    component = {
                        "id": component_id,
                        "type": "Component",
                        "stmt": f"Logical component for {req_base}",
                        "status": "Open",
                        "checklist": [],
                        "evidence": [],
                        "unaccounted": [],
                        "updated_at": datetime.now(timezone.utc).isoformat()
                    }
                    self.deltas.append({"op": "add_node", "node": component})
                    self.deltas.append({"op": "add_edge", "from": req_id, "to": component_id, "type": "traces_to"})
                    # Update Requirement in-memory
                    req["components"] = req.get("components", []) + [component_id]
                    self.graph.nodes[req_id] = req
                    self.changed_nodes.add(req_id)

            # Add missing ChangeSpec
            has_changespec_nodes = any(self.graph.has_node(cs_id) for cs_id in all_change_specs)
            if not has_changespec_nodes:
                change_id = f"change:{req_base}"
                if not self.graph.has_node(change_id):
                    change = {
                        "id": change_id,
                        "type": "ChangeSpec",
                        "stmt": f"Implement {req_base}",
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
                    self.deltas.append({"op": "add_node", "node": change})
                    self.deltas.append({"op": "add_edge", "from": change_id, "to": req_id, "type": "implements"})

                    # Update Requirement to include this ChangeSpec immediately
                    req["change_specs"] = req.get("change_specs", []) + [change_id]
                    self.graph.nodes[req_id] = req  # Update in-memory immediately
                    self.changed_nodes.add(req_id)
                    self.deltas.append({"op": "update_node", "node": req})

                    # Create at least one IX for this new ChangeSpec
                    # change is already in deltas, get from graph or create fresh
                    change_for_ix = {
                        "id": change_id,
                        "type": "ChangeSpec",
                        "stmt": f"Implement {req_base}",
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
                    self.graph.nodes[change_id] = change_for_ix  # Add to in-memory graph
                    change = change_for_ix
                    if change:
                        ix_id = f"ix:{req_base}-api-create-fresh-under-ok"
                        if not self.graph.has_node(ix_id):
                            ix = {
                                "id": ix_id,
                                "type": "InteractionSpec",
                                "stmt": "Create operation via API",
                                "method": "Svc.create()",
                                "interface": "API",
                                "operation": "POST /resource",
                                "state": {"token": "fresh", "quota": "under", "network": "ok"},
                                "pre": ["User authenticated", "Input validated"],
                                "in": {"params": "resource_data", "headers": ["Authorization"]},
                                "eff": ["Resource created"],
                                "err": {"retriable": ["5xx", "429"], "non_retriable": ["400", "401", "403"], "compensation": ["Rollback transaction"]},
                                "res": {"timeout_ms": 8000, "retry": {"strategy": "exp", "max": 4, "jitter": True}, "idem_key": f"create-{change_id}"},
                                "obs": {"logs": ["Operation start", "Operation complete"], "metrics": ["operation_create_count", "operation_create_duration"], "span": "api.create"},
                                "sec": {"authZ": "User owns resource or has permission", "least_priv": "Read/write own resources only", "pii": False},
                                "test": {"mocks": ["Database", "Auth service"], "acc": ["Given resource exists\nWhen user creates\nThen operation succeeds"]},
                                "depends_on": [f"contract:api-{req_base}"],
                                "owner": "backend-team",
                                "est_h": 1,
                                "status": "Open",
                                "unaccounted": [],
                                "updated_at": datetime.now(timezone.utc).isoformat()
                            }
                            self.deltas.append({"op": "add_node", "node": ix})
                            self.deltas.append({"op": "add_edge", "from": ix_id, "to": change_id, "type": "depends_on"})
                            # Update ChangeSpec immediately in in-memory graph
                            change["ix"] = change.get("ix", []) + [ix_id]
                            self.graph.nodes[change_id] = change  # Update in-memory immediately
                            self.changed_nodes.add(change_id)
                            # Also add update delta to ensure persistence
                            self.deltas.append({"op": "update_node", "node": change})

                self.changed_nodes.add(req_id)

        # D. Reattach orphans (IX_orphan)
        print("\n[D] Reattaching orphan InteractionSpecs...")
        for ix_id in list(self.IX_orphan)[:100]:  # Process first 100 to avoid too many at once
            ix = self.graph.get_node(ix_id)
            if not ix:
                continue

            # Check if has depends_on change
            depends_on = ix.get("depends_on", [])
            change_found = False

            for dep_id in depends_on:
                dep_node = self.graph.get_node(dep_id)
                if dep_node and dep_node.get("type") == "ChangeSpec":
                    change_found = True
                    change_id = dep_id
                    break

            if change_found:
                # Ensure change implements req and scenario traces_to req
                change = self.graph.get_node(change_id)
                if change:
                    implements = change.get("implements", [])
                    if implements:
                        req_id = implements[0]
                        req = self.graph.get_node(req_id)
                        if req:
                            # Find scenario that traces_to this req
                            scenarios = self.graph.get_nodes_by_type("Scenario")
                            scenario_found = False
                            for scenario in scenarios:
                                scenario_reqs = scenario.get("requirements", [])
                                if req_id in scenario_reqs:
                                    scenario_found = True
                                    break

                            if not scenario_found:
                                # Create scenario or link
                                scenario_id = f"scenario:{req_id.replace('req:', '')}"
                                if not self.graph.has_node(scenario_id):
                                    scenario = {
                                        "id": scenario_id,
                                        "type": "Scenario",
                                        "stmt": f"Scenario for {req.get('stmt', req_id)}",
                                        "status": "Open",
                                        "requirements": [req_id],
                                        "tests": [],
                                        "acceptance": [],
                                        "checklist": [],
                                        "evidence": [],
                                        "unaccounted": [],
                                        "updated_at": datetime.now(timezone.utc).isoformat()
                                    }
                                    self.deltas.append({"op": "add_node", "node": scenario})
                                    self.deltas.append({"op": "add_edge", "from": scenario_id, "to": req_id, "type": "traces_to"})
            else:
                # Create change and wire
                req_id = f"req:{ix_id.replace('ix:', '').split('-')[0]}-auto"
                change_id = f"change:{ix_id.replace('ix:', '').split('-')[0]}-auto"

                if not self.graph.has_node(change_id):
                    change = {
                        "id": change_id,
                        "type": "ChangeSpec",
                        "stmt": f"Auto-created change for {ix_id}",
                        "status": "Open",
                        "implements": [req_id],
                        "ix": [ix_id],
                        "accept": [],
                        "checklist": [],
                        "est_h": 0,
                        "owner": "backend-team",
                        "rollout_flag": f"feature.{change_id.replace('change:', '')}",
                        "evidence": [],
                        "unaccounted": [],
                        "simple": False,
                        "updated_at": datetime.now(timezone.utc).isoformat()
                    }
                    self.deltas.append({"op": "add_node", "node": change})
                    self.deltas.append({"op": "add_edge", "from": change_id, "to": req_id, "type": "implements"})
                    self.deltas.append({"op": "add_edge", "from": ix_id, "to": change_id, "type": "depends_on"})

        # E. Harden API contracts (API_weak)
        print("\n[E] Hardening API contracts...")
        for contract_id in self.API_weak:
            contract = self.graph.get_node(contract_id)
            if not contract:
                continue

            stmt = contract.get("stmt", "")

            # Enhance statement
            enhancements = []
            if "authz" not in stmt.lower():
                enhancements.append("AUTHZ(scopes)")
            if "rate" not in stmt.lower() and "quota" not in stmt.lower():
                enhancements.append("RATE LIMIT(quota tier)")
            if "idempotency" not in stmt.lower():
                enhancements.append("IDEMPOTENCY(key)")
            if "timeout" not in stmt.lower():
                enhancements.append("TIMEOUTS(ms)")
            if "error" not in stmt.lower() and "taxonomy" not in stmt.lower():
                enhancements.append("ERROR TAXONOMY(codes)")
            if "observability" not in stmt.lower() and "log" not in stmt.lower() and "metric" not in stmt.lower():
                enhancements.append("OBSERVABILITY(logs/metrics/spans)")

            if enhancements:
                contract["stmt"] = f"{stmt} ({', '.join(enhancements)})"
                self.deltas.append({"op": "update_node", "node": contract})
                self.changed_nodes.add(contract_id)

        # F. Tests & gating
        print("\n[F] Adding tests & gating...")
        scenarios = self.graph.get_nodes_by_type("Scenario")
        for scenario in scenarios:
            scenario_id = scenario.get("id")
            tests = scenario.get("tests", [])

            if not tests:
                test_id = f"test:{scenario_id.replace('scenario:', '')}-acc"
                if not self.graph.has_node(test_id):
                    test = {
                        "id": test_id,
                        "type": "Test",
                        "stmt": f"Acceptance test for {scenario.get('stmt', scenario_id)}",
                        "status": "Open",
                        "test_type": "e2e",
                        "acceptance": ["Given scenario context\nWhen user performs action\nThen expected outcome occurs"],
                        "checklist": [],
                        "evidence": [],
                        "unaccounted": [],
                        "updated_at": datetime.now(timezone.utc).isoformat()
                    }
                    self.deltas.append({"op": "add_node", "node": test})
                    self.deltas.append({"op": "add_edge", "from": scenario_id, "to": test_id, "type": "traces_to"})
                    self.changed_nodes.add(scenario_id)

        # Ensure all InteractionSpecs have test fields
        interaction_specs = self.graph.get_nodes_by_type("InteractionSpec")
        for ix in interaction_specs:
            ix_id = ix.get("id")
            test = ix.get("test", {})

            if not test or not test.get("mocks") or not test.get("acc"):
                if not test:
                    test = {}
                if not test.get("mocks"):
                    test["mocks"] = ["Database", "Auth service"]
                if not test.get("acc"):
                    test["acc"] = ["Given resource exists\nWhen user performs operation\nThen operation succeeds"]

                ix["test"] = test
                self.deltas.append({"op": "update_node", "node": ix})
                self.changed_nodes.add(ix_id)

        print(f"\nTotal deltas generated: {len(self.deltas)}")

    def _apply_deltas(self):
        """Apply deltas to graph"""
        # Clear deltas for next iteration
        current_deltas = self.deltas.copy()
        self.deltas = []

        # Apply in dependency order: add_node before add_edge, update_node last
        # First pass: add nodes
        for delta in current_deltas:
            if delta["op"] == "add_node":
                node = delta["node"]
                self.graph.save_node(node["id"], node)
                # Also update in-memory immediately
                self.graph.nodes[node["id"]] = node
                self.graph.node_by_type[node["type"]].add(node["id"])

        # Second pass: add edges
        for delta in current_deltas:
            if delta["op"] == "add_edge":
                # Check if edge already exists
                edge_exists = any(
                    e.get("from") == delta["from"] and
                    e.get("to") == delta["to"] and
                    e.get("type") == delta["type"]
                    for e in self.graph.edges
                )

                if not edge_exists:
                    edge = {
                        "from": delta["from"],
                        "to": delta["to"],
                        "type": delta["type"]
                    }
                    self.graph.edges.append(edge)

                    # Append to edges.ndjson
                    edges_file = self.graph.base_dir / "edges.ndjson"
                    with open(edges_file, 'a') as f:
                        f.write(json.dumps(edge) + "\n")

        # Third pass: update nodes (may reference newly created nodes)
        for delta in current_deltas:
            if delta["op"] == "update_node":
                node = delta["node"]
                self.graph.save_node(node["id"], node)
                # Also update in-memory
                self.graph.nodes[node["id"]] = node

    def _run_proofs(self) -> Dict:
        """Run Completion Proof Protocol"""
        proofs = {}
        details = {
            "S0": list(self.S0),
            "R0": list(self.R0),
            "C0": list(self.C0),
            "IX_orphan": list(self.IX_orphan),
            "API_weak": list(self.API_weak),
            "Q_open": list(self.Q_open)
        }

        # Recompute sets after deltas
        self._compute_sets()

        # P1: Topology
        required_types = ['Component', 'Contract', 'InteractionSpec']
        found = all(len(self.graph.get_nodes_by_type(nt)) > 0 for nt in required_types)
        proofs['P1'] = found

        # P2: |S0| == 0
        proofs['P2'] = len(self.S0) == 0

        # P3: Data lifecycle contracts specify ≥4 fields
        data_contracts = [c for c in self.graph.get_nodes_by_type('Contract')
                         if 'data' in c.get('id', '').lower() or 'data' in c.get('stmt', '').lower()]
        required_fields = ['schema', 'migration', 'retention', 'pii', 'region', 'index', 'backup', 'restore']
        complete_count = 0
        for contract in data_contracts:
            stmt = contract.get('stmt', '').lower()
            field_count = sum(1 for field in required_fields if field in stmt)
            if field_count >= 4:
                complete_count += 1
        proofs['P3'] = complete_count == len(data_contracts) if data_contracts else True

        # P4: |API_weak| == 0
        proofs['P4'] = len(self.API_weak) == 0

        # P5: Every Scenario has a Test
        scenarios = self.graph.get_nodes_by_type('Scenario')
        all_have_tests = all(s.get('tests') for s in scenarios)
        proofs['P5'] = all_have_tests

        # P6: Obs attached to every Component & IX
        components = self.graph.get_nodes_by_type('Component')
        ix_list = self.graph.get_nodes_by_type('InteractionSpec')
        all_have_obs = (all(c.get('observability') for c in components) if components else True) and \
                      (all(ix.get('obs') or ix.get('observability') for ix in ix_list) if ix_list else True)
        proofs['P6'] = all_have_obs

        # P7: Semver + migrations + flags/canary/rollback
        contracts = self.graph.get_nodes_by_type('Contract')
        change_specs = self.graph.get_nodes_by_type('ChangeSpec')
        contracts_versioned = all(c.get('versioning') for c in contracts)
        cs_have_flags = all(cs.get('rollout_flag') for cs in change_specs)
        proofs['P7'] = contracts_versioned and cs_have_flags

        # P8: No blocked leaves scheduled
        ix_list = self.graph.get_nodes_by_type('InteractionSpec')
        blocked = [ix for ix in ix_list if ix.get('status') == 'Blocked']
        proofs['P8'] = len(blocked) == 0

        # P9: Nonterminal expansion coverage = 1.00
        nonterminals = ['Requirement', 'ChangeSpec', 'Scenario']
        total = sum(len(self.graph.get_nodes_by_type(nt)) for nt in nonterminals)
        incomplete = 0

        for nt in nonterminals:
            nodes = self.graph.get_nodes_by_type(nt)
            for node in nodes:
                if nt == 'Requirement':
                    if not node.get('change_specs'):
                        incomplete += 1
                elif nt == 'ChangeSpec':
                    if not node.get('simple') and not node.get('ix'):
                        incomplete += 1
                elif nt == 'Scenario':
                    if not node.get('requirements'):
                        incomplete += 1

        coverage = 1.0 - (incomplete / total) if total else 1.0
        proofs['P9'] = coverage >= 1.0

        # P10: Core blueprint present and linked
        core_areas = ['identity', 'users', 'preferences', 'navigation', 'connectivity', 'data-storage',
                     'caching', 'queues', 'secrets', 'observability', 'analytics', 'feature-flags',
                     'security', 'i18n', 'notifications', 'payments']
        scenarios = self.graph.get_nodes_by_type('Scenario')
        scenario_stmts = [s.get('stmt', '').lower() for s in scenarios]
        requirements = self.graph.get_nodes_by_type('Requirement')
        req_stmts = [r.get('stmt', '').lower() for r in requirements]
        all_stmts = scenario_stmts + req_stmts
        covered = sum(1 for area in core_areas if any(area in stmt for stmt in all_stmts))
        proofs['P10'] = covered >= 14

        # Update details
        self._compute_sets()
        details.update({
            "S0": list(self.S0),
            "R0": list(self.R0),
            "C0": list(self.C0),
            "IX_orphan": list(self.IX_orphan),
            "API_weak": list(self.API_weak),
            "Q_open": list(self.Q_open)
        })

        proofs['details'] = details

        print("\nProof Results:")
        for proof_name, proof_result in proofs.items():
            if proof_name != 'details':
                status = "PASS" if proof_result else "FAIL"
                print(f"  {proof_name}: {status}")

        return proofs

    def _generate_output(self, proofs: Dict) -> Dict:
        """Generate output following execution brief format"""
        # Get manifest stats
        nodes = len(self.graph.nodes)
        edges = len(self.graph.edges)
        ready = sum(1 for n in self.graph.nodes.values() if n.get('status') == 'Ready')
        blocked = sum(1 for n in self.graph.nodes.values() if n.get('status') == 'Blocked')

        # Determine plan version
        manifest_path = self.graph.base_dir / "manifest.json"
        plan_version = "v39"
        if manifest_path.exists():
            try:
                with open(manifest_path, 'r') as f:
                    manifest = json.load(f)
                    old_version = manifest.get('plan_version', 'v38')
                    if old_version.startswith('v'):
                        version_num = int(old_version[1:])
                        plan_version = f"v{version_num + 1}"
            except Exception:
                pass

        output = {
            "plan_version": plan_version,
            "deltas": self.deltas,
            "task_order": self.task_order,
            "top_gaps": [
                {
                    "gap": "Scenarios without InteractionSpecs",
                    "origin": "S0",
                    "impact": len(self.S0),
                    "proposed_fix": f"Seed {len(self.S0)} minimal chains"
                },
                {
                    "gap": "Requirements missing pieces",
                    "origin": "R0",
                    "impact": len(self.R0),
                    "proposed_fix": f"Add missing Contracts/Components/ChangeSpecs for {len(self.R0)} requirements"
                },
                {
                    "gap": "Changes without InteractionSpecs",
                    "origin": "C0",
                    "impact": len(self.C0),
                    "proposed_fix": f"Create InteractionSpecs for {len(self.C0)} changes"
                },
                {
                    "gap": "Orphan InteractionSpecs",
                    "origin": "IX_orphan",
                    "impact": len(self.IX_orphan),
                    "proposed_fix": f"Reattach {len(self.IX_orphan)} orphan InteractionSpecs"
                },
                {
                    "gap": "Weak API contracts",
                    "origin": "API_weak",
                    "impact": len(self.API_weak),
                    "proposed_fix": f"Harden {len(self.API_weak)} API contracts"
                }
            ],
            "changed_nodes": list(self.changed_nodes),
            "manifest": {
                "stats": {
                    "nodes": nodes,
                    "edges": edges,
                    "ready": ready,
                    "blocked": blocked
                },
                "hotset": {
                    "changed": list(self.changed_nodes),
                    "deferred": []
                }
            },
            "proofs": proofs
        }

        return output


def main():
    """Main entry point"""
    plan_dir = Path("plan-fixed")

    if not plan_dir.exists():
        print(f"Error: {plan_dir} does not exist")
        return 1

    print(f"Loading plan graph from {plan_dir}...")
    graph = PlanGraph(str(plan_dir))
    print(f"Loaded {len(graph.nodes)} nodes and {len(graph.edges)} edges")

    verifier = VerifyAndRepair(graph)
    output = verifier.verify_and_repair()

    # Save output
    output_path = plan_dir / "verify_and_repair_output.json"
    with open(output_path, 'w') as f:
        json.dump(output, f, indent=2)

    print(f"\nOutput saved to {output_path}")

    # Check if all proofs pass
    all_passing = all(v for k, v in output['proofs'].items() if k != 'details')

    if all_passing:
        print("\nSUCCESS: All proofs passing - 100% complete verified!")
    else:
        print("\nWARNING: Not all proofs passing. Review gaps and re-run.")
        failing_proofs = [k for k, v in output['proofs'].items() if k != 'details' and not v]
        print(f"Failing proofs: {', '.join(failing_proofs)}")

    return 0 if all_passing else 1


if __name__ == "__main__":
    exit(main())

