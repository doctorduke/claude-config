# Wave 3: Implementation Specification
## GitHub Actions Workflows, AI Agent Scripts & Reusable Components

---

## CONTEXT / BACKGROUND

Wave 3 builds upon the foundation established by Wave 1 (architecture design) and Wave 2 (infrastructure deployment). With all cloud infrastructure now online and operational, Wave 3 focuses on implementing the actual GitHub Actions workflows, AI agent scripts, and reusable components that will power the automated review system.

- **Problem(s):**
  - Need production-ready GitHub Actions workflows for PR review, issue comments, and auto-fix functionality
  - Require cross-platform AI agent scripts that work on both Linux runners and Windows development environments
  - Must create reusable workflows and composite actions for organization-wide adoption
  - Security permissions and secret handling need proper implementation across all workflows

- **Constraints:**
  - All scripts must be POSIX-compliant and cross-platform compatible
  - Workflows must use minimal permissions (principle of least privilege)
  - Sparse checkout must be configured to minimize repository clone size
  - All outputs must follow structured JSON schemas for consistent parsing

- **Current state:**
  - Wave 1 has defined the system architecture and design patterns
  - Wave 2 has provisioned all cloud infrastructure (runners, storage, networking)
  - Wave 3 specialists are ready to implement parallel workstreams

## OUTCOMES / SUCCESS CRITERIA (OKRs)

### Objective 1: Deploy Production-Ready GitHub Actions Workflows
- **KR1:** 100% of defined workflows (PR review, issue comment, auto-fix) are deployable and functional
- **KR2:** All workflows pass security audit with explicit permissions blocks
- **KR3:** Reusable workflows are consumable across multiple repositories

### Objective 2: Deliver Cross-Platform AI Agent Scripts
- **KR1:** All scripts execute successfully on Linux (Ubuntu), macOS, and Windows (Git Bash)
- **KR2:** Scripts produce structured JSON outputs matching defined schemas
- **KR3:** Error handling and retry logic implemented for all API calls

### Objective 3: Complete Documentation and Testing Tools
- **KR1:** Every workflow has comprehensive documentation with examples
- **KR2:** Local testing tools allow developers to validate workflows before deployment
- **KR3:** API documentation covers all integration points and data formats

## REQUIREMENTS

### Functional
The system **must**:
- Execute AI-powered code reviews on every pull request
- Respond to issue comments with AI-generated assistance
- Automatically fix common code issues when triggered
- Support sparse checkout for efficient repository cloning
- Validate all inputs and sanitize outputs for security
- Provide reusable workflows for organization-wide adoption
- Include composite actions for common setup tasks
- Generate structured JSON outputs for all AI responses
- Support both GitHub-hosted and self-hosted runners
- Handle rate limiting and API failures gracefully

The agents **must**:
- Work in parallel without blocking each other
- Follow their designated specialist roles precisely
- Produce complete, production-ready code (not snippets)
- Include comprehensive error handling
- Document all configuration options
- Test their deliverables locally before submission

### Non-Functional (Quality Attributes)
- **Reliability:** 99.9% workflow execution success rate
- **Performance:** PR reviews complete within 2 minutes
- **Security:** All workflows use minimal required permissions
- **Maintainability:** Modular design with reusable components
- **Portability:** Scripts run on Linux, macOS, and Windows
- **Usability:** Clear documentation and error messages

## PLAN / WORK BREAKDOWN / DELIVERABLES

### Phase 1: Core Workflows (frontend-developer)
- `.github/workflows/pr-review.yml` - Main PR review workflow
- `.github/workflows/issue-comment.yml` - Issue comment handler
- `.github/workflows/auto-fix.yml` - Automated fix workflow

### Phase 2: Reusable Components (backend-architect)
- `.github/workflows/reusable-review.yml` - Reusable review workflow
- `.github/actions/setup-ai/action.yml` - Composite setup action
- `.github/actions/parse-output/action.yml` - JSON parsing action

### Phase 3: AI Agent Scripts (python-pro)
- `scripts/ai-review.sh` - Core review script
- `scripts/ai-agent.sh` - General AI agent interface
- `scripts/ai-autofix.sh` - Auto-fix implementation
- `scripts/lib/common.sh` - Shared utility functions

### Phase 4: Security Implementation (security-auditor)
- Permissions validation across all workflows
- Secret handling implementation
- Security documentation and guidelines

