# GitHub Actions Self-Hosted Runner Operations Playbook

**Version:** 1.0
**Last Updated:** October 2025
**Document Type:** Day-to-Day Operations Guide

---

## Table of Contents

1. [Introduction](#introduction)
2. [Daily Health Checks](#daily-health-checks)
3. [Weekly Maintenance Tasks](#weekly-maintenance-tasks)
4. [Monthly Review Procedures](#monthly-review-procedures)
5. [Incident Response Procedures](#incident-response-procedures)
6. [Escalation Paths](#escalation-paths)
7. [Runbooks for Common Scenarios](#runbooks-for-common-scenarios)
8. [Performance Tuning Procedures](#performance-tuning-procedures)
9. [Capacity Planning and Scaling](#capacity-planning-and-scaling)
10. [Appendices](#appendices)

---

## Introduction

### Purpose

This Operations Playbook provides comprehensive guidance for the day-to-day operation, maintenance, and optimization of the GitHub Actions Self-Hosted Runner infrastructure. It serves as the primary reference for operations teams, on-call engineers, and system administrators.

### Scope

This playbook covers:
- Routine operational procedures
- Monitoring and health checks
- Maintenance windows and tasks
- Incident response and escalation
- Performance optimization
- Capacity management

### Critical Metrics Dashboard

**Key Performance Indicators (KPIs)**
| Metric | Target | Alert Threshold | Current |
|--------|--------|-----------------|---------|
| System Availability | 99.9% | <99.5% | Monitor |
| Job Success Rate | >95% | <90% | Monitor |
| Average Job Duration | <2 min | >5 min | Monitor |
| Runner Utilization | 60-80% | >90% or <30% | Monitor |
| API Rate Limit Usage | <80% | >90% | Monitor |

---

## Daily Health Checks

### Morning Health Check (9:00 AM)

#### 1. System Status Verification
```bash
#!/bin/bash
# morning-health-check.sh

echo "=== GitHub Actions Runner Health Check ==="
echo "Time: $(date)"
echo ""

# Check all runner services
echo "1. Runner Service Status:"
for i in {1..10}; do
    status=$(systemctl is-active actions.runner.runner$i)
    if [ "$status" = "active" ]; then
        echo "   ✅ Runner $i: ACTIVE"
    else
        echo "   ❌ Runner $i: $status - REQUIRES ATTENTION"
    fi
done

# Check system resources
echo ""
echo "2. System Resources:"
echo "   CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')%"
echo "   Memory: $(free -h | grep Mem | awk '{print $3 "/" $2}')"
echo "   Disk: $(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}')"

# Check job queue
echo ""
echo "3. Job Queue Status:"
gh api /orgs/YOUR_ORG/actions/runners --jq '.runners[] |
    select(.busy==true) | .name' | wc -l |
    xargs -I {} echo "   Active Jobs: {}"

# Check recent failures
echo ""
echo "4. Recent Job Failures (last 24h):"
gh run list --limit 100 --json conclusion,createdAt |
    jq '[.[] | select(.conclusion=="failure")] | length' |
    xargs -I {} echo "   Failed Jobs: {}"
```

#### 2. Critical Service Verification
```bash
# Verify critical dependencies
echo "5. Service Dependencies:"

# GitHub API connectivity
if curl -s -o /dev/null -w "%{http_code}" https://api.github.com | grep -q "200"; then
    echo "   ✅ GitHub API: REACHABLE"
else
    echo "   ❌ GitHub API: UNREACHABLE"
fi

# AI Service connectivity
if curl -s -o /dev/null -w "%{http_code}" https://api.anthropic.com/v1/health | grep -q "200"; then
    echo "   ✅ AI Service: REACHABLE"
else
    echo "   ❌ AI Service: UNREACHABLE"
fi

# WSL Status
if wsl --list --running | grep -q "Ubuntu"; then
    echo "   ✅ WSL Ubuntu: RUNNING"
else
    echo "   ❌ WSL Ubuntu: NOT RUNNING"
fi
```

#### 3. Alert Review
```yaml
Morning Alert Review Checklist:
- [ ] Check overnight alerts in monitoring system
- [ ] Review any P1/P2 incidents from overnight
- [ ] Check email for GitHub service notifications
- [ ] Review security alerts
- [ ] Check backup completion status
- [ ] Verify log rotation completed
```

### Afternoon Health Check (2:00 PM)

#### 1. Performance Metrics Review
```bash
#!/bin/bash
# afternoon-performance-check.sh

echo "=== Afternoon Performance Review ==="

# Job execution metrics
echo "1. Job Performance (last 4 hours):"
gh run list --limit 50 --json durationMS,conclusion |
    jq '[.[] | select(.conclusion=="success")] |
    {
        avg: (map(.durationMS) | add/length/1000),
        max: (map(.durationMS) | max/1000),
        min: (map(.durationMS) | min/1000)
    }' |
    xargs -I {} echo "   Execution Times: {}"

# Cache hit rates
echo ""
echo "2. Cache Performance:"
find /home/runners/shared/cache -type f -amin -240 | wc -l |
    xargs -I {} echo "   Cache Hits (4h): {}"

# API rate limit check
echo ""
echo "3. GitHub API Rate Limit:"
gh api rate_limit --jq '.resources.core |
    "   Used: \(.used)/\(.limit) (\(.used * 100 / .limit)%)"'
```

#### 2. Queue Management
```bash
# Check and manage job queue
echo "4. Queue Management:"

QUEUE_DEPTH=$(gh api /orgs/YOUR_ORG/actions/runs --jq '.workflow_runs |
    map(select(.status=="queued")) | length')

echo "   Queue Depth: $QUEUE_DEPTH"

if [ $QUEUE_DEPTH -gt 50 ]; then
    echo "   ⚠️  HIGH QUEUE DEPTH - Consider scaling"
    # Alert team
    ./scripts/send-alert.sh "High queue depth: $QUEUE_DEPTH jobs pending"
fi
```

### Evening Health Check (6:00 PM)

#### End of Day Summary
```bash
#!/bin/bash
# evening-summary.sh

echo "=== End of Day Summary ==="
echo "Date: $(date +%Y-%m-%d)"
echo ""

# Daily statistics
echo "Today's Statistics:"
echo "  Total Jobs Run: $(gh run list --limit 200 --json createdAt |
    jq '[.[] | select(.createdAt | startswith("'$(date +%Y-%m-%d)'"))] | length')"

echo "  Success Rate: $(gh run list --limit 200 --json conclusion,createdAt |
    jq '[.[] | select(.createdAt | startswith("'$(date +%Y-%m-%d)'")] |
    (map(select(.conclusion=="success")) | length) * 100 / length')%"

echo "  Average Duration: $(gh run list --limit 200 --json durationMS,createdAt |
    jq '[.[] | select(.createdAt | startswith("'$(date +%Y-%m-%d)'")] |
    (map(.durationMS) | add / length / 1000)')s"

# Resource utilization
echo ""
echo "Peak Resource Usage:"
# Parse monitoring system for peak values
```

---

## Weekly Maintenance Tasks

### Monday: Token Rotation and Security Review

```bash
#!/bin/bash
# monday-security-maintenance.sh

echo "=== Monday Security Maintenance ==="

# 1. Rotate runner tokens
echo "1. Rotating Runner Tokens..."
./scripts/rotate-tokens.sh --all --force

# 2. Review access logs
echo "2. Reviewing Access Logs..."
grep "authentication" /var/log/runner/*.log |
    grep -v "success" |
    tail -20

# 3. Update security patches
echo "3. Checking for Security Updates..."
sudo apt update
sudo apt list --upgradable | grep -E "security|critical"

# 4. Validate secrets
echo "4. Validating Secrets Configuration..."
gh secret list | while read secret; do
    echo "   Checking: $secret"
    # Verify secret is not expired
done

# 5. Certificate expiry check
echo "5. Certificate Expiry Check..."
for cert in /etc/ssl/certs/github*.pem; do
    expiry=$(openssl x509 -enddate -noout -in "$cert" | cut -d= -f2)
    echo "   $cert expires: $expiry"
done
```

### Tuesday: Performance Optimization

```bash
#!/bin/bash
# tuesday-performance-tuning.sh

echo "=== Tuesday Performance Optimization ==="

# 1. Analyze slow jobs
echo "1. Identifying Slow Jobs..."
gh run list --limit 100 --json name,durationMS |
    jq '.[] | select(.durationMS > 300000) |
    {name: .name, duration: (.durationMS/1000)}'

# 2. Clean up old workspaces
echo "2. Cleaning Old Workspaces..."
find /home/runners/*/workspace -type d -mtime +7 -exec rm -rf {} \; 2>/dev/null
echo "   Freed space: $(du -sh /home/runners | cut -f1)"

# 3. Optimize cache
echo "3. Optimizing Cache..."
# Remove cache entries not accessed in 14 days
find /home/runners/shared/cache -type f -atime +14 -delete
# Defragment cache directory
e4defrag /home/runners/shared/cache

# 4. Review and adjust resource limits
echo "4. Reviewing Resource Limits..."
for i in {1..10}; do
    systemctl show actions.runner.runner$i |
        grep -E "Memory|CPU|Tasks" |
        head -5
done
```

### Wednesday: System Updates and Patches

```bash
#!/bin/bash
# wednesday-system-updates.sh

echo "=== Wednesday System Maintenance ==="

# 1. Update runner software
echo "1. Updating GitHub Runners..."
for i in {1..10}; do
    echo "   Updating runner$i..."
    ./scripts/setup-runner.sh --runner-id $i --update
done

# 2. Update system packages
echo "2. Updating System Packages..."
sudo apt update
sudo apt upgrade -y

# 3. Update monitoring agents
echo "3. Updating Monitoring Agents..."
# Update Datadog/Prometheus agents
sudo systemctl restart datadog-agent
sudo systemctl restart prometheus-node-exporter

# 4. Verify all updates
echo "4. Verifying Updates..."
./scripts/validate-setup.sh --comprehensive
```

### Thursday: Backup and Disaster Recovery Testing

```bash
#!/bin/bash
# thursday-backup-dr.sh

echo "=== Thursday Backup and DR Testing ==="

# 1. Verify backups
echo "1. Verifying Backup Integrity..."
for backup in /backup/runners/*.tar.gz; do
    tar -tzf "$backup" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "   ✅ $(basename $backup): Valid"
    else
        echo "   ❌ $(basename $backup): Corrupted"
    fi
done

# 2. Test restore procedure
echo "2. Testing Restore Procedure..."
# Restore to test environment
./scripts/restore-runner.sh --test --runner-id test1

# 3. Failover simulation
echo "3. Running Failover Simulation..."
./scripts/simulate-failover.sh --runner 5 --duration 300

# 4. Update DR documentation
echo "4. DR Documentation Status:"
echo "   Last updated: $(stat -c %y /docs/disaster-recovery.md)"
```

### Friday: Reporting and Planning

```bash
#!/bin/bash
# friday-reporting.sh

echo "=== Friday Weekly Report Generation ==="

# 1. Generate weekly metrics report
echo "1. Generating Weekly Metrics Report..."
cat > weekly-report-$(date +%Y%W).md << EOF
# Weekly Operations Report - Week $(date +%V), $(date +%Y)

## Executive Summary
- Total Jobs Processed: $(gh run list --limit 1000 --json id | jq length)
- Average Success Rate: $(calculate_success_rate)%
- Average Job Duration: $(calculate_avg_duration)s
- Total Downtime: $(calculate_downtime) minutes

## Key Achievements
- $(list_achievements)

## Issues and Resolutions
- $(list_issues)

## Upcoming Maintenance
- $(list_planned_maintenance)

## Recommendations
- $(generate_recommendations)
EOF

# 2. Capacity planning review
echo "2. Capacity Planning Analysis..."
./scripts/capacity-analyzer.sh --period 7d --forecast 30d

# 3. Update documentation
echo "3. Documentation Updates Required:"
find /docs -type f -name "*.md" -mtime +30 |
    xargs -I {} echo "   - {}"
```

---

## Monthly Review Procedures

### First Monday: Comprehensive System Audit

```yaml
Monthly System Audit Checklist:

Infrastructure Review:
- [ ] Review all runner configurations
- [ ] Validate network security rules
- [ ] Audit user access and permissions
- [ ] Review storage utilization trends
- [ ] Validate backup retention policies

Performance Analysis:
- [ ] Analyze monthly performance trends
- [ ] Identify bottlenecks and optimization opportunities
- [ ] Review capacity utilization
- [ ] Benchmark against SLAs
- [ ] Compare with previous month metrics

Security Audit:
- [ ] Review security logs for anomalies
- [ ] Validate compliance with security policies
- [ ] Update threat model if needed
- [ ] Review and rotate all credentials
- [ ] Patch compliance verification

Cost Analysis:
- [ ] Review infrastructure costs
- [ ] Calculate cost per job
- [ ] Identify cost optimization opportunities
- [ ] Update ROI calculations
- [ ] Budget forecast for next month
```

### Monthly Maintenance Window (Last Saturday)

```bash
#!/bin/bash
# monthly-maintenance-window.sh

echo "=== Monthly Maintenance Window ==="
echo "Start Time: $(date)"

# 1. Full system backup
echo "1. Performing Full System Backup..."
./scripts/backup-all.sh --full --compress

# 2. Major updates
echo "2. Installing Major Updates..."
# Coordinate with change management
sudo apt dist-upgrade -y

# 3. Runner re-registration
echo "3. Re-registering All Runners..."
for i in {1..10}; do
    ./scripts/setup-runner.sh --runner-id $i --update --force
done

# 4. Infrastructure optimization
echo "4. Infrastructure Optimization..."
# Defragment disks
sudo e4defrag /home/runners
# Clean package cache
sudo apt clean
# Optimize databases
./scripts/optimize-metrics-db.sh

# 5. Compliance scanning
echo "5. Running Compliance Scans..."
./scripts/compliance-scanner.sh --cis-benchmark --generate-report

echo "End Time: $(date)"
```

---

## Incident Response Procedures

### Incident Classification

| Priority | Definition | Response Time | Resolution Time | Examples |
|----------|------------|---------------|-----------------|----------|
| P1 - Critical | Complete service outage | 15 minutes | 2 hours | All runners down |
| P2 - High | Significant degradation | 30 minutes | 4 hours | >50% runners failing |
| P3 - Medium | Limited impact | 2 hours | 24 hours | Single runner issues |
| P4 - Low | No immediate impact | 24 hours | 72 hours | Documentation updates |

### P1 - Critical Incident Response

```yaml
P1 Incident Response Workflow:

1. Detection (0-5 minutes):
   - Alert received from monitoring system
   - Verify impact scope
   - Confirm P1 classification

2. Initial Response (5-15 minutes):
   - Page on-call engineer
   - Create incident channel/bridge
   - Begin incident log
   - Notify stakeholders

3. Triage (15-30 minutes):
   - Identify root cause category
   - Implement immediate mitigation
   - Escalate if needed
   - Update stakeholders

4. Resolution (30-120 minutes):
   - Execute fix procedure
   - Validate resolution
   - Monitor for stability
   - Close incident

5. Post-Incident (within 24 hours):
   - Conduct RCA (Root Cause Analysis)
   - Update runbooks
   - Implement preventive measures
   - Share lessons learned
```

### Common Incident Scenarios

#### Scenario 1: All Runners Offline

```bash
#!/bin/bash
# incident-all-runners-offline.sh

echo "=== INCIDENT: All Runners Offline ==="

# 1. Quick diagnosis
echo "1. Running Diagnostics..."
systemctl status actions.runner.* | grep -E "Active:|Main PID:"

# 2. Check WSL status
echo "2. Checking WSL..."
wsl --list --running

# 3. Restart WSL if needed
if ! wsl --list --running | grep -q "Ubuntu"; then
    echo "3. Restarting WSL..."
    wsl --shutdown
    sleep 5
    wsl --distribution Ubuntu-22.04 --exec echo "WSL Started"
fi

# 4. Restart all runners
echo "4. Restarting All Runners..."
for i in {1..10}; do
    sudo systemctl restart actions.runner.runner$i &
done
wait

# 5. Verify recovery
echo "5. Verifying Recovery..."
sleep 30
for i in {1..10}; do
    if systemctl is-active actions.runner.runner$i | grep -q "active"; then
        echo "   ✅ Runner$i: RECOVERED"
    else
        echo "   ❌ Runner$i: STILL DOWN"
    fi
done
```

#### Scenario 2: High Error Rate

```bash
#!/bin/bash
# incident-high-error-rate.sh

echo "=== INCIDENT: High Error Rate ==="

# 1. Identify error pattern
echo "1. Analyzing Error Patterns..."
tail -1000 /var/log/runner/*.log |
    grep -E "ERROR|FAIL" |
    cut -d: -f4- |
    sort | uniq -c | sort -rn | head -10

# 2. Check common causes
echo "2. Checking Common Causes..."

# API rate limit
RATE_LIMIT=$(gh api rate_limit --jq '.resources.core.remaining')
if [ $RATE_LIMIT -lt 100 ]; then
    echo "   ⚠️  API Rate Limit Critical: $RATE_LIMIT remaining"
    echo "   Implementing rate limit mitigation..."
    ./scripts/enable-api-caching.sh
fi

# Disk space
DISK_USAGE=$(df -h /home/runners | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 90 ]; then
    echo "   ⚠️  Disk Space Critical: ${DISK_USAGE}%"
    echo "   Emergency cleanup..."
    find /home/runners -name "_work" -type d -exec rm -rf {}/\* \; 2>/dev/null
fi

# Memory pressure
MEMORY_FREE=$(free -m | grep Mem | awk '{print $4}')
if [ $MEMORY_FREE -lt 1000 ]; then
    echo "   ⚠️  Low Memory: ${MEMORY_FREE}MB free"
    echo "   Restarting runners with memory limits..."
    ./scripts/restart-with-limits.sh --memory 4G
fi
```

#### Scenario 3: Network Connectivity Issues

```bash
#!/bin/bash
# incident-network-issues.sh

echo "=== INCIDENT: Network Connectivity Issues ==="

# 1. Test connectivity
echo "1. Testing Network Connectivity..."
ENDPOINTS=(
    "github.com"
    "api.github.com"
    "raw.githubusercontent.com"
    "api.anthropic.com"
)

for endpoint in "${ENDPOINTS[@]}"; do
    if ping -c 3 -W 2 "$endpoint" > /dev/null 2>&1; then
        echo "   ✅ $endpoint: REACHABLE"
    else
        echo "   ❌ $endpoint: UNREACHABLE"
    fi
done

# 2. Check proxy
echo "2. Checking Proxy Configuration..."
if [ ! -z "$HTTP_PROXY" ]; then
    curl -x "$HTTP_PROXY" -I https://api.github.com
fi

# 3. DNS resolution
echo "3. Testing DNS Resolution..."
nslookup github.com
nslookup api.github.com

# 4. Firewall rules
echo "4. Checking Firewall Rules..."
sudo iptables -L -n | grep -E "443|HTTPS"

# 5. Failover to backup network
if [ "$NETWORK_FAILED" = "true" ]; then
    echo "5. Activating Backup Network..."
    ./scripts/activate-backup-network.sh
fi
```

---

## Escalation Paths

### Escalation Matrix

```yaml
Level 1 - Operations Team:
  Response Time: Immediate
  Authority:
    - Restart services
    - Clear caches
    - Basic troubleshooting
    - Implement documented fixes
  Contact: ops-team@company.com
  On-Call: +1-555-OPS-TEAM

Level 2 - Platform Engineering:
  Response Time: 15 minutes
  Authority:
    - Infrastructure changes
    - Configuration updates
    - Advanced troubleshooting
    - Emergency patches
  Contact: platform-team@company.com
  On-Call: +1-555-PLATFORM

Level 3 - Senior Architecture:
  Response Time: 30 minutes
  Authority:
    - Architecture decisions
    - Major system changes
    - Vendor escalation
    - Business impact decisions
  Contact: architects@company.com
  On-Call: +1-555-ARCHITECT

External Support:
  GitHub Enterprise Support:
    Contact: enterprise-support@github.com
    Phone: +1-555-GITHUB-1
    Priority: Use for GitHub platform issues

  AI Service Support:
    Contact: support@anthropic.com
    Priority: Use for AI service issues

  Infrastructure Provider:
    Contact: support@cloudprovider.com
    Phone: +1-555-CLOUD-SP
    Priority: Use for infrastructure issues
```

### Escalation Decision Tree

```
Start
│
├── Is it a security incident?
│   └── Yes → Security Team (IMMEDIATE)
│
├── Are all services down?
│   └── Yes → Level 3 + Executive notification
│
├── Is it affecting production?
│   └── Yes → Level 2 within 15 minutes
│
├── Has Level 1 tried documented fixes?
│   └── No → Continue Level 1 troubleshooting
│
├── Has issue persisted > 30 minutes?
│   └── Yes → Escalate to Level 2
│
└── Is business impact increasing?
    └── Yes → Escalate immediately
```

---

## Runbooks for Common Scenarios

### Runbook: Add New Runner

```bash
#!/bin/bash
# runbook-add-new-runner.sh

# Purpose: Add a new runner to the fleet
# Time Required: 15 minutes
# Impact: None (additive)

echo "=== Runbook: Add New Runner ==="

# 1. Pre-checks
echo "Step 1: Pre-checks"
RUNNER_ID=$1
if [ -z "$RUNNER_ID" ]; then
    echo "Error: Runner ID required"
    echo "Usage: $0 <runner-id>"
    exit 1
fi

# Check if runner already exists
if [ -d "/home/runners/runner$RUNNER_ID" ]; then
    echo "Error: Runner $RUNNER_ID already exists"
    exit 1
fi

# 2. Generate token
echo "Step 2: Generating Registration Token"
TOKEN=$(gh api -X POST /orgs/YOUR_ORG/actions/runners/registration-token --jq .token)

# 3. Install runner
echo "Step 3: Installing Runner"
./scripts/setup-runner.sh \
    --org YOUR_ORG \
    --token "$TOKEN" \
    --runner-id "$RUNNER_ID" \
    --labels "self-hosted,linux,x64,ai-agent"

# 4. Verify installation
echo "Step 4: Verifying Installation"
sleep 10
if systemctl is-active actions.runner.runner$RUNNER_ID | grep -q "active"; then
    echo "✅ Runner $RUNNER_ID successfully added"
else
    echo "❌ Runner $RUNNER_ID failed to start"
    exit 1
fi

# 5. Update monitoring
echo "Step 5: Updating Monitoring"
./scripts/update-monitoring.sh --add-runner "$RUNNER_ID"

# 6. Update documentation
echo "Step 6: Updating Documentation"
echo "- Runner $RUNNER_ID added on $(date)" >> /docs/runner-inventory.md

echo "=== Runner Successfully Added ==="
```

### Runbook: Remove Runner

```bash
#!/bin/bash
# runbook-remove-runner.sh

# Purpose: Gracefully remove a runner from the fleet
# Time Required: 10 minutes
# Impact: Reduced capacity

echo "=== Runbook: Remove Runner ==="

RUNNER_ID=$1

# 1. Drain runner
echo "Step 1: Draining Runner"
gh api -X PATCH /orgs/YOUR_ORG/actions/runners/$RUNNER_ID \
    -f status=offline

# Wait for current jobs to complete
echo "Waiting for jobs to complete (max 5 minutes)..."
timeout 300 bash -c "while gh api /orgs/YOUR_ORG/actions/runners/$RUNNER_ID --jq .busy | grep -q true; do sleep 10; done"

# 2. Stop service
echo "Step 2: Stopping Service"
sudo systemctl stop actions.runner.runner$RUNNER_ID
sudo systemctl disable actions.runner.runner$RUNNER_ID

# 3. Remove from GitHub
echo "Step 3: Removing from GitHub"
cd /home/runners/runner$RUNNER_ID
./config.sh remove --token "$(gh api -X POST /orgs/YOUR_ORG/actions/runners/remove-token --jq .token)"

# 4. Clean up files
echo "Step 4: Cleaning Up Files"
rm -rf /home/runners/runner$RUNNER_ID

# 5. Update monitoring
echo "Step 5: Updating Monitoring"
./scripts/update-monitoring.sh --remove-runner "$RUNNER_ID"

echo "=== Runner Successfully Removed ==="
```

### Runbook: Emergency Cache Clear

```bash
#!/bin/bash
# runbook-emergency-cache-clear.sh

# Purpose: Clear all caches when experiencing cache corruption
# Time Required: 5 minutes
# Impact: Temporary performance degradation

echo "=== Runbook: Emergency Cache Clear ==="

# 1. Notify team
echo "Step 1: Notifying Team"
./scripts/send-notification.sh "Emergency cache clear initiated by $USER"

# 2. Clear runner caches
echo "Step 2: Clearing Runner Caches"
for i in {1..10}; do
    echo "   Clearing runner$i cache..."
    rm -rf /home/runners/runner$i/cache/*
    rm -rf /home/runners/runner$i/_work/_tool/*
done

# 3. Clear shared cache
echo "Step 3: Clearing Shared Cache"
rm -rf /home/runners/shared/cache/*

# 4. Clear package manager caches
echo "Step 4: Clearing Package Manager Caches"
npm cache clean --force
pip cache purge
sudo apt clean

# 5. Restart runners
echo "Step 5: Restarting Runners"
for i in {1..10}; do
    sudo systemctl restart actions.runner.runner$i &
done
wait

echo "=== Cache Clear Complete ==="
```

### Runbook: Scale Up During High Load

```bash
#!/bin/bash
# runbook-scale-up.sh

# Purpose: Quickly scale up runner capacity during high load
# Time Required: 20 minutes
# Impact: Positive - increased capacity

echo "=== Runbook: Scale Up Runners ==="

# 1. Check current load
echo "Step 1: Checking Current Load"
QUEUE_DEPTH=$(gh api /orgs/YOUR_ORG/actions/runs --jq '[.workflow_runs[] | select(.status=="queued")] | length')
echo "Current queue depth: $QUEUE_DEPTH"

if [ $QUEUE_DEPTH -lt 20 ]; then
    echo "Queue depth normal, scale-up not required"
    exit 0
fi

# 2. Determine scale factor
echo "Step 2: Calculating Scale Requirements"
ADDITIONAL_RUNNERS=$((QUEUE_DEPTH / 5))
echo "Adding $ADDITIONAL_RUNNERS additional runners"

# 3. Activate standby runners
echo "Step 3: Activating Standby Runners"
for i in $(seq 11 $((10 + ADDITIONAL_RUNNERS))); do
    echo "   Activating runner$i..."
    ./scripts/setup-runner.sh \
        --org YOUR_ORG \
        --token "$(gh api -X POST /orgs/YOUR_ORG/actions/runners/registration-token --jq .token)" \
        --runner-id "$i" \
        --quick-start &
done
wait

# 4. Verify scale-up
echo "Step 4: Verifying Scale-Up"
sleep 30
ACTIVE_RUNNERS=$(gh api /orgs/YOUR_ORG/actions/runners --jq '[.runners[] | select(.status=="online")] | length')
echo "Active runners: $ACTIVE_RUNNERS"

# 5. Set auto-scale-down timer
echo "Step 5: Scheduling Scale-Down"
echo "./scripts/auto-scale-down.sh" | at now + 2 hours

echo "=== Scale-Up Complete ==="
```

---

## Performance Tuning Procedures

### Weekly Performance Analysis

```bash
#!/bin/bash
# performance-analysis.sh

echo "=== Weekly Performance Analysis ==="

# 1. Collect metrics
echo "1. Collecting Performance Metrics..."

# Job execution times
JOB_METRICS=$(gh run list --limit 500 --json durationMS,conclusion |
    jq '{
        avg_duration: ([.[] | select(.conclusion=="success") | .durationMS] | add / length / 1000),
        p95_duration: ([.[] | select(.conclusion=="success") | .durationMS] | sort | .[length * 0.95 / 1] / 1000),
        max_duration: ([.[] | select(.conclusion=="success") | .durationMS] | max / 1000)
    }')

echo "Job Execution Metrics:"
echo "$JOB_METRICS" | jq .

# 2. Identify bottlenecks
echo ""
echo "2. Identifying Bottlenecks..."

# Slow steps analysis
gh run list --limit 10 --json id | jq -r '.[].id' | while read run_id; do
    gh run view $run_id --json jobs --jq '.jobs[].steps[] |
        select(.conclusion=="success") |
        {name: .name, duration: .durationMS}' |
        jq -s 'sort_by(.duration) | reverse | .[0:3]'
done | jq -s 'flatten | group_by(.name) |
    map({step: .[0].name, avg_duration: (map(.duration) | add / length / 1000)}) |
    sort_by(.avg_duration) | reverse | .[0:5]'

# 3. Resource utilization
echo ""
echo "3. Resource Utilization Analysis..."

for i in {1..10}; do
    echo "Runner$i:"
    # CPU usage
    top -bn1 -p $(pgrep -f "runner$i") 2>/dev/null | tail -1 | awk '{print "  CPU: "$9"%"}'
    # Memory usage
    ps aux | grep "runner$i" | grep -v grep | awk '{print "  Memory: "$4"%"}'
done
```

### Performance Optimization Recommendations

```yaml
Optimization Checklist:

Code Level:
- [ ] Enable sparse checkout for large repos
- [ ] Implement caching for dependencies
- [ ] Optimize Docker layer caching
- [ ] Use matrix builds efficiently
- [ ] Parallelize test execution

Infrastructure Level:
- [ ] Increase runner memory if swapping
- [ ] Add more runners if queue depth > 20
- [ ] Upgrade to NVMe SSD if disk I/O > 100MB/s
- [ ] Implement regional runners if latency > 200ms
- [ ] Enable GitHub Actions cache

Script Level:
- [ ] Batch API calls to reduce rate limit usage
- [ ] Implement local caching for AI responses
- [ ] Optimize git operations (shallow clone, sparse checkout)
- [ ] Pre-warm commonly used tools
- [ ] Clean up workspace after each job

Network Level:
- [ ] Configure HTTP/2 for API calls
- [ ] Implement connection pooling
- [ ] Use CDN for artifact downloads
- [ ] Configure DNS caching
- [ ] Optimize proxy settings
```

### Performance Tuning Scripts

#### Memory Optimization
```bash
#!/bin/bash
# tune-memory.sh

echo "=== Memory Optimization ==="

# 1. Adjust WSL memory allocation
cat > ~/.wslconfig << EOF
[wsl2]
memory=48GB
swap=16GB
swapFile=C:\\temp\\wsl-swap.vhdx
pageReporting=false
EOF

# 2. Configure runner memory limits
for i in {1..10}; do
    sudo systemctl set-property actions.runner.runner$i MemoryMax=4G
    sudo systemctl set-property actions.runner.runner$i MemorySwapMax=8G
done

# 3. Enable memory compression
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

echo "Memory optimization complete - restart required"
```

#### CPU Optimization
```bash
#!/bin/bash
# tune-cpu.sh

echo "=== CPU Optimization ==="

# 1. Set CPU affinity for runners
for i in {1..10}; do
    # Assign 2 cores per runner
    CORES=$((i*2-1)),$((i*2))
    sudo systemctl set-property actions.runner.runner$i CPUAffinity=$CORES
done

# 2. Adjust CPU scheduling
echo "kernel.sched_migration_cost_ns=5000000" | sudo tee -a /etc/sysctl.conf
echo "kernel.sched_autogroup_enabled=1" | sudo tee -a /etc/sysctl.conf

# 3. Set CPU governor to performance
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

sudo sysctl -p
echo "CPU optimization complete"
```

---

## Capacity Planning and Scaling

### Capacity Monitoring Dashboard

```bash
#!/bin/bash
# capacity-dashboard.sh

echo "=== Capacity Planning Dashboard ==="
echo "Generated: $(date)"
echo ""

# Current capacity
TOTAL_RUNNERS=$(gh api /orgs/YOUR_ORG/actions/runners --jq '.runners | length')
ONLINE_RUNNERS=$(gh api /orgs/YOUR_ORG/actions/runners --jq '[.runners[] | select(.status=="online")] | length')
BUSY_RUNNERS=$(gh api /orgs/YOUR_ORG/actions/runners --jq '[.runners[] | select(.busy==true)] | length')

echo "Current Capacity:"
echo "  Total Runners: $TOTAL_RUNNERS"
echo "  Online: $ONLINE_RUNNERS"
echo "  Busy: $BUSY_RUNNERS"
echo "  Available: $((ONLINE_RUNNERS - BUSY_RUNNERS))"
echo "  Utilization: $((BUSY_RUNNERS * 100 / ONLINE_RUNNERS))%"

# Historical trends
echo ""
echo "Weekly Trends:"
for day in {0..6}; do
    DATE=$(date -d "$day days ago" +%Y-%m-%d)
    JOBS=$(gh run list --limit 500 --json createdAt |
        jq --arg date "$DATE" '[.[] | select(.createdAt | startswith($date))] | length')
    echo "  $DATE: $JOBS jobs"
done

# Forecasting
echo ""
echo "Capacity Forecast (Next 30 Days):"
./scripts/ml-forecast.py --metric jobs --period 30d
```

### Scaling Decision Matrix

| Queue Depth | Wait Time | CPU Usage | Action Required |
|------------|-----------|-----------|-----------------|
| < 10 | < 30s | < 50% | No action |
| 10-20 | 30-60s | 50-70% | Monitor closely |
| 20-50 | 1-2 min | 70-85% | Add 2-3 runners |
| 50-100 | 2-5 min | 85-95% | Add 5-10 runners |
| > 100 | > 5 min | > 95% | Emergency scale-up |

### Auto-Scaling Configuration

```yaml
# auto-scaling-config.yaml
auto_scaling:
  enabled: true
  min_runners: 5
  max_runners: 20

  scale_up:
    trigger:
      queue_depth: 20
      wait_time: 60s
      cpu_usage: 80%
    action:
      add_runners: 3
      cooldown: 300s

  scale_down:
    trigger:
      idle_runners: 5
      idle_time: 600s
      cpu_usage: 30%
    action:
      remove_runners: 2
      cooldown: 600s

  predictive:
    enabled: true
    model: arima
    forecast_window: 4h
    preemptive_scale: true
```

### Capacity Planning Script

```bash
#!/bin/bash
# capacity-planner.sh

echo "=== Monthly Capacity Planning ==="

# 1. Analyze growth trend
echo "1. Growth Analysis (Last 90 Days):"
GROWTH_RATE=$(./scripts/calculate-growth.sh --period 90d --metric jobs)
echo "   Job growth rate: ${GROWTH_RATE}% per month"

# 2. Calculate required capacity
echo "2. Capacity Requirements:"
CURRENT_JOBS_PER_DAY=$(gh run list --limit 1000 --json createdAt |
    jq '[.[] | select(.createdAt | startswith("'$(date +%Y-%m)'"))] | length' |
    awk '{print $1/30}')

PROJECTED_JOBS=$((CURRENT_JOBS_PER_DAY * (100 + GROWTH_RATE) / 100))
REQUIRED_RUNNERS=$((PROJECTED_JOBS / 100 + 2))  # 100 jobs/day per runner + buffer

echo "   Current: ${CURRENT_JOBS_PER_DAY} jobs/day"
echo "   Projected: ${PROJECTED_JOBS} jobs/day"
echo "   Required Runners: ${REQUIRED_RUNNERS}"

# 3. Cost projection
echo "3. Cost Projection:"
RUNNER_COST=345  # per runner per month
PROJECTED_COST=$((REQUIRED_RUNNERS * RUNNER_COST))
echo "   Infrastructure Cost: \$${PROJECTED_COST}/month"
echo "   Cost per Job: \$$(echo "scale=2; $PROJECTED_COST / ($PROJECTED_JOBS * 30)" | bc)"

# 4. Recommendations
echo "4. Recommendations:"
if [ $REQUIRED_RUNNERS -gt $ONLINE_RUNNERS ]; then
    echo "   ⚠️  Add $((REQUIRED_RUNNERS - ONLINE_RUNNERS)) runners"
    echo "   ⚠️  Consider implementing auto-scaling"
else
    echo "   ✅ Current capacity sufficient"
fi
```

---

## Appendices

### Appendix A: Quick Reference Commands

```bash
# Runner Management
systemctl status actions.runner.*          # Check all runners
systemctl restart actions.runner.runner1   # Restart specific runner
journalctl -u actions.runner.* -f         # View all runner logs

# GitHub CLI
gh run list --limit 10                    # List recent runs
gh run watch                              # Watch current run
gh api /orgs/ORG/actions/runners         # List all runners

# Performance
top -b -n 1 | head -20                   # Quick performance check
iotop -b -n 1                            # Disk I/O check
netstat -tulpn | grep ESTABLISHED        # Network connections

# Troubleshooting
tail -f /var/log/runner/*.log            # Live log monitoring
df -h /home/runners                      # Check disk space
free -h                                   # Check memory

# Cache Management
du -sh /home/runners/*/cache/            # Cache sizes
find /home/runners -name "cache" -exec du -sh {} \;
```

### Appendix B: Configuration Files

#### Monitoring Alert Rules
```yaml
# alerts.yaml
groups:
  - name: runner_alerts
    interval: 30s
    rules:
      - alert: RunnerDown
        expr: up{job="github-runner"} == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Runner {{ $labels.instance }} is down"

      - alert: HighErrorRate
        expr: rate(runner_errors_total[5m]) > 0.1
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High error rate on {{ $labels.instance }}"

      - alert: QueueBacklog
        expr: github_actions_queued_jobs > 50
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "Job queue depth is {{ $value }}"
```

### Appendix C: Emergency Contact List

```yaml
Emergency Contacts:

Internal:
  Operations Team:
    Primary: ops-oncall@company.com
    Phone: +1-555-OPS-0911
    Slack: #ops-emergency

  Platform Team:
    Primary: platform-oncall@company.com
    Phone: +1-555-PLT-0911
    Slack: #platform-emergency

  Management:
    CTO: cto@company.com
    VP Engineering: vp-eng@company.com

External:
  GitHub Support:
    Email: enterprise-support@github.com
    Phone: +1-855-448-4820
    Portal: https://support.github.com

  Infrastructure Provider:
    Email: support@provider.com
    Phone: +1-800-XXX-XXXX
    Portal: https://support.provider.com

Critical Vendors:
  AI Service: support@anthropic.com
  Monitoring: support@datadog.com
  Backup: support@backup-vendor.com
```

### Appendix D: Compliance Checklist

```yaml
Daily Compliance:
- [ ] Review security logs
- [ ] Check backup completion
- [ ] Validate secret rotation status

Weekly Compliance:
- [ ] Run vulnerability scans
- [ ] Review access logs
- [ ] Update security patches
- [ ] Audit user permissions

Monthly Compliance:
- [ ] Full security audit
- [ ] Compliance report generation
- [ ] Policy review and updates
- [ ] Penetration testing (quarterly)
- [ ] Disaster recovery test

Annual Compliance:
- [ ] SOC 2 audit preparation
- [ ] Security training completion
- [ ] Policy documentation update
- [ ] Third-party security assessment
```

---

## Document Control

**Version:** 1.0
**Last Updated:** October 2025
**Next Review:** January 2026
**Owner:** Operations Team
**Approved By:** Platform Engineering Lead

**Change Log:**
- v1.0 - Initial version - October 2025

**Distribution:**
- Operations Team (Primary)
- Platform Engineering Team
- On-Call Engineers
- Management Team

---

*This Operations Playbook is a living document and should be updated regularly based on operational experience and system changes.*