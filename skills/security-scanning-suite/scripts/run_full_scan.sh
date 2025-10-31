#!/bin/bash
# run_full_scan.sh - Complete security scan workflow

set -e

REPORT_DIR="security-reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$REPORT_DIR"

echo "=== Full Security Scan ($TIMESTAMP) ==="
echo ""

# 1. Check scanners installed
echo "1. Checking scanner availability..."
if command -v semgrep &> /dev/null; then
  echo "  ✓ Semgrep installed"
else
  echo "  ✗ Semgrep not installed, skipping SAST"
fi

# 2. Secret detection
echo ""
echo "2. Scanning for secrets..."
if command -v gitleaks &> /dev/null; then
  gitleaks detect --source . --report-path "$REPORT_DIR/gitleaks-$TIMESTAMP.json" || true
  echo "  ✓ Gitleaks complete"
fi

# 3. SAST
echo ""
echo "3. Running SAST (Semgrep)..."
if command -v semgrep &> /dev/null; then
  semgrep --config=p/owasp-top-ten \
    --json -o "$REPORT_DIR/semgrep-$TIMESTAMP.json" \
    . 2>/dev/null || true
  echo "  ✓ Semgrep complete"
fi

# 4. Python dependency audit
if [ -f "requirements.txt" ]; then
  echo ""
  echo "4. Auditing Python dependencies..."
  if command -v pip-audit &> /dev/null; then
    pip-audit --requirement requirements.txt > "$REPORT_DIR/pip-audit-$TIMESTAMP.txt" || true
    echo "  ✓ pip-audit complete"
  fi
fi

# 5. Node.js dependency audit
if [ -f "package.json" ]; then
  echo ""
  echo "5. Auditing Node.js dependencies..."
  if command -v npm &> /dev/null; then
    npm audit --json > "$REPORT_DIR/npm-audit-$TIMESTAMP.json" 2>/dev/null || true
    echo "  ✓ npm audit complete"
  fi
fi

# 6. IaC scanning
if [ -d "terraform" ] || [ -f "*.tf" ]; then
  echo ""
  echo "6. Scanning Infrastructure as Code..."
  if command -v checkov &> /dev/null; then
    checkov -d . --framework terraform \
      --output json --output-file-path "$REPORT_DIR/checkov-$TIMESTAMP" \
      --soft-fail 2>/dev/null || true
    echo "  ✓ Checkov complete"
  fi
fi

# 7. Container scanning (if Dockerfile exists)
if [ -f "Dockerfile" ]; then
  echo ""
  echo "7. Building and scanning container..."
  if command -v trivy &> /dev/null; then
    # Try to build image
    IMAGE_TAG="app:$TIMESTAMP"
    if docker build -t "$IMAGE_TAG" . 2>/dev/null; then
      trivy image --format json --output "$REPORT_DIR/trivy-$TIMESTAMP.json" "$IMAGE_TAG"
      echo "  ✓ Trivy container scan complete"
    fi
  fi
fi

echo ""
echo "=== Scan Complete ==="
echo "Reports saved to: $REPORT_DIR/"
echo ""

# Summary statistics
REPORT_COUNT=$(find "$REPORT_DIR" -name "*-$TIMESTAMP.*" | wc -l)
echo "Generated $REPORT_COUNT reports"

# Show high-severity findings
echo ""
echo "=== High Severity Findings ==="
if [ -f "$REPORT_DIR/semgrep-$TIMESTAMP.json" ]; then
  ERROR_COUNT=$(jq '[.results[] | select(.extra.severity=="ERROR")] | length' "$REPORT_DIR/semgrep-$TIMESTAMP.json" 2>/dev/null || echo "0")
  echo "Semgrep errors: $ERROR_COUNT"
fi

if [ -f "$REPORT_DIR/gitleaks-$TIMESTAMP.json" ]; then
  SECRET_COUNT=$(jq 'length' "$REPORT_DIR/gitleaks-$TIMESTAMP.json" 2>/dev/null || echo "0")
  echo "Secrets found: $SECRET_COUNT"
fi

echo ""
echo "For detailed analysis, review reports in $REPORT_DIR/"
