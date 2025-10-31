# Secret Masking - Quick Reference Guide

## For Workflow Authors

### Required: Add Masking to Every Job

**ALWAYS** add secret masking as the **FIRST STEP** in every job that uses secrets:

```yaml
jobs:
  your-job:
    runs-on: ubuntu-latest
    steps:
      # CRITICAL: Mask secrets FIRST
      - name: Mask sensitive values
        uses: ./.github/actions/mask-secrets
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          ai_api_key: ${{ secrets.AI_API_KEY }}
          # Add any custom secrets here
          custom_secrets: "${{ secrets.SECRET1 }},${{ secrets.SECRET2 }}"

      # Now safe to use secrets
      - name: Your step
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          # Token will show as *** in logs
```

## Common Mistakes to Avoid

### ❌ WRONG: No masking
```yaml
steps:
  - run: echo "${{ secrets.GITHUB_TOKEN }}"  # EXPOSED!
```

### ✅ CORRECT: Mask first
```yaml
steps:
  - uses: ./.github/actions/mask-secrets
    with:
      github_token: ${{ secrets.GITHUB_TOKEN }}
  - run: echo "$GITHUB_TOKEN"  # Shows as ***
```

### ❌ WRONG: Verbose mode with secrets
```yaml
- run: |
    set -x  # BAD: Echoes commands
    curl -H "Authorization: Bearer $TOKEN"
```

### ✅ CORRECT: Disable verbose in sensitive sections
```yaml
- run: |
    set +x  # Disable command echo
    curl -H "Authorization: Bearer $TOKEN"
```

### ❌ WRONG: Logging API responses
```yaml
- run: |
    RESPONSE=$(curl -H "Authorization: $TOKEN" ...)
    echo "$RESPONSE"  # Might contain token!
```

### ✅ CORRECT: Filter sensitive data
```yaml
- run: |
    RESPONSE=$(curl -H "Authorization: $TOKEN" ...)
    echo "$RESPONSE" | jq 'del(.token)'
```

## Testing Your Workflow

1. **Before committing**, test your workflow:
   ```bash
   gh workflow run your-workflow.yml
   ```

2. **Check the logs** for `***` instead of actual secrets

3. **Run the test workflow**:
   ```bash
   gh workflow run test-secret-masking.yml -f test_mode=with-masking
   ```

## Adding New Secrets

When adding a new secret to your workflow:

1. Add it to the masking step:
   ```yaml
   - uses: ./.github/actions/mask-secrets
     with:
       github_token: ${{ secrets.GITHUB_TOKEN }}
       ai_api_key: ${{ secrets.AI_API_KEY }}
       custom_secrets: ${{ secrets.YOUR_NEW_SECRET }}  # ADD HERE
   ```

2. Test the workflow to verify masking works

## Security Checklist

Before merging workflow changes:

- [ ] Secret masking is the FIRST step in each job
- [ ] All secrets used in the workflow are masked
- [ ] No `set -x` or debug flags with secrets
- [ ] API responses are filtered for sensitive data
- [ ] Tested workflow and verified `***` in logs
- [ ] No secrets in file paths or error messages

## Emergency: Secret Exposed

If you accidentally expose a secret:

1. **Immediately** rotate the secret in GitHub settings
2. Report to security team (do NOT create public issue)
3. Review recent workflow runs for exposure
4. Update the secret in GitHub secrets

## Help & Support

- **Documentation**: See `SECURITY-AUDIT.md` for detailed info
- **Testing**: Run `.github/workflows/test-secret-masking.yml`
- **Questions**: Contact security team
- **Issues**: Report security concerns privately

## References

- [GitHub Actions: Using secrets](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions)
- [Security hardening](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- OWASP A09:2021 - Security Logging and Monitoring Failures

---

**Last Updated**: 2025-10-23
**Maintained by**: Security Team