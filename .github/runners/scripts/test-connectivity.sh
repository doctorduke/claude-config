#!/usr/bin/env bash
# Source network utilities
SCRIPT_DIR_TEST="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR_TEST}/lib/network.sh"

################################################################################
# GitHub Actions Runner Network Connectivity Test
#
# Purpose: Comprehensive network validation for self-hosted runners
# Platform: Windows+WSL, Linux, macOS
# Requirements: curl, dig/nslookup, jq (optional for JSON output)
################################################################################

set -euo pipefail

# Color output (disable in non-interactive environments)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Configuration
SCRIPT_VERSION="1.0.0"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
LOG_FILE="${LOG_FILE:-connectivity-test.log}"
OUTPUT_FORMAT="${OUTPUT_FORMAT:-text}" # text, json, or markdown
CONTINUOUS_MODE="${CONTINUOUS_MODE:-false}"
INTERVAL="${INTERVAL:-60}" # seconds between checks in continuous mode
TIMEOUT="${TIMEOUT:-10}" # connection timeout in seconds

# Counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARNING=0

# GitHub Endpoints
declare -A GITHUB_ENDPOINTS=(
    ["GitHub API"]="https://api.github.com"
    ["GitHub Main Site"]="https://github.com"
    ["Actions Pipelines"]="https://pipelines.actions.githubusercontent.com"
    ["Actions Results"]="https://results.actions.githubusercontent.com"
    ["Runner Releases"]="https://github.com/actions/runner/releases"
    ["GitHub Objects"]="https://objects.githubusercontent.com"
    ["GitHub Avatars"]="https://avatars.githubusercontent.com"
    ["GitHub Raw Content"]="https://raw.githubusercontent.com"
)

# Package Registry Endpoints
declare -A REGISTRY_ENDPOINTS=(
    ["npm Registry"]="https://registry.npmjs.org"
    ["PyPI"]="https://pypi.org/pypi/pip/json"
    ["Docker Hub"]="https://hub.docker.com"
    ["GitHub Packages"]="https://npm.pkg.github.com"
)

# DNS Servers to test
DNS_SERVERS=("8.8.8.8" "1.1.1.1")

################################################################################
# Utility Functions
################################################################################

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

print_header() {
    if [ "$OUTPUT_FORMAT" = "text" ]; then
        echo ""
        echo -e "${BLUE}================================================================${NC}"
        echo -e "${BLUE}  $1${NC}"
        echo -e "${BLUE}================================================================${NC}"
    fi
}

