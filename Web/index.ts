/**
 * @delax/shared-components
 * 
 * PMliberaryプロジェクトから抽出した再利用可能なReactコンポーネント・ユーティリティライブラリ
 * 
 * @author DELAX
 * @version 1.0.0
 * @license MIT
 */

// Utils - ユーティリティ関数
export * from './Utils/timezone';
export * from './Utils/dateUtils';
export * from './Utils/supabaseHelpers';

// Components - UIコンポーネント
export { StatusBadge, STATUS_PRESETS } from './Components/StatusBadge';
export type { StatusBadgeProps, StatusConfig } from './Components/StatusBadge';

export { DashboardWidget, DashboardGrid } from './Components/Dashboard/DashboardWidget';
export type { DashboardWidgetProps, DashboardGridProps } from './Components/Dashboard/DashboardWidget';

export { BaseModal, ConfirmModal } from './Components/Modals/BaseModal';
export type { BaseModalProps, ConfirmModalProps } from './Components/Modals/BaseModal';

// Contexts - Reactコンテキスト
export { AuthProvider, useAuth, useAuthGuard, useAdminAuth } from './Contexts/AuthContext';
export type { AuthContextType, AuthConfig, AuthProviderProps } from './Contexts/AuthContext';

// Hooks - カスタムReactフック
export { useDashboard, useWidgetData } from './Hooks/useDashboard';
export type { 
  DashboardWidget as DashboardWidgetConfig,
  DashboardConfig, 
  DashboardStats, 
  UseDashboardConfig 
} from './Hooks/useDashboard';

// Types - TypeScript型定義
export type * from './Types/workflow';

// Services - ビジネスロジック
export { ReportGenerator, ReportDelivery } from './Services/reportGenerator';
export type { 
  ReportConfig, 
  DataSourceConfig, 
  ReportStatistics, 
  GeneratedReport,
  ReportDeliveryConfig 
} from './Services/reportGenerator';

export { WorkflowEngine, WorkflowEngineFactory } from './Services/workflowEngine';
export type { 
  WorkflowChangeEvent, 
  WorkflowEngineConfig 
} from './Services/workflowEngine';

// プリセット・設定
export { WORKFLOW_PRESETS } from './Types/workflow';
export { DEFAULT_DELIVERY_CONFIG } from './Utils/dateUtils';

/**
 * ライブラリ情報
 */
export const LIBRARY_INFO = {
  name: '@delax/shared-components',
  version: '1.0.0',
  description: 'Reusable components and utilities extracted from PMliberary project',
  author: 'DELAX',
  repository: 'https://github.com/DELAxGithub/delax-shared-packages',
  license: 'MIT'
} as const;

/**
 * 互換性情報
 */
export const COMPATIBILITY = {
  react: '^18.0.0',
  reactDom: '^18.0.0',
  typescript: '^5.0.0',
  supabase: '^2.39.0'
} as const;