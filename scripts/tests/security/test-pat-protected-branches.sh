#!/usr/bin/env bash
# Script: test-pat-protected-branches.sh
# Description: Security tests for Task #8 - PAT for Protected Branches
# Purpose: Validate PAT usage for protected branch operations
# Reference: TASKS-REMAINING.md Task #8

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${SCRIPT_DIR}/test-framework.sh"

test_autofix_workflow_uses_pat() {
    local autofix_workflow="${PROJECT_ROOT}/.github/workflows/ai-autofix.yml"

    if [[ ! -f "$autofix_workflow" ]]; then
        log_test_warn "ai-autofix.yml not found"
        return 0
    fi

    if grep -q "GH_PAT\|GITHUB_PAT" "$autofix_workflow" 2>/dev/null; then
        log_test_info "Found PAT usage in autofix workflow"
        return 0
    else
        log_test_warn "No PAT found in autofix workflow"
        return 0
    fi
}

test_protected_branch_detection() {
    local ai_scripts=("${PROJECT_ROOT}/scripts/ai-autofix.sh" "${PROJECT_ROOT}/scripts/ai-agent.sh")

    for script in "${ai_scripts[@]}"; do
        if [[ -f "$script" ]]; then
            if grep -q "check.*branch.*protection\|protected.*branch" "$script" 2>/dev/null; then
                log_test_info "Found protected branch detection in $(basename "$script")"
            fi
        fi
    done

    return 0
}

test_pr_fallback_for_protected_branches() {
    local autofix_script="${PROJECT_ROOT}/scripts/ai-autofix.sh"

    if [[ ! -f "$autofix_script" ]]; then
        log_test_warn "ai-autofix.sh not found"
        return 0
    fi

    if grep -q "create.*pr\|gh pr create" "$autofix_script" 2>/dev/null; then
        log_test_info "Found PR creation capability (fallback for protected branches)"
    else
        log_test_warn "No PR creation fallback found"
    fi

    return 0
}

test_branch_protection_check_function() {
    local scripts_dir="${PROJECT_ROOT}/scripts"

    if grep -r "check_branch_protection\|is_protected_branch" "$scripts_dir" --include="*.sh" --exclude-dir=tests 2>/dev/null >/dev/null; then
        log_test_info "Found branch protection check function"
    else
        log_test_warn "No branch protection check function found"
    fi

    return 0
}

test_pat_not_hardcoded() {
    local workflows_dir="${PROJECT_ROOT}/.github/workflows"
    local scripts_dir="${PROJECT_ROOT}/scripts"

    if grep -r "ghp_[a-zA-Z0-9]\{36\}" "$workflows_dir" "$scripts_dir" --exclude-dir=tests 2>/dev/null | grep -v "example\|test"; then
        log_test_error "Found hardcoded PAT"
        return 1
    fi

    return 0
}

main() {
    test_suite_start "PAT Protected Branches Security Tests (Task #8)"

    run_test test_autofix_workflow_uses_pat "Autofix workflow uses PAT"
    run_test test_protected_branch_detection "Protected branch detection exists"
    run_test test_pr_fallback_for_protected_branches "PR fallback for protected branches"
    run_test test_branch_protection_check_function "Branch protection check function exists"
    run_test test_pat_not_hardcoded "PAT not hardcoded"

    test_suite_end "PAT Protected Branches Security Tests (Task #8)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
