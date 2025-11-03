#!/usr/bin/env python3
"""
Semantic Content Generator for PlanGraf

Uses goal.md context to generate semantically rich plan content (not boilerplate)
for the 420 generative gaps identified in the analysis.

This generates:
- Semantic Requirements based on goal.md scenarios
- Domain-specific Contracts with actual operations
- Context-aware ChangeSpecs
- Rich InteractionSpecs with real operations from goal.md
"""

import json
import sys
from pathlib import Path
from typing import Dict, List, Set, Optional
from datetime import datetime, timezone
import re


class SemanticContentGenerator:
    """Generate semantic plan content using goal.md context"""

    def __init__(self, plan_dir: Path, goal_file: Path, analysis_file: Path):
        self.plan_dir = plan_dir
        self.goal_file = goal_file
        self.goal_content = self._load_goal()
        self.analysis = self._load_analysis(analysis_file)
        self.graph = self._load_graph()

        # Extract structured content from goal.md
        self.goal_sections = self._parse_goal_sections()

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

    def _parse_goal_sections(self) -> Dict[str, List[str]]:
        """Parse goal.md into structured sections"""
        sections = {
            "objectives": [],
            "epics": {},
            "requirements": {},
            "operations": {}
        }

        lines = self.goal_content.split("\n")
        current_section = None
        current_epic = None
        epic_content = []

        for line in lines:
            # Detect section headers
            if line.startswith("0)") or "Objectives" in line:
                current_section = "objectives"
                sections["objectives"].append(line)
            elif line.startswith("#") or line.startswith("##"):
                # Epic header
                if "Epic" in line or "—" in line:
                    if current_epic and epic_content:
                        sections["epics"][current_epic] = "\n".join(epic_content)
                    current_epic = line.strip()
                    epic_content = [line]
                current_section = None
            elif current_section == "objectives" and line.strip():
                sections["objectives"].append(line)
            elif current_epic and line.strip():
                epic_content.append(line)

        # Add final epic
        if current_epic and epic_content:
            sections["epics"][current_epic] = "\n".join(epic_content)

        return sections

    def generate_all_semantic_content(self) -> List[Dict]:
        """Generate semantic content for all generative gaps"""
        all_deltas = []

        generative_gaps = set(self.analysis.get("generative", []))

        print(f"Generating semantic content for {len(generative_gaps)} generative gaps...")

        # Process by type in priority order - process ALL gaps
        changes = sorted([nid for nid in generative_gaps if nid.startswith("change:")])
        requirements = sorted([nid for nid in generative_gaps if nid.startswith("req:")])
        scenarios = sorted([nid for nid in generative_gaps if nid.startswith("scenario:")])

        print(f"  Processing {len(changes)} ChangeSpecs (ALL gaps)...")
        for change_id in changes:
            deltas = self.generate_changespec_content(change_id)
            all_deltas.extend(deltas)
            if len(all_deltas) % 10 == 0:
                print(f"    Generated {len(all_deltas)} deltas so far...")

        print(f"  Processing {len(requirements)} Requirements (ALL gaps)...")
        for req_id in requirements:
            deltas = self.generate_requirement_content(req_id)
            all_deltas.extend(deltas)

        print(f"  Processing {len(scenarios)} Scenarios (ALL gaps)...")
        for scenario_id in scenarios:
            deltas = self.generate_scenario_content(scenario_id)
            all_deltas.extend(deltas)

        return all_deltas

    def generate_scenario_content(self, scenario_id: str) -> List[Dict]:
        """Generate semantic content for a scenario"""
        scenario = self.graph["nodes"].get(scenario_id)
        if not scenario:
            return []

        deltas = []
        stmt = scenario.get("stmt", "")

        # Find relevant epic from goal.md
        relevant_epic = self._find_relevant_epic(stmt, scenario_id)
        epic_context = self.goal_sections["epics"].get(relevant_epic, "")

        # Generate semantic Requirement
        s_base = self._sanitize_id(scenario_id.replace("scenario:", ""))
        req_id = f"req:{s_base}-semantic"

        if not self.graph["nodes"].get(req_id):
            req_stmt = self._generate_requirement_stmt(stmt, epic_context)
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

            # Update scenario
            scenario["requirements"] = scenario.get("requirements", []) + [req_id]
            deltas.append({"op": "update_node", "node": scenario})

            # Create edge
            deltas.append({"op": "add_edge", "from": scenario_id, "to": req_id, "type": "traces_to"})

        return deltas

    def generate_requirement_content(self, req_id: str) -> List[Dict]:
        """Generate semantic content for a requirement"""
        req = self.graph["nodes"].get(req_id)
        if not req:
            return []

        deltas = []
        stmt = req.get("stmt", "")

        # Find relevant epic
        relevant_epic = self._find_relevant_epic(stmt, req_id)
        epic_context = self.goal_sections["epics"].get(relevant_epic, "")

        # Generate Contracts
        req_base = self._sanitize_id(req_id.replace("req:", ""))

        # API Contract
        api_contract_id = f"contract:api-{req_base}-semantic"
        if not self.graph["nodes"].get(api_contract_id):
            api_contract = self._generate_api_contract(req_id, stmt, epic_context)
            if api_contract:
                deltas.append({"op": "add_node", "node": api_contract})
                req["contracts"] = req.get("contracts", []) + [api_contract_id]
                deltas.append({"op": "add_edge", "from": req_id, "to": api_contract_id, "type": "depends_on"})

        # Data Contract
        data_contract_id = f"contract:data-{req_base}-semantic"
        if not self.graph["nodes"].get(data_contract_id):
            data_contract = self._generate_data_contract(req_id, stmt, epic_context)
            if data_contract:
                deltas.append({"op": "add_node", "node": data_contract})
                req["contracts"] = req.get("contracts", []) + [data_contract_id]
                deltas.append({"op": "add_edge", "from": req_id, "to": data_contract_id, "type": "depends_on"})

        # Component
        component_id = f"component:{req_base}-semantic"
        if not self.graph["nodes"].get(component_id):
            component = self._generate_component(req_id, stmt, epic_context)
            if component:
                deltas.append({"op": "add_node", "node": component})
                req["components"] = req.get("components", []) + [component_id]
                deltas.append({"op": "add_edge", "from": req_id, "to": component_id, "type": "traces_to"})

        # ChangeSpec
        change_id = f"change:{req_base}-semantic"
        if not self.graph["nodes"].get(change_id):
            change = self._generate_changespec(req_id, stmt, epic_context)
            if change:
                deltas.append({"op": "add_node", "node": change})
                req["change_specs"] = req.get("change_specs", []) + [change_id]
                deltas.append({"op": "add_edge", "from": change_id, "to": req_id, "type": "implements"})

        if deltas:
            deltas.append({"op": "update_node", "node": req})

        return deltas

    def generate_changespec_content(self, change_id: str) -> List[Dict]:
        """Generate semantic InteractionSpecs for a ChangeSpec"""
        change = self.graph["nodes"].get(change_id)
        if not change:
            return []

        deltas = []
        stmt = change.get("stmt", "")

        # Find requirement this implements
        implements = change.get("implements", [])
        req = None
        req_stmt = ""
        if implements:
            req = self.graph["nodes"].get(implements[0])
            if req:
                req_stmt = req.get("stmt", "")

        # Find relevant epic
        relevant_epic = self._find_relevant_epic(stmt or req_stmt, change_id)
        epic_context = self.goal_sections["epics"].get(relevant_epic, "")

        # Combine context
        full_context = f"{epic_context}\n\nRequirement: {req_stmt}\nChangeSpec: {stmt}"

        # Generate semantic InteractionSpecs
        ix_specs = self._generate_interaction_specs(change_id, stmt, full_context, epic_context)

        for ix in ix_specs:
            deltas.append({"op": "add_node", "node": ix})
            change["ix"] = change.get("ix", []) + [ix["id"]]
            deltas.append({"op": "add_edge", "from": ix["id"], "to": change_id, "type": "depends_on"})

        if ix_specs:
            deltas.append({"op": "update_node", "node": change})

        return deltas

    def _find_relevant_epic(self, stmt: str, node_id: str) -> str:
        """Find relevant epic from goal.md based on statement/node"""
        stmt_lower = stmt.lower()
        node_lower = node_id.lower()

        # Keywords to epic mapping
        epic_keywords = {
            "Mobile Editor UX": ["mobile editor", "editor", "block", "bear", "compose"],
            "Slash Commands": ["slash", "command", "/command", "keyboard"],
            "Smart Linking": ["smart link", "link", "placeholder", "draft"],
            "Tags/Filters/Channels": ["tag", "filter", "channel", "organize"],
            "Gesture System": ["gesture", "swipe", "directional", "elastic"],
            "Condensed Feed": ["condensed", "feed", "gallery", "viewer"],
            "View Education": ["education", "coach", "spotlight", "demo", "help"],
            "Mode Architecture": ["mode", "read", "edit", "transition"],
            "Export Threads": ["export", "thread", "export thread"],
            "Custom Keyboard": ["keyboard", "custom keyboard", "expansion"],
            "AR & Geospatial": ["ar", "geospatial", "spatial", "location"]
        }

        # Check statement and node ID for keywords
        for epic_name, keywords in epic_keywords.items():
            if any(kw in stmt_lower or kw in node_lower for kw in keywords):
                return epic_name

        # Default to first epic if no match
        return list(self.goal_sections["epics"].keys())[0] if self.goal_sections["epics"] else ""

    def _generate_requirement_stmt(self, scenario_stmt: str, epic_context: str) -> str:
        """Generate semantic requirement statement"""
        # Extract key functionality from epic context
        if "Mobile Editor" in epic_context:
            return f"Functional requirement: Mobile editor with block-based editing, Bear-inspired UI, and gesture support - {scenario_stmt}"
        elif "Slash Commands" in epic_context:
            return f"Functional requirement: Slash commands for keyboard-first navigation and quick actions - {scenario_stmt}"
        elif "Smart Linking" in epic_context:
            return f"Functional requirement: Smart linking that creates missing content during authoring - {scenario_stmt}"
        elif "Tags/Filters" in epic_context or "Channels" in epic_context:
            return f"Functional requirement: Tags, filters, and user-defined channels for content organization - {scenario_stmt}"
        elif "Gesture" in epic_context:
            return f"Functional requirement: Gesture system with directional navigation and elastic swipes - {scenario_stmt}"
        elif "Condensed Feed" in epic_context:
            return f"Functional requirement: Condensed feed with gallery/post viewer and thread reading - {scenario_stmt}"
        elif "Export" in epic_context:
            return f"Functional requirement: Thread export functionality - {scenario_stmt}"
        elif "Keyboard" in epic_context:
            return f"Functional requirement: Custom keyboard expansion for mobile editor - {scenario_stmt}"
        elif "AR" in epic_context or "Geospatial" in epic_context:
            return f"Functional requirement: AR and geospatial features for future expansion - {scenario_stmt}"

        return f"Functional requirement: {scenario_stmt}"

    def _generate_api_contract(self, req_id: str, req_stmt: str, epic_context: str) -> Optional[Dict]:
        """Generate semantic API contract"""
        req_base = self._sanitize_id(req_id.replace("req:", ""))[:50]
        contract_id = f"contract:api-{req_base}-semantic"

        # Extract operations from epic context
        operations = self._extract_operations_from_epic(epic_context)
        operation_names = [op.get("name", "operation") for op in operations[:3]]

        return {
            "id": contract_id,
            "type": "Contract",
            "stmt": f"API contract: {req_stmt[:100]} - Operations: {', '.join(operation_names)}",
            "status": "Open",
            "contract_type": "api",
            "versioning": "semver:minor",
            "operations": operations,
            "checklist": ["authZ defined", "rate_limit defined", "idempotency defined", "timeouts defined", "error taxonomy defined", "observability defined"],
            "evidence": [],
            "unaccounted": [],
            "updated_at": datetime.now(timezone.utc).isoformat()
        }

    def _generate_data_contract(self, req_id: str, req_stmt: str, epic_context: str) -> Optional[Dict]:
        """Generate semantic data contract"""
        req_base = self._sanitize_id(req_id.replace("req:", ""))[:50]
        contract_id = f"contract:data-{req_base}-semantic"

        # Extract data model hints from epic context
        data_hints = self._extract_data_model_hints(epic_context)

        return {
            "id": contract_id,
            "type": "Contract",
            "stmt": f"Data contract: {req_stmt[:100]} - Schema for {', '.join(data_hints[:3]) if data_hints else 'entities'}",
            "status": "Open",
            "contract_type": "data",
            "lifecycle_fields": ["schema", "migration", "retention", "PII", "region", "index", "backup", "restore"],
            "data_hints": data_hints,
            "checklist": ["schema defined", "migration defined", "retention defined", "PII defined", "region defined", "index defined", "backup defined", "restore defined"],
            "evidence": [],
            "unaccounted": [],
            "updated_at": datetime.now(timezone.utc).isoformat()
        }

    def _generate_component(self, req_id: str, req_stmt: str, epic_context: str) -> Optional[Dict]:
        """Generate semantic component"""
        req_base = self._sanitize_id(req_id.replace("req:", ""))[:50]
        component_id = f"component:{req_base}-semantic"

        # Extract component name from epic context
        component_name = self._extract_component_name(epic_context)

        return {
            "id": component_id,
            "type": "Component",
            "stmt": f"{component_name}: {req_stmt[:80]}",
            "status": "Open",
            "checklist": [],
            "evidence": [],
            "unaccounted": [],
            "updated_at": datetime.now(timezone.utc).isoformat()
        }

    def _generate_changespec(self, req_id: str, req_stmt: str, epic_context: str) -> Optional[Dict]:
        """Generate semantic ChangeSpec"""
        req_base = self._sanitize_id(req_id.replace("req:", ""))[:50]
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

    def _generate_interaction_specs(self, change_id: str, change_stmt: str, full_context: str, epic_context: str) -> List[Dict]:
        """Generate semantic InteractionSpecs based on goal.md context"""
        specs = []

        change_base = self._sanitize_id(change_id.replace("change:", ""))[:50]

        # Extract actual operations from epic context
        operations = self._extract_operations_from_epic(epic_context)

        # Generate IX for each operation
        for i, operation in enumerate(operations[:4]):  # Max 4 operations
            ix_id = f"ix:{change_base}-{operation['name']}-{i}"

            # Generate semantic operation details
            operation_detail = self._generate_operation_detail(operation, epic_context, full_context)

            ix = {
                "id": ix_id,
                "type": "InteractionSpec",
                "stmt": operation_detail["stmt"],
                "method": operation_detail["method"],
                "interface": operation_detail["interface"],
                "operation": operation_detail["operation"],
                "state": operation_detail["state"],
                "pre": operation_detail["preconditions"],
                "in": operation_detail["inputs"],
                "eff": operation_detail["effects"],
                "err": operation_detail["errors"],
                "res": operation_detail["resources"],
                "obs": operation_detail["observability"],
                "sec": operation_detail["security"],
                "test": operation_detail["test"],
                "depends_on": [],
                "owner": "backend-team",
                "est_h": 1,
                "status": "Open",
                "unaccounted": [],
                "updated_at": datetime.now(timezone.utc).isoformat()
            }

            specs.append(ix)

        return specs

    def _extract_operations_from_epic(self, epic_context: str) -> List[Dict]:
        """Extract operations from epic context"""
        operations = []
        context_lower = epic_context.lower()

        # Operation patterns based on epic content
        if "mobile editor" in context_lower or "editor" in context_lower:
            operations.extend([
                {"name": "create_post", "method": "Editor.createPost()", "interface": "Mobile"},
                {"name": "edit_block", "method": "Editor.editBlock()", "interface": "Mobile"},
                {"name": "apply_format", "method": "Editor.applyFormat()", "interface": "Mobile"}
            ])

        if "slash" in context_lower or "command" in context_lower:
            operations.extend([
                {"name": "trigger_command", "method": "Commands.trigger()", "interface": "Keyboard"},
                {"name": "execute_command", "method": "Commands.execute()", "interface": "Keyboard"}
            ])

        if "link" in context_lower:
            operations.extend([
                {"name": "create_link", "method": "Links.create()", "interface": "API"},
                {"name": "resolve_link", "method": "Links.resolve()", "interface": "API"}
            ])

        if "tag" in context_lower or "filter" in context_lower or "channel" in context_lower:
            operations.extend([
                {"name": "apply_tag", "method": "Tags.apply()", "interface": "API"},
                {"name": "filter_content", "method": "Filters.apply()", "interface": "API"},
                {"name": "create_channel", "method": "Channels.create()", "interface": "API"}
            ])

        if "gesture" in context_lower or "swipe" in context_lower:
            operations.extend([
                {"name": "handle_gesture", "method": "Gestures.handle()", "interface": "Touch"},
                {"name": "navigate_direction", "method": "Gestures.navigate()", "interface": "Touch"}
            ])

        if "export" in context_lower:
            operations.extend([
                {"name": "export_thread", "method": "Export.thread()", "interface": "API"},
                {"name": "generate_export", "method": "Export.generate()", "interface": "API"}
            ])

        # Core Blueprint operations (from how-to-plan.md §2.1)
        if "analytics" in context_lower or "event" in context_lower:
            operations.extend([
                {"name": "emit_event", "method": "Analytics.emit()", "interface": "API"},
                {"name": "sample_event", "method": "Analytics.sample()", "interface": "API"},
                {"name": "validate_taxonomy", "method": "Analytics.validateTaxonomy()", "interface": "API"}
            ])

        if "caching" in context_lower or "cdn" in context_lower or "cache" in context_lower:
            operations.extend([
                {"name": "store_cache", "method": "Cache.store()", "interface": "API"},
                {"name": "invalidate_cache", "method": "Cache.invalidate()", "interface": "API"},
                {"name": "purge_cache", "method": "Cache.purge()", "interface": "API"}
            ])

        if "connectivity" in context_lower or "offline" in context_lower or "network" in context_lower:
            operations.extend([
                {"name": "detect_connection", "method": "Connectivity.detect()", "interface": "Network"},
                {"name": "queue_operation", "method": "Connectivity.queue()", "interface": "Network"},
                {"name": "replay_queue", "method": "Connectivity.replay()", "interface": "Network"}
            ])

        if "data-storage" in context_lower or "storage" in context_lower or "database" in context_lower:
            operations.extend([
                {"name": "store_data", "method": "Storage.store()", "interface": "Database"},
                {"name": "backup_data", "method": "Storage.backup()", "interface": "Database"},
                {"name": "restore_data", "method": "Storage.restore()", "interface": "Database"},
                {"name": "migrate_schema", "method": "Storage.migrate()", "interface": "Database"}
            ])

        if "identity" in context_lower or "access" in context_lower or "auth" in context_lower:
            operations.extend([
                {"name": "authenticate", "method": "Auth.authenticate()", "interface": "API"},
                {"name": "refresh_token", "method": "Auth.refreshToken()", "interface": "API"},
                {"name": "authorize", "method": "Auth.authorize()", "interface": "API"}
            ])

        if "observability" in context_lower or "log" in context_lower or "metric" in context_lower:
            operations.extend([
                {"name": "create_log", "method": "Obs.createLog()", "interface": "API"},
                {"name": "record_metric", "method": "Obs.recordMetric()", "interface": "API"},
                {"name": "start_trace", "method": "Obs.startTrace()", "interface": "API"}
            ])

        if "secret" in context_lower or "key" in context_lower:
            operations.extend([
                {"name": "retrieve_secret", "method": "Secrets.retrieve()", "interface": "KMS"},
                {"name": "rotate_secret", "method": "Secrets.rotate()", "interface": "KMS"}
            ])

        if "notification" in context_lower:
            operations.extend([
                {"name": "send_notification", "method": "Notifications.send()", "interface": "API"},
                {"name": "deliver_notification", "method": "Notifications.deliver()", "interface": "API"}
            ])

        # Default CRUD if no specific operations found
        if not operations:
            operations = [
                {"name": "create", "method": "Svc.create()", "interface": "API"},
                {"name": "read", "method": "Svc.read()", "interface": "API"},
                {"name": "update", "method": "Svc.update()", "interface": "API"}
            ]

        return operations

    def _generate_operation_detail(self, operation: Dict, epic_context: str, full_context: str) -> Dict:
        """Generate detailed operation specification"""
        op_name = operation["name"]

        # Generate semantic statement based on operation and context
        context_lower = epic_context.lower()
        full_lower = full_context.lower()

        # Check change_stmt for hints
        if "mobile editor" in full_lower or "editor" in full_lower:
            if "create" in op_name:
                stmt = "User creates new post via mobile editor with block-based UI, Bear-inspired design"
            elif "read" in op_name:
                stmt = "User views post in read mode with collapsed separators and tighter leading"
            elif "update" in op_name or "edit" in op_name:
                stmt = "User edits block content with drag handles, toolbar, and gesture support"
            elif "delete" in op_name:
                stmt = "User deletes block from mobile editor with undo support"
            else:
                stmt = f"Mobile editor operation: {op_name.replace('_', ' ').title()}"
        elif "slash" in full_lower or "command" in full_lower:
            if "trigger" in op_name or "create" in op_name:
                stmt = "User triggers slash command via keyboard, menu renders within 75ms"
            elif "execute" in op_name or "read" in op_name:
                stmt = "User executes slash command for block insertion (h1, task, img, callout, link)"
            elif "update" in op_name:
                stmt = "User updates slash command filter/search"
            else:
                stmt = f"Slash command operation: {op_name.replace('_', ' ').title()}"
        elif "link" in full_lower or "draft" in full_lower:
            if "create" in op_name:
                stmt = "User creates smart link [[title]] that creates DraftLink if missing"
            elif "read" in op_name or "resolve" in op_name:
                stmt = "System resolves smart link to existing post or creates DraftLink stub"
            elif "update" in op_name:
                stmt = "User updates DraftLink metadata or converts to full post"
            else:
                stmt = f"Smart linking operation: {op_name.replace('_', ' ').title()}"
        elif "tag" in full_lower or "filter" in full_lower or "channel" in full_lower:
            if "apply" in op_name or "create" in op_name:
                stmt = "User applies tag #x to content, auto-surfaces filter in sidebar"
            elif "filter" in op_name or "read" in op_name:
                stmt = "User filters content by tags/channels with saved query presets"
            elif "create" in op_name and "channel" in full_lower:
                stmt = "User creates channel from multiple tags and accounts with friendly name"
            elif "update" in op_name:
                stmt = "User updates channel configuration (tags, accounts, sort, timeframe)"
            else:
                stmt = f"Tag/filter/channel operation: {op_name.replace('_', ' ').title()}"
        elif "gesture" in full_lower or "swipe" in full_lower:
            if "handle" in op_name or "create" in op_name:
                stmt = "User performs gesture (swipe, directional navigation) with elastic response"
            elif "navigate" in op_name or "read" in op_name:
                stmt = "User navigates directionally (Up/Down block-to-block, Left/Right within block)"
            elif "update" in op_name:
                stmt = "User reorders blocks via long-press Up/Down with haptic feedback"
            else:
                stmt = f"Gesture operation: {op_name.replace('_', ' ').title()}"
        elif "export" in full_lower or "thread" in full_lower:
            if "export" in op_name or "create" in op_name:
                stmt = "User exports thread for external use with ThreadExport generation"
            elif "generate" in op_name or "read" in op_name:
                stmt = "System generates export format (markdown, PDF, etc.) from thread"
            else:
                stmt = f"Export operation: {op_name.replace('_', ' ').title()}"
        elif "bookmark" in full_lower:
            if "create" in op_name:
                stmt = "User bookmarks post for later viewing, organizing into lists"
            elif "read" in op_name:
                stmt = "User views bookmarked posts with tags and notes"
            elif "update" in op_name:
                stmt = "User edits bookmark (adds tag, note, moves to list)"
            elif "delete" in op_name:
                stmt = "User removes bookmark from list"
            else:
                stmt = f"Bookmark operation: {op_name.replace('_', ' ').title()}"
        elif "analytics" in full_lower or "event" in full_lower:
            if "emit" in op_name or "create" in op_name:
                stmt = "System emits analytics event with taxonomy validation and privacy controls"
            elif "sample" in op_name or "read" in op_name:
                stmt = "System samples analytics event based on privacy controls and sampling rate"
            elif "validate" in op_name:
                stmt = "System validates analytics event taxonomy and structure"
            else:
                stmt = f"Analytics operation: {op_name.replace('_', ' ').title()}"
        elif "caching" in full_lower or "cdn" in full_lower or "cache" in full_lower:
            if "store" in op_name or "create" in op_name:
                stmt = "System stores object in cache/CDN with TTL and invalidation rules"
            elif "invalidate" in op_name or "update" in op_name:
                stmt = "System invalidates cache entry by pattern or key"
            elif "purge" in op_name or "delete" in op_name:
                stmt = "System purges cache entries matching pattern"
            elif "read" in op_name:
                stmt = "System retrieves cached object with hit/miss metrics"
            else:
                stmt = f"Cache operation: {op_name.replace('_', ' ').title()}"
        elif "connectivity" in full_lower or "offline" in full_lower or "network" in full_lower:
            if "detect" in op_name or "read" in op_name:
                stmt = "System detects network state (online/offline/slow/captive-portal)"
            elif "queue" in op_name or "create" in op_name:
                stmt = "System queues operation for replay when network available"
            elif "replay" in op_name or "update" in op_name:
                stmt = "System replays queued operations when network restored"
            else:
                stmt = f"Connectivity operation: {op_name.replace('_', ' ').title()}"
        elif "data-storage" in full_lower or "storage" in full_lower or "database" in full_lower:
            if "store" in op_name or "create" in op_name:
                stmt = "System stores data with proper schema, indices, and retention policy"
            elif "backup" in op_name:
                stmt = "System creates backup with retention and disaster recovery configuration"
            elif "restore" in op_name or "read" in op_name:
                stmt = "System restores data from backup with validation and rollback capability"
            elif "migrate" in op_name or "update" in op_name:
                stmt = "System applies database migration with schema versioning and rollback"
            else:
                stmt = f"Storage operation: {op_name.replace('_', ' ').title()}"
        elif "identity" in full_lower or "access" in full_lower or "auth" in full_lower:
            if "authenticate" in op_name or "login" in op_name or "create" in op_name:
                stmt = "User authenticates via credentials or SSO with session creation"
            elif "refresh" in op_name or "update" in op_name:
                stmt = "User refreshes session token during poor network with retry logic"
            elif "authorize" in op_name or "read" in op_name:
                stmt = "System authorizes user access based on roles and permissions"
            else:
                stmt = f"Auth operation: {op_name.replace('_', ' ').title()}"
        elif "observability" in full_lower or "log" in full_lower or "metric" in full_lower:
            if "create" in op_name or "log" in op_name:
                stmt = "System creates structured log entry with context and severity"
            elif "metric" in op_name or "read" in op_name:
                stmt = "System records metric with tags and aggregation rules"
            elif "trace" in op_name or "update" in op_name:
                stmt = "System starts trace span with parent context and sampling"
            else:
                stmt = f"Observability operation: {op_name.replace('_', ' ').title()}"
        elif "secret" in full_lower or "key" in full_lower:
            if "retrieve" in op_name or "read" in op_name:
                stmt = "System retrieves secret from KMS with rotation and access logging"
            elif "rotate" in op_name or "update" in op_name:
                stmt = "System rotates secret/key with version management and zero downtime"
            else:
                stmt = f"Secret operation: {op_name.replace('_', ' ').title()}"
        elif "notification" in full_lower:
            if "send" in op_name or "create" in op_name:
                stmt = "System sends notification (push/email) with delivery preferences"
            elif "deliver" in op_name or "update" in op_name:
                stmt = "System delivers notification with tracking and deliverability metrics"
            else:
                stmt = f"Notification operation: {op_name.replace('_', ' ').title()}"
        else:
            # Fallback to context-aware generic
            if "create" in op_name:
                stmt = f"User creates resource: {full_context[:50]}..."
            elif "read" in op_name:
                stmt = f"User reads resource: {full_context[:50]}..."
            elif "update" in op_name:
                stmt = f"User updates resource: {full_context[:50]}..."
            elif "delete" in op_name:
                stmt = f"User deletes resource: {full_context[:50]}..."
            else:
                stmt = f"{op_name.replace('_', ' ').title()} operation: {full_context[:50]}..."

        return {
            "stmt": stmt,
            "method": operation.get("method", f"Svc.{op_name}()"),
            "interface": operation.get("interface", "API"),
            "operation": f"{op_name.upper()} /resource" if "API" in operation.get("interface", "") else op_name,
            "state": {"token": "fresh", "quota": "under", "network": "ok", "device": "mobile"},
            "preconditions": ["User authenticated", "Input validated"],
            "inputs": {"params": "resource_data", "headers": ["Authorization"]},
            "effects": [f"Resource {op_name}ed", "State updated"],
            "errors": {
                "retriable": ["5xx", "429", "Network timeout"],
                "non_retriable": ["400", "401", "403"],
                "compensation": ["Rollback transaction"] if "create" in op_name or "update" in op_name else []
            },
            "resources": {
                "timeout_ms": 8000,
                "retry": {"strategy": "exp", "max": 4, "jitter": True},
                "idem_key": f"{op_name}-{datetime.now().timestamp()}"
            },
            "observability": {
                "logs": ["Operation start", "Operation complete"],
                "metrics": [f"operation_{op_name}_count", f"operation_{op_name}_duration"],
                "span": f"{operation.get('interface', 'api').lower()}.{op_name}"
            },
            "security": {
                "authZ": "User owns resource or has permission",
                "least_priv": "Read/write own resources only",
                "pii": "tag" in op_name or "channel" in op_name or "link" in op_name
            },
            "test": {
                "mocks": ["Database", "Auth service"],
                "acc": [f"Given resource exists\nWhen user {op_name}s\nThen operation succeeds"]
            }
        }

    def _extract_data_model_hints(self, epic_context: str) -> List[str]:
        """Extract data model hints from epic context"""
        hints = []
        context_lower = epic_context.lower()

        if "post" in context_lower:
            hints.append("Post")
        if "block" in context_lower:
            hints.append("Block")
        if "tag" in context_lower:
            hints.append("Tag")
        if "channel" in context_lower:
            hints.append("Channel")
        if "link" in context_lower or "draft" in context_lower:
            hints.append("DraftLink")
        if "export" in context_lower or "thread" in context_lower:
            hints.append("ThreadExport")

        return hints if hints else ["Entity"]

    def _extract_component_name(self, epic_context: str) -> str:
        """Extract component name from epic context"""
        if "Mobile Editor" in epic_context:
            return "MobileEditorComponent"
        elif "Slash Commands" in epic_context:
            return "SlashCommandsComponent"
        elif "Smart Linking" in epic_context:
            return "SmartLinkingComponent"
        elif "Tags" in epic_context or "Filters" in epic_context:
            return "TagsFiltersComponent"
        elif "Gesture" in epic_context:
            return "GestureSystemComponent"
        elif "Feed" in epic_context:
            return "FeedComponent"
        elif "Export" in epic_context:
            return "ExportComponent"
        elif "Keyboard" in epic_context:
            return "KeyboardComponent"

        return "FeatureComponent"

    def _sanitize_id(self, node_id: str) -> str:
        """Sanitize node ID for use in file paths"""
        # Replace problematic characters
        sanitized = node_id.replace(":", "-").replace("/", "-").replace("\\", "-")
        sanitized = re.sub(r'[<>"|?*]', '-', sanitized)
        # Limit length
        if len(sanitized) > 100:
            sanitized = sanitized[:100]
        return sanitized


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

    generator = SemanticContentGenerator(plan_dir, goal_file, analysis_file)
    deltas = generator.generate_all_semantic_content()

    print(f"\nGenerated {len(deltas)} deltas for semantic content")

    # Save deltas
    deltas_file = Path("semantic_content_deltas.json")
    deltas_file.write_text(json.dumps(deltas, indent=2), encoding='utf-8')
    print(f"Deltas saved to: {deltas_file}")

    # Apply deltas to plan
    print("\nApplying deltas to plan...")
    from verify_and_repair_planning import PlanGraph  # Import graph class

    graph = PlanGraph(plan_dir)
    applied = 0
    for delta in deltas:
        try:
            if delta["op"] == "add_node":
                graph.save_node(delta["node"]["id"], delta["node"])
                applied += 1
            elif delta["op"] == "update_node":
                graph.save_node(delta["node"]["id"], delta["node"])
                applied += 1
            elif delta["op"] == "add_edge":
                # Add to edges.ndjson
                edges_file = plan_dir / "edges.ndjson"
                with open(edges_file, 'a') as f:
                    f.write(json.dumps({
                        "from": delta["from"],
                        "to": delta["to"],
                        "type": delta["type"]
                    }) + "\n")
                applied += 1
        except Exception as e:
            print(f"  Error applying delta {delta.get('op', 'unknown')}: {e}")

    print(f"\nApplied {applied} deltas successfully")
    print(f"Remaining: {len(deltas) - applied} deltas")


if __name__ == "__main__":
    main()

