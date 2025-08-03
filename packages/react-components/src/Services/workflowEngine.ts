import { SupabaseClient } from '@supabase/supabase-js';
import { 
  WorkflowConfig, 
  WorkflowItem, 
  StatusHistoryEntry, 
  WorkflowStatistics,
  WorkflowFilterOptions,
  WORKFLOW_PRESETS 
} from '../Types/workflow';

/**
 * ワークフロー変更イベント
 */
export interface WorkflowChangeEvent<T extends string = string> {
  /** イベントタイプ */
  type: 'status_changed' | 'item_created' | 'item_updated' | 'item_deleted';
  /** アイテムID */
  itemId: string;
  /** 変更前データ */
  oldData?: WorkflowItem<T>;
  /** 変更後データ */
  newData?: WorkflowItem<T>;
  /** 変更者 */
  changedBy: string;
  /** タイムスタンプ */
  timestamp: string;
}

/**
 * ワークフローエンジンの設定
 */
export interface WorkflowEngineConfig {
  /** Supabaseクライアント */
  supabase: SupabaseClient;
  /** アイテム保存テーブル名 */
  itemsTable: string;
  /** 履歴保存テーブル名 */
  historyTable: string;
  /** 自動遷移を有効にするか */
  enableAutoTransitions?: boolean;
  /** リアルタイム更新を有効にするか */
  enableRealtimeUpdates?: boolean;
}

/**
 * ワークフロー管理エンジン
 * 
 * 10段階ワークフローを含む任意のワークフローを管理する汎用エンジン。
 * PMliberaryのエピソード管理システムをベースに抽象化。
 * 
 * @example
 * ```typescript
 * const engine = new WorkflowEngine({
 *   supabase,
 *   itemsTable: 'tasks',
 *   historyTable: 'task_history'
 * });
 * 
 * // ワークフロー設定
 * await engine.setWorkflowConfig(WORKFLOW_PRESETS.production);
 * 
 * // アイテム作成
 * const item = await engine.createItem({
 *   title: '新しいタスク',
 *   workflowId: 'production',
 *   assignee: 'user123'
 * });
 * 
 * // ステータス変更
 * await engine.changeStatus(item.id, '編集中', 'user123', '作業開始');
 * ```
 */
export class WorkflowEngine<T extends string = string> {
  private config: WorkflowEngineConfig;
  private workflowConfig: WorkflowConfig<T> | null = null;
  private changeListeners: ((event: WorkflowChangeEvent<T>) => void)[] = [];

  constructor(config: WorkflowEngineConfig) {
    this.config = config;
    this.initializeRealtimeUpdates();
  }

  /**
   * ワークフロー設定をセットする
   */
  async setWorkflowConfig(workflowConfig: WorkflowConfig<T>) {
    this.workflowConfig = workflowConfig;
  }

  /**
   * ワークフローアイテムを作成する
   */
  async createItem(
    data: Omit<WorkflowItem<T>, 'id' | 'createdAt' | 'updatedAt'> & { 
      initialStatus?: T 
    }
  ): Promise<WorkflowItem<T>> {
    if (!this.workflowConfig) {
      throw new Error('Workflow configuration is not set');
    }

    const initialStatus = data.initialStatus || this.workflowConfig.steps[0].id;
    const now = new Date().toISOString();

    const itemData = {
      ...data,
      currentStatus: initialStatus,
      createdAt: now,
      updatedAt: now
    };

    const { data: created, error } = await this.config.supabase
      .from(this.config.itemsTable)
      .insert([itemData])
      .select()
      .single();

    if (error) throw error;

    // 履歴記録
    await this.recordStatusChange(created.id, null, initialStatus, data.assignee || 'system', '初期作成');

    // イベント発行
    this.emitEvent({
      type: 'item_created',
      itemId: created.id,
      newData: created,
      changedBy: data.assignee || 'system',
      timestamp: now
    });

    return created;
  }

  /**
   * アイテムを取得する
   */
  async getItem(id: string): Promise<WorkflowItem<T> | null> {
    const { data, error } = await this.config.supabase
      .from(this.config.itemsTable)
      .select('*')
      .eq('id', id)
      .single();

    if (error) {
      if (error.code === 'PGRST116') return null; // Not found
      throw error;
    }

    return data;
  }

  /**
   * アイテム一覧を取得する
   */
  async getItems(filters?: WorkflowFilterOptions<T>): Promise<WorkflowItem<T>[]> {
    let query = this.config.supabase
      .from(this.config.itemsTable)
      .select('*');

    // フィルター適用
    if (filters) {
      if (filters.status) {
        if (Array.isArray(filters.status)) {
          query = query.in('currentStatus', filters.status);
        } else {
          query = query.eq('currentStatus', filters.status);
        }
      }

      if (filters.assignee) {
        query = query.eq('assignee', filters.assignee);
      }

      if (filters.priority) {
        query = query.eq('priority', filters.priority);
      }

      if (filters.dueDateRange) {
        if (filters.dueDateRange.from) {
          query = query.gte('dueDate', filters.dueDateRange.from);
        }
        if (filters.dueDateRange.to) {
          query = query.lte('dueDate', filters.dueDateRange.to);
        }
      }

      if (filters.overdueOnly) {
        const today = new Date().toISOString().split('T')[0];
        query = query.lt('dueDate', today);
      }

      if (filters.searchQuery) {
        query = query.or(`title.ilike.%${filters.searchQuery}%,data->>'description'.ilike.%${filters.searchQuery}%`);
      }

      if (filters.tags && filters.tags.length > 0) {
        query = query.contains('tags', filters.tags);
      }
    }

    query = query.order('updatedAt', { ascending: false });

    const { data, error } = await query;
    if (error) throw error;

    return data || [];
  }

