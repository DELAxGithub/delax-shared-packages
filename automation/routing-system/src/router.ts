/**
 * Main routing logic - orchestrates rule-based + LLM classification
 */

import { IssueClassifier } from './classifier';
import { GitHubApiClient } from './github-api';
import { ProjectsApiClient } from './projects-api';
import type {
  ClassificationContext,
  ClassificationResult,
  IssueData,
  RouterContext,
  RoutingConfig,
  RoutingResult,
  RoutingRule,
} from './types';

export class IssueRouter {
  private classifier: IssueClassifier;
  private githubClient: GitHubApiClient;
  private projectsClient: ProjectsApiClient;
  private config: RoutingConfig;
  private verbose: boolean;

  constructor(context: RouterContext) {
    this.config = context.config;
    this.verbose = context.verbose ?? false;
    
    this.classifier = new IssueClassifier(context.config, context.openAIApiKey);
    this.githubClient = new GitHubApiClient(context.gitHubToken, context.config);
    this.projectsClient = new ProjectsApiClient(context.gitHubToken);
  }

  /**
   * Route an issue through the complete pipeline
   */
  async routeIssue(issue: IssueData, routerRepo: string): Promise<RoutingResult> {
    const startTime = Date.now();
    const logs: string[] = [];
    
    try {
      this.log(logs, `Starting routing for issue #${issue.number}: "${issue.title}"`);

      // Step 1: Apply rule-based routing
      this.log(logs, 'Step 1: Applying rule-based routing...');
      const ruleResult = this.applyRoutingRules(issue);
      
      if (ruleResult) {
        this.log(logs, `✅ Rule match found: ${ruleResult.repo}`);
      } else {
        this.log(logs, '❌ No matching rules found, proceeding to LLM classification');
      }

      // Step 2: LLM classification (if no rule match or to enhance rule result)
      let classification: ClassificationResult;
      
      if (ruleResult) {
        // Enhance rule result with LLM if needed
        classification = await this.enhanceWithLLM(ruleResult, issue);
        this.log(logs, '✅ Rule result enhanced with LLM');
      } else {
        // Full LLM classification
        this.log(logs, 'Step 2: Running LLM classification...');
        classification = await this.runLLMClassification(issue);
        this.log(logs, `✅ LLM classification complete: ${classification.repo} (confidence: ${classification.confidence})`);
      }

      // Step 3: Duplicate detection
      this.log(logs, 'Step 3: Checking for duplicates...');
      const duplicateCheck = await this.githubClient.checkForDuplicates(issue, classification.repo);
      
      if (duplicateCheck.isDuplicate) {
        this.log(logs, `⚠️ Duplicate found: ${duplicateCheck.existingIssue?.url}`);
      } else {
        this.log(logs, '✅ No duplicates found');
      }

      // Step 4: Execute GitHub operations
      this.log(logs, 'Step 4: Executing GitHub operations...');
      const githubOperation = duplicateCheck.isDuplicate
        ? await this.handleDuplicateIssue(duplicateCheck, classification, issue)
        : await this.createNewIssue(classification, issue);

      if (githubOperation.success) {
        this.log(logs, `✅ GitHub operation successful: ${githubOperation.issueUrl}`);
      } else {
        this.log(logs, `❌ GitHub operation failed: ${githubOperation.error}`);
      }

      // Step 5: Add to project (if configured and operation succeeded)
      if (githubOperation.success && this.config.defaults.project) {
        this.log(logs, 'Step 5: Adding to project...');
        await this.addToProject(classification, githubOperation, issue);
        this.log(logs, '✅ Added to project');
      }

      // Step 6: Close router issue
      if (githubOperation.success && githubOperation.issueUrl) {
        this.log(logs, 'Step 6: Closing router issue...');
        await this.githubClient.closeRouterIssue(routerRepo, issue.number, githubOperation.issueUrl);
        this.log(logs, '✅ Router issue closed');
      }

      const executionTime = Date.now() - startTime;
      this.log(logs, `🎉 Routing completed successfully in ${executionTime}ms`);

      return {
        success: githubOperation.success,
        classification,
        duplicateCheck,
        githubOperation,
        executionTime,
        logs,
      };

    } catch (error) {
      const executionTime = Date.now() - startTime;
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      
      this.log(logs, `❌ Routing failed: ${errorMessage}`);

      return {
        success: false,
        classification: this.createFallbackClassification(issue),
        duplicateCheck: { isDuplicate: false, method: 'none', confidence: 0 },
        githubOperation: { success: false, error: errorMessage },
        executionTime,
        logs,
        error: errorMessage,
      };
    }
  }

