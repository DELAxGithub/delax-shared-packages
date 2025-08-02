import { useState, useEffect, useCallback } from 'react';
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
export function useDashboard(api, options = {}) {
    const { autoRefreshInterval, initialFilter = {}, onError, onSuccess } = options;
    // 状態管理
    const [widgets, setWidgets] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [filter, setFilter] = useState(initialFilter);
    // エラーハンドリング
    const handleError = useCallback((err) => {
        const errorMessage = err instanceof Error ? err.message : 'ダッシュボードでエラーが発生しました';
        setError(errorMessage);
        setLoading(false);
        if (onError) {
            onError(err instanceof Error ? err : new Error(errorMessage));
        }
    }, [onError]);
    // 成功時のコールバック
    const handleSuccess = useCallback((message) => {
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
        }
        catch (err) {
            handleError(err);
        }
        finally {
            setLoading(false);
        }
    }, [api, filter, handleError, handleSuccess]);
    // ウィジェットの作成
    const createWidget = useCallback(async (widget) => {
        try {
            setLoading(true);
            const newWidget = await api.createDashboardWidget(widget);
            setWidgets(prev => [...prev, newWidget]);
            handleSuccess('ウィジェットを作成しました');
            return newWidget;
        }
        catch (err) {
            handleError(err);
            return null;
        }
        finally {
            setLoading(false);
        }
    }, [api, handleError, handleSuccess]);
    // ウィジェットの更新
    const updateWidget = useCallback(async (id, updates) => {
        try {
            setLoading(true);
            const updatedWidget = await api.updateDashboardWidget(id, updates);
            setWidgets(prev => prev.map(widget => widget.id === id ? updatedWidget : widget));
            handleSuccess('ウィジェットを更新しました');
            return updatedWidget;
        }
        catch (err) {
            handleError(err);
            return null;
        }
        finally {
            setLoading(false);
        }
    }, [api, handleError, handleSuccess]);
    // ウィジェットの削除
    const deleteWidget = useCallback(async (id) => {
        try {
            setLoading(true);
            await api.deleteDashboardWidget(id);
            setWidgets(prev => prev.filter(widget => widget.id !== id));
            handleSuccess('ウィジェットを削除しました');
            return true;
        }
        catch (err) {
            handleError(err);
            return false;
        }
        finally {
            setLoading(false);
        }
    }, [api, handleError, handleSuccess]);
    // ウィジェットの並び替え
    const reorderWidgets = useCallback(async (widgetIds) => {
        try {
            setLoading(true);
            await api.reorderWidgets(widgetIds);
            // 新しい順序でソート
            setWidgets(prev => {
                const widgetMap = new Map(prev.map(w => [w.id, w]));
                return widgetIds.map((id, index) => ({
                    ...widgetMap.get(id),
                    sort_order: index + 1
                }));
            });
            handleSuccess('ウィジェットの順序を変更しました');
            return true;
        }
        catch (err) {
            handleError(err);
            return false;
        }
        finally {
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
        if (!autoRefreshInterval)
            return;
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
//# sourceMappingURL=index.js.map