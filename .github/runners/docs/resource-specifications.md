# GitHub Actions Runner Resource Specifications

## Executive Summary

This document defines the detailed resource specifications for self-hosted GitHub Actions runners deployed on Windows with WSL 2.0. It covers hardware requirements, capacity planning, and configuration specifications for native runner processes supporting 3-5 initial runners per host, scalable to 10-20 runners.

## Host Server Specifications

### Minimum Host Requirements

```yaml
Hardware Specifications:
  CPU:
    Cores: 16 physical cores (32 threads with HT)
    Architecture: x86_64 (Intel Xeon or AMD EPYC)
    Frequency: 2.4 GHz base, 3.0 GHz boost
    Cache: 32 MB L3 cache minimum

  Memory:
    Total RAM: 64 GB DDR4 ECC
    Speed: 2666 MHz or higher
    Configuration: Dual channel minimum

  Storage:
    System Drive: 256 GB NVMe SSD (OS)
    Data Drive: 1 TB NVMe SSD (Runners)
    Backup Drive: 2 TB HDD (Archives)
    IOPS: 100,000+ for NVMe drives

  Network:
    Primary NIC: 1 Gbps Ethernet
    Secondary NIC: 1 Gbps (optional, for redundancy)
    Latency: < 10ms to local network
    Bandwidth: 100 Mbps guaranteed to Internet

  Virtualization:
    Type: Bare metal preferred, VM acceptable
    Hypervisor: VMware vSphere 7.0+ or Hyper-V
    Nested Virtualization: Enabled for WSL 2.0
```

### Recommended Host Requirements

```yaml
Hardware Specifications:
  CPU:
    Cores: 32 physical cores (64 threads)
    Architecture: Intel Xeon Gold or AMD EPYC 7003
    Frequency: 2.8 GHz base, 3.5 GHz boost
    Cache: 64 MB L3 cache

  Memory:
    Total RAM: 128 GB DDR4 ECC
    Speed: 3200 MHz
    Configuration: Quad channel

  Storage:
    System Drive: 512 GB NVMe Gen4 SSD
    Data Drive: 2 TB NVMe Gen4 SSD
    Cache Drive: 512 GB NVMe (dedicated cache)
    Backup Drive: 4 TB HDD RAID 1
    IOPS: 500,000+ for Gen4 NVMe

  Network:
    Primary NIC: 10 Gbps Ethernet
    Secondary NIC: 10 Gbps (bonded)
    Latency: < 1ms to local network
    Bandwidth: 1 Gbps guaranteed
```

## Operating System Requirements

### Windows Host OS

```yaml
Windows Configuration:
  Version:
    Minimum: Windows 10 Pro 21H2 (Build 19044)
    Recommended: Windows Server 2022 (Build 20348)
    Alternative: Windows 11 Pro 22H2 (Build 22621)

  Features Required:
    - Hyper-V
    - Windows Subsystem for Linux
    - Virtual Machine Platform
    - Windows Hypervisor Platform

  Updates:
    - Automatic updates enabled
    - Maintenance window: Sunday 2-4 AM
    - Security patches: Within 48 hours

  PowerShell:
    Version: 7.3+ required
    Modules:
      - WSL
      - Hyper-V
      - NetAdapter
      - Storage
```

### WSL 2.0 Configuration

```yaml
WSL Setup:
  Version: WSL 2.0.0.0 or higher
  Distribution: Ubuntu 22.04 LTS
  Kernel: 5.15.90.1 or higher

  Resource Allocation:
    Memory: 50% of host RAM (32-64 GB)
    CPU: 50% of host cores (8-16 cores)
    Swap: 25% of allocated memory (8-16 GB)
    Storage: Expandable VHD, 500 GB initial

  Configuration File (.wslconfig):
    ```ini
    [wsl2]
    memory=32GB
    processors=16
    swap=8GB
    swapFile=D:\\WSL\\swap.vhdx
    localhostForwarding=false
    kernelCommandLine=systemd.unified_cgroup_hierarchy=1
    pageReporting=true
    guiApplications=false
    nestedVirtualization=true
    ```

  Ubuntu Configuration:
    Packages:
      - build-essential
      - git (2.34+)
      - curl
      - wget
      - jq
      - nodejs (18 LTS)
      - python3 (3.10+)
      - docker.io (optional)
      - gh (GitHub CLI)
```

## Runner Process Specifications

