import { SupabaseClient } from '@supabase/supabase-js';
import { formatJSTDate, getJSTToday } from '../Utils/timezone';

/**
 * レポート設定
 */
export interface ReportConfig {
  /** レポートタイトル */
  title: string;
  /** 対象期間（週/月/カスタム） */
  period: 'week' | 'month' | 'custom';
  /** カスタム期間の開始日 */
  startDate?: string;
  /** カスタム期間の終了日 */
  endDate?: string;
  /** 含めるセクション */
  sections: {
    summary?: boolean;
    details?: boolean;
    charts?: boolean;
    recommendations?: boolean;
  };
  /** 出力フォーマット */
  format: 'markdown' | 'html' | 'json';
  /** テンプレート設定 */
  template?: {
    headerTemplate?: string;
    footerTemplate?: string;
    sectionTemplates?: Record<string, string>;
  };
}

/**
 * レポートデータソース設定
 */
export interface DataSourceConfig {
  /** テーブル名 */
  table: string;
  /** 主要な日付フィールド */
  dateField: string;
  /** ステータスフィールド */
  statusField?: string;
  /** 担当者フィールド */
  assigneeField?: string;
  /** フィルター条件 */
  filters?: Record<string, any>;
  /** 集計するフィールド */
  aggregateFields?: string[];
}

/**
 * レポート統計データ
 */
export interface ReportStatistics {
  /** 総件数 */
  totalItems: number;
  /** 期間内新規作成 */
  newItems: number;
  /** 期間内完了 */
  completedItems: number;
  /** 期間内更新 */
  updatedItems: number;
  /** ステータス別件数 */
  statusBreakdown: Record<string, number>;
  /** 担当者別件数 */
  assigneeBreakdown?: Record<string, number>;
  /** 完了率 */
  completionRate: number;
  /** 前期比較 */
  previousPeriodComparison?: {
    totalChange: number;
    completionRateChange: number;
  };
}

/**
 * レポートセクション
 */
export interface ReportSection {
  /** セクションID */
  id: string;
  /** セクションタイトル */
  title: string;
  /** セクション内容 */
  content: string;
  /** データ */
  data?: any;
  /** チャート設定 */
  chart?: {
    type: 'bar' | 'line' | 'pie' | 'doughnut';
    data: any;
    options?: any;
  };
}

/**
 * 生成されたレポート
 */
export interface GeneratedReport {
  /** レポートID */
  id: string;
  /** タイトル */
  title: string;
  /** 生成日時 */
  generatedAt: string;
  /** 対象期間 */
  period: {
    start: string;
    end: string;
  };
  /** 統計データ */
  statistics: ReportStatistics;
  /** セクション */
  sections: ReportSection[];
  /** フォーマット済み内容 */
  formattedContent: string;
  /** メタデータ */
  metadata: {
    generator: string;
    version: string;
    dataSource: string;
  };
}

/**
 * 汎用レポート生成エンジン
 * 
 * 様々なデータソースから定期レポートを生成する汎用エンジン。
 * PMliberaryの週報システムをベースに抽象化。
 * 
 * @example
 * ```typescript
 * const generator = new ReportGenerator(supabase);
 * 
 * const report = await generator.generateReport({
 *   title: '週次進捗レポート',
 *   period: 'week',
 *   sections: { summary: true, details: true },
 *   format: 'markdown'
 * }, {
 *   table: 'tasks',
 *   dateField: 'updated_at',
 *   statusField: 'status',
 *   assigneeField: 'assignee'
 * });
 * 
 * console.log(report.formattedContent);
 * ```
 */
export class ReportGenerator {
  constructor(private supabase: SupabaseClient) {}

  /**
   * レポートを生成する
   */
  async generateReport(
    config: ReportConfig,
    dataSource: DataSourceConfig
  ): Promise<GeneratedReport> {
    const period = this.calculatePeriod(config);
    const data = await this.fetchData(dataSource, period);
    const statistics = this.calculateStatistics(data, period);
    const sections = await this.generateSections(config, statistics, data);
    const formattedContent = this.formatReport(config, sections);

    return {
      id: this.generateReportId(),
      title: config.title,
      generatedAt: new Date().toISOString(),
      period,
      statistics,
      sections,
      formattedContent,
      metadata: {
        generator: 'ReportGenerator',
        version: '1.0.0',
        dataSource: dataSource.table
      }
    };
  }

