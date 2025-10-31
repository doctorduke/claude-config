# GitHub Actions Runner Network Requirements

**Version:** 1.0.0
**Last Updated:** 2025-10-17
**Platform:** Windows+WSL, Linux, macOS

## Table of Contents

- [Overview](#overview)
- [Network Architecture](#network-architecture)
- [Required Connectivity](#required-connectivity)
- [Firewall Rules](#firewall-rules)
- [Proxy Configuration](#proxy-configuration)
- [DNS Requirements](#dns-requirements)
- [TLS/SSL Requirements](#tls-ssl-requirements)
- [Bandwidth Requirements](#bandwidth-requirements)
- [Monitoring and Validation](#monitoring-and-validation)

---

## Overview

Self-hosted GitHub Actions runners require **outbound HTTPS connectivity only**. No inbound connections are required, making them suitable for deployment behind corporate firewalls and proxies.

### Key Principles

- **Outbound Only**: Runners initiate all connections to GitHub
- **HTTPS Only**: All communication over port 443 (TLS encrypted)
- **Proxy Friendly**: Full support for HTTP/HTTPS proxies
- **No Inbound**: No ports need to be opened for inbound traffic
- **Stateless**: Runners poll GitHub for jobs, no persistent connections required

---

## Network Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    GitHub Cloud                         │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │
│  │   API       │  │  Pipelines  │  │   Objects   │   │
│  │ github.com  │  │  .actions.. │  │     CDN     │   │
│  └─────────────┘  └─────────────┘  └─────────────┘   │
└─────────────────────────────────────────────────────────┘
                           ▲
                           │ HTTPS (443)
                           │ Outbound Only
                           │
┌──────────────────────────┼──────────────────────────────┐
│                          │                              │
│                   Corporate Network                     │
│                          │                              │
│  ┌──────────────────┐    │    ┌──────────────────┐    │
│  │  Firewall/Proxy  │◄───┘    │   DNS Server     │    │
│  └──────────────────┘         └──────────────────┘    │
│           │                                             │
│           ▼                                             │
│  ┌─────────────────────────────────────────┐          │
│  │  Self-Hosted Runner (Windows+WSL)       │          │
│  │                                          │          │
│  │  - GitHub Actions Runner Service        │          │
│  │  - Runner Worker Processes              │          │
│  │  - Job Execution Environment            │          │
│  └─────────────────────────────────────────┘          │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Connection Flow

1. **Runner Registration**: Runner authenticates with GitHub API using registration token
2. **Job Polling**: Runner continuously polls `pipelines.actions.githubusercontent.com` for available jobs
3. **Job Execution**: Runner downloads job definition and executes workflow steps
4. **Artifact Upload**: Runner uploads logs, artifacts to `results.actions.githubusercontent.com`
5. **Status Updates**: Runner sends job status updates via GitHub API

---

## Required Connectivity

### Critical GitHub Endpoints

These endpoints are **required** for runner operation:

| Endpoint | Purpose | Test Command |
|----------|---------|--------------|
| `https://github.com` | Main site, runner downloads | `curl -I https://github.com` |
| `https://api.github.com` | GitHub API for authentication | `curl -I https://api.github.com` |
| `https://pipelines.actions.githubusercontent.com` | Job polling and orchestration | `curl -I https://pipelines.actions.githubusercontent.com` |
| `https://results.actions.githubusercontent.com` | Log and artifact upload | `curl -I https://results.actions.githubusercontent.com` |
| `https://objects.githubusercontent.com` | Actions cache and artifacts | `curl -I https://objects.githubusercontent.com` |

### Additional GitHub Endpoints

These endpoints are used for additional functionality:

| Endpoint | Purpose | Required |
|----------|---------|----------|
| `https://github.com/actions/runner/releases` | Runner binary updates | Yes |
| `https://raw.githubusercontent.com` | Raw file access | Optional |
| `https://avatars.githubusercontent.com` | User avatars | No |
| `https://codeload.github.com` | Repository archives | Optional |
| `https://*.pkg.github.com` | GitHub Packages | Optional |

### Package Registry Endpoints

Required if workflows use package managers:

| Registry | Endpoint | Purpose |
|----------|----------|---------|
| npm | `https://registry.npmjs.org` | Node.js packages |
| PyPI | `https://pypi.org` | Python packages |
| RubyGems | `https://rubygems.org` | Ruby packages |
| Docker Hub | `https://hub.docker.com` | Container images |
| Maven Central | `https://repo1.maven.org` | Java packages |

### IP Address Ranges

GitHub uses dynamic IP addresses. Use DNS-based firewall rules where possible.

For IP-based firewalls, consult the GitHub Meta API:
```bash
curl https://api.github.com/meta | jq '.actions'
```

**Note**: IP ranges change frequently. DNS-based rules are strongly recommended.

---

## Firewall Rules

### Outbound Rules (Required)

#### Windows Firewall (PowerShell)

```powershell
# Allow outbound HTTPS for runner
New-NetFirewallRule -DisplayName "GitHub Actions Runner - HTTPS" `
    -Direction Outbound `
    -Action Allow `
    -Protocol TCP `
    -RemotePort 443 `
    -Program "C:\actions-runner\run.exe"

# Allow outbound DNS
New-NetFirewallRule -DisplayName "GitHub Actions Runner - DNS" `
    -Direction Outbound `
    -Action Allow `
    -Protocol UDP `
    -RemotePort 53
```

#### Linux iptables

```bash
# Allow outbound HTTPS
iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT

# Allow outbound DNS
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
```

#### UFW (Ubuntu/Debian)

```bash
# Allow outbound HTTPS
ufw allow out 443/tcp

# Allow outbound DNS
ufw allow out 53/udp
ufw allow out 53/tcp
```

### Inbound Rules

**No inbound rules required** for runner operation. The runner only makes outbound connections.

### Corporate Firewall Requirements

Provide this information to your network team:

```
REQUIRED OUTBOUND ACCESS:
- Protocol: HTTPS (TCP/443)
- Destination: *.github.com, *.githubusercontent.com, *.actions.githubusercontent.com
- Method: DNS-based filtering preferred
- Direction: Outbound only
- Source: Runner host IP(s)

DNS REQUIREMENTS:
- Protocol: DNS (UDP/53, TCP/53)
- Destination: Corporate DNS or 8.8.8.8, 1.1.1.1
- Method: Standard DNS resolution
```

---

## Proxy Configuration

### Proxy Environment Variables

The runner respects standard proxy environment variables:

```bash
# HTTP proxy (used for HTTP and HTTPS if HTTPS_PROXY not set)
export HTTP_PROXY="http://proxy.example.com:8080"
export http_proxy="http://proxy.example.com:8080"

# HTTPS proxy (takes precedence for HTTPS connections)
export HTTPS_PROXY="http://proxy.example.com:8080"
export https_proxy="http://proxy.example.com:8080"

# No proxy exceptions (comma-separated)
export NO_PROXY="localhost,127.0.0.1,.local"
export no_proxy="localhost,127.0.0.1,.local"
```

### Proxy Authentication

For authenticated proxies:

```bash
# With username and password
export HTTPS_PROXY="http://username:password@proxy.example.com:8080"

# URL-encoded special characters
export HTTPS_PROXY="http://user%40name:p%40ssword@proxy.example.com:8080"
```

### Runner Configuration with Proxy

#### Option 1: Environment Variables (Recommended)

Add to runner service configuration:

**systemd (Linux/WSL):**
```ini
# /etc/systemd/system/actions.runner.service
[Service]
Environment="HTTPS_PROXY=http://proxy.example.com:8080"
Environment="NO_PROXY=localhost,127.0.0.1"
```

**Windows Service:**
```cmd
# Set before starting runner service
setx HTTPS_PROXY "http://proxy.example.com:8080" /M
```

#### Option 2: Runner Configuration File

Create `.proxyconfig` in runner directory:

```bash
# .proxyconfig
PROXY_URL=http://proxy.example.com:8080
PROXY_USERNAME=username
PROXY_PASSWORD=password
NO_PROXY=localhost,127.0.0.1
```

#### Option 3: System-Wide Proxy

**WSL/Ubuntu:**
```bash
# /etc/environment
HTTP_PROXY="http://proxy.example.com:8080"
HTTPS_PROXY="http://proxy.example.com:8080"
NO_PROXY="localhost,127.0.0.1"
```

**Windows:**
```powershell
# System proxy settings
netsh winhttp set proxy proxy-server="http=proxy.example.com:8080;https=proxy.example.com:8080" bypass-list="localhost;127.0.0.1"
```

### Proxy Testing

Test proxy connectivity:

```bash
# Test HTTPS through proxy
curl -x http://proxy.example.com:8080 https://api.github.com

# Test with authentication
curl -x http://user:pass@proxy.example.com:8080 https://api.github.com

# Test proxy bypass (NO_PROXY)
export NO_PROXY="localhost"
curl https://localhost:8080  # Should bypass proxy
```

### Proxy Troubleshooting

Common proxy issues:

1. **Authentication Failures**
   - Verify credentials are URL-encoded
   - Check proxy supports HTTPS CONNECT method
   - Verify proxy allows GitHub domains

2. **SSL/TLS Issues**
   - Check if proxy performs SSL inspection
   - Install proxy's CA certificate if needed
   - Use `curl -k` to test (insecure, for debugging only)

3. **Connection Timeouts**
   - Verify proxy is reachable: `nc -zv proxy.example.com 8080`
   - Check proxy timeout settings
   - Increase runner timeout values

---

## DNS Requirements

### DNS Resolution

Runners require reliable DNS resolution for GitHub endpoints:

```bash
# Required domains to resolve
github.com
api.github.com
*.actions.githubusercontent.com
*.githubusercontent.com
```

### DNS Servers

#### Recommended DNS Servers

1. **Corporate DNS** (Primary)
   - Use corporate DNS for internal name resolution
   - Ensure it can resolve external GitHub domains

2. **Public DNS** (Fallback)
   - Google DNS: `8.8.8.8`, `8.8.4.4`
   - Cloudflare DNS: `1.1.1.1`, `1.0.0.1`
   - Quad9 DNS: `9.9.9.9`, `149.112.112.112`

#### WSL DNS Configuration

**WSL 2 (Automatic):**
```bash
# WSL 2 inherits Windows DNS by default
cat /etc/resolv.conf
```

**WSL 2 (Manual Override):**
```bash
# Disable auto-generation
sudo tee /etc/wsl.conf > /dev/null <<'EOF'
[network]
generateResolvConf = false
EOF

# Set custom DNS
sudo tee /etc/resolv.conf > /dev/null <<'EOF'
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF

# Restart WSL
wsl.exe --shutdown
```

**WSL 1:**
```bash
# Manually configure /etc/resolv.conf
sudo tee /etc/resolv.conf > /dev/null <<'EOF'
nameserver 192.168.1.1
nameserver 8.8.8.8
EOF
```

#### Linux DNS Configuration

**systemd-resolved (Ubuntu 18.04+):**
```bash
# Check current DNS
resolvectl status

# Set custom DNS
sudo tee /etc/systemd/resolved.conf > /dev/null <<'EOF'
[Resolve]
DNS=8.8.8.8 1.1.1.1
FallbackDNS=8.8.4.4 1.0.0.1
EOF

sudo systemctl restart systemd-resolved
```

**Traditional resolv.conf:**
```bash
sudo tee /etc/resolv.conf > /dev/null <<'EOF'
nameserver 8.8.8.8
nameserver 1.1.1.1
options timeout:2
options attempts:3
EOF
```

### DNS Testing

```bash
# Test DNS resolution
nslookup github.com
nslookup api.github.com
nslookup pipelines.actions.githubusercontent.com

# Test with specific DNS server
nslookup github.com 8.8.8.8

# Detailed DNS query
dig github.com A
dig +trace github.com

# Test DNS performance
time dig github.com
```

### DNS Caching

Optimize DNS performance with local caching:

**systemd-resolved (Ubuntu):**
```bash
# Check cache statistics
resolvectl statistics

# Flush DNS cache
resolvectl flush-caches
```

**dnsmasq (Alternative):**
```bash
# Install dnsmasq
sudo apt-get install dnsmasq

# Configure
sudo tee -a /etc/dnsmasq.conf > /dev/null <<'EOF'
cache-size=1000
strict-order
EOF

sudo systemctl restart dnsmasq
```

---

## TLS/SSL Requirements

### TLS Version

- **Minimum**: TLS 1.2
- **Recommended**: TLS 1.3
- **Ciphers**: Modern cipher suites only

### Certificate Validation

Runners validate SSL certificates by default:

```bash
# Test certificate validation
curl -v https://api.github.com 2>&1 | grep -i "ssl\|tls\|certificate"

# Check certificate chain
openssl s_client -connect api.github.com:443 -showcerts
```

### Certificate Authority (CA) Bundles

Ensure CA certificates are up to date:

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install ca-certificates
sudo update-ca-certificates
```

**RHEL/CentOS:**
```bash
sudo yum update ca-certificates
```

**Windows (WSL uses Windows certificates):**
```powershell
# Update Windows root certificates
certutil -generateSSTFromWU roots.sst
```

### Corporate CA Certificates

If your proxy uses SSL inspection, install corporate CA:

**Ubuntu/Debian:**
```bash
# Copy corporate CA certificate
sudo cp corporate-ca.crt /usr/local/share/ca-certificates/

# Update CA bundle
sudo update-ca-certificates
```

**RHEL/CentOS:**
```bash
sudo cp corporate-ca.crt /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust
```

### TLS Troubleshooting

```bash
# Check TLS handshake
openssl s_client -connect api.github.com:443 -tls1_2

# Test with specific cipher
openssl s_client -connect api.github.com:443 -cipher 'ECDHE-RSA-AES256-GCM-SHA384'

# View certificate details
openssl s_client -connect api.github.com:443 -showcerts 2>/dev/null | \
  openssl x509 -noout -text | grep -E "Subject:|Issuer:|Not"
```

---

## Bandwidth Requirements

### Minimum Bandwidth

- **Download**: 10 Mbps minimum, 50+ Mbps recommended
- **Upload**: 5 Mbps minimum, 20+ Mbps recommended
- **Latency**: <300ms to GitHub endpoints (100ms ideal)

### Bandwidth Usage Patterns

| Activity | Typical Usage | Notes |
|----------|---------------|-------|
| Runner Registration | <1 MB | One-time per registration |
| Job Polling | <10 KB/poll | Every 5-10 seconds |
| Workflow Download | 1-10 MB | Per job |
| Log Upload | 1-50 MB | Per job, depends on verbosity |
| Artifact Upload | Variable | User-defined, can be GBs |
| Cache Upload/Download | 100 MB - 10 GB | Dependency caches |
| Container Image Pull | 100 MB - 5 GB | If using containers |

### Bandwidth Optimization

1. **Use Actions Cache**
   ```yaml
   - uses: actions/cache@v3
     with:
       path: ~/.npm
       key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
   ```

2. **Minimize Log Output**
   - Reduce verbosity in builds
   - Use `::group::` to collapse logs
   - Limit debug output

3. **Optimize Artifacts**
   - Compress before upload
   - Use retention policies
   - Upload only necessary files

4. **Local Package Mirrors** (Optional)
   - npm: Verdaccio, Nexus
   - PyPI: devpi, Nexus
   - Docker: Harbor, Registry

### Network Performance Testing

```bash
# Test download speed
curl -o /dev/null https://github.com/actions/runner/releases/download/v2.300.0/actions-runner-linux-x64-2.300.0.tar.gz

# Test upload speed (requires authenticated API)
dd if=/dev/zero bs=1M count=10 | \
  curl -X POST -H "Authorization: token $GITHUB_TOKEN" \
  --data-binary @- https://api.github.com/repos/test/test/releases

# Measure latency
for i in {1..10}; do
  curl -o /dev/null -s -w "%{time_total}\n" https://api.github.com
done | awk '{sum+=$1} END {print "Average: " sum/NR " seconds"}'
```

---

## Monitoring and Validation

### Connectivity Validation Script

Use the provided `scripts/test-connectivity.sh`:

```bash
# Run basic connectivity test
./scripts/test-connectivity.sh

# Run with JSON output
./scripts/test-connectivity.sh --format json

# Continuous monitoring
./scripts/test-connectivity.sh --continuous --interval 300
```

### Monitoring Checklist

- [ ] DNS resolution successful for all GitHub domains
- [ ] HTTPS connectivity to all critical endpoints
- [ ] TLS certificate validation passing
- [ ] Latency to `api.github.com` <100ms (optimal) or <300ms (acceptable)
- [ ] Proxy configuration correct (if applicable)
- [ ] No firewall blocks on outbound port 443
- [ ] Runner registration API accessible
- [ ] Package registries accessible (if needed)

### Continuous Monitoring

#### Prometheus Metrics (Example)

```yaml
# prometheus-config.yml
scrape_configs:
  - job_name: 'github-runner-connectivity'
    static_configs:
      - targets: ['localhost:9090']
    metrics_path: '/metrics'
    scrape_interval: 60s
```

#### Nagios/Icinga Checks

```bash
# /usr/lib/nagios/plugins/check_github_connectivity.sh
#!/bin/bash
if curl -sf --max-time 10 https://api.github.com > /dev/null; then
  echo "OK - GitHub API accessible"
  exit 0
else
  echo "CRITICAL - Cannot reach GitHub API"
  exit 2
fi
```

#### Health Check Integration

```bash
# Add to runner health check
if ! curl -sf --max-time 5 https://api.github.com > /dev/null; then
  logger "GitHub connectivity lost"
  # Trigger alert or remediation
fi
```

### Network Diagnostic Commands

```bash
# Complete diagnostic suite
# 1. DNS resolution
dig github.com api.github.com pipelines.actions.githubusercontent.com

# 2. TCP connectivity
nc -zv github.com 443
nc -zv api.github.com 443

# 3. HTTPS validation
curl -Iv https://api.github.com

# 4. Trace route (if permitted)
traceroute -T -p 443 github.com

# 5. Packet capture (debugging only)
sudo tcpdump -i any -nn port 443 and host api.github.com

# 6. TLS handshake
openssl s_client -connect api.github.com:443 -brief

# 7. Proxy test
curl -x $HTTPS_PROXY -Iv https://api.github.com
```

---

## WSL-Specific Networking

### WSL Network Modes

**WSL 2 (Default - NAT Mode):**
- Automatic DNS from Windows
- Shared network with Windows
- NAT for outbound connections
- May require firewall rules on Windows

**WSL 2 (Mirrored Mode - Windows 11 23H2+):**
```ini
# .wslconfig (in Windows user home)
[wsl2]
networkingMode=mirrored
```

### WSL Networking Issues

#### Issue 1: DNS Resolution Fails

**Solution:**
```bash
# Disable auto-generated resolv.conf
sudo tee /etc/wsl.conf > /dev/null <<'EOF'
[network]
generateResolvConf = false
EOF

# Set static DNS
sudo tee /etc/resolv.conf > /dev/null <<'EOF'
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF

# Make immutable
sudo chattr +i /etc/resolv.conf

# Restart WSL
wsl.exe --shutdown
```

#### Issue 2: VPN Interference

**Solution:**
```bash
# Check VPN adapter
ip link show

# If VPN blocks connectivity, use Windows host as proxy
export HTTPS_PROXY="http://$(grep nameserver /etc/resolv.conf | awk '{print $2}'):8888"
```

#### Issue 3: Firewall Blocks WSL

**Solution (Windows PowerShell as Admin):**
```powershell
# Allow WSL through Windows Firewall
New-NetFirewallRule -DisplayName "WSL GitHub Runner" `
    -Direction Outbound `
    -Action Allow `
    -Protocol TCP `
    -RemotePort 443

# Check WSL adapter
Get-NetAdapter | Where-Object {$_.Name -like "*WSL*"}
```

### WSL Network Testing

```bash
# Test from WSL
curl -I https://api.github.com

# Test from Windows (PowerShell)
Invoke-WebRequest -Uri https://api.github.com -UseBasicParsing

# Compare Windows vs WSL
echo "Windows IP:" && powershell.exe -c "(Invoke-WebRequest ifconfig.me).Content"
echo "WSL IP:" && curl -s ifconfig.me

# Check WSL route
ip route show
```

---

## Quick Reference

### Essential Commands

```bash
# Test connectivity
./scripts/test-connectivity.sh

# Configure proxy
export HTTPS_PROXY="http://proxy:8080"

# Test DNS
dig github.com

# Test HTTPS
curl -Iv https://api.github.com

# Check latency
ping -c 5 github.com
```

### Required Endpoints Summary

```
✓ https://github.com
✓ https://api.github.com
✓ https://pipelines.actions.githubusercontent.com
✓ https://results.actions.githubusercontent.com
✓ https://objects.githubusercontent.com
```

### Network Troubleshooting Flowchart

```
Connection Issue
    │
    ├─→ DNS Resolution?
    │   ├─→ No → Check /etc/resolv.conf, test with 8.8.8.8
    │   └─→ Yes → Continue
    │
    ├─→ TCP Connection?
    │   ├─→ No → Check firewall, test with nc -zv github.com 443
    │   └─→ Yes → Continue
    │
    ├─→ TLS Handshake?
    │   ├─→ No → Check CA certificates, SSL inspection
    │   └─→ Yes → Continue
    │
    ├─→ HTTP Response?
    │   ├─→ No → Check proxy, authentication
    │   └─→ Yes → Connection OK
    │
    └─→ High Latency?
        └─→ Yes → Check network path, bandwidth
```

---

## Support and Resources

### Documentation
- [GitHub Actions Network Documentation](https://docs.github.com/actions)
- [WSL Networking Guide](https://docs.microsoft.com/windows/wsl/networking)
- [Proxy Configuration Guide](../config/proxy-configuration.sh)

### Troubleshooting
- [Network Troubleshooting Guide](../docs/network-troubleshooting.md)
- [Runner Setup Guide](../docs/setup-guide.md)

### Scripts
- `scripts/test-connectivity.sh` - Network validation
- `config/proxy-configuration.sh` - Proxy setup automation

---

**Document Version:** 1.0.0
**Maintained By:** Network Engineering Team
**Last Review:** 2025-10-17
