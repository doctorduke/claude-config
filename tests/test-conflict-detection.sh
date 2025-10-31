#!/usr/bin/env bash
# Test Suite: Conflict Detection for Auto-Fix Workflow
# Description: Comprehensive tests for merge conflict detection and guidance
# Usage: ./test-conflict-detection.sh

set -euo pipefail

# Test framework setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source libraries
source "${PROJECT_ROOT}/scripts/lib/common.sh"
source "${PROJECT_ROOT}/scripts/lib/conflict-detection.sh"

# Test configuration
TEST_REPO_DIR="/tmp/conflict-test-repo-$$"
TEST_RESULTS=()
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test result tracking
pass_test() {
    local test_name="$1"
    echo -e "${GREEN}✓ PASS${NC}: ${test_name}"
    TEST_RESULTS+=("PASS: ${test_name}")
    ((TESTS_PASSED++))
}

fail_test() {
    local test_name="$1"
    local reason="${2:-Unknown failure}"
    echo -e "${RED}✗ FAIL${NC}: ${test_name}"
    echo -e "  ${RED}Reason${NC}: ${reason}"
    TEST_RESULTS+=("FAIL: ${test_name} - ${reason}")
    ((TESTS_FAILED++))
}

skip_test() {
    local test_name="$1"
    local reason="${2:-Test skipped}"
    echo -e "${YELLOW}⊘ SKIP${NC}: ${test_name}"
    echo -e "  ${YELLOW}Reason${NC}: ${reason}"
}

# Setup test repository
setup_test_repo() {
    log_info "Setting up test repository..."

    # Clean up existing test repo
    rm -rf "${TEST_REPO_DIR}"
    mkdir -p "${TEST_REPO_DIR}"
    cd "${TEST_REPO_DIR}"

    # Initialize git repo
    git init
    git config user.email "test@example.com"
    git config user.name "Test User"

    # Create main branch with initial commit
    echo "Initial content" > file1.txt
    echo "Another file" > file2.txt
    git add .
    git commit -m "Initial commit"

    # Create main branch reference
    git branch -M main

    log_info "Test repository initialized at ${TEST_REPO_DIR}"
}

# Cleanup test repository
cleanup_test_repo() {
    log_info "Cleaning up test repository..."
    cd /tmp
    rm -rf "${TEST_REPO_DIR}"
}

# Test 1: Clean merge (no conflicts)
test_clean_merge() {
    local test_name="Clean merge - no conflicts"

    cd "${TEST_REPO_DIR}"

    # Create feature branch
    git checkout -b feature/clean-branch

    # Add non-conflicting changes
    echo "Feature addition" > file3.txt
    git add file3.txt
    git commit -m "Add feature file"

    # Simulate origin/main (no changes)
    git checkout main

    # Check for conflicts from feature branch
    git checkout feature/clean-branch

    if check_merge_conflicts "main" "HEAD"; then
        pass_test "${test_name}"
    else
        fail_test "${test_name}" "Expected no conflicts, but conflicts were detected"
    fi

    git checkout main
}

# Test 2: Conflicting changes
test_conflicting_changes() {
    local test_name="Conflicting changes in same file"

    cd "${TEST_REPO_DIR}"

    # Make change on main
    git checkout main
    echo "Main branch change" > file1.txt
    git add file1.txt
    git commit -m "Update file1 on main"

    # Create feature branch from earlier commit
    git checkout HEAD~1
    git checkout -b feature/conflict-branch

    # Make conflicting change
    echo "Feature branch change" > file1.txt
    git add file1.txt
    git commit -m "Update file1 on feature"

    # Simulate checking conflicts with main
    if ! check_merge_conflicts "main" "HEAD"; then
        local status=$?
        if [[ ${status} -eq 1 ]]; then
            pass_test "${test_name}"
        else
            fail_test "${test_name}" "Unexpected error code: ${status}"
        fi
    else
        fail_test "${test_name}" "Expected conflicts, but none were detected"
    fi

    git checkout main
}

# Test 3: Branch behind base
test_branch_behind() {
    local test_name="Branch behind base branch"

    cd "${TEST_REPO_DIR}"

    # Make commits on main
    git checkout main
    echo "New feature on main" > file4.txt
    git add file4.txt
    git commit -m "Add file4 on main"

    # Create feature branch from earlier commit
    git checkout HEAD~1
    git checkout -b feature/behind-branch

    # Check if branch is behind
    if ! check_branch_behind "main" "HEAD"; then
        pass_test "${test_name}"
    else
        fail_test "${test_name}" "Expected branch to be behind, but it's not"
    fi

    git checkout main
}

