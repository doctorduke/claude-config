#!/usr/bin/env python3
"""
Generate Core Blueprint nodes according to how-to-plan.md §2.1
Creates Scenarios, Requirements, Contracts, Components, and ChangeSpecs for
mandatory baseline subsystems.
"""

import json
import os
from pathlib import Path
from datetime import datetime, timezone
from typing import Dict, List

# Core Blueprint subsystems from how-to-plan.md §2.1
CORE_BLUEPRINT_SUBSYSTEMS = {
    "Identity & Access": {
        "description": "AuthN (login, signup, reset), AuthZ (roles/scopes), session & token lifecycle (refresh, revocation, device binding), multi-account & tenant switching, SSO (optional).",
        "scenarios": [
            "User logs in with credentials",
            "User logs out",
            "User refreshes session token",
            "User resets password",
            "User changes device",
            "User switches between multiple accounts",
            "User authenticates via SSO (optional)"
        ],
        "core_components": ["Auth Service", "Session Manager", "Token Service", "Multi-Account Manager", "SSO Provider"]
    },
    "Users & Profiles": {
        "description": "User model, profile edits, avatars, handles, blocking/reporting (if social).",
        "scenarios": [
            "User views profile",
            "User edits profile",
            "User uploads avatar",
            "User sets handle",
            "User blocks another user",
            "User reports content/user"
        ],
        "core_components": ["User Service", "Profile Service", "Media Service", "Block/Report Service"]
    },
    "Preferences & Settings": {
        "description": "Data model, defaults, overrides, per-device sync, UI projection.",
        "scenarios": [
            "User reads default preferences",
            "User updates preference",
            "Preference syncs across devices",
            "Preference projects to UI"
        ],
        "core_components": ["Preferences Service", "Sync Service", "Settings UI"]
    },
    "Navigation & Destinations": {
        "description": "App shell, routing, screen catalog (e.g., Feed, Compose, Notifications, Search, Profile, Settings, DM/Inbox, Onboarding/Auth).",
        "scenarios": [
            "User opens app (cold start)",
            "User navigates to Feed",
            "User navigates to Compose",
            "User navigates to Profile",
            "User navigates via deep link",
            "User navigates from warm start"
        ],
        "core_components": ["App Shell", "Router", "Screen Catalog", "Deep Link Handler"]
    },
    "Connectivity": {
        "description": "Online/slow/offline/captive-portal; retry/backoff/idempotency; offline queue & replay; background constraints.",
        "scenarios": [
            "App goes offline",
            "App goes online",
            "App detects slow connection",
            "App detects captive portal",
            "App replays queued operations",
            "Token refresh during poor network"
        ],
        "core_components": ["Connectivity Monitor", "Offline Queue", "Retry Handler", "Idempotency Service"]
    },
    "Data Storage": {
        "description": "Primary DB schemas, indices, migrations/backfills, retention/PII/region; backups/restore/DR.",
        "scenarios": [
            "Data is stored with proper schema",
            "Migrations are applied",
            "Backfills are executed",
            "Data retention policy is enforced",
            "Backups are created",
            "Data is restored from backup"
        ],
        "core_components": ["Database", "Migration Service", "Backup Service", "Retention Service"]
    },
    "Caching/CDN": {
        "description": "Object & page cache, invalidation/purge, TTLs; cache hit/miss behavior.",
        "scenarios": [
            "Cache stores object",
            "Cache invalidates object",
            "Cache purges by pattern",
            "Cache respects TTL"
        ],
        "core_components": ["Cache Service", "CDN", "Invalidation Service"]
    },
    "Queues/Workers": {
        "description": "Background jobs, backpressure, DLQ, retries.",
        "scenarios": [
            "Job is queued",
            "Worker processes job",
            "Job fails and retries",
            "Job exceeds retries and goes to DLQ",
            "Backpressure is detected"
        ],
        "core_components": ["Queue Service", "Worker Service", "DLQ Handler", "Backpressure Monitor"]
    },
    "Secrets/Keys": {
        "description": "Storage, rotation, KMS integration.",
        "scenarios": [
            "Secret is stored securely",
            "Secret is rotated",
            "Secret is retrieved",
            "KMS integration is used"
        ],
        "core_components": ["Secrets Manager", "Key Rotation Service", "KMS Integration"]
    },
    "Observability": {
        "description": "Structured logs, metrics, traces; dashboards+alerts; SLIs/SLOs.",
        "scenarios": [
            "Log entry is created",
            "Metric is emitted",
            "Trace is started",
            "Alert is triggered",
            "SLO is evaluated"
        ],
        "core_components": ["Logging Service", "Metrics Service", "Tracing Service", "Alert Manager", "SLO Monitor"]
    },
    "Analytics/Events": {
        "description": "Event taxonomy, privacy controls, sampling.",
        "scenarios": [
            "Event is emitted",
            "Event respects privacy controls",
            "Event is sampled",
            "Event taxonomy is validated"
        ],
        "core_components": ["Event Service", "Privacy Manager", "Sampling Service"]
    },
    "Feature Flags/Config": {
        "description": "Flags, canaries, kill switch.",
        "scenarios": [
            "Feature flag is evaluated",
            "Canary deployment is executed",
            "Kill switch is activated",
            "Config is updated"
        ],
        "core_components": ["Feature Flag Service", "Config Service", "Canary Manager", "Kill Switch Service"]
    },
    "Security & Policy": {
        "description": "Rate limits/quotas, CSRF/CORS, content policy/moderation (if applicable).",
        "scenarios": [
            "Rate limit is enforced",
            "Quota is checked",
            "CSRF token is validated",
            "CORS policy is enforced",
            "Content is moderated"
        ],
        "core_components": ["Rate Limiter", "Quota Service", "CSRF Handler", "CORS Handler", "Content Moderation Service"]
    },
    "Internationalization & A11y": {
        "description": "i18n/l10n; accessibility states and labels.",
        "scenarios": [
            "UI is localized",
            "Accessibility labels are read",
            "Screen reader navigates UI",
            "Text scales with user preferences"
        ],
        "core_components": ["i18n Service", "Accessibility Service", "Localization Service"]
    },
    "Notifications": {
        "description": "Push/email; preferences; deliverability.",
        "scenarios": [
            "Push notification is sent",
            "Email notification is sent",
            "Notification preference is updated",
            "Notification delivery is tracked"
        ],
        "core_components": ["Push Service", "Email Service", "Notification Preferences Service"]
    },
    "Payments/Monetization": {
        "description": "Contracts & compliance if applicable.",
        "scenarios": [
            "Payment is processed",
            "Subscription is created",
            "Refund is issued",
            "Compliance is verified"
        ],
        "core_components": ["Payment Processor", "Subscription Service", "Compliance Service"]
    }
}

