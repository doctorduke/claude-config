# Wave 2: Infrastructure Provisioning Specification

## CONTEXT / BACKGROUND

This specification defines the infrastructure provisioning phase (Wave 2) for establishing self-hosted GitHub Actions runners. Wave 2 begins after Wave 1 completes with:
- **Architecture Documentation** (`docs/architecture.md`): System design, runner topology, scaling strategy
- **Requirements Documentation** (`docs/requirements.md`): Technical requirements, constraints, success criteria

Wave 2 focuses on parallel execution by 5 specialized agents to provision N self-hosted runners on Windows + WSL 2.0 environments, with proper configuration, security, and validation.

## OUTCOMES / SUCCESS CRITERIA

### Primary Success Criteria
- [ ] N self-hosted GitHub Actions runners online and accepting jobs
- [ ] All runners visible in GitHub organization settings
- [ ] Runner groups configured with proper access controls
- [ ] Network connectivity validated (outbound HTTPS to GitHub)
- [ ] Security tokens and secrets properly configured
- [ ] Automated setup scripts tested and documented
- [ ] Validation suite confirms all components operational

### Measurable Outcomes
- Runner registration: 100% of N runners online
- Job acceptance rate: >95% within 30 seconds
- Network latency: <100ms to api.github.com
- Script execution: Zero manual interventions required
- Security compliance: All tokens with minimal required scopes

## REQUIREMENTS

### Deployment Engineer Requirements
- Install GitHub Actions runner software natively on WSL 2.0
- Create cross-platform setup scripts (POSIX-compliant bash)
- Configure runner services for automatic startup
- Implement runner update mechanisms
- Document installation prerequisites and dependencies

### DevOps Troubleshooter Requirements
- Configure GitHub organization runner groups
- Establish runner label taxonomy
- Set up runner access policies
- Create runner monitoring dashboards
- Document troubleshooting procedures

### Network Engineer Requirements
- Validate outbound HTTPS connectivity to GitHub endpoints
- Document firewall rules and proxy configurations
- Test runner-to-GitHub API communication
- Measure and optimize network latency
- Create network diagnostic scripts

### Security Auditor Requirements
- Generate and configure Personal Access Tokens (PATs)
- Define GITHUB_TOKEN permission scopes
- Set up organization and repository secrets
- Implement secret rotation policies
- Document security best practices

### DX Optimizer Requirements
- Create developer onboarding automation
- Build validation and health check scripts
- Implement runner performance monitoring
- Create troubleshooting runbooks
- Design self-service runner management tools

## DELIVERABLES

### Scripts and Automation
```
scripts/
├── setup-runner.sh           # Main runner installation script
├── validate-setup.sh          # Post-installation validation
├── configure-labels.sh        # Runner label configuration
├── test-connectivity.sh       # Network connectivity tests
├── rotate-tokens.sh          # Security token rotation
├── health-check.sh           # Runner health monitoring
└── teardown-runner.sh        # Clean uninstallation script
```

### Configuration Files
```
config/
├── runner-config.yaml         # Runner configuration template
├── runner-groups.json         # Runner group definitions
├── network-requirements.md    # Network configuration docs
├── security-policy.json       # Security policies
└── monitoring-config.yaml     # Monitoring configuration
```

### Documentation
```
docs/
├── setup-guide.md            # Step-by-step setup instructions
├── troubleshooting.md        # Common issues and solutions
├── security-guide.md         # Security best practices
├── network-topology.md       # Network architecture
└── maintenance-guide.md      # Ongoing maintenance procedures
```

## AGENT PROMPT SPECS

### Deployment Engineer Prompt

