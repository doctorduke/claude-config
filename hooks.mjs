/**
 * Claude Code Hooks for umemee-v0
 * Enforces documentation standards across the monorepo
 */

import fs from 'fs';
import { promises as fsPromises } from 'fs';
import path from 'path';

// Logging utility for audit trail
const logEnforcement = (action, details) => {
  const timestamp = new Date().toISOString();
  const logEntry = {
    timestamp,
    action,
    ...details
  };
  console.log('[DOCS-ENFORCEMENT]', JSON.stringify(logEntry));
};

// Check if a directory contains code files
const isCodeDirectory = async (dirPath, depth = 0, maxDepth = 5) => {
  try {
    // Check if path exists and is a directory
    try {
      const stats = await fsPromises.stat(dirPath);
      if (!stats.isDirectory()) {
        return false;
      }
    } catch {
      return false;
    }

    // Prevent infinite recursion
    if (depth > maxDepth) {
      return false;
    }

    const entries = await fsPromises.readdir(dirPath, { withFileTypes: true });
    const codeExtensions = ['.js', '.jsx', '.ts', '.tsx', '.mjs', '.cjs', '.json'];

    for (const entry of entries) {
      if (entry.isFile()) {
        const ext = path.extname(entry.name).toLowerCase();
        if (codeExtensions.includes(ext) && !entry.name.startsWith('.')) {
          return true;
        }
      } else if (entry.isDirectory() && !entry.name.startsWith('.') && entry.name !== 'node_modules') {
        // Recursively check subdirectories with depth limit
        if (await isCodeDirectory(path.join(dirPath, entry.name), depth + 1, maxDepth)) {
          return true;
        }
      }
    }

    return false;
  } catch (error) {
    logEnforcement('error', {
      function: 'isCodeDirectory',
      path: dirPath,
      error: error.message
    });
    return false;
  }
};

// Validate BRIEF.md structure
const validateBriefStructure = (content) => {
  try {
    const errors = [];

    // Check for required sections
    if (!content.includes('#')) {
      errors.push('BRIEF.md must have at least one heading');
    }

    // Check minimum length (should be brief but meaningful)
    if (content.trim().length < 50) {
      errors.push('BRIEF.md must contain meaningful content (at least 50 characters)');
    }

    // Check for descriptive content
    const lines = content.split('\n').filter(line => line.trim().length > 0);
    if (lines.length < 3) {
      errors.push('BRIEF.md must have at least 3 non-empty lines');
    }

    return errors;
  } catch (error) {
    logEnforcement('error', {
      function: 'validateBriefStructure',
      error: error.message
    });
    return ['Error validating BRIEF.md structure'];
  }
};

// Validate CLAUDE.md structure
const validateClaudeStructure = (content) => {
  try {
    const errors = [];
    const requiredSections = [
      '## Purpose',
      '## Dependencies',
      '## Key Files',
      '## Conventions'
    ];

    for (const section of requiredSections) {
      if (!content.includes(section)) {
        errors.push(`CLAUDE.md missing required section: ${section}`);
      }
    }

    // Check minimum content length
    if (content.trim().length < 500) {
      errors.push('CLAUDE.md must be comprehensive (at least 500 characters)');
    }

    // Check for proper markdown structure
    if (!content.includes('# ')) {
      errors.push('CLAUDE.md must have a main heading');
    }

    return errors;
  } catch (error) {
    logEnforcement('error', {
      function: 'validateClaudeStructure',
      error: error.message
    });
    return ['Error validating CLAUDE.md structure'];
  }
};

/**
 * Hook: Pre-Directory Creation
 * Prevents directory creation without BRIEF.md
 */
