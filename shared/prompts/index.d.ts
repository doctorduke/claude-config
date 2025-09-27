export interface PromptVariable {
  name: string;
  description: string;
  default?: any;
  required?: boolean;
}

export interface PromptMetadata {
  name: string;
  description: string;
  usage: string;
  variables?: PromptVariable[];
}

export interface LoadedPrompt {
  prompt: string;
  metadata: PromptMetadata;
  variables: Record<string, any>;
}

export interface PromptInfo {
  name: string;
  description: string;
  usage: string;
}

export interface ValidationResult {
  valid: boolean;
  errors: string[];
  warnings: string[];
}

/**
 * Load and parse a prompt template from a YAML file
 */
export function loadPrompt(
  promptName: string,
  variables?: Record<string, any>
): Promise<LoadedPrompt>;

/**
 * List all available prompts
 */
export function listPrompts(): Promise<PromptInfo[]>;

/**
 * Validate variables against prompt requirements
 */
export function validateVariables(
  promptName: string,
  variables: Record<string, any>
): Promise<ValidationResult>;

/**
 * Get prompt metadata without loading the full prompt
 */
export function getPromptMetadata(promptName: string): Promise<PromptMetadata>;

/**
 * Substitute variables in prompt template
 */
export function substituteVariables(
  template: string,
  provided: Record<string, any>,
  definitions?: PromptVariable[]
): string;