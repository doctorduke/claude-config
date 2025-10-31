# Branch Protection Bypass with Automatic Fallback

**Task #12 Enhancement** - Comprehensive branch protection handling with 4 automatic fallback strategies

## Overview

This enhancement improves the AI Auto-Fix workflow to automatically detect branch protection settings and select the optimal push strategy. It gracefully handles protected branches by creating pull requests instead of failing.

## The 4 Fallback Strategies

### Strategy 1: Direct Push (Unprotected Branches)

**When Used:**
- Branch is not protected
- No branch protection rules exist

**Behavior:**
- Commits are pushed directly to the PR branch
- Fastest execution (no PR overhead)
- Immediate application of fixes

**Requirements:**
- Standard GITHUB_TOKEN permissions
- Unprotected target branch

**Example:**
```yaml
Strategy: Direct Push
Branch Protection: None
Token: GITHUB_TOKEN
Result: Direct push to branch
```

### Strategy 2: PR with Auto-Merge (Full Automation)

**When Used:**
- Branch is protected
- GH_PAT available with `repo` AND `workflow` scopes
- No admin-only push restrictions

**Behavior:**
- Creates a PR from fix branch to protected branch
- Automatically enables auto-merge
- PR merges automatically when checks pass

**Requirements:**
- GH_PAT secret with `repo` and `workflow` scopes
- Branch protection allows auto-merge
- No admin-only restrictions

**Example:**
```yaml
Strategy: PR with Auto-Merge
Branch Protection: Enabled
Token: GH_PAT (repo + workflow scopes)
Result: PR created with auto-merge enabled
```

**Setup:**
```bash
# Create PAT with required scopes
1. Go to GitHub Settings > Developer settings > Personal access tokens
2. Click "Generate new token (classic)"
   NOTE: Classic tokens are required because fine-grained tokens do not support
   bypassing branch protection rules, even with admin permissions. This is a
   GitHub API limitation as of 2024. Classic tokens with proper scopes can
   leverage the bot account's permissions to enable auto-merge on PRs.
3. Select scopes:
   - repo (full control)
   - workflow (update workflows)
4. Add as GH_PAT secret in repository
```

### Strategy 3: PR without Auto-Merge (Manual Review Required)

**When Used:**
- Branch is protected
- GH_PAT available with `repo` scope only (no `workflow` scope)
- OR: Admin-only push restrictions exist

**Behavior:**
- Creates a PR from fix branch to protected branch
- Manual review and merge required
- Maintains security while enabling automation

**Requirements:**
- GH_PAT secret with `repo` scope
- Manual approval required

**Example:**
```yaml
Strategy: PR without Auto-Merge
Branch Protection: Enabled (requires review)
Token: GH_PAT (repo scope only)
Result: PR created, manual merge needed
```

### Strategy 4: PR with Limited Permissions (GITHUB_TOKEN Fallback)

**When Used:**
- Branch is protected
- No GH_PAT configured
- Only GITHUB_TOKEN available

**Behavior:**
- Creates a PR from fix branch to protected branch
- Limited permissions (may fail on some repos)
- Manual review and merge required
- Best-effort fallback

**Requirements:**
- Standard GITHUB_TOKEN
- May have limitations based on repo settings

**Example:**
```yaml
Strategy: PR with Limited Permissions
Branch Protection: Enabled
Token: GITHUB_TOKEN (limited)
Result: PR created (best effort)
```

## Branch Protection Detection

The workflow performs comprehensive branch protection analysis:

### Detection Checks

1. **Branch Protection Status**
   ```bash
   gh api repos/{owner}/{repo}/branches/{branch}/protection
   ```

2. **Required Pull Request Reviews**
   - Number of required approvals
   - Dismiss stale reviews setting
   - Code owner reviews requirement

3. **Required Status Checks**
   - List of required checks
   - Strict mode setting

4. **Push Restrictions**
   - Admin-only push rules
   - User/team restrictions

5. **Additional Settings**
   - Force push allowance
   - Delete protection

### Protection Details Captured

```json
{
  "is_protected": true,
  "requires_review": true,
  "review_count": 1,
  "requires_status_checks": true,
  "status_checks": "ci/test,ci/lint",
  "requires_admin": false
}
```

## Token Permission Validation

The workflow validates token permissions before execution:

### GH_PAT Validation

```bash
# Check token scopes
gh api user -i | grep "x-oauth-scopes:"

# Expected scopes:
# - repo: Full repository access
# - workflow: Workflow management (optional, enables auto-merge)
```

### Permission Matrix

