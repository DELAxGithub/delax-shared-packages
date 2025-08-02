// Components
export { StatusBadge, ProgressBar } from './components/StatusBadge';
export type { StatusBadgeProps, ProgressBarProps } from './components/StatusBadge';

export { DashboardWidget, DashboardWidgetContainer } from './components/DashboardWidget';
export type { DashboardWidgetProps, DashboardWidgetContainerProps } from './components/DashboardWidget';

export { BaseModal, ConfirmModal } from './components/Modal';
export type { BaseModalProps, ConfirmModalProps } from './components/Modal';

export { KanbanBoard, KanbanCardComponent, KanbanColumnComponent } from './components/KanbanBoard';
export type { 
  KanbanCard, 
  KanbanColumn, 
  KanbanCardProps, 
  KanbanColumnProps, 
  KanbanBoardProps 
} from './components/KanbanBoard';

// Hooks
export { useDashboard } from './hooks/useDashboard';
export type { 
  DashboardAPI, 
  UseDashboardOptions, 
  UseDashboardReturn 
} from './hooks/useDashboard';

// Utilities
export {
  getJSTToday,
  parseJSTDate,
  isJSTBefore,
  formatJSTDate,
  JST_TIMEZONE
} from './utils/timezone';

export {
  calculateCompleteDate,
  calculatePrDueDate,
  BusinessDateUtils
} from './utils/dateUtils';

// Types - Episode
export type {
  EpisodeStatus,
  EpisodeType,
  MaterialStatus,
  EpisodeStatusInfo,
  Episode,
  EpisodeDetail,
  StatusHistory,
  NewEpisode,
  UpdateEpisode
} from './types/episode';

export {
  STATUS_ORDER,
  STATUS_COLORS,
  REVERTIBLE_STATUS,
  StatusManager
} from './types/episode';

// Types - Dashboard
export type {
  DashboardWidget as DashboardWidgetType,
  QuickLink,
  QuickLinksContent,
  MemoContent,
  Task,
  TasksContent,
  ScheduleContent,
  ScheduleEvent,
  CustomContent,
  NewDashboardWidget,
  UpdateDashboardWidget,
  DashboardConfig,
  DashboardLayout,
  DashboardFilter,
  DashboardStats,
  WidgetOperationResult
} from './types/dashboard';

export { DashboardUtils } from './types/dashboard';

// Re-export commonly used external dependencies for convenience
export { ChevronDown, ChevronRight } from 'lucide-react';