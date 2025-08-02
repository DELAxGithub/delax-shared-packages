# 🛠️ iOS Auto Build & Fix System トラブルシューティング

## 🚨 よくある問題と解決方法

### 1. Claude CLI 関連

#### ❌ "Claude CLI not found"
```bash
Error: Claude CLI not found. Please install it first.
```

**解決方法**:
```bash
# Python pip でインストール
pip install claude-cli

# npm でインストール
npm install -g @anthropic-ai/claude-cli

# Homebrew でインストール (macOS)
brew install claude-cli

# インストール確認
claude --version
```

#### ❌ "Claude API key not configured"
```bash
Error: No API key found
```

**解決方法**:
```bash
# 環境変数で設定
export CLAUDE_API_KEY="your-api-key-here"

# 設定ファイルで設定
claude configure
```

### 2. Xcode ビルド関連

#### ❌ "xcodebuild command not found"
```bash
Error: xcodebuild not found. Make sure Xcode is installed.
```

**解決方法**:
```bash
# Xcode Command Line Tools をインストール
xcode-select --install

# Xcode パスを確認
xcode-select -p

# パスが間違っている場合は修正
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

#### ❌ "No scheme named 'XXX' found"
```bash
Error: Scheme 'MyProject' not found
```

**解決方法**:
```bash
# 利用可能なスキームを確認
xcodebuild -list -project YourProject.xcodeproj