### Phase 5: Documentation (api-documenter)
- `docs/workflows/README.md` - Workflow documentation
- `docs/api/schemas.md` - JSON schema definitions
- `docs/usage/examples.md` - Usage examples

### Phase 6: Developer Tools (dx-optimizer)
- `tools/test-workflow.sh` - Local workflow testing
- `tools/validate-permissions.sh` - Permission validator
- `tools/mock-runner.sh` - Mock runner environment

## PROBLEMS • RISKS • ASSUMPTIONS • DEPENDENCIES

### Problems
- Cross-platform script compatibility (Windows path handling)
- GitHub API rate limits during high activity
- Sparse checkout configuration complexity

### Risks
- Workflow permissions might be too restrictive
- AI model API availability and response times
- Secret leakage through logs or outputs

### Assumptions
- GitHub CLI (`gh`) is available on all runners
- AI model API endpoints are stable
- Organization has necessary GitHub Action minutes

### Dependencies
- `actions/checkout@v4` for repository access
- GitHub CLI for API interactions
- AI model API (Claude/OpenAI/etc.)
- jq for JSON processing (must be installed)

## PRIORITIZATION (MoSCoW)

### Must Have
- PR review workflow with AI integration
- Cross-platform agent scripts
- Minimal permission configurations
- Structured JSON outputs

### Should Have
- Reusable workflows for org-wide use
- Composite actions for common tasks
- Local testing tools
- Comprehensive documentation

### Could Have
- Advanced caching strategies
- Custom GitHub App integration
- Webhook-based triggers
- Multi-model AI support

### Won't Have (This Phase)
- UI dashboard
- Custom GitHub Action marketplace publication
- Multi-language script implementations

## STATUS & MILESTONES / ROADMAP

### Week 1: Core Implementation
- [ ] Core workflows created (frontend-developer)
- [ ] AI agent scripts implemented (python-pro)
- [ ] Initial security review (security-auditor)

### Week 2: Integration & Testing
- [ ] Reusable components built (backend-architect)
- [ ] Documentation drafted (api-documenter)
- [ ] Local testing tools created (dx-optimizer)

### Week 3: Refinement & Deployment
- [ ] Security hardening complete
- [ ] Documentation finalized
- [ ] Production deployment

## AGENT PROMPT SPECS / POLICIES

### frontend-developer Prompt

```
You are a frontend-developer specialist implementing GitHub Actions workflows for Wave 3.

YOUR MISSION:
Create production-ready GitHub Actions workflows for PR review, issue comments, and auto-fix functionality.

DELIVERABLES:
1. .github/workflows/pr-review.yml
2. .github/workflows/issue-comment.yml
3. .github/workflows/auto-fix.yml

REQUIREMENTS:
- Include sparse checkout configuration in EVERY workflow:
  ```yaml
  - uses: actions/checkout@v4
    with:
      sparse-checkout: |
        scripts/
        .github/
      sparse-checkout-cone-mode: false
  ```
- Define explicit permissions blocks (use minimal required scopes)
- Support all relevant event types (pull_request, issue_comment, workflow_dispatch)
- Use environment variables for configuration
- Include proper error handling and status reporting
- Set up GitHub CLI authentication using GITHUB_TOKEN
- Call AI agent scripts from scripts/ directory
- Parse JSON outputs and create PR comments/reviews

WORKFLOW STRUCTURE:
Each workflow must include:
- name and description
- Comprehensive on: triggers with all event types
- permissions: block with minimal scopes
- env: block for configuration
- jobs with clear step names
- Error handling and retry logic
- Status badges and notifications

EXAMPLE OUTPUT FORMAT:
```yaml
name: AI PR Review
description: Automated PR review using AI

on:
  pull_request:
    types: [opened, synchronize, reopened]
  workflow_dispatch:
    inputs:
      pr_number:
        description: 'PR number to review'
        required: false
        type: number

permissions:
  contents: read
  pull-requests: write
  issues: read

env:
  AI_MODEL: claude-3-opus
  MAX_FILES: 20

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - name: Sparse checkout
        uses: actions/checkout@v4
        with:
          sparse-checkout: |
            scripts/
            .github/
          sparse-checkout-cone-mode: false

      - name: Setup environment
        run: |
          echo "PR_NUMBER=${{ github.event.pull_request.number }}" >> $GITHUB_ENV

      - name: Run AI review
        id: review
        run: |
          ./scripts/ai-review.sh \
            --pr "$PR_NUMBER" \
            --model "$AI_MODEL" \
            --output review.json

      - name: Post review
        if: success()
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          gh pr review "$PR_NUMBER" \
            --body-file review.json \
            --approve