### Runner Tiers and Capacity

```yaml
Light Runner (Tier 1):
  Resources:
    CPU: 2 vCPU
    Memory: 4 GB RAM
    Storage: 20 GB workspace
    Network: 10 Mbps allocated

  Capacity:
    Max per Host: 10 runners
    Concurrent Jobs: 2 per runner
    Job Types:
      - Unit tests
      - Linting
      - Documentation builds
      - Simple scripts

  Performance Targets:
    Startup Time: < 15 seconds
    Job Overhead: < 5 seconds
    Max Job Duration: 30 minutes

Standard Runner (Tier 2):
  Resources:
    CPU: 4 vCPU
    Memory: 8 GB RAM
    Storage: 50 GB workspace
    Network: 25 Mbps allocated

  Capacity:
    Max per Host: 5 runners
    Concurrent Jobs: 1 per runner
    Job Types:
      - Integration tests
      - Application builds
      - Container operations
      - AI/LLM operations

  Performance Targets:
    Startup Time: < 20 seconds
    Job Overhead: < 10 seconds
    Max Job Duration: 60 minutes

Heavy Runner (Tier 3):
  Resources:
    CPU: 8 vCPU
    Memory: 16 GB RAM
    Storage: 100 GB workspace
    Network: 50 Mbps allocated

  Capacity:
    Max per Host: 2 runners
    Concurrent Jobs: 1 per runner
    Job Types:
      - Performance tests
      - Large builds
      - Data processing
      - ML training

  Performance Targets:
    Startup Time: < 30 seconds
    Job Overhead: < 15 seconds
    Max Job Duration: 120 minutes
```

### Workspace Configuration

```yaml
Directory Structure:
  /home/runners/
    ├── runner-{id}/
    │   ├── actions-runner/      # Runner binaries (500 MB)
    │   ├── workspace/            # Active workspace
    │   │   ├── _work/           # GitHub work directory
    │   │   ├── _temp/           # Temporary files
    │   │   └── _tools/          # Cached tools
    │   ├── workspace-warm/       # Pre-warmed workspace
    │   └── config/              # Runner configuration
    │
    └── shared/
        ├── cache/               # Shared package cache (50 GB)
        ├── tools/               # Shared tools (20 GB)
        ├── artifacts/           # Shared artifacts (100 GB)
        └── logs/               # Centralized logs (10 GB)

Workspace Sizes:
  Light Runner:
    - Active: 10 GB
    - Warm: 5 GB
    - Cache: 5 GB
    Total: 20 GB per runner

  Standard Runner:
    - Active: 25 GB
    - Warm: 15 GB
    - Cache: 10 GB
    Total: 50 GB per runner

  Heavy Runner:
    - Active: 50 GB
    - Warm: 30 GB
    - Cache: 20 GB
    Total: 100 GB per runner
```

## Resource Allocation Matrix

### Capacity Planning Table

```markdown
| Host Type | CPU Cores | RAM (GB) | Runners (Light) | Runners (Standard) | Runners (Heavy) | Mixed Config |
|-----------|-----------|----------|-----------------|-------------------|-----------------|--------------|
| Small     | 16        | 64       | 8               | 4                 | 2               | 2L + 2S + 0H |
| Medium    | 24        | 96       | 12              | 6                 | 3               | 4L + 3S + 1H |
| Large     | 32        | 128      | 16              | 8                 | 4               | 6L + 4S + 1H |
| XLarge    | 48        | 192      | 20              | 10                | 5               | 8L + 5S + 2H |

L = Light, S = Standard, H = Heavy
```

### Resource Calculation Formulas

