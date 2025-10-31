# Security Scanning Reference

## Table of Contents
- [SAST Tools Reference](#sast-tools-reference)
- [Dependency Scanning Reference](#dependency-scanning-reference)
- [Secret Detection Reference](#secret-detection-reference)
- [Container Security Reference](#container-security-reference)
- [DAST Tools Reference](#dast-tools-reference)
- [IaC Security Reference](#iac-security-reference)

## SAST Tools Reference

### Semgrep

**Installation:**
```bash
pip install semgrep
# or
brew install semgrep
```

**Basic Usage:**
```bash
# Scan current directory
semgrep --config=auto .

# Run OWASP Top 10 rules
semgrep --config=p/owasp-top-ten .

# Run security audit
semgrep --config=p/security-audit .

# Scan specific file
semgrep --config=auto file.py

# JSON output
semgrep --config=auto --json . > results.json

# Exit non-zero on findings
semgrep --config=auto --error .

# Run custom rules
semgrep --config=.semgrep/rules/ .
```

**Configuration Options:**
```yaml
# .semgrep.yml
rules:
  - id: rule-id
    patterns:
      - pattern: code_pattern
    message: Description
    languages: [python, javascript]
    severity: ERROR  # ERROR, WARNING
```

**Output Formats:**
- `--json` - JSON format for parsing
- `--sarif` - SARIF format for GitHub integration
- `--html` - HTML report
- `--junit-xml` - JUnit XML for CI/CD

### Bandit (Python)

**Installation:**
```bash
pip install bandit
```

**Basic Usage:**
```bash
# Scan entire directory
bandit -r .

# Scan single file
bandit file.py

# JSON output
bandit -r . -f json -o results.json

# HTML report
bandit -r . -f html -o report.html

# Exclude directories
bandit -r . --exclude tests,venv

# Run specific tests
bandit -r . -t B201,B301
```

**Configuration:**
```yaml
# .bandit
tests: [B201, B301, B302]  # Specific tests
skips: [B101]  # Skip specific tests
```

**Severity Levels:**
- `LOW`, `MEDIUM`, `HIGH`

### ESLint Security Plugin (JavaScript)

**Installation:**
```bash
npm install --save-dev eslint eslint-plugin-security
```

**Configuration:**
```javascript
// .eslintrc.json
{
  "extends": ["plugin:security/recommended"],
  "plugins": ["security"]
}
```

**Usage:**
```bash
eslint . --ext .js,.ts

# JSON output
eslint . --format json -o results.json

# HTML report
eslint . --format html -o report.html
```

### Brakeman (Ruby on Rails)

**Installation:**
```bash
gem install brakeman
```

**Usage:**
```bash
# Scan Rails app
brakeman -A

# JSON output
brakeman -f json -o results.json

# HTML report
brakeman -f html -o report.html

# Ignore specific checks
brakeman --skip-checks 1,2,3
```

### gosec (Go)

**Installation:**
```bash
go install github.com/securego/gosec/v2/cmd/gosec@latest
```

**Usage:**
```bash
# Scan directory
gosec ./...

# JSON output
gosec -fmt json ./... > results.json

# HTML output
gosec -fmt sarif ./... > results.sarif

# Exclude directories
gosec -exclude=./tests ./...
```

## Dependency Scanning Reference

### npm audit (Node.js)

**Basic Usage:**
```bash
# Check for vulnerabilities
npm audit

# Show json format
npm audit --json

# Audit specific packages
npm audit --package=lodash

# Set minimum severity
npm audit --audit-level=moderate

# Fix vulnerabilities
npm audit fix

# Fix with latest versions
npm audit fix --force
```

### pip-audit (Python)

**Installation:**
```bash
pip install pip-audit
```

**Usage:**
```bash
# Audit installed packages
pip-audit

# Audit requirements file
pip-audit --requirement requirements.txt

# JSON output
pip-audit --desc > audit-report.json

# Fix vulnerabilities
pip-audit --fix
```

### cargo-audit (Rust)

**Installation:**
```bash
cargo install cargo-audit
```

**Usage:**
```bash
# Check Cargo.lock
cargo audit

# JSON output
cargo audit --json

# Fix vulnerabilities
cargo update
```

### bundle audit (Ruby)

**Installation:**
```bash
gem install bundler-audit
```

**Usage:**
```bash
# Audit Gemfile.lock
bundle-audit check

# Update database
bundle-audit update

# JSON output (check project docs)
bundle-audit check --format json
```

### OWASP Dependency-Check

**Installation:**
```bash
# Via Docker (recommended)
docker pull owasp/dependency-check

# Or download from https://github.com/jeremylong/DependencyCheck/releases
```

**Usage:**
```bash
# Scan directory
docker run --rm -v $(pwd):/src owasp/dependency-check --scan /src

# XML report
dependency-check.sh --scan . --format XML

# HTML report
dependency-check.sh --scan . --format HTML

# Exclude patterns
dependency-check.sh --scan . --exclude node_modules,build
```

## Secret Detection Reference

### TruffleHog

**Installation:**
```bash
pip install trufflehog
# or
brew install trufflehog
```

**Usage:**
```bash
# Scan Git history
trufflehog git file://.

# JSON output
trufflehog git file://. --json > results.json

# High entropy only
trufflehog filesystem . --entropy

# Regex patterns
trufflehog regex file://. --regex "AWS|password"

# Specific branch
trufflehog git file://. --branch main
```

**Configuration:**
```json
{
  "detectors": ["aws", "github", "slack"],
  "entropy_threshold": 4.5
}
```

### Gitleaks

**Installation:**
```bash
brew install gitleaks
# or
docker pull zricethezav/gitleaks
```

**Usage:**
```bash
# Scan directory
gitleaks detect --source .

# JSON report
gitleaks detect -v --report-path report.json

# Scan Git history
gitleaks detect --no-git

# Scan specific branch
gitleaks detect -v -s origin/main

# Config file
gitleaks detect --config=.gitleaks.toml
```

**Configuration:**
```toml
# .gitleaks.toml
[[rules]]
id = "github-token"
description = "GitHub Personal Access Token"
regex = "ghp_[0-9a-zA-Z]{36}"
entropy = 3.7
keywords = ["github"]
```

### detect-secrets (Yelp)

**Installation:**
```bash
pip install detect-secrets
```

**Usage:**
```bash
# Create baseline
detect-secrets scan > .secrets.baseline

# Scan with baseline
detect-secrets scan --baseline .secrets.baseline

# Audit findings
detect-secrets audit .secrets.baseline

# JSON output (use audit)
detect-secrets scan --json
```

## Container Security Reference

### Trivy

**Installation:**
```bash
brew install trivy
# or
wget https://github.com/aquasecurity/trivy/releases/download/v0.x.x/trivy_Linux_x86_64.tar.gz
```

**Usage:**
```bash
# Scan image
trivy image ubuntu:20.04

# JSON output
trivy image --format json --output results.json ubuntu:20.04

# SARIF output (GitHub integration)
trivy image --format sarif --output results.sarif ubuntu:20.04

# Severity filter
trivy image --severity HIGH,CRITICAL ubuntu:20.04

# Scan local tarball
trivy image --input image.tar

# Filesystem scan
trivy fs /path/to/project

# Config scan
trivy config /path/to/terraform
```

### Grype

**Installation:**
```bash
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh
```

**Usage:**
```bash
# Scan image
grype ubuntu:20.04

# JSON output
grype --output json ubuntu:20.04 > results.json

# Fail on severity
grype --fail-on high ubuntu:20.04

# SBOM input
grype sbom:syft-json-file.json
```

### Docker Scout

**Usage:**
```bash
# List vulnerabilities
docker scout cves myimage:latest

# Show recommendations
docker scout recommendations myimage:latest

# Compare images
docker scout compare myimage:v1 myimage:v2
```

## DAST Tools Reference

### OWASP ZAP

**Docker Usage:**
```bash
# Start ZAP in daemon mode
docker run -d --name zap -p 8080:8080 owasp/zap2docker-stable zap.sh -daemon -host 0.0.0.0 -port 8080

# Spider
docker exec zap zap-cli spider http://target.com

# Active scan
docker exec zap zap-cli active-scan http://target.com

# Generate report
docker exec zap zap-cli report -o /zap/wrk/report.html -f html

# Check alerts
docker exec zap zap-cli alerts -l High
```

### Nikto

**Installation:**
```bash
brew install nikto
# or download from https://github.com/sullo/nikto/wiki
```

**Usage:**
```bash
# Basic scan
nikto -h target.com

# Specify port
nikto -h target.com -p 8080

# SSL
nikto -h target.com -ssl

# Plugins
nikto -h target.com -Plugins tests

# Output formats
nikto -h target.com -Format txt -o report.txt
```

## IaC Security Reference

### Checkov

**Installation:**
```bash
pip install checkov
```

**Usage:**
```bash
# Scan Terraform
checkov -d . --framework terraform

# Scan CloudFormation
checkov -d . --framework cloudformation

# Scan Kubernetes
checkov -d . --framework kubernetes

# Soft fail (warn but don't fail)
checkov -d . --soft-fail

# JSON output
checkov -d . --framework terraform --output json

# Skip checks
checkov -d . --skip-check CKV_AWS_1,CKV_AWS_2
```

**Custom Checks:**
Create `custom_checks/` directory with check files.

### tfsec

**Installation:**
```bash
brew install tfsec
```

**Usage:**
```bash
# Scan Terraform
tfsec .

# Specific minimum severity
tfsec . --minimum-severity MEDIUM

# JSON output
tfsec . --format json > results.json

# Skip rules
tfsec . --skip aws/s3/enable-bucket-encryption
```

## Standards & Compliance Reference

### OWASP Top 10 (2021)

| ID | Name | CWE | Detection |
|----|------|-----|-----------|
| A01 | Broken Access Control | 639 | SAST, code review |
| A02 | Cryptographic Failures | 327 | SAST, crypto analyzers |
| A03 | Injection | 89 | SAST, DAST |
| A04 | Insecure Design | 1275 | Architecture review |
| A05 | Security Misconfiguration | 16 | IaC scanners |
| A06 | Vulnerable Components | 1104 | Dependency scanning |
| A07 | Authentication Failures | 287 | DAST, code review |
| A08 | Software/Data Integrity | 345 | DAST, supply chain |
| A09 | Security Logging Failures | 778 | Code review |
| A10 | Server-Side Request Forgery | 918 | DAST, SAST |

### CWE Top 25

See [cwe.mitre.org/top25](https://cwe.mitre.org/top25/) for current list.

### CVE Databases

- **NVD**: https://nvd.nist.gov/
- **CVE**: https://cve.mitre.org/
- **GitHub Advisory**: https://github.com/advisories
- **Snyk Database**: https://snyk.io/vulnerability-scanner/