export const preDirectoryCreate = async (context) => {
  try {
    const { targetPath, operation } = context;

    // Skip validation for special directories
    const skipPatterns = [
      'node_modules',
      '.git',
      '.claude',
      'dist',
      'build',
      '.next',
      '.turbo',
      'coverage'
    ];

    const dirName = path.basename(targetPath);
    if (skipPatterns.some(pattern => dirName.includes(pattern))) {
      return { allow: true };
    }

    // Check if parent directory exists
    const parentDir = path.dirname(targetPath);
    try {
      await fsPromises.access(parentDir);
    } catch {
      return {
        allow: false,
        error: `Cannot create directory: parent directory ${parentDir} does not exist`
      };
    }

    logEnforcement('DIRECTORY_CREATE_ATTEMPT', {
      path: targetPath,
      operation
    });

    return {
      allow: true,
      warning: `Remember to create BRIEF.md in ${targetPath} immediately after creation`,
      postCreateCheck: true
    };
  } catch (error) {
    logEnforcement('error', {
      function: 'preDirectoryCreate',
      error: error.message
    });
    return { allow: true }; // Allow operation on error to prevent blocking
  }
};

/**
 * Hook: Post-Directory Creation
 * Validates BRIEF.md exists after directory creation
 */
export const postDirectoryCreate = async (context) => {
  try {
    const { targetPath } = context;
    const briefPath = path.join(targetPath, 'BRIEF.md');

    // Give a grace period for file creation
    await new Promise(resolve => setTimeout(resolve, 100));

    // Check if BRIEF.md exists
    let briefExists = true;
    try {
      await fsPromises.access(briefPath);
    } catch {
      briefExists = false;
    }

    if (!briefExists) {
      const warning = `BRIEF.md is required in ${targetPath}. Please create it with:
      - A clear description of the directory's purpose
      - Contents overview
      - Any relevant notes`;

      logEnforcement('MISSING_BRIEF', {
        path: targetPath,
        file: 'BRIEF.md'
      });

      return {
        status: 'warning',
        message: warning,
        requiresAction: true
      };
    }

    // Validate BRIEF.md structure
    const content = await fsPromises.readFile(briefPath, 'utf8');
    const errors = validateBriefStructure(content);

    if (errors.length > 0) {
      logEnforcement('INVALID_BRIEF_STRUCTURE', {
        path: briefPath,
        errors
      });

      return {
        status: 'warning',
        message: `BRIEF.md structure issues:\n${errors.join('\n')}`,
        requiresAction: true
      };
    }

    logEnforcement('BRIEF_VALIDATED', {
      path: briefPath
    });

    return { status: 'success' };
  } catch (error) {
    logEnforcement('POST_DIRECTORY_CREATE_ERROR', {
      path: context.targetPath,
      error: error.message
    });

    return {
      status: 'error',
      message: `Error validating directory: ${error.message}`
    };
  }
};

/**
 * Hook: File Creation/Modification
 * Ensures CLAUDE.md exists in code directories
 */
export const onFileChange = async (context) => {
  try {
    const { filePath, operation } = context;

    // Only check for code file operations
    const codeExtensions = ['.js', '.jsx', '.ts', '.tsx', '.mjs', '.cjs'];
    const ext = path.extname(filePath).toLowerCase();

    if (!codeExtensions.includes(ext)) {
      return { status: 'skip' };
    }

    const dir = path.dirname(filePath);
    const claudePath = path.join(dir, 'CLAUDE.md');

    // Skip if in special directories
    const skipPatterns = ['node_modules', '.git', 'dist', 'build', '.next', '.turbo'];
    if (skipPatterns.some(pattern => dir.includes(pattern))) {
      return { status: 'skip' };
    }

    // Check if CLAUDE.md exists
    let claudeExists = true;
    try {
      await fsPromises.access(claudePath);
    } catch {
      claudeExists = false;
    }

    if (!claudeExists && await isCodeDirectory(dir)) {
      const warning = `Code directory ${dir} is missing CLAUDE.md. This file should include:
      - Purpose and architecture overview
      - Dependencies (internal and external)
      - Key files and their roles
      - Development conventions
      - Testing approach
      - Common tasks and gotchas`;

      logEnforcement('MISSING_CLAUDE', {
        path: dir,
        triggeredBy: filePath,
        operation
      });

      return {
        status: 'warning',
        message: warning,
        requiresAction: true
      };
    }

    // If CLAUDE.md exists, validate its structure
    if (claudeExists) {
      const content = await fsPromises.readFile(claudePath, 'utf8');
      const errors = validateClaudeStructure(content);

      if (errors.length > 0) {
        logEnforcement('INVALID_CLAUDE_STRUCTURE', {
          path: claudePath,
          errors
        });

        return {
          status: 'warning',
          message: `CLAUDE.md structure issues in ${dir}:\n${errors.join('\n')}`,
          requiresAction: false
        };
      }
    }

    return { status: 'success' };
  } catch (error) {
    logEnforcement('error', {
      function: 'onFileChange',
      error: error.message
    });
    return { status: 'error', message: error.message };
  }
};

