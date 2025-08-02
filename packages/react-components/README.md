# @delax/react-components

React コンポーネント・ユーティリティ・フック集 - PMliberary技術遺産

## 🎯 概要

PMliberary プロジェクトから抽出された、メディア制作・プログラム管理システム開発で実戦検証済みの再利用可能な資産集です。

## 📦 インストール

```bash
# モノレポ内で使用
pnpm add @delax/react-components

# 外部プロジェクトで使用
npm install @delax/react-components
```

## 🚀 主要コンポーネント

### StatusBadge - 進捗ステータス表示

```tsx
import { StatusBadge } from '@delax/react-components';

<StatusBadge 
  status="編集中" 
  showProgress={true} 
  size="lg" 
/>
```

**特徴**: 10段階ステータス対応、進捗バー、自動色分け

### DashboardWidget - 折りたたみウィジェット

```tsx
import { DashboardWidget } from '@delax/react-components';

<DashboardWidget
  title="タスク一覧"
  isCollapsed={collapsed}
  onToggleCollapse={() => setCollapsed(!collapsed)}
>
  <TaskList />
</DashboardWidget>
```

**特徴**: アニメーション対応、アクセシビリティ準拠

### KanbanBoard - ドラッグ&ドロップカンバン

```tsx
import { KanbanBoard } from '@delax/react-components';

<KanbanBoard
  columns={columns}
  onDragEnd={handleDragEnd}
  onCardClick={handleCardClick}
/>
```

**特徴**: @hello-pangea/dnd基盤、カスタマイズ可能

### BaseModal - 汎用モーダル

```tsx
import { BaseModal, ConfirmModal } from '@delax/react-components';

<BaseModal
  isOpen={showModal}
  onClose={() => setShowModal(false)}
  title="設定"
  size="lg"
>
  <SettingsForm />
</BaseModal>
```

**特徴**: 5サイズ対応、キーボード操作、フォーカストラップ

## 🛠️ ユーティリティ

### 日本時間対応日付処理

```tsx
import { 
  getJSTToday, 
  formatJSTDate, 
  calculateCompleteDate 
} from '@delax/react-components';

// JST基準の日付操作
const today = getJSTToday();
const dateStr = formatJSTDate(new Date());

// 業務日計算（メディア制作特化）
const completeDate = calculateCompleteDate('2024-01-15');
```

### useDashboard - ダッシュボード管理フック

```tsx
import { useDashboard, DashboardAPI } from '@delax/react-components';

const dashboardAPI: DashboardAPI = {
  getDashboardWidgets: async () => { /* 実装 */ },
  // ... 他のAPI関数
};

const {
  widgets,
  loading,
  createWidget,
  updateWidget
} = useDashboard(dashboardAPI);
```

## 🎨 スタイリング

Tailwind CSS使用。設定に以下を追加:

```js
// tailwind.config.js
module.exports = {
  content: [
    "./node_modules/@delax/react-components/dist/**/*.js",
    // ... 他のパス
  ],
}
```

## 📊 再利用性評価

| コンポーネント | 再利用性 | 適用領域 |
|:---|:---:|:---|
| StatusBadge | ★★★★★ | 全進捗管理システム |
| DashboardWidget | ★★★★★ | 全管理画面・ダッシュボード |
| timezone utils | ★★★★★ | 全JST対応システム |
| useDashboard | ★★★★☆ | ダッシュボード機能 |
| KanbanBoard | ★★★★☆ | タスク・進捗管理 |

## 🏆 技術遺産価値

- **実戦検証済み**: PMliberary本番環境で安定稼働
- **型安全性**: 完全TypeScript対応
- **アクセシビリティ**: WCAG準拠
- **パフォーマンス**: 最適化済み

## 🔗 関連プロジェクト

- **Source**: PMliberary (Program Management System)
- **Integration**: DELAxPM統合システム
- **Future**: tonton, みちしるべ等での活用予定

---

**🤖 Generated with Claude Code integration for maximum development efficiency**