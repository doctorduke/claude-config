# Integration: AI Agent Tool Builder

Integration points with existing agents and skills in the repository.

## Agent Integration

### mcp-server-engineer

**Purpose**: Agent that creates complete MCP servers

**How it uses this skill**:
- Uses PATTERNS.md Pattern 1 & 2 for server templates
- References EXAMPLES.md for complete server implementations
- Applies KNOWLEDGE.md security principles
- Follows GOTCHAS.md to avoid common pitfalls

**Workflow**:
1. Agent receives requirement: "Create MCP server for X"
2. Invokes skill: `/skill ai-agent-tool-builder`
3. Reads PATTERNS.md to select FastMCP or TypeScript SDK
4. Follows pattern template to implement server
5. References EXAMPLES.md for similar implementations
6. Applies GOTCHAS.md security and error handling
7. Uses tests from PATTERNS.md Pattern 5 for validation

### mcp-tool-engineer

**Purpose**: Agent that builds individual tool implementations

**How it uses this skill**:
- Uses PATTERNS.md Pattern 2 (Function Calling Schema Design)
- References KNOWLEDGE.md for schema design principles
- Applies EXAMPLES.md tool composition patterns
- Follows REFERENCE.md for schema validation

**Workflow**:
1. Agent receives requirement: "Create tool for Y operation"
2. Invokes skill: `/skill ai-agent-tool-builder`
3. Designs JSON schema using KNOWLEDGE.md principles
4. Implements tool logic with error handling from GOTCHAS.md
5. Writes tests following PATTERNS.md Pattern 5
6. Validates schema using REFERENCE.md validators

### ai-engineer

**Purpose**: Generalist AI engineering agent

**How it uses this skill**:
- Consults KNOWLEDGE.md for MCP vs alternatives decision
- Uses PATTERNS.md for quick tool prototypes
- References EXAMPLES.md for end-to-end workflows
- Applies GOTCHAS.md for debugging production issues

**Use cases**:
- Adding new capabilities to existing agent systems
- Integrating external APIs as agent tools
- Debugging tool integration issues
- Evaluating tool architecture decisions

## Skill Integration

### context-engineering-framework

**Relationship**: Complementary

**Integration points**:
- AI Tool Builder creates tools that agents use
- Context Engineering manages context when using tools
- Context compression affects tool parameter design
- Tool responses should consider token budgets

**Example**:
```python
# Tool designed for context efficiency
@mcp.tool()
def analyze_code(file_path: str, detail_level: str = "summary") -> str:
    """
    Analyze code with configurable detail level.

    Uses context engineering principles:
    - detail_level="summary": < 200 tokens
    - detail_level="detailed": < 1000 tokens
    - detail_level="full": Complete analysis
    """
    if detail_level == "summary":
        return generate_summary(file_path)  # Compressed output
    elif detail_level == "detailed":
        return generate_detailed_analysis(file_path)
    else:
        return generate_full_analysis(file_path)
```

### agent-builder-framework

**Relationship**: Dependent (Agent Builder uses AI Tool Builder)

**Integration points**:
- Agent Builder defines which tools agent should use
- AI Tool Builder creates the actual tool implementations
- Agent capabilities determined by available tools
- Tool design influences agent architecture

**Workflow**:
1. Agent Builder designs agent capabilities
2. Identifies required tools (existing or new)
3. For new tools: uses AI Tool Builder skill
4. Registers tools with agent configuration
5. Tests agent with tool integration

### workflow-builder-framework

**Relationship**: Complementary

**Integration points**:
- Workflows orchestrate multiple tool calls
- Tools designed for composition work well in workflows
- Tool error handling critical for workflow reliability
- Tool performance affects workflow latency

**Example**:
```python
# Tools designed for workflow composition
@mcp.tool()
def fetch_data(source: str) -> str:
    """Step 1: Fetch data (returns JSON string)."""
    return json.dumps(fetch_from_source(source))

@mcp.tool()
def transform_data(data_json: str, operation: str) -> str:
    """Step 2: Transform data (accepts JSON string)."""
    data = json.loads(data_json)
    return json.dumps(transform(data, operation))

@mcp.tool()
def save_results(data_json: str, destination: str) -> str:
    """Step 3: Save results (accepts JSON string)."""
    data = json.loads(data_json)
    save(data, destination)
    return f"Saved to {destination}"

# Workflow orchestrates these tools:
# result = fetch_data("api.example.com")
# transformed = transform_data(result, "normalize")
# save_results(transformed, "output.json")
```

## Tool Ecosystem Design

### Tool Categories

**Query Tools** (read-only):
- Created using Pattern 1 (FastMCP) for simplicity
- Focus: Fast response, idempotent
- Examples: read_file, search_database, fetch_url

**Mutation Tools** (state-changing):
- Require confirmation patterns from GOTCHAS.md
- Focus: Safety, validation, error handling
- Examples: write_file, delete_resource, send_email

**Analysis Tools** (data processing):
- Use Pattern 4 (Tool Composition) for complex analysis
- Focus: Composability, structured outputs
- Examples: analyze_code, process_data, generate_report

