# API リファレンス

`@delax/shared-components` の詳細なAPI文書です。

## 🛠️ ユーティリティ関数

### timezone.ts

日本標準時（JST）ベースの日付処理ユーティリティ。

#### `getJSTToday(): Date`
JST基準の今日の日付を取得します。

```typescript
const today = getJSTToday();
console.log(today); // JST基準の今日 00:00:00
```

#### `parseJSTDate(dateStr: string): Date`
YYYY-MM-DD形式の文字列をJST基準のDateオブジェクトに変換します。

**Parameters:**
- `dateStr` - YYYY-MM-DD形式の日付文字列

**Returns:** JST基準のDateオブジェクト

#### `isJSTBefore(date1: Date | string, date2: Date | string): boolean`
2つの日付をJST基準で比較します。

**Parameters:**
- `date1` - 比較する日付1
- `date2` - 比較する日付2

**Returns:** date1がdate2より前の場合true

#### `formatJSTDate(date: Date): string`
JST基準でYYYY-MM-DD形式の文字列を取得します。

#### `getJSTNow(): Date`
JST基準の現在日時を取得します。

#### `formatJSTDateTime(date: Date): string`
JST基準でYYYY-MM-DD HH:mm:ss形式の文字列を取得します。

---

### dateUtils.ts

放送・制作業界向け日程計算ユーティリティ。

#### `calculateCompleteDate(firstAirDate: string, config?: Partial<DeliveryConfig>): string`
完パケ納品日を計算します。

**Parameters:**
- `firstAirDate` - 初回放送日（YYYY-MM-DD）
- `config` - 納期設定（オプション）

**Returns:** 計算された完パケ納品日

**Example:**
```typescript
const completeDate = calculateCompleteDate('2025-08-15');
// デフォルト: 1週間前の火曜日
```

#### `calculatePrDueDate(firstAirDate: string, config?: Partial<DeliveryConfig>): string`
PR納品日を計算します。

#### `calculateProductionSchedule(firstAirDate: string, config?: Partial<DeliveryConfig>, processingDays?: number)`
制作スケジュール全体を計算します。

**Returns:**
```typescript
{
  airDate: string;
  finalPackageDate: string;
  prDueDate: string;
  previewDate: string | null;
  recommendedRecordingDate: string;
  processingDays: number;
  config: DeliveryConfig;
}
```

#### Interfaces

##### `DeliveryConfig`
```typescript
interface DeliveryConfig {
  finalPackage: {
    weeksBeforeAir: number;  // 放送日から何週間前か
    dayOfWeek: number;       // 0=日曜, 1=月曜, 2=火曜...
  };
  promotional: {
    weeksBeforeAir: number;
    dayOfWeek: number;
  };
  preview?: {
    daysAfterFinalPackage: number;
  };
}
```

---

### supabaseHelpers.ts

Supabase操作の汎用ヘルパー関数群。

#### `fetchTable<T>(supabase: SupabaseClient, tableName: string, options?: SupabaseQueryOptions): Promise<SupabaseResponse<T>>`
汎用的なテーブル取得関数。

**Parameters:**
- `supabase` - Supabaseクライアント
- `tableName` - テーブル名
- `options` - クエリオプション

#### `fetchById<T>(supabase: SupabaseClient, tableName: string, id: string | number, idColumn?: string)`
単一レコード取得。

#### `insertRecord<T>(supabase: SupabaseClient, tableName: string, data: Omit<T, 'id' | 'created_at' | 'updated_at'>)`
レコード挿入。

#### `updateRecord<T>(supabase: SupabaseClient, tableName: string, id: string | number, updates: Partial<T>, idColumn?: string)`
レコード更新。

#### `subscribeToTable<T>(supabase: SupabaseClient, tableName: string, callback: Function, filters?: Record<string, any>)`
リアルタイム購読ヘルパー。

**Returns:** 購読解除関数

---

## 🎨 UIコンポーネント

### StatusBadge

プログレス表示付きステータスバッジコンポーネント。

#### Props

