/**
 * LLM-based issue classification system
 */

import { createClaudeIntegration, type ClaudeConfig } from '@delax/claude-integration';
import type {
  ClassificationContext,
  ClassificationResult,
  IssueData,
  RoutingConfig,
} from './types';

export class IssueClassifier {
  private claude: ReturnType<typeof createClaudeIntegration>;
  private config: RoutingConfig;

  constructor(config: RoutingConfig, apiKey?: string) {
    this.config = config;
    
    const claudeConfig: ClaudeConfig = {
      model: config.llm?.model ?? 'claude-3-sonnet',
      apiKey,
      maxTokens: config.llm?.maxTokens ?? 4000,
      temperature: config.llm?.temperature ?? 0.1,
    };
    
    this.claude = createClaudeIntegration(claudeConfig);
  }

  /**
   * Classify an issue and determine routing destination
   */
  async classify(context: ClassificationContext): Promise<ClassificationResult> {
    try {
      const prompt = this.buildClassificationPrompt(context);
      
      // For now, we'll create a mock implementation since the original library
      // focuses on error analysis. We'll need to extend it for issue classification.
      const response = await this.callClaudeForClassification(prompt);
      
      return this.parseClassificationResponse(response, context);
    } catch (error) {
      // Fallback to default repository with low confidence
      return this.createFallbackClassification(context.issue);
    }
  }

  /**
   * Build classification prompt for Claude
   */
  private buildClassificationPrompt(context: ClassificationContext): string {
    const { issue, availableRepos, existingLabels, organizationContext } = context;
    
    const repoInfo = availableRepos.map(repo => {
      const labels = existingLabels[repo] ?? [];
      return `- ${repo}: [${labels.join(', ')}]`;
    }).join('\n');

    return `
You are an expert at categorizing GitHub issues for a multi-repository organization.

## Issue to Classify
**Title:** ${issue.title}
**Body:** ${issue.body}
**Author:** ${issue.author}
**Existing Labels:** ${issue.labels.join(', ') || 'none'}

## Organization Context
${organizationContext ?? 'No specific context provided'}

## Available Repositories and Their Common Labels
${repoInfo}

## Classification Task
Analyze the issue and provide a JSON response with the following structure:
\`\`\`json
{
  "repo": "owner/repo-name",
  "title": "refined issue title if needed",
  "body": "enhanced or cleaned issue body if needed",
  "labels": ["label1", "label2"],
  "assignees": ["username1"],
  "priority": "low|medium|high|critical",
  "confidence": 0.85,
  "reasoning": "Brief explanation of classification logic",
  "projectFields": {
    "Status": "Todo",
    "Size": "Medium"
  }
}
\`\`\`

## Classification Guidelines
1. **Repository Selection**: Choose the most appropriate repository based on:
   - Technical domain (iOS, backend, frontend, etc.)
   - Issue content and keywords
   - Mentioned technologies or frameworks

2. **Label Assignment**: 
   - Use existing repository labels when possible
   - Add appropriate type labels (bug, feature, documentation, etc.)
   - Include technology-specific labels
   - Consider urgency and complexity labels

3. **Priority Assessment**:
   - **critical**: System down, security vulnerabilities, blocking issues
   - **high**: Important features, significant bugs affecting users
   - **medium**: Standard features, non-blocking bugs
   - **low**: Nice-to-have features, minor improvements

4. **Confidence Scoring**:
   - 0.9+: Very clear categorization with obvious keywords/context
   - 0.7-0.9: Good categorization with reasonable indicators
   - 0.5-0.7: Moderate confidence, some ambiguity
   - <0.5: Low confidence, unclear categorization

5. **Title/Body Enhancement**:
   - Fix typos and formatting
   - Add missing technical details if obvious
   - Clarify ambiguous descriptions
   - Keep original meaning intact

6. **Assignee Suggestions**:
   - Only suggest if there are clear domain experts
   - Consider team structure and expertise areas
   - Leave empty if uncertain

Respond with valid JSON only, no additional text.`;
  }