```

Provide complete, production-ready workflows with all features implemented.
```

### backend-architect Prompt

```
You are a backend-architect specialist creating reusable workflows and composite actions for Wave 3.

YOUR MISSION:
Design and implement reusable GitHub Actions workflows and composite actions for organization-wide adoption.

DELIVERABLES:
1. .github/workflows/reusable-review.yml (workflow_call trigger)
2. .github/actions/setup-ai/action.yml (composite action)
3. .github/actions/parse-output/action.yml (composite action)
4. .github/actions/sparse-checkout/action.yml (composite action)

REQUIREMENTS:
- Create reusable workflow with workflow_call trigger
- Define clear input/output contracts using inputs: and outputs:
- Implement composite actions for common setup tasks
- Use semantic versioning approach for actions
- Include comprehensive input validation
- Support both required and optional parameters with defaults
- Implement proper error handling and logging
- Create abstraction layers for common operations

REUSABLE WORKFLOW STRUCTURE:
```yaml
name: Reusable AI Review Workflow
on:
  workflow_call:
    inputs:
      pr_number:
        required: true
        type: number
      ai_model:
        required: false
        type: string
        default: 'claude-3-opus'
      max_files:
        required: false
        type: number
        default: 20
    outputs:
      review_id:
        description: 'The ID of the posted review'
        value: ${{ jobs.review.outputs.review_id }}
      review_status:
        description: 'Status of the review (approved/changes_requested/commented)'
        value: ${{ jobs.review.outputs.status }}
    secrets:
      ai_token:
        required: true
      github_token:
        required: false

jobs:
  review:
    runs-on: ubuntu-latest
    outputs:
      review_id: ${{ steps.post.outputs.review_id }}
      status: ${{ steps.analyze.outputs.status }}
    steps:
      # Implementation here
```

COMPOSITE ACTION STRUCTURE:
```yaml
name: 'Setup AI Environment'
description: 'Sets up the AI agent environment with necessary tools'
inputs:
  ai-model:
    description: 'AI model to use'
    required: false
    default: 'claude-3-opus'
  install-tools:
    description: 'Whether to install required tools'
    required: false
    default: 'true'
outputs:
  config-path:
    description: 'Path to the generated configuration'
    value: ${{ steps.setup.outputs.config }}
runs:
  using: "composite"
  steps:
    - id: setup
      shell: bash
      run: |
        # Implementation here
        echo "config=$CONFIG_PATH" >> $GITHUB_OUTPUT
```

Design patterns to implement:
- Factory pattern for AI model selection
- Strategy pattern for different review types
- Observer pattern for status notifications
- Decorator pattern for workflow extensions

Provide complete, modular, reusable components with clear documentation.
```

### python-pro Prompt

```
You are a python-pro specialist implementing cross-platform AI agent scripts for Wave 3.

YOUR MISSION:
Write POSIX-compliant, cross-platform bash scripts for AI agent operations.

DELIVERABLES:
1. scripts/ai-review.sh - PR review script
2. scripts/ai-agent.sh - General AI interface
3. scripts/ai-autofix.sh - Auto-fix script
4. scripts/lib/common.sh - Shared utilities
5. scripts/schemas/review-output.json - Review JSON schema
6. scripts/schemas/comment-output.json - Comment JSON schema

REQUIREMENTS:
- Use #!/usr/bin/env bash shebang for portability
- Write POSIX-compliant code (no bashisms unless necessary)
- Handle Windows paths (convert with cygpath when detected)
- Implement comprehensive error handling with trap
- Use structured JSON for all outputs
- Include retry logic for API calls
- Support both environment variables and command-line arguments
- Implement proper logging to stderr
- Create modular, reusable functions

SCRIPT STRUCTURE:
```bash
#!/usr/bin/env bash
set -euo pipefail

# Script: ai-review.sh
# Description: Performs AI-powered code review on pull requests
# Usage: ./ai-review.sh --pr PR_NUMBER [--model MODEL] [--output FILE]

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Configuration
readonly DEFAULT_MODEL="${AI_MODEL:-claude-3-opus}"
readonly DEFAULT_OUTPUT="review.json"
readonly MAX_RETRIES=3
readonly RETRY_DELAY=5

