# Security Scanning Examples

## Table of Contents
- [CVE Tracking and Remediation](#cve-tracking-and-remediation)
- [Security Dashboard](#security-dashboard)
- [Language-Specific Scanning](#language-specific-scanning)
- [Remediation Workflows](#remediation-workflows)
- [Real-World Scenarios](#real-world-scenarios)

## CVE Tracking and Remediation

### Python: CVE Priority Script

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
    days_unpatched: int = 0

def prioritize_cves(cves: List[CVE]) -> List[CVE]:
    """Prioritize CVEs for remediation"""

    def score(cve: CVE) -> int:
        priority = 0

        # Severity (highest impact)
        severity_scores = {
            "CRITICAL": 100,
            "HIGH": 75,
            "MEDIUM": 50,
            "LOW": 25
        }
        priority += severity_scores.get(cve.severity, 0)

        # CVSS score
        priority += int(cve.cvss_score * 10)

        # Actively exploited in wild
        if cve.exploitable:
            priority += 50

        # In production (affects revenue/users)
        if cve.in_production:
            priority += 75

        # Days unpatched (age matters)
        if cve.days_unpatched > 30:
            priority += 25

        # Has fix available (can be fixed)
        if cve.fixed_version:
            priority += 25

        return priority

    return sorted(cves, key=score, reverse=True)

def generate_remediation_plan(cves: List[CVE]) -> str:
    """Generate remediation plan grouped by urgency"""

    prioritized = prioritize_cves(cves)

    plan = f"# CVE Remediation Plan - {datetime.now().date()}\n\n"
    plan += f"Total CVEs: {len(cves)}\n"
    plan += f"Generated: {datetime.now().isoformat()}\n\n"

    # Immediate action (critical + exploited)
    critical = [c for c in prioritized if c.severity == "CRITICAL"]
    exploited = [c for c in prioritized if c.exploitable]
    immediate = list(set(critical + exploited))[:5]

    if immediate:
        plan += "## IMMEDIATE ACTION REQUIRED (Fix Today)\n\n"
        for cve in immediate:
            plan += f"### {cve.id} - {cve.package}\n\n"
            plan += f"- **Severity**: {cve.severity} (CVSS {cve.cvss_score})\n"
            plan += f"- **Status**: Actively exploited\n" if cve.exploitable else f"- **Status**: Unpatched for {cve.days_unpatched} days\n"
            plan += f"- **Fix**: Upgrade {cve.package} to {cve.fixed_version}\n"
            plan += f"- **Impact**: {'Production' if cve.in_production else 'Development'}\n"
            plan += f"- **Description**: {cve.description}\n\n"

    # High priority (this week)
    high = [c for c in prioritized if c.severity == "HIGH" and c not in immediate]
    if high:
        plan += "## High Priority (This Week)\n\n"
        for cve in high[:10]:
            plan += f"- {cve.id} ({cve.package}) → {cve.fixed_version}\n"

    # Medium priority (this month)
    medium = [c for c in prioritized if c.severity == "MEDIUM"]
    if medium:
        plan += f"\n## Medium Priority (This Month)\n"
        plan += f"- Total: {len(medium)} items\n"
        plan += "- Schedule for regular dependency update cycle\n"

    # Low priority (eventually)
    low = [c for c in prioritized if c.severity == "LOW"]
    if low:
        plan += f"\n## Low Priority (Batch with Updates)\n"
        plan += f"- Total: {len(low)} items\n"

    return plan

# Example usage
if __name__ == "__main__":
    example_cves = [
        CVE(
            id="CVE-2024-1234",
            severity="CRITICAL",
            package="django",
            fixed_version="4.2.8",
            description="SQL Injection in ORM",
            cvss_score=9.8,
            exploitable=True,
            in_production=True,
            days_unpatched=5
        ),
        CVE(
            id="CVE-2024-5678",
            severity="HIGH",
            package="requests",
            fixed_version="2.31.0",
            description="XXE vulnerability",
            cvss_score=7.5,
            exploitable=False,
            in_production=True,
            days_unpatched=10
        ),
    ]

    plan = generate_remediation_plan(example_cves)
    print(plan)

    with open("remediation-plan.md", "w") as f:
        f.write(plan)
```

## Security Dashboard

### Generate Dashboard from Scan Results

```python
# security_dashboard.py

import json
from datetime import datetime
from pathlib import Path
from collections import defaultdict

def load_json(filepath):
    try:
        with open(filepath) as f:
            return json.load(f)
    except:
        return {}

def count_by_severity(results):
    """Count findings by severity"""
    counts = defaultdict(int)
    if isinstance(results, dict):
        for finding in results.get("findings", []):
            counts[finding.get("severity", "UNKNOWN")] += 1
    return counts

def generate_dashboard():
    """Generate security dashboard from scan results"""

    dashboard = f"""# Security Dashboard
Generated: {datetime.now().isoformat()}
Last Updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## Overall Status

### SAST (Static Analysis)
- **Tool**: Semgrep
- **Status**: Scanned this commit
- **Total Issues**: 42
- **Critical**: 1
- **High**: 5
- **Medium**: 12
- **Low**: 24

### Dependency Scanning
- **Tool**: npm audit / pip-audit
- **Status**: Scanned
- **Vulnerable Packages**: 3
- **Critical**: 0
- **High**: 1
- **Medium**: 2
- **Low**: 0

### Secrets Detection
- **Tool**: TruffleHog / Gitleaks
- **Status**: No secrets detected
- **Findings**: 0

### Container Security
- **Tool**: Trivy
- **Status**: Image not built yet
- **Base Image**: ubuntu:22.04
- **Expected Critical**: 5-10

## Severity Breakdown

| Category | Critical | High | Medium | Low |
|----------|----------|------|--------|-----|
| SAST | 1 | 5 | 12 | 24 |
| Dependencies | 0 | 1 | 2 | 0 |
| Secrets | 0 | 0 | 0 | 0 |
| Containers | - | - | - | - |
| **Total** | **1** | **6** | **14** | **24** |

## Top 5 Issues

### 1. SQL Injection Risk in User Query Builder
- **Location**: src/database.py:145
- **Severity**: CRITICAL
- **CWE**: CWE-89
- **OWASP**: A03:2021 - Injection
- **Fix**: Use parameterized queries instead of string concatenation
- **Status**: OPEN (2 days)

### 2. Hardcoded API Key Detected
- **Location**: config/settings.py:23
- **Severity**: HIGH
- **CWE**: CWE-798
- **OWASP**: A02:2021 - Cryptographic Failures
- **Fix**: Move to environment variables
- **Status**: OPEN (1 day)

### 3. Outdated Django Version
- **Package**: django 3.2.0
- **Severity**: HIGH
- **CVE**: CVE-2024-XXXX
- **Fix**: Upgrade to 4.2.8 (stable) or 5.0.1 (latest)
- **Status**: BLOCKED (compatibility concerns)

## Action Items

### This Sprint (CRITICAL)
- [ ] Fix SQL injection in user query builder (Est: 4 hours)
- [ ] Rotate API key and move to secrets manager (Est: 2 hours)

### This Month (HIGH)
- [ ] Upgrade Django to LTS version (Est: 1 day)
- [ ] Update requests library (Est: 2 hours)
- [ ] Review 12 medium-severity findings (Est: 4 hours)

### Ongoing
- [ ] Monitor low-severity findings
- [ ] Update scan databases daily
- [ ] Review OWASP Top 10 recommendations

## Trends

### This Month
- Critical issues: 1 → 1 (stable)
- High issues: 8 → 6 (improving)
- Medium issues: 18 → 14 (improving)

### This Quarter
- Scanning coverage: 60% → 95% (improving)
- Vulnerability detection: ↑ 40% (more thorough scanning)
- Mean time to remediation: 5 days → 2 days (improving)

## Related Skills

- See `REFERENCE.md` for scanner commands
- See `PATTERNS.md` for CI/CD integration
- See `GOTCHAS.md` for common mistakes
"""

    return dashboard

if __name__ == "__main__":
    dashboard = generate_dashboard()
    Path("security-dashboard.md").write_text(dashboard)
    print(dashboard)
```

## Language-Specific Scanning

### Python Project Security Scan

```bash
#!/bin/bash
# scan-python-project.sh

set -e

echo "=== Python Project Security Scan ==="

# 1. Dependency scanning
echo "1. Scanning Python dependencies..."
if [ -f "requirements.txt" ]; then
    pip-audit --requirement requirements.txt
fi

# 2. SAST
echo "2. Running Bandit (SAST)..."
bandit -r src/ -f json -o bandit-results.json

# 3. Type checking
echo "3. Type checking with mypy..."
mypy src/ --strict || true

# 4. Secret scanning
echo "4. Scanning for secrets..."
detect-secrets scan --all-files > secrets-scan.json

# 5. Code quality
echo "5. Code quality with pylint..."
pylint src/ || true

echo "=== Results ==="
echo "Bandit: $(jq '.results | length' bandit-results.json) issues"
echo "Check results in: bandit-results.json"
```

### JavaScript/Node.js Project Scan

```bash
#!/bin/bash
# scan-nodejs-project.sh

set -e

echo "=== Node.js Project Security Scan ==="

# 1. Install dependencies
echo "1. Installing dependencies..."
npm ci

# 2. Audit dependencies
echo "2. Auditing npm packages..."
npm audit --json > npm-audit.json

# 3. Snyk scan (optional)
if command -v snyk &> /dev/null; then
    echo "3. Running Snyk scan..."
    snyk test --json > snyk-results.json
fi

# 4. ESLint security
echo "4. Running ESLint security scan..."
npx eslint src/ --format json --output eslint-results.json || true

# 5. OWASP ZAP (if running local server)
if [ -n "$API_URL" ]; then
    echo "5. Running OWASP ZAP..."
    # Start local server first
    npm run start &
    SERVER_PID=$!
    sleep 5

    docker run -t owasp/zap2docker-stable zap-baseline.py -t $API_URL -r zap-report.html
    kill $SERVER_PID
fi

echo "=== Results ==="
echo "npm audit: $(jq '.metadata.vulnerabilities.total' npm-audit.json) vulnerabilities"
```

## Remediation Workflows

### Critical CVE Response Workflow

```bash
#!/bin/bash
# critical-cve-response.sh

# When a critical CVE is discovered

CVE_ID=$1
PACKAGE=$2
FIXED_VERSION=$3

if [ -z "$CVE_ID" ] || [ -z "$PACKAGE" ]; then
    echo "Usage: $0 <CVE_ID> <PACKAGE> <FIXED_VERSION>"
    exit 1
fi

echo "=== CRITICAL CVE Response ==="
echo "CVE: $CVE_ID"
echo "Package: $PACKAGE"
echo "Fix: $FIXED_VERSION"
echo ""

# 1. Assess impact
echo "1. Assessing impact..."
grep -r "$PACKAGE" requirements*.txt package*.json Gemfile Cargo.toml pom.xml || echo "Not found in dependencies"

# 2. Check production status
echo "2. Checking if in production..."
git tag | grep prod | tail -5

# 3. Create emergency branch
echo "3. Creating emergency branch..."
BRANCH="hotfix/cve-$CVE_ID-$(date +%s)"
git checkout -b "$BRANCH"

# 4. Update dependency
echo "4. Updating dependency..."
if [ -f "requirements.txt" ]; then
    sed -i "s/$PACKAGE.*/$PACKAGE==$FIXED_VERSION/" requirements.txt
fi
if [ -f "package.json" ]; then
    npm install "$PACKAGE@$FIXED_VERSION"
fi

# 5. Run tests
echo "5. Running tests..."
npm test || pip pytest

# 6. Create PR
echo "6. Creating emergency PR..."
git add .
git commit -m "CRITICAL: Fix $CVE_ID in $PACKAGE"
git push origin "$BRANCH"
echo "PR: $(git remote get-url origin)/compare/$BRANCH"

echo "=== Next Steps ==="
echo "1. Review PR immediately"
echo "2. Merge to main branch"
echo "3. Deploy to production"
echo "4. Verify fix in production"
echo "5. Document in incident log"
```

## Real-World Scenarios

### Scenario 1: Hardcoded API Key in GitHub

**Discovery:**
```
TruffleHog found: AWS_SECRET_ACCESS_KEY = "AKIAIOSFODNN7EXAMPLE"
In file: config.py (5 commits ago)
```

**Response:**
```bash
# 1. Immediately revoke key in AWS
aws iam delete-access-key --access-key-id AKIAIOSFODNN7EXAMPLE

# 2. Create new key
aws iam create-access-key --user-name app-service

# 3. Update all references
grep -r "AKIAIOSFODNN7EXAMPLE" .
# Update CI/CD secrets, environment files, etc.

# 4. Remove from Git history
git filter-repo --path config.py --invert-paths

# 5. Force push
git push --force-with-lease --all

# 6. Notify team
echo "Repository history rewritten - please re-clone"
```

### Scenario 2: Transitive Dependency with Critical CVE

**Discovery:**
```
npm audit reports:
myapp@1.0.0
└── lodash@4.17.19
    └── lodash-es@4.17.19 (CVE-2024-12345 - CRITICAL)
```

**Resolution:**
```bash
# 1. Identify the issue
npm ls lodash-es

# 2. Find who depends on it
grep -r "lodash-es" package.json

# 3. Update to fixed version
npm install lodash-es@4.17.20 --save

# 4. Verify fix
npm audit

# 5. Test thoroughly
npm test

# 6. Deploy
git commit -m "fix: Update lodash-es to patch CVE-2024-12345"
```

### Scenario 3: False Positive in SAST

**Discovery:**
```
Semgrep flags:
- id: hardcoded-secret
  file: tests/test_auth.py:45
  pattern: password = "test_password_123"
```

**Resolution:**
```python
# tests/test_auth.py

# Add nosec comment with explanation
# nosec - Test fixture, not real credential
password = "test_password_123"

# Or create test data file
# tests/fixtures/credentials.json (in .gitignore)
{
    "password": "test_password_123"  # Mock data for tests only
}

# Then update code to load from fixture
```

### Scenario 4: Container Scan Shows Base Image Vulnerabilities

**Discovery:**
```
Trivy scan of ubuntu:20.04:
- 42 vulnerabilities found
- 5 CRITICAL (unrelated to our code)
- 8 HIGH (kernel vulnerabilities)
```

**Resolution:**
```dockerfile
# Old Dockerfile
FROM ubuntu:20.04
RUN apt-get update && apt-get install -y python3

# New: Use hardened base image
FROM python:3.11-slim-bullseye
# Automatically patched, minimal footprint

# Or: Create custom base image
FROM ubuntu:22.04  # Newer version
RUN apt-get update && apt-get upgrade -y  # Apply patches
RUN apt-get install --no-install-recommends -y \
    python3 \
    python3-pip
```

Then:
```bash
# Test new base
trivy image myapp:new
# Verify vulnerabilities reduced
```
