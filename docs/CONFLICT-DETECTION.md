# Merge Conflict Detection for Auto-Fix Workflow

## Overview

The auto-fix workflow includes intelligent merge conflict detection to prevent automated changes from creating merge conflicts or being lost when the PR branch is behind the base branch.

## Features

### Pre-Flight Checks

Before applying any automated fixes, the system performs comprehensive pre-flight checks:

1. **Base Branch Reachability**: Validates that the target base branch is accessible
2. **Branch Status Check**: Determines if the PR branch is behind the base branch
3. **Merge Conflict Detection**: Uses git merge-tree to simulate a three-way merge and detect conflicts
4. **Conflict Analysis**: Provides detailed analysis of conflicting files with commit counts

### Conflict Detection Strategy

The system uses a three-way merge simulation approach:

```bash
# Find common ancestor
MERGE_BASE=$(git merge-base HEAD origin/main)

# Simulate merge and check for conflict markers
git merge-tree $MERGE_BASE HEAD origin/main | grep "^<<<"
```

This approach:
- Does not modify the working tree
- Detects conflicts before they occur
- Works with any base branch
- Provides accurate conflict information

### Conflict Guidance

When conflicts are detected, the system provides comprehensive guidance:

#### Automatic PR Comment

A detailed comment is posted to the PR containing:
- List of conflicting files
- Number of commits in PR vs base branch for each file
- File sizes and conflict status
- Step-by-step resolution instructions
- Multiple resolution strategies (merge vs rebase)

#### Example Comment

```markdown
## Merge Conflicts Detected

Auto-fix cannot proceed due to merge conflicts with the `main` branch.

### Conflicting Files

- **src/index.js**: 2 commit(s) in PR, 3 commit(s) in main
- **config/settings.yaml**: 1 commit(s) in PR, 1 commit(s) in main

### Conflict Details

| File | PR Changes | Base Changes | Size | Status |
|------|-----------|--------------|------|--------|
| src/index.js | 2 | 3 | 245 lines | ⚠️ Conflicts |
| config/settings.yaml | 1 | 1 | 42 lines | ⚠️ Conflicts |

### Resolution Steps

#### Option 1: Merge Strategy (Recommended)

\`\`\`bash
# Fetch latest changes
git fetch origin main

# Merge base branch into your branch
git merge origin/main

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
git fetch origin main

# Rebase your branch onto base
git rebase origin/main

# Resolve conflicts as they appear
# After resolving each conflict:
git add <resolved-files>
git rebase --continue

# Force push (only if not shared with others)
git push --force-with-lease
\`\`\`

### After Resolution

Once conflicts are resolved and pushed, you can re-trigger auto-fix by:
- Commenting `/autofix` on PR #123
- Re-labeling with `auto-fix` label

### Alternative: Request Manual Review

If conflicts are complex, consider:
- Requesting a maintainer review
- Breaking the PR into smaller changes
- Merging main first, then re-running auto-fix

---

**Need Help?** Check the [conflict resolution guide](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/addressing-merge-conflicts) or ask a maintainer.
```

### PR Labeling

When conflicts are detected:
- The `merge-conflicts` label is added to the PR
- This label is automatically removed when conflicts are resolved
- Helps maintainers quickly identify PRs needing attention

## Usage

### In Auto-Fix Script

The ai-autofix.sh script automatically performs conflict detection when a PR number is specified:

```bash
# Auto-fix with conflict detection
./scripts/ai-autofix.sh --pr 123

# Skip conflict detection (force mode)
./scripts/ai-autofix.sh --pr 123 --skip-conflict-check

# Use custom base branch
./scripts/ai-autofix.sh --pr 123 --base-branch develop
```

### In GitHub Workflow

The workflow automatically includes conflict detection:

```yaml
- name: Pre-flight conflict detection
  run: |
    source ./scripts/lib/conflict-detection.sh

    if ! run_preflight_checks "main" "HEAD"; then
      echo "Conflicts detected!"
      exit 1
    fi
```

### Manual Conflict Detection

You can also use the library directly:

```bash
# Source the library
source scripts/lib/conflict-detection.sh

# Check for conflicts
if check_merge_conflicts "main" "HEAD"; then
  echo "No conflicts"
else
  echo "Conflicts detected"
fi

# Analyze conflicts
conflict_json=$(analyze_conflicts "main" "HEAD")
echo "$conflict_json" | jq .

# Generate guidance
guidance=$(generate_conflict_guidance "$conflict_json" "main" "123")
echo "$guidance"
```

## Configuration

### Environment Variables

- `BASE_BRANCH`: Default base branch for conflict detection (default: `main`)
- `SKIP_CONFLICT_CHECK`: Set to `true` to bypass conflict detection
- `GITHUB_TOKEN`: Required for posting PR comments and labels

### Workflow Inputs

When manually triggering the workflow:

```yaml
inputs:
  skip_conflict_check:
    description: 'Skip merge conflict detection'
    required: false
    type: boolean
    default: false
```

## Exit Codes

The conflict detection system uses specific exit codes:

- `0`: No conflicts detected, safe to proceed
- `1`: Merge conflicts detected
- `2`: Branch is behind base (warning, not blocking)
- `3`: Base branch not reachable
- `4`: Error during conflict detection
- `5`: Auto-fix blocked by conflicts (script-level)

## Architecture

### Components

#### 1. conflict-detection.sh Library

Location: `scripts/lib/conflict-detection.sh`