  /**
   * 期間を計算する
   */
  private calculatePeriod(config: ReportConfig) {
    const today = getJSTToday();
    
    if (config.period === 'custom' && config.startDate && config.endDate) {
      return {
        start: config.startDate,
        end: config.endDate
      };
    }

    if (config.period === 'week') {
      const startOfWeek = new Date(today);
      startOfWeek.setDate(today.getDate() - 7);
      return {
        start: formatJSTDate(startOfWeek),
        end: formatJSTDate(today)
      };
    }

    if (config.period === 'month') {
      const startOfMonth = new Date(today);
      startOfMonth.setMonth(today.getMonth() - 1);
      return {
        start: formatJSTDate(startOfMonth),
        end: formatJSTDate(today)
      };
    }

    throw new Error('Invalid period configuration');
  }

  /**
   * データを取得する
   */
  private async fetchData(dataSource: DataSourceConfig, period: { start: string; end: string }) {
    let query = this.supabase
      .from(dataSource.table)
      .select('*')
      .gte(dataSource.dateField, period.start)
      .lte(dataSource.dateField, period.end);

    // フィルター適用
    if (dataSource.filters) {
      Object.entries(dataSource.filters).forEach(([key, value]) => {
        query = query.eq(key, value);
      });
    }

    const { data, error } = await query;
    if (error) throw error;

    return data || [];
  }

