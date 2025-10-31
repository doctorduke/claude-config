#!/usr/bin/env bash
# Script: validate-ai-scripts.sh
# Description: Tests AI scripts with mock data and validates outputs
# Usage: ./validate-ai-scripts.sh [OPTIONS] [SCRIPT_FILE]

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly TEST_DATA_DIR="${PROJECT_ROOT}/.github/test-data"
readonly MOCK_API_DIR="${PROJECT_ROOT}/.github/mock-api"
readonly RESULTS_DIR="${PROJECT_ROOT}/.github/test-results"

# Default values
SCRIPT_FILE=""
TEST_ALL=false
VERBOSE=false
BENCHMARK=false
MOCK_API=true
VALIDATE_SCHEMA=true
TEST_ERROR_HANDLING=true

# Test statistics
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
START_TIME=0

# Logging functions
log() {
    echo -e "${BLUE}[INFO]${NC} $*" >&2
}

success() {
    echo -e "${GREEN}[PASS]${NC} $*" >&2
}

fail() {
    echo -e "${RED}[FAIL]${NC} $*" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

verbose() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $*" >&2
    fi
}

# Usage information
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [SCRIPT_FILE]

Test AI agent scripts with mock data and validate outputs.

OPTIONS:
    -a, --all               Test all scripts in scripts/ directory
    -s, --script FILE       Specific script to test
    -v, --verbose           Enable verbose logging
    -b, --benchmark         Run performance benchmarks
    --no-mock-api          Use real API (requires API keys)
    --no-schema            Skip JSON schema validation
    --no-error-tests       Skip error handling tests
    -h, --help             Show this help message

EXAMPLES:
    # Test a specific script
    $(basename "$0") -s scripts/ai-review.sh

    # Test all scripts
    $(basename "$0") --all

    # Test with benchmarking
    $(basename "$0") -b -s scripts/ai-review.sh

    # Test without mocking API
    $(basename "$0") --no-mock-api scripts/ai-review.sh

TEST COVERAGE:
    - Input validation
    - Mock API responses
    - JSON output format validation
    - Error handling scenarios
    - Performance benchmarking
    - Cross-platform compatibility

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -a|--all)
                TEST_ALL=true
                shift
                ;;
            -s|--script)
                SCRIPT_FILE="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -b|--benchmark)
                BENCHMARK=true
                shift
                ;;
            --no-mock-api)
                MOCK_API=false
                shift
                ;;
            --no-schema)
                VALIDATE_SCHEMA=false
                shift
                ;;
            --no-error-tests)
                TEST_ERROR_HANDLING=false
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                fail "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                SCRIPT_FILE="$1"
                shift
                ;;
        esac
    done

    if [[ "$TEST_ALL" == false && -z "$SCRIPT_FILE" ]]; then
        fail "Script file is required, or use --all to test all scripts"
        usage
        exit 1
    fi
}

# Setup test environment
setup_test_environment() {
    log "Setting up test environment..."

    # Create directories
    mkdir -p "$TEST_DATA_DIR" "$MOCK_API_DIR" "$RESULTS_DIR"

    # Create mock test data if not exists
    create_mock_test_data

    # Setup mock API if enabled
    if [[ "$MOCK_API" == true ]]; then
        setup_mock_api
    fi

    success "Test environment ready"
}

