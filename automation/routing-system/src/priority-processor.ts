/**
 * Intelligent Processing Priority System
 * Manages API usage by prioritizing critical issues and deferring low-priority ones
 */

import type { IssueData, ClassificationResult } from './types';
import type { UsageCheckResult } from './api-usage-monitor';

export interface PriorityConfig {
  emergencyKeywords: string[];
  highPriorityKeywords: string[];
  lowPriorityKeywords: string[];
  productionRepos: string[];
  criticalLabels: string[];
  deferralThresholds: {
    apiUsagePercentage: number; // Defer low-priority when usage > this %
    emergencyOnlyPercentage: number; // Only process emergencies when usage > this %
  };
  batchProcessing: {
    enabled: boolean;
    maxBatchSize: number;
    similarityThreshold: number; // 0.0-1.0
    batchWindowMinutes: number;
  };
}

export interface PriorityScore {
  overall: number; // 0.0-1.0
  urgency: number; // 0.0-1.0
  importance: number; // 0.0-1.0
  businessImpact: number; // 0.0-1.0
  reasoning: string[];
  category: 'emergency' | 'high' | 'medium' | 'low' | 'deferred';
  processingDecision: 'immediate' | 'batch' | 'deferred' | 'blocked';
  estimatedApiCost: number;
}

export interface BatchCandidate {
  issue: IssueData;
  priority: PriorityScore;
  similarity?: number;
  addedAt: Date;
}

export class PriorityProcessor {
  private config: PriorityConfig;
  private batchQueue: Map<string, BatchCandidate[]> = new Map();
  private deferralQueue: BatchCandidate[] = [];

  constructor(config: PriorityConfig) {
    this.config = config;
  }

  /**
   * Analyze issue priority and determine processing strategy
   */
  analyzePriority(issue: IssueData, currentUsage?: UsageCheckResult): PriorityScore {
    const urgency = this.calculateUrgency(issue);
    const importance = this.calculateImportance(issue);
    const businessImpact = this.calculateBusinessImpact(issue);
    
    const overall = (urgency * 0.4) + (importance * 0.3) + (businessImpact * 0.3);
    
    const reasoning: string[] = [];
    let category: PriorityScore['category'] = 'medium';
    let processingDecision: PriorityScore['processingDecision'] = 'immediate';

    // Determine category based on scoring
    if (urgency >= 0.9 || this.isEmergencyIssue(issue)) {
      category = 'emergency';
      reasoning.push('Emergency: Critical system issue or security vulnerability');
    } else if (overall >= 0.8) {
      category = 'high';
      reasoning.push('High priority: Significant impact on users or business operations');
    } else if (overall >= 0.5) {
      category = 'medium';
      reasoning.push('Medium priority: Standard issue with moderate impact');
    } else {
      category = 'low';
      reasoning.push('Low priority: Enhancement or minor issue');
    }

    // Adjust processing decision based on API usage
    if (currentUsage) {
      const dailyUsage = Math.max(
        currentUsage.currentUsage.daily.calls.percentage,
        currentUsage.currentUsage.daily.tokens.percentage,
        currentUsage.currentUsage.daily.cost.percentage
      );

      if (dailyUsage >= this.config.deferralThresholds.emergencyOnlyPercentage) {
        if (category !== 'emergency') {
          processingDecision = 'blocked';
          reasoning.push(`API usage at ${Math.round(dailyUsage * 100)}% - emergency issues only`);
        }
      } else if (dailyUsage >= this.config.deferralThresholds.apiUsagePercentage) {
        if (category === 'low') {
          processingDecision = 'deferred';
          reasoning.push(`API usage at ${Math.round(dailyUsage * 100)}% - deferring low priority`);
        } else if (category === 'medium' && this.config.batchProcessing.enabled) {
          processingDecision = 'batch';
          reasoning.push('Medium priority queued for batch processing');
        }
      } else if (category === 'medium' && this.config.batchProcessing.enabled) {
        // Check if we can batch this with similar issues
        const similarIssues = this.findSimilarIssues(issue);
        if (similarIssues.length >= 2) {
          processingDecision = 'batch';
          reasoning.push(`Found ${similarIssues.length} similar issues - batching for efficiency`);
        }
      }
    }

    const estimatedApiCost = this.estimateApiCost(issue, processingDecision);

    return {
      overall,
      urgency,
      importance,
      businessImpact,
      reasoning,
      category,
      processingDecision,
      estimatedApiCost
    };
  }

