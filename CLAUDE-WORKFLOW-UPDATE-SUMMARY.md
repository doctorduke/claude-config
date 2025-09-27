# Claude GitHub Workflow Update Summary

## Changes Made

### Updated Files
1. `.github/workflows/claude.yml` - Main Claude bot workflow
2. `.github/workflows/claude-code-review.yml` - Automated PR review workflow

## Key Improvements

### 1. Conversation Context Collection
Added a new step `Get conversation context` that uses `actions/github-script@v7` to:
- Fetch all previous comments on issues and PRs
- Retrieve PR/issue descriptions and metadata
- Sort and format conversation history chronologically
- Handle different event types (issue_comment, pull_request_review_comment, pull_request_review, issues)

### 2. Context-Aware Prompting
Modified the Claude prompt to include:
- Full conversation history with timestamps and authors
- Clear separation between previous comments and current request
- Instructions to avoid repeating previous analyses
- Guidelines to acknowledge and build upon previous discussions

### 3. Event-Specific Context Handling

#### For Issue Comments:
- Fetches original issue body and title
- Retrieves all previous comments
- Excludes the current comment from history

#### For Pull Request Comments:
- Fetches PR description, title, and statistics
- Retrieves both review comments and issue comments
- Combines and sorts all comments chronologically
- Includes change statistics (additions/deletions/files)

#### For Pull Request Reviews:
- Fetches PR details and all previous reviews
- Filters and displays previous review states
- Provides context about code changes

### 4. Error Handling
- Wrapped context fetching in try-catch blocks
- Provides fallback empty context on errors
- Logs errors to console for debugging

## Technical Implementation

### JavaScript Context Collection
```javascript
// Key features:
- Uses GitHub REST API via actions/github-script
- Fetches up to 100 comments per request
- Formats timestamps in readable format
- Filters out current comment to avoid self-reference
- Combines multiple comment types for PRs
```

### Prompt Engineering
The updated prompt includes:
1. **Conversation History Section**: Full context of previous discussions
2. **Current Request Section**: Clearly marked new request
3. **Instructions**: Explicit guidance to avoid repetition
4. **Event Details**: Original event data for reference

## Benefits

1. **No More Repetition**: Claude will understand what has already been discussed
2. **Contextual Responses**: Responses will build upon previous conversations
3. **Better Follow-ups**: Claude can answer follow-up questions directly
4. **Acknowledgment**: Claude will reference previous comments when relevant
5. **Efficient Reviews**: Automated reviews won't repeat the same points

## Testing Recommendations

1. Test with a PR that has multiple comments
2. Verify Claude acknowledges previous discussions
3. Check that follow-up questions get direct answers
4. Ensure error handling works with API failures
5. Monitor performance with large comment threads

## Deployment

The workflows are ready to deploy. No additional secrets or configuration needed beyond:
- `CLAUDE_CODE_OAUTH_TOKEN` (already configured)
- `GITHUB_TOKEN` (automatically provided by GitHub)

## Notes

- The context collection respects GitHub API rate limits
- Maximum 100 comments are fetched (can be increased if needed)
- Bot comments are specially filtered in the code review workflow
- Timestamps are formatted for readability