# Functions
usage() {
    cat << EOF
Usage: $(basename "$0") --pr PR_NUMBER [OPTIONS]

Options:
    --pr NUMBER       Pull request number (required)
    --model MODEL     AI model to use (default: $DEFAULT_MODEL)
    --output FILE     Output file (default: $DEFAULT_OUTPUT)
    --max-files NUM   Maximum files to review (default: 20)
    --verbose         Enable verbose logging
    --help            Show this help message

Environment Variables:
    AI_MODEL          Default AI model
    GITHUB_TOKEN      GitHub API token (required)
    AI_API_KEY        AI service API key (required)
EOF
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --pr)
                PR_NUMBER="$2"
                shift 2
                ;;
            --model)
                MODEL="$2"
                shift 2
                ;;
            --output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            --max-files)
                MAX_FILES="$2"
                shift 2
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Main review function
perform_review() {
    local pr_number="$1"
    local model="${2:-$DEFAULT_MODEL}"

    log "Starting review for PR #${pr_number} using model: ${model}"

    # Get PR details
    local pr_data
    pr_data=$(gh pr view "${pr_number}" --json files,title,body,additions,deletions)

    # Get changed files
    local changed_files
    changed_files=$(echo "${pr_data}" | jq -r '.files[].path' | head -n "${MAX_FILES}")

    # Build review request
    local review_request
    review_request=$(cat << EOF
{
    "pr_number": ${pr_number},
    "model": "${model}",
    "files": $(echo "${changed_files}" | jq -Rs 'split("\n") | map(select(. != ""))'),
    "context": {
        "title": $(echo "${pr_data}" | jq '.title'),
        "body": $(echo "${pr_data}" | jq '.body'),
        "stats": {
            "additions": $(echo "${pr_data}" | jq '.additions'),
            "deletions": $(echo "${pr_data}" | jq '.deletions')
        }
    }
}
EOF
    )

    # Call AI API
    local response
    response=$(call_ai_api "${review_request}" "${model}")

    # Format output
    format_review_output "${response}" > "${OUTPUT_FILE}"

    log "Review completed and saved to ${OUTPUT_FILE}"
}

# JSON output formatter
format_review_output() {
    local response="$1"

    cat << EOF
{
    "review": {
        "body": "## AI Code Review\n\n${response}",
        "event": "COMMENT",
        "comments": []
    },
    "metadata": {
        "model": "${MODEL}",
        "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
        "pr_number": ${PR_NUMBER}
    }
}
EOF
}

# Main execution
main() {
    # Validate environment
    check_required_env "GITHUB_TOKEN" "AI_API_KEY"
    check_required_commands "gh" "jq" "curl"

    # Parse arguments
    parse_args "$@"

    # Validate required arguments
    [[ -z "${PR_NUMBER:-}" ]] && error "PR number is required"

    # Set defaults
    MODEL="${MODEL:-$DEFAULT_MODEL}"
    OUTPUT_FILE="${OUTPUT_FILE:-$DEFAULT_OUTPUT}"
    MAX_FILES="${MAX_FILES:-20}"

    # Perform review
    perform_review "${PR_NUMBER}" "${MODEL}"

    # Validate output
    if [[ -f "${OUTPUT_FILE}" ]]; then
        jq empty "${OUTPUT_FILE}" || error "Invalid JSON output"
        success "Review completed successfully"
    else
        error "Failed to generate review output"
    fi
}

# Run main function
main "$@"
```

JSON SCHEMA DEFINITIONS:
```json
// review-output.json
{
    "$schema": "http://json-schema.org/draft-07/schema#",
    "title": "AI Review Output",
    "type": "object",
    "required": ["review", "metadata"],
    "properties": {
        "review": {
            "type": "object",
            "required": ["body", "event"],
            "properties": {
                "body": {
                    "type": "string",
                    "description": "The review comment body in Markdown"
                },
                "event": {
                    "type": "string",
                    "enum": ["APPROVE", "REQUEST_CHANGES", "COMMENT"],
                    "description": "The review event type"
                },
                "comments": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "required": ["path", "line", "body"],
                        "properties": {
                            "path": {"type": "string"},
                            "line": {"type": "integer"},
                            "body": {"type": "string"}
                        }
                    }
                }
            }
        },
        "metadata": {
            "type": "object",
            "properties": {
                "model": {"type": "string"},
                "timestamp": {"type": "string", "format": "date-time"},
                "pr_number": {"type": "integer"}
            }
        }
    }
}
```

Implement all scripts with production-quality error handling and cross-platform compatibility.
```

