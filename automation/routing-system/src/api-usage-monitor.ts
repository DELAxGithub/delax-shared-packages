/**
 * API Usage Monitoring and Control System
 * Prevents excessive Claude API usage and manages cost control
 */

import fs from 'fs/promises';
import path from 'path';

export interface ApiUsageConfig {
  limits: {
    dailyCallLimit: number;
    monthlyCallLimit: number;
    dailyTokenLimit: number;
    monthlyTokenLimit: number;
    dailyCostLimit: number; // USD
    monthlyCostLimit: number; // USD
  };
  pricing: {
    inputTokenCost: number; // per 1K tokens
    outputTokenCost: number; // per 1K tokens
    model: string;
  };
  monitoring: {
    usageFilePath: string;
    warningThresholds: {
      daily: number; // 0.8 = 80%
      monthly: number; // 0.8 = 80%
    };
    emergencyThresholds: {
      daily: number; // 0.95 = 95%
      monthly: number; // 0.9 = 90%
    };
  };
}

export interface ApiUsageData {
  version: string;
  lastUpdated: string;
  currentPeriod: {
    daily: {
      date: string; // YYYY-MM-DD
      calls: number;
      inputTokens: number;
      outputTokens: number;
      estimatedCost: number;
    };
    monthly: {
      month: string; // YYYY-MM
      calls: number;
      inputTokens: number;
      outputTokens: number;
      estimatedCost: number;
    };
  };
  history: Array<{
    date: string;
    calls: number;
    inputTokens: number;
    outputTokens: number;
    estimatedCost: number;
    type: 'daily' | 'monthly';
  }>;
}

export interface UsageCheckResult {
  allowed: boolean;
  reason?: string;
  currentUsage: {
    daily: {
      calls: { current: number; limit: number; percentage: number };
      tokens: { current: number; limit: number; percentage: number };
      cost: { current: number; limit: number; percentage: number };
    };
    monthly: {
      calls: { current: number; limit: number; percentage: number };
      tokens: { current: number; limit: number; percentage: number };
      cost: { current: number; limit: number; percentage: number };
    };
  };
  warnings: string[];
  recommendations: string[];
}

export class ApiUsageMonitor {
  private config: ApiUsageConfig;
  private usageData: ApiUsageData | null = null;

  constructor(config: ApiUsageConfig) {
    this.config = config;
  }

  /**
   * Initialize monitor by loading usage data
   */
  async initialize(): Promise<void> {
    try {
      await this.loadUsageData();
      console.log('📊 API usage monitor initialized');
    } catch (error) {
      console.warn('⚠️ Failed to load usage data, starting fresh:', error);
      await this.initializeUsageData();
    }
  }