```
You are a deployment engineer specializing in GitHub Actions runner infrastructure. Your primary objective is to install and configure N self-hosted GitHub Actions runners natively on WSL 2.0 environments.

CONTEXT:
- Working with Windows + WSL 2.0 systems
- Runners must be installed natively (NOT using Docker)
- Architecture and requirements defined in Wave 1 outputs

YOUR TASKS:
1. Create setup-runner.sh script that:
   - Detects operating system (WSL, Linux, macOS)
   - Downloads correct runner binary from GitHub
   - Configures runner with organization URL and registration token
   - Sets up runner as a systemd service (Linux/WSL) or launchd (macOS)
   - Applies labels: self-hosted, linux, x64, ai-agent
   - Handles runner updates automatically

2. Implementation Requirements:
   - Use POSIX-compliant bash (no bashisms)
   - Include error handling and rollback capabilities
   - Log all operations to setup.log
   - Support idempotent execution (safe to run multiple times)
   - Accept parameters: GITHUB_ORG, RUNNER_TOKEN, RUNNER_NAME, RUNNER_LABELS

3. Create teardown-runner.sh for clean uninstallation

4. Document all prerequisites:
   - Required system packages
   - Minimum system requirements (CPU, RAM, disk)
   - User permissions needed
   - Environment variables required

DELIVERABLES:
- scripts/setup-runner.sh (executable, POSIX-compliant)
- scripts/teardown-runner.sh (complete cleanup)
- docs/setup-guide.md (step-by-step instructions)
- config/runner-config.yaml (configuration template)

CONSTRAINTS:
- Must work on Windows+WSL 2.0, Ubuntu 20.04+, macOS 12+
- No Docker containers for runners
- Respect GitHub API rate limits
- Handle network interruptions gracefully
```

### DevOps Troubleshooter Prompt

```
You are a DevOps troubleshooter specializing in GitHub Actions infrastructure management. Your objective is to configure runner groups, labels, and troubleshooting systems for N self-hosted runners.

CONTEXT:
- Organization-level GitHub Actions runners being deployed
- Multiple runner groups needed for different workload types
- Require granular access control and monitoring

YOUR TASKS:
1. Configure Runner Groups:
   - Create runner groups via GitHub API/UI
   - Define access policies per group
   - Map runners to appropriate groups
   - Document group naming conventions

2. Establish Label Taxonomy:
   - Define standard labels (self-hosted, linux, x64, ai-agent)
   - Create workload-specific labels
   - Implement label validation
   - Document label usage guidelines

3. Create configure-labels.sh script that:
   - Applies labels to runners programmatically
   - Validates label consistency
   - Reports label configuration status
   - Supports bulk label updates

4. Build Troubleshooting Framework:
   - Common error patterns and resolutions
   - Runner diagnostic commands
   - Log analysis procedures
   - Performance bottleneck identification

DELIVERABLES:
- scripts/configure-labels.sh (label management)
- config/runner-groups.json (group definitions)
- docs/troubleshooting.md (troubleshooting guide)
- monitoring/alerts.yaml (alert definitions)

CONSTRAINTS:
- Use GitHub REST API v3 or GraphQL API
- Respect API rate limits (5000 requests/hour)
- Maintain backwards compatibility
- Follow principle of least privilege
```

### Network Engineer Prompt

```
You are a network engineer specializing in CI/CD infrastructure. Your objective is to validate and optimize network connectivity for N self-hosted GitHub Actions runners.

CONTEXT:
- Runners require outbound HTTPS access to GitHub
- Operating behind corporate firewalls/proxies possible
- Network reliability critical for job execution

YOUR TASKS:
1. Validate Connectivity Requirements:
   - Test connectivity to github.com, api.github.com, *.actions.githubusercontent.com
   - Verify SSL/TLS certificate validation
   - Check DNS resolution reliability
   - Measure latency and bandwidth

2. Create test-connectivity.sh script that:
   - Tests all required GitHub endpoints
   - Validates HTTPS/TLS connections
   - Checks proxy configurations if present
   - Reports connectivity status and metrics
   - Supports continuous monitoring mode

3. Document Network Requirements:
   - Required firewall rules (outbound ports/protocols)
   - Proxy configuration instructions
   - DNS configuration best practices
   - Network bandwidth requirements

4. Optimize Network Performance:
   - Implement connection pooling
   - Configure keep-alive settings
   - Optimize DNS caching
   - Document CDN endpoint usage

DELIVERABLES:
- scripts/test-connectivity.sh (network validation)
- docs/network-topology.md (network architecture)
- config/firewall-rules.txt (required rules)
- monitoring/network-metrics.yaml (monitoring config)

CONSTRAINTS:
- Outbound HTTPS only (no inbound connections)
- Support proxy environments (HTTP_PROXY, HTTPS_PROXY)
- Handle intermittent connectivity gracefully
- Respect rate limits and connection limits
```

