#!/usr/bin/env python3
"""
Classify all 169 screen files into proper categories.
Based on v44 learnings about backend operations wrongly classified as screens.
"""

import json
import os
from pathlib import Path
from typing import Dict, List, Any
from collections import defaultdict

# Classification rules
CLASSIFICATION_RULES = {
    'POLICY': [
        'analytics', 'events', 'sampled', 'validation', 'privacy-control',
        'taxonomy', 'quota', 'rate-limit', 'csrf', 'cors', 'moderated',
        'policy', 'slo-is-evaluated', 'alert-is-triggered'
    ],
    'SERVICE': [
        'caching', 'cdn', 'queue', 'worker', 'backpressure', 'job-is-queued',
        'job-fails', 'job-exceeds', 'worker-processes', 'backfills-are-executed',
        'backups-are-created', 'migrations-are-applied', 'data-retention',
        'secret-is-rotated', 'kms-integration'
    ],
    'API_ENDPOINT': [
        'http', 'endpoint', 'api', 'token-refresh', 'auth-refresh',
        'notification-is-sent', 'email-notification', 'push-notification',
        'payment-is-processed', 'refund-is-issued', 'subscription-is-created',
        'metric-is-emitted', 'log-entry-is-created', 'trace-is-started'
    ],
    'COMPONENT': [
        'modal', 'overlay', 'dialog', 'drawer', 'toast', 'popup'
    ]
}

# Known screen patterns (user-facing with routes)
SCREEN_PATTERNS = [
    'feed', 'profile', 'compose', 'bookmarks', 'thread', 'community-notes',
    'navigation', 'preferences', 'settings', 'property-editor', 'mobile-editor'
]

