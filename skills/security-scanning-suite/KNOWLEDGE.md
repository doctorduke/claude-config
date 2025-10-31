# Security Scanning Knowledge Base

## Table of Contents
- [SAST Tools Overview](#sast-tools-overview)
- [Dependency Scanning Tools](#dependency-scanning-tools)
- [Secret Detection Tools](#secret-detection-tools)
- [Container Security Tools](#container-security-tools)
- [DAST Tools Overview](#dast-tools-overview)
- [IaC Security Tools](#iac-security-tools)
- [Standards & Compliance](#standards--compliance)

## SAST Tools Overview

### Semgrep
- **Best for**: Multi-language, customizable rules
- **Languages**: Python, JavaScript, TypeScript, Go, Java, Ruby, PHP, C, and 30+ more
- **Strengths**: Fast, easy custom rules, great OWASP coverage
- **Weaknesses**: Can have false positives, needs tuning for projects
- **Cost**: Free/Open Source and Semgrep Pro
- **Website**: https://semgrep.dev/

### Bandit
- **Best for**: Python-specific security issues
- **Languages**: Python only
- **Strengths**: Purpose-built for Python, catches common mistakes
- **Weaknesses**: Python-only, less sophisticated than Semgrep
- **Cost**: Free
- **Website**: https://bandit.readthedocs.io/

### ESLint Security Plugin
- **Best for**: JavaScript/TypeScript security rules
- **Languages**: JavaScript, TypeScript
- **Strengths**: Integrates with ESLint workflow
- **Weaknesses**: Limited scope compared to Semgrep
- **Cost**: Free
- **Website**: https://github.com/nodesecurity/eslint-plugin-security

### Brakeman
- **Best for**: Ruby on Rails applications
- **Languages**: Ruby
- **Strengths**: Rails-specific vulnerabilities
- **Weaknesses**: Rails-only
- **Cost**: Free
- **Website**: https://brakemanscanner.org/

### gosec
- **Best for**: Go security analysis
- **Languages**: Go
- **Strengths**: Go-specific, built-in with Go toolchain
- **Weaknesses**: Go-only, less sophisticated
- **Cost**: Free
- **Website**: https://github.com/securego/gosec

### SonarQube
- **Best for**: Enterprise code quality + security
- **Languages**: 30+ languages
- **Strengths**: Comprehensive, tracks trends
- **Weaknesses**: Commercial, requires setup
- **Cost**: Free Community / Commercial Enterprise
- **Website**: https://www.sonarqube.org/

## Dependency Scanning Tools

### npm audit
- **Package Manager**: npm (Node.js)
- **Coverage**: Direct + transitive dependencies
- **Strengths**: Built-in, requires no setup
- **Limitations**: npm-only
- **Cost**: Free
- **Commands**: `npm audit`, `npm audit fix`

### pip-audit
- **Package Manager**: pip (Python)
- **Coverage**: All installed packages + requirements files
- **Strengths**: Python-focused
- **Limitations**: Python-only
- **Cost**: Free
- **Website**: https://pypi.org/project/pip-audit/

### cargo-audit
- **Package Manager**: Cargo (Rust)
- **Coverage**: Cargo.lock and Cargo.toml
- **Strengths**: Rust-focused
- **Limitations**: Rust-only
- **Cost**: Free
- **Website**: https://github.com/rustsec/rustsec

### bundle audit
- **Package Manager**: Bundler (Ruby)
- **Coverage**: Gemfile.lock
- **Strengths**: Ruby-focused
- **Limitations**: Ruby-only
- **Cost**: Free

### Snyk
- **Package Manager**: All (npm, pip, Maven, Gradle, Composer, etc.)
- **Coverage**: Direct + transitive + dev dependencies
- **Strengths**: Multi-language, real-time vulnerability data
- **Limitations**: Commercial SaaS
- **Cost**: Free tier / Commercial
- **Website**: https://snyk.io/

### OWASP Dependency-Check
- **Package Manager**: Multiple (Maven, Gradle, npm, pip, Composer, etc.)
- **Coverage**: Comprehensive dependency analysis
- **Strengths**: Open source, no account required
- **Limitations**: Slower, sometimes noisy
- **Cost**: Free
- **Website**: https://owasp.org/www-project-dependency-check/

## Secret Detection Tools

### TruffleHog
- **Detection**: Entropy-based + pattern matching
- **Scope**: Git history, file systems, S3
- **Strengths**: High accuracy, finds real secrets
- **Limitations**: Slower on large repos
- **Cost**: Free / Truffle Pro
- **Website**: https://github.com/trufflesecurity/truffleHog

### Gitleaks
- **Detection**: Pattern-based (regex rules)
- **Scope**: Git history, file systems
- **Strengths**: Very fast, configurable rules
- **Limitations**: Pattern-based can miss entropy-based secrets
- **Cost**: Free
- **Website**: https://github.com/gitleaks/gitleaks

### detect-secrets (Yelp)
- **Detection**: Entropy + pattern based
- **Scope**: Git history, file systems
- **Strengths**: Baseline support, audit workflows
- **Limitations**: Requires baseline management
- **Cost**: Free
- **Website**: https://github.com/Yelp/detect-secrets

### git-secrets (AWS)
- **Detection**: Pre-commit hooks + patterns
- **Scope**: Commits, history
- **Strengths**: AWS-focused patterns, CLI focus
- **Limitations**: AWS-centric
- **Cost**: Free
- **Website**: https://github.com/awslabs/git-secrets

## Container Security Tools

### Trivy
- **Scope**: Container images, filesystems, IaC
- **Vulnerabilities**: CVEs, misconfigurations, secrets
- **Strengths**: All-in-one, fast, free, reliable
- **Cost**: Free / Aqua Security paid
- **Website**: https://trivy.dev/

### Grype (Anchore)
- **Scope**: Container images, SBOMs
- **Vulnerabilities**: CVEs from multiple databases
- **Strengths**: Multiple DB sources, accurate
- **Cost**: Free
- **Website**: https://github.com/anchore/grype

### Docker Scout
- **Scope**: Docker images
- **Vulnerabilities**: CVEs, supply chain data
- **Strengths**: Native Docker integration
- **Limitations**: Docker Desktop only
- **Cost**: Free (integrated with Docker)

### Clair (Quay.io)
- **Scope**: Container registries
- **Vulnerabilities**: CVEs
- **Strengths**: Registry-level scanning
- **Limitations**: Requires registry integration
- **Cost**: Free
- **Website**: https://github.com/quay/clair

## DAST Tools Overview

### OWASP ZAP
- **Type**: Web application security scanner
- **Coverage**: SQL injection, XSS, CSRF, etc.
- **Strengths**: Free, no subscription, comprehensive
- **Limitations**: Can be noisy, requires tuning
- **Cost**: Free
- **Website**: https://www.zaproxy.org/

### Nuclei
- **Type**: Template-based vulnerability scanner
- **Coverage**: Fast reconnaissance + scanning
- **Strengths**: Community templates, flexible
- **Limitations**: Requires templates
- **Cost**: Free / Nuclei Cloud (subscription)
- **Website**: https://github.com/projectdiscovery/nuclei

### Burp Suite
- **Type**: Web security testing platform
- **Coverage**: Comprehensive web testing
- **Strengths**: Professional, feature-rich
- **Limitations**: Commercial, steep learning curve
- **Cost**: Burp Community (free) / Professional
- **Website**: https://portswigger.net/burp

### Nikto
- **Type**: Web server scanner
- **Coverage**: Outdated software, misconfigurations
- **Strengths**: Fast, lightweight
- **Limitations**: Limited to web servers
- **Cost**: Free
- **Website**: https://github.com/sullo/nikto

## IaC Security Tools

### Checkov
- **Type**: Infrastructure-as-Code security scanner
- **Coverage**: Terraform, CloudFormation, Kubernetes, Docker, serverless
- **Strengths**: Multi-framework, customizable checks
- **Cost**: Free / Bridgecrew Pro
- **Website**: https://www.checkov.io/

### tfsec
- **Type**: Terraform security scanner
- **Coverage**: Terraform-specific misconfigurations
- **Strengths**: Fast, focused on Terraform
- **Limitations**: Terraform-only
- **Cost**: Free
- **Website**: https://github.com/aquasecurity/tfsec

### KICS (Keeping Infrastructure as Code Secure)
- **Type**: IaC security scanner
- **Coverage**: Multiple IaC formats
- **Strengths**: Comprehensive rules
- **Cost**: Free
- **Website**: https://kics.io/

### Terrascan
- **Type**: IaC security scanner
- **Coverage**: Multiple IaC and container formats
- **Strengths**: Policy-driven approach
- **Cost**: Free
- **Website**: https://runterrascan.io/

## Standards & Compliance

### OWASP Top 10 (2021)

The 10 most critical web application vulnerabilities:

1. **A01:2021 - Broken Access Control**
   - CWE-639: Authorization Bypass
   - **Scanner Detection**: SAST, DAST
   - **Prevention**: Proper access control checks

2. **A02:2021 - Cryptographic Failures**
   - CWE-327: Weak Encryption
   - **Scanner Detection**: SAST (Semgrep, Bandit)
   - **Prevention**: Use strong algorithms, TLS everywhere

3. **A03:2021 - Injection**
   - CWE-89: SQL Injection
   - **Scanner Detection**: SAST, DAST
   - **Prevention**: Parameterized queries, input validation

4. **A04:2021 - Insecure Design**
   - CWE-1275: Missing Security Control
   - **Scanner Detection**: Architecture review, threat modeling
   - **Prevention**: Secure by design principles

5. **A05:2021 - Security Misconfiguration**
   - CWE-16: Configuration Issues
   - **Scanner Detection**: IaC scanners (Checkov, tfsec)
   - **Prevention**: Secure defaults, hardening

6. **A06:2021 - Vulnerable Components**
   - CWE-1104: Outdated Dependencies
   - **Scanner Detection**: Dependency scanners
   - **Prevention**: Regular updates, supply chain security

7. **A07:2021 - Authentication Failures**
   - CWE-287: Authentication Issues
   - **Scanner Detection**: DAST, code review
   - **Prevention**: Multi-factor auth, session management

8. **A08:2021 - Software/Data Integrity**
   - CWE-345: Supply Chain Attacks
   - **Scanner Detection**: DAST, supply chain tools
   - **Prevention**: Secure CI/CD, signed releases

9. **A09:2021 - Security Logging Failures**
   - CWE-778: Insufficient Logging
   - **Scanner Detection**: Code review
   - **Prevention**: Comprehensive audit logs

10. **A10:2021 - Server-Side Request Forgery (SSRF)**
    - CWE-918: SSRF
    - **Scanner Detection**: SAST, DAST
    - **Prevention**: Input validation, network segmentation

### CWE Top 25

Common Weakness Enumeration - Top 25 software weaknesses:

1. CWE-787: Out-of-bounds Write
2. CWE-79: Cross-site Scripting (XSS)
3. CWE-89: SQL Injection
4. CWE-200: Information Exposure
5. CWE-125: Out-of-bounds Read
6. CWE-690: Unchecked Return Value
7. CWE-252: Unchecked Return Value
8. CWE-434: Unrestricted Upload
9. CWE-611: XML External Entity (XXE)
10. CWE-94: Code Injection

Full list: https://cwe.mitre.org/top25/

### Vulnerability Databases

- **NVD** (nvd.nist.gov): NIST's National Vulnerability Database
- **CVE** (cve.mitre.org): Official CVE list
- **GitHub Security Advisories**: GitHub's curated database
- **Snyk Vulnerability Database**: Snyk's proprietary database
- **OSV** (osv.dev): Open Source Vulnerability database

### CVSS Score Interpretation

Common Vulnerability Scoring System (0.0 - 10.0):

- **9.0-10.0**: CRITICAL - Immediate action required
- **7.0-8.9**: HIGH - Fix within days/week
- **4.0-6.9**: MEDIUM - Fix within month
- **0.1-3.9**: LOW - Fix eventually

### Severity Classifications

Different tools use different severity levels:

- **Trivy**: CRITICAL, HIGH, MEDIUM, LOW, UNKNOWN
- **npm audit**: CRITICAL, HIGH, MODERATE, LOW
- **Semgrep**: ERROR, WARNING
- **Custom**: Can define your own

### Compliance Standards

- **PCI-DSS**: Payment Card Industry (requires vulnerability scanning)
- **HIPAA**: Health Insurance Portability (requires risk assessment)
- **GDPR**: General Data Protection Regulation (requires security measures)
- **SOC 2**: Service Organization Control (requires security testing)
- **ISO 27001**: Information Security Management System

### Security Frameworks

- **NIST Cybersecurity Framework**: https://www.nist.gov/cyberframework
- **OWASP ASVS**: Application Security Verification Standard
- **SANS Secure Coding**: https://www.sans.org/secure-coding/
