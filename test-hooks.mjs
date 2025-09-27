#!/usr/bin/env node
/**
 * Test script for documentation enforcement hooks
 * Run with: node .claude/test-hooks.mjs
 */

import hooks from './hooks.mjs';
import fs from 'fs';
import path from 'path';
import assert from 'assert';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.dirname(__dirname);

console.log('Documentation Enforcement Hooks Test Suite\n');
console.log('==========================================\n');

// Test 1: Scan the project for documentation compliance
console.log('Test 1: Scanning project for documentation compliance...\n');
const scanResult = await hooks.scanProjectDocumentation(projectRoot);

console.log(`Scan Summary:`);
console.log(`- Total Issues: ${scanResult.summary.total}`);
console.log(`- Errors (missing CLAUDE.md in code dirs): ${scanResult.summary.errors}`);
console.log(`- Warnings (missing BRIEF.md): ${scanResult.summary.warnings}`);
console.log(`- Overall Success: ${scanResult.success ? 'Yes' : 'No'}\n`);

// Assertions for Test 1
assert(typeof scanResult === 'object', 'Scan result should be an object');
assert(typeof scanResult.success === 'boolean', 'Scan result should have a boolean success property');
assert(Array.isArray(scanResult.issues), 'Scan result should have an issues array');
assert(typeof scanResult.summary === 'object', 'Scan result should have a summary object');
assert(typeof scanResult.summary.total === 'number', 'Summary should have a numeric total');

if (scanResult.issues.length > 0) {
  console.log('Top Issues Found:');
  const topIssues = scanResult.issues.slice(0, 10);
  topIssues.forEach(issue => {
    const severity = issue.severity === 'error' ? '❌' : '⚠️';
    console.log(`${severity} ${issue.type}: ${issue.path}`);
    if (issue.errors) {
      issue.errors.forEach(err => console.log(`   - ${err}`));
    }
  });

  if (scanResult.issues.length > 10) {
    console.log(`\n... and ${scanResult.issues.length - 10} more issues`);
  }
}

console.log('\n==========================================\n');

// Test 2: Validate specific documentation files
console.log('Test 2: Validating existing documentation files...\n');

const docsToValidate = [
  '/Users/doctorduke/Developer/doctorduke/umemee-v0/CLAUDE.md',
  '/Users/doctorduke/Developer/doctorduke/umemee-v0/platforms/BRIEF.md',
  '/Users/doctorduke/Developer/doctorduke/umemee-v0/platforms/CLAUDE.md'
];

for (const docPath of docsToValidate) {
  if (fs.existsSync(docPath)) {
    const result = await hooks.validateDocumentation({ filePath: docPath });
    const status = result.status === 'success' ? '✅' : '❌';
    console.log(`${status} ${path.basename(docPath)} in ${path.dirname(docPath)}`);
    if (result.errors && result.errors.length > 0) {
      result.errors.forEach(err => console.log(`   - ${err}`));
    }

    // Assertions for Test 2
    assert(typeof result === 'object', 'Validation result should be an object');
    assert(typeof result.status === 'string', 'Validation result should have a status string');
    assert(['success', 'error', 'warning'].includes(result.status), 'Status should be success, error, or warning');
  }
}

console.log('\n==========================================\n');

// Test 3: Test directory creation hook
console.log('Test 3: Testing directory creation hook...\n');

const testDirPath = path.join(projectRoot, 'test-docs-enforcement');

// Simulate pre-directory creation
const preCreateResult = await hooks.preDirectoryCreate({
  targetPath: testDirPath,
  operation: 'mkdir'
});

console.log(`Pre-create check for ${testDirPath}:`);
console.log(`- Allowed: ${preCreateResult.allow}`);
if (preCreateResult.warning) {
  console.log(`- Warning: ${preCreateResult.warning}`);
}

// Assertions for Test 3
assert(typeof preCreateResult === 'object', 'Pre-create result should be an object');
assert(typeof preCreateResult.allow === 'boolean', 'Pre-create result should have an allow boolean');

// Create test directory
if (!fs.existsSync(testDirPath)) {
  fs.mkdirSync(testDirPath);
  console.log(`\nCreated test directory: ${testDirPath}`);

  // Test post-directory creation
  const postCreateResult = await hooks.postDirectoryCreate({
    targetPath: testDirPath
  });

  console.log(`\nPost-create check:`);
  console.log(`- Status: ${postCreateResult.status}`);
  if (postCreateResult.message) {
    console.log(`- Message: ${postCreateResult.message}`);
  }

  // Initialize documentation for the test directory
  console.log('\nInitializing documentation for test directory...');
  const initResult = await hooks.initializeDocumentation(testDirPath, 'both');
  initResult.results.forEach(msg => console.log(`- ${msg}`));

  // Clean up test directory
  console.log('\nCleaning up test directory...');
  fs.rmSync(testDirPath, { recursive: true, force: true });
  console.log('Test directory removed.');
}

console.log('\n==========================================\n');

// Test 4: Check if directories have code
console.log('Test 4: Checking code directory detection...\n');

const dirsToCheck = [
  '/Users/doctorduke/Developer/doctorduke/umemee-v0/platforms/web/src',
  '/Users/doctorduke/Developer/doctorduke/umemee-v0/shared',
  '/Users/doctorduke/Developer/doctorduke/umemee-v0/tools'
];

dirsToCheck.forEach(dir => {
  if (fs.existsSync(dir)) {
    const hasCode = hooks.isCodeDirectory(dir);
    const status = hasCode ? '📁' : '📄';
    console.log(`${status} ${dir}: ${hasCode ? 'Contains code' : 'No code files'}`);

    // Assertions for Test 4
    assert(typeof hasCode === 'boolean', 'isCodeDirectory should return a boolean');
  }
});

console.log('\n==========================================\n');
console.log('Hook tests complete!\n');

// Summary recommendations
const errors = scanResult.issues.filter(i => i.severity === 'error');
const warnings = scanResult.issues.filter(i => i.severity === 'warning');

if (errors.length > 0) {
  console.log('🔴 Action Required:');
  console.log(`   ${errors.length} code directories need CLAUDE.md files`);
  console.log('   Run: node .claude/test-hooks.mjs to see full list\n');
}

if (warnings.length > 0) {
  console.log('🟡 Recommended:');
  console.log(`   ${warnings.length} directories could benefit from BRIEF.md files`);
  console.log('   This helps with project navigation and understanding\n');
}

if (scanResult.success) {
  console.log('🟢 Documentation compliance is good overall!');
}