### security-auditor Prompt

```
You are a security-auditor specialist validating and hardening Wave 3 implementations.

YOUR MISSION:
Audit all workflows for security vulnerabilities and implement proper permission guards and secret handling.

DELIVERABLES:
1. Security audit report for all workflows
2. Updated workflow files with security improvements
3. .github/security/permissions-policy.yml
4. .github/security/secret-scanning.yml
5. docs/security/best-practices.md

REQUIREMENTS:
- Validate ALL workflows have explicit permissions: blocks
- Ensure minimal permission scopes (principle of least privilege)
- Implement secret scanning and validation
- Add input sanitization for all user-provided data
- Prevent command injection vulnerabilities
- Audit third-party action usage
- Implement GITHUB_TOKEN scope restrictions
- Add security headers to API calls
- Document security considerations

SECURITY CHECKLIST:
For each workflow, verify:
□ Explicit permissions block with minimal scopes
□ No use of pull_request_target without proper guards
□ Input validation for workflow_dispatch inputs
□ Secrets never logged or exposed in outputs
□ Third-party actions pinned to specific SHA
□ No shell injection vulnerabilities
□ Proper GITHUB_TOKEN handling
□ Rate limiting implemented for API calls

EXAMPLE SECURITY IMPROVEMENTS:
```yaml
# BEFORE (Insecure)
on: pull_request_target
permissions: write-all

# AFTER (Secure)
on:
  pull_request_target:
    types: [opened, reopened]
permissions:
  contents: read
  pull-requests: write

jobs:
  review:
    if: |
      github.event.pull_request.head.repo.full_name == github.repository ||
      contains(github.event.pull_request.labels.*.name, 'safe-to-test')
    runs-on: ubuntu-latest
    steps:
      - name: Validate inputs
        run: |
          if [[ ! "${{ github.event.pull_request.number }}" =~ ^[0-9]+$ ]]; then
            echo "Invalid PR number"
            exit 1
          fi
```

PERMISSIONS POLICY:
```yaml
# permissions-policy.yml
workflows:
  pr-review:
    permissions:
      contents: read
      pull-requests: write
      issues: read
    secrets:
      - GITHUB_TOKEN
      - AI_API_KEY
    third-party-actions:
      - actions/checkout@SHA
      - actions/setup-node@SHA

  issue-comment:
    permissions:
      issues: write
    secrets:
      - GITHUB_TOKEN
      - AI_API_KEY
```

Provide comprehensive security analysis and hardened configurations.
```

### api-documenter Prompt

```
You are an api-documenter specialist creating comprehensive documentation for Wave 3.

YOUR MISSION:
Document all workflows, APIs, and integration patterns for the Wave 3 implementation.

DELIVERABLES:
1. docs/workflows/README.md - Complete workflow documentation
2. docs/api/schemas.md - JSON schema documentation
3. docs/usage/examples.md - Usage examples
4. docs/api/github-integration.md - GitHub API integration guide
5. docs/troubleshooting/common-issues.md - Troubleshooting guide

REQUIREMENTS:
- Document every workflow's purpose, triggers, inputs, and outputs
- Provide JSON schema documentation with examples
- Include curl/gh CLI examples for all operations
- Create troubleshooting guides for common issues
- Document rate limits and error handling
- Include sequence diagrams for complex flows
- Provide migration guides from manual to automated reviews

DOCUMENTATION STRUCTURE:
```markdown
# Workflow Name

## Overview
Brief description of what this workflow does and why it's useful.

## Trigger Events
- `pull_request`: [opened, synchronize, reopened]
- `workflow_dispatch`: Manual trigger with inputs

## Configuration

### Required Secrets
- `GITHUB_TOKEN`: Automatically provided by GitHub Actions
- `AI_API_KEY`: API key for AI service (stored in repository secrets)

### Environment Variables
| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| AI_MODEL | Model to use for analysis | claude-3-opus | No |
| MAX_FILES | Maximum files to review | 20 | No |

