# GitHub Actions Runner Network Troubleshooting Guide

**Version:** 1.0.0
**Last Updated:** 2025-10-17
**Platform:** Windows+WSL, Linux, macOS

## Table of Contents

- [Quick Diagnostic Checklist](#quick-diagnostic-checklist)
- [Common Issues and Solutions](#common-issues-and-solutions)
- [Platform-Specific Issues](#platform-specific-issues)
- [Diagnostic Procedures](#diagnostic-procedures)
- [Advanced Troubleshooting](#advanced-troubleshooting)
- [Escalation Procedures](#escalation-procedures)

---

## Quick Diagnostic Checklist

Run these checks first to identify the issue category:

```bash
# 1. Basic connectivity
curl -I https://api.github.com
# Expected: HTTP/2 200 or 301

# 2. DNS resolution
nslookup github.com
# Expected: Multiple IP addresses returned

# 3. TLS certificate
openssl s_client -connect api.github.com:443 -brief
# Expected: Verification: OK

# 4. Proxy detection
echo $HTTPS_PROXY
# Expected: Empty or valid proxy URL

# 5. Run comprehensive test
./scripts/test-connectivity.sh
# Expected: All tests pass
```

**Quick Reference Decision Tree:**

```
Can't reach GitHub?
├─ DNS fails? → See "DNS Resolution Failures"
├─ TCP fails? → See "Firewall/Network Blocks"
├─ TLS fails? → See "SSL/TLS Certificate Issues"
├─ Slow/timeouts? → See "Performance Issues"
└─ Proxy issues? → See "Proxy Configuration Problems"
```

---

## Common Issues and Solutions

### Issue 1: Cannot Reach GitHub API

**Symptoms:**
```bash
$ curl https://api.github.com
curl: (6) Could not resolve host: api.github.com
# OR
curl: (7) Failed to connect to api.github.com port 443
# OR
curl: (28) Connection timed out
```

**Diagnosis:**

```bash
# Test 1: DNS resolution
dig api.github.com
nslookup api.github.com

# Test 2: Network path
ping -c 5 api.github.com
traceroute api.github.com

# Test 3: Port accessibility
nc -zv api.github.com 443
# OR
telnet api.github.com 443
```

**Solutions:**

#### Solution 1A: DNS Resolution Failure

```bash
# Check current DNS servers
cat /etc/resolv.conf

# Test with Google DNS
dig @8.8.8.8 api.github.com

# If Google DNS works, update system DNS
sudo tee /etc/resolv.conf > /dev/null <<EOF
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF

# Make permanent (Ubuntu/systemd)
sudo tee /etc/systemd/resolved.conf > /dev/null <<EOF
[Resolve]
DNS=8.8.8.8 1.1.1.1
FallbackDNS=8.8.4.4 1.0.0.1
EOF

sudo systemctl restart systemd-resolved
```

#### Solution 1B: Firewall Block

```bash
# Check if firewall is blocking outbound
sudo iptables -L OUTPUT -v -n | grep -i drop

# Temporarily allow HTTPS (testing only)
sudo iptables -I OUTPUT -p tcp --dport 443 -j ACCEPT

# Permanent rule (if test succeeds)
# Ubuntu/UFW
sudo ufw allow out 443/tcp

# RHEL/CentOS
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --reload
```

#### Solution 1C: Corporate Proxy Required

```bash
# Configure proxy
export HTTPS_PROXY="http://proxy.company.com:8080"
export NO_PROXY="localhost,127.0.0.1"

# Test through proxy
curl -x $HTTPS_PROXY https://api.github.com

# If successful, run proxy configuration script
./config/proxy-configuration.sh --configure
```

---

### Issue 2: DNS Resolution Failures

**Symptoms:**
```bash
$ nslookup github.com
;; connection timed out; no servers could be reached
# OR
** server can't find github.com: NXDOMAIN
```

**Diagnosis:**

```bash
# Check DNS configuration
cat /etc/resolv.conf

# Test DNS servers individually
dig @8.8.8.8 github.com        # Google DNS
dig @1.1.1.1 github.com        # Cloudflare DNS
dig @9.9.9.9 github.com        # Quad9 DNS

# Check if DNS port is accessible
sudo tcpdump -i any port 53
```

**Solutions:**

#### Solution 2A: No DNS Servers Configured

```bash
# Add public DNS servers
sudo tee /etc/resolv.conf > /dev/null <<EOF
nameserver 8.8.8.8
nameserver 1.1.1.1
nameserver 8.8.4.4
EOF

# Verify
nslookup github.com
```

#### Solution 2B: Corporate DNS Issues

```bash
# Find your default gateway (often the DNS server)
ip route | grep default

# Try corporate DNS
dig @192.168.1.1 github.com

# If corporate DNS fails, use hybrid approach
sudo tee /etc/resolv.conf > /dev/null <<EOF
nameserver 192.168.1.1
nameserver 8.8.8.8
EOF
```

#### Solution 2C: DNS Blocked by Firewall

```bash
# Test UDP DNS
nc -zu 8.8.8.8 53

# If blocked, check firewall
sudo iptables -L OUTPUT | grep -i 53

# Allow DNS traffic
sudo iptables -I OUTPUT -p udp --dport 53 -j ACCEPT
sudo iptables -I OUTPUT -p tcp --dport 53 -j ACCEPT
```

---

### Issue 3: SSL/TLS Certificate Validation Failures

**Symptoms:**
```bash
$ curl https://api.github.com
curl: (60) SSL certificate problem: certificate has expired
# OR
curl: (60) SSL certificate problem: unable to get local issuer certificate
```

**Diagnosis:**

```bash
# Check certificate
openssl s_client -connect api.github.com:443 -showcerts

# Check certificate expiration
echo | openssl s_client -connect api.github.com:443 2>/dev/null | \
  openssl x509 -noout -dates

# Check CA bundle location
curl-config --ca 2>/dev/null || echo "/etc/ssl/certs/ca-certificates.crt"
```

**Solutions:**

#### Solution 3A: Outdated CA Certificates

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install --reinstall ca-certificates
sudo update-ca-certificates

# RHEL/CentOS
sudo yum reinstall ca-certificates
sudo update-ca-trust

# Verify
curl https://api.github.com
```

#### Solution 3B: Corporate SSL Inspection

If your company uses SSL inspection (man-in-the-middle proxy):

```bash
# Obtain corporate root CA certificate
# (Contact your IT department for this file)

# Install corporate CA (Ubuntu/Debian)
sudo cp corporate-root-ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

# Install corporate CA (RHEL/CentOS)
sudo cp corporate-root-ca.crt /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust

# Verify
curl https://api.github.com
```

#### Solution 3C: Certificate Pinning Issues

```bash
# Test without certificate validation (INSECURE - debugging only)
curl -k https://api.github.com

# If this works, issue is definitely certificate-related
# Check for custom CA bundle
echo $CURL_CA_BUNDLE
echo $SSL_CERT_FILE

# Reset to system default
unset CURL_CA_BUNDLE
unset SSL_CERT_FILE
```

---

### Issue 4: Proxy Configuration Problems

**Symptoms:**
```bash
$ curl https://api.github.com
curl: (56) Proxy CONNECT aborted
# OR
curl: (7) Failed to connect to proxy.company.com port 8080
# OR
curl: (407) Proxy Authentication Required
```

**Diagnosis:**

```bash
# Check proxy variables
env | grep -i proxy

# Test proxy connectivity
nc -zv proxy.company.com 8080

# Test through proxy
curl -x http://proxy.company.com:8080 https://api.github.com

# Test proxy authentication
curl -x http://user:pass@proxy.company.com:8080 https://api.github.com
```

**Solutions:**

#### Solution 4A: Proxy Not Configured

```bash
# Configure proxy manually
export HTTP_PROXY="http://proxy.company.com:8080"
export HTTPS_PROXY="http://proxy.company.com:8080"
export NO_PROXY="localhost,127.0.0.1,.local"

# Test
curl https://api.github.com

# Make permanent
./config/proxy-configuration.sh --configure
```

#### Solution 4B: Proxy Authentication Required

```bash
# Configure with authentication
export HTTPS_PROXY="http://username:password@proxy.company.com:8080"

# URL-encode special characters in password
# @ becomes %40, : becomes %3A, etc.
export HTTPS_PROXY="http://user:p%40ssw0rd@proxy.company.com:8080"

# Test
curl https://api.github.com
```

#### Solution 4C: NO_PROXY Not Configured

```bash
# Add localhost and internal domains to NO_PROXY
export NO_PROXY="localhost,127.0.0.1,::1,.local,.internal,.company.com"

# Test local connections don't use proxy
curl http://localhost:8080

# Make permanent
echo 'export NO_PROXY="localhost,127.0.0.1,.local"' >> ~/.bashrc
source ~/.bashrc
```

---

### Issue 5: Runner Registration Fails

**Symptoms:**
```bash
$ ./config.sh --url https://github.com/org/repo --token ABC123
Failed to connect to GitHub.com:443
# OR
An error occurred: Not Found
# OR
The registration token provided is invalid or has expired
```

**Diagnosis:**

```bash
# Test runner registration endpoint
curl -I https://api.github.com/repos/OWNER/REPO/actions/runners

# Test with authentication
curl -H "Authorization: token YOUR_PAT" \
  https://api.github.com/repos/OWNER/REPO/actions/runners

# Check token validity
curl -H "Authorization: token YOUR_PAT" \
  https://api.github.com/user
```

**Solutions:**

#### Solution 5A: Invalid or Expired Token

1. Generate new registration token:
   - Go to: Settings > Actions > Runners > New self-hosted runner
   - Copy the new token (valid for 1 hour)

2. Use the token immediately:
   ```bash
   ./config.sh --url https://github.com/org/repo --token NEW_TOKEN
   ```

#### Solution 5B: Network Connectivity Issue

```bash
# Run connectivity test
./scripts/test-connectivity.sh

# Check specific endpoints
curl -I https://api.github.com
curl -I https://pipelines.actions.githubusercontent.com

# Test registration with verbose output
./config.sh --url https://github.com/org/repo --token TOKEN --trace
```

#### Solution 5C: Incorrect URL Format

```bash
# Correct formats:
# Repository: https://github.com/owner/repo
# Organization: https://github.com/org
# Enterprise: https://github.enterprise.com/org

# Wrong:
./config.sh --url https://github.com/owner  # Missing repo
./config.sh --url github.com/owner/repo     # Missing https://

# Correct:
./config.sh --url https://github.com/owner/repo --token TOKEN
```

---

### Issue 6: High Latency / Performance Issues

**Symptoms:**
- Slow runner registration
- Job execution delays
- Artifact upload timeouts

**Diagnosis:**

```bash
# Measure latency
for i in {1..10}; do
  curl -o /dev/null -s -w "Connect: %{time_connect}s, Total: %{time_total}s\n" \
    https://api.github.com
done

# Average latency
./scripts/test-connectivity.sh | grep latency

# Check bandwidth
curl -o /dev/null https://github.com/actions/runner/releases/download/v2.300.0/actions-runner-linux-x64-2.300.0.tar.gz \
  --progress-bar 2>&1 | tail -1

# Network path analysis
traceroute api.github.com
mtr -r -c 10 api.github.com
```

**Solutions:**

#### Solution 6A: High Network Latency

```bash
# Check route to GitHub
traceroute api.github.com

# If latency is >300ms consistently:
# 1. Check if traffic is routing through proxy unnecessarily
unset HTTPS_PROXY
curl -o /dev/null -s -w "%{time_total}\n" https://api.github.com

# 2. Check for VPN interference
ip link show | grep -i "tun\|vpn"

# 3. Use DNS server closer to you
# Europe: 9.9.9.9 (Quad9)
# Asia: 1.1.1.1 (Cloudflare)
```

#### Solution 6B: Bandwidth Limitations

```bash
# Optimize runner configuration
# In workflow, use caching:
# - uses: actions/cache@v3
#   with:
#     path: ~/.npm
#     key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}

# Limit artifact size
# - uses: actions/upload-artifact@v3
#   with:
#     retention-days: 5  # Shorter retention

# Use local package mirrors if available
npm config set registry http://local-npm-mirror:4873
```

#### Solution 6C: Connection Pooling / Keep-Alive

```bash
# Configure Git to use keep-alive
git config --global http.postBuffer 524288000
git config --global http.keepAlive true

# Configure curl to reuse connections
echo 'curl-config: use-keep-alive=true' > ~/.curlrc
```

---

## Platform-Specific Issues

### Windows + WSL Issues

#### Issue W1: WSL Cannot Resolve DNS

**Symptoms:**
```bash
$ ping github.com
ping: github.com: Temporary failure in name resolution
```

**Solutions:**

```bash
# Solution 1: Use Windows DNS
# Create /etc/wsl.conf
sudo tee /etc/wsl.conf > /dev/null <<'EOF'
[network]
generateResolvConf = false
EOF

# Set DNS manually
sudo tee /etc/resolv.conf > /dev/null <<'EOF'
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF

# Protect from overwrite
sudo chattr +i /etc/resolv.conf

# Restart WSL
wsl.exe --shutdown
# Then restart WSL
```

```powershell
# Solution 2: Fix Windows DNS (PowerShell as Admin)
# Get network adapter
Get-NetAdapter | Where-Object {$_.Status -eq "Up"}

# Set DNS servers
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "8.8.8.8","1.1.1.1"

# Restart WSL
wsl --shutdown
```

#### Issue W2: VPN Breaks WSL Networking

**Symptoms:**
- Works without VPN
- Fails when VPN connected
- WSL can't reach internet

**Solutions:**

```bash
# Solution 1: Use Windows host as gateway
# Get Windows host IP
cat /etc/resolv.conf | grep nameserver | awk '{print $2}'

# Add route through Windows (if needed)
WINDOWS_IP=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')
sudo ip route add default via $WINDOWS_IP
```

```powershell
# Solution 2: Configure VPN to allow WSL (PowerShell as Admin)
# Add firewall rule for WSL
New-NetFirewallRule -DisplayName "WSL" -Direction Inbound -InterfaceAlias "vEthernet (WSL)" -Action Allow
New-NetFirewallRule -DisplayName "WSL" -Direction Outbound -InterfaceAlias "vEthernet (WSL)" -Action Allow

# Check VPN adapter metric
Get-NetAdapter | Sort-Object -Property InterfaceMetric

# Lower WSL adapter metric (higher priority)
Set-NetIPInterface -InterfaceAlias "vEthernet (WSL)" -InterfaceMetric 1
```

#### Issue W3: Windows Firewall Blocks WSL

**Symptoms:**
```bash
$ curl https://api.github.com
curl: (7) Failed to connect to api.github.com port 443: Connection refused
```

**Solutions:**

```powershell
# Check Windows Firewall (PowerShell as Admin)
Get-NetFirewallProfile | Format-Table Name, Enabled

# Allow WSL through firewall
New-NetFirewallRule -DisplayName "WSL Outbound" `
  -Direction Outbound `
  -InterfaceAlias "vEthernet (WSL)" `
  -Action Allow

# Allow HTTPS specifically
New-NetFirewallRule -DisplayName "WSL HTTPS" `
  -Direction Outbound `
  -Protocol TCP `
  -LocalPort Any `
  -RemotePort 443 `
  -Action Allow

# Verify rules
Get-NetFirewallRule -DisplayName "*WSL*" | Format-Table Name, Enabled, Direction, Action
```

#### Issue W4: Clock Skew in WSL

**Symptoms:**
```bash
$ curl https://api.github.com
curl: (60) SSL certificate problem: certificate is not yet valid
```

**Solutions:**

```bash
# Check system time
date
timedatectl

# Sync with Windows time
sudo hwclock -s

# Or sync with NTP
sudo ntpdate pool.ntp.org

# Configure automatic time sync (WSL 2)
sudo tee -a /etc/wsl.conf > /dev/null <<'EOF'
[boot]
command = "hwclock -s"
EOF

# Restart WSL
wsl.exe --shutdown
```

### Linux-Specific Issues

#### Issue L1: SELinux Blocking Connections

**Symptoms:**
```bash
$ curl https://api.github.com
# No error, but hangs
```

**Solutions:**

```bash
# Check SELinux status
getenforce

# Temporarily disable (testing only)
sudo setenforce 0

# If this fixes it, add proper SELinux policy
sudo ausearch -m avc -ts recent | audit2allow -M mypolicy
sudo semodule -i mypolicy.pp

# Re-enable SELinux
sudo setenforce 1
```

#### Issue L2: AppArmor Blocking Connections

**Solutions:**

```bash
# Check AppArmor status
sudo aa-status

# Temporarily disable profile (testing)
sudo aa-complain /path/to/runner

# Create proper AppArmor profile
sudo aa-logprof

# Re-enable
sudo aa-enforce /path/to/runner
```

### macOS-Specific Issues

#### Issue M1: System Proxy Overriding Settings

**Solutions:**

```bash
# Check system proxy
scutil --proxy

# Disable system proxy temporarily
sudo networksetup -setwebproxystate "Wi-Fi" off
sudo networksetup -setsecurewebproxystate "Wi-Fi" off

# Test
curl https://api.github.com

# Configure proxy explicitly for runner
export HTTPS_PROXY="http://proxy:8080"
```

---

## Diagnostic Procedures

### Procedure 1: Complete Network Diagnostic

Run this comprehensive diagnostic:

```bash
#!/bin/bash
# save as diagnose-network.sh

echo "=== GitHub Actions Runner Network Diagnostic ==="
echo ""
echo "Date: $(date)"
echo "Platform: $(uname -a)"
echo ""

echo "=== 1. DNS Configuration ==="
cat /etc/resolv.conf
echo ""

echo "=== 2. DNS Resolution Test ==="
for domain in github.com api.github.com pipelines.actions.githubusercontent.com; do
  echo -n "Testing $domain: "
  if nslookup $domain > /dev/null 2>&1; then
    echo "OK"
  else
    echo "FAIL"
  fi
done
echo ""

echo "=== 3. Network Connectivity ==="
for host in github.com api.github.com; do
  echo -n "Ping $host: "
  if ping -c 1 -W 2 $host > /dev/null 2>&1; then
    echo "OK"
  else
    echo "FAIL"
  fi
done
echo ""

echo "=== 4. Port Connectivity ==="
for host in github.com:443 api.github.com:443; do
  echo -n "Testing $host: "
  if timeout 5 bash -c "echo > /dev/tcp/${host/:/ }" 2>/dev/null; then
    echo "OK"
  else
    echo "FAIL"
  fi
done
echo ""

echo "=== 5. HTTPS Connectivity ==="
for url in https://github.com https://api.github.com; do
  echo -n "Testing $url: "
  code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "$url" 2>/dev/null || echo "000")
  if [[ "$code" =~ ^(200|301|302)$ ]]; then
    echo "OK ($code)"
  else
    echo "FAIL ($code)"
  fi
done
echo ""

echo "=== 6. TLS Certificate ==="
echo | openssl s_client -connect api.github.com:443 -brief 2>&1 | grep -i "verification"
echo ""

echo "=== 7. Proxy Configuration ==="
env | grep -i proxy || echo "No proxy configured"
echo ""

echo "=== 8. Latency Test ==="
echo -n "Average latency to api.github.com: "
{
  for i in {1..5}; do
    curl -o /dev/null -s -w "%{time_total}\n" https://api.github.com
  done
} | awk '{sum+=$1} END {printf "%.0f ms\n", (sum/NR)*1000}'
echo ""

echo "=== Diagnostic Complete ==="
```

Make executable and run:
```bash
chmod +x diagnose-network.sh
./diagnose-network.sh > network-diagnostic-$(date +%Y%m%d-%H%M%S).txt
```

### Procedure 2: Packet Capture for Advanced Debugging

```bash
# Capture HTTPS traffic to GitHub (requires root)
sudo tcpdump -i any -n 'host api.github.com and port 443' -w github-capture.pcap

# In another terminal, reproduce the issue
curl https://api.github.com

# Stop capture (Ctrl+C in tcpdump terminal)

# Analyze capture
tcpdump -r github-capture.pcap -n

# Look for:
# - TCP SYN/ACK handshake
# - TLS ClientHello/ServerHello
# - Any RST or FIN packets
```

### Procedure 3: SSL/TLS Handshake Analysis

```bash
# Detailed TLS handshake
openssl s_client -connect api.github.com:443 -state -debug

# Check supported TLS versions
for version in ssl3 tls1 tls1_1 tls1_2 tls1_3; do
  echo -n "Testing $version: "
  if openssl s_client -connect api.github.com:443 -$version < /dev/null 2>/dev/null | grep -q "Verify return code: 0"; then
    echo "Supported"
  else
    echo "Not supported"
  fi
done

# Check certificate chain
openssl s_client -connect api.github.com:443 -showcerts 2>/dev/null | \
  awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/' | \
  csplit -f cert- - '/END CERTIFICATE/+1' '{*}' 2>/dev/null

# Verify each certificate
for cert in cert-*; do
  if [ -s "$cert" ]; then
    echo "Certificate: $cert"
    openssl x509 -in "$cert" -noout -subject -issuer -dates
    echo ""
  fi
done
```

---

## Advanced Troubleshooting

### Scenario 1: Intermittent Connection Failures

**Diagnosis:**
```bash
# Continuous monitoring
while true; do
  if ! curl -sSf --connect-timeout 5 https://api.github.com > /dev/null 2>&1; then
    echo "$(date): Connection failed"
    # Capture diagnostic info
    ip route >> failure-$(date +%s).log
    netstat -rn >> failure-$(date +%s).log
  fi
  sleep 10
done

# Analyze patterns
# - Time-based? (might be DNS TTL)
# - Random? (might be load balancer/network path)
# - After idle? (might be connection timeout)
```

**Solutions:**
- If DNS-related: Reduce DNS TTL or use local caching
- If idle timeout: Configure keep-alive
- If load balancer: Add retry logic to runner

### Scenario 2: Works from Browser, Fails from CLI

This usually indicates:
1. Proxy authentication handled by browser but not CLI
2. Certificate trust store difference
3. Browser using system proxy, CLI not configured

**Diagnosis:**
```bash
# Check if browser uses proxy
# Chrome: chrome://net-internals/#proxy
# Firefox: about:networking

# Export browser's proxy config
# Then test CLI with same config
export HTTPS_PROXY="http://proxy:8080"
curl https://api.github.com
```

### Scenario 3: IPv4 vs IPv6 Issues

**Diagnosis:**
```bash
# Check IPv6 connectivity
ping6 -c 3 ipv6.google.com

# Force IPv4
curl -4 https://api.github.com

# Force IPv6
curl -6 https://api.github.com

# Check GitHub IPs
dig github.com A      # IPv4
dig github.com AAAA   # IPv6
```

**Solutions:**
```bash
# Disable IPv6 if problematic (temporary)
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1

# Prefer IPv4 in curl
echo 'ipv4' >> ~/.curlrc

# Configure runner to prefer IPv4
export PREFER_IPV4=true
```

---

## Escalation Procedures

### Level 1: Self-Service (This Document)

1. Run `./scripts/test-connectivity.sh`
2. Check "Common Issues" section
3. Run diagnostic scripts
4. Apply solutions

### Level 2: Team Support

If Level 1 doesn't resolve:

1. Gather diagnostic information:
   ```bash
   # Create support bundle
   tar -czf support-bundle-$(date +%Y%m%d).tar.gz \
     connectivity-test.log \
     network-diagnostic-*.txt \
     /etc/resolv.conf \
     ~/.bashrc
   ```

2. Document:
   - Exact error messages
   - Steps to reproduce
   - What you've tried
   - Platform details (WSL/Linux/macOS)

3. Contact: DevOps Team

### Level 3: Vendor Support

If Level 2 doesn't resolve:

1. GitHub Support:
   - [GitHub Support Portal](https://support.github.com)
   - Provide runner logs: `~/actions-runner/_diag/Runner_*.log`
   - Provide network diagnostic output

2. Corporate IT:
   - For proxy/firewall issues
   - Provide list of required endpoints
   - Reference: `config/network-requirements.md`

### Emergency Workarounds

If runner is urgently needed and network issues persist:

1. **Temporary Direct Connection** (if allowed):
   ```bash
   # Bypass proxy temporarily
   unset HTTP_PROXY HTTPS_PROXY
   # Start runner
   ./run.sh
   ```

2. **Alternative Network Path**:
   - Mobile hotspot
   - Different network segment
   - DMZ if available

3. **GitHub-Hosted Runners** (temporary fallback):
   - Use while debugging self-hosted
   - Switch back after resolution

---

## Monitoring and Prevention

### Continuous Monitoring Setup

```bash
# Cron job for connectivity monitoring
crontab -e

# Add line:
*/5 * * * * /path/to/scripts/test-connectivity.sh --format json >> /var/log/runner-connectivity.log 2>&1
```

### Alerting on Failures

```bash
# Simple email alert
if ! /path/to/scripts/test-connectivity.sh > /dev/null 2>&1; then
  echo "GitHub connectivity failed at $(date)" | \
    mail -s "Runner Connectivity Alert" admin@company.com
fi
```

### Health Check Dashboard

Use the test script with JSON output for monitoring:
```bash
./scripts/test-connectivity.sh --format json | \
  jq '.status, .summary'
```

Integrate with your monitoring solution (Prometheus, Grafana, etc.)

---

## Quick Reference Commands

### Most Useful Diagnostic Commands

```bash
# All-in-one test
./scripts/test-connectivity.sh

# Quick DNS test
nslookup github.com 8.8.8.8

# Quick connectivity test
curl -I https://api.github.com

# Quick latency test
time curl -so /dev/null https://api.github.com

# Quick proxy test
curl -x $HTTPS_PROXY -I https://api.github.com

# Quick certificate test
echo | openssl s_client -connect api.github.com:443 2>/dev/null | grep -i verify
```

### Emergency Quick Fixes

```bash
# Reset DNS
sudo tee /etc/resolv.conf <<< "nameserver 8.8.8.8"

# Bypass proxy
unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy

# Refresh network
sudo systemctl restart networking

# WSL: Restart network
wsl.exe --shutdown

# macOS: Flush DNS
sudo dscacheutil -flushcache
```

---

## Additional Resources

- **Documentation**: [Network Requirements](../config/network-requirements.md)
- **Scripts**: [Connectivity Test](../scripts/test-connectivity.sh)
- **Configuration**: [Proxy Setup](../config/proxy-configuration.sh)
- **GitHub Docs**: [Self-hosted runner networking](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners#communication-requirements)

---

**For urgent issues**: Contact DevOps Team or open incident ticket

**Document Maintainer**: Network Engineering Team
**Last Review**: 2025-10-17
**Version**: 1.0.0