```python
def calculate_host_capacity(cpu_cores, ram_gb):
    """Calculate maximum runner capacity for a host"""

    # Reserve resources for OS and WSL overhead
    available_cpu = cpu_cores * 0.8  # 80% for runners
    available_ram = ram_gb * 0.75    # 75% for runners

    # Calculate capacity per tier
    light_by_cpu = available_cpu / 2      # 2 vCPU per light
    light_by_ram = available_ram / 4      # 4 GB per light
    light_capacity = int(min(light_by_cpu, light_by_ram))

    standard_by_cpu = available_cpu / 4   # 4 vCPU per standard
    standard_by_ram = available_ram / 8   # 8 GB per standard
    standard_capacity = int(min(standard_by_cpu, standard_by_ram))

    heavy_by_cpu = available_cpu / 8      # 8 vCPU per heavy
    heavy_by_ram = available_ram / 16     # 16 GB per heavy
    heavy_capacity = int(min(heavy_by_cpu, heavy_by_ram))

    return {
        "light_max": min(light_capacity, 20),      # Cap at 20
        "standard_max": min(standard_capacity, 10), # Cap at 10
        "heavy_max": min(heavy_capacity, 5)        # Cap at 5
    }

def calculate_mixed_deployment(cpu_cores, ram_gb, workload_profile):
    """Calculate optimal mixed runner deployment"""

    # Workload profile: percentage of light, standard, heavy jobs
    light_pct = workload_profile["light"]
    standard_pct = workload_profile["standard"]
    heavy_pct = workload_profile["heavy"]

    capacity = calculate_host_capacity(cpu_cores, ram_gb)

    # Calculate proportional allocation
    total_weight = (light_pct * 1) + (standard_pct * 2) + (heavy_pct * 4)

    light_runners = int((light_pct / total_weight) * capacity["light_max"])
    standard_runners = int((standard_pct / total_weight) * capacity["standard_max"])
    heavy_runners = int((heavy_pct / total_weight) * capacity["heavy_max"])

    # Verify resources don't exceed limits
    cpu_used = (light_runners * 2) + (standard_runners * 4) + (heavy_runners * 8)
    ram_used = (light_runners * 4) + (standard_runners * 8) + (heavy_runners * 16)

    if cpu_used > cpu_cores * 0.8 or ram_used > ram_gb * 0.75:
        # Scale down proportionally
        scale_factor = min(
            (cpu_cores * 0.8) / cpu_used,
            (ram_gb * 0.75) / ram_used
        )
        light_runners = int(light_runners * scale_factor)
        standard_runners = int(standard_runners * scale_factor)
        heavy_runners = int(heavy_runners * scale_factor)

    return {
        "light": light_runners,
        "standard": standard_runners,
        "heavy": heavy_runners,
        "cpu_utilization": cpu_used / cpu_cores,
        "ram_utilization": ram_used / ram_gb
    }
```

## Storage Specifications

### Storage Layout

```yaml
Disk Configuration:
  System Drive (C:):
    Type: NVMe SSD
    Size: 256-512 GB
    Filesystem: NTFS
    Contents:
      - Windows OS: 50 GB
      - Program Files: 30 GB
      - Windows Updates: 20 GB
      - Page File: 32 GB
      - System Restore: 10 GB
      - Free Space: 114-370 GB

  Runner Drive (D:):
    Type: NVMe SSD Gen4
    Size: 1-2 TB
    Filesystem: NTFS + WSL ext4
    Partition Layout:
      - WSL VHD: 500-1000 GB (ext4)
      - Runner Cache: 200-400 GB (NTFS)
      - Artifacts: 200-400 GB (NTFS)
      - Temp Space: 100-200 GB (NTFS)

  Backup Drive (E:):
    Type: HDD or SSD
    Size: 2-4 TB
    Filesystem: NTFS
    RAID: RAID 1 recommended
    Contents:
      - Configuration backups
      - Log archives
      - Artifact archives
      - System images

Storage Performance Requirements:
  Sequential Read: > 3,500 MB/s
  Sequential Write: > 3,000 MB/s
  Random 4K Read: > 500,000 IOPS
  Random 4K Write: > 400,000 IOPS
  Latency: < 0.1 ms average
```

### Cache Strategy

```yaml
Cache Hierarchy:
  L1 - Memory Cache:
    Size: 2 GB per runner
    Location: RAM
    Contents: Hot data, current job files
    TTL: Job duration

  L2 - Local SSD Cache:
    Size: 10 GB per runner
    Location: Runner workspace
    Contents: Dependencies, tools
    TTL: 7 days

  L3 - Shared SSD Cache:
    Size: 200 GB total
    Location: D:\SharedCache
    Contents: Common packages, artifacts
    TTL: 30 days

  L4 - Network Cache (Optional):
    Size: 1 TB
    Location: Network share
    Contents: Large artifacts, archives
    TTL: 90 days

Cache Management:
  Eviction Policy: LRU (Least Recently Used)
  Cleanup Schedule: Daily at 3 AM
  Reserved Space: 10% always free
  Compression: Enabled for artifacts > 100 MB
```

## Network Resource Allocation

### Bandwidth Allocation