  /**
   * Apply rule-based routing logic
   */
  private applyRoutingRules(issue: IssueData): ClassificationResult | null {
    for (const rule of this.config.rules) {
      if (this.matchesRule(issue, rule)) {
        return {
          repo: rule.route.repo,
          title: issue.title,
          body: issue.body,
          labels: [...(rule.route.labels ?? []), ...issue.labels],
          assignees: rule.route.assignees ?? [],
          priority: rule.route.priority ?? 'medium',
          confidence: 0.95, // High confidence for rule matches
          reasoning: `Matched routing rule: ${JSON.stringify(rule.when)}`,
          projectFields: rule.route.projectFields ?? {},
        };
      }
    }
    
    return null;
  }

  /**
   * Check if an issue matches a routing rule
   */
  private matchesRule(issue: IssueData, rule: RoutingRule): boolean {
    const { when } = rule;
    
    // Check keywords in title and body
    if (when.keywords) {
      const content = `${issue.title} ${issue.body}`.toLowerCase();
      const hasKeyword = when.keywords.some(keyword => 
        content.includes(keyword.toLowerCase())
      );
      if (!hasKeyword) return false;
    }

    // Check title patterns
    if (when.titlePatterns) {
      const hasPattern = when.titlePatterns.some(pattern => {
        const regex = new RegExp(pattern, 'i');
        return regex.test(issue.title);
      });
      if (!hasPattern) return false;
    }

    // Check body patterns
    if (when.bodyPatterns) {
      const hasPattern = when.bodyPatterns.some(pattern => {
        const regex = new RegExp(pattern, 'i');
        return regex.test(issue.body);
      });
      if (!hasPattern) return false;
    }

    // Check existing labels
    if (when.labels) {
      const hasLabel = when.labels.some(label =>
        issue.labels.some(issueLabel => 
          issueLabel.toLowerCase() === label.toLowerCase()
        )
      );
      if (!hasLabel) return false;
    }

    // Check Slack channels (if available in source meta)
    if (when.channels && issue.sourceMeta?.channel) {
      const channel = String(issue.sourceMeta.channel);
      const hasChannel = when.channels.some(ruleChannel =>
        channel.toLowerCase().includes(ruleChannel.toLowerCase())
      );
      if (!hasChannel) return false;
    }

    return true;
  }

  /**
   * Enhance rule result with LLM classification
   */
  private async enhanceWithLLM(
    ruleResult: ClassificationResult,
    issue: IssueData
  ): Promise<ClassificationResult> {
    try {
      const context: ClassificationContext = {
        issue,
        availableRepos: [ruleResult.repo], // Only consider the rule-matched repo
        existingLabels: {
          [ruleResult.repo]: await this.githubClient.getRepositoryLabels(ruleResult.repo),
        },
        organizationContext: `Rule-matched repository: ${ruleResult.repo}`,
      };

      const llmResult = await this.classifier.classify(context);
      
      // Merge rule result with LLM enhancements
      return {
        ...ruleResult,
        title: llmResult.title.length > ruleResult.title.length ? llmResult.title : ruleResult.title,
        body: llmResult.body.length > ruleResult.body.length ? llmResult.body : ruleResult.body,
        labels: Array.from(new Set([...ruleResult.labels, ...llmResult.labels])),
        assignees: ruleResult.assignees.length > 0 ? ruleResult.assignees : llmResult.assignees,
        reasoning: `${ruleResult.reasoning} | LLM enhancement: ${llmResult.reasoning}`,
        confidence: Math.max(0.8, (ruleResult.confidence + llmResult.confidence) / 2),
        projectFields: { ...llmResult.projectFields, ...ruleResult.projectFields },
      };
    } catch (error) {
      // If LLM enhancement fails, return the rule result as-is
      console.warn('LLM enhancement failed, using rule result:', error);
      return ruleResult;
    }
  }

  /**
   * Run full LLM classification
   */
  private async runLLMClassification(issue: IssueData): Promise<ClassificationResult> {
    const availableRepos = this.classifier.getAvailableRepos();
    const existingLabels: Record<string, string[]> = {};
    
    // Fetch labels for all available repositories
    for (const repo of availableRepos) {
      existingLabels[repo] = await this.githubClient.getRepositoryLabels(repo);
    }

    const context: ClassificationContext = {
      issue,
      availableRepos,
      existingLabels,
      organizationContext: this.generateOrganizationContext(),
    };

    return await this.classifier.classify(context);
  }