  /**
   * ステータスを変更する
   */
  async changeStatus(
    itemId: string, 
    newStatus: T, 
    changedBy: string, 
    comment?: string
  ): Promise<WorkflowItem<T>> {
    if (!this.workflowConfig) {
      throw new Error('Workflow configuration is not set');
    }

    // 現在のアイテムを取得
    const currentItem = await this.getItem(itemId);
    if (!currentItem) {
      throw new Error('Item not found');
    }

    // ステータス遷移の妥当性チェック
    await this.validateStatusTransition(currentItem.currentStatus, newStatus);

    const now = new Date().toISOString();

    // アイテム更新
    const { data: updated, error } = await this.config.supabase
      .from(this.config.itemsTable)
      .update({
        currentStatus: newStatus,
        updatedAt: now
      })
      .eq('id', itemId)
      .select()
      .single();

    if (error) throw error;

    // 履歴記録
    await this.recordStatusChange(itemId, currentItem.currentStatus, newStatus, changedBy, comment);

    // 自動遷移チェック
    if (this.config.enableAutoTransitions && this.workflowConfig.autoTransitions) {
      const nextStatus = this.workflowConfig.autoTransitions[newStatus];
      if (nextStatus) {
        // 自動遷移の実行（非同期）
        setTimeout(() => {
          this.changeStatus(itemId, nextStatus, 'system', '自動遷移');
        }, 1000);
      }
    }

    // イベント発行
    this.emitEvent({
      type: 'status_changed',
      itemId,
      oldData: currentItem,
      newData: updated,
      changedBy,
      timestamp: now
    });

    return updated;
  }

  /**
   * アイテムを更新する
   */
  async updateItem(
    itemId: string, 
    updates: Partial<WorkflowItem<T>>, 
    changedBy: string
  ): Promise<WorkflowItem<T>> {
    const currentItem = await this.getItem(itemId);
    if (!currentItem) {
      throw new Error('Item not found');
    }

    const now = new Date().toISOString();

    const { data: updated, error } = await this.config.supabase
      .from(this.config.itemsTable)
      .update({
        ...updates,
        updatedAt: now
      })
      .eq('id', itemId)
      .select()
      .single();

    if (error) throw error;

    // イベント発行
    this.emitEvent({
      type: 'item_updated',
      itemId,
      oldData: currentItem,
      newData: updated,
      changedBy,
      timestamp: now
    });

    return updated;
  }

  /**
   * アイテムを削除する
   */
  async deleteItem(itemId: string, changedBy: string): Promise<void> {
    const currentItem = await this.getItem(itemId);
    if (!currentItem) {
      throw new Error('Item not found');
    }

    const { error } = await this.config.supabase
      .from(this.config.itemsTable)
      .delete()
      .eq('id', itemId);

    if (error) throw error;

    // イベント発行
    this.emitEvent({
      type: 'item_deleted',
      itemId,
      oldData: currentItem,
      changedBy,
      timestamp: new Date().toISOString()
    });
  }

  /**
   * 統計データを取得する
   */
  async getStatistics(): Promise<WorkflowStatistics<T>> {
    if (!this.workflowConfig) {
      throw new Error('Workflow configuration is not set');
    }

    const { data: items, error } = await this.config.supabase
      .from(this.config.itemsTable)
      .select('*');

    if (error) throw error;

    const totalItems = items?.length || 0;
    const statusCounts = items?.reduce((acc, item) => {
      acc[item.currentStatus] = (acc[item.currentStatus] || 0) + 1;
      return acc;
    }, {} as Record<T, number>) || {};

    // 最終ステップのアイテム数で完了率を計算
    const finalStatus = this.workflowConfig.steps[this.workflowConfig.steps.length - 1].id;
    const completedCount = statusCounts[finalStatus] || 0;
    const completionRate = totalItems > 0 ? (completedCount / totalItems) * 100 : 0;

    // 期限切れアイテム数
    const today = new Date().toISOString().split('T')[0];
    const overdueCount = items?.filter(item => 
      item.dueDate && item.dueDate < today && item.currentStatus !== finalStatus
    ).length || 0;

    // ボトルネック分析（最もアイテム数が多いステップ）
    const bottleneckStep = Object.entries(statusCounts)
      .sort(([,a], [,b]) => (b as number) - (a as number))[0]?.[0] as T;

    return {
      workflowId: this.workflowConfig.id,
      statusCounts,
      totalItems,
      completionRate: Math.round(completionRate * 100) / 100,
      bottleneckStep,
      overdueCount
    };
  }