/**
 * Hook: Documentation Quality Check
 * Validates documentation files meet quality standards
 */
export const validateDocumentation = async (context) => {
  try {
    const { filePath } = context;

    if (!filePath.endsWith('.md')) {
      return { status: 'skip' };
    }

    const fileName = path.basename(filePath);
    const content = await fsPromises.readFile(filePath, 'utf8');

    let errors = [];

    if (fileName === 'BRIEF.md') {
      errors = validateBriefStructure(content);
    } else if (fileName === 'CLAUDE.md') {
      errors = validateClaudeStructure(content);
    }

    if (errors.length > 0) {
      logEnforcement('DOCUMENTATION_QUALITY_CHECK', {
        path: filePath,
        errors,
        status: 'failed'
      });

      return {
        status: 'error',
        message: `Documentation quality issues in ${filePath}:\n${errors.join('\n')}`,
        errors
      };
    }

    logEnforcement('DOCUMENTATION_QUALITY_CHECK', {
      path: filePath,
      status: 'passed'
    });

    return { status: 'success' };
  } catch (error) {
    logEnforcement('error', {
      function: 'validateDocumentation',
      error: error.message
    });
    return { status: 'error', message: error.message };
  }
};

/**
 * Hook: Project Scan
 * Scans entire project for documentation compliance
 */
export const scanProjectDocumentation = async (rootPath = process.cwd()) => {
  const issues = [];

  const scanDirectory = async (dirPath, depth = 0) => {
    // Skip deep nested directories and special folders
    if (depth > 5) return;

    const skipPatterns = ['node_modules', '.git', 'dist', 'build', '.next', '.turbo', 'coverage'];
    const dirName = path.basename(dirPath);
    if (skipPatterns.some(pattern => dirName.includes(pattern))) {
      return;
    }

    try {
      const entries = await fsPromises.readdir(dirPath, { withFileTypes: true });
      const hasCode = await isCodeDirectory(dirPath);

      // Check for BRIEF.md
      const briefPath = path.join(dirPath, 'BRIEF.md');
      let briefExists = true;
      try {
        await fsPromises.access(briefPath);
      } catch {
        briefExists = false;
      }
      if (!briefExists && depth > 0) {
        issues.push({
          type: 'MISSING_BRIEF',
          path: dirPath,
          severity: 'warning'
        });
      }

      // Check for CLAUDE.md in code directories
      const claudePath = path.join(dirPath, 'CLAUDE.md');
      let claudeExists = true;
      try {
        await fsPromises.access(claudePath);
      } catch {
        claudeExists = false;
      }
      if (hasCode && !claudeExists) {
        issues.push({
          type: 'MISSING_CLAUDE',
          path: dirPath,
          severity: 'error'
        });
      }

      // Validate existing documentation
      if (briefExists) {
        const content = await fsPromises.readFile(briefPath, 'utf8');
        const errors = validateBriefStructure(content);
        if (errors.length > 0) {
          issues.push({
            type: 'INVALID_BRIEF',
            path: briefPath,
            errors,
            severity: 'warning'
          });
        }
      }

      if (claudeExists) {
        const content = await fsPromises.readFile(claudePath, 'utf8');
        const errors = validateClaudeStructure(content);
        if (errors.length > 0) {
          issues.push({
            type: 'INVALID_CLAUDE',
            path: claudePath,
            errors,
            severity: 'error'
          });
        }
      }

      // Recursively scan subdirectories
      for (const entry of entries) {
        if (entry.isDirectory()) {
          await scanDirectory(path.join(dirPath, entry.name), depth + 1);
        }
      }
    } catch (error) {
      logEnforcement('SCAN_ERROR', {
        path: dirPath,
        error: error.message
      });
    }
  };

  await scanDirectory(rootPath);

  logEnforcement('PROJECT_SCAN_COMPLETE', {
    rootPath,
    issuesFound: issues.length,
    errors: issues.filter(i => i.severity === 'error').length,
    warnings: issues.filter(i => i.severity === 'warning').length
  });

  return {
    success: issues.filter(i => i.severity === 'error').length === 0,
    issues,
    summary: {
      total: issues.length,
      errors: issues.filter(i => i.severity === 'error').length,
      warnings: issues.filter(i => i.severity === 'warning').length
    }
  };
};

