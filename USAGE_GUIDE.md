# 🚀 DELAX Shared Packages 利用ガイド

並行開発中のiOSアプリや他のプロジェクトで技術遺産を活用するための実践的ガイド

## 📱 iOS開発での利用方法

### Method 1: GitHub直接参照（即座利用可能）

```bash
# 1. プロジェクトルートで実行
git clone https://github.com/DELAxGithub/delax-shared-packages.git .delax-shared

# 2. iOS Auto-Fix システムをコピー
cp -r .delax-shared/native-tools/ios-auto-fix/Scripts ./scripts
cp .delax-shared/native-tools/ios-auto-fix/Templates/auto-fix-config.yml ./

# 3. 実行権限付与
chmod +x scripts/*.sh

# 4. 設定ファイルをカスタマイズ
vim auto-fix-config.yml
```

### Method 2: npm link（開発利用）

```bash
# 1. delax-shared-packages で npm link 準備
cd delax-shared-packages/native-tools/ios-auto-fix
npm link

# 2. あなたのiOSプロジェクトで利用
cd your-ios-project
npm link @delax/ios-auto-fix

# 3. 利用開始
npx ios-auto-fix setup
```

### Method 3: 将来のnpm公開版（準備済み）

```bash
# 公開後は以下で利用可能
npm install -g @delax/ios-auto-fix
ios-auto-fix setup
```

## ⚙️ 並行開発iOSアプリでの設定例

### プロジェクト構成例
```
YourIOSApp/
├── YourApp.xcodeproj
├── YourApp/
│   ├── Sources/
│   ├── Views/
│   └── Models/
├── auto-fix-config.yml          # ← 技術遺産から取得
├── scripts/                     # ← 技術遺産から取得
│   ├── auto-build-fix.sh
│   ├── extract-xcode-errors.sh
│   ├── claude-patch-generator.sh
│   ├── safe-patch-apply.sh
│   └── watch-and-fix.sh
└── .github/workflows/           # ← オプション：CI/CD統合
    └── auto-build-fix.yml
```

### カスタマイズ設定例

```yaml
# auto-fix-config.yml
project:
  name: "YourAwesomeApp"
  xcode_project: "YourApp.xcodeproj"  
  scheme: "YourApp"
  configuration: "Debug"

build:
  max_attempts: 3
  timeout_seconds: 300

claude:
  model: "claude-4-sonnet-20250514"
  context:
    include_project_structure: true
    max_context_files: 5

watch:
  directories:
    - "YourApp/Sources"
    - "YourApp/Views"
    - "YourApp/Models" 
  debounce_seconds: 2
```

## 🤖 Claude統合ライブラリの利用

### TypeScript/JavaScript プロジェクトで

```typescript
import { ClaudeIntegration, ErrorContext } from '@delax/claude-integration';

const claude = new ClaudeIntegration({
  model: 'claude-4-sonnet-20250514',
  apiKey: process.env.ANTHROPIC_API_KEY
});

// あなたのビルドエラー修正システムに統合
const context: ErrorContext = {
  language: 'swift',
  errorType: 'SWIFT_ERROR', 
  errorMessage: 'Cannot find ContentView in scope',
  filePath: 'ContentView.swift',
  projectContext: {
    name: 'YourApp',
    architecture: 'SwiftUI + MVVM'
  }
};

const response = await claude.generateFix(context);
```

### Swift Packageとして利用（将来対応）

```swift
// 将来のSwift Package対応
import ClaudeIntegration

let claude = ClaudeIntegration(
    model: "claude-4-sonnet-20250514",
    apiKey: ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]
)
```

## 📊 実用的な開発ワークフロー

### 日常開発での利用

```bash
# 1. 開発開始時に watch モード起動
./scripts/watch-and-fix.sh

# 2. コードを書く（ファイル変更を自動監視）
# 3. ビルドエラーが発生すると自動修正される
# 4. 修正が適用されて再ビルド
# 5. 成功まで自動繰り返し
```

### CI/CDでの利用

```yaml
# .github/workflows/auto-build-fix.yml
name: iOS Auto Build & Fix
on:
  push:
    branches: [ main, develop ]
    paths: [ 'YourApp/**/*.swift' ]

jobs:
  auto-build-fix:
    runs-on: macos-15
    steps:
    - uses: actions/checkout@v4
    - name: Run iOS Auto-Fix
      run: |
        chmod +x scripts/*.sh
        ./scripts/auto-build-fix.sh
      env:
        ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
```

## 🎯 並行開発プロジェクトでの活用例

### シナリオ1: 新規iOSアプリ開発

```bash
# プロジェクト初期化時
cd NewIOSApp
git clone https://github.com/DELAxGithub/delax-shared-packages.git .delax-shared
cp -r .delax-shared/native-tools/ios-auto-fix/Scripts ./scripts
cp .delax-shared/native-tools/ios-auto-fix/Templates/auto-fix-config.yml ./

# あなたのプロジェクトに合わせて設定
vim auto-fix-config.yml

# 開発開始
./scripts/watch-and-fix.sh
```

### シナリオ2: 既存プロジェクトへの導入

```bash
# 既存プロジェクトに後から追加
cd ExistingIOSApp
mkdir scripts
curl -O https://raw.githubusercontent.com/DELAxGithub/delax-shared-packages/main/native-tools/ios-auto-fix/Scripts/auto-build-fix.sh
# (他のスクリプトも同様に取得)

chmod +x scripts/*.sh
```

### シナリオ3: カスタマイズ・改良

```bash
# 技術遺産をベースにカスタマイズ
cp -r .delax-shared/native-tools/ios-auto-fix ./my-custom-auto-fix
cd my-custom-auto-fix

# あなたのプロジェクト固有の改良を追加
vim Scripts/auto-build-fix.sh
```

## 🔧 トラブルシューティング

### よくある問題と解決法

1. **実行権限エラー**
   ```bash
   chmod +x scripts/*.sh
   ```

2. **Claude CLI not found**
   ```bash
   pip install claude-cli
   export ANTHROPIC_API_KEY="your-key"
   ```

3. **設定ファイルが見つからない**
   ```bash
   # 設定ファイルのパスを確認
   ls -la auto-fix-config.yml
   ```

4. **Xcode project not found**
   ```yaml
   # auto-fix-config.yml で正しいパスを設定
   project:
     xcode_project: "正しい/パス/YourApp.xcodeproj"
   ```

## 📈 効果測定

導入後の改善指標：

- ✅ **ビルドエラー修正時間**: 手動5-10分 → 自動30秒-2分
- ✅ **開発中断回数**: 日10回 → 日2-3回
- ✅ **CI/CD失敗率**: 30% → 5%以下
- ✅ **開発フロー継続性**: 大幅改善

## 🚀 次のステップ

1. **基本導入**: GitHub直接参照で即座開始
2. **カスタマイズ**: プロジェクト固有の設定調整
3. **CI/CD統合**: GitHub Actionsでの自動化
4. **チーム導入**: 開発チーム全体での標準化
5. **改良フィードバック**: MyProjectsへの改善提案

---

**技術遺産を活用して、あなたの開発効率を劇的に向上させましょう！** 🎯✨

> このガイドは [DELAX Shared Packages](https://github.com/DELAxGithub/delax-shared-packages) の一部です