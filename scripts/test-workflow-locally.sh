#!/usr/bin/env bash
# Script: test-workflow-locally.sh
# Description: Simulates GitHub Actions workflow execution locally
# Usage: ./test-workflow-locally.sh [OPTIONS] WORKFLOW_FILE

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly MOCK_ENV_DIR="${PROJECT_ROOT}/.github/test-env"
readonly LOG_DIR="${PROJECT_ROOT}/.github/test-logs"

# Default values
WORKFLOW_FILE=""
EVENT_TYPE="pull_request"
EVENT_PAYLOAD_FILE=""
VERBOSE=false
DRY_RUN=false
MOCK_GH_CLI=true
SECRETS_FILE="${PROJECT_ROOT}/.env.local"

# Logging functions
log() {
    echo -e "${BLUE}[INFO]${NC} $*" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

verbose() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $*" >&2
    fi
}

# Usage information
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] WORKFLOW_FILE

Test GitHub Actions workflows locally by simulating the Actions environment.

OPTIONS:
    -e, --event TYPE        Event type (pull_request, push, issue_comment, workflow_dispatch)
                           Default: pull_request
    -p, --payload FILE     Path to event payload JSON file
    -s, --secrets FILE     Path to secrets file (default: .env.local)
    -m, --no-mock-gh      Don't mock gh CLI (use real gh commands)
    -v, --verbose         Enable verbose logging
    -d, --dry-run         Show what would be executed without running
    -h, --help            Show this help message

EXAMPLES:
    # Test PR review workflow with default pull_request event
    $(basename "$0") .github/workflows/pr-review.yml

    # Test with custom event type
    $(basename "$0") -e push .github/workflows/pr-review.yml

    # Test with custom payload
    $(basename "$0") -p test-event.json .github/workflows/pr-review.yml

    # Verbose dry run
    $(basename "$0") -v -d .github/workflows/pr-review.yml

ENVIRONMENT:
    The script creates a mock GitHub Actions environment with:
    - GITHUB_* environment variables
    - Mock gh CLI (unless -m is specified)
    - Simulated checkout
    - Log output to .github/test-logs/

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--event)
                EVENT_TYPE="$2"
                shift 2
                ;;
            -p|--payload)
                EVENT_PAYLOAD_FILE="$2"
                shift 2
                ;;
            -s|--secrets)
                SECRETS_FILE="$2"
                shift 2
                ;;
            -m|--no-mock-gh)
                MOCK_GH_CLI=false
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                WORKFLOW_FILE="$1"
                shift
                ;;
        esac
    done

    if [[ -z "$WORKFLOW_FILE" ]]; then
        error "Workflow file is required"
        usage
        exit 1
    fi

    if [[ ! -f "$WORKFLOW_FILE" ]]; then
        error "Workflow file not found: $WORKFLOW_FILE"
        exit 1
    fi
}

# Setup test environment
setup_test_environment() {
    log "Setting up test environment..."

    # Create directories
    mkdir -p "$MOCK_ENV_DIR" "$LOG_DIR"

    # Export GitHub Actions environment variables
    export GITHUB_ACTIONS=true
    export GITHUB_WORKFLOW="Test Workflow (Local)"
    export GITHUB_RUN_ID=$RANDOM
    export GITHUB_RUN_NUMBER=1
    export GITHUB_RUN_ATTEMPT=1
    export GITHUB_JOB="test-job"
    export GITHUB_ACTION="test-action"
    export GITHUB_ACTOR="test-user"
    export GITHUB_REPOSITORY="test-org/test-repo"
    export GITHUB_EVENT_NAME="$EVENT_TYPE"
    export GITHUB_SHA="abc123def456789"
    export GITHUB_REF="refs/heads/main"
    export GITHUB_HEAD_REF="feature-branch"
    export GITHUB_BASE_REF="main"
    export GITHUB_SERVER_URL="https://github.com"
    export GITHUB_API_URL="https://api.github.com"
    export GITHUB_GRAPHQL_URL="https://api.github.com/graphql"
    export GITHUB_WORKSPACE="$PROJECT_ROOT"
    export RUNNER_OS="$(uname -s)"
    export RUNNER_ARCH="$(uname -m)"
    export RUNNER_TEMP="${MOCK_ENV_DIR}/tmp"
    export RUNNER_TOOL_CACHE="${MOCK_ENV_DIR}/tools"
    export GITHUB_ENV="${MOCK_ENV_DIR}/github_env"
    export GITHUB_OUTPUT="${MOCK_ENV_DIR}/github_output"
    export GITHUB_PATH="${MOCK_ENV_DIR}/github_path"
    export GITHUB_STEP_SUMMARY="${MOCK_ENV_DIR}/step_summary"

    # Create required directories
    mkdir -p "$RUNNER_TEMP" "$RUNNER_TOOL_CACHE"

    # Initialize output files
    touch "$GITHUB_ENV" "$GITHUB_OUTPUT" "$GITHUB_PATH" "$GITHUB_STEP_SUMMARY"

    # Load secrets if file exists
    if [[ -f "$SECRETS_FILE" ]]; then
        verbose "Loading secrets from $SECRETS_FILE"
        set -a
        # shellcheck disable=SC1090
        source "$SECRETS_FILE"
        set +a
    else
        warn "Secrets file not found: $SECRETS_FILE"
        warn "Create it with: cp .env.example .env.local"
    fi

    success "Test environment created"
}

