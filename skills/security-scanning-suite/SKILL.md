---
name: security-scanning-suite
description: Comprehensive security analysis including SAST, DAST, dependency scanning, secret detection, and vulnerability assessment. Use for security audits, CVE tracking, compliance checks, and preventing vulnerabilities from reaching production. Supports multiple languages and frameworks.
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, WebFetch]
---

# Security Scanning Suite

## Purpose

Security scanning detects vulnerabilities before they reach production. This Skill provides:

1. **SAST** - Code analysis for vulnerabilities (Semgrep, Bandit, ESLint-security)
2. **Dependency Scanning** - Find vulnerable packages (npm audit, pip-audit, Snyk)
3. **Secret Detection** - Prevent credential leaks (TruffleHog, Gitleaks)
4. **Container Security** - Docker/OCI scanning (Trivy, Grype)
5. **DAST** - Runtime security testing (OWASP ZAP, Nikto)
6. **IaC Security** - Infrastructure scanning (Checkov, tfsec)
7. **Compliance** - OWASP Top 10, CWE verification
8. **Vulnerability Management** - CVE tracking and remediation

## When to Use This Skill

- Pre-commit security checks and CI/CD gates
- Security audits before production deployment
- Finding and fixing CVEs in dependencies
- Detecting hardcoded secrets or credentials
- Scanning Docker images for vulnerabilities
- Terraform/CloudFormation security analysis
- API security testing and compliance verification
- Penetration testing automation and security regression testing

## Quick Reference

| Layer | Tools | Detection |
|-------|-------|-----------|
| **Code** | Semgrep, Bandit | SQL injection, XSS, weak crypto |
| **Dependencies** | npm audit, pip-audit, Snyk | Known CVEs |
| **Secrets** | TruffleHog, Gitleaks | API keys, passwords, tokens |
| **Containers** | Trivy, Grype | OS vulns, misconfigs |
| **Infrastructure** | Checkov, tfsec | IaC misconfigurations |

## Core Concepts

### Security Layers

1. **Code Level (SAST)** - Vulnerable code patterns
2. **Component Level (SCA)** - Vulnerable dependencies
3. **Configuration Level** - Misconfigurations
4. **Runtime Level (DAST)** - Actual exploitation
5. **Container Level** - Base image vulnerabilities

### OWASP Top 10 (2021)

1. **A01** - Broken Access Control (authorization failures)
2. **A02** - Cryptographic Failures (weak encryption, exposed data)
3. **A03** - Injection (SQL, NoSQL, command injection)
4. **A04** - Insecure Design (missing security controls)
5. **A05** - Security Misconfiguration (default configs, verbose errors)
6. **A06** - Vulnerable Components (outdated libraries)
7. **A07** - Authentication Failures (weak auth/session management)
8. **A08** - Software/Data Integrity (untrusted sources)
9. **A09** - Security Logging Failures (inadequate monitoring)
10. **A10** - Server-Side Request Forgery (SSRF attacks)

## Essential Workflow

### 1. Pre-Commit: Secret Detection

Prevent secrets from being committed:

```bash
pip install pre-commit
# Add .pre-commit-config.yaml (see PATTERNS.md)
pre-commit install
```

### 2. Code Scan (SAST)

Analyze code for vulnerabilities:

```bash
# Python
bandit -r src/

# JavaScript
npx eslint src/ --plugin security

# Multi-language
semgrep --config=p/owasp-top-ten .
```

### 3. Dependency Audit

Check for known CVEs:

```bash
npm audit --audit-level=moderate
pip-audit --requirement requirements.txt
cargo audit
```

### 4. Secret History Scan

Find secrets already in Git:

```bash
trufflehog git file://.
gitleaks detect --source .
```

### 5. Container Scan

Scan Docker images:

```bash
trivy image ubuntu:20.04
trivy image myapp:latest
```

### 6. Infrastructure Scan

Analyze IaC files:

```bash
checkov -d . --framework terraform
tfsec . --minimum-severity MEDIUM
```

## Scanning Pattern

Most efficient approach:

