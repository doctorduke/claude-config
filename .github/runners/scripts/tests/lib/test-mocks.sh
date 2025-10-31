#!/usr/bin/env bash
# Script: test-mocks.sh
# Description: Mock infrastructure for external dependencies
# Usage: source "${SCRIPT_DIR}/tests/lib/test-mocks.sh"

# Mock state directory
MOCK_STATE_DIR="${TEST_TEMP_DIR}/mock-state"
mkdir -p "${MOCK_STATE_DIR}"

# ============================================================
# Mock: gh CLI
# ============================================================

mock_gh() {
    local command="$1"
    shift

    case "${command}" in
        "auth")
            if [[ "$1" == "status" ]]; then
                if [[ -f "${MOCK_STATE_DIR}/gh-auth-fail" ]]; then
                    return 1
                fi
                echo "Logged in to github.com as testuser"
                return 0
            elif [[ "$1" == "token" ]]; then
                echo "ghp_mock_token_1234567890"
                return 0
            fi
            ;;
        "pr")
            case "$1" in
                "diff")
                    local pr_num="$2"
                    if [[ -f "${MOCK_STATE_DIR}/pr-${pr_num}-diff.txt" ]]; then
                        cat "${MOCK_STATE_DIR}/pr-${pr_num}-diff.txt"
                    else
                        echo "diff --git a/file.txt b/file.txt"
                        echo "--- a/file.txt"
                        echo "+++ b/file.txt"
                        echo "@@ -1,1 +1,1 @@"
                        echo "-old line"
                        echo "+new line"
                    fi
                    return 0
                    ;;
                "view")
                    local pr_num="$2"
                    if [[ "$3" == "--json" ]]; then
                        local fields="$4"
                        if [[ -f "${MOCK_STATE_DIR}/pr-${pr_num}.json" ]]; then
                            cat "${MOCK_STATE_DIR}/pr-${pr_num}.json"
                        else
                            echo '{"number":123,"title":"Test PR","body":"Test description","author":{"login":"testuser"},"additions":10,"deletions":5,"changedFiles":2,"state":"OPEN","isDraft":false,"files":[{"path":"file1.txt"},{"path":"file2.txt"}]}'
                        fi
                        return 0
                    fi
                    ;;
                "comment")
                    local pr_num="$2"
                    shift 2
                    echo "$@" > "${MOCK_STATE_DIR}/pr-${pr_num}-comment.txt"
                    return 0
                    ;;
                "review")
                    local pr_num="$2"
                    shift 2
                    echo "$@" > "${MOCK_STATE_DIR}/pr-${pr_num}-review.txt"
                    return 0
                    ;;
            esac
            ;;
        "repo")
            if [[ "$1" == "view" ]]; then
                echo '{"nameWithOwner":"testuser/testrepo"}'
                return 0
            fi
            ;;
        "api")
            local endpoint="$2"
            if [[ -f "${MOCK_STATE_DIR}/api-response.json" ]]; then
                cat "${MOCK_STATE_DIR}/api-response.json"
            else
                echo '{"status":"success"}'
            fi
            return 0
            ;;
    esac

    # Default: command not mocked
    echo "Mock gh: command not implemented: ${command} $*" >&2
    return 1
}

# Set up gh mock
setup_gh_mock() {
    export -f mock_gh

    # Create wrapper script
    cat > "${MOCK_STATE_DIR}/gh" <<'EOF'
#!/usr/bin/env bash
mock_gh "$@"
EOF
    chmod +x "${MOCK_STATE_DIR}/gh"

    # Add to PATH
    export PATH="${MOCK_STATE_DIR}:${PATH}"
}

# Set gh auth to fail
mock_gh_auth_fail() {
    touch "${MOCK_STATE_DIR}/gh-auth-fail"
}

# Set gh auth to succeed
mock_gh_auth_success() {
    rm -f "${MOCK_STATE_DIR}/gh-auth-fail"
}

# Set PR diff response
mock_pr_diff() {
    local pr_num="$1"
    local diff_content="$2"
    echo "${diff_content}" > "${MOCK_STATE_DIR}/pr-${pr_num}-diff.txt"
}

# Set PR metadata response
mock_pr_metadata() {
    local pr_num="$1"
    local json_content="$2"
    echo "${json_content}" > "${MOCK_STATE_DIR}/pr-${pr_num}.json"
}

# Set API response
mock_api_response() {
    local json_content="$1"
    echo "${json_content}" > "${MOCK_STATE_DIR}/api-response.json"
}

# ============================================================
# Mock: curl
# ============================================================

mock_curl() {
    local url=""
    local http_code="200"
    local output_file=""
    local data=""
    local method="GET"

    # Parse curl arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -X)
                method="$2"
                shift 2
                ;;
            -o)
                output_file="$2"
                shift 2
                ;;
            -w)
                # Write format (e.g., %{http_code})
                shift 2
                ;;
            -d)
                data="$2"
                shift 2
                ;;
            -H)
                # Headers (ignored in mock)
                shift 2
                ;;
            -s|-S)
                shift
                ;;
            *)
                if [[ "$1" != -* ]]; then
                    url="$1"
                fi
                shift
                ;;
        esac
    done

    # Check for mock response
    if [[ -f "${MOCK_STATE_DIR}/curl-response.json" ]]; then
        if [[ -n "${output_file}" ]]; then
            cat "${MOCK_STATE_DIR}/curl-response.json" > "${output_file}"
        else
            cat "${MOCK_STATE_DIR}/curl-response.json"
        fi
    else
        # Default response
        local response='{"status":"success"}'
        if [[ -n "${output_file}" ]]; then
            echo "${response}" > "${output_file}"
        else
            echo "${response}"
        fi
    fi

    # Check for mock HTTP code
    if [[ -f "${MOCK_STATE_DIR}/curl-http-code.txt" ]]; then
        cat "${MOCK_STATE_DIR}/curl-http-code.txt"
    else
        echo "${http_code}"
    fi

    # Check for mock failure
    if [[ -f "${MOCK_STATE_DIR}/curl-fail" ]]; then
        return 1
    fi

    return 0
}

