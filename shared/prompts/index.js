const fs = require('fs').promises;
const path = require('path');
const yaml = require('js-yaml');

/**
 * Load and parse a prompt template from a YAML file
 * @param {string} promptName - Name of the prompt file (without .yaml extension)
 * @param {Object} variables - Variables to substitute in the prompt
 * @returns {Promise<Object>} Parsed prompt with substituted variables
 */
async function loadPrompt(promptName, variables = {}) {
  const promptPath = path.join(__dirname, `${promptName}.yaml`);

  try {
    const content = await fs.readFile(promptPath, 'utf8');
    const [promptBody, metadataSection] = content.split('\n---\n');

    // Parse metadata
    const metadata = yaml.load(metadataSection);

    // Clean prompt body (remove comments and leading #)
    let cleanedPrompt = promptBody
      .split('\n')
      .filter(line => !line.trim().startsWith('#') || line.trim().length === 0)
      .join('\n')
      .trim();

    // Substitute variables
    const substitutedPrompt = substituteVariables(cleanedPrompt, variables, metadata.variables);

    return {
      prompt: substitutedPrompt,
      metadata,
      variables: variables
    };
  } catch (error) {
    throw new Error(`Failed to load prompt '${promptName}': ${error.message}`);
  }
}

/**
 * Substitute variables in prompt template
 * @param {string} template - Template string with {VARIABLE} placeholders
 * @param {Object} provided - Provided variable values
 * @param {Array} definitions - Variable definitions from metadata
 * @returns {string} Template with substituted values
 */
function substituteVariables(template, provided, definitions = []) {
  let result = template;

  // Create a map of variable definitions for easy lookup
  const varMap = new Map(definitions.map(v => [v.name, v]));

  // Find all variables in template
  const variablePattern = /\{([A-Z_]+)\}/g;
  const matches = [...template.matchAll(variablePattern)];

  for (const match of matches) {
    const varName = match[1];
    const varDef = varMap.get(varName);

    // Determine value to use
    let value;
    if (provided[varName] !== undefined) {
      value = provided[varName];
    } else if (varDef && varDef.default !== undefined) {
      value = varDef.default;
    } else if (varDef && varDef.required) {
      throw new Error(`Required variable '${varName}' not provided`);
    } else {
      // Leave placeholder if no value available
      continue;
    }

    // Replace all occurrences of this variable
    result = result.replace(new RegExp(`\\{${varName}\\}`, 'g'), value);
  }

  return result;
}

/**
 * List all available prompts
 * @returns {Promise<Array>} List of prompt names and descriptions
 */
async function listPrompts() {
  const files = await fs.readdir(__dirname);
  const prompts = [];

  for (const file of files) {
    if (file.endsWith('.yaml') && file !== 'template.yaml') {
      try {
        const content = await fs.readFile(path.join(__dirname, file), 'utf8');
        const [, metadataSection] = content.split('\n---\n');
        const metadata = yaml.load(metadataSection);

        prompts.push({
          name: file.replace('.yaml', ''),
          description: metadata.description,
          usage: metadata.usage
        });
      } catch (error) {
        console.error(`Error reading ${file}: ${error.message}`);
      }
    }
  }

  return prompts;
}

/**
 * Validate variables against prompt requirements
 * @param {string} promptName - Name of the prompt
 * @param {Object} variables - Variables to validate
 * @returns {Promise<Object>} Validation result
 */
async function validateVariables(promptName, variables) {
  const promptPath = path.join(__dirname, `${promptName}.yaml`);

  try {
    const content = await fs.readFile(promptPath, 'utf8');
    const [, metadataSection] = content.split('\n---\n');
    const metadata = yaml.load(metadataSection);

    const errors = [];
    const warnings = [];

    // Check required variables
    for (const varDef of metadata.variables || []) {
      if (varDef.required && !variables[varDef.name]) {
        errors.push(`Missing required variable: ${varDef.name}`);
      }
    }

    // Check for unknown variables
    const knownVars = new Set((metadata.variables || []).map(v => v.name));
    for (const varName of Object.keys(variables)) {
      if (!knownVars.has(varName)) {
        warnings.push(`Unknown variable provided: ${varName}`);
      }
    }

    return {
      valid: errors.length === 0,
      errors,
      warnings
    };
  } catch (error) {
    throw new Error(`Failed to validate prompt '${promptName}': ${error.message}`);
  }
}

/**
 * Get prompt metadata without loading the full prompt
 * @param {string} promptName - Name of the prompt
 * @returns {Promise<Object>} Prompt metadata
 */
async function getPromptMetadata(promptName) {
  const promptPath = path.join(__dirname, `${promptName}.yaml`);

  try {
    const content = await fs.readFile(promptPath, 'utf8');
    const [, metadataSection] = content.split('\n---\n');
    return yaml.load(metadataSection);
  } catch (error) {
    throw new Error(`Failed to get metadata for prompt '${promptName}': ${error.message}`);
  }
}

module.exports = {
  loadPrompt,
  listPrompts,
  validateVariables,
  getPromptMetadata,
  substituteVariables
};