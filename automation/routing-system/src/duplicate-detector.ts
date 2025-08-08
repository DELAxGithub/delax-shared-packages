/**
 * Enhanced Duplicate Detection System with API Usage Control
 * Prevents redundant Claude API calls by detecting duplicate issues
 */

import crypto from 'crypto';
import fs from 'fs/promises';
import path from 'path';
import type { IssueData, DuplicateCheckResult, ProcessingHistory } from './types';

export interface DuplicateDetectorConfig {
  enabled: boolean;
  lookbackDays: number;
  editThreshold: number; // 0.1 = 10% change required to reprocess
  skipEditedWithinHours: number;
  historyFilePath: string;
  maxHistoryEntries: number;
}

export interface ProcessedIssue {
  issueId: string;
  contentHash: string;
  processedAt: string;
  classification: any;
  apiCalls: number;
  routingResult: 'success' | 'failed';
  slackPermalink?: string;
  editCount: number;
  lastEditAt?: string;
}

export class DuplicateDetector {
  private config: DuplicateDetectorConfig;
  private historyCache: Map<string, ProcessedIssue> = new Map();
  private hashIndex: Map<string, string[]> = new Map(); // hash -> issue IDs

  constructor(config: DuplicateDetectorConfig) {
    this.config = config;
  }

  /**
   * Initialize detector by loading processing history
   */
  async initialize(): Promise<void> {
    try {
      await this.loadProcessingHistory();
      console.log(`📋 Loaded ${this.historyCache.size} processed issues from history`);
    } catch (error) {
      console.warn('⚠️ Failed to load processing history, starting fresh:', error);
      await this.saveProcessingHistory();
    }
  }

  /**
   * Check if issue is duplicate and should be skipped
   */
  async checkDuplicate(issue: IssueData): Promise<DuplicateCheckResult> {
    if (!this.config.enabled) {
      return { isDuplicate: false, reason: 'duplicate-detection-disabled' };
    }

    const contentHash = this.generateContentHash(issue);
    const issueKey = this.getIssueKey(issue);

    // Check for exact content match
    const existingIssuesWithHash = this.hashIndex.get(contentHash) || [];
    if (existingIssuesWithHash.length > 0) {
      const existingIssue = this.historyCache.get(existingIssuesWithHash[0]);
      if (existingIssue && this.isWithinLookbackPeriod(existingIssue.processedAt)) {
        return {
          isDuplicate: true,
          reason: 'exact-content-match',
          existingIssue: {
            id: existingIssue.issueId,
            processedAt: existingIssue.processedAt,
            classification: existingIssue.classification,
            url: `#${existingIssue.issueId}`
          },
          savedApiCalls: 1
        };
      }
    }

    // Check for issue edit (same issue ID but potentially different content)
    const existingProcessed = this.historyCache.get(issueKey);
    if (existingProcessed) {
      const editResult = this.checkEditSignificance(issue, existingProcessed);
      if (!editResult.requiresReprocessing) {
        return {
          isDuplicate: true,
          reason: 'minor-edit',
          existingIssue: {
            id: existingProcessed.issueId,
            processedAt: existingProcessed.processedAt,
            classification: existingProcessed.classification,
            url: `#${existingProcessed.issueId}`
          },
          savedApiCalls: 1,
          editDetails: editResult
        };
      }
    }

    // Check for Slack permalink duplicates
    if (issue.slackPermalink) {
      const slackDuplicate = await this.checkSlackPermalinkDuplicate(issue.slackPermalink);
      if (slackDuplicate.isDuplicate) {
        return slackDuplicate;
      }
    }

    // No duplicate found
    return { isDuplicate: false, reason: 'no-duplicate-found' };
  }

  /**
   * Record successful processing to prevent future duplicates
   */
  async recordProcessing(
    issue: IssueData,
    classification: any,
    apiCalls: number,
    routingResult: 'success' | 'failed'
  ): Promise<void> {
    const contentHash = this.generateContentHash(issue);
    const issueKey = this.getIssueKey(issue);
    const now = new Date().toISOString();

    const processedIssue: ProcessedIssue = {
      issueId: issueKey,
      contentHash,
      processedAt: now,
      classification,
      apiCalls,
      routingResult,
      slackPermalink: issue.slackPermalink,
      editCount: 0,
      lastEditAt: now
    };

    // Update caches
    this.historyCache.set(issueKey, processedIssue);
    
    // Update hash index
    const existingIssues = this.hashIndex.get(contentHash) || [];
    if (!existingIssues.includes(issueKey)) {
      existingIssues.push(issueKey);
      this.hashIndex.set(contentHash, existingIssues);
    }

    // Persist to disk
    await this.saveProcessingHistory();

    console.log(`✅ Recorded processing for issue ${issueKey} (hash: ${contentHash.substring(0, 8)})`);
  }

