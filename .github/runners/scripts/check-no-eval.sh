#!/usr/bin/env bash

################################################################################
# Script: check-no-eval.sh
# Purpose: Security check to prevent dangerous eval usage in shell scripts
# Usage: ./scripts/check-no-eval.sh
################################################################################

set -e

# Color output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

echo "Checking for dangerous eval usage..."

# Find all shell scripts
shell_files=$(find . -type f \( -name "*.sh" -o -name "*.bash" \) -not -path "./.git/*" -not -path "./node_modules/*")

found_eval=false
dangerous_files=()

for file in $shell_files; do
    # Skip checking this script itself
    if [[ "$file" == "./scripts/check-no-eval.sh" ]]; then
        continue
    fi

    # Look for eval usage, excluding safe yq eval commands and comments
    # We look for eval followed by space or quote to avoid matching "evaluate" etc.
    if grep -E '^\s*[^#]*\beval\s+["$]' "$file" 2>/dev/null | grep -v "yq eval" > /dev/null; then
        echo -e "${RED}[ERROR]${NC} Dangerous eval usage found in: $file"
        grep -nE '^\s*[^#]*\beval\s+["$]' "$file" | grep -v "yq eval" || true
        found_eval=true
        dangerous_files+=("$file")
    fi
done

if [ "$found_eval" = true ]; then
    echo -e "\n${RED}Security check failed!${NC}"
    echo "The following files contain dangerous eval usage:"
    for file in "${dangerous_files[@]}"; do
        echo "  - $file"
    done
    echo ""
    echo "Recommendations:"
    echo "1. Use arrays for command construction instead of eval"
    echo "2. Use 'declare' for dynamic variable assignment"
    echo "3. Use parameter expansion for variable indirection"
    echo ""
    echo "Example fixes:"
    echo '  # UNSAFE: eval "${cmd}"'
    echo '  # SAFE: Use array'
    echo '  cmd_array=("git" "commit" "-m" "${message}")'
    echo '  "${cmd_array[@]}"'
    echo ""
    echo '  # UNSAFE: eval "var_${name}=value"'
    echo '  # SAFE: Use declare'
    echo '  declare "var_${name}=value"'
    exit 1
else
    echo -e "${GREEN}✓ No dangerous eval usage found${NC}"
    echo "All shell scripts passed security check"
fi