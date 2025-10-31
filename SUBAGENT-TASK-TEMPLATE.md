# Subagent Task Construction Guide

## 1. Task Tool Structure

A task is defined using a structured JSON/TypeScript interface:

```typescript
interface SubagentTask {
  description: string   // Concise 3-5 word task summary
  subagent_type: string // Specific agent type from available list
  prompt: string        // Detailed task instructions
}
```

## 2. Prompt Template Pattern

The prompt should follow a consistent, comprehensive structure:

```markdown
[Context about Current State]
Provide background information, current project status, and relevant details

[Specific Problem to Solve]
Clearly articulate the specific challenge or objective

Required Actions:
1. [Specific, actionable first step]
2. [Specific, actionable second step]
3. [Continue with additional steps as needed]

Expected Output:
- [Precise output expectation 1]
- [Precise output expectation 2]
- Include file paths, specific formats, or structural requirements

Constraints:
- [Constraint 1: Technical or process limitation]
- [Constraint 2: Scope or implementation restriction]
- Emphasize any critical boundaries or rules
```

## 3. Best Practices

### Crafting Effective Tasks

- **Context**: Always provide comprehensive context
- **File Paths**: Use absolute, fully-qualified file paths
- **Current State**: Include current project or file state
- **Specificity**: Be extremely precise about expectations
- **Output Format**: Clearly define the expected output structure
- **Constraints**: Highlight any critical limitations or rules

### Example Task Prompt

```markdown
Context:
- Current project is a monorepo with shared TypeScript configurations
- Working on improving type safety and developer experience

Problem:
Refactor the shared TypeScript configuration to enforce stricter type checking across all packages

Required Actions:
1. Review current tsconfig.json in shared/config
2. Update configuration to enable stricter type checking flags
3. Ensure compatibility with existing packages

Expected Output:
- Updated /shared/config/tsconfig.json
- List of added/modified TypeScript compiler options
- Brief explanation of how stricter typing improves type safety

Constraints:
- Do not break existing package builds
- Maintain compatibility with current TypeScript version
- Provide migration guidance for downstream packages
```

## 4. Parallel Execution Strategy

### Principles
- Multiple tasks can be executed simultaneously
- Tasks should be independent and non-blocking
- Use when working on separate, unrelated improvements

### Example of Parallel Tasks
```json
[
  {
    "description": "Update TypeScript Config",
    "subagent_type": "Reference Builder",
    "prompt": "..."
  },
  {
    "description": "Refactor Linting Rules",
    "subagent_type": "Code Quality Agent",
    "prompt": "..."
  }
]
```

## 5. Available Subagent Types

### Reference Builder
- Specializes in documentation and technical references
- Creates comprehensive, structured technical documentation
- Focuses on clarity, precision, and completeness

### Code Quality Agent
- Improves code quality, linting, and static analysis
- Refactors code for better maintainability
- Ensures adherence to best practices and design patterns

### Architecture Advisor
- Designs system and application architectures
- Provides high-level structural recommendations
- Focuses on scalability, performance, and modularity

### Performance Optimizer
- Identifies and resolves performance bottlenecks
- Conducts performance analysis and optimization
- Provides benchmarking and improvement strategies

### Security Analyst
- Reviews code for potential security vulnerabilities
- Recommends security best practices
- Conducts threat modeling and risk assessment

### Integration Specialist
- Manages cross-package and cross-platform integrations
- Ensures smooth data and interface interactions
- Designs robust integration patterns

## 6. Task Lifecycle

1. **Task Submission**: Provide a well-structured task
2. **Agent Selection**: Matched to the most appropriate subagent
3. **Execution**: Agent processes the task
4. **Validation**: Results checked against expected output
5. **Iteration**: Refinement if needed

## Notes

- Tasks are treated as atomic, isolated units of work
- Maximize task independence and minimize side effects
- Provide clear, actionable, and comprehensive instructions
