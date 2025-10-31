# Security Scanning Patterns

## Table of Contents
- [Pre-Commit Secret Detection](#pre-commit-secret-detection)
- [CI/CD Security Pipeline](#cicd-security-pipeline)
- [Comprehensive Dependency Audit](#comprehensive-dependency-audit)
- [SAST with Semgrep](#sast-with-semgrep)
- [Container Security Scanning](#container-security-scanning)
- [IaC Security Analysis](#iac-security-analysis)
- [API Security Testing](#api-security-testing)
- [Git History Secret Scanning](#git-history-secret-scanning)

## Pre-Commit Secret Detection

Prevent secrets from ever being committed:

```bash
# Install pre-commit framework
pip install pre-commit

# .pre-commit-config.yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks

  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']

# Install hooks
pre-commit install

# Now git commit will automatically scan for secrets
```

**Baseline for False Positives:**
```bash
# Create baseline of "known" secrets (test data, etc.)
detect-secrets scan > .secrets.baseline

# Future scans will only alert on new secrets
```

## CI/CD Security Pipeline

Multi-stage security scanning in GitHub Actions:

```yaml
# .github/workflows/security.yml
name: Security Scan

on: [push, pull_request]

jobs:
  sast:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # Semgrep SAST
      - name: Semgrep Scan
        uses: semgrep/semgrep-action@v1
        with:
          config: >-
            p/owasp-top-ten
            p/security-audit
        env:
          SEMGREP_RULES: auto

  secrets:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history for secret scanning

      # TruffleHog secret scanning
      - name: TruffleHog Scan
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./
          base: main
          head: HEAD

  dependencies:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # Node.js dependency scanning
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install Dependencies
        run: npm ci

      - name: Audit Dependencies
        run: npm audit --audit-level=moderate

      # Or use Snyk
      - name: Snyk Security Scan
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}

  containers:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build Docker Image
        run: docker build -t myapp:${{ github.sha }} .

      # Trivy container scanning
      - name: Trivy Scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: myapp:${{ github.sha }}
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH'

      - name: Upload Results
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'

  iac:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # Checkov IaC scanning
      - name: Checkov Scan
        uses: bridgecrewio/checkov-action@master
        with:
          directory: infrastructure/
          framework: terraform
          soft_fail: false  # Fail build on security issues
```

## Comprehensive Dependency Audit

Multi-language dependency scanning script:

```bash
#!/bin/bash
# audit-dependencies.sh

set -e

echo "=== Dependency Security Audit ==="

# Node.js
if [ -f "package.json" ]; then
  echo "Scanning Node.js dependencies..."
  npm audit --audit-level=moderate
fi

# Python
if [ -f "requirements.txt" ]; then
  echo "Scanning Python dependencies..."
  pip install pip-audit
  pip-audit --requirement requirements.txt
fi

# Ruby
if [ -f "Gemfile" ]; then
  echo "Scanning Ruby dependencies..."
  bundle audit check --update
fi

# Go
if [ -f "go.mod" ]; then
  echo "Scanning Go dependencies..."
  go list -json -m all | nancy sleuth
fi

# Rust
if [ -f "Cargo.toml" ]; then
  echo "Scanning Rust dependencies..."
  cargo audit
fi

# Java/Maven
if [ -f "pom.xml" ]; then
  echo "Scanning Maven dependencies..."
  mvn org.owasp:dependency-check-maven:check
fi

# .NET
if [ -f "*.csproj" ]; then
  echo "Scanning .NET dependencies..."
  dotnet list package --vulnerable --include-transitive
fi

echo "=== Audit Complete ==="
```

## SAST with Semgrep

Custom security rules for your codebase:

```yaml
# .semgrep/rules/custom-security.yml
rules:
  - id: hardcoded-secret
    pattern: |
      $VAR = "..."
    message: Potential hardcoded secret detected
    languages: [python, javascript, typescript]
    severity: ERROR
    metadata:
      cwe: "CWE-798: Use of Hard-coded Credentials"
      owasp: "A02:2021 - Cryptographic Failures"

  - id: sql-injection
    patterns:
      - pattern: |
          cursor.execute($QUERY + $VAR)
      - pattern-not: |
          cursor.execute($QUERY, $PARAMS)
    message: Potential SQL injection - use parameterized queries
    languages: [python]
    severity: ERROR
    metadata:
      cwe: "CWE-89: SQL Injection"
      owasp: "A03:2021 - Injection"

  - id: unsafe-deserialization
    pattern: pickle.loads($INPUT)
    message: Unsafe deserialization with pickle
    languages: [python]
    severity: ERROR
    metadata:
      cwe: "CWE-502: Deserialization of Untrusted Data"

  - id: missing-csrf-protection
    pattern: |
      @app.route(...)
      def $FUNC(...):
        ...
    pattern-not-inside: |
      @csrf.exempt
      ...
    message: Route may be missing CSRF protection
    languages: [python]
    severity: WARNING
    metadata:
      owasp: "A01:2021 - Broken Access Control"
```

**Run Semgrep:**
```bash
# Run all rules
semgrep --config=.semgrep/rules/ .

# Run OWASP Top 10 rules
semgrep --config=p/owasp-top-ten .

# Run security audit
semgrep --config=p/security-audit .

# CI mode (exit non-zero on findings)
semgrep --config=auto --error .
```

## Container Security Scanning

Multi-tool container scanning:

```bash
#!/bin/bash
# scan-container.sh

IMAGE=$1

if [ -z "$IMAGE" ]; then
  echo "Usage: $0 <image>"
  exit 1
fi

echo "=== Scanning Container: $IMAGE ==="

# Trivy - Comprehensive scan
echo "Running Trivy..."
trivy image --severity HIGH,CRITICAL $IMAGE

# Grype - Vulnerability scan
echo "Running Grype..."
grype $IMAGE --fail-on high

# Docker Scout (if available)
if command -v docker-scout &> /dev/null; then
  echo "Running Docker Scout..."
  docker scout cves $IMAGE
fi

# Snyk (if authenticated)
if [ -n "$SNYK_TOKEN" ]; then
  echo "Running Snyk..."
  snyk container test $IMAGE --severity-threshold=high
fi

echo "=== Scan Complete ==="
```

## IaC Security Analysis

Terraform security scanning:

```bash
#!/bin/bash
# scan-terraform.sh

set -e

echo "=== Terraform Security Scan ==="

# tfsec - Fast Terraform scanner
echo "Running tfsec..."
tfsec . --minimum-severity MEDIUM

# Checkov - Comprehensive IaC scanner
echo "Running Checkov..."
checkov -d . --framework terraform --soft-fail

# Terrascan - Policy-based scanner
echo "Running Terrascan..."
terrascan scan -t terraform -d .

# Custom checks
echo "Checking for common issues..."

# No hardcoded IPs
if grep -r "0.0.0.0/0" *.tf; then
  echo "WARNING: Found 0.0.0.0/0 (open to world)"
fi

# No default VPCs
if grep -r "default" *.tf | grep -i vpc; then
  echo "WARNING: Using default VPC"
fi

# Encryption enabled
if grep -r "encrypt" *.tf | grep -i "false"; then
  echo "ERROR: Encryption disabled"
  exit 1
fi

echo "=== Scan Complete ==="
```

## API Security Testing

OWASP ZAP automated scanning:

```bash
#!/bin/bash
# scan-api.sh

API_URL=$1
API_SPEC=$2  # OpenAPI/Swagger spec

if [ -z "$API_URL" ]; then
  echo "Usage: $0 <api-url> [openapi-spec.json]"
  exit 1
fi

echo "=== API Security Scan: $API_URL ==="

# Start ZAP in daemon mode
docker run -d --name zap -p 8080:8080 owasp/zap2docker-stable zap.sh -daemon -host 0.0.0.0 -port 8080

sleep 10  # Wait for ZAP to start

# If OpenAPI spec provided, use it
if [ -n "$API_SPEC" ]; then
  echo "Importing API specification..."
  docker exec zap zap-cli open-url "$API_URL"
  docker exec zap zap-cli import-api "$API_SPEC"
else
  # Spider the API
  echo "Spidering API..."
  docker exec zap zap-cli spider "$API_URL"
fi

# Active scan
echo "Running active scan..."
docker exec zap zap-cli active-scan "$API_URL"

# Generate report
echo "Generating report..."
docker exec zap zap-cli report -o /zap/wrk/report.html -f html

# Copy report
docker cp zap:/zap/wrk/report.html ./zap-report.html

# Check for high-severity issues
HIGH_ALERTS=$(docker exec zap zap-cli alerts -l High)
if [ -n "$HIGH_ALERTS" ]; then
  echo "ERROR: High-severity vulnerabilities found!"
  echo "$HIGH_ALERTS"
  exit 1
fi

# Cleanup
docker stop zap && docker rm zap

echo "=== Scan Complete - Report: zap-report.html ==="
```

## Git History Secret Scanning

Comprehensive secret detection:

```bash
#!/bin/bash
# scan-secrets-history.sh

set -e

echo "=== Scanning Git History for Secrets ==="

# TruffleHog - High sensitivity
echo "Running TruffleHog..."
trufflehog git file://. --json --no-update > trufflehog-results.json

# Gitleaks - Fast scanner
echo "Running Gitleaks..."
gitleaks detect --source . --report-path gitleaks-report.json

# detect-secrets - Yelp's scanner
echo "Running detect-secrets..."
detect-secrets scan --all-files > detect-secrets-results.json

# Custom patterns
echo "Checking custom patterns..."

# AWS keys
git grep -E "(AKIA|A3T|AGPA|AIDA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Z0-9]{16}" || true

# Private keys
git grep -E "BEGIN (RSA|DSA|EC|OPENSSH|PGP) PRIVATE KEY" || true

# Generic secrets
git grep -E "(password|passwd|pwd|secret|token|api[_-]?key)\s*[:=]\s*['\"][^'\"]{8,}" -i || true

# Analyze results
echo "=== Analysis ==="

TRUFFLEHOG_COUNT=$(jq length trufflehog-results.json)
GITLEAKS_COUNT=$(jq '.[] | length' gitleaks-report.json)

echo "TruffleHog found: $TRUFFLEHOG_COUNT potential secrets"
echo "Gitleaks found: $GITLEAKS_COUNT potential secrets"

if [ "$TRUFFLEHOG_COUNT" -gt 0 ] || [ "$GITLEAKS_COUNT" -gt 0 ]; then
  echo ""
  echo "ACTION REQUIRED:"
  echo "1. Review findings in *-results.json files"
  echo "2. Remove false positives"
  echo "3. For real secrets:"
  echo "   a. Rotate ALL exposed credentials immediately"
  echo "   b. Remove from history: git filter-repo --path-glob '**/*secret*' --invert-paths"
  echo "   c. Force push: git push --force --all"
  echo "   d. Notify team to re-clone"
  exit 1
fi

echo "=== No Secrets Found ==="
```