**Integration Tools** (external services):
- Use Pattern 2 (TypeScript SDK) for production-grade implementation
- Focus: Error handling, rate limiting, authentication
- Examples: github_create_pr, slack_send_message, jira_create_ticket

### Tool Discovery

```python
# Tool that helps agents discover other tools
@mcp.tool()
def list_available_tools(category: str = "all") -> str:
    """
    List available tools by category.

    Integrates with agent-builder-framework to show
    which tools are available for agent use.
    """
    tools_by_category = {
        "query": ["read_file", "search_database", "fetch_url"],
        "mutation": ["write_file", "delete_file", "send_email"],
        "analysis": ["analyze_code", "process_data", "generate_report"],
        "integration": ["github_create_pr", "slack_send_message"]
    }

    if category == "all":
        return json.dumps(tools_by_category, indent=2)
    else:
        return json.dumps(tools_by_category.get(category, []))
```

## Repository Structure

```
.claude/skills/ai-agent-tool-builder/
├── SKILL.md              # Main entry point (344 lines)
├── KNOWLEDGE.md          # Theory and concepts (582 lines)
├── PATTERNS.md           # Implementation patterns (956 lines)
├── EXAMPLES.md           # Working code examples (1001 lines)
├── GOTCHAS.md            # Troubleshooting (707 lines)
├── REFERENCE.md          # API documentation (745 lines)
├── INTEGRATION.md        # This file (integration docs)
└── tests/
    └── test_ai_tool_builder.py  # Validation tests (432 lines)
```

## Usage Guidelines

### For Agents

**When to invoke this skill**:
- Need to create new MCP server
- Building custom tool for specific domain
- Wrapping external API for agent use
- Debugging tool integration issues
- Designing tool composition patterns

**How to use**:
1. Start with SKILL.md for overview and pattern selection
2. Read relevant detailed file (KNOWLEDGE, PATTERNS, EXAMPLES, etc.)
3. Implement tool following pattern template
4. Validate with tests from PATTERNS.md Pattern 5
5. Consult GOTCHAS.md if issues arise

### For Developers

**Before creating a new tool**:
1. Check if similar tool exists in repository
2. Review KNOWLEDGE.md for design principles
3. Choose appropriate pattern from PATTERNS.md
4. Follow security guidelines in GOTCHAS.md
5. Write tests before deploying

**For production deployment**:
1. Complete deployment checklist in GOTCHAS.md
2. Add monitoring and logging per REFERENCE.md
3. Document tool in agent configuration
4. Add to tool discovery registry
5. Create integration tests with actual agents

## Migration Path

### From Custom Agent Logic to Reusable Tools

**Before** (tool logic embedded in agent):
```python
# Inside agent definition
def agent_specific_github_action():
    """GitHub API call embedded in agent."""
    # 100 lines of GitHub API logic
    # Hard to reuse, test, or maintain
```

**After** (using AI Tool Builder skill):
```python
# Create MCP server with tool
@mcp.tool()
def github_create_issue(owner: str, repo: str, title: str) -> str:
    """Create GitHub issue (reusable tool)."""
    # Clean, tested, reusable implementation

# Agent simply uses the tool
result = call_tool("github_create_issue", {
    "owner": "myorg",
    "repo": "myrepo",
    "title": "Bug report"
})
```

**Benefits**:
- Tool reusable across multiple agents
- Easier to test and maintain
- Centralized error handling
- Better monitoring and logging

## Future Extensions

### Planned Enhancements

1. **Tool Registry**: Central catalog of all available tools
2. **Tool Versioning**: Manage tool schema changes
3. **Tool Analytics**: Usage metrics and performance monitoring
4. **Tool Templates**: More domain-specific templates (database, cloud, monitoring)
5. **Tool Composition Patterns**: Pre-built multi-tool workflows

### Integration Opportunities

- **Security Scanning Suite**: Audit tool implementations for vulnerabilities
- **Evaluation Framework**: Measure tool quality and reliability
- **Orchestration Framework**: Advanced multi-tool workflows
- **Documentation Generator**: Auto-generate tool docs from schemas

## Support

### Getting Help

**For tool creation issues**:
1. Check GOTCHAS.md for common problems
2. Review EXAMPLES.md for similar use cases
3. Consult REFERENCE.md for API details
4. Search repository for existing tool implementations

**For integration questions**:
1. Review this INTEGRATION.md file
2. Check agent documentation for tool requirements
3. Look at skill integration examples above
4. Test with minimal example before full implementation

### Contributing

**Adding new patterns**:
1. Implement pattern following existing structure
2. Add to PATTERNS.md with "When to Use" section
3. Create complete example in EXAMPLES.md
4. Document gotchas in GOTCHAS.md
5. Update tests to validate new pattern

**Improving documentation**:
1. Keep SKILL.md under 500 lines (progressive disclosure)
2. Add detailed information to specific files
3. Include working code examples
4. Update cross-references
5. Run tests to validate changes

---

**Status**: Active integration with mcp-server-engineer, mcp-tool-engineer, ai-engineer agents.

**Last Updated**: 2025-10-27
