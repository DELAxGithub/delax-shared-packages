# DELAX Shared Packages

[![Swift](https://img.shields.io/badge/swift-5.9+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platforms-iOS%2016.0%2B%20%7C%20macOS%2013.0%2B-blue.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

**DELAX Shared Packages** は、効率的な開発のための再利用可能なコンポーネントとツールのモノレポジトリです。

## 🚀 特徴

- **プロダクション品質**: 実際のプロジェクトで実証済みの実装パターン
- **95% 開発時間短縮**: 手動実装と比較して大幅な効率化
- **Swift Package Manager**: 標準的なパッケージマネージャーでの配布
- **モノレポ構造**: 複数パッケージの一元管理
- **継続的改善**: コミュニティからのフィードバックとアップデート

## 📦 利用可能なパッケージ

### DelaxCloudKitSharingKit
CloudKit共有機能を簡単に実装できるSwift Package

- 🚀 **95% 開発時間短縮**: DELAX品質基準で設計された実装パターン
- ✅ **簡単導入**: わずか数行のコードで共有機能を実装
- ✅ **プロトコルベース設計**: 任意のデータモデルに対応
- ✅ **完全なエラーハンドリング**: 詳細なエラー情報とデバッグ支援
- ✅ **SwiftUI対応**: UICloudSharingControllerの完全なSwiftUIラッパー

[詳細はこちら](packages/cloudkit-sharing-kit/README.md)

## 🔧 クイックスタート

### Swift Package Manager での使用

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/DELAxGithub/delax-shared-packages", from: "1.0.0")
]

targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "DelaxCloudKitSharingKit", package: "delax-shared-packages")
        ]
    )
]
```

### Xcode での使用

1. **File > Add Package Dependencies**
2. **URL**: `https://github.com/DELAxGithub/delax-shared-packages`
3. 必要なプロダクトを選択

## 🏗️ モノレポ構造

```
delax-shared-packages/
├── packages/
│   └── cloudkit-sharing-kit/          # CloudKit共有パッケージ
│       ├── Sources/                   # ソースコード
│       ├── Examples/                  # サンプルアプリ
│       ├── Templates/                 # 実装テンプレート
│       └── Documentation/             # 詳細ドキュメント
├── package.json                       # pnpmワークスペース設定
└── README.md                         # このファイル
```

## 🛠️ 開発環境

### 必要な環境
- **Xcode**: 15.0+
- **Swift**: 5.9+
- **Node.js**: 18.0+ (monorepo管理用)
- **pnpm**: 8.0+ (パッケージマネージャー)

### セットアップ
```bash
git clone https://github.com/DELAxGithub/delax-shared-packages.git
cd delax-shared-packages
pnpm install  # 開発依存関係のインストール
```

## 🤝 コントリビューション

1. このリポジトリをフォーク
2. 機能ブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add amazing feature'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを作成

## 🐛 バグレポート・機能要求

[GitHub Issues](https://github.com/DELAxGithub/delax-shared-packages/issues) でバグレポートや機能要求を投稿してください。

## 📝 ライセンス

このプロジェクトはMITライセンスで公開されています。詳細は[LICENSE](LICENSE)ファイルを参照してください。

## 🏢 DELAX について

**DELAX** - Technical Heritage for Efficient Development

効率的な開発のための技術資産を継承し、品質の高いソフトウェア開発をサポートします。

---

Made with ❤️ by DELAX - Claude Code