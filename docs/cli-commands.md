# GitHub CLI Commands Reference

## PR Review Commands

```bash
# Approve
gh pr review 123 --approve --body "LGTM"

# Request changes
gh pr review 123 --request-changes --body "Issues found"

# Comment
gh pr comment 123 --body "Suggestion"
```

## Issue Commands

```bash
gh issue comment 456 --body "Working on this"
gh issue list --label bug
```

## Workflow Commands

```bash
gh run list --workflow=pr-review.yml
gh run view 1234567890
gh run watch 1234567890
```

## References

- [GitHub CLI Manual](https://cli.github.com/manual/)
