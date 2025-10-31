#!/bin/bash
# Mocking Library
# Provides functions to mock external dependencies

# Storage for mocked commands
MOCK_DIR=""
MOCK_RESPONSES=()
MOCK_CALL_COUNT=()

# Initialize mocking system
init_mocks() {
    MOCK_DIR=$(mktemp -d)
    export PATH="$MOCK_DIR:$PATH"
    register_cleanup cleanup_mocks
}

# Cleanup mocks
cleanup_mocks() {
    if [[ -n "$MOCK_DIR" && -d "$MOCK_DIR" ]]; then
        rm -rf "$MOCK_DIR"
    fi
}

# Mock a command with a specific response
mock_command() {
    local command_name="$1"
    local response="$2"
    local exit_code="${3:-0}"

    [[ -z "$MOCK_DIR" ]] && init_mocks

    local mock_script="$MOCK_DIR/$command_name"

    cat > "$mock_script" << EOF
#!/bin/bash
# Mock for $command_name

# Log the call
echo "\$@" >> "$MOCK_DIR/${command_name}.calls"

# Return the mocked response
echo "$response"
exit $exit_code
EOF

    chmod +x "$mock_script"

    log_test "DEBUG" "Mocked command: $command_name"
}

# Mock a command with a script
mock_command_with_script() {
    local command_name="$1"
    local script="$2"

    [[ -z "$MOCK_DIR" ]] && init_mocks

    local mock_script="$MOCK_DIR/$command_name"

    cat > "$mock_script" << EOF
#!/bin/bash
# Mock for $command_name

# Log the call
echo "\$@" >> "$MOCK_DIR/${command_name}.calls"

# Run the custom script
$script
EOF

    chmod +x "$mock_script"

    log_test "DEBUG" "Mocked command with script: $command_name"
}

# Get number of times a mocked command was called
get_mock_call_count() {
    local command_name="$1"
    local call_log="$MOCK_DIR/${command_name}.calls"

    if [[ -f "$call_log" ]]; then
        wc -l < "$call_log"
    else
        echo "0"
    fi
}

# Get arguments from a specific call to a mocked command
get_mock_call_args() {
    local command_name="$1"
    local call_number="${2:-1}"
    local call_log="$MOCK_DIR/${command_name}.calls"

    if [[ -f "$call_log" ]]; then
        sed -n "${call_number}p" "$call_log"
    else
        echo ""
    fi
}

# Verify a command was called with specific arguments
assert_mock_called_with() {
    local command_name="$1"
    local expected_args="$2"
    local call_log="$MOCK_DIR/${command_name}.calls"

    if [[ ! -f "$call_log" ]]; then
        log_test "ERROR" "Mock $command_name was never called"
        return 1
    fi

    if grep -Fq "$expected_args" "$call_log"; then
        log_test "DEBUG" "Mock $command_name was called with: $expected_args"
        return 0
    else
        log_test "ERROR" "Mock $command_name was not called with: $expected_args"
        log_test "ERROR" "Actual calls:"
        cat "$call_log" | sed 's/^/  /' >&2
        return 1
    fi
}

# Mock GitHub CLI (gh)
# Store endpoint responses in a temporary file
mock_gh_api() {
    local endpoint="$1"
    local response="$2"
    local exit_code="${3:-0}"

    [[ -z "$MOCK_DIR" ]] && init_mocks

    local mock_script="$MOCK_DIR/gh"
    local endpoints_file="$MOCK_DIR/gh.endpoints"

    # Store endpoint data
    echo "$endpoint|$exit_code|$response" >> "$endpoints_file"

    # Rebuild the entire gh mock script from stored endpoints
    cat > "$mock_script" << EOFGH
#!/bin/bash
# Mock for gh (GitHub CLI)

# Log the call
echo "\$@" >> "$MOCK_DIR/gh.calls"

# Parse command
case "\$1" in
    api)
        endpoint="\$2"
        # Read endpoint responses from file
        while IFS='|' read -r ep_pattern ep_exit ep_response; do
            if [[ "\$endpoint" == "\$ep_pattern" ]]; then
                echo "\$ep_response"
                exit "\$ep_exit"
            fi
        done < "$MOCK_DIR/gh.endpoints"
        # No match found
        echo "Mock gh: Unknown endpoint: \$endpoint" >&2
        exit 1
        ;;
    pr)
        case "\$2" in
            view)
                echo '{"number": 123, "title": "Test PR", "state": "open"}'
                ;;
            list)
                echo '[{"number": 123, "title": "Test PR"}]'
                ;;
            *)
                echo "Mock gh pr: Unknown subcommand: $2" >&2
                exit 1
                ;;
        esac
        ;;
    issue)
        case "$2" in
            view)
                echo '{"number": 456, "title": "Test Issue", "state": "open"}'
                ;;
            list)
                echo '[{"number": 456, "title": "Test Issue"}]'
                ;;
            *)
                echo "Mock gh issue: Unknown subcommand: $2" >&2
                exit 1
                ;;
        esac
        ;;
    *)
        echo "Mock gh: Unknown command: $1" >&2
        exit 1
        ;;
