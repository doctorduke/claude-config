#!/bin/bash
# Coverage Tracking Script
# Tracks which functions are tested and reports coverage

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
readonly SCRIPTS_DIR="$PROJECT_ROOT/scripts"
readonly TESTS_DIR="$SCRIPT_DIR/.."

# Colors
readonly COLOR_RESET='\033[0m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BLUE='\033[0;34m'

# Extract all functions from shell scripts
extract_functions() {
    local script_file="$1"
    grep -E '^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(\)' "$script_file" | \
        sed -E 's/^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\(\).*/\1/' || true
}

# Check if a function is tested
is_function_tested() {
    local function_name="$1"

    # Search for test functions that might test this function
    # Look for test_<function_name> or references to the function in tests
    grep -r "test_${function_name}" "$TESTS_DIR" &>/dev/null && return 0
    grep -r "$function_name" "$TESTS_DIR" | grep -v "^Binary" | grep -qE "(assert|mock|test)" && return 0

    return 1
}

# Discover all shell scripts in the project
discover_scripts() {
    find "$SCRIPTS_DIR" -name "*.sh" -type f ! -path "*/tests/*" | sort
}

# Generate coverage report
generate_coverage_report() {
    local total_functions=0
    local tested_functions=0
    local untested_functions=()

    echo ""
    echo "========================================"
    echo "        COVERAGE REPORT"
    echo "========================================"
    echo ""

    while IFS= read -r script_file; do
        local script_name="$(basename "$script_file")"
        local functions

        # Extract functions from script
        mapfile -t functions < <(extract_functions "$script_file")

        if [[ ${#functions[@]} -eq 0 ]]; then
            continue
        fi

        echo "Script: $script_name"
        echo "----------------------------------------"

        local script_total=0
        local script_tested=0

        for func in "${functions[@]}"; do
            # Skip common/generic function names
            [[ "$func" == "main" ]] && continue
            [[ "$func" == "usage" ]] && continue
            [[ "$func" == "help" ]] && continue

            ((total_functions++))
            ((script_total++))

            if is_function_tested "$func"; then
                echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} $func"
                ((tested_functions++))
                ((script_tested++))
            else
                echo -e "  ${COLOR_RED}✗${COLOR_RESET} $func"
                untested_functions+=("$script_name:$func")
            fi
        done

        if [[ $script_total -gt 0 ]]; then
            local script_coverage=$((script_tested * 100 / script_total))
            echo ""
            echo "  Coverage: $script_tested/$script_total ($script_coverage%)"
        fi

        echo ""
    done < <(discover_scripts)

    # Calculate overall coverage
    local coverage_percent=0
    if [[ $total_functions -gt 0 ]]; then
        coverage_percent=$((tested_functions * 100 / total_functions))
    fi

    echo "========================================"
    echo "SUMMARY"
    echo "========================================"
    echo "Total Functions:  $total_functions"
    echo -e "${COLOR_GREEN}Tested:${COLOR_RESET}           $tested_functions"
    echo -e "${COLOR_RED}Untested:${COLOR_RESET}         $((total_functions - tested_functions))"
    echo ""

    if [[ $coverage_percent -ge 80 ]]; then
        echo -e "Coverage: ${COLOR_GREEN}${coverage_percent}%${COLOR_RESET}"
    elif [[ $coverage_percent -ge 50 ]]; then
        echo -e "Coverage: ${COLOR_YELLOW}${coverage_percent}%${COLOR_RESET}"
    else
        echo -e "Coverage: ${COLOR_RED}${coverage_percent}%${COLOR_RESET}"
    fi

    echo ""

    # List untested functions
    if [[ ${#untested_functions[@]} -gt 0 ]]; then
        echo "========================================"
        echo "UNTESTED FUNCTIONS"
        echo "========================================"
        for func_ref in "${untested_functions[@]}"; do
            echo "  - $func_ref"
        done
        echo ""
    fi

    # Write coverage data to file
    local coverage_file="$TESTS_DIR/.coverage"

    # Build untested functions JSON array properly
    local untested_json=""
    if [[ ${#untested_functions[@]} -gt 0 && -n "${untested_functions[0]}" ]]; then
        untested_json=$(printf '    "%s"' "${untested_functions[0]}")
        if [[ ${#untested_functions[@]} -gt 1 ]]; then
            untested_json+=$(printf ',\n    "%s"' "${untested_functions[@]:1}")
        fi
    fi

    cat > "$coverage_file" << EOF
{
  "total_functions": $total_functions,
  "tested_functions": $tested_functions,
  "coverage_percent": $coverage_percent,
  "untested": [
${untested_json}
  ]
}
EOF

    echo "Coverage data written to: $coverage_file"
    echo ""

    return 0
}

# Generate HTML coverage report
generate_html_report() {
    local output_file="${1:-coverage.html}"

    # This is a placeholder for HTML generation
    # In a real implementation, this would generate a full HTML report

    cat > "$output_file" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Test Coverage Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #333; color: white; padding: 20px; }
        .summary { margin: 20px 0; }
        .coverage-high { color: green; }
        .coverage-medium { color: orange; }
        .coverage-low { color: red; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #333; color: white; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Test Coverage Report</h1>
    </div>
    <div class="summary">
        <h2>Summary</h2>
        <p>Coverage report will be generated here</p>
    </div>
</body>
</html>
EOF

    echo "HTML report generated: $output_file"
}

# Main execution
main() {
    generate_coverage_report
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