# Create event payload
create_event_payload() {
    local event_type="$1"
    local payload_file="${MOCK_ENV_DIR}/event.json"

    if [[ -n "$EVENT_PAYLOAD_FILE" ]]; then
        verbose "Using custom event payload: $EVENT_PAYLOAD_FILE"
        cp "$EVENT_PAYLOAD_FILE" "$payload_file"
    else
        verbose "Generating default event payload for: $event_type"
        case "$event_type" in
            pull_request)
                cat > "$payload_file" << 'EOF'
{
  "action": "opened",
  "number": 123,
  "pull_request": {
    "number": 123,
    "title": "Test PR: Add new feature",
    "body": "This is a test pull request for local testing.\n\nChanges:\n- Added feature X\n- Fixed bug Y",
    "state": "open",
    "draft": false,
    "head": {
      "ref": "feature-branch",
      "sha": "abc123def456",
      "repo": {
        "full_name": "test-org/test-repo"
      }
    },
    "base": {
      "ref": "main",
      "sha": "def456abc123"
    },
    "user": {
      "login": "test-user",
      "type": "User"
    },
    "additions": 150,
    "deletions": 25,
    "changed_files": 5
  },
  "repository": {
    "name": "test-repo",
    "full_name": "test-org/test-repo",
    "owner": {
      "login": "test-org"
    }
  }
}
EOF
                ;;
            push)
                cat > "$payload_file" << 'EOF'
{
  "ref": "refs/heads/main",
  "before": "0000000000000000000000000000000000000000",
  "after": "abc123def456",
  "repository": {
    "name": "test-repo",
    "full_name": "test-org/test-repo"
  },
  "pusher": {
    "name": "test-user",
    "email": "test@example.com"
  },
  "commits": [
    {
      "id": "abc123def456",
      "message": "Test commit message",
      "author": {
        "name": "Test User",
        "email": "test@example.com"
      },
      "added": ["new-file.txt"],
      "modified": ["existing-file.txt"],
      "removed": []
    }
  ]
}
EOF
                ;;
            issue_comment)
                cat > "$payload_file" << 'EOF'
{
  "action": "created",
  "issue": {
    "number": 456,
    "title": "Test Issue",
    "body": "This is a test issue",
    "state": "open",
    "user": {
      "login": "test-user"
    },
    "pull_request": {
      "url": "https://api.github.com/repos/test-org/test-repo/pulls/123"
    }
  },
  "comment": {
    "id": 789,
    "body": "/review-pr",
    "user": {
      "login": "test-user"
    }
  },
  "repository": {
    "name": "test-repo",
    "full_name": "test-org/test-repo"
  }
}
EOF
                ;;
            workflow_dispatch)
                cat > "$payload_file" << 'EOF'
{
  "inputs": {
    "pr_number": "123",
    "model": "claude-3-opus"
  },
  "ref": "refs/heads/main",
  "repository": {
    "name": "test-repo",
    "full_name": "test-org/test-repo"
  },
  "sender": {
    "login": "test-user"
  }
}
EOF
                ;;
            *)
                error "Unknown event type: $event_type"
                exit 1
                ;;
        esac
    fi

    export GITHUB_EVENT_PATH="$payload_file"
    verbose "Event payload created: $payload_file"
}

