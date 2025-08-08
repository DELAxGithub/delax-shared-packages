/**
 * GitHub API client for issue management
 */

import { Octokit } from '@octokit/rest';
import type {
  ClassificationResult,
  DuplicateCheckResult,
  GitHubOperationResult,
  IssueData,
  RoutingConfig,
} from './types';
import { createHash } from 'crypto';

export class GitHubApiClient {
  private octokit: Octokit;
  private config: RoutingConfig;

  constructor(token: string, config: RoutingConfig) {
    this.octokit = new Octokit({ auth: token });
    this.config = config;
  }

  /**
   * Create a new issue in the target repository
   */
  async createIssue(
    classification: ClassificationResult,
    sourceIssue: IssueData
  ): Promise<GitHubOperationResult> {
    try {
      const [owner, repo] = classification.repo.split('/');
      if (!owner || !repo) {
        throw new Error(`Invalid repository format: ${classification.repo}`);
      }

      // Prepare issue body with metadata
      const enhancedBody = this.enhanceIssueBody(classification.body, sourceIssue);

      const response = await this.octokit.rest.issues.create({
        owner,
        repo,
        title: classification.title,
        body: enhancedBody,
        labels: classification.labels,
        assignees: classification.assignees,
      });

      return {
        success: true,
        issueNumber: response.data.number,
        issueUrl: response.data.html_url,
        details: {
          id: response.data.id,
          nodeId: response.data.node_id,
        },
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error creating issue',
        details: { classification, sourceIssue },
      };
    }
  }

  /**
   * Update an existing issue (for duplicates)
   */
  async updateIssue(
    repo: string,
    issueNumber: number,
    classification: ClassificationResult,
    sourceIssue: IssueData
  ): Promise<GitHubOperationResult> {
    try {
      const [owner, repoName] = repo.split('/');
      if (!owner || !repoName) {
        throw new Error(`Invalid repository format: ${repo}`);
      }

      // Add comment with new information
      const commentBody = this.createUpdateComment(classification, sourceIssue);
      
      const commentResponse = await this.octokit.rest.issues.createComment({
        owner,
        repo: repoName,
        issue_number: issueNumber,
        body: commentBody,
      });

      // Update labels if needed
      const currentIssue = await this.octokit.rest.issues.get({
        owner,
        repo: repoName,
        issue_number: issueNumber,
      });

      const existingLabels = currentIssue.data.labels.map(label => 
        typeof label === 'string' ? label : label.name
      ).filter(Boolean) as string[];

      const newLabels = Array.from(new Set([...existingLabels, ...classification.labels]));

      if (newLabels.length > existingLabels.length) {
        await this.octokit.rest.issues.update({
          owner,
          repo: repoName,
          issue_number: issueNumber,
          labels: newLabels,
        });
      }

      return {
        success: true,
        issueNumber,
        issueUrl: currentIssue.data.html_url,
        details: {
          commentId: commentResponse.data.id,
          labelsAdded: newLabels.length - existingLabels.length,
        },
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error updating issue',
        details: { repo, issueNumber, classification },
      };
    }
  }

  /**
   * Check for duplicate issues
   */
  async checkForDuplicates(
    sourceIssue: IssueData,
    targetRepo: string
  ): Promise<DuplicateCheckResult> {
    const { duplicateDetection } = this.config;
    if (!duplicateDetection?.enabled) {
      return {
        isDuplicate: false,
        method: 'none',
        confidence: 0,
      };
    }

    try {
      // Check by Slack permalink first (most reliable)
      if (sourceIssue.slackPermalink && 
          (duplicateDetection.method === 'slack-permalink' || duplicateDetection.method === 'both')) {
        const slackResult = await this.findBySlackPermalink(sourceIssue.slackPermalink, targetRepo);
        if (slackResult.isDuplicate) {
          return slackResult;
        }
      }

      // Check by content hash
      if (duplicateDetection.method === 'content-hash' || duplicateDetection.method === 'both') {
        const hashResult = await this.findByContentHash(sourceIssue, targetRepo);
        if (hashResult.isDuplicate) {
          return hashResult;
        }
      }

      return {
        isDuplicate: false,
        method: 'none',
        confidence: 0,
      };
    } catch (error) {
      console.warn('Duplicate check failed:', error);
      return {
        isDuplicate: false,
        method: 'none',
        confidence: 0,
      };
    }
  }

  /**
   * Find issues by Slack permalink
   */
  private async findBySlackPermalink(
    permalink: string,
    repo: string
  ): Promise<DuplicateCheckResult> {
    const [owner, repoName] = repo.split('/');
    if (!owner || !repoName) {
      return { isDuplicate: false, method: 'slack-permalink', confidence: 0 };
    }

    try {
      // Search for issues containing the Slack permalink
      const response = await this.octokit.rest.search.issuesAndPullRequests({
        q: `repo:${repo} "${permalink}" in:body`,
        sort: 'created',
        order: 'desc',
        per_page: 5,
      });

      if (response.data.total_count > 0) {
        const issue = response.data.items[0];
        return {
          isDuplicate: true,
          existingIssue: {
            number: issue.number,
            url: issue.html_url,
            repo,
          },
          method: 'slack-permalink',
          confidence: 0.95, // Very high confidence for permalink matches
        };
      }

      return { isDuplicate: false, method: 'slack-permalink', confidence: 0 };
    } catch (error) {
      console.warn('Slack permalink search failed:', error);
      return { isDuplicate: false, method: 'slack-permalink', confidence: 0 };
    }
  }

