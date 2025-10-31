#!/bin/bash
# Assertion Library
# Provides test assertion functions

# Assert two values are equal
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Expected '$expected' but got '$actual'}"

    if [[ "$expected" == "$actual" ]]; then
        log_test "DEBUG" "assert_equals: PASS"
        return 0
    else
        log_test "ERROR" "$message"
        log_test "ERROR" "  Expected: $expected"
        log_test "ERROR" "  Actual:   $actual"
        return 1
    fi
}

# Assert two values are not equal
assert_not_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Expected values to be different but both were '$actual'}"

    if [[ "$expected" != "$actual" ]]; then
        log_test "DEBUG" "assert_not_equals: PASS"
        return 0
    else
        log_test "ERROR" "$message"
        return 1
    fi
}

# Assert string contains substring
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-Expected to find '$needle' in '$haystack'}"

    if [[ "$haystack" == *"$needle"* ]]; then
        log_test "DEBUG" "assert_contains: PASS"
        return 0
    else
        log_test "ERROR" "$message"
        return 1
    fi
}

# Assert string does not contain substring
assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-Expected NOT to find '$needle' in '$haystack'}"

    if [[ "$haystack" != *"$needle"* ]]; then
        log_test "DEBUG" "assert_not_contains: PASS"
        return 0
    else
        log_test "ERROR" "$message"
        return 1
    fi
}

# Assert value is true (0 exit code or "true" string)
assert_true() {
    local value="$1"
    local message="${2:-Expected true but got '$value'}"

    if [[ "$value" == "true" || "$value" == "0" ]]; then
        log_test "DEBUG" "assert_true: PASS"
        return 0
    else
        log_test "ERROR" "$message"
        return 1
    fi
}

# Assert value is false
assert_false() {
    local value="$1"
    local message="${2:-Expected false but got '$value'}"

    if [[ "$value" == "0" || "$value" == "true" ]]; then
        log_test "ERROR" "$message"
        return 1
    elif [[ "$value" == "false" || "$value" == "" || "$value" =~ ^[1-9][0-9]*$ ]]; then
        log_test "DEBUG" "assert_false: PASS"
        return 0
    else
        log_test "ERROR" "$message"
        return 1
    fi
}

# Assert file exists
assert_file_exists() {
    local file="$1"
    local message="${2:-Expected file '$file' to exist}"

    if [[ -f "$file" ]]; then
        log_test "DEBUG" "assert_file_exists: PASS ($file)"
        return 0
    else
        log_test "ERROR" "$message"
        return 1
    fi
}

# Assert file does not exist
assert_file_not_exists() {
    local file="$1"
    local message="${2:-Expected file '$file' NOT to exist}"

    if [[ ! -f "$file" ]]; then
        log_test "DEBUG" "assert_file_not_exists: PASS ($file)"
        return 0
    else
        log_test "ERROR" "$message"
        return 1
    fi
}

# Assert directory exists
assert_dir_exists() {
    local dir="$1"
    local message="${2:-Expected directory '$dir' to exist}"

    if [[ -d "$dir" ]]; then
        log_test "DEBUG" "assert_dir_exists: PASS ($dir)"
        return 0
    else
        log_test "ERROR" "$message"
        return 1
    fi
}

# Assert directory does not exist
assert_dir_not_exists() {
    local dir="$1"
    local message="${2:-Expected directory '$dir' NOT to exist}"

    if [[ ! -d "$dir" ]]; then
        log_test "DEBUG" "assert_dir_not_exists: PASS ($dir)"
        return 0
    else
        log_test "ERROR" "$message"
        return 1
    fi
}

# Assert command succeeds
assert_command_success() {
    local message="${2:-Expected command to succeed: $1}"

    if eval "$1" &> /dev/null; then
        log_test "DEBUG" "assert_command_success: PASS"
        return 0
    else
        log_test "ERROR" "$message"
        return 1
    fi
}

# Assert command fails
assert_command_fails() {
    local message="${2:-Expected command to fail: $1}"

    if eval "$1" &> /dev/null; then
        log_test "ERROR" "$message"
        return 1
    else
        log_test "DEBUG" "assert_command_fails: PASS"
        return 0
    fi
}

