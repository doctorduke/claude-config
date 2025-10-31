#!/bin/bash
# validate-security.sh - Comprehensive security validation script
# Security Auditor - Wave 2 Infrastructure Provisioning
# Validates all security controls and configurations

set -euo pipefail
IFS=$'\n\t'

# Script metadata
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly VALIDATION_REPORT="${SCRIPT_DIR}/../reports/security-validation-$(date +%Y%m%d-%H%M%S).json"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Validation counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# Initialize
init_validation() {
    mkdir -p "$(dirname "$VALIDATION_REPORT")"

    echo "=========================================="
    echo "Security Validation v${SCRIPT_VERSION}"
    echo "Started: $(date -Iseconds)"
    echo "=========================================="
    echo ""
}

# Check result functions
check_pass() {
    local check_name="$1"
    echo -e "${GREEN}[PASS]${NC} ${check_name}"
    ((PASSED_CHECKS++))
    ((TOTAL_CHECKS++))
}

check_fail() {
    local check_name="$1"
    local reason="$2"
    echo -e "${RED}[FAIL]${NC} ${check_name}: ${reason}"
    ((FAILED_CHECKS++))
    ((TOTAL_CHECKS++))
}

check_warn() {
    local check_name="$1"
    local reason="$2"
    echo -e "${YELLOW}[WARN]${NC} ${check_name}: ${reason}"
    ((WARNING_CHECKS++))
    ((TOTAL_CHECKS++))
}

# Environment validation
validate_environment() {
    echo "=== Environment Validation ==="

    # Check required environment variables
    if [[ -n "${GITHUB_ORG:-}" ]]; then
        check_pass "GITHUB_ORG configured"
    else
        check_fail "GITHUB_ORG not set" "Required environment variable missing"
    fi

    if [[ -n "${GITHUB_PAT:-}" ]]; then
        check_pass "GITHUB_PAT configured"

        # Validate PAT format
        if [[ "$GITHUB_PAT" =~ ^ghp_[a-zA-Z0-9]{36}$ ]] || [[ "$GITHUB_PAT" =~ ^github_pat_[a-zA-Z0-9]{22}_[a-zA-Z0-9]{59}$ ]]; then
            check_pass "PAT format valid"
        else
            check_warn "PAT format non-standard" "May be using custom or fine-grained token"
        fi
    else
        check_fail "GITHUB_PAT not set" "Required for API access"
    fi

    # Check required tools
    local required_tools=("curl" "jq" "git" "openssl")
    for tool in "${required_tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            check_pass "Tool available: ${tool}"
        else
            check_fail "Tool missing: ${tool}" "Install required tool"
        fi
    done

    echo ""
}

# PAT validation
validate_pat_authentication() {
    echo "=== PAT Authentication ==="

    if [[ -z "${GITHUB_PAT:-}" ]]; then
        check_fail "PAT authentication" "GITHUB_PAT not set"
        echo ""
        return
    fi

    # Test authentication
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
                     -H "Authorization: token ${GITHUB_PAT}" \
                     https://api.github.com/user)

    if [[ "$http_code" == "200" ]]; then
        check_pass "PAT authentication successful"
    else
        check_fail "PAT authentication failed" "HTTP ${http_code}"
    fi

    # Check PAT scopes
    local scopes
    scopes=$(curl -s -I -H "Authorization: token ${GITHUB_PAT}" \
                  https://api.github.com/rate_limit 2>/dev/null | \
                  grep -i "x-oauth-scopes:" | cut -d: -f2- | tr -d ' \r')

    if [[ -n "$scopes" ]]; then
        check_pass "PAT scopes retrieved: ${scopes}"

        # Validate required scopes
        if [[ "$scopes" == *"repo"* ]]; then
            check_pass "Required scope 'repo' present"
        else
            check_fail "Missing required scope" "Need 'repo' scope"
        fi

        if [[ "$scopes" == *"workflow"* ]]; then
            check_pass "Required scope 'workflow' present"
        else
            check_fail "Missing required scope" "Need 'workflow' scope"
        fi

        # Check for excessive scopes
        if [[ "$scopes" == *"admin:org"* ]]; then
            check_warn "Excessive scope detected" "admin:org not recommended"
        fi

        if [[ "$scopes" == *"delete"* ]]; then
            check_warn "Dangerous scope detected" "delete permissions not recommended"
        fi
    else
        check_warn "PAT scopes not available" "May be using fine-grained token"
    fi

    echo ""
}

