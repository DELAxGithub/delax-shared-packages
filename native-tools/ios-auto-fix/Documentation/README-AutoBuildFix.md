# iOS Auto Build & Fix System

MyProjectsプロジェクト専用のXcodeビルドエラー自動修正システムです。手動での「ビルド→エラー確認→修正→再ビルド」ワークフローを完全自動化します。

## 🚀 Quick Start

```bash
# システム全体を実行
./scripts/auto-build-fix.sh

# ファイル監視モードで継続的に実行
./scripts/watch-and-fix.sh

# 設定確認（dry run）
./scripts/watch-and-fix.sh --dry-run
```

## 📋 システム構成

### 1. `auto-build-fix.sh` - メインスクリプト
- Xcodeプロジェクトのclean & build実行
- ビルドエラーの自動抽出と分類
- Claude Code CLIを使ったAI修正
- 安全なパッチ適用とロールバック
- 最大試行回数制限による無限ループ防止

### 2. `extract-xcode-errors.sh` - エラー解析
- Xcodeビルドログから構造化されたエラー情報を抽出
- Swift、SwiftUI、ビルドシステム、インポート、コード署名エラーに対応
- Claude Codeが理解しやすい形式で出力

### 3. `claude-patch-generator.sh` - AI統合
- エラー情報をClaude Code CLIに送信
- MyProjectsのSwiftUI/SwiftDataアーキテクチャコンテキストを追加
- プロジェクト固有の修正パターンでパッチ生成

### 4. `safe-patch-apply.sh` - 安全適用
- Git stashによる自動バックアップ
- パッチ適用前の構文・形式チェック
- 3-way mergeによる競合解決
- 失敗時の自動ロールバック機能

### 5. `watch-and-fix.sh` - 監視モード
- ファイル変更の監視（fswatch/inotify使用）
- デバウンス機能による過度なビルド防止
- Swift/設定ファイルの変更に自動反応

## ⚙️ 設定

`config/auto-fix-config.yml`で動作をカスタマイズできます：

```yaml
# プロジェクト設定
project:
  scheme: "Myprojects"
  configuration: "Debug"

# ビルド設定
build:
  max_attempts: 5
  timeout_seconds: 300

# Claude AI設定
claude:
  model: "claude-3-5-sonnet-20241022"
  
# 監視設定
watch:
  debounce_seconds: 3
  directories:
    - "Myprojects/Myprojects"
```

## 🛠️ セットアップ

### 前提条件
```bash
# Xcode & Command Line Tools
xcode-select --install

# Claude CLI (オプション - AI修正に必要)
pip install claude-cli

# fswatch (macOSの場合)
brew install fswatch

# inotify-tools (Linuxの場合)
apt-get install inotify-tools
```

### 実行権限の設定
```bash
chmod +x scripts/*.sh
```

## 📖 使用方法

### 基本的な使用方法

```bash
# 1回だけ実行
./scripts/auto-build-fix.sh

# 継続監視モード
./scripts/watch-and-fix.sh

# 5秒デバウンスで監視
./scripts/watch-and-fix.sh -d 5
```

### 個別スクリプトの使用

```bash
# エラー抽出のみ
./scripts/extract-xcode-errors.sh build.log

# パッチ生成のみ
./scripts/claude-patch-generator.sh builderror/errors.txt

# パッチ適用のみ
./scripts/safe-patch-apply.sh builderror/patch.diff
```

## 🔧 対応エラータイプ

- **Swift Compiler Errors**: 構文エラー、型不一致、未定義変数など
- **SwiftUI Errors**: State管理、Binding、プロパティラッパーの問題
- **Build System Errors**: リンクエラー、リソース不足、依存関係の問題
- **Import Errors**: モジュール不足、パッケージ依存関係の問題
- **Code Signing Errors**: 証明書、プロビジョニングプロファイルの問題
- **Critical Warnings**: エラーになる可能性のある警告

## 🛡️ 安全機能

### バックアップとロールバック
- Git stashによる自動バックアップ
- ファイルレベルのバックアップ保存
- 失敗時の自動ロールバック
- バックアップの保持期間管理

### 検証機能
- パッチ適用前のドライラン
- 構文チェック
- 危険なコマンドの検出
- ファイル整合性の確認

### 制限機能
- 最大試行回数制限
- タイムアウト設定
- CPU/メモリ使用量制限
- 重要ファイルの変更禁止

## 📊 ログとモニタリング

### ログ出力
```bash
# ログファイル
tail -f build-fix.log

# リアルタイム出力
./scripts/auto-build-fix.sh 2>&1 | tee -a build-fix.log
```

### 統計情報
- エラータイプ別の修正成功率
- 修正時間の統計
- よく発生するエラーパターン

## 🔍 トラブルシューティング

### よくある問題

1. **Claude CLI not found**
   ```bash
   pip install claude-cli
   # または
   npm install -g @anthropic/claude-cli
   ```

2. **Permission denied**
   ```bash
   chmod +x scripts/*.sh
   ```

3. **Xcode project not found**
   - `config/auto-fix-config.yml`のパス設定を確認

4. **Build timeout**
   - 設定ファイルの`timeout_seconds`を増加

### デバッグモード
```bash
# 詳細ログ出力
VERBOSE=1 ./scripts/auto-build-fix.sh

# dry runモード
./scripts/watch-and-fix.sh --dry-run
```

## 🚀 高度な使用方法

### CI/CDとの統合
```yaml
# GitHub Actions例
- name: Auto fix build errors
  run: |
    ./scripts/auto-build-fix.sh
    if [ $? -ne 0 ]; then
      echo "Auto-fix failed, manual intervention required"
      exit 1
    fi
```

### カスタムフック
```bash
# ビルド前フック
echo "Starting custom prebuild tasks..." >> custom-prebuild.sh

# ビルド後フック  
echo "Running custom tests..." >> custom-postbuild.sh
```

## 📚 関連ドキュメント

- [MyProjects Architecture](../PROJECT_ARCHITECTURE.md)
- [Development Workflow](../QUICKSTART.md)  
- [Claude Code Documentation](../CLAUDE.md)
- [Configuration Reference](../config/auto-fix-config.yml)

## 🤝 Contributing

バグ報告や機能要求は [Issues](https://github.com/DELAxGithub/myprojects/issues) で受け付けています。

---

**注意**: このシステムはMyProjectsプロジェクト専用に設計されています。他のプロジェクトで使用する場合は、設定ファイルとスクリプトの調整が必要です。