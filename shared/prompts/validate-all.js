#!/usr/bin/env node

const fs = require('fs').promises;
const path = require('path');
const yaml = require('js-yaml');

/**
 * Validate all YAML prompts in the directory
 */
async function validateAllPrompts() {
  console.log('Validating All Prompts\n');
  console.log('=' .repeat(50));

  const errors = [];
  const warnings = [];
  let validCount = 0;

  try {
    const files = await fs.readdir(__dirname);
    const yamlFiles = files.filter(f => f.endsWith('.yaml') && f !== 'template.yaml');

    for (const file of yamlFiles) {
      console.log(`\nValidating: ${file}`);
      const filePath = path.join(__dirname, file);

      try {
        const content = await fs.readFile(filePath, 'utf8');

        // Check for proper structure
        if (!content.includes('\n---\n')) {
          errors.push(`${file}: Missing metadata separator (---)`);
          console.log('  ❌ Missing metadata separator');
          continue;
        }

        const [promptBody, metadataSection] = content.split('\n---\n');

        // Validate metadata
        let metadata;
        try {
          metadata = yaml.load(metadataSection);
        } catch (e) {
          errors.push(`${file}: Invalid YAML in metadata - ${e.message}`);
          console.log('  ❌ Invalid YAML metadata');
          continue;
        }

        // Check required metadata fields
        const requiredFields = ['name', 'description', 'usage'];
        for (const field of requiredFields) {
          if (!metadata[field]) {
            errors.push(`${file}: Missing required field '${field}'`);
            console.log(`  ❌ Missing required field: ${field}`);
          }
        }

        // Validate variables if present
        if (metadata.variables) {
          if (!Array.isArray(metadata.variables)) {
            errors.push(`${file}: Variables must be an array`);
            console.log('  ❌ Variables must be an array');
          } else {
            for (const variable of metadata.variables) {
              if (!variable.name) {
                errors.push(`${file}: Variable missing 'name' field`);
                console.log('  ❌ Variable missing name');
              }
              if (!variable.description) {
                warnings.push(`${file}: Variable '${variable.name}' missing description`);
                console.log(`  ⚠️  Variable '${variable.name}' missing description`);
              }
            }
          }
        }

        // Check for variable placeholders in prompt body
        const variablePattern = /\{([A-Z_]+)\}/g;
        const foundVars = new Set();
        let match;
        while ((match = variablePattern.exec(promptBody)) !== null) {
          foundVars.add(match[1]);
        }

        // Check if all found variables are documented
        const documentedVars = new Set(
          (metadata.variables || []).map(v => v.name)
        );

        for (const varName of foundVars) {
          if (varName !== 'PROMPT_BODY' && !documentedVars.has(varName)) {
            warnings.push(`${file}: Variable '${varName}' used but not documented`);
            console.log(`  ⚠️  Variable '${varName}' used but not documented`);
          }
        }

        // Check if documented variables are actually used
        for (const varName of documentedVars) {
          if (!foundVars.has(varName)) {
            warnings.push(`${file}: Variable '${varName}' documented but not used`);
            console.log(`  ⚠️  Variable '${varName}' documented but not used`);
          }
        }

        console.log('  ✅ Valid');
        validCount++;

      } catch (error) {
        errors.push(`${file}: ${error.message}`);
        console.log(`  ❌ Error: ${error.message}`);
      }
    }

    // Summary
    console.log('\n' + '=' .repeat(50));
    console.log('\nValidation Summary:');
    console.log(`  Total prompts: ${yamlFiles.length}`);
    console.log(`  Valid: ${validCount}`);
    console.log(`  Errors: ${errors.length}`);
    console.log(`  Warnings: ${warnings.length}`);

    if (errors.length > 0) {
      console.log('\nErrors:');
      errors.forEach(e => console.log(`  - ${e}`));
    }

    if (warnings.length > 0) {
      console.log('\nWarnings:');
      warnings.forEach(w => console.log(`  - ${w}`));
    }

    if (errors.length === 0) {
      console.log('\n✅ All prompts are valid!');
      process.exit(0);
    } else {
      console.log('\n❌ Validation failed. Please fix errors above.');
      process.exit(1);
    }

  } catch (error) {
    console.error('Validation script failed:', error);
    process.exit(1);
  }
}

// Run validation if executed directly
if (require.main === module) {
  validateAllPrompts();
}