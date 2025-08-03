/**
 * ワークフロー管理用の型定義
 */

/**
 * ワークフローステップの定義
 */
export interface WorkflowStep<T extends string = string> {
  /** ステップのID */
  id: T;
  /** ステップ名 */
  name: string;
  /** 説明 */
  description?: string;
  /** 表示順序 */
  order: number;
  /** 表示色 */
  color: string;
  /** 必須ステップかどうか */
  required?: boolean;
  /** 前提条件となるステップ */
  prerequisites?: T[];
  /** 推定所要時間（分） */
  estimatedMinutes?: number;
}

/**
 * ワークフロー設定
 */
export interface WorkflowConfig<T extends string = string> {
  /** ワークフローのID */
  id: string;
  /** ワークフロー名 */
  name: string;
  /** 説明 */
  description?: string;
  /** ステップ定義 */
  steps: WorkflowStep<T>[];
  /** バックフロー（戻り）が可能なステップのマッピング */
  backflowMap?: Record<T, T[]>;
  /** 自動遷移の設定 */
  autoTransitions?: Record<T, T>;
}

/**
 * ワークフローアイテム（実際の作業項目）
 */
export interface WorkflowItem<T extends string = string, D = any> {
  /** アイテムID */
  id: string;
  /** アイテム名 */
  title: string;
  /** 現在のステータス */
  currentStatus: T;
  /** ワークフロー設定ID */
  workflowId: string;
  /** 作成日時 */
  createdAt: string;
  /** 更新日時 */
  updatedAt: string;
  /** 担当者 */
  assignee?: string;
  /** 期限 */
  dueDate?: string;
  /** 優先度 */
  priority?: 'low' | 'medium' | 'high' | 'urgent';
  /** 追加データ */
  data?: D;
  /** タグ */
  tags?: string[];
}

/**
 * ステータス変更履歴
 */
export interface StatusHistoryEntry<T extends string = string> {
  /** 履歴ID */
  id: string;
  /** アイテムID */
  itemId: string;
  /** 変更前ステータス */
  oldStatus: T | null;
  /** 変更後ステータス */
  newStatus: T;
  /** 変更者 */
  changedBy: string;
  /** 変更理由・コメント */
  comment?: string;
  /** 変更日時 */
  changedAt: string;
  /** 変更タイプ */
  changeType: 'manual' | 'auto' | 'bulk';
}

/**
 * ワークフロー統計情報
 */
export interface WorkflowStatistics<T extends string = string> {
  /** ワークフローID */
  workflowId: string;
  /** ステータス別アイテム数 */
  statusCounts: Record<T, number>;
  /** 総アイテム数 */
  totalItems: number;
  /** 完了率（最終ステップの割合） */
  completionRate: number;
  /** 平均処理時間（分） */
  averageProcessingTime?: number;
  /** ボトルネックステップ */
  bottleneckStep?: T;
  /** 期限超過アイテム数 */
  overdueCount: number;
}

/**
 * ワークフロー設定のプリセット
 */
export const WORKFLOW_PRESETS = {
  /** 制作ワークフロー（PMliberaryベース） */
  production: {
    id: 'production',
    name: '制作ワークフロー',
    description: '番組・動画制作の標準的なワークフロー',
    steps: [
      { id: '台本作成中', name: '台本作成中', order: 1, color: '#f59e0b' },
      { id: '素材準備', name: '素材準備', order: 2, color: '#f97316' },
      { id: '素材確定', name: '素材確定', order: 3, color: '#eab308' },
      { id: '編集中', name: '編集中', order: 4, color: '#3b82f6' },
      { id: '試写1', name: '試写1', order: 5, color: '#8b5cf6' },
      { id: '修正1', name: '修正1', order: 6, color: '#ec4899' },
      { id: 'MA中', name: 'MA中', order: 7, color: '#06b6d4' },
      { id: '初稿完成', name: '初稿完成', order: 8, color: '#10b981' },
      { id: '修正中', name: '修正中', order: 9, color: '#f59e0b' },
      { id: '完パケ納品', name: '完パケ納品', order: 10, color: '#059669' }
    ],
    backflowMap: {
      '試写1': ['編集中'],
      '初稿完成': ['修正1', 'MA中'],
      '修正中': ['編集中']
    }
  } as WorkflowConfig,

  /** シンプルなタスク管理 */
  simple: {
    id: 'simple',
    name: 'シンプルタスク',
    description: '基本的なTODO管理ワークフロー',
    steps: [
      { id: 'todo', name: 'TODO', order: 1, color: '#6b7280' },
      { id: 'in_progress', name: '進行中', order: 2, color: '#3b82f6' },
      { id: 'done', name: '完了', order: 3, color: '#10b981' }
    ]
  } as WorkflowConfig,

  /** アジャイル開発 */
  agile: {
    id: 'agile',
    name: 'アジャイル開発',
    description: 'スクラム・アジャイル開発のワークフロー',
    steps: [
      { id: 'backlog', name: 'バックログ', order: 1, color: '#6b7280' },
      { id: 'sprint_planning', name: 'スプリント計画', order: 2, color: '#f59e0b' },
      { id: 'in_development', name: '開発中', order: 3, color: '#3b82f6' },
      { id: 'code_review', name: 'コードレビュー', order: 4, color: '#8b5cf6' },
      { id: 'testing', name: 'テスト', order: 5, color: '#ec4899' },
      { id: 'done', name: '完了', order: 6, color: '#10b981' }
    ],
    backflowMap: {
      'code_review': ['in_development'],
      'testing': ['in_development', 'code_review']
    }
  } as WorkflowConfig
} as const;

/**
 * ワークフローアイテムの型推論ヘルパー
 */
export type InferWorkflowStatus<T extends WorkflowConfig> = 
  T extends WorkflowConfig<infer U> ? U : never;

/**
 * ワークフローステップの検索・フィルター条件
 */
export interface WorkflowFilterOptions<T extends string = string> {
  /** ステータスでフィルター */
  status?: T | T[];
  /** 担当者でフィルター */
  assignee?: string;
  /** 期限でフィルター */
  dueDateRange?: {
    from?: string;
    to?: string;
  };
  /** 優先度でフィルター */
  priority?: WorkflowItem['priority'];
  /** タグでフィルター */
  tags?: string[];
  /** 期限超過のみ */
  overdueOnly?: boolean;
  /** 検索クエリ */
  searchQuery?: string;
}