/**
 * Hook: Initialize Documentation
 * Helper to create standard documentation templates
 */
export const initializeDocumentation = async (dirPath, type = 'both') => {
  const results = [];

  if (type === 'brief' || type === 'both') {
    const briefPath = path.join(dirPath, 'BRIEF.md');
    let briefExists = true;
    try {
      await fsPromises.access(briefPath);
    } catch {
      briefExists = false;
    }
    if (!briefExists) {
      const dirName = path.basename(dirPath);
      const briefTemplate = `# ${dirName}

Brief description of this directory's purpose and contents.

## Contents

- List key subdirectories or files
- Explain their roles briefly

## Notes

Any important notes for developers working in this directory.
`;

      await fsPromises.writeFile(briefPath, briefTemplate);
      results.push(`Created BRIEF.md in ${dirPath}`);

      logEnforcement('DOCUMENTATION_CREATED', {
        path: briefPath,
        type: 'BRIEF'
      });
    }
  }

  if (type === 'claude' || type === 'both') {
    const claudePath = path.join(dirPath, 'CLAUDE.md');
    let claudeExists = true;
    try {
      await fsPromises.access(claudePath);
    } catch {
      claudeExists = false;
    }
    if (!claudeExists) {
      const dirName = path.basename(dirPath);
      const claudeTemplate = `# CLAUDE.md - ${dirName}

## Purpose

Describe the purpose and role of this module/directory in the system.

## Dependencies

### Internal Dependencies
- List internal package dependencies

### External Dependencies
- List external npm dependencies

## Key Files

- \`file1.ts\`: Description of its role
- \`file2.ts\`: Description of its role

## Conventions

### Naming Conventions
- Describe naming patterns used

### Code Style
- Specific style guidelines for this module

## Testing

### Testing Strategy
Describe how this module should be tested.

### Running Tests
\`\`\`bash
# Commands to run tests
\`\`\`

## Common Tasks

### Task 1
Description and commands

### Task 2
Description and commands

## Gotchas

### Known Issues
- List any known issues or quirks

### Common Mistakes
- List common mistakes to avoid

## Architecture Decisions

### Design Rationale
Explain key design decisions made for this module.

## Performance Considerations

Notes on performance optimization and concerns.

## Security Notes

Any security considerations for this module.
`;

      await fsPromises.writeFile(claudePath, claudeTemplate);
      results.push(`Created CLAUDE.md in ${dirPath}`);

      logEnforcement('DOCUMENTATION_CREATED', {
        path: claudePath,
        type: 'CLAUDE'
      });
    }
  }

  return {
    success: true,
    results
  };
};

// Export all hooks and utilities
export default {
  preDirectoryCreate,
  postDirectoryCreate,
  onFileChange,
  validateDocumentation,
  scanProjectDocumentation,
  initializeDocumentation,

  // Utilities
  isCodeDirectory,
  validateBriefStructure,
  validateClaudeStructure,
  logEnforcement
};