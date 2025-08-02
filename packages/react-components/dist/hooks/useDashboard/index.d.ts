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
export declare function useDashboard(api: DashboardAPI, options?: UseDashboardOptions): UseDashboardReturn;
export default useDashboard;
//# sourceMappingURL=index.d.ts.map