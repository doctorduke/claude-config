#!/bin/bash
# Test GitHub Actions workflows locally using act
# Usage: ./scripts/test-workflows/test-local.sh [workflow-name] [event-type]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
WORKFLOW_NAME="${1:-}"
EVENT_TYPE="${2:-issue_comment}"

echo -e "${BLUE}🧪 GitHub Actions Local Testing${NC}"
echo "=================================="

# Check if act is installed
if ! command -v act &> /dev/null; then
    echo -e "${RED}❌ act is not installed${NC}"
    echo "Install it with: curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash"
    exit 1
fi

# Check if Docker is running
if ! docker ps &> /dev/null; then
    echo -e "${RED}❌ Docker is not running${NC}"
    echo "Please start Docker Desktop or Docker daemon"
    exit 1
fi

echo -e "${GREEN}✅ act and Docker are available${NC}"

# Function to test a specific workflow
test_workflow() {
    local workflow_file="$1"
    local event_type="$2"

    echo -e "\n${BLUE}🔍 Testing $(basename "$workflow_file")${NC}"

    # Create test event based on event type
    local event_file="/tmp/test-event-$(basename "$workflow_file" .yml).json"

    case "$event_type" in
        "issue_comment")
            cat > "$event_file" << 'EOF'
{
  "comment": {
    "body": "@claude test the workflow",
    "user": {
      "login": "testuser"
    }
  },
  "issue": {
    "number": 123
  }
}
EOF
            ;;
        "pull_request")
            cat > "$event_file" << 'EOF'
{
  "pull_request": {
    "number": 123,
    "title": "Test PR",
    "body": "Test pull request for workflow testing",
    "head": {
      "ref": "test-branch"
    },
    "base": {
      "ref": "trunk"
    }
  }
}
EOF
            ;;
        "push")
            cat > "$event_file" << 'EOF'
{
  "ref": "refs/heads/test-branch",
  "head_commit": {
    "id": "abc123",
    "message": "Test commit"
  }
}
EOF
            ;;
        *)
            echo -e "${YELLOW}⚠️  Unknown event type: $event_type${NC}"
            return 1
            ;;
    esac

    echo "Created test event: $event_file"

    # Run act with dry run first
    echo -e "${YELLOW}🔍 Dry run test...${NC}"
    if act -W "$workflow_file" -e "$event_file" --dryrun --container-architecture linux/amd64; then
        echo -e "${GREEN}✅ Dry run successful${NC}"
    else
        echo -e "${RED}❌ Dry run failed${NC}"
        return 1
    fi

    # Ask if user wants to run actual test
    echo -e "${YELLOW}🤔 Run actual test? (y/N)${NC}"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}🚀 Running actual test...${NC}"
        if act -W "$workflow_file" -e "$event_file" --container-architecture linux/amd64; then
            echo -e "${GREEN}✅ Actual test successful${NC}"
        else
            echo -e "${RED}❌ Actual test failed${NC}"
            return 1
        fi
    fi

    # Cleanup
    rm -f "$event_file"
}

# Function to validate workflow syntax
validate_workflows() {
    echo -e "\n${BLUE}🔍 Validating workflow syntax${NC}"

    if ! command -v js-yaml &> /dev/null; then
        echo "Installing js-yaml for validation..."
        npm install -g js-yaml
    fi

    local has_errors=false

    for workflow in .github/workflows/*.yml; do
        if [ -f "$workflow" ]; then
            echo "Checking $(basename "$workflow")..."
            if js-yaml "$workflow" > /dev/null 2>&1; then
                echo -e "${GREEN}✅ $(basename "$workflow") - Valid YAML${NC}"
            else
                echo -e "${RED}❌ $(basename "$workflow") - Invalid YAML${NC}"
                has_errors=true
            fi
        fi
    done

    if [ "$has_errors" = true ]; then
        echo -e "${RED}❌ Some workflows have syntax errors${NC}"
        return 1
    else
        echo -e "${GREEN}✅ All workflows have valid syntax${NC}"
    fi
}

# Main execution
main() {
    # Validate workflows first
    validate_workflows

    if [ -n "$WORKFLOW_NAME" ]; then
        # Test specific workflow
        local workflow_file=".github/workflows/$WORKFLOW_NAME"
        if [ -f "$workflow_file" ]; then
            test_workflow "$workflow_file" "$EVENT_TYPE"
        else
            echo -e "${RED}❌ Workflow not found: $workflow_file${NC}"
            exit 1
        fi
    else
        # Test all workflows
        echo -e "\n${BLUE}🔍 Testing all workflows${NC}"
        for workflow in .github/workflows/*.yml; do
            if [ -f "$workflow" ]; then
                test_workflow "$workflow" "$EVENT_TYPE"
            fi
        done
    fi

    echo -e "\n${GREEN}🎉 Testing complete!${NC}"
}

# Run main function
main "$@"
