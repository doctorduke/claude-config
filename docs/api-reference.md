# GitHub API Reference for Self-Hosted Runners

## GitHub REST API

### PR Reviews API

**Create PR Review**
```bash
POST /repos/{owner}/{repo}/pulls/{pull_number}/reviews
Authorization: Bearer $GITHUB_TOKEN

{
  "event": "APPROVE" | "REQUEST_CHANGES" | "COMMENT",
  "body": "Review summary",
  "comments": [{"path": "file.js", "line": 42, "body": "Line comment"}]
}
```

### Issue Comments API

**Create Comment**
```bash
POST /repos/{owner}/{repo}/issues/{issue_number}/comments
{
  "body": "Comment with @mentions"
}
```

### Rate Limits

- REST API: 5,000 req/hr
- GITHUB_TOKEN: Same as account limits
- PAT: Based on token owner

## GitHub CLI

```bash
gh pr review 123 --approve
gh pr comment 123 --body "text"
gh issue comment 456 --body "text"
```

## References

- [REST API Docs](https://docs.github.com/en/rest)
- [GraphQL API](https://docs.github.com/en/graphql)
- [Runner API](https://docs.github.com/en/rest/actions/self-hosted-runners)
