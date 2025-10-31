# Mask Secrets Action

## Purpose

This composite action provides centralized secret masking for GitHub Actions workflows to prevent credential exposure in logs.

## Security Context

- **OWASP Top 10**: A09:2021 - Security Logging and Monitoring Failures
- **CWE-532**: Insertion of Sensitive Information into Log File
- **Defense in Depth**: Implements multiple layers of protection

## Usage

```yaml
- name: Mask all secrets
  uses: ./.github/actions/mask-secrets
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    ai_api_key: ${{ secrets.AI_API_KEY }}
    gh_pat: ${{ secrets.GH_PAT }}
    custom_secrets: ${{ secrets.CUSTOM_SECRET1 }},${{ secrets.CUSTOM_SECRET2 }}
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `github_token` | GitHub token to mask | No | Empty |
| `ai_api_key` | AI API key to mask | No | Empty |
| `gh_pat` | GitHub Personal Access Token to mask | No | Empty |
| `custom_secrets` | Comma-separated list of additional secrets | No | Empty |

## Best Practices

1. **Always mask at job start**: Call this action as the first step in any job that uses secrets
2. **Mask before use**: Ensure masking happens before any step that might log secrets
3. **Include all secrets**: Add any custom secrets used in your workflow
4. **Avoid debug mode**: The action automatically disables debug flags that might expose secrets

## Security Features

- Masks all provided secrets using GitHub's `::add-mask::` directive
- Disables command echoing (`set +x`)
- Sets `ACTIONS_STEP_DEBUG=false` to prevent debug logging
- Sets `ACTIONS_RUNNER_DEBUG=false` to prevent runner debug output
- Groups output for clean logs

## Example Integration

```yaml
jobs:
  secure-job:
    runs-on: ubuntu-latest
    steps:
      # CRITICAL: Mask secrets FIRST
      - name: Mask secrets
        uses: ./.github/actions/mask-secrets
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          ai_api_key: ${{ secrets.AI_API_KEY }}

      # Now safe to use secrets
      - name: Use secrets safely
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          # Token is masked in logs
          echo "Token value: $GITHUB_TOKEN"  # Shows as ***
```

## Testing

Masked values will appear as `***` in GitHub Actions logs. Test by:
1. Running a workflow with this action
2. Attempting to echo a secret value
3. Verifying it shows as `***` in logs

## Compliance

- SOC 2 Type II: Confidentiality controls
- ISO 27001: A.12.4.1 Event logging
- PCI DSS: Requirement 10.3.4 - Mask sensitive data