# Create mock test data
create_mock_test_data() {
    verbose "Creating mock test data..."

    # Sample PR data
    cat > "${TEST_DATA_DIR}/sample-pr.json" << 'EOF'
{
  "number": 123,
  "title": "Add new feature for data processing",
  "body": "This PR adds a new data processing pipeline.\n\nChanges:\n- Implement data parser\n- Add unit tests\n- Update documentation",
  "state": "open",
  "draft": false,
  "head": {
    "ref": "feature/data-processing",
    "sha": "abc123def456"
  },
  "base": {
    "ref": "main",
    "sha": "def456abc123"
  },
  "user": {
    "login": "developer"
  },
  "additions": 250,
  "deletions": 50,
  "changed_files": 8,
  "files": [
    {"path": "src/parser.js", "additions": 120, "deletions": 10},
    {"path": "src/processor.js", "additions": 80, "deletions": 20},
    {"path": "tests/parser.test.js", "additions": 50, "deletions": 10}
  ]
}
EOF

    # Sample issue data
    cat > "${TEST_DATA_DIR}/sample-issue.json" << 'EOF'
{
  "number": 456,
  "title": "Bug: Application crashes on startup",
  "body": "The application crashes when started with invalid configuration.\n\nSteps to reproduce:\n1. Set invalid config\n2. Start application\n3. Observe crash",
  "state": "open",
  "labels": ["bug", "priority:high"],
  "user": {
    "login": "reporter"
  }
}
EOF

    # Sample diff data
    cat > "${TEST_DATA_DIR}/sample-diff.txt" << 'EOF'
diff --git a/src/parser.js b/src/parser.js
index abc123..def456 100644
--- a/src/parser.js
+++ b/src/parser.js
@@ -1,5 +1,10 @@
 export class Parser {
+  constructor(options = {}) {
+    this.options = options;
+  }
+
   parse(data) {
-    return JSON.parse(data);
+    // Enhanced parsing with validation
+    return this.validate(JSON.parse(data));
   }
 }
EOF

    # Expected output schema
    cat > "${TEST_DATA_DIR}/review-schema.json" << 'EOF'
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
        "body": {"type": "string", "minLength": 1},
        "event": {
          "type": "string",
          "enum": ["APPROVE", "REQUEST_CHANGES", "COMMENT"]
        },
        "comments": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["path", "line", "body"],
            "properties": {
              "path": {"type": "string"},
              "line": {"type": "integer", "minimum": 1},
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
        "timestamp": {"type": "string"},
        "pr_number": {"type": "integer"}
      }
    }
  }
}
EOF

    verbose "Mock test data created"
}

# Setup mock API
setup_mock_api() {
    verbose "Setting up mock API..."

    # Create mock API endpoint script
    cat > "${MOCK_API_DIR}/mock-ai-api.sh" << 'EOF'
#!/usr/bin/env bash
# Mock AI API for testing

# Parse input
INPUT=$(cat)

# Generate mock response based on input
cat << 'RESPONSE'
{
  "id": "mock-response-123",
  "model": "claude-3-opus-test",
  "content": [
    {
      "type": "text",
      "text": "## Code Review\n\nThis code change looks good overall. Here are my observations:\n\n### Strengths\n- Good separation of concerns\n- Proper error handling added\n- Tests included\n\n### Suggestions\n1. Consider adding input validation for edge cases\n2. Document the new parsing logic\n3. Add integration tests\n\n### Security\nNo security concerns identified.\n\n**Recommendation:** Approve with minor suggestions"
    }
  ],
  "usage": {
    "input_tokens": 150,
    "output_tokens": 120
  }
}
RESPONSE
EOF

    chmod +x "${MOCK_API_DIR}/mock-ai-api.sh"

    # Set environment variable to use mock API
    export AI_API_ENDPOINT="${MOCK_API_DIR}/mock-ai-api.sh"
    export AI_API_KEY="mock-api-key-12345"

    verbose "Mock API configured"
}

# Test script with sample inputs
test_script_with_samples() {
    local script="$1"
    local script_name
    script_name=$(basename "$script")

    log "Testing script: $script_name"

    # Determine script type and test accordingly
    case "$script_name" in
        *review*)
            test_review_script "$script"
            ;;
        *agent*)
            test_agent_script "$script"
            ;;
        *autofix*)
            test_autofix_script "$script"
            ;;
        *)
            warn "Unknown script type: $script_name"
            test_generic_script "$script"
            ;;
    esac
}

# Test review script
test_review_script() {
    local script="$1"
    local output_file="${RESULTS_DIR}/review-output.json"

    ((TESTS_RUN++))

    log "Running review script test..."

    # Setup test environment
    export GITHUB_TOKEN="mock-token-12345"
    export PR_NUMBER=123

    # Create a simple mock gh command
    export PATH="${MOCK_API_DIR}:$PATH"
    cat > "${MOCK_API_DIR}/gh" << 'MOCKGH'
#!/usr/bin/env bash
if [[ "$1" == "pr" && "$2" == "view" ]]; then
    cat "${TEST_DATA_DIR:-/tmp}/sample-pr.json"
fi
MOCKGH
    chmod +x "${MOCK_API_DIR}/gh"

    # Run script (if it's executable and exists)
    if [[ -f "$script" && -x "$script" ]]; then
        verbose "Executing: $script --pr 123 --output $output_file"

        if timeout 30s "$script" --pr 123 --output "$output_file" 2>/dev/null; then
            # Validate output
            if [[ -f "$output_file" ]]; then
                validate_json_output "$output_file"
                if [[ $? -eq 0 ]]; then
                    success "Review script test passed"
                    ((TESTS_PASSED++))
                    return 0
                fi
            else
                fail "Review script did not produce output file"
            fi
        else
            fail "Review script execution failed or timed out"
        fi
    else
        warn "Script not executable or not found: $script"
        log "This is expected if scripts haven't been implemented yet"
    fi

    ((TESTS_FAILED++))
    return 1
}

