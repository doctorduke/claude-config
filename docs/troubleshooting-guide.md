# Troubleshooting Guide

## Top 10 Common Issues

### 1. Runner Registration Fails
**Solution**: Generate new token, check network connectivity
```bash
./config.sh --url https://github.com/ORG --token NEW_TOKEN --replace
```

### 2. Permission Denied on PR Comment
**Solution**: Add explicit permissions
```yaml
permissions:
  pull-requests: write
  contents: read
```

### 3. Sparse Checkout Not Working
**Solution**: Check Git version >= 2.25
```yaml
- uses: actions/checkout@v4
  with:
    sparse-checkout: |
      src/
      tests/
```

### 4. Runner Not Picking Up Jobs
**Solution**: Verify labels match
```yaml
runs-on: [self-hosted, linux, ai-agent]
```

### 5. WSL Network Issues
**Solution**: Configure proxy
```bash
export https_proxy=http://proxy:8080
```

### 6. Cannot Push to Protected Branch
**Solution**: Use PAT instead of GITHUB_TOKEN
```yaml
- uses: actions/checkout@v4
  with:
    token: ${{ secrets.BOT_PAT }}
```

### 7. AI API Rate Limits
**Solution**: Add retry logic with backoff

### 8. Disk Space Exhausted
**Solution**: Clean old workspaces
```bash
find _work -maxdepth 2 -type d -mtime +7 -exec rm -rf {} +
```

### 9. Git Conflicts on Auto-Fix
**Solution**: Fetch latest before push
```bash
git fetch origin $BRANCH
git rebase origin/$BRANCH
```

### 10. Secret Not Available
**Solution**: Verify secret name matches exactly (case-sensitive)

## Debug Mode

```yaml
env:
  ACTIONS_STEP_DEBUG: true
  ACTIONS_RUNNER_DEBUG: true
```