| Token Type | Repo Scope | Workflow Scope | Strategy |
|------------|------------|----------------|----------|
| GITHUB_TOKEN | Yes | No | Strategy 1 (no protection) |
| GH_PAT | Yes | Yes | Strategy 2 (auto-merge) |
| GH_PAT | Yes | No | Strategy 3 (manual merge) |
| GITHUB_TOKEN | Limited | No | Strategy 4 (fallback) |

**Note:** Strategy 1 uses GITHUB_TOKEN when no branch protection is enabled. GH_PAT provides elevated permissions for bypassing protection rules via PR workflows.

## Error Handling and Recovery

### Push Error Detection

The workflow detects and categorizes push failures:

1. **Protected Branch Error**
   ```
   Error: "protected branch hook declined"
   Action: Create PR instead (fallback)
   ```

2. **Permission Denied**
   ```
   Error: "permission denied"
   Action: Request admin assistance
   Guidance: Add GH_PAT or update permissions
   ```

3. **Non-Fast-Forward**
   ```
   Error: "non-fast-forward"
   Action: Suggest rebase/update
   ```

4. **Unknown Error**
   ```
   Error: Any other error
   Action: Log error, request review
   ```

### Automatic Fallback

If direct push fails with protection error:

```yaml
1. Detect failure reason: "protected branch"
2. Create fix branch: autofix/{branch}-{sha}
3. Push fix branch to remote
4. Create PR with detailed status
5. Enable auto-merge if possible
6. Post comment with next steps
```

## Status Reporting

### PR Comments

The workflow posts detailed status comments:

#### Direct Push Success
```markdown
## Auto-Fix Applied

Successfully applied **5** automated fixes.

Strategy: **Direct Push**
Commit: `abc1234`
```

#### PR Created for Protected Branch
```markdown
## Auto-Fix Status

Created PR #456 with **5** fixes.

Strategy: **PR with Auto-Merge**
Protection: Branch is protected
Auto-merge: Enabled

### Protection Settings
- Requires Code Review: Yes (1 approvals)
- Requires Status Checks: Yes

Review and approve PR #456 to apply fixes.
```

### PR Body Details

```markdown
## Auto-Fix for PR #123

This PR contains **5** automated fixes for protected branch `main`.

### Strategy Used
**PR with Auto-Merge**

### Protection Settings
- Branch Protection: Enabled
- Requires Code Review: Yes
- Required Approvals: 1
- Requires Status Checks: Yes
- Has Admin Restrictions: No

### Token Permissions
- Token Type: PAT
- Has Repo Scope: Yes
- Has Workflow Scope: Yes

### Auto-Merge Status
Auto-merge enabled. PR will automatically merge when:
1. All required status checks pass
2. Required approvals are obtained
```

## Testing

### Running Tests

```bash
# Run all tests
./tests/test-protection-bypass-strategies.sh

# Tests performed:
# 1. Branch protection detection
# 2. Strategy selection logic
# 3. Push error detection
# 4. Token permission validation
# 5. PR creation (interactive)
```

### Test Scenarios

1. **Unprotected Branch** - Strategy 1
   - Create test branch
   - Make change
   - Verify direct push succeeds

2. **Protected Branch with Full PAT** - Strategy 2
   - Verify GH_PAT has workflow scope
   - Create PR with auto-merge
   - Verify auto-merge enabled

3. **Protected Branch with Limited PAT** - Strategy 3
   - Verify GH_PAT has repo scope only
   - Create PR without auto-merge
   - Verify manual merge required

4. **Protected Branch without PAT** - Strategy 4
   - Use GITHUB_TOKEN only
   - Create PR with limited permissions
   - Verify best-effort behavior

### Expected Results

```
Passed:  12
Failed:  0
Skipped: 2
Total:   14

All tests passed!
```

## Troubleshooting

### Common Issues

#### 1. Push Rejected - Protected Branch

**Symptom:**
```
Error: protected branch hook declined
```

**Solution:**
```bash
# Add GH_PAT secret with repo and workflow scopes
1. Create PAT: GitHub Settings > Developer settings
2. Select scopes: repo, workflow
3. Add as GH_PAT secret
4. Workflow will automatically create PR
```

#### 2. Auto-Merge Not Available

**Symptom:**
```
Warning: Could not enable auto-merge
```

**Solutions:**
- Add `workflow` scope to GH_PAT
- Check if branch allows auto-merge
- Verify no admin-only restrictions

#### 3. Insufficient Permissions

**Symptom:**
```
Error: permission denied
```