def read_json_file(file_path: Path) -> Dict[str, Any]:
    """Read and parse a JSON file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
        return {}

def extract_screen_id(data: Dict[str, Any]) -> str:
    """Extract screen ID from JSON data."""
    return data.get('id', '')

def classify_screen(filename: str, data: Dict[str, Any]) -> str:
    """
    Classify a screen file into one of the categories.

    Categories:
    - SCREEN: Actual user-visible screens with routes
    - SERVICE: Backend workers, queues, CDN operations
    - API_ENDPOINT: HTTP endpoints, caching operations
    - POLICY: Internal logic, sampling, validation rules
    - COMPONENT: Modals, overlays without routes
    - DUPLICATE: Multiple versions of same screen
    """
    screen_id = extract_screen_id(data)
    name = data.get('name', '')
    description = data.get('description', '')

    # Combine all text for analysis
    text = f"{filename} {screen_id} {name} {description}".lower()

    # Check for duplicates (files with hash suffixes or duplicate base names)
    if any(char in filename for char in ['650abc90', 'b2ebf0f38e88']):
        return 'DUPLICATE'

    # Check for POLICY indicators
    if any(keyword in text for keyword in CLASSIFICATION_RULES['POLICY']):
        return 'POLICY'

    # Check for SERVICE indicators
    if any(keyword in text for keyword in CLASSIFICATION_RULES['SERVICE']):
        return 'SERVICE'

    # Check for API_ENDPOINT indicators
    if any(keyword in text for keyword in CLASSIFICATION_RULES['API_ENDPOINT']):
        return 'API_ENDPOINT'

    # Check for COMPONENT indicators
    if any(keyword in text for keyword in CLASSIFICATION_RULES['COMPONENT']):
        return 'COMPONENT'

    # User action patterns (these are operations, not screens)
    # Check BEFORE screen patterns to avoid false positives
    user_action_patterns = [
        'user-navigates', 'user-opens', 'user-logs-in', 'user-logs-out',
        'user-refreshes', 'user-resets', 'user-switches', 'user-changes',
        'user-authenticates', 'user-blocks', 'user-edits', 'user-reports',
        'user-sets', 'user-uploads', 'user-reads', 'user-updates', 'user-views'
    ]

    if any(pattern in text for pattern in user_action_patterns):
        # These are operations, not screens
        if any(word in text for word in ['identity', 'access', 'auth', 'login', 'logout', 'password']):
            return 'API_ENDPOINT'
        if any(word in text for word in ['profiles', 'settings', 'preferences', 'navigation']):
            return 'POLICY'
        return 'API_ENDPOINT'

    # Check for known SCREEN patterns
    if any(pattern in text for pattern in SCREEN_PATTERNS):
        # Additional validation - screens should have user-facing descriptions
        # Backend operations often have technical descriptions
        if any(word in text for word in ['view', 'display', 'show', 'edit']):
            return 'SCREEN'

    # Special cases
    if 'contract-' in filename:
        return 'POLICY'  # Contract definitions

    if 'identity---access' in text:
        return 'API_ENDPOINT'  # Auth operations

    if 'preferences---settings' in text:
        return 'POLICY'  # Settings logic

    if 'users---profiles' in text:
        return 'API_ENDPOINT'  # Profile operations

    if 'observability' in text:
        return 'SERVICE'  # Observability operations

    if 'connectivity-app' in text:
        return 'POLICY'  # Connectivity detection logic

    if 'data-storage' in text:
        return 'SERVICE'  # Storage operations

    if 'feature-flags-config' in text:
        return 'POLICY'  # Feature flag logic

    if 'internationalization---a11y' in text:
        return 'POLICY'  # A11y logic

    if 'secrets-keys' in text:
        return 'SERVICE'  # Secret management

    if 'security---policy' in text:
        return 'POLICY'  # Security policies

    if 'payments-monetization' in text:
        return 'API_ENDPOINT'  # Payment operations

    if 'notifications-' in text and any(word in text for word in ['is-sent', 'delivery', 'preference']):
        return 'API_ENDPOINT'  # Notification operations

    if 'queues-workers' in text:
        return 'SERVICE'  # Queue workers

    # Architecture/design concepts (not actual screens)
    if any(word in text for word in ['architecture', 'system', 'concept', 'language', 'schema']):
        # Check if it's truly a screen or just documentation
        if 'mode-architecture' in text and 'consumption-vs-edit' in text:
            return 'SCREEN'  # Mode switching screen
        return 'POLICY'

    # Default: if it looks like infrastructure, it's a SERVICE
    # Otherwise, assume SCREEN (conservative approach)
    if any(word in text for word in ['infrastructure', 'core-', 'behavior-', 'external-']):
        return 'POLICY'

    return 'SCREEN'

def main():
    """Main classification function."""
    screens_dir = Path("D:/doctorduke/umemee/umemee-v0/plan-fixed/nodes/Screen")

    # Read all screen files
    screen_files = sorted(screens_dir.glob("screen-*.json"))

    classifications: Dict[str, List[str]] = defaultdict(list)
    screen_data: Dict[str, Dict[str, Any]] = {}

    print(f"Analyzing {len(screen_files)} screen files...")

    for file_path in screen_files:
        data = read_json_file(file_path)
        if not data:
            continue

        screen_id = extract_screen_id(data)
        filename = file_path.stem

        category = classify_screen(filename, data)
        classifications[category].append(screen_id or filename)
        screen_data[screen_id or filename] = {
            'filename': filename,
            'name': data.get('name', ''),
            'category': category
        }

        print(f"  {category:15s} | {filename}")

    # Calculate counts
    counts = {category: len(items) for category, items in classifications.items()}
    total = sum(counts.values())

    # Calculate percentages
    backend_operations = counts.get('SERVICE', 0) + counts.get('POLICY', 0) + counts.get('API_ENDPOINT', 0)
    backend_percentage = (backend_operations / total * 100) if total > 0 else 0
    duplicate_percentage = (counts.get('DUPLICATE', 0) / total * 100) if total > 0 else 0
    actual_screens = counts.get('SCREEN', 0)

    # Create output
    output = {
        'total_screens': total,
        'classifications': {k: sorted(v) for k, v in classifications.items()},
        'counts': counts,
        'analysis': {
            'backend_as_screens_count': backend_operations,
            'backend_as_screens_percentage': round(backend_percentage, 2),
            'duplicates_count': counts.get('DUPLICATE', 0),
            'duplicates_percentage': round(duplicate_percentage, 2),
            'actual_screens': actual_screens,
            'actual_screens_percentage': round((actual_screens / total * 100), 2) if total > 0 else 0
        }
    }

    # Write JSON report
    output_path = Path("D:/doctorduke/umemee/umemee-v0/plan-fixed/screen_classification_v45.json")
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(output, f, indent=2)

    print(f"\nClassification complete: {output_path}")
    print(f"\nSummary:")
    print(f"  Total files: {total}")
    print(f"  SCREEN: {counts.get('SCREEN', 0)}")
    print(f"  SERVICE: {counts.get('SERVICE', 0)}")
    print(f"  POLICY: {counts.get('POLICY', 0)}")
    print(f"  API_ENDPOINT: {counts.get('API_ENDPOINT', 0)}")
    print(f"  COMPONENT: {counts.get('COMPONENT', 0)}")
    print(f"  DUPLICATE: {counts.get('DUPLICATE', 0)}")
    print(f"\nAnalysis:")
    print(f"  Backend operations: {backend_operations} ({backend_percentage:.1f}%)")
    print(f"  Actual screens: {actual_screens} ({output['analysis']['actual_screens_percentage']:.1f}%)")
    print(f"  Duplicates: {counts.get('DUPLICATE', 0)} ({duplicate_percentage:.1f}%)")

    return output

if __name__ == '__main__':
    main()
