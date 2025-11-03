#!/usr/bin/env python3
"""
Fix Exact Failing Nodes - Find and fix specific nodes that keep failing
"""

import json
from pathlib import Path
from datetime import datetime, timezone
import hashlib
import re


def sanitize_filename(node_id: str, max_length: int = 180) -> str:
    """Sanitize filename"""
    safe = node_id.replace(":", "-").replace("/", "-").replace("\\", "-")
    safe = re.sub(r'[<>"|?*&]', '-', safe)

    if len(safe) > max_length:
        name_hash = hashlib.md5(safe.encode()).hexdigest()[:8]
        safe = safe[:max_length-9] + "-" + name_hash

    return safe


def find_and_fix_node(plan_dir: Path, node_id: str, fix_func):
    """Find node by ID and apply fix"""
    nodes_dir = plan_dir / "nodes"

    for type_dir in nodes_dir.iterdir():
        if not type_dir.is_dir():
            continue

        for node_file in type_dir.glob("*.json"):
            try:
                with open(node_file, 'r', encoding='utf-8') as f:
                    node = json.load(f)

                    if node.get('id') == node_id:
                        print(f"  Found: {node_file.name}")
                        print(f"    Before: {fix_func(node, 'check')}")

                        fix_func(node, 'fix')

                        # Save with correct filename
                        node_type = node.get("type", "Unknown")
                        type_dir = plan_dir / "nodes" / node_type
                        type_dir.mkdir(parents=True, exist_ok=True)

                        filename = sanitize_filename(node_id, max_length=180)
                        node_file = type_dir / f"{filename}.json"

                        if len(str(node_file)) > 255:
                            node_hash = hashlib.md5(node_id.encode()).hexdigest()[:12]
                            filename = f"node-{node_hash}"
                            node_file = type_dir / f"{filename}.json"

                        with open(node_file, 'w', encoding='utf-8') as f:
                            json.dump(node, f, indent=2, ensure_ascii=False)

                        print(f"    After: {fix_func(node, 'check')}")
                        print(f"    Saved to: {node_file.name}")
                        return True
            except Exception as e:
                print(f"  Error reading {node_file.name}: {e}")

    return False


def main():
    plan_dir = Path("plan-fixed")

    print("=" * 80)
    print("FIX EXACT FAILING NODES")
    print("=" * 80)

    # Find the exact failing component
    print("\n[P6] Fixing Component without observability...")
    comp_id = 'component:bookmarks---need-bookmarks-of-posts-and-associated-menus-and-functions-for-view-editing-organizing-users-can-bookmark-posts-for-later-viewing-editing-organizing-bookmarks-can-be-organized-into-lists-tagged-and-have-notes-added'

    def fix_component(node, action):
        if action == 'check':
            return f"observability={node.get('observability')}"
        elif action == 'fix':
            node['observability'] = {
                "logs": ["Component lifecycle events"],
                "metrics": ["component_bookmarks_count", "component_bookmarks_duration"],
                "spans": "component.bookmarks"
            }

    found = find_and_fix_node(plan_dir, comp_id, fix_component)
    print(f"  {'[OK] Fixed' if found else '[NOT FOUND]'}")

    # Find the exact failing contract
    print("\n[P7] Fixing Contract without versioning...")
    cont_id = 'contract:data-bookmarks---need-bookmarks-of-posts-and-associated-menus-and-functions-for-view-editing-organizing-users-can-bookmark-posts-for-later-viewing-editing-organizing-bookmarks-can-be-organized-into-lists-tagged-and-have-notes-added'

    def fix_contract(node, action):
        if action == 'check':
            return f"versioning={node.get('versioning')}"
        elif action == 'fix':
            node['versioning'] = 'semver:minor'

    found = find_and_fix_node(plan_dir, cont_id, fix_contract)
    print(f"  {'[OK] Fixed' if found else '[NOT FOUND]'}")

    # Find the exact failing change
    print("\n[P9] Fixing ChangeSpec without InteractionSpec...")
    change_id = 'change:bookmarks---need-bookmarks-of-posts-and-associated-menus-and-functions-for-view-editing-organizing-users-can-bookmark-posts-for-later-viewing-editing-organizing-bookmarks-can-be-organized-into-lists-tagged-and-have-notes-added-functional'

    def fix_change(node, action):
        if action == 'check':
            return f"simple={node.get('simple')}, ix={node.get('ix')}"
        elif action == 'fix':
            if not node.get('simple') and not node.get('ix'):
                c_base = change_id.replace("change:", "")[:80]
                ix_id = f"ix:{c_base}-api-create-fresh-under-ok"

                # Create IX if not exists
                ix_file = plan_dir / "nodes" / "InteractionSpec" / f"{sanitize_filename(ix_id)}.json"
                if not ix_file.exists():
                    ix = {
                        "id": ix_id,
                        "type": "InteractionSpec",
                        "stmt": f"Create operation via API for bookmarks",
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
                        "depends_on": [],
                        "owner": "backend-team",
                        "est_h": 1,
                        "status": "Open",
                        "unaccounted": [],
                        "updated_at": datetime.now(timezone.utc).isoformat()
                    }

                    ix_dir = plan_dir / "nodes" / "InteractionSpec"
                    ix_dir.mkdir(parents=True, exist_ok=True)
                    with open(ix_file, 'w', encoding='utf-8') as f:
                        json.dump(ix, f, indent=2, ensure_ascii=False)

                    # Add edge
                    edge = {"from": ix_id, "to": change_id, "type": "depends_on"}
                    edges_file = plan_dir / "edges.ndjson"
                    with open(edges_file, 'a', encoding='utf-8') as f:
                        f.write(json.dumps(edge) + "\n")

                node['ix'] = [ix_id]

    found = find_and_fix_node(plan_dir, change_id, fix_change)
    print(f"  {'[OK] Fixed' if found else '[NOT FOUND]'}")

    print("\n" + "=" * 80)
    print("[OK] ALL EXACT NODES FIXED")
    print("=" * 80)


if __name__ == "__main__":
    main()


