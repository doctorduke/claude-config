#!/bin/bash
# Unit tests for assertion library

# Source test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/test-helpers.sh"

# Test: assert_equals with matching values
test_assert_equals_with_matching_values() {
    assert_equals "hello" "hello"
}

# Test: assert_equals with non-matching values should fail
test_assert_equals_with_non_matching_values() {
    # We expect this assertion to fail
    if assert_equals "hello" "world" 2>/dev/null; then
        return 1  # Test should fail if assertion passes
    fi
    return 0  # Test passes because assertion correctly failed
}

# Test: assert_not_equals with different values
test_assert_not_equals_with_different_values() {
    assert_not_equals "hello" "world"
}

# Test: assert_contains finds substring
test_assert_contains_finds_substring() {
    assert_contains "hello world" "world"
}

# Test: assert_not_contains when substring not present
test_assert_not_contains_when_substring_not_present() {
    assert_not_contains "hello world" "foo"
}

# Test: assert_true with true value
test_assert_true_with_true_value() {
    assert_true "true"
}

# Test: assert_false with false value
test_assert_false_with_false_value() {
    assert_false "false"
}

# Test: assert_empty with empty string
test_assert_empty_with_empty_string() {
    assert_empty ""
}

# Test: assert_not_empty with non-empty string
test_assert_not_empty_with_non_empty_string() {
    assert_not_empty "hello"
}

# Test: assert_greater_than
test_assert_greater_than() {
    assert_greater_than 10 5
}

# Test: assert_less_than
test_assert_less_than() {
    assert_less_than 5 10
}

# Test: assert_matches with regex
test_assert_matches_with_regex() {
    assert_matches "test123" "test[0-9]+"
}

# Test: assert_exit_code
test_assert_exit_code() {
    assert_exit_code 0 0
}

# Run all tests

# Test: assert_true with shell success code (0)
test_assert_true_with_zero() {
    assert_true "0"
}

# Test: assert_true rejects shell failure code (1)
test_assert_true_rejects_one() {
    if assert_true "1" 2>/dev/null; then
        return 1  # Should fail
    fi
    return 0  # Correctly rejected
}

# Test: assert_false with shell failure code (1)
test_assert_false_with_one() {
    assert_false "1"
}

# Test: assert_false with any non-zero code
test_assert_false_with_non_zero() {
    assert_false "127"
}

# Test: assert_false rejects shell success code (0)
test_assert_false_rejects_zero() {
    if assert_false "0" 2>/dev/null; then
        return 1  # Should fail
    fi
    return 0  # Correctly rejected
}

# Test: assert_false rejects true string
test_assert_false_rejects_true_string() {
    if assert_false "true" 2>/dev/null; then
        return 1  # Should fail
    fi
    return 0  # Correctly rejected
}

run_all_tests