  /**
   * ステータス変更履歴を取得する
   */
  async getStatusHistory(itemId?: string): Promise<StatusHistoryEntry<T>[]> {
    let query = this.config.supabase
      .from(this.config.historyTable)
      .select('*')
      .order('changedAt', { ascending: false });

    if (itemId) {
      query = query.eq('itemId', itemId);
    }

    const { data, error } = await query;
    if (error) throw error;

    return data || [];
  }

  /**
   * ステータス遷移の妥当性をチェック
   */
  private async validateStatusTransition(currentStatus: T, newStatus: T): Promise<void> {
    if (!this.workflowConfig) return;

    // 同じステータスへの遷移は許可
    if (currentStatus === newStatus) return;

    // 前進する場合は常に許可
    const currentIndex = this.workflowConfig.steps.findIndex(step => step.id === currentStatus);
    const newIndex = this.workflowConfig.steps.findIndex(step => step.id === newStatus);

    if (newIndex > currentIndex) return;

    // 後退（バックフロー）の場合はバックフローマップをチェック
    if (this.workflowConfig.backflowMap) {
      const allowedBackflows = this.workflowConfig.backflowMap[currentStatus];
      if (allowedBackflows && allowedBackflows.includes(newStatus)) return;
    }

    throw new Error(`Invalid status transition from ${currentStatus} to ${newStatus}`);
  }

  /**
   * ステータス変更履歴を記録
   */
  private async recordStatusChange(
    itemId: string,
    oldStatus: T | null,
    newStatus: T,
    changedBy: string,
    comment?: string
  ): Promise<void> {
    const historyEntry = {
      itemId,
      oldStatus,
      newStatus,
      changedBy,
      comment,
      changedAt: new Date().toISOString(),
      changeType: 'manual' as const
    };

    const { error } = await this.config.supabase
      .from(this.config.historyTable)
      .insert([historyEntry]);

    if (error) {
      console.error('Failed to record status change:', error);
      // 履歴記録の失敗はメイン処理をブロックしない
    }
  }

  /**
   * リアルタイム更新の初期化
   */
  private initializeRealtimeUpdates(): void {
    if (!this.config.enableRealtimeUpdates) return;

    this.config.supabase
      .channel(`${this.config.itemsTable}_changes`)
      .on('postgres_changes', 
        { 
          event: '*', 
          schema: 'public', 
          table: this.config.itemsTable 
        },
        (payload) => {
          // リアルタイム更新をイベントとして発行
          const eventType = payload.eventType === 'INSERT' ? 'item_created' :
                           payload.eventType === 'UPDATE' ? 'item_updated' :
                           'item_deleted';

          this.emitEvent({
            type: eventType,
            itemId: payload.new?.id || payload.old?.id,
            oldData: payload.old,
            newData: payload.new,
            changedBy: 'realtime',
            timestamp: new Date().toISOString()
          });
        }
      )
      .subscribe();
  }

  /**
   * イベントリスナーを追加
   */
  addEventListener(listener: (event: WorkflowChangeEvent<T>) => void): void {
    this.changeListeners.push(listener);
  }

  /**
   * イベントリスナーを削除
   */
  removeEventListener(listener: (event: WorkflowChangeEvent<T>) => void): void {
    const index = this.changeListeners.indexOf(listener);
    if (index > -1) {
      this.changeListeners.splice(index, 1);
    }
  }

  /**
   * イベントを発行
   */
  private emitEvent(event: WorkflowChangeEvent<T>): void {
    this.changeListeners.forEach(listener => {
      try {
        listener(event);
      } catch (error) {
        console.error('Event listener error:', error);
      }
    });
  }

  /**
   * クリーンアップ
   */
  destroy(): void {
    this.changeListeners = [];
    // Supabaseリアルタイム接続のクリーンアップは実装依存
  }
}

/**
 * ワークフローエンジンファクトリー
 */
export class WorkflowEngineFactory {
  /**
   * プリセット設定でワークフローエンジンを作成
   */
  static createWithPreset<T extends string>(
    config: WorkflowEngineConfig,
    presetName: keyof typeof WORKFLOW_PRESETS
  ): WorkflowEngine<T> {
    const engine = new WorkflowEngine<T>(config);
    const preset = WORKFLOW_PRESETS[presetName] as WorkflowConfig<T>;
    engine.setWorkflowConfig(preset);
    return engine;
  }

  /**
   * PMliberary形式の制作ワークフローエンジンを作成
   */
  static createProductionWorkflow(
    config: WorkflowEngineConfig
  ): WorkflowEngine<string> {
    return this.createWithPreset(config, 'production');
  }

  /**
   * シンプルなタスク管理ワークフローエンジンを作成
   */
  static createSimpleWorkflow(
    config: WorkflowEngineConfig
  ): WorkflowEngine<'todo' | 'in_progress' | 'done'> {
    return this.createWithPreset(config, 'simple');
  }
}

export default WorkflowEngine;