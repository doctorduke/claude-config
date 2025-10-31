# GitHub Actions Self-Hosted Runner Installation Guide

**Version:** 1.0.0
**Last Updated:** 2025-10-17
**Target Platform:** Windows + WSL 2.0 / Linux / macOS

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation Methods](#installation-methods)
- [Quick Start](#quick-start)
- [Step-by-Step Installation](#step-by-step-installation)
- [Multi-Runner Setup](#multi-runner-setup)
- [Service Management](#service-management)
- [Validation and Testing](#validation-and-testing)
- [Label Management](#label-management)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [Security Considerations](#security-considerations)

---

## Overview

This guide provides comprehensive instructions for installing and configuring GitHub Actions self-hosted runners on Windows + WSL 2.0, Linux, and macOS systems. The installation uses **native runner binaries** (not Docker containers) and supports running multiple concurrent runners on a single host.

### Key Features

- **Cross-platform support**: WSL 2.0, Ubuntu, Debian, RHEL, macOS
- **Multi-runner capability**: Run 3-5 runners per host with isolated work directories
- **Automated installation**: POSIX-compliant bash scripts
- **Service integration**: systemd support for automatic startup
- **Label management**: Flexible label configuration for workflow targeting
- **Health monitoring**: Comprehensive validation and health check scripts

---

## Prerequisites

### System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **CPU** | 2 cores | 4+ cores |
| **RAM** | 4 GB | 8+ GB |
| **Disk** | 10 GB free | 20+ GB free |
| **OS** | Ubuntu 20.04+ / macOS 12+ | Ubuntu 22.04 / macOS 13+ |

### Required Software

Install the following packages before running the setup scripts:

#### Ubuntu/Debian (WSL or Native)
```bash
sudo apt-get update
sudo apt-get install -y curl jq tar systemd
```

#### RHEL/CentOS/Fedora
```bash
sudo yum install -y curl jq tar systemd
```

#### macOS
```bash
brew install curl jq
```

### Network Requirements

The runner requires **outbound HTTPS access** to the following GitHub endpoints:

- `https://github.com`
- `https://api.github.com`
- `https://ghcr.io`
- `https://objects.githubusercontent.com`
- `https://*.actions.githubusercontent.com`

**Firewall Rules:**
- Outbound HTTPS (port 443) - Required
- No inbound connections needed

**Proxy Configuration:**
If behind a corporate proxy, configure these environment variables:
```bash
export HTTP_PROXY=http://proxy.example.com:8080
export HTTPS_PROXY=http://proxy.example.com:8080
export NO_PROXY=localhost,127.0.0.1
```

### GitHub Requirements

1. **Organization Access**: Admin or Owner permissions on the GitHub organization
2. **Registration Token**: Generate a runner registration token

#### Generate Registration Token

**Option 1: Via GitHub Web UI**
1. Navigate to: `https://github.com/organizations/YOUR_ORG/settings/actions/runners/new`
2. Copy the token from the configuration command

**Option 2: Via GitHub API**
```bash
ORG="your-org"
TOKEN="your-personal-access-token"

curl -X POST \
  -H "Authorization: token $TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/orgs/$ORG/actions/runners/registration-token \
  | jq -r '.token'
```

**Note:** Registration tokens expire after 1 hour.

---

## Installation Methods

### Method 1: Automated Setup (Recommended)

Use the provided `setup-runner.sh` script for automated installation.

### Method 2: Manual Installation

Follow GitHub's official documentation for manual step-by-step installation.

This guide focuses on **Method 1** for consistent, repeatable deployments.

---

## Quick Start

For experienced users, here's the minimal installation command:

```bash
# Clone or download the scripts
cd /path/to/github-act

# Make scripts executable
chmod +x scripts/setup-runner.sh
chmod +x scripts/validate-setup.sh
chmod +x scripts/configure-labels.sh

# Install first runner
./scripts/setup-runner.sh \
  --org "your-org-name" \
  --token "your-registration-token"

# Validate installation
./scripts/validate-setup.sh --runner-id 1
```

---

## Step-by-Step Installation

### Step 1: Prepare Your Environment

1. **Check OS Compatibility**
   ```bash
   # Verify OS
   uname -a

   # For WSL, verify version
   wsl.exe -l -v  # Run from Windows
   ```

2. **Verify Prerequisites**
   ```bash
   # Check required commands
   command -v curl && echo "curl: OK" || echo "curl: MISSING"
   command -v jq && echo "jq: OK" || echo "jq: MISSING"
   command -v tar && echo "tar: OK" || echo "tar: MISSING"
   command -v systemctl && echo "systemd: OK" || echo "systemd: MISSING"
   ```

3. **Check Disk Space**
   ```bash
   df -h ~
   # Ensure at least 10GB free space
   ```

4. **Test GitHub Connectivity**
   ```bash
   curl -s https://api.github.com > /dev/null && echo "GitHub: Reachable" || echo "GitHub: BLOCKED"
   ```

### Step 2: Download Installation Scripts

```bash
# Navigate to your project directory
cd ~

# Clone the repository (if not already done)
git clone https://github.com/your-org/github-act.git
cd github-act

# Or download scripts individually
# wget https://raw.githubusercontent.com/your-org/github-act/main/scripts/setup-runner.sh
# wget https://raw.githubusercontent.com/your-org/github-act/main/scripts/validate-setup.sh
# wget https://raw.githubusercontent.com/your-org/github-act/main/scripts/configure-labels.sh
```

### Step 3: Make Scripts Executable

```bash
chmod +x scripts/setup-runner.sh
chmod +x scripts/validate-setup.sh
chmod +x scripts/configure-labels.sh
```

### Step 4: Generate Registration Token

```bash
# Navigate to GitHub and generate token
# https://github.com/organizations/YOUR_ORG/settings/actions/runners/new

# Or use API
export ORG="your-org"
export PAT="ghp_your_personal_access_token"

RUNNER_TOKEN=$(curl -s -X POST \
  -H "Authorization: token $PAT" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/orgs/$ORG/actions/runners/registration-token \
  | jq -r '.token')

echo "Registration token: $RUNNER_TOKEN"
```

### Step 5: Install First Runner

```bash
./scripts/setup-runner.sh \
  --org "your-org" \
  --token "$RUNNER_TOKEN" \
  --runner-id 1 \
  --name "runner-wsl-prod-1" \
  --labels "self-hosted,linux,x64,ai-agent,wsl-ubuntu-22.04"
```

**Expected Output:**
```
===================================================================
GitHub Actions Self-Hosted Runner Setup v1.0.0
===================================================================
[2025-10-17 10:00:00] Platform detected: linux-x64
[2025-10-17 10:00:01] Checking prerequisites...
[2025-10-17 10:00:02] Prerequisites check passed
[2025-10-17 10:00:03] Runner directory: /home/user/actions-runner-1
[2025-10-17 10:00:04] Fetching latest runner version for linux-x64...
[2025-10-17 10:00:05] Latest runner version: 2.311.0
[2025-10-17 10:00:06] Downloading GitHub Actions runner v2.311.0...
[2025-10-17 10:00:15] Downloaded actions-runner-linux-x64-2.311.0.tar.gz
[2025-10-17 10:00:16] Extracting runner...
[2025-10-17 10:00:17] Runner extracted successfully
[2025-10-17 10:00:18] Configuring runner: runner-wsl-prod-1
[INFO] Running configuration...
[2025-10-17 10:00:25] Runner configured successfully
[2025-10-17 10:00:26] Installation validation passed
[2025-10-17 10:00:27] Installing systemd service...
[2025-10-17 10:00:30] Systemd service installed
[2025-10-17 10:00:31] Starting runner service...
[2025-10-17 10:00:33] Runner service started successfully
[2025-10-17 10:00:34] Runner service is running
===================================================================
Runner setup completed successfully!
===================================================================
```

### Step 6: Validate Installation

```bash
./scripts/validate-setup.sh --runner-id 1 --org "your-org"
```

**Expected Output:**
```
===================================================================
GitHub Actions Runner Validation v1.0.0
===================================================================
[PASS] OS: WSL (x86_64)
[PASS] All required commands available
[PASS] System resources checked (Disk: 45GB)
[PASS] All GitHub endpoints reachable
[PASS] Latency to github.com: 23.5ms
[PASS] DNS resolution working

Validating: /home/user/actions-runner-1
-------------------------------------------------------------------
[PASS] Runner installation valid
[PASS] Runner configured: runner-wsl-prod-1
[PASS] Runner credentials present
[PASS] Work directory exists
[PASS] Runner service is active
[PASS] Runner labels: self-hosted,linux,x64,ai-agent,wsl-ubuntu-22.04
[PASS] File permissions are secure

===================================================================
Validation Summary
===================================================================
Total Checks: 15
Passed: 15
Failed: 0
Warnings: 0

All critical checks passed!
```

### Step 7: Verify in GitHub UI

1. Navigate to: `https://github.com/organizations/YOUR_ORG/settings/actions/runners`
2. You should see your runner listed as **"Idle"** (green status)

---

## Multi-Runner Setup

To maximize resource utilization, install 3-5 runners per host.

### Install Additional Runners

```bash
# Runner 2
./scripts/setup-runner.sh \
  --org "your-org" \
  --token "$RUNNER_TOKEN" \
  --runner-id 2 \
  --name "runner-wsl-prod-2"

# Runner 3
./scripts/setup-runner.sh \
  --org "your-org" \
  --token "$RUNNER_TOKEN" \
  --runner-id 3 \
  --name "runner-wsl-prod-3"

# Continue for runners 4 and 5...
```

### Batch Installation Script

Create a helper script for batch installation:

```bash
#!/bin/bash
# install-all-runners.sh

ORG="your-org"
TOKEN="your-registration-token"
NUM_RUNNERS=5

for i in $(seq 1 $NUM_RUNNERS); do
  echo "Installing runner $i..."
  ./scripts/setup-runner.sh \
    --org "$ORG" \
    --token "$TOKEN" \
    --runner-id "$i" \
    --name "runner-wsl-prod-$i"

  echo "Waiting 5 seconds before next installation..."
  sleep 5
done

echo "All runners installed!"
```

### Validate All Runners

```bash
./scripts/validate-setup.sh
# Validates all runners found in ~/actions-runner-*
```

---

## Service Management

### Check Service Status

```bash
# For specific runner
cd ~/actions-runner-1
sudo ./svc.sh status

# Or using systemd
systemctl --user status actions.runner.YOUR_ORG.runner-wsl-prod-1
```

### Start/Stop/Restart Service

```bash
cd ~/actions-runner-1

# Stop
sudo ./svc.sh stop

# Start
sudo ./svc.sh start

# Restart
sudo ./svc.sh stop && sudo ./svc.sh start

# Check status
sudo ./svc.sh status
```

### View Service Logs

```bash
# View logs for specific runner
journalctl -u actions.runner.YOUR_ORG.runner-wsl-prod-1 -f

# View last 100 lines
journalctl -u actions.runner.YOUR_ORG.runner-wsl-prod-1 -n 100

# View logs from today
journalctl -u actions.runner.YOUR_ORG.runner-wsl-prod-1 --since today
```

### Enable Auto-Start on Boot

The service is automatically configured to start on boot when installed via `setup-runner.sh`. Verify with:

```bash
systemctl --user is-enabled actions.runner.YOUR_ORG.runner-wsl-prod-1
```

---

## Label Management

Labels are used to target specific runners in your workflows.

### View Current Labels

```bash
./scripts/configure-labels.sh --runner-id 1 --action list
```

### Validate Labels

```bash
./scripts/configure-labels.sh --runner-id 1 --action validate
```

### Add Custom Labels

**Note:** Label changes require runner reconfiguration.

```bash
./scripts/configure-labels.sh \
  --runner-id 1 \
  --action add \
  --labels "python,docker,gpu"
```

The script will provide instructions for reconfiguration.

### Reset Labels to Preset

```bash
./scripts/configure-labels.sh \
  --runner-id 1 \
  --action reset \
  --preset gpu \
  --org "your-org" \
  --token "$RUNNER_TOKEN"
```

**Available Presets:**
- `default`: self-hosted,linux,x64,ai-agent,wsl-ubuntu-22.04
- `gpu`: self-hosted,linux,x64,gpu,cuda
- `high-memory`: self-hosted,linux,x64,high-memory
- `docker`: self-hosted,linux,x64,docker

### Using Labels in Workflows

```yaml
name: CI Pipeline
on: [push]

jobs:
  build:
    runs-on: [self-hosted, linux, x64, ai-agent]
    steps:
      - uses: actions/checkout@v3
      - name: Build
        run: ./build.sh
```

---

## Validation and Testing

### Comprehensive Validation

```bash
# Validate all runners
./scripts/validate-setup.sh

# Validate specific runner with GitHub API
./scripts/validate-setup.sh \
  --runner-id 1 \
  --org "your-org" \
  --token "$PAT"

# Validate and attempt fixes
./scripts/validate-setup.sh --runner-id 1 --fix

# JSON output for automation
./scripts/validate-setup.sh --runner-id 1 --json
```

### Test Workflow Execution

Create a test workflow to verify runner functionality:

```yaml
# .github/workflows/test-runner.yml
name: Test Self-Hosted Runner
on:
  workflow_dispatch:

jobs:
  test:
    runs-on: [self-hosted, linux, x64, ai-agent]
    steps:
      - name: Check Runner Info
        run: |
          echo "Runner name: $RUNNER_NAME"
          echo "Runner OS: $RUNNER_OS"
          echo "Runner arch: $RUNNER_ARCH"
          uname -a
          df -h
          free -h

      - name: Test Git Clone
        uses: actions/checkout@v3

      - name: Test Network
        run: curl -s https://api.github.com/zen
```

---

## Troubleshooting

### Runner Not Appearing in GitHub

**Symptoms:**
- Runner installed but not visible in GitHub UI
- Configuration succeeded but status shows offline

**Solutions:**
1. Check service status:
   ```bash
   cd ~/actions-runner-1
   sudo ./svc.sh status
   ```

2. Verify credentials:
   ```bash
   cat ~/actions-runner-1/.credentials
   # File should exist and contain OAuth token
   ```

3. Check logs:
   ```bash
   journalctl -u actions.runner.YOUR_ORG.runner-wsl-prod-1 -n 50
   ```

4. Test connectivity:
   ```bash
   curl -s https://api.github.com
   ```

### Service Fails to Start

**Symptoms:**
- `svc.sh start` returns error
- Service status shows "failed" or "inactive"

**Solutions:**
1. Check permissions:
   ```bash
   ls -la ~/actions-runner-1/
   # All files should be owned by current user
   ```

2. Verify systemd service file:
   ```bash
   systemctl --user cat actions.runner.YOUR_ORG.runner-wsl-prod-1
   ```

3. Reinstall service:
   ```bash
   cd ~/actions-runner-1
   sudo ./svc.sh uninstall
   sudo ./svc.sh install
   sudo ./svc.sh start
   ```

### Runner Gets Disconnected

**Symptoms:**
- Runner shows "Offline" in GitHub UI
- Workflows queue but don't execute

**Solutions:**
1. Check network connectivity:
   ```bash
   ./scripts/validate-setup.sh --runner-id 1
   ```

2. Restart service:
   ```bash
   cd ~/actions-runner-1
   sudo ./svc.sh restart
   ```

3. Check for runner updates:
   ```bash
   ./scripts/setup-runner.sh \
     --org "your-org" \
     --token "$RUNNER_TOKEN" \
     --runner-id 1 \
     --update
   ```

### Disk Space Issues

**Symptoms:**
- Jobs fail with "No space left on device"
- Work directory growing large

**Solutions:**
1. Clean work directories:
   ```bash
   cd ~/actions-runner-1/_work
   rm -rf *
   ```

2. Set up automatic cleanup:
   ```bash
   # Add to crontab
   0 2 * * * find ~/actions-runner-*/_work -mtime +7 -delete
   ```

### Permission Denied Errors

**Symptoms:**
- Service installation fails
- Configuration fails with permission errors

**Solutions:**
1. Ensure not running as root:
   ```bash
   whoami  # Should NOT be root
   ```

2. Check sudo access:
   ```bash
   sudo -v
   ```

3. Fix file permissions:
   ```bash
   chmod 700 ~/actions-runner-1
   chmod 600 ~/actions-runner-1/.credentials
   ```

---

## Best Practices

### Security

1. **Never run runners as root**
   - Always use a dedicated non-root user
   - Runners should have minimal privileges

2. **Rotate registration tokens regularly**
   - Tokens expire after 1 hour
   - Generate new tokens for each installation

3. **Secure credential files**
   ```bash
   chmod 600 ~/actions-runner-*/.credentials
   ```

4. **Use runner groups for access control**
   - Limit which repositories can use runners
   - Implement least-privilege access

### Performance

1. **Allocate sufficient resources**
   - 2GB RAM minimum per runner
   - 10GB disk space minimum per runner

2. **Use separate work directories**
   - Each runner gets isolated workspace
   - Prevents job interference

3. **Monitor resource usage**
   ```bash
   # Check CPU and memory
   top -u $(whoami)

   # Check disk usage
   du -sh ~/actions-runner-*/_work
   ```

### Maintenance

1. **Regular updates**
   - Update runners monthly or when GitHub releases security patches
   - Use `--update` flag with setup script

2. **Log rotation**
   - Configure systemd journal rotation
   - Archive old logs

3. **Health checks**
   - Run validation script weekly
   - Set up monitoring alerts

4. **Backup configuration**
   ```bash
   # Backup runner configs
   tar -czf runner-configs-$(date +%Y%m%d).tar.gz \
     ~/actions-runner-*/.runner \
     ~/actions-runner-*/.credentials
   ```

### Scalability

1. **Start with 3-5 runners per host**
   - Monitor job queue length
   - Scale horizontally (more hosts) vs vertically (more runners)

2. **Use runner groups**
   - Separate dev/staging/production runners
   - Different runner pools for different workload types

3. **Implement auto-scaling** (future enhancement)
   - Monitor queue depth
   - Provision runners on-demand

---

## Security Considerations

### Token Security

1. **Registration tokens are short-lived** (1 hour)
   - Generate fresh tokens for each installation
   - Never commit tokens to version control

2. **Personal Access Tokens (PATs)**
   - Use fine-grained PATs with minimal scopes
   - Required scopes for runner management:
     - `admin:org` (for organization runners)
     - `repo` (for repository runners)

3. **Credential storage**
   - Credentials stored in `~/.runner/.credentials`
   - File permissions: 600 (owner read/write only)

### Network Security

1. **Outbound-only communication**
   - Runners initiate connections to GitHub
   - No inbound ports required

2. **TLS/SSL verification**
   - All communication over HTTPS
   - Certificate validation enabled by default

3. **Proxy support**
   - Configure HTTP_PROXY/HTTPS_PROXY for corporate environments
   - Ensure proxy allows GitHub domains

### Workflow Security

1. **Restrict runner access**
   - Use runner groups to limit repository access
   - Don't allow public repositories on self-hosted runners

2. **Secure secrets**
   - Store sensitive data in GitHub Secrets
   - Secrets are not logged or exposed to console

3. **Review workflows**
   - Audit workflow definitions before execution
   - Watch for malicious code in pull requests

### Compliance

1. **Audit logging**
   - All runner activity logged to systemd journal
   - Retain logs per compliance requirements

2. **Access control**
   - Document who has runner admin access
   - Implement change management processes

3. **Regular security reviews**
   - Quarterly security audits
   - Update runners promptly for security patches

---

## Additional Resources

### GitHub Documentation
- [About self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners)
- [Adding self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners/adding-self-hosted-runners)
- [Managing runner groups](https://docs.github.com/en/actions/hosting-your-own-runners/managing-access-to-self-hosted-runners-using-groups)
- [Security hardening](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)

### Script Reference
- **setup-runner.sh**: Automated runner installation and configuration
- **validate-setup.sh**: Comprehensive health checks and validation
- **configure-labels.sh**: Label management and reconfiguration

### Support
For issues or questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review GitHub Actions documentation
3. Contact your organization's DevOps team

---

**Document Version:** 1.0.0
**Last Updated:** 2025-10-17
**Next Review:** After Wave 2 completion
