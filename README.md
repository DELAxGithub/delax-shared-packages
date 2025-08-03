# @delax/shared-components

PMliberaryプロジェクトから抽出した再利用可能なReactコンポーネント・ユーティリティライブラリ

## 🚀 Features

### 📊 UIコンポーネント
- **StatusBadge** - プログレス表示付きステータスバッジ
- **DashboardWidget** - 折り畳み可能なダッシュボードウィジェット
- **KanbanBoard** - ドラッグ&ドロップ対応のカンバンボード
- **Calendar** - リアルタイム更新対応カレンダー
- **Modal系** - 汎用モーダルコンポーネント

### 🛠️ ユーティリティ
- **timezone** - 日本時間（JST）基準の日付処理
- **dateUtils** - 放送業界向け日程計算（完パケ・PR納品日算出）
- **supabaseHelpers** - Supabase統合ヘルパー関数

### ⚛️ React統合
- **AuthContext** - Supabase認証コンテキスト
- **useDashboard** - ダッシュボード状態管理フック
- **WorkflowContext** - ワークフロー管理コンテキスト

### 📈 ビジネスロジック
- **reportGenerator** - 自動レポート生成エンジン
- **workflowEngine** - 10段階ワークフロー管理

## 📦 Installation

```bash
npm install @delax/shared-components
```

## 🔧 Usage

### StatusBadge Component
```tsx
import { StatusBadge } from '@delax/shared-components';

<StatusBadge 
  status="編集中" 
  showProgress={true} 
  size="md" 
/>
```

### Timezone Utilities
```typescript
import { getJSTToday, formatJSTDate } from '@delax/shared-components/utils';

const today = getJSTToday();
const formattedDate = formatJSTDate(new Date());
```

### Date Calculation (Broadcasting Industry)
```typescript
import { calculateCompleteDate, calculatePrDueDate } from '@delax/shared-components/utils';

const airDate = '2025-08-15';
const completeDate = calculateCompleteDate(airDate); // 1週間前の火曜日
const prDueDate = calculatePrDueDate(airDate); // 2週間前の月曜日
```

## 🏗️ Architecture

```
Web/
├── Components/           # 再利用UIコンポーネント
├── Utils/               # ユーティリティ関数
├── Hooks/              # カスタムReactフック
├── Types/              # TypeScript型定義
├── Services/           # ビジネスロジック
└── Contexts/           # Reactコンテキスト
```

## 📚 Documentation

詳細なAPI文書は `docs/` ディレクトリまたはTypeDocで生成された文書を参照してください。

## 🤝 Contributing

このライブラリはPMliberaryプロジェクトから抽出された資産です。改善提案やバグ報告は Issues でお知らせください。

## 📄 License

MIT License

---

**Origin Project**: [PMliberary](https://github.com/DELAxGithub/PMliberary) - Program Management System
**Shared Repository**: [delax-shared-packages](https://github.com/DELAxGithub/delax-shared-packages)