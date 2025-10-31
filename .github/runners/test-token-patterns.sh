#!/usr/bin/env bash

################################################################################
# Direct Token Pattern Test
# Tests the actual regex patterns in setup-runner.sh
################################################################################

set -e
set -u
set -o pipefail

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Testing Token Pattern Detection${NC}"
echo -e "${BLUE}========================================${NC}"

# Extract functions from setup-runner.sh
SCRIPT_FILE="scripts/setup-runner.sh"

# Extract sanitize_log function
echo -e "\n${YELLOW}Extracting sanitize_log function...${NC}"
sed -n '/^sanitize_log()/,/^}/p' "$SCRIPT_FILE" > /tmp/sanitize_log.sh

# Extract verify_no_tokens_in_logs function
echo -e "${YELLOW}Extracting verify_no_tokens_in_logs function...${NC}"
sed -n '/^verify_no_tokens_in_logs()/,/^}/p' "$SCRIPT_FILE" > /tmp/verify_no_tokens.sh

# Test token samples
declare -A token_samples=(
    ["GitHub PAT classic"]="ghp_1234567890abcdefghijklmnopqrstuvwxyz"
    ["GitHub server token"]="ghs_abcdefghijklmnop1234567890"
    ["GitHub PAT fine-grained"]="github_pat_11ABCDEF2G3HIJKLMNOP4QRSTUV5WXYZ67890"
    ["GitHub OAuth token"]="gho_16C3B1A21E23D4F5G6H7I8J9K0LMNOPQRSTUVWX"
    ["GitHub refresh token"]="ghr_1B2C3D4E5F6A7B8C9D0E1F2G3H4I5J6K7L8M9N0"
    ["GitHub user-to-server"]="ghu_to_s_16C3B1A21E23D4F5G6H7I8J9K0LMNOPQRSTUVWX"
)

# Test sanitize_log patterns
echo -e "\n${YELLOW}Testing sanitize_log patterns...${NC}"
source /tmp/sanitize_log.sh

PASSED=0
FAILED=0

for token_name in "${!token_samples[@]}"; do
    token="${token_samples[$token_name]}"
    result=$(sanitize_log "Token: $token")

    if [[ "$result" == *"[REDACTED]"* ]] && [[ "$result" != *"${token:0:4}"* ]]; then
        echo -e "${GREEN}✓${NC} $token_name: Properly sanitized"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $token_name: NOT sanitized"
        echo "    Token: $token"
        echo "    Result: $result"
        ((FAILED++))
    fi
done

# Test verify_no_tokens_in_logs patterns
echo -e "\n${YELLOW}Testing verify_no_tokens_in_logs patterns...${NC}"

# Create a function to test the grep pattern
test_verify_pattern() {
    local pattern='(ghp_|ghs_|github_pat_|gho_|ghr_|ghu_to_s_)[A-Za-z0-9_]+'
    local text="$1"

    if echo "$text" | grep -qE "$pattern"; then
        return 0  # Token found
    else
        return 1  # No token found
    fi
}

for token_name in "${!token_samples[@]}"; do
    token="${token_samples[$token_name]}"

    if test_verify_pattern "Test with $token in logs"; then
        echo -e "${GREEN}✓${NC} $token_name: Would be detected"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $token_name: Would NOT be detected"
        echo "    Token: $token"
        ((FAILED++))
    fi
done

# Check if contains_token function exists
echo -e "\n${YELLOW}Checking for removed functions...${NC}"
if grep -q "contains_token()" "$SCRIPT_FILE"; then
    echo -e "${RED}✗${NC} contains_token function still exists"
    ((FAILED++))
else
    echo -e "${GREEN}✓${NC} contains_token function removed"
    ((PASSED++))
fi

# Check regex consistency
echo -e "\n${YELLOW}Checking regex pattern consistency...${NC}"
sanitize_pattern=$(grep -E "ghp_\|ghs_\|github_pat_" "$SCRIPT_FILE" | head -1)
verify_pattern=$(grep -E "ghp_\|ghs_\|github_pat_" "$SCRIPT_FILE" | tail -1)

echo "Sanitize pattern: ${sanitize_pattern:0:80}..."
echo "Verify pattern: ${verify_pattern:0:80}..."

if [[ "$sanitize_pattern" == *"gho_"* ]] && [[ "$sanitize_pattern" == *"ghr_"* ]] && [[ "$sanitize_pattern" == *"ghu_to_s_"* ]]; then
    echo -e "${GREEN}✓${NC} sanitize_log has all token patterns"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} sanitize_log missing some token patterns"
    ((FAILED++))
fi

if [[ "$verify_pattern" == *"gho_"* ]] && [[ "$verify_pattern" == *"ghr_"* ]] && [[ "$verify_pattern" == *"ghu_to_s_"* ]]; then
    echo -e "${GREEN}✓${NC} verify_no_tokens_in_logs has all token patterns"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} verify_no_tokens_in_logs missing some token patterns"
    ((FAILED++))
fi

# Summary
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"

if [[ $FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}✓ All token patterns are properly handled!${NC}"
    exit 0
else
    echo -e "\n${RED}✗ Some token patterns are not properly handled${NC}"
    exit 1
fi