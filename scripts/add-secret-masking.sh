#!/bin/bash
# Script to add secret masking to GitHub Actions workflows
# Security: Prevents credential exposure in logs (OWASP A09:2021)

set -euo pipefail

WORKFLOW_DIR=".github/workflows"
MASKING_STEP='      # SECURITY: Mask secrets as first step to prevent credential exposure
      # OWASP A09:2021 - Security Logging and Monitoring Failures
      - name: Mask sensitive values
        uses: ./.github/actions/mask-secrets
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          ai_api_key: ${{ secrets.AI_API_KEY }}
'

# Function to add masking to a workflow
add_masking_to_workflow() {
    local file="$1"
    local temp_file="${file}.tmp"

    echo "Processing: $file"

    # Check if masking already exists
    if grep -q "mask-secrets" "$file"; then
        echo "  ✓ Already has secret masking"
        return 0
    fi

    # Add masking after 'steps:' line in each job
    awk -v masking="$MASKING_STEP" '
    /^    steps:$/ {
        print $0
        print masking
        next
    }
    { print }
    ' "$file" > "$temp_file"

    # Replace original with updated version
    mv "$temp_file" "$file"
    echo "  ✓ Added secret masking"
}

# Process all workflow files
echo "Adding secret masking to workflows..."
echo "======================================"

for workflow in "$WORKFLOW_DIR"/*.yml; do
    if [[ -f "$workflow" ]]; then
        add_masking_to_workflow "$workflow"
    fi
done

echo ""
echo "✅ Secret masking added to all workflows"
echo ""
echo "Summary:"
echo "--------"
grep -l "mask-secrets" "$WORKFLOW_DIR"/*.yml | while read -r file; do
    echo "  ✓ $(basename "$file")"
done