  /**
   * Find issues by content hash
   */
  private async findByContentHash(
    sourceIssue: IssueData,
    repo: string
  ): Promise<DuplicateCheckResult> {
    const contentHash = this.generateContentHash(sourceIssue);
    const [owner, repoName] = repo.split('/');
    if (!owner || !repoName) {
      return { isDuplicate: false, method: 'content-hash', confidence: 0 };
    }

    try {
      // Search for issues with the same content hash in their body
      const response = await this.octokit.rest.search.issuesAndPullRequests({
        q: `repo:${repo} "${contentHash}" in:body`,
        sort: 'created',
        order: 'desc',
        per_page: 5,
      });

      if (response.data.total_count > 0) {
        const issue = response.data.items[0];
        return {
          isDuplicate: true,
          existingIssue: {
            number: issue.number,
            url: issue.html_url,
            repo,
          },
          method: 'content-hash',
          confidence: 0.85, // High confidence for hash matches
        };
      }

      return { isDuplicate: false, method: 'content-hash', confidence: 0 };
    } catch (error) {
      console.warn('Content hash search failed:', error);
      return { isDuplicate: false, method: 'content-hash', confidence: 0 };
    }
  }

  /**
   * Generate content hash for duplicate detection
   */
  private generateContentHash(issue: IssueData): string {
    const content = `${issue.title}\n${issue.body}`.toLowerCase().trim();
    return createHash('sha256').update(content).digest('hex').substring(0, 16);
  }

  /**
   * Enhance issue body with routing metadata
   */
  private enhanceIssueBody(body: string, sourceIssue: IssueData): string {
    const metadata = [
      '<!-- Routing Metadata -->',
      `**Original Issue:** ${sourceIssue.url}`,
      `**Author:** @${sourceIssue.author}`,
      `**Created:** ${sourceIssue.createdAt}`,
    ];

    if (sourceIssue.slackPermalink) {
      metadata.push(`**Slack Thread:** ${sourceIssue.slackPermalink}`);
    }

    const contentHash = this.generateContentHash(sourceIssue);
    metadata.push(`**Content Hash:** \`${contentHash}\``);
    
    metadata.push('', '---', '');

    return metadata.join('\n') + body;
  }

  /**
   * Create update comment for duplicate issues
   */
  private createUpdateComment(
    classification: ClassificationResult,
    sourceIssue: IssueData
  ): string {
    const lines = [
      '## 🔄 Duplicate Issue Update',
      '',
      `A similar issue was reported: ${sourceIssue.url}`,
      `**Reporter:** @${sourceIssue.author}`,
      `**Date:** ${sourceIssue.createdAt}`,
    ];

    if (sourceIssue.slackPermalink) {
      lines.push(`**Slack Thread:** ${sourceIssue.slackPermalink}`);
    }

    if (classification.reasoning) {
      lines.push('', '**Classification Notes:**', classification.reasoning);
    }

    lines.push('', '---');
    lines.push('*This comment was automatically generated by the routing system.*');

    return lines.join('\n');
  }

  /**
   * Close router issue after successful routing
   */
  async closeRouterIssue(
    routerRepo: string,
    issueNumber: number,
    targetUrl: string
  ): Promise<GitHubOperationResult> {
    try {
      const [owner, repoName] = routerRepo.split('/');
      if (!owner || !repoName) {
        throw new Error(`Invalid repository format: ${routerRepo}`);
      }

      // Add comment with routing information
      await this.octokit.rest.issues.createComment({
        owner,
        repo: repoName,
        issue_number: issueNumber,
        body: `🎯 **Issue Routed Successfully**\n\nThis issue has been routed to: ${targetUrl}\n\n*Automatically closed by routing system*`,
      });

      // Close the issue
      const response = await this.octokit.rest.issues.update({
        owner,
        repo: repoName,
        issue_number: issueNumber,
        state: 'closed',
        labels: ['routed', 'automated'],
      });

      return {
        success: true,
        issueNumber,
        issueUrl: response.data.html_url,
        details: { closedAt: response.data.closed_at },
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error closing router issue',
        details: { routerRepo, issueNumber, targetUrl },
      };
    }
  }

  /**
   * Get repository information
   */
  async getRepositoryInfo(repo: string): Promise<{ exists: boolean; isAccessible: boolean }> {
    try {
      const [owner, repoName] = repo.split('/');
      if (!owner || !repoName) {
        return { exists: false, isAccessible: false };
      }

      await this.octokit.rest.repos.get({ owner, repo: repoName });
      return { exists: true, isAccessible: true };
    } catch (error) {
      return { exists: false, isAccessible: false };
    }
  }

  /**
   * Get existing labels for a repository
   */
  async getRepositoryLabels(repo: string): Promise<string[]> {
    try {
      const [owner, repoName] = repo.split('/');
      if (!owner || !repoName) {
        return [];
      }

      const response = await this.octokit.rest.issues.listLabelsForRepo({
        owner,
        repo: repoName,
        per_page: 100,
      });

      return response.data.map(label => label.name);
    } catch (error) {
      console.warn(`Failed to get labels for ${repo}:`, error);
      return [];
    }
  }
}