# 設定ファイルでスキーム名を修正
vim config/auto-fix-config.yml
```

### 3. ファイル権限関連

#### ❌ "Permission denied"
```bash
bash: ./scripts/auto-build-fix.sh: Permission denied
```

**解決方法**:
```bash
# 実行権限を付与
chmod +x ios-auto-build-fix/scripts/*.sh

# 権限確認
ls -la ios-auto-build-fix/scripts/
```

#### ❌ "Cannot write to builderror directory"
```bash
Error: Cannot create builderror/errors.txt
```

**解決方法**:
```bash
# ディレクトリを手動作成
mkdir -p builderror

# 権限確認・修正
chmod 755 builderror
```

### 4. Git 関連

#### ❌ "Not a git repository"
```bash
Error: Not a git repository. Git is required for safe patching.
```

**解決方法**:
```bash
# Git リポジトリを初期化
git init
git add .
git commit -m "Initial commit"

# または既存リポジトリの確認
ls -la .git
```

#### ❌ "Working directory has uncommitted changes"
```bash
Warning: Working directory has uncommitted changes
```

**解決方法**:
```bash
# 変更をコミット
git add .
git commit -m "WIP: before auto-fix"

# または変更を一時保存
git stash
```

### 5. 監視システム関連

#### ❌ "fswatch not found" (macOS)
```bash
Error: Neither fswatch (macOS) nor inotifywait (Linux) found
```

**解決方法**:
```bash
# macOS: Homebrew でインストール
brew install fswatch

# Linux: apt でインストール
sudo apt-get install inotify-tools

# インストール確認
fswatch --version
# または
inotifywait --help
```

#### ❌ "Too many file change events"
```bash
Warning: Max events per minute exceeded
```

**解決方法**:
```bash
# デバウンス時間を増加
./scripts/watch-and-fix.sh -d 5

# または設定ファイルで調整
vim config/auto-fix-config.yml
# watch:
#   debounce_seconds: 5
#   max_events_per_minute: 5
```

### 6. パッチ適用関連

#### ❌ "Patch cannot be applied"
```bash
Error: Patch cannot be applied
```

**解決方法**:
```bash
# パッチファイルの内容確認
cat builderror/patch.diff

# 手動でパッチ適用を試行
git apply --check builderror/patch.diff

# 3-way merge で試行
git apply --3way builderror/patch.diff

# 失敗した場合は手動修正
vim path/to/problematic/file.swift
```

#### ❌ "Rollback failed"
```bash
Error: Failed to restore from git stash
```

**解決方法**:
```bash
# 利用可能なStashを確認
git stash list

# 手動でStashを適用
git stash apply stash@{0}

# 最終手段: HEADに戻す
git reset --hard HEAD
```

### 7. Claude AI エラー

#### ❌ "Failed to call Claude CLI"
```bash
Error: Failed to call Claude CLI
```

**解決方法**:
```bash
# Claude CLI の手動テスト
echo "test" | claude --model claude-4-sonnet-20250514

# ネットワーク接続確認
curl -s https://api.anthropic.com/v1/health

# API制限の確認
claude --help
```

#### ❌ "No patch generated"
```bash
Warning: No patch generated
```

**解決方法**:
```bash
# エラーファイルの内容確認
cat builderror/errors.txt

# 手動でClaude CLIをテスト
./scripts/claude-patch-generator.sh builderror/errors.txt

# プロンプトの調整
vim scripts/claude-patch-generator.sh
```

### 8. パフォーマンス問題

#### ❌ "Build taking too long"
```bash
Warning: Build timeout exceeded
```

**解決方法**:
```bash
# 並列ビルドを無効化
vim config/auto-fix-config.yml
# build:
#   parallel_builds: false

# タイムアウト時間を延長
# build:
#   timeout_seconds: 600

# クリーンビルドを無効化
# build:
#   clean_before_build: false
```

#### ❌ "Memory usage too high"
```bash
Warning: High memory usage detected
```

**解決方法**:
```bash
# メモリ制限を設定
vim config/auto-fix-config.yml
# performance:
#   max_memory_mb: 256
#   max_concurrent_fixes: 1

# コンテキストサイズを削減
# claude:
#   context:
#     max_context_files: 5
#     max_context_lines: 100
```

## 🔍 デバッグ方法

### 詳細ログの有効化
```bash
# デバッグモードで実行
export DEBUG=1
./scripts/auto-build-fix.sh

# ログファイルの確認
tail -f build-fix.log
```

### 手動ステップ実行
```bash
# 1. エラー抽出のテスト
./scripts/extract-xcode-errors.sh build.log

# 2. パッチ生成のテスト
./scripts/claude-patch-generator.sh builderror/errors.txt

# 3. パッチ適用のテスト
./scripts/safe-patch-apply.sh builderror/patch.diff
```

### 設定値の確認
```bash
# 現在の設定を確認
cat config/auto-fix-config.yml

# 環境変数の確認
env | grep -E "(XCODE|CLAUDE|BUILD)"

# プロジェクト構造の確認
find . -name "*.swift" | head -10
```

## 🆘 緊急復旧手順

### 1. システム全体の停止
```bash
# 監視プロセスの停止
killall fswatch
killall inotifywait

# 実行中のビルドの停止
killall xcodebuild
```

### 2. バックアップからの復旧
```bash
# 最新のバックアップを確認
ls -la .patch-backups/

# Git stash からの復旧
git stash list
git stash apply stash@{0}

# ファイルレベルの復旧
cp .patch-backups/latest_backup/path/to/file.swift path/to/file.swift
```

### 3. クリーンな状態への復帰
```bash
# 作業ディレクトリのリセット
git clean -fd
git reset --hard HEAD

# 一時ファイルの削除
rm -rf builderror/
rm -f build.log
rm -f /tmp/claude_*
```

## 📊 ログ分析

### エラーパターンの確認
```bash
# よくあるエラーを分析
grep -E "SWIFT_ERROR|SWIFTUI_ERROR" builderror/errors.txt

# 修正成功率の確認
grep -c "Patch applied successfully" build-fix.log
```

### システム負荷の確認
```bash
# CPU使用率
top -p $(pgrep -f auto-build-fix)

# メモリ使用量
ps aux | grep -E "(xcodebuild|claude|fswatch)"

# ディスク使用量
du -sh .patch-backups/
```

## 🔧 カスタム修正

### プロジェクト固有のエラー処理を追加
```bash
# extract-xcode-errors.sh に新しいパターンを追加
vim scripts/extract-xcode-errors.sh

# 例: カスタムエラーハンドラー
extract_my_custom_errors() {
    grep -E "MyFramework.*error" "$BUILD_LOG" | \
    while IFS= read -r line; do
        echo "CUSTOM_ERROR||$line"
    done
}
```

### プロンプトの改善
```bash
# claude-patch-generator.sh のプロンプトをカスタマイズ
vim scripts/claude-patch-generator.sh

# プロジェクト固有のコンテキストを追加
```

## 📞 サポート

### 問題報告時に含める情報
1. **エラーメッセージ**: 完全なエラーログ
2. **環境情報**: OS, Xcode バージョン, Claude CLI バージョン
3. **設定ファイル**: `config/auto-fix-config.yml` の内容
4. **再現手順**: 問題が発生するまでの具体的な手順
5. **期待する動作**: 本来どのように動作すべきか

### ログファイルの収集
```bash
# デバッグ情報の収集
./scripts/collect-debug-info.sh > debug-report.txt

# システム情報の確認
system_profiler SPSoftwareDataType
xcodebuild -version
claude --version
```

このトラブルシューティングガイドで解決しない問題がある場合は、DELAX技術遺産リポジトリでIssueを作成してください。