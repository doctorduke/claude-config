#!/usr/bin/env node
/**
 * GitHub Actions Workflow Validator
 *
 * Validates workflow syntax, references, and dependencies
 * Usage: node scripts/test-workflows/validate-workflows.js [workflow-file]
 */

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

// Colors for console output
const colors = {
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  reset: '\x1b[0m'
};

function log(color, message) {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function validateYamlSyntax(workflowPath) {
  try {
    const content = fs.readFileSync(workflowPath, 'utf8');
    yaml.load(content);
    return { valid: true, error: null };
  } catch (error) {
    return { valid: false, error: error.message };
  }
}

function validateWorkflowReferences(workflowPath) {
  const content = fs.readFileSync(workflowPath, 'utf8');
  const workflow = yaml.load(content);
  const issues = [];
  const foundSecrets = new Set();

  // Recursive function to traverse the YAML object
  function traverse(obj) {
    for (const key in obj) {
      if (Object.prototype.hasOwnProperty.call(obj, key)) {
        const value = obj[key];

        // Check for workflow references (uses: ./.github/workflows/...)
        if (key === 'uses' && typeof value === 'string' && value.startsWith('./.github/workflows/')) {
          const referencedWorkflow = value.substring('./.github/workflows/'.length);
          const referencedPath = path.join('.github', 'workflows', referencedWorkflow);

          if (!fs.existsSync(referencedPath)) {
            issues.push(`Missing referenced workflow: ${referencedWorkflow}`);
          }
        }
        // Check for secrets in any string value
        else if (typeof value === 'string') {
          const matches = value.matchAll(/\$\{\{\s*secrets\.([^\s}]+)\s*\}\}/g);
          for (const match of matches) {
            foundSecrets.add(match[1]);
          }
        }

        // Recursively traverse nested objects and arrays
        if (typeof value === 'object' && value !== null) {
          traverse(value);
        }
      }
    }
  }

  traverse(workflow);

  // Check for required secrets (warn only, don't fail)
  if (foundSecrets.size > 0) {
    const uniqueSecrets = [...foundSecrets];
    const commonSecrets = ['PAT_GITHUB', 'CLAUDE_CODE_OAUTH_TOKEN'];
    const missingSecrets = uniqueSecrets.filter(secret =>
      commonSecrets.includes(secret) && !process.env[`GITHUB_${secret}`]
    );

    if (missingSecrets.length > 0 && process.env.NODE_ENV !== 'production') {
      console.log(`⚠️  Missing environment variables for secrets: ${missingSecrets.join(', ')} (local development - not failing)`);
    }
  }

  return issues;
}

function validateWorkflowStructure(workflowPath) {
  const content = fs.readFileSync(workflowPath, 'utf8');
  const workflow = yaml.load(content);
  const issues = [];

  // Check required fields
  if (!workflow.name) {
    issues.push('Missing workflow name');
  }

  if (!workflow.on) {
    issues.push('Missing trigger events (on)');
  }

  if (!workflow.jobs || Object.keys(workflow.jobs).length === 0) {
    issues.push('Missing or empty jobs section');
  }

  // Check job structure
  if (workflow.jobs) {
    Object.entries(workflow.jobs).forEach(([jobName, job]) => {
      if (!job['runs-on'] && !job.runs_on && !job.uses) {
        issues.push(`Job '${jobName}' missing runs-on or uses`);
      }

      if (job.steps && Array.isArray(job.steps)) {
        job.steps.forEach((step, index) => {
          if (!step.name && !step.uses && !step.run) {
            issues.push(`Step ${index + 1} in job '${jobName}' missing name, uses, or run`);
          }
        });
      }
    });
  }

  return issues;
}

function main() {
  const targetWorkflow = process.argv[2];
  const workflowsDir = '.github/workflows';

  let workflowsToCheck = [];

  if (targetWorkflow) {
    const workflowPath = path.join(workflowsDir, targetWorkflow);
    if (fs.existsSync(workflowPath)) {
      workflowsToCheck = [workflowPath];
    } else {
      log('red', `❌ Workflow not found: ${workflowPath}`);
      process.exit(1);
    }
  } else {
    // Check all workflows
    workflowsToCheck = fs.readdirSync(workflowsDir)
      .filter(file => file.endsWith('.yml'))
      .map(file => path.join(workflowsDir, file));
  }

  log('blue', '🔍 GitHub Actions Workflow Validator');
  log('blue', '=====================================');

  let totalIssues = 0;
  let validWorkflows = 0;

  workflowsToCheck.forEach(workflowPath => {
    const workflowName = path.basename(workflowPath);
    log('blue', `\n📋 Checking ${workflowName}`);

    // Validate YAML syntax
    const syntaxCheck = validateYamlSyntax(workflowPath);
    if (!syntaxCheck.valid) {
      log('red', `❌ Invalid YAML syntax: ${syntaxCheck.error}`);
      totalIssues++;
      return;
    }
    log('green', '✅ Valid YAML syntax');

    // Validate workflow references
    const referenceIssues = validateWorkflowReferences(workflowPath);
    if (referenceIssues.length > 0) {
      log('yellow', '⚠️  Reference issues:');
      referenceIssues.forEach(issue => log('yellow', `   - ${issue}`));
      totalIssues += referenceIssues.length;
    } else {
      log('green', '✅ All references valid');
    }

    // Validate workflow structure
    const structureIssues = validateWorkflowStructure(workflowPath);
    if (structureIssues.length > 0) {
      log('yellow', '⚠️  Structure issues:');
      structureIssues.forEach(issue => log('yellow', `   - ${issue}`));
      totalIssues += structureIssues.length;
    } else {
      log('green', '✅ Workflow structure valid');
    }

    if (referenceIssues.length === 0 && structureIssues.length === 0) {
      validWorkflows++;
    }
  });

  // Summary
  log('blue', '\n📊 Summary');
  log('blue', '==========');
  log('green', `✅ Valid workflows: ${validWorkflows}/${workflowsToCheck.length}`);

  if (totalIssues > 0) {
    log('red', `❌ Total issues found: ${totalIssues}`);
    process.exit(1);
  } else {
    log('green', '🎉 All workflows are valid!');
    process.exit(0);
  }
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = {
  validateYamlSyntax,
  validateWorkflowReferences,
  validateWorkflowStructure
};
