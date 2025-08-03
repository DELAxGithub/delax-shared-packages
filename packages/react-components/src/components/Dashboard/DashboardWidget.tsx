import React, { useState } from 'react';
import { ChevronDown, ChevronRight, X } from 'lucide-react';

/**
 * ダッシュボードウィジェットのプロパティ
 */
export interface DashboardWidgetProps {
  /** ウィジェットのタイトル */
  title: string;
  /** 初期折り畳み状態 */
  isCollapsed?: boolean;
  /** 折り畳み状態変更時のハンドラー */
  onToggleCollapse?: (collapsed: boolean) => void;
  /** 子要素 */
  children: React.ReactNode;
  /** ウィジェットアイコン */
  icon?: React.ReactNode;
  /** 閉じるボタンを表示するか */
  showCloseButton?: boolean;
  /** 閉じるボタンクリック時のハンドラー */
  onClose?: () => void;
  /** カスタムクラス名 */
  className?: string;
  /** ヘッダーの背景色 */
  headerBgColor?: string;
  /** ボーダーの色 */
  borderColor?: string;
  /** アクションボタン（ヘッダー右側） */
  actions?: React.ReactNode;
  /** ローディング状態 */
  loading?: boolean;
  /** エラー状態 */
  error?: string | null;
  /** 最小化可能かどうか */
  collapsible?: boolean;
}

/**
 * 折り畳み可能なダッシュボードウィジェットコンポーネント
 * 
 * ダッシュボード画面でよく使用される、折り畳み可能なコンテナコンポーネント。
 * アイコン、アクションボタン、ローディング・エラー状態の表示に対応。
 * 
 * @example
 * ```tsx
 * <DashboardWidget
 *   title=\"タスク一覧\"
 *   icon={<TaskIcon />}
 *   collapsible={true}
 *   showCloseButton={true}
 *   onClose={() => console.log('Widget closed')}
 *   actions={<RefreshButton />}
 * >
 *   <TaskList />
 * </DashboardWidget>
 * ```
 */
export function DashboardWidget({
  title,
  isCollapsed: controlledCollapsed,
  onToggleCollapse,
  children,
  icon,
  showCloseButton = false,
  onClose,
  className = '',
  headerBgColor = 'bg-white',
  borderColor = 'border-gray-200',
  actions,
  loading = false,
  error = null,
  collapsible = true
}: DashboardWidgetProps) {
  const [internalCollapsed, setInternalCollapsed] = useState(false);
  
  // 制御されているかどうかで状態を切り替え
  const isCollapsed = controlledCollapsed !== undefined ? controlledCollapsed : internalCollapsed;
  
  const handleToggleCollapse = () => {
    const newCollapsed = !isCollapsed;
    
    if (onToggleCollapse) {
      onToggleCollapse(newCollapsed);
    } else {
      setInternalCollapsed(newCollapsed);
    }
  };

  const widgetClasses = [
    'border last:border-b-0 rounded-lg overflow-hidden shadow-sm',
    borderColor,
    className
  ].filter(Boolean).join(' ');

  const headerClasses = [
    'w-full flex items-center justify-between px-3 py-2 text-left text-sm font-medium text-gray-700 transition-colors',
    headerBgColor,
    collapsible ? 'hover:bg-gray-50 cursor-pointer' : ''
  ].filter(Boolean).join(' ');

  return (
    <div className={widgetClasses}>
      <div
        className={headerClasses}
        onClick={collapsible ? handleToggleCollapse : undefined}
      >
        <div className=\"flex items-center gap-2\">
          {icon && (
            <span className=\"text-gray-500\">
              {icon}
            </span>
          )}
          <span>{title}</span>
          {loading && (
            <span className=\"text-xs text-gray-500\">読み込み中...</span>
          )}
          {error && (
            <span className=\"text-xs text-red-500\" title={error}>
              エラー
            </span>
          )}
        </div>
        
        <div className=\"flex items-center gap-1\">
          {actions && (
            <div className=\"flex items-center gap-1\">
              {actions}
            </div>
          )}
          
          {showCloseButton && onClose && (
            <button
              onClick={(e) => {
                e.stopPropagation();
                onClose();
              }}
              className=\"p-1 text-gray-400 hover:text-gray-600 transition-colors\"
              title=\"閉じる\"
            >
              <X size={14} />
            </button>
          )}
          
          {collapsible && (
            <button
              className=\"p-1 text-gray-400 hover:text-gray-600 transition-colors\"
              title={isCollapsed ? '展開' : '折り畳み'}
              onClick={(e) => {
                e.stopPropagation();
                handleToggleCollapse();
              }}
            >
              {isCollapsed ? (
                <ChevronRight size={16} />
              ) : (
                <ChevronDown size={16} />
              )}
            </button>
          )}
        </div>
      </div>
      
      {!isCollapsed && (
        <div className=\"px-3 pb-3 text-sm bg-white\">
          {error ? (
            <div className=\"text-red-600 p-2 bg-red-50 rounded border border-red-200\">
              <div className=\"font-medium\">エラーが発生しました</div>
              <div className=\"text-sm text-red-500 mt-1\">{error}</div>
            </div>
          ) : loading ? (
            <div className=\"text-gray-500 text-center py-4\">
              <div className=\"animate-spin rounded-full h-6 w-6 border-b-2 border-gray-300 mx-auto mb-2\"></div>
              読み込み中...
            </div>
          ) : (
            children
          )}
        </div>
      )}
    </div>
  );
}

/**
 * ダッシュボードウィジェットのグリッドコンテナ
 */
export interface DashboardGridProps {
  /** 子要素（DashboardWidgetコンポーネント） */
  children: React.ReactNode;
  /** グリッドカラム数 */
  columns?: 1 | 2 | 3 | 4;
  /** ギャップサイズ */
  gap?: 'sm' | 'md' | 'lg';
  /** カスタムクラス名 */
  className?: string;
}

/**
 * ダッシュボードウィジェット用グリッドレイアウト
 */
export function DashboardGrid({
  children,
  columns = 2,
  gap = 'md',
  className = ''
}: DashboardGridProps) {
  const columnClasses = {
    1: 'grid-cols-1',
    2: 'grid-cols-1 md:grid-cols-2',
    3: 'grid-cols-1 md:grid-cols-2 lg:grid-cols-3',
    4: 'grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4'
  };

  const gapClasses = {
    sm: 'gap-2',
    md: 'gap-4',
    lg: 'gap-6'
  };

  const gridClasses = [
    'grid',
    columnClasses[columns],
    gapClasses[gap],
    className
  ].filter(Boolean).join(' ');

  return (
    <div className={gridClasses}>
      {children}
    </div>
  );
}

export default DashboardWidget;