# Reverse Engineering Toolkit

**Version**: 1.0.0
**Status**: Complete
**Issue**: #60 - Week 1 Foundation Skill

## Quick Start

Understand undocumented systems through:
- Static code analysis (AST parsing, symbol extraction)
- Dynamic analysis (execution tracing, behavior observation)
- Dependency graph extraction
- Design pattern recognition
- Automated documentation generation

## Files

| File | Purpose | Lines |
|------|---------|-------|
| **SKILL.md** | Main navigation & quick reference | 308 |
| **KNOWLEDGE.md** | Theory, concepts, tools comparison | 420 |
| **PATTERNS.md** | 5 implementation patterns | 43 |
| **EXAMPLES.md** | Working code examples | 133 |
| **GOTCHAS.md** | Troubleshooting & debugging | 177 |
| **REFERENCE.md** | Tool commands & APIs | 175 |
| **INTEGRATION.md** | Agent integration guide | 166 |

**Total**: 1,422 lines

## 5 Core Patterns

1. **Static Code Analysis**: Understand structure without execution
2. **Dynamic Analysis & Tracing**: Observe runtime behavior
3. **Dependency Graph Extraction**: Map module relationships
4. **Design Pattern Recognition**: Identify architectural patterns
5. **Documentation Generation**: Auto-generate docs from analysis

## Primary Agent

**code-archaeologist**: Specializes in understanding legacy/undocumented systems

This skill provides the reverse engineering expertise, allowing the agent to focus on user interaction and workflow orchestration.

## Usage

```markdown
# In agent definition
skills: [reverse-engineering-toolkit]

# When analyzing codebase
1. Consult SKILL.md for approach
2. Follow relevant pattern from PATTERNS.md
3. Use examples from EXAMPLES.md
4. Check GOTCHAS.md if issues arise
5. Reference REFERENCE.md for tool details
```

## Requirements

- **allowed-tools**: Read, Write, Edit, Bash, Grep, Glob, WebFetch
- **Dependencies**: None (foundation skill)
- **Platform**: Cross-platform (Windows/Linux/Mac)

## Testing

```bash
# Run test suite
python tests/test_reverse_engineering.py

# Expected: All 10 tests pass
```

## Validation

- [x] SKILL.md < 500 lines (308 lines)
- [x] 6 file structure complete
- [x] 5 patterns documented
- [x] Working examples provided
- [x] All tests passing (10/10)
- [x] Cross-references valid
- [x] No time-sensitive content
- [x] Integration documented

## Next Steps

1. **Integration**: Refactor code-archaeologist agent to use this skill
2. **Expansion**: Add more language-specific examples
3. **Optimization**: Performance tuning for large codebases
4. **Community**: Gather feedback from usage

## Related Skills

- **codebase-onboarding-analyzer**: Uses this for rapid understanding
- **architecture-evaluation-framework**: Uses this to identify architecture
- **security-scanning-suite**: Uses this for security analysis
- **gap-analysis-framework**: Uses this to identify what exists

## References

- Issue #60: 7 New Skills Architecture
- Issue #59: 500-line skill best practice
- Implementation Sequence: Week 1 Foundation Skill

---

**Maintainer**: Issue #60 Implementation Team
**Last Updated**: 2025-10-27