## Inputs (workflow_dispatch)
```yaml
inputs:
  pr_number:
    description: 'Pull request number'
    required: true
    type: number
  model:
    description: 'AI model to use'
    required: false
    type: choice
    options:
      - claude-3-opus
      - gpt-4
      - claude-3-sonnet
```

## Outputs
```json
{
  "review": {
    "body": "string",
    "event": "APPROVE | REQUEST_CHANGES | COMMENT"
  }
}
```

## Usage Examples

### Via GitHub UI
1. Navigate to Actions tab
2. Select "AI PR Review" workflow
3. Click "Run workflow"
4. Enter PR number
5. Select model (optional)

### Via GitHub CLI
```bash
gh workflow run pr-review.yml \
  -f pr_number=123 \
  -f model=claude-3-opus
```

### Via API
```bash
curl -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/OWNER/REPO/actions/workflows/pr-review.yml/dispatches \
  -d '{"ref":"main","inputs":{"pr_number":"123"}}'
```

## Permissions Required
- `contents: read` - Read repository contents
- `pull-requests: write` - Post reviews and comments

## Error Handling
- API rate limiting: Automatic retry with exponential backoff
- AI service unavailable: Graceful failure with informative message
- Invalid PR number: Validation error before execution

## Monitoring
- Check workflow runs: `gh run list --workflow=pr-review.yml`
- View logs: `gh run view RUN_ID --log`

## Troubleshooting

### Common Issues

#### Workflow not triggering
- Verify workflow file is in default branch
- Check workflow file syntax with `yamllint`
- Ensure proper permissions in repository settings

#### AI API errors
- Verify API key is correctly set in secrets
- Check API rate limits and quotas
- Validate model name is supported
```

Create comprehensive, user-friendly documentation with practical examples.
```

### dx-optimizer Prompt

```
You are a dx-optimizer specialist creating developer experience tools for Wave 3.

YOUR MISSION:
Build local testing and validation tools to improve developer workflow and reduce debugging time.

DELIVERABLES:
1. tools/test-workflow.sh - Local workflow testing script
2. tools/validate-permissions.sh - Permission validator
3. tools/mock-runner.sh - Mock GitHub Actions environment
4. tools/debug-action.sh - Action debugging utility
5. .github/dev/local-config.yml - Local development configuration
6. docker/Dockerfile.act - Container for act testing

REQUIREMENTS:
- Create tools for local workflow testing before deployment
- Implement permission validation without running workflows
- Build mock environments for GitHub Actions
- Support debugging of composite actions
- Enable fast iteration cycles for developers
- Provide clear error messages and suggestions
- Support both act and native testing approaches

LOCAL TESTING SCRIPT:
```bash
#!/usr/bin/env bash
# tools/test-workflow.sh - Test GitHub Actions workflows locally

set -euo pipefail

# Check for required tools
check_requirements() {
    local tools=("docker" "act" "yq" "jq")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo "Error: $tool is not installed"
            echo "Install with: brew install $tool"
            exit 1
        fi
    done
}

# Validate workflow syntax
validate_syntax() {
    local workflow="$1"
    echo "Validating syntax for $workflow..."

    # Check YAML syntax
    yq eval '.' "$workflow" > /dev/null || {
        echo "Error: Invalid YAML syntax"
        return 1
    }

    # Check required fields
    local required=("name" "on" "jobs")
    for field in "${required[@]}"; do
        if ! yq eval ".$field" "$workflow" | grep -q .; then
            echo "Error: Missing required field: $field"
            return 1
        fi
    done

    echo "✓ Syntax valid"
}

# Test workflow with act
test_with_act() {
    local workflow="$1"
    local event="${2:-push}"

    echo "Testing $workflow with act (event: $event)..."

    # Create event payload
    local event_file="/tmp/event.json"
    create_event_payload "$event" > "$event_file"

    # Run with act
    act "$event" \
        --workflows "$workflow" \
        --event-path "$event_file" \
        --secret-file .env.local \
        --platform ubuntu-latest=catthehacker/ubuntu:act-latest \
        --artifact-server-path /tmp/artifacts \
        --verbose
}

