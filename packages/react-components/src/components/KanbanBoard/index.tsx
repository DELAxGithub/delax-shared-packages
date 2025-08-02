import React from 'react';
import { DragDropContext, Droppable, Draggable, DropResult } from '@hello-pangea/dnd';
import { MoreVertical } from 'lucide-react';

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
export function KanbanCardComponent({
  card,
  index,
  onClick,
  onMenuClick,
  className = '',
  showMenu = true,
  isDragDisabled = false
}: KanbanCardProps) {
  return (
    <Draggable 
      draggableId={card.id} 
      index={index} 
      isDragDisabled={isDragDisabled}
    >
      {(provided, snapshot) => (
        <div
          ref={provided.innerRef}
          {...provided.draggableProps}
          {...provided.dragHandleProps}
          onClick={() => onClick?.(card)}
          className={`
            bg-white rounded-lg shadow-sm border border-gray-200 p-3 mb-2
            ${snapshot.isDragging ? 'shadow-lg rotate-1' : 'hover:shadow-md'}
            ${onClick ? 'cursor-pointer' : ''}
            ${isDragDisabled ? 'opacity-60' : ''}
            transition-all duration-200 ${className}
          `}
        >
          <div className="flex items-start justify-between gap-2">
            <div className="min-w-0 flex-1">
              <h3 className="text-sm font-medium text-gray-900 truncate">
                {card.title}
              </h3>
              {card.subtitle && (
                <p className="text-xs text-gray-500 truncate mt-0.5">
                  {card.subtitle}
                </p>
              )}
              {card.content && (
                <div className="mt-2">
                  {card.content}
                </div>
              )}
            </div>
            {showMenu && onMenuClick && (
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  onMenuClick(card);
                }}
                className="text-gray-400 hover:text-gray-600 p-1 transition-colors"
                aria-label="カードメニュー"
              >
                <MoreVertical size={16} />
              </button>
            )}
          </div>
        </div>
      )}
    </Draggable>
  );
}

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
export function KanbanColumnComponent({
  column,
  onCardClick,
  onCardMenuClick,
  onColumnHeaderClick,
  className = '',
  headerClassName = '',
  showCardMenu = true,
  showCardCount = true,
  emptyMessage = 'カードがありません'
}: KanbanColumnProps) {
  const isOverLimit = column.maxCards && column.cards.length > column.maxCards;

  return (
    <div className={`flex flex-col h-full ${className}`}>
      {/* 列ヘッダー */}
      <div 
        className={`
          px-3 py-2 border-b border-gray-200 bg-gray-50 
          ${onColumnHeaderClick ? 'cursor-pointer hover:bg-gray-100' : ''}
          transition-colors ${headerClassName}
        `}
        onClick={() => onColumnHeaderClick?.(column)}
        style={column.color ? { borderTopColor: column.color, borderTopWidth: '3px' } : {}}
      >
        <div className="flex items-center justify-between">
          <h3 className="font-medium text-gray-900 text-sm">
            {column.title}
          </h3>
          {showCardCount && (
            <span className={`
              text-xs px-2 py-1 rounded-full 
              ${isOverLimit ? 'bg-red-100 text-red-800' : 'bg-gray-100 text-gray-600'}
            `}>
              {column.cards.length}
              {column.maxCards && ` / ${column.maxCards}`}
            </span>
          )}
        </div>
      </div>

      {/* ドロップエリア */}
      <Droppable droppableId={column.id} isDropDisabled={column.isReadOnly}>
        {(provided, snapshot) => (
          <div
            ref={provided.innerRef}
            {...provided.droppableProps}
            className={`
              flex-1 p-2 overflow-y-auto
              ${snapshot.isDraggingOver ? 'bg-blue-50' : 'bg-gray-50'}
              ${column.isReadOnly ? 'opacity-75' : ''}
              transition-colors
            `}
          >
            {column.cards.length === 0 ? (
              <div className="text-center py-8 text-gray-400 text-sm">
                {emptyMessage}
              </div>
            ) : (
              column.cards.map((card, index) => (
                <KanbanCardComponent
                  key={card.id}
                  card={card}
                  index={index}
                  onClick={onCardClick}
                  onMenuClick={onCardMenuClick}
                  showMenu={showCardMenu}
                  isDragDisabled={column.isReadOnly}
                />
              ))
            )}
            {provided.placeholder}
          </div>
        )}
      </Droppable>
    </div>
  );
}

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
export function KanbanBoard({
  columns,
  onDragEnd,
  onCardClick,
  onCardMenuClick,
  onColumnHeaderClick,
  className = '',
  columnClassName = '',
  columnHeaderClassName = '',
  showCardMenu = true,
  showCardCount = true,
  emptyColumnMessage = 'カードがありません',
  loading = false
}: KanbanBoardProps) {
  if (loading) {
    return (
      <div className={`flex items-center justify-center h-64 ${className}`}>
        <div className="text-gray-500">読み込み中...</div>
      </div>
    );
  }

  return (
    <DragDropContext onDragEnd={onDragEnd}>
      <div className={`flex gap-4 h-full overflow-x-auto pb-4 ${className}`}>
        {columns.map((column) => (
          <div key={column.id} className="flex-shrink-0 w-80">
            <div className="bg-white rounded-lg shadow border border-gray-200 h-full">
              <KanbanColumnComponent
                column={column}
                onCardClick={onCardClick}
                onCardMenuClick={onCardMenuClick}
                onColumnHeaderClick={onColumnHeaderClick}
                className={columnClassName}
                headerClassName={columnHeaderClassName}
                showCardMenu={showCardMenu}
                showCardCount={showCardCount}
                emptyMessage={emptyColumnMessage}
              />
            </div>
          </div>
        ))}
      </div>
    </DragDropContext>
  );
}

export default KanbanBoard;