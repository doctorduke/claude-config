#!/usr/bin/env bash
# Library: conflict-detection.sh
# Description: Merge conflict detection and guidance for auto-fix workflow
# Usage: Source this file and call check_merge_conflicts()

set -euo pipefail

# Configuration
readonly CONFLICT_LABEL="merge-conflicts"
readonly CONFLICT_MARKER_START="<<<<<<<"
readonly CONFLICT_MARKER_MID="======="
readonly CONFLICT_MARKER_END=">>>>>>>"

# Check if there are merge conflicts with target branch
# Args:
#   $1 - base branch name (e.g., "main")
#   $2 - current branch name (optional, defaults to current HEAD)
# Returns:
#   0 - No conflicts detected
#   1 - Conflicts detected
check_merge_conflicts() {
    local base_branch="${1:-main}"
    local current_branch="${2:-HEAD}"

    log_info "Checking for merge conflicts with ${base_branch}..."

    # Fetch latest from base branch
    if ! git fetch origin "${base_branch}" 2>/dev/null; then
        log_error "Failed to fetch ${base_branch} from origin"
        return 2
    fi

    # Find merge base
    local merge_base
    if ! merge_base=$(git merge-base "${current_branch}" "origin/${base_branch}" 2>/dev/null); then
        log_error "Failed to find merge base between ${current_branch} and origin/${base_branch}"
        return 2
    fi

    log_debug "Merge base: ${merge_base}"

    # Perform three-way merge simulation
    local merge_tree_output
    merge_tree_output=$(git merge-tree "${merge_base}" "${current_branch}" "origin/${base_branch}" 2>/dev/null)

    # Check for conflict markers
    if echo "${merge_tree_output}" | grep -q "^${CONFLICT_MARKER_START}"; then
        log_warn "Merge conflicts detected with ${base_branch}"
        return 1
    else
        log_info "No merge conflicts detected"
        return 0
    fi
}

# Analyze conflicts and provide detailed information
# Args:
#   $1 - base branch name (e.g., "main")
#   $2 - current branch name (optional, defaults to current HEAD)
# Outputs:
#   JSON object with conflict details
analyze_conflicts() {
    local base_branch="${1:-main}"
    local current_branch="${2:-HEAD}"

    log_info "Analyzing merge conflicts..."

    # Find merge base
    local merge_base
    merge_base=$(git merge-base "${current_branch}" "origin/${base_branch}" 2>/dev/null || echo "")

    if [[ -z "${merge_base}" ]]; then
        # FIXED: Use jq for safe JSON construction
        jq -n --arg error "Failed to find merge base" '{error: $error}'
        return 1
    fi

    # Get merge tree output
    local merge_tree_output
    merge_tree_output=$(git merge-tree "${merge_base}" "${current_branch}" "origin/${base_branch}" 2>/dev/null)

    # Extract files from diff output
    local diff_files
    diff_files=$(git diff --name-only "${merge_base}...${current_branch}" 2>/dev/null || echo "")

    # Build file array using jq (safe for filenames with special characters)
    local files_json="[]"

    # Analyze each potentially conflicting file
    while IFS= read -r file; do
        [[ -z "${file}" ]] && continue

        # Count commits in PR branch
        local pr_commits
        pr_commits=$(git log --oneline "${merge_base}..${current_branch}" -- "${file}" 2>/dev/null | wc -l || echo 0)

        # Count commits in base branch
        local base_commits
        base_commits=$(git log --oneline "${merge_base}..origin/${base_branch}" -- "${file}" 2>/dev/null | wc -l || echo 0)

        # Get file size
        local file_size=0
        if [[ -f "${file}" ]]; then
            file_size=$(wc -l < "${file}" 2>/dev/null || echo 0)
        fi

        # FIXED: Check if file has actual conflicts using proper merge-tree parsing
        local has_conflicts="false"
        if echo "${merge_tree_output}" | grep -q "^${CONFLICT_MARKER_START}"; then
            # Check if the conflict markers are for this specific file
            # Use awk to extract the section for this specific file
            local file_section
            file_section=$(echo "${merge_tree_output}" | awk -v file="${file}" '
                /^changed in both/ { in_section = ($4 == file || $NF == file) }
                in_section { print }
                /^$/ { in_section = 0 }
            ')
            if [[ -n "${file_section}" ]] && echo "${file_section}" | grep -q "^${CONFLICT_MARKER_START}"; then
                has_conflicts="true"
            fi
        fi

        # Only include files with changes
        if [[ "${pr_commits}" -gt 0 ]] || [[ "${base_commits}" -gt 0 ]]; then
            # FIXED: Use jq to safely build JSON object for this file (handles special chars)
            files_json=$(jq -n \
                --argjson files "${files_json}" \
                --arg file "${file}" \
                --argjson pr_commits "${pr_commits}" \
                --argjson base_commits "${base_commits}" \
                --argjson size_lines "${file_size}" \
                --argjson has_conflicts "${has_conflicts}" \
                '$files + [{
                    file: $file,
                    pr_commits: $pr_commits,
                    base_commits: $base_commits,
                    size_lines: $size_lines,
                    has_conflicts: $has_conflicts
                }]')
        fi
    done < <(echo "${diff_files}")

    # Get file count
    local file_count
    file_count=$(echo "${files_json}" | jq 'length')

    # FIXED: Build final JSON structure using jq (no manual string concatenation)
    jq -n \
        --arg base_branch "${base_branch}" \
        --arg current_branch "${current_branch}" \
        --arg merge_base "${merge_base}" \
        --argjson files "${files_json}" \
        --argjson total_files "${file_count}" \
        '{
            base_branch: $base_branch,
            current_branch: $current_branch,
            merge_base: $merge_base,
            files: $files,
            total_files: $total_files
        }'
}