# Set up curl mock
setup_curl_mock() {
    export -f mock_curl

    # Create wrapper script
    cat > "${MOCK_STATE_DIR}/curl" <<'EOF'
#!/usr/bin/env bash
mock_curl "$@"
EOF
    chmod +x "${MOCK_STATE_DIR}/curl"

    # Add to PATH
    export PATH="${MOCK_STATE_DIR}:${PATH}"
}

# Set curl response
mock_curl_response() {
    local json_content="$1"
    echo "${json_content}" > "${MOCK_STATE_DIR}/curl-response.json"
}

# Set curl HTTP code
mock_curl_http_code() {
    local code="$1"
    echo "${code}" > "${MOCK_STATE_DIR}/curl-http-code.txt"
}

# Set curl to fail
mock_curl_fail() {
    touch "${MOCK_STATE_DIR}/curl-fail"
}

# Set curl to succeed
mock_curl_success() {
    rm -f "${MOCK_STATE_DIR}/curl-fail"
}

# ============================================================
# Mock: jq
# ============================================================

# jq is real - we need it for testing, but we can mock its input

# ============================================================
# Mock: git
# ============================================================

mock_git() {
    local command="$1"
    shift

    case "${command}" in
        "status")
            echo "On branch main"
            echo "nothing to commit, working tree clean"
            return 0
            ;;
        "diff")
            if [[ -f "${MOCK_STATE_DIR}/git-diff.txt" ]]; then
                cat "${MOCK_STATE_DIR}/git-diff.txt"
            else
                echo "diff --git a/file.txt b/file.txt"
            fi
            return 0
            ;;
        "log")
            echo "commit abc123"
            echo "Author: Test User <test@example.com>"
            echo "Date: Mon Oct 23 12:00:00 2025"
            echo ""
            echo "    Test commit message"
            return 0
            ;;
        *)
            # Pass through to real git
            command git "${command}" "$@"
            ;;
    esac
}

# Set up git mock
setup_git_mock() {
    export -f mock_git

    # Create wrapper script
    cat > "${MOCK_STATE_DIR}/git" <<'EOF'
#!/usr/bin/env bash
mock_git "$@"
EOF
    chmod +x "${MOCK_STATE_DIR}/git"

    # Add to PATH (but keep real git accessible)
    export PATH="${MOCK_STATE_DIR}:${PATH}"
}

# ============================================================
# Mock: date
# ============================================================

mock_date() {
    if [[ "$1" == "+%s" ]]; then
        if [[ -f "${MOCK_STATE_DIR}/mock-timestamp.txt" ]]; then
            cat "${MOCK_STATE_DIR}/mock-timestamp.txt"
        else
            echo "1698062400"  # Fixed timestamp for testing
        fi
    else
        # Pass through to real date
        command date "$@"
    fi
    return 0
}

# Set up date mock
setup_date_mock() {
    export -f mock_date

    # Create wrapper script
    cat > "${MOCK_STATE_DIR}/date" <<'EOF'
#!/usr/bin/env bash
mock_date "$@"
EOF
    chmod +x "${MOCK_STATE_DIR}/date"

    # Add to PATH
    export PATH="${MOCK_STATE_DIR}:${PATH}"
}

# Set mock timestamp
mock_timestamp() {
    local timestamp="$1"
    echo "${timestamp}" > "${MOCK_STATE_DIR}/mock-timestamp.txt"
}

# ============================================================
# Mock: sleep
# ============================================================

mock_sleep() {
    # Record sleep calls but don't actually sleep
    echo "$1" >> "${MOCK_STATE_DIR}/sleep-calls.txt"
    return 0
}

# Set up sleep mock
setup_sleep_mock() {
    export -f mock_sleep

    # Create wrapper script
    cat > "${MOCK_STATE_DIR}/sleep" <<'EOF'
#!/usr/bin/env bash
mock_sleep "$@"
EOF
    chmod +x "${MOCK_STATE_DIR}/sleep"

    # Add to PATH
    export PATH="${MOCK_STATE_DIR}:${PATH}"
}

# Get sleep calls count
get_sleep_calls_count() {
    if [[ -f "${MOCK_STATE_DIR}/sleep-calls.txt" ]]; then
        wc -l < "${MOCK_STATE_DIR}/sleep-calls.txt"
    else
        echo "0"
    fi
}

# ============================================================
# Mock setup helpers
# ============================================================

# Set up all common mocks
setup_all_mocks() {
    setup_gh_mock
    setup_curl_mock
    setup_git_mock
    setup_date_mock
    setup_sleep_mock
}

# Clean up all mocks
cleanup_all_mocks() {
    rm -rf "${MOCK_STATE_DIR}"
}

# Export functions
export -f mock_gh mock_curl mock_git mock_date mock_sleep
export -f setup_gh_mock setup_curl_mock setup_git_mock setup_date_mock setup_sleep_mock
export -f setup_all_mocks cleanup_all_mocks
export -f mock_gh_auth_fail mock_gh_auth_success
export -f mock_pr_diff mock_pr_metadata mock_api_response
export -f mock_curl_response mock_curl_http_code mock_curl_fail mock_curl_success
export -f mock_timestamp get_sleep_calls_count
