#!/usr/bin/env node

/**
 * Example of using the prompts system in various contexts
 */

const { loadPrompt } = require('./index.js');

// Example 1: GitHub Action PR Review
async function runPRReview() {
  // In a real GitHub Action, these would come from environment variables
  const prData = {
    PR_NUMBER: process.env.GITHUB_PR_NUMBER || '42',
    REPO_NAME: process.env.GITHUB_REPOSITORY || 'doctorduke/umemee-v0',
    BRANCH_NAME: process.env.GITHUB_HEAD_REF || 'feature/new-feature',
    TARGET_BRANCH: process.env.GITHUB_BASE_REF || 'trunk',
    PR_AUTHOR: process.env.GITHUB_ACTOR || 'developer',
    CHANGES_SUMMARY: await getChangesSummary() // Would run git diff in practice
  };

  const { prompt } = await loadPrompt('pr-review', prData);

  // Send to Claude API or use in workflow
  console.log('PR Review Prompt Generated:');
  console.log(prompt.substring(0, 200) + '...\n');
}

// Example 2: CI Failure Analysis
async function analyzeCIFailure() {
  const errorOutput = `
    Error: Cannot find module '@umemee/utils'
    at Module._resolveFilename (node:internal/modules/cjs/loader:1077:15)
    at Module._load (node:internal/modules/cjs/loader:922:27)
  `;

  const { prompt } = await loadPrompt('code-fix', {
    CI_JOB_NAME: 'Build and Test',
    WORKFLOW_NAME: 'CI',
    BRANCH_NAME: 'feature/update-deps',
    COMMIT_SHA: 'abc123def456',
    ERROR_OUTPUT: errorOutput,
    FAILED_COMMAND: 'pnpm build'
  });

  console.log('CI Fix Prompt Generated:');
  console.log(prompt.substring(0, 200) + '...\n');
}

// Example 3: Interactive Development Assistant
async function interactiveDevelopment() {
  const { prompt } = await loadPrompt('context-aware-response', {
    WORKING_DIR: process.cwd(),
    GIT_BRANCH: await getCurrentBranch(),
    PROJECT_CONTEXT: 'Working on monorepo shared packages',
    CONVERSATION_HISTORY: 'User: How do I add a new shared package?\nAssistant: Create a new directory under shared/...',
    USER_REQUEST: 'Can you help me set up TypeScript for the new package?'
  });

  console.log('Context-Aware Prompt Generated:');
  console.log(prompt.substring(0, 200) + '...\n');
}

// Example 4: Documentation Generator
async function generateDocumentation() {
  const packageInfo = {
    PACKAGE_NAME: '@umemee/utils',
    PACKAGE_PATH: 'shared/utils',
    PACKAGE_TYPE: 'shared',
    DEPENDENCIES: 'lodash, date-fns',
    EXPORTS: 'formatDate, parseJSON, debounce',
    CODE_SAMPLES: `
export function formatDate(date: Date): string {
  return date.toISOString();
}
    `,
    PACKAGE_JSON: JSON.stringify({
      name: '@umemee/utils',
      version: '1.0.0',
      main: 'dist/index.js'
    }, null, 2)
  };

  const { prompt } = await loadPrompt('brief-generator', packageInfo);

  console.log('Documentation Generator Prompt Created:');
  console.log(prompt.substring(0, 200) + '...\n');
}

// Helper functions (would be real implementations in practice)
async function getChangesSummary() {
  return 'Added authentication module, updated dependencies, fixed TypeScript errors';
}

async function getCurrentBranch() {
  return 'feat/wave1-restructure-and-docs';
}

// Main execution
async function main() {
  console.log('Prompt System Usage Examples\n');
  console.log('=' .repeat(50) + '\n');

  try {
    await runPRReview();
    await analyzeCIFailure();
    await interactiveDevelopment();
    await generateDocumentation();

    console.log('=' .repeat(50));
    console.log('\nAll examples executed successfully!');
    console.log('\nThese prompts can be integrated into:');
    console.log('  - GitHub Actions workflows');
    console.log('  - CLI tools and scripts');
    console.log('  - VS Code extensions');
    console.log('  - CI/CD pipelines');
    console.log('  - Development automation tools');
  } catch (error) {
    console.error('Example failed:', error);
    process.exit(1);
  }
}

// Run examples if executed directly
if (require.main === module) {
  main();
}