  /**
   * Check if API call is allowed within limits
   */
  async checkUsageLimits(estimatedInputTokens: number, estimatedOutputTokens: number): Promise<UsageCheckResult> {
    if (!this.usageData) {
      await this.initialize();
    }

    const today = new Date().toISOString().split('T')[0];
    const currentMonth = today.substring(0, 7); // YYYY-MM

    // Ensure we have current period data
    await this.ensureCurrentPeriod(today, currentMonth);

    const estimatedCost = this.calculateCost(estimatedInputTokens, estimatedOutputTokens);
    const totalEstimatedTokens = estimatedInputTokens + estimatedOutputTokens;

    const daily = this.usageData!.currentPeriod.daily;
    const monthly = this.usageData!.currentPeriod.monthly;

    // Calculate usage percentages
    const dailyCallsPercentage = (daily.calls + 1) / this.config.limits.dailyCallLimit;
    const monthlyCallsPercentage = (monthly.calls + 1) / this.config.limits.monthlyCallLimit;
    const dailyTokensPercentage = (daily.inputTokens + daily.outputTokens + totalEstimatedTokens) / this.config.limits.dailyTokenLimit;
    const monthlyTokensPercentage = (monthly.inputTokens + monthly.outputTokens + totalEstimatedTokens) / this.config.limits.monthlyTokenLimit;
    const dailyCostPercentage = (daily.estimatedCost + estimatedCost) / this.config.limits.dailyCostLimit;
    const monthlyCostPercentage = (monthly.estimatedCost + estimatedCost) / this.config.limits.monthlyCostLimit;

    const result: UsageCheckResult = {
      allowed: true,
      currentUsage: {
        daily: {
          calls: { current: daily.calls, limit: this.config.limits.dailyCallLimit, percentage: dailyCallsPercentage },
          tokens: { current: daily.inputTokens + daily.outputTokens, limit: this.config.limits.dailyTokenLimit, percentage: dailyTokensPercentage },
          cost: { current: daily.estimatedCost, limit: this.config.limits.dailyCostLimit, percentage: dailyCostPercentage }
        },
        monthly: {
          calls: { current: monthly.calls, limit: this.config.limits.monthlyCallLimit, percentage: monthlyCallsPercentage },
          tokens: { current: monthly.inputTokens + monthly.outputTokens, limit: this.config.limits.monthlyTokenLimit, percentage: monthlyTokensPercentage },
          cost: { current: monthly.estimatedCost, limit: this.config.limits.monthlyCostLimit, percentage: monthlyCostPercentage }
        }
      },
      warnings: [],
      recommendations: []
    };

    // Check emergency thresholds (block processing)
    if (dailyCallsPercentage >= this.config.monitoring.emergencyThresholds.daily) {
      result.allowed = false;
      result.reason = `Daily API call limit exceeded (${Math.round(dailyCallsPercentage * 100)}% of ${this.config.limits.dailyCallLimit})`;
    } else if (monthlyCallsPercentage >= this.config.monitoring.emergencyThresholds.monthly) {
      result.allowed = false;
      result.reason = `Monthly API call limit exceeded (${Math.round(monthlyCallsPercentage * 100)}% of ${this.config.limits.monthlyCallLimit})`;
    } else if (dailyTokensPercentage >= this.config.monitoring.emergencyThresholds.daily) {
      result.allowed = false;
      result.reason = `Daily token limit exceeded (${Math.round(dailyTokensPercentage * 100)}% of ${this.config.limits.dailyTokenLimit})`;
    } else if (monthlyTokensPercentage >= this.config.monitoring.emergencyThresholds.monthly) {
      result.allowed = false;
      result.reason = `Monthly token limit exceeded (${Math.round(monthlyTokensPercentage * 100)}% of ${this.config.limits.monthlyTokenLimit})`;
    } else if (dailyCostPercentage >= this.config.monitoring.emergencyThresholds.daily) {
      result.allowed = false;
      result.reason = `Daily cost limit exceeded ($${daily.estimatedCost.toFixed(2)} + $${estimatedCost.toFixed(2)} > $${this.config.limits.dailyCostLimit})`;
    } else if (monthlyCostPercentage >= this.config.monitoring.emergencyThresholds.monthly) {
      result.allowed = false;
      result.reason = `Monthly cost limit exceeded ($${monthly.estimatedCost.toFixed(2)} + $${estimatedCost.toFixed(2)} > $${this.config.limits.monthlyCostLimit})`;
    }

    // Generate warnings for approaching limits
    if (dailyCallsPercentage >= this.config.monitoring.warningThresholds.daily) {
      result.warnings.push(`Daily API calls at ${Math.round(dailyCallsPercentage * 100)}% (${daily.calls}/${this.config.limits.dailyCallLimit})`);
    }
    if (monthlyCallsPercentage >= this.config.monitoring.warningThresholds.monthly) {
      result.warnings.push(`Monthly API calls at ${Math.round(monthlyCallsPercentage * 100)}% (${monthly.calls}/${this.config.limits.monthlyCallLimit})`);
    }
    if (dailyTokensPercentage >= this.config.monitoring.warningThresholds.daily) {
      result.warnings.push(`Daily tokens at ${Math.round(dailyTokensPercentage * 100)}% (${daily.inputTokens + daily.outputTokens}/${this.config.limits.dailyTokenLimit})`);
    }
    if (monthlyCostPercentage >= this.config.monitoring.warningThresholds.monthly) {
      result.warnings.push(`Monthly cost at ${Math.round(monthlyCostPercentage * 100)}% ($${monthly.estimatedCost.toFixed(2)}/$${this.config.limits.monthlyCostLimit})`);
    }

    // Generate recommendations
    if (result.warnings.length > 0) {
      result.recommendations.push('Consider processing only critical issues until usage resets');
      result.recommendations.push('Implement batch processing for similar issues');
      result.recommendations.push('Review duplicate detection to reduce unnecessary API calls');
    }

    if (dailyCallsPercentage >= 0.9 || monthlyCallsPercentage >= 0.9) {
      result.recommendations.push('Enable emergency mode: process only critical/urgent issues');
      result.recommendations.push('Consider increasing API limits if budget allows');
    }

    return result;
  }

