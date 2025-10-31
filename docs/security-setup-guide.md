# Security Setup Guide for Self-Hosted GitHub Actions Runners

## Table of Contents

1. [Overview](#overview)
2. [Security Architecture](#security-architecture)
3. [Prerequisites](#prerequisites)
4. [Initial Setup](#initial-setup)
5. [PAT Configuration](#pat-configuration)
6. [Secrets Management](#secrets-management)
7. [Token Rotation](#token-rotation)
8. [Security Validations](#security-validations)
9. [GITHUB_TOKEN vs PAT Decision Guide](#github_token-vs-pat-decision-guide)
10. [Windows + WSL Security Considerations](#windows--wsl-security-considerations)
11. [Monitoring and Audit](#monitoring-and-audit)
12. [Incident Response](#incident-response)
13. [Compliance and Standards](#compliance-and-standards)
14. [Troubleshooting](#troubleshooting)
15. [Security Checklist](#security-checklist)

## Overview

This guide provides comprehensive instructions for setting up secure self-hosted GitHub Actions runners with a zero-trust security model. It implements defense-in-depth strategies, minimal permission principles, and automated security controls.

### Key Security Principles

- **Zero Trust**: Never trust, always verify
- **Least Privilege**: Minimal permissions required for operation
- **Defense in Depth**: Multiple layers of security controls
- **Fail Secure**: Default to secure state on failure
- **Continuous Monitoring**: Real-time security validation

### Security Standards Compliance

- **OWASP Top 10**: Application security best practices
- **SOC2 Type II**: Security and availability controls
- **ISO 27001**: Information security management
- **CIS Benchmarks**: GitHub security configuration

## Security Architecture

```
┌─────────────────────────────────────────────┐
│            GitHub Organization              │
│                                              │
│  ┌──────────────┐    ┌──────────────┐      │
│  │ Org Secrets  │    │Runner Groups │      │
│  │ • AI_API_KEY │    │ • Default    │      │
│  │ • BOT_PAT    │    │ • Production │      │
│  └──────────────┘    └──────────────┘      │
└─────────────────┬───────────────────────────┘
                  │ HTTPS/TLS 1.3
                  │ (Outbound Only)
┌─────────────────┴───────────────────────────┐
│           Self-Hosted Runners               │
│                                              │
│  ┌──────────────────────────────────┐       │
│  │        Windows + WSL 2.0          │       │
│  │  ┌──────────────────────────┐    │       │
│  │  │   Runner Service (WSL)    │    │       │
│  │  │  • Token Authentication   │    │       │
│  │  │  • Encrypted Secrets      │    │       │
│  │  │  • Audit Logging          │    │       │
│  │  └──────────────────────────┘    │       │
│  └──────────────────────────────────┘       │
└──────────────────────────────────────────────┘
```

## Prerequisites

### Required Access

- GitHub organization owner or admin access
- Ability to create and manage Personal Access Tokens
- Access to target Windows + WSL 2.0 infrastructure

### Required Tools

```bash
# Check required tools
for tool in curl jq openssl base64 git; do
    command -v $tool >/dev/null 2>&1 || echo "Missing: $tool"
done
```

### Environment Setup

```bash
# Required environment variables
export GITHUB_ORG="your-organization"
export GITHUB_PAT="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Optional (for automated setup)
export AI_API_KEY="your-ai-api-key"
export BOT_PAT="ghp_yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy"
```

## Initial Setup

### Step 1: Create Security Directory Structure

```bash
# Create required directories
mkdir -p github-act/{scripts,config,docs,logs,audit,reports,.secrets,.state}

# Set appropriate permissions
chmod 700 github-act/.secrets
chmod 700 github-act/audit
```

### Step 2: Install Security Scripts

```bash
# Navigate to project directory
cd github-act

# Make scripts executable
chmod +x scripts/setup-secrets.sh
chmod +x scripts/rotate-tokens.sh

# Verify scripts
./scripts/setup-secrets.sh --help
./scripts/rotate-tokens.sh --help
```

### Step 3: Initialize Security Configuration

```bash
# Copy security policy
cp config/security-policy.json config/security-policy.active.json

# Verify JSON syntax
jq '.' config/security-policy.active.json
```

## PAT Configuration

### Creating a Personal Access Token

#### Classic PAT (Recommended for automation)

1. Navigate to https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Configure token:
   - **Note**: `github-actions-runner-YYYYMMDD`
   - **Expiration**: 90 days
   - **Scopes**:
     - ✅ `repo` (Full control of private repositories)
     - ✅ `workflow` (Update GitHub Action workflows)
     - ⬜ `admin:org` (DO NOT SELECT - excessive permissions)

#### Fine-grained PAT (Enhanced security)

1. Navigate to https://github.com/settings/personal-access-tokens/new
2. Configure token:
   - **Repository access**: Selected repositories
   - **Permissions**:
     - Actions: Read
     - Contents: Read
     - Metadata: Read
     - Pull requests: Write
     - Workflows: Write

### PAT Security Best Practices

```bash
# Never hardcode PATs in scripts
# BAD:
GITHUB_PAT="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# GOOD:
GITHUB_PAT="${GITHUB_PAT:-}"
if [[ -z "$GITHUB_PAT" ]]; then
    read -r -s -p "Enter GitHub PAT: " GITHUB_PAT
    export GITHUB_PAT
fi
```

### Validating PAT Scopes

```bash
# Check PAT authentication
curl -s -H "Authorization: token ${GITHUB_PAT}" \
     https://api.github.com/user | jq '.login'

# Check PAT scopes
curl -s -I -H "Authorization: token ${GITHUB_PAT}" \
     https://api.github.com/rate_limit | \
     grep -i x-oauth-scopes
```

## Secrets Management

### Configure Organization Secrets

```bash
# Run setup script
./scripts/setup-secrets.sh

# The script will:
# 1. Validate environment and PAT
# 2. Check existing secrets
# 3. Configure AI_API_KEY
# 4. Configure BOT_PAT
# 5. Generate runner registration token
# 6. Perform security validations
```

### Manual Secret Configuration

#### Via GitHub UI

1. Navigate to Organization Settings → Secrets and variables → Actions
2. Click "New organization secret"
3. Configure each secret:

**AI_API_KEY**:
- Name: `AI_API_KEY`
- Value: Your AI service API key
- Repository access: All repositories

**BOT_PAT**:
- Name: `BOT_PAT`
- Value: Bot account PAT (with repo, workflow scopes)
- Repository access: All repositories

#### Via GitHub API

```bash
# Get organization public key
curl -s -H "Authorization: token ${GITHUB_PAT}" \
     "https://api.github.com/orgs/${GITHUB_ORG}/actions/secrets/public-key"

# Create secret (requires encryption with public key)
# Use setup-secrets.sh for proper encryption
```

### Secret Access in Workflows

```yaml
# .github/workflows/example.yml
name: Secure Workflow Example
on: [push]

jobs:
  secure-job:
    runs-on: self-hosted
    steps:
      - name: Use organization secret
        env:
          AI_KEY: ${{ secrets.AI_API_KEY }}
        run: |
          # Secret is masked in logs
          echo "Using AI service..."
          # Never echo secrets directly

      - name: Use BOT_PAT for cross-repo access
        env:
          BOT_TOKEN: ${{ secrets.BOT_PAT }}
        run: |
          # Access another repository
          git clone https://x-access-token:${BOT_TOKEN}@github.com/org/other-repo.git
```

## Token Rotation

### Automated Rotation Setup

```bash
# Set up rotation schedule (daily checks)
./scripts/rotate-tokens.sh --schedule

# Verify cron job
crontab -l | grep rotate-tokens

# Check systemd timer (if using systemd)
systemctl status github-token-rotation.timer
```

### Manual Token Rotation

```bash
# Check token status
./scripts/rotate-tokens.sh --check

# Rotate BOT_PAT
./scripts/rotate-tokens.sh --rotate-bot-pat

# After manual PAT rotation
./scripts/rotate-tokens.sh --mark-rotated BOT_PAT

# Rotate runner tokens
./scripts/rotate-tokens.sh --rotate-runner-tokens
```

### Rotation Schedule

| Token Type | Rotation Period | Warning Threshold | Critical Threshold |
|------------|-----------------|-------------------|-------------------|
| BOT_PAT | 90 days | 7 days | 3 days |
| AI_API_KEY | 180 days | 14 days | 7 days |
| Runner Token | 1 hour (auto) | N/A | N/A |

## Security Validations

### Pre-deployment Validation

```bash
# Run comprehensive validation
cat << 'EOF' > validate-security.sh
#!/bin/bash

echo "Security Validation Checklist"
echo "=============================="

# Check PAT configuration
echo -n "✓ PAT authentication: "
curl -s -o /dev/null -w "%{http_code}" \
     -H "Authorization: token ${GITHUB_PAT}" \
     https://api.github.com/user

# Check secrets
echo -n "✓ Organization secrets: "
curl -s -H "Authorization: token ${GITHUB_PAT}" \
     "https://api.github.com/orgs/${GITHUB_ORG}/actions/secrets" | \
     jq '.total_count'

# Check for hardcoded secrets
echo -n "✓ No hardcoded secrets: "
grep -r "ghp_" scripts/ 2>/dev/null && echo "FAIL" || echo "PASS"

# Check file permissions
echo -n "✓ Secure file permissions: "
find .secrets -type f -perm /077 2>/dev/null && echo "FAIL" || echo "PASS"

EOF
chmod +x validate-security.sh
./validate-security.sh
```

### Runtime Validation

```bash
# Monitor runner logs for secrets
tail -f logs/*.log | grep -v "ghp_" | grep -v "github_pat_"

# Check audit logs
tail -f audit/*.log

# Verify no secrets in GitHub Actions logs
# (Check workflow run logs in GitHub UI)
```

## GITHUB_TOKEN vs PAT Decision Guide

### Decision Matrix

| Scenario | Use GITHUB_TOKEN | Use PAT | Reason |
|----------|------------------|---------|---------|
| Access current repository only | ✅ | ❌ | GITHUB_TOKEN is automatically scoped |
| Cross-repository access | ❌ | ✅ | PAT required for org-wide access |
| Bypass branch protection | ❌ | ✅ | GITHUB_TOKEN cannot bypass protection |
| Create/delete repositories | ❌ | ✅ | Requires admin permissions |
| Read public repositories | ✅ | ❌ | GITHUB_TOKEN sufficient |
| Long-running operations | ❌ | ✅ | GITHUB_TOKEN expires with job |
| Forked PR workflows | ❌ | ✅ | GITHUB_TOKEN not available |

### Implementation Examples

#### Using GITHUB_TOKEN (Recommended when possible)

```yaml
# Automatic authentication for current repository
- name: Checkout code
  uses: actions/checkout@v4
  # GITHUB_TOKEN used automatically

- name: Create issue
  env:
    GH_TOKEN: ${{ github.token }}
  run: |
    gh issue create --title "Automated issue" --body "Created by workflow"
```

#### Using PAT (When required)

```yaml
# Cross-repository operations
- name: Access another repository
  env:
    PAT: ${{ secrets.BOT_PAT }}
  run: |
    git clone https://x-access-token:${PAT}@github.com/org/other-repo.git

# Bypass branch protection
- name: Force push to protected branch
  env:
    PAT: ${{ secrets.BOT_PAT }}
  run: |
    git remote set-url origin https://x-access-token:${PAT}@github.com/org/repo.git
    git push --force origin main
```

## Windows + WSL Security Considerations

### WSL 2.0 Security Configuration

```bash
# Check WSL version
wsl --list --verbose

# Ensure WSL 2 is used (better isolation)
wsl --set-version Ubuntu 2

# Configure WSL security settings
cat << 'EOF' > /etc/wsl.conf
[automount]
enabled = true
options = "metadata,umask=077,fmask=077"

[network]
generateResolvConf = true

[interop]
enabled = true
appendWindowsPath = false
EOF
```

### Windows Security Hardening

```powershell
# Enable BitLocker (PowerShell as Admin)
Enable-BitLocker -MountPoint "C:" -EncryptionMethod Aes256 -UsedSpaceOnly

# Enable Windows Defender
Set-MpPreference -DisableRealtimeMonitoring $false

# Disable unnecessary protocols
Disable-NetAdapterBinding -Name "*" -ComponentID ms_netbios
Disable-NetAdapterBinding -Name "*" -ComponentID ms_lltdio

# Enable audit logging
auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
```

### Cross-platform Considerations

```bash
# Path handling
# Always use forward slashes in scripts
SCRIPT_PATH="/mnt/c/github-act/scripts"

# Line endings
# Configure Git for LF line endings
git config --global core.autocrlf input

# File permissions
# Preserve execute bit
git config --global core.filemode true
```

## Monitoring and Audit

### Enable Audit Logging

```bash
# Create audit log rotation
cat << 'EOF' > /etc/logrotate.d/github-audit
/var/log/github-actions-audit.log {
    daily
    rotate 90
    compress
    delaycompress
    notifempty
    create 0600 runner runner
}
EOF

# Monitor audit logs
tail -f audit/token-rotation-audit.log
tail -f audit/secret-setup-audit.log
```

### Security Metrics Dashboard

```bash
# Generate security metrics
cat << 'EOF' > generate-metrics.sh
#!/bin/bash

echo "Security Metrics Dashboard"
echo "========================="
echo ""

# Token age
./scripts/rotate-tokens.sh --check

# Secret count
echo "Organization secrets:"
curl -s -H "Authorization: token ${GITHUB_PAT}" \
     "https://api.github.com/orgs/${GITHUB_ORG}/actions/secrets" | \
     jq '.total_count'

# Runner status
echo "Active runners:"
curl -s -H "Authorization: token ${GITHUB_PAT}" \
     "https://api.github.com/orgs/${GITHUB_ORG}/actions/runners" | \
     jq '.total_count'

# Recent audit events
echo "Recent audit events:"
tail -5 audit/*.log

EOF
chmod +x generate-metrics.sh
```

### Alerting Configuration

```yaml
# .github/workflows/security-alert.yml
name: Security Alert
on:
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours

jobs:
  security-check:
    runs-on: ubuntu-latest
    steps:
      - name: Check token expiration
        run: |
          # Check token age and alert if needed

      - name: Scan for secrets
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./

      - name: Send alert
        if: failure()
        uses: 8398a7/action-slack@v3
        with:
          webhook_url: ${{ secrets.SLACK_WEBHOOK_URL }}
          status: ${{ job.status }}
          text: 'Security alert detected!'
```

## Incident Response

### Secret Leak Response

If a secret is accidentally exposed:

1. **Immediately rotate the affected secret**
   ```bash
   # Rotate the leaked secret
   ./scripts/rotate-tokens.sh --rotate-bot-pat

   # Update in GitHub
   ./scripts/setup-secrets.sh
   ```

2. **Audit access logs**
   ```bash
   # Check for unauthorized usage
   curl -H "Authorization: token ${GITHUB_PAT}" \
        "https://api.github.com/orgs/${GITHUB_ORG}/audit-log"
   ```

3. **Update dependent systems**
   ```bash
   # Restart runners with new token
   sudo systemctl restart github-runner-*.service
   ```

4. **Conduct root cause analysis**
   - Review how the leak occurred
   - Update security controls
   - Document lessons learned

### Unauthorized Access Response

1. **Revoke access immediately**
   ```bash
   # Revoke PAT
   curl -X DELETE \
        -H "Authorization: token ${GITHUB_PAT}" \
        "https://api.github.com/user/tokens/{token_id}"
   ```

2. **Review audit logs**
   ```bash
   # Export audit logs
   curl -H "Authorization: token ${GITHUB_PAT}" \
        "https://api.github.com/orgs/${GITHUB_ORG}/audit-log" > \
        audit-export-$(date +%Y%m%d).json
   ```

3. **Reset all credentials**
   ```bash
   # Rotate all secrets
   ./scripts/rotate-tokens.sh --rotate-bot-pat
   ./scripts/rotate-tokens.sh --rotate-runner-tokens
   ```

## Compliance and Standards

### OWASP Top 10 Controls

| Control | Implementation |
|---------|----------------|
| A01:2021 - Broken Access Control | RBAC, minimal permissions |
| A02:2021 - Cryptographic Failures | TLS 1.3, encrypted secrets |
| A03:2021 - Injection | Input validation, parameterized queries |
| A04:2021 - Insecure Design | Zero-trust architecture |
| A05:2021 - Security Misconfiguration | Security policy enforcement |
| A07:2021 - Identification and Authentication Failures | Token rotation, MFA |

### SOC2 Compliance Checklist

- [x] Access controls implemented
- [x] Encryption at rest and in transit
- [x] Audit logging enabled
- [x] Incident response procedures
- [x] Regular security reviews
- [x] Change management process

### ISO 27001 Controls

- [x] A.9.1.1 - Access control policy
- [x] A.9.1.2 - Access to networks
- [x] A.9.2.1 - User registration
- [x] A.12.1.1 - Operating procedures
- [x] A.12.1.2 - Change management

## Troubleshooting

### Common Issues

#### PAT Authentication Fails

```bash
# Check PAT format
echo "$GITHUB_PAT" | grep -E "^(ghp_[a-zA-Z0-9]{36}|github_pat_)"

# Verify PAT hasn't expired
curl -I -H "Authorization: token ${GITHUB_PAT}" \
     https://api.github.com/rate_limit 2>&1 | \
     grep -i "github-authentication-token-expiration"

# Test with minimal request
curl -H "Authorization: token ${GITHUB_PAT}" \
     https://api.github.com/zen
```

#### Secret Not Available in Workflow

```yaml
# Debug secret availability
- name: Debug secrets
  run: |
    echo "Secret names available:"
    echo "${{ toJSON(secrets) }}" | jq 'keys'

# Check organization secret visibility
# Go to: Org Settings → Secrets → Check "Repository access"
```

#### Token Rotation Fails

```bash
# Check rotation state
cat .state/token-rotation-state.json | jq '.'

# Reset rotation state
echo '{}' > .state/token-rotation-state.json

# Manual rotation
export NEW_BOT_PAT="ghp_new_token_here"
./scripts/setup-secrets.sh
```

### Debug Mode

```bash
# Enable debug output
set -x
export DEBUG=1

# Run scripts with verbose output
bash -x ./scripts/setup-secrets.sh

# Check detailed curl output
curl -v -H "Authorization: token ${GITHUB_PAT}" \
     https://api.github.com/user
```

## Security Checklist

### Pre-deployment

- [ ] PAT created with minimal scopes (repo, workflow only)
- [ ] Organization secrets configured (AI_API_KEY, BOT_PAT)
- [ ] Security policy reviewed and customized
- [ ] Audit logging enabled
- [ ] No hardcoded secrets in scripts
- [ ] File permissions set correctly (.secrets = 700)

### Deployment

- [ ] Secrets successfully configured via API
- [ ] Token rotation scheduled
- [ ] Runner registration tokens generated
- [ ] Security validations passing
- [ ] Audit logs being generated

### Post-deployment

- [ ] Workflows can access secrets
- [ ] Token rotation working
- [ ] No secrets in logs
- [ ] Monitoring active
- [ ] Incident response tested
- [ ] Security report generated

### Ongoing

- [ ] Weekly security validation
- [ ] Monthly token rotation check
- [ ] Quarterly security review
- [ ] Annual compliance audit
- [ ] Continuous monitoring active

---

## Quick Reference

### Essential Commands

```bash
# Setup secrets
./scripts/setup-secrets.sh

# Check token status
./scripts/rotate-tokens.sh --check

# Rotate tokens
./scripts/rotate-tokens.sh --rotate-bot-pat

# Validate security
grep -r "ghp_" scripts/ logs/

# View audit logs
tail -f audit/*.log

# Generate security report
./scripts/rotate-tokens.sh --report
```

### Important URLs

- [GitHub PAT Settings](https://github.com/settings/tokens)
- [Organization Secrets](https://github.com/organizations/{ORG}/settings/secrets/actions)
- [GitHub API Documentation](https://docs.github.com/en/rest)
- [Actions Security Guide](https://docs.github.com/en/actions/security-guides)

### Support Contacts

- Security Team: security-team@company.com
- On-call: Use PagerDuty escalation
- GitHub Support: https://support.github.com

---

*Document Version: 1.0.0*
*Last Updated: 2025-10-17*
*Security Classification: Internal Use Only*