# Test 4: Branch up to date
test_branch_uptodate() {
    local test_name="Branch up to date with base"

    cd "${TEST_REPO_DIR}"

    # Create feature branch from main
    git checkout main
    git checkout -b feature/uptodate-branch

    # Add change to feature
    echo "Feature content" > file5.txt
    git add file5.txt
    git commit -m "Add file5"

    # Check if branch is behind (should not be)
    if check_branch_behind "main" "HEAD"; then
        pass_test "${test_name}"
    else
        fail_test "${test_name}" "Expected branch to be up-to-date, but it's behind"
    fi

    git checkout main
}

# Test 5: Analyze conflicts
test_analyze_conflicts() {
    local test_name="Analyze conflicts and generate JSON"

    cd "${TEST_REPO_DIR}"

    # Use existing conflict scenario
    git checkout feature/conflict-branch 2>/dev/null || {
        # Recreate if doesn't exist
        git checkout main
        git checkout HEAD~1
        git checkout -b feature/conflict-branch
        echo "Feature branch change" > file1.txt
        git add file1.txt
        git commit -m "Update file1 on feature"
    }

    # Analyze conflicts
    local conflict_json
    conflict_json=$(analyze_conflicts "main" "HEAD")

    # Validate JSON structure
    if echo "${conflict_json}" | jq empty 2>/dev/null; then
        # Check for required fields
        if echo "${conflict_json}" | jq -e '.base_branch' >/dev/null && \
           echo "${conflict_json}" | jq -e '.files' >/dev/null; then
            pass_test "${test_name}"
        else
            fail_test "${test_name}" "JSON missing required fields"
        fi
    else
        fail_test "${test_name}" "Invalid JSON output"
    fi

    git checkout main
}

# Test 6: Generate conflict guidance
test_generate_guidance() {
    local test_name="Generate conflict resolution guidance"

    cd "${TEST_REPO_DIR}"

    # Create conflict analysis
    local conflict_json='{"base_branch":"main","current_branch":"feature","files":[{"file":"file1.txt","pr_commits":1,"base_commits":1,"has_conflicts":true}],"total_files":1}'

    # Generate guidance
    local guidance
    guidance=$(generate_conflict_guidance "${conflict_json}" "main" "123")

    # Validate guidance content
    if echo "${guidance}" | grep -q "Merge Conflicts Detected" && \
       echo "${guidance}" | grep -q "Resolution Steps" && \
       echo "${guidance}" | grep -q "file1.txt"; then
        pass_test "${test_name}"
    else
        fail_test "${test_name}" "Guidance missing required sections"
    fi
}

# Test 7: Pre-flight checks - no conflicts
test_preflight_noconflict() {
    local test_name="Pre-flight checks - no conflicts"

    cd "${TEST_REPO_DIR}"

    # Use clean branch
    git checkout feature/clean-branch 2>/dev/null || {
        git checkout main
        git checkout -b feature/clean-branch
        echo "Clean feature" > file6.txt
        git add file6.txt
        git commit -m "Add file6"
    }

    # Run pre-flight checks
    if run_preflight_checks "main" "HEAD"; then
        pass_test "${test_name}"
    else
        fail_test "${test_name}" "Pre-flight checks failed unexpectedly"
    fi

    git checkout main
}

# Test 8: Pre-flight checks - with conflicts
test_preflight_conflict() {
    local test_name="Pre-flight checks - detect conflicts"

    cd "${TEST_REPO_DIR}"

    # Use conflict branch
    git checkout feature/conflict-branch 2>/dev/null || {
        git checkout main
        git checkout HEAD~1
        git checkout -b feature/conflict-branch
        echo "Conflict content" > file1.txt
        git add file1.txt
        git commit -m "Conflicting change"
    }

    # Run pre-flight checks
    if ! run_preflight_checks "main" "HEAD"; then
        local status=$?
        if [[ ${status} -eq 1 ]]; then
            pass_test "${test_name}"
        else
            fail_test "${test_name}" "Expected conflict error (1), got ${status}"
        fi
    else
        fail_test "${test_name}" "Expected conflicts, but checks passed"
    fi

    git checkout main
}

# Test 9: Base branch reachable
test_base_reachable() {
    local test_name="Check base branch reachable"

    cd "${TEST_REPO_DIR}"

    # Check if main is reachable
    if check_base_branch_reachable "main"; then
        pass_test "${test_name}"
    else
        fail_test "${test_name}" "Main branch should be reachable"
    fi
}

# Test 10: Base branch unreachable
test_base_unreachable() {
    local test_name="Check base branch unreachable"

    cd "${TEST_REPO_DIR}"

    # Check for non-existent branch
    if ! check_base_branch_reachable "nonexistent-branch"; then
        pass_test "${test_name}"
    else
        fail_test "${test_name}" "Expected unreachable branch to fail check"
    fi
}

