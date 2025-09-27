# Subagent Task Construction Guide

## 1. Task Tool Structure

```typescript
{
  description: string  // 3-5 word task summary
  subagent_type: string  // Agent from available list
  prompt: string  // Detailed instructions
}
```

## 2. Prompt Template Pattern

```markdown
[Context about current state]

[Specific problem to solve]

Required actions:
1. [Action 1]
2. [Action 2]

Expected output:
- [Output 1]
- [Output 2]

Constraints:
- [Constraint 1]
- [Constraint 2]
```

## 3. Best Practices

### Comprehensive Task Definition
- **Context**: Provide full background information
- **File Paths**: Always include absolute file paths
- **Current State**: Describe the existing situation
- **Problem Statement**: Clearly define the specific challenge
- **Action Items**: Break down tasks into specific, actionable steps

### Output Specification
- Specify expected output format precisely
- Include example outputs when possible
- Define success criteria clearly

### Constraints and Limitations
- Explicitly state any technical or business constraints
- Highlight potential risks or considerations
- Provide guidance on handling edge cases

## 4. Prompt Construction Checklist

### Required Elements
- [ ] Context and background information
- [ ] Specific problem or task
- [ ] Detailed action steps
- [ ] Expected output format
- [ ] Technical and business constraints
- [ ] Reference to related files or resources

### File Path Handling
- Use absolute paths
- Prefer existing file editing over new file creation
- Provide context for file modifications

## 5. Parallel Task Execution

### Multi-Task Invocation
- Tasks should be independent
- No implicit dependencies between tasks
- Separate tasks that can be executed concurrently

#### Example of Parallel Tasks
```json
[
  {
    "description": "Update configuration",
    "subagent_type": "reference_builder",
    "prompt": "..."
  },
  {
    "description": "Refactor utility function",
    "subagent_type": "code_architect",
    "prompt": "..."
  }
]
```

## 6. Available Subagent Specialties

### Reference Builder
- Technical documentation
- API specification
- Architectural documentation
- Configuration management

### Code Architect
- System design
- Code refactoring
- Performance optimization
- Architectural patterns

### UI Specialist
- Component design
- Cross-platform UI consistency
- Interaction patterns
- Responsive design

### Infrastructure Engineer
- DevOps tooling
- Build system configuration
- CI/CD pipeline design
- Development workflow optimization

### Security Analyst
- Code security review
- Vulnerability assessment
- Access control design
- Compliance checking

## 7. Error Handling and Fallback

### Task Failure Modes
- Provide clear error reporting
- Include debug information
- Suggest remediation steps
- Allow for task retry or manual intervention

## 8. Example Task Template

```markdown
Context:
- Current project: Umemee monorepo
- Existing configuration needs update

Problem:
Standardize and optimize the build configuration for cross-platform packages

Required Actions:
1. Review existing Turborepo configuration
2. Identify performance bottlenecks
3. Propose configuration improvements

Expected Output:
- Updated turbo.json with optimized pipeline
- Performance comparison report
- Recommendations for build system enhancement

Constraints:
- Maintain existing package structure
- Do not introduce breaking changes
- Minimize build time and complexity
```

## Conclusion

Effective subagent task construction requires clear communication, precise specification, and a structured approach to problem-solving.