```
Pre-commit      → Secrets only (gitleaks protect)
PR checks       → SAST + Dependency audit (quick)
Nightly build   → Full suite (comprehensive)
Release         → Full + container scan
Production      → Continuous monitoring
```

## Best Practices

### DO's

1. **Shift Left** - Scan early, scan often
2. **Prioritize** - Fix critical/high first
3. **Automate** - Integrate into CI/CD
4. **Track Trends** - Monitor posture over time
5. **Update Scanners** - Keep databases current
6. **Rotate Secrets** - Immediately when exposed

### DON'Ts

1. **Don't Ignore Low CVEs** - Can chain into exploits
2. **Don't Trust Defaults** - Configure for your threat model
3. **Don't Scan Only Production** - Scan all environments
4. **Don't Block Everything** - Balance security with velocity
5. **Don't Skip Updates** - Outdated deps are easy targets
6. **Don't Scan Without Acting** - Fix what you find

## CI/CD Integration (GitHub Actions)

Quick security pipeline:

```yaml
name: Security

on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      # SAST
      - uses: semgrep/semgrep-action@v1
        with:
          config: p/owasp-top-ten

      # Dependencies
      - run: npm audit --audit-level=moderate

      # Secrets
      - uses: trufflesecurity/trufflehog@main

      # Container
      - run: trivy image myapp:latest

      # IaC
      - uses: bridgecrewio/checkov-action@master
        with:
          framework: terraform
```

## Key Decisions

**Which tools to use?**
- Start with 1-2 core tools (Semgrep + Trivy covers most cases)
- Add language-specific tools as needed
- Avoid "all the tools" - causes fatigue

**What severity levels?**
- CRITICAL/HIGH: Fix this sprint
- MEDIUM: Schedule this month
- LOW: Batch with regular updates

**False positives?**
- Focus on high-confidence findings first
- Create baselines to track only new issues
- Use `# nosec` comments sparingly

## Common Issues & Solutions

**Too many false positives?**
- Tune scanner rules for your codebase
- Start with pre-configured OWASP rules
- See GOTCHAS.md for detailed solutions

**Secrets already committed?**
- Rotate all exposed credentials immediately
- Remove from history: `git filter-repo`
- Notify team to re-clone
- See PATTERNS.md for secret scanning pattern

**Can't upgrade vulnerable dependency?**
- Check for security patches in current version
- Use workarounds if necessary
- Plan upgrade in next release
- See EXAMPLES.md for remediation workflows

## File References

This skill uses progressive disclosure - related content in separate files:

- **REFERENCE.md** - Complete scanner CLI reference and commands
- **PATTERNS.md** - SAST/DAST patterns and CI/CD integration examples
- **GOTCHAS.md** - False positives, limitations, configuration mistakes
- **EXAMPLES.md** - Real-world examples and remediation workflows
- **KNOWLEDGE.md** - Tool overviews, OWASP, CVE databases, standards

## Minimal Scanner Setup

### Python Project

```bash
# Install
pip install bandit semgrep pip-audit detect-secrets

# Run
bandit -r src/
semgrep --config=p/security-audit .
pip-audit --requirement requirements.txt
detect-secrets scan > .secrets.baseline
```

### JavaScript Project

```bash
# Install
npm install --save-dev eslint-plugin-security
npm install -g semgrep

# Run
npx eslint src/ --plugin security
npm audit
semgrep --config=p/owasp-top-ten .
```

### Container

```bash
# Install (Docker)
docker pull aquasecurity/trivy

# Run
trivy image ubuntu:20.04
trivy fs /path/to/project
```

## Related Skills

- `deployment-automation-toolkit` - Integrate scanning in CI/CD
- `code-review-framework` - Security-focused code review
- `incident-responder` (agent) - Handle security incidents

## Standards

- **OWASP Top 10 (2021)** - Web app vulnerabilities
- **CWE Top 25** - Most dangerous weaknesses
- **CVE Database** - Known vulnerabilities
- **CVSS** - Vulnerability severity scores
- **PCI-DSS** - Compliance requirement for scanning