  /**
   * Record actual API usage after a successful call
   */
  async recordUsage(inputTokens: number, outputTokens: number): Promise<void> {
    if (!this.usageData) {
      await this.initialize();
    }

    const today = new Date().toISOString().split('T')[0];
    const currentMonth = today.substring(0, 7);
    const cost = this.calculateCost(inputTokens, outputTokens);

    await this.ensureCurrentPeriod(today, currentMonth);

    // Update daily usage
    this.usageData!.currentPeriod.daily.calls += 1;
    this.usageData!.currentPeriod.daily.inputTokens += inputTokens;
    this.usageData!.currentPeriod.daily.outputTokens += outputTokens;
    this.usageData!.currentPeriod.daily.estimatedCost += cost;

    // Update monthly usage
    this.usageData!.currentPeriod.monthly.calls += 1;
    this.usageData!.currentPeriod.monthly.inputTokens += inputTokens;
    this.usageData!.currentPeriod.monthly.outputTokens += outputTokens;
    this.usageData!.currentPeriod.monthly.estimatedCost += cost;

    this.usageData!.lastUpdated = new Date().toISOString();

    await this.saveUsageData();

    console.log(`📊 Recorded API usage: ${inputTokens + outputTokens} tokens, ~$${cost.toFixed(4)}`);
  }

  /**
   * Generate usage report for GitHub comment
   */
  generateUsageReport(): string {
    if (!this.usageData) {
      return '📊 **API Usage**: Not initialized';
    }

    const daily = this.usageData.currentPeriod.daily;
    const monthly = this.usageData.currentPeriod.monthly;

    const dailyCallsPercent = Math.round((daily.calls / this.config.limits.dailyCallLimit) * 100);
    const monthlyCallsPercent = Math.round((monthly.calls / this.config.limits.monthlyCallLimit) * 100);

    let report = `## 📊 API Usage Status\n\n`;
    
    report += `**Today (${daily.date})**:\n`;
    report += `- Calls: ${daily.calls}/${this.config.limits.dailyCallLimit} (${dailyCallsPercent}%)\n`;
    report += `- Tokens: ${(daily.inputTokens + daily.outputTokens).toLocaleString()}/${this.config.limits.dailyTokenLimit.toLocaleString()}\n`;
    report += `- Cost: $${daily.estimatedCost.toFixed(2)}/$${this.config.limits.dailyCostLimit}\n\n`;

    report += `**This Month (${monthly.month})**:\n`;
    report += `- Calls: ${monthly.calls}/${this.config.limits.monthlyCallLimit} (${monthlyCallsPercent}%)\n`;
    report += `- Tokens: ${(monthly.inputTokens + monthly.outputTokens).toLocaleString()}/${this.config.limits.monthlyTokenLimit.toLocaleString()}\n`;
    report += `- Cost: $${monthly.estimatedCost.toFixed(2)}/$${this.config.limits.monthlyCostLimit}\n\n`;

    // Add status indicator
    if (dailyCallsPercent >= 90 || monthlyCallsPercent >= 90) {
      report += `🚨 **Status**: Near limit - processing restricted to critical issues only\n`;
    } else if (dailyCallsPercent >= 80 || monthlyCallsPercent >= 80) {
      report += `⚠️ **Status**: High usage - monitoring closely\n`;
    } else {
      report += `✅ **Status**: Normal usage levels\n`;
    }

    report += `\n*Model: ${this.config.pricing.model}*`;

    return report;
  }

  /**
   * Calculate estimated cost for token usage
   */
  private calculateCost(inputTokens: number, outputTokens: number): number {
    const inputCost = (inputTokens / 1000) * this.config.pricing.inputTokenCost;
    const outputCost = (outputTokens / 1000) * this.config.pricing.outputTokenCost;
    return inputCost + outputCost;
  }