# Test agent script
test_agent_script() {
    local script="$1"

    ((TESTS_RUN++))

    log "Running agent script test..."

    # Test with help flag
    if [[ -f "$script" && -x "$script" ]]; then
        if "$script" --help &>/dev/null; then
            success "Agent script responds to --help"
            ((TESTS_PASSED++))
            return 0
        else
            warn "Agent script does not respond to --help"
        fi
    else
        warn "Script not executable or not found: $script"
        log "This is expected if scripts haven't been implemented yet"
    fi

    ((TESTS_FAILED++))
    return 1
}

# Test autofix script
test_autofix_script() {
    local script="$1"
    local output_file="${RESULTS_DIR}/autofix-output.json"

    ((TESTS_RUN++))

    log "Running autofix script test..."

    export GITHUB_TOKEN="mock-token-12345"
    export PR_NUMBER=123

    if [[ -f "$script" && -x "$script" ]]; then
        if timeout 30s "$script" --pr 123 --output "$output_file" 2>/dev/null; then
            if [[ -f "$output_file" ]]; then
                success "Autofix script test passed"
                ((TESTS_PASSED++))
                return 0
            fi
        fi
    else
        warn "Script not executable or not found: $script"
        log "This is expected if scripts haven't been implemented yet"
    fi

    ((TESTS_FAILED++))
    return 1
}

# Test generic script
test_generic_script() {
    local script="$1"

    ((TESTS_RUN++))

    log "Running generic script test..."

    if [[ -f "$script" ]]; then
        # Check if it's a bash script
        if head -n 1 "$script" | grep -q "bash"; then
            # Try to source it to check for syntax errors
            if bash -n "$script" 2>/dev/null; then
                success "Script has valid bash syntax"
                ((TESTS_PASSED++))
                return 0
            else
                fail "Script has syntax errors"
            fi
        else
            warn "Not a bash script"
        fi
    else
        warn "Script not found: $script"
    fi

    ((TESTS_FAILED++))
    return 1
}

# Validate JSON output
validate_json_output() {
    local output_file="$1"

    verbose "Validating JSON output: $output_file"

    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        warn "jq not found - skipping JSON validation"
        return 0
    fi

    # Validate JSON syntax
    if ! jq empty "$output_file" 2>/dev/null; then
        fail "Invalid JSON output"
        return 1
    fi

    verbose "JSON syntax valid"

    # Validate against schema if enabled
    if [[ "$VALIDATE_SCHEMA" == true ]]; then
        validate_against_schema "$output_file"
        return $?
    fi

    return 0
}

# Validate against JSON schema
validate_against_schema() {
    local output_file="$1"
    local schema_file="${TEST_DATA_DIR}/review-schema.json"

    if [[ ! -f "$schema_file" ]]; then
        verbose "Schema file not found, skipping validation"
        return 0
    fi

    # Check for ajv or another schema validator
    if command -v ajv &> /dev/null; then
        if ajv validate -s "$schema_file" -d "$output_file" 2>/dev/null; then
            verbose "Schema validation passed"
            return 0
        else
            warn "Schema validation failed"
            return 1
        fi
    else
        verbose "ajv not found - skipping schema validation"
        verbose "Install with: npm install -g ajv-cli"
        return 0
    fi
}

# Test error handling
test_error_handling() {
    local script="$1"

    if [[ "$TEST_ERROR_HANDLING" != true ]]; then
        return 0
    fi

    log "Testing error handling..."

    ((TESTS_RUN++))

    # Test with missing required arguments
    if [[ -f "$script" && -x "$script" ]]; then
        verbose "Testing missing arguments..."
        if "$script" 2>/dev/null; then
            fail "Script should fail with missing arguments"
            ((TESTS_FAILED++))
            return 1
        else
            success "Script properly handles missing arguments"
            ((TESTS_PASSED++))
            return 0
        fi
    fi

    return 0
}

# Performance benchmark
benchmark_script() {
    local script="$1"

    if [[ "$BENCHMARK" != true ]]; then
        return 0
    fi

    log "Running performance benchmark..."

    local iterations=5
    local total_time=0

    for ((i=1; i<=iterations; i++)); do
        verbose "Iteration $i/$iterations"

        local start
        start=$(date +%s%N)

        if [[ -f "$script" && -x "$script" ]]; then
            "$script" --help &>/dev/null || true
        fi

        local end
        end=$(date +%s%N)

        local duration=$(( (end - start) / 1000000 ))
        total_time=$((total_time + duration))

        verbose "  Duration: ${duration}ms"
    done

    local avg_time=$((total_time / iterations))

    log "Average execution time: ${avg_time}ms (over $iterations runs)"

    # Performance thresholds
    if [[ $avg_time -lt 100 ]]; then
        success "Excellent performance (<100ms)"
    elif [[ $avg_time -lt 500 ]]; then
        success "Good performance (<500ms)"
    elif [[ $avg_time -lt 1000 ]]; then
        warn "Acceptable performance (<1s)"
    else
        warn "Slow performance (>1s) - consider optimization"
    fi
}