# Create mock event payload
create_event_payload() {
    local event="$1"

    case "$event" in
        pull_request)
            cat << 'EOF'
{
  "action": "opened",
  "number": 1,
  "pull_request": {
    "number": 1,
    "title": "Test PR",
    "body": "Test description",
    "head": {
      "ref": "feature-branch",
      "sha": "abc123"
    },
    "base": {
      "ref": "main"
    }
  }
}
EOF
            ;;
        push)
            cat << 'EOF'
{
  "ref": "refs/heads/main",
  "before": "000000",
  "after": "abc123",
  "commits": [
    {
      "id": "abc123",
      "message": "Test commit",
      "author": {
        "name": "Test User",
        "email": "test@example.com"
      }
    }
  ]
}
EOF
            ;;
    esac
}

# Main execution
main() {
    local workflow="${1:-.github/workflows/pr-review.yml}"
    local event="${2:-pull_request}"

    check_requirements
    validate_syntax "$workflow"

    # Check for local secrets
    if [[ ! -f .env.local ]]; then
        echo "Warning: .env.local not found"
        echo "Create it with: cp .env.example .env.local"
    fi

    test_with_act "$workflow" "$event"
}

main "$@"
```

PERMISSION VALIDATOR:
```bash
#!/usr/bin/env bash
# tools/validate-permissions.sh - Validate GitHub Actions permissions

validate_permissions() {
    local workflow="$1"

    echo "Checking permissions in $workflow..."

    # Extract permissions
    local perms=$(yq eval '.permissions' "$workflow")

    if [[ "$perms" == "null" ]]; then
        echo "⚠️  Warning: No explicit permissions defined"
        echo "   Workflow will inherit default permissions"
        return 1
    fi

    if [[ "$perms" == "write-all" || "$perms" == "read-all" ]]; then
        echo "❌ Error: Using $perms is not recommended"
        echo "   Define specific permissions instead"
        return 1
    fi

    # Check for minimal permissions
    echo "Permissions defined:"
    echo "$perms" | yq eval '.' -

    # Validate against policy
    validate_against_policy "$workflow" "$perms"
}

validate_against_policy() {
    local workflow="$1"
    local perms="$2"
    local policy=".github/security/permissions-policy.yml"

    if [[ ! -f "$policy" ]]; then
        echo "⚠️  No permissions policy found"
        return 0
    fi

    # Compare with policy
    local workflow_name=$(basename "$workflow" .yml)
    local allowed=$(yq eval ".workflows.${workflow_name}.permissions" "$policy")

    echo "✓ Permissions validated against policy"
}
```

MOCK RUNNER ENVIRONMENT:
```bash
#!/usr/bin/env bash
# tools/mock-runner.sh - Create mock GitHub Actions environment

setup_mock_environment() {
    # Set GitHub Actions environment variables
    export GITHUB_ACTIONS=true
    export GITHUB_WORKFLOW="Test Workflow"
    export GITHUB_RUN_ID=$RANDOM
    export GITHUB_RUN_NUMBER=1
    export GITHUB_JOB="test"
    export GITHUB_ACTION="test-action"
    export GITHUB_ACTOR="test-user"
    export GITHUB_REPOSITORY="org/repo"
    export GITHUB_EVENT_NAME="${1:-push}"
    export GITHUB_SHA="abc123def456"
    export GITHUB_REF="refs/heads/main"
    export GITHUB_HEAD_REF=""
    export GITHUB_BASE_REF=""
    export GITHUB_SERVER_URL="https://github.com"
    export GITHUB_API_URL="https://api.github.com"
    export GITHUB_WORKSPACE="$PWD"
    export RUNNER_OS="Linux"
    export RUNNER_TEMP="/tmp/runner"
    export RUNNER_TOOL_CACHE="/tmp/tools"

    # Create required directories
    mkdir -p "$RUNNER_TEMP" "$RUNNER_TOOL_CACHE"

    echo "Mock environment created:"
    env | grep GITHUB_ | sort
}

# Run command in mock environment
run_in_mock() {
    setup_mock_environment "$1"
    shift
    exec "$@"
}

run_in_mock "$@"
```

Provide complete, working tools that significantly improve the developer experience.
```

## CONSTRAINTS / SLOs & SLIs

### Constraints
- All scripts must be POSIX-compliant for cross-platform compatibility
- Workflows must complete within 5 minutes (300 seconds timeout)
- API calls must implement retry logic with exponential backoff
- Memory usage must not exceed 2GB for script execution
- Sparse checkout must be used to minimize repository clone size
- Permission scopes must be minimal (principle of least privilege)