def generate_node_id(node_type: str, subsystem_name: str, item_name: str = None) -> str:
    """Generate a node ID following the pattern type:slug"""
    slug_base = subsystem_name.lower().replace(" ", "-").replace("/", "-").replace("&", "-")
    if item_name:
        item_slug = item_name.lower().replace(" ", "-").replace("'", "").replace(".", "")
        return f"{node_type}:{slug_base}-{item_slug}"
    return f"{node_type}:{slug_base}"

def create_scenario_node(subsystem: str, scenario_stmt: str, subsystem_data: Dict) -> Dict:
    """Create a Scenario node"""
    scenario_id = generate_node_id("scenario", subsystem, scenario_stmt[:30])

    return {
        "id": scenario_id,
        "type": "Scenario",
        "stmt": f"{scenario_stmt} ({subsystem})",
        "status": "Open",
        "requirements": [],  # Will be populated
        "tests": [],
        "acceptance": [],
        "checklist": [],
        "evidence": [],
        "unaccounted": [],
        "updated_at": datetime.now(timezone.utc).isoformat()
    }

def create_requirement_node(subsystem: str, req_type: str, req_stmt: str) -> Dict:
    """Create a Requirement node"""
    req_id = generate_node_id("req", subsystem, f"{req_type}-{req_stmt[:20]}")

    return {
        "id": req_id,
        "type": "Requirement",
        "stmt": f"{req_type} requirement for {subsystem}: {req_stmt}",
        "status": "Open",
        "change_specs": [],
        "contracts": [],
        "components": [],
        "checklist": [],
        "evidence": [],
        "unaccounted": [],
        "updated_at": datetime.now(timezone.utc).isoformat()
    }

def create_component_node(subsystem: str, component_name: str) -> Dict:
    """Create a Component node"""
    component_id = generate_node_id("component", subsystem, component_name.lower().replace(" ", "-"))

    return {
        "id": component_id,
        "type": "Component",
        "stmt": f"{component_name} for {subsystem}",
        "status": "Open",
        "checklist": [],
        "evidence": [],
        "unaccounted": [],
        "updated_at": datetime.now(timezone.utc).isoformat()
    }

