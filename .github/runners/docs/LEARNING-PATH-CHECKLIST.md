# Learning Path Checklist for GitHub Actions Self-Hosted Runners

Track your progress toward mastery with role-specific learning paths. Each skill includes prerequisites, resources, and estimated time to competency.

## How to Use This Checklist

1. **Select your primary role** below
2. **Complete prerequisites** before advancing
3. **Check off skills** as you master them
4. **Track your progress** percentage
5. **Share achievements** with your team

---

# Developer Learning Path

**Role**: Software developers implementing workflows and AI automation
**Goal**: Create and maintain CI/CD workflows with AI enhancement
**Time to Competency**: 2-3 weeks (part-time learning)

## Foundation Skills (Week 1)

### GitHub Actions Basics
- [ ] **Understand workflow syntax** (2 hours)
  - Prerequisites: Git, YAML basics
  - Resources: [Workflow syntax docs](https://docs.github.com/actions/reference/workflow-syntax)
  - Validate: Create a "Hello World" workflow

- [ ] **Master workflow triggers** (1 hour)
  - Prerequisites: GitHub Actions basics
  - Resources: [Events that trigger workflows](https://docs.github.com/actions/reference/events-that-trigger-workflows)
  - Validate: Implement 3 different trigger types

- [ ] **Configure job dependencies** (1 hour)
  - Prerequisites: Workflow basics
  - Resources: WORKFLOW-REFERENCE.md
  - Validate: Create multi-job workflow with dependencies

- [ ] **Implement environment variables and secrets** (1 hour)
  - Prerequisites: Workflow creation
  - Resources: [Using secrets](https://docs.github.com/actions/security-guides/encrypted-secrets)
  - Validate: Use secrets in a workflow

### Self-Hosted Runners
- [ ] **Deploy first runner** (30 minutes)
  - Prerequisites: WSL or Linux access
  - Resources: Lab 1 in HANDS-ON-LABS.md
  - Validate: Runner appears online in GitHub

- [ ] **Target runners with labels** (30 minutes)
  - Prerequisites: Runner deployment
  - Resources: quick-start-guides.md
  - Validate: Workflow runs on specific runner

- [ ] **Implement sparse checkout** (30 minutes)
  - Prerequisites: Large repository
  - Resources: ONBOARDING-TUTORIAL.md Part 2
  - Validate: 70% faster checkout achieved

## Intermediate Skills (Week 2)

### AI Integration
- [ ] **Configure AI API access** (1 hour)
  - Prerequisites: AI API key
  - Resources: Lab 2 in HANDS-ON-LABS.md
  - Validate: Successfully call AI API

- [ ] **Implement AI PR review** (2 hours)
  - Prerequisites: AI API configuration
  - Resources: ai-pr-review.yml workflow
  - Validate: AI reviews posted on PRs

- [ ] **Create custom AI prompts** (2 hours)
  - Prerequisites: AI PR review working
  - Resources: ONBOARDING-TUTORIAL.md Part 4
  - Validate: Stack-specific reviews working

- [ ] **Build AI issue responder** (2 hours)
  - Prerequisites: AI integration
  - Resources: Lab 4 in HANDS-ON-LABS.md
  - Validate: AI responds to issue commands

### Automation
- [ ] **Implement auto-fix workflows** (2 hours)
  - Prerequisites: Linting rules configured
  - Resources: Lab 3 in HANDS-ON-LABS.md
  - Validate: Code automatically fixed and committed

- [ ] **Handle merge conflicts** (1 hour)
  - Prerequisites: Auto-fix workflows
  - Resources: troubleshooting-guide.md
  - Validate: Graceful conflict resolution

- [ ] **Create reusable workflows** (1 hour)
  - Prerequisites: Multiple similar workflows
  - Resources: reusable-ai-workflow.yml
  - Validate: Workflow reused across repos

## Advanced Skills (Week 3)

### Performance Optimization
- [ ] **Benchmark workflow performance** (2 hours)
  - Prerequisites: Running workflows
  - Resources: Lab 5 in HANDS-ON-LABS.md
  - Validate: Baseline metrics captured

- [ ] **Optimize for <30s starts** (2 hours)
  - Prerequisites: Performance baselines
  - Resources: ONBOARDING-TUTORIAL.md Part 5
  - Validate: Job starts in <30 seconds

- [ ] **Implement caching strategies** (1 hour)
  - Prerequisites: Dependency-heavy workflows
  - Resources: [Caching dependencies](https://docs.github.com/actions/using-workflows/caching-dependencies)
  - Validate: 50% faster dependency installation

### Security
- [ ] **Implement least privilege** (1 hour)
  - Prerequisites: Understanding permissions
  - Resources: workflow-security-guide.md
  - Validate: Minimal permissions in all workflows

- [ ] **Configure secret scanning** (30 minutes)
  - Prerequisites: Organization admin access
  - Resources: Security quick start guide
  - Validate: Secret scanning enabled

- [ ] **Set up audit logging** (1 hour)
  - Prerequisites: Compliance requirements
  - Resources: ONBOARDING-TUTORIAL.md Part 3
  - Validate: Audit logs being collected

## Expert Skills (Optional)

### Advanced Automation
- [ ] **Multi-repo workflow orchestration** (4 hours)
  - Prerequisites: All intermediate skills
  - Resources: GitHub Actions docs
  - Validate: Cross-repo workflows working

- [ ] **Dynamic workflow generation** (4 hours)
  - Prerequisites: Advanced YAML/JSON
  - Resources: Matrix builds documentation
  - Validate: Workflows generated from config

- [ ] **Custom GitHub Actions development** (8 hours)
  - Prerequisites: JavaScript/TypeScript
  - Resources: [Creating actions](https://docs.github.com/actions/creating-actions)
  - Validate: Custom action published

### AI Enhancement
- [ ] **Fine-tune AI models** (8 hours)
  - Prerequisites: ML knowledge
  - Resources: AI provider documentation
  - Validate: Custom model deployed

- [ ] **Implement AI code generation** (4 hours)
  - Prerequisites: AI integration mastery
  - Resources: Advanced AI guides
  - Validate: Code generated from issues

---

# DevOps Engineer Learning Path

**Role**: DevOps engineers managing infrastructure and operations
**Goal**: Deploy and maintain production runner infrastructure
**Time to Competency**: 3-4 weeks (part-time learning)

## Foundation Skills (Week 1)

### Infrastructure Setup
- [ ] **Install WSL 2.0** (1 hour)
  - Prerequisites: Windows 10/11
  - Resources: [WSL installation](https://docs.microsoft.com/windows/wsl/install)
  - Validate: Ubuntu 22.04 running

- [ ] **Deploy 5 production runners** (2 hours)
  - Prerequisites: WSL, GitHub org access
  - Resources: ONBOARDING-TUTORIAL.md Part 3
  - Validate: All runners online

- [ ] **Configure runner labels** (30 minutes)
  - Prerequisites: Runners deployed
  - Resources: setup-runner.sh script
  - Validate: Specialized labels working

- [ ] **Set up systemd services** (1 hour)
  - Prerequisites: Linux knowledge
  - Resources: Runner installation guide
  - Validate: Runners start on boot

### Monitoring Setup
- [ ] **Implement health checks** (1 hour)
  - Prerequisites: Runners deployed
  - Resources: ONBOARDING-TUTORIAL.md Part 5
  - Validate: Monitoring script running

- [ ] **Configure alerting** (2 hours)
  - Prerequisites: Monitoring tools
  - Resources: monitoring scripts
  - Validate: Alerts firing correctly

- [ ] **Create operations dashboard** (2 hours)
  - Prerequisites: Metrics collection
  - Resources: Lab 5 dashboard example
  - Validate: Real-time metrics displayed

## Intermediate Skills (Week 2)

### Performance Management
- [ ] **Analyze performance bottlenecks** (2 hours)
  - Prerequisites: Running workloads
  - Resources: Lab 5 in HANDS-ON-LABS.md
  - Validate: Bottlenecks identified

- [ ] **Optimize runner configuration** (2 hours)
  - Prerequisites: Performance analysis
  - Resources: optimize-runners.sh
  - Validate: 50% performance improvement

- [ ] **Implement caching** (1 hour)
  - Prerequisites: Understanding workflows
  - Resources: Performance guides
  - Validate: Cache hit rate >80%

- [ ] **Configure runner autoscaling** (4 hours)
  - Prerequisites: Cloud platform knowledge
  - Resources: Actions Runner Controller docs
  - Validate: Autoscaling working

### Maintenance Operations
- [ ] **Automate runner updates** (2 hours)
  - Prerequisites: Script knowledge
  - Resources: setup-runner.sh --update
  - Validate: Automated update process

- [ ] **Implement backup procedures** (2 hours)
  - Prerequisites: Understanding runner state
  - Resources: maintenance.sh script
  - Validate: Backup/restore tested

- [ ] **Create disaster recovery plan** (3 hours)
  - Prerequisites: Infrastructure knowledge
  - Resources: Best practices guides
  - Validate: DR plan documented

## Advanced Skills (Week 3-4)

### Infrastructure as Code
- [ ] **Terraform runner deployment** (4 hours)
  - Prerequisites: Terraform basics
  - Resources: Terraform modules
  - Validate: IaC deployment working

- [ ] **Ansible configuration management** (4 hours)
  - Prerequisites: Ansible knowledge
  - Resources: Ansible playbooks
  - Validate: Configuration automated

- [ ] **Kubernetes runner deployment** (8 hours)
  - Prerequisites: K8s knowledge
  - Resources: ARC documentation
  - Validate: K8s runners operational

### Cost Optimization
- [ ] **Implement cost tracking** (2 hours)
  - Prerequisites: Metrics collection
  - Resources: Cost analysis scripts
  - Validate: Cost reports generated

- [ ] **Optimize resource allocation** (3 hours)
  - Prerequisites: Usage patterns
  - Resources: Performance data
  - Validate: 30% cost reduction

- [ ] **Implement spot instances** (4 hours)
  - Prerequisites: Cloud platform
  - Resources: Cloud provider docs
  - Validate: Spot runners working

---

# Platform Engineer Learning Path

**Role**: Platform engineers building developer platforms
**Goal**: Create self-service CI/CD platform with AI capabilities
**Time to Competency**: 4-5 weeks (part-time learning)

## Foundation Skills (Week 1)

### Platform Architecture
- [ ] **Design runner architecture** (4 hours)
  - Prerequisites: System design knowledge
  - Resources: Architecture diagrams
  - Validate: Architecture documented

- [ ] **Implement runner routing** (2 hours)
  - Prerequisites: Label understanding
  - Resources: ONBOARDING-TUTORIAL.md Part 4
  - Validate: Smart routing working

- [ ] **Create platform abstractions** (4 hours)
  - Prerequisites: API design
  - Resources: Platform engineering guides
  - Validate: Abstractions documented

### Developer Experience
- [ ] **Build workflow templates** (3 hours)
  - Prerequisites: Workflow expertise
  - Resources: Reusable workflows
  - Validate: Templates in use

- [ ] **Create self-service portal** (8 hours)
  - Prerequisites: Web development
  - Resources: GitHub Apps docs
  - Validate: Portal operational

- [ ] **Implement workflow catalog** (4 hours)
  - Prerequisites: Template creation
  - Resources: Best practices
  - Validate: Catalog published

## Intermediate Skills (Week 2-3)

### Integration
- [ ] **Integrate with existing CI/CD** (4 hours)
  - Prerequisites: CI/CD knowledge
  - Resources: Integration guides
  - Validate: Hybrid pipeline working

- [ ] **Connect monitoring systems** (4 hours)
  - Prerequisites: Observability tools
  - Resources: Metrics exporters
  - Validate: Metrics in Grafana

- [ ] **Implement SSO/SAML** (3 hours)
  - Prerequisites: Auth knowledge
  - Resources: GitHub Enterprise docs
  - Validate: SSO working

### Compliance
- [ ] **Implement audit logging** (2 hours)
  - Prerequisites: Compliance requirements
  - Resources: Audit guides
  - Validate: Logs exported to SIEM

- [ ] **Configure policy enforcement** (4 hours)
  - Prerequisites: Policy requirements
  - Resources: OPA/Gatekeeper
  - Validate: Policies enforced

- [ ] **Create compliance reports** (3 hours)
  - Prerequisites: Audit data
  - Resources: Reporting tools
  - Validate: Reports generated

## Advanced Skills (Week 4-5)

### Platform Scaling
- [ ] **Multi-region deployment** (8 hours)
  - Prerequisites: Cloud architecture
  - Resources: Multi-region guides
  - Validate: Global deployment

- [ ] **Implement federation** (6 hours)
  - Prerequisites: Distributed systems
  - Resources: Federation patterns
  - Validate: Cross-org workflows

- [ ] **Build platform APIs** (8 hours)
  - Prerequisites: API development
  - Resources: REST/GraphQL
  - Validate: APIs documented

### Innovation
- [ ] **Implement ChatOps** (4 hours)
  - Prerequisites: Chat platforms
  - Resources: Slack/Teams integrations
  - Validate: ChatOps commands working

- [ ] **Create AI workflow builder** (8 hours)
  - Prerequisites: AI integration
  - Resources: Visual builders
  - Validate: No-code workflows

- [ ] **Develop platform metrics** (4 hours)
  - Prerequisites: KPI knowledge
  - Resources: DORA metrics
  - Validate: Dashboards created

---

# Security Engineer Learning Path

**Role**: Security engineers ensuring secure CI/CD operations
**Goal**: Implement security controls and compliance
**Time to Competency**: 3-4 weeks (part-time learning)

## Foundation Skills (Week 1)

### Security Fundamentals
- [ ] **Understand GitHub Actions security model** (2 hours)
  - Prerequisites: Security basics
  - Resources: [Security hardening](https://docs.github.com/actions/security-guides)
  - Validate: Security model documented

- [ ] **Implement least privilege** (2 hours)
  - Prerequisites: IAM knowledge
  - Resources: workflow-security-guide.md
  - Validate: Permissions minimized

- [ ] **Configure secret management** (2 hours)
  - Prerequisites: Secrets knowledge
  - Resources: Secrets documentation
  - Validate: Secrets properly managed

- [ ] **Enable security scanning** (1 hour)
  - Prerequisites: Org admin access
  - Resources: Security settings
  - Validate: Scanning enabled

### Network Security
- [ ] **Configure network isolation** (2 hours)
  - Prerequisites: Network knowledge
  - Resources: Firewall guides
  - Validate: Network rules applied

- [ ] **Implement egress filtering** (2 hours)
  - Prerequisites: Firewall knowledge
  - Resources: iptables guides
  - Validate: Egress controlled

- [ ] **Set up VPN/proxy** (3 hours)
  - Prerequisites: VPN knowledge
  - Resources: Network guides
  - Validate: Secure connectivity

## Intermediate Skills (Week 2)

### Vulnerability Management
- [ ] **Implement dependency scanning** (2 hours)
  - Prerequisites: Package managers
  - Resources: Dependabot docs
  - Validate: Vulnerabilities detected

- [ ] **Configure SAST/DAST** (4 hours)
  - Prerequisites: Security tools
  - Resources: Security scanners
  - Validate: Scans automated

- [ ] **Create security workflows** (3 hours)
  - Prerequisites: Workflow knowledge
  - Resources: Security templates
  - Validate: Security checks running

### Compliance
- [ ] **Implement audit logging** (2 hours)
  - Prerequisites: Compliance needs
  - Resources: Audit guides
  - Validate: Logs collected

- [ ] **Configure retention policies** (1 hour)
  - Prerequisites: Compliance requirements
  - Resources: Retention guides
  - Validate: Policies enforced

- [ ] **Create compliance reports** (3 hours)
  - Prerequisites: Reporting tools
  - Resources: Compliance frameworks
  - Validate: Reports generated

## Advanced Skills (Week 3-4)

### Threat Detection
- [ ] **Implement anomaly detection** (4 hours)
  - Prerequisites: ML basics
  - Resources: Anomaly detection
  - Validate: Anomalies detected

- [ ] **Configure SIEM integration** (4 hours)
  - Prerequisites: SIEM knowledge
  - Resources: Integration guides
  - Validate: Events in SIEM

- [ ] **Create incident response** (6 hours)
  - Prerequisites: IR knowledge
  - Resources: IR playbooks
  - Validate: Playbooks tested

### Advanced Security
- [ ] **Implement zero trust** (8 hours)
  - Prerequisites: Zero trust concepts
  - Resources: Zero trust guides
  - Validate: Controls implemented

- [ ] **Configure supply chain security** (6 hours)
  - Prerequisites: SLSA framework
  - Resources: Supply chain guides
  - Validate: Attestations working

- [ ] **Build security metrics** (4 hours)
  - Prerequisites: KRI knowledge
  - Resources: Security KPIs
  - Validate: Metrics dashboard

---

# Progress Tracking

## Overall Competency Levels

### Beginner (0-25% Complete)
- Understanding basic concepts
- Following tutorials
- Setting up first runners
- **Time Investment**: 1 week

### Intermediate (26-50% Complete)
- Implementing workflows independently
- Basic troubleshooting
- Optimizing performance
- **Time Investment**: 2-3 weeks

### Advanced (51-75% Complete)
- Designing solutions
- Complex integrations
- Teaching others
- **Time Investment**: 4-6 weeks

### Expert (76-100% Complete)
- Architecting platforms
- Innovation and research
- Organization-wide impact
- **Time Investment**: 8+ weeks

## Skill Assessment Rubric

Rate yourself on each skill area (1-5 scale):

### Technical Skills
- [ ] **GitHub Actions** (1-5): _____
- [ ] **Self-Hosted Runners** (1-5): _____
- [ ] **AI Integration** (1-5): _____
- [ ] **Performance Optimization** (1-5): _____
- [ ] **Security Implementation** (1-5): _____

### Operational Skills
- [ ] **Monitoring & Alerting** (1-5): _____
- [ ] **Troubleshooting** (1-5): _____
- [ ] **Maintenance** (1-5): _____
- [ ] **Documentation** (1-5): _____
- [ ] **Training Others** (1-5): _____

## Certification Path

### Level 1: Runner Operator
**Requirements**:
- Deploy 5 runners
- Create 5 workflows
- Achieve <60s job starts
- **Badge**: 🥉 Bronze

### Level 2: Automation Engineer
**Requirements**:
- Implement AI workflows
- Create reusable components
- Achieve <30s job starts
- **Badge**: 🥈 Silver

### Level 3: Platform Architect
**Requirements**:
- Design multi-repo platform
- Implement advanced security
- Train 5 team members
- **Badge**: 🥇 Gold

### Level 4: Innovation Leader
**Requirements**:
- Create new capabilities
- Contribute to community
- Drive organizational change
- **Badge**: 💎 Diamond

---

# Quick Reference Links

## Essential Documentation
- [README.md](../README.md) - Project overview
- [ONBOARDING-TUTORIAL.md](./ONBOARDING-TUTORIAL.md) - Step-by-step guide
- [HANDS-ON-LABS.md](./HANDS-ON-LABS.md) - Practical exercises
- [COMMON-PITFALLS.md](./COMMON-PITFALLS.md) - Mistakes to avoid
- [troubleshooting-guide.md](./troubleshooting-guide.md) - Problem solving

## Workflow References
- [WORKFLOW-REFERENCE.md](./WORKFLOW-REFERENCE.md) - Workflow documentation
- [workflow-security-guide.md](./workflow-security-guide.md) - Security best practices
- [local-testing-guide.md](./local-testing-guide.md) - Testing workflows

## Scripts and Tools
- [setup-runner.sh](../scripts/setup-runner.sh) - Runner installation
- [ai-review.sh](../scripts/ai-review.sh) - AI review script
- [ai-agent.sh](../scripts/ai-agent.sh) - AI agent script
- [ai-autofix.sh](../scripts/ai-autofix.sh) - Auto-fix script

## External Resources
- [GitHub Actions Documentation](https://docs.github.com/actions)
- [GitHub Actions Community](https://github.community/c/github-actions)
- [Actions Marketplace](https://github.com/marketplace?type=actions)
- [Runner Releases](https://github.com/actions/runner/releases)

---

# Share Your Progress

## Team Collaboration
1. **Share this checklist** with your team
2. **Track collective progress** in a shared document
3. **Celebrate milestones** together
4. **Create team challenges** for learning

## Community Engagement
1. **Share success stories** in GitHub Discussions
2. **Contribute improvements** via pull requests
3. **Help others** in community forums
4. **Write blog posts** about your journey

## Continuous Learning
1. **Review monthly** to track progress
2. **Update skills** as platform evolves
3. **Learn from failures** and document them
4. **Teach others** to reinforce knowledge

---

**Version**: 1.0.0
**Last Updated**: 2025-10-17
**Total Skills**: 120+
**Average Time to Expert**: 8-12 weeks

*Remember: Learning is a journey, not a destination. Focus on consistent progress rather than perfection.*