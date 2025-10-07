# Parallel Task Execution Examples

## Sequential Execution (Slower)

When you invoke Task agents one after another:

```
// First message
"Use Task to analyze the authentication module"

// Second message
"Use Task to review the database schema"

// Third message
"Use Task to check API endpoints"
```

This results in sequential execution: Task 1 → Task 2 → Task 3

## Parallel Execution (Faster)

Invoke multiple Task agents in the same message:

```
// Single message with multiple Task invocations
"Please perform the following analyses:
1. Use Task to analyze the authentication module
2. Use Task to review the database schema
3. Use Task to check API endpoints"
```

Or use natural language that implies parallel work:

```
"Simultaneously:
- Use Task to analyze authentication security
- Use Task to audit database performance
- Use Task to validate API contracts"
```

This results in parallel execution: Task 1, Task 2, Task 3 (all at once)

## Performance Benefits

- **Sequential**: Total time = Task1 + Task2 + Task3
- **Parallel**: Total time = max(Task1, Task2, Task3)

For example, if each task takes 3 seconds:
- Sequential: 9 seconds total
- Parallel: 3 seconds total (3x faster!)

## When to Use Sequential

Keep tasks sequential when they depend on each other:

```
"First, use Task to compile the TypeScript code.
After compilation completes, use Task to run the test suite.
Based on test results, use Task to generate a coverage report."
```

The hook system is smart enough to detect these dependencies and won't suggest parallelization.

## Best Practices

1. **Batch Independent Tasks**: Group unrelated analyses together
2. **Preserve Dependencies**: Keep dependent tasks sequential
3. **Clear Instructions**: Use clear language to indicate parallel intent
4. **Monitor Performance**: The hooks will guide you toward optimal patterns

## Quick Reference

### Parallel-Friendly Keywords
- "simultaneously"
- "in parallel"
- "at the same time"
- "concurrently"

### Sequential Keywords (Dependencies)
- "after"
- "then"
- "based on"
- "using the results"
- "once complete"
