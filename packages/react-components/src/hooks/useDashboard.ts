import { useState, useEffect, useCallback, useMemo } from 'react';
import { SupabaseClient } from '@supabase/supabase-js';

/**
 * ダッシュボードウィジェットの設定
 */
export interface DashboardWidget {
  /** ウィジェットのID */
  id: string;
  /** ウィジェット名 */
  name: string;
  /** 表示順序 */
  order: number;
  /** 表示するかどうか */
  visible: boolean;
  /** 折り畳み状態 */
  collapsed: boolean;
  /** ウィジェットのサイズ */
  size: 'sm' | 'md' | 'lg' | 'xl';
  /** ウィジェットの設定データ */
  config?: Record<string, any>;
}

/**
 * ダッシュボード設定
 */
export interface DashboardConfig {
  /** ダッシュボードのレイアウト */
  layout: 'grid' | 'list' | 'masonry';
  /** グリッドのカラム数 */
  columns: number;
  /** テーマ設定 */
  theme: 'light' | 'dark' | 'auto';
  /** 自動更新間隔（秒） */
  refreshInterval?: number;
  /** ウィジェット設定 */
  widgets: DashboardWidget[];
}

/**
 * ダッシュボード統計データ
 */
export interface DashboardStats {
  /** 総アイテム数 */
  totalItems: number;
  /** 今日作成されたアイテム数 */
  todayItems: number;
  /** 期限切れアイテム数 */
  overdueItems: number;
  /** 完了率 */
  completionRate: number;
  /** アクティブユーザー数 */
  activeUsers?: number;
  /** カスタム統計 */
  customStats?: Record<string, number>;
}

/**
 * ダッシュボードフックの設定
 */
export interface UseDashboardConfig {
  /** Supabaseクライアント */
  supabase?: SupabaseClient;
  /** ユーザーID */
  userId?: string;
  /** 自動更新を有効にするか */
  enableAutoRefresh?: boolean;
  /** デフォルトの更新間隔（秒） */
  defaultRefreshInterval?: number;
  /** 統計データを取得するテーブル名 */
  statsTable?: string;
  /** ダッシュボード設定を保存するテーブル名 */
  configTable?: string;
}

/**
 * ダッシュボード管理フック
 * 
 * ダッシュボードの状態管理、ウィジェット設定、統計データの取得を行う汎用フック
 * 
 * @example
 * ```tsx
 * function Dashboard() {
 *   const {
 *     config,
 *     stats,
 *     loading,
 *     error,
 *     updateWidget,
 *     refreshStats,
 *     saveConfig
 *   } = useDashboard({
 *     supabase,
 *     userId: user?.id,
 *     enableAutoRefresh: true
 *   });
 * 
 *   return (
 *     <DashboardGrid columns={config.columns}>
 *       {config.widgets
 *         .filter(w => w.visible)
 *         .map(widget => (
 *           <DashboardWidget
 *             key={widget.id}
 *             title={widget.name}
 *             isCollapsed={widget.collapsed}
 *             onToggleCollapse={(collapsed) => 
 *               updateWidget(widget.id, { collapsed })
 *             }
 *           >
 *             <WidgetContent widgetId={widget.id} />
 *           </DashboardWidget>
 *         ))
 *       }
 *     </DashboardGrid>
 *   );
 * }
 * ```
 */
