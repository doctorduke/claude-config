# GitHub Actions Testing Infrastructure

This document describes the testing infrastructure for GitHub Actions workflows in the umemee-v0 project.

## Overview

We use a comprehensive testing approach that includes:
- **Local testing** with `act` (GitHub Actions local runner)
- **Syntax validation** with `js-yaml`
- **Reference validation** to ensure all workflow dependencies exist
- **CI/CD testing** via GitHub Actions

## Prerequisites

### Required Tools

1. **Docker Desktop** - Required for `act`
   ```bash
   # Install Docker Desktop from https://www.docker.com/products/docker-desktop
   # Or via Homebrew:
   brew install --cask docker
   ```

2. **act** - GitHub Actions local runner
   ```bash
   # Install act
   # Install act (download and inspect before executing)
   curl -sS https://raw.githubusercontent.com/nektos/act/master/install.sh -o act_install.sh
   # IMPORTANT: Inspect act_install.sh before running it
   sudo bash act_install.sh

   # Or via Homebrew:
   brew install act
   ```

3. **Node.js** (v20+) - For validation scripts
   ```bash
   # Already installed as part of project requirements
   ```

## Quick Start

### 1. Validate Workflow Syntax
```bash
# Validate all workflows
pnpm test:workflows

# Validate specific workflow
node scripts/test-workflows/validate-workflows.js ai-agents-matrix.yml
```

### 2. Test Workflows Locally
```bash
# Test all workflows (dry run)
pnpm test:workflows:local

# Test specific workflow
pnpm test:workflows:matrix

# Test with specific event type
./scripts/test-workflows/test-local.sh ai-agents-matrix.yml issue_comment
```

### 3. List Available Workflows
```bash
# See all workflows that act can run
pnpm test:workflows:act
```

## Testing Workflows

### AI Agents Matrix Workflow

The `ai-agents-matrix.yml` workflow is our most complex workflow that requires special testing:

```bash
# Test with @claude mention
echo '{"comment": {"body": "@claude test"}, "issue": {"number": 123}}' > /tmp/test-event.json
act -W .github/workflows/ai-agents-matrix.yml -e /tmp/test-event.json --dryrun

# Test with @codex mention
echo '{"comment": {"body": "@codex test"}, "issue": {"number": 123}}' > /tmp/test-event.json
act -W .github/workflows/ai-agents-matrix.yml -e /tmp/test-event.json --dryrun

# Test with @gemini mention
echo '{"comment": {"body": "@gemini test"}, "issue": {"number": 123}}' > /tmp/test-event.json
act -W .github/workflows/ai-agents-matrix.yml -e /tmp/test-event.json --dryrun
```

### Individual Agent Workflows

Test each agent workflow individually:

```bash
# Test Claude workflow
act -W .github/workflows/claude.yml -e /tmp/test-event.json --dryrun

# Test Codex workflow
act -W .github/workflows/codex.yml -e /tmp/test-event.json --dryrun

# Test Gemini workflow
act -W .github/workflows/gemini.yml -e /tmp/test-event.json --dryrun
```

## CI/CD Testing

### Automated Testing

The `test-workflows.yml` workflow automatically runs when:
- Pull requests modify workflow files
- Manual trigger via workflow_dispatch

### Manual Testing

You can trigger workflow testing manually:

1. Go to Actions tab in GitHub
2. Select "Test Workflows"
3. Click "Run workflow"
4. Choose specific workflow or test all

## Configuration

### Act Configuration

The `.actrc` file contains act configuration:
- Container architecture: `linux/amd64` (for Apple Silicon compatibility)
- Bind working directory for faster execution
- Verbose output for debugging

### Environment Variables

For full testing, set these environment variables:

```bash
export GITHUB_PAT_GITHUB="your-github-token"
export GITHUB_CLAUDE_CODE_OAUTH_TOKEN="your-claude-token"
export GITHUB_CODEX_API_KEY="your-codex-key"
export GITHUB_GEMINI_API_KEY="your-gemini-key"
```

## Troubleshooting

### Common Issues

1. **Docker not running**
   ```bash
   # Start Docker Desktop or Docker daemon
   open -a Docker
   ```

2. **Act can't find workflows**
   ```bash
   # Make sure you're in the project root
   cd /path/to/umemee-v0
   act --list
   ```

3. **Container architecture issues**
   ```bash
   # Use the correct architecture flag
   act --container-architecture linux/amd64
   ```

4. **Missing secrets**
   ```bash
   # Create .secrets file for act
   # ⚠️ IMPORTANT: Never commit .secrets to git! Add to .gitignore
   echo "PAT_GITHUB=your-token" > .secrets
   act --secret-file .secrets
   ```

### Debug Mode

Run act with verbose output:
```bash
act --verbose -W .github/workflows/ai-agents-matrix.yml --dryrun
```

## Best Practices

1. **Always test locally** before pushing workflow changes
2. **Use dry run first** to validate syntax and structure
3. **Test with different event types** (issue_comment, pull_request, push)
4. **Validate all workflow references** before committing
5. **Test matrix workflows** with different agent mentions

## File Structure

```
.github/workflows/
├── ai-agents-matrix.yml    # Main matrix workflow
├── claude.yml              # Claude agent workflow
├── codex.yml               # Codex agent workflow
├── gemini.yml              # Gemini agent workflow
└── test-workflows.yml      # Testing infrastructure

scripts/test-workflows/
├── test-local.sh           # Local testing script
└── validate-workflows.js   # Validation script

.actrc                      # Act configuration
README-TESTING.md          # This file
```

## Contributing

When adding new workflows:

1. Create the workflow file
2. Add validation tests
3. Test locally with act
4. Update this documentation
5. Submit PR with test results

## Resources

- [Act Documentation](https://github.com/nektos/act)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Documentation](https://docs.docker.com/)
