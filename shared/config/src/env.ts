/**
 * Environment variable loading and validation
 */

/**
 * Load Node.js environment variables with optional validation
 * @param requiredVars - Array of required environment variable names
 * @returns Object containing environment variables
 */
export function loadNodeEnv(requiredVars: string[] = []): Record<string, string | undefined> {
  const env: Record<string, string | undefined> = {};

  // Load all environment variables
  Object.keys(process.env).forEach((key) => {
    env[key] = process.env[key];
  });

  // Check for required variables
  const missing = requiredVars.filter((varName) => !process.env[varName]);

  if (missing.length > 0) {
    console.warn(`Missing required environment variables: ${missing.join(', ')}`);
  }

  return env;
}

/**
 * Get environment variable with default value
 * @param key - Environment variable name
 * @param defaultValue - Default value if not found
 * @returns Environment variable value or default
 */
export function getEnvVar(key: string, defaultValue?: string): string | undefined {
  return process.env[key] || defaultValue;
}

/**
 * Check if running in development mode
 */
export function isDevelopment(): boolean {
  return process.env.NODE_ENV === 'development';
}

/**
 * Check if running in production mode
 */
export function isProduction(): boolean {
  return process.env.NODE_ENV === 'production';
}

/**
 * Check if running in test mode
 */
export function isTest(): boolean {
  return process.env.NODE_ENV === 'test';
}