  /**
   * 統計を計算する
   */
  private calculateStatistics(data: any[], period: { start: string; end: string }): ReportStatistics {
    const totalItems = data.length;
    
    // 期間内作成・完了・更新の計算（実装依存）
    const newItems = data.filter(item => 
      item.created_at >= period.start && item.created_at <= period.end
    ).length;

    const completedItems = data.filter(item => 
      item.status === '完了' || item.status === '完パケ納品'
    ).length;

    const updatedItems = data.filter(item => 
      item.updated_at >= period.start && item.updated_at <= period.end
    ).length;

    // ステータス別集計
    const statusBreakdown = data.reduce((acc, item) => {
      const status = item.status || '未設定';
      acc[status] = (acc[status] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);

    // 担当者別集計
    const assigneeBreakdown = data.reduce((acc, item) => {
      const assignee = item.assignee || item.director || '未割当';
      acc[assignee] = (acc[assignee] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);

    const completionRate = totalItems > 0 ? (completedItems / totalItems) * 100 : 0;

    return {
      totalItems,
      newItems,
      completedItems,
      updatedItems,
      statusBreakdown,
      assigneeBreakdown,
      completionRate: Math.round(completionRate * 100) / 100
    };
  }

  /**
   * セクションを生成する
   */
  private async generateSections(
    config: ReportConfig,
    statistics: ReportStatistics,
    data: any[]
  ): Promise<ReportSection[]> {
    const sections: ReportSection[] = [];

    if (config.sections.summary) {
      sections.push(this.generateSummarySection(statistics));
    }

    if (config.sections.details) {
      sections.push(this.generateDetailsSection(data));
    }

    if (config.sections.charts) {
      sections.push(this.generateChartsSection(statistics));
    }

    if (config.sections.recommendations) {
      sections.push(this.generateRecommendationsSection(statistics, data));
    }

    return sections;
  }

  /**
   * サマリーセクションを生成
   */
  private generateSummarySection(statistics: ReportStatistics): ReportSection {
    const content = `
## 📊 期間サマリー

- **総アイテム数**: ${statistics.totalItems}件
- **新規作成**: ${statistics.newItems}件
- **完了**: ${statistics.completedItems}件
- **更新**: ${statistics.updatedItems}件
- **完了率**: ${statistics.completionRate}%

### ステータス別内訳
${Object.entries(statistics.statusBreakdown)
  .map(([status, count]) => `- **${status}**: ${count}件`)
  .join('\n')}
`;

    return {
      id: 'summary',
      title: '期間サマリー',
      content: content.trim(),
      data: statistics
    };
  }

  /**
   * 詳細セクションを生成
   */
  private generateDetailsSection(data: any[]): ReportSection {
    const recentItems = data
      .sort((a, b) => new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime())
      .slice(0, 10);

    const content = `
## 📋 最近の更新

${recentItems.map(item => 
  `- **${item.title || item.name}** (${item.status}) - ${item.updated_at.split('T')[0]}`
).join('\n')}
`;

    return {
      id: 'details',
      title: '詳細情報',
      content: content.trim(),
      data: recentItems
    };
  }

  /**
   * チャートセクションを生成
   */
  private generateChartsSection(statistics: ReportStatistics): ReportSection {
    const chartData = {
      labels: Object.keys(statistics.statusBreakdown),
      datasets: [{
        data: Object.values(statistics.statusBreakdown),
        backgroundColor: [
          '#f59e0b', '#3b82f6', '#10b981', '#ec4899', '#8b5cf6'
        ]
      }]
    };

    return {
      id: 'charts',
      title: 'グラフ・チャート',
      content: '## 📈 ステータス分布',
      data: statistics,
      chart: {
        type: 'pie',
        data: chartData
      }
    };
  }

  /**
   * 推奨事項セクションを生成
   */
  private generateRecommendationsSection(statistics: ReportStatistics, data: any[]): ReportSection {
    const recommendations = [];

    // 完了率による推奨事項
    if (statistics.completionRate < 50) {
      recommendations.push('⚠️ 完了率が低下しています。タスクの優先順位を見直すことをお勧めします。');
    }

    // ボトルネック検出
    const bottleneck = Object.entries(statistics.statusBreakdown)
      .sort(([,a], [,b]) => b - a)[0];
    
    if (bottleneck && bottleneck[1] > statistics.totalItems * 0.3) {
      recommendations.push(`🔄 「${bottleneck[0]}」に多くのアイテムが集中しています。処理能力の向上を検討してください。`);
    }

    // 期限切れチェック
    const overdueItems = data.filter(item => 
      item.due_date && new Date(item.due_date) < new Date()
    );
    
    if (overdueItems.length > 0) {
      recommendations.push(`📅 ${overdueItems.length}件のアイテムが期限切れです。優先的に対応してください。`);
    }

    const content = `
## 💡 推奨事項

${recommendations.map(rec => `- ${rec}`).join('\n')}
`;

    return {
      id: 'recommendations',
      title: '推奨事項',
      content: content.trim(),
      data: { recommendations }
    };
  }

  /**
   * レポートをフォーマットする
   */
  private formatReport(config: ReportConfig, sections: ReportSection[]): string {
    if (config.format === 'markdown') {
      return this.formatAsMarkdown(config, sections);
    }
    
    if (config.format === 'html') {
      return this.formatAsHTML(config, sections);
    }
    
    if (config.format === 'json') {
      return JSON.stringify({ title: config.title, sections }, null, 2);
    }

    throw new Error('Unsupported format');
  }

  /**
   * Markdownフォーマット
   */
  private formatAsMarkdown(config: ReportConfig, sections: ReportSection[]): string {
    const header = config.template?.headerTemplate || `# ${config.title}\n\n生成日時: ${formatJSTDate(new Date())}\n\n`;
    const footer = config.template?.footerTemplate || '\n\n---\n*自動生成レポート*';
    
    const content = sections.map(section => section.content).join('\n\n');
    
    return header + content + footer;
  }

  /**
   * HTMLフォーマット
   */
  private formatAsHTML(config: ReportConfig, sections: ReportSection[]): string {
    const header = config.template?.headerTemplate || 
      `<h1>${config.title}</h1><p>生成日時: ${formatJSTDate(new Date())}</p>`;
    
    const content = sections.map(section => 
      `<div class="section" id="${section.id}">
        <h2>${section.title}</h2>
        ${section.content.replace(/\n/g, '<br>')}
      </div>`
    ).join('\n');
    
    const footer = config.template?.footerTemplate || '<hr><em>自動生成レポート</em>';
    
    return `<div class="report">${header}${content}${footer}</div>`;
  }

  /**
   * レポートIDを生成
   */
  private generateReportId(): string {
    return `report_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}

/**
 * レポート送信機能
 */
export interface ReportDeliveryConfig {
  /** 送信方法 */
  method: 'email' | 'slack' | 'webhook';
  /** 送信先設定 */
  destinations: string[];
  /** テンプレート設定 */
  template?: {
    subject?: string;
    body?: string;
  };
}

/**
 * レポート送信エンジン
 */
export class ReportDelivery {
  /**
   * レポートを送信する
   */
  async deliverReport(
    report: GeneratedReport,
    config: ReportDeliveryConfig
  ): Promise<{ success: boolean; errors: string[] }> {
    const errors: string[] = [];
    let successCount = 0;

    for (const destination of config.destinations) {
      try {
        if (config.method === 'email') {
          await this.sendEmail(report, destination, config.template);
        } else if (config.method === 'slack') {
          await this.sendSlack(report, destination, config.template);
        } else if (config.method === 'webhook') {
          await this.sendWebhook(report, destination);
        }
        successCount++;
      } catch (error) {
        errors.push(`${destination}: ${error instanceof Error ? error.message : 'Unknown error'}`);
      }
    }

    return {
      success: successCount === config.destinations.length,
      errors
    };
  }

  private async sendEmail(report: GeneratedReport, email: string, template?: any) {
    // メール送信の実装（Resend, SendGrid等）
    throw new Error('Email delivery not implemented');
  }

  private async sendSlack(report: GeneratedReport, webhook: string, template?: any) {
    // Slack送信の実装
    throw new Error('Slack delivery not implemented');
  }

  private async sendWebhook(report: GeneratedReport, url: string) {
    // Webhook送信の実装
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(report)
    });

    if (!response.ok) {
      throw new Error(`Webhook failed: ${response.statusText}`);
    }
  }
}

export default ReportGenerator;