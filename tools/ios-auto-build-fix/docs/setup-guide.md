# 📱 iOS Auto Build & Fix System セットアップガイド

## 🎯 概要

この技術遺産を新しいiOSプロジェクトに導入し、AIによる自動ビルド修正機能を活用するための詳細手順書です。

## 📋 前提条件チェック

### 必須環境
- [ ] **Xcode** インストール済み
- [ ] **Git** リポジトリでプロジェクト管理
- [ ] **Claude CLI** インストール済み
- [ ] **macOS** または **Linux** 環境

### 推奨環境
- [ ] **fswatch** (macOS): `brew install fswatch`
- [ ] **inotify-tools** (Linux): `apt install inotify-tools`

### Claude CLI インストール確認
```bash
# Claude CLI が利用可能か確認
claude --version

# 利用できない場合のインストール
pip install claude-cli
# または
npm install -g @anthropic-ai/claude-cli
```

## 🚀 Step 1: システム導入

### 1.1 ファイル配置
```bash
# プロジェクトルートに移動
cd /path/to/your/ios-project

# ios-auto-build-fixシステムをコピー
cp -r /path/to/delax-shared-packages/tools/ios-auto-build-fix/ .

# スクリプトに実行権限を付与
chmod +x ios-auto-build-fix/scripts/*.sh
```

### 1.2 ディレクトリ構造確認
```
YourProject/
├── YourProject.xcodeproj/
├── YourProject/
│   ├── ContentView.swift
│   └── ...
├── ios-auto-build-fix/           # ← 新規追加
│   ├── scripts/
│   │   ├── auto-build-fix.sh
│   │   ├── extract-xcode-errors.sh
│   │   ├── claude-patch-generator.sh
│   │   ├── safe-patch-apply.sh
│   │   └── watch-and-fix.sh
│   ├── config/
│   │   └── auto-fix-config.yml
│   └── README.md
└── builderror/                   # ← 自動作成される
```

## 🛠️ Step 2: プロジェクト設定

### 2.1 設定ファイルのカスタマイズ
```bash
# 設定ファイルをプロジェクト用にコピー
cp ios-auto-build-fix/config/auto-fix-config.yml ios-auto-build-fix/config/my-project-config.yml

# プロジェクト設定を編集
vim ios-auto-build-fix/config/my-project-config.yml
```

### 2.2 必須設定項目
```yaml
# プロジェクト情報を実際の値に変更
project:
  name: "YourActualProject"           # ← 実際のプロジェクト名
  xcode_project: "YourProject/YourProject.xcodeproj"  # ← 実際のパス
  scheme: "YourProject"               # ← 実際のスキーム名
  target_device: "iPhone 16"         # ← ターゲットデバイス

# 監視ディレクトリをプロジェクト構造に合わせる
watch:
  directories:
    - "YourProject/YourProject"       # ← 実際のソースパス
    - "YourProject/YourProject/Views" # ← 必要に応じて追加
    - "YourProject/YourProject/Models"
```

### 2.3 環境変数設定（オプション）
```bash
# .bashrc または .zshrc に追加
export XCODE_PROJECT="YourProject/YourProject.xcodeproj"
export SCHEME="YourProject"
export CONFIG_FILE="ios-auto-build-fix/config/my-project-config.yml"
```

## 🧪 Step 3: 動作テスト

### 3.1 基本動作確認
```bash
# 1. エラー抽出スクリプトのテスト
# まず手動ビルドを実行してエラーログを作成
xcodebuild -project YourProject/YourProject.xcodeproj \
           -scheme YourProject \
           -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
           build > build.log 2>&1

# エラー抽出をテスト
./ios-auto-build-fix/scripts/extract-xcode-errors.sh build.log
```

### 3.2 Claude連携テスト
```bash
# Claude CLIの動作確認
echo "Test prompt for Claude" | claude --model claude-4-sonnet-20250514

# 修正生成スクリプトのテスト（エラーがある場合）
./ios-auto-build-fix/scripts/claude-patch-generator.sh builderror/errors.txt
```

### 3.3 統合テスト
```bash
# メインスクリプトの実行テスト
./ios-auto-build-fix/scripts/auto-build-fix.sh

# 期待される出力:
# [INFO] Starting iOS Auto Build & Fix System
# [INFO] Project: /path/to/your/project
# [INFO] Checking prerequisites...
# ...
```

