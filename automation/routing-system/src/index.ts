/**
 * Issue Routing System - Main exports
 */

// Core classes
export { IssueRouter } from './router';
export { IssueClassifier } from './classifier';
export { GitHubApiClient } from './github-api';
export { ProjectsApiClient } from './projects-api';
export { ConfigManager, loadRoutingConfig, validateConfigFile, createTestConfig } from './config';

// Types
export type {
  IssueData,
  ClassificationResult,
  ClassificationContext,
  RoutingConfig,
  RoutingRule,
  RouterContext,
  RoutingResult,
  GitHubOperationResult,
  DuplicateCheckResult,
  ProjectInfo,
  ProjectField,
  ProjectFieldOption,
} from './types';

// Validation functions
export { 
  validateRoutingConfig, 
  validateIssueData, 
  validateClassificationResult,
} from './types';

/**
 * Create a configured router instance
 */
export function createRouter(context: RouterContext) {
  return new IssueRouter(context);
}

/**
 * Quick setup function for common use cases
 */
export async function quickRoute(
  issue: IssueData,
  options: {
    configPath?: string;
    environment?: string;
    githubToken: string;
    openaiApiKey?: string;
    routerRepo: string;
    dryRun?: boolean;
    verbose?: boolean;
  }
): Promise<RoutingResult> {
  const config = loadRoutingConfig(options.environment);
  
  const router = createRouter({
    config,
    issue,
    gitHubToken: options.githubToken,
    openAIApiKey: options.openaiApiKey,
    dryRun: options.dryRun,
    verbose: options.verbose,
  });

  return await router.routeIssue(issue, options.routerRepo);
}

// Re-export validation schemas for runtime validation
export { 
  RoutingConfigSchema,
  IssueDataSchema,
  ClassificationResultSchema,
} from './types';