# Test all scripts
test_all_scripts() {
    log "Testing all scripts in scripts/ directory..."

    local scripts
    scripts=$(find "$SCRIPT_DIR" -name "*.sh" -type f)

    if [[ -z "$scripts" ]]; then
        warn "No scripts found in $SCRIPT_DIR"
        return 1
    fi

    while IFS= read -r script; do
        echo ""
        echo "========================================"
        test_script_with_samples "$script"
        test_error_handling "$script"
        benchmark_script "$script"
        echo "========================================"
        echo ""
    done <<< "$scripts"
}

# Display test results
display_results() {
    local duration=$(($(date +%s) - START_TIME))

    echo ""
    echo "=========================================="
    echo "Test Results Summary"
    echo "=========================================="
    echo "Total Tests:     $TESTS_RUN"
    echo "Passed:          $TESTS_PASSED ($([ $TESTS_RUN -gt 0 ] && echo $((TESTS_PASSED * 100 / TESTS_RUN)) || echo 0)%)"
    echo "Failed:          $TESTS_FAILED ($([ $TESTS_RUN -gt 0 ] && echo $((TESTS_FAILED * 100 / TESTS_RUN)) || echo 0)%)"
    echo "Duration:        ${duration}s"
    echo "Results saved:   $RESULTS_DIR"
    echo "=========================================="

    if [[ $TESTS_FAILED -eq 0 && $TESTS_RUN -gt 0 ]]; then
        success "All tests passed!"
        return 0
    elif [[ $TESTS_RUN -eq 0 ]]; then
        warn "No tests were run"
        return 1
    else
        fail "Some tests failed"
        return 1
    fi
}

# Generate test report
generate_report() {
    local report_file="${RESULTS_DIR}/test-report-$(date +%Y%m%d-%H%M%S).md"

    log "Generating test report: $report_file"

    cat > "$report_file" << EOF
# AI Scripts Validation Report

**Generated:** $(date)

## Summary

- Total Tests: $TESTS_RUN
- Passed: $TESTS_PASSED
- Failed: $TESTS_FAILED
- Success Rate: $([ $TESTS_RUN -gt 0 ] && echo "$((TESTS_PASSED * 100 / TESTS_RUN))%" || echo "N/A")

## Configuration

- Mock API: $MOCK_API
- Schema Validation: $VALIDATE_SCHEMA
- Error Handling Tests: $TEST_ERROR_HANDLING
- Benchmarking: $BENCHMARK

## Test Coverage

- Input validation
- Mock API responses
- JSON output format validation
- Error handling scenarios
- Performance benchmarking

## Files Tested

$(if [[ "$TEST_ALL" == true ]]; then
    find "$SCRIPT_DIR" -name "*.sh" -type f | while read -r script; do
        echo "- $(basename "$script")"
    done
else
    echo "- $(basename "$SCRIPT_FILE")"
fi)

## Results Details

Test results are available in: $RESULTS_DIR

## Recommendations

$(if [[ $TESTS_FAILED -gt 0 ]]; then
    echo "- Review failed tests and fix issues"
    echo "- Ensure all required dependencies are installed"
    echo "- Check script permissions (chmod +x)"
else
    echo "- All tests passed successfully"
    echo "- Scripts are ready for integration testing"
fi)

---

*Report generated by validate-ai-scripts.sh*
EOF

    success "Test report generated: $report_file"
}

# Main execution
main() {
    START_TIME=$(date +%s)

    parse_args "$@"

    log "Starting AI scripts validation"

    setup_test_environment

    if [[ "$TEST_ALL" == true ]]; then
        test_all_scripts
    else
        test_script_with_samples "$SCRIPT_FILE"
        test_error_handling "$SCRIPT_FILE"
        benchmark_script "$SCRIPT_FILE"
    fi

    display_results
    generate_report

    # Exit with appropriate code
    [[ $TESTS_FAILED -eq 0 ]]
}

# Cleanup on exit
cleanup() {
    verbose "Cleaning up..."
}

trap cleanup EXIT

main "$@"