```typescript
interface StatusBadgeProps<T extends string = string> {
  status: T;                    // 現在のステータス
  config: StatusConfig<T>;      // ステータス設定
  showProgress?: boolean;       // プログレスバー表示
  size?: 'sm' | 'md' | 'lg';   // サイズ
  className?: string;           // カスタムクラス
  onClick?: (status: T) => void; // クリックハンドラー
}
```

#### StatusConfig

```typescript
interface StatusConfig<T extends string = string> {
  colors: Record<T, string>;           // ステータス色マッピング
  order: T[];                          // ステータス順序
  displayNames?: Record<T, string>;    // 表示名マッピング
}
```

#### 定数

##### `STATUS_PRESETS`
```typescript
const STATUS_PRESETS = {
  production: { /* 制作ワークフロー */ },
  simple: { /* シンプルタスク */ },
  project: { /* プロジェクト管理 */ }
};
```

---

### DashboardWidget

折り畳み可能なダッシュボードウィジェット。

#### Props

```typescript
interface DashboardWidgetProps {
  title: string;                           // タイトル
  isCollapsed?: boolean;                   // 折り畳み状態
  onToggleCollapse?: (collapsed: boolean) => void;
  children: React.ReactNode;               // 子要素
  icon?: React.ReactNode;                  // アイコン
  showCloseButton?: boolean;               // 閉じるボタン
  onClose?: () => void;
  className?: string;
  headerBgColor?: string;
  borderColor?: string;
  actions?: React.ReactNode;               // アクションボタン
  loading?: boolean;                       // ローディング状態
  error?: string | null;                   // エラー状態
  collapsible?: boolean;                   // 折り畳み可能か
}
```

### DashboardGrid

ダッシュボードウィジェット用グリッドレイアウト。

#### Props

```typescript
interface DashboardGridProps {
  children: React.ReactNode;
  columns?: 1 | 2 | 3 | 4;        // カラム数
  gap?: 'sm' | 'md' | 'lg';       // ギャップサイズ
  className?: string;
}
```

---

### BaseModal

汎用ベースモーダルコンポーネント。

#### Props

```typescript
interface BaseModalProps {
  isOpen: boolean;                    // 開いているか
  onClose: () => void;               // 閉じるハンドラー
  title?: string;                    // タイトル
  children: React.ReactNode;         // 子要素
  size?: 'sm' | 'md' | 'lg' | 'xl' | 'full'; // サイズ
  closeOnBackdropClick?: boolean;    // 背景クリックで閉じる
  closeOnEscape?: boolean;           // ESCで閉じる
  showCloseButton?: boolean;         // 閉じるボタン表示
  className?: string;
  headerContent?: React.ReactNode;   // ヘッダーカスタム要素
  footerContent?: React.ReactNode;   // フッターカスタム要素
  zIndex?: number;                   // Z-index値
}
```

### ConfirmModal

確認用モーダル。

#### Props

```typescript
interface ConfirmModalProps {
  isOpen: boolean;
  onCancel: () => void;
  onConfirm: () => void;
  title: string;
  message: string;
  confirmText?: string;              // 確認ボタンテキスト
  cancelText?: string;               // キャンセルボタンテキスト
  confirmVariant?: 'primary' | 'danger'; // 確認ボタン色
  loading?: boolean;                 // ローディング状態
}
```

---

## ⚛️ React統合

### AuthProvider

Supabase認証プロバイダー。

#### Props

```typescript
interface AuthProviderProps {
  supabase: SupabaseClient;    // Supabaseクライアント
  config?: AuthConfig;         // 認証設定
  children: ReactNode;         // 子要素
}
```

#### AuthConfig

```typescript
interface AuthConfig {
  redirectUrl?: string;        // 認証後リダイレクトURL
  defaultRoute?: string;       // デフォルトルート
  loginRoute?: string;         // ログインページルート
  autoSignIn?: boolean;        // 自動サインイン
  persistence?: 'local' | 'session' | 'none'; // セッション永続化
}
```

### useAuth

認証フック。

#### Returns