**Solutions:**
- Verify GH_PAT has `repo` scope
- Check token hasn't expired
- Ensure token user has write access
- Contact repository admin

#### 4. PR Creation Failed

**Symptom:**
```
Error: Failed to create PR
```

**Solutions:**
- Check network connectivity
- Verify GitHub API is accessible
- Check token permissions
- Review GitHub Actions logs

## Configuration

### Required Secrets

```yaml
# Minimal configuration
secrets:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}  # Provided by GitHub

# Recommended configuration
secrets:
  GH_PAT: ${{ secrets.GH_PAT }}  # Create this
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Workflow Configuration

```yaml
# Use GH_PAT as primary, GITHUB_TOKEN as fallback
token: ${{ secrets.GH_PAT || secrets.GITHUB_TOKEN }}

# Benefits:
# - Automatic strategy selection
# - Graceful degradation
# - Maximum flexibility
```

## Migration from Task #8

Task #8 provided basic PAT support. Task #12 enhances it with:

### Improvements Over Task #8

1. **Automatic Strategy Selection**
   - Was: Manual configuration required
   - Now: Automatic based on permissions

2. **Comprehensive Protection Detection**
   - Was: Simple protected/not protected check
   - Now: Full protection details analysis

3. **Permission Validation**
   - Was: No validation
   - Now: Token scope verification

4. **Error Detection and Recovery**
   - Was: Generic error messages
   - Now: Specific error categorization and guidance

5. **Status Reporting**
   - Was: Basic success/failure
   - Now: Detailed status with next steps

### Backward Compatibility

Task #12 is fully backward compatible with Task #8:
- Existing GH_PAT configurations work unchanged
- GITHUB_TOKEN fallback maintains compatibility
- No breaking changes to workflow interface

## Best Practices

### 1. Always Configure GH_PAT

For best results:
```bash
# Create PAT with maximum permissions
Scopes: repo + workflow

# Benefits:
- Full automation (Strategy 2)
- Auto-merge capability
- No manual intervention
```

### 2. Monitor Workflow Logs

Check logs for strategy used:
```
::notice::Strategy 2: PR with Auto-Merge (GH_PAT with workflow scope)
```

### 3. Review Protection Settings

Regularly audit branch protection:
```bash
gh api repos/{owner}/{repo}/branches/{branch}/protection
```

### 4. Test Before Production

Run test script to verify:
```bash
./tests/test-protection-bypass-strategies.sh
```

### 5. Document Custom Configurations

If using custom protection rules, document them:
```markdown
## Branch Protection

- main: Requires 2 reviews + status checks
- develop: Requires 1 review
- feature/*: No protection (direct push)
```

## Performance Impact

### Strategy Comparison

| Strategy | Execution Time | Automation | Manual Steps |
|----------|---------------|------------|--------------|
| Strategy 1 | ~10s | Full | 0 |
| Strategy 2 | ~30s | Full | 0 (after approval) |
| Strategy 3 | ~30s | Partial | 1 (merge) |
| Strategy 4 | ~30s | Partial | 1 (merge) |

### Optimization Tips

1. **Use Strategy 1 when possible**
   - Unprotect feature branches
   - Fastest execution

2. **Enable auto-merge for Strategy 2**
   - Configure GH_PAT with workflow scope
   - Reduces manual intervention

3. **Batch fixes**
   - Combine multiple fixes in one PR
   - Reduces workflow runs

## Security Considerations

### Token Security

1. **GH_PAT Protection**
   - Store as repository secret
   - Use environment-specific tokens
   - Rotate regularly (90 days)

2. **Scope Minimization**
   - Only add required scopes
   - Prefer repo-specific tokens over personal tokens

3. **Access Control**
   - Limit who can configure secrets
   - Audit token usage regularly

### Branch Protection

1. **Maintain Protection on Critical Branches**
   - Always protect main/master
   - Require reviews for production branches

2. **Status Checks**
   - Require CI/CD to pass
   - Don't allow bypassing checks

3. **Admin Restrictions**
   - Restrict who can push to protected branches
   - Use CODEOWNERS for critical files

## Summary

Task #12 provides enterprise-grade branch protection handling:

- **4 automatic fallback strategies** for any configuration
- **Comprehensive protection detection** with full details
- **Permission validation** before execution
- **Intelligent error handling** with specific guidance
- **Detailed status reporting** for transparency
- **Full backward compatibility** with Task #8
- **Extensive testing** with automated test suite

This enhancement ensures the AI Auto-Fix workflow works reliably in any repository configuration, from open-source projects to enterprise environments with strict protection rules.