# Setup mock gh CLI
setup_mock_gh() {
    if [[ "$MOCK_GH_CLI" != true ]]; then
        verbose "Using real gh CLI"
        return 0
    fi

    log "Setting up mock gh CLI..."

    local mock_gh="${MOCK_ENV_DIR}/bin/gh"
    mkdir -p "$(dirname "$mock_gh")"

    cat > "$mock_gh" << 'EOF'
#!/usr/bin/env bash
# Mock gh CLI for local testing

echo "[MOCK-GH] Command: $*" >&2

case "$1" in
    pr)
        case "$2" in
            view)
                cat << 'PRJSON'
{
  "number": 123,
  "title": "Test PR: Add new feature",
  "body": "Test PR body",
  "state": "OPEN",
  "additions": 150,
  "deletions": 25,
  "files": [
    {"path": "src/main.js", "additions": 50, "deletions": 10},
    {"path": "src/utils.js", "additions": 30, "deletions": 5},
    {"path": "tests/main.test.js", "additions": 40, "deletions": 5},
    {"path": "README.md", "additions": 20, "deletions": 3},
    {"path": "package.json", "additions": 10, "deletions": 2}
  ],
  "headRefName": "feature-branch",
  "baseRefName": "main"
}
PRJSON
                ;;
            review)
                echo "[MOCK-GH] Review posted for PR $3" >&2
                echo '{"id": 123456}'
                ;;
            comment)
                echo "[MOCK-GH] Comment posted on PR $3" >&2
                echo '{"id": 789012}'
                ;;
            diff)
                echo "diff --git a/src/main.js b/src/main.js"
                echo "+++ added line 1"
                echo "+++ added line 2"
                ;;
            *)
                echo '{"success": true}'
                ;;
        esac
        ;;
    issue)
        case "$2" in
            comment)
                echo "[MOCK-GH] Comment posted on issue" >&2
                echo '{"id": 345678}'
                ;;
            view)
                echo '{"number": 456, "title": "Test Issue"}'
                ;;
            *)
                echo '{"success": true}'
                ;;
        esac
        ;;
    api)
        echo '{"success": true, "data": []}'
        ;;
    *)
        echo "[MOCK-GH] Unknown command: $1" >&2
        echo '{"success": true}'
        ;;
esac

exit 0
EOF

    chmod +x "$mock_gh"
    export PATH="${MOCK_ENV_DIR}/bin:$PATH"

    success "Mock gh CLI created at: $mock_gh"
}

# Parse workflow file
parse_workflow() {
    local workflow="$1"

    log "Parsing workflow: $workflow"

    # Check if yq is available
    if ! command -v yq &> /dev/null; then
        warn "yq not found - skipping advanced workflow parsing"
        warn "Install with: brew install yq (macOS) or apt-get install yq (Linux)"
        return 0
    fi

    # Extract workflow name
    local workflow_name
    workflow_name=$(yq eval '.name' "$workflow" 2>/dev/null || echo "Unknown")
    verbose "Workflow name: $workflow_name"

    # Extract jobs
    local jobs
    jobs=$(yq eval '.jobs | keys | .[]' "$workflow" 2>/dev/null || echo "")
    if [[ -n "$jobs" ]]; then
        verbose "Jobs found:"
        echo "$jobs" | while read -r job; do
            verbose "  - $job"
        done
    fi

    # Check permissions
    local permissions
    permissions=$(yq eval '.permissions' "$workflow" 2>/dev/null || echo "null")
    if [[ "$permissions" != "null" ]]; then
        verbose "Permissions defined:"
        echo "$permissions" | while read -r line; do
            verbose "  $line"
        done
    else
        warn "No explicit permissions defined in workflow"
    fi

    success "Workflow parsed successfully"
}

# Simulate sparse checkout
simulate_checkout() {
    log "Simulating sparse checkout..."

    local workflow="$1"

    # Check if workflow uses sparse checkout
    if ! command -v yq &> /dev/null; then
        verbose "Skipping checkout simulation (yq not available)"
        return 0
    fi

    local sparse_paths
    sparse_paths=$(yq eval '.. | select(has("sparse-checkout")) | .sparse-checkout' "$workflow" 2>/dev/null || echo "")

    if [[ -n "$sparse_paths" ]]; then
        verbose "Sparse checkout paths:"
        echo "$sparse_paths" | while read -r path; do
            [[ -n "$path" ]] && verbose "  - $path"
        done
    else
        verbose "No sparse checkout configuration found"
    fi

    success "Checkout simulation complete"
}

