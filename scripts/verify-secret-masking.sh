#!/bin/bash
# Verification script for secret masking implementation
# Security: Ensures all workflows have proper secret masking

set -euo pipefail

WORKFLOW_DIR=".github/workflows"
EXIT_CODE=0

echo "🔍 Secret Masking Verification"
echo "=============================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check 1: All workflows have masking
echo "Check 1: Verifying all workflows have secret masking..."
MISSING_MASKING=0

for workflow in "$WORKFLOW_DIR"/*.yml; do
    if [[ -f "$workflow" ]]; then
        FILENAME=$(basename "$workflow")

        # Skip the test workflow itself
        if [[ "$FILENAME" == "test-secret-masking.yml" ]]; then
            continue
        fi

        if grep -q "mask-secrets" "$workflow"; then
            echo -e "${GREEN}✓${NC} $FILENAME has secret masking"
        else
            echo -e "${RED}✗${NC} $FILENAME MISSING secret masking"
            MISSING_MASKING=$((MISSING_MASKING + 1))
            EXIT_CODE=1
        fi
    fi
done

echo ""

# Check 2: Masking is first step in jobs
echo "Check 2: Verifying masking is first step in jobs..."
WRONG_ORDER=0

for workflow in "$WORKFLOW_DIR"/*.yml; do
    if [[ -f "$workflow" ]]; then
        FILENAME=$(basename "$workflow")

        # Skip test workflow
        if [[ "$FILENAME" == "test-secret-masking.yml" ]]; then
            continue
        fi

        # Extract first step after "steps:" that isn't a comment
        FIRST_STEP=$(awk '/^    steps:$/ {getline; while ($0 ~ /^[[:space:]]*#/ || $0 ~ /^[[:space:]]*$/) getline; print; exit}' "$workflow")

        if echo "$FIRST_STEP" | grep -q "Mask sensitive\|mask-secrets"; then
            echo -e "${GREEN}✓${NC} $FILENAME: Masking is first step"
        else
            echo -e "${YELLOW}⚠${NC} $FILENAME: Masking might not be first step"
            echo "  First step: $FIRST_STEP"
            # Not a hard error since some workflows might have special cases
        fi
    fi
done

echo ""

# Check 3: Composite action exists
echo "Check 3: Verifying composite action exists..."
ACTION_FILE=".github/actions/mask-secrets/action.yml"

if [[ -f "$ACTION_FILE" ]]; then
    echo -e "${GREEN}✓${NC} Composite action exists: $ACTION_FILE"

    # Verify it has the required inputs
    if grep -q "github_token:" "$ACTION_FILE"; then
        echo -e "${GREEN}✓${NC} Action has github_token input"
    else
        echo -e "${RED}✗${NC} Action missing github_token input"
        EXIT_CODE=1
    fi

    if grep -q "ai_api_key:" "$ACTION_FILE"; then
        echo -e "${GREEN}✓${NC} Action has ai_api_key input"
    else
        echo -e "${RED}✗${NC} Action missing ai_api_key input"
        EXIT_CODE=1
    fi

    if grep -q "::add-mask::" "$ACTION_FILE"; then
        echo -e "${GREEN}✓${NC} Action uses ::add-mask:: directive"
    else
        echo -e "${RED}✗${NC} Action missing ::add-mask:: directive"
        EXIT_CODE=1
    fi
else
    echo -e "${RED}✗${NC} Composite action NOT found: $ACTION_FILE"
    EXIT_CODE=1
fi

echo ""

# Check 4: Test workflow exists
echo "Check 4: Verifying test workflow exists..."
TEST_WORKFLOW=".github/workflows/test-secret-masking.yml"

if [[ -f "$TEST_WORKFLOW" ]]; then
    echo -e "${GREEN}✓${NC} Test workflow exists: $TEST_WORKFLOW"
else
    echo -e "${RED}✗${NC} Test workflow NOT found: $TEST_WORKFLOW"
    EXIT_CODE=1
fi

echo ""

# Check 5: Documentation exists
echo "Check 5: Verifying documentation exists..."
DOCS=(
    "SECURITY-AUDIT.md"
    "SECURITY-TASK7-SUMMARY.md"
    ".github/SECURITY-QUICK-REFERENCE.md"
    ".github/actions/mask-secrets/README.md"
)

for doc in "${DOCS[@]}"; do
    if [[ -f "$doc" ]]; then
        echo -e "${GREEN}✓${NC} Documentation exists: $doc"
    else
        echo -e "${RED}✗${NC} Documentation MISSING: $doc"
        EXIT_CODE=1
    fi
done

echo ""

# Check 6: No hardcoded secrets
echo "Check 6: Scanning for hardcoded secrets (basic check)..."
SUSPICIOUS_PATTERNS=(
    "ghp_[a-zA-Z0-9]{36}"
    "gho_[a-zA-Z0-9]{36}"
    "github_pat_[a-zA-Z0-9]{22}_[a-zA-Z0-9]{59}"
    "sk-[a-zA-Z0-9]{48}"
)

FOUND_SECRETS=0

for pattern in "${SUSPICIOUS_PATTERNS[@]}"; do
    # Exclude docs directory (contains examples) and look for real secrets
    MATCHES=$(grep -rE "$pattern" --exclude-dir=.git --exclude-dir=docs . 2>/dev/null || true)

    if [[ -n "$MATCHES" ]]; then
        # Filter out obvious placeholders (all x's or y's)
        REAL_SECRETS=$(echo "$MATCHES" | grep -vE "(x{10,}|y{10,}|EXAMPLE|example|placeholder)" || true)

        if [[ -n "$REAL_SECRETS" ]]; then
            echo -e "${RED}✗${NC} Found pattern matching: $pattern"
            echo "$REAL_SECRETS"
            FOUND_SECRETS=$((FOUND_SECRETS + 1))
            EXIT_CODE=1
        fi
    fi
done

if [[ $FOUND_SECRETS -eq 0 ]]; then
    echo -e "${GREEN}✓${NC} No hardcoded secrets found (examples excluded)"
fi

echo ""

# Summary
echo "=============================="
echo "Summary:"
echo "=============================="

if [[ $EXIT_CODE -eq 0 ]]; then
    echo -e "${GREEN}✅ All checks passed!${NC}"
    echo ""
    echo "Secret masking is properly implemented across all workflows."
else
    echo -e "${RED}❌ Some checks failed!${NC}"
    echo ""
    echo "Please review and fix the issues above."

    if [[ $MISSING_MASKING -gt 0 ]]; then
        echo ""
        echo "To add masking to missing workflows, run:"
        echo "  bash scripts/add-secret-masking.sh"
    fi
fi

echo ""
echo "Next steps:"
echo "  1. Review the verification results above"
echo "  2. Run test workflow: gh workflow run test-secret-masking.yml -f test_mode=with-masking"
echo "  3. Check logs to verify secrets appear as ***"
echo "  4. Merge to main when ready: git checkout main && git merge security/task7-secret-masking"

exit $EXIT_CODE