  /**
   * Add issue to appropriate processing queue
   */
  queueIssue(issue: IssueData, priority: PriorityScore): void {
    const candidate: BatchCandidate = {
      issue,
      priority,
      addedAt: new Date()
    };

    switch (priority.processingDecision) {
      case 'immediate':
        // Process immediately - no queueing needed
        break;
        
      case 'batch':
        this.addToBatchQueue(candidate);
        break;
        
      case 'deferred':
        this.deferralQueue.push(candidate);
        this.cleanupDeferralQueue();
        break;
        
      case 'blocked':
        // Don't queue blocked issues
        console.log(`🚫 Issue blocked due to API limits: ${issue.title}`);
        break;
    }
  }

  /**
   * Get next batch of issues ready for processing
   */
  getNextBatch(maxBatchSize?: number): BatchCandidate[] {
    const batchSize = maxBatchSize || this.config.batchProcessing.maxBatchSize;
    const cutoffTime = new Date();
    cutoffTime.setMinutes(cutoffTime.getMinutes() - this.config.batchProcessing.batchWindowMinutes);

    // Find ready batches (issues that have been waiting long enough)
    const readyBatches: BatchCandidate[] = [];
    
    for (const [category, candidates] of this.batchQueue.entries()) {
      const readyCandidates = candidates.filter(c => c.addedAt <= cutoffTime);
      
      if (readyCandidates.length >= 2 || readyCandidates.some(c => c.addedAt <= cutoffTime)) {
        readyBatches.push(...readyCandidates.slice(0, batchSize));
        
        // Remove processed candidates from queue
        const remainingCandidates = candidates.filter(c => !readyCandidates.includes(c));
        if (remainingCandidates.length > 0) {
          this.batchQueue.set(category, remainingCandidates);
        } else {
          this.batchQueue.delete(category);
        }
        
        if (readyBatches.length >= batchSize) {
          break;
        }
      }
    }

    return readyBatches;
  }

  /**
   * Process deferred issues when usage allows
   */
  processDeferredQueue(currentUsage: UsageCheckResult): BatchCandidate[] {
    const dailyUsage = Math.max(
      currentUsage.currentUsage.daily.calls.percentage,
      currentUsage.currentUsage.daily.tokens.percentage,
      currentUsage.currentUsage.daily.cost.percentage
    );

    if (dailyUsage < this.config.deferralThresholds.apiUsagePercentage) {
      // Process some deferred issues
      const toProcess = this.deferralQueue.splice(0, 5); // Process up to 5 deferred issues
      console.log(`📤 Processing ${toProcess.length} deferred issues (usage: ${Math.round(dailyUsage * 100)}%)`);
      return toProcess;
    }

    return [];
  }

  /**
   * Calculate urgency score based on issue content
   */
  private calculateUrgency(issue: IssueData): number {
    let score = 0.3; // Base urgency

    const content = `${issue.title} ${issue.body}`.toLowerCase();
    
    // Emergency keywords
    if (this.config.emergencyKeywords.some(keyword => content.includes(keyword.toLowerCase()))) {
      score += 0.6;
    }

    // High priority keywords
    if (this.config.highPriorityKeywords.some(keyword => content.includes(keyword.toLowerCase()))) {
      score += 0.3;
    }

    // Labels indicating urgency
    if (this.config.criticalLabels.some(label => issue.labels.includes(label))) {
      score += 0.4;
    }

    // Recent creation (within last 2 hours = more urgent)
    const createdAt = new Date(issue.createdAt);
    const hoursAgo = (Date.now() - createdAt.getTime()) / (1000 * 60 * 60);
    if (hoursAgo <= 2) {
      score += 0.2;
    }

    return Math.min(score, 1.0);
  }