```yaml
Per-Runner Bandwidth:
  Light Runner:
    Guaranteed: 10 Mbps
    Burst: 50 Mbps
    Priority: Low

  Standard Runner:
    Guaranteed: 25 Mbps
    Burst: 100 Mbps
    Priority: Medium

  Heavy Runner:
    Guaranteed: 50 Mbps
    Burst: 200 Mbps
    Priority: High

Total Host Bandwidth:
  Minimum: 100 Mbps dedicated
  Recommended: 1 Gbps dedicated
  Burst: 10 Gbps (if available)

Traffic Shaping:
  QoS Enabled: Yes
  Traffic Classes:
    - GitHub API: High priority
    - Package downloads: Medium priority
    - Log shipping: Low priority
  Rate Limiting:
    - Per connection: 100 Mbps max
    - Per service: Configured limits
```

### Connection Pools

```yaml
Connection Limits:
  Per Runner:
    GitHub API: 10 concurrent
    Package Registries: 5 concurrent
    AI Services: 2 concurrent
    Total: 20 concurrent

  Per Host:
    Total Connections: 200 maximum
    GitHub API: 100 maximum
    External Services: 100 maximum

  Timeouts:
    Connection: 10 seconds
    Read: 30 seconds
    Write: 30 seconds
    Idle: 60 seconds
```

## Software Stack Specifications

### Required Software

```yaml
Base Software:
  Operating System:
    - Windows: Fully patched
    - WSL: Ubuntu 22.04 LTS
    - Drivers: Latest stable

  Runtimes:
    - .NET: 6.0 and 7.0
    - Node.js: 16 LTS, 18 LTS, 20 LTS
    - Python: 3.9, 3.10, 3.11
    - Java: OpenJDK 11, 17
    - Go: 1.20+
    - Ruby: 3.0+

  Version Control:
    - Git: 2.40+
    - Git LFS: 3.3+
    - GitHub CLI: 2.35+

  Build Tools:
    - MSBuild: Latest
    - Make: 4.3+
    - CMake: 3.25+
    - Maven: 3.9+
    - Gradle: 8.0+

  Container Tools (Optional):
    - Docker: 24.0+
    - Podman: 4.5+
    - Buildah: 1.30+

Development Tools:
  Package Managers:
    - npm: 9.0+
    - yarn: 1.22+
    - pip: 23.0+
    - pipenv: Latest
    - NuGet: 6.0+
    - Chocolatey: 2.0+

  Testing Frameworks:
    - Jest: Latest
    - Pytest: 7.0+
    - xUnit: 2.5+
    - Selenium: 4.0+

  Linters and Formatters:
    - ESLint: 8.0+
    - Pylint: 2.17+
    - Black: 23.0+
    - Prettier: 3.0+

  Security Tools:
    - Trivy: Latest
    - SonarScanner: 5.0+
    - OWASP Dependency Check: 8.0+
```

### AI/LLM Integration Tools

```yaml
AI Service Clients:
  OpenAI:
    - Python SDK: openai 1.0+
    - Node.js SDK: openai 4.0+
    - CLI Tool: Custom wrapper

  Anthropic:
    - Python SDK: anthropic 0.5+
    - API Client: Custom implementation

  Azure OpenAI:
    - Azure CLI: 2.50+
    - Python SDK: azure-openai 1.0+

Supporting Libraries:
  - LangChain: 0.0.300+
  - Transformers: 4.35+
  - Tiktoken: 0.5+
  - ChromaDB: 0.4+

Rate Limiting:
  - Default: 60 requests/minute
  - Burst: 100 requests/minute
  - Retry Logic: Exponential backoff
  - Timeout: 30 seconds per request
```

## Monitoring and Metrics

### Resource Monitoring

```yaml
System Metrics:
  Collection Interval: 30 seconds
  Retention: 30 days

  CPU Metrics:
    - Overall utilization
    - Per-core utilization
    - Process CPU usage
    - Context switches
    - Load average

  Memory Metrics:
    - Total usage
    - Available memory
    - Cache usage
    - Swap usage
    - Page faults

  Disk Metrics:
    - IOPS (read/write)
    - Throughput (MB/s)
    - Queue depth
    - Latency
    - Space utilization

  Network Metrics:
    - Bandwidth usage
    - Packet rate
    - Error rate
    - Connection count
    - Latency

Runner Metrics:
  - Job execution time
  - Queue wait time
  - Success/failure rate
  - Resource consumption
  - Cache hit rate
```

