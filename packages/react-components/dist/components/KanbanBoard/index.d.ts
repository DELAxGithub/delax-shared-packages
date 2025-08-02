import React from 'react';
import { DropResult } from '@hello-pangea/dnd';
/**
 * カンバンカードの基本情報
 */
export interface KanbanCard {
    id: string;
    title: string;
    subtitle?: string;
    content?: React.ReactNode;
    metadata?: Record<string, unknown>;
}
/**
 * カンバン列の情報
 */
export interface KanbanColumn {
    id: string;
    title: string;
    cards: KanbanCard[];
    color?: string;
    maxCards?: number;
    isReadOnly?: boolean;
}
/**
 * カードコンポーネントのプロパティ
 */
export interface KanbanCardProps {
    card: KanbanCard;
    index: number;
    onClick?: (card: KanbanCard) => void;
    onMenuClick?: (card: KanbanCard) => void;
    className?: string;
    showMenu?: boolean;
    isDragDisabled?: boolean;
}
/**
 * カンバンカードコンポーネント
 */
export declare function KanbanCardComponent({ card, index, onClick, onMenuClick, className, showMenu, isDragDisabled }: KanbanCardProps): import("react/jsx-runtime").JSX.Element;
/**
 * カンバン列のプロパティ
 */
export interface KanbanColumnProps {
    column: KanbanColumn;
    onCardClick?: (card: KanbanCard) => void;
    onCardMenuClick?: (card: KanbanCard) => void;
    onColumnHeaderClick?: (column: KanbanColumn) => void;
    className?: string;
    headerClassName?: string;
    showCardMenu?: boolean;
    showCardCount?: boolean;
    emptyMessage?: string;
}
/**
 * カンバン列コンポーネント
 */
export declare function KanbanColumnComponent({ column, onCardClick, onCardMenuClick, onColumnHeaderClick, className, headerClassName, showCardMenu, showCardCount, emptyMessage }: KanbanColumnProps): import("react/jsx-runtime").JSX.Element;
/**
 * カンバンボードのプロパティ
 */
export interface KanbanBoardProps {
    columns: KanbanColumn[];
    onDragEnd: (result: DropResult) => void;
    onCardClick?: (card: KanbanCard) => void;
    onCardMenuClick?: (card: KanbanCard) => void;
    onColumnHeaderClick?: (column: KanbanColumn) => void;
    className?: string;
    columnClassName?: string;
    columnHeaderClassName?: string;
    showCardMenu?: boolean;
    showCardCount?: boolean;
    emptyColumnMessage?: string;
    loading?: boolean;
}
/**
 * カンバンボードコンポーネント
 *
 * ドラッグ&ドロップ機能付きのカンバンボードを提供します。
 * 列とカードの管理、カスタマイズ可能なスタイリングをサポートします。
 *
 * @param props KanbanBoardProps
 * @returns JSX要素
 *
 * @example
 * ```tsx
 * const columns: KanbanColumn[] = [
 *   {
 *     id: 'todo',
 *     title: 'TODO',
 *     cards: [
 *       { id: '1', title: 'タスク1', subtitle: '説明1' }
 *     ]
 *   },
 *   {
 *     id: 'doing',
 *     title: '進行中',
 *     cards: [],
 *     color: '#3B82F6'
 *   }
 * ];
 *
 * <KanbanBoard
 *   columns={columns}
 *   onDragEnd={(result) => {
 *     // ドラッグ終了時の処理
 *   }}
 *   onCardClick={(card) => {
 *     // カードクリック時の処理
 *   }}
 * />
 * ```
 */
export declare function KanbanBoard({ columns, onDragEnd, onCardClick, onCardMenuClick, onColumnHeaderClick, className, columnClassName, columnHeaderClassName, showCardMenu, showCardCount, emptyColumnMessage, loading }: KanbanBoardProps): import("react/jsx-runtime").JSX.Element;
export default KanbanBoard;
//# sourceMappingURL=index.d.ts.map