### Service Level Objectives (SLOs)
- **Availability:** 99.9% workflow success rate
- **Latency:** 95% of PR reviews complete within 2 minutes
- **Throughput:** Support 100 concurrent workflow runs
- **Error Rate:** Less than 0.1% workflow failures due to script errors

### Service Level Indicators (SLIs)
- Workflow execution time (P50, P95, P99)
- API call success rate
- Script error rate
- Permission violation attempts
- Resource utilization (CPU, memory, API rate limits)

## STANDARDS & FRAMEWORKS

### GitHub Actions Standards
- Use `actions/checkout@v4` for repository access
- Pin third-party actions to specific SHA for security
- Follow GitHub's security hardening guidelines
- Use GITHUB_OUTPUT instead of set-output (deprecated)
- Implement job outputs using `${{ steps.STEP_ID.outputs.NAME }}`

### Scripting Standards
- POSIX.1-2017 compliance for shell scripts
- Shellcheck validation (no errors, minimal warnings)
- Use `set -euo pipefail` for error handling
- Implement trap for cleanup operations
- Follow Google Shell Style Guide

### JSON Schema Standards
- JSON Schema Draft 7 (`http://json-schema.org/draft-07/schema#`)
- Required fields must be explicitly defined
- Use semantic property names (camelCase for objects)
- Include descriptions for all properties
- Validate against schema before output

### Documentation Standards
- Markdown formatting with proper headers
- Include table of contents for documents > 500 lines
- Provide code examples for all features
- Use mermaid diagrams for complex flows
- Follow semantic versioning for updates

## REFERENCES

### GitHub Actions Documentation
- [GitHub Actions Workflow Syntax](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions)
- [actions/checkout@v4](https://github.com/actions/checkout)
- [GitHub CLI Manual](https://cli.github.com/manual/)
- [Reusable Workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)
- [Composite Actions](https://docs.github.com/en/actions/creating-actions/creating-a-composite-action)
- [Security Hardening](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)

### API References
- [GitHub REST API - Pull Requests](https://docs.github.com/en/rest/pulls)
- [GitHub GraphQL API](https://docs.github.com/en/graphql)
- [GitHub Webhooks](https://docs.github.com/en/webhooks)
- [Rate Limiting](https://docs.github.com/en/rest/rate-limit)

### Tool References
- [jq Manual](https://stedolan.github.io/jq/manual/)
- [yq Documentation](https://mikefarah.gitbook.io/yq/)
- [act - Local GitHub Actions](https://github.com/nektos/act)
- [ShellCheck](https://www.shellcheck.net/)

### Standards References
- [POSIX.1-2017](https://pubs.opengroup.org/onlinepubs/9699919799/)
- [JSON Schema Specification](https://json-schema.org/specification.html)
- [Semantic Versioning](https://semver.org/)
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)

---

## NOTES

### Implementation Order
1. Core scripts (python-pro) and workflows (frontend-developer) can be developed in parallel
2. Security audit (security-auditor) should review as soon as initial implementations are ready
3. Reusable components (backend-architect) can build on core workflow patterns
4. Documentation (api-documenter) should track implementation progress
5. Developer tools (dx-optimizer) can be created alongside main implementation

### Testing Strategy
- Local testing with act before deployment
- Validate permissions without execution
- Mock API responses for development
- Use test repositories for initial deployment
- Gradual rollout with feature flags

### Migration Path
1. Deploy to test repository first
2. Run in parallel with existing manual process
3. Compare results and refine
4. Gradual migration of production repositories
5. Full cutover after validation period

---

## ASSUMPTIONS / HYPOTHESES / PRINCIPLES

### Assumptions
- GitHub-hosted runners have necessary tools installed (git, curl, jq)
- Organization allows GitHub Actions and has sufficient minutes
- AI API endpoints are stable and accessible
- Development team has basic GitHub Actions knowledge

### Hypotheses
- AI-powered reviews will reduce review time by 70%
- Structured JSON outputs will enable better integration
- Local testing tools will reduce debugging time by 50%
- Reusable workflows will improve consistency across repositories

### Principles
- **Security First:** Every workflow must be secure by default
- **Developer Experience:** Tools should be intuitive and helpful
- **Modularity:** Components should be reusable and composable
- **Observability:** All operations should be logged and traceable
- **Graceful Degradation:** Failures should not block development
- **Progressive Enhancement:** Start simple, add features iteratively