  /**
   * Calculate importance score based on business impact
   */
  private calculateImportance(issue: IssueData): number {
    let score = 0.4; // Base importance

    const content = `${issue.title} ${issue.body}`.toLowerCase();

    // Production repository issues are more important
    const repoName = issue.sourceMeta?.repository as string || '';
    if (this.config.productionRepos.some(repo => repoName.includes(repo))) {
      score += 0.3;
    }

    // User-reported issues (not system-generated) are more important
    if (!issue.author.includes('bot') && !issue.author.includes('action')) {
      score += 0.2;
    }

    // Issues with multiple assignees indicate importance
    if (issue.assignees.length > 1) {
      score += 0.1;
    }

    return Math.min(score, 1.0);
  }

  /**
   * Calculate business impact score
   */
  private calculateBusinessImpact(issue: IssueData): number {
    let score = 0.3; // Base business impact

    const content = `${issue.title} ${issue.body}`.toLowerCase();

    // User-facing feature issues have high business impact
    const userFacingKeywords = ['ui', 'user', 'interface', 'experience', 'usability', 'accessibility'];
    if (userFacingKeywords.some(keyword => content.includes(keyword))) {
      score += 0.2;
    }

    // Data/security issues have high business impact
    const criticalKeywords = ['data loss', 'security', 'vulnerability', 'crash', 'corruption'];
    if (criticalKeywords.some(keyword => content.includes(keyword))) {
      score += 0.4;
    }

    // Performance issues affect user experience
    const performanceKeywords = ['slow', 'performance', 'timeout', 'hang', 'freeze'];
    if (performanceKeywords.some(keyword => content.includes(keyword))) {
      score += 0.3;
    }

    return Math.min(score, 1.0);
  }

  /**
   * Check if issue qualifies as emergency
   */
  private isEmergencyIssue(issue: IssueData): boolean {
    const content = `${issue.title} ${issue.body}`.toLowerCase();
    
    const emergencyPatterns = [
      'production down',
      'service down', 
      'data loss',
      'security breach',
      'critical vulnerability',
      'system crash',
      'cannot access'
    ];

    return emergencyPatterns.some(pattern => content.includes(pattern)) ||
           this.config.criticalLabels.some(label => issue.labels.includes(label));
  }

  /**
   * Find similar issues for batching
   */
  private findSimilarIssues(issue: IssueData): BatchCandidate[] {
    const similar: BatchCandidate[] = [];
    
    for (const candidates of this.batchQueue.values()) {
      for (const candidate of candidates) {
        const similarity = this.calculateSimilarity(issue, candidate.issue);
        if (similarity >= this.config.batchProcessing.similarityThreshold) {
          candidate.similarity = similarity;
          similar.push(candidate);
        }
      }
    }

    return similar.sort((a, b) => (b.similarity || 0) - (a.similarity || 0));
  }

  /**
   * Calculate similarity between two issues
   */
  private calculateSimilarity(issue1: IssueData, issue2: IssueData): number {
    // Simple similarity calculation based on:
    // 1. Common labels
    // 2. Keyword overlap in title/body
    // 3. Same repository/project

    let similarity = 0;

    // Label similarity (30%)
    const commonLabels = issue1.labels.filter(label => issue2.labels.includes(label));
    const labelSimilarity = commonLabels.length / Math.max(issue1.labels.length, issue2.labels.length, 1);
    similarity += labelSimilarity * 0.3;

    // Repository similarity (20%)
    const repo1 = issue1.sourceMeta?.repository || '';
    const repo2 = issue2.sourceMeta?.repository || '';
    if (repo1 === repo2) {
      similarity += 0.2;
    }

    // Title/content keywords similarity (50%)
    const keywords1 = this.extractKeywords(issue1.title + ' ' + issue1.body);
    const keywords2 = this.extractKeywords(issue2.title + ' ' + issue2.body);
    const commonKeywords = keywords1.filter(word => keywords2.includes(word));
    const keywordSimilarity = commonKeywords.length / Math.max(keywords1.length, keywords2.length, 1);
    similarity += keywordSimilarity * 0.5;

    return Math.min(similarity, 1.0);
  }