```typescript
interface AuthContextType {
  user: User | null;                    // 現在のユーザー
  session: Session | null;              // セッション情報
  loading: boolean;                     // ローディング状態
  error: string | null;                 // エラー情報
  signIn: (email: string, password: string) => Promise<{ error: Error | null }>;
  signUp: (email: string, password: string, metadata?: Record<string, any>) => Promise<{ error: Error | null }>;
  signInWithMagicLink: (email: string) => Promise<{ error: Error | null }>;
  signInWithOAuth: (provider: 'google' | 'github' | 'facebook' | 'twitter') => Promise<{ error: Error | null }>;
  signOut: () => Promise<{ error: Error | null }>;
  resetPassword: (email: string) => Promise<{ error: Error | null }>;
  updateProfile: (updates: { email?: string; password?: string; data?: Record<string, any> }) => Promise<{ error: Error | null }>;
  clearError: () => void;
}
```

### useAuthGuard

認証ガード用フック。

```typescript
function useAuthGuard(fallback?: ReactNode): ReactNode | null
```

### useAdminAuth

管理者権限チェック用フック。

```typescript
function useAdminAuth(adminRole?: string): { isAdmin: boolean; user: User | null }
```

---

### useDashboard

ダッシュボード管理フック。

#### Parameters

```typescript
interface UseDashboardConfig {
  supabase?: SupabaseClient;
  userId?: string;
  enableAutoRefresh?: boolean;
  defaultRefreshInterval?: number;     // 秒
  statsTable?: string;
  configTable?: string;
}
```

#### Returns

```typescript
{
  // 状態
  config: DashboardConfig;
  stats: DashboardStats;
  loading: boolean;
  error: string | null;
  lastRefresh: Date | null;

  // ウィジェット管理
  updateWidget: (widgetId: string, updates: Partial<DashboardWidget>) => Promise<void>;
  addWidget: (widget: Omit<DashboardWidget, 'order'>) => Promise<void>;
  removeWidget: (widgetId: string) => Promise<void>;
  reorderWidgets: (widgetIds: string[]) => Promise<void>;
  sortedVisibleWidgets: DashboardWidget[];

  // 設定管理
  saveConfig: (newConfig: Partial<DashboardConfig>) => Promise<void>;
  
  // データ更新
  refreshStats: () => void;
  refresh: () => void;

  // ユーティリティ
  clearError: () => void;
}
```

### useWidgetData

ウィジェット個別データ管理フック。

```typescript
function useWidgetData<T = any>(
  widgetId: string,
  dataLoader: () => Promise<T>,
  dependencies?: any[]
): {
  data: T | null;
  loading: boolean;
  error: string | null;
  reload: () => void;
  clearError: () => void;
}
```

---

## 🔄 ビジネスロジック

### ReportGenerator

汎用レポート生成エンジン。

#### Constructor

```typescript
new ReportGenerator(supabase: SupabaseClient)
```

#### Methods

##### `generateReport(config: ReportConfig, dataSource: DataSourceConfig): Promise<GeneratedReport>`

レポートを生成します。

**ReportConfig:**
```typescript
interface ReportConfig {
  title: string;
  period: 'week' | 'month' | 'custom';
  startDate?: string;    // カスタム期間用
  endDate?: string;      // カスタム期間用
  sections: {
    summary?: boolean;
    details?: boolean;
    charts?: boolean;
    recommendations?: boolean;
  };
  format: 'markdown' | 'html' | 'json';
  template?: {
    headerTemplate?: string;
    footerTemplate?: string;
    sectionTemplates?: Record<string, string>;
  };
}
```

**DataSourceConfig:**
```typescript
interface DataSourceConfig {
  table: string;                     // テーブル名
  dateField: string;                 // 日付フィールド
  statusField?: string;              // ステータスフィールド
  assigneeField?: string;            // 担当者フィールド
  filters?: Record<string, any>;     // フィルター条件
  aggregateFields?: string[];        // 集計フィールド
}
```

---

### WorkflowEngine

ワークフロー管理エンジン。

#### Constructor

```typescript
new WorkflowEngine<T extends string>(config: WorkflowEngineConfig)
```

