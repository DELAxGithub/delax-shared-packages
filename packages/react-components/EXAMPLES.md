# 使用例・サンプルコード

`@delax/shared-components` の実際の使用例とサンプルコードを紹介します。

## 📦 インストール

```bash
npm install @delax/shared-components
```

## 🎯 基本的な使用例

### 1. StatusBadge - ステータス表示

```tsx
import { StatusBadge, STATUS_PRESETS } from '@delax/shared-components';

function TaskCard({ task }) {
  return (
    <div className=\"p-4 border rounded\">
      <h3>{task.title}</h3>
      <StatusBadge 
        status={task.status}
        config={STATUS_PRESETS.production}
        showProgress={true}
        size=\"md\"
        onClick={(status) => console.log('Clicked:', status)}
      />
    </div>
  );
}
```

### 2. DashboardWidget - ダッシュボードウィジェット

```tsx
import { DashboardWidget, DashboardGrid } from '@delax/shared-components';
import { RefreshCw, Settings } from 'lucide-react';

function Dashboard() {
  const [collapsed, setCollapsed] = useState({});

  return (
    <DashboardGrid columns={3} gap=\"md\">
      <DashboardWidget
        title=\"タスク一覧\"
        icon={<TaskIcon />}
        isCollapsed={collapsed.tasks}
        onToggleCollapse={(c) => setCollapsed(prev => ({ ...prev, tasks: c }))}
        actions={
          <button onClick={refreshTasks}>
            <RefreshCw size={16} />
          </button>
        }
        loading={loading}
        error={error}
      >
        <TaskList />
      </DashboardWidget>

      <DashboardWidget
        title=\"統計情報\"
        showCloseButton={true}
        onClose={() => removeWidget('stats')}
      >
        <StatisticsChart />
      </DashboardWidget>
    </DashboardGrid>
  );
}
```

### 3. BaseModal - モーダルダイアログ

```tsx
import { BaseModal, ConfirmModal } from '@delax/shared-components';

function TaskManager() {
  const [isEditOpen, setIsEditOpen] = useState(false);
  const [isDeleteOpen, setIsDeleteOpen] = useState(false);

  return (
    <>
      {/* 編集モーダル */}
      <BaseModal
        isOpen={isEditOpen}
        onClose={() => setIsEditOpen(false)}
        title=\"タスク編集\"
        size=\"lg\"
        footerContent={
          <div className=\"flex gap-2\">
            <button onClick={handleSave}>保存</button>
            <button onClick={() => setIsEditOpen(false)}>キャンセル</button>
          </div>
        }
      >
        <TaskEditForm />
      </BaseModal>

      {/* 削除確認モーダル */}
      <ConfirmModal
        isOpen={isDeleteOpen}
        onCancel={() => setIsDeleteOpen(false)}
        onConfirm={handleDelete}
        title=\"削除確認\"
        message=\"このタスクを削除してもよろしいですか？\"
        confirmText=\"削除\"
        confirmVariant=\"danger\"
        loading={deleting}
      />
    </>
  );
}
```

## 🔐 認証システム

### AuthProvider セットアップ

```tsx
import { createClient } from '@supabase/supabase-js';
import { AuthProvider } from '@delax/shared-components';

const supabase = createClient(
  process.env.REACT_APP_SUPABASE_URL,
  process.env.REACT_APP_SUPABASE_ANON_KEY
);

function App() {
  return (
    <AuthProvider 
      supabase={supabase}
      config={{
        defaultRoute: '/dashboard',
        loginRoute: '/login',
        redirectUrl: window.location.origin
      }}
    >
      <Router>
        <Routes>
          <Route path=\"/login\" element={<LoginPage />} />
          <Route path=\"/dashboard\" element={<Dashboard />} />
        </Routes>
      </Router>
    </AuthProvider>
  );
}
```

### ログインフォーム

```tsx
import { useAuth } from '@delax/shared-components';

function LoginPage() {
  const { signIn, signInWithMagicLink, loading, error } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    const { error } = await signIn(email, password);
    if (!error) {
      navigate('/dashboard');
    }
  };

  const handleMagicLink = async () => {
    const { error } = await signInWithMagicLink(email);
    if (!error) {
      alert('マジックリンクを送信しました');
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <input 
        type=\"email\" 
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        placeholder=\"メールアドレス\"
      />
      <input 
        type=\"password\" 
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        placeholder=\"パスワード\"
      />
      <button type=\"submit\" disabled={loading}>
        {loading ? '処理中...' : 'ログイン'}
      </button>
      <button type=\"button\" onClick={handleMagicLink}>
        マジックリンク
      </button>
      {error && <p className=\"error\">{error}</p>}
    </form>
  );
}
```

