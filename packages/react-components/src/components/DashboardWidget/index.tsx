import React from 'react';
import { ChevronDown, ChevronRight } from 'lucide-react';

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
export function DashboardWidget({ 
  title, 
  isCollapsed = false, 
  onToggleCollapse,
  children,
  className = '',
  headerClassName = '',
  contentClassName = '',
  animate = true
}: DashboardWidgetProps) {
  const baseHeaderClass = `w-full flex items-center justify-between px-3 py-2 text-left text-sm font-medium text-gray-700 hover:bg-gray-50 ${animate ? 'transition-colors' : ''}`;
  const baseContentClass = `px-3 pb-3 text-sm ${animate ? 'transition-all duration-200 ease-in-out' : ''}`;

  return (
    <div className={`border-b border-gray-200 last:border-b-0 ${className}`}>
      <button
        onClick={onToggleCollapse}
        className={`${baseHeaderClass} ${headerClassName}`}
        disabled={!onToggleCollapse}
        type="button"
        aria-expanded={!isCollapsed}
        aria-controls={`widget-content-${title.replace(/\s+/g, '-').toLowerCase()}`}
      >
        <span>{title}</span>
        {onToggleCollapse && (
          <span 
            className={`text-gray-400 ${animate ? 'transition-transform duration-200' : ''}`}
            style={{
              transform: isCollapsed ? 'rotate(0deg)' : 'rotate(90deg)'
            }}
          >
            {isCollapsed ? (
              <ChevronRight size={16} />
            ) : (
              <ChevronDown size={16} />
            )}
          </span>
        )}
      </button>
      
      <div
        id={`widget-content-${title.replace(/\s+/g, '-').toLowerCase()}`}
        className={`overflow-hidden ${animate ? 'transition-all duration-200 ease-in-out' : ''}`}
        style={{
          maxHeight: isCollapsed ? '0px' : '1000px',
          opacity: isCollapsed ? 0 : 1
        }}
      >
        <div className={`${baseContentClass} ${contentClassName}`}>
          {children}
        </div>
      </div>
    </div>
  );
}

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

export function DashboardWidgetContainer({
  children,
  className = '',
  allCollapsed = false,
  onToggleAll,
  title
}: DashboardWidgetContainerProps) {
  return (
    <div className={`bg-white rounded-lg shadow border border-gray-200 ${className}`}>
      {(title || onToggleAll) && (
        <div className="px-4 py-3 border-b border-gray-200 flex items-center justify-between">
          {title && <h2 className="text-lg font-semibold text-gray-900">{title}</h2>}
          {onToggleAll && (
            <button
              onClick={onToggleAll}
              className="text-sm text-gray-500 hover:text-gray-700 transition-colors"
              type="button"
            >
              {allCollapsed ? '全て展開' : '全て折りたたみ'}
            </button>
          )}
        </div>
      )}
      <div>
        {children}
      </div>
    </div>
  );
}

export default DashboardWidget;