  /**
   * Call Claude API for issue classification
   * This is a simplified implementation - in reality, we'd need to extend
   * the existing claude-integration library to support this use case
   */
  private async callClaudeForClassification(prompt: string): Promise<string> {
    // For now, we'll use the existing generateFix method with adapted context
    // In a real implementation, we'd extend the library with a classify method
    const mockErrorContext = {
      language: 'typescript' as const,
      errorType: 'issue-classification',
      errorMessage: prompt,
      filePath: 'routing-request',
    };

    const result = await this.claude.generateFix(mockErrorContext);
    
    if (result.success && result.suggestions.length > 0) {
      return result.suggestions[0].content;
    }
    
    throw new Error(result.error ?? 'Classification failed');
  }

  /**
   * Parse Claude's classification response
   */
  private parseClassificationResponse(
    response: string,
    context: ClassificationContext
  ): ClassificationResult {
    try {
      // Extract JSON from response (Claude might return it wrapped in markdown)
      const jsonMatch = response.match(/```json\s*([\s\S]*?)\s*```/) 
        ?? response.match(/\{[\s\S]*\}/);
      
      if (!jsonMatch) {
        throw new Error('No JSON found in response');
      }

      const parsed = JSON.parse(jsonMatch[0] || jsonMatch[1]);
      
      // Validate and sanitize the response
      return {
        repo: this.validateRepo(parsed.repo, context.availableRepos),
        title: parsed.title || context.issue.title,
        body: parsed.body || context.issue.body,
        labels: Array.isArray(parsed.labels) ? parsed.labels : [],
        assignees: Array.isArray(parsed.assignees) ? parsed.assignees : [],
        priority: this.validatePriority(parsed.priority),
        confidence: Math.max(0, Math.min(1, Number(parsed.confidence) || 0.5)),
        reasoning: parsed.reasoning || 'LLM classification',
        projectFields: parsed.projectFields || {},
      };
    } catch (error) {
      console.warn('Failed to parse classification response:', error);
      return this.createFallbackClassification(context.issue);
    }
  }

  /**
   * Validate repository name against available repos
   */
  private validateRepo(repo: string, availableRepos: string[]): string {
    if (availableRepos.includes(repo)) {
      return repo;
    }
    
    // Try to find a partial match
    const match = availableRepos.find(r => 
      r.toLowerCase().includes(repo.toLowerCase()) ||
      repo.toLowerCase().includes(r.toLowerCase())
    );
    
    return match ?? this.config.defaults.repo;
  }

  /**
   * Validate priority level
   */
  private validatePriority(priority: string): 'low' | 'medium' | 'high' | 'critical' {
    const validPriorities = ['low', 'medium', 'high', 'critical'] as const;
    return validPriorities.includes(priority as any) 
      ? (priority as any) 
      : 'medium';
  }

  /**
   * Create fallback classification when LLM fails
   */
  private createFallbackClassification(issue: IssueData): ClassificationResult {
    return {
      repo: this.config.defaults.repo,
      title: issue.title,
      body: issue.body,
      labels: [...this.config.defaults.labels, 'triage-needed'],
      assignees: [],
      priority: 'medium',
      confidence: 0.1, // Very low confidence for fallback
      reasoning: 'Fallback classification - LLM unavailable',
      projectFields: {},
    };
  }

  /**
   * Get available repositories from config
   */
  getAvailableRepos(): string[] {
    const repos = new Set<string>();
    
    // Add default repo
    repos.add(this.config.defaults.repo);
    
    // Add repos from rules
    this.config.rules.forEach(rule => {
      repos.add(rule.route.repo);
    });
    
    return Array.from(repos);
  }

  /**
   * Get typical labels for a repository based on rules
   */
  getRepoLabels(repo: string): string[] {
    const labels = new Set<string>();
    
    this.config.rules.forEach(rule => {
      if (rule.route.repo === repo && rule.route.labels) {
        rule.route.labels.forEach(label => labels.add(label));
      }
    });
    
    return Array.from(labels);
  }
}