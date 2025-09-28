# Prompts System — BRIEF

## Purpose & Boundary
Centralized prompt management system for the umemee-v0 monorepo, enabling reuse across workflows, CI/CD, and development tools. Manages YAML-based prompt templates with variable substitution.

## Interface Contract (Inputs → Outputs)
- **Inputs**: Prompt name, template variables, YAML definitions
- **Outputs**: Parsed prompt strings, rendered templates, validated prompts
- **Acceptance**:
  - GIVEN prompt name WHEN loaded THEN returns template
  - GIVEN template with variables WHEN parsed THEN substitutes values

## Structure
```
shared/prompts/
├── BRIEF.md           # This file
├── template.yaml      # Template for creating new prompts
├── index.js          # Loader and parser for prompts
└── *.yaml            # Individual prompt definitions
```

## Usage

### In Node.js/JavaScript
```javascript
const { loadPrompt, parsePrompt } = require('@umemee/prompts');

// Load a specific prompt
const prReviewPrompt = await loadPrompt('pr-review');

// Parse with variables
const rendered = parsePrompt(prReviewPrompt, {
  prNumber: '123',
  author: 'doctorduke'
});
```

### In GitHub Actions
```yaml
- name: Load prompt
  run: |
    PROMPT=$(node -e "require('@umemee/prompts').loadPrompt('pr-review').then(p => console.log(p.body))")
    echo "PROMPT=$PROMPT" >> $GITHUB_ENV
```

## Available Prompts

| Prompt | Description | Use Case |
|--------|-------------|----------|
| `pr-review` | Pull request review instructions | GitHub Actions Claude bot |
| `context-aware-response` | Context-aware conversation prompts | Claude conversations |
| `code-fix` | CI failure fixing instructions | Automated fixes |
| `brief-generator` | BRIEF.md generation template | Documentation creation |

## Dependencies & Integration Points
- Upstream: YAML files, Node.js runtime
- Downstream: GitHub Actions, CI/CD, development tools

## Work State (Planned / Doing / Done)
- **Done**: Basic prompt loading and parsing system

## Spec Snapshot (2025-09-27)
- Features: YAML prompts, variable substitution, validation
- Tech: Node.js, YAML parsing

## Decisions & Rationale
- 2025-09-27 — YAML format for human readability

## Local Reference Index
- Prompt files: pr-review.yaml, code-fix.yaml, context-aware-response.yaml, brief-generator.yaml

## Answer Pack (YAML)
kind: answerpack
module: shared/prompts/
intent: "Centralized prompt management for AI integrations"

## Creating New Prompts

1. Copy `template.yaml` to new file (e.g., `my-prompt.yaml`)
2. Fill in prompt body and metadata
3. Define any variables with defaults
4. Test with `index.js` loader

## Format Specification

Prompts use YAML with front matter separation:
- **Body**: Main prompt content (top section)
- **Metadata**: YAML front matter (after `---`)
- **Variables**: Placeholder substitutions in format `{VAR_NAME}`

## Best Practices

1. **Keep prompts focused**: Single responsibility per prompt
2. **Use clear variables**: Descriptive names with defaults
3. **Document usage**: Include examples in description
4. **Version control**: Track changes to prompts
5. **Test prompts**: Validate before using in production