# Secrets validation
validate_secrets() {
    echo "=== Secrets Configuration ==="

    if [[ -z "${GITHUB_PAT:-}" ]] || [[ -z "${GITHUB_ORG:-}" ]]; then
        check_fail "Secrets validation" "Missing required environment variables"
        echo ""
        return
    fi

    # Check organization secrets
    local secrets_response
    secrets_response=$(curl -s -H "Authorization: token ${GITHUB_PAT}" \
                            "https://api.github.com/orgs/${GITHUB_ORG}/actions/secrets")

    local total_secrets
    total_secrets=$(echo "$secrets_response" | jq -r '.total_count // 0')

    if [[ "$total_secrets" -gt 0 ]]; then
        check_pass "Organization has ${total_secrets} secret(s)"

        # Check for required secrets
        local secret_names
        secret_names=$(echo "$secrets_response" | jq -r '.secrets[].name' | tr '\n' ' ')

        if [[ "$secret_names" == *"AI_API_KEY"* ]]; then
            check_pass "Required secret 'AI_API_KEY' exists"
        else
            check_warn "Missing secret 'AI_API_KEY'" "May not be required for all setups"
        fi

        if [[ "$secret_names" == *"BOT_PAT"* ]]; then
            check_pass "Required secret 'BOT_PAT' exists"
        else
            check_warn "Missing secret 'BOT_PAT'" "Required for cross-repo operations"
        fi
    else
        check_fail "No organization secrets found" "Run setup-secrets.sh"
    fi

    echo ""
}

# Security leak detection
validate_no_leaks() {
    echo "=== Secret Leak Detection ==="

    # Check for hardcoded tokens in scripts
    local script_files
    script_files=$(find "${SCRIPT_DIR}" -type f \( -name "*.sh" -o -name "*.bash" \) 2>/dev/null || true)

    local leaks_found=0
    for file in $script_files; do
        if grep -qE "ghp_[a-zA-Z0-9]{36}" "$file" 2>/dev/null; then
            check_fail "Potential token leak in $(basename "$file")" "Found hardcoded PAT"
            leaks_found=1
        fi

        if grep -qE "github_pat_[a-zA-Z0-9]{22}_[a-zA-Z0-9]{59}" "$file" 2>/dev/null; then
            check_fail "Potential token leak in $(basename "$file")" "Found hardcoded fine-grained PAT"
            leaks_found=1
        fi
    done

    if [[ $leaks_found -eq 0 ]]; then
        check_pass "No hardcoded tokens in scripts"
    fi

    # Check logs for secrets
    if [[ -d "${SCRIPT_DIR}/../logs" ]]; then
        local log_files
        log_files=$(find "${SCRIPT_DIR}/../logs" -type f -name "*.log" 2>/dev/null || true)

        local log_leaks=0
        for file in $log_files; do
            if [[ -f "$file" ]] && grep -qE "(ghp_|github_pat_)" "$file" 2>/dev/null; then
                check_fail "Secret found in log: $(basename "$file")" "Review and clean immediately"
                log_leaks=1
            fi
        done

        if [[ $log_leaks -eq 0 ]]; then
            check_pass "No secrets found in log files"
        fi
    else
        check_warn "Logs directory not found" "Cannot verify log security"
    fi

    echo ""
}