### 認証ガード

```tsx
import { useAuthGuard } from '@delax/shared-components';

function ProtectedPage() {
  const authGuard = useAuthGuard(
    <div>ログインが必要です</div>
  );

  if (authGuard) return authGuard;

  return (
    <div>
      <h1>保護されたページ</h1>
      <p>認証済みユーザーのみ表示</p>
    </div>
  );
}
```

## 📊 ダッシュボード管理

```tsx
import { useDashboard, useWidgetData } from '@delax/shared-components';

function TeamDashboard() {
  const {
    config,
    stats,
    loading,
    updateWidget,
    addWidget,
    refreshStats,
    sortedVisibleWidgets
  } = useDashboard({
    supabase,
    userId: user?.id,
    enableAutoRefresh: true
  });

  // ウィジェット個別データ
  const { data: tasks, loading: tasksLoading } = useWidgetData(
    'tasks',
    () => fetchTasks(),
    [user?.id]
  );

  return (
    <div>
      <div className=\"mb-4 flex gap-2\">
        <button onClick={refreshStats}>
          統計更新
        </button>
        <button onClick={() => addWidget({
          id: 'new-widget',
          name: '新しいウィジェット',
          visible: true,
          collapsed: false,
          size: 'md'
        })}>
          ウィジェット追加
        </button>
      </div>

      <DashboardGrid columns={config.columns}>
        {sortedVisibleWidgets.map(widget => (
          <DashboardWidget
            key={widget.id}
            title={widget.name}
            isCollapsed={widget.collapsed}
            onToggleCollapse={(collapsed) => 
              updateWidget(widget.id, { collapsed })
            }
          >
            <WidgetContent 
              widgetId={widget.id} 
              data={tasks}
              loading={tasksLoading}
            />
          </DashboardWidget>
        ))}
      </DashboardGrid>
    </div>
  );
}
```

## 📅 日付処理ユーティリティ

```tsx
import { 
  getJSTToday, 
  formatJSTDate,
  calculateCompleteDate,
  calculatePrDueDate,
  calculateProductionSchedule 
} from '@delax/shared-components';

function ProductionScheduler() {
  const [airDate, setAirDate] = useState('');

  // JST基準の今日
  const today = getJSTToday();
  
  // 放送業界向け日程計算
  const schedule = useMemo(() => {
    if (!airDate) return null;
    
    return calculateProductionSchedule(airDate, {
      finalPackage: { weeksBeforeAir: 1, dayOfWeek: 2 }, // 1週間前の火曜日
      promotional: { weeksBeforeAir: 2, dayOfWeek: 1 }    // 2週間前の月曜日
    }, 10); // 編集処理日数
  }, [airDate]);

  return (
    <div>
      <input 
        type=\"date\" 
        value={airDate}
        onChange={(e) => setAirDate(e.target.value)}
        min={formatJSTDate(today)}
      />
      
      {schedule && (
        <div className=\"mt-4\">
          <h3>制作スケジュール</h3>
          <ul>
            <li>収録推奨日: {schedule.recommendedRecordingDate}</li>
            <li>PR納品日: {schedule.prDueDate}</li>
            <li>完パケ納品日: {schedule.finalPackageDate}</li>
            {schedule.previewDate && (
              <li>試写日: {schedule.previewDate}</li>
            )}
            <li>放送日: {schedule.airDate}</li>
          </ul>
        </div>
      )}
    </div>
  );
}
```

## 🔄 ワークフロー管理

```tsx
import { 
  WorkflowEngine, 
  WorkflowEngineFactory,
  WORKFLOW_PRESETS 
} from '@delax/shared-components';

function WorkflowManager() {
  const [engine] = useState(() => 
    WorkflowEngineFactory.createProductionWorkflow({
      supabase,
      itemsTable: 'episodes',
      historyTable: 'episode_history',
      enableRealtimeUpdates: true
    })
  );

  const [items, setItems] = useState([]);

  useEffect(() => {
    // リアルタイム更新のリスナー
    engine.addEventListener((event) => {
      if (event.type === 'status_changed') {
        setItems(prev => prev.map(item => 
          item.id === event.itemId ? event.newData : item
        ));
      }
    });

    // 初期データ取得
    engine.getItems().then(setItems);
  }, [engine]);

  const handleStatusChange = async (itemId, newStatus, comment) => {
    try {
      await engine.changeStatus(itemId, newStatus, user.id, comment);
    } catch (error) {
      alert(error.message);
    }
  };

  return (
    <div>
      {items.map(item => (
        <div key={item.id} className=\"border p-4 rounded\">
          <h3>{item.title}</h3>
          <StatusBadge 
            status={item.currentStatus}
            config={STATUS_PRESETS.production}
            showProgress={true}
          />
          <select 
            onChange={(e) => handleStatusChange(
              item.id, 
              e.target.value, 
              'ステータス変更'
            )}
            value={item.currentStatus}
          >
            {WORKFLOW_PRESETS.production.steps.map(step => (
              <option key={step.id} value={step.id}>
                {step.name}
              </option>
            ))}
          </select>
        </div>
      ))}
    </div>
  );
}
```