  /**
   * Extract keywords from text for similarity calculation
   */
  private extractKeywords(text: string): string[] {
    const stopWords = new Set(['the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should']);
    
    return text
      .toLowerCase()
      .replace(/[^a-zA-Z\s]/g, ' ')
      .split(/\s+/)
      .filter(word => word.length > 2 && !stopWords.has(word))
      .slice(0, 20); // Limit to top 20 keywords
  }

  /**
   * Add issue to batch queue
   */
  private addToBatchQueue(candidate: BatchCandidate): void {
    const category = candidate.priority.category;
    
    if (!this.batchQueue.has(category)) {
      this.batchQueue.set(category, []);
    }
    
    this.batchQueue.get(category)!.push(candidate);
    
    console.log(`📥 Added issue to ${category} batch queue (queue size: ${this.batchQueue.get(category)!.length})`);
  }

  /**
   * Clean up old deferred issues
   */
  private cleanupDeferralQueue(): void {
    const maxAge = 7 * 24 * 60 * 60 * 1000; // 7 days
    const cutoff = new Date(Date.now() - maxAge);
    
    const originalLength = this.deferralQueue.length;
    this.deferralQueue = this.deferralQueue.filter(candidate => candidate.addedAt > cutoff);
    
    if (this.deferralQueue.length < originalLength) {
      console.log(`🧹 Cleaned up ${originalLength - this.deferralQueue.length} old deferred issues`);
    }
  }

  /**
   * Estimate API cost for processing decision
   */
  private estimateApiCost(issue: IssueData, decision: PriorityScore['processingDecision']): number {
    const baseTokens = 1000 + (issue.title.length + issue.body.length) * 0.5; // Rough estimate
    
    switch (decision) {
      case 'immediate':
        return baseTokens * 0.018; // $0.018 per 1K tokens average
      case 'batch':
        return baseTokens * 0.012; // 33% savings through batching
      case 'deferred':
        return baseTokens * 0.018; // Same cost, just delayed
      case 'blocked':
        return 0; // No API cost if blocked
      default:
        return baseTokens * 0.018;
    }
  }

  /**
   * Get current queue statistics
   */
  getQueueStats(): {
    batchQueue: Record<string, number>;
    deferralQueue: number;
    totalQueued: number;
    estimatedCost: number;
  } {
    const batchQueue: Record<string, number> = {};
    let totalQueued = 0;
    let estimatedCost = 0;

    for (const [category, candidates] of this.batchQueue.entries()) {
      batchQueue[category] = candidates.length;
      totalQueued += candidates.length;
      estimatedCost += candidates.reduce((sum, c) => sum + c.priority.estimatedApiCost, 0);
    }

    totalQueued += this.deferralQueue.length;
    estimatedCost += this.deferralQueue.reduce((sum, c) => sum + c.priority.estimatedApiCost, 0);

    return {
      batchQueue,
      deferralQueue: this.deferralQueue.length,
      totalQueued,
      estimatedCost
    };
  }
}

/**
 * Create default priority configuration
 */
export function createDefaultPriorityConfig(): PriorityConfig {
  return {
    emergencyKeywords: [
      'production down', 'service down', 'critical', 'urgent', 'emergency',
      'data loss', 'security breach', 'vulnerability', 'crash', 'down',
      'cannot access', 'broken', 'not working', 'failed', 'error'
    ],
    highPriorityKeywords: [
      'bug', 'issue', 'problem', 'broken', 'not working', 'performance',
      'slow', 'timeout', 'freeze', 'hang', 'memory leak'
    ],
    lowPriorityKeywords: [
      'enhancement', 'feature request', 'improvement', 'suggestion',
      'documentation', 'cleanup', 'refactor', 'style', 'typo'
    ],
    productionRepos: [
      'myprojects-ios', '100-days-workout-ios', 'delaxpm-web'
    ],
    criticalLabels: [
      'critical', 'urgent', 'security', 'data-loss', 'production-issue'
    ],
    deferralThresholds: {
      apiUsagePercentage: 0.8, // 80%
      emergencyOnlyPercentage: 0.95 // 95%
    },
    batchProcessing: {
      enabled: true,
      maxBatchSize: 5,
      similarityThreshold: 0.6,
      batchWindowMinutes: 30
    }
  };
}