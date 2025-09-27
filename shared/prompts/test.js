#!/usr/bin/env node

const { loadPrompt, listPrompts, validateVariables } = require('./index.js');

async function testPromptSystem() {
  console.log('Testing Prompt System\n');
  console.log('=' .repeat(50));

  try {
    // Test 1: List all prompts
    console.log('\n1. Available Prompts:');
    const prompts = await listPrompts();
    prompts.forEach(p => {
      console.log(`   - ${p.name}: ${p.description}`);
    });

    // Test 2: Load PR review prompt with variables
    console.log('\n2. Loading PR Review Prompt:');
    const prReview = await loadPrompt('pr-review', {
      PR_NUMBER: '123',
      REPO_NAME: 'doctorduke/umemee-v0',
      BRANCH_NAME: 'feature/new-feature',
      PR_AUTHOR: 'developer',
      CHANGES_SUMMARY: 'Added new authentication module'
    });
    console.log('   Loaded successfully');
    console.log('   Metadata:', prReview.metadata.name);
    console.log('   First 100 chars:', prReview.prompt.substring(0, 100) + '...');

    // Test 3: Validate variables
    console.log('\n3. Variable Validation:');
    const validation = await validateVariables('pr-review', {
      PR_NUMBER: '123',
      REPO_NAME: 'test-repo'
      // Missing required variables to test validation
    });
    console.log('   Valid:', validation.valid);
    if (validation.errors.length > 0) {
      console.log('   Errors:', validation.errors);
    }

    // Test 4: Load with defaults
    console.log('\n4. Loading Context-Aware Prompt with Defaults:');
    const context = await loadPrompt('context-aware-response', {
      WORKING_DIR: '/Users/dev/project',
      GIT_BRANCH: 'main',
      PROJECT_CONTEXT: 'Building a monorepo',
      CONVERSATION_HISTORY: 'User asked about TypeScript setup',
      USER_REQUEST: 'How do I configure TypeScript?'
    });
    console.log('   Loaded with defaults applied');
    console.log('   Platform default:', context.metadata.variables.find(v => v.name === 'PLATFORM').default);

    // Test 5: Error handling
    console.log('\n5. Error Handling:');
    try {
      await loadPrompt('non-existent-prompt');
    } catch (error) {
      console.log('   Caught expected error:', error.message.substring(0, 50) + '...');
    }

    console.log('\n' + '=' .repeat(50));
    console.log('All tests completed successfully!\n');

  } catch (error) {
    console.error('Test failed:', error);
    process.exit(1);
  }
}

// Run tests if executed directly
if (require.main === module) {
  testPromptSystem();
}