# Extract and execute steps
execute_workflow_steps() {
    local workflow="$1"
    local log_file="${LOG_DIR}/test-$(date +%Y%m%d-%H%M%S).log"

    log "Executing workflow steps..."
    log "Logs will be saved to: $log_file"

    {
        echo "=========================================="
        echo "Workflow Test Execution"
        echo "=========================================="
        echo "Workflow: $workflow"
        echo "Event: $EVENT_TYPE"
        echo "Started: $(date)"
        echo "=========================================="
        echo ""
    } | tee "$log_file"

    if [[ "$DRY_RUN" == true ]]; then
        warn "DRY RUN MODE - No actual execution"
        {
            echo "Environment Variables:"
            env | grep GITHUB_ | sort
            echo ""
            echo "Event Payload:"
            cat "$GITHUB_EVENT_PATH"
            echo ""
        } | tee -a "$log_file"
        return 0
    fi

    # For actual execution, we would parse and run steps
    # This is a simplified version
    if command -v yq &> /dev/null; then
        local job_count
        job_count=$(yq eval '.jobs | length' "$workflow" 2>/dev/null || echo "0")

        {
            echo "Found $job_count job(s) in workflow"
            echo ""
            echo "Note: This is a simulation. For full workflow execution, use 'act':"
            echo "  act $EVENT_TYPE -W $workflow"
            echo ""
        } | tee -a "$log_file"
    fi

    {
        echo "=========================================="
        echo "Test completed: $(date)"
        echo "=========================================="
    } | tee -a "$log_file"

    success "Workflow simulation complete"
    log "Full logs saved to: $log_file"
}

# Validate workflow execution
validate_execution() {
    log "Validating execution..."

    # Check output files
    local outputs=("$GITHUB_ENV" "$GITHUB_OUTPUT" "$GITHUB_PATH")
    for output in "${outputs[@]}"; do
        if [[ -f "$output" ]]; then
            verbose "Output file created: $output"
            if [[ -s "$output" ]]; then
                verbose "  Content:"
                while IFS= read -r line; do
                    verbose "    $line"
                done < "$output"
            fi
        fi
    done

    # Check for common issues
    local issues=()

    if [[ ! -f "$SECRETS_FILE" ]]; then
        issues+=("Missing secrets file: $SECRETS_FILE")
    fi

    if [[ ${#issues[@]} -gt 0 ]]; then
        warn "Potential issues found:"
        for issue in "${issues[@]}"; do
            warn "  - $issue"
        done
    else
        success "No issues found"
    fi
}

# Display test summary
display_summary() {
    echo ""
    echo "=========================================="
    echo "Test Summary"
    echo "=========================================="
    echo "Workflow:        $WORKFLOW_FILE"
    echo "Event Type:      $EVENT_TYPE"
    echo "Mock gh CLI:     $MOCK_GH_CLI"
    echo "Dry Run:         $DRY_RUN"
    echo "Environment:     $MOCK_ENV_DIR"
    echo "Logs:            $LOG_DIR"
    echo "=========================================="
    echo ""
    echo "To run with act (recommended):"
    echo "  act $EVENT_TYPE -W $WORKFLOW_FILE --secret-file $SECRETS_FILE"
    echo ""
    echo "To clean up test environment:"
    echo "  rm -rf $MOCK_ENV_DIR $LOG_DIR"
    echo ""
}

# Main execution
main() {
    parse_args "$@"

    log "Starting local workflow test"
    log "Workflow: $WORKFLOW_FILE"
    log "Event: $EVENT_TYPE"

    setup_test_environment
    create_event_payload "$EVENT_TYPE"
    setup_mock_gh
    parse_workflow "$WORKFLOW_FILE"
    simulate_checkout "$WORKFLOW_FILE"
    execute_workflow_steps "$WORKFLOW_FILE"
    validate_execution
    display_summary

    success "Local workflow test completed"
}

# Cleanup on exit
cleanup() {
    if [[ "$VERBOSE" == true ]]; then
        log "Cleanup complete"
    fi
}

trap cleanup EXIT

main "$@"
