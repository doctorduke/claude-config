# GitHub Personal Access Token (PAT) Setup Guide

## Overview

The AI Auto-Fix workflow now supports GitHub Personal Access Tokens (PAT) for enhanced permissions, especially when working with protected branches. This guide explains how to create and configure a PAT for your repository.

## Why Use a PAT?

### Benefits
1. **Protected Branch Support**: Automatically create PRs when direct push is restricted
2. **Auto-Merge Capability**: Enable auto-merge on created PRs
3. **Enhanced Permissions**: Bypass certain restrictions while maintaining security
4. **Graceful Degradation**: Workflow falls back to GITHUB_TOKEN if PAT is not available

### Security Considerations
- PATs should have **minimal required permissions**
- Store PATs as **encrypted secrets** in GitHub
- **Rotate PATs regularly** (e.g., every 90 days)
- **Never commit PATs** to your repository

## Creating a Personal Access Token

### Step 1: Access Token Settings

1. Go to GitHub.com and sign in
2. Click your profile photo → **Settings**
3. In the left sidebar, click **Developer settings**
4. Click **Personal access tokens** → **Tokens (classic)**
   - Or use **Fine-grained tokens** for better security (recommended)

### Step 2: Generate New Token

#### Option A: Classic Token (Simpler)
1. Click **Generate new token** → **Generate new token (classic)**
2. Give your token a descriptive name: `AI-AutoFix-PAT`
3. Set expiration (recommend 90 days)
4. Select scopes:
   - ✅ `repo` (Full control of private repositories)
   - ✅ `workflow` (Update GitHub Actions workflows)
5. Click **Generate token**
6. **Copy the token immediately** (you won't see it again!)

#### Option B: Fine-grained Token (More Secure) - Recommended
1. Click **Generate new token** → **Generate new token (Fine-grained)**
2. Token name: `AI-AutoFix-PAT`
3. Expiration: 90 days (recommended)
4. Repository access: Select specific repositories
5. Permissions:
   - **Repository permissions:**
     - Contents: `Write`
     - Pull requests: `Write`
     - Actions: `Write` (if modifying workflows)
     - Metadata: `Read` (automatically selected)
   - **Account permissions:** None needed
6. Click **Generate token**
7. **Copy the token immediately**

## Adding PAT to Repository Secrets

### Step 1: Navigate to Repository Settings
1. Go to your repository on GitHub
2. Click **Settings** tab
3. In the left sidebar, click **Secrets and variables** → **Actions**

### Step 2: Create New Secret
1. Click **New repository secret**
2. Name: `GH_PAT`
3. Value: Paste your personal access token
4. Click **Add secret**

### Step 3: Verify Secret Creation
- You should see `GH_PAT` in the list of repository secrets
- The value will be hidden (shown as `***`)

## Workflow Configuration

The AI Auto-Fix workflow automatically detects and uses the PAT:

```yaml
env:
  GITHUB_TOKEN: ${{ secrets.GH_PAT || secrets.GITHUB_TOKEN }}
```

### How It Works

1. **Branch Protection Detection**:
   ```yaml
   - name: Check branch protection
     run: |
       if gh api "repos/${{ github.repository }}/branches/${BRANCH_NAME}/protection" &>/dev/null; then
         echo "protected=true" >> $GITHUB_OUTPUT
       else
         echo "protected=false" >> $GITHUB_OUTPUT
       fi
   ```

2. **Dual-Mode Operation**:
   - **Unprotected branches**: Direct push (works with GITHUB_TOKEN)
   - **Protected branches**: Creates PR (enhanced with GH_PAT)

3. **Auto-Merge** (requires PAT):
   ```yaml
   if [[ "${{ steps.check-protection.outputs.has_pat }}" == "true" ]]; then
     gh pr merge "$NEW_PR_NUM" --auto --merge
   fi
   ```

## Testing Your Setup

### Test Script
Run the included test script to verify both scenarios:

```bash
# Set environment variables
export TEST_REPO="owner/repo"
export GITHUB_TOKEN="your-github-token"
export GH_PAT="your-pat"  # Optional

# Run tests
./tests/test-autofix-protected-branches.sh
```

### Manual Testing

1. **Test Unprotected Branch**:
   ```bash
   # Create a PR to an unprotected branch
   # Add 'auto-fix' label or comment '/autofix'
   # Workflow should push directly
   ```

2. **Test Protected Branch**:
   ```bash
   # Create a PR to a protected branch (e.g., main)
   # Add 'auto-fix' label or comment '/autofix'
   # Workflow should create a new PR
   ```

## Permissions Reference

### Minimal Required Permissions

| Permission | Scope | Purpose |
|------------|-------|---------|
| `contents:write` | Repository | Push commits, create branches |
| `pull_requests:write` | Repository | Create and update PRs |
| `actions:read` | Repository | Read workflow runs |
| `metadata:read` | Repository | Read repository metadata |

### Optional Enhanced Permissions

| Permission | Scope | Purpose |
|------------|-------|---------|
| `administration:write` | Repository | Enable auto-merge |
| `checks:write` | Repository | Update check status |

## Security Best Practices

### Do's ✅
- Use fine-grained tokens when possible
- Set short expiration periods (30-90 days)
- Limit token scope to specific repositories
- Store tokens as encrypted secrets
- Rotate tokens regularly
- Audit token usage in GitHub Settings

### Don'ts ❌
- Never hardcode tokens in code
- Don't share tokens between projects
- Avoid tokens with org-wide permissions
- Don't use tokens in client-side code
- Never commit tokens to version control

## Troubleshooting

### Common Issues

1. **"Not Found" error when checking branch protection**
   - **Cause**: Insufficient permissions
   - **Fix**: Ensure PAT has `repo` scope

2. **Cannot create PR for protected branch**
   - **Cause**: Missing pull request permissions
   - **Fix**: Add `pull_requests:write` permission

3. **Auto-merge fails**
   - **Cause**: Branch protection rules or missing permissions
   - **Fix**: Ensure PAT has admin rights or adjust branch rules

4. **Token not recognized**
   - **Cause**: Secret name mismatch
   - **Fix**: Ensure secret is named exactly `GH_PAT`

### Debug Mode

Enable debug logging in the workflow:

```yaml
- name: Debug token detection
  run: |
    if [[ -n "${{ secrets.GH_PAT }}" ]]; then
      echo "::debug::PAT is configured"
    else
      echo "::debug::PAT is not configured, using GITHUB_TOKEN"
    fi
```

## Monitoring & Auditing

### Token Usage
1. Go to **Settings** → **Personal access tokens**
2. Click on your token name
3. View **Recent activity** to see usage

### Workflow Logs
- Check workflow run logs for token usage
- Look for notices about PAT vs GITHUB_TOKEN
- Monitor PR creation vs direct push patterns

## Rotation Schedule

### Recommended Timeline
- **Every 30 days**: Review token usage
- **Every 90 days**: Rotate tokens
- **Immediately**: If token is compromised

### Rotation Process
1. Create new token with same permissions
2. Update `GH_PAT` secret in repository
3. Verify workflow still functions
4. Revoke old token

## Support

### Resources
- [GitHub PAT Documentation](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Branch Protection Rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/defining-the-mergeability-of-pull-requests/about-protected-branches)

### Getting Help
- Check workflow logs for specific error messages
- Review this guide's troubleshooting section
- Open an issue in the repository
- Contact your GitHub administrator

---

**Last Updated**: October 2025
**Version**: 1.0.0