print_section() {
    if [ "$OUTPUT_FORMAT" = "text" ]; then
        echo ""
        echo -e "${YELLOW}>>> $1${NC}"
        echo ""
    fi
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((TESTS_WARNING++))
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

################################################################################
# Detection Functions
################################################################################

detect_platform() {
    if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "WSL"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "Linux"
    else
        echo "Unknown"
    fi
}

detect_proxy() {
    local proxy_vars=()

    [ -n "${HTTP_PROXY:-}" ] && proxy_vars+=("HTTP_PROXY=$HTTP_PROXY")
    [ -n "${HTTPS_PROXY:-}" ] && proxy_vars+=("HTTPS_PROXY=$HTTPS_PROXY")
    [ -n "${http_proxy:-}" ] && proxy_vars+=("http_proxy=$http_proxy")
    [ -n "${https_proxy:-}" ] && proxy_vars+=("https_proxy=$https_proxy")
    [ -n "${NO_PROXY:-}" ] && proxy_vars+=("NO_PROXY=$NO_PROXY")
    [ -n "${no_proxy:-}" ] && proxy_vars+=("no_proxy=$no_proxy")

    if [ ${#proxy_vars[@]} -gt 0 ]; then
        echo "true"
        return 0
    else
        echo "false"
        return 1
    fi
}

get_proxy_info() {
    local proxy="${HTTPS_PROXY:-${https_proxy:-${HTTP_PROXY:-${http_proxy:-}}}}"
    echo "${proxy:-None configured}"
}

################################################################################
# Network Test Functions
################################################################################

test_dns_resolution() {
    local domain=$1
    local dns_server=${2:-}

    # Try dig first, fall back to nslookup, then host
    if command -v dig &> /dev/null; then
        if [ -n "$dns_server" ]; then
            dig +short +time=3 @"$dns_server" "$domain" A &>/dev/null
        else
            dig +short +time=3 "$domain" A &>/dev/null
        fi
    elif command -v nslookup &> /dev/null; then
        if [ -n "$dns_server" ]; then
            nslookup "$domain" "$dns_server" &>/dev/null
        else
            nslookup "$domain" &>/dev/null
        fi
    elif command -v host &> /dev/null; then
        host "$domain" &>/dev/null
    else
        # Fall back to trying to resolve via ping
        ping -c 1 -W 2 "$domain" &>/dev/null
    fi
}

test_https_connectivity() {
    local url=$1
    local name=$2

    # Test with curl
    if curl -sSf --connect-timeout "$TIMEOUT" --max-time $((TIMEOUT * 2)) \
         -o /dev/null -w "%{http_code}" "$url" 2>/dev/null | grep -qE "^(200|301|302|403)$"; then
        return 0
    else
        return 1
    fi
}

test_tls_certificate() {
    local domain=$1

    # Test TLS certificate validity
    if command -v openssl &> /dev/null; then
        if echo | openssl s_client -connect "$domain:443" -servername "$domain" \
           -showcerts </dev/null 2>/dev/null | grep -q "Verify return code: 0"; then
            return 0
        fi
    fi

    # Fallback to curl certificate check
    curl -sSf --connect-timeout "$TIMEOUT" "https://$domain" -o /dev/null 2>&1
    return $?
}

measure_latency() {
    local url=$1

    # Measure time to first byte
    if command -v curl &> /dev/null; then
        local time_total
        time_total=$(curl -o /dev/null -s -w '%{time_total}' --connect-timeout "$TIMEOUT" "$url" 2>/dev/null || echo "999")
        # Convert to milliseconds
        echo "$time_total" | awk '{printf "%.0f", $1 * 1000}'
    else
        echo "N/A"
    fi
}

test_github_api() {
    local endpoint="https://api.github.com"

    # Test GitHub API with rate limit check
    local response
    response=$(curl -sSf --connect-timeout "$TIMEOUT" "$endpoint" 2>/dev/null || echo "")

    if [ -n "$response" ]; then
        # Check if we can get rate limit info
        local rate_limit
        rate_limit=$(curl -sSf --connect-timeout "$TIMEOUT" "${endpoint}/rate_limit" 2>/dev/null || echo "")

        if [ -n "$rate_limit" ]; then
            if command -v jq &> /dev/null; then
                local remaining
                remaining=$(echo "$rate_limit" | jq -r '.rate.remaining // "N/A"')
                echo "Remaining API calls: $remaining"
            fi
            return 0
        fi
        return 0
    else
        return 1
    fi
}

################################################################################
# Test Suites
################################################################################

run_system_checks() {
    print_section "System Information"

    local platform
    platform=$(detect_platform)
    print_info "Platform: $platform"

    print_info "OS: $(uname -s) $(uname -r)"
    print_info "Architecture: $(uname -m)"
    print_info "Hostname: $(hostname)"

    # Check for required tools
    local required_tools=("curl")
    local optional_tools=("dig" "nslookup" "openssl" "jq" "nc" "telnet")

    print_info "Checking required tools..."
    for tool in "${required_tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            print_pass "Found: $tool"
        else
            print_fail "Missing required tool: $tool"
        fi
    done

    print_info "Checking optional tools..."
    for tool in "${optional_tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            print_info "Found: $tool ($(command -v "$tool"))"
        fi
    done
}

run_proxy_checks() {
    print_section "Proxy Configuration"

    local has_proxy
    has_proxy=$(detect_proxy)

    if [ "$has_proxy" = "true" ]; then
        print_info "Proxy detected: $(get_proxy_info)"

        # List all proxy-related environment variables
        [ -n "${HTTP_PROXY:-}" ] && print_info "HTTP_PROXY: $HTTP_PROXY"
        [ -n "${HTTPS_PROXY:-}" ] && print_info "HTTPS_PROXY: $HTTPS_PROXY"
        [ -n "${http_proxy:-}" ] && print_info "http_proxy: $http_proxy"
        [ -n "${https_proxy:-}" ] && print_info "https_proxy: $https_proxy"
        [ -n "${NO_PROXY:-}" ] && print_info "NO_PROXY: $NO_PROXY"
        [ -n "${no_proxy:-}" ] && print_info "no_proxy: $no_proxy"

        print_pass "Proxy configuration found"
    else
        print_info "No proxy detected (direct connection)"
    fi

    # Test if GitHub is accessible through proxy (if configured)
    if [ "$has_proxy" = "true" ]; then
        if curl -sSf --connect-timeout "$TIMEOUT" -o /dev/null "https://github.com" 2>/dev/null; then
            print_pass "GitHub accessible through proxy"
        else
            print_fail "Cannot reach GitHub through proxy"
        fi
    fi
}

run_dns_checks() {
    print_section "DNS Resolution Tests"

    # Test critical GitHub domains
    local domains=("github.com" "api.github.com" "pipelines.actions.githubusercontent.com" "objects.githubusercontent.com")

    for domain in "${domains[@]}"; do
        if test_dns_resolution "$domain"; then
            print_pass "DNS resolution: $domain"

            # Show resolved IPs if dig is available
            if command -v dig &> /dev/null; then
                local ips
                ips=$(dig +short "$domain" A 2>/dev/null | head -3)
                if [ -n "$ips" ]; then
                    echo "         Resolved to: $(echo "$ips" | tr '\n' ', ' | sed 's/,$//')"
                fi
            fi
        else
            print_fail "DNS resolution failed: $domain"
        fi
    done

    # Test with specific DNS servers
    print_info "Testing with public DNS servers..."
    for dns_server in "${DNS_SERVERS[@]}"; do
        if test_dns_resolution "github.com" "$dns_server"; then
            print_pass "DNS via $dns_server"
        else
            print_warn "DNS via $dns_server failed"
        fi
    done
}

run_connectivity_tests() {
    print_section "GitHub Endpoint Connectivity"

    for name in "${!GITHUB_ENDPOINTS[@]}"; do
        local url="${GITHUB_ENDPOINTS[$name]}"

        if test_https_connectivity "$url" "$name"; then
            local latency
            latency=$(measure_latency "$url")
            print_pass "$name ($url) - ${latency}ms"
        else
            print_fail "$name ($url)"
        fi
    done
}

run_tls_checks() {
    print_section "TLS/SSL Certificate Validation"

    local domains=("github.com" "api.github.com" "pipelines.actions.githubusercontent.com")

    for domain in "${domains[@]}"; do
        if test_tls_certificate "$domain"; then
            print_pass "TLS certificate valid: $domain"
        else
            print_fail "TLS certificate validation failed: $domain"
        fi
    done
}

run_registry_tests() {
    print_section "Package Registry Connectivity"

    for name in "${!REGISTRY_ENDPOINTS[@]}"; do
        local url="${REGISTRY_ENDPOINTS[$name]}"

        if test_https_connectivity "$url" "$name"; then
            print_pass "$name ($url)"
        else
            print_warn "$name ($url) - Not critical for runner operation"
        fi
    done
}

run_github_api_tests() {
    print_section "GitHub API Validation"

    local api_info
    api_info=$(test_github_api 2>&1)

    if [ $? -eq 0 ]; then
        print_pass "GitHub API accessible"
        [ -n "$api_info" ] && print_info "$api_info"

        # Test specific API endpoints
        if curl -sSf --connect-timeout "$TIMEOUT" "https://api.github.com/meta" -o /dev/null 2>/dev/null; then
            print_pass "GitHub Meta API accessible"
        fi

        # Test runner API endpoint (requires auth but should return 401, not connection error)
        local runner_response
        runner_response=$(curl -s -w "%{http_code}" --connect-timeout "$TIMEOUT" \
                         "https://api.github.com/orgs/test/actions/runners" -o /dev/null 2>/dev/null || echo "000")

        if [[ "$runner_response" =~ ^(401|404)$ ]]; then
            print_pass "Runner API endpoint accessible (auth required)"
        elif [ "$runner_response" = "000" ]; then
            print_fail "Cannot reach Runner API endpoint"
        fi
    else
        print_fail "GitHub API not accessible"
    fi
}

run_latency_benchmarks() {
    print_section "Network Latency Benchmarks"

    local api_latency
    api_latency=$(measure_latency "https://api.github.com")
    print_info "GitHub API latency: ${api_latency}ms"

    if [ "$api_latency" != "N/A" ] && [ "$api_latency" -lt 100 ]; then
        print_pass "Latency excellent (<100ms)"
    elif [ "$api_latency" != "N/A" ] && [ "$api_latency" -lt 300 ]; then
        print_pass "Latency acceptable (100-300ms)"
    elif [ "$api_latency" != "N/A" ]; then
        print_warn "Latency high (>300ms) - May impact runner performance"
    fi
}

run_wsl_specific_checks() {
    print_section "WSL-Specific Network Checks"

    local platform
    platform=$(detect_platform)

    if [ "$platform" != "WSL" ]; then
        print_info "Not running on WSL - skipping WSL-specific checks"
        return
    fi

    print_info "Detected WSL environment"

    # Check WSL version
    if command -v wsl.exe &> /dev/null; then
        print_info "WSL version: $(wsl.exe --version 2>/dev/null | head -1 || echo 'WSL 1 or version command not available')"
    fi

    # Check if we can reach Windows host
    local windows_host
    windows_host=$(grep -m1 nameserver /etc/resolv.conf | awk '{print $2}')
    if [ -n "$windows_host" ]; then
        print_info "Windows host IP: $windows_host"

        if ping -c 1 -W 2 "$windows_host" &>/dev/null; then
            print_pass "Can reach Windows host"
        else
            print_warn "Cannot reach Windows host"
        fi
    fi

    # Check for VPN interference
    print_info "Checking for VPN adapters..."
    if ip link show 2>/dev/null | grep -qiE "(vpn|tun|tap)"; then
        print_warn "VPN adapter detected - may affect connectivity"
    else
        print_info "No VPN adapters detected"
    fi

    # Check Windows firewall status (if accessible)
    if command -v netsh.exe &> /dev/null; then
        print_info "Windows firewall accessible for configuration"
    fi
}

################################################################################
# Output Formatters
################################################################################

generate_json_output() {
    cat <<EOF
{
  "timestamp": "$TIMESTAMP",
  "version": "$SCRIPT_VERSION",
  "platform": "$(detect_platform)",
  "proxy_enabled": $(detect_proxy),
  "summary": {
    "passed": $TESTS_PASSED,
    "failed": $TESTS_FAILED,
    "warnings": $TESTS_WARNING,
    "total": $((TESTS_PASSED + TESTS_FAILED + TESTS_WARNING))
  },
  "status": "$([ $TESTS_FAILED -eq 0 ] && echo "PASS" || echo "FAIL")"
}
EOF
}

generate_summary() {
    print_header "Test Summary"

    echo ""
    echo "Tests Passed:   ${GREEN}$TESTS_PASSED${NC}"
    echo "Tests Failed:   ${RED}$TESTS_FAILED${NC}"
    echo "Warnings:       ${YELLOW}$TESTS_WARNING${NC}"
    echo "Total Tests:    $((TESTS_PASSED + TESTS_FAILED + TESTS_WARNING))"
    echo ""

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}Overall Status: PASS - Runner connectivity requirements met${NC}"
        echo ""
        echo "Next steps:"
        echo "  1. Proceed with runner installation"
        echo "  2. Configure runner with organization token"
        echo "  3. Run validation script after installation"
        return 0
    else
        echo -e "${RED}Overall Status: FAIL - Connectivity issues detected${NC}"
        echo ""
        echo "Required actions:"
        echo "  1. Review failed tests above"
        echo "  2. Check firewall/proxy configuration"
        echo "  3. Verify DNS resolution"
        echo "  4. Consult docs/network-troubleshooting.md"
        return 1
    fi
}

################################################################################
# Main Execution
################################################################################

show_usage() {
    cat <<EOF
GitHub Actions Runner Network Connectivity Test v$SCRIPT_VERSION

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -f, --format FORMAT     Output format: text (default), json, markdown
    -c, --continuous        Run in continuous monitoring mode
    -i, --interval SECONDS  Interval between checks in continuous mode (default: 60)
    -t, --timeout SECONDS   Connection timeout (default: 10)
    -l, --log FILE          Log file path (default: connectivity-test.log)
    -q, --quiet             Suppress output (log only)
    -v, --verbose           Verbose output

EXAMPLES:
    # Run basic connectivity test
    $0

    # Run with JSON output
    $0 --format json

    # Run in continuous monitoring mode
    $0 --continuous --interval 300

    # Run with custom timeout and log
    $0 --timeout 30 --log /var/log/runner-connectivity.log

EOF
}

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -f|--format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            -c|--continuous)
                CONTINUOUS_MODE="true"
                shift
                ;;
            -i|--interval)
                INTERVAL="$2"
                shift 2
                ;;
            -t|--timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            -l|--log)
                LOG_FILE="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # Initialize log
    log "Starting GitHub Actions Runner connectivity test"
    log "Platform: $(detect_platform)"
    log "Proxy: $(get_proxy_info)"

    # Run test suites
    if [ "$OUTPUT_FORMAT" = "text" ]; then
        print_header "GitHub Actions Runner Network Connectivity Test v$SCRIPT_VERSION"
    fi

    run_system_checks
    run_proxy_checks
    run_dns_checks
    run_connectivity_tests
    run_tls_checks
    run_github_api_tests
    run_latency_benchmarks
    run_registry_tests
    run_wsl_specific_checks

    # Generate output based on format
    case "$OUTPUT_FORMAT" in
        json)
            generate_json_output
            ;;
        text|*)
            generate_summary
            ;;
    esac

    local exit_code=$?

    # Continuous mode
    if [ "$CONTINUOUS_MODE" = "true" ]; then
        print_info "Entering continuous monitoring mode (interval: ${INTERVAL}s)"
        print_info "Press Ctrl+C to exit"

        while true; do
            sleep "$INTERVAL"
            echo ""
            log "Running scheduled connectivity check"

            # Reset counters
            TESTS_PASSED=0
            TESTS_FAILED=0
            TESTS_WARNING=0

            # Re-run critical tests
            run_dns_checks
            run_connectivity_tests
            run_github_api_tests
            generate_summary
        done
    fi

    exit $exit_code
}

# Execute main function
main "$@"