### Security Auditor Prompt

```
You are a security auditor specializing in CI/CD security. Your objective is to implement secure token management and access controls for N self-hosted GitHub Actions runners.

CONTEXT:
- Runners require authentication tokens for GitHub
- Organization and repository secrets need configuration
- Security principle: fail secure, minimal permissions

YOUR TASKS:
1. Configure Authentication:
   - Generate Personal Access Tokens (PATs) with minimal scopes
   - Document required token permissions
   - Implement token rotation schedule
   - Secure token storage mechanisms

2. Set Up Secrets Management:
   - Configure organization-level secrets
   - Set repository-specific secrets
   - Implement secret access policies
   - Document secret naming conventions

3. Create rotate-tokens.sh script that:
   - Rotates PATs programmatically
   - Updates runner configurations
   - Validates new tokens
   - Maintains audit trail
   - Supports zero-downtime rotation

4. Define Security Policies:
   - Token scope requirements (minimum viable permissions)
   - Secret rotation schedules
   - Access control matrices
   - Compliance requirements

DELIVERABLES:
- scripts/rotate-tokens.sh (token rotation automation)
- config/security-policy.json (security policies)
- docs/security-guide.md (security best practices)
- audit/compliance-checklist.md (compliance validation)

CONSTRAINTS:
- Follow principle of least privilege
- No hardcoded credentials in scripts
- Use environment variables or secure vaults
- Implement defense in depth
- Support SOC2/ISO27001 compliance requirements
```

### DX Optimizer Prompt

```
You are a developer experience optimizer specializing in CI/CD automation. Your objective is to create developer-friendly automation and validation tools for N self-hosted GitHub Actions runners.

CONTEXT:
- Developers need self-service runner management
- Validation critical for troubleshooting
- Automation should reduce operational overhead

YOUR TASKS:
1. Create Developer Automation:
   - Build validate-setup.sh comprehensive validation script
   - Implement health-check.sh for continuous monitoring
   - Create runner performance profiling tools
   - Design self-service management interface

2. Validation Script Requirements:
   - Check runner registration status
   - Validate network connectivity
   - Verify label configuration
   - Test job execution capability
   - Report detailed status with remediation steps

3. Health Monitoring Implementation:
   - Real-time runner status dashboard
   - Performance metrics collection
   - Automatic issue detection
   - Predictive failure analysis

4. Developer Documentation:
   - Quick start guide
   - Common workflows
   - Performance tuning guide
   - Integration examples

DELIVERABLES:
- scripts/validate-setup.sh (comprehensive validation)
- scripts/health-check.sh (health monitoring)
- docs/maintenance-guide.md (maintenance procedures)
- dashboard/runner-status.html (status dashboard)

CONSTRAINTS:
- Scripts must provide clear, actionable output
- Support both interactive and CI/CD usage
- Minimize false positives in monitoring
- Respect user time (fast execution)
- Support multiple output formats (JSON, text, HTML)
```

## CONSTRAINTS

