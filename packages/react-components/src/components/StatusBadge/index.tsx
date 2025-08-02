import React from 'react';
import { EpisodeStatus, STATUS_COLORS, STATUS_ORDER } from '../../types/episode';

/**
 * StatusBadgeコンポーネントのプロパティ
 */
export interface StatusBadgeProps {
  /** 表示するステータス */
  status: EpisodeStatus;
  /** 進捗バーを表示するかどうか */
  showProgress?: boolean;
  /** バッジのサイズ */
  size?: 'sm' | 'md' | 'lg';
  /** カスタムクラス名 */
  className?: string;
}

/**
 * ステータスバッジコンポーネント
 * 
 * エピソードの進行状況を視覚的に表示するコンポーネントです。
 * ステータスに応じた色分けと、オプションで進捗バーも表示できます。
 * 
 * @param props StatusBadgeProps
 * @returns JSX要素
 * 
 * @example
 * ```tsx
 * // 基本的な使用
 * <StatusBadge status="編集中" />
 * 
 * // 進捗バー付きで大きいサイズ
 * <StatusBadge 
 *   status="編集中" 
 *   showProgress={true} 
 *   size="lg" 
 * />
 * 
 * // カスタムスタイル適用
 * <StatusBadge 
 *   status="完パケ納品" 
 *   className="ml-2"
 * />
 * ```
 */
export function StatusBadge({ 
  status, 
  showProgress = false, 
  size = 'md',
  className = ''
}: StatusBadgeProps) {
  const statusIndex = STATUS_ORDER.indexOf(status);
  const progress = ((statusIndex + 1) / STATUS_ORDER.length) * 100;
  const color = STATUS_COLORS[status];

  const sizeClasses = {
    sm: 'px-2 py-1 text-xs',
    md: 'px-3 py-1.5 text-sm',
    lg: 'px-4 py-2 text-base'
  };

  return (
    <div className={`inline-flex items-center gap-2 ${className}`}>
      <span
        className={`inline-flex items-center rounded-full font-medium ${sizeClasses[size]}`}
        style={{ 
          backgroundColor: color + '20', // 透明度20%の背景色
          color: color,
          borderColor: color,
          borderWidth: '1px',
          borderStyle: 'solid'
        }}
      >
        {status}
      </span>
      {showProgress && (
        <div className="flex items-center gap-1">
          <div className="w-16 bg-gray-200 rounded-full h-1.5">
            <div
              className="h-1.5 rounded-full transition-all duration-300"
              style={{ 
                width: `${progress}%`,
                backgroundColor: color
              }}
            />
          </div>
          <span className="text-xs text-gray-500">{Math.round(progress)}%</span>
        </div>
      )}
    </div>
  );
}

/**
 * ステータス進捗バーのみのコンポーネント
 * StatusBadgeから独立して進捗バーのみを使用したい場合に使用
 */
export interface ProgressBarProps {
  /** 進捗率（0-100） */
  progress: number;
  /** プログレスバーの色 */
  color: string;
  /** プログレスバーの幅（Tailwindクラス） */
  width?: string;
  /** 進捗率テキストを表示するかどうか */
  showPercentage?: boolean;
}

export function ProgressBar({ 
  progress, 
  color, 
  width = 'w-16',
  showPercentage = true 
}: ProgressBarProps) {
  return (
    <div className="flex items-center gap-1">
      <div className={`${width} bg-gray-200 rounded-full h-1.5`}>
        <div
          className="h-1.5 rounded-full transition-all duration-300"
          style={{ 
            width: `${Math.min(100, Math.max(0, progress))}%`,
            backgroundColor: color
          }}
        />
      </div>
      {showPercentage && (
        <span className="text-xs text-gray-500">{Math.round(progress)}%</span>
      )}
    </div>
  );
}

export default StatusBadge;