  /**
   * Ensure current period data exists and is up to date
   */
  private async ensureCurrentPeriod(today: string, currentMonth: string): Promise<void> {
    if (!this.usageData) return;

    // Check if we need to roll over to new day
    if (this.usageData.currentPeriod.daily.date !== today) {
      // Archive old daily data
      this.usageData.history.push({
        date: this.usageData.currentPeriod.daily.date,
        calls: this.usageData.currentPeriod.daily.calls,
        inputTokens: this.usageData.currentPeriod.daily.inputTokens,
        outputTokens: this.usageData.currentPeriod.daily.outputTokens,
        estimatedCost: this.usageData.currentPeriod.daily.estimatedCost,
        type: 'daily'
      });

      // Reset daily counters
      this.usageData.currentPeriod.daily = {
        date: today,
        calls: 0,
        inputTokens: 0,
        outputTokens: 0,
        estimatedCost: 0
      };
    }

    // Check if we need to roll over to new month
    if (this.usageData.currentPeriod.monthly.month !== currentMonth) {
      // Archive old monthly data
      this.usageData.history.push({
        date: this.usageData.currentPeriod.monthly.month,
        calls: this.usageData.currentPeriod.monthly.calls,
        inputTokens: this.usageData.currentPeriod.monthly.inputTokens,
        outputTokens: this.usageData.currentPeriod.monthly.outputTokens,
        estimatedCost: this.usageData.currentPeriod.monthly.estimatedCost,
        type: 'monthly'
      });

      // Reset monthly counters
      this.usageData.currentPeriod.monthly = {
        month: currentMonth,
        calls: 0,
        inputTokens: 0,
        outputTokens: 0,
        estimatedCost: 0
      };
    }

    // Cleanup old history (keep last 90 days of daily data, 24 months of monthly data)
    this.usageData.history = this.usageData.history.filter(entry => {
      const entryDate = new Date(entry.date);
      const now = new Date();
      const daysDiff = (now.getTime() - entryDate.getTime()) / (1000 * 60 * 60 * 24);
      
      if (entry.type === 'daily') {
        return daysDiff <= 90;
      } else {
        return daysDiff <= 730; // ~24 months
      }
    });

    await this.saveUsageData();
  }

  /**
   * Initialize fresh usage data
   */
  private async initializeUsageData(): Promise<void> {
    const today = new Date().toISOString().split('T')[0];
    const currentMonth = today.substring(0, 7);

    this.usageData = {
      version: '1.0',
      lastUpdated: new Date().toISOString(),
      currentPeriod: {
        daily: {
          date: today,
          calls: 0,
          inputTokens: 0,
          outputTokens: 0,
          estimatedCost: 0
        },
        monthly: {
          month: currentMonth,
          calls: 0,
          inputTokens: 0,
          outputTokens: 0,
          estimatedCost: 0
        }
      },
      history: []
    };

    await this.saveUsageData();
  }

  /**
   * Load usage data from disk
   */
  private async loadUsageData(): Promise<void> {
    const usageExists = await fs.access(this.config.monitoring.usageFilePath).then(() => true).catch(() => false);
    
    if (!usageExists) {
      await this.initializeUsageData();
      return;
    }

    const usageDataRaw = await fs.readFile(this.config.monitoring.usageFilePath, 'utf8');
    this.usageData = JSON.parse(usageDataRaw);
  }

  /**
   * Save usage data to disk
   */
  private async saveUsageData(): Promise<void> {
    if (!this.usageData) return;

    await fs.mkdir(path.dirname(this.config.monitoring.usageFilePath), { recursive: true });
    await fs.writeFile(this.config.monitoring.usageFilePath, JSON.stringify(this.usageData, null, 2));
  }
}

/**
 * Create default API usage configuration
 */
export function createDefaultApiUsageConfig(baseDir: string): ApiUsageConfig {
  return {
    limits: {
      dailyCallLimit: 100,
      monthlyCallLimit: 2000,
      dailyTokenLimit: 500000, // 500K tokens per day
      monthlyTokenLimit: 10000000, // 10M tokens per month
      dailyCostLimit: 50, // $50 per day
      monthlyCostLimit: 1000 // $1000 per month
    },
    pricing: {
      inputTokenCost: 0.003, // $3 per 1K input tokens (Claude 4 Sonnet)
      outputTokenCost: 0.015, // $15 per 1K output tokens (Claude 4 Sonnet)
      model: 'claude-4-sonnet-20250514'
    },
    monitoring: {
      usageFilePath: path.join(baseDir, 'data', 'api-usage.json'),
      warningThresholds: {
        daily: 0.8, // 80%
        monthly: 0.8 // 80%
      },
      emergencyThresholds: {
        daily: 0.95, // 95%
        monthly: 0.9 // 90%
      }
    }
  };
}