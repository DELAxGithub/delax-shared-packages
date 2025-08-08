/**
 * Configuration management system
 */

import { readFileSync, existsSync } from 'fs';
import { join } from 'path';
import { parse as parseYaml } from 'yaml';
import { validateRoutingConfig, type RoutingConfig } from './types';

export class ConfigManager {
  private static instance: ConfigManager;
  private config: RoutingConfig | null = null;
  private configPath: string;

  private constructor(configPath?: string) {
    this.configPath = configPath ?? this.getDefaultConfigPath();
  }

  /**
   * Get singleton instance
   */
  static getInstance(configPath?: string): ConfigManager {
    if (!ConfigManager.instance) {
      ConfigManager.instance = new ConfigManager(configPath);
    }
    return ConfigManager.instance;
  }

  /**
   * Load configuration from YAML file
   */
  loadConfig(environment?: string): RoutingConfig {
    if (!existsSync(this.configPath)) {
      throw new Error(`Configuration file not found: ${this.configPath}`);
    }

    try {
      const yamlContent = readFileSync(this.configPath, 'utf8');
      const rawConfig = parseYaml(yamlContent);

      // Apply environment-specific overrides
      let config = rawConfig;
      if (environment && rawConfig[environment]) {
        config = this.mergeConfigs(rawConfig, rawConfig[environment]);
      }

      // Remove environment-specific sections from final config
      const cleanConfig = this.cleanEnvironmentSections(config);

      // Validate configuration
      this.config = validateRoutingConfig(cleanConfig);
      
      return this.config;
    } catch (error) {
      throw new Error(`Failed to load configuration: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  /**
   * Get current configuration (load if not already loaded)
   */
  getConfig(environment?: string): RoutingConfig {
    if (!this.config) {
      return this.loadConfig(environment);
    }
    return this.config;
  }

  /**
   * Reload configuration from file
   */
  reloadConfig(environment?: string): RoutingConfig {
    this.config = null;
    return this.loadConfig(environment);
  }

  /**
   * Get default configuration path
   */
  private getDefaultConfigPath(): string {
    // Look for config in several locations
    const possiblePaths = [
      process.env.ROUTING_CONFIG_PATH,
      join(process.cwd(), 'config', 'routing.yml'),
      join(process.cwd(), 'routing.yml'),
      join(__dirname, '..', 'config', 'routing.yml'),
    ].filter(Boolean) as string[];

    for (const path of possiblePaths) {
      if (existsSync(path)) {
        return path;
      }
    }

    throw new Error(`Configuration file not found. Searched in: ${possiblePaths.join(', ')}`);
  }

  /**
   * Deep merge two configuration objects
   */
  private mergeConfigs(base: any, override: any): any {
    const result = { ...base };

    for (const [key, value] of Object.entries(override)) {
      if (value && typeof value === 'object' && !Array.isArray(value)) {
        result[key] = this.mergeConfigs(result[key] || {}, value);
      } else {
        result[key] = value;
      }
    }

    return result;
  }

  /**
   * Remove environment-specific sections from config
   */
  private cleanEnvironmentSections(config: any): any {
    const cleaned = { ...config };
    
    // Remove known environment sections
    const environmentSections = ['development', 'staging', 'production'];
    environmentSections.forEach(env => {
      delete cleaned[env];
    });

    return cleaned;
  }

  /**
   * Validate configuration file without loading
   */
  static validateConfigFile(filePath: string): { valid: boolean; errors: string[] } {
    try {
      if (!existsSync(filePath)) {
        return { valid: false, errors: [`Configuration file not found: ${filePath}`] };
      }

      const yamlContent = readFileSync(filePath, 'utf8');
      const rawConfig = parseYaml(yamlContent);
      
      // Remove environment sections for validation
      const manager = new ConfigManager();
      const cleanConfig = manager.cleanEnvironmentSections(rawConfig);
      
      validateRoutingConfig(cleanConfig);
      return { valid: true, errors: [] };
    } catch (error) {
      return {
        valid: false,
        errors: [error instanceof Error ? error.message : 'Unknown validation error'],
      };
    }
  }

  /**
   * Get configuration from environment variables
   */
  static getEnvironmentConfig(): Partial<RoutingConfig> {
    const config: any = {};

    // GitHub configuration
    if (process.env.GITHUB_TOKEN) {
      config.githubToken = process.env.GITHUB_TOKEN;
    }

    // OpenAI configuration
    if (process.env.OPENAI_API_KEY) {
      config.openaiApiKey = process.env.OPENAI_API_KEY;
    }

    // Default repository override
    if (process.env.DEFAULT_REPO) {
      config.defaults = {
        ...config.defaults,
        repo: process.env.DEFAULT_REPO,
      };
    }

    // Project configuration
    if (process.env.DEFAULT_PROJECT_ORG && process.env.DEFAULT_PROJECT_NUMBER) {
      config.defaults = {
        ...config.defaults,
        project: {
          org: process.env.DEFAULT_PROJECT_ORG,
          number: parseInt(process.env.DEFAULT_PROJECT_NUMBER, 10),
        },
      };
    }

    // LLM configuration
    if (process.env.LLM_MODEL) {
      config.llm = {
        ...config.llm,
        model: process.env.LLM_MODEL,
      };
    }

    if (process.env.LLM_MAX_TOKENS) {
      config.llm = {
        ...config.llm,
        maxTokens: parseInt(process.env.LLM_MAX_TOKENS, 10),
      };
    }

    // Duplicate detection configuration
    if (process.env.DUPLICATE_DETECTION_ENABLED) {
      config.duplicateDetection = {
        ...config.duplicateDetection,
        enabled: process.env.DUPLICATE_DETECTION_ENABLED.toLowerCase() === 'true',
      };
    }

    return config;
  }

  /**
   * Merge environment variables with file configuration
   */
  getConfigWithEnvironment(environment?: string): RoutingConfig {
    const fileConfig = this.getConfig(environment);
    const envConfig = ConfigManager.getEnvironmentConfig();
    
    return this.mergeConfigs(fileConfig, envConfig) as RoutingConfig;
  }

  /**
   * Get configuration summary for debugging
   */
  getConfigSummary(): {
    configPath: string;
    rulesCount: number;
    defaultRepo: string;
    hasProject: boolean;
    duplicateDetection: boolean;
  } {
    const config = this.getConfig();
    
    return {
      configPath: this.configPath,
      rulesCount: config.rules.length,
      defaultRepo: config.defaults.repo,
      hasProject: !!config.defaults.project,
      duplicateDetection: config.duplicateDetection?.enabled ?? false,
    };
  }
}

/**
 * Convenience functions for common use cases
 */

/**
 * Load configuration from default location
 */
export function loadRoutingConfig(environment?: string): RoutingConfig {
  const manager = ConfigManager.getInstance();
  return manager.getConfigWithEnvironment(environment);
}

/**
 * Validate a configuration file
 */
export function validateConfigFile(filePath: string): { valid: boolean; errors: string[] } {
  return ConfigManager.validateConfigFile(filePath);
}

/**
 * Create a minimal configuration for testing
 */
export function createTestConfig(overrides?: Partial<RoutingConfig>): RoutingConfig {
  const baseConfig: RoutingConfig = {
    defaults: {
      repo: 'test-org/test-repo',
      labels: ['test'],
    },
    rules: [
      {
        when: {
          keywords: ['test'],
        },
        route: {
          repo: 'test-org/test-repo',
          labels: ['test-label'],
        },
      },
    ],
  };

  if (overrides) {
    return { ...baseConfig, ...overrides } as RoutingConfig;
  }

  return baseConfig;
}