  /**
   * Generate organization context for LLM
   */
  private generateOrganizationContext(): string {
    const repos = this.classifier.getAvailableRepos();
    const repoDescriptions = repos.map(repo => {
      const labels = this.classifier.getRepoLabels(repo);
      return `${repo}: Common labels [${labels.join(', ')}]`;
    });

    return `Available repositories:\n${repoDescriptions.join('\n')}`;
  }

  /**
   * Handle duplicate issue (update existing)
   */
  private async handleDuplicateIssue(
    duplicateCheck: any,
    classification: ClassificationResult,
    sourceIssue: IssueData
  ) {
    if (!duplicateCheck.existingIssue) {
      throw new Error('Duplicate check result missing existing issue info');
    }

    return await this.githubClient.updateIssue(
      duplicateCheck.existingIssue.repo,
      duplicateCheck.existingIssue.number,
      classification,
      sourceIssue
    );
  }

  /**
   * Create new issue in target repository
   */
  private async createNewIssue(
    classification: ClassificationResult,
    sourceIssue: IssueData
  ) {
    return await this.githubClient.createIssue(classification, sourceIssue);
  }

  /**
   * Add issue to GitHub Projects v2
   */
  private async addToProject(
    classification: ClassificationResult,
    githubOperation: any,
    sourceIssue: IssueData
  ): Promise<void> {
    if (!this.config.defaults.project || !githubOperation.issueNumber) {
      return;
    }

    try {
      const { org, number } = this.config.defaults.project;
      
      // Get project info
      const project = await this.projectsClient.getProject(org, number);
      if (!project) {
        console.warn(`Project ${org}/${number} not found`);
        return;
      }

      // Get issue node ID
      const [owner, repo] = classification.repo.split('/');
      const issueNodeId = await this.projectsClient.getIssueNodeId(
        owner,
        repo,
        githubOperation.issueNumber
      );
      
      if (!issueNodeId) {
        console.warn('Failed to get issue node ID');
        return;
      }

      // Check if already in project
      const alreadyInProject = await this.projectsClient.isIssueInProject(
        project.id,
        issueNodeId
      );
      
      if (alreadyInProject) {
        console.log('Issue already in project');
        return;
      }

      // Add to project with field values
      const projectFields = ProjectsApiClient.createDefaultProjectFields(classification);
      const updatedClassification = {
        ...classification,
        projectFields,
      };

      await this.projectsClient.addIssueToProject(
        project.id,
        issueNodeId,
        updatedClassification
      );
    } catch (error) {
      console.warn('Failed to add to project:', error);
    }
  }

  /**
   * Create fallback classification for error cases
   */
  private createFallbackClassification(issue: IssueData): ClassificationResult {
    return {
      repo: this.config.defaults.repo,
      title: issue.title,
      body: issue.body,
      labels: [...this.config.defaults.labels, 'routing-failed'],
      assignees: [],
      priority: 'medium',
      confidence: 0.0,
      reasoning: 'Fallback classification due to routing failure',
      projectFields: {},
    };
  }

  /**
   * Log messages with optional verbose output
   */
  private log(logs: string[], message: string): void {
    const timestamp = new Date().toISOString();
    const logEntry = `[${timestamp}] ${message}`;
    
    logs.push(logEntry);
    
    if (this.verbose) {
      console.log(logEntry);
    }
  }

  /**
   * Validate routing configuration
   */
  static validateConfig(config: RoutingConfig): { valid: boolean; errors: string[] } {
    const errors: string[] = [];

    // Check defaults
    if (!config.defaults.repo) {
      errors.push('defaults.repo is required');
    }

    // Check rules
    if (!config.rules || config.rules.length === 0) {
      errors.push('At least one routing rule is required');
    }

    config.rules.forEach((rule, index) => {
      if (!rule.route.repo) {
        errors.push(`Rule ${index}: route.repo is required`);
      }
      
      if (!rule.when || Object.keys(rule.when).length === 0) {
        errors.push(`Rule ${index}: at least one 'when' condition is required`);
      }
    });

    return {
      valid: errors.length === 0,
      errors,
    };
  }
}