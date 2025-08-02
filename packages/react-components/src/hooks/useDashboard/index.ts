import { useState, useEffect, useCallback } from 'react';
import type { DashboardWidget, NewDashboardWidget, UpdateDashboardWidget, DashboardFilter } from '../../types/dashboard';

/**
 * ダッシュボードAPI関数の型定義
 * 実装側でこれらの関数を提供する必要があります
 */
export interface DashboardAPI {
  getDashboardWidgets: (filter?: DashboardFilter) => Promise<DashboardWidget[]>;
  createDashboardWidget: (widget: NewDashboardWidget) => Promise<DashboardWidget>;
  updateDashboardWidget: (id: string, updates: UpdateDashboardWidget) => Promise<DashboardWidget>;
  deleteDashboardWidget: (id: string) => Promise<void>;
  reorderWidgets: (widgetIds: string[]) => Promise<void>;
}

/**
 * ダッシュボードフックの設定オプション
 */
export interface UseDashboardOptions {
  /** 自動リフレッシュ間隔（ミリ秒） */
  autoRefreshInterval?: number;
  /** 初期フィルター */
  initialFilter?: DashboardFilter;
  /** エラーハンドリング */
  onError?: (error: Error) => void;
  /** 成功時のコールバック */
  onSuccess?: (message: string) => void;
}

/**
 * ダッシュボードフックの戻り値
 */
export interface UseDashboardReturn {
  /** ウィジェット一覧 */
  widgets: DashboardWidget[];
  /** ロード中状態 */
  loading: boolean;
  /** エラー状態 */
  error: string | null;
  /** フィルター状態 */
  filter: DashboardFilter;
  /** ウィジェット一覧の再取得 */
  refreshWidgets: () => Promise<void>;
  /** ウィジェットの作成 */
  createWidget: (widget: NewDashboardWidget) => Promise<DashboardWidget | null>;
  /** ウィジェットの更新 */
  updateWidget: (id: string, updates: UpdateDashboardWidget) => Promise<DashboardWidget | null>;
  /** ウィジェットの削除 */
  deleteWidget: (id: string) => Promise<boolean>;
  /** ウィジェットの並び替え */
  reorderWidgets: (widgetIds: string[]) => Promise<boolean>;
  /** フィルターの設定 */
  setFilter: (filter: DashboardFilter) => void;
  /** フィルターのクリア */
  clearFilter: () => void;
  /** ローディング状態の設定 */
  setLoading: (loading: boolean) => void;
  /** エラー状態のクリア */
  clearError: () => void;
}

/**
 * ダッシュボード管理用カスタムフック
 * 
 * ダッシュボードウィジェットの取得、作成、更新、削除、並び替えを管理します。
 * 自動リフレッシュ、フィルタリング、エラーハンドリング機能を提供します。
 * 
 * @param api ダッシュボードAPI関数群
 * @param options フックのオプション設定
 * @returns ダッシュボード管理用の状態と関数
 * 
 * @example
 * ```tsx
 * // API関数を定義
 * const dashboardAPI: DashboardAPI = {
 *   getDashboardWidgets: async (filter) => {
 *     // ウィジェット取得の実装
 *   },
 *   createDashboardWidget: async (widget) => {
 *     // ウィジェット作成の実装
 *   },
 *   // ... 他のAPI関数
 * };
 * 
 * // フックを使用
 * const {
 *   widgets,
 *   loading,
 *   error,
 *   refreshWidgets,
 *   createWidget,
 *   updateWidget
 * } = useDashboard(dashboardAPI, {
 *   autoRefreshInterval: 30000, // 30秒ごとに自動リフレッシュ
 *   onError: (error) => console.error('Dashboard error:', error)
 * });
 * ```
 */
