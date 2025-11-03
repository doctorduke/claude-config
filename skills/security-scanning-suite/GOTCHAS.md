# Security Scanning Gotchas & Limitations

## Table of Contents
- [False Positives](#false-positives)
- [Transitive Dependencies](#transitive-dependencies)
- [Scanner Fatigue](#scanner-fatigue)
- [Low Severity CVEs](#low-severity-cves)
- [Outdated Scanners](#outdated-scanners)
- [Environment Differences](#environment-differences)
- [Secrets in Git History](#secrets-in-git-history)
- [API Key Rotation](#api-key-rotation)
- [Configuration Mistakes](#configuration-mistakes)

## False Positives

SAST tools generate many false positives. This is one of the biggest frustrations.

**Problem:**
- Semgrep flags `"password" = "test123"` even in test files
- Bandit warns about pickle even when input is trusted
- 70%+ of alerts may be false positives in some codebases

**Solutions:**
1. **Use `# nosec` comments judiciously** (prefer sparingly, not everywhere):
   ```python
   # nosec - Known test data, not real credentials
   password = "test123"
   ```

2. **Focus on high-severity findings first** - Low/medium often have high FP rate

3. **Create baseline of false positives**:
   ```bash
   # Save baseline
   semgrep --config=auto . > baseline.json

   # Future runs compare only new issues
   semgrep --config=auto . > current.json
   # Filter to delta
   ```

4. **Tune rules for your context**:
   ```yaml
   - id: sql-injection
     patterns:
       - pattern: cursor.execute($QUERY + $VAR)
       - pattern-not: cursor.execute(f"SELECT * FROM {table}") # Known pattern
     message: Potential SQL injection
   ```

5. **Separate tooling by severity**:
   - **Pre-commit**: Only highest confidence rules
   - **CI/CD**: Medium confidence
   - **Nightly**: All rules

## Transitive Dependencies

Vulnerabilities hidden in dependencies of dependencies.

**Problem:**
```
myapp → lodash@4.0.0
       → underscore@1.0.0 → CVE-2021-12345
```

The vulnerability is in `underscore`, a dependency of your dependency.

**Solutions:**
1. **Use lock files** - Pin exact versions:
   ```bash
   npm ci  # Uses package-lock.json, not package.json
   pip install -r requirements.lock.txt
   ```

2. **Deep scanning**:
   ```bash
   npm audit  # Scans all transitive deps
   pip-audit --requirement requirements.txt
   ```

3. **Update regularly**:
   ```bash
   npm update  # Updates all packages within ranges
   npm audit fix  # Automatically fixes CVEs
   ```

4. **Monitor SBOM**:
   ```bash
   # Generate Software Bill of Materials
   trivy image --format sbom ubuntu:20.04 > sbom.json
   ```

## Scanner Fatigue

Too many scanners → conflicting results → ignored findings.

**Problem:**
- Semgrep says "OK"
- Bandit says "CRITICAL"
- ESLint says "WARNING"
- You ignore all three because they disagree

**Solutions:**
1. **Start with 1-2 core tools**:
   - Python codebase: Bandit + Semgrep
   - JavaScript: ESLint-security + npm audit
   - Containers: Trivy (covers most cases)

2. **Layer scanners by stage**:
   ```
   Pre-commit:      detect-secrets only
   PR:              Semgrep + npm audit
   Nightly:         Full suite (+ DAST)
   Production:      Trivy container scan
   ```

3. **Map findings to OWASP Top 10**:
   ```
   CWE-89 (SQL injection) → A03:2021 (Injection)
   CWE-798 (Hardcoded secret) → A02:2021 (Cryptographic Failures)

   Only report if finding maps to top categories
   ```

## Low Severity CVEs

Tempting to ignore, but can chain into exploits.

**Problem:**
- CVE-2024-12345: Low severity (CVSS 3.2)
- Seems unimportant
- Gets ignored in backlog
- Later: combined with CVE-2024-54321 (low) = critical exploit

**Solutions:**
1. **Track all CVEs**, prioritize but don't ignore:
   ```
   CRITICAL/HIGH: Fix immediately (this sprint)
   MEDIUM: Schedule fix (this month)
   LOW: Track & fix when updating anyway
   ```

2. **Review low CVEs monthly**:
   ```python
   low_cves = [c for c in all_cves if c.severity == "LOW"]
   if len(low_cves) > 0:
       # Schedule batch update
       print(f"Low CVEs to address: {len(low_cves)}")
   ```

3. **Create dependency update policy**:
   - Monthly dependency updates minimum
   - Run full security audit each cycle
   - Batch low-severity fixes

## Outdated Scanners

Scanner databases decay quickly. Old data = missed vulnerabilities.

**Problem:**
- Trivy database from 2 weeks ago misses new CVEs
- Semgrep rules don't have latest OWASP patterns
- npm audit cache stale by a few days

**Solutions:**
1. **Update scanner databases before each scan**:
   ```bash
   # Trivy
   trivy image --download-db-only
   trivy image ubuntu:20.04

   # npm
   npm cache clean --force
   npm audit
   ```

2. **Schedule nightly updates**:
   ```yaml
   # .github/workflows/security-nightly.yml
   name: Nightly Security

   on:
     schedule:
       - cron: '0 2 * * *'  # 2 AM daily

   jobs:
     update:
       runs-on: ubuntu-latest
       steps:
         - run: trivy image --download-db-only
         - run: npm cache clean --force
         - run: semgrep --config=p/security-audit . > report.json
   ```

3. **Centralize DB updates**:
   - Use shared container image with pre-downloaded databases
   - Versioned databases: `trivy:v0.50.0-db-2024-10-26`

## Environment Differences

Different security posture per environment.

**Problem:**
```
Local:       No secrets scan, no container scan
Staging:     Secrets scan only
Production:  Full security suite
```

Result: Issues slip through because you didn't scan that environment.

**Solutions:**
1. **Scan all environments identically**:
   ```bash
   # Parameterize scan scripts
   ./run-security-scan.sh --environment local
   ./run-security-scan.sh --environment staging
   ./run-security-scan.sh --environment production

   # Each runs same scanners
   ```

2. **Use same base images everywhere**:
   ```dockerfile
   FROM ubuntu:20.04-base  # Single base, versioned
   # All environments reference same base
   ```

3. **Configuration management**:
   - Store configs in code (not per-environment)
   - Scan all configs: local, staging, prod

## Secrets in Git History

Removing from current code isn't enough.

**Problem:**
```
$ git show HEAD~5:password_config.py
PASSWORD="super_secret_123"  # Still in history!
```

Even if you delete the file now, it's still in Git history.

**Solutions:**
1. **Immediately rotate** any found credentials:
   ```bash
   # 1. Change password/key NOW
   # 2. Alert infrastructure team
   # 3. Revoke old credentials
   # 4. Only then remove from repo
   ```

2. **Remove from history** (use one tool, not multiple):
   ```bash
   # Option A: git filter-repo (recommended)
   git filter-repo --path password_config.py --invert-paths

   # Option B: git filter-branch (older)
   git filter-branch --tree-filter 'rm -f password_config.py' HEAD

   # Option C: BFG (for large repos)
   bfg --delete-files password_config.py
   ```

3. **Force push** (notify all developers to re-clone):
   ```bash
   git push --force --all
   git push --force --tags
   # Notify team: "Repo history rewritten, please re-clone"
   ```

4. **Pre-commit prevention**:
   ```bash
   # Install gitleaks pre-commit hook
   pre-commit install
   git commit -m "test"  # Will fail if secrets detected
   ```

## API Key Rotation

Finding secrets but not rotating them.

**Problem:**
- Scanner finds AWS key in code from 2023
- Team removes from code
- Old key still active (in AWS, in CI/CD, in employee's laptop)
- Attacker still has access

**Solution - Incident Response**:
1. **Discover**: Scanner alerts on API key
2. **Assess**: Is key still active? How was it used?
3. **Rotate NOW**:
   ```bash
   # AWS
   aws iam delete-access-key --access-key-id AKIA...
   aws iam create-access-key --user-name service-account

   # GitHub
   gh secret set GITHUB_TOKEN
   ```
4. **Update everywhere**: CI/CD, services, documentation
5. **Verify**: Old key is deleted, new one works
6. **Audit logs**: Check if compromised key was used

**Prevention:**
- Secrets manager (AWS Secrets Manager, Vault)
- Short-lived credentials (IAM roles, JWT)
- Audit all credential usage

## Configuration Mistakes

Misconfigured scanners → miss findings.

**Common Mistakes:**

1. **Wrong severity threshold**:
   ```bash
   npm audit --audit-level=moderate  # Misses low/info issues

   # Better:
   npm audit --audit-level=low  # Flag all issues, decide separately
   ```

2. **Excluding too much**:
   ```bash
   bandit -r . --exclude tests  # Also exclude venv, node_modules, etc

   # But don't exclude actual source!
   ```

3. **Not running in CI mode**:
   ```bash
   semgrep .  # Runs but doesn't fail build

   # Better:
   semgrep --error .  # Fails with non-zero exit
   ```

4. **Hardcoded paths**:
   ```bash
   # Bad - works locally, fails in CI
   tfsec /home/developer/project

   # Good - relative paths
   tfsec .
   ```

5. **Missing fetch-depth in GitHub Actions**:
   ```yaml
   - uses: actions/checkout@v4
     # Missing fetch-depth: 0

   - run: trufflehog git file://. # Only scans current commit!

   # Better:
   - uses: actions/checkout@v4
     with:
       fetch-depth: 0  # Full history
   ```

6. **Scanner version mismatch**:
   ```bash
   # Local: Trivy v0.48.0 (old database)
   # CI: Trivy v0.50.0 (new database)
   # Different results!

   # Solution: Pin versions
   trivy 0.50.0 --download-db-only
   ```
