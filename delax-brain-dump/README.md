# DELAX Brain Dump System 🧠

書き殴りから整理されたissueまでの効率的ワークフロー（動的リポジトリ対応）

## 📁 ディレクトリ構造

```
delax-brain-dump/
├── inbox/              # 書き殴りファイルをここに投入
├── projects/           # 分類済みファイル
│   ├── myprojects/     # MyProjects iOS App
│   ├── workout-100days/# 100 Days Workout
│   ├── delaxpm/        # DELAxPM Web
│   └── shared-packages/# 共通ライブラリ
├── scripts/            # 自動化スクリプト
│   ├── discover-repos.sh   # 動的リポジトリ検出
│   ├── classify-issues.sh  # AI分類（動的対応）
│   ├── push-to-github.sh   # GitHub送信（動的対応）
│   └── quick-dump.sh       # 即座書き殴り
├── repos-config.json   # 動的リポジトリ設定
└── archive/            # 完了したissue
```

## 🚀 使用方法

### 1. 書き殴り（思いついたらすぐ）
```bash
# クイック書き殴り（推奨）
./scripts/quick-dump.sh "タスク作成ボタンが反応しない。タップしても何も起きない。"

# インタラクティブモード
./scripts/quick-dump.sh -i

# カスタムファイル名で作成
./scripts/quick-dump.sh -t "button-bug" "タスク作成ボタンの問題について"

# 作成後にエディタで開く
./scripts/quick-dump.sh -o "HealthKit権限エラーが発生"
```

### 2. AI分類（まとめて処理）
```bash
# Claude CLIを使用して自動分類（動的リポジトリ対応）
./scripts/classify-issues.sh

# 初回実行時またはリポジトリ更新時
./scripts/discover-repos.sh  # 最新リポジトリ情報を取得
```

### 3. GitHub送信（選択的）
```bash
# 特定のファイルを送信
./scripts/push-to-github.sh -f myprojects/task-button-bug.md

# プロジェクト全体を送信
./scripts/push-to-github.sh -p myprojects

# 全ての分類済みissueを送信
./scripts/push-to-github.sh -a

# ドライラン（テスト）
./scripts/push-to-github.sh --dry-run -a
```

### 4. ワークフロー全体をテスト
```bash
# 完全なワークフローテスト
./scripts/test-workflow.sh
```

## ⚡ 特徴
- **即座の書き殴り**: 思考を止めずにファイル作成
- **AI分類**: Claude CLIで効率的に整理
- **動的リポジトリ対応**: GitHub APIから最新情報を自動取得
- **20+プロジェクト対応**: project-management、fitness、automation、app、shared、nutritionカテゴリ
- **コスト制御**: API使用量を完全管理
- **柔軟性**: 任意のタイミングで編集・送信

### 🎯 動的分類カテゴリ
- **project-management**: MyProjects、PMplatto、PMliberary、DELAxPM、wordvine、michishirebe
- **fitness**: delax100daysworkout  
- **automation**: issue-router、slackissue、claude-code-action、claude-code-base-action
- **app**: shadow_master、delax-unified-pm、delaxcloudkit、menumenu
- **shared**: delax-shared-packages
- **nutrition**: （将来のtontonプロジェクト用）