# File permissions validation
validate_file_permissions() {
    echo "=== File Permissions ==="

    # Check .secrets directory
    if [[ -d "${SCRIPT_DIR}/../.secrets" ]]; then
        local secrets_perms
        secrets_perms=$(stat -c "%a" "${SCRIPT_DIR}/../.secrets" 2>/dev/null || stat -f "%OLp" "${SCRIPT_DIR}/../.secrets" 2>/dev/null || echo "unknown")

        if [[ "$secrets_perms" == "700" ]]; then
            check_pass ".secrets directory properly secured (700)"
        else
            check_fail ".secrets directory permissions" "Current: ${secrets_perms}, Expected: 700"
        fi
    else
        check_warn ".secrets directory not found" "Will be created when needed"
    fi

    # Check audit directory
    if [[ -d "${SCRIPT_DIR}/../audit" ]]; then
        local audit_perms
        audit_perms=$(stat -c "%a" "${SCRIPT_DIR}/../audit" 2>/dev/null || stat -f "%OLp" "${SCRIPT_DIR}/../audit" 2>/dev/null || echo "unknown")

        if [[ "$audit_perms" == "700" ]] || [[ "$audit_perms" == "750" ]]; then
            check_pass "Audit directory properly secured"
        else
            check_warn "Audit directory permissions" "Current: ${audit_perms}, Recommended: 700"
        fi
    fi

    # Check script permissions
    for script in "${SCRIPT_DIR}"/*.sh; do
        if [[ -f "$script" ]]; then
            local script_perms
            script_perms=$(stat -c "%a" "$script" 2>/dev/null || stat -f "%OLp" "$script" 2>/dev/null || echo "unknown")

            if [[ "$script_perms" =~ ^7[0-5][0-5]$ ]]; then
                check_pass "$(basename "$script") permissions OK"
            else
                check_warn "$(basename "$script") permissions" "Consider restricting to 755"
            fi
        fi
    done

    echo ""
}

# Token rotation validation
validate_token_rotation() {
    echo "=== Token Rotation Status ==="

    if [[ -f "${SCRIPT_DIR}/../.state/token-rotation-state.json" ]]; then
        local state
        state=$(cat "${SCRIPT_DIR}/../.state/token-rotation-state.json")

        # Check BOT_PAT rotation
        local bot_pat_rotation
        bot_pat_rotation=$(echo "$state" | jq -r '.bot_pat.last_rotation // ""')

        if [[ -n "$bot_pat_rotation" ]]; then
            local days_since
            if [[ "$OSTYPE" == "darwin"* ]]; then
                days_since=$(( ($(date +%s) - $(date -j -f "%Y-%m-%dT%H:%M:%S" "${bot_pat_rotation%%.*}" +%s 2>/dev/null || echo 0)) / 86400 ))
            else
                days_since=$(( ($(date +%s) - $(date -d "$bot_pat_rotation" +%s 2>/dev/null || echo 0)) / 86400 ))
            fi

            if [[ $days_since -lt 90 ]]; then
                check_pass "BOT_PAT rotation status (${days_since} days old)"
            else
                check_fail "BOT_PAT expired" "${days_since} days old (>90 days)"
            fi
        else
            check_warn "No BOT_PAT rotation history" "Run rotate-tokens.sh"
        fi
    else
        check_warn "Token rotation state not found" "Initialize with rotate-tokens.sh"
    fi

    # Check for rotation schedule
    if crontab -l 2>/dev/null | grep -q "rotate-tokens.sh"; then
        check_pass "Token rotation scheduled in crontab"
    elif systemctl is-enabled github-token-rotation.timer &>/dev/null; then
        check_pass "Token rotation scheduled via systemd"
    else
        check_warn "No automated rotation scheduled" "Run: ./rotate-tokens.sh --schedule"
    fi

    echo ""
}

# Network security validation
validate_network_security() {
    echo "=== Network Security ==="

    # Check TLS version support
    local tls_version
    tls_version=$(curl -s --tlsv1.2 -I https://api.github.com 2>&1 | head -1)

    if [[ "$tls_version" == *"200"* ]] || [[ "$tls_version" == *"301"* ]]; then
        check_pass "TLS 1.2+ supported"
    else
        check_fail "TLS configuration" "Unable to verify TLS support"
    fi

    # Verify HTTPS only
    local http_test
    http_test=$(curl -s -o /dev/null -w "%{http_code}" http://api.github.com 2>/dev/null || echo "000")

    if [[ "$http_test" == "301" ]] || [[ "$http_test" == "000" ]]; then
        check_pass "HTTPS enforcement working"
    else
        check_warn "HTTP redirect test" "Unexpected response: ${http_test}"
    fi

    # Check certificate validation
    if curl -s --cacert /dev/null https://api.github.com 2>&1 | grep -q "certificate"; then
        check_pass "Certificate validation enabled"
    else
        check_warn "Certificate validation" "Could not verify cert checking"
    fi

    echo ""
}

# Generate validation report
generate_report() {
    local report
    report=$(jq -n \
        --arg timestamp "$(date -Iseconds)" \
        --arg version "${SCRIPT_VERSION}" \
        --arg total "${TOTAL_CHECKS}" \
        --arg passed "${PASSED_CHECKS}" \
        --arg failed "${FAILED_CHECKS}" \
        --arg warnings "${WARNING_CHECKS}" \
        '{
            timestamp: $timestamp,
            validator_version: $version,
            summary: {
                total_checks: ($total | tonumber),
                passed: ($passed | tonumber),
                failed: ($failed | tonumber),
                warnings: ($warnings | tonumber),
                pass_rate: (($passed | tonumber) / ($total | tonumber) * 100)
            },
            status: (if ($failed | tonumber) > 0 then "FAILED" elif ($warnings | tonumber) > 3 then "WARNING" else "PASSED" end)
        }')

    echo "$report" > "$VALIDATION_REPORT"
}

# Display summary
display_summary() {
    echo ""
    echo "=========================================="
    echo "VALIDATION SUMMARY"
    echo "=========================================="
    echo "Total Checks: ${TOTAL_CHECKS}"
    echo -e "${GREEN}Passed: ${PASSED_CHECKS}${NC}"
    echo -e "${RED}Failed: ${FAILED_CHECKS}${NC}"
    echo -e "${YELLOW}Warnings: ${WARNING_CHECKS}${NC}"

    local pass_rate
    pass_rate=$(( PASSED_CHECKS * 100 / TOTAL_CHECKS ))
    echo "Pass Rate: ${pass_rate}%"

    echo ""
    if [[ $FAILED_CHECKS -eq 0 ]]; then
        echo -e "${GREEN}✓ Security validation PASSED${NC}"
        exit 0
    else
        echo -e "${RED}✗ Security validation FAILED${NC}"
        echo "  Review and fix failed checks before proceeding"
        exit 1
    fi
}

# Main execution
main() {
    init_validation

    validate_environment
    validate_pat_authentication
    validate_secrets
    validate_no_leaks
    validate_file_permissions
    validate_token_rotation
    validate_network_security

    generate_report
    display_summary
}

# Execute main function
main "$@"