# Test 11: Multiple conflicting files
test_multiple_conflicts() {
    local test_name="Multiple conflicting files"

    cd "${TEST_REPO_DIR}"

    # Create scenario with multiple conflicts
    git checkout main
    echo "Main change 1" > file1.txt
    echo "Main change 2" > file2.txt
    git add file1.txt file2.txt
    git commit -m "Update multiple files on main"

    # Create feature branch from earlier
    git checkout HEAD~1
    git checkout -b feature/multi-conflict

    echo "Feature change 1" > file1.txt
    echo "Feature change 2" > file2.txt
    git add file1.txt file2.txt
    git commit -m "Update same files on feature"

    # Check for conflicts
    if ! check_merge_conflicts "main" "HEAD"; then
        # Analyze conflicts
        local conflict_json
        conflict_json=$(analyze_conflicts "main" "HEAD")

        # Check if multiple files are detected
        local file_count
        file_count=$(echo "${conflict_json}" | jq -r '.files | length')

        if [[ ${file_count} -ge 2 ]]; then
            pass_test "${test_name}"
        else
            fail_test "${test_name}" "Expected 2+ conflicting files, got ${file_count}"
        fi
    else
        fail_test "${test_name}" "Expected conflicts, but none detected"
    fi

    git checkout main
}

# Test 12: Empty repository handling
test_empty_repo() {
    local test_name="Handle empty repository gracefully"

    # Create empty repo
    local empty_repo="/tmp/empty-repo-$$"
    mkdir -p "${empty_repo}"
    cd "${empty_repo}"
    git init

    # Try to check conflicts (should handle gracefully)
    if ! check_merge_conflicts "main" "HEAD" 2>/dev/null; then
        pass_test "${test_name}"
    else
        fail_test "${test_name}" "Should fail gracefully on empty repo"
    fi

    cd /tmp
    rm -rf "${empty_repo}"
}

# Test 13: Conflict guidance markdown format
test_guidance_markdown() {
    local test_name="Conflict guidance markdown formatting"

    local conflict_json='{"base_branch":"main","files":[{"file":"test.js","pr_commits":2,"base_commits":3,"size_lines":150,"has_conflicts":true}],"total_files":1}'

    local guidance
    guidance=$(generate_conflict_guidance "${conflict_json}" "main" "456")

    # Check markdown formatting
    if echo "${guidance}" | grep -q "^##" && \
       echo "${guidance}" | grep -q "^|" && \
       echo "${guidance}" | grep -q "\`\`\`bash"; then
        pass_test "${test_name}"
    else
        fail_test "${test_name}" "Guidance missing markdown formatting"
    fi
}

# Test 14: Integration with ai-autofix.sh
test_integration_autofix() {
    local test_name="Integration with ai-autofix.sh script"

    # Check if ai-autofix.sh sources conflict-detection.sh
    local autofix_script="${PROJECT_ROOT}/scripts/ai-autofix.sh"

    if [[ -f "${autofix_script}" ]]; then
        if grep -q "conflict-detection.sh" "${autofix_script}"; then
            pass_test "${test_name}"
        else
            fail_test "${test_name}" "ai-autofix.sh doesn't source conflict-detection.sh"
        fi
    else
        skip_test "${test_name}" "ai-autofix.sh not found"
    fi
}

# Test 15: Workflow integration check
test_workflow_integration() {
    local test_name="Workflow integration in ai-autofix.yml"

    local workflow="${PROJECT_ROOT}/.github/workflows/ai-autofix.yml"

    if [[ -f "${workflow}" ]]; then
        if grep -q "conflict" "${workflow}" || grep -q "preflight" "${workflow}"; then
            pass_test "${test_name}"
        else
            fail_test "${test_name}" "Workflow missing conflict detection steps"
        fi
    else
        skip_test "${test_name}" "ai-autofix.yml not found"
    fi
}

# Print test summary
print_summary() {
    echo ""
    echo "========================================"
    echo "Test Summary"
    echo "========================================"
    echo -e "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"
    echo -e "${GREEN}Passed: ${TESTS_PASSED}${NC}"
    echo -e "${RED}Failed: ${TESTS_FAILED}${NC}"
    echo ""

    if [[ ${TESTS_FAILED} -gt 0 ]]; then
        echo "Failed Tests:"
        for result in "${TEST_RESULTS[@]}"; do
            if [[ "${result}" == FAIL:* ]]; then
                echo -e "  ${RED}- ${result#FAIL: }${NC}"
            fi
        done
        echo ""
    fi

    local pass_rate=0
    if [[ $((TESTS_PASSED + TESTS_FAILED)) -gt 0 ]]; then
        pass_rate=$(( TESTS_PASSED * 100 / (TESTS_PASSED + TESTS_FAILED) ))
    fi

    echo "Pass Rate: ${pass_rate}%"
    echo "========================================"
}