## 📈 レポート生成

```tsx
import { ReportGenerator } from '@delax/shared-components';

function ReportingSystem() {
  const [generator] = useState(() => new ReportGenerator(supabase));
  const [report, setReport] = useState(null);

  const generateWeeklyReport = async () => {
    const report = await generator.generateReport({
      title: '週次進捗レポート',
      period: 'week',
      sections: {
        summary: true,
        details: true,
        charts: true,
        recommendations: true
      },
      format: 'markdown'
    }, {
      table: 'episodes',
      dateField: 'updated_at',
      statusField: 'current_status',
      assigneeField: 'assignee'
    });

    setReport(report);
  };

  return (
    <div>
      <button onClick={generateWeeklyReport}>
        週報生成
      </button>
      
      {report && (
        <div className=\"mt-4\">
          <h2>{report.title}</h2>
          <p>生成日時: {report.generatedAt}</p>
          <p>対象期間: {report.period.start} 〜 {report.period.end}</p>
          
          <div className=\"bg-gray-100 p-4 rounded mt-4\">
            <pre>{report.formattedContent}</pre>
          </div>
        </div>
      )}
    </div>
  );
}
```

## 🔧 Supabaseヘルパー

```tsx
import { 
  fetchTable, 
  fetchById, 
  insertRecord, 
  updateRecord,
  subscribeToTable 
} from '@delax/shared-components';

function DataManager() {
  const [items, setItems] = useState([]);

  useEffect(() => {
    // データ取得
    const loadData = async () => {
      const { data, error } = await fetchTable(supabase, 'tasks', {
        orderBy: { column: 'created_at', ascending: false },
        filters: { status: 'active' },
        pagination: { from: 0, to: 9 }
      });
      
      if (!error && data) {
        setItems(data);
      }
    };

    loadData();

    // リアルタイム購読
    const unsubscribe = subscribeToTable(
      supabase,
      'tasks',
      ({ eventType, new: newData, old: oldData }) => {
        if (eventType === 'INSERT') {
          setItems(prev => [newData, ...prev]);
        } else if (eventType === 'UPDATE') {
          setItems(prev => prev.map(item => 
            item.id === newData.id ? newData : item
          ));
        } else if (eventType === 'DELETE') {
          setItems(prev => prev.filter(item => item.id !== oldData.id));
        }
      }
    );

    return () => unsubscribe();
  }, []);

  const createItem = async (data) => {
    const { data: created, error } = await insertRecord(
      supabase, 
      'tasks', 
      data
    );
    if (!error) {
      console.log('Created:', created);
    }
  };

  return (
    <div>
      {/* UI implementation */}
    </div>
  );
}
```

## 🎨 カスタムステータス設定

```tsx
import { StatusBadge } from '@delax/shared-components';

// カスタムステータス設定
const customStatusConfig = {
  colors: {
    '設計': '#3b82f6',
    '開発': '#f59e0b', 
    'レビュー': '#8b5cf6',
    'テスト': '#ec4899',
    'リリース': '#10b981'
  },
  order: ['設計', '開発', 'レビュー', 'テスト', 'リリース'],
  displayNames: {
    '設計': '📋 設計フェーズ',
    '開発': '💻 開発フェーズ',
    'レビュー': '👀 レビューフェーズ',
    'テスト': '🧪 テストフェーズ',
    'リリース': '🚀 リリース完了'
  }
};

function CustomStatusExample() {
  return (
    <StatusBadge 
      status=\"開発\"
      config={customStatusConfig}
      showProgress={true}
      onClick={(status) => console.log('Status clicked:', status)}
    />
  );
}
```

これらの例を参考に、あなたのプロジェクトに `@delax/shared-components` を組み込んでください。