import React from 'react';

/**
 * ステータス設定の型定義
 */
export interface StatusConfig<T extends string = string> {
  /** ステータス値とカラーのマッピング */
  colors: Record<T, string>;
  /** ステータスの順序（プログレス計算用） */
  order: T[];
  /** ステータス表示名のマッピング（オプション） */
  displayNames?: Record<T, string>;
}

/**
 * StatusBadgeコンポーネントのプロパティ
 */
export interface StatusBadgeProps<T extends string = string> {
  /** 現在のステータス */
  status: T;
  /** ステータス設定 */
  config: StatusConfig<T>;
  /** プログレスバーを表示するか */
  showProgress?: boolean;
  /** サイズ */
  size?: 'sm' | 'md' | 'lg';
  /** カスタムクラス名 */
  className?: string;
  /** クリック時のハンドラー */
  onClick?: (status: T) => void;
}

/**
 * プログレス付きステータスバッジコンポーネント
 * 
 * 汎用的なステータス表示コンポーネント。設定可能なカラーテーマと
 * プログレス表示機能を提供します。
 * 
 * @example
 * ```tsx
 * // エピソード管理での使用例
 * const episodeStatusConfig = {
 *   colors: {
 *     '台本作成中': '#f59e0b',
 *     '編集中': '#3b82f6', 
 *     '完パケ納品': '#10b981'
 *   },
 *   order: ['台本作成中', '編集中', '完パケ納品']
 * };
 * 
 * <StatusBadge 
 *   status="編集中"
 *   config={episodeStatusConfig}
 *   showProgress={true}
 *   size="md"
 * />
 * ```
 */
export function StatusBadge<T extends string = string>({
  status,
  config,
  showProgress = false,
  size = 'md',
  className = '',
  onClick
}: StatusBadgeProps<T>) {
  const statusIndex = config.order.indexOf(status);
  const progress = statusIndex >= 0 ? ((statusIndex + 1) / config.order.length) * 100 : 0;
  const color = config.colors[status] || '#6b7280'; // デフォルトグレー
  const displayName = config.displayNames?.[status] || status;

  const sizeClasses = {
    sm: 'px-2 py-1 text-xs',
    md: 'px-3 py-1.5 text-sm',
    lg: 'px-4 py-2 text-base'
  };

  const badgeClasses = [
    'inline-flex items-center rounded-full font-medium transition-all duration-200',
    sizeClasses[size],
    onClick ? 'cursor-pointer hover:opacity-80' : '',
    className
  ].filter(Boolean).join(' ');

  return (
    <div className=\"inline-flex items-center gap-2\">
      <span
        className={badgeClasses}
        style={{ 
          backgroundColor: color + '20',
          color: color,
          borderColor: color,
          borderWidth: '1px',
          borderStyle: 'solid'
        }}
        onClick={onClick ? () => onClick(status) : undefined}
        role={onClick ? 'button' : undefined}
        tabIndex={onClick ? 0 : undefined}
        onKeyDown={onClick ? (e) => {
          if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault();
            onClick(status);
          }
        } : undefined}
      >
        {displayName}
      </span>
      {showProgress && statusIndex >= 0 && (
        <div className=\"flex items-center gap-1\">
          <div className=\"w-16 bg-gray-200 rounded-full h-1.5\">
            <div
              className=\"h-1.5 rounded-full transition-all duration-300\"
              style={{ 
                width: `${progress}%`,
                backgroundColor: color
              }}
            />
          </div>
          <span className=\"text-xs text-gray-500\">{Math.round(progress)}%</span>
        </div>
      )}
    </div>
  );
}

/**
 * よく使用されるステータス設定のプリセット
 */
export const STATUS_PRESETS = {
  /** 制作ワークフロー（PMliberaryベース） */
  production: {
    colors: {
      '台本作成中': '#f59e0b',
      '素材準備': '#f97316', 
      '素材確定': '#eab308',
      '編集中': '#3b82f6',
      '試写1': '#8b5cf6',
      '修正1': '#ec4899',
      'MA中': '#06b6d4',
      '初稿完成': '#10b981',
      '修正中': '#f59e0b',
      '完パケ納品': '#059669'
    } as const,
    order: [
      '台本作成中', '素材準備', '素材確定', '編集中', '試写1',
      '修正1', 'MA中', '初稿完成', '修正中', '完パケ納品'
    ] as const
  },

  /** シンプルなタスク管理 */
  simple: {
    colors: {
      'TODO': '#6b7280',
      '進行中': '#3b82f6',
      '完了': '#10b981'
    } as const,
    order: ['TODO', '進行中', '完了'] as const
  },

  /** プロジェクト管理 */
  project: {
    colors: {
      '企画': '#f59e0b',
      '設計': '#3b82f6',
      '開発': '#8b5cf6',
      'テスト': '#ec4899',
      'リリース': '#10b981'
    } as const,
    order: ['企画', '設計', '開発', 'テスト', 'リリース'] as const
  }
} as const;

export default StatusBadge;