## 🎛️ Step 4: カスタマイズ

### 4.1 プロジェクト固有エラーパターン
```bash
# extract-xcode-errors.sh にプロジェクト固有パターンを追加
vim ios-auto-build-fix/scripts/extract-xcode-errors.sh

# 例: カスタムエラーパターンの追加
extract_custom_errors() {
    grep -E "YourCustomFramework|YourSpecificError" "$BUILD_LOG" | \
    while IFS= read -r line; do
        echo "CUSTOM_ERROR||$line"
    done
}
```

### 4.2 Claude プロンプトのカスタマイズ
```bash
# プロジェクト固有のコンテキストを追加
vim ios-auto-build-fix/scripts/claude-patch-generator.sh

# generate_project_context() 関数をカスタマイズ
```

### 4.3 ビルド設定の調整
```yaml
# config/my-project-config.yml
build:
  max_attempts: 3                    # 最大試行回数を調整
  flags:
    - "-destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'"
    - "-configuration Debug"
    - "-derivedDataPath ./DerivedData"  # カスタムパス
```

## 🔄 Step 5: ワークフロー統合

### 5.1 開発ワークフロー
```bash
# 通常の開発サイクル
git add .
git commit -m "WIP: implementing new feature"

# 自動ビルド&修正の実行
./ios-auto-build-fix/scripts/auto-build-fix.sh

# 成功した場合の最終コミット
git add .
git commit -m "✅ Feature implementation with auto-fix"
```

### 5.2 継続監視モードの活用
```bash
# バックグラウンドで監視開始
./ios-auto-build-fix/scripts/watch-and-fix.sh &

# 監視状況の確認
jobs

# 監視停止
fg  # フォアグラウンドに持ってきて Ctrl+C
```

### 5.3 Git フック統合（上級）
```bash
# pre-commit フックでの自動チェック
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
./ios-auto-build-fix/scripts/auto-build-fix.sh --quick-check
EOF

chmod +x .git/hooks/pre-commit
```

## 🚨 トラブルシューティング

### エラー: "Claude CLI not found"
```bash
# 解決方法
pip install claude-cli
# または
brew install claude-cli
```

### エラー: "xcodebuild failed"
```bash
# Xcode パスの確認
xcode-select -p

# 必要に応じてパス修正
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

### エラー: "Permission denied"
```bash
# 実行権限の付与
chmod +x ios-auto-build-fix/scripts/*.sh
```

### パッチ適用失敗
```bash
# 手動ロールバック
cd /path/to/your/project
git stash list
git stash apply stash@{0}  # 最新のバックアップを適用
```

## 📊 パフォーマンス最適化

### 大規模プロジェクトの場合
```yaml
# config/my-project-config.yml
claude:
  context:
    max_context_files: 5      # ファイル数を削減
    max_context_lines: 100    # 行数を削減

performance:
  max_concurrent_fixes: 1     # 並列処理を削減
  max_memory_mb: 256         # メモリ使用量制限
```

### 高速化設定
```yaml
build:
  clean_before_build: false   # クリーンビルドを無効化
  parallel_builds: true       # 並列ビルドを有効化

watch:
  debounce_seconds: 1         # デバウンス時間を短縮
```

## ✅ セットアップ完了チェックリスト

- [ ] スクリプトファイルが配置され、実行権限が付与されている
- [ ] 設定ファイルがプロジェクトに合わせてカスタマイズされている
- [ ] Claude CLI が正常に動作する
- [ ] 基本的なビルドテストが成功する
- [ ] エラー抽出機能が動作する
- [ ] パッチ生成・適用機能が動作する
- [ ] 監視モードが正常に起動する

## 🎉 成功例

**MyProjects での実績**:
- Swift 6 並行性エラーを30秒で自動修正
- BUILD SUCCEEDEDまで完全自動化
- 90%の開発効率向上を実現

このセットアップを完了すれば、あなたのプロジェクトでも同様の効果が期待できます！

## 🆘 サポート

問題が発生した場合:
1. README.md の詳細ドキュメントを確認
2. 設定ファイルの内容を再確認
3. トラブルシューティングセクションを参照
4. 必要に応じてDELAX技術遺産リポジトリでIssueを作成