export function useDashboard(options: UseDashboardConfig = {}) {
  const {
    supabase,
    userId,
    enableAutoRefresh = false,
    defaultRefreshInterval = 300, // 5分
    statsTable = 'dashboard_stats',
    configTable = 'dashboard_configs'
  } = options;

  // 状態管理
  const [config, setConfig] = useState<DashboardConfig>({
    layout: 'grid',
    columns: 2,
    theme: 'light',
    refreshInterval: defaultRefreshInterval,
    widgets: []
  });

  const [stats, setStats] = useState<DashboardStats>({
    totalItems: 0,
    todayItems: 0,
    overdueItems: 0,
    completionRate: 0
  });

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [lastRefresh, setLastRefresh] = useState<Date | null>(null);

  // エラーハンドリング
  const handleError = useCallback((err: any) => {
    const message = err?.message || 'エラーが発生しました';
    setError(message);
    console.error('Dashboard error:', err);
  }, []);

  // ダッシュボード設定の読み込み
  const loadConfig = useCallback(async () => {
    if (!supabase || !userId) return;

    try {
      setLoading(true);
      const { data, error } = await supabase
        .from(configTable)
        .select('*')
        .eq('user_id', userId)
        .single();

      if (error && error.code !== 'PGRST116') { // レコードが見つからない場合以外
        throw error;
      }

      if (data) {
        setConfig(data.config);
      }
    } catch (err) {
      handleError(err);
    } finally {
      setLoading(false);
    }
  }, [supabase, userId, configTable, handleError]);

  // 統計データの取得
  const loadStats = useCallback(async () => {
    if (!supabase) return;

    try {
      // カスタム統計取得ロジック（実装依存）
      // 実際の実装では、statsTableからデータを取得するか、
      // 複数のテーブルから集計を行う
      
      const today = new Date().toISOString().split('T')[0];
      
      // 例: エピソードテーブルから統計を取得
      const [totalResult, todayResult, overdueResult] = await Promise.all([
        supabase.from('episodes').select('count', { count: 'exact' }),
        supabase.from('episodes').select('count', { count: 'exact' }).gte('created_at', today),
        supabase.from('episodes').select('count', { count: 'exact' }).lt('due_date', today)
      ]);

      const newStats: DashboardStats = {
        totalItems: totalResult.count || 0,
        todayItems: todayResult.count || 0,
        overdueItems: overdueResult.count || 0,
        completionRate: 0 // 計算ロジック実装
      };

      setStats(newStats);
      setLastRefresh(new Date());
      setError(null);
    } catch (err) {
      handleError(err);
    }
  }, [supabase, handleError]);

  // 設定の保存
  const saveConfig = useCallback(async (newConfig: Partial<DashboardConfig>) => {
    if (!supabase || !userId) return;

    try {
      setLoading(true);
      const updatedConfig = { ...config, ...newConfig };
      
      const { error } = await supabase
        .from(configTable)
        .upsert({
          user_id: userId,
          config: updatedConfig,
          updated_at: new Date().toISOString()
        });

      if (error) throw error;

      setConfig(updatedConfig);
    } catch (err) {
      handleError(err);
    } finally {
      setLoading(false);
    }
  }, [supabase, userId, configTable, config, handleError]);

  // ウィジェット設定の更新
  const updateWidget = useCallback(async (widgetId: string, updates: Partial<DashboardWidget>) => {
    const updatedWidgets = config.widgets.map(widget =>
      widget.id === widgetId ? { ...widget, ...updates } : widget
    );

    await saveConfig({ widgets: updatedWidgets });
  }, [config.widgets, saveConfig]);

  // ウィジェットの追加
  const addWidget = useCallback(async (widget: Omit<DashboardWidget, 'order'>) => {
    const maxOrder = Math.max(...config.widgets.map(w => w.order), 0);
    const newWidget: DashboardWidget = {
      ...widget,
      order: maxOrder + 1
    };

    await saveConfig({ widgets: [...config.widgets, newWidget] });
  }, [config.widgets, saveConfig]);

  // ウィジェットの削除
  const removeWidget = useCallback(async (widgetId: string) => {
    const updatedWidgets = config.widgets.filter(widget => widget.id !== widgetId);
    await saveConfig({ widgets: updatedWidgets });
  }, [config.widgets, saveConfig]);

  // ウィジェットの並び替え
  const reorderWidgets = useCallback(async (widgetIds: string[]) => {
    const updatedWidgets = widgetIds.map((id, index) => {
      const widget = config.widgets.find(w => w.id === id);
      return widget ? { ...widget, order: index } : null;
    }).filter(Boolean) as DashboardWidget[];

    await saveConfig({ widgets: updatedWidgets });
  }, [config.widgets, saveConfig]);

  // 統計データの手動更新
  const refreshStats = useCallback(() => {
    loadStats();
  }, [loadStats]);

  // 全体のリフレッシュ
  const refresh = useCallback(() => {
    loadConfig();
    loadStats();
  }, [loadConfig, loadStats]);

  // 自動更新の設定
  useEffect(() => {
    if (enableAutoRefresh && config.refreshInterval) {
      const interval = setInterval(loadStats, config.refreshInterval * 1000);
      return () => clearInterval(interval);
    }
  }, [enableAutoRefresh, config.refreshInterval, loadStats]);

  // 初期化
  useEffect(() => {
    if (supabase) {
      loadConfig();
      loadStats();
    }
  }, [supabase, loadConfig, loadStats]);

  // 表示用ウィジェットのソート
  const sortedVisibleWidgets = useMemo(() => {
    return config.widgets
      .filter(widget => widget.visible)
      .sort((a, b) => a.order - b.order);
  }, [config.widgets]);

  // 統計サマリー
  const statsSummary = useMemo(() => {
    return {
      ...stats,
      growthRate: lastRefresh ? 0 : 0, // 前回比較実装
      lastUpdated: lastRefresh
    };
  }, [stats, lastRefresh]);

  return {
    // 状態
    config,
    stats: statsSummary,
    loading,
    error,
    lastRefresh,

    // ウィジェット管理
    updateWidget,
    addWidget,
    removeWidget,
    reorderWidgets,
    sortedVisibleWidgets,

    // 設定管理
    saveConfig,
    
    // データ更新
    refreshStats,
    refresh,

    // ユーティリティ
    clearError: () => setError(null)
  };
}

/**
 * ダッシュボードウィジェット用の個別データ管理フック
 */
export function useWidgetData<T = any>(
  widgetId: string,
  dataLoader: () => Promise<T>,
  dependencies: any[] = []
) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const loadData = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const result = await dataLoader();
      setData(result);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'データの取得に失敗しました');
    } finally {
      setLoading(false);
    }
  }, [dataLoader]);

  useEffect(() => {
    loadData();
  }, [loadData, ...dependencies]);

  return {
    data,
    loading,
    error,
    reload: loadData,
    clearError: () => setError(null)
  };
}

export default useDashboard;