  /**
   * Generate content hash for issue deduplication
   */
  private generateContentHash(issue: IssueData): string {
    // Normalize content for consistent hashing
    const normalizedTitle = issue.title.toLowerCase().trim();
    const normalizedBody = (issue.body || '').toLowerCase().trim()
      .replace(/\s+/g, ' ') // normalize whitespace
      .replace(/https?:\/\/[^\s)]+/g, '[URL]'); // normalize URLs
    
    const normalizedLabels = issue.labels
      .map(label => label.toLowerCase())
      .sort()
      .join(',');

    const content = `${normalizedTitle}|${normalizedBody}|${normalizedLabels}`;
    return crypto.createHash('sha256').update(content).digest('hex');
  }

  /**
   * Get unique key for issue
   */
  private getIssueKey(issue: IssueData): string {
    // Use issue number if available, otherwise use author + title hash
    if (issue.number) {
      return `${issue.sourceMeta?.repository || 'unknown'}-${issue.number}`;
    }
    
    const titleHash = crypto.createHash('md5').update(issue.title).digest('hex').substring(0, 8);
    return `${issue.author}-${titleHash}`;
  }

  /**
   * Check if edit is significant enough to require reprocessing
   */
  private checkEditSignificance(issue: IssueData, existingProcessed: ProcessedIssue): {
    requiresReprocessing: boolean;
    editDistance: number;
    timeSinceLastEdit: number;
    reason: string;
  } {
    const newHash = this.generateContentHash(issue);
    const timeSinceLastEdit = Date.now() - new Date(existingProcessed.lastEditAt || existingProcessed.processedAt).getTime();
    const hoursThreshold = this.config.skipEditedWithinHours * 60 * 60 * 1000;

    // If content hash is identical, no reprocessing needed
    if (newHash === existingProcessed.contentHash) {
      return {
        requiresReprocessing: false,
        editDistance: 0,
        timeSinceLastEdit,
        reason: 'identical-content'
      };
    }

    // If edited within threshold time, skip reprocessing
    if (timeSinceLastEdit < hoursThreshold) {
      return {
        requiresReprocessing: false,
        editDistance: 0.5, // estimated
        timeSinceLastEdit,
        reason: `edited-within-${this.config.skipEditedWithinHours}h`
      };
    }

    // Calculate edit distance (simplified Levenshtein ratio)
    const editDistance = this.calculateEditDistance(
      issue.title + (issue.body || ''),
      // We don't have the original content, so assume significant change
      ''
    );

    const requiresReprocessing = editDistance > this.config.editThreshold;

    return {
      requiresReprocessing,
      editDistance,
      timeSinceLastEdit,
      reason: requiresReprocessing ? 'significant-edit' : 'minor-edit'
    };
  }

  /**
   * Check for Slack permalink duplicates
   */
  private async checkSlackPermalinkDuplicate(permalink: string): Promise<DuplicateCheckResult> {
    for (const [issueKey, processedIssue] of this.historyCache.entries()) {
      if (processedIssue.slackPermalink === permalink && 
          this.isWithinLookbackPeriod(processedIssue.processedAt)) {
        return {
          isDuplicate: true,
          reason: 'slack-permalink-match',
          existingIssue: {
            id: processedIssue.issueId,
            processedAt: processedIssue.processedAt,
            classification: processedIssue.classification,
            url: `#${processedIssue.issueId}`
          },
          savedApiCalls: 1
        };
      }
    }

    return { isDuplicate: false, reason: 'no-slack-duplicate' };
  }

  /**
   * Check if timestamp is within lookback period
   */
  private isWithinLookbackPeriod(timestamp: string): boolean {
    const lookbackMs = this.config.lookbackDays * 24 * 60 * 60 * 1000;
    const timestampMs = new Date(timestamp).getTime();
    return Date.now() - timestampMs < lookbackMs;
  }

  /**
   * Calculate edit distance (simplified Levenshtein)
   */
  private calculateEditDistance(str1: string, str2: string): number {
    const len1 = str1.length;
    const len2 = str2.length;
    
    if (len1 === 0) return len2;
    if (len2 === 0) return len1;

    // Simplified ratio for performance
    const maxLen = Math.max(len1, len2);
    const minLen = Math.min(len1, len2);
    
    return 1 - (minLen / maxLen);
  }

  /**
   * Load processing history from disk
   */
  private async loadProcessingHistory(): Promise<void> {
    const historyExists = await fs.access(this.config.historyFilePath).then(() => true).catch(() => false);
    
    if (!historyExists) {
      return;
    }

    const historyData = await fs.readFile(this.config.historyFilePath, 'utf8');
    const history: ProcessingHistory = JSON.parse(historyData);

    // Load into cache
    for (const [issueKey, processedIssue] of Object.entries(history.processedIssues)) {
      this.historyCache.set(issueKey, processedIssue);
      
      // Build hash index
      const existingIssues = this.hashIndex.get(processedIssue.contentHash) || [];
      existingIssues.push(issueKey);
      this.hashIndex.set(processedIssue.contentHash, existingIssues);
    }
  }

  /**
   * Save processing history to disk
   */
  private async saveProcessingHistory(): Promise<void> {
    // Cleanup old entries
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - this.config.lookbackDays);
    const cutoffMs = cutoffDate.getTime();

    const cleanHistory = new Map<string, ProcessedIssue>();
    for (const [key, issue] of this.historyCache.entries()) {
      if (new Date(issue.processedAt).getTime() > cutoffMs) {
        cleanHistory.set(key, issue);
      }
    }

    // Limit total entries
    if (cleanHistory.size > this.config.maxHistoryEntries) {
      const sortedEntries = Array.from(cleanHistory.entries())
        .sort(([,a], [,b]) => new Date(b.processedAt).getTime() - new Date(a.processedAt).getTime())
        .slice(0, this.config.maxHistoryEntries);
      
      cleanHistory.clear();
      sortedEntries.forEach(([key, value]) => cleanHistory.set(key, value));
    }

    this.historyCache = cleanHistory;

    // Rebuild hash index
    this.hashIndex.clear();
    for (const [issueKey, processedIssue] of this.historyCache.entries()) {
      const existingIssues = this.hashIndex.get(processedIssue.contentHash) || [];
      existingIssues.push(issueKey);
      this.hashIndex.set(processedIssue.contentHash, existingIssues);
    }

    // Save to disk
    const historyData: ProcessingHistory = {
      version: '1.0',
      lastCleanup: new Date().toISOString(),
      settings: {
        lookbackDays: this.config.lookbackDays,
        editThreshold: this.config.editThreshold,
        maxHistoryEntries: this.config.maxHistoryEntries
      },
      processedIssues: Object.fromEntries(this.historyCache)
    };

    await fs.mkdir(path.dirname(this.config.historyFilePath), { recursive: true });
    await fs.writeFile(this.config.historyFilePath, JSON.stringify(historyData, null, 2));
  }

  /**
   * Get processing statistics
   */
  getStats(): {
    totalProcessed: number;
    duplicatesBlocked: number;
    apiCallsSaved: number;
    oldestEntry: string | null;
    newestEntry: string | null;
  } {
    const entries = Array.from(this.historyCache.values());
    
    if (entries.length === 0) {
      return {
        totalProcessed: 0,
        duplicatesBlocked: 0,
        apiCallsSaved: 0,
        oldestEntry: null,
        newestEntry: null
      };
    }

    const timestamps = entries.map(e => new Date(e.processedAt).getTime());
    const totalApiCalls = entries.reduce((sum, e) => sum + e.apiCalls, 0);
    
    return {
      totalProcessed: entries.length,
      duplicatesBlocked: 0, // Would need to track this separately
      apiCallsSaved: 0, // Would need to track this separately
      oldestEntry: new Date(Math.min(...timestamps)).toISOString(),
      newestEntry: new Date(Math.max(...timestamps)).toISOString()
    };
  }
}

/**
 * Create default duplicate detector configuration
 */
export function createDefaultDuplicateConfig(baseDir: string): DuplicateDetectorConfig {
  return {
    enabled: true,
    lookbackDays: 60,
    editThreshold: 0.1, // 10% change required
    skipEditedWithinHours: 24,
    historyFilePath: path.join(baseDir, 'data', 'processing-history.json'),
    maxHistoryEntries: 5000
  };
}