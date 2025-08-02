import { EpisodeStatus } from '../../types/episode';
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
export declare function StatusBadge({ status, showProgress, size, className }: StatusBadgeProps): import("react/jsx-runtime").JSX.Element;
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
export declare function ProgressBar({ progress, color, width, showPercentage }: ProgressBarProps): import("react/jsx-runtime").JSX.Element;
export default StatusBadge;
//# sourceMappingURL=index.d.ts.map