# Generate conflict resolution guidance
# Args:
#   $1 - conflict analysis JSON
#   $2 - base branch name
#   $3 - pr number (optional)
# Outputs:
#   Markdown formatted guidance
generate_conflict_guidance() {
    local conflict_json="$1"
    local base_branch="$2"
    local pr_number="${3:-}"

    local total_files
    total_files=$(echo "${conflict_json}" | jq -r '.total_files // 0')

    if [[ "${total_files}" -eq 0 ]]; then
        echo "No conflicts detected."
        return 0
    fi

    # Build markdown guidance
    cat << EOF
## Merge Conflicts Detected

Auto-fix cannot proceed due to merge conflicts with the \`${base_branch}\` branch.

### Conflicting Files

$(echo "${conflict_json}" | jq -r '.files[] | "- **\(.file)**: \(.pr_commits) commit(s) in PR, \(.base_commits) commit(s) in ${base_branch}"')

### Conflict Details

| File | PR Changes | Base Changes | Size | Status |
|------|-----------|--------------|------|--------|
$(echo "${conflict_json}" | jq -r '.files[] | "| \(.file) | \(.pr_commits) | \(.base_commits) | \(.size_lines) lines | \(if .has_conflicts then "⚠️ Conflicts" else "✓ Diverged" end) |"')

### Resolution Steps

#### Option 1: Merge Strategy (Recommended)

\`\`\`bash
# Fetch latest changes
git fetch origin ${base_branch}

# Merge base branch into your branch
git merge origin/${base_branch}

# Resolve conflicts in your editor
# After resolving, stage the files
git add <resolved-files>

# Complete the merge
git commit

# Push your changes
git push
\`\`\`

#### Option 2: Rebase Strategy (Clean History)

\`\`\`bash
# Fetch latest changes
git fetch origin ${base_branch}

# Rebase your branch onto base
git rebase origin/${base_branch}

# Resolve conflicts as they appear
# After resolving each conflict:
git add <resolved-files>
git rebase --continue

# Force push (only if not shared with others)
git push --force-with-lease
\`\`\`

### After Resolution

Once conflicts are resolved and pushed, you can re-trigger auto-fix by:
EOF

    if [[ -n "${pr_number}" ]]; then
        cat << EOF
- Commenting \`/autofix\` on PR #${pr_number}
- Re-labeling with \`auto-fix\` label
EOF
    else
        cat << EOF
- Commenting \`/autofix\` on the PR
- Re-labeling with \`auto-fix\` label
- Manually triggering the workflow
EOF
    fi

    cat << EOF

### Alternative: Request Manual Review

If conflicts are complex, consider:
- Requesting a maintainer review
- Breaking the PR into smaller changes
- Merging ${base_branch} first, then re-running auto-fix

---

**Need Help?** Check the [conflict resolution guide](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/addressing-merge-conflicts) or ask a maintainer.
EOF
}

# Check if PR branch is behind base branch
# Args:
#   $1 - base branch name
#   $2 - current branch name (optional)
# Returns:
#   0 - Branch is up to date or ahead
#   1 - Branch is behind base
check_branch_behind() {
    local base_branch="${1:-main}"
    local current_branch="${2:-HEAD}"

    log_debug "Checking if branch is behind ${base_branch}..."

    # Fetch latest
    git fetch origin "${base_branch}" 2>/dev/null || return 2

    # Count commits behind
    local commits_behind
    commits_behind=$(git rev-list --count "${current_branch}..origin/${base_branch}" 2>/dev/null || echo 0)

    if [[ "${commits_behind}" -gt 0 ]]; then
        log_warn "Branch is ${commits_behind} commit(s) behind ${base_branch}"
        return 1
    else
        log_debug "Branch is up to date with ${base_branch}"
        return 0
    fi
}

# Check if base branch is reachable
# Args:
#   $1 - base branch name
# Returns:
#   0 - Branch is reachable
#   1 - Branch is not reachable
check_base_branch_reachable() {
    local base_branch="${1:-main}"

    log_debug "Checking if ${base_branch} is reachable..."

    if ! git ls-remote --heads origin "${base_branch}" &>/dev/null; then
        log_error "Base branch ${base_branch} is not reachable"
        return 1
    fi

    log_debug "Base branch ${base_branch} is reachable"
    return 0
}

# Run all pre-flight checks before auto-fix
# Args:
#   $1 - base branch name
#   $2 - current branch name (optional)
# Returns:
#   0 - All checks passed
#   1 - Conflicts detected
#   2 - Branch is behind
#   3 - Base branch not reachable
#   4 - Other error
run_preflight_checks() {
    local base_branch="${1:-main}"
    local current_branch="${2:-HEAD}"

    log_info "Running pre-flight checks for auto-fix..."

    # Check 1: Base branch reachable
    if ! check_base_branch_reachable "${base_branch}"; then
        log_error "Pre-flight check failed: Base branch not reachable"
        return 3
    fi

    # Check 2: Branch status (behind/up-to-date)
    if ! check_branch_behind "${base_branch}" "${current_branch}"; then
        log_warn "Pre-flight check warning: Branch is behind ${base_branch}"
        log_info "This may indicate potential conflicts, but is not blocking"
    fi

    # Check 3: Merge conflicts
    local conflict_status=0
    if ! check_merge_conflicts "${base_branch}" "${current_branch}"; then
        conflict_status=$?

        if [[ ${conflict_status} -eq 1 ]]; then
            log_error "Pre-flight check failed: Merge conflicts detected"
            return 1
        elif [[ ${conflict_status} -eq 2 ]]; then
            log_error "Pre-flight check failed: Unable to check conflicts"
            return 4
        fi
    fi

    log_info "All pre-flight checks passed"
    return 0
}

# Post conflict report as PR comment
# Args:
#   $1 - PR number
#   $2 - conflict analysis JSON
#   $3 - base branch name
# Requires:
#   GITHUB_TOKEN environment variable
post_conflict_comment() {
    local pr_number="$1"
    local conflict_json="$2"
    local base_branch="$3"

    if [[ -z "${GITHUB_TOKEN:-}" ]]; then
        log_error "GITHUB_TOKEN not set, cannot post comment"
        return 1
    fi

    if ! command -v gh &>/dev/null; then
        log_error "GitHub CLI (gh) not found, cannot post comment"
        return 1
    fi

    log_info "Posting conflict report to PR #${pr_number}..."

    # Generate guidance
    local guidance
    guidance=$(generate_conflict_guidance "${conflict_json}" "${base_branch}" "${pr_number}")

    # Create temp file for comment
    local comment_file
    comment_file=$(mktemp)
    echo "${guidance}" > "${comment_file}"

    # Post comment using gh CLI
    if gh pr comment "${pr_number}" --body-file "${comment_file}"; then
        log_info "Successfully posted conflict report"
        rm -f "${comment_file}"
        return 0
    else
        log_error "Failed to post conflict report"
        rm -f "${comment_file}"
        return 1
    fi
}

# Add merge conflict label to PR
# Args:
#   $1 - PR number
# Requires:
#   GITHUB_TOKEN environment variable
add_conflict_label() {
    local pr_number="$1"

    if [[ -z "${GITHUB_TOKEN:-}" ]]; then
        log_error "GITHUB_TOKEN not set, cannot add label"
        return 1
    fi

    if ! command -v gh &>/dev/null; then
        log_error "GitHub CLI (gh) not found, cannot add label"
        return 1
    fi

    log_info "Adding ${CONFLICT_LABEL} label to PR #${pr_number}..."

    if gh pr edit "${pr_number}" --add-label "${CONFLICT_LABEL}"; then
        log_info "Successfully added conflict label"
        return 0
    else
        log_warn "Failed to add conflict label (it may not exist)"
        return 1
    fi
}

# Remove merge conflict label from PR
# Args:
#   $1 - PR number
# Requires:
#   GITHUB_TOKEN environment variable
remove_conflict_label() {
    local pr_number="$1"

    if [[ -z "${GITHUB_TOKEN:-}" ]]; then
        log_error "GITHUB_TOKEN not set, cannot remove label"
        return 1
    fi

    if ! command -v gh &>/dev/null; then
        log_error "GitHub CLI (gh) not found, cannot remove label"
        return 1
    fi

    log_info "Removing ${CONFLICT_LABEL} label from PR #${pr_number}..."

    if gh pr edit "${pr_number}" --remove-label "${CONFLICT_LABEL}"; then
        log_info "Successfully removed conflict label"
        return 0
    else
        log_debug "Label may not exist on PR"
        return 0
    fi
}

# Handle conflict detection and reporting workflow
# Args:
#   $1 - PR number
#   $2 - base branch name
#   $3 - current branch name (optional)
# Returns:
#   0 - No conflicts, safe to proceed
#   1 - Conflicts detected and reported
#   2 - Error during detection
handle_conflict_workflow() {
    local pr_number="$1"
    local base_branch="${2:-main}"
    local current_branch="${3:-HEAD}"

    log_info "Starting conflict detection workflow for PR #${pr_number}..."

    # Run pre-flight checks
    local preflight_status=0
    if ! run_preflight_checks "${base_branch}" "${current_branch}"; then
        preflight_status=$?

        case ${preflight_status} in
            1)
                # Conflicts detected
                log_warn "Conflicts detected, analyzing..."

                # Analyze conflicts
                local conflict_json
                conflict_json=$(analyze_conflicts "${base_branch}" "${current_branch}")

                # Post comment
                post_conflict_comment "${pr_number}" "${conflict_json}" "${base_branch}" || true

                # Add label
                add_conflict_label "${pr_number}" || true

                log_error "Auto-fix cannot proceed due to merge conflicts"
                return 1
                ;;
            2)
                log_warn "Branch is behind base, but no conflicts detected"
                log_info "Proceeding with caution..."
                return 0
                ;;
            3)
                log_error "Base branch not reachable"
                return 2
                ;;
            4)
                log_error "Error during conflict detection"
                return 2
                ;;
        esac
    fi

    # No conflicts, safe to proceed
    log_info "No conflicts detected, safe to proceed with auto-fix"

    # Remove conflict label if present
    remove_conflict_label "${pr_number}" || true

    return 0
}

# Export functions
export -f check_merge_conflicts
export -f analyze_conflicts
export -f generate_conflict_guidance
export -f check_branch_behind
export -f check_base_branch_reachable
export -f run_preflight_checks
export -f post_conflict_comment
export -f add_conflict_label
export -f remove_conflict_label
export -f handle_conflict_workflow