# Assert JSON values are equal
assert_json_equals() {
    local expected="$1"
    local actual="$2"
    local jq_query="${3:-.}"
    local message="${4:-JSON values do not match}"

    if ! command -v jq &> /dev/null; then
        log_test "ERROR" "jq not installed, cannot perform JSON assertion"
        return 1
    fi

    local expected_value
    local actual_value

    expected_value=$(echo "$expected" | jq -r "$jq_query" 2>/dev/null) || {
        log_test "ERROR" "Failed to parse expected JSON"
        return 1
    }

    actual_value=$(echo "$actual" | jq -r "$jq_query" 2>/dev/null) || {
        log_test "ERROR" "Failed to parse actual JSON"
        return 1
    }

    if [[ "$expected_value" == "$actual_value" ]]; then
        log_test "DEBUG" "assert_json_equals: PASS"
        return 0
    else
        log_test "ERROR" "$message"
        log_test "ERROR" "  Expected: $expected_value"
        log_test "ERROR" "  Actual:   $actual_value"
        return 1
    fi
}

# Assert JSON contains key/value
assert_json_contains() {
    local json="$1"
    local jq_query="$2"
    local expected_value="$3"
    local message="${4:-JSON does not contain expected value}"

    if ! command -v jq &> /dev/null; then
        log_test "ERROR" "jq not installed, cannot perform JSON assertion"
        return 1
    fi

    local actual_value
    actual_value=$(echo "$json" | jq -r "$jq_query" 2>/dev/null) || {
        log_test "ERROR" "Failed to parse JSON or query not found"
        return 1
    }

    if [[ "$actual_value" == "$expected_value" ]]; then
        log_test "DEBUG" "assert_json_contains: PASS"
        return 0
    else
        log_test "ERROR" "$message"
        log_test "ERROR" "  Query: $jq_query"
        log_test "ERROR" "  Expected: $expected_value"
        log_test "ERROR" "  Actual:   $actual_value"
        return 1
    fi
}

# Assert exit code matches
assert_exit_code() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Expected exit code $expected but got $actual}"

    if [[ "$expected" -eq "$actual" ]]; then
        log_test "DEBUG" "assert_exit_code: PASS"
        return 0
    else
        log_test "ERROR" "$message"
        return 1
    fi
}

# Assert string matches regex
assert_matches() {
    local string="$1"
    local pattern="$2"
    local message="${3:-Expected '$string' to match pattern '$pattern'}"

    if [[ "$string" =~ $pattern ]]; then
        log_test "DEBUG" "assert_matches: PASS"
        return 0
    else
        log_test "ERROR" "$message"
        return 1
    fi
}

# Assert string does not match regex
assert_not_matches() {
    local string="$1"
    local pattern="$2"
    local message="${3:-Expected '$string' NOT to match pattern '$pattern'}"

    if [[ ! "$string" =~ $pattern ]]; then
        log_test "DEBUG" "assert_not_matches: PASS"
        return 0
    else
        log_test "ERROR" "$message"
        return 1
    fi
}

# Assert variable is empty
assert_empty() {
    local value="$1"
    local message="${2:-Expected empty value but got '$value'}"

    if [[ -z "$value" ]]; then
        log_test "DEBUG" "assert_empty: PASS"
        return 0
    else
        log_test "ERROR" "$message"
        return 1
    fi
}

# Assert variable is not empty
assert_not_empty() {
    local value="$1"
    local message="${2:-Expected non-empty value}"

    if [[ -n "$value" ]]; then
        log_test "DEBUG" "assert_not_empty: PASS"
        return 0
    else
        log_test "ERROR" "$message"
        return 1
    fi
}

# Assert greater than
assert_greater_than() {
    local actual="$1"
    local threshold="$2"
    local message="${3:-Expected $actual > $threshold}"

    if [[ "$actual" -gt "$threshold" ]]; then
        log_test "DEBUG" "assert_greater_than: PASS"
        return 0
    else
        log_test "ERROR" "$message"
        return 1
    fi
}

# Assert less than
assert_less_than() {
    local actual="$1"
    local threshold="$2"
    local message="${3:-Expected $actual < $threshold}"

    if [[ "$actual" -lt "$threshold" ]]; then
        log_test "DEBUG" "assert_less_than: PASS"
        return 0
    else
        log_test "ERROR" "$message"
        return 1
    fi
}

# Export assertion functions
export -f assert_equals
export -f assert_not_equals
export -f assert_contains
export -f assert_not_contains
export -f assert_true
export -f assert_false
export -f assert_file_exists
export -f assert_file_not_exists
export -f assert_dir_exists
export -f assert_dir_not_exists
export -f assert_command_success
export -f assert_command_fails
export -f assert_json_equals
export -f assert_json_contains
export -f assert_exit_code
export -f assert_matches
export -f assert_not_matches
export -f assert_empty
export -f assert_not_empty
export -f assert_greater_than
export -f assert_less_than