Functions:
- `check_merge_conflicts()`: Detect conflicts between branches
- `analyze_conflicts()`: Generate detailed conflict analysis
- `generate_conflict_guidance()`: Create markdown guidance
- `check_branch_behind()`: Determine if branch is behind base
- `check_base_branch_reachable()`: Validate base branch access
- `run_preflight_checks()`: Execute all pre-flight checks
- `post_conflict_comment()`: Post guidance to PR
- `add_conflict_label()`: Add merge-conflicts label
- `remove_conflict_label()`: Remove label when resolved
- `handle_conflict_workflow()`: Complete conflict handling workflow

#### 2. Integration Points

**ai-autofix.sh**:
- Sources conflict-detection.sh library
- Calls `handle_conflict_workflow()` before applying fixes
- Supports `--skip-conflict-check` flag
- Supports `--base-branch` option

**ai-autofix.yml**:
- Dedicated "Pre-flight conflict detection" step
- Conditional execution based on conflict status
- Posts informative comments on conflict detection
- Handles conflict failures gracefully

### Flow Diagram

```
PR Auto-Fix Triggered
         |
         v
  Checkout PR Branch
         |
         v
Pre-Flight Conflict Check
         |
    /----+----\
   /           \
Conflicts    No Conflicts
   |             |
   v             v
Analyze      Run Auto-Fix
   |             |
   v             v
Post Comment  Apply Fixes
   |             |
   v             v
Add Label    Commit & Push
   |             |
   v             v
Exit 1       Success
```

## Testing

A comprehensive test suite is provided:

```bash
# Run all conflict detection tests
./tests/test-conflict-detection.sh

# Tests include:
# - Clean merge (no conflicts)
# - Conflicting changes detection
# - Branch behind/up-to-date checks
# - Conflict analysis JSON validation
# - Guidance generation
# - Pre-flight checks
# - Multiple conflicting files
# - Integration tests
```

### Test Coverage

- Clean merge scenarios
- Single file conflicts
- Multiple file conflicts
- Branch status detection
- JSON structure validation
- Markdown formatting
- Integration with ai-autofix.sh
- Workflow integration
- Edge cases (empty repos, unreachable branches)

## Best Practices

### For Users

1. **Keep PRs Updated**: Regularly merge or rebase with base branch
2. **Small PRs**: Smaller PRs have fewer conflicts
3. **Coordinate Changes**: Communicate with team about overlapping work
4. **Use Guidance**: Follow the posted resolution steps
5. **Test After Resolution**: Re-run tests after resolving conflicts

### For Maintainers

1. **Monitor Labels**: Watch for `merge-conflicts` label
2. **Review Complex Conflicts**: Some conflicts need human review
3. **Update Base Branch**: Keep base branch stable
4. **Configure Appropriately**: Set correct BASE_BRANCH for your workflow
5. **Test Detection**: Periodically verify conflict detection is working

## Troubleshooting

### Conflict Detection Not Running

**Symptom**: Pre-flight checks are skipped

**Solutions**:
- Ensure PR number is provided (`--pr` flag)
- Check that `--skip-conflict-check` is not set
- Verify you're in a git repository
- Check git is available in PATH

### False Positives

**Symptom**: Conflicts detected when none exist

**Solutions**:
- Ensure origin remote is properly configured
- Verify base branch is up-to-date
- Check for stale refs: `git fetch --prune`
- Review merge-tree output manually

### Missing PR Comments

**Symptom**: Conflicts detected but no comment posted

**Solutions**:
- Verify `GITHUB_TOKEN` is set and valid
- Check `gh` CLI is installed and authenticated
- Ensure workflow has `pull-requests: write` permission
- Check for API rate limiting

### Label Not Applied

**Symptom**: Conflict comment posted but label missing

**Solutions**:
- Create `merge-conflicts` label in repository
- Ensure label name matches configuration
- Verify token has repo write permissions
- Check workflow permissions

## Performance

### Metrics

- **Detection Time**: < 5 seconds for typical PRs
- **Analysis Time**: < 2 seconds per conflicting file
- **Comment Generation**: < 1 second
- **Total Overhead**: 5-10 seconds per auto-fix run

### Optimization

The system is optimized for:
- Minimal git operations (fetch once, simulate merge)
- Efficient conflict analysis (parallel file processing)
- Cached merge-base calculations
- Smart label management (only when needed)

## Security Considerations

1. **No Working Tree Modification**: Uses merge-tree simulation
2. **Read-Only Operations**: Detection doesn't modify repository
3. **Token Scope**: Only requires read access for detection
4. **Safe for Forks**: Works with fork PRs (comment only)
5. **No Secret Exposure**: Conflict info doesn't leak sensitive data

## Future Enhancements

Potential improvements:

1. **Auto-Resolution**: Attempt to auto-resolve simple conflicts
2. **Conflict Prediction**: Warn before conflicts occur
3. **Smart Retry**: Auto-retry after conflict resolution
4. **Conflict History**: Track conflict patterns
5. **Custom Strategies**: Per-file conflict resolution strategies
6. **Integration Tests**: E2E tests with real GitHub API
7. **Metrics Dashboard**: Track conflict detection effectiveness

## Contributing

To contribute to conflict detection:

1. Test your changes with test suite
2. Add new tests for new functionality
3. Update documentation
4. Follow existing code style
5. Ensure backward compatibility

## License

Part of the GitHub Actions Self-Hosted Runner System.
See main LICENSE file for details.
