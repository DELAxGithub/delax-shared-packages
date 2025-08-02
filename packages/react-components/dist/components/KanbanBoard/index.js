import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { DragDropContext, Droppable, Draggable } from '@hello-pangea/dnd';
import { MoreVertical } from 'lucide-react';
/**
 * カンバンカードコンポーネント
 */
export function KanbanCardComponent({ card, index, onClick, onMenuClick, className = '', showMenu = true, isDragDisabled = false }) {
    return (_jsx(Draggable, { draggableId: card.id, index: index, isDragDisabled: isDragDisabled, children: (provided, snapshot) => (_jsx("div", { ref: provided.innerRef, ...provided.draggableProps, ...provided.dragHandleProps, onClick: () => onClick?.(card), className: `
            bg-white rounded-lg shadow-sm border border-gray-200 p-3 mb-2
            ${snapshot.isDragging ? 'shadow-lg rotate-1' : 'hover:shadow-md'}
            ${onClick ? 'cursor-pointer' : ''}
            ${isDragDisabled ? 'opacity-60' : ''}
            transition-all duration-200 ${className}
          `, children: _jsxs("div", { className: "flex items-start justify-between gap-2", children: [_jsxs("div", { className: "min-w-0 flex-1", children: [_jsx("h3", { className: "text-sm font-medium text-gray-900 truncate", children: card.title }), card.subtitle && (_jsx("p", { className: "text-xs text-gray-500 truncate mt-0.5", children: card.subtitle })), card.content && (_jsx("div", { className: "mt-2", children: card.content }))] }), showMenu && onMenuClick && (_jsx("button", { onClick: (e) => {
                            e.stopPropagation();
                            onMenuClick(card);
                        }, className: "text-gray-400 hover:text-gray-600 p-1 transition-colors", "aria-label": "\u30AB\u30FC\u30C9\u30E1\u30CB\u30E5\u30FC", children: _jsx(MoreVertical, { size: 16 }) }))] }) })) }));
}
/**
 * カンバン列コンポーネント
 */
export function KanbanColumnComponent({ column, onCardClick, onCardMenuClick, onColumnHeaderClick, className = '', headerClassName = '', showCardMenu = true, showCardCount = true, emptyMessage = 'カードがありません' }) {
    const isOverLimit = column.maxCards && column.cards.length > column.maxCards;
    return (_jsxs("div", { className: `flex flex-col h-full ${className}`, children: [_jsx("div", { className: `
          px-3 py-2 border-b border-gray-200 bg-gray-50 
          ${onColumnHeaderClick ? 'cursor-pointer hover:bg-gray-100' : ''}
          transition-colors ${headerClassName}
        `, onClick: () => onColumnHeaderClick?.(column), style: column.color ? { borderTopColor: column.color, borderTopWidth: '3px' } : {}, children: _jsxs("div", { className: "flex items-center justify-between", children: [_jsx("h3", { className: "font-medium text-gray-900 text-sm", children: column.title }), showCardCount && (_jsxs("span", { className: `
              text-xs px-2 py-1 rounded-full 
              ${isOverLimit ? 'bg-red-100 text-red-800' : 'bg-gray-100 text-gray-600'}
            `, children: [column.cards.length, column.maxCards && ` / ${column.maxCards}`] }))] }) }), _jsx(Droppable, { droppableId: column.id, isDropDisabled: column.isReadOnly, children: (provided, snapshot) => (_jsxs("div", { ref: provided.innerRef, ...provided.droppableProps, className: `
              flex-1 p-2 overflow-y-auto
              ${snapshot.isDraggingOver ? 'bg-blue-50' : 'bg-gray-50'}
              ${column.isReadOnly ? 'opacity-75' : ''}
              transition-colors
            `, children: [column.cards.length === 0 ? (_jsx("div", { className: "text-center py-8 text-gray-400 text-sm", children: emptyMessage })) : (column.cards.map((card, index) => (_jsx(KanbanCardComponent, { card: card, index: index, onClick: onCardClick, onMenuClick: onCardMenuClick, showMenu: showCardMenu, isDragDisabled: column.isReadOnly }, card.id)))), provided.placeholder] })) })] }));
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
export function KanbanBoard({ columns, onDragEnd, onCardClick, onCardMenuClick, onColumnHeaderClick, className = '', columnClassName = '', columnHeaderClassName = '', showCardMenu = true, showCardCount = true, emptyColumnMessage = 'カードがありません', loading = false }) {
    if (loading) {
        return (_jsx("div", { className: `flex items-center justify-center h-64 ${className}`, children: _jsx("div", { className: "text-gray-500", children: "\u8AAD\u307F\u8FBC\u307F\u4E2D..." }) }));
    }
    return (_jsx(DragDropContext, { onDragEnd: onDragEnd, children: _jsx("div", { className: `flex gap-4 h-full overflow-x-auto pb-4 ${className}`, children: columns.map((column) => (_jsx("div", { className: "flex-shrink-0 w-80", children: _jsx("div", { className: "bg-white rounded-lg shadow border border-gray-200 h-full", children: _jsx(KanbanColumnComponent, { column: column, onCardClick: onCardClick, onCardMenuClick: onCardMenuClick, onColumnHeaderClick: onColumnHeaderClick, className: columnClassName, headerClassName: columnHeaderClassName, showCardMenu: showCardMenu, showCardCount: showCardCount, emptyMessage: emptyColumnMessage }) }) }, column.id))) }) }));
}
export default KanbanBoard;
//# sourceMappingURL=index.js.map