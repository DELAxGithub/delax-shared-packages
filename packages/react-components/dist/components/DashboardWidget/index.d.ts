import React from 'react';
/**
 * DashboardWidgetコンポーネントのプロパティ
 */
export interface DashboardWidgetProps {
    /** ウィジェットのタイトル */
    title: string;
    /** 折りたたみ状態 */
    isCollapsed?: boolean;
    /** 折りたたみ状態変更ハンドラー */
    onToggleCollapse?: () => void;
    /** ウィジェットの内容 */
    children: React.ReactNode;
    /** カスタムクラス名 */
    className?: string;
    /** ヘッダーのカスタムクラス名 */
    headerClassName?: string;
    /** コンテンツのカスタムクラス名 */
    contentClassName?: string;
    /** アニメーション有効化 */
    animate?: boolean;
}
/**
 * ダッシュボードウィジェットコンポーネント
 *
 * 折りたたみ可能なダッシュボードウィジェットを提供します。
 * 管理画面やダッシュボードで情報をグループ化して表示する際に使用します。
 *
 * @param props DashboardWidgetProps
 * @returns JSX要素
 *
 * @example
 * ```tsx
 * // 基本的な使用
 * <DashboardWidget title="タスク一覧">
 *   <div>タスクの内容</div>
 * </DashboardWidget>
 *
 * // 折りたたみ機能付き
 * const [collapsed, setCollapsed] = useState(false);
 * <DashboardWidget
 *   title="統計情報"
 *   isCollapsed={collapsed}
 *   onToggleCollapse={() => setCollapsed(!collapsed)}
 * >
 *   <div>統計データ</div>
 * </DashboardWidget>
 *
 * // カスタムスタイル適用
 * <DashboardWidget
 *   title="メモ"
 *   className="mb-4"
 *   headerClassName="bg-blue-50"
 *   contentClassName="p-4"
 * >
 *   <textarea className="w-full" />
 * </DashboardWidget>
 * ```
 */
export declare function DashboardWidget({ title, isCollapsed, onToggleCollapse, children, className, headerClassName, contentClassName, animate }: DashboardWidgetProps): import("react/jsx-runtime").JSX.Element;
/**
 * ダッシュボードウィジェットコンテナー
 * 複数のDashboardWidgetをまとめて管理するコンテナー
 */
export interface DashboardWidgetContainerProps {
    /** ウィジェットのリスト */
    children: React.ReactNode;
    /** コンテナーのカスタムクラス名 */
    className?: string;
    /** 全ウィジェットの折りたたみ状態制御 */
    allCollapsed?: boolean;
    /** 全体の折りたたみ制御ハンドラー */
    onToggleAll?: () => void;
    /** コンテナーのタイトル */
    title?: string;
}
export declare function DashboardWidgetContainer({ children, className, allCollapsed, onToggleAll, title }: DashboardWidgetContainerProps): import("react/jsx-runtime").JSX.Element;
export default DashboardWidget;
//# sourceMappingURL=index.d.ts.map