esac
EOFGH

    chmod +x "$mock_script"

    log_test "DEBUG" "Mocked gh api: $endpoint"
}

# Mock AI API calls (curl to AI providers)
# Store provider responses in a temporary file to support multiple providers
mock_ai_api() {
    local provider="$1"  # anthropic, openai, etc.
    local response="$2"
    local exit_code="${3:-0}"

    [[ -z "$MOCK_DIR" ]] && init_mocks

    local mock_script="$MOCK_DIR/curl"
    local providers_file="$MOCK_DIR/curl.providers"

    # Store provider data
    echo "$provider|$exit_code|$response" >> "$providers_file"

    # Rebuild the entire curl mock script from stored providers
    cat > "$mock_script" << 'EOFCURL'
#!/bin/bash
# Mock for curl (AI API calls)

# Log the call
echo "$@" >> "$MOCK_DIR/curl.calls"

# Check provider-specific API calls
matched=false
while IFS='|' read -r prov_name prov_exit prov_response; do
    case "$prov_name" in
        anthropic)
            if [[ "$*" == *"api.anthropic.com"* ]]; then
                echo "$prov_response"
                exit "$prov_exit"
            fi
            ;;
        openai)
            if [[ "$*" == *"api.openai.com"* ]]; then
                echo "$prov_response"
                exit "$prov_exit"
            fi
            ;;
    esac
done < "$MOCK_DIR/curl.providers"

# Fall back to real curl for other requests
command curl "$@"
EOFCURL

    chmod +x "$mock_script"

    log_test "DEBUG" "Mocked AI API: $provider"
}

# Mock git commands
mock_git_command() {
    local subcommand="$1"
    local response="$2"
    local exit_code="${3:-0}"

    [[ -z "$MOCK_DIR" ]] && init_mocks

    local mock_script="$MOCK_DIR/git"

    # Create or append to existing git mock
    if [[ ! -f "$mock_script" ]]; then
        cat > "$mock_script" << 'EOFGIT'
#!/bin/bash
# Mock for git

# Log the call
echo "$@" >> "$MOCK_DIR/git.calls"

# Parse command
case "$1" in
EOFGIT
    fi

    # Add subcommand handler
    cat >> "$mock_script" << EOFGITSUB
    "$subcommand")
        echo '$response'
        exit $exit_code
        ;;
EOFGITSUB

    # Close the script
    cat >> "$mock_script" << 'EOFGIT'
    *)
        echo "Mock git: Unknown subcommand: $1" >&2
        exit 1
        ;;
esac
EOFGIT

    chmod +x "$mock_script"

    log_test "DEBUG" "Mocked git command: $subcommand"
}

# Mock environment variable
mock_env() {
    local var_name="$1"
    local var_value="$2"

    export "$var_name=$var_value"

    log_test "DEBUG" "Mocked environment variable: $var_name=$var_value"
}

# Restore environment variable
restore_env() {
    local var_name="$1"
    unset "$var_name"
}

# Create a mock HTTP server response
mock_http_response() {
    local status_code="$1"
    local body="$2"
    local headers="${3:-Content-Type: application/json}"

    cat << EOF
HTTP/1.1 $status_code
$headers

$body
EOF
}

# Mock successful API response
mock_api_success() {
    local data="$1"
    echo "{\"success\": true, \"data\": $data}"
}

# Mock API error response
mock_api_error() {
    local message="$1"
    local code="${2:-500}"
    echo "{\"error\": {\"message\": \"$message\", \"code\": $code}}"
}

# Export mocking functions
export -f init_mocks
export -f cleanup_mocks
export -f mock_command
export -f mock_command_with_script
export -f get_mock_call_count
export -f get_mock_call_args
export -f assert_mock_called_with
export -f mock_gh_api
export -f mock_ai_api
export -f mock_git_command
export -f mock_env
export -f restore_env
export -f mock_http_response
export -f mock_api_success
export -f mock_api_error