export function useDashboard(
  api: DashboardAPI,
  options: UseDashboardOptions = {}
): UseDashboardReturn {
  const {
    autoRefreshInterval,
    initialFilter = {},
    onError,
    onSuccess
  } = options;

  // 状態管理
  const [widgets, setWidgets] = useState<DashboardWidget[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<DashboardFilter>(initialFilter);

  // エラーハンドリング
  const handleError = useCallback((err: unknown) => {
    const errorMessage = err instanceof Error ? err.message : 'ダッシュボードでエラーが発生しました';
    setError(errorMessage);
    setLoading(false);
    if (onError) {
      onError(err instanceof Error ? err : new Error(errorMessage));
    }
  }, [onError]);

  // 成功時のコールバック
  const handleSuccess = useCallback((message: string) => {
    setError(null);
    if (onSuccess) {
      onSuccess(message);
    }
  }, [onSuccess]);

  // ウィジェット一覧の取得
  const fetchWidgets = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await api.getDashboardWidgets(filter);
      setWidgets(data);
      handleSuccess('ウィジェットを正常に取得しました');
    } catch (err) {
      handleError(err);
    } finally {
      setLoading(false);
    }
  }, [api, filter, handleError, handleSuccess]);

  // ウィジェットの作成
  const createWidget = useCallback(async (widget: NewDashboardWidget): Promise<DashboardWidget | null> => {
    try {
      setLoading(true);
      const newWidget = await api.createDashboardWidget(widget);
      setWidgets(prev => [...prev, newWidget]);
      handleSuccess('ウィジェットを作成しました');
      return newWidget;
    } catch (err) {
      handleError(err);
      return null;
    } finally {
      setLoading(false);
    }
  }, [api, handleError, handleSuccess]);

  // ウィジェットの更新
  const updateWidget = useCallback(async (id: string, updates: UpdateDashboardWidget): Promise<DashboardWidget | null> => {
    try {
      setLoading(true);
      const updatedWidget = await api.updateDashboardWidget(id, updates);
      setWidgets(prev => 
        prev.map(widget => 
          widget.id === id ? updatedWidget : widget
        )
      );
      handleSuccess('ウィジェットを更新しました');
      return updatedWidget;
    } catch (err) {
      handleError(err);
      return null;
    } finally {
      setLoading(false);
    }
  }, [api, handleError, handleSuccess]);

  // ウィジェットの削除
  const deleteWidget = useCallback(async (id: string): Promise<boolean> => {
    try {
      setLoading(true);
      await api.deleteDashboardWidget(id);
      setWidgets(prev => prev.filter(widget => widget.id !== id));
      handleSuccess('ウィジェットを削除しました');
      return true;
    } catch (err) {
      handleError(err);
      return false;
    } finally {
      setLoading(false);
    }
  }, [api, handleError, handleSuccess]);

  // ウィジェットの並び替え
  const reorderWidgets = useCallback(async (widgetIds: string[]): Promise<boolean> => {
    try {
      setLoading(true);
      await api.reorderWidgets(widgetIds);
      // 新しい順序でソート
      setWidgets(prev => {
        const widgetMap = new Map(prev.map(w => [w.id, w]));
        return widgetIds.map((id, index) => ({
          ...widgetMap.get(id)!,
          sort_order: index + 1
        }));
      });
      handleSuccess('ウィジェットの順序を変更しました');
      return true;
    } catch (err) {
      handleError(err);
      return false;
    } finally {
      setLoading(false);
    }
  }, [api, handleError, handleSuccess]);

  // フィルターのクリア
  const clearFilter = useCallback(() => {
    setFilter({});
  }, []);

  // エラーのクリア
  const clearError = useCallback(() => {
    setError(null);
  }, []);

  // 初回ロード
  useEffect(() => {
    fetchWidgets();
  }, [fetchWidgets]);

  // 自動リフレッシュ
  useEffect(() => {
    if (!autoRefreshInterval) return;

    const interval = setInterval(() => {
      fetchWidgets();
    }, autoRefreshInterval);

    return () => clearInterval(interval);
  }, [autoRefreshInterval, fetchWidgets]);

  return {
    widgets,
    loading,
    error,
    filter,
    refreshWidgets: fetchWidgets,
    createWidget,
    updateWidget,
    deleteWidget,
    reorderWidgets,
    setFilter,
    clearFilter,
    setLoading,
    clearError,
  };
}

export default useDashboard;