**WorkflowEngineConfig:**
```typescript
interface WorkflowEngineConfig {
  supabase: SupabaseClient;
  itemsTable: string;               // アイテムテーブル
  historyTable: string;             // 履歴テーブル
  enableAutoTransitions?: boolean;   // 自動遷移
  enableRealtimeUpdates?: boolean;   // リアルタイム更新
}
```

#### Methods

##### `setWorkflowConfig(workflowConfig: WorkflowConfig<T>): Promise<void>`
ワークフロー設定をセット。

##### `createItem(data: Omit<WorkflowItem<T>, 'id' | 'createdAt' | 'updatedAt'> & { initialStatus?: T }): Promise<WorkflowItem<T>>`
ワークフローアイテムを作成。

##### `changeStatus(itemId: string, newStatus: T, changedBy: string, comment?: string): Promise<WorkflowItem<T>>`
ステータスを変更。

##### `getItems(filters?: WorkflowFilterOptions<T>): Promise<WorkflowItem<T>[]>`
アイテム一覧を取得。

##### `getStatistics(): Promise<WorkflowStatistics<T>>`
統計データを取得。

##### `addEventListener(listener: (event: WorkflowChangeEvent<T>) => void): void`
イベントリスナーを追加。

---

### WorkflowEngineFactory

ワークフローエンジンファクトリー。

#### Static Methods

##### `createWithPreset<T extends string>(config: WorkflowEngineConfig, presetName: keyof typeof WORKFLOW_PRESETS): WorkflowEngine<T>`
プリセット設定でエンジンを作成。

##### `createProductionWorkflow(config: WorkflowEngineConfig): WorkflowEngine<string>`
制作ワークフローエンジンを作成。

##### `createSimpleWorkflow(config: WorkflowEngineConfig): WorkflowEngine<'todo' | 'in_progress' | 'done'>`
シンプルタスクワークフローエンジンを作成。

---

## 📊 型定義

### ワークフロー関連型

#### `WorkflowStep<T>`
```typescript
interface WorkflowStep<T extends string = string> {
  id: T;
  name: string;
  description?: string;
  order: number;
  color: string;
  required?: boolean;
  prerequisites?: T[];
  estimatedMinutes?: number;
}
```

#### `WorkflowConfig<T>`
```typescript
interface WorkflowConfig<T extends string = string> {
  id: string;
  name: string;
  description?: string;
  steps: WorkflowStep<T>[];
  backflowMap?: Record<T, T[]>;      // バックフロー設定
  autoTransitions?: Record<T, T>;     // 自動遷移設定
}
```

#### `WorkflowItem<T, D>`
```typescript
interface WorkflowItem<T extends string = string, D = any> {
  id: string;
  title: string;
  currentStatus: T;
  workflowId: string;
  createdAt: string;
  updatedAt: string;
  assignee?: string;
  dueDate?: string;
  priority?: 'low' | 'medium' | 'high' | 'urgent';
  data?: D;                          // 追加データ
  tags?: string[];
}
```

---

## 🚀 定数・プリセット

### WORKFLOW_PRESETS

事前定義されたワークフロー設定。

```typescript
const WORKFLOW_PRESETS = {
  production: WorkflowConfig,  // 10段階制作ワークフロー
  simple: WorkflowConfig,      // 3段階シンプルタスク
  agile: WorkflowConfig        // 6段階アジャイル開発
};
```

### DEFAULT_DELIVERY_CONFIG

デフォルト納期設定。

```typescript
const DEFAULT_DELIVERY_CONFIG: DeliveryConfig = {
  finalPackage: { weeksBeforeAir: 1, dayOfWeek: 2 },  // 1週間前火曜
  promotional: { weeksBeforeAir: 2, dayOfWeek: 1 },   // 2週間前月曜
  preview: { daysAfterFinalPackage: 2 }               // 完パケ2日後
};
```

### LIBRARY_INFO

ライブラリ情報。

```typescript
const LIBRARY_INFO = {
  name: '@delax/shared-components',
  version: '1.0.0',
  description: 'Reusable components and utilities extracted from PMliberary project',
  author: 'DELAX',
  repository: 'https://github.com/DELAxGithub/delax-shared-packages',
  license: 'MIT'
};
```