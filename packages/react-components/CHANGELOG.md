# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0] - 2025-08-03

### 🚀 Major Release - Complete Package Rebuild

#### ✨ New Features
- **WorkflowEngine**: 10段階ワークフロー管理システム（バックフロー対応、リアルタイム更新）
- **ReportGenerator**: 自動レポート生成エンジン（週報、月報、カスタムレポート）
- **AuthContext**: Supabase認証プロバイダー（Magic Link、OAuth、管理者権限）
- **SupabaseHelpers**: 汎用Supabaseユーティリティ関数群
- **Calendar Components**: カレンダーコンポーネント（イベント管理、ドラッグ&ドロップ）
- **KanbanBoard Components**: 完全なKanbanボード実装

#### 🔧 Enhanced Components
- **StatusBadge**: 
  - ジェネリック型対応で完全な型安全性
  - 3種類のプリセット（production, simple, project）
  - アクセシビリティ対応（ARIA、キーボード操作）
  - プログレス表示機能
  - カスタムクリックハンドラー
- **DashboardWidget**: 
  - アクション機能追加
  - ローディング・エラー状態管理
  - 詳細カスタマイズオプション
- **BaseModal**: 
  - サイズバリエーション拡張
  - ヘッダー・フッターカスタマイズ
  - Z-index制御

#### 🛠️ Enhanced Utilities
- **timezone.ts**: 
  - `getJSTNow()`, `formatJSTDateTime()`関数追加
  - より詳細なJST処理機能
- **dateUtils.ts**: 
  - 放送業界向け完全な日程計算システム
  - `calculateProductionSchedule()`による包括的スケジュール計算
- **新規**: **supabaseHelpers.ts**
  - fetchTable, insertRecord, updateRecord, subscribeToTable
  - 汎用的なSupabaseオペレーション

#### 📊 Business Logic
- **WorkflowEngine**: 
  - 任意のワークフロー管理（タイプセーフ）
  - 自動遷移、バックフロー制御
  - イベントリスナー、統計情報
  - ファクトリーパターンによる簡単初期化
- **ReportGenerator**: 
  - Markdown/HTML/JSON形式出力
  - テンプレートエンジン
  - 統計分析、推奨事項生成

#### 🎨 Type Definitions
- **workflow.ts**: 完全な10段階ワークフロー型定義
- ジェネリック型による型安全性の大幅向上
- プリセット型定義によるコード補完強化

#### 📚 Documentation
- **API.md**: 601行の包括的API文書
- **EXAMPLES.md**: 573行の実用的使用例
- **README.md**: 完全なセットアップガイド
- 各コンポーネントの詳細JSDoc

#### 🔨 Development
- **Rollup**: 最適化されたビルドシステム
- **Jest**: テスト環境完備
- **TypeDoc**: 自動ドキュメント生成
- **ESLint**: コード品質管理

#### 💥 Breaking Changes
- エクスポート構造の完全刷新（Utils/, Components/, Services/等）
- StatusBadgeのプロパティ変更（config必須、プリセット対応）
- 一部ユーティリティ関数の引数・戻り値変更

#### 📦 Dependencies
- `@supabase/supabase-js`: Supabase統合
- React 18対応強化
- TypeScript 5.x完全対応

---

## [1.0.0] - Previous Release

### Initial release
- 基本的なStatusBadge, DashboardWidget, Modal
- 基本的なtimezone, dateUtilsユーティリティ
- エピソード・ダッシュボード型定義