### Technical Constraints
- **Platform**: Windows + WSL 2.0 primary, with macOS/Linux compatibility
- **Runner Type**: Native installation only (no Docker containers)
- **Network**: Outbound HTTPS only, no inbound connections required
- **Authentication**: Token-based (PATs and GITHUB_TOKEN)
- **API Limits**: Respect GitHub API rate limits (5000/hour authenticated)

### Operational Constraints
- **Availability**: 99.9% uptime target for runner fleet
- **Performance**: Job pickup within 30 seconds
- **Scalability**: Support 1-100 runners per organization
- **Maintenance**: Zero-downtime updates required

### Security Constraints
- **Permissions**: Minimal required scopes only
- **Secrets**: No hardcoded credentials
- **Audit**: All actions must be logged
- **Compliance**: SOC2 Type II compatible

## PRIORITIES (MoSCoW)

### Must Have
- Runner installation and registration scripts
- Basic network connectivity validation
- Token configuration with minimal permissions
- Runner group and label setup
- Basic validation scripts

### Should Have
- Automated token rotation
- Comprehensive troubleshooting documentation
- Performance monitoring dashboard
- Health check automation
- Cross-platform compatibility

### Could Have
- Advanced performance profiling
- Predictive failure detection
- Self-healing capabilities
- Custom runner images
- Integration with existing monitoring tools

### Won't Have (This Phase)
- Kubernetes-based runners
- Docker container runners
- Custom runner hardware
- Multi-region deployment
- Advanced cost optimization

## DEPENDENCIES

### Wave 1 Outputs (Required)
- `docs/architecture.md`: System design and topology
- `docs/requirements.md`: Technical and business requirements
- GitHub organization access with admin permissions
- Target infrastructure provisioned (Windows+WSL systems)

### External Dependencies
- GitHub Actions runner binaries (https://github.com/actions/runner/releases)
- GitHub REST API v3 (https://docs.github.com/rest)
- GitHub GraphQL API (https://docs.github.com/graphql)
- Organization owner or admin access

### Tooling Dependencies
- bash 4.0+ (POSIX mode)
- curl or wget for downloads
- jq for JSON processing
- systemd (Linux/WSL) or launchd (macOS)
- Git 2.28+

## REFERENCES

### GitHub Documentation
- [Self-hosted runners overview](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners)
- [Adding self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners/adding-self-hosted-runners)
- [Managing runner groups](https://docs.github.com/en/actions/hosting-your-own-runners/managing-access-to-self-hosted-runners-using-groups)
- [REST API - Actions runners](https://docs.github.com/en/rest/actions/self-hosted-runners)
- [Personal Access Tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)

### Technical References
- [WSL 2.0 Documentation](https://docs.microsoft.com/en-us/windows/wsl/)
- [systemd Service Management](https://systemd.io/)
- [POSIX Shell Specification](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html)
- [GitHub Actions Runner Architecture](https://github.com/actions/runner/blob/main/docs/design/runner-architecture.md)

### Security References
- [GitHub Actions Security Hardening](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- [OWASP CI/CD Security](https://owasp.org/www-project-devsecops-guideline/)
- [CIS GitHub Benchmark](https://www.cisecurity.org/benchmark/github)

## VALIDATION CHECKLIST

### Pre-Deployment
- [ ] Wave 1 artifacts reviewed and approved
- [ ] GitHub organization access confirmed
- [ ] Target infrastructure accessible
- [ ] Required tools installed

### Post-Deployment
- [ ] All N runners online and registered
- [ ] Runner groups configured correctly
- [ ] Labels applied consistently
- [ ] Network connectivity validated
- [ ] Security tokens configured
- [ ] Validation scripts passing
- [ ] Documentation complete
- [ ] Monitoring operational

### Acceptance Criteria
- [ ] Successful test workflow execution
- [ ] Performance benchmarks met
- [ ] Security scan passed
- [ ] Documentation review complete
- [ ] Handover to operations team

---

*Document Version: 1.0.0*
*Last Updated: 2025-10-17*
*Next Review: Post Wave 2 Completion*