#!/bin/bash
# Validate E2E Test Suite
# Checks syntax, dependencies, and configuration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_RESET='\033[0m'

VALIDATION_ERRORS=0

# ============================================================================
# Validation Functions
# ============================================================================

check_syntax() {
    echo ""
    echo "============================================================================"
    echo "Checking Bash Syntax"
    echo "============================================================================"

    local errors=0

    for script in "$SCRIPT_DIR"/*.sh "$SCRIPT_DIR"/lib/*.sh; do
        if [[ -f "$script" ]]; then
            echo -n "Checking $(basename "$script")... "
            if bash -n "$script" 2>/dev/null; then
                echo -e "${COLOR_GREEN}✓${COLOR_RESET}"
            else
                echo -e "${COLOR_RED}✗ FAILED${COLOR_RESET}"
                errors=$((errors + 1))
            fi
        fi
    done

    if [[ $errors -eq 0 ]]; then
        echo -e "${COLOR_GREEN}All scripts have valid syntax${COLOR_RESET}"
    else
        echo -e "${COLOR_RED}$errors script(s) have syntax errors${COLOR_RESET}"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + errors))
    fi
}

check_dependencies() {
    echo ""
    echo "============================================================================"
    echo "Checking Dependencies"
    echo "============================================================================"

    local required_commands=(
        "bash"
        "git"
        "gh"
        "jq"
        "curl"
    )

    local errors=0

    for cmd in "${required_commands[@]}"; do
        echo -n "Checking $cmd... "
        if command -v "$cmd" &>/dev/null; then
            local version
            case "$cmd" in
                gh)
                    version=$(gh --version | head -1)
                    ;;
                jq)
                    version=$(jq --version)
                    ;;
                git)
                    version=$(git --version)
                    ;;
                bash)
                    version=$BASH_VERSION
                    ;;
                curl)
                    version=$(curl --version | head -1)
                    ;;
            esac
            echo -e "${COLOR_GREEN}✓${COLOR_RESET} ($version)"
        else
            echo -e "${COLOR_RED}✗ NOT FOUND${COLOR_RESET}"
            errors=$((errors + 1))
        fi
    done

    if [[ $errors -eq 0 ]]; then
        echo -e "${COLOR_GREEN}All dependencies available${COLOR_RESET}"
    else
        echo -e "${COLOR_RED}$errors missing dependencies${COLOR_RESET}"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + errors))
    fi
}

check_permissions() {
    echo ""
    echo "============================================================================"
    echo "Checking File Permissions"
    echo "============================================================================"

    local errors=0

    for script in "$SCRIPT_DIR"/*.sh "$SCRIPT_DIR"/lib/*.sh; do
        if [[ -f "$script" ]]; then
            echo -n "Checking $(basename "$script")... "
            if [[ -x "$script" ]]; then
                echo -e "${COLOR_GREEN}✓ executable${COLOR_RESET}"
            else
                echo -e "${COLOR_YELLOW}⚠ not executable${COLOR_RESET}"
                chmod +x "$script"
                echo "  Fixed: made executable"
            fi
        fi
    done

    echo -e "${COLOR_GREEN}All scripts are executable${COLOR_RESET}"
}

check_environment() {
    echo ""
    echo "============================================================================"
    echo "Checking Environment Configuration"
    echo "============================================================================"

    local warnings=0

    # Optional but recommended
    local optional_vars=(
        "GITHUB_TOKEN:GitHub API authentication"
        "TEST_REPO:Target test repository"
        "RUNNER_ORG:Organization for runner tests"
    )

    for var_desc in "${optional_vars[@]}"; do
        IFS=':' read -r var desc <<< "$var_desc"
        echo -n "Checking $var ($desc)... "
        if [[ -n "${!var:-}" ]]; then
            echo -e "${COLOR_GREEN}✓ set${COLOR_RESET}"
        else
            echo -e "${COLOR_YELLOW}⚠ not set (optional)${COLOR_RESET}"
            warnings=$((warnings + 1))
        fi
    done

    if [[ $warnings -eq 0 ]]; then
        echo -e "${COLOR_GREEN}All environment variables configured${COLOR_RESET}"
    else
        echo -e "${COLOR_YELLOW}$warnings optional variables not set${COLOR_RESET}"
        echo "Note: Tests will run with limited functionality"
    fi
}

check_test_structure() {
    echo ""
    echo "============================================================================"
    echo "Checking Test Structure"
    echo "============================================================================"

    local required_files=(
        "lib/test-helpers.sh:Helper functions library"
        "test-pr-review-journey.sh:PR review test"
        "test-issue-analysis-journey.sh:Issue analysis test"
        "test-autofix-journey.sh:Auto-fix test"
        "test-runner-lifecycle.sh:Runner lifecycle test"
        "test-failure-recovery.sh:Failure recovery test"
        "run-all-e2e-tests.sh:Master test runner"
        "README.md:Documentation"
    )

    local errors=0

    for file_desc in "${required_files[@]}"; do
        IFS=':' read -r file desc <<< "$file_desc"
        echo -n "Checking $file ($desc)... "
        if [[ -f "$SCRIPT_DIR/$file" ]]; then
            echo -e "${COLOR_GREEN}✓${COLOR_RESET}"
        else
            echo -e "${COLOR_RED}✗ MISSING${COLOR_RESET}"
            errors=$((errors + 1))
        fi
    done

    if [[ $errors -eq 0 ]]; then
        echo -e "${COLOR_GREEN}All required files present${COLOR_RESET}"
    else
        echo -e "${COLOR_RED}$errors required files missing${COLOR_RESET}"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + errors))
    fi
}

check_workflow() {
    echo ""
    echo "============================================================================"
    echo "Checking CI/CD Workflow"
    echo "============================================================================"

    local workflow_file="$SCRIPT_DIR/../../../.github/workflows/e2e-tests.yml"

    echo -n "Checking e2e-tests.yml... "
    if [[ -f "$workflow_file" ]]; then
        echo -e "${COLOR_GREEN}✓${COLOR_RESET}"

        # Validate YAML syntax if yq is available
        if command -v yq &>/dev/null; then
            echo -n "Validating YAML syntax... "
            if yq eval '.' "$workflow_file" >/dev/null 2>&1; then
                echo -e "${COLOR_GREEN}✓${COLOR_RESET}"
            else
                echo -e "${COLOR_YELLOW}⚠ Cannot validate (yq error)${COLOR_RESET}"
            fi
        fi
    else
        echo -e "${COLOR_YELLOW}⚠ not found${COLOR_RESET}"
        echo "  Workflow file should be at: $workflow_file"
    fi
}

print_summary() {
    echo ""
    echo "============================================================================"
    echo "VALIDATION SUMMARY"
    echo "============================================================================"

    if [[ $VALIDATION_ERRORS -eq 0 ]]; then
        echo -e "${COLOR_GREEN}✓ ALL VALIDATIONS PASSED${COLOR_RESET}"
        echo ""
        echo "E2E test suite is ready to run!"
        echo ""
        echo "Run tests with:"
        echo "  cd $SCRIPT_DIR"
        echo "  bash run-all-e2e-tests.sh"
        return 0
    else
        echo -e "${COLOR_RED}✗ $VALIDATION_ERRORS VALIDATION ERROR(S)${COLOR_RESET}"
        echo ""
        echo "Please fix the errors above before running tests."
        return 1
    fi
}

# ============================================================================
# Main
# ============================================================================

main() {
    echo ""
    echo "###############################################################################"
    echo "# E2E TEST SUITE VALIDATION"
    echo "###############################################################################"

    check_syntax
    check_dependencies
    check_permissions
    check_environment
    check_test_structure
    check_workflow

    print_summary
}

main "$@"