def create_contract_node(subsystem: str, contract_type: str) -> Dict:
    """Create a Contract node"""
    contract_id = generate_node_id(f"contract:{contract_type}", subsystem, "")
    contract_id = contract_id.replace("contract:contract:", "contract:")

    # Core blueprint contracts need: versioning, error taxonomy, timeouts, idempotency
    stmt = f"{contract_type.upper()} contract for {subsystem}. MUST include: versioning, error taxonomy, timeouts, idempotency."

    return {
        "id": contract_id,
        "type": "Contract",
        "stmt": stmt,
        "status": "Open",
        "contract_type": contract_type,
        "versioning": "semver:minor",  # Default per knobs
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

def generate_core_blueprint_nodes(plan_dir: Path):
    """Generate all Core Blueprint nodes"""
    nodes = {}
    edges = []

    for subsystem_name, subsystem_data in CORE_BLUEPRINT_SUBSYSTEMS.items():
        print(f"\nGenerating nodes for: {subsystem_name}")

        # Create Scenario nodes
        scenarios = []
        for scenario_stmt in subsystem_data["scenarios"]:
            scenario = create_scenario_node(subsystem_name, scenario_stmt, subsystem_data)
            scenario_id = scenario["id"]
            nodes[scenario_id] = scenario
            scenarios.append(scenario_id)

        # Create Requirement nodes (functional and non-functional per scenario)
        for scenario_id in scenarios:
            scenario_node = nodes[scenario_id]

            # Functional requirement
            func_req = create_requirement_node(
                subsystem_name,
                "functional",
                scenario_node["stmt"]
            )
            func_req_id = func_req["id"]
            nodes[func_req_id] = func_req
            scenario_node["requirements"].append(func_req_id)
            edges.append({
                "from": scenario_node["id"],
                "to": func_req_id,
                "type": "traces_to"
            })

            # Non-functional requirement
            nonfunc_req = create_requirement_node(
                subsystem_name,
                "non-functional",
                scenario_node["stmt"]
            )
            nonfunc_req_id = nonfunc_req["id"]
            nodes[nonfunc_req_id] = nonfunc_req
            scenario_node["requirements"].append(nonfunc_req_id)
            edges.append({
                "from": scenario_node["id"],
                "to": nonfunc_req_id,
                "type": "traces_to"
            })

        # Create Component nodes
        for component_name in subsystem_data["core_components"]:
            component = create_component_node(subsystem_name, component_name)
            component_id = component["id"]
            nodes[component_id] = component

        # Create Contract nodes (API, Data, Event, Policy as needed)
        contract_types = ["api", "data"]
        if "Notifications" in subsystem_name or "Analytics" in subsystem_name:
            contract_types.append("event")
        if "Security" in subsystem_name or "Policy" in subsystem_name:
            contract_types.append("policy")

        for contract_type in contract_types:
            contract = create_contract_node(subsystem_name, contract_type)
            contract_id = contract["id"]
            nodes[contract_id] = contract

    return nodes, edges

def save_nodes(nodes: Dict, edges: List, plan_dir: Path):
    """Save nodes to filesystem following plan-fixed structure"""
    nodes_dir = plan_dir / "nodes"

    # Create type directories if needed
    for node in nodes.values():
        node_type = node["type"]
        type_dir = nodes_dir / node_type
        type_dir.mkdir(parents=True, exist_ok=True)

    # Save each node
    for node_id, node in nodes.items():
        node_type = node["type"]
        # Replace colons with dashes and clean up filename
        safe_filename = node_id.replace(':', '-').replace('/', '-').replace('&', '-')
        node_file = nodes_dir / node_type / f"{safe_filename}.json"

        with open(node_file, 'w') as f:
            json.dump(node, f, indent=2)

    # Append edges to edges.ndjson
    edges_file = plan_dir / "edges.ndjson"
    with open(edges_file, 'a') as f:
        for edge in edges:
            f.write(json.dumps(edge) + "\n")

    print(f"\nSaved {len(nodes)} nodes and {len(edges)} edges")

def main():
    """Main entry point"""
    plan_dir = Path("plan-fixed")

    if not plan_dir.exists():
        print(f"Error: {plan_dir} does not exist")
        return 1

    print("=" * 80)
    print("GENERATING CORE BLUEPRINT NODES")
    print("Following how-to-plan.md §2.1 methodology")
    print("=" * 80)

    nodes, edges = generate_core_blueprint_nodes(plan_dir)

    print(f"\nGenerated {len(nodes)} nodes and {len(edges)} edges")

    save_nodes(nodes, edges, plan_dir)

    print("\nCore Blueprint generation complete!")
    print("Next steps:")
    print("  1. Review generated nodes")
    print("  2. Run execute_planning.py again to verify P10 passes")
    print("  3. Expand Requirements -> ChangeSpecs -> InteractionSpecs")

    return 0

if __name__ == "__main__":
    exit(main())

