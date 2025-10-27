---
name: security-scanning-suite
description: Comprehensive security analysis including SAST, DAST, dependency scanning, secret detection, and vulnerability assessment. Use for security audits, CVE tracking, compliance checks, and preventing vulnerabilities from reaching production. Supports multiple languages and frameworks.
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, WebFetch]
---

# Security Scanning Suite

## Purpose

"With no vulnerabilities, no security issues" (user's production requirement). This Skill provides comprehensive security scanning and analysis:

1. **SAST (Static Application Security Testing)** - Code analysis for vulnerabilities
2. **DAST (Dynamic Application Security Testing)** - Runtime security testing
3. **Dependency Scanning** - Find vulnerable dependencies
4. **Secret Detection** - Prevent credential leaks
5. **Container Security** - Docker/OCI image scanning
6. **Infrastructure Security** - IaC security analysis
7. **Compliance Checking** - OWASP, CWE, PCI-DSS standards
8. **Vulnerability Management** - CVE tracking and remediation

## When to Use This Skill

- Pre-commit security checks
- CI/CD security gates
- Security audits before production deployment
- Finding and fixing CVEs in dependencies
- Detecting hardcoded secrets or credentials
- Scanning Docker images for vulnerabilities
- Terraform/CloudFormation security analysis
- API security testing
- Compliance verification (OWASP Top 10, CWE Top 25)
- Penetration testing automation
- Security regression testing

## Core Concepts

### Security Layers

```
┌─────────────────────────────────────┐
│  Code (SAST)                        │
│  ├── SQL Injection                  │
│  ├── XSS                            │
│  └── Code Quality Issues            │
├─────────────────────────────────────┤
│  Dependencies (SCA)                 │
│  ├── Known CVEs                     │
│  ├── License Compliance             │
│  └── Outdated Packages              │
├─────────────────────────────────────┤
│  Secrets (Secret Detection)         │
│  ├── API Keys                       │
│  ├── Passwords                      │
│  └── Tokens                         │
├─────────────────────────────────────┤
│  Infrastructure (IaC Security)      │
│  ├── Misconfigurations              │
│  ├── Excessive Permissions          │
│  └── Insecure Defaults              │
├─────────────────────────────────────┤
│  Containers (Image Scanning)        │
│  ├── Base Image Vulnerabilities     │
│  ├── Malware                        │
│  └── Configuration Issues           │
└─────────────────────────────────────┘
```

### OWASP Top 10 (2021)

1. **A01: Broken Access Control** - Authorization failures
2. **A02: Cryptographic Failures** - Weak encryption, exposed data
3. **A03: Injection** - SQL, NoSQL, OS command injection
4. **A04: Insecure Design** - Missing security controls
5. **A05: Security Misconfiguration** - Default configs, verbose errors
6. **A06: Vulnerable Components** - Outdated libraries
7. **A07: Authentication Failures** - Weak auth/session management
8. **A08: Software/Data Integrity** - Untrusted sources, insecure CI/CD
9. **A09: Security Logging Failures** - Inadequate monitoring
10. **A10: Server-Side Request Forgery** - SSRF attacks

## Knowledge Resources

### SAST Tools

- [Semgrep](https://semgrep.dev/) - Fast, customizable SAST (30+ languages)
- [Bandit](https://bandit.readthedocs.io/) - Python security linter
- [ESLint Security Plugin](https://github.com/nodesecurity/eslint-plugin-security) - JavaScript security rules
- [Brakeman](https://brakemanscanner.org/) - Ruby on Rails security scanner
- [gosec](https://github.com/securego/gosec) - Go security checker
- [SonarQube](https://www.sonarqube.org/) - Enterprise code quality & security

### Dependency Scanning

- [npm audit](https://docs.npmjs.com/cli/v8/commands/npm-audit) - Node.js dependency scanning
- [Dependabot](https://github.com/dependabot) - Automated dependency updates
- [Snyk](https://snyk.io/) - Comprehensive dependency scanning
- [OWASP Dependency-Check](https://owasp.org/www-project-dependency-check/) - Java/Python/Ruby/.NET
- [pip-audit](https://pypi.org/project/pip-audit/) - Python dependency scanner
- [cargo-audit](https://github.com/rustsec/rustsec) - Rust dependency scanner

### Secret Detection

- [TruffleHog](https://github.com/trufflesecurity/truffleHog) - Find secrets in Git history
- [detect-secrets](https://github.com/Yelp/detect-secrets) - Prevent secret commits
- [GitLeaks](https://github.com/gitleaks/gitleaks) - Fast secret scanner
- [git-secrets](https://github.com/awslabs/git-secrets) - AWS-focused secret prevention

### Container Security

- [Trivy](https://trivy.dev/) - Comprehensive container/IaC/dependency scanner
- [Grype](https://github.com/anchore/grype) - Vulnerability scanner for containers
- [Docker Scout](https://docs.docker.com/scout/) - Docker's native security scanner
- [Clair](https://github.com/quay/clair) - Container vulnerability analysis

### DAST Tools

- [OWASP ZAP](https://www.zaproxy.org/) - Web application security scanner
- [Nuclei](https://github.com/projectdiscovery/nuclei) - Fast vulnerability scanner
- [Burp Suite](https://portswigger.net/burp) - Web security testing (commercial)
- [Nikto](https://github.com/sullo/nikto) - Web server scanner

### IaC Security

- [Checkov](https://www.checkov.io/) - IaC security scanner (Terraform, CloudFormation, K8s)
- [tfsec](https://github.com/aquasecurity/tfsec) - Terraform security scanner
- [KICS](https://kics.io/) - Keeping Infrastructure as Code Secure
- [Terrascan](https://runterrascan.io/) - IaC vulnerability scanner

### Standards & References

- [OWASP Top 10](https://owasp.org/www-project-top-ten/) - Top web vulnerabilities
- [CWE Top 25](https://cwe.mitre.org/top25/) - Most dangerous software weaknesses
- [CVE Database](https://cve.mitre.org/) - Common Vulnerabilities and Exposures
- [NIST NVD](https://nvd.nist.gov/) - National Vulnerability Database
- [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/) - Verification standard

## Common Security Gotchas

1. **False Positives** - SAST tools generate many false positives
   - **Solution**: Tune rules, use `# nosec` comments judiciously, focus on high-severity

2. **Secrets in Git History** - Removing from current commit isn't enough
   - **Solution**: Use `git filter-repo` or BFG to rewrite history, rotate credentials

3. **Transitive Dependencies** - Vulnerabilities in dependencies of dependencies
   - **Solution**: Use lock files, scan deeply, update regularly

4. **Scanner Fatigue** - Too many scanners, conflicting results
   - **Solution**: Start with 1-2 core tools (Semgrep + Trivy covers most), expand gradually

5. **Ignoring Low Severity** - Low CVEs can be chained into high-impact exploits
   - **Solution**: Track all vulnerabilities, prioritize high/critical but fix low eventually

6. **Outdated Scanners** - Scanner databases need frequent updates
   - **Solution**: Update scanner DBs daily in CI/CD

7. **Local vs Production Config** - Different security posture in different environments
   - **Solution**: Scan all environments, use same base images/configs

8. **API Key Rotation** - Finding secrets but not rotating them
   - **Solution**: Immediately rotate any found credentials, don't just remove from code

## Implementation Patterns

### Pattern 1: Pre-Commit Secret Detection

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

**Baseline for False Positives**:
```bash
# Create baseline of "known" secrets (test data, etc.)
detect-secrets scan > .secrets.baseline

# Future scans will only alert on new secrets
```

### Pattern 2: CI/CD Security Pipeline

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

### Pattern 3: Comprehensive Dependency Audit

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

  # Alternative: Snyk
  # npx snyk test --severity-threshold=medium
fi

# Python
if [ -f "requirements.txt" ]; then
  echo "Scanning Python dependencies..."
  pip install pip-audit
  pip-audit --requirement requirements.txt

  # Alternative: Safety
  # pip install safety
  # safety check --file requirements.txt
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

### Pattern 4: SAST with Semgrep

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

**Run Semgrep**:
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

### Pattern 5: Container Security Scanning

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

### Pattern 6: IaC Security Analysis

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

### Pattern 7: API Security Testing

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

### Pattern 8: Secret Scanning Git History

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

## Vulnerability Management

### CVE Tracking Workflow

```python
# cve_tracker.py - Track and prioritize CVEs

import json
from dataclasses import dataclass
from typing import List
from datetime import datetime

@dataclass
class CVE:
    id: str
    severity: str  # CRITICAL, HIGH, MEDIUM, LOW
    package: str
    fixed_version: str
    description: str
    cvss_score: float
    exploitable: bool
    in_production: bool

def prioritize_cves(cves: List[CVE]) -> List[CVE]:
    """Prioritize CVEs for remediation"""

    def score(cve: CVE) -> int:
        priority = 0

        # Severity
        severity_scores = {
            "CRITICAL": 100,
            "HIGH": 75,
            "MEDIUM": 50,
            "LOW": 25
        }
        priority += severity_scores.get(cve.severity, 0)

        # CVSS score
        priority += int(cve.cvss_score * 10)

        # Exploitable in wild
        if cve.exploitable:
            priority += 50

        # In production
        if cve.in_production:
            priority += 75

        # Has fix available
        if cve.fixed_version:
            priority += 25

        return priority

    return sorted(cves, key=score, reverse=True)

def generate_remediation_plan(cves: List[CVE]) -> str:
    """Generate remediation plan"""

    prioritized = prioritize_cves(cves)

    plan = f"# CVE Remediation Plan - {datetime.now().date()}\n\n"
    plan += f"Total CVEs: {len(cves)}\n\n"

    # Critical immediate action
    critical = [c for c in prioritized if c.severity == "CRITICAL"]
    if critical:
        plan += "## IMMEDIATE ACTION REQUIRED\n\n"
        for cve in critical:
            plan += f"- **{cve.id}** ({cve.package})\n"
            plan += f"  - CVSS: {cve.cvss_score}\n"
            plan += f"  - Fix: Upgrade to {cve.fixed_version}\n"
            if cve.exploitable:
                plan += "  - ⚠️ ACTIVELY EXPLOITED IN WILD\n"
            plan += f"  - {cve.description}\n\n"

    # High priority (this week)
    high = [c for c in prioritized if c.severity == "HIGH"]
    if high:
        plan += "## High Priority (This Week)\n\n"
        for cve in high:
            plan += f"- {cve.id} ({cve.package}) - Upgrade to {cve.fixed_version}\n"

    # Medium priority (this month)
    medium = [c for c in prioritized if c.severity == "MEDIUM"]
    if medium:
        plan += f"\n## Medium Priority ({len(medium)} items)\n\n"
        plan += "Schedule for this sprint\n"

    return plan

# Usage
if __name__ == "__main__":
    # Parse scan results and create CVE objects
    cves = parse_scan_results("trivy-results.json")
    plan = generate_remediation_plan(cves)

    with open("remediation-plan.md", "w") as f:
        f.write(plan)

    print(plan)
```

### Security Dashboard

Generate security status dashboard:

```python
# security_dashboard.py

import json
from datetime import datetime
from pathlib import Path

def generate_dashboard():
    """Generate security dashboard from scan results"""

    # Load scan results
    sast_results = load_json("semgrep-results.json")
    dependency_results = load_json("npm-audit.json")
    secret_results = load_json("trufflehog-results.json")
    container_results = load_json("trivy-results.json")

    # Calculate metrics
    dashboard = f"""# Security Dashboard
Generated: {datetime.now().isoformat()}

## Overall Status
- **SAST Issues**: {count_by_severity(sast_results)}
- **Vulnerable Dependencies**: {count_vulnerabilities(dependency_results)}
- **Exposed Secrets**: {len(secret_results)}
- **Container Vulnerabilities**: {count_by_severity(container_results)}

## Severity Breakdown
| Category | Critical | High | Medium | Low |
|----------|----------|------|--------|-----|
| SAST | {count_severity(sast_results, 'CRITICAL')} | {count_severity(sast_results, 'HIGH')} | {count_severity(sast_results, 'MEDIUM')} | {count_severity(sast_results, 'LOW')} |
| Dependencies | {count_severity(dependency_results, 'CRITICAL')} | {count_severity(dependency_results, 'HIGH')} | {count_severity(dependency_results, 'MEDIUM')} | {count_severity(dependency_results, 'LOW')} |
| Containers | {count_severity(container_results, 'CRITICAL')} | {count_severity(container_results, 'HIGH')} | {count_severity(container_results, 'MEDIUM')} | {count_severity(container_results, 'LOW')} |

## Top Issues
{generate_top_issues(sast_results, dependency_results, container_results)}

## Trends
{generate_trends()}

## Action Items
{generate_action_items(sast_results, dependency_results, secret_results, container_results)}
"""

    Path("security-dashboard.md").write_text(dashboard)
    print(dashboard)

if __name__ == "__main__":
    generate_dashboard()
```

## Best Practices

### DO's

1. **Shift Left** - Scan early, scan often (pre-commit, PR, deploy)
2. **Prioritize** - Fix critical/high first, track medium/low
3. **Automate** - Integrate into CI/CD, block on critical issues
4. **Track Trends** - Monitor security posture over time
5. **Update Scanners** - Keep scanner databases current
6. **Educate Team** - Security training, secure coding practices
7. **Rotate Secrets** - Rotate credentials immediately when exposed
8. **Use Baselines** - Track known false positives, focus on new issues

### DON'Ts

1. **Don't Ignore Low Severity** - Can be chained into serious exploits
2. **Don't Trust Defaults** - Configure scanners for your threat model
3. **Don't Scan Only Production** - Scan all environments
4. **Don't Block Everything** - Balance security with developer velocity
5. **Don't Forget Transitive Deps** - Scan entire dependency tree
6. **Don't Hardcode Secrets** - Use env vars, secret managers
7. **Don't Skip Updates** - Outdated dependencies are easy targets
8. **Don't Scan Without Acting** - Scanning without fixing is security theater

## Integration with Development

### Pre-Commit Hooks

```bash
# .git/hooks/pre-commit
#!/bin/bash

echo "Running security checks..."

# Secret detection
echo "Checking for secrets..."
if ! gitleaks protect --staged; then
  echo "ERROR: Secrets detected!"
  exit 1
fi

# SAST on changed files
echo "Running SAST..."
CHANGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(py|js|ts|go)$')
if [ -n "$CHANGED_FILES" ]; then
  semgrep --config=auto --error $CHANGED_FILES
fi

echo "Security checks passed!"
```

### PR Checks

```yaml
# .github/workflows/pr-security.yml
name: PR Security Checks

on: pull_request

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Security Scan
        run: |
          # Quick SAST on changed files only
          git diff --name-only origin/main... | xargs semgrep --config=auto

      - name: Dependency Check
        run: npm audit --audit-level=high

      - name: Secret Scan
        uses: trufflesecurity/trufflehog@main
        with:
          base: ${{ github.event.pull_request.base.sha }}
          head: ${{ github.event.pull_request.head.sha }}

      - name: Comment Results
        uses: actions/github-script@v6
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: 'Security scan complete! ✅'
            })
```

## Related Skills

- `deployment-automation-toolkit` - Integrate security scanning in deployment
- `code-review-framework` - Security-focused code review
- `multi-agent-coordination-framework` - Coordinate security response
- `incident-responder` (agent) - Handle security incidents

## References

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CWE/SANS Top 25](https://cwe.mitre.org/top25/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [SANS Secure Coding](https://www.sans.org/secure-coding/)
- [GitHub Security Best Practices](https://docs.github.com/en/code-security)