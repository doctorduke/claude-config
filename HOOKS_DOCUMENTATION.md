# Claude Code Intelligent Hooks Documentation

## Overview

The Claude Code Hooks system provides intelligent enhancements to improve developer experience by detecting patterns and suggesting optimizations. The primary features include Task parallelization detection and documentation best practices enforcement.

## Features

### 1. Task Parallelization Detection

The system monitors Task tool invocations and intelligently suggests when multiple tasks could be executed in parallel for better performance.

#### How it Works

- **Detection Window**: Monitors Task calls within a 2-second window
- **Smart Analysis**: Distinguishes between truly independent tasks and intentionally sequential ones
- **Cooldown Period**: 5-minute cooldown between suggestions to avoid spam
- **Dependency Recognition**: Automatically detects when tasks have dependencies using pattern matching

#### Dependency Patterns

The system recognizes these patterns as indicators of intentional sequential execution:
- Keywords: `wait`, `depend`, `after`, `then`, `complete`, `finish`
- Result-based: `result`, `output`, `response`, `return`
- Explicit ordering: `sequential`, `order`, `step`

#### Example Scenarios

**Parallel-Friendly Tasks** (will trigger suggestion):
```
Task: "Analyze code quality metrics"
Task: "Check security vulnerabilities"
Task: "Generate performance report"
```

**Sequential Dependencies** (won't trigger suggestion):
```
Task: "Build the project"
Task: "After build completes, run tests"
Task: "Generate report based on test results"
```

### 2. Documentation Enforcement

Reminds developers to only create documentation files when explicitly requested by users.

- Monitors `Write` tool invocations
- Detects `.md` files and README creation
- Provides gentle reminders with 1-minute cooldown

## Configuration

The hooks system is configured in `.claude/hooks.mjs` with these settings:

```javascript
{
  taskParallelization: {
    enabled: true,
    windowMs: 2000,        // 2-second detection window
    cooldownMs: 300000     // 5-minute reminder cooldown
  },
  documentationEnforcement: {
    enabled: true,
    cooldownMs: 60000      // 1-minute reminder cooldown
  }
}
```

## Hook Functions

### `beforeToolInvocation(tool, params)`

Intercepts tool calls before execution to provide suggestions:
- Tracks Task tool usage patterns
- Analyzes parallelization opportunities
- Checks documentation file creation
- Returns non-blocking suggestions

### `afterToolInvocation(tool, params, result)`

Post-processes tool results for learning and optimization:
- Tracks successful Task completions
- Improves future pattern recognition

### `onMessage(message)`

Analyzes message patterns:
- Resets task tracking on new contexts
- Detects start of new workflows

### `onError(error, context)`

Provides helpful guidance for parallel execution errors.

## Benefits

1. **Performance Improvement**: Reduces execution time by suggesting parallel task execution
2. **Educational**: Teaches developers about Claude Code's parallel capabilities
3. **Non-Intrusive**: Suggestions are informative, not blocking
4. **Smart Detection**: Avoids false positives with dependency pattern recognition
5. **Best Practices**: Encourages proper documentation practices

## Testing

Run the test suite to validate hook functionality:

```bash
cd .claude
node test-hooks.mjs
```

The test suite covers:
1. Sequential task detection
2. Intentionally sequential task recognition
3. Cooldown behavior
4. Documentation warnings
5. Mixed tool invocations

## Implementation Details

### State Management

The system maintains lightweight state for:
- Recent task invocations (last 10 or within 5 seconds)
- Last reminder timestamps
- Suppressed file types

### Performance Considerations

- Minimal memory footprint
- O(n) complexity for pattern matching where n is number of recent tasks
- Automatic cleanup of old task records
- Non-blocking execution

## Future Enhancements

Potential improvements for consideration:
- Machine learning for better dependency detection
- Customizable detection windows
- User preference persistence
- Performance metrics tracking
- Integration with Claude Code analytics

## Troubleshooting

If suggestions aren't appearing:
1. Check cooldown hasn't been triggered (5 minutes for tasks, 1 minute for docs)
2. Verify tasks are within 2-second window
3. Ensure tasks don't contain dependency keywords
4. Confirm hooks.mjs is properly loaded

## Version History

- **v1.0.0**: Initial release with task parallelization and documentation enforcement