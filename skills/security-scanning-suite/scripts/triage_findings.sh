#!/bin/bash
# triage_findings.sh - Triage and prioritize security findings

set -e

REPORT_DIR="${1:-security-reports}"
OUTPUT_FILE="${2:-security-triage.md}"

if [ ! -d "$REPORT_DIR" ]; then
  echo "Error: Report directory not found: $REPORT_DIR"
  exit 1
fi

echo "=== Security Findings Triage ==="
echo ""

# Initialize output file
cat > "$OUTPUT_FILE" << 'EOF'
# Security Findings Triage Report

Generated: $(date)

## Executive Summary

This report categorizes and prioritizes security findings for remediation.

### Critical & High (Act Immediately)

| Finding | Severity | Tools | Action |
|---------|----------|-------|--------|
EOF

# Parse Semgrep findings
if ls "$REPORT_DIR"/semgrep-*.json &> /dev/null; then
  echo ""
  echo "Analyzing Semgrep findings..."

  for report in "$REPORT_DIR"/semgrep-*.json; do
    # Count by severity
    ERRORS=$(jq '[.results[] | select(.extra.severity=="ERROR")] | length' "$report" 2>/dev/null || echo "0")
    WARNINGS=$(jq '[.results[] | select(.extra.severity=="WARNING")] | length' "$report" 2>/dev/null || echo "0")

    if [ "$ERRORS" -gt 0 ] || [ "$WARNINGS" -gt 0 ]; then
      echo "  Semgrep findings:"
      echo "    - Errors (High): $ERRORS"
      echo "    - Warnings: $WARNINGS"

      # Extract top issues
      if [ "$ERRORS" -gt 0 ]; then
        echo ""
        echo "  Top HIGH severity issues:"
        jq -r '.results[] | select(.extra.severity=="ERROR") | "\(.check_id): \(.message)" | limit(3; .)' "$report" 2>/dev/null | while read -r line; do
          echo "    - $line"
        done
      fi
    fi
  done
fi

# Parse Gitleaks findings
if ls "$REPORT_DIR"/gitleaks-*.json &> /dev/null; then
  echo ""
  echo "Analyzing Gitleaks findings..."

  for report in "$REPORT_DIR"/gitleaks-*.json; do
    SECRET_COUNT=$(jq 'length' "$report" 2>/dev/null || echo "0")

    if [ "$SECRET_COUNT" -gt 0 ]; then
      echo "  Secrets found: $SECRET_COUNT"
      echo ""
      echo "  ⚠️ ACTION REQUIRED: Immediately rotate exposed credentials"
      echo "    1. Review findings in: $report"
      echo "    2. Rotate all exposed credentials"
      echo "    3. Remove from Git history"
      echo "    4. Force push"
    fi
  done
fi

# Parse Checkov findings
if ls "$REPORT_DIR"/checkov-*.json &> /dev/null; then
  echo ""
  echo "Analyzing Checkov (IaC) findings..."

  for report in "$REPORT_DIR"/checkov-*/results_json.json; do
    if [ -f "$report" ]; then
      CRITICAL=$(jq '.summary.failed // 0' "$report" 2>/dev/null || echo "0")
      PASSED=$(jq '.summary.passed // 0' "$report" 2>/dev/null || echo "0")

      if [ "$CRITICAL" -gt 0 ]; then
        echo "  IaC issues:"
        echo "    - Failed checks: $CRITICAL"
        echo "    - Passed checks: $PASSED"
      fi
    fi
  done
fi

# Parse npm audit findings
if ls "$REPORT_DIR"/npm-audit-*.json &> /dev/null; then
  echo ""
  echo "Analyzing npm audit findings..."

  for report in "$REPORT_DIR"/npm-audit-*.json; do
    CRITICAL=$(jq '.metadata.vulnerabilities.critical // 0' "$report" 2>/dev/null || echo "0")
    HIGH=$(jq '.metadata.vulnerabilities.high // 0' "$report" 2>/dev/null || echo "0")

    if [ "$CRITICAL" -gt 0 ] || [ "$HIGH" -gt 0 ]; then
      echo "  npm vulnerabilities:"
      echo "    - Critical: $CRITICAL"
      echo "    - High: $HIGH"
    fi
  done
fi

# Parse pip-audit findings
if ls "$REPORT_DIR"/pip-audit-*.txt &> /dev/null; then
  echo ""
  echo "Analyzing pip-audit findings..."

  for report in "$REPORT_DIR"/pip-audit-*.txt; do
    VULN_COUNT=$(grep -c "has \|vulnerability" "$report" 2>/dev/null || echo "0")

    if [ "$VULN_COUNT" -gt 0 ]; then
      echo "  pip vulnerabilities found: $VULN_COUNT"
    fi
  done
fi

# Generate remediation section
cat >> "$OUTPUT_FILE" << 'EOF'

## Remediation Priority

### Immediate (Today)
- [ ] Review and rotate exposed secrets
- [ ] Fix critical SAST issues
- [ ] Update critical dependency vulnerabilities
- [ ] Fix infrastructure misconfigurations

### This Week
- [ ] Fix high-severity findings
- [ ] Update high-priority dependencies
- [ ] Review OWASP Top 10 findings

### This Month
- [ ] Address medium-severity findings
- [ ] Update medium-priority dependencies
- [ ] Verify all fixes in staging

### Long-term
- [ ] Track low-severity findings
- [ ] Plan major version upgrades
- [ ] Security training and awareness

## Report Files

EOF

# List generated reports
echo "Generated report files:" >> "$OUTPUT_FILE"
ls -1 "$REPORT_DIR"/* 2>/dev/null | while read -r file; do
  echo "- $(basename "$file")" >> "$OUTPUT_FILE"
done

echo ""
echo "Triage complete!"
echo "Summary written to: $OUTPUT_FILE"
cat "$OUTPUT_FILE"