### Performance Baselines

```yaml
Expected Performance:
  Light Runner:
    - Job startup: 10-15 seconds
    - Simple build: 1-2 minutes
    - Unit tests: 30 seconds
    - CPU usage: 40-60%
    - Memory usage: 2-3 GB

  Standard Runner:
    - Job startup: 15-20 seconds
    - App build: 5-10 minutes
    - Integration tests: 2-5 minutes
    - CPU usage: 60-80%
    - Memory usage: 4-6 GB

  Heavy Runner:
    - Job startup: 20-30 seconds
    - Large build: 15-30 minutes
    - Performance tests: 10-20 minutes
    - CPU usage: 70-90%
    - Memory usage: 8-12 GB
```

## Scaling Considerations

### Vertical Scaling Options

```yaml
CPU Scaling:
  - Enable Turbo Boost
  - Adjust CPU governor to performance
  - Increase core allocation in WSL
  - Upgrade to higher frequency CPUs

Memory Scaling:
  - Add RAM modules (maintain channel config)
  - Increase WSL memory allocation
  - Enable memory compression
  - Optimize page file settings

Storage Scaling:
  - Add NVMe drives
  - Implement storage tiering
  - Expand existing volumes
  - Upgrade to Gen5 NVMe

Network Scaling:
  - Upgrade to 10 Gbps NICs
  - Implement NIC teaming
  - Add dedicated runner VLANs
  - Enable jumbo frames
```

### Horizontal Scaling Triggers

```yaml
Scale-Out Indicators:
  - Host CPU > 80% sustained
  - Memory usage > 85%
  - Disk I/O saturation
  - Network bandwidth > 80%
  - All runners busy > 10 minutes

Scale-In Indicators:
  - Host CPU < 30% for 30 minutes
  - Memory usage < 40%
  - Idle runners > 50%
  - Low job queue depth
```

## Cost Analysis

### Infrastructure Costs

```yaml
Hardware Costs (One-time):
  Small Host (16 cores, 64 GB):
    - Server: $3,000
    - Storage: $500
    - Network: $200
    Total: $3,700

  Medium Host (32 cores, 128 GB):
    - Server: $6,000
    - Storage: $1,000
    - Network: $400
    Total: $7,400

  Large Host (48 cores, 192 GB):
    - Server: $10,000
    - Storage: $1,500
    - Network: $600
    Total: $12,100

Operating Costs (Monthly):
  Power and Cooling:
    - Small: $50
    - Medium: $100
    - Large: $150

  Software Licensing:
    - Windows Server: $100
    - Monitoring Tools: $50
    - Backup Software: $30

  Network Bandwidth:
    - 1 Gbps: $100
    - 10 Gbps: $500

Cost per Runner (Monthly):
  Light Runner: ~$25
  Standard Runner: ~$50
  Heavy Runner: ~$100
```

### ROI Calculation

```yaml
GitHub Hosted Runner Costs:
  - Linux (2 vCPU): $0.008/minute
  - Windows (2 vCPU): $0.016/minute
  - Large (4 vCPU): $0.032/minute

Monthly Usage (Example):
  - 10,000 minutes Linux: $80
  - 5,000 minutes Windows: $80
  - 2,000 minutes Large: $64
  Total: $224/month

Self-Hosted Savings:
  - Initial Investment: $7,400 (medium host)
  - Monthly Operating: $280
  - Break-even: ~10 months
  - 3-year savings: $5,664
```

## Maintenance Windows

```yaml
Scheduled Maintenance:
  Weekly:
    - Day: Sunday
    - Time: 2-4 AM
    - Tasks:
      - Security patches
      - Log rotation
      - Cache cleanup
      - Metrics collection

  Monthly:
    - First Sunday
    - Extended window: 2-6 AM
    - Tasks:
      - OS updates
      - Driver updates
      - Full backup
      - Performance tuning

  Quarterly:
    - Scheduled with notice
    - Full day window
    - Tasks:
      - Hardware maintenance
      - Major upgrades
      - Disaster recovery test
```

## Document Control

- **Version**: 1.0
- **Author**: Cloud Architecture Team
- **Date**: 2024-10-17
- **Review Cycle**: Quarterly
- **Next Review**: 2025-01-17

---

*This document is part of the Wave 1 GitHub Actions Self-Hosted Runner Infrastructure project.*