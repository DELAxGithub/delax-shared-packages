import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { STATUS_COLORS, STATUS_ORDER } from '../../types/episode';
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
export function StatusBadge({ status, showProgress = false, size = 'md', className = '' }) {
    const statusIndex = STATUS_ORDER.indexOf(status);
    const progress = ((statusIndex + 1) / STATUS_ORDER.length) * 100;
    const color = STATUS_COLORS[status];
    const sizeClasses = {
        sm: 'px-2 py-1 text-xs',
        md: 'px-3 py-1.5 text-sm',
        lg: 'px-4 py-2 text-base'
    };
    return (_jsxs("div", { className: `inline-flex items-center gap-2 ${className}`, children: [_jsx("span", { className: `inline-flex items-center rounded-full font-medium ${sizeClasses[size]}`, style: {
                    backgroundColor: color + '20', // 透明度20%の背景色
                    color: color,
                    borderColor: color,
                    borderWidth: '1px',
                    borderStyle: 'solid'
                }, children: status }), showProgress && (_jsxs("div", { className: "flex items-center gap-1", children: [_jsx("div", { className: "w-16 bg-gray-200 rounded-full h-1.5", children: _jsx("div", { className: "h-1.5 rounded-full transition-all duration-300", style: {
                                width: `${progress}%`,
                                backgroundColor: color
                            } }) }), _jsxs("span", { className: "text-xs text-gray-500", children: [Math.round(progress), "%"] })] }))] }));
}
export function ProgressBar({ progress, color, width = 'w-16', showPercentage = true }) {
    return (_jsxs("div", { className: "flex items-center gap-1", children: [_jsx("div", { className: `${width} bg-gray-200 rounded-full h-1.5`, children: _jsx("div", { className: "h-1.5 rounded-full transition-all duration-300", style: {
                        width: `${Math.min(100, Math.max(0, progress))}%`,
                        backgroundColor: color
                    } }) }), showPercentage && (_jsxs("span", { className: "text-xs text-gray-500", children: [Math.round(progress), "%"] }))] }));
}
export default StatusBadge;
//# sourceMappingURL=index.js.map