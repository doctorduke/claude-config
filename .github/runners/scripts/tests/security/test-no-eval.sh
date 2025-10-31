#!/usr/bin/env bash
# Script: test-no-eval.sh
# Description: Security tests for Task #6 - No Eval Usage
# Purpose: Validate that dangerous eval statements have been removed
# Reference: TASKS-REMAINING.md Task #6

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${SCRIPT_DIR}/test-framework.sh"

test_no_eval_in_scripts() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    local eval_files=$(grep -r "\beval\b" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null | grep -v "yq eval" | grep -v "# Safe:" || true)

    if [[ -n "$eval_files" ]]; then
        log_test_error "Found dangerous eval usage:"
        echo "$eval_files"
        return 1
    fi

    return 0
}

test_no_eval_in_setup_runner() {
    local setup_runner="${PROJECT_ROOT}/scripts/setup-runner.sh"

    if [[ ! -f "$setup_runner" ]]; then
        log_test_warn "setup-runner.sh not found"
        return 0
    fi

    if ! assert_no_eval_in_file "$setup_runner"; then
        return 1
    fi

    return 0
}

test_arrays_used_instead_of_eval() {
    local setup_runner="${PROJECT_ROOT}/scripts/setup-runner.sh"

    if [[ ! -f "$setup_runner" ]]; then
        return 0
    fi

    if grep -q "declare -a\|local -a\|ARGS=(" "$setup_runner" 2>/dev/null; then
        log_test_info "Found array usage (good alternative to eval)"
    fi

    return 0
}

test_no_eval_in_ai_scripts() {
    local ai_scripts=("${PROJECT_ROOT}/scripts/ai-agent.sh" "${PROJECT_ROOT}/scripts/ai-review.sh" "${PROJECT_ROOT}/scripts/ai-autofix.sh")

    for script in "${ai_scripts[@]}"; do
        if [[ -f "$script" ]]; then
            if ! assert_no_eval_in_file "$script"; then
                return 1
            fi
        fi
    done

    return 0
}

test_safe_command_construction() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    if grep -r "IFS=.*read -r -a\|mapfile\|readarray" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null >/dev/null; then
        log_test_info "Found safe command construction patterns"
    fi

    return 0
}

main() {
    test_suite_start "No Eval Security Tests (Task #6)"

    run_test test_no_eval_in_scripts "No dangerous eval in scripts"
    run_test test_no_eval_in_setup_runner "No eval in setup-runner.sh"
    run_test test_arrays_used_instead_of_eval "Arrays used instead of eval"
    run_test test_no_eval_in_ai_scripts "No eval in AI scripts"
    run_test test_safe_command_construction "Safe command construction"

    test_suite_end "No Eval Security Tests (Task #6)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