# Main test execution
main() {
    echo "=========================================="
    echo "Conflict Detection Test Suite"
    echo "=========================================="
    echo ""

    # Setup
    setup_test_repo

    # Run tests
    test_clean_merge
    test_conflicting_changes
    test_branch_behind
    test_branch_uptodate
    test_analyze_conflicts
    test_generate_guidance
    test_preflight_noconflict
    test_preflight_conflict
    test_base_reachable
    test_base_unreachable
    test_multiple_conflicts
    test_empty_repo
    test_guidance_markdown
    test_integration_autofix
    test_workflow_integration
    test_special_chars_quotes
    test_special_chars_spaces
    test_special_chars_unicode

    # Cleanup
    cleanup_test_repo

    # Summary
    print_summary

    # Exit with appropriate code
    if [[ ${TESTS_FAILED} -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

# Run tests
main "$@"

# Test 16: Special character filenames - quotes
test_special_chars_quotes() {
    local test_name="Handle filenames with double quotes"

    cd "${TEST_REPO_DIR}"

    # Create main branch change
    git checkout main
    echo 'file with "quotes"' > 'test"file.txt'
    git add 'test"file.txt'
    git commit -m 'Add file with quotes'

    # Create feature branch from earlier
    git checkout HEAD~1
    git checkout -b feature/special-quotes

    # Make conflicting change
    echo 'different content' > 'test"file.txt'
    git add 'test"file.txt'
    git commit -m 'Update file with quotes'

    # Analyze conflicts - should not break JSON
    local conflict_json
    if conflict_json=$(analyze_conflicts "main" "HEAD" 2>&1); then
        # Validate JSON is well-formed
        if echo "${conflict_json}" | jq empty 2>/dev/null; then
            # Check if filename is properly escaped in JSON
            if echo "${conflict_json}" | jq -e '.files[] | select(.file == "test\"file.txt")' >/dev/null 2>&1; then
                pass_test "${test_name}"
            else
                fail_test "${test_name}" "Filename with quotes not properly handled in JSON"
            fi
        else
            fail_test "${test_name}" "Invalid JSON with quoted filename: ${conflict_json}"
        fi
    else
        fail_test "${test_name}" "analyze_conflicts failed with quoted filename"
    fi

    git checkout main
}

# Test 17: Special character filenames - spaces
test_special_chars_spaces() {
    local test_name="Handle filenames with spaces"

    cd "${TEST_REPO_DIR}"

    # Create main branch change
    git checkout main
    echo 'file with spaces' > 'test file with spaces.txt'
    git add 'test file with spaces.txt'
    git commit -m 'Add file with spaces'

    # Create feature branch from earlier
    git checkout HEAD~1
    git checkout -b feature/special-spaces

    # Make conflicting change
    echo 'different content' > 'test file with spaces.txt'
    git add 'test file with spaces.txt'
    git commit -m 'Update file with spaces'

    # Analyze conflicts - should handle spaces correctly
    local conflict_json
    if conflict_json=$(analyze_conflicts "main" "HEAD" 2>&1); then
        # Validate JSON is well-formed
        if echo "${conflict_json}" | jq empty 2>/dev/null; then
            # Check if filename with spaces is in JSON
            if echo "${conflict_json}" | jq -e '.files[] | select(.file == "test file with spaces.txt")' >/dev/null 2>&1; then
                pass_test "${test_name}"
            else
                fail_test "${test_name}" "Filename with spaces not found in JSON"
            fi
        else
            fail_test "${test_name}" "Invalid JSON with spaces in filename"
        fi
    else
        fail_test "${test_name}" "analyze_conflicts failed with spaces in filename"
    fi

    git checkout main
}

# Test 18: Special character filenames - unicode
test_special_chars_unicode() {
    local test_name="Handle filenames with unicode characters"

    cd "${TEST_REPO_DIR}"

    # Create main branch change
    git checkout main
    echo 'file with unicode' > 'test_файл_文件.txt'
    git add 'test_файл_文件.txt'
    git commit -m 'Add file with unicode'

    # Create feature branch from earlier
    git checkout HEAD~1
    git checkout -b feature/special-unicode

    # Make conflicting change
    echo 'different content' > 'test_файл_文件.txt'
    git add 'test_файл_文件.txt'
    git commit -m 'Update file with unicode'

    # Analyze conflicts
    local conflict_json
    if conflict_json=$(analyze_conflicts "main" "HEAD" 2>&1); then
        # Validate JSON is well-formed
        if echo "${conflict_json}" | jq empty 2>/dev/null; then
            pass_test "${test_name}"
        else
            fail_test "${test_name}" "Invalid JSON with unicode filename"
        fi
    else
        fail_test "${test_name}" "analyze_conflicts failed with unicode filename"
    fi

    git checkout main
}
