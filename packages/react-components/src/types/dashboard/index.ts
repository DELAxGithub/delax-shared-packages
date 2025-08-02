/**
 * ダッシュボードウィジェット基本情報
 */
export interface DashboardWidget {
  id: string;
  widget_type: 'quicklinks' | 'memo' | 'tasks' | 'schedule' | 'custom';
  title: string;
  content: QuickLinksContent | MemoContent | TasksContent | ScheduleContent | CustomContent;
  sort_order: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

/**
 * クイックリンク項目
 */
export interface QuickLink {
  url: string;
  label: string;
  description?: string;
  icon?: string;
}

/**
 * クイックリンクウィジェットのコンテンツ
 */
export interface QuickLinksContent {
  links: QuickLink[];
}

/**
 * メモウィジェットのコンテンツ
 */
export interface MemoContent {
  text: string;
  lastModified?: string;
}

/**
 * タスク項目
 */
export interface Task {
  id: string;
  text: string;
  completed: boolean;
  dueDate?: string;
  priority?: 'low' | 'medium' | 'high';
  tags?: string[];
}

/**
 * タスクウィジェットのコンテンツ
 */
export interface TasksContent {
  tasks: Task[];
  showCompleted?: boolean;
  sortBy?: 'dueDate' | 'priority' | 'created' | 'alphabetical';
}

/**
 * スケジュールウィジェットのコンテンツ
 */
export interface ScheduleContent {
  events?: ScheduleEvent[];
  viewMode?: 'day' | 'week' | 'month';
}

/**
 * スケジュールイベント
 */
export interface ScheduleEvent {
  id: string;
  title: string;
  start: string;
  end?: string;
  description?: string;
  type?: 'meeting' | 'task' | 'deadline' | 'event';
}

/**
 * カスタムウィジェットのコンテンツ
 */
export interface CustomContent {
  data: Record<string, unknown>;
  template?: string;
}

/**
 * ウィジェット作成用型
 */
export type NewDashboardWidget = Omit<DashboardWidget, 'id' | 'created_at' | 'updated_at'>;

/**
 * ウィジェット更新用型
 */
export type UpdateDashboardWidget = Partial<Omit<DashboardWidget, 'id' | 'created_at' | 'updated_at'>>;

/**
 * ダッシュボード設定
 */
export interface DashboardConfig {
  id: string;
  user_id: string;
  layout: 'grid' | 'list' | 'masonry';
  columns: number;
  theme: 'light' | 'dark' | 'auto';
  auto_refresh: boolean;
  refresh_interval: number; // seconds
  widget_spacing: 'compact' | 'normal' | 'spacious';
}

/**
 * ダッシュボードレイアウト情報
 */
export interface DashboardLayout {
  widget_id: string;
  x: number;
  y: number;
  width: number;
  height: number;
  minWidth?: number;
  minHeight?: number;
  maxWidth?: number;
  maxHeight?: number;
}

/**
 * ダッシュボードフィルター
 */
export interface DashboardFilter {
  widget_types?: string[];
  active_only?: boolean;
  search_term?: string;
  date_range?: {
    start: string;
    end: string;
  };
}

/**
 * ダッシュボード統計情報
 */
export interface DashboardStats {
  total_widgets: number;
  active_widgets: number;
  last_updated: string;
  most_used_widget_type: string;
}

/**
 * ウィジェット操作結果
 */
export interface WidgetOperationResult {
  success: boolean;
  message: string;
  widget?: DashboardWidget;
  error?: string;
}

/**
 * ダッシュボードユーティリティクラス
 */
export class DashboardUtils {
  /**
   * ウィジェットをソート順で並び替え
   */
  static sortWidgets(widgets: DashboardWidget[]): DashboardWidget[] {
    return [...widgets].sort((a, b) => a.sort_order - b.sort_order);
  }

  /**
   * アクティブなウィジェットのみをフィルター
   */
  static filterActiveWidgets(widgets: DashboardWidget[]): DashboardWidget[] {
    return widgets.filter(widget => widget.is_active);
  }

  /**
   * ウィジェットタイプでフィルター
   */
  static filterByType(widgets: DashboardWidget[], type: string): DashboardWidget[] {
    return widgets.filter(widget => widget.widget_type === type);
  }

  /**
   * ウィジェットのコンテンツが有効かチェック
   */
  static isValidContent(widget: DashboardWidget): boolean {
    switch (widget.widget_type) {
      case 'quicklinks':
        return !!(widget.content as QuickLinksContent).links?.length;
      case 'memo':
        return !!(widget.content as MemoContent).text?.trim();
      case 'tasks':
        return !!(widget.content as TasksContent).tasks?.length;
      case 'schedule':
        return true; // スケジュールは常に有効
      case 'custom':
        return !!(widget.content as CustomContent).data;
      default:
        return false;
    }
  }

  /**
   * 新しいソート順を生成
   */
  static generateSortOrder(widgets: DashboardWidget[]): number {
    return widgets.length > 0 ? Math.max(...widgets.map(w => w.sort_order)) + 1 : 1;
  }
}