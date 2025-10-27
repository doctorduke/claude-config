#!/bin/bash
# check_scanner_installed.sh - Verify security scanners are installed

set -e

SCANNERS=(
  "semgrep"
  "bandit"
  "npm"
  "pip-audit"
  "trivy"
  "trufflehog"
  "gitleaks"
  "checkov"
  "tfsec"
)

echo "=== Security Scanner Verification ==="
echo ""

INSTALLED=0
MISSING=0

for scanner in "${SCANNERS[@]}"; do
  if command -v "$scanner" &> /dev/null; then
    VERSION=$("$scanner" --version 2>/dev/null || echo "unknown")
    echo "✓ $scanner: $VERSION"
    ((INSTALLED++))
  else
    echo "✗ $scanner: NOT INSTALLED"
    ((MISSING++))
  fi
done

echo ""
echo "=== Summary ==="
echo "Installed: $INSTALLED/${#SCANNERS[@]}"
echo "Missing: $MISSING/${#SCANNERS[@]}"

if [ $MISSING -gt 0 ]; then
  echo ""
  echo "Install missing scanners:"
  echo "  pip install bandit pip-audit semgrep checkov"
  echo "  brew install trivy trufflehog gitleaks tfsec"
  exit 1
fi

exit 0
