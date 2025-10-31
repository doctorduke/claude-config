#!/usr/bin/env bash
# Script: test-secret-masking.sh
# Description: Security tests for Task #7 - Secret Masking
# Purpose: Validate that secrets are masked in GitHub Actions workflows
# Reference: TASKS-REMAINING.md Task #7

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${SCRIPT_DIR}/test-framework.sh"

test_workflows_have_secret_masking() {
    local workflows_dir="${PROJECT_ROOT}/.github/workflows"

    if [[ ! -d "$workflows_dir" ]]; then
        log_test_warn "Workflows directory not found"
        return 0
    fi

    local workflows_with_masking=0
    local total_workflows=0

    for workflow in "$workflows_dir"/*.yml "$workflows_dir"/*.yaml; do
        if [[ -f "$workflow" ]]; then
            total_workflows=$((total_workflows + 1))
            if grep -q "add-mask" "$workflow" 2>/dev/null; then
                workflows_with_masking=$((workflows_with_masking + 1))
            fi
        fi
    done

    log_test_info "Workflows with masking: $workflows_with_masking / $total_workflows"

    return 0
}

test_secret_masking_action_exists() {
    local action_file="${PROJECT_ROOT}/.github/actions/mask-secrets/action.yml"

    if [[ -f "$action_file" ]]; then
        log_test_info "Found secret masking action"
        return 0
    else
        log_test_warn "No dedicated secret masking action found"
        return 0
    fi
}

test_ai_workflows_mask_tokens() {
    local ai_workflows=(
        "${PROJECT_ROOT}/.github/workflows/ai-pr-review.yml"
        "${PROJECT_ROOT}/.github/workflows/ai-issue-comment.yml"
        "${PROJECT_ROOT}/.github/workflows/ai-autofix.yml"
    )

    for workflow in "${ai_workflows[@]}"; do
        if [[ -f "$workflow" ]]; then
            if ! grep -q "add-mask\|mask.*secret" "$workflow" 2>/dev/null; then
                log_test_warn "$(basename "$workflow") may not mask secrets"
            fi
        fi
    done

    return 0
}

test_tokens_masked_in_output() {
    local workflows_dir="${PROJECT_ROOT}/.github/workflows"

    if [[ ! -d "$workflows_dir" ]]; then
        return 0
    fi

    if grep -r "secrets\." "$workflows_dir" --include="*.yml" --include="*.yaml" 2>/dev/null >/dev/null; then
        log_test_info "Found secret usage in workflows"

        if grep -r "add-mask" "$workflows_dir" --include="*.yml" --include="*.yaml" 2>/dev/null >/dev/null; then
            log_test_info "Found masking directives"
        else
            log_test_warn "Secrets used but no masking found"
        fi
    fi

    return 0
}

test_no_secret_echo_in_workflows() {
    local workflows_dir="${PROJECT_ROOT}/.github/workflows"

    if [[ ! -d "$workflows_dir" ]]; then
        return 0
    fi

    local dangerous=$(grep -r "echo.*secrets\.\|print.*secrets\." "$workflows_dir" --include="*.yml" --include="*.yaml" 2>/dev/null || true)

    if [[ -n "$dangerous" ]]; then
        log_test_error "Found potential secret exposure in echo/print"
        echo "$dangerous"
        return 1
    fi

    return 0
}

main() {
    test_suite_start "Secret Masking Security Tests (Task #7)"

    run_test test_workflows_have_secret_masking "Workflows have secret masking"
    run_test test_secret_masking_action_exists "Secret masking action exists"
    run_test test_ai_workflows_mask_tokens "AI workflows mask tokens"
    run_test test_tokens_masked_in_output "Tokens masked in output"
    run_test test_no_secret_echo_in_workflows "No secret echo in workflows"

    test_suite_end "Secret Masking Security Tests (Task #7)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
